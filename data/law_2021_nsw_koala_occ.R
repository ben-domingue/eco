#!/usr/bin/env Rscript
# Table:  law_2021_nsw_koala_occ
# Source: Dryad doi:10.5061/dryad.2rbnzs7pq, version 4 (2021-12-21), CC0 1.0 (as shown on the Dryad page).
#   Law, B., Kerr, I., Gonsalves, L., Brassil, T., Eichinski, P., Truskinger, A. & Roe, P. (2021). Mini-acoustic
#   sensors reveal occupancy and threats to koalas (Phascolarctos cinereus) in private native forests. Dryad.
# Paper:  Law, B. et al. (2022). Mini-acoustic sensors reveal occupancy and threats to koalas in private native
#         forests. Journal of Applied Ecology 59(3), 815-826, doi:10.1111/1365-2664.14099. From the Dryad abstract:
#         AudioMoth sensors mailed to landholders in north-east New South Wales; 128 sites over three years
#         (2018-2020), repeat surveys on consecutive nights; 2,560 male bellows recorded.
# Data:   det_data.csv: ident (site1..site128) x KoalaPresent.1..19 (night), 0/1, NA = "data not available".
#         surv_cov_long.csv: 2,432 rows = 19 nights stacked x 128 sites (site order repeats per night): rain
#           (mm to 9 am after the night, SILO), mintemp.1 (minimum temperature of the night, SILO).
#         unit_covs.csv: 128 sites; month and year of the survey; sep..jan and yr2018..yr2020 (dummies of month and
#           year); recent_harv, padd, youngR, regrowth, mat, euc (described in the metadata file as "0=not sampled;
#           1=sampled", which cannot be right for forest-history classes; two sites carry two of them; 30 NA);
#           length = number of sampling nights; habitat suitability (DPI_mod_*), elevation, road lengths, fire
#           severity, topographic position, NDVI, cleared area, koala tree species index (KTSI_*), each at 500 m and
#           1 km buffers. metadata_*.csv describe the three files.
#         Checked: ident agrees across files; in every site the non-NA nights are 1..length (trailing NA only, the
#           count equals `length`); rain is NA exactly where the detection is NA; mintemp has further NA on surveyed
#           nights (shipped as NA).
# Mapping (single-season occupancy, one species): unit = site, occasion = night 1..19, y = koala bellow detected
#   0/1. Survey evidence: deposited_matrix (NA = no recording that night; rain NA on exactly the same cells).
#   obs_rain_mm, obs_min_temp_c. unit_: survey year and month (each site was surveyed once, so they are site
#   facts), n_nights (= length), and the documented landscape covariates. DPI_mod_* is the NSW habitat
#   suitability model, built from other data, not from these detections, so it ships. Not shipped: the month and
#   year dummies (recodes of month and year) and the six forest-history dummies (mis-described in the metadata).
#   No coordinates in the deposit. Koala: IUCN VU (flagged under E7, but there is nothing to coarsen).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "law_2021_nsw_koala_occ"
dir <- download_dryad("10.5061/dryad.2rbnzs7pq", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

d <- fread(file.path(dir, "det_data.csv")); u <- fread(file.path(dir, "unit_covs.csv")); s <- fread(file.path(dir, "surv_cov_long.csv"))
stopifnot(nrow(d) == 128, identical(names(d), c("ident", paste0("KoalaPresent.", 1:19))), identical(d$ident, u$ident),
          !anyDuplicated(d$ident), identical(names(s), c("ident", "rain", "mintemp.1")), nrow(s) == 128 * 19,
          identical(s$ident, rep(d$ident, 19)))
Y <- as.matrix(d[, -1]); dimnames(Y) <- list(d$ident, NULL)
stopifnot(all(Y %in% c(0, 1, NA)), all(rowSums(!is.na(Y)) == u$length),
          all(apply(Y, 1, function(r) all(diff(is.na(r)) >= 0))), sum(!is.na(Y)) == 1073)
rain <- matrix(s$rain, 128); tmin <- matrix(s$mintemp.1, 128)
stopifnot(all(is.na(rain) == is.na(Y)), all(is.na(tmin[is.na(Y)])))
stopifnot(all(u$year %in% 2018:2020), all(u$month %in% c(1, 10:12)),
          all(u$yr2018 + u$yr2019 + u$yr2020 == 1), all(u$sep + u$oct + u$nov + u$dec + u$jan == 1))

site_covs <- u[, .(survey_year = year, survey_month = month, n_nights = length,
  habitat_suitability_500m = DPI_mod_500m, habitat_suitability_1km = DPI_mod_1km, habitat_suitability_point = DPI_mod_point,
  elevation_m = DEM, sealed_road_m_500m = sealed_500m, sealed_road_m_1km = sealed_1km,
  unsealed_road_m_500m = unsealed_500m, unsealed_road_m_1km = unsealed_1km,
  low_burn_pct_500m = low_burn_500m, low_burn_pct_1km = low_burn_1km, high_burn_pct_500m = high_burn_500m, high_burn_pct_1km = high_burn_1km,
  topographic_position = Topography, ndvi_sep_500m = NDVI_500m, ndvi_sep_1km = NDVI_1km,
  cleared_pct_500m = clear_500m, cleared_pct_1km = clear_1km, ktsi_500m = KTSI_500m, ktsi_1km = KTSI_1km)]
long <- array_to_eco(Y, taxon = "PHACIN", site_ids = d$ident, site_covs = site_covs,
                     obs_covs = list(rain_mm = rain, min_temp_c = tmin))
stopifnot(nrow(long) == 1073, sum(long$y) == 215, !anyNA(long$obs_rain_mm))

taxa <- make_taxa("PHACIN", "Phascolarctos cinereus", vernacularName = "Koala")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, taxon_iucnCategory)])

