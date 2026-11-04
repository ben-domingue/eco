#!/usr/bin/env Rscript
# Tables: boone_2023_minnesota_bombus_count (coarsened) and boone_2023_minnesota_bombus_exact_count
#         (E7.3 sibling without Bombus affinis)
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
#   v1.1: closure = closed (five rounds in one summer), occasionKind = time, taxonInclusion =
#   recorded (every class recorded at least once). The two group classes are taxonRank
#   speciesAggregate with taxonRemarks (taxonID the genus Bombus), and BOMVAG says it is also
#   inside the vagans/sandersoni class (E6). E7.3 / E7.4: the deposit's site ids are place
#   names (afton, bremen, ...), so the coarsened table (all classes, coordinates at 0.1-degree
#   cell centres) uses sequential ids S01..S25 (in order of the source ids); the _exact sibling
#   (every class but B. affinis) keeps the source ids and the two-decimal coordinates as
#   published. unit_region (central / northeast / ...) is a compass sector of the state, not a
#   place name, and ships in both.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
dir <- download_dryad("10.5061/dryad.0p2ngf264", "boone_2023_minnesota_bombus_count")
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
stopifnot(all(site$lat == round(site$lat, 2)), all(site$lon == round(site$lon, 2)))
setorder(site, site)
site[, sid := sprintf("S%02d", seq_len(.N))]
cc <- coarsen_coords(site$lat, site$lon, 0.1)
site[, `:=`(c_lat = cc$lat, c_lon = cc$lon, c_unc = cc$uncertainty_m)]
long <- merge(long, site[, .(site, sid, lat, lon, c_lat, c_lon, c_unc,
                             unit_dominant_landuse = landuse, unit_region = region)], by = "site")
long <- long[, .(unit = site, taxon, y, occasion = as.integer(round),
                 date = sprintf("2021-%02d-%02d", as.integer(month), as.integer(day)), observer,
                 obs_females, obs_males, obs_queens, obs_id_confidence,
                 obs_survey_minutes = as.integer(total_survey_time), obs_time_start = format(time_start, "%H:%M", tz = "UTC"),
                 obs_time_end = format(time_end, "%H:%M", tz = "UTC"), obs_temp_f = temperature_F, obs_wind_mph = wind_mph,
                 obs_cloud_pct = cloud_percentage, obs_bloom_cover_class = percent_est_veg_cover,
                 obs_native_plants_in_bloom_class = no_native_plants, obs_honey_bees_seen = honey_bees,
                 obs_bombus_apis_ratio = bombus_apis_ratio,
                 sid, lat, lon, c_lat, c_lon, c_unc, unit_dominant_landuse, unit_region)]
stopifnot(nrow(long) == 121 * 15, sum(long$y) == rec[, sum(female_count + male_count + queen_count)],
          sum(long$y > 0) == nrow(rec), !anyNA(long$date), !anyNA(as.IDate(long$date)))

CLASS[rank == "species group", rank := "speciesAggregate"]
CLASS[, remarks := NA_character_]
CLASS[taxon == "BOMAUP", remarks := "Species aggregate recorded as one class by the source (B. auricomus and B. pensylvanicus not separated in the field); taxonID is the genus Bombus"]
CLASS[taxon == "BOMVGS", remarks := "Species aggregate recorded as one class by the source (B. vagans and B. sandersoni not separated in the field); taxonID is the genus Bombus. B. vagans is also its own class (BOMVAG)"]
CLASS[taxon == "BOMVAG", remarks := "Individuals identified as B. vagans; others not separated from B. sandersoni are in BOMVGS, so a zero here is not an absence of B. vagans"]
taxa <- make_taxa(CLASS$taxon, CLASS$scientificName, taxonRank = CLASS$rank, lookupName = CLASS$lookup,
                  taxon_deposited_class = CLASS$species_group, taxonRemarks = CLASS$remarks, allow_higher = c("BOMAUP", "BOMVGS"))
