# HTTP 陷阱

## 陷阱 1：DefaultClient 无超时

`http.DefaultClient` 没有设置 Timeout。生产环境中一个没有超时的 HTTP 请求会一直挂到系统资源耗尽。

```go
// ❌ 永远不要在生产代码里用
resp, err := http.Get("https://api.example.com/data")
resp, err := http.Post(url, bodyType, body)

// ✅ 自定义 Client
client := &http.Client{
    Timeout: 10 * time.Second,
}
resp, err := client.Get("https://api.example.com/data")
```

## 陷阱 2：err handler 后缺 return

HTTP handler 中 `WriteHeader` 或 `Write` 后没有 return，导致继续执行正常逻辑，返回 200 + error body。

```go
// ❌
func handler(w http.ResponseWriter, r *http.Request) {
    data, err := getData()
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        w.Write([]byte(err.Error()))
        // 缺 return！继续执行下面的代码
    }
    w.Write(data) // 又写了一次，body 混乱
}

// ✅
func handler(w http.ResponseWriter, r *http.Request) {
    data, err := getData()
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        w.Write([]byte(err.Error()))
        return // 必须 return
    }
    w.Write(data)
}
```

## 陷阱 3：resp.Body 未关闭

```go
// ❌
resp, _ := http.Get(url)
body, _ := io.ReadAll(resp.Body)
// 没有 Close，连接泄漏

// ✅
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()
body, _ := io.ReadAll(resp.Body)
```

## 陷阱 4：连接池配置

```go
// ❌ 使用默认 Transport
client := &http.Client{Timeout: 10 * time.Second}

// ✅ 高并发场景自定义连接池
client := &http.Client{
    Timeout: 10 * time.Second,
    Transport: &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
    },
}
```

## 陷阱 5：context 传递

```go
// ❌ 不传 context，无法取消
resp, err := http.Get(url)

// ✅ 传 context，支持取消和超时
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
resp, err := client.Do(req)
```

## 检测模式

1. `http.Get`/`http.Post` 直接调用 → 改为自定义 Client
2. HTTP handler 中 `WriteHeader`/`Write` 后没有 `return` → 添加 return
3. `http.Get` 后没有 `defer resp.Body.Close()` → 添加
4. 高并发 HTTP client 无自定义 Transport → 检查连接池配置
5. HTTP 请求不传 context → 检查是否需要超时/取消支持
