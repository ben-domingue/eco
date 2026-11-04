# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

## What this is

**eco** is an IRW-style warehouse for ecological detection data: occupancy, repeated
counts, capture histories and community surveys, one long table per deposit, with
`unit`, `taxon`, `y` where IRW has `id`, `item`, `resp`. Tables are built by agents,
one R script per source deposit, validated by `eco-validate`, and shipped to the
Redivis dataset `datapages.eco` as an unreleased draft that a human publishes.

**Start with [`ARCHITECTURE.md`](ARCHITECTURE.md)**: what owns what, and which
document wins when two disagree. **Before building a table read
[`processing_guide.md`](processing_guide.md)**, and follow the skill
`.claude/skills/eco-convert-deposit/SKILL.md` for the step order. **Before choosing
what kind of work to do, read [`PRIORITIES.md`](PRIORITIES.md).**

## Running things

Everything runs from the repo root.

```bash
Rscript data/<table>.R                       # build one table (download cached in .cache/raw/<table>/)
Rscript data/run_all.R                       # rebuild every table
python3 -m eco_validate.cli output/          # the gate: every core table, clause ids, exit 0/1/2
python3 -m eco_validate.cli output/<table>.csv -v --irw   # one table, every affected case, plus the IRW view
python3 -m pytest eco_validate/tests -q      # validator tests; the corpus test covers every table in output/
python3 tools/check_coverage.py             # every core table has __taxa, __dataset.json, dictionary, tags and metadata rows (CI runs this)
python3 tools/check_prose_numbers.py --strict   # a count in a title/description near but not equal to n_units/n_periods/n_taxa (CI runs this)
Rscript validate/validate_all.R              # eco-validate --irw over output/, writes validate/report.csv (the site reads it)
metadata/run_pipeline.sh                     # metadata.csv, biblio.csv, tags.csv, status.json from output/, dictionary/, tags/
python3 metadata/upload_meta.py --dry-run    # ship those three to Redivis eco_meta (draft)
python3 releases/manifest.py --check         # is releases/manifest.csv up to date with Redivis? (run after Ben publishes)
python3 upload/red_up_eco.py --dry-run       # what would ship; never publishes
python3 upload/red_up_eco.py                 # upload to the Redivis draft (confirms first)
cd site && quarto render                     # the website (GitHub Pages builds it on push)
R CMD INSTALL Rpkg && Rscript -e 'library(eco); testthat::test_dir("Rpkg/tests/testthat")'   # the R package (reads Redivis anonymously)
```

Needs R with `data.table` and `jsonlite` (plus `readxl` for xlsx deposits), python3 with `pandas`, and for the IRW
view check the `ben-domingue/irw` checkout at `~/Dropbox/projects/irw/src` or
`$IRW_SRC`. The uploader also needs IRW's `red_up` importable and a Redivis token.

Nothing in this repo publishes. `red_up_eco.py` writes a draft; releasing is Ben's
click on Redivis, followed by the checklist in `upload/README.md` (manifest row,
table_changes row if a published table changed).

## The format, quick reference

The standard is [`standard.md`](standard.md) (v1.1-draft, clauses E1 to E10 plus
intake policy). `eco-validate` reports every finding against a clause. This table is
a reminder, not the rule.

| Column | Required | Meaning |
|---|---|---|
| `unit` | yes | the thing with the latent state: a site, camera, pond, transect, or an individual animal |
| `taxon` | yes | short stable species code; resolved in `__taxa` |
| `y` | yes | the observation, numeric, meaning set by `responseType` (detection 0/1, count, state, ordinal, multinomial_cell, detection_event) |
| `y_raw` | no | the recorded value behind a recode |
| `trap` | SCR | trap key, with `__traps` |
| `period` | conditional | primary period (season, year, session), integer ordered in time; needs `__periods` |
| `occasion` | conditional | replicate survey within a period, integer |
| `date` | no | ISO 8601 per row; never a bare year or day-of-year |
| `observer`, `treat`, `cluster_id` | no | observer id; 1/0 manipulation; design grouping above `unit` |
| `unit_*`, `period_*`, `obs_*`, `taxon_*` | no | covariates, prefixed by the level at which they are constant (E5) |

Key: `(unit, taxon, trap, period, occasion)`. **A row exists iff a survey happened**;
`y = 0` is surveyed and not detected; a missing row is not surveyed; `y` is never NA
(E4). Community tables carry a row for every taxon surveyed for at every survey. Side tables share
the name plus `__taxa` (required), `__periods`, `__units`, `__traps`, `__survey_taxa`; metadata is
`<table>__dataset.json` (E10), which must say what the survey set rests on
(`surveyEvidence`).

## Conventions for `data/` scripts

- **The script is the processing record.** Its header states the source, licence
  (as shown on the source page), paper, the files as deposited, the mapping onto
  the standard, the survey-evidence rule, and what was not shipped and why.
- **Assertions, not comments, for facts about the source**: row counts, value sets,
  that the NA pattern is identical across species, that effort > 0 exactly where a
  survey exists. A re-download that changes the source fails loudly.
- **Model outputs are not covariates or `y`.** An occupancy estimate or predicted
  density the authors derived from the same detections is dropped and recorded in
  `notShipped`.
- **Coordinates never finer than the source.** Flagged taxa (source says so, IUCN
  CR/EN/VU in its native range, cited red list) with coordinates finer than 0.1 degree are coarsened
  with `coarsen_coords()`, and `coordinatesCoarsened` says how. Agency-published
  coordinates are kept as published.
- **Species codes on `taxon`**, scientific name and GBIF key in `__taxa` via
  `make_taxa()`; period-level facts in `__periods`.
- **One table per survey design x response type.** Name
  `author_year_taxonOrPlace_type`, lower case, 40 characters or fewer.
- Every script ends with `write_table()`, `stage_dict_row()` and `stage_tag_row()`
  from `lib/eco_common.R`. After a batch, run `metadata/run_pipeline.sh` and commit
  `metadata/` too: the site reads it, not `tags/` or `dictionary/`. `write_table()` runs the R twin of the validator and
  refuses a bad table; the Python gate is the authority.
- The converters (`array_to_eco()`, `ch_to_eco()`, `eco_to_irw()`, `eco_check()`, ...) live
  in `Rpkg/R/convert.R`; `converters/eco_standard.R` only sources that file. A change
  there changes the installed package too: run its tests.
- Scripts are self-contained apart from `lib/eco_common.R`. The table name is the
  script name: `data/<table>.R` builds `output/<table>.csv`; there is no separate
  table-to-script map.
- Reference issues in commit messages (`#10`). Commit only the files you changed;
  other sessions may be building batches in the same tree.

## Which document wins

`standard.md` > `eco-validate`'s finding > `processing_guide.md` > this file >
`README.md` and the per-directory READMEs. When the validator and the standard
disagree, the standard is right and the validator has a bug: file it, do not
work around it. Full precedence table in `ARCHITECTURE.md`.
