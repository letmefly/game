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

int clientsocket_connect(const char *ip, unsigned short port);

int clientsocket_start();

int clientsocket_recv(unsigned short *prototype, char *outdata, unsigned int *outsize);

int clientsocket_send(unsigned short prototype, const char *data, unsigned int size);

#endif /* defined(__test_clientsocket__clientsocket__) */
