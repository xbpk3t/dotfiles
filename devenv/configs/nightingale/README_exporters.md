# Nightingale 集成 Prometheus Exporters

## 已集成的核心 Exporters

### 1. Blackbox Exporter (端口: 9115)
- **用途**: 黑盒监控，支持 HTTP、TCP、ICMP 探测
- **镜像**: `prom/blackbox-exporter:latest`
- **配置**: `etc-blackbox/blackbox.yml`
- **主要指标**:
  - `probe_success`: 探测是否成功
  - `probe_duration_seconds`: 探测持续时间
  - `probe_http_status_code`: HTTP 响应状态码

### 2. Redis Exporter (端口: 9121)
- **用途**: Redis 数据库监控
- **镜像**: `oliver006/redis_exporter:latest`
- **配置**: 自动连接到 redis:6379
- **主要指标**:
  - `redis_up`: Redis 服务状态
  - `redis_connected_clients`: 连接的客户端数量
  - `redis_memory_used_bytes`: Redis 使用的内存

### 3. SSL Exporter (端口: 9219)
- **用途**: TLS/SSL 证书监控
- **镜像**: `ribbybibby/ssl_exporter:latest`
- **主要指标**:
  - `ssl_cert_not_after`: 证书到期时间
  - `ssl_probe_success`: SSL 探测是否成功

### 4. Cprobe (端口: 8080)
- **用途**: 整合的监控代理，支持多种数据源采集
- **镜像**: `cprobe/cprobe:latest`
- **主要指标**:
  - `cprobe_up`: 服务状态
  - `cprobe_scrape_duration_seconds`: 抓取持续时间

## 启动服务

```bash
cd /path/to/dotfiles/devenv/configs/nightingale
docker-compose up -d
```

## 监控端口

- Nightingale Web UI: http://localhost:17000
- VictoriaMetrics: http://localhost:8428
- Blackbox Exporter: http://localhost:9115
- Redis Exporter: http://localhost:9121
- SSL Exporter: http://localhost:9219
- Cprobe: http://localhost:8080

## 配置说明

1. **Docker Compose**: 添加了所有 exporter 的服务定义
2. **Metrics YAML**: 在 `metrics.yaml` 中添加了所有新指标的中英文描述
3. **Categraf**: 更新了 `input.prometheus/prometheus.toml` 配置来采集新 exporter 的指标

## 使用建议

1. **Blackbox Exporter**: 可用于监控网站可用性、API 响应时间等
2. **Redis Exporter**: 监控 Redis 性能和健康状态
3. **SSL Exporter**: 监控 SSL 证书到期时间，及时提醒续期
4. **Cprobe**: 作为统一的监控数据采集代理，支持更多数据源

## 注意事项

- 所有服务都配置了时区为 `Asia/Shanghai`
- 服务间通过 Docker 网络 `nightingale` 进行通信
- 数据存储在 VictoriaMetrics 中，通过 Nightingale 进行可视化和告警
