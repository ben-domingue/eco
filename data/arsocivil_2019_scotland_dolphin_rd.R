#!/usr/bin/env Rscript
# Table:  arsocivil_2019_scotland_dolphin_rd
# Source: Dryad doi:10.5061/dryad.8qm8r4m, version 13298 (published 2018-12-19), licence CC0 1.0
#         (as shown on Dryad). Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V.,
#         Graves, J. A., Janik, V. M., Thompson, P. M. & Hammond, P. S. "Data from: Variations in
#         age- and sex-specific survival rates help explain population trend in a discrete marine
#         mammal population".
# Paper:  Arso Civil, M. et al. (2019). Variations in age- and sex-specific survival rates help
#         explain population trend in a discrete marine mammal population. Ecology and Evolution
#         9(1):533-544. doi:10.1002/ece3.4772 (open access, CC BY; read via Europe PMC PMC6342117).
# Data:   five text files in the RMark / MARK .inp shape (history, space, frequency or group
#         columns, ";"), no individual ids, no header, CRLF line endings:
#           JuvAd_Robust design models.txt    205 histories x 131 secondary occasions, freq 1 each:
#               the photo-ID histories of every marked juvenile / adult bottlenose dolphin, east
#               coast of Scotland, 1989-2015 (the paper's "205 juvenile/adult marked dolphins").
#           time_intervals.txt                RMark time.intervals for the two RD files: 0 within a
#               primary period, 1 between; gives 27 primaries (field seasons 1989..2015) with 3, 4,
#               5, 5, 5, 4, then 5 secondaries (months May-September; months not named).
#           JuvAd_Multistate models.txt       205 x 27 annual states U / F / M / 0 (sex unknown,
#               female, male, not seen): the same 205 dolphins in the same row order, sightings
#               pooled by year, labelled U until sexed and the sex thereafter (asserted below).
#           Adult only_Robust design models.txt  148 x 130: the paper's restricted adults-only
#               dataset (first 6 years of sightings dropped for dolphins first seen as juveniles,
#               first 3 for subadults; and one secondary fewer in 2002, per time.intervals_restr).
#           calf_age CJS models.txt           56 calves x 26 years with two MARK group columns:
#               the sibling table arsocivil_2019_scotland_dolphincalf_cjs.
#         No coordinates (two study areas: Moray Firth SAC and St Andrews Bay / Tay estuary).
#
# Mapping (standard E9 robust design, responseType detection, unitKind individual):
#   unit = dolphin D001..D205 (row of the RD file; the deposit has no catalogue ids), taxon =
#   TURTRU, period = field season 1..27 (1989..2015, in __periods), occasion = secondary occasion
#   (month index) within the season, 1..3, 1..4 or 1..5 as time.intervals defines; y = 0/1 photo-ID
#   sighting. Survey evidence: the deposited matrix; every dolphin carries all 131 secondary
#   occasions, including those before its first sighting (kept as 0, E4; RMark conditions on
#   first capture). unit_sex = the dolphin's final state in the multistate file (F, M, U = never
#   sexed); unit_sexed_period = the first season in which the multistate file labels it F or M
#   (NA if never sexed). Those two columns plus the annual pooling reproduce the multistate file
#   exactly (asserted), so it is not shipped as its own table.
#   Not shipped: the multistate file (a recode, see above); the adults-only RD file (the
#   authors' restriction of the same histories by age class at first sighting, which the deposit
#   does not give per dolphin); the calf file goes to its own table.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "arsocivil_2019_scotland_dolphin_rd"
dir <- download_dryad("10.5061/dryad.8qm8r4m", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Adult only_Robust design models.txt", "calf_age CJS models.txt",
  "JuvAd_Multistate models.txt", "JuvAd_Robust design models.txt", "time_intervals.txt")))

read_inp <- function(f) {
  l <- trimws(gsub("\r", "", readLines(file.path(dir, f), warn = FALSE))); l <- l[nzchar(l)]
  stopifnot(all(grepl(";$", l)))
  p <- strsplit(sub(";$", "", l), " +"); list(ch = sapply(p, `[`, 1), rest = lapply(p, `[`, -1))
}
rd <- read_inp("JuvAd_Robust design models.txt"); ms <- read_inp("JuvAd_Multistate models.txt")
ad <- read_inp("Adult only_Robust design models.txt")
n <- 205L; n_sec <- 131L; years <- 1989L:2015L; n_yr <- length(years)
stopifnot(length(rd$ch) == n, all(nchar(rd$ch) == n_sec), all(grepl("^[01]+$", rd$ch)),
          all(sapply(rd$rest, identical, "1")), all(grepl("1", rd$ch)))
