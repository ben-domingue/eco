# An IRW-style data standard for ecological detection data — draft v0.3

*Status: exploratory draft, v0.3 of 2026-10-31 (v0.2: 2026-10-30). Written against the IRW Data Standard v1.0
(beta, 2026-09-19, clauses C1–C7) and the data structures used by `unmarked`,
`AHMbook`/AHMnimble, `nimbleEcology`, `spOccupancy` and `marked`. Revised after the
Phase 2 round-trip tests (see `roundtrip_report.md`); the changelog is at the end.*

---

## 0. The one-paragraph version

Keep the IRW's long format and its three-column core, under local names. `unit` is
the thing that carries the latent ecological state (a site, or an individual animal).
`taxon` is the species probed for — always, even when there is only one. `y` is the
numeric observation (0/1 detection, a count, or a coded state). Two time columns,
`period` (the primary period across which the latent state may change) and
`occasion` (the replicate survey within a period, across which closure is assumed),
make `unit`–`taxon` pairs unique; spatial capture–recapture adds `trap`. Covariates
are prefixed by the level at which they are constant: `unit_`, `taxon_`, `period_`
(unit × period), `obs_` (survey row). A row exists if and only if a survey happened; a
missing row is *not* a zero. Species, survey-protocol and licence metadata live in
side tables borrowed from Darwin Core and EML. `eco_to_irw()` renames the columns to
IRW's `id`/`item`/`resp` and the table then validates under IRW v1.0 unchanged.

## 1. Why this is close to IRW at all

The hierarchical models fit with NIMBLE in Kéry & Royle's *AHM* share the structure
of an taxon response model: a unit has a latent quantity, and that quantity is
observed imperfectly through repeated probes whose detection parameters play the
role of taxon parameters.

| Ecology (AHM / NIMBLE)              | Latent state per unit        | Probe                       | IRT analogue                              |
|-------------------------------------|------------------------------|-----------------------------|-------------------------------------------|
| Single-season occupancy             | z_i ∈ {0,1} (site occupied)   | visit j                     | one dichotomous taxon, repeated trials     |
| N-mixture                           | N_i ∈ ℕ (site abundance)      | visit j, binomial count     | count taxon, repeated trials               |
| Multinomial N-mixture (removal, double-observer) | N_i                | pass / observer cell        | nominal taxon                              |
| Cormack–Jolly–Seber (CJS)           | alive_it (individual, per time) | capture session t         | longitudinal 0/1 taxon with absorbing state |
| Dynamic (multi-season) occupancy    | z_it (site, per season)        | visit j within season t     | longitudinal taxon, HMM over waves         |
| Community / multi-species occupancy | z_ik (site × species)          | species k × visit j         | **multilevel IRT: species are items**      |
| Spatial capture–recapture (SCR)     | activity centre s_i            | trap k × occasion j         | traps as items with coordinates            |
| Distance sampling                   | N_i and detection-by-distance  | detected individual + distance | awkward: rows are individuals, not probes |

The community occupancy model is the clearest case: logit P(detect species k at
site i on visit j) = α_k + …, with species-level random effects — a random-taxon
model. That is what motivates putting the species, not the visit, on `taxon`.

---

## 2. Core table

One CSV, long format, one row per **survey observation** of one unit for one taxon.

