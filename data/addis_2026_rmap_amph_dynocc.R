#!/usr/bin/env Rscript
# Table: addis_2026_rmap_amph_dynocc (replaces addis_2026_rmap_mbrt_dynocc + addis_2026_rmap_bt_dynocc)
# Source: figshare 10.6084/m9.figshare.31257466.v2 (CC BY 4.0). Addis, Brett (2026). Rocky
#         Mountain Amphibian Project occupancy data and analyses. "Code and data files for
#         conducting autologistic dynamic occupancy modeling of six species of amphibians
#         occurring in the Rocky Mountains ... 2012-2019."
# Data:   one long CSV per species (<sp>.ch_bayesian.csv): one row per site x survey with
#         SiteNumber, SurveyDate, SurveyNumber (nth survey of the site that year), SpeciesCode
#         (0/1 detected), Catchment, Site, SurveyYear, Jdate, site covariates (SiteAreaHa,
#         AveSiteDist, MedSiteDist, NumNeighbors, Forest, Latitude, Longitude, UTM), survey
#         covariates (NumOfObservers, CitizenScientist 1 = citizen scientist / 2 = biologist;
#         AirTemp.sq in the wood frog file only). Species: bcf boreal chorus frog, bt boreal
#         toad, csf Columbia spotted frog, nlf northern leopard frog, ts tiger salamander, wf
#         wood frog. Checked: bcf, bt and ts files share the identical 6,446 survey keys and
#         dates; nlf and wf are exactly the MBRT (Medicine Bow-Routt NF) subset (4,145
#         surveys, 188 sites, 2012-2019); csf is exactly the BT (Bridger-Teton NF) subset
#         (2,301 surveys, 145 sites, 2014-2019). Site attributes are constant within site.
# Mapping (standard v1.1 E1-E5; multi-species dynamic occupancy): ONE table for the deposit
#   (ruling #31: one deposit x protocol x response type). The species surveyed for differ by
#   national forest (nlf/wf only in MBRT, csf only in BT; bcf, bt, ts in both), so the table
#   carries __survey_taxa (taxon x unit, E4.2): every site lists the taxa of its forest.
#   unit = SiteNumber, cluster_id = Catchment, unit_forest = MBRT / BT, taxon = species code,
#   period = year index over 2012-2019 (years in __periods), occasion = SurveyNumber, y = 0/1,
#   date = SurveyDate (ISO); unit_area_ha, unit_ave_site_dist_m, unit_med_site_dist_m,
#   unit_n_neighbors, unit_decimalLatitude, unit_decimalLongitude (as published; no taxon in
#   IUCN CR/EN/VU, boreal toad is NT); obs_date_doy, obs_n_observers, obs_citizen_scientist (1
#   if the surveyor was a citizen scientist, 0 if a biologist); obs_air_temp_f_sq from the wood
#   frog file (MBRT surveys only; empty for BT surveys, where the deposit has none). UTM
#   coordinates dropped (derivable). closure = closed (repeat summer visits, occasionKind =
#   time), taxonInclusion = target (the six species the project files name, per forest).
#   surveyEvidence = row_presence (one row per conducted survey per species file).
#   Replaces addis_2026_rmap_mbrt_dynocc and addis_2026_rmap_bt_dynocc (v1.0 split by forest).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SOURCE <- "addis_2026_rmap_amph_dynocc"
files <- c(bcf = 61646545, bt = 61646548, csf = 61646551, nlf = 61646554, ts = 61646557, wf = 61646560)
species <- c(bcf = "Pseudacris maculata", bt = "Anaxyrus boreas", csf = "Rana luteiventris",
             nlf = "Lithobates pipiens", ts = "Ambystoma mavortium", wf = "Lithobates sylvaticus")
vern <- c(bcf = "Boreal chorus frog", bt = "Boreal toad", csf = "Columbia spotted frog",
          nlf = "Northern leopard frog", ts = "Western tiger salamander", wf = "Wood frog")
