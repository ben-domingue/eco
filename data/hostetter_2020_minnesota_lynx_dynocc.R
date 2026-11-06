#!/usr/bin/env Rscript
# Table:  hostetter_2020_minnesota_lynx_dynocc
# Source: Dryad doi:10.5061/dryad.66t1g1jzq (CC0 1.0, as shown on the Dryad page; published
#         2020-04-21). Hostetter, N., Ryan, D., Grosshuesch, D., Catton, T., Malick-Wahls, S.,
#         Smith, T. & Gardner, B. Data from: Quantifying spatiotemporal occupancy dynamics and
#         multi-year core-use areas at a species range boundary.
# Paper:  Hostetter, N.J. et al. (2020). Diversity and Distributions, doi:10.1111/ddi.13066.
#         Canada lynx snow-track surveys in grid cells of the northeastern Minnesota lynx
#         geographic unit (Superior National Forest), five winters 2014-15 to 2018-19, > 17,000
#         km surveyed; dynamic occupancy in JAGS (abstract).
# Data:   data.RData, list `data`: jags.data (y: 431 surveyed cells x 18 surveys x 5 winters,
#         0/1/NA; surveyedCells = the cells' index among nsite = 884 grid cells; yearSite /
#         nyrsSamp = which winters each cell was sampled; effort (log of survey effort; the unit
#         is not stated), SnowCond (1-3), SDaySurv (standardized day of year) and SDaySurv2 (its
#         square, asserted) per survey; RoadCondMat (1/2 per cell-winter); Spcteverg,
#         SAvgSnowDepth, SLidarHigh, SLidarMid (standardized, per grid cell)) and zik (884 x 5,
#         the model's initial / known occupancy states, not observations). LynxDynamicOccupancy.R
#         is the authors' model. Asserted: y is non-NA exactly in each cell's sampled winters
#         (yearSite) and exactly where effort is non-NA; 25 surveys have effort = -Inf (zero
#         effort; all y = 0).
# Mapping (standard: dynamic occupancy, E9 core): unit = grid cell ("C" + its index among the 884
#   cells); taxon = LYNCAN; period = winter 1..5 (__periods); occasion = survey 1..18; y = the
#   cell. Survey evidence: effort_table: a survey is a non-NA y with finite effort; the 25
#   zero-effort zeros are not surveys (dropped, as the model gives them p = 0).
#   obs_: log effort, snow condition, day of year (standardized); period_road_condition; unit_:
#   the four standardized cell covariates. Not shipped: zik (model states), SDaySurv2 (square of
#   SDaySurv). No coordinates (cell indices only). Canada lynx is US ESA threatened; IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hostetter_2020_minnesota_lynx_dynocc"
dir <- download_dryad("10.5061/dryad.66t1g1jzq", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^data\\.RData$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
e <- new.env(); load(f, envir = e); j <- e$data$jags.data
y <- j$y; ef <- j$effort
stopifnot(identical(dim(y), c(431L, 18L, 5L)), j$nsite == 884, length(j$surveyedCells) == 431, !anyDuplicated(j$surveyedCells),
          identical(is.na(y), is.na(ef)), all(y %in% c(0, 1, NA)), sum(!is.na(y)) == 4424,
          sum(is.infinite(ef)) == 25, all(y[is.infinite(ef)] == 0),
          all(abs(j$SDaySurv2 - j$SDaySurv^2) < 1e-8, na.rm = TRUE),
          all(sapply(1:431, function(s) setequal(j$yearSite[s, seq_len(j$nyrsSamp[s])], which(apply(!is.na(y[s, , ]), 2, any))))))
w <- which(!is.na(y) & is.finite(ef), arr.ind = TRUE)
cell <- j$surveyedCells[w[, 1]]
long <- data.table(unit = sprintf("C%03d", cell), taxon = "LYNCAN", y = as.integer(y[w]), period = w[, 3], occasion = w[, 2],
                   obs_log_effort = ef[w], obs_snow_condition = as.integer(j$SnowCond[w]), obs_doy_std = j$SDaySurv[w],
                   period_road_condition = as.integer(j$RoadCondMat[cbind(w[, 1], w[, 3])]),
                   unit_pct_evergreen_std = j$Spcteverg[cell], unit_avg_snow_depth_std = j$SAvgSnowDepth[cell],
                   unit_lidar_high_std = j$SLidarHigh[cell], unit_lidar_mid_std = j$SLidarMid[cell])
long <- order_eco(long)
stopifnot(nrow(long) == 4424 - 25, sum(long$y) == 616, !anyNA(long$period_road_condition))
periods <- data.table(period = 1:5, period_winter = c("2014-15", "2015-16", "2016-17", "2017-18", "2018-19"))
taxa <- make_taxa("LYNCAN", "Lynx canadensis", vernacularName = "Canada lynx")
dataset <- list(
  title = "Canada lynx snow-track detections in 431 grid cells of northeastern Minnesota, up to 18 surveys per winter, five winters 2014-15 to 2018-19",
  creator = "Hostetter, Nathan J.; Ryan, Daniel; Grosshuesch, David; Catton, Timothy; Malick-Wahls, Sarah; Smith, Tamara; Gardner, Beth", pubDate = "2020",
  doi = "10.5061/dryad.66t1g1jzq", sourceURL = "https://doi.org/10.5061/dryad.66t1g1jzq",
  citation = "Hostetter, N., Ryan, D., Grosshuesch, D., Catton, T., Malick-Wahls, S., Smith, T., & Gardner, B. (2020). Data from: Quantifying spatiotemporal occupancy dynamics and multi-year core-use areas at a species range boundary [Dataset]. Dryad. https://doi.org/10.5061/dryad.66t1g1jzq",
  paperDOI = "10.1111/ddi.13066",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of Canada lynx (Lynx canadensis) tracks on repeated snow-track surveys of grid cells in the northeastern Minnesota lynx geographic unit (Superior National Forest), winters 2014-15 to 2018-19, with log survey effort, snow and road conditions, standardized survey date and standardized forest, snow-depth and lidar canopy covariates per cell.",
  samplingProtocol = "Spatially and temporally replicated snow-track surveys along roads and trails in grid cells after fresh snow, up to 18 surveys per cell per winter; survey effort and snow conditions recorded.",
  samplingProtocolCode = "track_survey", surveyEvidence = "effort_table", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a winter, open between the five winters (dynamic occupancy)",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_log_effort",
  geographicCoverage = "Northeastern Minnesota lynx geographic unit and Superior National Forest, Minnesota, USA; grid-cell indices only, no coordinates deposited",
  temporalCoverage = "2014-11/2019-04",
  notShipped = list(zik = "the model's initial / known occupancy states per cell and winter (not observations)",
                    SDaySurv2 = "square of the standardized day of year (asserted)",
                    zero_effort = "25 surveys with effort -Inf (zero effort) and y = 0: not surveys"),
  notes = "obs_log_effort is the deposited log effort (unit not stated in the deposit). obs_doy_std and the unit_ covariates are standardized as deposited. temporalCoverage is the five winters; exact survey dates are not deposited. Canada lynx is listed as threatened under the US Endangered Species Act; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hostetter_2020_minnesota_lynx_dynocc.R")
stage_dict_row(TABLE,
  description = "Snow-track detection/non-detection of Canada lynx in 431 grid cells of northeastern Minnesota, five winters 2014-15 to 2018-19, with effort and snow covariates.",
  url = "https://doi.org/10.5061/dryad.66t1g1jzq",
  reference = "Hostetter, N. J. et al. (2020). Quantifying spatiotemporal occupancy dynamics and multi-year core-use areas at a species range boundary. Diversity and Distributions.",
  doi_paper = "10.1111/ddi.13066", doi_data = "10.5061/dryad.66t1g1jzq", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic occupancy from snow tracking; zero-effort surveys dropped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "track_survey", design = "Multi-season (5 winters, up to 18 surveys)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "ESA-threatened lynx; cell indices only.")
