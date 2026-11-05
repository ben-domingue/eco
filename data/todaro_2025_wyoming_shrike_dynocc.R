#!/usr/bin/env Rscript
# Table:  todaro_2025_wyoming_shrike_dynocc
# Source: Dryad doi:10.5061/dryad.rbnzs7hr9, version 419171 (version 2, published 2026-01-14),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Todaro, H., Loss, S., Lonsinger, R. & Duchardt, C. "Data from: Factors influencing
#         spatial and temporal patterns of Lanius ludovicianus (Loggerhead Shrike) occupancy at a
#         grassland-sagebrush ecotone".
# Paper:  Todaro, H. M., Loss, S. R., Lonsinger, R. C. & Duchardt, C. J. (2025). Factors
#         influencing spatial and temporal patterns of Lanius ludovicianus (Loggerhead Shrike)
#         occupancy at a grassland-sagebrush ecotone. Ornithological Applications 128(1), 1-13,
#         doi:10.1093/ornithapp/duaf055 (not read; design from the Dryad abstract and README).
# Data:   README.md (variables, read) and LOSH_2015-2024.csv: 445 point-count locations (Point,
#         e.g. C1.1, on 62 transects; points 250 m apart) in one wide row each, columns per
#         year-visit YYYY_1 / YYYY_2 for 2015-2024: detection 0/1 (NA = not surveyed), Date_,
#         Obs_ (observer initials), Time_ (local clock time), Sky_ (C, PC, MC, OC), Wind_ (code),
#         Temp_ (deg), YYYY_v_AC (1 = a shrike was detected at an adjacent point on that survey);
#         point covariates Veg_Height (cm), Fence_Leng (m in the point buffer), Tree_Area_Bin
#         (0/1); yearly covariates Herb_, LTR_, SHR_ (% herbaceous, litter, shrub cover).
#         Two visits a year in 2015-2017, one in 2018-2024 (no _2 detection in those years).
#         A detection is present exactly where a date is (asserted); three cells carry an
#         observer or AC value with no detection and no date (C1.8, E31.7, E54.1 in 2023_1), so
#         they are not surveys. The _1 / _2 labels are not in date order within a year (some _2
#         visits precede _1), so occasions are re-ordered by date.
#
# Mapping (standard E9 dynamic occupancy, responseType detection, unitKind site):
#   unit = Point, taxon = LANLUD, period = year 1..10 (2015..2024, __periods), occasion = visit
#   within the year in date order (1, 2), y = the deposited 0/1, date = survey date,
#   observer = Obs_, cluster_id = Transect. obs_time_local (HH:MM, local), obs_sky, obs_wind,
#   obs_temp, obs_adjacent_det (the deposited AC flag: detection at a neighbouring point on the
#   same survey, an observation, not a model output; NA where not recorded); unit_veg_height,
#   unit_fence_length, unit_tree; period_herb, period_litter, period_shrub.
#   Survey evidence: deposited_matrix (NA and 0 distinct; the date column agrees).
#   No coordinates are deposited; Lanius ludovicianus is IUCN LC.
#   Not shipped: the three stray observer / AC cells on unsurveyed point-years (no survey).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "todaro_2025_wyoming_shrike_dynocc"
dir <- download_dryad("doi:10.5061/dryad.rbnzs7hr9", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "419171"), setequal(list.files(dir), c("LOSH_2015-2024.csv", "README.md")))
d <- fread(file.path(dir, "LOSH_2015-2024.csv"), colClasses = "character", na.strings = c("NA", ""))
stopifnot(identical(names(d)[1:2], c("Transect", "Point")))   # header "Point " (fread strips the space)
years <- 2015:2024
yc <- paste0(rep(years, each = 2), "_", 1:2)
stopifnot(nrow(d) == 445L, ncol(d) == 195L, all(yc %in% names(d)), !anyDuplicated(d$Point),
          uniqueN(d$Transect) == 62L, all(startsWith(d$Point, paste0(d$Transect, "."))))
lng <- rbindlist(lapply(yc, function(v) data.table(
  unit = d$Point, cluster_id = d$Transect, yv = v, year = as.integer(substr(v, 1, 4)), visit = as.integer(substr(v, 6, 6)),
  y = d[[v]], date = d[[paste0("Date_", v)]], observer = d[[paste0("Obs_", v)]], time = d[[paste0("Time_", v)]],
  sky = d[[paste0("Sky_", v)]], wind = d[[paste0("Wind_", v)]], temp = d[[paste0("Temp_", v)]], ac = d[[paste0(v, "_AC")]])))
stopifnot(identical(is.na(lng$y), is.na(lng$date)), all(lng$y %in% c("0", "1", NA)),
          sum(lng$y == "1", na.rm = TRUE) == 190L, sum(lng$y == "0", na.rm = TRUE) == 4062L,
          nrow(lng[is.na(y) & (!is.na(observer) | !is.na(ac) | !is.na(time) | !is.na(sky))]) == 3L,
          all(lng[visit == 2L & year >= 2018L, is.na(y)]))
lng <- lng[!is.na(y)]
lng[, date := as.Date(date, format = "%m/%d/%Y")]
stopifnot(!anyNA(lng$date), all(year(lng$date) == lng$year), all(month(lng$date) %in% 5:7),
          lng[, .N, by = .(unit, year)][, all(N <= 2L)],
          lng[, uniqueN(date) == .N, by = .(unit, year)][, all(V1)],                       # two visits on different days
          !anyNA(lng$observer), !anyNA(lng$sky), !anyNA(lng$wind), !anyNA(lng$temp))
