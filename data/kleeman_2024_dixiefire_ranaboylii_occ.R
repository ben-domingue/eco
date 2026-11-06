#!/usr/bin/env Rscript
# Table:  kleeman_2024_dixiefire_ranaboylii_occ
# Source: USGS ScienceBase doi:10.5066/P14TDU8A (USGS data release, published 2024-11-15; use
#         constraints "No use constraints", questions to the point of contact; US public domain,
#         recorded as CC0 1.0)
#   Kleeman, P.M., Rose, J.P., and Halstead, B.J., 2024, Foothill yellow-legged frog (Rana boylii)
#   2022 site and survey data in and near the footprint of the 2021 Dixie Fire, northeastern
#   California, USA: U.S. Geological Survey data release.
# Paper:  Halstead, B.J., Kleeman, P.M., and Rose, J.P., 2025, Using structural causal modeling to
#   infer the effects of wildfire on foothill yellow-legged frog occurrence. Journal of Fish and
#   Wildlife Management 15(2):419-431, doi:10.3996/JFWM-24-037.
# Data:   RABO_DF_occ_site_data.csv: 43 stream-segment sites with burn status (0/1; burn_code is the
#         same variable as a 1/2 index), visually estimated pre-fire canopy cover (%) and its z-score,
#         and site summaries (n_survey, dc = surveys with a detection, det = detected at the site).
#         RABO_TTD_occ_data.csv: 83 surveys (site x survey_no 1..2) with survey duration (min), time to
#         first detection (min, NA when not detected), d (1 = not detected) and obs (1 = detected).
#         Asserted: one row per site x survey_no, d = 1 - obs, ttd present exactly when obs = 1 and
#         never beyond the survey's duration, and the site summaries equal the surveys.
# Mapping: unit = site, taxon = RANBOY, occasion = survey_no, y = obs (surveyEvidence sample_table:
#   a row of the survey file is a survey). Time to detection (ruling 2026-11-06): obs_ttd_min = ttd,
#   or the survey duration where the frog was not detected, and obs_ttd_censored = 1 there, 0
#   otherwise; obs_survey_min = duration. unit_burn and unit_canopy_cover_pre_pct from the site
#   file. No coordinates are deposited. Not shipped: burn_code (a recode of burn), z_cc_pre (the
#   z-score of cc_pre, recoverable), and the site summaries (derived from the surveys, asserted).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "kleeman_2024_dixiefire_ranaboylii_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/6720161bd34ed0f827eaa427?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
s <- fread(download_cached(fl[["RABO_DF_occ_site_data.csv"]], TABLE, filename = "RABO_DF_occ_site_data.csv"))
v <- fread(download_cached(fl[["RABO_TTD_occ_data.csv"]], TABLE, filename = "RABO_TTD_occ_data.csv"))
stopifnot(nrow(s) == 43, !anyDuplicated(s$site), nrow(v) == 83, !anyDuplicated(v[, .(site, survey_no)]),
          all(v$site %in% s$site), all(s$site %in% v$site), all(v$obs %in% 0:1), all(v$d == 1 - v$obs),
          identical(is.na(v$ttd), v$obs == 0), all(v$ttd[v$obs == 1] <= v$survey_time[v$obs == 1]),
          sum(v$obs) == 8, all(v$survey_time > 0), all(s$burn_code == s$burn + 1))
sm <- v[, .(n = .N, dc = sum(obs), mx = max(survey_no)), by = site][s, on = "site"]
stopifnot(all(sm$n == sm$n_survey), all(sm$dc == sm$i.dc), all(sm$mx == sm$n), all(sm$det == as.integer(sm$dc > 0)))
long <- v[s, on = "site", .(unit = site, taxon = "RANBOY", y = obs, occasion = as.integer(survey_no),
                            unit_burn = burn, unit_canopy_cover_pre_pct = cc_pre,
                            obs_survey_min = survey_time, obs_ttd_min = ifelse(obs == 1, ttd, survey_time),
                            obs_ttd_censored = 1L - obs)]
stopifnot(nrow(long) == 83, sum(long$obs_ttd_censored) == 75)
taxa <- make_taxa("RANBOY", "Rana boylii", vernacularName = "Foothill yellow-legged frog")
dataset <- list(
  title = "Foothill yellow-legged frog time-to-detection occupancy surveys at 43 stream sites in and near the 2021 Dixie Fire, California, 2022",
  creator = "Kleeman, Patrick M.; Rose, Jonathan P.; Halstead, Brian J.",
  pubDate = "2024", doi = "10.5066/P14TDU8A", sourceURL = "https://doi.org/10.5066/P14TDU8A",
  citation = "Kleeman, P.M., Rose, J.P., and Halstead, B.J., 2024, Foothill yellow-legged frog (Rana boylii) 2022 site and survey data in and near the footprint of the 2021 Dixie Fire, northeastern California, USA: U.S. Geological Survey data release, https://doi.org/10.5066/P14TDU8A.",
  paperDOI = "10.3996/JFWM-24-037",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Visual encounter surveys for foothill yellow-legged frogs at 43 stream segments in and near the footprint of the 2021 Dixie Fire, northeastern California, in July and August 2022, one year after the fire. Each site was surveyed once or twice; each survey records its duration and the time to first detection of the frog. Site covariates are burn status and pre-fire canopy cover.",
  samplingProtocol = "Visual encounter surveys of stream segments, up to two per site in summer 2022, recording the survey duration and the time to first detection of Rana boylii.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "two surveys per site within one summer", occasionKind = "time",
  taxonInclusion = "single",
  geographicCoverage = list(description = "Feather River and North Fork Feather River watersheds, Plumas and Butte counties, northeastern California, USA",
                            boundingBox = list(west = -121.7175, east = -120.0916, south = 39.8254, north = 40.8471)),
  temporalCoverage = "2022-07/2022-08",
  notShipped = list(burn_code = "a 1/2 recode of burn",
                    z_cc_pre = "z-score of cc_pre (recoverable from unit_canopy_cover_pre_pct)",
                    site_summaries = "n_survey, dc, det: derived from the surveys (asserted equal)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/kleeman_2024_dixiefire_ranaboylii_occ.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection and time to first detection of foothill yellow-legged frogs on 83 visual encounter surveys at 43 stream sites in and near the 2021 Dixie Fire, California, 2022, with burn status and pre-fire canopy cover.",
  url = "https://doi.org/10.5066/P14TDU8A",
  reference = "Halstead, B.J., Kleeman, P.M., and Rose, J.P. (2025). Using structural causal modeling to infer the effects of wildfire on foothill yellow-legged frog occurrence. Journal of Fish and Wildlife Management 15(2):419-431.",
  doi_paper = "10.3996/JFWM-24-037", doi_data = "10.5066/P14TDU8A", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Time to detection as obs_ttd_min with obs_ttd_censored (ruling 2026-11-06).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Single-season occupancy (time to detection)", sampling_protocol = "visual_encounter",
  design = "Single-season (up to 2 surveys)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Post-fire survey one year after the 2021 Dixie Fire; 8 detections.")
