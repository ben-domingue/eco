#!/usr/bin/env Rscript
# Table:  neon_2026_landbirds_count
# Source: NEON (National Ecological Observatory Network). Breeding landbird point counts
#         (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57. Dataset accessed
#         from https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026 on
#         2026-11-02 through the NEON Data API (token-gated; NEON_TOKEN environment variable).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data
#         products and sample data are licensed under a Creative Commons Attribution 4.0
#         International License (CC-BY)"); the product page itself is rendered by JavaScript.
#         NEON is funded by the U.S. National Science Foundation and operated by Battelle.
# Data:   per site-month "basic" package CSVs, all 47 sites and all 483 site-months of the
#         release (2013-06 to 2024-07), two NEON tables:
#         brd_perpoint: one row per point-count event (namedLocation, siteID, plotID,
#           pointID, plotType, nlcdClass, decimalLatitude/Longitude of the point as published
#           by NEON, elevation, startDate "YYYY-MM-DDThh:mmZ", boutNumber 1-2,
#           samplingImpractical OK/other/logistical, eventID BRD.site.year.bout, start/end
#           cloud cover, RH, observedHabitat, observedAirTemp, kmPerHourObservedWindSpeed,
#           measuredBy = observer).
#         brd_countdata: one row per detection (same keys, pointCountMinute 1-6 or 88 =
#           detected outside the 6-min count, taxonID, scientificName, taxonRank,
#           vernacularName, observerDistance m (NA for part of the later minutes),
#           detectionMethod, visualConfirmation, clusterSize, clusterCode A-Z linking the
#           records of one cluster across minutes, targetTaxaPresent N = a count with no
#           detections, one placeholder row). Readme: "taxonomic IDs of species of concern
#           have been 'fuzzed', i.e. reported at a higher taxonomic rank"; at GRSM such
#           records are not published at all.
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture):
#   unit = point "<plotID>_<pointID>"; period = calendar year (index in __periods);
#   occasion = boutNumber within the year (1-2); y = number of individuals of the species
#   detected inside the 6-min count (sum of clusterSize, each clusterCode counted once);
#   date = startDate (ISO, UTC); observer = measuredBy; obs_* = event weather and habitat;
#   unit_site in the core; __units carries site, domain, plot type, NLCD class, point
#   coordinates (as published), coordinate uncertainty and elevation.
#   Survey evidence = sample_table: brd_perpoint is the list of counts; a count exists iff
#   its row has samplingImpractical == "OK" and at least one brd_countdata child row (the
#   readme: every event "should have 6+ child records"; OK rows with none are dropped and
#   counted below). Species pool: the species-rank taxa with >= MIN_DET detections (clusters)
#   over the release, every one at every count nationally (the precedent is
#   rooney_2025_snapshotusa_comm; a per-site pool is the alternative, flagged for a ruling).
#   Not shipped: minute-88 detections, higher-rank ("fuzzed") and subspecies IDs, species
#   below the cut, and the per-detection distance/minute/method (sibling table
#   neon_2026_landbirds_ds carries distance bins). Species cut: MIN_DET = 100 clusters keeps
#   the core under 8 million rows (50, the Snapshot USA cut, gave 333 species and 8.8 M).
# Coordinates (E7; batch 46, #10): chimney swift, pinyon jay, long-tailed duck, Puerto Rican bullfinch and Puerto
#   Rican nightjar are IUCN VU (GBIF IUCN records, asserted) and are shipped, within their native ranges. Under the
#   ruling on the publisher (2026-11-06, which withdrew the agency exception) two tables ship (E7 scope, 3): this one,
#   every species, with the point coordinates in __units snapped to their 0.1-degree cell centre and elevation rounded
#   to 100 m; and neon_2026_landbirds_exact_count, at NEON's coordinates, without the five species.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_landbirds_count"
PRODUCT <- "DP1.10003.001"; RELEASE <- "RELEASE-2026"; MIN_DET <- 100L
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("brd_perpoint", "brd_countdata"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 483L,
          identical(attr(nx, "productDoi"), "https://doi.org/10.48443/v6hs-mx57"))