| Column       | Required | Definition | IRW v1.0 status |
|--------------|----------|------------|-----------------|
| `unit`       | yes | Identifier of the unit carrying the latent state: a site/point/transect/camera station for occupancy, N-mixture and community data; an individual animal for capture–recapture. Unique per unit, not per row. | C2 (`id`) |
| `taxon`      | yes | Identifier of the taxon probed for. A short stable code (`CHAFFINCH`, `TAMSCI`, or the source's species code); resolved to a scientific name and a GBIF taxon key in the `__taxa` side table (§5). Single-species tables have one value. | C3 (`item`) |
| `y`          | yes | The observation, numeric. 0/1 for detection/non-detection and capture histories; a non-negative integer for counts; an integer cell code for multinomial observations with the label in `y_raw`. Never a missing code and never an aggregate (e.g., a site total across visits is not a `y`). | C4 (`resp`) |
| `period`     | conditional | Primary period (season, year, primary session). Integer, ordered in time. Required whenever the latent state is allowed to change between surveys (dynamic occupancy, CJS, robust design). Omit for single-season data. | one of the C5 occasion columns |
| `occasion`   | conditional | Secondary occasion: the replicate survey within a period (visit, trapping night, removal pass, distance bin). Integer, ordered in time where time is meaningful. Required whenever an `unit`–`taxon`(–`period`) combination has more than one row. | one of the C5 occasion columns |
| `y_raw`   | no | The observation as recorded when `y` is a recode (a multinomial cell label such as `"10"` for "seen by observer 1 only"; a removal interval label; a raw count when `y` has been collapsed to 0/1). | optional element |
| `date`       | no | Survey date of this row as ISO 8601: `YYYY-MM-DD`, or `YYYY-MM-DDThh:mm[:ss]Z` when the time is known. Never a bare year or a day-of-year (those go to `__periods` or `obs_date_doy`). `eco_to_irw()` converts to Unix seconds. | optional element (`date`), encoding differs |
| `observer`      | no | Observer identifier for this row. Same semantics as IRW `observer` ("identifier associated with the observer producing the rating"). | optional element |
| `unit_*`      | no | Covariates constant within `unit`: site covariates (elevation, forest cover, coordinates), individual covariates (sex, stratum). | optional element |
| `taxon_*`  | no | Covariates constant within `taxon`: species traits (body mass, guild, migratory status). Prefer to carry these in the `taxa` side table and only copy into the core file when convenient. | optional element |
| `period_*`| no | Covariates constant within `unit` × `period`: yearly site covariates (habitat in year t), individual time-varying covariates in CR (age class at session t). `unmarked`'s `yearlySiteCovs`. | **new**, follows the `unit_` convention |
| `obs_*`      | no | Covariates that vary row by row: wind, temperature, survey duration, time of day, effort, trap-dependence indicator, distance (for distance sampling). `unmarked`'s `obsCovs`. | **new** |
| `treat`      | no | Experimental manipulation indicator (1/0) in manipulative field experiments (e.g. predator exclosure). | optional element |
| `cluster_id` | no | A grouping of units above `unit` that is a design element rather than a covariate: transect for points-on-transects, trapping grid for individuals, study region. | optional element |

Column order: `unit, taxon, y, y_raw, trap, period, occasion, date, observer, treat,
cluster_id, unit_*, period_*, obs_*, taxon_*`.

**Why not two new prefixes instead of `obs_`?** An `obs_` column that happens to
be constant within `unit` is not a defect, so one could argue for a single
"everything else" prefix. The three-level split is kept because it is exactly the
split `unmarked`, `spOccupancy` and the AHM BUGS code expect as separate inputs,
and because the level at which a covariate is constant tells a modeller which
sub-model it belongs in (state vs. observation) without consulting documentation.

**Why `period`/`occasion` rather than IRW's `wave`?** Both names are already
accepted by IRW C5 as occasion-distinguishing columns, so the IRW view validates
without a special case. `wave` would be acceptable for `period` and a converter
to a plain IRW view may rename it, but ecologists will read `period`/`occasion`
(primary/secondary) correctly and `wave` wrongly.

### 2.1 Encoding rules for `y`

| Data type | `y` | `y_raw` | Notes |
|-----------|--------|------------|-------|
| Detection / non-detection | 0 or 1 | — | A count collapsed to 0/1 keeps the count in `y_raw`. |
| Repeated counts (N-mixture) | integer ≥ 0 | — | |
| Capture history (CJS, JS, robust design) | 0 or 1 | — | Rows before first capture are kept as 0 (a trapping session happened). Losses on capture: no rows after the removal session; record the removal in `obs_removed = 1` on the capture row. |
| Removal counts | count in removal interval | — | `occasion` = removal interval within the survey; the survey itself, if there are several, is `period` **only if** closure is not assumed across them — otherwise use `cluster_id`-style grouping via `obs_survey`. See §7 on multinomial data. |
| Double-observer / dependent double-observer | count in cell | cell label (`"10"`,`"01"`,`"11"`) | `occasion` indexes the cell. |
| Binned distance sampling | count in distance bin | bin label | `occasion` indexes the bin; bin breaks go in dataset metadata (`distance_breaks`). |
| Individual-level distance sampling | 1 | — | One row per detected individual with `obs_distance`; sites with no detections get a single row with `y = 0` and no distance. **Experimental**, see §8. |
| Multi-state (e.g. breeding status, disease state) | integer state code, 0 = not detected | state label | Codes defined in metadata `state_codes`. |

`y` must be numeric (IRW C4). Counts that were themselves imputed or
interpolated should be removed.

### 2.2 Uniqueness (IRW C5)

The key is `(unit, taxon, trap, period, occasion)`, with absent columns treated as 1. A duplicate key is a defect. If a source records two observers'
results for the same visit as separate rows, the observer is the secondary
replicate and should be recorded as `occasion` with `observer` giving the identity —
not as duplicate rows.

---

## 3. Mapping tables by model family

For each family: what goes where, the recommended mapping, and alternatives that
were considered. "Native" refers to the `unmarked` / AHM representation.

### 3.1 Single-season occupancy (AHM ch. 10; `unmarked::occu`; `nimbleEcology::dOcc`)

Native: `y[M, J]` 0/1; `siteCovs` data.frame (M rows); `obsCovs` M×J matrices.

| Native | Standard |
|--------|----------|
| row i of `y` | `unit` |
| column j of `y` | `occasion = j` |
| `y[i,j]` | `y` |
| `NA` in `y[i,j]` | **no row** |
| species | `taxon` (one value) |
| `siteCovs$x` | `unit_x` |
| `obsCovs$w[i,j]` | `obs_w` |

Alternatives considered: (a) `taxon = paste0("visit_", j)` — the "visit-as-taxon"
view. It makes the table look like a person × taxon matrix and a plain IRT model
can be fit to it directly. It is rejected as the canonical form because visits are
not shared probes (visit 2 at site A has nothing in common with visit 2 at site B
beyond its index), and because it does not generalise to multi-species data. It is
a one-line pivot from the canonical form and is documented as a *derived view* in
§9. (b) `unit = site × visit` with a single taxon — loses the replication structure
that the whole model depends on.

### 3.2 N-mixture (AHM ch. 6; `unmarked::pcount`; `nimbleEcology::dNmixture`)

Identical to 3.1 with `y` a count. Mixture family (Poisson / NB / ZIP) and the
upper bound K are analytic choices, not data. `unmarked` additionally allows
`yearlySiteCovs` for multi-season `pcountOpen` → `period_`.

### 3.3 Multinomial N-mixture (AHM ch. 7; `unmarked::multinomPois`, `gmultmix`)

Native: `y[M, C]` cell counts with a `type` (`"removal"`, `"double"`,
`"depDouble"`) that defines the multinomial cell probabilities as a function of p.

| Native | Standard |
|--------|----------|
| site | `unit` |
| cell c | `occasion = c`, `y_raw` = cell label |
| `y[i,c]` | `y` |
| `type` | dataset metadata `multinomial_type` |
| `obsCovs` (per survey, replicated over cells in unmarked) | `obs_*` |

When a site is surveyed on several visits each with C cells (`gmultmix`: M × T × C),
visits are `period` if the population is open between visits and closed within;
otherwise use `occasion = (t−1)·C + c` with `obs_visit = t` and `y_raw` the cell
label. **This is the family where the format feels most forced** (§8): the cells
are not time-ordered replicates in the double-observer case, they are categories
of a single multinomial draw. The information is preserved; the semantics of
`occasion` are stretched.

### 3.4 Capture–recapture: CJS (AHM ch. 7.8-style spatially stratified CR, `marked::crm`, `nimbleEcology::dCJS`)

Native (`marked`, `RMark`): data.frame with `ch` = `"0110100"` string, `freq`,
and individual covariates; or a `CH[N, T]` matrix.

| Native | Standard |
|--------|----------|
| individual i | `unit` |
| character t of `ch` | `period = t` (sessions are primary periods: the state may change between them) |
| `ch[t]` | `y` 0/1 |
| species | `taxon` (one value) |
| `freq` | expand into `freq` identical individuals with distinct `unit`s |
| sex / group / stratum | `unit_sex`, `unit_stratum` |
| time-varying individual covariate (age, trap-dependence) | `period_*` |
| session-level covariate (effort, flow) | `period_*` — but it is constant across `unit`, so prefer the `periods` side table (§5.4) |
| `-1` loss on capture (MARK) | last row is the removal session, `obs_removed = 1`, no later rows |

Alternative considered: `occasion` rather than `period` for sessions, on the
grounds that there is only one time axis. Rejected: in CJS the latent state
(alive) evolves between sessions, which is precisely what `period` means; keeping
`occasion` for within-period replicates means a robust-design table (primary
sessions × secondary trap nights) needs no new column.

No "survey happened for this individual at this session" problem arises as long as
every individual is at risk of capture on every session; a session on which some
individuals were not at risk (e.g. a sub-site not trapped) is encoded by omitting
those rows, which `marked` cannot represent natively — see §4.

### 3.5 Dynamic (multi-season) occupancy (AHM vol. 2; `unmarked::colext`; `nimbleEcology::dDynOcc`)

Native: `y[M, T·J]` with `numPrimary = T`; `siteCovs`; `yearlySiteCovs` (M × T);
`obsCovs` (M × T·J).

| Native | Standard |
|--------|----------|
| site | `unit` |
| primary t | `period` |
| secondary j | `occasion` |
| `yearlySiteCovs` | `period_*` |
| `obsCovs` | `obs_*` |

### 3.6 Community / multi-species occupancy or abundance (AHM ch. 11; `spOccupancy::msPGOcc`; `unmarked::occuComm`)

Native: `y[M, J, K]` (AHMbook) or `y[K, M, J]` (spOccupancy) array; `siteCovs`;
`obsCovs` M×J; species traits K-vector.

| Native | Standard |
|--------|----------|
| site | `unit` |
| species k | `taxon` |
| visit j | `occasion` |
| `y[i,j,k]` | `y` |
| species trait | `taxon_*` (and the `taxa` table) |
| `obsCovs[i,j]` | `obs_*`, repeated across the K species rows for that survey |

The repetition of `obs_*` across species is deliberate: it keeps the file flat and
IRW-valid. The **explicit-zero rule** (§4) matters most here: every surveyed (i, j)
has K rows, so the species list is recoverable from the table and "surveyed but
not detected" is distinguishable from "not surveyed". Data augmentation (the
all-zero pseudo-species M − K used to estimate richness) is an analytic device and
is **not** stored.

