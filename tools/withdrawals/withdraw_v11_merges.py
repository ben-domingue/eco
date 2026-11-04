#!/usr/bin/env python3
"""Withdraw the eleven sibling tables that standard v1.1-draft ruling #31 merged.

Each was split from one deposit and one protocol only because the taxa surveyed
for differed between units or runs; under v1.1 one table carries them with a
`__survey_taxa` side table. The rows are all in the merged tables:

    addis_2026_rmap_bt_dynocc, addis_2026_rmap_mbrt_dynocc   -> addis_2026_rmap_amph_dynocc
    nowicki_2019_sharkbay_{megafauna,turtle,dolphin}_count  -> nowicki_2019_sharkbay_count
    inbo_2026_flanders_{aesiso,calvir,coepul}_count         -> inbo_2026_flanders_dragonfly_count
    goldingay_2022_richmond_{glider,koala}_dynocc           -> goldingay_2022_richmond_mammals_dynocc

Dry run by default; APPLY=1 deletes them (and their side tables) from the eco
draft and appends the ledger rows. Kept here as the record the ledger cites.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ledger import record  # noqa: E402

TARGETS = {
    "addis_2026_rmap_bt_dynocc": "addis_2026_rmap_amph_dynocc",
    "addis_2026_rmap_mbrt_dynocc": "addis_2026_rmap_amph_dynocc",
    "nowicki_2019_sharkbay_megafauna_count": "nowicki_2019_sharkbay_count",
    "nowicki_2019_sharkbay_turtle_count": "nowicki_2019_sharkbay_count",
    "nowicki_2019_sharkbay_dolphin_count": "nowicki_2019_sharkbay_count",
    "inbo_2026_flanders_aesiso_count": "inbo_2026_flanders_dragonfly_count",
    "inbo_2026_flanders_calvir_count": "inbo_2026_flanders_dragonfly_count",
    "inbo_2026_flanders_coepul_count": "inbo_2026_flanders_dragonfly_count",
    "goldingay_2022_richmond_glider_dynocc": "goldingay_2022_richmond_mammals_dynocc",
    "goldingay_2022_richmond_koala_dynocc": "goldingay_2022_richmond_mammals_dynocc",
}


def main() -> int:
    apply = os.environ.get("APPLY") == "1"
    sys.path.insert(0, str(Path.home() / "Dropbox" / "projects" / "irw" / "src"))
    from red_up.auth import authenticate
    from red_up.push import open_draft
    authenticate()
    draft = open_draft("datapages", "eco")
    names = sorted(t.name for t in draft.list_tables())
    for old, new in TARGETS.items():
        targets = [n for n in names if n == old or n.startswith(old + "__")]
        rows = {}
        for n in targets:
            try:
                rows[n] = draft.table(n).get().properties.get("numRows", "")
            except Exception:
                rows[n] = ""
        print(f"{'APPLY' if apply else 'DRY RUN'} {old} -> {new}: {', '.join(targets) or 'not in draft'}")
        if apply and targets:
            for n in targets:
                draft.table(n).delete()
            record(targets, dataset="eco", reason="duplicate", refs="#31",
                   note=f"merged into {new} under standard v1.1-draft ruling #31 (__survey_taxa)",
                   script=__file__, rows=rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
