#!/usr/bin/env Rscript
# Tables: schaub_2005_egermany_stork_ld, mccrea_2010_kattegat_cormorant_ms
# Source: the example datasets of the R package IPMbook (Schaub, Kéry, Meredith), version 0.1.5
#         (CRAN, published 2023-08-21), licence GPL (>= 3) as shown on the CRAN page and in the
#         package DESCRIPTION (asserted below); the data carry no licence of their own.
#         https://CRAN.R-project.org/package=IPMbook. The package is not loaded: the pinned
#         source tarball is downloaded and data/<name>.rda loaded directly (as in
#         data/ipmbook_package_cjs.R). The book's chapter code (github.com/mikemeredith/IPM_code,
#         IPM_04.5.4.R and IPM_18.all_tr.R) was read for how the authors use the data: neither
#         fixes a recapture probability at 0, so every year is a survey.
# Data (help pages data_stork.Rd, data_cormorant.Rd, read in full):
#   stork: white storks in eastern Germany, 1986-2001 (Vogelwarte Hiddensee): a 691 x 16 matrix,
#     1 = ringing or resighting in that year, 2 = dead recovery (19 birds), 0 otherwise. Chicks
#     were ringed and adults resighted when they raised a brood in the study area. The data
#     set includes only birds resighted at least once when older than two years (help page):
#     survival to that age is built into the selection. Every history starts with a 1
#     (asserted), no 1 or 2 follows a 2 (asserted). Schaub, Kania & Köppen (2005), Journal of
#     Animal Ecology 74, 656-666, doi:10.1111/j.1365-2656.2005.00961.x; IPM book 4.5.4.
#   cormorant: great cormorants of three breeding colonies in the south-western Kattegat,
#     Denmark (Vorsø V, Mågeøerne M, Stavns Fjord S), 1991-2004. ms.ch, 12,659 birds x 14
#     years: 0 not seen, 1-3 nestling ringed at V, M, S, 4-6 resighted as a breeder at V, M, S
#     (resightings restricted to breeders, from towers, hides or the ground with a telescope).
#     12,659 nestlings were ringed in all; 1,031 birds first appear as breeders, having been
#     ringed as nestlings before 1991. Also annual counts of occupied nests per colony (not
#     shipped). Data of Thomas Bregnballe. McCrea et al. (2010), JABES 15, 539-561,
#     doi:10.1007/s13253-010-0027-5; Borysiewicz et al. (2009), doi:10.1007/978-0-387-78151-8_25;
#     IPM book chapter 18.
# Mapping:
#   stork (dead recovery, Burnham live-dead, as moe_2020_hunder_trout_ld; responseType state,
#   unitKind individual): unit = row number, period = year (1986 = 1), y = 0 none, 1 alive
#   (ringed or resighted), 2 recovered dead in that calendar year; y_raw = the live-dead pair
#   (00, 10, 01). Every bird was ringed as a chick (help page), so it is at risk from its
#   ringing year (E4.4), to its recovery year or 2001. The source codes a recovery by calendar
#   year only, so the Burnham interval is the year itself (stated in notes).
#   cormorant (multistate CMR; responseType state): unit = row number, period = year (1991 =
#   1), y = the deposited state code 0-6 (stateCodes). At-risk span: a bird first recorded as
#   a nestling (codes 1-3) from that year; one first recorded as a breeder (4-6), ringed
#   before 1991, from 1991 (E4.4). unit_first_state = its first code.
#   Survey evidence = inferred for both: no effort is deposited; ringing and resighting took
#   place every year (help pages) and the book's code estimates a recapture probability for
#   every year (cormorant: every colony-year), fixing none at 0. Some cormorant colony-years
#   have no breeder resighting at all (counted in __periods); they are kept as surveyed, as
#   in the book.
#   No coordinates in the package.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/ipmbook_package_ms.R"
VER <- "0.1.5"
TARBALL <- sprintf("IPMbook_%s.tar.gz", VER)
CRAN_PAGE <- "https://cran.r-project.org/package=IPMbook"
PKG_CITE <- sprintf("Schaub, M., Kéry, M., & Meredith, M. (2023). IPMbook: Functions and data for the book 'Integrated Population Models' (Version %s) [R package; dataset %%s]. CRAN. https://CRAN.R-project.org/package=IPMbook", VER)
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
common <- list(sourceURL = CRAN_PAGE, intellectualRights = GPL, responseType = "state", unitKind = "individual",
               closure = "none", occasionKind = "none", taxonInclusion = "single", surveyEvidence = "inferred",
               coordinatesCoarsened = NA)
