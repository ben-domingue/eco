#!/usr/bin/env Rscript
# Table:  muths_2020_blackrock_toad_rd
# Source: USGS ScienceBase doi:10.5066/P9VACHX0 (USGS data release, published 2020-11-24; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Muths, E., 2020, Capture-recapture, disease and covariate data for boreal toads from Blackrock
#   Wyoming 2019: U.S. Geological Survey data release.
# Paper:  Muths, E., et al., 2020, Herpetologica 76(2): 132-143, doi:10.1655/0018-0831-76.2.132
#         (robust-design multi-state model with disease state uncertainty; cited in the metadata).
# Data:   br_cmr.csv: after one blank line, 3,522 toads (animal number, site, sex) x 178 survey-date
#         columns, 2003-2019, coded 1 seen, 0 not seen, "-" no survey on this date (with stray
#         spaces), NR animal not released, empty = no data; plus 430 blank padding rows. Two dates
#         (30 May and 3 June 2019) have two columns each, surveys of different sites on one day.
#         br_bd.csv: the same toads x the 159 survey columns from 2006, Bd status coded 1 not tested,
#         0 tested negative, 2 tested positive, and an undefined code T; one column header is
#         18-May-19 where br_cmr has 16-May-19 (the columns align by position, asserted on every
#         other date). br_cov.csv: fall soil temperature and snow water equivalent per year
#         2012-2018. br_eggmass.csv: Columbia spotted frog egg-mass counts per site-year 2013-2018.
#         Asserted: animal numbers unique; values limited to the codes above.
# Mapping: robust design. unit = toad, cluster_id = its site, period = year (1 = 2003 ... 17 = 2019;
#   2017 has no surveys), occasion = the survey column within the year (columns are survey events:
#   occasion k is not the same date at every site), y = seen. surveyEvidence deposited_matrix: a row
#   for every cell not "-" (the not-surveyed code is per animal and date, so it also marks dates on
#   which the toad's site was not surveyed). NR (not released, 2 cells): y = 1, obs_removed = 1, and
#   the toad's later cells get no rows. obs_bd: the Bd code on a capture (0 negative, 2 positive,
#   1 not tested; T and pre-2006 captures NA); unit_sex normalised (F, M; "M/F?" and juveniles U).
#   __periods: soil temperature and snow water equivalent of the winter before each year
#   (separate weather records, not derived from the toads), where deposited.
# Not shipped: 13 toads with no capture in the matrix (catalogue entries never seen); 2 empty cells (no data); toad cells after a non-release; code T in br_bd (undefined);
#   the spotted frog egg-mass counts (one count per site-year, a covariate of the paper, not a
#   repeated survey of the toads).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "muths_2020_blackrock_toad_rd"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5e989e5682ce172707f6a9d0?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f, skip) {
  x <- fread(download_cached(fl[[f]], TABLE, filename = f), skip = skip, colClasses = "character", header = TRUE, na.strings = NULL, check.names = FALSE)
  x <- x[, names(x) != "" & !startsWith(names(x), "V"), with = FALSE]
  x[`animal number` != ""]
}
cm <- rd("br_cmr.csv", 1); bd <- rd("br_bd.csv", 0)
cov <- fread(download_cached(fl[["br_cov.csv"]], TABLE, filename = "br_cov.csv"))
stopifnot(nrow(cm) == 3522, !anyDuplicated(cm$`animal number`), ncol(cm) == 3 + 178, nrow(bd) == 3522, ncol(bd) == 3 + 159,
          identical(bd$`animal number`, cm$`animal number`))
pd <- function(s) { s <- trimws(sub("\\.[0-9]+$", "", s)); d <- as.IDate(s, format = "%d-%b-%y"); d[is.na(d)] <- as.IDate(s[is.na(d)], format = "%m/%d/%y"); d }
dcm <- pd(names(cm)[-(1:3)]); dbd <- pd(names(bd)[-(1:3)])
stopifnot(!anyNA(dcm), !anyNA(dbd), !is.unsorted(dcm), sum(dcm[20:178] != dbd) == 1, which(dcm[20:178] != dbd) == 149, dcm[168] == as.IDate("2019-05-16"))
cm[, `:=`(site = trimws(site), sex = trimws(sex))]
M <- as.matrix(cm[, -(1:3)]); M[] <- trimws(M)
B <- matrix(NA_character_, nrow(M), ncol(M)); B[, 20:178] <- trimws(as.matrix(bd[, -(1:3)]))
stopifnot(setequal(unique(as.vector(M)), c("-", "0", "1", "NR", "")), sum(M == "NR") == 2, sum(M == "") == 2,
          all(unique(as.vector(B[, 20:178])) %in% c("1", "0", "2", "T", "")))
