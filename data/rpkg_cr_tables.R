#!/usr/bin/env Rscript
# Tables: stokes_1987_logan_bunting_cjs, coulson_1984_eider_cjs, rivest_2004_duchenier_vole_rd,
#         collier_2013_alice_dove_cjs, edwards_1967_cottontail_cc, collier_2012_brosnan_deer_dobs,
#         mackenzie_2006_mahoenui_weta_occ, harding_2010_aukelake_cutthroat_cjs,
#         schneider_1998_jewettlake_bluegill_cc
# Sources: example datasets of three CRAN packages, loaded from their pinned source tarballs
#   without loading the packages, Version and License asserted from DESCRIPTION; the data carry
#   no licence of their own (the package licence governs):
#     Rcapture 1.4-4 (Baillargeon & Rivest), GPL-2: bunting, duck, rbvole
#     RMark 3.1.0 (Laake), GPL (>= 2): wwdo.09, wwdo.10, edwards.eberhardt, deer, weta
#     FSA 0.10.1 (Ogle et al.), GPL (>= 2): CutthroatAL, BluegillJL
# Data (help pages read in full):
#   bunting: frequencies of 8-year capture histories (1973-1980) of lazuli buntings in Logan,
#     Utah (A. W. Stokes); 255 history patterns, 198 with frequency 0, 1,681 birds. The help page
#     says 'wintering'; lazuli buntings breed, not winter, in northern Utah, so the season is as
#     the source states it and unverified. Burnham et al. (1987), AFS Monograph 5; Cormack (1993).
#   duck: frequencies of 6-year capture histories of 896 eiders, years 19-24 of Coulson's 25-year
#     study (calendar years and colony not given in the package). Coulson (1984), Ibis 126,
#     525-543, doi:10.1111/j.1474-919X.1984.tb02078.x; Cormack (1989).
#   rbvole: robust-design histories (6 primary x 3 consecutive days: May, July, August 1999 and
#     2000) of 560 red-backed voles, Duchénier conservation area, south-eastern Quebec
#     (Etcheverry et al.); frequency format. Rivest & Daigle (2004), Biometrics 60, 100-107,
#     doi:10.1111/j.0006-341X.2004.00157.x.
#   wwdo.09, wwdo.10: white-winged doves banded in baited walk-in traps in Alice, Texas (27.25 N,
#     98.07 W), mid-February to mid-September 2009 (5,101 birds) and 2010 (3,502), histories over
#     biweekly windows from 27 February plus a leading column E0 that the authors set to 0 for all
#     birds to fix entry before trapping (asserted all 0; dropped); Age AHY (after hatch year) or
#     HY. Band numbers are not in the package, so birds are not linked across years. Collier et
#     al. (2013), J. Fish Wildl. Manage. 4, 33-40, doi:10.3996/052012-JFWM-043.
#   edwards.eberhardt: 76 cottontail rabbits, 18 live-trapping occasions (the MARK closed-
#     population example). Edwards & Eberhardt (1967), J. Wildl. Manage. 31, 87-96,
#     doi:10.2307/3798362. Place and dates are not in the package.
#   deer: 4,508 white-tailed deer seen on 79 paired road-transect surveys (Group) on Brosnan
#     Forest, South Carolina, in August 2005-2009, each recorded as seen by the thermal imager
#     (TI, primary observer) and/or the spotlight (SL, secondary observer in the same vehicle);
#     Cluster = the group of deer seen together; MgmtUnit = management unit (1-4). Collier,
#     Ditchkoff, Ruth & Raglin (2012), J. Wildl. Manage. 77, 165-171, doi:10.1002/jwmg.444.
#   weta: Mahoenui giant weta presence on up to 5 visits to 72 sites (. = not visited), browsing
#     indicator, observer per visit; the PRESENCE example of MacKenzie et al. (2006, pp. 116-122).
#   CutthroatAL: annual capture histories of 1,684 cutthroat trout in Auke Lake, Alaska, 1998-
#     2006 (individual ids), from Harding, Hoover & Marshall (2010), ADF&G Fishery Data Series
#     10-82, Appendix A.3.
#   BluegillJL: two-sample capture histories of 277 bluegill > 6 in, Jewett Lake, Michigan
#     (Schneider 1998, example 8.1; year not given).
# Mapping: capture histories -> detection, unitKind individual, unit = row id (frequency
#   histories expanded, ids anonymous), y = 1 if caught. Annual and seasonal CJS/JS tables:
#   period = year/window, no occasion; closed captures (cottontail, bluegill): occasion only;
#   robust design (voles): period = primary, occasion = day. At-risk span (E4.4): unknown age ->
#   from the first period of the study (or of the bird's year for the doves); hatch-year doves
#   from their marking window. Survey evidence inferred throughout (no effort in any package
#   object; every occasion taken as surveyed), except weta (deposited_matrix: '.' = not
#   visited) and deer (row_presence: rows are detected deer, as tumursukh_2016_tost_argali_dobs).
#   Deer: multinomial_cell double observer, one unit per detected deer, y = 1 in its cell
#   (10 TI only, 01 SL only, 11 both) and 0 in the others, y_raw the cell label.
#   No coordinates in any of these objects.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/rpkg_cr_tables.R"
PKG <- list(Rcapture = list(ver = "1.4-4", lic = "GPL-2", spdx = "GPL-2.0-only"),
            RMark = list(ver = "3.1.0", lic = "GPL (>= 2)", spdx = "GPL-2.0-or-later"),
            FSA = list(ver = "0.10.1", lic = "GPL (>= 2)", spdx = "GPL-2.0-or-later"))
