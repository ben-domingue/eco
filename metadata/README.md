# metadata/

The pipeline's own tables, regenerated from the repo by numbered stages;
`run_pipeline.sh` is the run order. Before it, after a batch, `Rscript metadata/fetch_bibtex.R` caches BibTeX for any new DOI in `bibtex/` (network; commit the new files); the pipeline itself stays offline. The site and (later) the client packages read
these, never `tags/` or `dictionary/` directly.

| File | Stage | What |
|---|---|---|
| `metadata.csv` | `01_metadata.R` | computed per core table from `output/`: counts, density, naive occupancy, response type, survey evidence, sample floor, coordinates, variables, standard version |
| `biblio.csv` | `02_biblio.R` | origin, licence and citation per table: `dictionary/dictionary_auto.csv` joined to `__dataset.json`; `bibtex` is the deposit's entry (key `<table>`) and the paper's (`<table>_paper`) from `bibtex/`, a `@misc` where the deposit has no DOI; `deposit` = the source deposit (its DOI URL, else source URL), which groups a deposit's tables; `derived_license` = the SPDX id (#11) |
| `tags.csv` | `03_tags.R` | filterable attributes: `tags/tags_auto.csv` with `tags/tags_human.csv` cells winning; vocabulary from `tags/vocab.md` enforced |
| `table_locations.csv` | `tools/table_locations.py` | one approximate point per table for the homepage map: the mean of its decimal unit coordinates (read from Redivis), else the centre of `geographicCoverage.boundingBox`, else the hand-assigned point in `tags/locations_human.csv`; rounded to 0.1 degree, with `precision`, `extent_km` and `source`. `upload/red_up_eco.py` reads the points of the tables it uploads from the Redivis draft; pipeline stage 12 runs it `--offline`, keeping those and placing the rest from tracked files. `tools/check_coverage.py` fails a table with no point and no `tags/locations_human.csv` row, so add one (a point, or empty lat/lon and a basis saying why none) |
| `status.json`, `status_history.tsv` | `11_status.R` | the current counts (tables, deposits, rows, ...) and one appended row per run |

Human tags go in `tags/tags_human.csv` (same columns as `tags_auto.csv`, `rater` =
initials); never edit `tags_auto.csv` or `metadata/*.csv` by hand, the next run
overwrites them. `upload_meta.py` ships the three CSVs to Redivis `eco_meta` as a
draft (the dataset must exist; Ben creates it).
