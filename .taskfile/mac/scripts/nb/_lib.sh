#!/usr/bin/env bash
set -euo pipefail

strip_ansi() {
  sed -E 's/\x1b\[[0-9;]*m//g'
}

extract_id() {
  sed -E 's/^[[:space:]]*\[([^]]+)\].*/\1/'
}

pick_line() {
  local prompt="$1"
  gum filter --prompt "$prompt" || true
}

list_items() {
  local notebook="$1"
  nb list --no-color --no-indicator "${notebook}:" | sed -nE '/^\[/{p;}'
}

search_items() {
  local notebook="$1"
  local query="$2"
  nb search --no-color "${notebook}:" "$query" --list | sed -nE '/^\[/{p;}'
}
