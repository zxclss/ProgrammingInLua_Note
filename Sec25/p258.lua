local debug = require("debug")

local steplimit = 1000

local count = 0

local function step()
    count = count + 1
    if count >= steplimit then
        error("script uses too much CPU")
    end
end

local env = {}
env._G = env -- 让沙盒内的代码可以通过 _G 访问到自身定义的全局函数/变量
local f = assert(loadfile(arg[1], "t", env))

debug.sethook(step, "", steplimit)
f()