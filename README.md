# eco — an IRW-style warehouse for ecological detection data?

*Exploratory study, 2026-10-30. Everything here is a draft for Ben to react to;
nothing is production.*

## The question

The IRW harmonises item-response data into one long-format table (`id`, `item`,
`resp`) so psychometric methods can be benchmarked at scale. Could the same move
work for the hierarchical ecological models fit with NIMBLE — occupancy,
N-mixture, capture–recapture, community models — where a site or animal has a
latent state observed imperfectly across repeated surveys?

## Short answer: yes, and more cheaply than for psychology

- **The structure maps.** `id` = the unit carrying the latent state (site or
  individual), `item` = the taxon probed for, `resp` = detection / count,
  `period` + `occasion` = primary / secondary survey indices (both already legal
  IRW C5 occasion columns), covariates prefixed by the level at which they are
  constant (`cov_`, `periodcov_`, `obs_`, `itemcov_` — exactly `unmarked`'s
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

1. **What is `item`?** The draft puts the *species* on `item`, so single-species
   tables look like IRW's repeated-trial family (one item, many occasions) and
   community tables are species-as-items. The alternative — visit on `item` —
   makes every table a person × item matrix an IRT model can eat directly, but
   does not generalise to multi-species data. It is a one-line pivot either way;
   the choice is about what the canonical corpus looks like.
2. **Dense zeros or a surveys table?** The explicit-zero rule (a row exists iff a
   survey happened; missing row ≠ zero) makes community tables large (MHB2014:
   118,658 rows, 95% zeros, 7.6 MB from a 267 × 3 × 158 array) and repeats
   observation covariates across species. The alternative is Darwin Core's
   event-core model: a sparse detections table plus a `surveys` table. The draft
   recommends dense for IRW-likeness and self-containment.
3. **Sample floor.** 100 ids is wrong for ecology; the draft proposes ≥ 30 units
   and ≥ 2 occasions (or ≥ 2 periods for capture–recapture).
4. **Sensitive-species coordinates.** Coarsen by rule (draft: 0.1° / 10 km grid,
   with `coordinateUncertaintyInMeters` set) versus drop coordinates for any
   flagged taxon. Several small Dryad/Zenodo deposits of threatened species carry
   raw lat/long.
5. **How far to stretch.** Multinomial (double-observer) and binned distance
   sampling fit by using `occasion` for a *category* rather than a time-ordered
   replicate; SCR fits by putting *traps* on `item`. Accept the stretched
   semantics with a declared `itemKind`/`responseType`, or keep v1 to the
   detection/count/capture-history families where the format is unforced.

## Contents

| Path | What |
|------|------|
| `standard_draft.md` | The proposed standard: core table, mapping tables per model family, missingness rule, side tables (Darwin Core / EML borrowings), scope, what is lost, open questions, changelog |
| `converters/eco_standard.R` | R converters: array ↔ long, `unmarked` frames ↔ long, multinomial frames, capture histories; validator; writer |
| `converters/rt_0*_*.R`, `run_all.R` | Round-trip tests for six datasets; `converters/output/` holds the converted tables and `roundtrip_results.csv` |
| `roundtrip_report.md` | What matched, what did not, what changed in the standard |
| `discovery/eco_discover.py` | Repository search (connectors adapted from `ben-domingue/irw`), with cached responses in `discovery/cache/` |
| `discovery_log.csv`, `discovery_summary.md` | Per-source hit counts, curated candidates with difficulty scores, and the narrative |

To rerun the tests: `cd converters && Rscript run_all.R` (needs `unmarked`,
`AHMbook`, `marked`, `nimble`, `nimbleEcology`, `data.table`, `jsonlite`).
