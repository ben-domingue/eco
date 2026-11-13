#!/usr/bin/env Rscript
# Tables: sutherland_2012_scotland_vole_dynocc, roth_2014_aargau_marbledwhite_dynocc,
#         kery_2021_jura_peregrine_dynocc, kery_2016_jura_peregrine_ttd_occ,
#         kery_2021_swiss_eagleowl_state, zipkin_2014_maryland_dusky_count,
#         kery_2016_swiss_squirrel_occ
# Source: the example datasets of the R package AHMbook (Kéry, Royle, Meredith), version 0.2.12
#         (CRAN, published 2026-04-15), licence GPL (>= 3) as shown on the CRAN page and in the
#         package DESCRIPTION (asserted below); the data carry no licence of their own.
#         Kéry, M., Royle, J. A. & Meredith, M. AHMbook: Functions and data for the book
#         'Applied Hierarchical Modeling in Ecology' Vols 1 and 2. R package version 0.2.12.
#         https://CRAN.R-project.org/package=AHMbook
#         The package is not loaded: the pinned source tarball is downloaded and
#         data/<name>.rda (inst/extdata/SwissSquirrels.txt for the squirrels) read directly.
# Data (help pages man/data_<name>.Rd, read in full):
#   waterVoles: water vole latrine surveys of 114 habitat patches in Scotland, up to 3 surveys
#     a year 2009-2011 (322 patch-years, all with 3 surveys; patch-years not in the frame were
#     not surveyed); the help page says some detections may be false positives. Patch codes
#     carry five area prefixes (cla, cro, led, lei, sgi) the help page does not expand. Data
#     of C. Sutherland, X. Lambin and colleagues; Sutherland, Elston & Lambin (2012), Ecology
#     93, 2465-2473, doi:10.1890/12-0172.1; AHM2 section 7.2.2.
#   SwissMarbledWhite: Marbled White detection/non-detection on 11 visits a year at 519
#     plots of the Aargau Biodiversity Monitoring Program (LANAG), each plot sampled in one
#     year of every five, 1998-2010 (1,337 plot-years); Day1-Day11 = Julian date (1 = 1 April),
#     NA where the date was not recorded (195 visits; their detections are recorded).
#     Roth, Strebel & Amrhein (2014), Ecology 95, 2144-2154, doi:10.1890/13-1830.1 (field
#     methods: figshare 3559965); AHM2 section 4.13. Courtesy I. Flöss, Kanton Aargau.
#   FrenchPeregrines: whether a peregrine pair was detected at least once per year at 284 cliff
#     sites of the French Jura (departments Ain, Doubs, Jura), 1964-2016; NA = no survey that
#     year. Only sites where a pair was detected at least once are included (help page).
#     Groupe Pèlerin Jura (R.-J. Monneret, R. Ruffinoni and colleagues); AHM2 section 4.11.
#   ttdPeregrine: 38 breeding cliffs in the French Jura searched up to 3 times on 7-9 March
#     2015; search length 3-95 min (Tmax); one row per bird seen (ttd in minutes and sex),
#     or one row with ttd NA when none was seen. AHM1 section 10.12.
#   SwissEagleOwls: eagle owl observations in the 274 1-km2 territories in Switzerland where
#     a territorial owl was detected at least once 2007-2016, from more or less opportunistic
#     surveys; at most 20 observations per site-year, randomly selected where there were
#     more (help page). obs: site, year, Julian date (1 = 1 Jan), state 0 not detected, 1
#     single bird, 2 pair without breeding evidence, 3 pair with breeding evidence. sites:
#     region, elevation, forest, slope, road length. Swiss Ornithological Institute; AHM2
#     chapter 6.
#   duskySalamanders: counts of northern dusky salamanders, juveniles (< 35 mm SVL) and
#     adults, at 21 locations on 12 headwater streams in Maryland and the District of
#     Columbia, in June and July of 2005-2011 (the array has these 7 years; the help page
#     text says 2005-2012), two 15-m stream-bed transects turning cover objects; no NA.
#     Data of E. Grant and colleagues (USGS ARMI); Zipkin et al. (2014), Ecology 95, 22-29,
#     doi:10.1890/13-1131.1; AHM2 section 2.9.2.
#   SwissSquirrels.txt: red squirrel detection/non-detection on 3 surveys in 2007 at 265 Swiss
#     MHB 1-km2 quadrats, with survey date (1 = 1 April) and duration, quadrat elevation,
#     route length and forest cover, and quadrat centre coordinates whose reference system
#     the source 'intentionally' does not specify. Swiss Ornithological Institute; AHM1
#     section 10.9.
# Mapping (standard E1-E6, E8):
#   Each site table: unit = the source's site or patch id (row number for the squirrels),
#   period = year index (year in __periods) where there are several years, occasion =
#   visit within the year, y = the recorded value; a row exists for every visit the source
#   records (surveyEvidence deposited_matrix: absent rows or NA = not surveyed), or for every
#   observation row (row_presence: eagle owls, ttd searches). Covariates at their level:
#   unit_ (site), obs_ (visit), __periods (year). taxon codes: MELGAL, FALPER, BUBBUB,
#   ARVAMP, SCIVUL, and DESFUS_J / DESFUS_A for the dusky salamander stage counts (lifeStage
#   in __taxa, as in price_2018_mtr_salamanders_count).
#   Time to detection (standard ruling 2026-11-06): y = 1 if any peregrine was seen in the
#   search, obs_ttd = the first time any bird was seen (minutes), or the search length when
#   none was, obs_ttd_censored = 1 then; obs_n_records = rows the source lists for the search.
#   No table has real coordinates: the squirrel quadrat coordinates are shipped as unit_
#   covariates in the source's unspecified reference system, not as locations.
#   Not shipped: the AHMbook model code and simulated data sets (not in these scripts).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/ahmbook_package_tables.R"
VER <- "0.2.12"
TARBALL <- sprintf("AHMbook_%s.tar.gz", VER)
CRAN_PAGE <- "https://cran.r-project.org/package=AHMbook"
PKG_CITE <- sprintf("Kéry, M., Royle, J. A., & Meredith, M. (2026). AHMbook: Functions and data for the book 'Applied Hierarchical Modeling in Ecology' Vols 1 and 2 (Version %s) [R package; dataset %%s]. CRAN. https://CRAN.R-project.org/package=AHMbook", VER)
AHM1 <- "Kéry, M. & Royle, J. A. (2016). Applied Hierarchical Modeling in Ecology, Volume 1. Academic Press."
AHM2 <- "Kéry, M. & Royle, J. A. (2021). Applied Hierarchical Modeling in Ecology, Volume 2. Academic Press."
GPL <- list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html")

