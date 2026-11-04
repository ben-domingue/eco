#!/usr/bin/env Rscript
# Table:  blount_2025_neturkiye_lynx_occ
# Source: Zenodo 10.5281/zenodo.14618279 (Blount, 2025-01-08, CC BY 4.0). See
#         data/blount_2025_neturkiye_carniv_count.R for the full source, paper and file
#         description; this script is the sibling for the Eurasian lynx.
# Paper:  Blount et al. (2025). PLOS One 20(5), e0320768, doi:10.1371/journal.pone.0320768.
# Data:   Lynx.Bi(7-Day).xlsx: 229 deployments x o1..o104 seven-day occasions, 0/1, the same
#         NA pattern as the wolf and bear matrices (asserted); 128 detection-weeks.
#         Lynx.Count(7-Day).xlsx: 215 x 472, no ids, two rows with more than 104 surveyed
#         weeks; it cannot be aligned to the 229 deployments and is not shipped, so lynx is a
#         detection table, not a count table like its siblings. Covariates: Final_covs-Trimmed.
# Mapping: unit = deployment_id, taxon = LYNLYN, occasion = seven-day window 1..104, y = 0/1
#   (responseType detection), one period, deposited_matrix survey evidence, the same 20 unit_
#   covariates as the count table. Coordinates as deposited (exact; lynx is IUCN LC); cluster_id = camera location (157 distinct coordinate pairs).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "blount_2025_neturkiye_lynx_occ"
BASE <- "https://zenodo.org/api/records/14618279/files/%s/content"
FILES <- c("Lynx.Bi(7-Day).xlsx", "Wolf.Count(7-Day).xlsx", "Lynx.Count(7-Day).xlsx", "Final_covs-Trimmed.xlsx")
f <- sapply(FILES, function(x) download_cached(sprintf(BASE, utils::URLencode(x, reserved = TRUE)), TABLE, x))
rd <- function(x) { d <- read_excel(f[[x]]); stopifnot(identical(names(d), paste0("o", seq_len(ncol(d))))); suppressWarnings(matrix(as.numeric(as.matrix(d)), nrow(d))) }

Lb <- rd("Lynx.Bi(7-Day).xlsx"); W <- rd("Wolf.Count(7-Day).xlsx"); L <- rd("Lynx.Count(7-Day).xlsx")
na <- is.na(Lb)
stopifnot(dim(Lb) == c(229, 104), identical(na, is.na(W)), sum(!na) == 3540, sum(rowSums(!na) == 0) == 13,
          all(Lb[!na] %in% 0:1), sum(Lb, na.rm = TRUE) == 128,
          all(apply(na, 1, function(r) all(diff(as.integer(r)) >= 0))),
          dim(L) == c(215, 472), sum(rowSums(!is.na(L)) > 104) == 2, sum(L, na.rm = TRUE) == 173)
cat(sprintf("  %d surveyed deployment-weeks, %d with a lynx detection at %d deployments\n", sum(!na), sum(Lb, na.rm = TRUE), sum(rowSums(Lb, na.rm = TRUE) > 0)))

cv <- as.data.table(read_excel(f[["Final_covs-Trimmed.xlsx"]], "Sheet 1"))
stopifnot(nrow(cv) == 229, !anyDuplicated(cv$deployment_id), identical(cv$place, as.numeric(1:229)),
          uniqueN(paste(cv$x, cv$y)) == 157, sum(is.na(cv$AREA)) == 2)
cv[, location := sprintf("L%03d", match(paste(x, y), unique(paste(x, y))))]   # 157 camera locations (paper: 151 sites, <= 15 m merged)
site_covs <- cv[, .(year = as.integer(YYYY), deployment_rank_at_site = as.integer(Year), camera_model = Model,
                    camera_height = tolower(Heigth), fov_score = as.integer(FOV),
                    decimalLongitude = x, decimalLatitude = y, elevation_m = elevation, slope_deg = slope, aspect_deg = aspect,
                    land_type_clc = as.integer(land_type), forest_pct_500m = PERCENTAGE, buffer_area_500m_m2 = AREA,
                    dist_main_roads_m = dist_from_m_rds, dist_f_rds_m = dist_from_f_rds, dist_urban_m = dist_from_ua,
                    dist_fe_m = dist_from_fe, dist_dump_m = dist_from_dump,
                    human_rate = human.rate, vehicle_rate = vehicle.rate)]
dimnames(Lb) <- list(cv$deployment_id, NULL)
long <- array_to_eco(Lb, taxon = "LYNLYN", site_ids = cv$deployment_id, site_covs = site_covs)
long[, cluster_id := cv$location[match(unit, cv$deployment_id)]]; long <- order_eco(long)
stopifnot(nrow(long) == sum(!na), uniqueN(long$unit) == 216, sum(long$y) == 128)

