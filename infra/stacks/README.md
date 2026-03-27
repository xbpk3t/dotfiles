# Stacks

这里放后续新增的基础设施 stack。

目录约定：

```text
infra/stacks/<scope>/<provider>/<service>/
```

示例：

```text
infra/stacks/homelab/minio/prometheus/
infra/stacks/homelab/cloudflare/dns/
infra/stacks/vps/cloudflare/zone/
```

现有 `infra/minio/*` 目录暂时继续作为 legacy root module 保留，不在这一步强迁。
