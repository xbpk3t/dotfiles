# 浮点数陷阱

## 问题

IEEE 754 浮点数有精度损失。`0.1 + 0.2` 的结果是 `0.30000000000000004`，不是 `0.3`。

## 常见错误

```go
// ❌ 直接比较
if price1 == price2 { }

// ❌ 用 float 存金额
type Invoice struct {
    Amount float64 // 19.99 可能变成 19.989999999999998
}

// ❌ 累加误差
sum := 0.0
for i := 0; i < 1000; i++ {
    sum += 0.01
}
// sum 不等于 10.0
```

## 正确做法

```go
// ✅ 用 epsilon 比较
const epsilon = 1e-9
func equal(a, b float64) bool {
    return math.Abs(a-b) < epsilon
}

// ✅ 金额用整数（分）或 decimal 库
type Invoice struct {
    AmountCents int64 // 1999 表示 19.99
}

// ✅ 用 shopspring/decimal
import "github.com/shopspring/decimal"
price, _ := decimal.NewFromString("19.99")
```

## 什么时候可以忽略

- 像素坐标、UI 尺寸 → `float64` 直接比较通常 OK（精度够用）
- 物理模拟、游戏坐标 → 用 epsilon
- 金额、财务 → **必须**用整数或 decimal
