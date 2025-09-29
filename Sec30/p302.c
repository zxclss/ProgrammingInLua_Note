#include <lua.h>
#include <lauxlib.h>
#include <string.h>

// split(s, sep): split string s by single-byte separator sep (can be '\0')
// Returns an array-table of substrings; keeps empty fields between/at ends.
static int l_split(lua_State *L) {
    size_t s_len;
    const char *s = luaL_checklstring(L, 1, &s_len);

    size_t sep_len;
    const char *sep = luaL_optlstring(L, 2, " ", &sep_len);
    luaL_argcheck(L, sep_len == 1, 2, "separator must be a single byte");
    unsigned char sep_ch = (unsigned char)sep[0];

    lua_createtable(L, 0, 0);
    int result_index = lua_gettop(L);

    const char *cursor = s;
    size_t remaining = s_len;
    lua_Integer out_index = 1;

    while (1) {
        const void *found = memchr(cursor, sep_ch, remaining);
        if (found == NULL) break;

        size_t piece_len = (const char *)found - cursor;
        lua_pushlstring(L, cursor, piece_len);
        lua_seti(L, result_index, out_index++);

        size_t consumed = piece_len + 1; // skip separator
        cursor += consumed;
        remaining -= consumed;
    }

    // tail segment
    lua_pushlstring(L, cursor, remaining);
    lua_seti(L, result_index, out_index++);

    return 1;
}

static const luaL_Reg p302_funcs[] = {
    {"split", l_split},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p302(lua_State *L) {
    luaL_newlib(L, p302_funcs);
    return 1;
}


