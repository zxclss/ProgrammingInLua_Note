// 假设栈是空的，执行下列代码后会是什么内容
lua_pushnumber(L, 3.5);
lua_pushstring(L, " hello ");
lua_pushnil(L);
lua_rotate(L, 1, -1);
lua_pushvalue(L, -2);
lua_remove(L, 1);
lua_insert(L, -2);

/*
lua_pushnumber(L, 3.5):
[3.5]
lua_pushstring(L, " hello "):
[3.5, " hello "]
lua_pushnil(L):
[3.5, " hello ", nil]
lua_rotate(L, 1, -1) // 把索引1的元素旋到栈顶
[" hello ", nil, 3.5]
lua_pushvalue(L, -2) // 复制倒数第二个元素（nil）
[" hello ", nil, 3.5, nil]
lua_remove(L, 1) // 移除底部的 " hello "
[nil, 3.5, nil]
lua_insert(L, -2) // 把栈顶元素插入到倒数第二个位置
[nil, nil, 3.5]
*/