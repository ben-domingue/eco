#!/usr/bin/env Rscript
# Table:  henry_2020_karoo_birds_comm
# Source: Dryad doi:10.5061/dryad.msbcc2fv7 (CC0 1.0), version 53974 (2020-02-18).
#         Henry, D.A.W., Lee, A.T.K. & Altwegg, R. (2020). Data from: Can time-to-detection
#         models with fewer survey replicates provide a robust alternative to traditional
#         site-occupancy models? Dryad.
# Paper:  Henry, D.A.W., Lee, A.T.K. & Altwegg, R. (2020). Can time-to-detection models with
#         fewer survey replicates provide a robust alternative to traditional site-occupancy
#         models? Methods in Ecology and Evolution 11(5), 643-655, doi:10.1111/2041-210X.13379
#         (publisher-only; abstract used; 63 species, Karoo, South Africa).
# Data:   TTD_karoo_bird_data.xlsx, sheet "TTD karoo bird data": one row per FIRST detection
#         of a species on a point count (4,015 rows; no species repeats within a count):
#         survey_id (pentad code + count sequence number), temperature, cloud (%), wind (m/s),
#         rain (1-4 days-since-rain category), pentad (SABAP 5 x 5 arc-minute cell, code =
#         its north-west corner, e.g. 3255_2535 = 32 deg 55' S, 25 deg 35' E), survey_start
#         and datetime (ISO, UTC), species (common name), ttd (seconds from the count start to
#         the detection; the Metadata sheet says "minutes" but ttd equals datetime -
#         survey_start in seconds everywhere, floored at 10 s for the 915 detections made within
#         10 s of the start, asserted), longitude / latitude (GPS at the
#         detection), mins_after_dawn, seenheard, perchedflying, distance (m, rangefinder),
#         latin_name (IOC with bracketed synonyms), date, time. Sheet "Metadata": column
#         definitions. 61 pentads, 1,055 point counts (10-20 per pentad, mostly 20 on one or
#         two days), Feb-Oct 2017, 63 species. No zero-detection counts and no count list.
#
# Mapping (standard E9 community occupancy from a record table; design_landscape.md B/C
# for the time-to-detection component):
#   unit = pentad (61), occasion = point count in chronological order within the pentad
#   (1-20), taxon = six-letter code from the IOC name (vernacular and source spelling in
#   __taxa), y = 1 if the species has a first-detection row on that count else 0, one
#   season (2017). Survey evidence: row_presence -- a point count exists iff at least one
#   species was recorded on it; counts with no detections, if any, cannot be recovered
#   (stated in surveyEvidenceNote). Survey covariates (obs_, constant within a count):
#   date = survey_start (ISO, UTC), obs_temperature_c, obs_cloud_pct, obs_wind_ms,
#   obs_rain_class, obs_mins_after_dawn_start (mins_after_dawn - elapsed/60, constant within a
#   count to the second, asserted), obs_decimalLatitude / obs_decimalLongitude (median GPS of
#   the count's detections; the counts are the sampling locations). Unit covariates:
#   unit_decimalLatitude / unit_decimalLongitude = pentad centroid (code corner + 2.5').
#   Species-row covariates (obs_ varying across taxa within a count, E5): obs_ttd_s = time
#   to first detection in seconds (NA = not detected on that count, right-censored at the
#   count's end), obs_distance_m, obs_detection_mode (seenheard), obs_behaviour
#   (perchedflying). The time-to-detection response is NOT y (design_landscape.md C,
#   continuous censored y); it rides as obs_ttd_s so the TTD model can be refit, pending a
#   family ruling. Count duration is not deposited: observed first detections run to 658 s,
#   so counts were about 10 minutes (surveyDuration in metadata states this as observed).
#   Coordinates as published: no taxon is IUCN CR/EN/VU (Karoo Korhaan NT), pentad centroids
#   are coarser than 0.1 degree anyway.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "henry_2020_karoo_birds_comm"
dir <- download_dryad("10.5061/dryad.msbcc2fv7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, pattern = "TTD_karoo_bird_data\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1, setequal(excel_sheets(f), c("TTD karoo bird data", "Metadata")))
raw <- as.data.table(read_excel(f, sheet = "TTD karoo bird data"))
stopifnot(nrow(raw) == 4015, ncol(raw) == 19, uniqueN(raw$pentad) == 61, uniqueN(raw$survey_id) == 1055,
          uniqueN(raw$species) == 63, uniqueN(raw$latin_name) == 63, !anyNA(raw[, .(survey_id, pentad, species, latin_name, ttd, survey_start, datetime)]),
          !anyDuplicated(raw[, .(survey_id, species)]))                        # one row = first detection of a species on a count
