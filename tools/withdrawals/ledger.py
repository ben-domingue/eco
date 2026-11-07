"""Append withdrawn tables to `releases/withdrawals.csv`, the record keyed by table name.

Append-only: rows are never rewritten or removed. The one column filled after
the fact is `released`, the eco version at which the withdrawal left the current
release; a draft deletion is invisible until Ben publishes, so the row is written
at deletion time with `released` blank. `reinstated` is a date, written by hand,
when a withdrawal is undone. Shape from irw's tools/withdrawals/ledger.py (#2155).

    from ledger import record
    record(["some_table", "some_table__taxa"], dataset="eco", reason="wrong_data",
           refs="#NN", note="zeros encoded unsurveyed cells", script=__file__)
"""
from __future__ import annotations

import csv
import datetime as dt
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / "releases" / "withdrawals.csv"
COLUMNS = ["table", "dataset", "withdrawn", "reason", "refs", "rows", "released", "script", "note", "reinstated"]
REASONS = ("rights", "wrong_data", "duplicate", "unlicensed", "source_withdrawn", "out_of_scope", "misnamed",
           "care_review")


def record(tables, *, dataset: str, reason: str, refs: str = "", note: str = "",
           script: str = "", rows: dict | None = None) -> None:
    if reason not in REASONS:
        raise ValueError(f"reason must be one of {REASONS}, not {reason!r}")
    new = not LEDGER.exists()
    today = dt.date.today().isoformat()
    rel = str(Path(script).resolve().relative_to(ROOT)) if script else ""
    with LEDGER.open("a", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS)
        if new:
            w.writeheader()
        for t in tables:
            w.writerow({"table": t, "dataset": dataset, "withdrawn": today, "reason": reason, "refs": refs,
                        "rows": (rows or {}).get(t, ""), "released": "", "script": rel, "note": note, "reinstated": ""})
