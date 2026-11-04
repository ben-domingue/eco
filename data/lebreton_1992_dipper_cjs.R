#!/usr/bin/env Rscript
# Table:  lebreton_1992_dipper_cjs
# Source: marked::dipper (GPL >= 2): the European dipper capture-recapture data from eastern
#         France, 1981-1987 (Marzolin; Lebreton et al. 1992, Ecological Monographs 62), the
#         standard CJS example distributed with program MARK.
# Data:   294 individuals x ch (7-character capture history) x sex (Female/Male).
# Mapping (standard E1-E5; CJS, standard_draft.md section 3.4): unit = individual, taxon =
#   CINCIN, period = capture occasion 1..7 (years 1981..1987 in __periods), y = 0/1,
#   unit_sex. Every individual has a row at every period (all at risk; no losses on
#   capture in this version of the data). surveyEvidence = deposited_matrix.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(marked))
TABLE <- "lebreton_1992_dipper_cjs"

data(dipper)
stopifnot(nrow(dipper) == 294, all(nchar(dipper$ch) == 7), all(dipper$sex %in% c("Female", "Male")))
long <- ch_to_eco(dipper, taxon = "CINCIN")
stopifnot(nrow(long) == 294 * 7, all(long$y %in% 0:1))
periods <- data.table(period = 1:7, year = 1981:1987)

taxa <- make_taxa("CINCIN", "Cinclus cinclus", vernacularName = "White-throated Dipper")
dataset <- list(
  title = "European dipper capture-recapture histories, eastern France, 1981-1987 (marked::dipper)",
  creator = "Marzolin, Gilbert (data); Lebreton, Jean-Dominique; Burnham, Kenneth P.; Clobert, Jean; Anderson, David R.",
  pubDate = "1992", sourceURL = "https://cran.r-project.org/package=marked",
  citation = "Lebreton, J.-D., Burnham, K. P., Clobert, J. & Anderson, D. R. (1992). Modeling survival and testing biological hypotheses using marked animals: a unified approach with case studies. Ecological Monographs 62(1), 67-118. https://doi.org/10.2307/2937171. Data as bundled in marked (Laake, Johnson & Conn 2013).",
  paperDOI = "10.2307/2937171",
  intellectualRights = list(spdx = "GPL-2.0-or-later", url = "https://www.gnu.org/licenses/gpl-2.0.html"),
  abstract = "Textbook CJS dataset: 294 European dippers captured and recaptured over seven annual occasions (1981-1987) along streams in eastern France, with sex. A flood in 1983 is the classic covariate on survival.",
  samplingProtocol = "Annual capture-mark-recapture of dippers along streams; one capture occasion per year.",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Eastern France (streams; no coordinates in the package)", temporalCoverage = "1981/1987",
  coordinatesCoarsened = NA,
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lebreton_1992_dipper_cjs.R")
stage_dict_row(TABLE,
  description = "Capture histories of 294 European dippers over 7 annual occasions (1981-1987) in eastern France, with sex (marked::dipper; Lebreton et al. 1992). The standard CJS textbook example.",
  url = "https://cran.r-project.org/package=marked",
  reference = "Lebreton, J.-D., Burnham, K. P., Clobert, J. & Anderson, D. R. (1992). Modeling survival and testing biological hypotheses using marked animals. Ecological Monographs 62(1), 67-118.",
  doi_paper = "10.2307/2937171", original_license = "GPL-2", derived_license = "GPL-2",
  notes = "Textbook dataset bundled with an R package. Round-trip tested in converters/rt_04_dipper_cjs.R.",
  source_via = "R package (marked)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (7 annual occasions)", realm = "Freshwater", country = "FRA",
  coordinates = "None in source", notes = "Textbook dataset (marked). unit = individual; period = year.")
