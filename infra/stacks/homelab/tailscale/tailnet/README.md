# Tailscale Tailnet (terranix)

这个 stack 管理 Tailscale tailnet 的 ACL、DNS preferences、Services 和
device/auth keys（custom DERP map 只加入 agt，保留默认 region）。现在由
terranix 生成 Terraform JSON。

## 文件

- `terranix.nix`：唯一手写源文件（ACL / provider / resources）
- `generated.tf.json`：terranix 生成物，**不要手改**
- `stack.tm.hcl`：Terramate 元数据
- `.terraform.lock.hcl`：provider 版本锁

## 生成与校验

```bash
task tf:terranix-tailscale
cd infra/stacks/homelab/tailscale/tailnet
tofu init -reconfigure -input=false
tofu validate
tofu plan -input=false
```

CI 会重新生成并检查 `generated.tf.json` 无 diff。

## 回退

迁移 commit 删除了 `main.tf` / `locals.tf` / `imports.tf` / `versions.tf` /
`provider.tf`。需要回退时：

```bash
git revert <tailscale-terranix-commit>
```

terranix 迁移当时（LUC-552）state 地址保持不变：`tailscale_acl.main`、
`tailscale_dns_preferences.main`、`tailscale_service.*`、
`tailscale_tailnet_key.device_join`、`data.tailscale_device.servers[...]`、
`tailscale_device_tags.nixos_vps_dev`、`tailscale_device_key.servers[...]`。

LUC-556 的安全优化拆分了 auth key：

- `tailscale_tailnet_key.device_join` → `vps_join` / `ws_join`
  （旧 key 已 revoke；新的 tagged key 在 restore 时创建）
- 设备 tag/key 仍使用 per-device 地址：
  `data.tailscale_device.servers[...]`、`tailscale_device_tags.<real_name>`、
  `tailscale_device_key.servers[...]`；代码里的 `moved` 块负责从旧
  `devices[...]` 地址迁移。

回退到 LUC-552 的 commit 时，需要先 `tofu state rm` 新地址，再按旧地址
import；只 `git revert` 会让旧地址计划为 create。

## 历史 import 备注

- `tailscale_acl` / `tailscale_dns_preferences` 是单例，import ID 用任意字符串。
- `tailscale_tailnet_key` 必须用数字 key ID（不是 `tskey-auth-...` 字符串）。

## DX 备注

- ACL 由 Nix 生成后经 `lib.tf.ref` 以 HCL 表达式交给 provider：
  `var.tailscale_acl_allow_all` 选择 Phase 1（`*→*`）或 Phase 2（最小权限）。
  默认 false；Phase 2 生效后 `plan` 保持 no-op。若用 `-var` 打开过 Phase 1，
  记得用默认值再 apply 一次恢复最小权限。
- `terraform fmt` / `tflint` / `terraform-ls` 对该 stack 不再适用；
  `tofu validate` / `plan` 是最终闸门。

## 安全模型（2026-11）

- `tag:vps`：公网/低信任设备（dev、agt、hermes；tc/hk 回来时）
- `tag:ws`：个人设备（macos-ws、nixos-wsl、nixos-usb，以及手动打 tag 的手机 Redmi Note 13 Pro）
- `tag:svc`：Tailscale Services host（dev）
- `tag:exit`：exit node（dev）
- tag 是扁平的；一台设备可叠加多个：dev = `tag:vps` + `tag:svc` + `tag:exit`，
  agt = `tag:vps`。
- ACL 默认拒绝；一次性/非 fleet 设备在 `hosts` 里定义 alias。
  直接写 hostname 会被控制面拒绝（`invalid address`）。
- Tailscale SSH 已关闭（2026-11-21，LUC-556 D 方案）：agt 显式
  `--ssh=false`。所有 SSH 统一走 OpenSSH over tailnet，由
  `tag:ws → tag:vps:22` 的 grant 放行；deploy-rs 的 root 连接恢复正常。
  手机 herdr-app 改为自带 SSH key（`tag:ws` 仍适用），不再依赖 Tailscale SSH。
  不再有 `tag:ssh`、`ssh` ACL 规则和 sshTests。
- 手机（`nod-am`）已打 `tag:ws`，与 Mac 共享 `tag:ws` 的 grants/services/SSH；
  唯一区别是手机保留 exit node（`nod-am → autogroup:internet via tag:exit`），
  Mac 不走 exit。手机不在 fleet `deviceTags` 里，tag 是手动/API 打的。
- 维护通道：`agt → macos-ws:22` 允许从 agt 部署/维护 Mac，不是最终信任
  模型；有固定的可信开发机后删除。
- `deviceTags` 只列当前实际在 tailnet 的设备；离线/未加入的设备不要加，
  用 tagged auth key 加入时会自动带 tag。加错设备会让 `tofu plan` 的
  data source 查不到 hostname。

## 两阶段 rollout（必须先 tag 再 deny）

Phase 1：保留 `*→*`，只打 tag / 重新认证：

```bash
cd infra/stacks/homelab/tailscale/tailnet
tofu apply -var tailscale_acl_allow_all=true
```

然后在每台设备上重新认证/确认 tag：

```bash
tailscale status --json | jq '.Self.Tags'
# 需要时用该角色的 tagged key 重新认证（key 从 Phase 1 的 tofu output 取，见下方
# Auth keys）。不要用不带 key 的 `tailscale up --force-reauth`——那会以用户身份
# 重新登录并清掉 tag：
tailscale up --force-reauth --authkey=<vps_join_key 或 ws_join_key>
```

注意：auth key 只带角色 tag（`tag:vps` / `tag:ws`）。重新认证会把设备 tag
重置为该 key 的 tag 集合；dev 的 `tag:svc`/`tag:exit` 等 per-device 能力 tag
由 `tailscale_device_tags` 管理，re-auth 后需要再跑一次 `tofu apply` 恢复
（否则服务/exit node 会短暂失效）。

Phase 2：默认最小权限（`tailscale_acl_allow_all=false`）：

```bash
tofu apply
```

回滚：`tofu apply -var tailscale_acl_allow_all=true`，或从控制台恢复 ACL。

## Auth keys / sops

Phase 1 会创建两个 tagged key；取出并写入 sops：

```bash
tofu output -raw vps_join_key
tofu output -raw ws_join_key
task nix:sk:edit
# 写入：tailscale/auth_key_vps、tailscale/auth_key_ws
```

然后部署 Nix 侧。旧的 `tailscale/auth_key` 在所有设备迁移完后 revoke/删除。

## Tailnet Lock

2026-11-21 已关闭并移除（LUC-556）。启用后新设备/重装/重新认证都需要在
macos-ws 上 `tailscale lock sign`，对当前单人 fleet 的操作成本高于收益。
当前控制面依赖 ACL + tagged auth key；如果将来重新启用，需要重新
`tailscale lock init` 并生成新的 disablement secrets。

## DERP

- 只把 agt（`nva.lucc.dev`）加入 custom `derpMap`；dev/tc 的 derper 已关。
- agt 需要 TCP 10043 + UDP 10078 入站；STUN 10078 已从 Mac 验证
  （region 900 ≈ 30ms）。若新环境不响应，检查腾讯云安全组和
  mihomo policy route（`derper-policy-route`）。
- 如果 Mac↔dev 出现单向，先把 agt 从 `derpMap` 移除（回退到默认 DERP + peer relay）。

## Taildrop / Taildrive / Funnel

- Funnel / Taildrive 未配置 `nodeAttrs`，默认关闭。
- Taildrop 是 tailnet 级设置；在 admin console 的 General settings 关闭 `Send Files`
  （provider 没有对应 resource）。
