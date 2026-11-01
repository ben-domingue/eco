#!/usr/bin/env Rscript
# Table:  glorioso_2025_atchafalaya_calls
# Source: USGS ScienceBase doi:10.5066/P9T71JCO (US public domain / CC0), published 2025-03-25
#   Glorioso, B.M. & Waddle, J.H. (2025). Data from time-constrained visual encounter
#   surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin
#   conducted from 2008 through 2016. U.S. Geological Survey data release.
# Data:   Vocalizations.csv: 2,222 samples x 14 anuran species x {In, Out}: calling index
#         0 none / 1 individuals countable, gaps between calls / 2 overlapping calls but
#         individuals distinguishable / 3 full chorus, heard inside the study plot (In) and
#         outside it (Out). Sample_Data.csv supplies the site, date, times, personnel and
#         conditions of each sample (see glorioso_2025_atchafalaya_ves.R for the layout).
#         Checked: Sample ID 348 is in Vocalizations but not Sample_Data (dropped, logged);
#         every sample in Sample_Data has one vocalization row; the five samples without a
#         Sample # (done in error, per the authors) are dropped as in the VES table.
#
# Mapping (standard E2, responseType = ordinal): unit = site, taxon =
#   6-letter code, period = year index 1..9, occasion = Sample # within year, y = calling
#   index inside the plot (0-3; stateCodes in dataset.json), obs_call_index_outside = the
#   index for calls heard outside the plot (a row-level covariate, varies by species).
#   Same date / observer / obs_ / unit_ columns as the VES table, so the two can be joined
#   on (unit, period, occasion).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "glorioso_2025_atchafalaya_calls"
SB <- "https://www.sciencebase.gov/catalog/file/get/5eb5880c82ce25b5135ae784?f=%s"
files <- c(Sample_Data.csv = "__disk__67%2F2c%2F4b%2F672c4b967096cd0a1e180355f2db4b5e028540be",
           Vocalizations.csv = "__disk__1a%2Faa%2F48%2F1aaa480f9f9f997b34bcd1d645c4510fbc0ecdf2",
           Site_Var_Loc_Desc.csv = "__disk__d0%2Fcf%2Fbc%2Fd0cfbc6e8d146aaff82803aca79f23b05ff08dcb")
rd <- function(f) fread(download_cached(sprintf(SB, files[[f]]), TABLE, filename = f), na.strings = c("NULL", ""))
sd <- rd("Sample_Data.csv"); vo <- rd("Vocalizations.csv"); si <- rd("Site_Var_Loc_Desc.csv")
setnames(sd, c("sid", "sampno", "site", "date", "start", "end", "personnel", "air_temp_c", "humidity_pct", "wind_ms", "salinity",
               "water_temp_c", "perm_water", "eph_water", "water_depth_cm", "weather", "comments"))
stopifnot(nrow(sd) == 2221, !anyDuplicated(sd$sid), sum(is.na(sd$sampno)) == 5)
cat("  dropped 5 samples with no Sample # (flagged by the authors as done in error)\n")
sd <- sd[!is.na(sampno)]; stopifnot(all(sd$sampno %in% 1:7))
sd[, date := as.IDate(date, "%m/%d/%Y")]; sd[, year := year(date)]
dur <- as.numeric(difftime(as.POSIXct(sd$end, format = "%H:%M", tz = "UTC"), as.POSIXct(sd$start, format = "%H:%M", tz = "UTC"), units = "mins"))
sd[, duration_min := ifelse(dur < 0, dur + 1440, dur)]
stopifnot(nrow(vo) == 2222, !anyDuplicated(vo$`Sample ID`), all(sd$sid %in% vo$`Sample ID`))
orphan <- setdiff(vo$`Sample ID`, sd$sid); stopifnot(348L %in% orphan, length(orphan) == 6)
cat(sprintf("  dropped vocalization rows for Sample IDs %s (not a kept sample)\n", paste(orphan, collapse = ",")))
vo <- vo[`Sample ID` %in% sd$sid]
in_cols <- grep("_In$", names(vo), value = TRUE); out_cols <- sub("_In$", "_Out", in_cols)
stopifnot(length(in_cols) == 14, all(out_cols %in% names(vo)), all(as.matrix(vo[, c(in_cols, out_cols), with = FALSE]) %in% 0:3))
sp <- data.table(scientificName = sub("_In$", "", in_cols))
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", scientificName), 1, 3), substr(sub("^[^ ]+ ", "", scientificName), 1, 3)))]
stopifnot(!anyDuplicated(sp$taxon))
vin <- melt(vo[, c("Sample ID", in_cols), with = FALSE], id.vars = "Sample ID", variable.name = "col", value.name = "y", variable.factor = FALSE)
vout <- melt(vo[, c("Sample ID", out_cols), with = FALSE], id.vars = "Sample ID", variable.name = "col", value.name = "out", variable.factor = FALSE)
vin[, scientificName := sub("_In$", "", col)]; vout[, scientificName := sub("_Out$", "", col)]
calls <- merge(vin[, .(sid = `Sample ID`, scientificName, y)], vout[, .(sid = `Sample ID`, scientificName, out)], by = c("sid", "scientificName"))
calls <- merge(calls, sp, by = "scientificName")

