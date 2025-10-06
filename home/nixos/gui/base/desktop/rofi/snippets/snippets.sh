#!/usr/bin/env bash
# Snippets script using espanso-like functionality
# Allows quick insertion of predefined text snippets

snippets_dir="$HOME/.config/rofi/snippets"
snippets_file="$snippets_dir/snippets.txt"

# Create snippets directory and file if they don't exist
mkdir -p "$snippets_dir"
if [[ ! -f "$snippets_file" ]]; then
  cat > "$snippets_file" << 'EOF'
# Rofi Snippets - Format: trigger:text
email:your.email@example.com
sig:Best regards,\nYour Name
date:$(date '+%Y-%m-%d')
time:$(date '+%H:%M')
code:``` \n \n ```
link:[Link Text](URL)
todo:- [ ] Task description
nix:{ pkgs, ... }:\n  # Nix configuration
EOF
fi

# Extract snippet triggers
triggers=$(grep -v "^#" "$snippets_file" | cut -d: -f1)
selected=$(printf "%s\n" $triggers | rofi -dmenu -p "Snippet:")

if [[ -n "$selected" ]]; then
  snippet=$(grep "^$selected:" "$snippets_file" | cut -d: -f2-)
  # Process snippet (expand variables, newlines)
  processed_snippet=$(eval "echo \"$snippet\"" | sed 's/\\n/\n/g')
  echo "$processed_snippet" | wl-copy
  notify-send "Snippet Copied" "Selected snippet copied to clipboard"
fi