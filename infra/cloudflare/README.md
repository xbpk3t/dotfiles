# Cloudflare

这里存放 Cloudflare 的纳管设计，而不是直接堆放旧版导出的 Terraform 文件。

## 当前策略

Cloudflare 先走 `inventory -> ownership -> import/adopt -> managed stacks` 的路径：

1. 先从 Cloudflare API 拉取当前真实资产
2. 再判断哪些资源要进入 Terraform/OpenTofu
3. 最后才在 `infra/stacks/` 下建立正式 stack

这样做的原因：

- 当前 dashboard 和旧 TF 已经明显 drift
- 直接从旧 HCL 反推会把历史误差固化下来
- Cloudflare provider / resource model 本身也在演进，不能假设旧资源名仍然是最优建模

## 目录职责

- `infra/scripts/cloudflare-inventory.sh`
  - 只读盘点脚本
  - 从 API 拉 raw JSON 快照
- `infra/inventory/<date>/cloudflare/`
  - 每次盘点的输出
  - 用于对齐当前真实状态
- `infra/stacks/homelab/cloudflare/`
  - 已经收编进 OpenTofu/Terramate 的正式 stack
  - 当前已覆盖 DNS、Email Routing、Pages、D1、KV、R2

## Secret 约定

脚本运行时通过环境变量注入，不把 token 写入仓库：

- `CF_API_TOKEN` 或 `CLOUDFLARE_API_TOKEN`
- `CF_ACCOUNT_ID`
- `CF_ZONE_ID`

Cloudflare stacks 的 remote state 则单独走 R2 backend：

- `CF_R2_AK`
- `CF_R2_SK`

说明：

- provider 读的是 `CLOUDFLARE_API_TOKEN`
- inventory task 会把 `CLOUDFLARE_API_TOKEN` 透明映射给脚本需要的 `CF_API_TOKEN`
- OpenTofu backend 底层仍然读 `AWS_*`，但 task 会把 `CF_R2_AK` / `CF_R2_SK` 透明映射过去

## 运行方式

```bash
export CF_API_TOKEN="..."
export CF_ACCOUNT_ID="..."
export CF_ZONE_ID="..."

./infra/scripts/cloudflare-inventory.sh
```

输出目录默认是：

```text
infra/inventory/YYYY-MM-DD/cloudflare/
```

## 当前边界

当前这一轮没有直接把 Workers scripts 纳入 Terraform。

原因不是能力不够，而是这样做会把整段 Worker 源码和 bindings 一起塞进 state 对应的 HCL，
维护性会明显变差。现阶段更合理的做法是先把 Workers 保留在 inventory 里，等后续确定
源码仓库、发布链路和 secret ownership 之后，再决定是否正式纳管。

## Remote State

Cloudflare stacks 现在统一使用专用的 R2 bucket：

- bucket: `luck-dotfiles-opentofu-state`
- endpoint: `https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com`

这个 bucket 是 bootstrap resource，当前通过 API / S3-compatible tooling 预先创建，不由同一套 Cloudflare stack 自举创建。
