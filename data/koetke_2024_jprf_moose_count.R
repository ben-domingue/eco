#!/usr/bin/env Rscript
# Table:  koetke_2024_jprf_moose_count
# Source: Dryad doi:10.5061/dryad.w6m905qv3, "Data from: using camera traps and N-mixture models
#         to estimate population abundance: model selection really matters", Koetke, Johnson &
#         Hodder, version 4 published 2024-03-14, licence CC0 1.0 (as shown on Dryad).
# Paper:  Koetke, L. J., Hodder, D. P. & Johnson, C. J. (2024). Using camera traps and N-mixture
#         models to estimate population abundance: model selection really matters. Methods in
#         Ecology and Evolution 15(5), 900-915. https://doi.org/10.1111/2041-210X.14320.
#         Moose (Alces alces) in the John Prince Research Forest (JPRF), central interior British
#         Columbia, Canada, winter 2020-21; camera-trap counts compared with a stratified random
#         block (SRB) aerial survey.
# Data:   one xlsx, four sheets, plus README.md.
#         "moose at camera traps 5 min" / "30 min" / "8 hr": 72 cameras x 91 days (column names
#           are Excel serial dates 44180..44270 = 2020-12-15..2021-03-15); each cell is the number
#           of independent moose detections on that camera-day, with independence defined by the
#           sheet's gap between videos (5 min, 30 min, 8 h). The three sheets are one set of
#           observations under three independence criteria: identical NA pattern (617 of 6,552
#           cells, the README's "camera not active": dead battery or full card; gaps are not
#           contiguous), counts ordered 8 h <= 30 min <= 5 min in every cell, totals 170 / 158 /
#           145, maximum 6. 44 of 72 cameras ever detected a moose. Camera ids are "14_01".."14_42"
#           (42), "LC67".."LC74" (6) and "N01".."N25" (24).
#         "SRB data": the 2021 aerial survey, three strata x 5 sampled cells of 10, one count of
#           bulls, cows and calves per cell with cell areas. Not detection data (one pass, no
#           replication, the paper's reference abundance): not shipped.
#         No coordinates, no site or observation covariates, no camera deployment dates beyond
#         the NA pattern.
# Mapping (standard E1-E5; N-mixture family):
#   unit = camera id, taxon = ALCALC (Alces alces), occasion = day index 1..91 from 2020-12-15,
#   date = that calendar day (ISO), y = independent detections under the 5-minute criterion (the
#   finest deposited, closest to the raw video record); obs_detections_30min and
#   obs_detections_8hr carry the same camera-day under the two coarser criteria, so a user can
#   swap the response (they are deterministic re-codings of the same videos, not covariates in
#   the modelling sense; see covariateNote). Survey evidence: deposited_matrix; an NA cell is not
#   surveyed and has no row. 6,552 - 617 = 5,935 rows.
#   Not shipped: the SRB aerial survey sheet (reference abundance, not detection data).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "koetke_2024_jprf_moose_count"

