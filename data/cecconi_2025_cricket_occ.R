#!/usr/bin/env Rscript
# Table:  cecconi_2025_cricket_occ
# Source: Dryad doi:10.5061/dryad.ns1rn8q4k (CC0 1.0, as shown on the Dryad page; version 3,
#         published 2025-09-12). Cecconi, S., Notarianni, N. & McNeil, D. Assessing factors
#         associated with detection probability of the Japanese burrowing cricket
#         (Velarifictorus micado) on point count surveys.
# Paper:  Cecconi, S.V., Notarianni, N. & McNeil, D.J. (2025). Assessing factors associated with
#         detection probability of the Japanese burrowing cricket (Velarifictorus micado) on
#         point count surveys. Journal of Applied Entomology 150(2), 200-206,
#         doi:10.1111/jen.70022. Single-season occupancy of an invasive cricket at 49 aural
#         point-count sites in the Inner Bluegrass Region of central Kentucky, USA, surveyed at
#         all hours of the day from 19 September to 5 November 2024; the abstract reports
#         detection at 16 of the 49 sites.
# Data:   cecconi_crickets_cleaned.csv, 49 rows (point_id lex_*) x 19 columns: JBCR_1..3
#         (detection on occasions 1-3, 0/1), temp1-3 (F), ordinal1-3 (ordinal date),
#         barometric1-3 (barometric pressure; the README states no unit, values 28.34-29.48
#         are consistent with inHg), wind1-3 (mph), MSSS1-3 (minutes since sunset, 10-1431 as
#         deposited, never negative, so a daytime count is minutes since the previous sunset).
#         README.md describes every column. No missing values: every site has three surveys.
#         Quirks: the data file and README give no year, the Dryad abstract does (below); at
#         5 sites (lex_13, lex_18, lex_50, lex_51, lex_53) occasions 2 and 3 fall on one
#         calendar day, with occasion 3 later by minutes since sunset. No coordinates.
#
# Mapping (standard: single-season occupancy, E9 core):
#   unit = point_id; taxon = VELMIC; one period (dropped by the converter); occasion = survey
#   1..3; y = JBCR_k; obs_: temperature F, barometric pressure, wind mph, minutes since sunset.
#   date = 2024 + ordinal day: E8's obs_date_doy fallback is for when only a day-of-year exists,
#   but this source gives the year. The abstract on the Dryad page dates the surveys 19 September
#   to 5 November 2024, and the script asserts the deposited ordinals span exactly those two
#   dates under 2024's leap-year calendar. No unit covariates are deposited.
#   Survey evidence: the deposited site x occasion matrix (deposited_matrix; complete, no NA).
#   Nothing is a model output; every deposited column is shipped (ordinal as date).
#   v1.1: closure = closed (the authors fit single-season occupancy across the three counts),
#   occasionKind = time, taxonInclusion = single.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cecconi_2025_cricket_occ"
dir <- download_dryad("10.5061/dryad.ns1rn8q4k", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^cecconi_crickets_cleaned\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f)

stopifnot(identical(names(raw), c("point_id", paste0("JBCR_", 1:3),
                                  paste0(rep(c("temp", "ordinal", "barometric", "wind", "MSSS"), each = 3), 1:3))),
          nrow(raw) == 49, !anyNA(raw), !anyDuplicated(raw$point_id), all(grepl("^lex_[0-9]+$", raw$point_id)))
mat <- function(v) as.matrix(raw[, paste0(v, 1:3), with = FALSE])
Y <- as.matrix(raw[, .(JBCR_1, JBCR_2, JBCR_3)])
ORD <- mat("ordinal")
stopifnot(all(Y %in% 0:1),
          sum(rowSums(Y) > 0) == 16,                               # the abstract's 16 of 49 sites
          identical(range(ORD), c(263L, 310L)),                    # the abstract's survey window, asserted as dates below
          all(raw$ordinal1 < raw$ordinal2 & raw$ordinal2 <= raw$ordinal3),
          # the 5 same-day pairs: still in survey order, by time since sunset
          identical(raw[ordinal2 == ordinal3, point_id], c("lex_13", "lex_18", "lex_50", "lex_51", "lex_53")),
          raw[ordinal2 == ordinal3, all(MSSS2 < MSSS3)],
          all(mat("MSSS") >= 0 & mat("MSSS") < 1440),              # within one day of the last sunset
          all(mat("wind") >= 0),
          all(mat("temp") >= 40 & mat("temp") <= 100),             # plausibly Fahrenheit
          all(mat("barometric") >= 28 & mat("barometric") <= 31))  # plausibly inHg; the README states no unit
