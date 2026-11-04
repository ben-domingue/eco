#!/usr/bin/env Rscript
# Tables: rich_2016_botswana_mamm_binom (coarsened) and rich_2016_botswana_mamm_exact_binom (E7.3
#         sibling without the IUCN EN / VU species)
# Source: Dryad doi:10.5061/dryad.q54rp, version 1 (2016-06-03), CC0 1.0 (Dryad; the xlsx carries
#         no licence statement).
#   Rich, L. N., Miller, D. A. W., Robinson, H. S., McNutt, J. W. & Kelly, M. J. (2016). Data from:
#   Using camera trapping and hierarchical occupancy modelling to evaluate the spatial ecology of an
#   African mammal community. Dryad.
# Paper:  Rich et al. (2016). Using camera trapping and hierarchical occupancy modelling to evaluate
#         the spatial ecology of an African mammal community. Journal of Applied Ecology 53(4),
#         1225-1235, doi:10.1111/1365-2664.12650 (Crossref-confirmed; paywalled, abstract used).
# Data:   one xlsx, five sheets, all 221 camera stations in the same order (asserted):
#         CameraLocations (StudySite, Southing, Easting: decimal degrees to 5 places, exact
#         station locations, -19.7 to -19.3 S, 23.5 to 23.9 E); Detections (221 x 44
#         species codes, each cell = number of camera-nights on which the species was photographed,
#         0-26); DetectionCovariates (RdDensity, VegetationDensity, HumansVehicles);
#         PsiCovariates (num.nights 15-33, HumansVehicles [identical to the detection sheet's],
#         DistanceWildlifeArea [km, negative = inside a wildlife area], FloodplainGrassland
#         [proportion], DistanceWater [km]); Species (SppCode, Genus, Species, CommName, Diet,
#         Size). Station codes 1WA (88), 2WA (91), 3LA (42) are the three study blocks. The nights
#         sum to 6,607, the paper's trap nights. The night-level histories are NOT deposited.
#
# Mapping (standard E2 binomial_count, ruling #34; community rule E4.2): one row per station x
#   species (no occasion), unit = station code, taxon = the deposit's 4-letter code, y = nights
#   with a detection, obs_trials = num.nights (nights surveyed), effortColumn = obs_trials;
#   surveyEvidence = deposited_matrix (every station has every species with an explicit count,
#   effort on every row). Covariates, all station-level and as deposited: unit_road_density,
#   unit_vegetation_density, unit_humans_vehicles (detection covariates in the paper),
#   unit_distance_wildlife_area_km, unit_floodplain_grassland, unit_distance_water_km (occupancy
#   covariates). Coordinates: the deposit has exact station locations and the table carries wild
#   dog (EN), elephant (EN), cheetah, lion, leopard, giraffe and hippo (VU), so every station is
#   coarsened to its 0.1-degree cell centre with coarsen_coords() (E7), one unit set serving all
#   44 species; unit_coordinateUncertaintyInMeters carries the half-diagonal.
#   Traits Diet and Size ride in __taxa as taxon_diet, taxon_body_size_class. Nothing dropped.
#   E7.3: rich_2016_botswana_mamm_exact_binom has the 37 species that are not IUCN CR / EN / VU
#   at the deposited station coordinates (5 decimals). Station codes (1WA.1 ...) are not place
#   names, so E7.4 changes nothing. v1.1: closure = none, occasionKind = none (no occasion
#   column), taxonInclusion = recorded (every one of the 44 species is detected somewhere).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "rich_2016_botswana_mamm_binom"
dir <- download_dryad("10.5061/dryad.q54rp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Rich_data.xlsx"); stopifnot(file.exists(f), identical(list.files(dir), "Rich_data.xlsx"))
stopifnot(setequal(excel_sheets(f), c("CameraLocations", "Detections", "DetectionCovariates", "PsiCovariates", "Species")))

loc <- as.data.table(read_excel(f, "CameraLocations"))
det <- as.data.table(read_excel(f, "Detections"))
dc  <- as.data.table(read_excel(f, "DetectionCovariates"))
pc  <- as.data.table(read_excel(f, "PsiCovariates"))
sp  <- as.data.table(read_excel(f, "Species"))

