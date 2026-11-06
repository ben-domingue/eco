#!/usr/bin/env Rscript
# Tables: thomas_2025_boreal_moose_occ, thomas_2025_boreal_moose_ms
# Source: Dryad doi:10.5061/dryad.bk3j9kdpn (CC0 1.0, as shown on the Dryad page; published
#         2025-04-24). Thomas, J., Reid, M., Barclay, R. & Jung, T. Data from: Influence of
#         reproductive status on occupancy of salvage-logged boreal forest by moose.
# Paper:  Thomas, J.P., Reid, M.L., Barclay, R.M.R. & Jung, T.S. (2025). Ecology and Evolution 15:
#         e71302, doi:10.1002/ece3.71302. Camera traps in salvage-logged and unsalvaged burned
#         boreal forest stands; single-state and multi-state (female with / without calf)
#         occupancy in PRESENCE (README).
# Data:   MooseOccupancy_SingleState.csv (89 sites x 5 fifteen-day survey periods: 0 / 1 = moose of
#         any sex or status detected / NA = no survey data); MooseOccupancy_MultiState.csv (the
#         same 89 x 5: 0 no female detected, 1 female, 2 female with calf, NA); Detection_
#         Predictor_Variable.csv (survey month per period); Occupancy_Predictor_Variables.csv
#         (stand type, stand age, canopy %, deciduous stems /10 m2, lateral cover %, CWD count,
#         distance to water km, linear disturbance density km/km2, forest cover % within 500 m,
#         bears = grizzly and black bear detections per day on the same cameras). README.md
#         defines every column. Asserted: identical site order and NA pattern in both files; a
#         female (1 or 2) is never recorded where the single-state value is 0; 22 survey periods
#         have a moose but no female (males or unsexed).
# Mapping (standard: occupancy and multi-state occupancy, E9 core): two tables, one per response
#   (the single-state file also counts males, so it is not a recode of the multi-state file).
#   unit = site ID; taxon = ALCALC; occasion = 15-day survey period 1..5; y = the cell (state
#   code in the _ms table, stateCodes from the README); NA = no row; obs_month = survey month.
#   unit_: the site covariates except bears. Survey evidence: deposited_matrix.
#   Not shipped: bears, a detection rate of other species on the same cameras (processing
#   guide). No coordinates; moose is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/thomas_2025_boreal_moose.R"
dir <- download_dryad("10.5061/dryad.bk3j9kdpn", "thomas_2025_boreal_moose")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f, header = TRUE) }
s <- rf("MooseOccupancy_SingleState\\.csv"); m <- rf("MooseOccupancy_MultiState\\.csv")
dv <- rf("Detection_Predictor_Variable\\.csv"); ov <- rf("Occupancy_Predictor_Variables\\.csv")
stopifnot(nrow(s) == 89, identical(s$`site ID`, m$`site ID`), identical(s$`site ID`, dv$`site ID`), identical(s$`site ID`, ov$`site ID`),
          !anyDuplicated(s$`site ID`))
S <- as.matrix(s[, -1]); M <- as.matrix(m[, -1]); MO <- as.matrix(dv[, -1])
stopifnot(identical(is.na(S), is.na(M)), all(S %in% c(0, 1, NA)), all(M %in% c(0, 1, 2, NA)),
          sum(M > 0 & S == 0, na.rm = TRUE) == 0, sum(S == 1 & M == 0, na.rm = TRUE) == 22, !anyNA(MO[!is.na(S)]))
ids <- s$`site ID`; dimnames(S) <- dimnames(M) <- list(ids, NULL)
sc <- as.data.frame(ov[, .(stand_type, stand_age, canopy_pct = canopy, deciduous_stems_10m2 = deciduous_stems, lateral_cover_pct = lateral_cover,
                           cwd_count = CWD, water_distance_km = water_distance, linear_density_km_km2 = linear_density, forest_cover_pct_500m = forest_cover)])
