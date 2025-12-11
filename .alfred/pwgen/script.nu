#!/usr/bin/env nu

use ../common.nu *

def get-query [] {
  ($env | get -o alfred_workflow_query | default "" | str trim)
}

def get-secret [] {
  ($env | get -o PWGEN_SECRET | default "" | str trim)
}

def build-args [secret: string, query: string] {
  ["--output" "alfred" "--secret" $secret $query]
}

export def main [query?: string] {
  ensure-path

  let query = (if $query != null { $query } else { get-query })
  if ($query | is-empty) { exit 0 }

  let secret = (get-secret)
  if ($secret | is-empty) {
    alfred-error "缺少 PWGEN_SECRET" "在 env 里设置 PWGEN_SECRET 或用 --secret" | print
    exit 0
  }

  let cmd = (ensure-cmd-or-install "pwgen" "go install github.com/xbpk3t/docs-alfred/pwgen@main" "pwgen")
  let args = (build-args $secret $query)
  let out  = (run-safe $cmd $args "pwgen")
  let _    = (print $out)
}
