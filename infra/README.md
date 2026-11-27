# Infra

`infra/` 采用“原生 Terraform/OpenTofu root module + Terramate 编排层”的轻量方案。

目标不是把现有代码重写成另一套框架，而是：

- 给 stack 一个统一的元数据入口
- 新增 stack 时，provider/backend/命名约定不再散落
- 为“盘点现有云资源 -> 逐步纳管到 IaC”留出稳定路径

## 当前目录

```text
infra/
  stacks/
    homelab/
      cloudflare/
        account/{d1,kv,r2}/
        lucc.dev/{dns,email-routing}/
      tailscale/tailnet/
  .taskfile/              # OpenTofu/Cloudflare inventory 任务
  cloudflare/             # Cloudflare 纳管策略与 inventory 说明
```

> 注：inventory 为本地盘点产物，不入仓库（见 `infra/AGENTS.md`）。
> 历史 `infra/cloud-init/aliyun-vps.yaml` 已删除：模板没有被任何链路引用，
> 当前 VPS 走 NixOS + Ansible，不再维护 Ubuntu/Debian cloud-init 模板。

## 当前 stack

每个 stack 都是独立 root module，由 Terramate 编目，使用 OpenTofu + R2 remote state：

- `stacks/homelab/cloudflare/lucc.dev/dns`
- `stacks/homelab/cloudflare/lucc.dev/email-routing`
- `stacks/homelab/cloudflare/lucc.dev/workers`（`music.lucc.dev` -> Worker `music`）

> Pages stack 已移除：live 已无 Pages project。KV stack 只纳管 `docs-session`；
> `__me-workers_sites_assets` 是 Workers Sites 自动创建的 assets namespace，
> 仍有数据，刻意不纳管。

- `stacks/homelab/cloudflare/account/d1`
- `stacks/homelab/cloudflare/account/kv`
- `stacks/homelab/cloudflare/account/r2`
- `stacks/homelab/tailscale/tailnet`

历史 `infra/minio/tf-s3-backend` 已移除；Cloudflare state 统一放在 R2 bucket
`luck-dotfiles-opentofu-state`（bootstrap resource，不由同一套 stack 自举创建）。

## 为什么是 Terramate

- 当前 TF 规模还小，直接上 Atmos 这类平台级框架会过度设计
- Terragrunt 更偏 wrapper；这里更需要对现有目录侵入更小的编排层
- Terramate 先只做 stack 编目，后面再逐步补 code generation 和 orchestration

换句话说，Terramate 是 `flake-parts` 那种“组织层”，不是第二套 Terraform 语言。

## 新增 stack 怎么放

```text
infra/stacks/<scope>/<provider>/<service>/
```

示例：

```text
infra/stacks/homelab/cloudflare/lucc.dev/dns/
infra/stacks/homelab/cloudflare/account/d1/
infra/stacks/homelab/tailscale/tailnet/
```

- `scope` 表达部署边界（`homelab`、`vps` 等）
- `provider` 只表示 API 边界
- `service` 是实际 stack 单元，便于单独 plan/apply

不要继续平铺在 `infra/<provider>/<service>` 下。

## 盘点现有云资源

1. 先做 inventory，不直接重构
2. 按 provider / account / project / region 导出资源
3. 输出到被忽略的 `infra/.inventory/<date>/`（不提交）
4. 标记哪些资源已由 IaC 管理，哪些仍是手工资源
5. 先纳管高价值资源：DNS、对象存储、网络、IAM
6. import / generated config 只作为迁移草稿，不直接当最终代码

## 推荐命令

```bash
cd /path/to/dotfiles

task tf                    # 列出 stacks
task tf:validate STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
task tf:plan STACK=infra/stacks/homelab/cloudflare/account/d1
task tf:apply STACK=infra/stacks/homelab/cloudflare/account/d1

terramate list --tags layer-infra
terramate run --tags layer-infra -- tofu plan
```

Cloudflare inventory：

```bash
task tf:inventory
```

本地完整校验（与 CI `validate` job 一致）：

```bash
nix develop .#infra
task tf:check
```

## GitOps / CI

`.github/workflows/infra.yml` 是 infra 的 CI 控制面：

- **PR**：对 `terramate list --tags layer-infra` 选出的全部 stack 逐个跑
  `tofu plan`（只读）。fork PR 拿不到 secrets，会跳过；同仓分支 PR 正常跑。
- **所有 PR / push**：`validate` job 不依赖 secrets，跑 `task tf:check`
  （terranix freshness、actionlint、`tofu fmt -check`、全 stack
  `tofu validate`）。fork PR 也能拿到这层检查。
- **main**：merge 后**默认不自动 apply**。确认仓库里的 drift 可接受后，可在
  仓库变量里设置 `INFRA_AUTO_APPLY=true` 打开自动 apply；或者手动触发
  `workflow_dispatch` 并选择 `mode=apply`。apply job 绑定 `environment: infra`，
  建议在 GitHub 仓库设置里给该 environment 配 required reviewers，形成人工批准闸门。
