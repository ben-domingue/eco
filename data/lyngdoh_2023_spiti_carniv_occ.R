#!/usr/bin/env Rscript
# Table:  lyngdoh_2023_spiti_carniv_occ
# Source: Dryad doi:10.5061/dryad.547d7wmd9 (CC0 1.0, as shown on the Dryad page; published
#         2025-11-03). Lyngdoh, S. & Justa, P. Data from: Understanding carnivore interactions in a
#         cold arid trans-Himalayan landscape: What drives co-existence patterns within predator
#         guild along varying resource gradients?
# Paper:  Justa, P. & Lyngdoh, S. (2023). Ecology and Evolution 13, doi:10.1002/ece3.10040.
#         Camera traps in 1 x 1 km cells across three sites of the Spiti Valley, Himachal Pradesh,
#         India (Chandratal, Kibber, Pin); multi-species occupancy (unmarked occuMulti) of
#         free-ranging dog, red fox, snow leopard and Himalayan wolf.
# Data:   Data_archive__ECE-2022-10-01556.R1.zip, folder occupancy/: DH_dog, DH_redfox, DH_SL,
#         DH_wolf.csv (97 camera stations in file order x o1..o6 weekly occasions, 0/1/NA);
#         det_covs.csv (days operated per station-week, 0-7); Scaled_covs.csv (CT no., Trap_nights,
#         Site, and scaled cell covariates: distance to drainage, main road and settlement, slope,
#         elevation, NDVI, terrain ruggedness, small and large prey); R scripts. Other folders: diet
#         overlap tables, per-station co-occurrence and RAI tables, detection times.
# Mapping (standard: multi-species occupancy, E9 core): unit = station (CT no. 1-97, the row
#   order shared by all files, asserted); taxon = CANFAM / VULVUL / PANUNC / CANLUP; occasion =
#   week 1-6; y = the cell. A week is NA exactly where the camera ran fewer than 7 days (asserted;
#   the authors kept full weeks only), identically for all four species: those weeks are not
#   surveys. unit_site, unit_trap_nights, and the scaled habitat covariates. Survey evidence:
#   deposited_matrix with det_covs.
#   Not shipped: Small_prey / Large_prey (prey availability per cell; the deposit does not say how
#   they were measured, and the README's spatial-overlap folder computes RAIs from the same cameras:
#   indices from the same detectors are not shipped); the co-occurrence and RAI tables (summaries
#   of the same detections); diet overlap and detection times (not survey data). Snow leopard is
#   IUCN VU; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lyngdoh_2023_spiti_carniv_occ"
dir <- download_dryad("10.5061/dryad.547d7wmd9", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
z <- list.files(dir, "^Data_archive__ECE-2022-10-01556\\.R1\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(z) == 1)
ex <- file.path(dirname(z), "unzipped"); if (!dir.exists(ex)) unzip(z, exdir = ex)
rf <- function(n) { f <- list.files(ex, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f, na.strings = "NA") }
SP <- c(CANFAM = "DH_dog\\.csv", VULVUL = "DH_redfox\\.csv", PANUNC = "DH_SL\\.csv", CANLUP = "DH_wolf\\.csv")
O <- paste0("o", 1:6)
D <- lapply(SP, function(n) as.matrix(rf(n)[, ..O]))
dc <- as.matrix(rf("det_covs\\.csv")[, ..O]); sc <- rf("Scaled_covs\\.csv")
setnames(sc, trimws(names(sc)))
stopifnot(all(sapply(D, nrow) == 97), nrow(dc) == 97, nrow(sc) == 97, identical(sc$`CT no.`, 1:97),
          all(sapply(D, function(m) identical(is.na(m), is.na(D[[1]])) && all(m %in% c(0L, 1L, NA)))),
          identical(is.na(D[[1]]), dc < 7), all(rowSums(dc) == sc$Trap_nights), all(trimws(sc$Site) %in% c("CT", "Kibber", "Pin")))
Y <- array(NA_integer_, dim = c(97, 6, 4), dimnames = list(as.character(1:97), NULL, names(SP)))
for (k in names(SP)) Y[, , k] <- D[[k]]
sitec <- data.frame(site = c(CT = "Chandratal", Kibber = "Kibber", Pin = "Pin")[trimws(sc$Site)], trap_nights = sc$Trap_nights,
  dist_drainage_std = sc$Dist_Drain, dist_mainroad_std = sc$Dist_roadm, dist_settlement_std = sc$Dist_settl, slope_std = sc$Slopemean,
  elevation_std = sc$DEMmean, ndvi_std = sc$NDVImean, ruggedness_std = sc$Trimean)
long <- order_eco(array_to_eco(Y, site_ids = as.character(1:97), site_covs = sitec))
stopifnot(nrow(long) == 4 * sum(!is.na(D[[1]])), sum(long$y) == sum(sapply(D, sum, na.rm = TRUE)))
taxa <- make_taxa(names(SP), c("Canis familiaris", "Vulpes vulpes", "Panthera uncia", "Canis lupus"),
                  vernacularName = c("Free-ranging dog", "Red fox", "Snow leopard", "Himalayan wolf"),
                  taxonRemarks = c(NA, NA, NA, "Himalayan wolf lineage, recorded as Canis lupus in the deposit"))
dataset <- list(
  title = "Weekly camera-trap detections of dog, red fox, snow leopard and wolf at 97 stations in the Spiti Valley, India",
  creator = "Lyngdoh, Salvador; Justa, Priyanka", pubDate = "2025", doi = "10.5061/dryad.547d7wmd9", sourceURL = "https://doi.org/10.5061/dryad.547d7wmd9",
  citation = "Lyngdoh, S., & Justa, P. (2025). Data from: Understanding carnivore interactions in a cold arid trans-Himalayan landscape: What drives co-existence patterns within predator guild along varying resource gradients? [Dataset]. Dryad. https://doi.org/10.5061/dryad.547d7wmd9",
  paperDOI = "10.1002/ece3.10040",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of free-ranging dogs, red fox, snow leopard and Himalayan wolf on six weekly occasions at 97 camera-trap stations (one per 1-km cell) in Chandratal, Kibber and Pin, Spiti Valley, trans-Himalayan India, with scaled habitat and human-footprint covariates.",
  samplingProtocol = "One camera trap per 1 x 1 km grid cell at three study sites; detections collapsed to one-week occasions; weeks with fewer than seven camera-days left missing by the authors.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one deployment of up to six weeks per station (the authors' single-season occupancy)", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Spiti Valley, Himachal Pradesh, India (Chandratal, Kibber, Pin); no coordinates deposited",
  temporalCoverage = "survey years not stated in the deposit (paper 2023)",
  notShipped = list(prey = "Small_prey and Large_prey cell covariates (prey availability; source undocumented, likely from the same cameras)",
                    summaries = "co-occurrence and RAI tables per station (summaries of the same detections)", other = "diet overlap tables and detection times"),
  notes = "Partial weeks (1-6 camera-days) are missing in the deposit and are not rows; unit_trap_nights counts all camera-days, including those partial weeks.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/lyngdoh_2023_spiti_carniv_occ.R")
stage_dict_row(TABLE, description = "Weekly camera-trap detections of free-ranging dog, red fox, snow leopard and Himalayan wolf at 97 stations in the Spiti Valley, trans-Himalayan India.",
  url = "https://doi.org/10.5061/dryad.547d7wmd9", reference = "Justa, P., & Lyngdoh, S. (2023). Understanding carnivore interactions in a cold arid trans-Himalayan landscape: What drives co-existence patterns within predator guild along varying resource gradients? Ecology and Evolution, 13.",
  doi_paper = "10.1002/ece3.10040", doi_data = "10.5061/dryad.547d7wmd9", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-species occupancy with dogs.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-species occupancy with interactions",
  sampling_protocol = "camera_trap", design = "Single-season (6 weekly occasions)", realm = "Terrestrial",
  country = "IND", coordinates = "None in source", notes = "Dogs and native carnivores.")
