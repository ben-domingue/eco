# Converting an ecological deposit: the agent processing guide

What to produce when turning a public deposit into an eco table, and the judgement
calls along the way. The format itself is the numbered clauses of
[`standard.md`](standard.md) (v1.1-draft); `eco-validate` reports each finding
against them, and this guide does not restate the clauses. It adds the intake
checklist and the working practice. Where the two disagree, the standard governs;
raise the disagreement rather than following either silently. The step order and
the hard rules are in `.claude/skills/eco-convert-deposit/SKILL.md`; read that too.

## Before you start

**Licence, verified on the source page**, not inferred from the repository's
default. Intake policy in `standard.md`:

- CC0, CC BY, CC BY-SA, public domain (USGS, government agencies): proceed.
- CC BY-NC, ODbL, GPL (data shipped in R packages) and other propagating clauses:
  proceed; `derived_license` carries the clause so a reuser can exclude the table.
- **What eco redistributes under.** eco does not relicense: each table is
  redistributed under its source's licence, so `derived_license` in `biblio.csv` is
  that licence's SPDX id (stage 02 sets it from `__dataset.json`'s
  `intellectualRights.spdx`). CC0 stays CC0; CC BY stays CC BY, with the attribution
  the citation carries; NC, SA and ODbL clauses pass through to anyone who reuses the
  table. The source's own wording, conflicts included, stays in `original_license`.
- No licence, an unresolvable licence UUID, "contact the author": **stop**. Record
  the candidate in `queue/human_review.csv` as `held`, set the queue row to
  `held: no licence`, and move on. Ben emails; process only once permission is
  written.
- ND: **stop**. Reshaping is a derivative.
- Repository and deposited readme disagree (Dryad says CC0, the readme says ODbL):
  the stricter licence governs and propagates; record both in `original_license`.
- Scraped or re-uploaded third-party data: do not host under any licence.

Assert the licence in the script where the download helper exposes it
(`download_dryad()` returns it as an attribute), so a relicensed deposit fails the
rebuild.

**The paper.** When a deposit cannot be read without its paper (column meanings,
the survey design, which file is which) and the paper is paywalled, set the queue
row to `blocked: paper` with the DOI and move on. Ben drops the PDF into
`queue/papers/`; a file there whose name matches the author and year unblocks the
row. Cite what the paper supplied in the script header.

**Duplicates.** Search `dictionary/dictionary_auto.csv` by DOI (paper and data) and
by author-year. A deposit mirrored on Dryad and Zenodo is one table. The same
survey published as two files with different response types (counts and a calling
index from the same visits) is two tables, named for the type.

**Can the explicit zeros be recovered?** This is the question that decides whether
a deposit is buildable (E4). You need to know which surveys happened:

