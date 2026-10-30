# Discovery summary — where ecological detection data lives

*Light pass, 2026-10-30. Counts come from each repository's public search API
with ten query terms; they are rough upper bounds (most APIs word-match rather
than phrase-match) and overlap across sources. Full per-query counts and the
curated sample are in `discovery_log.csv`; the raw hits and cached responses are
in `discovery/`. Nothing was downloaded beyond file listings and the first lines
of a few small CSVs; no accounts were created and no access requests made.*

## Headline

The data exists in volume, it is overwhelmingly **CC0**, and the dominant
deposited shape is exactly the one the draft standard targets: a wide site ×
occasion matrix with `NA` for occasions not surveyed, plus a separate
site-covariate file. The hard part is not licensing or format but **recovering
the survey design** (which occasions were conducted, what the effort was) from
deposits that often ship only the analysed matrix.

## Sources, ranked by apparent richness

| Source | Signal | Notes |
|--------|--------|-------|
| **Dryad** | 400–1,250 word-match hits per term ("detection/non-detection" 1,254; "detection history" 1,063; "occupancy model" 606; "capture history" 533; "camera trap" 482; "capture-recapture" 401; "N-mixture" 132) | The richest general repository by a wide margin and the one with the cleanest licensing (CC0 by policy). Deposits are typically 2–6 small CSV/xlsx files: one detection matrix per species, one covariate file, a README. Anonymous API file download returns 401; the Zenodo mirror of each Dryad deposit (same DOI) serves the files openly, so a harvester should resolve Dryad → Zenodo. Realistic yield after false positives (phylogenetics, isotopes, fossils): perhaps 20–30% of the "detection history"/"occupancy model" hits, i.e. **a few hundred usable tables**. |
| **Zenodo** | 18–391 phrase hits per term | A large share are Dryad mirrors (dedupe by DOI). Native Zenodo deposits add MARK `.inp` files (CJS), zipped R projects, and camera-trap image archives (not usable). Licences mostly CC0 / CC-BY-4.0. |
| **USGS ScienceBase** | 3–99 per term | Public domain. Two kinds of hit: (a) raw survey data releases with FGDC metadata (loon occupancy, amphibian VES surveys, bat acoustic surveys), small and clean; (b) model *outputs* (prediction rasters, coefficient tables) that match "occupancy" but are not detection data — roughly half of the "occupancy model" hits. Also hosts the **North American Breeding Bird Survey** release (1966–2021): route × year × species counts with 50-stop detail, observer and weather tables; the single largest well-structured source (id = route, item = species, period = year, occasion = stop, rater = observer). |
| **DataONE / KNB / EDI / LTER** | 3–357 per term on DataONE | DataONE's index is dominated by Dryad (237 of 325 "occupancy" hits), so it is not an independent source. EDI (14) and KNB (11) contribute long-term monitoring series (Hubbard Brook valleywide bird survey 1999–, Pepperwood point counts) documented in EML, usually as long event tables — the easiest to convert when the event table lists every survey. EDI's own PASTA search endpoint returns 403 to anonymous users; go through DataONE. |
| **GBIF sampling-event datasets** | 5,319 datasets of type `SAMPLING_EVENT`; 12–103 per term | Darwin Core event core = our `surveys` side table; the occurrence extension holds detections. Non-detections are *implicit* (an event with no occurrence row for a species) and must be zero-filled against the dataset's species list, which the DwC-A does not always carry. Only 185 datasets mention "absence". National bird monitoring schemes (Swedish Bird Survey, 490k + 900k records, CC0) are the prize here. Occurrence-only datasets (the bulk of GBIF) are excluded by the type filter and are out of scope. |
| **NEON** | 26 organismal products | CC0, API-served, long tables, every survey event recorded. Breeding landbird point counts (47 sites, distance and time bands), small-mammal box trapping (tag IDs, every trap-night incl. empty traps — robust-design CR and SCR-ready), beetles, mosquitoes, ticks, fish. A handful of products but each is large and continuously growing; the best "one integration, many tables" target. |
| **Harvard / other Dataverses** | 1–57 per term | Thin. Hits are mostly code-and-data replication packages (R scripts + `.rds`) and Borealis (Canada) deposits; a few good long-term series (fish detection histories per HUC-year, 77 years). CC0 default. |
| **Figshare** | API gives no totals | Dominated by journal supplementary files (PLOS, Frontiers): single detection-history tables attached to a paper, licence inherited from the article (usually CC-BY). Individually small, collectively numerous; a journal-driven harvest (as IRW does with PLOS) would work here. |
| **OSF** | 0–21 | Weak title search and few ecology deposits; mostly SCR and camera-trap projects. Low priority. |
| **eBird** | not queried | Gated (data request form). Complete checklists plus the sampling-event file give true non-detections; the `auk` package zero-fills. Enormous, but terms of use would need review before any redistribution. |
| **Movebank** | not queried | Telemetry; out of scope (no unit × probe structure). |
| **R packages** (`unmarked`, `AHMbook`, `spOccupancy`, `marked`, `RMark`, `secr`, `nimbleSCR`, `ubms`, `camtrapR` examples) | ~80 datasets | GPL, already in model-ready structures, every family represented. The right seed corpus; six were round-tripped in Phase 2. |

