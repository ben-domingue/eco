# An IRW-style data standard for ecological detection data — draft v0.2

*Status: exploratory draft, 2026-10-30. Written against the IRW Data Standard v1.0
(beta, 2026-09-19, clauses C1–C7) and the data structures used by `unmarked`,
`AHMbook`/AHMnimble, `nimbleEcology`, `spOccupancy` and `marked`. Revised after the
Phase 2 round-trip tests (see `roundtrip_report.md`); the changelog is at the end.*

---

## 0. The one-paragraph version

Keep IRW's three required columns and its long format. `id` is the unit that carries
the latent ecological state (a site, or an individual animal). `item` is the species
(taxon) being probed for — always, even when there is only one. `resp` is the
numeric observation (0/1 detection, a count, or a coded category). Two time
columns, `period` (the primary period across which the latent state may change)
and `occasion` (the replicate survey within a period, across which it is assumed
closed), make `id`–`item` pairs unique, exactly as IRW's C5 allows. Covariates are
prefixed by the level at which they are constant: `cov_` (unit), `itemcov_`
(species), `periodcov_` (unit × period), `obs_` (survey row). A row exists if and
only if a survey happened; a missing row is *not* a zero. Species, survey-protocol
and licence metadata live in side tables borrowed from Darwin Core and EML. A table
in this format validates under IRW v1.0 unchanged.

---

## 1. Why this is close to IRW at all

The hierarchical models fit with NIMBLE in Kéry & Royle's *AHM* share the structure
of an item response model: a unit has a latent quantity, and that quantity is
observed imperfectly through repeated probes whose detection parameters play the
role of item parameters.

| Ecology (AHM / NIMBLE)              | Latent state per unit        | Probe                       | IRT analogue                              |
|-------------------------------------|------------------------------|-----------------------------|-------------------------------------------|
| Single-season occupancy             | z_i ∈ {0,1} (site occupied)   | visit j                     | one dichotomous item, repeated trials     |
| N-mixture                           | N_i ∈ ℕ (site abundance)      | visit j, binomial count     | count item, repeated trials               |
| Multinomial N-mixture (removal, double-observer) | N_i                | pass / observer cell        | nominal item                              |
| Cormack–Jolly–Seber (CJS)           | alive_it (individual, per time) | capture session t         | longitudinal 0/1 item with absorbing state |
| Dynamic (multi-season) occupancy    | z_it (site, per season)        | visit j within season t     | longitudinal item, HMM over waves         |
| Community / multi-species occupancy | z_ik (site × species)          | species k × visit j         | **multilevel IRT: species are items**      |
| Spatial capture–recapture (SCR)     | activity centre s_i            | trap k × occasion j         | traps as items with coordinates            |
| Distance sampling                   | N_i and detection-by-distance  | detected individual + distance | awkward: rows are individuals, not probes |

The community occupancy model is the clearest case: logit P(detect species k at
site i on visit j) = α_k + …, with species-level random effects — a random-item
model. That is what motivates putting the species, not the visit, on `item`.

---

## 2. Core table

One CSV, long format, one row per **survey observation** of one unit for one taxon.

