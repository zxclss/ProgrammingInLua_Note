## C 语言中的用户自定义类型

### 笔记

**用户数据（Userdata）**
 - 概念：在C侧携带任意二进制块，让Lua把它当成一种新“值”。分为“完全用户数据（full userdata）”与“轻量级用户数据（light userdata）”。
 - 完全用户数据：由Lua分配与回收其“外层块”；可各自拥有独立元表与用户值（uservalue）。适合封装C结构体、句柄等。
 - 创建：
   - Lua 5.3/5.4：`void* p = lua_newuserdatauv(L, size, nuvalues);`，随后可 `lua_setiuservalue(L, idx, i)` 绑定第 `i` 个用户值。
   - 旧版：`void* p = lua_newuserdata(L, size);`（无多用户值）。
 - 设定类型与方法：
   - 首次：`luaL_newmetatable(L, "MyType");` 填入元方法与方法表；之后 `lua_pop(L, 1)`。
   - 关联：`luaL_setmetatable(L, "MyType");` 把元表绑到栈顶那个userdata。
   - 取回并校验：`My* self = (My*)luaL_checkudata(L, 1, "MyType");`
 - 资源回收：
   - 完全用户数据的“外层内存”由Lua自动释放；若内部还持有额外资源（malloc内存、文件句柄、socket等），用 `__gc` 释放。
 - 最小示例（二维向量）：
```c
#include <lua.h>
#include <lauxlib.h>

typedef struct { double x, y; } Vec2;

static int vec2_new(lua_State *L) {
  double x = luaL_optnumber(L, 1, 0.0);
  double y = luaL_optnumber(L, 2, 0.0);
  Vec2 *v = (Vec2*)lua_newuserdatauv(L, sizeof(Vec2), 0);
  v->x = x; v->y = y;
  luaL_setmetatable(L, "Vec2");
  return 1;
}

static int vec2_tostring(lua_State *L) {
  Vec2 *v = (Vec2*)luaL_checkudata(L, 1, "Vec2");
  lua_pushfstring(L, "Vec2(%f,%f)", v->x, v->y);
  return 1;
}
```

**元表（Metatable）**
 - 用途：赋予userdata运算与属性语义（方法派发、字符串化、比较、索引、回收等）。
 - 常用元方法：`__index`、`__newindex`、`__tostring`、`__len`、`__eq`、`__lt`、`__le`、`__gc`、`__pairs`（依需要）。
 - 典型注册流程：
```c
static int vec2_add(lua_State *L) {
  Vec2 *a = (Vec2*)luaL_checkudata(L, 1, "Vec2");
  Vec2 *b = (Vec2*)luaL_checkudata(L, 2, "Vec2");
  Vec2 *r = (Vec2*)lua_newuserdatauv(L, sizeof(Vec2), 0);
  r->x = a->x + b->x; r->y = a->y + b->y;
  luaL_setmetatable(L, "Vec2");
  return 1;
}

static int vec2_len(lua_State *L) {
  Vec2 *v = (Vec2*)luaL_checkudata(L, 1, "Vec2");
  lua_pushnumber(L, v->x*v->x + v->y*v->y);
  return 1;
}

static const luaL_Reg vec2_methods[] = {
  {"__tostring", vec2_tostring},
  {"__add",      vec2_add},
  {"__len",      vec2_len},
  {NULL, NULL}
};

static void create_vec2_mt(lua_State *L) {
  if (luaL_newmetatable(L, "Vec2")) {
    luaL_setfuncs(L, vec2_methods, 0);
    // 方法表：__index = methods
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
  }
  lua_pop(L, 1);
}
```
 - 注意：`__gc` 仅用于释放“外部资源”；userdata本体内存由Lua释放，不需要手动 `free` 该块。

**面向对象访问**
 - Lua侧调用 `obj:method(a,b)` 等价于 `obj.method(obj, a, b)`；实现要点是将“方法表”挂在metatable的 `__index` 上。
 - 典型方法：
