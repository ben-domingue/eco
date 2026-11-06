#!/usr/bin/env python3
"""Ship output/ to the eco core shards on Redivis (`eco`, `eco_2`, ...) with IRW's uploader, red_up.

    python3 upload/red_up_eco.py --dry-run     # plan only
    python3 upload/red_up_eco.py               # confirm, then upload to the draft
    python3 upload/red_up_eco.py --yes
    python3 upload/red_up_eco.py --dataset eco    # put NEW tables in this shard

Which shard: the core shards are listed in `redivis_config.py` (the rules are
there). Every shard is listed first; a table already on Redivis is updated in
the shard that holds it, a new table and its side tables go to the default
shard (the newest, unless CORE_DEFAULT pins one) or to `--dataset`, and an
upload that would take a shard past 1000 tables is refused before anything is
written. The plan, dry run included, prints each table's shard.

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
  * red_up's targets come from IRW's redivis_config.R, where eco is not and
    should not be registered: eco's shards are separate datasets under the
    same owner, registered in this repo's redivis_config.py.
  * Each table gets its description from output/<table>__dataset.json (title,
    citation, licence, counts), which IRW keeps in a sheet instead.
  * A core must be the build its __dataset.json describes: `coreMd5` (or an
    `md5` per part), recorded by write_table() as it writes the core. A
    gitignored core with no hash, or with a different one, is refused as stale:
    a local copy left over from an older build never ships beside newer side
    tables (#75). A tracked core with no hash is covered by git.
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
import hashlib
import json
import sys
from pathlib import Path

from red_up.auth import authenticate
from red_up.checks import FileReport, check_all, scan
from red_up.push import UploadResult, open_draft, push_one
from red_up.verify import verify

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))            # eco_validate/ and redivis_config.py live at the repo root
import redivis_config as rc   # noqa: E402
sys.path.insert(0, str(ROOT / "upload"))
from placement import place   # noqa: E402
from eco_validate import validate_file   # noqa: E402
sys.path.insert(0, str(ROOT / "validate"))
from report import dataset_meta, report_row, update_report   # noqa: E402
from eco_validate.core import is_parted, part_files, table_name   # noqa: E402
from eco_validate.model import STANDARD_URL   # noqa: E402

OUT = ROOT / "output"
TAGS = ROOT / "tags" / "tags_auto.csv"


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
        "GBIF key) and, where relevant, <t>__periods, <t>__units, <t>__traps and "
        "<t>__survey_taxa. "
        f"Standard: {', '.join(versions)}, {STANDARD_URL}. Sources are openly licensed "
        "deposits; each table's description gives its citation and licence.")

#: Which column a side table must carry to be the table its suffix claims.
SIDE_KEYS = {"__taxa": "taxon", "__periods": "period", "__units": "unit", "__traps": "trap",
             "__survey_taxa": "taxon"}


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
            f"surveyEvidence={m['surveyEvidence']}, closure={m['closure']}, "
            f"occasionKind={' x '.join(m['occasionKind']) if isinstance(m['occasionKind'], list) else m['occasionKind']}, "
            f"taxonInclusion={m['taxonInclusion']}. "
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
    if suffix == "__survey_taxa":
        return (f"Survey-taxa side table for {core}: which taxa were surveyed for at which "
                f"surveys (standard E4.2, E6).\n\n{head}")
    body = (f"{s['n_rows']:,} rows; {s['n_units']:,} units x {s['n_taxa']:,} taxa x "
            f"{s['n_periods']} periods x {s['n_occasions']} occasions; {s['n_surveys']:,} surveys; "
            f"y values {s['y_values']}; {s['prop_zero']:.1%} zeros. Sample floor: {m['sampleFloor']}. "
            f"Built by {m['script']} on {m['buildDate']}.")
    coarse = m.get("coordinatesCoarsened")
    if isinstance(coarse, dict) and coarse.get("value"):
        body += f" Coordinates coarsened: {coarse.get('method')}."
    return f"{head}\n\n{body}"


def md5_file(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def stale_core(path: Path, table: str) -> str | None:
    """Is this core the build its __dataset.json describes? (#75)

    Tables live on Redivis, not in git (#88): a core exists locally only between
    `Rscript data/<table>.R` and this upload, and a copy left over from an older
    build must not ship beside newer side tables. write_table() records `coreMd5`
    (and write_table_parts() an `md5` per part) as it writes the core; a core
    without a hash is refused.
    """
    meta_path = OUT / f"{table}__dataset.json"
    if not meta_path.exists():
        return None                      # the validator reports a missing __dataset.json
    meta = json.loads(meta_path.read_text())
    fix = f"rebuild it with Rscript data/{meta.get('script', '').split('/')[-1] or table + '.R'}"
    if is_parted(path):
        listed = {m.get("file"): m.get("md5") for m in meta.get("parts") or [] if isinstance(m, dict)}
        if any(v is None for v in listed.values()):
            return f"__dataset.json `parts` records no md5, so this local copy cannot be shown to be the current build; {fix}"
        bad = [f for f, want in listed.items() if (path / f).exists() and md5_file(path / f) != want]
        if bad:
            return f"part(s) {', '.join(sorted(bad))} are not the build __dataset.json describes; {fix}"
        return None
    want = meta.get("coreMd5")
    if want is None:
        return f"__dataset.json records no coreMd5, so it cannot be shown to be the current build; {fix}"
    if md5_file(path) != want:
        return f"this core is not the build its __dataset.json describes (coreMd5 differs); {fix}"
    return None


def scan_parts(d: Path) -> FileReport:
    """A table stored as period parts (standard E4): one Redivis table, rows = the sum."""
    name = table_name(d)
    r = FileReport(path=d, table=name)
    parts = part_files(d)
    if not parts:
        r.errors.append("no part-*.csv files in the parts directory")
        return r
    for part in parts:
        pr = scan(part, name)
        if r.columns and pr.columns != r.columns:
            r.errors.append(f"{part.name}: columns differ from {parts[0].name}")
        r.columns = r.columns or pr.columns
        r.rows += pr.rows
        r.errors.extend(f"{part.name}: {e}" for e in pr.errors)
    return r


def push_parts(dataset, d: Path, table_name_: str, expected_rows: int) -> UploadResult:
    """Upload every part of a parted table into ONE table (Redivis uploads append),
    replacing any existing table of that name, then verify count(*) against the sum."""
    result = UploadResult(table=table_name_, dataset=dataset.name, expected=expected_rows)
    try:
        table = dataset.table(table_name_)
        description = None
        if table.exists():
            description = table.get().properties.get("description")
            table.delete()                       # the only true replace (red_up/push.py)
            table = dataset.table(table_name_)
        table = table.create(description=description) if description else table.create()
        try:
            for part in part_files(d):
                print(f"        {part.name}", flush=True)
                with part.open("rb") as handle:
                    table.upload(part.name).create(handle, type="delimited", delimiter=",",
                                                   remove_on_fail=True, wait_for_finish=True, raise_on_fail=True)
        except Exception:
            try:
                table.delete()                   # never leave a partial table in the draft
            except Exception:
                pass
            raise
        ok, actual = verify(table, expected_rows)
        result.actual = actual
        if not ok:
            result.error = f"row count mismatch: uploaded {expected_rows:,} from the parts, count(*) reports {actual:,}"
    except Exception as exc:
        result.error = f"{type(exc).__name__}: {exc}"
    return result


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


def shard_listing(owner: str) -> dict[str, set[str]]:
    """Table names in every core shard, oldest first, as the next upload finds
    them: the open draft, else the latest release. Needs a token (drafts are
    not public). A shard that cannot be read stops the run: placing a table
    without seeing every shard is how a name ends up in two of them."""
    import redivis
    import warnings
    warnings.filterwarnings("ignore", message="No reference id")
    org = redivis.organization(owner)
    out = {}
    for d in rc.CORE_SHARDS:
        try:
            tables = org.dataset(d.qualified, version="next").list_tables()
        except Exception:
            try:
                tables = org.dataset(d.qualified).list_tables()
            except Exception as exc:
                raise RuntimeError(f"cannot list {owner}.{d.name} ({d.ref}): {type(exc).__name__}: {exc}") from exc
        out[d.name] = {t.name for t in tables}
    return out


def ensure_dataset(owner: str, name: str) -> None:
    """Shards are created by Ben on Redivis, never here (redivis_config.py)."""
    import redivis
    if not redivis.organization(owner).dataset(rc.shard(name).qualified).exists():
        raise SystemExit(f"{owner}.{name} is registered in redivis_config.py but does not exist on "
                         "Redivis. Ask Ben to create it (public access level \"data\", like eco).")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("paths", nargs="*", default=[str(OUT)],
                    help="CSV files or directories (default: output/)")
    ap.add_argument("--dataset", default=None, choices=[d.name for d in rc.CORE_SHARDS],
                    help="the shard NEW tables go to (default: redivis_config.default_shard(), "
                         f"now {rc.default_shard().name}); existing tables always stay where they are")
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
    parted: list[Path] = []                   # tables stored as period parts: <name>.parts/
    for p in args.paths:
        p = Path(p).expanduser().resolve()
        if is_parted(p):
            parted.append(p)
        elif p.is_file():
            csvs.append(p)
        else:
            csvs += sorted(p.glob("*.csv"))
            parted += sorted(q for q in p.glob("*.parts") if is_parted(q))
    csvs = list(dict.fromkeys(csvs)); parted = list(dict.fromkeys(parted))
    if not csvs and not parted:
        print("no CSV files", file=sys.stderr); return 2

    if args.describe:
        print(dataset_description(), end="\n\n")
        bad = 0
        for p in csvs + parted:
            print(f"=== {table_name(p)}")
            try:
                print(describe(table_name(p)) or "(no __dataset.json)", end="\n\n")
            except KeyError as exc:
                bad += 1
                print(f"ERROR: __dataset.json lacks {exc}\n")
        return 1 if bad else 0

    owner = rc.OWNER

    reports = check_all([(p, p.stem) for p in csvs])
    for d in parted:
        r = scan_parts(d)
        if any(x.table == r.table for x in reports):
            r.errors.append(f"table name '{r.table}' is claimed by a CSV and a parts directory")
        reports.append(r)
    core = [r for r in reports if side_suffix(r.table) is None]
    side = [r for r in reports if side_suffix(r.table) is not None]
    verdicts: dict[str, dict] = {}   # table -> eco-validate --irw result, for validate/report.csv
    for r in core:
        missing = [c for c in ("unit", "taxon", "y") if c not in r.columns]
        if missing:
            r.errors.append(f"missing required column(s): {', '.join(missing)}")
            continue
        stale = stale_core(r.path, r.table)
        if stale:
            r.errors.append(f"stale core: {stale}")
            continue
        if args.no_validate:
            continue
        # The gate: eco-validate over the core table, its side tables and
        # __dataset.json (standard E1-E10, intake policy: standardVersion, name,
        # surveyEvidence), plus irw-validate on the IRW view unless --no-irw.
        try:
            rep = validate_file(r.path, profile="upload", irw=not args.no_irw)
            if not args.no_irw:
                verdicts[r.table] = rep.to_dict()
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
        # the side table __dataset.json describes (#88): same rule as the core
        base, suf = r.table.split("__", 1)
        mp = OUT / f"{base}__dataset.json"
        rec = (json.loads(mp.read_text()).get("sideTables") or {}).get(suf) if mp.exists() else None
        if rec is None:
            r.errors.append(f"__dataset.json has no sideTables.{suf} record; rebuild the table")
        elif md5_file(r.path) != rec.get("md5"):
            r.errors.append("stale side table: not the build its __dataset.json describes (md5 differs); rebuild the table")
        base = r.table.split('__')[0]
        if not ((OUT / f"{base}.csv").exists() or is_parted(OUT / f"{base}.parts")):
            r.errors.append("no core table for this side table")

    # Which shard each table goes to. Every shard is read first (a token is
    # needed for drafts); a dry run without one says so and places nothing.
    default = args.dataset or rc.default_shard().name
    plan = None
    try:
        authenticate()
        listing = shard_listing(owner)
        plan = place([r.table for r in reports], listing, default=default, forced=args.dataset,
                     cap=rc.TABLE_CAP, warn=rc.TABLE_WARN)
    except (Exception, SystemExit) as exc:
        if not args.dry_run:
            print(f"cannot place tables in shards: {exc}", file=sys.stderr); return 2
        print(f"(shards not read, so no table is placed: {exc})\n")
    if plan:
        for r in reports:
            if r.table in plan.errors:
                r.errors.append(plan.errors[r.table])

    print(f"red_up_eco -- {len(reports)} CSV file(s) -> {owner}: "
          + ", ".join(f"{d.name}:next" for d in rc.CORE_SHARDS) + f" (new tables -> {default})\n")
    for r in sorted(reports, key=lambda r: r.table):
        status = "SKIP" if r.errors else ("CORE" if r in core else "SIDE")
        parts = f"  ({len(part_files(r.path))} parts -> one table)" if is_parted(r.path) else ""
        where = ""
        if plan and r.table in plan.home:
            where = f"  -> {plan.home[r.table]}" + (" (new)" if r.table in plan.new.get(plan.home[r.table], []) else "")
        print(f"  {status:<5} {r.table:<40} {r.rows:>8,} rows  {len(r.columns):>3} cols{where}{parts}")
        for e in r.errors:
            print(f"        error: {e}")
        for w in r.warnings:
            print(f"        warn:  {w}")
    live = [r for r in reports if not r.errors]
    skipped = [r for r in reports if r.errors]
    if plan:
        # Count only what will actually be written: skipped tables add nothing.
        plan = place([r.table for r in live], listing, default=default, forced=args.dataset,
                     cap=rc.TABLE_CAP, warn=rc.TABLE_WARN)
        for s, n in plan.over_warn.items():
            print(f"  warning: {owner}.{s} will hold {n} tables (cap {rc.TABLE_CAP}); the next shard is due "
                  "(redivis_config.py says how to add one)")
        if plan.over_cap:
            for s, n in plan.over_cap.items():
                print(f"  error: {owner}.{s} would hold {n} tables, over Redivis' cap of {rc.TABLE_CAP}. "
                      "Nothing uploaded. Set CORE_DEFAULT / --dataset to another shard, or add one.",
                      file=sys.stderr)
            return 2
    if not live:
        print("nothing to upload", file=sys.stderr); return 2
    if args.dry_run:
        print(f"\n--dry-run: {len(live)} table(s) would be uploaded; {len(skipped)} skipped. Nothing written.")
        return 1 if skipped else 0

    by_shard: dict[str, int] = {}
    for r in live:
        by_shard[plan.home[r.table]] = by_shard.get(plan.home[r.table], 0) + 1
    summary = ", ".join(f"{n} to {owner}.{s}:next" for s, n in by_shard.items())
    for s in by_shard:
        ensure_dataset(owner, s)
    if not args.yes and sys.stdin.isatty():
        if input(f"\nUpload {summary}? [y/N] ").strip().lower() != "y":
            print("Cancelled."); return 0

    drafts = {s: open_draft(owner, rc.shard(s).qualified) for s in by_shard}
    results = []
    order = sorted(live, key=lambda r: (plan.home[r.table], r.table))
    for n, r in enumerate(order, 1):
        dataset = drafts[plan.home[r.table]]
        print(f"  [{n}/{len(live)}] {plan.home[r.table]}.{r.table}", flush=True)
        res = (push_parts(dataset, r.path, r.table, r.rows) if is_parted(r.path)
               else push_one(dataset, r.path, r.table, r.rows))
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
    # The upload gate's verdict is the report row (#88): tables are not in git, so
    # validate/report.csv is written where a table is validated, here and in
    # validate/validate_redivis.py. Commit it with the batch.
    shipped = [x.table for x in results if x.ok and x.table in verdicts]
    if shipped:
        update_report([report_row(verdicts[t], dataset_meta(t)) for t in shipped])
        print(f"validate/report.csv: {len(shipped)} row(s) written from the upload gate")
    for x in failed:
        print(f"  FAILED {x.table}: {x.error}", file=sys.stderr)
    if skipped:
        print(f"{len(skipped)} skipped for errors: {', '.join(r.table for r in skipped)}", file=sys.stderr)
    if not failed:
        print("\nDRAFT only: review " + ", ".join(f"{owner}.{s}:next" for s in by_shard)
              + " on Redivis and publish by hand.")
    return 1 if (failed or skipped) else 0


if __name__ == "__main__":
    sys.exit(main())
