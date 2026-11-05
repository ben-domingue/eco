#!/usr/bin/env Rscript
# Table:  proudman_2026_illinois_coyote_count
# Source: Dryad, doi:10.5061/dryad.p8cz8wb5w, version 458048 (version 3, published 2026-08-14), licence
#         CC0 1.0 as shown on the Dryad page (the README defers to "the terms specified by Dryad").
# Paper:  Proudman, N. J. et al. (2026). Hierarchical habitat selection by coyotes: scale-dependent
#         responses to land cover, prey, and harvest. Journal of Biogeography (under review; no DOI).
# Data:   Camera_Deployment_Data.csv: 164 camera sites (Site.ID, sorted alphabetically), Study.Year
#           2021/22 (45), 2022/23 (50), 2023/24 (69; the README says "2024/25", the file and the deployment
#           dates say 2023/24), Habitat (CTAP stratum: Forest / Grassland / Wetland), Latitude/Longitude
#           (WGS84, 6 decimals), deployment begin/end dates (M/D/YYYY). Each site is deployed once.
#         Camera_Site_Data.csv: the same 164 Site.IDs in the same order (asserted): land cover areas (m2)
#           within 100 m / 1 km / 5 km buffers (NLCD 2019), edge_dist, dist_water (m), Harvest (county
#           trapper harvest per km2, from the Illinois trapper reports), road and housing density per
#           buffer, WTD_RAB (white-tailed deer detections per 100 trap nights at the camera), Human
#           Footprint and NDVI per buffer.
#         Coyote_Detection_History.csv: 164 rows x o1..o28, no id column; rows are the sites in alphabetical
#           order (README). Cell = number of coyote detections in camera-specific survey week k (week 1
#           starts on the deployment date); "n/a" = camera not active. Non-NA cells are a leading block
#           and their number equals ceiling((end - begin + 1) / 7) for every row (asserted), which is the
#           evidence that the id-less rows are in deployment order.
#         Effort_DetVariable.csv, TMIN_/TMAX_/PRCP_DetVariable.csv: 164 x 24 weeks (weeks 1-24 only): days
#           active in the week (0 to 7, half days at deployment and collection), mean daily min/max
#           temperature (C) and total precipitation (mm). Effort > 0 exactly where the history is non-NA
#           in weeks 1-24 (asserted); 126 active cells in weeks 25-28 have no effort or weather values.
# Mapping: unit = Site.ID, taxon = CANLAT, period = winter season (1 = 2021/22, 2 = 2022/23, 3 = 2023/24;
#   each unit is in one period), occasion = survey week 1..28 within the deployment, y = coyote detections
#   in the week (count; the README does not state the independence interval), date = first day of the week
#   (deployment begin date + 7 (k - 1)). surveyEvidence = deposited_matrix (n/a = camera not active).
#   obs_effort_days, obs_tmin_c, obs_tmax_c, obs_prcp_mm: weeks 1-24 (NA in weeks 25-28, not deposited).
#   unit_*: habitat stratum, coordinates, deployment dates and all site covariates as deposited.
#   Coordinates as published: Canis latrans is IUCN LC and the sites are a statewide survey network.
#   Not shipped: model outputs (the authors' site-use intensity estimates are not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "proudman_2026_illinois_coyote_count"

dir <- download_dryad("10.5061/dryad.p8cz8wb5w", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Camera_Deployment_Data.csv", "Camera_Site_Data.csv", "Coyote_Detection_History.csv",
  "Effort_DetVariable.csv", "PRCP_DetVariable.csv", "README.md", "TMAX_DetVariable.csv", "TMIN_DetVariable.csv")))

dep <- fread(file.path(dir, "Camera_Deployment_Data.csv"))
sit <- fread(file.path(dir, "Camera_Site_Data.csv"), colClasses = list(character = "Site.ID"))
dep[, Site.ID := as.character(Site.ID)]
stopifnot(nrow(dep) == 164, !anyDuplicated(dep$Site.ID), identical(dep$Site.ID, sort(dep$Site.ID)),
          identical(dep$Site.ID, sit$Site.ID), ncol(sit) == 38)
stopifnot(identical(as.vector(table(dep$Study.Year)), c(45L, 50L, 69L)),
          identical(names(table(dep$Study.Year)), c("2021/22", "2022/23", "2023/24")),
          all(dep$Habitat %in% c("Forest", "Grassland", "Wetland")))
dep[, begin := as.IDate(Camera.Deployment.Begin.Date, "%m/%d/%Y")][, end := as.IDate(Camera.Deployment.End.Date, "%m/%d/%Y")]
stopifnot(!anyNA(dep$begin), !anyNA(dep$end), all(dep$end > dep$begin))