pkg_obj <- function(table, pkg, file, name) {
  tb <- sprintf("%s_%s.tar.gz", pkg, PKG[[pkg]]$ver)
  f <- file.path(RAW_DIR, table, tb)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", tb), table, tb), silent = TRUE)
    if (inherits(ok, "try-error")) download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", pkg, tb), table, tb)
  }
  ex <- file.path(RAW_DIR, table, pkg)
  if (!dir.exists(ex)) untar(f, files = c(file.path(pkg, "DESCRIPTION"), file.path(pkg, "data")), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == PKG[[pkg]]$ver, desc[, "License"] == PKG[[pkg]]$lic)
  e <- new.env(); load(file.path(ex, "data", file), envir = e); get(name, envir = e)
}
lic <- function(pkg) list(spdx = PKG[[pkg]]$spdx, url = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html")
dictc <- function(pkg) list(url = sprintf("https://cran.r-project.org/package=%s", pkg),
  original_license = sprintf("%s (%s R package; the data have no licence of their own)", PKG[[pkg]]$lic, pkg),
  derived_license = PKG[[pkg]]$spdx, source_via = sprintf("CRAN source tarball %s %s", pkg, PKG[[pkg]]$ver))
pcite <- function(pkg, ds) switch(pkg,
  Rcapture = sprintf("Baillargeon, S., & Rivest, L.-P. (2022). Rcapture: Loglinear models for capture-recapture experiments (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=Rcapture", PKG$Rcapture$ver, ds),
  RMark = sprintf("Laake, J. L. (2026). RMark: R code for Mark analysis (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=RMark", PKG$RMark$ver, ds),
  FSA = sprintf("Ogle, D. H., Doll, J. C., Wheeler, A. P., & Dinno, A. (2026). FSA: Simple fisheries stock assessment methods (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=FSA", PKG$FSA$ver, ds))
# expand frequency rows of a 0/1 history matrix into individuals
expand_freq <- function(h, freq) { stopifnot(all(freq >= 0), all(h %in% 0:1)); h[rep(seq_len(nrow(h)), times = freq), , drop = FALSE] }
# annual-type CJS rows from a 0/1 matrix, every animal from period 1
cjs_rows <- function(m, prefix) {
  stopifnot(all(rowSums(m) >= 1))
  data.table(unit = rep(sprintf("%s%04d", prefix, seq_len(nrow(m))), times = ncol(m)),
             period = rep(seq_len(ncol(m)), each = nrow(m)), y = as.integer(m))
}

# =========================================================================================
# 1. Lazuli buntings, Logan, Utah, 1973-1980
# =========================================================================================
TABLE <- "stokes_1987_logan_bunting_cjs"
b <- pkg_obj(TABLE, "Rcapture", "bunting.rda", "bunting")
stopifnot(identical(dim(b), c(255L, 9L)), identical(colnames(b), c(paste0("p", 1:8), "freq")), sum(b[, "freq"]) == 1681,
          sum(b[, "freq"] == 0) == 198L, !anyDuplicated(b[, 1:8]))
m <- expand_freq(b[, 1:8], b[, "freq"])
long <- order_eco(cjs_rows(m, "B")[, .(unit, taxon = "PASAMO", y, period)])
stopifnot(nrow(long) == 1681L * 8L, sum(long$y) == sum(b[, 1:8] * b[, "freq"]))
periods <- data.table(period = 1:8, year = 1973:1980, n_caught = colSums(m), n_new = tabulate(apply(m, 1, function(r) which(r == 1)[1]), 8))
taxa <- make_taxa("PASAMO", "Passerina amoena", vernacularName = "Lazuli bunting", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Annual capture histories of 1,681 lazuli buntings, Logan, Utah, 1973-1980",
  creator = "Stokes, Allen W. (data); Burnham, K. P.; Anderson, D. R.; White, G. C.; Brownie, C.; Pollock, K. H. (analysis); Baillargeon, S.; Rivest, L.-P. (distributed in the Rcapture R package)",
  pubDate = "1987", sourceURL = "https://cran.r-project.org/package=Rcapture", citation = pcite("Rcapture", "bunting"),
  intellectualRights = lic("Rcapture"),
  abstract = "Lazuli buntings (Passerina amoena) captured and banded at Logan, Utah, over eight years 1973-1980 in a study by Allen W. Stokes, analysed by Burnham et al. (1987) and Cormack (1993). The Rcapture package gives the frequencies of the 255 possible capture histories (198 unobserved); expanded here to 1,681 birds, one row per bird x year, y = 1 if caught.",
  samplingProtocol = "Annual trapping and banding at one site in Logan, Utah; the season and effort are not described in the package (its help page says the birds were wintering).",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; every year 1973-1980 is taken as a survey, as the frequency table spans all eight. Birds of unknown age have rows from 1973.",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period = year (open population)",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Logan, Cache County, Utah, USA (about 41.74 N, 111.83 W); no coordinates in the package", temporalCoverage = "1973/1980",
  coordinatesCoarsened = NA,
  notes = "Frequency histories expanded to individuals: unit ids (B0001-B1681) are arbitrary and carry no identity beyond the history. The help page calls the buntings wintering in Logan; lazuli buntings breed in northern Utah, so the season is unverified. Ages, sexes and losses are not in the package.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Annual capture histories of 1,681 lazuli buntings at Logan, Utah, 1973-1980 (A. W. Stokes; Rcapture::bunting, expanded from history frequencies).",
  reference = "Burnham, K. P., Anderson, D. R., White, G. C., Brownie, C., & Pollock, K. H. (1987). Design and analysis methods for fish survival experiments based on release-recapture. American Fisheries Society Monograph 5. Bethesda, Maryland.",
  doi_paper = "", doi_data = "", notes = "Rcapture package data (GPL-2). Frequency histories expanded."), dictc("Rcapture")))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (8 annual occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the Rcapture R package.")

# =========================================================================================
# 2. Eiders, years 19-24 of Coulson's study
# =========================================================================================
TABLE <- "coulson_1984_eider_cjs"
du <- pkg_obj(TABLE, "Rcapture", "duck.rda", "duck")
stopifnot(identical(dim(du), c(63L, 7L)), identical(colnames(du), c(paste0("p", 1:6), "freq")), sum(du[, "freq"]) == 896,
          sum(du[, "freq"] == 0) == 5L, all(du[, "freq"] >= 0), !anyDuplicated(du[, 1:6]))
m <- expand_freq(du[, 1:6], du[, "freq"])
long <- order_eco(cjs_rows(m, "E")[, .(unit, taxon = "SOMMOL", y, period)])
periods <- data.table(period = 1:6, study_year = 19:24, n_caught = colSums(m))
taxa <- make_taxa("SOMMOL", "Somateria mollissima", vernacularName = "Common eider", taxon_iucnCategory = "NT")
dataset <- list(
  title = "Annual capture histories of 896 common eiders over six consecutive years of Coulson's 25-year study",
  creator = "Coulson, J. C. (data); Cormack, R. M. (analysis); Baillargeon, S.; Rivest, L.-P. (distributed in the Rcapture R package)",
  pubDate = "1984", sourceURL = "https://cran.r-project.org/package=Rcapture", citation = pcite("Rcapture", "duck"),
  paperDOI = "10.1111/j.1474-919X.1984.tb02078.x", intellectualRights = lic("Rcapture"),
  abstract = "Common eiders (Somateria mollissima) from J. C. Coulson's 25-year capture-recapture study of a breeding population, years 19 to 24, as extracted by Cormack (1989) and distributed in Rcapture (duck): 63 history patterns with frequencies (5 of them 0), expanded to 896 birds, one row per bird x year.",
  samplingProtocol = "Annual capture of breeding eiders (Coulson 1984); details are in the paper, not the package.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; each of the six years is taken as a survey. Birds have rows from the first of the six years (age unknown).",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period = year (open population)",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Coulson's eider study colony (not named in the package); no coordinates", temporalCoverage = "six consecutive years (years 19-24 of a 25-year study; calendar years not in the package)",
  coordinatesCoarsened = NA,
  notes = "The six periods are years 19-24 of the study; their calendar years and the colony are not in the package (see Coulson 1984). Frequency histories expanded: unit ids are arbitrary. Common eider is IUCN Near Threatened; no coordinates exist to coarsen.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Annual capture histories of 896 common eiders over six consecutive years (years 19-24) of J. C. Coulson's 25-year study (Rcapture::duck, expanded from history frequencies).",
  reference = "Coulson, J. C. (1984). The population dynamics of the Eider Duck Somateria mollissima and evidence of extensive non-breeding by adult ducks. Ibis, 126, 525-543.",
  doi_paper = "10.1111/j.1474-919X.1984.tb02078.x", doi_data = "", notes = "Rcapture package data (GPL-2). Calendar years and colony not in the package."), dictc("Rcapture")))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (6 annual occasions)", realm = "Marine",
  country = "GBR", coordinates = "None in source", notes = "From the Rcapture R package.")

