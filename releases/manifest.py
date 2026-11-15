#!/usr/bin/env python3
"""The eco version manifest: which Redivis version of each dataset was live, when.

Redivis versions each dataset independently -- the core shards `eco`, `eco_2`,
... (redivis_config.py) and `eco_meta` -- so there is no corpus-wide number to
cite. This file writes one down, as `releases/manifest.csv`: one row per eco
version, each a release of one or more core shards, recording the version of
every core shard live at that moment (one `<shard>_redivis_version` column each,
blank before a shard's first release) and the `eco_meta` version that goes with
it. Core releases within SAME_RELEASE of each other are one eco version: Ben
publishes the drafts together and Redivis stamps them a moment apart. A paper cites the integer; the row says what it
was. Modelled on irw's `red_up/manifest.py` (irw#1705), without the shards and
without the overwritten-date detection, which does not apply to a dataset
created after Redivis' 2026-07 migration.

    python3 releases/manifest.py              # refresh: append anything new (incremental)
    python3 releases/manifest.py --check      # is the file up to date? exit 1 if not (incremental)
    python3 releases/manifest.py --full       # rebuild the whole history from Redivis (slow; an audit)
    python3 releases/manifest.py --show 1     # print one eco version

Exit codes: 0 ok - 1 stale or would renumber - 2 bad input. Reads Redivis
anonymously (the datasets are public); nothing here writes to Redivis.

**Incremental by default (2026-11-15).** The rows on disk are trusted: a run
lists each dataset's versions (one cheap call per dataset), checks that the
last row's tags are what Redivis says was live then, and counts tables only
for releases after it, so its cost does not grow with the history. `--full`
recomputes every row, listing the tables of every version of every shard.

**Version numbers are never reused.** A run refuses if the rows already on
disk would change (`--full`: any row; incremental: the last row's tags). The `note` column is the one
hand-edited field and is preserved across runs.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
import redivis_config as rc   # noqa: E402

MANIFEST = ROOT / "releases" / "manifest.csv"
OWNER = rc.OWNER
SAME_RELEASE = dt.timedelta(minutes=5)
#: One version column per core shard, in registry order; eco's is the original
#: `eco_redivis_version`, so the rows written before eco_2 keep their meaning.
CORE_COLUMNS = [d.manifest_column for d in rc.CORE_SHARDS]
COLUMNS = ["eco_version", "date", *CORE_COLUMNS, rc.META.manifest_column, "n_tables", "note"]


def _iso(epoch_ms) -> str:
    return dt.datetime.fromtimestamp(epoch_ms / 1000, dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def released_versions(d: "rc.Dataset", count_after: str | None = "") -> list[dict]:
    """[{tag, released_at, n_tables}] for every released version, oldest first.

    Listing a version's tables is the slow part, so `n_tables` is counted only
    for versions released after `count_after` (the default "" counts all);
    None counts none, and an uncounted version has `n_tables` None."""
    import redivis
    import warnings
    warnings.filterwarnings("ignore", message="No reference id")
    name = d.qualified
    ds = redivis.organization(OWNER).dataset(name)
    if not ds.exists():
        return []
    out = []
    for v in ds.list_versions():
        p = v.properties
        if not p.get("releasedAt"):
            continue
        tag, ts = p["tag"], _iso(p["releasedAt"])
        n = count_tables(d, tag) if count_after is not None and ts > count_after else None
        out.append({"tag": tag, "released_at": ts, "n_tables": n})
    return sorted(out, key=lambda r: r["released_at"])


def count_tables(d: "rc.Dataset", tag: str):
    """Tables in one released version of `d`, or "" when Redivis does not answer."""
    import redivis
    try:
        return len(redivis.organization(OWNER).dataset(f"{d.qualified}:{tag.replace('.', '_')}").list_tables())
    except Exception:
        return ""


def _dt(ts: str) -> dt.datetime:
    return dt.datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ")


def core_events(shards: dict[str, list[dict]], live: dict[str, dict | None] | None = None) -> list[dict]:
    """Merge the core shards' releases into eco versions: [{released_at, tags, n_tables}].

    Releases are taken in time order; one within SAME_RELEASE of the first
    release of the current group joins it. `tags` holds every shard's live tag
    after the group ({column: tag or ""}); `n_tables` sums the live versions.
    `live` seeds what was live before the first of these releases (incremental
    runs: the last row's versions)."""
    flat = sorted(((r["released_at"], col, r) for col, rs in shards.items() for r in rs),
                  key=lambda x: x[0])
    live = {col: (live or {}).get(col) for col in shards}
    events: list[dict] = []
    start = None
    for ts, col, r in flat:
        if start is None or _dt(ts) - _dt(start) > SAME_RELEASE:
            start = ts
            events.append({"released_at": ts})
        live[col] = r
        events[-1]["tags"] = {c: (v["tag"] if v else "") for c, v in live.items()}
        ns = [v["n_tables"] for v in live.values() if v]
        events[-1]["n_tables"] = sum(ns) if all(isinstance(n, int) for n in ns) else ""
    return events


def build(core: list[dict], meta: list[dict], first: int = 1) -> list[dict]:
    # An eco version's metadata is the last eco_meta release before the *next* eco
    # release (the metadata pipeline runs after the tables ship, so eco_meta for
    # version i is released after eco version i). The latest eco version takes the
    # latest eco_meta, so this column can change for that row; diverges() allows it.
    # Ben publishes the two drafts together, and Redivis can stamp eco_meta a moment
    # before eco; an eco_meta release within SAME_RELEASE of the next eco release
    # belongs to that next release, not to this one.
    def _before(ts: str) -> str:
        t = dt.datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ") - SAME_RELEASE
        return t.strftime("%Y-%m-%dT%H:%M:%SZ")
    rows = []
    for i, c in enumerate(core, 1):
        until = _before(core[i]["released_at"]) if i < len(core) else "9999"
        i += first - 1
        live_meta = [m for m in meta if m["released_at"] < until]
        rows.append({"eco_version": str(i), "date": c["released_at"], **c["tags"],
                     rc.META.manifest_column: live_meta[-1]["tag"] if live_meta else "",
                     "n_tables": str(c["n_tables"]), "note": ""})
    return rows


def read() -> list[dict]:
    if not MANIFEST.exists():
        return []
    with MANIFEST.open(newline="", encoding="utf-8") as fh:
        # A shard added since the file was written has no column yet: blank,
        # which is what it was then.
        return [{k: (r.get(k) or "") for k in COLUMNS} for r in csv.DictReader(fh)]


def write(rows: list[dict]) -> None:
    with MANIFEST.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)


