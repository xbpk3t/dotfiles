# Cloudflare Pages Stack

这个 stack 负责当前 Cloudflare account 下已经存在的 Pages projects。

## 使用方式

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."

# docs 项目的 runtime/build secret 不直接写入仓库
export TF_VAR_pages_docs_cfp_pwd="..."
```

然后执行：

```bash
tofu init
tofu plan
```

## 注意

- 这个 stack 当前是 `adopt existing projects` 的基线，不是最终的人类友好抽象。
- OpenTofu 的 `s3` backend 底层仍然读取 `AWS_*` 变量名，但仓库 task 已经帮你把 `CF_R2_AK` / `CF_R2_SK` 映射过去了，日常不需要再手写 `AWS_*`。
- `docs` 的 `CFP_PASSWORD` 是 live secret，必须通过 `TF_VAR_pages_docs_cfp_pwd` 注入，否则 plan 会看到 drift。
- `music` 当前已经绑定了一个 D1 database，所以这里直接按 live binding 声明。
- `web_analytics_token` 也是 sensitive，当前故意不落仓库。
- 日常维护时优先修改 `locals.tf` 里的 `pages_projects` 数据模型，而不是继续复制完整 project resource。
