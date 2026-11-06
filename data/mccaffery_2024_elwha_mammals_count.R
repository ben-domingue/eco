#!/usr/bin/env Rscript
# Table:  mccaffery_2024_elwha_mammals_count
# Source: USGS ScienceBase doi:10.5066/P1BJD7OH (USGS data release, published 2024-03-07; use
#         constraints "No use constraints. Public domain data from the U.S. Government are freely
#         redistributable with proper metadata and source attribution"; recorded as CC0 1.0)
#   McCaffery, R.M., Cendejas-Zarelli, S.J., Goodwin, K.R., Happe, P.J., Jenkins, K.J., and
#   Sager-Fradkin, K.A., 2024, Camera trap photo detections of mammals along three reaches of the
#   Elwha River, Washington: U.S. Geological Survey data release.
# Data:   ElwhaRiver_CameraTrapping.csv: 255,540 rows, one per camera station x calendar date x
#         species for 15 mammal taxa, with the number of independent photo detections that day
#         (photos of a species at a camera at least 30 minutes apart), the study reach (Aldwell and
#         Mills, former reservoir beds, and Geyser, an undammed reach), study year (Year 1 =
#         2021-07-08 to 2022-07-07, Year 2 = 2022-07-08 to 2023-07-08), season, the camera's
#         viewshed and its distance to the former shoreline or forest edge. 34 station names: 30
#         stations plus four relocated cameras (Aldwell_03_2, Aldwell_09_2, Geyser_05_2, Mills_09_2).
#         Unbaited cameras, motion trigger plus two time-lapse frames a day to confirm operation.
#         Asserted: every station-date has exactly the 15 species rows (17,036 station-days; the
#         lineage reports 17,037 trap-nights), no counts missing, viewshed and edge distance
#         constant within a station, and the year labels match the date ranges.
# Mapping: unit = camera station as named by the source (a relocated camera is its own unit),
#   cluster_id = study reach, period = study year (1, 2), occasion = day of the study year (1 = 8
#   July), date = the calendar date, taxon = species code, y = independent detections that day
#   (responseType count). surveyEvidence row_presence: a station-date exists in the file only when
#   the camera operated, and then with explicit zeros for every species; dates a camera was down
#   have no rows. obs_season as deposited. unit_viewshed (as deposited; the metadata gives no
#   unit) and unit_dist_edge_m. No coordinates are deposited. Taxa as the source names them:
#   "Chipmunk" is the genus Neotamias, "Spotted Skunk" the genus Spilogale, "Mustelid Unspecified"
#   the family Mustelidae; Columbian black-tailed deer is matched at subspecies, Roosevelt elk at
#   the species Cervus canadensis (GBIF has no exact match for the subspecies).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mccaffery_2024_elwha_mammals_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/65dce343d34eb64889e197bb?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
d <- fread(download_cached(fl[["ElwhaRiver_CameraTrapping.csv"]], TABLE, filename = "ElwhaRiver_CameraTrapping.csv"))
stopifnot(nrow(d) == 255540, uniqueN(d$Species) == 15, !anyNA(d), all(d$PhotoCount >= 0), all(d$PhotoCount == round(d$PhotoCount)),
          !anyDuplicated(d[, .(CameraStationName, Date, Species)]), all(d[, .N, by = .(CameraStationName, Date)]$N == 15),
          uniqueN(d[, .(CameraStationName, Date)]) == 17036, uniqueN(d$CameraStationName) == 34,
          d[, .(uniqueN(Viewshed), uniqueN(DistEdge), uniqueN(StudyReach)), by = CameraStationName][, all(V1 == 1 & V2 == 1 & V3 == 1)])
d[, date := as.IDate(Date)]
y0 <- setNames(as.IDate(c("2021-07-08", "2022-07-08")), c("Year 1", "Year 2"))
stopifnot(all(d$Year %in% names(y0)), d[Year == "Year 1", all(date >= y0[1] & date < y0[2])], d[Year == "Year 2", all(date >= y0[2] & date <= as.IDate("2023-07-08"))])
code <- c("American Black Bear" = "URSAME", "Bobcat" = "LYNRUF", "Chipmunk" = "NEOTAM", "Columbian Black-tailed Deer" = "ODOHEC",
          "Coyote" = "CANLAT", "Douglas's Squirrel" = "TAMDOU", "Fisher" = "PEKPEN", "Mustelid Unspecified" = "MUSTEL",
          "Northern Flying Squirrel" = "GLASAB", "Puma" = "PUMCON", "Raccoon" = "PROLOT", "Roosevelt Elk" = "CERCAN",
          "Snowshoe Hare" = "LEPAME", "Spotted Skunk" = "SPILOG", "Virginia Opossum" = "DIDVIR")
