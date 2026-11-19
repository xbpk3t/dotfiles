# Cloudflare Email Routing Stack

这个 stack 负责 `lucc.dev` 的 Email Routing rules。

## 当前范围

- 一个定向转发规则：`me@lucc.dev -> jeffcottlu@gmail.com`（Terraform 管理）
- catch-all 规则：live 为 `disabled + drop`，**不由 Terraform 管理**
  - provider v5 的 `cloudflare_email_routing_catch_all.tag` 是 computed-only，
    每次 plan 都会出现永久 diff；详见 `main.tf` 的说明
  - 需要修改时走 Cloudflare Dashboard 或 API

## 有意不放进这个 stack 的内容

- catch-all 规则（原因见 `main.tf`）
- MX / SPF / DKIM records

这些记录虽然服务于 Email Routing，但它们本质上仍然是 DNS ownership，已经放在：

`../dns`

这样做可以避免一个资源组被两个 state 同时管理。

## backend

这个 stack 现在和其它 Cloudflare stacks 一样，统一使用 Cloudflare R2 remote backend。

```bash
export CLOUDFLARE_API_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."
```
