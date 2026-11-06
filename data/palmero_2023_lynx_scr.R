#!/usr/bin/env Rscript
# Tables: palmero_2023_ucez_lynx_scr, palmero_2023_sbnp_lynx_scr, palmero_2023_bpp_lynx_scr
# Source: Dryad doi:10.5061/dryad.rbnzs7hhx (CC0 1.0, as shown on the Dryad page; version
#         261734). Palmero, S., Smith, A.F. et al. Code and data for: Shining a light on elusive
#         lynx: density estimation of three Eurasian lynx populations in Ukraine and Belarus.
# Paper:  Palmero, S., Smith, A.F. et al. (2023). Shining a light on elusive lynx: density
#         estimation of three Eurasian lynx populations in Ukraine and Belarus. Ecology and
#         Evolution, doi:10.1002/ece3.10688 (Dryad primary_article). Paired camera traps,
#         winter 2020-21, individuals identified from coat patterns; Bayesian SCR fitted
#         separately per study area.
# Data:   Data_and_code.zip -> "Data and code/<AREA>/" for AREA = UCEZ (Chornobyl Exclusion
#         Zone, Ukraine), SBNP (Skolivski Beskydy NP, Ukraine), BPP (Pripyat-Polesia, Belarus):
#         edf.csv (";"-separated: SESSION (always 1), LYNX_ID, OCCASION (day index), DETECTOR_ID,
#         DATE_TIME; one row per photograph event, several per day possible), tdf.csv
#         (DETECTOR_ID, X, Y in metres, DAYS = days the station operated), traps.txt (the same
#         ids and coordinates for secr), <AREA>list.RData (ntraps, noccasions, nindividuals).
#         The authors' code reduces edf to unique individual x occasion x trap ("at most one
#         event per site per occasion") and models y_ij ~ Binomial(p_ij, K_j), with y_ij the
#         number of occasions individual i was photographed at trap j and K_j = DAYS.
#         Which days each station operated is not deposited, only the count.
#         Lynx ids are as deposited (B.., R.., L.. prefixes; the deposit does not define them,
#         the authors treat each id as one individual).
# Mapping (standard: E9 experimental, SCR; binomial observation as in
#         gardner_2018_nagarahole_tiger_oscr): one table per study area (three independent
#         arrays and populations, each analysed alone). unit = LYNX_ID; taxon = LYNLYN;
#         trap = DETECTOR_ID; no period, no occasion; y = number of distinct occasions with a
#         photograph of the individual at the trap; obs_trials = DAYS (effortColumn), the
#         binomial denominator. Survey evidence: effort_table: a trap is surveyed iff DAYS > 0;
#         every individual carries a row at every operated trap of its area (full rectangle).
#         __traps: trap, x, y as deposited (projected metres; the deposit names no CRS).
#         Eurasian lynx is IUCN LC and the deposit flags nothing, so coordinates are as
#         published. Not shipped: DATE_TIME and OCCASION per event (no per-day effort to pair
#         them with; they survive as the count y), duplicate events within a day.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/palmero_2023_lynx_scr.R"
dir <- download_dryad("10.5061/dryad.rbnzs7hhx", "palmero_2023_lynx_scr")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^Data_and_code\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
base <- file.path(ex, "Data and code"); stopifnot(dir.exists(base))

AREAS <- list(
  UCEZ = list(table = "palmero_2023_ucez_lynx_scr", name = "Chornobyl Exclusion Zone, Ukraine", iso = "UKR",
              n_ev = 46L, n_ind = 22L, n_trap = 65L, n_op = 65L, n_y = 46L,
              crs = "projected metres as deposited; no CRS stated (values consistent with WGS 84 / UTM zone 36N)"),
  SBNP = list(table = "palmero_2023_sbnp_lynx_scr", name = "Skolivski Beskydy National Park, Ukrainian Carpathians", iso = "UKR",
              n_ev = 47L, n_ind = 5L, n_trap = 35L, n_op = NA, n_y = 27L,
              crs = "projected metres as deposited; no CRS stated (values consistent with WGS 84 / UTM zone 34N)"),
  BPP  = list(table = "palmero_2023_bpp_lynx_scr", name = "Pripyat-Polesia, southern Belarus", iso = "BLR",
              n_ev = 119L, n_ind = 14L, n_trap = 50L, n_op = NA, n_y = 52L,
              crs = "projected metres as deposited; no CRS stated (values consistent with WGS 84 / UTM zone 35N)"))