dict_common <- list(url = CRAN_PAGE, original_license = "GPL (>= 3) (IPMbook R package; the data have no licence of their own)",
                    derived_license = "GPL-3.0-or-later", source_via = sprintf("CRAN source tarball IPMbook %s (data/*.rda)", VER))

# =========================================================================================
# 1. White storks, eastern Germany, 1986-2001 (live resightings and dead recoveries)
# =========================================================================================
TABLE <- "schaub_2005_egermany_stork_ld"
st <- ipm_data(TABLE, "stork")
years <- 1986:2001
stopifnot(is.matrix(st), identical(dim(st), c(691L, 16L)), identical(colnames(st), as.character(years)),
          all(st %in% 0:2), sum(st == 2) == 19L, all(rowSums(st == 2) <= 1))
f <- apply(st, 1, function(r) which(r > 0)[1])
rec <- apply(st, 1, function(r) if (any(r == 2)) which(r == 2) else NA_integer_)
stopifnot(all(st[cbind(seq_len(nrow(st)), f)] == 1L),                         # every history starts with ringing
          all(is.na(rec) | rec > f),
          all(sapply(which(!is.na(rec)), function(i) all(st[i, seq_len(16) > rec[i]] == 0L))))
long <- rbindlist(lapply(seq_len(nrow(st)), function(i) {
  last <- if (is.na(rec[i])) 16L else rec[i]
  t <- f[i]:last
  data.table(unit = sprintf("%03d", i), period = t, y = as.integer(st[i, t]), unit_ring_year = years[f[i]])
}))
long[, y_raw := c("00", "10", "01")[y + 1L]]
stopifnot(sum(long$y == 1L) == sum(st == 1L), sum(long$y == 2L) == 19L)
long <- order_eco(long[, .(unit, taxon = "CICCIC", y, y_raw, period, unit_ring_year)])
periods <- data.table(period = 1:16, year = years, n_ringed = tabulate(f, 16),
                      n_resighted = colSums(st == 1) - tabulate(f, 16), n_recovered = colSums(st == 2))