pp <- nx$brd_perpoint; cd <- nx$brd_countdata
stopifnot(uniqueN(pp$siteID) == 47, !anyNA(pp$decimalLatitude), !anyNA(pp$startDate), !anyNA(pp$measuredBy),
          all(pp$boutNumber %in% c("1", "2")), all(pp$samplingImpractical %in% c("OK", "other", "logistical")),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", pp$startDate)),
          all(cd$pointCountMinute %in% c(as.character(1:6), "88")), all(cd$targetTaxaPresent %in% c("Y", "N")))
cat(sprintf("  brd_perpoint %d rows, brd_countdata %d rows\n", nrow(pp), nrow(cd)))

# --- events: one count per (point, startDate); two duplicate perpoint rows are collapsed ----
pp[, unit := paste(plotID, pointID, sep = "_")]
pp[, ev := paste(unit, startDate)]
dup <- pp[duplicated(ev) | duplicated(ev, fromLast = TRUE)]
cat(sprintf("  %d duplicated perpoint rows (same point and start time), first kept\n", nrow(dup)))
pp <- pp[!duplicated(ev)]
cd[, unit := paste(plotID, pointID, sep = "_")][, ev := paste(unit, startDate)]
# a few countdata rows carry a start time that differs from the perpoint row of the same
# point and day (the readme warns of data-entry aberrations): re-key them to that count
# when the point has exactly one count that day
cd[, day := substr(startDate, 1, 10)]; pp[, day := substr(startDate, 1, 10)]
one_per_day <- pp[, .N, by = .(unit, day)][N == 1, .(unit, day)]
fix <- merge(unique(cd[!ev %in% pp$ev, .(unit, day, ev_bad = ev)]), merge(one_per_day, pp[, .(unit, day, ev_pp = ev)], by = c("unit", "day")), by = c("unit", "day"))
cat(sprintf("  %d countdata rows (%d counts) whose start time matches no perpoint row; %d counts re-keyed to the point's single count that day\n",
            sum(!cd$ev %in% pp$ev), uniqueN(cd[!ev %in% pp$ev, ev]), nrow(fix)))
cd[fix, on = .(ev = ev_bad), ev := i.ev_pp]
stopifnot(all(cd$ev %in% pp$ev), nrow(fix) == 5)
has_child <- pp$ev %in% cd$ev
cat(sprintf("  samplingImpractical: %s; OK events without countdata rows: %d (dropped, not evidenced as counted)\n",
            paste(names(table(pp$samplingImpractical)), table(pp$samplingImpractical), collapse = ", "),
            sum(pp$samplingImpractical == "OK" & !has_child)))
evt <- pp[samplingImpractical == "OK" & has_child]
evt[, year := as.integer(substr(startDate, 1, 4))][, bout := as.integer(boutNumber)]
# a point is counted at most once per bout; the few repeats keep the first count of the bout
rep_ev <- evt[, .N, by = .(unit, year, bout)][N > 1]
cat(sprintf("  %d point-year-bouts with more than one count; first count kept\n", nrow(rep_ev)))
setorder(evt, unit, year, bout, startDate)
evt <- evt[!duplicated(evt, by = c("unit", "year", "bout"))]
stopifnot(!anyDuplicated(evt[, .(unit, year, bout)]))
# unit-level facts are constant per point
for (cc in c("siteID", "domainID", "plotType", "nlcdClass", "decimalLatitude", "decimalLongitude", "elevation"))
  stopifnot(evt[, uniqueN(get(cc)), by = unit][, all(V1 == 1)])

