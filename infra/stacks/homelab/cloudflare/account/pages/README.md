# Cloudflare Pages Stack

这个 stack 目前只负责 `music` 一个 Pages project。

## 当前范围

- `music`：长三角青少年小提琴艺术展演活动站点，live 绑定 D1 `vscs`。
- 旧项目 `blog` / `docs` / `me` 已经迁到 Workers routes；`slides` 已删除；
  `nextflux` 已从 state 移除。
- `music` 计划后续迁到 Workers Static Assets；迁移完成前保留在 Pages，
  避免站点中断。

## 使用方式

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."

tofu init -reconfigure -input=false
tofu plan -input=false
```

## 注意

- 这个 stack 是 `adopt existing projects` 的基线，不是最终的人类友好抽象。
- OpenTofu 的 `s3` backend 底层仍然读取 `AWS_*` 变量名，但仓库 task 已经帮你把
  `CF_R2_AK` / `CF_R2_SK` 映射过去了，日常不需要再手写 `AWS_*`。
- 不要显式写 `path_excludes` / `preview_branch_excludes = []`：provider v5 会把
  空列表读回 null，apply 后报 `inconsistent result after apply`。
- `web_analytics_token` 是 sensitive，当前故意不落仓库。
- 日常维护时优先修改 `locals.tf` 里的 `pages_projects` 数据模型，而不是继续复制
  完整 project resource。
