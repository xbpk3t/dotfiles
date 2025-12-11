#!/usr/bin/env nu

use ../common.nu *

def get-query [] {
  ($env | get -o alfred_workflow_query | default "" | str trim)
}

def build-args [config: string, url: string, docs: string, query: string] {
  mut args: list<string> = ["--output" "alfred"]
  if $config != "" { $args ++= ["--config" $config] }
  if $url    != "" { $args ++= ["--url" $url] }
  if $docs   != "" { $args ++= ["--docs" $docs] }
  $args ++= [$query]
  $args
}

export def main [query?: string] {
  ensure-path

  # 空查询时返回全部仓库（dgh 本身会处理空字符串）
  let query = (if $query != null { $query } else { get-query })

  let cmd = (ensure-cmd-or-install "dgh" "go install github.com/xbpk3t/docs-alfred/dgh@main" "dgh")

  let config = ($env | get -o DGH_CONFIG | default "" | str trim)
  let url    = ($env | get -o DGH_URL    | default "" | str trim)
  let docs   = ($env | get -o DGH_DOCS   | default "" | str trim)

  let args = (build-args $config $url $docs $query)
  let out  = (run-safe $cmd $args "dgh")
  let _    = (print $out)
}
