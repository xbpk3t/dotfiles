# Cloudflare DNS Stack

这个 stack 负责 `lucc.dev` 当前已经存在的 DNS records。

## 使用方式

1. 提供 Cloudflare token
2. 提供 Cloudflare R2 backend 凭据
3. `tofu init`
4. `tofu plan`

需要的环境变量：

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."
```

## 注意

- 这个 stack 当前是 `adopt existing records`，不是从零创建。
- `imports.tf` 会把 live DNS records 导入 state。
- 第一次目标应该是 `no-op plan`。
- Email Routing 用到的 MX / SPF / DKIM records 也统一放在这个 DNS stack，避免 DNS ownership 被拆散。
- 日常维护时优先修改 `locals.tf` 里的 `dns_records_managed`，而不是继续新增独立 resource block。
- DERP records（`derp-dev` / `nva` / `derp-sm-vps-tc`）不手改 `locals.tf`：
  - 事实来源：`hosts/**/meta.nix` 的 `derper.*` 与 `publicIpv4`
  - 生成：`task tf:dns:generate`
  - 校验：`task tf:dns:check`（CI 也会跑）
  - 生成物：`fleet.generated.json`（需要提交）
