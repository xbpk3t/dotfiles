# Cloudflare D1 Stack

这个 stack 负责当前 Cloudflare account 下已经存在的 D1 databases。

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
- `imports.tf` 会把 live D1 databases 导入 state。
- 第一次目标应该是 `no-op plan`。
