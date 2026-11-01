#!/usr/bin/env Rscript
# Table:  tleimat_2023_ecuador_capuchin_occ
# Source: figshare 10.6084/m9.figshare.22626790.v1 (CC BY 4.0). Tleimat, J., McCracken, S.F.,
#         Lynch, R., Rodriguez, D. & Fritts, S. (2023). Capuchin Detection History.
#         "capuchin detection data binned on a two-week interval from the HCKBA ... used for
#         detection and presence modeling"; tags: Ecuadorian Capuchin, habitat association.
# Data:   capubinup2.csv: 21 camera stations (AG01 ...) x 39 two-week occasions whose column
#         headers are the interval start dates (2019-12-22 .. 2021-06-03), 0/1/NA, followed
#         by 19 station covariates (elevation, tree and station height, habitat class,
#         distances to barrio / edge / water, DBH, connected trees, canopy and vegetation
#         cover overall and by aspect). Station codes only; no coordinates.
# Mapping (standard E1-E5; single-season occupancy): unit = station, taxon = CEBAEQ
#   (Cebus aequatorialis, Ecuadorian white-fronted capuchin, IUCN CR; the deposit says
#   "Ecuadorian Capuchin" and names no species, so the taxon is the one Ecuadorian capuchin
#   that name denotes), occasion = 1..39, date = interval start (ISO), y = 0/1; unit_*
#   covariates with the deposit's names made snake_case. Closure across the 18-month series is
#   the depositors' assumption; recorded in closure. surveyEvidence = deposited_matrix.
#   Coordinates: none deposited, so the CR-taxon coarsening rule (E7) does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "tleimat_2023_ecuador_capuchin_occ"

f <- download_cached("https://ndownloader.figshare.com/files/40152604", TABLE, filename = "capubinup2.csv")
raw <- fread(f, encoding = "UTF-8"); setnames(raw, 1, "station")
stopifnot(nrow(raw) == 21)
occ_cols <- grep("^\\d{1,2}/\\d{1,2}/\\d{4}$", names(raw), value = TRUE); stopifnot(length(occ_cols) == 39)
dates <- as.Date(occ_cols, format = "%m/%d/%Y"); stopifnot(!anyNA(dates), all(diff(dates) > 0))
m <- as.matrix(raw[, ..occ_cols]); stopifnot(all(m[!is.na(m)] %in% 0:1))
cov_names <- c(elevat = "elevation_m", `tree height` = "tree_height_m", `station height` = "station_height_m", habitat = "habitat",
               `dist to barrio (km)` = "dist_barrio_km", `dist to edge (km)` = "dist_edge_km", `DBH (cm)` = "dbh_cm",
               `Connected trees` = "connected_trees", `CC (avg)` = "canopy_cover_avg", `VC (avg)` = "veg_cover_avg",
               `dist to water (km)` = "dist_water_km", `CC (N)` = "canopy_cover_n", `CC (E)` = "canopy_cover_e", `CC (W)` = "canopy_cover_w",
               `CC (S)` = "canopy_cover_s", `VC (N)` = "veg_cover_n", `VC (E)` = "veg_cover_e", `VC (W)` = "veg_cover_w", `VC (S)` = "veg_cover_s")
stopifnot(all(names(cov_names) %in% names(raw)))
site_covs <- as.data.frame(raw[, names(cov_names), with = FALSE]); names(site_covs) <- unname(cov_names)
long <- array_to_eco(m, taxon = "CEBAEQ", site_ids = raw$station, site_covs = site_covs,
                     obs_covs = list(interval_start = matrix(format(dates), nrow(m), ncol(m), byrow = TRUE)))
setnames(long, "obs_interval_start", "date")
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(m)), uniqueN(long$unit) == 21)

taxa <- make_taxa("CEBAEQ", "Cebus aequatorialis", vernacularName = "Ecuadorian white-fronted capuchin", taxon_iucnCategory = "CR")
dataset <- list(
  title = "Ecuadorian capuchin camera-trap detection histories, 21 stations x 39 two-week occasions, Dec 2019 - Jun 2021",
  creator = "Tleimat, Jacquelyn; McCracken, Shawn F.; Lynch, Ryan; Rodriguez, David; Fritts, Sarah",
  pubDate = "2023", doi = "10.6084/m9.figshare.22626790.v1", sourceURL = "https://doi.org/10.6084/m9.figshare.22626790.v1",
  citation = "Tleimat, J., McCracken, S. F., Lynch, R., Rodriguez, D. & Fritts, S. (2023). Capuchin Detection History [Data set]. figshare. https://doi.org/10.6084/m9.figshare.22626790.v1",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Capuchin detection data binned on a two-week interval from the HCKBA, used for detection and presence modelling (deposit description). Station-level habitat covariates: elevation, tree and station height, habitat class, distances to settlement, forest edge and water, DBH, connected trees, canopy and vegetation cover.",
  samplingProtocol = "Camera traps at 21 stations; detection/non-detection per two-week interval; NA where the station was not operating.",
  samplingProtocolCode = "camera_trap", occasionLength = "14 days", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion (the depositors treat the 18-month series as one season)",
  geographicCoverage = "Ecuador, study area 'HCKBA' (station codes only; no coordinates deposited)",
  temporalCoverage = "2019-12-22/2021-06-17",
  coordinatesCoarsened = NA,
  notShipped = list(none = "all deposited columns are shipped"),
  taxonNote = "The deposit names no species; 'Ecuadorian capuchin' is Cebus aequatorialis (IUCN Critically Endangered). No coordinates are deposited, so no coarsening was needed.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/tleimat_2023_ecuador_capuchin_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of Ecuadorian capuchins at 21 stations over 39 two-week intervals (Dec 2019 - Jun 2021) in Ecuador, with 19 station-level habitat covariates; no coordinates.",
  url = "https://doi.org/10.6084/m9.figshare.22626790.v1",
  reference = "Tleimat, J., McCracken, S. F., Lynch, R., Rodriguez, D. & Fritts, S. (2023). Capuchin Detection History [Data set]. figshare.",
  doi_data = "10.6084/m9.figshare.22626790.v1", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "21 units: below the sample floor (filterable). Species inferred from 'Ecuadorian capuchin' (Cebus aequatorialis, CR); study area given only as 'HCKBA'. No paper DOI on the deposit.",
  source_via = "figshare")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (18 months, 14-day occasions)", realm = "Terrestrial", country = "ECU",
  coordinates = "None in source", notes = "Critically Endangered primate; 21 stations; many stations operated for part of the series only.")
