#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  prompt-fuzzel
  type-into-focused
]

let website = prompt-fuzzel "" --lines 0 --input "\n"
if $website == '' {
  exit 1
}

let secret = ($env.PWGEN_SECRET? | default '')
if $secret == '' {
  print --stderr "pwgen: PWGEN_SECRET is not set"
  exit 1
}

let password = (
  try {
    ^pwgen --secret $secret $website
  } catch {
    ''
  } | str trim
)

if $password == '' {
  exit 1
}

print --no-newline $password

if (not (copy-to-clipboard $password)) {
  print --stderr "pwgen: failed to copy password to clipboard"
}

sleep 100ms

if (not (type-into-focused $password)) {
  print --stderr "pwgen: failed to type password into the focused window"
}
