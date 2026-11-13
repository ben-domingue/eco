#!/usr/bin/env Rscript
# Table:  neon_2026_aqplants_occ
# Source: NEON (National Ecological Observatory Network). Aquatic plant, bryophyte, lichen, and macroalgae
#         point counts in wadeable streams (DP1.20072.001), RELEASE-2026. https://doi.org/10.48443/sgfd-xs73.
#         Dataset accessed from https://data.neonscience.org/data-products/DP1.20072.001/RELEASE-2026 on
#         2026-11-12 through the NEON Data API (token-gated; NEON_TOKEN environment variable, see
#         lib/eco_common.R). Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data
#         products and sample data are licensed under a Creative Commons Attribution 4.0 International
#         License (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.003039 (AOS Protocol and Procedure: Aquatic Plant,
#         Bryophyte, Lichen, and Macroalgae Sampling) and the product user guide, linked from the product
#         page. Design: ten permanent transects across the wetted channel of each wadeable-stream reach,
#         surveyed three bouts a year (spring, summer, fall); at regular points along each transect the
#         technician records whether aquatic plants, bryophytes, lichens or macroalgae are present at the
#         point, which taxa, habitat type and substrate.
# Data:   basic package, all 24 wadeable-stream sites and 610 site-months of the release (2014-2024):
#         apc_pointTransect: one row per point x transect x visit (namedLocation = transect, pointNumber,
#           transectDistance m, collectDate, eventID SITE.DATE = the bout, boutNumber 1-3,
#           samplingImpractical where a transect was not sampled (no pointNumber, or a point on a dry
#           transect), targetTaxaPresent Y / N / U, habitatType, substrate, transect coordinates as
#           published).
#         apc_perTaxon: one row per point x taxon present (taxonID, scientificName with authority,
#           taxonRank, aquaticPlantType plant / macroalgae, growthForm, morphospeciesID, classification).
#           About a fifth of its rows (mostly macroalgae, 2016-2021) carry no taxonID: a morphospecies
#           not resolved in the basic package; NEON's 'Unknown plant' and 'Unknown Algae' codes are rows
#           at the kingdom rank.
# Mapping (standard E9 core: multi-scale / community occupancy with spatial replicates; responseType detection):
#   unit = transect (NEON namedLocation); unit_site; period = bout (eventID), a global integer index
#   ordered by date (__periods: eventID, site, year, boutNumber, date); occasion = point along the
#   transect at the bout, ordered by pointNumber then time (spatial replicates: occasionKind spatial,
#   closure closed); date = collectDate as published; y = 1 if NEON lists the taxon at the point,
#   else 0. obs_point = NEON pointNumber, obs_distance_m = transectDistance, obs_habitat_type,
#   obs_substrate per point.
#   Survey evidence = sample_table: apc_pointTransect lists every point visited (and transects not
#   sampled, with samplingImpractical); a survey is a point row with a pointNumber, samplingImpractical
#   blank and targetTaxaPresent N (y = 0 for every taxon) or Y with apc_perTaxon rows.
#   Taxa surveyed for (ruling 19): the per-site pool, every taxon this table records at the transect's
#   site at any point, carried by __survey_taxa (unit, taxon); derived from detections.
#   Taxa: NEON taxonID; varieties and subspecies rolled up to the species; records identified to genus,
#   family or order are their own taxa (E6); NEON's kingdom-level 'Unknown plant' and 'Plantae sp.' and
#   plant rows with no taxonID are one taxon, Plantae ('plant, not identified'); 'Unknown Algae' and
#   macroalgae rows with no taxonID (unresolved morphospecies) are one functional group, 'macroalgae, not
#   identified', with no taxonID. Identifications NEON qualifies 'cf.' or 'aff.' are kept as recorded.
#   Not shipped: transects not sampled; points recorded U (unknown); points recorded Y with no taxon rows
#   or N with taxon rows; a point recorded more than once at one bout (2014-2016 legacy data; the taxon rows
#   cannot be assigned to one record); perTaxon rows with neither a taxonID nor an aquaticPlantType (the point stays a survey and
#   the record is counted in notShipped); growth form; vouchers and morphospecies tables (expanded package).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_aqplants_occ"
PRODUCT <- "DP1.20072.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/sgfd-xs73"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("apc_pointTransect", "apc_perTaxon"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 610L, identical(attr(nx, "productDoi"), DOI))
pt <- nx$apc_pointTransect; tx <- nx$apc_perTaxon
cat(sprintf("  apc_pointTransect %d, apc_perTaxon %d rows\n", nrow(pt), nrow(tx)))

