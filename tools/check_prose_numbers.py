#!/usr/bin/env python3
"""Numbers in a table's prose that disagree with its computed metadata (issue #28).

A title, description, abstract, designNote or `design` tag is typed by whoever
wrote the data/ script; `n_units`, `n_periods` and `n_taxa` in
metadata/metadata.csv are computed from the table. When the prose says "48
cameras" and the table has 46 units, a reader gets the wrong number. This pulls
every integer that sits just before a unit, period or taxon word ("145 wetland
sites", "26 three-year primary periods", "74 fish species") and lists the ones
that match none of the table's computed counts for that kind.

It is a warning list, not a gate: prose legitimately mentions other numbers
("36 catchments" is a grouping, "of 48 positions" a design total, "7 seasons of
304 days" mixes levels). A number is not flagged when it is followed by "of",
sits in a range ("1-8 sites"), or is followed by "per". Exit 0 always unless
--strict, which exits 1 when anything is flagged.

Text sources, all in the repo: dictionary/dictionary_auto.csv `description`,
tags/tags_auto.csv and tags_human.csv `design`, and from output/<t>__dataset.json
`title`, `abstract`, `designNote` when the core table is present (the four NEON
tables over 100 MB live only on Redivis; their dictionary and tags rows are
still checked).

    python3 tools/check_prose_numbers.py            # every table, flagged lines
    python3 tools/check_prose_numbers.py --strict   # exit 1 if anything flagged
"""
from __future__ import annotations

import argparse
import csv
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
META = ROOT / "metadata" / "metadata.csv"
DICT = ROOT / "dictionary" / "dictionary_auto.csv"
TAGS = [ROOT / "tags" / "tags_auto.csv", ROOT / "tags" / "tags_human.csv"]

# The noun that names the counted thing, mapped to the metadata column(s) it may
# legitimately equal. Units can be individuals or sites; a trap count is also a
# fair reading of "cameras"/"traps" in SCR tables.
KINDS = {
    "units": (r"units?|sites?|cameras?|camera[- ]traps?|ponds?|wetlands?|lakes?|"
              r"streams?|reaches|transects?|plots?|quadrats?|points?|stations?|"
              r"routes?|cells?|watersheds?|individuals?|animals?|grids?|"
              r"segments?|locations?|stops?|squares?|traps?|nests?|islands?",
              ("n_units", "n_traps")),
    "periods": (r"periods?|seasons?|years?|sessions?|surveys? years?|primary periods?",
                ("n_periods",)),
    "taxa": (r"species|taxa|taxon|genera|morphospecies|OTUs?|ASVs?",
             ("n_taxa",)),
}

# Near-misses read and judged correct, with the reason. Key: (table, the phrase as
# printed). Add to this only after reading the sentence; the reason is the record.
EXEMPT = {
    ("murphy_2021_riogrande_otter_scr", "30 individuals"):
        "the conservative matching rule's count; unit is the lenient individual (37)",
    ("tleimat_2023_ecuador_capuchin_occ", "19 station"):
        "19 station covariates, not stations",
    ("kyaw_2024_myanmar_mamm_comm", "47 species"):
        "the paper's count, with the reason the pooled matrix has 46",
    ("curveirasantos_2026_phinda_hyena_scr", "60 cameras placed"):
        "the leopard-design subset of the 100 cameras; near 51 hyenas by coincidence",
    # v1.1: species counts of the source or of the E7.3 sibling table, named as such
    ("peer_2014_bmsil_butterfly_count", "81 species plus"):
        "81 species plus 7 family- or order-level taxa = 88",
    ("barea_2021_sierran_butterfly_exact_count", "102 species"): "the source's count; this sibling omits the flagged taxa",
    ("lafferty_2024_estuaryfish_exact_mb", "17 species"): "the source's count; this sibling omits the flagged taxon",
    ("rich_2016_botswana_mamm_binom", "37 species at"): "the _exact sibling's count",
    ("rich_2016_botswana_mamm_exact_binom", "44 mammal species"): "the source's (and the coarsened table's) count",
    ("rich_2016_botswana_mamm_exact_binom", "44 species with"): "the coarsened sibling's count",
    ("rooney_2025_snapshotusa_comm", "85 species at"): "the _exact sibling's count",
    ("rooney_2025_snapshotusa_exact_comm", "87 species with"): "the coarsened sibling's count",
    ("stallings_2025_gulfreefs_exact_count", "171 resolved taxa"): "the source's count; this sibling omits the flagged taxa",
    ("ke_2022_costarica_birds_nmix", "120 points in"): "the 2016 subset; 150 points from 2017",
    ("ke_2022_costarica_birds_exact_nmix", "120 points in"): "the 2016 subset; 150 points from 2017",
    ("ke_2022_costarica_birds_nmix", "164 species at"): "the _exact sibling's count",
    ("ke_2022_costarica_birds_exact_nmix", "167 species with"): "the coarsened sibling's count",
    ("frishkoff_2014_costarica_birds_binom", "486 species"): "486 species plus 4 genus-only records = 490 taxa",
}

WORDS = {w: i for i, w in enumerate(
    "zero one two three four five six seven eight nine ten eleven twelve thirteen "
    "fourteen fifteen sixteen seventeen eighteen nineteen twenty".split())}