taxa <- make_taxa("CICCIC", "Ciconia ciconia", vernacularName = "White stork", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Ringing, breeding resightings and dead recoveries of 691 white storks in eastern Germany, 1986-2001",
  creator = "Vogelwarte Hiddensee (data); Schaub, Michael; Kania, Wojciech; Köppen, Ulrich (distributed in the IPMbook R package)",
  pubDate = "2005", citation = sprintf(PKG_CITE, "stork"), paperDOI = "10.1111/j.1365-2656.2005.00961.x",
  abstract = "White storks (Ciconia ciconia) ringed as chicks in eastern Germany and resighted as breeding adults in the study area, 1986-2001, from the Vogelwarte Hiddensee ringing scheme; 19 were recovered dead. The package keeps only birds resighted at least once when older than two years. The data are the IPMbook package's stork (IPM book section 4.5.4, a joint live-resighting and dead-recovery model; Schaub et al. 2005): one row per stork x year at risk, y = 0 not encountered, 1 ringed or resighted alive, 2 recovered dead.",
  samplingProtocol = "Chicks ringed in the nest; ringed adults read when breeding in the study area each year; dead ringed storks reported to the ringing centre.",
  samplingProtocolCode = "resighting",
  surveyEvidenceNote = "No effort is deposited. Ringing and resighting of breeders took place every year 1986-2001 and dead recoveries are reported continuously (help page); the book's code estimates a resighting probability for every year and fixes none at 0. Every year is a live occasion and a recovery interval.",
  closureNote = "open between years (Burnham live-dead: one live occasion per breeding season, dead recoveries by calendar year)",
  stateCodes = list(`0` = "not encountered in year t (live 0, dead 0)", `1` = "ringed as a chick or resighted alive in year t (live 1, dead 0)", `2` = "recovered dead in calendar year t (live 0, dead 1)"),
  respRawCodes = list(`00` = "neither", `10` = "ringed or resighted alive", `01` = "recovered dead"),
  geographicCoverage = "Eastern Germany (study area of the Vogelwarte Hiddensee ringing scheme; no coordinates in the package)",
  temporalCoverage = "1986/2001",
  designNote = "Live-dead (Burnham) capture-recapture with dead recoveries, as moe_2020_hunder_trout_ld. Each stork has rows from its ringing year (all ringed as chicks) to its recovery year or 2001; no rows after a recovery.",
  notes = "Selection: the package includes only storks resighted at least once when older than two years (help page), so every bird survived its first two years; survival estimates from these data are conditional on that. Recoveries are coded by calendar year; whether a recovery precedes or follows that year's breeding season is not given, so state 2 does not order the two within a year. No bird is both resighted and recovered in one year. unit_ring_year = the year of ringing. Unit ids are row numbers of the package's matrix.",
  notShipped = list(none = "nothing: the matrix is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Live-dead histories of 691 white storks ringed as chicks in eastern Germany, 1986-2001: ringing, resightings as breeders and 19 dead recoveries; only birds resighted after age two are included (IPMbook::stork; Vogelwarte Hiddensee).",
  reference = "Schaub, M., Kania, W., & Köppen, U. (2005). Variation of primary production during winter induces synchrony in survival rates in migratory white storks Ciconia ciconia. Journal of Animal Ecology, 74, 656-666.",
  doi_paper = "10.1111/j.1365-2656.2005.00961.x", doi_data = "",
  notes = "IPMbook package data (GPL). Live-dead state table; sample selected on resighting after age two."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Live-dead capture-recapture (dead recoveries)",
  sampling_protocol = "resighting", design = "Multi-season (16 annual occasions)", realm = "Terrestrial",
  country = "DEU", coordinates = "None in source", notes = "From the IPMbook R package (IPM 4.5.4). Selection on resighting after age 2.")

# =========================================================================================
# 2. Great cormorants, three Kattegat colonies, 1991-2004 (multistate)
# =========================================================================================
TABLE <- "mccrea_2010_kattegat_cormorant_ms"
co <- ipm_data(TABLE, "cormorant")
ch <- co$ms.ch; years <- 1991:2004
stopifnot(identical(dim(ch), c(12659L, 14L)), all(ch %in% 0:6),
          identical(as.vector(table(factor(ch, levels = 0:6))), c(160524L, 4506L, 3463L, 3659L, 3212L, 994L, 868L)),
          identical(rownames(co$count), c("V", "M", "S")))
f <- apply(ch, 1, function(r) which(r > 0)[1])
first <- ch[cbind(seq_len(nrow(ch)), f)]
stopifnot(!anyNA(f), identical(as.vector(table(first)), c(4506L, 3463L, 3659L, 883L, 114L, 34L)),
          all(ch[cbind(seq_len(nrow(ch)), f)][first %in% 1:3] %in% 1:3),
          sum(ch %in% 1:3) == sum(first %in% 1:3))                               # a nestling code only at ringing
start <- ifelse(first %in% 1:3, f, 1L)
long <- rbindlist(lapply(seq_len(nrow(ch)), function(i) {
  t <- start[i]:14L
  data.table(unit = sprintf("%05d", i), period = t, y = as.integer(ch[i, t]), unit_first_state = first[i])
}))
stopifnot(sum(long$y > 0) == sum(ch > 0))
long <- order_eco(long[, .(unit, taxon = "PHACAR", y, period, unit_first_state)])
cnt <- function(k) colSums(ch == k)
periods <- data.table(period = 1:14, year = years,
                      ringed_V = cnt(1), ringed_M = cnt(2), ringed_S = cnt(3),
                      breeders_seen_V = cnt(4), breeders_seen_M = cnt(5), breeders_seen_S = cnt(6))
no_resight <- periods[, sum(breeders_seen_V == 0) + sum(breeders_seen_M == 0) + sum(breeders_seen_S == 0)]
cat(sprintf("  cormorant: %d colony-years with no breeder resighting\n", no_resight))
stopifnot(no_resight == 6L)
taxa <- make_taxa("PHACAR", "Phalacrocorax carbo", vernacularName = "Great cormorant", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Multistate ringing and breeder resighting histories of 12,659 great cormorants at three Danish colonies, 1991-2004",
  creator = "Bregnballe, Thomas (data); McCrea, Rachel S.; Morgan, Byron J. T.; Gimenez, Olivier; and colleagues (distributed in the IPMbook R package)",
  pubDate = "2010", citation = sprintf(PKG_CITE, "cormorant"), paperDOI = "10.1007/s13253-010-0027-5",
  abstract = "Great cormorant (Phalacrocorax carbo) nestlings were ringed with metal and coloured alphanumeric rings at three breeding colonies in the south-western Kattegat, Denmark (Vorsø, Mågeøerne, Stavns Fjord), and ringed birds were resighted as breeders at the colonies from towers, hides or the ground, 1991-2004. The data are the IPMbook package's cormorant multistate histories (IPM book chapter 18; McCrea et al. 2010): state 1-3 ringed as a nestling at colony V, M or S, 4-6 seen breeding at V, M or S, 0 not seen. Annual nest counts per colony are not shipped.",
  samplingProtocol = "Nestlings ringed (metal and coloured alphanumeric ring); breeding adults read by telescope at all three colonies each season.",
  samplingProtocolCode = "resighting",
  surveyEvidenceNote = "No effort is deposited. Ringing and resighting took place every year (help page); the book's code estimates a resighting probability for every colony and year and fixes none at 0, so every year is a survey of every colony. Six colony-years have no breeder resighting at all (breeders_seen_* = 0 in __periods); they are kept as surveyed, as in the book, though they may be years without effort at that colony.",
  closureNote = "open between years (multistate CMR, one occasion per breeding season)",
  stateCodes = list(`0` = "not seen", `1` = "ringed as a nestling at Vorsø (V)", `2` = "ringed as a nestling at Mågeøerne (M)",
                    `3` = "ringed as a nestling at Stavns Fjord (S)", `4` = "seen breeding at Vorsø (V)",
                    `5` = "seen breeding at Mågeøerne (M)", `6` = "seen breeding at Stavns Fjord (S)"),
  geographicCoverage = "Three breeding colonies in the south-western Kattegat, Denmark: Vorsø, Mågeøerne, Stavns Fjord (no coordinates in the package)",
  temporalCoverage = "1991/2004",
  designNote = "Multistate capture-recapture with states = age class x colony. Birds first recorded as nestlings have rows from their ringing year; birds first recorded as breeders were ringed as nestlings before 1991 and have rows from 1991 (E4.4).",
  notes = "unit_first_state is the bird's first recorded code (1-3: ringed in the study; 4-6: ringed before 1991, first seen breeding). Nestling codes occur only at ringing (asserted). Phalacrocorax carbo sinensis is the subspecies breeding in Denmark; the taxon is resolved at species rank. __periods gives per year the nestlings ringed and breeders seen at each colony. Unit ids are row numbers of the package's matrix.",
  notShipped = list(count = "annual counts of occupied nests per colony: aggregates without unit-level data (E9)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Multistate histories of 12,659 great cormorants ringed as nestlings and resighted as breeders at three colonies in the south-western Kattegat, Denmark, 1991-2004 (IPMbook::cormorant; data of T. Bregnballe).",
  reference = "McCrea, R. S., Morgan, B. J. T., Gimenez, O., Besbeas, P., Bregnballe, T., Hénaux, V., & Lebreton, J. D. (2010). Multi-site integrated population modelling. Journal of Agricultural, Biological and Environmental Statistics, 15, 539-561.",
  doi_paper = "10.1007/s13253-010-0027-5", doi_data = "",
  notes = "IPMbook package data (GPL). Multistate (age class x colony). Six colony-years with no breeder resighting kept as surveyed."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multistate capture-recapture",
  sampling_protocol = "resighting", design = "Multi-season (14 annual occasions, 3 colonies)", realm = "Marine",
  country = "DNK", coordinates = "None in source", notes = "From the IPMbook R package (IPM 18).")