# --- the source as deposited --------------------------------------------------------------------
IMPR <- c("location dry", "other", "logistical", "location frozen", "high water velocity", "location snow covered")
stopifnot(uniqueN(pt$siteID) == 24L, all(is.na(pt$samplingImpractical) | pt$samplingImpractical %in% IMPR),
          all(!is.na(pt$pointNumber) | !is.na(pt$samplingImpractical)), all(pt$targetTaxaPresent %in% c("Y", "N", "U", NA)),
          all(is.na(pt$targetTaxaPresent) == !is.na(pt$samplingImpractical)),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", pt$collectDate)), all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", tx$collectDate)),
          all(grepl("^[A-Z]{4}\\.AOS\\.(aquatic\\.plant\\.transect\\.\\d+b?|reach)$", pt$namedLocation)),
          all(tx$aquaticPlantType %in% c("plant", "macroalgae", NA)))
# a point is keyed by transect x bout x point; a taxon row's collection time can differ from its point
# row's (2015-2016), and a few points carry more than one record in a bout (2014-2016 legacy data, some at
# the same time), so the taxa cannot be assigned to one record: those points are dropped whole (below)
pt[, pk := paste(namedLocation, eventID, pointNumber)]
tx[, pk := paste(namedLocation, eventID, pointNumber)]
stopifnot(all(tx$pk %in% pt$pk))

# --- surveys -------------------------------------------------------------------------------------------
# points filed under the reach, not a transect (CUPE, MAYF): no transect to be the unit
n_reach <- pt[grepl("\\.reach$", namedLocation), .N]
stopifnot(n_reach == 510L, all(is.na(pt[grepl("\\.reach$", namedLocation), samplingImpractical])))
pt <- pt[!grepl("\\.reach$", namedLocation)]
n_impr <- pt[!is.na(samplingImpractical), .N]
sv <- pt[is.na(samplingImpractical)]
n_u <- sv[targetTaxaPresent == "U", .N]
n_y_none <- sv[targetTaxaPresent == "Y" & !pk %in% tx$pk, .N]
n_n_some <- sv[targetTaxaPresent == "N" & pk %in% tx$pk, .N]
sv <- sv[targetTaxaPresent == "N" & !pk %in% tx$pk | targetTaxaPresent == "Y" & pk %in% tx$pk]
dup <- pt[!is.na(pointNumber), .N, by = pk][N > 1L, pk]
n_dup <- uniqueN(sv[pk %in% dup, pk])
sv <- sv[!pk %in% dup]
sv[, day := substr(collectDate, 1, 10)]
stopifnot(sv[, uniqueN(siteID), by = eventID][, all(V1 == 1)], sv[, as.numeric(diff(range(as.Date(day)))), by = eventID][, all(V1 <= 1)],
          !anyNA(sv$boutNumber))
cat(sprintf("  %d point surveys kept; %d transect or point rows not sampled; %d points U; %d Y with no taxon rows; %d N with taxon rows; %d points with more than one record in a bout\n",
            nrow(sv), n_impr, n_u, n_y_none, n_n_some, n_dup))
cat(sprintf("  %d points filed under the reach, not a transect, not used\n", n_reach))
stopifnot(n_u == 361L, n_y_none == 36L, n_n_some == 15L, n_dup == 340L)