# --- source facts ---------------------------------------------------------------------------
stopifnot(nrow(loc) == 221, nrow(det) == 221, nrow(dc) == 221, nrow(pc) == 221, nrow(sp) == 44)
stopifnot(!anyDuplicated(loc$StudySite), identical(det$StudySite, loc$StudySite),
          identical(dc$StudySite, loc$StudySite), identical(pc$StudySite, loc$StudySite))
stopifnot(identical(as.vector(table(sub("\\..*", "", loc$StudySite))), c(88L, 91L, 42L)))     # blocks 1WA, 2WA, 3LA
stopifnot(all(loc$Southing > -19.8 & loc$Southing < -19.2), all(loc$Easting > 23.4 & loc$Easting < 24),
          nrow(unique(loc[, .(Southing, Easting)])) == 221)                                   # exact, distinct station locations
stopifnot(setequal(names(det)[-1], sp$SppCode), !anyDuplicated(sp$SppCode), ncol(det) == 45)
m <- as.matrix(det[, -1]); stopifnot(!anyNA(m), all(m == round(m)), all(m >= 0), max(m) == 26)
stopifnot(!anyNA(pc$num.nights), all(pc$num.nights == round(pc$num.nights)), min(pc$num.nights) == 15,
          max(pc$num.nights) == 33, sum(pc$num.nights) == 6607)                                  # paper: 6,607 trap nights
stopifnot(all(sweep(m, 1, pc$num.nights, "<=")))                                               # y <= nights everywhere
stopifnot(identical(dc$HumansVehicles, pc$HumansVehicles))                                     # one covariate, listed twice
stopifnot(!anyNA(dc), !anyNA(pc), all(sp$Diet %in% c("Carnivore", "Omnivore", "Herbivore")),
          all(sp$Size %in% c("Small", "Medium", "Large", "Xlarge")))
cat(sprintf("  %d stations x %d species, %d camera-nights, %d station-species detections\n",
            nrow(det), nrow(sp), sum(pc$num.nights), sum(m > 0)))

# --- the table: station x species, y = nights with a detection out of obs_trials -------------
long <- melt(det, id.vars = "StudySite", variable.name = "taxon", value.name = "y", variable.factor = FALSE)
setnames(long, "StudySite", "unit")
long <- merge(long, pc[, .(unit = StudySite, obs_trials = as.integer(num.nights),
                           unit_humans_vehicles = HumansVehicles, unit_distance_wildlife_area_km = DistanceWildlifeArea,
                           unit_floodplain_grassland = FloodplainGrassland, unit_distance_water_km = DistanceWater)], by = "unit")
long <- merge(long, dc[, .(unit = StudySite, unit_road_density = RdDensity, unit_vegetation_density = VegetationDensity)], by = "unit")
cc <- coarsen_coords(loc$Southing, loc$Easting)
stopifnot(length(unique(paste(cc$lat, cc$lon))) < 221)                                        # cells pool stations
long_exact <- merge(copy(long), data.table(unit = loc$StudySite, unit_decimalLatitude = loc$Southing, unit_decimalLongitude = loc$Easting), by = "unit")
long <- merge(long, data.table(unit = loc$StudySite, unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                               unit_coordinateUncertaintyInMeters = cc$uncertainty_m), by = "unit")
long[, y := as.integer(y)]
long <- order_eco(long)
stopifnot(nrow(long) == 221 * 44, sum(long$y) == sum(m), all(long$y <= long$obs_trials), !"occasion" %in% names(long))

