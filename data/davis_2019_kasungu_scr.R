#!/usr/bin/env Rscript
# Tables: davis_2019_kasungu_leopard_scr, davis_2019_kasungu_hyaena_scr (one script, two species tables, ruling #20)
# Source: Zenodo 10.5281/zenodo.3540503, "Spatial partial identity model for spatial capture-recapture analysis of
#         large carnivores in Kasungu National Park, Malawi" (Davis, R. S.), published 2019-11-13, licence CC BY 4.0
#         (as shown on Zenodo).
# Paper:  Davis, R. S., Stone, E., Gentle, L., Mgoola, W. O., Uzal, A. & Yarnell, R. W. (2020). Spatial partial
#         identity model reveals low densities of leopard and spotted hyaena in a miombo woodland. Journal of Zoology,
#         doi:10.1111/jzo.12838 (not read; design from the Zenodo methods text and the files).
# Data:   Camera-trap surveys in Kasungu National Park, one each year 2016, 2017, 2018; "each day (24 hours) treated as a
#         separate sampling occasion"; "trap effort was measured through a binary matrix of active-inactive days".
#         tdf_2016/2017/2018.csv: trap_ID, X, Y (UTM 36S metres) and one 0/1 column per day (90, 120, 90 days); 17, 50
#           and 25 traps; 92 distinct trap ids over the three years, each with one position (asserted).
#         Leopard_SPIM_<year>.csv: SESSION, ANIMAL_ID, SO (day), LOC_ID (trap), SEX, SIDE (L / R flank photographed).
#         Hyaena_SPIM_<year>.csv: Session, ID, Occasion, trapID, Side (no sex: hyaenas were not sexed).
#         Leopard_flank_ID.csv (54 ids: Animal_ID, Sex, Left Flank, Right Flank = Y when that flank is known) and
#         Hyaena_flank_ID.csv (50 ids, no Sex): the catalogue; ids are shared across the three years (one catalogue).
#           Individuals were identified from left flanks; "complete identities were added where flanks were certain
#           to come from the same individual". A right-only id may be the same animal as a left-only id.
#         process leopard.R, process hyaena.R: the authors' SPIM fitting code.
# Mapping (standard E9 experimental: spatial capture-recapture, multi-session):
#   unit = individual (catalogue id, prefixed L / H), trap = camera trap id, period = survey year 1..3 (2016..2018),
#   occasion = day within the year's survey (1..90 / 1..120 / 1..90), y = 1 if the individual was photographed at the
#   trap that day. Survey evidence: effort_table (a trap-day is surveyed iff the tdf matrix is 1). Every detection
#   falls on an active trap-day except one leopard record (2017, id 42, trap B20, day 16), where the matrix says the
#   camera was inactive: the photograph is believed (a camera that took a dated photograph was working) and that
#   trap-day is added to the survey set for both tables.
#   At-risk span (E4.4): individuals are wild adults of unknown age, so each detected individual carries every
#   surveyed trap-day of all three years; catalogue ids never detected have no rows.
#   unit_identity (E2 partial identity): both / left / right from the catalogue's flank columns; every record of a
#   one-flank id is of that flank (asserted). obs_side = flank photographed (left / right) on detection rows, NA
#   otherwise. unit_sex (leopard): F / M from the catalogue, NA for "N/A".
#   __traps: trap, x_m, y_m = UTM 36S easting/northing CENTRED on the mean trap position by the processor. Leopard is
#   IUCN VU (E7, trap arrays): exact positions are withheld; the hyaena table shares the same trap key and array, so
#   it carries the same centred positions (as for the Phinda tables). The array centre is given at 0.1 degree.
#   Not shipped: the SPIM scripts; exact trap coordinates (VU taxon on the array).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/davis_2019_kasungu_scr.R"
CACHE <- "davis_2019_kasungu_scr"
FILES <- c("Leopard_flank_ID.csv", "Hyaena_flank_ID.csv", sprintf("%s_SPIM_%d.csv", rep(c("Leopard", "Hyaena"), each = 3), 2016:2018),
           sprintf("tdf_%d.csv", 2016:2018))
