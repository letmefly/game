//
//  clientsocket.h
//  test_clientsocket
//
//  Created by chris li on 15/10/16.
//  Copyright (c) 2015年 chris li. All rights reserved.
//

#ifndef __test_clientsocket__clientsocket__
#define __test_clientsocket__clientsocket__

#include <stdio.h>

enum connect_status {
    STATUS_NOT_CONNECT,
    STATUS_CONNECTING,
    STATUS_CONNECT_OK,
    STATUS_CONNECT_FAIL,
    STATUS_DISCONNECT
};

int clientsocket_init(const char *ip, unsigned short port);

int clientsocket_start();

int clientsocket_stop();

int clientsocket_recv(unsigned short *prototype, char *outdata, unsigned int *outsize);

int clientsocket_send(unsigned short prototype, const char *data, unsigned int size);

int clientsocket_connectstatus();

int clientsocket_reconnect();

#endif /* defined(__test_clientsocket__clientsocket__) */
