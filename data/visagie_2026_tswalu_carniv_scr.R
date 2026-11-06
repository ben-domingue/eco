#!/usr/bin/env Rscript
# Tables: visagie_2026_tswalu_leopard_scr, visagie_2026_tswalu_brownhyaena_scr,
#         visagie_2026_tswalu_spothyaena_scr
# Source: Dryad doi:10.5061/dryad.rxwdbrvrt (CC0 1.0, as shown on the Dryad page; published
#         2026). Visagie et al. Data and code from: Estimating large carnivore populations in an
#         arid fenced reserve using spatial capture-recapture modelling.
# Paper:  Visagie, M., Davis, R.S., Overton, E.K. & Venter, J. (2026), Wildlife Biology, doi:10.1002/wlb3.01630.
#         Camera-trap survey at 85 paired stations over 127 daily sampling occasions, 18 January
#         to 23 May 2024, Korannaberg section (1,017 km2) of Tswalu Kalahari Reserve, Northern
#         Cape, South Africa; leopard, brown hyaena and spotted hyaena identified from natural
#         markings; oSCR fitted per species (README).
# Data:   Tswalu_09.07.26.zip -> Tswalu_tdf.csv (85 stations: TRAP_ID, X, Y in km on 1 km grid
#         centroids, generalised by the authors for sensitive species, UTM 34S per the README's
#         raster script; X1..X127 = station operating (1) or not (0) on each occasion; "sep";
#         TRAIL (camera on a trail, 0/1); DEN (distance to the spotted hyaena den, m, from
#         independent GPS-collar data)); Tswalu_leopard.csv, Tswalu_brown.csv,
#         Tswalu_spotted_edf.csv (SESSION = 1, TRAP_ID, SO = occasion, ANIMAL_ID; one row per
#         detection event, duplicates removed by the authors' script). Also shapefiles, the
#         state space, fitted model objects and predicted density rasters (not data).
#         Quirk: 4 detections fall on station-occasions the operation matrix marks 0 (spotted
#         hyaena: station 16, SO 115 and 122; brown hyaena: station 78, SO 86 and 98).
# Mapping (standard: E9 experimental, SCR; proximity detectors, daily occasions): one table per
#   species, as the authors fit them (separate individuals on one camera array). unit =
#   ANIMAL_ID; trap = TRAP_ID; occasion = SO (day 1..127); date = 2024-01-17 + SO (127 days
#   from 18 January to 23 May 2024, asserted); y = 1 if the individual was detected at the
#   station that day. Survey evidence: effort_table (the operation matrix): a station-day is
#   surveyed iff marked 1, PLUS the 4 station-days with a photograph despite a 0 (a photograph
#   shows the camera operated; the detections are believed over the matrix, E4) in all three
#   tables, as the array is one detector for all species. Every individual carries a row for
#   every surveyed station-day (full rectangle, ruling #30).
#   __traps: trap, x, y centred on the array centroid in metres by the processor, trail, den_m.
#   Coordinates (E7): leopard is IUCN VU (native range) and brown hyaena NT; the source
#   generalised stations to 1 km cells, finer than the 0.1 degree rule, so, following
#   davis_2019_kasungu_scr and curveirasantos_2026_phinda_carniv_scr, station coordinates are
#   centred on the array centroid (local metres; UTM positions withheld) in all three tables
#   (one shared array); the centroid is in geographicCoverage at 0.1 degree.
#   Not shipped: model outputs, state space, density rasters, shapefiles (not data); duplicate
#   detection rows (the authors' rule).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/visagie_2026_tswalu_carniv_scr.R"
dir <- download_dryad("10.5061/dryad.rxwdbrvrt", "visagie_2026_tswalu_carniv_scr")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^Tswalu_09\\.07\\.26\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
base <- file.path(ex, "Tswalu_09.07.26"); stopifnot(dir.exists(base))
tdf <- fread(file.path(base, "Tswalu_tdf.csv"))
stopifnot(identical(names(tdf), c("TRAP_ID", "X", "Y", paste0("X", 1:127), "sep", "TRAIL", "DEN")),
          nrow(tdf) == 85, !anyDuplicated(tdf$TRAP_ID), all(tdf$sep == "/"), all(tdf$TRAIL %in% 0:1))
