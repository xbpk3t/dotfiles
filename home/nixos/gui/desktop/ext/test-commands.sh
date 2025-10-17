#!/usr/bin/env bash

# Test script for vicinae extension commands
# This script tests the basic functionality of pwgen, dgh, and bookmarks

set -e

echo "=== Testing Extension Commands ==="
echo ""

# Test 1: Check if pwgen binary exists
echo "1. Testing pwgen binary..."
if command -v pwgen &> /dev/null; then
    echo "✓ pwgen binary found at: $(which pwgen)"

    # Check if secret key exists
    if [ -f /etc/sk/pwgen ]; then
        echo "✓ Secret key file exists at /etc/sk/pwgen"
        SECRET=$(cat /etc/sk/pwgen)
        echo "  Testing password generation..."
        pwgen test --secret "$SECRET" --output raw
        echo "✓ Password generation works"
    else
        echo "⚠ Secret key file not found at /etc/sk/pwgen"
        echo "  You can set PWGEN_SECRET environment variable instead"
    fi
else
    echo "✗ pwgen binary not found"
    echo "  Install with: go install github.com/xbpk3t/docs-alfred/pwgen@main"
fi
echo ""

# Test 2: Check if dgh binary exists
echo "2. Testing dgh binary..."
if command -v dgh &> /dev/null; then
    echo "✓ dgh binary found at: $(which dgh)"
    echo "  Testing repository listing..."
    REPO_COUNT=$(dgh --output raw 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    echo "✓ Found $REPO_COUNT repositories"
else
    echo "✗ dgh binary not found"
    echo "  Install with: go install github.com/xbpk3t/docs-alfred/dgh@main"
fi
echo ""

# Test 3: Check bookmarks data
echo "3. Testing bookmarks..."
BOOKMARK_FILE="taskfile/mac/Taskfile.bm.yml"
if [ -f "$BOOKMARK_FILE" ]; then
    echo "✓ Bookmark file found at: $BOOKMARK_FILE"
    BOOKMARK_COUNT=$(grep -c "alias:" "$BOOKMARK_FILE" || echo "0")
    echo "✓ Found $BOOKMARK_COUNT bookmarks"
else
    echo "✗ Bookmark file not found at: $BOOKMARK_FILE"
fi
echo ""

# Test 4: Check snippets data
echo "4. Testing snippets..."
SNIPPET_FILE="taskfile/mac/Taskfile.snippets.yml"
if [ -f "$SNIPPET_FILE" ]; then
    echo "✓ Snippet file found at: $SNIPPET_FILE"
    echo "✓ Snippets data available"
else
    echo "✗ Snippet file not found at: $SNIPPET_FILE"
fi
echo ""

# Test 5: Check if vicinae is installed
echo "5. Testing vicinae installation..."
if command -v vici &> /dev/null; then
    echo "✓ vici command found at: $(which vici)"
    echo "  Vicinae version: $(vici --version 2>/dev/null || echo 'unknown')"
else
    echo "✗ vici command not found"
    echo "  Make sure vicinae is installed and in PATH"
fi
echo ""

echo "=== Test Summary ==="
echo "All basic checks completed."
echo ""
echo "To test the extension in vicinae:"
echo "1. Run: cd home/nixos/gui/desktop/ext && pnpm dev"
echo "2. Open vicinae and search for:"
echo "   - 'pwgen' for password generation"
echo "   - 'gh' for GitHub repositories"
echo "   - 'ws' for bookmarks"
echo "   - 'ss' for snippets"
