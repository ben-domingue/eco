#!/usr/bin/env Rscript
# Tables: volzke_2021_macquarie_seal1950s_cjs, volzke_2021_macquarie_seal1990s_cjs
#         (one deposit, two mark-recapture studies with disjoint cohorts, disjoint seasons and
#         different resight regimes; one script, two tables, as lazenby_2021_tasmania_smallmammal_scr.R)
# Source: Dryad doi:10.5061/dryad.zpc866t7f, version 262273 (published 2023-10-30), licence CC0 1.0
#         (as shown on Dryad). Volzke, S. "Macquarie Island southern elephant seal
#         capture-mark-recapture data". Mirrors the Australian Antarctic Data Centre collections
#         AADC-00101 (1950-1965) and AADC-00102 (1985 onwards).
# Papers: Volzke, S., McMahon, C. R., Hindell, M. A., Burton, H. R. & Wotherspoon, S. J. (2021).
#         Climate influences on female survival in a declining population of southern elephant
#         seals (Mirounga leonina). Ecology and Evolution 11:11333-11344. doi:10.1002/ece3.7919
#         (open access, CC BY; PMC8366891).
#         Volzke, S., Cleeland, J. B., Hindell, M. A., Corney, S. P., Wotherspoon, S. J. & McMahon,
#         C. R. (2023). Extreme polygyny results in intersex differences in age-dependent survival
#         of a highly dimorphic marine mammal. Royal Society Open Science 10:221635.
#         doi:10.1098/rsos.221635.
# Data:   TAGS_ELLIE_SIGHTINGS.csv: 242,278 sighting records (one row per resighting of a marked
#         seal; the unnamed first column is a database row number; SIGHTING_ID is unique except one
#         id shared by two seals on 2014-01-14) with SEAL_ID, DATE_OBSERVED (DD/MM/YYYY, 1951-2020),
#         MASTER_SEX_CHECKED (F/M/U, constant within seal), MASTER_TAG_TYPE (B brand, T tags, BT
#         both, #N/A not recorded; constant within seal; #N/A for every 1950s seal although the
#         README says they were branded), SEX_ON_SIGHTING, SEAL_TAGS_ON_ANIMAL, MOULT_ID,
#         SEAL_STATUS_ID (breeding status codes), AGE_CLASS_ID (01 black pup .. 05 abandoned pup,
#         10 underyearling, 20 yearling, 30 subadult, 40 adult, 50 dead, 99 unknown), WEIGHT,
#         COMMENTS, data-entry columns. README.md documents the columns.
#         Two studies (README; Volzke et al. 2021 section 2): weaners branded 1951-1965 and
#         resighted by organised island searches (1952, 1959) and opportunistic sightings to 1979
#         (a handful to 1986); weaners tagged and/or branded 1984-2000 (mostly 1987-2000; branding 1993-1999) and
#         resighted by daily isthmus searches in the breeding season plus monthly whole-island
#         searches 1993-2001, then declining effort to 2010 and ad hoc sightings to 2020.
#
# Mapping (standard E9 CJS / robust design on individuals, responseType detection):
#   unit = SEAL_ID (one seal), taxon = MIRLEO, period = seal year (1 September of `year` to
#   31 August of `year`+1, the papers' annual cycle; __periods gives the year and the sighting
#   counts), occasion = 1 the breeding season (September-October, the papers' "seen breeding"
#   emission) or 2 the rest of the seal year (November-August, "seen other"), y = 1 if the seal
#   has at least one sighting record in that window, y_raw = number of distinct sighting days.
#   Units: seals whose first record is a pup age class (01-05), i.e. a known-cohort animal marked
#   as a weaner; the seal year of that first record is unit_cohort_year. Seals first recorded as
#   underyearling or older (7 in the 1950s study, 2,275 in the 1990s study; the 2021 paper also
#   drops seals first tagged as adults) are not units. unit_sex = MASTER_SEX_CHECKED,
#   unit_tag_type = MASTER_TAG_TYPE (NA where #N/A), unit_first_age_class = the first record's
#   AGE_CLASS_ID.
#   Studies: 1950s table = cohorts 1951-1965 and seal years 1951-1985 (the last 1950s-cohort
#   sighting); 1990s table = cohorts 1984-2005 (35 seals marked 1984-1986 before the main
#   1987-2000 marking, AADC-00102 "1985 onwards") and seal years 1984-2019.
#   Survey evidence (inferred): a period x occasion window is surveyed iff at least one marked
#   seal of that study was sighted in it. The deposit has no effort table; the papers describe
#   the regimes but not which seasons were searched. Sparse windows (one or two sightings, e.g.
#   seal years 1979-1986 and 2011-2019) are therefore in the survey set with almost no effort;
#   __periods carries n_sightings per occasion so they can be filtered. At-risk span (E4.4):
#   every unit was marked as a weaned pup, so it has no rows before its cohort (marking) seal
#   year; from then on it carries every surveyed window of its study to the study's last seal
#   year, 0 where not sighted. Tag loss is not recorded per seal (seals resighted later were
#   still identifiable, by brand or a remaining tag), so no history is cut short; every unit has
#   a sighting (its marking record).
#   Not shipped: per-sighting attributes (breeding status, age class, moult stage, weight, tags
#   on animal, sex on sighting, comments, data-entry fields); the 2,282 seals first recorded past
#   the pup stage; 163 same-day duplicate records (collapsed by distinct day).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/volzke_2021_macquarie_seal_cjs.R"
dir <- download_dryad("10.5061/dryad.zpc866t7f", "volzke_2021_macquarie_seal_cjs")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "TAGS_ELLIE_SIGHTINGS.csv"); stopifnot(file.exists(f))

