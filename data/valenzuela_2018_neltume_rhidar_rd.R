#!/usr/bin/env Rscript
# Table:  valenzuela_2018_neltume_rhidar_rd
# Source: Zenodo 10.5281/zenodo.1327549 (published 2018-08-03), CC BY-SA 4.0 as shown on the
#         record. "Spatial capture-recapture data of Darwin's frogs captured between
#         2014-2017." Valenzuela-Sánchez, Andrés (ONG Ranita de Darwin). The derived table
#         is CC BY-SA 4.0 (the share-alike clause propagates).
# Paper:  The record names no article. It is the two-plot (HUI1, HUI2: Huilo Huilo, Neltume,
#         Los Ríos, Chile) search-encounter capture-recapture data of the Ranita de Darwin
#         programme; the same programme's related papers are Valenzuela-Sánchez et al. (2017)
#         Proc. R. Soc. B 284:20171176 (doi:10.1098/rspb.2017.1176, two Huilo Huilo
#         populations, Bd and survival) and Valenzuela-Sánchez et al. (2022) J. Anim. Ecol.
#         91:308-319 (doi:10.1111/1365-2656.13603, four populations). Which one these 16
#         primary periods served is not stated; the design below is the record's own
#         description, asserted against the files. A sibling record (zenodo.1185403, 48
#         columns, three populations, March 2014 to December 2016) describes the same
#         protocol: Pollock's robust design, primary periods three months apart, each of four
#         consecutive days of capture.
# Data:   Four tab-separated text files, no header, 311 rows (frogs) each.
#           x.txt, y.txt: 64 columns = 16 primary periods x 4 secondary occasions (columns
#             grouped by primary, secondary fastest). The cell is the capture location in
#             plot-local metres, NA when the frog was not captured. Seven primary periods
#             (2, 6, 10, 11, 13, 14, 15) are all-NA in every row: the plots were not visited
#             (the sibling record says so of its own gaps). In the nine visited primaries every
#             secondary has captures at both plots. 1,031 captures (1,028 with an x coordinate); every frog captured at
#             least once; at most one capture per frog x secondary. Six cells carry a
#             coordinate in one file and NA in the other (frogs 10 and 24 at primary 5
#             secondaries 3-4, frogs 3 and 27 at primary 7 secondary 3): treated as captures
#             with the missing coordinate NA.
#           svl.txt: snout-vent length (mm) written on all four secondaries of every primary in
#             which the frog was captured (constant within the primary in all but one
#             frog-primary), NA otherwise; absent for three captured frog-primaries (the
#             half-coordinate frogs 10 and 27, and G251b in primary 16). 12.5-37.5 mm.
#           id.txt: frog code (integers and codes like I275, G251b) and plot (1 = HUI1,
#             2 = HUI2); 192 and 119 frogs. A frog belongs to one plot.
#
# Mapping (standard E9 core: robust design capture-recapture on individuals; the spatial
#   half of a search-encounter SCR has no fixed detectors, so there is no `trap` key and the
#   capture coordinates ride as observation covariates):
#   unit = frog code, cluster_id = plot (HUI1 / HUI2), taxon = RHIDAR, period = primary
#   period index 1..16 as in the file (quarterly; the seven unvisited primaries have no
#   rows, so period takes the values 1,3,4,5,7,8,9,12,16 and the gaps are real time),
#   occasion = secondary occasion 1..4 (consecutive capture days), y = 1 captured / 0 not,
#   responseType = detection, full rectangle 311 x 36 (every frog at every visited
#   secondary; rows before first capture kept as 0). obs_x_m, obs_y_m = capture location in
#   plot-local metres (NA when not captured); obs_svl_mm = snout-vent length in the primary
#   of capture (NA when not captured). surveyEvidence = deposited_matrix: a column with any
#   capture is a surveyed secondary, an all-NA column an unvisited primary. No geographic
#   coordinates, dates or sex are deposited; the species is IUCN EN, and the plot-local
#   metres have no origin, so nothing is coarsened and nothing locates the plots.
#   Not shipped: nothing (the seven unvisited primaries contain no data).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "valenzuela_2018_neltume_rhidar_rd"
base <- "https://zenodo.org/records/1327549/files/%s?download=1"
f <- sapply(c("x.txt", "y.txt", "svl.txt", "id.txt"), function(n) download_cached(sprintf(base, n), TABLE, filename = n))
rd <- function(n) as.matrix(read.table(f[[n]], sep = "\t", na.strings = "NA", header = FALSE))
X <- rd("x.txt"); Y <- rd("y.txt"); S <- rd("svl.txt")
id <- read.table(f[["id.txt"]], sep = "\t", header = FALSE, colClasses = c("character", "integer"))
setnames(setDT(id), c("frog", "plot"))
stopifnot(dim(X) == c(311, 64), dim(Y) == c(311, 64), dim(S) == c(311, 64), nrow(id) == 311,
          !anyDuplicated(id$frog), all(id$plot %in% 1:2), identical(as.integer(table(id$plot)), c(192L, 119L)))