files <- sapply(FILES, function(n) download_cached(paste0("https://zenodo.org/records/3540503/files/", n, "?download=1"), CACHE, n))
YEARS <- 2016:2018; K <- c(90L, 120L, 90L)

utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM; the caller passes N - 1e7 in the southern hemisphere
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  list(lat = lat * 180 / pi, lon = (zone - 1) * 6 - 180 + 3 + lon * 180 / pi)
}

# ---- trap effort: the survey set --------------------------------------------------------
tdf <- lapply(seq_along(YEARS), function(i) {
  t <- fread(files[[sprintf("tdf_%d.csv", YEARS[i])]], header = TRUE)
  t <- t[, which(names(t) != "" & !grepl("^V\\d+$", names(t))), with = FALSE]
  stopifnot(identical(names(t), c("trap_ID", "X", "Y", as.character(seq_len(K[i])))), !anyDuplicated(t$trap_ID))
  t
})
stopifnot(identical(sapply(tdf, nrow), c(17L, 50L, 25L)))
surveyed <- rbindlist(lapply(seq_along(YEARS), function(i) {
  t <- tdf[[i]]; E <- as.matrix(t[, -(1:3)]); stopifnot(all(E %in% 0:1), all(rowSums(E) > 0))
  data.table(trap = rep(t$trap_ID, K[i]), period = i, occasion = rep(seq_len(K[i]), each = nrow(t)), on = c(E))[on == 1, !"on"]
}))
alltr <- unique(rbindlist(lapply(tdf, function(t) t[, .(trap = trap_ID, X, Y)])))
stopifnot(nrow(alltr) == 92L, !anyDuplicated(alltr$trap), all(alltr$X > 5e5 & alltr$X < 5.3e5), all(alltr$Y > 8.54e6 & alltr$Y < 8.58e6))
n_surv0 <- nrow(surveyed)
# the one leopard photograph on an inactive trap-day (asserted below) joins the survey set
surveyed <- rbind(surveyed, data.table(trap = "B20", period = 2L, occasion = 16L))
stopifnot(!anyDuplicated(surveyed))
cx <- mean(alltr$X); cy <- mean(alltr$Y)
ctr <- utm_to_ll(cx, cy - 1e7, zone = 36)
stopifnot(ctr$lat > -13.5 & ctr$lat < -12.5, ctr$lon > 33 & ctr$lon < 33.5)
ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
traps <- alltr[, .(trap, x_m = round(X - cx, 1), y_m = round(Y - cy, 1))]
traps <- merge(traps, surveyed[, .(years_operated = paste(YEARS[sort(unique(period))], collapse = ";"), n_days_operating = .N), by = trap], by = "trap")
setorder(traps, trap)
cat(sprintf("  92 traps, %d active trap-days (+1 from a photograph), array centre %.2f, %.2f\n", n_surv0, ctr$lat, ctr$lon))

# ---- species ------------------------------------------------------------------------------
SP <- list(
  leopard = list(table = "davis_2019_kasungu_leopard_scr", pre = "L", taxon = "PANPAR", sci = "Panthera pardus", vern = "Leopard", iucn = "VU",
                 n_cat = 54L, n_rec = c(29L, 68L, 107L)),
  hyaena  = list(table = "davis_2019_kasungu_hyaena_scr", pre = "H", taxon = "CROCRO", sci = "Crocuta crocuta", vern = "Spotted hyaena", iucn = "LC",
                 n_cat = 50L, n_rec = c(70L, 73L, 129L)))
OTHER <- function(sp) SP[[setdiff(names(SP), sp)]]$table

