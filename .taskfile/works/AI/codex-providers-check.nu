#!/usr/bin/env nu

def config-path [] {
  $env.HOME | path join ".codex" "config.toml"
}

def normalize-text [value: string] {
  $value | str replace -ar '\s+' ' ' | str trim
}

def maybe-json-message [line: string] {
  let trimmed = ($line | str trim)
  if ($trimmed | is-empty) {
    return null
  }

  if not ($trimmed | str starts-with "{") {
    return null
  }

  try {
    let obj = ($trimmed | from json)
    [
      ($obj | get -o error.message),
      ($obj | get -o message),
      ($obj | get -o error),
    ]
    | where {|item| $item != null and (($item | into string | str trim) != "")}
    | append null
    | first
  } catch {
    null
  }
}

def reason-from-output [output: string exit_code: int] {
  let normalized = (normalize-text $output)
  let lowered = ($normalized | str downcase)

  if ($lowered | str contains "timeout") {
    return "timeout"
  }

  let obvious = (
    $output
    | lines
    | each {|line|
        let msg = (maybe-json-message $line)
        let trimmed = ($line | str trim)
        if $msg != null {
          $msg | into string
        } else if ($trimmed | str starts-with "{") {
          ""
        } else {
          $line
        }
      }
    | each {|line| normalize-text ($line | into string)}
    | where {|line| $line != "" and $line != "OK"}
    | append null
    | first
  )

  if $obvious != null {
    return ($obvious | str substring 0..120)
  }

  if $exit_code != 0 {
    "non-zero exit"
  } else {
    "unexpected response"
  }
}

def probe-provider [profile: string] {
  let tmpdir = (^mktemp -d | str trim)
  let last_message_file = ($tmpdir | path join $"($profile)-last-message.txt")
  let run = (
    ^codex exec
      --profile $profile
      --skip-git-repo-check
      --ephemeral
      --color never
      --json
      --output-last-message $last_message_file
      "Reply with exactly OK."
      | complete
  )

  let last_message = if ($last_message_file | path exists) {
    open $last_message_file | into string | str trim
  } else {
    ""
  }
  let status = if (($last_message_file | path exists) and $last_message == "OK") {
    "ok"
  } else {
    "fail"
  }
  let reason = if $status == "ok" {
    ""
  } else {
    reason-from-output $"($run.stdout)\n($run.stderr)" $run.exit_code
  }
  rm -rf $tmpdir

  {
    profile: $profile
    status: $status
    reason: $reason
  }
}

def render-results [rows: list<any>] {
  if ((which gum | length) > 0) {
    let table_file = (^mktemp | str trim)
    let table_rows = (
      $rows
      | update reason {|row| if ($row.reason | is-empty) { "-" } else { $row.reason }}
      | each {|row| $"($row.profile)\t($row.status)\t($row.reason)"}
      | str join "\n"
    )
    $table_rows | save --force $table_file
    ^gum table --print --separator "\t" --columns profile,status,reason --file $table_file
    rm $table_file
  } else {
    $rows | select profile status reason | table
  }
}

def main [] {
  let cfg_path = (config-path)
  let config = (open --raw $cfg_path | from toml)
  let providers = (
    $config
    | get model_providers
    | columns
    | sort
  )

  if ($providers | is-empty) {
    error make { msg: "no model_providers found" }
  }

  let results = (
    $providers
    | par-each {|profile| probe-provider $profile }
    | sort-by profile
  )
  render-results $results
}
