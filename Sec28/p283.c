/*
   - 加载配置文件（默认 p283.lua，或从命令行指定）
   - 根据站点代码（argv[1]）查找 URL，查找顺序：
     1) 全局变量 _G[code]
     2) 全局表 stations[code]
     3) 全局函数 url_for(code)
   - 找到就打印 URL 并返回 0；未找到返回 1。
*/

#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int print_url_for_code(lua_State *L, const char *code) {
  // 1) 全局变量：_G[code]
  lua_getglobal(L, code);
  if (lua_isstring(L, -1)) {
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    return 1;
  }
  lua_pop(L, 1);

  // 2) 全局表：stations[code]
  lua_getglobal(L, "stations");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, code);
    if (lua_isstring(L, -1)) {
      printf("%s\n", lua_tostring(L, -1));
      lua_pop(L, 2); // value + table
      return 1;
    }
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // stations or nil

  // 3) 全局函数：url_for(code)
  lua_getglobal(L, "url_for");
  if (lua_isfunction(L, -1)) {
    lua_pushstring(L, code);
    if (lua_pcall(L, 1, 1, 0) == LUA_OK) {
      if (lua_isstring(L, -1)) {
        printf("%s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        return 1;
      }
      lua_pop(L, 1); // result (non-string)
    } else {
      // 调用错误，打印错误信息
      fprintf(stderr, "%s\n", lua_tostring(L, -1));
      lua_pop(L, 1);
    }
  }
  lua_pop(L, 1); // function or non-function

  return 0;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s CODE [config.lua]\n", argv[0]);
    return 2;
  }

  const char *code = argv[1];
  const char *config = (argc >= 3) ? argv[2] : "p283.lua";

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  if (luaL_dofile(L, config)) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  int found = print_url_for_code(L, code);
  lua_close(L);
  return found ? 0 : 1;
}