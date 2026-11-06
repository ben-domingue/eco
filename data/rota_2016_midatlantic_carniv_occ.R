#!/usr/bin/env Rscript
# Table:  rota_2016_midatlantic_carniv_occ
# Source: Dryad doi:10.5061/dryad.pq624 (CC0 1.0, as shown on the Dryad page; published
#         2017-05-04). Rota, C.T., Ferreira, M.A.R., Kays, R.W., Forrester, T.D., Kalies, E.L.,
#         McShea, W.J., Parsons, A.W. & Millspaugh, J.J. Data from: A multispecies occupancy
#         model for two or more interacting species.
# Paper:  Rota, C.T. et al. (2016). Methods in Ecology and Evolution 7(10), 1164-1173,
#         doi:10.1111/2041-210X.12587. Camera-trap co-occurrence of bobcat, coyote, grey fox and
#         red fox across six Mid-Atlantic states, eastern USA (the eMammal citizen-science
#         camera survey).
# Data:   Data.zip -> Data/: Bobcat.csv, Coyote.csv, Gray Fox.csv, Red Fox.csv (no header; 1906
#         sites x 71 replicate columns; 1 detected, 0 not, NA "no sampling" (ReadMe.pdf));
#         psi covariates.csv (Dist_5km = proportion disturbed within 5 km 2001-2006, HDens_5km =
#         housing density within 5 km, Latitude and Longitude "in decimal degrees divided by
#         100", People_site = hikers photographed at the site / 1000, Trail = camera on a trail);
#         p covariates.csv (Det_dist = maximum distance in metres at which the camera triggers on
#         a person); Design Matrix.xlsx, model3.R/.stan, Formatting Data.R (the authors' code:
#         a replicate is one camera day, cday = number of non-NA columns).
#         Asserted: the NA pattern is identical for the four species and every site's non-NA
#         cells are its first cday columns (1-71 camera days). No dates are deposited.
# Mapping (standard: community / multi-species occupancy, E9 core; occuMulti): unit = site
#   row (S0001...); taxon = LYNRUF, CANLAT, UROCIN, VULVUL; occasion = camera day 1..cday;
#   y = the cell; NA = no row. Survey evidence: deposited_matrix. unit_: Dist_5km, HDens_5km,
#   Trail, Det_dist (constant per site), latitude/longitude x 100 (decimal degrees, as
#   published; all four species are IUCN LC).
#   Not shipped: People_site, hikers photographed by the same cameras (an index built from the
#   same camera detections, processing guide); the design matrix and model code.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "rota_2016_midatlantic_carniv_occ"
dir <- download_dryad("10.5061/dryad.pq624", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^Data\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "Data")
SP <- c(LYNRUF = "Bobcat", CANLAT = "Coyote", UROCIN = "Gray Fox", VULVUL = "Red Fox")
L <- lapply(SP, function(s) as.matrix(read.csv(file.path(b, paste0(s, ".csv")), header = FALSE)))
na <- is.na(L[[1]])
stopifnot(all(sapply(L, dim) == c(1906, 71)), all(sapply(L, function(m) identical(is.na(m), na))),
          all(sapply(L, function(m) all(m %in% c(0, 1, NA)))))
cday <- rowSums(!na)
stopifnot(all(cday >= 1), all(sapply(seq_len(nrow(na)), function(i) all(!na[i, seq_len(cday[i])]))),
          all(unname(sapply(L, sum, na.rm = TRUE)) == c(429, 1237, 176, 590)))
pc <- read.csv(file.path(b, "psi covariates.csv")); qc <- read.csv(file.path(b, "p covariates.csv"))
stopifnot(nrow(pc) == 1906, nrow(qc) == 1906, identical(names(pc), c("Dist_5km", "HDens_5km", "Latitude", "Longitude", "People_site", "Trail")),
          !anyNA(pc), !anyNA(qc), all(pc$Trail %in% 0:1), all(pc$Latitude * 100 > 34 & pc$Latitude * 100 < 40))
