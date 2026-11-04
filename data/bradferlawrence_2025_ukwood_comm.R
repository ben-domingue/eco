#!/usr/bin/env Rscript
# Tables: bradferlawrence_2025_ukwood_beetle_comm, bradferlawrence_2025_ukwood_bird_comm,
#         bradferlawrence_2025_ukwood_mammal_comm, bradferlawrence_2025_ukwood_plant_comm
#         (one script, four tables: one per taxon group, because the groups were surveyed by
#         different methods at different subsets of sites and years).
# Source: Zenodo doi:10.5281/zenodo.14946190 (version 1, 2025-02-28), Bradfer-Lawrence, Dobson,
#         Finch et al. Licence as shown on the record: Creative Commons Attribution 4.0
#         International (cc-by-4.0).
# Paper:  Bradfer-Lawrence, T., et al. "Spillovers and legacies of land management on temperate
#         woodland biodiversity" (manuscript NATECOLEVOL-24030739; Nature Ecology & Evolution).
#         Bayesian hierarchical (spOccupancy) occupancy models for 373 species in 134 woodlands
#         (10 to > 250 years old) in agricultural landscapes in England and Scotland.
# Data:   Data_for_NATECOLEVOL-24030739.xlsx, eight sheets:
#           Predictors (134 sites: Country, Age_years, Site_area_ha, Shape_Index,
#             Structure_Sd_tree_DBH (field-measured), and six 3-km landscape proportions /
#             densities from maps);
#           Coordinates (134 sites, X / Y in metres: British National Grid, EPSG:27700);
#           Beetles (34,500 rows = 60 sites x 5 pitfall collections x 115 taxa; Site_ID, Year
#             2013 / 2014 (each site in one year), Date (Excel serial), Collection_no 1-5,
#             No_of_traps_at_site 6-15, Species, Species_occ 0 / 1 / NA);
#           Birds (20,250 rows = 125 sites x 3 surveys x 54 species; Year 2015 / 2017, Date,
#             Survey_no, Surveyor 1-3, Species, Species_occ);
#           Mammals (1,600 rows = 100 sites x 4 trap days x 4 species; Year 2013 / 2014, Date,
#             Trap_day, Species, Species_occ; no NA);
#           Plants (25,800 rows = 129 sites x 200 species; Site_ID, Species, Species_occ; one
#             survey per site, no date, no NA);
#           Unused_predictors and Landscape_composition (136 rows; see notShipped).
#         Code_for_NATECOLEVOL-24030739B.R: the authors' model code (read, not run). It reads
#         the sheets with na = "NA" and then sets every NA Species_occ to 0 for beetles
#         (BEETLE.ARRAY$Species_occ[is.na(...)] <- 0) before fitting.
#         Beetle NA pattern (asserted): one whole collection is NA (site 10, 2014, collection 5,
#         the only collection without a date: lost); in every other collection the NA taxa are
#         a fixed set per year (34 taxa in 2013, 16 in 2014), and that set is exactly the taxa
#         with no detection anywhere in that year: every taxon scored in a year is detected at
#         least once that year, and every NA taxon is detected in the other year. So a
#         species-year NA is a zero the source left blank because the taxon was absent from the
#         year's catch, and the authors' code treats it as 0.
#         Bird NA pattern (asserted): 47 whole surveys are NA in Species_occ, Date and Surveyor
#         alike (not carried out); no other NA.
#
# Mapping (E1-E5, community occupancy):
#   unit = woodland Site_ID (as "W001"), taxon = a code from the source name (GENSPE, longer
#   where two collide; subfamilies keep their name: Aleocharinae, Omaliinae and Tachyporinae are
#   not in the GBIF backbone at subfamily rank, so their taxonID is NA), y = Species_occ (0 / 1).
#   beetles: occasion = pitfall collection 1-5 (fortnightly), date = collection date,
#     obs_n_traps = No_of_traps_at_site; the lost collection has no rows; species-year NA ->
#     y = 0 with y_raw = "NA" (every other row's y_raw is the recorded value).
#     surveyEvidence = deposited_matrix.
#   birds: occasion = Survey_no 1-3, date, observer = Surveyor; the 47 NA surveys have no rows.
#     surveyEvidence = deposited_matrix.
#   mammals: occasion = Trap_day 1-4, date. surveyEvidence = deposited_matrix (complete).
#   plants: one survey per site, no occasion (n_occasions = 1; admitted as a single-visit
#     matrix with that fact filterable). surveyEvidence = deposited_matrix.
#   unit_ covariates (all tables): survey year (beetles, birds, mammals), country, age, area,
#   shape, structure, the six landscape predictors, and unit_x / unit_y in EPSG:27700 (crs).
#   No period: every site is surveyed in one year only.
#   Coordinates: as deposited (1 m BNG) unless a taxon in the table is flagged (IUCN CR / EN /
#   VU via GBIF, checked by hand for synonym mismatches): a flagged table gets 10 km BNG grid
#   square centres instead (the projected analogue of 0.1 degree; stated in
#   coordinatesCoarsened).
#   Not shipped: Unused_predictors (road density, urban proportion, cropland ratio and
#   livestock density at five dates: the authors' discarded predictors, kept in the deposit) and
#   Landscape_composition (woodland and arable proportions at five radii); the model code.
#   v1.1: beetle, bird, mammal tables closure = closed, occasionKind = time; plant table closure
#   = none, occasionKind = none; taxonInclusion = recorded for all four (every taxon detected).
#   Four tables stay four (four methods, ruling #31). Taxa via make_taxa(exact = TRUE): the three
#   staphylinid subfamilies are no_key with taxonRemarks; Poa pratensis s.l., Rosa canina agg.
#   and the Pterostichus nigrita / rhaeticus record are taxonRank speciesAggregate with
#   taxonRemarks; Lesteva sicula heeri is a subspecies; Taraxacum is looked up as "Taraxacum
#   Weber" (the bare name matches the family). IUCN categories through iucn_category().
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
SCRIPT <- "data/bradferlawrence_2025_ukwood_comm.R"
T_BEE <- "bradferlawrence_2025_ukwood_beetle_comm"; T_BIR <- "bradferlawrence_2025_ukwood_bird_comm"
T_MAM <- "bradferlawrence_2025_ukwood_mammal_comm"; T_PLA <- "bradferlawrence_2025_ukwood_plant_comm"
f <- download_cached("https://zenodo.org/api/records/14946190/files/Data_for_NATECOLEVOL-24030739.xlsx/content", T_BEE, "Data_for_NATECOLEVOL-24030739.xlsx")
fc <- download_cached("https://zenodo.org/api/records/14946190/files/Code_for_NATECOLEVOL-24030739B.R/content", T_BEE, "Code_for_NATECOLEVOL-24030739B.R")
stopifnot(identical(excel_sheets(f), c("Predictors", "Coordinates", "Beetles", "Birds", "Mammals", "Plants", "Unused_predictors", "Landscape_composition")))
code <- readLines(fc, warn = FALSE)
stopifnot(any(grepl("BEETLE.ARRAY$Species_occ[is.na(BEETLE.ARRAY$Species_occ)] <- 0", code, fixed = TRUE)))
rd <- function(s) as.data.table(read_excel(f, s, col_types = "text"))
pred <- as.data.table(read_excel(f, "Predictors")); coo <- as.data.table(read_excel(f, "Coordinates"))
bee <- rd("Beetles"); bir <- rd("Birds"); mam <- rd("Mammals"); pla <- rd("Plants")
stopifnot(nrow(pred) == 134, nrow(coo) == 134, setequal(pred$Site_ID, 1:134), setequal(coo$Site_ID, 1:134),
          all(coo$X > 2e5 & coo$X < 6e5), all(coo$Y > 2e5 & coo$Y < 8e5),
          nrow(bee) == 34500, nrow(bir) == 20250, nrow(mam) == 1600, nrow(pla) == 25800,
          all(bee$Species_occ %in% c("0", "1", "NA")), all(bir$Species_occ %in% c("0", "1", "NA")),
          all(mam$Species_occ %in% c("0", "1")), all(pla$Species_occ %in% c("0", "1")))
