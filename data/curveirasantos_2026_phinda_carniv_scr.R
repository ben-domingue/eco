#!/usr/bin/env Rscript
# Tables: curveirasantos_2026_phinda_leopard_scr, curveirasantos_2026_phinda_cheetah_scr,
#         curveirasantos_2026_phinda_lion_scr, curveirasantos_2026_phinda_hyena_scr,
#         curveirasantos_2026_phinda_genet_scr, curveirasantos_2026_phinda_serval_scr
#         (one script, six tables: one camera array, one season, one species each, following
#         ruling #20 and the Lazenby precedent)
# Source: OSF project https://osf.io/y3w6f/ (doi:10.17605/OSF.IO/Y3W6F), "Data and Code for:
#         Optimizing Camera-Trap Survey Designs for Multi-Species Density Estimation Using
#         Spatial Capture-Recapture Models", created 2025-06-05, modified 2025-12-09.
#         Licence shown on the project: CC-By Attribution 4.0 International.
#         Contributors: Goncalo Curveira-Santos, Gates Dupont, Chris Sutherland, Laura Gigliotti.
# Paper:  Curveira-Santos, G., Dupont, G., Sutherland, C., Pretorius, C., Naylor, S., Allan, K. &
#         Gigliotti, L. C. (2026). Optimizing camera-trap survey designs for multi-species density
#         estimation using spatial capture-recapture models. Journal of Applied Ecology 63(1).
#         doi:10.1111/1365-2664.70261 (Wiley; bronze open access but the publisher blocks the
#         agent, so design facts below come from the deposit, its R code and the abstract).
# Data:   data/ folder: six detection files <species>_detections_grid21.csv, one row per
#         identified detection (Animal_ID, Site, Date d/m/Y, and depending on species Side =
#         flank photographed (both/left/right), Sex, Group = pride or coalition);
#         MYW2021_cam_op_site_effort_UTM.csv: 100 camera sites (Site, UTM_x, UTM_y, Half
#         North/South, Brand, Grid_Allocation Leopard/Small) x 117 daily columns 9/17/21 to
#         1/11/22 with 1 = operating, 0 = deployed but not operating, NA = not deployed;
#         MYW_grid_cam_allocation.csv: Site x Grid_type (same as Grid_Allocation, asserted).
#         output/ (simulation results, fitted null models) and R/ (oSCR fitting and simulation
#         code) are analysis inputs and outputs; spatial/ is the reserve fence shapefile (the
#         SCR state space). The authors' fit_null_models.R reads exactly these files:
#         occasion = day since 2021-09-17, trap operation NA -> 0, oSCR data2oscr().
#         Design (abstract + code): Munywana Conservancy (Phinda), KwaZulu-Natal, South Africa;
#         60 cameras placed for leopards plus 40 for small-bodied carnivores (a two-stage
#         optimised design), one season Sept 2021 to Jan 2022, six individually identifiable
#         carnivores.
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture):
#   unit = individual (the deposit's Animal_ID), trap = camera site (MYW01..MYW100),
#   occasion = survey day 1..117 from 2021-09-17 (the authors' Occasion), date = that day,
#   y = 1 if the individual was photographed at that site on that day else 0; one period.
#   Survey evidence = effort_table: a site-day is surveyed iff the operation matrix is 1
#   (4,470 of 11,700 site-days; 0 and NA are not surveyed). Every detection falls on an
#   operating site-day (asserted). Each individual carries the full rectangle of surveyed
#   site-days (the batch 5 SCR convention).
#   y_raw = number of records that day (lions only: three individual-site-days have two
#   records; every other species has at most one, so no y_raw column there).
#   obs_side = flank(s) photographed on detection rows (both / left / right), NA otherwise;
#   unit_identity (E2 partial identity) = the flanks from which the individual is identified:
#   "left" or "right" when every record of the id is that flank, else "both"; a left- or
#   right-only id may be the same animal as another single-flank id of the opposite side (the
#   authors used the ids as deposited; genets are mostly single-flank). Cheetah records carry no
#   Side column (identified from coat pattern with sex and coalition), so that table has no
#   unit_identity: the deposit gives no sign of one-sided ids.
#   At-risk span (E4.4): one closed session (no period), so every individual carries every
#   surveyed camera-day; no never-detected ids (every id comes from a detection).
#   unit_sex (leopard, cheetah, lion), unit_group (cheetah coalition, lion pride) as deposited.
#   __traps: trap, x_m, y_m = UTM 36S easting/northing CENTRED on the array centroid by the
#   processor (local metres), half, brand, grid_allocation, n_days_operating. Leopard, cheetah
#   and lion are IUCN VU, so under E7 the exact coordinates are not shipped; centring keeps
#   the inter-trap geometry an SCR needs (a 0.1 degree grid would collapse 100 cameras into
#   a handful of cells) while withholding the absolute positions, and the same trap table
#   serves all six tables. The array centroid is given at 0.1 degree in geographicCoverage.
#   Taxa: the genet is identified only as "genet" in the deposit; shipped at genus rank
#   (Genetta, GBIF exact genus match) with taxonRemarks: Phinda holds the large-spotted genet
#   complex, not separated in the deposit.
#   NOT shipped: output/ (simulation designs and results, fitted null models), R/ code,
#   spatial/ fence (analysis state space), MYW_grid_cam_allocation.csv (duplicate of the
#   Grid_Allocation column, asserted identical).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/curveirasantos_2026_phinda_carniv_scr.R"
CACHE <- "curveirasantos_2026_phinda_scr"
OSF <- c(genet_detections_grid21.csv = "rtfze", cheetah_detections_grid21.csv = "y84gh",
         leopard_detections_grid21.csv = "aw8yu", lion_detections_grid21.csv = "c7x4q",
         hyena_detections_grid21.csv = "eyrmh", serval_detections_grid21.csv = "p3y7c",
         MYW_grid_cam_allocation.csv = "4x879", MYW2021_cam_op_site_effort_UTM.csv = "gkhsv")
