#!/usr/bin/env Rscript
# Table:  smith_2024_florida_tegu_dynocc
# Source: Dryad doi:10.5061/dryad.jsxksn0kp (CC0 1.0, as shown on the Dryad page; published
#         2024-11-18). Smith, S., Miller, M., Waddle, H., Cooke, S., Yackel Adams, A.,
#         Currylow, A., Donmoyer, K. & Mazzotti, F. (2024). Using camera traps to estimate
#         site occupancy of invasive Argentine black and white tegus (Salvator merianae) in
#         South Florida. Code also on Zenodo doi:10.5281/zenodo.14147426.
# Paper:  Smith, S.N. et al. (2024). Using camera traps to estimate site occupancy of
#         invasive Argentine Black and White Tegus (Salvator merianae) in South Florida.
#         Southeastern Naturalist 23(4), doi:10.1656/058.023.0402. Dynamic occupancy
#         (unmarked::colext) of tegus at camera traps in Miami-Dade County, 2016-2019.
# Data:   SENA_final_submission.zip holding, per year 2016-2019: <yr>_detectionhistory
#         (scaled).csv (camera x 19 consecutive 14-day windows, 15 Feb - 1 Nov; 1/0/NA =
#         camera not running; "(scaled)" is the authors' file name, values are 0/1),
#         Camera trap effort_<yr>.csv (days active per window, 0.5-14, NA = not running),
#         <yr>Temp.csv and <yr>Precip.csv (mean daily temperature F and rainfall in per
#         window, all 87 cameras), Juliandate<yr>_brum.csv (window midpoint day, identical
#         for every camera); plus Baited4yr.csv (87 x 76 bait status 0/1 per window, no id
#         column, rows in SiteData order: asserted that SiteData order is the order the
#         authors' joins give), SiteData.csv (87 cameras: distances in m to agriculture,
#         to the US-1 underpass "core", to urban land, to the presumed release point, and
#         habitat Terrestrial/Levee/Disturbed), CPUEnt4yr.csv (one row per camera-year
#         surveyed: nearest live trap, its distance, agency and capture per unit effort),
#         TeguDynamicOccupancyModeling.R and .Rhistory (code). Detection rows per year:
#         56, 65, 77, 70 cameras (87 distinct).
#         Quirk: the 2019 effort file names camera C113-2B as "C113-2" (C113-2 is a
#         different camera with its own site row; the 2019 detection and CPUE files use
#         C113-2B); the effort row is assigned to C113-2B (both rows are complete).
#
# Mapping (standard: dynamic occupancy, E9 core):
#   unit = camera (TrapID); taxon = SALMER; period = year 1..4 (2016-2019, __periods);
#   occasion = 14-day window 1..19; y = detection; date = window start (ISO), with
#   obs_window_end. obs_: camera_days (days active in the window; effortColumn), baited,
#   temp_mean_f, precip_mean_in (raw values; the authors standardised them in code).
#   unit_: the four distances and habitat. period_ (camera x year): nearest live trap,
#   its distance, agency and CPUE (from a separate live-trapping programme; a covariate,
#   not an estimate from these detections). Survey evidence: effort table; a survey
#   exists where days active > 0, which is exactly where the detection matrix is not NA
#   (asserted). No coordinates deposited. Not shipped: Juliandate files (window midpoint,
#   derivable from date), code files.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "smith_2024_florida_tegu_dynocc"
dir <- download_dryad("10.5061/dryad.jsxksn0kp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zip <- list.files(dir, "^SENA_final_submission\\.zip$", recursive = TRUE, full.names = TRUE)
stopifnot(length(zip) == 1)
ex <- file.path(dirname(zip), "unz"); if (!dir.exists(ex)) unzip(zip, exdir = ex)
src <- file.path(ex, "SENA final submission")
rd <- function(f) { d <- fread(file.path(src, f), encoding = "UTF-8"); setnames(d, sub("^﻿", "", names(d))); d }

site <- rd("SiteData.csv")
stopifnot(nrow(site) == 87, !anyDuplicated(site$TrapID), setequal(site$Habitat, c("Terrestrial", "Levee", "Disturbed")))
bait <- as.matrix(rd("Baited4yr.csv")); stopifnot(identical(dim(bait), c(87L, 76L)), all(bait %in% 0:1))
cpue <- rd("CPUEnt4yr.csv"); stopifnot(nrow(cpue) == 268, identical(sort(unique(cpue$Year)), 2016:2019), !anyNA(cpue$CPUE))

YRS <- 2016:2019; NCAM <- c(56L, 65L, 77L, 70L); NDET <- c(114L, 60L, 86L, 120L)
order_ids <- character(); recs <- list()
for (k in seq_along(YRS)) {
  yr <- YRS[k]
  d <- rd(sprintf("%d_detectionhistory(scaled).csv", yr)); setnames(d, 1, "TrapID")
  e <- rd(sprintf("Camera trap effort_%d.csv", yr)); setnames(e, 1, "TrapID")
  tt <- rd(sprintf("%dTemp.csv", yr)); setnames(tt, 1, "TrapID")
  pp <- rd(sprintf("%dPrecip.csv", yr)); setnames(pp, 1, "TrapID")
  if (yr == 2019) { stopifnot(setdiff(e$TrapID, d$TrapID) == "C113-2", setdiff(d$TrapID, e$TrapID) == "C113-2B"); e[TrapID == "C113-2", TrapID := "C113-2B"] }
  stopifnot(nrow(d) == NCAM[k], ncol(d) == 20, setequal(d$TrapID, e$TrapID), all(d$TrapID %in% site$TrapID),
            identical(tt$TrapID, site$TrapID), identical(pp$TrapID, site$TrapID), ncol(tt) == 20, ncol(pp) == 20)
  win <- tstrsplit(names(d)[-1], "_")
  ws <- as.IDate(win[[1]]); we <- as.IDate(win[[2]])
  stopifnot(length(ws) == 19, ws[1] == as.IDate(sprintf("%d-02-15", yr)), all(diff(ws) %in% 13:15), all(we >= ws))
  dm <- as.matrix(d[, -1]); em <- as.matrix(e[match(d$TrapID, TrapID), -1])
  stopifnot(all(dm %in% c(0, 1, NA)), identical(unname(is.na(dm)), unname(is.na(em))), all(em[!is.na(em)] > 0 & em[!is.na(em)] <= 14),
            sum(dm, na.rm = TRUE) == NDET[k])
  order_ids <- c(order_ids, setdiff(d$TrapID, order_ids))
  tm <- as.matrix(tt[match(d$TrapID, TrapID), -1]); pm <- as.matrix(pp[match(d$TrapID, TrapID), -1])
  bm <- bait[match(d$TrapID, site$TrapID), (k - 1) * 19 + 1:19]
  recs[[k]] <- data.table(unit = rep(d$TrapID, 19), period = k, occasion = rep(1:19, each = nrow(d)),
                          y = as.vector(dm), date = rep(format(ws), each = nrow(d)), obs_window_end = rep(format(we), each = nrow(d)),
                          obs_camera_days = as.vector(em), obs_baited = as.vector(bm),
                          obs_temp_mean_f = as.vector(tm), obs_precip_mean_in = as.vector(pm))
}
stopifnot(identical(order_ids, site$TrapID))   # Baited4yr.csv rows are in this order
long <- rbindlist(recs)[!is.na(y)]
stopifnot(nrow(long) == 920 + 1090 + 1288 + 1229, sum(long$y) == sum(NDET), !anyNA(long$obs_baited), !anyNA(long$obs_temp_mean_f))
long[, y := as.integer(y)][, taxon := "SALMER"]
setnames(cpue, c("Trap", "Dist", "Affiliation", "CPUE"), c("period_live_trap", "period_live_trap_dist_m", "period_live_trap_agency", "period_live_trap_cpue"))
cpue[, period := Year - 2015L]
stopifnot(nrow(unique(long[, .(unit, period)])) == 268, nrow(merge(unique(long[, .(unit, period)]), cpue, by.x = c("unit", "period"), by.y = c("CamTrap", "period"))) == 268)
long <- merge(long, cpue[, .(unit = CamTrap, period, period_live_trap, period_live_trap_dist_m, period_live_trap_agency, period_live_trap_cpue)], by = c("unit", "period"))
long <- merge(long, site[, .(unit = TrapID, unit_dist_agriculture_m = disttoag, unit_dist_core_m = disttocore,
                             unit_dist_urban_m = disttourban, unit_dist_release_point_m = disttorrp, unit_habitat = Habitat)], by = "unit")
stopifnot(nrow(long) == 4527, uniqueN(long$unit) == 87)

taxa <- make_taxa("SALMER", "Salvator merianae", vernacularName = "Argentine black and white tegu", taxon_nativeStatus = "introduced (invasive) in Florida")
periods <- data.table(period = 1:4, year = YRS, n_cameras = NCAM, start = sprintf("%d-02-15", YRS), end = sprintf("%d-11-02", YRS))

dataset <- list(
  title = "Camera-trap detections of invasive Argentine black and white tegus at 87 cameras in Miami-Dade County, Florida, in 14-day windows, 2016-2019",
  creator = "Smith, Samantha N.; Miller, Melissa A.; Waddle, Hardin; Cooke, Sarah; Yackel Adams, Amy; Currylow, Andrea; Donmoyer, Kevin; Mazzotti, Frank",
  pubDate = "2024", doi = "10.5061/dryad.jsxksn0kp", sourceURL = "https://doi.org/10.5061/dryad.jsxksn0kp",
  citation = "Smith, S., Miller, M., Waddle, H., Cooke, S., Yackel Adams, A., Currylow, A., Donmoyer, K., & Mazzotti, F. (2024). Using camera traps to estimate site occupancy of invasive Argentine black and white tegus (Salvator merianae) in South Florida [Dataset]. Dryad. https://doi.org/10.5061/dryad.jsxksn0kp",
  paperDOI = "10.1656/058.023.0402",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the invasive Argentine black and white tegu (Salvator merianae) at 87 camera traps (56-77 per year) in Miami-Dade County, Florida, in nineteen consecutive 14-day windows from mid-February to early November each year, 2016-2019, with days active per window, bait status, mean temperature and rainfall per window, distances to agriculture, an underpass, urban land and the presumed release point, habitat, and the capture rate of the nearest live trap each year. The paper fit dynamic occupancy models: detection peaked in June, lures did not affect detection, and occupancy did not change across years.",
  samplingProtocol = "Camera traps with and without lures, operated February to November; detections aggregated by the authors to 14-day windows, with the number of days each camera was active in the window.",
  samplingProtocolCode = "camera_trap", occasionLength = "14 days", effortColumn = "obs_camera_days",
  surveyEvidence = "effort_table", responseType = "detection", unitKind = "site",
  closure = "period (year; the paper's colext primary period)",
  geographicCoverage = "Miami-Dade County, South Florida, USA (Everglades margin, C-113 canal, L-31 levee, US-1 corridor); no coordinates deposited",
  temporalCoverage = "2016-02-15/2019-11-02",
  coordinatesCoarsened = NA,
  notShipped = list(`Juliandate<yr>_brum.csv` = "window midpoint day of year, identical across cameras, derivable from date",
                    `TeguDynamicOccupancyModeling.R, .Rhistory` = "analysis code",
                    standardised_covariates = "the authors standardise temperature and rainfall in code; raw values are shipped"),
  notes = "The 2019 effort file labels camera C113-2B as C113-2; the row is assigned to C113-2B (C113-2 is a separate camera surveyed 2016-2018; the 2019 detection and live-trap files use C113-2B). obs_baited is from Baited4yr.csv, whose 87 unlabelled rows follow SiteData.csv order (asserted equal to the order of first appearance across the yearly detection files, which is how the authors align it). The last window of each year runs to 1-2 November.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/smith_2024_florida_tegu_dynocc.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of the invasive Argentine black and white tegu (Salvator merianae) at 87 camera traps in Miami-Dade County, Florida, in 19 fourteen-day windows per year, 2016-2019, with camera-days per window, bait status, temperature, rainfall, distances to landscape features, habitat and yearly live-trap capture rates.",
  url = "https://doi.org/10.5061/dryad.jsxksn0kp",
  reference = "Smith, S. N., Miller, M. A., Waddle, H., Cooke, S., Yackel Adams, A. A., Currylow, A., Donmoyer, K., & Mazzotti, F. (2024). Using camera traps to estimate site occupancy of invasive Argentine Black and White Tegus (Salvator merianae) in South Florida. Southeastern Naturalist, 23(4).",
  doi_paper = "10.1656/058.023.0402", doi_data = "10.5061/dryad.jsxksn0kp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Invasive reptile, dynamic occupancy. One mislabelled camera id in the 2019 effort file corrected. No coordinates deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Dynamic occupancy (colext)",
  sampling_protocol = "camera_trap", design = "Multi-season (4 years x 19 fourteen-day windows)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "380 detection-windows over 4,527 camera-windows; invasive species.")
