#!/usr/bin/env bash

# ss workflow for rofi
# Displays snippets using task -g ss:json

# Function to copy snippet to clipboard
copy_snippet() {
    snippet_val="$1"
    snippet_name="$2"

    # Copy to clipboard
    echo -n "$snippet_val" | wl-copy 2>/dev/null || echo -n "$snippet_val" | xclip -selection clipboard 2>/dev/null

    # Show notification
    notify-send "Snippet Copied" "Snippet '$snippet_name' copied to clipboard" 2>/dev/null || echo "Snippet '$snippet_name' copied to clipboard"

    # Exit after copying
    exit 0
}

# If we have an argument, it means a snippet was selected
if [ -n "$@" ]; then
    # Parse the selected snippet (format: "name::::value")
    snippet_line="$@"
    snippet_name="${snippet_line%%%%::::*}"
    snippet_val="${snippet_line#*::::}"

    copy_snippet "$snippet_val" "$snippet_name"
fi

# Get snippets data as JSON
snippets_json=$(task -g ss:json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$snippets_json" ]; then
    echo "Error: Failed to get snippets data"
    echo "Make sure 'task -g ss:json' works correctly"
    exit 1
fi

# Parse JSON and display snippets grouped by category
# Using jq to parse the JSON structure:
# [
#   {
#     "group": "groupName",
#     "sub": [
#       {"name": "snippetName", "val": "snippetValue"},
#       ...
#     ]
#   },
#   ...
# ]

# Process the JSON with jq
echo "$snippets_json" | jq -r '.[] | "\(.group)//\(.sub[] | "\(.name)::::\(.val)")"' 2>/dev/null | \
while IFS= read -r line; do
    if [[ "$line" == *//* ]]; then
        # This is a group header
        group="${line%//*}"
        echo -e "\0markup-rows\x1ftrue"
        echo "$group"
    else
        # This is a snippet
        echo "$line"
    fi
done