# --- taxa with traits; IUCN categories for the flagged species (IUCN Red List, as of 2026) ----
iucn <- c(LYPI = "EN", LOAF = "EN", ACJU = "VU", PALE = "VU", PAPA = "VU", GICA = "VU", HIAM = "VU", HYBR = "NT", EQBU = "NT")
stopifnot(all(names(iucn) %in% sp$SppCode))
flagged <- names(iucn)[iucn %in% c("CR", "EN", "VU")]
stopifnot(length(flagged) == 7)
long_exact[, y := as.integer(y)]
long_exact <- order_eco(long_exact[!taxon %in% flagged])
stopifnot(nrow(long_exact) == 221 * 37)
sci <- paste(sp$Genus, sp$Species)
stopifnot("Equus burchelli" %in% sci)   # source spelling; GBIF strict match is FUZZY on it, EXACT on burchellii (a synonym of E. quagga)
taxa <- make_taxa(sp$SppCode, sci, lookupName = sub("^Equus burchelli$", "Equus burchellii", sci), vernacularName = gsub("\\.", " ", sp$CommName),
                  taxon_diet = sp$Diet, taxon_body_size_class = sp$Size,
                  taxon_iucnCategory = unname(iucn[sp$SppCode]))
stopifnot(nrow(taxa) == 44)

