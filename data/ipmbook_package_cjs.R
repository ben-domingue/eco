#!/usr/bin/env Rscript
# Tables: schaub_2007_vex_horseshoebat_cjs, schaub_2012_valais_hoopoe_cjs,
#         schaub_2021_albvorland_woodchat_cjs
# Source: the example datasets of the R package IPMbook (Schaub, Kéry, Meredith), version 0.1.5
#         (CRAN, published 2023-08-21), licence GPL (>= 3) as shown on the CRAN page and in the
#         package DESCRIPTION (asserted below); the data carry no licence of their own.
#         Schaub, M., Kéry, M. & Meredith, M. (2023). IPMbook: Functions and data for the book
#         'Integrated Population Models'. R package version 0.1.5.
#         https://CRAN.R-project.org/package=IPMbook
#         The package is not loaded: the pinned source tarball is downloaded and data/<name>.rda
#         loaded directly. Which years had recapture effort comes from the book's own code
#         (Schaub & Kéry 2022, Integrated Population Models, Academic Press; chapter scripts
#         in github.com/mikemeredith/IPM_code, IPM_11.all_tr.R and IPM_13.all_tr.R), restated
#         below as constants and checked against the histories.
# Data (help pages data_bats.Rd, data_hoopoe.Rd, data_woodchat11.Rd, read in full):
#   bats: greater horseshoe bats, nursery colony in the church of St-Sylvie at Vex (Valais,
#     Switzerland), 1989-2017. ch 574 x 29 (0/1), age at first capture (1 juvenile, 2 one
#     year old, 3 at least two), sex (1 female, 2 male); also annual counts of newborns and
#     of adults leaving the roost (J.count, Jm, Jf, A.count: aggregate counts, not shipped).
#     'In some years no capture was performed': the book's recapture index k (IPM_13) fixes
#     p = 0 for 1990-2003, 2009, 2010 and 2014 and flags 2015 as incomplete; the histories
#     agree (no recapture in those years, asserted). Newborns were still marked in most of
#     them (1991-2003, 2009, 2010, 2014), and four bats older than juveniles were first
#     marked in 1993. Schaub, Gimenez, Sierro & Arlettaz (2007), Conservation Biology 21,
#     945-955, doi:10.1111/j.1523-1739.2007.00743.x; Sierro, Lugon & Arlettaz (2009).
#   hoopoe: hoopoes in nestboxes in the Valais (Swiss Alps), 2002-2017. ch 3,844 female birds
#     x 16 years (0/1), age at first capture (1 nestling, 2 at least one year old); also an
#     annual pair count and reproduction (aggregates, not shipped). Nestlings ringed and
#     breeding adults captured every year (recaptures in every year, asserted). Schaub,
#     Reichlin, Abadi, Kéry, Jenni & Arlettaz (2012), Oecologia 168, 97-108,
#     doi:10.1007/s00442-011-2070-5; Arlettaz et al. (2010); Plard et al. (2020).
#   woodchat11: woodchat shrikes, Streuobstwiesen of the Mittleres Albvorland (Göppingen and
#     Esslingen districts, southern Germany), 1964-1992. ch 1,079 individuals x 29 years
#     (0/1), age at first capture (1 nestling, 2 adult); also pair counts and brood
#     productivity (not shipped). 'In some years no resighting data were collected': the
#     book's recap index (IPM_11) fixes p = 0 for 1973, 1978-1981 and 1984-1988; the
#     histories agree (no recapture in those years, asserted), and nestlings were still
#     ringed in them. Data of Bruno Ullrich. Schaub & Ullrich (2021), Animal Conservation 24,
#     doi:10.1111/acv.12639; Ullrich (2017).
# Mapping (standard E1-E5, CJS; responseType detection, unitKind individual; period = year,
#   no occasion):
#   unit = row number of ch, taxon code, period = year index (year in __periods), y = ch.
#   At-risk span (E4.4): a nestling or newborn (age 1) from its marking year; a bat marked
#   as a one-year-old (age 2) from the year it was born (marking year - 1, not before the
#   study); every other animal (adult, age unknown) from the first year of the study. To
#   the last year (no removals, no mark loss recorded).
#   Survey evidence = inferred: a year is a recapture survey unless the book's code fixes
#   its recapture probability at 0. Within the at-risk span an animal has a row in every
#   recapture year and in its own marking year (marking happened in some years without
#   recapture effort; the marking row is y = 1). Every capture falls on a row (asserted).
#   unit_age_first_capture (source code, labelled in notes), unit_sex where deposited;
#   __periods: year, recapture_survey (1/0), n_marked, n_recaptured.
#   No coordinates in the package; place names only.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/ipmbook_package_cjs.R"
VER <- "0.1.5"
TARBALL <- sprintf("IPMbook_%s.tar.gz", VER)
CRAN_PAGE <- "https://cran.r-project.org/package=IPMbook"
PKG_CITE <- sprintf("Schaub, M., Kéry, M., & Meredith, M. (2023). IPMbook: Functions and data for the book 'Integrated Population Models' (Version %s) [R package; dataset %%s]. CRAN. https://CRAN.R-project.org/package=IPMbook", VER)
BOOK <- "Schaub, M. & Kéry, M. (2022). Integrated Population Models: Theory and Ecological Applications with R and JAGS. Academic Press."
GPL <- list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html")

