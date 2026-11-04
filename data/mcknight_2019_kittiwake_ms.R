#!/usr/bin/env Rscript
# Tables: mcknight_2019_kittiwake_fledgling_ms, mcknight_2019_kittiwake_recruit_ms
#         (one deposit, two analysis data sets with different birds, release ages and state
#         definitions; one script builds both)
# Source: Dryad doi:10.5061/dryad.ch2740k, version 33126 (version 1, published 2020-09-11),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         McKnight, A., Blomberg, E. J., Irons, D. B., Loftin, C. S. & McKinney, S. T. "Data from:
#         Survival and recruitment dynamics of black-legged kittiwakes Rissa tridactyla at an
#         Alaskan colony".
# Paper:  McKnight, A., Blomberg, E. J., Irons, D. B., Loftin, C. S. & McKinney, S. T. (2019).
#         Survival and recruitment dynamics of Black-legged Kittiwakes Rissa tridactyla at an
#         Alaskan colony. Marine Ornithology 47, 209-222, doi:10.5038/2074-1235.47.2.1319 (open
#         access; read).
# Data:   one workbook, McKnightEtAl2019_MarineOrnithology_KittiwakeSurvivalRecruitment_
#         FledglingAndRecruitSurvivalData.xlsx, three sheets, no header rows, no ids, no cohort
#         column:
#   ReadMe               state definitions for the two data sheets (read).
#   FledglingSurvival    5,090 lines, one 19-character history each over the resighting years
#                        1992-2010 (paper: "From 1992 to 2010 ... resighting"; n = 5,090 chicks
#                        banded in 1991 and 1995-2006). P = pre-recruit (not yet defended a nest
#                        site in the current or a previous year), B = recruit (defended a nest site
#                        in the current or a previous year), 0 = not resighted. The first non-zero
#                        character is always P, at column cohort + 1: the paper "simulated the
#                        release of all birds as age-1 pre-recruits" (banding was at age 0, the
#                        year before; 8 of 5,090 birds were truly seen at age 1).
#   PostRecruitSurvival  977 lines, 18-character histories over 1993-2010, eventual recruits only
#                        (paper: 1991 and 1995-2004 cohorts, n = 997; the deposit has 977 lines and
#                        two birds released in 2007, i.e. a 2005 cohort; kept as deposited).
#                        P = pre-recruit, B = breeder (seen three or more times on one nest site
#                        this year), U = recruited non-breeder (a former breeder not holding a site
#                        this year); first non-zero character always P at column cohort + 2 (birds
#                        "released ... as two-year-olds"). The two sheets are separate analysis
#                        sets: the recruit sheet's detection patterns do not line up with the
#                        fledgling sheet's recruits (checked: 293 of 977 match), so neither is a
#                        recode of the other and both ship.
#
# Mapping (standard E9 multistate CJS, responseType state, unitKind individual):
#   unit = line number within sheet (KF0001.., KR0001..), taxon = RISTRI, period = resighting
#   year (fledgling 1..19 = 1992..2010; recruit 1..18 = 1993..2010, in __periods), no occasion
#   (one May resighting season per year, about 10 passes per breeding patch summarised by the
#   authors into one state). y: fledgling 0 / 1 P / 2 B; recruit 0 / 1 P / 2 B / 3 U; y_raw =
#   the deposited letter. obs_release = 1 on the first non-zero cell: the authors' simulated
#   release (age 1 or age 2), not an observed resighting; unit_cohort = hatch (banding) year
#   derived from the release column (release year minus release age).
#   At-risk span (E4.4): the birds were banded as chicks, so each history starts in its real
#   banding year (unit_cohort), not at the authors' simulated release: no rows before it. The
#   banding-year row is the marking capture, y = 1 (pre-recruit), obs_banding = 1, y_raw empty
#   (the deposit has 0 there because the authors' histories begin at release; asserted). Years
#   between banding and release (the age-1 year in the recruit sheet) are y = 0 as deposited.
#   The 1991 cohort was banded before the first resighting season (fledgling 1992, recruit 1993),
#   so its rows start at the table's first period. To reproduce the authors' data, drop the
#   rows before obs_release = 1. Bands are colour bands; the deposit records no band loss.
#   Survey evidence: deposited_matrix (the colony was resighted every year 1992-2010).
#   No coordinates per bird; Shoup Bay colony at 61.17 N, 146.58 W (paper), in metadata only.
#   Rissa tridactyla is IUCN VU (global, 2017 assessment) and Alaska is in its native range,
#   but nothing is coordinate-level.
#   Not shipped: nothing in the deposit is left out. The paper's colony size, productivity and
#   climate covariates are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
CACHE <- "mcknight_2019_kittiwake_ms"
dir <- download_dryad("doi:10.5061/dryad.ch2740k", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "33126"))
xl <- file.path(dir, "McKnightEtAl2019_MarineOrnithology_KittiwakeSurvivalRecruitment_FledglingAndRecruitSurvivalData.xlsx")
stopifnot(identical(list.files(dir), basename(xl)),
          identical(excel_sheets(xl), c("ReadMe", "FledglingSurvival", "PostRecruitSurvival")))
