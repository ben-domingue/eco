#!/usr/bin/env Rscript
# Table:  neon_2026_landbirds_ds
# Source: NEON (National Ecological Observatory Network). Breeding landbird point counts
#         (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57. Dataset accessed
#         from https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026 on
#         2026-11-02 through the NEON Data API (token-gated; NEON_TOKEN environment variable).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data
#         products and sample data are licensed under a Creative Commons Attribution 4.0
#         International License (CC-BY)"). Sibling table of neon_2026_landbirds_count, built
#         from the same cached download (see that script's header for the files).
# Data:   brd_perpoint (one row per point-count event) and brd_countdata (one row per
#         detection record: pointCountMinute 1-6 or 88, taxonID, taxonRank, observerDistance
#         in metres from a laser rangefinder, clusterSize, clusterCode linking the records of
#         one cluster across minutes). Distances are continuous (0-999 m; median 71, 99th
#         percentile 426); 0.3% of clusters have no distance.
# Mapping (standard E9 core: binned point-transect distance sampling, multi-species):
#   unit = point "<plotID>_<pointID>"; period = count event index (year x bout, in
#   __periods, ordered in time); occasion = radial-distance bin 1-4 with y_raw the label;
#   y = number of clusters of the species first detected in that bin inside the 6-min
#   count, obs_individuals = individuals in those clusters; obs_* weather as in the count
#   table; __units as in the count table. BREAKS 0, 25, 50, 100, 1000 m: the 100 m truncation
#   NEON's own analyses use plus one wide bin to the furthest record, so no detection is
#   dropped; binning continuous distances is a processing decision (precedent
#   bedson_2021_holmemoss_hare_vis_ds). Removal (minute) information is not carried: one
#   cell index per table. Species: the species-rank taxa with >= MIN_DET clusters (2000),
#   every one at every count, which keeps the table under 5 million rows; the count
#   table carries 283 species. Survey evidence = sample_table (brd_perpoint, as in the
#   count table). Not shipped: clusters without a distance, minute-88 detections,
#   higher-rank ("fuzzed") IDs, species below the cut, pointCountMinute, detectionMethod.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_landbirds_ds"; CACHE_AS <- "neon_2026_landbirds_count"
PRODUCT <- "DP1.10003.001"; RELEASE <- "RELEASE-2026"; MIN_DET <- 2000L
BREAKS <- c(0, 25, 50, 100, 1000); BINS <- c("0-25 m", "25-50 m", "50-100 m", "100-1000 m")
nx <- download_neon(PRODUCT, CACHE_AS, RELEASE, tables = c("brd_perpoint", "brd_countdata"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 483L,
          identical(attr(nx, "productDoi"), "https://doi.org/10.48443/v6hs-mx57"))
pp <- nx$brd_perpoint; cd <- nx$brd_countdata
stopifnot(nrow(pp) == 27076, nrow(cd) == 373518, uniqueN(pp$siteID) == 47, !anyNA(pp$decimalLatitude),
          all(pp$boutNumber %in% c("1", "2")), all(cd$pointCountMinute %in% c(as.character(1:6), "88")))

# --- events, exactly as in neon_2026_landbirds_count.R ------------------------------------
pp[, unit := paste(plotID, pointID, sep = "_")][, ev := paste(unit, startDate)]
pp <- pp[!duplicated(ev)]
cd[, unit := paste(plotID, pointID, sep = "_")][, ev := paste(unit, startDate)]
cd[, day := substr(startDate, 1, 10)]; pp[, day := substr(startDate, 1, 10)]
one_per_day <- pp[, .N, by = .(unit, day)][N == 1, .(unit, day)]
fix <- merge(unique(cd[!ev %in% pp$ev, .(unit, day, ev_bad = ev)]), merge(one_per_day, pp[, .(unit, day, ev_pp = ev)], by = c("unit", "day")), by = c("unit", "day"))
cd[fix, on = .(ev = ev_bad), ev := i.ev_pp]
stopifnot(all(cd$ev %in% pp$ev), nrow(fix) == 5)
evt <- pp[samplingImpractical == "OK" & ev %in% cd$ev]
evt[, year := as.integer(substr(startDate, 1, 4))][, bout := as.integer(boutNumber)]
setorder(evt, unit, year, bout, startDate)
evt <- evt[!duplicated(evt, by = c("unit", "year", "bout"))]
stopifnot(nrow(evt) == 26363, uniqueN(evt$unit) == 3434)

# --- clusters inside the 6-min count, species rank, one record per cluster ---------------
cd <- cd[ev %in% evt$ev]
det <- cd[targetTaxaPresent == "Y" & pointCountMinute != "88" & taxonRank == "species"]
det[, minute := as.integer(pointCountMinute)][, size := as.integer(clusterSize)][, dist := as.numeric(observerDistance)]
det[is.na(size), size := 1L]                                     # PUUM records without a cluster size (897)
det[, cl := ifelse(is.na(clusterCode) | clusterCode == "X", paste0("r", seq_len(.N)), clusterCode)]
setorder(det, ev, taxonID, cl, minute)
det <- det[!duplicated(det, by = c("ev", "taxonID", "cl"))]     # a cluster is dated and placed by its first record
n_nodist <- sum(is.na(det$dist))
stopifnot(all(det$dist >= 0, na.rm = TRUE), max(det$dist, na.rm = TRUE) < 1000)
sp_tot <- det[, .(n_det = .N, scientificName = scientificName[1], vernacularName = vernacularName[1]), by = taxonID][order(-n_det)]
species <- sp_tot[n_det >= MIN_DET]; below <- sp_tot[n_det < MIN_DET]
n_nodist_sp <- det[taxonID %in% species$taxonID, sum(is.na(dist))]
det <- det[taxonID %in% species$taxonID & !is.na(dist)]
det[, bin := as.integer(cut(dist, BREAKS, include.lowest = TRUE, right = TRUE))]
stopifnot(!anyNA(det$bin), all(det$bin %in% 1:4))
cat(sprintf("  %d species-rank taxa, %d with >= %d clusters shipped; %d clusters without a distance (%d of the shipped species) dropped\n",
            nrow(sp_tot), nrow(species), MIN_DET, n_nodist, n_nodist_sp))
cells <- det[, .(y = .N, individuals = sum(size)), by = .(ev, taxonID, bin)]

# --- long table: every shipped species x every count x four bins --------------------------
periods <- unique(evt[, .(year, bout)])[order(year, bout)][, period := seq_len(.N)]
evt <- merge(evt, periods, by = c("year", "bout"))
stopifnot(!anyDuplicated(evt[, .(unit, period)]))
units <- unique(evt[, .(unit, site = siteID, domain = domainID, named_location = namedLocation, plot_type = plotType, nlcd_class = nlcdClass,
                        decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                        coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "unit")
base <- evt[, .(unit, period, date = startDate, observer = measuredBy, unit_site = siteID,
                obs_air_temp_c = as.numeric(observedAirTemp), obs_wind_kmh = as.numeric(kmPerHourObservedWindSpeed),
                obs_cloud_pct = as.numeric(startCloudCoverPercentage), obs_rh_pct = as.numeric(startRH), obs_habitat = observedHabitat, ev)]
grid <- CJ(ev = base$ev, taxon = species$taxonID, occasion = 1:4)
long <- merge(grid, base, by = "ev")
long <- merge(long, cells[, .(ev, taxon = taxonID, occasion = bin, y, obs_individuals = individuals)], by = c("ev", "taxon", "occasion"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_individuals = 0L)]
long[, y_raw := BINS[occasion]][, ev := NULL]
stopifnot(nrow(long) == nrow(evt) * nrow(species) * 4L, sum(long$y) == nrow(det), sum(long$obs_individuals) == sum(det$size),
          !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d counts at %d points, %d year-bout periods; %d rows, %d clusters, %d individuals\n",
            nrow(evt), uniqueN(evt$unit), nrow(periods), nrow(long), nrow(det), sum(det$size)))

taxa <- make_taxa(species$taxonID, species$scientificName, vernacularName = species$vernacularName)
periods <- periods[, .(period, year, bout)]
dataset <- list(
  title = sprintf("NEON breeding landbird point counts, RELEASE-2026, as distance-sampling cells: clusters of %d common species in four radial-distance bins per 6-minute count at %d points across 47 NEON sites, %d-%d", nrow(species), uniqueN(evt$unit), min(evt$year), max(evt$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/v6hs-mx57",
  sourceURL = "https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026",
  citation = "NEON (National Ecological Observatory Network). Breeding landbird point counts (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57. Dataset accessed from https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026 on 2026-11-02",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's breeding landbird point counts record the radial distance (laser rangefinder) of every detected individual or cluster. This table bins those distances to four cells (0-25, 25-50, 50-100, 100-1000 m) per count for the %d species with at least %d detected clusters over the release: y = clusters first detected in the bin, obs_individuals = individuals in them, every shipped species at every count. The sibling table neon_2026_landbirds_count carries the per-count totals for 283 species.", nrow(species), MIN_DET),
  samplingProtocol = "6-minute unlimited-radius point counts between dawn and 3.5 h after sunrise, May-July, by trained observers; each individual or cluster recorded with minute of first detection, radial distance (laser rangefinder), detection method and cluster size; one or two bouts per year (NEON TOS protocol for breeding landbird sampling)",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table",
  surveyEvidenceNote = "brd_perpoint lists every point-count event; a count exists iff samplingImpractical == OK and at least one brd_countdata row. Species pool is national: every shipped species at every count.",
  responseType = "multinomial_cell", distanceBreaks = BREAKS, distanceUnits = "m", transectType = "point",
  unitKind = "site", closure = "closed", closureNote = "occasion = distance bin of one count; period = the count event (year x bout), 1-2 per point per year", occasionKind = "cell", taxonInclusion = "recorded",
  geographicCoverage = sprintf("47 NEON terrestrial sites in 20 domains, continental USA, Alaska, Hawaii and Puerto Rico; point coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(evt$startDate), 1, 10), substr(max(evt$startDate), 1, 10)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = "As published by NEON (agency-published point coordinates); no coarsening. Species of concern are already reported by NEON at a higher taxonomic rank ('fuzzed') or withheld at some sites, and those records are not shipped"),
  occasionLength = "6 minutes (the count); occasion indexes the distance bin",
  components = list(neon_2026_landbirds_count = "per-count individuals of 283 species (count), same events and units"),
  covariateNote = "obs_individuals = individuals in the bin's clusters; obs_air_temp_c, obs_wind_kmh, obs_cloud_pct, obs_rh_pct, obs_habitat per count; point-level facts in __units. NEON publishes the grid centre for the nine points of a bird grid (coordinateUncertaintyInMeters ~250 m), so points of one grid share coordinates; single-point arrays carry the point itself.",
  notes = sprintf("Distances are deposited to the metre and binned here (0, 25, 50, 100, 1000 m); drop occasion 4 to truncate at 100 m. A cluster is placed by its first record (clusterCode across minutes). Period is the count event (year x bout), so a dynamic model by year needs __periods$year. %d clusters of the shipped species had no recorded distance and are dropped. Removal-sampling information (pointCountMinute) is not carried.", n_nodist_sp),
  notShipped = list(
    `clusters without a distance` = sprintf("%d of the shipped species (%d over all species)", n_nodist_sp, n_nodist),
    `species below the cut` = sprintf("%d species with fewer than %d clusters (in the count table when >= 100)", nrow(below), MIN_DET),
    `per-detection fields` = "pointCountMinute, detectionMethod, visualConfirmation, sexOrAge",
    `minute 88, higher-rank IDs, uncounted events` = "as in neon_2026_landbirds_count"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/neon_2026_landbirds_ds.R")

stage_dict_row(TABLE,
  description = sprintf("Clusters of %d common bird species in four radial-distance bins (0-25, 25-50, 50-100, 100-1000 m) per 6-minute point count at %d points on 47 NEON terrestrial sites, %d-%d, with individuals per bin, observer, date-time, weather and habitat; built from NEON's per-detection distances (RELEASE-2026). Sibling of neon_2026_landbirds_count.", nrow(species), uniqueN(evt$unit), min(evt$year), max(evt$year)),
  url = "https://data.neonscience.org/data-products/DP1.10003.001/RELEASE-2026",
  reference = "NEON (National Ecological Observatory Network). Breeding landbird point counts (DP1.10003.001), RELEASE-2026. https://doi.org/10.48443/v6hs-mx57",
  doi_paper = "", doi_data = "10.48443/v6hs-mx57",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = sprintf("Continuous distances binned by the processor (4 bins); species with >= %d clusters only; period = count event. Token-gated NEON API; release pinned.", MIN_DET),
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Distance sampling (point transect, 4 bins; multi-species)",
  sampling_protocol = "point_count", design = sprintf("Multi-season (%d year-bout events)", nrow(periods)), realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "Occasion = distance bin; period = count event. Common species only. Sibling: neon_2026_landbirds_count.",
  status = "tagged")