# captures: a coordinate in either file. Six half cells, asserted by position.
cap <- !is.na(X) | !is.na(Y)
half <- which(is.na(X) != is.na(Y), arr.ind = TRUE)
stopifnot(nrow(half) == 6, setequal(id$frog[half[, "row"]], c("10", "24", "3", "27")), all(half[, "col"] %in% c(19, 20, 27)))
stopifnot(sum(cap) == 1031, sum(!is.na(X)) == 1028, all(rowSums(cap) > 0))   # 1,028 cells with an x, 3 more with only a y
primary <- rep(1:16, each = 4); secondary <- rep(1:4, times = 16)
visited <- sort(unique(primary[colSums(cap) > 0]))
stopifnot(identical(visited, c(1L, 3L, 4L, 5L, 7L, 8L, 9L, 12L, 16L)),
          all(colSums(cap)[primary %in% visited] > 0),                       # every secondary of a visited primary has captures
          all(colSums(cap[id$plot == 1, ])[primary %in% visited] > 0),      # ... at both plots
          all(colSums(cap[id$plot == 2, ])[primary %in% visited] > 0))
# SVL: per primary of capture, constant within the primary (one exception), NA otherwise
svl_by_fp <- function(fun) t(sapply(seq_len(311), function(i) sapply(1:16, function(p) fun(S[i, primary == p], cap[i, primary == p]))))
has_svl <- svl_by_fp(function(s, c) any(!is.na(s))); has_cap <- svl_by_fp(function(s, c) any(c))
stopifnot(sum(has_svl & !has_cap) == 0, sum(has_cap & !has_svl) == 3, sum(has_cap) == 611,
          sum(svl_by_fp(function(s, c) length(unique(s[!is.na(s)])) > 1)) == 1,
          sum(is.na(S[cap])) == 4, abs(min(S, na.rm = TRUE) - 12.5) < 1e-6, abs(max(S, na.rm = TRUE) - 37.5) < 1e-6)
cat(sprintf("  %d frogs (%d HUI1, %d HUI2) x %d secondary occasions in %d visited primary periods; %d captures\n",
            311, sum(id$plot == 1), sum(id$plot == 2), sum(primary %in% visited), length(visited), sum(cap)))

keep <- primary %in% visited
Ycap <- cap[, keep]; storage.mode(Ycap) <- "integer"
long <- array_to_eco(Ycap, taxon = "RHIDAR", site_ids = id$frog, period = primary[keep],
                     site_covs = list(cluster_id = paste0("HUI", id$plot)),
                     obs_covs = list(x_m = X[, keep], y_m = Y[, keep], svl_mm = S[, keep]))
setnames(long, "unit_cluster_id", "cluster_id", skip_absent = TRUE)
long[y == 0L, c("obs_x_m", "obs_y_m", "obs_svl_mm") := NA_real_]     # SVL is written on all secondaries of the primary; keep it on capture rows only
long <- order_eco(long)
stopifnot(nrow(long) == 311 * 36, sum(long$y) == 1031, uniqueN(long$unit) == 311,
          identical(sort(unique(long$period)), visited), max(long$occasion) == 4,
          sum(long$y == 1 & is.na(long$obs_x_m)) == 3, sum(long$y == 1 & is.na(long$obs_y_m)) == 3,
          sum(long$y == 1 & is.na(long$obs_svl_mm)) == 4, all(is.na(long[y == 0, obs_x_m])),
          all(long[, uniqueN(cluster_id), by = unit]$V1 == 1))

taxa <- make_taxa("RHIDAR", "Rhinoderma darwinii", vernacularName = "Southern Darwin's frog", taxon_iucnCategory = "EN")
periods <- data.table(period = visited)[, .(period, primary_index_in_file = period, months_after_first_primary = (period - 1L) * 3L,
                                            n_secondary_occasions = 4L,
                                            n_captures = sapply(period, function(p) sum(cap[, primary == p])),
                                            n_frogs_captured = sapply(period, function(p) sum(rowSums(cap[, primary == p]) > 0)))]
stopifnot(sum(periods$n_captures) == 1031)

