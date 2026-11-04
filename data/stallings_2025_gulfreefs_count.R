#!/usr/bin/env Rscript
# Tables: stallings_2025_gulfreefs_count (coarsened) and stallings_2025_gulfreefs_exact_count (E7.3
#         sibling without the IUCN CR / EN / VU taxa)
# Source: Zenodo doi:10.5281/zenodo.14338634 (version of 2024-12-09; concept DOI
#         10.5281/zenodo.10882237, whose first version of 2024-04-17 also carried a
#         data_decriptors.csv), Stallings, Emory, Peake, Schram, Wall & Williams. Licence as shown
#         on the record: Creative Commons Attribution 4.0 International (CC BY 4.0); the abstract
#         adds "the data are free to use, are not copyright restricted, and we ask users to cite
#         this data paper".
# Paper:  Stallings, C. D., Emory, M. E., Peake, J. A., Schram, M. J., Wall, K. R. & Williams, I.
#         (2025). Ten years (2013-2023) of fish assemblage data collected seasonally with diver
#         surveys on artificial and natural reefs. Ecology 106(5), e70108, doi:10.1002/ecy.70108
#         (data paper).
# Data:   habitat.csv: 14 reefs (reef_ID, name, Artificial / Natural, pair 1-4 for the eight
#           paired reefs, depth m, latitude / longitude to 3 decimals, deployment year of the
#           artificial reefs, first survey year: 2013 for the paired eight, 2020 for six unpaired
#           artificial reefs).
#         surveys.csv: 1,349 rows, one per 10-minute stationary diver count (sample_ID), nested
#           in 388 survey events (survey_ID = reef x season x year); sample_unit 1-6 numbers the
#           counts of an event (mostly 4, some 2-3; four events have 6, two have 1); date
#           (m/d/yyyy), season (calendar quarter Winter = Jan-Mar ... Fall = Oct-Dec; 8 winter counts
#           fall on 1-2 April and 29 summer counts in late June, so the field season, not the date,
#           sets the quarter), visibility m (the cylinder radius, <= 7.5 m), observer code,
#           start / stop clock times (several implausible, e.g. 1:00-5:00, 12:00-22:00),
#           bottom temperature. Two events (AC5_SP16, CWR_SP16) span two dates.
#         fishes.csv: 30,734 rows, one per fish or school recorded on a count: species_code,
#           number, individual length or school mean / min / max length. A species can have
#           several rows on one count (size classes). One row (AC5_FA16_1, ARPR) has no number
#           and no length beside a real ARPR row on the same count: an empty duplicate, dropped.
#         taxa.csv: 171 codes with scientific and common name, genus, family, order, class,
#           length-weight coefficients a, b, maximum length, trophic position and four shape
#           traits. 17 further codes occur in fishes.csv but are not in taxa.csv (LARV larval
#           fish, BAIT bait fish, UNKN unknown, and 14 family / genus codes such as GOFM, HOSP,
#           LAFM): 183 rows in total; they cannot be resolved from the deposit and are not
#           shipped (they are unidentified or undefined taxa, so no other taxon's zeros
#           change).
#         The descriptors note: "within-survey sample units should not be treated as independent
#         data" (the counts of an event are made by two divers, often side by side, at the same
#         reef within minutes).
#
# Mapping (standard E1-E5, community repeated counts / N-mixture):
#   unit = reef_ID (14), taxon = the deposit's 4-letter species_code (171), period = calendar
#   quarter index 1..41 (Spring 2013 = 1 ... Spring 2023 = 41; year and season in __periods),
#   occasion = sample_unit within the event (1-6), y = fish of that taxon counted on the
#   10-minute count = sum of `number` over its rows (0 for every one of the 171 taxa on every
#   count: divers record all fishes, so the community rule applies; the six reefs first
#   surveyed in 2020 simply have no rows before then). date = the count's date; observer =
#   diver code; obs_visibility_m (survey cylinder radius), obs_temperature_c. unit_ covariates:
#   reef type, pair (NA for unpaired reefs), depth, deployment year, coordinates.
#   cluster_id = reef pair ("pair1".."pair4"; the six unpaired reefs are their own cluster).
#   surveyEvidence = sample_table: surveys.csv lists every count, and every fishes.csv row
#   belongs to a listed count (asserted).
#   Coordinates: as published (3 decimals, about 100 m). The script looks up each taxon's IUCN
#   category through GBIF; flagged taxa (CR / EN / VU) trigger coarsening of all reef
#   coordinates, because a reef's location reveals where the flagged fish is. At build time 13
#   taxa are flagged (12 VU, sandbar shark EN; red snapper, gag, red grouper, goliath grouper,
#   gray triggerfish, hogfish, cubera snapper, vermilion snapper, four sharks and a stingray), so
#   the 14 reefs are generalised to 0.1 degree cell centres (12 distinct cells), and (E7.4) the
#   reef names (unit_reef_name, e.g. "3 Mile Reef North") are not shipped in that table; reef
#   ids are codes. unit_depth_m (8-30 m) is a depth, not an elevation, and is kept. E7.3:
#   stallings_2025_gulfreefs_exact_count has every unflagged taxon at the published reef
#   coordinates, with the reef names.
#   v1.1: closure = dependent (side-by-side divers; the authors say the counts of an event are not
#   independent; closureNote), occasionKind = time, taxonInclusion = recorded (every taxon of
#   taxa.csv is counted at least once). Genus / family / suborder codes carry taxonRemarks (E6).
#   Not shipped: individual and school lengths (biomass can be rebuilt from the deposit with
#   the taxa.csv coefficients); start / stop times (several are clearly mistyped, and every
#   count is 10 minutes); the 17 unresolved codes.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "stallings_2025_gulfreefs_count"
BASE <- "https://zenodo.org/api/records/14338634/files/%s/content"
f <- sapply(c("habitat.csv", "surveys.csv", "fishes.csv", "taxa.csv"), function(x) download_cached(sprintf(BASE, x), TABLE, x))
hab <- fread(f[["habitat.csv"]]); sv <- fread(f[["surveys.csv"]]); fi <- fread(f[["fishes.csv"]], encoding = "UTF-8")
tx <- fread(f[["taxa.csv"]], encoding = "UTF-8")
setnames(fi, 1, "survey_ID"); setnames(tx, 1, "species_code")         # strip the UTF-8 byte-order mark
stopifnot(nrow(hab) == 14, !anyDuplicated(hab$reef_ID), sum(!is.na(hab$pair)) == 8,
          all(table(hab$pair) == 2), hab[!is.na(pair), uniqueN(type), by = pair][, all(V1 == 2)],
          nrow(sv) == 1349, !anyDuplicated(sv$sample_ID), uniqueN(sv$survey_ID) == 388, all(sv$reef_ID %in% hab$reef_ID),
          !anyDuplicated(sv[, .(survey_ID, sample_unit)]), all(sv$sample_unit %in% 1:6),
          nrow(fi) == 30734, all(fi$sample_ID %in% sv$sample_ID), all(sv$sample_ID %in% fi$sample_ID),
          nrow(tx) == 171, !anyDuplicated(tx$species_code))
