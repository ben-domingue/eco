#!/usr/bin/env Rscript
# Table:  clipp_2024_monongahela_comm
# Source: Zenodo doi:10.5281/zenodo.10391650 (CC BY 4.0, published 2023-12-15), one file
#         Zenodo-Files.zip. Rota, C. T. (2023). Data for White-tailed Deer Detection Intensity
#         Increases When Coyotes Are Present. Zenodo.
# Paper:  Clipp, H. L., Pesi, S. M., Miller, M. L., Gigliotti, L. C., Skelly, B. P. & Rota, C. T.
#         (2024). White-tailed deer detection rates increase when coyotes are present. Ecology
#         and Evolution 14(3), e11149, doi:10.1002/ece3.11149 (CC BY 4.0).
# Data:   The zip holds three camera-trap datasets the paper combined for a two-species
#         (deer, coyote) continuous-time occupancy model, plus Stan code, fitted models and
#         derived RDS objects. This table is the first dataset only:
#         Data/Wildlife_Openings_Game_Camera_Site_Data.csv: 129 camera deployments (one per
#         Site_Name) at wildlife openings in the Monongahela National Forest, WV, in April-May
#         of 2019 (43), 2020 (19) and 2021 (67); deployment and retrieval timestamps to the
#         minute, camera model, study area, habitat type. No coordinates.
#         Data/Wildlife_Openings_Game_Camera_Detection_Data.csv: 1,395 rows, one per photo
#         record (minute resolution) with Site_Name, Species_Detected (43 labels incl. six
#         Unknown classes and a misspelt opossum), Timestamp_Detected. All species the
#         cameras recorded are present (birds and mammals), not only deer and coyote.
#         The other two datasets: Data/sequences.csv + Data/2022_Cameras.xlsx (private-land
#         WV cameras, 2022; Wildlife Insights export whose rows carry licence CC-BY-NC) are
#         the sibling table clipp_2024_wvprivate_comm; Data/SNAPSHOT_USA_2020_*.csv is the
#         complete Snapshot USA 2020 release re-uploaded by the authors (third-party data,
#         intake policy: not hosted from here; the paper used its 52 WV/PA cameras).
#         sites.RDS adds a per-camera NDVI (30 m raster mean over the deployment) the
#         authors computed; wtd.RDS / coy.RDS / stan_data.RDS are derived from the files above.
#         Checked: 12 of 1,395 records fall outside their camera's deployment window after
#         the window is widened to whole minutes (1 record one minute before the stated
#         deployment time; 3 records 6-17 days before deployment; 7 records at site 17-147
#         0-2 days before deployment; 1 record in 2021 at a camera deployed in 2019). They
#         are dropped as camera-clock errors (the paper's own code also discards detections
#         outside the deployment window).
#
# Mapping (standard section 3.6, community detection from a camera-trap record table with a
# deployment table):
#   unit = Site_Name (camera deployment; each site was deployed once), taxon = species code
#   for the 36 labels resolved to species (Virginia Opposum merged into Virginia Opossum),
#   occasion = camera-day index within the deployment (1 = deployment date), date = that
#   calendar date, y = 1 if the taxon has at least one record in that camera-day, y_raw =
#   number of photo records. Survey evidence: the deployment table; a camera-day exists
#   iff the deployment window (to the minute) covers part of that date, and
#   obs_camera_hours is the covered part of the day. unit_year, unit_camera_model and
#   unit_study_area / unit_habitat (constants here) as deposited. No period: every site has
#   one deployment. Not shipped: Unknown Animal / Bird / Corvid / Fox / Owl / Thrush (26
#   records), the 12 out-of-window records, NDVI (sites.RDS, an author-derived raster
#   summary not in the deposited raw files), everything derived from the detections
#   (stan_data.RDS, fitted models), the Snapshot USA 2020 files.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "clipp_2024_monongahela_comm"
zip <- download_cached("https://zenodo.org/api/records/10391650/files/Zenodo-Files.zip/content", TABLE, filename = "Zenodo-Files.zip")
dir <- file.path(dirname(zip), "Zenodo-Files")
if (!dir.exists(dir)) unzip(zip, exdir = dirname(zip))
meta_f <- file.path(dirname(zip), "zenodo_record.json")
if (!file.exists(meta_f)) download.file("https://zenodo.org/api/records/10391650", meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
stopifnot(identical(fromJSON(meta_f)$metadata$license$id, "cc-by-4.0"))
stopifnot(all(file.exists(file.path(dir, "Data", c("Wildlife_Openings_Game_Camera_Site_Data.csv", "Wildlife_Openings_Game_Camera_Detection_Data.csv",
                                                   "sequences.csv", "2022_Cameras.xlsx", "SNAPSHOT_USA_2020_deployments.csv", "SNAPSHOT_USA_2020_observations.csv")))))

site <- fread(file.path(dir, "Data", "Wildlife_Openings_Game_Camera_Site_Data.csv"))
det  <- fread(file.path(dir, "Data", "Wildlife_Openings_Game_Camera_Detection_Data.csv"))
stopifnot(nrow(site) == 129, uniqueN(site$Site_Name) == 129, nrow(det) == 1395, all(det$Site_Name %in% site$Site_Name),
          all(site$SiteCov_Study_Area == "Monongahela National Forest"), all(site$SiteCov_Habitat_Type == "Wildlife Opening"),
          site[, .N, by = Year][order(Year), identical(N, c(43L, 19L, 67L))])
site[, dep := as.POSIXct(SiteCov_Deployment_Timestamp, "%m/%d/%Y %H:%M", tz = "UTC")]
site[, ret := as.POSIXct(SiteCov_Retrieval_Timestamp, "%m/%d/%Y %H:%M", tz = "UTC")]
det[, t := as.POSIXct(Timestamp_Detected, "%m/%d/%Y %H:%M", tz = "UTC")]
stopifnot(!anyNA(site$dep), !anyNA(site$ret), !anyNA(det$t), all(site$ret > site$dep))
site[, ret := ret + 59]                                       # window inclusive of the retrieval minute
dur <- as.numeric(difftime(site$ret, site$dep, units = "days"))
stopifnot(min(dur) > 1, max(dur) < 11)                       # paper: 2-12 days, mean 8.9

# records outside the deployment window: camera-clock errors, dropped
det <- merge(det, site[, .(Site_Name, dep, ret)], by = "Site_Name")
out <- det[t < dep | t > ret]
stopifnot(nrow(out) == 12, out[, .N, by = Site_Name][order(Site_Name), identical(Site_Name, c("12-101", "12-147", "14-047", "14-057", "17-147", "18-281"))])
det <- det[t >= dep & t <= ret]

# taxa: labels resolved to species; Unknown classes dropped
det[Species_Detected == "Virginia Opposum", Species_Detected := "Virginia Opossum"]
species <- fread(text = '
label|scientificName
American Black Bear|Ursus americanus
American Crow|Corvus brachyrhynchos
American Robin|Turdus migratorius
American Woodcock|Scolopax minor
Barred Owl|Strix varia
Blue Jay|Cyanocitta cristata
Bobcat|Lynx rufus
Broad-winged Hawk|Buteo platypterus
Brown-headed Cowbird|Molothrus ater
Common Raven|Corvus corax
Coyote|Canis latrans
Dark-eyed Junco|Junco hyemalis
Domestic Cat|Felis catus
Domestic Dog|Canis familiaris
Eastern Bluebird|Sialia sialis
Eastern Cottontail|Sylvilagus floridanus
Eastern Fox Squirrel|Sciurus niger
Eastern Gray Squirrel|Sciurus carolinensis
Eastern Towhee|Pipilo erythrophthalmus
European Starling|Sturnus vulgaris
Fisher|Pekania pennanti
Gray Fox|Urocyon cinereoargenteus
Indigo Bunting|Passerina cyanea
Long-tailed Weasel|Neogale frenata
Northern Flicker|Colaptes auratus
Northern Raccoon|Procyon lotor
Red-shouldered Hawk|Buteo lineatus
Red-winged Blackbird|Agelaius phoeniceus
Ruffed Grouse|Bonasa umbellus
Scarlet Tanager|Piranga olivacea
Turkey Vulture|Cathartes aura
Virginia Opossum|Didelphis virginiana
White-tailed Deer|Odocoileus virginianus
Wild Turkey|Meleagris gallopavo
Wood Thrush|Hylocichla mustelina', sep = "|")
unknown <- c("Unknown Animal", "Unknown Bird", "Unknown Corvid", "Unknown Fox", "Unknown Owl", "Unknown Thrush")
stopifnot(setequal(det$Species_Detected, c(species$label, unknown)), nrow(species) == 35)
n_unknown <- sum(det$Species_Detected %in% unknown); stopifnot(n_unknown == 23)        # 24 in the file, one of them out of window
cat(sprintf("  dropped %d records in Unknown classes and %d out-of-window records\n", n_unknown, nrow(out)))
det <- det[!Species_Detected %in% unknown]
stopifnot(det[Species_Detected == "White-tailed Deer", .N] == 1153 - 11, det[Species_Detected == "Coyote", .N] == 24)
species[, taxon := toupper(paste0(substr(sub(" .*", "", scientificName), 1, 3), substr(sub(".* ", "", scientificName), 1, 3)))]
stopifnot(!anyDuplicated(species$taxon))
det <- merge(det, species, by.x = "Species_Detected", by.y = "label")

# survey set: camera-days from the deployment table
days <- site[, .(date = seq(as.IDate(dep), as.IDate(ret), by = "day")), by = .(Site_Name, dep, ret)]
days[, d0 := as.POSIXct(paste(date, "00:00:00"), tz = "UTC")]
days[, camera_hours := round(as.numeric(difftime(pmin(ret, d0 + 86400), pmax(dep, d0), units = "hours")), 2)]
stopifnot(all(days$camera_hours > 0), all(days$camera_hours <= 24))
days[, occasion := seq_len(.N), by = Site_Name]
stopifnot(abs(sum(days$camera_hours) / 24 - sum(dur)) < 0.01)
cat(sprintf("  %d deployments, %d camera-days (%.0f camera-days of effort)\n", nrow(site), nrow(days), sum(dur)))

det[, date := as.IDate(t)]
counts <- det[, .(records = .N), by = .(Site_Name, date, taxon)]
stopifnot(nrow(counts[!days, on = .(Site_Name, date)]) == 0)
long <- days[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(days))]
long <- merge(long, counts, by = c("Site_Name", "date", "taxon"), all.x = TRUE)
long[is.na(records), records := 0L]
long <- merge(long, site[, .(Site_Name, Year, SiteCov_Game_Camera_Type, SiteCov_Study_Area, SiteCov_Habitat_Type)], by = "Site_Name")
long <- long[, .(unit = Site_Name, taxon, y = as.integer(records > 0), y_raw = records, occasion, date = format(date),
                 obs_camera_hours = camera_hours, unit_year = Year, unit_camera_model = SiteCov_Game_Camera_Type,
                 unit_study_area = SiteCov_Study_Area, unit_habitat = SiteCov_Habitat_Type)]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(days) * nrow(species), sum(long$y_raw) == nrow(det), uniqueN(long$unit) == 129)

taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$label,
                  lookupName = ifelse(species$scientificName == "Neogale frenata", "Mustela frenata", species$scientificName))   # GBIF backbone still under Mustela
taxa[, taxon_class := ifelse(scientificName %in% species[label %in% c("American Black Bear", "Bobcat", "Coyote", "Domestic Cat", "Domestic Dog", "Eastern Cottontail",
  "Eastern Fox Squirrel", "Eastern Gray Squirrel", "Fisher", "Gray Fox", "Long-tailed Weasel", "Northern Raccoon", "Virginia Opossum", "White-tailed Deer"), scientificName], "Mammalia", "Aves")]
units <- site[, .(unit = Site_Name, year = Year, camera_model = SiteCov_Game_Camera_Type, deployed = format(dep, "%Y-%m-%dT%H:%MZ"),
                  retrieved = format(ret - 59, "%Y-%m-%dT%H:%MZ"), camera_days = round(dur, 2))]

dataset <- list(
  title = "Daily camera-trap detections of 35 bird and mammal taxa at 129 wildlife-opening cameras, Monongahela National Forest, West Virginia, April-May 2019-2021",
  creator = "Rota, Christopher T.; Clipp, Hannah L.", pubDate = "2023", doi = "10.5281/zenodo.10391650", sourceURL = "https://doi.org/10.5281/zenodo.10391650",
  citation = "Rota, C. T. (2023). Data for White-tailed Deer Detection Intensity Increases When Coyotes Are Present [Data set]. Zenodo. https://doi.org/10.5281/zenodo.10391650",
  paperDOI = "10.1002/ece3.11149",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Motion-triggered game cameras deployed for about a week each spring (2019-2021) at 129 wildlife openings in the Monongahela National Forest, West Virginia, one of three camera datasets Clipp et al. (2024) combined to fit a two-species occupancy model with a continuous-time detection process for white-tailed deer and coyote. The deposit lists every photo record by species and minute, so this table carries all 35 taxa the cameras identified to species, not only the two the paper modelled, as daily detection/non-detection with the number of records.",
  samplingProtocol = "Bushnell Trophy Cam HD (120 cameras) and Reconyx Hyperfire (9) game cameras at wildlife openings, deployed 1.4-11 days (mean 7.9) in April-May; every photo record with species and timestamp at minute resolution. Occasion = calendar day of the deployment; effort = hours the camera operated within that day.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day", effortColumn = "obs_camera_hours",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "occasion (camera-days within one deployment of 2-11 days); no period, each site deployed once", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Monongahela National Forest, West Virginia, USA (no coordinates deposited)", temporalCoverage = "2019-04-13/2021-05-12",
  coordinatesCoarsened = NA,
  notShipped = list(`Unknown Animal, Bird, Corvid, Fox, Owl, Thrush` = "24 records not resolved to a taxon (one also out of window)",
                    out_of_window = "12 records timestamped outside their camera's deployment window (camera-clock errors)",
                    `sites.RDS ndvi` = "per-camera NDVI the authors computed from 30 m rasters over the deployment; not among the deposited raw files",
                    `wtd.RDS, coy.RDS, stan_data.RDS, Fitted-Models/` = "derived from the detections; model inputs and outputs",
                    `Data/SNAPSHOT_USA_2020_*.csv` = "the full Snapshot USA 2020 release re-uploaded by the authors (third-party data, not hosted from this deposit; the paper used its 52 WV and PA cameras)",
                    `Data/sequences.csv, Data/2022_Cameras.xlsx` = "the 2022 private-land cameras, shipped as clipp_2024_wvprivate_comm (rows licensed CC BY-NC)"),
  notes = "The paper's response was the timestamp of each deer or coyote sequence (photos within one minute of each other); this table aggregates records to camera-days, with y_raw the number of minute-resolution records. The deposit gives records at minute resolution, so the paper's sequences cannot be reconstructed exactly. Deer detected at 114 of 129 cameras, coyote at a few; most bird taxa are rare.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, units = units, script = "data/clipp_2024_monongahela_comm.R")

stage_dict_row(TABLE,
  description = "Daily detection/non-detection (with record counts in y_raw) of 35 bird and mammal taxa at 129 game cameras deployed about a week each at wildlife openings in the Monongahela National Forest, West Virginia, in April-May 2019, 2020 and 2021, with camera-hours per day as effort; one of three datasets behind a deer-coyote two-species occupancy paper.",
  url = "https://doi.org/10.5281/zenodo.10391650",
  reference = "Clipp, H. L., Pesi, S. M., Miller, M. L., Gigliotti, L. C., Skelly, B. P., & Rota, C. T. (2024). White-tailed deer detection rates increase when coyotes are present. Ecology and Evolution, 14(3), e11149.",
  doi_paper = "10.1002/ece3.11149", doi_data = "10.5281/zenodo.10391650", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Wildlife-openings dataset only. The deposit also re-uploads Snapshot USA 2020 (third-party, not hosted) and a Wildlife Insights export licensed CC BY-NC (shipped separately as clipp_2024_wvprivate_comm).",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Community occupancy (single season); two-species co-occurrence (deer, coyote)",
  sampling_protocol = "camera_trap", design = "Single-season (1-11 camera-days per deployment)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "All taxa identified to species shipped, including domestic dog and cat; paper modelled deer and coyote only.",
  status = "tagged")
