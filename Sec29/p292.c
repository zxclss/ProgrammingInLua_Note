#include <lua.h>
#include <lauxlib.h>

// pack(...): returns a table with array part {1=..., 2=..., ...} and field n = number of args
static int l_pack(lua_State *L) {
    int numArgs = lua_gettop(L);

    lua_createtable(L, numArgs, 1);

    for (int i = 1; i <= numArgs; ++i) {
        lua_pushvalue(L, i);
        lua_seti(L, -2, i);
    }

    lua_pushinteger(L, numArgs);
    lua_setfield(L, -2, "n");

    return 1;
}

static const luaL_Reg p292_funcs[] = {
    {"pack", l_pack},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p292(lua_State *L) {
    luaL_newlib(L, p292_funcs);
    return 1;
}