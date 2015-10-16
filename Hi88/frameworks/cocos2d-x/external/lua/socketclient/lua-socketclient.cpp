//
//  lua-socketclient.c
//  cocos2d_lua_bindings
//
//  Created by li on 15/10/16.
//
//
#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#include "SocketClient.h"

static int _connectServer(lua_State *L)
{
	const char * ip = luaL_checkstring(L, 1);
	int port = luaL_checkinteger(L, 2);
    int ret = SocketClient::getInstance()->connectServer(ip, port);
    lua_pushinteger(L, ret);
    return 1;
}


#ifdef __cplusplus
extern "C" {
#endif

int luaopen_socketclient(lua_State *L) {
	luaL_Reg reg[] = {
		{"connectServer" , _connectServer },
		{NULL,NULL},
	};

	//luaL_checkversion(L);
	luaL_newlib(L, reg);

	return 1;
}

#ifdef __cplusplus
}
#endif