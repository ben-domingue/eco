#!/usr/bin/env Rscript
# Table:  whitworth_2019_manu_terr_mamm_binom
# Source: Dryad, doi:10.5061/dryad.32464qs, version 28246 (published 2019-06-28), licence CC0 1.0 as shown on the
#         Dryad dataset page (asserted from the dataset JSON).
# Paper:  Whitworth, A., Beirne, C., Pillco Huarcaya, R., Whittaker, L., Serrano Rojas, S. J., Tobler, M. W. &
#         MacLeod, R. (2019). Human disturbance impacts on rainforest mammals are most notable in the canopy,
#         especially for larger-bodied species. Diversity and Distributions 25(7), 1166-1178.
#         https://doi.org/10.1111/ddi.12930 (CC BY 4.0; the publisher returns 403 to the agent and it is not in
#         Europe PMC, so the design is from the Dryad abstract and file descriptions): arboreal and terrestrial
#         camera traps in the Manu Biosphere Reserve, southeast Peru, along a gradient of forest disturbance.
# Data:   occ_data_ter_6d.txt: 77 terrestrial camera stations x 26 species; the header row lacks the row-name
#           field. Values are, per the authors' JAGS model (y[j,i] ~ dbin(mu.r[j,i], k[j])), the number of six-day
#           sessions with a detection of the species (the Dryad file note says 'independent captures within a
#           six-day window'; every value is <= the station's sessions, asserted).
#         occ_effort_ter_6d.txt: the number of six-day sessions per terrestrial station (9-32).
#         occ_data_arb_6d.txt / occ_effort_arb_6d.txt: the same for 145 arboreal stations x 24 species: HELD, 13 of
#           the 24 arboreal codes (the primates, porcupine_bicolor, squirrel_dwarf) are not in species_data.txt.
#         species_data.txt: 34 codes with body mass (kg), common and Latin name, family, order, IUCN category.
#         station_covariates.txt: 168 station-years (STATION, YEAR 15/16, SITE AGU/DIA/MLC/ROM/SHIN/SHIP,
#           CAM.HEIGHT (arboreal camera), CC, SHRUB, CONN, TREE.DENS, CAN.HEIGHT, CAM.BEARING, ASL, RIV.DIST,
#           FOREST.LOSS, COMM.DIST, UNIQUE (arboreal id), UNIQUE.TER (terrestrial id), SurveyName, FACTOR1/FACTOR2
#           (principal components of the disturbance features)). MSRoyleNicholsMSOccJAGS_X_YEAR.txt: the model.
#         No coordinates deposited.
# Mapping: responseType binomial_count (ruling #34): unit = SITE.STATION (station ids repeat across 2015 and 2016
#   with identical elevation and distances, so they are the same stations resurveyed), period = year (1 = 2015,
#   2 = 2016), taxon = the deposit's species code upper-cased, y = sessions with a detection, obs_trials = sessions.
#   surveyEvidence = effort_table: every station-year in the effort file has >= 9 sessions and a row per species.
#   Covariates: each station covariate is unit_ where it is constant across the station's years, else period_
#   (asserted per column). CAM.HEIGHT describes the arboreal camera and is not shipped in the terrestrial table.
#   FACTOR1/2 are principal components of habitat covariates, not of detections, and ship.
#   IUCN (deposit): tapir, giant armadillo, giant anteater, white-lipped peccary, pacarana VU; no coordinates are
#   deposited, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "whitworth_2019_manu_terr_mamm_binom"
NBOTH <- 9L   # stations surveyed in both years

dir <- download_dryad("10.5061/dryad.32464qs", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 7L)
f <- file.path(dir, "occ_data_ter_6d.txt")
h <- scan(f, what = "", nlines = 1, sep = ",", quiet = TRUE)
d <- fread(f, skip = 1, header = FALSE); setnames(d, c("st", h))
e <- fread(file.path(dir, "occ_effort_ter_6d.txt"), skip = 1, header = FALSE); setnames(e, c("i", "st", "k"))
sp <- fread(file.path(dir, "species_data.txt"))
sc <- fread(file.path(dir, "station_covariates.txt"))
stopifnot(nrow(d) == 77L, length(h) == 26L, identical(d$st, e$st), !anyDuplicated(d$st), all(e$k >= 9L & e$k <= 32L),
          nrow(sp) == 34L, all(h %in% sp$SPECIES), nrow(sc) == 168L, !anyNA(sc), !anyDuplicated(sc$UNIQUE.TER),
          all(d$st %in% sc$UNIQUE.TER), all(grepl("^[A-Z]+\\.[0-9]+\\.1[56]\\.T$", d$st)))
