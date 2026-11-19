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

## 回退（Pages project 已删除）

- 在 Cloudflare 重新创建 Pages project `music`（或把 zzz 的部署切回 Pages）
- 重新绑定 `music.lucc.dev` custom domain
- 在 DNS stack 新增 `music` CNAME，`id = null`（不要复用已删除记录的 id）
- 删除本 stack 的 custom domain

注意：直接 `git revert` 会带回旧 DNS record 的 import id；旧记录已经删除，
import 会失败。回退时把 `id` 改成 `null`，或 import 新建出来的 record。

## 注意

- custom domain 和 DNS stack 不能同时管理同一个 hostname；`music` 记录已经从
  DNS stack 移除，ownership 归本 stack。