d <- fread(f, colClasses = "character"); setnames(d, 1, "ROW")
stopifnot(nrow(d) == 242278, ncol(d) == 17,
          c("SEAL_ID", "DATE_OBSERVED", "MASTER_SEX_CHECKED", "MASTER_TAG_TYPE", "AGE_CLASS_ID") %in% names(d))
d[, date := as.IDate(DATE_OBSERVED, "%d/%m/%Y")]
stopifnot(!anyNA(d$date), min(year(d$date)) == 1951L, max(year(d$date)) == 2020L,
          uniqueN(d$SEAL_ID) == 28184L, sum(duplicated(d$SIGHTING_ID)) == 1L,   # one id shared by two seals on 2014-01-14
          sum(duplicated(d[, .(SEAL_ID, date)])) == 163L)
# master sex and tag type are constant within seal
stopifnot(all(d[, uniqueN(MASTER_SEX_CHECKED), by = SEAL_ID]$V1 == 1L),
          all(d[, uniqueN(MASTER_TAG_TYPE), by = SEAL_ID]$V1 == 1L),
          all(d$MASTER_SEX_CHECKED %in% c("F", "M", "U")), all(d$MASTER_TAG_TYPE %in% c("B", "BT", "T", "#N/A")))
d[, sy := year(date) - (month(date) < 9L)]                 # seal year starts 1 September
d[, occ := ifelse(month(date) %in% 9:10, 1L, 2L)]           # 1 breeding season, 2 rest of year

setorder(d, date, ROW)
seals <- d[, .(first_date = date[1], cohort = sy[1], first_age = AGE_CLASS_ID[1], last_sy = sy[.N],
               sex = MASTER_SEX_CHECKED[1], tag = MASTER_TAG_TYPE[1]), by = SEAL_ID]
seals[, pup := first_age %in% c("1", "2", "3", "4", "5")]
seals[, study := ifelse(cohort <= 1965L, "1950s", "1990s")]
stopifnot(seals[pup == TRUE & study == "1950s", .N] == 7531L, seals[pup == TRUE & study == "1990s", .N] == 18371L,
          seals[pup == FALSE, .N] == 2282L,
          seals[pup == TRUE & study == "1950s", range(cohort)] == c(1951L, 1965L),
          seals[pup == TRUE & study == "1990s", range(cohort)] == c(1984L, 2005L),
          seals[pup == TRUE & study == "1950s", max(last_sy)] == 1985L)
cat(sprintf("  %d sightings, %d seals; %d known-cohort (pup-first) seals: %d in the 1950s study, %d in the 1990s study; %d first seen past the pup stage, not units\n",
            nrow(d), nrow(seals), sum(seals$pup), seals[pup & study == "1950s", .N], seals[pup & study == "1990s", .N], sum(!seals$pup)))

taxa <- make_taxa("MIRLEO", "Mirounga leonina", vernacularName = "Southern elephant seal")
taxa[, taxon_iucnCategory := "LC"]

