#!/usr/bin/env Rscript
# Tables: glorioso_2020_bigthicket_ves, glorioso_2020_bigthicket_calls
# Source: USGS ScienceBase doi:10.5066/P99Z3UZU (USGS data release, published 2020-08-07; use
#         constraints name only the product-names disclaimer and "read the metadata"; US public
#         domain, recorded as CC0 1.0)
#   Glorioso, B.M., and Waddle, J.H., 2020, Data from visual encounter and acoustic monitoring
#   surveys targeting amphibians and reptiles in Big Thicket National Preserve in southeast Texas
#   from August 2010 to September 2018: U.S. Geological Survey data release.
# Paper:  none named in the release (USGS Amphibian Research and Monitoring Initiative monitoring,
#   the same protocol as glorioso_2025_atchafalaya_ves / _calls).
# Data:   Sample Data.csv: 1,779 surveys (Survey_ID) at 52 sites, 2010-2018, with date, site,
#         personnel codes, Sample (the round of the year: each round aims to survey every site),
#         channel salinity (ppt), start and end time (each deposited twice, identically), air
#         temperature (C), humidity (%), wind (mph), water temperature, backwater salinity and
#         temperature (occasional), weather and comments. Sample Matrix.csv: surveys per site per
#         year (asserted equal to Sample Data). Site Locations.csv: 52 sites with management unit
#         and coordinates (decimal degrees). Observations.csv: 6,128 animals seen on the
#         time-constrained visual encounter survey (VES), 37 amphibian and reptile species, with
#         sex, SVL, substrate, height. Vocalizations.csv: one row per survey, calling index
#         (0-3) inside (_In) and outside (_Out) the survey area for 14 anuran species; the 40
#         surveys of rounds 3 and 4 of 2012 at the 20 sites added mid-2012 have no value for
#         Eleutherodactylus cystignathoides (not scored). BITH*.csv and Salinity Logger
#         Locations.csv: hourly conductivity and water temperature from nine loggers.
#         Asserted: one survey per site x year x Sample, the matrix agrees, every observation and
#         vocalization row belongs to a survey, and the only missing calling values are the 40
#         E. cystignathoides pairs.
# Mapping: unit = site, period = calendar year (2010-2018), occasion = Sample (round) within the
#   year, date, observer = personnel codes. _ves: taxon = 6-letter code (3 genus + 3 species
#   letters), y = individuals of the species seen on that VES, zeros for every one of the 37
#   species recorded at every survey (taxonInclusion recorded; surveyEvidence sample_table).
#   _calls: responseType ordinal, y = calling index inside the survey area, obs_call_index_outside
#   = the index outside (varies by species within a survey, E5), taxonInclusion target (the 14
#   species on the data sheet); __survey_taxa lists the taxa scored at each survey, omitting
#   E. cystignathoides at the 40 surveys where it was not scored. obs_ duration (from start and
#   end), weather, temperatures, humidity, wind, channel salinity. Coordinates kept as USGS
#   published them for sites in a national preserve (no species is IUCN CR/EN/VU; asserted).
# Not shipped: per-animal sex, SVL, substrate and height (lost by counting); the logger series
#   (hourly conductivity, not linked to surveys); backwater salinity and temperature (rarely
#   measured, kept only as comments in the source's sense); comments (free text).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "glorioso_2020_bigthicket_ves"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5eb58a3582ce25b5135ae793?format=json", SRC, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], SRC, filename = f), na.strings = c("NULL", ""))
sd <- rd("Sample Data.csv"); mx <- rd("Sample Matrix.csv"); si <- rd("Site Locations.csv"); ob <- rd("Observations.csv"); vo <- rd("Vocalizations.csv")
stopifnot(nrow(sd) == 1779, !anyDuplicated(sd$Survey_ID), identical(names(sd)[7:10], c("Start_Time", "End_Time", "Start_Time", "End_Time")),
          identical(sd[[7]], sd[[9]]), identical(sd[[8]], sd[[10]]), nrow(si) == 52, !anyDuplicated(si$Site_Number), all(sd$Site_Number %in% si$Site_Number))
sd <- sd[, c(1:8, 11:18), with = FALSE]
sd[, date := as.IDate(Date, format = "%m/%d/%Y")]
sd[, year := year(date)]
stopifnot(!anyNA(sd$date), all(sd$year %in% 2010:2018), !anyNA(sd$Sample), !anyDuplicated(sd[, .(Site_Number, year, Sample)]))
mm <- melt(mx[, !"Comments"], id.vars = "Site_Number", variable.name = "yr", value.name = "n")[, year := as.integer(substr(yr, 1, 4))]
chk <- merge(sd[, .N, by = .(Site_Number, year)], mm[n > 0], by = c("Site_Number", "year"), all = TRUE)
stopifnot(!anyNA(chk), all(chk$N == chk$n))
dur <- as.numeric(difftime(as.POSIXct(sd$End_Time, format = "%H:%M", tz = "UTC"), as.POSIXct(sd$Start_Time, format = "%H:%M", tz = "UTC"), units = "mins"))
sd[, duration_min := ifelse(!is.na(dur) & dur < 0, dur + 1440, dur)]
stopifnot(all(ob$Survey_ID %in% sd$Survey_ID), nrow(ob) == 6128, uniqueN(ob$Species) == 37,
          nrow(vo) == 1779, setequal(vo$Survey_ID, sd$Survey_ID))
