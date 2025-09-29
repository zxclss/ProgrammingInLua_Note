#include <lua.h>
#include <lauxlib.h>

// filter(list, predicate): returns a new list with elements where predicate(elem) is truthy
static int l_filter(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    lua_newtable(L); // result table
    int resultIndex = lua_gettop(L);

    lua_Integer outIndex = 1;
    lua_Integer n = (lua_Integer)lua_rawlen(L, 1);

    for (lua_Integer i = 1; i <= n; ++i) {
        // call predicate(list[i])
        lua_pushvalue(L, 2);           // push predicate function
        lua_geti(L, 1, i);             // push list[i]
        lua_call(L, 1, 1);             // call predicate(elem) -> returns one value

        int pass = lua_toboolean(L, -1);
        lua_pop(L, 1);                 // pop predicate result

        if (pass) {
            lua_geti(L, 1, i);         // push original element again
            lua_seti(L, resultIndex, outIndex++); // result[outIndex] = elem
        }
    }

    return 1; // return result table
}

static const luaL_Reg p301_funcs[] = {
    {"filter", l_filter},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p301(lua_State *L) {
    luaL_newlib(L, p301_funcs);
    return 1;
}


