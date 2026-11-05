"""validate/report.csv: one row per table, the eco-validate verdict the site reads.

Rows are written where a table is validated, never by scanning a local corpus
(#88): the uploader writes the rows for what it ships (upload/red_up_eco.py),
and validate_redivis.py rewrites them from the tables on Redivis. A row for a
table that was not validated in this run is kept as it was; a row for a table
with no output/<t>__dataset.json (withdrawn) is dropped.

Columns are those the R report builder (validate_all.R, before #88) wrote, so
site/ and metadata/11_status.R read the file unchanged.
"""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
REPORT = ROOT / "validate" / "report.csv"
COLUMNS = ["table", "rows", "units", "taxa", "eco_valid", "eco_problems", "eco_warnings", "conforms",
           "nonconforming", "taxa_table_matches", "sample_floor", "survey_evidence", "standard",
           "irw_v1", "irw_warnings"]


def _tf(x: bool) -> str:
    return "TRUE" if x else "FALSE"


def report_row(r: dict, ds: dict) -> dict:
    """One report row from a validate_file(..., irw=True).to_dict() result and
    the table's __dataset.json."""
    f = r.get("findings") or []
    eco = [x for x in f if x.get("group") != "irw"]
    irw = [x for x in f if x.get("group") == "irw"]
    eco_err = [x for x in eco if x.get("severity") == "error"]
    irw_conf = not any(x.get("check") == "irw:conformance" for x in f)
    irw_v1 = ("blocks" if any(x.get("severity") == "error" for x in irw) else "passes") + \
             (" (conforms to v1.0)" if irw_conf else " (does not conform)")
    s = r.get("stats") or {}
    return {
        "table": r["label"], "rows": s.get("n_rows", ""), "units": s.get("n_units", ""), "taxa": s.get("n_taxa", ""),
        "eco_valid": _tf(bool(r.get("ok")) or not eco_err),
        "eco_problems": "; ".join(f"{x['check']}: {x['message']}" for x in eco_err),
        "eco_warnings": "; ".join(x["check"] for x in eco if x.get("severity") == "warn"),
        "conforms": _tf(bool(r.get("conforms"))),
        "nonconforming": ",".join(r.get("nonconforming") or []),
        "taxa_table_matches": _tf("taxa" in (r.get("side_tables") or [])
                                  and not any(x["check"] == "side_taxa" and x.get("severity") == "error" for x in f)),
        "sample_floor": ds.get("sampleFloor") or "", "survey_evidence": ds.get("surveyEvidence") or "",
        "standard": ds.get("standardVersion") or "",
        "irw_v1": irw_v1,
        "irw_warnings": "; ".join(x["check"].removeprefix("irw:") for x in irw
                                  if x.get("severity") == "warn" and x["check"] != "irw:conformance"),
    }


def read_report(path: Path = REPORT) -> dict[str, dict]:
    if not path.exists():
        return {}
    with path.open(newline="", encoding="utf-8") as fh:
        return {row["table"]: row for row in csv.DictReader(fh)}


def _cell(v) -> str:
    v = "" if v is None else str(v)
    if v == "" or any(c in v for c in ',"\n\r'):
        return '"' + v.replace('"', '""') + '"'
    return v


def update_report(rows: list[dict], path: Path = REPORT) -> None:
    """Replace the rows for these tables, keep every other row, drop rows for
    tables that no longer have a __dataset.json, write sorted by table."""
    old = read_report(path)
    for r in rows:
        old[r["table"]] = r
    listed = {p.name.removesuffix("__dataset.json") for p in OUT.glob("*__dataset.json")}
    keep = [old[t] for t in sorted(old) if t in listed]
    with path.open("w", encoding="utf-8", newline="") as fh:
        fh.write(",".join(COLUMNS) + "\n")
        for r in keep:
            fh.write(",".join(_cell(r.get(c, "")) for c in COLUMNS) + "\n")


def dataset_meta(table: str) -> dict:
    p = OUT / f"{table}__dataset.json"
    return json.loads(p.read_text()) if p.exists() else {}
