#!/usr/bin/env Rscript
# Table:  chabanne_2017_perth_dolphin_msrd
# Source: Dryad doi:10.5061/dryad.24s3c, version 18507 (2017-04-06), CC0 1.0 as shown on
#         the Dryad page. "Data from: Applying the multistate capture-recapture robust
#         design to characterize metapopulation structure." Chabanne, D.
# Paper:  Chabanne, D.B.H., Pollock, K.H., Finn, H., Bejder, L. & Gimenez, O. (2017).
#         Applying the multistate capture-recapture robust design to characterize
#         metapopulation structure. Methods in Ecology and Evolution 8(11), 1547-1557,
#         doi:10.1111/2041-210X.12792. Design details that the paper puts in its
#         supplement (Table S3, S7) were read from the author's open-access PhD thesis,
#         Chabanne (2017), Murdoch University, chapter 2, Appendix A2.1 and A2.7.
# Data:   Mark_files.zip with two Program MARK input files (one line per individual,
#         /*<id>*/ <75-character history> 1;) and a 2-line README.
#           Mark_file_3States.txt: 209 lines, codes 0 = not captured, 1 = captured in the
#             Swan Canning Riverpark (SCR, estuary), 2 = Cockburn Sound / Owen Anchorage
#             (CS/OA, embayment), 3 = Gage Roads (GR, open coast). The paper's Scenario 1.
#           Mark_file_2States.txt: 209 lines, codes 0 / A (SCR) / B (coastal = CS/OA + GR).
#             The paper's Scenario 2. NOT a deterministic collapse of the 3-state file:
#             207 labels are shared (208 after the relabelling below), 25 histories differ (the within-primary-period "first
#             site" rule was applied after pooling, so captures the 3-state file dropped
#             as site conflicts survive here) and the id sets differ by one label each way.
#         Design (paper + thesis Table A2.1.1): boat-based photo-identification, June 2011
#         to May 2015; 16 primary periods = Australasian seasons (winter Jun-Aug, spring
#         Sep-Nov, summer Dec-Feb, autumn Mar-May); secondary occasions = complete surveys
#         of all three sites on consecutive days, 6,5,5,5, 5,5,5,5, 5,4,4,4, 5,3,5,5 per
#         season = 76 completed. The MARK file has 75 columns and no column labels, so
#         one secondary occasion is absent from it. Which one is inferred below and
#         asserted: with summer 2011-12 at 4 occasions (all other seasons as in the
#         thesis) no individual has two different sites within a primary period, which is
#         exactly the authors' data rule, and the per-season individuals per site match
#         the thesis Table A2.7.1 best (summer 2011-12: 6 / 30 / 0 marked individuals,
#         GR had no groups that season). Layouts dropping an occasion from spring 2011,
#         autumn 2012 or winter 2012 also give zero within-period conflicts but do not
#         reproduce the summer counts; the rest give conflicts. Recorded in the metadata.
#         Individuals: 209 distinctly marked (D1/D2) non-calf dolphins = the thesis total
#         "(209)". The 3-state file lists "UNK201313" twice; the second line equals the
#         2-state file's UNK201314 exactly, so it is relabelled UNK201314 (label typo).
#         UNK201203 (3-state) equals the 2-state UNK201204; the deposited 3-state label is
#         kept. Frequency is 1 on every line (no losses on capture).
#
# Mapping (standard E9 core: multi-state capture-recapture, robust design; the first
#   table in the corpus with both `period` and `occasion` on individual units):
#   unit = dolphin id, taxon = TURADU, period = season 1..16 (__periods: season, year,
#   months, n_occasions in the file and completed per the thesis, survey hours and
#   distance, mean days within and between secondary occasions), occasion = secondary
#   occasion within the season, responseType = state, y = 0/1/2/3 (0 not captured,
#   1 SCR, 2 CS/OA, 3 GR) with stateCodes; no y_raw (the file code is the state code). Rows: the
#   full rectangle 209 x 75 (every individual at every secondary occasion, 0 where not
#   captured), the convention of the CJS and SCR tables. surveyEvidence = deposited_matrix.
#   No coordinates, no covariates (sex is not in the deposit; the paper withholds the
#   sex analysis). Not shipped: the 2-state file (a second processing of the same
#   sightings under Scenario 2; derivable only approximately from this table).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "chabanne_2017_perth_dolphin_msrd"
dir <- download_dryad("10.5061/dryad.24s3c", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(setdiff(list.files(dir), "mark"), c("Mark_files.zip", "README_for_Mark_files.txt")))
mark <- file.path(dir, "mark")
if (!dir.exists(mark)) unzip(file.path(dir, "Mark_files.zip"), exdir = mark)
stopifnot(setequal(list.files(mark), c("Mark_file_2States.txt", "Mark_file_3States.txt")))

