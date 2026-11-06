#!/usr/bin/env Rscript
# Table:  frishkoff_2014_costarica_birds_binom
# Source: Dryad doi:10.5061/dryad.fv921, version 24999, CC0 1.0 (Dryad licence field; the README
#         states none).
#   Frishkoff, L. O., Karp, D. S., M'Gonigle, L. K., Mendenhall, C. D., Zook, J., Kremen, C.,
#   Hadly, E. A. & Daily, G. C. (2014). Data from: Loss of avian phylogenetic diversity in
#   neotropical agricultural systems. Dryad.
# Paper:  Frishkoff et al. (2014). Loss of avian phylogenetic diversity in neotropical agricultural
#         systems. Science 345(6202), 1343-1346, doi:10.1126/science.1254610.
# Data:   1254610supplementdata.csv (40,764 rows): Transect (44 codes, <habitat letter>-<region>
#         <number>, e.g. F-GU1), LUI (Forest / Diversified / Intensive, constant within a transect),
#         Year (2001-2012), Season (dry / wet), Spp (scientific name; 491 names, four of them
#         "<Genus> sp."), "Number of surveys per season detection (out of 3)" (1-3). The README
#         (a Word .doc) says three surveys were conducted at each transect in each season of each
#         year, and every row is a species detected at least once in those three. Only detections
#         are deposited: there are no zero rows and no visit list.
#         Region codes GU, LC, PV, SI are four Costa Rican regions; transect prefixes F (forest),
#         H and L (agricultural transects; LUI gives Intensive / Diversified), I (agricultural).
#         No coordinates are deposited.
#         Quirk: Empidonax traillii has two rows in six transect-season cells (two source codes,
#         probably Willow and "Traill's" flycatcher, lumped onto one name); the detections of the
#         union cannot be recovered from two counts out of 3, so the taxon is not shipped.
#
# Mapping (E2 binomial_count, ruling #34): unit = Transect, cluster_id = region (GU / LC / PV / SI),
#   unit_landuse = LUI (lower case), taxon = a code made from the scientific name (Genus_epithet),
#   period = year x season in time order (2001 dry = 1, 2001 wet = 2, ..., 2012 wet = 24; the dry
#   season, January to April, precedes the wet season, May to November, within a calendar year),
#   y = surveys with a detection out of obs_trials = 3, no occasion column.
#   Survey evidence: row_presence. A transect x year x season was surveyed iff the file has at
#   least one detection row for it: three surveys of a bird transect in Costa Rica
#   always record birds, and the 8 absent cells (of 44 x 24 = 1,056) are all wet-season cells of
#   the three H-SI transects, a pattern of missed visits, not of empty surveys (asserted). Within
#   a surveyed cell, every species recorded anywhere in the study and not listed is y = 0
#   (taxonInclusion = recorded, community rule E4.2).
#   The four genus-only names (Amazilia sp., Contopus sp., Empidonax sp., Laterallus sp.) are
#   their own taxa at taxonRank genus (E6), code Genus_sp. Not shipped: Empidonax traillii
#   (see quirk). No other columns exist.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "frishkoff_2014_costarica_birds_binom"
dir <- download_dryad("10.5061/dryad.fv921", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("1254610supplementdata.csv", "README_for_1254610supplementdata.doc")))
x <- fread(file.path(dir, "1254610supplementdata.csv"))
stopifnot(identical(names(x), c("Transect", "LUI", "Year", "Season", "Spp", "Number of surveys per season detection (out of 3)")))
setnames(x, 6, "k")

# --- source facts ---------------------------------------------------------------------------
stopifnot(nrow(x) == 40764, !anyNA(x), all(x$k %in% 1:3), all(x$Year %in% 2001:2012),
          setequal(x$Season, c("dry", "wet")), setequal(x$LUI, c("Forest", "Diversified", "Intensive")))
stopifnot(uniqueN(x$Transect) == 44, all(grepl("^[FHIL]-(GU|LC|PV|SI)[1-3]$", x$Transect)))
stopifnot(x[, uniqueN(LUI), by = Transect][, all(V1 == 1)])                     # LUI is a transect fact
stopifnot(x[substr(Transect, 1, 1) == "F", all(LUI == "Forest")], x[substr(Transect, 1, 1) != "F", all(LUI != "Forest")])
stopifnot(uniqueN(x$Spp) == 491)
gen <- c("Amazilia sp.", "Contopus sp.", "Empidonax sp.", "Laterallus sp.")
stopifnot(setequal(grep(" sp\\.$", unique(x$Spp), value = TRUE), gen),
          all(grepl("^[A-Z][a-z]+ [a-z]+$", setdiff(unique(x$Spp), gen))))
