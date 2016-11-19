//
//  clientsocket.c
//  test_clientsocket
//
//  Created by chris li on 15/10/16.
//  Copyright (c) 2015年 chris li. All rights reserved.
//

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
//#include<windows.h>  
#ifndef UNICODE
#define UNICODE
#endif

#define WIN32_LEAN_AND_MEAN

#include <winsock2.h>
#include <ws2tcpip.h>

// Need to link with Ws2_32.lib
#pragma comment(lib, "ws2_32.lib")
#else
#include <signal.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>
#include "clientsocket.h"


/*
 * message unit in send or recv message queue
 */

struct message {
    char *data;
    unsigned int size;
};

struct package_header {
    unsigned short size;
};

/*
 * send or recv message queue
 */
#define QUEUE_SIZE 1024
struct messagequeue {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	HANDLE lock;
#else
    pthread_mutex_t lock;
#endif
    int head;
    int tail;
    struct message* queue[QUEUE_SIZE];
};

/*
 * clientsocket object
 */
struct clientsocket {
    /* server ip and port */
    char addr[120];
    unsigned short port;
    
    /* 0 not connect, 1 connecting, 2 connect ok, 3 connect fail, 4 disconnect */
    int connectstatus;
    
    /* network thread id */
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	HANDLE  pid;
#else
    pthread_t pid;
#endif
    /* socket fd */
    int fd;
    
    struct messagequeue *sendqueue;
    struct messagequeue *recvqueue;
};

static const unsigned int SOCKET_BUFF_SIZE = (0x1000);
static const unsigned int PACKAGE_HEADER_SIZE = sizeof(struct package_header);

static struct clientsocket *s_clientsocket = NULL;

int
clientsocket_init(const char *addr, unsigned short port) {
    if (s_clientsocket) {return -1;}
    
    s_clientsocket = (struct clientsocket*)malloc(sizeof(struct clientsocket));
    memset(s_clientsocket, 0, sizeof(struct clientsocket));
    s_clientsocket->sendqueue = (struct messagequeue*)malloc(sizeof(struct messagequeue));
    s_clientsocket->recvqueue = (struct messagequeue*)malloc(sizeof(struct messagequeue));
    memset(s_clientsocket->sendqueue, 0, sizeof(struct messagequeue));
    memset(s_clientsocket->recvqueue, 0, sizeof(struct messagequeue));
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	s_clientsocket->sendqueue->lock = CreateMutex(NULL, FALSE, NULL);
	s_clientsocket->recvqueue->lock = CreateMutex(NULL, FALSE, NULL);
#else
    pthread_mutex_init(&s_clientsocket->sendqueue->lock, NULL);
    pthread_mutex_init(&s_clientsocket->recvqueue->lock, NULL);
#endif
    strcpy(s_clientsocket->addr, addr);
    s_clientsocket->port = port;
    
    return 0;
}


int
clientsocket_connectstatus() {
    assert(s_clientsocket);
    return s_clientsocket->connectstatus;
}

static struct message* message_malloc() {
    struct message *ret = (struct message*)malloc(sizeof(struct message));
    memset(ret, 0, sizeof(sizeof(struct message)));
    return ret;
}
static void message_free(struct message *message) {
    free(message->data);
    message->data = NULL;
    free(message);
}


static void
message_queue_pop(struct messagequeue *q) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	WaitForSingleObject(&q->lock, INFINITE);
#else
    pthread_mutex_lock(&q->lock);
#endif
    if (q->head == q->tail) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
		ReleaseMutex(&q->lock);
#else
        pthread_mutex_unlock(&q->lock);
#endif
    }
    struct message *ret = q->queue[q->head];
    q->queue[q->head] = NULL;
    if (++q->head >= QUEUE_SIZE) {
        q->head = 0;
    }
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	ReleaseMutex(&q->lock);
#else
    pthread_mutex_unlock(&q->lock);
#endif
    message_free(ret);
}

static struct message*
message_queue_head(struct messagequeue *q) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	WaitForSingleObject(&q->lock, INFINITE);
#else
    pthread_mutex_lock(&q->lock);
#endif
    if (q->head == q->tail) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
		ReleaseMutex(&q->lock);
#else
        pthread_mutex_unlock(&q->lock);
#endif
        return NULL;
    }
    struct message *ret = q->queue[q->head];
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	ReleaseMutex(&q->lock);
#else
    pthread_mutex_unlock(&q->lock);
