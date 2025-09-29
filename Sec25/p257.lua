-- Breakpoint library implementing setbreakpoint and removebreakpoint

local M = {}

-- Internal state
local breakpointsByFunc = {}            -- [func] -> { lines = { [line] = { [handle] = true, count = N } }, totalCount = N }
local handleToBreakpoint = {}           -- [handle] -> { func = f, line = n }
local nextHandleId = 0                  -- incremental id for handles (for readability/debugging)
local activeHook = false                -- whether any hook is installed
local inTargetDepth = 0                 -- >0 when currently executing inside a target function stack frame
local isInDebugRepl = false             -- guard to avoid re-entrant breaks while in debug.debug

-- Utility to check if there is at least one breakpoint overall
local function hasAnyBreakpoints()
  for _ in pairs(handleToBreakpoint) do
    return true
  end
  return false
end

-- Hook installer: toggles line events depending on whether we are inside a target function
local function updateHookMask()
  if not hasAnyBreakpoints() then
    debug.sethook()
    activeHook = false
    inTargetDepth = 0
    return
  end

  local mask = (inTargetDepth > 0) and "crl" or "cr"

  if not activeHook or mask ~= M.__currentMask then
    debug.sethook(M.__hook, mask)
    M.__currentMask = mask
    activeHook = true
  end
end

-- Debug hook function
function M.__hook(event, line)
  -- Avoid re-entrancy while inside interactive debug session
  if isInDebugRepl then return end

  if event == "call" then
    local info = debug.getinfo(2, "f")
    local f = info and info.func
    if f and breakpointsByFunc[f] then
      inTargetDepth = inTargetDepth + 1
      if inTargetDepth == 1 then
        updateHookMask() -- enable line events when first entering a target function
      end
    end
    return
  end

  if event == "return" or event == "tail return" then
    local info = debug.getinfo(2, "f")
    local f = info and info.func
    if f and breakpointsByFunc[f] then
      if inTargetDepth > 0 then
        inTargetDepth = inTargetDepth - 1
        if inTargetDepth == 0 then
          updateHookMask() -- disable line events when leaving all target functions
        end
      end
    end
    return
  end

  if event == "line" then
    -- Only reached when inTargetDepth > 0 (since we only enable 'l' mask then)
    local info = debug.getinfo(2, "f")
    local f = info and info.func
    if not f then return end
    local byFunc = breakpointsByFunc[f]
    if not byFunc then return end
    local byLine = byFunc.lines[line]
    if not byLine then return end

    -- We have at least one breakpoint at this line for this function
    isInDebugRepl = true
    pcall(debug.debug)
    isInDebugRepl = false
    return
  end
end

-- Public API: setbreakpoint(functionValue, lineNumber) -> handle
function M.setbreakpoint(func, line)
  if type(func) ~= "function" then
    error("setbreakpoint: first argument must be a function", 2)
  end
  if type(line) ~= "number" then
    error("setbreakpoint: second argument must be a line number", 2)
  end

  nextHandleId = nextHandleId + 1
  local handle = { __breakpoint_handle_id = nextHandleId }

  local byFunc = breakpointsByFunc[func]
  if not byFunc then
    byFunc = { lines = {}, totalCount = 0 }
    breakpointsByFunc[func] = byFunc
  end

  local byLine = byFunc.lines[line]
  if not byLine then
    byLine = { count = 0 }
    byFunc.lines[line] = byLine
  end

  if not byLine[handle] then
    byLine[handle] = true
    byLine.count = byLine.count + 1
    byFunc.totalCount = byFunc.totalCount + 1
  end

  handleToBreakpoint[handle] = { func = func, line = line }

  updateHookMask()
  return handle
end

-- Public API: removebreakpoint(handle)
function M.removebreakpoint(handle)
  local bp = handleToBreakpoint[handle]
  if not bp then return false end

  local func = bp.func
  local line = bp.line
  local byFunc = breakpointsByFunc[func]
  if byFunc then
    local byLine = byFunc.lines[line]
    if byLine and byLine[handle] then
      byLine[handle] = nil
      byLine.count = byLine.count - 1
      byFunc.totalCount = byFunc.totalCount - 1
      if byLine.count <= 0 then
        byFunc.lines[line] = nil
      end
      if byFunc.totalCount <= 0 then
        breakpointsByFunc[func] = nil
      end
    end
  end

  handleToBreakpoint[handle] = nil
  updateHookMask()
  return true
end

return M