read_inp <- function(f, codes) {
  l <- trimws(readLines(f, warn = FALSE)); l <- l[nzchar(l)]
  stopifnot(grepl("^/\\*CEDP_[23]states\\*/$", l[1]))
  m <- regmatches(l[-1], regexec(sprintf("^/\\*([A-Z0-9]+)\\*/([%s]{75}) (1);$", codes), l[-1]))
  stopifnot(all(lengths(m) == 4))
  data.table(unit = sapply(m, `[`, 2), ch = sapply(m, `[`, 3), freq = as.integer(sapply(m, `[`, 4)))
}
inp3 <- read_inp(file.path(mark, "Mark_file_3States.txt"), "0-3")
inp2 <- read_inp(file.path(mark, "Mark_file_2States.txt"), "0AB")
stopifnot(nrow(inp3) == 209, nrow(inp2) == 209, all(inp3$freq == 1L), all(inp2$freq == 1L))

# the duplicated label: second UNK201313 line is the 2-state file's UNK201314
dup <- which(inp3$unit == "UNK201313"); stopifnot(length(dup) == 2, !anyDuplicated(inp2$unit))
collapse <- function(ch) chartr("123", "ABB", ch)
stopifnot(identical(collapse(inp3$ch[dup[1]]), inp2[unit == "UNK201313", ch]),
          identical(collapse(inp3$ch[dup[2]]), inp2[unit == "UNK201314", ch]),
          !"UNK201314" %in% inp3$unit)
inp3[dup[2], unit := "UNK201314"]
stopifnot(!anyDuplicated(inp3$unit))
# the two files are two processings of the same sightings, not a deterministic collapse
stopifnot(identical(setdiff(inp3$unit, inp2$unit), "UNK201203"), identical(setdiff(inp2$unit, inp3$unit), "UNK201204"),
          identical(collapse(inp3[unit == "UNK201203", ch]), inp2[unit == "UNK201204", ch]))
shared <- merge(inp3[, .(unit, ch3 = collapse(ch))], inp2[, .(unit, ch2 = ch)], by = "unit")
stopifnot(nrow(shared) == 208, sum(shared$ch3 != shared$ch2) == 25)   # 207 shared labels plus the relabelled UNK201314

CH <- do.call(rbind, strsplit(inp3$ch, "")); dimnames(CH) <- list(inp3$unit, NULL)
stopifnot(dim(CH) == c(209, 75), all(CH %in% c("0", "1", "2", "3")), all(rowSums(CH != "0") > 0),
          sum(CH != "0") == 1432)

