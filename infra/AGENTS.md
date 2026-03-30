# Infra Notes

- `infra/inventory` 视为本地盘点产物，不入仓库。
- inventory 默认应写到 `infra/.inventory/` 这类被 `.gitignore` 忽略的路径。
- 如果为了临时排查生成了新的 inventory 数据，处理完成后应删除，不要提交。
- 现有 `infra/README.md`、`infra/cloudflare/README.md` 等历史文档即使仍提到 `infra/inventory`，后续执行以本文件约定为准。