setorder(lng, unit, year, date)
lng[, occasion := seq_len(.N), by = .(unit, year)]
cat(sprintf("  %d surveys; %d point-years with visits out of label order\n", nrow(lng),
            lng[, .(o = any(visit != occasion)), by = .(unit, year)][, sum(o)]))
lng[, time := ifelse(is.na(time), NA_character_, sprintf("%02d:%s", as.integer(sub(":.*", "", time)), substr(sub("^[0-9]+:", "", time), 1, 2)))]
stopifnot(all(is.na(lng$time) | grepl("^[0-2][0-9]:[0-5][0-9]$", lng$time)), sum(is.na(lng$time)) == 2L)
long <- lng[, .(unit, taxon = "LANLUD", y = as.integer(y), period = year - 2014L, occasion, date = format(date),
                observer, cluster_id, obs_time_local = time, obs_sky = sky, obs_wind = as.integer(wind),
                obs_temp = as.numeric(temp), obs_adjacent_det = as.integer(ac))]
uc <- d[, .(unit = Point, unit_veg_height = as.numeric(Veg_Height), unit_fence_length = as.numeric(Fence_Leng),
            unit_tree = as.integer(Tree_Area_Bin))]
pc <- rbindlist(lapply(years, function(yr) d[, .(unit = Point, period = yr - 2014L,
  period_herb = as.numeric(get(paste0("Herb_", yr))), period_litter = as.numeric(get(paste0("LTR_", yr))),
  period_shrub = as.numeric(get(paste0("SHR_", yr))))]))
long <- merge(merge(long, uc, by = "unit"), pc, by = c("unit", "period"), all.x = TRUE)
long <- order_eco(long)
stopifnot(nrow(long) == 4252L, uniqueN(long$unit) == 445L)

taxa <- make_taxa("LANLUD", "Lanius ludovicianus", vernacularName = "Loggerhead shrike")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
periods <- long[, .(year = period + 2014L, n_points = uniqueN(unit), n_surveys = .N, n_detections = sum(y),
                    first_date = min(date), last_date = max(date)), by = period][order(period)]

dataset <- list(
  title = "Loggerhead shrike detection / non-detection at 445 point-count locations in a grassland-sagebrush ecotone, northeastern Wyoming, 2015-2024",
  creator = "Todaro, Holly; Loss, Scott; Lonsinger, Robert; Duchardt, Courtney",
  pubDate = "2026", doi = "10.5061/dryad.rbnzs7hr9", sourceURL = "https://doi.org/10.5061/dryad.rbnzs7hr9",
  citation = "Todaro, H., Loss, S., Lonsinger, R., & Duchardt, C. (2026). Data from: Factors influencing spatial and temporal patterns of Lanius ludovicianus (Loggerhead Shrike) occupancy at a grassland-sagebrush ecotone [Dataset]. Dryad. https://doi.org/10.5061/dryad.rbnzs7hr9",
  paperDOI = "10.1093/ornithapp/duaf055",
  abstract = "Ten years of point-count surveys for Loggerhead Shrike at fixed points 250 m apart along transects in a grassland-sagebrush ecotone of northeastern Wyoming, with two visits a year in 2015-2017 and one in 2018-2024, survey conditions, observer, point habitat and yearly ground cover. The paper fits dynamic occupancy models (initial occupancy, colonisation, local extinction) with an adjacent-detection autocovariate.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Standardised point counts at fixed points spaced 250 m apart on transects, surveyed in the morning between late May and early July; two visits per point in 2015-2017 and one in 2018-2024, recording detection of Loggerhead Shrike, observer, time, sky, wind and temperature.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasions within a breeding season (May-July) are assumed closed; colonisation and extinction between years",
  occasionKind = "time", taxonInclusion = "single",
  temporalCoverage = "2015-05/2024-07",
  geographicCoverage = "Grassland-sagebrush ecotone, northeastern Wyoming, USA (no coordinates deposited)",
  notes = "Visits re-ordered by date within each year (the deposit's _1/_2 labels are not in date order for some point-years). obs_adjacent_det is the authors' recorded flag that a shrike was detected at an adjacent point on the same survey (an autocovariate built from observations, not a model output). Clock time is local (obs_time_local). cluster_id = transect.",
  notShipped = list(stray_cells = "three observer / adjacent-detection values recorded on point-years with no detection and no date (not surveys)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/todaro_2025_wyoming_shrike_dynocc.R")
stage_dict_row(TABLE,
  description = "Loggerhead shrike detection / non-detection at 445 point-count locations on 62 transects in a grassland-sagebrush ecotone of northeastern Wyoming, 2015-2024 (two visits a year 2015-2017, one after), with survey conditions, observer, point habitat and yearly ground cover.",
  url = "https://doi.org/10.5061/dryad.rbnzs7hr9",
  reference = "Todaro, H. M., Loss, S. R., Lonsinger, R. C., & Duchardt, C. J. (2025). Factors influencing spatial and temporal patterns of Lanius ludovicianus (Loggerhead Shrike) occupancy at a grassland-sagebrush ecotone. Ornithological Applications, 128(1), 1-13.",
  doi_paper = "10.1093/ornithapp/duaf055", doi_data = "10.5061/dryad.rbnzs7hr9",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic occupancy, single species; visits re-ordered by date.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy",
  sampling_protocol = "point_count", design = "Multi-season (10 years, 1-2 visits per year)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Single-species dynamic occupancy with an adjacent-detection autocovariate.")