### 3.7 Spatial capture–recapture (SCR; `nimbleSCR`, `secr`)

Native: `y[N, K_traps, J]` captures; trap coordinates; a habitat mask / state space.

| Native | Standard |
|--------|----------|
| individual | `unit` |
| species | `taxon` (one value) |
| trap | `trap` — a second probe index beside `occasion`; coordinates in the `__traps` side table (`trap`, `x`, `y`, `crs`, usage) |
| occasion | `occasion` |
| capture | `y` 0/1 (or count for count detectors) |
| trap usage (trap k not operated on occasion j) | omit rows |
| state space / mask | not stored (analytic); the trap polygon is recoverable from `__traps` |

v0.2 put traps on `item`; with `taxon` as the required column that reading is no
longer available, so SCR gets its own key column. The `y` array is recovered by a
pivot over `(unit, trap, occasion)`. SCR is "fits with extensions".

### 3.8 Distance sampling

See §8. Binned: fits (`occasion` = distance bin). Continuous: experimental.

---

## 4. Missingness: the explicit-zero rule

**A row exists if and only if a survey was conducted for that `(unit, taxon, trap, period,
occasion)`. A `y` of 0 means surveyed and not detected. A missing row means not
surveyed. No row ever carries an empty `y`.**

Consequences:

1. Unbalanced designs (sites visited 1–3 times, as in the Swiss MHB) are encoded by
   row count, not by `NA` padding. The converter back to the native matrix pads
   with `NA`.
