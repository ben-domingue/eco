# The eco data standard, v1.1-draft

*2026-11-01; v1.1-draft 2026-11-03 (see the changelog). Supersedes `standard_draft.md` (v0.1–v0.3.1), which is kept as the
record of how the clauses were arrived at and still holds the per-family mapping
tables and the discussion of alternatives. This file is the normative text: ten
numbered clauses, `E1`–`E10`, which the validator cites, followed by the intake
policy and the metadata contract. Where this file and the draft disagree, this file
governs.*

*The standard is written against the IRW Data Standard v1.0 (clauses C1–C7) and the
data structures of `unmarked`, `AHMbook`, `nimbleEcology`, `spOccupancy` and
`marked`. It was frozen after twelve public deposits across five model families had
been through the pipeline (`BATCH_LOG.md`), and the six textbook datasets had been
round-tripped (`roundtrip_report.md`).*

---

## The one-paragraph version

One CSV per table, long format, one row per **survey observation** of one unit for
one taxon. `unit` is the thing that carries the latent ecological state (a site, or an
individual animal); `taxon` is the species probed for, always, even when there is one;
`y` is the numeric observation. `period` (primary period, across which the state may
change) and `occasion` (replicate survey within a period, across which closure is
assumed) make the key unique; spatial capture–recapture adds `trap`. Covariates are
prefixed by the level at which they are constant: `unit_`, `period_`, `obs_`,
`taxon_`. **A row exists if and only if a survey happened; a missing row is not a
zero.** Taxa, periods, units and traps have side tables; licence, protocol, response
type and the evidence for the survey set are in a `__dataset.json`. `eco_to_irw()`
renames the columns to IRW's `id`/`item`/`resp` and the table validates under IRW v1.0.

---

## E1. Core columns

A core table MUST have `unit`, `taxon` and `y`, in that order, as its first three
columns. It MAY have the optional columns below and no others (E5 governs prefixed
columns).

