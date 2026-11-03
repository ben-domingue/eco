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
| `goldingay_2022_richmond_koala_dynocc.R` | single-species dynamic occupancy, spotlight transects, 8 years x 3 surveys, 7 habitat covariates, 2019 drought flagged | Dryad (version zip, UTF-16 text) | CC0 |
| `goldingay_2022_richmond_glider_dynocc.R` | same deposit and design for the central greater glider; separate table because the two species' survey sets differ in 22 cells | Dryad (version zip, UTF-16 text) | CC0 |
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
| `tetzlaff_2026_crotalus_cjs.R` | CJS histories, 707 adult female timber rattlesnakes, New York, 1983-2019, den group, annual covariates | Dryad | CC0 |
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
| `sandercock_2022_norway_alien.R` | community occupancy (plants, two botanists) + multi-scale eDNA (insects) | Dryad | CC0 |
| `armstrong_2024_hydrilla_dynocc.R` | dynamic occupancy (plant) | Dryad | CC0 |
| `martinezvillegas_2024_plants_cjs.R` | CJS, five marked plant species | Dryad | CC0 |
| `deprengerlevin_2024_astragalus_cmr.R` | multistate robust design + multistate CJS (plant, dormancy) | Dryad | CC0 |
| `schleimer_2019_gsl_finwhale_cjs.R` | CJS, photo-ID | Dryad | CC0 |
| `ancona_2016_isabel_booby_cjs.R` | CJS | Dryad | CC0 |
| `dezeeuw_2024_nl_waterbeetle_nmix.R` | community repeated counts (water beetles) | Dryad | CC0 |
| `inbo_2026_flanders_aesiso_count.R` | repeated counts, target species (dragonfly) | GBIF (INBO) | CC0 |
| `inbo_2026_flanders_calvir_count.R` | repeated counts, target species (dragonfly) | GBIF (INBO) | CC0 |
| `inbo_2026_flanders_coepul_count.R` | repeated counts, target species (dragonfly) | GBIF (INBO) | CC0 |

Batch 2 (2026-11-01) was rebuilt against v1.0-draft and uploaded; batch 3 (2026-11-01) is the six round-trip
textbook datasets routed through `data/` (issue #18), loaded from package data rather than a download; batch 4 (2026-11-01) adds five public-deposit tables; batch 5 (2026-11-01) adds the first SCR and distance-sampling tables; batch 6 (2026-11-01) the first eDNA multi-scale and double-observer tables, built once Ben supplied the two open-access papers in `../queue/papers/`; see `../BATCH_LOG.md`. `aux/` holds lookup tables
shared by scripts (bird alpha codes).