# --- taxa --------------------------------------------------------------------------------------------------
lab <- tx[pk %in% sv$pk]
n_reach_tx <- tx[grepl("\\.reach$", namedLocation), .N]
n_untyped <- lab[is.na(taxonID) & is.na(aquaticPlantType), .N]
lab <- lab[!(is.na(taxonID) & is.na(aquaticPlantType))]
lab[, rank := taxonRank]
lab[is.na(taxonID) | rank == "kingdom", rank := fifelse(aquaticPlantType == "plant", "kingdom", "functional group")]
stopifnot(!anyNA(lab$rank), all(lab$rank %in% c("species", "variety", "subspecies", "genus", "family", "order", "kingdom", "functional group")),
          all(lab[rank %in% c("species", "variety", "subspecies"), !is.na(genus) & !is.na(specificEpithet)]))
lab[, name := fcase(rank %in% c("species", "variety", "subspecies"), paste(genus, specificEpithet),
                    rank == "genus", genus, rank == "family", family, rank == "order", order,
                    rank == "kingdom", "Plantae", rank == "functional group", "macroalgae, not identified")]
stopifnot(!anyNA(lab$name))
lab[rank %in% c("variety", "subspecies"), rank := "species"]
stopifnot(lab[, uniqueN(rank), by = name][, all(V1 == 1)])
lab[rank == "kingdom", taxonID := fifelse(is.na(taxonID), "2PLANT", taxonID)]
lab[rank == "functional group", taxonID := "UNKALG"]
code <- lab[, .N, by = .(name, rank, taxonID)][order(-N)][, .(taxon = taxonID[1], codes = paste(sort(unique(taxonID)), collapse = "/"), n_codes = uniqueN(taxonID)), by = .(name, rank)]
stopifnot(!anyDuplicated(code$name), !anyDuplicated(code$taxon), code[name == "Plantae", taxon] == "2PLANT")
lab <- merge(lab, code[, .(name, taxon)], by = "name")
det <- unique(lab[, .(pk, taxon)])
n_noid <- tx[pk %in% sv$pk & is.na(taxonID) & !is.na(aquaticPlantType), .N]
tot <- lab[, .(n_points = uniqueN(pk), type = names(which.max(table(aquaticPlantType)))), by = .(taxon, name, rank)][order(-n_points)]
tot <- merge(tot, lab[, .(family = family[!is.na(family)][1]), by = taxon], by = "taxon")[order(-n_points)]
cat(sprintf("  %d taxa (%d species, %d higher rank); %d records with no taxonID pooled as not identified, %d with no type not shipped; %d detections\n",
            nrow(tot), tot[rank == "species", .N], tot[rank != "species", .N], n_noid, n_untyped, nrow(det)))

# --- periods, occasions, units -------------------------------------------------------------------------
# one bout (COMO.20240708) has 164 points recorded as boutNumber 1 and 16 as 2 on the same day: its modal number
stopifnot(identical(sv[, uniqueN(boutNumber), by = eventID][V1 > 1, eventID], "COMO.20240708"))
ev <- sv[, .(day = min(day), site = siteID[1], bout = as.integer(names(which.max(table(boutNumber))))), by = eventID]
setorder(ev, day, eventID); ev[, period := seq_len(.N)][, year := as.integer(substr(day, 1, 4))]
stopifnot(all(ev$bout %in% 1:3))
sv <- merge(sv, ev[, .(eventID, period)], by = "eventID")
setorder(sv, namedLocation, period, pointNumber, collectDate)
sv[, pointNumber := as.integer(pointNumber)]
setorder(sv, namedLocation, period, pointNumber, collectDate)
sv[, occasion := seq_len(.N), by = .(namedLocation, period)]
sv[, unit := sub("^([A-Z]{4})\\.AOS\\.aquatic\\.plant\\.transect\\.", "\\1_T", namedLocation)]
units <- pt[order(namedLocation, -as.numeric(as.Date(substr(collectDate, 1, 10))))][!duplicated(namedLocation),
          .(unit = sub("^([A-Z]{4})\\.AOS\\.aquatic\\.plant\\.transect\\.", "\\1_T", namedLocation), site = siteID, domain = domainID,
            named_location = namedLocation, decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
            coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))]