# --- detections inside the 6-min count, species rank, clusters counted once ---------------
cd <- cd[ev %in% evt$ev]
n88 <- sum(cd$pointCountMinute == "88")
rank_tab <- table(cd[targetTaxaPresent == "Y" & pointCountMinute != "88", taxonRank], useNA = "ifany")
det <- cd[targetTaxaPresent == "Y" & pointCountMinute != "88" & taxonRank == "species"]
det[, minute := as.integer(pointCountMinute)][, size := as.integer(clusterSize)]
na_size <- sum(is.na(det$size))                      # PUUM only: a detection record with no cluster size counts one individual
stopifnot(na_size == 897L, det[is.na(size), all(siteID == "PUUM")], all(det$size >= 1, na.rm = TRUE), !anyNA(det$taxonID), !anyNA(det$scientificName))
det[is.na(size), size := 1L]
det[, cl := ifelse(is.na(clusterCode) | clusterCode == "X", paste0("r", seq_len(.N)), clusterCode)]
setorder(det, ev, taxonID, cl, minute)
det <- det[!duplicated(det, by = c("ev", "taxonID", "cl"))]          # one record per cluster: its first minute
counts <- det[, .(y = sum(size), n_clusters = .N), by = .(ev, taxonID)]
sp_tot <- det[, .(n_det = .N, scientificName = scientificName[1], vernacularName = vernacularName[1]), by = taxonID][order(-n_det)]
stopifnot(sp_tot[, uniqueN(scientificName)] == nrow(sp_tot))
species <- sp_tot[n_det >= MIN_DET]
below <- sp_tot[n_det < MIN_DET]
cat(sprintf("  %d species-rank taxa; %d with >= %d clusters shipped, %d below the cut; %d minute-88 rows; ranks inside the count: %s\n",
            nrow(sp_tot), nrow(species), MIN_DET, nrow(below), n88, paste(names(rank_tab), rank_tab, collapse = ", ")))

