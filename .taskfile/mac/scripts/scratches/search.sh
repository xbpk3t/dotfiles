#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

notebook="${1:-}"
if [ -z "$notebook" ]; then
  echo "SCRATCH_NOTEBOOK is required" >&2
  exit 1
fi

query="$(gum input --prompt "Search query: " || true)"
if [ -z "$query" ]; then
  exit 0
fi

items="$(search_items "$notebook" "$query" || true)"
if [ -z "$items" ]; then
  echo "No matches."
  exit 0
fi

line="$(printf "%s\n" "$items" | pick_line "Search> ")"
if [ -z "$line" ]; then
  exit 0
fi

clean="$(printf "%s\n" "$line" | strip_ansi)"
id="$(printf "%s\n" "$clean" | extract_id)"
if [ -z "$id" ]; then
  exit 0
fi

nb edit "$id"
