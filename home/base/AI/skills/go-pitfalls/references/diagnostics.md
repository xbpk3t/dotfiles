# Go 诊断工具陷阱

## 问题

Go 内置了完整的诊断工具链（pprof、trace、fuzzing），但很多项目从不使用它们，导致性能问题和 bug 在生产环境才被发现。

## 工具 1：pprof（性能剖析）

### CPU Profiling

```bash
# 从 benchmark 生成 CPU profile
go test -bench=BenchmarkHotPath -cpuprofile=cpu.prof ./...

# 分析
go tool pprof cpu.prof
(pprof) top10           # 最耗 CPU 的函数
(pprof) list funcName   # 逐行耗时
(pprof) web             # 浏览器可视化
```

### Memory Profiling

```bash
go test -bench=. -memprofile=mem.prof ./...
go tool pprof mem.prof
(pprof) top10           # 最多分配的函数
(pprof) list funcName   # 逐行分配量
```

### 生产环境 HTTP 接口

```go
import _ "net/http/pprof"

func main() {
    go http.ListenAndServe(":6060", nil) // 别暴露到公网
    // ...
}
```

```bash
# 采集 30 秒 CPU profile
curl -o cpu.prof http://localhost:6060/debug/pprof/profile?seconds=30
go tool pprof cpu.prof
```

## 工具 2：execution trace（执行追踪）

trace 比 pprof 更细粒度，能看到 goroutine 调度、GC STW、系统调用阻塞。

```bash
# 从 benchmark 生成 trace
go test -bench=BenchmarkHotPath -trace=trace.out ./...

# 分析
go tool trace trace.out
# 打开浏览器，查看：
# - Goroutine 分析：是否有 goroutine 泄漏
# - GC 分析：STW 时间是否过长
# - Network blocking：是否有意外的阻塞调用
```

### 生产环境采集

```bash
curl -o trace.out http://localhost:6060/debug/pprof/trace?seconds=5
go tool trace trace.out
```

## 工具 3：fuzzing（模糊测试）

Go 1.18+ 内置 fuzzing。适合测试解析器、编解码器、输入校验等接受外部输入的函数。

```go
func FuzzParseInput(f *testing.F) {
    f.Add([]byte("valid input"))
    f.Add([]byte(""))
    f.Fuzz(func(t *testing.T, data []byte) {
        result, err := ParseInput(data)
        if err != nil {
            return // 错误是预期的
        }
        // 验证不变量
        if result.IsValid() && len(data) == 0 {
            t.Error("empty input should not be valid")
        }
    })
}
```

```bash
go test -fuzz=FuzzParseInput -fuzztime=30s ./...
```

## 陷阱：只用 benchmark 不用 pprof/trace

benchmark 告诉你"慢了多少"，pprof 告诉你"慢在哪"，trace 告诉你"为什么慢"。

```bash
# ❌ 只跑 benchmark，不知道瓶颈在哪
go test -bench=.

# ✅ 先 benchmark，再 pprof 定位，再 trace 分析原因
go test -bench=. -cpuprofile=cpu.prof -memprofile=mem.prof ./...
go tool pprof cpu.prof
go test -bench=. -trace=trace.out ./...
go tool trace trace.out
```

## 检查时机

- 看到性能优化任务但没有 profile 数据
- 看到 benchmark 结果但不知道瓶颈在哪
- 看到生产环境 CPU/内存异常但没有 pprof 接口
- 看到接受外部输入的解析函数但没有 fuzz test
- 看到 goroutine 泄漏但没有 trace 分析
