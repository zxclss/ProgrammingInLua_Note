#include <lua.h>
#include <lauxlib.h>

// reverse(...): returns all arguments in reverse order
static int l_reverse(lua_State *L) {
    int numArgs = lua_gettop(L);
    for (int i = numArgs; i >= 1; --i) {
        lua_pushvalue(L, i);
    }
    return numArgs;
}

static const luaL_Reg p293_funcs[] = {
    {"reverse", l_reverse},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p293(lua_State *L) {
    luaL_newlib(L, p293_funcs);
    return 1;
}

