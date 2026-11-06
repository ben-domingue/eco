#!/usr/bin/env Rscript
# Table:  rose_2024_sjvalley_leglesslizard_occ
# Source: USGS ScienceBase doi:10.5066/P9R7UIV7 (USGS data release, published 2024-05-24;
#         use constraints name no restriction, only where to direct questions; US public domain,
#         recorded as CC0 1.0)
#   Rose, J.P., Camp, S.M., Sheikh, Z.N., Johnson, C.B., Lei, S.H., Napolitano, G.R., Schoenig,
#   E.J., Macias, D.A., Jordan, A.C., and Halstead, B.J., 2024, Occupancy surveys for the Temblor
#   legless lizard (Anniella alexanderae) in the San Joaquin Valley, California 2022 to 2023:
#   U.S. Geological Survey data release. Analysis code: doi:10.5066/P95O3WW2 (not used).
# Data:   TLL_site_data.csv: 89 sites (cover-board arrays) with centroid latitude / longitude
#         (WGS84), GRTS-random vs manually chosen, years sampled, the number of surveys per year
#         and per week (secondary occasion), site-year detection summaries, distance to the
#         nearest ephemeral stream (m) and a high-clay indicator. TLL_survey_data.csv: 563
#         cover-board checks (site x year x check number) with date, start time, week of the
#         season, secondary occasion (week index within year), detection 0/1, substrate
#         temperature (handheld), iButton temperature and humidity (67 / 68 missing), and
#         mu/sd/tau of the priors the authors used to impute missing iButton values.
#         Asserted: one survey row per site x year x check, checks numbered 1..K with K the
#         site file's K_site_<yy>, and every site-year in the site file has its surveys.
#
# Mapping: unit = site, taxon = ANNALE, period = year (2022, 2023), occasion = check number
#   (time-ordered within year), y = ll.det (surveyEvidence sample_table: a row of the survey
#   file is a check). obs_week = secondary occasion (week) for multi-scale models, obs_ time of
#   day (radians), day of season, substrate temperatures and humidity; unit_ covariates and
#   coordinates from the site file. Coordinates kept as published: the species is not on the
#   IUCN Red List under its own name (GBIF's IUCN record is for Anniella pulchra) and the
#   release does not flag it. Not shipped: the imputation priors (mu/sd/tau .temp/.rh) are
#   model inputs, and the site-year detection summaries are derived from the checks.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "rose_2024_sjvalley_leglesslizard_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/663bfe55d34e77890839c348?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
s <- fread(download_cached(fl[["TLL_site_data.csv"]], TABLE, filename = "TLL_site_data.csv"))
v <- fread(download_cached(fl[["TLL_survey_data.csv"]], TABLE, filename = "TLL_survey_data.csv"))
stopifnot(nrow(s) == 89, !anyDuplicated(s$Site_ID), nrow(v) == 563, !anyDuplicated(v[, .(Site_ID, year, check)]),
          all(v$year %in% 2022:2023), all(v$ll.det %in% 0:1), sum(v$ll.det) == 54, all(v$Site_ID %in% s$Site_ID))
k <- v[, .(n = .N, mx = max(check)), by = .(Site_ID, year)]
ks <- melt(s[, .(Site_ID, `2022` = K_site_22, `2023` = K_site_23)], id.vars = "Site_ID", variable.name = "year", value.name = "K")[!is.na(K)]
ks[, year := as.integer(as.character(year))]
m <- merge(k, ks, by = c("Site_ID", "year"), all = TRUE)
stopifnot(!anyNA(m), all(m$n == m$K), all(m$n == m$mx))
# site-year detection summary agrees with the checks
dsum <- v[, .(det = max(ll.det)), by = .(Site_ID, year)]
chk <- merge(dsum, melt(s[, .(Site_ID, `2022` = ll_det_22, `2023` = ll_det_23)], id.vars = "Site_ID", variable.name = "year")[!is.na(value)][, year := as.integer(as.character(year))], by = c("Site_ID", "year"))
stopifnot(nrow(chk) == nrow(dsum), all(chk$det == chk$value))
long <- merge(v[, .(Site_ID, year, check, y = ll.det, date = format(as.IDate(date)), obs_start_time = Start.Time, obs_week = sec.occasion,
                    obs_week_of_season = week, obs_time_of_day_rad = tod, obs_day_of_season = dos, obs_substrate_temp_c = TempSubstrate,
                    obs_ibutton_temp_c = ib.temp, obs_ibutton_rh_pct = ib.rh)],
              s[, .(Site_ID, unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude, unit_grts_random = random,
                    unit_stream_dist_m = stream_dist_m, unit_high_clay = clay)], by = "Site_ID")
