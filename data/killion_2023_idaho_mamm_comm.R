#!/usr/bin/env Rscript
# Table:  killion_2023_idaho_mamm_comm
# Source: Zenodo doi:10.5281/zenodo.7826340, published 2023-04-13, licence CC BY 4.0 (record metadata licence id
#         "cc-by-4.0", asserted from the cached record JSON).
#   Killion, A., Honda, A., Trout, E. & Carter, N. H. (2023). Species detection histories used in Killion et al.
#   (2023): Integrating Spaceborne Estimates of Structural Diversity of Habitat into Wildlife Occupancy Models
#   [Dataset]. Zenodo.
# Paper:  Killion, A., Honda, A., Trout, E. & Carter, N. H. (2023). Integrating spaceborne estimates of structural
#         diversity of habitat into wildlife occupancy models. Environmental Research Letters 18, 065002.
#         doi:10.1088/1748-9326/acce4d (CC BY 4.0; read on iopscience). Section 2.1: Big Wood River watershed,
#         central Idaho (43.485-43.905 N, 114.067-114.719 W). Section 2.2: cameras deployed 7 July-4 November 2018
#         (44 cameras) and 25 May-27 October 2019 (49 cameras), at least 1 km apart; independent events 2 min
#         apart; "The observation period for modeling was one week ... each species had a detection history with
#         88 cameras and 23 weeks."
# Data:   seven CSVs, one per species, each 88 rows x 23 week columns (week1-week23), first column the camera-year
#         ("<station>_18" or "_19"): bear_det_hist.csv (Ursus americanus), coyo_det_hist.csv (Canis latrans),
#         deer_det_history.csv (Odocoileus hemionus), elk_det_history.csv (Cervus canadensis), moli_det_history.csv
#         (Puma concolor), moos_det_history.csv (Alces alces), wolf_det_history.csv (Canis lupus). Cells 0/1/NA; the
#         NA pattern is identical across the seven files (asserted): NA = camera not operating that week. 40 camera
#         names end in _18 and 48 in _19 (the paper says 44 and 49 cameras were deployed); 38 station names occur
#         in both years. No covariates or coordinates deposited; week numbers are not mapped to dates in the
#         deposit (2018 cameras operate in weeks 7-23, 2019 cameras in weeks 1-22).
# Mapping: unit = station (camera name without the year suffix), period = year (1 = 2018, 2 = 2019), occasion = the
#   deposited week index, taxon = the seven species codes, y = week detection 0/1. The authors fitted single-season
#   models stacking camera-years as sites; the same station name in both years is taken as one station (the
#   name is the deposit's only key). surveyEvidence = deposited_matrix (NA distinct from 0, identical across
#   species). taxonInclusion = target: the seven species the authors modelled; other species photographed were
#   not deposited.
#   Not shipped: the GEDI structural-diversity covariates and occupancy estimates (not deposited / model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "killion_2023_idaho_mamm_comm"
REC <- "7826340"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
sp <- data.table(file = c("bear_det_hist.csv", "coyo_det_hist.csv", "deer_det_history.csv", "elk_det_history.csv",
                          "moli_det_history.csv", "moos_det_history.csv", "wolf_det_history.csv"),
                 taxon = c("URSAME", "CANLAT", "ODOHEM", "CERCAN", "PUMCON", "ALCALC", "CANLUP"),
                 sci = c("Ursus americanus", "Canis latrans", "Odocoileus hemionus", "Cervus canadensis", "Puma concolor", "Alces alces", "Canis lupus"),
                 vern = c("American black bear", "Coyote", "Mule deer", "Elk", "Mountain lion", "Moose", "Grey wolf"),
                 ndet = c(124L, 132L, 718L, 237L, 22L, 44L, 25L))
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.7826340"), setequal(meta$files$key, sp$file))
W <- paste0("week", 1:23)
L <- lapply(sp$file, function(f) { d <- fread(zen(f)); setnames(d, 1, "cam"); stopifnot(identical(names(d), c("cam", W)), nrow(d) == 88L); d[order(cam)] })
na0 <- is.na(as.matrix(L[[1]][, ..W]))
for (i in seq_along(L)) {
  m <- as.matrix(L[[i]][, ..W])
  stopifnot(identical(L[[i]]$cam, L[[1]]$cam), identical(is.na(m), na0), all(m %in% c(0L, 1L, NA)), sum(m, na.rm = TRUE) == sp$ndet[i])
}
stopifnot(sum(!na0) == 1221L, all(grepl("_1[89]$", L[[1]]$cam)), sum(grepl("_18$", L[[1]]$cam)) == 40L,
          all(rowSums(!na0) > 0))
long <- rbindlist(lapply(seq_along(L), function(i) {
  x <- melt(L[[i]], id.vars = "cam", measure.vars = W, variable.name = "w", value.name = "y")[!is.na(y)]
  x[, `:=`(taxon = sp$taxon[i], occasion = as.integer(sub("week", "", w)))][, w := NULL] }))
