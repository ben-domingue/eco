# data/

One self-contained processing script per source, mirroring `data/` in
`ben-domingue/irw`. Each script downloads its source into `.cache/raw/<table>/`,
reshapes it into the standard (`../standard.md`, v1.1-draft), validates it, and
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
(`Rscript data/run_all.R`), then `python3 -m eco_validate.cli output/<table>.csv`.
The CSVs in `output/` are not tracked (#88): commit `__dataset.json`, and ship the
CSVs with `upload/red_up_eco.py`.

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
- **Core tables over 100 MB** (GitHub's file limit) are listed in `.gitignore` and not
  tracked; `Rscript data/<table>.R` rebuilds them and the uploader ships them. Their
  side tables, `__dataset.json`, dictionary, tags and metadata rows are tracked as usual.
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
| `goldingay_2022_richmond_mammals_dynocc.R` | dynamic occupancy, spotlight transects, koala and central greater glider, 8 years x 3 surveys; one table with `__survey_taxa` by survey (v1.1 ruling #31; replaced the koala and glider tables) | Dryad | CC0 |
| `nina_2026_norway_pollinator_count.R` | community counts, 50 m transect sections, bumblebees and butterflies, zeros added per the publisher; builds the coarsened table and its `_exact` sibling (E7.3) | GBIF (NINA IPT) | CC BY 4.0 |
| `fukaya_2022_kasumigaura_fish_mb.R` | community detection, eDNA metabarcoding, three replicate samples per site | Dryad | CC0 |
| `allen_2021_nj_lanternfly_edna.R` | multi-scale eDNA qPCR with a paired visual survey (`obs_method`), plot in vineyard, two rounds | Dryad | CC0 |
| `hastings_2018_seak_sealion_cjs.R` | CJS, resighting histories of pups branded at birth (E4.4) | Dryad | CC0 |
| `dettling_2021_marin_riparian_count.R` | N-mixture community counts, 14 riparian landbirds, 183 points x 23 years x 1-3 visits, explicit zeros as deposited | Dryad (version zip) | CC0 |
| `ferguson_2015_macon_bawa_fpocc.R` | multi-state occupancy with false positives (0 / unconfirmed / confirmed per visit), one warbler, 272 sites x 3 visits, coordinates and forest cover | Dryad (version zip) | CC0 |
| `murray_2021_chicago_coyote_mange.R` | multi-state occupancy (disease: 0 / coyote / coyote with mange signs), daily camera-trap observations, 16 seasons x 28 days, per-day image-quality covariates, coordinates | Dryad (version zip) | CC0 |
| `hepler_2018_serengeti_gazelle_occ.R` | single-species camera occupancy, 194 Snapshot Serengeti cameras x 46 calendar-aligned 8-day windows, camera-days of effort, NDVI and rainfall per window, coordinates as published | Dryad (version zip) | CC0 |
| `gardner_2018_nagarahole_tiger_oscr.R` | open-population SCR, 75 photo-identified tigers x 195 camera stations x 10 primary periods (1991-2000), y = capture days per station-period with trap-day effort; first open SCR table; `binomial_count` under ruling #34 | Dryad (version zip) | CC0 |
| `distiller_2020_cockscomb_jaguar_scr.R` | closed-population SCR, 29 photo-identified jaguars x 20 camera stations x 183 daily occasions with per-row dates and photograph times; station x day operating matrix as the survey set | Dryad (version zip) | CC0 |
| `bison_2024_montblanc_hare_dynocc.R` | single-species seasonal occupancy, daily camera-trap detections, 46 stations x 20 meteorological seasons (2017-2022), survey set from setup dates minus downtime windows, coordinates and vegetation-cover classes | Dryad (version zip) | CC0 |
| `rich_2016_botswana_mamm_binom.R` | community camera-trap survey as binomial counts (nights detected out of nights surveyed), 44 mammals x 221 stations, diet and body-size traits in __taxa, coordinates coarsened (EN/VU taxa); first binomial_count table (ruling #34) | Dryad (version zip) | CC0 |
| `feng_2021_nechina_mamm_binom.R` | community camera-trap detections collapsed to 14-day windows with a detection out of windows surveyed (`binomial_count`, ruling #34), 18 mammals x 138 stations, 12 site covariates | Dryad (version zip) | CC0 |
| `bhattacharya_2022_himachal_bear_occ.R` | single-species camera occupancy, 67 cameras in two Himachal Pradesh sanctuaries (2018, 2019) x up to 49 camera-days, camera-relative occasions, no coordinates (VU taxon) | Dryad (version zip, xlsx) | CC0 |
| `burgar_2018_alberta_fisher_scr.R` | closed-population genetic SCR (hair snags), 24 fishers x 64 sites x 4 occasions, TDF usage as survey set, UTM coordinates in __traps | Dryad (version zip) | CC0 |
| `burgar_2018_alberta_fisher_count.R` | single-species camera detections, 64 sites x 64 occasions, complete 0/1 matrix; the unmarked half of the same study, not joinable to the SCR sites | Dryad (version zip) | CC0 |
| `koetke_2024_jprf_moose_count.R` | N-mixture daily camera-trap counts, one species, 72 cameras x 91 winter days with per-row dates; three detection-independence criteria deposited (5 min as y, 30 min and 8 h alongside) | Dryad (version zip, xlsx) | CC0 |
| `jhala_2024_india_tiger_binom.R` | multi-season tiger sign-survey occupancy as binomial counts (replicates with sign out of replicates surveyed), 7,183 100 km2 cells x 4 All-India cycles 2006-2018, standardised static and cycle covariates; no coordinates | Zenodo | CC BY 4.0 |
| `khelifa_2021_seybouse_calexul_cjs.R` | CJS capture histories, 313 wing-marked adult damselflies (IUCN EN) x 25 daily occasions, sex and daily water depth as covariates | Dryad (version zip, xlsx) | CC0 |
| `blount_2025_neturkiye_carniv_count.R` | N-mixture community counts, grey wolf and brown bear, 229 camera deployments (2009-2023) x up to 104 seven-day occasions, 20 deployment covariates, exact coordinates | Zenodo (xlsx) | CC BY 4.0 |
| `blount_2025_neturkiye_lynx_occ.R` | single-species camera occupancy, Eurasian lynx 0/1 on the same deployments and weeks; the lynx count matrix in the deposit cannot be aligned | Zenodo (xlsx) | CC BY 4.0 |
| `hollanders_2022_brindle_mfleayi_msdis.R` | disease-structured multi-state robust-design capture histories, 116 juvenile frogs (IUCN EN) x 8 primary x 2 weekly secondaries, infection state from Bd qPCR per capture, run-level summaries as obs_ covariates | Dryad (version zip) | CC0 |
| `obrist_2024_gooseisland_birds_count.R` | **withdrawn 2026-11-06 (#150, care_review); not shipped.** N-mixture community counts, 50 bird species x 50 points x 3 surveys (2011) in four habitat types on six BC islands, built from per-detection records under the authors' own minute-and-distance rule; coordinates, weather, observer | Zenodo (xlsx) | CC BY 4.0 |
| `murphy_2021_riogrande_otter_scr.R` | closed-population genetic SCR (scat genotyping at latrines), 37 river otters x 20 latrines x 8 occasions, usage string as survey set, UTM latrine coordinates in __traps; conservative individual id as unit covariate | Dryad (version zip, xlsx) | CC0 |
| `valenzuela_2018_neltume_rhidar_rd.R` | robust-design search-encounter capture histories, 311 Darwin's frogs (IUCN EN) x 9 visited quarterly primaries x 4 capture days, plot-local capture coordinates and SVL on capture rows for a spatial CJS | Zenodo (txt) | CC BY-SA 4.0 (derived CC BY-SA 4.0) |
| `whittington_2015_banff_tracks_comm.R` | multi-scale community occupancy from snow-track surveys, 7 mammals x 443 one-km segments nested in 39 hexagonal cells, 1-14 repeat walks, days since snowfall per survey, segment coordinates | Dryad (version zip) | CC0 |
| `henry_2020_karoo_birds_comm.R` | community occupancy from point counts, 63 bird species x 61 Karoo pentads x 10-20 counts (2017), time to first detection, distance and detection mode per species-count as obs_ covariates, count weather and GPS | Dryad (version zip, xlsx) | CC0 |
| `riecke_2018_tutakoke_brant_rd.R` | robust-design capture histories, 7,845 female black brant x 27 breeding seasons (1988-2014) x 3 capture methods (nest, tower, banding), banding year and age class, gosling tarsus for 713 | Dryad (version zip, RData) | CC0 |
| `bedson_2021_holmemoss_hare_vis_ds.R` | line-transect distance sampling, mountain hare, one walk per 1 km site (6 walks), hare groups in five perpendicular-distance bins; method-comparison deposit, sibling of the thermal and camera tables | Dryad (version zip) | CC0 |
| `bedson_2021_holmemoss_hare_therm_ds.R` | point-transect distance sampling by thermal imager, 71 vantage points x 1-3 visits (114), hare groups in eight radial-distance bins; visits recovered from row order and asserted against the paper | Dryad (version zip) | CC0 |
| `bedson_2021_holmemoss_hare_cam_ds.R` | camera-trap distance sampling (1 s snapshots, 42 degree field of view), 91 cameras, snapshot detections in twelve 1 m radial bins, seconds deployed as effort; first CTDS table | Dryad (version zip) | CC0 |
| `volzke_2021_macquarie_seal_cjs.R` | two CJS tables: resighting histories of 7,531 (1951-1965 cohorts) and 18,371 (1984-2005 cohorts) southern elephant seals marked as weaned pups, seal years x breeding / rest-of-year windows, survey set inferred from the sightings | Dryad (version zip) | CC0 |
| `lebeuftaylor_2026_boreal_edges_aru_comm.R` | community occupancy from ARU recordings, 34 boreal songbirds x 564 recorder locations (3 positions across 189 harvest edges) x 1-5 visits, years since harvest and spruce cover per side, coordinates; year not deposited | Borealis Dataverse (rds Stan input) | CC0 |
| `rooney_2025_snapshotusa_comm.R` | community camera-trap detections by camera-week, 87 mammal species x 9,694 deployments in 263 arrays across the USA, autumn 2019-2023, camera-days per week as effort, coordinates coarsened (CR/EN taxa); built from Dryad version 3 (v6 needs a token); core CSV not tracked (548 MB) | Dryad (version zip) | CC0 |
| `lindstrom_2025_sweden_summerpoints_count.R` | annual route-total counts, 270 bird taxa x 1,256 Swedish Bird Survey summer point count routes (20 points summed) x 50 years 1975-2024, observer, date-time, transport, county, 25 km grid-square centres; built from the GBIF DwC event core; core CSV not tracked (348 MB) | GBIF (Swedish GBIF IPT, Lund University) | CC0 |
| `doser_2022_hbef_trends_dynocc.R` | dynamic community occupancy, textbook (spOccupancy::hbefTrends), 12 foliage-gleaning songbirds x 373 Hubbard Brook plots x 9 years x up to 3 point counts, elevation, coordinates, survey day and time; hbef2015 is its 2015 slice | R package (spOccupancy, via GitHub source) | GPL-3 |
| `doser_2022_neon2015_removal.R` | time-removal community detections, textbook (spOccupancy::neon2015), 12 species x 80 NEON Bartlett sites x three 2-minute intervals of one count, multinomial_cell / removal; two all-zero taxa | R package (spOccupancy, via GitHub source) | GPL-3 |
| `curveirasantos_2026_phinda_carniv_scr.R` | six closed-population camera-trap SCR tables (leopard, cheetah, lion, spotted hyaena, genet, serval), 100 optimised camera sites x 117 daily occasions in the Munywana Conservancy, South Africa, 2021-22; operation matrix as survey set; trap coordinates centred on the array (VU taxa) | OSF (osfstorage csv) | CC BY 4.0 |
| `neon_2026_landbirds_count.R` | repeated six-minute point counts, 283 bird species x 3,434 NEON points (47 sites) x 2 bouts x 2013-2024, observer, weather, NLCD class, coordinates as published; core CSV not tracked (583 MB) | NEON DP1.10003.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_landbirds_ds.R` | binned distance sampling (four radial bins), 46 common bird species at the same counts, multinomial_cell; core CSV not tracked (433 MB) | NEON DP1.10003.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_smallmammals_count.R` | robust-design nightly counts of individuals, 143 small-mammal species x 332 NEON trapping grids x 1,612 bouts, traps set as effort; core CSV not tracked (304 MB) | NEON DP1.10072.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_smallmammals_rd.R` | nine single-species robust-design capture histories (Peromyscus maniculatus, P. leucopus, Sigmodon hispidus, Microtus pennsylvanicus; Myodes rutilus, M. gapperi, Napaeozapus insignis, Dipodomys merriami, Peromyscus gossypinus added in batch 58), individuals x bouts x nights at the home grid | NEON DP1.10072.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_carabids_count.R` | biweekly pitfall counts, 55 carabid species x 2,029 NEON traps x 2013-2023, trapping days as effort; core CSV not tracked (354 MB) | NEON DP1.10022.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_fish_removal.R` | three-pass electrofishing removal (one pass at random reaches), 155 fish taxa x 223 NEON wadeable-stream reaches (23 sites) x 278 bouts, 2016-2024, multinomial_cell / removal; estimated bulk counts kept with obs_count_estimated (ruling 17), net-compromised bouts dropped | NEON DP1.20107.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_ticks_count.R` | drag / flag counts per plot-bout, 28 tick species x life-stage taxa x 287 NEON plots (46 sites), 2019-2024, area sampled as effort; larval counts in whole thousands flagged obs_count_likely_estimated (ruling 18) | NEON DP1.10093.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_mosquitoes_count.R` | CO2 light-trap collections, identified-subsample counts of 77 mosquito taxa x 518 NEON plots (47 sites), 2014-2024, trap hours and proportion identified (subsampleColumn); year parts (7.5M rows), not tracked | NEON DP1.10043.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_plants_occ.R` | plant presence per visit to permanent 1 m2 subplots, 4,980 plant taxa x 12,622 subplots in 1,598 plots (47 sites) x 12 years (2013-2025), 1-2 visits a year, percent cover; per-site species pools in __survey_taxa (ruling 19); year parts, not tracked | NEON DP1.10058.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_macroinverts_count.R` | benthic macroinvertebrate counts per sample (about 8 samples per bout, 3 bouts a year), 1,229 taxa x 24 NEON wadeable-stream sites x 539 bouts, 2014-2024, habitat, sampler, area as effort and the fraction counted (subsampleColumn); year parts, not tracked | NEON DP1.20120.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `tetzlaff_2026_crotalus_cjs.R` | CJS histories, 707 adult female timber rattlesnakes, New York, 1983-2019, den group, annual covariates | Dryad | CC0 |
| `gelle_2026_mauritius_parakeet_ms.R` | multi-state CJS, 2,734 echo parakeets ringed as nestlings, Mauritius, 1994-2022 | Dryad | CC0 |
| `cubaynes_2021_svalbard_polarbear_ms.R` | multievent capture-recapture, 158 female polar bear family units, Svalbard, 1992-2019 | Dryad | CC0 |
| `moinet_2024_nz_mouse_scr.R` | SCR with a removal phase, house mice on two Longworth grids, New Zealand | Dryad | CC0 |
| `broekhuis_2020_mara_cheetah_scr.R` | search-encounter SCR (pixel x day traps, km driven), cheetahs, Maasai Mara; E9 search-encounter ruling (2026-11-05) | Dryad | CC0 |
| `todaro_2025_wyoming_shrike_dynocc.R` | dynamic occupancy, loggerhead shrike point counts, Wyoming, 2015-2024 | Dryad | CC0 |
| `betancur_2021_antioquia_birds_count.R` | two-species repeated counts, endemic Andean birds, Colombia, coarsened coordinates | Dryad | CC0 |
| `hamer_2021_kooragang_amph_comm.R` | multi-season community occupancy, 11 frog species x 55 wetlands, Kooragang Island NSW, 2000-2002 | Dryad | CC0 |
| `tsuboi_2020_japan_charr_ms.R` | multi-state CJS (age x stream location), 1,373 white-spotted charr, Japanese headwater network, 2009-2017 | Dryad | CC0 |
| `tsuboi_2020_japan_masu_ms.R` | multi-state CJS (age x stream location), 1,335 red-spotted masu salmon, same surveys as the charr | Dryad | CC0 |
| `cumming_2021_ngami_waterbird_count.R` | repeated community point counts, 182 bird species x 14 points x 6 trips, Lake Ngami, Botswana, coarsened | Dryad | CC0 |
| `prabowo_2016_jambi_birds_count.R` | repeated community point counts, 71 bird species x 32 land-use plots, Jambi, Sumatra, 2013 | Dryad | CC0 |
| `raman_2003_kalakad_birds_count.R` | repeated line-transect counts, 60 rainforest bird taxa x 12 transects, Western Ghats, 1997-1999, coarsened | Dryad | CC0 |
| `cecala_2026_kiawah_terrapin_cjs.R` | annual CJS histories, 1,553 diamondback terrapins, Kiawah River SC, 1983-2012, sex and size | Dryad | CC0 |
| `karvemo_2024_nacka_grasssnake_cjs.R` | annual CJS histories, 1,113 grass snakes, Nacka, Sweden, 66 years, snow cover | Dryad | CC0 |
| `doyle_2025_chinalake_tortoise_scr.R` | search-track SCR, 24 Mojave desert tortoises x 548 cells x 4 days, detectors centred (CR) | Dryad | CC0 |
| `ahizi_2021_civ_crocodylians_occ.R` | spotlight occupancy, 2 crocodylian taxa x 42 sites x 5 nights, Ivory Coast | Dryad | CC0 |
| `yadav_2022_rapti_gharial_count.R` | repeated counts, gharial x 18 river segments x 3 counts, Chitwan | Dryad | CC0 |
| `moe_2020_hunder_trout_ld.R` | live-dead (Burnham) state-coded histories, 13,975 Hunder brown trout, 1966-2015 | Dryad | CC0 |
| `banik_2025_dollyvarden_ms.R` | **withdrawn 2026-11-06 (#150, care_review); not shipped.** multistate CR, 21,430 anadromous Dolly Varden, five Yukon rivers, 14 autumns | Dryad | CC0 |
| `tomke_2025_hellbender_edna.R` | multi-scale eDNA occupancy, Eastern Hellbender, 385 filters at 90 sites | Dryad | CC0 |
| `swedberg_2023_springfish_occ.R` | multi-scale community occupancy, six spring-associated fishes x 153 sites, Oklahoma | Dryad | CC0 |
| `kanno_2022_indiancreek_fish_cjs.R` | three CJS tables (bluehead chub, creek chub, mottled sculpin), 2-month occasions | Dryad | CC0 |
| `lafferty_2024_socal_estuary_edna.R` | two tables: tidewater goby qPCR + metabarcoding detections, and 17-species estuarine metabarcoding, southern California | Dryad | CC0 |
| `hartley_2024_cpraealtus_occ.R` | dynamic occupancy, alpine she-oak skink x 113 transects x 4 seasons | Dryad | CC0 |
| `smith_2024_florida_tegu_dynocc.R` | dynamic camera occupancy, Argentine tegu x 87 cameras x 4 years | Dryad | CC0 |
| `samek_2024_racerunner_occ.R` | single-season occupancy, six-lined racerunner x 100 transects x 3 surveys | Dryad | CC0 |
| `boone_2023_minnesota_bombus_count.R` | community counts, 15 Bombus classes x 25 sites x 5 surveys, Minnesota 2021, coordinates coarsened | Dryad | CC0 |
| `chambert_2018_plethodon_fpocc.R` | two-species occupancy with misidentification, Plethodon salamanders x 131 sites x 4 years | Dryad | CC0 |
| `teitsworth_2026_necturus_dynocc.R` | dynamic occupancy, Neuse River waterdog x 176 sites x 5 years | Dryad | CC0 |
| `price_2018_mtr_salamanders_count.R` | dynamic counts, 7 stream salamander species-stage items x 23 reaches x 3 years | Dryad | CC0 |
| `tumursukh_2016_tost_ungulates_dobs.R` | two double-observer tables (Siberian ibex, argali), groups as units, Tost, Mongolia | Dryad | CC0 |
| `davis_2016_feralswine_removal.R` | three-pass aerial removal, feral swine x 49 properties x 9 years | Dryad | CC0 |
| `dougherty_2016_rustycrayfish_edna.R` | qPCR replicates plus baited trap, rusty crayfish x 261 locations in 12 lakes | Dryad | CC0 |
| `ziolkowski_2026_bbs.R` | North American Breeding Bird Survey, 3 tables from one script: national run totals of all 764 taxa at every run (110.1 M rows, 1966-2025, stored as period parts, standard E4), plus 10-stop blocks and stops for BCR 15; cores not tracked | USGS ScienceBase | CC0 |
| `sandercock_2022_norway_alien.R` | community occupancy (plants, two botanists) + multi-scale eDNA (insects) | Dryad | CC0 |
| `armstrong_2024_hydrilla_dynocc.R` | dynamic occupancy (plant) | Dryad | CC0 |
| `martinezvillegas_2024_plants_cjs.R` | CJS, five marked plant species | Dryad | CC0 |
| `deprengerlevin_2024_astragalus_cmr.R` | multistate robust design + multistate CJS (plant, dormancy) | Dryad | CC0 |
| `schleimer_2019_gsl_finwhale_cjs.R` | CJS, photo-ID | Dryad | CC0 |
| `ancona_2016_isabel_booby_cjs.R` | CJS | Dryad | CC0 |
| `dezeeuw_2024_nl_waterbeetle_nmix.R` | community repeated counts (water beetles) | Dryad | CC0 |
| `inbo_2026_flanders_dragonfly_count.R` | repeated counts, three target dragonflies, one table with `__survey_taxa` by unit (v1.1 ruling #31; replaced three per-species tables) | GBIF (INBO) | CC0 |
| `hinneberg_2022_limenitis_ccr.R` | closed-population capture-recapture, occasion = surveyor (first of its family) | Dryad | CC0 |
| `leith_2022_africanpenguin_ms.R` | multistate CJS, breeder / non-breeder, PIT resightings | Dryad | CC0 |
| `bruce_2021_wisconsin_monarch_nmix.R` | N-mixture repeated counts (monarch adults) | ScienceBase (USGS) | public domain |
| `leone_2019_minnesota_monarch_nmix.R` | N-mixture repeated counts (monarch adults) | ScienceBase (USGS) | public domain |
| `stallings_2025_gulfreefs_count.R` | community repeated counts, reef fish diver counts, coarsened coordinates | Zenodo | CC BY 4.0 |
| `vanklink_2025_wijster_carabid_count.R` | community pitfall counts, trap x collection, with effort | GBIF (NLBIF) | CC0 |
| `arsocivil_2019_scotland_dolphin_rd.R` | robust design capture-recapture, photo-ID, sex as unit covariate | Dryad | CC0 |
| `arsocivil_2019_scotland_dolphincalf_cjs.R` | CJS, photo-ID calves | Dryad | CC0 |
| `cleavitt_2017_hbef_plamac_ms.R` | multistate CJS, marked orchids, lost flags censor | DataONE (LTER) | CC BY 4.0 |
| `cleavitt_2017_hbef_plaorb_ms.R` | multistate CJS, marked orchids (sibling) | DataONE (LTER) | CC BY 4.0 |
| `work_2026_ocala_odonates_comm.R` | community occupancy, adult odonates by aerial net, coarsened coordinates | Dataverse | CC0 |
| `work_2026_ocala_odonatenymphs_count.R` | community counts, odonate nymphs by dipnet (sibling) | Dataverse | CC0 |
| `peer_2014_bmsil_butterfly_count.R` | Pollard-walk community counts, sections summed to the walk | GBIF | CC0 |
| `barea_2021_sierranevada_butterfly_count.R` | Pollard-walk community counts, coarsened coordinates | GBIF | CC BY 4.0 |
| `peters_2026_carabid_count.R` | community counts: pitfalls and emergence tents, two tables | Zenodo | CC BY 4.0 |
| `curtis_2021_sannicolas_ziphius_cjs.R` | CJS with partial identity (one-sided photo-ID, multimark codes), vessel effort | Dryad | CC0 |
| `mcknight_2019_kittiwake_ms.R` | multistate CR, two analysis sets (fledglings, recruits), two tables | Dryad | CC0 |
| `koester_2023_aldabra_reeffish_count.R` | community counts, reef fish UVC belt transects, two methods, two tables, inferred survey set | figshare | CC BY 4.0 |
| `bradferlawrence_2025_ukwood_comm.R` | community occupancy, four taxa groups in UK woods (beetles, birds, mammals, plants), four tables | Zenodo | CC BY 4.0 |
| `nowicki_2019_sharkbay_count.R` | repeated boat-transect counts, marine megafauna, three tables by per-taxon survey set | Dryad | CC0 |
| `symons_2018_bunbury_dolphin.R` | robust design photo-ID, plus female/calf multistate robust design | Dryad | CC0 |
| `fabritius_2015_fritillary_cjs.R` | CJS from daily MRR with searched-area effort, three populations | Dryad | CC0 |
| `maihoff_2023_berchtesgaden_bees_count.R` | community counts, wild bee transect walks, 2009 vs 2019 | Dryad | CC0 |
| `johnson_2023_tweedsmuir_bombus_count.R` | **withdrawn 2026-11-06 (#150, care_review); not shipped.** community counts, bumble bee vane traps, postfire | Dryad | CC0 |
| `ke_2022_costarica_birds_nmix.R` | community counts, repeated point counts, coarsened + `_exact` sibling | Dryad | CC0 |
| `frishkoff_2014_costarica_birds_binom.R` | binomial counts, bird transects x season, 12 years | Dryad | CC0 |
| `frank_2017_costarica_bats_comm.R` | community detection, bat mist nets, from a JAGS array | Dryad | CC0 |
| `olimpi_2024_calfarms_nmix.R` | community counts, repeated point counts on farms, flyovers excluded | Dryad | CC0 |
| `ruff_2025_piwo_state.R` | multi-state occupancy, acoustic (ARU + classifier), weekly effort | Zenodo | CC BY 4.0 |
| `malachowski_2026_koloa_rd.R` | robust design from a MARK `.inp`, untrapped primaries | Zenodo | CC BY 4.0 |
| `dutta_2024_panna_carnivore_occ.R` | multispecies detection, camera traps, 5-night sessions, two seasons (stations not linked) | Dryad | CC0 |
| `neubauer_2021_bialowieza_marshtit_nmix.R` | repeated counts, 33 years x 6 counts on 4 plots, census truth as `period_` covariates | Dryad | CC0 |
| `law_2021_nsw_koala_occ.R` | single-species detection, acoustic (AudioMoth), nightly occasions | Dryad | CC0 |
| `mills_2019_kibale_carnivore_comm.R` | community detection, camera traps, daily occasions from a station-day function table, coarsened | Dryad | CC0 |
| `dooley_2025_agapostemon_cjs.R` | CJS, bee mark-resight at flower patches, histories rebuilt from raw captures | Dryad | CC0 |
| `leipold_2025_duskygrouse_roads_count.R` | repeated counts, playback point counts, 2 years x 4 counts | Dryad | CC0 |
| `leipold_2025_duskygrouse_offtrail_count.R` | repeated counts, visit x playback treatment occasions | Dryad | CC0 |
| `ruppel_2025_richmond_pollinator_comm.R` | community detection, pollinator flower watches, plant x inflorescence occasions | Dryad | CC0 |
| `martel_2020_tidewatergoby_edna.R` | multi-scale eDNA (site, water sample, qPCR replicate), two seasons, coarsened | Dryad | CC0 |
| `battaile_2023_sacramento_sturgeon_count.R` | repeated counts, side scan sonar passes, fish, 3 years | Dryad (UCSC) | CC0 |
| `proudman_2026_illinois_coyote_count.R` | repeated counts, camera detections per week, 3 winters | Dryad | CC0 |
| `twining_2024_adirondack_carniv_occ.R` | multi-species detection, baited cameras, 3 winters x 3 weeks | Dryad | CC0 |
| `parren_2021_centralvalley_mesocarn_occ.R` | multi-species detection, baited cameras, daily occasions | Dryad | CC0 |
| `parren_2021_mojave_mesocarn_occ.R` | multi-species detection, baited cameras, 3-day occasions | Dryad | CC0 |
| `goldingay_2026_diamondhill_nestbox_occ.R` | multi-species detection, nest-box censuses, 12 periods | Dryad | CC0 |
| `neateclegg_2018_cusuco_birds_count.R` | community counts, point-count transects, 10 years x 1-7 surveys, Honduras | Dryad | CC0 |
| `cayuela_2020_bombina_cjs.R` | CJS, annual toad histories, four populations stacked (cluster_id), birth year | Dryad | CC0 |
| `fouchet_2016_kerguelen_cat_cjs.R` | CJS, feral cat captures pooled to dated trapping sessions from a session table | Dryad | CC0 |
| `ludwig_2026_lusatia_capercaillie_cjs.R` | CJS, reintroduced grouse, release year flagged, ends at confirmed death | Dryad | CC0 |
| `king_2018_lakeerie_watersnake_cjs.R` | CJS, MARK .inp with site x sex groups, surveyed site-years inferred | Dryad | CC0 |
| `dyck_2022_carpathians_carniv_occ.R` | multi-species detection, cameras, 14-day sessions with effort, two seasons, Romania | Dryad | CC0 |
| `asfaw_2025_omo_carniv_occ.R` | multi-species detection, cameras, 3-day occasions from a deposited 0/1/NA matrix, Ethiopia | Dryad | CC0 |
| `hollanders_2022_mfleayi_rdms.R` | multi-state (Bd infection) robust design, three sites, histories padded to study start | Dryad | CC0 |
| `pilger_2022_gila_fish_count.R` | community counts, electrofishing and seining, area file as sample table, annual | Dryad | CC0 |
| `crunchant_2020_issa_chimp_occ.R` | single-species detection, cameras, daily occasions from a deposited matrix, coordinates coarsened (EN), Tanzania | Dryad | CC0 |
| `fraticelli_2026_zakouma_carniv_occ.R` | multi-species detection, cameras, 5-day occasions with an effort table, dry and wet seasons, Chad | Dryad | CC0 |
| `mungi_2025_india_invplant_binom.R` | binomial_count (replicates with presence of replicates surveyed), 11 invasive plants, 25 km2 cells, five cycles, India | Zenodo | CC BY 4.0 |
| `davis_2019_kasungu_scr.R` | SCR, multi-session (three annual surveys), partial identity (single-flank ids), two species tables (`davis_2019_kasungu_leopard_scr`, `davis_2019_kasungu_hyaena_scr`), traps centred (VU), Malawi | Zenodo | CC BY 4.0 |
| `iannarilli_2026_snapshoteurope_comm.R` | community detection, cameras, camera-weeks from a Wildlife Insights deployment + sequence export, failed deployments dropped, coordinates coarsened (EN/VU), 24 European countries and Israel | Edmond (Dataverse) | CC BY-SA 4.0 (derived CC BY-NC-SA 4.0) |
| `faveyts_2026_zwin_butterfly_count.R` | community counts, butterfly transects, checklist with explicit zeros, 12 routes, one season, Belgium | GBIF (Belgian IPT) | CC BY 4.0 |
| `sepulveda_2019_streamgage_fish_edna.R` | multi-scale eDNA, kokanee and yellow perch, 9 streamgages x 6 events x 3-10 water samples x 4 qPCR replicates, field-blank and inhibition covariates, Columbia and Colorado basins 2018 | USGS ScienceBase | US public domain (CC0) |
| `siren_2024_vtnh_moose_count.R` | open multistate N-mixture counts, moose calves and adult cows (species x stage taxa), 225 camera sites x 6 years x 4 months, Vermont and New Hampshire | Dryad | CC0 |
| `finnegan_2024_afognak_deer_scr.R` | closed SCR, 23 Sitka black-tailed deer bucks x 26 cameras x 32 nights, Afognak Island, Alaska | Dryad | CC0 |
| `pakanen_2020_dunlin_ms.R` | multi-state CJS by geolocator status, 337 southern dunlins, 2002-2018, removals flagged, Finland | Dryad | CC0 |
| `nicolau_2021_porsanger_vole_ccr.R` | closed capture-recapture, multi-session: 3,145 gray-sided voles x 2 visits in 36 spring and autumn sessions at 21 stations, session-scoped ids, Porsanger, Norway, 2000-2017 | Dryad | CC0 |
| `valente_2018_indiana_birds_comm.R` | community occupancy, 19 forest birds x 193 point-count stations x 3 visits with three within-count intervals as obs_, southern Indiana 2014 | Dryad | CC0 |
| `goldman_2023_pnw_pika_dynocc.R` | dynamic occupancy, American pika sign surveys at 771 plots in five park units, 2010-2021, counts per sign type as obs_ (multi-sign model), Oregon / Idaho / California | Dryad | CC0 |
| `maphisa_2019_ingula_birds_comm.R` | community occupancy from a record table, 92 grassland bird taxa x 20 plots, 11 months 2010-2012, English names resolved by hand, Ingula, South Africa | Dryad | CC0 |
| `cecconi_2025_cricket_occ.R` | single-season occupancy, Japanese burrowing cricket x 49 sites x 3 aural point counts, Kentucky 2024 | Dryad | CC0 |
| `shah_2025_bardia_tiger_occ.R` | single-season occupancy, tiger camera traps x 719 grid cells x 20 replicates, Bardia-Banke, Nepal 2021-22 (batch 37) | Dryad | CC0 |
| `joshi_2025_shuklaphanta_leopard_occ.R` | single-season occupancy, leopard camera traps x 92 grid cells x 4 blocks, Shuklaphanta, Nepal 2022-23 (batch 37) | Dryad | CC0 |
| `goldman_2025_pennsylvania_grouse_occ.R` | single-season occupancy, ruffed grouse drumming on ARUs x 305 points x 5 weeks, Pennsylvania 2021-23; zero-minute weeks dropped (batch 37) | Dryad | CC0 |
| `palmero_2023_lynx_scr.R` | three SCR tables (binomial counts per station, days operated), Eurasian lynx in Chornobyl, Skolivski Beskydy and Pripyat-Polesia (batch 37) | Dryad | CC0 |
| `visagie_2026_tswalu_carniv_scr.R` | three SCR tables (daily occasions, operation matrix), leopard, brown and spotted hyaena, Tswalu Kalahari; stations centred (batch 37) | Dryad | CC0 |
| `rich_2019_mojave_binom.R` | two binomial_count community tables, Mojave camera mammals and acoustic songbirds x 210 sites (batch 37) | Dryad | CC0 |
| `zuberogoitia_2021_basque_owls_count.R` | community repeated counts, 9 owls and nightjar x 527 playback points x 8 rounds, Basque Country 2018 (batch 37) | Dryad | CC0 |
| `gaynor_2020_gorongosa_mamm_binom.R` | binomial_count community, 38 mammals x 60 cameras, Gorongosa (batch 37) | Dryad | CC0 |
| `rota_2016_midatlantic_carniv_occ.R` | multi-species occupancy, 4 carnivores x 1,906 camera sites x camera days, Mid-Atlantic USA (batch 37) | Dryad | CC0 |
| `fidino_2018_chicago_mesocarn_dynocc.R` | dynamic community occupancy, coyote/opossum/raccoon x 111 Chicago stations x 13 seasons x 28 days (batch 37) | Dryad | CC0 |
| `burgstahler_2026_wa_shrubsteppe_mamm_occ.R` | occupancy with spatial replicates, 5 mammals x 141 sites x 4 cameras, eastern Washington 2021-24 (batch 37) | Dryad | CC0 |
| `gustafson_2024_seward_gyrfalcon_dynocc.R` | dynamic occupancy, gyrfalcon territories x 6 years x 2 helicopter surveys, Seward Peninsula (batch 37) | Dryad | CC0 |
| `furnas_2021_ncalifornia_carniv_comm.R` | multi-season community occupancy, 15 carnivores x 1,451 site-years x 30 days, northern California 2009-18; coordinates coarsened (batch 37) | Dryad | CC0 |
| `wong_2022_sabah_acacia_mamm_comm.R` | community occupancy with effort, 25 taxa x 142 cameras x 31 occasions, Sabah (batch 37) | Dryad | CC0 |
| `higgins_2022_utila_anole_ccr.R` | closed capture-recapture, Utila anole (CR) x 10 plots x 4 visits (batch 37) | Dryad | CC0 |
| `iknayan_2023_svalley_pollinator_occ.R` | community occupancy, 42 pollinator taxa x 41 plots x 1-4 visual surveys, Silicon Valley 2017 (batch 37) | Dryad | CC0 |
| `priol_2014_quebec_flyingsquirrel_rd.R` | robust design CMR, northern flying squirrel x 56 sites, 2008 and 2012 x 2 occasions, nest-box BACI (batch 37) | Dryad | CC0 |
| `warretrodrigues_2022_iguana_msrd.R` | multi-state robust design, Lesser Antillean iguana (CR) x 9 years x 5 days, age-sex class at capture (batch 37) | Dryad | CC0 |
| `morganti_2017_swift_cjs.R` | two CJS tables, common and pallid swifts with and without geolocators, Italy (batch 37) | Dryad | CC0 |
| `poutanen_2018_finland_whitetail_scr.R` | SCR, faecal-DNA white-tailed deer x 180 plots x 3 visits, Finland 2015 (batch 37) | Dryad | CC0 |
| `vandeweyer_2024_australia_mouse_scr.R` | multi-session SCR, house mice x 8 live-trap grids x 4 sessions; nights and trap positions inferred (batch 37) | Dryad | CC0 |
| `lindenmayer_2022_nsw_woodland_birds_comm.R` | dynamic community occupancy, 31 woodland birds x 259 sites x 17 years (batch 37) | Dryad | CC0 |
| `henden_2013_finnmark_birds_dynocc.R` | dynamic community occupancy, 17 tundra birds x 37 willow plots x 4 years x 3 visits (batch 37) | Dryad | CC0 |
| `thomas_2025_boreal_moose.R` | occupancy and multi-state occupancy (female, female with calf), moose x 89 cameras (batch 37) | Dryad | CC0 |
| `mcnew_2025_sagegrouse_lek_count.R` | N-mixture lek counts, greater sage-grouse x 23 leks, 2021-22 (batch 37) | Dryad | CC0 |
| `rivera_2022_diel_msocc.R` | three multi-state diel occupancy tables: Chicago coyote, Makira and Ranomafana fosa (batch 37) | Dryad | CC0 |
| `tjornlov_2020_eider_ld.R` | two Burnham live-dead tables, common eiders at Christianso and Vlieland (batch 37) | Dryad | CC0 |
| `hostetter_2020_minnesota_lynx_dynocc.R` | dynamic occupancy, Canada lynx snow tracks x 431 cells x 5 winters (batch 37) | Dryad | CC0 |
| `jones_2021_madagascar_plovers_cjs.R` | three CJS tables, Kittlitz's, Madagascar (VU) and white-fronted plovers, 2008-2020 (batch 37) | Dryad | CC0 |
| `wang_2019_amazon_ocelot_occ.R` | single-season occupancy with effort, ocelot x 899 cameras, Brazilian Amazon (batch 37) | Dryad | CC0 |
| `monterroso_2020_iberia_carniv_comm.R` | community occupancy, 8 carnivores x 446 Iberian station-seasons x 64 days; coordinates coarsened (Iberian lynx) (batch 37) | Dryad | CC0 |
| `murn_2016_kruger_vulture_occ.R` | single-season occupancy (occupancy known), white-headed vulture (CR) x 17 territories x 359 visits, Kruger (batch 37) | Dryad | CC0 |
| `green_2018_ncal_mesocarnivores.R` | dynamic occupancy of fisher, grey fox and ringtail on track plates, and fisher hair-snare SCR, northwestern California (batch 37) | Dryad | CC0 |
| `regmi_2024_madhesh_tiger_binom.R` | binomial_count community, tiger and six prey x 94 cameras x 3 weeks, Madhesh, Nepal (batch 37) | Dryad | CC0 |
| `braga_2024_saopaulo_guan_occ.R` | single-season occupancy, rusty-margined guan x 205 cameras x 6 occasions, Brazil (batch 37) | Dryad | CC0 |
| `roth_2016_aargau_amph_count.R` | community N-mixture counts, three endangered toads and water frogs x 481 sites x 2 visits, Aargau (batch 37) | Dryad | CC0 |
| `bianchi_2021_furnas_carniv_occ.R` | multi-species occupancy, tayra, puma, dogs x 57 cameras x 9 occasions, Brazil (batch 37) | Dryad | CC0 |
| `paquet_2015_weaver_helpers_ms.R` | multi-event CMR, sociable weaver breeders coded by helper number, 13 years (batch 37) | Dryad | CC0 |
| `mizel_2018_alaska_sparrows_count.R` | N-mixture counts, two sparrows x 150 Alaska sites x 5 visits (batch 37) | Dryad | CC0 |
| `chambert_2018_frogs_acoustic_count.R` | two count tables of automated acoustic detections with validated false positives, pig frog and green treefrog (batch 37) | Dryad | CC0 |
| `fogarty_2022_greatbasin_birds_count.R` | multi-season community N-mixture, 32 riparian birds x 275 points x 15 years, Nevada (batch 37) | Dryad | CC0 |
| `thuma_2025_massachusetts_bombus_nests.R` | two within-season nest capture-recapture tables, Bombus impatiens and B. griseocollis, 2018-2024 (batch 37) | Dryad | CC0 |
| `roder_2020_valais_ungulates_count.R` | multi-season community N-mixture, five ungulates from snow tracks x 218 transects x 4 winters (batch 37) | Dryad | CC0 |
| `taraporevala_2025_kansas_canids_dynocc.R` | dynamic two-species occupancy with effort, coyote and red fox x 74 urban cameras x 4 seasons (batch 37) | Dryad | CC0 |
| `croose_2019_michigan_mustelid_dynocc.R` | dynamic two-species occupancy with effort, marten and fisher x 64 cells x 3 winters (batch 37) | Dryad | CC0 |
| `jacobson_2020_cookinlet_beluga_cjs.R` | CJS photo-ID, 386 Cook Inlet belugas, 2005-2016 (batch 37) | Dryad | CC0 |
| `hamer_2017_wtp_growlingfrog_dynocc.R` | dynamic occupancy, growling grass frog (VU) x 33 wetlands x 4 seasons (batch 37) | Dryad | CC0 |
| `peron_2017_sabap2_broodparasites_occ.R` | dynamic community occupancy, 8 brood-parasite and host birds on 82,189 SABAP2 atlas cards, 2007-2013 (batch 37) | Dryad | CC0 |
| `lloyd_2020_marion_elephantseal_ms.R` | multi-event resighting (breeding status x tag loss), 6,245 male southern elephant seals, Marion Island, 1983-2016 (batch 37) | Dryad | CC0 |
| `laytonmatthews_2024_hornoya_gull_cjs.R` | CJS, 158 great black-backed gulls with contaminant levels, Hornoya, 2001-2017 (batch 37) | Dryad | CC0 |
| `guzy_2018_southcarolina_anuran_comm.R` | community occupancy, 13 calling anurans x 42 riparian sites x 9 surveys, South Carolina (batch 37) | Dryad | CC0 |
| `goldingay_2022_nsw_underpass_mamm_occ.R` | two weekly camera detection tables (Grafton, Port Macquarie), mammals and lace monitor in road underpasses and forest (batch 37) | Dryad | CC0 |
| `saeed_2022_murree_spinyfrogs_dynocc.R` | two-species occupancy, Himalayan spiny frogs x 34 streams x 21 VES visits, 2017-2018 (batch 37) | Dryad | CC0 |
| `lyngdoh_2023_spiti_carniv_occ.R` | multi-species occupancy, dog, red fox, snow leopard, wolf x 97 cameras x 6 weeks, Spiti Valley (batch 37) | Dryad | CC0 |
| `twining_2024_newyork_carniv_occ.R` | two stacked occupancy tables: bobcat and coyote (winters 2013-2021, 3,849 site-years) and black bear (summers 2016-2018), New York (batch 37) | Dryad | CC0 |
| `fidino_2021_lincolnpark_birds_binom.R` | binomial counts, days seen of days walked, 193 birds x 16 years over a century, Lincoln Park, Chicago (batch 37) | Dryad | CC0 |
| `husemann_2015_taita_greenbul_cjs.R` | five CJS tables (one per forest fragment), Cabanis's greenbul, Taita Hills, 1996-2009 (batch 37) | Dryad | CC0 |
| `amir_2022_seasia_coabundance_count.R` | community counts, tiger, clouded leopard, sambar, red muntjac x 416 3-km cells x 40 five-day occasions, Southeast Asia (batch 37) | Dryad | CC0 |
| `mackenzie_2021_stexas_mesocarniv_dynocc.R` | dynamic three-species occupancy, ocelot, bobcat, coyote x 28 cameras x 14 seasons x 5 occasions, South Texas (batch 37) | Dryad | CC0 |
| `goldingay_2026_bendigo_camera_occ.R` | dynamic occupancy, cameras: phascogale and sugar glider x 30 sites near / away from nest boxes x 60 weeks in 5 season blocks, Bendigo, Victoria, 2023-2024; shared-detector ruling | Dryad | CC0 |
| `sharma_2021_spiti_snowleopard_scr.R` | count-detector SCR: 16 snow leopards x 30 cameras, encounters under a 4-hour rule, Spiti Valley, India, 2011-2012; coordinates displaced by the source | Dryad | CC0 |
| `schorr_2021_yampa_mylu_rd.R` | robust design, PIT antennas: 1,741 little brown bats at two roosts, 10 closed sessions with weekly occasions, Colorado, 2014-2018; survey set inferred | Dryad | CC0 |
| `botsch_2020_tits_territory_count.R` | repeated territory-mapping counts, occasion = visit x territory editor: two tits x 24 subsites, Switzerland, 2014-2015 | Dryad | CC0 |
| `schmelzle_2016_tidewatergoby_edna.R` | multi-scale eDNA: tidewater goby, 358 water samples x 6 qPCR wells at 39 sites, California, 2014; coarsened | Dryad | CC0 |
| `marshall_2020_saltmarshsparrow_nmix.R` | N-mixture point counts: saltmarsh sparrow x 913 points x 2-3 counts, Maine-Maryland, 2012; coarsened | Dryad | CC0 |
| `bisht_2019_corbett_tiger_rd.R` | robust design, camera traps: 307 tigers x 6 annual primaries x 42 nights, Corbett, India, 2010-2015 | Dryad | CC0 |
| `shyvers_2020_ppr_sagegrouse_rd.R` | robust design, genetic CR from faecal pellets: 543 greater sage-grouse, 2 winters, NW Colorado | Dryad | CC0 |
| `jordan_2025_kapitia_skink_rd.R` | robust design, photo-ID: 360 Kapitia skinks x 5 primaries, New Zealand, 2019-2021 | Dryad | CC0 |
| `belder_2020_nsw_woodbird_cjs.R` | CJS, mist nets: 13 per-species tables (`belder_2020_nsw_<species>_cjs`), 21 restoration sites, NSW, 2015-2017 | Dryad | CC0 |
| `morrison_2023_fundy_salmon_edna.R` | multi-scale eDNA: Atlantic salmon, 547 bottles x 3 qPCR replicates on 21 days, Inner Bay of Fundy, 2020-2021; Ct in y_raw; coarsened | Dryad | CC0 |
| `sepulveda_2019_streamgage_dreis_edna.R` | multi-scale eDNA: dreissenid 16S screen, 200 samples x 4 replicates at 9 streamgages, 6 events, 2018; blank-positive flag | USGS ScienceBase | public domain |
| `osborne_2026_largeheath_dynocc.R` | dynamic occupancy: reintroduced Large Heath butterfly x 380 bog compartments x 9-23 visits a year, NW England, 2021-2025; coarsened | MMU figshare | ODC-By 1.0 |
| `inbo_2026_flanders_butterfly_count.R` | community counts, Pollard walks: 50 butterfly taxa x 112 routes, Flanders, 1991-2020, sections summed per visit | GBIF (INBO IPT) | CC BY-NC 4.0 |
| `ohrens_2026_latam_puma_occ.R` | occupancy, cameras: puma x 13,148 stations, daily occasions by calendar year, 19 countries, 2001-2023 (1.17M rows) | Dryad | CC0 |
| `strebel_2026_swiss_mhb_count.R` | Swiss MHB 1999-2025: per-visit territory counts and season totals (four tables: `_count`, `_exact_count`, `_total_count`, `_total_exact_count`), 267 squares | Zenodo | CC BY 4.0 |
| `chauvenet_2014_serotine_ms.R` | multi-state CJS (juvenile / immature / breeder): female serotine bats at two roosts (`chauvenet_2014_crundale_serotine_ms`, `chauvenet_2014_hollingbury_serotine_ms`), England, 1987-2011 | Dryad | CC0 |
| `perea_2025_coastalplain_bats_comm.R` | community occupancy, acoustic: 8 bat taxa x 240 sites x 3 nights, southeastern US Coastal Plain, winters 2020-2022 | Dryad | CC0 |
| `goldberg_2015_manas_leopard_scr.R` | closed SCR, cameras: 22 leopards x 29 stations x 91 days, Royal Manas NP, Bhutan, 2010-2011; traps centred (VU) | Dryad | CC0 |
| `roderiksen_2023_norway_tundra_carniv_occ.R` | community occupancy, cameras: 4 predators x 96 baited stations, daily occasions, late winters 2011-2020, Norway | Dryad | CC0 |
| `sovie_2023_ichauway_wildlife_comm.R` | community occupancy, cameras: 11 mammals and game birds x 71 cameras, Ichauway, Georgia | Dryad | CC0 |
| `barrueto_2023_nwt_grizzly_scr.R` | **withdrawn 2026-11-06 (#150, care_review); not shipped.** SCR, hair snags: 204 grizzly bears x 218 detectors x 6 visits, NWT, 2012-2014; traps centred | Dryad | CC0 |
| `sossover_2026_outerbanks_coyote_ms.R` | multi-state robust design, faecal DNA: 62 coyotes, islands as states, Outer Banks, NC | Dryad | CC0 |
| `bauer_2022_neshrubland_birds_count.R` | community point counts with minute intervals: 79 taxa x 66 points x 3 visits x 2 years, New England shrublands | Dryad | CC0 |
| `bedwell_2020_sierranevada_edna_binom.R` | binomial_count eDNA: Bd and yellow-legged frogs, 10 lakes and streams x 4 months, Sierra Nevada, 2016 | Dryad | CC0 |
| `katuwal_2025_parsakoshi_leopard_binom.R` | binomial_count, cameras: leopard x 154 cameras, Parsa-Koshi, Nepal | Dryad | CC0 |
| `manzo_2024_pedregulho_tayra_dog_occ.R` | single-season occupancy, cameras: tayra and domestic dog x 69 points x 21 five-day occasions, Brazil | Dryad | CC0 |
| `whitworth_2019_manu_terr_mamm_binom.R` | binomial_count, cameras: 26 terrestrial mammals x 68 stations, Manu, Peru, 2015-2016 | Dryad | CC0 |
| `zamuda_2022_yalemyers_mesopred_dynocc.R` | dynamic occupancy, cameras: 4 mesopredators x 56 sites x 4 seasons x 7 surveys, Connecticut | Dryad | CC0 |
| `curveirasantos_2019_guadiana_carn_occ.R` | single-season occupancy, cameras: 4 carnivores x 77 stations, Guadiana valley, Portugal | Dryad | CC0 |
| `raman_2006_anamalai_birds_count.R` | community counts, spatial replicates: 107 bird taxa x 13 rainforest fragments (`_count` coarsened, `_exact_count`), Anamalai, India | Dryad | CC0 |
| `roberts_2019_sierranevada_birds_count.R` | community point counts: 154 taxa x 1,353 points, Sierra Nevada, 2009-2016 (`roberts_2019_sierranevada_birds_count` coarsened, `roberts_2019_sierrane_birds_exact_count`) | Dryad | CC0 |
| `cove_2018_lowerkeys_dynocc.R` | dynamic occupancy, cameras: Lower Keys marsh rabbit and feral cat x 84 sites (`_dynocc` coarsened, `_exact_dynocc` cat only), Florida | Dryad | CC0 |
| `bruce_2022_wettropics_cat_occ.R` | single-season occupancy, cameras: feral cat x 90 sites x 18 five-day occasions, Wet Tropics, Australia | Dryad | CC0 |
| `barrile_2022_bridgerteton_toad_msrd.R` | multi-state robust design: 1,415 boreal toads, breeding sites as states, Bridger-Teton, 6 seasons; survey set inferred | Dryad | CC0 |
| `sweeney_2026_ocracoke_plover_cjs.R` | stopover CJS and counts of piping plovers (`_cjs`, `_count`), Ocracoke, NC, 8 seasons | Dryad | CC0 |
| `feldman_2023_quebec_wetland_comm.R` | community occupancy, cameras: 56 taxa x 50 ponds x 2 years (`_comm` coarsened latitude, `_exact_comm`), Quebec | Dryad | CC0 |
| `fiss_2024_pennsylvania_birds_count.R` | point counts with time to detection and ARU daily detections of two warblers (`_count`, `_aru_occ`), Pennsylvania | Dryad | CC0 |
| `barros_2024_mostela_weasel_occ.R` | multi-scale occupancy, paired methods: least weasel x 56 stations x 7 occasions x 2 devices (Mostela box, camera), Portugal, 2021 | Zenodo | CC BY 4.0 |
| `letourneux_2022_snowgoose_ms.R` | multi-state CMR with dead recoveries: 22,599 adult female greater snow geese, collar vs leg ring, 1990-2019 | Dryad | CC0 |
| `whittington_2025_banff_grizzly_occ.R` | dynamic occupancy, cameras: grizzly bear x 625 Parks Canada camera sites x 10 years, Canadian Rockies, 2012-2021 | Dryad | CC0 |
| `carter_2021_louisiana_lamp_calls.R` | NAAMP roadside calling index (ordinal 0-3), 27 anuran taxa x 540 route stops x 21 years, up to 3 seasonal runs | USGS ScienceBase | US public domain |
| `zipkin_2017_oregon_barredowl.R` | Barred Owl: incidental detections 1995-2014 (dynocc) and pair counts 2015-2016 (count), two tables | USGS ScienceBase | US public domain |
| `wiens_2021_socal_goldeneagle_dynocc.R` | Golden Eagle territorial-pair dynamic occupancy, 175 hexagons x 2 seasons x 4 windows | USGS ScienceBase | US public domain |
| `waddle_2020_louisiana_marshbird_comm.R` | ARU community occupancy, 11 marsh birds x 33 sites x 20 windows | USGS ScienceBase | US public domain |
| `rose_2024_sjvalley_leglesslizard_occ.R` | cover-board occupancy (checks within weeks within years), Temblor legless lizard | USGS ScienceBase | US public domain |
| `laramie_2019_bruneau_trout_edna.R` | eDNA occupancy, bull and rainbow trout, 26 sites x 12 months x 3 replicates, coarsened coordinates | USGS ScienceBase | US public domain |
| `hunter_2025_georgia_pinesavanna_occ.R` | single-season occupancy, Bachman's Sparrow and Northern Bobwhite, 161 points x 3 visits | USGS ScienceBase | CC0 |
| `halstead_2025_yosemite_rasi_cjs.R` | daily capture histories of 1,251 Sierra Nevada yellow-legged frogs, 192 survey days over 20 years | USGS ScienceBase | CC0 |
| `direnzo_2025_elcope_espadarana.R` | glass frog CJS before (2000-2004) and multi-state Bd infection after (2010-2014) the chytrid outbreak, two tables | USGS ScienceBase | CC0 |
| `kleeman_2024_dixiefire_ranaboylii_occ.R` | time-to-detection occupancy, foothill yellow-legged frog x 43 stream sites x up to 2 surveys, Dixie Fire 2022 | USGS ScienceBase | US public domain |
| `grant_2023_canaanvalley_amph_count.R` | egg-mass and larval counts by two observers, wood frog and spotted salamander x 108 vernal pools, 2004-2016 | USGS ScienceBase | US public domain |
| `glorioso_2021_louisiana_turtle_count.R` | hoop-net community counts, 7 turtle species x 119 trap sites x 2 nightly checks, Louisiana 2019 | USGS ScienceBase | US public domain |
| `holcomb_2017_suwannee_moccasinshell_occ.R` | occupancy with surveyors as occasions, Suwannee moccasinshell x 220 sites, coarsened coordinates (IUCN CR) | USGS ScienceBase | US public domain |
| `valente_2024_oregon_murrelet_state.R` | multi-state (none / presence / occupied behaviour), marbled murrelet x 132 stations, 2018-2022 | USGS ScienceBase | US public domain |
| `mccaffery_2024_elwha_mammals_count.R` | daily camera detection counts, 15 mammal taxa x 34 stations x 2 study years, Elwha River after dam removal | USGS ScienceBase | US public domain |
| `merkes_2016_wabash_carp_edna.R` | eDNA (multi-scale), bighead and silver carp x 611 water samples x 2 qPCR reactions, Wabash River 2013 | USGS ScienceBase | US public domain |
| `glorioso_2020_bigthicket.R` | ARMI visual encounter counts (37 species) and calling index (14 anurans), 52 sites, Big Thicket 2010-2018, two tables | USGS ScienceBase | US public domain |
| `swanson_2018_iowa_amph_occ.R` | occupancy by life stage, 4 anurans x 27 agricultural wetlands x 7 surveys, Iowa 2015-2016 | USGS ScienceBase | US public domain |
| `uherkoch_2019_npra_loon_ms.R` | multi-state breeding-state resight histories, Pacific and yellow-billed loons, NPR-A 2011-2014, two tables | USGS ScienceBase | CC0 |
| `rogers_2024_bighunting_sculpin_cjs.R` | CJS from mobile PIT-antenna surveys, 385 translocated Blue Ridge sculpin x 11 surveys | USGS ScienceBase | US public domain |
| `glorioso_2026_bayouteche_pipe_count.R` | PVC-pipe refugia counts, 9 herpetofauna taxa x 200 pipes x 62 monthly checks, 2017-2023 | USGS ScienceBase | US public domain |
| `hanslowe_2022_marianas_rat_occ.R` | chew-card occupancy with density manipulations, rats x 1,026 card stations, Guam and Rota | USGS ScienceBase | US public domain |
| `gapinski_2025_iowawrp_birds.R` | wetland-easement point counts: property presence (123 spp.), focal counts (16 spp.), point presence (54 spp.), three tables | USGS ScienceBase | CC0 |
| `hossack_2020_losttrail_toad.R` | robust-design capture histories of boreal toads, males (1,232) and females (167), 2003-2018, two tables | USGS ScienceBase | US public domain |
| `inbo_2026_flanders_abv_count.R` | common breeding bird point counts summed per square visit, 180 taxa, 757 squares, 2017-2025 | GBIF (INBO IPT) | CC0 |
| `inbo_2026_flanders_priobutterfly_count.R` | Meetnetten.be transect counts of nine priority butterflies (one target per transect, `__survey_taxa`) | GBIF (INBO IPT) | CC0 |
| `inbo_2026_flanders_odonatasite_count.R` | Meetnetten.be site counts of six priority dragonflies (one target per site, `__survey_taxa`) | GBIF (INBO IPT) | CC0 |
| `inbo_2026_flanders_crestednewt_count.R` | Meetnetten.be fyke counts of great crested newts per pond visit, fykes as effort | GBIF (INBO IPT) | CC0 |
| `haas_2025_sweden_waterbird_count.R` | Swedish midwinter waterbird census, 70 taxa on 3,724 sectors, 1966-2024, method as occasion | GBIF (Swedish IPT) | CC0 |
| `nrm_2024_sweden_porpoise_occ.R` | daily C-POD harbour porpoise detections at 34 Swedish monitoring stations, 2015-2023 | GBIF (Swedish IPT, SHARK) | CC0 |
| `kuczkowska_2026_warsaw_owl_occ.R` | owl playback survey, five species at 431 points x 3 surveys, habitat-based lists (`__survey_taxa`) | GBIF (Polish IPT) | CC BY 4.0 |
| `duboisgagnon_2021_quebec_chorusfrog_occ.R` | eDNA at two visits plus a paired call survey, boreal chorus frog, 180 ponds x 2 years (`obs_method`) | Dryad via Zenodo mirror | CC0 |
| `lombardi_2022_virginia_woodrat_occ.R` | live-trap occupancy, Allegheny woodrat, 226 site-years x up to 4 nights (no site id) | Dryad via Zenodo mirror | CC0 |
| `culina_2019_uk_bat_ms.R` | multi-event reproductive histories, two Myotis bats (two tables) | Zenodo | CC BY 4.0 |
| `killion_2023_idaho_mamm_comm.R` | camera-trap weekly detections, 7 mammals, 50 stations x 2 years | Zenodo | CC BY 4.0 |
| `macario_2026_serido_sparrow_rd.R` | robust design, Grassland Sparrow, 7 sessions x 6 occasions | Zenodo | CC BY 4.0 |
| `thomas_2025_oregon_murrelet_occ.R` | marbled murrelet passive acoustic and audio-visual surveys (two tables) | Zenodo | CC BY 4.0 |
| `arango_odonata_andes_cjs.R` | daily CJS, two Andean odonates x two seasons (four tables) | figshare | CC BY 4.0 |
| `freake_2016_hiwassee_hellbender_cjs.R` | annual CJS, hellbender, 2004-2008 | Harvard Dataverse | CC0 |
| `saracco_2019_saipan_cjs.R` | annual CJS, five Saipan landbirds at six TMAPS stations (five tables) | Harvard Dataverse | CC0 |
| `cox_2018_qubs_treeswallow_cjs.R` | annual CJS, tree swallow females and nestlings, 1975-2017 | Borealis | CC0 |
| `ruiz_2021_oaxaca_wetbirds_count.R` | monthly point counts, 149 bird species x 20 sites x 36 months | Dryad via Zenodo mirror | CC0 |
| `mattioli_2018_arezzo_wolf_scr.R` | camera-trap SCR, grey wolf, two sessions (RAR read with `archive`) | figshare | CC BY 4.0 (+ CC0) |
| `marescot_2018_serengeti_hyena_ms.R` | multi-event histories with CDV status, spotted hyena females and males (two tables) | figshare | CC BY 4.0 |
| `wikston_2021_ontario_anuran_occ.R` | call, dipnet and visual-encounter anuran surveys (three tables) | Borealis | CC BY-NC 4.0 |
| `deere_2017_safe_mamm_comm.R` | camera-trap weekly detections, 28 mammals x 115 sites, coarsened plus `_exact` sibling | EIDC | OGL v3 |
| `dominoni_2024_glasgow_tit_cjs.R` | annual CJS, blue and great tits along an urban gradient (two tables) | EIDC | OGL v3 |
| `ukpoms_2026_uk_pantrap_count.R` | pan-trap bee and hoverfly counts, 480 stations in 96 squares, 2017-2023 | EIDC | OGL v3 |
| `benoit_2018_costello_fish_count.R` | minnow-trap counts, 14 fish x 36 traps x 3 days x 2 years (`__survey_taxa`) | Dryad via Zenodo mirror | CC0 |
| `ademola_2021_ukaguru_praomys_cjs.R` | monthly CJS, Praomys delectorum on four grids (sessions inferred from the protocol) | Dryad via Zenodo mirror | CC0 |
| `klmn_2026_klamath_landbird_count.R` | NPS Klamath Network landbird point counts, 2010-2025 | NPS IRMA | CC0 |
| `glorioso_2026_bayouteche_frog_cjs.R` | CJS per species (four tables), tagged treefrogs in PVC pipes, deaths as removals | USGS ScienceBase | public domain |
| `poessel_2026_coso_mgs_rd.R` | robust design, Mohave ground squirrel trapping days inferred from captures | USGS ScienceBase | public domain |
| `dittman_2025_genesee_sturgeon_count.R` | gill-net counts of reintroduced lake sturgeon per site visit, coarsened (IUCN EN) | USGS ScienceBase | public domain |
| `alchokhachy_2024_duckcreek_trout_cjs.R` | CJS per species (two tables), seasonal electrofishing of PIT-tagged trout | USGS ScienceBase | public domain |
| `brinck_2022_maunakea_palila_count.R` | point counts of palila (IUCN CR, no locations), 1-4 visits a year for 21 years | USGS ScienceBase | public domain |
| `muths_2020_blackrock_toad_rd.R` | robust design, boreal toads with per-capture Bd status | USGS ScienceBase | public domain |
| `rowe_2021_deschutes_ospfrog_rd.R` | robust design, Oregon spotted frogs, three visits per season | USGS ScienceBase | public domain |
| `buhl_2023_ndmt_grassbirds_count.R` | community counts, 9 visits per stop (on-, near-, off-road), PLSS locators coded plus `_exact` sibling (E7.3) | USGS ScienceBase | public domain |
| `inbo_2026_flanders_alconegg_count.R` | Alcon blue egg counts, Meetnetten.be | GBIF (INBO IPT) | CC0 |
| `levy_2025_sclerocactus_ms.R` | multi-state census histories of two hookless cacti (two tables) | GBIF (VertNet IPT) | CC0 |
| `law_2018_nsw_koala_occ.R` | single-season occupancy, acoustic koala detections | Dryad (via Zenodo) | CC0 |
| `bauwens_2019_belgium_adder_ms.R` | multi-state (breeding state) CJS from a MARK .inp file | Zenodo | CC BY 4.0 |
| `hitchcock_2025_garden_hedgehog_count.R` | weekly camera detection counts in gardens, camera days as effort | Zenodo | CC BY 4.0 |
| `fancourt_2019_aus_catdingo_occ.R` | two-species camera occupancy, dingo and feral cat | Dryad (via Zenodo) | CC0 |
| `mellado_2021_carollia_ms.R` | multi-state CJS of bats: tag carried and arm-band injury (two tables) | Zenodo | CC BY 4.0 |
| `messerman_2020_ambystoma_cjs.R` | CJS per species (three tables), juvenile salamanders in enclosures | Dryad (via Zenodo) | CC0 |
| `lenzi_2024_alpine_toad_cjs.R` | 30-year annual CJS of an alpine common toad population | Zenodo | CC BY 4.0 |
| `chanex_2026_swissalps_amph_count.R` | community counts at snow-making reservoirs and ponds, read from a 1.1 GB zip by range requests | Zenodo | CC BY 4.0 |
| `lebeuftaylor_2026_alpac_songbird_dynocc.R` | dynamic community occupancy from classifier detections on ARU recordings | Borealis | CC0 |
| `steinmetz_2025_maewong_tiger_rd.R` | robust design, tigers (IUCN EN) in six biennial camera sessions | figshare | CC BY 4.0 |
| `inbo_2026_flanders_batwinter_count.R` | Meetnetten.be winter counts of hibernating bats, 23 identification classes, 1,380 sites, 1943-2024 | GBIF (INBO IPT) | CC0 |
| `inbo_2026_flanders_firesalamander_count.R` | Meetnetten.be night transect counts of fire salamanders, 83 transects, 2016-2025 | GBIF (INBO IPT) | CC0 |
| `haas_2025_sweden_waterbirdsep_count.R` | Swedish September waterbird census, 48 species on 1,645 sectors, 1973-2024, method as occasion | GBIF (Swedish IPT) | CC0 |
| `lindstrom_2025_sweden_winterpoints_count.R` | Swedish winter point count routes, 262 taxa, 2,452 routes, survey period as occasion, winter parts | GBIF (Swedish IPT) | CC0 |
| `carro_2023_donana_tracks_count.R` | Doñana carnivore track counts, nine per-taxon GBIF datasets joined, 12 transects, coarsened (lynx) | GBIF (GBIF Spain IPT) | CC BY 4.0 |
| `rees_2023_victoria_cat_smr.R` | spatial mark-resight, feral cats with natural marks + reserved unmarked / marked_unidentified units, 10 camera sessions, Victoria, 2017-2019 | Dryad | CC0 |
| `ford_2025_iowa_grassbirds_count.R` | grassland bird point counts, 3 intervals x 4 distance cells as obs_ columns (repeated rows within a visit summed), southern Iowa, 2022-2023 | USGS ScienceBase | CC0 |
| `roberts_2025_arkansas_birds_count.R` | grassland bird point counts with distance cells, 416 points on five Arkansas sites, 2022-2023; coarsened (chimney swift VU) + `_exact` sibling | USGS ScienceBase | CC0 |
| `klymus_2023_niobrara_mussel_edna.R` | eDNA qPCR, all-zero table (admitted 2026-11-06) | USGS ScienceBase | US public domain |
| `nakashima_2024_japan_ttd_occ.R` | time to detection at ephemeral resources (nests, carcasses), two tables | Dryad | CC0 |
| `gustafson_2024_seward_prey_count.R` | single-visit time-removal point counts, intervals as obs_ | Dryad | CC0 |
| `bornand_2014_gantrisch_plant_occ.R` | double-observer time-to-detection plant search | Dryad | CC0 |
| `dwyer_2024_phoenix_bat_occ.R` | acoustic bat detections, four seasons | Dryad | CC0 |
| `hastings_2018_sealion_philopatry_ms.R` | multistate philopatry, two spatial scales, two tables | Dryad | CC0 |
| `silva_2018_scotland_badger_occ.R` | camera-trap occupancy, weekly | Dryad | CC0 |
| `jenkins_2019_olympic_fisher_occ.R` | camera + hair-snare occupancy, hexagon x 14-day interval | ScienceBase | US PD |
| `barry_2025_sierra_owls_comm.R` | acoustic ARU occupancy, two units (ARU community; cell GHO), two tables, author-corrected files | Dryad | CC0 |
| `trujillo_2020_tasmania_crayfish_edna.R` | eDNA multi-scale, stream > water sample > qPCR replicate, author-supplied site metadata | Zenodo | CC BY 4.0 |
| `debusschere_2026_bpns_porpoise_occ.R` | passive acoustic detection, harbour porpoise per deployment-hour (C-POD / F-POD), 172 deployments at 24 stations, Belgian North Sea, 2014-2024 | VLIZ IPT | CC BY 4.0 |
| `azzurro_2022_med_climatefish_count.R` | repeated counts, diver transects (4 per location x depth layer x visit), 15 Mediterranean coastal fish incl. 8 non-indigenous, 2009-2021 | VLIZ IPT / SEANOE | CC BY 4.0 |
| `nichols_2025_hawaii_acanthophora_edna.R` | eDNA multi-scale, reef site > water sample > qPCR well, non-indigenous red alga, Hawaii 2020-2023 | Dryad | CC0 |
| `seys_2020_belgium_seawatch_count.R` | repeated counts, citizen-science shore push-net, 50 fish / crab / shrimp / jellyfish taxa at 14 Belgian beaches, seasonal visits 2014-2018; also builds `seys_2020_belgium_patella_count` (limpets, ten groyne quadrats per visit, 13 beaches) and `seys_2020_belgium_arenicola_count` (lugworm casts on the low beach, 14 beaches) | VLIZ IPT (SeaWatch-B) | CC BY-NC-SA 4.0 |
| `faria_2026_azores_patella_count.R` | repeated counts, spatial replicates (15 quadrats per location x shore level), two Azorean limpets, 2006 | GBIF Portugal IPT | CC BY 4.0 |
| `faria_2026_azores_mpa_patella_count.R` | repeated counts, spatial replicates (10 quadrats per site x campaign), Patella candei in partial and full MPAs, São Miguel 2006-2008 | GBIF Portugal IPT | CC BY 4.0 |
| `szewczyk_2019_colorado_ants_binom.R` | pitfall binomial counts, multi-scale (site > trap pair), per-region lists, two tables (coarsened + `_exact`) | Dryad | CC0 |
| `jimenezfranco_2019_murcia_birds_binom.R` | line-transect binomial counts, transects as spatial replicates of grid cells | Dryad | CC0 |
| `jimenezfranco_2023_murcia_birds_binom.R` | line-transect binomial counts, modern resurvey (2012, 2017) of the same region, cells of 2 x 2 km | Dryad | CC0 |
| `neon_2026_zooplankton_count.R` | lake zooplankton counts per tow / trap sample (about 3 samples per bout, 3 bouts a year), 208 taxa x 7 NEON lakes x 204 bouts, 2014-2024, sampler, volume as effort and the fraction counted (subsampleColumn); coarsened (Hesperodiaptomus augustaensis VU) plus `neon_2026_zooplankton_exact_count` | NEON DP1.20219.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_aqplants_occ.R` | aquatic plant, bryophyte, lichen and macroalgae presence at points along permanent transects (transect = unit, point = spatial occasion, bout = period), 153 taxa x 240 transects at 24 NEON wadeable-stream sites x 548 bouts, 2014-2024, per-site pools | NEON DP1.20072.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_dna_occ.R` | COI metabarcoding detections (reads at or above NEON's reporting threshold; reads in y_raw, depth as obs_) per sample x primer set, benthic macroinvertebrates (4,689 names x 34 sites, 2018-2022) and lake zooplankton (492 names x 7 lakes), per-site name pools; each with an `_exact` E7 sibling | NEON DP1.20126.001 / DP1.20221.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `secr_package_scr.R` | five closed-population SCR tables from the secr package (possums Waitarere, stoats Matakitaki, black bears Smokies, deer mice Colorado, house mice Ballona), loaded from the pinned CRAN tarball without the package; survey set inferred (no usage) | CRAN secr 5.5.1 | GPL (>= 2) |
| `ipmbook_package_cjs.R` | three CJS tables from the IPMbook package (horseshoe bats Vex, hoopoes Valais, woodchat shrikes Albvorland); recapture years from the book's chapter code | CRAN IPMbook 0.1.5 | GPL (>= 3) |
| `ahmbook_package_tables.R` | seven AHMbook tables: water voles (dynocc), Aargau marbled white (rotating-panel dynocc), Jura peregrines (annual aggregate dynocc; time-to-detection searches), Swiss eagle owls (multi-state), dusky salamander stage counts, Swiss red squirrels (occupancy); pinned CRAN tarball, no package load | CRAN AHMbook 0.2.12 | GPL (>= 3) |
| `ipmbook_package_ms.R` | IPMbook white storks (live-dead, Burnham) and Kattegat cormorants (multistate, age x colony) | CRAN IPMbook 0.1.5 | GPL (>= 3) |
| `ahmbook_package_tables2.R` | seven more AHMbook tables: Hubbard Brook warbler counts (community, 20 years), Swiss atlas 1-ha community counts, Flevoland wagtail distance classes, WMNF chestnut-sided warbler removal counts, Alpine lynx certain/uncertain records (state), BTO CES willow warbler CJS, Swiss middle spotted woodpecker checklist binomial counts | CRAN AHMbook 0.2.12 | GPL (>= 3) |
| `ergon_2014_kielder_vole_scr.R` | robust-design SCR of adult field voles, Kielder 2000; deposit is an R dput file read by safe parsing | Dryad | CC0 |
| `cr_package_tables.R` | nine capture-recapture tables from openCR (moths, Patuxent voles RD and females, Orongorongo possums RD), secr (Orongorongo possum SCR, Patuxent ovenbirds, Buller skinks x2 with centred coordinates) and multimark (Nagarahole tigers, centred coordinates) | CRAN openCR 2.2.8, secr 5.5.1, multimark 2.1.7 | GPL |
| `rpkg_cr_tables.R` | nine capture-history tables from Rcapture (Logan buntings, Coulson eiders, Duchenier voles RD), RMark (Alice doves JS, Edwards-Eberhardt cottontails, Brosnan deer double observer, Mahoenui weta occupancy) and FSA (Auke Lake cutthroat, Jewett Lake bluegill); frequency histories expanded | CRAN Rcapture 1.4-4, RMark 3.1.0, FSA 0.10.1 | GPL |
| `howe_2017_tai_duiker_ds.R` | camera-trap distance sampling of Maxwell's duikers, Taï 2014: all daytime hours and the peak-hours subset (siblings); interval bounds from deposited midpoints | Dryad | CC0 |
| `rpkg_misc_tables.R` | multimark bobcats with partial identity (closed CR and SCR), unmarked NAAMP calling indices (Delaware 2001, Massachusetts 2001-2007) and ovenbird removal counts | CRAN multimark 2.1.7, unmarked 1.5.2 | GPL |
| `inbo_2026_flanders_amphchorus_count.R` | Meetnetten.be chorus counts of tree frog, common spadefoot and natterjack toad, 121 ponds, 2016-2025; one target species per pond (`__survey_taxa`) | GBIF (INBO IPT) | CC0 |
| `haas_2025_sweden_coastalbirds_count.R` | Swedish coastal bird monitoring, 84 bird taxa on 200 archipelago squares, 2015-2024, one count per square-year; E7 `_exact` sibling | GBIF (Swedish IPT) | CC0 |
| `edp_2018_footua_amph_count.R` | EDP Foz Tua dam amphibian dip-net counts, 12 species at 30 plots, spring/autumn 2011-2017; E7 `_exact` sibling | GBIF (GBIF Portugal IPT) | CC BY 4.0 |
| `edp_2019_footua_winterbirds_count.R` | EDP Foz Tua winter point counts, 70 bird species at 128 points (matched across years by coordinates), 2011-2017 | GBIF (GBIF Portugal IPT) | CC BY 4.0 |
| `beja_2021_sabor_fish_count.R` | LTER Baixo Sabor single-pass electrofishing, 14 fish species in 75 reaches, 2012-2020 | GBIF (GBIF Portugal IPT) | CC BY 4.0 |
| `cortes_2023_sabor_fish_count.R` | EDP Baixo Sabor fish monitoring, 18 taxa at 69 stations, electrofishing plus reservoir netting (method as occasion), 2015-2020 | GBIF (GBIF Portugal IPT) | CC BY 4.0 |
| `evju_2025_hvaler_herminium_count.R` | NINA musk-orchid ramet counts in 77 permanent plots, Hvaler, 2014-2025; coordinates coarsened | GBIF (NINA IPT) | CC BY 4.0 |
| `merker_2021_coweeta_cawa_count.R` | Canada warbler counts in four 2.5-min intervals at 71 points near Coweeta, NC, 2014-2017 (Allee playback experiment; treatment held) | Zenodo (authors' permission) | CC BY 4.0 |
| `calhoun_2023_hopland_mamm_dynocc.R` | weekly camera-trap detection of 9 mammals at 36 stations, Hopland, CA, Oct-Nov 2016-2020, before and after the 2018 megafire | Dryad | CC0 |
| `sheehy_2018_scotland_marten_scr.R` | pine marten genetic SCR at 222 hair feeders in three Scottish regions, 2016; and red/grey squirrel and marten detection at 186 of the feeders (`sheehy_2018_scotland_feeder_comm`) | Dryad | CC0 |

Batch 2 (2026-11-01) was rebuilt against v1.0-draft and uploaded; batch 3 (2026-11-01) is the six round-trip
textbook datasets routed through `data/` (issue #18), loaded from package data rather than a download; batch 4 (2026-11-01) adds five public-deposit tables; batch 5 (2026-11-01) adds the first SCR and distance-sampling tables; batch 6 (2026-11-01) the first eDNA multi-scale and double-observer tables, built once Ben supplied the two open-access papers in `../queue/papers/`; see `../BATCH_LOG.md`. `aux/` holds lookup tables
shared by scripts (bird alpha codes).
