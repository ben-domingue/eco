#!/usr/bin/env Rscript
# Table:  khelifa_2021_seybouse_calexul_cjs
# Source: Dryad doi:10.5061/dryad.xksn02vfv (CC0 1.0), version 112130, published 2021-03-27.
#   Khelifa, R. et al. (2021). Capture-mark-recapture of Calopteryx exul in 2011 [Dataset].
# Paper:  Khelifa, R., Mahdjoub, H., Baaloudj, A., Cannings, R. A. & Samways, M. J. (2021).
#         Effects of both climate change and human water demand on a highly threatened
#         damselfly. Scientific Reports 11:7725, doi:10.1038/s41598-021-86383-z (CC BY 4.0,
#         PMC8032742). Methods: daily hand-net captures of adult Calopteryx exul along a
#         100 m transect of a channel of the Seybouse River at El Fedjoudj (36 deg 28' N,
#         7 deg 22' E, Guelma, NE Algeria) in the morning, individual alphanumeric wing
#         marks; "313 marked adults, of which 56.8% were recaptured at least once".
# Data:   one xlsx, three sheets.
#         CMR (313 x 27): indiv (mark), Sex (F/M), then 25 columns named by Julian date
#           132..157 with 153 missing (no sampling that day), cells 0/1.
#         EnvironmentalCovariate (25 x 2): Water_depth (cm, graded stick at the centre of
#           the waterbed, one reading per sampling day) and JulianDate, the same 25 days.
#         Metadata: variable definitions.
#         Quirk: the paper's text dates the 2011 campaign 28 April-29 May; the deposit's
#         Julian dates 132-157 are 12 May-6 June if counted from 1 January 2011. The
#         deposit does not state the origin, so no calendar `date` is derived (E8); the
#         Julian day is carried in __periods as deposited.
#
# Mapping (standard E9, CJS): unit = individual mark, taxon = CALEXU, period = sampling
#   day 1..25 in Julian-date order (one capture occasion per day, so no `occasion`),
#   y = 0/1 captured. Full rectangle 313 x 25 including rows before first capture (E2).
#   unit_sex as deposited. Water depth is a per-day covariate constant across individuals:
#   period_water_depth_cm on the core rows and water_depth_cm in __periods.
#   Survey evidence: deposited_matrix (every individual has a 0/1 for every sampled day;
#   Julian 153 is absent from both sheets, so it was not sampled and has no period).
#   Not shipped: nothing; the daily abundance transect counts and dam data the paper uses
#   are not in the deposit.
#   Coordinates: none per unit. The single site coordinate from the paper is given in
#   geographicCoverage at 0.1 degree (C. exul is IUCN EN).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "khelifa_2021_seybouse_calexul_cjs"
dir <- download_dryad("10.5061/dryad.xksn02vfv", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, pattern = "^Data_Khelifa.*\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1, setequal(excel_sheets(f), c("CMR", "EnvironmentalCovariate", "Metadata")))

cmr <- as.data.table(read_excel(f, sheet = "CMR"))
env <- as.data.table(read_excel(f, sheet = "EnvironmentalCovariate"))
stopifnot(dim(cmr) == c(313, 27), identical(names(cmr)[1:2], c("indiv", "Sex")),
          !anyDuplicated(cmr$indiv), all(cmr$Sex %in% c("F", "M")))
jd <- as.integer(names(cmr)[-(1:2)])
stopifnot(!anyNA(jd), identical(jd, setdiff(132:157, 153L)), identical(as.integer(sort(env$JulianDate)), jd),
          nrow(env) == 25, !anyNA(env$Water_depth), all(env$Water_depth >= 0))
CH <- as.matrix(cmr[, -(1:2)]); stopifnot(all(CH %in% c(0, 1)), all(rowSums(CH) >= 1))
# paper: 313 marked adults, 56.8% recaptured at least once
stopifnot(nrow(CH) == 313, abs(mean(rowSums(CH) >= 2) - 0.568) < 0.002)
cat(sprintf("  %d individuals x %d sampling days, %d captures, %.1f%% recaptured at least once\n",
            nrow(CH), ncol(CH), sum(CH), 100 * mean(rowSums(CH) >= 2)))

Tn <- ncol(CH)
long <- array_to_eco(CH, taxon = "CALEXU", site_ids = paste0("ind", cmr$indiv), period = seq_len(Tn))
long[, occasion := NULL]
long <- merge(long, data.table(unit = paste0("ind", cmr$indiv), unit_sex = cmr$Sex), by = "unit")
periods <- data.table(period = seq_len(Tn), julian_day = jd)
periods <- merge(periods, env[, .(julian_day = as.integer(JulianDate), water_depth_cm = Water_depth)], by = "julian_day")
setorder(periods, period); setcolorder(periods, c("period", "julian_day", "water_depth_cm"))
long <- merge(long, periods[, .(period, period_water_depth_cm = water_depth_cm)], by = "period")
long <- order_eco(long)
stopifnot(nrow(long) == 313 * Tn, sum(long$y) == sum(CH), uniqueN(long$unit) == 313)
periods[, note := "sampling day of the 2011 campaign; Julian day as deposited (origin not stated: the paper dates the campaign 28 April-29 May 2011)"]

taxa <- make_taxa("CALEXU", "Calopteryx exul", vernacularName = "Glittering Demoiselle", taxon_iucnCategory = "EN")
dataset <- list(
  title = "Capture-mark-recapture histories of 313 adult Calopteryx exul over 25 daily sampling occasions, Seybouse River, Algeria, 2011",
  creator = "Khelifa, Rassim; Mahdjoub, Hayat; Baaloudj, Affef; Cannings, Robert A.; Samways, Michael J.",
  pubDate = "2021", doi = "10.5061/dryad.xksn02vfv", sourceURL = "https://doi.org/10.5061/dryad.xksn02vfv",
  citation = "Khelifa, R., Mahdjoub, H., Baaloudj, A., Cannings, R. A., & Samways, M. J. (2021). Capture-mark-recapture of Calopteryx exul in 2011 [Dataset]. Dryad. https://doi.org/10.5061/dryad.xksn02vfv",
  paperDOI = "10.1038/s41598-021-86383-z",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily capture-mark-recapture of adult Glittering Demoiselles (Calopteryx exul, IUCN EN) along a 100 m transect of a channel of the Seybouse River at El Fedjoudj, Guelma, northeastern Algeria, in the 2011 flight season: 313 individually wing-marked adults x 25 sampling days (Julian 132-157, day 153 not sampled), with the sex of each adult and the water depth at the centre of the waterbed on each sampling day. The paper fits a Cormack-Jolly-Seber model with constant survival and recapture probability as a quadratic function of water depth and sex.",
  samplingProtocol = "Hand-net capture of adults along a fixed 100 m river transect in the morning (09:00-12:00), individual alphanumeric wing marks, daily resampling; CJS.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "period (one capture occasion per sampling day; open between days)",
  effortColumn = NA,
  geographicCoverage = "Seybouse River at El Fedjoudj, Guelma, northeastern Algeria; one site, about 36.5 N 7.4 E (paper's coordinate rounded to 0.1 degree; the species is IUCN EN)",
  temporalCoverage = "2011", coordinatesCoarsened = NA,
  notes = "Rows before an individual's first capture are kept as 0 (E2). The Julian-day origin is not stated in the deposit and the paper's campaign dates (28 April-29 May 2011) do not match days 132-157 counted from 1 January, so no calendar date is derived; __periods carries the Julian day. period_water_depth_cm is the deposit's daily water depth (cm, graded stick), the paper's detection covariate.",
  notShipped = list(Metadata = "variable definitions sheet, used for the header"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/khelifa_2021_seybouse_calexul_cjs.R")

stage_dict_row(TABLE,
  description = "Cormack-Jolly-Seber capture histories of 313 wing-marked adult Calopteryx exul (Glittering Demoiselle, IUCN EN) over 25 daily sampling occasions on the Seybouse River, Guelma, Algeria, 2011, with sex and daily water depth.",
  url = "https://doi.org/10.5061/dryad.xksn02vfv",
  reference = "Khelifa, R., Mahdjoub, H., Baaloudj, A., Cannings, R. A., & Samways, M. J. (2021). Effects of both climate change and human water demand on a highly threatened damselfly. Scientific Reports, 11, 7725.",
  doi_paper = "10.1038/s41598-021-86383-z", doi_data = "10.5061/dryad.xksn02vfv",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Julian-day origin not stated; no calendar date derived. One site; coordinate given at 0.1 degree in geographicCoverage.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-session (25 daily capture occasions, no secondary)", realm = "Freshwater",
  country = "DZA", coordinates = "None in source", notes = "Individuals as unit; rows before first capture kept as 0; daily water depth as period_ covariate.")