rd <- function(sh) suppressMessages(read_excel(xl, sheet = sh, col_names = FALSE, col_types = "text"))[[1]]
fl <- rd("FledglingSurvival"); pr <- rd("PostRecruitSurvival")
stopifnot(length(fl) == 5090L, all(nchar(fl) == 19L), all(grepl("^[0PB]+$", fl)),
          length(pr) == 977L, all(nchar(pr) == 18L), all(grepl("^[0PBU]+$", pr)))

taxa <- make_taxa("RISTRI", "Rissa tridactyla", vernacularName = "Black-legged kittiwake",
                  taxon_iucnCategory = "VU")

build <- function(h, years, codes, release_age, prefix) {
  S <- do.call(rbind, strsplit(h, ""))
  first <- apply(S, 1, function(r) which(r != "0")[1])
  stopifnot(!anyNA(first), all(S[cbind(seq_along(h), first)] == "P"))
  Y <- matrix(match(S, names(codes)) - 1L, nrow(S)); stopifnot(!anyNA(Y))
  R <- matrix(0L, nrow(S), ncol(S)); R[cbind(seq_along(h), first)] <- 1L
  cohort <- years[first] - release_age
  band <- first - release_age                       # column of the real banding year (< 1: before the table)
  start <- pmax(band, 1L)
  Y[col(Y) < start] <- NA_integer_                  # E4.4: before banding the chick had not hatched
  YR <- S; YR[is.na(Y)] <- NA_character_
  B <- matrix(0L, nrow(S), ncol(S)); ib <- which(band >= 1L)
  stopifnot(all(S[cbind(ib, band[ib])] == "0"))     # the deposit starts at the simulated release
  B[cbind(ib, band[ib])] <- 1L
  Y[cbind(ib, band[ib])] <- 1L; YR[cbind(ib, band[ib])] <- NA_character_   # the marking capture: pre-recruit
  long <- array_to_eco(Y, taxon = "RISTRI", site_ids = sprintf("%s%04d", prefix, seq_along(h)),
                       site_covs = data.frame(cohort = cohort), period = seq_along(years),
                       obs_covs = list(banding = B, release = R), y_raw = YR)
  long[, occasion := NULL]
  stopifnot(nrow(long) == sum(!is.na(Y)), sum(long$obs_release) == length(h), sum(long$obs_banding) == length(ib),
            long[, .(mp = min(period)), by = unit][, all(mp == start[match(unit, sprintf("%s%04d", prefix, seq_along(h)))])])
  periods <- data.table(period = seq_along(years), year = years,
                        n_resighted = as.integer(colSums(!is.na(Y) & Y > 0 & R == 0 & B == 0)),
                        n_banded = as.integer(tabulate(band[ib], length(years))),
                        n_released = as.integer(tabulate(first, length(years))))
  list(long = long, periods = periods, cohort = cohort)
}

