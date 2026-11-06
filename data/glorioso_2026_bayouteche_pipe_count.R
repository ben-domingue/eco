#!/usr/bin/env Rscript
# Table:  glorioso_2026_bayouteche_pipe_count
# Source: USGS ScienceBase doi:10.5066/P97QPY0E (USGS data release, published 2026-01-14; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Glorioso, B.M., and Waddle, J.H., 2026, Data from a capture-mark-recapture survey of native
#   treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023: U.S.
#   Geological Survey data release.
# Data:   Installed.csv: four sites (50 numbered PVC pipes nailed to trees at each, as artificial
#         refugia) with coordinates and installation date. Sample Data.csv: 248 site surveys (62 per
#         site, one a month at every site when surveyed, October 2017 to May 2023) with start and end
#         time, previous-night low and daytime high temperature, weather, herpetofauna seen and heard
#         outside the pipes, comments, personnel. Pipe Check Data.csv: 12,400 pipe checks (50 per
#         survey) with water present / dumped, bycatch, comments and the count of each of nine
#         taxa in the pipe (treefrogs Hyla chrysoscelis HCHR, H. cinerea HCIN, H. squirella HSQU,
#         Pseudacris crucifer PCRU; Anolis carolinensis ACAR, Pantherophis obsoletus POBS,
#         Plestiodon fasciatus PFAS, P. laticeps PLAT, Plestiodon sp.), NULL where none. Frog
#         Capture Data.csv: 8,290 tagged-frog captures (tag, recapture flag, sex, SVL). Air
#         Temp_Humidity.csv: logger series. Asserted: one survey per site per month, 50 checks per
#         survey, one row per survey x pipe, counts non-negative integers; the two 2019-07-18 surveys
#         at North Bend West and Centerville ("could not complete survey due to extreme flooding")
#         have no water status and no animal in any pipe.
# Mapping: unit = pipe ("<site>_<pipe>"), cluster_id = site, period = month of the study (1 =
#   October 2017 ... 68 = May 2023; months with no survey have no rows), no occasion (one check per
#   pipe per month), taxon = the nine pipe taxa, y = number in the pipe at the check (NULL = 0;
#   surveyEvidence sample_table: a row of the pipe-check file is a check). Plestiodon sp. is its
#   own taxon at genus rank (E6). obs_ water present / dumped, survey start time, temperatures,
#   weather; unit_ coordinates are the site's (as published; refuge land, no flagged taxon).
# Not shipped: the two flooded surveys (100 pipe rows; pipes not checked); the tagged-frog capture
#   records (individual histories: a CJS table per species is possible from Frog Capture Data and
#   is not built here); animals seen or heard outside the pipes (Seen / Heard, not a pipe count);
#   bycatch; the air temperature / humidity logger series.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "glorioso_2026_bayouteche_pipe_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/655250cfd34ee4b6e05c3679?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f, ...) fread(download_cached(fl[[f]], TABLE, filename = f), na.strings = c("NULL", ""), ...)
s <- rd("Sample Data.csv"); ck <- rd("Pipe Check Data.csv", colClasses = list(character = "Pipe Number")); ins <- rd("Installed.csv")
sp <- c("HCHR", "HCIN", "HSQU", "PCRU", "ACAR", "POBS", "PFAS", "PLAT", "Plestiodon")
s[, d := as.IDate(Date, format = "%m/%d/%Y")]
s[, mon := (year(d) - 2017L) * 12L + month(d) - 9L]
stopifnot(nrow(s) == 248, !anyDuplicated(s$ID), !anyNA(s$d), !anyDuplicated(s[, .(`Site Name`, mon)]), nrow(ins) == 4,
          setequal(ins$`Site Name`, s$`Site Name`), min(s$mon) == 1, max(s$mon) == 68)
stopifnot(nrow(ck) == 12400, all(ck[, .N, by = `Sample ID`]$N == 50), !anyDuplicated(ck[, .(`Sample ID`, `Pipe Number`)]),
          setequal(ck$`Sample ID`, s$ID), all(unlist(ck[, ..sp]) >= 0, na.rm = TRUE))
fl_ids <- s[grepl("could not complete survey due to extreme flooding", Comments), ID]
stopifnot(length(fl_ids) == 2, all(ck[`Sample ID` %in% fl_ids, is.na(`Water Present`) | `Water Present` == "NA"]),
          all(is.na(unlist(ck[`Sample ID` %in% fl_ids, ..sp]))), sum(is.na(ck$`Water Present`) | ck$`Water Present` == "NA") == 100)
ck <- ck[!`Sample ID` %in% fl_ids]
m <- melt(ck[, c("Sample ID", "Pipe Number", "Water Present", "Water Dumped", sp), with = FALSE], id.vars = c("Sample ID", "Pipe Number", "Water Present", "Water Dumped"),
          variable.name = "taxon", value.name = "y")