xl_date <- function(x) as.IDate(as.integer(x), origin = "1899-12-30")
site_code <- function(id) sprintf("W%03d", as.integer(id))

## taxa -----------------------------------------------------------------------
fix_lookup <- c("Tachnius rufipes" = "Tachinus rufipes", "Pterostichus nigrata" = "Pterostichus nigrita",
                "Pterostichus nigrata rhaeticus" = "Pterostichus nigrita",
                # homonyms and names the strict match refuses without an authority
                "Chloris chloris" = "Chloris chloris (Linnaeus, 1758)", "Blechnum spicant" = "Blechnum spicant (L.) Roth",
                "Festuca pratensis" = "Festuca pratensis Huds.", "Senecio erucifolius" = "Senecio erucifolius L.",
                "Angelica officinalis" = "Angelica archangelica",   # A. officinalis Moench is a name for A. archangelica
                "Taraxacum" = "Taraxacum Weber",                    # the bare name matches the family Asteraceae
                "Poa pratensis sens lat" = "Poa pratensis", "Rosa canina agg" = "Rosa canina")
# taxonRemarks (E6): aggregates, the subfamilies the backbone does not hold, the unseparated pair
remarks <- c("Aleocharinae" = "subfamily (Staphylinidae) recorded as one taxon by the source; the GBIF backbone holds no Aleocharinae at subfamily rank, so taxonID is empty",
             "Omaliinae" = "subfamily (Staphylinidae) recorded as one taxon by the source; the GBIF backbone holds no Omaliinae at subfamily rank, so taxonID is empty",
             "Tachyporinae" = "subfamily (Staphylinidae) recorded as one taxon by the source; the GBIF backbone holds no Tachyporinae at subfamily rank, so taxonID is empty",
             "Pterostichus nigrata rhaeticus" = "recorded as 'Pterostichus nigrata rhaeticus' beside 'Pterostichus nigrata': read as the P. nigrita / P. rhaeticus pair not separated (species aggregate); taxonID is P. nigrita",
             "Pterostichus nigrata" = "source spelling of P. nigrita; the source also records the unseparated nigrita / rhaeticus pair as its own taxon (PTENIGRHA)",
             "Poa pratensis sens lat " = "Poa pratensis sensu lato, recorded as an aggregate by the source; taxonID is P. pratensis",
             "Rosa canina agg " = "Rosa canina aggregate, recorded as such by the source; taxonID is R. canina",
             "Taraxacum" = "recorded at genus rank by the source")
