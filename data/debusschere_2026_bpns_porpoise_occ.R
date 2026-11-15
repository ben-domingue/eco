#!/usr/bin/env Rscript
# Table:  debusschere_2026_bpns_porpoise_occ
# Source: VLIZ IPT (eurobis) resource lifewatch_cpod, Darwin Core Archive, version 1.10 (published 2026-11-06);
#         GBIF sampling-event dataset ef8d8e2b-a206-4850-9a01-3da0233b39af; Marine Data Archive doi:10.14284/639;
#         EurOBIS / EMODnet Biology IMIS dataset 5531 (also served on EDITO, the European Digital Twin of the Ocean,
#         in the EMODnet Biology occurrence parquet). Licence: CC BY 4.0 (EML, every event row's `license`, and the
#         IMIS record "Attribution (CC BY)"). Earlier versions carried accessRights "not-for-profit use only" on the
#         event rows; E. Debusschere (VLIZ) confirmed by email 2026-11-10 that the dataset is CC BY 4.0 and the field
#         was corrected; this version has accessRights "CC BY 4.0" on every row (asserted).
#         Citation: Debusschere E, Calonge A, Conings B (2026). LifeWatch observatory data: Permanent Cetacean passive
#         acoustic sensor network in the Belgian Part of the North Sea. Version 1.10. Flanders Marine Institute (VLIZ).
#         Samplingevent dataset. https://doi.org/10.14284/639
# Paper:  none; protocol in the EML and https://www.lifewatch.be/en/cetacean-passive-acoustic-network.
#         C-POD and F-POD click loggers (Chelonia) moored next to shipwrecks and other structures in the Belgian part
#         of the North Sea; clicks classified as narrow-band high-frequency (harbour porpoise) click trains by the
#         KERNO classifier in cpod.exe; output summarised per hour.
# Data:   Darwin Core Archive (IPT serves only the current version; the cached zip is the build's record):
#   event.txt (449,293 rows), three levels: 2 device-type events (01_CPOD, 02_FPOD, with the instrument in eMoF),
#     172 deployments (parentEventID = device type; locality = station name, 24 stations; decimalLatitude/Longitude
#     and minimumDepthInMeters per deployment; eventRemarks bottom-mooring or surface-buoy; eventDate the deployment
#     interval), and 449,119 hours (eventID = <deployment>_<YYYY-MM-DD>_<HH>, eventDate one UTC hour, no
#     coordinates of their own).
#   occurrence.txt (449,119 rows): one Phocoena phocoena row per hour, occurrenceStatus present (159,076) or
#     absent (290,043).
#   extendedmeasurementorfact.txt: per hour, "Recorded minutes" (1-60), "sum of Detection Positive Minutes"
#     (0-60, never above recorded minutes), "Total number of clicks" (all clicks logged) and "Number of filtered
#     clicks" (clicks in classified porpoise trains); per device type, the instrument name.
#   Station coordinates differ slightly between deployments at a station (redeployment; at most 0.0032 deg latitude),
#   except one F-POD deployment at ReefballsBelwind (57130, 2023-06/10) at 2.913 E, 0.1 deg east of the others and
#   5 m deeper; kept as published.
#   At 9 stations two deployments overlap for some hours (15,568 station-hours: a C-POD beside an F-POD, or two
#   C-PODs during a swap); each deployment's hours are its own records.
# Mapping (detection, single species, passive acoustic): unit = deployment (one POD on one mooring; D<id>),
#   cluster_id = station (locality), so the deployment's own coordinates, depth, mooring and device are unit
#   covariates and simultaneous deployments at a station are separate units (as a camera deployment would be).
#   period = calendar month (1 = June 2014), occasion = hour of the month (1 = day 1, 00:00 UTC), date = the hour's
#   UTC date, obs_hour_utc its hour. y = 1 if any detection-positive minute in the hour (occurrenceStatus present,
#   asserted to coincide), y_raw = detection-positive minutes. obs_recorded_min = minutes the POD logged in the hour
#   (effortColumn); obs_total_clicks = all clicks logged (an ambient-noise / click-saturation covariate).
#   surveyEvidence = sample_table: every hour with recording time is an event with a measured "Recorded minutes"
#   (all >= 1); hours outside deployments, or with no recording, are not rows.
#   Coordinates: Phocoena phocoena is Least Concern (IUCN, asserted); stations are at sea; not coarsened.
# Not shipped: "Number of filtered clicks" (a second measure of the same classified detection, not a covariate);
#   the device-type events (their instrument name is unit_device).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "debusschere_2026_bpns_porpoise_occ"
zip <- download_cached("https://ipt.vliz.be/eurobis/archive.do?r=lifewatch_cpod", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by/4.0", eml, fixed = TRUE), grepl("Version 1.10.", eml, fixed = TRUE))

ev <- fread(file.path(dwca, "event.txt"), quote = "", colClasses = "character")
oc <- fread(file.path(dwca, "occurrence.txt"), quote = "", colClasses = "character")
mf <- fread(file.path(dwca, "extendedmeasurementorfact.txt"), quote = "", colClasses = "character")
stopifnot(nrow(ev) == 449293L, nrow(oc) == 449119L, !anyDuplicated(ev$eventID),
          all(ev$license == "http://creativecommons.org/licenses/by/4.0/legalcode"), all(ev$accessRights == "CC BY 4.0"))

dev <- ev[parentEventID == ""]
dep <- ev[parentEventID %in% dev$eventID]
hr  <- ev[parentEventID %in% dep$eventID]
stopifnot(setequal(dev$eventID, c("01_CPOD", "02_FPOD")), nrow(dep) == 172L, nrow(hr) == 449119L,
          nrow(dev) + nrow(dep) + nrow(hr) == nrow(ev),
          uniqueN(dep$locality) == 24L, all(dep$locality != ""), all(dep$decimalLatitude != ""), all(dep$decimalLongitude != ""),
          all(dep$eventRemarks %in% c("bottom-mooring", "surface-buoy")),
          all(hr$decimalLatitude == ""), all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:00:00Z/", hr$eventDate)))
hr[, start := substr(eventDate, 1, 20)]
stopifnot(all(hr$eventID == paste0(hr$parentEventID, "_", substr(hr$start, 1, 10), "_", substr(hr$start, 12, 13))))

# occurrences: one porpoise row per hour
stopifnot(all(oc$scientificName == "Phocoena phocoena"), all(oc$scientificNameID == "urn:lsid:marinespecies.org:taxname:137117"),
          setequal(oc$eventID, hr$eventID), !anyDuplicated(oc$eventID),
          sum(oc$occurrenceStatus == "present") == 159076L, sum(oc$occurrenceStatus == "absent") == 290043L)
# measurements: four per hour
mh <- mf[id %in% hr$eventID]
stopifnot(nrow(mh) == 4L * nrow(hr), nrow(mf) == nrow(mh) + 2L,
          setequal(mh$measurementType, c("Recorded minutes", "sum of Detection Positive Minutes", "Total number of clicks", "Number of filtered clicks")))
mw <- dcast(mh, id ~ measurementType, value.var = "measurementValue")
setnames(mw, c("id", "Recorded minutes", "sum of Detection Positive Minutes", "Total number of clicks", "Number of filtered clicks"),
         c("eventID", "rec", "dpm", "total", "filtered"))
mw[, c("rec", "dpm", "total", "filtered") := lapply(.SD, as.integer), .SDcols = c("rec", "dpm", "total", "filtered")]
stopifnot(nrow(mw) == nrow(hr), !anyNA(mw), all(mw$rec >= 1L & mw$rec <= 60L), all(mw$dpm >= 0L & mw$dpm <= mw$rec),
          all(mw$total >= 0L), all(mw$filtered >= 0L))
x <- merge(merge(hr[, .(eventID, dep = parentEventID, start)], mw, by = "eventID"), oc[, .(eventID, status = occurrenceStatus)], by = "eventID")
stopifnot(nrow(x) == 449119L, all((x$dpm > 0L) == (x$status == "present")))
x <- merge(x, dep[, .(dep = eventID, device = fifelse(parentEventID == "01_CPOD", "C-POD", "F-POD"), station = locality,
                       lat = as.numeric(decimalLatitude), lon = as.numeric(decimalLongitude),
                       depth = round(as.numeric(minimumDepthInMeters), 1), mooring = eventRemarks)], by = "dep")
stopifnot(nrow(x) == 449119L, !anyNA(x$lat), !anyNA(x$lon), x[, sum(duplicated(paste(station, start)))] == 15568L)

x[, `:=`(yr = as.integer(substr(start, 1, 4)), mo = as.integer(substr(start, 6, 7)),
         dy = as.integer(substr(start, 9, 10)), hh = as.integer(substr(start, 12, 13)))]
m0 <- x[, min(yr * 12L + mo - 1L)]
x[, period := yr * 12L + mo - 1L - m0 + 1L]
x[, occasion := (dy - 1L) * 24L + hh + 1L]
stopifnot(!anyDuplicated(x[, .(dep, period, occasion)]), all(x$occasion >= 1L & x$occasion <= 744L))

long <- x[, .(unit = paste0("D", dep), taxon = "PHOPHO", y = as.integer(dpm > 0L), y_raw = dpm, period, occasion,
              date = substr(start, 1, 10), cluster_id = station,
              unit_device = device, unit_mooring = mooring, unit_depth_m = depth,
              unit_decimalLatitude = lat, unit_decimalLongitude = lon,
              obs_hour_utc = hh, obs_recorded_min = rec, obs_total_clicks = total)]
setorder(long, unit, period, occasion)
stopifnot(nrow(long) == 449119L, uniqueN(long$unit) == 172L, uniqueN(long$cluster_id) == 24L, sum(long$y) == 159076L,
          long[, uniqueN(paste(unit_device, unit_mooring, unit_depth_m, unit_decimalLatitude, unit_decimalLongitude)), by = unit][, all(V1 == 1L)],
          long[, uniqueN(cluster_id), by = unit][, all(V1 == 1L)])

taxa <- make_taxa("PHOPHO", "Phocoena phocoena", vernacularName = "Harbour porpoise")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
mons <- unique(x[, .(period, yr, mo)])
periods <- CJ(period = seq_len(max(x$period)))
periods[, `:=`(year = (m0 + period - 1L) %/% 12L, month = (m0 + period - 1L) %% 12L + 1L)]
periods <- periods[period %in% x$period]
stopifnot(nrow(periods) == uniqueN(x$period), all(merge(mons, periods, by = "period")[, yr == year & mo == month]))

ny <- sprintf("%d-%d", min(x$yr), max(x$yr))
dataset <- list(
  title = sprintf("Harbour porpoise detections per hour on %d C-POD and F-POD deployments at %d stations, Belgian part of the North Sea, %s",
                  uniqueN(long$unit), uniqueN(long$cluster_id), ny),
  creator = "Debusschere, Elisabeth; Calonge, Arienne; Conings, Bram (Flanders Marine Institute, VLIZ)",
  pubDate = "2026", doi = "10.14284/639", sourceURL = "https://doi.org/10.14284/639",
  citation = "Debusschere E, Calonge A, Conings B (2026). LifeWatch observatory data: Permanent Cetacean passive acoustic sensor network in the Belgian Part of the North Sea. Version 1.10. Flanders Marine Institute (VLIZ). Samplingevent dataset. https://doi.org/10.14284/639",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("Passive acoustic monitoring of harbour porpoise (Phocoena phocoena) in the LifeWatch cetacean network of VLIZ: C-POD and F-POD click loggers moored next to shipwrecks and other structures at %d stations in the Belgian part of the North Sea, %s. Porpoise click trains are classified by the KERNO classifier and summarised per hour as detection-positive minutes out of minutes recorded. One row per deployment-hour with recording time: y = 1 if any minute in the hour had a porpoise detection, y_raw = detection-positive minutes, obs_recorded_min = minutes recorded, obs_total_clicks = all clicks logged. The unit is the deployment (%d), and cluster_id is the station, so simultaneous deployments at a station (paired C-POD and F-POD, or overlap during a swap) are separate units.",
                     uniqueN(long$cluster_id), ny, uniqueN(long$unit)),
  samplingProtocol = "Continuous recording by moored C-POD or F-POD click loggers; clicks classified as narrow-band high-frequency porpoise click trains by the KERNO classifier (cpod.exe), summarised per hour as detection-positive minutes and minutes recorded.",
  samplingProtocolCode = "acoustic", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "period = calendar month, occasion = hour of the month (UTC); porpoise presence at a station changes within hours, so occupancy within a month is use, not a closed state. date and obs_hour_utc allow any regrouping (day, week, season).",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_recorded_min",
  geographicCoverage = "Belgian part of the North Sea (51.2-51.8 N, 2.4-3.1 E)",
  temporalCoverage = sprintf("%d-%02d/%d-%02d", min(x$yr), x[yr == min(yr), min(mo)], max(x$yr), x[yr == max(yr), max(mo)]),
  coordinatesCoarsened = list(value = FALSE, method = "Phocoena phocoena is Least Concern (IUCN); offshore mooring positions kept as published (4 decimals)."),
  notes = "Detections are the KERNO classifier's output as published (automated, not validated by hand). Recording time is under 60 minutes in some hours (deployment start and end, battery or memory end); use obs_recorded_min as effort. One F-POD deployment at ReefballsBelwind (D57130) is published 0.1 deg east of the station's other deployments. Licence: CC BY 4.0, confirmed by VLIZ (E. Debusschere, 2026-11-10) after earlier versions carried a not-for-profit accessRights note.",
  notShipped = list(`Number of filtered clicks` = "clicks in classified porpoise trains per hour: a second measure of the same detection, not a covariate",
                    `device-type events` = "01_CPOD / 02_FPOD parent events; their instrument is unit_device"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Hourly harbour porpoise detections (detection-positive minutes) from %d C-POD / F-POD deployments at %d stations of the VLIZ LifeWatch passive acoustic network, Belgian part of the North Sea, %s.",
                        uniqueN(long$unit), uniqueN(long$cluster_id), ny),
  url = "https://doi.org/10.14284/639",
  reference = "Debusschere E, Calonge A, Conings B (2026). LifeWatch observatory data: Permanent Cetacean passive acoustic sensor network in the Belgian Part of the North Sea. Version 1.10. VLIZ.",
  doi_paper = "", doi_data = "10.14284/639", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "VLIZ IPT DwC-A (lifewatch_cpod v1.10); licence confirmed by VLIZ 2026-11-10. Also in EurOBIS (IMIS 5531) and on EDITO.",
  source_via = "VLIZ IPT")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (continuous hourly detections)",
  sampling_protocol = "acoustic", design = sprintf("Multi-season (%d months x up to 744 hourly occasions; %d deployments at %d stations)", uniqueN(long$period), uniqueN(long$unit), uniqueN(long$cluster_id)),
  realm = "Marine", country = "BEL", coordinates = "As published",
  notes = "Moored porpoise click loggers; hourly detection-positive minutes with minutes recorded as effort.")
