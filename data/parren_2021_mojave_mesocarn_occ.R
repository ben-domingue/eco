#!/usr/bin/env Rscript
# Table:  parren_2021_mojave_mesocarn_occ
# Source: Dryad, doi:10.5061/dryad.6t1g1jx08, version 140793 (version 3, published 2021-09-19), licence CC0 1.0
#         as shown on the Dryad page. Data of the California Department of Fish and Wildlife drought study.
# Paper:  Parren, M. et al. (2022). Drought and coyotes mediate mesopredator response to human disturbance.
#         Ecosphere. https://doi.org/10.1002/ecs2.4258
# Data:   The deposit covers two ecoregions with different occasion definitions; this table is the Mojave
#         Desert (MD). The Central Valley is parren_2021_centralvalley_mesocarn_occ (read its header too).
#         MD_{CANLAT,LYNRUF,VULMAC}_detection_history_and_covariates.csv: 319 camera sites ("/* 26969A */"),
#           survey1..survey9 = nine 3-day survey periods, 1/0, NA = camera not functional; then standardised
#           covariates and b1..b9 (standardised bait age = survey index). Identical site order and NA pattern
#           across the three species (asserted; 28 NA cells, no all-NA site).
#         MD_covariates.csv: the same 319 sites, raw covariates: elev (km), water (distance to water, km), HD
#           (human disturbance 1-10 within 1 km), YR (0 = 2016, 1 = 2017), guzz (guzzler at the site, 1/0),
#           julian1 (ordinal date of the first survey day), YR interactions.
#         MD_CANLAT_{LYNRUF,VULMAC}_...: the same detections interleaved, coyote first (cell-by-cell equality
#           asserted); not shipped separately. *_Parameter_Estimates_Figures.csv: model output.
#         Site ids are a 5-digit cell number plus a camera letter: 176 cells.
# Mapping: unit = SiteID, cluster_id = the 5-digit cell, taxon = CANLAT / LYNRUF / VULMAC, period = year
#   (1 = 2016, 2 = 2017; each site is surveyed in one year), occasion = 3-day survey 1..9, y = 0/1.
#   No date column: only the first survey day is deposited (unit_first_survey_date = 1 January + julian1 - 1);
#   the README does not say that the nine 3-day periods are consecutive. Community rule: every species has a
#   row at every functional survey. surveyEvidence = deposited_matrix. unit_elev_km, unit_d_water_km, unit_hd,
#   unit_guzzler. No coordinates in the deposit. All three species IUCN LC.
#   Not shipped: standardised covariates, year interactions and bait age (derivable); parameter estimates
#   (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "parren_2021_mojave_mesocarn_occ"
R <- "MD"; J <- 9L; SP <- c("CANLAT", "LYNRUF", "VULMAC")

dir <- download_dryad("10.5061/dryad.6t1g1jx08", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 14)
L <- lapply(SP, function(s) { d <- fread(file.path(dir, sprintf("%s_%s_detection_history_and_covariates.csv", R, s)));
                                setnames(d, 1, "site"); d[, site := gsub("[/* ]", "", site)]; d })
names(L) <- SP
cv <- fread(file.path(dir, "MD_covariates.csv")); setnames(cv, 1, "site")
stopifnot(nrow(cv) == 319, !anyDuplicated(cv$site), all(grepl("^[0-9]{5}[A-Z]$", cv$site)),
          all(sapply(L, function(d) identical(d$site, cv$site))))
Y <- lapply(L, function(d) as.matrix(d[, paste0("survey", 1:J), with = FALSE]))
stopifnot(all(sapply(Y, function(m) identical(is.na(m), is.na(Y$CANLAT)))), sum(is.na(Y$CANLAT)) == 28,
          all(rowSums(!is.na(Y$CANLAT)) > 0), all(unlist(Y) %in% c(0L, 1L, NA)))
for (s in SP[-1]) {   # the two-species files carry the same detections, coyote first
  two <- as.matrix(fread(file.path(dir, sprintf("%s_CANLAT_%s_detection_history_and_covariates.csv", R, s)), header = FALSE, skip = 1)[, 2:(2 * J + 1)])
  stopifnot(all(two[, seq(1, 2 * J, 2)] == Y$CANLAT, na.rm = TRUE), all(two[, seq(2, 2 * J, 2)] == Y[[s]], na.rm = TRUE))
}
stopifnot(all(cv$YR %in% 0:1), as.vector(table(cv$YR)) == c(217L, 102L), all(cv$guzz %in% 0:1), !anyNA(cv$julian1))
year <- 2016L + cv$YR

