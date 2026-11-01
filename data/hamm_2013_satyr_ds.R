#!/usr/bin/env Rscript
# Table:  hamm_2013_satyr_ds
# Source: Dryad doi:10.5061/dryad.v977b (CC0 1.0), version 1 (2013-01-22)
#   Hamm, C. A. (2013). Data from: Estimating abundance of the federally endangered
#   Mitchell's satyr butterfly using hierarchical distance sampling. Dryad.
# Paper:  Hamm, C. A. (2013). Estimating abundance of the federally endangered Mitchell's
#         satyr butterfly using hierarchical distance sampling. Insect Conservation and
#         Diversity 6(5), 619-626. doi:10.1111/icad.12017 (paywalled; design read from the
#         deposited files and the deposited R script).
# Data:   five xlsx files, one per survey date (4, 6, 7, 8, 12 July 2011), each one row per
#         line transect walked that day: Transect (stake pair, e.g. P1P2; the labels are
#         date-specific and are not re-used across dates), D0..D4 = number of butterflies
#         detected at perpendicular distance 0-1, 1-2, 2-3, 3-4, 4-5 m, Length (m), Site
#         (JCC, Liberty, Weaver), Habitat (management unit A-D), Temp (C) and RH (%) for
#         the day. The deposited R script builds one unmarkedFrameDS per date with
#         dist.breaks = 0:5 m, survey = 'line', unitsIn = 'm'.
#
# Mapping (standard E1-E5, E9 declared stretch: binned line-transect distance sampling):
#   unit = date_transect (125 transect-walks; transects are not matched across dates in
#   the deposit, so there is no period), taxon = NEOMIM, occasion = distance bin 1..5 with
#   y_raw = "0-1 m" .. "4-5 m", y = count in the bin, date = survey date, cluster_id = Site;
#   unit_habitat, unit_length_m, unit_temp_c, unit_rh_pct. distanceBreaks = 0,1,2,3,4,5 m.
#   Survey evidence = deposited_matrix: each file lists every transect walked that day,
#   with all-zero rows for transects without detections.
#   Flagged taxon (US federally endangered) but no coordinates in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "hamm_2013_satyr_ds"
dir <- download_dryad("10.5061/dryad.v977b", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
files <- c("ds_Lib_4_Jul.xlsx" = "2011-07-04", "ds_Lib_6_Jul.xlsx" = "2011-07-06", "ds_Lib_7_Jul.xlsx" = "2011-07-07",
           "ds_Lib_8_Jul.xlsx" = "2011-07-08", "ds_Lib_12_Jul.xlsx" = "2011-07-12")
stopifnot(all(file.exists(file.path(dir, names(files)))))
BINS <- c("0-1 m", "1-2 m", "2-3 m", "3-4 m", "4-5 m")

raw <- rbindlist(lapply(names(files), function(f) {
  d <- as.data.table(read_excel(file.path(dir, f)))
  setnames(d, 1, "Transect")                                  # 7 July header reads "Trasect"
  stopifnot(identical(names(d), c("Transect", "D0", "D1", "D2", "D3", "D4", "Length", "Site", "Habitat", "Temp", "RH")))
  d[, date := files[[f]]]
  d
}))
stopifnot(nrow(raw) == 27 + 24 + 25 + 33 + 16, !anyNA(raw$Transect), !anyDuplicated(raw[, .(date, Transect)]),
          all(as.matrix(raw[, D0:D4]) >= 0), all(as.matrix(raw[, D0:D4]) == round(as.matrix(raw[, D0:D4]))),
          all(raw$Length > 0), all(raw$Site %in% c("JCC", "Liberty", "Weaver")), all(raw$Habitat %in% c("A", "B", "C", "D")),
          raw[, uniqueN(Temp) == 1 & uniqueN(RH) == 1, by = date][, all(V1)])
stopifnot(sum(as.matrix(raw[, D0:D4])) == 114 + 74 + 62 + 63 + 15)   # per-date totals as deposited

y <- as.matrix(raw[, D0:D4]); storage.mode(y) <- "integer"; colnames(y) <- BINS
unit_ids <- paste(raw$date, raw$Transect, sep = "_")
site_covs <- data.frame(habitat = raw$Habitat, length_m = as.numeric(raw$Length), temp_c = as.numeric(raw$Temp), rh_pct = as.numeric(raw$RH))
long <- array_to_eco(y, taxon = "NEOMIM", site_ids = unit_ids, site_covs = site_covs,
                     y_raw = matrix(BINS, nrow(y), 5, byrow = TRUE))
long[, date := sub("_.*$", "", unit)]
long[, cluster_id := raw$Site[match(unit, unit_ids)]]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(raw) * 5, sum(long$y) == sum(y), uniqueN(long$unit) == nrow(raw))

