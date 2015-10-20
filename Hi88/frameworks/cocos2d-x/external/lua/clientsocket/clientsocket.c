//
//  clientsocket.c
//  test_clientsocket
//
//  Created by chris li on 15/10/16.
//  Copyright (c) 2015年 chris li. All rights reserved.
//
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include "clientsocket.h"

struct message {
    char *data;
    unsigned int size;
};

struct package_header {
    unsigned short size;
};

#define QUEUE_SIZE 1024

struct queue {
    pthread_mutex_t lock;
    int head;
    int tail;
    struct message* queue[QUEUE_SIZE];
};

struct thread_param {
    struct queue * sendqueue;
    struct queue * recvqueue;
    int fd;
};

static struct queue * s_sendqueue = NULL;
static struct queue * s_recvqueue = NULL;

static const unsigned int SOCKET_BUFF_SIZE = (0x1000);
static const unsigned int PACKAGE_HEADER_SIZE = sizeof(struct package_header);
static int s_fd = 0;
static pthread_t s_pid = 0;


static struct message*
message_queue_pop(struct queue *q) {
    pthread_mutex_lock(&q->lock);
    if (q->head == q->tail) {
        pthread_mutex_unlock(&q->lock);
        return NULL;
    }
    struct message *ret = q->queue[q->head];
    q->queue[q->head] = NULL;
    if (++q->head >= QUEUE_SIZE) {
        q->head = 0;
    }
    pthread_mutex_unlock(&q->lock);
    return ret;
}


static int
message_queue_push(struct queue *q, struct message *message) {
    pthread_mutex_lock(&q->lock);
    int next = (q->tail + 1) % QUEUE_SIZE;
    if (q->head == next) {
        pthread_mutex_unlock(&q->lock);
        return -1;
    }
    q->queue[q->tail] = message;
    q->tail = next;
    pthread_mutex_unlock(&q->lock);
    return 0;
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


int
clientsocket_pushmessage(struct queue *q, const char *data, unsigned int size) {
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
    
    return ret;
}


static void
clientsocket_parsebuff(struct queue *q, char *databuff, long databuff_size, long *offset) {
    if (databuff_size <= 0) return;
    
    if (databuff_size > PACKAGE_HEADER_SIZE) {
        struct package_header *header = (struct package_header*)databuff;
        unsigned int message_size = (NTOHS(header->size));
        if (databuff_size >= PACKAGE_HEADER_SIZE + message_size) {
            clientsocket_pushmessage(q, databuff, PACKAGE_HEADER_SIZE + message_size);
            
            *offset = *offset + message_size + PACKAGE_HEADER_SIZE;
            
            clientsocket_parsebuff(q, databuff + PACKAGE_HEADER_SIZE + message_size,
                                   databuff_size - PACKAGE_HEADER_SIZE - message_size,
                                   offset);
        }
    }
}


static void
clientsocket_poll(void * arg) {
    struct thread_param *param = arg;
    struct queue * sendqueue = param->sendqueue;
    struct queue * recvqueue = param->recvqueue;
    int fd = param->fd;
    char databuff[SOCKET_BUFF_SIZE+50];
    memset(databuff, 0, sizeof(SOCKET_BUFF_SIZE+50));
    long databuff_unused = 0;
    
    while (1) {
        // 1. process send message
        struct message *sendmessage = message_queue_pop(sendqueue);
        if (NULL != sendmessage) {
            if (send(fd, sendmessage->data, sendmessage->size, 0) <= 0) {
                printf("[ERR]send fail");
            }
            message_free(sendmessage);
        }
        
        // 2. process recv message
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
        
        usleep(1000000*1/60);
    }
}


int
clientsocket_connect(const char *ip, unsigned short port) {
    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);
    int fd = s_fd;
    if (fd == 0) {
        if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
            printf("create socket error\n");
            return -1;
        }
        s_fd = fd;
    }
    
    if (connect(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        printf("connect error\n");
        return -2;
    }
    
    int flag = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flag | O_NONBLOCK);
    
    // set socket buffer size
    int send_buff_size = SOCKET_BUFF_SIZE;
    if (setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &send_buff_size, sizeof(send_buff_size)) < 0) {
        printf("[ERR]setsockopt for sending fail");
        return -5;
    }
    int recv_buff_size = SOCKET_BUFF_SIZE;
    if (setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &recv_buff_size, sizeof(recv_buff_size)) < 0) {
        printf("[ERR]setsockopt for receiving fail");
        return -6;
    }
    
    clientsocket_start();
    
    return fd;
}


int
clientsocket_start() {
    if (s_pid > 0) return -1;
    s_sendqueue = malloc(sizeof(struct queue));
    s_recvqueue = malloc(sizeof(struct queue));
    memset(s_sendqueue, 0, sizeof(struct queue));
    memset(s_recvqueue, 0, sizeof(struct queue));
    pthread_mutex_init(&s_sendqueue->lock, NULL);
    pthread_mutex_init(&s_recvqueue->lock, NULL);
    struct thread_param *arg = malloc(sizeof(struct thread_param));
    arg->sendqueue = s_sendqueue;
    arg->recvqueue = s_recvqueue;
    arg->fd = s_fd;
    
    int ret = pthread_create(&s_pid, NULL, (void*)clientsocket_poll, arg);
    if (ret != 0) {
        printf("Create pthread error!\n");
        pthread_mutex_destroy(&s_sendqueue->lock);
        pthread_mutex_destroy(&s_recvqueue->lock);
        free(s_sendqueue);
        free(s_recvqueue);
        return -1;
    }
    //pthread_join(s_pid, NULL);
    return 0;
}

static inline void
write_2byte(char *buffer, int val) {
	buffer[0] = (val >> 8) & 0xff;
	buffer[1] = val & 0xff;
}

static inline unsigned short
read_2byte(const char *buffer) {
    int val = 0;
	val = buffer[1] + (buffer[0] << 8);
	return val;
}

int clientsocket_send(unsigned short prototype, const char *data, unsigned int size) {
    if (NULL == s_sendqueue) {
        return -1;
    }
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
    
    int ret = message_queue_push(s_sendqueue, message);
    
    return ret;
}


int clientsocket_recv(unsigned short *prototype, char *outdata, unsigned int *outsize) {
    if (*outsize < SOCKET_BUFF_SIZE) {
        printf("out size is too small");
        return 0;
    }
    if (NULL == s_recvqueue) {
        return 0;
    }
    struct message *message = message_queue_pop(s_recvqueue);
    if (NULL == message) {
        *outsize = 0;
        return 0;
    }
    int recvsize = read_2byte(message->data);
    *prototype = read_2byte(message->data + 2);
    memcpy(outdata, message->data + 4, message->size - 4);
    *outsize = message->size - 4;
    message_free(message);
    
    return recvsize;
}