stopifnot(length(ms$ch) == n, all(nchar(ms$ch) == n_yr), all(grepl("^[0UFM]+$", ms$ch)), all(sapply(ms$rest, identical, "1")))
stopifnot(length(ad$ch) == 148L, all(nchar(ad$ch) == 130L))

ti <- readLines(file.path(dir, "time_intervals.txt"), warn = FALSE)
iv <- as.integer(strsplit(sub(".*c\\((.*)\\).*", "\\1", grep("^time.intervals=c", ti, value = TRUE)), ",")[[1]])
stopifnot(length(iv) == n_sec - 1L, all(iv %in% 0:1), sum(iv) == n_yr - 1L)
period_of <- cumsum(c(1L, iv))                                   # primary period of each secondary occasion
n_occ <- as.integer(table(period_of))
stopifnot(identical(n_occ, c(3L, 4L, 5L, 5L, 5L, 4L, rep(5L, 21))))
occ_of <- sequence(n_occ)

Y <- do.call(rbind, lapply(strsplit(rd$ch, ""), as.integer))
# the multistate file is the same dolphins, row for row: annual pooling of the RD rows reproduces its
# seen / not-seen pattern, and its labels are U until sexed, then a constant sex
pooled <- t(apply(Y, 1, function(r) as.integer(tapply(r, period_of, max))))
M <- do.call(rbind, strsplit(ms$ch, ""))
stopifnot(identical(pooled, matrix(as.integer(M != "0"), n)))
seen_lab <- lapply(seq_len(n), function(i) M[i, M[i, ] != "0"])
sex <- sapply(seen_lab, function(s) tail(s, 1))
sexed_period <- sapply(seq_len(n), function(i) { k <- which(M[i, ] %in% c("F", "M")); if (length(k)) k[1] else NA_integer_ })
rebuilt <- t(sapply(seq_len(n), function(i) {
  out <- ifelse(pooled[i, ] == 1, "U", "0")
  if (!is.na(sexed_period[i])) out[pooled[i, ] == 1 & seq_len(n_yr) >= sexed_period[i]] <- sex[i]
  out }))
stopifnot(identical(rebuilt, M))                                 # unit_sex + unit_sexed_period carry the multistate file
stopifnot(identical(as.integer(table(factor(sex, levels = c("F", "M", "U")))), c(65L, 42L, 98L)))
cat(sprintf("  %d dolphins x %d seasons (%d secondary occasions); %d sightings; sex F %d, M %d, unknown %d\n",
            n, n_yr, n_sec, sum(Y), sum(sex == "F"), sum(sex == "M"), sum(sex == "U")))

units <- sprintf("D%03d", seq_len(n))
long <- array_to_eco(Y, taxon = "TURTRU", site_ids = units, period = period_of,
                     site_covs = data.frame(sex = sex, sexed_period = sexed_period))
stopifnot(nrow(long) == n * n_sec, sum(long$y) == sum(Y), uniqueN(long$unit) == n,
          identical(long[, .N, by = .(unit, period)][unit == "D001", N], n_occ),
          max(long$occasion) == 5L)

taxa <- make_taxa("TURTRU", "Tursiops truncatus", vernacularName = "Common bottlenose dolphin",
                  taxon_iucnCategory = "LC")
periods <- data.table(period = seq_len(n_yr), year = years, n_occasions = n_occ,
                      n_detected = as.integer(colSums(pooled)),
                      note = "field season May-September; secondary occasions are months (not named in the deposit)")

