#!/usr/bin/env Rscript
# Table:  perea_2025_coastalplain_bats_comm
# Source: Dryad, doi:10.5061/dryad.m0cfxpp9f, version 345889 (published 2025-02-14), licence CC0 1.0 as shown on the
#         Dryad dataset page (asserted from the dataset JSON). Perea, S., Fandos, G., Larsen-Gray, A., Greene, D. U.,
#         Chandler, R. B. & Castleberry, S. B.
# Paper:  Perea, S. et al. (2025). Bat winter foraging habitat use in working forests: a multispecies spatial occupancy
#         approach. Animal Conservation, doi:10.1111/acv.12924 (not read). Design from the Dryad methods and README:
#         six working pine-forest landscapes in FL, GA, LA, MS, NC and SC, 40 points per landscape at random
#         intersections of a 900 m grid, all points of a landscape sampled within one month, January-March 2020-2022,
#         Anabat Swift acoustic detectors, three survey nights per site; HOBO loggers for sunset temperature.
# Data:   sfMSOM_data_available.xlsx, sheet Multisp_winter_new (240 rows = sites): State, State_num, Point (1-40),
#           Year, detection 0/1 for nights 1-3 of EPFU, LABO, LACI, LAIN, MYO, NYHU, PESU, TABR (no missing cells,
#           asserted), Temperature Sunset 1-3 (deg C), Temperature.Mean, Canopy Openness (%), Basal Area (10-factor
#           prism value as deposited), Vegetation Clutter. README.md (species codes: LABO = Lasiurus borealis /
#           L. seminolus, MYO = Myotis austroriparius / M. septentrionalis; LAIN is in the sheet but not the README
#           list: Lasiurus intermedius, the standard four-letter code). No coordinates (private land; the README says
#           the rest of the data are sensitive and not shared).
# Mapping (community occupancy, acoustic detectors; responseType detection): unit = <state>_<point>, cluster_id =
#   the state's landscape, period = year (2020-2022 as 1..3; each landscape sampled in one year), occasion = survey
#   night 1..3, y = 0/1. obs_temp_sunset_c per night; unit_temp_sunset_mean_c, unit_canopy_openness_pct,
#   unit_basal_area (as deposited), unit_veg_clutter. surveyEvidence = deposited_matrix (all 240 x 3 nights
#   surveyed for all 8 taxa). Pooled groups LABO and MYO are their own taxa (E6) without a GBIF key.
#   E7: no coordinates (Perimyotis subflavus is IUCN VU, but nothing locates the sites beyond the state).
# Not shipped: model code and estimates; private-property data the authors withheld.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "perea_2025_coastalplain_bats_comm"
dir <- download_dryad("10.5061/dryad.m0cfxpp9f", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
d <- as.data.table(readxl::read_excel(file.path(dir, "sfMSOM_data_available.xlsx"), "Multisp_winter_new"))
sp <- c("EPFU", "LABO", "LACI", "LAIN", "MYO", "NYHU", "PESU", "TABR")
det <- as.vector(outer(sp, 1:3, paste))
stopifnot(nrow(d) == 240L, all(det %in% names(d)), all(unlist(d[, ..det]) %in% 0:1), !anyDuplicated(d[, .(State, Point)]),
          identical(d[, .N, by = .(State, Year)]$N, rep(40L, 6)), d[, uniqueN(Year), by = State][, all(V1 == 1L)],
          setequal(d$Year, 2020:2022), !anyNA(d[, c("Temperature Sunset 1", "Temperature Sunset 2", "Temperature Sunset 3"), with = FALSE]))
d[, unit := paste0(gsub(" ", "", State), "_", sprintf("%02d", as.integer(Point)))]
long <- rbindlist(lapply(sp, function(s) rbindlist(lapply(1:3, function(k) d[, .(unit, taxon = s, y = as.integer(get(paste(s, k))),
  period = as.integer(Year) - 2019L, occasion = k, cluster_id = State,
  unit_temp_sunset_mean_c = Temperature.Mean, unit_canopy_openness_pct = `Canopy Openness`, unit_basal_area = `Basal Area`,
  unit_veg_clutter = `Vegetation Clutter`, obs_temp_sunset_c = get(paste("Temperature Sunset", k)))]))))
long <- order_eco(long)
stopifnot(nrow(long) == 240L * 3L * 8L, sum(long$y) == sum(unlist(d[, ..det])))
cat(sprintf("  %d rows; detections %d; sites with any detection %d\n", nrow(long), sum(long$y), long[, max(y), by = unit][V1 == 1, .N]))

taxa <- make_taxa(sp, c("Eptesicus fuscus", "Lasiurus borealis / Lasiurus seminolus", "Lasiurus cinereus", "Lasiurus intermedius",
                        "Myotis austroriparius / Myotis septentrionalis", "Nycticeius humeralis", "Perimyotis subflavus", "Tadarida brasiliensis"),
                  vernacularName = c("Big brown bat", "Eastern red / Seminole bat", "Hoary bat", "Northern yellow bat",
                                     "Southeastern / northern long-eared myotis", "Evening bat", "Tricolored bat", "Brazilian free-tailed bat"),
                  taxonRank = c("species", "species group", "species", "species", "species group", "species", "species", "species"),
                  no_key = c("LABO", "MYO"),
                  taxonRemarks = c(NA, "Calls of L. borealis and L. seminolus not separated; pooled by the source (no single GBIF key)", NA, "LAIN is in the data sheet but not in the README species list; read as Lasiurus intermedius, the standard code",
                                   "Calls of M. austroriparius and M. septentrionalis not separated; pooled by the source (no single GBIF key)", NA, NA, NA))
periods <- data.table(period = 1:3, year = 2020:2022, season = "January-March")

dataset <- list(
  title = "Winter acoustic detections of eight bat taxa at 240 sites in six working pine-forest landscapes, southeastern US Coastal Plain, 2020-2022",
  creator = "Perea, Santiago; Fandos, Guillermo; Larsen-Gray, Angela; Greene, D. Ulrich; Chandler, Richard B.; Castleberry, Steven B.", pubDate = "2025",
  doi = "10.5061/dryad.m0cfxpp9f", sourceURL = "https://doi.org/10.5061/dryad.m0cfxpp9f",
  citation = "Perea, S., Fandos, G., Larsen-Gray, A., Greene, D. U., Chandler, R. B., & Castleberry, S. B. (2025). Data from: Bat winter foraging habitat use in working forests: A multispecies spatial occupancy approach [Dataset]. Dryad. https://doi.org/10.5061/dryad.m0cfxpp9f",
  paperDOI = "10.1111/acv.12924",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Anabat Swift acoustic detectors at 40 random grid points in each of six working pine-forest landscapes (Florida, Georgia, Louisiana, Mississippi, North Carolina, South Carolina), three nights per site in January-March of 2020, 2021 or 2022. Nightly detection of five bat species and pooled groups, with sunset temperature and site vegetation structure; the authors fitted spatial factor multi-species occupancy models.",
  samplingProtocol = "One acoustic detector per site for three nights in winter; calls identified to species or species group; a night with any identified call of the taxon is a detection.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "three nights at one site within the landscape's one-month sampling window",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Six working forest landscapes in the southeastern United States Coastal Plain (FL, GA, LA, MS, NC, SC); no coordinates deposited",
  temporalCoverage = "2020/2022",
  covariateNote = "obs_temp_sunset_c: temperature at sunset on the night (HOBO logger). unit_temp_sunset_mean_c: the source's mean of the three. unit_canopy_openness_pct (spherical densiometer), unit_basal_area (10-factor prism value as deposited; the README says m2/ha), unit_veg_clutter (modified Nudds board). cluster_id: the state's landscape (sampled in one year).",
  notShipped = list(private_data = "further site data the authors withheld as sensitive (private land)", model_output = "occupancy and richness estimates", code = "model and figure scripts"),
  notes = "Each landscape was sampled in one winter only (Georgia and Louisiana 2020, Mississippi and South Carolina 2021, Florida and North Carolina 2022), so period and cluster_id are confounded. 225 of 240 sites have a detection in the deposit; the abstract says 224.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/perea_2025_coastalplain_bats_comm.R")
stage_dict_row(TABLE,
  description = "Nightly acoustic detections of eight bat taxa at 240 sites (3 nights each) in six working pine-forest landscapes of the southeastern US Coastal Plain, winters 2020-2022, with sunset temperature and vegetation structure.",
  url = "https://doi.org/10.5061/dryad.m0cfxpp9f",
  reference = "Perea, S., Fandos, G., Larsen-Gray, A., Greene, D. U., Chandler, R. B., & Castleberry, S. B. (2025). Bat winter foraging habitat use in working forests: A multispecies spatial occupancy approach. Animal Conservation. https://doi.org/10.1111/acv.12924",
  doi_paper = "10.1111/acv.12924", doi_data = "10.5061/dryad.m0cfxpp9f",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy from acoustic detectors; two pooled call groups; no coordinates.",
  source_via = "Dryad (per-file, token)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-species)",
  sampling_protocol = "acoustic", design = "Single-season (3 nights per site; 240 sites in 6 landscapes, 2020-2022)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Winter bat acoustic survey in managed pine forests.")