years <- 2008:2016
surveys <- merge(sd, si[, .(site = Site, decimalLatitude = Latitude, decimalLongitude = Longitude, management_unit = `Management Unit`,
                            owner = Owner, parish = Parish)], by = "site")
long <- merge(surveys[, .(sid, unit = site, period = match(year, years), occasion = sampno, date = format(date), observer = personnel,
                          unit_decimalLatitude = decimalLatitude, unit_decimalLongitude = decimalLongitude, unit_management_unit = management_unit,
                          unit_owner = owner, unit_parish = parish, obs_duration_min = duration_min, obs_air_temp_c = air_temp_c,
                          obs_humidity_pct = humidity_pct, obs_wind_ms = wind_ms, obs_water_temp_c = water_temp_c,
                          obs_water_depth_cm = water_depth_cm, obs_weather = weather)],
              calls[, .(sid, taxon, y, obs_call_index_outside = out)], by = "sid")
long[, sid := NULL]
stopifnot(nrow(long) == 2216 * 14, !anyNA(long$y))

taxa <- make_taxa(sp$taxon, sp$scientificName)
periods <- data.table(period = seq_along(years), year = years)
dataset <- list(
  title = "Anuran calling-index surveys at 70 sites in the Atchafalaya Basin, Louisiana, 2008-2016",
  creator = "Glorioso, Brad M.; Waddle, J. Hardin", pubDate = "2025", doi = "10.5066/P9T71JCO", sourceURL = "https://doi.org/10.5066/P9T71JCO",
  citation = "Glorioso, B.M., and Waddle, J.H., 2025, Data from time-constrained visual encounter surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin conducted from 2008 through 2016: U.S. Geological Survey data release, https://doi.org/10.5066/P9T71JCO.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, no access or use constraints"),
  abstract = "Vocalization (calling index) data for 14 anuran species collected concurrently with night-time visual encounter surveys in the Atchafalaya River Basin, Louisiana, 2008-2016, under the Amphibian Research and Monitoring Initiative.",
  samplingProtocol = "Aural survey during each night-time site visit; calling intensity of each species scored 0-3 separately for calls inside and outside the study plot.",
  samplingProtocolCode = "acoustic", effortColumn = "obs_duration_min", surveyEvidence = "sample_table", responseType = "ordinal", unitKind = "site",
  closure = "occasion (samples within a calendar year); period = year",
  stateCodes = list(`0` = "no calling inside the plot", `1` = "individuals can be counted; gaps between calls", `2` = "calls overlap but individuals distinguishable", `3` = "full chorus; individuals not distinguishable"),
  geographicCoverage = list(description = "Atchafalaya River Basin, Louisiana, USA", boundingBox = list(west = -91.8979, east = -91.2689, south = 29.8001, north = 30.5694)),
  temporalCoverage = "2008-02-19/2016-07-13",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS (sites on public management units)"),
  notes = "Companion of glorioso_2025_atchafalaya_ves (same samples); y > 0 collapses to a detection for occupancy models.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/glorioso_2025_atchafalaya_calls.R")

stage_dict_row(TABLE,
  description = "Calling index (0 none to 3 full chorus) of 14 frog and toad species inside the study plot on 2,216 night-time site visits at 70 Atchafalaya Basin sites, Louisiana (2008-2016), with the outside-plot index as a covariate, survey conditions, observers and site coordinates.",
  url = "https://doi.org/10.5066/P9T71JCO", reference = "Glorioso, B.M., and Waddle, J.H., 2025, Data from time-constrained visual encounter surveys and acoustic surveys for amphibians and reptiles in the Atchafalaya Basin conducted from 2008 through 2016: U.S. Geological Survey data release.",
  doi_data = "10.5066/P9T71JCO", original_license = "CC0 1.0 (US public domain)", derived_license = "CC0 1.0",
  notes = "Ordinal calling index (responseType ordinal, standard E2). Orphan Sample ID 348 and five 'done in error' samples dropped. Companion: glorioso_2025_atchafalaya_ves.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Ordinal index (calling index; multi-season)",
  sampling_protocol = "acoustic", design = "Multi-season (9 years x 4-6 samples)", realm = "Freshwater", country = "USA",
  coordinates = "As published", notes = "y is an ordinal 0-3 calling index; same surveys as the VES table.",
  status = "tagged")
