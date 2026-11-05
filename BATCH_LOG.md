# Batch log

One entry per conversion batch (issue #10, step 5): what was built, what was
held and why. Tables listed here are in `output/`; whether they are published is
the `status` column of `tags/tags_auto.csv`.

## Batch 1 — 2026-10-31 (six tables, published to Redivis)

malhotra_2021_loslagos_comm, schank_2015_tapir_occ, toledolima_2024_elaenia_cjs,
palacio_2020_pampasbirds_comm, frimpong_2017_newriver_dynocc,
uherkoch_2021_npraloon_dynocc. See `data/README.md`.

## Batch 2 — 2026-11-01 (six tables from five deposits)

Built under v0.3 and held locally on Ben's instruction until the standard was frozen
as v1.0-draft (commit 088ba37) the same day; then rebuilt with `surveyEvidence`
(E4), `responseType = ordinal` for the calling index (E2) and the licence-conflict
ruling (intake policy), re-validated (12/12 eco_valid, 12/12 IRW view conforms) and
uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| hamer_2024_hungary_amph_comm | community occupancy | Dryad CC0 | 2,691 | 100 ponds x 3 surveys x 9 amphibians; `date` from a day offset; one unsurveyed cell |
| galvez_2021_araucania_comm | community occupancy (camera) | Dryad CC0 / readme ODbL -> derived ODbL-1.0 | 9,135 | 180 cameras x 14 occasions x 5 taxa; per-occasion camera nights; stricter licence propagates (intake ruling) |
| margenau_2021_rowsongbirds_nmix | N-mixture, multi-species, manipulative | Dryad CC0 | 135,072 | first N-mixture table; counts built from per-individual records; flyovers excluded; 2 non-IBP codes handled |
| glorioso_2025_atchafalaya_ves | community counts (N-mixture), 9 years | USGS public domain | 104,152 | surveys from a deposited sample table (explicit zeros verifiable); coordinates as published |
| glorioso_2025_atchafalaya_calls | ordinal (calling index 0-3) | USGS public domain | 31,024 | same 2,216 surveys; `obs_call_index_outside` |
| mctigue_2023_nwarkansas_comm | community occupancy (camera), 2 winters | Dryad CC0 | 46,746 | record table; deployment dates unreliable, zeros inferred from first/last detection spans; `y_raw` = episodes |

Held / rejected this batch (details in `queue/human_review.csv`): the two EDI
point-count packages (edi.348.2, edi.556.1: Cloudflare login wall on the portal
and 403 on PASTA for scripted requests), Margenau's `Data_stopover.csv` (second
table later), McTigue's density/covariate file (model output, unjoinable IDs).

Survey evidence (E4): Hamer `deposited_matrix`, Gálvez `effort_table`, Glorioso x2
`sample_table`, Margenau `row_presence`, McTigue `inferred` (first-to-last detection
span; deployment dates not believed).

Things this batch strained in the v0.3 standard, each now ruled in v1.0-draft:

- **Explicit zeros from record tables.** Three of five deposits (Margenau,
  McTigue, and to a lesser degree Glorioso) are one-row-per-detection files. The
  standard should say what counts as evidence of a survey when no sample table is
  deposited, and require the inference rule in `dataset.notes`.
- **Ordinal / index responses.** The calling index is neither a count nor a
  state; now `responseType = "ordinal"` with `stateCodes` (E2).
- **Per-row covariates that vary by taxon** (`obs_call_index_outside`): allowed by
  the `obs_` definition but worth an explicit sentence, since most `obs_` columns
  repeat across the taxa of a survey.
- **Licence conflicts** between the repository metadata and the deposited readme
  (Gálvez): ruled, the stricter licence governs and propagates (`derived_license =
  ODbL-1.0`, both recorded in `original_license`).
- **`y_raw` as the uncollapsed count** behind a 0/1 `y` (McTigue) is in 2.1 and
  worked without changes.
- No multinomial, distance-sampling or SCR deposit in this batch; no sensitive
  taxon with exact coordinates (USGS sites are on public management units and are
  published by the agency; kept as published); largest table 135k rows.

## Batch 3 — 2026-11-01 (six textbook tables, issue #18)

The six datasets of the Phase 2 round-trip tests (`converters/rt_0*`), routed
through `data/` as ordinary tables: loaded from R package data (`unmarked`,
`marked`, `AHMbook`; GPL carried through as `derived_license`), validated under
v1.0-draft (18/18 eco_valid, 18/18 IRW view conforms) and uploaded to the Redivis
draft. They add the first `multinomial_cell` table (E9 declared stretch), a second
N-mixture table, a second CJS table and the largest community table so far.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| kery_2008_willowtit_occ | single-season occupancy | unmarked widewt.csv, GPL-3 | 665 | 237 quadrats x 3 surveys; 46 unsurveyed cells; covariates standardised in the source |
| kery_2005_mallard_count | N-mixture | unmarked::mallard, GPL-3 | 659 | 239 quadrats (4 never surveyed, no rows); covariates standardised |
| chandler_2009_alfl_removal | multinomial N-mixture (removal) | unmarked alfl.csv, GPL-3 | 150 | `occasion` = 5-min removal interval, `y_raw` = interval label, `multinomialType = removal`; survey 1 of 3 only |
| lebreton_1992_dipper_cjs | CJS | marked::dipper, GPL-2 | 2,058 | 294 individuals x 7 years; `__periods` carries the years |
| kery_2010_crossbill_dynocc | dynamic occupancy | unmarked::crossbill, GPL-3 | 6,642 | 267 quadrats x 3 x 9 years; raw Julian dates shipped (the vignette standardises) |
| kery_2014_mhb_comm | community counts | AHMbook::MHB2014, GPL-3 | 118,658 | 158 species (13 never recorded, all-zero); counts shipped, the book collapses to 0/1; quadrat coordinates in an unspecified CRS; one GBIF match fuzzy (Phylloscopus sibilatrix) |

Strains: none on the format. Two source-quality notes for `data_notes` when #6
exists: the MHB covariate scales in `widewt`/`mallard` are standardised and not
recoverable; the AHMbook coordinates deliberately omit their CRS.

## Batch 4 — 2026-11-01 (five tables from four public deposits)

