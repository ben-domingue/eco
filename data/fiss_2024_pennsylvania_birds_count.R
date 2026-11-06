#!/usr/bin/env Rscript
# Tables: fiss_2024_pennsylvania_birds_count (point counts) and fiss_2024_pennsylvania_birds_aru_occ (ARU daily
#         detections from a machine-learning classifier verified by a listener)
# Source: Dryad, doi:10.5061/dryad.4j0zpc8k0, version 313018 (published 2024-08-27), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API). Fiss, C., Lapp, S., Cohen, J., Parker, H., Larkin, J. T., Larkin, J. L.
#         & Kitzes, J. Data from: Performance of unmarked abundance models with data from machine-learning
#         classification of passive acoustic recordings. Code on Zenodo (doi:10.5281/zenodo.13362533; not used).
# Paper:  Fiss, C. et al. (2024). Performance of unmarked abundance models with data from machine-learning
#         classification of passive acoustic recordings. Ecosphere. doi:10.1002/ecs2.4954 (not in Europe PMC; not read).
#         Design from the Dryad abstract and README: forests of Pennsylvania, spring 2020 and 2021, traditional point
#         counts and autonomous recording units (ARUs) at the same points; Wood Thrush and Cerulean Warbler; Royle-
#         Nichols, time-to-detection, N-mixture and distance models.
# Data:   point_count_data_dryad.csv (573 point-years; each Point in one year only, asserted): Point, Block (5 study
#           areas), Year, per species (WOTH, CERW) and visit (1, 2): <sp>_count<v>, <sp>_ttd<v> (minute interval of
#           first detection 1..10; 11 = not detected, asserted: 11 exactly where the count is 0),
#           <sp><v>_dist1..5 (counts in five distance bins; breaks not deposited); Wind1, Wind2, Date1,
#           Date2 (a day index, units not documented); Wind2 and Date2 are NA at one point (asserted).
#         WOTH_det_hist_2020-2021_dryad.csv (571 point-years) and CERW_det_hist_2020-2021_dryad.csv (243, at the
#           Ohiopyle and SGL089 blocks only; every CERW point-year is also a WOTH point-year, asserted): site (block),
#           point, year, det1..det10 (species detected on recording day 1..10), ttd (first day detected, 11 = never;
#           rebuilt from det1..10 and asserted, so not shipped), date1..10 (scaled day), wind1..10. No NA.
# Mapping, count (repeated counts; responseType count, unitKind site): unit = Point, taxon = WOTH / CERW, period = year
#   (1 = 2020, 2 = 2021; each point in one year), occasion = visit 1..2, y = <sp>_count<v>. surveyEvidence =
#   deposited_matrix (complete: both visits at every point, both species). obs_ttd = minute interval of first
#   detection, the survey length (10) where not detected, obs_ttd_censored = 1 there (time-to-detection ruling);
#   obs_dist_bin1..5 = the distance-bin counts (their sum differs from the count on 7 of 2,292 rows, asserted; y is
#   the count as deposited); obs_wind, obs_date_index (visit-level, repeated on both species' rows). unit_block.
# Mapping, aru_occ (responseType detection, unitKind site): unit = point, taxon, period = year, occasion = recording
#   day 1..10, y = det<d>. surveyEvidence = deposited_matrix (complete for each species' point set). The classifier
#   was run for the Cerulean Warbler at two blocks only, so the table carries __survey_taxa (taxon x unit; ruling
#   #31). obs_wind, obs_date_scaled (as deposited, per species file; identical across the two files where both
#   exist, asserted). unit_block.
# Not shipped: the ARU ttd columns (a recode of det1..10); model estimates. Two point-count point-years have no ARU
#   history.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fiss_2024_pennsylvania_birds_count"
ARU <- "fiss_2024_pennsylvania_birds_aru_occ"
dir <- download_dryad("10.5061/dryad.4j0zpc8k0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("CERW_det_hist_2020-2021_dryad.csv", "point_count_data_dryad.csv", "README.md",
                                      "WOTH_det_hist_2020-2021_dryad.csv")))
pc <- fread(file.path(dir, "point_count_data_dryad.csv"), encoding = "UTF-8")
setnames(pc, 1, "Point")
stopifnot(nrow(pc) == 573L, !anyDuplicated(pc$Point), setequal(pc$Year, 2020:2021), uniqueN(pc$Block) == 5L,
          sum(is.na(pc)) == 2L, sum(is.na(pc$Wind2)) == 1L, identical(which(is.na(pc$Wind2)), which(is.na(pc$Date2))))
