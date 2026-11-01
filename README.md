# eco — an IRW-style warehouse for ecological detection data?

*Exploratory study, 2026-10-30, extended 2026-10-31 with six built tables on Redivis (`datapages.eco`). Everything here is a draft for Ben to react to;
nothing is production.*

*Website: <https://ben-domingue.github.io/eco/> (source in `site/`, rendered by
`.github/workflows/site.yml`; preview locally with `cd site && quarto preview`).*

## The question

The IRW harmonises item-response data into one long-format table (`unit`, `taxon`,
`y`) so psychometric methods can be benchmarked at scale. Could the same move
work for the hierarchical ecological models fit with NIMBLE — occupancy,
N-mixture, capture–recapture, community models — where a site or animal has a
latent state observed imperfectly across repeated surveys?

## Short answer: yes, and more cheaply than for psychology

- **The structure maps.** `unit` = the unit carrying the latent state (site or
  individual), `taxon` = the taxon probed for, `y` = detection / count,
  `period` + `occasion` = primary / secondary survey indices (both already legal
  IRW C5 occasion columns), covariates prefixed by the level at which they are
  constant (`unit_`, `period_`, `obs_`, `taxon_` — exactly `unmarked`'s
  three covariate levels). A community occupancy model is literally a
  random-item IRT model with species as items. See `standard_draft.md`.
- **It round-trips.** Six bundled datasets covering single-season occupancy,
  N-mixture, removal/multinomial, CJS, dynamic occupancy and a 158-species
  community dataset convert to the format, validate, convert back to identical
  arrays, and give identical model estimates (`unmarked`, `marked`, NIMBLE) on
  native and reconstructed data. The only things lost are covariate values at
  surveys that never happened and units that were never surveyed — irrelevant
  to any likelihood, but they need a `units`/`periods` side table if the
  sampling frame matters. See `roundtrip_report.md`.
- **The data exists and is open.** Dryad alone has on the order of a thousand
  word-match hits for "detection history" / "detection/non-detection", nearly
  all CC0, usually deposited as the very site × occasion matrix the standard
  targets. ScienceBase (public domain), EDI/KNB (CC0), NEON (CC0), GBIF
  sampling-event datasets and the Breeding Bird Survey add a few very large
  structured sources. See `discovery_summary.md` and `discovery_log.csv`.

## Scale

- **Seed corpus (weeks):** 50–100 tables from R packages, ScienceBase, EDI and
  the cleanest Dryad deposits.
- **Harvested corpus (months, with a Dryad→Zenodo harvester and a journal
  supplement sweep):** several hundred to ~1,000 tables, most with 20–300 units
  and 2–12 occasions — a corpus of *small* tables, which is where the IRW floor
  of 100 ids would exclude most of ecology.
- **Big integrations (each a project):** BBS, NEON, GBIF sampling-event
  datasets, eBird (gated) — a handful of tables with 10⁵–10⁷ rows that would
  dominate by volume.

## The five decisions that are Ben's to make

1. **What is `taxon`?** The draft puts the *species* on `taxon`, so single-species
   tables look like IRW's repeated-trial family (one item, many occasions) and
   community tables are species-as-items. The alternative — visit on `taxon` —
   makes every table a person × item matrix an IRT model can eat directly, but
   does not generalise to multi-species data. It is a one-line pivot either way;
   the choice is about what the canonical corpus looks like.
2. **Dense zeros or a surveys table?** The explicit-zero rule (a row exists iff a
   survey happened; missing row ≠ zero) makes community tables large (MHB2014:
   118,658 rows, 95% zeros, 7.6 MB from a 267 × 3 × 158 array) and repeats
   observation covariates across species. The alternative is Darwin Core's
   event-core model: a sparse detections table plus a `surveys` table. The draft
   recommends dense for IRW-likeness and self-containment.
3. **Sample floor.** *Settled 2026-11-01:* a reported attribute, not an intake
   gate. `sample_floor` is `meets` (≥ 30 units and ≥ 2 occasions, or ≥ 2 periods
   for capture–recapture) or `below (reason)`, and users filter on it. Small
   tables are not sought out, but they ship when they come.
4. **Sensitive-species coordinates.** Coarsen by rule (draft: 0.1° / 10 km grid,
   with `coordinateUncertaintyInMeters` set) versus drop coordinates for any
   flagged taxon. Several small Dryad/Zenodo deposits of threatened species carry
   raw lat/long.
5. **How far to stretch.** Multinomial (double-observer) and binned distance
   sampling fit by using `occasion` for a *category* rather than a time-ordered
   replicate; SCR fits by putting *traps* on `taxon`. Accept the stretched
   semantics with a declared `itemKind`/`responseType`, or keep v1 to the
   detection/count/capture-history families where the format is unforced.

## Nomenclature (v0.3, 2026-10-31)

The IRW's `id`/`item`/`resp` were kept through v0.2 to show the tables validate
under IRW v1.0 unchanged. From v0.3 the standard uses local names and keeps IRW
conformance as a *view*:

| eco | IRW | meaning |
|---|---|---|
| `unit` | `id` | the thing with the latent state: a site, or an individual animal |
| `taxon` | `item` | the species probed for |
| `y` | `resp` | the observation: 0/1, count, or state code |
| `y_raw`, `observer` | `resp_raw`, `rater` | |
| `unit_*`, `period_*`, `obs_*`, `taxon_*` | `cov_*`, `periodcov_*`, (none), `itemcov_*` | covariate at the level where it is constant |
| `trap` | (none) | SCR trap index; `__traps` side table |
| `date` ISO 8601 | `date` Unix seconds | |
| `__taxa`, `__periods`, `__units`, `__traps` | item text | side tables, typed by key column |