2. Multi-species tables must carry a 0 row for every species on the list at every
   conducted survey. The list of species is therefore exactly `unique(taxon)` and
   needs no separate declaration — but the `taxa` side table should still exist
   for the taxonomic resolution.
3. A site that was never surveyed in the study has no rows, and its covariates are
   therefore lost from the core table. If its existence matters (it does for the
   sampling frame), it belongs in the `units` side table.
4. CJS: a session at which an individual was known not to be at risk (dead on
   capture, outside the trapped area) has no row.

This is the same rule as IRW C4 ("rows without a response SHOULD be omitted") with
the additional, ecology-specific insistence that a non-detection *is* a response.
The failure mode this guards against — treating an unvisited site-occasion as a
non-detection — biases detection probability downward and is the single most
consequential encoding error in this domain.

---

## 5. Side tables

The core file is complete on its own for modelling. Side tables carry what IRW
carries in its taxon-text and metadata tables.

### 5.1 `__taxa` (taxon table) — analogous to IRW taxon text

| Column | Definition | Borrowed from |
|--------|------------|---------------|
| `taxon` | key | — |
| `scientificName` | Linnaean name as used by the source | DwC |
| `taxonRank` | species, genus, … | DwC |
| `taxonID` | resolvable identifier: `https://www.gbif.org/species/<usageKey>` or an ITIS TSN URI | DwC |
| `vernacularName` | common name | DwC |
| `taxon_*` | traits | — |

