# Nil 语义陷阱

## 陷阱 1：nil 指针赋给 interface 不是 nil interface

Go 的 interface 值是 `(type, value)` 二元组。当 `type` 不为 nil 时，即使 `value` 为 nil，interface 本身也不等于 nil。

```go
type MyError struct{ Msg string }
func (e *MyError) Error() string { return e.Msg }

func getError() error {
    var p *MyError = nil
    return p // 返回的 error != nil！
}

err := getError()
if err != nil {
    // 会走到这里，err 是 (*MyError, nil)，不是 (nil, nil)
    fmt.Println("error:", err.Error()) // panic: nil pointer dereference
}
```

**防法**：函数签名用 `error` 接口，不要返回具体指针类型。

```go
// ❌
func getError() *MyError { return nil }

// ✅
func getError() error { return nil }
```

## 陷阱 2：nil 接收器可以调用方法

```go
type Person struct{ Name string }

func (p *Person) GetName() string {
    if p == nil { return "unknown" }
    return p.Name
}

var p *Person = nil
fmt.Println(p.GetName()) // "unknown"，不 panic
```

这本身不是 bug，但调用方可能不知道 receiver 是 nil。如果方法内没有 nil 检查，就会 panic。

**防法**：指针接收器的方法在入口处检查 nil，或者在文档中明确说明 nil receiver 的行为。

## 检测模式

1. 函数返回具体指针类型（`*T`）且可能返回 nil → 改为返回 `error` 接口
2. 指针接收器方法内无 nil 检查 → 添加检查或文档说明

> nil slice vs 空 slice、nil map 读写已由 `go-data-structures` skill 覆盖，此处不重复。