build <- function(st, sy_range, table, cohort_label, regime) {
  u <- seals[pup == TRUE & study == st]
  s <- d[SEAL_ID %in% u$SEAL_ID & sy %between% sy_range]
  stopifnot(nrow(s) > 0, all(u$cohort %between% sy_range))
  # survey set: windows with at least one sighting of a study seal (inferred, see header)
  eff <- s[, .(n_sightings = .N, n_seals = uniqueN(SEAL_ID)), by = .(sy, occ)][order(sy, occ)]
  windows <- eff[, .(sy, occ)]
  per <- data.table(sy = sort(unique(windows$sy))); per[, period := seq_len(.N)]
  windows <- merge(windows, per, by = "sy")[order(period, occ)]
  # detections per seal x window: distinct sighting days
  det <- s[, .(y_raw = uniqueN(date)), by = .(SEAL_ID, sy, occ)]
  grid <- CJ(SEAL_ID = u$SEAL_ID, w = seq_len(nrow(windows)))
  grid <- cbind(grid, windows[grid$w, .(sy, occ, period)])
  grid <- grid[sy >= u$cohort[match(SEAL_ID, u$SEAL_ID)]]       # E4.4: marked as pups, no rows before the cohort year
  long <- merge(grid, det, by = c("SEAL_ID", "sy", "occ"), all.x = TRUE)
  long[is.na(y_raw), y_raw := 0L]
  stopifnot(nrow(long) == sum(sapply(u$cohort, function(c) sum(windows$sy >= c))), sum(long$y_raw > 0) == nrow(det), sum(long$y_raw) == nrow(unique(s[, .(SEAL_ID, date)])))
  long <- merge(long, u[, .(SEAL_ID, cohort, sex, tag, first_age)], by = "SEAL_ID")
  long <- long[, .(unit = paste0("S", SEAL_ID), taxon = "MIRLEO", y = as.integer(y_raw > 0), y_raw = as.integer(y_raw),
                   period, occasion = occ,
                   unit_sex = sex, unit_cohort_year = cohort, unit_tag_type = ifelse(tag == "#N/A", NA_character_, tag),
                   unit_first_age_class = as.integer(first_age))]
  long <- order_eco(long)
  stopifnot(uniqueN(long$unit) == nrow(u), !anyDuplicated(long[, .(unit, period, occasion)]),
            all(long$period >= per[match(long$unit_cohort_year, per$sy), period]))
  periods <- merge(per, dcast(eff, sy ~ occ, value.var = c("n_sightings", "n_seals"), fill = 0L), by = "sy")
  setnames(periods, c("n_sightings_1", "n_sightings_2", "n_seals_1", "n_seals_2"),
           c("n_sightings_breeding", "n_sightings_other", "n_seals_breeding", "n_seals_other"))
  periods[, year := sy][, label := sprintf("%d/%02d", sy, (sy + 1L) %% 100)][, sy := NULL]
  periods[, surveyed_occasions := ifelse(n_sightings_breeding > 0 & n_sightings_other > 0, "1,2", ifelse(n_sightings_breeding > 0, "1", "2"))]
  setcolorder(periods, c("period", "year", "label"))
  cat(sprintf("  %s: %d seals (cohorts %d-%d), %d seal years, %d surveyed windows, %d rows, %d detections\n",
              table, nrow(u), min(u$cohort), max(u$cohort), nrow(per), nrow(windows), nrow(long), sum(long$y)))
  dataset <- list(
    title = sprintf("Southern elephant seal resighting histories, Macquarie Island, %s study (cohorts %s): seal years %d-%d, breeding season and rest-of-year occasions", st, cohort_label, min(per$sy), max(per$sy)),
    creator = "Volzke, Sophia (University of Tasmania); McMahon, Clive R.; Hindell, Mark A.; Burton, Harry R.; Wotherspoon, Simon J.", pubDate = "2023",
    doi = "10.5061/dryad.zpc866t7f", sourceURL = "https://doi.org/10.5061/dryad.zpc866t7f",
    citation = "Volzke, S. (2023). Macquarie Island southern elephant seal capture-mark-recapture data [Dataset]. Dryad. https://doi.org/10.5061/dryad.zpc866t7f",
    paperDOI = "10.1002/ece3.7919", relatedWorks = c("10.1098/rsos.221635", "https://data.aad.gov.au/metadata/records/AADC-00101", "https://data.aad.gov.au/metadata/records/AADC-00102"),
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Resighting histories of %d southern elephant seals marked as weaned pups on the Macquarie Island isthmus (cohorts %s) and resighted %s. Built from the deposited sighting records: one row per seal x seal year (September to August) x occasion (1 = breeding season, September-October; 2 = the rest of the seal year), y = 1 if the seal was recorded in that window, y_raw = number of distinct sighting days. The survey set is inferred from the sightings themselves (a window is surveyed if any marked seal of this study was sighted in it); per-window sighting counts are in __periods so sparse windows can be dropped. Each seal's rows begin in its cohort (marking) year.", nrow(u), cohort_label, regime),
    samplingProtocol = sprintf("Permanent marking of weaned pups (%s) and resighting of marked seals ashore: %s. Sightings record date, sex, age class, breeding status and moult stage.",
                               if (st == "1950s") "hot-iron branding, 1951-1965" else "hot-iron branding 1993-1999 and/or Roto flipper tags, 1984-2000", regime),
    samplingProtocolCode = "tag_resight", surveyEvidence = "inferred",
    surveyEvidenceNote = "No effort table is deposited and the papers do not list which seasons were searched. A period x occasion window is in the survey set iff at least one marked seal of this study has a sighting record in it; every unit then carries a row for that window. Windows with very few sightings (see __periods n_sightings_*) reflect ad hoc effort and may be dropped before fitting; the 2021 paper's analysis windows were 1957-1979 and 1993-2003.",
    responseType = "detection", unitKind = "individual",
    closure = "closed", closureNote = "occasion within period (two resight windows per seal year; the papers treat a breeding-season sighting as a breeding event and a rest-of-year sighting as alive, nonbreeding or unknown); open between seal years (CJS / multi-state)", occasionKind = "time", taxonInclusion = "single",
    occasionCodes = list(`1` = "breeding season, September-October of `year` (the papers' 'seen breeding' emission)", `2` = "rest of the seal year, November of `year` to August of `year`+1 (the papers' 'seen other' emission; moult, mid-year haul-out)"),
    geographicCoverage = "Macquarie Island, Southern Ocean (54.5 S, 158.9 E); all seals marked on the isthmus; no coordinates deposited",
    temporalCoverage = sprintf("%d-09/%d-08", min(per$sy), max(per$sy) + 1L),
    coordinatesCoarsened = NA,
    notes = sprintf("Units are seals whose first record is a pup age class (01-05); their first record's seal year is unit_cohort_year, and as seals marked at birth (E4.4) they have no rows before it. unit_tag_type is NA where the deposit has #N/A (%s). unit_sex U = never sexed. y_raw counts distinct sighting days (163 same-day duplicate records in the deposit collapsed). Per-sighting breeding status, age class, moult and weight are not shipped; a multi-state breeding history can be rebuilt from the deposit's SEAL_STATUS_ID.",
                    if (st == "1950s") "every 1950s seal, although the README says they were branded" else "908 of the 1987-1992 cohort seals"),
    notShipped = list(`seals first recorded past the pup stage` = sprintf("%d seals (both studies: 2,282) with no known cohort; the 2021 paper also excludes seals first tagged as adults", seals[pup == FALSE & study == st, .N]),
                      `other study` = "the other mark-recapture study in the same file is the sibling table",
                      `per-sighting attributes` = "SEAL_STATUS_ID, AGE_CLASS_ID, MOULT_ID, WEIGHT, SEX_ON_SIGHTING, SEAL_TAGS_ON_ANIMAL, COMMENTS and data-entry columns",
                      `sightings outside the study's seal years` = "none: the 1950s cohorts' last sighting is in seal year 1985 and the 1990s cohorts' first is 1984"))
  ds <- write_table(long, table, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(table,
    description = sprintf("Resighting histories of %d southern elephant seals (Mirounga leonina) marked as weaned pups at Macquarie Island (%s cohorts %s) over seal years %d-%d, two occasions per year (breeding season Sept-Oct; rest of year); y = seen, y_raw = sighting days. Survey set inferred from the sightings (per-window counts in __periods).",
                          nrow(u), st, cohort_label, min(per$sy), max(per$sy)),
    url = "https://doi.org/10.5061/dryad.zpc866t7f",
    reference = "Volzke, S., McMahon, C. R., Hindell, M. A., Burton, H. R., & Wotherspoon, S. J. (2021). Climate influences on female survival in a declining population of southern elephant seals (Mirounga leonina). Ecology and Evolution, 11, 11333-11344.",
    doi_paper = "10.1002/ece3.7919", doi_data = "10.5061/dryad.zpc866t7f",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = sprintf("%s mark-recapture study of the deposit (the other is %s). Survey set inferred (no effort table); sparse ad hoc seal years included and flagged in __periods. Known-cohort seals only.",
                    st, if (st == "1950s") "volzke_2021_macquarie_seal1990s_cjs" else "volzke_2021_macquarie_seal1950s_cjs"),
    source_via = "Dryad")
  stage_tag_row(table, ds, taxon_group = "Mammals", model_family = "CJS / multi-state capture-recapture (breeding and non-breeding resight windows)",
    sampling_protocol = "tag_resight", design = sprintf("Multi-session (%d seal years x 2 resight windows)", nrow(per)), realm = "Marine",
    country = "AUS", coordinates = "None in source", notes = "Individuals as unit; rows from the cohort (marking) year; survey set inferred from sightings.")
  invisible(ds)
}

build("1950s", c(1951L, 1985L), "volzke_2021_macquarie_seal1950s_cjs", "1951-1965",
      "by organised island searches (1952, 1959) and opportunistic sightings to 1979, with a handful of sightings to 1986")
build("1990s", c(1984L, 2019L), "volzke_2021_macquarie_seal1990s_cjs", "1984-2005",
      "by daily isthmus searches during the breeding season and monthly whole-island searches 1993-2001, declining effort to 2010 and ad hoc sightings to 2020")
