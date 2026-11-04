#!/usr/bin/env Rscript
# Table:  evans_2021_maine_marten_dynocc
# Source: figshare 10.6084/m9.figshare.16441422.v1 (CC BY 4.0), Evans, Bryn (2021). Marten
#         detection history. University of Maine.
#         "Detection history data for seven seasons of camera trapping surveys in Maine, USA.
#         0 = station active, no detection; 1 = station active, American marten detected,
#         NA = station not active."
# Data:   Marten_multi_year_presence_by_station_to_SY4.csv: 197 stations x 231 columns
#         S1.1-S1.33, W1.1-W1.33, S2.*, W2.*, S3.*, W3.*, S4.* (summer / winter seasons, 33
#         occasions each; occasion length not stated in the deposit). 193 stations active in
#         season W1, 26 in S4. No covariates, coordinates or calendar years deposited.
# Mapping (standard E1-E5; dynamic occupancy): unit = STATION, taxon = MARAME, period =
#   season 1..7 (labels in __periods), occasion = 1..33 within season, y = 0/1. NA cells are
#   missing rows (E4). surveyEvidence = deposited_matrix. No paper DOI is given on the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "evans_2021_maine_marten_dynocc"

f <- download_cached("https://ndownloader.figshare.com/files/30455196", TABLE, filename = "Marten_multi_year_presence_by_station_to_SY4.csv")
raw <- fread(f)
stopifnot(nrow(raw) == 197, names(raw)[1] == "STATION", ncol(raw) == 232)
seasons <- c("S1", "W1", "S2", "W2", "S3", "W3", "S4")
cols <- setdiff(names(raw), "STATION")
stopifnot(all(sub("\\.\\d+$", "", cols) %in% seasons), all(table(sub("\\.\\d+$", "", cols)) == 33))
m <- as.matrix(raw[, ..cols]); stopifnot(all(m[!is.na(m)] %in% 0:1))
period <- match(sub("\\.\\d+$", "", cols), seasons)
long <- array_to_eco(m, taxon = "MARAME", site_ids = raw$STATION, period = period)
stopifnot(nrow(long) == sum(!is.na(m)), uniqueN(long$unit) == 197, max(long$period) == 7)
periods <- data.table(period = 1:7, season = seasons,
                      season_type = ifelse(substr(seasons, 1, 1) == "S", "summer", "winter"),
                      n_stations_active = sapply(1:7, function(t) uniqueN(long[period == t, unit])))

taxa <- make_taxa("MARAME", "Martes americana", vernacularName = "American marten")
dataset <- list(
  title = "American marten camera-trap detection histories, 197 stations over seven summer/winter seasons, Maine, USA",
  creator = "Evans, Bryn", pubDate = "2021", doi = "10.6084/m9.figshare.16441422.v1",
  sourceURL = "https://doi.org/10.6084/m9.figshare.16441422.v1",
  citation = "Evans, B. (2021). Marten detection history [Data set]. figshare. https://doi.org/10.6084/m9.figshare.16441422.v1",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Detection history data for seven seasons of camera trapping surveys in Maine, USA (deposit description). 0 = station active, no detection; 1 = station active, American marten detected; NA = station not active.",
  samplingProtocol = "Camera-trap stations surveyed over seven consecutive seasons (four summers, three winters), 33 occasions per season; occasion length not stated in the deposit.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Maine, USA (no coordinates deposited)",
  temporalCoverage = "seven seasons (S1-S4, W1-W3); calendar years not stated in the deposit",
  coordinatesCoarsened = NA,
  notShipped = list(none = "the deposit holds detection histories only; no covariates, coordinates or dates"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/evans_2021_maine_marten_dynocc.R")
stage_dict_row(TABLE,
  description = "American marten camera-trap detection/non-detection at 197 stations in Maine over seven summer/winter seasons of 33 occasions each (station activity varies by season: 197 active in S1, 26 in S4); no covariates or coordinates deposited.",
  url = "https://doi.org/10.6084/m9.figshare.16441422.v1",
  reference = "Evans, B. (2021). Marten detection history [Data set]. figshare.",
  doi_data = "10.6084/m9.figshare.16441422.v1", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Occasion length and calendar years not stated in the deposit; seasons labelled S1-S4 / W1-W3 in __periods. No associated paper DOI on the deposit.",
  source_via = "figshare")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "camera_trap", design = "Multi-season (7 seasons x 33 occasions)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Single species; strongly unbalanced station activity across seasons.")
