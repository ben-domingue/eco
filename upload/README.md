# Releasing

`red_up_eco.py` writes an unreleased draft on Redivis. Nothing in this repo
publishes; the release is a human click. The checklist, in order:

1. `Rscript metadata/fetch_bibtex.R` has cached BibTeX for new DOIs, and `metadata/run_pipeline.sh` has regenerated `metadata/`.
2. `python3 upload/red_up_eco.py --dry-run` shows every intended table as `CORE` or `SIDE`, none `SKIP`, each with the shard it goes to (`-> eco_2 (new)`; new tables go to the oldest shard under 950 tables (`redivis_config.py`), an existing table stays where it is); then `python3 upload/red_up_eco.py`. The upload is the gate (eco-validate `--irw`) and writes the shipped tables' rows in `validate/report.csv`. Commit the `__dataset.json` files, staging rows, `metadata/` and the report, and push.
3. `python3 metadata/upload_meta.py` to the `eco_meta` draft (once that dataset exists).
4. Ben reviews the drafts on Redivis and publishes every core shard the upload touched (`eco`, `eco_2`, ...; together, so the manifest counts them as one eco version), then `eco_meta`.
5. `python3 releases/manifest.py` appends the new eco version; add a `note` if the release has a theme; commit.
6. If the release carries a correction, rename or withdrawal to a table already published, append its row to `releases/table_changes.csv` naming the new `eco_version`, and fill `released` on any `releases/withdrawals.csv` row it carries.
7. Push. The site rebuilds and the Corrections page and release line update.

A table that must not ship carries `do_not_publish: <reason>` in its tags `status`
and the uploader refuses it. A table that has shipped and must go is a withdrawal:
`tools/withdrawals/`.

Tables live on Redivis, not in git (#88); a table's CSVs exist in `output/` only
between `Rscript data/<table>.R` and the upload. The uploader ships a core or side
table only if it is the build its `__dataset.json` describes (`coreMd5` or an `md5`
per part, and `sideTables.<suffix>.md5`, recorded by `write_table()`), and refuses
a leftover from an older build as stale (#75). Rebuild, then upload, in one sitting.