M <- as.matrix(d[, -1])
stopifnot(!anyNA(M), all(M == round(M)), all(M >= 0), all(M <= e$k), all(colSums(M) > 0), sum(M > 0) == 746L)

cv <- sc[match(d$st, UNIQUE.TER)]
stopifnot(identical(cv$UNIQUE.TER, d$st), identical(as.integer(table(cv$YEAR)), c(37L, 40L)))
cv[, unit := paste(SITE, STATION, sep = ".")]
stopifnot(!anyDuplicated(cv[, .(unit, YEAR)]))
covs <- c(cc_pct = "CC", shrub_density = "SHRUB", tree_connectivity = "CONN", tree_density = "TREE.DENS",
          canopy_height_m = "CAN.HEIGHT", cam_bearing_deg = "CAM.BEARING", elev_m = "ASL", dist_river_m = "RIV.DIST",
          forest_loss = "FOREST.LOSS", dist_community_m = "COMM.DIST", disturbance_pc1 = "FACTOR1", disturbance_pc2 = "FACTOR2")
lev <- sapply(covs, function(cn) if (all(cv[, uniqueN(get(cn)), by = unit]$V1 == 1L)) "unit_" else "period_")
stopifnot(lev[["dist_river_m"]] == "unit_", lev[["elev_m"]] == "period_",   # MLC.7: ASL 566 in 2015, 515 in 2016
          sum(cv[, .N, by = unit]$N == 2L) == NBOTH)
stn <- data.table(unit = cv$unit, period = as.integer(cv$YEAR) - 14L, obs_trials = as.integer(e$k), unit_site = cv$SITE)
for (n in names(covs)) stn[, (paste0(lev[[n]], n)) := cv[[covs[[n]]]]]
stopifnot(all(stn$period %in% 1:2))

long <- rbindlist(lapply(seq_along(h), function(j) cbind(stn[, .(unit, period)], taxon = toupper(h[j]), y = as.integer(M[, j]), stn[, -(1:2)])))
long <- order_eco(long)
stopifnot(nrow(long) == 77L * 26L, uniqueN(long$unit) == uniqueN(cv$unit), sum(long$y) == sum(M), all(long$y <= long$obs_trials))
cat(sprintf("  %d rows; %d stations, %d station-years; %d station-year x species with a detection; levels: %s\n",
            nrow(long), uniqueN(long$unit), nrow(stn), sum(M > 0), paste(names(lev)[lev == "period_"], collapse = ", ")))

s <- sp[match(h, SPECIES)]
taxa <- make_taxa(toupper(s$SPECIES), s$LATIN.NAME, vernacularName = s$COMMON.NAME,
                  taxon_family = s$FAMILY, taxon_order = s$ORDER, taxon_body_mass_kg = s$WEIGHT,
                  taxon_iucnCategory = s$IUCN, taxon_sourceCode = s$SPECIES)
taxa[taxon == "KINKAJOU", `:=`(taxon_family = "Procyonidae", taxon_order = "Carnivora")]   # swapped in the deposit
stopifnot(sp[SPECIES == "kinkajou"]$FAMILY == "Carnivora")
periods <- data.table(period = 1:2, year = c(2015L, 2016L), source_year_code = c(15L, 16L),
                      n_stations = as.integer(table(stn$period)), sites = c(paste(sort(unique(stn[period == 1]$unit_site)), collapse = ","),
                                                                            paste(sort(unique(stn[period == 2]$unit_site)), collapse = ",")))

