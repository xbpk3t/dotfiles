#!/usr/bin/env nu
# YAML Bookmark Manager for Rofi with Smart Search and Icon Support
# Dependencies: rofi, xdg-utils

# Configuration
const BOOKMARKS_FILE = ($env.HOME | path join ".config/rofi/bookmark/bm.yml")
const ICON_DIR = ($env.HOME | path join ".config/rofi/bookmark/icon")
const FALLBACK_ICON = "text-html"
const GOOGLE_ICON = "google"

# Supported image extensions (based on GdkPixbuf support)
const SUPPORTED_EXTENSIONS = ["png" "svg" "jpg" "jpeg" "gif" "ico" "webp"]

# Check dependencies
def check-dependencies [] {
    let missing_tools = []

    if (which rofi | is-empty) {
        $missing_tools = ($missing_tools | append "rofi")
    }

    if (which xdg-open | is-empty) {
        $missing_tools = ($missing_tools | append "xdg-open")
    }

    if ($missing_tools | length) > 0 {
        error make {
            msg: $"Missing required tools: ($missing_tools | str join ', ')"
        }
    }
}

# Check if bookmarks file exists
def validate-bookmark-file [] {
    if not ($BOOKMARKS_FILE | path exists) {
        error make {
            msg: $"Bookmarks file not found: $BOOKMARKS_FILE"
        }
    }
}

# Find icon file for given alias (supports multiple formats)
def find-icon-file [alias: string] {
    $SUPPORTED_EXTENSIONS
    | each { |ext|
        let icon_path = ($ICON_DIR | path join $"($alias).($ext)")
        if ($icon_path | path exists) {
            return $icon_path
        }
    }
    null
}

# Generate bookmarks with icons
def generate-bookmarks-with-icons [] {
    open $BOOKMARKS_FILE
    | each { |bookmark|
        let alias = $bookmark.alias
        let url = $bookmark.url

        let icon_string = (find-icon-file $alias) | default $FALLBACK_ICON

        # Rofi format: alias\0icon\x1ficon_path\turl
        {
            display: $"($alias)\0icon\x1f($icon_string)\t($url)"
            url: $url
        }
    }
}

# Parse user input from rofi and generate display format
def parse-user-input [input: string] {
    if ($input | is-empty) {
        return null
    }

    # Check if it's a bookmark selection (contains icon separator)
    if ($input | str contains "\x00icon\x1f") {
        # Extract URL from bookmark format
        let url = ($input
            | split column "\t" display url
            | get url.0)
        {
            url: $url
            display: $input
        }
    } else if ($input | str contains ".") and not ($input | str contains " ") {
        # Direct URL input
        let url = if ($input | str starts-with "https://") or ($input | str starts-with "http://") {
            $input
        } else {
            $"https://($input)"
        }
        let icon_string = (find-icon-file "external-url") | default "web-browser"
        {
            url: $url
            display: $"($input)\0icon\x1f($icon_string)\t($url)"
        }
    } else {
        # Default to Google search
        let search_url = $"https://www.google.com/search?q=($input | url encode)"
        let google_icon = (find-icon-file $GOOGLE_ICON) | default $GOOGLE_ICON
        {
            url: $search_url
            display: $"Search: ($input)\0icon\x1f($google_icon)\t($search_url)"
        }
    }
}

# Open URL in default browser
def open-url [url: string] {
    xdg-open $url
}

# Main function
def main [] {
    # Validate environment
    check-dependencies
    validate-bookmark-file

    # Generate bookmarks
    let bookmarks = generate-bookmarks-with-icons

    if ($bookmarks | is-empty) {
        error make {
            msg: "No bookmarks found or invalid YAML"
        }
    }

    # Show rofi interface
    let selected = $bookmarks
    | get display
    | str join "\n"
    | rofi -dmenu -p "Bookmarks" -matching fuzzy -filter "" -show-icons

    # Handle user selection
    let result = parse-user-input $selected

    if not ($result | is-empty) and ($result | columns | length) > 0 {
        open-url $result.url
    }
}

# Run main function
main