stopifnot(all(abs(si$Latitude - 30.15) < 0.1), all(abs(si$Longitude + 94.1) < 0.1))
code6 <- function(n) toupper(paste0(substr(sub(" .*$", "", n), 1, 3), substr(sub("^[^ ]+ ", "", n), 1, 3)))
base <- merge(sd, si[, .(Site_Number, Management_Unit, Latitude, Longitude)], by = "Site_Number")
base <- base[, .(Survey_ID, unit = as.character(Site_Number), period = year - 2009L, occasion = as.integer(Sample), date = format(date),
                 observer = Personnel_Code, unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude,
                 unit_management_unit = Management_Unit, obs_duration_min = duration_min, obs_air_temp_c = Air_Temp,
                 obs_humidity_pct = Humidity, obs_wind_mph = Wind, obs_water_temp_c = Water_Temp, obs_salinity_ppt = Salinity,
                 obs_weather = Weather)]
periods <- data.table(period = 1:9, year = 2010:2018)
geo <- list(description = "Big Thicket National Preserve (Lower Neches River corridor and nearby units), Jefferson, Hardin and Orange counties, Texas, USA",
            boundingBox = list(west = min(si$Longitude), east = max(si$Longitude), south = min(si$Latitude), north = max(si$Latitude)))
common <- list(creator = "Glorioso, Brad M.; Waddle, J. Hardin", pubDate = "2020", doi = "10.5066/P99Z3UZU", sourceURL = "https://doi.org/10.5066/P99Z3UZU",
  citation = "Glorioso, B.M., and Waddle, J.H., 2020, Data from visual encounter and acoustic monitoring surveys targeting amphibians and reptiles in Big Thicket National Preserve in southeast Texas from August 2010 to September 2018: U.S. Geological Survey data release, https://doi.org/10.5066/P99Z3UZU.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (no access or use constraints beyond the product-names disclaimer)"),
  surveyEvidence = "sample_table", unitKind = "site", closure = "closed",
  closureNote = "occasion = sampling round within a calendar year (one to six rounds); period = year", occasionKind = "time",
  geographicCoverage = geo, temporalCoverage = "2010-08/2018-09",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS (sites in Big Thicket National Preserve; no species is IUCN CR, EN or VU)"))
ref <- "Glorioso, B.M., and Waddle, J.H. (2020). Data from visual encounter and acoustic monitoring surveys targeting amphibians and reptiles in Big Thicket National Preserve in southeast Texas from August 2010 to September 2018. U.S. Geological Survey data release."