raw[, start := as.POSIXct(survey_start, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")]
raw[, det := as.POSIXct(datetime, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")]
raw[, elapsed := as.numeric(difftime(det, start, units = "secs"))]
stopifnot(!anyNA(raw$start), !anyNA(raw$det), all(raw$ttd == pmax(raw$elapsed, 10)), sum(raw$elapsed < 10) == 915)   # ttd is seconds, floored at 10 s by the authors
stopifnot(all(raw$ttd >= 10), max(raw$ttd) == 658, all(raw$rain %in% 1:4), all(raw$cloud >= 0 & raw$cloud <= 100),
          all(year(raw$start) == 2017), all(substr(raw$survey_id, 1, 9) == raw$pentad), grepl("^\\d{4}_\\d{4}$", raw$pentad[1]))
stopifnot(all(raw$seenheard %in% c("Heard only", "Heard Seen", "Seen Heard", "Seen only")),
          all(raw$perchedflying %in% c("Perched", "Flying", "Perched Flying", "Flying Perched")))

# surveys: one row per point count; covariates constant within a count
raw[, dawn_start := mins_after_dawn - elapsed / 60]                 # the true elapsed time, not the 10 s-floored ttd
stopifnot(raw[, max(dawn_start) - min(dawn_start), by = survey_id][, max(V1)] < 0.001)   # constant within a count (float noise only)
raw[, dawn_start := round(median(dawn_start), 1), by = survey_id]
sv <- unique(raw[, .(survey_id, pentad, start, temperature, cloud, wind, rain, dawn_start)])
stopifnot(nrow(sv) == 1055, !anyDuplicated(sv$survey_id))                        # every covariate constant within a count
gps <- raw[, .(lat = median(latitude), lon = median(longitude), lat_sd = sd(latitude), lon_sd = sd(longitude)), by = survey_id]
stopifnot(max(gps$lat_sd, na.rm = TRUE) < 0.01, max(gps$lon_sd, na.rm = TRUE) < 0.01)   # one location per count (GPS jitter < 1 km)
sv <- merge(sv, gps[, .(survey_id, lat, lon)], by = "survey_id")
setorder(sv, pentad, start)
sv[, occasion := seq_len(.N), by = pentad]
stopifnot(all(sv[, .N, by = pentad]$N %in% 10:20))
# pentad centroid: code is the NW corner (lat S, lon E) of a 5' x 5' cell; GPS fixes sit 0 to 0.083 deg south/east of it
sv[, c("plat", "plon") := .(-(as.integer(substr(pentad, 1, 2)) + as.integer(substr(pentad, 3, 4)) / 60 + 2.5 / 60),
                            as.integer(substr(pentad, 6, 7)) + as.integer(substr(pentad, 8, 9)) / 60 + 2.5 / 60)]
stopifnot(all(abs(sv$lat - sv$plat) < 0.05), all(abs(sv$lon - sv$plon) < 0.05))
cat(sprintf("  %d pentads, %d point counts (%d-%d per pentad), %s to %s\n", uniqueN(sv$pentad), nrow(sv), min(sv[, .N, by = pentad]$N),
            max(sv[, .N, by = pentad]$N), min(as.Date(sv$start)), max(as.Date(sv$start))))

# taxa: six-letter code from the IOC name with bracketed/parenthesised synonyms removed
species <- unique(raw[, .(species, latin_name)])
species[, scientificName := trimws(gsub("\\s+", " ", gsub("\\[[^]]*\\]|\\([^)]*\\)", "", latin_name)))]
stopifnot(all(lengths(strsplit(species$scientificName, " ")) == 2), !anyDuplicated(species$scientificName))
species[, taxon := toupper(paste0(substr(sub(" .*", "", scientificName), 1, 3), substr(sub(".* ", "", scientificName), 1, 3)))]
species[scientificName == "Corvus albicollis", taxon := "CORALC"]      # CORALB collides with Corvus albus (Pied Crow)
stopifnot(!anyDuplicated(species$taxon), nrow(species) == 63)
raw <- merge(raw, species[, .(species, taxon)], by = "species")

# community table: every species at every count
long <- sv[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(sv))]
det <- raw[, .(survey_id, taxon, ttd, distance, seenheard, perchedflying)]
long <- merge(long, det, by = c("survey_id", "taxon"), all.x = TRUE)
long[, y := as.integer(!is.na(ttd))]
stopifnot(sum(long$y) == 4015, nrow(long) == 1055 * 63)
long <- long[, .(unit = pentad, taxon, y, occasion, date = format(start, "%Y-%m-%dT%H:%M:%SZ"),
                 unit_decimalLatitude = round(plat, 5), unit_decimalLongitude = round(plon, 5),
                 obs_decimalLatitude = round(lat, 6), obs_decimalLongitude = round(lon, 6),
                 obs_temperature_c = temperature, obs_cloud_pct = cloud, obs_wind_ms = wind, obs_rain_class = rain,
                 obs_mins_after_dawn_start = dawn_start, obs_ttd_s = ttd, obs_distance_m = distance,
                 obs_detection_mode = seenheard, obs_behaviour = perchedflying)]
long <- order_eco(long)
stopifnot(uniqueN(long$unit) == 61, uniqueN(long$taxon) == 63, max(long$occasion) == 20)

lookup <- species$scientificName
lookup[lookup == "Parisoma subcaeruleum"] <- "Sylvia subcoerulea"      # GBIF spelling of the Chestnut-vented Tit-Babbler
taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$species, lookupName = lookup,
                  taxon_sourceName = species$latin_name)
stopifnot(!anyNA(taxa$taxonID))
taxa[taxon == "EUPVIG", taxon_iucnCategory := "NT"]      # Karoo Korhaan; no CR/EN/VU species in the table
dataset <- list(
  title = "Karoo bird point counts with time to first detection, 61 SABAP pentads x 10-20 counts, South Africa, 2017 (Henry et al. 2020)",
  creator = "Henry, Dominic A. W.; Lee, Alan T. K.; Altwegg, Res", pubDate = "2020", doi = "10.5061/dryad.msbcc2fv7",
  sourceURL = "https://doi.org/10.5061/dryad.msbcc2fv7",
  citation = "Henry, D. A. W., Lee, A. T. K., & Altwegg, R. (2020). Data from: Can time-to-detection models with fewer survey replicates provide a robust alternative to traditional site-occupancy models? Dryad. https://doi.org/10.5061/dryad.msbcc2fv7",
  paperCitation = "Henry, D. A. W., Lee, A. T. K., & Altwegg, R. (2020). Can time-to-detection models with fewer survey replicates provide a robust alternative to traditional site-occupancy models? Methods in Ecology and Evolution, 11(5), 643-655. https://doi.org/10.1111/2041-210X.13379",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://spdx.org/licenses/CC0-1.0.html"),
  abstract = "Bird point counts in the Karoo, South Africa, February to October 2017, recorded with CyberTracker so that the time from the start of the count to the first detection of each species is known. 61 SABAP pentads (5 x 5 arc-minute cells) each received 10 to 20 point counts, usually 20 on one or two days; 63 species were recorded. The deposit is one row per first detection of a species on a count (4,015 rows). The table is the detection/non-detection view the paper compares against: unit = pentad, occasion = point count in time order, y = detected on that count, with the time to first detection carried as obs_ttd_s on the species rows (NA = not detected within the count) so the paper's time-to-detection models can be refit; count-level weather, minutes after dawn and the count's GPS location ride as obs_ covariates; the pentad centroid is the unit coordinate.",
  samplingProtocol = "Point counts of about 10 minutes (observed first detections up to 658 s) at 10-20 points per 5 x 5 arc-minute pentad, all species detected by sight or sound recorded with the time of first detection, distance (rangefinder), detection mode and behaviour; temperature, cloud, wind and days since rain per count.",
  samplingProtocolCode = "point_count", responseType = "detection", unitKind = "site",
  closure = "occasion: the 10-20 point counts within a pentad are the replicates of one 2017 season (the paper's DND design); period absent",
  surveyEvidence = "row_presence",
  surveyEvidenceNote = "The deposit is a record table of first detections with no list of point counts: a count exists iff at least one species was recorded on it. Counts with zero detections, if any occurred, cannot be recovered. Every count carries a full set of weather covariates, so the 1,055 counts are the surveyed set as far as the deposit shows.",
  surveyDuration = "not deposited; first detections run to 658 s, so counts were about 10 minutes; obs_ttd_s is right-censored at the count's end",
  temporalCoverage = "2017-02-21/2017-10-25",
  geographicCoverage = "Karoo, Western and Eastern Cape, South Africa; 61 SABAP pentads between 30.8 and 33.1 S, 19.8 and 26.0 E",
  crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "as published: unit coordinates are pentad centroids (5 x 5 arc-minute cells, coarser than 0.1 degree); count locations as obs_ covariates at GPS precision; no taxon is IUCN CR/EN/VU (Karoo Korhaan NT)"),
  designNote = "Community detection/non-detection with spatial replication within the pentad (the authors' DND models). The time-to-detection response (design_landscape.md C: continuous, right-censored) is not y; it rides as obs_ttd_s on species rows pending a family ruling. obs_distance_m, obs_detection_mode and obs_behaviour are first-detection attributes.",
  notes = "ttd is in seconds (the Metadata sheet says minutes; ttd equals datetime minus survey_start in seconds on every row, floored at 10 s by the authors for the 915 detections within 10 s of the start). obs_mins_after_dawn_start = the deposited minutes-after-dawn of the detection minus the elapsed seconds/60, constant within a count to 0.1 min. Occasion is the chronological rank of the count within its pentad; the deposit's sequence numbers run beyond 20 for pentads surveyed on several days and are not used. Species codes are six letters from the IOC name with bracketed synonyms removed (White-necked Raven is CORALC because CORALB is Pied Crow); the deposit's spelling is in __taxa.taxon_sourceName.",
  notShipped = list(mins_after_dawn = "per-detection value; the count-start value is obs_mins_after_dawn_start and the detection value is recoverable as start + obs_ttd_s/60",
                    time = "the detection clock time, redundant with date + obs_ttd_s"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/henry_2020_karoo_birds_comm.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of 63 bird species on 1,055 point counts in 61 Karoo pentads, South Africa, 2017, with the time to first detection, distance and detection mode of each species on each count as observation covariates; count weather and location.",
  url = "https://doi.org/10.5061/dryad.msbcc2fv7",
  reference = "Henry, D. A. W., Lee, A. T. K., & Altwegg, R. (2020). Can time-to-detection models with fewer survey replicates provide a robust alternative to traditional site-occupancy models? Methods in Ecology and Evolution, 11(5), 643-655.",
  doi_paper = "10.1111/2041-210X.13379", doi_data = "10.5061/dryad.msbcc2fv7",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Record table of first detections; survey set = counts with at least one detection (row_presence). Time to detection carried as obs_ttd_s, not y (design_landscape C).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (single season); time-to-detection occupancy refittable from obs_ttd_s",
  sampling_protocol = "point_count", design = "Single-season (10-20 point counts per pentad)", realm = "Terrestrial", country = "ZAF",
  coordinates = "As published (pentad centroids as unit coordinates; count GPS as obs_)",
  notes = "63 species; TTD in seconds on species rows; no zero-detection counts recoverable.", status = "tagged")
