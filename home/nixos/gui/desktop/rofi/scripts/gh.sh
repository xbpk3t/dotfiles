#!/usr/bin/env bash

# gh workflow for rofi
# Displays GitHub repositories with icons and nested actions using dgh

# Function to handle repository selection
handle_repo_selection() {
    repo_url="$1"

    # Show actions for the selected repository
    echo "Open Repository::::$repo_url"
    echo "Open in Browser::::$repo_url"
    echo "Copy URL::::$repo_url"
    echo ""
    echo "Back to Repositories"
    exit 0
}

# Function to handle action selection
handle_action_selection() {
    action_line="$@"
    action="${action_line%%%%::::*}"
    url="${action_line#*::::}"

    case "$action" in
        "Open Repository")
            # Open repository in default application
            xdg-open "$url" 2>/dev/null || echo "Opening $url..."
            notify-send "GitHub" "Opening repository" 2>/dev/null || echo "Opening repository..."
            ;;
        "Open in Browser")
            # Open in web browser
            xdg-open "$url" 2>/dev/null || echo "Opening $url in browser..."
            notify-send "GitHub" "Opening in browser" 2>/dev/null || echo "Opening in browser..."
            ;;
        "Copy URL")
            # Copy URL to clipboard
            echo -n "$url" | wl-copy 2>/dev/null || echo -n "$url" | xclip -selection clipboard 2>/dev/null
            notify-send "GitHub" "URL copied to clipboard" 2>/dev/null || echo "URL copied to clipboard"
            ;;
        "Back to Repositories")
            # Return to repository list
            show_repositories
            ;;
        *)
            # Default action - open repository
            xdg-open "$url" 2>/dev/null || echo "Opening $url..."
            ;;
    esac

    exit 0
}

# Function to show repositories
show_repositories() {
    # Get repositories data as JSON using dgh
    repos_json=$(dgh --output raw 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$repos_json" ]; then
        echo "Error: Failed to get repositories data"
        echo "Make sure 'dgh' command works correctly"
        exit 1
    fi

    # Define icon directory
    ICON_DIR="/home/luck/Desktop/docs-images/workflow/gh"

    # Parse JSON and display repositories with icons
    # Using jq to parse the JSON structure:
    # [
    #   {
    #     "URL": "repositoryUrl",
    #     "Des": "description",
    #     "Type": "iconType",  // a=qs, b=doc, ab=qs+doc, check=default, search=not found
    #     ...
    #   },
    #   ...
    # ]

    # Process the JSON with jq
    echo "$repos_json" | jq -r --arg icon_dir "$ICON_DIR" '.[] |
        # Extract repository name from URL
        (.URL | split("/") | last) as $repo_name |
        # Map Type to icon filename
        (
            if .Type == "a" then "a.svg"
            elif .Type == "b" then "b.svg"
            elif .Type == "ab" then "ab.svg"
            elif .Type == "check" then "check.svg"
            elif .Type == "search" then "search.svg"
            else "check.svg"
            end
        ) as $icon_file |
        "\(.URL)::::\(.Des // .Tag // \"\")::::\($icon_dir)/\($icon_file)"' 2>/dev/null | \
    while IFS= read -r line; do
        url="${line%%%%::::*}"
        remaining="${line#*::::}"
        description="${remaining%%%%::::*}"
        icon_path="${remaining#*::::}"

        # Extract repository name from URL
        repo_name=$(basename "$url")

        # Check if icon exists, if not use a default icon or no icon
        if [ -f "$icon_path" ]; then
            echo -e "$repo_name\x00icon\x1f$icon_path\x00meta\x1f$url"
        else
            # Try with .png extension
            png_icon_path="${icon_path%.svg}.png"
            if [ -f "$png_icon_path" ]; then
                echo -e "$repo_name\x00icon\x1f$png_icon_path\x00meta\x1f$url"
            else
                # No icon found, just show the repository name with URL as meta
                echo -e "$repo_name\x00meta\x1f$url"
            fi
        fi
    done
}

# Main logic
if [ -n "$@" ]; then
    # Check if this is an action selection (contains ::::)
    if [[ "$@" == *::::* ]]; then
        handle_action_selection "$@"
    else
        # This is a repository selection, show actions
        repo_url="$@"
        handle_repo_selection "$repo_url"
    fi
else
    # Show repositories list
    show_repositories
fi