long[, `:=`(unit = sub("_1[89]$", "", cam), period = ifelse(grepl("_18$", cam), 1L, 2L), y = as.integer(y))][, cam := NULL]
stopifnot(uniqueN(long$unit) == 50L, long[, uniqueN(period), by = unit][V1 == 2, .N] == 38L)
long <- order_eco(long)
stopifnot(nrow(long) == 1221L * 7L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))

taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$vern)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# GBIF's backbone accepts Cervus elaphus for this key, so iucn_category() declines; the cached IUCN record is the
# assessment of Cervus canadensis itself (LEAST_CONCERN), the name the source uses
stopifnot(is.na(taxa[taxon == "CERCAN", taxon_iucnCategory]),
          identical(fromJSON(file.path(GBIF_DIR, "iucn_8600904.json"))$code, "LC"),
          identical(fromJSON(file.path(GBIF_DIR, "iucn_8600904.json"))$scientificName, "Cervus canadensis Erxleben, 1777"))
taxa[taxon == "CERCAN", taxon_iucnCategory := "LC"]
stopifnot(all(taxa$taxon_iucnCategory == "LC"))
print(taxa[, .(taxon, scientificName, gbifMatchType, taxon_iucnCategory)])
periods <- data.table(period = 1:2, year = 2018:2019, start = c("2018-07-07", "2019-05-25"), end = c("2018-11-04", "2019-10-27"),
                      cameras_paper = c(44L, 49L), camera_days_paper = c(2704L, 5900L))

dataset <- list(
  title = "Weekly camera-trap detections of seven mammals at 88 camera-years (50 stations), Big Wood River watershed, central Idaho, 2018-2019",
  creator = "Killion, Alexander; Honda, Arata; Trout, Edward; Carter, Neil H.",
  pubDate = "2023", doi = "10.5281/zenodo.7826340", sourceURL = "https://doi.org/10.5281/zenodo.7826340",
  citation = "Killion, A., Honda, A., Trout, E., & Carter, N. H. (2023). Species detection histories used in Killion et al. (2023): Integrating Spaceborne Estimates of Structural Diversity of Habitat into Wildlife Occupancy Models [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.7826340",
  paperDOI = "10.1088/1748-9326/acce4d",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Camera traps in the Big Wood River watershed of central Idaho in summer and autumn 2018 and 2019, at stations at least 1 km apart, with weekly detection histories for American black bear, coyote, mule deer, elk, mountain lion, moose and grey wolf. The authors used them in single-species occupancy models with habitat structure from GEDI spaceborne lidar.",
  samplingProtocol = "Infrared-triggered cameras on trees or stumps about 1 m above ground, 1-5 m from a trail or feature; 7 July-4 November 2018 and 25 May-27 October 2019; independent events 2 min apart; a species detected in a week is a detection for that week.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "open",
  closureNote = "Weekly occasions over a season of up to 23 weeks; the authors model use (occupancy as habitat use). The two years are periods; 38 station names appear in both years and are taken as the same station.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Big Wood River watershed, central Idaho, USA (43.485-43.905 N, 114.067-114.719 W; no station coordinates deposited)",
  temporalCoverage = "2018-07/2019-10",
  notShipped = list(
    other_species = "species photographed other than the seven the authors modelled are not in the deposit",
    camera_counts = "the deposit has 40 cameras in 2018 and 48 in 2019, the paper reports 44 and 49 deployed; the missing cameras are not in the deposit",
    model_output = "the GEDI covariates and the occupancy estimates (not deposited; model output)"),
  notes = "Week numbers are as deposited (2018 cameras run in weeks 7-23, 2019 in weeks 1-22); the deposit gives no calendar date for a week.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/killion_2023_idaho_mamm_comm.R")
stage_dict_row(TABLE,
  description = "Weekly camera-trap detection histories of seven large mammals (black bear, coyote, mule deer, elk, mountain lion, moose, grey wolf) at 50 stations in central Idaho, 2018-2019.",
  url = "https://doi.org/10.5281/zenodo.7826340",
  reference = "Killion, A., Honda, A., Trout, E. & Carter, N. H. (2023). Integrating spaceborne estimates of structural diversity of habitat into wildlife occupancy models. Environmental Research Letters 18, 065002. https://doi.org/10.1088/1748-9326/acce4d",
  doi_paper = "10.1088/1748-9326/acce4d", doi_data = "10.5281/zenodo.7826340",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Seven per-species matrices with an identical NA pattern merged into one community table.",
  source_via = "Zenodo (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (seven target species)",
  sampling_protocol = "camera_trap", design = "Multi-season (2 years, up to 23 weekly occasions)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Station identity across years from the camera name.")
