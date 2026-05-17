#!/usr/bin/env python3
"""Read JSON from stdin, try to parse, attempt repair if needed, output fixed JSON or exit 1."""

import sys
import json


def fix_json(s: str) -> str:
    """Try to parse s as JSON; if invalid, attempt to repair unescaped quotes."""
    try:
        json.loads(s)
        return s
    except json.JSONDecodeError:
        pass

    chars = list(s)
    i = 0
    in_string = False
    n = len(chars)

    while i < n:
        c = chars[i]
        if c == "\\" and in_string and i + 1 < n:
            # Valid escape sequence inside string — skip escaped char
            i += 2
            continue
        if c == '"':
            if not in_string:
                in_string = True
            else:
                # Inside a string and see " — could be real close or unescaped inner quote.
                # Heuristic: read next non-whitespace char; if it's a JSON structural
                # delimiter (, : } ]) or end of input, this is the real closing quote.
                # Otherwise it's an unescaped quote inside the value.
                j = i + 1
                while j < n and chars[j] in " \t\n\r":
                    j += 1
                if j >= n or chars[j] in ",:}]":
                    in_string = False
                else:
                    # Unescaped inner quote — replace with left double quotation mark
                    chars[i] = "“"
        i += 1

    fixed = "".join(chars)
    try:
        json.loads(fixed)
        return fixed
    except json.JSONDecodeError:
        return s  # give up, return original


if __name__ == "__main__":
    text = sys.stdin.read()
    result = fix_json(text)
    try:
        json.loads(result)
        sys.stdout.write(result)
        sys.exit(0)
    except json.JSONDecodeError:
        sys.exit(1)
