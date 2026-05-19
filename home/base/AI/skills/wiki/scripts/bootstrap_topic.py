#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.strip().lower()).strip("-")
    return slug or "topic"


def is_ascii_slug(value: str) -> bool:
    return bool(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value))


def write_if_missing(path: Path, content: str) -> None:
    if not path.exists():
        path.write_text(content, encoding="utf-8")


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: bootstrap_topic.py <wiki-root> <english-topic-slug> [display-topic]"
        )
        return 1

    wiki_root = Path(sys.argv[1]).resolve()
    topic_slug = slugify(sys.argv[2])
    if not is_ascii_slug(topic_slug):
        print("Topic slug must be an English kebab-case slug")
        return 1
    display_topic = sys.argv[3].strip() if len(sys.argv) > 3 else topic_slug
    topic_dir = wiki_root / topic_slug
    chat_dir = topic_dir / "chat"
    assets_dir = topic_dir / "assets"

    assets_dir.mkdir(parents=True, exist_ok=True)
    chat_dir.mkdir(parents=True, exist_ok=True)

    write_if_missing(
        topic_dir / "research-log.md",
        "# Research Log\n\n- Topic: {}\n- Topic Slug: {}\n".format(
            display_topic, topic_slug
        ),
    )
    write_if_missing(
        topic_dir / "plan.md",
        ("# Research Plan\n\n## Todo\n\n## Doing\n\n## Done\n\n## Blocked\n"),
    )
    write_if_missing(topic_dir / "highlights.md", "# Highlights\n")
    write_if_missing(topic_dir / "sources.md", "# Sources\n")

    print(topic_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
