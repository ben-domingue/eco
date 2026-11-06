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
| `obrist_2024_gooseisland_birds_count.R` | N-mixture community counts, 50 bird species x 50 points x 3 surveys (2011) in four habitat types on six BC islands, built from per-detection records under the authors' own minute-and-distance rule; coordinates, weather, observer | Zenodo (xlsx) | CC BY 4.0 |
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
| `neon_2026_smallmammals_rd.R` | four single-species robust-design capture histories (Peromyscus maniculatus, P. leucopus, Sigmodon hispidus, Microtus pennsylvanicus), individuals x bouts x nights at the home grid | NEON DP1.10072.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_carabids_count.R` | biweekly pitfall counts, 55 carabid species x 2,029 NEON traps x 2013-2023, trapping days as effort; core CSV not tracked (354 MB) | NEON DP1.10022.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_fish_removal.R` | three-pass electrofishing removal (one pass at random reaches), 155 fish taxa x 223 NEON wadeable-stream reaches (23 sites) x 272 bouts, 2016-2024, multinomial_cell / removal; estimated bulk counts and net-compromised bouts dropped | NEON DP1.20107.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_ticks_count.R` | drag / flag counts per plot-bout, 28 tick species x life-stage taxa x 287 NEON plots (46 sites), 2019-2024, area sampled as effort | NEON DP1.10093.001 RELEASE-2026 (API token) | CC BY 4.0 |
| `neon_2026_mosquitoes_count.R` | CO2 light-trap collections, identified-subsample counts of 77 mosquito taxa x 518 NEON plots (47 sites), 2014-2024, trap hours and proportion identified; year parts (7.5M rows), not tracked | NEON DP1.10043.001 RELEASE-2026 (API token) | CC BY 4.0 |
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
| `banik_2025_dollyvarden_ms.R` | multistate CR, 21,430 anadromous Dolly Varden, five Yukon rivers, 14 autumns | Dryad | CC0 |
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
| `johnson_2023_tweedsmuir_bombus_count.R` | community counts, bumble bee vane traps, postfire | Dryad | CC0 |
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

Batch 2 (2026-11-01) was rebuilt against v1.0-draft and uploaded; batch 3 (2026-11-01) is the six round-trip
textbook datasets routed through `data/` (issue #18), loaded from package data rather than a download; batch 4 (2026-11-01) adds five public-deposit tables; batch 5 (2026-11-01) adds the first SCR and distance-sampling tables; batch 6 (2026-11-01) the first eDNA multi-scale and double-observer tables, built once Ben supplied the two open-access papers in `../queue/papers/`; see `../BATCH_LOG.md`. `aux/` holds lookup tables
shared by scripts (bird alpha codes).
