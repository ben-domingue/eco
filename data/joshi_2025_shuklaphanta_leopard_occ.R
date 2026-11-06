#!/usr/bin/env Rscript
# Table:  joshi_2025_shuklaphanta_leopard_occ
# Source: Dryad doi:10.5061/dryad.2jm63xszp (CC0 1.0, as shown on the Dryad page; published 2025).
#         Joshi et al. Data from: Tigers, terrain, and human settlement influence the occupancy of
#         leopards (Panthera pardus) in southwestern Tarai, Nepal.
# Paper:  Joshi, L.R. et al. (2025), Ecology and Evolution, doi:10.1002/ece3.70898 (Dryad primary_article).
#         Camera survey of Shuklaphanta National Park (ShNP, 305 km2), December
#         2022 to January 2023, under Nepal's 2017 tiger monitoring protocol: 92 grid cells of
#         4 km2, paired Panthera cameras operated 15-19 nights per cell (README).
# Data:   4-5-2024-leo_cov_v1.csv, 92 rows x 11 columns: Grid ID; OC1-OC4, leopard detection
#         (0/1) in four consecutive 4-day blocks (README); disthuman, distriver (m, from the
#         camera); terrain (TRI of the grid); det_tiger, det_prey, det_livestock (relative
#         abundance indices, RAI, from the same cameras). No missing cells. No coordinates.
# Mapping (standard: single-season occupancy, E9 core):
#   unit = Grid ID; taxon = PANPAR; occasion = 4-day block 1..4; y = OCk. unit_: disthuman,
#   distriver, terrain. Survey evidence: deposited_matrix (complete: every cell has 4 blocks).
#   closure = closed (one 15-19 night session; the authors' single-season occupancy).
#   Not shipped: det_tiger, det_prey, det_livestock, RAIs computed from the same camera survey's
#   detections (processing guide: indices from the same detections are not covariates; tiger
#   RAI is the paper's main predictor, and the tiger and prey RAIs are recoverable from the
#   source). Leopard is IUCN VU; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "joshi_2025_shuklaphanta_leopard_occ"
dir <- download_dryad("10.5061/dryad.2jm63xszp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "leo_cov_v1\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f)
stopifnot(identical(names(raw), c("Grid ID", paste0("OC", 1:4), "disthuman", "distriver", "terrain",
                                  "det_tiger", "det_prey", "det_livestock")),
          nrow(raw) == 92, !anyDuplicated(raw$`Grid ID`), !anyNA(raw))
Y <- as.matrix(raw[, paste0("OC", 1:4), with = FALSE]); dimnames(Y) <- list(raw$`Grid ID`, NULL)
stopifnot(all(Y %in% 0:1))
sc <- as.data.frame(raw[, .(dist_human_m = disthuman, dist_river_m = distriver, terrain_tri = terrain)])
long <- array_to_eco(Y, taxon = "PANPAR", site_ids = raw$`Grid ID`, site_covs = sc)
stopifnot(nrow(long) == 92 * 4, sum(long$y) == sum(Y))
taxa <- make_taxa("PANPAR", "Panthera pardus", vernacularName = "Leopard")
dataset <- list(
  title = "Leopard camera-trap detections in 92 grid cells of Shuklaphanta National Park, Nepal, four 4-day blocks, winter 2022-23",
  creator = "Joshi, Laxmi Raj; K C, Rabin Bahadur; Chhetri, Madhu; Odden, Morten; Devineau, Olivier; Karki, Ajay; Dahal, Bhagwan Raj; Subedi, Naresh", pubDate = "2025", doi = "10.5061/dryad.2jm63xszp",
  sourceURL = "https://doi.org/10.5061/dryad.2jm63xszp",
  citation = "Joshi, L. R. et al. (2025). Data from: Tigers, terrain, and human settlement influence the occupancy of leopards (Panthera pardus) in southwestern Tarai, Nepal [Dataset]. Dryad. https://doi.org/10.5061/dryad.2jm63xszp",
  paperDOI = "10.1002/ece3.70898",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of leopard (Panthera pardus) from paired camera traps in 92 4 km2 grid cells of Shuklaphanta National Park, Nepal, December 2022 to January 2023, in four 4-day blocks per cell, with distance to settlement, distance to river and terrain ruggedness.",
  samplingProtocol = "Paired Panthera V5/V6 camera traps on roads, fire lines, riverbeds and trails in each 4 km2 grid cell, 15-19 nights per cell, under Nepal's 2017 tiger and prey monitoring protocol; detections summarised in four consecutive 4-day blocks.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed",
  closureNote = "one 15-19 night camera session per grid cell; the authors fit single-season occupancy",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Shuklaphanta National Park, southwestern Tarai, Nepal; no coordinates deposited",
  temporalCoverage = "2022-12/2023-01",
  notShipped = list(det_tiger = "tiger relative abundance index from the same camera survey",
                    det_prey = "prey relative abundance index from the same camera survey",
                    det_livestock = "livestock relative abundance index from the same camera survey"),
  notes = "Leopard is IUCN VU; no coordinates are deposited. The three RAI covariates come from the same cameras' detections and are not shipped.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/joshi_2025_shuklaphanta_leopard_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of leopard in 92 grid cells of Shuklaphanta National Park, Nepal, winter 2022-23, four 4-day blocks per cell, with three site covariates.",
  url = "https://doi.org/10.5061/dryad.2jm63xszp",
  reference = "Joshi et al. (2025). Tigers, terrain, and human settlement influence the occupancy of leopards (Panthera pardus) in southwestern Tarai, Nepal. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.70898", doi_data = "10.5061/dryad.2jm63xszp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-species occupancy; RAI covariates from the same cameras not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (4 x 4-day blocks)", realm = "Terrestrial",
  country = "NPL", coordinates = "None in source", notes = "IUCN VU species, no coordinates deposited.")
