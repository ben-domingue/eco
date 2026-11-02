#!/usr/bin/env Rscript
# Table:  boone_2023_minnesota_bombus_count
# Source: Dryad doi:10.5061/dryad.0p2ngf264 (CC0 1.0, as shown on the Dryad page; published
#         2023-08-03). Boone, M. (2023). 2021 Minnesota bumble bee survey data.
# Paper:  Boone, M.L. et al. (2023). Multi-species occupancy models of seven Bombus species,
#         including the endangered rusty patched bumble bee (Bombus affinis), against
#         developed, agricultural and natural land use within 0.5 and 1.5 km, Minnesota
#         (the Dryad record names no article DOI; the abstract and methods are on the Dryad
#         page and quoted below).
# Data:   2021MNBumbleBeeData.xlsx, sheet "bee data" (587 rows x 35 columns) and sheet
#         "metadata" (one row per column: possible values, scale, unit, description);
#         README.md.txt. One row per survey x species group with counts of females, males
#         and queens; a survey with no bumble bees has one row with species_group "none"
#         (one such survey). Survey columns (constant within site x round, asserted):
#         round (survey number), day, month, year (2021), observer (one: mlb), temperature
#         (F), wind (mph), cloud %, start and end time, total_survey_time (minutes of
#         active search, 20/40/60), percent of the 3-acre area in bloom (class and 1-5
#         recode), native plants in bloom (class and 0-4 recode), honey bees seen (yes/no),
#         bumble bee : honey bee ratio class. Site columns: latitude, longitude (two
#         decimals), dominant_landuse_type, region. Record columns: species_group (17
#         species or groups, "unidentified", "none"), female_count, male_count,
#         queen_count, confidence (% sure of the identification), plant_id1..8 (plants the
#         species was seen foraging on). 25 sites: 24 surveyed in five rounds and rockdell
#         in round 1 only (121 surveys); the metadata says the two Lone Lake Park sites
#         were surveyed six times, but the deposit has one "lonelake" site with five
#         rounds. Dryad methods: each site was visited five times between 14 June and 1
#         September 2021 following the USFWS B. affinis recovery survey protocol; a single
#         observer actively searched a 3-acre area for one hour (timer stopped while
#         handling bees) and recorded species and sex of every bumble bee.
#
# Mapping (standard: community counts, E9 core; the paper fit multi-species occupancy):
#   unit = site; one period; occasion = round; taxon = identification class as recorded
#   (12 species plus two species-group classes, auricomus/pensylvanicus and
#   vagans/sandersoni, resolved in __taxa with taxonRank "species group"); y = females +
#   males + queens counted; obs_females / obs_males / obs_queens / obs_id_confidence vary
#   by taxon within a survey (E5 allows it; NA where the class was not recorded); date =
#   2021-month-day; observer. obs_ survey covariates as deposited (time as HH:MM;
#   total_survey_time is effortColumn). unit_: coordinates coarsened to 0.1 degree,
#   dominant land use, region. Survey evidence: the record table (row_presence): a survey
#   is a site x round with at least one row, including the "none" row; every class gets a
#   row (0 if not recorded) at every survey. Not shipped: "unidentified" (13 records),
#   "fervidus_borealis" (1, ambiguous between two shipped species), "psythirus_sp" (1,
#   genus-level cuckoo bumble bee), plant_id1..8 (forage plants per record), the
#   recoded vegetation and native-plant columns (duplicates of the class columns).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "boone_2023_minnesota_bombus_count"
dir <- download_dryad("10.5061/dryad.0p2ngf264", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^2021MNBumbleBeeData\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1, identical(excel_sheets(f), c("bee data", "metadata")))
raw <- as.data.table(read_excel(f, "bee data"))

# facts about the source
SURV <- c("day", "month", "year", "observer", "temperature_F", "wind_mph", "cloud_percentage", "time_start", "time_end",
          "total_survey_time", "percent_est_veg_cover", "veg_cover_recoded", "no_native_plants", "native_plants_recoded",
          "honey_bees", "bombus_apis_ratio")
stopifnot(nrow(raw) == 587, ncol(raw) == 35, uniqueN(raw$site) == 25, all(raw$year == 2021), all(raw$observer == "mlb"),
          nrow(unique(raw[, .(site, round)])) == 121, !anyDuplicated(raw[, .(site, round, species_group)]),
          all(sapply(SURV, function(v) raw[, uniqueN(get(v)), by = .(site, round)][, max(V1)]) == 1),
          raw[, uniqueN(latitude), by = site][, max(V1)] == 1, raw[, uniqueN(longitude), by = site][, max(V1)] == 1,
          raw[, uniqueN(dominant_landuse_type), by = site][, max(V1)] == 1,
          raw[species_group == "none", .N] == 1, raw[species_group != "none", !anyNA(female_count + male_count + queen_count)],
          raw[species_group != "none", all(female_count + male_count + queen_count > 0 | species_group == "unidentified")],
          all(raw$total_survey_time %in% c(20, 40, 60)), all(raw$month %in% 6:9))
