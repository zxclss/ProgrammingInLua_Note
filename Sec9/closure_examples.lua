-- 闭包示例文件
-- 演示Lua中闭包的各种用法

print("=== 闭包基础示例 ===")

-- 1. 基本闭包 - 计数器
function createCounter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

local counter1 = createCounter()
local counter2 = createCounter()

print("Counter1:", counter1())  -- 1
print("Counter1:", counter1())  -- 2
print("Counter2:", counter2())  -- 1 (独立的计数器)

print("\n=== 闭包高级应用 ===")

-- 2. 银行账户模拟 - 数据隐藏
function createBankAccount(initialBalance)
    local balance = initialBalance or 0
    
    return {
        deposit = function(amount)
            balance = balance + amount
            print("存款", amount, "元，当前余额:", balance)
            return balance
        end,
        withdraw = function(amount)
            if amount <= balance then
                balance = balance - amount
                print("取款", amount, "元，当前余额:", balance)
                return true, balance
            else
                print("余额不足，当前余额:", balance)
                return false, "余额不足"
            end
        end,
        getBalance = function()
            return balance
        end
    }
end

local account1 = createBankAccount(100)
local account2 = createBankAccount(50)

print("账户1余额:", account1.getBalance())
account1.deposit(50)
account1.withdraw(30)
account1.withdraw(200)  -- 余额不足

print("\n=== 函数工厂 ===")

-- 3. 函数工厂 - 创建特定功能的函数
function makeAdder(x)
    return function(y)
        return x + y
    end
end

local add5 = makeAdder(5)
local add10 = makeAdder(10)

print("add5(3) =", add5(3))     -- 8
print("add10(3) =", add10(3))   -- 13

-- 4. 配置函数
function makeMultiplier(factor)
    return function(value)
        return value * factor
    end
end

local double = makeMultiplier(2)
local triple = makeMultiplier(3)

print("double(5) =", double(5))   -- 10
print("triple(5) =", triple(5))   -- 15

print("\n=== 闭包在循环中的应用 ===")

-- 5. 循环中的闭包 - 注意变量捕获
local functions = {}
for i = 1, 3 do
    functions[i] = function()
        return i  -- 这里会捕获循环变量i
    end
end

-- 注意：所有函数都会返回3，因为i最终的值是3
for j = 1, 3 do
    print("functions[" .. j .. "]() =", functions[j]())
end

-- 正确的做法 - 使用立即执行函数
local functions2 = {}
for i = 1, 3 do
    functions2[i] = (function(captured_i)
        return function()
            return captured_i
        end
    end)(i)
end

print("\n修正后的结果:")
for j = 1, 3 do
    print("functions2[" .. j .. "]() =", functions2[j]())
end

print("\n=== 闭包实现面向对象 ===")

-- 6. 使用闭包实现简单的面向对象
function createPerson(name, age)
    local privateData = {
        name = name,
        age = age
    }
    
    return {
        getName = function()
            return privateData.name
        end,
        getAge = function()
            return privateData.age
        end,
        setAge = function(newAge)
            if newAge >= 0 then
                privateData.age = newAge
                return true
            else
                return false
            end
        end,
        celebrateBirthday = function()
            privateData.age = privateData.age + 1
            print(privateData.name .. " 过生日了！现在" .. privateData.age .. "岁")
        end
    }
end

local person = createPerson("张三", 25)
print("姓名:", person.getName())
print("年龄:", person.getAge())
person.celebrateBirthday()
person.setAge(30)
print("新年龄:", person.getAge()) 