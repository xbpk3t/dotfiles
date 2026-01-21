#!/usr/bin/env bash
set -euo pipefail

notebook="${1:-}"
if [ -z "$notebook" ]; then
  echo "SCRATCH_NOTEBOOK is required" >&2
  exit 1
fi

default_name="scratch-$(date +%Y%m%d-%H%M%S).md"
name="$(gum input --prompt "Scratch filename: " --value "$default_name" || true)"
if [ -z "$name" ]; then
  exit 0
fi

nb add "${notebook}:$name" --edit