stopifnot(identical(raw[, uniqueN(round), by = site][order(site)][V1 != 5, site], "rockdell"))
reg2 <- raw[, uniqueN(region), by = site][V1 > 1, site]
stopifnot(identical(sort(reg2), c("oakleaflake", "oavee")))   # region recorded inconsistently between surveys

CLASS <- data.table(
  species_group = c("griseocollis", "impatiens", "bimaculatus", "auricomus_pensylvanicus", "borealis", "rufocinctus", "fervidus",
                    "vagans", "ternarius", "vagans_sandersoni", "citrinus", "affinis", "terricola", "perplexus", "insularis"),
  taxon = c("BOMGRI", "BOMIMP", "BOMBIM", "BOMAUP", "BOMBOR", "BOMRUF", "BOMFER", "BOMVAG", "BOMTRN", "BOMVGS", "BOMCIT",
            "BOMAFF", "BOMTRC", "BOMPER", "BOMINS"),
  scientificName = c("Bombus griseocollis", "Bombus impatiens", "Bombus bimaculatus", "Bombus auricomus / Bombus pensylvanicus",
                     "Bombus borealis", "Bombus rufocinctus", "Bombus fervidus", "Bombus vagans", "Bombus ternarius",
                     "Bombus vagans / Bombus sandersoni", "Bombus citrinus", "Bombus affinis", "Bombus terricola",
                     "Bombus perplexus", "Bombus insularis"),
  lookup = c("Bombus griseocollis", "Bombus impatiens", "Bombus bimaculatus", "Bombus", "Bombus borealis", "Bombus rufocinctus",
             "Bombus fervidus", "Bombus vagans", "Bombus ternarius", "Bombus", "Bombus citrinus", "Bombus affinis",
             "Bombus terricola", "Bombus perplexus", "Bombus insularis"),
  rank = c(rep("species", 3), "species group", rep("species", 5), "species group", rep("species", 5)))
NOTSHIP <- c("unidentified", "fervidus_borealis", "psythirus_sp", "none")
stopifnot(setequal(unique(raw$species_group), c(CLASS$species_group, NOTSHIP)))

surv <- unique(raw[, c("site", "round", SURV), with = FALSE])
stopifnot(nrow(surv) == 121)
rec <- merge(raw[species_group %in% CLASS$species_group], CLASS[, .(species_group, taxon)], by = "species_group")
grid <- CJ(i = seq_len(nrow(surv)), taxon = CLASS$taxon)
grid <- cbind(surv[grid$i, .(site, round)], taxon = grid$taxon)
long <- merge(grid, rec[, .(site, round, taxon, obs_females = as.integer(female_count), obs_males = as.integer(male_count),
                            obs_queens = as.integer(queen_count), obs_id_confidence = confidence)],
              by = c("site", "round", "taxon"), all.x = TRUE)
long[, y := fcoalesce(obs_females, 0L) + fcoalesce(obs_males, 0L) + fcoalesce(obs_queens, 0L)]
long <- merge(long, surv, by = c("site", "round"))
site <- raw[, .(region = names(which.max(table(region))), lat = latitude[1], lon = longitude[1], landuse = dominant_landuse_type[1]), by = site]
cc <- coarsen_coords(site$lat, site$lon, 0.1)
site[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertainty_m = cc$uncertainty_m)]
long <- merge(long, site[, .(site, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertainty_m,
                             unit_dominant_landuse = landuse, unit_region = region)], by = "site")
long <- long[, .(unit = site, taxon, y, occasion = as.integer(round),
                 date = sprintf("2021-%02d-%02d", as.integer(month), as.integer(day)), observer,
                 obs_females, obs_males, obs_queens, obs_id_confidence,
                 obs_survey_minutes = as.integer(total_survey_time), obs_time_start = format(time_start, "%H:%M", tz = "UTC"),
                 obs_time_end = format(time_end, "%H:%M", tz = "UTC"), obs_temp_f = temperature_F, obs_wind_mph = wind_mph,
                 obs_cloud_pct = cloud_percentage, obs_bloom_cover_class = percent_est_veg_cover,
                 obs_native_plants_in_bloom_class = no_native_plants, obs_honey_bees_seen = honey_bees,
                 obs_bombus_apis_ratio = bombus_apis_ratio,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertainty_m, unit_dominant_landuse, unit_region)]