# =========================================================================================
# 3. Red-backed voles, Duchénier, Quebec, 1999-2000 (robust design)
# =========================================================================================
TABLE <- "rivest_2004_duchenier_vole_rd"
rb <- pkg_obj(TABLE, "Rcapture", "rbvole.rda", "rbvole")
oc <- paste0("c", rep(1:6, each = 3), rep(1:3, 6))
stopifnot(identical(dim(rb), c(66L, 19L)), identical(colnames(rb), c(oc, "freq")), sum(rb[, "freq"]) == 560, all(rb[, "freq"] >= 1))
m <- expand_freq(rb[, oc], rb[, "freq"])
ids <- sprintf("V%03d", seq_len(nrow(m)))
long <- rbindlist(lapply(1:6, function(s) rbindlist(lapply(1:3, function(d)
  data.table(unit = ids, period = s, occasion = d, y = as.integer(m[, (s - 1) * 3 + d]))))))
long <- order_eco(long[, .(unit, taxon = "MYOGAP", y, period, occasion)])
stopifnot(nrow(long) == 560L * 18L)
periods <- data.table(period = 1:6, month = c("1999-05", "1999-07", "1999-08", "2000-05", "2000-07", "2000-08"))
taxa <- make_taxa("MYOGAP", "Myodes gapperi", vernacularName = "Southern red-backed vole", taxon_iucnCategory = "LC",
                  taxonRemarks = "the package names 'red-back voles'; the southern red-backed vole is the Myodes species of south-eastern Quebec")
