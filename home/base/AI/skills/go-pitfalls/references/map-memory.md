# Map 内存陷阱

## 问题

Go 的 map 删除 key 后不会缩容。底层 bucket 只增不减。

```go
m := make(map[int]struct{})
for i := 0; i < 100_000; i++ {
    m[i] = struct{}{}
}
for k := range m {
    delete(m, k) // 删了所有 key，但内存不降
}
// len(m) == 0，但底层 bucket 数量跟 100_000 时一样
```

## 场景

- session 管理器：用户登录加 map，登出删 map → 内存只涨不跌
- 缓存：过期后 delete → 底层不释放
- 计数器：reset 后重新填充 → 旧 bucket 残留

## 防法

**定期重建 map**：

```go
// 每 N 次 delete 后重建
if deleteCount > threshold {
    newMap := make(map[K]V, len(m))
    for k, v := range m {
        newMap[k] = v
    }
    m = newMap
}
```

**高并发场景用 `sync.Map`**：内部有优化的 GC 机制，适合 key 频繁增删的场景。

**预估大小时给 hint**：

```go
m := make(map[string]int, expectedSize) // 减少 rehash 次数
```

## 检测模式

代码中出现以下模式时检查：
1. 循环中 `delete(m, k)` → 检查是否有重建逻辑
2. map 作为长期存储（全局变量、struct 字段）+ 频繁增删 → 警告
