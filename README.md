# eco — an IRW-style warehouse for ecological detection data?

*Exploratory project, started 2026-10-30. As of 2026-11-01: 30 tables from 20
public deposits and 6 package datasets, built by one script each, validated
against standard v1.0-draft, and released on Redivis as `datapages.eco` (eco v2).
The standard is a draft and may change between releases; released versions do not.*

*Website: <https://ben-domingue.github.io/eco/> (source in `site/`, rendered by
`.github/workflows/site.yml`; preview locally with `cd site && quarto preview`).*

## The question

The IRW harmonises item-response data into one long-format table (`id`, `item`,
`resp`) so psychometric methods can be benchmarked at scale. Could the same move
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
  random-item IRT model with species as items. See `standard.md` (v1.1-draft, the
  normative clauses) and `standard_draft.md` (the reasoning).
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

## The design decisions, and how they were ruled

All five were ruled on 2026-11-01 (the ruling follows each item; `standard.md`
is the normative text). Two later rulings, on a fourth nesting level
(`unit_<group>` covariate) and on confirmation surveys (`detectionCertainty`),
are in E9 of the standard.

1. **What is `taxon`?** The draft puts the *species* on `taxon`, so single-species
   tables look like IRW's repeated-trial family (one item, many occasions) and
   community tables are species-as-items. The alternative — visit on `taxon` —
   makes every table a person × item matrix an IRT model can eat directly, but
   does not generalise to multi-species data. *Ruled: species on `taxon`; the
   visit view is a derived pivot.*
2. **Dense zeros or a surveys table?** The explicit-zero rule (a row exists iff a
   survey happened; missing row ≠ zero) makes community tables large (MHB2014:
   118,658 rows, 95% zeros, 7.6 MB from a 267 × 3 × 158 array) and repeats
   observation covariates across species. The alternative is Darwin Core's
   event-core model: a sparse detections table plus a `surveys` table. *Ruled:
   dense, and every table declares what its survey set rests on
   (`surveyEvidence`: a deposited matrix, an effort table, a sample table, row
   presence, or a stated inference rule).*
3. **Sample floor.** *Settled 2026-11-01:* a reported attribute, not an intake
   gate. `sample_floor` is `meets` (≥ 30 units and ≥ 2 occasions, or ≥ 2 periods
   for capture–recapture) or `below (reason)`, and users filter on it. Five of
   the 30 tables are below it. Small tables are not sought out, but they ship
   when they come.
4. **Sensitive-species coordinates.** Coarsen by rule (draft: 0.1° / 10 km grid,
   with `coordinateUncertaintyInMeters` set) versus drop coordinates for any
   flagged taxon. *Ruled: coarsen, never drop; a taxon is flagged by the source,
   by IUCN CR/EN/VU, or by a cited national red list. Needed twice so far.*
5. **How far to stretch.** Multinomial (double-observer) and binned distance
   sampling fit by using `occasion` for a *category* rather than a time-ordered
   replicate; SCR fits by putting *traps* on `taxon`. Accept the stretched
   semantics with a declared `itemKind`/`responseType`, or keep v1 to the
   detection/count/capture-history families where the format is unforced.
   *Ruled: three lists. Removal, double-observer and binned distance sampling
   are in as declared stretches with their metadata required; SCR (with a
   `trap` key and `__traps`, not traps on `taxon`), multi-scale and
   per-detection designs are experimental and may be restructured.*

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
| `trap` | folded into `item` as `taxon:trap` | SCR trap index; `__traps` side table; IRW has no trap key, so traps become items in the view |
| `date` ISO 8601 | `date` Unix seconds | |
| `__taxa`, `__periods`, `__units`, `__traps` | item text | side tables, typed by key column |

`eco_to_irw()` (in `Rpkg/R/convert.R` and `eco_validate/core.py`) produces the IRW
view; `eco-validate --irw` and the uploader run `irw-validate` on it.

## The corpus (2026-11-01)

