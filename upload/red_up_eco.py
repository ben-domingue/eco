#!/usr/bin/env python3
"""Ship output/ to the Redivis dataset `eco` with IRW's uploader, red_up.

    python3 upload/red_up_eco.py --dry-run     # plan only
    python3 upload/red_up_eco.py               # confirm, then upload to the draft
    python3 upload/red_up_eco.py --yes

Borrowed from ben-domingue/irw `src/red_up` (installed editable from that
checkout): its CSV scan and duplicate-name checks, the IRW format validator
gate, the true-replace upload (`push_one`: delete the draft table, recreate,
upload, count(*) against the draft), and the draft opener. What this wrapper
adds, and why red_up alone is not enough here:

  * red_up refuses `--dataset eco` without `--allow-unregistered`, excludes
    every `*__items.csv` (that suffix means IRW item text) and gates on
    id/item/resp. Eco tables are unit/taxon/y, so the IRW validator runs on the
    `eco_to_irw()` view that validate/validate_all.R writes to .cache/irw_view/. The eco side tables (`__taxa`, `__periods`,
    `__units`, `__traps`) are real tables that belong beside the core file, so they are
    uploaded here with their own key check instead of the core gate.
  * red_up's targets come from IRW's redivis_config.R, where `eco` is not and
    should not be registered: the eco corpus is a separate dataset under the
    same owner, not an IRW shard.
  * Each table gets its description from output/<table>__dataset.json (title,
    citation, licence, counts), which IRW keeps in a sheet instead.
  * A core table whose tags row (tags/tags_auto.csv) carries a `do_not_publish`
    (or the retired `hold`) status is refused, with its side tables, unless
    `--allow-hold` is passed. Added after two tables tagged `hold` reached the
    first published version (ben-domingue/eco#1): the tag is the one place a
    "do not ship" decision is written, so the uploader has to read it.

Like red_up, nothing here publishes. Everything lands on the dataset's
unreleased draft; releasing is a human click on Redivis.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

from red_up.auth import authenticate
from red_up.checks import check_all, run_validator
from red_up.push import open_draft, push_one
from red_up.targets import load_registry

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "output"
TAGS = ROOT / "tags" / "tags_auto.csv"
STANDARD_PREFIX = "eco v1.0"   # standard.md; a table built under an older draft is rebuilt, not shipped
DATASET = "eco"
DATASET_DESCRIPTION = (
    "Ecological detection data (occupancy, counts, capture histories, community "
    "surveys) in an IRW-style long format: unit = site or individual, taxon, "
    "y = detection / count / state, period + occasion = primary / secondary survey, "
    "covariates prefixed unit_ / period_ / obs_ / taxon_. A row exists iff a survey "
    "happened. Each core table <t> has side tables <t>__items (taxa, GBIF keys, traits) "
    "and, where relevant, <t>__periods. Draft standard v0.2, 2026-10. Sources are CC0 / "
    "CC BY deposits; see each table's description.")

#: Which column a side table must carry to be the table its suffix claims.
SIDE_KEYS = {"__taxa": "taxon", "__periods": "period", "__units": "unit", "__traps": "trap"}


def side_suffix(table: str) -> str | None:
    for suffix in SIDE_KEYS:
        if table.endswith(suffix):
            return suffix
    return None


def describe(table: str) -> str | None:
    """Table description from the core table's __dataset.json."""
    core = table.split("__")[0]
    meta_path = OUT / f"{core}__dataset.json"
    if not meta_path.exists():
        return None
    m = json.loads(meta_path.read_text())
    s = m.get("summary", {})
    rights = m.get("intellectualRights", {})
    spdx = rights.get("spdx") if isinstance(rights, dict) else rights
    head = (f"{m.get('title', core)}\n\nSource: {m.get('citation', m.get('sourceURL', ''))}\n"
            f"Licence: {spdx}. responseType={m.get('responseType')}, unitKind={m.get('unitKind')}, "
            f"itemKind={m.get('itemKind')}, closure={m.get('closure')}.")
    suffix = side_suffix(table)
    if suffix == "__taxa":
        return f"Taxon side table for {core}: taxon code -> scientificName, GBIF taxonID, traits (taxon_*).\n\n{head}"
    if suffix == "__periods":
        return f"Primary-period side table for {core}: period index -> calendar / season.\n\n{head}"
    if suffix == "__units":
        return f"Unit side table for {core}: every unit in the sampling frame, surveyed or not.\n\n{head}"
    if suffix == "__traps":
        return f"Trap side table for {core}: trap index -> coordinates and usage.\n\n{head}"
    body = (f"{s.get('n_rows', '?'):,} rows; {s.get('n_units', '?')} units x {s.get('n_items', '?')} items x "
            f"{s.get('n_periods', '?')} periods x {s.get('n_occasions', '?')} occasions; "
            f"resp values {s.get('resp_values')}. Sample floor: {m.get('sampleFloor')}. "
            f"Built by {m.get('script')} on {m.get('buildDate')}.")
    coarse = m.get("coordinatesCoarsened")
    if isinstance(coarse, dict) and coarse.get("value"):
        body += f" Coordinates coarsened: {coarse.get('method')}."
    return f"{head}\n\n{body}"


def blocked_by_tags() -> dict[str, str]:
    """Core tables whose tags status says not to ship, mapped to the reason."""
    if not TAGS.exists():
        return {}
    out = {}
    with TAGS.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            status = (row.get("status") or "").lower()
            if "do_not_publish" in status or "hold" in status:
                out[row["table"]] = row.get("status", "")
    return out