taxa[taxon == "BOMAFF", taxon_conservationStatus := "Endangered (US ESA, 2017); IUCN Critically Endangered"]
emit <- function(TABLE, exact) {
  lg <- copy(long); tx <- copy(taxa)
  if (exact) {
    lg <- lg[taxon != "BOMAFF"]; tx <- tx[taxon != "BOMAFF"]
    lg[, `:=`(unit_decimalLatitude = lat, unit_decimalLongitude = lon)]
  } else {
    lg[, `:=`(unit = sid, unit_decimalLatitude = c_lat, unit_decimalLongitude = c_lon, unit_coordinateUncertainty_m = c_unc)]
  }
  lg[, c("sid", "lat", "lon", "c_lat", "c_lon", "c_unc") := NULL]
  setcolorder(lg, c(setdiff(names(lg), c("unit_dominant_landuse", "unit_region")), "unit_dominant_landuse", "unit_region"))
  dataset <- list(
    title = paste0("Bumble bee counts by species from five timed searches at 25 sites across Minnesota, June-September 2021", if (exact) " (without Bombus affinis, coordinates as published)" else ""),
    creator = "Boone, Michelle L.",
    pubDate = "2023", doi = "10.5061/dryad.0p2ngf264", sourceURL = "https://doi.org/10.5061/dryad.0p2ngf264",
    citation = "Boone, M. (2023). 2021 Minnesota bumble bee survey data [Dataset]. Dryad. https://doi.org/10.5061/dryad.0p2ngf264",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Counts of bumble bees (females, males and queens) by species or species group in one-hour active searches of a 3-acre area at 25 sites across Minnesota, five rounds between mid-June and 1 September 2021 (one site once), with survey weather, timing, bloom cover, native plants in bloom and honey bee presence, and site land use and region. The data supported multi-species occupancy models for seven Bombus species including the endangered rusty patched bumble bee (Bombus affinis), which was associated with developed land.",
    samplingProtocol = "USFWS (2019) recovery-monitoring protocol for B. affinis in high-potential zones: one experienced observer actively searched a 3-acre area for 60 minutes (20 or 40 at two sub-areas in rounds 1-2), timer stopped while netting and photographing, recording species/species group and sex of every bumble bee; one bee per species per survey netted and photographed for verification.",
    samplingProtocolCode = "timed_search", effortColumn = "obs_survey_minutes",
    surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
    closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
    closureNote = "occasion (five survey rounds within one summer)",
    geographicCoverage = list(description = "Minnesota, USA (five regions)",
                              boundingBox = if (exact) list(west = min(site$lon), east = max(site$lon), south = min(site$lat), north = max(site$lat)) else
                                list(west = min(site$c_lon) - 0.05, east = max(site$c_lon) + 0.05, south = min(site$c_lat) - 0.05, north = max(site$c_lat) + 0.05)),
    temporalCoverage = paste(min(long$date), max(long$date), sep = "/"),
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "As published (two decimals): Bombus affinis (US ESA endangered, IUCN CR) is not in this table (E7.3); boone_2023_minnesota_bombus_count has it with coarsened coordinates") else
      list(value = TRUE, method = "coarsen_coords() to 0.1-degree cell centres: the deposited two-decimal site coordinates (about 1 km) are finer than 0.1 degree and the table includes Bombus affinis (US ESA endangered, IUCN CR); site ids, which are place names, replaced by S01..S25 (E7.4)"),
    notShipped = c(if (exact) list(BOMAFF = "Bombus affinis (US ESA endangered, IUCN CR): in boone_2023_minnesota_bombus_count only, whose coordinates are coarsened")
                   else list(`site names` = "the deposit's site ids are place names; replaced by sequential ids S01..S25 (E7.4); the names are in boone_2023_minnesota_bombus_exact_count"), list(unidentified = "13 records of bumble bees not identified to species or group",
                      fervidus_borealis = "1 record (one female) ambiguous between two shipped species",
                      psythirus_sp = "1 record of a cuckoo bumble bee identified to subgenus only",
                      `plant_id1..8` = "plants each species was seen foraging on (per record)",
                      `veg_cover_recoded, native_plants_recoded` = "numeric recodes of the shipped class columns")),
    notes = "taxon is the identification class as recorded: B. vagans appears both as its own class and inside the vagans/sandersoni group class, and B. auricomus and B. pensylvanicus only as a group, so a zero for BOMVAG means no individual was recorded as vagans (not that none was present). y = females + males + queens; the split is in obs_females/obs_males/obs_queens with obs_id_confidence (% confidence of the identification), all NA where the class was not recorded at the survey. Region is recorded inconsistently between surveys for oakleaflake and oavee; unit_region is the most frequent value. The metadata says the two Lone Lake Park sites were surveyed six times; the deposit has one lonelake site with five rounds. No paper DOI is linked on the Dryad record.")
  ds <- write_table(lg, TABLE, dataset, taxa = tx, script = "data/boone_2023_minnesota_bombus_count.R")

  stage_dict_row(TABLE,
    description = if (exact) "Bumble bee counts (females, males, queens) for 14 species and species-group classes (all but the endangered rusty patched bumble bee) from five one-hour active searches at 25 sites across Minnesota, June-September 2021, with survey weather, bloom and honey bee covariates and site land use; coordinates as published." else
      "Bumble bee counts (females, males, queens) for 15 species and species-group classes, including the endangered rusty patched bumble bee, from five one-hour active searches at 25 sites across Minnesota, June-September 2021, with survey weather, bloom and honey bee covariates and site land use; coordinates coarsened to 0.1 degree.",
    url = "https://doi.org/10.5061/dryad.0p2ngf264",
    reference = "Boone, M. (2023). 2021 Minnesota bumble bee survey data. Dryad. https://doi.org/10.5061/dryad.0p2ngf264",
    doi_paper = "", doi_data = "10.5061/dryad.0p2ngf264",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = if (exact) "E7.3 sibling of boone_2023_minnesota_bombus_count without B. affinis; coordinates and site names as published." else "Taxa are identification classes as recorded, two of them species aggregates. Coordinates coarsened and site ids replaced for B. affinis; boone_2023_minnesota_bombus_exact_count has the other classes at published precision.",
    source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy or N-mixture (multi-species)",
    sampling_protocol = "timed_search", design = "Single-season (5 survey rounds)", realm = "Terrestrial",
    country = "USA", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)", notes = if (exact) "121 surveys x 14 classes (B. affinis withheld for precision)." else "9 B. affinis records; 121 surveys x 15 classes.")
}
emit("boone_2023_minnesota_bombus_count", exact = FALSE)
emit("boone_2023_minnesota_bombus_exact_count", exact = TRUE)