sv[, d := as.IDate(date, "%m/%d/%Y")]; stopifnot(!anyNA(sv$d), all(year(sv$d) == sv$year))
qtr <- c(Winter = 1L, Spring = 2L, Summer = 3L, Fall = 4L)
win <- list(Winter = 2:4, Spring = 4:6, Summer = 6:9, Fall = 10:12)     # field seasons spill a few weeks past the quarter
stopifnot(all(sv$season %in% names(qtr)), all(mapply(function(s, m) m %in% win[[s]], sv$season, month(sv$d))),
          sum(sv$season == "Winter" & month(sv$d) == 4L) == 8, sum(sv$season == "Summer" & month(sv$d) == 6L) == 29,
          all(sv$survey_ID == sprintf("%s_%s%02d", sv$reef_ID, toupper(substr(sv$season, 1, 2)), sv$year %% 100)))
sv[, period := (year - 2013L) * 4L + qtr[season] - 1L]; stopifnot(min(sv$period) == 1L, max(sv$period) == 41L)

# fish rows: one empty duplicate; codes outside taxa.csv
stopifnot(sum(is.na(fi$number)) == 1, fi[is.na(number), sample_ID == "AC5_FA16_1" & species_code == "ARPR" & is.na(size) & is.na(school_mean_size)],
          fi[sample_ID == "AC5_FA16_1" & species_code == "ARPR" & !is.na(number), .N] == 1, all(fi$number >= 1, na.rm = TRUE))