def ensure_dataset(owner: str, name: str, assume: bool) -> None:
    import redivis
    ds = redivis.organization(owner).dataset(name)
    if ds.exists():
        return
    print(f"\n{owner}.{name} does not exist on Redivis.")
    if not assume and sys.stdin.isatty():
        if input("Create it (private, unreleased)? [y/N] ").strip().lower() != "y":
            raise SystemExit("Cancelled.")
    ds.create(public_access_level="none", description=DATASET_DESCRIPTION)
    print(f"created {owner}.{name} (private)")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("paths", nargs="*", default=[str(OUT)],
                    help="CSV files or directories (default: output/)")
    ap.add_argument("--dataset", default=DATASET)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--yes", "-y", action="store_true")
    ap.add_argument("--no-validate", action="store_true", help="skip irw-validate on core tables")
    ap.add_argument("--allow-hold", action="store_true",
                    help="upload tables whose tags status says do_not_publish / hold")
    args = ap.parse_args(argv)

    csvs: list[Path] = []
    for p in args.paths:
        p = Path(p).expanduser().resolve()
        csvs += [p] if p.is_file() else sorted(p.glob("*.csv"))
    csvs = list(dict.fromkeys(csvs))
    if not csvs:
        print("no CSV files", file=sys.stderr); return 2

    owner, _ = load_registry()          # the owner (datapages) from IRW's config; eco is not a shard

    reports = check_all([(p, p.stem) for p in csvs])
    core = [r for r in reports if side_suffix(r.table) is None]
    side = [r for r in reports if side_suffix(r.table) is not None]
    views = ROOT / ".cache" / "irw_view"
    for r in core:
        missing = [c for c in ("unit", "taxon", "y") if c not in r.columns]
        if missing:
            r.errors.append(f"missing required column(s): {', '.join(missing)}")
            continue
        # IRW's validator wants id/item/resp; run it on the eco_to_irw() view that
        # validate/validate_all.R writes, so the IRW v1.0 check still gates the upload.
        view = views / f"{r.table}.csv"
        if args.no_validate:
            continue
        if not view.exists():
            r.errors.append("no IRW view in .cache/irw_view/ -- run `Rscript validate/validate_all.R` first")
            continue
        errors, warnings = run_validator(view)
        r.errors.extend(errors); r.warnings.extend(warnings)
    blocked = {} if args.allow_hold else blocked_by_tags()
    for r in core:
        meta_p = OUT / f"{r.table}__dataset.json"
        if not meta_p.exists():
            r.errors.append("no __dataset.json"); continue
        m = json.loads(meta_p.read_text())
        ver = str(m.get("standardVersion", ""))
        if not ver.startswith(STANDARD_PREFIX):
            r.errors.append(f"built under `{ver or 'unknown'}`, not {STANDARD_PREFIX}: rerun its data/ script")
        if not m.get("surveyEvidence"):
            r.errors.append("standard E4: surveyEvidence missing from __dataset.json")
    for r in reports:
        base = r.table.split("__")[0]
        if base in blocked:
            r.errors.append(f"tags status is `{blocked[base]}` -- not shipped (pass --allow-hold to override)")
    for r in side:
        key = SIDE_KEYS[side_suffix(r.table)]
        if r.columns and key not in r.columns:
            r.errors.append(f"side table lacks its key column `{key}`")
        if not (OUT / f"{r.table.split('__')[0]}.csv").exists():
            r.errors.append("no core table for this side table")

    print(f"red_up_eco -- {len(reports)} CSV file(s) -> {owner}.{args.dataset}:next\n")
    for r in sorted(reports, key=lambda r: r.table):
        status = "SKIP" if r.errors else ("CORE" if r in core else "SIDE")
        print(f"  {status:<5} {r.table:<40} {r.rows:>8,} rows  {len(r.columns):>3} cols")
        for e in r.errors:
            print(f"        error: {e}")
        for w in r.warnings:
            print(f"        warn:  {w}")
    live = [r for r in reports if not r.errors]
    skipped = [r for r in reports if r.errors]
    if not live:
        print("nothing to upload", file=sys.stderr); return 2
    if args.dry_run:
        print(f"\n--dry-run: {len(live)} table(s) would be uploaded; {len(skipped)} skipped. Nothing written.")
        return 1 if skipped else 0

    authenticate()
    ensure_dataset(owner, args.dataset, args.yes)
    if not args.yes and sys.stdin.isatty():
        if input(f"\nUpload {len(live)} table(s) to {owner}.{args.dataset}:next? [y/N] ").strip().lower() != "y":
            print("Cancelled."); return 0

    dataset = open_draft(owner, args.dataset)
    results = []
    for n, r in enumerate(sorted(live, key=lambda r: r.table), 1):
        print(f"  [{n}/{len(live)}] {r.table}", flush=True)
        res = push_one(dataset, r.path, r.table, r.rows)
        if res.ok:
            desc = describe(r.table)
            if desc:
                try:
                    dataset.table(r.table).update(description=desc[:4000])
                except Exception as exc:     # a description is not worth failing the upload
                    print(f"        description not set: {type(exc).__name__}: {exc}")
        results.append(res)
    failed = [x for x in results if not x.ok]
    print(f"\n{len(results) - len(failed)}/{len(results)} uploaded and row-count verified.")
    for x in failed:
        print(f"  FAILED {x.table}: {x.error}", file=sys.stderr)
    if skipped:
        print(f"{len(skipped)} skipped for errors: {', '.join(r.table for r in skipped)}", file=sys.stderr)
    if not failed:
        print(f"\nDRAFT only: review {owner}.{args.dataset}:next on Redivis and publish by hand.")
    return 1 if (failed or skipped) else 0


if __name__ == "__main__":
    sys.exit(main())
