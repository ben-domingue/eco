#!/usr/bin/env Rscript
# Table:  clipp_2024_wvprivate_comm
# Source: Zenodo doi:10.5281/zenodo.10391650 (CC BY 4.0 on Zenodo, published 2023-12-15), one
#         file Zenodo-Files.zip. Rota, C. T. (2023). Data for White-tailed Deer Detection
#         Intensity Increases When Coyotes Are Present. Zenodo. The rows of Data/sequences.csv
#         (a Wildlife Insights export) carry licence = CC-BY-NC on every row; the stricter
#         licence governs (intake policy), so derived_license = CC BY-NC 4.0.
# Paper:  Clipp, H. L., Pesi, S. M., Miller, M. L., Gigliotti, L. C., Skelly, B. P. & Rota, C. T.
#         (2024). White-tailed deer detection rates increase when coyotes are present. Ecology
#         and Evolution 14(3), e11149, doi:10.1002/ece3.11149 (CC BY 4.0).
# Data:   The zip holds three camera-trap datasets the paper combined (see
#         clipp_2024_monongahela_comm.R for the full inventory). This table is the 2022
#         private-land dataset:
#         Data/2022_Cameras.xlsx: three sheets of deployments on private land in West Virginia,
#         named by county pair (Jackson-Mason 49, Barbour-Upshur 56, Hampshire 41 = 146
#         deployments; two header rows, then Deployment Name, deployment date and time,
#         retrieval date and time, team, UTM easting/northing, latitude, longitude, camera id,
#         card id, battery, detection distance (m), camera working at retrieval (Y/N), comments,
#         cataloguing dates) and a Metadata sheet defining the columns. The paper's code reads
#         rows 3-43 / 3-58 / 3-43 (41 + 56 + 41 = 138 cameras, as the paper reports); the eight
#         further Jackson-Mason rows (Fleming-1..4, Hoffman-1,2,3,6, deployed 2022-06-29) have no
#         NDVI in sites.RDS and were not modelled, but they are documented deployments with
#         sequences, so they are shipped here.
#         Data/sequences.csv: 11,553 Wildlife Insights sequences (project 2004262, identified by
#         Sarah Pesi, is_blank = 0 throughout) with deployment_id, taxonomy (class to species),
#         common_name, start_time / end_time to the second, group_size, age, sex, licence.
#         144 of the 146 deployments have sequences (Haynes-11 and Shanholtz-6 have none).
#         Checked: deployment ids match the xlsx exactly. 199 sequences are timestamped in 2017
#         (149) or 2021 (50) at four cameras whose comments say the clock was wrong; a further
#         66 fall outside the window at the deployment or retrieval boundary, 61 of them by
#         under an hour (timestamps to the second, window to the minute) and 5 by 2-12 h. Both are
#         dropped after the window is widened to whole minutes (the paper's code also keeps
#         only detections inside the window).
#
# Mapping (standard section 3.6, community detection from a sequence table with a deployment
# table):
#   unit = pseudonymised deployment id <county-pair>_<sheet row> (146; the deposited
#   Deployment Names are property-owner surnames plus a camera number and are not shipped,
#   Ben's ruling 2026-11-01; the sheet row keeps the join to the deposit), cluster_id = county-pair sheet, taxon = species code for
#   every sequence identified to species in Mammalia or Aves except Homo sapiens (humans,
#   vehicles, insects and higher-rank labels such as "Sciurus Species" are dropped);
#   occasion = camera-day index within the deployment (1 = deployment date), date = that
#   calendar date, y = 1 if the taxon has at least one sequence in that camera-day, y_raw =
#   number of sequences. Survey evidence: the deployment table; a camera-day exists iff the
#   deployment window covers part of the date and obs_camera_hours is the covered part.
#   unit_decimalLatitude / unit_decimalLongitude as published (no flagged taxon: none of the
#   taxa is IUCN CR/EN/VU), unit_detection_distance_m, unit_camera_working_at_retrieval
#   (0/1; 14 cameras were not working when retrieved, so their later camera-days may
#   overstate effort; the deposit does not say when they failed). Not shipped: group_size,
#   age, sex (per sequence), the out-of-window sequences, NDVI (author-derived), the Stan
#   inputs and fitted models, and the other two datasets (see the sibling script).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "clipp_2024_wvprivate_comm"
zip <- download_cached("https://zenodo.org/api/records/10391650/files/Zenodo-Files.zip/content", TABLE, filename = "Zenodo-Files.zip")
dir <- file.path(dirname(zip), "Zenodo-Files")
if (!dir.exists(dir)) unzip(zip, exdir = dirname(zip))
meta_f <- file.path(dirname(zip), "zenodo_record.json")
if (!file.exists(meta_f)) download.file("https://zenodo.org/api/records/10391650", meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
stopifnot(identical(fromJSON(meta_f)$metadata$license$id, "cc-by-4.0"))

xl <- file.path(dir, "Data", "2022_Cameras.xlsx")
sheets <- excel_sheets(xl); stopifnot(identical(sheets, c("Jackson-Mason", "Barbour-Upshur", "Hampshire", "Metadata")))
hdr <- as.data.frame(read_xlsx(xl, 1, skip = 1, n_max = 1, col_names = FALSE, .name_repair = "minimal"))
stopifnot(identical(unname(unlist(hdr[1, 1:16])), c("Deployment Name", "Date", "Time", "Date", "Time", "Team", "Easting", "Northing", "Latitude", "Longitude",
                                                     "Camera ID", "Memory Card ID", "Battery %", "Dection Distance (m)", "Camera Working at Retrieval", "Comments")))
dep <- rbindlist(lapply(1:3, function(i) {
  x <- as.data.frame(read_xlsx(xl, i, skip = 2, col_names = FALSE, .name_repair = "minimal"))
  data.table(cluster = sheets[i], row = seq_len(nrow(x)) + 2L, unit = x[[1]], d1 = as.Date(x[[2]]), t1 = format(x[[3]], "%H:%M"), d2 = as.Date(x[[4]]), t2 = format(x[[5]], "%H:%M"),
             lat = as.numeric(x[[9]]), lon = as.numeric(x[[10]]), dist_m = as.numeric(x[[14]]), working = x[[15]], comments = x[[16]])
}))
stopifnot(nrow(dep) == 146, dep[, .N, by = cluster][, identical(N, c(49L, 56L, 41L))], !anyDuplicated(dep$unit),
          !anyNA(dep$d1), !anyNA(dep$t1), !anyNA(dep$d2), !anyNA(dep$t2), !anyNA(dep$lat), !anyNA(dep$lon),
          all(dep$working %in% c("Y", "N")), sum(dep$working == "N") == 14,
          all(dep$lat > 38.5 & dep$lat < 39.6), all(dep$lon > -82 & dep$lon < -78.4))
dep[, dep := as.POSIXct(paste(d1, t1), tz = "UTC")][, ret := as.POSIXct(paste(d2, t2), tz = "UTC") + 59]   # window inclusive of the retrieval minute
dur <- as.numeric(difftime(dep$ret, dep$dep, units = "days"))
stopifnot(all(dur > 1), max(dur) < 77, all(format(dep$dep, "%Y") == "2022"))     # paper: 2-76 days

seq <- fread(file.path(dir, "Data", "sequences.csv"))
stopifnot(nrow(seq) == 11553, all(seq$license == "CC-BY-NC"), all(seq$is_blank == 0), all(seq$project_id == 2004262),
          uniqueN(seq$deployment_id) == 144, all(seq$deployment_id %in% dep$unit),
          setequal(setdiff(dep$unit, seq$deployment_id), c("Haynes-11 05/05/2022", "Shanholtz-6 07/06/2022")))
seq[, t := as.POSIXct(start_time, tz = "UTC")]; stopifnot(!anyNA(seq$t))
seq <- merge(seq, dep[, .(unit, dep, ret)], by.x = "deployment_id", by.y = "unit")
out <- seq[t < dep | t > ret]
stopifnot(sum(year(out$t) != 2022) == 199, nrow(out) == 265,
          setequal(unique(out[year(t) != 2022, deployment_id]), c("Fleming-2 06/29/2022", "Fleming-3 06/29/2022", "Haile-3 04/23/2022", "Hoffman-4 06/28/2022")))
cat(sprintf("  dropped %d sequences outside their deployment window (%d with a wrong camera year)\n", nrow(out), sum(year(out$t) != 2022)))
seq <- seq[t >= dep & t <= ret]

# taxa: species-level identifications in Mammalia and Aves, humans excluded
stopifnot(all(seq$class %in% c("", "Aves", "Insecta", "Mammalia")))
sp <- seq[species != "" & class %in% c("Mammalia", "Aves") & genus != "Homo"]
dropped <- seq[!(species != "" & class %in% c("Mammalia", "Aves") & genus != "Homo"), .N, by = common_name][order(-N)]
cat(sprintf("  dropped %d sequences not identified to a wild or domestic bird/mammal species (%d labels, e.g. %s)\n", sum(dropped$N), nrow(dropped), paste(head(dropped$common_name, 6), collapse = ", ")))
species <- unique(sp[, .(class, genus, species, common_name)])
species[, scientificName := paste(genus, species)]
stopifnot(!anyDuplicated(species$scientificName), !anyDuplicated(species$common_name))
species[, taxon := toupper(paste0(substr(genus, 1, 3), substr(species, 1, 3)))]
stopifnot(!anyDuplicated(species$taxon))
cat(sprintf("  %d taxa (%d mammals, %d birds)\n", nrow(species), sum(species$class == "Mammalia"), sum(species$class == "Aves")))
stopifnot(c("Odocoileus virginianus", "Canis latrans") %in% species$scientificName)
sp <- merge(sp, species[, .(genus, species, taxon)], by = c("genus", "species"), all.x = TRUE)
stopifnot(!anyNA(sp$taxon))

# pseudonymise the deployment names (property-owner surnames) before anything is shipped:
# unit = <county-pair letters>_<sheet row number>, unique, in deposit order; the name itself
# stays in the cached deposit only
dep[, unit_src := unit][, unit := sprintf("%s_%02d", gsub("[^A-Za-z]", "", cluster), row)]
stopifnot(!anyDuplicated(dep$unit), !any(grepl("[A-Z][a-z]+-[0-9]", dep$unit)))
pseudo <- setNames(dep$unit, dep$unit_src)    # sp has a column named dep, so look up outside the data.table scope
sp[, deployment_id := pseudo[deployment_id]]
stopifnot(!anyNA(sp$deployment_id))

# survey set: camera-days from the deployment table
days <- dep[, .(date = seq(as.IDate(dep), as.IDate(ret), by = "day")), by = .(unit, dep, ret)]
days[, d0 := as.POSIXct(paste(date, "00:00:00"), tz = "UTC")]
days[, camera_hours := round(as.numeric(difftime(pmin(ret, d0 + 86400), pmax(dep, d0), units = "hours")), 2)]
stopifnot(all(days$camera_hours > 0), all(days$camera_hours <= 24), abs(sum(days$camera_hours) / 24 - sum(dur)) < 0.01)
days[, occasion := seq_len(.N), by = unit]
cat(sprintf("  %d deployments, %d camera-days (%.0f camera-days of effort)\n", nrow(dep), nrow(days), sum(dur)))

sp[, date := as.IDate(t)]
counts <- sp[, .(sequences = .N), by = .(unit = deployment_id, date, taxon)]
stopifnot(nrow(counts[!days, on = .(unit, date)]) == 0)
long <- days[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(days))]
long <- merge(long, counts, by = c("unit", "date", "taxon"), all.x = TRUE)
long[is.na(sequences), sequences := 0L]
long <- merge(long, dep[, .(unit, cluster, lat, lon, dist_m, working)], by = "unit")
long <- long[, .(unit, taxon, y = as.integer(sequences > 0), y_raw = sequences, occasion, date = format(date), cluster_id = cluster,
                 unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_detection_distance_m = dist_m,
                 unit_camera_working_at_retrieval = as.integer(working == "Y"), obs_camera_hours = camera_hours)]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(days) * nrow(species), sum(long$y_raw) == nrow(sp), uniqueN(long$unit) == 146)

taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$common_name, taxon_class = species$class)
units <- dep[, .(unit, cluster_id = cluster, decimalLatitude = lat, decimalLongitude = lon, detection_distance_m = dist_m,
                 camera_working_at_retrieval = as.integer(working == "Y"), deployed = format(dep, "%Y-%m-%dT%H:%MZ"),
                 retrieved = format(ret - 59, "%Y-%m-%dT%H:%MZ"), camera_days = round(dur, 2), modelled_in_paper = as.integer(!(cluster == "Jackson-Mason" & row > 43)))]   # the paper's code reads rows 3-43 / 3-58 / 3-43
stopifnot(sum(units$modelled_in_paper == 0) == 8, all(grepl("^(Fleming-[1-4]|Hoffman-[1236]) ", dep[units[modelled_in_paper == 0], on = "unit", unit_src])))

dataset <- list(
  title = sprintf("Daily camera-trap detections of %d bird and mammal taxa at 146 cameras on private land in three West Virginia county pairs, April-September 2022", nrow(species)),
  creator = "Rota, Christopher T.; Pesi, Sarah M.", pubDate = "2023", doi = "10.5281/zenodo.10391650", sourceURL = "https://doi.org/10.5281/zenodo.10391650",
  citation = "Rota, C. T. (2023). Data for White-tailed Deer Detection Intensity Increases When Coyotes Are Present [Data set]. Zenodo. https://doi.org/10.5061/zenodo.10391650",
  paperDOI = "10.1002/ece3.11149",
  intellectualRights = list(spdx = "CC-BY-NC-4.0", url = "https://creativecommons.org/licenses/by-nc/4.0/",
                            note = "Zenodo record CC BY 4.0; every row of sequences.csv (Wildlife Insights export) carries licence CC-BY-NC, which governs"),
  abstract = sprintf("Game cameras deployed for about two months in summer 2022 at 146 sites on private land in Jackson-Mason, Barbour-Upshur and Hampshire counties, West Virginia, one of three camera datasets Clipp et al. (2024) combined to fit a two-species occupancy model with a continuous-time detection process for white-tailed deer and coyote. The Wildlife Insights sequence export lists every identified sequence, so this table carries all %d taxa identified to species (wild and domestic mammals and birds) as daily detection/non-detection with the number of sequences, with camera coordinates as published.", nrow(species)),
  samplingProtocol = "Game cameras on private land, deployed 1.7-76 days (median 62) between 2022-04-23 and 2022-09-15; images grouped into sequences (photos within one minute of each other) and identified in Wildlife Insights. Occasion = calendar day of the deployment; effort = hours the camera operated within that day, from the deployment and retrieval timestamps.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day", effortColumn = "obs_camera_hours",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "occasion (camera-days within one deployment of up to 76 days, the paper's closure assumption); no period",
  geographicCoverage = "Private land in Jackson, Mason, Barbour, Upshur and Hampshire counties, West Virginia, USA (camera coordinates as published)", temporalCoverage = "2022-04-23/2022-09-15",
  coordinatesCoarsened = list(value = FALSE, method = "none: no taxon is flagged (no IUCN CR/EN/VU species; white-tailed deer and coyote are Least Concern); coordinates as deposited"),
  notShipped = list(out_of_window = "265 sequences timestamped outside their deployment window: 199 with a wrong camera year (2017, 2021) at four cameras whose comments report clock faults, 66 at the deployment or retrieval boundary (61 by under an hour, 5 by 2-12 hours)",
                    `higher-rank, human, vehicle, insect labels` = "sequences not identified to a bird or mammal species (Unknown, Animal, Mammal, Rodent, Sciurus Species, Human-*, Vehicle, Insect, ...)",
                    `group_size, age, sex` = "per-sequence attributes that do not survive aggregation to camera-days",
                    `sites.RDS ndvi` = "per-camera NDVI the authors computed from 30 m rasters; not among the deposited raw files",
                    `wtd.RDS, coy.RDS, stan_data.RDS, Fitted-Models/` = "derived from the detections; model inputs and outputs",
                    `Data/SNAPSHOT_USA_2020_*.csv` = "the full Snapshot USA 2020 release re-uploaded by the authors (third-party data, not hosted from this deposit)",
                    `Data/Wildlife_Openings_*.csv` = "the 2019-2021 Monongahela cameras, shipped as clipp_2024_monongahela_comm"),
  notes = "Eight Jackson-Mason deployments (sheet rows 46-53, units JacksonMason_46..53) are in the deployment sheet and the sequence export but were not modelled in the paper (no NDVI); __units.modelled_in_paper marks them. Fourteen cameras were not working at retrieval; the deposit does not say when they failed, so their later camera-days may overstate effort (unit_camera_working_at_retrieval). Deployment names in the deposit are property-owner surnames plus a camera number; unit is pseudonymised to <county-pair>_<sheet row> and the names are not shipped.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, units = units, script = "data/clipp_2024_wvprivate_comm.R")

stage_dict_row(TABLE,
  description = sprintf("Daily detection/non-detection (with sequence counts in y_raw) of %d bird and mammal taxa at 146 game cameras deployed about two months each on private land in three West Virginia county pairs in summer 2022, with camera-hours per day as effort, coordinates and detection distance; one of three datasets behind a deer-coyote two-species occupancy paper.", nrow(species)),
  url = "https://doi.org/10.5281/zenodo.10391650",
  reference = "Clipp, H. L., Pesi, S. M., Miller, M. L., Gigliotti, L. C., Skelly, B. P., & Rota, C. T. (2024). White-tailed deer detection rates increase when coyotes are present. Ecology and Evolution, 14(3), e11149.",
  doi_paper = "10.1002/ece3.11149", doi_data = "10.5281/zenodo.10391650",
  original_license = "CC BY 4.0 (Zenodo record) / CC BY-NC (licence column of sequences.csv)", derived_license = "CC BY-NC 4.0",
  notes = "Wildlife Insights export; the per-row CC BY-NC governs over the record's CC BY. Eight deployments beyond the paper's 138 shipped and marked in __units. Coordinates on private land as published; unit ids pseudonymised (deposited names are landowner surnames).",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Community occupancy (single season); two-species co-occurrence (deer, coyote)",
  sampling_protocol = "camera_trap", design = "Single-season (2-77 camera-days per deployment)", realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "CC BY-NC (Wildlife Insights rows). All taxa identified to species shipped, including domestic cattle, horse, donkey, dog, cat; paper modelled deer and coyote only.",
  status = "tagged")