taxa <- make_taxa("NEOMIM", "Neonympha mitchellii mitchellii", vernacularName = "Mitchell's satyr", taxonRank = "subspecies")
dataset <- list(
  title = "Mitchell's satyr butterfly line-transect distance sampling counts in 1 m bins, 125 transect walks on five days, lower Michigan, July 2011",
  creator = "Hamm, Christopher A.", pubDate = "2013", doi = "10.5061/dryad.v977b", sourceURL = "https://doi.org/10.5061/dryad.v977b",
  citation = "Hamm, C. A. (2013). Data from: Estimating abundance of the federally endangered Mitchell's satyr butterfly using hierarchical distance sampling [Data set]. Dryad. https://doi.org/10.5061/dryad.v977b",
  paperDOI = "10.1111/icad.12017",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Line-transect distance sampling of the federally endangered Mitchell's satyr (Neonympha mitchellii mitchellii) at one fen site in lower Michigan, USA: one observer walked a series of short transects on each of five days in July 2011 and recorded the number of butterflies seen in 1 m perpendicular-distance bins out to 5 m. The deposited analysis fits one unmarked distsamp model per day with management unit as a covariate.",
  samplingProtocol = "Line-transect distance sampling on foot; perpendicular distance of each butterfly recorded and binned at 1 m to a 5 m truncation; transect length in metres per walk.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", distanceBreaks = c(0, 1, 2, 3, 4, 5), distanceUnits = "m", transectType = "line",
  effortColumn = "unit_length_m", unitKind = "site", closure = "occasion (bins of one walk)",
  geographicCoverage = "One Mitchell's satyr site in lower Michigan, USA (site names JCC, Liberty, Weaver; no coordinates deposited)",
  temporalCoverage = "2011-07-04/2011-07-12",
  notes = "Transect labels are date-specific (P, Q, Y, G, S series) and the deposit does not match them across days, so each walk is its own unit and there is no period. Temperature and humidity are per day, carried at unit level. First distance-sampling table.",
  notShipped = list(none = "all deposited data files shipped; Hamm_JICD_201X.R is analysis code"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hamm_2013_satyr_ds.R")
stage_dict_row(TABLE,
  description = "Line-transect distance sampling counts of the federally endangered Mitchell's satyr butterfly (Neonympha mitchellii mitchellii) in five 1 m perpendicular-distance bins on 125 transect walks over five days in July 2011 at one site in lower Michigan, with transect length, management unit, temperature and humidity. First distance-sampling (multinomial_cell, distanceBreaks) table.",
  url = "https://doi.org/10.5061/dryad.v977b",
  reference = "Hamm, C. A. (2013). Estimating abundance of the federally endangered Mitchell's satyr butterfly using hierarchical distance sampling. Insect Conservation and Diversity, 6(5), 619-626.",
  doi_paper = "10.1111/icad.12017", doi_data = "10.5061/dryad.v977b",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = distance bin, distanceBreaks in metadata. Transects not matched across days; unit = date_transect. Endangered taxon, no coordinates in the deposit.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Distance sampling (line transect, 1 m bins)",
  sampling_protocol = "line_transect", design = "Single-season (5 survey days, transects not matched across days)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source",
  notes = "Declared stretch: occasion = distance bin (0-5 m). US federally endangered subspecies; no coordinates deposited.")