build <- function(sp) {
  s <- SP[[sp]]; Sp <- if (sp == "leopard") "Leopard" else "Hyaena"
  fl <- fread(files[[paste0(Sp, "_flank_ID.csv")]], na.strings = c("", "NA"))
  setnames(fl, c("Animal_ID", "Left Flank", "Right Flank"), c("id", "L", "R"))
  stopifnot(nrow(fl) == s$n_cat, !anyDuplicated(fl$id), all(fl$L %in% c("Y", NA)), all(fl$R %in% c("Y", NA)), !any(is.na(fl$L) & is.na(fl$R)))
  fl[, unit_identity := fifelse(!is.na(L) & !is.na(R), "both", fifelse(!is.na(L), "left", "right"))]
  d <- rbindlist(lapply(seq_along(YEARS), function(i) {
    x <- fread(files[[sprintf("%s_SPIM_%d.csv", Sp, YEARS[i])]])
    if (sp == "hyaena") setnames(x, c("Session", "ID", "Occasion", "trapID", "Side"), c("SESSION", "ANIMAL_ID", "SO", "LOC_ID", "SIDE"))
    stopifnot(nrow(x) == s$n_rec[i], all(x$SESSION == 1L), all(x$SIDE %in% c("L", "R")), all(x$SO %in% seq_len(K[i])),
              all(x$LOC_ID %in% tdf[[i]]$trap_ID), all(x$ANIMAL_ID %in% fl$id))
    x[, .(id = ANIMAL_ID, trap = LOC_ID, period = i, occasion = SO, side = fifelse(SIDE == "L", "left", "right"))]
  }))
  d <- merge(d, fl[, .(id, unit_identity)], by = "id")
  stopifnot(d[unit_identity != "both", all(side == unit_identity)])
  off <- d[!surveyed[seq_len(n_surv0)], on = c("trap", "period", "occasion")]
  stopifnot(nrow(off) == if (sp == "leopard") 1L else 0L)
  if (sp == "leopard") stopifnot(off$id == 42L, off$trap == "B20", off$period == 2L, off$occasion == 16L)
  det <- d[, .(obs_side = paste(sort(unique(side)), collapse = "/"), n = .N), by = .(unit = paste0(s$pre, id), trap, period, occasion)]
  ind <- fl[id %in% d$id, .(unit = paste0(s$pre, id), unit_identity)]
  if (sp == "leopard") {
    ind <- merge(ind, fl[, .(unit = paste0(s$pre, id), unit_sex = fifelse(Sex %in% c("F", "M"), Sex, NA_character_))], by = "unit")
    stopifnot(all(fl$Sex %in% c("F", "M", "N/A")))
  }
  long <- surveyed[rep(seq_len(.N), times = nrow(ind))]
  long[, unit := rep(ind$unit, each = nrow(surveyed))]
  long <- merge(long, det, by = c("unit", "trap", "period", "occasion"), all.x = TRUE)
  long[, y := as.integer(!is.na(n))]
  stopifnot(nrow(long) == nrow(ind) * nrow(surveyed), sum(long$y) == nrow(det), sum(long$n, na.rm = TRUE) == nrow(d))
  long[, n := NULL]
  long <- merge(long, ind, by = "unit")
  long[, taxon := s$taxon]
  long <- order_eco(long)
  cat(sprintf("  %s: %d individuals (%s), %d records on %d individual-trap-days, %d rows\n", sp, nrow(ind),
              paste(names(table(ind$unit_identity)), table(ind$unit_identity), collapse = " "), nrow(d), nrow(det), nrow(long)))

  taxa <- make_taxa(s$taxon, s$sci, vernacularName = s$vern, taxon_iucnCategory = s$iucn)
  periods <- data.table(period = 1:3, year = YEARS, label = paste("Camera-trap survey", YEARS), n_days = K,
                        n_traps = sapply(tdf, nrow))
  dataset <- list(
    title = sprintf("Spatial capture-recapture of %s (%s) from camera traps in Kasungu National Park, Malawi, annual surveys 2016 to 2018, with partial (single-flank) identities", tolower(s$vern), s$sci),
    creator = "Davis, Robert Scott",
    pubDate = "2019", doi = "10.5281/zenodo.3540503", sourceURL = "https://doi.org/10.5281/zenodo.3540503",
    citation = "Davis, R. S. (2019). Spatial partial identity model for spatial capture-recapture analysis of large carnivores in Kasungu National Park, Malawi [Data set]. Zenodo. https://doi.org/10.5281/zenodo.3540503",
    paperDOI = "10.1111/jzo.12838",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("Daily camera-trap detections of individually identified %s (%s) in Kasungu National Park, Malawi, a miombo woodland, from three annual surveys (2016, 2017, 2018) of 90, 120 and 90 days at 17, 50 and 25 camera traps. Individuals were identified from pelage patterns; some are known from both flanks and some from one flank only, so a left-only and a right-only id may be the same animal (unit_identity; the authors fitted the two-flank spatial partial identity model). One row per individual x active trap-day; the deposited active-inactive matrix is the survey set. Sibling table for the other species of the same survey: %s. Trap coordinates are centred on the array (local metres) because the leopard is IUCN Vulnerable.",
                       tolower(s$vern), s$sci, OTHER(sp)),
    samplingProtocol = "Camera traps at trap stations in three annual surveys; each 24-hour day is an occasion and a binary matrix gives each trap's active days. Individuals identified from left and right flank pelage patterns; complete (two-flank) identities only where flanks were certainly from the same animal.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
    surveyEvidenceNote = sprintf("tdf_<year>.csv gives each trap x day as active (1) or inactive (0); a trap-day is surveyed iff 1 (%d trap-days). One leopard photograph (id 42, trap B20, 2017 day 16) falls on a day the matrix marks inactive; the photograph is believed and that trap-day is added to the survey set of both tables.", n_surv0),
    responseType = "detection", unitKind = "individual", closure = "closed",
    closureNote = "each annual survey (period) treated as closed by the authors; open between years",
    occasionKind = "time", taxonInclusion = "single",
    geographicCoverage = sprintf("Kasungu National Park, Malawi; trap array centre %.1f, %.1f (0.1 degree); trap positions in __traps as local metres centred on the array", ctr_c$lat, ctr_c$lon),
    temporalCoverage = "2016/2018",
    crs = "local: metres, UTM 36S (EPSG:32736) easting/northing minus the mean trap position (processor-centred)",
    coordinatesCoarsened = list(value = TRUE, method = "trap coordinates centred on the array by the processor (local metres; exact UTM 36S positions withheld) because the leopard (IUCN VU) shares the camera array with the hyaena table; the array centre is given at 0.1 degree in geographicCoverage"),
    designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps, three annual sessions as periods; partial identity (E2) in unit_identity. One species per table (ruling #20); the two tables share traps and survey set.",
    notes = paste("unit_identity = the flanks from which the individual is known (both / left / right); single-flank ids may duplicate an animal known from the other flank. obs_side = the flank photographed on detection rows.",
                  if (sp == "leopard") "unit_sex from the catalogue (N/A shipped as missing)." else "Hyaenas were not sexed."),
    notShipped = list(scripts = "process leopard.R / process hyaena.R: the authors' SPIM fitting code",
                      exact_coordinates = "UTM 36S trap positions withheld (VU taxon on the array); __traps carries them centred on the array"))
  ds <- write_table(long, s$table, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("Spatial capture-recapture histories of %s (%s) from camera traps in Kasungu National Park, Malawi, three annual surveys 2016-2018, individual x trap x day on the deposited active-day matrix, with single-flank partial identities; trap coordinates centred on the array.", tolower(s$vern), s$sci),
    url = "https://doi.org/10.5281/zenodo.3540503",
    reference = "Davis, R. S., Stone, E., Gentle, L., Mgoola, W. O., Uzal, A., & Yarnell, R. W. (2020). Spatial partial identity model reveals low densities of leopard and spotted hyaena in a miombo woodland. Journal of Zoology.",
    doi_paper = "10.1111/jzo.12838", doi_data = "10.5281/zenodo.3540503",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "SCR (E9 experimental), multi-session; partial identity (unit_identity). Trap key + __traps in processor-centred local metres (leopard VU). One script writes two species tables.",
    source_via = "Zenodo")
  stage_tag_row(s$table, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (partial identity, camera traps)",
    sampling_protocol = "camera_trap", design = "Multi-session (three annual surveys of 90-120 daily occasions)", realm = "Terrestrial",
    country = "MWI", coordinates = "Coarsened (trap coordinates centred on the array, local metres; VU taxon)",
    notes = "Experimental (E9): trap key + __traps; single-flank ids (unit_identity). Two sibling tables share traps and survey set.")
  invisible(ds)
}
for (sp in names(SP)) build(sp)