# primary periods: 16 seasons; secondary occasions per season per the thesis (76), with the
# summer 2011-12 column missing from the file (75). Inference asserted two ways.
seasons <- CJ(year = 2011:2015, season = c("autumn", "winter", "spring", "summer"), sorted = FALSE)[2:17]   # winter 2011 .. autumn 2015; year = calendar year the season starts in
stopifnot(seasons$season[1] == "winter", seasons$year[1] == 2011, seasons$season[16] == "autumn", seasons$year[16] == 2015)
seasons[, period := 1:16]
seasons[, n_occasions_completed := c(6, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 5, 3, 5, 5)]   # thesis Table A2.1.1
seasons[, n_occasions := n_occasions_completed - (period == 3L)]
stopifnot(sum(seasons$n_occasions_completed) == 76, sum(seasons$n_occasions) == 75)
period <- rep(seasons$period, seasons$n_occasions)
n_conflict <- function(per) {                      # individuals with two sites within one primary period
  sum(sapply(split(seq_len(75), per), function(j) sum(apply(CH[, j, drop = FALSE], 1, function(r) length(setdiff(unique(r), "0")) > 1))))
}
stopifnot(n_conflict(period) == 0)                 # the authors' "first site in the period" rule holds under this layout
alt <- rep(seasons$period, seasons$n_occasions_completed - (seasons$period == 4L))   # the nearest rival layout
stopifnot(n_conflict(alt) == 0)                    # ... also conflict-free, so the second test decides:
per_site <- function(per) t(sapply(split(seq_len(75), per), function(j) sapply(c("1", "2", "3"), function(s) sum(rowSums(CH[, j, drop = FALSE] == s) > 0))))
stopifnot(all(per_site(period)[3, ] == c(6, 30, 0)), per_site(alt)[3, 3] > 0)   # thesis Table A2.7.1 summer 2011-12: 6 (SCR), 30 (CS/OA), 0 (GR)
stopifnot(all(per_site(period)[, 1] <= c(10, 13, 6, 16, 14, 10, 14, 10, 12, 5, 6, 10, 15, 11, 14, 14)))   # never more SCR individuals than the thesis counts

Y <- CH; storage.mode(Y) <- "integer"
long <- array_to_eco(Y, taxon = "TURADU", site_ids = inp3$unit, period = period)   # no y_raw: the file code is the state code
stopifnot(nrow(long) == 209 * 75, all(long$y %in% 0:3),
          uniqueN(long$unit) == 209, max(long$period) == 16, max(long$occasion) == 6)
cat(sprintf("  %d individuals x %d secondary occasions in %d seasons; %d captures (SCR %d, CS/OA %d, GR %d)\n",
            209, 75, 16, sum(long$y > 0), sum(long$y == 1), sum(long$y == 2), sum(long$y == 3)))

taxa <- make_taxa("TURADU", "Tursiops aduncus", vernacularName = "Indo-Pacific bottlenose dolphin")
month_lab <- c(winter = "06/08", spring = "09/11", summer = "12/02", autumn = "03/05")
periods <- seasons[, .(period, season, year_start = year, year_end = year + (season == "summer"),
                       months = month_lab[season], n_occasions, n_occasions_completed,
                       survey_hours = c(53.1, 42.6, 43.9, 40.8, 40.5, 43.2, 43.9, 39.2, 42.1, 31.3, 32.8, 36.0, 45.3, 26.3, 44.5, 45.3),
                       survey_km = c(NA, 663, 672, 662, 670, 669, 675, 663, 678, 534, 531, 547, 676, 417, 683, 686),
                       mean_days_in_occasion = c(2.17, 3.20, 2.20, 2.00, 2.20, 3.00, 3.00, 2.00, 2.00, 2.00, 3.75, 2.00, 2.00, 4.67, 2.40, 3.00),
                       mean_days_between_occasions = c(11.20, 14.50, 13.25, 17.50, 4.25, 7.25, 3.75, 4.25, 9.50, 7.33, 7.67, 8.67, 9.00, 8.50, 6.75, 3.50),
                       days_since_previous_season = c(NA, 12, 27, 16, 32, 80, 58, 45, 59, 41, 77, 38, 63, 57, 52, 53))]
stopifnot(periods[period == 3, season == "summer" & year_start == 2011 & year_end == 2012 & n_occasions == 4])