taxa <- make_taxa("LYNLYN", "Lynx lynx", vernacularName = "Eurasian lynx", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Weekly camera-trap detection of Eurasian lynx at 229 deployments, Sarikamis-Allahuekber Mountains, northeastern Turkiye, 2009-2023",
  creator = "Blount, Judson D.; Green, Austin M.; Chynoweth, Mark; Coban, Emrah; Kusak, Josip; Sekercioglu, Cagan H.",
  pubDate = "2025", sourceURL = "https://doi.org/10.5281/zenodo.14618279",
  citation = "Blount, J. D., Green, A. M., Chynoweth, M., Coban, E., Kusak, J. & Sekercioglu, C. H. (2025). Combining N-mixture and occupancy analysis offers a more complete picture of carnivore habitat use in Northeastern Turkiye. PLOS One 20(5), e0320768. https://doi.org/10.1371/journal.pone.0320768. Data: Zenodo https://doi.org/10.5281/zenodo.14618279 (CC BY 4.0).",
  paperDOI = "10.1371/journal.pone.0320768", dataDOI = "10.5281/zenodo.14618279",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Eurasian lynx detection / non-detection per seven-day window at the 229 camera deployments (2009-2023) of the Sarikamis long-term camera-trap study, northeastern Turkiye, with the same deployment covariates as the wolf and bear count table blount_2025_neturkiye_carniv_count. The deposit's lynx count matrix (215 x 472) cannot be aligned to the deployments, so lynx ships as 0/1 only; the paper's lynx N-mixture model used counts with a one-minute independence interval.",
  samplingProtocol = "Unbaited camera traps at canopy, chest or knee height facing dirt roads and trails in randomly chosen 2-km2 grid cells, 1-728 days per deployment; detection / non-detection per seven-day occasion from the first deployment day.",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A deployment-week is surveyed iff the cell is non-NA (trailing NA = camera stopped); identical to the wolf and bear matrices. No row ids: matrix and covariate sheet aligned by row order (229 each).",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Sarikamis-Allahuekber Mountains National Park and surrounding forest, Kars Province, northeastern Turkiye (about 40.2-40.5 N, 42.4-42.8 E)",
  temporalCoverage = "2009/2023",
  coordinatesCoarsened = list(value = FALSE, method = "kept as deposited (exact camera locations); lynx is IUCN LC"),
  crs = "EPSG:4326",
  covariateNote = "As in blount_2025_neturkiye_carniv_count: unit_year, unit_deployment_rank_at_site (1-4), camera model / height / field-of-view score, topography, CORINE level-3 land type, forest cover within 500 m, distances to main roads, dist_from_f_rds, urban areas, dist_from_fe and the town dump, human and vehicle trap rates at the same camera.",
  notes = "Deployment-relative seven-day occasions, no dates. The paper reports 190 lynx detections; the weekly 0/1 matrix has 128 detection-weeks and the unalignable count file sums to 173.",
  notShipped = list(`Lynx.Count(7-Day).xlsx` = "215 x 472 with no ids: cannot be aligned to the 229 deployments (two rows have more than 104 surveyed weeks)",
                    `Wolf / Bear files` = "shipped as blount_2025_neturkiye_carniv_count (counts)",
                    `scaled_*, OBJECTID.*, place, placename` = "derived z-scores, GIS keys, row index, mostly empty names"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/blount_2025_neturkiye_lynx_occ.R")

stage_dict_row(TABLE,
  description = "Eurasian lynx detection / non-detection per seven-day occasion at 229 camera deployments (2009-2023) in and around Sarikamis-Allahuekber Mountains National Park, northeastern Turkiye, with camera, topographic, land-cover, distance and human-activity covariates; sibling of the wolf and bear count table.",
  url = "https://doi.org/10.5281/zenodo.14618279",
  reference = "Blount, J. D., Green, A. M., Chynoweth, M., Coban, E., Kusak, J. & Sekercioglu, C. H. (2025). Combining N-mixture and occupancy analysis offers a more complete picture of carnivore habitat use in Northeastern Turkiye. PLOS One 20(5), e0320768.",
  doi_paper = "10.1371/journal.pone.0320768", doi_data = "10.5281/zenodo.14618279",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "0/1 only: the lynx count matrix (215 x 472, no ids) cannot be aligned to the deployments. Same survey set as blount_2025_neturkiye_carniv_count.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (up to 104 seven-day occasions per deployment)", realm = "Terrestrial", country = "TUR",
  coordinates = "As published", notes = "Sibling of the wolf/bear count table; lynx counts not alignable in the deposit.")