# --- long table: every shipped species at every count --------------------------------------
periods <- data.table(year = sort(unique(evt$year)))[, period := seq_len(.N)]
evt <- merge(evt, periods, by = "year")
units <- unique(evt[, .(unit, site = siteID, domain = domainID, named_location = namedLocation, plot_type = plotType, nlcd_class = nlcdClass,
                        decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                        coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "unit")
stopifnot(nrow(units) == uniqueN(evt$unit), !anyNA(units$decimalLatitude))
base <- evt[, .(unit, period, occasion = bout, date = startDate, observer = measuredBy, unit_site = siteID,
               obs_air_temp_c = as.numeric(observedAirTemp), obs_wind_kmh = as.numeric(kmPerHourObservedWindSpeed),
               obs_cloud_pct = as.numeric(startCloudCoverPercentage), obs_rh_pct = as.numeric(startRH),
               obs_habitat = observedHabitat, ev)]
long <- base[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxonID, times = nrow(base))]
long <- merge(long, counts[taxonID %in% species$taxonID, .(ev, taxon = taxonID, y)], by = c("ev", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, ev := NULL]
stopifnot(nrow(long) == nrow(evt) * nrow(species), sum(long$y) == counts[taxonID %in% species$taxonID, sum(y)],
          !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d counts at %d points, %d sites, %d years; %d rows\n", nrow(evt), uniqueN(evt$unit), uniqueN(evt$siteID), nrow(periods), nrow(long)))

taxa <- make_taxa(species$taxonID, species$scientificName, vernacularName = species$vernacularName)
periods <- periods[, .(period, year)]
# E7 (batch 46, #10; ruling on the publisher, 2026-11-06, which withdrew the agency exception): taxa IUCN CR/EN/VU in
# their native range are in the table, so it ships with coarsened reach / plot coordinates, and neon_2026_landbirds_exact_count without them
# at NEON's published coordinates (E7 scope, 3)
NONNATIVE <- character()
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
fl_sp <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU") & !taxon %in% NONNATIVE, taxon]
stopifnot(setequal(fl_sp, c("PRBU", "LTDU", "CHSW", "PIJA", "PRNI")))
fl <- fl_sp   # E7 scope 3: the sibling drops the flagged taxa; records identified only to a higher rank stay
flag <- taxa[taxon %in% fl_sp, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  flagged:", paste(flag, collapse = "; "), "\n")
cg <- coarsen_coords(units$decimalLatitude, units$decimalLongitude, 0.1)
units_c <- copy(units)[, `:=`(decimalLatitude = cg$lat, decimalLongitude = cg$lon, coordinateUncertaintyInMeters = cg$uncertainty_m)]
if ("elevation_m" %in% names(units_c)) units_c[, elevation_m := round(elevation_m, -2)]
EXACT <- "neon_2026_landbirds_exact_count"
emit <- function(TABLE, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  ut <- if (exact) units else units_c
  nt <- nrow(tt)
  dataset <- list(
    title = paste0(sprintf("NEON breeding landbird point counts, RELEASE-2026: individuals of %d species per 6-minute count at %d points across %d NEON sites, %d-%d", nt, uniqueN(evt$unit), uniqueN(evt$siteID), min(evt$year), max(evt$year)), if (exact) " (without IUCN-threatened taxa; coordinates as published)" else ""),
    creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/v6hs-mx57",
    sourceURL = "https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026",
    citation = "NEON (National Ecological Observatory Network). Breeding landbird point counts (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57. Dataset accessed from https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026 on 2026-11-02",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("NEON's breeding landbird survey: 6-minute point counts, once or twice per breeding season, at grids of nine points (large sites) or single points (small sites) on every NEON terrestrial site, with every individual recorded by minute, distance, detection method and cluster. This table aggregates the per-detection records to the number of individuals of each species per count for the %d species with at least %d detected clusters over the release; every shipped species carries a row at every count. Unit coordinates are the point coordinates NEON publishes. Sibling table neon_2026_landbirds_ds holds the same counts as distance-bin cells.", nt, MIN_DET),
    samplingProtocol = "6-minute unlimited-radius point counts between dawn and 3.5 h after sunrise, May-July, by trained observers; each individual or cluster recorded with minute of first detection, radial distance (laser rangefinder), detection method and cluster size; one or two bouts per year (NEON TOS protocol for breeding landbird sampling)",
    samplingProtocolCode = "point_count", surveyEvidence = "sample_table",
    surveyEvidenceNote = "brd_perpoint lists every point-count event; a count exists iff samplingImpractical == OK and at least one brd_countdata row (a targetTaxaPresent = N row records a count with no detections). Species pool is national: every shipped species at every count.",
    responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasion = bout within the breeding season (1-2 counts per point per year); period = calendar year", occasionKind = "time", taxonInclusion = "recorded",
    geographicCoverage = sprintf("47 NEON terrestrial sites in 20 domains, continental USA, Alaska, Hawaii and Puerto Rico; point coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
    temporalCoverage = sprintf("%s/%s", substr(min(evt$startDate), 1, 10), substr(max(evt$startDate), 1, 10)),
    crs = "EPSG:4326 (WGS 84), as published",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("As published by NEON (coordinates with coordinateUncertaintyInMeters in __units). The IUCN-threatened taxa (%s) are not in this table (E7 scope, 3); neon_2026_landbirds_count has them, with coordinates coarsened.", paste(flag, collapse = ", "))) else
      list(value = TRUE, method = sprintf("coarsen_coords(): NEON's published coordinates in __units snapped to their 0.1-degree cell centre, uncertainty the cell half-diagonal, elevation rounded to 100 m, because taxa IUCN CR/EN/VU in their native range are in the table (%s; E7, ruling on the publisher 2026-11-06, which withdrew the agency exception). NEON site and location codes are kept: they locate a site, not a plot or reach, without NEON's own lookup. neon_2026_landbirds_exact_count keeps the other taxa at published precision.", paste(flag, collapse = ", "))),
    occasionLength = "6 minutes",
    components = list(neon_2026_landbirds_ds = "the same counts as distance-bin cells (multinomial_cell, four bins) for the species with >= 2000 clusters"),
    covariateNote = "obs_air_temp_c, obs_wind_kmh, obs_cloud_pct (start of count), obs_rh_pct (start) and obs_habitat are the observer's field records per count; end-of-count cloud and RH are not carried. Point-level facts (site, domain, NEON namedLocation, plot type, NLCD class, coordinates, coordinate uncertainty, elevation) are in __units; the core carries unit_site only, to keep an 8-figure table narrow. NEON publishes the grid centre for the nine points of a bird grid (coordinateUncertaintyInMeters ~250 m), so points of one grid share coordinates; single-point arrays carry the point itself.",
    notes = sprintf("Taxa: the %d species-rank taxa with >= %d clusters; %d species below the cut are listed in notShipped. Clusters: records sharing a clusterCode within a count and species are one cluster counted once (first minute). %d duplicated perpoint rows and %d point-year-bouts counted twice keep the first record; 5 counts whose countdata start time differs from the perpoint start time are re-keyed by point and day; %d detection records at PUUM with no clusterSize count one individual each. Period = calendar year, so a point surveyed in one bout only has one occasion that year.", nt, MIN_DET, nrow(below), nrow(dup), nrow(rep_ev), na_size),
    notShipped = c(if (exact) list(threatened = sprintf("%s; records identified only to a higher rank stay in both tables: in neon_2026_landbirds_count only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "))), list(
      `minute 88` = sprintf("%d detections outside the 6-minute count period", n88),
      `higher-rank and subspecies IDs` = paste(sprintf("%s: %d", names(rank_tab)[names(rank_tab) != "species"], rank_tab[names(rank_tab) != "species"]), collapse = "; "),
      `species below the cut` = paste(sprintf("%s (%s, %d)", below$taxonID, below$scientificName, below$n_det), collapse = "; "),
      `per-detection fields` = "pointCountMinute, observerDistance, detectionMethod, visualConfirmation, sexOrAge (aggregated to counts here; distance bins in the sibling table)",
      `events not counted` = "samplingImpractical other/logistical rows and OK rows without countdata")))
  # over 5 M rows: period parts, one per year (batch 46; the table was a single CSV before)
  ds <- write_table_parts(as.list(periods$period), function(pp) lt[period %in% pp], TABLE, dataset, taxa = tt, periods = periods,
                          units = ut, script = "data/neon_2026_landbirds_count.R")

  stage_dict_row(TABLE,
    description = sprintf("Number of individuals of %d bird species per 6-minute point count at %d points on 47 NEON terrestrial sites, %d-%d (one or two bouts per breeding season), built from NEON's per-detection records (RELEASE-2026) with observer, date-time, weather and habitat per count and point coordinates as published.", nt, uniqueN(evt$unit), min(evt$year), max(evt$year)),
    url = "https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026",
    reference = "NEON (National Ecological Observatory Network). Breeding landbird point counts (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57",
    doi_paper = "", doi_data = "10.48443/v6hs-mx57",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = sprintf("Token-gated NEON API (NEON_TOKEN); release pinned. National species pool (>= %d clusters); fuzzed higher-rank IDs and minute-88 detections not shipped. Sibling: neon_2026_landbirds_ds.", MIN_DET),
    source_via = "NEON Data API, basic package")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
    sampling_protocol = "point_count", design = sprintf("Multi-season (%d years x 1-2 bouts)", nrow(periods)), realm = "Terrestrial", country = "USA",
    coordinates = if (exact) "As published" else "Coarsened (0.1 deg)", notes = "NEON national scheme; counts from per-detection records; every species at every count.",
    status = "tagged")
}
emit("neon_2026_landbirds_count", exact = FALSE)
emit(EXACT, exact = TRUE)