stopifnot(setequal(names(code), d$Species))
long <- d[, .(unit = CameraStationName, taxon = code[Species], y = as.integer(PhotoCount), period = match(Year, names(y0)),
              occasion = as.integer(date - y0[Year]) + 1L, date = format(date), cluster_id = StudyReach,
              unit_viewshed = Viewshed, unit_dist_edge_m = DistEdge, obs_season = Season)]
stopifnot(nrow(long) == 255540, max(long$occasion) == 366, sum(long$y) == sum(d$PhotoCount))
sci <- c(URSAME = "Ursus americanus", LYNRUF = "Lynx rufus", NEOTAM = "Neotamias", ODOHEC = "Odocoileus hemionus columbianus",
         CANLAT = "Canis latrans", TAMDOU = "Tamiasciurus douglasii", PEKPEN = "Pekania pennanti", MUSTEL = "Mustelidae",
         GLASAB = "Glaucomys sabrinus", PUMCON = "Puma concolor", PROLOT = "Procyon lotor", CERCAN = "Cervus canadensis",
         LEPAME = "Lepus americanus", SPILOG = "Spilogale", DIDVIR = "Didelphis virginiana")
rank <- c(NEOTAM = "genus", ODOHEC = "subspecies", MUSTEL = "family", SPILOG = "genus")
tc <- unname(code)
taxa <- make_taxa(tc, sci[tc], vernacularName = names(code), taxonRank = ifelse(tc %in% names(rank), rank[tc], "species"),
                  taxonRemarks = ifelse(tc == "CERCAN", "source names Roosevelt elk (C. c. roosevelti); matched at species, GBIF has no exact subspecies match",
                                 ifelse(tc == "MUSTEL", "source: Mustelid Unspecified", NA_character_)))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Daily independent camera detections of 15 mammal taxa at 34 camera stations along three reaches of the Elwha River, Washington, 2021-2023",
  creator = "McCaffery, Rebecca M.; Cendejas-Zarelli, Sara J.; Goodwin, Katy R.; Happe, Patricia J.; Jenkins, Kurt J.; Sager-Fradkin, Kimberly A.",
  pubDate = "2024", doi = "10.5066/P1BJD7OH", sourceURL = "https://doi.org/10.5066/P1BJD7OH",
  citation = "McCaffery, R.M., Cendejas-Zarelli, S.J., Goodwin, K.R., Happe, P.J., Jenkins, K.J., and Sager-Fradkin, K.A., 2024, Camera trap photo detections of mammals along three reaches of the Elwha River, Washington: U.S. Geological Survey data release, https://doi.org/10.5066/P1BJD7OH.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (no use constraints)"),
  abstract = "Unbaited camera traps at ten stations in each of three reaches of the Elwha River (the drained Aldwell and Mills reservoirs and the undammed Geyser reach), July 2021 to July 2023, after the removal of two dams, recording mammal use as the riparian ecosystem recovers. The data are daily counts of independent photo detections (at least 30 minutes apart) for 15 mammal taxa at every station-day a camera operated.",
  samplingProtocol = "Unbaited cameras (Browning ProDCL, motion trigger plus two daily time-lapse frames to confirm operation) at a systematic sample of 200 m grid points, ten per reach; independent detections are photos of a species at a camera at least 30 minutes apart, counted per day.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "occasions are days across a study year (July to July); use is not closed across seasons", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = list(description = "Elwha River valley (Aldwell, Mills and Geyser reaches), Olympic Peninsula, Washington, USA",
                            boundingBox = list(west = -123.6525, east = -123.4506, south = 47.8611, north = 48.1533)),
  temporalCoverage = "2021-07/2023-07",
  notes = "Rows exist only for station-days the camera operated (17,036 of the 17,037 trap-nights the lineage reports). The source compiled the counts with machine-learning classifiers verified by hand.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:2, start = c("2021-07-08", "2022-07-08"), end = c("2022-07-07", "2023-07-08")),
                  script = "data/mccaffery_2024_elwha_mammals_count.R")
stage_dict_row(TABLE,
  description = "Daily counts of independent camera detections of 15 mammal taxa at every operating station-day of 34 camera stations along three reaches of the Elwha River, Washington, after dam removal, July 2021 to July 2023.",
  url = "https://doi.org/10.5066/P1BJD7OH",
  reference = "McCaffery, R.M., et al. (2024). Camera trap photo detections of mammals along three reaches of the Elwha River, Washington. U.S. Geological Survey data release.",
  doi_data = "10.5066/P1BJD7OH", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "occasion = day of the study year; rows only for station-days the camera operated.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy / N-mixture (camera days)", sampling_protocol = "camera_trap",
  design = "Multi-season (2 study years x daily occasions)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Post dam-removal monitoring; relocated cameras are separate units.")
