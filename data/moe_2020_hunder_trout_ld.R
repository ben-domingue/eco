#!/usr/bin/env Rscript
# Table:  moe_2020_hunder_trout_ld
# Source: Dryad doi:10.5061/dryad.9cnp5hqf4, version 67305 (published 2020-05-28), licence CC0 1.0
#         (as shown on Dryad). Moe, S. J., Nater, C. R., Rustadbakken, A., Vollestad, L. A.,
#         Lund, E., Qvenild, T., Hegge, O. & Aass, P. "Data from: Long-term mark-recapture and
#         growth data for large-sized migratory brown trout (Salmo trutta) from Lake Mjosa, Norway".
# Paper:  Moe, S. J. et al. (2020). Long-term mark-recapture and growth data for large-sized
#         migratory brown trout (Salmo trutta) from Lake Mjosa, Norway. Biodiversity Data Journal
#         8: e52157. doi:10.3897/BDJ.8.e52157 (the data paper; the README says to read it first).
# Data:   HunderTroutData_CMRR.csv: 18,488 encounter records of 13,975 individually marked adult
#         "Hunder trout", one row per encounter (MarkNo, CaptureNo of CaptureNoMax, MarkDate,
#         MarkYear, CaptureDate as YYYY-MM-DD, YYYY-MM or YYYY, CaptureDay/Month/Year,
#         CaptureArea, CaptureType, CaptureEquipment, LengthAtCapture mm, WeightAtCapture g,
#         Sex, Origin wild/stocked, ScaleData yes/no). Every fish's first record is a live
#         capture in the fish-ladder trap on the river Gudbrandsdalslagen during the autumn
#         spawning migration ("trap alive", "river trap"); later records are live recaptures in
#         the trap in later runs (15,709 trap-alive records in all), dead recoveries reported by
#         fishers or staff (harvest 2,322 in the lake or river by net or rod; trap dead 376;
#         found dead 72) and 9 catch-and-release encounters. Trap captures 1966-2016 (marking
#         1966-2015, recaptures only in 2016), dead recoveries 1966-2017.
#         HunderTroutData_Growth.csv (scale-read growth increments) is not shipped: it is not an
#         encounter history.
#
# Mapping (standard E9 dead-recovery capture-recapture, Burnham live-dead model; responseType
# state, unitKind individual). First live-dead table in the corpus.
#   unit = MarkNo (one fish), taxon = SALTRU, period = spawning year t = 1966..2016 (index 1..51,
#   __periods), no occasion. Each period carries two Burnham components:
#     L_t = 1 if the fish was captured alive in the river trap in calendar year t (the annual
#           live-capture occasion; 13 trap captures in April-May count for that year's run);
#     D_t = 1 if the fish was recovered dead in the interval that starts with run t: from 1 July
#           of year t to 30 June of year t+1 (harvest, trap dead or found dead). A dead
#           recovery is never placed before the fish's last live capture (if the July rule would
#           do so, as for a spring trap capture followed by a June harvest, the recovery is moved
#           to the live year; counted below).
#   y = state code 0 = neither (00), 1 = live only (10), 2 = dead only (01), 3 = live then dead in
#   the same interval (11); y_raw = the "LD" pair as text. stateCodes and respRawCodes in metadata.
#   Rows: from 1966, the study's first spawning run, to the period of dead recovery, or to 2016
#   for fish not recovered dead by 30 June 2017 (E4.4: an individual has no rows after it has
#   left the population). At-risk span (E4.4): every fish was first caught as an adult of
#   unknown age in the fish-ladder trap (wild-spawned or stocked; the deposit gives no stocking
#   or hatch year), so it is at risk from the first period: years before its marking run are
#   y = 0 (00). The marking run is unit_mark_year (always y = 1 or 3); drop earlier rows to
#   condition on first capture. Carlin-tag loss is not recorded; every fish has a capture.
#   Survey evidence (inferred): the deposit has no effort table. The trap is operated every
#   spawning run (data paper) and the deposit has trap captures in every year 1966-2016, so every
#   period is a live occasion; dead recoveries are reported continuously (harvest reporting),
#   so every interval is a recovery interval. Recovery effort (fishing pressure) is not recorded.
#   Covariates: unit_sex (NA for 520 records' fish), unit_origin (wild / stocked),
#   unit_mark_year, unit_length_mark_mm, unit_weight_mark_g (at the marking capture),
#   unit_tag_series (the MarkNo letter prefix); obs_length_mm and obs_weight_g at a live trap
#   capture in that period (first capture of the year; NA otherwise); obs_recovery_type
#   (harvest, trap dead, found dead), obs_recovery_area and obs_recovery_gear on the recovery
#   period (NA otherwise).
#   Not shipped: the 9 catch-and-release encounters (live encounters away from the trap: a
#   Barker-model resighting component the live-dead pair cannot hold); the harvest record of
#   NH 13124 dated 2007-05-11, followed by a live trap capture on 2007-07-31 (the fish was alive:
#   a data error, dropped); dead recoveries after 30 June 2017, after the last live occasion
#   (counted); the growth file.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "moe_2020_hunder_trout_ld"
dir <- download_dryad("10.5061/dryad.9cnp5hqf4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "HunderTroutData_CMRR.csv"); stopifnot(file.exists(f))

d <- fread(f, colClasses = list(character = c("MarkNo", "MarkDate", "CaptureDate")))
stopifnot(nrow(d) == 18488L, ncol(d) == 17L, uniqueN(d$MarkNo) == 13975L,
          all(d$CaptureType %in% c("trap alive", "harvest", "trap dead", "found dead", "catch release")),
          d[CaptureType == "trap alive", .N] == 15709L, d[CaptureType == "harvest", .N] == 2322L,
          d[CaptureType == "trap dead", .N] == 376L, d[CaptureType == "found dead", .N] == 72L,
          d[CaptureType == "catch release", .N] == 9L,
          all(d$Origin %in% c("wild", "stocked", NA)), all(d$Sex %in% c("female", "male", NA)),
          !anyNA(d$CaptureYear), !anyNA(d$CaptureNo))
setorder(d, MarkNo, CaptureNo)
stopifnot(!anyDuplicated(d[, .(MarkNo, CaptureNo)]),
          # every fish is marked alive in the river trap, and that is its first record
          all(d[CaptureNo == 1L, CaptureType == "trap alive" & CaptureArea == "river trap"]),
          d[CaptureNo == 1L, .N] == 13975L,
          d[CaptureType == "trap alive", all(CaptureArea == "river trap")],
          d[CaptureType == "trap alive", range(CaptureYear)] == c(1966L, 2016L),
          d[CaptureNo == 1L, range(CaptureYear)] == c(1966L, 2015L),
          setequal(d[CaptureType == "trap alive", unique(CaptureYear)], 1966:2016))

# the one fish recorded dead and then alive: drop the harvest record
bad <- d[, .(n = sum(CaptureType %in% c("harvest", "trap dead", "found dead") & CaptureNo < max(CaptureNo[CaptureType == "trap alive"]))), by = MarkNo][n > 0]
stopifnot(identical(bad$MarkNo, "NH 13124"))
d <- d[!(MarkNo == "NH 13124" & CaptureType == "harvest")]
n_cr <- d[CaptureType == "catch release", .N]
d <- d[CaptureType != "catch release"]
d[, dead := CaptureType %in% c("harvest", "trap dead", "found dead")]
stopifnot(all(d[, sum(dead), by = MarkNo]$V1 <= 1L))     # at most one dead recovery per fish

# live occasions: calendar year of the trap capture
live <- d[dead == FALSE, .(L = 1L, obs_length_mm = LengthAtCapture[1], obs_weight_g = WeightAtCapture[1]),
          by = .(MarkNo, year = CaptureYear)]
last_live <- live[, .(last_live = max(year)), by = MarkNo]
# dead recoveries: interval from 1 July of t to 30 June of t+1
rec <- d[dead == TRUE, .(MarkNo, CaptureYear, CaptureMonth, CaptureDate, obs_recovery_type = CaptureType,
                         obs_recovery_area = CaptureArea, obs_recovery_gear = CaptureEquipment)]
n_nomonth <- rec[is.na(CaptureMonth), .N]
stopifnot(n_nomonth == 6L)   # year-only dates (5 harvests, 1 trap dead): placed by the last-live rule below
rec[, year := ifelse(!is.na(CaptureMonth) & CaptureMonth >= 7L, CaptureYear, CaptureYear - 1L)]
rec <- merge(rec, last_live, by = "MarkNo")
n_moved <- rec[year < last_live, .N]
rec[year < last_live, year := last_live]
n_after <- rec[year > 2016L, .N]
rec <- rec[year <= 2016L]
cat(sprintf("  %d dead recoveries placed; %d moved to the last live year; %d after the last occasion dropped; %d year-only dates\n",
            nrow(rec), n_moved, n_after, n_nomonth))

fish <- d[CaptureNo == 1L, .(MarkNo, mark_year = CaptureYear, unit_sex = Sex, unit_origin = Origin,
                             unit_length_mark_mm = LengthAtCapture, unit_weight_mark_g = WeightAtCapture)]
fish[, unit_tag_series := trimws(sub("[0-9].*$", "", MarkNo))]
fish <- merge(fish, rec[, .(MarkNo, end = year)], by = "MarkNo", all.x = TRUE)
fish[is.na(end), end := 2016L]
stopifnot(all(fish$end >= fish$mark_year))
grid <- fish[, .(year = 1966L:end), by = MarkNo]                     # E4.4: wild-caught adults, at risk from 1966
long <- merge(grid, live, by = c("MarkNo", "year"), all.x = TRUE)
long <- merge(long, rec[, .(MarkNo, year, D = 1L, obs_recovery_type, obs_recovery_area, obs_recovery_gear)],
              by = c("MarkNo", "year"), all.x = TRUE)
long[is.na(L), L := 0L][is.na(D), D := 0L]
long <- merge(long, fish[, .(MarkNo, unit_sex, unit_origin, mark_year, unit_length_mark_mm, unit_weight_mark_g, unit_tag_series)], by = "MarkNo")
stopifnot(nrow(long) == sum(fish$end - 1966L + 1L), all(long[year < mark_year, L == 0L & D == 0L]),
          sum(long$L) == nrow(live), sum(long$D) == nrow(rec),
          all(long[year == mark_year, L == 1L]))
long <- long[, .(unit = MarkNo, taxon = "SALTRU", y = L + 2L * D, y_raw = paste0(L, D), period = year - 1965L,
                 unit_sex, unit_origin, unit_mark_year = mark_year, unit_length_mark_mm, unit_weight_mark_g, unit_tag_series,
                 obs_length_mm, obs_weight_g, obs_recovery_type, obs_recovery_area, obs_recovery_gear)]
long <- order_eco(long)
stopifnot(!anyDuplicated(long[, .(unit, period)]), all(long$y %in% 0:3), uniqueN(long$unit) == 13975L)
cat(sprintf("  %d fish, %d rows; states: %s\n", uniqueN(long$unit), nrow(long), paste(names(table(long$y_raw)), table(long$y_raw), sep = "=", collapse = " ")))

periods <- data.table(period = 1:51, year = 1966:2016)
periods <- merge(periods, fish[, .(n_marked = .N), by = .(year = mark_year)], by = "year", all.x = TRUE)
periods <- merge(periods, live[, .(n_live = .N), by = year], by = "year", all.x = TRUE)
periods <- merge(periods, rec[, .(n_dead_recoveries = .N), by = year], by = "year", all.x = TRUE)
for (c in c("n_marked", "n_live", "n_dead_recoveries")) set(periods, which(is.na(periods[[c]])), c, 0L)
periods[, n_live_recaptures := n_live - n_marked][, n_live := NULL]
periods[, note := "live occasion = trap captures in calendar year `year`; recovery interval = 1 July `year` to 30 June `year`+1"]
setcolorder(periods, c("period", "year"))

taxa <- make_taxa("SALTRU", "Salmo trutta", vernacularName = "Brown trout (Hunder trout, Lake Mjosa)")
taxa[, taxon_iucnCategory := "LC"]

dataset <- list(
  title = "Hunder brown trout live-recapture and dead-recovery histories, Lake Mjosa and river Gudbrandsdalslagen, Norway, 1966-2016",
  creator = "Moe, S. Jannicke; Nater, Chloe R.; Rustadbakken, Atle; Vollestad, L. Asbjorn; Lund, Espen; Qvenild, Tore; Hegge, Ola; Aass, Per", pubDate = "2020",
  doi = "10.5061/dryad.9cnp5hqf4", sourceURL = "https://doi.org/10.5061/dryad.9cnp5hqf4",
  citation = "Moe, S. J., Nater, C. R., Rustadbakken, A., Vollestad, L. A., Lund, E., Qvenild, T., Hegge, O. & Aass, P. (2020). Data from: Long-term mark-recapture and growth data for large-sized migratory brown trout (Salmo trutta) from Lake Mjosa, Norway. Dryad. https://doi.org/10.5061/dryad.9cnp5hqf4",
  paperDOI = "10.3897/BDJ.8.e52157",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Burnham live-dead histories of 13,975 adult brown trout marked in the fish-ladder trap on the river Gudbrandsdalslagen during their spawning migration from Lake Mjosa, 1966-2015, recaptured alive in the trap in later runs (to 2016) and recovered dead by fishers or staff (harvest, found dead, dead in the trap). One row per fish per spawning year from 1966 to dead recovery or 2016 (years before marking are y = 0): y = 0 not encountered, 1 captured alive in the trap that year, 2 recovered dead in the interval after that year's run (1 July to 30 June), 3 both; y_raw = the live-dead pair.",
  samplingProtocol = "Adults ascending the river Gudbrandsdalslagen to spawn are caught in a trap in the fish ladder at the Hunderfossen hydropower dam each summer and autumn, measured, weighed, sexed where possible, Carlin-tagged and released upstream; stocked hatchery fish are marked as well. Live recaptures are trap captures in later runs; dead recoveries are tag returns from anglers and net fishers in the lake and river, fish found dead, and fish dead in the trap (data paper, Moe et al. 2020).",
  samplingProtocolCode = "tag_recovery", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort table is deposited. The trap is operated in every spawning run (data paper) and the deposit has live trap captures in every year 1966-2016, so every period is a live occasion; tag recovery from the fishery is continuous, so every interval is a recovery interval. Fishing effort, and so recovery probability, is not recorded and varies over the 51 years.",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "open between periods (Burnham live-dead model: one live-capture occasion per spawning run and one dead-recovery interval after it; no closure assumed within a period)", occasionKind = "none", taxonInclusion = "single",
  stateCodes = list(`0` = "not encountered in period t (live 0, dead 0)", `1` = "captured alive in the river trap in calendar year t (live 1, dead 0)",
                    `2` = "recovered dead between 1 July of t and 30 June of t+1 (live 0, dead 1)", `3` = "captured alive in run t and recovered dead in the following interval (live 1, dead 1)"),
  respRawCodes = list(`00` = "neither", `10` = "live capture only", `01` = "dead recovery only", `11` = "live capture and dead recovery"),
  geographicCoverage = "Lake Mjosa and the river Gudbrandsdalslagen at Hunderfossen, Innlandet, Norway (61.2 N, 10.4 E); recoveries in the lake, the river above and below the dam and a few in the river Glomma; no coordinates deposited",
  temporalCoverage = "1966-07/2017-06",
  coordinatesCoarsened = NA,
  notes = sprintf("First live-dead (Burnham) table in eco. Rows run from 1966 (E4.4: fish first caught as adults of unknown age are at risk from the first run; unit_mark_year is the marking run, so drop earlier rows to condition on first capture) to the dead-recovery period, or to 2016; the period of dead recovery is a fish's last row. Dead recoveries are placed by date in the interval 1 July of t to 30 June of t+1; %d recoveries with year-only dates were placed by year with the same rule (an April-June harvest assumed when no month), and %d recoveries that the rule would have put before the fish's last live capture were moved to the live year. Spring trap captures (13, April-May) are live captures of that calendar year. The deposit's ScaleData flag and the growth file are not shipped. Recovery covariates (type, area, gear) are on the recovery row.", n_nomonth, n_moved),
  notShipped = list(`catch and release` = sprintf("%d live encounters away from the trap (Barker-model resightings; the live-dead pair has no cell for them)", n_cr),
                    `dead-then-alive record` = "NH 13124: a harvest dated 2007-05-11 followed by a live trap capture on 2007-07-31; the harvest record is dropped",
                    `recoveries after the last occasion` = sprintf("%d dead recoveries dated after 30 June 2017 (no live occasion follows)", n_after),
                    `growth data` = "HunderTroutData_Growth.csv: scale-read growth increments, not an encounter history"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/moe_2020_hunder_trout_ld.R")
stage_dict_row(TABLE,
  description = "Burnham live-dead histories of 13,975 adult migratory brown trout (Salmo trutta, Hunder trout) marked in a river fish-ladder trap 1966-2015, live-recaptured in the trap to 2016 and recovered dead by the fishery; one row per fish x spawning year, y = state (0 none, 1 live, 2 dead recovery, 3 both), y_raw = live-dead pair. First dead-recovery table.",
  url = "https://doi.org/10.5061/dryad.9cnp5hqf4",
  reference = "Moe, S. J., Nater, C. R., Rustadbakken, A., Vollestad, L. A., Lund, E., Qvenild, T., Hegge, O., & Aass, P. (2020). Long-term mark-recapture and growth data for large-sized migratory brown trout (Salmo trutta) from Lake Mjosa, Norway. Biodiversity Data Journal, 8, e52157.",
  doi_paper = "10.3897/BDJ.8.e52157", doi_data = "10.5061/dryad.9cnp5hqf4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Live-dead (Burnham) encoding: dead recoveries placed in the 1 July - 30 June interval after each run; catch-and-release encounters not shipped; survey set inferred (trap captures every year).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Dead recovery / live-dead capture-recapture (Burnham)",
  sampling_protocol = "tag_recovery", design = "Multi-session (51 spawning runs, live capture plus dead-recovery interval)", realm = "Freshwater",
  country = "NOR", coordinates = "None in source", notes = "Individuals as unit; rows from 1966 (adults of unknown age) to dead recovery or 2016; y = live-dead state.")