emit <- function(TABLE, lg, tx, exact) {
  dataset <- list(
    title = sprintf("Camera-trap detections of %d mammal species%s at 221 stations in northern Botswana: nights with a detection out of nights surveyed (binomial counts), with body-size and diet traits", nrow(tx), if (exact) " (without IUCN EN/VU species, coordinates as deposited)" else ""),
    creator = "Rich, Lindsey N.; Miller, David A. W.; Robinson, Hugh S.; McNutt, J. Weldon; Kelly, Marcella J.",
    pubDate = "2016", doi = "10.5061/dryad.q54rp", sourceURL = "https://doi.org/10.5061/dryad.q54rp",
    citation = "Rich, L. N., Miller, D. A. W., Robinson, H. S., McNutt, J. W., & Kelly, M. J. (2016). Data from: Using camera trapping and hierarchical occupancy modelling to evaluate the spatial ecology of an African mammal community [Data set]. Dryad. https://doi.org/10.5061/dryad.q54rp",
    paperDOI = "10.1111/1365-2664.12650",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = paste0("Camera-trap survey of the terrestrial mammal community of northern Botswana (Okavango region; three study blocks coded 1WA, 2WA, 3LA) by Rich et al. (2016): 221 camera stations run for 15-33 nights each (6,607 trap nights), 44 mammal species. The deposit gives, for each station and species, the number of camera-nights with at least one photograph and the number of nights the station operated; the night-level histories were not deposited. The table is therefore one row per station x species with y = nights with a detection and obs_trials = nights surveyed (responseType binomial_count, ruling #34), the binomial form the authors' multi-species occupancy model used. Station covariates as deposited: road density, vegetation density, humans and vehicles per station (detection covariates in the paper), distance to the nearest wildlife area (km, negative inside), proportion floodplain grassland, distance to water (km). Species traits (diet: carnivore / omnivore / herbivore; body size: small / medium / large / extra-large), the authors' grouping variables, are in the taxa side table. ", if (exact) "This table omits the seven EN and VU species (wild dog, elephant, cheetah, lion, leopard, giraffe, hippo) so that the exact station coordinates ship as deposited; rich_2016_botswana_mamm_binom has all 44 species with coarsened coordinates." else "Station coordinates are coarsened to 0.1-degree cells here because the community includes EN and VU species; the deposit has exact locations (rich_2016_botswana_mamm_exact_binom has the other 37 species at them)."),
    samplingProtocol = "Unbaited passive camera-trap stations across protected wildlife areas and adjoining non-protected land in northern Botswana, each run for 15-33 consecutive nights; species identified from photographs; detections collapsed by the authors to camera-nights with a detection per station and species (Rich et al. 2016, J Appl Ecol 53:1225-1235).",
    samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
    surveyEvidenceNote = "Every station has an explicit count for all 44 species and a nights-surveyed value (num.nights, 15-33) on the PsiCovariates sheet; obs_trials carries it on every row. Which nights the camera ran is not deposited, so there is no occasion.",
    effortColumn = "obs_trials",
    responseType = "binomial_count", unitKind = "site",
    closure = "none", occasionKind = "none", taxonInclusion = "recorded",
    closureNote = "single season (one deployment of 15-33 nights per station; occupancy assumed constant within it)",
    geographicCoverage = paste0("Northern Botswana, Okavango Delta region (Ngamiland), roughly 19.3-19.7 S, 23.5-23.9 E: protected wildlife areas and adjoining non-protected land; station coordinates ", if (exact) "as deposited" else "coarsened to 0.1-degree cells"),
    temporalCoverage = "one deployment of 15-33 nights per station; the survey year is not stated in the deposit or the open abstract (paper published 2016-04)",
    crs = "EPSG:4326",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "As deposited (5 decimal places): the IUCN EN/VU species (Lycaon pictus, Loxodonta africana, Acinonyx jubatus, Panthera leo, Panthera pardus, Giraffa camelopardalis, Hippopotamus amphibius) are not in this table (E7.3)") else list(value = TRUE, method = "0.1-degree grid cell centre (coarsen_coords), applied to all 221 stations because the table carries IUCN EN/VU taxa (Lycaon pictus, Loxodonta africana EN; Acinonyx jubatus, Panthera leo, Panthera pardus, Giraffa camelopardalis, Hippopotamus amphibius VU); the deposit has exact station coordinates to 5 decimal places"),
    designNote = "First binomial_count table under ruling #34 (E2, E9): the authors deposited the sufficient statistic of a constant-p detection model (nights with a detection out of nights surveyed) rather than the night-level history. Community rule E4.2 holds: every species at all 221 stations.",
    notes = "HumansVehicles appears on both covariate sheets with identical values and is shipped once. DistanceWildlifeArea is negative for stations inside a wildlife area (the paper's sign convention). The deposit carries no dates and the survey year is only in the paywalled methods. taxon_iucnCategory is filled for the CR/EN/VU/NT species only.",
    notShipped = if (exact) list(`EN and VU species` = "LYPI, LOAF, ACJU, PALE, PAPA, GICA, HIAM: in rich_2016_botswana_mamm_binom only, whose coordinates are coarsened") else list())
  ds <- write_table(lg, TABLE, dataset, taxa = tx, script = "data/rich_2016_botswana_mamm_binom.R")

  stage_dict_row(TABLE,
    description = if (exact) "Camera-trap community survey of the 37 mammal species that are not IUCN EN/VU at 221 stations in northern Botswana (Rich et al. 2016): nights with a detection out of nights surveyed per station x species, station covariates, traits; exact station coordinates as deposited." else "Camera-trap community survey of 44 mammal species at 221 stations in northern Botswana (Rich et al. 2016): nights with a detection out of nights surveyed per station x species (binomial counts, 6,607 trap nights), six station covariates, diet and body-size traits per species; coordinates coarsened to 0.1 degree (EN/VU taxa present).",
    url = "https://doi.org/10.5061/dryad.q54rp",
    reference = "Rich, L. N., Miller, D. A. W., Robinson, H. S., McNutt, J. W., & Kelly, M. J. (2016). Using camera trapping and hierarchical occupancy modelling to evaluate the spatial ecology of an African mammal community. Journal of Applied Ecology, 53(4), 1225-1235.",
    doi_paper = "10.1111/1365-2664.12650", doi_data = "10.5061/dryad.q54rp",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = if (exact) "E7.3 sibling of rich_2016_botswana_mamm_binom without the EN/VU species; coordinates as deposited." else "First binomial_count table (ruling #34): night-level histories not deposited, y = nights detected out of obs_trials. Traits (diet, body size class) in __taxa. Exact station coordinates in the deposit coarsened to 0.1 degree (wild dog, elephant EN; cheetah, lion, leopard, giraffe, hippo VU).",
    source_via = "Dryad (version zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season, binomial counts with trait groups)",
    sampling_protocol = "camera_trap", design = "Single-season (221 stations x 15-33 nights collapsed to binomial counts; 3 study blocks)", realm = "Terrestrial",
    country = "BWA", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = "binomial_count (ruling #34); 44 species incl. EN/VU carnivores and megaherbivores; diet and body-size traits in __taxa.", status = "tagged")
}
emit(TABLE, long, taxa, exact = FALSE)
emit("rich_2016_botswana_mamm_exact_binom", long_exact, taxa[!taxon %in% flagged], exact = TRUE)
