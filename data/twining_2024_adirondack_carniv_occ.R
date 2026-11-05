#!/usr/bin/env Rscript
# Table:  twining_2024_adirondack_carniv_occ
# Source: Dryad, doi:10.5061/dryad.pc866t1rz, version 301294 (version 7, published 2024-06-24), licence
#         CC0 1.0 as shown on the Dryad page. Code: Zenodo doi:10.5281/zenodo.6968397 (not used).
# Paper:  Twining, J. P. et al. (author list as on the article; the deposit lists Twining, Jensen, Fuller,
#         Brazeal). Intraguild interactions and abiotic conditions mediate occupancy of
#         mammalian carnivores: co-occurrence of coyotes, fishers and martens. Oikos.
#         https://doi.org/10.1111/oik.10577
# Data:   7dayoccDetections{coyote,fisher,marten}NZ.csv: 572 site-years (Location x SurveyYear; 195 sites,
#           2016 and 2018 all 195, 2017 182: 13 sites not sampled) x Occasion1..3 (7-day occasions), 0/1,
#           NA = camera not working. Same keys in each file, the fisher file in another row order (rows are
#           matched by key); identical NA pattern across the three species (asserted): 155 NA cells, 13
#           site-years entirely NA. Location is "ADK - nnnn" (Adirondacks) or "TH - nnnn" (Tug Hill).
#         NZ7daycameras.csv / NZ7dayoccbait.csv: camera model (Browning / Reconyx) and bait (Beaver, Deer,
#           Moose, Misc) per occasion, plus Date = deployment date (DD/MM/YYYY). The two files' Date agree
#           except at ADK - 0915 and ADK - 0992 in 2016 (cameras 15/01, bait 27/01); the camera file's date
#           agrees with the ordinal-date file and is used.
#         NZdataJulianDay7dayocc.csv: ordinal date of the first day of each occasion; equals the deployment
#           day-of-year minus 1 for occasion 1 (a 0-based ordinal) and steps by 7 (asserted).
#         NZAvgTempByOcc.csv: mean temperature per occasion, "degrees C" per the README; the values run
#           from -18.7 to 33.2 in January-March in the Adirondacks, which reads as Fahrenheit; shipped as
#           deposited under a neutral name.
#         NZ.3yrcamsite.{6km,15km,20km}.buffer.alllandscapecovariates.csv: 559 site-years each (the 13
#           unsampled-or-failed site-years absent), landcover proportions (NLCD 2019), road density, WSI
#           (winter severity index), elevation, forest edge density, snow depth, GPP; plus columns the
#           README does not describe (FID, random, corerange, deer).
#         README.md.
# Mapping: unit = Location, taxon = CANLAT / PEKPEN / MARAME, period = survey year (1 = 2016 .. 3 = 2018),
#   occasion = 7-day occasion 1..3, y = 0/1. Community rule: all three species carry a row at every
#   working camera-week (identical NA pattern). date = deployment Date + 7 (k - 1).
#   obs_camera, obs_bait, obs_mean_temp_as_deposited. period_* = the 6 km buffer covariates (they vary by
#   year: WSI, snow depth, GPP); unit_region = ADK / TH. surveyEvidence = deposited_matrix.
#   No coordinates in the deposit. All three species are IUCN LC (the fisher set by hand from the IUCN record:
#   iucn_category() returns NE for GBIF's Pekania pennanti key).
#   Not shipped: the 15 km and 20 km buffer covariates (the same layers at wider buffers); the undescribed
#   columns FID, random, corerange, deer; the 0-based ordinal dates (date carries them).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "twining_2024_adirondack_carniv_occ"