H <- as.matrix(fread(file.path(dir, "Coyote_Detection_History.csv"), na.strings = c("n/a", "NA")))
stopifnot(identical(colnames(H), paste0("o", 1:28)), nrow(H) == 164)
rdw <- function(f) { m <- as.matrix(fread(file.path(dir, f))); stopifnot(dim(m) == c(164, 24), !anyNA(m)); m }
E <- rdw("Effort_DetVariable.csv"); TN <- rdw("TMIN_DetVariable.csv"); TX <- rdw("TMAX_DetVariable.csv"); PR <- rdw("PRCP_DetVariable.csv")
nh <- rowSums(!is.na(H))
stopifnot(all(apply(H, 1, function(r) { k <- sum(!is.na(r)); all(!is.na(r[seq_len(k)])) })),   # leading block
          identical(as.numeric(nh), ceiling((as.numeric(dep$end - dep$begin) + 1) / 7)),       # row alignment
          all((E > 0) == !is.na(H[, 1:24])), all(E >= 0 & E <= 7),
          sum(!is.na(H[, 25:28])) == 126, sum(!is.na(H)) == 3745,
          all(H >= 0, na.rm = TRUE), all(H == round(H), na.rm = TRUE))

pad <- function(m) cbind(m, matrix(NA_real_, 164, 4))
site_covs <- data.frame(habitat = dep$Habitat, decimalLatitude = dep$Latitude, decimalLongitude = dep$Longitude,
                        deploy_begin = as.character(dep$begin), deploy_end = as.character(dep$end),
                        as.data.frame(sit[, -1]))
long <- array_to_eco(H, taxon = "CANLAT", site_ids = dep$Site.ID, site_covs = site_covs,
                     obs_covs = list(effort_days = pad(E), tmin_c = pad(TN), tmax_c = pad(TX), prcp_mm = pad(PR)))
season <- c("2021/22" = 1L, "2022/23" = 2L, "2023/24" = 3L)
long[, period := season[dep$Study.Year[match(unit, dep$Site.ID)]]]
long[, date := as.character(dep$begin[match(unit, dep$Site.ID)] + 7L * (occasion - 1L))]
stopifnot(nrow(long) == 3745, uniqueN(long$unit) == 164, long[occasion <= 24, !anyNA(obs_effort_days)],
          long[occasion > 24, all(is.na(obs_effort_days))])
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))

taxa <- make_taxa("CANLAT", "Canis latrans", vernacularName = "Coyote")
stopifnot(identical(iucn_category(taxa$taxonID[1], "Canis latrans"), "LC"))
periods <- data.table(period = 1:3, season = names(season),
                      period_start = sapply(names(season), function(s) as.character(min(dep[Study.Year == s, begin]))),
                      period_end = sapply(names(season), function(s) as.character(max(dep[Study.Year == s, end]))),
                      n_cameras = as.integer(table(dep$Study.Year)))

dataset <- list(
  title = "Weekly coyote detections at 164 camera traps across Illinois, three winter seasons 2021/22 to 2023/24",
  creator = "Proudman, Nathan; Allen, Maximilian", pubDate = "2026",
  doi = "10.5061/dryad.p8cz8wb5w", sourceURL = "https://doi.org/10.5061/dryad.p8cz8wb5w",
  citation = "Proudman, N., & Allen, M. (2026). Camera trap detections and environmental covariates for modeling scale-dependent coyote (Canis latrans) site-use intensity [Dataset]. Dryad. https://doi.org/10.5061/dryad.p8cz8wb5w",
  paperDOI = NA,
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Illinois Natural History Survey statewide camera network (CTAP forest, grassland and wetland strata): 164 cameras, each deployed once for 13 to 28 weeks between November and June in 2021/22, 2022/23 or 2023/24. Number of coyote detections per camera-week, with weekly effort and weather and site land cover, prey (deer) and harvest covariates at three scales.",
  samplingProtocol = "One camera trap per site, deployed November to February and collected May to June; detections summarised in seven-day windows from the deployment date.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the authors fit N-mixture models treating each deployment's weeks as replicates of site-use intensity",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Illinois, USA (statewide)",
  temporalCoverage = "2021-12-13/2024-05-22",
  coordinatesCoarsened = list(value = FALSE, method = "as published (6 decimals); Canis latrans is IUCN LC"),
  effortColumn = "obs_effort_days",
  covariateNote = "y counts detections, not individuals; the independence interval is not stated. obs_* weather and effort cover weeks 1-24 only (the deposited files stop there); 126 active camera-weeks 25-28 have them NA. unit_Harvest is county trapper harvest per km2 from state reports; unit_WTD_RAB is deer detections per 100 trap nights at the camera.",
  notShipped = list(model_output = "the authors' site-use intensity estimates (not deposited)"),
  notes = "The detection history has no id column; its rows are matched to the deployments by alphabetical Site.ID as the README states, confirmed by every row's number of active weeks equalling its deployment length. The README's Study.Year '2024/25' is 2023/24 in the file.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/proudman_2026_illinois_coyote_count.R")
stage_dict_row(TABLE,
  description = "Weekly coyote (Canis latrans) detection counts at 164 Illinois camera traps over three winter seasons (2021/22 to 2023/24), with weekly effort and weather and multi-scale land cover, deer and harvest covariates.",
  url = "https://doi.org/10.5061/dryad.p8cz8wb5w",
  reference = "Proudman, N. J. et al. (2026). Hierarchical habitat selection by coyotes: scale-dependent responses to land cover, prey, and harvest. Journal of Biogeography (under review).",
  doi_paper = "", doi_data = "10.5061/dryad.p8cz8wb5w",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Detections per week (not individuals); effort and weather for weeks 1-24 only.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "camera_trap", design = "Multi-season (3 winter seasons, each camera in one; weekly occasions)",
  realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "y = detections per camera-week; id-less history aligned by alphabetical Site.ID.")