dataset <- list(
  title = "Passive acoustic detections of koala bellows over consecutive nights at 128 private native forest sites in north-east New South Wales, 2018-2020",
  creator = "Law, Brad; Kerr, Isobel; Gonsalves, Leroy; Brassil, Traecey; Eichinski, Philip; Truskinger, Anthony; Roe, Paul", pubDate = "2021",
  doi = "10.5061/dryad.2rbnzs7pq", sourceURL = "https://doi.org/10.5061/dryad.2rbnzs7pq",
  citation = "Law, B., Kerr, I., Gonsalves, L., Brassil, T., Eichinski, P., Truskinger, A., & Roe, P. (2021). Mini-acoustic sensors reveal occupancy and threats to koalas (Phascolarctos cinereus) in private native forests [Dataset]. Dryad. https://doi.org/10.5061/dryad.2rbnzs7pq",
  paperDOI = "10.1111/1365-2664.14099",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "AudioMoth acoustic sensors mailed to landholders recorded koala bellows on consecutive nights at 128 sites in private native forests of north-east New South Wales, Australia, in the spring-summer breeding seasons of 2018-2020, to model koala occupancy against roads, NDVI, fire, clearing, harvest history and a habitat suitability model.",
  samplingProtocol = "One AudioMoth sensor per site recording overnight on consecutive nights (up to 19); a night is an occasion, scored 1 if a male koala bellow was detected in the recording.",
  samplingProtocolCode = "acoustic", occasionLength = "1 night",
  surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time",
  closureNote = "Each site was surveyed once, for consecutive nights within one month.",
  taxonInclusion = "single",
  geographicCoverage = "Private native forests, north-east New South Wales, Australia (no coordinates deposited)", temporalCoverage = "2018-10/2020-12",
  notShipped = list(`sep, oct, nov, dec, jan, yr2018, yr2019, yr2020` = "dummy recodes of month and year, which ship as unit_survey_month and unit_survey_year",
                    `recent_harv, padd, youngR, regrowth, mat, euc` = "forest-history class dummies that the deposited metadata describes as 0 = not sampled / 1 = sampled; meaning not recoverable from the deposit"),
  notes = "obs_min_temp_c is NA on some surveyed nights in the source. The habitat suitability covariates are the NSW DPI koala model, independent of these detections.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/law_2021_nsw_koala_occ.R")

stage_dict_row(TABLE,
  description = "Nightly detection/non-detection of koala bellows on AudioMoth acoustic sensors at 128 private native forest sites in north-east New South Wales, Australia (2018-2020), with nightly rain and temperature and 21 landscape covariates per site.",
  url = "https://doi.org/10.5061/dryad.2rbnzs7pq",
  reference = "Law, B., Kerr, I., Gonsalves, L., Brassil, T., Eichinski, P., Truskinger, A., & Roe, P. (2022). Mini-acoustic sensors reveal occupancy and threats to koalas (Phascolarctos cinereus) in private native forests. Journal of Applied Ecology, 59(3), 815-826.",
  doi_paper = "10.1111/1365-2664.14099", doi_data = "10.5061/dryad.2rbnzs7pq",
  original_license = "CC0 1.0", derived_license = "CC0-1.0",
  notes = "Fetched as the Dryad version zip. Forest-history dummies not shipped (metadata mis-describes them).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "acoustic", design = "Single-season (sites surveyed once, 2018-2020)", realm = "Terrestrial", country = "AUS",
  coordinates = "None in source", notes = "Koala (IUCN VU). Occasion = night; up to 19 nights per site.", status = "tagged")