ahm_dir <- function(table) {
  f <- file.path(RAW_DIR, table, TARBALL)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", TARBALL), table, TARBALL), silent = TRUE)
    if (inherits(ok, "try-error"))
      download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/AHMbook/%s", TARBALL), table, TARBALL)
  }
  ex <- file.path(RAW_DIR, table, "AHMbook")
  if (!dir.exists(ex)) untar(f, files = c("AHMbook/DESCRIPTION", "AHMbook/data", "AHMbook/inst/extdata"), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == VER, desc[, "License"] == "GPL (>= 3)")
  ex
}
ahm_data <- function(table, name) {
  e <- new.env(); load(file.path(ahm_dir(table), "data", paste0(name, ".rda")), envir = e); get(name, envir = e)
}
common <- list(sourceURL = CRAN_PAGE, intellectualRights = GPL, coordinatesCoarsened = NA)
dict_common <- list(url = CRAN_PAGE, original_license = "GPL (>= 3) (AHMbook R package; the data have no licence of their own)",
                    derived_license = "GPL-3.0-or-later", source_via = sprintf("CRAN source tarball AHMbook %s", VER))
wide_long <- function(dt, id_cols, ycols, occ_names = seq_along(ycols)) {
  l <- melt(dt, id.vars = id_cols, measure.vars = ycols, variable.name = "vcol", value.name = "y")
  l[, occasion := as.integer(match(as.character(vcol), ycols))]
  l[, vcol := NULL]
  l
}

# =========================================================================================
# 1. Water voles, Scotland, 2009-2011
# =========================================================================================
TABLE <- "sutherland_2012_scotland_vole_dynocc"
wv <- as.data.table(ahm_data(TABLE, "waterVoles"))
stopifnot(nrow(wv) == 322L, uniqueN(wv$Patch) == 114L, !anyDuplicated(wv[, .(Patch, Year)]),
          identical(as.vector(table(wv$Year)), c(105L, 106L, 111L)), identical(levels(wv$Year), c("2009", "2010", "2011")),
          !anyNA(wv[, .(y1, y2, y3)]), all(unlist(wv[, .(y1, y2, y3)]) %in% 0:1),
          setequal(unique(substr(as.character(wv$Patch), 1, 3)), c("cla", "cro", "led", "lei", "sgi")))
