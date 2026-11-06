#!/usr/bin/env Rscript
# Table:  carter_2021_louisiana_lamp_calls
# Source: USGS ScienceBase doi:10.5066/P9VNBWM2 (USGS data release, published 2021-02-16;
#         metadata use constraints "None"; US public domain, recorded as CC0 1.0)
#   Carter, J., 2021, The Louisiana Amphibian Monitoring Program from 1997 to 2017: Data:
#   U.S. Geological Survey data release, https://doi.org/10.5066/P9VNBWM2.
# Paper:  Carter, J., Johnson, D., Boundy, J. & Vermillion, W. (2021). The Louisiana Amphibian
#         Monitoring Program from 1997 to 2017: results, analyses, and lessons learned.
#         PLOS ONE 16(9): e0257869, doi:10.1371/journal.pone.0257869.
# Data:   LAMPDataForPLOS.csv (CR line endings), 12,772 rows = one per route x stop x survey
#         night: RouteRegion (North / South / Florida parishes), RouteNumb (NAAMP route number),
#         RouteName, Run (1 winter, 2 spring, 3 summer), Stop (1-10), Year (sampling year),
#         Month, Day, then one column per frog / toad taxon (26 species and "Dryophytes sp")
#         holding the NAAMP calling index 0 (not heard) to 3 (full chorus).
#         Quirks, asserted below: two route names differ only in case (one route each);
#         nine route-year-runs were run on two nights (20 stop rows, two dates), kept as two
#         surveys; one route-year-run (Le Bleu 2000 run 3) has no month/day; some runs have
#         fewer than 10 stops (stops not surveyed that night have no row). The metadata say
#         "Dates from December 1997 are in the 1998 sampling year" but the only December rows
#         carry Year 1997 next to January-June 1997 rows, while the release's start date is
#         1997-12-20; the calendar year of the 1997 rows is therefore ambiguous and no ISO
#         `date` is built: month and day ship as obs_month / obs_day, the sampling year as
#         given goes in __periods. "Scaphiopus hurteri" is looked up on GBIF as S. hurterii.
#
# Mapping (standard E2, responseType = ordinal): unit = route x stop ("<RouteNumb>_<Stop>"),
#   cluster_id = route, taxon = 6-letter code, period = sampling year (1997-2017, index in
#   __periods), occasion = survey night within the route-year, ordered by run then month
#   (December first) and day; obs_run = the run (season window). y = calling index 0-3
#   (stateCodes). Survey evidence: row presence (every row is one stop surveyed on one night
#   with all taxa scored; a stop without a row was not surveyed). No coordinates in the
#   release. Not shipped: nothing dropped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "carter_2021_louisiana_lamp_calls"
f <- download_cached("https://www.sciencebase.gov/catalog/file/get/600789c4d34e162231fb1cdb?f=__disk__7d%2F8a%2F87%2F7d8a876c4bf12982a7415298f2b9e153b4cf3750",
                     TABLE, filename = "LAMPDataForPLOS.csv")
txt <- gsub("\r", "\n", readChar(f, file.size(f), useBytes = TRUE), fixed = TRUE)
d <- fread(text = txt)
stopifnot(nrow(d) == 12772, ncol(d) == 35)
sp_cols <- names(d)[9:ncol(d)]
stopifnot(length(sp_cols) == 27, all(as.matrix(d[, ..sp_cols]) %in% 0:3))
stopifnot(all(d$Run %in% 1:3), all(d$Stop %in% 1:10), all(d$Year %in% 1997:2017),
          uniqueN(d$RouteNumb) == 54)
# route names: two routes carry a lower-case variant of their name
stopifnot(d[, uniqueN(tolower(RouteName)), by = RouteNumb][, all(V1 == 1)])
d[, RouteName := names(sort(table(RouteName), decreasing = TRUE))[1], by = RouteNumb]
stopifnot(d[, uniqueN(RouteName), by = RouteNumb][, all(V1 == 1)], d[, uniqueN(RouteRegion), by = RouteNumb][, all(V1 == 1)])
# missing month/day: exactly one route-year-run
stopifnot(d[is.na(Month) | is.na(Day), uniqueN(paste(RouteNumb, Year, Run))] == 1, sum(is.na(d$Month)) == 10)
# a survey night = route x year x run x month x day; nine route-year-runs have two nights
d[, night := paste(Run, Month, Day)]
stopifnot(d[, uniqueN(night), by = .(RouteNumb, Year, Run)][, sum(V1 == 2)] == 9,
          d[, uniqueN(night), by = .(RouteNumb, Year, Run)][, all(V1 %in% 1:2)],
          !anyDuplicated(d[, .(RouteNumb, Year, night, Stop)]))
nights <- unique(d[, .(RouteNumb, Year, Run, Month, Day, night)])
nights[, mo := ifelse(!is.na(Month) & Month == 12, 0L, Month)]
setorder(nights, RouteNumb, Year, Run, mo, Day)
nights[, occasion := seq_len(.N), by = .(RouteNumb, Year)]
d <- merge(d, nights[, .(RouteNumb, Year, night, occasion)], by = c("RouteNumb", "Year", "night"))
stopifnot(nrow(d) == 12772, max(d$occasion) <= 4)

