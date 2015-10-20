
#include "lua_extensions.h"

#if __cplusplus
extern "C" {
#endif
// socket
#include "luasocket/luasocket.h"
#include "luasocket/luasocket_scripts.h"
#include "luasocket/mime.h"

// lfs
#include "lfs/lfs.h"

// cjson
#include "cjson/cjson.h"

// zlib
#include "zlib/lua_zlib.h"

// md5
#include "md5/md5.h"

// protobuf-lua
extern int luaopen_protobuf_c(lua_State *L);

// socketclient
extern int luaopen_clientsocket(lua_State *L);

// lpeg
extern int luaopen_lpeg (lua_State *L);

static luaL_Reg luax_exts[] = {
    //{"socket.core", luaopen_socket_core},
    {"mime.core", luaopen_mime_core},
    {"lpeg", luaopen_lpeg},
    {"lfs", luaopen_lfs},
    {"cjson", luaopen_cjson},
    {"zlib", luaopen_zlib},
    {"md5.core", luaopen_md5_core},
    {"protobuf.c", luaopen_protobuf_c},
    {"clientsocket", luaopen_clientsocket},
    {NULL, NULL}
};

void luaopen_lua_extensions(lua_State *L)
{
    // load extensions
    luaL_Reg* lib = luax_exts;
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lua_pushcfunction(L, lib->func);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);

    luaopen_luasocket_scripts(L);
}

#if __cplusplus
} // extern "C"
#endif
