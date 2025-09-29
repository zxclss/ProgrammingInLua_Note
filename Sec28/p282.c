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