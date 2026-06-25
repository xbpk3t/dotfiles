# CPU 缓存与内存布局陷阱

## 背景

现代 CPU 有多级缓存（L1/L2/L3），缓存以 **cache line**（通常 64 字节）为单位加载。数据访问模式对性能的影响远大于算法复杂度。

## 陷阱 1：struct 字段顺序导致内存浪费

Go 编译器不会自动重排 struct 字段。不同顺序可能导致不同的内存占用。

```go
// ❌ 浪费空间（padding）
type Bad struct {
    a bool    // 1 byte + 7 padding
    b int64   // 8 bytes
    c bool    // 1 byte + 7 padding
}
// sizeof(Bad) = 24 bytes

// ✅ 按大小排序，减少 padding
type Good struct {
    b int64   // 8 bytes
    a bool    // 1 byte
    c bool    // 1 byte + 6 padding
}
// sizeof(Good) = 16 bytes
```

**检查工具**：`go vet -fieldalignment` 或 `fieldalignment ./...`

## 陷阱 2：false sharing（伪共享）

两个不同 goroutine 写入不同变量，但这些变量在同一个 cache line 上，导致缓存行在 CPU 核心之间反复失效。

```go
// ❌ 两个计数器紧挨着，可能在同一个 cache line
type Counters struct {
    a int64  // goroutine 1 写
    b int64  // goroutine 2 写
}

// ✅ 用 padding 隔离到不同 cache line
type CountersPadded struct {
    a int64
    _ [56]byte // padding to 64 bytes
    b int64
    _ [56]byte
}
```

实际场景：高频更新的 per-goroutine 计数器、统计结构。用 `perf stat -e cache-misses` 可以观测。

## 陷阱 3：slice of struct vs slice of pointer

遍历 slice 时，struct 连续内存布局对 CPU cache 友好，pointer 分散分配则不友好。

```go
// ✅ 连续内存，cache 友好
type Point struct { X, Y float64 }
points := make([]Point, 10000)
for _, p := range points {
    sum += p.X + p.Y
}

// ❌ 分散内存，cache 不友好
points := make([]*Point, 10000)
for i := range points {
    points[i] = &Point{X: float64(i), Y: float64(i)}
}
for _, p := range points {
    sum += p.X + p.Y  // 每次访问可能 cache miss
}
```

## 陷阱 4：map 遍历的 cache 行为

map 的底层 bucket 内存不连续，遍历大量 map 比遍历等量 slice 慢得多（cache miss 率高）。

```go
// 遍历 map：cache 不友好
for k, v := range bigMap {
    process(k, v)
}

// 如果可以，转成 slice 遍历
items := make([]Item, 0, len(bigMap))
for k, v := range bigMap {
    items = append(items, Item{K: k, V: v})
}
for _, item := range items {
    process(item.K, item.V)
}
```

## 检查时机

- 看到 struct 有很多字段且用于高频分配/遍历
- 看到多个 goroutine 写同一个 struct 的不同字段
- 看到 `[]*T`（slice of pointer）用于大量数据遍历
- 看到遍历大 map 的热路径
- 看到性能敏感代码且没有 profile 数据支撑