files <- sapply(names(OSF), function(n) download_cached(paste0("https://osf.io/download/", OSF[[n]], "/"), CACHE, n))

utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM, southern hemisphere handled by the caller
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  lon0 <- (zone - 1) * 6 - 180 + 3
  list(lat = lat * 180 / pi, lon = lon0 + lon * 180 / pi)
}

# ---- camera operation: the survey set -------------------------------------------------
op <- fread(files[["MYW2021_cam_op_site_effort_UTM.csv"]])
stopifnot(nrow(op) == 100, ncol(op) == 123, identical(names(op)[1:6], c("Site", "UTM_x", "UTM_y", "Half", "Brand", "Grid_Allocation")),
          !anyDuplicated(op$Site), all(grepl("^MYW\\d{2,3}$", op$Site)),
          all(op$Half %in% c("North", "South")), all(op$Brand %in% c("Cuddeback", "Spartan")),
          all(op$Grid_Allocation %in% c("Leopard", "Small")), sum(op$Grid_Allocation == "Leopard") == 60,
          all(op$UTM_x > 4.1e5 & op$UTM_x < 4.5e5), all(op$UTM_y > 6.91e6 & op$UTM_y < 6.94e6))   # UTM 36S, KwaZulu-Natal
alloc <- fread(files[["MYW_grid_cam_allocation.csv"]])
stopifnot(nrow(alloc) == 100, identical(alloc[match(op$Site, Site), Grid_type], op$Grid_Allocation))
day_cols <- names(op)[7:ncol(op)]
days <- as.Date(day_cols, format = "%m/%d/%y")
DAY1 <- as.Date("2021-09-17")
stopifnot(!anyNA(days), length(days) == 117, all(days == seq(DAY1, by = "day", length.out = 117)))
m <- as.matrix(op[, ..day_cols])
stopifnot(all(m %in% c(0, 1) | is.na(m)), sum(m == 1, na.rm = TRUE) == 4470, sum(m == 0, na.rm = TRUE) == 323)
surveyed <- data.table(trap = rep(op$Site, times = ncol(m)), occasion = rep(seq_along(days), each = nrow(m)),
                       date = rep(days, each = nrow(m)), on = as.vector(m))[on == 1, .(trap, occasion, date = format(date))]
stopifnot(nrow(surveyed) == 4470)
n_days <- surveyed[, .N, by = trap]
stopifnot(sum(!(op$Site %in% n_days$trap)) == 1, setdiff(op$Site, n_days$trap) == "MYW43")  # one camera never operated
cat(sprintf("  100 cameras, 117 days (%s to %s), %d surveyed camera-days; MYW43 never operated\n", min(days), max(days), nrow(surveyed)))

