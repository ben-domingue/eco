#!/usr/bin/env Rscript
# Table:  glorioso_2025_atchafalaya_ves
# Source: USGS ScienceBase doi:10.5066/P9T71JCO (US public domain / CC0), published 2025-03-25
#   Glorioso, B.M. & Waddle, J.H. (2025). Data from time-constrained visual encounter
#   surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin
#   conducted from 2008 through 2016. U.S. Geological Survey data release.
# Paper:  none named in the release (ARMI monitoring; see USGS Fact Sheet 2011-3056).
# Data:   Sample_Data.csv: 2,221 samples (site x date; Sample # = consecutive sample of the
#         year at that site, 1-7; mostly 4 or 6 per site-year), start/end time, personnel
#         codes, air temperature, humidity, wind, water temperature, water depth, weather.
#         Observations.csv: 17,364 rows, one per animal seen on the time-constrained
#         visual encounter survey (VES): Sample ID, species (47 amphibians and reptiles),
#         sex, length, substrate. Site_Var_Loc_Desc.csv: 70 sites with decimal coordinates,
#         management unit, owner, parish. Vocalizations.csv and Tadpoles_Larvae.csv are
#         other methods (the calling index is table glorioso_2025_atchafalaya_calls).
#         Checked: one Sample ID (348) appears in Observations and Vocalizations but not
#         in Sample_Data (dropped, logged); five samples have no Sample # and are flagged by
#         the authors as done in error (dropped with their observations, logged). Start/End are
#         clock times; durations crossing midnight are corrected modulo 24 h.
#
# Mapping (standard section 3.2 N-mixture, multi-species -> community counts):
#   unit = site, taxon = 6-letter code (3 genus + 3 species letters), period = year index
#   1..9 (2008-2016, calendar year in the periods table), occasion = Sample # within the
#   year, y = number of individuals of the species recorded on that VES (0 for every
#   species on the 47-species list at every sample). date, observer (personnel codes,
#   comma-separated), obs_duration_min, obs_air_temp_c, obs_humidity_pct, obs_wind_ms,
#   obs_water_temp_c, obs_water_depth_cm, obs_weather; unit_ coordinates as published
#   (USGS releases them; sites are on public land), management unit, owner, parish.
#   Larval/tadpole detections and the per-animal sex/length/substrate are not shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "glorioso_2025_atchafalaya_ves"
SB <- "https://www.sciencebase.gov/catalog/file/get/5eb5880c82ce25b5135ae784?f=%s"
files <- c(Sample_Data.csv = "__disk__67%2F2c%2F4b%2F672c4b967096cd0a1e180355f2db4b5e028540be",
           Observations.csv = "__disk__c0%2F13%2F5d%2Fc0135d171534aa8c12d130224c58e076d7aba9d7",
           Site_Var_Loc_Desc.csv = "__disk__d0%2Fcf%2Fbc%2Fd0cfbc6e8d146aaff82803aca79f23b05ff08dcb")
rd <- function(f) fread(download_cached(sprintf(SB, files[[f]]), TABLE, filename = f), na.strings = c("NULL", ""))
sd <- rd("Sample_Data.csv"); ob <- rd("Observations.csv"); si <- rd("Site_Var_Loc_Desc.csv")
setnames(sd, c("sid", "sampno", "site", "date", "start", "end", "personnel", "air_temp_c", "humidity_pct", "wind_ms", "salinity",
               "water_temp_c", "perm_water", "eph_water", "water_depth_cm", "weather", "comments"))
stopifnot(nrow(sd) == 2221, !anyDuplicated(sd$sid), uniqueN(sd$site) == 70)
# five samples have no Sample # ("extra sample done in error, not used in occupancy analysis"): dropped
stopifnot(sum(is.na(sd$sampno)) == 5, all(grepl("done in error", sd[is.na(sampno), comments])))
cat("  dropped 5 samples with no Sample # (flagged by the authors as done in error)\n")
sd <- sd[!is.na(sampno)]; stopifnot(all(sd$sampno %in% 1:7))
sd[, date := as.IDate(date, "%m/%d/%Y")]; sd[, year := year(date)]; stopifnot(all(sd$year %in% 2008:2016))
stopifnot(!anyDuplicated(sd[, .(site, year, sampno)]))
dur <- as.numeric(difftime(as.POSIXct(sd$end, format = "%H:%M", tz = "UTC"), as.POSIXct(sd$start, format = "%H:%M", tz = "UTC"), units = "mins"))
dur <- ifelse(dur < 0, dur + 1440, dur)
bad_dur <- !is.na(dur) & dur > 120; stopifnot(sum(bad_dur) == 2)   # two samples with a mistyped clock time
cat(sprintf("  %d implausible durations (%s min) set to missing\n", sum(bad_dur), paste(dur[bad_dur], collapse = ", ")))
dur[bad_dur] <- NA
sd[, duration_min := dur]
stopifnot(nrow(ob) == 17364, uniqueN(ob$Species) == 47)
orphan <- setdiff(ob$`Sample ID`, sd$sid); stopifnot(348L %in% orphan)
cat(sprintf("  dropped %d observation row(s) whose Sample ID is not a kept sample (%s)\n", sum(ob$`Sample ID` %in% orphan), paste(orphan, collapse = ",")))
ob <- ob[`Sample ID` %in% sd$sid]

