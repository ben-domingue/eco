# dictionary/

`dictionary_auto.csv` is the eco analogue of IRW's Data Dictionary: one
description / origin / licence row per table. Columns: `table`, `description`,
`source_url`, `reference`, `doi_paper`, `doi_data`, `original_license`,
`derived_license`, `notes`, `contributor`, `date` (ISO), `source_via`. Rows are
written by `stage_dict_row()` in `lib/eco_common.R` from each `data/` script;
re-running a script replaces its row. Through v0.2 the file used IRW's 16-column
sheet header for union compatibility; v0.3 dropped that, since these tables are
not going into the IRW dictionary.

Richer per-table metadata (EML/Darwin Core fields, protocol, closure, state
codes, coordinate handling, counts) lives in `output/<table>__dataset.json`,
which also becomes the Redivis table description.