#endif
    return ret;
}

static int
message_queue_push(struct messagequeue *q, struct message *message) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	WaitForSingleObject(&q->lock, INFINITE);
#else
    pthread_mutex_lock(&q->lock);
#endif
    int next = (q->tail + 1) % QUEUE_SIZE;
    if (q->head == next) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
		ReleaseMutex(&q->lock);
#else
        pthread_mutex_unlock(&q->lock);
#endif
        return -1;
    }
    q->queue[q->tail] = message;
    q->tail = next;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	ReleaseMutex(&q->lock);
#else
    pthread_mutex_unlock(&q->lock);
#endif
    return 0;
}

static void
message_queue_clear(struct messagequeue *q) {
    while (1) {
        struct message *message = message_queue_head(q);
        if (message == NULL) break;
        message_queue_pop(q);
    }
}


int
clientsocket_pushmessage(struct messagequeue *q, const char *data, unsigned int size) {
    struct message *message = message_malloc();
    if (NULL == message) {
        printf("malloc message fail\n");
        return -1;
    }
    
    char *messagedata = (char *)malloc(size + 10);
    memset(messagedata, 0, size + 10);
    memcpy(messagedata, data, size);
    
    message->data = messagedata;
    message->size = size;
    
    int ret = message_queue_push(q, message);
    if (ret < 0) {
        message_free(message);
    }
    
    return ret;
}


static void
clientsocket_parsebuff(struct messagequeue *q, char *databuff, long databuff_size, long *offset) {
    if (databuff_size <= 0) return;
    
    if (databuff_size > sizeof(struct package_header)) {
        struct package_header *header = (struct package_header*)databuff;
		unsigned int message_size = ntohs(header->size);
        if (databuff_size >= PACKAGE_HEADER_SIZE + message_size) {
            int ret = clientsocket_pushmessage(q, databuff, PACKAGE_HEADER_SIZE + message_size);
            if (ret < 0) {
                printf("[ERR]receive message fail, recev queue is full!");
            }
            
            *offset = *offset + message_size + PACKAGE_HEADER_SIZE;
            
            clientsocket_parsebuff(q, databuff + PACKAGE_HEADER_SIZE + message_size,
                                   databuff_size - PACKAGE_HEADER_SIZE - message_size,
                                   offset);
        }
    }
}

static void
write_2byte(char *buffer, int val) {
	buffer[0] = (val >> 8) & 0xff;
	buffer[1] = val & 0xff;
}

static unsigned short
read_2byte(const char *buffer) {
    int val = 0;
	val = buffer[1] + (buffer[0] << 8);
	return val;
}

int clientsocket_send(unsigned short prototype, const char *data, unsigned int size) {
    if (STATUS_CONNECT_OK != s_clientsocket->connectstatus) {
        return -1;
    }
    struct messagequeue * sendqueue = s_clientsocket->sendqueue;
    struct message *message = message_malloc();
    if (NULL == message) {
        printf("malloc message fail\n");
        return -1;
    }
    
    char *message_data = (char *)malloc(size + 4 + 10);
    memset(message_data, 0, size + 4 + 10);
    
    // write message totoal size. (prototype + logical_data_size)
    write_2byte(message_data, size+2);
    
    // wirte prototype
    write_2byte(message_data+2, prototype);
    
    memcpy(message_data+4, data, size);
    
    message->data = message_data;
    message->size = size + 4;
    
    int ret = message_queue_push(sendqueue, message);
    if (ret < 0) {
        message_free(message);
        printf("[ERR]send message fail, send message queue full!");
    }
    
    return ret;
}


