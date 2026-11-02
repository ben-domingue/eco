#!/usr/bin/env Rscript
# Table:  blount_2025_neturkiye_carniv_count
# Source: Zenodo 10.5281/zenodo.14618279, "Combining N-mixture and Occupancy Analysis Offers a
#         More Complete Picture of Carnivore Habitat Use in Northeastern Turkiye", uploaded by
#         Judson Blount, published 2025-01-08, licence CC BY 4.0 (as shown on the record).
# Paper:  Blount, J. D., Green, A. M., Chynoweth, M., Coban, E., Kusak, J. & Sekercioglu, C. H.
#         (2025). Combining N-mixture and occupancy analysis offers a more complete picture of
#         carnivore habitat use in Northeastern Turkiye. PLOS One 20(5), e0320768.
#         https://doi.org/10.1371/journal.pone.0320768 (open access, PMC12077724).
# Data:   seven xlsx files, no readme, no row ids anywhere.
#         Wolf.Count(7-Day).xlsx, Bear.Count(7-Day).xlsx: 229 deployments x o1..o104 seven-day
#           occasions (o1 = first week of the deployment), independent detections per week
#           (wolf event = 30 min, bear = 10 min, paper), NA = camera not operating; NA cells are
#           a trailing block in every row; 13 rows are all NA; 3,540 surveyed cells; max 104
#           weeks = the paper's 728-day longest deployment.
#         Lynx.Bi / Wolf.Bi / Bear.Bi (7-Day).xlsx: 229 x 104, 0/1, the same NA pattern; wolf
#           and bear Bi equal (Count > 0) in every surveyed cell (asserted).
#         Lynx.Count(7-Day).xlsx: 215 x 472, a different shape (14 rows fewer, 472 columns,
#           two rows with more than 104 surveyed weeks) and no ids, so it cannot be aligned to
#           the deployments; not shipped. Lynx 0/1 ships in the sibling table
#           blount_2025_neturkiye_lynx_occ.
#         Final_covs-Trimmed.xlsx, sheet "Sheet 1": 229 deployments x 34 columns: deployment_id
#           (camera id, deployment number, setup dates), FOV (field-of-view score 1-5), Model,
#           Heigth (canopy / chest / knee), place (row index 1-229), Year (the deployment's rank
#           1-4 at its site), YYYY (calendar year 2009-2023), x / y (longitude / latitude, WGS84, 8 decimals;
#           157 distinct locations), aspect, slope, dist_from_m_rds (main roads, m), dist_from_f_rds,
#           dist_from_ua (urban areas, m), land_type (CORINE level-3 code 24/25/26/29),
#           elevation (m), dist_from_fe, dist_from_dump (m), OBJECTID.x/.y (GIS join keys),
#           placename (mostly empty), human.rate / vehicle.rate (trap rates at the deployment),
#           AREA / PERCENTAGE (500-m buffer area in m2 and percent forest in it, CORINE 2018; AREA
#           NA for two deployments), scaled_* (z-scores of the preceding, dropped as derived). Sheet "Sheet1" repeats
#           deployment_id and place. The matrices and the covariate sheet have no ids in common;
#           they are the authors' unmarked inputs and are taken to be in the same row order
#           (the only reading under which the 13 all-NA matrix rows make sense as deployments
#           kept for covariate alignment).
# Mapping (standard E1-E5; N-mixture community counts):
#   unit = deployment_id (229; the paper models each deployment as a site, one per site per
#   year, at most four per site), taxon = CANLUP / URSARC, occasion = seven-day window 1..104
#   within the deployment, y = independent detections in the week (count). Community rule:
#   both taxa carry a row for every surveyed deployment-week (identical NA pattern, asserted).
#   One period: occasions are deployment-relative weeks and each deployment is one site-year;
#   the calendar year is unit_year. No dates (week start dates are not deposited).
#   Survey evidence: deposited_matrix (NA = not operating). Coordinates as deposited (exact; neither
#   taxon is IUCN CR/EN/VU). cluster_id = camera location (157 distinct coordinate pairs).
#   Not shipped: the three Bi files (0/1 = y > 0), Lynx.Count (unalignable), scaled_* columns,
#   OBJECTID.*, place, placename.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "blount_2025_neturkiye_carniv_count"
BASE <- "https://zenodo.org/api/records/14618279/files/%s/content"
FILES <- c("Wolf.Count(7-Day).xlsx", "Bear.Count(7-Day).xlsx", "Lynx.Count(7-Day).xlsx",
           "Lynx.Bi(7-Day).xlsx", "Wolf.Bi(7-Day).xlsx", "Bear.Bi(7-Day).xlsx", "Final_covs-Trimmed.xlsx")
