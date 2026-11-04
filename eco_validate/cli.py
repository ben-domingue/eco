"""`eco-validate` -- check eco tables against standard.md and exit non-zero if
anything blocks.

    eco-validate output/                        # every core table in output/
    eco-validate output/kery_2005_mallard_count.csv
    eco-validate output/ --profile format       # the clauses only, no intake policy
    eco-validate output/ --irw                  # also irw-validate on the IRW view
    eco-validate output/ --strict               # warnings block too
    eco-validate output/ --json                 # machine-readable, for CI
    eco-validate output/ -v                     # every affected case, not the first few

Side tables (`<name>__taxa.csv`, `__periods`, `__units`, `__traps`) and
`<name>__dataset.json` are picked up from beside each core CSV; naming a side
table on the command line validates its core table. A table stored as period
parts is the directory `<name>.parts/` (standard E4); name the directory, or
`<name>.csv`, or the directory that holds it.

Exit codes: 0 ok - 1 something blocks - 2 bad input.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .core import PARTS_SUFFIX, TABLE_SUFFIXES, is_parted, format_report, is_core_table, side_suffix, validate_file
from .model import PROFILES, exit_code

_SKIP_DIRS = {"__MACOSX", ".git", "__pycache__", ".cache"}


def expand_paths(paths: list, recursive: bool = False) -> tuple[list, list]:
    """Command-line paths -> core table files. A side table or __dataset.json
    named explicitly resolves to its core table; a directory contributes every
    core CSV directly inside it (or below it with `recursive`)."""
    files, empty = [], []
    for raw in paths:
        p = Path(raw)
        if is_parted(p):                      # a table stored as period parts
            files.append(str(p))
            continue
        if not p.is_dir():
            if side_suffix(p.stem) is not None:
                p = p.with_name(p.stem.rsplit("__", 1)[0] + ".csv")
            files.append(str(p))
            continue
        walk = p.rglob("*") if recursive else p.iterdir()
        found = []
        for f in walk:
            rel = f.relative_to(p).parts
            if any(part.startswith(".") or part in _SKIP_DIRS for part in rel):
                continue
            if any(part.endswith(PARTS_SUFFIX) for part in rel[:-1]):
                continue                      # a part of a parted table, not a table
            if is_core_table(f):
                found.append(str(f))
        if found:
            files.extend(sorted(found))
        else:
            empty.append(str(p))
    seen = set()
    return [f for f in files if not (f in seen or seen.add(f))], empty


def main(argv: list | None = None) -> int:
    ap = argparse.ArgumentParser(prog="eco-validate",
                                 description="Validate eco tables against the eco data standard.")
    ap.add_argument("paths", nargs="+", help="core table CSV(s), or a directory of them")
    ap.add_argument("-r", "--recursive", action="store_true",
                    help="also look in subdirectories of a directory argument")
    ap.add_argument("--profile", default="upload", choices=PROFILES,
                    help="format = the standard's clauses only; upload = clauses plus "
                         "intake policy, the gate (default)")
    ap.add_argument("--irw", action="store_true",
                    help="also run irw-validate on the IRW view (needs irw_validate "
                         "importable or IRW_SRC set)")
    ap.add_argument("--strict", action="store_true", help="warnings block too")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="list every affected case under a finding that otherwise "
                         "names only the first few (--json always carries them)")
    args = ap.parse_args(argv)

    paths, empty = expand_paths(args.paths, recursive=args.recursive)
    for d in empty:
        hint = "" if args.recursive else " (use -r to look in subdirectories)"
        print(f"eco-validate: no core tables ({', '.join(TABLE_SUFFIXES)}) in {d}{hint}",
              file=sys.stderr)
    if empty:
        return 2

    reports = []
    for path in paths:
        try:
            reports.append(validate_file(path, profile=args.profile, irw=args.irw))
        except FileNotFoundError:
            print(f"eco-validate: no such file: {path}", file=sys.stderr)
            return 2
        except Exception as exc:
            print(f"eco-validate: cannot read {path}: {exc}", file=sys.stderr)
            return 2

    if args.json:
        print(json.dumps([r.to_dict() for r in reports], indent=2, default=str))
    else:
        for r in reports:
            print(format_report(r, verbose=args.verbose))
        n_ok = sum(r.ok for r in reports)
        print(f"\n{len(reports)} table(s): {n_ok} pass, {len(reports) - n_ok} blocked")

    code = exit_code(reports, strict=args.strict)
    if code and not args.json:
        blocking = sum(len(r.errors) for r in reports)
        if blocking:
            print(f"{blocking} blocking finding(s).", file=sys.stderr)
        else:
            print("--strict: warnings are blocking.", file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
