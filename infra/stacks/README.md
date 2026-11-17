# Stacks

这里放基础设施 stack，按 Terramate stack 编目。

目录约定：

```text
infra/stacks/<scope>/<provider>/<service>/
```

当前 stack：

```text
infra/stacks/homelab/cloudflare/account/{d1,kv,pages,r2}/
infra/stacks/homelab/cloudflare/lucc.dev/{dns,email-routing}/
infra/stacks/homelab/tailscale/tailnet/
```

- `scope`：部署边界（`homelab`、`vps` 等）
- `provider`：API 边界
- `service`：实际 stack 单元

每个 stack 是独立 root module，单独 plan/apply；不要把所有资源塞进一个 state。