dataset <- list(
  title = "Multi-state robust-design capture histories of 209 Indo-Pacific bottlenose dolphins across three sites in Perth metropolitan waters, 2011-2015",
  creator = "Chabanne, Delphine B.H.", pubDate = "2017", doi = "10.5061/dryad.24s3c",
  sourceURL = "https://doi.org/10.5061/dryad.24s3c",
  citation = "Chabanne, D. (2017). Data from: Applying the multistate capture-recapture robust design to characterize metapopulation structure [Dataset]. Dryad. https://doi.org/10.5061/dryad.24s3c",
  paperDOI = "10.1111/2041-210X.12792",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Photo-identification capture histories of distinctly marked, non-calf Indo-Pacific bottlenose dolphins (Tursiops aduncus) from boat-based surveys of three sites in Perth metropolitan waters, Western Australia (the Swan Canning Riverpark estuary, Cockburn Sound / Owen Anchorage, and Gage Roads), June 2011 to May 2015. Sixteen seasonal primary periods each hold three to six secondary occasions (complete surveys of all sites on consecutive days). y is the site of capture (0 = not captured); an individual captured at two sites within a season was assigned by the authors to the site of its first capture that season. The Program MARK input for the paper's Scenario 1 (three sites).",
  samplingProtocol = "Boat-based photo-identification along pre-defined transects covering three sites; a secondary occasion is the set of surveys covering all sites (2-8 days); first capture per secondary occasion retained; distinctive fins (D1, D2) only; calves excluded.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The MARK file has 75 unlabelled columns; the thesis effort table lists 76 completed secondary occasions (6,5,5,5,5,5,5,5,5,4,4,4,5,3,5,5 per season). Columns are assigned to seasons with summer 2011-12 at 4 occasions, the only layout that both leaves no individual at two sites within a season (the authors' data rule) and reproduces the thesis's per-site individual counts for that season (6, 30, 0). Period assignment for columns 12-26 is therefore inferred, not deposited.",
  responseType = "state", unitKind = "individual",
  closure = "occasion within period (robust design: sites closed within a season, open between seasons)",
  stateCodes = list(`0` = "not captured", `1` = "captured in the Swan Canning Riverpark (SCR, estuary)",
                    `2` = "captured in Cockburn Sound / Owen Anchorage (CS/OA, semi-enclosed embayment)",
                    `3` = "captured in Gage Roads (GR, open coast)"),
  geographicCoverage = "Perth metropolitan waters, Western Australia: 45 km of coast plus the Swan Canning Riverpark estuary, c. 275 km2 (no coordinates deposited)",
  temporalCoverage = "2011-06/2015-05",
  notes = "__periods effort columns (survey hours, km, mean days within and between secondary occasions, days since the previous season) are from Chabanne (2017) PhD thesis Table A2.1.1; n_occasions is the count in the MARK file, n_occasions_completed the thesis count. Individual ids are the authors' three-letter or UNKyyyynn codes. Line 2 of 2 labelled UNK201313 in the deposit is relabelled UNK201314 (identical to that id in the 2-state file). No sex or other individual covariates are deposited.",
  notShipped = list(Mark_file_2States.txt = "the paper's Scenario 2 (SCR vs pooled coastal) histories: a separate processing of the same sightings (208 shared ids, 25 histories differ because the within-season single-site rule was applied after pooling), not a deterministic collapse of this table; a user wanting Scenario 2 should pool states 2 and 3 here and accept the small difference"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/chabanne_2017_perth_dolphin_msrd.R")

stage_dict_row(TABLE,
  description = "Multi-state closed robust design capture histories of 209 photo-identified Indo-Pacific bottlenose dolphins (Tursiops aduncus) at three sites in Perth metropolitan waters, Western Australia: 16 seasonal primary periods (June 2011 to May 2015) x 3-6 secondary occasions; y is the site of capture (0 not captured, 1 estuary, 2 embayment, 3 open coast). The Program MARK input for Chabanne et al. (2017) Scenario 1.",
  url = "https://doi.org/10.5061/dryad.24s3c",
  reference = "Chabanne, D.B.H., Pollock, K.H., Finn, H., Bejder, L. & Gimenez, O. (2017). Applying the multistate capture-recapture robust design to characterize metapopulation structure. Methods in Ecology and Evolution, 8(11), 1547-1557.",
  doi_paper = "10.1111/2041-210X.12792", doi_data = "10.5061/dryad.24s3c",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Season layout of the 75 unlabelled MARK columns inferred against the thesis effort table (76 completed occasions); summer 2011-12 carries 4 columns. 2-state (Scenario 2) file not shipped. One duplicated id relabelled.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state closed robust design capture-recapture",
  sampling_protocol = "photo_id", design = "Robust design (16 seasonal primary periods x 3-6 secondary occasions)",
  realm = "Marine", country = "AUS", coordinates = "None in source",
  notes = "First robust-design and first multi-state capture-recapture table; y = site of capture, full 209 x 75 rectangle.")
