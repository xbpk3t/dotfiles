#!/usr/bin/env nu

# Cloudflare inventory — pull live state from Cloudflare API as a read-only snapshot.
# Usage: nu cloudflare-inventory.nu [date_stamp]

# HTTP GET with Cloudflare auth headers
def api-get [path: string]: nothing -> record {
  try {
    http get $"https://api.cloudflare.com/client/v4/($path)" -H {
      Authorization: $"Bearer ($env.CF_API_TOKEN)",
      "Content-Type": "application/json"
    }
  } catch {|err|
    error make {msg: $"Cloudflare API ($path) failed: ($err.msg)"}
  }
}

def save-json [value: record, path: path]: nothing -> nothing {
  try {
    $value | to json | save --force $path
  } catch {|err|
    error make {msg: $"failed to write ($path): ($err.msg)"}
  }
}

def open-json [path: path]: nothing -> record {
  try {
    open $path
  } catch {|err|
    error make {msg: $"failed to read ($path): ($err.msg)"}
  }
}

# Fetch a single API resource and save to raw_dir
def fetch-single [name: string, path: string, raw_dir: string]: nothing -> nothing {
  let resp = api-get $path
  save-json $resp $"($raw_dir)/($name).json"
}

# Fetch a paginated API resource, merge all pages, and save to raw_dir
def fetch-paginated [name: string, path: string, raw_dir: string, per_page: int = 100]: nothing -> nothing {
  let separator = if ($path | str contains "?") { "&" } else { "?" }

  let pages = generate {|page_num|
    let url = $"($path)($separator)page=($page_num)&per_page=($per_page)"
    let resp = api-get $url
    let total_pages = ($resp | get --optional result_info.total_pages | default 1 | into int)
    if $page_num >= $total_pages {
      {out: $resp}
    } else {
      {out: $resp, next: ($page_num + 1)}
    }
  } 1

  let merged = if ($pages | length) == 1 {
    $pages | first
  } else {
    let first = $pages | first
    let all_results = $pages | each {|p| $p | get --optional result | default [] } | flatten
    let last_info = $pages | last | get --optional result_info | default ($first | get --optional result_info | default null)
    {
      ...$first,
      result: $all_results,
      result_info: $last_info
    }
  }

  save-json $merged $"($raw_dir)/($name).json"
}

# Build a resource summary entry for the summary JSON
def build-resource-entry [key: string, scope: string, data: record, name_fn: closure]: nothing -> record {
  let result = $data | get --optional result
  let is_list = ($result | describe) =~ "list"
  let ok = ($data.success? == true)

  {
    key: $key,
    scope: $scope,
    count: (if $ok and $is_list { $result | length } else { 0 }),
    names: (if $ok and $is_list { $result | each $name_fn | sort | uniq } else { [] })
  }
}

