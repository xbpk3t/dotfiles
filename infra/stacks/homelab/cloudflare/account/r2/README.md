# Cloudflare R2 Stack

这个 stack 负责当前 Cloudflare account 下已经存在的 R2 buckets。

## 注意

- 这是一版 `adopt existing buckets` 基线，不是最终的人类友好抽象。
- 当前先只固化 bucket ownership；更细的 lifecycle / policy / public access 规则后续再拆。
- `luck-dotfiles-opentofu-state` 是 backend bootstrap bucket，当前故意不放进这个 stack，避免 state bucket 和自身 state 互相依赖。
- 第一次目标仍然是 `no-op plan`。
