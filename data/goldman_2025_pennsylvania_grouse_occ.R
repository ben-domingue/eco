#!/usr/bin/env Rscript
# Table:  goldman_2025_pennsylvania_grouse_occ
# Source: Dryad doi:10.5061/dryad.pzgmsbd0h (CC0 1.0, as shown on the Dryad page; published
#         2025-07-07). Goldman, J. et al. Data from: Does a decision support tool designed to
#         depict West Nile Virus risk explain variation in ruffed grouse (Bonasa umbellus) use of
#         managed forests?
# Paper:  Goldman, J. et al. (2025). Wildlife Biology, doi:10.1002/wlb3.01389. Autonomous
#         recording units (ARUs) in managed forest stands across Pennsylvania, April 2021 to
#         August 2023; ruffed grouse drumming detected in weekly blocks of recordings.
# Data:   Goldman-et-al-25-data.csv, 305 rows (point_id "RUGR nn" in 2021, "RUGR22_n", "RUGR23_n"; unique: each point was recorded
#         in one year only; 51 in 2021, 135 in 2022, 119 in 2023) x 28 columns, all described in
#         README.md: juliandate_b1-b5 (ordinal date of the first day of survey week k; weeks are
#         consecutive, 7 days apart at every point), occu_wk1-5 (detection 0/1, NA = "not
#         available"), pres_abs (= max of the weekly columns, asserted, not shipped),
#         mins_b1-5 (minutes of recording in week k), rec_duration (hours programmed per day),
#         stand variables (basal area, stem densities, stand age; NA where not measured) and
#         500 m / 5 km landscape variables (connectivity, % WNV high-risk pixels, % mixed oak,
#         % northern hardwood). No coordinates.
#         Quirk: 39 week cells are 0 with 0 minutes of recording (no recording, not a survey),
#         and 18 cells are NA despite minutes > 0.
# Mapping (standard: single-season occupancy, E9 core):
#   unit = point_id; taxon = BONUMB; period = year (one per point; __periods carries the year);
#   occasion = survey week 1..5; y = occu_wk. date = year + juliandate_bk, the first day of the
#   week (exact: the ordinal is deposited, the year is the row's year). obs_minutes_recorded =
#   mins_bk; unit_rec_duration_h and the stand and landscape variables as unit_.
#   Survey evidence: effort_table. A survey is a week with y not NA AND minutes recorded > 0:
#   the 39 zero-minute zeros are not surveys (dropped, asserted none is a detection) and the 55
#   NA cells (18 of them with minutes > 0) have no row.
#   closure = closed within a point-season (the authors' single-season occupancy over five
#   weeks of the drumming season). wnv_high_500m is a map product of a West Nile Virus decision
#   support tool, not derived from these detections, and ships as a unit covariate.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldman_2025_pennsylvania_grouse_occ"
dir <- download_dryad("10.5061/dryad.pzgmsbd0h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Goldman-et-al-25-data\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f, na.strings = c("NA", "N/A", ""))
stopifnot(nrow(raw) == 305, !anyDuplicated(raw$point_id), all(grepl("^RUGR", raw$point_id)),
          identical(as.integer(table(raw$year)), c(51L, 135L, 119L)), identical(sort(unique(raw$year)), 2021:2023))
yc <- paste0("occu_wk", 1:5); mc <- paste0("mins_b", 1:5); jc <- paste0("juliandate_b", 1:5)
Y <- as.matrix(raw[, ..yc]); M <- as.matrix(raw[, ..mc]); J <- as.matrix(raw[, ..jc])
stopifnot(all(Y %in% c(0, 1, NA)), !anyNA(M), !anyNA(J), all(M >= 0),
          all(apply(J, 1, diff) == 7),
          identical(as.numeric(apply(Y, 1, max, na.rm = TRUE)), as.numeric(raw$pres_abs)),
          sum(!is.na(Y) & M == 0) == 39, all(Y[!is.na(Y) & M == 0] == 0),
          sum(is.na(Y)) == 55, sum(is.na(Y) & M > 0) == 18)
Y[M == 0] <- NA                                        # no recording that week: not a survey
dimnames(Y) <- list(raw$point_id, NULL)
sc <- as.data.frame(raw[, .(rec_duration_h = rec_duration, basal_area_m2_ha = Basal_m2_ha,
                            stem_density = avg_stem_dens, stem_density_lt_1_5m = `stems_less_1.5m`,
                            stem_density_gt_1_5m = `stems_greater_1.5m`, stand_age_yr = stand_age,
                            connectivity_5km = connx5km, wnv_high_risk_500m = wnv_high_500m,
                            pct_mixed_oak_500m = p_mo, pct_northern_hardwood_500m = p_nh)])
long <- array_to_eco(Y, taxon = "BONUMB", site_ids = raw$point_id, site_covs = sc,
                     obs_covs = list(minutes_recorded = M))
long[, period := match(raw$year[match(unit, raw$point_id)], 2021:2023)]
D <- matrix(format(as.IDate(paste0(raw$year - 1, "-12-31")) + as.vector(J)), nrow = nrow(J))
long[, date := D[cbind(match(unit, raw$point_id), occasion)]]
stopifnot(nrow(long) == 305 * 5 - 55 - 39, uniqueN(long$unit) == 299,   # 6 points have no recorded week
          sum(long$y) == sum(Y, na.rm = TRUE), all(long$obs_minutes_recorded > 0),
          !anyNA(long$date), substr(long$date, 1, 4) == as.character(2020 + long$period))
periods <- data.table(period = 1:3, period_year = 2021:2023)
taxa <- make_taxa("BONUMB", "Bonasa umbellus", vernacularName = "Ruffed grouse")
dataset <- list(
  title = "Ruffed grouse drumming detections by autonomous recorders at 299 managed-forest points in Pennsylvania, five weekly occasions, 2021-2023",
  creator = "Goldman, Jacob; McNeil, Darin; Chronister, Lauren; Koleck, Randall; Lapp, Samuel; Larkin, Jeffery; Tyl, Reina; Kitzes, Justin",
  pubDate = "2025", doi = "10.5061/dryad.pzgmsbd0h", sourceURL = "https://doi.org/10.5061/dryad.pzgmsbd0h",
  citation = "Goldman, J. et al. (2025). Data from: Does a decision support tool designed to depict West Nile Virus risk explain variation in ruffed grouse (Bonasa umbellus) use of managed forests? [Dataset]. Dryad. https://doi.org/10.5061/dryad.pzgmsbd0h",
  paperDOI = "10.1002/wlb3.01389",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Weekly detection/non-detection of ruffed grouse (Bonasa umbellus) drumming on autonomous recording units at 299 points (six more deposited points have no recorded week) in managed forest stands across Pennsylvania, each recorded for five consecutive weeks in one spring of 2021-2023, with minutes recorded per week, stand structure and landscape covariates including a West Nile Virus risk map.",
  samplingProtocol = "Autonomous recording units programmed to record 1.5 or 2 h per day in managed forest stands; recordings processed and verified for ruffed grouse drumming and summarised as detection per survey week, five consecutive weeks per point.",
  samplingProtocolCode = "acoustic", surveyEvidence = "effort_table", responseType = "detection",
  unitKind = "site", closure = "closed",
  closureNote = "five consecutive weeks of one drumming season per point; the authors fit single-season occupancy",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_minutes_recorded",
  geographicCoverage = "Managed forest stands, Commonwealth of Pennsylvania, USA; no coordinates deposited",
  temporalCoverage = "2021-04/2023-08",
  notShipped = list(pres_abs = "detection in any week, the maximum of the weekly columns (asserted)",
                    zero_minute_weeks = "39 week cells coded 0 with 0 minutes of recording: no recording, so not a survey"),
  notes = "A survey is a week with a non-missing detection value and minutes recorded > 0. 39 deposited zeros have no recording behind them and are dropped; 18 NA weeks had recording minutes but no detection value and have no row. date is the first day of the survey week (deposited ordinal date + the point's year). Six of the 305 points have no week with both a value and a recording and so have no rows. Each point was surveyed in one year, so period is the year with no revisits across periods.")
dataset$temporalCoverage <- paste(substr(min(long$date), 1, 7), substr(max(long$date), 1, 7), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/goldman_2025_pennsylvania_grouse_occ.R")
stage_dict_row(TABLE,
  description = "Weekly ARU detection/non-detection of ruffed grouse drumming at 299 managed-forest points in Pennsylvania, 2021-2023, five weeks per point, with recording minutes, stand and landscape covariates.",
  url = "https://doi.org/10.5061/dryad.pzgmsbd0h",
  reference = "Goldman, J. et al. (2025). Does a decision support tool designed to depict West Nile Virus risk explain variation in ruffed grouse (Bonasa umbellus) use of managed forests? Wildlife Biology.",
  doi_paper = "10.1002/wlb3.01389", doi_data = "10.5061/dryad.pzgmsbd0h",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Acoustic single-season occupancy; zero-minute weeks dropped as not surveyed.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy",
  sampling_protocol = "acoustic", design = "Single-season (5 weekly ARU occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Drumming detections from ARUs; effort in minutes recorded.")
