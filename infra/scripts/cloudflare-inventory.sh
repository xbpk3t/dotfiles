#!/usr/bin/env bash

set -euo pipefail

# 这个脚本的职责只有一个：从 Cloudflare API 拉取“当前真实状态”做 inventory。
# 它不会写入 Terraform state，也不会修改任何 Cloudflare 资源。

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_STAMP="${1:-$(date +%F)}"
OUT_DIR="${ROOT_DIR}/inventory/${DATE_STAMP}/cloudflare"
RAW_DIR="${OUT_DIR}/raw"
SUMMARY_JSON="${OUT_DIR}/summary.json"
SUMMARY_MD="${OUT_DIR}/README.md"

: "${CF_API_TOKEN:?CF_API_TOKEN is required}"
: "${CF_ACCOUNT_ID:?CF_ACCOUNT_ID is required}"
: "${CF_ZONE_ID:?CF_ZONE_ID is required}"

mkdir -p "${RAW_DIR}"

api_get() {
  local path="$1"
  curl -sS \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/${path}"
}

fetch_single() {
  local name="$1"
  local path="$2"
  api_get "${path}" | jq . > "${RAW_DIR}/${name}.json"
}

fetch_paginated_array() {
  local name="$1"
  local path="$2"
  local per_page="${3:-100}"
  local tmp_dir
  local page
  local total_pages
  local body

  tmp_dir="$(mktemp -d)"
  page=1
  total_pages=1

  while :; do
    if [[ "${path}" == *"?"* ]]; then
      body="$(api_get "${path}&page=${page}&per_page=${per_page}")"
    else
      body="$(api_get "${path}?page=${page}&per_page=${per_page}")"
    fi

    printf '%s\n' "${body}" | jq . > "${tmp_dir}/${page}.json"
    total_pages="$(printf '%s\n' "${body}" | jq -r '.result_info.total_pages // 1')"

    if (( page >= total_pages )); then
      break
    fi

    page=$((page + 1))
  done

  jq -s '
    if length == 1 then
      .[0]
    else
      .[0] * {
        result: ([.[].result[]] // []),
        result_info: (
          .[-1].result_info // .[0].result_info
        )
      }
    end
  ' "${tmp_dir}"/*.json > "${RAW_DIR}/${name}.json"

  rm -rf "${tmp_dir}"
}

echo "Fetching Cloudflare inventory into: ${OUT_DIR}"

# 基础元数据：后续做 state 边界、资源归属判断时会用到。
fetch_single "token_verify" "accounts/${CF_ACCOUNT_ID}/tokens/verify"
fetch_single "account" "accounts/${CF_ACCOUNT_ID}"
fetch_single "zone" "zones/${CF_ZONE_ID}"

# zone-scoped resources
fetch_paginated_array "dns_records" "zones/${CF_ZONE_ID}/dns_records"
fetch_paginated_array "email_routing_rules" "zones/${CF_ZONE_ID}/email/routing/rules"

# account-scoped resources
# Cloudflare Pages 这个 endpoint 对 per_page 更严格，不能和其它列表统一写死成 100。
fetch_paginated_array "pages_projects" "accounts/${CF_ACCOUNT_ID}/pages/projects" "10"
fetch_paginated_array "d1_databases" "accounts/${CF_ACCOUNT_ID}/d1/database"
fetch_paginated_array "kv_namespaces" "accounts/${CF_ACCOUNT_ID}/storage/kv/namespaces"
fetch_single "r2_buckets" "accounts/${CF_ACCOUNT_ID}/r2/buckets"
fetch_single "workers_scripts" "accounts/${CF_ACCOUNT_ID}/workers/scripts"
fetch_single "workers_subdomain" "accounts/${CF_ACCOUNT_ID}/workers/subdomain"

jq -n \
  --slurpfile token "${RAW_DIR}/token_verify.json" \
  --slurpfile account "${RAW_DIR}/account.json" \
  --slurpfile zone "${RAW_DIR}/zone.json" \
  --slurpfile dns "${RAW_DIR}/dns_records.json" \
  --slurpfile email "${RAW_DIR}/email_routing_rules.json" \
  --slurpfile pages "${RAW_DIR}/pages_projects.json" \
  --slurpfile d1 "${RAW_DIR}/d1_databases.json" \
  --slurpfile kv "${RAW_DIR}/kv_namespaces.json" \
  --slurpfile r2 "${RAW_DIR}/r2_buckets.json" \
  --slurpfile workers "${RAW_DIR}/workers_scripts.json" \
  --slurpfile workersSubdomain "${RAW_DIR}/workers_subdomain.json" \
  '
  {
    generated_at: now | todate,
    token: {
      id: $token[0].result.id,
      status: $token[0].result.status
    },
    account: {
      id: $account[0].result.id,
      name: $account[0].result.name
    },
    zone: {
      id: $zone[0].result.id,
      name: $zone[0].result.name,
      status: $zone[0].result.status,
      type: $zone[0].result.type
    },
    resources: [
      {
        key: "dns_records",
        scope: "zone",
        count: (if $dns[0].success and ($dns[0].result | type) == "array" then ($dns[0].result | length) else 0 end),
        names: (if $dns[0].success and ($dns[0].result | type) == "array" then ($dns[0].result | map(.name) | unique | sort) else [] end)
      },
      {
        key: "email_routing_rules",
        scope: "zone",
        count: (if $email[0].success and ($email[0].result | type) == "array" then ($email[0].result | length) else 0 end),
        names: (if $email[0].success and ($email[0].result | type) == "array" then ($email[0].result | map(.name // .tag // .id) | sort) else [] end)
      },
      {
        key: "pages_projects",
        scope: "account",
        count: (if $pages[0].success and ($pages[0].result | type) == "array" then ($pages[0].result | length) else 0 end),
        names: (if $pages[0].success and ($pages[0].result | type) == "array" then ($pages[0].result | map(.name) | sort) else [] end)
      },
      {
        key: "d1_databases",
        scope: "account",
        count: (if $d1[0].success and ($d1[0].result | type) == "array" then ($d1[0].result | length) else 0 end),
        names: (if $d1[0].success and ($d1[0].result | type) == "array" then ($d1[0].result | map(.name) | sort) else [] end)
      },
      {
        key: "kv_namespaces",
        scope: "account",
        count: (if $kv[0].success and ($kv[0].result | type) == "array" then ($kv[0].result | length) else 0 end),
        names: (if $kv[0].success and ($kv[0].result | type) == "array" then ($kv[0].result | map(.title // .name // .id) | sort) else [] end)
      },
      {
        key: "r2_buckets",
        scope: "account",
        count: (if $r2[0].success and (($r2[0].result.buckets // []) | type) == "array" then ($r2[0].result.buckets | length) else 0 end),
        names: (if $r2[0].success and (($r2[0].result.buckets // []) | type) == "array" then ($r2[0].result.buckets | map(.name) | sort) else [] end)
      },
      {
        key: "workers_scripts",
        scope: "account",
        count: (if $workers[0].success and ($workers[0].result | type) == "array" then ($workers[0].result | length) else 0 end),
        names: (if $workers[0].success and ($workers[0].result | type) == "array" then ($workers[0].result | map(.id // .tag // .name) | sort) else [] end)
      },
      {
        key: "workers_subdomain",
        scope: "account",
        count: (if $workersSubdomain[0].success then 1 else 0 end),
        names: ([($workersSubdomain[0].result.subdomain // empty)] | map(select(. != "")))
      }
    ]
  }
  ' > "${SUMMARY_JSON}"

ZONE_NAME="$(jq -r '.zone.name' "${SUMMARY_JSON}")"
ACCOUNT_NAME="$(jq -r '.account.name' "${SUMMARY_JSON}")"
GENERATED_AT="$(jq -r '.generated_at' "${SUMMARY_JSON}")"

{
  echo "# Cloudflare Inventory"
  echo
  echo "- generated_at: ${GENERATED_AT}"
  echo "- account: ${ACCOUNT_NAME} (${CF_ACCOUNT_ID})"
  echo "- zone: ${ZONE_NAME} (${CF_ZONE_ID})"
  echo "- token_status: $(jq -r '.token.status' "${SUMMARY_JSON}")"
  echo
  echo "## Resource Summary"
  echo
  jq -r '
    .resources[]
    | "- \(.key): \(.count)"
  ' "${SUMMARY_JSON}"
  echo
  echo "## Notes"
  echo
  echo "- 这是 Cloudflare API 的只读快照，不代表这些资源已经被 Terraform/OpenTofu 纳管。"
  echo "- 这些 raw JSON 用来做 inventory、ownership decision、import planning。"
  echo "- 正式纳管前，先确认每一类资源的 state 边界，再决定是否生成 HCL/import blocks。"
} > "${SUMMARY_MD}"

echo "Cloudflare inventory written to: ${OUT_DIR}"
