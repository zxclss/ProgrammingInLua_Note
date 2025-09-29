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