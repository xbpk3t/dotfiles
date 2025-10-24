#!/usr/bin/env bash

# pwgen workflow for rofi
# Generates passwords for websites using pwgen --secret=<secret> <website>

# Get user input for website
if [ -z "$@" ]; then
    echo "Enter website:"
else
    website="$@"

    # Generate password using pwgen command
    # Assumes PWGEN_SECRET environment variable is set
    password=$(pwgen --secret="$PWGEN_SECRET" "$website" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$password" ]; then
        # Copy password to clipboard
        echo -n "$password" | wl-copy 2>/dev/null || echo -n "$password" | xclip -selection clipboard 2>/dev/null

        # Show notification
        notify-send "Password Generator" "Password for '$website' copied to clipboard" 2>/dev/null || echo "Password copied to clipboard"

        # Output for rofi display
        echo "Password for '$website' copied to clipboard"
        echo ""
        echo "Press Enter to exit"
    else
        # Show error
        echo "Error generating password for '$website'"
        echo ""
        echo "Make sure 'pwgen --secret=<secret> $website' works correctly"
        echo "And that PWGEN_SECRET is set in environment"
    fi
fi