dataset <- list(
  title = "Robust-design capture histories of 560 red-backed voles, Duchénier conservation area, Quebec: three days in May, July and August of 1999 and 2000",
  creator = "Etcheverry, P. and colleagues (data); Rivest, Louis-Paul; Daigle, Gaétan (analysis); Baillargeon, S.; Rivest, L.-P. (distributed in the Rcapture R package)",
  pubDate = "2004", sourceURL = "https://cran.r-project.org/package=Rcapture", citation = pcite("Rcapture", "rbvole"),
  paperDOI = "10.1111/j.0006-341X.2004.00157.x", intellectualRights = lic("Rcapture"),
  abstract = "Red-backed voles live-trapped on three consecutive days in May, July and August of 1999 and 2000 in the Duchénier conservation area, south-eastern Quebec (Etcheverry et al.), analysed with loglinear robust-design models by Rivest & Daigle (2004). Rcapture's rbvole gives 66 history patterns with frequencies, expanded to 560 voles: one row per vole x primary period x day.",
  samplingProtocol = "Live trapping on three consecutive days in each of six primary periods (May, July, August 1999 and 2000).",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; every day of every primary period is taken as a survey. Voles of unknown age have rows from May 1999.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (robust design: closed within the three days, open between)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Réserve Duchénier, Bas-Saint-Laurent, south-eastern Quebec, Canada; no coordinates in the package", temporalCoverage = "1999-05/2000-08",
  coordinatesCoarsened = NA,
  notes = "Frequency histories expanded: unit ids arbitrary. The package says 'red-back voles' without a scientific name; Myodes gapperi is assumed (the red-backed vole of the area). Losses on capture are not coded.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Robust-design capture histories of 560 red-backed voles (three days in each of May, July and August 1999 and 2000), Duchénier conservation area, Quebec (Rcapture::rbvole; Rivest & Daigle 2004).",
  reference = "Rivest, L.-P., & Daigle, G. (2004). Loglinear models for the robust design in mark-recapture experiments. Biometrics, 60, 100-107.",
  doi_paper = "10.1111/j.0006-341X.2004.00157.x", doi_data = "", notes = "Rcapture package data (GPL-2). Robust design; frequency histories expanded."), dictc("Rcapture")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture",
  sampling_protocol = "live_trap", design = "Robust design (6 primary periods x 3 days)", realm = "Terrestrial",
  country = "CAN", coordinates = "None in source", notes = "From the Rcapture R package.")

# =========================================================================================
# 4. White-winged doves, Alice, Texas, 2009 and 2010
# =========================================================================================
TABLE <- "collier_2013_alice_dove_cjs"
w9 <- pkg_obj(TABLE, "RMark", "wwdo.09.rda", "wwdo.09"); w10 <- pkg_obj(TABLE, "RMark", "wwdo.10.rda", "wwdo.10")
to_m <- function(w) { m <- do.call(rbind, strsplit(as.character(w$ch), "")); storage.mode(m) <- "integer"; m }
m9 <- to_m(w9); m10 <- to_m(w10)
stopifnot(nrow(m9) == 5101L, nrow(m10) == 3502L, ncol(m9) == 14L, ncol(m10) == 14L, all(m9[, 1] == 0L), all(m10[, 1] == 0L),
          all(c(m9, m10) %in% 0:1), all(rowSums(m9) >= 1), all(rowSums(m10) >= 1),
          identical(as.vector(table(w9$Age)), c(2894L, 2207L)), identical(as.vector(table(w10$Age)), c(3016L, 486L)))
yr_rows <- function(m, age, yr, per) {
  m <- m[, -1]; f <- apply(m, 1, function(r) which(r == 1)[1])
  rbindlist(lapply(seq_len(nrow(m)), function(i) {
    t <- if (age[i] == "HY") f[i]:13 else 1:13
    data.table(unit = sprintf("%d_%04d", yr, i), period = (per - 1L) * 13L + t, y = as.integer(m[i, t]), unit_age_first = as.character(age[i]))
  }))
}
long <- rbind(yr_rows(m9, w9$Age, 2009L, 1L), yr_rows(m10, w10$Age, 2010L, 2L))
stopifnot(sum(long$y) == sum(m9) + sum(m10))
WIN <- c("02-27", "03-13", "03-27", "04-10", "04-24", "05-08", "05-22", "06-05", "06-19", "07-03", "07-17", "07-31", "08-14")
long <- order_eco(long[, .(unit, taxon = "ZENASI", y, period, unit_age_first)])
periods <- data.table(period = 1:26, year = rep(2009:2010, each = 13), window = rep(1:13, 2), window_start = paste(rep(2009:2010, each = 13), rep(WIN, 2), sep = "-"),
                      n_caught = c(colSums(m9[, -1]), colSums(m10[, -1])))