### 5.2 `__units` (site/individual table)

`unit`, `unit_*`, and for sites `decimalLatitude`, `decimalLongitude`,
`coordinateUncertaintyInMeters` (DwC; WGS84 fixed). Optional; the same `unit_`
values are also in the core file.

### 5.3 `dataset` (JSON or YAML, one per table)

| Field | Borrowed from |
|-------|---------------|
| `title`, `creator`, `pubDate`, `abstract` | EML |
| `intellectualRights` (SPDX licence id + URL), `citation`, `doi`, `sourceURL` | EML / IRW biblio (`Original_License`, `Derived_License`) |
| `samplingProtocol` (free text) and `samplingProtocolCode` (`point_count`, `camera_trap`, `live_trap`, `line_transect`, `removal`, `double_observer`, `eDNA`, `acoustic`, …) | DwC |
| `samplingEffort` and `effortUnit` when effort is constant; otherwise `obs_effort` in the core | DwC |
| `responseType`: `detection` / `count` / `multinomial_cell` / `state` | new |
| `unitKind`: `site` / `individual` | new |
| `closure`: statement of which index closure is assumed over (`"occasion"` by default) | new |
| `multinomialType`, `distanceBreaks`, `stateCodes` | new, family-specific |
| `geographicCoverage` bounding box; `temporalCoverage` | EML |
| `coordinatesCoarsened`: boolean and method | new |

### 5.4 `__periods` (optional)

And `__traps` for SCR (§3.7).

### 5.4a `__periods`

`period`, calendar bounds, and any covariate constant across all units within a
period (session effort, flow, year-level climate). Keeps the core file from
carrying a column that is constant across every `unit`.

---

## 6. Spatial information

- Coordinates go in `unit_decimalLatitude` / `unit_decimalLongitude` (WGS84) with
  `unit_coordinateUncertaintyInMeters`. A projected `unit_x`/`unit_y` pair is allowed
  if `dataset.crs` names the EPSG code; converters do not reproject.