`eco_to_irw()` in `converters/eco_standard.R` produces the IRW view; the validator
and the uploader run `irw-validate` on it.

## Worked tables (2026-10-31)

Six public deposits were run through an IRW-style pipeline (one processing
script per source, a dictionary row, a tags row, a clean CSV plus side tables),
to see the standard meet real deposits rather than package data. All six pass
the draft validator and `irw-validate` (IRW v1.0 upload gate; the only warnings
are IRW's own 100-id floor and the `obs_` prefix it does not know).

| Table | Family | Units x items x periods x occasions | Rows | Source, licence |
|---|---|---|---|---|
| `malhotra_2021_loslagos_comm` | community occupancy (camera traps) | 48 x 4 x 1 x 11 | 1,944 | Dryad, CC0 |
| `schank_2015_tapir_occ` | single-season occupancy; coordinates coarsened | 22 x 1 x 1 x 72 | 1,008 | Zenodo, CC0 |
| `toledolima_2024_elaenia_cjs` | CJS from a MARK `.inp`, 4 losses on capture | 175 x 1 x 9 x 1 | 1,559 | Zenodo, CC BY 4.0 |
| `palacio_2020_pampasbirds_comm` | multi-season community occupancy, 19 traits | 10 x 43 x 4 x 5 | 8,600 | Dryad, CC0 |
| `frimpong_2017_newriver_dynocc` | multi-species dynamic occupancy, 1938-2014, effort | 100 x 74 x 25 x 3 | 74,592 | Harvard Dataverse, CC0 |
| `uherkoch_2021_npraloon_dynocc` | multi-state (breeding status) dynamic occupancy | 117 x 2 x 4 x 1 | 886 | USGS ScienceBase, CC0 |

What the real deposits added to the round-trip findings:

- **The explicit-zero rule was never ambiguous**: every deposit used `NA`/blank
  for "not surveyed" and 0 for "not detected", and in two of them the survey
  pattern could be cross-checked against an effort table (fish: blank iff
  effort 0; tapir: filled cells = effort + 1 or 2 days).
- **Two tables fall below the 30-unit floor** (tapir, 22 cameras; Argentine
  birds, 10 points). They were staged as `hold` until the floor was ruled a
  filterable attribute rather than an intake rule (decision 3); both now ship
  with `sample_floor = below (...)`. The bird table is why: 10 sites but 43
  species x 20 surveys each, so a unit floor measures the wrong axis for
  community data.
- **Coarsening was needed once** (Endangered tapir, exact camera coordinates
  deposited) and exercised the section 6 rule; the loon table keeps coordinates
  as the USGS published them (decision 4).
- **Multi-state data fit with `y` = species-specific state and `y_raw` =
  source code**; a territory held by one loon species is a 0 for the other.
  Suggests adding `state` to the section 10 type suffixes.
- **Losses on capture** (MARK `freq = -1`) exercised the `obs_removed`
  encoding, which the round trips had not.
- **A model output posing as a covariate** (Malhotra's dog-occupancy estimate)
  is the ecological version of IRW's composite-score rule and was dropped.

## Contents

| Path | What |
|------|------|
| `standard_draft.md` | The proposed standard: core table, mapping tables per model family, missingness rule, side tables (Darwin Core / EML borrowings), scope, what is lost, open questions, changelog |
| `converters/eco_standard.R` | R converters: array ↔ long, `unmarked` frames ↔ long, multinomial frames, capture histories; validator; writer |
| `converters/rt_0*_*.R`, `run_all.R` | Round-trip tests for six datasets; `converters/output/` holds the converted tables and `roundtrip_results.csv` |
| `roundtrip_report.md` | What matched, what did not, what changed in the standard |
| `discovery/eco_discover.py` | Repository search (connectors adapted from `ben-domingue/irw`), with cached responses in `discovery/cache/` |
| `data/*.R`, `data/run_all.R` | One processing script per public deposit (download, reshape, validate, stage rows); see `data/README.md` |
| `lib/eco_common.R` | Shared harness: cached downloads, GBIF taxon lookup, coordinate coarsening, `write_table()`, dictionary and tag staging |
| `converters/eco_standard.R` → `eco_to_irw()` | The IRW view (id/item/resp names, Unix-second dates) that `irw-validate` and the uploader check |
| `output/` | Clean CSV per table plus `__taxa.csv`, `__periods.csv`, `__dataset.json` side files |
| `dictionary/dictionary_auto.csv` | Data-Dictionary rows (eco header; see `dictionary/README.md`) |
| `tags/tags_auto.csv`, `tags/vocab.md` | Filter tags per table and their vocabulary |
| `validate/validate_all.R`, `validate/report.csv` | Draft validator + `irw-validate` over every output |
| `upload/red_up_eco.py` | Ships `output/` to Redivis `datapages.eco` (reference `eco:4j5q`) with IRW's `red_up`: true replace, row counts verified, descriptions from `__dataset.json`; draft only |
| `queue/candidates.csv` | Inspected deposits collaborators can claim (`available` / `claimed` / `built`) |
| `analysis/*.R`, `analysis/build_report.py` | The illustrative figures and the assembly of `report.html` from the repo's own files |
| `discovery_log.csv`, `discovery_summary.md` | Per-source hit counts, curated candidates with difficulty scores, and the narrative |

To rebuild the tables: `Rscript data/run_all.R && Rscript validate/validate_all.R` (from the repo root; needs `data.table`, `jsonlite`, network access for the first run, and the `ben-domingue/irw` checkout at `~/Dropbox/projects/irw/src` or `IRW_SRC` for the IRW check).

To rerun the round-trip tests: `cd converters && Rscript run_all.R` (needs `unmarked`,
`AHMbook`, `marked`, `nimble`, `nimbleEcology`, `data.table`, `jsonlite`).
