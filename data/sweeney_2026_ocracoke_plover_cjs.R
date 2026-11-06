#!/usr/bin/env Rscript
# Tables: sweeney_2026_ocracoke_plover_cjs (resighting histories of marked piping plovers) and
#         sweeney_2026_ocracoke_plover_count (survey counts of all plovers)
# Source: Dryad, doi:10.5061/dryad.0zpc867d2, version 464290 (published 2026-09-17), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API). Sweeney, C. E., Wails, C. N., Alvino, C. R., Oliver, K. W., Maddock,
#         S. B., Catlin, D. H., Fraser, J. D. & Karpanty, S. M. Data from: Storm-driven habitat loss reduced migrating
#         piping plover abundance and stopover time, not body condition, at a key site.
# Paper:  the same title, Ecosphere (per the file names; no DOI on the Dryad record; not read). Design from the
#         Dryad abstract, methods and README: fall-migration surveys (July-October 2016-2023) of piping plovers
#         (Charadrius melodus, US federally threatened) on South Point, Ocracoke Island, North Carolina, before and
#         after Hurricane Dorian (September 2019); on each survey observers counted all plovers and recorded marked
#         (banded / flagged) birds; birds were also trapped and banded; the data are structured for an integrated
#         Jolly-Seber and binomial-count superpopulation (stopover) model.
# Data:   surveys_Sweeney_et_al_Ecosphere.csv (207 surveys): date (m/d/Y), marked (count of banded plovers seen,
#           including unidentified marks; a bird may be counted twice), total (all plovers), yday.
#         chs_Sweeney_et_al_Ecosphere.zip -> ch_2016.csv .. ch_2023.csv: anon (anonymised individual number,
#           consistent across years) x the dates of that year's completed surveys (1 seen, 0 not); a bird is listed in
#           a year only if seen that year. The survey dates are exactly the surveys file's dates (asserted).
#         masses_Sweeney_et_al_Ecosphere.csv (100 captures, 2017-2023): date, mass (g; one NA), tarsus (mm), age
#           (HY hatch-year, AHY after-hatch-year), flag (band / flag code), month, year, anon (NA for 39 birds not in
#           any history). README: newly banded birds were excluded from their capture year's history.
# Mapping, cjs (Jolly-Seber histories; responseType detection, unitKind individual): unit = anon, taxon = CHAMEL,
#   period = year 1..8 (2016-2023), occasion = survey within the year, date = the survey date, y = 0/1 as deposited.
#   surveyEvidence = sample_table (the surveys file lists the completed surveys). At risk (E4.4): a bird of unknown
#   age has rows from 2016; a bird first captured here as a hatch-year (HY) has rows from its capture year (not yet
#   hatched before). A bird banded here has no rows in its banding year, because the authors removed that year's
#   resightings (README; asserted: such a bird is never in its capture year's history, while the 6 birds that are
#   were resighted before their capture date, i.e. already marked); a 0 there would be invented. Birds never in a history are not units. No removals or lost
#   marks are recorded, so histories run to 2023. unit_ covariates from the bird's capture here (mass, tarsus, age
#   class, capture year), NA for birds banded elsewhere.
# Mapping, count (responseType count, unitKind site): unit = South Point (one site), taxon = CHAMEL, period = year,
#   occasion = survey, date, y = total; obs_marked = the marked count. surveyEvidence = sample_table.
# Not shipped: band / flag codes (the authors anonymised identifiers for this threatened species); yday (equal to
#   the date); month and year of the masses file (in the date); model estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sweeney_2026_ocracoke_plover_cjs"
COUNT <- "sweeney_2026_ocracoke_plover_count"
dir <- download_dryad("10.5061/dryad.0zpc867d2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
inner <- file.path(dir, "chs_Sweeney_et_al_Ecosphere.zip")
if (!file.exists(inner)) unzip(paste0(dir, ".zip"), files = basename(inner), exdir = dir)
stopifnot(setequal(list.files(dir), c("masses_Sweeney_et_al_Ecosphere.csv", "surveys_Sweeney_et_al_Ecosphere.csv",
                                      "chs_Sweeney_et_al_Ecosphere.zip", "README.md")))
chdir <- file.path(tempdir(), "sweeney_chs"); dir.create(chdir, showWarnings = FALSE)
unzip(inner, exdir = chdir)
stopifnot(setequal(list.files(chdir), sprintf("ch_%d.csv", 2016:2023)))

sv <- fread(file.path(dir, "surveys_Sweeney_et_al_Ecosphere.csv"), encoding = "UTF-8")
setnames(sv, 1, "date")
stopifnot(identical(names(sv), c("date", "marked", "total", "yday")), nrow(sv) == 207L, !anyNA(sv))
sv[, d := as.IDate(date, format = "%m/%d/%Y")]
stopifnot(!anyNA(sv$d), !anyDuplicated(sv$d), all(sv$yday == yday(sv$d)), all(sv$marked <= sv$total & sv$marked >= 0),
          all(month(sv$d) %in% 7:10), identical(as.vector(table(year(sv$d))), c(22L, 33L, 33L, 20L, 21L, 37L, 20L, 21L)))
setorder(sv, d)
sv[, `:=`(period = year(d) - 2015L, occasion = seq_len(.N)), by = .(year(d))]

ch <- rbindlist(lapply(2016:2023, function(yr) {
  x <- fread(file.path(chdir, sprintf("ch_%d.csv", yr)), colClasses = "character", encoding = "UTF-8")
  setnames(x, 1, "anon")
  dts <- as.IDate(names(x)[-1], format = "%m/%d/%Y")
  stopifnot(!anyNA(dts), setequal(dts, sv[year(d) == yr, d]), !anyDuplicated(x$anon))
  m <- as.matrix(x[, -1]); stopifnot(all(m %in% c("0", "1")), all(rowSums(m == "1") >= 1))
  data.table(anon = rep(x$anon, ncol(m)), d = rep(dts, each = nrow(m)), y = as.integer(as.vector(m)))
}))
stopifnot(uniqueN(ch$anon) == 399L, sum(ch$y) == 2571L)
seen_years <- ch[, .(years = list(sort(unique(year(d))))), by = anon]

ms <- fread(file.path(dir, "masses_Sweeney_et_al_Ecosphere.csv"), encoding = "UTF-8", colClasses = list(character = c("anon", "flag")))
setnames(ms, 1, "date")
stopifnot(nrow(ms) == 100L, identical(names(ms), c("date", "mass", "tarsus", "age", "flag", "month", "year", "anon")),
          setequal(ms$age, c("HY", "AHY")), sum(is.na(ms$mass)) == 1L)
ms[anon == "NA", anon := NA_character_]
ms[, d := as.IDate(date, format = "%m/%d/%Y")]
stopifnot(!anyNA(ms$d), all(year(ms$d) == ms$year), sum(is.na(ms$anon)) == 39L, !anyDuplicated(na.omit(ms$anon)))
mk <- merge(ms[!is.na(anon)], seen_years, by = "anon", all.x = TRUE)
mk[, `:=`(in_year = mapply(function(y, ys) y %in% ys, year, years), before = mapply(function(y, ys) !length(ys) || y < min(ys), year, years))]
# newly banded here (not in the capture year's history; every later history year follows it) vs birds already marked
# when captured (in that year's history, resighted before the capture date: recaptures of birds banded earlier or elsewhere)
stopifnot(sum(mk$in_year) == 6L, all(mk$before | mk$in_year))
rc <- mk[in_year == TRUE]
stopifnot(all(sapply(seq_len(nrow(rc)), function(i) { cd <- rc$d[i]
  any(ch[anon == rc$anon[i] & year(d) == year(cd) & y == 1L, d] < cd) })))
mk[, new_band := !in_year]
cat(sprintf("  masses: %d linked captures, %d banded here, %d of them never in a history\n", nrow(mk), sum(mk$new_band),
            sum(mk$new_band & lengths(mk$years) == 0L)))

birds <- seen_years$anon
first_p <- setNames(rep(1L, length(birds)), birds)
hy <- mk[age == "HY" & anon %in% birds]; first_p[hy$anon] <- hy$year - 2015L
excl <- mk[new_band == TRUE & anon %in% birds, .(anon, period = year - 2015L)]
stopifnot(all(first_p[hy$anon] <= sapply(hy$years, min) - 2015L))
grid <- rbindlist(lapply(birds, function(a) sv[period >= first_p[[a]], .(unit = a, period, occasion, d)]))
grid <- grid[!excl, on = c(unit = "anon", "period")]
long <- merge(grid, ch, by.x = c("unit", "d"), by.y = c("anon", "d"), all.x = TRUE)
stopifnot(sum(long$y, na.rm = TRUE) == 2571L, nrow(merge(ch[y == 1L], grid, by.x = c("anon", "d"), by.y = c("unit", "d"))) == 2571L)
long[is.na(y), y := 0L]
long[, `:=`(taxon = "CHAMEL", date = as.character(d))][, d := NULL]
uc <- mk[anon %in% birds, .(unit = anon, unit_capture_year = year, unit_capture_age = age, unit_capture_mass_g = mass,
                            unit_capture_tarsus_mm = tarsus)]
long <- merge(long, uc, by = "unit", all.x = TRUE)
long <- order_eco(long)
cat(sprintf("  cjs: %d rows, %d birds, %d banding-year exclusions, %d HY starts\n", nrow(long), uniqueN(long$unit), nrow(excl), nrow(hy)))

taxa <- make_taxa("CHAMEL", "Charadrius melodus", vernacularName = "Piping plover")
taxa[, taxonRemarks := "US federally threatened (Atlantic Coast population); identifiers anonymised by the source"]
periods <- sv[, .(year = year(d[1]), n_surveys = .N, first_survey = as.character(min(d)), last_survey = as.character(max(d))), by = period]
periods[, hurricane_dorian := as.integer(year >= 2019L)]
setcolorder(periods, "period")

base <- list(
  creator = "Sweeney, Chelsea E.; Wails, Christy N.; Alvino, Camille R.; Oliver, Katie W.; Maddock, Sidney B.; Catlin, Daniel H.; Fraser, James D.; Karpanty, Sarah M.",
  pubDate = "2026-09-17", doi = "10.5061/dryad.0zpc867d2", sourceURL = "https://doi.org/10.5061/dryad.0zpc867d2",
  citation = "Sweeney, C. E., Wails, C. N., Alvino, C. R., Oliver, K. W., Maddock, S. B., Catlin, D. H., Fraser, J. D., & Karpanty, S. M. (2026). Data from: Storm-driven habitat loss reduced migrating piping plover abundance and stopover time, not body condition, at a key site [Dataset]. Dryad. https://doi.org/10.5061/dryad.0zpc867d2",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Fall-migration surveys of piping plovers on South Point, Ocracoke Island, North Carolina, July-October 2016-2023, spanning Hurricane Dorian (September 2019): counts of all and of marked plovers on 20-37 surveys a year, resighting histories of individually marked birds, and mass, tarsus and age of birds trapped there. The authors fitted an integrated Jolly-Seber and binomial-count superpopulation model of passage abundance and stopover duration.",
  samplingProtocol = "Repeated surveys of the South Point stopover site in July-October; observers counted all plovers once and recorded the band or flag combination of marked birds; plovers were also trapped, banded and measured.",
  surveyEvidence = "sample_table", taxonInclusion = "single", temporalCoverage = "2016-07/2023-10",
  geographicCoverage = "South Point, Ocracoke Island, Outer Banks, North Carolina, USA (about 35.07 N, 76.0 W); no coordinates deposited",
  occasionKind = "time")

ds_cjs <- c(list(title = "Resighting histories of 399 marked piping plovers on fall-migration surveys at South Point, Ocracoke Island, North Carolina, 2016-2023"),
  base, list(samplingProtocolCode = "tag_resight", responseType = "detection", unitKind = "individual",
  closure = "open", closureNote = "stopover: birds arrive and depart within each July-October season (Jolly-Seber within a year); open between years",
  covariateNote = "unit_capture_year, unit_capture_age (HY hatch-year, AHY after-hatch-year), unit_capture_mass_g, unit_capture_tarsus_mm: from the bird's capture on South Point (NA for birds banded elsewhere).",
  notShipped = list(flag_codes = "band and flag codes of the masses file (the source anonymised identifiers for this threatened species)",
                    banding_year = "the banding year of birds banded on South Point: the authors removed those resightings from the histories (README), so those years have no rows for those birds",
                    unlinked_captures = "39 captured birds with no history (anon NA) and birds banded here and never in a later history: no detections in the table, not units (E4.4)",
                    model_output = "superpopulation, stopover and body-condition estimates"),
  notes = "Hatch-year birds trapped here have rows from their hatch year; other birds from 2016. Rows in a bird's South Point banding year are absent (resightings excluded by the authors). Integrated with the count table sweeney_2026_ocracoke_plover_count."))
ds <- write_table(long, TABLE, ds_cjs, taxa = taxa, periods = periods, script = "data/sweeney_2026_ocracoke_plover_cjs.R")

cl <- sv[, .(unit = "SOUTHPOINT", taxon = "CHAMEL", y = total, period, occasion, date = as.character(d), obs_marked = marked)]
cl <- order_eco(cl)
ds_cnt <- c(list(title = "Survey counts of all and of marked piping plovers on 207 fall-migration surveys at South Point, Ocracoke Island, North Carolina, 2016-2023"),
  base, list(samplingProtocolCode = "visual_census", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "stopover: birds arrive and depart within each July-October season; the count tracks passage, not a closed population",
  covariateNote = "obs_marked: plovers with bands or flags seen on the survey, including unidentified marks; a marked bird may be counted more than once, and birds with non-unique marks are counted as unmarked.",
  notShipped = list(yday = "day of year (equal to the date)", model_output = "superpopulation and stopover estimates"),
  notes = "One site surveyed 20-37 times a season. The marked birds' individual histories are in sweeney_2026_ocracoke_plover_cjs."))
ds2 <- write_table(cl, COUNT, ds_cnt, taxa = taxa, periods = periods, script = "data/sweeney_2026_ocracoke_plover_cjs.R")

ref <- "Sweeney, C. E., Wails, C. N., Alvino, C. R., Oliver, K. W., Maddock, S. B., Catlin, D. H., Fraser, J. D., & Karpanty, S. M. Storm-driven habitat loss reduced migrating piping plover abundance and stopover time, not body condition, at a key site. Ecosphere."
stage_dict_row(TABLE,
  description = "Resighting histories of 399 individually marked piping plovers across 207 fall-migration surveys on South Point, Ocracoke Island, North Carolina, 2016-2023, before and after Hurricane Dorian.",
  url = "https://doi.org/10.5061/dryad.0zpc867d2", reference = ref, doi_paper = "", doi_data = "10.5061/dryad.0zpc867d2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Banding-year resightings excluded by the authors (no rows); HY birds from hatch year; identifiers anonymised by the source; paper not read.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Jolly-Seber (stopover)", sampling_protocol = "tag_resight",
  design = "Multi-season (8 fall stopover seasons x 20-37 surveys; one site)", realm = "Marine", country = "USA",
  coordinates = "None in source", notes = "Threatened shorebird stopover; integrated with a count table.")
stage_dict_row(COUNT,
  description = "Counts of all and of marked piping plovers on 207 fall-migration surveys of South Point, Ocracoke Island, North Carolina, 2016-2023, before and after Hurricane Dorian.",
  url = "https://doi.org/10.5061/dryad.0zpc867d2", reference = ref, doi_paper = "", doi_data = "10.5061/dryad.0zpc867d2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "One site; marked count as obs_marked; paper not read.", source_via = "Dryad")
stage_tag_row(COUNT, ds2, taxon_group = "Birds", model_family = "Repeated counts (open population)", sampling_protocol = "visual_census",
  design = "Multi-season (8 fall stopover seasons x 20-37 surveys; one site)", realm = "Marine", country = "USA",
  coordinates = "None in source", notes = "Single-site count series; integrated with the resighting table.")
