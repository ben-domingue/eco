Batch 45 GBIF sampling-event listing and triage (2026-11-06). Run in order from a scratch directory:
`curl` the occurrence facet `occurrenceStatus=ABSENT&license=<CC0_1_0|CC_BY_4_0>&facet=datasetKey&facetLimit=10000` into
`absent_<lic>.json`, then `list_se.py` (all SAMPLING_EVENT datasets), `dedupe.py` (drop what eco already has; paths are
hard-coded to the batch worktree), `triage.py` (GBIF metadata and occurrence facets), `gen.py` (decisions ->
`discovery/gbif_se_absent_b45.csv`, manual calls in `credible.py`), `rows.py` (queue and discovery-log rows).
