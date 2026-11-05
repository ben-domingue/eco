#!/usr/bin/env Rscript
# Table:  asfaw_2025_omo_carniv_occ
# Source: Dryad doi:10.5061/dryad.nk98sf83t, version 343462 (published 2025-01-31), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Asfaw, T., Sillero-Zubiri, C., Leirs, H., Gebresenbet, F.
#         & Bauer, H. "Data from: Anthropogenic and environmental factors determine occupancy and rarity of large
#         carnivores in the Omo valley, Southwest Ethiopia".
# Paper:  Asfaw, T., Sillero-Zubiri, C., Leirs, H., Gebresenbet, F. & Bauer, H. (2025). Anthropogenic and
#         environmental factors determine occupancy and rarity of large carnivores in the Omo Valley, southwest
#         Ethiopia. Ecological Solutions and Evidence, doi:10.1002/2688-8319.70019 (not read: the publisher
#         returns 403 to scripted requests; design from the deposited README.md and the files).
# Data:   README.md and four csv files, one per park x species, each a camera station x occasion 0/1 matrix
#         ("Each sampling occasion spans three days"; "NA values indicate no data") followed by station covariates:
#         Leopard_detection_history_and_covariates.csv and Omo_Spotted_hyaena_detection_history_and_covariates.csv:
#           Omo National Park, 36 stations (first column unnamed; ids FG1..FG62 plus "DCIM" and "FG empety", kept as
#           deposited), S1..S30, then DistRiv (m), Dense_habitat (1 forest, 0 grassland), fifteen prey
#           "abundance" columns, SP, LP, Sum_Prey_Abundance, Min_Dist_Canal (m), Elevation (m), Dist_to_Kuraz
#           (distance to the Omo-Kuraz sugar factory; values 12-52, km by their range), Setup_Date and
#           Retrieval_date (m/d/Y, May to August 2021), Time (setup time, in mixed 12- and 24-hour formats).
#           The two files are identical apart from the 30 detection columns, and their NA patterns are identical
#           (asserted). Every station's NAs are trailing (asserted): occasions run from setup until the camera
#           stopped, truncated at 30.
#         CCNP_leopard_... and CCNP_Spotted_hyaena_...csv: Chebera Churchura NP, 36 stations, S1..S40 and
#           covariates, but no setup or retrieval date and no survey year (the README gives 2020-2022 for the four
#           parks together). Not shipped (see notShipped).
# Mapping (standard E9 single-season occupancy, two species at the same stations):
#   unit = station id; taxon = PANPAR (leopard), CROCRO (spotted hyaena); occasion = 3-day occasion 1..30;
#   y = detected (0/1). Survey evidence: deposited_matrix (NA = no data; the NA pattern is the same for both
#   species). Covariates (unit_): distance to river, dense habitat, distance to canal, elevation, distance to the
#   Kuraz sugar factory, setup and retrieval date (ISO). No dates per occasion: the deposit gives the setup date
#   but the number of non-NA occasions does not match the deployment length exactly for every station, so occasion
#   dates are not reconstructed. No coordinates in the deposit.
#   Not shipped: the CCNP matrices (no survey year or dates); the prey "abundance" covariates (undocumented
#   measure, and many stations share the same small floor value per species, the signature of imputed or modelled
#   values rather than counts); setup time (mixed formats, no AM/PM on most).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "asfaw_2025_omo_carniv_occ"
dir <- download_dryad("10.5061/dryad.nk98sf83t", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "343462"), length(list.files(dir)) == 5L)
rd <- function(f) { d <- fread(file.path(dir, f), encoding = "Latin-1"); setnames(d, 1, "station"); d }
leo <- rd("Leopard_detection_history_and_covariates.csv")
hya <- rd("Omo_Spotted_hyaena_detection_history_and_covariates.csv")
occ <- paste0("S", 1:30)
stopifnot(nrow(leo) == 36L, !anyDuplicated(leo$station), identical(names(leo)[2:31], occ),
          identical(leo[, -(2:31)], hya[, -(2:31)]))
YL <- as.matrix(leo[, ..occ]); YH <- as.matrix(hya[, ..occ])
stopifnot(all(YL %in% c(0L, 1L, NA)), all(YH %in% c(0L, 1L, NA)), identical(is.na(YL), is.na(YH)),
          all(apply(YL, 1, function(r) { k <- which(!is.na(r)); length(k) > 0 && all(k == seq_along(k)) })),
          sum(!is.na(YL)) == 938L, sum(YL, na.rm = TRUE) == 32L, sum(YH, na.rm = TRUE) == 29L)
