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

- ACL 是静态数据，在 Nix 里用 `builtins.toJSON` 生成后作为字符串交给 provider；
  生成结果与 HCL `jsonencode` 字节级一致，plan 保持 no-op。
- `terraform fmt` / `tflint` / `terraform-ls` 对该 stack 不再适用；
  `tofu validate` / `plan` 是最终闸门。

## 安全模型（2026-11）

- `tag:vps`：公网/低信任设备（dev、agt、hermes；tc/hk 回来时）
- `tag:ws`：个人设备（macos-ws、nixos-wsl、nixos-usb）
- `tag:svc`：Tailscale Services host（dev）
- `tag:exit`：exit node（dev）
- `tag:ssh`：Tailscale SSH 目标（agt）。SSH 规则的 dst 只接受 tag/autogroup，
  不能写 host alias/IP，所以单独用这个 tag。
- tag 是扁平的；一台设备可叠加多个：dev = `tag:vps` + `tag:svc` + `tag:exit`，
  agt = `tag:vps` + `tag:ssh`。
- ACL 默认拒绝；一次性/非 fleet 设备在 `hosts` 里定义 alias。
  直接写 hostname 会被控制面拒绝（`invalid address`）。
- Tailscale SSH：
  - `tag:ws`（可信 workstation，含 Mac）→ `tag:ssh`（agt）用 `accept`；
  - 手机（user-owned）→ `tag:ssh` 用 `check`（`users = ["luck"]`）。
  - agt 开启 `--ssh` 后，所有到 agt tailnet 22 的连接都由 Tailscale SSH
    裁决；`grants` 只负责网络层放行。tagged 设备不匹配 `autogroup:self`，
    且 `check` 不支持 tag src，所以 tagged ws 只能用 `accept`。
  - 不开 `tag:vps` → `tag:ssh`：VPS/hermes 不用 Tailscale SSH 连 agt。
  - herdr-app 如果无法处理 check，再考虑改成 `accept`（风险更高）。
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
# 需要时：tailscale up --force-reauth
```

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

## Tailnet Lock（手动）

Tailnet Lock 没有 Terraform resource，需在 macos-ws 上执行：

```bash
tailscale lock status           # 记录 macos-ws 的 tlpub:
tailscale lock init --gen-disablements 2 --gen-disablement-for-support \
  --confirm tlpub:<macos-ws-tlpub>
tailscale lock status           # 确认 ENABLED
```

- disablement secrets 只显示一次，存密码管理器/离线；不要放服务器。
- 新设备/重装/自动 auth key 加入的节点会 locked out；在 macos-ws 上：
  `tailscale lock sign nodekey:<new-node-key>`
- 不要用 `tailscale lock sign <auth-key>` 包装共享 auth key（官方不推荐）。
- Tailnet Lock 与 device approval 二选一。
- 只有一个签名节点（macos-ws）；丢失 Mac 时用 disablement secret 关闭 Lock。

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
