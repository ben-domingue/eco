#!/usr/bin/env Rscript
# Table:  yadav_2022_rapti_gharial_count
# Source: Dryad doi:10.5061/dryad.fttdz08ww (CC0 1.0 as shown on the dataset JSON), version
#   199657 (published 2022-10-04). Yadav, R. K., Lamichhane, S., Thanet, D. R., Rayamajhi, T.,
#   Bhattarai, S., Bashyal, A. & Lamichhane, B. R. Gharial abundance in Rapti River, Chitwan,
#   Nepal.
# Paper:  Yadav, R. K., et al. (2022). Ecology and Evolution 12: e9425, doi:10.1002/ece3.9425
#         (gharial abundance by binomial N-mixture model).
# Data:   Data.xlsx, two sheets.
#         "Gharial Count Data": header row SITE, REP 1, REP 2, REP 3; 18 rows site1..site18 =
#           the ~4 km segments of the 72 km Rapti River through Chitwan National Park; cells =
#           gharials counted in the segment on each of three boat surveys (13 Nov - 3 Dec 2019,
#           PRESENCE layout, no missing values).
#         "Covariates": columns 1-5 rows 2-19 = DepthXDepth (depth squared), River Depth (m),
#           River Channel Width (m), Sandbank number, Human Disturbance (people washing clothes
#           plus fishermen); segment means of measurements every 200 m. Columns 9-13 hold a
#           correlation matrix of the covariates (an analysis product).
#
# Mapping (standard E1-E6, N-mixture): unit = segment (site1..site18), taxon = GAVGAN, occasion
#   = survey replicate 1-3, y = gharials counted. Survey evidence: the deposited matrix (every
#   segment counted on all three surveys; no missing-value code). unit_depth_m, unit_width_m,
#   unit_sandbanks, unit_human_disturbance per segment (constant across replicates, as deposited).
#   Not shipped: DepthXDepth (the square of the shipped depth) and the covariate correlation
#   matrix. Survey dates per replicate are not deposited. Gavialis gangeticus is IUCN Critically
#   Endangered; no coordinates are deposited (segment labels only).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "yadav_2022_rapti_gharial_count"
dir <- download_dryad("10.5061/dryad.fttdz08ww", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Data.xlsx"); stopifnot(file.exists(f), identical(excel_sheets(f), c("Gharial Count Data", "Covariates")))
cnt <- as.data.table(read_excel(f, "Gharial Count Data"))
stopifnot(identical(names(cnt), c("SITE", "REP 1", "REP 2", "REP 3")), nrow(cnt) == 18L,
          identical(cnt$SITE, paste0("site", 1:18)), !anyNA(cnt))
Y <- as.matrix(cnt[, 2:4]); storage.mode(Y) <- "integer"
stopifnot(all(Y >= 0L), sum(Y) == 276L, all(unname(colSums(Y)) == c(86L, 94L, 96L)))
cv <- as.data.table(suppressMessages(read_excel(f, "Covariates", col_names = FALSE)))
stopifnot(identical(unlist(cv[1, 1:5], use.names = FALSE),
                    c("DepthXDepth", "River Depth (m)", "River Channel Width (m)", "Sandbank number",
                      "Human Disturbance(#washing clothes+fishermen")))
cv <- cv[2:19, 1:5]; setnames(cv, c("depth2", "depth_m", "width_m", "sandbanks", "human_disturbance"))
cv <- cv[, lapply(.SD, as.numeric)]
stopifnot(nrow(cv) == 18L, !anyNA(cv), all(abs(cv$depth2 - cv$depth_m^2) < 1e-6))
cat(sprintf("  18 segments x 3 counts, %d gharial sightings; max per count %d; segments with none: %d\n",
            sum(Y), max(Y), sum(rowSums(Y) == 0)))

long <- array_to_eco(Y, taxon = "GAVGAN", site_ids = cnt$SITE,
                     site_covs = cv[, .(depth_m, width_m, sandbanks = as.integer(sandbanks), human_disturbance = as.integer(human_disturbance))])
stopifnot(nrow(long) == 54L, sum(long$y) == sum(Y))

taxa <- make_taxa("GAVGAN", "Gavialis gangeticus", vernacularName = "Gharial", taxon_iucnCategory = "CR")
dataset <- list(
  title = "Repeated counts of gharials on 18 river segments, Rapti River, Chitwan National Park, Nepal, November-December 2019",
  creator = "Yadav, Ramesh Kumar; Lamichhane, Saneer; Thanet, Dol Raj; Rayamajhi, Trishna; Bhattarai, Santosh; Bashyal, Ashish; Lamichhane, Babu Ram",
  pubDate = "2022", doi = "10.5061/dryad.fttdz08ww", sourceURL = "https://doi.org/10.5061/dryad.fttdz08ww",
  citation = "Yadav, R. K., Lamichhane, S., Thanet, D. R., Rayamajhi, T., Bhattarai, S., Bashyal, A., & Lamichhane, B. R. (2022). Gharial abundance in Rapti river, Chitwan, Nepal [Dataset]. Dryad. https://doi.org/10.5061/dryad.fttdz08ww",
  paperDOI = "10.1002/ece3.9425",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of basking gharials (Gavialis gangeticus) on each of 18 four-kilometre segments of the Rapti River in Chitwan National Park, Nepal, on three boat surveys between 13 November and 3 December 2019, with segment means of river depth and width, sandbank number and human disturbance; analysed with a binomial N-mixture model.",
  samplingProtocol = "Boat survey by two observers with binoculars along the whole 72 km river, three replicate surveys in winter when gharials bask; each 4 km segment's count summed from 20 points at 200 m.",
  samplingProtocolCode = "boat_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "period (three surveys within three weeks in winter; population treated as closed by the authors)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Rapti River, Chitwan National Park, Nepal (segment labels only, no coordinates deposited)",
  temporalCoverage = "2019-11-13/2019-12-03", coordinatesCoarsened = NA,
  notShipped = list(DepthXDepth = "the square of unit_depth_m (asserted)", correlation_matrix = "covariate correlation matrix on the Covariates sheet (analysis product)",
                    survey_dates = "dates of the three replicates not deposited"),
  notes = "Covariates are segment means of measurements every 200 m and do not vary by replicate in the deposit.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/yadav_2022_rapti_gharial_count.R")

stage_dict_row(TABLE,
  description = "Repeated counts of the Critically Endangered gharial (Gavialis gangeticus) on 18 four-kilometre segments of the Rapti River, Chitwan National Park, Nepal, three boat surveys in November-December 2019, with river depth, width, sandbanks and human disturbance per segment.",
  url = "https://doi.org/10.5061/dryad.fttdz08ww",
  reference = "Yadav, R. K., Lamichhane, S., Thanet, D. R., Rayamajhi, T., Bhattarai, S., Bashyal, A., & Lamichhane, B. R. (2022). Gharial (Gavialis gangeticus) abundance in the Rapti River, Chitwan National Park, Nepal. Ecology and Evolution, 12, e9425.",
  doi_paper = "10.1002/ece3.9425", doi_data = "10.5061/dryad.fttdz08ww",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Small N-mixture table (18 segments, below the sample floor). CR species; no coordinates in source.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "N-mixture",
  sampling_protocol = "boat_count", design = "Single-season (3 replicate counts)", realm = "Freshwater",
  country = "NPL", coordinates = "None in source", notes = "Basking counts along river segments; 18 units.")