stopifnot(nrow(long) == 121 * 15, sum(long$y) == rec[, sum(female_count + male_count + queen_count)],
          sum(long$y > 0) == nrow(rec), !anyNA(long$date), !anyNA(as.IDate(long$date)))

taxa <- make_taxa(CLASS$taxon, CLASS$scientificName, taxonRank = CLASS$rank, lookupName = CLASS$lookup,
                  taxon_deposited_class = CLASS$species_group)
taxa[taxon == "BOMAFF", taxon_conservationStatus := "Endangered (US ESA, 2017); IUCN Critically Endangered"]
dataset <- list(
  title = "Bumble bee counts by species from five timed searches at 25 sites across Minnesota, June-September 2021",
  creator = "Boone, Michelle L.",
  pubDate = "2023", doi = "10.5061/dryad.0p2ngf264", sourceURL = "https://doi.org/10.5061/dryad.0p2ngf264",
  citation = "Boone, M. (2023). 2021 Minnesota bumble bee survey data [Dataset]. Dryad. https://doi.org/10.5061/dryad.0p2ngf264",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of bumble bees (females, males and queens) by species or species group in one-hour active searches of a 3-acre area at 25 sites across Minnesota, five rounds between mid-June and 1 September 2021 (one site once), with survey weather, timing, bloom cover, native plants in bloom and honey bee presence, and site land use and region. The data supported multi-species occupancy models for seven Bombus species including the endangered rusty patched bumble bee (Bombus affinis), which was associated with developed land.",
  samplingProtocol = "USFWS (2019) recovery-monitoring protocol for B. affinis in high-potential zones: one experienced observer actively searched a 3-acre area for 60 minutes (20 or 40 at two sub-areas in rounds 1-2), timer stopped while netting and photographing, recording species/species group and sex of every bumble bee; one bee per species per survey netted and photographed for verification.",
  samplingProtocolCode = "timed_search", effortColumn = "obs_survey_minutes",
  surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "occasion (five survey rounds within one summer)",
  geographicCoverage = list(description = "Minnesota, USA (five regions)",
                            boundingBox = list(west = min(site$unit_decimalLongitude) - 0.05, east = max(site$unit_decimalLongitude) + 0.05,
                                               south = min(site$unit_decimalLatitude) - 0.05, north = max(site$unit_decimalLatitude) + 0.05)),
  temporalCoverage = paste(min(long$date), max(long$date), sep = "/"),
  coordinatesCoarsened = list(value = TRUE, method = "coarsen_coords() to 0.1-degree cell centres: the deposited two-decimal site coordinates (about 1 km) are finer than 0.1 degree and the table includes Bombus affinis (US ESA endangered, IUCN CR)"),
  notShipped = list(unidentified = "13 records of bumble bees not identified to species or group",
                    fervidus_borealis = "1 record (one female) ambiguous between two shipped species",
                    psythirus_sp = "1 record of a cuckoo bumble bee identified to subgenus only",
                    `plant_id1..8` = "plants each species was seen foraging on (per record)",
                    `veg_cover_recoded, native_plants_recoded` = "numeric recodes of the shipped class columns"),
  notes = "taxon is the identification class as recorded: B. vagans appears both as its own class and inside the vagans/sandersoni group class, and B. auricomus and B. pensylvanicus only as a group, so a zero for BOMVAG means no individual was recorded as vagans (not that none was present). y = females + males + queens; the split is in obs_females/obs_males/obs_queens with obs_id_confidence (% confidence of the identification), all NA where the class was not recorded at the survey. Region is recorded inconsistently between surveys for oakleaflake and oavee; unit_region is the most frequent value. The metadata says the two Lone Lake Park sites were surveyed six times; the deposit has one lonelake site with five rounds. No paper DOI is linked on the Dryad record.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/boone_2023_minnesota_bombus_count.R")

stage_dict_row(TABLE,
  description = "Bumble bee counts (females, males, queens) for 15 species and species-group classes, including the endangered rusty patched bumble bee, from five one-hour active searches at 25 sites across Minnesota, June-September 2021, with survey weather, bloom and honey bee covariates and site land use; coordinates coarsened to 0.1 degree.",
  url = "https://doi.org/10.5061/dryad.0p2ngf264",
  reference = "Boone, M. (2023). 2021 Minnesota bumble bee survey data. Dryad. https://doi.org/10.5061/dryad.0p2ngf264",
  doi_paper = "", doi_data = "10.5061/dryad.0p2ngf264",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First pollinator table. Taxa are identification classes as recorded, two of them species groups. Coordinates coarsened for B. affinis.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy or N-mixture (multi-species)",
  sampling_protocol = "timed_search", design = "Single-season (5 survey rounds)", realm = "Terrestrial",
  country = "USA", coordinates = "Coarsened (0.1 deg)", notes = "9 B. affinis records; 121 surveys x 15 classes.")
