#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  notify
  open-url
  prompt-fuzzel
]

def fetch-repo-json [] {
  try {
    ^dgh --output raw err> /dev/null
  } catch {
    ''
  }
}

def icon-path [icon_dir icon_file] {
  if $icon_file == '' {
    ''
  } else {
    let candidate = ([$icon_dir $icon_file] | path join)
    if (($candidate | path exists) == true) {
      $candidate
    } else {
      ''
    }
  }
}

def build-repo-entries [raw icon_dir] {
  if $raw == '' {
    []
  } else {
    let jq_program = '
      def norm_doc:
        (if . == null then "" else (. | tostring) end | gsub("^[[:space:]]+|[[:space:]]+$"; ""));
      def has_qs:
        ((.qs // []) | length > 0) or any(.topics[]?; ((.qs // []) | length > 0));
      .[] |
        (.URL // "") as $url |
        ($url | split("/")) as $parts |
        select(($parts | length) > 4) |
        ($parts[3] // "") as $owner |
        ($parts[4] // "") as $name |
        select($owner != "" and $name != "") |
        ($owner + "/" + $name) as $display |
        (.Doc | norm_doc) as $doc_raw |
        ($doc_raw != "" and $doc_raw != "null") as $has_doc |
        has_qs as $has_qs |
        (if $has_doc and $has_qs then "ab.svg"
         elif $has_doc then "a.svg"
         elif $has_qs then "b.svg"
         else "check.svg" end) as $icon |
        [$display, $url, (if $has_doc then $doc_raw else "" end), $icon] | @tsv
    ';

    $raw
    | ^jq -r $jq_program
    | lines
    | where {|line| ($line | str trim) != '' }
    | each {|line|
        let parts = ($line | split row "\t")
        let display = ($parts | get 0? | default '')
        let url = ($parts | get 1? | default '')

        if $display == '' or $url == '' {
          null
        } else {
          let doc = ($parts | get 2? | default '')
          let icon_file = ($parts | get 3? | default '')

          {
            display: $display
            url: $url
            doc: $doc
            icon_path: (icon-path $icon_dir $icon_file)
          }
        }
      }
    | where {|entry| $entry != null }
  }
}

def format-menu-entry [display_text icon_path] {
  let icon_suffix = if $icon_path == '' {
    ''
  } else {
    (char nul) + "icon" + (char us) + $icon_path
  }

  $display_text + $icon_suffix
}

def repo-actions [has_doc] {
  if $has_doc {
    ["Open Repository" "Open Docs (docs.lucc.dev)" "Open Documentation" "Copy URL"]
  } else {
    ["Open Repository" "Open Docs (docs.lucc.dev)" "Copy URL"]
  }
}

def open-docs [full_name] {
  let repo_name = (
    $full_name
    | split row "/"
    | get 1?
    | default ''
  )

  if $repo_name == '' {
    return
  }

  let docs_url = $"https://docs.lucc.dev/($repo_name)"
  open-url $docs_url --message (["Opening docs for " $full_name] | str join)
}

def run-action [action repo] {
  match $action {
    "Open Repository" => {
      open-url $repo.url --message (["Opening " $repo.display] | str join)
      true
    }
    "Open Docs (docs.lucc.dev)" => {
      open-docs $repo.display
      true
    }
    "Open Documentation" => {
      if $repo.doc != '' {
        open-url $repo.doc --message (["Opening documentation for " $repo.display] | str join)
      }
      true
    }
    "Copy URL" => {
      if (not (copy-to-clipboard $repo.url)) {
        print --stderr "gh: failed to copy URL to clipboard"
        false
      } else {
        notify "GitHub" (["URL copied for " $repo.display] | str join)
        true
      }
    }
    _ => false
  }
}

def handle-repo [repo] {
  if $repo.url == '' {
    false
  } else {
    let has_doc = $repo.doc != ''
    let actions = repo-actions $has_doc
    let selection = prompt-fuzzel $"Action for ($repo.display): " --lines 10 --input ($actions | str join "\n")

    if $selection == '' {
      true
    } else {
      run-action $selection $repo
    }
  }
}

def main [] {
  let icon_dir = ([$env.HOME ".local" "share" "icons" "gh"] | path join)
  let repos_raw = fetch-repo-json
  let repo_entries = build-repo-entries $repos_raw $icon_dir

  let repo_lines = (
    $repo_entries
    | each {|entry| format-menu-entry $entry.display $entry.icon_path }
  )

  let menu_input = ($repo_lines | str join "\n")

  let selected_value = prompt-fuzzel "" --lines 20 --input $menu_input

  if $selected_value == '' {
    exit 1
  }

  let repo = (
    $repo_entries
    | where display == $selected_value
    | get 0?
  )

  if $repo == null {
    if ($selected_value | str contains "/") {
      open-url $"https://github.com/($selected_value)" --message (["Opening " $selected_value] | str join)
      exit 0
    }

    exit 1
  }

  if (handle-repo $repo) {
    exit 0
  } else {
    exit 1
  }
}

main