m[is.na(y), y := 0]
stopifnot(all(m$y == round(m$y)))
m <- merge(m, s[, .(`Sample ID` = ID, site = `Site Name`, d, mon, start = `Start Time`, low = `Previous Night Low`, high = `Daytime High`, Weather)], by = "Sample ID")
m <- merge(m, ins[, .(site = `Site Name`, lat = Latitude, lon = Longitude)], by = "site")
long <- m[, .(unit = paste0(gsub("[^A-Za-z]", "", site), "_", `Pipe Number`), taxon = as.character(taxon), y = as.integer(y), period = mon,
              date = format(d), cluster_id = site, unit_decimalLatitude = lat, unit_decimalLongitude = lon,
              obs_water_present = as.integer(`Water Present` == "Y"), obs_water_dumped = as.integer(`Water Dumped` == "Y"),
              obs_start_time = start, obs_prev_night_low_c = low, obs_daytime_high_c = high, obs_weather = Weather)]
stopifnot(nrow(long) == 246 * 50 * 9, uniqueN(long$unit) == 200, sum(long$y) == 8554)
mons <- data.table(period = 1:68)[, `:=`(year = 2017L + (period + 8L) %/% 12L, month = (period + 8L) %% 12L + 1L)]
mons <- mons[period %in% long$period]
taxa <- make_taxa(sp, c("Hyla chrysoscelis", "Hyla cinerea", "Hyla squirella", "Pseudacris crucifer", "Anolis carolinensis",
                        "Pantherophis obsoletus", "Plestiodon fasciatus", "Plestiodon laticeps", "Plestiodon"),
                  vernacularName = c("Cope's gray treefrog", "Green treefrog", "Squirrel treefrog", "Spring peeper", "Green anole",
                                     "Western ratsnake", "Common five-lined skink", "Broad-headed skink", NA),
                  taxonRank = c(rep("species", 8), "genus"),
                  taxonRemarks = c(rep(NA, 8), "lizards identified only to Plestiodon"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Monthly counts of treefrogs and other herpetofauna in 200 PVC pipe refugia at four sites, Bayou Teche National Wildlife Refuge, Louisiana, 2017-2023",
  creator = "Glorioso, Brad M.; Waddle, J. Hardin",
  pubDate = "2026", doi = "10.5066/P97QPY0E", sourceURL = "https://doi.org/10.5066/P97QPY0E",
  citation = "Glorioso, B.M., and Waddle, J.H., 2026, Data from a capture-mark-recapture survey of native treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023: U.S. Geological Survey data release, https://doi.org/10.5066/P97QPY0E.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Fifty PVC pipes hung on trees at each of four sites in Bayou Teche National Wildlife Refuge, Louisiana, were checked about monthly from October 2017 to May 2023 as part of a capture-mark-recapture study of native treefrogs. Every animal in each pipe was counted by species: four treefrog species and five lizard and snake taxa.",
  samplingProtocol = "Each month all four sites were visited in turn and each of 50 numbered PVC pipes (artificial refugia nailed to trees) was checked, recording water in the pipe and the number of each amphibian and reptile taxon inside; frogs were tagged and released.",
  samplingProtocolCode = "pvc_pipe", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "none", occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Bayou Teche National Wildlife Refuge, St. Mary Parish, Louisiana, USA",
                            boundingBox = list(west = min(ins$Longitude), east = max(ins$Longitude), south = min(ins$Latitude), north = max(ins$Latitude))),
  temporalCoverage = "2017-10/2023-05",
  coordinatesCoarsened = list(value = FALSE, method = "site coordinates as published by USGS (national wildlife refuge; no taxon CR, EN or VU)"),
  notShipped = list(flooded_surveys = "two 2019-07-18 surveys abandoned for flooding: 100 pipes not checked",
                    frog_captures = "Frog Capture Data.csv: tagged-frog captures (individual histories), not built in this table",
                    seen_heard = "animals seen or heard outside the pipes (survey-level lists)",
                    bycatch = "non-herpetofauna bycatch", loggers = "air temperature and humidity logger series"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = mons, script = "data/glorioso_2026_bayouteche_pipe_count.R")
stage_dict_row(TABLE,
  description = "Counts of four treefrog species and five lizard and snake taxa in each of 200 PVC pipe refugia at four sites in Bayou Teche National Wildlife Refuge, Louisiana, checked monthly from October 2017 to May 2023.",
  url = "https://doi.org/10.5066/P97QPY0E",
  reference = "Glorioso, B.M., and Waddle, J.H. (2026). Data from a capture-mark-recapture survey of native treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023. U.S. Geological Survey data release.",
  doi_data = "10.5066/P97QPY0E", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "unit = pipe, period = study month; the tagged-frog histories are not built.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Open N-mixture / dynamic occupancy (community)", sampling_protocol = "pvc_pipe",
  design = "Multi-season (62 monthly checks over 68 months)", realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Artificial refugia (PVC pipes) for treefrogs; lizards and snakes also counted.")
