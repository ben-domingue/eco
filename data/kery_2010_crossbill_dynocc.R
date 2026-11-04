#!/usr/bin/env Rscript
# Table:  kery_2010_crossbill_dynocc
# Source: unmarked::crossbill (GPL >= 3): European crossbill detection/non-detection on 267
#         Swiss MHB quadrats, 3 surveys per year, 1999-2007; the dataset of the unmarked
#         colext vignette (Kery & Chandler) and of Kery, Dorazio et al. (2010 ... AHM2 ch. 4).
# Data:   267 rows: id, ele, forest, surveys (2 or 3 planned per year), det991..det073
#         (27 detection columns, year x survey), date991..date073 (27 Julian-date columns).
#         NA = no survey. The round trip (rt_05) showed 48 site-years with no survey.
# Mapping (standard E1-E5; dynamic occupancy, standard_draft.md section 3.5): unit = quadrat
#   id, taxon = LOXCUR, period = year 1..9 (1999..2007 in __periods), occasion = survey 1..3,
#   y = 0/1; unit_ele, unit_forest, unit_surveys_planned; obs_date_doy (raw Julian date, not
#   standardised as in the vignette). Cells where date is NA but y is not (or vice versa)
#   are treated as not surveyed, as the vignette does. surveyEvidence = deposited_matrix.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(unmarked))
TABLE <- "kery_2010_crossbill_dynocc"

data(crossbill)
stopifnot(nrow(crossbill) == 267, all(crossbill$surveys %in% 2:3))
y <- as.matrix(crossbill[, 5:31]); DATE <- as.matrix(crossbill[, 32:58])
stopifnot(ncol(y) == 27, ncol(DATE) == 27, all(y[!is.na(y)] %in% 0:1))
mismatch <- sum(is.na(DATE) != is.na(y)); cat(sprintf("  %d cells with y but no date or date but no y -> not surveyed\n", mismatch))
y[is.na(DATE) != is.na(y)] <- NA; DATE[is.na(y)] <- NA
years <- 1999:2007
umf <- unmarkedMultFrame(y = y, siteCovs = data.frame(ele = crossbill$ele, forest = crossbill$forest, surveys_planned = crossbill$surveys),
                         obsCovs = list(date_doy = DATE), numPrimary = 9)
long <- umf_to_eco(umf, taxon = "LOXCUR", site_ids = crossbill$id)
stopifnot(nrow(long) == sum(!is.na(y)), max(long$period) == 9, max(long$occasion) == 3)
periods <- data.table(period = 1:9, year = years)

taxa <- make_taxa("LOXCUR", "Loxia curvirostra", vernacularName = "Red Crossbill")
dataset <- list(
  title = "European crossbill detection/non-detection, Swiss MHB, 267 quadrats x 3 surveys x 9 years, 1999-2007 (unmarked::crossbill)",
  creator = "Kery, Marc; Swiss Ornithological Institute (data); Fiske, Ian; Chandler, Richard (package)",
  pubDate = "2011", sourceURL = "https://cran.r-project.org/package=unmarked",
  citation = "Fiske, I. & Chandler, R. (2011). unmarked: An R package for fitting hierarchical models of wildlife occurrence and abundance. Journal of Statistical Software 43(10). https://doi.org/10.18637/jss.v043.i10. Data: Swiss breeding bird survey MHB (Schweizerische Vogelwarte), unmarked::crossbill; analysed in the colext vignette and in Kery & Royle, AHM2 chapter 4.",
  paperDOI = "10.18637/jss.v043.i10",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook dynamic-occupancy dataset: crossbill detection/non-detection on up to three surveys per year over nine years at 267 MHB quadrats, with elevation, forest cover and survey date.",
  samplingProtocol = "Simplified territory mapping along a fixed transect in each 1-km2 quadrat, two (above the tree line) or three surveys per breeding season, every year 1999-2007; collapsed to detection/non-detection per survey.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Switzerland, MHB 1-km2 quadrats (no coordinates in the package)", temporalCoverage = "1999/2007",
  coordinatesCoarsened = NA,
  notShipped = list(unsurveyed_site_years = "site-years with no survey have no rows (48 in the round trip); the year is in __periods so nothing is lost"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/kery_2010_crossbill_dynocc.R")
stage_dict_row(TABLE,
  description = "European crossbill detection/non-detection on up to 3 surveys per year, 1999-2007, at 267 Swiss MHB 1-km2 quadrats, with elevation, forest cover and survey date (unmarked::crossbill; the colext vignette and AHM2 ch. 4 dataset).",
  url = "https://cran.r-project.org/package=unmarked",
  reference = "Fiske, I. & Chandler, R. (2011). unmarked: An R package for fitting hierarchical models of wildlife occurrence and abundance. Journal of Statistical Software 43(10).",
  doi_paper = "10.18637/jss.v043.i10", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package. Raw Julian survey dates shipped (the vignette standardises them). Round-trip tested in converters/rt_05_crossbill_dynocc.R.",
  source_via = "R package (unmarked)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy",
  sampling_protocol = "line_transect", design = "Multi-season (9 years x 3 surveys)", realm = "Terrestrial", country = "CHE",
  coordinates = "None in source", notes = "Textbook dataset (unmarked). Unbalanced: 2 or 3 surveys per year; some site-years unsurveyed.")
