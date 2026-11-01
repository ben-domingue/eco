# eco: project map

What owns what, where each fact lives, and which document wins. Modelled on
`ben-domingue/irw`'s `src/ARCHITECTURE.md`, scaled to a corpus of a few dozen tables.

## 1. One repository

`ben-domingue/eco` holds everything: the standard, the processing scripts, the
validator, the staged metadata, the uploader and the website. IRW split these over
four repositories because it has three client packages and a thousand-table
pipeline; eco does not, and one repo means one place to look.

| Directory | Owns |
|---|---|
| `standard.md` | **The format.** v1.0-draft, clauses E1 to E10, intake policy, changelog. `standard_draft.md` is its history and `design_landscape.md` the checklist of study designs behind E9. |
| `data/` | One R script per source deposit, `<table>.R`; the processing record. `data/aux/` holds shared lookups. `data/README.md` lists the tables built. |
| `lib/eco_common.R` | The build harness: cached downloads (`download_cached`, `download_dryad`), GBIF matching (`gbif_taxon`, `make_taxa`), `coarsen_coords`, `write_table` (runs the R validator twin, writes the CSV, side tables and `__dataset.json`), `stage_dict_row`, `stage_tag_row`. |
| `Rpkg/` | **The R package `eco`** (#7): list / filter / fetch over Redivis' anonymous CSV endpoint, version pinning through `releases/manifest.csv`, a disk cache, and the converters (`R/convert.R`: array, `unmarked`-frame and capture-history converters to and from the long format; `eco_check()`, the R validator twin; `eco_to_irw()`, the IRW view). Installed with `remotes::install_github("ben-domingue/eco", subdir = "Rpkg")`; tests in `tests/testthat`. |
| `converters/eco_standard.R` | A shim: sources `Rpkg/R/convert.R` so the build scripts share the package's converters without installing it, and keeps `validate_eco` as an alias of `eco_check`. `converters/rt_*.R` are the round-trip tests. |
| `eco_validate/` | **The validator.** `eco-validate`, pandas only, clause ids, intake profile, `--irw`, exit codes; `tests/`. Installable as a package. |
| `output/` | The built tables: `<table>.csv`, `<table>__taxa.csv`, `__periods`, `__units`, `__traps`, `<table>__dataset.json`. What gets uploaded. |
| `dictionary/dictionary_auto.csv` | One description / origin / licence row per table (`stage_dict_row`). The biblio. |
| `tags/tags_auto.csv`, `tags/tags_human.csv`, `tags/vocab.md` | One row of filterable attributes per table: automated (`stage_tag_row`, rater `claude-auto`) and human (initials); `status` carries `do_not_publish`. The vocabulary. |
| `metadata/` | **The metadata pipeline**: numbered stages, `run_pipeline.sh` is the run order. `metadata.csv` (computed from `output/`), `biblio.csv` (dictionary + `__dataset.json`), `tags.csv` (auto with human cells winning, vocabulary enforced), `status.json` + `status_history.tsv`. What the site reads; `upload_meta.py` ships them to `eco_meta`. |
| `validate/` | `validate_all.R` runs `eco-validate --irw --json` over `output/` and writes `report.csv`, which the site reads. |
| `upload/red_up_eco.py` | The one uploader, a wrapper on IRW's `red_up`: eco-validate gate, true replace, row counts verified, descriptions from `__dataset.json`, refuses `do_not_publish`. Draft only. |
| `releases/` | **The release ledger**: `manifest.csv` (eco version -> Redivis versions, written by `manifest.py` from Redivis' history, append-only), `table_changes.csv`, `withdrawals.csv`, `data_notes.csv`. Rendered by `site/corrections.qmd` and `site/data_notes.qmd`. |
| `tools/withdrawals/` | `withdraw_table.py` (dry run by default) removes a shipped table from the Redivis draft and `ledger.py` records it. |
| `queue/` | `candidates.csv`: inspected deposits, their `status` (`available`, `built: <table>`, `held: ...`, `blocked: ...`, `deferred: ...`) and `claimed_by`. `human_review.csv`: what was held and why. |
| `BATCH_LOG.md` | One entry per conversion batch: built, held, what strained the standard. |
| `site/` | Quarto website, published to GitHub Pages by `.github/workflows/site.yml`; pages read the repo's own files at render time. |
| `.github/workflows/` | `tests.yml`: on every PR and push, `eco-validate output/`, the validator's tests, `tools/check_coverage.py` (every core table has `__taxa`, `__dataset.json`, dictionary, tags and metadata rows) and an R parse check; offline by design. `release-eco-validate.yml`: an `eco-validate-vX.Y.Z` tag builds the wheel and attaches it to a GitHub release. `rebuild.yml`: `data/run_all.R` from source, on demand and monthly, never on push (network-bound). `site.yml`: the website. |
| `discovery/`, `discovery_log.csv`, `discovery_summary.md` | The repository search that fed the queue. |
| `analysis/`, `report.html`, `roundtrip_report.md` | The exploratory study's figures and reports. |

## 2. Redivis

| Dataset | Holds | Written by |
|---|---|---|
| `datapages.eco` (reference `eco:4j5q`) | every core table and its side tables, next to each other; a table's kind is its key column, not its location (E10 ruling) | `upload/red_up_eco.py`, draft only |
| `datapages.eco_meta` | the pipeline's own tables: `metadata`, `biblio`, `tags`, later collections (#15) | `metadata/upload_meta.py`, draft only; the dataset is created by Ben, never by a script |

Publishing is a human click. `releases/manifest.csv` records which Redivis version
of each dataset each eco version names; the release checklist is `upload/README.md`.

## 3. How a deposit travels

1. **Found**: a row in `queue/candidates.csv` with `status = available` (from
   discovery, an issue, or by hand).
2. **Intake**: licence verified on the source page, duplicate check by DOI in the
   dictionary, explicit zeros recoverable, taxa resolvable (`processing_guide.md`).
   A deposit that fails goes to `queue/human_review.csv` with the reason and the
   queue row becomes `held:` or `blocked:`.
3. **Built**: `data/<table>.R` downloads into `.cache/raw/<table>/`, reshapes,
   asserts, and calls `write_table()`, which refuses a table the R twin rejects
   and otherwise writes `output/<table>*`; then `stage_dict_row()` and
   `stage_tag_row()` upsert the table's rows; `metadata/run_pipeline.sh` regenerates
   `metadata/`.
4. **Gated**: `python3 -m eco_validate.cli output/<table>.csv`; then
   `Rscript validate/validate_all.R` for the corpus report. The uploader runs the
   same gate again and will not ship a blocked table.
5. **Shipped**: `upload/red_up_eco.py` to the draft; `BATCH_LOG.md` gets its
   entry; the queue row becomes `built: <table>`; commit with the issue number.
6. **Published**: Ben releases the Redivis version; `releases/manifest.py` appends the
   eco version; any correction to an already-published table gets its
   `releases/table_changes.csv` row. The site rebuilds on push.

Facts about a table live in exactly one place:

| Fact | Lives in |
|---|---|
| how the table was made, what was excluded | the header of `data/<table>.R` and `notShipped` in `__dataset.json` |
| licence, citation, DOIs | `dictionary_auto.csv` (one line) and `__dataset.json` (`intellectualRights`, `citation`) |
| counts, density, sample floor, columns, standard version | computed from `output/` by `metadata/01_metadata.R` into `metadata/metadata.csv`; `__dataset.json` carries the same under `summary` for the Redivis description |
| filterable attributes (taxon group, family, protocol, design, coordinates handling, status) | `tags/tags_auto.csv` (automated) and `tags/tags_human.csv` (human, wins per cell), merged into `metadata/tags.csv` |
| corpus counts over time | `metadata/status.json`, `metadata/status_history.tsv` |
| whether the table conforms | `eco-validate`, summarised in `validate/report.csv` |
| why a candidate was not built | `queue/human_review.csv` |
| which Redivis version an eco version names | `releases/manifest.csv` |
| what changed in a published table, and when | `releases/table_changes.csv` (public) and `releases/withdrawals.csv` (the table-keyed index) |
| a caveat about the source that is not an eco defect | `releases/data_notes.csv` |

## 4. Which document wins

| Question | Authoritative source |
|---|---|
| The format: columns, key, zeros, side tables, metadata | `standard.md` |
| Whether a table meets it | `eco_validate/` (`eco-validate`); `standard.md` states the rules, the validator enforces them, the uploader will not ship what it blocks. The R twin in `converters/eco_standard.R` and `lib/eco_common.R` is a convenience for `write_table()`; where it and the Python disagree, fix the R |
| Intake: licence, floor, naming, duplicates | `standard.md` "Intake policy"; the working checklist is `processing_guide.md` |
| How to build a table, step by step | `.claude/skills/eco-convert-deposit/SKILL.md` (order and hard rules) and `processing_guide.md` (judgement) |
| Which designs are in scope, and what a new family would need | `standard.md` E9, then `design_landscape.md` |
| Redivis dataset names | `DATASET` in `upload/red_up_eco.py`; the owner comes from IRW's `redivis_config.R` through `red_up` |
| How anything is uploaded, and the release checklist | `upload/README.md`, then `upload/red_up_eco.py`'s docstring |
| Which Redivis version was live as eco vN | `releases/manifest.csv`; an eco version number is a citation and is never renumbered |
| Whether a published table was corrected, renamed or withdrawn | `releases/table_changes.csv`; `releases/withdrawals.csv` is the internal index by table name |
| Tag vocabulary | `VOCAB` and `PREFIX_VOCAB` in `metadata/03_tags.R`, enforced; `tags/vocab.md` describes them |
| Metadata pipeline run order | `DEFAULT_ORDER` in `metadata/run_pipeline.sh`, the order actually executed |
| Which candidate to process next | `queue/candidates.csv` and the `data queue` issues; `PRIORITIES.md` says why volume ranks where it does |
| What kind of work to do next | `PRIORITIES.md`, advisory; Ben overrules it |
| The work plan | GitHub issues #1 to #19; #19 is the overview and dependency sketch |

## 5. Two rules

**Never duplicate a fact.** Point at where it lives. The counts in `tags_auto.csv`
are copied from `__dataset.json` by code, not retyped; the table-to-script map is
the naming convention, not a file; the validator's clause ids are the standard's
numbering, not a parallel one.

**Run the check rather than trust the paragraph.** A sentence saying a table passes
is a claim; `eco-validate` is the fact. When a document and a tool disagree, the
tool is what actually happened; fix whichever is wrong and say which.

## 6. Parallel sessions

Several Claude Code sessions work in this one tree at once (a batch builder, a
tooling session, a CI session). Each commits only its own files, pulls before
pushing, and tells the others through `SendMessage` when it changes something they
run (`lib/`, the validator, the uploader). The batch session owns `data/`,
`output/`, `dictionary/`, `tags/`, `queue/`, `BATCH_LOG.md` and `data/README.md`
while a batch is in progress; do not edit those from another session.
