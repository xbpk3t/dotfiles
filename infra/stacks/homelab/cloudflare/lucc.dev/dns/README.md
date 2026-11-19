# Cloudflare DNS Stack (terranix pilot)

这个 stack 负责 `lucc.dev` 当前已经存在的 DNS records，是 adopt existing
records，不是从零创建。Email Routing 用到的 MX / SPF / DKIM records 也统一放在
这里，避免 DNS ownership 被拆散。每次改动后的目标仍是 no-op plan。

这个 stack 由 terranix 生成 Terraform JSON。

## 文件

- `terranix.nix`：唯一手写源文件（provider / backend / records / moved / import）
- `generated.tf.json`：terranix 生成物，**不要手改**
- `fleet.generated.json`：DERP DNS 事实，由 fleet metadata 生成，**不要手改**
- `stack.tm.hcl`：Terramate 元数据
- `.terraform.lock.hcl`：provider 版本锁

## DERP records

`derp-dev` / `nva` / `derp-sm-vps-tc` 不手写：

- 事实来源：`hosts/**/meta.nix` 的 `derper.*` 与 `publicIpv4`
- 生成：`task tf:dns:generate`
- 校验：`task tf:dns:check`（CI 也会跑）
- 生成物：`fleet.generated.json`
- terranix 读取 `fleet.generated.json` 生成 `derpRecords`

## 使用方式

1. 提供 Cloudflare token
2. 提供 Cloudflare R2 backend 凭据
3. 生成 JSON、init、plan

需要的环境变量：

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."
```

生成与校验：

```bash
task tf:dns:generate
task tf:terranix
cd infra/stacks/homelab/cloudflare/lucc.dev/dns
tofu init -reconfigure -input=false
tofu validate
tofu plan -input=false
```

CI 会检查 `fleet.generated.json` / `generated.tf.json` 无 diff；
`tofu validate` / `plan` 仍然是最终闸门。

## 回退

迁移 commit 删除了 `main.tf` / `locals.tf` / `imports.tf` / `versions.tf` /
`provider.tf`。需要回退时：

```bash
git revert <terranix-pilot-commit>
```

HCL 原文件仍在 git 历史里，state 地址未改变（`cloudflare_dns_record.records[...]`），
回退不需要动 state。

## DX 备注

- 日常维护优先改 `terranix.nix` 里的 records 数据模型，不要新增独立 resource block。
- 共享记录来自 `infra/facts.nix`；DERP 记录来自 `fleet.generated.json`。
- 改 host meta 后先 `task tf:dns:generate` / `task tf:facts`，再 `task tf:terranix`。
- `terraform fmt` / `tflint` / `terraform-ls` 对该 stack 不再适用；
  改记录时靠 `tofu validate` / `plan` 反馈。
