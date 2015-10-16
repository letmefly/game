//
//  SocketClient.cpp
//  mygame
//
//  Created by chris li on 15/9/2.
//
//
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include "SocketClient.h"
//#include "cocos2d.h"

#define MAX_MSGPOOL_SIZE    2000

static ElementPool *g_ElementPool = nullptr;

ElementPool* ElementPool::getInstance()
{
    if (nullptr == g_ElementPool)
    {
        g_ElementPool = new ElementPool();
    }
    return g_ElementPool;
}

ElementPool::ElementPool()
{
    for (int i = 0; i < MAX_MSGPOOL_SIZE+10; i++)
    {
        Element *msg = new Element();
        msg->data = NULL;
        msg->size = 0;
        _elementPool.push_back(msg);
    }
}

ElementPool::~ElementPool()
{
}

Element* ElementPool::allocElement()
{
    Element *element = NULL;
    
    _mutex.lock();
    if (_elementPool.size() > 0)
    {
        element = _elementPool.back();
        _elementPool.pop_back();
    }
    _mutex.unlock();
    
    return element;
}

void ElementPool::freeElement(Element *element)
{
    free(element->data);
    element->data = NULL;
    element->size = 0;
    
    _mutex.lock();
    _elementPool.push_back(element);
    _mutex.unlock();
}

static const unsigned int SOCKET_BUFF_SIZE = (10*1024);
static const unsigned int MSG_HEADER_SIZE = sizeof(MessageHeader);
static SocketClient *g_SocketClient = nullptr;

SocketClient* SocketClient::getInstance()
{
    if (nullptr == g_SocketClient)
    {
        g_SocketClient = new SocketClient();
    }
    return g_SocketClient;
}

SocketClient::SocketClient(){}

SocketClient::~SocketClient(){}