f <- sapply(FILES, function(x) download_cached(sprintf(BASE, utils::URLencode(x, reserved = TRUE)), TABLE, x))
rd <- function(x) { d <- read_excel(f[[x]]); stopifnot(identical(names(d), paste0("o", seq_len(ncol(d))))); suppressWarnings(matrix(as.numeric(as.matrix(d)), nrow(d))) }

W <- rd("Wolf.Count(7-Day).xlsx"); B <- rd("Bear.Count(7-Day).xlsx")
Wb <- rd("Wolf.Bi(7-Day).xlsx"); Bb <- rd("Bear.Bi(7-Day).xlsx"); Lb <- rd("Lynx.Bi(7-Day).xlsx")
L <- rd("Lynx.Count(7-Day).xlsx")
stopifnot(dim(W) == c(229, 104), dim(B) == c(229, 104), dim(Wb) == c(229, 104), dim(Bb) == c(229, 104), dim(Lb) == c(229, 104),
          dim(L) == c(215, 472), sum(!is.na(L)) == 3409, sum(rowSums(!is.na(L)) > 104) == 2)   # Lynx.Count is another shape
na <- is.na(W)
stopifnot(identical(na, is.na(B)), identical(na, is.na(Wb)), identical(na, is.na(Bb)), identical(na, is.na(Lb)),
          sum(!na) == 3540, sum(rowSums(!na) == 0) == 13, max(rowSums(!na)) == 104,
          all(apply(na, 1, function(r) all(diff(as.integer(r)) >= 0))),           # trailing NA only
          all(W[!na] == round(W[!na])), all(B[!na] == round(B[!na])), all(W[!na] >= 0), all(B[!na] >= 0),
          max(W, na.rm = TRUE) == 11, max(B, na.rm = TRUE) == 14, sum(W, na.rm = TRUE) == 614, sum(B, na.rm = TRUE) == 637,
          all((W[!na] > 0) == Wb[!na]), all((B[!na] > 0) == Bb[!na]))
cat(sprintf("  229 deployments, %d surveyed deployment-weeks (13 deployments with none); %d wolf and %d bear detections\n",
            sum(!na), sum(W, na.rm = TRUE), sum(B, na.rm = TRUE)))

cv <- as.data.table(read_excel(f[["Final_covs-Trimmed.xlsx"]], "Sheet 1"))
cv2 <- as.data.table(read_excel(f[["Final_covs-Trimmed.xlsx"]], "Sheet1"))
stopifnot(nrow(cv) == 229, ncol(cv) == 34, !anyDuplicated(cv$deployment_id), identical(cv$deployment_id, cv2$deployment_id),
          identical(cv$place, cv2$Place), identical(cv$place, as.numeric(1:229)),
          all(cv$Year %in% 1:4), all(cv$YYYY %in% 2009:2023), all(cv$FOV %in% 1:5),
          all(cv$land_type %in% c(24, 25, 26, 29)), all(cv$Heigth %in% c("Canopy", "Chest", "knee", "Knee")),
          sum(is.na(cv$AREA)) == 2, !anyNA(cv$PERCENTAGE), uniqueN(paste(cv$x, cv$y)) == 157,
          all(cv$x > 42.3 & cv$x < 42.9), all(cv$y > 40.1 & cv$y < 40.6),
          all(cv$elevation > 1600 & cv$elevation < 2700), max(table(sub("_[0-9]{3}_.*$", "", cv$deployment_id))) <= 8)
