---
name: go-pitfalls
description: >
  Go 语言陷阱检测：浮点精度、slice/map 内存语义、time/JSON/HTTP 标准库陷阱、
  nil 语义、控制流陷阱、容器化性能、string/rune 编码、CPU 缓存友好性。
  覆盖 100 Go Mistakes 中 linter 和其他 skills 无法处理的常见错误模式。
  Use when writing code involving float comparison, slice/map operations, time/JSON/HTTP usage,
  string substrings, switch/select/break control flow, nil interface values, Docker/K8S deployment,
  rune/string iteration, defer with named returns, CPU cache layout, or profiling/diagnostics.
---

# Go 语言陷阱

覆盖 linter 和其他 Go skills 检测不到的语言层面陷阱。每个陷阱都有固定的代码模式，AI agent 可以在写代码时主动预防。

## 检查时机

在以下场景触发检查：

1. **浮点数比较** — 看到 `==` 或 `!=` 作用于 `float32`/`float64`
2. **slice 切分后 append** — 看到 `s[:n]` 后跟 `append`
3. **大 slice 切小子串** — 看到 `s[:n]` 且 `n << cap(s)`
4. **大字符串切子串** — 看到 `s[:n]` 且 `s` 来自外部输入或大文件
5. **map 频繁增删** — 看到 `delete(m, k)` 在循环中
6. **switch/select 内 break** — 看到 `break` 在 `switch` 或 `select` 块内
7. **返回具体指针类型作为 error** — 看到 `func() *MyError` 返回给 `error` 接口
8. **Docker/K8S 部署** — 看到 `Dockerfile` 或 `GOMAXPROCS` 相关配置
9. **time.After 在循环中** — 看到 `time.After` 在 `for` 或 `select` 块内
10. **JSON 大整数/零值** — 看到 `int64` 字段反序列化 JSON，或 `omitempty` 用于零值有意义的字段
11. **HTTP 默认 client** — 看到 `http.Get`/`http.Post` 直接调用，或 HTTP handler 中 `Write` 后无 `return`
12. **字符串按 byte 操作** — 看到 `len(s)` 用于字符串、`s[i]` 索引、`s[:n]` 切片、`for i < len(s)` 遍历
13. **defer + 命名返回值** — 看到 `defer` 函数修改命名返回值
14. **sync.Cond** — 看到 goroutine 忙等轮询共享变量，或需要 Broadcast/Signal 通知的场景
15. **fmt.Sprintf 触发 Stringer** — 看到 `%v`/`%s` 作用于可能有锁的类型
16. **struct 内存布局** — 看到高频分配的 struct 有很多字段，或多 goroutine 写同一 struct 不同字段
17. **测试用 sleep** — 看到 `time.Sleep` 在测试中等待异步结果
18. **getter/setter 惯性** — 看到 Go 代码中为每个字段写 `GetXxx()`/`SetXxx()` 方法

## 核心规则

### 1. 浮点数不用 == 比较

浮点运算有精度损失，`0.1 + 0.2 != 0.3`。

```go
// ❌
if a == b { }

// ✅
if math.Abs(a-b) < 1e-9 { }
```

详见 [references/float.md](references/float.md)

### 2. slice 切分后 append 可能污染原数组

子 slice 与父 slice 共享底层数组，append 在容量足够时直接覆盖原数据。

```go
// ❌
sub := s[:2]
sub = append(sub, 99) // 修改了 s[2]

// ✅
sub := make([]int, 2)
copy(sub, s[:2])
```

详见 [references/slice-memory.md](references/slice-memory.md)

### 3. 大 slice/map 有内存泄漏风险

- slice 切小段后，整个底层数组无法 GC
- map 删除 key 后不缩容

详见 [references/slice-memory.md](references/slice-memory.md) 和 [references/map-memory.md](references/map-memory.md)

### 4. 子字符串保留原字符串内存

