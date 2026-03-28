# Nightingale 集成 Prometheus Exporters

## 已集成的核心 Exporters

### 🎯 经典的独立 Exporter 架构

恢复使用传统的独立 exporter 配置，每个服务使用专门的 exporter：

### 1. Blackbox Exporter (端口: 9115)
- **用途**: 黑盒监控，支持 HTTP、TCP、ICMP 探测
- **镜像**: `prom/blackbox-exporter:latest`
- **配置**: `configs/nightingale/etc-blackbox/blackbox.yml`
- **容器名**: `devenv_blackbox_exporter`
- **主要指标**:
  - `probe_success`: 探测是否成功
  - `probe_duration_seconds`: 探测持续时间
  - `probe_http_status_code`: HTTP 响应状态码

### 2. Redis Exporter (端口: 9121)
- **用途**: Redis 数据库监控
- **镜像**: `oliver006/redis_exporter:latest`
- **容器名**: `devenv_redis_exporter`
- **连接**: `n9e-redis:6379`
- **主要指标**:
  - `redis_up`: Redis 服务状态
  - `redis_connected_clients`: 连接的客户端数量
  - `redis_memory_used_bytes`: Redis 使用的内存

### 3. SSL Exporter (端口: 9219)
- **用途**: TLS/SSL 证书监控
- **镜像**: `ribbybibby/ssl_exporter:latest`
- **容器名**: `devenv_ssl_exporter`
- **主要指标**:
  - `ssl_cert_not_after`: 证书到期时间
  - `ssl_probe_success`: SSL 探测是否成功

## 启动服务

```bash
# 启动 Nightingale 及相关监控服务
cd /path/to/dotfiles/devenv
docker-compose --profile n9e up -d

# 或者分别启动各个服务
docker-compose --profile n9e up -d nightingale n9e-mysql n9e-redis n9e-victoriametrics blackbox_exporter redis_exporter ssl_exporter
```

## 监控端口

- Nightingale Web UI: http://localhost:17000
- VictoriaMetrics: http://localhost:8428
- Blackbox Exporter: http://localhost:9115
- Redis Exporter: http://localhost:9121
- SSL Exporter: http://localhost:9219

## 配置说明

1. **Docker Compose**: 在主 `docker-compose.yml` 中配置了所有 exporter 服务
2. **Blackbox 配置**: `configs/nightingale/etc-blackbox/blackbox.yml` 包含黑盒监控配置
3. **Categraf**: `configs/categraf/input.prometheus/prometheus.toml` 配置了指标采集

## 使用建议

1. **Blackbox Exporter**: 专门用于外部服务的黑盒监控（HTTP、TCP、ICMP）
   - 监控网站可用性、API 响应时间
   - 支持多种探测协议和自定义配置

2. **Redis Exporter**: 专业的 Redis 监控工具
   - 监控连接数、内存使用、命中率
   - 跟踪慢查询和持久化状态
   - 提供详细的性能指标

3. **SSL Exporter**: SSL/TLS 证书监控
   - 监控证书到期时间，及时提醒续期
   - 检查证书链完整性和有效性

## 注意事项

- 所有服务都配置了时区为 `Asia/Shanghai`
- 服务间通过 Docker 网络 `backend` 进行通信
- 数据存储在 VictoriaMetrics 中，通过 Nightingale 进行可视化和告警
- 使用成熟稳定的 exporter，避免使用 star 数少且不活跃的项目
