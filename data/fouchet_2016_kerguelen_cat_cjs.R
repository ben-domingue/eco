#!/usr/bin/env Rscript
# Table:  fouchet_2016_kerguelen_cat_cjs
# Source: Dryad doi:10.5061/dryad.53j96, version 8610 (published 2015-10-26), licence CC0 1.0 (as shown on the
#         Dryad landing page and in the API record). Fouchet, D., Santin-Janin, H., Sauvage, F., Yoccoz, N. G.
#         & Pontier, D. "Data from: An R package for analyzing survival using continuous-time open capture-
#         recapture models".
# Paper:  Fouchet, D., Santin-Janin, H., Sauvage, F., Yoccoz, N. G. & Pontier, D. (2016). An R package for
#         analyzing survival using continuous-time open capture-recapture models. Methods in Ecology and
#         Evolution 7, doi:10.1111/2041-210X.12497 (not read; design from the Dryad usage notes).
# Data:   one workbook, "KERGUELEN data.xls" (Dryad usage notes: "Long-term dataset of capture-mark-recapture
#         of feral cats collected at three sites in the Grande Terre Island of the Kerguelen archipelago").
#         captocc: 196 capture sessions, start and end date and population (1, 2, 3: 68, 71 and 57 sessions,
#           October 1994 to August 2013, 5 to 28 days long, never overlapping within a population).
#         sptvar: NDVI per population (1-4) and year 1984-2010 ("variables that vary in time and between the
#           populations"); population 4 has no sessions.
#         indvar: 1,203 capture records of 684 cats: ind, pop, sex (0 female, 1 male), age (months), physical
#           condition (PC), date. Every record falls inside exactly one session of its population and every
#           session has at least one capture (asserted); no cat is in two populations; one cat (Y624) is
#           recorded as male once and female once. The age column does not advance with the capture dates
#           within a cat (it is not age at capture in any documented sense).
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = ind; taxon = FELCAT; period = the session, numbered 1..196 over all three populations in order of
#   start date (ties by population), __periods carrying start, end, population and that population's NDVI
#   for the session's start year; y = 1 if the cat was captured in the session; cluster_id = unit_population
#   = population; unit_sex (female / male; NA for Y624); obs_body_condition = PC at the cat's first capture
#   in the session (NA on non-capture rows); obs_n_captures (capture records in the session).
#   At-risk rows (E4.4): wild-caught cats, so every session of the cat's population from that population's
#   first session to its last; rows before first capture are 0. Survey evidence: sample_table (captocc).
#   Not shipped: age (undocumented; does not advance with date); capture dates within a session (the
#   continuous-time detail, summarised as obs_n_captures); NDVI for population 4 and years without sessions.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "fouchet_2016_kerguelen_cat_cjs"
dir <- download_dryad("10.5061/dryad.53j96", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "8610"), length(list.files(dir)) == 1L)
f <- file.path(dir, "KERGUELEN data.xls")
stopifnot(identical(excel_sheets(f), c("captocc", "sptvar", "indvar")))
s <- as.data.table(read_excel(f, "captocc")); nd <- as.data.table(read_excel(f, "sptvar")); i <- as.data.table(read_excel(f, "indvar"))
stopifnot(identical(names(s), c("start", "end", "pop")), identical(names(nd), c("pop", "date", "NDVI")),
          identical(names(i), c("ind", "pop", "sex", "age", "PC", "date")),
          nrow(s) == 196L, nrow(nd) == 108L, nrow(i) == 1203L, uniqueN(i$ind) == 684L,
          identical(as.integer(table(s$pop)), c(68L, 71L, 57L)), all(i$sex %in% 0:1), all(i$pop %in% 1:3))
s[, `:=`(start = as.IDate(start), end = as.IDate(end), pop = as.integer(pop))]
i[, `:=`(date = as.IDate(date), pop = as.integer(pop))]
nd[, `:=`(pop = as.integer(pop), year = as.integer(date), NDVI = as.numeric(NDVI))]
setorder(s, start, pop)
s[, period := seq_len(.N)]
stopifnot(all(s$end >= s$start), s[, all(as.integer(end - start) %between% c(5L, 28L))],
          s[order(pop, start), all(shift(end) < start, na.rm = TRUE), by = pop][, all(V1)])
i[, period := vapply(seq_len(.N), function(k) { w <- s[pop == i$pop[k] & start <= i$date[k] & end >= i$date[k], period]
  if (length(w) == 1L) w else NA_integer_ }, 0L)]
stopifnot(!anyNA(i$period), uniqueN(i$period) == 196L, i[, uniqueN(pop), by = ind][, all(V1 == 1L)])
sexes <- i[, .(sx = if (uniqueN(sex) == 1L) c("female", "male")[sex[1] + 1L] else NA_character_), by = ind]
stopifnot(identical(sexes[is.na(sx), ind], "Y624"))

