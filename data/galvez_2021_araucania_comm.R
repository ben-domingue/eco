#!/usr/bin/env Rscript
# Table:  galvez_2021_araucania_comm
# Source: Dryad doi:10.5061/dryad.5qfttdz3h, version 3 (2021-09-14). Dryad records CC0 1.0;
#         the deposited readme states ODbL 1.0 / DbCL 1.0. Intake policy: the stricter
#         licence governs, so derived_license = ODbL-1.0.
#   Galvez, N., Infante, J., Fernandez, A., Diaz, J. & Petracca, L. (2021). Detection
#   histories of mesocarnivores in agricultural areas of Southern Chile. Dryad.
# Paper:  Galvez et al. (2021). Land use intensification coupled with free-roaming dogs
#         as potential defaunation drivers of mesocarnivores in agricultural landscapes.
#         Journal of Applied Ecology 58(12), 2962-2974, doi:10.1111/1365-2664.14026
# Data:   one xlsx. Sheets guiñahistory / skunkhistory / cathistory / foxhistory /
#         doghistory: 180 sample units x o1..o14 (5-night occasions), 0/1/NA. site_covs:
#         180 x 36 landscape metrics (400-ha and 10-ha buffers), TYPE, Effort (total camera
#         nights). occ_covs: 180 x 14 for e (camera nights in the occasion), j (days since
#         1 Jan 2019 at the start of the occasion), hc/dc/cc (human/dog/cat detections),
#         hb/db/cb (the same as 0/1). ForOverlap: raw camtrapR record table (not used).
#         Checked: all five histories and all occasion covariates share one NA pattern
#         (693 of 2,520 unit-occasions, trailing occasions only, "NA" stored as text).
#         site_covs$Effort (total camera days) differs from the sum of e for 146 units, so
#         it is not shipped; obs_camera_nights is the per-row effort.
#
# Mapping (standard section 3.6, community occupancy): unit = sample unit (4-km2 grid
#   cell id), taxon = GUIGNA / SKUNK / CAT / FOX / DOG, occasion = 1..14, y = 0/1.
#   date = 2019-01-01 + j (start of the occasion; verified against the record table:
#   j1 = 7 at unit 21020 and its first record is 2019-01-08). obs_camera_nights = e,
#   obs_human_detections = hc. dc/cc (dog and cat detection counts) are NOT shipped: dog
#   and cat are taxa in the table (as 0/1), and the counts would be a covariate built from
#   the same detections. unit_: the 13 readme-listed landscape metrics + TYPE; the other
#   22 FRAGSTATS columns (AREA_*, GYRATE_* except MN, SHAPE_*, CA, PredsDiss_count,
#   POB_estima) are not shipped (undocumented in the readme). FOX = Lycalopex (genus;
#   culpeo and chilla are not separated in the deposit). No coordinates in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "galvez_2021_araucania_comm"
dir <- download_dryad("10.5061/dryad.5qfttdz3h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "mesoc_agrilandscapes_chile.xlsx"); stopifnot(file.exists(f))

sheets <- c(GUIGNA = "guiñahistory", SKUNK = "skunkhistory", CAT = "cathistory", FOX = "foxhistory", DOG = "doghistory")
species <- c(GUIGNA = "Leopardus guigna", SKUNK = "Conepatus chinga", CAT = "Felis catus", FOX = "Lycalopex", DOG = "Canis familiaris")
vern <- c("Guigna (kodkod)", "Molina's hog-nosed skunk", "Domestic cat", "Foxes (culpeo / chilla)", "Domestic dog")
hist <- lapply(sheets, function(s) as.data.table(read_excel(f, s)))   # cells are text ("NA" literal) in the xlsx
to_num <- function(m) suppressWarnings(matrix(as.numeric(m), nrow(m)))
units <- as.character(hist[[1]]$SampleUnits)
stopifnot(length(units) == 180, !anyDuplicated(units), all(sapply(hist, function(h) identical(as.character(h$SampleUnits), units))))
y <- array(unlist(lapply(hist, function(h) to_num(as.matrix(h[, paste0("o", 1:14)])))), dim = c(180, 14, 5), dimnames = list(units, NULL, names(sheets)))
stopifnot(all(y %in% c(0, 1, NA)))
na_hist <- is.na(y[, , 1]); stopifnot(all(apply(is.na(y), 3, identical, na_hist)))

oc <- as.data.table(read_excel(f, "occ_covs")); stopifnot(identical(as.character(oc$SampleUnits), units))
num_mat <- function(prefix) suppressWarnings(matrix(as.numeric(as.matrix(oc[, paste0(prefix, 1:14), with = FALSE])), 180))  # "NA" strings -> NA
e <- num_mat("e"); j <- num_mat("j"); hc <- num_mat("hc")
stopifnot(identical(is.na(e), is.na(j)), identical(is.na(e), is.na(hc)), all(e >= 1, na.rm = TRUE))
stopifnot(all(is.na(e) == na_hist), sum(na_hist) == 693)   # surveyed iff camera nights recorded
cat(sprintf("  %d of %d units have non-trailing gaps in camera operation\n", sum(apply(na_hist, 1, function(r) any(diff(as.integer(r)) < 0))), nrow(na_hist)))
stopifnot(all(apply(j, 1, function(r) all(diff(na.omit(r)) > 0))))
date_m <- matrix(format(as.Date("2019-01-01") + j), 180)

sc <- as.data.table(read_excel(f, "site_covs")); stopifnot(identical(as.character(sc$SITE), units), all(sc$TYPE == "Forest"))
site_covs <- sc[, .(habitat_type = TYPE, forest_pct_400ha = PLAND, largest_patch_index_400ha = LPI, total_edge_m_400ha = TE,
                    edge_density_400ha = ED, gyration_mean_m_400ha = GYRATE_MN, n_patches_400ha = NP, landscape_shape_index_400ha = LSI,
                    cohesion_400ha = COHESION, n_land_subdivisions_400ha = Preds_coun, forest_pct_10ha = PLAND10,
                    n_patches_10ha = NP10, edge_density_10ha = ED10, n_land_subdivisions_10ha = Preds_coun10)]
long <- array_to_eco(y, site_ids = units, site_covs = site_covs,
                     obs_covs = list(camera_nights = e, human_detections = hc, date = date_m))
setnames(long, "obs_date", "date")
stopifnot(nrow(long) == 5 * sum(!is.na(e)), !anyNA(long$obs_camera_nights))
cat("  skipped dc*/cc* (dog and cat detection counts): the same detections are taxa DOG and CAT\n")

taxa <- make_taxa(names(species), unname(species), vernacularName = vern,
                  taxonRank = ifelse(names(species) == "FOX", "genus", "species"))
dataset <- list(
  title = "Camera-trap detection histories of guigna, hog-nosed skunk, foxes, domestic dogs and cats in agricultural landscapes of La Araucania, Chile, 2019",
  creator = "Galvez, Nicolas; Infante, Jose; Fernandez, Adrian; Diaz, Jesus; Petracca, Lisanne", pubDate = "2021",
  doi = "10.5061/dryad.5qfttdz3h", sourceURL = "https://doi.org/10.5061/dryad.5qfttdz3h",
  citation = "Galvez, N., Infante, J., Fernandez, A., Diaz, J., & Petracca, L. (2021). Detection histories of mesocarnivores in agricultural areas of Southern Chile [Dataset]. Dryad. https://doi.org/10.5061/dryad.5qfttdz3h",
  paperDOI = "10.1111/1365-2664.14026",
  intellectualRights = list(spdx = "ODbL-1.0", url = "https://opendatacommons.org/licenses/odbl/1-0/",
                            note = "Dryad records CC0 1.0; the deposited readme states ODbL 1.0 / DbCL 1.0. Per the intake policy (standard.md, ruled 2026-11-01) the stricter licence governs and propagates."),
  abstract = "Camera-trap survey of 180 sampling units selected from a grid of 4-km2 cells in agricultural landscapes of La Araucania Region, southern Chile (February-March 2019), with landscape metrics at 400-ha and 10-ha scales, used to fit single-species occupancy and two-species co-occurrence models of mesocarnivores, free-roaming dogs and cats.",
  samplingProtocol = "One camera trap per 4-km2 grid cell; detection histories built with camtrapR; occasion = 5 camera nights; camera nights per occasion is the effort covariate.",
  samplingProtocolCode = "camera_trap", occasionLength = "5 nights", effortColumn = "obs_camera_nights",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "La Araucania Region, Chile (no coordinates deposited)", temporalCoverage = "2019-01/2019-03",
  coordinatesCoarsened = NA,
  notShipped = list(`dc*, cc*` = "dog/cat detection counts (same detections as taxa DOG, CAT)",
                    `hb*, db*, cb*` = "0/1 versions of hc/dc/cc",
                    `22 site_covs columns` = "FRAGSTATS metrics not documented in the readme",
                    ForOverlap = "raw record table used for activity-overlap analysis"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/galvez_2021_araucania_comm.R")

stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of guigna, Molina's hog-nosed skunk, foxes (Lycalopex), domestic dog and domestic cat at 180 grid-cell camera stations over up to 14 five-night occasions in agricultural landscapes of La Araucania, Chile (2019), with camera nights and human detections per occasion and 13 landscape metrics per station.",
  url = "https://doi.org/10.5061/dryad.5qfttdz3h",
  reference = "Galvez, N., Infante, J., Fernandez, A., Diaz, J., & Petracca, L. (2021). Land use intensification coupled with free-roaming dogs as potential defaunation drivers of mesocarnivores in agricultural landscapes. Journal of Applied Ecology, 58(12), 2962-2974.",
  doi_paper = "10.1111/1365-2664.14026", doi_data = "10.5061/dryad.5qfttdz3h",
  original_license = "CC0 1.0 (Dryad) / ODbL 1.0 (readme)", derived_license = "ODbL-1.0",
  notes = "Licence conflict: Dryad metadata CC0, deposited readme ODbL/DbCL; the stricter (ODbL) governs and propagates (intake policy). 693 of 2,520 unit-occasions not surveyed (trailing). Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy",
  sampling_protocol = "camera_trap", design = "Single-season", realm = "Terrestrial", country = "CHL",
  coordinates = "None in source", notes = "Five taxa incl. domestic dog and cat; FOX is genus-level. Occasion = 5 camera nights. Derived licence ODbL-1.0 (propagating).",
  status = "tagged")