## ---- VES counts ----
TABLE <- "glorioso_2020_bigthicket_ves"
sp <- data.table(scientificName = sort(unique(ob$Species)))[, taxon := code6(scientificName)]
stopifnot(!anyDuplicated(sp$taxon))
cnt <- merge(ob[, .(n = .N), by = .(Survey_ID, scientificName = Species)], sp, by = "scientificName")
long <- base[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(base))]
long <- merge(long, cnt[, .(Survey_ID, taxon, y = n)], by = c("Survey_ID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L][, Survey_ID := NULL]
stopifnot(nrow(long) == 1779 * 37, sum(long$y) == 6128)
taxa <- make_taxa(sp$taxon, sp$scientificName)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- c(list(
  title = "Time-constrained visual encounter survey counts of amphibians and reptiles at 52 sites in Big Thicket National Preserve, Texas, 2010-2018",
  abstract = "Amphibian Research and Monitoring Initiative surveys at 52 sites in Big Thicket National Preserve, southeast Texas, August 2010 to September 2018, to monitor amphibian and reptile populations and their response to saltwater intrusion. Each survey is a night-time time-constrained visual encounter survey; every animal seen is recorded by species.",
  samplingProtocol = "Night-time time-constrained visual encounter surveys (about ten minutes, two to four observers) at fixed sites, one to six rounds per year; every amphibian and reptile seen is recorded to species.",
  samplingProtocolCode = "ves", responseType = "count", taxonInclusion = "recorded", effortColumn = "obs_duration_min",
  notShipped = list(per_animal = "sex, SVL, substrate, height and comments of each animal (lost by counting)",
                    loggers = "BITH*.csv: hourly conductivity and water temperature at nine loggers, not linked to surveys",
                    backwater = "Backwater_Salinity and Backwater_Water_Temp: occasional comparison readings",
                    comments = "survey comments (free text)",
                    calls = "Vocalizations.csv: the calling index is table glorioso_2020_bigthicket_calls")), common)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/glorioso_2020_bigthicket.R")
stage_dict_row(TABLE,
  description = "Counts of 37 amphibian and reptile species on 1,779 night-time visual encounter surveys at 52 sites in Big Thicket National Preserve, Texas, 2010-2018, with duration, weather, water temperature and salinity, observers and site coordinates.",
  url = "https://doi.org/10.5066/P99Z3UZU", reference = ref, doi_data = "10.5066/P99Z3UZU",
  original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "ARMI protocol as in glorioso_2025_atchafalaya_ves; companion table glorioso_2020_bigthicket_calls.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "N-mixture (multi-species, multi-season)", sampling_protocol = "ves",
  design = "Multi-season (9 years x 1-6 rounds)", realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Amphibians and reptiles; saltwater-intrusion monitoring.")

## ---- calling index ----
TABLE <- "glorioso_2020_bigthicket_calls"
in_cols <- grep("_In$", names(vo), value = TRUE); out_cols <- sub("_In$", "_Out", in_cols)
stopifnot(length(in_cols) == 14, all(out_cols %in% names(vo)))
vin <- melt(vo[, c("Survey_ID", in_cols), with = FALSE], id.vars = "Survey_ID", variable.name = "col", value.name = "y")
vout <- melt(vo[, c("Survey_ID", out_cols), with = FALSE], id.vars = "Survey_ID", variable.name = "col", value.name = "out")
vin[, scientificName := sub("_In$", "", col)]; vout[, scientificName := sub("_Out$", "", col)]
v <- merge(vin[, !"col"], vout[, !"col"], by = c("Survey_ID", "scientificName"))
stopifnot(identical(is.na(v$y), is.na(v$out)), sum(is.na(v$y)) == 40, all(v[is.na(y), scientificName] == "Eleutherodactylus cystignathoides"))
added12 <- sd[Survey_ID %in% v[is.na(y), Survey_ID]]
stopifnot(all(added12$year == 2012), all(added12$Sample %in% 3:4), uniqueN(added12$Site_Number) == 20)
v <- v[!is.na(y)]
stopifnot(all(v$y %in% 0:3), all(v$out %in% 0:3))
v[, taxon := code6(scientificName)]
long <- merge(base, v[, .(Survey_ID, taxon, y = as.integer(y), obs_call_index_outside = as.integer(out))], by = "Survey_ID")
st <- long[, .(unit, period, occasion, taxon)]
long[, Survey_ID := NULL]
stopifnot(nrow(long) == 1779 * 14 - 40)
csp <- unique(v[, .(taxon, scientificName)])
taxa <- make_taxa(csp$taxon, csp$scientificName)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- c(list(
  title = "Anuran calling index at 52 sites in Big Thicket National Preserve, Texas, 2010-2018 (14 species, inside and outside the survey area)",
  abstract = "Calling surveys made with each Amphibian Research and Monitoring Initiative visit to 52 sites in Big Thicket National Preserve, 2010-2018: for each of 14 frog and toad species the calling index (0 none to 3 full chorus) heard inside the survey area, with the index heard outside it as a covariate.",
  samplingProtocol = "At each night-time visit the observers record, for each anuran species on the data sheet, the calling index heard inside the survey area and outside it (0 none; 1 individuals countable; 2 calls overlapping, individuals distinguishable; 3 full chorus).",
  samplingProtocolCode = "call_survey", responseType = "ordinal",
  stateCodes = list(`0` = "no calling inside the survey area", `1` = "individuals can be counted; gaps between calls", `2` = "calls overlap but individuals distinguishable", `3` = "full chorus; individuals not distinguishable"),
  taxonInclusion = "target",
  notShipped = list(not_scored = "Eleutherodactylus cystignathoides at the 40 surveys of rounds 3 and 4 of 2012 at the 20 sites added that year: no value deposited (not surveyed for it; __survey_taxa)",
                    ves = "the visual encounter counts are table glorioso_2020_bigthicket_ves",
                    loggers = "BITH*.csv: hourly conductivity and water temperature, not linked to surveys")), common)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = st, script = "data/glorioso_2020_bigthicket.R")
stage_dict_row(TABLE,
  description = "Calling index (0-3) of 14 anuran species inside the survey area, with the index outside it, on 1,779 night-time surveys at 52 sites in Big Thicket National Preserve, Texas, 2010-2018.",
  url = "https://doi.org/10.5066/P99Z3UZU", reference = ref, doi_data = "10.5066/P99Z3UZU",
  original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Ordinal calling index; __survey_taxa omits E. cystignathoides where it was not scored. Companion table glorioso_2020_bigthicket_ves.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Ordinal occupancy (calling index)", sampling_protocol = "call_survey",
  design = "Multi-season (9 years x 1-6 rounds)", realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Anuran calling index; same visits as glorioso_2020_bigthicket_ves.")
