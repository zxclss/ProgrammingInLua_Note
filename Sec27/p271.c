// 编译并运行简单的独立运行的解释器(示例 27.1)
#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(void) {
    char buff[256];
    int error;
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);                    // 打开标准库

    while (fget(buff, sizeof(buff), stdin) != NULL)
    {
        error = luaL_loadstring(L, buff) || lua_pcall(L, 0, 0, 0);
        if (error)
        {
            fprintf(stderror, "%s\n", lua_tostring(L, -1));
            lua_pop(L, 1);
        }
    }

    lua_close(L);
    return 0;
}