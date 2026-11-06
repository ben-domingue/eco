#!/usr/bin/env Rscript
# Table:  brinck_2022_maunakea_palila_count
# Source: USGS ScienceBase doi:10.5066/P9DO0PL4 (USGS data release, ver. 2.0, January 2022; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Brinck, K.W., Genz, A.S., and Camp, R.J., 2022, Mauna Kea Palila point count data from annual
#   surveys 1998-2018 (ver. 2.0, January 2022): U.S. Geological Survey data release.
# Data:   Mauna Kea Palila 1998 2018.csv: 14,257 rows, one per palila detected at a six-minute point
#         count, or one row with NA species, distance and detection type for a count with no palila
#         ("No bird was detected"): survey year for abundance (9999 = an observation outside the area
#         of inference, used for detection functions only), stratum area, station id (OID; the
#         version 2.0 release replaced locations with an id "that does not have any spatial
#         reference"), the station's number of counts that year (EFFORT), horizontal distance (m),
#         species (PALI), detection type (1 heard only, 2 seen first, 4 heard then seen) and two
#         groupings of it, observer initials, observer sequence (1 primary; 10, 11, 12 the primary
#         observer's second to fourth visits), the authors' observer grouping (ObDumCode), year,
#         month, start time, cloud, rain, wind and gust (9999 = not recorded) with coarse blocks.
#         Palila Data Release Revision History v2.0.txt: the removal of location fields.
#         Asserted: start time, observer, month and weather are constant within a station-year-
#         visit; only OBSSEQ 1, 10, 11, 12 occur.
# Mapping: unit = station (OID), period = year (1 = 1998 ... 21 = 2018), occasion = visit within the
#   year (OBSSEQ 1 -> 1, 10 -> 2, 11 -> 3, 12 -> 4), observer = OBSCODE, y = palila detected in the
#   count (rows with ALPHACODE PALI and survey year not 9999). surveyEvidence row_presence: a count
#   with no palila has its own NA row. obs_n_outside = detections at the count filed under survey
#   9999 (outside the area of inference; not in y). Distances and detection types: obs_ columns
#   cannot hold a list per count, so per-bird distances are not shipped here (see Not shipped).
#   obs_n_heard_only / obs_n_seen_first / obs_n_heard_then_seen split y by detection type.
#   obs_time_start (hhmm), obs_cloud_pct, obs_rain, obs_wind, obs_gust (Beaufort; 9999 -> NA).
# Not shipped: per-detection distances (a distance-sampling table needs bins or a per-detection
#   form, neither settled for this deposit; y here is the count); the authors' coarse blocks and
#   observer groups (ObDumCode, YearBlock: modelling choices); EFFORT (the station's visit count,
#   recoverable from the rows; 14 station-years (0.2 percent) record one more visit than they have
#   rows, asserted and kept as recorded); stratum area. No coordinates are in the release.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "brinck_2022_maunakea_palila_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5b9b1833e4b02ff63f6ea112?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
x <- fread(download_cached(fl[["Mauna Kea Palila 1998 2018.csv"]], TABLE, filename = "palila.csv"), colClasses = "character", na.strings = NULL)
stopifnot(nrow(x) == 14257, setequal(unique(x$OBSSEQ), c("1", "10", "11", "12")), setequal(unique(x$ALPHACODE), c("NA", "PALI")),
          all(x[ALPHACODE == "NA", DETECTION == "NA" & DISTANCE == "NA"]), all(x[ALPHACODE == "PALI", DETECTION %in% c("1", "2", "4")]))
x[, occ := c(`1` = 1L, `10` = 2L, `11` = 3L, `12` = 4L)[OBSSEQ]]
x[, yr := as.integer(Year)]
k <- c("OID", "yr", "occ")
stopifnot(x[, .(uniqueN(`TIME START`), uniqueN(OBSCODE), uniqueN(`MONTH #`), uniqueN(CLOUD), uniqueN(RAIN), uniqueN(WIND), uniqueN(GUST)), by = k][, all(.SD == 1), .SDcols = -k])
x[, inside := Survey != "9999"]
stopifnot(sum(!x$inside) == 76, all(x[!(inside), ALPHACODE == "PALI"]))
v <- x[, .(y = sum(ALPHACODE == "PALI" & inside), n_out = sum(!inside), n1 = sum(DETECTION == "1" & inside), n2 = sum(DETECTION == "2" & inside),
           n4 = sum(DETECTION == "4" & inside), obs = OBSCODE[1], month = as.integer(`MONTH #`[1]), t = `TIME START`[1],
           cloud = CLOUD[1], rain = RAIN[1], wind = WIND[1], gust = GUST[1], eff = as.integer(EFFORT[1])), by = k]
