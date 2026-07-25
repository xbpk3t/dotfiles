# zzz — personal prompt router

## 动机

这些 prompts 的 source，都是我日常经常输入的内容，以及之前存在
alfred snippets 里的。为了在 export 的 markdown 里不出现大段重复，
把它们做到 skills 里，通过 slash 直接调用。

## 命名与 frontmatter

- `name` 必须等于 **filename stem**（路由名 = 文件名）。
- `role`: `atom` | `composite`（先二分即可）。
- `description`: 短说明。
- `pipeline`: 仅 composite；**name 列表**（S 方案），触发细节写在 body。

```yaml
# atom
---
name: brk
role: atom
description: …
---

# composite
---
name: 3w3h
role: composite
description: …
pipeline:
  - brk
  - vs
---
```

改完 prompt 后在 zzz 目录执行：`nu gen-aliases.nu`（校验 name/role/pipeline 后写 aliases.json）。

## dot file 约定

默认不读取 `.md` 作为路由入口（gen 与 zzz.nu 都不收录 hidden）。
hidden file 仅作为 cross-reference 目标，供其他 prompt 引用。

## cross-reference / pipeline

- composite 的 hard 依赖写在 frontmatter `pipeline`；body 写何时执行。
- soft 后续只写在 body（如 repo 文末可参考 vs），不进 pipeline。
- 避免 loop hell；gen 会做简单环检测。

## 维护

- 定期调用 `stats-zzz` 看频次，低频可 hidden 或删。
- 保证 prompts 质量与使用频率。