OP <- as.matrix(tdf[, paste0("X", 1:127), with = FALSE]); dimnames(OP) <- list(tdf$TRAP_ID, NULL)
stopifnot(all(OP %in% 0:1), sum(OP) == 9978)
stopifnot(as.IDate("2024-01-17") + 1L == as.IDate("2024-01-18"), as.IDate("2024-01-17") + 127L == as.IDate("2024-05-23"))

SP <- list(
  leopard = list(file = "Tswalu_leopard.csv", table = "visagie_2026_tswalu_leopard_scr", code = "PANPAR",
                 sci = "Panthera pardus", vern = "Leopard", n_raw = 29L, n_det = 23L, n_ind = 5L),
  brown   = list(file = "Tswalu_brown.csv", table = "visagie_2026_tswalu_brownhyaena_scr", code = "PARBRU",
                 sci = "Parahyaena brunnea", vern = "Brown hyaena", n_raw = 121L, n_det = 113L, n_ind = 39L),
  spotted = list(file = "Tswalu_spotted_edf.csv", table = "visagie_2026_tswalu_spothyaena_scr", code = "CROCRO",
                 sci = "Crocuta crocuta", vern = "Spotted hyaena", n_raw = 115L, n_det = 98L, n_ind = 7L))
E <- lapply(SP, function(s) {
  e <- fread(file.path(base, s$file), encoding = "UTF-8"); names(e) <- sub("^﻿", "", names(e))
  stopifnot(identical(names(e), c("SESSION", "TRAP_ID", "SO", "ANIMAL_ID")), nrow(e) == s$n_raw, all(e$SESSION == 1))
  e <- unique(e)
  stopifnot(nrow(e) == s$n_det, uniqueN(e$ANIMAL_ID) == s$n_ind, all(e$TRAP_ID %in% tdf$TRAP_ID), all(e$SO %in% 1:127))
  e
})
# station-days with a photograph but marked not operating: believed operating, for every species
ev <- rbindlist(E)
off <- unique(ev[OP[cbind(match(as.character(TRAP_ID), rownames(OP)), SO)] == 0, .(TRAP_ID, SO)])
stopifnot(nrow(off) == 4, setequal(paste(off$TRAP_ID, off$SO), c("16 115", "16 122", "78 86", "78 98")))
OP[cbind(match(as.character(off$TRAP_ID), rownames(OP)), off$SO)] <- 1L
surv <- as.data.table(which(OP == 1, arr.ind = TRUE))[, .(TRAP_ID = tdf$TRAP_ID[row], SO = col)]
stopifnot(nrow(surv) == 9982)
cx <- mean(tdf$X); cy <- mean(tdf$Y)
traps <- tdf[, .(trap = as.character(TRAP_ID), x = round((X - cx) * 1000), y = round((Y - cy) * 1000),
                 trail = as.integer(TRAIL), den_m = DEN)]