| Column | Required | Definition |
|---|---|---|
| `unit` | yes | Identifier of the unit carrying the latent state: a site, point, transect, camera station, pond or territory for occupancy, N-mixture and community data; an individual animal for capture–recapture. Unique per unit, not per row. |
| `taxon` | yes | Identifier of the taxon probed for: a short stable code (`CHAFFINCH`, `TAPBAI`, the source's species code), resolved in `__taxa` (E6). Single-species tables have one value. |
| `y` | yes | The observation, numeric, per E2. Never a missing code, never an aggregate across surveys (a total over the sub-units of one survey, as the source defines and publishes it, such as a Breeding Bird Survey run's total over its stops, is that survey's observation). |
| `y_raw` | no | The observation as recorded when `y` is a recode: the uncollapsed count behind a 0/1 `y`, a multinomial cell label, a state letter. |
| `trap` | conditional | Trap identifier in spatial capture–recapture; a key column (E3) with a `__traps` side table. |
| `period` | conditional | Primary period (season, year, session): integer, ordered in time. Required whenever the latent state may change between surveys (dynamic occupancy, capture–recapture, robust design). |
| `occasion` | conditional | Secondary occasion: the replicate survey within a period (visit, trapping night, week, removal pass, distance bin). Integer, ordered in time where time is meaningful. Required whenever a `(unit, taxon, trap, period)` combination has more than one row. |
| `date` | no | Survey date of the row, ISO 8601 (`YYYY-MM-DD`, or `YYYY-MM-DDThh:mm[:ss]Z`). Never a bare year or day-of-year (E8). |
| `observer` | no | Observer identifier for the row. |
| `treat` | no | Experimental manipulation indicator, 1/0, in manipulative field experiments. |
| `cluster_id` | no | A design grouping above `unit`: transect for points on transects, plot for sub-plots, site for samples in multi-scale designs, trapping grid for individuals. |
| `unit_*`, `period_*`, `obs_*`, `taxon_*` | no | Covariates, per E5. |

Column order: `unit, taxon, y, y_raw, trap, period, occasion, date, observer, treat,
cluster_id, unit_*, period_*, obs_*, taxon_*`.

**Ruling (Q1, 2026-11-01).** The species is on `taxon`. Single-species tables have one
`taxon` and many occasions, like IRW's repeated-trial family; community tables are
species-as-items, which is the psychometric payoff of the warehouse. The
visit-as-item view is a derived pivot (`taxon := paste(taxon, period, occasion)`) and
needs no support from the standard.

## E2. Encoding of `y`

`y` MUST be numeric. Its meaning is declared by `responseType` in `__dataset.json`
(E10), which MUST take one of these values:

| `responseType` | `y` | `y_raw` | Notes |
|---|---|---|---|
| `detection` | 0 or 1 | the count, if `y` was collapsed from one | Detection / non-detection, capture histories. Rows before an individual's first capture follow E4 consequence 4. |
| `count` | integer ≥ 0 | — | Repeated counts (N-mixture), removal counts, trap counts. |
| `state` | integer state code, 0 = not detected | the source's label | Multi-state occupancy or capture–recapture: breeding status, disease state, false-positive certainty. `stateCodes` required in metadata. |
| `ordinal` | integer index, 0 = none | the source's label | An ordered index that is neither a count nor a latent state: an anuran calling index 0–3, an abundance class. `stateCodes` required. *Added v1.0 after `glorioso_2025_atchafalaya_calls`.* |
| `multinomial_cell` | count in the cell | the cell label (`"10"`, `"01"`, `"11"`; a removal interval; a distance bin) | `occasion` indexes the cell (E9). `multinomialType` or `distanceBreaks` required. |
| `detection_event` | 1 | — | One row per detection with `obs_*` (distance, classifier score) plus one `y = 0` row per survey with no detections. Experimental (E9). |
| `binomial_count` | number of occasions with a detection, integer 0 to `obs_trials` | — | The source collapsed the occasions: only the count of occasions with a detection and the number surveyed (`obs_trials`, required on every row, integer ≥ 1) are deposited. No `occasion` column; a row is one `(unit, taxon [, trap] [, period])`. Supports constant-`p` models only; a time-varying detection model needs the history, which does not exist. `effortColumn = "obs_trials"`. *Added by ruling #34 (2026-11-01).* |

**Partial identity.** Where some individuals are identified from one side only (one
flank in camera traps, one side of the dorsal fin in photo-ID), so that a left-only and
a right-only record may be the same animal, every unit carries `unit_identity` with one
of `both`, `left`, `right`: the sides from which the individual's identity is known.
`y` stays the detection or state of E2; a design that codes which side was seen on each
encounter (multimark's 0 to 4) is `responseType = state` with those codes in
`stateCodes`.

Counts that were imputed or interpolated MUST be removed. A quantity the source
authors *estimated* from the same observations (a model-based occupancy estimate, a
predicted density) is a model output, not a covariate or a `y`, and MUST NOT be
shipped; the omission is recorded in `notShipped`.

## E3. Uniqueness

The key is `(unit, taxon, trap, period, occasion)`, with absent columns treated as a
single level. A duplicate key is a defect. Two observers' results for one visit are two
`occasion`s with `observer` giving the identity, never duplicate rows.

## E4. The explicit-zero rule

**A row exists if and only if a survey was conducted for that key. A `y` of 0 means
surveyed and not detected. A missing row means not surveyed. No row carries an empty
`y`.**

Consequences:

1. Unbalanced designs are encoded by row count, not by `NA` padding; the converter
   back to the native matrix pads with `NA`.
2. A multi-species table MUST carry a row for every taxon surveyed for at every
   conducted survey, so "surveyed, not detected" is distinguishable from "not
   surveyed". By default every taxon is surveyed for at every survey, and the validator
   checks that every survey has the same set of taxon rows. Where the source states
   that the taxa surveyed for differ between surveys (different species lists by
   region, taxa countable only on some runs), the table carries a `__survey_taxa` side
   table (E6) listing them, and the validator checks each survey's taxon rows against
   it. Which taxa are on the list at all is `taxonInclusion` (E10).
3. A unit never surveyed has no rows; if the sampling frame matters it belongs in
   `__units`.
4. Capture–recapture: a session at which an individual was not at risk has no row.
   Not at risk means removed (a loss on capture is `obs_removed = 1` on the last
   row), outside the trapped area, not yet born or hatched (an individual marked as a
   newborn, chick or seedling has no rows before the period in which it was marked,
whatever release convention the authors' analysis used), or no longer
   identifiable (a lost tag or flag ends the history: no rows after the last period at
   which the mark was known to be present). An individual of unknown age caught in
   the wild was at risk from the first period of the study, so its rows begin there.
   Within the span at risk, a session in which the individual was not caught is a row
   with `y = 0`, including whole primary periods with no capture; converters that
   build per-session histories for a closed model (`eco_to_ch()`) drop all-zero
   unit × period blocks unless asked to keep them (ruling #30). An individual with no
   detection anywhere in the table (a catalogue entry never sighted) is not a unit
   and has no rows.

**Ruling (#20, 2026-11-01).** Consequence 2 applies to `unitKind = site`. When the
unit is an individual (`cjs`, `scr`, closed captures) the taxon is a property of the
unit, so an individual's surveys can carry only its own taxon's rows. A deposit with
several species of individuals ships as one table per taxon (E9: one table per
survey design × response type); a multi-taxon table with `unitKind = individual` is
rejected.

**Ruling (#31, 2026-11-03).** The site-unit surveys of one deposit under one protocol ×
response type are one table: differences in which taxa were surveyed for, between
regions, units or runs, are carried by `__survey_taxa`, not by splitting the table.
Two methods (pitfall and emergence tent, aerial net and dipnet, eDNA and visual
survey) are two protocols when each has its own survey set; when both methods are
applied to the same unit at the same visit (a paired design), the deposit is one table
with `obs_method`, under the multi-method form of E9 (*Experimental*). The ruling is about
taxon lists only, so it does not touch
`unitKind = individual` tables, which split by taxon (ruling #20) and stay separate
where the source deposited separate analysis sets or populations.

**Ruling (Q3, 2026-11-01).** Dense explicit zeros are the only canonical form. A sparse
detections-only table is not accepted as a core table. Across twelve deposits the
rule was never ambiguous once the survey set was fixed; its cost is size (a 267 × 3 ×
158 array becomes 118k rows, 95% zeros), which is trivial at the scale seen. A table
that would exceed about five million rows MAY be stored as period parts: the
directory `output/<table>.parts/` holds `part-01.csv`, `part-02.csv`, ..., each with
the same columns and whole periods (no period in two parts), and the table keeps one
`__dataset.json` (whose `parts` lists each file, its periods and its row count) and
one set of side tables beside the directory. It is one table: every clause applies to
the union of the parts, and on Redivis the parts are one table.

**The survey set is evidence, not assumption (Q7).** Because the rows *are* the
record of which surveys happened, the standard requires each table to say what that
record rests on. `surveyEvidence` in `__dataset.json` (E10) MUST be one of:

| `surveyEvidence` | Meaning |
|---|---|
| `sample_table` | The source deposited a list of conducted surveys (a samples or events table). |
| `effort_table` | The source deposited effort per unit × occasion, and a survey exists where effort > 0. |
| `deposited_matrix` | The source deposited a unit × occasion matrix in which not-surveyed (`NA`, blank) and not-detected (0) are distinct. |
| `row_presence` | The source is a record table and a survey exists where it has at least one row, including explicit zero-count rows. |
| `inferred` | The survey set was reconstructed by a rule the script states in `surveyEvidenceNote` (for example, first-to-last detection span per camera-year). |

`inferred` is a warning in the validator and a filterable fact for users. A
`__surveys` side table is NOT required: the core table already lists every survey as
`distinct(unit, trap, period, occasion)`. Where the source's own record of surveys
disagrees with its detections (deployment dates that contradict detection dates),
the script MUST say which was believed and why.

## E5. Covariates and their levels

A covariate column MUST carry the prefix of the level at which it is constant, and
the validator checks the constancy:

| Prefix | Constant within | `unmarked` analogue | Examples |
|---|---|---|---|
| `unit_` | `unit` | `siteCovs` | elevation, forest cover, coordinates, sex, stratum, treatment arm |
| `period_` | `unit` × `period` | `yearlySiteCovs` | habitat in year t, age class at session t |
| `obs_` | nothing (varies by row) | `obsCovs` | wind, temperature, duration, effort, time of day, trap-dependence, removal flag |
| `taxon_` | `taxon` | — | body mass, guild, IUCN category; prefer the `__taxa` table and copy into the core only when convenient |

An `obs_` column that happens to be constant within a unit is not a defect. An `obs_`
column MAY vary across taxa within one survey (a per-species index recorded at the
survey, such as the calling index outside the plot); that is allowed by the
definition and should be noted in the column's description. IRW's `cov_`,
`itemcov_` and `periodcov_` MUST NOT appear; `eco_to_irw()` produces them. A prefix
appears once: `unit_unit_sex` or `obs_obs_effort` is a processing error.

**Ruling (Q4, 2026-11-01).** Observation covariates live in the core file, repeated
across taxa in community tables. The three-level split is exactly the one `unmarked`,
`spOccupancy` and the AHM code take as separate inputs, and one file that is complete
for modelling is the IRW's position too.

## E6. Side tables

Side tables share the core table's name plus a suffix, and are typed by their key
column, not by the suffix.

| Table | Key | Required | Columns |
|---|---|---|---|
| `__taxa` | `taxon` | yes | `scientificName`, `taxonRank`, `taxonID` (a GBIF species URL or ITIS TSN), `vernacularName` (Darwin Core), `taxon_*` traits, `taxon_iucnCategory` where known. Every `taxon` in the core table MUST appear; every row MUST appear in the core table. |
| `__periods` | `period` | when `period` exists | Calendar bounds and any covariate constant across all units within a period (session effort, year-level climate). |
| `__units` | `unit` | no | The sampling frame: `unit_*`, coordinates, including units never surveyed. |
| `__traps` | `trap` | when `trap` exists | Trap coordinates, `crs`, usage. |
| `__survey_taxa` | `taxon` plus one or more of `unit`, `trap`, `period`, `occasion` | when the taxa surveyed for differ between surveys (E4.2) | One row per taxon surveyed for at the surveys matching the other columns; a survey matched by no row has no taxa surveyed for, which is a defect. |

A taxon is a species, or the lowest unit the source identified (a genus, a species
aggregate the source records as one, such as *Bombus lucorum/terrestris*, with
`taxonRank` and `taxonRemarks` saying so). It is never a composite of a taxon and
something else (a sex, a method, a site), with one exception: where the source records
life stages separately within one survey (adults and larvae counted on the same visit),
`taxon` is the species × stage (`AESCYA_L`) and `__taxa` carries `lifeStage` (Darwin
Core). Records the source identified only to a higher rank are their own taxon, at that
`taxonRank`. Where the source says two taxa were not reliably separated, both are
shipped as recorded and `__taxa` says so in `taxonRemarks`. `taxonID` MAY be empty only
for a group the GBIF backbone does not hold (a pooled group, a subfamily absent from the
backbone), and `taxonRemarks` then says so.

## E7. Spatial information

Coordinates go in `unit_decimalLatitude` / `unit_decimalLongitude` (WGS84) with
`unit_coordinateUncertaintyInMeters`; a projected pair `unit_x` / `unit_y` is allowed
when `crs` in `__dataset.json` names the EPSG code. Converters do not reproject.

**Ruling (Q5, 2026-11-01).** Never publish finer than the source did. A taxon is
*flagged* when (a) the source says so, (b) its IUCN category is CR, EN or VU, which is
checkable from the GBIF key the pipeline resolves, or (c) a national red list the
source cites lists it. For a flagged taxon with coordinates finer than 0.1°, generalise
to the 0.1° grid-cell centre, set `unit_coordinateUncertaintyInMeters` to the cell
half-diagonal, set `coordinatesCoarsened` with the method, and say so in the tags.
Coordinates are coarsened, not dropped: spatial occupancy and SCR need them, and a
10 km cell is what GBIF publishes for sensitive taxa. Coordinates a government
agency released for a flagged taxon on public land are kept as published; the agency
is the authority on what it publishes. Trap coordinates follow the same rule.

**Ruling (non-native taxa, 2026-11-02).** (b) applies only where the survey is within
the taxon's native range. The IUCN category protects wild populations; an introduced
population (a garden escape, an invasive) is not flagged by its global category, so
its coordinates are kept as the source published them. (a) and (c) still apply, and
`coordinatesCoarsened` says why a listed taxon was not coarsened.

**Ruling (E7 scope, 2026-11-03).**

1. *Projected coordinates.* Coarsening a projected pair snaps it to the centre of the
   10 km cell of the source's grid (`floor(x / 10000) * 10000 + 5000`), with
   uncertainty 7,071 m.
2. *Trap arrays.* Coarsening the traps of an SCR array would destroy the distances the
   model needs, so for a flagged taxon the trap coordinates are centred on the array
   (the mean trap position subtracted, local metres), the array's own location is
   given as a 0.1° cell in `geographicCoverage`, and `crs` says `local`.
3. *Multi-taxon tables.* When some but not all taxa of a site-unit table are flagged,
   two tables ship: the whole table, coarsened, under the table's name; and the table
   without the flagged taxa, at the source's precision, under the same name with
   `_exact` before the type suffix (`stallings_2025_gulfreefs_exact_count`); if that
   exceeds 40 characters, the longest segment between the year and the type suffix
   is cut from its end until it fits. The user chooses; nothing is lost that the source
   published.
4. *Other locators.* In a coarsened table, elevation columns are rounded to the nearest
   100 m, and columns that name a place (locality, site name) are not shipped
   (`notShipped`). A `unit` or `cluster_id` value that names a place is replaced by the
   source's code or a sequential id. The `_exact` sibling keeps them as published.
5. *Displaced coordinates.* Coordinates the source deliberately displaced for privacy
   are shipped as published, and `coordinatesCoarsened.method` says how they were
   displaced.

## E8. Time

`period` and `occasion` are integers ordered in time (an `occasion` that indexes a
category rather than a time is E9's stretch). `date` is ISO 8601 per row where known;
when only a day-of-year exists it goes in `obs_date_doy` and `date` is left empty, not
fabricated. A calendar year is a property of a `period` and belongs in `__periods`.
Closure is assumed across `occasion` within a `period`. Robust design is both
columns present.

**Ruling (closure and occasions, 2026-11-03).** `closure` in `__dataset.json` MUST be
one of:

| `closure` | Meaning |
|---|---|
| `closed` | The state is assumed constant across the occasions of a period, and the source gives no reason to doubt it. |
| `open` | The occasions of a period span a time over which the state may change (year-round trapping, a season of weekly walks across emergence), as the source states or its dates show. |
| `dependent` | The occasions are simultaneous or not independent (side-by-side divers, observers who share information), as the source states. |
| `none` | There is one occasion per period, or no `occasion` column. |

Anything further goes in `closureNote`. `occasionKind` MUST be one of:

| `occasionKind` | The occasion indexes |
|---|---|
| `time` | repeat surveys ordered in time (visits, nights, weeks, passes) |
| `observer` | independent observers or surveyors at one survey |
| `method` | methods or sample types applied at one survey (DNA sources, gear types) |
| `spatial` | spatial replicates within the unit at one time (transects, quadrats, samples, PCR replicates) |
| `cell` | the cells of a multinomial design (removal intervals, distance bins, observer cells; E9) |
| `none` | there is no `occasion` column |

`occasion` is ordered in time when `occasionKind = time`; for the others its order is
the source's. When each occasion is a crossing of two kinds (a method × a replicate,
a visit × a method), `occasionKind` is the list of both, outer first
(`["method", "spatial"]`), and the components are recoverable from `obs_` columns.

## E9. Scope

**Ruling (Q6, 2026-11-01).** Three lists. The test for the second is that the
likelihood can still be written from the key and `y` plus one metadata field, and a
converter back to the native frame exists.

**Ruling (plants, 2026-11-02).** Plants are in scope. The lists below are about
designs, not taxa: repeat-visit plant surveys are occupancy, and histories of marked
plants (including dormancy) are capture-recapture, under the same clauses as animals.

**Ruling (#34, 2026-11-01).** Occasions collapsed by the source to "detected on `y` of
`obs_trials` occasions" are `responseType = binomial_count` (E2), not `count` with an
effort column and not a reason to hold. The likelihood is Binomial(`y` | p, `obs_trials`);
the converter expands each row to an exchangeable history (`y` ones, then zeros) for
`unmarked`. The four deposits that raised it (Nagarahole tigers, NE China and Botswana
camera communities, Jhala tiger cells) move together under this type.

**Ruling (#22, #23, 2026-11-01).** A fourth nesting level is a `unit_<group>` covariate,
not a second grouping column or a reuse of `period`. Confirmation surveys by a second
method take one of the two forms stated under *Experimental* and are declared in
`detectionCertainty`.

**Core, unforced semantics:** single-season occupancy (incl. Royle–Nichols),
dynamic occupancy, N-mixture (incl. open), community occupancy and abundance (incl.
dynamic and with interactions), multi-state occupancy (incl. false positives),
ordinal indices, CJS / Jolly–Seber / Pradel, closed-population capture–recapture,
robust design, multi-state and dead-recovery capture–recapture, repeated-count
indices with within-route replication, occasions collapsed to a binomial count
(`binomial_count`, ruling #34).

**Declared stretch, `responseType = multinomial_cell`:** removal and time-removal
sampling (`multinomialType = removal`), double-observer and dependent
double-observer (`multinomialType = double_observer | dep_double_observer`),
binned and hierarchical distance sampling (`distanceBreaks`), camera-trap distance
sampling (`distanceBreaks` and `snapshotInterval`). `occasion` indexes the cell.

**Experimental:** spatial capture–recapture (`trap`, `__traps`), multi-scale
occupancy and eDNA (`cluster_id` = site, `unit` = sample, `occasion` = replicate;
a fourth level above `cluster_id`, such as the watershed of an eDNA site, is a
`unit_<group>` covariate, constant within the unit as E5 requires, so the deposit stays
one table), false-positive designs with a confirmation survey by a second method
(`detectionCertainty` in `__dataset.json` names the certain method and where it sits:
a `unit_` covariate when the certain method is at a coarser level than the rows, or an
`obs_method` value when both methods share a level and each survey has one row set per
method; `y_raw` keeps the method's own code),
per-detection rows with scores (`detection_event`). A table in this list is tagged
`experimental` and may be restructured between versions.

**Out of scope:** presence-only occurrence records, telemetry and movement,
used–available resource selection, aggregated indices without unit-level data, model
outputs. A deposit that fits none of the three lists is logged against the matching
row of `design_landscape.md` table C and held; three deposits on one row open a
family issue.

## E10. Metadata and storage

Every core table has a `__dataset.json`. Required fields: `title`, `creator`,
`pubDate`, `citation`, `sourceURL`, `intellectualRights` (`spdx`, `url`),
`samplingProtocol`, `samplingProtocolCode`, `responseType` (E2), `unitKind` (`site` |
`individual`), `closure`, `surveyEvidence` (E4), `temporalCoverage`,
`geographicCoverage`, `occasionKind` (E8), `taxonInclusion`. Conditional: `stateCodes` (for `state` and `ordinal`),
`multinomialType` or `distanceBreaks` (for `multinomial_cell`), `effortColumn =
"obs_trials"` (for `binomial_count`),
`coordinatesCoarsened` (when coordinates exist; `null`, or an object
`{"value": true|false, "method": "..."}` saying how or why not, E7), `surveyEvidenceNote` (when
`surveyEvidence = inferred`), `taxaWithheld` (taxa the source surveyed for but did not
publish, such as security-class species in a national scheme: a list of names, with no
core rows and no zeros), `crs`, `effortColumn`, `detectionCertainty` (when a
second, certain detection method is carried; E9). Recommended: `abstract`,
`notShipped` (what was in the source and not shipped, with the reason). The
pipeline adds `summary`, `sampleFloor`, `columns`, `standardVersion`, `script`,
`buildDate`, and in the metadata table `components`: the other core tables built from
the same deposit.

`closure` and `occasionKind` take the values in E8. `taxonInclusion` says which taxa are
in the table:

| `taxonInclusion` | The taxa are |
|---|---|
| `recorded` | every taxon of the target group recorded at least once in this table's own surveys (a complete-community protocol; a taxon never recorded is not listed, because the set of possible taxa is open, and one recorded only by another method or outside the counting rule is not recorded here) |
| `target` | the taxa the protocol names as searched for, all of them, including any never detected |
| `single` | the one taxon of a single-species table |

A cut the processor made beyond that (taxa below a record threshold) is stated in
`notShipped`. Records identified only to a higher rank are not cut: they are their own
taxa (E6).

**Ruling (Q8, 2026-11-01).** One Redivis dataset, `datapages.eco`, holds every core
table and its side tables, next to each other. A table's kind is defined by its key
column, not by where it lives. Per-table metadata travels as the Redivis table
description, generated from `__dataset.json`. The pipeline's own tables (metadata,
biblio, tags, collections) go in a second dataset, `eco_meta`, so a `LIKE` query over
`eco` sees only data. Sharding is not a concern at the expected scale.

---

## Intake policy

These rules govern what enters the corpus; they are not part of the format and
`eco-validate` reports them under a separate intake profile.

**Licence.** Verify on the source page before writing a script. CC0, CC BY, CC BY-SA,
public domain: proceed. CC BY-NC, ODbL, GPL and other licences with a propagating
clause: proceed, and `derived_license` carries the clause so a reuser can exclude the
table. No licence, an unresolvable licence UUID, or "contact the author": stop and ask
by email (IRW's template, `processing_notes/Licensing.txt` in `ben-domingue/irw`);
process only once permission is written. ND: stop; reshaping is a derivative.
**Conflicts (ruled 2026-11-01):** when the repository's metadata and the deposited
files disagree (Dryad says CC0, the readme says ODbL), the stricter licence governs
and propagates, because the originator's terms govern over a repository default;
record both in the dictionary row. Scraped or re-uploaded third-party data: do not
host under any licence.

**Sample floor (ruled 2026-11-01, #1).** `sample_floor` is a reported, filterable
attribute, not an admission rule: `meets` at ≥ 30 units and ≥ 2 occasions (or ≥ 2
periods for capture–recapture), otherwise `below (reason)`. Small tables ship when
they come and are not prioritised; for community tables the per-unit count
understates the information, which is one reason the floor is a filter.

**Replication.** A table with `n_occasions = 1` and `n_periods = 1` (a single-visit
community matrix) fits the format but supports none of the models in E9's core list.
It is admitted with that fact filterable; the pipeline does not seek such tables out.

**Naming.** `author_year_taxonOrPlace_type`, lower case, ≤ 40 characters; type
suffixes `occ`, `count` / `nmix`, `cjs`, `dynocc`, `comm`, `removal`, `dobs`, `ds`, `scr`,
`state`, `calls` and the like. One table per survey protocol × response type (E4,
ruling #31); the precise sibling of a coarsened table puts `_exact` before the type
suffix (E7).

**Duplicates.** Search the dictionary by DOI before processing; a deposit mirrored on
two repositories is one table.

**Processing record.** The `data/` script is the record: its header states the source,
licence, files as deposited, the mapping, the survey-evidence rule, and what was not
shipped and why. Facts about the source are assertions, not comments.

---

## Changelog

- **v1.0-draft (2026-11-01).** First frozen version: ten numbered clauses. Rulings on
  all open questions of the v0.3 draft, in the clauses marked *Ruling*. New since
  v0.3.1: `surveyEvidence` required (E4), `ordinal` added to `responseType` (E2), the
  licence-conflict rule and the replication note (intake), `obs_` may vary across taxa
  within a survey (E5), the IUCN trigger for coarsening (E7), the three-list scope with
  `experimental` (E9), `eco_meta` as the second dataset (E10).
- **v1.0-draft, ruling #34 (2026-11-01).** `binomial_count` added to `responseType`
  (E2): occasions collapsed by the source to a count out of `obs_trials`; no `occasion`
  column; core semantics in E9.
- **v1.0-draft, ruling #20 (2026-11-01).** E4.2 applies to site units; individual-unit
  deposits with several species ship as one table per taxon.
- **v1.1-draft (2026-11-03).** Rulings drawn from batches 4 to 20 (`BATCH_LOG.md`),
  under the rule that a clause must be clear, need no judgement, and lose information
  only where protection requires it. `closure` and `occasionKind` enumerated (E8);
  `taxonInclusion` and `taxaWithheld` (E10); `__survey_taxa` and one table per deposit
  × protocol × response type (E4.2, E6, ruling #31); individuals at risk, lost marks,
  never-detected catalogue entries and all-zero sessions (E4.4, ruling #30); partial
  identity (E2); life stage, higher-rank records and empty `taxonID` (E6); E7 for
  projected coordinates, trap arrays, multi-taxon tables (the `_exact` sibling), other
  locators and displaced coordinates; `components` in the metadata table (E10). Every
  table was rebuilt under v1.1-draft.
- **v1.1-draft, ruling #31 clarified (2026-11-04).** Two methods are two protocols
  only when each has its own survey set; a paired design (both methods on the same unit
  at the same visit) is one table with `obs_method` (E9), as the published
  `dougherty_2016_rustycrayfish_edna` and `lafferty_2024_tidewatergoby_edna` already are.
- **v1.1-draft, E1 and E4 (2026-11-04, Breeding Bird Survey, #24).** E1: `y` is never an
  aggregate *across surveys*; a run total over the stops of one survey, as the source
  publishes it, is that survey's observation. E4: the split of a table over about five
  million rows is stated as period parts, `output/<table>.parts/part-NN.csv` with one
  `__dataset.json` and one set of side tables, one table on Redivis.
- **v0.3.1 (2026-11-01)** and earlier: see `standard_draft.md`.
