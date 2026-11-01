---
name: eco-convert-deposit
description: Use when asked to build an eco table from a public ecological deposit, "process the queue", "convert this Dryad/Zenodo/USGS/figshare dataset", "run the next batch", or otherwise turn a row of queue/candidates.csv into a validated table in output/ with its dictionary row, tags row and __dataset.json. Also use when reviewing a data/ script someone else wrote.
---

# Convert a deposit into an eco table

Orchestration for one `queue/candidates.csv` row, or a batch of them. The format
is `standard.md` (E1 to E10); judgement calls are in `processing_guide.md`; this file
is the step order and the rules that must not be skipped. Work from the repo root.
Read `CLAUDE.md` once per session.

## Hard rules

1. **Licence first, verified on the source page.** No licence, unresolvable, ND, or
   scraped third-party data: hold, do not write a script. The stricter of two
   conflicting licences governs.
2. **Explicit zeros come from evidence.** Decide `surveyEvidence` before reshaping.
   If the survey set cannot be recovered, the deposit is not buildable as a core
   table.
3. **Model outputs are not shipped** as `y` or as covariates; record them in
   `notShipped`.
4. **Coordinates never finer than the source**; flagged taxa are coarsened.
5. **Assertions, not comments**, for every fact about the source the script relies on.
6. **The gate is `eco-validate`.** A table that fails it does not ship, and the
   validator is not edited to make it pass. If a check is wrong, stop and say so.
7. **Commit only your own files.** Other sessions may be working in the same tree.
   Never push to `ben-domingue/irw`. Never publish on Redivis; upload to the draft.

## Step 0. Pick the row

`queue/candidates.csv`, `status = available`. Prefer, in order: a design or
response type the corpus lacks (`design_landscape.md`, "Built or round-tripped?"
column), a deposit with a sample or effort table, an open licence, resolvable taxa.
Put your session or initials in `claimed_by` while working, so another session does
not start the same deposit. If the request names a deposit not in the queue, add the row first.

## Step 1. Intake (no code yet)

Open the source page. Record, for the script header: licence as displayed, version
and date of the deposit, paper citation and DOI, the list of deposited files and
what each holds, the survey design (units, occasions, periods, species), and how
the survey set is evidenced. Check the dictionary for a duplicate by DOI. Check
E9 scope. Decide the table name.

If any of these fails: add a row to `queue/human_review.csv`
(`candidate, source, doi_or_url, decision, reason, date, reviewer`), set the queue
row to `held: <reason>` or `blocked: <reason>`, and go to the next row.

## Step 2. Download and read everything

```r
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "<author_year_place_type>"
dir <- download_dryad("<doi>", TABLE)            # or download_cached(url, TABLE, filename)
stopifnot(identical(attr(dir, "license"), "<spdx url>"))
```

Read every deposited file. Write down what each column is before mapping. Find the
survey set (sample table, effort table, NA pattern, row presence) and the species
code list.

## Step 3. Write `data/<table>.R`

Header comment: `# Table:`, `# Source:` (repository, DOI, licence, version),
`# Paper:`, `# Data:` (files as deposited and what they contain, including the
quirks), `# Mapping:` (unit, taxon, period, occasion, y, each covariate's level,
the survey-evidence rule, what is not shipped and why). Copy the shape from an
existing script of the same family (`data/README.md` lists them by family):
`hamer_2024_hungary_amph_comm.R` for a deposited matrix, `galvez_2021_araucania_comm.R`
for an effort table, `glorioso_2025_atchafalaya_ves.R` for a sample table,
`mctigue_2023_nwarkansas_comm.R` for an inferred survey set,
`toledolima_2024_elaenia_cjs.R` for capture histories,
`margenau_2021_rowsongbirds_nmix.R` for counts built from individual records.

Body, in order: read and assert the source; build `y` (array or long) and the
covariates at their levels; convert with `array_to_eco()` or the family's
converter; assert the row count against the survey set and the species count;
`make_taxa()`; `__periods` if `period` exists; the `dataset` list (every E10 field,
`surveyEvidence` and, when `inferred`, `surveyEvidenceNote`; `coordinatesCoarsened`
whenever coordinates exist; `notShipped`); then

```r
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/<table>.R")
stage_dict_row(TABLE, description = ..., url = ..., reference = ..., doi_paper = ..., doi_data = ...,
               original_license = ..., derived_license = ..., notes = ..., source_via = ...)
stage_tag_row(TABLE, ds, taxon_group = ..., model_family = ..., sampling_protocol = ..., design = ...,
              realm = ..., country = ..., coordinates = ..., notes = ..., status = "tagged")
```

`write_table()` refuses a table the R validator twin rejects; fix the script, not
the harness.

## Step 4. Run and gate

```bash
Rscript data/<table>.R
python3 -m eco_validate.cli output/<table>.csv -v --irw
python3 -m pytest eco_validate/tests -q
```

Exit 0 on the validator and all tests passing are required. Read every warning: a
`survey_evidence` warning is expected for `inferred`; a `sample_floor` warning is a
fact to carry into the batch log; a `column_order` warning means the converter was
bypassed, look at why. Then read `output/<table>__dataset.json` against the paper's
reported design.

## Step 5. Record

- `queue/candidates.csv`: `status = built: <table>` (several tables from one
  deposit: list them).
- `BATCH_LOG.md`: a row in the batch's table (family, source, rows, notes) and, under
  the batch, what was held and anything that strained the standard. If a deposit
  needed a rule the standard does not state, say so there and open an issue; do not
  settle it in the script.
- `data/README.md`: a row in "Tables built so far".

## Step 6. Ship

```bash
Rscript validate/validate_all.R           # corpus report; the site reads it
python3 upload/red_up_eco.py --dry-run    # every new table CORE/SIDE, nothing SKIP
python3 upload/red_up_eco.py              # to the draft; confirms first
```

Commit the script, its outputs, the dictionary and tags rows, the queue, the batch
log, `data/README.md` and `validate/report.csv`, with the issue number (`#10`).
Pull before pushing. Tell Ben the draft is ready to release; never release it.

## When to stop and ask

A licence that fits none of the intake rules; a design not in E9's lists; a
deposit whose zeros cannot be evidenced; a flagged taxon where the coarsening
rule and the source's own publication conflict; a validator check you believe is
wrong; anything that would change `standard.md`, `lib/`, `converters/`,
`eco_validate/` or `upload/`. Hold the deposit, write the reason in
`queue/human_review.csv`, and continue with the next row.
