#!/usr/bin/env python3
"""Do redivis_config.py and Rpkg/R/config.R name the same Redivis datasets?

The dataset names and reference ids are declared twice, once per language (the
R package is installed from Rpkg/ and cannot read the repository at run time).
IRW's two copies drifted undetected for months (irw#1733); this compares eco's
on every pull request: the owner, the core shards in order, and eco_meta.

    python3 tools/check_config_parity.py      # exit 0 if they agree, 1 if not
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import redivis_config as rc  # noqa: E402

R_CONFIG = ROOT / "Rpkg" / "R" / "config.R"
PAIR = re.compile(r'list\(\s*name\s*=\s*"([^"]+)"\s*,\s*ref\s*=\s*"([^"]+)"\s*\)')


def read_r(text: str) -> dict:
    text = "\n".join(line.split("#")[0] for line in text.splitlines())   # drop comments
    owner = re.search(r'^\.eco_owner\s*<-\s*"([^"]+)"', text, re.M)
    cores = re.search(r'^\.eco_cores\s*<-\s*list\((.*?)^\)', text, re.M | re.S)
    meta = re.search(r'^\.eco_meta\s*<-\s*(list\([^)]*\))', text, re.M)
    if not (owner and cores and meta):
        raise SystemExit(f"{R_CONFIG.relative_to(ROOT)}: could not find .eco_owner, .eco_cores and .eco_meta")
    return {"owner": owner.group(1), "cores": PAIR.findall(cores.group(1)),
            "meta": PAIR.findall(meta.group(1))[0]}


def main() -> int:
    r = read_r(R_CONFIG.read_text())
    py = {"owner": rc.OWNER, "cores": [(d.name, d.ref) for d in rc.CORE_SHARDS],
          "meta": (rc.META.name, rc.META.ref)}
    bad = [f"{k}: redivis_config.py has {py[k]!r}, Rpkg/R/config.R has {r[k]!r}"
           for k in py if py[k] != r[k]]
    for line in bad:
        print(f"config parity: {line}")
    if bad:
        print("Add a shard in both files, in the same order (redivis_config.py says how).")
        return 1
    print(f"config parity: ok ({len(py['cores'])} core shard(s): {', '.join(n for n, _ in py['cores'])})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