- **schedule**：每天 03:17 UTC 跑 `tofu plan -detailed-exitcode`；exit 2 表示
  云端有 drift，job 失败并触发通知。
- **workflow_dispatch**：手动选择 `plan` / `apply` / `drift`，`stack` 填单个
  stack 路径或 `all`。

需要的 repository secrets：

| Secret | 用途 |
| --- | --- |
| `CF_R2_AK` / `CF_R2_SK` | R2 S3-compatible backend 凭据 |
| `CLOUDFLARE_API_TOKEN` | Cloudflare provider token |
| `TAILSCALE_API_KEY` | Tailscale provider token |

所有 stack 的 backend 已启用 `use_lockfile = true`，用 R2 的条件写做 state
locking（OpenTofu 1.13.9 实测可用），不再需要 DynamoDB 锁表。workflow 另外用
`concurrency` 按 stack 串行化 apply。

### Token 权限

- **plan / drift**：Cloudflare Email Routing / DNS / Workers 的 Read
  权限即可；R2 state backend 需要 `CF_R2_AK` / `CF_R2_SK` 的读写。
- **apply**：上述资源需要 Edit 权限；`CLOUDFLARE_API_TOKEN` 在 GitHub 里必须
  使用 write token。
- 本地 / CI 的 `CLOUDFLARE_API_TOKEN` 来自 SOPS `cf/token/all`
  （全能 read/write token）。rotate 时用：

```bash
printf '%s' '"cfat_..."' | sops set --value-stdin secrets/secrets.yaml \
  '["cf"]["token"]["all"]'
```

不要把 token 贴到聊天/commit 里；rotate 后同步更新 GitHub secret。

### Apply 运营清单

- [ ] GitHub secret `CLOUDFLARE_API_TOKEN` 使用有 Edit 权限的 token
- [ ] `infra` environment 配置 required reviewers
- [ ] 需要 main 自动 apply 时设置仓库变量 `INFRA_AUTO_APPLY=true`
- [ ] 每次 drift 变红时先确认是否预期，再手动 `workflow_dispatch mode=apply`
- [ ] 回退：`git revert` + 对应 stack apply；Workers 域名 ownership
      的变更要先确认 custom domain/DNS 顺序

本地复现（与 CI 使用同一套工具）：

```bash
nix develop .#infra
cd infra/stacks/homelab/cloudflare/lucc.dev/dns
tofu init -reconfigure -input=false
tofu plan -input=false
```

## 共享 infra facts

`infra/facts.nix` 是 Nix 与 Terraform 共享的事实源：

- Cloudflare account / zone id、R2 endpoint / bucket 名称
- D1 database id（docs / vscs）
- `nixos-vps-dev` 的公网 IP（api / as / rsshub 共用）
- Tailscale tailnet 名称
- 由 host meta 派生的共享 DNS 记录（api / as / rsshub）；DERP 记录
  （derp / nva）由 DNS terranix 直接 import `lib/fleet` 派生

`infra/facts.nix` 是共享事实源；所有 terranix stack 直接 `import` 它，
不再生成中间 JSON。改 `hosts/*/meta.nix` 或 `infra/facts.nix` 后重跑
`task tf:terranix` 即可。CI 会做 terranix freshness 检查。

## terranix stacks

目前所有 stack 都使用 terranix：

- `infra/stacks/homelab/cloudflare/lucc.dev/dns`
- `infra/stacks/homelab/cloudflare/lucc.dev/email-routing`
- `infra/stacks/homelab/cloudflare/lucc.dev/workers`
- `infra/stacks/homelab/cloudflare/account/d1`
- `infra/stacks/homelab/cloudflare/account/kv`
- `infra/stacks/homelab/cloudflare/account/r2`
- `infra/stacks/homelab/tailscale/tailnet`

每个 stack 的源文件是 `terranix.nix`，生成物是同目录的
`generated.tf.json`，由 `task tf:terranix` 统一写入，不要手改。
共享的 `required_version` / provider / R2 backend 骨架在
`infra/terranix-lib.nix`；资源、import、moved 等语义仍留在各 stack。

共同约定：

- 回退：`git revert` 对应 commit 即可恢复被删除的 HCL 文件（git 历史保留）
- 这些 stack 不再适用 `terraform fmt` / `tflint` / `terraform-ls` 的 HCL 能力；
  `tofu validate` / `tofu plan` 仍是有效闸门
- 新增 stack 时优先用 terranix；默认不引入新 HCL

## 下一步

- 按需补充 `infra/.inventory/<date>/` 盘点清单
- 新资源优先进入 `stacks/<scope>/<provider>/<service>/`
- 不要为了“框架整齐”先做大规模抽模块或改 state key

<!-- infra-gate verification: infra path -->