dir <- download_dryad("10.5061/dryad.pc866t1rz", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rd <- function(f) fread(file.path(dir, f))
sp <- c(CANLAT = "7dayoccDetectionscoyoteNZ.csv", PEKPEN = "7dayoccDetectionsfisherNZ.csv", MARAME = "7dayoccDetectionsmartenNZ.csv")
D <- lapply(sp, rd)
key <- function(d, a = "Location", b = "SurveyYear") paste(d[[a]], d[[b]])
K <- key(D$CANLAT)
stopifnot(length(K) == 572, !anyDuplicated(K), identical(as.vector(table(D$CANLAT$SurveyYear)), c(195L, 182L, 195L)),
          uniqueN(D$CANLAT$Location) == 195, all(grepl("^(ADK|TH) - [0-9]{4}$", D$CANLAT$Location)))
Y <- lapply(D, function(d) { stopifnot(setequal(key(d), K)); m <- as.matrix(d[match(K, key(d)), paste0("Occasion", 1:3), with = FALSE]); m })
NAp <- is.na(Y$CANLAT)
stopifnot(all(sapply(Y, function(m) identical(is.na(m), NAp))), sum(NAp) == 155, sum(rowSums(NAp) == 3) == 13,
          all(sapply(Y, function(m) all(m %in% c(0L, 1L, NA)))))

ca <- rd("NZ7daycameras.csv"); ba <- rd("NZ7dayoccbait.csv"); te <- rd("NZAvgTempByOcc.csv"); ju <- rd("NZdataJulianDay7dayocc.csv")
al <- function(d, a = "Location", b = "SurveyYear") { stopifnot(setequal(key(d, a, b), K)); d[match(K, key(d, a, b))] }
ca <- al(ca); ba <- al(ba); te <- al(te, "Location.x", "SurveyYear.x"); ju <- al(ju, "Location.x", "SurveyYear.x")
stopifnot(sum(ca$Date != ba$Date) == 2)  # ADK - 0915 and ADK - 0992, 2016: 15/01 (cameras, agrees with the ordinal file) vs 27/01 (bait)
dep <- as.IDate(ca$Date, "%d/%m/%Y")
stopifnot(!anyNA(dep), all(year(dep) == D$CANLAT$SurveyYear), all(month(dep) %in% 1:3),
          all(yday(dep) - 1L == ju$Occ1), all(ju$Occ2 - ju$Occ1 == 7), all(ju$Occ3 - ju$Occ2 == 7))
CAM <- as.matrix(ca[, paste0("Occasion", 1:3), with = FALSE]); BAIT <- as.matrix(ba[, paste0("Occasion", 1:3), with = FALSE])
TEMP <- as.matrix(te[, paste0("Occ", 1:3), with = FALSE])
stopifnot(all(CAM %in% c("Browning", "Reconyx")), all(BAIT %in% c("Beaver", "Deer", "Moose", "Misc")),
          !anyNA(TEMP), min(TEMP) > -19, max(TEMP) < 34)

cv <- rd("NZ.3yrcamsite.6km.buffer.alllandscapecovariates.csv")
stopifnot(nrow(cv) == 559, !anyDuplicated(key(cv)), all(key(cv) %in% K))
keep <- c("Open.Water", "Developed.Open", "Developed.Low", "Developed.Mid", "Developed.High", "Barren", "Deciduous",
          "Coniferous", "Mixed", "Scrub", "Grassland", "Pasture", "Cultivated.Crops", "Woody.Wetlands",
          "Herbaceus.Wetlands", "RoadDen", "WSI", "elevation", "forest.edge", "snowdepth", "GPP")
stopifnot(setequal(names(cv), c("FID", "Location", "SurveyYear", keep, "random", "corerange", "deer")))
cvk <- cv[match(K, key(cv)), keep, with = FALSE]
setnames(cvk, paste0(gsub("[.]", "_", tolower(names(cvk))), "_6km"))

years <- 2016:2018
rows <- data.table(unit = D$CANLAT$Location, period = match(D$CANLAT$SurveyYear, years), dep = dep)
long <- rbindlist(lapply(names(Y), function(s) rbindlist(lapply(1:3, function(k)
  data.table(rows, taxon = s, occasion = k, y = Y[[s]][, k], obs_camera = CAM[, k], obs_bait = BAIT[, k],
             obs_mean_temp_as_deposited = TEMP[, k], cvk)))))
long <- long[!is.na(y)]
long[, date := as.character(dep + 7L * (occasion - 1L))][, dep := NULL]
long[, unit_region := sub(" - .*", "", unit)]
pc <- grep("_6km$", names(long), value = TRUE)
setnames(long, pc, paste0("period_", pc))
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
setorder(long, period, unit, occasion, taxon)
stopifnot(nrow(long) == 3 * (572 * 3 - 155), uniqueN(long$unit) == 195)

taxa <- make_taxa(c("CANLAT", "PEKPEN", "MARAME"), c("Canis latrans", "Pekania pennanti", "Martes americana"),
                  vernacularName = c("Coyote", "Fisher", "American marten"))
# iucn_category() gives NE for the fisher (GBIF key 8631083); the IUCN Red List assesses Pekania pennanti as LC.
stopifnot(identical(unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName)), c("LC", "NE", "LC")))
periods <- data.table(period = 1:3, year = years,
                      period_start = sapply(years, function(y) as.character(min(dep[year(dep) == y]))),
                      period_end = sapply(years, function(y) as.character(max(dep[year(dep) == y]) + 20L)),
                      n_sites_sampled = c(195L, 182L, 195L))