ipm_data <- function(table, name) {
  f <- file.path(RAW_DIR, table, TARBALL)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", TARBALL), table, TARBALL), silent = TRUE)
    if (inherits(ok, "try-error"))
      download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/IPMbook/%s", TARBALL), table, TARBALL)
  }
  ex <- file.path(RAW_DIR, table, "IPMbook")
  if (!dir.exists(ex)) untar(f, files = c("IPMbook/DESCRIPTION", "IPMbook/data"), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == VER, desc[, "License"] == "GPL (>= 3)")
  e <- new.env(); load(file.path(ex, "data", paste0(name, ".rda")), envir = e)
  get(name, envir = e)
}

# ch (individual x year, 0/1) -> long CJS rows under the rule in the header
cjs_long <- function(ch, start, survey) {
  stopifnot(is.matrix(ch), all(ch %in% 0:1), all(rowSums(ch) >= 1), length(survey) == ncol(ch),
            length(start) == nrow(ch))
  f <- apply(ch, 1, function(r) which(r == 1L)[1])
  stopifnot(all(start >= 1L & start <= f))
  long <- rbindlist(lapply(seq_len(nrow(ch)), function(i) {
    t <- seq.int(start[i], ncol(ch)); t <- t[survey[t] | t == f[i]]
    data.table(i = i, period = t, y = ch[i, t])
  }))
  # every capture is on a row: no capture outside the survey set
  stopifnot(sum(long$y) == sum(ch))
  long[, `:=`(unit = sprintf("%04d", i), first = f[i])]
  long
}
periods_of <- function(ch, years, survey) {
  f <- apply(ch, 1, function(r) which(r == 1L)[1])
  data.table(period = seq_along(years), year = years, recapture_survey = as.integer(survey),
             n_marked = tabulate(f, length(years)), n_recaptured = colSums(ch) - tabulate(f, length(years)))
}
common <- list(sourceURL = CRAN_PAGE, intellectualRights = GPL, responseType = "detection",
               unitKind = "individual", closure = "none", closureNote = "period", occasionKind = "none",
               taxonInclusion = "single", surveyEvidence = "inferred", coordinatesCoarsened = NA)
dict_common <- list(url = CRAN_PAGE, original_license = "GPL (>= 3) (IPMbook R package; the data have no licence of their own)",
                    derived_license = "GPL-3.0-or-later", source_via = sprintf("CRAN source tarball IPMbook %s (data/*.rda)", VER))

# =========================================================================================
# 1. Greater horseshoe bats, Vex (Valais), 1989-2017
# =========================================================================================
TABLE <- "schaub_2007_vex_horseshoebat_cjs"
bats <- ipm_data(TABLE, "bats")
ch <- bats$ch; years <- 1989:2017
stopifnot(identical(dim(ch), c(574L, 29L)), sum(ch) == 1116L, all(bats$age %in% 1:3), all(bats$sex %in% 1:2),
          identical(as.vector(table(bats$age)), c(548L, 15L, 11L)))
