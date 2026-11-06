#!/usr/bin/env Rscript
# Table:  fancourt_2019_aus_catdingo_occ
# Source: Zenodo record 5001772, doi:10.5061/dryad.6hb0063 (the Dryad deposit as served by Zenodo, published
#         2019-11-14; licence as shown on the record: CC0 1.0). Fetched from Zenodo, no Dryad request.
#   Fancourt, B., Cremasco, P., Wilson, C. & Gentle, M. Data from: Do introduced apex predators suppress introduced
#   mesopredators? A multiscale spatiotemporal study of dingoes and feral cats in Australia suggests not.
# Paper:  Journal of Applied Ecology (2019), not read; the record's abstract describes the design (camera traps at a
#         national park and an agricultural site; co-occurrence models of cat and dingo).
# Data:   Cat and dingo detection data.zip: CAT_DINGO_2016_PA_NP.csv and CAT_DINGO_2016_PA_AG.csv: 30 cameras (T01..T30)
#         x 2 species (D dingo, C cat) x 21 (national park) or 22 (agricultural site) days, 0/1, no missing code;
#         NP_ and AG_Temporal Cat and Dingo detections 2016.csv: per-detection time of day (fraction of a day), species
#         and whether dingoes were present at the camera (for the activity-overlap analysis).
#         Asserted: 60 rows per matrix (30 cameras x 2 species), values only 0 / 1, same camera list for both species.
# Mapping: community single-season occupancy (two species). unit = "<site>_<camera>" (NP national park, AG
#   agricultural), cluster_id = site, occasion = day 1..21 / 1..22, taxon = DINGO / CAT, y = detected that day.
#   surveyEvidence deposited_matrix: the matrices have a cell for every camera-day and no not-surveyed code, so every
#   camera is taken to have run every day of its site's deployment (the deposit cannot say otherwise).
# Not shipped: the per-detection times of day (activity data, not a survey of units); no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fancourt_2019_aus_catdingo_occ"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/5001772", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-zero"), identical(rec$doi, "10.5061/dryad.6hb0063"))
zip <- download_cached("https://zenodo.org/api/records/5001772/files/Cat%20and%20dingo%20detection%20data.zip/content", TABLE, "catdingo.zip")
ex <- file.path(dirname(zip), "x"); if (!dir.exists(ex)) unzip(zip, exdir = ex)
rd <- function(site, nd) {
  d <- fread(file.path(ex, sprintf("CAT_DINGO_2016_PA_%s.csv", site)), colClasses = "character", header = TRUE)
  stopifnot(nrow(d) == 60, ncol(d) == 2 + nd, identical(names(d)[-(1:2)], as.character(1:nd)), setequal(d$SPP, c("D", "C")),
            identical(sort(d[SPP == "D", CAM]), sort(d[SPP == "C", CAM])), uniqueN(d$CAM) == 30, all(unlist(d[, -(1:2)]) %in% c("0", "1")))
  m <- melt(d, id.vars = c("CAM", "SPP"), variable.name = "occasion", value.name = "y", variable.factor = FALSE)
  m[, .(unit = paste0(site, "_", CAM), taxon = c(D = "DINGO", C = "CAT")[SPP], y = as.integer(y), occasion = as.integer(occasion), cluster_id = site)]
}
long <- rbind(rd("NP", 21), rd("AG", 22))
stopifnot(nrow(long) == 60 * 21 + 60 * 22, sum(long$y) == 88 + 54)
taxa <- make_taxa(c("DINGO", "CAT"), c("Canis familiaris", "Felis catus"), vernacularName = c("Dingo", "Feral cat"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Daily camera-trap detections of dingoes and feral cats at 60 cameras on a national park and an agricultural property, Australia, 2016",
  creator = "Fancourt, Bronwyn; Cremasco, Peter; Wilson, Cameron; Gentle, Matthew",
  pubDate = "2019", doi = "10.5061/dryad.6hb0063", sourceURL = "https://doi.org/10.5061/dryad.6hb0063",
  citation = "Fancourt, B., Cremasco, P., Wilson, C. & Gentle, M. (2019). Data from: Do introduced apex predators suppress introduced mesopredators? A multiscale spatiotemporal study of dingoes and feral cats in Australia suggests not. Dryad (served by Zenodo), https://doi.org/10.5061/dryad.6hb0063.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Thirty camera traps at each of a national park conserving endangered species and an agricultural (cattle grazing) site recorded dingoes and feral cats daily for three weeks in 2016, to test whether the introduced apex predator suppresses the introduced mesopredator (co-occurrence and activity overlap).",
  samplingProtocol = "Thirty camera traps per site run for 21 (national park) or 22 (agricultural) consecutive days in 2016; a camera-day is a detection of a species when it was photographed that day.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The detection matrices have no not-surveyed code: every camera is taken as operating on every day of its site's deployment.",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion = consecutive days of one deployment.",
  geographicCoverage = "A national park and an agricultural property in Australia (sites not located in the deposit)",
  temporalCoverage = "2016/2016",
  notShipped = list(activity_times = "NP_ and AG_Temporal Cat and Dingo detections 2016.csv: time of day of each detection (activity analysis)"),
  notes = "Two species surveyed at every camera-day. Both are introduced in Australia.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/fancourt_2019_aus_catdingo_occ.R")
stage_dict_row(TABLE,
  description = "Daily detection histories of dingoes and feral cats at 30 camera traps on each of a national park and an agricultural property in Australia, 21-22 days in 2016.",
  url = "https://doi.org/10.5061/dryad.6hb0063",
  reference = "Fancourt, B., Cremasco, P., Wilson, C. & Gentle, M. (2019). Do introduced apex predators suppress introduced mesopredators? A multiscale spatiotemporal study of dingoes and feral cats in Australia suggests not. Journal of Applied Ecology.",
  doi_data = "10.5061/dryad.6hb0063", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Fetched from the Zenodo copy of the Dryad deposit (record 5001772).", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (two-species co-occurrence)", sampling_protocol = "camera_trap",
  design = "Single season (21-22 days)", realm = "Terrestrial", country = "AUS", coordinates = "None in source",
  notes = "Apex predator vs mesopredator co-occurrence; two sites.")
