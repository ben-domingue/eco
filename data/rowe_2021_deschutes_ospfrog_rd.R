#!/usr/bin/env Rscript
# Table:  rowe_2021_deschutes_ospfrog_rd
# Source: USGS ScienceBase doi:10.5066/P9R1S1BD (USGS data release, 2021; use constraints "No use
#         constraints. Public domain data from the U.S. Government are freely redistributable with
#         proper metadata and source attribution"; recorded as CC0 1.0)
#   Rowe, J.C., Duarte, A., Pearl, C.A., McCreary, B., Haggerty, P.K., and Adams, M.J., 2021,
#   Capture-mark-recapture data for Oregon spotted frogs (Rana pretiosa) along the Deschutes River,
#   Oregon, 2016-2019: U.S. Geological Survey data release.
# Data:   one workbook. CMRdata: 484 rows (site DS / SCE / SCSW, PIT tag, sex, size class 0 = snout-
#         urostyle <= 58.5 mm, 1 = larger) x 30 visit columns (Summer 2016; Spring, Summer and Fall
#         2017-2019; three consecutive-day visits each), 1 detected / 0 not; the metadata say one
#         tag appears twice because the frog was detected at two sites. DetCov: the 90 site visits
#         (site, visit, day of year, year, season, air temperature, wind 0 calm / 1 breeze). FlowData:
#         daily river flow, reservoir storage and drought indices 2010-2019. AreaWet_DSWE and
#         AreaWet_ModelPred: remotely sensed and model-predicted wetted area per site and date.
#         Asserted: no missing cells; every site has all 30 visits in DetCov; tags read as text
#         (15-digit PIT codes).
# Mapping: robust design. unit = frog (PIT tag), cluster_id = site, period = season (1 = summer 2016,
#   2 = spring 2017, ... 10 = fall 2019), occasion = visit 1-3, y = detected. surveyEvidence
#   sample_table: DetCov lists every site visit, and the matrix has a cell for each. obs_date_doy,
#   obs_temp_c, obs_wind (DetCov, per site visit; the release's day of year is "days from the start
#   of the year", so no ISO date is built from it). unit_sex, unit_size_large (0/1 as deposited).
#   Frogs are wild-caught adults of unknown age: every history starts at period 1 (E4.4), as the
#   deposited matrix does.
# Not shipped: the frog detected at two sites (two rows of one tag: its visits at the two sites are
#   different dates under one key); FlowData and the wetted-area series (site hydrology; the
#   model-predicted wetted area is a model output); no coordinates are in the workbook (Rana
#   pretiosa is IUCN VU).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "rowe_2021_deschutes_ospfrog_rd"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5f3b0f8f82ce8df5b6c4129c?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
xf <- download_cached(fl[["Oregon_spotted_frog_monitoring_data_for_Deschutes_survival_analysis_2016-2019.xlsx"]], TABLE, filename = "osf.xlsx")
cm <- as.data.table(read_excel(xf, "CMRdata", col_types = "text"))
dc <- as.data.table(read_excel(xf, "DetCov"))
stopifnot(nrow(cm) == 484, ncol(cm) == 34, uniqueN(cm$tag) == 483, all(nchar(cm$tag) == 15), nrow(dc) == 90, !anyNA(dc),
          all(dc[, .N, by = site]$N == 30))
two <- cm[duplicated(tag), tag]; stopifnot(length(two) == 1, uniqueN(cm[tag == two, site]) == 2)
n_two_y <- sum(as.integer(unlist(cm[tag == two, -(1:4)])))
stopifnot(sum(as.integer(unlist(cm[, -(1:4)]))) == 675)
cm <- cm[tag != two]
vc <- names(cm)[-(1:4)]
stopifnot(length(vc) == 30, all(grepl("^(Spring|Summer|Fall)_v[123]_20(16|17|18|19)$", vc)))
L <- melt(cm, id.vars = c("site", "tag", "sex", "size"), variable.name = "col", value.name = "v", variable.factor = FALSE)
stopifnot(setequal(unique(L$v), c("0", "1")))
L[, `:=`(season = tolower(sub("_.*", "", col)), visit = as.integer(sub(".*_v([123])_.*", "\\1", col)), year = as.integer(sub(".*_", "", col)))]
sk <- unique(L[, .(year, season)])[, s := match(season, c("spring", "summer", "fall"))][order(year, s)][, period := .I]
stopifnot(nrow(sk) == 10)
L <- merge(L, sk[, .(year, season, period)], by = c("year", "season"))
L <- merge(L, dc[, .(site, visit, year, season, doy, temp, wind)], by = c("site", "visit", "year", "season"))
stopifnot(nrow(L) == 482 * 30)
long <- L[, .(unit = tag, taxon = "RANPRE", y = as.integer(v), period, occasion = visit, cluster_id = site,
              unit_sex = sex, unit_size_large = as.integer(size), obs_date_doy = as.integer(doy), obs_temp_c = temp, obs_wind = as.integer(wind))]
