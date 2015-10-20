//
//  SocketClient.h
//  mygame
//
//  Created by chris li on 15/9/2.
//
//

#ifndef __mygame__SocketClient__
#define __mygame__SocketClient__
#include "cocos2d.h"


typedef struct _element
{
    char *data;
    unsigned int size;
} Element;

typedef struct _messageHeader
{
    unsigned short messageID;
    unsigned char  protoType;
    unsigned int size;
} MessageHeader;

typedef std::function<void(const char *data, unsigned int size)> MessageHandler;

class ElementPool
{
public:
    static ElementPool* getInstance();
    ElementPool();
    ~ElementPool();
    
    Element* allocElement();
    void freeElement(Element *element);
    
private:
    std::vector<Element*> _elementPool;
    std::mutex _mutex;
};


class SocketClient
{
public:
    static SocketClient* getInstance();
    SocketClient();
    ~SocketClient();
    
    bool connectServer(std::string ip, unsigned short port);
    void startThread();
    void stopThread();
    
    void sendMessage(unsigned int messageID, char *data, long size);
    void recvMessage();
    void registerMessageHandler(unsigned short messageID, MessageHandler handler);
    void unregisterMessageHandler(unsigned short messageID);
    void update(float dt);
    
private:
    void parseBuff(char *dataBuff, long dataBuffSize, long *offset);
    int recvData(const char *data, unsigned int size);
    
    Element* getSendQueueElement();
    Element* getRecvQueueElement();
    void pushSendQueueElement(Element *element);
    void pushRecvQueueElement(Element *element);
    
    std::string _ip;
    unsigned short _port;
    
    std::thread _networkThread;
    int _socketfd;
    std::mutex _sendQueueMutex;
    std::mutex _recvQueueMutex;
    std::queue<Element*> _sendQueue;
    std::queue<Element*> _recvQueue;
    
    std::map<int, MessageHandler> _messageHandlers;
};


#endif /* defined(__mygame__SocketClient__) */
