# String / Rune 陷阱

## 背景

Go 的 `string` 是 UTF-8 编码的字节序列。`len(s)` 返回**字节数**，不是字符数。`for range s` 按 **rune**（Unicode 码点）遍历，`for i := 0; i < len(s); i++` 按 **byte** 遍历。

## 陷阱 1：len(s) 返回字节数

```go
s := "中文"
fmt.Println(len(s))       // 6，不是 2
fmt.Println(len("hello")) // 5
```

**正确做法**：用 `utf8.RuneCountInString(s)` 获取字符数。

```go
import "unicode/utf8"

s := "中文"
fmt.Println(utf8.RuneCountInString(s)) // 2
```

## 陷阱 2：s[i] 返回 byte，不是 rune

```go
s := "中文"
fmt.Printf("%T %v\n", s[0], s[0]) // uint8 228（'中' 的第一个 UTF-8 字节）
```

**正确做法**：用 `for range` 或 `[]rune` 转换。

```go
// for range 自动按 rune 遍历
for i, r := range s {
    fmt.Printf("index=%d rune=%c\n", i, r)
}
// index=0 rune=中
// index=3 rune=文

// 或转换为 rune slice
runes := []rune(s)
fmt.Println(runes[0]) // 20013（'中' 的 Unicode 码点）
```

## 陷阱 3：按 byte 遍历含多字节字符的字符串

```go
s := "Hello, 世界"

// ❌ 按 byte 遍历，中文字符被拆散
for i := 0; i < len(s); i++ {
    fmt.Printf("%c", s[i])
}
// 输出乱码：Hello, ä¸–ç•

// ✅ 按 rune 遍历
for _, r := range s {
    fmt.Printf("%c", r)
}
// 输出：Hello, 世界
```

## 陷阱 4：子字符串按 byte 索引

```go
s := "中文abc"
sub := s[:3] // 取前 3 个字节，恰好是 '中' 的 UTF-8 编码
fmt.Println(sub) // 中

sub2 := s[:4] // 取前 4 个字节，'中'(3字节) + '文' 的第一个字节 → 乱码
fmt.Println(sub2) // 中�
```

**正确做法**：用 `[]rune` 转换后再切片。

```go
runes := []rune(s)
sub := string(runes[:2]) // 取前 2 个字符
fmt.Println(sub) // 中文
```

## 陷阱 5：strings 函数按 byte 操作

`strings.Index`、`strings.Count`、`strings.Replace` 等都是按字节操作的，对多字节字符的行为可能不符合预期。

```go
s := "中文abc"
fmt.Println(strings.Index(s, "文")) // 3（字节偏移，不是字符偏移）
fmt.Println(strings.Count(s, "中")) // 1（正确，但底层是字节匹配）
```

## 检查时机

- 看到 `len(s)` 用于字符串且后续逻辑依赖字符数
- 看到 `s[i]` 索引字符串
- 看到 `s[:n]` 切片字符串且 n 不是字节边界
- 看到 `for i := 0; i < len(s); i++` 遍历字符串
- 看到处理中文/日文/韩文/emoji 等多字节字符的代码
