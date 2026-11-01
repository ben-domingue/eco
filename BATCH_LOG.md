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