ids <- sprintf("S%04d", seq_len(1906))
Y <- array(unlist(L), dim = c(1906, 71, 4), dimnames = list(ids, NULL, names(SP)))
sc <- data.frame(dist_5km = pc$Dist_5km, housing_density_5km = pc$HDens_5km, trail = pc$Trail,
                 det_dist_m = qc$Det_dist, decimalLatitude = round(pc$Latitude * 100, 7), decimalLongitude = round(pc$Longitude * 100, 7))
long <- array_to_eco(Y, site_ids = ids, site_covs = sc)
stopifnot(nrow(long) == sum(cday) * 4, sum(long$y) == 429 + 1237 + 176 + 590)
taxa <- make_taxa(names(SP), c("Lynx rufus", "Canis latrans", "Urocyon cinereoargenteus", "Vulpes vulpes"),
                  vernacularName = c("Bobcat", "Coyote", "Gray fox", "Red fox"))
dataset <- list(
  title = "Daily camera-trap detections of bobcat, coyote, gray fox and red fox at 1,906 sites in six Mid-Atlantic states, USA",
  creator = "Rota, Christopher T.; Ferreira, Marco A. R.; Kays, Roland W.; Forrester, Tavis D.; Kalies, Elizabeth L.; McShea, William J.; Parsons, Arielle W.; Millspaugh, Joshua J.",
  pubDate = "2017", doi = "10.5061/dryad.pq624", sourceURL = "https://doi.org/10.5061/dryad.pq624",
  citation = "Rota, C. T., Ferreira, M. A. R., Kays, R. W., Forrester, T. D., Kalies, E. L., McShea, W. J., Parsons, A. W., & Millspaugh, J. J. (2017). Data from: A multispecies occupancy model for two or more interacting species [Dataset]. Dryad. https://doi.org/10.5061/dryad.pq624",
  paperDOI = "10.1111/2041-210X.12587",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily detection/non-detection of four carnivores (bobcat, coyote, gray fox, red fox) at 1,906 camera-trap sites across six Mid-Atlantic states of the eastern USA, 1-71 camera days per site, with disturbance, housing density, trail placement, camera detection distance and site coordinates: the input of Rota et al.'s (2016) multispecies occupancy model with interactions.",
  samplingProtocol = "Passive camera traps at sites on and off hiking trails across six Mid-Atlantic states (eMammal survey); each camera day is a replicate survey with detection 0/1 per species.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one deployment per site; the authors' single-season multispecies occupancy", occasionKind = "time",
  taxonInclusion = "target",
  geographicCoverage = "Six Mid-Atlantic states, eastern USA (about 34.5-39.7 N, 76.9-85.4 W); site coordinates as deposited (x 100)",
  temporalCoverage = "survey years not stated in the deposit (paper 2016)", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "as published: the deposit gives decimal degrees / 100 to 7 places, multiplied back by 100; all four species are IUCN LC"),
  notShipped = list(People_site = "hikers photographed per site / 1000, an index from the same camera detections",
                    model_files = "design matrix and Stan/R model code"),
  notes = "occasion is the camera day in deposited order (1..cday per site; no dates deposited). Site ids S0001-S1906 are the deposited row order. Latitude/longitude are the deposit's values x 100.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/rota_2016_midatlantic_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of bobcat, coyote, gray fox and red fox at 1,906 sites in six Mid-Atlantic US states, with site covariates and coordinates.",
  url = "https://doi.org/10.5061/dryad.pq624",
  reference = "Rota, C. T. et al. (2016). A multispecies occupancy model for two or more interacting species. Methods in Ecology and Evolution, 7(10), 1164-1173.",
  doi_paper = "10.1111/2041-210X.12587", doi_data = "10.5061/dryad.pq624", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-species occupancy (occuMulti) input; People_site not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-species occupancy with interactions",
  sampling_protocol = "camera_trap", design = "Single-season (1-71 camera days per site)", realm = "Terrestrial",
  country = "USA", coordinates = "As published", notes = "Four interacting carnivores.")