taxa <- make_taxa("ZENASI", "Zenaida asiatica", vernacularName = "White-winged dove", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Biweekly capture histories of 8,603 white-winged doves banded in an urban breeding colony, Alice, Texas, 2009 and 2010",
  creator = "Collier, Bret A.; Kremer, S. R.; Mason, C. D.; Stone, J.; Calhoun, K. W.; Peterson, M. J. (data; distributed in the RMark R package)",
  pubDate = "2013", sourceURL = "https://cran.r-project.org/package=RMark", citation = pcite("RMark", "wwdo.09 and wwdo.10"),
  paperDOI = "10.3996/052012-JFWM-043", intellectualRights = lic("RMark"),
  abstract = "White-winged doves (Zenaida asiatica) captured continuously in baited walk-in traps and leg-banded in an urban breeding colony at Alice, Texas, from mid-February to mid-September 2009 (5,101 doves) and 2010 (3,502), aged as hatch-year or after-hatch-year. Captures are grouped into 13 roughly two-week windows starting 27 February (the last open-ended from 14 August). One row per dove x window of its year, y = 1 if captured; the authors' Jolly-Seber (POPAN) analysis estimated immigration and recruitment.",
  samplingProtocol = "Baited walk-in traps operated continuously February-September; doves leg-banded and aged; captures pooled into two-week windows.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; trapping was continuous (help page), so every two-week window of each year is a survey. The authors' leading all-zero column (E0, used to fix entry before trapping) is dropped (asserted all 0).",
  responseType = "detection", unitKind = "individual", closure = "none",
  closureNote = "period = two-week window (13 per year, 2009 = 1-13, 2010 = 14-26; __periods has year and window start); open (Jolly-Seber). Band numbers are not in the package, so a dove's id is valid within its year only and it has rows in that year's windows only (E4.4)",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Alice, Jim Wells County, Texas, USA (27.25 N, 98.07 W, as given on the help page); trap locations not in the package",
  temporalCoverage = "2009-02-27/2010-09-15", coordinatesCoarsened = NA,
  notes = "At-risk span: after-hatch-year doves from the first window of their year; hatch-year doves (hatched that season) from their marking window. The help page gives 3,106 AHY doves in 2010; the data have 3,016 (asserted). Window start dates in __periods. Unit ids are year_row.",
  notShipped = list(E0 = "the authors' dummy all-zero first column"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Two-week capture histories of white-winged doves banded at an urban breeding colony in Alice, Texas, February-September 2009 (5,101) and 2010 (3,502), with age class (RMark::wwdo.09, wwdo.10; Collier et al. 2013).",
  reference = "Collier, B. A., Kremer, S. R., Mason, C. D., Stone, J., Calhoun, K. W., & Peterson, M. J. (2013). Immigration and recruitment in an urban white-winged dove breeding colony. Journal of Fish and Wildlife Management, 4, 33-40.",
  doi_paper = "10.3996/052012-JFWM-043", doi_data = "", notes = "RMark package data (GPL). Jolly-Seber within year; ids not linked across years."), dictc("RMark")))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Jolly-Seber capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (2 years x 13 two-week windows)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the RMark R package.")

# =========================================================================================
# 5. Cottontails, Edwards & Eberhardt (1967), 18 occasions
# =========================================================================================
TABLE <- "edwards_1967_cottontail_cc"
ee <- pkg_obj(TABLE, "RMark", "edwards.eberhardt.rda", "edwards.eberhardt")
m <- do.call(rbind, strsplit(as.character(ee$ch), "")); storage.mode(m) <- "integer"
stopifnot(identical(dim(m), c(76L, 18L)), all(m %in% 0:1), all(rowSums(m) >= 1))
ids <- sprintf("R%02d", seq_len(76))
long <- data.table(unit = rep(ids, times = 18), occasion = rep(1:18, each = 76), y = as.integer(m))
long <- order_eco(long[, .(unit, taxon = "SYLFLO", y, occasion)])
taxa <- make_taxa("SYLFLO", "Sylvilagus floridanus", vernacularName = "Eastern cottontail", taxon_iucnCategory = "LC",
                  taxonRemarks = "the package says 'rabbits'; Edwards & Eberhardt (1967) studied cottontails, assumed the eastern cottontail")
dataset <- list(
  title = "Live-trapping histories of 76 cottontail rabbits over 18 occasions (Edwards & Eberhardt 1967)",
  creator = "Edwards, W. R.; Eberhardt, L. L. (data); Laake, Jeff L. (distributed in the RMark R package)",
  pubDate = "1967", sourceURL = "https://cran.r-project.org/package=RMark", citation = pcite("RMark", "edwards.eberhardt"),
  paperDOI = "10.2307/3798362", intellectualRights = lic("RMark"),
  abstract = "Capture histories of 76 cottontail rabbits live-trapped on 18 occasions, from Edwards & Eberhardt's (1967) study of estimating cottontail abundance from live-trapping data, the closed-population example distributed with program MARK and RMark. One row per rabbit x occasion.",
  samplingProtocol = "Live trapping on 18 occasions (Edwards & Eberhardt 1967); trap layout and dates are not in the package.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; every one of the 18 occasions is taken as a survey.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "single closed session of 18 occasions",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Not stated in the package (see Edwards & Eberhardt 1967); no coordinates", temporalCoverage = "before 1967 (dates not in the package)",
  coordinatesCoarsened = NA,
  notes = "The MARK teaching example of the closed-population models (Closed, Huggins and their mixtures). Species assumed Sylvilagus floridanus (the package says 'rabbits'). Unit ids are row numbers.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Closed-population live-trapping histories of 76 cottontail rabbits over 18 occasions (Edwards & Eberhardt 1967; RMark::edwards.eberhardt, the MARK example).",
  reference = "Edwards, W. R., & Eberhardt, L. L. (1967). Estimating cottontail abundance from livetrapping data. Journal of Wildlife Management, 31, 87-96.",
  doi_paper = "10.2307/3798362", doi_data = "", notes = "RMark package data (GPL). Place and dates not in the package."), dictc("RMark")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Closed capture-recapture",
  sampling_protocol = "live_trap", design = "Single-season (18 occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the RMark R package (MARK example).")

