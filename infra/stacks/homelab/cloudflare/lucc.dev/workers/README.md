# Cloudflare Workers Stack (lucc.dev)

这个 stack 管理 `lucc.dev` 下由 Cloudflare Workers 承接的自定义域名。

## 当前范围

- `music.lucc.dev` -> Worker `music`
  - Worker 脚本由 `zzz` repo 部署
  - 这个 stack 只负责 custom domain（Cloudflare 会自动创建/接管 DNS 记录和证书）

## Cutover

`music` 从 Pages 迁移到 Workers 的顺序：

1. 确认 `https://music.yyzw.workers.dev` 返回 200
2. 解绑 Pages project `music` 的 `music.lucc.dev`（以及历史 typo `musci.lucc.dev`）
3. DNS stack 删除旧的 `music.lucc.dev` CNAME（指向 `music-6gm.pages.dev`）
4. `tofu apply` 本 stack，创建 Worker custom domain
5. 验证 `https://music.lucc.dev` 200
6. 删除 Pages project `music`

## 回退

在 Pages project 删除前：

- 重新把 `music.lucc.dev` 加回 Pages custom domain
- DNS stack `git revert` 恢复旧 CNAME 并 apply
- 删除本 stack 的 custom domain

## 注意

- custom domain 和 DNS stack 不能同时管理同一个 hostname；`music` 记录已经从
  DNS stack 移除，ownership 归本 stack。