- **Coarsening.** Follow the source: never publish finer than the source did
  (IRW's existing rule). For taxa flagged sensitive by the source, by a national
  red list, or by GBIF's sensitive-species handling, generalise to a grid (0.1°
  or 10 km) and set `coordinateUncertaintyInMeters` accordingly, and set
  `coordinatesCoarsened = true`. Coarsening does not affect any model in §3 that
  does not use coordinates directly; it does affect spatial occupancy
  (`spOccupancy`'s spatial random effects) and SCR, for which the table should
  say so.
- Trap coordinates in SCR (`taxon_x`, `taxon_y`) are the same kind of
  sensitive information and follow the same rule.

---

## 7. Time

- `period` and `occasion` are integers ordered in time. `date` (ISO 8601) gives
  calendar time per row where known; ecological data has calendar dates, so the IRW's
  seconds encoding is not used (the IRW view converts). When only a survey day-of-year
  exists (common: `date` in AHM is Julian day), it goes in `obs_date_doy` **and**
  `date` is left empty rather than fabricated. A calendar year is a property of a
  `period` and belongs in `__periods`.
- Closure is assumed across `occasion` within a `period`. That is the convention of
  every model in §3; where a source violates it (counts across a whole season
  treated as closed), the `dataset.closure` field says so.
- Robust design = both columns present.
- For data without a natural replicate (single-visit occupancy with a detection
  covariate, or "time-to-detection" designs), `occasion` is omitted and the
  dataset declares `responseType` accordingly; such data fit IRW trivially (one
  row per unit) but support few of the models here.

---

## 8. Scope

**Fits the standard as written**

- single-season occupancy, incl. site-occupancy with false positives (`y` 0/1/2 with `stateCodes`)
- N-mixture, including zero-inflated and multi-season (`pcountOpen`)
- dynamic occupancy
- CJS, Jolly–Seber (same table; JS adds augmentation at analysis time), robust design, multi-state CR
- community occupancy / community N-mixture
- binned distance sampling and hierarchical distance sampling with bins
- removal sampling

**Fits with extensions / stretched semantics**

- multinomial N-mixture with non-ordered cells (double-observer): `occasion` indexes a category, not a replicate
- SCR: a `trap` key column beside `occasion` (§3.7)
- occupancy with continuous detection covariates at the individual-detection level (e.g. per-detection confidence scores): one row per detection with `obs_*`, plus a 0 row per survey without detections

**Out of scope (for now)**

- continuous-distance sampling as the canonical form (binned is the canonical form; an experimental individual-row encoding is described in §2.1)
- telemetry / movement data (Movebank): no latent state per unit in the above sense; continuous location process
- occurrence-only (presence-only) data such as most of GBIF: no survey rows, so the explicit-zero rule cannot be met; these are not detection data
- integrated population models' auxiliary data (productivity counts, ring recoveries) — may be separate tables under the same `dataset`

---

## 9. What is lost, and what is only *moved*

| NIMBLE user needs | Status |
|-------------------|--------|
| The `NA` pattern of unbalanced designs | **moved**: recovered by pivot + padding |
| Number of sites M, visits J, species K | recovered from the table |
| Data augmentation size (community models, JS) | **analytic**, not data; user chooses |
| Upper bound K for N-mixture | analytic |
| Multinomial cell-probability function | **lost** unless `dataset.multinomialType` is set; it is required for that family |
| Distance bin breaks | `dataset.distanceBreaks`, required for binned DS |
| State space / habitat mask (SCR) | **lost**; it is derived from trap layout + buffer at analysis time |
| Effort offsets | `obs_effort` or `dataset.samplingEffort` |
| Trap usage matrix (SCR) | moved: missing rows |
| Species list including never-detected species | **lost** unless the source's list is carried as all-zero rows (recommended) or in `taxa` |
| Which sites were in the sampling frame but never visited | **lost** from core; `units` side table |
| Observation-covariate values at *unvisited* occasions | lost; harmless, since the model does not use them — but `unmarked` stores them, so the round trip is lossless only up to those cells |

**Derived "visit-as-taxon" view.** For single-species tables, a user wanting a plain
person × taxon matrix sets `taxon := paste(taxon, period, occasion)`. This is exactly
how IRW's repeated-trial tables are used with standard IRT software and needs no
support from the standard.

---

## 10. Naming and intake

- Table names: `author_year_taxonOrCommunity_type`, lowercase, ≤ 40 characters,
  e.g. `kery_2015_squirrel_occ`, `sauer_2021_bbs_count`, `lebreton_1992_dipper_cjs`.
- Type suffixes: `occ`, `count`, `cjs`, `dynocc`, `comm`, `removal`, `dobs`, `ds`, `scr`, `state` (multi-state responses).
- One file per *survey design × response type*. A paper with a bird community
  point-count dataset and a small-mammal trapping grid yields two tables.
- Sample floor (ruled 2026-11-01): **a reported attribute, not an intake gate.**
  IRW's 100-`unit` floor exists for psychometric power on a person × item matrix;
  the quantity that limits an occupancy or capture–recapture model is different,
  and ecology is a corpus of small tables. Every table carries `sampleFloor` in its
  `__dataset.json` and `sample_floor` in the tags: `meets` when ≥ 30 units **and**
  ≥ 2 occasions (or ≥ 2 periods for CR), otherwise `below (reason)`. Users filter
  on it; the warehouse ships small tables and does not prioritise finding them.
  For community tables the per-unit count understates the information (10 sites ×
  43 species × 20 surveys), which is one more reason the floor is a filter rather
  than a rule.
- Licence handling: adopt IRW's intake rules unchanged (CC0/BY/BY-SA/NC/GPL hosted
  with propagation; ND and unlicensed not hosted). Note that much ecological data
  is CC0 by repository policy (Dryad, EDI by default) — a favourable contrast with
  psychology.

