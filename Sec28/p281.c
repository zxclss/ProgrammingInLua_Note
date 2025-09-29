/* 最简实现：从命令行读取 cnt，加载 p281.lua 并调用 Lua 的 f(cnt) */
#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(int argc, char **argv) {
  int cnt = (argc > 1) ? atoi(argv[1]) : 10;

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  if (luaL_dofile(L, "p281.lua")) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  lua_getglobal(L, "f");
  lua_pushinteger(L, cnt);
  if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  lua_close(L);
  return 0;
}
