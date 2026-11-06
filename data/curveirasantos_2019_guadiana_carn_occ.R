#!/usr/bin/env Rscript
# Table:  curveirasantos_2019_guadiana_carn_occ
# Source: Dryad, doi:10.5061/dryad.36g41fd, version 29977 (published 2020-01-07), licence CC0 1.0 as shown on the
#         Dryad dataset page (asserted from the dataset JSON).
# Paper:  Curveira-Santos, G., Pedroso, N. M., Barros, A. L. & Santos-Reis, M. (2019). Mesocarnivore community
#         structure under predator control: unintended patterns in a conservation context. PLoS ONE 14(1), e0210661.
#         https://doi.org/10.1371/journal.pone.0210661 (open access, PMC6336399). Methods: June to August 2015, 77
#         camera-trap stations on a 1 x 1 km grid along dirt roads across ~80 km2 of five hunting estates in the
#         Guadiana Valley Natural Park, SE Portugal, each run for 24 consecutive days in a two-phase rotation;
#         detections collapsed into 6-day occasions (four per station). Table 1 defines the covariates; Table 2 gives
#         occupied stations per species (red fox 71, feral cat 29, stone marten 17, mongoose 8; asserted).
# Data:   Mesocarnivore_occupancy_GVNP.xlsx, sheet DATA (77 stations): vv1-4 (red fox), fc1-4 (feral cat), mf1-4
#           (stone marten), hi1-4 (Egyptian mongoose) as 0/1/NA; NA at station 71 occasion 2 and station 76
#           occasions 3-4 for every species (asserted). Covariates: Hab (habitat type at the station, 1-3), Forest,
#           MScrb, Grass (proportion cover within 500 m), L_div and Ldiv (two landcover diversity columns; L_div has
#           the paper's Table 1 range 0-0.76 for Simpson's index, Ldiv (0-0.65) is not documented), DistWS (to water,
#           m), Slp_local / Slp_500m (slope, degrees), Ele_local / Ele_500m (elevation, m), Rabbit and Pat (rabbit and
#           red-legged partridge independent records per 100 trap-days at the same camera), DistR (to paved road, m),
#           DistSet (to settlement, m), HEstate (hunting estate 1-5). No coordinates.
# Mapping: single-season community occupancy. unit = Station, taxon = VULVUL / FELCAT / MARFOI / HERICH, occasion =
#   6-day occasion 1-4, y = 0/1. surveyEvidence = deposited_matrix (NA = not surveyed; identical across species).
#   Station covariates are unit_*; Rabbit and Pat are camera capture rates of prey species, not outputs of the
#   carnivore models, so they ship.
#   Not shipped: European badger, common genet and Eurasian otter (photographed, Table 2, but not in the deposit).
#   IUCN: all four LC; no coordinates, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "curveirasantos_2019_guadiana_carn_occ"

dir <- download_dryad("10.5061/dryad.36g41fd", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(list.files(dir), "Mesocarnivore_occupancy_GVNP.xlsx"))
f <- file.path(dir, "Mesocarnivore_occupancy_GVNP.xlsx")
stopifnot(identical(excel_sheets(f), "DATA"))
d <- as.data.table(read_excel(f, "DATA", na = "NA"))
cd <- c(vv = "VULVUL", fc = "FELCAT", mf = "MARFOI", hi = "HERICH")
stopifnot(nrow(d) == 77L, identical(d$Station, as.numeric(1:77)), ncol(d) == 33L,
          identical(names(d)[2:17], as.vector(outer(1:4, names(cd), function(i, s) paste0(s, i)))),
          !anyNA(d[, 18:33]), all(d$Hab %in% 1:3), all(d$HEstate %in% 1:5),
          all(c(d$Forest, d$MScrb, d$Grass) >= 0 & c(d$Forest, d$MScrb, d$Grass) <= 1),
          isTRUE(all.equal(range(d$L_div), c(0, 0.76))), isTRUE(all.equal(range(d$Ldiv), c(0, 0.65))))
arr <- lapply(names(cd), function(s) unname(as.matrix(d[, paste0(s, 1:4), with = FALSE])))
na1 <- is.na(arr[[1]])
stopifnot(all(sapply(arr, function(m) identical(is.na(m), na1))), sum(na1) == 3L,
          identical(which(rowSums(na1) > 0), c(71L, 76L)), all(unlist(arr) %in% c(0, 1, NA)),
          identical(sapply(arr, function(m) sum(rowSums(m, na.rm = TRUE) > 0)), c(71L, 29L, 17L, 8L)))
Y <- array(unlist(arr), dim = c(77, 4, 4), dimnames = list(as.character(d$Station), NULL, unname(cd)))
sc <- d[, .(hab_code = as.integer(Hab), forest_500m = Forest, scrub_500m = MScrb, grass_500m = Grass,
            landcover_div = L_div, landcover_div_alt = Ldiv, dist_water_m = DistWS, slope_local_deg = Slp_local,
            slope_500m_deg = Slp_500m, elev_local_m = Ele_local, elev_500m_m = Ele_500m,
            rabbit_rate_100td = Rabbit, partridge_rate_100td = Pat, dist_road_m = DistR,
            dist_settlement_m = DistSet, hunting_estate = as.integer(HEstate))]