---

## 11. Storage: one dataset, tables typed by structure

*Added 2026-10-31 after the first upload.* The IRW keeps response tables and taxon
text in separate Redivis datasets and separate shard lists. For eco the side tables
(`__items`, `__periods`, `__units`) are small, there are several kinds, and every one
of them is meaningless without its core table, so the simplest rule is adopted:

- **One Redivis dataset holds everything** (`datapages.eco`). A core table `<t>` and
  its side tables `<t>__items`, `<t>__periods`, `<t>__units` sit next to each other.
- **A table's kind is defined by its structure, not by where it lives.** A core table
  has `unit`, `taxon`, `y`; an `__items` table has `taxon` as its key; `__periods` has
  `period`; `__units` has `unit`. The suffix is a convenience for humans and for
  `LIKE` queries; the key column is the contract.
- **Per-table metadata travels as the Redivis table description**, generated from
  `<t>__dataset.json` (title, citation, licence, response/unit/taxon kind, closure,
  counts). The dictionary row and the tags row are kept in the repository
  (`dictionary/`, `tags/`) as in the IRW.
- Sharding (IRW's 1000-table cap) is not a concern at the expected scale; if it
  becomes one, shard by core table and keep each table's side tables in its shard.

This is also the reason the eco uploader (`upload/red_up_eco.py`) wraps IRW's
`red_up` rather than using it directly: `red_up` treats any `__items.csv` as taxon
text and routes it away from the core dataset.

## 12. Open questions for Ben

1. **Species as the probe versus visit as the probe.** The draft makes `taxon` the required probe column,
   which makes single-species tables look like IRW's repeated-trial family (one
   taxon, many `occasion`s). The psychometric payoff of the warehouse comes from the
   multi-species tables. Is a corpus in which most tables have a single `taxon`
   acceptable, or should the canonical form be the visit-as-taxon view with
   species as a different column? (Reversible: it is a pivot.)