taxa <- make_taxa("ALCALC", "Alces alces", vernacularName = "Moose",
                  taxonRemarks = "the deposit names Alces americanus (North American moose), which GBIF treats within Alces alces")
base <- list(
  creator = "Thomas, Julie P.; Reid, Mary L.; Barclay, Robert M. R.; Jung, Thomas S.", pubDate = "2025",
  doi = "10.5061/dryad.bk3j9kdpn", sourceURL = "https://doi.org/10.5061/dryad.bk3j9kdpn",
  citation = "Thomas, J., Reid, M., Barclay, R., & Jung, T. (2025). Data from: Influence of reproductive status on occupancy of salvage-logged boreal forest by moose (Alces americanus) [Dataset]. Dryad. https://doi.org/10.5061/dryad.bk3j9kdpn",
  paperDOI = "10.1002/ece3.71302",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Camera traps in salvage-logged (low and high retention) and unsalvaged burned boreal forest stands, June to September; detections summarised per 15-day survey period.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", unitKind = "site", closure = "closed",
  closureNote = "one summer season (five 15-day periods), analysed as single-season occupancy", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Burned and salvage-logged boreal forest (see the paper); no coordinates deposited",
  temporalCoverage = "survey year not stated in the deposit; periods fall in June-September",
  notShipped = list(bears = "grizzly and black bear detection rate on the same cameras (an index from the same detections)"))
for (k in c("occ", "ms")) {
  TABLE <- paste0("thomas_2025_boreal_moose_", k)
  long <- array_to_eco(if (k == "occ") S else M, taxon = "ALCALC", site_ids = ids, site_covs = sc, obs_covs = list(month = MO))
  if (k == "ms") long[, y_raw := c("no female", "female", "female with calf")[y + 1L]]
  long <- order_eco(long)
  stopifnot(nrow(long) == sum(!is.na(S)))
  dataset <- c(base, list(
    title = if (k == "occ") "Camera-trap detections of moose (any sex) at 89 burned boreal forest sites, five 15-day periods in one summer" else
      "Female moose with and without calves on camera traps at 89 burned boreal forest sites: multi-state detections, five 15-day periods",
    abstract = if (k == "occ") "Detection/non-detection of moose of any sex or reproductive status per 15-day survey period at 89 camera sites in salvage-logged and unsalvaged burned boreal forest, with stand and landscape covariates and survey month; the companion multi-state table is thomas_2025_boreal_moose_ms." else
      "Multi-state detections of female moose (0 no female, 1 female without calf, 2 female with calf) per 15-day survey period at 89 camera sites in salvage-logged and unsalvaged burned boreal forest, with stand and landscape covariates and survey month; the any-moose table is thomas_2025_boreal_moose_occ.",
    responseType = ifelse(k == "occ", "detection", "state"),
    notes = ifelse(k == "occ", "Includes males and unsexed moose: 22 survey periods have a moose but no female.", "State 2 (female with calf) implies a detected female; males are not recorded in this table.")),
    if (k == "ms") list(stateCodes = list(`0` = "no female moose detected", `1` = "female moose detected without a calf", `2` = "female moose with calf detected")) else list())
  ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(TABLE, description = dataset$abstract, url = "https://doi.org/10.5061/dryad.bk3j9kdpn",
    reference = "Thomas, J. P., Reid, M. L., Barclay, R. M. R., & Jung, T. S. (2025). Influence of reproductive status on occupancy of salvage-logged boreal forest by moose (Alces americanus). Ecology and Evolution, 15, e71302.",
    doi_paper = "10.1002/ece3.71302", doi_data = "10.5061/dryad.bk3j9kdpn", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = if (k == "occ") "Single-state occupancy; companion multi-state table." else "Multi-state occupancy (reproductive status).", source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = if (k == "occ") "Single-season occupancy" else "Multi-state occupancy",
    sampling_protocol = "camera_trap", design = "Single-season (5 x 15-day periods)", realm = "Terrestrial",
    country = "CAN", coordinates = "None in source", notes = "Salvage logging after fire.")
}
