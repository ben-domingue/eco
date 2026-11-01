# data/

One self-contained processing script per source, mirroring `data/` in
`ben-domingue/irw`. Each script downloads its source into `.cache/raw/<table>/`,
reshapes it into the draft standard (`../standard_draft.md`), validates it, and
writes four things:

| Output | Where |
|---|---|
| the clean long-format CSV for upload | `output/<table>.csv` |
| side tables: taxa (`__taxa.csv`), primary periods (`__periods.csv`), units (`__units.csv`) | `output/` |
| dataset metadata (EML / Darwin Core fields, counts, sample-floor status) | `output/<table>__dataset.json` |
| a Data-Dictionary row and a tags row | `dictionary/dictionary_auto.csv`, `tags/tags_auto.csv` |

Shared code is in `../lib/eco_common.R`; the converters and the validator are in
`../converters/eco_standard.R`. Run one script from the repo root
(`Rscript data/<table>.R`) or all of them (`Rscript data/run_all.R`), then
`Rscript validate/validate_all.R`.

## Conventions

- **Header comment** states source, licence, paper, the file layout as deposited,
  the mapping onto the standard, and what was *not* shipped and why. The script
  is the processing record; there is no separate notes file.
- **Assertions, not comments, for facts about the source** (row counts, value
  sets, that the `NA` pattern is identical across species, that effort > 0
  exactly where a survey exists). A re-download that changes the source fails
  loudly.
- **Explicit-zero rule**: a row exists iff a survey happened. `NA` cells in a
  deposited matrix become missing rows, never `y = NA`.
- **Species codes** on `taxon` (short, upper case); the scientific name, GBIF
  taxon key and any traits go to the `__taxa.csv` side table.
- **Period-level facts** (season label, calendar year of a primary period) go to
  `__periods.csv`, not into the core file.
- **Model outputs are not covariates.** A covariate that the authors estimated
  from the same detections (Malhotra's `Dog_occu`) is dropped and the drop is
  logged.
- **Coordinates**: never finer than the source; a 0.1-degree coarsening for
  taxa the source or a red list flags as sensitive (`coarsen_coords()`), with
  `unit_coordinateUncertaintyInMeters` and `dataset.coordinatesCoarsened` set.
- **Table names** follow standard section 10: `author_year_taxonOrPlace_type`,
  lower case, 40 characters or fewer.
- **Dictionary rows** use the exact header of IRW's
  `automated_finding/dictionary_auto.csv`, with `Contributor = automated`, so
  they could be unioned into an IRW-style dictionary unchanged.
- **Record-table sources** (one row per detection, as camera-trap and point-count
  deposits often are) need a survey list to make zeros explicit. Use a deposited
  sample/effort table when there is one (Glorioso); otherwise state the inference
  rule in the header and in `dataset.notes` (Margenau: a point-visit is a survey iff
  it has a row; McTigue: a camera-week is surveyed iff inside the first-to-last
  detection span), set `surveyEvidence` (standard E4) accordingly, and log what
  cannot be recovered.
- **Dryad** deposits are fetched whole with `download_dryad()` (the per-file API
  needs a token; the version zip does not). Check the deposited readme's licence
  against Dryad's CC0 and flag any conflict.

## Tables built so far

| Script | Family | Source | Licence |
|---|---|---|---|
| `malhotra_2021_loslagos_comm.R` | community occupancy, camera traps | Dryad (via Zenodo mirror) | CC0 |
| `schank_2015_tapir_occ.R` | single-season occupancy, coarsened coordinates | Zenodo | CC0 |
| `toledolima_2024_elaenia_cjs.R` | CJS from a MARK `.inp`, losses on capture | Zenodo | CC BY 4.0 |
| `palacio_2020_pampasbirds_comm.R` | multi-season community occupancy with traits | Dryad (via Zenodo mirror) | CC0 |
| `frimpong_2017_newriver_dynocc.R` | multi-species dynamic occupancy, 77 years, effort | Harvard Dataverse | CC0 |
| `uherkoch_2021_npraloon_dynocc.R` | multi-state (breeding status) dynamic occupancy | USGS ScienceBase | CC0 / public domain |
| `hamer_2024_hungary_amph_comm.R` | community occupancy, 9 amphibians x 3 multi-method surveys, 8 survey covariates | Dryad (version zip) | CC0 |
| `galvez_2021_araucania_comm.R` | community occupancy, camera traps, 5 taxa, per-occasion effort | Dryad (version zip) | CC0 on Dryad, ODbL in readme; derived ODbL-1.0 |
| `margenau_2021_rowsongbirds_nmix.R` | N-mixture counts, 112 bird species, manipulative design, built from per-individual records | Dryad (version zip) | CC0 |
| `glorioso_2025_atchafalaya_ves.R` | community counts (N-mixture), 47 herp species, 9 years, coordinates | USGS ScienceBase | CC0 / public domain |
| `glorioso_2025_atchafalaya_calls.R` | ordinal calling index (`responseType = ordinal`), 14 anurans, same surveys | USGS ScienceBase | CC0 / public domain |
| `mctigue_2023_nwarkansas_comm.R` | community occupancy from a camera record table, zeros inferred from operating spans | Dryad (version zip) | CC0 |
| `kery_2008_willowtit_occ.R` | single-season occupancy, textbook (unmarked widewt) | R package (unmarked) | GPL-3 |
| `kery_2005_mallard_count.R` | N-mixture, textbook (unmarked::mallard) | R package (unmarked) | GPL-3 |
| `chandler_2009_alfl_removal.R` | multinomial N-mixture, removal design; first `multinomial_cell` table (E9 declared stretch) | R package (unmarked) | GPL-3 |
| `lebreton_1992_dipper_cjs.R` | CJS, textbook (marked::dipper) | R package (marked) | GPL-2 |
| `kery_2010_crossbill_dynocc.R` | dynamic occupancy, 9 years, textbook (unmarked::crossbill) | R package (unmarked) | GPL-3 |
| `kery_2014_mhb_comm.R` | community counts, 158 species incl. 13 all-zero, textbook (AHMbook::MHB2014) | R package (AHMbook) | GPL-3 |

Batch 2 (2026-11-01) was rebuilt against v1.0-draft and uploaded; batch 3 (2026-11-01) is the six round-trip
textbook datasets routed through `data/` (issue #18), loaded from package data rather than a download; see `../BATCH_LOG.md`. `aux/` holds lookup tables
shared by scripts (bird alpha codes).
