"""Fail the release if the tag, eco_validate/pyproject.toml and
eco_validate/__init__.py disagree about the version.

Runs before the build, so an artifact never carries a version that disagrees
with the tag people cite. Called with the tag name, or with "" for a
workflow_dispatch run, where there is no tag to compare; the pyproject and
__init__ are still checked against each other.

Borrowed from irw/src/.github/scripts/check_irw_validate_version.py (#4).
"""
from __future__ import annotations

import pathlib
import re
import sys

PREFIX = "eco-validate-v"
PKG = pathlib.Path(__file__).resolve().parents[2] / "eco_validate"


def grab(path: pathlib.Path, pattern: str) -> str:
    # Not tomllib: this must run on whatever Python the workflow pins, and both
    # fields are unambiguous one-liners.
    m = re.search(pattern, path.read_text(encoding="utf-8"), re.MULTILINE)
    if m is None:
        sys.exit(f"no version found in {path}")
    return m.group(1)


def main(argv: list[str]) -> int:
    pyproject = grab(PKG / "pyproject.toml", r'^version\s*=\s*"([^"]+)"')
    init = grab(PKG / "__init__.py", r'^__version__\s*=\s*"([^"]+)"')
    if pyproject != init:
        sys.exit(f"eco_validate/pyproject.toml says {pyproject!r} but "
                 f"eco_validate/__init__.py says {init!r}; they must agree.")
    tag = argv[1] if len(argv) > 1 else ""
    if not tag:
        print(f"no tag (workflow_dispatch); package declares {pyproject}")
        return 0
    if not tag.startswith(PREFIX):
        sys.exit(f"tag {tag!r} does not start with {PREFIX!r}. Only eco_validate "
                 f"is released from this repository, so its tags say so.")
    tagged = tag[len(PREFIX):]
    if tagged != pyproject:
        sys.exit(f"tag {tag!r} means version {tagged!r}, but the package declares "
                 f"{pyproject!r}. Bump pyproject.toml and __init__.py in a commit "
                 f"on main, then tag that commit.")
    print(f"tag {tag} matches package version {pyproject}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