cv[, location := sprintf("L%03d", match(paste(x, y), unique(paste(x, y))))]   # 157 camera locations (paper: 151 sites, <= 15 m merged)
site_covs <- cv[, .(year = as.integer(YYYY), deployment_rank_at_site = as.integer(Year), camera_model = Model,
                    camera_height = tolower(Heigth), fov_score = as.integer(FOV),
                    decimalLongitude = x, decimalLatitude = y, elevation_m = elevation, slope_deg = slope, aspect_deg = aspect,
                    land_type_clc = as.integer(land_type), forest_pct_500m = PERCENTAGE, buffer_area_500m_m2 = AREA,
                    dist_main_roads_m = dist_from_m_rds, dist_f_rds_m = dist_from_f_rds, dist_urban_m = dist_from_ua,
                    dist_fe_m = dist_from_fe, dist_dump_m = dist_from_dump,
                    human_rate = human.rate, vehicle_rate = vehicle.rate)]

y <- array(c(W, B), dim = c(229, 104, 2), dimnames = list(cv$deployment_id, NULL, c("CANLUP", "URSARC")))
long <- array_to_eco(y, site_ids = cv$deployment_id, site_covs = site_covs)
long[, cluster_id := cv$location[match(unit, cv$deployment_id)]]; long <- order_eco(long)
stopifnot(nrow(long) == 2 * sum(!na), uniqueN(long$unit) == 216, sum(long$y) == 614 + 637,
          long[, .N, by = .(unit, occasion)][, all(N == 2)])

taxa <- make_taxa(c("CANLUP", "URSARC"), c("Canis lupus", "Ursus arctos"), vernacularName = c("Grey wolf", "Brown bear"),
                  taxon_iucnCategory = c("LC", "LC"))
