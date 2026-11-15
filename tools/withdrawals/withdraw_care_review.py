#!/usr/bin/env python3
"""Withdraw the four tables the CARE screen of 2026-11-06 flagged (#150).

Ben, 2026-11-06: withdraw them now and ask their originators about inclusion
once eco has a way to make sure such contributors get credit; they can be
re-added. The screen and the reasons for each table are in
notes/decisions/care_e7_screen_held.md. Released versions keep them (Redivis
versions are immutable); this removes them from the draft, so they leave the
current release at the next publish.

    python3 tools/withdrawals/withdraw_care_review.py            # dry run
    APPLY=1 python3 tools/withdrawals/withdraw_care_review.py    # delete from the draft, write the ledger
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import withdraw_table  # noqa: E402

TARGETS = {
    "barrueto_2023_nwt_grizzly_scr": "Indigenous Knowledge; detector placement from a TEK workshop in Lutsel K'e, NT",
    "johnson_2023_tweedsmuir_bombus_count": "collected on the unceded territories of the Nuxalk and Ulkatcho First Nations",
    "obrist_2024_gooseisland_birds_count": "Yalaxi (Goose Island) archipelago, BC; results framed with Indigenous and place-based knowledge",
    "banik_2025_dollyvarden_ms": "a species of cultural and subsistence importance to local communities (Yukon North Slope)",
}

if __name__ == "__main__":
    withdraw_table.__file__ = __file__   # the ledger's `script` cites this file, not the generic one
    rc = 0
    for table, why in TARGETS.items():
        rc |= withdraw_table.main([table, "--reason", "care_review", "--refs", "#150",
                                   "--note", f"held pending originator consultation: {why}; may be reinstated"])
    sys.exit(rc)