# =========================================================================================
# 6. White-tailed deer, Brosnan Forest, double observer, 2005-2009
# =========================================================================================
TABLE <- "collier_2012_brosnan_deer_dobs"
de <- as.data.table(pkg_obj(TABLE, "RMark", "deer.rda", "deer"))
stopifnot(nrow(de) == 4508L, all(de$SL %in% 0:1), all(de$TI %in% 0:1), !any(de$SL == 0 & de$TI == 0),
          uniqueN(de$Group) == 79L, identical(sort(unique(as.integer(as.character(de$Year)))), 2005:2009),
          de[, uniqueN(paste(Year, MgmtUnit)), by = Group][, all(V1 == 1L)])
de[, `:=`(unit = sprintf("D%04d", .I), cell = paste0(TI, SL))]
CELLS <- c("10", "01", "11")
long <- de[, .(occasion = 1:3, y = as.integer(cell == CELLS), y_raw = CELLS), by = .(unit, Group, Year, MgmtUnit, Cluster)]
long[, `:=`(period = as.integer(as.character(Year)) - 2004L, cluster_id = sprintf("S%02d", as.integer(as.character(Group))),
            unit_mgmt_unit = as.character(MgmtUnit), unit_obs_cluster = as.character(Cluster))]
stopifnot(nrow(long) == 4508L * 3L, sum(long$y) == 4508L)
long <- order_eco(long[, .(unit, taxon = "ODOVIR", y, y_raw, period, occasion, cluster_id, unit_mgmt_unit, unit_obs_cluster)])
periods <- de[, .(n_surveys = uniqueN(Group), n_deer = .N), by = Year][order(Year)][, `:=`(period = as.integer(as.character(Year)) - 2004L, year = as.integer(as.character(Year)))][, .(period, year, n_surveys, n_deer)]
taxa <- make_taxa("ODOVIR", "Odocoileus virginianus", vernacularName = "White-tailed deer", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Double-observer (thermal imager and spotlight) road-transect detections of 4,508 white-tailed deer, Brosnan Forest, South Carolina, August 2005-2009",
  creator = "Collier, Bret A.; Ditchkoff, Stephen S.; Ruth, Charles R.; Raglin, Joshua B. (data; distributed in the RMark R package)",
  pubDate = "2012", sourceURL = "https://cran.r-project.org/package=RMark", citation = pcite("RMark", "deer"),
  paperDOI = "10.1002/jwmg.444", intellectualRights = lic("RMark"),
  abstract = "White-tailed deer (Odocoileus virginianus) counted from a vehicle on 79 night road-transect surveys on Brosnan Forest, South Carolina, in August 2005-2009, by a thermal imager (primary observer) and an independent spotlight observer on the same side. Each deer seen is recorded as seen by the thermal imager only, the spotlight only, or both. One unit per detected deer with its three detection cells (y = 1 in its cell), as in tumursukh_2016_tost_argali_dobs; the survey is cluster_id. Collier et al. (2012) used it to show how many deer spotlight surveys miss.",
  samplingProtocol = "Night road transects driven with a thermal imager and a spotlight operated independently on the same side of the vehicle; 79 paired surveys over four management units, August 2005-2009.",
  samplingProtocolCode = "line_transect", surveyEvidence = "row_presence",
  surveyEvidenceNote = "Each row of the package is a deer seen by at least one observer; both observers surveyed it, so all three cells are defined. Deer missed by both are not in the data by design, and a survey with no deer seen would be absent.",
  responseType = "multinomial_cell", multinomialType = "double_observer", unitKind = "individual",
  closure = "closed", closureNote = "occasion = the three detection cells of one deer on one survey; deer are not matched between surveys",
  occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Brosnan Forest, Dorchester County, South Carolina, USA (about 33.1 N, 80.4 W); no transect coordinates in the package",
  temporalCoverage = "2005-08/2009-08", coordinatesCoarsened = NA,
  notes = "occasion 1 = thermal imager only (y_raw 10), 2 = spotlight only (01), 3 = both (11); sum y by occasion within a survey for the authors' cell counts. cluster_id = the paired survey (Group); unit_obs_cluster = the group of deer seen together (detections are not independent within a cluster); unit_mgmt_unit = management unit 1-4. MaxCount (per survey, for bootstrapping) is not shipped.",
  notShipped = list(MaxCount = "maximum count per survey, used only for the authors' bootstrap"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Double-observer detections (thermal imager only, spotlight only, both) of 4,508 white-tailed deer on 79 night road-transect surveys, Brosnan Forest, South Carolina, August 2005-2009 (RMark::deer; Collier et al. 2012).",
  reference = "Collier, B. A., Ditchkoff, S. S., Ruth, C. R., & Raglin, J. B. (2012). Spotlight surveys for white-tailed deer: monitoring panacea or exercise in futility? Journal of Wildlife Management, 77, 165-171.",
  doi_paper = "10.1002/jwmg.444", doi_data = "", notes = "RMark package data (GPL). Independent double observer, one unit per detected deer."), dictc("RMark")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Double-observer",
  sampling_protocol = "line_transect", design = "Multi-season (5 years, 79 paired surveys)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the RMark R package.")

