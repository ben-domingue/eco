#!/usr/bin/env python3
"""Every core table in output/ has its full set of companions, or the build is red.

A table is a set of files, not one CSV: the core table, its `__taxa` side table
and `__dataset.json` (standard.md E10), a row in dictionary/dictionary_auto.csv,
a row in tags/tags_auto.csv (or tags_human.csv), and, because the site and the R
package read the derived pipeline outputs rather than those staging files, a row
in metadata/metadata.csv. CLAUDE.md asks every data/ script to end with
write_table(), stage_dict_row() and stage_tag_row(), and every batch to be
followed by metadata/run_pipeline.sh; this is the mechanical check that it
happened, run on every PR (issue #4) rather than by a monthly audit (IRW's
17_coverage.R).

Missing companions FAIL (exit 1). A table is known by its `__dataset.json`, which
is always tracked; a table whose core CSV (or `.parts/` directory) is not on this
machine, because it is gitignored and has not been rebuilt here, is checked like
any other and reported as `core absent here`, not as stale (#66). A dictionary,
tags or metadata row that names a table with no `__dataset.json` is WARNED about
and does not fail: withdrawals are ledgered in releases/withdrawals.csv and the
pipeline prunes on its own schedule.

Offline, standard library only. Run from anywhere: paths are relative to the
repository root this file lives in.

    python3 tools/check_coverage.py            # exit 0 = every table covered
    python3 tools/check_coverage.py --quiet    # only the problems
"""
from __future__ import annotations

import argparse
import csv
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
DICT = ROOT / "dictionary" / "dictionary_auto.csv"
TAGS = [ROOT / "tags" / "tags_auto.csv", ROOT / "tags" / "tags_human.csv"]
META = ROOT / "metadata" / "metadata.csv"


def tables_in(path: pathlib.Path) -> set[str]:
    if not path.exists():
        return set()
    with path.open(newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None or "table" not in reader.fieldnames:
            sys.exit(f"{path.relative_to(ROOT)}: no 'table' column")
        return {row["table"] for row in reader if row.get("table")}


def core_tables() -> list[str]:
    # Side tables carry a double underscore; core tables never do (standard E10).
    # A table stored as period parts is the directory <name>.parts/ (standard E4).
    return sorted([p.stem for p in OUT.glob("*.csv") if "__" not in p.name]
                  + [p.name.removesuffix(".parts") for p in OUT.glob("*.parts") if p.is_dir()])


def tables_by_dataset() -> set[str]:
    return {p.name.removesuffix("__dataset.json") for p in OUT.glob("*__dataset.json")}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--quiet", action="store_true", help="print only problems")
    args = ap.parse_args(argv)

    present = set(core_tables())
    known = tables_by_dataset()
    core = sorted(present | known)
    if not core:
        print(f"no core tables under {OUT}", file=sys.stderr)
        return 2

    in_dict = tables_in(DICT)
    in_tags = set().union(*(tables_in(p) for p in TAGS))
    in_meta = tables_in(META)

    problems: list[str] = []
    for t in core:
        missing = []
        if not (OUT / f"{t}__taxa.csv").exists():
            missing.append("output/<t>__taxa.csv")
        if not (OUT / f"{t}__dataset.json").exists():
            missing.append("output/<t>__dataset.json")
        if t not in in_dict:
            missing.append("dictionary/dictionary_auto.csv row")
        if t not in in_tags:
            missing.append("tags/tags_auto.csv (or tags_human.csv) row")
        if t not in in_meta:
            missing.append("metadata/metadata.csv row (run metadata/run_pipeline.sh)")
        if missing:
            problems.append(f"{t}: missing " + "; ".join(missing))
        elif not args.quiet:
            print(f"ok   {t}" + ("" if t in present else "   (core absent here: gitignored, not rebuilt)"))

    absent = sorted(known - present)
    stale = (in_dict | in_tags | in_meta) - set(core)
    for t in sorted(stale):
        where = [n for n, s in (("dictionary", in_dict), ("tags", in_tags), ("metadata", in_meta)) if t in s]
        print(f"WARN {t}: row in {', '.join(where)} but no output/{t}__dataset.json")

    for p in problems:
        print(f"FAIL {p}")
    print(f"{len(core)} tables ({len(absent)} with the core absent here), {len(problems)} incomplete, {len(stale)} stale rows")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
