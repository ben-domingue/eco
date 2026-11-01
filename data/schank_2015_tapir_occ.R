#!/usr/bin/env Rscript
# Table:  schank_2015_tapir_occ
# Source: Zenodo record 17602, doi:10.5281/zenodo.17602 (CC0 1.0)
#   Schank, C. (2015). Tapir detection histories (Tapirus bairdii) from Rio Indio,
#   Nicaragua. Camera trap detection histories from June-August 2014.
# Data:   one CSV, 22 cameras x (Provider, Days, Lat, Long, S1..S217). S_k = daily
#         detection (0/1) on the k-th day the camera operated; trailing blanks = camera
#         no longer operating (checked: the non-blank cells of every row are a prefix).
#         `Days` is the deposited effort (camera-days); it is 1-2 less than the number of
#         filled S cells in every row, presumably because partial first/last days are
#         counted as cells but not as effort. Both are kept: cells drive the rows,
#         `Days` goes to unit_trapdays.
#
# Mapping (standard section 3.1, single-season occupancy): unit = camera (row index; the
#   deposit has no camera labels), taxon = TAPBAI, occasion = day index, y = 0/1.
#   Occasions are camera-relative (day 1 is each camera's first day), so no `date`.
# Coordinates: Baird's tapir is IUCN Endangered and the deposit carries raw camera
#   coordinates to 1e-8 degrees. Following standard section 6 the coordinates are
#   coarsened to the centre of a 0.1-degree cell, with the cell half-diagonal as
#   unit_coordinateUncertaintyInMeters and dataset.coordinatesCoarsened = TRUE.
# Floor: 22 cameras is below the proposed 30-unit floor (standard section 10, open
#   question 2). Built anyway as a concrete case for that decision; flagged in the
#   tags row and dataset.json.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "schank_2015_tapir_occ"
f <- download_cached("https://zenodo.org/api/records/17602/files/Tapir_detection_histories_-_Rio_Indio_Nicaragua_-_Cody_Schank.csv/content",
                     TABLE, filename = "tapir_detection_histories.csv")
raw <- fread(f)
stopifnot(nrow(raw) == 22, all(raw$Provider == "Cody Schank"))
scols <- grep("^S[0-9]+$", names(raw), value = TRUE)
y <- as.matrix(raw[, ..scols]); storage.mode(y) <- "integer"
stopifnot(all(y %in% c(0L, 1L, NA)))
# non-blank cells form a prefix of each row
stopifnot(all(apply(is.na(y), 1, function(r) all(diff(as.integer(r)) >= 0))))
n_cells <- rowSums(!is.na(y)); stopifnot(all((n_cells - raw$Days) %in% 1:2))

cc <- coarsen_coords(raw$Lat, raw$Long)
site_covs <- data.frame(trapdays = raw$Days, decimalLatitude = cc$lat, decimalLongitude = cc$lon,
                        coordinateUncertaintyInMeters = cc$uncertainty_m)
long <- array_to_eco(y, taxon = "TAPBAI", site_ids = seq_len(nrow(raw)), site_covs = site_covs)
stopifnot(nrow(long) == sum(n_cells))

taxa <- make_taxa("TAPBAI", "Tapirus bairdii", vernacularName = "Baird's tapir")
dataset <- list(
  title = "Baird's tapir camera-trap detection histories, Rio Indio, Nicaragua, June-August 2014",
  creator = "Schank, Cody", pubDate = "2015", doi = "10.5281/zenodo.17602",
  sourceURL = "https://doi.org/10.5281/zenodo.17602",
  citation = "Schank, C. (2015). Tapir detection histories (Tapirus bairdii) from Rio Indio, Nicaragua [Data set]. Zenodo. https://doi.org/10.5281/zenodo.17602",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera trap detection histories from June-August 2014 (deposit description in full).",
  samplingProtocol = "Camera traps; daily detection/non-detection per camera; camera-days of effort in unit_trapdays.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day", effortColumn = "unit_trapdays",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = list(description = "Rio Indio, southeastern Nicaragua",
                            boundingBox = list(west = min(cc$lon), east = max(cc$lon), south = min(cc$lat), north = max(cc$lat))),
  temporalCoverage = "2014-06/2014-08",
  coordinatesCoarsened = list(value = TRUE, method = "0.1-degree grid cell centre; IUCN Endangered taxon; source coordinates were exact camera locations"),
  notShipped = list(Provider = "constant (data provider, not an observer)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/schank_2015_tapir_occ.R")

stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of Baird's tapir at 22 cameras (6-72 camera-days each) in Rio Indio, Nicaragua, June-August 2014, with camera-days of effort and coarsened (0.1 degree) camera coordinates.",
  url = "https://doi.org/10.5281/zenodo.17602",
  reference = "Schank, C. (2015). Tapir detection histories (Tapirus bairdii) from Rio Indio, Nicaragua [Data set]. Zenodo.",
  doi_data = "10.5281/zenodo.17602", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "No associated paper identified. Coordinates coarsened to a 0.1-degree grid (Endangered taxon). 22 units: below the proposed 30-unit floor.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season", realm = "Terrestrial", country = "NIC",
  coordinates = "Coarsened (0.1 deg)", notes = "Daily occasions, camera-relative; 11 detections in 1,050 camera-days.",
  status = "tagged; hold: below sample floor")
