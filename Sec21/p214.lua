-- 银行账户类 - 使用代理表来表示对象
Account = {}

-- 内部表：代理 -> 对象状态的映射
-- 这个表完全不能从外部访问
local internal = {}

function Account:new(o)
    o = o or {}
    
    -- 创建一个完全空的代理表
    local proxy = {}
    
    -- 在内部表中为这个代理创建对应的状态
    internal[proxy] = {
        balance = o.balance or 0,
        owner = o.owner or "Anonymous"
    }
    
    -- 设置代理的元表
    setmetatable(proxy, {
        __index = function(t, k)
            -- 只允许访问Account类中的方法
            if Account[k] and type(Account[k]) == "function" then
                return Account[k]
            end
            -- 不允许直接访问任何属性
            return nil
        end,
        __newindex = function(t, k, v)
            error("Cannot directly access object properties")
        end,
        __tostring = function(t)
            local state = internal[t]
            if state then
                return string.format("Account[%s]: %.2f", state.owner, state.balance)
            end
            return "Invalid Account"
        end
    })
    
    return proxy
end

function Account:deposit(amount)
    if type(amount) ~= "number" or amount <= 0 then
        error("Invalid deposit amount")
    end
    
    -- 使用内部表把self（代理）转换为真正的对象状态
    local state = internal[self]
    if not state then
        error("Invalid account object")
    end
    
    state.balance = state.balance + amount
    return state.balance
end

function Account:withdraw(amount)
    if type(amount) ~= "number" or amount <= 0 then
        error("Invalid withdrawal amount")
    end
    
    -- 使用内部表把self（代理）转换为真正的对象状态
    local state = internal[self]
    if not state then
        error("Invalid account object")
    end
    
    if state.balance < amount then
        error("Insufficient balance")
    end
    
    state.balance = state.balance - amount
    return state.balance
end

function Account:getBalance()
    local state = internal[self]
    if not state then
        error("Invalid account object")
    end
    return state.balance
end

function Account:getOwner()
    local state = internal[self]
    if not state then
        error("Invalid account object")
    end
    return state.owner
end

function Account:setOwner(owner)
    if type(owner) ~= "string" or owner == "" then
        error("Invalid owner name")
    end
    
    local state = internal[self]
    if not state then
        error("Invalid account object")
    end
    
    state.owner = owner
end

-- 测试代码
if arg[1] == "test214" then
    print("=== 真正的代理表设计测试 ===")
    
    local a1 = Account:new({balance = 100, owner = "张三"})
    local a2 = Account:new({balance = 200, owner = "李四"})
    
    print("初始状态:")
    print(a1)
    print(a2)
    
    print("\n=== 操作测试 ===")
    a1:deposit(50)
    print("张三存款50后:", a1)
    
    a2:withdraw(30)
    print("李四取款30后:", a2)
    
    print("\n=== 完全封装测试 ===")
    print("尝试访问a1.balance:", a1.balance)  -- 应该是nil
    print("尝试访问a1.owner:", a1.owner)     -- 应该是nil
    print("正确获取余额:", a1:getBalance())
    print("正确获取所有者:", a1:getOwner())
    
    -- 测试直接设置属性
    local success, err = pcall(function()
        a1.balance = 1000
    end)
    if not success then
        print("直接设置属性失败:", err)
    end
    
    -- 测试方法可访问性
    print("\n=== 方法访问测试 ===")
    print("可以访问deposit方法:", type(a1.deposit))
    print("可以访问getBalance方法:", type(a1.getBalance))
    
    print("\n最终状态:")
    print(a1)
    print(a2)
end