# =========================================================================================
# 7. Mahoenui giant weta occupancy (PRESENCE example)
# =========================================================================================
TABLE <- "mackenzie_2006_mahoenui_weta_occ"
wt <- as.data.table(pkg_obj(TABLE, "RMark", "weta.rda", "weta"))
stopifnot(nrow(wt) == 72L, all(nchar(wt$ch) == 5L), identical(names(wt), c("ch", "Browse", paste0("Obs", 1:5))), all(wt$Browse %in% 0:1))
chm <- do.call(rbind, strsplit(wt$ch, "")); obm <- as.matrix(wt[, paste0("Obs", 1:5), with = FALSE])
stopifnot(all(chm %in% c("0", "1", ".")), all((chm == ".") == (obm == ".")), sum(chm == ".") == 98L)
long <- data.table(unit = rep(sprintf("W%02d", 1:72), times = 5), occasion = rep(1:5, each = 72), yc = as.vector(chm), ob = as.vector(obm),
                   unit_browsed = rep(as.integer(wt$Browse), times = 5))[yc != "."]
long <- order_eco(long[, .(unit, taxon = "DEIMAH", y = as.integer(yc), occasion, observer = paste0("obs", ob), unit_browsed)])
stopifnot(nrow(long) == 360L - 98L)
taxa <- make_taxa("DEIMAH", "Deinacrida mahoenui", vernacularName = "Mahoenui giant weta")
dataset <- list(
  title = "Mahoenui giant weta detection on up to 5 visits to 72 sites, with browsing and observer (MacKenzie et al. 2006 PRESENCE example)",
  creator = "MacKenzie, Darryl I.; Nichols, James D.; Royle, J. Andrew; Pollock, Kenneth H.; Bailey, Larissa L.; Hines, James E. (book example; distributed in the RMark R package)",
  pubDate = "2006", sourceURL = "https://cran.r-project.org/package=RMark", citation = pcite("RMark", "weta"),
  intellectualRights = lic("RMark"),
  abstract = "Detection/non-detection of the Mahoenui giant weta (Deinacrida mahoenui), a New Zealand insect, on up to five visits to 72 sites, with whether the site was browsed (by goats) and the observer on each visit: the example data of MacKenzie et al. (2006, pp. 116-122) distributed with PRESENCE and RMark. One row per site x visit made.",
  samplingProtocol = "Repeated searches of sites for weta; visit-specific observers; browsing recorded per site (MacKenzie et al. 2006).",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The history marks visits not made with '.', identically in the observer columns (asserted); a row exists for each visit made (262 of 360).",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "single season",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Mahoenui Giant Weta Scientific Reserve area, King Country, New Zealand (as the species' range implies; not stated in the package); no coordinates",
  temporalCoverage = "not stated in the package (MacKenzie et al. 2006)", coordinatesCoarsened = NA,
  notes = "A textbook example with no place, date or field description in the package; the weta's only natural population is at Mahoenui. The help page's description line says 'salamanders' in error. Observer codes as deposited (obs1-obs3). Site ids are row numbers.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Mahoenui giant weta detection/non-detection on up to 5 visits to 72 sites, with browsing and observer (RMark::weta; the MacKenzie et al. 2006 PRESENCE example).",
  reference = "MacKenzie, D. I., Nichols, J. D., Royle, J. A., Pollock, K. H., Bailey, L. L., & Hines, J. E. (2006). Occupancy Estimation and Modeling. Elsevier (pp. 116-122).",
  doi_paper = "", doi_data = "", notes = "RMark package data (GPL). Textbook example; place and year not in the package."), dictc("RMark")))
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Single-season occupancy",
  sampling_protocol = "visual_encounter", design = "Single-season (up to 5 visits)", realm = "Terrestrial",
  country = "NZL", coordinates = "None in source", notes = "From the RMark R package (PRESENCE example).")

# =========================================================================================
# 8. Cutthroat trout, Auke Lake, Alaska, 1998-2006
# =========================================================================================
TABLE <- "harding_2010_aukelake_cutthroat_cjs"
ct <- as.data.table(pkg_obj(TABLE, "FSA", "CutthroatAL.rdata", "CutthroatAL"))
yc <- paste0("y", 1998:2006)
stopifnot(nrow(ct) == 1684L, identical(names(ct), c("id", yc)), !anyDuplicated(ct$id), all(unlist(ct[, ..yc]) %in% 0:1),
          all(rowSums(ct[, ..yc]) >= 1), all(colSums(ct[, ..yc]) > 0))