setorder(i, ind, date)
cap <- i[, .(y = 1L, obs_body_condition = as.numeric(PC[1]), obs_n_captures = .N), by = .(ind, period)]
stopifnot(sum(cap$obs_n_captures) == 1203L, all(cap$obs_n_captures %in% 1:2))
cats <- unique(i[, .(ind, pop)])
grid <- merge(cats, s[, .(pop, period)], by = "pop", allow.cartesian = TRUE)
long <- merge(grid, cap, by = c("ind", "period"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_n_captures = 0L)]
long <- merge(long, sexes, by = "ind")
long <- order_eco(long[, .(unit = ind, taxon = "FELCAT", y, period, cluster_id = as.character(pop),
                           unit_population = pop, unit_sex = sx, obs_body_condition, obs_n_captures)])
stopifnot(nrow(long) == sum(c(68L, 71L, 57L)[cats$pop]), sum(long$y) == nrow(cap), uniqueN(long$unit) == 684L)

periods <- s[, .(period, period_start = as.character(start), period_end = as.character(end), period_population = pop,
                 year = year(start))]
periods <- merge(periods, nd[, .(period_population = pop, year, period_ndvi = NDVI)], by = c("period_population", "year"), all.x = TRUE)
periods <- periods[order(period), .(period, period_start, period_end, period_population, period_ndvi)]
stopifnot(nrow(periods) == 196L, sum(is.na(periods$period_ndvi)) == s[year(start) > 2010, .N])
taxa <- make_taxa("FELCAT", "Felis catus", vernacularName = "Feral cat")

dataset <- list(
  title = "Capture histories of 684 feral cats over 196 trapping sessions at three sites on Grande Terre, Kerguelen Islands, 1994-2013",
  creator = "Fouchet, David; Santin-Janin, Hugues; Sauvage, Frank; Yoccoz, Nigel Gilles; Pontier, Dominique",
  pubDate = "2015", doi = "10.5061/dryad.53j96", sourceURL = "https://doi.org/10.5061/dryad.53j96",
  citation = "Fouchet, D., Santin-Janin, H., Sauvage, F., Yoccoz, N. G., & Pontier, D. (2015). Data from: An R package for analyzing survival using continuous-time open capture-recapture models [Dataset]. Dryad. https://doi.org/10.5061/dryad.53j96",
  paperDOI = "10.1111/2041-210X.12497",
  abstract = "A long-term capture-mark-recapture study of introduced feral cats at three sites on Grande Terre, the main island of the sub-Antarctic Kerguelen archipelago, October 1994 to August 2013: trapping sessions of 5 to 28 days, several a year at each site, with the date, sex and physical condition of every capture. The authors used it to illustrate survival analysis for continuous-time capture protocols.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Capture sessions of 5 to 28 days at each of three sites; cats captured, individually marked, sexed and assessed for physical condition, with the date of every capture recorded. Here each session is a period and a cat's captures in it are pooled.",
  samplingProtocolCode = "live_trap", surveyEvidence = "sample_table",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "captures within a session are pooled to one record (obs_n_captures counts them); sessions are the primary periods",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "not recorded in the deposit",
  geographicCoverage = "Three sites on Grande Terre, Kerguelen Islands (French Southern and Antarctic Lands); site names and coordinates not deposited",
  temporalCoverage = "1994-10/2013-08",
  covariateNote = "cluster_id and unit_population: the deposit's population (site) 1, 2 or 3. unit_sex: NA for one cat recorded with both sexes. obs_body_condition: the deposited physical-condition index (PC, centred) at the cat's first capture in the session. __periods: session start and end dates, the population trapped, and that population's NDVI for the start year (NA after 2010, the last NDVI year deposited).",
  notShipped = list(age = "age in months: does not advance with capture date within a cat and is undocumented",
                    capture_dates = "the date of each capture within a session (continuous-time detail; obs_n_captures gives the number)",
                    ndvi_extra = "NDVI for population 4, which has no sessions, and for years without sessions"),
  notes = "Each cat has rows for every session of its own population (wild-caught, so from the population's first session, E4.4); rows before first capture are 0. Periods are numbered across all three populations in order of start date, so period indices are not consecutive within a population; use period_start for intervals.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fouchet_2016_kerguelen_cat_cjs.R")
stage_dict_row(TABLE,
  description = "Session-level capture histories of 684 introduced feral cats over 196 trapping sessions at three sites on Grande Terre, Kerguelen Islands, 1994-2013, with sex, body condition and session dates.",
  url = "https://doi.org/10.5061/dryad.53j96",
  reference = "Fouchet, D., Santin-Janin, H., Sauvage, F., Yoccoz, N. G., & Pontier, D. (2016). An R package for analyzing survival using continuous-time open capture-recapture models. Methods in Ecology and Evolution, 7.",
  doi_paper = "10.1111/2041-210X.12497", doi_data = "10.5061/dryad.53j96",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; captures pooled to sessions from the deposited session table; age column not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (57-71 sessions per site over 20 years)",
  realm = "Terrestrial", country = "ATF", coordinates = "None in source",
  notes = "Invasive predator on a sub-Antarctic island; sessions of unequal length and spacing.")
