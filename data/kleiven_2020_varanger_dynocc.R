#!/usr/bin/env Rscript
# Table:  kleiven_2020_varanger_dynocc
# Source: DataverseNO doi:10.18710/ZLW59W (CC0 1.0), version 4 (2023-09-28). Kleiven, E.F. et
#         al. Data and code to replicate "A dynamic occupancy model for interacting species
#         with two spatial scales". Case-study data from the COAT (Climate-ecological
#         Observatory for Arctic Tundra) small-mammal camera-trap programme, Varanger
#         Peninsula, Norway; collection 2015-09-01 to 2020-06-01. Images classified by an
#         automatic classifier (MLWIC) into small rodents / small mustelids.
# Data:   Case_study_data.rda: occm_va[6 sites, 8 blocks, 304 days, 7 seasons] with the
#         four-state observation 1 = none, 2 = rodent, 3 = mustelid, 4 = both, NA = camera
#         not operating / no image that day. Calendar dates of the day index are not in the
#         deposit (seas_2021.rda labels 305 day indices summer/winter for one season; its
#         alignment to the 304-day axis is not stated, so it is not shipped).
# Mapping (standard E1-E5, E9 experimental multi-scale via cluster_id; dynamic co-occurrence
#   occupancy): unit = camera (block_site; 48 positions, those with data), cluster_id = block (the second
#   spatial scale), taxon = RODENT (Rodentia, functional group) and MUSTEL (Mustela, small
#   mustelids), period = season 1..7, occasion = day index 1..304, y = 0/1 per taxon derived
#   from the state (rodent: state 2 or 4; mustelid: 3 or 4), y_raw = the four-state code.
#   surveyEvidence = deposited_matrix. Block 6 has no data in seasons 1-2 (no rows).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "kleiven_2020_varanger_dynocc"

f <- download_cached("https://dataverse.no/api/access/datafile/175350", TABLE, filename = "Case_study_data.rda")
e <- new.env(); load(f, envir = e); x <- e$occm_va
stopifnot(dim(x) == c(6, 8, 304, 7), all(x[!is.na(x)] %in% 1:4))
idx <- which(!is.na(x), arr.ind = TRUE)
obs <- data.table(site = idx[, 1], block = idx[, 2], day = idx[, 3], season = idx[, 4], state = x[idx])
stopifnot(nrow(obs) == sum(!is.na(x)))
obs[, unit := sprintf("B%d_S%d", block, site)]
long <- rbindlist(list(
  obs[, .(unit, taxon = "RODENT", y = as.integer(state %in% c(2L, 4L)), y_raw = state, period = season, occasion = day, cluster_id = sprintf("B%d", block))],
  obs[, .(unit, taxon = "MUSTEL", y = as.integer(state %in% c(3L, 4L)), y_raw = state, period = season, occasion = day, cluster_id = sprintf("B%d", block))]))
long <- order_eco(long)
cat(sprintf("  %d of 48 block x site cameras have data\n", uniqueN(long$unit)))
stopifnot(nrow(long) == 2 * nrow(obs), uniqueN(long$unit) <= 48, long[, .N, by = .(unit, period, occasion)][, all(N == 2)])
periods <- data.table(period = 1:7, n_cameras_active = sapply(1:7, function(t) uniqueN(long[period == t, unit])),
                      note = "calendar bounds not in the deposit; collection 2015-09 to 2020-06")

taxa <- make_taxa(c("RODENT", "MUSTEL"), c("Rodentia", "Mustela"), vernacularName = c("Small rodents (functional group)", "Small mustelids (stoat, least weasel)"),
                  taxonRank = c("order", "genus"))
dataset <- list(
  title = "COAT small-mammal camera traps, Varanger Peninsula: daily detection of small rodents and small mustelids at 48 cameras in 8 blocks over 7 seasons",
  creator = "Kleiven, Eivind Flittie; COAT (Climate-ecological Observatory for Arctic Tundra), UiT The Arctic University of Norway",
  pubDate = "2020", doi = "10.18710/ZLW59W", sourceURL = "https://doi.org/10.18710/ZLW59W",
  citation = "Kleiven, E. F. et al. (2020, v4 2023). Data and code to replicate \"A dynamic occupancy model for interacting species with two spatial scales\" [Data set]. DataverseNO. https://doi.org/10.18710/ZLW59W",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Case-study data for a dynamic occupancy model of interacting species with two spatial scales: daily camera-trap detection of small rodents and small mustelids on the arctic tundra of the Varanger Peninsula, from the COAT long-term monitoring programme. Images were classified by an automatic classifier (MLWIC). The deposited observation is a four-state code (none, rodent, mustelid, both) per camera-day; it is split here into one detection row per functional group with the state kept in y_raw.",
  samplingProtocol = "Camera traps inside small-mammal tunnels (Soininen et al. 2015 design), 6 cameras per block in 8 blocks; daily detection/non-detection of each functional group; seasons of 304 days.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion (within a 304-day season, as the source model assumes)",
  geographicCoverage = "Varanger Peninsula, Troms og Finnmark, Norway (no coordinates deposited)",
  temporalCoverage = "2015-09/2020-06 (seven seasons; day-to-date mapping not in the deposit)",
  coordinatesCoarsened = NA,
  stateCodes = list(`1` = "no detection", `2` = "rodent detected", `3` = "mustelid detected", `4` = "rodent and mustelid detected"),
  notShipped = list(seas_2021 = "summer/winter day labels whose alignment to the day axis is not stated",
                    SimData = "simulated data for the paper's simulation study (not real observations)"),
  designNote = "Two spatial scales: cluster_id = block is the coarse scale of the source model; the 48 cameras are the fine scale. Experimental list of E9 (multi-scale via cluster_id).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/kleiven_2020_varanger_dynocc.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of small rodents and small mustelids (two functional groups) at 48 cameras in 8 blocks on the Varanger Peninsula, Norway, over 7 seasons of 304 days (COAT programme, 2015-2020); the deposited four-state code is kept in y_raw.",
  url = "https://doi.org/10.18710/ZLW59W",
  reference = "Kleiven, E. F. et al. Data and code to replicate \"A dynamic occupancy model for interacting species with two spatial scales\". DataverseNO.",
  doi_data = "10.18710/ZLW59W", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Taxa are functional groups (order / genus rank), not species. Calendar dates of the day index are not deposited. Two-spatial-scale design: cluster_id = block.",
  source_via = "DataverseNO")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic co-occurrence occupancy (two species, two spatial scales)",
  sampling_protocol = "camera_trap", design = "Multi-season (7 seasons x 304 daily occasions)", realm = "Terrestrial", country = "NOR",
  coordinates = "None in source", notes = "Experimental (E9): multi-scale via cluster_id. Automatic image classification. Functional groups, not species.")