L <- data.table(i = rep(seq_len(nrow(M)), ncol(M)), j = rep(seq_len(ncol(M)), each = nrow(M)), v = as.vector(M), b = as.vector(B))
L <- L[!v %in% c("-", "")]
nr <- L[v == "NR", .(i, jr = j)]
L <- merge(L, nr, by = "i", all.x = TRUE)
n_after_nr <- L[!is.na(jr) & j > jr, .N]
L <- L[is.na(jr) | j <= jr]
stopifnot(L[v == "0" & b %in% c("0", "2"), .N] == 6, L[v != "0" & b == "T", .N] == 130)
L[, d := dcm[j]][, yr := year(d)]
setorder(L, i, j)
L[, occasion := frank(j, ties.method = "dense"), by = yr]
sexmap <- c(F = "F", M = "M")
long <- L[, .(unit = cm$`animal number`[i], taxon = "ANABOR", y = as.integer(v != "0"), period = yr - 2002L, occasion, date = format(d),
              cluster_id = cm$site[i], unit_sex = ifelse(cm$sex[i] %in% names(sexmap), cm$sex[i], "U"),
              obs_bd = ifelse(v != "0" & b %in% c("0", "1", "2"), match(b, c("0", "1", "2")) - 1L, NA_integer_), obs_removed = as.integer(v == "NR"))]
never <- long[, sum(y), by = unit][V1 == 0, unit]
stopifnot(length(never) == 13); long <- long[!unit %in% never]
stopifnot(sum(long$y) == sum(M %in% c("1", "NR")), uniqueN(long$unit) == 3509, sum(long$obs_removed) == 2)
periods <- data.table(period = sort(unique(long$period)))[, year := period + 2002L]
periods <- merge(periods, cov[, .(year = `fall soil temp year`, fall_soil_temp_c = `fall soil temperature (deg centigrade)`)], by = "year", all.x = TRUE)
periods <- merge(periods, cov[, .(year = `SWE year`, swe = `SWE value at 7day min winter temperature`)], by = "year", all.x = TRUE)
setcolorder(periods, "period")
taxa <- make_taxa("ANABOR", "Anaxyrus boreas", vernacularName = "Boreal toad (western toad)")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Capture histories of 3,509 boreal toads on breeding-season survey dates at ten sites near Blackrock, Wyoming, 2003-2019, with Bd status",
  creator = "Muths, Erin",
  pubDate = "2020", doi = "10.5066/P9VACHX0", sourceURL = "https://doi.org/10.5066/P9VACHX0",
  citation = "Muths, E., 2020, Capture-recapture, disease and covariate data for boreal toads from Blackrock Wyoming 2019: U.S. Geological Survey data release, https://doi.org/10.5066/P9VACHX0.",
  paperDOI = "10.1655/0018-0831-76.2.132",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Boreal toads were captured, marked and released on breeding-season survey dates at sites along the Buffalo Fork River near Blackrock, Wyoming, from 2003 to 2019 to study how fall soil temperature, snowpack and a second anuran host affect survival under chytrid (Bd) infection; Bd test results are given per capture.",
  samplingProtocol = "Breeding-season capture surveys at each site on several dates a year; toads individually marked, sexed and released; many captures swabbed for Batrachochytrium dendrobatidis.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "Robust design as in the paper: period = year, occasion = survey date (column) within the breeding season; occasion k is a column of the deposit, not one date at every site. Ids are valid across the study.",
  geographicCoverage = list(description = "Buffalo Fork River near Blackrock, Teton County, Wyoming, USA",
                            boundingBox = list(west = -110.4, east = -110.1, south = 43.8, north = 43.9)),
  temporalCoverage = "2003-05/2019-06",
  notShipped = list(never_seen = "13 toads with no 1 in any surveyed cell (catalogue entries; E4.4)", empty_cells = "2 empty cells ('No Data')", after_nonrelease = sprintf("%d surveyed cells after a toad was not released", n_after_nr),
                    bd_code_T = "130 captures with Bd code T (undefined in the metadata); 6 Bd test results on dates the toad is recorded as not seen", egg_masses = "Columbia spotted frog egg-mass counts per site-year (a paper covariate)"),
  notes = "obs_bd on captures only: 0 tested negative, 2 tested positive, 1 not tested (as deposited; NA before 2006 and where the code is T). __periods carries fall soil temperature (C) and snow water equivalent of the preceding winter, 2012-2018.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/muths_2020_blackrock_toad_rd.R")
stage_dict_row(TABLE,
  description = "Capture histories of 3,509 boreal toads on breeding-season survey dates at sites near Blackrock, Wyoming, 2003-2019 (robust design), with per-capture Bd test results and yearly soil temperature and snowpack.",
  url = "https://doi.org/10.5066/P9VACHX0",
  reference = "Muths, E. (2020). Capture-recapture, disease and covariate data for boreal toads from Blackrock Wyoming 2019. U.S. Geological Survey data release.",
  doi_paper = "10.1655/0018-0831-76.2.132", doi_data = "10.5066/P9VACHX0", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Robust design from the deposited 1/0/- matrix; Bd status as obs_bd.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Robust design", sampling_protocol = "visual_encounter",
  design = "Multi-season (16 years, survey dates within years)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Chytrid (Bd) infection status per capture.")