common <- list(
  creator = "McKnight, Aly; Blomberg, Erik J.; Irons, David B.; Loftin, Cynthia S.; McKinney, Shawn T.",
  pubDate = "2020", doi = "10.5061/dryad.ch2740k", sourceURL = "https://doi.org/10.5061/dryad.ch2740k",
  citation = "McKnight, A., Blomberg, E. J., Irons, D. B., Loftin, C. S., & McKinney, S. T. (2020). Data from: Survival and recruitment dynamics of black-legged kittiwakes Rissa tridactyla at an Alaskan colony [Dataset]. Dryad. https://doi.org/10.5061/dryad.ch2740k",
  paperDOI = "10.5038/2074-1235.47.2.1319",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Chicks colour-banded at 12-32 days old at the Shoup Bay colony; each May 1992-2010, four to eight observers read colour bands with binoculars and spotting scopes during morning and evening watches, about 10 times per breeding patch (10 patches) per season, recording the nest site each bird occupied; birds seen three or more times on one site were breeders. Encounters summarised into one state per bird per year.",
  samplingProtocolCode = "resighting", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "period (one state per May resighting season; survival and state transitions between years)", occasionKind = "none", taxonInclusion = "single",
  lossesOnCapture = "none",
  geographicCoverage = "Shoup Bay colony, Prince William Sound, Alaska, USA (61.17 N, 146.58 W, from the paper)",
  coordinatesCoarsened = NA,
  notShipped = list(none = "every deposited history is shipped; the paper's colony size, productivity and weather covariates are not in the deposit"))

# --- fledgling survival and recruitment (two states) -------------------------------------------
fy <- 1992:2010
f <- build(fl, fy, c(`0` = 0, P = 1, B = 2), release_age = 1L, prefix = "KF")
stopifnot(setequal(unique(f$cohort), c(1991L, 1995:2006)))
cat(sprintf("  fledgling: %d birds, cohorts %s; %d rows\n", length(fl), paste(sort(unique(f$cohort)), collapse = ","), nrow(f$long)))
TABLE <- "mcknight_2019_kittiwake_fledgling_ms"
dataset <- c(list(
  title = "Annual multistate resighting histories (pre-recruit / recruit) of 5,090 black-legged kittiwakes banded as chicks at Shoup Bay, Alaska, 1992-2010",
  abstract = "Kittiwakes colour-banded as chicks in 1991 and 1995-2006 at the Shoup Bay colony, Prince William Sound, and resighted at the colony each May through 2010; annual state pre-recruit or recruit. The paper fits multistate CJS models of apparent fledgling survival and age-dependent recruitment to the natal colony.",
  temporalCoverage = "1992/2010",
  stateCodes = list(`0` = "not resighted", `1` = "pre-recruit (y_raw P): present, not yet documented holding a nest site in this or a previous year; also the banding of the chick (obs_banding = 1, y_raw empty) and the simulated age-1 release (obs_release = 1)",
                    `2` = "recruit (y_raw B): documented holding a nest site this or a previous year"),
  notes = "Unit ids are line numbers (no band ids in the deposit). Rows begin in the real banding year (E4.4, marked as chicks): that row is the banding capture (y = 1, obs_banding = 1, y_raw empty; the deposit has 0 there), except for the 1991 cohort, banded before the first resighting year, whose rows begin in 1992. The row with obs_release = 1 is the authors' simulated release as an age-1 pre-recruit in the year after banding, not an observation; to reproduce their data drop the rows before it and condition on it. unit_cohort = banding year. Breeder-to-pre-recruit transitions are impossible by the state definition."), common)
ds <- write_table(f$long, TABLE, dataset, taxa = taxa, periods = f$periods, script = "data/mcknight_2019_kittiwake_ms.R")
stage_dict_row(TABLE,
  description = "Annual multistate resighting histories (pre-recruit / recruit) of 5,090 black-legged kittiwakes banded as chicks (1991, 1995-2006 cohorts) at the Shoup Bay colony, Prince William Sound, Alaska, resighted each May 1992-2010; rows from the banding year, with the authors' simulated age-1 release flagged (obs_release).",
  url = "https://doi.org/10.5061/dryad.ch2740k",
  reference = "McKnight, A., Blomberg, E. J., Irons, D. B., Loftin, C. S., & McKinney, S. T. (2019). Survival and recruitment dynamics of Black-legged Kittiwakes Rissa tridactyla at an Alaskan colony. Marine Ornithology, 47, 209-222.",
  doi_paper = "10.5038/2074-1235.47.2.1319", doi_data = "10.5061/dryad.ch2740k",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Sibling of mcknight_2019_kittiwake_recruit_ms (same deposit, different analysis set). Unit ids are line numbers.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS capture-recapture (fledgling survival and recruitment)",
  sampling_protocol = "resighting", design = "Multi-session (19 annual resighting seasons)",
  realm = "Marine", country = "USA", coordinates = "None in source",
  notes = "Seabird banded as chicks; rows from the banding year; the authors' simulated release is flagged (obs_release).")

