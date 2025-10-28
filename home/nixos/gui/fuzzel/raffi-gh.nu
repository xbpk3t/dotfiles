#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  notify
  open-url
  prompt-fuzzel
]

let repos_json = (
  try {
    ^dgh --output raw err> /dev/null
  } catch {
    ''
  }
)

if $repos_json == '' {
  exit 1
}

let repo_lines = (
  try {
    $repos_json
    | ^jq -r '
      .[] |
      (.URL | split("/") | .[3] + "/" + .[4])
    '
  } catch {
    ''
  }
)

let search_entry = "Search GitHub for typed query ↗"
let menu_input = if $repo_lines == '' { $search_entry } else { $repo_lines + "\n" + $search_entry }

# let selected_repo = prompt-fuzzel "GitHub Repos: " --lines 20 --input $menu_input
let selected_repo = prompt-fuzzel "" --lines 20 --input $menu_input

if $selected_repo == '' {
  exit 1
}

let repo_info_raw = (
  try {
    $repos_json
    | ^jq -r --arg full_name $selected_repo '
      .[] |
      (.URL | split("/") | .[3] + "/" + .[4]) as $repo_full_name |
      select($repo_full_name == $full_name) |
      {url: .URL, doc: (.Doc // ""), des: (.Des // ""), tag: .Tag}
    '
  } catch {
    ''
  }
) | str trim

if $repo_info_raw == '' or $repo_info_raw == 'null' {
  if $selected_repo == $search_entry {
    let query = prompt-fuzzel "GitHub Search: " --lines 0 --input "\n"

    if $query == '' {
      exit 1
    }

    let encoded_query = ($query | url encode)
    let search_url = (["https://github.com/search?q=" $encoded_query "&type=repositories"] | str join)
    open-url $search_url --message (["Searching GitHub for " $query] | str join)
    exit 0
  }

  let owner_repo = (
    $selected_repo
    | str trim
  )

  if ($owner_repo | str contains "/") {
    open-url $"https://github.com/($owner_repo)" --message (["Opening " $owner_repo] | str join)
    exit 0
  }

  exit 1
}

let repo_info = (
  try {
    $repo_info_raw | from json
  } catch {
    {}
  }
)

let repo_url = ($repo_info.url? | default '')
let repo_doc = ($repo_info.doc? | default '')
let repo_full_name = $selected_repo

if $repo_url == '' {
  exit 1
}

let actions = if $repo_doc != '' and $repo_doc != 'null' {
  ["Open Repository" "Open Docs (docs.lucc.dev)" "Open Documentation" "Copy URL"]
} else {
  ["Open Repository" "Open Docs (docs.lucc.dev)" "Copy URL"]
}

let action = prompt-fuzzel $"Action for ($repo_full_name): " --lines 10 --input ($actions | str join "\n")

match $action {
  "Open Repository" => {
    open-url $repo_url --message (["Opening " $repo_full_name] | str join)
  }
  "Open Docs (docs.lucc.dev)" => {
    let repo_name = (
      $repo_full_name
      | split row "/"
      | get 1?
      | default ''
    )

    if $repo_name == '' {
      exit 0
    }

    let docs_url = $"https://docs.lucc.dev/($repo_name)"
    open-url $docs_url --message (["Opening docs for " $repo_full_name] | str join)
  }
  "Open Documentation" => {
    if $repo_doc != '' and $repo_doc != 'null' {
      open-url $repo_doc --message (["Opening documentation for " $repo_full_name] | str join)
    }
  }
  "Copy URL" => {
    if (not (copy-to-clipboard $repo_url)) {
      print --stderr "gh: failed to copy URL to clipboard"
    } else {
      notify "GitHub" (["URL copied for " $repo_full_name] | str join)
    }
  }
  _ => {
    exit 0
  }
}