```go
// ❌
huge := readHugeString() // 10MB
sub := huge[:100]        // 底层仍引用 10MB

// ✅
sub := strings.Clone(huge[:100])
```

### 5. break 在 switch/select 内不跳出 for

```go
// ❌ break 只跳出 switch
for {
    select {
    case <-ch:
        break // 没跳出 for
    }
}

// ✅ 用 label
loop:
for {
    select {
    case <-ch:
        break loop
    }
}
```

### 6. nil 指针赋给 interface 不是 nil interface

```go
// ❌
var p *MyError = nil
var err error = p
err != nil // true! interface 是 (type, value) pair

// ✅ 函数签名用 error 接口，不要返回具体指针类型
func doSomething() error { // 不是 *MyError
    return nil
}
```

详见 [references/nil-semantics.md](references/nil-semantics.md)

### 7. 容器化环境必须设置 GOMAXPROCS/GOMEMLIMIT

Go 不自动感知 cgroup 限制。Docker/K8S 中必须显式配置。

```dockerfile
# ✅
ENV GOMAXPROCS=4
ENV GOMEMLIMIT=1GiB
```

或用 `automaxprocs` / `automemlimit`。

详见 [references/container.md](references/container.md)

### 8. time.After 在 for+select 中会泄漏

每次 `time.After` 调用创建一个 Timer，超时前不会被 GC。循环中反复调用导致内存飙升。

```go
// ❌
for {
    select {
    case v := <-ch:
        process(v)
    case <-time.After(time.Second): // 每次 new Timer
    }
}

// ✅ 重用 Timer
t := time.NewTimer(time.Second)
defer t.Stop()
for {
    t.Reset(time.Second)
    select {
    case v := <-ch:
        process(v)
    case <-t.C:
    }
}
```

详见 [references/time.md](references/time.md)

### 9. JSON 大整数精度丢失 + omitempty 吞零值

JSON number 是 float64，超过 2^53 的整数精度丢失。`omitempty` 会吞掉零值字段。

```go
// ❌ 大整数
var v struct { ID int64 `json:"id"` }
json.Unmarshal([]byte(`{"id": 17181928374625163728}`), &v) // 精度丢失

// ✅ 用 string
var v struct { ID string `json:"id"` }

// ❌ omitempty 吞零值
type User struct {
    Age int `json:"age,omitempty"` // Age=0 被吞掉
}

// ✅ 用指针
type User struct {
    Age *int `json:"age,omitempty"` // Age=0 保留
}
```

详见 [references/json.md](references/json.md)

### 10. HTTP DefaultClient 无超时 + handler 缺 return

```go
// ❌ 无超时
resp, err := http.Get(url)

// ✅ 自定义 Client
client := &http.Client{Timeout: 10 * time.Second}
resp, err := client.Get(url)

// ❌ handler 中 Write 后缺 return
func handler(w http.ResponseWriter, r *http.Request) {
    data, err := getData()
    if err != nil {
        w.WriteHeader(500)
        w.Write([]byte(err.Error()))
        // 缺 return，继续执行下面的代码
    }
    w.Write(data) // body 混乱
}
```

详见 [references/http.md](references/http.md)

### 11. 字符串长度和遍历按 byte 不按 rune

`len(s)` 返回字节数，`s[i]` 返回 byte，`for range s` 按 rune 遍历。处理中文/emoji 等多字节字符时必须注意。

```go
// ❌
s := "中文"
len(s)          // 6，不是 2
s[0]            // 228，不是 '中'
for i := 0; i < len(s); i++ { ... } // 按 byte 遍历，中文被拆散

// ✅
utf8.RuneCountInString(s) // 2
for _, r := range s { ... } // 按 rune 遍历
```

详见 [references/string-rune.md](references/string-rune.md)

### 12. defer 可以修改命名返回值

```go
func f() (result int) {
    defer func() {
        result++ // 修改了返回值！
    }()
    return 0 // 实际返回 1
}
```

这个行为在 error handling 中尤其危险：

