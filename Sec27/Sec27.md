## 27 C语言API总览

### 笔记

最小宿主程序（创建 `lua_State`、加载标准库、执行一段 Lua 代码）：

```c
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
```

**栈**

Lua C API 通过一条“虚拟栈”与 C 交互：

- **索引**：正索引从栈底 1 开始；负索引从栈顶 -1 开始。
- **协定**：C 函数从栈上取参数、向栈上压返回值；返回值个数由 C 函数返回的整数给出。
- **不变量**：调用 API 前后，明确栈平衡（谁压入、谁弹出）。

**压入元素**

- **基本类型**：
  - `lua_pushnil(L)`
  - `lua_pushboolean(L, b)`
  - `lua_pushinteger(L, i)` / `lua_pushnumber(L, n)`
  - `lua_pushlstring(L, s, len)` / `lua_pushstring(L, s)`
- **表/函数/用户数据**：
  - `lua_newtable(L)` / `lua_createtable(L, narr, nrec)`
  - `lua_pushcfunction(L, f)` / `lua_pushcclosure(L, f, nup)`
  - `lua_newuserdata(L, sz)`  (5.4 为 `lua_newuserdatauv`)
- **辅助**：
  - `lua_pushvalue(L, idx)` 复制指定位置的值入栈

示例：构造一个表 `{x=10, y=true}` 并设为全局 `pt`：

```c
lua_newtable(L);                  // {..., tbl}
lua_pushinteger(L, 10);           // {..., tbl, 10}
lua_setfield(L, -2, "x");         // tbl.x = 10  => {..., tbl}
lua_pushboolean(L, 1);            // {..., tbl, true}
lua_setfield(L, -2, "y");         // tbl.y = true
lua_setglobal(L, "pt");           // _G.pt = tbl（并弹出 tbl）
```

**查询元素**

- **类型判断**：`lua_type(L, idx)` / `lua_typename(L, t)`；快捷：`lua_isnumber`、`lua_istable`、`lua_isstring`、`lua_isfunction` 等。
- **取值转换**：
  - 宽松：`lua_tointeger(L, idx)`、`lua_tonumber(L, idx)`、`lua_tostring(L, idx)`（可能做隐式转换）。
  - 严格：`lua_tointegerx(L, idx, &ok)`、`lua_tonumberx(L, idx, &ok)`（返回是否成功）。

示例：从栈顶安全取整数：

```c
int ok = 0;
lua_Integer v = lua_tointegerx(L, -1, &ok);
if (!ok) luaL_error(L, "expected integer");
```

**其他栈操作**

- **栈高度**：`lua_gettop(L)`、`lua_settop(L, idx)`；`lua_pop(L, n)` 宏等价于 `lua_settop(L, -(n)-1)`。
- **索引变换**：`lua_absindex(L, idx)` 将相对索引转为绝对索引。
- **重排**：`lua_remove(L, idx)`、`lua_insert(L, idx)`、`lua_replace(L, idx)`、`lua_rotate(L, idx, n)`。
- **容量**：`lua_checkstack(L, n)` 预留栈空间。
- **长度**：`lua_len(L, idx)` 将长度结果压栈；`lua_rawlen(L, idx)` 返回 `size_t`。

常用习惯用法：

```c
int base = lua_gettop(L);          // 记录调用前栈顶
// ... 期间可随意压入/弹出 ...
lua_settop(L, base);               // 恢复栈
```

**使用C API进行错误处理**

处理应用代码中的错误

- **关键区别**：`lua_call` 会抛出长跳转，C 端无法捕获；`lua_pcall` （protected call）将错误留在栈顶并返回状态码。
- **建议**：宿主应用一律使用 `lua_pcall`，并提供消息处理函数生成堆栈回溯。

示例：带回溯的安全调用：

```c
static int msgh(lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  luaL_traceback(L, L, msg, 1);
  return 1; // 将 traceback 字符串作为新的错误消息
}

int safe_pcall(lua_State *L, int nargs, int nres) {
  int base = lua_gettop(L) - nargs;   // 函数位置
  lua_pushcfunction(L, msgh);         // 压入消息处理函数
  lua_insert(L, base);                // 放到函数之前
  int status = lua_pcall(L, nargs, nres, base);
  lua_remove(L, base);                // 移除消息处理函数
  return status;                      // LUA_OK / 错误码
}
```

处理库代码中的错误

- **参数检查**：`luaL_check*` / `luaL_opt*`（失败时自动 `luaL_error`）：
  - `luaL_checkinteger(L, idx)`、`luaL_checknumber(L, idx)`、`luaL_checkstring(L, idx)`
  - `luaL_optinteger(L, idx, d)`、`luaL_optnumber(L, idx, d)`、`luaL_optstring(L, idx, d)`
- **显式报错**：`luaL_error(L, "message ...")` 或 `luaL_argerror(L, idx, "msg")`。

示例：一个简单库函数 `add(x, y)`：

```c
static int l_add(lua_State *L) {
  lua_Integer x = luaL_checkinteger(L, 1);
  lua_Integer y = luaL_checkinteger(L, 2);
  lua_pushinteger(L, x + y);
  return 1;
}

int luaopen_mylib(lua_State *L) {
  luaL_Reg lib[] = {
    {"add", l_add},
    {NULL, NULL}
  };
  luaL_newlib(L, lib);
  return 1;
}
```

**内存分配**

