# Releasing

`red_up_eco.py` writes an unreleased draft on Redivis. Nothing in this repo
publishes; the release is a human click. The checklist, in order:

1. `python3 -m eco_validate.cli output/` exits 0 and `Rscript validate/validate_all.R` has rewritten `validate/report.csv`.
2. `metadata/run_pipeline.sh` has regenerated `metadata/`; everything is committed and pushed.
3. `python3 upload/red_up_eco.py --dry-run` shows every intended table as `CORE` or `SIDE`, none `SKIP`; then `python3 upload/red_up_eco.py`.
4. `python3 metadata/upload_meta.py` to the `eco_meta` draft (once that dataset exists).
5. Ben reviews the drafts on Redivis and publishes `eco`, then `eco_meta`.
6. `python3 releases/manifest.py` appends the new eco version; add a `note` if the release has a theme; commit.
7. If the release carries a correction, rename or withdrawal to a table already published, append its row to `releases/table_changes.csv` naming the new `eco_version`, and fill `released` on any `releases/withdrawals.csv` row it carries.
8. Push. The site rebuilds and the Corrections page and release line update.

A table that must not ship carries `do_not_publish: <reason>` in its tags `status`
and the uploader refuses it. A table that has shipped and must go is a withdrawal:
`tools/withdrawals/`.
