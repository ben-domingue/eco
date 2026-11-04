#!/usr/bin/env Rscript
# Table:  samek_2024_racerunner_occ
# Source: Dryad doi:10.5061/dryad.cc2fqz6gk (CC0 1.0, as shown on the Dryad page; published
#         2024-11-24). Samek, I., Price, S., Terhune, T. & McNeil, D. (2024). Habitat
#         associations of six-lined racerunners in longleaf pine managed with a short fire
#         rotation for northern bobwhites.
# Paper:  Samek, I.W., Price, S.J., Terhune, T.M. II & McNeil, D.J. (2024). Habitat
#         associations of six-lined racerunners in longleaf pine managed with a short fire
#         rotation for northern bobwhites. Ecosphere, doi:10.1002/ecs2.70126. Single-season
#         occupancy of Aspidoscelis sexlineata on 100 transects in Brunswick County, North
#         Carolina, July-August 2023.
# Data:   SLRA_analysis_data_fordryad.csv, 100 rows (transects t1..t100) x 45 columns:
#         obs1-3 (detection on occasions 1-3, 0/1), wind1-3 (Beaufort), cloud1-3 (%),
#         ordinal1-3 (day of year, 2023), mssr1-3 (minutes since sunrise), temp1-3 (F);
#         site covariates: ocular-tube cover readings (ot_bare ... ot_can), Nudd's board
#         (nudds), NDVI, land cover within 100 m (perc_mpine, perc_grassy, perc_decid,
#         perc_bf, perc_water, as proportions 0-1 despite the "percent" label), distances
#         to the nearest road and cover types (DTN_*, m), proportion burned within the past
#         year within 100 m (perc_burn) and burned-in-past-year flag (burn_stat). README.md
#         describes every column. No missing values: every transect has three surveys.
#
# Mapping (standard: single-season occupancy, E9 core):
#   unit = transect; taxon = ASPSEX; one period; occasion = survey 1..3; y = obsk;
#   date = 2023 + ordinal day (README: collection July-August 2023); obs_: wind (Beaufort),
#   cloud %, minutes since sunrise, temperature F. unit_: every site covariate as deposited
#   (perc_* kept on the deposited 0-1 scale and named _prop). Survey evidence: the
#   deposited transect x occasion matrix (deposited_matrix; complete, no NA). No
#   coordinates deposited. Nothing is a model output. v1.1: closure = closed, occasionKind =
#   time, taxonInclusion = single.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "samek_2024_racerunner_occ"
dir <- download_dryad("10.5061/dryad.cc2fqz6gk", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^SLRA_analysis_data_fordryad\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f)

SITE <- c("ot_bare", "ot_wat", "ot_lit", "ot_cwd", "ot_moss", "ot_grass", "ot_forb", "ot_fern", "ot_shrub", "ot_sap", "ot_can",
          "nudds", "ndvi", "perc_mpine", "perc_grassy", "perc_decid", "perc_bf", "perc_water",
          "DTN_road", "DTN_mpine", "DTN_grassy", "DTN_decid", "DTN_bf", "DTN_water", "perc_burn", "burn_stat")
stopifnot(identical(names(raw), c("transect", paste0(rep(c("obs", "wind", "cloud", "ordinal", "mssr", "temp"), each = 3), 1:3), SITE)),
          nrow(raw) == 100, !anyNA(raw), identical(sort(raw$transect), sort(paste0("t", 1:100))))
Y <- as.matrix(raw[, .(obs1, obs2, obs3)])
stopifnot(all(Y %in% 0:1), all(raw[, .(ordinal1, ordinal2, ordinal3)] >= 182 & raw[, .(ordinal1, ordinal2, ordinal3)] <= 243),  # July-August
          all(raw$ordinal1 < raw$ordinal2 & raw$ordinal2 < raw$ordinal3), all(raw$burn_stat %in% 0:1),
          all(raw[, lapply(.SD, function(x) all(x >= 0 & x <= 1)), .SDcols = patterns("^perc_")]))