| Column       | Required | Definition | IRW v1.0 status |
|--------------|----------|------------|-----------------|
| `id`         | yes | Identifier of the unit carrying the latent state: a site/point/transect/camera station for occupancy, N-mixture and community data; an individual animal for capture–recapture. Unique per unit, not per row. | C2, unchanged |
| `item`       | yes | Identifier of the taxon probed for. A short stable code (`CHAFFINCH`, `TAMSCI`, or the source's species code); resolved to a scientific name and a taxon ID in the `items` side table (§5). Single-species tables have one value. | C3, unchanged |
| `resp`       | yes | The observation, numeric. 0/1 for detection/non-detection and capture histories; a non-negative integer for counts; an integer cell code for multinomial observations with the label in `resp_raw`. Never a missing code and never an aggregate (e.g., a site total across visits is not a `resp`). | C4, unchanged |
| `period`     | conditional | Primary period (season, year, primary session). Integer, ordered in time. Required whenever the latent state is allowed to change between surveys (dynamic occupancy, CJS, robust design). Omit for single-season data. | one of the C5 occasion columns |
| `occasion`   | conditional | Secondary occasion: the replicate survey within a period (visit, trapping night, removal pass, distance bin). Integer, ordered in time where time is meaningful. Required whenever an `id`–`item`(–`period`) combination has more than one row. | one of the C5 occasion columns |
| `resp_raw`   | no | The observation as recorded when `resp` is a recode (a multinomial cell label such as `"10"` for "seen by observer 1 only"; a removal interval label; a raw count when `resp` has been collapsed to 0/1). | optional element |
| `date`       | no | Survey date-time of this row, as Unix seconds (UTC) — or seconds since the first survey in the dataset when only relative dates exist. Same encoding as IRW `date`. | optional element |
| `rater`      | no | Observer identifier for this row. Same semantics as IRW `rater` ("identifier associated with the rater producing the rating"). | optional element |
| `cov_*`      | no | Covariates constant within `id`: site covariates (elevation, forest cover, coordinates), individual covariates (sex, stratum). | optional element |
| `itemcov_*`  | no | Covariates constant within `item`: species traits (body mass, guild, migratory status). Prefer to carry these in the `items` side table and only copy into the core file when convenient. | optional element |
| `periodcov_*`| no | Covariates constant within `id` × `period`: yearly site covariates (habitat in year t), individual time-varying covariates in CR (age class at session t). `unmarked`'s `yearlySiteCovs`. | **new**, follows the `cov_` convention |
| `obs_*`      | no | Covariates that vary row by row: wind, temperature, survey duration, time of day, effort, trap-dependence indicator, distance (for distance sampling). `unmarked`'s `obsCovs`. | **new** |
| `treat`      | no | Experimental manipulation indicator (1/0) in manipulative field experiments (e.g. predator exclosure). | optional element |
| `cluster_id` | no | A grouping of units above `id` that is a design element rather than a covariate: transect for points-on-transects, trapping grid for individuals, study region. | optional element |

Column order: `id, item, resp, resp_raw, period, occasion, date, rater, treat,
cluster_id, cov_*, periodcov_*, obs_*, itemcov_*`.

**Why not two new prefixes instead of `obs_`?** An `obs_` column that happens to
be constant within `id` is not a defect, so one could argue for a single
"everything else" prefix. The three-level split is kept because it is exactly the
split `unmarked`, `spOccupancy` and the AHM BUGS code expect as separate inputs,
and because the level at which a covariate is constant tells a modeller which
sub-model it belongs in (state vs. observation) without consulting documentation.

**Why `period`/`occasion` rather than IRW's `wave`?** Both names are already
accepted by IRW C5 as occasion-distinguishing columns, so the table validates
without a special case. `wave` would be acceptable for `period` and a converter
to a plain IRW view may rename it, but ecologists will read `period`/`occasion`
(primary/secondary) correctly and `wave` wrongly.

### 2.1 Encoding rules for `resp`

| Data type | `resp` | `resp_raw` | Notes |
|-----------|--------|------------|-------|
| Detection / non-detection | 0 or 1 | — | A count collapsed to 0/1 keeps the count in `resp_raw`. |
| Repeated counts (N-mixture) | integer ≥ 0 | — | |
| Capture history (CJS, JS, robust design) | 0 or 1 | — | Rows before first capture are kept as 0 (a trapping session happened). Losses on capture: no rows after the removal session; record the removal in `obs_removed = 1` on the capture row. |
| Removal counts | count in removal interval | — | `occasion` = removal interval within the survey; the survey itself, if there are several, is `period` **only if** closure is not assumed across them — otherwise use `cluster_id`-style grouping via `obs_survey`. See §7 on multinomial data. |
| Double-observer / dependent double-observer | count in cell | cell label (`"10"`,`"01"`,`"11"`) | `occasion` indexes the cell. |
| Binned distance sampling | count in distance bin | bin label | `occasion` indexes the bin; bin breaks go in dataset metadata (`distance_breaks`). |
| Individual-level distance sampling | 1 | — | One row per detected individual with `obs_distance`; sites with no detections get a single row with `resp = 0` and no distance. **Experimental**, see §8. |
| Multi-state (e.g. breeding status, disease state) | integer state code, 0 = not detected | state label | Codes defined in metadata `state_codes`. |

`resp` must be numeric (IRW C4). Counts that were themselves imputed or
interpolated should be removed.

### 2.2 Uniqueness (IRW C5)

The key is `(id, item, period, occasion)`, with `period` and `occasion` treated as
1 when absent. A duplicate key is a defect. If a source records two observers'
results for the same visit as separate rows, the observer is the secondary
replicate and should be recorded as `occasion` with `rater` giving the identity —
not as duplicate rows.

---

## 3. Mapping tables by model family

For each family: what goes where, the recommended mapping, and alternatives that
were considered. "Native" refers to the `unmarked` / AHM representation.

### 3.1 Single-season occupancy (AHM ch. 10; `unmarked::occu`; `nimbleEcology::dOcc`)

Native: `y[M, J]` 0/1; `siteCovs` data.frame (M rows); `obsCovs` M×J matrices.

| Native | Standard |
|--------|----------|
| row i of `y` | `id` |
| column j of `y` | `occasion = j` |
| `y[i,j]` | `resp` |
| `NA` in `y[i,j]` | **no row** |
| species | `item` (one value) |
| `siteCovs$x` | `cov_x` |
| `obsCovs$w[i,j]` | `obs_w` |

Alternatives considered: (a) `item = paste0("visit_", j)` — the "visit-as-item"
view. It makes the table look like a person × item matrix and a plain IRT model
can be fit to it directly. It is rejected as the canonical form because visits are
not shared probes (visit 2 at site A has nothing in common with visit 2 at site B
beyond its index), and because it does not generalise to multi-species data. It is
a one-line pivot from the canonical form and is documented as a *derived view* in
§9. (b) `id = site × visit` with a single item — loses the replication structure
that the whole model depends on.

### 3.2 N-mixture (AHM ch. 6; `unmarked::pcount`; `nimbleEcology::dNmixture`)

Identical to 3.1 with `resp` a count. Mixture family (Poisson / NB / ZIP) and the
upper bound K are analytic choices, not data. `unmarked` additionally allows
`yearlySiteCovs` for multi-season `pcountOpen` → `periodcov_`.

### 3.3 Multinomial N-mixture (AHM ch. 7; `unmarked::multinomPois`, `gmultmix`)

Native: `y[M, C]` cell counts with a `type` (`"removal"`, `"double"`,
`"depDouble"`) that defines the multinomial cell probabilities as a function of p.

| Native | Standard |
|--------|----------|
| site | `id` |
| cell c | `occasion = c`, `resp_raw` = cell label |
| `y[i,c]` | `resp` |
| `type` | dataset metadata `multinomial_type` |
| `obsCovs` (per survey, replicated over cells in unmarked) | `obs_*` |

When a site is surveyed on several visits each with C cells (`gmultmix`: M × T × C),
visits are `period` if the population is open between visits and closed within;
otherwise use `occasion = (t−1)·C + c` with `obs_visit = t` and `resp_raw` the cell
label. **This is the family where the format feels most forced** (§8): the cells
are not time-ordered replicates in the double-observer case, they are categories
of a single multinomial draw. The information is preserved; the semantics of
`occasion` are stretched.

### 3.4 Capture–recapture: CJS (AHM ch. 7.8-style spatially stratified CR, `marked::crm`, `nimbleEcology::dCJS`)

Native (`marked`, `RMark`): data.frame with `ch` = `"0110100"` string, `freq`,
and individual covariates; or a `CH[N, T]` matrix.

| Native | Standard |
|--------|----------|
| individual i | `id` |
| character t of `ch` | `period = t` (sessions are primary periods: the state may change between them) |
| `ch[t]` | `resp` 0/1 |
| species | `item` (one value) |
| `freq` | expand into `freq` identical individuals with distinct `id`s |
| sex / group / stratum | `cov_sex`, `cov_stratum` |
| time-varying individual covariate (age, trap-dependence) | `periodcov_*` |
| session-level covariate (effort, flow) | `periodcov_*` — but it is constant across `id`, so prefer the `periods` side table (§5.4) |
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
| site | `id` |
| primary t | `period` |
| secondary j | `occasion` |
| `yearlySiteCovs` | `periodcov_*` |
| `obsCovs` | `obs_*` |

### 3.6 Community / multi-species occupancy or abundance (AHM ch. 11; `spOccupancy::msPGOcc`; `unmarked::occuComm`)

Native: `y[M, J, K]` (AHMbook) or `y[K, M, J]` (spOccupancy) array; `siteCovs`;
`obsCovs` M×J; species traits K-vector.

| Native | Standard |
|--------|----------|
| site | `id` |
| species k | `item` |
| visit j | `occasion` |
| `y[i,j,k]` | `resp` |
| species trait | `itemcov_*` (and the `items` table) |
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
| individual | `id` |
| trap | `item` — traps are the probes; `itemcov_x`, `itemcov_y` carry trap coordinates |
| occasion | `occasion` |
| capture | `resp` 0/1 (or count for count detectors) |
| trap usage (trap k not operated on occasion j) | omit rows |
| state space / mask | not stored (analytic); the trap polygon is recoverable from `itemcov_x`, `itemcov_y` |

This mapping is clean but **changes what `item` means** (a trap, not a taxon); a
table-level `item_kind` metadata field (`taxon` | `trap` | `station`) makes the
reading explicit. SCR is "fits with extensions".

### 3.8 Distance sampling

See §8. Binned: fits (`occasion` = distance bin). Continuous: experimental.

---

## 4. Missingness: the explicit-zero rule

**A row exists if and only if a survey was conducted for that `(id, item, period,
occasion)`. A `resp` of 0 means surveyed and not detected. A missing row means not
surveyed. No row ever carries an empty `resp`.**

Consequences:

1. Unbalanced designs (sites visited 1–3 times, as in the Swiss MHB) are encoded by
   row count, not by `NA` padding. The converter back to the native matrix pads
   with `NA`.
2. Multi-species tables must carry a 0 row for every species on the list at every
   conducted survey. The list of species is therefore exactly `unique(item)` and
   needs no separate declaration — but the `items` side table should still exist
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
carries in its item-text and metadata tables.

### 5.1 `items` (taxon table) — analogous to IRW item text

| Column | Definition | Borrowed from |
|--------|------------|---------------|
| `item` | key | — |
| `scientificName` | Linnaean name as used by the source | DwC |
| `taxonRank` | species, genus, … | DwC |
| `taxonID` | resolvable identifier: `https://www.gbif.org/species/<usageKey>` or an ITIS TSN URI | DwC |
| `vernacularName` | common name | DwC |
| `itemcov_*` | traits | — |

### 5.2 `units` (site/individual table)

`id`, `cov_*`, and for sites `decimalLatitude`, `decimalLongitude`,
`coordinateUncertaintyInMeters` (DwC; WGS84 fixed). Optional; the same `cov_`
values are also in the core file.

### 5.3 `dataset` (JSON or YAML, one per table)

| Field | Borrowed from |
|-------|---------------|
| `title`, `creator`, `pubDate`, `abstract` | EML |
| `intellectualRights` (SPDX licence id + URL), `citation`, `doi`, `sourceURL` | EML / IRW biblio (`Original_License`, `Derived_License`) |
| `samplingProtocol` (free text) and `samplingProtocolCode` (`point_count`, `camera_trap`, `live_trap`, `line_transect`, `removal`, `double_observer`, `eDNA`, `acoustic`, …) | DwC |
| `samplingEffort` and `effortUnit` when effort is constant; otherwise `obs_effort` in the core | DwC |
| `responseType`: `detection` / `count` / `multinomial_cell` / `state` | new |
| `unitKind`: `site` / `individual`; `itemKind`: `taxon` / `trap` | new |
| `closure`: statement of which index closure is assumed over (`"occasion"` by default) | new |
| `multinomialType`, `distanceBreaks`, `stateCodes` | new, family-specific |
| `geographicCoverage` bounding box; `temporalCoverage` | EML |
| `coordinatesCoarsened`: boolean and method | new |

### 5.4 `periods` (optional)

`period`, calendar bounds, and any covariate constant across all units within a
period (session effort, flow, year-level climate). Keeps the core file from
carrying a column that is constant across every `id`.

---

## 6. Spatial information

- Coordinates go in `cov_decimalLatitude` / `cov_decimalLongitude` (WGS84) with
  `cov_coordinateUncertaintyInMeters`. A projected `cov_x`/`cov_y` pair is allowed
  if `dataset.crs` names the EPSG code; converters do not reproject.
- **Coarsening.** Follow the source: never publish finer than the source did
  (IRW's existing rule). For taxa flagged sensitive by the source, by a national
  red list, or by GBIF's sensitive-species handling, generalise to a grid (0.1°
  or 10 km) and set `coordinateUncertaintyInMeters` accordingly, and set
  `coordinatesCoarsened = true`. Coarsening does not affect any model in §3 that
  does not use coordinates directly; it does affect spatial occupancy
  (`spOccupancy`'s spatial random effects) and SCR, for which the table should
  say so.
- Trap coordinates in SCR (`itemcov_x`, `itemcov_y`) are the same kind of
  sensitive information and follow the same rule.

---

## 7. Time

- `period` and `occasion` are integers ordered in time. `date` (Unix seconds)
  gives calendar time per row where known. When only a survey day-of-year exists
  (common: `date` in AHM is Julian day), it goes in `obs_date_doy` **and** `date`
  is left empty rather than fabricated.
- Closure is assumed across `occasion` within a `period`. That is the convention of
  every model in §3; where a source violates it (counts across a whole season
  treated as closed), the `dataset.closure` field says so.
- Robust design = both columns present.
- For data without a natural replicate (single-visit occupancy with a detection
  covariate, or "time-to-detection" designs), `occasion` is omitted and the
  dataset declares `responseType` accordingly; such data fit IRW trivially (one
  row per id) but support few of the models here.

---

## 8. Scope

**Fits the standard as written**

- single-season occupancy, incl. site-occupancy with false positives (`resp` 0/1/2 with `stateCodes`)
- N-mixture, including zero-inflated and multi-season (`pcountOpen`)
- dynamic occupancy
- CJS, Jolly–Seber (same table; JS adds augmentation at analysis time), robust design, multi-state CR
- community occupancy / community N-mixture
- binned distance sampling and hierarchical distance sampling with bins
- removal sampling

**Fits with extensions / stretched semantics**

- multinomial N-mixture with non-ordered cells (double-observer): `occasion` indexes a category, not a replicate
- SCR: `item` = trap, `itemKind = trap`
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
| Species list including never-detected species | **lost** unless the source's list is carried as all-zero rows (recommended) or in `items` |
| Which sites were in the sampling frame but never visited | **lost** from core; `units` side table |
| Observation-covariate values at *unvisited* occasions | lost; harmless, since the model does not use them — but `unmarked` stores them, so the round trip is lossless only up to those cells |

**Derived "visit-as-item" view.** For single-species tables, a user wanting a plain
person × item matrix sets `item := paste(item, period, occasion)`. This is exactly
how IRW's repeated-trial tables are used with standard IRT software and needs no
support from the standard.

---

## 10. Naming and intake

- Table names: `author_year_taxonOrCommunity_type`, lowercase, ≤ 40 characters,
  e.g. `kery_2015_squirrel_occ`, `sauer_2021_bbs_count`, `lebreton_1992_dipper_cjs`.
- Type suffixes: `occ`, `count`, `cjs`, `dynocc`, `comm`, `removal`, `dobs`, `ds`, `scr`.
- One file per *survey design × response type*. A paper with a bird community
  point-count dataset and a small-mammal trapping grid yields two tables.
- Sample floor: IRW's 100-`id` floor is the wrong unit here; many clean occupancy
  datasets have 50–100 sites. Proposed floor: ≥ 30 units **and** ≥ 2 occasions
  (or ≥ 2 periods for CR), so that detection is identifiable. Open question (§11).
- Licence handling: adopt IRW's intake rules unchanged (CC0/BY/BY-SA/NC/GPL hosted
  with propagation; ND and unlicensed not hosted). Note that much ecological data
  is CC0 by repository policy (Dryad, EDI by default) — a favourable contrast with
  psychology.

---

## 11. Open questions for Ben

1. **Species as `item` versus visit as `item`.** The draft puts species on `item`,
   which makes single-species tables look like IRW's repeated-trial family (one
   item, many `occasion`s). The psychometric payoff of the warehouse comes from the
   multi-species tables. Is a corpus in which most tables have a single `item`
   acceptable, or should the canonical form be the visit-as-item view with
   species as a different column? (Reversible: it is a pivot.)
2. **Sample floor.** 30 units × 2 occasions, or something else?
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

- **v0.1** (2026-10-30, pre-round-trip): initial draft as above with `season` for
  the primary period and `visit` for the secondary.
- **v0.2** (2026-10-30, post-round-trip; see `roundtrip_report.md`):
  - Renamed `season`→`period`, `visit`→`occasion` so both are literally IRW C5
    occasion-column names, and so the same two columns serve dynamic occupancy
    (crossbill: period = year, occasion = visit) and CJS (dipper: period =
    session, no occasion) without a special case.
  - Added `periodcov_` after `crossbill` needed `yearlySiteCovs`; and added the
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
