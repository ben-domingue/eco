# Round-trip report

*2026-10-30. Six bundled datasets, native structure → draft standard → native,
with model fits on both. Scripts in `converters/rt_0*_*.R`; collated checks in
`converters/output/roundtrip_results.csv` (51 checks, 0 failures).*

| # | Dataset | Family | Native shape | Standard rows | Fit compared | Result |
|---|---------|--------|--------------|---------------|--------------|--------|
| 1 | `widewt.csv` (unmarked) — Swiss willow tit | single-season occupancy | 237 × 3, 46 NA | 665 | `occu` (unmarked) and NIMBLE `dOcc_s` | identical |
| 2 | `mallard` (unmarked) | N-mixture | 239 × 3, 58 NA, 4 all-NA sites | 659 | `pcount` | identical |
| 3 | `alfl` (unmarked) — Alder Flycatcher | removal / multinomial N-mixture | 50 × 3 cells | 150 | `multinomPois` | identical |
| 4 | `dipper` (marked) | CJS | 294 × 7 `ch` strings, sex | 2,058 | `marked::crm` Phi(~sex) p(~1) | identical |
| 5 | `crossbill` (unmarked) | dynamic occupancy | 267 × 27 (9 yrs × 3), 567 NA | 6,642 | `colext` | identical |
| 6 | `MHB2014` (AHMbook) — 158 species | community occupancy | 267 × 3 × 158, 1 all-NA site | 118,658 | NIMBLE community model (opt-in; arrays identical) | arrays identical |

"Identical" means `all.equal` on the coefficient vectors at 1e-6 (1e-5 for
`colext`), and for NIMBLE identical posterior means from the same seed.

## What matched

- The detection/count arrays, including the `NA` pattern, reconstruct exactly in
  all six cases. The explicit-zero rule (row ⇔ survey) carries the design
  without an `NA` token.
- Site covariates, observation covariates and species traits reconstruct
  exactly *at surveyed units/cells*.
- Capture histories reconstruct as the same strings in the same order; `freq`
  aggregation is recoverable by grouping.
- Every output file passes the draft's validator and, by construction, IRW
  v1.0 C1–C7 (`period`/`occasion` are C5 occasion columns; all other columns
  are prefixed).

## What did not match, and why it is acceptable

1. **Covariate values at unsurveyed cells.** `widewt` has 4 and `mallard` 22
   observation-covariate values (`date`, `ivel`) at cells where `y` is `NA`.
   `unmarked` stores them; the long format cannot. They enter no likelihood.
2. **Covariates of never-surveyed units.** `mallard` has 4 sites and `MHB2014`
   1 site with no surveys at all; their site covariates are lost from the core
   file. Likelihood-irrelevant, but the *sampling frame* is lost — hence the
   `units` side table in the draft (§5.2).
3. **Period-level covariates at unsurveyed site × period.** `crossbill`'s
   `year` is missing at 48 of 2,403 site-years. `unmarked` cannot fit `colext`
   with `NA` there, so the test rebuilds `year` from `period`. A covariate that is
   a function of `period` alone belongs in the `periods` side table (§5.4), not in
   the core file.
4. **Multinomial cell structure.** `alfl`'s removal design is not recoverable
   from the table: the standard needs `dataset.multinomialType`. The round trip
   passes only because the test supplies `type = "removal"` from metadata.

## What felt forced

- `alfl`: survey-level covariates (`time.1`, `date.1`) are site covariates in the
  vignette's frame because only survey 1 is used; in the standard they are
  `cov_` with a `.1` suffix. Harmless here, but it shows that the level of a
  covariate is a property of the *design as deposited*, not of the variable.
- The community table is 95% zeros and 7.6 MB from a 0.3 MB array. Dense zeros
  are honest and IRW-like; they are also the obvious thing to question (README
  decision 2).
- CJS needs only `period`; a reader expecting `occasion` on every table will
  find it absent. The draft says `occasion` is conditional, which the validator
  enforces.

## Changes made to the standard as a result

See the v0.2 changelog in `standard_draft.md`: `season`/`visit` → `period`/
`occasion`; `periodcov_` and the `periods` side table; the §9 rows on
unsurveyed cells and units; `multinomialType` required; `freq` expansion rule.

## Not tested

Spatial capture–recapture (traps as items), distance sampling, false-positive
occupancy, multi-state capture–recapture, and any Darwin Core archive. The
converter library handles arrays, `unmarked` frames, multinomial frames and
capture-history data frames; a DwC event-core converter is the next one to write
because that is the shape of the largest public sources.