wv[, `:=`(unit = as.character(Patch), period = as.integer(Year))]
long <- wide_long(wv[, .(unit, period, y1, y2, y3)], c("unit", "period"), c("y1", "y2", "y3"))
long[, unit_area_code := substr(unit, 1, 3)]
stopifnot(nrow(long) == 966L)
long <- order_eco(long[, .(unit, taxon = "ARVAMP", y, period, occasion, unit_area_code)])
periods <- data.table(period = 1:3, year = 2009:2011, n_patches_surveyed = c(105L, 106L, 111L))
taxa <- make_taxa("ARVAMP", "Arvicola amphibius", vernacularName = "European water vole", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Water vole latrine surveys of 114 habitat patches in Scotland, 3 surveys a year, 2009-2011",
  creator = "Sutherland, Chris; Lambin, Xavier; and colleagues (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2012", citation = sprintf(PKG_CITE, "waterVoles"), paperDOI = "10.1890/12-0172.1",
  abstract = "Habitat patches suitable for water voles (Arvicola amphibius) in Scotland were searched for latrines (territorial faecal deposits) up to three times a year from 2009 to 2011, as part of the metapopulation studies of Sutherland, Elston & Lambin. The data are the AHMbook package's waterVoles: one row per patch x year x survey, y = 1 where latrines were found. The help page notes that some detections may be false positives; the data are the model example for false-positive dynamic occupancy in AHM2 section 7.2.2.",
  samplingProtocol = "Each suitable habitat patch searched for water vole latrines up to three times per year; detection = latrines found.",
  samplingProtocolCode = "sign_survey", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The data frame has one row per surveyed patch-year with three surveys each (no NA); a patch-year absent from it was not surveyed and has no rows.",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "period (closed within a year, dynamic between years)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Scotland, UK: five groups of habitat patches (codes cla, cro, led, lei, sgi); the help page names no locality and gives no coordinates",
  temporalCoverage = "2009/2011",
  notes = "unit_area_code is the three-letter prefix of the patch code (not expanded in the source). Possible false positives are not flagged per record. Survey dates are not in the package.",
  notShipped = list(none = "nothing: the data frame is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Water vole latrine detection/non-detection at 114 habitat patches in Scotland, 3 surveys a year 2009-2011 (AHMbook::waterVoles; Sutherland, Lambin and colleagues).",
  reference = "Sutherland, C., Elston, D. A., & Lambin, X. (2012). Multi-scale processes in metapopulations: contributions of stage structure, rescue effect, and correlated extinctions. Ecology, 93, 2465-2473.",
  doi_paper = "10.1890/12-0172.1", doi_data = "",
  notes = "AHMbook package data (GPL). Possible false positives (help page)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "sign_survey", design = "Multi-season (3 years x 3 surveys)", realm = "Freshwater",
  country = "GBR", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 7.2.2, false positives).")

# =========================================================================================
# 2. Marbled White, Aargau, 1998-2010
# =========================================================================================
TABLE <- "roth_2014_aargau_marbledwhite_dynocc"
mw <- as.data.table(ahm_data(TABLE, "SwissMarbledWhite"))
yc <- paste0("y", 1:11); dc <- paste0("Day", 1:11)
stopifnot(nrow(mw) == 1337L, uniqueN(mw$site) == 519L, !anyDuplicated(mw[, .(site, year)]),
          identical(sort(unique(mw$year)), 1998:2010), !anyNA(mw[, ..yc]), all(unlist(mw[, ..yc]) %in% 0:1),
          sum(is.na(mw[, ..dc])) == 195L)
long <- wide_long(mw[, c("site", "year", yc), with = FALSE], c("site", "year"), yc)
days <- wide_long(mw[, c("site", "year", dc), with = FALSE], c("site", "year"), dc)
setnames(days, "y", "obs_day_from_apr1")
long <- merge(long, days, by = c("site", "year", "occasion"))
long[, `:=`(unit = sprintf("%03d", site), period = year - 1997L)]
stopifnot(nrow(long) == 1337L * 11L)
long <- order_eco(long[, .(unit, taxon = "MELGAL", y, period, occasion, obs_day_from_apr1)])
periods <- mw[, .(n_plots_surveyed = .N), by = year][order(year)][, period := year - 1997L][, .(period, year, n_plots_surveyed)]
taxa <- make_taxa("MELGAL", "Melanargia galathea", vernacularName = "Marbled white", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Marbled White detection on 11 visits at 519 plots of the Aargau Biodiversity Monitoring Program, Switzerland, 1998-2010",
  creator = "Kanton Aargau, Abteilung Landschaft und Gewässer (LANAG monitoring; courtesy I. Flöss); Roth, Tobias; Strebel, Nicolas; Amrhein, Valentin (distributed in the AHMbook R package)",
  pubDate = "2014", citation = sprintf(PKG_CITE, "SwissMarbledWhite"), paperDOI = "10.1890/13-1830.1",
  abstract = "Butterfly surveys of the Aargau Biodiversity Monitoring Program (LANAG), canton Aargau, Switzerland: each of 519 plots was surveyed in one year out of every five from 1998 to 2010, with 11 visits through the flight season. The data are the AHMbook package's SwissMarbledWhite: one row per plot x year x visit, y = 1 where the Marbled White (Melanargia galathea) was recorded, with the visit date. Used by Roth et al. (2014) to estimate phenological trends with site-occupancy models, and in AHM2 section 4.13.",
  samplingProtocol = "Butterfly transect counts on monitoring plots, 11 visits per survey year (field methods in Roth et al. 2014, Appendix C, figshare 3559965); collapsed by the source to detection/non-detection of the Marbled White per visit.",
  samplingProtocolCode = "transect_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "One row per surveyed plot-year with 11 visits, none NA; a plot-year absent from the frame (each plot is surveyed one year in five) was not surveyed. 195 visits have no recorded date but a recorded result; they are kept with obs_day_from_apr1 NA.",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "period (closed within a year)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Canton Aargau, Switzerland (no plot coordinates in the package)", temporalCoverage = "1998/2010",
  notes = "obs_day_from_apr1 is the package's Julian date (1 = 1 April), NA where not recorded (the AHM2 code imputes these; not done here). Plot ids are the package's site numbers. Each plot has rows in about every fifth year only.",
  notShipped = list(none = "nothing: the data frame is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Marbled White detection/non-detection on 11 visits per survey year at 519 plots of the Aargau Biodiversity Monitoring Program, Switzerland, each plot surveyed every fifth year 1998-2010, with visit dates (AHMbook::SwissMarbledWhite).",
  reference = "Roth, T., Strebel, N., & Amrhein, V. (2014). Estimating unbiased phenological trends by adapting site-occupancy models. Ecology, 95, 2144-2154.",
  doi_paper = "10.1890/13-1830.1", doi_data = "",
  notes = "AHMbook package data (GPL). Rotating panel: each plot surveyed one year in five."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Dynamic occupancy",
  sampling_protocol = "transect_count", design = "Multi-season (13 years, rotating panel, 11 visits)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 4.13).")

# =========================================================================================
# 3. Peregrine pairs, French Jura, 1964-2016 (one aggregated record per year)
# =========================================================================================
TABLE <- "kery_2021_jura_peregrine_dynocc"
pf <- as.data.table(ahm_data(TABLE, "FrenchPeregrines"))
ycols <- paste0("yr", 1964:2016)
stopifnot(nrow(pf) == 284L, identical(names(pf), c("site", "department", "height", ycols)), !anyDuplicated(pf$site),
          all(unlist(pf[, ..ycols]) %in% c(0L, 1L, NA)), sum(!is.na(pf[, ..ycols])) == 10468L,
          all(rowSums(pf[, ..ycols], na.rm = TRUE) >= 1))
long <- melt(pf, id.vars = c("site", "department", "height"), measure.vars = ycols, variable.name = "yr", value.name = "y")[!is.na(y)]
long[, `:=`(unit = sprintf("%03d", site), period = as.integer(sub("yr", "", yr)) - 1963L)]
stopifnot(nrow(long) == 10468L)
long <- order_eco(long[, .(unit, taxon = "FALPER", y, period, unit_department = as.character(department), unit_cliff_height = as.character(height))])
periods <- long[, .(n_sites_surveyed = .N, n_sites_pair = sum(y)), by = period][order(period)][, year := period + 1963L][, .(period, year, n_sites_surveyed, n_sites_pair)]
stopifnot(nrow(periods) == 53L)
taxa <- make_taxa("FALPER", "Falco peregrinus", vernacularName = "Peregrine falcon", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Annual detection of peregrine pairs at 284 cliff territories in the French Jura, 1964-2016",
  creator = "Groupe Pèlerin Jura (Monneret, René-Jean; Ruffinoni, René; and colleagues) (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2021", citation = sprintf(PKG_CITE, "FrenchPeregrines"), paperDOI = "10.1016/B978-0-12-809585-0.00004-1",
  abstract = "Peregrine falcon (Falco peregrinus) cliff territories in the French Jura (departments Ain, Doubs, Jura) monitored by the Groupe Pèlerin Jura from 1964 to 2016, through the species' pesticide-era decline and recovery. Many cliffs were visited several times a year, but only the yearly result survives: whether a pair was seen at least once. The data are the AHMbook package's FrenchPeregrines (AHM2 section 4.11): one row per cliff x year with a survey, y = 1 if a pair was detected.",
  samplingProtocol = "Cliff territories visited by volunteers, often several times per breeding season; the record is the yearly aggregate (pair detected at least once or not).",
  samplingProtocolCode = "territory_survey", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The package's site x year matrix codes 1 (pair detected), 0 (surveyed, no pair) and NA (no survey that year); a row exists where the cell is 0 or 1 (10,468 site-years).",
  responseType = "detection", unitKind = "site", closure = "none", closureNote = "period: one aggregated record per site and year; the number of visits behind it is not available",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "French Jura mountains: departments Ain, Doubs and Jura, France (no coordinates in the package)", temporalCoverage = "1964/2016",
  notes = "Only cliffs where a pair was detected at least once in 1964-2016 are included (help page): the site set is conditioned on detection. unit_cliff_height (low, medium, tall) and unit_department as in the package. Site ids are the package's site numbers.",
  notShipped = list(none = "nothing: the data frame is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Yearly detection of peregrine pairs at 284 cliff territories in the French Jura, 1964-2016, one aggregated record per cliff-year with a survey, with department and cliff height (AHMbook::FrenchPeregrines; Groupe Pèlerin Jura).",
  reference = AHM2, doi_paper = "10.1016/B978-0-12-809585-0.00004-1", doi_data = "",
  notes = "AHMbook package data (GPL). One aggregated record per year; sites conditioned on at least one detection."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy",
  sampling_protocol = "territory_survey", design = "Multi-season (53 years, one aggregated record per year)", realm = "Terrestrial",
  country = "FRA", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 4.11).")

# =========================================================================================
# 4. Peregrine time to detection, French Jura, March 2015
# =========================================================================================
TABLE <- "kery_2016_jura_peregrine_ttd_occ"
td <- as.data.table(ahm_data(TABLE, "ttdPeregrine"))
stopifnot(nrow(td) == 70L, uniqueN(td$SiteNumber) == 38L, identical(levels(td$Date), c("7 March", "8 March", "9 March")),
          all(td$DayNumber == as.integer(td$Date)), sum(is.na(td$ttd)) == 13L, all(is.na(td$ttd) == is.na(td$sex)),
          all(td$ttd <= td$Tmax, na.rm = TRUE), all(td$Tmax >= 3 & td$Tmax <= 95))
td[, search := .GRP, by = .(SiteNumber, DayNumber, Start.hour, Start.minute)]
stopifnot(td[, uniqueN(paste(Tmax, End.hour, End.minute, MinOfDay)), by = search][, all(V1 == 1L)],
          td[, !(any(is.na(ttd)) && .N > 1L), by = search][, all(V1)])
sv <- td[, .(SiteNumber = SiteNumber[1], DayNumber = DayNumber[1], start = MinOfDay[1], Tmax = Tmax[1],
             y = as.integer(any(!is.na(ttd))), ttd_first = if (all(is.na(ttd))) NA_real_ else min(ttd, na.rm = TRUE),
             n_rec = sum(!is.na(ttd))), by = search]
setorder(sv, SiteNumber, DayNumber, start)
sv[, occasion := seq_len(.N), by = SiteNumber]
stopifnot(max(sv$occasion) <= 3L, sum(sv$y) == uniqueN(td[!is.na(ttd), search]))
long <- sv[, .(unit = sprintf("%02d", SiteNumber), taxon = "FALPER", y, occasion,
               date = sprintf("2015-03-%02d", 6L + DayNumber),
               obs_ttd = ifelse(y == 1L, ttd_first, as.numeric(Tmax)), obs_ttd_censored = 1L - y,
               obs_search_min = as.numeric(Tmax), obs_start_min_after_0600 = start, obs_n_records = n_rec)]
long <- order_eco(long)
taxa <- make_taxa("FALPER", "Falco peregrinus", vernacularName = "Peregrine falcon", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Time-to-detection searches for peregrines at 38 breeding cliffs in the French Jura, 7-9 March 2015",
  creator = "Kéry, Marc; Royle, J. Andrew (data and distribution in the AHMbook R package)",
  pubDate = "2016", citation = sprintf(PKG_CITE, "ttdPeregrine"), paperDOI = "10.1016/B978-0-12-801378-6.00010-2",
  abstract = "Between 7 and 9 March 2015, 38 peregrine falcon breeding cliffs in the French Jura were searched up to three times for 3 to 95 minutes, recording the time at which each bird was first seen and its sex. The data are the AHMbook package's ttdPeregrine (AHM1 section 10.12). One row per search: y = 1 if any peregrine was seen, obs_ttd the minutes to the first bird (the search length when none, censored).",
  samplingProtocol = "Timed searches of breeding cliffs by one observer, 3-95 minutes; the time to detection of each bird seen recorded.",
  samplingProtocolCode = "visual_survey", surveyEvidence = "row_presence",
  surveyEvidenceNote = "The package lists every search: one row per bird seen, or a single row with no time when none was. A search is a site x day x start time (asserted to share one length and end time).",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "single season: three days in March 2015",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "French Jura mountains, France (no coordinates in the package)", temporalCoverage = "2015-03-07/2015-03-09",
  notes = "Time to detection per the 2026-11-06 ruling: obs_ttd in minutes from the search start, obs_ttd_censored = 1 where nothing was seen (obs_ttd = search length). obs_n_records = birds listed for the search (a bird may appear more than once; the package does not say). The sex of each bird is in the source but not per search here. Site ids are the package's SiteNumber; whether they match FrenchPeregrines sites is not stated. Two searches of one site on one day are two occasions.",
  notShipped = list(sex_per_bird = "the sex and individual times of each bird after the first: per-record detail beyond the survey's time to first detection",
                    Start.hour_End.hour_End.minute = "redundant with obs_start_min_after_0600 and obs_search_min")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Time-to-detection searches (3-95 min) for peregrines at 38 breeding cliffs in the French Jura on 7-9 March 2015: detection per search with the time to first detection and a censoring flag (AHMbook::ttdPeregrine).",
  reference = AHM1, doi_paper = "10.1016/B978-0-12-801378-6.00010-2", doi_data = "",
  notes = "AHMbook package data (GPL). Time to detection as obs_ columns (ruling 2026-11-06)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Occupancy with time to detection",
  sampling_protocol = "visual_survey", design = "Single-season (up to 3 searches per cliff)", realm = "Terrestrial",
  country = "FRA", coordinates = "None in source", notes = "From the AHMbook R package (AHM1 10.12).")

# =========================================================================================
# 5. Eagle owls, Switzerland, 2007-2016 (multi-state)
# =========================================================================================
TABLE <- "kery_2021_swiss_eagleowl_state"
eo <- ahm_data(TABLE, "SwissEagleOwls")
obs <- as.data.table(eo$obs); sites <- as.data.table(eo$sites)
stopifnot(nrow(obs) == 5974L, nrow(sites) == 274L, !anyDuplicated(sites$site_name), all(obs$site_name %in% sites$site_name),
          all(obs$y %in% 0:3), identical(as.vector(table(obs$y)), c(2414L, 1977L, 635L, 948L)),
          identical(range(obs$year), c(2007L, 2016L)), !anyNA(obs$jdate), all(obs$jdate >= 1 & obs$jdate <= 366),
          max(obs[, .N, by = .(site_name, year)]$N) == 20L)
obs[, ord := .I]
setorder(obs, site_name, year, jdate, ord)
obs[, occasion := seq_len(.N), by = .(site_name, year)]
long <- obs[, .(unit = sprintf("%03d", site_name), taxon = "BUBBUB", y = as.integer(y), period = year - 2006L, occasion,
                date = format(as.Date(sprintf("%d-01-01", year)) + jdate - 1L))]
long <- merge(long, sites[, .(unit = sprintf("%03d", site_name), unit_region = as.character(region), unit_elevation_m = elev,
                              unit_forest_prop = forest, unit_slope_deg = slope, unit_road_length_m = roads)], by = "unit")
stopifnot(nrow(long) == 5974L)
long <- order_eco(long)
periods <- obs[, .(n_sites = uniqueN(site_name), n_obs = .N), by = year][order(year)][, period := year - 2006L][, .(period, year, n_sites, n_obs)]
taxa <- make_taxa("BUBBUB", "Bubo bubo", vernacularName = "Eurasian eagle-owl", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Multi-state observations of eagle owls (none, single bird, pair, breeding pair) at 274 Swiss territories, 2007-2016",
  creator = "Swiss Ornithological Institute (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2021", citation = sprintf(PKG_CITE, "SwissEagleOwls"), paperDOI = "10.1016/B978-0-12-809585-0.00006-5",
  abstract = "Observations of Eurasian eagle-owls (Bubo bubo) in the 274 1-km2 quadrats in Switzerland where a territorial owl was detected at least once from 2007 to 2016, from more or less opportunistic surveys reported to the Swiss Ornithological Institute, each classed as not detected, single bird, pair without breeding evidence, or pair with confirmed breeding (the atlas criteria). Where a site-year had more than 20 observations, 20 were randomly selected. The data are the AHMbook package's SwissEagleOwls (AHM2 chapter 6), with quadrat covariates.",
  samplingProtocol = "More or less opportunistic visits to known territories, each reported as an observation with an atlas breeding-evidence state.",
  samplingProtocolCode = "visual_survey", surveyEvidence = "row_presence",
  surveyEvidenceNote = "Each observation row of the package is a survey, including the explicit non-detections (state 0). Where a site-year had more than 20 observations the source kept a random 20, so the survey set is a subsample there. occasion orders a site-year's observations by date (ties in deposited order).",
  responseType = "state", unitKind = "site", closure = "closed", closureNote = "period (closed within a year)",
  occasionKind = "time", taxonInclusion = "single",
  stateCodes = list(`0` = "not detected", `1` = "single bird detected", `2` = "pair detected, no breeding evidence", `3` = "pair with confirmed breeding"),
  geographicCoverage = "Switzerland, six regions (unit_region); 1-km2 quadrats, no coordinates in the package", temporalCoverage = "2007/2016",
  notes = "Only quadrats where a territorial eagle-owl was ever detected in 2007-2016 are included, and surveys are partly opportunistic (help page). The book aggregates states 2 and 3 into 'pair'; the four states are shipped as deposited. Several observations can share a date. unit_ covariates from the package's sites table (elevation of the quadrat centre, forest proportion, slope, road length).",
  notShipped = list(none = "nothing: both data frames are shipped")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Multi-state eagle-owl observations (not detected, single bird, pair, pair with breeding) at 274 Swiss territories, 2007-2016, from partly opportunistic surveys, with quadrat covariates (AHMbook::SwissEagleOwls).",
  reference = AHM2, doi_paper = "10.1016/B978-0-12-809585-0.00006-5", doi_data = "",
  notes = "AHMbook package data (GPL). Opportunistic surveys at sites conditioned on detection; max 20 observations per site-year (random subsample)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state occupancy",
  sampling_protocol = "visual_survey", design = "Multi-season (10 years, opportunistic visits)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 6).")

# =========================================================================================
# 6. Dusky salamanders, Maryland and DC, 2005-2011 (stage counts)
# =========================================================================================
TABLE <- "zipkin_2014_maryland_dusky_count"
ds_arr <- ahm_data(TABLE, "duskySalamanders")
stopifnot(identical(dim(ds_arr), c(21L, 7L, 2L, 2L)), identical(dimnames(ds_arr)$year, as.character(2005:2011)),
          identical(dimnames(ds_arr)$age, c("Juveniles", "Adults")), identical(dimnames(ds_arr)$survey, c("Jun", "Jul")),
          !anyNA(ds_arr), all(ds_arr >= 0))
long <- as.data.table(as.table(ds_arr))
setnames(long, c("site", "year", "age", "survey", "y"))
long[, `:=`(unit = sprintf("%02d", as.integer(as.character(site))), period = as.integer(as.character(year)) - 2004L,
            occasion = match(as.character(survey), c("Jun", "Jul")), taxon = c(Juveniles = "DESFUS_J", Adults = "DESFUS_A")[as.character(age)],
            obs_month = as.character(survey), y = as.integer(y))]
stopifnot(nrow(long) == 21L * 7L * 2L * 2L, sum(long$y) == sum(ds_arr))
long <- order_eco(long[, .(unit, taxon, y, period, occasion, obs_month)])
periods <- data.table(period = 1:7, year = 2005:2011)
taxa <- make_taxa(c("DESFUS_J", "DESFUS_A"), c("Desmognathus fuscus", "Desmognathus fuscus"),
                  vernacularName = "Northern dusky salamander", lifeStage = c("juvenile", "adult"),
                  taxon_stage_rule = c("< 35 mm snout-vent length (first- and second-year juveniles)", ">= 35 mm snout-vent length"),
                  taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Counts of juvenile and adult northern dusky salamanders at 21 stream locations in Maryland and DC, June and July 2005-2011",
  creator = "Grant, Evan H. C. and colleagues (data); Zipkin, Elise F.; and co-authors; Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2014", citation = sprintf(PKG_CITE, "duskySalamanders"), paperDOI = "10.1890/13-1131.1",
  abstract = "Northern dusky salamanders (Desmognathus fuscus) were counted in June and July each year at 21 locations on 12 headwater streams in Maryland and the District of Columbia, USA: at each location an observer walked two 15-m stream-bed transects turning cover objects in the water and on the bank. Juveniles (< 35 mm snout-vent length) and adults were counted separately. The data are the AHMbook package's duskySalamanders (AHM2 section 2.9.2), used by Zipkin et al. (2014) for stage-structured N-mixture models.",
  samplingProtocol = "Two 15-m transects per location along the stream bed, cover objects turned within 2 m of the stream; counts by age class; surveys in June and July.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The package's site x year x age x month array has no NA: every location was surveyed in both months of every year. Each survey has a row for both stage taxa.",
  responseType = "count", unitKind = "site", closure = "closed", closureNote = "period (June and July of a year treated as closed, as in the source analysis)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "12 headwater streams in Maryland and the District of Columbia, USA (no coordinates in the package)", temporalCoverage = "2005/2011",
  notes = "taxon is species x stage (DESFUS_J juveniles, DESFUS_A adults; lifeStage and the size rule in __taxa), as in price_2018_mtr_salamanders_count. The array has 2005-2011; the help page text says 2005-2012. Most streams have two locations at least 100 m apart; which locations share a stream is not in the package.",
  notShipped = list(none = "nothing: the array is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Counts of juvenile and adult northern dusky salamanders on paired 15-m transects at 21 stream locations in Maryland and DC, June and July 2005-2011 (AHMbook::duskySalamanders; Zipkin et al. 2014).",
  reference = "Zipkin, E. F., Thorson, J. T., See, K., Lynch, H. J., Grant, E. H. C., Kanno, Y., Chandler, R. B., Letcher, B. H., & Royle, J. A. (2014). Modeling structured population dynamics using data from unmarked individuals. Ecology, 95, 22-29.",
  doi_paper = "10.1890/13-1131.1", doi_data = "",
  notes = "AHMbook package data (GPL). Stage-structured counts: stage as taxon (lifeStage in __taxa). Below floor."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture (stage-structured, dynamic)",
  sampling_protocol = "visual_encounter", design = "Multi-season (7 years x 2 surveys)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 2.9.2).")

# =========================================================================================
# 7. Red squirrels, Swiss MHB 2007
# =========================================================================================
TABLE <- "kery_2016_swiss_squirrel_occ"
sq <- fread(file.path(ahm_dir(TABLE), "inst", "extdata", "SwissSquirrels.txt"))
stopifnot(nrow(sq) == 265L, all(sq$spec.name == "Squirrel"),
          identical(names(sq), c("spec.name", "coordx", "coordy", "ele", "route", "forest", "det071", "det072", "det073",
                                 "date071", "date072", "date073", "dur071", "dur072", "dur073")),
          !anyDuplicated(sq[, .(coordx, coordy)]))
sq[, unit := sprintf("%03d", .I)]
long <- rbindlist(lapply(1:3, function(k) sq[, .(unit, occasion = k, y = get(sprintf("det07%d", k)),
                                                  obs_day_from_apr1 = get(sprintf("date07%d", k)), obs_duration_min = get(sprintf("dur07%d", k)))]))
nas <- long[, .(y = is.na(y), d = is.na(obs_day_from_apr1), u = is.na(obs_duration_min))]
cat(sprintf("  squirrels: %d survey cells with no detection value; %d of them also lack date and duration\n", sum(nas$y), sum(nas$y & nas$d & nas$u)))
stopifnot(sum(nas$y) == 48L, all(nas$y == (nas$d & nas$u)))   # a missing survey has no date or duration either
long <- long[!is.na(y)]
stopifnot(all(long$y %in% 0:1), nrow(long) == 747L)
long <- merge(long, sq[, .(unit, unit_x_unspecified_crs = coordx, unit_y_unspecified_crs = coordy, unit_elevation_m = ele,
                          unit_route_km = route, unit_forest_pct = forest)], by = "unit")
long <- order_eco(long[, .(unit, taxon = "SCIVUL", y, occasion, unit_x_unspecified_crs, unit_y_unspecified_crs, unit_elevation_m,
                           unit_route_km, unit_forest_pct, obs_day_from_apr1, obs_duration_min)])
n_surveys <- nrow(long)
taxa <- make_taxa("SCIVUL", "Sciurus vulgaris", vernacularName = "Eurasian red squirrel", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Red squirrel detection on up to 3 surveys of 265 Swiss breeding bird survey (MHB) quadrats, 2007",
  creator = "Swiss Ornithological Institute (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2016", citation = sprintf(PKG_CITE, "SwissSquirrels"), paperDOI = "10.1016/B978-0-12-801378-6.00010-2",
  abstract = "Fieldworkers of the Swiss breeding bird survey MHB also recorded Eurasian red squirrels (Sciurus vulgaris) on their three territory-mapping walks through each 1-km2 quadrat in 2007. The data are the AHMbook package's SwissSquirrels file (AHM1 section 10.9): 265 quadrats (all but two of the MHB sample), one row per quadrat x survey, y = 1 where a squirrel was recorded, with survey date and duration, quadrat elevation, route length and forest cover.",
  samplingProtocol = "Swiss MHB: a fixed route of several km walked three times in the breeding season (2007) through each 1-km2 quadrat; squirrels recorded alongside the bird territory mapping.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The file has a detection column for each of three surveys per quadrat; a missing value means the survey did not take place and has no row.",
  responseType = "detection", unitKind = "site", closure = "closed", closureNote = "single season (2007)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Switzerland, 265 MHB 1-km2 quadrats; quadrat coordinates are in a reference system the source intentionally leaves unspecified (unit_x_unspecified_crs, unit_y_unspecified_crs)",
  temporalCoverage = "2007",
  notes = "The package's coordinates are shipped as unit_ covariates, not as locations: the help page says their reference system is intentionally not specified, so they give relative positions only. Quadrat ids are row numbers of the file. obs_day_from_apr1: 1 = 1 April. Two of the 267 MHB quadrats are not in the source.",
  notShipped = list(spec.name = "constant ('Squirrel')")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Red squirrel detection/non-detection on up to 3 surveys of 265 Swiss MHB 1-km2 quadrats in 2007, with survey date and duration and quadrat elevation, route length and forest cover (AHMbook::SwissSquirrels).",
  reference = AHM1, doi_paper = "10.1016/B978-0-12-801378-6.00010-2", doi_data = "",
  notes = "AHMbook package data (GPL). Coordinates in an unspecified reference system, shipped as covariates only."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "line_transect", design = "Single-season (3 surveys)", realm = "Terrestrial",
  country = "CHE", coordinates = "As published (unspecified CRS, shipped as covariates)", notes = "From the AHMbook R package (AHM1 10.9). Source coordinates have an unspecified CRS; shipped as covariates.")