30 core tables, 1.18 million survey observations, 4,538 units, 14 model families,
every one passing `eco-validate` and `irw-validate` (the only IRW warnings are its
100-id floor and the `obs_` prefix it does not know). The live list, with
dimensions, licence, survey evidence and a link to each script, is the site's
[Data page](https://ben-domingue.github.io/eco/data.html); the numbers here come
from `metadata/status.json`.

| Family | Tables |
|---|---|
| Community occupancy (incl. multi-season) | 7 |
| Single-season occupancy | 3 |
| Dynamic occupancy (single and multi-species) | 3 |
| N-mixture | 3 |
| Multinomial N-mixture (removal, double-observer) | 2 |
| Distance sampling | 2 |
| CJS capture-recapture | 2 |
| Spatial capture-recapture | 2 |
| Community abundance; multi-state dynamic occupancy; dynamic co-occurrence; ordinal index | 1 each |
| Multi-scale occupancy, eDNA (one with false positives) | 2 |

Sources: Dryad (12, two of them via its Zenodo mirror), figshare (4), USGS ScienceBase (3),
Zenodo (3), Harvard Dataverse and DataverseNO (1 each), and the `unmarked`,
`AHMbook` and `marked` packages (6). Licences: 18 CC0, 5 CC BY 4.0, 1 ODbL, 6 GPL
(the package datasets). Protocols: camera traps, line transects, point counts,
visual encounter surveys, live traps, eDNA, mist nets, acoustic, aerial
double-observer, and one 77-year compilation of fish collections.

What building 30 tables established, beyond the round trips:

- **The explicit-zero rule is unambiguous when a matrix was deposited** (17
  tables) and checkable against an effort or sample table (7 more). Record
  tables with no survey list are the hard case: 3 tables take each deposited
  row as a survey, and 3 reconstruct the survey set by a stated rule and ship
  as `surveyEvidence = inferred`.
- **The sample floor measures the wrong axis for community data**: the table
  with 10 points has 43 species and 20 surveys each. Hence a reported attribute,
  not a gate.
- **Coarsening was needed twice** (an Endangered tapir with exact camera
  coordinates; a bird community including Vulnerable taxa). Agency-published
  coordinates are kept as published.
- **The stretches fit**: distance bins, observer cells and removal intervals on
  `occasion` with the binning declared in the metadata; SCR with a `trap` key;
  eDNA with site, sample and qPCR replicate as `cluster_id`, `unit`, `occasion`
  and the watershed as a `unit_` covariate.
- **Model outputs posing as covariates** turn up and are dropped and logged
  (`notShipped`), the ecological version of IRW's composite-score rule.
- **Textbook datasets round-trip through the public pipeline too**: the six
  Phase 2 datasets are now ordinary tables, built by scripts under `data/`.

## Contents

| Path | What |
|------|------|
| `CLAUDE.md`, `ARCHITECTURE.md`, `PRIORITIES.md`, `processing_guide.md`, `.claude/skills/eco-convert-deposit/` | Agent-facing docs (issue #9): how to run things and which document wins; the project map; what kind of work to do next; the deposit-conversion checklist; the step order a session follows for one queue row |
| `standard.md` | **The standard**, v1.1-draft: clauses E1-E10, intake policy, changelog |
| `standard_draft.md` | History of the standard: core table, mapping tables per model family, missingness rule, side tables (Darwin Core / EML borrowings), scope, what is lost, open questions, changelog |
| `Rpkg/` | **The R package `eco`**: `eco_list_tables()`, `eco_filter()`, `eco_fetch()`, `eco_to_unmarked()`, `eco_set_version()`, over Redivis' anonymous CSV endpoint; no login. `remotes::install_github("ben-domingue/eco", subdir = "Rpkg")` |
| `converters/eco_standard.R` | Shim over `Rpkg/R/convert.R`: array ↔ long, `unmarked` frames ↔ long, multinomial frames, capture histories; validator twin; writer |
| `converters/rt_0*_*.R`, `run_all.R` | Round-trip tests for six datasets; `converters/output/` holds the converted tables and `roundtrip_results.csv` |
| `roundtrip_report.md` | What matched, what did not, what changed in the standard |
| `discovery/eco_discover.py` | Repository search (connectors adapted from `ben-domingue/irw`), with cached responses in `discovery/cache/` |
| `data/*.R`, `data/run_all.R` | One processing script per public deposit (download, reshape, validate, stage rows); see `data/README.md` |
| `lib/eco_common.R` | Shared harness: cached downloads, GBIF taxon lookup, coordinate coarsening, `write_table()`, dictionary and tag staging |
| `eco_validate/` | **The validator**: `eco-validate`, one pandas package with clause ids (E1-E10), intake profile, `--irw` for the IRW view, exit codes, `--json`; gates the uploader; `pytest eco_validate/tests` |
| `Rpkg/R/convert.R` → `eco_to_irw()` | The IRW view (id/item/resp names, Unix-second dates) that `irw-validate` checks; mirrored in `eco_validate.eco_to_irw` |
| `output/` | Build area: `data/<table>.R` writes the table CSV and its side tables here for upload; only `<table>__dataset.json` is tracked (the tables live on Redivis, #88) |
| `metadata/` | `run_pipeline.sh` builds `metadata.csv`, `biblio.csv`, `tags.csv`, `status.json` from `output/*__dataset.json`, `dictionary/`, `tags/`; the site and the R package read these |
| `releases/` | The release ledger: `manifest.csv` (eco version ↔ Redivis versions), `table_changes.csv` (corrections), `data_notes.csv` (caveats about sources) |
| `site/` | The Quarto website, rendered by GitHub Pages on push |
| `dictionary/dictionary_auto.csv` | Data-Dictionary rows (eco header; see `dictionary/README.md`) |
| `tags/tags_auto.csv`, `tags/vocab.md` | Filter tags per table and their vocabulary |
| `validate/report.csv`, `validate/validate_redivis.py` | One eco-validate verdict per table, the report the site reads; written by the uploader and by a scheduled re-validation of the tables on Redivis |
| `upload/red_up_eco.py` | Ships `output/` to Redivis `datapages.eco` (reference `eco:4j5q`) with IRW's `red_up`: true replace, row counts verified, descriptions from `__dataset.json`; draft only |
| `queue/candidates.csv` | Inspected deposits collaborators can claim (`available` / `claimed` / `built` / held with a reason) |
| `analysis/*.R`, `analysis/build_report.py` | The illustrative figures and the assembly of `report.html` from the repo's own files |
| `discovery_log.csv`, `discovery_summary.md` | Per-source hit counts, curated candidates with difficulty scores, and the narrative |

The tables are on Redivis; read them with the R package (`eco_fetch()`). To rebuild one from source: `Rscript data/<table>.R` (from the repo root; needs `data.table`, `jsonlite`, and network access for the first run), then `python3 -m eco_validate.cli output/<table>.csv --irw` (python3 with pandas, and `irw-validate` installed or the `ben-domingue/irw` checkout at `~/Dropbox/projects/irw/src` or `IRW_SRC`).

To rerun the round-trip tests: `cd converters && Rscript run_all.R` (needs `unmarked`,
`AHMbook`, `marked`, `nimble`, `nimbleEcology`, `data.table`, `jsonlite`).