for (k in names(SP)) {
  s <- SP[[k]]; e <- E[[k]]
  long <- CJ(ANIMAL_ID = sort(unique(e$ANIMAL_ID)), i = seq_len(nrow(surv)))
  long <- cbind(long[, .(ANIMAL_ID)], surv[long$i])
  long <- merge(long, e[, .(ANIMAL_ID, TRAP_ID, SO, y = 1L)], by = c("ANIMAL_ID", "TRAP_ID", "SO"), all.x = TRUE)[is.na(y), y := 0L]
  stopifnot(nrow(long) == s$n_ind * 9982, sum(long$y) == s$n_det)
  long <- order_eco(long[, .(unit = ANIMAL_ID, taxon = s$code, y, trap = as.character(TRAP_ID), occasion = as.integer(SO),
                             date = format(as.IDate("2024-01-17") + as.integer(SO)))])
  taxa <- make_taxa(s$code, s$sci, vernacularName = s$vern)
  dataset <- list(
    title = sprintf("Spatial capture-recapture of %s from 85 paired camera stations in Tswalu Kalahari Reserve, South Africa: %d individuals, 127 daily occasions, January-May 2024", tolower(s$vern), s$n_ind),
    creator = "Visagie, Marna; Davis, Robert Simon; Overton, Elizabeth Kennedy; Venter, Jan", paperDOI = "10.1002/wlb3.01630", pubDate = "2026", doi = "10.5061/dryad.rxwdbrvrt",
    sourceURL = "https://doi.org/10.5061/dryad.rxwdbrvrt",
    citation = "Visagie, M., Davis, R. S., Overton, E. K., & Venter, J. (2026). Data and code from: Estimating large carnivore populations in an arid fenced reserve using spatial capture-recapture modelling [Dataset]. Dryad. https://doi.org/10.5061/dryad.rxwdbrvrt",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Daily detections of individually identified %s (%s) at 85 paired camera-trap stations in the Korannaberg section of Tswalu Kalahari Reserve, Northern Cape, South Africa, 18 January to 23 May 2024, as the authors' oSCR input: one row per individual x station x day the station operated, with station placement (on trail or not) and distance to the spotted hyaena den.", tolower(s$vern), s$sci),
    samplingProtocol = "85 paired camera-trap stations operated over 127 daily occasions; individuals identified from natural markings; detections per individual, station and day (proximity detectors), with a per-day operation matrix.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
    surveyEvidenceNote = "The deposited operation matrix (station x day) defines the survey set: a station-day is surveyed iff marked 1 (9,978). Four station-days marked 0 carry a photograph (spotted hyaena at station 16 on days 115 and 122; brown hyaena at station 78 on days 86 and 98); the photographs are believed and the four are added as surveyed in all three species' tables (9,982).",
    responseType = "detection", unitKind = "individual", closure = "closed",
    closureNote = "one 127-day session analysed as a closed population (oSCR)", occasionKind = "time",
    taxonInclusion = "single", crs = "local: station positions centred on the array centroid by the processor, metres (source: 1 km grid centroids, WGS 84 / UTM 34S)",
    geographicCoverage = "Korannaberg section of Tswalu Kalahari Reserve, Northern Cape, South Africa; array centroid about 27.3 S, 22.4 E",
    temporalCoverage = "2024-01/2024-05",
    coordinatesCoarsened = list(value = TRUE, method = "station coordinates (generalised by the source to 1 km grid centroids) centred on the array centroid by the processor, local metres, UTM positions withheld, because leopard (IUCN VU) shares the camera array with the two hyaena tables; the centroid is given at 0.1 degree in geographicCoverage"),
    designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; daily Bernoulli detections at proximity detectors.",
    notShipped = list(model_outputs = "fitted oSCR models, state-space grid, predicted density rasters and shapefiles (not observations)",
                      duplicate_rows = "duplicate detection rows in the encounter files, removed as in the authors' script",
                      utm_coordinates = "station UTM coordinates (1 km centroids), withheld under E7 (centred instead)"),
    notes = sprintf("One of three species tables from one camera array (leopard, brown hyaena, spotted hyaena). %d individuals; ids as deposited. date = 2024-01-17 + occasion (127 days, 18 January to 23 May 2024, as the README states).", s$n_ind))
  ds <- write_table(long, s$table, dataset, taxa = taxa, traps = traps, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("Camera-trap spatial capture-recapture of %s at 85 stations in Tswalu Kalahari Reserve, South Africa, 127 daily occasions in 2024; %d individuals.", tolower(s$vern), s$n_ind),
    url = "https://doi.org/10.5061/dryad.rxwdbrvrt",
    reference = "Visagie et al. (2026). Estimating large carnivore populations in an arid fenced reserve using spatial capture-recapture modelling. Wildlife Biology.",
    doi_paper = "10.1002/wlb3.01630", doi_data = "10.5061/dryad.rxwdbrvrt", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "SCR (E9 experimental), daily occasions with the deposited operation matrix; station coordinates centred (leopard VU on the array).",
    source_via = "Dryad")
  stage_tag_row(s$table, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture",
    sampling_protocol = "camera_trap", design = "Single-season (one 127-day SCR session, daily occasions)", realm = "Terrestrial",
    country = "ZAF", coordinates = "Coarsened (trap coordinates centred on the array, local metres)",
    notes = "Experimental (E9): trap key + __traps; full individual x station-day rectangle.")
}