dataset <- list(
  title = "Terrestrial camera-trap detections of 26 mammal species at 77 station-years across a disturbance gradient, Manu Biosphere Reserve, Peru, 2015 and 2016: six-day sessions with a detection out of sessions surveyed",
  creator = "Whitworth, Andrew; Beirne, Chris; Pillco Huarcaya, Ruthmery; Whittaker, Lawrence; Serrano Rojas, Shirley Jennifer; Tobler, Mathias; MacLeod, Ross",
  pubDate = "2019",
  doi = "10.5061/dryad.32464qs", sourceURL = "https://doi.org/10.5061/dryad.32464qs",
  citation = "Whitworth, A., Beirne, C., Pillco Huarcaya, R., Whittaker, L., Serrano Rojas, S. J., Tobler, M., & MacLeod, R. (2019). Data from: Human disturbance impacts on rainforest mammals are most notable in the canopy; especially for larger-bodied species [Dataset]. Dryad. https://doi.org/10.5061/dryad.32464qs",
  paperDOI = "10.1111/ddi.12930",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Arboreal and terrestrial camera traps across a gradient of rainforest disturbance in the Manu Biosphere Reserve, southeast Peru, to compare how the canopy and ground mammal communities respond. This table is the terrestrial survey: 77 station-years at six sites (2015 and 2016; 9 stations resurveyed in both years at two sites), 26 species. For each station-year and species the deposit gives the number of six-day sessions with a detection out of the sessions surveyed, as the authors' multi-season Royle-Nichols community model uses it, with habitat and disturbance covariates.",
  samplingProtocol = "Terrestrial camera traps at stations along a forest disturbance gradient; each deployment divided into six-day sessions (9-32 per station-year), y = sessions in which the species was photographed.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "binomial_count", effortColumn = "obs_trials", unitKind = "site",
  closure = "none", closureNote = "one row per station x species x year; the six-day sessions of a deployment are collapsed by the source into obs_trials. Years are periods (2015, 2016); 9 stations (MLC, DIA) were surveyed in both years.",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Manu Biosphere Reserve, Madre de Dios, southeast Peru: six sites (AGU, DIA, MLC, ROM, SHIN, SHIP; codes as deposited, no coordinates)",
  temporalCoverage = "2015/2016",
  covariateNote = "unit_site: study site code. cc_pct canopy cover (%), shrub_density, tree_connectivity (estimated connectivity of the focal tree), tree_density (surrounding), canopy_height_m (surrounding canopy layer), cam_bearing_deg, elev_m (m asl), dist_river_m (to the nearest navigable river), forest_loss (surrounding canopy loss), dist_community_m (to the nearest community), disturbance_pc1/pc2 (first two principal components of the disturbance features, as deposited). Each is unit_ when constant across a station's two years, otherwise period_.",
  notShipped = list(
    arboreal_survey = "occ_data_arb_6d.txt / occ_effort_arb_6d.txt (145 arboreal station-years x 24 species): held, because 13 of its 24 species codes (the primates, porcupine_bicolor, squirrel_dwarf) have no scientific name in species_data.txt",
    cam_height = "CAM.HEIGHT, the height of the arboreal camera",
    survey_name = "SurveyName (site x year, recoverable from unit_site and period)",
    model_output = "Royle-Nichols occupancy and abundance estimates (the JAGS code is deposited, its outputs are not)"),
  notes = "Body mass, family, order and IUCN category in __taxa are the deposit's (species_data.txt, 2019); the kinkajou's family and order are swapped in the deposit and are corrected in __taxa. Several species are IUCN VU (tapir, giant armadillo, giant anteater, white-lipped peccary, pacarana); no coordinates are deposited.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/whitworth_2019_manu_terr_mamm_binom.R")
stage_dict_row(TABLE,
  description = "Terrestrial camera-trap community data for 26 mammal species at 77 station-years along a rainforest disturbance gradient in the Manu Biosphere Reserve, Peru, 2015-2016: six-day sessions with a detection out of sessions surveyed (binomial_count), with habitat covariates.",
  url = "https://doi.org/10.5061/dryad.32464qs",
  reference = "Whitworth, A., Beirne, C., Pillco Huarcaya, R., Whittaker, L., Serrano Rojas, S. J., Tobler, M. W. & MacLeod, R. (2019). Human disturbance impacts on rainforest mammals are most notable in the canopy, especially for larger-bodied species. Diversity and Distributions 25, 1166-1178. https://doi.org/10.1111/ddi.12930",
  doi_paper = "10.1111/ddi.12930", doi_data = "10.5061/dryad.32464qs",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Terrestrial survey only; the arboreal survey of the same deposit is held (13 species codes undefined).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (binomial counts over six-day sessions, multi-season)",
  sampling_protocol = "camera_trap", design = "Multi-season (2 years; 77 station-years, 9-32 six-day sessions collapsed to a count)",
  realm = "Terrestrial", country = "PER", coordinates = "None in source",
  notes = "Terrestrial cameras along a disturbance gradient; several VU species; no coordinates.")
