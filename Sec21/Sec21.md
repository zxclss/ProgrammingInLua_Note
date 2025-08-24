## 21 面向对象（Object-Oriented）编程

### 笔记

**类**

在Lua中，表既是对象又是类。使用元表和`__index`元方法可以实现类的功能。

基本的类实现模式：
```lua
Account = {balance = 0}
function Account:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
```

**继承**

继承通过让子类从父类获得方法来实现。这在Lua中非常容易实现，因为类本身就是对象。

```lua
Account = {balance = 0}
function Account:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
SpecialAccount = Account:new()
```

**多重继承**

Lua可以通过搜索函数实现多重继承：

```lua
local function search(k, plist)
    for i = 1, #plist do
        local v = plist[i][k]
        if v then return v end
    end
end

function createClass(...)
    local c = {}
    local parents = {...}
    
    -- 设置类的元表进行多重继承搜索
    setmetatable(c, {
        __index = function(t, k)
            return search(k, parents)
        end
    })
    
    -- 准备c作为实例的元表
    c.__index = c
    
    -- 构造函数
    function c:new(o)
        o = o or {}
        setmetatable(o, c)
        return o
    end
    
    return c
end

-- 示例：多重继承
Named = {}
function Named:getname()
    return self.name
end
function Named:setname(name)
    self.name = name
end

Account = {}
function Account:getbalance()
    return self.balance
end
function Account:deposit(v)
    self.balance = (self.balance or 0) + v
end

-- NamedAccount继承自Named和Account
NamedAccount = createClass(Named, Account)

local account = NamedAccount:new()
account:setname("Paul")
account:deposit(100)
print(account:getname())    --> Paul
print(account:getbalance()) --> 100
```

**私有性**，Lua中可以使用闭包实现私有变量：

```lua
function newAccount(initialBalance)
    local self = {}
    local balance = initialBalance or 0
    
    function self.withdraw(v)
        if v > balance then
            error("insufficient funds")
        end
        balance = balance - v
    end
    
    function self.deposit(v)
        balance = balance + v
    end
    
    function self.getBalance()
        return balance
    end
    
    return self
end

local acc = newAccount(100)
acc.deposit(50)
print(acc.getBalance())  --> 150
-- 无法直接访问balance变量
```

**单方法对象**

对于只有一个方法的对象，可以直接返回该方法：

```lua
function newObject(value)
    return function(action, v)
        if action == "get" then
            return value
        elseif action == "set" then
            value = v
        else
            error("invalid action")
        end
    end
end

local d = newObject(0)
print(d("get"))     --> 0
d("set", 10)
print(d("get"))     --> 10
```

**对偶表示**：本来应该存放在对象内部的变量，现在转存到其他表里，用对象作为key来索引访问。

### 练习

练习 21.1

```lua
Stack = {}

function Stack:new()
    local o = {items = {}}
    self.__index = self
    setmetatable(o, self)
    return o
end

function Stack:push(value)
    table.insert(self.items, value)
end

function Stack:pop()
    table.remove(self.items)
end

function Stack:top()
    return self.items[#self.items]
end

function Stack:isEmpty()
    return #self.items == 0
end
```

练习 21.2

```lua
require "p211"

StackQueue = Stack:new()

function StackQueue:insertbottom(value)
    if #self.items == 0 then
        self:push(value)
        return
    end
    for i = #self.items, 1, -1 do
        self.items[i+1] = self.items[i]
    end
    self.items[1] = value
end
```

练习 21.3

```lua
local stack_data = {}

Stack = {}

function Stack:new(o)
    local o = o or {}
    self.__index = self
    setmetatable(o, self)
    stack_data[o] = {}
    return o
end

function Stack:push(value)
    table.insert(stack_data[self], value)
end

function Stack:pop()
    return table.remove(stack_data[self])
end

function Stack:top()
    return stack_data[self][#stack_data[self]]
end

function Stack:isEmpty()
    return #stack_data[self] == 0
end
```

练习 21.4

```lua
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
```