| The deposit has | `surveyEvidence` | What to do |
|---|---|---|
| a list of conducted surveys or sampling events | `sample_table` | a survey is a row of that table |
| effort per unit x occasion (camera nights, trap nights, minutes) | `effort_table` | a survey exists where effort > 0 |
| a unit x occasion matrix where NA and 0 are distinct | `deposited_matrix` | NA cells become missing rows; assert the NA pattern is the same across species |
| a record table with explicit zero-count rows, or one row per visit | `row_presence` | a survey exists where the table has at least one row for it |
| a site x species matrix of "occasions with a detection" plus the number of occasions surveyed (camera nights, 14-day windows, trap days), no occasion-level history | `deposited_matrix` or `effort_table` | `responseType = binomial_count` (ruling #34): one row per unit x taxon, `obs_trials` = occasions surveyed, no `occasion` column; never invent occasion rows |
| only detections, with dates | `inferred` | reconstruct the survey set by a rule you state in `surveyEvidenceNote` (first-to-last detection span per camera-year, for instance); the validator warns and users can filter it out |

A detections-only table with no dates and no deployment record cannot be built as
a core table. Hold it and say why.

**Taxa resolve on GBIF.** `make_taxa()` matches each scientific name against the
GBIF backbone (cached in `.cache/gbif/`). A code the deposit never expands, a
"spp." group, or a functional group is allowed at the rank the source gives
(`taxonRank = "genus"`, `"order"`, `"species complex"`, `"functional group"`), with
`taxonID` at that rank or NA; say so in `notes`. Keep the source's spelling in
`scientificName` and pass a corrected spelling as `lookupName` when GBIF needs it.

**Coordinates and sensitivity.** Decide before writing: does the deposit carry
coordinates, and is any taxon flagged (the source says so, IUCN CR/EN/VU within its
native range, a cited national red list)? If both, coarsen with `coarsen_coords()` to the 0.1 degree cell
and set `coordinatesCoarsened`. Agency-published coordinates on public land are
kept as published. Never publish finer than the source did. If there are no
coordinates, `coordinatesCoarsened = NA` still has to be present in the metadata
when any coordinate column exists; otherwise leave it out. When set, it is
`list(value = TRUE/FALSE, method = "...")`, never a bare string or logical: the
validator and `metadata/01_metadata.R` read `$value`.

**Sample floor and replication** are reported, not gates: `write_table()` computes
`sampleFloor` (30 units and 2 occasions or periods). A single-visit community matrix
is admitted and filterable; do not seek such tables out.

**Name**: `author_year_taxonOrPlace_type`, lower case, 40 characters or fewer; type
suffixes `occ`, `count` / `nmix`, `cjs`, `dynocc`, `comm`, `removal`, `dobs`, `ds`,
`scr`, `state`, `calls`. The name is the script name and the table name.

**Is it in scope?** Check `standard.md` E9 and the table in `design_landscape.md`.
Core: single-season and dynamic occupancy, N-mixture, community occupancy and
abundance, multi-state, ordinal indices, CJS / Jolly-Seber, closed captures, robust
design. Declared stretch: removal and double-observer (`multinomial_cell`),
distance sampling, SCR. A design not on either list needs a ruling: open an issue,
hold the deposit.

## Reading the deposit

Download into `.cache/raw/<table>/` with `download_cached()` or `download_dryad()`
(the Dryad version zip is the only anonymous route; per-file downloads need a
token; a few Dryad deposits also have a Zenodo copy, most do not). EDI's portal and PASTA refuse
scripted requests; use DataONE or hold. The intake is anonymous: a deposit whose anonymous
download fails (404, 405) is `blocked`, not fetched with a token or by hand (ruling
2026-11-06). Read every file the deposit ships, not only
the obvious one: the covariate files often reveal which cells were surveyed, and
the readme often carries the licence and the species code list.

Turn what you learn into assertions: the number of sites, that site ids agree
across files, the set of values `y` takes, that the NA pattern is identical across
species, that effort is positive exactly where a detection row exists. The
assertions are the processing record's facts; prose in the header is the
explanation.

## Building the table

Prefer the converters in `Rpkg/R/convert.R` (sourced through `converters/eco_standard.R`;
the same code the `eco` R package ships) over hand-rolled reshapes:
`array_to_eco()` for site x occasion (x species) arrays with site, observation,
period and taxon covariates; the `unmarked` frame converters; `ch_to_eco()` for
capture histories. They produce the right column order and the explicit-zero rows.

**Dependencies.** `data.table` and `jsonlite` through `lib/eco_common.R`; `readxl`
is accepted for `.xlsx` deposits (`galvez_2021_araucania_comm` uses it). Anything
else (a format reader, a package that ships the data) is a question for the batch
log before it goes in a script.

**Row layout by family.** Site tables: one row per taxon per survey (E4). Capture
histories (`cjs`): one row per individual per surveyed `period` while it was at risk
(E4.4): from the study's first period for an animal caught in the wild, from the
marking period for one marked at birth or hatching, and to the end of the study unless
it was removed or its mark was lost. This is the full rectangle MARK history strings
give; a deposit that starts each history at first capture is padded back to the
study's first period. Spatial capture-recapture
(`scr`): a row per individual x `trap` x `period` x `occasion` for every trap-night
the trap was operated, since an operating trap surveys every individual in the
population; trap usage comes from the deposit (`__traps` usage) or, if it is not
deposited, from a stated rule declared in `surveyEvidence`. Sessions with no
capture of an individual keep their rows (ruling #30); `eco_to_ch()` drops all-zero
unit x period blocks by default for closed-model users, and the table does not
pre-filter for them. The IRW view folds
`trap` into `item` as `taxon:trap`.

Covariates go at the level where they are constant (E5): `unit_` (elevation,
habitat, coordinates, an individual's sex), `period_` (habitat in year t),
`obs_` (wind, effort, duration, date offset, trap dependence; may vary across taxa
within one survey), `taxon_` (traits; prefer `__taxa`). Period-level facts (calendar
year, season label) go in `__periods`, not the core.

**What is not a covariate.** Anything the authors estimated from the same
detections: an occupancy or detection estimate, a predicted density, a model-based
"dog activity" index. Drop it, and record the drop in `notShipped`. Standardised
versions of a covariate are shipped as the source gives them, with the fact noted.

**What is not `y`.** Imputed or interpolated counts (remove), aggregates across
surveys (the per-survey values are `y`), and model estimates.

`date` is ISO 8601 or absent. A day-of-year goes in `obs_date_doy`; a year is a
`__periods` fact; a date reconstructed exactly from a deposited offset is a date.

Capture histories: `unit` is the animal, `period` the session, `y` 0/1, a session at
which the animal was not at risk has no row, loss on capture is `obs_removed = 1`
on the last row. Removal and double-observer designs put the cell on `occasion`
and declare `multinomialType`.

Community tables carry a row for every taxon surveyed for at every conducted survey.
When the source says the taxa surveyed for differ between regions, units or runs,
the table stays whole and `__survey_taxa` lists them (E4.2, E6, ruling #31); never
invent zeros for taxa that were not surveyed for, and never split one protocol's
table to avoid them. Two methods are two tables.

**Rules learned in batches 17 to 20.** Each is a fact to assert, not a judgement:

- A table over about five million rows is written with `write_table_parts()` (period parts in
  `output/<table>.parts/`, standard E4), not split into sibling tables by region or taxon; its
  core is gitignored and `red_up_eco.py` uploads the parts as one table.
- A code the source does not define gets no row; count it in `notShipped`.
- A lost mark (tag, flag) ends the history after the last period it was known present.
- A catalogue entry never detected in the deposit is not a unit; drop all-zero histories.
- A deposited history cell that is the authors' simulated release, not an encounter,
  is kept and flagged `obs_release = 1`.
- A second file is a recode of the first only if the script rebuilds it exactly from
  the first and asserts so; then it ships once. Otherwise it is its own table.
- A source state letter that is the authors' recode of another (P from N) keeps both
  letters in `y_raw` under one `y` code, with the counts asserted.
- NA in a species x survey matrix means "not scored", not "not surveyed", only when
  every NA taxon-period has no detection anywhere in that period and every scored
  taxon is detected somewhere; assert both, ship `y = 0` with `y_raw = "NA"`.
- A source `replicate` or `round` number with gaps is not evidence of lost surveys
  until the walk count per unit-period is checked against the protocol.
- Pollard-walk archives on GBIF record a section only where something was seen, so
  the unit is the transect walk (sections summed) unless empty section events exist.
- A covariate from a separate survey (fisheries prey biomass, regional weather) is
  not derived from these detections and may ship, in `__periods` or as `unit_`.
- Dryad's `primary_article` field can be wrong; check the paper by title.
- A deposit of model inputs (SDM presence and pseudo-absence points, gridded arrays
  with no survey list) is held: there is no survey set.
- GBIF strict name matching can resolve a homonym to a kingdom or family, and the
  IUCN endpoint can answer for a synonym's different species. `make_taxa()` asserts
  EXACT matches and `iucn_category()` checks the assessed name; HTTP 204 is "not
  assessed".

**Rules from the 2026-11-06 rulings** (clauses in `standard.md`; the how-to here):

- eDNA with Ct values and no call: `y = as.integer(!is.na(ct) & ct != "Undetermined")`,
  `y_raw` the Ct string as deposited. Find the field blanks per sampling event in the
  deposit, assert their count, and set `obs_blank_positive` on every row of an event
  whose blank amplified. An author's call (a Ct cutoff, an LOD rule in the readme)
  wins; cite it in the header.
- An all-zero table: assert that `y` is all 0, and put "No detection in any survey;
  detection probability is not estimable from this table alone" in `notes`.
- A detector shared by all taxa with a not-surveyed mark for one taxon: drop that
  survey for every taxon, assert the number dropped, list it in `notShipped`.
- Count-detector SCR: one row per individual x trap operated, `y` the encounter count
  under the source's independence rule (name it in `samplingProtocol`),
  `effortColumn = "obs_effort_days"`, `closure = "none"`, `occasionKind = "none"`.
- Time to detection: `obs_ttd` (units in the column description) holds the time, or
  the survey length where not detected; `obs_ttd_censored` is 1 there and 0 otherwise.
- A survey set inferred from detections: state the rule in `surveyEvidenceNote` and
  the header, and say that surveys with no detection of anything are absent.
- Ids valid only within a session: make the unit `<session>_<id>` (or assert the
  source's ids are already unique across sessions) and say so in `closureNote`.
- Within-visit intervals: `occasion` is the visit; `y` is the visit's detection or
  total, built from the intervals and asserted equal to any visit-level value the
  source gives; `obs_int1`, `obs_int2`, ... carry the intervals.
- Several sign types: read which sign types the authors' model counts as a detection
  and build `y` from those; ship each sign count as `obs_<sign>`; cite the paper's
  definition in the header.
- Per-visit series plus season total (Swiss MHB): build the per-visit table with
  `__survey_taxa` (visits outside a species' counting window, and square-years with no
  per-visit values, are not surveyed for that species), then the total table from the
  total column; assert how many positive totals have no per-visit values, which is why
  the second table ships.
- Several people's interpretations of the same field visits (territory editors): one
  table, `occasion` = visit x interpreter, `observer` = the interpreter's code,
  `occasionKind = ["time", "observer"]`, `closure = "dependent"` (they share the field
  data); never one table per interpreter.
- Synonyms: merge only names the source uses for one species, assert the merge, and
  list both names in `taxonRemarks`.
- Licence: ODC-By 1.0 proceeds like CC BY. Zenodo "Other (Open)" with no text, or a
  CC0 badge with a consult-the-PIs clause: hold as `held: unclear licence terms` and
  ask by email; a refusal or no reply leaves the deposit linked, not reshared.

## Metadata (`__dataset.json`)

`write_table()` takes the `dataset` list and refuses one that fails the E10
contract. Required: `title`, `creator`, `pubDate`, `citation`, `sourceURL`,
`intellectualRights` (`spdx`, `url`), `samplingProtocol` (a sentence),
`samplingProtocolCode` (a token: `camera_trap`, `point_count`, `line_transect`,
`mist_net`, `live_trap`, `removal`, `double_observer`, `eDNA`, `acoustic`,
`territory_survey`, ...), `responseType`, `unitKind`, `closure` and `occasionKind` (one of the E8 values; prose
goes in `closureNote`), `taxonInclusion` (`recorded` | `target` | `single`, E10),
`surveyEvidence`, `temporalCoverage` (`YYYY/YYYY` or `YYYY-MM/YYYY-MM`),
`geographicCoverage`. Conditional: `stateCodes`, `multinomialType` or
`distanceBreaks`, `coordinatesCoarsened`, `surveyEvidenceNote`, `crs`, `effortColumn`,
`taxaWithheld`, `detectionCertainty`. Recommended:
`abstract`, `paperDOI`, `notShipped` (a named list: what and why), `notes`.
`write_table()` adds `summary`, `sampleFloor`, `columns`, `standardVersion`,
`script`, `buildDate`.

## Staging

`stage_dict_row()` writes the dictionary row: a one-sentence description, URL,
reference, DOIs, `original_license` (both licences when they conflict),
`derived_license`, `source_via`, and notes on how the deposit was fetched.
`stage_tag_row()` writes the tags row from the dataset object plus `taxon_group`,
`model_family`, `sampling_protocol`, `design`, `realm`, `country` (ISO 3166-1
alpha-3), `coordinates` (`None in source`, `As published`, `Coarsened (0.1 deg)`),
`notes`, `status` (`tagged`, or `tagged; do_not_publish: <reason>`). Vocabulary in
`tags/vocab.md`. Re-running the script replaces both rows.

## Verify before you ship

```bash
Rscript data/<table>.R                                   # builds, R twin passes
python3 -m eco_validate.cli output/<table>.csv -v --irw  # the gate, every finding, IRW view
python3 -m pytest eco_validate/tests -q                  # the corpus test now includes your table
```

Then read `output/<table>__dataset.json` once as a user would: does `summary` match
what the paper reports (sites, surveys, species)? If the paper says 100 ponds x 3
surveys and you have 299 surveys, the one missing is either a real unsurveyed cell
(assert it) or a bug.

## Common mistakes

- Treating a blank cell in a matrix as `y = 0`. Blank is "not surveyed" unless the
  readme says otherwise; assert which.
- Padding an unbalanced design to a rectangle with zeros.
- A `unit_` covariate that varies within a unit (it is `obs_` or `period_`).
- A bare year in `date`.
- Shipping an author's occupancy estimate as `unit_occupancy`.
- Coordinates finer than the source, or a flagged taxon at exact coordinates.
- A species code in `taxon` that is not in `__taxa`, or a `__taxa` row no core row uses.
- Trusting the repository's licence badge over the deposited readme.
- Fixing a check the validator raises by editing the validator. If the check is
  wrong, say so to Ben; the standard decides.

## Where things go

| Output | Path |
|---|---|
| script | `data/<table>.R` |
| core table, side tables, metadata | `output/<table>.csv`, `output/<table>__taxa.csv`, `__periods`, `__units`, `__traps`, `output/<table>__dataset.json` |
| dictionary and tags rows | `dictionary/dictionary_auto.csv`, `tags/tags_auto.csv` (upserted by code) |
| the queue row | `queue/candidates.csv`: `status = built: <table>`, or `held: ...` with a `queue/human_review.csv` row |
| the batch entry | `BATCH_LOG.md` |
| cached downloads | `.cache/raw/<table>/` (ignored by git) |
