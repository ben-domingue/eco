#!/usr/bin/env python3
"""Assemble report.html from the repo's own files: output/*__dataset.json,
analysis/figures.json, queue/candidates.csv, dictionary/dictionary_auto.csv."""
import csv, json, html
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
fig = json.load(open(ROOT / "analysis/figures.json"))
cand = list(csv.DictReader(open(ROOT / "queue/candidates.csv")))
tables = ["malhotra_2021_loslagos_comm", "schank_2015_tapir_occ", "toledolima_2024_elaenia_cjs",
          "palacio_2020_pampasbirds_comm", "frimpong_2017_newriver_dynocc", "uherkoch_2021_npraloon_dynocc"]
meta = {t: json.load(open(ROOT / f"output/{t}__dataset.json")) for t in tables}
family = {"malhotra_2021_loslagos_comm": "community occupancy, camera traps",
          "schank_2015_tapir_occ": "single-season occupancy, coordinates coarsened",
          "toledolima_2024_elaenia_cjs": "CJS from a MARK .inp, 4 losses on capture",
          "palacio_2020_pampasbirds_comm": "multi-season community occupancy, 19 traits",
          "frimpong_2017_newriver_dynocc": "multi-species dynamic occupancy, 1938 to 2014",
          "uherkoch_2021_npraloon_dynocc": "multi-state (breeding status) dynamic occupancy"}
srcname = {"malhotra_2021_loslagos_comm": "Dryad", "schank_2015_tapir_occ": "Zenodo", "toledolima_2024_elaenia_cjs": "Zenodo",
           "palacio_2020_pampasbirds_comm": "Dryad", "frimpong_2017_newriver_dynocc": "Harvard Dataverse", "uherkoch_2021_npraloon_dynocc": "USGS ScienceBase"}
E = html.escape
rows = ""
tot = 0
for t in tables:
    m = meta[t]; s = m["summary"]; tot += s["n_rows"]
    floor = m["sampleFloor"]
    fl = '<span class="ok">meets</span>' if floor == "meets" else f'<span class="warn">{E(floor)}</span>'
    rows += (f'<tr><td class="mono"><a href="{E(m["sourceURL"])}">{t}</a></td><td>{E(family[t])}</td>'
             f'<td class="num">{s["n_units"]} × {s["n_taxa"]} × {s["n_periods"]} × {s["n_occasions"]}</td>'
             f'<td class="num">{s["n_rows"]:,}</td><td>{E(srcname[t])}, {E(m["intellectualRights"]["spdx"])}</td><td>{fl}</td></tr>\n')
avail = [c for c in cand if c["status"] == "available"]
crow = ""
for c in avail:
    url = c["doi_or_url"]
    href = ("https://doi.org/" + url[4:]) if url.startswith("doi:") else ("https://doi.org/" + url if url[:3] == "10." else url)
    crow += (f'<tr><td class="num">{E(c["difficulty_1to5"])}</td><td><a href="{E(href)}">{E(c["candidate"])}</a></td>'
             f'<td>{E(c["source"])}</td><td>{E(c["data_type"])}</td><td>{E(c["license"])}</td><td class="small">{E(c["notes"])}</td></tr>\n')
data_js = json.dumps({k: fig[k] for k in ["taxa", "est", "fish_effort", "cjs"]}, separators=(",", ":"))
tpl = open(ROOT / "analysis/report_template.html").read()
out = (tpl.replace("{{ROWS}}", rows).replace("{{CANDS}}", crow).replace("{{DATA}}", data_js)
       .replace("{{TOT}}", f"{tot:,}").replace("{{NAVAIL}}", str(len(avail))))
open(ROOT / "report.html", "w").write(out)
print("report.html", len(out), "bytes;", tot, "rows;", len(avail), "candidates")