dataset <- list(
  title = "Robust-design photo-identification histories of 205 marked juvenile and adult bottlenose dolphins, east coast of Scotland, 1989-2015",
  creator = "Arso Civil, Monica; Cheney, Barbara; Quick, Nicola J.; Islas-Villanueva, Valentina; Graves, Jeff A.; Janik, Vincent M.; Thompson, Paul M.; Hammond, Philip S.",
  pubDate = "2018", doi = "10.5061/dryad.8qm8r4m", sourceURL = "https://doi.org/10.5061/dryad.8qm8r4m",
  citation = "Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V., Graves, J. A., Janik, V. M., Thompson, P. M., & Hammond, P. S. (2018). Data from: Variations in age- and sex-specific survival rates help explain population trend in a discrete marine mammal population [Dataset]. Dryad. https://doi.org/10.5061/dryad.8qm8r4m",
  paperDOI = "10.1002/ece3.4772",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Photo-identification capture histories of the 205 marked juvenile and adult bottlenose dolphins identified off the east coast of Scotland (Moray Firth Special Area of Conservation and St Andrews Bay / Tay estuary) from 1989 to 2015, arranged for robust-design models: each annual field season (May-September) is a primary period and months within it are secondary occasions. The paper estimated juvenile/adult survival with temporary emigration and individual heterogeneity, sex-specific survival with multistate models, and calf survival with age-specific CJS models.",
  samplingProtocol = "Boat-based photo-identification surveys May-September each year following standardised protocols; individuals identified from long-lasting nicks on the trailing edge of the dorsal fin and matched against the east-coast catalogue. Sex from photographs of the genital area, biopsy genetics or mother-calf pairs. Effort in the Moray Firth SAC was consistent over the study; in St Andrews Bay / Tay it varied 1997-2007 and was consistent from 2009.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "occasion within period (robust design: months within a field season; temporary emigration between seasons, which the paper models as Markovian)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "East coast of Scotland, UK: Moray Firth SAC and St Andrews Bay / Tay estuary; no coordinates deposited",
  temporalCoverage = "1989/2015",
  coordinatesCoarsened = NA,
  notes = "Dolphin ids are row numbers (the deposit has no catalogue ids). Seasons 1989, 1990 and 1994 have 3, 4 and 4 secondary occasions, all others 5 (time_intervals.txt). Occasions before a dolphin's first sighting are kept as 0 (E4); RMark conditions on first capture. unit_sex is the final multistate label (F 65, M 42, U 98 never sexed; the paper reports 66 / 43 / 96); unit_sexed_period is the first season labelled F or M, so the deposited multistate histories are rebuilt exactly by pooling each season and labelling U before unit_sexed_period. Effort varied between study areas and years (see samplingProtocol), which is not in the deposit.",
  notShipped = list(`JuvAd_Multistate models.txt` = "annual U/F/M histories of the same 205 dolphins: a recode of this table plus unit_sex and unit_sexed_period (asserted identical)",
                    `Adult only_Robust design models.txt` = "the authors' adults-only restriction (148 dolphins, first 6 or 3 years of sightings dropped by age class at first sighting, which is not deposited per dolphin)",
                    `calf_age CJS models.txt` = "shipped as arsocivil_2019_scotland_dolphincalf_cjs"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/arsocivil_2019_scotland_dolphin_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design photo-ID capture histories of 205 marked juvenile/adult bottlenose dolphins off the east coast of Scotland, 27 field seasons (1989-2015) x 3-5 monthly secondary occasions; y = sighted; sex and the season it was determined as covariates (rebuilding the authors' multistate histories).",
  url = "https://doi.org/10.5061/dryad.8qm8r4m",
  reference = "Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V., Graves, J. A., Janik, V. M., Thompson, P. M., & Hammond, P. S. (2019). Variations in age- and sex-specific survival rates help explain population trend in a discrete marine mammal population. Ecology and Evolution, 9(1), 533-544.",
  doi_paper = "10.1002/ece3.4772", doi_data = "10.5061/dryad.8qm8r4m",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Built from the RMark input files in the Dryad version zip. The multistate file is a recode of this table (asserted); the adults-only file is a restriction; calves are the sibling table arsocivil_2019_scotland_dolphincalf_cjs.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture (survival, temporary emigration; multistate by sex via unit covariates)",
  sampling_protocol = "photo_id", design = "Robust design (27 field seasons x 3-5 monthly occasions)", realm = "Marine",
  country = "GBR", coordinates = "None in source", notes = "Individuals as unit; ids are row numbers; sibling calf CJS table from the same deposit.")