taxa_of <- function(src) {
  sp <- data.table(src = sort(unique(src)))
  sp[, sci := gsub("\\.", " ", src)]
  sp[, rank := fifelse(!grepl(" ", sci), fifelse(grepl("inae$", sci), "subfamily", "genus"),
               fifelse(lengths(strsplit(sci, " ")) >= 3, "speciesAggregate", "species"))]
  sp[sci == "Lesteva sicula heeri", rank := "subspecies"]   # a subspecies name, matched EXACTLY by GBIF
  w <- strsplit(sp$sci, " ")
  code <- function(k) vapply(w, function(x) if (length(x) == 1) toupper(x) else toupper(paste(substr(x, 1, k), collapse = "")), "")
  sp[, taxon := code(3)]                                     # GENSPE (GENSPESUB for trinomials); subfamilies keep their name
  d <- sp[duplicated(taxon) | duplicated(taxon, fromLast = TRUE), taxon]
  i4 <- sp$taxon %in% d; c4 <- code(4); sp$taxon[i4] <- c4[i4]   # collisions: four letters per word
  d <- sp[duplicated(taxon) | duplicated(taxon, fromLast = TRUE), taxon]
  i5 <- sp$taxon %in% d; sp$taxon[i5] <- toupper(gsub("[^A-Za-z]", "", sp$sci[i5]))
  stopifnot(!anyDuplicated(sp$taxon), all(nchar(sp$taxon) <= 30))
  sp[, lookup := fifelse(trimws(sci) %in% names(fix_lookup), fix_lookup[trimws(sci)], sci)]
  sp[, rem := fifelse(sci %in% names(remarks), remarks[sci], fifelse(trimws(sci) %in% names(remarks), remarks[trimws(sci)], NA_character_))]
  stopifnot(all(!is.na(sp[rank %in% c("subfamily", "speciesAggregate", "genus"), rem])))
  tx <- make_taxa(sp$taxon, sp$sci, taxonRank = sp$rank, lookupName = sp$lookup, taxon_sourceName = sp$src,
                  taxonRemarks = sp$rem, no_key = sp[rank == "subfamily", taxon])
  stopifnot(tx[taxonRank == "subfamily", all(is.na(taxonID))], tx[taxonRank != "subfamily", !anyNA(taxonID)])
  tx[taxonRank %in% c("species", "speciesAggregate", "subspecies"), taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  # NA = the IUCN record's name differs from GBIF's accepted name; for these eight the record
  # carries the source's own name (same species), and its category is taken (checked 2026-11-03)
  same_sp <- c("Corvus monedula" = "LC", "Sylvia communis" = "LC", "Sylvia curruca" = "LC", "Myodes glareolus" = "LC",
               "Blechnum spicant" = "NE", "Festuca pratensis" = "NE", "Picris echioides" = "NE", "Senecio erucifolius" = "NE")
  tx[is.na(taxon_iucnCategory) & scientificName %in% names(same_sp), taxon_iucnCategory := same_sp[scientificName]]
  stopifnot(tx[taxonRank %in% c("species", "speciesAggregate", "subspecies"), !anyNA(taxon_iucnCategory)])
  list(sp = sp, tx = tx)
}

## site covariates --------------------------------------------------------------
units_all <- merge(pred, coo, by = "Site_ID")
units_all <- units_all[, .(Site_ID = as.character(Site_ID), unit = site_code(Site_ID), unit_country = Country, unit_age_years = Age_years,
                           unit_area_ha = Site_area_ha, unit_shape_index = Shape_Index, unit_structure_sd_dbh = Structure_Sd_tree_DBH,
                           unit_current_woodland_prop_3km = Current_Woodland_prop, unit_old_woodland_prop_3km = Old_Woodland_prop,
                           unit_lost_woodland_prop_3km = Lost_Woodland_prop, unit_trees_outside_woodland_prop_3km = Trees_Outside_Woodlands_prop,
                           unit_arable_prop_3km = Arable_prop, unit_livestock_density_3km = Livestock_density, X, Y)]
stopifnot(setequal(units_all$unit_country, c("England", "Scotland")))

coords_for <- function(tx) {
  fl <- tx[taxon_iucnCategory %in% c("CR", "EN", "VU")]
  u <- copy(units_all)
  if (nrow(fl)) {
    u[, `:=`(unit_x = floor(X / 1e4) * 1e4 + 5e3, unit_y = floor(Y / 1e4) * 1e4 + 5e3, unit_coordinateUncertaintyInMeters = round(5e3 * sqrt(2)))]
    cc <- list(value = TRUE, method = sprintf("British National Grid coordinates (1 m in the deposit) generalised to the centre of their 10 km grid square (the projected analogue of 0.1 degree), uncertainty = half-diagonal 7,071 m; flagged taxa (IUCN via GBIF): %s",
                                              paste(sprintf("%s (%s)", fl$scientificName, fl$taxon_iucnCategory), collapse = ", ")))
  } else {
    u[, `:=`(unit_x = X, unit_y = Y, unit_coordinateUncertaintyInMeters = NA_real_)]
    cc <- list(value = FALSE, method = "As deposited (British National Grid, EPSG:27700, metres); no taxon in this table is IUCN CR, EN or VU and the source flags none")
  }
  u[, c("X", "Y") := NULL]
  list(units = u, coarse = cc, flagged = fl)
}

common <- list(
  creator = "Bradfer-Lawrence, Tom; Dobson, Andrew; Finch, Tom; et al.",
  pubDate = "2025-02-28", sourceURL = "https://doi.org/10.5281/zenodo.14946190",
  citation = "Bradfer-Lawrence, T., Dobson, A., Finch, T., et al. (2025). Data and code for \"Spillovers and legacies of land management on temperate woodland biodiversity\". Zenodo, version 1. https://doi.org/10.5281/zenodo.14946190 (CC BY 4.0).",
  dataDOI = "10.5281/zenodo.14946190",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  responseType = "detection", unitKind = "site", crs = "EPSG:27700",
  geographicCoverage = list(description = "Woodland patches (10 to > 250 years old) in agricultural landscapes in England and Scotland, United Kingdom",
                            boundingBox = list(west = -4.9, east = 1.2, south = 52.4, north = 57.0)))
not_shipped_common <- list(
  Unused_predictors = "road density, urban proportion, cropland ratio and livestock density at five dates: predictors the authors did not use (kept in the deposit)",
  Landscape_composition = "woodland and arable proportions in five radii (1-3 km) around each site (kept in the deposit)",
  `Code_for_NATECOLEVOL-24030739B.R` = "the authors' spOccupancy model code")

stage_both <- function(table, ds, desc, notes, model_family, protocol, design, group) {
  stage_dict_row(table, description = desc, url = "https://doi.org/10.5281/zenodo.14946190",
    reference = "Bradfer-Lawrence, T., Dobson, A., Finch, T., et al. (2025). Data and code for \"Spillovers and legacies of land management on temperate woodland biodiversity\". Zenodo.",
    doi_paper = "", doi_data = "10.5281/zenodo.14946190", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = notes, source_via = "Zenodo")
  stage_tag_row(table, ds, taxon_group = group, model_family = model_family, sampling_protocol = protocol, design = design,
    realm = "Terrestrial", country = "GBR", coordinates = if (isTRUE(ds$coordinatesCoarsened$value)) "Coarsened (by the processor: 10 km BNG grid squares)" else "As published (British National Grid, EPSG:27700)",
    notes = notes, status = "tagged")
}

## beetles --------------------------------------------------------------------
stopifnot(bee[, uniqueN(Year), by = Site_ID][, all(V1 == 1)], uniqueN(bee$Site_ID) == 60,
          bee[, .N, by = .(Site_ID, Collection_no)][, all(N == 115)], setequal(bee$Collection_no, as.character(1:5)))
ev <- bee[, .(nNA = sum(Species_occ == "NA"), dateNA = all(is.na(Date) | Date == "NA")), by = .(Site_ID, Year, Collection_no)]
lost <- ev[nNA == 115]
stopifnot(nrow(lost) == 1, lost$Site_ID == "10", lost$Year == "2014", lost$Collection_no == "5", lost$dateNA,
          ev[nNA < 115, !any(dateNA)], ev[nNA < 115 & Year == "2013", all(nNA == 34)], ev[nNA < 115 & Year == "2014", all(nNA == 16)])
b2 <- bee[!(Site_ID == "10" & Year == "2014" & Collection_no == "5")]
na_set <- b2[Species_occ == "NA", .(set = list(sort(unique(Species)))), by = Year]
scored <- b2[Species_occ != "NA", .(det = sum(Species_occ == "1")), by = .(Year, Species)]
stopifnot(scored[, all(det > 0)],                                              # every scored taxon is detected that year
          b2[Species_occ == "NA", .N, by = .(Year, Species)][, uniqueN(N), by = Year][, all(V1 == 1)],   # NA in every collection of that year
          length(intersect(na_set$set[[1]], na_set$set[[2]])) == 0)
for (y in c("2013", "2014")) {                                                    # NA taxa of a year are detected in the other year
  oth <- setdiff(c("2013", "2014"), y)
  stopifnot(all(na_set[Year == y, set[[1]]] %in% b2[Year == oth & Species_occ == "1", unique(Species)]))
}
tb <- taxa_of(bee$Species); stopifnot(nrow(tb$tx) == 115)
cb <- coords_for(tb$tx)
long_b <- b2[, .(Site_ID, unit = site_code(Site_ID), taxon = tb$sp$taxon[match(Species, tb$sp$src)],
                 y = as.integer(fifelse(Species_occ == "NA", "0", Species_occ)), y_raw = Species_occ,
                 occasion = as.integer(Collection_no), date = format(xl_date(Date)), obs_n_traps = as.integer(No_of_traps_at_site),
                 unit_survey_year = as.integer(Year))]
long_b <- merge(long_b, cb$units, by = c("Site_ID", "unit"))[, Site_ID := NULL]
stopifnot(nrow(long_b) == 34500 - 115, !anyNA(long_b$date), sum(long_b$y_raw == "NA") == 199 * 16 + 100 * 34)
long_b <- order_eco(long_b)
ds_b <- write_table(long_b, T_BEE, c(common, list(
  title = "Pitfall-trap detections of 115 beetle taxa (carabids, staphylinids, weevils and others) in 60 UK farmland woodlands, five fortnightly collections, 2013-2014",
  abstract = "Presence / absence of 115 beetle taxa in five successive pitfall-trap collections at each of 60 woodland patches of known age in agricultural landscapes in England and Scotland (20 sites in 2013, 40 in 2014), from a study of spatial spillovers and temporal legacies of land use on woodland biodiversity.",
  samplingProtocol = "Pitfall traps (6-15 per site) emptied fortnightly; five collections per site in one summer; catches identified and scored as present / absent per taxon and collection.",
  samplingProtocolCode = "pitfall_trap", occasionLength = "about two weeks (one pitfall collection)", effortColumn = "obs_n_traps",
  closure = "closed", closureNote = "occasion within site (five fortnightly collections in one summer); each site is surveyed in one year only",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = sprintf("%s/%s", min(long_b$date), max(long_b$date)),
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The Beetles sheet is a full site x collection x taxon matrix. The one collection that is NA for every taxon and has no date (site 10, 2014, collection 5) was not obtained and has no rows. All other NA cells are a fixed taxon set per year (34 in 2013, 16 in 2014) that is exactly the taxa with no detection anywhere that year; they are shipped as y = 0 with y_raw = 'NA', as the authors' model code does.",
  coordinatesCoarsened = cb$coarse,
  notShipped = c(not_shipped_common, list(`site 10 collection 5 (2014)` = "lost collection: NA for every taxon, no date; not surveyed")))),
  taxa = tb$tx, script = SCRIPT)
stage_both(T_BEE, ds_b,
  desc = "Pitfall-trap presence / absence of 115 beetle taxa in five fortnightly collections at 60 farmland woodlands of known age (England and Scotland, 2013-2014), with trap numbers, woodland age, area, structure and landscape history.",
  notes = "Species-year NA cells (taxa never caught that year) shipped as 0 with y_raw = NA, as in the authors' code; one lost collection has no rows. Siblings: _bird_comm, _mammal_comm, _plant_comm.",
  model_family = "Community occupancy (single season)", protocol = "pitfall_trap", design = "Single-season (5 fortnightly pitfall collections)", group = "Invertebrates")

## birds ------------------------------------------------------------------------
stopifnot(bir[, uniqueN(Year), by = Site_ID][, all(V1 == 1)], uniqueN(bir$Site_ID) == 125, setequal(bir$Survey_no, as.character(1:3)),
          bir[, .N, by = .(Site_ID, Survey_no)][, all(N == 54)])
isna <- function(x) is.na(x) | x == "NA"           # the sheet stores missing dates and surveyors as text "NA"
evb <- bir[, .(nNA = sum(Species_occ == "NA"), dNA = sum(isna(Date)), sNA = sum(isna(Surveyor))), by = .(Site_ID, Survey_no)]
stopifnot(nrow(evb) == 375, evb[, all((nNA == 0 & dNA == 0 & sNA == 0) | (nNA == 54 & dNA == 54 & sNA == 54))], evb[nNA == 54, .N] == 47)
bi2 <- bir[Species_occ != "NA"]
tbi <- taxa_of(bir$Species); stopifnot(nrow(tbi$tx) == 54)
cbi <- coords_for(tbi$tx)
long_bi <- bi2[, .(Site_ID, unit = site_code(Site_ID), taxon = tbi$sp$taxon[match(Species, tbi$sp$src)], y = as.integer(Species_occ),
                   occasion = as.integer(Survey_no), date = format(xl_date(Date)), observer = paste0("surveyor_", Surveyor),
                   unit_survey_year = as.integer(Year))]
long_bi <- merge(long_bi, cbi$units, by = c("Site_ID", "unit"))[, Site_ID := NULL]
stopifnot(nrow(long_bi) == 328 * 54, all(year(as.IDate(long_bi$date)) == long_bi$unit_survey_year))
long_bi <- order_eco(long_bi)
ds_bi <- write_table(long_bi, T_BIR, c(common, list(
  title = "Bird detections (54 species) on three repeat surveys at 125 UK farmland woodlands, 2015 and 2017",
  abstract = "Presence / absence of 54 bird species on up to three repeat surveys at each of 125 woodland patches of known age in agricultural landscapes in England and Scotland (79 sites in 2015, 46 in 2017), from a study of spatial spillovers and temporal legacies of land use on woodland biodiversity.",
  samplingProtocol = "Repeat bird surveys of each woodland patch (three visits per site, surveyor recorded; the survey method is described in the paper, not the deposit); species scored present / absent per visit.",
  samplingProtocolCode = "bird_survey", occasionLength = "one survey visit",
  closure = "closed", closureNote = "occasion within site (three visits in one breeding season); each site is surveyed in one year only",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = sprintf("%s/%s", min(long_bi$date), max(long_bi$date)),
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The Birds sheet is a full site x survey x species matrix; 47 surveys are NA for every species and have no date or surveyor (not carried out) and have no rows. No other NA.",
  coordinatesCoarsened = cbi$coarse,
  notShipped = c(not_shipped_common, list(`47 NA surveys` = "visits not carried out (NA for every species, no date, no surveyor)")))),
  taxa = tbi$tx, script = SCRIPT)
stage_both(T_BIR, ds_bi,
  desc = "Bird presence / absence (54 species) on up to three repeat surveys at 125 farmland woodlands of known age in England and Scotland (2015, 2017), with surveyor, date, woodland age, area, structure and landscape history.",
  notes = "47 surveys not carried out have no rows. Siblings: _beetle_comm, _mammal_comm, _plant_comm.",
  model_family = "Community occupancy (single season)", protocol = "bird_survey", design = "Single-season (3 repeat surveys)", group = "Birds")

## mammals ----------------------------------------------------------------------
stopifnot(mam[, uniqueN(Year), by = Site_ID][, all(V1 == 1)], uniqueN(mam$Site_ID) == 100, setequal(mam$Trap_day, as.character(1:4)),
          mam[, .N, by = .(Site_ID, Trap_day)][, all(N == 4)], mam[, uniqueN(Date), by = .(Site_ID, Trap_day)][, all(V1 == 1)])
tm <- taxa_of(mam$Species); stopifnot(nrow(tm$tx) == 4)
cm <- coords_for(tm$tx)
long_m <- mam[, .(Site_ID, unit = site_code(Site_ID), taxon = tm$sp$taxon[match(Species, tm$sp$src)], y = as.integer(Species_occ),
                  occasion = as.integer(Trap_day), date = format(xl_date(Date)), unit_survey_year = as.integer(Year))]
long_m <- merge(long_m, cm$units, by = c("Site_ID", "unit"))[, Site_ID := NULL]
stopifnot(nrow(long_m) == 1600, !anyNA(long_m$date))
long_m <- order_eco(long_m)
ds_m <- write_table(long_m, T_MAM, c(common, list(
  title = "Live-trap detections of four small mammal species on four trap days at 100 UK farmland woodlands, 2013-2014",
  abstract = "Presence / absence of wood mouse, bank vole, field vole and common shrew on four successive live-trapping days at each of 100 woodland patches of known age in agricultural landscapes in England and Scotland, from a study of spatial spillovers and temporal legacies of land use on woodland biodiversity.",
  samplingProtocol = "Small-mammal live trapping over four consecutive trap days per site in one season; species scored present / absent per trap day (the deposit does not give trap numbers).",
  samplingProtocolCode = "live_trap", occasionLength = "one trap day",
  closure = "closed", closureNote = "occasion within site (four consecutive trap days); each site is surveyed in one year only",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = sprintf("%s/%s", min(long_m$date), max(long_m$date)),
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The Mammals sheet is a complete site x trap day x species matrix with no NA.",
  coordinatesCoarsened = cm$coarse, notShipped = not_shipped_common)),
  taxa = tm$tx, script = SCRIPT)
stage_both(T_MAM, ds_m,
  desc = "Small-mammal live-trap presence / absence (four species) on four trap days at 100 farmland woodlands of known age in England and Scotland (2013-2014), with woodland age, area, structure and landscape history.",
  notes = "Complete matrix. Siblings: _beetle_comm, _bird_comm, _plant_comm.",
  model_family = "Community occupancy (single season)", protocol = "live_trap", design = "Single-season (4 trap days)", group = "Mammals")

## plants -----------------------------------------------------------------------
stopifnot(uniqueN(pla$Site_ID) == 129, pla[, .N, by = Site_ID][, all(N == 200)], !anyDuplicated(pla[, .(Site_ID, Species)]))
tp <- taxa_of(pla$Species); stopifnot(nrow(tp$tx) == 200)
cp <- coords_for(tp$tx)
long_p <- pla[, .(Site_ID, unit = site_code(Site_ID), taxon = tp$sp$taxon[match(Species, tp$sp$src)], y = as.integer(Species_occ))]
long_p <- merge(long_p, cp$units, by = c("Site_ID", "unit"))[, Site_ID := NULL]
stopifnot(nrow(long_p) == 25800)
long_p <- order_eco(long_p)
ds_p <- write_table(long_p, T_PLA, c(common, list(
  title = "Vascular plant presence / absence (200 species) in one survey of each of 129 UK farmland woodlands",
  abstract = "Presence / absence of 200 vascular plant species recorded in a single survey of each of 129 woodland patches of known age in agricultural landscapes in England and Scotland, from a study of spatial spillovers and temporal legacies of land use on woodland biodiversity. One visit per site: detection is not estimable from this table alone.",
  samplingProtocol = "One botanical survey per woodland patch; species scored present / absent (survey year and date not in the deposit).",
  samplingProtocolCode = "botanical_survey", occasionLength = "one survey",
  closure = "none", closureNote = "single visit per site (no replication)",
  occasionKind = "none", taxonInclusion = "recorded",
  temporalCoverage = "2013/2017",
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The Plants sheet is a complete site x species matrix with no NA; one survey per site. The survey year is not deposited; temporalCoverage is the study's span (2013-2017).",
  coordinatesCoarsened = cp$coarse, notShipped = not_shipped_common)),
  taxa = tp$tx, script = SCRIPT)
stage_both(T_PLA, ds_p,
  desc = "Single-survey presence / absence of 200 vascular plant species at 129 farmland woodlands of known age in England and Scotland, with woodland age, area, structure and landscape history (no repeat visits).",
  notes = "Single visit per site (n_occasions = 1): detection not estimable from this table. Survey dates not deposited. Siblings: _beetle_comm, _bird_comm, _mammal_comm.",
  model_family = "Single-visit presence / absence (community)", protocol = "botanical_survey", design = "Single-season (one survey per site)", group = "Plants")
cat("flagged taxa:\n"); for (z in list(cb, cbi, cm, cp)) print(z$flagged[, .(taxon, scientificName, taxon_iucnCategory)])
