//
//  clientsocket.c
//  test_clientsocket
//
//  Created by chris li on 15/10/16.
//  Copyright (c) 2015年 chris li. All rights reserved.
//
#include <signal.h>
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
#include <assert.h>
#include <errno.h>
#include "clientsocket.h"



/*
struct package_header {
    unsigned short size;
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
static int s_isconnect = 0;
static pthread_t s_pid = 0;


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
message_queue_pop(struct queue *q) {
    pthread_mutex_lock(&q->lock);
    if (q->head == q->tail) {
        pthread_mutex_unlock(&q->lock);
    }
    struct message *ret = q->queue[q->head];
    q->queue[q->head] = NULL;
    if (++q->head >= QUEUE_SIZE) {
        q->head = 0;
    }
    pthread_mutex_unlock(&q->lock);
    message_free(ret);
}

static struct message*
message_queue_head(struct queue *q) {
    pthread_mutex_lock(&q->lock);
    if (q->head == q->tail) {
        pthread_mutex_unlock(&q->lock);
        return NULL;
    }
    struct message *ret = q->queue[q->head];
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
    if (ret < 0) {
        message_free(message);
    }
    
    return ret;
}


static void
clientsocket_parsebuff(struct queue *q, char *databuff, long databuff_size, long *offset) {
    if (databuff_size <= 0) return;
    
    if (databuff_size > PACKAGE_HEADER_SIZE) {
        struct package_header *header = (struct package_header*)databuff;
        unsigned int message_size = (NTOHS(header->size));
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
        if (s_isconnect == 0) continue;
        struct message *sendmessage = message_queue_head(sendqueue);
        if (NULL != sendmessage) {
            if (send(fd, sendmessage->data, sendmessage->size, 0) <= 0) {
                //printf("[ERR]send fail");
                s_isconnect= 0;
            } else {
                message_queue_pop(sendqueue);
            }
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

void
disconnect_handler(int sig) {
    //printf("socket disconnect..., please reconnect");
    s_isconnect = 0;
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
        
//        struct sigaction action;
//        action.sa_handler = disconnect_handler;
//        sigemptyset(&action.sa_mask);
//        action.sa_flags = 0;
//        sigaction(SIGPIPE, &action, NULL);

//        struct sigaction sa;
//        sa.sa_handler = SIG_IGN;
//        sigaction(SIGPIPE,&sa,0);
//        struct sigaction act;
//        act.sa_handler = SIG_IGN;
//        if (sigaction(SIGPIPE, &act, NULL) == 0) {
//        }
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
    
    s_isconnect = 1;
    
    return fd;
}


int
clientsocket_start() {
    if (s_pid > 0) return -1;
    
    struct sigaction act;
    act.sa_handler = SIG_IGN;
    if (sigaction(SIGPIPE, &act, NULL) == 0) {
    }
    
    
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
    if (ret < 0) {
        message_free(message);
        printf("[ERR]send message fail, send message queue full!");
    }
    
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
    struct message *message = message_queue_head(s_recvqueue);
    if (NULL == message) {
        *outsize = 0;
        return 0;
    }
    int recvsize = read_2byte(message->data);
    *prototype = read_2byte(message->data + 2);
    memcpy(outdata, message->data + 4, message->size - 4);
    *outsize = message->size - 4;
    message_queue_pop(s_recvqueue);
    
    return recvsize;
}
*/

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
    pthread_mutex_t lock;
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
    pthread_t pid;
    
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
    
    pthread_mutex_init(&s_clientsocket->sendqueue->lock, NULL);
    pthread_mutex_init(&s_clientsocket->recvqueue->lock, NULL);
    
    strcpy(s_clientsocket->addr, addr);
    s_clientsocket->port = port;
    
    return 0;
}

int
clientsocket_get_connectstatus() {
    assert(s_clientsocket);
    return s_clientsocket->connectstatus;
}

int
clientsocket_set_connectstatus(int status) {
    s_clientsocket->connectstatus = status;
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


static void
message_queue_pop(struct messagequeue *q) {
    pthread_mutex_lock(&q->lock);
    if (q->head == q->tail) {
        pthread_mutex_unlock(&q->lock);
    }
    struct message *ret = q->queue[q->head];
    q->queue[q->head] = NULL;
    if (++q->head >= QUEUE_SIZE) {
        q->head = 0;
    }
    pthread_mutex_unlock(&q->lock);
    message_free(ret);
}

static struct message*
message_queue_head(struct messagequeue *q) {
    pthread_mutex_lock(&q->lock);
    if (q->head == q->tail) {
        pthread_mutex_unlock(&q->lock);
        return NULL;
    }
    struct message *ret = q->queue[q->head];
    pthread_mutex_unlock(&q->lock);
    return ret;
}

static int
message_queue_push(struct messagequeue *q, struct message *message) {
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
        unsigned int message_size = (NTOHS(header->size));
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

int
clientsocket_start() {
    assert(s_clientsocket);
    if (0 == s_clientsocket->pid) {
        pthread_create(&s_clientsocket->pid, NULL, (void*)clientsocket_networkprocess, NULL);
    }
    return 0;
}

int
clientsocket_stop() {
}