# --- post-recruitment survival (three states, eventual recruits only) --------------------------
ry <- 1993:2010
r <- build(pr, ry, c(`0` = 0, P = 1, B = 2, U = 3), release_age = 2L, prefix = "KR")
stopifnot(setequal(unique(r$cohort), c(1991L, 1995:2005)), sum(r$cohort == 2005L) == 2L)
cat(sprintf("  recruit: %d birds, cohorts %s; %d rows\n", length(pr), paste(sort(unique(r$cohort)), collapse = ","), nrow(r$long)))
TABLE <- "mcknight_2019_kittiwake_recruit_ms"
dataset <- c(list(
  title = "Annual multistate resighting histories (pre-recruit / breeder / non-breeder) of 977 kittiwakes that recruited to the Shoup Bay colony, Alaska, 1993-2010",
  abstract = "Kittiwakes banded as chicks at Shoup Bay (1991 and 1995-2004 cohorts per the paper) that eventually recruited to the colony, resighted each May through 2010 with annual state pre-recruit, breeder or recruited non-breeder; for multistate CJS models of apparent post-recruitment survival and breeding.",
  temporalCoverage = "1993/2010",
  stateCodes = list(`0` = "not resighted", `1` = "pre-recruit (y_raw P); also the banding of the chick (obs_banding = 1, y_raw empty) and the simulated age-2 release (obs_release = 1)",
                    `2` = "breeder (y_raw B): seen three or more times on one nest site this year",
                    `3` = "recruited non-breeder (y_raw U): a former breeder not holding a nest site this year"),
  notes = "Unit ids are line numbers. Rows begin in the real banding year (E4.4, marked as chicks): that row is the banding capture (y = 1, obs_banding = 1, y_raw empty; the deposit has 0 there), the age-1 year is y = 0 as deposited, and the 1991 cohort (banded before the first resighting year) starts in 1993. The row with obs_release = 1 is the authors' simulated release as a two-year-old pre-recruit, not an observation; to reproduce their data drop the rows before it and condition on it. The deposit has 977 birds (paper: 997) and two birds of a 2005 cohort (paper: cohorts to 2004); kept as deposited. Only eventual recruits are included, so pre-recruit survival is 1 by construction (the paper fixes it)."), common)
ds <- write_table(r$long, TABLE, dataset, taxa = taxa, periods = r$periods, script = "data/mcknight_2019_kittiwake_ms.R")
stage_dict_row(TABLE,
  description = "Annual multistate resighting histories (pre-recruit / breeder / recruited non-breeder) of 977 black-legged kittiwakes banded as chicks that recruited to the Shoup Bay colony, Prince William Sound, Alaska, resighted each May 1993-2010; rows from the banding year, with the authors' simulated age-2 release flagged (obs_release).",
  url = "https://doi.org/10.5061/dryad.ch2740k",
  reference = "McKnight, A., Blomberg, E. J., Irons, D. B., Loftin, C. S., & McKinney, S. T. (2019). Survival and recruitment dynamics of Black-legged Kittiwakes Rissa tridactyla at an Alaskan colony. Marine Ornithology, 47, 209-222.",
  doi_paper = "10.5038/2074-1235.47.2.1319", doi_data = "10.5061/dryad.ch2740k",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Sibling of mcknight_2019_kittiwake_fledgling_ms (same deposit, different analysis set: recruits only, three states). 977 birds vs the paper's 997.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS capture-recapture (post-recruitment survival and breeding state)",
  sampling_protocol = "resighting", design = "Multi-session (18 annual resighting seasons)",
  realm = "Marine", country = "USA", coordinates = "None in source",
  notes = "Recruits only; rows from the banding year; the authors' simulated release is flagged (obs_release).")