# traps: centred local metres (E7: VU taxa share the array), with the WGS 84 centroid for the metadata
cx <- mean(op$UTM_x); cy <- mean(op$UTM_y)
ctr <- utm_to_ll(cx, cy - 1e7, zone = 36)
stopifnot(ctr$lat < -27 & ctr$lat > -29, ctr$lon > 31.5 & ctr$lon < 33)
ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
traps <- op[, .(trap = Site, x_m = round(UTM_x - cx, 1), y_m = round(UTM_y - cy, 1), half = Half, brand = Brand,
                grid_allocation = Grid_Allocation)]
traps <- merge(traps, n_days[, .(trap, n_days_operating = N)], by = "trap", all.x = TRUE)[is.na(n_days_operating), n_days_operating := 0L]
setorder(traps, trap)
stopifnot(abs(mean(traps$x_m)) < 1, abs(mean(traps$y_m)) < 1, max(abs(traps$x_m)) < 15000, max(abs(traps$y_m)) < 15000)

# ---- species -------------------------------------------------------------------------
SP <- list(
  leopard = list(table = "curveirasantos_2026_phinda_leopard_scr", taxon = "PANPAR", sci = "Panthera pardus", vern = "Leopard", iucn = "VU", rank = "species", n_rows = 254L, n_ids = 48L, n_dup = 0L),
  cheetah = list(table = "curveirasantos_2026_phinda_cheetah_scr", taxon = "ACIJUB", sci = "Acinonyx jubatus", vern = "Cheetah", iucn = "VU", rank = "species", n_rows = 20L, n_ids = 6L, n_dup = 0L),
  lion    = list(table = "curveirasantos_2026_phinda_lion_scr",    taxon = "PANLEO", sci = "Panthera leo", vern = "Lion", iucn = "VU", rank = "species", n_rows = 141L, n_ids = 21L, n_dup = 3L),
  hyena   = list(table = "curveirasantos_2026_phinda_hyena_scr",   taxon = "CROCRO", sci = "Crocuta crocuta", vern = "Spotted hyaena", iucn = "LC", rank = "species", n_rows = 195L, n_ids = 51L, n_dup = 0L),
  genet   = list(table = "curveirasantos_2026_phinda_genet_scr",   taxon = "GENSPP", sci = "Genetta", vern = "Genet (large-spotted genet complex)", iucn = NA_character_, rank = "genus", n_rows = 614L, n_ids = 301L, n_dup = 0L),
  serval  = list(table = "curveirasantos_2026_phinda_serval_scr",  taxon = "LEPSER", sci = "Leptailurus serval", vern = "Serval", iucn = "LC", rank = "species", n_rows = 33L, n_ids = 11L, n_dup = 0L))
OTHERS <- function(t) paste(setdiff(sapply(SP, `[[`, "table"), t), collapse = ", ")