dup <- x[, .N, by = .(Transect, Year, Season, Spp)][N > 1]
stopifnot(nrow(dup) == 6, all(dup$N == 2), all(dup$Spp == "Empidonax traillii"))

# --- survey set: transect x year x season with at least one detection row -------------------
cells <- unique(x[, .(Transect, LUI, Year, Season)])
stopifnot(nrow(cells) == 1048)
full <- CJ(Transect = unique(x$Transect), Year = 2001:2012, Season = c("dry", "wet"))
miss <- full[!cells, on = .(Transect, Year, Season)]
stopifnot(nrow(miss) == 8, all(miss$Season == "wet"), all(grepl("^H-SI", miss$Transect)))
cat(sprintf("  %d transects, %d of %d transect x season cells surveyed; absent: %s\n", uniqueN(x$Transect), nrow(cells), nrow(full),
            paste(miss[, paste0(Transect, " ", Year, " ", Season)], collapse = ", ")))
cells[, period := (Year - 2001L) * 2L + fifelse(Season == "dry", 1L, 2L)]

# --- detections and the zero fill ------------------------------------------------------------
drop <- "Empidonax traillii"
det <- x[!Spp %in% drop]
stopifnot(!anyDuplicated(det[, .(Transect, Year, Season, Spp)]))
species <- sort(unique(det$Spp)); stopifnot(length(species) == 490)
code <- sub("\\.$", "", sub(" ", "_", species)); stopifnot(!anyDuplicated(code))
det[, taxon := sub("\\.$", "", sub(" ", "_", Spp))]
det <- merge(det, cells[, .(Transect, Year, Season, period)], by = c("Transect", "Year", "Season"))

