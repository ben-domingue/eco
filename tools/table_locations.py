#!/usr/bin/env python3
"""One approximate map point per table, for the homepage map: metadata/table_locations.csv.

Each table gets a single point (not one per site), chosen from the best source
available, in this order:

  1. unit coordinates   decimal latitude/longitude in the core table (unit_,
                        obs_ or period_ prefix) or in __units. The distinct
                        points are read from Redivis with one SQL query per
                        table, never from a local CSV (#88); the point is
                        their mean and the extent the diagonal of their box.
  2. bounding box       geographicCoverage.boundingBox in __dataset.json.
  3. place name         tags/locations_human.csv: a point assigned
                        by hand (agent-drafted, human-reviewed) from the
                        geographicCoverage text, with a precision label.

Projected coordinates (UTM, national grids, local trap grids) are not used:
their CRS is often unstated, so those tables fall to 2 or 3. Every point is
rounded to 0.1 degree, so the map is never finer than the E7 coarsening.

A table already in the output with source "unit coordinates" is not queried
again unless --refresh; so a run after a batch queries only the new tables.
Reading a released table is anonymous; a table only in a draft needs
REDIVIS_API_TOKEN, and without it falls to sources 2 and 3 until the next run.

    python3 tools/table_locations.py             # update metadata/table_locations.csv
    python3 tools/table_locations.py --refresh   # re-query every table
    python3 tools/table_locations.py --offline   # no Redivis; keep cached rows
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
import redivis_config as rc  # noqa: E402

OUT = ROOT / "metadata" / "table_locations.csv"
MANUAL = ROOT / "tags" / "locations_human.csv"
FIELDS = ["table", "lat", "lon", "precision", "extent_km", "n_points", "source", "basis"]
LAT = re.compile(r"^(unit_|obs_|period_)?(decimalLatitude|latitude|lat|cell_lat)$")
warnings.filterwarnings("ignore")


def lat_lon_pairs(cols: list[str]) -> list[tuple[str, str]]:
    """(lat, lon) column pairs: unit_decimalLatitude -> unit_decimalLongitude, unit_lat -> unit_lon."""
    out = []
    for c in cols:
        m = LAT.match(c)
        if not m:
            continue
        stem = c[: len(c) - len(m.group(2))]
        lon = {"decimalLatitude": ["decimalLongitude"], "latitude": ["longitude"],
               "lat": ["lon", "long", "lng"], "cell_lat": ["cell_long", "cell_lon"]}[m.group(2)]
        for l in lon:
            if stem + l in cols:
                out.append((c, stem + l))
                break
    return out


def km(lat1, lon1, lat2, lon2) -> float:
    p = math.pi / 180
    a = (math.sin((lat2 - lat1) * p / 2) ** 2
         + math.cos(lat1 * p) * math.cos(lat2 * p) * math.sin((lon2 - lon1) * p / 2) ** 2)
    return 12742 * math.asin(math.sqrt(min(1, a)))


def precision_for(extent: float) -> str:
    for lim, lab in ((5, "site"), (50, "locality"), (300, "region"), (1000, "state"), (2500, "country")):
        if extent <= lim:
            return lab
    return "multi"


def summarise(pts, source, basis):
    pts = [(a, b) for a, b in pts if a is not None and b is not None
           and not (math.isnan(a) or math.isnan(b)) and -90 <= a <= 90 and -180 <= b <= 180]
    if not pts:
        return None
    la = [p[0] for p in pts]
    lo = [p[1] for p in pts]
    ext = km(min(la), min(lo), max(la), max(lo))
    return {"lat": round(sum(la) / len(la), 1), "lon": round(sum(lo) / len(lo), 1),
            "precision": precision_for(ext), "extent_km": round(ext),
            "n_points": len(pts), "source": source, "basis": basis}


def shard_index():
    """table name -> fully qualified Redivis reference, newest shard first wins."""
    import redivis
    idx = {}
    for shard in rc.CORE_SHARDS:
        for version in ("next", None):
            try:
                ds = redivis.organization(rc.OWNER).dataset(shard.qualified, version=version) if version \
                    else redivis.organization(rc.OWNER).dataset(shard.qualified)
                ds.get()
                ref = f"{rc.OWNER}.{shard.qualified}:{version}" if version else f"{rc.OWNER}.{shard.qualified}"
                for t in ds.list_tables():
                    idx.setdefault(t.name, ref)
                break
            except Exception:
                continue
    return idx


def query_points(ref: str, table: str, pairs) -> list[tuple[float, float]]:
    import redivis
    sel = " UNION DISTINCT ".join(
        f"SELECT DISTINCT CAST({a} AS FLOAT64) AS lat, CAST({b} AS FLOAT64) AS lon FROM `{ref}.{table}` "
        f"WHERE {a} IS NOT NULL AND {b} IS NOT NULL" for a, b in pairs)
    df = redivis.query(sel).to_pandas_dataframe(progress=False)
    return list(zip(df["lat"].astype(float), df["lon"].astype(float)))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args(argv)

    cached = {}
    if OUT.exists() and not args.refresh:
        cached = {r["table"]: r for r in csv.DictReader(OUT.open()) if r["source"] == "unit coordinates"}
    manual = {r["table"]: r for r in csv.DictReader(MANUAL.open())} if MANUAL.exists() else {}
    idx = None
    rows, failed = [], []
    for f in sorted((ROOT / "output").glob("*__dataset.json")):
        d = json.loads(f.read_text())
        t = d["table"]
        cols = [c if isinstance(c, str) else c.get("name") for c in d.get("columns", [])]
        units = (d.get("sideTables") or {}).get("units", {}).get("columns", [])
        row = cached.get(t)
        main_pairs, unit_pairs = lat_lon_pairs(cols), lat_lon_pairs(units)
        if row is None and (main_pairs or unit_pairs) and not args.offline:
            if idx is None:
                idx = shard_index()
            # __units is small, so prefer it; the core table otherwise.
            name, pairs = (f"{t}__units", unit_pairs) if unit_pairs else (t, main_pairs)
            if name in idx:
                try:
                    pts = query_points(idx[name], name, pairs)
                    row = summarise(pts, "unit coordinates", ", ".join(p[0] for p in pairs)
                                    + (" in __units" if unit_pairs else ""))
                except Exception as e:  # noqa: BLE001
                    failed.append(f"{t}: {str(e)[:120]}")
            else:
                failed.append(f"{t}: not found on Redivis")
        if row is None:
            g = d.get("geographicCoverage")
            bb = g.get("boundingBox") if isinstance(g, dict) else None
            if bb:
                row = summarise([(bb["south"], bb["west"]), (bb["north"], bb["east"])],
                                "bounding box", "geographicCoverage.boundingBox")
                if row:
                    row["n_points"] = ""
        if row is None and t in manual and manual[t]["lat"]:
            m = manual[t]
            row = {"lat": round(float(m["lat"]), 1), "lon": round(float(m["lon"]), 1),
                   "precision": m["precision"], "extent_km": m["extent_km"], "n_points": "",
                   "source": "place name", "basis": m["basis"]}
        if row is None:
            row = {"lat": "", "lon": "", "precision": "none", "extent_km": "", "n_points": "",
                   "source": "none", "basis": manual.get(t, {}).get("basis", "no point assigned")}
        row["table"] = t
        rows.append(row)

    with OUT.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    by = {}
    for r in rows:
        by[r["source"]] = by.get(r["source"], 0) + 1
    print(f"table_locations.py: {len(rows)} tables -> {OUT.relative_to(ROOT)}; "
          + ", ".join(f"{k} {v}" for k, v in sorted(by.items())))
    for x in failed:
        print("  fell back:", x)
    for r in rows:
        if r["source"] == "none" and r["table"] not in manual:
            print(f"  no point: {r['table']} (add a row to tags/locations_human.csv)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