```c
static int vec2_scale(lua_State *L) {
  Vec2 *v = (Vec2*)luaL_checkudata(L, 1, "Vec2");
  double k = luaL_checknumber(L, 2);
  v->x *= k; v->y *= k;
  lua_settop(L, 1); // 返回 self
  return 1;
}

static const luaL_Reg vec2_objmethods[] = {
  {"scale", vec2_scale},
  {NULL, NULL}
};

static void add_vec2_objmethods(lua_State *L) {
  luaL_getmetatable(L, "Vec2");
  luaL_setfuncs(L, vec2_objmethods, 0); // 添加到 __index（上面已设置 __index=metatable 本身）
  lua_pop(L, 1);
}
```
 - 可选：也可将方法表单独创建为普通表，把它赋给 `__index`，避免把元方法和对象方法混在一个表里。

**数组访问**
 - 思路：在 `__index`/`__newindex` 中根据键的类型分派：若为整数，按数组访问；若为字符串，走方法/属性。
 - 变长数组布局（头部+柔性数组）：
```c
typedef struct { size_t len; double data[1]; } DArray; // C99中可用 data[]

static int darr_new(lua_State *L) {
  lua_Integer n = luaL_checkinteger(L, 1);
  luaL_argcheck(L, n >= 0, 1, "len must be non-negative");
  size_t size = sizeof(DArray) + (size_t)(n > 0 ? (n-1) : 0) * sizeof(double);
  DArray *a = (DArray*)lua_newuserdatauv(L, size, 0);
  a->len = (size_t)n;
  for (size_t i = 0; i < a->len; ++i) a->data[i] = 0.0;
  luaL_setmetatable(L, "DArray");
  return 1;
}

static int darr_index(lua_State *L) {
  DArray *a = (DArray*)luaL_checkudata(L, 1, "DArray");
  if (lua_isinteger(L, 2)) {
    lua_Integer i = lua_tointeger(L, 2);
    luaL_argcheck(L, 1 <= i && (size_t)i <= a->len, 2, "index out of range");
    lua_pushnumber(L, a->data[i-1]);
    return 1;
  }
  // 其他键走方法表
  luaL_getmetatable(L, "DArray");
  lua_getfield(L, -1, "__index");
  lua_remove(L, -2);
  lua_pushvalue(L, 2);
  lua_rawget(L, -2);
  return 1;
}

static int darr_newindex(lua_State *L) {
  DArray *a = (DArray*)luaL_checkudata(L, 1, "DArray");
  lua_Integer i = luaL_checkinteger(L, 2);
  lua_Number v = luaL_checknumber(L, 3);
  luaL_argcheck(L, 1 <= i && (size_t)i <= a->len, 2, "index out of range");
  a->data[i-1] = (double)v;
  return 0;
}

static const luaL_Reg darr_methods[] = {
  {"__index",    darr_index},
  {"__newindex", darr_newindex},
  {NULL, NULL}
};
```
 - 可配 `__len` 返回 `len`，以及只读/只写策略。

**轻量级用户数**
 - 含义：只存放一个裸 `void*` 指针值，不分配外层块，不能携带用户值；生命周期由C侧管理，Lua不会回收目标对象。
 - 元表：所有轻量userdata共享同一个元表；设置它会影响全部轻量userdata（一般不建议修改全局行为）。
 - 用途：作为注册表（registry）的键或句柄占位符；配合强引用/弱表映射到完整对象。
 - 示例：
```c
static const char REGKEY[] = "mylib.instance";

// 存：registry[ lightud(ptr) ] = full_userdata
lua_pushlightuserdata(L, (void*)ptr);
lua_pushvalue(L, -2);
lua_rawset(L, LUA_REGISTRYINDEX);

// 取：push registry[ lightud(ptr) ]
lua_pushlightuserdata(L, (void*)ptr);
lua_rawget(L, LUA_REGISTRYINDEX);
```

### 练习


练习 31.1

练习 31.2

练习 31.3

练习 31.4