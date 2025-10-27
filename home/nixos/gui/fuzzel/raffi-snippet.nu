#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  prompt-fuzzel
  type-into-focused
]

let snippets_json = (
  try {
    ^task -g ss:json err> /dev/null
  } catch {
    ''
  }
)

if $snippets_json == '' {
  exit 1
}

let names = (
  try {
    $snippets_json
    | ^jq -r '.[].sub[] | .name'
  } catch {
    ''
  }
)

let selected_name = prompt-fuzzel "Snippets: " --lines 20 --input $names

if $selected_name == '' {
  exit 1
}

let value = (
  try {
    $snippets_json
    | ^jq -r --arg name $selected_name '
      .[].sub[] |
      select(.name == $name) |
      .val
    '
  } catch {
    ''
  }
) | str trim

if $value == '' or $value == 'null' {
  print --stderr $"No value found for name: [($selected_name)]"
  exit 1
}

print --no-newline $value

if (not (copy-to-clipboard $value)) {
  print --stderr "snippet: failed to copy value to clipboard"
}

sleep 100ms

if (not (type-into-focused $value)) {
  print --stderr "snippet: failed to type value into the focused window"
}