mk <- function(Y, tx) data.table(unit = rep(leo$station, 30), occasion = rep(1:30, each = 36), y = c(Y), taxon = tx)[!is.na(y)]
long <- rbind(mk(YL, "PANPAR"), mk(YH, "CROCRO"))
pd <- function(x) format(as.IDate(x, format = "%m/%d/%Y"))
cov <- leo[, .(unit = station, unit_dist_river_m = DistRiv, unit_dense_habitat = as.integer(Dense_habitat),
               unit_dist_canal_m = Min_Dist_Canal, unit_elev_m = Elevation, unit_dist_kuraz_km = Dist_to_Kuraz,
               unit_setup_date = pd(Setup_Date), unit_retrieval_date = pd(Retrieval_date))]
stopifnot(!anyNA(cov), all(cov$unit_dense_habitat %in% 0:1), all(substr(cov$unit_setup_date, 1, 4) == "2021"),
          all(cov$unit_retrieval_date > cov$unit_setup_date), all(cov$unit_elev_m > 400 & cov$unit_elev_m < 800))
long <- order_eco(merge(long, cov, by = "unit"))
stopifnot(nrow(long) == 2L * 938L)

taxa <- make_taxa(c("PANPAR", "CROCRO"), c("Panthera pardus", "Crocuta crocuta"),
                  vernacularName = c("Leopard", "Spotted hyaena"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, c("VU", "LC")))

dataset <- list(
  title = "Camera-trap detections of leopard and spotted hyaena at 36 stations in Omo National Park, Ethiopia, May to August 2021",
  creator = "Asfaw, Tsyon; Sillero-Zubiri, Claudio; Leirs, Herwig; Gebresenbet, Fikirte; Bauer, Hans",
  pubDate = "2025", doi = "10.5061/dryad.nk98sf83t", sourceURL = "https://doi.org/10.5061/dryad.nk98sf83t",
  citation = "Asfaw, T., Sillero-Zubiri, C., Leirs, H., Gebresenbet, F., & Bauer, H. (2025). Data from: Anthropogenic and environmental factors determine occupancy and rarity of large carnivores in the Omo valley, Southwest Ethiopia [Dataset]. Dryad. https://doi.org/10.5061/dryad.nk98sf83t",
  paperDOI = "10.1002/2688-8319.70019",
  abstract = "Un-baited camera traps on a 25 km2 grid in Omo National Park, southwest Ethiopia, set in May 2021 and retrieved in July and August 2021, part of the Large Carnivore Occupancy Project in the Omo Valley. Detections of leopard and spotted hyaena are pooled into 3-day occasions, up to 30 per station, with each station's distance to river and canal, habitat, elevation and distance to the Omo-Kuraz sugar factory. The authors fitted occupancy models to relate carnivore occupancy to environmental and human factors.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Un-baited camera traps, one station per 25 km2 grid cell, run for about two and a half months; detections pooled into consecutive 3-day occasions from setup; occasions after the camera stopped are missing.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one deployment per station within one dry-to-wet season",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Omo National Park, Southwest Ethiopia (no station coordinates in the deposit)",
  temporalCoverage = "2021-03/2021-08",
  covariateNote = "unit_dense_habitat: 1 forest with thick vegetation, 0 grassland. unit_dist_kuraz_km: distance to the Omo-Kuraz sugar factory built-up area (unit not stated; km by its range). unit_setup_date and unit_retrieval_date: camera deployment dates as deposited.",
  notShipped = list(
    ccnp = "The two Chebera Churchura National Park matrices (36 stations x 40 occasions, leopard and spotted hyaena): the deposit gives no survey year or setup date for that park, only 2020-2022 for the project as a whole.",
    prey_abundance = "Fifteen prey 'abundance' columns plus SP, LP and Sum_Prey_Abundance: the measure is undocumented and most stations share one small floor value per species, the signature of imputed or modelled values.",
    setup_time = "Time: setup time in mixed 12- and 24-hour formats without AM/PM on most rows."),
  notes = "Station ids are as deposited, including 'DCIM' and 'FG empety'. Station FG28 was set in March 2021; like every station its history is truncated at 30 occasions. Occasion dates are not reconstructed: the count of non-missing occasions does not match each station's deployment length exactly.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/asfaw_2025_omo_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection of leopard and spotted hyaena in 3-day occasions at 36 stations in Omo National Park, Ethiopia, 2021, with habitat and distance covariates.",
  url = "https://doi.org/10.5061/dryad.nk98sf83t",
  reference = "Asfaw, T., Sillero-Zubiri, C., Leirs, H., Gebresenbet, F., & Bauer, H. (2025). Anthropogenic and environmental factors determine occupancy and rarity of large carnivores in the Omo Valley, southwest Ethiopia. Ecological Solutions and Evidence.",
  doi_paper = "10.1002/2688-8319.70019", doi_data = "10.5061/dryad.nk98sf83t",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; Omo NP only (CCNP matrices have no survey year); prey abundance columns not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-species, single season)",
  sampling_protocol = "camera_trap", design = "Single-season (30 occasions of 3 days)",
  realm = "Terrestrial", country = "ETH", coordinates = "None in source",
  notes = "East African large carnivores; leopard IUCN VU, no coordinates in source.")
