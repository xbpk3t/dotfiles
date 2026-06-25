# Time 陷阱

## 陷阱 1：time.After 在 for+select 中泄漏

`time.After` 每次调用创建一个 Timer，Timer 在超时前不会被 GC。在 for 循环中反复调用会导致内存飙升。

```go
// ❌ 每次循环 new Timer，高并发下内存飙升
for {
    select {
    case v := <-ch:
        process(v)
    case <-time.After(time.Second):
        // 超时处理
    }
}
```

```go
// ✅ 重用 Timer
t := time.NewTimer(time.Second)
defer t.Stop()

for {
    t.Reset(time.Second)
    select {
    case v := <-ch:
        process(v)
    case <-t.C:
        // 超时处理
    }
}
```

## 陷阱 2：time.Duration 隐式转换

`time.Duration` 底层是 `int64`（纳秒）。从整数转换时必须显式乘以时间单位。

```go
// ❌ 1 被解释为 1 纳秒，不是 1 秒
timeout := time.Duration(1) * time.Second // 等于 1s，但写法有歧义

// ❌ 从配置读取 int 后直接转 Duration
seconds := config.GetInt("timeout") // 值是 30
timeout := time.Duration(seconds)   // 30 纳秒！不是 30 秒

// ✅ 显式转换
timeout := time.Duration(seconds) * time.Second // 30 秒
```

## 陷阱 3：time.Now() 在测试中不可控

```go
// ❌ 直接调用 time.Now()，测试无法控制
func isExpired(createdAt time.Time) bool {
    return time.Now().Sub(createdAt) > 24*time.Hour
}

// ✅ 注入时钟
type Clock interface {
    Now() time.Time
}

type realClock struct{}
func (realClock) Now() time.Time { return time.Now() }

func isExpired(createdAt time.Time, clock Clock) bool {
    return clock.Now().Sub(createdAt) > 24*time.Hour
}
```

## 陷阱 4：时区处理

```go
// ❌ 解析时不指定时区，用本地时区
t, _ := time.Parse("2006-01-02", "2024-01-15") // UTC

// ✅ 明确时区
t, _ := time.ParseInLocation("2006-01-02", "2024-01-15", time.Local)
```

## 陷阱 5：测试中用 sleep 等待异步结果

```go
// ❌ 用 sleep 等待，要么太慢要么不够长
func TestAsync(t *testing.T) {
    go doAsync()
    time.Sleep(100 * time.Millisecond) // CI 上可能不够
    assert.Equal(t, expected, result)
}

// ✅ 用轮询等待
func TestAsync(t *testing.T) {
    go doAsync()
    assert.Eventually(t, func() bool {
        return getResult() == expected
    }, 5*time.Second, 10*time.Millisecond)
}

// ✅ 或用 channel 同步
func TestAsync(t *testing.T) {
    done := make(chan struct{})
    go func() {
        doAsync()
        close(done)
    }()
    select {
    case <-done:
        // 完成
    case <-time.After(5 * time.Second):
        t.Fatal("timeout")
    }
}
```

## 陷阱 6：time.Now() 无法在测试中 mock

陷阱 3 展示了注入时钟的方式。对于已有代码，可以用第三方 clock mock：

```go
// github.com/benbjohnson/clock
import "github.com/benbjohnson/clock"

// 生产代码
type Service struct {
    clock clock.Clock
}

func NewService() *Service {
    return &Service{clock: clock.New()} // 真实时钟
}

// 测试代码
func TestService(t *testing.T) {
    mock := clock.NewMock()
    svc := &Service{clock: mock}

    // 控制时间
    mock.Add(24 * time.Hour) // 快进 1 天
    svc.DoSomething()
}
```

## 检测模式

1. `time.After` 在 `for` 循环内 → 改用 `time.NewTimer` + `Reset`
2. `time.Duration(int)` 没乘以单位 → 检查是否需要 `* time.Second`
3. 测试中直接调用 `time.Now()` → 考虑注入时钟
4. `time.Parse` 不带时区 → 检查是否需要 `ParseInLocation`
5. 测试中用 `time.Sleep` 等待 → 改用 `assert.Eventually` 或 channel 同步
6. 测试中需要控制时间 → 注入 `Clock` 接口或用 `clock.NewMock()`
