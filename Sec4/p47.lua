local function isPalindrome(str)
    local len = #str
    for i = 1, len / 2 do
        if str:sub(i, i) ~= str:sub(len - i + 1, len - i + 1) then
            return false
        end
    end
    return true
end
print(isPalindrome("12321"))
print(isPalindrome("123221"))