codes <- c(bcf = "PSEMAC", bt = "ANABOR", csf = "RANLUT", nlf = "LITPIP", ts = "AMBMAV", wf = "LITSYL")
raw <- rbindlist(lapply(names(files), function(k) {
  d <- fread(download_cached(sprintf("https://ndownloader.figshare.com/files/%d", files[[k]]), SOURCE, filename = paste0(k, ".ch_bayesian.csv")))
  d[, sp := k]; d
}), fill = TRUE)
stopifnot(all(raw$SpeciesCode %in% 0:1), all(raw$Year == raw$SurveyYear), all(raw$CitizenScientist %in% 1:2))
key <- c("SiteNumber", "SurveyYear", "SurveyNumber")
K <- function(k) unique(raw[sp == k, ..key])
stopifnot(nrow(fsetdiff(K("bcf"), K("bt"))) == 0, nrow(fsetdiff(K("bcf"), K("ts"))) == 0, nrow(K("bcf")) == 6446)
stopifnot(nrow(fsetdiff(K("csf"), unique(raw[sp == "bcf" & Forest == "BT", ..key]))) == 0, nrow(K("csf")) == 2301)
stopifnot(nrow(fsetdiff(K("nlf"), unique(raw[sp == "bcf" & Forest == "MBRT", ..key]))) == 0, nrow(K("nlf")) == 4145, nrow(K("wf")) == 4145)
stopifnot(!anyDuplicated(raw, by = c(key, "sp")))
for (cc in c("Latitude", "Longitude", "SiteAreaHa", "AveSiteDist", "MedSiteDist", "NumNeighbors", "Catchment", "Forest"))
  stopifnot(raw[, uniqueN(get(cc)), by = SiteNumber][, all(V1 == 1)])

TABLE <- "addis_2026_rmap_amph_dynocc"
forest_taxa <- list(MBRT = c("bcf", "bt", "ts", "nlf", "wf"), BT = c("bcf", "bt", "ts", "csf"))
d <- rbindlist(lapply(names(forest_taxa), function(f) raw[Forest == f & sp %in% forest_taxa[[f]]]))
stopifnot(setequal(unique(raw$Forest), names(forest_taxa)), uniqueN(d$SiteNumber) == 145 + 188)
years <- sort(unique(d$SurveyYear))
long <- d[, .(unit = SiteNumber, taxon = codes[sp], y = as.integer(SpeciesCode),
              period = match(SurveyYear, years), occasion = as.integer(SurveyNumber),
              date = format(as.Date(SurveyDate, "%m/%d/%Y")), cluster_id = Catchment, unit_forest = Forest,
              unit_area_ha = SiteAreaHa, unit_ave_site_dist_m = AveSiteDist, unit_med_site_dist_m = MedSiteDist,
              unit_n_neighbors = NumNeighbors, unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude,
              obs_date_doy = Jdate, obs_n_observers = NumOfObservers, obs_citizen_scientist = as.integer(CitizenScientist == 1))]
at <- raw[sp == "wf", .(unit = SiteNumber, period = match(SurveyYear, years), occasion = as.integer(SurveyNumber), obs_air_temp_f_sq = AirTemp.sq)]
stopifnot(nrow(at) == 4145, any(!is.na(at$obs_air_temp_f_sq)))
long <- merge(long, at, by = c("unit", "period", "occasion"), all.x = TRUE)
stopifnot(!anyNA(long$date), nrow(long) == nrow(d), long[unit_forest == "BT", all(is.na(obs_air_temp_f_sq))])
long <- order_eco(long)
survey_taxa <- unique(long[, .(unit, unit_forest)])[, .(taxon = codes[forest_taxa[[unit_forest]]]), by = .(unit, unit_forest)][, .(taxon, unit)]
# every survey has exactly its forest's taxa (E4.2)
stopifnot(long[, .(ok = setequal(taxon, codes[forest_taxa[[unit_forest[1]]]])), by = .(unit, period, occasion)][, all(ok)])
taxa <- make_taxa(codes, species, vernacularName = vern, taxon_iucnCategory = ifelse(names(codes) == "bt", "NT", "LC"))
periods <- data.table(period = seq_along(years), year = years,
                      n_sites_surveyed = sapply(years, function(y) uniqueN(d[SurveyYear == y, SiteNumber])))
