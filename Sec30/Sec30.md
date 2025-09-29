## 编写 C 函数的技巧

### 笔记

**数组操作**
 - 表示：Lua中“数组”通常是表的整数键序列，约定从1开始。
 - 创建：`lua_createtable(L, narr, nrec)` 预分配数组/非数组部分，减少重分配。
 - 读写：
   - 读：`lua_rawgeti(L, idx, i)` 更快且不触发元方法；取值后用 `lua_tonumberx` 等转换。
   - 写：`lua_rawseti(L, idx, i)` 将栈顶值写入 `t[i]` 并弹出该值。
 - 长度：`luaL_len(L, idx)` 获取长度（考虑 `__len`）；若需要原生数组部分可用原语配合策略维护。
 - 遍历示例：
```c
#include <lua.h>
#include <lauxlib.h>

// sum(t): 对数组部分求和（忽略非数值与洞）
static int l_sum(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_Integer n = luaL_len(L, 1);
  double s = 0.0;
  for (lua_Integer i = 1; i <= n; ++i) {
    lua_rawgeti(L, 1, i);             // push t[i]
    if (lua_isnumber(L, -1)) s += lua_tonumber(L, -1);
    lua_pop(L, 1);                     // pop t[i]
  }
  lua_pushnumber(L, s);
  return 1;
}
```
 - 批量拷贝：`luaL_checkstack` 确保栈空间；批量 `lua_rawgeti`/`lua_rawseti` 可避免元方法与哈希冲突开销。

**字符串操作**
 - 读取：`const char* s = luaL_checklstring(L, idx, &len);` 得到只读指针与长度；Lua字符串不可变，绝不就地修改。
 - 构造：优先使用缓冲区API `luaL_Buffer`（自动增长、避免多次拼接开销）。
 - 常用流程：`luaL_buffinit` → 多次 `luaL_addlstring`/`luaL_addchar` → `luaL_pushresult` 推出最终字符串。
 - 示例（转大写）：
```c
#include <ctype.h>

static int l_upper(lua_State *L) {
  size_t len; const char *s = luaL_checklstring(L, 1, &len);
  luaL_Buffer b; luaL_buffinit(L, &b);
  for (size_t i = 0; i < len; ++i) {
    char c = (char)toupper((unsigned char)s[i]);
    luaL_addchar(&b, c);
  }
  luaL_pushresult(&b);
  return 1;
}
```
 - 子串/拼接：对多段内容用 `luaL_addvalue` 直接消耗栈顶字符串；避免在C侧做过多临时分配。

**在 C 函数中保存状态**

- 注册表
  - 全局隐蔽表，索引 `LUA_REGISTRYINDEX`；可用于跨调用/跨函数保存C数据或Lua对象的强引用。
  - `luaL_ref(L, LUA_REGISTRYINDEX)` 生成整数引用，稍后用 `lua_rawgeti` 取回；不用时 `luaL_unref` 释放，避免内存泄漏。
  - 以轻量userdata作为键：
```c
static const char KEY[] = "mylib.key";
// set: registry[&KEY] = value_on_top
lua_pushlightuserdata(L, (void*)KEY);
lua_pushvalue(L, -2);
lua_rawset(L, LUA_REGISTRYINDEX);
// get: push registry[&KEY]
lua_pushlightuserdata(L, (void*)KEY);
lua_rawget(L, LUA_REGISTRYINDEX);
```
- 上值
  - 用 `lua_pushcclosure(L, cfunc, nup)` 绑定 `nup` 个上值到C函数闭包；在函数内通过 `lua_upvalueindex(i)` 读取。
  - 适合存放常量、配置、预绑定表/函数引用等，无需查全局环境。
  - 示例（常量因子）：
```c
static int l_scale(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double k = lua_tonumber(L, lua_upvalueindex(1));
  lua_pushnumber(L, x * k);
  return 1;
}

static void push_scale(lua_State *L, double k) {
  lua_pushnumber(L, k);
  lua_pushcclosure(L, l_scale, 1); // 闭包捕获k
}
```
- 共享的上值
  - 多个闭包可共享同一上值（如共享的可变计数器/状态）。
  - 示例（计数器工厂）：
```c
static int l_inc(lua_State *L) {
  lua_Integer n = lua_tointeger(L, lua_upvalueindex(1));
  n += 1;
  lua_pushinteger(L, n);
  lua_pushvalue(L, -1);
  lua_replace(L, lua_upvalueindex(1)); // 更新共享上值
  return 1;
}

static int l_counter(lua_State *L) {
  lua_pushinteger(L, 0);            // 共享上值：计数
  lua_pushcclosure(L, l_inc, 1);    // 返回一个闭包
  return 1;
}
```
  - 若需要多个函数共享同一状态，可在入栈多个函数前先依次压入同一批上值，再分别 `lua_pushcclosure`。

### 练习

练习 30.1

```c
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
```

练习 30.2

```c
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
```

练习 30.3

```c
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
```