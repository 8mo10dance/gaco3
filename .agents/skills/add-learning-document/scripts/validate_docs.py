#!/usr/bin/env python3
"""Validate the repository's top-level learning documents and their index."""

from __future__ import annotations

import argparse
import re
import stat
import sys
from collections import Counter
from pathlib import Path


FILENAME_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\.md\Z")
HEADING_RE = re.compile(r"^(#{1,6})\s+\S")
FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")


def repository_root() -> Path:
    return Path(__file__).resolve().parents[4]


def is_relative_link(target: str) -> bool:
    return not (
        not target
        or target.startswith("#")
        or target.startswith("/")
        or target.startswith("//")
        or re.match(r"[A-Za-z][A-Za-z0-9+.-]*:", target)
    )


def link_destination(raw_target: str) -> str:
    target = raw_target.strip()
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    else:
        target = target.split(maxsplit=1)[0]
    return target.split("#", maxsplit=1)[0].split("?", maxsplit=1)[0]


def markdown_links(path: Path) -> list[str]:
    return [link_destination(match.group(1)) for match in LINK_RE.finditer(path.read_text())]


def validate_markdown(path: Path, errors: list[str]) -> None:
    fence: tuple[str, int] | None = None
    h1_count = 0
    previous_level = 0

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        fence_match = FENCE_RE.match(line)
        if fence_match:
            marker = fence_match.group(1)
            if fence is None:
                fence = (marker[0], len(marker))
                continue
            if marker[0] == fence[0] and len(marker) >= fence[1]:
                fence = None
                continue

        if fence is not None:
            continue

        heading_match = HEADING_RE.match(line)
        if heading_match is None:
            continue

        level = len(heading_match.group(1))
        if level == 1:
            h1_count += 1
        if previous_level and level > previous_level + 1:
            errors.append(
                f"{path}: line {line_number}: heading level jumps from H{previous_level} to H{level}"
            )
        previous_level = level

    if fence is not None:
        errors.append(f"{path}: unclosed code fence")
    if h1_count != 1:
        errors.append(f"{path}: expected exactly one H1, found {h1_count}")


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    docs_dir = root / "docs"
    index = docs_dir / "README.md"

    if not docs_dir.is_dir():
        return [f"{docs_dir}: directory does not exist"]
    if not index.is_file():
        return [f"{index}: index does not exist"]

    markdown_files = sorted(docs_dir.glob("*.md"))
    documents = [path for path in markdown_files if path.name != "README.md"]

    for path in markdown_files:
        mode = stat.S_IMODE(path.stat().st_mode)
        if mode != 0o644:
            errors.append(f"{path}: expected mode 0644, found {mode:04o}")
        validate_markdown(path, errors)

    for path in documents:
        if FILENAME_RE.fullmatch(path.name) is None:
            errors.append(f"{path}: filename must be lowercase English kebab-case")

    for path in markdown_files:
        for target in markdown_links(path):
            if not is_relative_link(target):
                continue
            linked_path = (path.parent / target).resolve()
            if not linked_path.exists():
                errors.append(f"{path}: broken relative link: {target}")

    index_links: list[Path] = []
    for target in markdown_links(index):
        if not is_relative_link(target):
            continue
        linked_path = (index.parent / target).resolve()
        if linked_path.parent == docs_dir.resolve() and linked_path.suffix == ".md":
            index_links.append(linked_path)

    document_paths = {path.resolve() for path in documents}
    index_counts = Counter(index_links)
    missing = sorted(document_paths - set(index_counts))
    extra = sorted(set(index_counts) - document_paths)

    for path in missing:
        errors.append(f"{index}: document is missing from index: {path.name}")
    for path in extra:
        errors.append(f"{index}: index links to a non-document: {path.name}")
    for path, count in sorted(index_counts.items()):
        if count != 1:
            errors.append(f"{index}: document is indexed {count} times: {path.name}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=repository_root(),
        help="repository root to validate (defaults to this skill's repository)",
    )
    args = parser.parse_args()

    errors = validate(args.root.resolve())
    if errors:
        print("Documentation validation failed:", file=sys.stderr)
        print(*errors, sep="\n", file=sys.stderr)
        return 1

    print("Documentation validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