stopifnot(sum(long$y) == 675 - n_two_y, uniqueN(long$unit) == 482)
periods <- sk[, .(period, year, season)]
taxa <- make_taxa("RANPRE", "Rana pretiosa", vernacularName = "Oregon spotted frog")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Capture histories of 482 PIT-tagged Oregon spotted frogs on three-visit seasonal surveys at three wetland sites on the upper Deschutes River, Oregon, 2016-2019",
  creator = "Rowe, Jennifer C.; Duarte, Adam; Pearl, Christopher A.; McCreary, Brome; Haggerty, Patricia K.; Adams, Michael J.",
  pubDate = "2021", doi = "10.5066/P9R1S1BD", sourceURL = "https://doi.org/10.5066/P9R1S1BD",
  citation = "Rowe, J.C., Duarte, A., Pearl, C.A., McCreary, B., Haggerty, P.K., and Adams, M.J., 2021, Capture-mark-recapture data for Oregon spotted frogs (Rana pretiosa) along the Deschutes River, Oregon, 2016-2019: U.S. Geological Survey data release, https://doi.org/10.5066/P9R1S1BD.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Oregon spotted frogs were captured and PIT-tagged at three wetland sites on the upper Deschutes River, Oregon, on three consecutive-day visits each spring, summer and fall from 2016 to 2019, to relate survival and abundance to wetland inundation driven by river flow.",
  samplingProtocol = "Capture-mark-recapture surveys: three consecutive-day visits per site each season; frogs captured, PIT-tagged, sexed, sized and released, with air temperature and wind recorded per visit.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "sample_table", responseType = "detection", unitKind = "individual",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "Robust design: period = season, occasion = one of three consecutive-day visits to the frog's site.",
  geographicCoverage = list(description = "Upper Deschutes River wetlands, Deschutes County, Oregon, USA",
                            boundingBox = list(west = -121.632223, east = -121.419413, south = 43.713060, north = 43.957463)),
  temporalCoverage = "2016-07/2019-10",
  notShipped = list(two_site_frog = "one PIT tag recorded at two sites (two rows; dropped)", hydrology = "FlowData: daily flow, reservoir storage and drought indices",
                    wetted_area = "AreaWet_DSWE (remotely sensed) and AreaWet_ModelPred (model-predicted, a model output) per site and date"),
  notes = "Rana pretiosa is IUCN VU; the release has site codes only, no coordinates. obs_date_doy as deposited ('days from the start of the year').")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/rowe_2021_deschutes_ospfrog_rd.R")
stage_dict_row(TABLE,
  description = "Capture histories of 482 PIT-tagged Oregon spotted frogs at three upper Deschutes River wetland sites, Oregon, on three consecutive-day visits each season 2016-2019 (robust design), with sex, size class and visit weather.",
  url = "https://doi.org/10.5066/P9R1S1BD",
  reference = "Rowe, J.C., Duarte, A., Pearl, C.A., McCreary, B., Haggerty, P.K., and Adams, M.J. (2021). Capture-mark-recapture data for Oregon spotted frogs (Rana pretiosa) along the Deschutes River, Oregon, 2016-2019. U.S. Geological Survey data release.",
  doi_data = "10.5066/P9R1S1BD", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Robust design from the deposited matrix; visit covariates from DetCov.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Robust design", sampling_protocol = "visual_encounter",
  design = "Multi-season (10 seasons x 3 visits)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "IUCN VU frog; wetland inundation study.")
