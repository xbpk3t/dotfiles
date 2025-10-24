#!/usr/bin/env bash

# ww workflow for rofi
# Displays bookmarks with icons using task -g ww:json

# Function to open bookmark
open_bookmark() {
    url="$1"
    alias="$2"

    # Open URL in default browser
    xdg-open "$url" 2>/dev/null || echo "Opening $url..."

    # Show notification
    notify-send "Bookmark Opener" "Opening '$alias'" 2>/dev/null || echo "Opening '$alias'..."

    # Exit after opening
    exit 0
}

# If we have an argument, it means a bookmark was selected
if [ -n "$@" ]; then
    # Parse the selected bookmark (format: "alias::::url::::icon_path")
    bookmark_line="$@"
    alias="${bookmark_line%%%%::::*}"
    remaining="${bookmark_line#*::::}"
    url="${remaining%%%%::::*}"
    icon_path="${remaining#*::::}"

    open_bookmark "$url" "$alias"
fi

# Get bookmarks data as JSON
bookmarks_json=$(task -g ww:json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$bookmarks_json" ]; then
    echo "Error: Failed to get bookmarks data"
    echo "Make sure 'task -g ww:json' works correctly"
    exit 1
fi

# Define icon directory
ICON_DIR="/home/luck/Desktop/docs-images/workflow/ww"

# Parse JSON and display bookmarks with icons
# Using jq to parse the JSON structure:
# [
#   {"alias": "bookmarkAlias", "url": "bookmarkUrl"},
#   ...
# ]

# Process the JSON with jq
echo "$bookmarks_json" | jq -r --arg icon_dir "$ICON_DIR" '.[] |
    # Construct icon filename from alias (replace special characters)
    (.alias | gsub("[^a-zA-Z0-9_-]"; "-")) as $safe_alias |
    "\(.alias)::::\(.url)::::\($icon_dir)/\($safe_alias).png"' 2>/dev/null | \
while IFS= read -r line; do
    alias="${line%%%%::::*}"
    remaining="${line#*::::}"
    url="${remaining%%%%::::*}"
    icon_path="${remaining#*::::}"

    # Check if icon exists, if not use a default icon or no icon
    if [ -f "$icon_path" ]; then
        echo -e "$alias\x00icon\x1f$icon_path"
    else
        # Try with .svg extension
        svg_icon_path="${icon_path%.png}.svg"
        if [ -f "$svg_icon_path" ]; then
            echo -e "$alias\x00icon\x1f$svg_icon_path"
        else
            # No icon found, just show the alias
            echo "$alias"
        fi
    fi
done
