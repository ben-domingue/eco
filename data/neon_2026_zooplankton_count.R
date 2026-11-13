#!/usr/bin/env Rscript
# Table:  neon_2026_zooplankton_count
# Source: NEON (National Ecological Observatory Network). Zooplankton collection (DP1.20219.001),
#         RELEASE-2026. https://doi.org/10.48443/6p6g-d296. Dataset accessed from
#         https://data.neonscience.org/data-products/DP1.20219.001/RELEASE-2026 on 2026-11-12 through
#         the NEON Data API (token-gated; NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data products
#         and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.001194 (AOS Protocol and Procedure: Zooplankton
#         Sampling in Lakes) and the product user guide, linked from the product page. The readme's
#         design description: "Zooplankton samples are collected three times per year at lake sites
#         during aquatic biology bout windows, roughly in spring, summer, and fall. Samples are collected
#         using either a tow net (water deeper than 4 m) or a Schindler-Patalas trap (water shallower
#         than 4 m) ... near the NEON profiling buoy as well as two littoral sensor sets."
# Data:   basic package, all 7 lake sites and 205 site-months of the release (2014-2024):
#         zoo_fieldData: one row per sample (sampleID, eventID SITE.DATE = the bout, boutNumber 1-3,
#           namedLocation buoy.c0 / buoy.c1 / littoral1 / littoral2 / littoral3, samplerType tow net or
#           Schindler-Patalas, towsTrapsNumber composited, towsTrapsVolume litres, samplingImpractical,
#           lake-centre coordinates as published). Three samples a bout (one per location), but two
#           per location in two 2014 bouts and two samples in one 2015 CRAM bout.
#         zoo_perSample: the laboratory's subsampling record per sample (subsampleType none / fine /
#           coarse, QC differences); no subsample share.
#         zoo_taxonomyProcessed: the laboratory's counts per sample x taxon (individualCount = animals
#           counted, zooSubsampleVolume of estConcentratedSampleVolume ml examined, subsampleType coarse
#           or fine, adjCountPerBottle = the count scaled to the whole bottle, nauplii Y/N, taxonRank,
#           sampleCondition per row). The readme's issue log corrects adjCountPerBottle (volumes) for
#           2015-2023 in RELEASE-2025 and RELEASE-2026; individualCount, the count itself, is not affected.
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture; responseType count):
#   unit = NEON lake site; period = bout (eventID), a global integer index ordered by date (__periods:
#   eventID, site, year, boutNumber, date); occasion = sample within the bout, ordered by namedLocation
#   then sampleID (spatial replicates taken on one day: occasionKind spatial, closure closed);
#   y = animals of the taxon counted by the laboratory in the sample (summed over the coarse and fine
#   subsamples and over nauplii and later stages), not the whole-bottle estimate; date = collectDate.
#   obs_location (buoy.c0, buoy.c1, littoral1, littoral2, littoral3), obs_sampler_type, obs_tows (tows or
#   traps composited) and obs_volume_l (litres of lake water sampled; effortColumn) per sample;
#   obs_n_nauplii = the count of nauplii within y; obs_subsample_fraction (subsampleColumn, ruling 21):
#   for a counted taxon, its counted animals over NEON's adjCountPerBottle for it (the share of the
#   bottle it was counted in), for a taxon not found, the largest share of the bottle the laboratory
#   examined in any subsample of that sample (zooSubsampleVolume / estConcentratedSampleVolume, capped at 1).
#   Survey evidence = sample_table: zoo_fieldData lists every sample (with samplingImpractical where one
#   was not taken); a survey is a sample with samplingImpractical blank and laboratory rows.
#   Taxa surveyed for (ruling 19): the per-site pool, every taxon this table records at the lake at any
#   sample, carried by __survey_taxa; derived from detections (surveyEvidenceNote says so).
#   Taxa: NEON taxonID; subspecies rolled up to the species; records identified to genus, family, ...,
#   phylum and NEON's species complexes ('cx.') are their own taxa (E6); NEON 'sp.' and 'spp.' codes of
#   one name merged (ruling 20).
#   Not shipped: samples not taken (samplingImpractical logistical); samples with a laboratory row
#   marked 'damaged, affecting analysis'; adjCountPerBottle (a whole-bottle estimate); body lengths and
#   widths; identification history, perVial and taxonomyRaw tables.
# Coordinates (E7): Hesperodiaptomus augustaensis (VU; GBIF IUCN record, asserted), a calanoid copepod of the
#   south-eastern USA, is recorded at the two Florida lakes (BARC, SUGG), within its native range. As for the
#   macroinvertebrates (E7 scope, 3) two tables ship: this one, every taxon, with the lake coordinates in __units
#   snapped to their 0.1-degree cell centre and elevation rounded to 100 m; and neon_2026_zooplankton_exact_count,
#   at NEON's coordinates, without H. augustaensis (records identified only to a higher rank stay in both).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_zooplankton_count"
PRODUCT <- "DP1.20219.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/6p6g-d296"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("zoo_fieldData", "zoo_perSample", "zoo_taxonomyProcessed"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 205L, identical(attr(nx, "productDoi"), DOI))
fd <- nx$zoo_fieldData; tx <- nx$zoo_taxonomyProcessed
cat(sprintf("  zoo_fieldData %d, zoo_taxonomyProcessed %d rows\n", nrow(fd), nrow(tx)))