fi <- fi[!is.na(number)]
unres <- fi[!species_code %in% tx$species_code, .(rows = .N, fish = sum(number)), by = species_code]
stopifnot(nrow(unres) == 17, sum(unres$rows) == 183, all(c("LARV", "BAIT", "UNKN") %in% unres$species_code))
cat(sprintf("  not shipped: %d rows (%d fish) of %d codes absent from taxa.csv\n", sum(unres$rows), sum(unres$fish), nrow(unres)))
fi <- fi[species_code %in% tx$species_code]
stopifnot(setequal(fi$species_code, tx$species_code))                 # every listed taxon is observed at least once
counts <- fi[, .(y = sum(number)), by = .(sample_ID, taxon = species_code)]

# taxa: rank from the name; GBIF lookups on the first word for genus / family / suborder codes
tx[, rank := fifelse(grepl(" spp?\\.$", species_name), "genus",
              fifelse(!grepl(" ", species_name), fifelse(grepl("idae$", species_name), "family", "suborder"), "species"))]
stopifnot(tx[rank == "genus", .N] == 11, tx[rank == "family", .N] == 3, tx[rank == "suborder", .N] == 1)
tx[, lookup := fifelse(rank == "genus", sub(" .*$", "", species_name), species_name)]
# "Calamus" is a homonym (palm, grasshopper, porgy) that the strict match refuses: name the porgy genus's authority
stopifnot(tx[species_code == "CASP", lookup == "Calamus"])
tx[species_code == "CASP", lookup := "Calamus Swainson, 1839"]
# Prionotus too (v1.0 matched it to the kingdom Animalia); two source spellings with the other gender ending
stopifnot(tx[species_code == "PRSP", lookup == "Prionotus"], tx[species_code == "CHEN", species_name == "Chromis enchrysurus"],
          tx[species_code == "STHI", species_name == "Stephanolepis hispida"])
tx[species_code == "PRSP", lookup := "Prionotus Lacepède, 1801"]
tx[species_code == "CHEN", lookup := "Chromis enchrysura"]
tx[species_code == "STHI", lookup := "Stephanolepis hispidus"]
tx[, remarks := fifelse(rank == "species", NA_character_, sprintf("Recorded only to %s by the source (code %s)", rank, species_code))]
taxa <- make_taxa(tx$species_code, tx$species_name, vernacularName = tx$common, taxonRank = tx$rank, lookupName = tx$lookup,
                  taxonRemarks = tx$remarks,
                  taxon_family = tx$family, taxon_order = tx$order, taxon_lw_coef_a = tx$coef_a, taxon_lw_coef_b = tx$coef_b,
                  taxon_max_length_cm = tx$max_length, taxon_trophic_position = tx$trophic_position,
                  taxon_lateral_profile = tx$lateral_profile, taxon_cross_section = tx$cross_section,
                  taxon_mouth_position = tx$mouth_position, taxon_caudal_aspect_ratio = tx$aspect_ratio)

stopifnot(taxa[taxon == "CASP", taxonID == "https://www.gbif.org/species/2392568"])
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
taxa[taxonRank != "species", taxon_iucnCategory := NA_character_]
# NA where GBIF's IUCN record carries the source's own binomial as a synonym of the backbone name:
# the record is the source's species, so its code is used (asserted: no species stays NA)
same_name <- function(id, nm) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- strsplit(r$scientificName %||% "", " ")[[1]]
  if (identical(paste(head(w, 2), collapse = " "), nm)) r$code %||% NA_character_ else NA_character_
}
taxa[taxonRank == "species" & is.na(taxon_iucnCategory), taxon_iucnCategory := mapply(same_name, taxonID, scientificName)]
print(taxa[taxonRank == "species" & is.na(taxon_iucnCategory), .(taxon, scientificName)])
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
cat(sprintf("  IUCN flagged taxa (CR/EN/VU): %s\n", if (nrow(flagged)) paste(sprintf("%s %s (%s)", flagged$taxon, flagged$scientificName, flagged$taxon_iucnCategory), collapse = "; ") else "none"))

# reefs; coordinates coarsened when any flagged taxon occurs (all occur on these reefs)
hab[, cluster := fifelse(is.na(pair), paste0("unpaired_", reef_ID), paste0("pair", pair))]
stopifnot(nrow(flagged) >= 1)
units_exact <- hab[, .(unit = reef_ID, unit_reef_name = reef_name, unit_reef_type = tolower(type), unit_pair = pair,
                       unit_depth_m = depth, unit_deployment_year = deployment, unit_first_survey_year = first_year,
                       unit_decimalLatitude = latitude, unit_decimalLongitude = longitude)]