int clientsocket_recv(unsigned short *prototype, char *outdata, unsigned int *outsize) {
    struct messagequeue * recvqueue = s_clientsocket->recvqueue;
    if (*outsize < SOCKET_BUFF_SIZE) {
        printf("out size is too small");
        return 0;
    }
    if (NULL == recvqueue) {
        return 0;
    }
    struct message *message = message_queue_head(recvqueue);
    if (NULL == message) {
        *outsize = 0;
        return 0;
    }
    int recvsize = read_2byte(message->data);
    *prototype = read_2byte(message->data + 2);
    memcpy(outdata, message->data + 4, message->size - 4);
    *outsize = message->size - 4;
    message_queue_pop(recvqueue);
    
    return recvsize;
}

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
DWORD WINAPI clientsocket_networkprocess(LPVOID pM) {
	//-------------------------
	// Initialize Winsock
	WSADATA wsaData;
	int iResult;
	u_long iMode = 1;
	iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != NO_ERROR)
		printf("Error at WSAStartup()\n");

	s_clientsocket->connectstatus = STATUS_CONNECTING;
	s_clientsocket->fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (!s_clientsocket->fd) {
		printf("socket create error!");
		s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
		return;
	}

	char *ip = s_clientsocket->addr;
	unsigned short port = s_clientsocket->port;
	struct hostent* hp = gethostbyname(ip);
	if (!hp) {
		printf("socket gethostbyname error!");
		s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
		return;
	}

	SOCKADDR_IN clientService;
	clientService.sin_family = AF_INET;
	clientService.sin_addr.s_addr = inet_addr(ip);
	clientService.sin_port = htons(port);

	printf("socket connect ip=%s, port=%d", ip, port);
	int ret = connect(s_clientsocket->fd, (SOCKADDR*)&clientService, sizeof(clientService));
	if (ret == SOCKET_ERROR) {
		printf("connect fail");
		s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
		WSACleanup();
		return;
	}

	iResult = ioctlsocket(s_clientsocket->fd, FIONBIO, &iMode);
	if (iResult != NO_ERROR)
		printf("ioctlsocket failed with error: %ld\n", iResult);

	// update connect status: ok
	s_clientsocket->connectstatus = STATUS_CONNECT_OK;

	// 2. start socket poll
	int fd = s_clientsocket->fd;
	struct messagequeue * sendqueue = s_clientsocket->sendqueue;
	struct messagequeue * recvqueue = s_clientsocket->recvqueue;
	char databuff[0x1000 + 50];
	memset(databuff, 0, sizeof(SOCKET_BUFF_SIZE + 50));
	long databuff_unused = 0;
	while (1) {
		if (s_clientsocket->connectstatus != STATUS_CONNECT_OK) { continue; }

		// 1. process recv message
		long recv_size = recv(fd, databuff + databuff_unused, SOCKET_BUFF_SIZE - databuff_unused, 0);
		if (recv_size > 0) {
			long offset = 0;
			long databuff_size = databuff_unused + recv_size;

			clientsocket_parsebuff(recvqueue, databuff, databuff_size, &offset);

			if (offset > 0 && offset < databuff_size) {
				memcpy(databuff, databuff + offset, databuff_size - offset);
			}

			databuff_unused = databuff_size - offset;
			if (databuff_unused < 0 || databuff_unused > SOCKET_BUFF_SIZE) {
				databuff_unused = 0;
			}
		}
		else if (recv_size <= 0) {
			int nError = WSAGetLastError();
			if (nError != WSAEWOULDBLOCK && nError != 0)
			{
				// Shutdown our socket
				shutdown(fd, SD_SEND);

				// Close our socket entirely
				closesocket(fd);
				printf("[ERR]network disconnect");
				s_clientsocket->connectstatus = STATUS_DISCONNECT;
				return;
			}

		}

		// 2. process send message
		struct message *sendmessage = message_queue_head(sendqueue);
		if (NULL != sendmessage) {
			if (send(fd, sendmessage->data, sendmessage->size, 0) > 0) {
				message_queue_pop(sendqueue);
			}
		}

		Sleep(1.0 / 30);
	}
	return 0;
}
#else