## Rough volume estimate

A precision check on the 80 unique top-ranked Dryad hits for the four strongest
terms ("detection history", "detection/non-detection", "occupancy model",
"capture history") finds **31 (39%)** whose title/keywords describe real
detection, count or capture-history data; the rest are model code, simulations,
genomics, isotopes, fossils or museum records matched on a word. Precision will
fall further down the ranking, and the four term counts (1,063 / 1,254 / 606 /
533) overlap heavily, so a defensible estimate for Dryad is **roughly 2,000
unique hits × 25–40% ≈ 500–800 usable deposits**, before any check that the
survey design is recoverable. In the whole 1,083-dataset sample across sources,
only 33 datasets appeared in more than one source, but 134 Dryad DOIs were
reachable through Zenodo or DataONE — the mirrors, not independent holdings.

- **Now, with modest effort:** 50–100 tables from bundled R data + ScienceBase +
  EDI/KNB + the cleanest Dryad deposits — comparable to IRW's early size.
- **With a Dryad/Zenodo harvester** plus a Figshare journal sweep: ~500–800 Dryad
  deposits plus a few hundred from elsewhere — on the order of 1,000 single- and multi-species tables, most of them small (20–300 units,
  2–12 occasions).
- **With GBIF sampling-event, BBS and NEON integrations:** a small number of
  very large multi-species tables (10⁵–10⁷ rows each) that would dominate the
  corpus by row count.

## Common formats and pitfalls

1. **Wide matrices with `NA` for "not surveyed"** (`o1…o12`, `S1…S80`,
   `det991…det073`). Straightforward; the explicit-zero rule handles them. Watch
   for deposits that pad with 0 instead of `NA` — only the README reveals it.
2. **Aggregated-over-occasions deposits**: counts per site over k pooled days
   with an effort column (e.g. Dryad `2jm63xsnp`). The occasion structure is
   gone; the table fits as `occasion = 1` with `obs_effort`, but supports fewer
   models.
3. **Column names that encode design**: `point1.fall2` = site × season,
   `det991` = year 99 visit 1. Parsing is per-deposit.
4. **Species as rows, site-occasions as columns** (the transpose of the usual
   layout) in multi-species deposits.
5. **MARK `.inp` files** for capture–recapture: histories as strings with a
   frequency column and group columns; need `RMark::convert.inp` or a small parser.
6. **Darwin Core archives**: event + occurrence tables; zero-filling needs the
   species list, which is often only in the metadata or must be inferred from
   the occurrence table (biasing toward detected species).
7. **Model outputs mislabelled as data** (prediction rasters, coefficient CSVs)
   match every query; expect ~30–50% false positives on "occupancy".
8. **Precise coordinates for sensitive taxa** (tapir, large carnivores) appear in
   small deposits as plain lat/long columns; a harvester needs a coarsening step
   before republication.
9. **xlsx and rar** archives on Dryad; multi-sheet workbooks with one sheet per
   species.

## Licensing patterns

Far more favourable than psychology. Dryad, EDI, NEON, Borealis and Harvard
Dataverse default to **CC0**; ScienceBase is **US public domain**; Zenodo and
GBIF are mostly **CC0 / CC-BY-4.0** with a minority of **CC-BY-NC** (GBIF
publishers in Kenya, Australia). Journal supplements inherit **CC-BY**. R
package data is **GPL**. We saw no ND licences and no "contact author" deposits
in the sample, though Zenodo native deposits should still be checked
individually. The gated sources (eBird) are the only ones with bespoke terms.

## What this means for the standard

- The `surveys`/effort problem is the real conversion cost. The explicit-zero
  rule is right, but a harvester needs a per-deposit decision about whether `0`
  means "surveyed, not detected" — and should refuse deposits where it cannot tell.
- Multi-species deposits usually arrive with a species-code table (`speciesCode.csv`
  with scientific names) — the `items` side table is natural, not imposed.
- Site covariates ship as a separate keyed file almost always; `cov_` joins are
  trivial. Observation covariates are rarer in deposits than in textbooks: many
  deposits carry only effort (trap-nights) per site.
