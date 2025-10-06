#!/usr/bin/env bash
# YAML Bookmark Manager for Rofi with Smart Search
# Dependencies: yq, rofi, xdg-utils

BOOKMARKS_FILE="$HOME/.config/rofi/bookmark/bm.yml"

# 检查必要工具
command -v yq >/dev/null 2>&1 || { echo "Error: yq is required"; exit 1; }
command -v rofi >/dev/null 2>&1 || { echo "Error: rofi is required"; exit 1; }

# 检查书签文件是否存在
if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    echo "Error: Bookmarks file not found: $BOOKMARKS_FILE"
    exit 1
fi

# 生成书签列表：alias | url (支持搜索别名和URL)
bookmarks=$(yq eval '.[] | "\(.alias) | \(.url)"' "$BOOKMARKS_FILE" 2>/dev/null)
if [[ -z "$bookmarks" ]]; then
    echo "Error: No bookmarks found or invalid YAML"
    exit 1
fi

# 使用 rofi 显示书签，支持模糊搜索
INPUT=$(echo "$bookmarks" | rofi -dmenu -p "Bookmarks" -matching fuzzy -filter "")

# 智能处理用户输入
if [[ -z $INPUT ]]; then
    # 用户取消输入，直接退出
    exit 0
elif [[ "$INPUT" == *" | "* ]]; then
    # 用户选择了书签（格式：alias | url）
    url=$(echo "$INPUT" | sed 's/.* | //')
    if [[ -n "$url" ]]; then
        xdg-open "$url"
    fi
elif [[ "$INPUT" == *"."* && "$INPUT" != *" "* ]]; then
    # 直接输入URL（包含点且不包含空格）
    if [[ ! "$INPUT" =~ ^https?:// ]]; then
        INPUT="https://$INPUT"
    fi
    xdg-open "$INPUT"
else
    # 默认Google搜索
    xdg-open "https://www.google.com/search?q=$INPUT"
fi