units <- units[unit %in% sv$unit]
stopifnot(!anyDuplicated(units$unit), !anyNA(units$decimalLatitude))
base <- sv[, .(unit, period, occasion, date = collectDate, unit_site = siteID, obs_point = pointNumber,
               obs_distance_m = as.numeric(transectDistance), obs_habitat_type = habitatType, obs_substrate = substrate, pk)]
periods <- ev[, .(period, eventID, site, year, bout, date = day)]
site_pool <- unique(merge(det, base[, .(pk, unit_site)], by = "pk")[, .(unit_site, taxon)])
pool <- merge(unique(base[, .(unit, unit_site)]), site_pool, by = "unit_site", allow.cartesian = TRUE)[, .(unit, taxon)]
setorder(pool, unit, taxon)
pool_n <- site_pool[, .N, by = unit_site]
stopifnot(setequal(pool$taxon, tot$taxon))
n_rows <- sum(pool[, .N, by = unit][base, on = "unit"]$N)
cat(sprintf("  %d point surveys on %d transects at %d sites in %d bouts, %d-%d; %d rows; per-site pools median %d taxa (range %d-%d)\n",
            nrow(base), uniqueN(base$unit), uniqueN(base$unit_site), nrow(ev), min(ev$year), max(ev$year), n_rows,
            as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N)))
stopifnot(n_rows < 5e6)
long <- merge(base, pool, by = "unit", allow.cartesian = TRUE)
det[, y := 1L]; setkey(det, pk, taxon)
long[, y := det[.(long$pk, long$taxon), y]][is.na(y), y := 0L][, pk := NULL]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == n_rows, sum(long$y) == nrow(det), !anyDuplicated(long[, .(unit, taxon, period, occasion)]))

# --- __taxa: GBIF; macroalgae may sit in Plantae, Chromista, Protozoa or Bacteria (cyanobacteria), lichens in Fungi
KINGDOMS <- c("Plantae", "Chromista", "Protozoa", "Bacteria", "Fungi")   # Fungi: the lichens
nokey <- "UNKALG"
rem <- ifelse(tot$rank == "species", ifelse(code$n_codes[match(tot$taxon, code$taxon)] > 1, sprintf("varieties or subspecies rolled up to the species; NEON code(s) %s", code$codes[match(tot$taxon, code$taxon)]), NA_character_),
              sprintf("identified by NEON only to %s; NEON code(s) %s", tot$rank, code$codes[match(tot$taxon, code$taxon)]))
rem[tot$taxon == "2PLANT"] <- sprintf("NEON's kingdom-level codes (Unknown plant, Plantae sp.) and plant records with no taxonID, as one taxon; NEON code(s) %s", code[taxon == "2PLANT", codes])
rem[tot$taxon == "UNKALG"] <- sprintf("NEON's 'Unknown Algae' code and macroalgae records with no taxonID (morphospecies not resolved in the basic package), as one functional group; not one taxon on the GBIF backbone, so taxonID is empty (%d records with no taxonID)", n_noid)
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = tot$rank, exact = FALSE, no_key = nokey, taxonRemarks = rem,
                  taxon_type = tot$type, taxon_n_points = tot$n_points)