```go
func getError() (err error) {
    defer func() {
        if err != nil {
            log.Error(err) // 这里的 err 是最终返回值，包括被 defer 修改的
        }
    }()
    return doSomething() // 如果 doSomething 返回 nil，但 defer 又赋了新 error...
}
```

### 13. 忘记 sync.Cond

goroutine 忙等轮询共享变量是常见的并发错误。sync.Cond 提供高效的等待/通知机制。

```go
// ❌ 忙等，浪费 CPU
for {
    mu.Lock()
    if ready {
        mu.Unlock()
        break
    }
    mu.Unlock()
    time.Sleep(10 * time.Millisecond) // 轮询
}

// ✅ 用 sync.Cond
cond := sync.NewCond(&mu)
cond.L.Lock()
for !ready {
    cond.Wait() // 释放锁，等待信号，重新获取锁
}
cond.L.Unlock()

// 通知方
cond.L.Lock()
ready = true
cond.Signal() // 或 cond.Broadcast()
cond.L.Unlock()
```

### 14. fmt.Sprintf + %v 可能触发死锁

如果类型实现了 `fmt.Stringer` 且 `String()` 方法加了锁，在持锁状态下调用 `fmt.Sprintf("%v", obj)` 会死锁。

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) String() string {
    c.mu.Lock()
    defer c.mu.Unlock()
    return fmt.Sprintf("count=%d", c.count)
}

// ❌ 在持锁时调用 String() → 死锁
func (c *SafeCounter) Incr() {
    c.mu.Lock()
    c.count++
    log.Printf("after incr: %v", c) // 触发 String()，死锁！
    c.mu.Unlock()
}

// ✅ 先获取值再格式化
func (c *SafeCounter) Incr() {
    c.mu.Lock()
    c.count++
    n := c.count
    c.mu.Unlock()
    log.Printf("after incr: count=%d", n)
}
```

### 15. Go 不需要 getter/setter

Go 不是 Java。直接暴露字段是惯用做法，只在需要额外逻辑时才写方法。

```go
// ❌ Java 风格
type User struct {
    name string
}
func (u *User) GetName() string    { return u.name }
func (u *User) SetName(name string) { u.name = name }

// ✅ 直接暴露
type User struct {
    Name string
}

// 只在需要验证/转换时加方法
type User struct {
    name string
}
func (u *User) SetName(name string) error {
    if name == "" {
        return errors.New("name required")
    }
    u.name = name
    return nil
}
```

### 16. struct 字段顺序影响内存布局

```go
// ❌ 浪费 8 字节 padding
type Bad struct {
    a bool    // 1 + 7 padding
    b int64   // 8
    c bool    // 1 + 7 padding
} // 24 bytes

// ✅ 按大小排序
type Good struct {
    b int64   // 8
    a bool    // 1
    c bool    // 1 + 6 padding
} // 16 bytes
```

详见 [references/cpu-cache.md](references/cpu-cache.md)

### 17. 测试中不要用 sleep 等待

```go
// ❌ 不确定性
go doAsync()
time.Sleep(100 * time.Millisecond)

// ✅ 轮询等待
assert.Eventually(t, func() bool {
    return getResult() == expected
}, 5*time.Second, 10*time.Millisecond)

// ✅ 或 channel 同步
done := make(chan struct{})
go func() { doAsync(); close(done) }()
select {
case <-done:
case <-time.After(5 * time.Second):
    t.Fatal("timeout")
}
```

详见 [references/time.md](references/time.md)

### 18. 不用 pprof/trace 诊断性能

benchmark 告诉你"慢了多少"，pprof 告诉你"慢在哪"，trace 告诉你"为什么慢"。

```bash
go test -bench=. -cpuprofile=cpu.prof -memprofile=mem.prof ./...
go tool pprof cpu.prof       # 定位热点函数
go test -bench=. -trace=trace.out ./...
go tool trace trace.out      # 分析 goroutine 调度、GC STW
```

详见 [references/diagnostics.md](references/diagnostics.md)
