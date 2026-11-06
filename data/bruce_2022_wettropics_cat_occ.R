#!/usr/bin/env Rscript
# Table:  bruce_2022_wettropics_cat_occ
# Source: Dryad, doi:10.5061/dryad.2v6wwpzq4, version 184115 (published 2022-06-21), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API). Bruce, T., Williams, S., Amin, R., L'Hotellier, F. & Hirsch, B. Laying
#         low: Rugged lowland rainforest preferred by feral cats in the Australian wet tropics [Dataset].
# Paper:  Bruce, T., Williams, S. E., Amin, R., L'Hotellier, F. & Hirsch, B. T. (2022). Laying low: Rugged lowland
#         rainforest preferred by feral cats in the Australian Wet Tropics. Ecology and Evolution 12: e9105.
#         doi:10.1002/ece3.9105 (open access, PMC9277418, read). Design: 108 camera-trap pairs (one camera facing a
#         road or track, one 50 m into the forest; treated as one site) in seven study areas of the Wet Tropics,
#         April 2019 - July 2020, at least six weeks per area (Table 1 gives each area's start and end dates);
#         detection histories of independent feral cat captures built with camtrapR, a 5-day sampling occasion,
#         an occasion kept if either camera ran 3 days or more; single-season occupancy (site use) in unmarked.
# Data:   Feral_cat_Pres_abs_DRYAD_FINAL.csv: Site_num (1..108, 90 present) x o1..o19 (o19 empty); 1 detected, 0 not, NA = the
#           site was not active for most of the occasion (< 3 days; readme).
#         Obs_Covs_DRYAD.csv: Site_num x Effort_1..Effort_19, survey effort (camera-days of both cameras in the
#           occasion; paper section 2.4) scaled (z-scores as deposited); NA exactly where the detection cell is NA
#           (asserted).
#         Site_Covs_DRYAD.csv: Site_num, DEM_mean (elevation, m), Integ (forest integrity), Low_veg (understorey
#           < 5 m), Frag (fragmentation), Hum_dist (distance to nearest human population), Precip (mean annual
#           precipitation), Rugged (terrain ruggedness index), Int_Herb (invasive herbivore trapping rate), Biomass
#           (prey biomass index), Fire (fire regime), RD_Width (road width at the camera, m), Habitat (RF / EUC),
#           Park (study area code). Unscaled. Sources in the paper's Table S1 (not read).
#         Dryad_Laying_Low_FC_AWT.html: the authors' R markdown (read as text: unmarkedFrameOccu(y, siteCovs,
#           obsCovs = Effort); 90 sites, 911 non-NA cells, 284 detections, 63 sites with a detection).
# Mapping (single-season occupancy; responseType detection, unitKind site): unit = Site_num, taxon = FELCAT,
#   occasion = 5-day occasion 1..19, y = the deposited 0/1; no period (each site was deployed once).
#   surveyEvidence = deposited_matrix (NA = not surveyed, no row). obs_effort_scaled = the deposited scaled effort.
#   unit_ covariates as deposited (unscaled); unit_study_area = Park code.
# Not shipped: model estimates; occasion dates (not deposited; Table 1 gives only each study area's span).
#   The 18 Paluma National Park sites of Table 1 (Site_num absent from all three files) are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bruce_2022_wettropics_cat_occ"
dir <- download_dryad("10.5061/dryad.2v6wwpzq4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Feral_cat_Pres_abs_DRYAD_FINAL.csv", "Site_Covs_DRYAD.csv", "Obs_Covs_DRYAD.csv",
                                      "README.txt", "Dryad_Laying_Low_FC_AWT.html")))
y <- fread(file.path(dir, "Feral_cat_Pres_abs_DRYAD_FINAL.csv"))
e <- fread(file.path(dir, "Obs_Covs_DRYAD.csv"))
s <- fread(file.path(dir, "Site_Covs_DRYAD.csv"))
stopifnot(identical(names(y), c("Site_num", paste0("o", 1:19))), identical(names(e), c("Site_num", paste0("Effort_", 1:19))),
          identical(names(s), c("Site_num", "DEM_mean", "Integ", "Low_veg", "Frag", "Hum_dist", "Precip", "Rugged",
                                "Int_Herb", "Biomass", "Fire", "RD_Width", "Habitat", "Park")),
          nrow(y) == 90L, identical(y$Site_num, e$Site_num), identical(y$Site_num, s$Site_num), !anyDuplicated(y$Site_num),
          all(y$Site_num %in% 1:108))
Y <- unname(as.matrix(y[, -1])); E <- unname(as.matrix(e[, -1]))
stopifnot(all(Y %in% c(0L, 1L, NA)), identical(is.na(Y), is.na(E)), all(rowSums(!is.na(Y)) >= 1),
          sum(!is.na(Y)) == 911L, sum(Y, na.rm = TRUE) == 284L, all(is.na(Y[, 19])), sum(apply(Y, 1, max, na.rm = TRUE)) == 63L)
stopifnot(!anyNA(s), setequal(s$Habitat, c("RF", "EUC")), sum(s$Habitat == "RF") == 40L,
          identical(as.vector(table(s$Park)[c("BF", "KIR", "KOM", "MZT", "TUM", "WOO")]), c(6L, 18L, 18L, 13L, 17L, 18L)))

