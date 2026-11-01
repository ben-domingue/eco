#!/usr/bin/env python3
"""Ship metadata/metadata.csv, biblio.csv and tags.csv to the Redivis dataset
`eco_meta` as tables `metadata`, `biblio`, `tags`, with IRW's `red_up` (true
replace, row counts verified). Draft only; publishing is a human click.

    python3 metadata/upload_meta.py --dry-run
    python3 metadata/upload_meta.py

The dataset must already exist: Ben creates Redivis datasets himself. If it does
not, this says so and exits 2 instead of creating it.
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

from red_up.auth import authenticate
from red_up.push import open_draft, push_one
from red_up.targets import load_registry

ROOT = Path(__file__).resolve().parent.parent
MD = ROOT / "metadata"
DATASET = "eco_meta"
TABLES = ("metadata", "biblio", "tags")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dataset", default=DATASET)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--yes", "-y", action="store_true")
    args = ap.parse_args(argv)

    owner, _ = load_registry()
    plan = []
    for t in TABLES:
        p = MD / f"{t}.csv"
        if not p.exists():
            print(f"missing {p}; run metadata/run_pipeline.sh first", file=sys.stderr); return 2
        with p.open(newline="", encoding="utf-8") as fh:
            n = sum(1 for _ in csv.reader(fh)) - 1
        plan.append((p, t, n))
    tabs = {r["table"] for r in csv.DictReader((MD / "metadata.csv").open(encoding="utf-8"))}
    for t in ("biblio", "tags"):
        other = {r["table"] for r in csv.DictReader((MD / f"{t}.csv").open(encoding="utf-8"))}
        if other != tabs:
            print(f"{t}.csv and metadata.csv list different tables: {sorted(tabs ^ other)}", file=sys.stderr); return 2

    print(f"upload_meta -- {len(plan)} table(s) -> {owner}.{args.dataset}:next")
    for p, t, n in plan:
        print(f"  {t:<10} {n:>5} rows  {p.relative_to(ROOT)}")
    if args.dry_run:
        print("--dry-run: nothing written."); return 0

    authenticate()
    import redivis
    ds = redivis.organization(owner).dataset(args.dataset)
    if not ds.exists():
        print(f"{owner}.{args.dataset} does not exist on Redivis. Ask Ben to create it; this script never does.",
              file=sys.stderr); return 2
    if not args.yes and sys.stdin.isatty():
        if input(f"Upload to {owner}.{args.dataset}:next? [y/N] ").strip().lower() != "y":
            print("Cancelled."); return 0
    dataset = open_draft(owner, args.dataset)
    failed = []
    for p, t, n in plan:
        res = push_one(dataset, p, t, n)
        print(f"  {'ok ' if res.ok else 'FAILED'} {t}" + ("" if res.ok else f": {res.error}"))
        if not res.ok:
            failed.append(t)
    if not failed:
        print(f"DRAFT only: review {owner}.{args.dataset}:next on Redivis and publish by hand.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
