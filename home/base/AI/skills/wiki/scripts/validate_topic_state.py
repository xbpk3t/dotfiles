#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


REQUIRED_FILES = [
    "plan.md",
    "research-log.md",
    "highlights.md",
    "sources.md",
]


def validate_required_files(topic_dir: Path) -> list[str]:
    return [name for name in REQUIRED_FILES if not (topic_dir / name).exists()]


def validate_chat_files(chat_dir: Path) -> list[str]:
    if not chat_dir.exists():
        return ["chat directory missing"]

    chat_files = sorted(chat_dir.glob("*.md"))
    if not chat_files:
        return []

    invalid = []
    pattern = re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$")
    for path in chat_files:
        if not pattern.match(path.name):
            invalid.append(path.name)
    return invalid


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate_topic_state.py <topic-dir>")
        return 1

    topic_dir = Path(sys.argv[1]).resolve()
    missing_files = validate_required_files(topic_dir)
    if missing_files:
        print("Missing files: " + ", ".join(missing_files))
        return 1

    chat_dir = topic_dir / "chat"
    chat_errors = validate_chat_files(chat_dir)
    if chat_errors:
        print("Chat issues: " + ", ".join(chat_errors))
        return 1

    if topic_dir.name != topic_dir.name.lower() or re.search(
        r"[^a-z0-9-]", topic_dir.name
    ):
        print("Topic directory name must be an English kebab-case slug")
        return 1

    print("Topic state is valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