if (nrow(flagged)) {
  cc <- coarsen_coords(hab$latitude, hab$longitude)
  hab[, `:=`(lat = cc$lat, lon = cc$lon, unc = cc$uncertainty_m)]
  coarse <- list(value = TRUE, method = sprintf("Reef coordinates (3 decimals in the deposit) generalised to the 0.1 degree cell centre with coarsen_coords(), uncertainty = cell half-diagonal; flagged taxa (IUCN via GBIF): %s%s",
                                                 paste(sprintf("%s (%s)", flagged$scientificName, flagged$taxon_iucnCategory), collapse = ", "), "; reef names not shipped (E7.4)"))
} else {
  hab[, `:=`(lat = latitude, lon = longitude, unc = NA_real_)]
  coarse <- list(value = FALSE, method = "As published (3 decimals); no taxon is IUCN CR, EN or VU and the source flags none")
}
units <- hab[, .(unit = reef_ID, unit_reef_type = tolower(type), unit_pair = pair,
                 unit_depth_m = depth, unit_deployment_year = deployment, unit_first_survey_year = first_year,
                 unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = unc)]

surveys <- sv[, .(sample_ID, unit = reef_ID, period, occasion = sample_unit, date = format(d), observer,
                  obs_visibility_m = visibility, obs_temperature_c = temperature)]
