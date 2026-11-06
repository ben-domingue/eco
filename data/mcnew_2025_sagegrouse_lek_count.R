#!/usr/bin/env Rscript
# Table:  mcnew_2025_sagegrouse_lek_count
# Source: Dryad doi:10.5061/dryad.v41ns1s6v (CC0 1.0, as shown on the Dryad page; published
#         2025-05-14). McNew, L. Data from: The performance of drones and artificial intelligence
#         for monitoring sage-grouse at leks.
# Paper:  McNew, L. et al. (2025). Wildlife Biology, doi:10.1002/wlb3.01482. Ground-based visual
#         lek counts of greater sage-grouse, 19 March to 4 May 2021 and 2022, 30 minutes before
#         and after sunrise, each followed by drone surveys (README).
# Data:   NmixDF.csv (23 leks, one row each: GB1-GB7 = ground-based counts on visits 1-7, NA = no
#         visit; Year (2021 or 2022); Profile / Height of that lek's drone flights; Date1-7
#         (MM/DD/YYYY), Time1-7, Wind1-7 (kph), Hum1-7 (%), Sky1-7 (c, pc, f, o)), the authors'
#         N-mixture input; README.md defines every column. Asserted: dates are present exactly
#         where counts are. SG_drone_data_longB.csv (the same ground counts plus manual and
#         AI-based counts from drone thermal video, long format, 358 NA count rows, every date
#         typed with year 2023) and SG.drone.response.csv (drone flush trials) are not built: see
#         notShipped.
#         Quirk: 47 of the 94 NmixDF dates carry a year other than the row's Year (5 of them
#         2023, outside the study); the README dates all surveys to 2021-2022. Which of Year and
#         date is right cannot be told, so no `date` column is built.
# Mapping (standard: repeated counts, N-mixture, E9 core): unit = Lek; taxon = CENURO; period =
#   year (2021, 2022; each lek is surveyed in one year); occasion = visit 1..7; y = ground count;
#   obs_date_deposited = the date string as deposited (no ISO `date`, see the quirk);
#   obs_: time, wind, humidity, sky.
#   Survey evidence: deposited_matrix. Greater sage-grouse is IUCN NT; no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mcnew_2025_sagegrouse_lek_count"
dir <- download_dryad("10.5061/dryad.v41ns1s6v", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^NmixDF\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, colClasses = "character")
K <- 1:7
stopifnot(nrow(d) == 23, !anyDuplicated(d$Lek), all(d$Year %in% c("2021", "2022")))
lng <- function(p) as.matrix(d[, paste0(p, K), with = FALSE])
G <- lng("GB"); D <- lng("Date"); Ti <- lng("Time"); W <- lng("Wind"); H <- lng("Hum"); S <- lng("Sky")
isna <- function(x) is.na(x) | x == "NA" | x == ""
stopifnot(all(isna(G) == isna(D)), all(grepl("^[0-9]+$", G[!isna(G)])), all(S[!isna(S)] %in% c("c", "C", "c,f", "o", "o,f", "pc", "PC", "pc,f,s,")))
w <- which(!isna(G), arr.ind = TRUE)
md <- sub("/[0-9]{4}$", "", D[w]); yr_dep <- sub("^.*/", "", D[w])
long <- data.table(unit = d$Lek[w[, 1]], taxon = "CENURO", y = as.integer(G[w]), period = match(d$Year[w[, 1]], c("2021", "2022")),
                   occasion = w[, 2], obs_date_deposited = D[w],
                   obs_time = Ti[w], obs_wind_kph = suppressWarnings(as.numeric(W[w])), obs_humidity_pct = suppressWarnings(as.numeric(H[w])),
                   obs_sky = ifelse(isna(S[w]), NA_character_, S[w]))   # as deposited (mixed case, combinations such as "o,f")
n_yr <- sum(yr_dep != d$Year[w[, 1]])
stopifnot(n_yr == 47, sum(yr_dep == "2023") == 5, all(sub("/.*", "", md) %in% c("3", "4", "5")))
long <- order_eco(long)
stopifnot(nrow(long) == sum(!isna(G)))
periods <- data.table(period = 1:2, period_year = 2021:2022)
taxa <- make_taxa("CENURO", "Centrocercus urophasianus", vernacularName = "Greater sage-grouse")
dataset <- list(
  title = "Ground-based lek counts of greater sage-grouse at 23 leks, 1-7 visits per lek, spring 2021-2022",
  creator = "McNew, Lance", pubDate = "2025", doi = "10.5061/dryad.v41ns1s6v", sourceURL = "https://doi.org/10.5061/dryad.v41ns1s6v",
  citation = "McNew, L. (2025). Data from: The performance of drones and artificial intelligence for monitoring sage-grouse at leks [Dataset]. Dryad. https://doi.org/10.5061/dryad.v41ns1s6v",
  paperDOI = "10.1002/wlb3.01482",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Repeated ground-based counts of greater sage-grouse (Centrocercus urophasianus) at 23 known leks, 1-7 visits per lek between 19 March and 4 May in 2021 or 2022, with survey time, wind, humidity and sky condition: the N-mixture input of a comparison of ground, drone and AI-based lek counts.",
  samplingProtocol = "Standard ground-based visual lek counts with binoculars from a distance, 30 minutes before to 30 minutes after sunrise; the maximum count of birds on the lek per survey.",
  samplingProtocolCode = "lek_count", surveyEvidence = "deposited_matrix", responseType = "count",
  unitKind = "site", closure = "closed", closureNote = "one lekking season per lek (19 March - 4 May), analysed as closed N-mixture", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = "Sage-grouse leks (see the paper); no coordinates deposited", temporalCoverage = "2021-03/2022-05",
  notShipped = list(drone_counts = "manual and AI-based (INDECS) counts from drone thermal video in SG_drone_data_longB.csv: 358 of 864 rows have no count and every date is typed 2023, so the drone surveys cannot be matched to dates; the ground counts there repeat NmixDF",
                    flush_trials = "SG.drone.response.csv, drone-flushing trials (behaviour, not counts)"),
  notes = "No ISO date column: 47 of the 94 deposited dates carry a year that disagrees with the lek's Year (5 of them 2023, outside the study), so the date string is shipped as obs_date_deposited and period follows the Year column. y is the per-survey maximum count, the standard lek count.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/mcnew_2025_sagegrouse_lek_count.R")
stage_dict_row(TABLE,
  description = "Repeated ground-based lek counts of greater sage-grouse at 23 leks, 2021-2022, with survey weather.",
  url = "https://doi.org/10.5061/dryad.v41ns1s6v",
  reference = "McNew, L. et al. (2025). The performance of drones and artificial intelligence for monitoring sage-grouse at leks. Wildlife Biology.",
  doi_paper = "10.1002/wlb3.01482", doi_data = "10.5061/dryad.v41ns1s6v", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "N-mixture lek counts; drone counts not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "lek_count", design = "Single-season (1-7 lek counts)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Lek counts.")
