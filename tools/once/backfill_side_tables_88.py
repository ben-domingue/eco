#!/usr/bin/env python3
"""One-off (#88): record each table's side tables in its __dataset.json.

write_table() now writes `sideTables` (suffix -> rows, columns, md5) so nothing
has to read a side-table CSV once the CSVs leave git. This adds the same record
to the 192 __dataset.json files built before that change, from the side tables
as they were tracked in git at the commit before #88. The field is inserted as
text before "standardVersion" so the rest of each file is byte-identical.
Run once, from the repo root, on a checkout whose output/ CSVs are the tracked ones.
"""
import csv, glob, hashlib, json, re, sys
from pathlib import Path

OUT = Path("output")
csv.field_size_limit(sys.maxsize)
n = 0
for f in sorted(OUT.glob("*__dataset.json")):
    t = f.name.removesuffix("__dataset.json")
    text = f.read_text()
    if '"sideTables"' in text:
        continue
    side = {}
    for p in sorted(OUT.glob(f"{t}__*.csv")):
        suf = p.name[len(t) + 2:-4]
        if not re.fullmatch(r"[a-z_]+", suf):
            continue
        with open(p, newline="") as h:
            r = csv.reader(h)
            cols = next(r)
            rows = sum(1 for _ in r)
        side[suf] = {"rows": rows, "columns": cols, "md5": hashlib.md5(p.read_bytes()).hexdigest()}
    if not side:
        sys.exit(f"{t}: no side tables found; is this the pre-#88 checkout?")
    lines = ['  "sideTables": {']
    for i, (k, v) in enumerate(side.items()):
        lines += [f'    {json.dumps(k)}: {{',
                  f'      "rows": {v["rows"]},',
                  f'      "columns": {json.dumps(v["columns"], ensure_ascii=False)},',
                  f'      "md5": {json.dumps(v["md5"])}',
                  '    }' + (',' if i < len(side) - 1 else '')]
    lines.append('  },')
    anchor = '\n  "standardVersion"'
    assert text.count(anchor) == 1, t
    text = text.replace(anchor, "\n" + "\n".join(lines) + anchor)
    json.loads(text)
    f.write_text(text)
    n += 1
print(f"sideTables added to {n} __dataset.json files")
