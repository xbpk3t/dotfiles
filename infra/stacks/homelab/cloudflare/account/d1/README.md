# Cloudflare D1 Stack

这个 stack 负责当前 Cloudflare account 下已经存在的 D1 databases。

## 生成方式

这个 stack 使用 terranix：源文件是 `terranix.nix`，生成物是
`generated.tf.json`。改完源文件后运行：

```bash
task tf:terranix
```

不要手改生成物；`git revert` 会恢复迁移前的 HCL 文件。

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

- 这个 stack 当前是 `adopt existing databases`，不是从零创建。
- `terranix.nix` 的 import 块会把 live D1 databases 导入 state。
- 第一次目标应该是 `no-op plan`。