SP <- c("WOTH", "CERW")
pcl <- rbindlist(lapply(SP, function(sp) rbindlist(lapply(1:2, function(v) {
  cnt <- pc[[sprintf("%s_count%d", sp, v)]]; ttd <- pc[[sprintf("%s_ttd%d", sp, v)]]
  stopifnot(all(ttd %in% 1:11), identical(ttd == 11L, cnt == 0L))
  bins <- sapply(1:5, function(b) pc[[sprintf("%s%d_dist%d", sp, v, b)]])
  d <- data.table(unit = pc$Point, taxon = sp, y = cnt, period = pc$Year - 2019L, occasion = v,
                  obs_ttd = pmin(ttd, 10L), obs_ttd_censored = as.integer(ttd == 11L),
                  obs_wind = pc[[paste0("Wind", v)]], obs_date_index = pc[[paste0("Date", v)]], unit_block = pc$Block)
  for (b in 1:5) d[[paste0("obs_dist_bin", b)]] <- bins[, b]
  d[, .binsum := rowSums(bins)]
  d }))))
stopifnot(nrow(pcl) == 573L * 4L, sum(pcl$y != pcl$.binsum) == 7L)
pcl[, .binsum := NULL]
pcl <- order_eco(pcl)

rd <- function(f) { d <- fread(file.path(dir, f), encoding = "UTF-8"); setnames(d, 1, "site")
  stopifnot(identical(names(d), c("site", "point", "year", paste0("det", 1:10), "ttd", paste0("date", 1:10), paste0("wind", 1:10))),
            !anyNA(d), !anyDuplicated(d$point))
  D <- as.matrix(d[, paste0("det", 1:10), with = FALSE]); stopifnot(all(D %in% 0:1))
  first <- apply(D, 1, function(r) if (any(r == 1L)) which(r == 1L)[1] else 11L)
  stopifnot(all(first == d$ttd))
  d }
W <- rd("WOTH_det_hist_2020-2021_dryad.csv"); C <- rd("CERW_det_hist_2020-2021_dryad.csv")
stopifnot(nrow(W) == 571L, nrow(C) == 243L, all(C$point %in% W$point), setequal(C$site, c("Ohiopyle", "SGL089")),
          all(W$point %in% pc$Point), length(setdiff(pc$Point, W$point)) == 2L)
m <- merge(W[, c("point", paste0("date", 1:10), paste0("wind", 1:10)), with = FALSE],
           C[, c("point", paste0("date", 1:10), paste0("wind", 1:10)), with = FALSE], by = "point")
stopifnot(nrow(m) == 243L, all(sapply(1:10, function(i) isTRUE(all.equal(m[[paste0("date", i, ".x")]], m[[paste0("date", i, ".y")]])))))
stopifnot(all(W[, .(point, site, year)][pc[, .(point = Point, Block, Year)], on = "point", nomatch = 0L][, site == Block & year == Year]))
arl <- rbindlist(lapply(list(WOTH = W, CERW = C), function(d) rbindlist(lapply(1:10, function(j)
  data.table(unit = d$point, y = d[[paste0("det", j)]], period = d$year - 2019L, occasion = j,
             obs_wind = d[[paste0("wind", j)]], obs_date_scaled = d[[paste0("date", j)]], unit_block = d$site)))), idcol = "taxon")
arl <- order_eco(arl)
stopifnot(nrow(arl) == (571L + 243L) * 10L, sum(arl$y) == 2052L + 150L)
survey_taxa <- unique(arl[, .(taxon, unit)])

taxa <- make_taxa(SP, c("Hylocichla mustelina", "Setophaga cerulea"), vernacularName = c("Wood Thrush", "Cerulean Warbler"))
periods <- data.table(period = 1:2, year = 2020:2021)

base <- list(
  creator = "Fiss, Cameron; Lapp, Samuel; Cohen, Jonathan; Parker, Halie; Larkin, Jeffery T.; Larkin, Jeffery L.; Kitzes, Justin",
  pubDate = "2024-08-27", doi = "10.5061/dryad.4j0zpc8k0", paperDOI = "10.1002/ecs2.4954", sourceURL = "https://doi.org/10.5061/dryad.4j0zpc8k0",
  citation = "Fiss, C., Lapp, S., Cohen, J., Parker, H., Larkin, J. T., Larkin, J. L., & Kitzes, J. (2024). Data from: Performance of unmarked abundance models with data from machine-learning classification of passive acoustic recordings [Dataset]. Dryad. https://doi.org/10.5061/dryad.4j0zpc8k0",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point counts and autonomous recording units at the same points in forests of Pennsylvania, spring 2020 and 2021, for Wood Thrush and Cerulean Warbler; the authors compared Royle-Nichols, time-to-detection, N-mixture and distance abundance models fitted to point counts and to classifier-derived ARU detection histories.",
  unitKind = "site", surveyEvidence = "deposited_matrix", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Forests of south-western Pennsylvania, USA (study blocks Laurel Ridge, Ohiopyle, State Game Lands 025, 060 and 089); no coordinates deposited",
  temporalCoverage = "2020/2021")

