# metadata/

The pipeline's own tables, regenerated from the repo by numbered stages;
`run_pipeline.sh` is the run order. The site and (later) the client packages read
these, never `tags/` or `dictionary/` directly.

| File | Stage | What |
|---|---|---|
| `metadata.csv` | `01_metadata.R` | computed per core table from `output/`: counts, density, naive occupancy, response type, survey evidence, sample floor, coordinates, variables, standard version |
| `biblio.csv` | `02_biblio.R` | origin, licence and citation per table: `dictionary/dictionary_auto.csv` joined to `__dataset.json`; `bibtex` reserved for #11 |
| `tags.csv` | `03_tags.R` | filterable attributes: `tags/tags_auto.csv` with `tags/tags_human.csv` cells winning; vocabulary from `tags/vocab.md` enforced |
| `status.json`, `status_history.tsv` | `11_status.R` | the current counts and one appended row per run |

Human tags go in `tags/tags_human.csv` (same columns as `tags_auto.csv`, `rater` =
initials); never edit `tags_auto.csv` or `metadata/*.csv` by hand, the next run
overwrites them. `upload_meta.py` ships the three CSVs to Redivis `eco_meta` as a
draft (the dataset must exist; Ben creates it).
