#!/usr/bin/env Rscript
# Table:  parren_2021_centralvalley_mesocarn_occ
# Source: Dryad, doi:10.5061/dryad.6t1g1jx08, version 140793 (version 3, published 2021-09-19), licence CC0 1.0
#         as shown on the Dryad page. Data of the California Department of Fish and Wildlife drought study.
# Paper:  Parren, M. et al. (2022). Drought and coyotes mediate mesopredator response to human disturbance.
#         Ecosphere. https://doi.org/10.1002/ecs2.4258
# Data:   The deposit covers two ecoregions with different occasion definitions; this table is the Central
#         Valley (CV). The Mojave Desert is parren_2021_mojave_mesocarn_occ.
#         CV_{CANLAT,LYNRUF,PROLOT}_detection_history_and_covariates.csv: 266 camera sites ("/* 21346A */"),
#           survey1..survey27 = 27 single-day surveys, 1/0, NA = camera not functional that day (not aimed at
#           the bait for 24 h); then standardised covariates. Identical site order and NA pattern across the
#           three species (asserted; 253 NA cells, no all-NA site).
#         CV_covariates.csv: the same 266 sites, raw covariates: lat (latitude; no longitude is deposited),
#           yr (0 = 2016, 1 = 2017), HD (human disturbance 1-10 within 1 km), trees (proportion tree cover incl.
#           orchards within 1 km), water (water at the site at deployment, 1/0), d_water (km), the yr
#           interactions, j1..j27 (ordinal date of each survey day; consecutive, asserted).
#         CV_CANLAT_{LYNRUF,PROLOT}_...: the same detections interleaved two species per survey for the
#           co-occurrence models; the README says the subordinate species comes first, but the coyote does
#           (cell-by-cell equality with the single-species files asserted); not shipped separately. The *_Parameter_Estimates_Figures.csv files are model output.
#         Site ids are a 5-digit cell number plus a camera letter (A/B): 137 cells.
# Mapping: unit = SiteID, cluster_id = the 5-digit cell, taxon = CANLAT / LYNRUF / PROLOT, period = year
#   (1 = 2016, 2 = 2017; each site is surveyed in one year), occasion = survey day 1..27, y = 0/1,
#   date = 1 January of the year + j - 1. Community rule: every species has a row at every functional
#   camera-day. surveyEvidence = deposited_matrix. unit_lat (latitude only), unit_hd, unit_trees,
#   unit_water_at_deploy, unit_d_water_km.
#   All three species IUCN LC; the deposit has a latitude but no longitude, shipped as deposited.
#   Not shipped: standardised covariates and yr interactions (derivable from the raw ones); 3lag1..27, the
#   authors' indicator of a coyote detection in the previous 3 days (derivable from the coyote rows);
#   parameter estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "parren_2021_centralvalley_mesocarn_occ"
R <- "CV"; J <- 27L; SP <- c("CANLAT", "LYNRUF", "PROLOT")

dir <- download_dryad("10.5061/dryad.6t1g1jx08", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 14)
L <- lapply(SP, function(s) { d <- fread(file.path(dir, sprintf("%s_%s_detection_history_and_covariates.csv", R, s)));
                                setnames(d, 1, "site"); d[, site := gsub("[/* ]", "", site)]; d })
names(L) <- SP
cv <- fread(file.path(dir, "CV_covariates.csv")); setnames(cv, 1, "site")
stopifnot(nrow(cv) == 266, !anyDuplicated(cv$site), all(grepl("^[0-9]{5}[A-Z]$", cv$site)),
          all(sapply(L, function(d) identical(d$site, cv$site))))
Y <- lapply(L, function(d) as.matrix(d[, paste0("survey", 1:J), with = FALSE]))
stopifnot(all(sapply(Y, function(m) identical(is.na(m), is.na(Y$CANLAT)))), sum(is.na(Y$CANLAT)) == 253,
          all(rowSums(!is.na(Y$CANLAT)) > 0), all(unlist(Y) %in% c(0L, 1L, NA)))
for (s in SP[-1]) {   # the two-species files carry the same detections
  two <- as.matrix(fread(file.path(dir, sprintf("%s_CANLAT_%s_detection_history_and_covariates.csv", R, s)), header = FALSE, skip = 1)[, 2:(2 * J + 1)])
  stopifnot(all(two[, seq(1, 2 * J, 2)] == Y$CANLAT, na.rm = TRUE), all(two[, seq(2, 2 * J, 2)] == Y[[s]], na.rm = TRUE))
}
JD <- as.matrix(cv[, paste0("j", 1:J), with = FALSE])
stopifnot(!anyNA(JD), all(JD[, -1] - JD[, -J] == 1), all(cv$yr %in% 0:1), as.vector(table(cv$yr)) == c(86L, 180L))
year <- 2016L + cv$yr
DATE <- matrix(as.character(as.IDate(sprintf("%d-01-01", year)) + as.vector(JD) - 1L), nrow(JD))

