#!/usr/bin/env python3
"""Remove a core table and its side tables from the Redivis `eco` draft, so they
disappear at the next release, and record it in `releases/withdrawals.csv`.

    python3 tools/withdrawals/withdraw_table.py <table> --reason wrong_data --refs "#NN" --note "why"
    APPLY=1 python3 tools/withdrawals/withdraw_table.py <table> --reason ...   # actually delete

Dry run by default: lists what would be deleted and exits. With APPLY=1 it
deletes from the draft (never from a released version: Redivis versions are
immutable, which is the point), appends the ledger rows, and tells you what to
commit. The table's `data/` script and `output/` files are not touched here;
removing those, and setting the tags `status` to `do_not_publish`, is the
follow-up commit the ledger row points at.

For a withdrawal with its own story, copy this file to `withdraw_<what>.py`
with an explicit TARGETS list, as IRW does; the copy stays as the record.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ledger import REASONS, record  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OWNER = "datapages"
DATASET = "eco"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("table", help="core table name; its __taxa/__periods/__units/__traps go with it")
    ap.add_argument("--reason", required=True, choices=REASONS)
    ap.add_argument("--refs", default="", help="issue numbers, e.g. '#12'")
    ap.add_argument("--note", default="")
    ap.add_argument("--dataset", default=DATASET)
    args = ap.parse_args(argv)
    apply = os.environ.get("APPLY") == "1"

    sys.path.insert(0, str(Path.home() / "Dropbox" / "projects" / "irw" / "src"))
    from red_up.auth import authenticate
    from red_up.push import open_draft
    authenticate()
    draft = open_draft(OWNER, args.dataset)
    names = sorted(t.name for t in draft.list_tables())
    targets = [n for n in names if n == args.table or n.startswith(args.table + "__")]
    if not targets:
        print(f"no table named {args.table} (or its side tables) in {OWNER}.{args.dataset}:next", file=sys.stderr)
        return 2
    rows = {}
    for n in targets:
        try:
            rows[n] = draft.table(n).get().properties.get("numRows", "")
        except Exception:
            rows[n] = ""
    mode = "APPLY" if apply else "DRY RUN"
    print(f"{mode}: {len(targets)} table(s) in {OWNER}.{args.dataset}:next")
    for n in targets:
        print(f"  {n:<45} {rows[n]!s:>8} rows")
    if not apply:
        print("\nnothing deleted. Rerun with APPLY=1 to delete from the draft and write the ledger.")
        return 0
    for n in targets:
        draft.table(n).delete()
        print(f"  deleted {n}")
    record(targets, dataset=args.dataset, reason=args.reason, refs=args.refs, note=args.note,
           script=__file__, rows=rows)
    print(f"\nledger: {len(targets)} row(s) appended to releases/withdrawals.csv. Commit it. "
          f"Then set `status` to `tagged; do_not_publish: ...` in tags/tags_auto.csv (or remove the "
          f"data/ script and output/ files), and after Ben publishes fill `released` and add the "
          f"table_changes.csv row.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