- `luaL_newstate()` 使用默认分配器；`lua_newstate(alloc, ud)` 可提供自定义分配器以统计/限流。
- 分配器原型：`void *alloc(void *ud, void *ptr, size_t osz, size_t nsz)`：
  - `nsz == 0` 表示释放；否则应返回新内存（可 `realloc`）。
  - 返回 `NULL` 代表分配失败（Lua 会抛出内存错误）。
- 可结合 `lua_gc(L, LUA_GC* ...)` 控制 GC（如 `LUA_GCCOLLECT` 触发一次完整回收）。

示例：带“软上限”的分配器：

```c
typedef struct { size_t used, limit; } MemStat;

static void *lim_alloc(void *ud, void *ptr, size_t osz, size_t nsz) {
  MemStat *ms = (MemStat*)ud;
  if (nsz == 0) {                     // free
    ms->used -= osz;
    free(ptr);
    return NULL;
  }
  if (ptr == NULL) {                  // malloc
    if (ms->limit && ms->used + nsz > ms->limit) return NULL;
    void *np = malloc(nsz);
    if (np) ms->used += nsz;
    return np;
  } else {                            // realloc
    if (ms->limit && ms->used - osz + nsz > ms->limit) return NULL;
    void *np = realloc(ptr, nsz);
    if (np) ms->used = ms->used - osz + nsz;
    return np;
  }
}

// 使用：
// MemStat ms = {0, 32 * 1024 * 1024};
// lua_State *L = lua_newstate(lim_alloc, &ms);
```

### 练习

练习 27.1

```c
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
```

练习 27.2

```c
lua_pushnumber(L, 3.5):
[3.5]
lua_pushstring(L, " hello "):
[3.5, " hello "]
lua_pushnil(L):
[3.5, " hello ", nil]
lua_rotate(L, 1, -1)  // 把索引1的元素旋到栈顶
[" hello ", nil, 3.5]
lua_pushvalue(L, -2)  // 复制倒数第二个元素（nil）
[" hello ", nil, 3.5, nil]
lua_remove(L, 1)      // 移除底部的 " hello "
[nil, 3.5, nil]
lua_insert(L, -2)     // 把栈顶元素插入到倒数第二个位置
[nil, nil, 3.5]
```

练习 27.3

```c
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
```

```bash
after lua_pushnumber(L, 3.5): [3.5]
after lua_pushstring(L, " hello " ): [3.5, " hello "]
after lua_pushnil(L): [3.5, " hello ", nil]
after lua_rotate(L, 1, -1): [" hello ", nil, 3.5]
after lua_pushvalue(L, -2): [" hello ", nil, 3.5, nil]
after lua_remove(L, 1): [nil, 3.5, nil]
after lua_insert(L, -2): [nil, nil, 3.5]
```

练习 27.4

```c
// 请编写一个库，该库允许一个脚本限制其 Lua 状态能够使用的总内存大小。该库可能仅提供一个函数setlimit，用来设置限制值。
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>

typedef struct {
    lua_Alloc original_alloc;
    void *original_ud;
    size_t used_bytes;
    size_t limit_bytes; // 0 表示不限制
} MemoryLimit;

static void *limit_alloc(void *ud, void *ptr, size_t old_size, size_t new_size) {
    MemoryLimit *ml = (MemoryLimit *)ud;

    if (new_size == 0) { // free
        void *ret = ml->original_alloc(ml->original_ud, ptr, old_size, 0);
        ml->used_bytes = (ml->used_bytes >= old_size) ? (ml->used_bytes - old_size) : 0;
        return ret; // 按约定返回 NULL
    }

    if (ptr == NULL) { // malloc
        if (ml->limit_bytes && ml->used_bytes + new_size > ml->limit_bytes) return NULL;
        void *ret = ml->original_alloc(ml->original_ud, NULL, 0, new_size);
        if (ret) ml->used_bytes += new_size;
        return ret;
    }

    // realloc
    size_t next_used = ml->used_bytes - (old_size <= ml->used_bytes ? old_size : ml->used_bytes) + new_size;
    if (ml->limit_bytes && next_used > ml->limit_bytes) return NULL;
    void *ret = ml->original_alloc(ml->original_ud, ptr, old_size, new_size);
    if (ret) ml->used_bytes = next_used;
    return ret;
}

// memlimit.setlimit(limit_bytes)
static int l_setlimit(lua_State *L) {
    lua_Integer limit = luaL_checkinteger(L, 1);
    if (limit < 0) limit = 0;

    void *cur_ud = NULL;
    lua_Alloc cur_alloc = lua_getallocf(L, &cur_ud);

    if (cur_alloc == limit_alloc) {
        ((MemoryLimit *)cur_ud)->limit_bytes = (size_t)limit;
        return 0;
    }

    MemoryLimit *ml = (MemoryLimit *)malloc(sizeof(MemoryLimit));
    if (!ml) return luaL_error(L, "memlimit: out of memory");
    ml->original_alloc = cur_alloc;
    ml->original_ud = cur_ud;
    ml->used_bytes = 0;        // 仅统计启用后的增量
    ml->limit_bytes = (size_t)limit;
    lua_setallocf(L, limit_alloc, ml);
    return 0;
}

static const luaL_Reg lib[] = {
    {"setlimit", l_setlimit},
    {NULL, NULL}
};

int luaopen_memlimit(lua_State *L) {
    luaL_newlib(L, lib);
    return 1;
}
```