dataset <- list(
  title = "Weekly camera detections of coyote, fisher and American marten at 195 baited camera sites in the Adirondacks and Tug Hill, New York, winters 2016-2018",
  creator = "Twining, Joshua; Jensen, Paul; Fuller, Angela; Brazeal, Jen", pubDate = "2024",
  doi = "10.5061/dryad.pc866t1rz", sourceURL = "https://doi.org/10.5061/dryad.pc866t1rz",
  citation = "Twining, J., Jensen, P., Fuller, A., & Brazeal, J. (2024). Intraguild interactions and abiotic conditions mediate occupancy of mammalian carnivores: co-occurrence of coyotes-fishers-martens [Dataset]. Dryad. https://doi.org/10.5061/dryad.pc866t1rz",
  paperDOI = "10.1111/oik.10577",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Winter camera trap survey of carnivores in New York's Northern Zone (Adirondacks and Tug Hill): one baited camera in each of 195 stratified-random 15-km2 sample units, run for three weeks each January-March of 2016, 2017 (13 units not sampled) and 2018. Detection/non-detection of coyote, fisher and American marten per 7-day occasion, with camera model, bait, temperature and year-specific landscape and winter covariates in a 6 km2 buffer.",
  samplingProtocol = "One camera 1.0-1.5 m up a tree facing a bait station (beaver, deer, moose or other carcass) on the opposite tree, three weeks per winter; detections summarised by 7-day occasion.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "three consecutive weeks within a winter; the authors fit single-season and co-occurrence occupancy models per year",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Adirondack and Tug Hill regions, northern New York, USA (no coordinates deposited)",
  temporalCoverage = sprintf("%s/%s", min(periods$period_start), max(periods$period_end)),
  coordinatesCoarsened = NA,
  covariateNote = "obs_mean_temp_as_deposited is labelled degrees C in the README but runs from -18.7 to 33.2 in January-March, which reads as Fahrenheit; units unverified. period_*_6km are the authors' 6 km2-buffer covariates for the site-year (NLCD 2019 proportions, road density, winter severity index WSI, elevation, forest edge density, SNODAS snow depth, MODIS GPP); NA for the 13 site-years without a covariate row.",
  notShipped = list(
    wider_buffers = "the same covariates in 15 km2 and 20 km2 buffers (alternative scales of the shipped 6 km2 set)",
    undescribed = "covariate columns FID, random, corerange, deer, which the README does not describe",
    ordinal_dates = "NZdataJulianDay7dayocc.csv (0-based ordinal of each occasion start; date carries it)",
    model_output = "occupancy and co-occurrence estimates"),
  notes = "Sites not sampled in 2017 (13) have no 2017 rows; 13 further site-years are entirely NA (camera not working) and also have no rows. The fisher detection file is in a different row order from the other files and is matched by Location and SurveyYear.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/twining_2024_adirondack_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Weekly detection/non-detection of coyote, fisher and American marten at 195 baited winter camera sites in the Adirondacks and Tug Hill, New York, 2016-2018 (3 x 7-day occasions per winter), with bait, camera, temperature and year-specific landscape covariates.",
  url = "https://doi.org/10.5061/dryad.pc866t1rz",
  reference = "Twining, J. P., et al. Intraguild interactions and abiotic conditions mediate occupancy of mammalian carnivores: co-occurrence of coyotes, fishers and martens. Oikos. https://doi.org/10.1111/oik.10577",
  doi_paper = "10.1111/oik.10577", doi_data = "10.5061/dryad.pc866t1rz",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Temperature units as deposited (README says C; values read as F). No coordinates.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-species, co-occurrence)",
  sampling_protocol = "camera_trap", design = "Multi-season (3 winters, 3 weekly occasions)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Baited cameras; three target carnivores.")