# --- the source as deposited --------------------------------------------------------------------
stopifnot(uniqueN(fd$siteID) == 7L, all(fd$aquaticSiteType == "lake"), !anyNA(fd$sampleID), !anyDuplicated(fd$sampleID),
          all(is.na(fd$samplingImpractical) | fd$samplingImpractical == "logistical"), sum(!is.na(fd$samplingImpractical)) == 9L,
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", fd$collectDate)), all(tx$sampleID %in% fd$sampleID),
          all(tx$targetTaxaPresent == "Y"), !anyNA(tx$individualCount), all(as.integer(tx$individualCount) >= 1),
          !anyNA(tx$adjCountPerBottle), all(as.numeric(tx$adjCountPerBottle) >= as.numeric(tx$individualCount)),
          !anyNA(tx$zooSubsampleVolume), !anyNA(tx$estConcentratedSampleVolume), !anyNA(tx$taxonRank),
          all(tx$nauplii %in% c("Y", "N", NA)))

# --- surveys -------------------------------------------------------------------------------------------
n_impr <- fd[!is.na(samplingImpractical), .N]
sv <- fd[is.na(samplingImpractical)]
stopifnot(all(sv$samplerType %in% c("tow net", "Schindler-Patalas")), !anyNA(sv$towsTrapsVolume), all(as.numeric(sv$towsTrapsVolume) > 0),
          !anyNA(sv$towsTrapsNumber))
n_nolab <- sv[!sampleID %in% tx$sampleID, .N]
bad_dmg <- unique(tx[sampleCondition %in% "damaged, affecting analysis", sampleID])
stopifnot(n_nolab == 0L, length(bad_dmg) == 2L)
sv <- sv[sampleID %in% tx$sampleID & !sampleID %in% bad_dmg]
sv[, day := substr(collectDate, 1, 10)]
stopifnot(sv[, uniqueN(day), by = eventID][, all(V1 == 1)], sv[, uniqueN(siteID), by = eventID][, all(V1 == 1)])
n_per_ev <- sv[, .(k = .N), by = eventID][, .(n_ev = .N), by = k][order(k)]
cat(sprintf("  %d samples kept; %d not taken (logistical); %d dropped (a row marked damaged, affecting analysis); bouts by samples: %s\n",
            nrow(sv), n_impr, length(bad_dmg), paste(sprintf("%d with %d", n_per_ev$n_ev, n_per_ev$k), collapse = ", ")))
lab <- tx[sampleID %in% sv$sampleID]

