#!/usr/bin/env python3
"""Re-validate the eco corpus on Redivis and update validate/report.csv (#88).

Tables live on Redivis, not in git, and the upload is the gate, so this is
needed only after a change to eco_validate/ that could flip the verdict on a
table already shipped. For each core table in the chosen version of `datapages.eco`
that has an output/<t>__dataset.json in the repo, the core and its side tables
are downloaded to a temporary directory, validated with eco-validate --irw
beside the tracked __dataset.json, and deleted. Nothing is read from output/
except the __dataset.json files.

The draft (`next`) is checked when one exists, otherwise the latest released
version (--released forces that). A table over
--max-rows (default five million, the size at which the standard splits a table
into period parts) is not downloaded: its row is kept from the last report,
which the uploader wrote when the table passed the upload gate.

Reading the draft needs REDIVIS_API_TOKEN; the released version reads
anonymously. irw-validate must be importable (pip install irw-validate, or the
IRW checkout at $IRW_SRC).

    python3 validate/validate_redivis.py                 # draft if any, else latest
    python3 validate/validate_redivis.py --released      # the latest released version
    python3 validate/validate_redivis.py --tables a b    # just these
Exit 0 when every table checked is eco-valid, 1 otherwise, 2 on a setup error.
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
import warnings
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
from eco_validate import validate_file  # noqa: E402
import report  # noqa: E402

OWNER, DATASET = "datapages", "eco"
warnings.filterwarnings("ignore", message="No reference id")


def open_version(released: bool):
    import redivis
    org = redivis.organization(OWNER)
    if not released:
        try:
            ds = org.dataset(DATASET, version="next")
            ds.get()
            return ds, "next (draft)"
        except Exception:
            pass
    ds = org.dataset(DATASET)
    ds.get()
    return ds, ds.properties.get("version", {}).get("tag", "latest")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--released", action="store_true", help="check the latest released version, not the draft")
    ap.add_argument("--tables", nargs="+", help="only these core tables")
    ap.add_argument("--max-rows", type=int, default=5_000_000)
    args = ap.parse_args(argv)

    try:
        ds, label = open_version(args.released)
        on_redivis = {t.name: t for t in ds.list_tables()}
    except Exception as e:
        print(f"cannot read {OWNER}.{DATASET} on Redivis: {e}", file=sys.stderr)
        return 2
    in_repo = {p.name.removesuffix("__dataset.json") for p in report.OUT.glob("*__dataset.json")}
    cores = sorted(n for n in on_redivis if "__" not in n)
    for t in sorted(set(cores) - in_repo):
        print(f"WARN {t}: on Redivis {label} but no output/{t}__dataset.json in the repo (withdrawn, or not merged)")
    for t in sorted(in_repo - set(cores)):
        print(f"WARN {t}: __dataset.json in the repo but not on Redivis {label} (not uploaded yet?)")
    todo = [t for t in cores if t in in_repo and (not args.tables or t in args.tables)]
    print(f"validate_redivis: {len(todo)} table(s) from {OWNER}.{DATASET} {label}")

    rows, skipped, bad = [], [], []
    for t in todo:
        tab = on_redivis[t]
        tab.get()
        n = int(tab.properties.get("numRows") or 0)
        if n > args.max_rows:
            skipped.append(f"{t} ({n:,} rows)")
            continue
        d = Path(tempfile.mkdtemp(prefix="eco_rd_"))
        try:
            for name in [t] + sorted(x for x in on_redivis if x.startswith(t + "__")):
                on_redivis[name].download(str(d / f"{name}.csv"), progress=False)
            shutil.copy(report.OUT / f"{t}__dataset.json", d)
            r = validate_file(d / f"{t}.csv", profile="upload", irw=True).to_dict()
            row = report.report_row(r, report.dataset_meta(t))
        finally:
            shutil.rmtree(d, ignore_errors=True)
        rows.append(row)
        flag = "ok  " if row["eco_valid"] == "TRUE" else "FAIL"
        if flag == "FAIL":
            bad.append(t)
        print(f"{flag} {t}  {row['rows']} rows  irw {row['irw_v1']}" + (f"  {row['eco_problems']}" if flag == "FAIL" else ""))

    report.update_report(rows)
    if skipped:
        print(f"kept the last report row for {len(skipped)} table(s) over {args.max_rows:,} rows: " + ", ".join(skipped))
    print(f"{len(rows)} validated, {len(bad)} not eco-valid, {len(skipped)} kept -> validate/report.csv")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
