# Cloudflare KV Stack

这个 stack 负责当前 Cloudflare account 下已经存在的 KV namespaces。

## 注意

- 这个 stack 当前是 `adopt existing namespaces`。
- KV 本身是 account 级资源，所以单独放在 account scope state。
- backend 已经切到 Cloudflare R2；日常运行请提供 `CF_R2_AK` / `CF_R2_SK`。
- 第一次目标仍然是 `no-op plan`。