long[, `:=`(unit = as.character(Site_ID), taxon = "ANNALE", period = year - 2021L, occasion = check)]
long[, c("Site_ID", "year", "check") := NULL]
stopifnot(nrow(long) == 563)
taxa <- make_taxa("ANNALE", "Anniella alexanderae", vernacularName = "Temblor legless lizard")
dataset <- list(
  title = "Temblor legless lizard cover-board occupancy surveys at 89 sites, San Joaquin Valley, California, 2022-2023",
  creator = "Rose, Jonathan P.; Camp, Sabrena M.; Sheikh, Zarina N.; Johnson, Chelsea B.; Lei, Samuel H.; Napolitano, Giancarlo R.; Schoenig, Elliot J.; Macias, Daniel A.; Jordan, Anna C.; Halstead, Brian J.",
  pubDate = "2024", doi = "10.5066/P9R7UIV7", sourceURL = "https://doi.org/10.5066/P9R7UIV7",
  citation = "Rose, J.P., Camp, S.M., Sheikh, Z.N., Johnson, C.B., Lei, S.H., Napolitano, G.R., Schoenig, E.J., Macias, D.A., Jordan, A.C., and Halstead, B.J., 2024, Occupancy surveys for the Temblor legless lizard (Anniella alexanderae) in the San Joaquin Valley, California 2022 to 2023: U.S. Geological Survey data release, https://doi.org/10.5066/P9R7UIV7.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints only direct questions to the point of contact)"),
  abstract = "Survey effort and results of USGS cover-board surveys for the Temblor legless lizard in 2022 and 2023, with detection covariates (substrate temperature and humidity, time of day, day of season) and occupancy covariates (distance to the nearest ephemeral stream, soil clay content), gathered to inform a US Fish and Wildlife Service Species Status Assessment.",
  samplingProtocol = "Cover-board arrays at GRTS-random and manually chosen sites; boards checked repeatedly, several times within each week (secondary occasion) of the February-May field season, recording whether a Temblor legless lizard was under any board.",
  samplingProtocolCode = "cover_board", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = cover-board check within a field season; obs_week gives the week (secondary occasion) for the authors' multi-scale model", occasionKind = "time",
  taxonInclusion = "single",
  geographicCoverage = list(description = "Western San Joaquin Valley and Temblor Range foothills, California, USA",
                            boundingBox = list(west = min(s$Longitude), east = max(s$Longitude), south = min(s$Latitude), north = max(s$Latitude))),
  temporalCoverage = "2022-02/2023-05",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS; the species has no IUCN assessment under its own name and the release does not flag it"),
  notShipped = list(imputation_priors = "mu/sd/tau of temperature and humidity priors: model inputs, not observations",
                    site_year_summaries = "ll_det_22, ll_det_23, ll_det_22_23, K_site_*, nsec_*, sec*_: derived from the checks (asserted equal)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:2, year = 2022:2023),
                  script = "data/rose_2024_sjvalley_leglesslizard_occ.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection of the Temblor legless lizard on 563 cover-board checks at 89 sites in the San Joaquin Valley, California, 2022-2023, with substrate temperature and humidity, time of day, week and day of season, site coordinates, stream distance and soil clay class.",
  url = "https://doi.org/10.5066/P9R7UIV7",
  reference = "Rose, J.P., et al. (2024). Occupancy surveys for the Temblor legless lizard (Anniella alexanderae) in the San Joaquin Valley, California 2022 to 2023. U.S. Geological Survey data release.",
  doi_data = "10.5066/P9R7UIV7", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Multi-scale design (checks within weeks within years): occasion = check, obs_week = week.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Single-season occupancy (multi-scale)", sampling_protocol = "cover_board",
  design = "Multi-season (2 years x up to 11 checks)", realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Species described 2013; surveys for a USFWS Species Status Assessment.")