bool SocketClient::connectServer(std::string ip, unsigned short port)
{
    _ip = ip;
    _port = port;
    
    sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip.c_str());
    
    if ((_socketfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        printf("create socket error: %s(errno: %d)\n", strerror(errno),errno);
        return false;
    }
    
    if (connect(_socketfd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
    {
        printf("connect error: %s(errno: %d)\n",strerror(errno),errno);
        return false;
    }
    
    int flags = fcntl(_socketfd, F_GETFL, 0);
    if (flags < 0 )
    {
        perror("fcntl F_GETFL");
        return false;
    }
    flags |= O_NONBLOCK;
    if (fcntl(_socketfd, F_SETFL, flags) < 0)
    {
        perror("fcntl F_SETFL");
        return false;
    }
    
    // set socket buffer size
    int send_buff_size = SOCKET_BUFF_SIZE;
    if (setsockopt(_socketfd, SOL_SOCKET, SO_SNDBUF, &send_buff_size, sizeof(send_buff_size)) < 0)
    {
        printf("[ERR]setsockopt for sending fail");
        return false;
    }
    int recv_buff_size = SOCKET_BUFF_SIZE;
    if (setsockopt(_socketfd, SOL_SOCKET, SO_RCVBUF, &recv_buff_size, sizeof(recv_buff_size)) < 0)
    {
        printf("[ERR]setsockopt for receiving fail");
        return false;
    }
    
    // start network thread, and preparing receive message
    this->startThread();
    //cocos2d::Director::getInstance()->getScheduler()->scheduleUpdate(this, 0, false);
    
    return true;
}

void SocketClient::sendMessage(unsigned int messageID, char *data, long size)
{
    Element *element = ElementPool::getInstance()->allocElement();
    if (NULL == element)
    {
        printf("[ERR]there is no element availabel in pool");
        return;
    }
    char *msgData = (char*)malloc(MSG_HEADER_SIZE + size);
    MessageHeader *header = (MessageHeader*)msgData;
    header->messageID = messageID;
    memcpy(msgData + MSG_HEADER_SIZE, data, size);
    element->data = msgData;
    element->size = MSG_HEADER_SIZE + size;
    this->pushSendQueueElement(element);
}

Element* SocketClient::getSendQueueElement()
{
    Element *element = NULL;
    _sendQueueMutex.lock();
    if (_sendQueue.size() > 0)
    {
        element = _sendQueue.front();
        _sendQueue.pop();
    }
    _sendQueueMutex.unlock();
    return element;
}

void SocketClient::pushSendQueueElement(Element *element)
{
    _sendQueueMutex.lock();
    _sendQueue.push(element);
    _sendQueueMutex.unlock();
}

Element* SocketClient::getRecvQueueElement()
{
    Element *element = NULL;
    _recvQueueMutex.lock();
    if (_recvQueue.size() > 0)
    {
        element = _recvQueue.front();
        _recvQueue.pop();
    }
    _recvQueueMutex.unlock();
    return element;
}

void SocketClient::pushRecvQueueElement(Element *element)
{
    _recvQueueMutex.lock();
    _recvQueue.push(element);
    _recvQueueMutex.unlock();
}

int SocketClient::recvData(const char *data, unsigned int size)
{
    Element *element = ElementPool::getInstance()->allocElement();
    if (NULL == element)
    {
        printf("message buffer is empty: %s(errno: %d)\n",strerror(errno),errno);
        return -1;
    }
    
    char *elementData = (char *)malloc(size + 10);
    memcpy(elementData, data, size);
    
    element->data = elementData;
    element->size = size;
    
    this->pushRecvQueueElement(element);
    
    return 0;
}

void SocketClient::parseBuff(char *dataBuff, long dataBuffSize, long *offset)
{
    if (dataBuffSize <= 0) return;
    
    if (dataBuffSize >= MSG_HEADER_SIZE)
    {
        MessageHeader *header = (MessageHeader*)dataBuff;
        unsigned int messageSize = (NTOHL(header->size));
        if (dataBuffSize >= MSG_HEADER_SIZE + messageSize)
        {
            this->recvData(dataBuff, MSG_HEADER_SIZE + messageSize);
            *offset = *offset + messageSize + MSG_HEADER_SIZE;
            this->parseBuff(dataBuff + MSG_HEADER_SIZE + messageSize, dataBuffSize - MSG_HEADER_SIZE - messageSize, offset);
        }
    }
}

void SocketClient::startThread()
{
    _networkThread = std::thread([this]() {
        char dataBuff[SOCKET_BUFF_SIZE+50];
        memset(dataBuff, 0, sizeof(dataBuff));
        long dataUnusedSize = 0;
                                     
        while (true)
        {
            // 1. process send message
            Element *element = this->getSendQueueElement();
            if (NULL != element)
            {
                if (send(_socketfd, element->data, element->size, 0) <= 0)
                {
                    printf("[ERR]send fail");
                }
                
                ElementPool::getInstance()->freeElement(element);
            }
            
            // 2. process recv message
            long recvSize = recv(_socketfd, dataBuff + dataUnusedSize, SOCKET_BUFF_SIZE - dataUnusedSize, 0);
            long offset = 0;
            long dataBuffSize = dataUnusedSize + recvSize;
            this->parseBuff(dataBuff, dataBuffSize, &offset);
            if (offset > 0 && offset < dataBuffSize)
            {
                memcpy(dataBuff, dataBuff + offset, dataBuffSize - offset);
            }

            dataUnusedSize = dataBuffSize - offset;
            if (dataUnusedSize < 0 || dataUnusedSize > SOCKET_BUFF_SIZE)
            {
                dataUnusedSize = 0;
            }
        }
    });
}

void SocketClient::recvMessage()
{
    Element *element = this->getRecvQueueElement();
    if (NULL == element) return;
    MessageHeader *messageHeader = (MessageHeader*)element->data;
    auto handler = _messageHandlers[messageHeader->messageID];
    if (handler)
    {
        handler(element->data + MSG_HEADER_SIZE, element->size-MSG_HEADER_SIZE);
    }
    
    ElementPool::getInstance()->freeElement(element);
}

void SocketClient::update(float dt)
{
    this->recvMessage();
}

void SocketClient::registerMessageHandler(unsigned short messageID, MessageHandler handler)
{
    _messageHandlers[messageID] = handler;
}

void SocketClient::unregisterMessageHandler(unsigned short messageID)
{
    _messageHandlers[messageID] = nullptr;
}

