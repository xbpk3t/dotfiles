# Cloudflare Pages Stack (deprecated)

这个 stack 目前为空。

## 迁移记录

- `blog` / `docs` / `me` 已迁到 Workers routes
- `slides` 已删除
- `nextflux` 已从 state 移除
- `music` 已迁到 Workers：
  - Worker 脚本由 `zzz` repo 部署
  - 自定义域名由 `../lucc.dev/workers` stack 管理
  - `music.lucc.dev` 已验证与 `music.yyzw.workers.dev` 内容一致

## 当前状态

- `pages_projects_managed = {}`
- 保留空 stack 作为历史锚点；确认不再使用 Pages 后可以整体删除

## 使用方式

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."

tofu init -reconfigure -input=false
tofu plan -input=false
```
