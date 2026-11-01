#!/usr/bin/env Rscript
# Table:  kery_2008_willowtit_occ
# Source: unmarked package file csv/widewt.csv (GPL >= 3), Swiss breeding bird survey MHB
#         willow tit detection/non-detection at 237 1-km2 quadrats x 3 surveys. The data
#         accompany the unmarked overview vignette (Fiske & Chandler 2011) and the MHB willow
#         tit analyses of Kery (2008, Auk 125) and Kery & Royle (AHM1 ch. 10).
# Data:   237 rows: site, y.1-y.3 (0/1), elev, forest, length (site covariates, already
#         standardised in the package file), date.1-3 and ivel.1-3 (survey date and survey
#         intensity, standardised). 46 NA cells (survey not made); no site is unsurveyed;
#         4 cells have a date but no y and are treated as not surveyed.
# Mapping (standard E1-E5; single-season occupancy, standard_draft.md section 3.1):
#   unit = site, taxon = POEMON, occasion = survey 1..3, y = 0/1; unit_elev, unit_forest,
#   unit_length (standardised, as shipped by the package); obs_date_doy_std, obs_ivel_std.
#   surveyEvidence = deposited_matrix (NA vs 0 in the package matrix).
#   Year of survey not stated in the package file.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(unmarked))
TABLE <- "kery_2008_willowtit_occ"

w <- read.csv(system.file("csv", "widewt.csv", package = "unmarked"))
Y <- as.matrix(w[, c("y.1", "y.2", "y.3")])
stopifnot(nrow(w) == 237, sum(is.na(Y)) == 46, all(rowSums(!is.na(Y)) > 0), all(Y[!is.na(Y)] %in% 0:1))
umf <- unmarkedFrameOccu(y = Y,
                         siteCovs = w[, c("elev", "forest", "length")],
                         obsCovs = list(date_doy_std = as.matrix(w[, c("date.1", "date.2", "date.3")]),
                                        ivel_std = as.matrix(w[, c("ivel.1", "ivel.2", "ivel.3")])))
long <- umf_to_eco(umf, taxon = "POEMON", site_ids = w$site)
stopifnot(nrow(long) == sum(!is.na(Y)), uniqueN(long$unit) == 237)

taxa <- make_taxa("POEMON", "Poecile montanus", vernacularName = "Willow Tit")
dataset <- list(
  title = "Willow tit detection/non-detection, Swiss MHB, 237 quadrats x 3 surveys (unmarked widewt.csv)",
  creator = "Kery, Marc; Swiss Ornithological Institute (data); Fiske, Ian; Chandler, Richard (package)",
  pubDate = "2011", sourceURL = "https://cran.r-project.org/package=unmarked",
  citation = "Fiske, I. & Chandler, R. (2011). unmarked: An R package for fitting hierarchical models of wildlife occurrence and abundance. Journal of Statistical Software 43(10), 1-23. https://doi.org/10.18637/jss.v043.i10. Data: Swiss breeding bird survey MHB (Schweizerische Vogelwarte), file csv/widewt.csv.",
  paperDOI = "10.18637/jss.v043.i10",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook dataset: willow tit (Poecile montanus) detection/non-detection on three replicate surveys of 237 1-km2 MHB quadrats, with standardised elevation, forest cover, transect length, survey date and survey intensity. Used in the unmarked overview vignette and in AHM1 chapter 10.",
  samplingProtocol = "Simplified territory mapping along a fixed transect in each 1-km2 quadrat, up to three surveys per breeding season; collapsed to detection/non-detection per survey.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "Switzerland, MHB 1-km2 quadrats (no coordinates in the package file)",
  temporalCoverage = "one breeding season, year not stated in the package file",
  coordinatesCoarsened = NA,
  covariateNote = "All covariates are standardised (mean 0, sd 1) in the package file; the raw scales are not recoverable.",
  notShipped = list(unsurveyed_cells = "46 site-surveys not made have no rows"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/kery_2008_willowtit_occ.R")
stage_dict_row(TABLE,
  description = "Willow tit detection/non-detection on 3 surveys of 237 Swiss MHB 1-km2 quadrats, with standardised elevation, forest, transect length, survey date and intensity (unmarked widewt.csv; the dataset of the unmarked overview vignette and AHM1 ch. 10).",
  url = "https://cran.r-project.org/package=unmarked",
  reference = "Fiske, I. & Chandler, R. (2011). unmarked: An R package for fitting hierarchical models of wildlife occurrence and abundance. Journal of Statistical Software 43(10).",
  doi_paper = "10.18637/jss.v043.i10", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package; covariates standardised in the source. Round-trip tested in converters/rt_01_willowtit_occu.R.",
  source_via = "R package (unmarked)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy",
  sampling_protocol = "line_transect", design = "Single-season", realm = "Terrestrial", country = "CHE",
  coordinates = "None in source", notes = "Textbook dataset (unmarked). Covariates standardised; 46 unsurveyed cells.")
