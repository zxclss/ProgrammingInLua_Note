## 扩展应用

### 笔记

- 场景：一个 C 应用带有窗口，需要从配置文件读取窗口初始大小等信息。
- 决定使用一个 Lua 配置文件（普通文本文件，同时也是可执行的 Lua 程序）。
- 目标：加载 `config.lua`，读取全局变量与表字段，设置默认值，给出健壮的类型检查与错误信息。

示例配置文件 `config.lua`（最简单形式）：

```lua
-- 窗口尺寸（像素）
width  = 800
height = 600

-- 窗口标题
title = "Lua Powered Window"

-- 背景色：既可用名字，也可用表
-- background = "blue"
background = { r = 0.2, g = 0.3, b = 0.4 }   -- 0..1 浮点
```

**读取配置（全局变量）**，即读取 `_G.width/_G.height/_G.title`，并支持默认值：

```c
typedef struct {
  int   width;
  int   height;
  char  title[128];
  float bg[3];   // r,g,b in [0,1]
} Options;

static int getglobalint(lua_State *L, const char *name, int dflt) {
  int v = dflt;
  lua_getglobal(L, name);
  if (lua_isinteger(L, -1)) v = (int)lua_tointeger(L, -1);
  lua_pop(L, 1);
  return v;
}

static const char *getglobalstring(lua_State *L, const char *name, const char *dflt) {
  const char *s = dflt;
  lua_getglobal(L, name);
  if (lua_isstring(L, -1)) s = lua_tostring(L, -1);
  lua_pop(L, 1);
  return s;
}
```

**颜色解析（字符串或表）**，即支持 `background = "blue"` 或 `background = { r=0.2, g=0.3, b=0.4 }`：

```c
typedef struct { const char *name; float r, g, b; } NamedColor;

static const NamedColor NAMED[] = {
  {"black", 0.0f, 0.0f, 0.0f},
  {"white", 1.0f, 1.0f, 1.0f},
  {"red",   1.0f, 0.0f, 0.0f},
  {"green", 0.0f, 1.0f, 0.0f},
  {"blue",  0.0f, 0.0f, 1.0f},
};

static int match_named_color(const char *s, float out[3]) {
  for (size_t i = 0; i < sizeof(NAMED)/sizeof(NAMED[0]); i++) {
    if (strcmp(NAMED[i].name, s) == 0) {
      out[0] = NAMED[i].r; out[1] = NAMED[i].g; out[2] = NAMED[i].b;
      return 1;
    }
  }
  return 0;
}

static int read_color(lua_State *L, int idx, float out[3]) {
  idx = lua_absindex(L, idx);
  if (lua_isstring(L, idx)) {
    const char *name = lua_tostring(L, idx);
    if (!match_named_color(name, out)) return 0; // 未识别
    return 1;
  }
  if (lua_istable(L, idx)) {
    lua_getfield(L, idx, "r"); out[0] = (float)luaL_checknumber(L, -1); lua_pop(L, 1);
    lua_getfield(L, idx, "g"); out[1] = (float)luaL_checknumber(L, -1); lua_pop(L, 1);
    lua_getfield(L, idx, "b"); out[2] = (float)luaL_checknumber(L, -1); lua_pop(L, 1);
    return 1;
  }
  return 0;
}
```

**完整示例：加载并解析配置**

```c
static void load_config(lua_State *L, const char *filename, Options *opt) {
  // 默认值
  opt->width  = 640;
  opt->height = 480;
  strcpy(opt->title, "My App");
  opt->bg[0] = 0.0f; opt->bg[1] = 0.0f; opt->bg[2] = 0.0f;

  if (luaL_loadfile(L, filename) || lua_pcall(L, 0, 0, 0)) {
    fprintf(stderr, "cannot run %s: %s\n", filename, lua_tostring(L, -1));
    lua_pop(L, 1);
    return; // 使用默认
  }

  // width/height/title
  opt->width  = getglobalint(L, "width",  opt->width);
  opt->height = getglobalint(L, "height", opt->height);
  const char *title = getglobalstring(L, "title", opt->title);
  strncpy(opt->title, title, sizeof(opt->title) - 1);
  opt->title[sizeof(opt->title) - 1] = '\0';

  // background
  lua_getglobal(L, "background");
  if (!lua_isnil(L, -1)) {
    float col[3];
    if (read_color(L, -1, col)) {
      opt->bg[0] = col[0]; opt->bg[1] = col[1]; opt->bg[2] = col[2];
    } else {
      fprintf(stderr, "invalid 'background' (string name or table {r,g,b} expected)\n");
    }
  }
  lua_pop(L, 1);
}

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  Options opt;
  load_config(L, "config.lua", &opt);

  printf("width=%d height=%d title=%s bg=(%.2f,%.2f,%.2f)\n",
         opt.width, opt.height, opt.title, opt.bg[0], opt.bg[1], opt.bg[2]);

  lua_close(L);
  return 0;
}
```

### 练习

练习 28.1

```c
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
```

练习 28.2

```c
// 修改函数 call_va （见示例 28.5 ）来处理布尔类型的值
#include <stdarg.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>

void call_va(lua_State *L, const char *func, const char *sig, ...)
{
    va_list vl;
    int narg = 0;
    int nres = 0;

    va_start(vl, sig);
    lua_getglobal(L, func);

    // push arguments according to 'sig' until '>'
    while (*sig && *sig != '>') {
        // ensure stack space for the next argument
        luaL_checkstack(L, 1, "too many arguments");
        switch (*sig++) {
            case 'd':
                lua_pushnumber(L, va_arg(vl, double));
                break;
            case 'i':
                lua_pushinteger(L, va_arg(vl, int));
                break;
            case 's':
                lua_pushstring(L, va_arg(vl, const char *));
                break;
            case 'b':
                // boolean argument (C int expected)
                lua_pushboolean(L, va_arg(vl, int));
                break;
            default:
                error(L, "invalid option (%c)", *(sig - 1));
        }
        narg++;
    }

    // skip the '>' if present
    if (*sig == '>') sig++;

    // number of expected results is the length of the remaining signature
    nres = (int)strlen(sig);

    if (lua_pcall(L, narg, nres, 0) != 0) {
        error(L, "error calling '%s': %s", func, lua_tostring(L, -1));
    }

    // retrieve results
    int resIndex = -nres; // first result index
    while (*sig) {
        switch (*sig++) {
            case 'd': {
                double *pd = va_arg(vl, double *);
                *pd = lua_tonumber(L, resIndex);
                break;
            }
            case 'i': {
                int *pi = va_arg(vl, int *);
                *pi = (int)lua_tointeger(L, resIndex);
                break;
            }
            case 's': {
                const char **ps = va_arg(vl, const char **);
                *ps = lua_tostring(L, resIndex);
                break;
            }
            case 'b': {
                // boolean result (C int* expected)
                int *pb = va_arg(vl, int *);
                *pb = lua_toboolean(L, resIndex);
                break;
            }
            default:
                error(L, "invalid option (%c)", *(sig - 1));
        }
        resIndex++;
    }

    va_end(vl);
}
```

练习 28.3

```c
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
```