sp <- data.table(scientificName = sort(unique(ob$Species)))
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", scientificName), 1, 3), substr(sub("^[^ ]+ ", "", scientificName), 1, 3)))]
stopifnot(!anyDuplicated(sp$taxon))
counts <- merge(ob[, .(n = .N), by = .(sid = `Sample ID`, scientificName = Species)], sp, by = "scientificName")

years <- 2008:2016
stopifnot(all(si$Site %in% sd$site), !anyNA(si$Latitude), all(si$Latitude > 29.8 & si$Latitude < 30.6), all(si$Longitude > -91.9 & si$Longitude < -91.2))
surveys <- merge(sd, si[, .(site = Site, decimalLatitude = Latitude, decimalLongitude = Longitude, management_unit = `Management Unit`,
                            owner = Owner, parish = Parish)], by = "site")
stopifnot(nrow(surveys) == 2216)
long <- surveys[, .(unit = site, period = match(year, years), occasion = sampno, date = format(date), observer = personnel,
                    unit_decimalLatitude = decimalLatitude, unit_decimalLongitude = decimalLongitude, unit_management_unit = management_unit,
                    unit_owner = owner, unit_parish = parish,
                    obs_duration_min = duration_min, obs_air_temp_c = air_temp_c, obs_humidity_pct = humidity_pct, obs_wind_ms = wind_ms,
                    obs_water_temp_c = water_temp_c, obs_water_depth_cm = water_depth_cm, obs_weather = weather, sid)]
long <- long[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(surveys))]
long <- merge(long, counts[, .(sid, taxon, y = n)], by = c("sid", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, sid := NULL]
stopifnot(nrow(long) == 2216 * 47, sum(long$y) == nrow(ob))

taxa <- make_taxa(sp$taxon, sp$scientificName)
taxa[, taxon_group := sapply(sp$scientificName, function(n) { r <- fromJSON(file.path(GBIF_DIR, paste0(gsub("[^A-Za-z0-9]+", "_", n), ".json"))); r$class %||% NA_character_ })]
periods <- data.table(period = seq_along(years), year = years)
dataset <- list(
  title = "Time-constrained visual encounter survey counts of amphibians and reptiles at 70 sites in the Atchafalaya Basin, Louisiana, 2008-2016",
  creator = "Glorioso, Brad M.; Waddle, J. Hardin", pubDate = "2025", doi = "10.5066/P9T71JCO", sourceURL = "https://doi.org/10.5066/P9T71JCO",
  citation = "Glorioso, B.M., and Waddle, J.H., 2025, Data from time-constrained visual encounter surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin conducted from 2008 through 2016: U.S. Geological Survey data release, https://doi.org/10.5066/P9T71JCO.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, no access or use constraints"),
  abstract = "Data from time-constrained visual encounter surveys conducted in the Atchafalaya River Basin in South Central Louisiana from February 2008 through July 2016, with concurrent vocalization data and tadpole/larva presence, collected under the Amphibian Research and Monitoring Initiative to assess occupancy of amphibian and reptile species.",
  samplingProtocol = "Night-time time-constrained visual encounter surveys (nominally 20 minutes, 2-4 observers) at fixed sites, 4-6 samples per site per year; every animal seen is recorded with species, sex, length and substrate.",
  samplingProtocolCode = "ves", effortColumn = "obs_duration_min", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "occasion (samples within a calendar year); period = year",
  geographicCoverage = list(description = "Atchafalaya River Basin, Louisiana, USA", boundingBox = list(west = -91.8979, east = -91.2689, south = 29.8001, north = 30.5694)),
  temporalCoverage = "2008-02-19/2016-07-13",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS (sites on public management units)"),
  notShipped = list(Tadpoles_Larvae.csv = "larval presence by species (another method)", Vocalizations.csv = "calling index; see glorioso_2025_atchafalaya_calls",
                    `Sex, Length, Substrate` = "per-animal attributes lost by aggregation to counts", Salinity = "almost entirely missing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/glorioso_2025_atchafalaya_ves.R")

stage_dict_row(TABLE,
  description = "Counts of 47 amphibian and reptile species on 2,216 night-time time-constrained visual encounter surveys at 70 sites in the Atchafalaya Basin, Louisiana (2008-2016; 4-6 samples per site-year), with survey duration, weather and water variables, observers, and site coordinates.",
  url = "https://doi.org/10.5066/P9T71JCO", reference = "Glorioso, B.M., and Waddle, J.H., 2025, Data from time-constrained visual encounter surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin conducted from 2008 through 2016: U.S. Geological Survey data release.",
  doi_data = "10.5066/P9T71JCO", original_license = "CC0 1.0 (US public domain)", derived_license = "CC0 1.0",
  notes = "Zeros built from the sample table (a sample exists iff a row in Sample_Data). Orphan Sample ID 348 and five 'done in error' samples dropped. Companion table: glorioso_2025_atchafalaya_calls.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "ves", design = "Multi-season (9 years x 4-6 samples)", realm = "Freshwater", country = "USA",
  coordinates = "As published", notes = "Amphibians and reptiles (taxon_group per species in the taxa table). Unbalanced: sites enter and leave over 9 years.",
  status = "tagged")