dataset <- list(
  title = "Weekly camera-trap counts of grey wolf and brown bear at 229 deployments, Sarikamis-Allahuekber Mountains, northeastern Turkiye, 2009-2023",
  creator = "Blount, Judson D.; Green, Austin M.; Chynoweth, Mark; Coban, Emrah; Kusak, Josip; Sekercioglu, Cagan H.",
  pubDate = "2025", sourceURL = "https://doi.org/10.5281/zenodo.14618279",
  citation = "Blount, J. D., Green, A. M., Chynoweth, M., Coban, E., Kusak, J. & Sekercioglu, C. H. (2025). Combining N-mixture and occupancy analysis offers a more complete picture of carnivore habitat use in Northeastern Turkiye. PLOS One 20(5), e0320768. https://doi.org/10.1371/journal.pone.0320768. Data: Zenodo https://doi.org/10.5281/zenodo.14618279 (CC BY 4.0).",
  paperDOI = "10.1371/journal.pone.0320768", dataDOI = "10.5281/zenodo.14618279",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Long-term camera trapping (2009-2023) on the Kars-Ardahan plateau around Sarikamis, northeastern Turkiye, in and around the Sarikamis-Allahuekber Mountains National Park: 229 camera deployments (the paper: 151 sites, at most four deployments per site, one per year, 25,471 survey days) in 2-km2 grid cells along landscape features. The deposit gives, per deployment, the number of independent wolf and bear detection events in each seven-day window of the deployment (o1 = first week), with deployment covariates: camera model, height and field-of-view score, year, topography, CORINE land type, forest cover within 500 m, distances to main roads, urban areas and the town dump, and human and vehicle trap rates at the same camera. Used in the paper for N-mixture models of site-use intensity next to occupancy models on the 0/1 versions.",
  samplingProtocol = "Unbaited camera traps (Reconyx PC900 / HPX2, Keepguard KG891) at canopy, chest or knee height on trees facing dirt roads and trails in randomly chosen 2-km2 grid cells, left for 1-728 days (mean 111); independent detection events separated by 30 min (wolf) or 10 min (bear); counts summed over seven-day occasions from the first deployment day.",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A deployment-week is surveyed iff the cell is non-NA in the count matrices; NA cells are the trailing weeks after the camera stopped. The matrices carry no row ids; they and the covariate sheet (229 rows each, 13 matrix rows entirely NA) are taken to be in the same deployment order, as the authors' unmarked inputs.",
  responseType = "count", unitKind = "site", closure = "occasion",
  geographicCoverage = "Sarikamis-Allahuekber Mountains National Park and surrounding forest, Kars Province, northeastern Turkiye (about 40.2-40.5 N, 42.4-42.8 E)",
  temporalCoverage = "2009/2023",
  coordinatesCoarsened = list(value = FALSE, method = "kept as deposited (exact camera locations); neither taxon is IUCN CR/EN/VU"),
  crs = "EPSG:4326",
  covariateNote = "unit_year = calendar year of the deployment; unit_deployment_rank_at_site = the deposit's Year column (1-4, the deployment's rank among the deployments kept at its site); unit_fov_score 1-5 (1 = less than one car length, 3 = a full vehicle, 5 = several car lengths); unit_land_type_clc = CORINE level-3 code (24 coniferous forest, 25 mixed forest, 26 natural grassland, 29 transitional woodland-shrub); unit_forest_pct_500m and unit_buffer_area_500m_m2 from CORINE 2018 within a 500-m buffer (the area is NA for two deployments); cluster_id = camera location (one of 157 distinct coordinate pairs; the paper merges locations within 15 m into 151 sites); unit_dist_f_rds_m and unit_dist_fe_m are the deposit's dist_from_f_rds and dist_from_fe (not defined in the paper; likely forest roads and forest edge); unit_human_rate / unit_vehicle_rate = human and vehicle trap rates at the deployment, computed by the authors from the same cameras (not from the carnivore detections).",
  notes = "Occasions are deployment-relative seven-day windows; no week start dates are deposited, so there is no date column. The paper reports 652 wolf and 688 bear detections in total; the deposited weekly counts sum to 614 and 637 (the independence filter, or deployments trimmed to four per site). Lynx is in the sibling table blount_2025_neturkiye_lynx_occ (0/1 only: the lynx count file has a different shape and cannot be aligned to the deployments).",
  notShipped = list(`Wolf.Bi, Bear.Bi` = "0/1 versions, equal to y > 0 in every surveyed cell",
                    `Lynx.Count(7-Day).xlsx` = "215 x 472 with no ids: cannot be aligned to the 229 deployments",
                    `Lynx.Bi(7-Day).xlsx` = "shipped as blount_2025_neturkiye_lynx_occ (a different responseType)",
                    `scaled_*` = "z-scores of the deposited covariates", `OBJECTID.x, OBJECTID.y, place, placename` = "GIS join keys, row index, mostly empty names"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/blount_2025_neturkiye_carniv_count.R")

stage_dict_row(TABLE,
  description = "Weekly counts of independent grey wolf and brown bear camera-trap detections at 229 deployments (2009-2023) in and around Sarikamis-Allahuekber Mountains National Park, northeastern Turkiye, up to 104 seven-day occasions per deployment, with camera, topographic, land-cover, distance and human-activity covariates.",
  url = "https://doi.org/10.5281/zenodo.14618279",
  reference = "Blount, J. D., Green, A. M., Chynoweth, M., Coban, E., Kusak, J. & Sekercioglu, C. H. (2025). Combining N-mixture and occupancy analysis offers a more complete picture of carnivore habitat use in Northeastern Turkiye. PLOS One 20(5), e0320768.",
  doi_paper = "10.1371/journal.pone.0320768", doi_data = "10.5281/zenodo.14618279",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Matrices have no row ids; aligned to the covariate sheet by row order (229 each). 13 deployments have no surveyed week. Lynx counts not alignable (215 x 472); lynx 0/1 in blount_2025_neturkiye_lynx_occ.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture (community counts)",
  sampling_protocol = "camera_trap", design = "Single-season (up to 104 seven-day occasions per deployment)", realm = "Terrestrial", country = "TUR",
  coordinates = "As published", notes = "Deployment = unit (one per site per year); occasions deployment-relative. Wolf and bear counts; lynx in the sibling table.")