site_covs <- data.frame(lat = cv$lat, hd = cv$HD, trees = cv$trees, water_at_deploy = cv$water, d_water_km = cv[["d_water (km)"]])
long <- rbindlist(lapply(SP, function(s) array_to_eco(Y[[s]], taxon = s, site_ids = cv$site, site_covs = site_covs,
                                                      obs_covs = list(date = DATE))))
setnames(long, "obs_date", "date")
long[, period := year[match(unit, cv$site)] - 2015L][, cluster_id := substr(unit, 1, 5)]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date", "cluster_id"))
setorder(long, period, unit, occasion, taxon)
stopifnot(nrow(long) == 3 * sum(!is.na(Y$CANLAT)), uniqueN(long$unit) == 266, uniqueN(long$cluster_id) == 137)

taxa <- make_taxa(SP, c("Canis latrans", "Lynx rufus", "Procyon lotor"), vernacularName = c("Coyote", "Bobcat", "Raccoon"))
stopifnot(all(mapply(iucn_category, taxa$taxonID, taxa$scientificName) == "LC"))
periods <- data.table(period = 1:2, year = 2016:2017,
                      period_start = sapply(1:2, function(k) min(long[period == k, date])),
                      period_end = sapply(1:2, function(k) max(long[period == k, date])),
                      n_sites = c(86L, 180L))

dataset <- list(
  title = "Daily camera detections of coyote, bobcat and raccoon at 266 baited sites in California's Central Valley, 2016 and 2017",
  creator = "Parren, Molly", pubDate = "2021",
  doi = "10.5061/dryad.6t1g1jx08", sourceURL = "https://doi.org/10.5061/dryad.6t1g1jx08",
  citation = "Parren, M. (2021). Drought and coyotes mediate mesopredator response to human disturbance [Dataset]. Dryad. https://doi.org/10.5061/dryad.6t1g1jx08",
  paperDOI = "10.1002/ecs2.4258",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "California Department of Fish and Wildlife drought study: baited camera traps at 266 sites (137 cells, mostly two cameras each) in the Central Valley in a drought year (2016) and a post-drought year (2017), each site surveyed in one year for up to 27 days. Daily detection/non-detection of coyote, bobcat and raccoon, with human disturbance, tree cover and water covariates.",
  samplingProtocol = "Baited camera trap per site; a survey is one day; a day on which the camera was not aimed at the bait for 24 h is not a survey.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "up to 27 consecutive days per site; the authors fit single-season and two-species occupancy models",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Central Valley ecoregion, California, USA (latitude only deposited, 35.3 to 40.2 N)",
  temporalCoverage = sprintf("%s/%s", min(periods$period_start), max(periods$period_end)),
  coordinatesCoarsened = NA,
  covariateNote = "unit_lat is the only coordinate deposited (no longitude). unit_hd: human disturbance 1-10 within 1 km; unit_trees: proportion tree cover (incl. orchards) within 1 km; unit_water_at_deploy: water at the site at deployment (1/0); unit_d_water_km: distance to water.",
  notShipped = list(
    standardised = "standardised covariates and year interactions in the detection-history files (derivable)",
    coyote_lag = "3lag1..27, an indicator of a coyote detection in the previous 3 days (derivable from the coyote rows)",
    two_species_files = "the same detections interleaved for co-occurrence models",
    model_output = "Single_ and Two_Species_Parameter_Estimates_Figures.csv"),
  notes = "The Mojave Desert half of the deposit, with 3-day surveys, is parren_2021_mojave_mesocarn_occ.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/parren_2021_centralvalley_mesocarn_occ.R")
stage_dict_row(TABLE,
  description = "Daily detection/non-detection of coyote, bobcat and raccoon at 266 baited camera sites in California's Central Valley, 2016 (drought) and 2017, up to 27 days per site, with human disturbance, tree cover and water covariates.",
  url = "https://doi.org/10.5061/dryad.6t1g1jx08",
  reference = "Parren, M. et al. (2022). Drought and coyotes mediate mesopredator response to human disturbance. Ecosphere. https://doi.org/10.1002/ecs2.4258",
  doi_paper = "10.1002/ecs2.4258", doi_data = "10.5061/dryad.6t1g1jx08",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Central Valley half of the deposit (daily surveys); latitude only.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (multi-species, co-occurrence)",
  sampling_protocol = "camera_trap", design = "Multi-season (2 years, each site in one; daily occasions)",
  realm = "Terrestrial", country = "USA", coordinates = "As published (latitude only)",
  notes = "Baited cameras, CDFW drought study; sibling table for the Mojave Desert.")