surveys[, cluster_id := hab$cluster[match(unit, hab$reef_ID)]]
long <- surveys[rep(seq_len(.N), each = nrow(tx))][, taxon := rep(tx$species_code, times = nrow(surveys))]
long <- merge(long, counts, by = c("sample_ID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, sample_ID := NULL]
stopifnot(nrow(long) == 1349 * 171, sum(long$y) == sum(fi$number), uniqueN(long$unit) == 14)
long <- order_eco(long)

per <- unique(sv[, .(period, year, season)])[order(period)]
periods <- per[, .(period, period_year = year, period_season = tolower(season),
                   period_n_reefs = sv[, uniqueN(reef_ID), by = period][match(per$period, period), V1])]
stopifnot(nrow(periods) == 41, !anyDuplicated(periods$period))

emit <- function(TABLE, lg, tx2, un, exact) {
  dataset <- list(
    title = sprintf("Diver visual census counts of %d reef fish taxa on 14 artificial and natural reefs, eastern Gulf of Mexico, quarterly 2013-2023%s", nrow(tx2), if (exact) " (without IUCN-threatened taxa, coordinates as published)" else ""),
    creator = "Stallings, Christopher D.; Emory, Meaghan E.; Peake, Jonathan A.; Schram, Michael J.; Wall, Kara R.; Williams, Ian",
    pubDate = "2024-12-09", sourceURL = "https://doi.org/10.5281/zenodo.14338634",
    citation = "Stallings, C. D., Emory, M. E., Peake, J. A., Schram, M. J., Wall, K. R. & Williams, I. (2025). Ten years (2013-2023) of fish assemblage data collected seasonally with diver surveys on artificial and natural reefs. Ecology 106(5), e70108. https://doi.org/10.1002/ecy.70108. Data: Zenodo https://doi.org/10.5281/zenodo.14338634 (CC BY 4.0).",
    paperDOI = "10.1002/ecy.70108", dataDOI = "10.5281/zenodo.14338634",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = paste0("Stationary-point underwater visual census of reef fish on eight paired artificial and natural reefs (2013-2023) and six further artificial reefs (2020-2023) off west-central Florida. Each calendar quarter two divers made two to four 10-minute counts of every fish seen in a cylinder of up to 7.5 m radius (visibility-limited); 1,349 counts, 544,736 fish, 171 resolved taxa.", if (exact) sprintf(" This table omits the %d IUCN CR/EN/VU taxa so that reef coordinates and names ship as published; stallings_2025_gulfreefs_count has all 171 with coarsened coordinates.", nrow(flagged)) else ""),
    samplingProtocol = "Stationary-point visual census by SCUBA divers: 10-minute counts of all fishes within an imaginary cylinder of radius up to 7.5 m (horizontal visibility) from the seafloor to the surface; two to four counts per reef per calendar quarter, usually two divers each making two counts; lengths estimated per fish or per school.",
    samplingProtocolCode = "visual_census", occasionLength = "10 minutes", surveyEvidence = "sample_table",
    surveyEvidenceNote = "surveys.csv lists all 1,349 counts; every fishes.csv row belongs to a listed count, so a taxon absent from a count's rows is a zero. The 17 codes missing from taxa.csv (larvae, bait fish, unknowns, unresolved family / genus codes; 183 rows) are dropped as taxa, not as surveys.",
    responseType = "count", unitKind = "site",
    closure = "dependent", occasionKind = "time", taxonInclusion = "recorded",
    closureNote = "occasion within period (the two to four counts of one reef in one quarter, made within minutes or a few days by side-by-side divers; the authors warn that within-survey sample units are not independent); open between quarters",
    geographicCoverage = list(description = "Artificial and natural reefs 8-30 m deep off Pinellas and Manatee counties, west-central Florida, eastern Gulf of Mexico, USA",
                              boundingBox = list(west = min(un$unit_decimalLongitude), east = max(un$unit_decimalLongitude), south = min(un$unit_decimalLatitude), north = max(un$unit_decimalLatitude))),
    temporalCoverage = sprintf("%s/%s", min(sv$d), max(sv$d)),
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("As published (3 decimals): the %d IUCN CR/EN/VU taxa are not in this table (E7.3)", nrow(flagged))) else coarse,
    notShipped = c(if (exact) list(`IUCN CR/EN/VU taxa` = sprintf("%s: in stallings_2025_gulfreefs_count only, whose coordinates are coarsened", paste(flagged$taxon, collapse = ", "))) else
                     list(unit_reef_name = "reef place names (E7.4); in stallings_2025_gulfreefs_exact_count"), list(`fishes.csv size, school_mean_size, school_min_size, school_max_size` = "individual and school length estimates (biomass is rebuildable from the deposit with taxa.csv's length-weight coefficients)",
                      `surveys.csv time_start, time_stop` = "clock times, several clearly mistyped; every count is 10 minutes",
                      `17 species codes absent from taxa.csv` = sprintf("%s: %d rows, %d fish (larval fish, bait fish, unknowns, and family / genus codes the deposit does not define)",
                                                                         paste(unres$species_code, collapse = ", "), sum(unres$rows), sum(unres$fish)),
                      `AC5_FA16_1 ARPR second row` = "no number and no length beside a real row: an empty duplicate")))
  ds <- write_table(lg, TABLE, dataset, taxa = tx2, periods = periods, units = un, script = "data/stallings_2025_gulfreefs_count.R")

  stage_dict_row(TABLE,
    description = sprintf("Ten years of quarterly diver visual-census counts of %d reef fish taxa%s on 14 reefs (eight paired artificial / natural reefs from 2013, six artificial reefs from 2020) in the eastern Gulf of Mexico: 1,349 ten-minute counts, 2-4 per reef per quarter, with visibility, temperature, observer, reef type, depth and traits per taxon.", nrow(tx2), if (exact) " (IUCN-threatened taxa omitted; coordinates as published)" else ""),
    url = "https://doi.org/10.5281/zenodo.14338634",
    reference = "Stallings, C. D., Emory, M. E., Peake, J. A., Schram, M. J., Wall, K. R. & Williams, I. (2025). Ten years (2013-2023) of fish assemblage data collected seasonally with diver surveys on artificial and natural reefs. Ecology 106(5), e70108.",
    doi_paper = "10.1002/ecy.70108", doi_data = "10.5281/zenodo.14338634", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0(if (exact) "E7.3 sibling of stallings_2025_gulfreefs_count without the IUCN CR/EN/VU taxa. " else "", "Zeros from the count list (surveys.csv). 17 codes absent from taxa.csv (183 rows, incl. larvae and bait schools) not shipped. Lengths not shipped. Within-quarter counts are side-by-side divers; the authors warn they are not independent."),
    source_via = "Zenodo")
  stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (community counts, multi-season)",
    sampling_protocol = "visual_census", design = "Multi-season (41 quarters x 2-4 counts); paired artificial / natural reefs",
    realm = "Marine", country = "USA", coordinates = if (!exact && isTRUE(coarse$value)) "Coarsened (0.1 deg)" else "As published",
    notes = "Reef fish UVC; fish traits and length-weight coefficients in __taxa; reef pair as cluster_id.", status = "tagged")
}
emit(TABLE, long, taxa, units, exact = FALSE)
emit("stallings_2025_gulfreefs_exact_count", long[!taxon %in% flagged$taxon], taxa[!taxon %in% flagged$taxon], units_exact, exact = TRUE)