taxa[, kingdom := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey) NA_character_ else gbif_kingdom(scientificName[i]), "")]
fix <- taxa[!taxon %in% c(nokey, "2PLANT") & !(gbifMatchType == "EXACT" & kingdom %in% KINGDOMS), taxon]
for (tk in fix) {
  h <- tot[taxon == tk]
  r <- gbif_taxon_hinted(h$name, list(family = if (h$rank %in% c("species", "genus")) h$family else NA))
  if (!(identical(r$canonicalName, h$name) && r$kingdom %in% KINGDOMS)) r <- gbif_taxon_hinted(h$name, list(kingdom = "Plantae"))
  if (identical(r$canonicalName, h$name) && r$kingdom %in% KINGDOMS) {
    taxa[taxon == tk, `:=`(taxonID = r$taxonID, gbifMatchType = paste0(r$matchType, " (hinted)"), gbifAcceptedName = r$acceptedName)]
  } else {
    taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = r$matchType,
         taxonRemarks = paste0(fifelse(is.na(taxonRemarks), "", paste0(taxonRemarks, "; ")), "no match of this name among plants, algae or lichens on the GBIF backbone (with NEON's family as a hint), so taxonID is empty"))]
  }
}
n_fixed <- taxa[taxon %in% fix & !is.na(taxonID), .N]; n_unmatched <- taxa[!taxon %in% nokey & is.na(taxonID), .N]
cat(sprintf("  GBIF: %d taxa re-matched with NEON's family as a hint, %d without a key\n", n_fixed, n_unmatched))
taxa[, kingdom := NULL]
stopifnot(!any(taxa$taxonID %in% "https://www.gbif.org/species/1"), all(!is.na(taxa$taxonID) | !is.na(taxa$taxonRemarks)))
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
flag <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  IUCN CR/EN/VU:", if (length(flag)) paste(flag, collapse = "; ") else "none", "\n")
stopifnot(length(flag) == 0L)

