// 请使用 C 语言编写一个可变长参数函数 summation ，来计算数值类型参数的和
#include <stdarg.h>
#include <stdio.h>
#include <math.h>

// 检查是否为 NaN（结束标记）
static int isnan_custom(double x) {
    return x != x;  // NaN 不等于自身
}

// 内部实现函数：使用 NAN 作为结束标记
static double summation_impl(double first, ...) {
    va_list args;
    double sum = first;
    double num;
    
    // 初始化可变参数列表（从 first 之后开始）
    va_start(args, first);
    
    // 遍历所有参数直到遇到 NAN
    while (!isnan_custom(num = va_arg(args, double))) {
        sum += num;
    }
    
    // 清理可变参数列表
    va_end(args);
    
    return sum;
}

// 宏定义：自动在末尾添加 NAN 结束标记
// 这样可以直接调用 summation(2.3, 4.5) 而不需要手动添加结束标记
#define summation(...) summation_impl(__VA_ARGS__, NAN)

// 测试函数
int main() {
    // 测试示例 - 可以直接像这样调用，不需要添加结束标记
    double result1 = summation(2.3, 4.5);
    printf("summation(2.3, 4.5) = %.2f\n", result1);
    
    double result2 = summation(1.5, 2.5, 3.0);
    printf("summation(1.5, 2.5, 3.0) = %.2f\n", result2);
    
    double result3 = summation(10.0, 20.0, 30.0, 40.0, 50.0);
    printf("summation(10.0, 20.0, 30.0, 40.0, 50.0) = %.2f\n", result3);
    
    double result4 = summation(-1.0, 2.0, -3.0, 4.0);
    printf("summation(-1.0, 2.0, -3.0, 4.0) = %.2f\n", result4);
    
    // 单个参数的情况
    double result5 = summation(42.0);
    printf("summation(42.0) = %.2f\n", result5);
    
    return 0;
}