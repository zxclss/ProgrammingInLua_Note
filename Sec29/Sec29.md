## 在 Lua 中调用 C 语言

### 笔记

**C函数**
 - 形态：C函数必须符合签名 `int f(lua_State *L)`，通过栈与Lua交换数据；返回值是“返回给Lua的结果数量”。
 - 栈约定：
   - 参数自栈底到栈顶依次入栈，索引从1开始；负索引从栈顶往下（`-1`为栈顶）。
   - 用 `lua_gettop(L)` 得到参数个数；读取用 `lua_tonumberx`、`lua_tostring`、`lua_is*` 等。
   - 传参回Lua用 `lua_push*` 系列（如 `lua_pushnumber`、`lua_pushstring`、`lua_pushboolean`）。
 - 参数校验：优先使用 `luaL_check*`/`luaL_opt*`，失败时会抛Lua错误并带栈追踪。
 - 错误：在C中调用 `luaL_error(L, "msg")` 抛出Lua层错误；不要返回负数作为错误。
 - Upvalues与闭包：用 `lua_pushcclosure(L, cfunc, nup)` 绑定 `nup` 个upvalues；在 `cfunc` 内通过 `lua_upvalueindex(i)` 访问。
 - 注册函数：
   - 单个：`lua_pushcfunction(L, cfunc); lua_setglobal(L, "fname");`
   - 批量：定义 `luaL_Reg lib[] = { {"fname", cfunc}, {NULL, NULL} };`，再 `luaL_setfuncs(L, lib, 0)` 或 `luaL_newlib(L, lib)` 创建表。
 - 简单示例：
```c
#include <lua.h>
#include <lauxlib.h>

static int l_add(lua_State *L) {
  double a = luaL_checknumber(L, 1);
  double b = luaL_checknumber(L, 2);
  lua_pushnumber(L, a + b);
  return 1; // 返回1个结果
}
```
**延续（Continuation）**
 - 背景：默认C函数是不可让出的（non-yieldable）。若需要在C里让出协程并异步恢复，需要使用“延续K函数（continuation）”接口。
 - 关键API：
   - 受保护调用：`lua_pcallk(L, nargs, nresults, errfunc, ctx, k)`；普通调用：`lua_callk(L, nargs, nresults, ctx, k)`。
   - 让出：`lua_yieldk(L, nresults, ctx, k)`；恢复时会调用 `k(L, LUA_OK, ctx)`，继续执行。
 - 使用要点：
   - 将进度通过 `ctx`（整数）或upvalues/registry保存；避免依赖C栈局部变量。
   - 写成“状态机”：首次进入从入口逻辑；让出后恢复改走 `k` 分支。
 - 兼容性：Lua 5.1 没有 `*k` 变体与 `lua_yieldk`；5.1中C函数基本不可yield（需LuaJIT/协作方案）。
 - 极简示例（结构示意）：
```c
static int cont(lua_State *L, int status, lua_KContext ctx) {
  // 恢复后的续体：栈已有先前yield返回的值
  // ... 继续处理，最终 push 结果并 return n
  return 1;
}

static int l_async(lua_State *L) {
  // 第一次进入：发起异步并让出
  // ... 发起IO ...
  return lua_yieldk(L, /*nresults=*/0, /*ctx=*/0, cont);
}
```
**C模块**
 - 结构：
   - 一个 `luaopen_modname(lua_State *L)` 的导出函数，返回模块表；Lua侧通过 `require "modname"` 调用它。
   - 用 `luaL_Reg` 列出导出函数，`luaL_newlib(L, reg)` 构造表并返回。
 - 5.3/5.4 推荐方式：
```c
#include <lua.h>
#include <lauxlib.h>

static int l_add(lua_State *L) { double a = luaL_checknumber(L,1); double b=luaL_checknumber(L,2); lua_pushnumber(L,a+b); return 1; }

static const luaL_Reg mymath_funcs[] = {
  {"add", l_add},
  {NULL, NULL}
};

LUAMOD_API int luaopen_mymath(lua_State *L) {
  luaL_newlib(L, mymath_funcs);
  return 1; // 返回表
}
```
 - Lua侧使用：