def diverges(existing: list[dict], fresh: list[dict]) -> str | None:
    keys = [c for c in COLUMNS if c not in ("note", rc.META.manifest_column)]
    for e, f in zip(existing, fresh):
        for k in keys:
            if e[k] != f[k]:
                return f"eco version {e['eco_version']}: {k} on disk is {e[k]!r}, Redivis says {f[k]!r}"
    if len(fresh) < len(existing):
        return f"{len(existing)} versions on disk, only {len(fresh)} on Redivis"
    return None


def incremental(existing: list[dict]) -> tuple[list[dict], str | None]:
    """The manifest from the rows on disk plus what Redivis released after the last one.

    Rows before the last are taken as written. The last row's tags are checked
    against Redivis' version list (no table listing), its eco_meta column is
    refreshed, and only the releases after it, plus each shard version live
    then, have their tables counted."""
    last = existing[-1]
    cut = (_dt(last["date"]) + SAME_RELEASE).strftime("%Y-%m-%dT%H:%M:%SZ")
    shards = {d.manifest_column: released_versions(d, count_after=cut) for d in rc.CORE_SHARDS}
    by_col = {d.manifest_column: d for d in rc.CORE_SHARDS}
    seed = {}
    for col, vs in shards.items():
        before = [v for v in vs if v["released_at"] <= cut]
        tag = before[-1]["tag"] if before else ""
        if tag != last[col]:
            return [], (f"eco version {last['eco_version']}: {col} on disk is {last[col]!r}, Redivis says {tag!r} "
                        "was live then; run --full to see the whole history")
        seed[col] = before[-1] if before else None
    newer = {col: [v for v in vs if v["released_at"] > cut] for col, vs in shards.items()}
    if any(newer.values()):
        for col, v in seed.items():      # a shard not re-released still counts toward n_tables
            if v is not None:
                v["n_tables"] = count_tables(by_col[col], v["tag"])
    head = {"released_at": last["date"], "tags": {c: last[c] for c in CORE_COLUMNS}, "n_tables": last["n_tables"]}
    events = [head] + core_events(newer, live=seed)
    rows = build(events, released_versions(rc.META, count_after=None), first=int(last["eco_version"]))
    rows[0] = {**last, rc.META.manifest_column: rows[0][rc.META.manifest_column]}
    return existing[:-1] + rows, None


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="exit 1 if the file is stale; write nothing")
    ap.add_argument("--full", action="store_true",
                    help="recompute every row from Redivis (lists the tables of every version: slow)")
    ap.add_argument("--show", type=int, metavar="N", help="print eco version N and exit")
    args = ap.parse_args(argv)

    existing = read()
    if args.show is not None:
        for r in existing:
            if int(r["eco_version"]) == args.show:
                print("\n".join(f"{k}: {r[k]}" for k in COLUMNS)); return 0
        print(f"no eco version {args.show} in {MANIFEST}", file=sys.stderr); return 2

    if args.full or not existing:
        fresh = build(core_events({d.manifest_column: released_versions(d) for d in rc.CORE_SHARDS}),
                      released_versions(rc.META, count_after=None))
        why = diverges(existing, fresh)
    else:
        fresh, why = incremental(existing)
    if why:
        print(f"manifest: refusing to renumber -- {why}", file=sys.stderr); return 1
    for e, f in zip(existing, fresh):
        f["note"] = e["note"]
    new = fresh[len(existing):]
    if args.check:
        changed = [e["eco_version"] for e, f in zip(existing, fresh)
                   if e["eco_meta_redivis_version"] != f["eco_meta_redivis_version"]]
        if changed:
            print(f"manifest: stale, eco_meta version changed for eco version(s) {', '.join(changed)}"); return 1
        if new:
            print(f"manifest: stale, {len(new)} new release(s): "
                  + ", ".join(" + ".join(f"{c.removesuffix('_redivis_version')} {r[c]}" for c in CORE_COLUMNS if r[c])
                              for r in new)); return 1
        print(f"manifest: up to date ({len(existing)} eco version(s))"); return 0
    write(fresh)
    print(f"manifest: {len(fresh)} eco version(s), {len(new)} appended -> {MANIFEST.relative_to(ROOT)}")
    for r in new:
        cores = "  ".join(f"{c.removesuffix('_redivis_version')} {r[c] or '-'}" for c in CORE_COLUMNS)
        print(f"  eco v{r['eco_version']}  {r['date']}  {cores}  eco_meta {r[rc.META.manifest_column] or '-'}  {r['n_tables']} tables")
    return 0


if __name__ == "__main__":
    sys.exit(main())