# Orchestrate all fetching and summary generation
def run-inventory [date_stamp: string]: nothing -> nothing {
  let script_dir = ($env.FILE_PWD | path expand)
  let infra_dir = ($script_dir | path join ".." | path expand)
  let out_dir = $"($infra_dir)/.inventory/($date_stamp)/cloudflare"
  let raw_dir = $"($out_dir)/raw"

  let cf_account = $env.CF_ACCOUNT_ID?
  let cf_zone = $env.CF_ZONE_ID?

  if ($cf_account | is-empty) {
    error make {msg: "CF_ACCOUNT_ID is required"}
  }
  if ($cf_zone | is-empty) {
    error make {msg: "CF_ZONE_ID is required"}
  }

  try {
    mkdir $raw_dir
  } catch {|err|
    error make {msg: $"failed to create ($raw_dir): ($err.msg)"}
  }

  print $"Fetching Cloudflare inventory into: ($out_dir)"

  # Account / zone metadata
  fetch-single "token_verify" $"accounts/($cf_account)/tokens/verify" $raw_dir
  fetch-single "account" $"accounts/($cf_account)" $raw_dir
  fetch-single "zone" $"zones/($cf_zone)" $raw_dir

  # Zone-scoped resources
  fetch-paginated "dns_records" $"zones/($cf_zone)/dns_records" $raw_dir
  fetch-paginated "email_routing_rules" $"zones/($cf_zone)/email/routing/rules" $raw_dir

  # Account-scoped resources
  fetch-paginated "pages_projects" $"accounts/($cf_account)/pages/projects" $raw_dir 10
  fetch-paginated "d1_databases" $"accounts/($cf_account)/d1/database" $raw_dir
  fetch-paginated "kv_namespaces" $"accounts/($cf_account)/storage/kv/namespaces" $raw_dir
  fetch-single "r2_buckets" $"accounts/($cf_account)/r2/buckets" $raw_dir
  fetch-single "workers_scripts" $"accounts/($cf_account)/workers/scripts" $raw_dir
  fetch-single "workers_subdomain" $"accounts/($cf_account)/workers/subdomain" $raw_dir

  # Read all raw data for summary construction
  let token = open-json $"($raw_dir)/token_verify.json"
  let account = open-json $"($raw_dir)/account.json"
  let zone = open-json $"($raw_dir)/zone.json"
  let dns = open-json $"($raw_dir)/dns_records.json"
  let email = open-json $"($raw_dir)/email_routing_rules.json"
  let pages = open-json $"($raw_dir)/pages_projects.json"
  let d1 = open-json $"($raw_dir)/d1_databases.json"
  let kv = open-json $"($raw_dir)/kv_namespaces.json"
  let r2 = open-json $"($raw_dir)/r2_buckets.json"
  let workers = open-json $"($raw_dir)/workers_scripts.json"
  let workers_subdomain = open-json $"($raw_dir)/workers_subdomain.json"

  # Build summary JSON
  let r2_result = $r2 | get --optional result.buckets
  let r2_ok = ($r2.success? == true) and (($r2_result | describe) =~ "list")

  let ws_result = $workers_subdomain | get --optional result
  let ws_ok = ($workers_subdomain.success? == true)
  let ws_sub = if $ws_ok { $ws_result | get --optional subdomain | default "" | into string } else { "" }

  let summary = {
    generated_at: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
    token: {
      id: ($token.result.id),
      status: ($token.result.status)
    },
    account: {
      id: ($account.result.id),
      name: ($account.result.name)
    },
    zone: {
      id: ($zone.result.id),
      name: ($zone.result.name),
      status: ($zone.result.status),
      type: ($zone.result.type)
    },
    resources: [
      (build-resource-entry "dns_records" "zone" $dns {|r| $r.name}),
      (build-resource-entry "email_routing_rules" "zone" $email {|r|
        $r | get --optional name | default ($r | get --optional tag | default ($r | get --optional id | default ""))
      }),
      (build-resource-entry "pages_projects" "account" $pages {|r| $r.name}),
      (build-resource-entry "d1_databases" "account" $d1 {|r| $r.name}),
      (build-resource-entry "kv_namespaces" "account" $kv {|r|
        $r | get --optional title | default ($r | get --optional name | default ($r | get --optional id | default ""))
      }),
      {
        key: "r2_buckets",
        scope: "account",
        count: (if $r2_ok { $r2_result | length } else { 0 }),
        names: (if $r2_ok { $r2_result | each {|b| $b.name} | sort } else { [] })
      },
      (build-resource-entry "workers_scripts" "account" $workers {|r|
        $r | get --optional id | default ($r | get --optional tag | default ($r | get --optional name | default ""))
      }),
      {
        key: "workers_subdomain",
        scope: "account",
        count: (if $ws_ok { 1 } else { 0 }),
        names: (if $ws_sub != "" { [$ws_sub] } else { [] })
      }
    ]
  }

  save-json $summary $"($out_dir)/summary.json"

  # Generate README.md
  let resource_lines = $summary.resources | each {|r| $"- ($r.key): ($r.count)"} | str join "\n"

  let readme = $"# Cloudflare Inventory

- generated_at: ($summary.generated_at)
- account: ($summary.account.name) \(($cf_account)\)
- zone: ($summary.zone.name) \(($cf_zone)\)
- token_status: ($summary.token.status)

## Resource Summary

($resource_lines)

## Notes

- 这是 Cloudflare API 的只读快照，不代表这些资源已经被 Terraform/OpenTofu 纳管。
- 这些 raw JSON 用来做 inventory、ownership decision、import planning。
- 正式纳管前，先确认每一类资源的 state 边界，再决定是否生成 HCL/import blocks。
"

  try {
    $readme | save --force $"($out_dir)/README.md"
  } catch {|err|
    error make {msg: $"failed to write ($out_dir)/README.md: ($err.msg)"}
  }

  print $"Cloudflare inventory written to: ($out_dir)"
}

# CLI entry point
def main [date_stamp?: string]: nothing -> nothing {
  let stamp = if ($date_stamp | is-empty) {
    date now | format date "%F"
  } else {
    $date_stamp
  }

  run-inventory $stamp
}