long <- rbindlist(lapply(1:19, function(j) { k <- !is.na(Y[, j])
  data.table(unit = as.character(y$Site_num[k]), taxon = "FELCAT", y = Y[k, j], occasion = j, obs_effort_scaled = E[k, j]) }))
uc <- s[, .(unit = as.character(Site_num), unit_elevation_m = DEM_mean, unit_forest_integrity = Integ,
            unit_understorey_veg = Low_veg, unit_fragmentation = Frag, unit_dist_human_population = Hum_dist,
            unit_annual_precip = Precip, unit_ruggedness = Rugged, unit_invasive_herbivore_rate = Int_Herb,
            unit_prey_biomass_index = Biomass, unit_fire = Fire, unit_road_width_m = RD_Width,
            unit_habitat = Habitat, unit_study_area = Park)]
long <- order_eco(merge(long, uc, by = "unit"))
stopifnot(nrow(long) == 911L, uniqueN(long$unit) == 90L)

taxa <- make_taxa("FELCAT", "Felis catus", vernacularName = "Feral cat")
taxa[, taxonRemarks := "Introduced in Australia"]

dataset <- list(
  title = "Feral cat detections in 5-day occasions at 90 paired camera-trap sites in the Australian Wet Tropics, 2019-2020",
  creator = "Bruce, Tom; Williams, Stephen; Amin, Rajan; L'Hotellier, Felicity; Hirsch, Ben", pubDate = "2022-06-21",
  doi = "10.5061/dryad.2v6wwpzq4", paperDOI = "10.1002/ece3.9105", sourceURL = "https://doi.org/10.5061/dryad.2v6wwpzq4",
  citation = "Bruce, T., Williams, S., Amin, R., L'Hotellier, F., & Hirsch, B. (2022). Laying low: Rugged lowland rainforest preferred by feral cats in the Australian wet tropics [Dataset]. Dryad. https://doi.org/10.5061/dryad.2v6wwpzq4",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Paired camera traps (one on a road or track, one 50 m into the forest) at sites in six study areas of the Australian Wet Tropics, 2019-2020, surveyed for at least six weeks; feral cat detection per 5-day occasion with survey effort and site covariates (elevation, ruggedness, habitat, road width, fragmentation, prey and invasive herbivore indices). The authors fitted single-season occupancy (site use) models.",
  samplingProtocol = "At each site a camera facing a road or track and a second camera 50 m into the forest, unbaited, run for at least six weeks; independent feral cat captures from either camera summarised into 5-day occasions; an occasion is kept if either camera ran 3 days or more.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "single deployment per site (six weeks or more); the authors interpret occupancy as site use because cats range over several sites",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Australian Wet Tropics, Queensland, Australia (Wooroonooran, Koombooloomba-Tully Falls and Kirrama National Parks, Tumoulin State Forest, a Paluma cattle property, Mount Zero-Taravale Wildlife Sanctuary); no coordinates deposited",
  temporalCoverage = "2019-04/2020-07",
  effortColumn = "obs_effort_scaled",
  covariateNote = "obs_effort_scaled: camera-days of both cameras in the occasion, scaled (z-score) as deposited. unit_ covariates unscaled as deposited (sources in the paper's Table S1): elevation (m), forest integrity, understorey vegetation < 5 m, fragmentation, distance to nearest human population, mean annual precipitation, terrain ruggedness index, invasive herbivore trapping rate, prey biomass index, fire regime, road width (m), habitat (RF rainforest, EUC eucalypt), study area code (BF Paluma cattle property, KIR Kirrama, KOM Koombooloomba, MZT Mount Zero-Taravale, TUM Tumoulin, WOO Wooroonooran).",
  notShipped = list(model_output = "occupancy and detection estimates", dates = "occasion dates are not deposited (the paper's Table 1 gives each study area's survey span)",
                    paluma_np = "the 18 Paluma National Park sites of the paper's Table 1 are not in the deposit (Site_num 1..108 with 90 present)"),
  notes = "Occasions are 5-day windows from each site's deployment; an occasion with under 3 active camera-days is not surveyed (no row).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bruce_2022_wettropics_cat_occ.R")
stage_dict_row(TABLE,
  description = "Feral cat detection per 5-day occasion at 90 paired road and forest camera-trap sites across six study areas of the Australian Wet Tropics, 2019-2020, with effort and habitat covariates.",
  url = "https://doi.org/10.5061/dryad.2v6wwpzq4",
  reference = "Bruce, T., Williams, S. E., Amin, R., L'Hotellier, F., & Hirsch, B. T. (2022). Laying low: Rugged lowland rainforest preferred by feral cats in the Australian Wet Tropics. Ecology and Evolution, 12, e9105.",
  doi_paper = "10.1002/ece3.9105", doi_data = "10.5061/dryad.2v6wwpzq4", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "NA cells (< 3 active days) not surveyed; effort scaled as deposited; no coordinates.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy", sampling_protocol = "camera_trap",
  design = "Single-season (up to 18 five-day occasions; 90 sites)", realm = "Terrestrial", country = "AUS",
  coordinates = "None in source", notes = "Introduced predator in tropical rainforest.")
