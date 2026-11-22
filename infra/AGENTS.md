# Infra Notes

- `infra/inventory` 视为本地盘点产物，不入仓库。
- inventory 默认应写到 `infra/.inventory/` 这类被 `.gitignore` 忽略的路径。
- 如果为了临时排查生成了新的 inventory 数据，处理完成后应删除，不要提交。
- 现有 `infra/README.md`、`infra/cloudflare/README.md` 等历史文档即使仍提到 `infra/inventory`，后续执行以本文件约定为准。
- `infra/facts.nix` 是唯一事实源；terranix stack 直接 import，不存在中间 facts JSON。
- 各 stack 的 `generated.tf.json` 由同目录 `terranix.nix` 生成，不要手改；改完跑 `task tf:terranix`。
- 共享的 backend/provider/版本骨架在 `infra/terranix-lib.nix`，不要在 stack 里重复写。
