# analysis/occupancy_corpus

One-off behind the artifact **Occupancy Across the Corpus**
(https://claude.ai/artifact/KX9mcaHATnhUpTUV83hULU, 2026-11-01): the constant
single-season occupancy model `occu(~1 ~1)` fitted to every repeated-visit
detection table in `output/` (count tables collapsed to `y > 0`), and
`colext(~1, ~1, ~1, ~1)` fitted to the crossbill, Maine marten and six New River
fish. Estimates are compared with naive occupancy per species.

| file | what |
|---|---|
| `fit_occ.R` | the fits; reads `output/`, writes `occu_fits.csv` and `colext_fits.csv` |
| `build_page.R` | assembles `occ_data.json` and inlines it into `occupancy_template.html` to give `occupancy_corpus.html` |
| `occupancy_corpus.html` | the published page (self-contained apart from Google Fonts) |

Run both from the repo root. The fits take about a minute; nothing here touches
`output/` or `metadata/`. The site vignette `site/vignettes/occupancy.qmd` has its
own corpus-wide section with a goodness-of-fit bootstrap; this directory is the
lighter artifact version and is not wired into the site.
