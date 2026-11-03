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
    id/item/resp. Eco tables are unit/taxon/y, with side tables `__taxa`,
    `__periods`, `__units`, `__traps` (standard.md E6), so the gate here is
    `eco-validate` (eco_validate/ at the repo root: standard.md clauses E1-E10
    plus intake policy), run with `--irw` so irw-validate still checks the IRW
    view of each core table. The eco side tables (`__taxa`, `__periods`,
    `__units`, `__traps`) are real tables that belong beside the core file;
    eco-validate checks them against their core table and they are uploaded here.
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
from red_up.checks import check_all
from red_up.push import open_draft, push_one
from red_up.targets import load_registry

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))            # eco_validate/ lives at the repo root
from eco_validate import validate_file   # noqa: E402
from eco_validate.model import STANDARD_URL   # noqa: E402

OUT = ROOT / "output"
TAGS = ROOT / "tags" / "tags_auto.csv"
DATASET = "eco"


def dataset_description() -> str:
    """The Redivis dataset description, citing the standard version(s) the
    tables in output/ were built under (their __dataset.json standardVersion)."""
    versions = sorted({json.loads(p.read_text())["standardVersion"]
                       for p in OUT.glob("*__dataset.json")})
    return (
        "Ecological detection data (occupancy, repeated counts, capture histories, "
        "community surveys) in an IRW-style long format, one table per deposit: "
        "unit = site or individual, taxon = species code, y = the observation "
        "(detection, count, state, ordinal, multinomial cell, detection event, "
        "binomial count), period + occasion = primary / secondary survey, covariates "
        "prefixed unit_ / period_ / obs_ / taxon_ by the level at which they are "
        "constant. A row exists iff a survey happened; y = 0 is surveyed and not "
        "detected. Each core table <t> has the side table <t>__taxa (scientific name, "
        "GBIF key) and, where relevant, <t>__periods, <t>__units and <t>__traps. "
        f"Standard: {', '.join(versions)}, {STANDARD_URL}. Sources are openly licensed "
        "deposits; each table's description gives its citation and licence.")

#: Which column a side table must carry to be the table its suffix claims.
SIDE_KEYS = {"__taxa": "taxon", "__periods": "period", "__units": "unit", "__traps": "trap"}


def side_suffix(table: str) -> str | None:
    for suffix in SIDE_KEYS:
        if table.endswith(suffix):
            return suffix
    return None


def describe(table: str) -> str | None:
    """Table description from the core table's __dataset.json.

    Keys are indexed, not .get()-ed: a key the standard requires (E10) or the
    pipeline always writes (`summary`, `sampleFloor`, `script`, `buildDate`)
    must exist, so an uploader that has drifted from the format raises KeyError
    at plan time instead of writing `None` to Redivis (#26)."""
    core = table.split("__")[0]
    meta_path = OUT / f"{core}__dataset.json"
    if not meta_path.exists():
        return None
    m = json.loads(meta_path.read_text())
    s = m["summary"]
    rights = m["intellectualRights"]
    spdx = rights["spdx"] if isinstance(rights, dict) else rights
    head = (f"{m['title']}\n\nSource: {m['citation']}\n"
            f"Licence: {spdx}. responseType={m['responseType']}, unitKind={m['unitKind']}, "
            f"surveyEvidence={m['surveyEvidence']}, closure={m['closure']}. "
            f"Standard: {m['standardVersion']}.")
    suffix = side_suffix(table)
    if suffix == "__taxa":
        return f"Taxon side table for {core}: taxon code -> scientificName, GBIF taxonID, traits (taxon_*).\n\n{head}"
    if suffix == "__periods":
        return f"Primary-period side table for {core}: period index -> calendar / season.\n\n{head}"
    if suffix == "__units":
        return f"Unit side table for {core}: every unit in the sampling frame, surveyed or not.\n\n{head}"
    if suffix == "__traps":
        return f"Trap side table for {core}: trap index -> coordinates and usage.\n\n{head}"
    body = (f"{s['n_rows']:,} rows; {s['n_units']:,} units x {s['n_taxa']:,} taxa x "
            f"{s['n_periods']} periods x {s['n_occasions']} occasions; {s['n_surveys']:,} surveys; "
            f"y values {s['y_values']}; {s['prop_zero']:.1%} zeros. Sample floor: {m['sampleFloor']}. "
            f"Built by {m['script']} on {m['buildDate']}.")
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
    ds.create(public_access_level="none", description=dataset_description())
    print(f"created {owner}.{name} (private)")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("paths", nargs="*", default=[str(OUT)],
                    help="CSV files or directories (default: output/)")
    ap.add_argument("--dataset", default=DATASET)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--describe", action="store_true",
                    help="print the dataset description and every table's generated description, then exit (no token needed)")
    ap.add_argument("--yes", "-y", action="store_true")
    ap.add_argument("--no-validate", action="store_true",
                    help="skip eco-validate on core tables (the gate; also skips the IRW view check)")
    ap.add_argument("--no-irw", action="store_true",
                    help="run eco-validate without --irw (no irw-validate on the IRW view)")
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

    if args.describe:
        print(dataset_description(), end="\n\n")
        bad = 0
        for p in csvs:
            print(f"=== {p.stem}")
            try:
                print(describe(p.stem) or "(no __dataset.json)", end="\n\n")
            except KeyError as exc:
                bad += 1
                print(f"ERROR: __dataset.json lacks {exc}\n")
        return 1 if bad else 0

    owner, _ = load_registry()          # the owner (datapages) from IRW's config; eco is not a shard

    reports = check_all([(p, p.stem) for p in csvs])
    core = [r for r in reports if side_suffix(r.table) is None]
    side = [r for r in reports if side_suffix(r.table) is not None]
    for r in core:
        missing = [c for c in ("unit", "taxon", "y") if c not in r.columns]
        if missing:
            r.errors.append(f"missing required column(s): {', '.join(missing)}")
            continue
        if args.no_validate:
            continue
        # The gate: eco-validate over the core table, its side tables and
        # __dataset.json (standard E1-E10, intake policy: standardVersion, name,
        # surveyEvidence), plus irw-validate on the IRW view unless --no-irw.
        try:
            rep = validate_file(r.path, profile="upload", irw=not args.no_irw)
        except Exception as exc:
            r.errors.append(f"eco-validate could not read this table: {exc}")
            continue
        r.errors.extend(f"{f.check}{f' [{f.clause}]' if f.clause else ''}: {f.message}" for f in rep.errors)
        r.warnings.extend(f"{f.check}{f' [{f.clause}]' if f.clause else ''}: {f.message}" for f in rep.warnings)
    # Descriptions are built now, not after each push: a __dataset.json the
    # uploader cannot describe stops that table before anything is written.
    descriptions = {}
    for r in reports:
        try:
            descriptions[r.table] = describe(r.table)
        except KeyError as exc:
            r.errors.append(f"cannot build the Redivis description: __dataset.json lacks {exc}")
    blocked = {} if args.allow_hold else blocked_by_tags()
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
            desc = descriptions[r.table]
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