stopifnot(sum(v$y) == 5852 - 76, nrow(v) == 11251)
ev <- v[, .(eff = eff[1], n = .N), by = .(OID, yr)]
stopifnot(sum(ev$eff != ev$n) == 14, all(ev[eff != n, eff - n] == 1))
na9 <- function(z) { z <- as.integer(z); z[z == 9999L] <- NA_integer_; z }
long <- v[, .(unit = OID, taxon = "PALI", y = as.integer(y), period = yr - 1997L, occasion = occ, observer = obs,
              obs_n_heard_only = n1, obs_n_seen_first = n2, obs_n_heard_then_seen = n4, obs_n_outside = n_out,
              obs_month = month, obs_time_start = as.integer(t), obs_cloud_pct = na9(cloud), obs_rain = na9(rain), obs_wind = na9(wind), obs_gust = na9(gust))]
periods <- data.table(period = 1:21, year = 1998:2018)
taxa <- make_taxa("PALI", "Loxioides bailleui", vernacularName = "Palila")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Point counts of palila at 455 stations on 32 transects around Mauna Kea, Hawaii, in annual surveys 1998-2018",
  creator = "Brinck, Kevin W.; Genz, Ayesha S.; Camp, Richard J.",
  pubDate = "2022", doi = "10.5066/P9DO0PL4", sourceURL = "https://doi.org/10.5066/P9DO0PL4",
  citation = "Brinck, K.W., Genz, A.S., and Camp, R.J., 2022, Mauna Kea Palila point count data from annual surveys 1998-2018 (ver. 2.0, January 2022): U.S. Geological Survey data release, https://doi.org/10.5066/P9DO0PL4.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Annual point-count surveys for the critically endangered palila on 32 transects around Mauna Kea, Hawaii Island, from treeline through the mamane-naio forest, 1998-2018; six-minute counts at stations about 150 m apart, with distance and detection type for every palila.",
  samplingProtocol = "Six-minute variable-distance point counts at stations about 150 m apart on transects perpendicular to the elevation gradient, each station counted one to four times a year in January-February; species, horizontal distance and detection type recorded for every bird, with time and weather.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "occasion = the primary observer's visits to the station within the January-February survey of a year.",
  geographicCoverage = list(description = "Mauna Kea, Hawaii Island, Hawaii, USA (palila critical habitat)",
                            boundingBox = list(west = -155.6653, east = -155.3851, south = 19.7512, north = 19.9992)),
  temporalCoverage = "1998/2018",
  notShipped = list(distances = "per-detection horizontal distances (no distance-sampling form built for this deposit)",
                    model_groupings = "ObDumCode, YearBlock, DECT14, DECT24 and weather blocks: the authors' groupings for model fitting",
                    effort = "EFFORT (the station's count of visits that year; 14 station-years record one more visit than they have rows)",
                    area = "stratum area for density-to-abundance"),
  notes = "Palila (Loxioides bailleui) is IUCN CR; the version 2.0 release has no station locations. y excludes detections filed under survey 9999 (outside the area of inference), counted in obs_n_outside.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/brinck_2022_maunakea_palila_count.R")
stage_dict_row(TABLE,
  description = "Counts of palila on six-minute point counts at 455 stations around Mauna Kea, Hawaii, repeated one to four times each year, 1998-2018, with observer, detection type and weather.",
  url = "https://doi.org/10.5066/P9DO0PL4",
  reference = "Brinck, K.W., Genz, A.S., and Camp, R.J. (2022). Mauna Kea Palila point count data from annual surveys 1998-2018 (ver. 2.0, January 2022). U.S. Geological Survey data release.",
  doi_data = "10.5066/P9DO0PL4", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Count per station visit; per-bird distances not shipped.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (open)", sampling_protocol = "point_count",
  design = "Multi-season (21 years, 1-4 visits a year)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Critically endangered Hawaiian honeycreeper; locations withheld by the source.")
