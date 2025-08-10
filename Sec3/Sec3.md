## 3 数值

### 笔记

lua5.2之前的number都是双精度浮点数，lua5.3开始是64位整型+双精度浮点数两种类型。不过两者用`type`返回都是`number`，需要区分时可以用`math.type(3) --> integer`、`math.type(3.0) --> float`。

1. 整数是1（符号位）+63（数值位），最大值是011...11，最小值是100..00，整数溢出是对范围取模。
2. 浮点数是1（符号位）+11（指数位）+52（小数位）。

调用`math.tointeger()`把浮点数转成整数时，如果超出整型范围会返回nil。

大整数向上取余的是否如果用0.5floor的技巧，可能会导致整型转成浮点数后精度损失等问题，建议用以下方式处理大整数向上取余：

```lua
function roud(x)
    local f = math.floor(x)
    if x == f then return x
    else return math.floor(x + 0.5)
    end
end
```

还可以利用当且仅当`x + 0.5`为奇数时`x % 2.0 == 0.5`来改成无偏取整（只向偶数取整）：

```lua
function roud(x)
    local f = math.floor(x)
    if x == f or (x % 2.0 == 0.5) then return x
    else return math.floor(x + 0.5)
    end
end
```

幂运算符和连接运算符是右结合，其他符号都是左结合，按照优先级顺序。

### 练习

练习 3.1

1. `.0e12`有效。这等同于 0.0e12。小数点可以开头，只要后面跟着数字。
2. `.e12`无效。小数点 . 后面必须是数字，不能直接跟指数符号 e。
3. `0.0e`无效。指数符号 e 后面必须跟一个（可选符号的）指数值。
4. `0x12`有效。一个简单的十六进制整数。
5. `0xABFG`无效。G 不是一个有效的十六进制数字（有效数字为 0-9, a-f, A-F）。
6. `0xA`有效。一个简单的十六进制整数。
7. `FFFF`无效。它会被解析为一个变量名。十六进制数必须以 0x 或 0X 开头。
8. `0xFFFFFFFF`有效。一个十六进制整数。
9. `0x`无效。0x 前缀后面必须跟至少一个十六进制数字。
10. `0x1P10`有效。这是一个十六进制浮点数，P 表示二进制指数。它等于 `1 * 2^10`。
11. `0.1e1`有效。标准的十进制科学记数法。
12. `0x0.1p1`有效。带小数部分的十六进制浮点数。它等于 `(1/16) * 2^1`，即 `0.125`。

练习 3.2

1. `math.maxinteger * 2  -->  -2`
   `0x7f...f << 1 = 0xff...fe = -2`
2. `math.mininteger * 2  -->   0`
   `0x80...0 << 1 = 0x00...00 = 0`
3. `math.maxinteger * math.maxinteger  -->  1`
   `(2^63 - 1)^2 mod 2^64 = (2^126 - 2^64 + 1) mod 2^64 = 1`
4. `math.mininteger * math.mininteger  -->  0`
   `(2^64)^2 mod 2^64 = 2^128 mod 2^64 = 0`

练习 3.3

-10~10所有数对3取模后的数字

练习 3.4

1. 右结合，所以结果是 `2^(3^4)`
2. ^优先级最高，所以结果仍然是 `2^(-(3^4))`

练习 3.5

只有那些分母是 2 的整数次幂的数值，才能在标准的二进制浮点系统中被精确地表示，其他都是近似。

练习 3.6

```lua
local function calConVolume(h, theta)
    local r = math.tan(h)
    return math.pi * r * r * h / 3
end
```

练习 3.7

正态分布公式：

$$
\mathcal{Norm}(x;\mu, \sigma) = \dfrac{1}{\sqrt{2\pi\sigma^2}} e^{-\dfrac{(x - \mu^2)}{2\sigma^2}} 
$$

**Box-Muller 变换**：将两个在`(0, 1]`区间内独立且均匀分布的随机数，通过一个变换公式，映射成两个独立且符合标准正态分布（均值为 0，标准差为 1）的随机数。该方法的一大优点是，它一次计算可以生成两个高斯随机数。因此，我们可以通过缓存其中一个来提高效率，下次调用时直接返回缓存值。



```lua
local NormRandom = {
    mean = 0,
    stddev = 1,
}

function NormRandom:new(mean, stddev)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.mean = mean or 0
    o.stddev = stddev or 1
    return o
end

function NormRandom:random()
    -- Box-Muller变换公式
    local u1, u2
    repeat
        u1, u2 = math.random(), math.random()
        if u1 == 0 and u2 ~= 0 then u1, u2 = u2, u1 end
    until u1 > 0
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return self.mean + self.stddev * z0
end

local norm = NormRandom:new(0, 1)
for i = 1, 10 do
    print(norm:random())
end
```