# --- taxa --------------------------------------------------------------------------------------------------
lab[, rank := taxonRank]
lab[, name := fifelse(rank %in% c("species", "subspecies"), sub("^(\\S+ \\S+).*$", "\\1", scientificName), sub(" spp?\\.$", "", scientificName))]
lab[rank == "subspecies", rank := "species"]
stopifnot(lab[, uniqueN(rank), by = name][, all(V1 == 1)], all(grepl(" cx\\.$", lab[rank == "speciesGroup", scientificName])))
code <- lab[, .N, by = .(name, rank, taxonID)][order(-N)][, .(taxon = taxonID[1], codes = paste(sort(unique(taxonID)), collapse = "/"), n_codes = uniqueN(taxonID)), by = .(name, rank)]
stopifnot(!anyDuplicated(code$name), !anyDuplicated(code$taxon))
lab <- merge(lab, code[, .(name, taxon)], by = "name")
lab[, vf := pmin(1, as.numeric(zooSubsampleVolume) / as.numeric(estConcentratedSampleVolume))]
counts <- lab[, .(y = sum(as.integer(individualCount)), est = sum(as.numeric(adjCountPerBottle)),
                  obs_n_nauplii = sum(as.integer(individualCount)[nauplii %in% "Y"])), by = .(sampleID, taxon)]
counts[, frac := pmin(1, y / est)]
sfrac <- lab[, .(zero_frac = max(vf)), by = sampleID]
stopifnot(all(counts$frac > 0), all(sfrac$zero_frac > 0), all(counts$obs_n_nauplii <= counts$y))
tot <- lab[, .(n_ind = sum(as.integer(individualCount)), n_samples = uniqueN(sampleID)), by = .(taxon, name, rank)][order(-n_ind)]
tot <- merge(tot, lab[, .(phylum = phylum[1], class = class[1], order = order[1], family = family[1]), by = taxon], by = "taxon")[order(-n_ind)]
cat(sprintf("  %d taxa (%d species, %d higher rank or complex); %d sp./spp. code pairs merged; %d animals counted\n",
            nrow(tot), tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], sum(tot$n_ind)))

# --- periods, occasions, units -------------------------------------------------------------------------
ev <- sv[, .(day = day[1], site = siteID[1], bout = as.integer(boutNumber[1])), by = eventID]
setorder(ev, day, eventID); ev[, period := seq_len(.N)][, year := as.integer(substr(day, 1, 4))]
stopifnot(all(ev$bout %in% 1:3))
sv <- merge(sv, ev[, .(eventID, period)], by = "eventID")
sv[, location := sub("^[A-Z]{4}\\.AOS\\.", "", namedLocation)]
stopifnot(all(sv$location %in% c("buoy.c0", "buoy.c1", "littoral1", "littoral2", "littoral3")))
setorder(sv, period, location, sampleID); sv[, occasion := seq_len(.N), by = period]
sv <- merge(sv, sfrac, by = "sampleID")
units <- fd[order(siteID, -as.numeric(as.Date(substr(collectDate, 1, 10))))][!duplicated(siteID),
          .(unit = siteID, domain = domainID, decimalLatitude = as.numeric(decimalLatitude),
            decimalLongitude = as.numeric(decimalLongitude), coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty),
            elevation_m = as.numeric(elevation))]
units <- units[unit %in% sv$siteID]
base <- sv[, .(unit = siteID, period, occasion, date = collectDate, obs_location = location, obs_sampler_type = samplerType,
               obs_tows = as.integer(towsTrapsNumber), obs_volume_l = as.numeric(towsTrapsVolume), zero_frac, sampleID)]
periods <- ev[, .(period, eventID, site, year, bout, date = day)]
pool <- unique(merge(counts[, .(sampleID, taxon)], base[, .(sampleID, unit)], by = "sampleID")[, .(unit, taxon)])
setorder(pool, unit, taxon)
pool_n <- pool[, .N, by = unit]
stopifnot(setequal(pool$taxon, tot$taxon), setequal(pool$unit, base$unit))
setkey(counts, sampleID, taxon)
long <- merge(base, pool, by = "unit", allow.cartesian = TRUE)
m <- counts[.(long$sampleID, long$taxon)]
long[, `:=`(y = m$y, obs_n_nauplii = m$obs_n_nauplii, obs_subsample_fraction = m$frac)]
long[is.na(y), `:=`(y = 0L, obs_n_nauplii = 0L, obs_subsample_fraction = zero_frac)]
long[, c("zero_frac", "sampleID") := NULL]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == sum(pool_n[base, on = "unit"]$N), sum(long$y) == sum(tot$n_ind), !anyDuplicated(long[, .(unit, taxon, period, occasion)]),
          !anyNA(long$obs_subsample_fraction))
