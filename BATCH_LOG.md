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
