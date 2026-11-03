#!/usr/bin/env python3
"""Every file outside site/ that the site reads is in site.yml's `paths:` (#27).

The Publish site workflow only runs when a push touches one of its `paths:`
globs. A page that reads a repository file not on that list (standard.md was the
case in #27) goes stale until something else triggers a rebuild. This greps the
Quarto sources under site/ for string literals starting with `../`, resolves each
against the directory of the file that names it, and fails if a path outside
site/ is matched by no glob. A directory reference (`"../output"`, read with
list.files) passes when some glob lies inside that directory.

Offline, standard library only.

    python3 tools/check_site_paths.py      # exit 0 = every path covered
"""
from __future__ import annotations

import fnmatch
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
WORKFLOW = ROOT / ".github" / "workflows" / "site.yml"
SOURCES = ("*.qmd", "*.R", "*.r", "*.py", "*.yml", "*.lua")
LITERAL = re.compile(r"""["'](\.\./[^"'\s]+)["']""")


def workflow_globs() -> list[str]:
    text = WORKFLOW.read_text(encoding="utf-8")
    block = re.search(r"^\s*paths:\s*\n((?:\s*-\s*.+\n)+)", text, re.M)
    if not block:
        sys.exit(f"{WORKFLOW.relative_to(ROOT)}: no `paths:` list under on.push")
    return [m.strip().strip("\"'") for m in re.findall(r"-\s*(.+)", block.group(1))]


def referenced() -> dict[str, set[str]]:
    refs: dict[str, set[str]] = {}
    for pattern in SOURCES:
        for f in SITE.rglob(pattern):
            if "_site" in f.parts or ".quarto" in f.parts:
                continue
            for lit in LITERAL.findall(f.read_text(encoding="utf-8", errors="replace")):
                target = pathlib.Path(os.path.normpath(f.parent / lit))
                try:
                    rel = target.relative_to(ROOT).as_posix()
                except ValueError:
                    continue                      # outside the repository
                if rel == "site" or rel.startswith("site/"):
                    continue                      # covered by site/**
                refs.setdefault(rel, set()).add(f.relative_to(ROOT).as_posix())
    return refs


def covered(rel: str, globs: list[str]) -> bool:
    if any(fnmatch.fnmatch(rel, g) for g in globs):
        return True
    if (ROOT / rel).is_dir():
        return any(g.startswith(rel + "/") for g in globs)
    return False


def main() -> int:
    globs = workflow_globs()
    missing = {rel: by for rel, by in referenced().items() if not covered(rel, globs)}
    for rel, by in sorted(missing.items()):
        print(f"FAIL {rel} (read by {', '.join(sorted(by))}) is not in "
              f".github/workflows/site.yml paths:")
    if missing:
        return 1
    print("site.yml paths: cover every repository file the site reads")
    return 0


if __name__ == "__main__":
    sys.exit(main())
