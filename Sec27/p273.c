// 使用函数 stackDump 检查上一道题的答案
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static void stackDump(lua_State *L) {
    int top = lua_gettop(L);
    printf("[");
    for (int i = 1; i <= top; i++) {
        int t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING:
                printf("\"%s\"", lua_tostring(L, i));
                break;
            case LUA_TBOOLEAN:
                printf(lua_toboolean(L, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:
                printf("%g", lua_tonumber(L, i));
                break;
            default:
                printf("%s", lua_typename(L, t));
                break;
        }
        if (i < top) printf(", ");
    }
    printf("]\n");
}

int main(void) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    // 初始：[]
    printf("after lua_pushnumber(L, 3.5): ");
    lua_pushnumber(L, 3.5);
    stackDump(L);

    printf("after lua_pushstring(L, \" hello \" ): ");
    lua_pushstring(L, " hello ");
    stackDump(L);

    printf("after lua_pushnil(L): ");
    lua_pushnil(L);
    stackDump(L);

    printf("after lua_rotate(L, 1, -1): ");
    lua_rotate(L, 1, -1);
    stackDump(L);

    printf("after lua_pushvalue(L, -2): ");
    lua_pushvalue(L, -2);
    stackDump(L);

    printf("after lua_remove(L, 1): ");
    lua_remove(L, 1);
    stackDump(L);

    printf("after lua_insert(L, -2): ");
    lua_insert(L, -2);
    stackDump(L);

    lua_close(L);
    return 0;
}