dataset <- list(
  title = sprintf("NEON wadeable-stream aquatic plants and macroalgae, RELEASE-2026: presence of %d taxa at points along %d permanent transects, three bouts a year at %d NEON stream sites, %d-%d", nrow(tot), uniqueN(base$unit), uniqueN(base$unit_site), min(ev$year), max(ev$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = sub("^https://doi.org/", "", DOI),
  sourceURL = "https://data.neonscience.org/data-products/DP1.20072.001/RELEASE-2026",
  citation = sprintf("NEON (National Ecological Observatory Network). Aquatic plant, bryophyte, lichen, and macroalgae point counts in wadeable streams (DP1.20072.001), RELEASE-2026. %s. Dataset accessed from https://data.neonscience.org/data-products/DP1.20072.001/RELEASE-2026 on 2026-11-12", DOI),
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's point-transect survey of aquatic plants, bryophytes, lichens and macroalgae in wadeable streams: ten permanent transects cross the wetted channel of each reach, and in spring, summer and fall bouts a technician records at regular points along each transect which taxa are present, with habitat and substrate. This table is the presence of each taxon at each point (y = 1 listed, 0 not), the transect as the unit and the points as spatial replicates within a bout. The taxa surveyed for at a site are the per-site pool of taxa this table records there (median %d of %d; __survey_taxa). Unidentified plants are one taxon (Plantae), unidentified macroalgae one functional group. Transect coordinates are as NEON publishes them.", as.integer(median(pool_n$N)), nrow(tot)),
  samplingProtocol = "Point-transect survey: ten permanent transects across the wetted channel of a wadeable-stream reach, points at regular intervals along each, the taxa of aquatic plants, bryophytes, lichens and macroalgae present at each point recorded (with voucher identification), three bouts a year (NEON AOS aquatic plant, bryophyte, lichen and macroalgae sampling protocol, NEON.DOC.003039)",
  samplingProtocolCode = "point_intercept", surveyEvidence = "sample_table",
  surveyEvidenceNote = "apc_pointTransect lists every point visited (transects not sampled carry samplingImpractical); a survey is a point with samplingImpractical blank and targetTaxaPresent N (y = 0 for every taxon) or Y with apc_perTaxon rows. The zeros rest on a per-site species pool derived from detections (ruling 19): the taxa surveyed for at a transect are every taxon this table records at its site (__survey_taxa), not a list NEON deposited.",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = point along the transect at one bout (spatial replicates, visited on one day; a bout spread over two days at a few sites); period = bout (spring, summer, fall), indexed globally by date", occasionKind = "spatial",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON wadeable-stream sites in the continental USA, Alaska and Puerto Rico; transect coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", uniqueN(base$unit_site), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(ev$day), 1, 7), substr(max(ev$day), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = "As published by NEON (transect coordinates with coordinateUncertaintyInMeters in __units); no taxon in the table is IUCN CR, EN or VU (taxon_iucnCategory in __taxa)"),
  covariateNote = "obs_point = NEON pointNumber along the transect; obs_distance_m = transectDistance (m); obs_habitat_type (riffle, run, pool, step pool) and obs_substrate (pebble, cobble, sand, ...) at the point. Site, domain, NEON namedLocation, coordinates, uncertainty and elevation per transect are in __units; unit_site in the core.",
  notes = sprintf("Per-site pools (ruling 19): median %d taxa (range %d-%d). Taxa: %d species (varieties and subspecies rolled up) and %d records identified only to genus, family or order, each its own taxon (E6); unidentified plants (NEON 'Unknown plant', 'Plantae sp.' and plant records with no taxonID) are Plantae, and unidentified macroalgae ('Unknown Algae' and %d macroalgae records with no taxonID, unresolved morphospecies) one functional group. Surveys: %d points; not used: %d transect or point rows not sampled, %d points recorded U, %d recorded Y with no taxon rows, %d recorded N with taxon rows, %d points with more than one record in one bout (2014-2016 legacy data; dropped, since the taxon rows cannot be assigned to one record). %d taxon records with neither a taxonID nor a plant type are not shipped (their points stay surveys).", as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), tot[rank == "species", .N], tot[rank != "species", .N], n_noid, nrow(base), n_impr, n_u, n_y_none, n_n_some, n_dup, n_untyped),
  notShipped = list(
    `points not used` = sprintf("%d transect or point rows not sampled (samplingImpractical); %d points with targetTaxaPresent U; %d Y with no taxon rows; %d N with taxon rows; %d points with more than one record in one bout (taxon rows not assignable to one record)", n_impr, n_u, n_y_none, n_n_some, n_dup),
    `untyped records` = sprintf("%d apc_perTaxon rows with neither a taxonID nor an aquaticPlantType", n_untyped),
    `reach points` = sprintf("%d point rows (with %d taxon rows) filed under the reach (CUPE, MAYF), not a transect, so with no unit", n_reach, n_reach_tx),
    `other fields` = "growthForm, herbarium and voucher records, morphospecies resolution and identification history (expanded package)",
    `zeros outside the site pool` = "a taxon never recorded at a site has no rows there (per-site pool, ruling 19)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, survey_taxa = pool,
                  script = "data/neon_2026_aqplants_occ.R")

stage_dict_row(TABLE,
  description = sprintf("Presence of %d aquatic plant, bryophyte and macroalgae taxa at points along %d permanent transects (spring, summer and fall bouts) at %d NEON wadeable-stream sites, %d-%d, built from NEON's point-transect records (RELEASE-2026), with habitat, substrate and transect coordinates as published.", nrow(tot), uniqueN(base$unit), uniqueN(base$unit_site), min(ev$year), max(ev$year)),
  url = "https://data.neonscience.org/data-products/DP1.20072.001/RELEASE-2026",
  reference = sprintf("NEON (National Ecological Observatory Network). Aquatic plant, bryophyte, lichen, and macroalgae point counts in wadeable streams (DP1.20072.001), RELEASE-2026. %s", DOI),
  doi_paper = "", doi_data = sub("^https://doi.org/", "", DOI),
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Token-gated NEON API (NEON_TOKEN); release pinned. Transect = unit, point = spatial occasion, bout = period; per-site pool from detections (ruling 19); unidentified plants and macroalgae pooled.",
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Community occupancy (multi-scale, multi-season)",
  sampling_protocol = "point_intercept", design = sprintf("Multi-season (%d bouts x about 20 points per transect)", nrow(ev)), realm = "Freshwater", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; wadeable streams; presence at points along permanent transects; per-site species pools (__survey_taxa).",
  status = "tagged")