cat(sprintf("  %d samples in %d bouts at %d lakes, %d-%d; %d rows; per-lake pools median %d taxa (range %d-%d)\n", nrow(base), nrow(ev), uniqueN(base$unit),
            min(ev$year), max(ev$year), nrow(long), as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N)))

# --- __taxa: GBIF, with NEON's classification as hints where the plain match is not an animal ------------
nokey <- tot[rank == "speciesGroup", taxon]
rem <- ifelse(tot$rank == "species", NA_character_,
              sprintf("identified by the NEON taxonomy laboratory only to %s; NEON code(s) %s", tot$rank, code$codes[match(tot$taxon, code$taxon)]))
rem[tot$rank == "speciesGroup"] <- paste0(rem[tot$rank == "speciesGroup"], "; a species complex ('cx.') NEON records as one; the GBIF backbone holds no such taxon, so taxonID is empty")
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = fifelse(tot$rank == "speciesGroup", "species complex", tot$rank), exact = FALSE, no_key = nokey, taxonRemarks = rem,
                  taxon_n_counted = tot$n_ind)
taxa[, kingdom := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey) NA_character_ else gbif_kingdom(scientificName[i]), "")]
fix <- taxa[!taxon %in% nokey & !(gbifMatchType == "EXACT" & kingdom %in% "Animalia"), taxon]
for (tk in fix) {
  h <- tot[taxon == tk]
  r <- gbif_taxon_hinted(h$name, list(kingdom = "Animalia", phylum = h$phylum, class = h$class, order = h$order, family = h$family))
  # NEON's higher classification is offset for some zooplankton rows (readme issue log), which can defeat
  # the full hints: fall back to the kingdom alone
  if (!(identical(r$canonicalName, h$name) && identical(r$kingdom, "Animalia"))) r <- gbif_taxon_hinted(h$name, list(kingdom = "Animalia"))
  if (identical(r$canonicalName, h$name) && identical(r$kingdom, "Animalia")) {
    taxa[taxon == tk, `:=`(taxonID = r$taxonID, gbifMatchType = paste0(r$matchType, " (hinted)"), gbifAcceptedName = r$acceptedName)]
  } else {
    taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = r$matchType,
         taxonRemarks = paste0(fifelse(is.na(taxonRemarks), "", paste0(taxonRemarks, "; ")), "no match of this name among animals on the GBIF backbone (with NEON's classification as hints), so taxonID is empty"))]
  }
}
n_fixed <- taxa[taxon %in% fix & !is.na(taxonID), .N]; n_unmatched <- taxa[!taxon %in% nokey & is.na(taxonID), .N]
cat(sprintf("  GBIF: %d taxa re-matched with NEON's classification as hints, %d without a key (plus %d species complexes)\n", n_fixed, n_unmatched, length(nokey)))
taxa[, kingdom := NULL]
stopifnot(!any(taxa$taxonID %in% "https://www.gbif.org/species/1"), all(!is.na(taxa$taxonID) | !is.na(taxa$taxonRemarks)))
# E7 (scope 3): taxa IUCN CR/EN/VU in their native range are in the table, so it ships with coarsened lake
# coordinates, and neon_2026_zooplankton_exact_count without them at NEON's published coordinates
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
fl <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(identical(taxa[taxon %in% fl, scientificName], "Hesperodiaptomus augustaensis"),
          setequal(pool[taxon %in% fl, unit], c("BARC", "SUGG")))
