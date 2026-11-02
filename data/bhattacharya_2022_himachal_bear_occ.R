#!/usr/bin/env Rscript
# Table:  bhattacharya_2022_himachal_bear_occ
# Source: Dryad doi:10.5061/dryad.fxpnvx0tp, version 170003 (2022-03-31), licence CC0 1.0
#         (as shown on the Dryad record; the README states none).
# Paper:  Bhattacharya, A., Chatterjee, N., Angrish, K., Meena, D., Sinha, B. C. & Habib, B.
#         (2022). Population estimation of Asiatic black bear in the Himalayan Region of
#         India using camera traps. Ursus 33(e8), 1-10. doi:10.2192/URSUS-D-21-00002.2
#         (paywalled; abstract used). Camera-trap survey May-July 2018 in Daranghati WLS and
#         May-July 2019 in Rupi Bhaba WLS, Himachal Pradesh; the paper fits a spatial
#         presence-absence model (no individual identification).
# Data:   Black_bear_ursus_dataset.xlsx, two sheets, one per protected area:
#         "Rupi-bhaba" (34 sites x day_1..day_49) and "Dharanghati" (33 sites x day_1..day_40).
#         Cells are "1" detected, "0" not detected, "NA" camera not active (README). The
#         README says histories are accumulated over 24-hour sampling periods, so a column
#         is one camera-day; day_1 is each camera's first deployment day (camera-relative,
#         no calendar dates). Checked: in every row the NA cells form a suffix (the camera
#         ran day_1..day_k then stopped). Site numbers repeat across the two sheets (e.g. 21,
#         23, 24) and are different cameras. README.txt (title, authors, value codes).
#
# Mapping (standard E9 core, single-season occupancy, one table for the deposit):
#   unit = area code + site number ("RB_8", "DH_6"), cluster_id = protected area (the two
#   areas were sampled in different years and analysed separately in the paper; the area is
#   also unit_area and unit_year), taxon = URSTHI, occasion = camera-day index (camera-
#   relative), y = 0/1. Survey evidence: the deposited matrix; a camera-day exists iff the
#   cell is 0 or 1 (deposited_matrix). No `date`: day_1 is not a calendar date.
#   No coordinates in the deposit (the bear is IUCN VU, so none to coarsen). No covariates
#   beyond area and year. Nothing is a model output; nothing not shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bhattacharya_2022_himachal_bear_occ"
dir <- download_dryad("10.5061/dryad.fxpnvx0tp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
x <- list.files(dir, pattern = "^Black_bear_ursus_dataset\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(x) == 1, setequal(readxl::excel_sheets(x), c("Rupi-bhaba", "Dharanghati")))

areas <- data.table(sheet = c("Rupi-bhaba", "Dharanghati"), code = c("RB", "DH"),
                    area = c("Rupi Bhaba Wildlife Sanctuary", "Daranghati Wildlife Sanctuary"),
                    year = c(2019L, 2018L), n_sites = c(34L, 33L), n_days = c(49L, 40L), n_det = c(20L, 38L))
parts <- lapply(seq_len(nrow(areas)), function(i) {
  a <- areas[i]
  d <- as.data.frame(readxl::read_excel(x, sheet = a$sheet, col_types = "text"))
  stopifnot(names(d)[1] == "site", identical(names(d)[-1], paste0("day_", seq_len(ncol(d) - 1L))),
            nrow(d) == a$n_sites, ncol(d) - 1L == a$n_days, !anyDuplicated(d$site))
  m <- as.matrix(d[, -1]); m[m == "NA"] <- NA
  stopifnot(all(m %in% c("0", "1", NA)))
  y <- matrix(as.integer(m), nrow(m)); dimnames(y) <- NULL
  isna <- is.na(y)
  stopifnot(all(apply(isna, 1, function(r) all(diff(as.integer(r)) >= 0))),   # NA cells are a suffix
            all(rowSums(!isna) >= 1), sum(y, na.rm = TRUE) == a$n_det)
  long <- array_to_eco(y, taxon = "URSTHI", site_ids = paste0(a$code, "_", d$site),
                       site_covs = data.frame(area = rep(a$area, nrow(y)), year = rep(a$year, nrow(y))))
  long[, cluster_id := a$code]
  stopifnot(nrow(long) == sum(!isna))
  long
})
long <- order_eco(rbindlist(parts))
stopifnot(nrow(long) == 1217 + 20 + 1051 + 38, uniqueN(long$unit) == 67, sum(long$y) == 58,
          all(long[, .N, by = unit]$N >= 1), max(long$occasion) == 49)
cat(sprintf("  %d cameras in 2 areas, %d camera-days, %d detections at %d cameras\n",
            uniqueN(long$unit), nrow(long), sum(long$y), uniqueN(long[y == 1, unit])))

taxa <- make_taxa("URSTHI", "Ursus thibetanus", vernacularName = "Asiatic black bear")
taxa[, taxon_iucnCategory := "VU"]
dataset <- list(
  title = "Asiatic black bear camera-trap detection histories, Rupi Bhaba and Daranghati Wildlife Sanctuaries, Himachal Pradesh, 2018-2019",
  creator = "Bhattacharya, Ankita; Chatterjee, Nilanjan; Angrish, Kunal; Meena, Dharamveer; Sinha, Bitapi C.; Habib, Bilal",
  pubDate = "2022", doi = "10.5061/dryad.fxpnvx0tp", sourceURL = "https://doi.org/10.5061/dryad.fxpnvx0tp",
  citation = "Bhattacharya, A., Chatterjee, N., Angrish, K., Meena, D., Sinha, B. C. & Habib, B. (2022). Capture history of Asiatic black bear from Himachal Pradesh, India [Dataset]. Dryad. https://doi.org/10.5061/dryad.fxpnvx0tp. Paper: Ursus 33(e8):1-10, https://doi.org/10.2192/URSUS-D-21-00002.2",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily camera-trap detection (1) / non-detection (0) of Asiatic black bear at 34 camera sites in Rupi Bhaba Wildlife Sanctuary (May-July 2019, up to 49 days) and 33 sites in Daranghati Wildlife Sanctuary (May-July 2018, up to 40 days), Himachal Pradesh, India, from the Wildlife Institute of India survey used to estimate population density with a spatial presence-absence model. Occasions are camera-relative days (day 1 = first deployment day); a camera's history ends when it stopped operating. 58 detections at 27 cameras in 2,326 camera-days.",
  samplingProtocol = "Camera traps at fixed sites, one detection/non-detection record per camera per 24-hour period, May-July; cameras in two protected areas sampled in different years.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day",
  surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "Rupi Bhaba Wildlife Sanctuary and Daranghati Wildlife Sanctuary, Himachal Pradesh, Indian Himalaya (no coordinates deposited)",
  temporalCoverage = "2018-05/2019-07",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit (IUCN VU taxon)"),
  notes = "cluster_id = protected area (RB = Rupi Bhaba, surveyed 2019; DH = Daranghati, surveyed 2018), also unit_area and unit_year; the paper analysed the areas separately. Site numbers repeat across areas and are prefixed with the area code. Day 1 is each camera's first deployment day, not a calendar date, so there is no date column. Survey years come from the paper's abstract; the deposit has no dates.",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bhattacharya_2022_himachal_bear_occ.R")

stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of Asiatic black bear at 67 camera sites in two Himachal Pradesh wildlife sanctuaries (Rupi Bhaba 2019, Daranghati 2018), up to 49 camera-days each; 58 detections in 2,326 camera-days; no coordinates.",
  url = "https://doi.org/10.5061/dryad.fxpnvx0tp",
  reference = "Bhattacharya, A., Chatterjee, N., Angrish, K., Meena, D., Sinha, B. C. & Habib, B. (2022). Population estimation of Asiatic black bear in the Himalayan Region of India using camera traps. Ursus 33(e8), 1-10.",
  doi_paper = "10.2192/URSUS-D-21-00002.2", doi_data = "10.5061/dryad.fxpnvx0tp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Two protected areas sampled in different years, shipped as one table with cluster_id = area. Camera-relative day occasions, no dates. Paper paywalled; abstract used.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (paper: spatial presence-absence model)",
  sampling_protocol = "camera_trap", design = "Single-season (two areas, up to 49 daily occasions)", realm = "Terrestrial", country = "IND",
  coordinates = "None in source", notes = "VU taxon, no coordinates deposited. 58 detections at 27 of 67 cameras.",
  status = "tagged")
