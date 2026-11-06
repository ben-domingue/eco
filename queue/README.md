# queue/

`candidates.csv` is the list collaborators consult before converting a deposit,
so two people do not build the same table. It was seeded from the discovery
pass (`../discovery_log.csv`: inspected deposits with recoverable non-detections
and conversion difficulty 1-4). Columns: `status` (`available`, `claimed`,
`built: <table>`), `claimed_by`, plus the deposit's source, DOI/URL, licence,
data type, difficulty and notes.

To claim one: open an issue on `ben-domingue/eco` titled with the table name you
intend to use (`author_year_place_type`), set `status = claimed` and
`claimed_by` in this file in the same PR as your `data/` script, and change it
to `built: <table>` when the script and its `output/` files land. Add new
candidates at the bottom with `status = available`.

`human_review.csv` is the IRW-style record of inspected deposits (or parts of
deposits) that were held, rejected or need a human ruling, with the reason, so
they are not re-triaged. Columns: `candidate`, `source`, `doi_or_url`, `decision`
(`held`, `blocked`, `rejected`, `needs-human`; `available` when a ruling lifts a hold
and the deposit can be built, `resolved` once it is), `reason` (appended to, never
overwritten), `date`, `reviewer`. A rejected deposit's `candidates.csv` row is
`not built: <reason>`.