dir <- download_dryad("10.5061/dryad.w6m905qv3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, pattern = "^Moose_abundance_data_for_archiving\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
stopifnot(identical(readxl::excel_sheets(f),
                    c("SRB data", "moose at camera traps 5 min", "moose at camera traps 30 min", "moose at camera traps 8 hr")))

read_mat <- function(sheet) {
  x <- as.data.frame(readxl::read_excel(f, sheet = sheet, col_types = "text"))
  stopifnot(names(x)[1] == "camera", !anyDuplicated(x$camera))
  m <- as.matrix(x[, -1]); stopifnot(all(m[!is.na(m)] %in% c(as.character(0:6), "NA")))   # literal "NA" strings in the sheet
  v <- suppressWarnings(as.integer(m)); dim(v) <- dim(m); dimnames(v) <- list(x$camera, names(x)[-1]); v
}
m5 <- read_mat("moose at camera traps 5 min")
m30 <- read_mat("moose at camera traps 30 min")
m8 <- read_mat("moose at camera traps 8 hr")

days <- as.Date(as.integer(colnames(m5)), origin = "1899-12-30")      # Excel serial dates
stopifnot(dim(m5) == c(72, 91), identical(dimnames(m30), dimnames(m5)), identical(dimnames(m8), dimnames(m5)),
          isTRUE(all.equal(as.numeric(days), as.numeric(seq(as.Date("2020-12-15"), as.Date("2021-03-15"), by = "day")))),
          identical(is.na(m5), is.na(m30)), identical(is.na(m5), is.na(m8)), sum(is.na(m5)) == 617,
          all(m8 <= m30, na.rm = TRUE), all(m30 <= m5, na.rm = TRUE),
          sum(m5, na.rm = TRUE) == 170, sum(m30, na.rm = TRUE) == 158, sum(m8, na.rm = TRUE) == 145,
          max(m5, na.rm = TRUE) == 6, sum(rowSums(m5, na.rm = TRUE) > 0) == 44, all(rowSums(!is.na(m5)) > 0),
          identical(as.integer(table(sub("_.*", "", rownames(m5)))[c("14", "N01")]), c(42L, 1L)),
          sum(grepl("^LC", rownames(m5))) == 6, sum(grepl("^N", rownames(m5))) == 24)
cat(sprintf("  %d cameras x %d days, %d camera-days surveyed, %d detections (5-min criterion) at %d cameras\n",
            nrow(m5), ncol(m5), sum(!is.na(m5)), sum(m5, na.rm = TRUE), sum(rowSums(m5, na.rm = TRUE) > 0)))

colnames(m5) <- colnames(m30) <- colnames(m8) <- seq_len(ncol(m5))
date_mat <- matrix(format(days), nrow(m5), ncol(m5), byrow = TRUE, dimnames = dimnames(m5))
long <- array_to_eco(m5, taxon = "ALCALC", site_ids = rownames(m5),
                     obs_covs = list(detections_30min = m30, detections_8hr = m8))
long <- merge(long, data.table(unit = rep(rownames(m5), ncol(m5)), occasion = rep(seq_len(ncol(m5)), each = nrow(m5)),
                                date = as.vector(date_mat)), by = c("unit", "occasion"))
long <- order_eco(long)
stopifnot(nrow(long) == 6552 - 617, uniqueN(long$unit) == 72, sum(long$y) == 170, !anyNA(long$y),
          !anyNA(long$obs_detections_30min), !anyNA(long$obs_detections_8hr), !anyNA(long$date),
          sum(long$obs_detections_30min) == 158, sum(long$obs_detections_8hr) == 145)

taxa <- make_taxa("ALCALC", "Alces alces", vernacularName = "Moose")
dataset <- list(
  title = "Moose camera-trap detection counts, 72 cameras x 91 winter days, John Prince Research Forest, BC (Koetke et al. 2024)",
  creator = "Koetke, Lisa J.; Johnson, Chris J.; Hodder, Dexter P.",
  pubDate = "2024", sourceURL = "https://doi.org/10.5061/dryad.w6m905qv3",
  citation = "Koetke, L. J., Hodder, D. P. & Johnson, C. J. (2024). Using camera traps and N-mixture models to estimate population abundance: model selection really matters. Methods in Ecology and Evolution 15(5), 900-915. https://doi.org/10.1111/2041-210X.14320. Data: Dryad https://doi.org/10.5061/dryad.w6m905qv3 (CC0 1.0).",
  paperDOI = "10.1111/2041-210X.14320", dataDOI = "10.5061/dryad.w6m905qv3",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily counts of independent moose detections at 72 camera traps in the John Prince Research Forest, central interior British Columbia, from 15 December 2020 to 15 March 2021 (91 days), the camera-trap data of Koetke et al. (2024), who compared N-mixture abundance estimates against a stratified random block aerial survey. A camera-day is surveyed if the camera was active (5,935 of 6,552); y is the count under the authors' 5-minute independence criterion, with the 30-minute and 8-hour recodings of the same videos carried alongside.",
  samplingProtocol = "Camera traps recording video; independent detections of moose per camera per day, with three independence criteria (gap of 5 min, 30 min or 8 h between videos) deposited as three matrices. Camera placement, model and settings are in the paper.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "occasion",
  geographicCoverage = "John Prince Research Forest, near Fort St. James, central interior British Columbia, Canada; no coordinates deposited",
  temporalCoverage = "2020-12-15/2021-03-15",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit"),
  covariateNote = "obs_detections_30min and obs_detections_8hr are the same camera-day's detections counted under the 30-minute and 8-hour independence criteria (deterministic recodings of the same videos; 8 h <= 30 min <= 5 min in every cell). They are alternative responses, not covariates: replace y with one of them to reproduce the paper's other criteria.",
  notes = "y uses the 5-minute criterion (the finest deposited). An NA cell in the deposit (camera not active: dead battery or full memory card) is a missing row; inactive days are scattered, not only at deployment ends. 44 of 72 cameras detected a moose. Camera id prefixes (14_, LC, N) are the deposit's; their meaning is in the paper.",
  notShipped = list(`SRB data` = "the 2021 stratified random block aerial survey (3 strata x 5 of 10 cells, one count of bulls, cows and calves per cell with areas): a single-pass reference abundance, not detection data"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/koetke_2024_jprf_moose_count.R")

stage_dict_row(TABLE,
  description = "Daily counts of independent moose detections at 72 camera traps over 91 winter days (Dec 2020-Mar 2021) in the John Prince Research Forest, British Columbia, under the 5-minute independence criterion, with the 30-minute and 8-hour recodings alongside (Koetke et al. 2024, N-mixture model-selection study).",
  url = "https://doi.org/10.5061/dryad.w6m905qv3",
  reference = "Koetke, L. J., Hodder, D. P. & Johnson, C. J. (2024). Using camera traps and N-mixture models to estimate population abundance: model selection really matters. Methods in Ecology and Evolution 15(5), 900-915.",
  doi_paper = "10.1111/2041-210X.14320", doi_data = "10.5061/dryad.w6m905qv3",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "72 cameras x 91 days, 617 inactive camera-days as missing rows; three independence criteria deposited, 5-min as y; no coordinates or covariates; aerial survey sheet not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture",
  sampling_protocol = "camera_trap", design = "Single-season (91 daily occasions, winter 2020-21)", realm = "Terrestrial", country = "CAN",
  coordinates = "None in source", notes = "Camera-trap N-mixture case study with three detection-independence criteria (Koetke et al. 2024).")
