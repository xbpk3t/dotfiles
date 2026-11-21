# Tailscale Tailnet (terranix)

这个 stack 管理 Tailscale tailnet 的 ACL、DNS preferences、Services 和
device/auth keys（不使用自定义 DERP map，保留默认 region）。现在由
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

state 地址未变：`tailscale_acl.main`、`tailscale_dns_preferences.main`、
`tailscale_service.*`、`tailscale_tailnet_key.device_join`、
`data.tailscale_device.servers[...]`、`tailscale_device_tags.nixos_vps_dev`、
`tailscale_device_key.servers[...]`。

## 历史 import 备注

- `tailscale_acl` / `tailscale_dns_preferences` 是单例，import ID 用任意字符串。
- `tailscale_tailnet_key` 必须用数字 key ID（不是 `tskey-auth-...` 字符串）。

## DX 备注

- ACL 是静态数据，在 Nix 里用 `builtins.toJSON` 生成后作为字符串交给 provider；
  生成结果与 HCL `jsonencode` 字节级一致，plan 保持 no-op。
- `terraform fmt` / `tflint` / `terraform-ls` 对该 stack 不再适用；
  `tofu validate` / `plan` 是最终闸门。
