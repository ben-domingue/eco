#!/usr/bin/env Rscript
# Table:  burgar_2018_alberta_fisher_count
# Source: Dryad doi:10.5061/dryad.dh7cd36 (CC0 1.0), version 17922 (published 2019-07-05)
#   Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T. & Burton, A. C. (2019). Data
#   from: Estimating density for species conservation: comparing camera trap spatial count
#   models to genetic spatial capture-recapture models. Dryad.
# Paper:  Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T. & Burton, A. C. (2018).
#         Global Ecology and Conservation 15, e00411. doi:10.1016/j.gecco.2018.e00411 (open
#         access, CC BY-NC-ND; publisher bot wall, not read by the agent).
# Data:   Fisher_60min2016_matrix.csv: the "unmarked fisher camera detection data" (Dryad
#         usage notes), a 64 x 64 matrix: row names are camera site ids 1..66 without 11 and
#         21; column names "0".."63" are the sampling occasions; cells are 0/1 (180 ones; the
#         file name says independent 60-minute detection events, and no cell exceeds 1). No
#         NA. What one occasion is (a day is the natural reading of 64 consecutive columns in
#         a winter 2016 survey) is stated only in the paper. The site numbering does not
#         match secr_trapID in TDF.csv (1..64), and the deposit gives no key, so the camera
#         sites carry no coordinates here; the genetic SCR data are the sibling table
#         burgar_2018_alberta_fisher_scr.
#         Asserted below: 64 x 64, ids as stated, cells in {0, 1}, 180 detections at 37 sites.
#
# Mapping (standard E1-E6; single-species camera-trap detections, one season):
#   unit = camera site (C01..C66 as deposited, 64 of them), occasion = deposited column
#   index + 1 (1..64), y = the cell (0/1). responseType = detection: the matrix holds only
#   0 and 1, so the authors' spatial-count reading (counts of independent events) and the
#   detection reading are the same table. Survey set = deposited_matrix: every site has a
#   value for every occasion (no NA), so all 64 x 64 site-occasions are surveyed. One
#   period. No covariates or coordinates in this file. Fisher is IUCN Least Concern.
#   NOT shipped: nothing from this file; edf.csv and TDF.csv are the sibling table.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "burgar_2018_alberta_fisher_count"
SCRIPT <- "data/burgar_2018_alberta_fisher_count.R"
dir <- download_dryad("10.5061/dryad.dh7cd36", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

m <- fread(file.path(dir, "Fisher_60min2016_matrix.csv"), header = TRUE)   # first header cell is "", fread needs the hint
stopifnot(ncol(m) == 65, nrow(m) == 64, identical(names(m)[-1], as.character(0:63)),
          identical(sort(m[[1]]), setdiff(1:66, c(11L, 21L))))
setnames(m, 1, "site")
long <- melt(m, id.vars = "site", variable.name = "col", value.name = "y")
long[, occasion := as.integer(as.character(col)) + 1L]
stopifnot(all(long$y %in% 0:1), sum(long$y) == 180, uniqueN(long[y == 1, site]) == 37, nrow(long) == 64 * 64)
cat(sprintf("  %d camera sites x %d occasions, %d detections at %d sites\n", 64L, 64L, sum(long$y), uniqueN(long[y == 1, site])))
long <- long[, .(unit = sprintf("C%02d", site), taxon = "PEKPEN", y = as.integer(y), occasion)]
long <- order_eco(long)

taxa <- make_taxa("PEKPEN", "Pekania pennanti", vernacularName = "Fisher", taxon_iucnCategory = "LC")

dataset <- list(
  title = "Camera-trap detections of fishers at 64 sites over 64 occasions, Alberta, 2016 (the unmarked data of a spatial-count vs genetic SCR comparison)",
  creator = "Burgar, Joanna M.; Stewart, Frances E. C.; Volpe, John P.; Fisher, Jason T.; Burton, A. Cole",
  pubDate = "2019", doi = "10.5061/dryad.dh7cd36", sourceURL = "https://doi.org/10.5061/dryad.dh7cd36",
  citation = "Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T., & Burton, A. C. (2019). Data from: Estimating density for species conservation: comparing camera trap spatial count models to genetic spatial capture-recapture models [Data set]. Dryad. https://doi.org/10.5061/dryad.dh7cd36",
  paperDOI = "10.1016/j.gecco.2018.e00411",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap detections of unmarked fishers (Pekania pennanti) at 64 camera sites over 64 sampling occasions in 2016, the 'unmarked' data set of a study comparing spatial count density estimates from cameras with genetic spatial capture-recapture estimates for the same population (sibling table burgar_2018_alberta_fisher_scr). The deposit is a site x occasion matrix of independent 60-minute detection events that contains only 0 and 1, shipped as detection / non-detection; 180 detections at 37 of 64 sites.",
  samplingProtocol = "Camera traps at 64 sites (deposited ids 1-66 without 11 and 21); independent detection events defined by a 60-minute interval; 64 sampling occasions in 2016 whose length (one day being the natural reading) is stated only in the paper, which the agent could not fetch.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The matrix has a value for every site x occasion (no NA), so every site-occasion is a survey.",
  responseType = "detection", unitKind = "site",
  closure = "single period: one 2016 survey of 64 occasions treated as closed (the authors' spatial count model)",
  geographicCoverage = "Alberta, Canada; no coordinates in this file (the camera site numbering is not keyed to the TDF of the sibling table); the hair-snag array of the same study sits at 53.2-53.6 N, 112.7-113.1 W if its UTM zone is 12N",
  temporalCoverage = "2016",
  designNote = "Single-species camera detections. The authors fitted spatial count models (counts per site-occasion); the deposited matrix never exceeds 1, so detection and count readings coincide. Occasion length not recoverable from the deposit.",
  notes = "Site ids C01-C66 without C11 and C21 as deposited; occasion = deposited column index 0-63 plus one. Not joinable to burgar_2018_alberta_fisher_scr (different site numbering, no key deposited).",
  notShipped = list(`edf.csv, TDF.csv` = "the genetic SCR data, shipped as burgar_2018_alberta_fisher_scr"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Camera-trap detection / non-detection of fishers at 64 sites x 64 sampling occasions, Alberta, 2016; the unmarked data set paired with the genetic SCR table burgar_2018_alberta_fisher_scr.",
  url = "https://doi.org/10.5061/dryad.dh7cd36",
  reference = "Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T., & Burton, A. C. (2018). Estimating density for species conservation: Comparing camera trap spatial count models to genetic spatial capture-recapture models. Global Ecology and Conservation, 15, e00411.",
  doi_paper = "10.1016/j.gecco.2018.e00411", doi_data = "10.5061/dryad.dh7cd36",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-species camera detections, complete 64 x 64 matrix. No coordinates (site numbering not keyed to the TDF). Occasion length only in the paywalled-to-agents paper.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy / spatial count (unmarked)",
  sampling_protocol = "camera_trap", design = "Single-season (64 occasions, 64 camera sites)", realm = "Terrestrial",
  country = "CAN", coordinates = "None in source (this file; the sibling SCR table has the hair-snag coordinates)",
  notes = "Unmarked half of the Burgar et al. 2018 comparison. 0/1 only, so shipped as detection.")