```lua
local mymath = require "mymath"
print(mymath.add(2, 3))
```
 - 版本差异：Lua 5.1 用 `luaL_register(L, "mymath", mymath_funcs)`（已废弃）；5.2+ 使用 `luaL_newlib`/`luaL_setfuncs`。
 - 构建与命名：生成 `mymath.so`（Linux）或 `mymath.dll`（Windows），放入 `package.cpath` 可搜索路径；导出符号名必须为 `luaopen_mymath`。

### 练习

练习 29.1

```c
// 请使用 C 语言编写一个可变长参数函数 summation ，来计算数值类型参数的和
#include <stdarg.h>
#include <stdio.h>
#include <math.h>

// 检查是否为 NaN（结束标记）
static int isnan_custom(double x) {
    return x != x;  // NaN 不等于自身
}

// 内部实现函数：使用 NAN 作为结束标记
static double summation_impl(double first, ...) {
    va_list args;
    double sum = first;
    double num;
    
    // 初始化可变参数列表（从 first 之后开始）
    va_start(args, first);
    
    // 遍历所有参数直到遇到 NAN
    while (!isnan_custom(num = va_arg(args, double))) {
        sum += num;
    }
    
    // 清理可变参数列表
    va_end(args);
    
    return sum;
}

// 宏定义：自动在末尾添加 NAN 结束标记
// 这样可以直接调用 summation(2.3, 4.5) 而不需要手动添加结束标记
#define summation(...) summation_impl(__VA_ARGS__, NAN)

// 测试函数
int main() {
    // 测试示例 - 可以直接像这样调用，不需要添加结束标记
    double result1 = summation(2.3, 4.5);
    printf("summation(2.3, 4.5) = %.2f\n", result1);
    
    double result2 = summation(1.5, 2.5, 3.0);
    printf("summation(1.5, 2.5, 3.0) = %.2f\n", result2);
    
    double result3 = summation(10.0, 20.0, 30.0, 40.0, 50.0);
    printf("summation(10.0, 20.0, 30.0, 40.0, 50.0) = %.2f\n", result3);
    
    double result4 = summation(-1.0, 2.0, -3.0, 4.0);
    printf("summation(-1.0, 2.0, -3.0, 4.0) = %.2f\n", result4);
    
    // 单个参数的情况
    double result5 = summation(42.0);
    printf("summation(42.0) = %.2f\n", result5);
    
    return 0;
}
```

练习 29.2

```c
#include <lua.h>
#include <lauxlib.h>

// pack(...): returns a table with array part {1=..., 2=..., ...} and field n = number of args
static int l_pack(lua_State *L) {
    int numArgs = lua_gettop(L);

    // Pre-size array part with numArgs, and one non-array field ("n")
    lua_createtable(L, numArgs, 1);

    // Copy all arguments into the array part to preserve nils and order
    for (int i = 1; i <= numArgs; ++i) {
        lua_pushvalue(L, i);
        lua_seti(L, -2, i);
    }

    // t.n = numArgs
    lua_pushinteger(L, numArgs);
    lua_setfield(L, -2, "n");

    return 1; // return the table
}

static const luaL_Reg p292_funcs[] = {
    {"pack", l_pack},
    {NULL, NULL}
};

LUAMOD_API int luaopen_p292(lua_State *L) {
    luaL_newlib(L, p292_funcs);
    return 1;
}
```

练习 29.3

```c
// reverse(...): returns all arguments in reverse order
static int l_reverse(lua_State *L) {
    int numArgs = lua_gettop(L);
    for (int i = numArgs; i >= 1; --i) {
        lua_pushvalue(L, i);
    }
    return numArgs;
}
```

练习 29.4

```c
#include <lua.h>
#include <lauxlib.h>

// foreach(t, f): for each key-value pair in table t, call f(key, value)
static int l_foreach(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    lua_pushnil(L); // first key
    while (lua_next(L, 1) != 0) {
        // initial stack per iteration: table(1), function(2), key(-2), value(-1)
        lua_pushvalue(L, 2);    // push function copy -> now top is func, key at -3, value at -2
        lua_pushvalue(L, -3);   // push key
        lua_pushvalue(L, -3);   // push value (after pushing key, value shifts to -3)
        lua_call(L, 2, 0);      // call f(key, value)
        lua_pop(L, 1);          // pop value, keep key for lua_next
    }

    return 0;
}
```