-- RUN_P246_DEMO=1 lua Sec24/p246.lua

-- Minimal coroutine scheduler with transfer semantics (resume/yield mediated)

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
  return setmetatable({ current = nil }, Scheduler)
end

-- Run starting from an entry coroutine. It continues following transfer hops
-- until the current coroutine returns or yields something other than a transfer.
function Scheduler:run(entry, ...)
  local nextCoroutine = assert(entry, "entry coroutine required")
  local args = { ... }

  while nextCoroutine do
    self.current = nextCoroutine

    if coroutine.status(nextCoroutine) == "dead" then
      return
    end

    local ok, yielded = coroutine.resume(nextCoroutine, table.unpack(args))
    if not ok then
      error(yielded, 0)
    end

    if coroutine.status(nextCoroutine) == "dead" then
      return
    end

    if type(yielded) == "table" and yielded.op == "transfer" then
      local target = yielded.target
      assert(type(target) == "thread", "transfer target must be a coroutine (thread)")
      assert(coroutine.status(target) ~= "dead", "cannot transfer to a dead coroutine")
      nextCoroutine = target
      args = yielded.args or {}
    else
      -- Any non-transfer yield stops the scheduler (simple demo policy)
      return
    end
  end
end

function Scheduler:transfer(target, ...)
  -- Yield a transfer request to the scheduler. When this coroutine is
  -- later resumed, the values passed to resume become our return values.
  return coroutine.yield({ op = "transfer", target = target, args = { ... } })
end

local scheduler = Scheduler.new()

local function spawn(fn)
  assert(type(fn) == "function", "spawn expects a function")
  return coroutine.create(fn)
end

-- transfer(target, ...): suspend the current coroutine and switch to target.
-- When some coroutine transfers back to this one, returned values will be
-- whatever that transfer provided to resume this coroutine.
local function transfer(target, ...)
  assert(coroutine.running(), "transfer must be called inside a coroutine")
  local results = { scheduler:transfer(target, ...) }
  return table.unpack(results)
end

local function demo()
  local coA, coB

  coA = spawn(function()
    print("A: start")
    local r1 = transfer(coB, "msg-from-A1")
    print("A: back, got", r1)
    local r2 = transfer(coB, "msg-from-A2")
    print("A: back again, got", r2)
    print("A: done")
  end)

  coB = spawn(function(x)
    print("B: got", x)
    transfer(coA, "reply-from-B1")
    print("B: resumed")
    transfer(coA, "reply-from-B2")
    -- At this point B is suspended until someone transfers back to it.
  end)

  scheduler:run(coA)
end

if os.getenv("RUN_P246_DEMO") == "1" then
  demo()
end
