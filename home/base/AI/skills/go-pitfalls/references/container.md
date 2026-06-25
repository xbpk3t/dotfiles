# 容器化环境陷阱

## 问题

Go 运行时不自动感知 cgroup 的 CPU 和内存限制。在 Docker/K8S 中：

- `runtime.NumCPU()` 返回宿主机的 CPU 核数，不是容器的限制
- `GOMAXPROCS` 默认等于 `runtime.NumCPU()`，可能远超容器配额
- GC 的 `GOGC` 目标基于系统内存，不感知 cgroup 内存限制

结果：Go 程序在容器中可能过度使用 CPU（被 throttle）或内存（被 OOM kill）。

## 防法

### GOMAXPROCS

```go
// ✅ 使用 uber 的 automaxprocs，自动感知 cgroup CPU 限制
import _ "go.uber.org/automaxprocs"

func main() {
    // automaxprocs 会在 init 中设置 GOMAXPROCS
    // ...
}
```

或在 Dockerfile 中手动设置：

```dockerfile
ENV GOMAXPROCS=4
```

### GOMEMLIMIT

Go 1.19+ 支持 `GOMEMLIMIT` 环境变量，告诉 GC 内存上限。

```dockerfile
ENV GOMEMLIMIT=1GiB
```

或用 `automemlimit`：

```go
import _ "go.uber.org/automemlimit"
```

### Dockerfile 示例

```dockerfile
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server .

FROM alpine:3.20
COPY --from=builder /app/server /server
ENV GOMAXPROCS=4
ENV GOMEMLIMIT=512MiB
ENTRYPOINT ["/server"]
```

### K8S 部署

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "4"
    memory: "1Gi"
```

确保 `GOMAXPROCS` ≈ CPU limit，`GOMEMLIMIT` ≈ memory limit 的 70-80%（留余量给非堆内存）。

## 检测模式

1. 看到 `Dockerfile` 或 K8S deployment YAML → 检查是否设置了 GOMAXPROCS/GOMEMLIMIT
2. 看到 `runtime.NumCPU()` 在容器中使用 → 提醒可能不准确
3. 看到 `go build` 的 Dockerfile → 建议用多阶段构建减少镜像大小