years <- 1997:2017
long <- melt(d[, c("RouteNumb", "RouteName", "RouteRegion", "Stop", "Year", "occasion", "Run", "Month", "Day", sp_cols), with = FALSE],
             measure.vars = sp_cols, variable.name = "scientificName", value.name = "y", variable.factor = FALSE)
sp <- data.table(scientificName = sp_cols)
sp[, taxon := ifelse(grepl(" sp$", scientificName), toupper(paste0(substr(scientificName, 1, 3), "SP")),
                     toupper(paste0(substr(sub(" .*$", "", scientificName), 1, 3), substr(sub("^[^ ]+ ", "", scientificName), 1, 3))))]
stopifnot(!anyDuplicated(sp$taxon))
long <- merge(long, sp, by = "scientificName")
long <- long[, .(unit = sprintf("%d_%02d", RouteNumb, Stop), taxon, y = as.integer(y), period = match(Year, years), occasion,
                 cluster_id = as.character(RouteNumb), unit_route_name = RouteName, unit_region = RouteRegion,
                 unit_stop = Stop, obs_run = Run, obs_month = Month, obs_day = Day)]
stopifnot(nrow(long) == 12772 * 27, !anyNA(long$y), !anyNA(long$period))

taxa <- make_taxa(sp$taxon, sp$scientificName,
                  taxonRank = ifelse(grepl(" sp$", sp$scientificName), "genus", "species"),
                  lookupName = sub("hurteri$", "hurterii", sub(" sp$", "", sp$scientificName)),
                  taxonRemarks = ifelse(grepl(" sp$", sp$scientificName), "treefrog calls identified to genus only (source column 'Dryophytes sp')", NA_character_))
periods <- data.table(period = seq_along(years), year = years)
dataset <- list(
  title = "Louisiana Amphibian Monitoring Program: anuran calling-index surveys on 54 roadside routes, 1997-2017",
  creator = "Carter, Jacoby", pubDate = "2021", doi = "10.5066/P9VNBWM2", sourceURL = "https://doi.org/10.5066/P9VNBWM2",
  citation = "Carter, J., 2021, The Louisiana Amphibian Monitoring Program from 1997 to 2017: Data: U.S. Geological Survey data release, https://doi.org/10.5066/P9VNBWM2.",
  paperDOI = "10.1371/journal.pone.0257869",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, use constraints none"),
  abstract = "Call observation data from the Louisiana Amphibian Monitoring Program (LAMP), part of the North American Amphibian Monitoring Program. Volunteers drove roadside routes of 10 stops in three Louisiana regions in winter, spring and summer runs, scoring the calling index (0 not heard to 3 full chorus) of each frog and toad species at each stop.",
  samplingProtocol = "NAAMP roadside calling survey: at each of 10 stops per route, observers listen for a fixed period after dark and score each species' calling index 0-3; three runs per year (winter, spring, summer windows that differ by region).",
  samplingProtocolCode = "acoustic", surveyEvidence = "row_presence", responseType = "ordinal", unitKind = "site",
  closure = "open", closureNote = "occasion = survey night within a sampling year; the three runs (winter, spring, summer) target seasonal calling windows, so a species' calling availability changes between runs (obs_run)",
  occasionKind = "time", taxonInclusion = "target",
  stateCodes = list(`0` = "not heard", `1` = "individuals can be counted; calls do not overlap", `2` = "calls of individuals distinguishable with some overlap", `3` = "full chorus; calls continuous and overlapping"),
  geographicCoverage = list(description = "Louisiana, USA (North, South and Florida-parishes regions)", boundingBox = list(west = -94.17, east = -88.75, south = 29.00, north = 33.10)),
  temporalCoverage = "1997/2017",
  notes = "Sampling year as deposited (period); the calendar year of the ten December 1997 rows is ambiguous in the release (see script header), so no ISO date is given: obs_month and obs_day carry the recorded month and day. Nine route-year-runs were surveyed on two nights; both are kept as separate occasions.",
  notShipped = list(nothing = "every deposited row and column is shipped"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/carter_2021_louisiana_lamp_calls.R")

stage_dict_row(TABLE,
  description = "Calling index (0 not heard to 3 full chorus) of 26 frog and toad species and one genus-level treefrog group at the 10 stops of 54 Louisiana Amphibian Monitoring Program roadside routes, three seasonal runs a year, 1997-2017.",
  url = "https://doi.org/10.5066/P9VNBWM2",
  reference = "Carter, J., Johnson, D., Boundy, J., & Vermillion, W. (2021). The Louisiana Amphibian Monitoring Program from 1997 to 2017: Results, analyses, and lessons learned. PLOS ONE, 16(9), e0257869.",
  doi_paper = "10.1371/journal.pone.0257869", doi_data = "10.5066/P9VNBWM2",
  original_license = "US public domain (USGS data release; use constraints none)", derived_license = "CC0 1.0",
  notes = "Ordinal calling index (NAAMP protocol). Unit = route stop, cluster_id = route. No coordinates in the release. Date fields shipped as month/day only (year of the December 1997 rows ambiguous).",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Ordinal index (calling index; multi-season)",
  sampling_protocol = "acoustic", design = "Multi-season (21 years x up to 3 seasonal runs)", realm = "Freshwater", country = "USA",
  coordinates = "None in source", notes = "NAAMP roadside calling routes; y > 0 collapses to a detection.")
