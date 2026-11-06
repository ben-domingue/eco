#!/usr/bin/env Rscript
# Table:  monterroso_2020_iberia_carniv_comm
# Source: Dryad doi:10.5061/dryad.59zw3r247 (CC0 1.0, as shown on the Dryad page; published
#         2021-03-09). Monterroso, P., Diaz-Ruiz, F., Lukacs, P., Alves, P. & Ferreras, P.
#         Ecological traits and the spatial structure of competitive coexistence among carnivores.
# Paper:  Monterroso, P. et al. (2020). Ecology 101(8): e03059, doi:10.1002/ecy.3059. Camera
#         trapping at multiple study areas in south-western Europe (Iberia); Bayesian
#         multi-species occupancy of a carnivore guild (abstract).
# Data:   DataS1.zip: occ.RData, list y of eight data frames, one per species (ylp Iberian lynx,
#         ymm badger, yvv red fox, yfs wildcat, ymf stone marten, ymmt pine marten, yhi Egyptian
#         mongoose, ygg common genet), each 446 station-seasons (station.season, station (237),
#         study.area (CNP, GVNP, MNP, MNR, PGNP, SANP), season (nonbreeding / breeding)) x 64
#         daily occasions o1..o64, 0/1/NA; det.Covs.RData (per-occasion detection covariates,
#         whose NA pattern does not match the histories; and per station-season on.trail);
#         siteCovs.csv (446 station-seasons: utm_x / utm_y, which hold decimal longitude /
#         latitude, distances to water, settlements and humans, rabbit and rodent trap success,
#         EVI and rabbit / rodent habitat indices); R scripts (fox x five subordinates model).
#         Species codes are the authors' (two-letter Linnaean initials) and are expanded here
#         (the script's comments name fox, wildcat, pine marten, stone marten, mongoose, genet).
#         Quirk: siteCovs.csv is in a different row order (joined by station.season); the NA pattern differs between species in a few cells (4-6 per species).
# Mapping (standard: community occupancy, E9 core): unit = station.season (a station surveyed in
#   the breeding and the nonbreeding season is two units; the deposit gives no year or order);
#   taxon = species code; occasion = day 1..64; y = the cell; unit_station, unit_study_area,
#   unit_season, unit_on_trail; distances and EVI as unit_. Survey evidence: deposited_matrix.
#   A cell NA for any species is dropped for all (ruling 2026-11-06, shared detector; count
#   asserted). Coordinates (E7): Iberian lynx is IUCN VU (EN until 2024), so station coordinates are
#   coarsened to 0.1 degree with coarsen_coords(). Not shipped: rabbit / rodent trap success
#   (from the same cameras' detections), the per-occasion detection covariates (NA pattern does
#   not match), the rabbit / rodent habitat indices derived from those, the model scripts.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "monterroso_2020_iberia_carniv_comm"
dir <- download_dryad("10.5061/dryad.59zw3r247", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^DataS1\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
e <- new.env(); load(file.path(ex, "occ.RData"), envir = e); y <- e$y
d <- new.env(); load(file.path(ex, "det.Covs.RData"), envir = d); tr <- as.data.table(d$detCovs$trail)
sc <- fread(file.path(ex, "siteCovs.csv"))
SP <- c(ylp = "Lynx pardinus", ymm = "Meles meles", yvv = "Vulpes vulpes", yfs = "Felis silvestris", ymf = "Martes foina",
        ymmt = "Martes martes", yhi = "Herpestes ichneumon", ygg = "Genetta genetta")
stopifnot(identical(names(y), names(SP)))
oc <- paste0("o", 1:64)
ss <- as.character(y$yvv$station.season)
stopifnot(length(ss) == 446, !anyDuplicated(ss), all(sapply(y, function(x) identical(as.character(x$station.season), ss))),
          setequal(as.character(sc$station.season), ss), setequal(as.character(tr$station.season), ss),
          !anyDuplicated(sc$station.season), !anyDuplicated(tr$station.season),
          all(sapply(y, function(x) all(as.matrix(x[, oc]) %in% c(0, 1, NA)))), sc[, .(a = uniqueN(utm_x), b = uniqueN(utm_y)), by = station][, all(a == 1 & b == 1)],
          all(sc$utm_x > -10 & sc$utm_x < 4), all(sc$utm_y > 35 & sc$utm_y < 44))
sc <- sc[match(ss, as.character(station.season))]; tr <- tr[match(ss, as.character(station.season))]   # siteCovs and trail are in another order: joined by station.season
NAany <- Reduce(`|`, lapply(y, function(x) is.na(as.matrix(x[, oc]))))
NAall <- Reduce(`&`, lapply(y, function(x) is.na(as.matrix(x[, oc]))))
ndrop <- sum(NAany & !NAall); stopifnot(ndrop == 7)
code <- toupper(paste0(substr(sub(" .*", "", SP), 1, 3), substr(sub(".* ", "", SP), 1, 3))); names(code) <- names(SP)
Y <- array(NA_integer_, dim = c(446, 64, 8), dimnames = list(ss, NULL, unname(code)))
for (k in names(SP)) { m <- as.matrix(y[[k]][, oc]); m[NAany] <- NA; Y[, , code[k]] <- m }
cc <- coarsen_coords(sc$utm_y, sc$utm_x)
ucov <- data.frame(station = as.character(sc$station), study_area = as.character(y$yvv$study.area), season = sc$season, on_trail = tr$on.trail,
                   dist_waterbodies = sc$dst.waterbodies, dist_settlement = sc$dst_settlement, dist_human = sc$dst.human,
                   evi_500m_nonbreeding = sc$EVI500nb, evi_500m_breeding = sc$EVI500b,
                   decimalLatitude = cc$lat, decimalLongitude = cc$lon, coordinateUncertaintyInMeters = cc$uncertainty_m)
long <- array_to_eco(Y, site_ids = ss, site_covs = ucov)
long <- order_eco(long)
stopifnot(nrow(long) == sum(!NAany) * 8)
taxa <- make_taxa(unname(code), unname(SP), vernacularName = c("Iberian lynx", "European badger", "Red fox", "Wildcat", "Stone marten", "Pine marten", "Egyptian mongoose", "Common genet"))
dataset <- list(
  title = "Daily camera-trap detections of eight carnivores at 446 station-seasons in six Iberian study areas",
  creator = "Monterroso, Pedro; Díaz-Ruiz, Francisco; Lukacs, Paul; Alves, Paulo Célio; Ferreras, Pablo", pubDate = "2021",
  doi = "10.5061/dryad.59zw3r247", sourceURL = "https://doi.org/10.5061/dryad.59zw3r247",
  citation = "Monterroso, P., Díaz-Ruiz, F., Lukacs, P., Alves, P., & Ferreras, P. (2021). Ecological traits and the spatial structure of competitive coexistence among carnivores [Dataset]. Dryad. https://doi.org/10.5061/dryad.59zw3r247",
  paperDOI = "10.1002/ecy.3059",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily detection/non-detection of eight carnivores (Iberian lynx, badger, red fox, wildcat, stone and pine martens, Egyptian mongoose, common genet) at 237 camera stations in six study areas of the Iberian Peninsula, each surveyed in a breeding and / or a nonbreeding season (446 station-seasons, up to 64 days), with trail placement, distances to water, settlements and humans, vegetation index and coordinates coarsened to 0.1 degree.",
  samplingProtocol = "Camera-trap stations in six Iberian protected areas, surveyed in the breeding and nonbreeding seasons; detections per species per day, up to 64 days.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "each station-season analysed as a single-season survey", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Six study areas in the Iberian Peninsula (CNP, GVNP, MNP, MNR, PGNP, SANP); coordinates coarsened to 0.1 degree", temporalCoverage = "survey years not stated in the deposit (paper 2020)",
  crs = "EPSG:4326",
  coordinatesCoarsened = list(value = TRUE, method = "station coordinates (deposited in columns named utm_x / utm_y but holding decimal degrees to 5 places) coarsened to the 0.1 degree cell centre with coarsen_coords(): Iberian lynx (IUCN VU, EN until 2024) shares the cameras"),
  notShipped = list(shared_detector = "7 station-day cells NA for some species and not others: dropped for all species (shared detector ruling)",
                    trap_success = "rabbit and rodent trap success and the habitat indices built on them (from the same cameras)",
                    detection_covariates = "det.Covs per-occasion covariates: NA pattern does not match the histories",
                    exact_coordinates = "station coordinates finer than 0.1 degree"),
  notes = "unit is the station-season (C03a = nonbreeding, C03w = breeding at station C03); the deposit gives no survey year or which season came first. Species codes expanded by the processor from the authors' two-letter initials (lp, mm, vv, fs, mf, mmt, hi, gg), consistent with the guild named in the scripts.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/monterroso_2020_iberia_carniv_comm.R")
stage_dict_row(TABLE, description = "Daily camera-trap detection/non-detection of eight Iberian carnivores at 446 station-seasons in six study areas, with site covariates; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.59zw3r247",
  reference = "Monterroso, P. et al. (2020). Ecological traits and the spatial structure of competitive coexistence among carnivores. Ecology, 101(8), e03059.",
  doi_paper = "10.1002/ecy.3059", doi_data = "10.5061/dryad.59zw3r247", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy; Iberian lynx present, coordinates coarsened.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season)",
  sampling_protocol = "camera_trap", design = "Single-season (446 station-seasons, up to 64 days)", realm = "Terrestrial",
  country = "ESP,PRT", coordinates = "Coarsened (0.1 deg)", notes = "Carnivore guild incl. Iberian lynx.")
