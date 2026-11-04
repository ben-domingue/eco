#!/usr/bin/env Rscript
# Table:  karvemo_2024_nacka_grasssnake_cjs
# Source: Dryad doi:10.5061/dryad.2z34tmpt4 (CC0 1.0 as shown on the dataset JSON), version
#   276313 (published 2024-01-31). Kärvemo, S., Elmberg, J., Palmheden, L., Edelstam, C. &
#   Hagman, M. Data from: Climate change-induced shifts in survival and size of the world's
#   northernmost oviparous snake: a 68-year study.
# Paper:  Kärvemo, S., et al. (2024). PLOS ONE 19: e0300363, doi:10.1371/journal.pone.0300363.
# Data:   Capture_data.xlsx (one sheet, 2,122 capture records of 1,113 individually marked
#         grass snakes Natrix natrix, Nacka nature reserve near Stockholm, by Carl Edelstam
#         1942-2009): Ind, Capture occasion (1 = first capture, 2 = first recapture, ...),
#         Capture date (Excel serial), Season (March = Winter, April-May = Spring, June-August
#         = Summer, September-October = Autumn), Sex (F, M, NA = juvenile or unidentified),
#         SVL (cm), Body mass (g). Records exist in 66 of the 68 years (none in 1943, 1965).
#         Snow_cover_and_winter_survival_data.xlsx: per year 1969-2001 and sex, maximum snow
#         cover (cm) and the authors' estimated winter survival.
#
# Mapping (standard section 3.4, CJS): unit = snake (Ind), taxon = NATNAT, period = calendar
#   year with at least one capture (66 periods, year in __periods), y = 1 if the snake was
#   captured that year. No `occasion`: captures within a year are pooled (the paper's seasonal
#   models are a finer split a user can rebuild from obs_seasons).
#   Survey evidence: inferred. One collector searched the reserve by hand every year he could;
#   a year with at least one capture is a surveyed year; 1943 and 1965 have no records and no
#   rows. Effort varied greatly between years (1 to 112 captures per year) and is not recorded.
#   Rows before first capture are kept as 0 (E4).
#   unit_sex = recorded sex (F/M); "U" for snakes only ever recorded as juvenile/unidentified
#   and for the one snake recorded as both. obs_n_captures = captures that year; obs_seasons =
#   ";"-joined seasons with a capture that year (empty on non-capture rows).
#   __periods: year, records that year, and max_snow_cm (1969-2001; identical for both sexes in
#   the deposit, asserted). Not shipped: the estimated winter survival column (a model output,
#   standard: model outputs are not covariates). Coordinates: the paper gives the reserve
#   centre (59.29 N, 18.15 E); no capture locations are deposited; Natrix natrix is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "karvemo_2024_nacka_grasssnake_cjs"
dir <- download_dryad("10.5061/dryad.2z34tmpt4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fc <- file.path(dir, "Capture_data.xlsx"); fs <- file.path(dir, "Snow_cover_and_winter_survival_data.xlsx")
stopifnot(file.exists(fc), file.exists(fs))
x <- as.data.table(suppressWarnings(read_excel(fc, col_types = "text")))
stopifnot(identical(names(x), c("Ind", "Capture occasion", "Capture date", "Season", "Sex", "SVL (cm)", "Body mass (g)")))
setnames(x, c("ind", "occ", "date", "season", "sex", "svl", "mass"))
stopifnot(nrow(x) == 2122L, uniqueN(x$ind) == 1113L, !anyNA(x$date))
x[, d := as.Date(as.numeric(date), origin = "1899-12-30")]
x[, year := as.integer(format(d, "%Y"))]
stopifnot(!anyNA(x$d), min(x$d) == as.Date("1942-05-22"), max(x$d) == as.Date("2009-04-30"))
stopifnot(setequal(unique(x$season), c("Winter", "Spring", "Summer", "Autumn")))
stopifnot(setequal(unique(x$sex), c("F", "M", "NA")) || setequal(unique(x$sex), c("F", "M", "NA", NA)))
# capture-occasion numbering against date order within each snake (reported, not relied on)
setorder(x, ind, d, occ)
n_misordered <- x[, !all(as.integer(occ) == seq_len(.N)), by = ind][, sum(V1)]
cat(sprintf("  %d snake(s) whose capture-occasion numbers do not follow date order\n", n_misordered))
yrs <- sort(unique(x$year))
stopifnot(length(yrs) == 66L, identical(setdiff(1942:2009, yrs), c(1943L, 1965L)))
Tn <- length(yrs); x[, period := match(year, yrs)]

ids <- sort(unique(as.integer(x$ind)))
yr <- x[, .(n = .N, seasons = paste(unique(season), collapse = ";")), by = .(ind = as.integer(ind), period)]
CH <- matrix(0L, length(ids), Tn); CH[cbind(match(yr$ind, ids), yr$period)] <- 1L
sxs <- x[sex %in% c("F", "M"), .(nsex = uniqueN(sex), sex = sex[1]), by = .(ind = as.integer(ind))]
stopifnot(sum(sxs$nsex > 1L) == 1L)
sxs[nsex > 1L, sex := "U"]
covs <- data.frame(sex = ifelse(is.na(sxs$sex[match(ids, sxs$ind)]), "U", sxs$sex[match(ids, sxs$ind)]))

long <- array_to_eco(CH, taxon = "NATNAT", site_ids = ids, site_covs = covs, period = seq_len(Tn))
long[, occasion := NULL]
long[yr, on = .(unit = ind, period), `:=`(obs_n_captures = i.n, obs_seasons = i.seasons)]
long[is.na(obs_n_captures), `:=`(obs_n_captures = 0L, obs_seasons = "")]
stopifnot(nrow(long) == length(ids) * Tn, sum(long$y) == nrow(yr), sum(long$obs_n_captures) == nrow(x))
cat(sprintf("  %d snakes, %d captures -> %d snake-years over %d years; sex F %d, M %d, U %d\n", length(ids), nrow(x),
            nrow(yr), Tn, sum(covs$sex == "F"), sum(covs$sex == "M"), sum(covs$sex == "U")))

snow <- as.data.table(read_excel(fs, sheet = "survsnow"))
stopifnot(identical(names(snow), c("Year", "Season", "Survival", "Max snow (cm)", "Sex")), nrow(snow) == 66L)
sn <- snow[, .(max_snow_cm = unique(`Max snow (cm)`)), by = Year]
stopifnot(nrow(sn) == 33L, identical(sn$Year, as.numeric(1969:2001)) || identical(as.integer(sn$Year), 1969:2001))

taxa <- make_taxa("NATNAT", "Natrix natrix", vernacularName = "Grass Snake")
periods <- x[, .(n_captures = .N, n_snakes = uniqueN(ind)), by = .(period, year)][order(period)]
periods[sn, on = .(year = Year), max_snow_cm := i.max_snow_cm]
periods[, note := "calendar year of hand captures, March-November; max_snow_cm = maximum snow cover of the winter before (1969-2001 only)"]

dataset <- list(
  title = "Annual capture histories of 1,113 grass snakes, Nacka nature reserve, Sweden, 1942-2009",
  creator = "Kärvemo, Simon; Elmberg, Johan; Palmheden, Linda; Edelstam, Carl; Hagman, Mattias", pubDate = "2024",
  doi = "10.5061/dryad.2z34tmpt4", sourceURL = "https://doi.org/10.5061/dryad.2z34tmpt4",
  citation = "Kärvemo, S., Elmberg, J., Palmheden, L., Edelstam, C., & Hagman, M. (2024). Data from: Climate change-induced shifts in survival and size of the worlds' northernmost oviparous snake: a 68-year study [Dataset]. Dryad. https://doi.org/10.5061/dryad.2z34tmpt4",
  paperDOI = "10.1371/journal.pone.0300363",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Hand-capture and recapture records of 1,113 individually marked grass snakes (Natrix natrix) collected by Carl Edelstam in the Nacka nature reserve near Stockholm, 1942-2009, with sex, snout-vent length and mass, plus maximum winter snow cover 1969-2001. Pooled here to annual capture histories over the 66 years with captures.",
  samplingProtocol = "Opportunistic hand capture by one collector during the active season (March-November); snakes marked by scale clipping and natural ventral pattern; one capture record per encounter.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "inferred",
  surveyEvidenceNote = "A calendar year with at least one capture record is a surveyed year; 1943 and 1965 have no records and no rows. Search effort per year is not recorded and varied greatly (1 to 112 captures per year).",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "period (captures within a year pooled; survival between years)", occasionKind = "none", taxonInclusion = "single",
  lossesOnCapture = "none recorded",
  geographicCoverage = "Nacka nature reserve (7.3 km2), Stockholm County, Sweden; reserve centre 59.29 N, 18.15 E as given in the paper; capture locations not deposited",
  temporalCoverage = "1942/2009", coordinatesCoarsened = NA,
  notShipped = list(winter_survival = "the authors' estimated proportional winter survival per year and sex (a model output)",
                    body_size = "SVL and body mass per capture (vary within individual)"),
  notes = "Rows before first capture kept as 0 (E4). Period indices are consecutive over the 66 years with captures; use __periods$year for intervals (1942-1944 and 1964-1966 span two years). obs_seasons gives the seasons with captures for users who want seasonal occasions.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/karvemo_2024_nacka_grasssnake_cjs.R")

stage_dict_row(TABLE,
  description = "Annual capture histories of 1,113 individually marked grass snakes (Natrix natrix) in the Nacka nature reserve, Sweden, over 66 years with captures 1942-2009 (one collector, hand captures), with sex, captures and seasons per year, and maximum winter snow cover 1969-2001 in __periods.",
  url = "https://doi.org/10.5061/dryad.2z34tmpt4",
  reference = "Kärvemo, S., Elmberg, J., Palmheden, L., Edelstam, C., & Hagman, M. (2024). Climate change-induced shifts in survival and size of the world's northernmost oviparous snake: a 68-year study. PLOS ONE 19(3): e0300363.",
  doi_paper = "10.1371/journal.pone.0300363", doi_data = "10.5061/dryad.2z34tmpt4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Survey years inferred from capture records; effort not recorded. Estimated winter survival (model output) not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-session (66 capture years)", realm = "Terrestrial",
  country = "SWE", coordinates = "None in source", notes = "Individuals as unit; longest series in the corpus (68 years).")
