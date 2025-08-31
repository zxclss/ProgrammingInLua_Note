-- 实验：展示为什么需要“瞬表”（ephemeron semantics）
-- 思路：使用弱键表（仅键为弱引用），但让 value 强引用其 key，形成 value→key 的环。
-- 在 Lua 5.1 中，这会阻止 key 被回收（因为 table 强引用 value，value 又强引用 key）。
-- 在 Lua 5.2/5.3/5.4 中，弱键表按瞬表语义处理：只有当 key 可达时，value 才被视为可达；
-- 若 key 仅通过该表可达，则先丢弃 value，从而允许回收 key 与整对项。

local function count_pairs(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

local function fill_with_cycles(num)
  -- 仅键为弱引用
  local t = setmetatable({}, { __mode = "k" })
  for _ = 1, num do
    local key = {}
    local value = { key_ref = key } -- value 强引用 key
    t[key] = value                   -- 表强引用 value
  end
  return t
end

local function fill_with_cycles_and_keep_one(num)
  local t = setmetatable({}, { __mode = "k" })
  local keep_key
  for i = 1, num do
    local key = {}
    local value = { key_ref = key }
    t[key] = value
    if i == num then
      keep_key = key -- 保留最后一个 key 的强引用
    end
  end
  return t, keep_key
end

local function run()
  print("Lua 版本:", _VERSION)
  collectgarbage("collect")

  local N = tonumber(_G.arg and _G.arg[1]) or 20000

  -- 测试 1：弱键表 + value→key 环，无其它引用
  local t1 = fill_with_cycles(N)
  collectgarbage("collect")
  print("[测试1] 弱键表 + 环引用，GC 后条目数:", count_pairs(t1))

  -- 测试 2：同上，但保留一个 key 的强引用
  local t2, keep_key = fill_with_cycles_and_keep_one(N)
  collectgarbage("collect")
  local c2 = count_pairs(t2)
  -- 防止编译器优化掉 keep_key
  if keep_key == nil then
    print("[测试2] 意外：保留的 key 丢失")
  end
  print("[测试2] 弱键表 + 环引用 + 保留1个强引用key，GC 后条目数:", c2)
end

run()