taxa <- make_taxa("LYNLYN", "Lynx lynx", vernacularName = "Eurasian lynx")

for (a in names(AREAS)) {
  A <- AREAS[[a]]
  e <- fread(file.path(base, a, "edf.csv"), sep = ";", encoding = "UTF-8")
  t <- fread(file.path(base, a, "tdf.csv"), sep = ";", encoding = "UTF-8")
  names(e) <- sub("^﻿", "", names(e)); names(t) <- sub("^﻿", "", names(t))
  stopifnot(identical(names(e), c("SESSION", "LYNX_ID", "OCCASION", "DETECTOR_ID", "DATE_TIME")),
            identical(names(t), c("DETECTOR_ID", "X", "Y", "DAYS")))
  lst <- readRDS(file.path(base, a, paste0(a, "list.RData")))
  stopifnot(nrow(e) == A$n_ev, all(e$SESSION == 1), uniqueN(e$LYNX_ID) == A$n_ind, lst$nindividuals == A$n_ind,
            nrow(t) == A$n_trap, lst$ntraps == A$n_trap, !anyDuplicated(t$DETECTOR_ID),
            all(e$DETECTOR_ID %in% t$DETECTOR_ID), all(e$OCCASION >= 1 & e$OCCASION <= lst$noccasions),
            all(t$DAYS >= 0), all(t[DETECTOR_ID %in% e$DETECTOR_ID, DAYS] > 0))
  dt <- as.IDate(substr(e$DATE_TIME, 1, 10), format = "%d/%m/%Y"); stopifnot(!anyNA(dt))
  # occasion = day index: two events on one occasion share a date (asserted)
  e[, d := dt]; stopifnot(e[, uniqueN(d), by = .(OCCASION)][, all(V1 == 1)])
  u <- unique(e[, .(LYNX_ID, OCCASION, DETECTOR_ID)]); stopifnot(nrow(u) == A$n_y)
  cnt <- u[, .(y = .N), by = .(LYNX_ID, DETECTOR_ID)]
  op <- t[DAYS > 0]
  if (!is.na(A$n_op)) stopifnot(nrow(op) == A$n_op)
  long <- CJ(LYNX_ID = sort(unique(e$LYNX_ID)), DETECTOR_ID = op$DETECTOR_ID)
  long <- merge(long, cnt, by = c("LYNX_ID", "DETECTOR_ID"), all.x = TRUE)[is.na(y), y := 0L]
  long <- merge(long, op[, .(DETECTOR_ID, DAYS)], by = "DETECTOR_ID")
  stopifnot(nrow(long) == A$n_ind * nrow(op), sum(long$y) == A$n_y, all(long$y <= long$DAYS))
  long <- order_eco(long[, .(unit = LYNX_ID, taxon = "LYNLYN", y = as.integer(y), trap = as.character(DETECTOR_ID),
                             obs_trials = as.integer(DAYS))])
  traps <- t[DAYS > 0, .(trap = as.character(DETECTOR_ID), x = X, y = Y, days_operated = as.integer(DAYS))]
  rng <- range(dt)
  dataset <- list(
    title = sprintf("Spatial capture-recapture of Eurasian lynx from paired camera traps, %s: %d individuals x %d stations, winter 2020-21", A$name, A$n_ind, nrow(op)),
    creator = "Palmero, Stefano; Smith, Adam F.; Kudrenko, Svitlana; Gahbauer, Martin; Dachs, Dominik; Weingarth-Dachs, Kirsten; Kashpei, Irina; Shamovich, Dmitry; Vyshnevskiy, Denys; Borsuk, Oleksandr; Korepanova, Kateryna; Bashta, Andriy-Taras; Zhuravchak, Rostyslav; Fenchuk, Viktar; Heurich, Marco",
    pubDate = "2023", doi = "10.5061/dryad.rbnzs7hhx", sourceURL = "https://doi.org/10.5061/dryad.rbnzs7hhx",
    citation = "Palmero, S., Smith, A. F., et al. (2023). Code and data for: Shining a light on elusive lynx: density estimation of three Eurasian lynx populations in Ukraine and Belarus [Dataset]. Dryad. https://doi.org/10.5061/dryad.rbnzs7hhx",
    paperDOI = "10.1002/ece3.10688",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Photographic captures of individually identified Eurasian lynx (Lynx lynx) at paired camera-trap stations in %s, %s to %s, as the authors' spatial capture-recapture input: one row per lynx x operated station, y = the number of days the lynx was photographed at the station and obs_trials = the days the station operated, with station coordinates in __traps.", A$name, rng[1], rng[2]),
    samplingProtocol = "Paired camera traps photographing both flanks at stations across the study area through winter 2020-21; lynx identified from coat patterns; at most one detection per individual per station per day (the authors' rule).",
    samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
    surveyEvidenceNote = "tdf.csv gives the days each station operated; a station is surveyed iff DAYS > 0. Which days it operated is not deposited, so the table is at the station level with the day count as the binomial denominator, the authors' own y ~ Binomial(p, K).",
    effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "individual",
    closure = "none", closureNote = "no occasion column; one winter session per study area, which the authors analysed as a closed population", occasionKind = "none",
    taxonInclusion = "single", crs = A$crs,
    geographicCoverage = sprintf("%s; station coordinates in __traps", A$name),
    temporalCoverage = paste(format(rng[1], "%Y-%m"), format(rng[2], "%Y-%m"), sep = "/"),
    coordinatesCoarsened = list(value = FALSE, method = "as published: Eurasian lynx is IUCN LC and the deposit flags no sensitivity"),
    designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; binomial observation per station (no occasion column) because per-day station operation is not deposited.",
    notShipped = list(DATE_TIME = "event date-times and day indices: no per-day effort to pair them with; they survive as the count y",
                      repeat_events = "repeat photographs of one lynx at one station on one day (collapsed, the authors' rule)"),
    notes = sprintf("One of three tables from this deposit (Chornobyl Exclusion Zone, Skolivski Beskydy, Pripyat-Polesia), each an independent array and population. Lynx ids as deposited; their B/R/L prefixes are not defined in the deposit and each id is treated as one individual, as the authors did. %d of %d deposited stations operated.", nrow(op), nrow(t)))
  ds <- write_table(long, A$table, dataset, taxa = taxa, traps = traps, script = SCRIPT)
  stage_dict_row(A$table,
    description = sprintf("Camera-trap spatial capture-recapture of Eurasian lynx in %s, winter 2020-21: %d individuals x %d stations, y = days photographed, effort = days operated.", A$name, A$n_ind, nrow(op)),
    url = "https://doi.org/10.5061/dryad.rbnzs7hhx",
    reference = "Palmero, S., Smith, A. F., et al. (2023). Shining a light on elusive lynx: density estimation of three Eurasian lynx populations in Ukraine and Belarus. Ecology and Evolution.",
    doi_paper = "10.1002/ece3.10688", doi_data = "10.5061/dryad.rbnzs7hhx",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "SCR (E9 experimental), binomial counts per station; one of three study-area tables.", source_via = "Dryad")
  stage_tag_row(A$table, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (binomial counts with day effort)",
    sampling_protocol = "camera_trap", design = "Single-season (one winter SCR session)", realm = "Terrestrial",
    country = A$iso, coordinates = "As published (projected metres in __traps)",
    notes = "Experimental (E9): trap key + __traps; individual x station rows with days operated as effort.")
}
