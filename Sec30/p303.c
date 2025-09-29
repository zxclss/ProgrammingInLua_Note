#include <lua.h>
#include <lauxlib.h>

// transliterate(s, map): for each byte in s, look up map[char]
// - if value is a string, replace by that string
// - if value is false or nil, drop the byte
// - otherwise, keep the original byte
static int l_transliterate(lua_State *L) {
    size_t s_len;
    const char *s = luaL_checklstring(L, 1, &s_len);
    luaL_checktype(L, 2, LUA_TTABLE);

    luaL_Buffer b;
    luaL_buffinit(L, &b);

    for (size_t i = 0; i < s_len; ++i) {
        unsigned char ch = (unsigned char)s[i];

        // key = one-byte string
        char key = (char)ch;
        lua_pushlstring(L, &key, 1);
        lua_rawget(L, 2); // map[key]

        int t = lua_type(L, -1);
        if (t == LUA_TSTRING) {
            size_t repl_len;
            const char *repl = lua_tolstring(L, -1, &repl_len);
            luaL_addlstring(&b, repl, repl_len);
        } else if (t == LUA_TBOOLEAN && !lua_toboolean(L, -1)) {
            // false => drop
        } else if (t == LUA_TNIL) {
            // nil => keep original
            luaL_addchar(&b, (char)ch);
        } else {
            // any other value => keep original
            luaL_addchar(&b, (char)ch);
        }

        lua_pop(L, 1); // pop map[key]
    }

    luaL_pushresult(&b);
    return 1;
}

static const luaL_Reg p303_funcs[] = {
    {"transliterate", l_transliterate},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p303(lua_State *L) {
    luaL_newlib(L, p303_funcs);
    return 1;
}


