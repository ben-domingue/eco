#!/usr/bin/env Rscript
# Table:  ahizi_2021_civ_crocodylians_occ
# Source: Dryad doi:10.5061/dryad.15dv41nz5 (CC0 1.0 as shown on the dataset JSON), version
#   148175 (published 2022-11-04). Ahizi, M. N., Kouman, C. Y., Ouattara, A., Kouamé, N. P.,
#   Dede, A., Fairet, E. & Shirley, M. H. Detectability and impact of repetitive surveys on
#   threatened West African crocodylians: Data M1.
# Paper:  Ahizi, M. N., et al. (2021). Detectability and impact of repetitive surveys on
#         threatened West African crocodylians. Ecology and Evolution 11, doi:10.1002/ece3.8188.
# Data:   occupancy.csv (Latin-1): 42 sites (the paper's 38 sites, four of them split into
#         interior/exterior sections) x 5 nightly spotlight surveys; MC1-5 and CS1-5 =
#         detection (0/1) of the slender-snouted crocodile Mecistops cataphractus and the West
#         African crocodile Crocodylus suchus; Surveys1-5 = survey number (1..5, NA when the
#         site had only 3 or 4 surveys); per-survey covariates Lu (moon phase 0-4), vt (wind
#         0/1), Vag (wave height 0-2), Vgto (aquatic vegetation index 0-2), Fish (fishing nets
#         per km), Rain (rain the day before, 0/1), T_day, P_day, T_48h, P_48h (night air
#         temperature and precipitation on the day and the previous 48 h, remote-sensed);
#         site covariates Min (mining) and Plan (plantation), 0/1.
#         Base_GLMM.txt, CS_wariness.txt, MC_wariness.txt: per-survey encounter rates (crocs per
#         km) and wariness indices, the inputs of the paper's GLMMs.
#
# Mapping (standard E1-E6, community occupancy): unit = site (as deposited, accents kept),
#   taxon = MECCAT / CROSUC, occasion = survey night 1..5, y = 0/1 detection. Survey evidence:
#   the deposited matrix: NA = no survey that night (identical NA pattern in MC, CS and Surveys,
#   asserted); 195 surveys at 42 sites, as in the paper. A row for both species at every survey.
#   obs_moon, obs_wind, obs_wave, obs_vegetation, obs_fishnets_per_km, obs_rain_prev_day,
#   obs_temp_day_c, obs_precip_day_mm, obs_temp_48h_c, obs_precip_48h_mm per survey (T_day is NA
#   for one survey, as deposited); unit_mining, unit_plantation per site.
#   Not shipped: the GLMM and wariness files (encounter rates per km and wariness indices are
#   derived ratios of the counts, not counts; the raw per-survey counts and survey lengths are
#   not deposited). Survey dates are not deposited (surveys 2014-2019, consecutive nights).
#   No coordinates are deposited; M. cataphractus is IUCN Critically Endangered.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ahizi_2021_civ_crocodylians_occ"
dir <- download_dryad("10.5061/dryad.15dv41nz5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "occupancy.csv"); stopifnot(file.exists(f))
x <- fread(f, encoding = "Latin-1"); setnames(x, trimws(names(x)))
stopifnot(nrow(x) == 42L, ncol(x) == 68L, !anyDuplicated(x$Sites))
x[, Sites := trimws(iconv(Sites, "latin1", "UTF-8"))]; stopifnot(!anyNA(x$Sites), validUTF8(x$Sites))
oc <- function(v) as.matrix(x[, paste0(v, 1:5), with = FALSE])
MC <- oc("MC"); CS <- oc("CS"); S <- oc("Surveys")
stopifnot(all(is.na(MC) == is.na(CS)), all(is.na(MC) == is.na(S)), all(MC %in% c(0, 1, NA)), all(CS %in% c(0, 1, NA)),
          all(S[!is.na(S)] == col(S)[!is.na(S)]), sum(!is.na(MC)) == 195L,
          all(rowSums(!is.na(MC)) %in% 3:5), all(apply(!is.na(MC), 1, function(r) all(diff(r) <= 0))))  # surveys 1..k, no gaps
stopifnot(all(x$Min %in% 0:1), all(x$Plan %in% 0:1))
cat(sprintf("  42 sites, 195 surveys; detections MC %d, CS %d; sites with MC %d, CS %d\n", sum(MC, na.rm = TRUE),
            sum(CS, na.rm = TRUE), sum(rowSums(MC, na.rm = TRUE) > 0), sum(rowSums(CS, na.rm = TRUE) > 0)))

y <- array(c(MC, CS), dim = c(42L, 5L, 2L), dimnames = list(x$Sites, NULL, c("MECCAT", "CROSUC")))
obs <- list(moon = oc("Lu"), wind = oc("vt"), wave = oc("Vag"), vegetation = oc("Vgto"), fishnets_per_km = oc("Fish"),
            rain_prev_day = oc("Rain"), temp_day_c = oc("T_day"), precip_day_mm = oc("P_day"),
            temp_48h_c = oc("T_48h"), precip_48h_mm = oc("P_48h"))
for (nm in names(obs)) stopifnot(sum(is.na(obs[[nm]]) & !is.na(MC)) == (if (nm == "temp_day_c") 1L else 0L))
long <- array_to_eco(y, site_ids = x$Sites, site_covs = data.frame(mining = x$Min, plantation = x$Plan), obs_covs = obs)
stopifnot(nrow(long) == 2L * 195L, sum(long$y) == sum(MC, CS, na.rm = TRUE))

taxa <- make_taxa(c("MECCAT", "CROSUC"), c("Mecistops cataphractus", "Crocodylus suchus"),
                  vernacularName = c("West African Slender-snouted Crocodile", "West African Crocodile"),
                  taxon_iucnCategory = c("CR", NA))
dataset <- list(
  title = "Repeated nocturnal spotlight surveys of two crocodylians at 42 sites in Côte d'Ivoire, 2014-2019",
  creator = "Ahizi, Michel N'Dede; Kouman, Christine Yaoua; Ouattara, Allassane; Kouamé, N'Dri Pascal; Dede, Azani; Fairet, Emilie; Shirley, Matthew H.",
  pubDate = "2022", doi = "10.5061/dryad.15dv41nz5", sourceURL = "https://doi.org/10.5061/dryad.15dv41nz5",
  citation = "Ahizi, M. N., Kouman, C. Y., Ouattara, A., Kouamé, N. P., Dede, A., Fairet, E., & Shirley, M. H. (2022). Detectability and impact of repetitive surveys on threatened West African crocodylians: Data M1 [Dataset]. Dryad. https://doi.org/10.5061/dryad.15dv41nz5",
  paperDOI = "10.1002/ece3.8188",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection histories of the Critically Endangered slender-snouted crocodile (Mecistops cataphractus) and the West African crocodile (Crocodylus suchus) from 195 nocturnal spotlight surveys on three to five consecutive nights at 42 sites across Côte d'Ivoire, 2014-2019, with moon, wind, wave, vegetation, fishing-net, rain and temperature covariates per survey and mining and plantation per site.",
  samplingProtocol = "Standard nocturnal spotlight (eyeshine) surveys by one observer from a boat, kayak or on foot, at least 10 km per site per night, on three (2014-mid 2016) or five (late 2016-2019) consecutive nights.",
  samplingProtocolCode = "spotlight_survey", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "period (three to five consecutive nights at a site, treated as closed by the authors)", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Côte d'Ivoire: Guinean forest, Sudano-Guinean and Sudanian ecoregions (site names only, no coordinates deposited)",
  temporalCoverage = "2014/2019", coordinatesCoarsened = NA,
  covariateNote = "obs_temp_day_c is NA for one survey, as deposited. obs_vegetation is the per-survey aquatic vegetation index; obs_fishnets_per_km nets seen per km surveyed.",
  notShipped = list(Base_GLMM.txt = "per-survey encounter rates (crocodiles per km) for the count GLMM: ratios, the counts and survey lengths behind them are not deposited",
                    `CS_wariness.txt, MC_wariness.txt` = "per-survey wariness indices (derived)",
                    survey_dates = "not deposited"),
  notes = "Four of the paper's 38 sites are split into interior and exterior sections as deposited (42 units). Survey occasions are consecutive nights; sites surveyed before mid-2016 have three.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/ahizi_2021_civ_crocodylians_occ.R")

stage_dict_row(TABLE,
  description = "Detection histories of two West African crocodylians (Mecistops cataphractus, CR; Crocodylus suchus) from 195 nocturnal spotlight surveys on 3-5 consecutive nights at 42 sites in Côte d'Ivoire, 2014-2019, with per-survey environmental covariates.",
  url = "https://doi.org/10.5061/dryad.15dv41nz5",
  reference = "Ahizi, M. N., Kouman, C. Y., Ouattara, A., Kouamé, N. P., Dede, A., Fairet, E., & Shirley, M. H. (2021). Detectability and impact of repetitive surveys on threatened West African crocodylians. Ecology and Evolution, 11, 15325-15338.",
  doi_paper = "10.1002/ece3.8188", doi_data = "10.5061/dryad.15dv41nz5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First crocodylian table. Encounter-rate and wariness files not shipped (derived ratios). No coordinates in source.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Community occupancy",
  sampling_protocol = "spotlight_survey", design = "Single-season (3-5 consecutive nights)", realm = "Freshwater",
  country = "CIV", coordinates = "None in source", notes = "Two species; occupancy fit species by species in the paper.")
