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

Shared code is in `../lib/eco_common.R`; the converters and the R validator twin are in
`../converters/eco_standard.R`. The gate is `eco-validate` (`../eco_validate/`). Run one
script from the repo root (`Rscript data/<table>.R`) or all of them
(`Rscript data/run_all.R`), then `python3 -m eco_validate.cli output/` (or
`Rscript validate/validate_all.R`, which also runs the IRW check and writes the report).

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
| `evans_2021_maine_marten_dynocc.R` | single-species dynamic occupancy, camera traps, 7 seasons | figshare | CC BY 4.0 |
| `tleimat_2023_ecuador_capuchin_occ.R` | single-season occupancy, CR primate, 19 station covariates, no coordinates | figshare | CC BY 4.0 |
| `addis_2026_rmap_amph_dynocc.R` | two tables (`_mbrt_`, `_bt_`): multi-species dynamic occupancy, split by national forest because the species pools differ (E4) | figshare | CC BY 4.0 |
| `kleiven_2020_varanger_dynocc.R` | dynamic co-occurrence occupancy, two functional groups, two spatial scales (`cluster_id` = block), daily occasions | DataverseNO | CC0 |
| `lazenby_2021_tasmania_smallmammal_scr.R` | spatial capture-recapture, two tables (`_swamprat_`, `_ltmouse_`): individual x Elliott trap x night, 4 grids x 6 sessions, `__traps`; first E9 experimental SCR | Dryad (version zip) | CC0 |
| `hamm_2013_satyr_ds.R` | line-transect distance sampling, 1 m bins to 5 m, endangered butterfly; first `distanceBreaks` table | Dryad (version zip) | CC0 |
| `raman_2024_nilgiris_birds_ds.R` | community line-transect distance sampling, 115 bird taxa x 7 bands, sample table, coarsened coordinates | Zenodo | CC0 |
| `smith_2019_greatbasin_csf_edna.R` | two tables (`_edna`: watershed > site > filter sample with covariates; `_qpcr`: site > sample > qPCR replicate with visual/dipnet confirmation); first eDNA multi-scale tables (E9 experimental) | Dryad (version zip) | CC0 |
| `roy_2022_labrador_waterfowl_dobs.R` | dependent double-observer flock counts, 15 waterfowl species x 27 helicopter plots; first `dep_double_observer` table | Dryad (version zip) | CC0 |
| `sullivan_2026_powdermill_count.R` | community counts (N-mixture), 105 bird species, 13 years x 2 visits on a 120 m point grid, built from a DwC event core + occurrence records | GBIF (CMNH IPT, sampling-event DwC-A) | CC BY 4.0 |
| `kyaw_2024_myanmar_mamm_comm.R` | community occupancy, camera traps, 46 taxa in six Myanmar protected areas, per-occasion effort, covariates at five scales | Dryad (version zip, .rar inside) | CC0 |
| `clipp_2024_monongahela_comm.R` | community detection by camera-day, 35 bird and mammal taxa, 129 one-week deployments, effort from deployment table | Zenodo | CC BY 4.0 |
| `clipp_2024_wvprivate_comm.R` | community detection by camera-day, 47 taxa, 146 two-month deployments with coordinates; Wildlife Insights export | Zenodo | CC BY 4.0 on Zenodo, CC BY-NC on the rows; derived CC BY-NC 4.0 |
| `knape_2018_shoveler_count.R` | N-mixture repeated counts, 50 Swedish wetlands x 10 visits, per-visit Julian day, three site covariates (nmixgof::shoveler) | Zenodo | CC BY 4.0 |
| `chabanne_2017_perth_dolphin_msrd.R` | multi-state closed robust design capture-recapture (16 seasons x 3-6 secondary occasions, y = site of capture), photo-id dolphins; first robust-design and first multi-state CR table | Dryad (version zip, MARK .inp) | CC0 |
| `oosthuizen_2019_marion_seal_rd.R` | robust design tag-resight, 1,729 female elephant seals x 28 seal years x 3 capture periods; multievent code in y_raw | Dryad | CC0 |
| `goldingay_2022_richmond_koala_dynocc.R` | single-species dynamic occupancy, spotlight transects, 8 years x 3 surveys, 7 habitat covariates, 2019 drought flagged | Dryad (version zip, UTF-16 text) | CC0 |
| `goldingay_2022_richmond_glider_dynocc.R` | same deposit and design for the central greater glider; separate table because the two species' survey sets differ in 22 cells | Dryad (version zip, UTF-16 text) | CC0 |
| `dettling_2021_marin_riparian_count.R` | N-mixture community counts, 14 riparian landbirds, 183 points x 23 years x 1-3 visits, explicit zeros as deposited | Dryad (version zip) | CC0 |
| `ferguson_2015_macon_bawa_fpocc.R` | multi-state occupancy with false positives (0 / unconfirmed / confirmed per visit), one warbler, 272 sites x 3 visits, coordinates and forest cover | Dryad (version zip) | CC0 |
| `murray_2021_chicago_coyote_mange.R` | multi-state occupancy (disease: 0 / coyote / coyote with mange signs), daily camera-trap observations, 16 seasons x 28 days, per-day image-quality covariates, coordinates | Dryad (version zip) | CC0 |
| `hepler_2018_serengeti_gazelle_occ.R` | single-species camera occupancy, 194 Snapshot Serengeti cameras x 46 calendar-aligned 8-day windows, camera-days of effort, NDVI and rainfall per window, coordinates as published | Dryad (version zip) | CC0 |
| `gardner_2018_nagarahole_tiger_oscr.R` | open-population SCR, 75 photo-identified tigers x 195 camera stations x 10 primary periods (1991-2000), y = capture days per station-period with trap-day effort; first open SCR table (aggregated binomial, pending ruling) | Dryad (version zip) | CC0 |

Batch 2 (2026-11-01) was rebuilt against v1.0-draft and uploaded; batch 3 (2026-11-01) is the six round-trip
textbook datasets routed through `data/` (issue #18), loaded from package data rather than a download; batch 4 (2026-11-01) adds five public-deposit tables; batch 5 (2026-11-01) adds the first SCR and distance-sampling tables; batch 6 (2026-11-01) the first eDNA multi-scale and double-observer tables, built once Ben supplied the two open-access papers in `../queue/papers/`; see `../BATCH_LOG.md`. `aux/` holds lookup tables
shared by scripts (bird alpha codes).
