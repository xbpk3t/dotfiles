# Cloudflare KV Stack

这个 stack 负责当前 Cloudflare account 下由 Terraform 管理的 KV namespaces。

## 当前范围

- `docs-session`：唯一纳管的 namespace
- `__me-workers_sites_assets`：Workers Sites 自动创建的 assets namespace，
  仍有数据；**刻意不纳管**，避免和 Worker 部署链路双写

## 生成方式

这个 stack 使用 terranix：源文件是 `terranix.nix`，生成物是
`generated.tf.json`。改完源文件后运行：

```bash
task tf:terranix
```

不要手改生成物。

## 使用方式

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."
tofu init -reconfigure -input=false
tofu plan -input=false
```

## 注意

- 这是 `adopt existing namespace`，不是从零创建。
- `terranix.nix` 的 import 块会把 `docs-session` 导入 state。
- 初始目标是 import 后 `no-op plan`。