forest_name <- "Medicine Bow-Routt National Forest (Wyoming/Colorado) and Bridger-Teton National Forest (Wyoming)"
dataset <- list(
  title = sprintf("Rocky Mountain Amphibian Project: detection/non-detection of six amphibian species at %d wetland sites in two national forests, %d-%d",
                  uniqueN(d$SiteNumber), min(years), max(years)),
  creator = "Addis, Brett; Rocky Mountain Amphibian Project", pubDate = "2026", doi = "10.6084/m9.figshare.31257466.v2",
  sourceURL = "https://doi.org/10.6084/m9.figshare.31257466.v2",
  citation = "Addis, B. (2026). Rocky Mountain Amphibian Project occupancy data and analyses [Data set]. figshare. https://doi.org/10.6084/m9.figshare.31257466.v2",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Occupancy survey data from the Rocky Mountain Amphibian Project (2012-2019), deposited for autologistic dynamic occupancy modelling of six amphibian species (deposit description). Wetland sites within catchments were surveyed one to eight times per summer by biologists and citizen scientists.",
  samplingProtocol = "Repeated visual-encounter surveys of wetland sites within catchments each summer; detection/non-detection per species per survey; number of observers and surveyor type recorded per survey.",
  samplingProtocolCode = "ves", surveyEvidence = "row_presence",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "target",
  surveyTaxaNote = "The species surveyed for differ by national forest (northern leopard frog and wood frog only in Medicine Bow-Routt; Columbia spotted frog only in Bridger-Teton): __survey_taxa lists them per site.",
  geographicCoverage = list(description = forest_name,
                            boundingBox = list(west = min(d$Longitude), east = max(d$Longitude), south = min(d$Latitude), north = max(d$Latitude))),
  temporalCoverage = sprintf("%d/%d", min(years), max(years)),
  coordinatesCoarsened = list(value = FALSE, method = "as published; no taxon in IUCN CR/EN/VU (boreal toad NT)"),
  notShipped = list(UTM_Easting_Northing = "derivable from the WGS84 coordinates"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa,
                  script = "data/addis_2026_rmap_amph_dynocc.R")
stage_dict_row(TABLE,
  description = sprintf("Detection/non-detection of six amphibian species (%s) at %d wetland sites in %d catchments of two national forests in Wyoming and Colorado, %d-%d (Rocky Mountain Amphibian Project), 1-8 surveys per site-year, with site area, isolation metrics, coordinates, survey date, observer count and surveyor type; the species list differs by forest (__survey_taxa).",
                        paste(tolower(vern), collapse = ", "), uniqueN(d$SiteNumber), uniqueN(d$Catchment), min(years), max(years)),
  url = "https://doi.org/10.6084/m9.figshare.31257466.v2",
  reference = "Addis, B. (2026). Rocky Mountain Amphibian Project occupancy data and analyses [Data set]. figshare.",
  doi_data = "10.6084/m9.figshare.31257466.v2", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Replaces addis_2026_rmap_mbrt_dynocc and addis_2026_rmap_bt_dynocc (ruling #31). Squared air temperature from the wood frog file shipped as obs_air_temp_f_sq (Medicine Bow-Routt surveys only).",
  source_via = "figshare")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "ves", design = sprintf("Multi-season (%d years x 1-8 surveys)", length(years)), realm = "Freshwater", country = "USA",
  coordinates = "As published", notes = "Citizen-science and biologist surveys; obs_citizen_scientist flags the surveyor type.")