ds_pc <- c(list(title = "Two-visit point counts of Wood Thrush and Cerulean Warbler at 573 forest points in Pennsylvania, 2020-2021, with time to first detection and distance bins"),
  base, list(responseType = "count", samplingProtocolCode = "point_count",
  samplingProtocol = "Two point-count visits per point in spring; the number of individuals of each species counted, with the minute interval of first detection and counts by distance bin.",
  closure = "closed", closureNote = "two visits within one breeding season; each point surveyed in one year only",
  covariateNote = "obs_ttd: minute interval (1-10) of the species' first detection on the visit; 10 with obs_ttd_censored = 1 where not detected (deposited code 11). obs_dist_bin1..5: individuals counted in five distance bins, nearest first (breaks not deposited; the bins sum to y except on 7 rows). obs_wind: wind on the visit (0-5 scale as deposited). obs_date_index: the deposited Date1/Date2 day index (origin not documented). unit_block: study block.",
  notShipped = list(model_output = "abundance and detection estimates"),
  notes = "Each point was surveyed in one year only (period 1 = 2020, 2 = 2021). The ARU histories at the same points are fiss_2024_pennsylvania_birds_aru_occ."))
ds <- write_table(pcl, TABLE, ds_pc, taxa = taxa, periods = periods, script = "data/fiss_2024_pennsylvania_birds_count.R")
ds_ar <- c(list(title = "Daily ARU detections of Wood Thrush and Cerulean Warbler from a verified machine-learning classifier over 10 recording days at forest points in Pennsylvania, 2020-2021"),
  base, list(responseType = "detection", samplingProtocolCode = "acoustic",
  samplingProtocol = "Autonomous recording units at point-count locations for 10 days; recordings processed with a machine-learning classifier and positives verified by a human listener; a species is detected on a day if any verified detection occurred that day.",
  closure = "closed", closureNote = "10 consecutive recording days within one breeding season; each point recorded in one year only",
  covariateNote = "obs_wind: wind on the recording day (as deposited). obs_date_scaled: recording day, scaled (z-score) as deposited. unit_block: study block. Cerulean Warbler histories exist only at the Ohiopyle and SGL089 blocks (__survey_taxa).",
  notShipped = list(ttd = "the ttd column (first day detected; rebuilt exactly from det1..det10)", model_output = "abundance and detection estimates"),
  notes = "The classifier was applied for the Cerulean Warbler at two of the five blocks; __survey_taxa lists the species surveyed for at each point. Point counts at the same points: fiss_2024_pennsylvania_birds_count."))
ds2 <- write_table(arl, ARU, ds_ar, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = "data/fiss_2024_pennsylvania_birds_count.R")

ref <- "Fiss, C., Lapp, S., Cohen, J., Parker, H., Larkin, J. T., Larkin, J. L., & Kitzes, J. (2024). Performance of unmarked abundance models with data from machine-learning classification of passive acoustic recordings. Ecosphere."
stage_dict_row(TABLE, description = "Two-visit point counts of Wood Thrush and Cerulean Warbler at 573 forest points in south-western Pennsylvania, 2020-2021, with minute of first detection and distance-bin counts.",
  url = "https://doi.org/10.5061/dryad.4j0zpc8k0", reference = ref, doi_paper = "10.1002/ecs2.4954", doi_data = "10.5061/dryad.4j0zpc8k0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "Distance-bin breaks not deposited; paper not read.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture", sampling_protocol = "point_count",
  design = "Single-season (2 visits; 573 points, each in one of two years)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Paired with ARU detection histories at the same points.")
stage_dict_row(ARU, description = "Daily detections of Wood Thrush (571 points) and Cerulean Warbler (243 points) over 10 ARU recording days from a human-verified machine-learning classifier, south-western Pennsylvania forests, 2020-2021.",
  url = "https://doi.org/10.5061/dryad.4j0zpc8k0", reference = ref, doi_paper = "10.1002/ecs2.4954", doi_data = "10.5061/dryad.4j0zpc8k0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "__survey_taxa: Cerulean Warbler classified at two blocks only; paper not read.", source_via = "Dryad")
stage_tag_row(ARU, ds2, taxon_group = "Birds", model_family = "Single-season occupancy (Royle-Nichols)", sampling_protocol = "acoustic",
  design = "Single-season (10 daily occasions; 571 points, each in one of two years)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Classifier-derived ARU detections paired with point counts.")
