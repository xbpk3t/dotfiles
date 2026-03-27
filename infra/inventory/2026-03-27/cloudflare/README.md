# Cloudflare Inventory

- generated_at: 2026-03-27T09:16:31Z
- account: HappyHacking (96540bd100b82adba941163704660c31)
- zone: lucc.dev (1c07a1b84d8273f4dfa6c3adce513f94)
- token_status: active

## Resource Summary

- dns_records: 24
- email_routing_rules: 2
- pages_projects: 6
- d1_databases: 3
- kv_namespaces: 2
- r2_buckets: 8
- workers_scripts: 1
- workers_subdomain: 1

## Notes

- 这是 Cloudflare API 的只读快照，不代表这些资源已经被 Terraform/OpenTofu 纳管。
- 这些 raw JSON 用来做 inventory、ownership decision、import planning。
- 正式纳管前，先确认每一类资源的 state 边界，再决定是否生成 HCL/import blocks。
