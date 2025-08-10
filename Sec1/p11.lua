#!/bin
function Factorial(n)
    if n < 0 then
        return "Error: Factorial of a negative number is not defined"
    elseif n == 0 then
        return 1
    else
        return n * Factorial(n - 1)
    end
end

print("enter a number:")
a = io.read("*n")
print(Factorial(a))