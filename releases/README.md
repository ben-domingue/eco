# releases/

The release ledger: what was published, when, and what changed afterwards. Small
tracked CSVs, appended by hand or by `manifest.py`; the site renders them
(`site/corrections.qmd`, `site/data_notes.qmd`). Policy, borrowed from IRW:
**released versions never change; corrections are new versions; every correction
is recorded here; drafts are published by a human.**

| File | One row per | Written by |
|---|---|---|
| `manifest.csv` | eco version: `eco_version, date, eco_redivis_version, eco_meta_redivis_version, n_tables, note` | `python3 releases/manifest.py` from Redivis' own version history, anonymously. Appends only; refuses to renumber. `note` is the one hand-edited column; `eco_meta_redivis_version` for the latest eco version is refreshed when `eco_meta` is released after the tables (the metadata pipeline runs last). `--check` for CI |
| `table_changes.csv` | correction to a published table: `date, table, eco_version, kind (correction, withdrawal, rename), summary, issue, replaces, replaced_by` | by hand, once the release carrying the change is live |
| `withdrawals.csv` | table removed from the current release onward: `table, dataset, withdrawn, reason, refs, rows, released, script, note, reinstated` | `tools/withdrawals/ledger.py` from a withdrawal script; `released` filled by hand after Ben publishes |
| `data_notes.csv` | caveat about a *source* that is not an eco defect: `table, note, issue, date` | by hand, whenever a script's `notShipped` or header records something a user should know |

`reason` in `withdrawals.csv` is one of `rights`, `wrong_data`, `duplicate`,
`unlicensed`, `source_withdrawn`, `out_of_scope`, `misnamed`. A withdrawn table also
gets a `table_changes.csv` row of kind `withdrawal` when the release goes live, so
the public record and the internal index agree.

The eco version number is the citation. `eco v1` is Redivis `eco` v1.0 of
2026-11-01 (16 tables: six core and their side tables). The release checklist is in
`upload/README.md`.