dimnames(Y) <- list(raw$transect, NULL)
day <- function(k) format(as.IDate("2022-12-31") + raw[[paste0("ordinal", k)]])
mat <- function(v) as.matrix(raw[, paste0(v, 1:3), with = FALSE])
obs <- list(wind_beaufort = mat("wind"), cloud_pct = mat("cloud"), minutes_since_sunrise = mat("mssr"), temp_f = mat("temp"))
sc <- raw[, SITE, with = FALSE]
setnames(sc, sub("^perc_(.*)$", "\\1_prop", sub("^DTN_(.*)$", "dist_\\1_m", sub("^ot_(.*)$", "ocular_\\1", names(sc)))))
setnames(sc, c("nudds", "ndvi", "burn_prop", "burn_stat"), c("nudds_board", "ndvi", "burned_past_year_prop", "burned_past_year"))
long <- array_to_eco(Y, taxon = "ASPSEX", site_ids = raw$transect, site_covs = sc, obs_covs = obs)
D <- cbind(day(1), day(2), day(3))
long[, date := D[cbind(match(unit, raw$transect), occasion)]]
stopifnot(nrow(long) == 300, sum(long$y) == sum(Y), !anyNA(long$date), !any(grepl("^unit_unit_", names(long))))

# GBIF's backbone has the masculine ending (Aspidoscelis sexlineatus, key 2472425; FUZZY on the
# source's sexlineata): the same species, looked up under the backbone spelling.
taxa <- make_taxa("ASPSEX", "Aspidoscelis sexlineata", vernacularName = "Six-lined racerunner",
                  lookupName = "Aspidoscelis sexlineatus")
dataset <- list(
  title = "Six-lined racerunner detections on 100 transects in bobwhite-managed longleaf pine, Brunswick County, North Carolina, three surveys each, summer 2023",
  creator = "Samek, Isaiah W.; Price, Steven J.; Terhune, Theron M., II; McNeil, Darin J., Jr.",
  pubDate = "2024", doi = "10.5061/dryad.cc2fqz6gk", sourceURL = "https://doi.org/10.5061/dryad.cc2fqz6gk",
  citation = "Samek, I., Price, S., Terhune, T., & McNeil, D. (2024). Habitat associations of six-lined racerunners in longleaf pine managed with a short fire rotation for northern bobwhites [Dataset]. Dryad. https://doi.org/10.5061/dryad.cc2fqz6gk",
  paperDOI = "10.1002/ecs2.70126",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the six-lined racerunner (Aspidoscelis sexlineata) on 100 transects surveyed three times each in July-August 2023 in longleaf pine savanna managed with frequent prescribed fire for northern bobwhites, with survey wind, cloud, time since sunrise and temperature, and transect ground-cover, vegetation-structure, NDVI, land-cover, distance-to-cover and burn covariates.",
  samplingProtocol = "Visual-encounter transect surveys, three per transect between early July and late August 2023; wind, cloud cover, time and temperature recorded per survey. Transect length and survey duration are in the paper.",
  samplingProtocolCode = "transect_search", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion (three surveys within one summer)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Brunswick County, North Carolina, USA (longleaf pine savanna on a bobwhite-managed property); no coordinates deposited",
  temporalCoverage = "2023-07-03/2023-08-22",
  coordinatesCoarsened = NA,
  notShipped = list(none = "every deposited column is shipped"),
  notes = "date = 2023 + the deposited ordinal day. The deposit's perc_* land-cover columns are proportions (0-1) and are named _prop here; ocular-tube readings (unit_ocular_*) are as deposited (0-100). Minutes since sunrise and temperature (F) per survey as deposited.")
dataset$temporalCoverage <- paste(min(long$date), max(long$date), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/samek_2024_racerunner_occ.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of the six-lined racerunner on 100 transects in longleaf pine managed with a short fire rotation for northern bobwhites, Brunswick County, North Carolina, three surveys each in July-August 2023, with survey weather and timing and transect ground cover, vegetation structure, land cover, distances to cover types and burn history.",
  url = "https://doi.org/10.5061/dryad.cc2fqz6gk",
  reference = "Samek, I. W., Price, S. J., Terhune, T. M., II, & McNeil, D. J. (2024). Habitat associations of six-lined racerunners in longleaf pine managed with a short fire rotation for northern bobwhites. Ecosphere.",
  doi_paper = "10.1002/ecs2.70126", doi_data = "10.5061/dryad.cc2fqz6gk",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Lizard single-season occupancy. No coordinates deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Single-season occupancy",
  sampling_protocol = "transect_search", design = "Single-season (3 surveys)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = paste0(sum(Y), " detections over 300 surveys."))
