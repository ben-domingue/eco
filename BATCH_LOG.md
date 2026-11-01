# Batch log

One entry per conversion batch (issue #10, step 5): what was built, what was
held and why. Tables listed here are in `output/`; whether they are published is
the `status` column of `tags/tags_auto.csv`.

## Batch 1 — 2026-10-31 (six tables, published to Redivis)

malhotra_2021_loslagos_comm, schank_2015_tapir_occ, toledolima_2024_elaenia_cjs,
palacio_2020_pampasbirds_comm, frimpong_2017_newriver_dynocc,
uherkoch_2021_npraloon_dynocc. See `data/README.md`.

## Batch 2 — 2026-11-01 (six tables from five deposits)

Built under v0.3 and held locally on Ben's instruction until the standard was frozen
as v1.0-draft (commit 088ba37) the same day; then rebuilt with `surveyEvidence`
(E4), `responseType = ordinal` for the calling index (E2) and the licence-conflict
ruling (intake policy), re-validated (12/12 eco_valid, 12/12 IRW view conforms) and
uploaded to the Redivis draft.

| Table | Family | Source | Rows | Notes |
|---|---|---|---|---|
| hamer_2024_hungary_amph_comm | community occupancy | Dryad CC0 | 2,691 | 100 ponds x 3 surveys x 9 amphibians; `date` from a day offset; one unsurveyed cell |
| galvez_2021_araucania_comm | community occupancy (camera) | Dryad CC0 / readme ODbL -> derived ODbL-1.0 | 9,135 | 180 cameras x 14 occasions x 5 taxa; per-occasion camera nights; stricter licence propagates (intake ruling) |
| margenau_2021_rowsongbirds_nmix | N-mixture, multi-species, manipulative | Dryad CC0 | 135,072 | first N-mixture table; counts built from per-individual records; flyovers excluded; 2 non-IBP codes handled |
| glorioso_2025_atchafalaya_ves | community counts (N-mixture), 9 years | USGS public domain | 104,152 | surveys from a deposited sample table (explicit zeros verifiable); coordinates as published |
| glorioso_2025_atchafalaya_calls | ordinal (calling index 0-3) | USGS public domain | 31,024 | same 2,216 surveys; `obs_call_index_outside` |
| mctigue_2023_nwarkansas_comm | community occupancy (camera), 2 winters | Dryad CC0 | 46,746 | record table; deployment dates unreliable, zeros inferred from first/last detection spans; `y_raw` = episodes |

Held / rejected this batch (details in `queue/human_review.csv`): the two EDI
point-count packages (edi.348.2, edi.556.1: Cloudflare login wall on the portal
and 403 on PASTA for scripted requests), Margenau's `Data_stopover.csv` (second
table later), McTigue's density/covariate file (model output, unjoinable IDs).

Survey evidence (E4): Hamer `deposited_matrix`, Gálvez `effort_table`, Glorioso x2
`sample_table`, Margenau `row_presence`, McTigue `inferred` (first-to-last detection
span; deployment dates not believed).

Things this batch strained in the v0.3 standard, each now ruled in v1.0-draft:

- **Explicit zeros from record tables.** Three of five deposits (Margenau,
  McTigue, and to a lesser degree Glorioso) are one-row-per-detection files. The
  standard should say what counts as evidence of a survey when no sample table is
  deposited, and require the inference rule in `dataset.notes`.
- **Ordinal / index responses.** The calling index is neither a count nor a
  state; now `responseType = "ordinal"` with `stateCodes` (E2).
- **Per-row covariates that vary by taxon** (`obs_call_index_outside`): allowed by
  the `obs_` definition but worth an explicit sentence, since most `obs_` columns
  repeat across the taxa of a survey.
- **Licence conflicts** between the repository metadata and the deposited readme
  (Gálvez): ruled, the stricter licence governs and propagates (`derived_license =
  ODbL-1.0`, both recorded in `original_license`).
- **`y_raw` as the uncollapsed count** behind a 0/1 `y` (McTigue) is in 2.1 and
  worked without changes.
- No multinomial, distance-sampling or SCR deposit in this batch; no sensitive
  taxon with exact coordinates (USGS sites are on public management units and are
  published by the agency; kept as published); largest table 135k rows.