long <- array_to_eco(Y, site_covs = data.frame(sc))
long <- order_eco(long)
stopifnot(nrow(long) == 4L * (77L * 4L - 3L), uniqueN(long$unit) == 77L,
          identical(as.integer(long[, sum(y), by = taxon][match(unname(cd), taxon)]$V1), c(218L, 57L, 23L, 14L)))
long[, y := as.integer(y)]
cat(sprintf("  %d rows; %d station-occasions\n", nrow(long), nrow(long) / 4L))

taxa <- make_taxa(unname(cd), c("Vulpes vulpes", "Felis silvestris catus", "Martes foina", "Herpestes ichneumon"),
                  vernacularName = c("Red fox", "Feral cat", "Stone marten", "Egyptian mongoose"),
                  lookupName = c("Vulpes vulpes", "Felis catus", "Martes foina", "Herpestes ichneumon"),
                  taxonRemarks = c(NA, "the source's 'Felis silvestris catus' (feral or free-roaming domestic cat; all cats without a clear wild morphotype, possible hybrids included, paper Methods); matched on GBIF as Felis catus", NA, NA))

dataset <- list(
  title = "Camera-trap detections of red fox, feral cat, stone marten and Egyptian mongoose at 77 stations over four 6-day occasions, Guadiana Valley Natural Park, Portugal, summer 2015",
  creator = "Curveira-Santos, Gonçalo; Pedroso, Nuno M.; Barros, Ana L.; Santos-Reis, Margarida", pubDate = "2019",
  doi = "10.5061/dryad.36g41fd", sourceURL = "https://doi.org/10.5061/dryad.36g41fd",
  citation = "Curveira-Santos, G., Pedroso, N. M., Barros, A. L., & Santos-Reis, M. (2020). Data from: Mesocarnivore community structure under predator control: unintended patterns in a conservation context [Dataset]. Dryad. https://doi.org/10.5061/dryad.36g41fd",
  paperDOI = "10.1371/journal.pone.0210661",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "77 camera-trap stations on a 1 km grid across five hunting estates with predator control in the Guadiana Valley Natural Park, southeast Portugal, each run for 24 days between June and August 2015. Detection of the four mesocarnivores the authors modelled (red fox, feral cat, stone marten, Egyptian mongoose) per station per 6-day occasion, with landscape, prey (rabbit and partridge camera capture rates) and disturbance covariates.",
  samplingProtocol = "One camera (Moultrie M-990i) per station along dirt roads, ~30 cm above ground, 24 h a day for 24 consecutive days, three photographs per trigger; the deployment split into four 6-day occasions, y = 1 if the species was photographed in the occasion.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "four 6-day occasions of one 24-day deployment per station; the authors assume closure over the 24 days (single-season models). Stations were run in two rotation phases between June and August 2015.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Five hunting estates in the Guadiana Valley Natural Park, near 37.7 N 7.65 W, southeast Portugal (no station coordinates deposited)",
  temporalCoverage = "2015-06/2015-08",
  covariateNote = "unit_hab_code: habitat type at the station, 1-3 as deposited (paper Table 1: forest, shrub, grassland; the code-to-type order is not stated). unit_forest_500m, unit_scrub_500m, unit_grass_500m: proportion cover within 500 m. unit_landcover_div: Simpson's landcover diversity (deposit L_div, the paper's range 0-0.76); unit_landcover_div_alt: the deposit's second, undocumented column Ldiv (0-0.65). unit_dist_water_m, unit_dist_road_m (paved), unit_dist_settlement_m; unit_slope_*_deg and unit_elev_*_m at the station (local, 30 m DEM) and averaged within 500 m. unit_rabbit_rate_100td, unit_partridge_rate_100td: independent camera records of European rabbit and red-legged partridge per 100 trap-days at the station. unit_hunting_estate: estate 1-5.",
  notShipped = list(
    other_species = "European badger (13 captures), common genet (4) and Eurasian otter (4), photographed but not modelled and not in the deposit",
    model_output = "occupancy and detection estimates"),
  notes = "Three station-occasions are not surveyed (station 71 occasion 2; station 76 occasions 3-4), identically for every species.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/curveirasantos_2019_guadiana_carn_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detections of four mesocarnivores (red fox, feral cat, stone marten, Egyptian mongoose) at 77 stations over four 6-day occasions in hunting estates of the Guadiana Valley Natural Park, Portugal, June-August 2015, with habitat, prey and disturbance covariates.",
  url = "https://doi.org/10.5061/dryad.36g41fd",
  reference = "Curveira-Santos, G., Pedroso, N. M., Barros, A. L. & Santos-Reis, M. (2019). Mesocarnivore community structure under predator control: unintended patterns in a conservation context. PLoS ONE 14, e0210661. https://doi.org/10.1371/journal.pone.0210661",
  doi_paper = "10.1371/journal.pone.0210661", doi_data = "10.5061/dryad.36g41fd",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Deposited occupancy matrix for the four modelled species; badger, genet and otter not deposited.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single-season)",
  sampling_protocol = "camera_trap", design = "Single-season (77 stations, four 6-day occasions)",
  realm = "Terrestrial", country = "PRT", coordinates = "None in source",
  notes = "Mesocarnivores under predator control in hunting estates; no coordinates.")