NUM = r"(?P<num>\d{1,3}(?:,\d{3})+|\d+|" + "|".join(WORDS) + r")"
# Up to two modifier words between the number and the noun ("three-year
# primary", "fish", "upper-Midwest"). A function word ends the phrase, so
# "four days of transect searches" is not a count of transects.
STOP = (r"of|in|on|at|the|a|an|and|or|per|were|was|with|from|for|to|by|where|"
        r"which|that|is|are|each|its|their|m|km|cm|ha|days?|nights?|hours?|weeks?")
MOD = r"(?:\s+(?!(?:" + STOP + r")\b)(?:[A-Za-z][A-Za-z\-]*|x|×)){0,2}?"
# A noun followed by one of these is a modifier of something else ("camera
# nights", "point counts", "site visits"), not the counted thing.
COMPOUND = {"nights", "night", "days", "day", "deployments", "deployment", "counts",
            "count", "visits", "visit", "radius", "records", "record", "hours",
            "occasions", "occasion", "searches", "search", "surveys", "survey",
            "walks", "walk", "checks", "trapping", "detections", "photos",
            "images", "later", "earlier", "apart", "old", "long"}


def patterns():
    for kind, (nouns, cols) in KINDS.items():
        rx = re.compile(r"(?<![\w.\-–])" + NUM + MOD + r"\s+(?P<noun>" + nouns + r")\b"
                        r"(?P<after>\s+\w+)?", re.IGNORECASE)
        yield kind, cols, rx


def to_int(s: str) -> int:
    s = s.lower()
    return WORDS[s] if s in WORDS else int(s.replace(",", ""))


def read_rows(path: pathlib.Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def texts_for(table: str, dict_rows: dict, tag_rows: dict) -> list[tuple[str, str]]:
    out = []
    if table in dict_rows:
        out.append(("dictionary.description", dict_rows[table].get("description", "")))
    for t in tag_rows.get(table, []):
        out.append(("tags.design", t.get("design", "")))
    ds = OUT / f"{table}__dataset.json"
    if ds.exists():
        d = json.loads(ds.read_text(encoding="utf-8"))
        for key in ("title", "abstract", "designNote"):
            v = d.get(key)
            if isinstance(v, str):
                out.append((f"dataset.{key}", v))
    return out


def check(table: str, meta: dict, sources) -> list[str]:
    found = []
    for where, text in sources:
        for kind, cols, rx in patterns():
            for m in rx.finditer(text):
                after = (m.group("after") or "").strip().lower()
                if after in ("of", "per") or after in COMPOUND:
                    continue
                n = to_int(m.group("num"))
                if 1800 <= n <= 2100:      # a year, not a count
                    continue
                pre = text[max(0, m.start() - 8):m.start()]
                if re.search(r"\b(up to|of|per|than|to)\s+$", pre, re.IGNORECASE):
                    continue
                # "100 camera sites (99 operated ...)": the parenthesis qualifies the count.
                if re.match(r"(?:\s+[A-Za-z]+)?\s*\(", text[m.end("noun"):]):
                    continue
                if (table, m.group(0).strip()) in EXEMPT:
                    continue
                # n_traps is 1 for a table without traps; that is not a count of anything.
                allowed = {int(float(meta[c])) for c in cols
                           if meta.get(c) not in (None, "", "NA")
                           and not (c == "n_traps" and float(meta[c]) <= 1)}
                if not allowed or n in allowed:
                    continue
                near = any(a >= 5 and abs(n - a) <= 0.2 * a for a in allowed)
                found.append(("NEAR " if near else "     ")
                             + f"{where}: \"{m.group(0).strip()}\" vs "
                             + ", ".join(f"{c}={meta.get(c)}" for c in cols))
    # One line per distinct finding; dictionary and dataset.abstract often repeat.
    return list(dict.fromkeys(found))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--strict", action="store_true", help="exit 1 when any near-miss is flagged")
    ap.add_argument("--all", action="store_true",
                    help="also list numbers far from every count (design totals, mostly)")
    ap.add_argument("tables", nargs="*", help="limit to these tables")
    args = ap.parse_args(argv)

    meta = {r["table"]: r for r in read_rows(META)}
    dict_rows = {r["table"]: r for r in read_rows(DICT)}
    tag_rows: dict[str, list] = {}
    for p in TAGS:
        for r in read_rows(p):
            tag_rows.setdefault(r["table"], []).append(r)

    tables = args.tables or sorted(meta)
    n_near = n_other = 0
    for t in tables:
        if t not in meta:
            print(f"{t}: not in metadata/metadata.csv", file=sys.stderr)
            continue
        hits = check(t, meta[t], texts_for(t, dict_rows, tag_rows))
        near = [h for h in hits if h.startswith("NEAR")]
        other = [h for h in hits if not h.startswith("NEAR")]
        n_near += bool(near)
        n_other += bool(other) and not near
        if near or (args.all and other):
            print(t)
            print("\n".join("  " + h for h in (near + other if args.all else near)))
    print(f"\n{n_near} of {len(tables)} tables have a near-miss (a count within 20% of, "
          f"but not equal to, n_units/n_traps/n_periods/n_taxa); {n_other} more mention "
          f"other counts (--all to list them)", file=sys.stderr)
    return 1 if (args.strict and n_near) else 0


if __name__ == "__main__":
    sys.exit(main())