dataset <- list(
  title = "Robust-design search-encounter capture histories with capture coordinates of 311 Southern Darwin's frogs at two plots near Neltume, Chile, 2014-2017",
  creator = "Valenzuela-Sánchez, Andrés", pubDate = "2018", doi = "10.5281/zenodo.1327549",
  sourceURL = "https://doi.org/10.5281/zenodo.1327549",
  citation = "Valenzuela-Sánchez, A. (2018). Spatial capture-recapture data of Darwin's frogs captured between 2014-2017 [Data set]. Zenodo. https://doi.org/10.5281/zenodo.1327549",
  relatedWorks = list("Valenzuela-Sánchez, A. et al. (2017). Cryptic disease-induced mortality may cause host extinction in an apparently stable host-parasite system. Proc. R. Soc. B 284, 20171176. doi:10.1098/rspb.2017.1176",
                      "Valenzuela-Sánchez, A. et al. (2022). Interpopulation differences in male reproductive effort drive the population dynamics of a host exposed to an emerging fungal pathogen. J. Anim. Ecol. 91, 308-319. doi:10.1111/1365-2656.13603"),
  intellectualRights = list(spdx = "CC-BY-SA-4.0", url = "https://creativecommons.org/licenses/by-sa/4.0/"),
  abstract = "Search-encounter capture-recapture of Southern Darwin's frogs (Rhinoderma darwinii) at two plots (HUI1, HUI2) in the Huilo Huilo reserve near Neltume, southern Chile, 2014-2017, under Pollock's robust design: 16 quarterly primary periods, nine of them visited, each of four consecutive capture days. y = 1 if the frog was captured on that day. The location of each capture in plot-local metres (obs_x_m, obs_y_m) and the frog's snout-vent length in the primary period of capture (obs_svl_mm) are carried on the capture rows, so the spatial Cormack-Jolly-Seber model the authors fitted, and non-spatial robust-design models, can be refit. No geographic coordinates, dates or sex are deposited.",
  samplingProtocol = "Visual search of fixed plots by hand on four consecutive days per primary period, frogs individually identified (photo-identification of ventral pattern), capture location recorded in plot coordinates (m), snout-vent length measured; primary periods three months apart.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A column (secondary occasion) with at least one capture is a surveyed occasion; the seven primary periods whose four columns are all NA in every row (2, 6, 10, 11, 13, 14, 15) were not visited and have no rows, following the record's sibling (zenodo.1185403: 'we did not visit the populations during all these periods'). Every secondary of a visited primary has captures at both plots.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "occasion within period (robust design: four consecutive capture days per quarterly primary period; open between primaries)", occasionKind = "time", taxonInclusion = "single",
  occasionCodes = list(`1` = "capture day 1 of the primary period", `2` = "day 2", `3` = "day 3", `4` = "day 4"),
  crs = "local: plot-local metres, origin not deposited",
  coordinatesCoarsened = list(value = FALSE, method = "no geographic coordinates: capture locations are plot-local metres with no deposited origin, so an IUCN EN species is not located by this table"),
  geographicCoverage = "Two plots (HUI1, HUI2) in the Huilo Huilo Biological Reserve near Neltume, Los Ríos Region, Chile (c. 39.8 S, 71.9 W at 0.1 degree; no coordinates deposited)",
  temporalCoverage = "2014/2017",
  designNote = "Search-encounter SCR without fixed detectors: there is no trap key or __traps table; the capture coordinates are observation covariates on the detection rows (design_landscape.md: SCR family, detector-less variant).",
  notes = "period is the primary-period index in the file (1-16, quarterly), so gaps between the nine visited periods are real time (months_after_first_primary in __periods); the calendar of period 1 is not deposited. Six cells have a coordinate in one of x.txt / y.txt and NA in the other (frogs 10 and 24, primary 5 secondaries 3-4; frogs 3 and 27, primary 7 secondary 3): counted as captures with the missing coordinate NA. svl.txt writes the SVL on all four secondaries of a captured primary; it is shipped on the capture rows only. Three captured frog-primaries have no SVL (frogs 10 and 27 above, G251b in primary 16). Frog codes are the deposit's (integers and codes such as I275, G251b).",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/valenzuela_2018_neltume_rhidar_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design capture histories of 311 individually identified Southern Darwin's frogs (Rhinoderma darwinii, IUCN EN) at two plots in the Huilo Huilo reserve, Chile, 2014-2017: 16 quarterly primary periods (9 visited) x 4 consecutive capture days, with each capture's plot-local coordinates (m) and the frog's snout-vent length on the capture rows, for spatial CJS or non-spatial robust-design models.",
  url = "https://doi.org/10.5281/zenodo.1327549",
  reference = "Valenzuela-Sánchez, A. (2018). Spatial capture-recapture data of Darwin's frogs captured between 2014-2017. Zenodo. Related: Valenzuela-Sánchez et al. (2017) Proc. R. Soc. B 284:20171176; Valenzuela-Sánchez et al. (2022) J. Anim. Ecol. 91:308-319.",
  doi_paper = "", doi_data = "10.5281/zenodo.1327549",
  original_license = "CC BY-SA 4.0", derived_license = "CC BY-SA 4.0",
  notes = "No article named by the record. Seven unvisited primaries carry no rows. Capture coordinates are plot-local metres (no origin). Six half-coordinate cells counted as captures.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Robust design capture-recapture; spatial CJS (search-encounter SCR without detectors)",
  sampling_protocol = "hand_capture", design = "Robust design (16 quarterly primary periods, 9 visited, x 4 consecutive capture days)",
  realm = "Terrestrial", country = "CHL", coordinates = "None in source (plot-local capture coordinates in metres as obs_x_m / obs_y_m)",
  notes = "Full 311 x 36 rectangle; cluster_id = plot. EN taxon with no geographic coordinates. CC BY-SA propagates.")