# the book's recapture index for occasions 2..29 (IPM_13.all_tr.R): 12 = no capture (p fixed 0), 11 = 2015, incomplete
k <- c(rep(12, 14), 1, 2, 3, 4, 5, 12, 12, 6, 7, 8, 12, 11, 9, 10)
survey <- c(FALSE, k != 12)                                  # 1989: first occasion, marking only
stopifnot(identical(years[survey], c(2004:2008, 2011:2013, 2015:2017)))
f <- apply(ch, 1, function(r) which(r == 1L)[1])
recap <- colSums(ch) - tabulate(f, 29)
stopifnot(all(recap[!survey] == 0L), all(recap[survey] > 0L))
start <- ifelse(bats$age == 1, f, ifelse(bats$age == 2, pmax(1L, f - 1L), 1L))
long <- cjs_long(ch, start, survey)
long[, `:=`(unit_age_first_capture = bats$age[i], unit_sex = c("F", "M")[bats$sex[i]])]
long <- order_eco(long[, .(unit, taxon = "RHIFER", y, period, unit_age_first_capture, unit_sex)])
periods <- periods_of(ch, years, survey)[, note := fifelse(year == 2015, "incomplete capture (book: p estimated separately)", "")]
taxa <- make_taxa("RHIFER", "Rhinolophus ferrumequinum", vernacularName = "Greater horseshoe bat", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Capture-recapture histories of 574 greater horseshoe bats at a nursery colony in Vex, Valais, Switzerland, 1989-2017",
  creator = "Arlettaz, Raphaël; Biollaz, François; Sierro, Antoine (data); Schaub, Michael; Gimenez, Olivier (distributed in the IPMbook R package)",
  pubDate = "2007", citation = sprintf(PKG_CITE, "bats"), paperDOI = "10.1111/j.1523-1739.2007.00743.x",
  abstract = "Greater horseshoe bats (Rhinolophus ferrumequinum) of a nursery colony in the church of St-Sylvie at Vex in the Valais, Switzerland, were marked from 1989 to 2017, mostly as newborns in the roost, and recaptured in the years with capture sessions (2004-2008, 2011-2013, 2015-2017). The data are the IPMbook package's bats capture histories (574 bats, 1989-2017; 1990 had neither marking nor capture), with age at first capture and sex; the package's annual roost and exit counts are aggregates and not shipped. Analysed in an integrated population model by Schaub et al. (2007) and in Schaub & Kéry (2022, chapter 13).",
  samplingProtocol = "Bats captured and marked in the nursery roost (newborns, and some adults), recaptured in years with capture sessions; one occasion per year.",
  samplingProtocolCode = "hand_capture",
  surveyEvidenceNote = "The package's help page says that in some years no capture was performed; the book's code (IPM_13.all_tr.R, recapture index k) fixes recapture probability at 0 in 1990-2003, 2009, 2010 and 2014, and the histories have no recapture in exactly those years (asserted). A year is a recapture survey otherwise (2004-2008, 2011-2013, 2015-2017; 2015 incomplete, flagged in __periods). In a year without recapture effort a bat has a row only if it was marked that year (newborns were marked in most such years). 1989, the first year, is marking only.",
  geographicCoverage = "Church of St-Sylvie, Vex, Valais, Switzerland (about 46.21 N, 7.40 E); no coordinates in the package",
  temporalCoverage = "1989/2017",
  designNote = "CJS with years as periods. At-risk span: newborns from the marking year, one-year-olds from the year before marking, older bats from 1989 (E4.4).",
  notes = "unit_age_first_capture as deposited: 1 juvenile (newborn), 2 one year old, 3 at least two years old. unit_sex: F, M. Unit ids are row numbers of the package's ch matrix. __periods gives per year whether recapture sessions took place, the number of bats first marked and the number recaptured. 2015 had incomplete capture (book). The colony is the subject of Sierro, Lugon & Arlettaz (2009, Le Rhinolophe 18).",
  notShipped = list(J.count_Jm_Jf_A.count = "annual counts of newborns and of adults leaving the roost: aggregates without unit-level data (E9)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Capture-recapture histories of 574 greater horseshoe bats (mostly marked as newborns) at the St-Sylvie church nursery colony, Vex, Valais, Switzerland, 1989-2017, with age at first capture and sex; recapture sessions in 10 of the years (IPMbook::bats).",
  reference = "Schaub, M., Gimenez, O., Sierro, A., & Arlettaz, R. (2007). Use of integrated modeling to enhance estimates of population dynamics obtained from limited data. Conservation Biology, 21, 945-955.",
  doi_paper = "10.1111/j.1523-1739.2007.00743.x", doi_data = "",
  notes = "IPMbook package data (GPL). Survey set from the book's code (years without capture have rows only for bats marked that year)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-season (annual occasions 1989-2017, recapture effort in 10 years)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "From the IPMbook R package. Survey years from the book's code. unit = individual; period = year.")

# =========================================================================================
# 2. Hoopoes, Valais, 2002-2017
# =========================================================================================
TABLE <- "schaub_2012_valais_hoopoe_cjs"
hoopoe <- ipm_data(TABLE, "hoopoe")
ch <- hoopoe$ch; years <- 2002:2017
stopifnot(identical(dim(ch), c(3844L, 16L)), sum(ch) == 4452L, identical(as.vector(table(hoopoe$age)), c(3374L, 470L)))
survey <- rep(TRUE, 16)
f <- apply(ch, 1, function(r) which(r == 1L)[1])
stopifnot(all((colSums(ch) - tabulate(f, 16))[-1] > 0L))
start <- ifelse(hoopoe$age == 1, f, 1L)
long <- cjs_long(ch, start, survey)
long[, unit_age_first_capture := hoopoe$age[i]]
long <- order_eco(long[, .(unit, taxon = "UPUEPO", y, period, unit_age_first_capture)])
periods <- periods_of(ch, years, survey)
taxa <- make_taxa("UPUEPO", "Upupa epops", vernacularName = "Eurasian hoopoe", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Capture-recapture histories of 3,844 female hoopoes from a nestbox population in the Valais, Switzerland, 2002-2017",
  creator = "Swiss Ornithological Institute; University of Bern, Division of Conservation Biology (data); Schaub, Michael; Arlettaz, Raphaël (distributed in the IPMbook R package)",
  pubDate = "2012", citation = sprintf(PKG_CITE, "hoopoe"), paperDOI = "10.1007/s00442-011-2070-5",
  abstract = "Hoopoes (Upupa epops) breeding in nestboxes in the Valais, Swiss Alps, 2002-2017: nestlings were ringed and breeding adults captured at the boxes every year. The data are the IPMbook package's hoopoe capture histories of 3,844 female birds (3,374 first marked as nestlings, 470 as adults); the package's pair counts and reproduction records are not shipped. Analysed by Schaub et al. (2012) and in Schaub & Kéry (2022, chapter 14).",
  samplingProtocol = "Nestboxes checked regularly through each breeding season; nestlings ringed and breeding females captured; one occasion per year.",
  samplingProtocolCode = "nest_box",
  surveyEvidenceNote = "No effort table is in the package; nestlings were ringed and breeders captured in every year 2002-2017 (help page), and every year after the first has recaptures (asserted). Every year is a survey; each female has a row in every year of its at-risk span.",
  geographicCoverage = "Upper Rhône valley, Valais, Switzerland (about 46.2 N, 7.3 E); no coordinates in the package",
  temporalCoverage = "2002/2017",
  designNote = "CJS with years as periods. At-risk span: nestlings from the marking year, adults from 2002 (E4.4).",
  notes = "Females only, as in the package; how nestlings were sexed is not stated in the help page. unit_age_first_capture as deposited: 1 nestling, 2 at least one year old. Unit ids are row numbers of the package's ch matrix.",
  notShipped = list(count_reproAgg_reproInd = "annual pair counts and reproduction: aggregates or non-detection data (fledgling counts per female)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Capture-recapture histories of 3,844 female hoopoes (3,374 ringed as nestlings) in a nestbox population in the Valais, Switzerland, 2002-2017, with age at first capture (IPMbook::hoopoe).",
  reference = "Schaub, M., Reichlin, T. S., Abadi, F., Kéry, M., Jenni, L., & Arlettaz, R. (2012). The demographic drivers of local population dynamics in two rare migratory birds. Oecologia, 168, 97-108.",
  doi_paper = "10.1007/s00442-011-2070-5", doi_data = "",
  notes = "IPMbook package data (GPL). Every year surveyed; nestlings at risk from ringing."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "nest_box", design = "Multi-season (16 annual occasions)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "From the IPMbook R package. unit = individual; period = year.")

# =========================================================================================
# 3. Woodchat shrikes, Mittleres Albvorland, 1964-1992
# =========================================================================================
TABLE <- "schaub_2021_albvorland_woodchat_cjs"
wc <- ipm_data(TABLE, "woodchat11")
ch <- wc$ch; years <- 1964:1992
stopifnot(identical(dim(ch), c(1079L, 29L)), sum(ch) == 1120L, identical(as.vector(table(wc$age)), c(967L, 112L)))
# the book's recapture index for occasions 2..29 (IPM_11.all_tr.R): 19 = no resighting (p fixed 0)
recap_idx <- c(1, 2, 3, 4, 5, 6, 7, 8, 19, 9, 10, 11, 12, 19, 19, 19, 19, 13, 14, 19, 19, 19, 19, 19, 15, 16, 17, 18)
survey <- c(FALSE, recap_idx != 19)                         # 1964: first occasion, marking only
stopifnot(identical(years[!survey][-1], c(1973L, 1978:1981, 1984:1988)))
f <- apply(ch, 1, function(r) which(r == 1L)[1])
recap <- colSums(ch) - tabulate(f, 29)
stopifnot(all(recap[!survey] == 0L))
start <- ifelse(wc$age == 1, f, 1L)
long <- cjs_long(ch, start, survey)
long[, unit_age_first_capture := wc$age[i]]
long <- order_eco(long[, .(unit, taxon = "LANSEN", y, period, unit_age_first_capture)])
periods <- periods_of(ch, years, survey)
taxa <- make_taxa("LANSEN", "Lanius senator", vernacularName = "Woodchat shrike", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Capture-resighting histories of 1,079 woodchat shrikes in orchard meadows of the Mittleres Albvorland, Germany, 1964-1992",
  creator = "Ullrich, Bruno (data); Schaub, Michael (distributed in the IPMbook R package)",
  pubDate = "2021", citation = sprintf(PKG_CITE, "woodchat11"), paperDOI = "10.1111/acv.12639",
  abstract = "Bruno Ullrich ringed and resighted woodchat shrikes (Lanius senator) in the orchard meadows (Streuobstwiesen) of the Mittleres Albvorland, districts of Göppingen and Esslingen, southern Germany, from the discovery of the population in 1964 to its extinction in the early 1990s. The data are the IPMbook package's woodchat11 histories (1,079 birds, 967 first marked as nestlings); pair counts and brood productivity are not shipped. Analysed by Schaub & Ullrich (2021) and in Schaub & Kéry (2022, section 11.4).",
  samplingProtocol = "Nestlings and adults captured and colour-ringed; territorial adults resighted in the breeding season in the years with resighting effort; one occasion per year.",
  samplingProtocolCode = "resighting",
  surveyEvidenceNote = "The package's help page says that in some years no resighting data were collected; the book's code (IPM_11.all_tr.R, recap index) fixes recapture probability at 0 in 1973, 1978-1981 and 1984-1988, and the histories have no resighting in those years (asserted). A year is a resighting survey otherwise. In a year without resighting effort a bird has a row only if it was marked that year (nestlings were ringed in most such years). 1964, the first year, is marking only.",
  geographicCoverage = "Orchard meadows of the Mittleres Albvorland, districts of Göppingen and Esslingen, Baden-Württemberg, Germany (about 48.65 N, 9.45 E); no coordinates in the package",
  temporalCoverage = "1964/1992",
  designNote = "CJS with years as periods. At-risk span: nestlings from the marking year, adults from 1964 (E4.4).",
  notes = "unit_age_first_capture as deposited: 1 nestling, 2 adult (at least one year old). Males and females, sex not given. Unit ids are row numbers of the package's ch matrix. Woodchat shrike is Least Concern globally; the population went extinct (Ullrich 2017; Schaub & Ullrich 2021).",
  notShipped = list(count_f_d_year = "annual pair counts and brood productivity: aggregates or non-detection data")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Capture-resighting histories of 1,079 woodchat shrikes (967 ringed as nestlings) in orchard meadows of the Mittleres Albvorland, southern Germany, 1964-1992, with age at first capture; no resighting in 10 of the years (IPMbook::woodchat11; data of B. Ullrich).",
  reference = "Schaub, M., & Ullrich, B. (2021). A drop in immigration results in the extinction of a local woodchat shrike population. Animal Conservation, 24.",
  doi_paper = "10.1111/acv.12639", doi_data = "",
  notes = "IPMbook package data (GPL). Survey set from the book's code (years without resighting have rows only for birds marked that year)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "resighting", design = "Multi-season (29 annual occasions, resighting in 19)", realm = "Terrestrial",
  country = "DEU", coordinates = "None in source", notes = "From the IPMbook R package. Survey years from the book's code. unit = individual; period = year.")
