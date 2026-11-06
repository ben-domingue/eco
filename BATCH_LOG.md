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

## Batch 28 — 2026-11-05 (card-sorted queue rows: Sacramento green sturgeon sonar, Illinois coyotes, Adirondack carnivores, California mesocarnivores, Victorian nest boxes)

One agent in `~/eco-b28` (branch `batch-28`, from main at 9bff2dc after batch 27). Rows from the 2026-11-05 card sort
(#85). Eleven deposits downloaded and read (about a dozen more screened from Dryad metadata only and left `available`),
six tables built from five deposits and uploaded to the Redivis draft, six deposits not built.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| battaile_2023_sacramento_sturgeon_count | repeated counts, side scan sonar | Dryad (UCSC) CC0 | 483 | green sturgeon (IUCN EN, southern DPS ESA threatened; pools deliberately not geolocated by the authors) in 70 upper Sacramento River pools, June 2020, June 2021, July 2022, 1-7 sonar passes per pool per year; the 2022 recount of fish >= 1.5 m ships as `obs_n_ge_1_5m` (it exceeds the full count in 2 of 295 passes, unexplained) and pass direction as `obs_downstream`; the methods say 32 pools in 2020, the file has 30 |
| proudman_2026_illinois_coyote_count | repeated counts, camera detections per week | Dryad CC0 | 3,745 | 164 INHS cameras across Illinois, winters 2021/22-2023/24 (each camera in one), up to 28 weeks; the history file has no ids and is matched to the deployments by alphabetical Site.ID, confirmed by every row's active-week count equalling its deployment length; effort and weather deposited for weeks 1-24 only; README's "2024/25" is 2023/24 in the file |
| twining_2024_adirondack_carniv_occ | multi-species detection, baited cameras | Dryad CC0 | 4,683 | coyote, fisher, marten at 195 sites in the Adirondacks and Tug Hill, 3 x 7-day occasions in each of 2016-2018; the fisher file is in another row order (matched by key); temperature labelled C but reads as F, shipped as `obs_mean_temp_as_deposited`; 6 km2-buffer covariates as `period_*`; fisher IUCN LC set by hand (iucn_category() gives NE) |
| parren_2021_centralvalley_mesocarn_occ | multi-species detection, baited cameras | Dryad CC0 | 20,787 | CDFW drought study, coyote, bobcat, raccoon at 266 Central Valley cameras (137 cells), 2016 or 2017, up to 27 daily surveys with dates from the deposited ordinal days; latitude only deposited |
| parren_2021_mojave_mesocarn_occ | multi-species detection, baited cameras | Dryad CC0 | 8,529 | same deposit, coyote, bobcat, kit fox at 319 Mojave cameras (176 cells), nine 3-day surveys; only the first survey day is deposited, so no `date` (unit_first_survey_date instead); the README says the two-species files list the subordinate species first, but the coyote is first |
| goldingay_2026_diamondhill_nestbox_occ | multi-species detection, nest-box censuses | Dryad CC0 | 1,746 | brush-tailed phascogale (NT) and inland sugar glider at 74 box clusters, Bendigo Regional Park, Victoria, 12 twice-yearly censuses 2018-2023; one cell (cluster 74, May-20) is "-" for gliders and 0 for phascogales and is treated as unsurveyed for both; the female-phascogale file is not a subset of the all-phascogale file (9 cells) and is not shipped; the deposit's separate camera study (30 sites x 60 weeks, 2023-24) is buildable but not built (batch cap) |

Not built (`queue/human_review.csv`): Santa Cruz rats (blocked: paper; which of two trapping periods the 14-site
file holds), NSW woodland bird CJS (blocked: paper; 36 species codes undefined), Connecticut/Rhode Island point
counts (held: no location id or year per survey), Oregon Coast Range winter birds (held: one count per point; would
need the 5-min halves as occasions), great crested newts (blocked: paper; calendar years per population not deposited),
Konza grasshopper sparrows (held: raw captures and resights with reused and misread colour combos; the authors'
cleaning rule is not deposited).

What this batch says about the standard:

- **A filtered recount of the same survey** (sturgeon): the authors recounted the 2022 sonar images keeping only
  fish >= 1.5 m. It is an observation, not a covariate, but a second `y` of the same survey has no slot; it rides as
  an `obs_` column. A rule for "alternative counts of one survey" would settle where it goes.
- **Id-less detection matrices** (coyotes, Turkiye before it): matching rows to sites on the README's word is safe
  only when something in the data checks it; here the active-week counts matched the deployment lengths row by row.
  The guide could ask for such a check whenever rows carry no id.
- **One cell where one species is unsurveyed** (nest boxes): a single "-" disagreement between two species files
  from the same box check was resolved by dropping both rows; the deferred per-species survey-set ruling would cover it.
- **Occasions known only by their first day** (Mojave): when the deposit gives only the first survey date of
  consecutive multi-day occasions, the table ships no `date`; a sentence in the guide on inferring later occasion
  dates would make this consistent.

## Batch 29 — 2026-11-05 (card-sorted queue rows: Honduran cloud-forest birds, French toads, Kerguelen cats, Lusatian capercaillie, Lake Erie watersnakes, Carpathian carnivores)

One agent in `~/eco-b29` (branch `batch-29`, from main at e9fb601 after batch 28). Rows from the 2026-11-05 card sort
(#85), chosen for regions and taxa the corpus lacks. Eleven deposits downloaded and read (the Goldingay camera study
left by batch 28 among them), six tables built from six deposits and uploaded to the Redivis draft, five not built.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| neateclegg_2018_cusuco_birds_count | community counts, point-count transects | Dryad CC0 | 149,017 | 209 bird taxa on 25 transects (2-8 stations each) in Cusuco NP, Honduras, 1-7 surveys a year 2007-2016 (Operation Wallacea); one row per transect survey in the deposit (row_presence); one all-zero species column (Dendroica nigrescens) dropped; two misspellings matched under the correct name; no dates or coordinates; below the unit floor (25) |
| cayuela_2020_bombina_cjs | CJS, annual histories | Dryad CC0 | 63,833 | 11,919 yellow-bellied toads in four French populations (two harvested woodland, two riverine), 5-9 years each within 2000-2014, stacked with population as cluster_id; birth year known for 6,714, always 1-2 years before first capture; rows start at the later of study start and birth year |
| fouchet_2016_kerguelen_cat_cjs | CJS, trapping sessions | Dryad CC0 | 45,749 | 684 feral cats at three Grande Terre sites, Kerguelen, 196 dated sessions 1994-2013 (5-28 days); every capture date falls in exactly one session of its site (asserted); captures pooled to sessions (obs_n_captures); session dates and site NDVI in __periods; age column not shipped (does not advance with date) |
| ludwig_2026_lusatia_capercaillie_cjs | CJS, annual encounters | Dryad CC0 | 3,220 | 552 capercaillie released in Lower Lusatia, Germany, 2012-2024 (Swedish adults and hen-reared juveniles), encountered by feather genotyping and telemetry; release-year 1 flagged obs_release; histories end at confirmed death (58), except bird 212 encountered a year after its recorded death (kept to 2020 as deposited) |
| king_2018_lakeerie_watersnake_cjs | CJS, annual histories | Dryad CC0 | 186,399 | 13,198 Lake Erie watersnakes at 14 island shoreline sites, 2000-2015, from a MARK .inp with 28 site x sex groups; surveyed site-years inferred from captures (193), matching the paper's account of sites added by 2005 and two dropped in 2011-2012 |
| dyck_2022_carpathians_carniv_occ | multi-species detection, cameras | Dryad CC0 | 3,012 | lynx, wildcat and wolf at 64 winter 2018/19 and 76 autumn 2019 stations (different stations), Southern Carpathians, 14-day sessions with active-day effort; three winter sessions with effort 0 and a detection are kept as surveyed (obs_effort_days = 0 as deposited); coordinates as published (all LC) |

Not built (`queue/human_review.csv`): Bolivian Andes bird counts (blocked: paper; the 5 seasons have no years and the
300-species axis no names), Goldingay Diamond Hill camera study (held: 14 of 1,610 site-weeks are "-" for one species
and 0 for the other; the deferred species-specific survey-set ruling), Nui Chua camera traps, Vietnam (held: 43+ records
inside declared camera-failure periods, records at stations with no camera row, common names only), Von der Decken's
hornbill 10-m grid (blocked: paper; what makes a 10-m cell surveyed, coordinates need the raster package), common eider
E-SURGE histories (held: meaning of RC = -1 for 1,009 East Bay birds).

What this batch says about the standard:

- **At-risk start for known-age animals caught in the wild** (toads): E4.4 names the study's first period for
  wild-caught animals and the marking period for animals marked at birth. A toad whose birth year is known but who was
  first caught a year or two later fits neither; the table starts its rows at the later of study start and birth year.
  A sentence in E4.4 would settle it.
- **Known deaths in CJS** (capercaillie): a confirmed death ends the history, like a lost mark; the deposit's one
  encounter after a recorded death (likely a feather shed before death) shows why the rule should say which wins.
- **Detections in zero-effort cells** (Carpathians, Nui Chua): a detection proves a camera worked, so a cell with
  effort 0 and a detection was kept as surveyed in the small Carpathian case (3 cells); Nui Chua's 43 records inside a
  declared failure period are too many to treat that way without a ruling.
- **Sessions of unequal length as periods** (Kerguelen): 196 sessions of 5-28 days at uneven intervals across three
  sites go in one period index with dates in `__periods`; the CJS interval is a user's computation from those dates.

## Batch 30 — 2026-11-05 (card-sorted queue rows: Omo carnivores, Fleay's barred frogs, Gila River fishes, Issa Valley chimpanzees)

One agent in `~/eco-b30` (branch `batch-30`, from main at 4ffe373 after batch 29). Rows from the 2026-11-05 card sort
(#85), chosen for regions and taxa the corpus has less of (Africa, Oceania, amphibians, fish, invertebrates). Seven
deposits downloaded and read, four tables built from four deposits and uploaded to the Redivis draft, three not built.
Dryad rate-limited the version zips for about 40 minutes mid-batch (429 on every zip, metadata still answered), and
two older deposits (Chure leopard, Churia sloth bear) answered 404 on their version zips, so the batch stopped at four
tables to stay inside the token budget.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| asfaw_2025_omo_carniv_occ | multi-species detection, cameras | Dryad CC0 | 1,876 | leopard and spotted hyaena at 36 stations in Omo NP, Ethiopia, May-August 2021, 3-day occasions (up to 30, NA trailing, same pattern for both species, asserted); the Chebera Churchura matrices in the same deposit have no survey year or dates and are not shipped; prey "abundance" columns not shipped (undocumented, shared floor values suggest imputation); no coordinates |
| hollanders_2022_mfleayi_rdms | multi-state (Bd infection) robust design | Dryad CC0 | 30,964 | 686 adult Fleay's barred frogs (IUCN EN) at three NSW creeks, 23 primaries x 1-3 nights, 2017-2021; layout from the authors' m2-cmr.qmd (Zenodo); y = 0/1/2 (not caught / Bd- / Bd+), 3 for captures in the unswabbed last primary (y_raw keeps the source 1); histories padded to the study start; one dates.csv typo (1/2/20 for 1/2/21) corrected with an assertion; companion of the juvenile table hollanders_2022_brindle_mfleayi_msdis |
| pilger_2022_gila_fish_count | community counts, electrofishing and seining | Dryad CC0 | 3,146 | 26 taxa (native and introduced fishes, bullfrog, crayfish, tadpoles) at 16 upper Gila sites each October 2008-2017; area file as sample table plus four 2014 site-years with catch but no area; Black Canyon 2013-2014 (area, no catch) not shipped; four IUCN categories set by hand (GBIF accepted name differs); below the unit floor (16) |
| crunchant_2020_issa_chimp_occ | single-species detection, cameras | Dryad CC0 | 11,342 | chimpanzee (IUCN EN) at 53 systematic and targeted cameras, Issa Valley, Tanzania, 280 daily occasions March-December 2018; coordinates coarsened to 0.1 degree; the acoustic (PAM) sheet held |

Not built (`queue/human_review.csv`): Colorado ant communities (held: JAGS inputs only, no survey year, San Juan species
unnamed), Kalakad-Mundanthurai birds (held: detection records with no list of points counted per visit), W-Arly-Pendjari
lions (held: lion matrix NA at 193 grid-occasions the other matrices survey, the deferred per-species survey-set
ruling; plus a pooled "competitor" history), and the Issa Valley acoustic sheet (held: one row per valley vs four
sensor positions per valley).

What this batch says about the standard:

- **Surveys before the first capture are invisible in first-capture histories** (frogs): a deposit that starts each
  history at first capture shows a survey only through frogs already marked, so a site's surveys before its first
  capture cannot be recovered (Tuntable primary 1, Bat Cave primaries 1-2 have dates but no rows). Padding to the
  study start (E4.4) cannot create them; a sentence in E4.4 saying such surveys are lost unless a survey list is
  deposited would make this explicit.
- **A state the protocol could not observe** (frogs): captures in a primary where no swabs were taken get their own
  state code rather than the source's "uninfected" code; worth a line in the guide next to the y_raw recode rule.

## Batch 31 — 2026-11-05 (card-sorted queue rows: Zakouma carnivores, India invasive plants, Kasungu leopards and hyaenas)

One agent in `~/eco-b31` (branch `batch-31`, from main at 9d7e104 after batch 30). Rows from the 2026-11-05 card sort
(#85), favouring Africa, Asia, plants and non-Dryad sources. Seven deposits read, four tables built from three deposits
and uploaded to the Redivis draft (after Ben published eco v2.3), four not built. Dryad stopped answering version zips
early in the batch: the 429 carries `ratelimit-limit: 100`, `ratelimit-remaining: 0` and a reset at midnight UTC, so
the anonymous API allowance is about 100 requests per day, not a short burst limit; batch 30's long 429 run was the
same daily quota. Screen Dryad candidates with as few metadata calls as possible, and expect a batch that starts late
in the UTC day to get only a few zips. The rest of the batch used Zenodo deposits.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| fraticelli_2026_zakouma_carniv_occ | multi-species detection, cameras | Dryad CC0 | 10,140 | cheetah, leopard, lion, spotted and striped hyaena at 121 stations in Zakouma NP, Chad, dry (Jan-Apr) and wet (Jul-Sep) 2020, 18 five-day occasions per season with trap-days of effort; effort table is the survey set (blank iff effort 0 in every matrix, asserted); wet-season cheetah (no records) and striped hyaena (one record), which the authors did not tabulate, rebuilt from the detection list by the rule that reproduces the deposited matrices (7 of 8 exactly, dry spotted hyaena all but 4 of 1,598 cells; deposited matrices shipped as deposited); prey RAI covariates not shipped; no coordinates |
| mungi_2025_india_invplant_binom | binomial_count, plants | Zenodo CC BY 4.0 | 1,193,665 | 11 invasive plants (Lantana, Prosopis, Parthenium, Chromolaena, Mikania, ...) in 21,703 25 km2 cells of India's tiger landscapes, five All-India estimation cycles 2006-2022; y = replicates with the species of obs_trials replicates (1-19; every cell surveyed every cycle); habitat-suitability model outputs not shipped; standardised covariates; no coordinates; first plant binomial_count table |
| davis_2019_kasungu_leopard_scr | SCR, multi-session, partial identity | Zenodo CC BY 4.0 | 287,568 | 48 leopards (IUCN VU; 15 both-flank, 17 left-only, 16 right-only ids) at 92 camera traps in Kasungu NP, Malawi, annual surveys 2016-2018 (90/120/90 days, 17/50/25 traps); individual x active trap-day; one 2017 photograph on a trap-day the effort matrix marks inactive is believed and the trap-day added to the survey set; traps centred on the array (E7.2) |
| davis_2019_kasungu_hyaena_scr | SCR, multi-session, partial identity | Zenodo CC BY 4.0 | 299,550 | 50 spotted hyaenas (19 both-flank, 14 left, 17 right) on the same array and survey set; traps centred as for the leopard table (shared array) |

Not built (`queue/human_review.csv`): Mongolia snow leopard sign survey (blocked: no survey years in the deposit and
the DDI paper returns a bot wall; otherwise a clean 1,017-cell x 40-segment matrix), Amur tiger and leopard (held:
days-detected per month with no camera effort), Chitwan-Parsa cameras (held: species totals only), Canada warbler
Allee experiment (held: Zenodo "Other (Open)" with no licence text; unlabelled arrays). Serengeti grazers (Dryad
7sqv9s4zk) stays `available`: its zip hit the daily 429 before it could be read. The grey wolf figshare files
(7164929, 7164893) are RAR archives and this machine has no RAR extractor; left `available`.

What this batch says about the standard:

- **A detection on a day the effort matrix calls inactive** (Kasungu leopard, one record): E4 asks the script to say
  which record it believed; a sentence in the processing guide that a dated photograph beats an effort flag (the
  trap-day joins the survey set), unless failures are declared at scale (Ben's deferred ruling), would make this the
  default rather than a per-script choice.
- **Taxa a camera survey recorded but the authors did not tabulate** (Zakouma wet season): rebuilding them from the
  detection list with the authors' own occasion rule, checked against the matrices they did deposit, keeps the
  community table complete without a per-species survey set. Worth a line in the guide, as the alternative is the
  deferred per-species survey-set ruling.

## Batch 32 — 2026-11-05 (non-Dryad queue rows: Snapshot Europe cameras, Zwin butterflies)

One agent in `~/eco-b32` (branch `batch-32`, from main at 25f9e0b after batch 31). Dryad's anonymous daily quota was
spent, so the batch made no Dryad requests and worked only the non-Dryad `available` / `needs-look` rows. Twelve
deposits read, two tables built and uploaded to the Redivis draft, eight held, two left `needs-look`. The Sollmann
et al. Zenodo deposit (a re-use of Snapshot USA and Europe records) pointed at the Snapshot Europe source deposit on
Edmond, which has the deployment table the re-use lacks; that became the batch's main table (new queue row).

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| iannarilli_2026_snapshoteurope_comm | community detection, cameras | Edmond CC BY-SA 4.0 (derived CC BY-NC-SA 4.0) | 878,157 | Snapshot Europe 2021-2022: 63 mammal species (humans excluded, domestic included) at 2,503 deployments in 106 arrays, 24 European countries and Israel; camera-weeks from the deployment dates (effort_table), y_raw = sequences; the 93 deployments that declare a camera failure dropped with their sequences (end_date is the retrieval date, failure date not recorded); coordinates coarsened to 0.1 deg and ids made sequential (European rabbit and mountain gazelle EN, garden dormouse and Italian hare VU in native ranges); mouflon IUCN category set by hand (Ovis gmelini NT); birds not shipped |
| faveyts_2026_zwin_butterfly_count | community counts, butterfly transects | GBIF / Belgian IPT CC BY 4.0 | 2,700 | 27 checklist taxa (incl. Pieris at genus rank) x 100 counts on 12 mapped routes in the Zwin Nature Park, Belgium, April-September 2025, explicit zeros, route length as effort; 2023-2024 counts not shipped (no route identity); below the sample floor (12 units) |

Not built (`queue/human_review.csv`): Sollmann et al. camera re-use (held: records only, sources built), Eresus
sandaliatus transects (held: events within a visit undefined), LIFE RIPARIAS crayfish (held: event, `code` and
`kreeften` columns undefined; street-address localities), the three Huynh-Royle-Hwang N-mixture Zenodo records (held:
two have no files, the third is an unlabelled 50 x 11 BBS wood thrush matrix), the ASF wild boar Frontiers data sheet
(held: supplementary figures only), Lake Constance quagga mussels (held: grab density sampling, scope question). Left
`needs-look`: the jaguar continuous-time SCR DataONE row (its authoritative member node is Dryad, so it waits for
the Dryad quota) and the Borealis camera/genetic SCR row (Borealis in maintenance). The grey wolf RAR files remain
unreadable here (no unrar, 7z or bsdtar).

What this batch says about the standard:

- **A licence field on every data row that differs from the repository's** (Snapshot Europe): Edmond shows CC BY-SA
  4.0; the Wildlife Insights export says metadata CC-BY, images CC-BY-NC, and every sequence row carries
  `license = CC-BY-NC`. The row field is almost certainly WI's image licence (no images ship), but the guide's
  stricter-governs rule was applied and the derived licence is CC BY-NC-SA 4.0. If Ben reads the row field as the
  image licence only, the table can be relabelled CC BY-SA 4.0 with no rebuild of the data.
- **Deployments that declare a failure but no failure date** (Snapshot Europe, 93 of 2,596): the end date is the
  retrieval date (in some the last photograph is up to 36 days earlier), so the deployment's camera-days
  cannot be evidenced. Dropping the whole deployment claims no zero it cannot support; it differs from the deferred
  ruling on records inside a dated failure window, where the window is known.
- **A checklist that grows between years** (Zwin): 21 taxa in 2023-2024, 27 in 2025. Not tested here because only
  2025 has route identity, but a multi-year build would need `__survey_taxa` by period (E4.2).

## Batch 33 — 2026-11-05 (ScienceBase eDNA rows, then small Dryad deposits: streamgage fish eDNA, Vermont moose, Afognak deer, Finnish dunlin)

One agent in `~/eco-b33` (branch `batch-33`, from main at a506650). The two ScienceBase rows went first (no Dryad
quota), then small Dryad deposits on a budget of 12 anonymous requests (6 dataset records, 6 version zips; no
429). Nine deposits read, four tables built and uploaded to the Redivis draft, four held, one blocked.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| sepulveda_2019_streamgage_fish_edna | multi-scale eDNA (streamgage > event > sample > qPCR replicate) | USGS ScienceBase, public domain | 1,520 | kokanee and yellow perch at nine streamgages below reservoirs, six events May-September 2018, 190 water samples x 4 replicates; cluster_id = gage, period = event; field-blank replicate count, inhibition and managers' relative abundance as obs_; the free-text abundance comments (one has a phone number) not shipped |
| siren_2024_vtnh_moose_count | open multistate N-mixture (Dail-Madsen) counts, cameras | Dryad CC0 | 4,400 | monthly maximum counts of calves and adult cows at 225 camera sites, May-August 2014-2019, Vermont and New Hampshire; taxon = species x stage (E6, lifeStage); count sums match the paper (568 cows, 192 calves); the bulls array not shipped (layout does not match its README) |
| finnegan_2024_afognak_deer_scr | closed SCR, camera traps | Dryad CC0 | 18,814 | 23 Sitka black-tailed deer bucks x 26 cameras x 32 nights, Afognak Island, Alaska, 2022; y_raw = independent events per buck-camera-night; night k read as 2022-09-01 + k - 1 (every capture on a worked night); UTM 5N inferred; below the sample floor (23 units) |
| pakanen_2020_dunlin_ms | multi-state CJS (geolocator status) | Dryad CC0 | 5,666 | 337 colour-ringed southern dunlins, 2002-2018, states A/B/C = without, carrying, after removal of a geolocator; seven nest-cage kills removed after 2009 (obs_removed); the authors' design covariates not shipped; the abstract says 338 birds |

Not built (`queue/human_review.csv`): the streamgage release's dreissenid file (held: its June positives at Jackson Lake
and Palisades come with positive field blanks and zebra-mussel sequences, i.e. contamination, and its sample sets do
not match the fish file), the Niobrara mussel qPCR assays (held: every field reaction negative; ship an all-zero
survey?), the TEAM functional-diversity deposit (held: occupancy estimates only), the BC/Chile point-count and ARU
deposit (held: BC point counts dated 2018 in the data, 2019 in the paper). Blocked: the Latin American puma
deposit (Dryad refuses the 703 MB version zip anonymously, HTTP 405; needs a token). Also fixed: row 515 of
`queue/candidates.csv` (the Mara cheetah row) had an unquoted comma in its status, which broke pandas.

What this batch says about the standard:

- **Multi-scale eDNA with time** (streamgage): the standard's E9 mapping is cluster_id = site, unit = sample,
  occasion = replicate; repeated sampling events at a site were added as `period`, so each unit (a water sample)
  lives in one period only. That is legal and keeps the event order a key column, but it is the first table where
  `period` indexes the cluster rather than the unit; a user fitting a dynamic model reads the state at
  cluster_id x period.
- **A field blank is a control, not a unit** (streamgage): blanks were not shipped as rows; each sample carries the
  count of its event's blank replicates that amplified for the same target (`obs_fieldblank_pcr_pos`). Batch 6's
  eDNA tables had no blank data; if this becomes common, a rule in the guide would help.
- **Stage-structured counts with a sex-restricted stage** (moose): the adult class counts cows only. Shipped as
  species x stage under E6 with `taxonRemarks` saying the class is female-only, not as a species x sex composite,
  which E6 forbids.
- **Dryad's version zip has a size ceiling** for anonymous users (the puma deposit, 703 MB, returns 405).
  `download_dryad()` cannot fetch such deposits; per-file downloads need a token.

## Batch 34 — 2026-11-05 (small Dryad deposits: Porsanger voles, Indiana forest birds, Pacific Northwest pika, Ingula grassland birds)

One agent in `~/eco-b34` (branch `batch-34`, from main at 70eba21 after batch 33). Small Dryad deposits, chosen for
designs the corpus is thin on (closed capture-recapture, multi-sign occupancy, interval detections), on a budget of
23 anonymous Dryad requests (12 dataset records, 11 version zips; no 429). Eleven deposits read, four tables built and
uploaded to the Redivis draft, three held, four blocked.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| nicolau_2021_porsanger_vole_ccr | closed capture-recapture, multi-session | Dryad CC0 | 6,290 | 3,145 gray-sided voles x 2 visits in 36 spring and autumn sessions (2000-2017) at 21 roadside stations, Porsanger, Norway; cluster_id = station, period = session; ids are session-scoped (the source treats animals in different sessions as different), so each vole has rows only in its session, as in the Mara cheetah table; station UTM 33 coordinates as published (LC); zero-capture station-sessions are not in the deposit |
| valente_2018_indiana_birds_comm | community occupancy, point counts | Dryad CC0 | 11,001 | 19 forest bird species x 193 stations x 3 visits, southern Indiana, June-July 2014; the three 3 min 20 s intervals of each count as obs_det_interval1-3 (time-to-detection refittable); closure = open, since the paper's own finding is that visits within the season are not closed; the authors deposited only their 19 case-study species |
| goldman_2023_pnw_pika_dynocc | dynamic occupancy, sign surveys | Dryad CC0 | 5,126 | American pika at 771 plots in five park units (OR, ID, CA), 2010-2014 and 2017-2021, 1-3 surveys per plot-year (sample table); y = the source's any-sign flag, with counts of old and fresh scat and haypiles, calls and sightings as obs_ columns so the paper's multi-sign / false-positive model can be refitted |
| maphisa_2019_ingula_birds_comm | community occupancy, walked plot surveys | Dryad CC0 | 32,292 | 92 grassland bird taxa x 20 plots x 351 surveys in 11 months (March 2010 to February 2012), Ingula, South Africa; a record table (row_presence), months as periods, y_raw = records per survey; English names resolved by hand; below the sample floor (20 units) |

Not built (`queue/human_review.csv`): Colorado sage-grouse faecal-pellet genetic CMR (held: the .inp headers say 7 and 8
occasions but the histories have 9 and 10 characters), Swiss MHB passerine territory totals 1999-2014 (held: same
territory-total question as the Swiss MHB 1999-2025 hold, and no quadrat ids), Hutchinson et al. penalised-likelihood
occupancy data (held: species are numbered 1-35 with no names, and no place or year). Blocked: Corbett tigers (paper:
252 MARK occasions with no primary-period boundaries), the tidewater goby eDNA + seine comparison (paper: no sampling
year anywhere in the deposit), and the Chure leopard and Trijuga sloth bear occupancy deposits (Dryad answers 404 to
the anonymous version zip, as Tutakoke brant did).

What this batch says about the standard and the tools:

- **Session-scoped ids in closed CR** (voles): the second table, after the Mara cheetahs, where an animal id lives in
  one session. E4.4 still says a wild animal is at risk from the study's first period; the cheetah precedent (rows only
  in the id's session) was followed. A sentence in E4.4 would make this objective rather than a precedent.
- **Sub-occasion detections** (Indiana birds): the within-count intervals were shipped as obs_ columns on the visit
  row, keeping `occasion` = visit. The alternative (occasion = visit x interval, occasionKind time) would also be
  legal; the standard does not say which, and the choice decides what the IRW view treats as an item.
- **Multi-sign occupancy** (pika): sign-type counts as obs_ columns with `y` = any sign. The paper's model treats each
  sign type as its own detection process with false positives for old sign; E9's multi-method form (`obs_method`, one
  row set per method) could carry that instead, at four times the rows. Left as obs_ because the source records all
  sign types in one search, which is one survey, not a paired method.
- **Common names to taxa** (Ingula): spelling variants and the source's own synonyms (Fan-tailed / Zitting Cisticola,
  White-bellied Bustard / Korhaan, Wattled / African Wattled Lapwing) were merged; three names that do not identify a
  species were kept at genus or family rank with taxonRemarks. The merge of synonyms is a judgement the processing
  guide does not state; each is listed in `__taxa`.
- **Dryad 404 on the version zip** for small deposits (7 KB and 27 KB) is a second failure mode besides the 405 on large
  ones; both need a token.

## Batch 36 — 2026-11-05 (NEON aquatic and vector products: stream fish, ticks, mosquitoes)

One agent in `~/eco-b36` (branch `batch-36-neon`, from main at 002865e). NEON has no daily request cap, so this batch
added NEON products while Dryad is rate-limited: five products read (readme, variables, every site-month of three),
three tables built and uploaded to the Redivis draft, one held, one left available. All three use `RELEASE-2026`, the
basic package and NEON's agency-published plot or reach coordinates; downloads ran as site shards under the 8
requests/s token limit.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| neon_2026_fish_removal | removal (multinomial_cell, removal), community | NEON DP1.20107.001 CC BY 4.0 | 378,355 | 2,441 electrofishing passes in 1,252 reach-bouts at 223 wadeable-stream reaches (23 sites), 272 bouts 2016-2024, 155 taxa (123 species, 32 higher rank incl. NEON-fuzzed ids); three passes at fixed reaches, one at random reaches; y = per-fish records + bulk counts; 23 reach-bouts with an estimated bulk count (13,768 fish), 26 net-compromised bouts and 6 broken pass series dropped whole; lakes not shipped |
| neon_2026_ticks_count | repeated counts, community, drag / flag | NEON DP1.10093.001 CC BY 4.0 | 216,104 | 7,718 plot-bouts at 287 plots (46 sites), 2019-2024, 28 species x life-stage taxa (adult = male + female; larvae mostly Ixodidae only); area dragged as effort; 6,253 surveys before 2019 not shipped (lab counts possibly subsampled, NEON issue log); 20 larval counts are whole thousands, shipped as published and noted |
| neon_2026_mosquitoes_count | repeated counts, community, CO2 light trap | NEON DP1.10043.001 CC BY 4.0 | 7,464,149 | 96,937 trap collections at 518 plots (47 sites), 2014-2024, 77 taxa with >= 1,000 identified individuals (99.7% of individuals; 57 below the cut); y = identified-subsample count, all sexes, with obs_proportion_identified and trap hours as effort; zero-catch collections (no sample kept) are y = 0; year parts, 627 MB, gitignored |

Not built: plant presence DP1.10058.001 (held, `queue/human_review.csv`: the survey set is clean, but a national
pool of thousands of taxa at ~150k subplot surveys forces a cut to under 5% of the flora; asks whether a per-site
pool in `__survey_taxa` is acceptable for NEON products). Macroinvertebrates DP1.20120.001 left `available` (lab
subsampling with subsamplePercent, several sampler types per site; would follow the mosquito pattern).

What this batch says about the standard and the tools:

- **Estimated counts.** E2 removes imputed or interpolated counts but says nothing of a field estimate the source
  labels as such (NEON fish `actualOrEstimated = estimated`, 80% of all fish in the product, mostly lake sites).
  The fish table drops the reach-bout whole rather than flag the row, because dropping one pass breaks the removal
  series; that removes the largest catches, so the choice is not neutral. A sentence in E2 (drop, or keep with an
  `obs_` flag) would settle it. The ticks have the unflagged version: larval counts of exactly 10,000-35,000.
- **Subsample counts.** Mosquito `y` is the count in the identified subsample, with the subsample's share
  (`proportionIdentified`, by wet weight) as an `obs_` column; the whole-catch estimate is not shipped. This is the
  first eco table where `y` counts a known fraction of the sample; it fits E2 as written, but a `subsampleColumn`
  in E10 (like `effortColumn`) would let tools find the offset. Macroinvertebrates, zooplankton and NEON's other
  sorted-sample products would use it too.
- **Survey-quality filters.** Each NEON product needed the same rules: a survey is a sampling-event row with
  samplingImpractical OK or blank; samples NEON marks lost, incomplete, damaged or estimated are dropped; a "target
  taxa present" sample with no laboratory rows is dropped, not zeroed. These are now repeated in five NEON scripts
  and could be one helper in `lib/`.
- **Split bouts.** NEON files the passes after a block-net failure under a second eventID (`.netCompromised`); the
  remaining passes of the bout then look like a 1,3 or 2,3 removal series. Dropped; a removal design needs the
  passes 1..k of one closed bout.
- **National pools again** (batch 14): fish (155 taxa nationally, a median of 6 per site) and ticks are small enough to
  ship whole; mosquitoes needed the carabid-style cut; plants cannot be built at all under one pool.

## Batch 37 — 2026-11-06 (needs-look Dryad rows, with a one-night Dryad token)

One agent in `~/eco-b37` (branch `batch-37`, from main at a6d2647 plus the `download_dryad()` DRYAD_TOKEN commit;
batch 35 merged in mid-batch). Scope: the `needs-look` rows of `queue/candidates.csv` (187 Dryad, 1 figshare). Each
deposit was screened from the Dryad dataset API and its file list first, and downloaded only where a build looked
likely. The dataset and file-list endpoints never refused. Downloads are metered separately: up to 100 per clock
hour, and 500 per day (token and anonymous alike), resetting at 00:00 UTC. The version zip answered 429 from the
first request of the night, so files were fetched one by one, hour by hour. The daily 500 ran out at 08:00 UTC,
and 77 needs-look rows were never fetched. They stay `needs-look` and unclaimed for the next batch.

111 needs-look rows were worked: 59 built (80 tables, all on the Redivis draft; the later ones on `eco_2`, since
`eco` passed SWITCH_AT during the batch), 26 not built, 17 blocked, 9 held (each with a question in
`queue/human_review.csv`).

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| amir_2022_seasia_coabundance_count | Community N-mixture (repeated counts) | count | 22,188 | 416 | 4 | 1 |
| bianchi_2021_furnas_carniv_occ | Multi-species occupancy | detection | 1,263 | 57 | 3 | 1 |
| braga_2024_saopaulo_guan_occ | Single-season occupancy | detection | 1,227 | 205 | 1 | 1 |
| burgstahler_2026_wa_shrubsteppe_mamm_occ | Single-season occupancy (spatial replicates) | detection | 2,820 | 141 | 5 | 4 |
| chambert_2018_pigfrog_acoustic_count | Occupancy with false positives (detection counts) | count | 480 | 60 | 1 | 1 |
| chambert_2018_treefrog_acoustic_count | Occupancy with false positives (detection counts) | count | 360 | 60 | 1 | 1 |
| croose_2019_michigan_mustelid_dynocc | Dynamic community occupancy | detection | 1,500 | 64 | 2 | 3 |
| fidino_2018_chicago_mesocarn_dynocc | Dynamic community occupancy (co-occurrence) | detection | 78,201 | 111 | 3 | 13 |
| fidino_2021_lincolnpark_birds_binom | Community occupancy (binomial counts) | binomial_count | 3,088 | 1 | 193 | 16 |
| fogarty_2022_greatbasin_birds_count | Community N-mixture (multi-season) | count | 264,256 | 275 | 32 | 15 |
| furnas_2021_ncalifornia_carniv_comm | Community occupancy (multi-season) | detection | 406,650 | 1,340 | 15 | 10 |
| gaynor_2020_gorongosa_mamm_binom | Community occupancy (single season, binomial counts) | binomial_count | 2,280 | 60 | 38 | 1 |
| goldingay_2022_grafton_underpass_occ | Community occupancy (single season) | detection | 14,179 | 13 | 11 | 1 |
| goldingay_2022_port_underpass_occ | Community occupancy (single season) | detection | 8,442 | 11 | 9 | 1 |
| goldman_2025_pennsylvania_grouse_occ | Single-season occupancy | detection | 1,431 | 299 | 1 | 3 |
| green_2018_ncal_fisher_scr | Spatial capture-recapture (binomial counts) | binomial_count | 107,364 | 138 | 1 | 8 |
| green_2018_ncal_mesocarn_dynocc | Dynamic community occupancy (interactions) | detection | 4,416 | 100 | 3 | 7 |
| gustafson_2024_seward_gyrfalcon_dynocc | Dynamic occupancy | detection | 1,068 | 97 | 1 | 6 |
| guzy_2018_southcarolina_anuran_comm | Community occupancy (single season) | detection | 4,914 | 42 | 13 | 1 |
| hamer_2017_wtp_growlingfrog_dynocc | Dynamic occupancy | detection | 233 | 33 | 1 | 4 |
| henden_2013_finnmark_birds_dynocc | Dynamic community occupancy | detection | 7,480 | 37 | 17 | 4 |
| higgins_2022_utila_anole_ccr | Closed-population capture-recapture | detection | 356 | 89 | 1 | 1 |
| hostetter_2020_minnesota_lynx_dynocc | Dynamic occupancy | detection | 4,399 | 431 | 1 | 5 |
| husemann_2015_ch_greenbul_cjs | Cormack-Jolly-Seber | detection | 2,161 | 264 | 1 | 25 |
| husemann_2015_fu_greenbul_cjs | Cormack-Jolly-Seber | detection | 374 | 46 | 1 | 26 |
| husemann_2015_mb_greenbul_cjs | Cormack-Jolly-Seber | detection | 1,211 | 177 | 1 | 20 |
| husemann_2015_nd_greenbul_cjs | Cormack-Jolly-Seber | detection | 345 | 38 | 1 | 25 |
| husemann_2015_ng_greenbul_cjs | Cormack-Jolly-Seber | detection | 2,281 | 285 | 1 | 24 |
| iknayan_2023_svalley_pollinator_occ | Community occupancy (single season) | detection | 4,956 | 41 | 42 | 1 |
| jacobson_2020_cookinlet_beluga_cjs | Cormack-Jolly-Seber | detection | 4,632 | 386 | 1 | 12 |
| jones_2021_mdg_kittlitzplover_cjs | Cormack-Jolly-Seber | detection | 13,923 | 1,071 | 1 | 13 |
| jones_2021_mdg_madagascarplover_cjs | Cormack-Jolly-Seber | detection | 4,849 | 373 | 1 | 13 |
| jones_2021_mdg_whitefrontplover_cjs | Cormack-Jolly-Seber | detection | 5,187 | 399 | 1 | 13 |
| joshi_2025_shuklaphanta_leopard_occ | Single-season occupancy | detection | 368 | 92 | 1 | 1 |
| laytonmatthews_2024_hornoya_gull_cjs | Cormack-Jolly-Seber | detection | 2,686 | 158 | 1 | 17 |
| lindenmayer_2022_nsw_woodland_birds_comm | Dynamic community occupancy | detection | 143,437 | 259 | 31 | 17 |
| lloyd_2020_marion_elephantseal_ms | Multi-state / multi-event capture-recapture | state | 134,247 | 6,245 | 1 | 34 |
| lyngdoh_2023_spiti_carniv_occ | Multi-species occupancy with interactions | detection | 1,720 | 97 | 4 | 1 |
| mackenzie_2021_stexas_mesocarniv_dynocc | Dynamic community occupancy (co-occurrence) | detection | 5,625 | 28 | 3 | 14 |
| mcnew_2025_sagegrouse_lek_count | N-mixture (repeated counts) | count | 94 | 23 | 1 | 2 |
| mizel_2018_alaska_sparrows_count | N-mixture (repeated counts) | count | 932 | 150 | 2 | 1 |
| monterroso_2020_iberia_carniv_comm | Community occupancy (single season) | detection | 110,528 | 446 | 8 | 1 |
| morganti_2017_carmagnola_pallidswift_cjs | Cormack-Jolly-Seber | detection | 558 | 93 | 1 | 6 |
| morganti_2017_modena_commonswift_cjs | Cormack-Jolly-Seber | detection | 1,278 | 213 | 1 | 6 |
| murn_2016_kruger_vulture_occ | Single-season occupancy (detection only; occupancy known) | detection | 359 | 17 | 1 | 1 |
| palmero_2023_bpp_lynx_scr | Spatial capture-recapture (binomial counts with day effort) | binomial_count | 686 | 14 | 1 | 1 |
| palmero_2023_sbnp_lynx_scr | Spatial capture-recapture (binomial counts with day effort) | binomial_count | 160 | 5 | 1 | 1 |
| palmero_2023_ucez_lynx_scr | Spatial capture-recapture (binomial counts with day effort) | binomial_count | 1,430 | 22 | 1 | 1 |
| paquet_2015_weaver_helpers_ms | Multi-state / multi-event capture-recapture | state | 2,184 | 168 | 1 | 13 |
| peron_2017_sabap2_broodparasites_occ | Dynamic community occupancy (interactions) | detection | 657,512 | 1,846 | 8 | 7 |
| poutanen_2018_finland_whitetail_scr | Spatial capture-recapture | detection | 14,580 | 27 | 1 | 1 |
| priol_2014_quebec_flyingsquirrel_rd | Robust design capture-recapture | detection | 1,200 | 300 | 1 | 2 |
| regmi_2024_madhesh_tiger_binom | Community occupancy (single season, binomial counts) | binomial_count | 658 | 94 | 7 | 1 |
| rich_2019_mojave_birds_binom | Community occupancy (single season, binomial counts) | binomial_count | 9,240 | 210 | 44 | 1 |
| rich_2019_mojave_mamm_binom | Community occupancy (single season, binomial counts) | binomial_count | 3,150 | 210 | 15 | 1 |
| rivera_2022_chicago_coyote_dielocc | Multi-state occupancy (diel) | state | 5,493 | 105 | 1 | 13 |
| rivera_2022_makira_fosa_dielocc | Multi-state occupancy (diel) | state | 3,004 | 290 | 1 | 1 |
| rivera_2022_rnp_fosa_dielocc | Multi-state occupancy (diel) | state | 831 | 42 | 1 | 1 |
| roder_2020_valais_ungulates_count | Community N-mixture (multi-season) | count | 8,460 | 218 | 5 | 4 |
| rota_2016_midatlantic_carniv_occ | Multi-species occupancy with interactions | detection | 170,224 | 1,906 | 4 | 1 |
| roth_2016_aargau_amph_count | Community N-mixture (repeated counts) | count | 3,848 | 481 | 4 | 1 |
| saeed_2022_murree_spinyfrogs_dynocc | Dynamic community occupancy | detection | 1,426 | 34 | 2 | 2 |
| shah_2025_bardia_tiger_occ | Single-season occupancy | detection | 14,337 | 719 | 1 | 1 |
| taraporevala_2025_kansas_canids_dynocc | Dynamic community occupancy | detection | 2,390 | 74 | 2 | 4 |
| thomas_2025_boreal_moose_ms | Multi-state occupancy | state | 358 | 89 | 1 | 1 |
| thomas_2025_boreal_moose_occ | Single-season occupancy | detection | 358 | 89 | 1 | 1 |
| thuma_2025_ma_bgriseocollis_nest_cr | Capture-recapture (nests, within-season) | detection | 230 | 46 | 1 | 6 |
| thuma_2025_ma_bimpatiens_nest_cr | Capture-recapture (nests, within-season) | detection | 290 | 58 | 1 | 7 |
| tjornlov_2020_christianso_eider_ld | Dead recovery (Burnham live-dead) | state | 240,195 | 11,192 | 1 | 25 |
| tjornlov_2020_vlieland_eider_ld | Dead recovery (Burnham live-dead) | state | 265,036 | 10,236 | 1 | 33 |
| twining_2024_ny_blackbear_occ | Single-season occupancy | detection | 3,234 | 673 | 1 | 1 |
| twining_2024_ny_bobcat_coyote_occ | Multi-species occupancy | detection | 22,376 | 3,849 | 2 | 1 |
| vandeweyer_2024_australia_mouse_scr | Spatial capture-recapture (multi-session) | detection | 1,993,088 | 1,656 | 1 | 4 |
| visagie_2026_tswalu_brownhyaena_scr | Spatial capture-recapture | detection | 389,298 | 39 | 1 | 1 |
| visagie_2026_tswalu_leopard_scr | Spatial capture-recapture | detection | 49,910 | 5 | 1 | 1 |
| visagie_2026_tswalu_spothyaena_scr | Spatial capture-recapture | detection | 69,874 | 7 | 1 | 1 |
| wang_2019_amazon_ocelot_occ | Single-season occupancy | detection | 4,018 | 899 | 1 | 1 |
| warretrodrigues_2022_iguana_msrd | Multi-state robust design capture-recapture | state | 52,020 | 1,156 | 1 | 9 |
| wong_2022_sabah_acacia_mamm_comm | Community occupancy (single season) | detection | 53,575 | 142 | 25 | 1 |
| zuberogoitia_2021_basque_owls_count | Community N-mixture (repeated counts) | count | 23,175 | 526 | 9 | 1 |

Held (`queue/human_review.csv`, each with its question):
- Twining pine marten: the camera operation matrix and capture history named in the README are not deposited, and
  live-trap and hair-tube usage is absent. Build with an all-operated rule?
- Crum right whale: line-transect SCR (the standing hold).
- McFarlane caribou: polygon search-encounter SCR, which has no E9 layout.
- Nakashima time-to-detection: one survey per station. Is this an exception to the replication ruling?
- Strait trout: part of each state is a growth-curve projection.
- Price / Sherman amphibians: the two count files disagree.
- Three spatial mark-resight deposits (Rees feral cats, Whittington grizzlies, the group-association SMR): these
  wait on the same SMR ruling as the grizzly deposit already held.

Blocked:
- On the paper (species, state or event codes undefined in the deposit): Tilker Annamites, Jimenez-Franco 2019 and
  2023 (the same 73 six-letter codes), Hastings sea lions, Cayuela toads, Fortuna shags (events 1-4), Davis wild pig
  eDNA, Davis rabies surveillance, Duangchatrasiri tigers.
- On size: Cole, Holm, Dorning, Geary and DiRenzo (the data sit inside multi-GB archives). Amir was unblocked by
  fetching per file and built; Holm's 48 MB eDNA zip and Dorning's image list were queued per file when the quota ran
  out.
- On a 404: Riecke tits.
- On the download quota: two rows that were claimed before the quota ran out.

What this batch says about the standard and the tools:

- **Dryad's download limit is per clock hour, not per night.** With a token the dataset and file-list endpoints
  answered every request (several hundred), but the download endpoints (version zip and per-file) answered 429 after
  about 100 downloads and reported `ratelimit-limit: 100`, `ratelimit-reset` on the next hour. The version zip was
  refused (429) from the first request. Fetching file by file inside each hour worked; the per-file route redirects
  to S3, and the redirect must not carry the Authorization header (S3 answers 400 if it does; R's libcurl drops it,
  Python's urllib does not).
- **`download_dryad()` fetches whole deposits.** Eight deposits were blocked only because a small data file sits
  beside gigabytes of images or model output. Fetching per file unblocked three of them (Amir built; Fortuna then
  blocked on undefined event codes; Rees held for SMR). A `files =` argument to `download_dryad()` would let the
  scripts do this; it is a lib/ change, so it is left for Ben.
- **The eco shard reached SWITCH_AT during the batch.** The uploader placed the last tables in `eco_2` on its own
  (no `--dataset` passed), as the shard rule says; earlier tables of this batch are in `eco`.
- **Indices from the same cameras.** Several deposits ship covariates computed from the same detector's detections of
  other species or of people (prey and carnivore RAIs, human and dog trap success, a bear detection rate, hikers per
  site, the noisy-miner flag). Following the "dog activity index" precedent they are not shipped; the guide could say
  so in one line, since the cases are common.
- **Multi-state diel occupancy** (Rivera): states not detected / day / night / both fit `responseType = state`
  directly; the deposited codes are 1-4 and were shifted to 0-3 with the deposited code in `y_raw`.
- **Burnham live-dead from MARK LDLD files** (Tjornlov): the second and third live-dead tables after the Hunder trout;
  ducklings marked at hatch start at their ringing year (E4.4), adults at the study's first year.
- **Covariate files in a different row order** (Burgstahler camera visibility, Monterroso site covariates, Wang site
  covariates with re-spelled ids): two were joined by key; Wang's could not be joined and was not shipped.
- **Single-visit with timed intervals** (Gustafson prey point counts, five 2-minute intervals) was not built under the
  replication ruling, although a time-removal model is identifiable from it; worth a sentence in the ruling if Ben
  wants removal-interval point counts admitted.
- **Per-file fetch makes "blocked on size" mostly go away.** With a filename whitelist the hourly fetcher took only
  the data files of deposits that are gigabytes of images or model output (and of large code-and-output deposits),
  which cut the night's download count by roughly a third. A `files =` argument to `download_dryad()` would let the
  scripts do the same; until then a script built from a partial fetch reads only the files its header names.
- **Stacked site-years.** Two New York camera surveys reuse site names across years at different coordinates, so
  the unit is the site-year (as the authors fit them); the coordinates let a user link years if they want to.
- **One-site series.** The Lincoln Park bird walks are one unit (days seen of days walked, 16 years over a
  century); the floor flags it, the data are still a clean binomial series.
- **Overlap between deposits.** The statewide New York winter survey contains the Northern Zone 2016-2018 coyote
  detections already in twining_2024_adirondack_carniv_occ; built, with the overlap stated in notes. The standard
  says nothing about partial overlap between deposits.

## Japanese burrowing cricket (#53, part of #17) — 2026-11-04

One queue row, one table, nothing held. Passes `eco-validate --irw` (exit 0) with four IRW warnings: `cov_prefix`, `imputed_values`, `sample_floor` (animal data are exempt) and `pii_screen_unavailable`; `pytest eco_validate/tests` passes.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| cecconi_2025_cricket_occ | single-season occupancy, aural point counts | Dryad CC0 | 147 | invasive cricket, 49 sites x 3 counts, central Kentucky, 19 September to 5 November 2024; detected at 16 sites; no coordinates deposited |

What this table says about the standard and the tools:

- **E8 and the year.** The data file and README give only an ordinal day; the year is in the abstract on the Dryad page. `date` is built from 2024 + the ordinal, and the script asserts that the ordinals span exactly the abstract's two dates. The queue note's "2024 per README" is wrong.
- **Closure over seven weeks.** `closure = open` (changed from `closed` in review, PR #64): the counts span about seven weeks across the end of the calling season. `closureNote` records that the authors fit single-season occupancy.
- **`metadata/run_pipeline.sh`** uses `declare -A`, which macOS's bash 3.2 cannot run, and on a clone without the gitignored cores stages 01 to 03 would drop those tables' rows. Only this table's `metadata.csv` row was added, computed by the unmodified `01_metadata.R`; `biblio.csv`, `tags.csv` and `status.json` were not regenerated. Since fixed on `main`: bash 3.2 by #67 (filed as #65), the dropped rows by #74 (filed as #66).

## Batch 35 — 2026-11-06 (papers Ben fetched, rows #116 lifted, the puma and Swiss MHB, more Dryad rows on a short-lived token)

One coordinating agent in `~/eco-b35` (branch `batch-35`, from main with rulings #116 and a `download_dryad()` token
change; main merged in again for the shard-aware uploader, #119), with up to two build agents at a time. Ben supplied
a one-off Dryad API token valid from about 03:00 to 13:00 UTC; it was loaded into the shell for each run and never
printed or committed. `processing_guide.md` and the standard's changelog now say the intake is anonymous by default
and uses `DRYAD_TOKEN` when Ben supplies one. Papers Ben fetched (`~/eco_papers/`) settled the sage-grouse occasions,
the Corbett tiger primaries, the Kapitia skink secondaries, the NSW bird codes, the tidewater goby and saltmarsh
sparrow survey years; they did not settle the Mediterranean fish visual census, the Nevada season blocks, the
Bolivian bird species order or the steelhead occasion structure. One table family (`goldingay_2026_bendigo_camera_occ`)
went to the new Redivis shard `datapages.eco_2`, as Ben asked; every other table went to `datapages.eco`. Drafts only.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| goldingay_2026_bendigo_camera_occ | dynamic occupancy, cameras | Dryad CC0 | 3,086 | phascogale and inland sugar glider, 30 sites (near / far from nest boxes, Sedgwick SF) x 60 weeks in 5 season blocks, Jan 2023-Feb 2024; 14 site-weeks with no camera for one species dropped for both (shared-detector ruling); on the new shard `datapages.eco_2` |
| sharma_2021_spiti_snowleopard_scr | count-detector SCR, cameras | Dryad CC0 | 480 | first table under the count-detector ruling: 16 snow leopards x 30 traps, y = encounters under the 4-hour rule, obs_effort_days; trap coordinates displaced by the source and shipped as published (E7.5); habitat mask not shipped |
| schorr_2021_yampa_mylu_rd | robust design, PIT antennas | Dryad CC0 | 65,245 | 1,741 little brown bats at a house and a barn roost, 10 closed sessions (early / late summer 2014-2018), weekly occasions; survey set inferred (a roost-week with any detection, ruling 2026-11-06), 82 of 96 roost-weeks; juveniles from their marking session; mean-filled body condition not shipped |
| botsch_2020_tits_territory_count | repeated counts, territory mapping | Dryad CC0 | 1,008 | first territory-editor table: Great and Blue Tit x 24 subsites, 3-4 visits x 3 editors (occasion = visit x editor, observer = editor, closure dependent), Switzerland 2014-2015; per-territory histories not shipped; the editors' totals file disagrees with the DH file in 1 of 288 cells |
| sepulveda_2019_streamgage_dreis_edna | multi-scale eDNA (gage > event > sample > qPCR) | USGS ScienceBase, public domain | 776 | dreissenid DRE16S screen, 200 river samples x 4 replicates at 9 gages, 6 events 2018; y = amplified, Cq in y_raw; obs_blank_positive on 5 events whose field blank amplified; the QM / ZM / 16S verification (contamination at Jackson Lake and Palisades) not shipped; American Falls samples 5-10 have their replicates split over two event dates as deposited |
| osborne_2026_largeheath_dynocc | dynamic occupancy, transect visits | MMU figshare, ODC-By 1.0 | 27,508 | reintroduced Large Heath, 380 nine-metre bog compartments x 9-23 visits a year, 2021-2025; first ODC-By table; coordinates snapped to the 10 km UTM cell (the source calls the species threatened); one site id typo normalised |
| inbo_2026_flanders_butterfly_count | community counts, Pollard walks | GBIF / INBO IPT, CC BY-NC 4.0 (stricter of CC BY-NC and CC0) | 445,300 | 50 butterfly taxa x 8,906 visits on 112 routes, Flanders 1991-2020; sections summed per visit (empty sections are not in the archive); visit weather as obs_; coordinates as INBO generalised them |
| ohrens_2026_latam_puma_occ | occupancy, cameras (daily) | Dryad CC0 | 1,169,563 | puma at 13,148 stations in 19 countries, 2001-2023, compiled from 200+ contributors; period = calendar year, occasion = active day; obs_survey; fetched file by file with the token (703 MB zip refused) |
| chauvenet_2014_crundale_serotine_ms | multi-state CJS (J / U / B) | Dryad CC0 | 4,076 | 228 female serotine bats, Crundale roost, Kent, 23 capture years 1987-2011; juveniles from their marking year; POPAN files a recode (asserted) |
| chauvenet_2014_hollingbury_serotine_ms | multi-state CJS (J / U / B) | Dryad CC0 | 972 | 102 females, Hollingbury roost, Brighton, 12 capture years 1989-2011 |
| perea_2025_coastalplain_bats_comm | community occupancy, acoustic | Dryad CC0 | 5,760 | 8 bat taxa (two pooled call groups) x 240 sites x 3 nights, six pine-forest landscapes FL-NC, winters 2020-2022; no coordinates (private land) |
| goldberg_2015_manas_leopard_scr | closed SCR, cameras | Dryad CC0 | 58,058 | 22 leopards x 29 stations x 91 days, Royal Manas NP, Bhutan, 2010-2011; survey set from the paper's statement of continuous operation (inferred); traps centred (IUCN VU) |
| schmelzle_2016_tidewatergoby_edna | multi-scale occupancy, eDNA | Dryad CC0 | 2,148 | endangered tidewater goby, 358 water samples x 6 qPCR wells at 39 coastal sites (CA/OR), Aug-Dec 2014, cluster_id = site; raw lab sheet shipped over the WinBUGS input (27 samples differ; raw matches the paper's 19/39 positive sites); coordinates = 0.1-deg cell of each site's median (11 keying errors), names withheld; paired seine not shipped (no sample-level seine survey set) |
| marshall_2020_saltmarshsparrow_nmix | N-mixture, point counts | Dryad CC0 | 2,718 | endangered Saltmarsh Sparrow, 913 SHARP points in 413 marsh patches x 2-3 counts, Maine-Maryland, Apr-Jul 2012 (year from the paper); survey covariates z-scores only, 4 all-zero (mean-filled) survey records set NA; latitude only, coarsened (IUCN EN); cluster_id = patch |
| bisht_2019_corbett_tiger_rd | robust design, camera-trap CR | Dryad CC0 | 77,364 | 307 tigers x 6 annual primaries x 42 nights (paper s. 2.4, p. 5); full rectangle E4.4; cluster_id = MARK block; the deposit's per-year counts differ from the paper's Table 2 (cumulative totals agree within 2; asserted, noted); IUCN EN, no coordinates |
| shyvers_2020_ppr_sagegrouse_rd | robust design, genetic CR (faecal pellets) | Dryad CC0 | 8,145 | 543 greater sage-grouse, 2 winters x 7/8 occasions, NW Colorado; occasions identified by reproducing the paper's Table 3 p (trailing history characters are padding); ids linked across seasons (82, as the paper); y_raw = M/F letter; no coordinates |
| jordan_2025_kapitia_skink_rd | robust design, photo-ID under cover objects | Dryad CC0 | 18,720 | 360 Kapitia skinks x 5 primaries (10,10,11,10,11 secondaries, the only split that reproduces the collapsed files); AI-supplemented identities only, human-only set in notShipped; IUCN CR, no coordinates |
| belder_2020_nsw_*_cjs (13 tables) | CJS, mist nets | Dryad CC0 | 3,151 in all | one table per species (ruling #20), 21 restoration sites, NSW, 2015-2017; 13 of 38 codes fixed from the paper (the 10 colour-banded species by initials, plus the top-5 list), 25 undefined codes (208 birds) not built; R5_CJS is a recode of R5; Barker resightings not shipped; diamondfiretail (VU) coarsened to 0.1 deg and site names replaced by sequential ids (E7.4) |
| morrison_2023_fundy_salmon_edna | multi-scale eDNA (station > day > bottle > qPCR) | Dryad CC0 | 1,641 | Inner Bay of Fundy Atlantic salmon (SARA endangered): 2020 parr survey, 2020 full transect and 2021 smolt survey in one table (21 days, 547 bottles, 53 stations); y = Ct present (no call stated), Ct in y_raw; obs_blank_positive = 1 on day iv (FB3iv), NA on days vii and ix (no blank deposited); coordinates coarsened, river/pool names withheld; Full_trans pool repeats disagree in 16 of 288 Ct (All_df shipped); Full_rls_mean (means only) not shipped |
| strebel_2026_swiss_mhb_count | community counts (N-mixture), multi-season | Zenodo CC BY 4.0 (paper doi:10.1002/ecy.70268) | 2,867,650 | Swiss MHB 1999-2025, 267 squares x 2-3 visits, territories per visit; 158 of 162 species (4 never positive per visit); __survey_taxa (taxon x square x year x visit) for date limits, undigitised maps (39,211 species x square-years) and invalid records (188); coarsened to 0.1 deg (turtle dove VU); 4 species withheld by the source (taxaWithheld); overlaps kery_2014_mhb_comm |
| strebel_2026_swiss_mhb_exact_count | same | same | 2,854,066 | E7.3 sibling without the turtle dove, coordinates as published |
| strebel_2026_swiss_mhb_total_count | season territory totals (count), multi-season | same | 1,152,118 | season total per square-year, 162 species (per-visit series and season total ruling): 36,530 positive totals have no per-visit values (33,407 at 3-visit squares, 3,123 at 2-visit squares); obs_per_visit_values; coarsened |
| strebel_2026_swiss_mhb_total_exact_count | same | same | 1,145,005 | E7.3 sibling without the turtle dove |
| roderiksen_2023_norway_tundra_carniv_occ | community occupancy, cameras (daily) | Dryad CC0 | 93,892 | 4 predators at 96 baited stations, late winters 2011-2020, alpine and Arctic files in one table (unit_region); ISO date from year + day of year; obs_bait_present; period_rodent_index (separate snap-trap survey); station coordinates not shipped; the deposit says 98 sites, the files hold 96 |
| sovie_2023_ichauway_wildlife_comm | community occupancy, cameras (5-day occasions) | Dryad CC0 | 4,158 | 11 mammals and game birds on pine / edge / hardwood transects in 6 patches (methods say 5), Ichauway, Georgia; cluster_id = patch; common names resolved to the region's only species of that name, rabbit at genus; no occasion dates |
| barrueto_2023_nwt_grizzly_scr | SCR, hair snags, multi-session | Dryad CC0 | 533,664 | 204 genotyped grizzly bears x 218 detectors x 6 visits, 2012-2014, ids linked across years; obs_lure; traps centred on the array (E7 a: the source calls the grizzly a species at risk in Canada) |
| sossover_2026_outerbanks_coyote_ms | multi-state robust design, faecal DNA | Dryad CC0 | 744 | 62 coyotes, 7 Outer Banks islands as states, 3 primaries x 4 secondaries; Bodie (state 1) not surveyed in period 1 (__periods states_not_surveyed); no paper linked |
| bauer_2022_neshrubland_birds_count | community point counts (N-mixture) | Dryad CC0 | 26,070 | 79 taxa x 66 points (44 in 2015) x 3 visits x 2 years, New England cottontail shrublands; y within 50 m, no flyovers (the authors' set); minute intervals as obs_int1-10 and outer-bin and flyover counts as obs_; 14 outer-only taxa and the undefined WOSP not shipped |
| bedwell_2020_sierranevada_edna_binom | binomial_count, eDNA, multi-season | Dryad CC0 | 80 | 10 lakes and streams x 4 months (May-August 2016) x Bd and yellow-legged frogs (pooled); y = sampling sites the authors called positive (2 of 6 qPCR replicates) of obs_trials sites sampled; filter-level files zero-truncated, not shipped |
| katuwal_2025_parsakoshi_leopard_binom | binomial_count, cameras | Dryad CC0 | 154 | leopard at 154 cameras, Parsa-Koshi, Nepal: weeks detected of 3 (the README's protocol; failures not recorded); tiger, prey, human and livestock detections as unit_ covariates; no coordinates |
| manzo_2024_pedregulho_tayra_dog_occ | single-season occupancy, cameras | Dryad CC0 | 1,904 | tayra and domestic dog x 69 points (README says 73) x 21 five-day occasions, Brazil; 20 point-occasions surveyed for one species only dropped for both (shared-detector ruling) |
| whitworth_2019_manu_terr_mamm_binom | binomial_count, community cameras | Dryad CC0 | 2,002 | 26 terrestrial mammals x 68 stations, Manu, Peru, 2015-2016; y = six-day sessions with a detection of sessions surveyed (the authors' dbin likelihood); arboreal cameras held |
| zamuda_2022_yalemyers_mesopred_dynocc | dynamic occupancy, cameras | Dryad CC0 | 6,272 | 4 mesopredators x 56 sites (paper says 60) x 4 seasons x 7 three-day surveys, Connecticut; complete matrix |
| curveirasantos_2019_guadiana_carn_occ | single-season occupancy, cameras | Dryad CC0 | 1,220 | 4 carnivores x 77 stations x four 6-day occasions, Guadiana valley, Portugal; occupied-station counts match the paper's Table 2; badger, genet and otter not deposited |
| raman_2006_anamalai_birds_count | community counts, spatial replicates | Dryad CC0 | 40,767 | 107 bird taxa x 13 rainforest fragments x 25-30 point counts, Anamalai, India; coarsened (great and Malabar grey hornbills VU), site names dropped; flock-size estimates not shipped |
| raman_2006_anamalai_birds_exact_count | same | same | 40,005 | E7.3 sibling without the two hornbills, coordinates as published |
| roberts_2019_sierranevada_birds_count | community counts, multi-season | Dryad CC0 | 2,338,028 | 154 bird taxa x 1,353 points, 15,182 visits, Sierra Nevada, 2009-2016; explicit no-detection rows; coarsened for the evening grosbeak (VU), elevation to 100 m; 24 undefined X-codes (3,438 records) not shipped; alpha codes from the IBP list fetched from GitHub |
| roberts_2019_sierrane_birds_exact_count | same | same | 2,322,846 | E7.3 sibling without the evening grosbeak |
| cove_2018_lowerkeys_dynocc | dynamic occupancy, cameras | Dryad CC0 | 5,124 | Lower Keys marsh rabbit (endangered, as the source says) and feral cat x 84 sites x 2 periods x 16 occasions; UTM snapped to 10 km cells, LiDAR elevation (standardised) not shipped; the 2013-14 cat-count columns are copies of 2015, only 2015 ships |
| cove_2018_lowerkeys_exact_dynocc | same | same | 2,562 | E7.3 sibling, cat only, UTM as deposited |
| bruce_2022_wettropics_cat_occ | single-season occupancy, cameras | Dryad CC0 | 911 | feral cat x 90 sites x 18 five-day occasions, Wet Tropics, Australia; NA cells match the effort file; 18 Paluma NP sites in the paper not deposited |
| barrile_2022_bridgerteton_toad_msrd | multi-state robust design | Dryad CC0 | 45,318 | 1,415 boreal toads, 6 seasons x 3-9 occasions (layout recovered from capture dates, asserted), states = primary / alternative breeding site; survey set inferred (a site-occasion with any capture); paper not read |
| sweeney_2026_ocracoke_plover_cjs | CJS / Jolly-Seber stopover, resightings | Dryad CC0 | 81,230 | 399 colour-marked piping plovers x 8 seasons x up to 37 surveys, Ocracoke, NC; surveys file lists every survey; hatch-year birds from their hatch year; banding-year resightings of South Point birds were removed by the authors, so those rows are absent |
| sweeney_2026_ocracoke_plover_count | repeated counts | same | 207 | the same surveys' plover counts at one site, with obs_marked; below the sample floor |
| feldman_2023_quebec_wetland_comm | community occupancy, cameras | Dryad CC0 | 78,008 | 56 taxa (French names mapped by hand) x 50 ponds x 2 seven-day sessions per year x 2 years; Rusty Blackbird (VU) => latitude (the only coordinate deposited) snapped to its 0.1 deg band; the README's session labels are contradicted by the days-since-snowmelt data, and the data are followed |
| feldman_2023_quebec_wetland_exact_comm | same | same | 76,615 | E7.3 sibling without the Rusty Blackbird |
| fiss_2024_pennsylvania_birds_count | N-mixture point counts | Dryad CC0 | 2,292 | 2 warblers x 573 points x 2 visits x 2 years; minute of first detection as obs_ttd with obs_ttd_censored (ruling 2026-11-06), distance bins as obs_ (breaks not deposited) |
| fiss_2024_pennsylvania_birds_aru_occ | occupancy, ARU | same | 8,140 | classifier-verified daily detections at 571 points x 10 days; __survey_taxa (Cerulean Warbler classified at 2 of 5 blocks) |
| barros_2024_mostela_weasel_occ | multi-scale occupancy, paired methods (obs_method) | Zenodo CC BY 4.0 | 781 | least weasel, 56 stations x 7 five-day occasions x 2 devices (Mostela box, tree camera), Portugal, Jan-Apr 2021; the paper (Basic Appl Ecol 75:18-25, p.19-21, Table 1) settled the year, the occasions and the 3 NAs (station 19's Mostela not operating on occasions 1-3); tree-camera trap-nights at CL 1,068 in the deposit vs 1,029 in Table 1 |
| letourneux_2022_snowgoose_ms | multi-state CMR with dead recoveries (multievent) | Dryad CC0 | 623,530 | 22,599 adult female greater snow geese, 30 yearly occasions 1990-2019: ring only / ring + collar / shot and recovered; histories expanded by frequency, wild adults from 1990; a recovery ends the history (obs_removed); 344 birds lose a collar; the deposited harvest-rate covariate not shipped (it may be estimated from these recoveries); paper not supplied |
| whittington_2025_banff_grizzly_occ | dynamic occupancy, cameras | Dryad CC0 | 31,180 | grizzly bear at 625 Parks Canada camera sites x 10 years (2012-2021) x 14 occasions (14-day windows from 1 May); NDays effort; UTM coordinates kept as published (agency rule); the spatial mark-resight part (collared bears, GPS telemetry) not an E9 design, not shipped |

Not built (`queue/human_review.csv`, one row each with the question):

- Held after reading the paper Ben fetched: Mediterranean fish visual census (protocols, visits and `sp.n = 0` rows not
  in the paper; Appendix S1 missing), Northern Nevada cameras (the six season blocks can only be inferred from the lure
  covariate), Bolivian Andes birds (species order of the count array), Upper Columbia steelhead (structure settled,
  but space-ordered occasions with undated dead recoveries need a ruling), Hutchinson penalised occupancy (no names,
  place or years in the paper), Colorado ants (San Juan species unnamed; Appendix 1 missing), great crested newts
  (per-population years only plotted), Western Ghats frogs (one night search per site: replication rule), Von der
  Decken's hornbill (author-discretised route buffers with an outcome-dependent exclusion: ruling).
- Settled by the paper but not downloaded tonight (Dryad 429 from 04:20 UTC): three eider colonies (RC = cholera
  death, right-censored), Issa chimp PAM sheet (a row is a four-sensor cluster location), dusky grouse (visits are
  passive / playback pairs), boreal caribou (T-to-winter map must come from the deposit), St. Marks amphibians ("-"
  undefined in the paper).
- Held or blocked for other reasons: the Bornand time-to-detection plants (species named by one word; paper closed),
  the Niobrara all-zero mussel eDNA (built, blocked by the validator, #120), the paired seine of the tidewater goby
  deposit, the human-only Kapitia skink identifications, the arboreal Manu cameras, the Himachal snow leopard SECR
  (traps encrypted), the Golden-winged Warbler point counts (survey key does not reconcile), the Scottish badger and
  Maine marten cameras (no survey years; papers closed), the Finnmark mesocarnivores (species key mismatch), the
  western sandpiper radio-detection histories (telemetry scope), the fisher occupancy + SCR deposited only as R code,
  the coyote / fisher / marten weekly counts (survey set not evidenced), the bat acoustic inputs (species codes
  undefined), the black bear SCR + REM (trap list incomplete; REM scope), and the Whittington grizzly spatial
  mark-resight part.
- Blocked at Dryad even with the token: Tutakoke brant, Chure leopard and Trijuga sloth bear (404 on the zip and on
  every file).

What this batch says about the standard and the tools:

- **The validator disagrees with the standard twice** (#120). The all-zero Niobrara mussel eDNA table
  (`klymus_2023_niobrara_mussel_edna`, script committed) conforms to the eco standard but `--irw` blocks it with
  `irw:resp_variation`, so it was not uploaded; and the `replication` intake warning fires on the count-detector SCR
  (`sharma_2021_spiti_snowleopard_scr`) that the standard exempts. The validator was not edited.
- **An event with no field blank** (Fundy salmon): the eDNA ruling says `obs_blank_positive` is 0 on every row of an
  event whose blank did not amplify; two sampling days have no blank deposited at all, and the table carries NA there,
  not 0, since a missing blank is not a clean one. Worth a sentence in the guide.
- **"The source says so" for E7 (a)** was read three times: the Large Heath (IUCN LC, "a threatened butterfly" in the
  source title), the grizzly ("a species at risk" in Canada) and the snow leopard deposits. Coordinates were coarsened
  or trap arrays centred in the first two; both are reversible if Ben reads (a) as an explicit sensitivity flag only.
- **Coarsening one species while its siblings stay exact** (NSW woodland birds): the Diamond Firetail (VU) table is
  coarsened and its site names replaced, but its site attributes (area, perimeter, planting age) match the twelve
  sibling species tables, which publish the exact site coordinates, so a user can re-link them. E7 does not address
  linkage across tables from one deposit.
- **A state not surveyed in one period** (Outer Banks coyotes, islands as states): there is no per-row place to say a
  state could not be observed; it is recorded in `__periods`.
- **Survey sets taken from a paper's sentence** (Manas leopards: "stations operated continuously"): shipped as
  `inferred` with the sentence quoted in `surveyEvidenceNote`, since the deposit itself has no operation table.
- **Two identification sets from the same photographs** (Kapitia skink: human-only and AI-supplemented): only the
  corrected set ships; whether the other is a second table is a question for Ben.
- **Data deposited as R code** (`dput` objects, fisher occupancy + SCR): not read, since the pipeline does not execute
  code from a deposit.
- **Dryad with a token**: the version zip is still refused for large deposits and for some small ones (404); per-file
  downloads worked for the puma (703 MB) and others, but for the Chure leopard, Trijuga sloth bear and Tutakoke brant
  deposits every file also returns 404, so their files are gone at Dryad. The token's rate limit is not unlimited:
  429s began after about 120 requests in a few minutes (03:22 UTC); pacing at one deposit per 20 s then fetched about
  20 more, but from about 04:20 UTC Dryad answered 429 to every request, with the token and anonymously, even at one
  request per 75-90 s, so the batch stopped asking. The token never returned 401. Roughly 220 Dryad requests in all.

## Batch 38 — 2026-11-06 (NEON follow-up: Ben's rulings 17 to 21, plant presence, stream macroinvertebrates)

One agent in `~/eco-b38` (branch `batch-38-neon`, from origin/main at dc8187a), using the batch 36 raw cache. Rulings
17 to 21 (2026-11-06) are written into `standard.md` (E2, E4.2, E6, E10, changelog) and `processing_guide.md`; three
batch 36 tables were rebuilt under them and two new NEON products built. All `RELEASE-2026`, basic package, CC BY 4.0,
agency-published coordinates.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| neon_2026_fish_removal (rebuilt) | removal (multinomial_cell), community | NEON DP1.20107.001 | 386,260 | ruling 17: the 23 reach-bouts with a bulk count NEON marks estimated (13,768 fish) are kept, with `obs_count_estimated` = 1 on the 81 pass x taxon rows whose y includes one; 2,492 passes, 278 bouts (was 2,441 and 272). GBIF fix: Cyprinella, Fundulus and Micropterus had matched the kingdom Animalia (strict match on a homonym, accepted under `allow_higher`); now matched with their authors, and Cyprinidae (no strict match at all) set by hand to the fish family's key 7336 |
| neon_2026_ticks_count (rebuilt) | repeated counts, community | NEON DP1.10093.001 | 216,104 | ruling 18: `obs_count_likely_estimated` = 1 on the 20 rows built from a larval laboratory count in an exact multiple of 1,000; no sample from 2019 is marked "Tick count estimated" (asserted, so ruling 17 adds no flag here) |
| neon_2026_mosquitoes_count (rebuilt) | repeated counts, community | NEON DP1.10043.001 | 7,464,149 | ruling 21: `subsampleColumn = "obs_proportion_identified"`; data unchanged |
| neon_2026_plants_occ | community occupancy (multi-season), detection | NEON DP1.10058.001 | 24,458,465 | ruling 19: 85,349 visits to 12,622 permanent 1 m2 subplots (1,598 plots, 47 sites), 2013-2025 in 12 yearly periods, 4,980 taxa; per-site pools (median 264 taxa, 66-756) in `__survey_taxa` (3,567,548 rows); `obs_percent_cover`; year parts |
| neon_2026_macroinverts_count | repeated counts, community | NEON DP1.20120.001 | 4,833,657 | 3,933 benthic samples at 24 wadeable-stream sites, 539 bouts (spring, summer, fall) 2014-2024, about 8 samples per bout (occasion, spatial), 1,229 taxa national pool; y = animals counted in the sorted fraction, `obs_subsample_fraction` (subsampleColumn), benthic area as effort; year parts |

Scale for plants (ruling 19 asked for care). NEON nests eight 1 m2 subplots, 10 m2 and 100 m2 subplots in each 400 m2
plot. Only the 1 m2 subplot has a complete species list at every visit: the 10 m2 and 100 m2 rows hold only the
species new at that scale, and the product remarks say the implied nested records are "not always populated", so
presence at the larger scales is a union the table would have to construct. The 1 m2 subplots are permanent and
listed every year (median eight years), twice a year at bimodal sites, so the table is unit = subplot (cluster_id =
plot), period = year, occasion = visit; 398 subplots listed twice within one bout are kept as extra visits. The
per-site pool is the taxa this table records at the site; `surveyEvidenceNote` says the zeros rest on it.

Macroinvertebrates: the design fits (bouts of about eight spatial samples in the two dominant habitats, three bouts
a year), so the product was built rather than held. Lakes and rivers (ponar near the buoy, littoral sweeps) are other
protocols, not built. Dropped samples: 27 of a second reach filed under another site's bout (STCU, STKG, STMA, STWA),
3 '.DNA' samples, one MAYF bout whose snag samples came 36 days after its cores, and 347 samples with an N row naming
a taxon, a counted taxon with no count, or a row marked "damaged, affecting analysis".

Shared code: `eco_validate` checks `subsampleColumn` (an `obs_` column of the core, values in (0, 1] or empty; R twin in
`lib/eco_common.R`; test `test_subsample_column`); `write_table_parts()` takes `survey_taxa` (each part checked against
the rows for its units); `gbif_kingdom()` and `gbif_taxon_hinted()` repair taxa whose strict match is not in the
expected kingdom.

What this batch says about the standard and the tools:

- **The strict GBIF match is not safe at higher ranks.** `make_taxa(allow_higher = ...)` accepted a HIGHERRANK match to
  the kingdom (gbif.org/species/1) for three fish genera in batch 36, so the published fish table carried Animalia as
  their taxonID. Strict matching also fails for many common animal and plant genera with homonyms (Orthocladius, Physa,
  Nais, Pinus, Salix, Viola), even with hints; a hinted non-strict match returns the genus itself, labelled
  HIGHERRANK. The new tables accept a hinted match only when its canonical name is the name asked for and its
  kingdom is the expected one. `allow_higher` should probably refuse a kingdom-rank match outright; the other NEON
  tables (carabids, landbirds, small mammals) were not re-checked in this batch.
- **Subsample fractions are not one number per sample.** NEON's macroinvertebrate laboratory picks large or rare taxa
  from the whole sample, so the fraction differs between taxa of one sample (4% of samples), and inv_persample's
  subsamplePercent disagrees with the taxonomy rows' in about a fifth of samples. `obs_subsample_fraction` is
  therefore per row: counted / NEON's estimated total for a taxon found, the persample share for a taxon not found.
  Ruling 21 fits, because E5 lets an `obs_` column vary across taxa within a survey.
- **Life stages in macroinvertebrates** are pooled in y: the laboratory's larva / pupa / adult / immature / none /
  unknown labels are its convention per taxon, not a survey-level split of one species, so E6's life-stage exception
  (used for ticks) was not applied. A question for Ben.
- **Plant pools are large.** The plant table is 24.5M rows with a 3.6M-row `__survey_taxa`, because a per-site pool of
  a few hundred taxa is carried at every 1 m2 visit; it is still about a third of a national-pool table.

## Batch 40 — 2026-11-06 (non-Dryad discovery: USGS ScienceBase and GBIF sampling-event datasets)

Dryad's anonymous quota was spent, so this batch searched elsewhere. EDI is fully walled to scripted
requests now: PASTA search, metadata and data endpoints return 403 ("not authorized"), and the DataONE
member nodes that used to serve LTER objects (gmn.lternet.edu, gmn.edirepository.org) return 403 too, so
no EDI/LTER rows were added. Discovery: the ScienceBase catalog search (occupancy, capture-recapture,
eDNA, call survey, camera trap, encounter history; 54 new rows after deduplication against the queue,
human_review and every `__dataset.json` DOI) and the GBIF occurrence facet `occurrenceStatus = ABSENT`
by dataset (1,000 datasets, of which 420 sampling-event CC0 / CC BY not yet in eco; 23 credible rows
queued as needs-look). Eleven tables built from nine ScienceBase releases, all to eco_2 drafts.

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| carter_2021_louisiana_lamp_calls | NAAMP calling routes | ordinal | 344,844 | 540 | 27 | 21 |
| zipkin_2017_oregon_barredowl_dynocc | dynamic occupancy | detection | 8,806 | 106 | 1 | 20 |
| zipkin_2017_oregon_barredowl_count | repeated counts of pairs | count | 406 | 106 | 1 | 2 |
| wiens_2021_socal_goldeneagle_dynocc | dynamic occupancy | detection | 1,252 | 175 | 1 | 2 |
| waddle_2020_louisiana_marshbird_comm | ARU community occupancy | detection | 3,311 | 33 | 11 | 1 |
| rose_2024_sjvalley_leglesslizard_occ | cover-board occupancy (multi-scale) | detection | 563 | 89 | 1 | 2 |
| laramie_2019_bruneau_trout_edna | eDNA occupancy | detection | 608 | 26 | 2 | 12 |
| hunter_2025_georgia_pinesavanna_occ | single-season occupancy | detection | 966 | 161 | 2 | 1 |
| halstead_2025_yosemite_rasi_cjs | capture histories (daily, 20 years) | detection | 240,192 | 1,251 | 1 | 20 |
| direnzo_2025_elcope_espadarana_cjs | CJS (annual) | detection | 2,075 | 415 | 1 | 5 |
| direnzo_2025_elcope_espadarana_ms | multi-state (Bd infection) | state | 2,331 | 259 | 1 | 9 |

Held: eight ScienceBase releases whose use constraints say the authors "require" or "request that data
users contact them regarding intended use" (Point Reyes TTD, Masticophis, SF gartersnake, two humpback chub
releases, Sonora mud turtles, Massachusetts Wildlife Monitoring Project, Olympic fisher), as unclear terms
under the 2026-11-06 intake ruling. Needs a look: Puerto Rico Eleutherodactylus (code 2 in "binary"
histories), Bristle-thighed Curlew (2015-2016 status from transmitters only), New England MYSE (possibly a
model table). Rejected: yellow-billed cuckoo (site summaries only), dove co-occurrence (built from BBS,
already in eco), NABat summer occupancy (model outputs).

Facts carried into the tables: LAMP's December 1997 rows are in sampling year 1997 although the
metadata put December 1997 in the 1998 sampling year and the release starts 1997-12-20, so no ISO dates
are built (obs_month, obs_day). The Georgia savanna release labels its coordinate columns the wrong way
round (swapped back, asserted). The Rana sierrae individual file has nine PIT codes mangled into E-notation
by a spreadsheet (matched back by mantissa). Bull trout (IUCN VU) on USGS-published stream sites: coarsened
to 0.1 degree, though the guide also says agency-published coordinates are kept (a question for Ben).
The marsh-bird release numbers its sample periods out of date order (renumbered by date; source number in
obs_sample_period).

What strained the standard: none of the tables needed a new rule. Two community point-count releases
(Arkansas and southern Iowa grassland birds) were inspected and queued rather than built: both have
repeated species rows within a survey and survey-level fields that vary within a survey, which need a
stated aggregation rule.

## Batch 41 — 2026-11-06 (USGS ScienceBase rows found by batch 40)

The 31 ScienceBase rows batch 40 queued as `available` were claimed (batch 42 worked the GBIF rows in
parallel). Every release's FGDC `useconst` was read before any download: 29 carry no restriction, two
carry the "authors require that users direct any questions pertaining to appropriate use" clause batch
40 held (Yosemite amphibians, Dixie Valley toads; the queue rows had recorded "use constraints none").
Twenty tables were built from fifteen releases, all to eco_2 drafts.

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| kleeman_2024_dixiefire_ranaboylii_occ | time-to-detection occupancy | detection | 83 | 43 | 1 | 1 |
| grant_2023_canaanvalley_amph_count | egg-mass / larval counts, two observers per visit | count | 13,712 | 108 | 4 | 13 |
| glorioso_2021_louisiana_turtle_count | hoop-net community counts | count | 1,666 | 119 | 7 | 1 |
| holcomb_2017_suwannee_moccasinshell_occ | occupancy, surveyors as occasions | detection | 662 | 220 | 1 | 1 |
| valente_2024_oregon_murrelet_state | multi-state station surveys | state | 447 | 132 | 1 | 1 |
| mccaffery_2024_elwha_mammals_count | camera daily detection counts | count | 255,540 | 34 | 15 | 2 |
| merkes_2016_wabash_carp_edna | eDNA, qPCR replicates | detection | 2,444 | 611 | 2 | 1 |
| glorioso_2020_bigthicket_ves | ARMI visual encounter counts | count | 65,823 | 52 | 37 | 9 |
| glorioso_2020_bigthicket_calls | anuran calling index | ordinal | 24,866 | 52 | 14 | 9 |
| swanson_2018_iowa_amph_occ | occupancy by life stage | detection | 3,024 | 27 | 16 | 2 |
| uherkoch_2019_npra_paloon_ms | multi-state resight histories | state | 200 | 50 | 1 | 4 |
| uherkoch_2019_npra_ybloon_ms | multi-state resight histories | state | 152 | 38 | 1 | 4 |
| rogers_2024_bighunting_sculpin_cjs | CJS, mobile PIT antenna | detection | 4,235 | 385 | 1 | 11 |
| glorioso_2026_bayouteche_pipe_count | PVC-pipe refugia counts | count | 110,700 | 200 | 9 | 62 |
| hanslowe_2022_marianas_rat_occ | chew-card occupancy with manipulations | detection | 6,945 | 1,026 | 1 | 2 |
| gapinski_2025_iowawrp_birds_occ | property-level community occupancy | detection | 70,233 | 55 | 123 | 5 |
| gapinski_2025_iowawrp_focal_count | property-level counts, focal species | count | 9,136 | 55 | 16 | 5 |
| gapinski_2025_iowawrp_point_occ | point-level community occupancy | detection | 157,950 | 494 | 54 | 2 |
| hossack_2020_losttrail_toadmale_rd | robust-design capture histories | detection | 40,864 | 1,232 | 1 | 16 |
| hossack_2020_losttrail_toadfem_rd | robust-design capture histories | detection | 5,233 | 167 | 1 | 16 |

Held (queue/human_review.csv): the two releases with the "authors require" clause; Guam brown treesnake
cameras (detections only, no camera nights); Burmese python ddPCR eDNA (the authors' limit-of-blank call
needs a 6.25 factor applied to "most samples", unspecified); Arkansas and southern Iowa grassland point
counts (standing call on aggregation: duplicate species rows and a whole point-visit entered twice, and
repeated groups across interval x band cells whose sum loses the first-detection interval); the Guam /
Rota live-trap SCR (two unkeyed traps at some stations, no G4 layout; the chew cards from the same
release were built). Not reached and released back to the queue with inspection notes: Mohave ground
squirrel, polar bear, lake sturgeon, giant gartersnake, Duck Creek trout, Palila, Blackrock boreal toads,
Oregon spotted frog, North Dakota / Montana grassland birds, the multi-project amphibian CMR (Russell);
also the Bayou Teche tagged-frog CJS (the pipe counts from that release were built).

Facts carried into the tables: the loon release stored its encounter histories as numbers, so histories
of loons first caught in 2012 and 2013 lost their leading zeros (asserted against the nest-id year and
padded). The Lost Trail male file names its fourth 2015 occasion "2015-3" twice (the metadata calls it
2015-4); data.table read both columns by the first name until renamed, which showed up as four toads
with one capture too many. The Canaan Valley pool file deposits one visit twice, identically. The
murrelet release has two surveys with detections coded N / presence 0 (y follows the authors' codes).
Big Thicket left the greenhouse frog unscored on rounds 3-4 of 2012 at the 20 sites added that year
(__survey_taxa). The Iowa amphibian release says in its completeness report that treefrog and chorus
frog egg masses were searched for and never found; they ship as all-zero target taxa. The Suwannee
moccasinshell is IUCN CR and was coarsened under the bull trout precedent (note added to the open
agency-coordinates question). Bird common names in the Iowa easement release were matched to the
IBP-AOS list (bbsAssistant copy) fetched into the script's cache, not added to data/aux.

What strained the standard: nothing new was needed. Two choices worth a look: the Iowa easement release
deposits three analysis sets of overlapping surveys (property presence, property counts, point
presence), shipped as three tables because none can be rebuilt from another; and the Lost Trail males
and females ship as two tables because the source deposited them as separate analysis sets (ruling
#31's wording), though one table with unit_sex would also fit.

## Batch 42 — 2026-11-06 (GBIF sampling-event rows from batch 40, and non-Dryad discovery)

One agent in `~/eco-b42` (branch `batch-42-gbif`, from main at e3df983). No Dryad requests. The 23 GBIF
sampling-event rows queued by batch 40 were claimed and every Darwin Core Archive was opened from its IPT
endpoint (event core plus extensions); seven tables built, all to eco_2 drafts.

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| inbo_2026_flanders_abv_count | Flemish common breeding birds (ABV), point counts summed per square visit | count | 885,960 | 757 | 180 | 9 |
| haas_2025_sweden_waterbird_count | Swedish midwinter waterbird census, method as occasion | count | 3,466,890 | 3,724 | 70 | 59 |
| inbo_2026_flanders_priobutterfly_count | Meetnetten.be priority butterfly transects (one target per transect) | count | 2,595 | 144 | 9 | 10 |
| inbo_2026_flanders_odonatasite_count | Meetnetten.be priority dragonfly site counts (one target per site) | count | 900 | 65 | 6 | 10 |
| inbo_2026_flanders_crestednewt_count | Meetnetten.be great crested newt fyke counts, fykes as effort | count | 619 | 145 | 1 | 9 |
| nrm_2024_sweden_porpoise_occ | Swedish national C-POD porpoise monitoring, daily detections | detection | 40,677 | 34 | 1 | 9 |
| kuczkowska_2026_warsaw_owl_occ | Warsaw owl playback survey, habitat-based species lists | detection | 3,295 | 431 | 5 | 1 |

Held or rejected (`queue/human_review.csv`): Solhomfjell vegetation (held: the archive has no dates or plot keys),
LifeWatch C-POD network (held: every event row says 'not-for-profit use only' against CC BY 4.0), Astragalus
microcymbus (held: the Dryad study already built, extended on GBIF to 2025), Norwegian alpine cameras (rejected:
duplicate of roderiksen_2023), FSFN carabids (rejected: single visit), both Fukushima ARU datasets (blocked: the
gbif.jp IPT serves a Cloudflare challenge). Inspected and left `needs-look` with notes for a later batch: Meetnetten
butterfly eggs, MEMO and AIMSurv mosquitoes, the Swedish forest inventory (no plot id; plots linkable only through
obfuscated coordinates; 5.9 GB occurrence file), EDP Foz Tua cameras and point counts (2017 point renumbering),
Florida Keys RVC (the IPT resource is the 2009 year only, with derived per-5-minute abundances), Reef Check
California (transect types set the taxa), Sclerocactus demography (a multi-state CJS like the Astragalus tables).

Facts carried into the tables: ABV's point is not a usable unit (598 visits record every point under one
locationID; some squares' points were entered as separate visits), so the unit is the 1 km square and the survey a
square-date, point counts summed with their number as effort; 14 square-dates with 7 to 12 point counts are double
entries and dropped (and with them Netta rufina, recorded only there). The waterbird census year is the source's
season: 45 December counts belong to the next January. The SHARK porpoise archive mixes 178 monthly summary samples
into the daily ones (dropped) and has 10 days on which two loggers overlapped at NMN2 (the earlier logger kept);
350 days at two stations give logger positions 4.5-19 km off the station (probably mistyped longitudes, kept in
obs_ coordinates as published). INBO, SMHI/HaV and the Swedish EPA publish generalised or station coordinates, kept
as published (agency rule); the waterbird table holds six IUCN VU species at 8 km sector centres, a call for Ben.

What strained the standard: summing ABV point counts per square visit is the Pollard-walk rule applied to points,
chosen because point identity is broken in the source; it is a processing choice Ben may want stated as a rule (or
a point-level table built for the 4,375 visits whose points are identifiable).

Discovery (part 2): API searches of Zenodo, Harvard and Borealis Dataverse, figshare, PANGAEA, UK EIDC, TERN, OSF
and NPS IRMA (twelve design queries each, 13 on TERN and OSF; 4,878 distinct hits, 1,307 after keyword screening and
deduplication against the queue, human_review, the discovery log, the dictionary and every `__dataset.json` DOI),
read by title and description; licences checked through each repository's API. 50 rows appended to
`queue/candidates.csv` and `discovery_log.csv` (26 `available`, 24 `needs-look`): Zenodo 28 (16 of them Dryad deposits
mirrored on Zenodo, fetchable without the Dryad quota), figshare 6, EIDC 6 (Open Government Licence), Borealis 5,
Harvard Dataverse 2, TERN 2, NPS IRMA 1; PANGAEA and OSF gave nothing in scope (PANGAEA's hits are
oceanographic and plankton series, OSF's are code and preregistrations). One Borealis hit (Calopteryx exul CMR) was
the Dryad deposit already built as khelifa_2021_seybouse_calexul_cjs and was dropped. EDI and DataONE were skipped
(403).

## Batch 44 — 2026-11-06 (leftover non-Dryad rows: ScienceBase, GBIF needs-look, batch 42 discovery)

One agent in `~/eco-b44` (branch `batch-44-leftovers`, from main at 3316146), in parallel with batch 43 in `~/eco-b43`. No Dryad
requests: four Dryad deposits were read from their Zenodo copies (records whose DOI is the Dryad DOI). 42 rows claimed: the
eleven ScienceBase rows batch 41 inspected, the seven GBIF `needs-look: inspected batch 42` rows that were not blocked, and the
24 `needs-look: not opened` rows from batch 42's discovery. Every ScienceBase release's FGDC `useconst` was read first.
29 tables built from 20 deposits, all to eco_2 drafts.

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| alchokhachy_2024_duckcreek_bnt_cjs | CJS, seasonal electrofishing (brown trout) | detection | 18,640 | 1,200 | 1 | 18 |
| alchokhachy_2024_duckcreek_yct_cjs | CJS, seasonal electrofishing (Yellowstone cutthroat) | detection | 30,244 | 1,761 | 1 | 20 |
| bauwens_2019_belgium_adder_ms | multi-state CJS (breeding state), MARK .inp | state | 16,344 | 908 | 1 | 18 |
| brinck_2022_maunakea_palila_count | point counts, 1-4 visits a year | count | 11,251 | 455 | 1 | 21 |
| buhl_2023_ndmt_grassbirds_count | community counts, PLSS locators coded | count | 235,815 | 1,160 | 28 | 3 |
| buhl_2023_ndmt_grassbirds_exact_count | E7.3 sibling without SPPI, CCLO | count | 215,725 | 1,160 | 26 | 3 |
| chanex_2026_swissalps_amph_count | community counts, four visits | count | 948 | 79 | 3 | 1 |
| dittman_2025_genesee_sturgeon_count | gill-net counts per site visit, coarsened | count | 904 | 23 | 1 | 21 |
| fancourt_2019_aus_catdingo_occ | two-species camera occupancy | detection | 2,580 | 60 | 2 | 1 |
| glorioso_2026_bayouteche_hchr_cjs | CJS, PVC-pipe treefrogs | detection | 51,870 | 853 | 1 | 62 |
| glorioso_2026_bayouteche_hcin_cjs | CJS, PVC-pipe treefrogs | detection | 25,368 | 418 | 1 | 62 |
| glorioso_2026_bayouteche_hsqu_cjs | CJS, PVC-pipe treefrogs | detection | 141,021 | 2,400 | 1 | 62 |
| glorioso_2026_bayouteche_pcru_cjs | CJS, PVC-pipe treefrogs | detection | 2,201 | 36 | 1 | 62 |
| hitchcock_2025_garden_hedgehog_count | weekly camera detection counts | count | 1,446 | 415 | 1 | 1 |
| inbo_2026_flanders_alconegg_count | annual egg counts | count | 178 | 19 | 1 | 10 |
| law_2018_nsw_koala_occ | acoustic single-season occupancy | detection | 1,463 | 171 | 1 | 1 |
| lebeuftaylor_2026_alpac_songbird_dynocc | classifier detections, dynamic community occupancy | detection | 22,788 | 162 | 6 | 8 |
| lenzi_2024_alpine_toad_cjs | annual CJS, 30 seasons | detection | 93,510 | 3,117 | 1 | 30 |
| levy_2025_sclerodawsoniae_ms | multi-state plant census | state | 38,326 | 2,595 | 1 | 17 |
| levy_2025_scleroglaucus_ms | multi-state plant census | state | 13,366 | 896 | 1 | 17 |
| mellado_2021_carollia_injury_ms | multi-state CJS (arm-band injury) | state | 30,197 | 1,183 | 1 | 31 |
| mellado_2021_carollia_tagloss_ms | multi-state CJS (tag carried) | state | 43,148 | 1,598 | 1 | 31 |
| messerman_2020_amb_annulatum_cjs | CJS, enclosure juveniles | detection | 1,320 | 60 | 1 | 22 |
| messerman_2020_amb_maculatum_cjs | CJS, enclosure juveniles | detection | 1,140 | 60 | 1 | 19 |
| messerman_2020_amb_texanum_cjs | CJS, enclosure juveniles | detection | 1,026 | 54 | 1 | 19 |
| muths_2020_blackrock_toad_rd | robust design with Bd status | detection | 220,748 | 3,509 | 1 | 16 |
| poessel_2026_coso_mgs_rd | robust design, days inferred | detection | 167,708 | 1,403 | 1 | 31 |
| rowe_2021_deschutes_ospfrog_rd | robust design, 3 visits per season | detection | 14,460 | 482 | 1 | 10 |
| steinmetz_2025_maewong_tiger_rd | robust design, biennial sessions | detection | 2,376 | 33 | 1 | 6 |

Held (`queue/human_review.csv`, each with a question): polar bear (a third of encounters have type Unknown; telemetry
relocations mixed with captures), giant gartersnake (the "questions on appropriate use ... to the Point of Contact" clause, the
standing call), Russell amphibian CMR (PIT codes rounded by a spreadsheet: four ids absorb 3,827 captures; no site or survey list),
MEMO and AIMSurv mosquitoes (per-protocol taxon lists, trap units; team protocols), EDP Foz Tua cameras (is an event a 12-day
deployment or a 3-day check?) and point counts (2017 key, as batch 42 found), NEON / forest camera traps (possible overlap with
Snapshot USA), coastal giant salamander (batch marks mixed with PIT tags), Central European wolves (variable-length histories,
calendar alignment). Rejected: Sonoran yellow-billed cuckoo (no point id; 2,754 coordinates in 3,126 points), SBL point counts
(annual totals), western India carnivores (key-informant interviews), eDNA metabarcoding vs electrofishing (raw reads only),
Newfoundland boreal birds (single visit), Hillesden transects (annual maxima). Inspected and released with notes, not reached:
Reef Check California, Rhode Island cameras (deployments + 1.4M image records), Savannah River raccoon cameras (records only),
Bedford / Luton / Milton Keynes point counts (86 species by BTO code only), the two TERN plot networks (no download link in the
GeoNetwork record).

Facts carried into the tables: the Bayou Teche frog comments record 225 frogs found dead in a later survey (mostly the February
2021 freeze; history ends at the survey before) and 23 dead at release, and 222 frogs retagged after losing a tag; the lost tag is
rarely named, so its history is not truncated (a strain, below). The Mohave ground squirrel release has no trapping schedule
(trapping days inferred from captures; several sessions a year until 1996). Lake sturgeon is IUCN EN per GBIF: USGS net positions
coarsened under the bull trout / moccasinshell precedent. The Palila release counts one row per bird and an NA row per empty
count; 76 detections filed under survey 9999 (outside the area of inference) are obs_n_outside, not y. The Blackrock toad file
has two columns per date on two days (different sites), a 16-May / 18-May header mismatch between its two matrices (aligned by
position, asserted), 13 toads never seen, 2 not released (removed), and an undefined Bd code T on 130 captures. The Northern
Great Plains release's StopID is a PLSS section; Sprague's pipit (VU) and chestnut-collared longspur (VU) are on the lists, so the
whole table carries sequential codes and the `_exact` sibling keeps the PLSS ids without those two species (and without the
SPPI1 count). Sclerocactus dawsoniae (split 2024) is not in the GBIF backbone (no_key with a remark). The snow-making reservoir
deposit is one 1.1 GB zip; the two raw CSVs were read through HTTP range requests on the zip directory (stdlib Python called
from the script). The alpine toad table follows the authors' own filter (no cohort marks, PIT era from 1993).

What strained the standard: (1) tag loss without the lost tag's identity (Bayou Teche): E4.4 ends a history when the mark is
lost, but the source names the lost tag only as "probably X"; the tables flag the new tag (unit_retagged) and leave the old
histories open; a rule for unidentified lost marks would help. (2) The agency-coordinates question now also covers a locator
that is an id (PLSS section in StopID), handled under E7.4 with an `_exact` sibling. (3) Classifier detections at the authors'
thresholds (Alberta ARUs) are treated like an author's eDNA call; worth stating as a rule.

## Batch 45 — 2026-11-06 (GBIF sampling-event datasets, round 2)

One agent in `~/eco-b45` (branch `batch-45-gbif2`, from main at 7e9a3c3). No Dryad requests. Discovery: the GBIF occurrence
facet `occurrenceStatus = ABSENT` by dataset, split by licence (CC0 1.0: 256 datasets; CC BY 4.0: 2,379), intersected with the
5,326 datasets of type SAMPLING_EVENT: 734, of which 697 not already in eco (deduplicated by GBIF key and DOI against
`queue/candidates.csv`, `queue/human_review.csv`, `discovery_log.csv`, the dictionary, every `__dataset.json` and every
`data/` script). Each was triaged from GBIF metadata (description, sampling text) and occurrence facets (years, event ids,
distinct latitudes); every decision and its reason is in `discovery/gbif_se_absent_b45.csv`: 67 queued (59 queue rows; the
nine Doñana per-taxon track datasets are one row), 332 rejected (single visit per location, one or two locations,
stratified-random stations, one year per dataset, landings, inventories and incidental records, NEON duplicates), 287 not
queued (plankton, microbial and benthic sample series; per-year CREMP and EDIA datasets that need a family merge; other
repeat sampling outside this batch's priorities), 11 held (9 CC BY-NC, PISCO kelp licence terms, the discontinued Swedish
NFI sample). The batch was shrunk mid-run to the cleanest five tables; the other ten claimed rows were released
(`available`, unclaimed).

| Table | Family | Response | Rows | Units | Taxa | Periods |
|---|---|---|---|---|---|---|
| inbo_2026_flanders_batwinter_count | Meetnetten.be hibernation-site bat counts, totals per site | count | 260,337 | 1,380 | 23 | 81 |
| inbo_2026_flanders_firesalamander_count | Meetnetten.be night transect counts, fire salamander | count | 998 | 83 | 1 | 10 |
| haas_2025_sweden_waterbirdsep_count | Swedish September waterbird census, method as occasion | count | 564,528 | 1,645 | 48 | 52 |
| lindstrom_2025_sweden_winterpoints_count | Swedish winter point count routes, survey period as occasion (5 winter parts) | count | 10,376,772 | 2,452 | 262 | 49 |
| carro_2023_donana_tracks_count | Doñana track counts, nine per-taxon datasets joined | count | 3,996 | 12 | 9 | 15 |

Held (`queue/human_review.csv`): PISCO kelp forest surveys (CC BY with a request to discuss analyses with the authors:
request or consult-the-PIs clause?), Meetnetten bat maternity roosts (two protocols, target-species projects with
non-target bats), the discontinued Swedish NFI vegetation sample (as batch 42). Not built and left `available`: Meetnetten
amphibian chorus and larvae counts, Swedish coastal birds, Taiwan New Year Bird Count, Taiwan butterfly census, Budai salt
pans, Doñana lizards, EDP Baixo Sabor acoustic bats, CDFW bull kelp (archives cached in `.cache/raw/` of the worktree).

Facts carried into the tables: the bat winter archive has 12 occurrence rows whose eventIDs are missing from the event core
(dropped) and two species-aggregate classes (Myotis mystacinus/brandtii, Plecotus auritus/austriacus) sharing a
scientificName with a species-level class (keyed on scientificName + identificationQualifier; species-level zeros are not
absences, taxonRemarks). Pipistrellus and Passer are GBIF homonyms (hinted matches). The nine Doñana archives share one
event set but differ cosmetically (date format in one, a tilde in one locality, one empty coordinate); dates come from the
eventID; three fox rows have no event (dropped). The Swedish winter routes carry one count per route per survey period
(asserted); eleven security-class-4 species are withheld by the publisher (taxaWithheld).

Coordinates: Iberian lynx (IUCN VU per GBIF) on the Doñana transects: transect positions coarsened to 0.1 degree. Fire
salamander is IUCN VU (2022) and is kept at INBO's 5 km UTM centroids, and the September waterbird census holds six VU species
at 8 km sector centres: both under the agency-published rule, the open question for Ben from batches 40-44.

What strained the standard: nothing new. The fire-salamander archive marks every row 'casual observation' (absences
included), read as an export constant, not a record type.
