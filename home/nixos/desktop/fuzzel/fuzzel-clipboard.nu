#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  prompt-fuzzel
  type-into-focused
]

use ./raffi-snippet.nu [
  snippet-names
]

const snippet_entry_label = "All Snippets"

def snippet-label [] {
  let names = snippet-names
  let count = ($names | length)

  if $count == 0 {
    $"($snippet_entry_label) (0)"
  } else {
    $"($snippet_entry_label) ($count)"
  }
}

def parse-cliphist-line [line] {
  let trimmed = $line | str trim
  if $trimmed == '' {
    null
  } else {
    let parsed = (
      try {
        $trimmed | parse -r '^(?P<id>[0-9]+)[[:space:]]+(?P<text>.*)$'
      } catch {
        []
      }
    )

    if ($parsed | length) == 0 {
      null
    } else {
      let row = $parsed | get 0
      let preview = (
        $row.text
        | default ''
        | str trim
      )

      {
        id: $row.id
        display: (if $preview == '' { "(empty clipboard entry)" } else { $preview })
      }
    }
  }
}

def fetch-cliphist-entries [] {
  let raw = (
    try {
      ^cliphist list
    } catch {
      ''
    }
  )

  if $raw == '' {
    []
  } else {
    $raw
    | lines
    | each {|line| parse-cliphist-line $line }
    | where {|entry| $entry != null }
  }
}

def decode-cliphist-entry [entry_id] {
  try {
    ^cliphist decode $entry_id
  } catch {
    ''
  }
}

def run-snippet-picker [] {
  let result = (
    try {
      ^raffi-snippet
      true
    } catch {
      false
    }
  )

  if (not $result) {
    print --stderr "clipboard: failed to launch snippet picker"
  }

  $result
}

def handle-clipboard-selection [selection entries skip_type] {
  let entry = (
    $entries
    | where display == $selection
    | get 0?
  )

  if $entry == null {
    print --stderr "clipboard: unknown selection"
    return false
  }

  let decoded = decode-cliphist-entry $entry.id
  if $decoded == '' {
    print --stderr "clipboard: failed to decode selection"
    return false
  }

  if (not (copy-to-clipboard $decoded)) {
    print --stderr "clipboard: failed to copy decoded content to clipboard"
    return false
  }

  if (not $skip_type) {
    sleep 100ms
    if (not (type-into-focused $decoded)) {
      print --stderr "clipboard: failed to type decoded content into the focused window"
      return false
    }
  }

  true
}

def main [
  --skip-type
] {
  let entries = fetch-cliphist-entries
  let snippet_name = snippet-label
  let history_lines = ($entries | each {|entry| $entry.display })
  let menu_lines = (
    [$snippet_name]
    | append $history_lines
  )
  let menu_input = ($menu_lines | str join "\n")

  let selection = prompt-fuzzel "Clipboard: " --lines 20 --input $menu_input
  if $selection == '' {
    exit 1
  }

  if $selection == $snippet_name {
    if (run-snippet-picker) {
      exit 0
    } else {
      exit 1
    }
  }

  if (handle-clipboard-selection $selection $entries $skip_type) {
    exit 0
  } else {
    exit 1
  }
}

main