m <- as.matrix(ct[, ..yc])
long <- data.table(unit = rep(sprintf("C%04d", ct$id), times = 9), period = rep(1:9, each = 1684), y = as.integer(m))
long <- order_eco(long[, .(unit, taxon = "ONCCLA", y, period)])
periods <- data.table(period = 1:9, year = 1998:2006, n_caught = colSums(m))
taxa <- make_taxa("ONCCLA", "Oncorhynchus clarkii", vernacularName = "Cutthroat trout", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Annual capture histories of 1,684 cutthroat trout in Auke Lake, Alaska, 1998-2006",
  creator = "Harding, Roger D.; Hoover, C. L.; Marshall, R. P. (Alaska Department of Fish and Game) (data); Ogle, Derek H. (distributed in the FSA R package)",
  pubDate = "2010", sourceURL = "https://cran.r-project.org/package=FSA", citation = pcite("FSA", "CutthroatAL"),
  intellectualRights = lic("FSA"),
  abstract = "Cutthroat trout (Oncorhynchus clarkii) marked and recaptured in Auke Lake, near Juneau, Southeast Alaska, in annual samples from 1998 to 2006, from Appendix A.3 of an Alaska Department of Fish and Game report on the population's abundance in 2005 and 2006 (Harding et al. 2010), as distributed in FSA (CutthroatAL). One row per fish x year, y = 1 if caught.",
  samplingProtocol = "Annual mark-recapture sampling of cutthroat trout in Auke Lake (ADF&G); gear and timing in the report, not the package.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; every year 1998-2006 had captures and is taken as a survey. Fish of unknown age have rows from 1998.",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period = year (open population, Jolly-Seber)",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Auke Lake, Juneau, Southeast Alaska, USA (about 58.38 N, 134.64 W); no coordinates in the package", temporalCoverage = "1998/2006",
  coordinatesCoarsened = NA,
  notes = "Unit ids are the package's fish ids. Source: Harding, R. D., Hoover, C. L., & Marshall, R. P. (2010). Abundance of cutthroat trout in Auke Lake, Southeast Alaska, in 2005 and 2006. Alaska Department of Fish and Game, Fishery Data Series No. 10-82, Appendix A.3. Losses and tagging details are not in the package.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Annual capture histories of 1,684 cutthroat trout in Auke Lake, Alaska, 1998-2006 (FSA::CutthroatAL; Harding et al. 2010, ADF&G Fishery Data Series 10-82).",
  reference = "Harding, R. D., Hoover, C. L., & Marshall, R. P. (2010). Abundance of cutthroat trout in Auke Lake, Southeast Alaska, in 2005 and 2006. Alaska Department of Fish and Game, Fishery Data Series No. 10-82.",
  doi_paper = "", doi_data = "", notes = "FSA package data (GPL). Annual open-population histories."), dictc("FSA")))
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Jolly-Seber / CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (9 annual occasions)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "From the FSA R package.")

# =========================================================================================
# 9. Bluegill, Jewett Lake, Michigan (two samples)
# =========================================================================================
TABLE <- "schneider_1998_jewettlake_bluegill_cc"
bg <- as.data.table(pkg_obj(TABLE, "FSA", "BluegillJL.rdata", "BluegillJL"))
stopifnot(nrow(bg) == 277L, identical(names(bg), c("first", "second")), all(unlist(bg) %in% 0:1), all(rowSums(bg) >= 1))
long <- data.table(unit = rep(sprintf("G%03d", 1:277), times = 2), occasion = rep(1:2, each = 277), y = c(bg$first, bg$second))
long <- order_eco(long[, .(unit, taxon = "LEPMAC", y = as.integer(y), occasion)])
taxa <- make_taxa("LEPMAC", "Lepomis macrochirus", vernacularName = "Bluegill", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Two-sample mark-recapture histories of 277 bluegill longer than 6 inches, Jewett Lake, Michigan",
  creator = "Schneider, James C. (Michigan Department of Natural Resources) (data); Ogle, Derek H. (distributed in the FSA R package)",
  pubDate = "1998", sourceURL = "https://cran.r-project.org/package=FSA", citation = pcite("FSA", "BluegillJL"),
  intellectualRights = lic("FSA"),
  abstract = "Bluegill (Lepomis macrochirus) longer than 6 inches marked in a first sample and checked in a second sample in Jewett Lake, Michigan: the Petersen example 8.1 of the Michigan DNR Manual of Fisheries Survey Methods II (Schneider 1998), as distributed in FSA (BluegillJL). One row per fish x sample.",
  samplingProtocol = "Two-sample (Petersen) mark-recapture of bluegill > 6 in; gear and dates in the manual, not the package.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; both samples are surveys.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "two samples, closed population (Petersen)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Jewett Lake, Michigan, USA; no coordinates in the package", temporalCoverage = "not stated in the package (before 1998)",
  coordinatesCoarsened = NA,
  notes = "Only fish > 6 in are included (help page). Source: Schneider, J. C. (1998). Lake fish population estimates by mark-and-recapture methods. Chapter 8 in Manual of fisheries survey methods II, Michigan DNR Fisheries Special Report 25. Unit ids are row numbers.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Two-sample mark-recapture histories of 277 bluegill > 6 in, Jewett Lake, Michigan (FSA::BluegillJL; Schneider 1998, Michigan DNR).",
  reference = "Schneider, J. C. (1998). Lake fish population estimates by mark-and-recapture methods. Chapter 8 in J. C. Schneider (Ed.), Manual of fisheries survey methods II. Michigan Department of Natural Resources, Fisheries Special Report 25.",
  doi_paper = "", doi_data = "", notes = "FSA package data (GPL). Petersen two-sample closed capture."), dictc("FSA")))
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Closed capture-recapture",
  sampling_protocol = "live_trap", design = "Single-season (2 samples)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "From the FSA R package.")
