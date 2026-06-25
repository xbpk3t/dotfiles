# JSON 陷阱

## 陷阱 1：大整数精度丢失

JSON number 是 float64，超过 2^53 的整数会丢失精度。

```go
// ❌
var data = `{"id": 17181928374625163728}`
var v struct {
    ID int64 `json:"id"`
}
json.Unmarshal([]byte(data), &v)
// v.ID != 17181928374625163728，精度丢失
```

```go
// ✅ 用 string 传递大整数
var data = `{"id": "17181928374625163728"}`
var v struct {
    ID string `json:"id"`
}

// ✅ 或用 json.Number
dec := json.NewDecoder(strings.NewReader(data))
dec.UseNumber()
dec.Decode(&v)
id, _ := v.ID.Int64()
```

## 陷阱 2：omitempty 吞掉零值

```go
type User struct {
    Name  string `json:"name"`
    Age   int    `json:"age,omitempty"`
    Admin bool   `json:"admin,omitempty"`
}

u := User{Name: "Alice", Age: 0, Admin: false}
json.Marshal(u)
// {"name":"Alice"} — Age 和 Admin 被吞掉了

// ✅ 用指针区分"未设置"和"零值"
type User struct {
    Name  string `json:"name"`
    Age   *int   `json:"age,omitempty"`
    Admin *bool  `json:"admin,omitempty"`
}
```

## 陷阱 3：时区处理

```go
// Go 的 time.Time JSON 序列化默认用 RFC3339，带时区
t := time.Date(2024, 1, 15, 10, 0, 0, 0, time.UTC)
json.Marshal(t) // "2024-01-15T10:00:00Z"

// 解析时如果源没带时区，用 ParseInLocation
json.Unmarshal([]byte(`"2024-01-15T10:00:00"`), &t) // 默认 UTC

// ✅ 需要特定时区时显式处理
loc, _ := time.LoadLocation("Asia/Shanghai")
json.Unmarshal([]byte(`"2024-01-15T10:00:00"`), &t) // 先解析
t = t.In(loc) // 再转换
```

## 陷阱 4：map[string]interface{} 类型断言

```go
var data = `{"name": "Alice", "age": 30}`
var v map[string]interface{}
json.Unmarshal([]byte(data), &v)

// ❌ 直接断言
age := v["age"].(int) // 如果 age 是 float64 就 panic

// ✅ comma-ok 惯用语
age, ok := v["age"].(float64) // JSON number 默认是 float64
if !ok {
    // 处理类型不匹配
}
```

## 检测模式

1. `int64` 字段反序列化 JSON → 检查值是否可能超过 2^53
2. `omitempty` 用于 `int`/`bool` 等零值有意义的字段 → 警告
3. `map[string]interface{}` + 类型断言 → 用 struct 替代
4. `time.Time` 字段反序列化不带时区的字符串 → 检查时区处理
