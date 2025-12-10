#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  prompt-fuzzel
  type-into-focused
]

def bail [message] {
  if $message != '' {
    print --stderr $message
  }
  exit 1
}

export def load-snippets [] {
  try {
    ^task -g ss:json err> /dev/null
  } catch {
    ''
  }
}

export def list-snippet-names [snippets_json] {
  try {
    $snippets_json
    | ^jq -r '.[].sub[] | .name'
  } catch {
    ''
  }
}

export def snippet-names [] {
  let snippets_json = load-snippets
  if $snippets_json == '' {
    []
  } else {
    list-snippet-names $snippets_json
    | lines
    | where {|name| ($name | str trim) != '' }
  }
}

def select-snippet-name [names provided_name] {
  if (not ($provided_name | is-empty)) {
    $provided_name
  } else {
    let selected = prompt-fuzzel "Snippets: " --lines 20 --input $names
    if $selected == '' {
      exit 1
    }
    $selected
  }
}

def read-snippet-value [snippets_json name] {
  try {
    $snippets_json
    | ^jq -r --arg name $name '
      .[].sub[] |
      select(.name == $name) |
      .val
    '
  } catch {
    ''
  }
}

def deliver-snippet [value skip_clipboard skip_type] {
  print --no-newline $value

  if (not $skip_clipboard) {
    if (not (copy-to-clipboard $value)) {
      print --stderr "snippet: failed to copy value to clipboard"
    }
  }

  if (not $skip_type) {
    sleep 100ms
    if (not (type-into-focused $value)) {
      print --stderr "snippet: failed to type value into the focused window"
    }
  }
}

def main [
  --name (-n): string
  --skip-type
  --skip-clipboard
] {
  let snippets_json = load-snippets
  if $snippets_json == '' {
    exit 1
  }

  let names = list-snippet-names $snippets_json
  let snippet_name = select-snippet-name $names $name
  if $snippet_name == '' {
    exit 1
  }

  let value = (read-snippet-value $snippets_json $snippet_name) | str trim
  if $value == '' or $value == 'null' {
    bail $"No value found for name: [($snippet_name)]"
  }

  deliver-snippet $value $skip_clipboard $skip_type
}