flag <- taxa[taxon %in% fl, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  flagged:", paste(flag, collapse = "; "), "\n")
cg <- coarsen_coords(units$decimalLatitude, units$decimalLongitude, 0.1)
units_c <- copy(units)[, `:=`(decimalLatitude = cg$lat, decimalLongitude = cg$lon, coordinateUncertaintyInMeters = cg$uncertainty_m, elevation_m = round(elevation_m, -2))]
EXACT <- "neon_2026_zooplankton_exact_count"
emit <- function(TABLE, exact) {
lt <- if (exact) long[!taxon %in% fl] else long
tt <- if (exact) taxa[!taxon %in% fl] else taxa
ut <- if (exact) units else units_c
st <- if (exact) pool[!taxon %in% fl] else pool
nt <- nrow(tt)
dataset <- list(
  title = paste0(sprintf("NEON lake zooplankton, RELEASE-2026: animals of %d taxa counted per tow or trap sample, about three samples per bout and three bouts a year at %d NEON lakes, %d-%d", nt, uniqueN(base$unit), min(ev$year), max(ev$year)), if (exact) " (without IUCN-threatened taxa; coordinates as published)" else ""),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = sub("^https://doi.org/", "", DOI),
  sourceURL = "https://data.neonscience.org/data-products/DP1.20219.001/RELEASE-2026",
  citation = sprintf("NEON (National Ecological Observatory Network). Zooplankton collection (DP1.20219.001), RELEASE-2026. %s. Dataset accessed from https://data.neonscience.org/data-products/DP1.20219.001/RELEASE-2026 on 2026-11-12", DOI),
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's lake zooplankton survey: in spring, summer and fall bouts a sample is taken near the profiling buoy and at two littoral sensor sets, by vertical tow net where the water is deeper than 4 m and by Schindler-Patalas trap elsewhere, preserved and sent to a taxonomy laboratory, which counts and identifies the animals in coarse and fine subsamples of known volume. This table is the number of animals of each taxon counted in each sample; obs_subsample_fraction gives the share of the sample they were counted in, and the whole-bottle estimate is not shipped. The taxa surveyed for at a lake are the per-lake pool of taxa this table records there (median %d of %d; __survey_taxa). %s", as.integer(median(pool_n$N)), nt, if (exact) "Lake-centre coordinates are as NEON publishes them; the IUCN-threatened copepod Hesperodiaptomus augustaensis is not in this table (neon_2026_zooplankton_count has it, with coarsened coordinates)." else "Lake-centre coordinates are coarsened to the 0.1-degree cell because an IUCN-threatened copepod is in the table; neon_2026_zooplankton_exact_count has the other taxa at NEON's coordinates."),
  samplingProtocol = "Vertical tow net (water deeper than 4 m) or Schindler-Patalas trap (shallower), one composite sample near the profiling buoy and one at each of two littoral sensor sets, three bouts a year; samples preserved in ethanol, subsampled (coarse and fine fractions of known volume) and counted and identified by a taxonomy laboratory (NEON AOS zooplankton sampling protocol)",
  samplingProtocolCode = "plankton_net", surveyEvidence = "sample_table",
  surveyEvidenceNote = "zoo_fieldData lists every sample (with samplingImpractical where one was not taken); a survey is a sample with samplingImpractical blank and laboratory rows in zoo_taxonomyProcessed. The zeros rest on a per-lake species pool derived from detections (ruling 19): the taxa surveyed for at a lake are every taxon this table records at that lake in any sample (__survey_taxa), not a list NEON deposited.",
  responseType = "count", unitKind = "site", effortColumn = "obs_volume_l", subsampleColumn = "obs_subsample_fraction",
  closure = "closed", closureNote = "occasion = sample within one bout, taken on one day at the buoy and the littoral sensor sets (two per location in two 2014 bouts); period = bout (spring, summer, fall), indexed globally by date", occasionKind = "spatial",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON lake sites in Florida, Wisconsin, North Dakota and Alaska; lake-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", nrow(units), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(ev$day), 1, 7), substr(max(ev$day), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("As published by NEON (lake-centre coordinates with coordinateUncertaintyInMeters in __units). The IUCN-threatened taxa (%s) are not in this table (E7 scope, 3); neon_2026_zooplankton_count has them, with coordinates coarsened.", paste(flag, collapse = ", "))) else
    list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): NEON's published lake-centre coordinates in __units snapped to their 0.1-degree cell centre, uncertainty the cell half-diagonal, elevation rounded to 100 m, because taxa IUCN CR/EN/VU in their native range are in the table (%s, recorded at BARC and SUGG, Florida; E7, ruling on the publisher 2026-11-06). NEON site codes are kept. neon_2026_zooplankton_exact_count keeps the other taxa at published precision.", paste(flag, collapse = ", "))),
  covariateNote = "obs_location = NEON sampling location (buoy.c0 / buoy.c1 near the buoy, littoral1-3 at the littoral sensor sets); obs_sampler_type = tow net or Schindler-Patalas; obs_tows = tows or traps composited into the sample; obs_volume_l = litres of lake water sampled (effort); obs_n_nauplii = nauplii among the animals counted (within y); obs_subsample_fraction (subsampleColumn) = for a counted taxon, its counted animals over NEON's adjCountPerBottle (the share of the bottle it was counted in), for a taxon not found, the largest share of the bottle examined in any subsample of the sample (zooSubsampleVolume / estConcentratedSampleVolume, capped at 1); it may vary across taxa within a sample (E5).",
  notes = sprintf("y = animals counted by the laboratory, summed over the coarse and fine subsamples and over nauplii and later stages (nauplii as obs_n_nauplii); NEON's whole-bottle estimate adjCountPerBottle, whose volumes the readme's issue log corrects for 2015-2023, is not shipped and does not enter y. Per-lake pools (ruling 19): median %d taxa (range %d-%d). Taxa: %d species (subspecies rolled up) and %d records identified only to a higher rank or to a species complex, each its own taxon (E6); %d pairs of NEON 'sp.' and 'spp.' codes merged (ruling 20). Surveys: %d samples in %d bouts; %d samples not taken (logistical); %d samples dropped (a laboratory row marked damaged, affecting analysis). Other per-row sample conditions (damaged, affecting taxonomy or measurement) are kept. Seven lakes: below the sample floor of 30 units.", as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], nrow(base), nrow(ev), n_impr, length(bad_dmg)),
  notShipped = c(if (exact) list(threatened = sprintf("%s; records identified only to a higher rank stay in both tables (E7 scope, 3)", paste(flag, collapse = ", "))), list(
    `samples not used` = sprintf("%d samples not taken (samplingImpractical logistical); %d with a laboratory row marked damaged, affecting analysis", n_impr, length(bad_dmg)),
    `whole-bottle estimate` = "adjCountPerBottle (the count scaled to the whole bottle; y and obs_subsample_fraction are shipped)",
    `other fields` = "body length and width summaries, zoo_perSample QC metrics, identification history, zoo_perVial and zoo_taxonomyRaw (expanded package)",
    `zeros outside the lake pool` = "a taxon never recorded at a lake has no rows there (per-lake pool, ruling 19)")))