dimnames(Y) <- list(raw$point_id, NULL)

obs <- list(temp_f = mat("temp"), barometric_pressure = mat("barometric"), wind_mph = mat("wind"),
            minutes_since_sunset = mat("MSSS"))
long <- array_to_eco(Y, taxon = "VELMIC", site_ids = raw$point_id, obs_covs = obs)
# date = 2024 + the deposited ordinal day; 2023-12-31 + 1 is 2024-01-01, so the offset is exact
D <- matrix(format(as.IDate("2023-12-31") + as.vector(ORD)), nrow = nrow(ORD))
long[, date := D[cbind(match(unit, raw$point_id), occasion)]]
stopifnot(nrow(long) == 49 * 3, sum(long$y) == sum(Y), !anyNA(long$date),
          uniqueN(long$unit) == 49, identical(sort(unique(long$occasion)), 1:3),
          min(long$date) == "2024-09-19", max(long$date) == "2024-11-05",   # the abstract's dates
          !any(grepl("^obs_obs_", names(long))))

taxa <- make_taxa("VELMIC", "Velarifictorus micado",
                  vernacularName = "Japanese burrowing cricket")
dataset <- list(
  title = "Japanese burrowing cricket aural detections at 49 point-count sites in central Kentucky, three counts each, autumn 2024",
  creator = "Cecconi, Sam V.; Notarianni, Nicole; McNeil, Darin J.",
  pubDate = "2025", doi = "10.5061/dryad.ns1rn8q4k", sourceURL = "https://doi.org/10.5061/dryad.ns1rn8q4k",
  citation = "Cecconi, S., Notarianni, N., & McNeil, D. (2025). Assessing factors associated with detection probability of the Japanese burrowing cricket (Velarifictorus micado) on point count surveys [Dataset]. Dryad. https://doi.org/10.5061/dryad.ns1rn8q4k",
  paperDOI = "10.1111/jen.70022",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Aural detection/non-detection of the invasive Japanese burrowing cricket (Velarifictorus micado) at 49 point-count sites in the Inner Bluegrass Region of central Kentucky, USA, each surveyed three times at varying hours of the day between 19 September and 5 November 2024, with the temperature, barometric pressure, wind speed, minutes since sunset and date of every count. No site covariates and no coordinates are deposited.",
  samplingProtocol = "Aural point counts at all hours of the day, three per site between 19 September and 5 November 2024; temperature, barometric pressure, wind speed and time relative to sunset recorded per count. Count duration and site spacing are not in the deposit; see the paper.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed",
  closureNote = "occasion (three aural point counts of one site over about seven weeks, analysed by the authors as single-season occupancy)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Inner Bluegrass Region, central Kentucky, USA; no coordinates deposited",
  temporalCoverage = "2024-09-19/2024-11-05",
  coordinatesCoarsened = NA,
  notShipped = list(none = "every deposited column is shipped; ordinal1-3 as date"),
  notes = "date = 2024 + the deposited ordinal day; the year is from the abstract on the Dryad page, not the data file or README, and the ordinals span exactly the abstract's dates. At 5 sites occasions 2 and 3 share a date, with occasion 3 later by minutes since sunset. obs_barometric_pressure is as deposited; the README states no unit and the values are consistent with inHg. obs_minutes_since_sunset runs 10-1431 as deposited, never negative. An invasive species, so the flagged-taxon coordinate rule does not apply; no coordinates are deposited in any case.")
dataset$temporalCoverage <- paste(min(long$date), max(long$date), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/cecconi_2025_cricket_occ.R")

stage_dict_row(TABLE,
  description = "Aural detection/non-detection of the invasive Japanese burrowing cricket at 49 point-count sites in central Kentucky, three counts per site between 19 September and 5 November 2024, with the temperature, barometric pressure, wind speed, minutes since sunset and date of every count.",
  url = "https://doi.org/10.5061/dryad.ns1rn8q4k",
  reference = "Cecconi, S. V., Notarianni, N., & McNeil, D. J. (2025). Assessing factors associated with detection probability of the Japanese burrowing cricket (Velarifictorus micado) on point count surveys. Journal of Applied Entomology, 150(2), 200-206.",
  doi_paper = "10.1111/jen.70022", doi_data = "10.5061/dryad.ns1rn8q4k",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Insect single-season occupancy from aural point counts. Invasive species; no coordinates deposited; date rebuilt from the ordinal day and the year in the Dryad abstract.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Single-season occupancy",
  sampling_protocol = "point_count", design = "Single-season (3 aural point counts)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source",
  notes = paste0(sum(Y), " aural detections over ", length(Y), " point counts. Invasive species."))