build <- function(sp) {
  s <- SP[[sp]]
  d <- fread(files[[paste0(sp, "_detections_grid21.csv")]], colClasses = "character")
  stopifnot(nrow(d) == s$n_rows, uniqueN(d$Animal_ID) == s$n_ids, all(c("Animal_ID", "Site", "Date") %in% names(d)),
            all(d$Site %in% op$Site))
  d[, date := as.Date(Date, format = "%d/%m/%Y")]
  stopifnot(!anyNA(d$date), all(d$date >= DAY1), all(d$date <= max(days)))
  d[, occasion := as.integer(date - DAY1) + 1L]
  # every detection on an operating camera-day
  stopifnot(all(m[cbind(match(d$Site, op$Site), d$occasion)] == 1))
  dup <- d[, .N, by = .(Animal_ID, Site, occasion)][N > 1]
  stopifnot(nrow(dup) == s$n_dup)
  if ("Side" %in% names(d)) stopifnot(all(d$Side %in% c("both", "left", "right")))
  if ("Sex" %in% names(d)) stopifnot(all(d$Sex %in% c("F", "M", "U")), d[, uniqueN(Sex), by = Animal_ID][, all(V1 == 1)])
  if ("Group" %in% names(d)) stopifnot(d[, uniqueN(Group), by = Animal_ID][, all(V1 == 1)])

  det <- d[, .(y_raw = .N, obs_side = if ("Side" %in% names(d)) paste(sort(unique(Side)), collapse = "/") else NA_character_),
           by = .(unit = Animal_ID, trap = Site, occasion)]
  ind <- unique(d[, .(unit = Animal_ID)])
  if ("Sex" %in% names(d)) ind <- merge(ind, unique(d[, .(unit = Animal_ID, unit_sex = Sex)]), by = "unit")
  if ("Group" %in% names(d)) ind <- merge(ind, unique(d[, .(unit = Animal_ID, unit_group = fifelse(Group == "", NA_character_, Group))]), by = "unit")
  if ("Side" %in% names(d)) ind <- merge(ind, d[, .(unit_identity = if (all(Side == "left")) "left" else if (all(Side == "right")) "right" else "both"),
                                                by = .(unit = Animal_ID)], by = "unit")
  stopifnot(nrow(ind) == s$n_ids)

  # the rectangle: individual x surveyed camera-days
  long <- surveyed[rep(seq_len(.N), times = nrow(ind))]
  long[, unit := rep(ind$unit, each = nrow(surveyed))]
  long <- merge(long, det, by = c("unit", "trap", "occasion"), all.x = TRUE)
  long[, y := as.integer(!is.na(y_raw))]
  stopifnot(nrow(long) == nrow(ind) * 4470, sum(long$y) == nrow(det), sum(long$y_raw, na.rm = TRUE) == nrow(d))
  if (s$n_dup == 0) long[, y_raw := NULL] else long[is.na(y_raw), y_raw := 0L]
  if (!"Side" %in% names(d)) long[, obs_side := NULL]
  long <- merge(long, ind, by = "unit")
  long[, taxon := s$taxon]
  long <- order_eco(long)
  cat(sprintf("  %s: %d individuals, %d detections (%d records), %d rows\n", sp, nrow(ind), nrow(det), nrow(d), nrow(long)))

  taxa <- make_taxa(s$taxon, s$sci, vernacularName = s$vern, taxonRank = s$rank, taxon_iucnCategory = s$iucn,
                    taxonRemarks = if (sp == "genet") "Recorded only as 'genet' in the deposit; the Phinda genets are the large-spotted genet complex (Genetta tigrina / G. maculata), not separated, so the taxon is the genus" else NA_character_)
  stopifnot(!is.na(taxa$taxonID))
  dataset <- list(
    title = sprintf("Spatial capture-recapture of %s (%s) at 99 operating camera traps (100 deployed) in the Munywana Conservancy, South Africa, Sept 2021 to Jan 2022", tolower(s$vern), s$sci),
    creator = "Curveira-Santos, Goncalo; Dupont, Gates; Sutherland, Chris; Gigliotti, Laura",
    pubDate = "2025", doi = "10.17605/OSF.IO/Y3W6F", sourceURL = "https://osf.io/y3w6f/",
    citation = "Curveira-Santos, G., Dupont, G., Sutherland, C., & Gigliotti, L. (2025). Data and Code for: Optimizing Camera-Trap Survey Designs for Multi-Species Density Estimation Using Spatial Capture-Recapture Models. OSF. https://doi.org/10.17605/OSF.IO/Y3W6F",
    paperDOI = "10.1111/1365-2664.70261",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/legalcode"),
    abstract = sprintf("Daily camera-trap detections of individually identified %s (%s) at 100 camera sites (99 operated; MYW43 never did) in the Munywana Conservancy (Phinda), KwaZulu-Natal, South Africa, 17 September 2021 to 11 January 2022: 60 cameras placed for leopards and 40 for small-bodied carnivores by the authors' two-stage design optimisation. One row per individual x operating camera-day; the deposited camera operation matrix is the survey set. Sibling tables for the other five identifiable carnivores of the same survey: %s. Trap coordinates are centred on the array (local metres) because three of the six species are IUCN Vulnerable.",
                       tolower(s$vern), s$sci, OTHERS(s$table)),
    samplingProtocol = "Paired or single camera traps at 100 sites (Cuddeback and Spartan), checked over 117 calendar days; individuals identified from coat pattern (flank recorded as both / left / right where applicable), lions and cheetahs also by pride or coalition. Detection history is individual x camera x day.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
    surveyEvidenceNote = "MYW2021_cam_op_site_effort_UTM.csv gives each camera site x day as 1 (operating), 0 (deployed, not operating) or NA (not deployed); a camera-day is surveyed iff 1 (4,470 of 11,700). Every detection falls on an operating camera-day. MYW43 never operated and has no rows.",
    responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (one season, Sept 2021 to Jan 2022, treated as closed by the authors)", occasionKind = "time", taxonInclusion = "single",
    geographicCoverage = sprintf("Munywana Conservancy (Phinda Private Game Reserve), KwaZulu-Natal, South Africa; camera array centroid %.1f, %.1f (0.1 degree); trap positions in __traps as local metres centred on the array", ctr_c$lat, ctr_c$lon),
    temporalCoverage = "2021-09-17/2022-01-11",
    crs = "local: metres, UTM 36S (EPSG:32736) easting/northing minus the array centroid (processor-centred)",
    coordinatesCoarsened = list(value = TRUE, method = "trap coordinates centred on the array centroid by the processor (local metres; exact UTM 36S positions withheld) because leopard, cheetah and lion (IUCN VU) share the one camera array; the centroid is given at 0.1 degree in geographicCoverage"),
    designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Closed population, one session; occasion = calendar day as in the authors' oSCR code (they collapse occasions to counts with effort). One species per table (ruling #20); the six tables share traps and survey set.",
    notes = if (sp == "genet") "The deposit identifies the species only as 'genet'; shipped at genus rank (Genetta). 237 of 301 genet ids are single-flank (unit_identity left or right), so two ids may be one animal; the authors used the ids as deposited." else
            if (sp == "lion") "Three individual-camera-days carry two records (y_raw = 2). unit_group is the pride or coalition as deposited." else
            if (sp == "cheetah") "Six individuals; two have no group recorded (unit_group NA). Below the sample floor; shipped as a sibling of the other five species." else
            "unit_identity = the flanks from which the individual is identified (both / left / right); single-flank ids may duplicate an animal recorded on the other flank.",
    notShipped = list(`output/` = "simulation designs, simulation results (out_df_1..6.csv) and fitted oSCR null models: analysis outputs",
                      `R/` = "the authors' oSCR fitting and simulation code",
                      `spatial/Full_Phinda_2018_UTM.*` = "reserve fence shapefile, the SCR state space (analysis input)",
                      MYW_grid_cam_allocation.csv = "identical to the Grid_Allocation column of the operation file (asserted); in __traps",
                      exact_coordinates = "UTM 36S trap positions withheld (VU taxa); __traps carries them centred on the array"))
  ds <- write_table(long, s$table, dataset, taxa = taxa, traps = traps, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("Spatial capture-recapture histories of %s (%s) at 99 operating camera sites (100 deployed) in the Munywana Conservancy, South Africa, 17 Sept 2021 to 11 Jan 2022, individual x camera x day on the deposited operation matrix; trap coordinates centred on the array (local metres). One of six sibling tables from a multi-species design-optimisation study.", tolower(s$vern), s$sci),
    url = "https://osf.io/y3w6f/",
    reference = "Curveira-Santos, G., Dupont, G., Sutherland, C., Pretorius, C., Naylor, S., Allan, K., & Gigliotti, L. C. (2026). Optimizing camera-trap survey designs for multi-species density estimation using spatial capture-recapture models. Journal of Applied Ecology, 63(1).",
    doi_paper = "10.1111/1365-2664.70261", doi_data = "10.17605/OSF.IO/Y3W6F",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = sprintf("SCR (E9 experimental): trap key + __traps in processor-centred local metres (VU taxa on the array). %s One script writes six species tables.",
                    if (sp == "genet") "Genus-rank taxon; mostly single-flank ids." else if (sp == "cheetah") "Below floor (6 individuals)." else ""),
    source_via = "OSF (osfstorage files)")
  stage_tag_row(s$table, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed, camera traps)",
    sampling_protocol = "camera_trap", design = "Single-season (117 daily occasions, 99 operating cameras of 100, one array)", realm = "Terrestrial",
    country = "ZAF", coordinates = "Coarsened (trap coordinates centred on the array, local metres; VU taxa)",
    notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle of surveyed camera-days. Six sibling tables share traps and survey set.")
  invisible(ds)
}

for (sp in names(SP)) build(sp)