site_covs <- data.frame(first_survey_date = as.character(as.IDate(sprintf("%d-01-01", year)) + cv$julian1 - 1L),
                        elev_km = cv[["elev (km)"]], d_water_km = cv[["water (km)"]], hd = cv$HD, guzzler = cv$guzz)
long <- rbindlist(lapply(SP, function(s) array_to_eco(Y[[s]], taxon = s, site_ids = cv$site, site_covs = site_covs)))
long[, period := year[match(unit, cv$site)] - 2015L][, cluster_id := substr(unit, 1, 5)]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "cluster_id"))
setorder(long, period, unit, occasion, taxon)
stopifnot(nrow(long) == 3 * sum(!is.na(Y$CANLAT)), uniqueN(long$unit) == 319, uniqueN(long$cluster_id) == 176)

taxa <- make_taxa(SP, c("Canis latrans", "Lynx rufus", "Vulpes macrotis"), vernacularName = c("Coyote", "Bobcat", "Kit fox"))
stopifnot(all(mapply(iucn_category, taxa$taxonID, taxa$scientificName) == "LC"))
first <- as.IDate(site_covs$first_survey_date)
periods <- data.table(period = 1:2, year = 2016:2017,
                      first_survey_min = sapply(2016:2017, function(k) as.character(min(first[year == k]))),
                      first_survey_max = sapply(2016:2017, function(k) as.character(max(first[year == k]))),
                      n_sites = c(217L, 102L))

dataset <- list(
  title = "Camera detections of coyote, bobcat and kit fox in nine 3-day surveys at 319 baited sites in the Mojave Desert, California, 2016 and 2017",
  creator = "Parren, Molly", pubDate = "2021",
  doi = "10.5061/dryad.6t1g1jx08", sourceURL = "https://doi.org/10.5061/dryad.6t1g1jx08",
  citation = "Parren, M. (2021). Drought and coyotes mediate mesopredator response to human disturbance [Dataset]. Dryad. https://doi.org/10.5061/dryad.6t1g1jx08",
  paperDOI = "10.1002/ecs2.4258",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "California Department of Fish and Wildlife drought study: baited camera traps at 319 sites (176 cells, mostly two cameras each) in the Mojave Desert in a drought year (2016) and a post-drought year (2017), each site surveyed in one year. Detection/non-detection of coyote, bobcat and kit fox in nine 3-day survey periods, with elevation, distance to water, human disturbance and guzzler covariates.",
  samplingProtocol = "Baited camera trap per site; a survey is a 3-day period; a period in which the camera was not functional is not a survey.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "nine 3-day periods per site in one season; the authors fit single-season and two-species occupancy models",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Mojave Desert ecoregion, California, USA (no coordinates deposited)",
  temporalCoverage = sprintf("%s/%s", min(periods$first_survey_min), as.character(max(first) + 26L)),
  coordinatesCoarsened = NA,
  covariateNote = "unit_first_survey_date is the first survey day (from julian1); the nine 3-day periods presumably follow it consecutively (27 days), which the README does not state, so there is no per-row date. unit_hd: human disturbance 1-10 within 1 km; unit_guzzler: wildlife water guzzler at the site (1/0).",
  notShipped = list(
    standardised = "standardised covariates, year interactions and bait age b1..b9 in the detection-history files (derivable)",
    two_species_files = "the same detections interleaved for co-occurrence models",
    model_output = "Single_ and Two_Species_Parameter_Estimates_Figures.csv"),
  notes = "The Central Valley half of the deposit, with daily surveys, is parren_2021_centralvalley_mesocarn_occ. temporalCoverage ends 26 days after the last first-survey date, assuming consecutive 3-day periods.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/parren_2021_mojave_mesocarn_occ.R")
stage_dict_row(TABLE,
  description = "Detection/non-detection of coyote, bobcat and kit fox in nine 3-day surveys at 319 baited camera sites in California's Mojave Desert, 2016 (drought) and 2017, with elevation, distance to water, human disturbance and guzzler covariates.",
  url = "https://doi.org/10.5061/dryad.6t1g1jx08",
  reference = "Parren, M. et al. (2022). Drought and coyotes mediate mesopredator response to human disturbance. Ecosphere. https://doi.org/10.1002/ecs2.4258",
  doi_paper = "10.1002/ecs2.4258", doi_data = "10.5061/dryad.6t1g1jx08",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Mojave Desert half of the deposit (3-day surveys); first survey date only.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (multi-species, co-occurrence)",
  sampling_protocol = "camera_trap", design = "Multi-season (2 years, each site in one; 3-day occasions)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Baited cameras, CDFW drought study; sibling table for the Central Valley.")
