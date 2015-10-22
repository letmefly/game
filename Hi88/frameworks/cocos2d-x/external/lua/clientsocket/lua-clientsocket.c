//
//  lua-clientsocket.c
//  cocos2d_lua_bindings
//
//  Created by li on 15/10/19.
//
//

#include "clientsocket.h"
#include "lua-clientsocket.h"
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>

#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define BUFFER_SIZE 0x10000


static int
lconnect(lua_State *L) {
	const char * addr = luaL_checkstring(L, 1);
	long port = luaL_checkinteger(L, 2);
    int ret = clientsocket_init(addr, (unsigned short)port);
    if (!ret) {
        clientsocket_start();
    }
    lua_pushinteger(L, ret);
    return 1;
}


static int
lsend(lua_State *L) {
    unsigned long sz = 0;
    long prototype = luaL_checkinteger(L, 1);
	const char *buffer = luaL_checklstring(L, 2, &sz);
    clientsocket_send((unsigned short)prototype, buffer, (unsigned int)sz);
	//free((void*)buffer);
	return 0;
}


static int
lrecv(lua_State *L) {
    unsigned short prototype = 0;
    unsigned int recvsize = BUFFER_SIZE;
    static char recvbuffer[BUFFER_SIZE];
    int r = clientsocket_recv(&prototype, recvbuffer, &recvsize);
    if (r <= 0) {
        lua_pushliteral(L, "");
        lua_pushliteral(L, "");
		lua_pushinteger(L, r);
		return 3;
    }
    lua_pushinteger(L, prototype);
    lua_pushlightuserdata(L, (void*)(recvbuffer));
	lua_pushinteger(L, recvsize);
    return 3;
}


int
luaopen_clientsocket(lua_State *L) {
	luaL_Reg l[] = {
		{ "connect", lconnect },
        { "send", lsend },
        { "recv", lrecv },
		{ NULL, NULL }
	};
//	luaL_newlib(L, l);
    luaL_register(L, "clientsocket", l);
    
    return 0;
}