long <- cells[rep(seq_len(.N), each = length(code))][, taxon := rep(code, times = nrow(cells))]
long <- merge(long, det[, .(Transect, period, taxon, y = k)], by = c("Transect", "period", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- long[, .(unit = Transect, taxon, period, y = as.integer(y), obs_trials = 3L,
                 cluster_id = substr(Transect, 3, 4), unit_landuse = tolower(LUI))]
long <- order_eco(long)
stopifnot(nrow(long) == 1048 * 490, sum(long$y) == sum(det$k), sum(long$y > 0) == nrow(det),
          all(long$y <= long$obs_trials))

periods <- unique(cells[, .(period, period_year = Year, period_season = Season)])[order(period)]
periods[, period_n_transects := cells[, .N, by = period][match(periods$period, period), N]]
stopifnot(nrow(periods) == 24, identical(periods$period, 1:24))

# source misspellings / gender endings that GBIF's strict match only fuzzily matches
fix <- c("Amazilia saucerrottei" = "Amazilia saucerottei", "Ceryle torquatus" = "Ceryle torquata", "Leptotila cassini" = "Leptotila cassinii")
stopifnot(all(names(fix) %in% species))
look <- ifelse(species %in% names(fix), fix[species], species)
isgen <- species %in% gen
look[isgen] <- sub(" sp\\.$", "", species[isgen])
# Contopus is a homonym on the GBIF backbone: the strict match falls to the kingdom
# (gbif.org/species/1, Animalia; batch 39, #10). It is matched with the bird family
# as a hint and accepted only when GBIF returns the genus itself among animals.
hom <- code[species == "Contopus sp."]
taxa <- make_taxa(code, species, lookupName = look, taxonRank = ifelse(isgen, "genus", "species"),
                  taxonRemarks = ifelse(isgen, "Recorded only to genus by the source", NA_character_),
                  allow_higher = setdiff(code[isgen], hom), no_key = hom)
h <- gbif_taxon_hinted("Contopus", list(kingdom = "Animalia", class = "Aves", family = "Tyrannidae"))
stopifnot(identical(h$canonicalName, "Contopus"), identical(h$kingdom, "Animalia"), identical(h$rank, "genus"))
taxa[taxon == hom, `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"),
                        taxonRemarks = paste0(taxonRemarks, "; a homonym on the GBIF backbone, matched with family Tyrannidae as a hint"))]
stopifnot(!any(kingdom_taxonID(taxa$taxonID)))
stopifnot(nrow(taxa) == 490, taxa[taxonRank == "genus", .N] == 4)

dataset <- list(
  title = "Bird detections on 44 transects in forest, diversified and intensive farmland across four regions of Costa Rica, dry and wet seasons 2001-2012: surveys with a detection out of three (binomial counts)",
  creator = "Frishkoff, Luke O.; Karp, Daniel S.; M'Gonigle, Leithen K.; Mendenhall, Chase D.; Zook, Jim; Kremen, Claire; Hadly, Elizabeth A.; Daily, Gretchen C.",
  pubDate = "2014", doi = "10.5061/dryad.fv921", sourceURL = "https://doi.org/10.5061/dryad.fv921",
  citation = "Frishkoff, L. O., Karp, D. S., M'Gonigle, L. K., Mendenhall, C. D., Zook, J., Kremen, C., Hadly, E. A., & Daily, G. C. (2014). Data from: Loss of avian phylogenetic diversity in neotropical agricultural systems [Data set]. Dryad. https://doi.org/10.5061/dryad.fv921",
  paperDOI = "10.1126/science.1254610",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Twelve years of bird surveys behind Frishkoff et al. (2014, Science): 44 transects in forest reserves, diversified agriculture and intensive monoculture in four regions of Costa Rica, each surveyed three times in the dry season and three times in the wet season of every year 2001-2012. The deposit gives, for each transect, year, season and detected species, the number of the three surveys on which the species was detected. The table is one row per transect x season x species with y = surveys with a detection and obs_trials = 3 (binomial_count, ruling #34); species not listed for a surveyed transect-season are explicit zeros. These are the long-term surveys later analysed by Hendershot et al. (2020, Nature).",
  samplingProtocol = "Fixed transects surveyed three times per season (dry and wet) each year 2001-2012 by trained observers recording every bird seen or heard; the authors collapsed each season's three surveys to the number with a detection per species (Frishkoff et al. 2014, Science 345:1343).",
  samplingProtocolCode = "line_transect", surveyEvidence = "row_presence",
  surveyEvidenceNote = "A transect x year x season is a survey iff the deposit has at least one detection row for it (1,048 of 1,056 cells); three bird surveys of a transect never record nothing, and the eight absent cells are all wet-season cells of the three H-SI transects. Within a surveyed cell an unlisted species is y = 0.",
  effortColumn = "obs_trials",
  responseType = "binomial_count", unitKind = "site",
  closure = "none", occasionKind = "none", taxonInclusion = "recorded",
  closureNote = "period = one season of one year (three surveys, collapsed by the authors); occupancy may change between seasons and years",
  geographicCoverage = "Costa Rica, four regions coded GU, LC, PV and SI (cluster_id); no coordinates deposited",
  temporalCoverage = "2001/2012",
  notShipped = list(`Empidonax traillii` = "two rows in six transect-season cells (two source codes lumped onto one name); the union's detections out of 3 cannot be recovered, so the taxon is not shipped"),
  notes = "taxon codes are Genus_epithet (Genus_sp for the four genus-only records) from the deposited names (2014 taxonomy; __taxa carries the GBIF accepted name where the backbone treats the name as a synonym). Transect H-, I- and L- prefixes are the authors' agricultural transect codes; unit_landuse is the deposited LUI. Seasons are ordered dry before wet within a calendar year.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/frishkoff_2014_costarica_birds_binom.R")

stage_dict_row(TABLE,
  description = "Twelve years (2001-2012) of dry- and wet-season bird surveys on 44 transects in forest, diversified and intensive agriculture across four regions of Costa Rica (Frishkoff et al. 2014, Science): surveys with a detection out of three per transect x season x taxon, 490 taxa (486 species, 4 genus-only records), with land use and region.",
  url = "https://doi.org/10.5061/dryad.fv921",
  reference = "Frishkoff, L. O., Karp, D. S., M'Gonigle, L. K., Mendenhall, C. D., Zook, J., Kremen, C., Hadly, E. A., & Daily, G. C. (2014). Loss of avian phylogenetic diversity in neotropical agricultural systems. Science, 345(6202), 1343-1346.",
  doi_paper = "10.1126/science.1254610", doi_data = "10.5061/dryad.fv921",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "binomial_count (ruling #34): only detections deposited, survey set from row presence per transect-season (8 H-SI wet-season cells absent). Four genus-only records shipped at genus rank; Empidonax traillii (duplicated cells) not shipped. Fetched as the Dryad version zip.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multi-season, binomial counts)",
  sampling_protocol = "line_transect", design = "Multi-season (12 years x 2 seasons; 3 surveys per season collapsed to binomial counts)",
  realm = "Terrestrial", country = "CRI", coordinates = "None in source",
  notes = "binomial_count; forest vs diversified vs intensive agriculture; Daily lab (Stanford) long-term Costa Rica bird surveys.", status = "tagged")
