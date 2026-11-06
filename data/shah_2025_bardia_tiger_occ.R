#!/usr/bin/env Rscript
# Table:  shah_2025_bardia_tiger_occ
# Source: Dryad doi:10.5061/dryad.6q573n65q (CC0 1.0, as shown on the Dryad page; version
#         351591, published 2025). Shah, Shyam Kumar et al. Ecological factors at fine spatial scale
#         associated with habitat use by tigers in western Terai Arc landscape, Nepal.
# Paper:  Ecology and Evolution (2025), doi:10.1002/ece3.71109 (Dryad primary_article).
#         Camera-trap survey of Bardia and Banke National Parks and adjoining forest, 16 December
#         2021 to 12 March 2022, under Nepal's tiger monitoring protocol (DNPWC 2017); 719 grid
#         cells of 2 x 2 km, a 15-16 day camera session per cell (Dryad methods text).
# Data:   Data_for_OpenAccess.csv, 719 rows (Id_grid, unique) x 32 columns: 20 detection columns
#         R1, R2, R3, R4, R1.1 ... R1.16 (README: "20 spatial replicates", 1 detected / 0 not;
#         the odd names are as deposited and the script keeps their column order as the
#         replicate index), then dist_build, dist_river, dist_road (m), ndvi, tri, slope (deg),
#         aspect (deg), ele (m), dist_waterholes (m), prey and carnivores (indices).
#         43 detection cells are "-" (41 grids with one, 1 with two), all but one in R1.1; the
#         README does not define "-": it is read as "replicate not surveyed" (a missing row),
#         the only reading under which it differs from 0. The README says 720 unique ids; the
#         file has 719, matching the 719 grid cells of the methods text. No coordinates.
# Mapping (standard: single-season occupancy, E9 core):
#   unit = Id_grid; taxon = PANTIG; occasion = replicate 1..20 in deposited column order;
#   y = the 0/1 cell; "-" = no row. unit_: the nine landscape covariates (remotely sensed,
#   averaged per grid; README). Survey evidence: deposited_matrix ("-" distinct from 0).
#   occasionKind = spatial (README: spatial replicates; how a replicate is defined within a grid
#   cell is not in the deposit). closure = closed (one 15-16 day session per cell, the authors'
#   single-season occupancy).
#   Not shipped: prey and carnivores, indices derived from the same camera survey's detections
#   of other species (processing guide: indices built from the same detections are not
#   covariates). Tiger is IUCN EN, but the deposit has no coordinates, only grid ids.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "shah_2025_bardia_tiger_occ"
dir <- download_dryad("10.5061/dryad.6q573n65q", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Data_for_OpenAccess\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f, colClasses = "character")
rc <- c(paste0("R", 1:4), paste0("R1.", 1:16))
cc <- c("dist_build", "dist_river", "dist_road", "ndvi", "tri", "slope", "aspect", "ele", "dist_waterholes")
stopifnot(identical(names(raw), c("Id_grid", rc, cc, "prey", "carnivores")),
          nrow(raw) == 719, !anyDuplicated(raw$Id_grid))
Yc <- as.matrix(raw[, ..rc])
stopifnot(all(Yc %in% c("0", "1", "-")), sum(Yc == "-") == 43, sum(Yc == "1") == 755,
          sum(rowSums(Yc == "-") > 0) == 42)
Y <- matrix(suppressWarnings(as.integer(Yc)), nrow(Yc)); dimnames(Y) <- list(raw$Id_grid, NULL)
stopifnot(sum(is.na(Y)) == 43)
sc <- as.data.frame(lapply(raw[, ..cc], as.numeric)); stopifnot(!anyNA(sc))
long <- array_to_eco(Y, taxon = "PANTIG", site_ids = raw$Id_grid, site_covs = sc)
stopifnot(nrow(long) == 719 * 20 - 43, sum(long$y) == 755, uniqueN(long$unit) == 719,
          sum(tapply(long$y, long$unit, max)) == sum(rowSums(Y, na.rm = TRUE) > 0))
taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger")
dataset <- list(
  title = "Tiger camera-trap detections in 719 grid cells of Bardia and Banke National Parks, Nepal, 20 replicates each, winter 2021-22",
  creator = "Shah, Shyam Kumar; Karki, Jhamak Bahadur; Bhatta, Balram; Subedi, Naresh; K. C., Rabin Bahadur; Kadariya, Rabin; Karki, Ajay; Poudel, Umesh; Lamichhane, Babu Ram; Thapa, Arjun", pubDate = "2025", doi = "10.5061/dryad.6q573n65q",
  sourceURL = "https://doi.org/10.5061/dryad.6q573n65q",
  citation = "Shah, S. K. et al. (2025). Ecological factors at fine spatial scale associated with habitat use by tigers in western Terai Arc landscape, Nepal [Dataset]. Dryad. https://doi.org/10.5061/dryad.6q573n65q",
  paperDOI = "10.1002/ece3.71109",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of tiger (Panthera tigris) from camera traps in 719 2 x 2 km grid cells covering Bardia and Banke National Parks and adjoining forest in the western Terai Arc Landscape, Nepal, 16 December 2021 to 12 March 2022, as 20 replicates per cell, with nine remotely sensed landscape covariates per cell.",
  samplingProtocol = "Paired camera traps on trails, roads and riverbeds in each 2 x 2 km grid cell for one 15-16 day session, under Nepal's tiger and prey monitoring protocol (DNPWC 2017); the deposit gives 20 replicates per cell, which its README calls spatial replicates.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed",
  closureNote = "one 15-16 day camera session per grid cell; the authors fit single-season occupancy",
  occasionKind = "spatial", taxonInclusion = "single",
  geographicCoverage = "Bardia and Banke National Parks and adjoining forest, western Terai Arc Landscape, Nepal; no coordinates deposited",
  temporalCoverage = "2021-12/2022-03",
  notShipped = list(prey = "prey index, derived from the same camera survey's detections of prey species",
                    carnivores = "carnivore index, derived from the same camera survey's detections of other carnivores"),
  notes = "occasion is the deposited replicate column in file order (R1-R4, then R1.1-R1.16, names as deposited); the README calls them spatial replicates and does not say how a replicate is defined within a cell. A '-' cell (43, 42 grids) is read as not surveyed and has no row; the README does not define it. The README says 720 grid ids, the file has 719. Tiger is IUCN EN; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/shah_2025_bardia_tiger_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of tiger in 719 2 x 2 km grid cells of Bardia and Banke National Parks, Nepal, winter 2021-22, 20 replicates per cell, with landscape covariates.",
  url = "https://doi.org/10.5061/dryad.6q573n65q",
  reference = "Shah, S. K. et al. (2025). Ecological factors at fine spatial scale associated with habitat use by tigers in western Terai Arc landscape, Nepal. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.71109", doi_data = "10.5061/dryad.6q573n65q",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-species occupancy; replicate definition not in the deposit; prey and carnivore indices not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (20 replicates per grid cell)", realm = "Terrestrial",
  country = "NPL", coordinates = "None in source",
  notes = "755 detections; IUCN EN species, no coordinates deposited.")
