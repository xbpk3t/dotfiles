# Slice 内存陷阱

## 陷阱 1：切分后 append 污染原数组

子 slice 与父 slice 共享底层数组。`append` 在容量足够时不分配新内存，直接写入原数组。

```go
s := []int{1, 2, 3, 4, 5}
sub := s[:2]       // len=2, cap=5, 底层数组 = s 的底层数组
sub = append(sub, 99) // cap 还够，直接写入 s[2]
fmt.Println(s)     // [1, 2, 99, 4, 5] ← 被污染了
```

**防法**：切分后如果要 append，先 copy 隔离。

```go
sub := make([]int, 2)
copy(sub, s[:2])
sub = append(sub, 99) // 安全，不影响 s
```

## 陷阱 2：大 slice 切小段后无法 GC

```go
func readFile() []byte {
    data, _ := os.ReadFile("huge.log") // 100MB
    header := data[:100]               // 只取前 100 字节
    return header
    // data 的 100MB 底层数组无法被 GC，因为 header 引用着
}
```

**防法**：用 copy 提取需要的部分。

```go
func readFile() []byte {
    data, _ := os.ReadFile("huge.log")
    header := make([]byte, 100)
    copy(header, data)
    return header
    // data 可以被 GC
}
```

## 陷阱 3：指针类型 slice 切分后元素无法 GC

```go
type Item struct { Data [1024]byte }

items := make([]*Item, 1_000_000)
// ... 填充 items

// 只取前 100 个
remaining := items[:100]
// 后面 999_900 个 Item 无法 GC，因为 remaining 的底层数组
// 仍然持有对它们的引用（即使 len=100，cap=1_000_000）
```

**防法**：切分后将不需要的位置 nil。

```go
remaining := items[:100]
for i := 100; i < len(items); i++ {
    items[i] = nil // 允许 GC 回收
}
items = remaining
```

## 检测模式

代码中出现以下模式时检查：
1. `s[:n]` 后跟 `append` → 检查是否共享底层数组
2. 大数据源（文件/网络）读取后切小段 → 检查是否 copy
3. 指针 slice 切分 → 检查是否置 nil