static void
clientsocket_networkprocess(void *param) {
    /* instals a handler to ignore sigpipe or it will crash us */
    signal(SIGPIPE, SIG_IGN);
    
    // update connect status: connecting
    s_clientsocket->connectstatus = STATUS_CONNECTING;
    
    // 1. connect server
    s_clientsocket->fd = socket(AF_INET, SOCK_STREAM, 0);
    if (!s_clientsocket->fd) {
        printf("socket create error!");
        s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
        return;
    }
    
    char *ip = s_clientsocket->addr;
    unsigned short port = s_clientsocket->port;
    struct hostent* hp = gethostbyname(ip);
    if (!hp) {
        printf("socket gethostbyname error!");
        s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
        return;
    }
    struct sockaddr_in svraddr;
    memset(&svraddr, 0, sizeof(svraddr));
    memcpy((char*)&svraddr.sin_addr, hp->h_addr, hp->h_length);
    svraddr.sin_family = hp->h_addrtype;
    svraddr.sin_port = htons(port);
    printf("socket connect ip=%s, port=%d",ip, port);
    int ret = connect(s_clientsocket->fd, (struct sockaddr*)&svraddr, sizeof(svraddr));
    if (ret < 0) {
        printf("connect fail");
        s_clientsocket->connectstatus = STATUS_CONNECT_FAIL;
        return;
    }
    fcntl(s_clientsocket->fd, F_SETFL, O_NONBLOCK);
    
    // update connect status: ok
    s_clientsocket->connectstatus = STATUS_CONNECT_OK;
    
    // 2. start socket poll
    int fd = s_clientsocket->fd;
    struct messagequeue * sendqueue = s_clientsocket->sendqueue;
    struct messagequeue * recvqueue = s_clientsocket->recvqueue;
    char databuff[SOCKET_BUFF_SIZE+50];
    memset(databuff, 0, sizeof(SOCKET_BUFF_SIZE+50));
    long databuff_unused = 0;
    
    while (1) {
        if (s_clientsocket->connectstatus != STATUS_CONNECT_OK) {continue;}
        
        // 1. process recv message
        long recv_size = recv(fd, databuff + databuff_unused, SOCKET_BUFF_SIZE - databuff_unused, 0);
        if (recv_size > 0) {
            long offset = 0;
            long databuff_size = databuff_unused + recv_size;
            
            clientsocket_parsebuff(recvqueue, databuff, databuff_size, &offset);
            
            if (offset > 0 && offset < databuff_size) {
                memcpy(databuff, databuff + offset, databuff_size - offset);
            }
            
            databuff_unused = databuff_size - offset;
            if (databuff_unused < 0 || databuff_unused > SOCKET_BUFF_SIZE) {
                databuff_unused = 0;
            }
        } else if (0 == recv_size) {
            printf("[ERR]network disconnect");
            s_clientsocket->connectstatus = STATUS_DISCONNECT;
            return;
        }
        
        // 2. process send message
        struct message *sendmessage = message_queue_head(sendqueue);
        if (NULL != sendmessage) {
            if (send(fd, sendmessage->data, sendmessage->size, 0) > 0) {
                message_queue_pop(sendqueue);
            }
        }
        
        usleep(1000000*1/60);
    }
}
#endif

int
clientsocket_start() {
    assert(s_clientsocket);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	if (0 == s_clientsocket->pid) {
		long pid;
		s_clientsocket->pid = CreateThread(NULL, 0, clientsocket_networkprocess, (LPVOID)0, 0, &pid);
	}
#else
    if (0 == s_clientsocket->pid) {
        pthread_create(&s_clientsocket->pid, NULL, (void*)clientsocket_networkprocess, NULL);
    }
#endif
    return 0;
}

int
clientsocket_stop() {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	// 1. kill network thread
	if (0 != s_clientsocket->pid) {
		CloseHandle(s_clientsocket->pid);
	}

	// 2. clear send and receive message queue
	struct messagequeue * sendqueue = s_clientsocket->sendqueue;
	if (sendqueue) {
		message_queue_clear(sendqueue);
		s_clientsocket->sendqueue = NULL;
	}
	struct messagequeue * recvqueue = s_clientsocket->recvqueue;
	if (recvqueue) {
		message_queue_clear(recvqueue);
		s_clientsocket->recvqueue = NULL;
	}

	// 3. close socket fd
	if (0 != s_clientsocket->fd) {
		closesocket(s_clientsocket->fd);
		s_clientsocket->fd = 0;
	}
	s_clientsocket->connectstatus = STATUS_NOT_CONNECT;
#else
    // 1. kill network thread
    if (0 != s_clientsocket->pid) {
        pthread_kill(s_clientsocket->pid, 0);
    }
    
    // 2. clear send and receive message queue
    struct messagequeue * sendqueue = s_clientsocket->sendqueue;
    if (sendqueue) {
        message_queue_clear(sendqueue);
        s_clientsocket->sendqueue = NULL;
    }
    struct messagequeue * recvqueue = s_clientsocket->recvqueue;
    if (recvqueue) {
        message_queue_clear(recvqueue);
        s_clientsocket->recvqueue = NULL;
    }
    
    // 3. close socket fd
    if (0 != s_clientsocket->fd) {
        close(s_clientsocket->fd);
        s_clientsocket->fd = 0;
    }
    s_clientsocket->connectstatus = STATUS_NOT_CONNECT;
#endif
    return 0;
}

int
clientsocket_reconnect() {
    clientsocket_stop();
    clientsocket_start();
    return 0;
}


