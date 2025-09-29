#include <lua.h>
#include <lauxlib.h>

// foreach(t, f): for each key-value pair in table t, call f(key, value)
static int l_foreach(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    lua_pushnil(L); // first key
    while (lua_next(L, 1) != 0) {
        // initial stack per iteration: table(1), function(2), key(-2), value(-1)
        lua_pushvalue(L, 2);    // push function copy -> now top is func, key at -3, value at -2
        lua_pushvalue(L, -3);   // push key
        lua_pushvalue(L, -3);   // push value (after pushing key, value shifts to -3)
        lua_call(L, 2, 0);      // call f(key, value)
        lua_pop(L, 1);          // pop value, keep key for lua_next
    }

    return 0;
}

static const luaL_Reg p294_funcs[] = {
    {"foreach", l_foreach},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p294(lua_State *L) {
    luaL_newlib(L, p294_funcs);
    return 1;
}

