#!/usr/bin/env python3
"""Withdraw the national Breeding Bird Survey count tables, replaced by 37 tables by BCR (#72).

Standard E4's partitions ruling (2026-11-15, an exception to ruling #31 for size): a
table over 1 GB as CSV ships split by the source's own regional stratum. The national
table (110,127,544 rows, about 9 GB as CSV, 18 GB on Redivis) and its _exact sibling
are replaced by `ziolkowski_2026_bbs_bcr<N>_count` (N = 1..37) and their `_exact`
siblings, built by data/ziolkowski_2026_bbs.R; every row of the national tables is in
them, apart from the zeros of a taxon at the runs of a BCR where it was never recorded,
which `eco_stack("ziolkowski_2026_bbs", fill_zeros = TRUE)` restores.

    python3 tools/withdrawals/withdraw_bbs_national.py            # dry run: what would go
    APPLY=1 python3 tools/withdrawals/withdraw_bbs_national.py    # delete from the eco draft

The ledger rows were written with the change (PR for #72), so APPLY=1 appends only a
row that is not there yet. Run it in the same sitting as the upload of the BCR tables,
so no draft holds the national table and its replacement together. Dry run by default.
"""
from __future__ import annotations

import csv
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ledger import LEDGER, record  # noqa: E402

DATASET = "eco"
TARGETS = ["ziolkowski_2026_bbs_count", "ziolkowski_2026_bbs_exact_count"]
NOTE = ("replaced by the 37 per-BCR tables ziolkowski_2026_bbs_bcr<N>_count (and their _exact siblings) "
        "under the partitions exception to ruling #31 (standard E4, #72)")


def main() -> int:
    apply = os.environ.get("APPLY") == "1"
    sys.path.insert(0, str(Path.home() / "Dropbox" / "projects" / "irw" / "src"))
    from red_up.auth import authenticate
    from red_up.push import open_draft
    authenticate()
    draft = open_draft("datapages", DATASET)
    names = sorted(t.name for t in draft.list_tables())
    with LEDGER.open(encoding="utf-8") as fh:
        in_ledger = {r["table"] for r in csv.DictReader(fh)}
    for old in TARGETS:
        targets = [n for n in names if n == old or n.startswith(old + "__")]
        rows = {}
        for n in targets:
            try:
                rows[n] = draft.table(n).get().properties.get("numRows", "")
            except Exception:
                rows[n] = ""
        print(f"{'APPLY' if apply else 'DRY RUN'} {old}: {', '.join(targets) or 'not in draft'}")
        if apply and targets:
            for n in targets:
                draft.table(n).delete()
            new = [n for n in targets if n not in in_ledger]
            if new:
                record(new, dataset=DATASET, reason="duplicate", refs="#72, #31", note=NOTE, script=__file__, rows=rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
