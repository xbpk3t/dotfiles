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

def collect-website [website?] {
  if (not ($website | is-empty)) {
    $website
  } else {
    let result = prompt-fuzzel "" --lines 0 --input "\n"
    if $result == '' {
      exit 1
    }
    $result
  }
}

def read-secret [] {
  let secret = ($env.PWGEN_SECRET? | default '')
  if $secret == '' {
    bail "pwgen: PWGEN_SECRET is not set"
  }
  $secret
}

def generate-password [website secret] {
  let password = (
    try {
      ^pwgen --secret $secret $website
    } catch {
      ''
    } | str trim
  )

  if $password == '' {
    bail "pwgen: failed to generate password"
  }

  $password
}

def deliver-password [password skip_clipboard skip_type] {
  print --no-newline $password

  if (not $skip_clipboard) {
    if (not (copy-to-clipboard $password)) {
      print --stderr "pwgen: failed to copy password to clipboard"
    }
  }

  if (not $skip_type) {
    sleep 100ms
    if (not (type-into-focused $password)) {
      print --stderr "pwgen: failed to type password into the focused window"
    }
  }
}

def main [
  --website (-w): string
  --skip-type
  --skip-clipboard
] {
  let site = collect-website $website
  let secret = read-secret
  let password = generate-password $site $secret
  deliver-password $password $skip_clipboard $skip_type
}