ds <- write_table(lt, TABLE, dataset, taxa = tt, periods = periods, units = ut, survey_taxa = st,
                  script = "data/neon_2026_zooplankton_count.R")

stage_dict_row(TABLE,
  description = sprintf("Animals of %d zooplankton taxa counted per tow-net or Schindler-Patalas trap sample (about three samples per bout, spring, summer and fall bouts) at %d NEON lakes, %d-%d, built from NEON's field and taxonomy-laboratory records (RELEASE-2026), with sampler, volume sampled, the fraction counted and lake-centre coordinates %s.", nt, uniqueN(base$unit), min(ev$year), max(ev$year), if (exact) "as published (IUCN-threatened taxa left out)" else "coarsened to 0.1 degree"),
  url = "https://data.neonscience.org/data-products/DP1.20219.001/RELEASE-2026",
  reference = sprintf("NEON (National Ecological Observatory Network). Zooplankton collection (DP1.20219.001), RELEASE-2026. %s", DOI),
  doi_paper = "", doi_data = sub("^https://doi.org/", "", DOI),
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Token-gated NEON API (NEON_TOKEN); release pinned. y = counted subsample with obs_subsample_fraction (subsampleColumn); per-lake pool from detections (ruling 19).",
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "plankton_net", design = sprintf("Multi-season (%d bouts x about 3 samples)", nrow(ev)), realm = "Freshwater", country = "USA",
  coordinates = if (exact) "As published" else "Coarsened (0.1 deg)", notes = "NEON national scheme; lakes; counted-subsample zooplankton counts per sample; per-lake species pools (__survey_taxa).",
  status = "tagged")
}
emit("neon_2026_zooplankton_count", exact = FALSE)
emit(EXACT, exact = TRUE)