Validated with `eco-validate` (the Python gate from #3): 23/23 tables pass, 23/23 IRW
view conforms; uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| evans_2021_maine_marten_dynocc | dynamic occupancy (camera) | figshare CC BY 4.0 | 15,792 | 197 stations x 7 seasons x 33 occasions; occasion length and years not in the deposit |
| tleimat_2023_ecuador_capuchin_occ | single-season occupancy (camera) | figshare CC BY 4.0 | 573 | 21 stations x 39 two-week occasions; CR taxon with no coordinates deposited; below floor |
| addis_2026_rmap_mbrt_dynocc | multi-species dynamic occupancy | figshare CC BY 4.0 | 20,725 | 188 sites, 5 species, 2012-2019; `obs_citizen_scientist`; coordinates as published |
| addis_2026_rmap_bt_dynocc | multi-species dynamic occupancy | figshare CC BY 4.0 | 9,204 | 145 sites, 4 species, 2014-2019; sibling of the above |
| kleiven_2020_varanger_dynocc | dynamic co-occurrence occupancy, two spatial scales | DataverseNO CC0 | 115,294 | 46 cameras in 8 blocks (`cluster_id`), 7 seasons x 304 daily occasions; four-state code split into two taxa with the code in `y_raw`; first table on E9's experimental list |

What this batch says about the standard:

- **Species pools that differ by region strain E4.** The RMAP deposit surveys for
  five species in one national forest and four in the other. E4 note 2 wants a row
  for every taxon at every survey, so the deposit became two tables. This is the
  clean answer, but a corpus of regional surveys will meet it often; a per-unit
  species list (E4 relaxed to "every taxon surveyed-for at that unit") is the
  alternative and would keep such deposits as one table. Logged, not changed.
- **Functional groups as taxa.** The COAT data classify images to "small rodents" and
  "small mustelids". `__taxa` carries `taxonRank = order / genus` and GBIF keys at
  that rank; nothing in the standard needed to change.
- **Multi-state co-occurrence codes** (none / A / B / both) split cleanly into one
  detection row per taxon with the code in `y_raw`; the two-species interaction model
  is a model choice on the same table (design landscape, group A).
- **Deposits without dates.** Two deposits (marten, COAT) give ordered occasions with
  no calendar; `period`/`occasion` carry the order and `__periods` says the calendar
  is absent. E8 already allows this.

Held this batch (`queue/human_review.csv`): Margenau stopover (one visit per
point-year, no within-season replication), Iowa herptiles (day columns unlabelled;
year boundaries not recoverable without the paper's survey calendar), water snake
CJS (no licence; needs permission by email), puma range-wide (CC0, 100 MB; its own
project, like BBS).

## Batch 5 — 2026-11-01 (first SCR and distance-sampling tables, from three public deposits)

Discovery pass for the four families the corpus lacked (closed capture-recapture,
double-observer / distance sampling, eDNA multi-scale, SCR): Dryad and Zenodo searches
plus the installed packages. Built from the processing guide and the
`eco-convert-deposit` skill. Validated with `eco-validate`: 27/27 tables pass; the IRW
view conforms after eco-ff's fix to `eco_to_irw()` (below). Uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| lazenby_2021_tasmania_swamprat_scr | spatial capture-recapture (Elliott traps) | Dryad CC0 | 277,200 | 154 individuals x 60 traps x 6 sessions x 5 nights, 4 grids (`cluster_id`), `__traps` in UTM 55S; survey set inferred (trap usage not deposited); first E9 experimental SCR table |
| lazenby_2021_tasmania_ltmouse_scr | spatial capture-recapture (Elliott traps) | Dryad CC0 | 178,200 | 99 individuals, same grids and sessions; sibling table (one species per table, see below) |
| hamm_2013_satyr_ds | line-transect distance sampling, 1 m bins | Dryad CC0 | 625 | 125 transect walks on 5 days; transects not matched across days so each walk is a unit; endangered taxon, no coordinates deposited; first `distanceBreaks` table |
| raman_2024_nilgiris_birds_ds | community line-transect distance sampling, 7 bands | Zenodo CC0 | 15,295 | 8 transects x 1-4 visits (`period`), 115 taxa; sample table; coordinates coarsened (Vulnerable taxa); 5 of 1,491 detections dropped (beyond 100 m or no usable band); below floor |

What this batch says about the standard:

- **The IRW view needed a rule for `trap`.** E3 puts `trap` in the key but `eco_to_irw()`
  only renamed unit/taxon/y, so the first SCR table was blocked by irw-validate
  (`dup_id_item`) while conforming to the eco standard. Reported, not patched; eco-ff
  changed the view to `item = taxon:trap` (the "traps as items" reading) in both the
  Python and R copies. The standard should state this mapping in E9/E10.
- **E4.2 is written for site-unit tables.** With `unitKind = individual` every survey
  has one taxon row, so a two-species SCR table from one trapping grid fails
  `check_explicit_zero_taxa`. Split into one table per species; issue #20 asks for a
  clause note that E4.2 applies to `unitKind = site`.
- **SCR rows.** Each individual carries the full rectangle of its grid's traps x nights
  for all six sessions, including sessions without a capture, following the CJS
  tables' convention; a `secr` user filters to captured individual-sessions. The
  alternative (rows only for sessions with a capture) is cheaper and closer to a
  `capthist`; worth a ruling before more SCR tables.
- **Distance sampling fits the declared stretch as written.** `occasion` = bin,
  `y_raw` = the band label, `distanceBreaks` in metadata; nothing else needed. A
  community DS table (Nilgiris) is just the community rule applied to bins.
- **Two deposits are buildable only with the paper.** Smith & Goldberg (eDNA
  multi-scale, 168 sites x 3 samples x 3 qPCR reps) and Roy et al. (dependent
  double-observer, 28 attributed plots x 15 species) have no readme and no years;
  both papers are CC BY but the publisher returns 403 to the agent. Held with the
  exact questions in `queue/human_review.csv`; a PDF in hand unblocks both.
- **First design-landscape C hit:** Alisauskas & Conn (one transect, observer history
  x distance bin per group), row "two categorical axes on observation".

Held this batch (`queue/human_review.csv`): Lazenby camera-trap devils and cats
(camera effort not deposited, devil coordinates masked), Smith & Goldberg eDNA, Roy
dependent double-observer, Alisauskas & Conn double-observer.

## Batch 6 — 2026-11-01 (eDNA multi-scale and double-observer, unblocked by two PDFs)

Ben placed the two open-access papers the agent could not fetch in `queue/papers/`;
both held deposits from batch 5 were then built the same day. Validated with
`eco-validate`: 30/30 tables pass, IRW view conforms. Uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| smith_2019_greatbasin_csf_edna | multi-scale occupancy, eDNA (watershed > site > filter sample) | Dryad CC0 | 504 | 61 watersheds (`cluster_id`) x 2-8 sites x 3 samples; site and watershed covariates as deposited (definitions in the paper's appendix); the authors' Program MARK input |
| smith_2019_greatbasin_csf_qpcr | multi-scale occupancy with false positives (site > sample > qPCR replicate) | Dryad CC0 | 1,512 | 168 sites x 3 samples x 3 replicates; site-level visual/dipnet confirmation (occuFP code 2) as `unit_visual_dipnet_detected`; same sites as the table above but the deposit gives no key to join them |
| roy_2022_labrador_waterfowl_dobs | dependent double-observer (`multinomialType = dep_double_observer`) | Dryad CC0 | 810 | 27 helicopter plots x 15 species x 2 cells, June 2009; 24 plots without the protocol and one with an unattributed flock not shipped; below floor |

What this batch says about the standard:

- **Four nesting levels do not fit three.** The eDNA deposit is watershed > site >
  filter sample > qPCR replicate. E9's experimental mapping (`cluster_id`, `unit`,
  `occasion`) holds three, so the deposit became two tables at adjacent levels. A
  second grouping column (or `cluster_id` allowed to nest) would keep it as one;
  not needed yet, but eDNA deposits will do this often.
- **Confirmation surveys by a second method.** False-positive occupancy models
  (Miller et al. 2011, `occuFP`) pair ambiguous detections with a certain-detection
  method. The certain detection sits at the site level while the rows are qPCR
  replicates, so it is carried as a `unit_` covariate with an explicit note. The
  standard has no multi-method rule; `obs_method` on rows of one table is the
  alternative when both methods share a level. Logged for a ruling.
- **Covariates without definitions.** The deposit has no readme; column meanings
  come from the paper, and three classes (emergent vegetation, livestock, water-type
  flags) are defined only in its supplementary table, which the PDF does not include.
  Shipped under the deposited names with that caveat in the abstract.
- **Partial protocol coverage.** The double-observer deposit mixes plots with and
  without the protocol in one file; only the attributed plots are a `multinomial_cell`
  table, and one plot with a single unattributed flock was dropped rather than shipped
  with a hole (E4.2). The paper's 29 protocol plots versus the deposit's 28 attributed
  is recorded, not resolved.

Held: nothing new. Still open from batch 5: Lazenby camera-trap predators, Alisauskas &
Conn (design landscape C).


## Batch 7 — 2026-11-01 (queue pull: GBIF sampling-event, Dryad rar, Zenodo mixed-licence; BBS left to issue #24)

Four queue rows claimed, three built into four tables, one held. Validated with
`eco-validate`: 34/34 tables pass, IRW view conforms. BBS stays deferred to its own
project (issue #24, collaborator); not touched.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| sullivan_2026_powdermill_count | community counts (N-mixture), point counts, multi-season | GBIF sampling-event (CMNH IPT) CC BY 4.0 | 231,210 | 101 grid points x 13 years (2013-2025; 2014-15 partial) x 2 visits x 105 species; survey set = DwC event core with Humboldt extension declaring full Aves scope with abundance; time bins and distance circles are remarks only, so y = 10-min total; dropped UNWO (90), two implausible species (Streak-crowned Antvireo 2, Lucy's Warbler 1, code-mapping errors), 40 empty 'Absent' placeholder rows, one event with no locationID; YSFL->NOFL, SCJU->DEJU |
| kyaw_2024_myanmar_mamm_comm | community occupancy, camera traps | Dryad CC0 | 140,760 | 518 stations in 10 surveys / 6 protected areas (2014-2020) pooled by the authors; 46 of the paper's 47 species (moonrat has no pooled matrix); occasions indexed within survey, not calendar-aligned; no coordinates; 30 GEE covariates at 5 scales; PANGOLIN genus-level, BMONITOR is a reptile the authors kept |
| clipp_2024_monongahela_comm | community detection, camera-days (two-species deer/coyote design subsettable) | Zenodo CC BY 4.0 | 40,215 | 129 wildlife-opening cameras, Monongahela NF, WV, Apr-May 2019-21, 1,014 camera-days; all 35 species-level taxa shipped; 12 out-of-window records and 23 Unknown-class records dropped; no coordinates in source |
| clipp_2024_wvprivate_comm | community detection, camera-days (same design) | Zenodo CC BY 4.0 / rows CC BY-NC; derived CC BY-NC 4.0 | 419,240 | 146 private-land cameras in 3 WV county pairs, 2022, 8,774 camera-days, coordinates as published; 8 deployments beyond the paper's 138 shipped and marked in __units.modelled_in_paper; 265 out-of-window sequences (199 wrong camera year) dropped; 14 cameras dead at retrieval flagged |

What this batch says about the standard:

- **GBIF sampling-event datasets are a clean source.** The Humboldt extension's
  `isTaxonomicScopeFullyReported` / `isAbundanceReported` is exactly the evidence E4
  asks for and maps onto `surveyEvidence = sample_table`; worth naming in
  `processing_guide.md` as the GBIF rule (`isAbsenceReported = FALSE` means no
  explicit absence rows, not that zeros are unknowable). The R validator twin
  accepts only `Z` for ISO date-times and rejects `+00:00`; stricter than E8's text.
- **Evident source errors.** Two Powdermill records are species impossible for
  Pennsylvania (code-mapping slips). Dropped and recorded in `notShipped` rather
  than shipped as deposited; the standard has no "ship as deposited vs drop evident
  errors" rule. Needs a ruling.
- **Pooled multi-survey designs.** The Myanmar deposit pools ten surveys with
  different spacing and calendar windows into one matrix; `occasion = 1` is a
  different window in each survey. Shipped as one single-season table with
  `unit_survey` as a grouping covariate. Whether this should be `cluster_id`,
  `period`, or separate tables is not stated anywhere.
- **Mixed licences inside one deposit.** Zenodo says CC BY; the Wildlife Insights
  rows inside the zip say CC BY-NC per row. Split into two tables so the NC clause
  taints only one. A per-row licence column should count as the deposited licence
  in the intake policy. The same zip re-uploads all of Snapshot USA 2020; not hosted
  from here (third-party), but Snapshot USA belongs on the queue from its own source.
- **Personal names as unit ids.** The private-land deployment names are landowner
  surnames (e.g. `Haile-2 04/23/2022`) with exact coordinates on private property,
  as deposited. No flagged taxa, so no coarsening rule fires. Ben ruled the same day:
  `unit` is pseudonymised to `<county-pair>_<sheet row>` in the core table and `__units`;
  the names stay only in the cached deposit and in the script's source assertions.
  The standard still has no personal-data clause; worth one.
- **Continuous-time camera detections** were aggregated to camera-days with
  `obs_camera_hours` rather than shipped as the experimental `detection_event`
  type; minute timestamps survive only as `y_raw` counts.

Held this batch (`queue/human_review.csv`): NEON small mammals DP1.10072.001 (every
`/api/v0/data/` endpoint returns 403 without a free API token; build plan recorded;
the NEON ground-beetle row hits the same wall); Dryad NE China cattle-forest mammals
(deposit is the count of 14-day windows with a detection per station x species, an
aggregated binomial with no `responseType`). Looked at and left available: Borealis
boreal-bird harvest edges (Stan-input `.rds`, 34 species x 189 ARU transects, CC0,
buildable next batch).

## Batch 8 — 2026-11-01 (first robust-design and multi-state CR tables, from the new search)

Six tables from six deposits found by the 2026-11-01 repository search, built two at a
time. Validated with `eco-validate`: 40/40 tables pass, IRW view conforms. Uploaded to
the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| knape_2018_shoveler_count | N-mixture repeated counts | Zenodo CC BY 4.0 | 481 | 50 wetlands x up to 10 visits, one season, southern to east-central Sweden (RT90 northing only); 19 unsurveyed cells; Julian day per visit but no year, so obs_julian_day and no date; visit columns are not in calendar order; year and protocol are in the paywalled paper |
| chabanne_2017_perth_dolphin_msrd | multi-state closed robust design CR (state = capture site) | Dryad CC0 | 15,675 | 209 photo-identified Tursiops aduncus x 75 secondary occasions in 16 seasons (Jun 2011-May 2015), Perth; y = 0/SCR/CS-OA/GR; season layout of the unlabelled MARK columns inferred against the thesis effort table (summer 2011-12 has 4 of 5 completed occasions in the file), asserted by the no-within-season-transition rule and the thesis per-site counts; one duplicated id relabelled; 2-state Scenario 2 file not shipped (not a deterministic collapse) |
| oosthuizen_2019_marion_seal_rd | robust design capture-recapture (multievent), first in corpus | Dryad CC0 | 145,236 | 1,729 females tagged as pups at Marion Island, breeding seasons 1986-2013; the deposit's 8 composite event codes per seal year decomposed losslessly into 3 capture-period rows (uneven weeks, even weeks, moult+winter), y = seen, y_raw = event code; the 8 weekly surveys per season are not deposited; histories condition on first breeding encounter, leading zeros kept; no covariates, dates or coordinates |
| goldingay_2022_richmond_koala_dynocc | dynamic occupancy, spotlight transects | Dryad CC0 | 659 | 34 transects (20 in 2014 -> 34 in 2019) x 8 years x 3 surveys, Richmond Range NP, NSW; drought year 2019 in __periods; 7 habitat unit covariates; no coordinates; 2021 ARU koala data not shipped |
| goldingay_2022_richmond_glider_dynocc | dynamic occupancy, spotlight transects | Dryad CC0 | 655 | same surveys for Petauroides armillatus; the two matrices disagree on 22 surveyed cells (0 vs "-"), so two tables, not one community table; IUCN category left empty (assessed as P. volans s.l.) |
| dettling_2021_marin_riparian_count | community counts (N-mixture), point counts, multi-season | Dryad CC0 | 65,968 | 183 points on 13 riparian transects in Marin County protected areas, 1997-2019, 4,712 five-minute 50 m point counts x 14 selected species; survey set = the deposit's own point-visit list (every point-visit carries all 14 species with zeros); visit = chronological number within 1 May-30 June (1-3); no dates, observers or coordinates deposited; README says 17 species / 80,104 rows, file has 14 / 65,968 |

What this batch says about the standard (robust design is no longer a gap; these are the
rulings it wants):

- **Robust design fits as written.** `period` + `occasion` on `unitKind = individual`
  expressed both a multi-state closed robust design (dolphins) and a multievent one
  (seals) without a stretch. `ch_to_eco()` cannot build it (it puts the whole history on
  `period`); a `period` vector argument would make it serve robust designs.
- **`closure` should be enumerated.** It is free text; a robust design wants a controlled
  value ("closed within period, open between") so a reader can filter. A `designType`
  field would do the same.
- **Named occasions.** In both CR tables the secondaries are design categories (capture
  site season windows; uneven weeks / even weeks / moult), not interchangeable time
  replicates. Both scripts improvised an `occasionCodes` field in `__dataset.json`. Worth
  a named convention, since every robust design with labelled secondaries will need it.
- **Multievent histories decompose into occasions.** The seals' 8-letter event alphabet
  is the product of three per-window outcomes, so `detection` rows per window with the
  event code in `y_raw` keep both the robust-design shape and the multievent information;
  `responseType = state` would have forced an arbitrary integer on it. A sentence in E9
  allowing this when the alphabet is a product would make it reusable.
- **States that are places.** The dolphin state is the capture site. The standard has no
  way to say whether `stateCodes` are places, statuses or certainty levels; a `stateKind`
  field would.
- **Unlabelled MARK columns.** The dolphin file's 75 columns had to be assigned to seasons
  from the thesis effort table and asserted two ways. E4 could say that a layout
  recovered from the paper is `deposited_matrix` with a `surveyEvidenceNote`.
- **Non-identical NA patterns across species matrices: split, never fill.** Koala and
  glider share 34 sites and 24 columns but differ in 22 surveyed cells, so two tables.
  Same shape as ruling #20; a line in `processing_guide.md` would settle it.
- **Alternative codings of one history set are not derivable.** The dolphins' 2-state
  file is not a collapse of the 3-state one once the within-season rule has been applied.
  Only one is shipped; worth a line in `processing_guide.md`.
- **Julian day without a year.** Common in N-mixture deposits; E8 held (no bare
  day-of-year in `date`), but the fallback covariate name varies (`obs_julian_day` here,
  `obs_date_doy_std` in the mallard table). One name would help.
- **Explicit-zero species tables.** The Marin deposit has every species at every survey
  with no NA at all; it is `sample_table` in spirit but not literally a samples table.
  E4's table could name the case.
- Small: `data/aux/bird_alpha_codes.csv` lacks eight common western species (defined in
  the Marin script); `samplingProtocolCode` values `site_count` and `tag_resight` are
  new, the list is open-ended; a taxon split after an IUCN assessment (P. armillatus vs
  P. volans) has nowhere to say which name the category belongs to.

Held: nothing. Two paywalled papers (Knape 2018, Chabanne 2017 final version) would
sharpen the shoveler header (year, protocol); the dolphin build used the accepted
manuscript and the open thesis.

## Batch 9 — 2026-11-01 (false positives, disease states, open SCR; the aggregated-binomial question)

Five deposits from the 2026-11-01 search, two at a time; four tables built, one held.
Validated with `eco-validate`: 44/44 tables pass, IRW view conforms. Uploaded to the
Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| ferguson_2015_macon_bawa_fpocc | multi-state occupancy, false positives (occuFP type 2 / CP model) | Dryad CC0 | 816 | 272 point-count sites in Macon County, NC, 3 visits each in 2010 or 2011, Black-and-white Warbler only; y = 0/1/2 none / unconfirmed / confirmed from two deposited 0/1 columns (confirmed implies detected, asserted); 23 confirmed of 157 detections; coordinates are decimal degrees despite the README's UTM label; count duration, radius and the confirmation criterion are only in the paper (paywalled) |
| murray_2021_chicago_coyote_mange | multi-state dynamic occupancy (disease state), camera traps | Dryad CC0 | 32,898 | 115 Chicago-area stations x 16 seasons (2010-2014) x 28 days; y = 0/1/2 with 2 = a visible-mange image that day (127 days, 85 station-seasons); survey set = deposited daily operability flag; image-quality covariates per day; 285 images outside windows or on inactive days dropped as in the authors' code; UTM 16N -> WGS84 in-script; authors' weekly aggregation and PCA axes not shipped |
| hepler_2018_serengeti_gazelle_occ | single-season occupancy, camera traps (paper: spatio-temporal, one survey per 8-day season) | Dryad CC0 | 5,669 | 194 Snapshot Serengeti cameras x 46 consecutive 8-day windows, rows only where the camera ran >= 1 day (obs_camera_days); 878 detections; obs_ndvi, obs_rain_gt100mm (occasion-level), obs_fire, tree classes, river distance, coordinates as published; window dates and year not deposited, so no date |
| gardner_2018_nagarahole_tiger_oscr | open-population spatial capture-recapture (station-period counts with effort) | Dryad CC0 | 34,350 | 75 tigers x 458 surveyed station-periods, Nagarahole, 10 primary periods 1991-2000; per-day station activity not deposited (283/343 capture occasion indices exceed the station's active-day count), so no occasion: y = capture days per station-period, obs_trap_days_active = K_jt, the paper's own Binomial(p, K) observation model; __traps in author-centred local metres (EN taxon, masked by the source); period 7 occasion indices exceed its 33 days; station 188 absent. **Shipped as the test case for the aggregated-binomial ruling below; hold it if the ruling goes the other way** |

What this batch says about the standard:

- **The aggregated binomial needs a ruling (issue opened).** Four deposits now ship
  `y` as the number of occasions with a detection out of K surveyed, with no
  occasion-level history: NE China cattle-forest mammals (held, batch 7), Jhala tiger
  occupancy (queued, flagged), Rich et al. Botswana mammals (held, this batch), and the
  Nagarahole tigers, whose authors' own likelihood is Binomial(p, K_jt). Camera-trap
  deposits collapse nights to a count routinely. Two ways: declare `count` with a
  required `effortColumn` the aggregated-binomial form (what the tiger table does, and
  the validator could check y <= effort), or add `responseType = binomial_count` with
  an `obs_trials` column and no `occasion`. Until ruled, one table is in the draft and
  three deposits are held; the four should move together.
- **Two false-positive forms, one rule missing.** The standard has `detectionCertainty`
  (a second, certain method at another level: the eDNA table) and multi-state
  `stateCodes` (certainty within the same survey: Ferguson). The choice was clear but
  is not written; one sentence in E9 would fix it.
- **`y_raw` when `y` is a recode of two columns.** Ferguson (detected + confirmed) and
  Murray (any image + any mange image) both had no single recorded value behind `y`;
  both omit `y_raw` and carry the parts as covariates. The definition assumes one
  source column.
- **Sub-occasion observation layers.** The mange signal is per image with per-image
  quality covariates; one row per camera-day forces aggregates (count, mean, max), and
  the authors' exact model is not recoverable from the core table. Second instance
  after the eDNA qPCR table; `detection_event` rows or a side table are the options.
- **Occasion-level covariates have no prefix.** Rainfall in the gazelle table is
  constant within an occasion across all units; E5 has `unit_`, `period_`, `obs_`,
  `taxon_` but not `occasion_`, so it rides under `obs_`.
- **Where trap x period usage lives.** E10 puts usage in `__traps`, but it varies by
  period in the tiger table, so it is a core `obs_` column. The standard should say.
- **Non-geographic `crs`.** Author-centred metres have no EPSG code; a reserved value
  ("local") would make source-masked coordinates machine-readable.
- **`closure` enumeration** asked for a third time (open SCR is "open" only in free text).
- Same-shape small items: a per-occasion NA-means-inactive flag inside the detection
  file is `effort_table` in spirit but not a separate table (Murray; cf. the Marin
  `sample_table` note); the Hepler design is indistinguishable in the table from "one
  season, 46 occasions" although the paper treats each window as a season.

Held this batch: Rich et al. 2016 Botswana mammals (aggregated binomial, third instance;
coordinates already whole-degree, Diet and Size traits would ride in `__taxa`).

## Batch 10 — 2026-11-01 (ruling #34 lands: binomial counts; two SCR deposits; three single-species camera tables)

Seven deposits, eight tables (two from the fisher deposit), plus the Nagarahole tiger
table rebuilt under `binomial_count`. Validated with `eco-validate`: 51/51 tables
pass, IRW view conforms. Uploaded to the Redivis draft. Ben ruled #34 during the
batch (option 2: a new `responseType`); the standard, validator, R twin and converter
changed in commit 61c65e5 and the two deposits held for that shape were built the
same night.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| distiller_2020_cockscomb_jaguar_scr | spatial capture-recapture (closed, camera traps, continuous-time capable) | Dryad CC0 | 103,820 | 29 jaguars (19 M, 8 F, 2 unsexed) x 20 stations x 183 days, eastern Cockscomb Basin, Belize, Aug 2013-Feb 2014; survey set = deposited station x day operating matrix (3,580 of 3,660); 334 detections, photograph time kept in obs_capture_time; 31 individual-days at two stations; CAM16 never detected a jaguar; UTM 16N inferred (readme names no CRS); below floor (29 units) |
| bison_2024_montblanc_hare_dynocc | dynamic occupancy (seasonal), camera traps, single species | Dryad CC0 | 45,469 | 46 stations (1,227-2,740 m), Mont-Blanc massif, Sept 2017-June 2022; y per camera-day; survey set = setup to the abstract's study end (2022-06-30) minus 185 deposited downtime windows (22% of days), no end dates deposited; 13 in-downtime and 2 post-study contacts dropped; period = meteorological season (processor's binning; the authors' seasons and occasion length are in the unreachable paper), date per row; coordinates as published (LC); out_height / out_contact raw vegetation points not shipped |
| rich_2016_botswana_mamm_binom | community occupancy, binomial counts (responseType binomial_count, first under ruling #34) | Dryad CC0 | 9,724 | 221 stations in 3 blocks, northern Botswana, 15-33 nights each (6,607 trap nights) x 44 species; y = nights with a detection, obs_trials = nights surveyed, no occasion; six station covariates; diet and body-size traits in __taxa; exact station coordinates coarsened to 0.1 deg (wild dog, elephant EN; cheetah, lion, leopard, giraffe, hippo VU); survey year not in the deposit |
| feng_2021_nechina_mamm_binom | community occupancy, binomial counts (ruling #34) | Dryad CC0 | 2,484 | 138 stations x 18 species along the China-Russia border, NE China, 22,976 trap days; y = 14-day windows with a detection (0-12), obs_trials = windows surveyed (4-13); held in batch 7, built under #34; k is not a function of trap days (7 stations have k > ceiling(Days/14)), both shipped; human and cattle detection rates at the same cameras kept as disturbance covariates; no coordinates (Amur tiger EN, leopard, musk deer VU present); study year only in the unfetchable paper |
| gardner_2018_nagarahole_tiger_oscr (rebuilt) | open SCR, binomial counts | Dryad CC0 | 34,350 | responseType count -> binomial_count, obs_trap_days_active -> obs_trials; otherwise as batch 9 |
| bhattacharya_2022_himachal_bear_occ | single-season occupancy, camera traps (paper: spatial presence-absence model) | Dryad CC0 | 2,326 | 34 cameras in Rupi Bhaba WLS (2019, <= 49 days) + 33 in Daranghati WLS (2018, <= 40 days), one table with cluster_id = area; day_1 = first deployment day, NA suffix = camera stopped; 58 detections at 27 cameras; no coordinates or covariates deposited; survey years from the abstract only |
| burgar_2018_alberta_fisher_scr | spatial capture-recapture (closed, genetic hair snags) | Dryad CC0 | 6,144 | 24 fishers (15 F, 9 M) x 64 hair-snag sites x 4 occasions, Alberta 2016; secr edf + TDF, all sites used on all occasions; 43 detections; UTM zone not stated (12N inferred: Beaver Hills, east of Edmonton); paper behind a publisher bot wall, occasion dates not deposited; below floor (24 units) |
| burgar_2018_alberta_fisher_count | single-season camera detections (authors: spatial count, unmarked) | Dryad CC0 | 4,096 | 64 camera sites x 64 occasions in 2016, 180 detections at 37 sites; matrix is 0/1 only so shipped as detection; site ids 1-66 minus 11, 21 do not key to the SCR TDF, so no coordinates and no join; occasion length only in the unreachable paper |

What this batch says about the standard:

- **`binomial_count` worked end to end** on three deposits with no workaround: the R
  twin accepted it, the validator's new checks ran clean, the replication warning
  stayed quiet. Two follow-ups: `table_summary()` could report `n_trials =
  sum(obs_trials)` as the natural survey count, and the Rich coordinates turned out to
  be exact in the cells (the xlsx only displays whole degrees), so the batch 9 hold
  note was wrong and the table is coarsened.
- **Continuous-time SCR is group A, not a new family.** A per-row `date` plus
  `obs_capture_time` on detection rows carries the exact times; the occasion table and
  the continuous-time data are the same table. A named convention for the time column
  would keep camera tables consistent.
- **Paired marked / unmarked deposits.** The fisher deposit is the integrated-model
  shape (SCR plus unmarked counts of one population) but gives no site key between
  the halves. Two independent tables with cross-references; a `components` list in
  `__dataset.json` would express the pairing when a key exists.
- **CRS inferred from the coordinate range** twice (jaguar UTM 16N, fisher UTM 12N):
  `crs` carries the word "inferred"; a reserved qualifier would make it
  machine-readable. Also "local" for author-centred metres (tigers).
- **Deployment tables without end dates** (hare: setup plus downtime windows, end
  from the abstract) and **detections inside declared downtime** (13 dropped) have no
  guidance in E4 or the guide; `inferred` with a note was used.
- **Disjoint unit sets in different years** (bear: two sanctuaries, 2018 and 2019) are
  `cluster_id` + `unit_year`, not `period`; same question as #31.
- **Count vs detection when the matrix never exceeds 1** (fisher cameras): `detection`
  is the claim the data support; the standard could say so.
- **`closure` enumeration** asked for a fourth time (hare: a processor-imposed
  season binning should be visible without reading free text).
- Small: `samplingProtocolCode = hair_snag` new; `n_surveys` in `table_summary()` now
  counts `trap`, matching the metadata pipeline (it did not before, so every SCR
  table's summary was wrong); `floor_status()` takes the responseType.

Held: nothing. Unblocked by #34 and built: Feng (NE China), Rich (Botswana). Still on
the ruling: Jhala tiger occupancy (next batch).

## Batch 11 — 2026-11-01 (overnight: nine tables, binomial counts with periods, three capture-recapture designs)

Eight deposits, nine tables, built two at a time overnight. Validated with
`eco-validate`: 60/60 tables pass, IRW view conforms. Uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| koetke_2024_jprf_moose_count | N-mixture repeated counts, camera traps, single species | Dryad CC0 | 5,935 | 72 cameras x 91 days (2020-12-15 to 2021-03-15), John Prince Research Forest, BC; 617 inactive camera-days as missing rows (scattered gaps); y = independent detections under the 5-min criterion (170 at 44 cameras), obs_detections_30min / _8hr = the same videos under the coarser criteria; no coordinates or covariates; aerial SRB survey sheet not shipped |
| jhala_2024_india_tiger_binom | dynamic occupancy, binomial counts (ruling #34) | Zenodo CC BY 4.0 | 26,271 | 7,183 grid cells x 4 cycles (2006, 2010, 2014, 2018), 242,271 sign-survey replicates collapsed to counts (max 21 per cell-cycle); 566 / 1,295 / 600 / 0 cell-cycles unsurveyed; covariates are the authors' standardised values (no means deposited); dpat (distance to tiger-occupied PA, derived from the previous cycle's survey) not shipped; cooccurrence sheet (continuous indices) not shipped; Science paper paywalled, definitions from the sheet dictionary |
| khelifa_2021_seybouse_calexul_cjs | CJS capture-recapture, daily occasions, insect | Dryad CC0 | 7,825 | 313 adult Calopteryx exul x 25 sampling days (Julian 132-157, 153 not sampled), Seybouse River at El Fedjoudj, Algeria, 2011; 871 captures, 56.9% recaptured; unit_sex, period_water_depth_cm (the paper's recapture covariate); Julian-day origin not stated and the paper's campaign dates disagree, so no calendar date; site coordinate at 0.1 deg in geographicCoverage (EN) |
| blount_2025_neturkiye_carniv_count | community counts (N-mixture), camera traps, 2 species | Zenodo CC BY 4.0 | 7,080 | 229 deployments (216 with data) at 157 locations around Sarikamis NP, NE Turkiye, 2009-2023, up to 104 deployment-relative 7-day occasions; y = independent events per week; no row ids in the deposit, matrices aligned to the covariate sheet by row order; 13 deployments with no surveyed week; wolf/bear 0/1 files equal y > 0; paper totals exceed deposited sums |
| blount_2025_neturkiye_lynx_occ | single-season occupancy, camera traps | Zenodo CC BY 4.0 | 3,540 | lynx 0/1 on the same survey set (128 detection-weeks at 61 deployments); the lynx count matrix (215 x 472, no ids, two rows beyond 104 weeks) cannot be aligned and is not shipped, so lynx is detection, not count |
| hollanders_2022_brindle_mfleayi_msdis | multi-state (disease) robust design capture-recapture; authors' model is multievent with state uncertainty | Dryad CC0 | 1,624 | 116 juvenile Mixophyes fleayi x 14 surveyed weekly occasions in 8 primary periods, Brindle Creek, NSW; y = 0 / captured Bd-negative / captured Bd-positive from up to 4 qPCR runs per swab; obs_qpcr_runs, obs_qpcr_positive, obs_its_copies_mean carry the run level; 386 captures, 101 positive; two skipped secondaries as missing rows; no dates, coordinates or covariates deposited |
| obrist_2024_gooseisland_birds_count | community counts (N-mixture), point counts, single season | Zenodo CC BY 4.0 | 7,500 | 50 points on six islands of the Yalalii (Goose Island) Archipelago, BC, 3 ten-minute 100 m counts each, 12 May-2 June 2011, 50 species; y = detections in minutes 1-10 within 100 m, the authors' rule, reproducing all 204 summary-sheet cells; 710 detections outside the rule not shipped; dates are 1904-system Excel serials; 33 alpha codes defined in-script; coordinates as published (no flagged taxa) |
| murphy_2021_riogrande_otter_scr | spatial capture-recapture (closed, genetic scat sampling, dendritic network) | Dryad CC0 | 4,551 | 37 lenient-rule otters (30 conservative, carried as unit_conservative_id) x 20 latrines x 8 occasions, Feb-Apr 2018, Upper Rio Grande, NM; survey set = per-latrine usage string (123 of 160 latrine-occasions; Excel-dropped leading zeros restored); 69 detections from 76 samples, 32 recaptures = the paper's lenient count; one detection at unlisted latrine RGDB03 not shipped; sex by the paper's rule gives 17 M / 15 F / 5 U vs the paper's 17 / 18 / 2; authors' network-distance state space not shipped |
| valenzuela_2018_neltume_rhidar_rd | robust design capture-recapture; spatial CJS without detectors (search-encounter SCR) | Zenodo CC BY-SA 4.0 | 11,196 | 311 frogs at two Huilo Huilo plots (HUI1 192, HUI2 119), 16 quarterly primaries 2014-2017 of which 9 visited (the 7 all-NA primaries have no rows), 4 consecutive capture days each; 1,031 captures (6 half-coordinate cells counted as captures); obs_x_m / obs_y_m plot-local metres and obs_svl_mm on capture rows; no article named by the record (related: Proc B 2017, J Anim Ecol 2022); first CC BY-SA table |

What this batch says about the standard:

- **Alternative codings of one response.** Moose: three detection-independence
  thresholds on the same videos; shipped as `y` plus two `obs_` columns with a
  `covariateNote` that they are responses. Dolphins (2/3 states), Ferguson and Murray
  (two source columns), otters (two individual-assignment rules, nested so the finer
  is the unit) are the same family. Rule to write: ship the finest coding as `y`,
  alternatives as `y_alt_*` or a `responseVariants` list; when alternatives nest, the
  finer partition is the unit and the coarser a `unit_` covariate.
- **Sub-occasion observation layers, third instance.** Bd qPCR runs within a capture
  (frogs) after eDNA replicates and mange images. Summarised to a per-capture state
  plus run counts; the authors' multievent model needs the run level. `detection_event`
  rows or a `__observations` side table are the options; three deposits on one row is
  the threshold `design_landscape.md` sets for a family issue.
- **Search-encounter SCR has no detector key.** Per-capture coordinates ride as
  `obs_x_m` / `obs_y_m` on detection rows (Darwin's frog). design_landscape.md should
  list it beside the `__traps` form.
- **Lagged covariates derived from the response** (Jhala `dpat`: distance to the
  previous cycle's occupied area) were dropped as data-derived; one sentence in the
  guide would settle whether lagged derivations count as model outputs.
- **Standardised-only covariates** (Jhala) have no stated status; shipped as deposited
  with a note.
- **Row-order alignment with no ids** (Türkiye): accepted when row counts match and
  all-NA rows are explicable, held otherwise (lynx counts). Worth naming in the guide.
- **Mixed response types in one deposit** (Türkiye: counts for two species, 0/1 for
  the third) force two tables on one survey set; a `components` cross-reference again.
- **Period gaps.** Darwin's frog keeps the unvisited primaries' indices so spacing
  survives; E8 should say gaps in `period` are allowed and meaningful.
- **No-date deposits**, fourth and fifth instances (Calopteryx Julian days with no
  origin, frogs with none): E8 held each time; a named fallback (`obs_day_index`) would
  keep tables consistent.
- **Single-site coordinates** for individual-unit tables have no machine-readable home
  (Calopteryx, Darwin's frog: text in `geographicCoverage` at 0.1 degree); a
  `siteCoordinates` metadata field would.
- **`crs` inferred from the coordinate range** a third and fourth time (otters 13N);
  "local" for plot metres again.
- **`data/aux/bird_alpha_codes.csv`** is missing dozens of western and shorebird codes
  (Goose Island defined 33 in-script, Marin 8); replace with the full IBP-AOS list.
- New `samplingProtocolCode` values: `sign_survey`, `hand_capture`, `scat_genotyping`.

Held: nothing.

## Batch 12 — 2026-11-01 (overnight: multi-scale snow tracks, time-to-detection, distance sampling by three methods, two long-term seal and goose studies)

Seven deposits, eleven tables. Validated with `eco-validate`: 69/69 tables pass, IRW
view conforms. Uploaded to the Redivis draft. Snapshot USA 2019-2023 is building and
will close with the next batch.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| whittington_2015_banff_tracks_comm | community occupancy, multi-scale (cell > segment > repeat walk), snow tracks | Dryad CC0 | 6,104 | 7 species x 872 segment-dates on 443 segments / 43 transects / 39 hexagonal 100 km2 cells, Banff NP, 2011-11-19 to 2012-04-09; cluster_id = cell (the paper's occupancy unit), unit = segment (spatial replicate), occasion = repeat walk (266 segments once, 177 up to 14x); obs_days_snow differs for ungulates vs carnivores within a survey; deer at genus rank; UTM 11N -> WGS84; authors' Markov lag columns (functions of y) not shipped |
| henry_2020_karoo_birds_comm | community occupancy, point counts (DND view of a time-to-detection study) | Dryad CC0 | 66,465 | 61 SABAP pentads x 10-20 point counts (1,055) x 63 species, Karoo, South Africa, Feb-Oct 2017; y = detected on the count; obs_ttd_s = seconds to first detection (NA = censored at the count's end, ~10 min, not deposited), obs_distance_m, detection mode and behaviour per species-count; survey set = counts with a detection (row_presence); ttd in seconds not minutes, floored at 10 s; pentad centroid as unit coordinate, count GPS as obs_ |
| riecke_2018_tutakoke_brant_rd | robust design capture-recapture (survival, breeding probability, temporary emigration) | Dryad CC0 | 635,445 | 7,845 females at the Tutakoke River colony, Y-K Delta, Alaska, 27 seasons 1988-2014 x 3 capture methods (nest searches, tower resighting, banding drives); built from the deposited R workspace's obs array; 22,510 detections; leading zeros kept (model conditions on first); gosling tarsus for 713 of 2,327 gosling-banded birds; authors' yes/total aggregates differ from the histories by 1-2 per cell; raw banding database (42k x 1,016) not shipped |
| bedson_2021_holmemoss_hare_vis_ds | distance sampling (line transect) | Dryad CC0 | 30 | 6 site walks (4.6-8.2 km) at Holme Moss, Peak District, Nov 2017-May 2018, 41 detections (43 hares); perpendicular distances to the metre binned at the paper's 5/10/20/100 m plus one 100-400 m bin so the 15 detections beyond the paper's 100 m truncation ship; obs_individuals per bin; no dates or coordinates; below floor (6 units) |
| bedson_2021_holmemoss_hare_therm_ds | distance sampling (point transect, thermal imager) | Dryad CC0 | 912 | 71 vantage points x 1-3 night visits = 114 units at six sites, 206 detections (285 hares, clusters to 8); visit = maximal run of same-point rows, matching the paper's replicates per site exactly; radial distances binned at 50 m to the paper's 350 m truncation plus 350-750 m (54 detections); four empty rows inside detection runs carry nothing |
| bedson_2021_holmemoss_hare_cam_ds | camera-trap distance sampling (snapshot 1 s, FOV 42 deg), first CTDS table | Dryad CC0 | 1,092 | 91 cameras (12-16 per site, deployed site by site 2-5 weeks each), 3,706 night-time snapshot detections (paper: 3,705; site 5 474 vs 479; 76 vs 77 detecting cameras) in whole-metre radial distances 1-12 taken as 1 m bins; paper truncated at 5 m with bins 1, 2, 3-4, 5 (n = 3,506 asserted); unit_effort_seconds as deposited (paper scales by 42/360); snapshotInterval and fieldOfViewDegrees in metadata; camera 53249 lacks the empty row the other 90 have |
| volzke_2021_macquarie_seal1950s_cjs | CJS / multi-state capture-recapture, tag-resight, two windows per year | Dryad CC0 | 391,612 | 7,531 seals branded as weaners 1951-1965 at Macquarie Island, 31 seal years 1951-1985 x 2 windows (Sept-Oct breeding; Nov-Aug); organised island searches 1952 and 1959, opportunistic sightings after; survey set inferred (window surveyed iff any study seal sighted), sparse years 1969-1985 flagged in __periods; tag type not recorded for this study |
| volzke_2021_macquarie_seal1990s_cjs | CJS / multi-state capture-recapture, tag-resight, two windows per year | Dryad CC0 | 1,083,889 | 18,371 seals marked as weaners 1984-2005 (mostly 1993-2000), 32 seal years 1984-2019 x 2 windows; daily isthmus and monthly island searches 1993-2001, declining to ad hoc after 2010; 2,275 seals first seen past the pup stage not units; same study split as the 2021 paper's 1990s period; second-largest table in the corpus |
| lebeuftaylor_2026_boreal_edges_aru_comm | community occupancy, acoustic recorders, harvest-edge design (cluster_id = transect) | Borealis CC0 | 55,318 | 564 ARU locations at 3 positions (150 m into regen / edge / 150 m into forest) on 189 transects, boreal Alberta, 1-5 visits per location, 34 species, 5,130 detections within 150 m; built from the authors' Stan input; visit day and time only as z-scores; survey year, dates and recording length not deposited; paper in prep (no DOI); 25-species radius files and Hill-number max counts not shipped |

What this batch says about the standard:

- **Time-to-detection carried as a covariate** (Karoo): `obs_ttd_s` on species rows,
  NA = censored at a count length that is not deposited. First TTD deposit; a
  `responseType = time_to_event` with `obs_censored`, or a declared `obs_` convention
  plus a `surveyDuration` field, would make it reusable. Also: `obs_decimalLatitude`
  (a survey-level GPS finer than the unit) is not recognised by the validator's
  coordinate regex, so E7 coarsening would not fire on it for a flagged taxon. **Gap
  in `eco-validate`**, no table affected tonight.
- **Binning continuous distances is a processing decision E9 does not name.** Two of
  the three hare files deposit exact metres; the processor chose breaks (the paper's
  where they exist) and added an outer bin so nothing is dropped (Nilgiris dropped
  beyond-truncation detections instead). Either name that rule, or let unbinned
  deposits ship exact distances as `obs_distance_m` on `detection_event` rows. Camera
  trap DS fits as declared but needs `fieldOfViewDegrees` beside `snapshotInterval`.
- **Occasions as named windows / methods**, third and fourth robust-design tables
  (brant: nest / tower / banding; seals: breeding / rest of year); `occasionCodes` is
  still ad hoc.
- **Inferred survey sets from long resighting records** (seals): "a window is
  surveyed iff some marked animal was seen" admits windows with one sighting; a
  period-level effort convention would let a user filter.
- **One deposit, two studies** with disjoint cohorts and seasons (seals): split, the
  temporal form of #31.
- **Analysis-ready inputs as deposits** (boreal ARU Stan list, brant RData): dates
  survive only as z-scores, year not deposited; `covariateNote` should be a named E10
  field, and `temporalCoverage` could allow an explicit "not deposited".
- **Covariates defined for a subset by design** (gosling tarsus): NA with a note;
  unstated but right.
- **Spatial replicates nested in the occupancy unit** (Banff) fit the eDNA multi-scale
  mapping exactly; the same table also reads as single-scale on segments; only
  `designNote` says which; the enumerated design field again. An `obs_` covariate that
  legitimately differs across taxa within a survey (days since snow by species group)
  is allowed by E5 and now has an example.
- Multi-state breeding histories (seals' per-sighting status) are rebuildable but not
  shipped; assigning one state per window from many sightings needs a rule.

Held: nothing.

## Batch 13 — 2026-11-01 (overnight: the two national schemes, textbook spOccupancy sets, a six-species SCR array)

Four deposits, eleven tables; the queue's buildable rows are now exhausted. Validated with
`eco-validate`: 79/79 tables pass, IRW view conforms. Uploaded to the Redivis draft.
Two core CSVs (Snapshot USA 548 MB, Swedish Bird Survey 348 MB) exceed GitHub's file
limit and are listed in `.gitignore`; their scripts rebuild them and CI runs the scripts.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| rooney_2025_snapshotusa_comm | community detection, camera-weeks, annual national survey | Dryad CC0 | 5,148,834 | 9,694 deployments (263 arrays, 6,712 sites, 50 states) x 1-21 weeks x 87 mammal species (>= 50 sequences; 43 rarer mammals, 225 birds, humans, vehicles and higher-rank labels not shipped); survey set = deployment start/end dates (381,673 camera-days); 126,471 detection-weeks; coordinates coarsened to 0.1 deg (red wolf CR, giant kangaroo rat EN); Sequence_ID NA on 223 deployments, keyed by start time; built from Dryad version 3 (2025-01-03) because version 6 is token-gated; largest table in the corpus (548 MB) |
| lindstrom_2025_sweden_summerpoints_count | repeated-count index (route totals, one count per route-year), multi-species, 50 years | GBIF sampling-event CC0 | 2,972,970 | 11,011 route counts on 1,256 free-choice routes across Sweden, 1975-2024, x 270 taxa (269 species + Loxia); y = sum over 20 five-minute points (point level not deposited); survey set = event core with protocol-stated completeness and noObservations = false everywhere; eleven security-class-4 species withheld by the publisher (no rows, not zeros); coordinates are 25 x 25 km grid centres as published; 712 pseudonymous observers; 348 MB |
| doser_2022_hbef_trends_dynocc | dynamic community occupancy, point counts, textbook (spOccupancy) | R package GPL-3 | 105,240 | 12 species x 373 plots x 2010-2018 x up to 3 replicates, Hubbard Brook Valleywide Bird Survey subset (the EDI deposit edi.348 is behind an access wall); 8,770 surveyed plot-year-replicates, 273 plot-years unsurveyed; 45 covariate-only cells not surveyed; hbef2015 is the identical 2015 slice and is not shipped separately; UTM 19N as published plus WGS84 |
| doser_2022_neon2015_removal | community time-removal (multinomial_cell, removal), textbook (spOccupancy) | R package GPL-3 | 2,880 | 12 species x 80 NEON Bartlett sites, one 6-min count in three 2-min intervals, June 2015; the package's NA-after-detection encoding shipped as 0 (asserted removal structure); 252 detections, BLPW and NAWA all-zero; elevation, day, start hour, coordinates |
| curveirasantos_2026_phinda_leopard_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 214,560 | 48 leopards x 4,470 surveyed camera-days (100 sites, 117 days, Sept 2021-Jan 2022), Munywana Conservancy, KwaZulu-Natal; two-stage optimised design (60 leopard + 40 small-carnivore cameras); trap coordinates processor-centred (VU); flank profile per individual (11 single-flank ids) |
| curveirasantos_2026_phinda_cheetah_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 26,820 | 6 cheetahs (2 coalitions), 20 detections; below floor; sibling of the leopard table |
| curveirasantos_2026_phinda_lion_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 93,870 | 21 lions in 6 prides/coalitions, 138 detection-days from 141 records (y_raw); below floor |
| curveirasantos_2026_phinda_hyena_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 227,970 | 51 spotted hyaenas, 195 detections; 21 single-flank ids |
| curveirasantos_2026_phinda_genet_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 1,345,470 | 301 genet ids (genus rank; species not named in the deposit), 614 detections; 237 single-flank ids, so ids may duplicate animals; largest of the six |
| curveirasantos_2026_phinda_serval_scr | spatial capture-recapture (closed, camera traps) | OSF CC BY 4.0 | 49,170 | 11 servals, 33 detections; below floor |

What this batch says about the standard:

- **E7 and SCR arrays of flagged taxa conflict.** Coarsening 100 cameras to 0.1 degree
  cells destroys the inter-trap distances the likelihood needs. The Phinda tables carry
  processor-centred local metres (the Nagarahole deposit was source-centred); E7 should
  name centring as the SCR coarsening form, and the validator should look at `__traps`
  coordinates at all (it checks only the core and `__units`). **Gap in `eco-validate`.**
- **Whole-array coarsening for two rare taxa** (Snapshot USA: 9,694 cameras lose
  precision for 339 red wolf and kangaroo rat sequences) is the other side of the same
  coin; dropping the flagged taxa and keeping exact coordinates is arguably more useful.
  E7 could say which to prefer for large multi-taxon tables.
- **Taxa withheld by the source are not zeros** (Swedish Bird Survey's eleven
  security-class species). The community rule would read their absence as zero; a
  `taxaWithheld` metadata field or a `__taxa` row flagged `withheld` with no core rows is
  needed for national schemes.
- **Token-gated repository versions.** Dryad gates per-file downloads and the latest
  version's zip for Snapshot USA; built from the newest anonymously served version and
  recorded. The guide should say so.
- **Processor-chosen aggregation and taxon cuts** (Snapshot: weeks, >= 50 sequences):
  `occasionLength` and `notShipped` carry them; `taxonInclusionRule` would make the cut
  visible.
- **No within-year replication** (Swedish routes: the 20 stops are summed by the source):
  the table is an annual index; `closure` is the only place that says detection is not
  estimable within a year. Enumerated closure, again.
- **Nested package objects ship once** (hbef2015 is the 2015 slice of hbefTrends);
  **removal encoding is not non-survey** (neon2015's NA after first detection); a survey
  with covariates but no observation is not surveyed (45 trends cells). Three sentences
  for the guide.
- **Single-flank individual ids** in camera SCR may be the same animal;
  `unit_flank_profile` lets a user filter; a named convention would serve partial-identity
  models.
- Sibling tables from one deposit (six Phinda SCR tables, two seal studies, two Türkiye
  tables, fisher pair) keep asking for a `components` cross-reference field.
- Oversize core tables: first two above GitHub's limit; `.gitignore` rule and a
  `data/README.md` note. The Redivis upload handled 548 MB.

Held this batch: black lion tamarin camera traps (OSF 8rw4t, no licence on the project).
Queue state after batch 13: every Dryad, Zenodo, Dataverse, GBIF, OSF and package row
is built or held; NEON rows wait on a token, eBird is gated, the "all GBIF
sampling-event datasets" row is a search pointer, not a deposit.

## Batch 14 — 2026-11-02 (NEON: the first token-gated agency source; three products, eight tables)

Three NEON Terrestrial Observation System products from `RELEASE-2026`, all sites and
months, built in a worktree (branch `neon-tables`) while the main checkout carried the
traits vignette. New in `lib/`: `download_neon()` and `headers`/`subdir` arguments on
`download_cached()`; the API token is read from `NEON_TOKEN` and never stored.
`rebuild.yml` passes a `NEON_TOKEN` secret, which the repository still needs. Licence is
CC BY 4.0 (NEON Data API docs; the queue had said CC0, corrected). Validated with
`eco-validate`: 87/87 tables pass, IRW view conforms. Four core CSVs over 100 MB are in
`.gitignore` and rebuilt by their scripts.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| neon_2026_landbirds_count | repeated counts, multi-species, national | NEON DP1.10003.001 CC BY 4.0 | 7,460,729 | 26,363 six-minute point counts at 3,434 points (47 sites) x 2 bouts x 2013-2024 x 283 species (>= 100 clusters; 261 rarer species and every higher-rank "fuzzed" id not shipped); clusters counted once; minute-88 detections dropped; point covariates in `__units`; NEON publishes grid centres for the nine points of a grid; 583 MB, gitignored |
| neon_2026_landbirds_ds | distance sampling, binned (multinomial_cell) | NEON DP1.10003.001 CC BY 4.0 | 4,850,792 | same counts, four radial bins (0-25-50-100-1000 m), 46 common species (>= 2,000 clusters); period = count event (year x bout), occasion = bin; removal minutes not carried; detection_event could not hold multi-species per-detection rows (see below); 433 MB, gitignored |
| neon_2026_smallmammals_count | robust-design counts, community | NEON DP1.10072.001 CC BY 4.0 | 2,531,672 | 17,704 surveyed grid-nights on 332 grids (46 sites), 1,612 bouts, 143 species; y = distinct individuals per night; traps set as effort; `__taxa` carries `taxon_sites`; Podomys floridanus (VU) among taxa, coordinates are NEON plot centres as published; 304 MB, gitignored |
| neon_2026_perman_rd | robust design, individual | NEON DP1.10072.001 CC BY 4.0 | 758,231 | 17,503 Peromyscus maniculatus, from first-capture bout to last surveyed bout at the home grid; 640 off-grid captures dropped |
| neon_2026_perleu_rd | robust design, individual | NEON DP1.10072.001 CC BY 4.0 | 617,561 | 13,647 Peromyscus leucopus |
| neon_2026_sighis_rd | robust design, individual | NEON DP1.10072.001 CC BY 4.0 | 203,621 | 4,474 Sigmodon hispidus |
| neon_2026_micpen_rd | robust design, individual | NEON DP1.10072.001 CC BY 4.0 | 171,464 | 3,435 Microtus pennsylvanicus; the other 101 marked species (34,491 individuals) in notShipped |
| neon_2026_carabids_count | repeated counts, community, pitfall | NEON DP1.10022.001 CC BY 4.0 | 5,976,135 | 108,657 collected pitfall samples at 2,029 traps (47 sites) x 2013-2023 x up to 17 bouts x 55 carabid species (>= 1,000 individuals; 73% of individuals; 644 species not shipped); sorting-level ids (parataxonomist changes 2.8%, expert changes 22.2% of pinned specimens, not applied); trappingDays as effort, outliers kept as published; 354 MB, gitignored |

What this batch says about the standard:

- **National species pools are the main strain.** E4.2 forces one taxon set per table,
  so a 47-site scheme ships a national rectangle full of structural zeros, and the row
  budget then forces severe species cuts (carabids: 55 of 699 species; at a site-level
  pool roughly 200 would fit). The processing guide's answer (split by region) would
  mean 47 tables per product. A declared grouping column for the pool, or a
  `taxon_sites` column in `__taxa` that the validator honours, is the request. The
  small-mammal table already carries `taxon_sites`.
- **`detection_event` cannot hold multi-species per-detection data**: several detections
  of one species in one count collide on the E3 key, and a detection index on
  `occasion` fails E4.2. Either add a detection index to the key or state that the type
  is single-species.
- **Ruling #20 on a national capture-recapture product** gives one table per species
  (105 here). This batch shipped the four with the most individuals, named
  `neon_2026_<gen3><spe3>_rd`, from one script; a convention for how many and how to
  name them is needed.
- **Sibling tables with different period definitions** (landbirds: year in the count
  table, year x bout in the distance table) and **sibling `__periods` files that are
  subsets** (rd tables carry only their bouts, with the count table's indices). Whether
  siblings must share period definitions is unstated; the `components` cross-reference
  from batch 8 would carry it.
- **Source-side taxon fuzzing**: NEON coarsens species of concern to higher rank and
  withholds some at GRSM. Same need as batch 13's `taxaWithheld`.
- **Identification layers**: which layer `y` uses when the source re-identifies a subset
  at higher authority, and whether the disagreement rate belongs in `__dataset.json`.
- **Effort outliers** far above protocol (pitfall trappingDays up to 245): kept as
  published; the guide could say whether such a sample is a survey.
- **Distance binning chosen by the processor** again (batch 12 asked the same).

Held: nothing. Queue: NEON rows built; remaining rows are eBird (gated), the GBIF
sampling-event search pointer, the tamarin OSF deposit (no licence) and BBS (#24).

## Batch 15 — 2026-11-02 (gap-targeted search: the first reptiles, ten fish and salamander tables, live-dead, removal and misidentification designs)

A Dryad search aimed at the corpus's gaps (no reptiles, one fish table, few
invertebrates; dead recovery, double-observer, removal, misidentification) returned
389 unseen deposits; 25 were queued, 26 tables built from 22 of them in a worktree
(branch `batch15`). Validated with `eco-validate`: 113/113 tables pass, IRW view
conforms. Uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| tetzlaff_2026_crotalus_cjs | CJS | Dryad CC0 | 18,382 | 707 adult female timber rattlesnakes, New York, 26 years (1983-2019) from the deposited MARK file; den group in `unit_den`; interval lengths and annual covariates (real scale) in `__periods`; first reptile table |
| cecala_2026_kiawah_terrapin_cjs | CJS | Dryad CC0 | 43,484 | 1,553 diamondback terrapins, Kiawah River SC, 1983-2012, annual histories from capture records; 2000-2001 have no records and no rows (survey years inferred); crab-pot recoveries kept as captures, counted in `obs_n_crabtrap` |
| karvemo_2024_nacka_grasssnake_cjs | CJS | Dryad CC0 | 73,458 | 1,113 grass snakes, Nacka, Sweden, 66 years; survey years inferred from records; authors' winter-survival estimates not shipped (model output); maximum snow cover in `__periods` |
| doyle_2025_chinalake_tortoise_scr | SCR (search tracks) | Dryad CC0 | 45,936 | 24 Mojave desert tortoises x 548 50-m search cells x 4 days; effort 0-5 per cell-day; detectors centred to local metres (IUCN CR); below floor |
| ahizi_2021_civ_crocodylians_occ | community occupancy (spotlight) | Dryad CC0 | 390 | 2 crocodylian taxa x 42 sites x 5 nights, Ivory Coast; four of the paper's 38 sites deposited as interior/exterior sections; encounter-rate and wariness files not shipped (derived ratios) |
| yadav_2022_rapti_gharial_count | N-mixture repeated counts | Dryad CC0 | 54 | gharial (CR), 18 river segments x 3 counts, Rapti River, Chitwan; below floor |
| moe_2020_hunder_trout_ld | live-dead (Burnham), state-coded | Dryad CC0 | 212,855 | 13,975 Hunder brown trout, Norway, 1966-2015; first live-dead table: state 0 none / 1 live / 2 dead recovery / 3 both, `y_raw` = the pair; recovery interval 1 July t to 30 June t+1; three recoveries moved after the last live capture |
| banik_2025_dollyvarden_ms | multistate CR | Dryad CC0 | 228,657 | 21,430 anadromous Dolly Varden, five Yukon rivers in one table (`unit_river`), 14 autumns, breeding state; Rat River uses the breeding matrix where the capture-only matrix disagrees in 10 cells |
| tomke_2025_hellbender_edna | multi-scale occupancy (eDNA) | Dryad CC0 | 3,462 | Eastern Hellbender (a salamander, not a fish), 385 filters at 90 sites, qPCR replicates; the 80- and 45-site files are subsets, not shipped |
| swedberg_2023_springfish_occ | multi-scale community occupancy | Dryad CC0 | 3,312 | six target spring-associated fishes x 153 sites in 61 reaches, Oklahoma; ten non-target darters with reach-specific lists not shipped (E4.2); two ID keys repaired |
| kanno_2022_bluehead_chub_cjs | CJS (2-month intervals) | Dryad CC0 | 6,435 | 429 bluehead chub, 15 occasions; PIT ids destroyed in the deposit (scientific notation), `Obs_ID` is the key; one of three sibling tables (ruling #20) |
| kanno_2022_creek_chub_cjs | CJS (2-month intervals) | Dryad CC0 | 9,960 | 664 creek chub; sibling |
| kanno_2022_mottled_sculpin_cjs | CJS (2-month intervals) | Dryad CC0 | 13,920 | 928 mottled sculpin; sibling |
| lafferty_2024_tidewatergoby_edna | multi-method detection (qPCR, metabarcoding; seine as covariate) | Dryad CC0 | 308 | tidewater goby (ESA endangered), 78 filters at 16 estuaries; qPCR presence = >100 reads (`y_raw` reads), metabarcoding as occasion 4; coordinates coarsened to 0.1 degree |
| lafferty_2024_estuaryfish_mb | community detection (metabarcoding) | Dryad CC0 | 1,258 | 17 estuarine fishes x 14 sites; Estuary column misaligned for 45 of 74 filters, joined on sample ID; below floor |
| hartley_2024_cpraealtus_occ | dynamic occupancy (transects) | Dryad CC0 | 1,404 | alpine she-oak skink (endangered), 113 transects x 4 seasons x up to 8 surveys; paired transects sharing a site id split by elevation; occasion = date order |
| smith_2024_florida_tegu_dynocc | dynamic occupancy (cameras) | Dryad CC0 | 4,527 | Argentine tegu (invasive), 87 cameras x 4 years x 19 windows; bait matrix row order asserted; live-trap capture rate as `period_` covariate |
| samek_2024_racerunner_occ | single-season occupancy | Dryad CC0 | 300 | six-lined racerunner, 100 longleaf pine transects x 3 surveys |
| boone_2023_minnesota_bombus_count | community repeated counts | Dryad CC0 | 1,815 | 15 Bombus identification classes (two are species groups) x 25 sites x 5 surveys, Minnesota 2021; coordinates coarsened (B. affinis endangered); first insect community table; below floor |
| chambert_2018_plethodon_fpocc | two-species occupancy with misidentification | Dryad CC0 | 1,360 | 2 Plethodon salamanders x 131 sites x 4 years; joint field state split into per-species rows, `y_raw` = joint code; DNA confirmation in `obs_dna_state` |
| teitsworth_2026_necturus_dynocc | dynamic occupancy | Dryad CC0 | 1,341 | Neuse River waterdog (ESA threatened), 176 sites x 5 study years (calendar years not deposited) x 4 visits; keyless yearly covariates assigned in unmarked order (flagged for author confirmation) |
| price_2018_mtr_salamanders_count | dynamic N-mixture, species x life-stage items | Dryad CC0 | 1,610 | 7 species-stage items x 23 stream reaches x 3 years under mountaintop removal mining; no codebook, item reading documented; years not deposited; below floor |
| tumursukh_2016_tost_ibex_dobs | double-observer (independent), group as unit | Dryad CC0 | 801 | 267 Siberian ibex groups x cells 10/01/11, Tost, Mongolia 2012-2013; no spatial unit deposited |
| tumursukh_2016_tost_argali_dobs | double-observer (independent), group as unit | Dryad CC0 | 99 | 33 argali groups; sibling |
| davis_2016_feralswine_removal | removal (aerial passes) | Dryad CC0 | 177 | feral swine, 49 properties x 9 years x 3 helicopter passes, Oklahoma and Texas; helicopter hours as effort; five episodes exceed the authors' closure guidance, kept and noted |
| dougherty_2016_rustycrayfish_edna | multi-method detection (qPCR + baited trap), multi-scale | Dryad CC0 | 732 | rusty crayfish (invasive), 261 trap locations in 12 lakes; occasions 1-4 qPCR, 5 baited trap; other crayfish catches as `obs_` |

Held: the DOAS mountain-ungulate deposit (simulation output, no field data); the
Brownie deer and turkey deposit (SURVIV model code in .docx, no data table). Not built:
the Kasumigaura fish metabarcoding deposit (Dryad returned HTTP 429 on its version zip
for over 20 minutes; queue row still `available`).

Fixed while closing: three tables wrote `coordinatesCoarsened` as a string rather than
the `{value, method}` object, which crashed `metadata/01_metadata.R`; neither validator
checks the field's shape. The tortoise design tag used "Single-session", outside the
vocabulary. Issue #38 filed for doubled level prefixes (`unit_unit_*`), which both
validators accepted and three reptile tables briefly carried.

What this batch says about the standard:

- **Live-dead designs** have no named E2 convention. The trout table encodes the
  Burnham pair as `state` 0-3 with the pair in `y_raw`; the rule placing a recovery in
  its interval is the processor's, and Barker-style resightings have no cell.
  Aggregated Brownie arrays (cohort x recovery year) have no stated home at all.
- **Method as a design dimension.** Three tables (goby, crayfish, and the springfish
  gear covariate) put different detection processes on `occasion` with
  `occasionCodes` and `obs_method`. A convention is needed: occasion, a `method`
  key column, or separate tables.
- **Survey years inferred from capture records** in long-term single-collector studies
  (terrapin, grass snake): a year without records may be a surveyed year with no
  captures.
- **Double-observer data deposited per group** with no spatial unit: group-as-unit
  works but pushes a site design into `unitKind individual` and one table per species.
- **Search-track SCR** (tortoise): detectors are cells built from surveyor tracks with
  an effort category; E9's SCR note assumes fixed traps.
- **Deposits without calendar years** (waterdog, mining salamanders) and **keyless
  covariate files** whose row order follows a package convention (unmarked
  `yearlySiteCovs`): the guide should say how to state a relative time frame and
  whether to ship covariates on the authors' stated order.
- **Life stage as part of the taxon item** (springfish, mining salamanders):
  `taxon_life_stage` should be named in E5 or E6.
- **Recorded identification classes as taxa** (bumble bees: overlapping species and
  species-group classes): a zero for one class is not an absence of the species.
- **Reach-level species lists** fail E4.2 (springfish non-targets): the national-pool
  strain of batch 14 at small scale.
- **Deposits that destroy keys** (PIT ids in scientific notation, a misaligned column):
  the guide could say how to record repairs.
- **Validator gaps**: doubled prefixes (#38); `coordinatesCoarsened` shape not checked.
- **IRW rights-register false positive**: species code ASPSEX matched a questionnaire
  code; the register needs a taxon exemption.
- **Sampling-protocol vocabulary**: `hand_capture`, `net_capture`, `transect_search`,
  `spotlight_survey`, `boat_count`, `cover_board`, `timed_search`, `visual_encounter`,
  `baited_trap`, `cover_object_search` should be listed in `tags/vocab.md`.

## Batch 16 — 2026-11-02 (the first plant tables; invertebrate and marine gap search)

A search aimed at invertebrates, plants and marine taxa (issue #40) inspected 100
unseen deposits (`discovery_log.csv`) and queued 69. Ben ruled plants in scope (E9,
2026-11-02). Sixteen tables were built from eight deposits in a worktree (branch
`search-2026-11-02`); all Dryad zips came from the search's own downloads, so Dryad's
rate limit did not block the build. Validated with `eco-validate`: 129/129 tables
pass, IRW view conforms. Uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| sandercock_2022_norway_plants_comm | community occupancy, two independent botanists | Dryad CC0 | 22,895 | first plant table: 241 alien plant taxa x 60 plots x 3 years, Norway; `occasion` = botanist (E3, not the multinomial double-observer form); coordinates as deposited: two taxa are IUCN threatened (horse chestnut VU, *Syringa josikaea* EN) but here are introduced garden escapes, not flagged under the E7 ruling on non-native taxa |
| sandercock_2022_norway_insects_edna | multi-scale eDNA metabarcoding (experimental) | Dryad CC0 | 42,185 | 143 insect taxa x 225 Malaise samples (`cluster_id` = plot); `occasion` = DNA source (crushed, ethanol, lysis buffer), not pooled as in the authors' script; abstract's "255 rounds" vs 225 samples noted |
| armstrong_2024_hydrilla_dynocc | dynamic occupancy | Dryad CC0 | 4,211 | Hydrilla in 506 rock pools x 5 years x up to 10 visits; 196 duplicated pool-dates collapsed (any detection), count in `obs_n_records`; 744-pool frame in `__units`; distance-to-occupied and transition probabilities not shipped (derived) |
| martinezvillegas_2024_flaveria_cjs | CJS, marked plants | Dryad CC0 | 9,708 | 809 plants x 12 censuses; census years and sites not deposited, index only in `__periods` |
| martinezvillegas_2024_mammillaria_cjs | CJS, marked plants | Dryad CC0 | 5,695 | 1,139 plants x 5 censuses (M. hernandezii, IUCN EN; no coordinates); sibling |
| martinezvillegas_2024_neobuxbaumia_cjs | CJS, marked plants | Dryad CC0 | 1,266 | 211 plants x 6 censuses; sibling |
| martinezvillegas_2024_govenia_cjs | CJS, marked plants | Dryad CC0 | 1,276 | 319 orchids x 4 censuses; one history typed `11O0` read as 1100 (asserted unique); sibling |
| martinezvillegas_2024_castilleja_cjs | CJS, marked plants | Dryad CC0 | 2,439 | 271 plants x 9 censuses; sibling |
| deprengerlevin_2024_astragalus_msrd | multistate robust design | Dryad CC0 | 28,718 | Astragalus microcymbus, 1,970 plants x 3 years x 10 encounter bins; state 0/1 veg/2 repro/3 found unrecorded; 2014-15 survey set inferred (plot visited iff any plant has a row), 2013 deposited zeros, distinguished in `y_raw` |
| deprengerlevin_2024_astragalus_ms | multistate CJS, stage | Dryad CC0 | 88,866 | 4,042 plants x 28 years (1995-2022); source's inferred dormant and dead are `y = 0` with the code in `y_raw` (ruling for this batch); next-year observations taken from the `fate` column; plot spans not padded to 2022 |
| schleimer_2019_gsl_finwhale_cjs | CJS, photo-ID | Dryad CC0 | 17,745 | 507 fin whales x 35 years, Gulf of St. Lawrence; `y_raw` = sighting days, asserted to rebuild the deposited histories; sex and calf flag as `unit_`; calves kept (authors exclude them) |
| ancona_2016_isabel_booby_cjs | CJS | Dryad CC0 | 105,984 | 4,608 blue-footed boobies x 23 years, Isla Isabel; no band numbers, unit = line number; sex from MARK group columns |
| dezeeuw_2024_nl_waterbeetle_nmix | community repeated counts | Dryad CC0 | 5,344 | 4 Graphoderus species x 337 locations x 12 years x 2 visits = the paper's 1,336 surveys; G. bilineatus IUCN VU, no coordinates deposited; occasions ordered by date, the location-selecting observer's visit flagged `obs_selector` |
| inbo_2026_flanders_aesiso_count | repeated counts, target species | GBIF CC0 (INBO) | 210 | Aeshna isoceles, 30 transects x 9 years; one table per target-species project (incidental species not shipped, they would invent zeros); coordinates as generalised by INBO; two counts dated 2025-12-11 kept as published |
| inbo_2026_flanders_calvir_count | repeated counts, target species | GBIF CC0 (INBO) | 240 | Calopteryx virgo, 30 transects x 8 years; sibling |
| inbo_2026_flanders_coepul_count | repeated counts, target species | GBIF CC0 (INBO) | 203 | Coenagrion pulchellum, 32 transects x 9 years; sibling |

Held: the Meetnetten butterfly site counts (doi:10.15468/hvgkh4): the target species
appears in one or two undistinguished occurrence rows per count, so `y` cannot be
defined; question to INBO. Nine other queued deposits need a ruling or author
information (`queue/human_review.csv`, 2026-11-02 rows).

Fixed while closing: the three INBO scripts wrote `coordinatesCoarsened` as a string,
which crashed `metadata/01_metadata.R` again (batch 15 hit the same thing; #38 asks the
validator to check the shape).

What this batch says about the standard:

- **IUCN trigger on non-native taxa.** E7(b) flagged horse chestnut (VU) and *Syringa
  josikaea* (EN), garden escapes in Norway, which coarsened every plot in both Norway
  tables. Ruled 2026-11-02 (Ben): (b) applies only within the native range; standard.md
  E7 now says so and the two tables were rebuilt with the deposited coordinates.
- **Occasion as a category, not a time** (botanist, DNA source): allowed by E3 and E9,
  but E8's "ordered in time" does not hold.
- **Partly inferred survey sets inside one table** (Astragalus 2013 deposited, 2014-15
  inferred): `surveyEvidence` is one value per table; `y_raw` marks the difference.
- **Stage-fate deposits**: the guide could say that a `fate` column is the next
  census's observation and that the source's dormant/dead are inferences (`y_raw`).
- **One survey design, several target-species frames** (Meetnetten): split per target,
  following the species-pool rule. Ben (2026-11-02): right; users can recombine them.
- **Categorised counts** (dragonfly sex/behaviour/teneral) are summed into `y`; E2 has
  no home for a breakdown of one count.
- **Synthetic unit ids** (booby line numbers) and **flagged subsets kept** (whale calves).

## Batch 17 — 2026-11-03 (the first closed-population capture-recapture table; marine reef fish; a 2-million-row carabid series)

Seven queue rows chosen to fill gaps: the corpus had no closed-population CR table, only seven
marine tables, and few invertebrate count tables. Built by two forks in a worktree
(`~/eco-b17`, branch `batch17` off `origin/main`). Six tables from six deposits; one held.
All pass `eco-validate --irw` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| hinneberg_2022_limenitis_ccr | closed-population CR | Dryad CC0 | 733 | first closed CR table: 75 hibernacula x 13 independent surveyors, one period; `occasion` = surveyor (unordered except that S1 always searched first; said in `closure`), `observer` and `obs_experience`; "." in the deposit is not-surveyed, 0 is missed; taxon at genus level with `unit_contents` (L. reducta / L. camilla / empty, identified after all searches); site coordinate to 0.1 degree (source: highly endangered) |
| leith_2022_africanpenguin_ms | multistate CJS | Dryad CC0 | 7,192 | 899 PIT-tagged African penguins (IUCN CR), Robben Island and Stony Point, 2013-2020; y = 0 / 1 breeder / 2 non-breeder, letter in `y_raw` (the source's P prebreeder is a recode of N, kept in `y_raw`, 13 cells in 9 birds break the paper's P rule, asserted); no coordinates deposited, colonies at 0.1 degree in metadata; prey biomass per year (DFFE survey, from the authors' RMark script) in `__periods` |
| bruce_2021_wisconsin_monarch_nmix | N-mixture | ScienceBase PD | 352 | 60 sites x 2 years x 3 surveys; rows absent = not surveyed (`row_presence`); no survey dates in the deposit; coordinates as USGS published; egg/larva per-stem ratios not shipped (derived) |
| leone_2019_minnesota_monarch_nmix | N-mixture | ScienceBase PD | 117 | 20 burned or grazed prairie remnants x 2 years x 3 dated surveys; separate from Wisconsin (protocol, region, years differ); below the sample floor |
| stallings_2025_gulfreefs_count | community repeated counts (marine) | Zenodo CC BY 4.0 | 230,679 | 14 NE Gulf of Mexico reefs x 171 fish taxa x 1,349 ten-minute diver counts; `period` = quarter (41, 2013-2023), `occasion` = count within quarter; 13 taxa IUCN VU/EN so all reefs coarsened to 0.1 degree; 17 codes (183 rows) with no taxa entry (larvae, bait, unknowns) not shipped; below the sample floor (14 units) |
| vanklink_2025_wijster_carabid_count | community pitfall counts | GBIF CC0 (NLBIF) | 2,013,216 | Biological Station Wijster 1959-1966: 156 traps x 134 species x 15,024 collections, `period` = year (5), `occasion` = collection (46-52 per year), effort in `obs_trap_days`, `cluster_id` = three-trap location; empty collections carry an explicit Carabidae absence, so zeros by complement over the event list; 77 MB (under GitHub's limit); EML says 135 species, the data have 134 |

Held: Agroecology-Transect butterflies (zenodo 22916934): four national protocols, 375 of
1,677 occurrence rows on visit ids missing from the Visits sheet, mixed moths and synonyms,
each country below the floor (`queue/human_review.csv`).

What this batch says about the standard:

- **Taxon identified after capture.** The Limenitis hibernacula were closed populations whose
  contents (two species or empty) were known only after every survey. Ruling #20 (one taxon per
  table when the unit is an individual) would drop the 34 empty hibernacula; a genus-level taxon
  with `unit_contents` keeps them. Worth a sentence in the guide.
- **Occasions that are observers, not times.** E8 orders occasions in time; here only the first
  surveyor's position is known. `closure` carries it; an `occasionKind` (time / observer / cell /
  replicate) field would make it filterable, and is the same request as the botanist occasions
  in batch 16.
- **Source state codes that are the authors' recodes** (penguin P from N): keep both in `y_raw`,
  one `y` code, assert the counts.
- **External time covariates from the authors' code** (prey biomass from a separate fisheries
  survey) are not derived from the detections, so they ship in `__periods`; the guide could say so.
- **GBIF IUCN lookups need checking.** `/species/{key}/iucnRedListCategory` mapped Calathus mollis
  through a synonym to the extinct St Helena C. extensicollis (EX); overridden with an assertion.
  "No assessment" is HTTP 204 (cached as `[]`), correctly read as not assessed. A shared
  `iucn_category()` helper in `lib/` would stop each script writing its own.
- **One flagged fish coarsens every reef.** Commercial Gulf species (red snapper, gag, red grouper)
  are VU/EN, so any Gulf reef-fish table is coarsened; the whole-array coarsening question again.
- **Replicates the authors say are not independent** (side-by-side divers) and **year-round
  occasions without closure** (Wijster, after NEON carabids) have only `closure` to live in:
  enumerated closure, again.
- **Species pairs the source could not separate** (five carabid pairs) have no field; recorded in
  `notShipped`. A `taxon_` flag or `__taxa` note column would serve.
- **IRW view quirk:** irw-validate's `date_range` reads pre-1970 dates as negative Unix seconds
  (Wijster); a checker quirk, not a table defect.

## Batch 18 — 2026-11-03 (photo-ID robust design, marked-orchid multistate, Pollard walks, carabid emergence)

Six queue rows, built by two forks in `~/eco-b18` (branch `batch18`). Ten tables from six
deposits; nothing held. All pass `eco-validate --irw` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| arsocivil_2019_scotland_dolphin_rd | robust design CR, photo-ID | Dryad CC0 | 26,855 | 205 bottlenose dolphins x 27 summer seasons (1989-2015) x 3-5 monthly occasions; the deposited multistate file is the same histories pooled by season with a U/F/M sex label, rebuilt exactly by assertion and carried as `unit_sex` + `unit_sexed_period`, not a second table; adults-only file is the authors' subset (`notShipped`) |
| arsocivil_2019_scotland_dolphincalf_cjs | CJS, photo-ID | Dryad CC0 | 1,456 | 56 calves x 26 years; two MARK group columns shipped as `g1`/`g2` unlabelled (paper: first-born vs subsequent calves, not mapped in the deposit) |
| cleavitt_2017_hbef_plamac_ms | multistate CJS, marked plants | DataONE LTER CC BY 4.0 | 816 | Platanthera macrophylla, 218 flagged plants x 5 years; state 0-4; code 11 (flag lost) censors (no rows after); 3 plant-years coded 5 (undefined in the EML) get no row; underground / presumed dead are source inferences, `y = 0` with code in `y_raw` |
| cleavitt_2017_hbef_plaorb_ms | multistate CJS, marked plants | DataONE LTER CC BY 4.0 | 840 | P. orbiculata, 241 plants; sibling (one census, split by ruling #20) |
| work_2026_ocala_odonates_comm | community occupancy | Dataverse CC0 | 2,880 | adult odonates by aerial net, 16 ponds x 45 species x 2 years x 2 visits; Libellula jesseana VU and Florida-endemic, so pond coordinates coarsened; six spellings corrected (`taxon_sourceName`); description says 2021 + 2023, sheets say 2022 + 2023 (sheets followed); below floor |
| work_2026_ocala_odonatenymphs_count | community counts | Dataverse CC0 | 2,880 | nymphs by dipnet, same ponds and visits; sibling; below floor |
| peer_2014_bmsil_butterfly_count | Pollard-walk community counts | GBIF CC0 | 149,526 | Israeli BMS: 39 transects x 81 species x 7 seasons (from 1 October) x up to 27 walks; section events exist only where something was seen, so sections summed to the walk (as the EML advises); empty walks are explicit `s00` events (`row_presence`), one duplicated empty walk collapsed; volunteer names pseudonymised; impossible temperatures set NA |
| barea_2021_sierranevada_butterfly_count | Pollard-walk community counts | GBIF CC BY 4.0 | 175,950 | 22 transects x 102 species x 12 years (none 2011) x up to 21 walks; every walk is a parent event, 109 with no butterfly; Polyommatus golgus (EN, endemic) and Carcharodus baeticus (VU) so transects coarsened to 0.1 degree; below floor |
| peters_2026_carabid_pitfall_count | community pitfall counts | Zenodo CC BY 4.0 | 224,110 | Belgian sugar beet / cereal plots 2023-24: 300 pitfalls (`cluster_id` = plot) x 73 species; `Etat = ok` rows are the surveys; two week codes mistyped (asserted); 31 all-zero template species not shipped; period letters A/J/G read as April/July/October (inferred; check) |
| peters_2026_carabid_emergence_count | community emergence-tent counts | Zenodo CC BY 4.0 | 111,617 | 185 tents, same species; split from the pitfalls (emergence vs activity-density); one script builds both (`data/peters_2026_carabid_count.R`) |

What this batch says about the standard:

- **Coarsening coordinates leaves other locators.** Sierra Nevada ships `unit_locality` and
  min/max elevation per transect, which with a 0.1 degree cell nearly re-identifies it. E7 speaks
  only of coordinates. Question for Ben: should E7 coarsening extend to locality names and
  elevation for flagged-taxon tables? (The source itself publishes all of it on GBIF.)
- **Pollard-walk archives record a section only when something was seen** (both GBIF schemes):
  section zeros need a stated section count; BMS-IL's stated count is exceeded by 94 events. Walk
  level is the safe unit; a guide sentence.
- **Lost marks are censoring, not death** (orchid code 11); E4 consequence 4 names removal, not
  lost marks. **Undefined source codes get no row**, not a guessed state. Two guide sentences.
- **Recode detection by exact rebuild** (dolphin multistate file = pooled RD histories): a stated
  rule for multi-file deposits would help.
- **Ruling #20 splits one census** (two orchid species, one flagging census); `components` again,
  also for pitfall / emergence and adults / nymphs.
- **Template taxa lists**: all-zero checklist species dropped; `taxonInclusionRule` would make the
  cut visible (also asked in batch 13). **Genus- or family-level records beside species zeros**
  (an unidentified "Pieridae" at a walk) may make some species zeros misses; no field for it.
- **Unexplained period codes** (carabid A/J/G) inferred from the record description.

## Batch 19 — 2026-11-03 (marine: beaked whales, kittiwakes, Aldabra reef fish; UK woodland communities)

Six queue rows, built by two forks in `~/eco-b19` (branch `batch19`). Nine tables from four
deposits; two held. All pass `eco-validate --irw` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| curtis_2021_sannicolas_ziphius_cjs | CJS, partial identity | Dryad CC0 | 1,397 | 127 Cuvier's beaked whales off San Nicolas Island, 11 August-July years 2007-18; histories rebuilt from 318 catalogued photo-ID records with the authors' deposited selection code (29 uncatalogued dropped), every Table 1 count asserted; `y` = multimark "sometimes" coding 0-4 with `unit_known`; vessel effort per year in `__periods` (`effort_table`); capture-weighted `eff.bssn` not shipped |
| mcknight_2019_kittiwake_fledgling_ms | multistate CR | Dryad CC0 | 55,472 | 5,090 black-legged kittiwakes banded as chicks, Middleton Island, 19 years; 0 / P / B; each bird's first cell is the authors' simulated release at age 1 or 2, flagged `obs_release = 1`, `unit_cohort` = banding year; histories start at release |
| mcknight_2019_kittiwake_recruit_ms | multistate CR | Dryad CC0 | 12,141 | 977 recruits (paper: 997), 0 / P / B / U; a separate analysis set (only 293 birds align with the fledgling sheet), not a recode; one script builds both |
| koester_2023_aldabra_reeffish_count | community counts (marine) | figshare CC BY 4.0 | 26,076 | Aldabra Atoll UVC, 21 site-depths x 82 taxa x 6 seasons x 1-3 belt transects; no survey list, so a transect is surveyed in a season iff it has a record (`inferred`); four EN/VU species recorded in `__taxa`, no coordinates deposited; SIF citation request carried; below floor |
| koester_2023_aldabra_reeffishext_count | community counts (marine) | figshare CC BY 4.0 | 16,632 | extended species list method, 198 taxa x 2 seasons; split by method (different species pools) |
| bradferlawrence_2025_ukwood_beetle_comm | community occupancy | Zenodo CC BY 4.0 | 34,385 | 60 woods x 115 beetle taxa x 5 pitfall collections; a species-year NA is exactly a taxon never caught that year (asserted), shipped `y = 0`, `y_raw = "NA"`, as the authors' code does; one lost collection has no rows; three staphylinid subfamilies have no GBIF key |
| bradferlawrence_2025_ukwood_bird_comm | community occupancy | Zenodo CC BY 4.0 | 17,712 | 125 woods x 54 species x 3 surveys; 47 all-NA surveys have no rows |
| bradferlawrence_2025_ukwood_mammal_comm | community occupancy | Zenodo CC BY 4.0 | 1,600 | 100 woods x 4 small mammals x 4 trap days |
| bradferlawrence_2025_ukwood_plant_comm | community detection, single visit | Zenodo CC BY 4.0 | 25,800 | 129 woods x 200 plants, one visit (replication warning); BNG coordinates as deposited (no flagged taxa) |

Held: the Hauraki Gulf aerial survey (doi:10.5061/dryad.wm37pvmrn: the deposit is presence and
pseudo-absence points built for boosted regression trees, not the survey) and the Western
Maryland dragonflies (doi:10.5063/J101KS: no visit schedule for the capture occasions, and
ruling #20 would give 24 near-empty single-species tables). Rows in `queue/human_review.csv`.

What this batch says about the standard:

- **Simulated releases in deposited histories** (kittiwake age-1/2 release cells) are analysis
  artefacts, not encounters; `obs_release` flags them. And **rows before marking**: the kittiwake
  histories start at release, the booby and fin-whale CJS tables carry zeros before first
  capture. E4 should say which is right for individuals marked as chicks.
- **Partial identity** (one-sided photo-ID, multimark 0-4) joins single-flank camera SCR: a named
  convention would let users find both.
- **Model-input deposits** (SDM presence / pseudo-absence) are a recurring hold class; intake
  could name it.
- **NA as "not scored" rather than "not surveyed"** (woodland beetles): the test is that every
  NA taxon-year has no detection anywhere that year and every scored taxon is detected. A guide
  sentence.
- **Record-only survey sets with a clear design** (Aldabra transects) have to be `inferred`.
- **Projected-coordinate coarsening** (BNG) has no stated grid in E7.
- **GBIF strict matching sends homonyms to kingdom or family** (Acanthurus, Naso, Aprion, Chloris,
  Taraxacum); both scripts assert EXACT matches. That assertion belongs in `make_taxa()`.
- **Residual list groups** ("other grouper") change meaning with the list; shipped at family rank
  with the qualifier in the name.

## Batch 20 — 2026-11-03 (Shark Bay megafauna, Bunbury dolphins, fritillary MRR with search effort, wild bees)

Six Dryad queue rows, built by two forks in `~/eco-b20` (branch `batch20`). Ten tables from
five deposits; one held. All pass `eco-validate --irw` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| nowicki_2019_sharkbay_megafauna_count | repeated transect counts (marine) | Dryad CC0 | 10,665 | Shark Bay boat transects, 11 transects x 3 taxa (incl. dugong, VU; sea snakes as Hydrophiinae, no GBIF key) x 109 months x 1-12 runs; only runs flagged usable (480 dropped); no coordinates deposited; densities and run durations not shipped; below floor |
| nowicki_2019_sharkbay_turtle_count | repeated transect counts (marine) | Dryad CC0 | 6,180 | the runs on which turtles were identified to species (E4: a different survey set); sibling |
| nowicki_2019_sharkbay_dolphin_count | repeated transect counts (marine) | Dryad CC0 | 2,338 | the runs on which dolphins were counted (not reliably 2002-07); sibling |
| symons_2018_bunbury_dolphin_rd | robust design CR, photo-ID | Dryad CC0 | 14,472 | 201 bottlenose dolphins x 12 seasons x 6 (paper's count); 28 all-zero catalogue rows dropped |
| symons_2018_bunbury_femalecalf_msrd | multistate robust design | Dryad CC0 | 6,552 | 91 females, 0 / 1 seen without calf / 2 with calf; separate selection (10 females absent from the main file); 40 calving events asserted against the paper |
| fabritius_2015_siitama_fritillary_cjs | CJS, daily MRR | Dryad CC0 | 21,050 | false heath fritillary, 842 butterflies x 25 search days; searched areas per day in `__periods` (`effort_table`); capture area as `obs_capture_area`; endangered per source, location as a 0.1 degree cell in metadata; privacy-shifted shapefiles not shipped |
| fabritius_2015_sorila_fritillary_cjs | CJS, daily MRR | Dryad CC0 | 3,514 | 251 butterflies x 14 days; sibling |
| fabritius_2015_merikarvia_fritillary_cjs | CJS, daily MRR | Dryad CC0 | 3,129 | 149 butterflies x 21 days; sibling |
| maihoff_2023_berchtesgaden_bees_count | community counts | Dryad CC0 | 46,636 | 33 sites x 131 bee taxa x 2009/2019 x 5-6 walks; source `replicate` is a campaign round (kept as `obs_round`), occasion = walk order; B. lucorum/terrestris complex at genus (asserted); Bavarian Forest half not buildable (specimens only, no trap-run record) |
| johnson_2023_tweedsmuir_bombus_count | community counts | Dryad CC0 | 520 | 26 sites x 10 Bombus x 2 vane-trap visits, postfire BC; netting (burned sites only, no effort; the only B. terricola VU records) not shipped; below floor |

Held: Mediterranean UVC (doi:10.5061/dryad.k6djh9wb4): three groups' protocols merged in one
undated CSV, 224 site labels vs the paper's 52; needs the Wiley paper (`queue/papers/`).

What this batch says about the standard:

- **Per-taxon survey sets inside one survey** (Shark Bay: which taxa were countable on which run)
  force E4 splits of one survey into sibling tables; a per-taxon survey-set rule or `components`
  would keep them together. Asked for again.
- **Covariates that vary by taxon within a survey** (sighting-band width per taxon) went into
  `__taxa`; E5 has no level for unit x taxon or survey x taxon facts.
- **Source seasons that are not contiguous** cannot be E8 periods; months used.
- **All-zero deposited histories** (never-seen catalogue rows; Bunbury, after Isla Isabel) are not
  shipped; a guide sentence.
- **Capture location on a detection** has to be an `obs_` column NA on non-detections, because
  E2 lets `y_raw` carry only the recorded value.
- **Campaign rounds vs walk indices** (Berchtesgaden): gaps in a replicate number are not lost
  surveys until checked against the protocol's walk count.
- **Methods at only some units** (netting at burned sites) cannot join the community table.
- **Privacy-shifted coordinates** are not locations; E7 has no wording for them.
- **Dryad `primary_article` can be wrong** (the wild-bee record names a transcriptome paper).
- **Partial builds** (Bavarian Forest half) live only in `notShipped`; the queue has no status
  for "built in part".
- **Pooled groups with no GBIF key** (Hydrophiinae): `make_taxa()` cannot mark an NA key as
  intentional.

## Standard v1.1-draft rebuild — 2026-11-03 (every table rebuilt; 164 -> 168 tables)

Ben's rule for standard changes (2026-11-03): clear, no judgement, and lossy only where
protection requires it. Rulings written into `standard.md` v1.1-draft from the strains logged
in batches 4 to 20; decision notes for #30 and #31 in `notes/decisions/`. Ben ruled the three
items that failed the test: E7 multi-taxon tables ship two tables (coarsened whole, plus an
`_exact` sibling without the flagged taxa); E7.4 other locators are coarsened only in tables
already coarsened; published tables are rebuilt to the new rules (no users yet).

Tooling: `eco-validate` (closure / occasionKind / taxonInclusion vocabularies and
consistency, set-based E4.2 with `__survey_taxa`, never-detected individuals, `unit_identity`,
`__traps` coordinates of flagged taxa, empty `taxonID` needs `taxonRemarks`); R twin to match;
`make_taxa(exact = TRUE, allow_higher, no_key)`; `iucn_category()` (checks the assessed name
against the accepted name; a synonym's assessment is not taken); `write_table(survey_taxa =)`;
`eco_to_ch(fill =, by_period =, drop_zero_sessions =)`; `components`, `closure`,
`occasion_kind`, `taxon_inclusion` in `metadata/metadata.csv`; `__survey_taxa` in the uploader.

Rebuild: 72 scripts needed only the new metadata (data reproduced exactly); 59 were rebuilt by
hand in three groups. All 168 tables pass `eco-validate`; pytest 199 passed; R package 93.

- **Merged (ruling #31, `__survey_taxa`)**: addis RMAP bt + mbrt -> `addis_2026_rmap_amph_dynocc`;
  nowicki Shark Bay megafauna + turtle + dolphin -> `nowicki_2019_sharkbay_count`; INBO aesiso +
  calvir + coepul -> `inbo_2026_flanders_dragonfly_count`; goldingay glider + koala ->
  `goldingay_2022_richmond_mammals_dynocc`. Ten tables withdrawn
  (`tools/withdrawals/withdraw_v11_merges.py`). Koester's two Aldabra tables stay split: the
  methods count different size classes (two protocols).
- **New `_exact` siblings (E7.3)**: barea (`barea_2021_sierran_butterfly_exact_count`), boone,
  lafferty estuary fish, raman, rich, stallings, work Ocala adults and nymphs, rooney Snapshot USA
  (543 MB, gitignored), and kery MHB (turtle dove VU found by `iucn_category()`; projected
  coordinates snapped to 10 km cells, E7.1). Place-name unit and cluster ids replaced in the
  coarsened twins; elevation rounded to 100 m.
- **At-risk span (E4.4)**: trimmed before marking for animals marked at birth or hatching
  (arsocivil calves, schleimer calves, riecke goslings, volzke seal cohorts, deprengerlevin
  seedlings, oosthuizen from first encounter because the authors deleted earlier sightings);
  padded to the study's first period for wild-caught animals (moe trout, cleavitt orchids with
  `y_raw = "-999"` kept, NEON small mammals: perleu and perman now exceed 100 MB, gitignored);
  kittiwakes start at the real banding year (`obs_banding = 1`), not the simulated release.
- **unit_identity (E2)**: Phinda (renamed from `unit_flank_profile`), curtis beaked whales.
- **Taxa (E6, E10)**: `taxonInclusion = recorded` drops taxa never detected in the table (obrist
  10 species seen only outside the counting rule; peters pitfall 3 and emergence 22 caught only
  by the other method; Ocala adults 15, nymphs 4; sandercock insects 1); family- and order-level
  records shipped as taxa (peer: 7); lifeStage (price, swedberg, hinneberg); taxonRemarks for
  unseparated pairs, aggregates and no-key groups; lindstrom's 11 security-class species in
  `taxaWithheld`.
- **v1.0 taxon errors caught by exact matching**: homonyms resolved to kingdom or phylum
  (stallings Prionotus, raman Iduna/Hippolais/Acrocephalus, kleiven Mustela), species matched
  to their genus (peer Melitaea ornata, sandercock Amelanchier and Sedum, bradferlawrence
  Taraxacum to Asteraceae), "sp." records labelled genus at family or class rank (raman), and
  about two dozen fuzzy spelling matches, all fixed through lookup names.

Not settled here (still open): `detection_event` for multi-species per-detection data, live-dead
and Brownie arrays, and the Limenitis hibernacula question (a structure detected, contents
identified later) which v1.1 leaves as built.

## Batch 21 — 2026-11-04 (first batch under v1.1-draft: NINA Norway pollinators, Kasumigaura fish eDNA, lanternfly eDNA, Steller sea lions)

Six queue rows, built by two agents in `~/eco-b21` (branch `batch21`). Five tables from four
deposits; two held. All pass `eco-validate --irw` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| nina_2026_norway_pollinator_count | community counts, Pollard-type 50 m sections | GBIF/NINA IPT CC BY 4.0 v1.12 | 4,734,122 | 2,651 sections in 92 1.5 km squares x 94 taxa (Bombus and Papilionoidea, plus Zygaena from the EML's registered families) x 2009-2025 x up to 7 walks; zeros added for every taxon at every walk as the publisher instructs (`sample_table`, the event list is complete); one protocol for bees and butterflies (ruling #31); Bombus alpinus IUCN VU, so coordinates at 0.1-degree cell centres and place names dropped (E7, E7.4); unit covariates in `__units`; core gitignored (297 MB) |
| nina_2026_norway_pollinator_exact_count | E7.3 sibling | same | 4,683,759 | without B. alpinus; 5 m coordinates, municipality, locality and section footprint in `__units`; core gitignored (294 MB) |
| fukaya_2022_kasumigaura_fish_mb | community detection, eDNA metabarcoding, replicate samples | Dryad CC0 | 7,200 | 50 sites x 3 replicate samples x 50 taxa (8 genus-level groups as own taxa); six zero-read samples are not surveys (authors' rule); y_raw = reads; no coordinates |
| allen_2021_nj_lanternfly_edna | multi-scale eDNA with a paired visual survey (E9 experimental) | Dryad CC0 | 376 | plot in vineyard, round = period, 3 qPCR replicates + visual count (`obs_method`); the paper's 3 suspected false positives flagged, not recoded; 14 plot surveys dated 2016 in a 2019 study left undated |
| hastings_2018_seak_sealion_cjs | CJS, resighting of branded pups | Dryad CC0 | 39,645 | 2,795 pups at 4 SE Alaska rookeries x 18 periods (1994, 1995, 2000-2015); rows from branding (E4.4); the 1994 cohort has no 1995 row (no resighting before 2000); no mark loss; caphist2 multistate male histories not shipped (state codes undefined); no coordinates; IUCN NT |

Held:
- Ohio butterflies (doi:10.5061/dryad.cf78420): Dryad holds indices and sample raw data only. The raw counts are by request from NABMN, and the GitHub copy is third-party data under a code licence.
- North Atlantic right whale open SCR (doi:10.5061/dryad.stqjq2c35): the detector is each day's set of flown transect lines, and detections have continuous locations. E9 has no layout for this. A non-spatial robust design is buildable from `y`.

What this batch says about the standard:

- **Ruling #31 and paired methods.** Its text named eDNA and visual survey as two protocols, but
  the published dougherty and lafferty eDNA tables keep two methods applied at the same visit in
  one table with `obs_method`. The text now says so: two methods are two protocols only when
  each has its own survey set (clarification in `standard.md`, 2026-11-04).
- **Line-transect / search-encounter SCR** (right whale) has no layout: it needs a per-occasion
  track side table and per-detection `obs_` locations.
- **A deposited period that is a survey for some cohorts and not others** (sea lions, 1995) is
  handled as "not surveyed" under E4.4; the at-risk rule does not say so in as many words.
- **Repeated section walks within one visit** (NINA, six visits in 2024-2025) take two occasion
  slots; `obs_visit` keeps the visit rank. No rule covers it.
- **Coarsening that is undone elsewhere**: GBIF publishes NINA's 5 m coordinates. E7 was applied
  as written; the agency exception does not cover land that is not public.
- **Size**: the NINA cores (about 295 MB each) are the largest tables so far.
- **Large Dryad deposits** refuse zip generation (405) and per-file downloads need a token
  (second instance after Snapshot USA); `download_dryad()` has no token path.
## Breeding Bird Survey (#24) — 2026-11-04

One deposit, the 2026 release (1966-2025, doi:10.5066/P144YU3S), one script, 3 tables. Built by Milan Gorislavets
(PR #57). Ben's review of that PR set the national design: standard v1.1-draft (#56) had merged in the meantime, and its
ruling #31 makes one protocol x response type one table. So the 37 per-BCR count tables Milan first built became one
national table, stored as period parts (E4). Design and every number: `notes/decisions/bbs_design.md`, with an
"After review" section. All pass `eco-validate --irw` (exit 0). Milan's independent check in Python from the raw files
was rerun on the national table at 5516d73 (the #62 merge): all 26 parts, 110,127,544 rows, 0 differences, 0 false
zeros; all 7,573,059 source run x taxon records present, sum of `y` 107,000,446 on both sides, the 16 run-level columns,
`__periods`, `__units` and `__taxa` year ranges matching; an independent rebuild byte-identical apart from build dates.
Cores are not tracked.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| ziolkowski_2026_bbs_count | annual route-run counts | USGS ScienceBase, CC0 | 110,127,544 | every run nationally (144,146) x every taxon of the species list (764); 26 period parts of at most 5 M rows in `output/ziolkowski_2026_bbs_count.parts/` (8.4 GB), one table on Redivis; `y` = run total including non-breeder records; `obs_nonbreeder_count`; BCR and stratum in `__units` |
| ziolkowski_2026_bbs_bcr15_block | 10-stop blocks along a route | same | 1,279,278 | Sierra Nevada, RPID 101, 1968-2025; survey set `inferred` |
| ziolkowski_2026_bbs_bcr15_stop | stops along a route | same | 3,957,863 | RPID 101, 2009-2025, with vehicles and noise per stop; survey set `inferred`; a Western Tanager `pcount` runs, but stops are not closed repeat visits |

Held: block and stop tables outside BCR 15 (`queue/human_review.csv`). Nationally they would be 17.6 GB and 112 GB.

What changed in review (2026-11-04): the national table replaces the 37 BCR tables (ruling #31); E1 now says `y` is never an aggregate *across surveys* (the run total is accepted); E4's split is stated as period parts (`write_table_parts()`, `eco-validate` and the uploader read `<table>.parts/`); v1.1 fields (`closure` closed / dependent with `closureNote`, `occasionKind`, `taxonInclusion`, `taxonRemarks` for the 61 categories with no GBIF key: 50 species complexes, 8 hybrids, 3 functional groups; Porphyrio martinicus looked up as GBIF's *martinica*); ScienceBase downloads resolved from the item JSON (the files are not refused).

What this batch says about the standard:

- **Non-breeders and E4 (ruling).** `States` holds breeding-category records only; a further zip holds the rest. Zero-filling
  from `States` alone writes `y = 0` for a recorded bird. `y` here includes both, so `y` steps up at 1999, when the survey began
  keeping such records; `y - obs_nonbreeder_count` removes the step. Before 1999 about 8,160 records are expected to be unseen,
  so a zero there cannot exclude a non-breeder; `obs_nonbreeder_count` is NA on those rows. The alternative is `y` = published count
  throughout, against E4's wording for 10,476 records.
- **E1 and a run total (ruling).** Count-table `y` sums the stops of one run. Read as allowed: the run is the survey the source publishes.
- **A survey set finer than the sample table (ruling).** No file says how many stops a run sampled. Stops past the last one with a bird,
  car or noise record have no row (16,088 of 4.28 M nationally), so `surveyEvidence` is `inferred`. A skipped stop mid-route cannot be seen.
- **E4.2 and regional programmes (#31, #40).** One table with per-route pools would be 15.3 M rows; 37 BCR tables are 42.1 M; a national pool is
  110.1 M (9.2 GB). A 1% species cut would save 41% at BCR level and was not applied. Settled in review: the national pool, one table.
- **E4 split by period.** It said "under one `__dataset.json`", but `load_table()` read `<name>__dataset.json`, so each shard would have needed its own.
  Settled in review: the layout is now stated (`<table>.parts/part-NN.csv`, one `__dataset.json` with a `parts` manifest) and the tools read it.
- **`eco_to_umf(type = "colext")`.** One column per `(period, occasion)` present and `numPrimary = max(period)`. Tested with `unmarked` 1.5.2 on BCR 12, 13 and 15: 13 and 15 error on the
  2020 gap, and BCR 12 is accepted silently because its column count happens to divide, which would misalign years after 2020. By arithmetic, 36 of 37 tables error. Notes in every table say to pad; the converter needs a fix.
- **`eco_to_array()` reads `unit_*` from the core only.** BBS keeps them in `__units` because three columns in the core would cost 0.5 to 1 GB, so `siteCovs` starts empty.
- **CI cannot see most of this.** A gitignored core's side tables are never gated in CI. (ScienceBase downloads turned out to work at the URLs in the
  item's JSON record; the script resolves them, so the CI skip is gone.)
- **`site/data.qmd:79` links `data/<table>.R`,** dead for every multi-table script, now 39 more cards. The `script` column of `metadata.csv` has the right value.
- **`gbif_taxon()` caches a network failure as a no-match.** The script asserts no `ERROR`; four 2024-on bird names needed `lookupName` to older names in GBIF.
- **`occasion` means three things across BBS tables:** rank of a run in a route-year, position of a block, position of a stop. `eco_to_unmarked()` treats all as repeat visits; `closure` says so per table.

## Batch 22 — 2026-11-04 (Stanford-linked Costa Rica countryside surveys: Daily, Karp, Hadly labs)

Five queue rows from the Daily-lab Costa Rica countryside programme, built in `~/eco-stanford`
(branch `batch-stanford-costarica`). Four tables from three deposits; two deposits not built as
duplicates. All pass `eco-validate` (exit 0); `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| ke_2022_costarica_birds_nmix | community counts, repeated point counts | Dryad CC0 | 187,374 | 150 points in 25 Guanacaste landscapes x 1,122 logged visits (2016-2019, 1-3 per year) x 167 species; `sample_table`; y = sum of Number1 per species x visit; coordinates coarsened (Amazona auropalliata CR, Crax rubra and Aratinga canicularis VU), elevation to 100 m; forest cover at 105 radii in `__units` |
| ke_2022_costarica_birds_exact_nmix | E7.3 sibling | same | 184,008 | without the three flagged species; coordinates and elevation as deposited |
| frishkoff_2014_costarica_birds_binom | binomial counts (ruling #34), transects x season | Dryad CC0 | 513,520 | 44 transects x 24 seasons (2001-2012 dry/wet; 1,048 surveyed) x 490 taxa (4 genus-only); detections out of 3; survey set from row presence |
| frank_2017_costarica_bats_comm | community detection, mist nets | Dryad CC0 | 7,770 | 18 sites x 185 netting visits (2009-2013) x 42 bats; JAGS input array, nrep = visits per site-year; below the sample floor (18 units) |

Not built:
- Frishkoff et al. 2018 (doi:10.5061/dryad.7c652r8): the same 240 visits in 2016 as Ke 2022, with counts that match. Its per-observation distance (to the nearest 10 m) is new, so it could become a distance-sampling table.
- Frishkoff et al. 2019 (doi:10.5061/dryad.fg8kq66): the 2016-2017 subset of Ke 2022.

What this batch says about the standard:

- **Behaviour-coded counts.** Ke 2022 records each observation with up to three (number,
  behaviour) pairs. Number2 and Number3 count the same individuals as Number1 doing a second or
  third behaviour. y is the sum of Number1, which the 2018 deposit of the same visits confirms.
  No rule covers multi-behaviour records. Here the earlier deposit settles it.
- **Two source codes lumped onto one name.** In Frishkoff 2014, Empidonax traillii has two rows
  in six transect-seasons. A union of two "detections out of 3" cannot be rebuilt, so the taxon
  is not shipped. E6's "not reliably separated" rule needs the source to say so, and this
  source does not.
- **A survey set from row presence in a binomial_count table.** The 8 absent transect-seasons
  are all wet seasons of the three H-SI transects. Three bird surveys of a transect never
  record nothing, so `row_presence` is defensible. The table says so in `surveyEvidenceNote`.
- **A deposited model array** (Frank 2017) zero-pads visits beyond `nrep`. The padded cells are
  asserted to carry no capture and get no row.

## Batch 23 — 2026-11-05 (card-sorted queue rows: Mauritius parakeet, Svalbard polar bears, NZ mice, Mara cheetahs, Wyoming shrike, Colombian endemics)

One agent in `~/eco-b23` (branch `batch-23`), from the 2026-11-05 card sort (#85). Twelve deposits inspected,
six tables built, six held. All six pass `eco-validate` (exit 0).

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| gelle_2026_mauritius_parakeet_ms | multi-state CJS (pre-breeder / breeder / non-breeder) | Dryad CC0 | 27,969 | 2,734 echo parakeets ringed as nestlings, 29 seasons 1994-2022; rows from the ringing season (E4.4); 995 resighted (Dryad methods say 997); IUCN VU set by hand (GBIF's IUCN endpoint has no record for the key); first table for Mauritius |
| cubaynes_2021_svalbard_polarbear_ms | multi-state (multievent) capture-recapture, 11 family-unit states | Dryad CC0 | 3,789 | 158 females, 28 springs; event codes from the paper's Table 1 (the Dryad text mislabels code 4); adults from 1992, known-age females from age 2 (the model's first state); dates rebuilt from day of year; IUCN VU, no coordinates |
| moinet_2024_nz_mouse_scr | SCR, live traps with a removal phase | Dryad CC0 | 180,288 | 230 house mice, 2 grids x 36 traps, 4 sessions of 10-12 nights; `obs_removed` on 186 euthanasia captures; trap usage inferred (as the authors' secr script); anonymised trap coordinates; Leptospira test results as `unit_`; first table for New Zealand |
| broekhuis_2020_mara_cheetah_scr | SCR, search-encounter (pixel x day traps with km driven) | Dryad CC0 | 2,206,029 | 8 sessions, 258 session-scoped ids; `effort_table` from the deposited pixel operation matrix; coordinates centred (VU); core gitignored (105 MB); **tagged do_not_publish** pending a ruling on search-encounter SCR |
| todaro_2025_wyoming_shrike_dynocc | dynamic occupancy | Dryad CC0 | 4,252 | 445 points, 2015-2024, 2 visits a year to 2017 and 1 after; the deposit's `_1/_2` visit labels are out of date order for 644 point-years, so occasions follow the date |
| betancur_2021_antioquia_birds_count | two-species repeated counts | Dryad CC0 | 560 | 70 points x 2 years x 2 visits; counts bound to points by row order as in the authors' scripts; coordinates coarsened because the source calls both species endangered (GBIF IUCN says LC); first table for Colombia |

Held (`queue/human_review.csv`): Serra do Amolar cameras (per-species occasion lengths), little brown bat robust design
(weeks with no antenna operating are zeros in the MARK matrix), Columbia steelhead CRR (blocked: paper), Spiti snow
leopards (count-detector SCR with one occasion), harlequin duck (three methods, unit unclear), Melbourne diadromous fish
(NA patterns differ between species and files).

What this batch says about the standard:

- **Search-encounter SCR.** The right whale was held in batch 21 for want of a line-transect rule. The cheetah deposit is the
  discretised form: the source already turned the search into pixel x day traps with an operation matrix and km driven, so it
  fits `trap` + `__traps` + `effort_table` without new columns. Built, but held from publication until Ben rules.
- **Identities not linked across sessions** (cheetah): E4.4 says a wild animal is at risk from the first period, but an id that
  exists only within one session cannot carry rows in other sessions without duplicating animals. Rows only in the id's own
  session; the rule does not say so.
- **Known-age individuals not marked at birth** (polar bear females first caught at 2-5 years): E4.4 covers unknown-age and
  marked-at-birth animals. Rows start at the first age the model's state space admits (independent at 2).
- **Count-detector SCR** (snow leopard) and **per-taxon occasion lengths** (Amolar) have no stated layout.
- **The IUCN lookup** returned NE for the echo parakeet (no GBIF record) and LC for two species the source calls endangered;
  the E7 flag followed the source.

## Batch 24 — 2026-11-05 (card-sorted queue rows: Kooragang frogs, Japanese salmonids, Lake Ngami birds, Sumatran and Western Ghats birds)

One agent in `~/eco-b24` (branch `batch-24`, stacked on `batch-23`), from the 2026-11-05 card sort (#85), choosing
for thin taxa and regions (amphibians, fish; Australia, Japan, Botswana, Indonesia, India). Ten deposits inspected,
six tables built from five deposits, five not built. All six pass `eco-validate` (exit 0).

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| hamer_2021_kooragang_amph_comm | multi-season community occupancy | Dryad CC0 | 10,780 | 11 frogs x 55 wetlands, 2 breeding seasons, 2-15 surveys per season (mark-recapture sites far more often); 10 zero cells in `crisig.csv` outside the survey set dropped (every other species NA, year 0, covariates mean-filled); covariates standardised as deposited; species codes expanded from the paper (author copy) |
| tsuboi_2020_japan_charr_ms | multi-state CJS (juvenile/adult x tributary/connected/fragmented mainstem) | Dryad CC0 | 7,147 | 1,373 charr, 9 annual October surveys; YOY rows start at marking (born that year), adults from 2009 (unknown age, E4.4); first table for Japan |
| tsuboi_2020_japan_masu_ms | same, red-spotted masu salmon | Dryad CC0 | 7,345 | 1,335 fish; split from the charr by ruling #20 (one taxon per individual table) |
| cumming_2021_ngami_waterbird_count | repeated community point counts | Dryad CC0 | 41,496 | 182 species x 228 half-hour counts at 14 points over 6 trips; Roberts common names mapped through the eBird/Clements taxonomy (en, en_ZA; 14 by hand, 6 GBIF genus spellings); y = foraging + not foraging + flying over, parts as `obs_`; coordinates coarsened (7 threatened species incl. white-backed vulture CR) |
| prabowo_2016_jambi_birds_count | repeated community point counts | Dryad CC0 | 8,733 | 71 species x 32 plots x 3-4 visits; `sample_table` survey set; y = the authors' max-per-visit rule; homegardens not shipped (no survey table, paper and script disagree on visits) |
| raman_2003_kalakad_birds_count | repeated line-transect counts | Dryad CC0 | 6,240 | 60 taxa x 104 walks of 12 transects; uncountable flocks flagged (`obs_uncounted_flock`, y a minimum); mammals and unidentified birds dropped; coordinates coarsened (3 VU) |

Not built (`queue/human_review.csv`): Endau Rompin leeches (held: per-analysis files disagree for the same point-visit),
Western Ghats agroforest amphibians (blocked: paper, what a "replicate" is), Kapitia skink robust design (blocked: paper,
plus which identification set to ship), Valparai tea birds (deferred: single visit), Tiwi mammal trapping (inspected:
SCR impossible without the trap layout; per-species closed-capture tables left for a later batch).

What this batch says about the standard:

- **Common names only.** The Ngami deposit has no scientific names. Matching through a published taxonomy (eBird/Clements,
  in the locale the names come from) with a hand list for the remainder, asserted complete, worked; `make_taxa()` then needs
  the GBIF backbone's older genus for six recent eBird moves (Ixobrychus, Charadrius, Bugeranus).
- **IUCN synonym direction.** `iucn_category()` returns NA when GBIF's accepted name differs from the assessed name, even when
  the IUCN record carries the deposit's own name (Litoria/Ranoidea, Turdinus, Brunhilda). Scripts fill those from the
  record when its binomial equals the deposit's name (the `same_name` pattern already in two scripts); a harness option
  would remove the copies.
- **Known-age young of the year** (salmonids): fish first caught as YOY were born that year, so their rows start at marking,
  the newborn branch of E4.4; adults are unknown-age and start in 2009. The rule fits, but "marked as a newborn" could say
  "first caught in its birth year".

## Batch 25 — 2026-11-05 (card-sorted queue rows: California farm birds, Pacific Northwest woodpecker acoustics, Hawaiian Duck robust design)

One agent in `~/eco-b25` (branch `batch-25`, from main after batches 22-24; merged with main after #92, so tables are
uploaded to the Redivis draft and only `__dataset.json` is committed). Rows from the 2026-11-05 card sort (#85),
preferring repeated-visit, multi-state and capture-history designs. Twelve deposits inspected (the cap), three tables
built, nine not built. Dryad rate-limited hard (429 on metadata and zips), so most inspections were Zenodo/USGS rows.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| olimpi_2024_calfarms_nmix | repeated community point counts | Dryad CC0 | 67,419 | 99 species x 227 point-years on 30 California farms x 3 visits; `row_presence` (every point-year has exactly three dated visits); flyovers excluded from y (12 flyover-only codes, incl. the two "spp." groups, have no taxon); unit = point-year because the readme does not say a replicate number is the same place across years; the authors' occupancy/N-mixture posteriors not shipped |
| ruff_2025_piwo_state | multi-state occupancy (0 / 1-3 days / 4+ days per week) | Zenodo CC BY 4.0 | 23,290 | Pileated Woodpecker at 3,948 ARU stations in 1,008 hexagons, 6 weekly occasions, 2023; `effort_table` (hours recorded, NA exactly where the week is missed); PNW-Cnet classifier detections; 62 raw station covariates; coordinates as published (LC); IUCN filled by hand (assessed as Hylatomus pileatus) |
| malachowski_2026_koloa_rd | robust design | Zenodo CC BY 4.0 | 22,968 | 792 Hawaiian Ducks (150 F, 642 M), 29 trapping secondaries in 7 trapped primaries of the MARK design's 11 (untrapped primaries keep their numbers and have no rows); trap-days and rainfall per secondary, season and elapsed time in `__periods`; IUCN VU, no coordinates in source |

Not built (`queue/human_review.csv`): Rio Grande giant reed birds and butterflies (held: only N-mixture estimates and
max counts deposited), Swiss MHB 1999-2025 (held: three kinds of per-visit NA, one of which drops 33k positive
territory totals; needs a ruling, and overlaps `kery_2014_mhb_comm`), Broadway nightjars (held: survey years only as a
0/1 code, paper not yet out, mean-imputed covariates), dusky grouse (held: what the four same-day "visits" are),
Tutakoke brant fitness (held: Dryad version zip returns 404), USGS Emperor Goose (held: split-history segments do not
chain), Bardia leopard SCR (held: no survey year or CRS), Valenzuela 2017 Darwin's frogs (held: headerless matrices,
trailing columns undefined), Portuguese weasels (blocked: paper).

What this batch says about the standard:

- **Per-visit NA with three meanings in one matrix** (Swiss MHB): protocol (2-visit squares), species breeding windows
  (not surveyed for: `__survey_taxa`), and values not retained (surveyed, aggregated only). E4.2 covers the first two;
  the third is neither "not surveyed" nor a zero, and the standard has no place for a surveyed-but-unrecorded cell
  other than dropping it. Ruling requested.
- **Untrapped primaries in a MARK design** (Koloa): the source's period numbering is kept with gaps, so the elapsed
  time from the deposited intervals goes in `__periods` (`start_6mo`); nothing in E8 forbids gaps, but a sentence saying
  "keep the source numbering" would settle it.
- **Split-history MARK inputs** (Emperor Goose): a multi-state study encoded as pseudo-individuals with losses on
  capture is a MARK device, not a data structure; E4.4 assumes one unit per animal. Rebuilding animals needs the
  segments to chain, which this deposit's do not.
- **Repository metadata as the only documentation** (leopard, weasel, nightjars): clean secr/MARK files with no survey
  year cannot meet E10's `temporalCoverage`; these wait for papers.
- `iucn_category()` NA from a genus move again (Dryocopus/Hylatomus); filled by hand as batch 24 did.

## Batch 26 — 2026-11-05 (card-sorted queue rows: Panna carnivores, Białowieża Marsh Tit, NSW koala acoustics, Kibale carnivore community)

One agent in `~/eco-b26` (branch `batch-26`, from main at 0691377 after batch 25). Rows from the 2026-11-05 card sort
(#85). Twelve deposits inspected (the cap), four tables built and uploaded to the Redivis draft, eight not built.
Dryad answered without 429s this time. `lib/eco_common.R`'s user agent was changed to the PR #94 line at the
coordinator's request (no email in request headers); it does not change any output.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| dutta_2024_panna_carnivore_occ | multispecies detection, camera traps | Dryad CC0 | 17,352 | tiger, leopard, striped hyena; 476 winter + 338 summer stations in 2019, 5-night sessions; `effort_table` (trap nights 0 exactly where the matrix is NA); station codes are numbered per season (covariates differ for the same code), so unit = season x station, period = season; no coordinates |
| neubauer_2021_bialowieza_marshtit_nmix | repeated counts | Dryad CC0 | 792 | Marsh Tit, 4 plots x 33 years (1987-2019) x 6 counts; the breeding pairs from the independent territory census ship as `period_pairs_within` / `period_pairs_with_adjacent` (a known-truth N-mixture benchmark); countersinging events and males per survey as `obs_`; deposited Total_cases disagrees with the per-survey sum at two plot-years (totals not shipped); below the unit floor |
| law_2021_nsw_koala_occ | single-species detection, acoustic | Dryad CC0 | 1,073 | koala (VU), 128 sites surveyed once each in 2018-2020, up to 19 nights; `deposited_matrix` (trailing NA = `length`, rain NA on the same cells); six forest-history dummies not shipped because the metadata describes them as "0 = not sampled / 1 = sampled" |
| mills_2019_kibale_carnivore_comm | community detection, camera traps | Dryad CC0 | 538,956 | 22 species (19 carnivores incl. dog and cat, 3 golden-cat prey) at 356 stations in 9 surveys, daily occasions; `effort_table` from the station x calendar-day function file plus 9 station-days with a photograph that the file marks 0 (`obs_trapfunction_zero = 1`); coordinates coarsened (golden cat, leopard, lion VU); IUCN filled by hand for five taxa |

Not built (`queue/human_review.csv`): Virginia marsh rope-drag (held: no transect id; a proprietary data-use clause
beside the CC0 badge), St. Marks amphibian metacommunity (blocked: paper; trap method and species-specific dashes),
Svalbard voles SCR (held: occasions per session and trap operation not deposited), White Mountains small mammals
(held: plot-year structure unclear between files; kill-trap daily catches may be removal data), northern Nevada
cameras (blocked: paper; six season blocks unlabelled), range-wide red-backed salamander (held: no trap layout or
visit table), cinereous vultures (blocked: paper; occasion years and group codes in appendices), Wakhan snow leopard
SCR (held: files embargoed to 2027-04-19).

What this batch says about the standard:

- **Station ids reused across seasons for different places** (Panna, also Kibale's surveys): the unit is the
  season-station and `period` only orders the seasons; no unit appears in two periods. Nothing in E4/E8 forbids it,
  but a user fitting colext on such a table gets nothing; a sentence in the guide ("period without revisits") or a
  metadata flag might help.
- **An effort table contradicted by detections** (Kibale): 14 records on 9 station-days that the function file marks 0. Kept as
  surveyed (a photograph shows the camera worked) and flagged per row; the standard does not say which source wins.
- **Independent known truth as a covariate** (Marsh Tit): census pairs ship as `period_` because they come from a
  separate field method, not from the counts; worth naming in the processing guide's "what is not a covariate" list
  as the converse case.
- **Kill traps** (White Mountains): daily catches from snap and pitfall traps are removal data in structure even when
  the authors model them as counts; a ruling on `count` vs `multinomial_cell` for kill-trap series would settle it.
- `iucn_category()` NA again from genus moves (Profelis/Caracal, Lupulella, Herpestes/Galerella, Aonyx capensis vs
  congicus) and NE for Genetta maculata; filled by hand with the reason in the script.

## Batch 27 — 2026-11-05 (card-sorted queue rows: Boston sweat bees, Montana dusky grouse, Richmond pollinators, rangewide tidewater goby eDNA)

One agent in `~/eco-b27` (branch `batch-27`, from main at c60b7a2 after batch 26). Rows from the 2026-11-05 card sort
(#85). Eleven deposits downloaded and read (two more screened from Dryad metadata only and left `available`: Colorado
ant JAGS lists, yellow-legged frog eDNA), five tables built from four deposits and uploaded to the Redivis draft,
seven deposits not built. Dryad answered one version download with 429s; a 90 s back-off cleared it.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| dooley_2025_agapostemon_cjs | CJS, insect mark-resight | Dryad CC0 | 1,200 | bicolored sweat bee at 14 Echinacea patches (in/out of 7 Boston-area gardens), 16 survey days in July 2023, each patch watched on 8; histories rebuilt from the raw captures and asserted equal to the deposited MARK file patch by patch; the README says bees seen at both patches were excluded, but the file carries 7 such bees once per patch (14 units, `unit_two_patch = 1`); the deposited survey intervals do not match the calendar, dates shipped instead |
| leipold_2025_duskygrouse_roads_count | repeated counts | Dryad CC0 | 12,492 | dusky grouse, 2,286 road/trail points in western Montana, 2020-2021, 4 playback counts per morning (outbound and return pass), exact dates from the deposited day number, weather/noise/observer covariates; male/female split of the counts not shipped (35 cells do not sum) |
| leipold_2025_duskygrouse_offtrail_count | repeated counts | Dryad CC0 | 1,180 | same deposit, 2019 off-trail experiment: 150 points, spring and summer, 3 visits x (no playback, playback) as `occasionKind = [time, method]`; spring survey conditions joined from route_type_data.csv, none deposited for summer (NA) |
| ruppel_2025_richmond_pollinator_comm | community detection, flower watches | Dryad CC0 | 4,900 | 14 visitor taxa (4 at genus/family/superfamily; Vespoidea has no GBIF key) on 5 inflorescences of Liatris and/or Pycnanthemum at 50 urban gardens, 2021; occasions stack plant x inflorescence in the authors' order; garden coordinates shipped as published |
| martel_2020_tidewatergoby_edna | multi-scale eDNA | Dryad CC0 | 2,788 | endangered tidewater goby, 813 water samples at 192 sites from the Oregon border to San Diego, 2016 and 2017, 3-6 qPCR replicates; cluster_id = site, unit = sample, period = season; coordinates coarsened and site names withheld (E7); 27 season-2 dates set NA (a 2016 year typo, a DD/MM date, and 13 in the same block that read either way), deposited string kept as `obs_date_as_deposited` |

Not built (`queue/human_review.csv`): Kentucky MTR salamanders 2016 (held: exact duplicate of year 1 of
price_2018_mtr_salamanders_count), saltmarsh sparrow (blocked: paper; no survey year in the deposit), Swiss territory
mapping N-mixture (held: three editors' territory delineations of the same visits; is an editor's interpretation an
observation?), RMBL marmots (blocked: paper; states A/B/C and the 5 within-year occasions undefined), Sierra Nevada
owls (held: the three species files disagree on surveyed weeks and site ids), Atlantic salmon eDNA (held: Ct values
only, no detection call), boreal caribou CKMR (blocked: paper; 26 occasions undated).

What this batch says about the standard:

- **A README contradicted by its own file** (sweat bees): the history file keeps the two-patch bees the README says
  were dropped. The table follows the file (it is what the authors' model saw) and flags the units; the guide could
  say which wins.
- **Dates that are partly DD/MM** (goby): once one row in a block is provably DD/MM, the other ambiguous rows in that
  block cannot be trusted either way. NA plus the deposited string was the least lossy choice; a sentence in the guide
  would make it the rule.
- **eDNA without a detection call** (salmon): Ct values with "Undetermined" are a detection in all but name, but the
  threshold is the analyst's; a ruling on whether "any amplification" may define y would unblock similar deposits.
- **Coordinates of private gardens** (pollinators): shipped at the source's 1e-10 degree because E7 only protects
  taxa; residential garden locations may deserve the E7.4 treatment, which the standard does not say.
- **Species-specific survey sets in a stacked file** (owls): per-species NA patterns at one site-year are the
  per-species occasion question again, which is still deferred.