2. ~~**Sample floor.**~~ Ruled 2026-11-01: a reported attribute (§10), not an intake rule.
3. **Dense zeros for community data.** The explicit-zero rule multiplies rows by
   the species count (MHB 2014: 267 sites × 3 visits × 158 species = 127k rows,
   ~95% zeros). Alternative: a `surveys` side table listing conducted surveys, with
   the core file holding only non-zero rows. The dense form is IRW-like and
   self-contained; the sparse form is Darwin Core's event-core model. Draft
   recommends dense.
4. **Should `obs_` covariates live in the core file** (flat, IRW-like, duplicated
   across species) or only in a `surveys` side table? Same tradeoff as (3).
5. **Sensitive-species policy**: coarsen by rule (draft) versus exclude
   coordinates entirely for any flagged taxon.
6. **Multinomial / distance families**: accept the stretched `occasion` semantics,
   or declare them out of scope for v1 and keep the standard clean?

---

## Changelog

- **v0.3.1 (2026-11-01)**: the sample floor is a published, filterable attribute
  (`sample_floor` = `meets` / `below (reason)`), not an intake gate (§10, closes open
  question 2). The two tables previously tagged `hold` (`schank_2015_tapir_occ`,
  `palacio_2020_pampasbirds_comm`) are published like any other; the `hold` status
  value is retired and `do_not_publish: <reason>` replaces it for tables that must
  not ship, which the uploader now refuses.

- **v0.3 (2026-10-31)**:
  - **Local nomenclature.** `id`/`item`/`resp` → `unit`/`taxon`/`y`; `resp_raw` → `y_raw`;
    `rater` → `observer`; prefixes `cov_`/`periodcov_`/`itemcov_` → `unit_`/`period_`/`taxon_`
    (`obs_` unchanged); side table `__items` → `__taxa`. The IRW names were kept in v0.1–0.2
    to show the tables validate under IRW v1.0 unchanged; that is now the job of the
    `eco_to_irw()` view, which the validator and uploader run before `irw-validate`.
  - `date` is ISO 8601, not Unix seconds.
  - SCR: traps move from `item` to a `trap` key column with a `__traps` side table;
    `itemKind` is dropped. The uniqueness key is `(unit, taxon, trap, period, occasion)`.
  - §11 on storage (one dataset, kinds defined by structure); `state` added to the §10
    type suffixes after the loon table; six public deposits built under `data/`.

- **v0.1** (2026-10-30, pre-round-trip): initial draft as above with `season` for
  the primary period and `visit` for the secondary.
- **v0.2** (2026-10-30, post-round-trip; see `roundtrip_report.md`):
  - Renamed `season`→`period`, `visit`→`occasion` so both are literally IRW C5
    occasion-column names, and so the same two columns serve dynamic occupancy
    (crossbill: period = year, occasion = visit) and CJS (dipper: period =
    session, no occasion) without a special case.
  - Added `period_` after `crossbill` needed `yearlySiteCovs`; and added the
    `periods` side table (§5.4) after the round trip showed that a period-level
    covariate is lost at every site × period with no survey (48 of 2,403 in
    crossbill) — a covariate that is a function of `period` alone should not be
    carried in the core file at all.
  - Added the §9 rows on covariates at *unsurveyed* cells and *unsurveyed* units:
    `widewt` carries 4 and `mallard` 22 observation-covariate values at cells
    where `y` is `NA`, and `mallard` (4 sites), `MHB2014` (1 site) carry site
    covariates for units with no surveys. None of these can be represented in a
    file whose rows are surveys; all are irrelevant to the likelihood. The
    `units` side table (§5.2) is the home for the latter.
  - Made `dataset.multinomialType` required for multinomial tables after `alfl`
    showed the cell-probability structure is not recoverable from the table.
  - Added the `freq` expansion rule (§3.4) from converting `dipper`; added
    `obs_removed` as the proposed encoding for losses on capture (not exercised:
    `dipper` has none).
  - Recorded the cost of dense zeros for community data (§11 Q3): `MHB2014`
    becomes 118,658 rows (751 surveys × 158 species) and 7.6 MB, against a
    267 × 3 × 158 array.
