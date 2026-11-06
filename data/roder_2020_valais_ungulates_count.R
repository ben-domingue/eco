#!/usr/bin/env Rscript
# Table:  roder_2020_valais_ungulates_count
# Source: Dryad doi:10.5061/dryad.2v6wwpzhx (CC0 1.0, as shown on the Dryad page; published
#         2020-02-18). Roder, S., Biollaz, F., Mettaz, S., Zimmermann, F., Manz, R., Kery, M.,
#         Vignali, S., Fumagalli, L., Arlettaz, R. & Braunisch, V. Data from: Deer density drives
#         habitat use of establishing wolves in the Western European Alps.
# Paper:  Roder, S. et al. (2020). Journal of Applied Ecology 57(5), doi:10.1111/1365-2664.13609.
#         Snow-tracking of ungulates along 218 1-km transects in 34 10 x 10 km squares, each
#         walked twice per winter (December-March) in four winters from 2012/13, by the same
#         observer per transect; "we estimated the minimal number of individuals present at each
#         visit"; snow covariates and fresh snow from 56 weather stations (Dryad methods).
# Data:   transect_2012.csv .. transect_2015.csv (";"-separated; one per winter starting that
#         year; 434-436 rows = transect x RUN 1-2): DATE (dd.mm.yyyy), QUAD (10-km square), TRANS,
#         TR_ID, CC / CE / RR / SS / CI = minimum number of roe deer, red deer, chamois, wild boar,
#         ibex (NA = not walked, identical across species, asserted), SNOW_H (snow height),
#         SNOW_C (snow quality a / f), SNOW_FO / SNOW_OP (snow cover in forest / open), RUN, STAT
#         (weather station), DSLSF (days since last snowfall), NWSN (fresh snow), S_C_C (a 1-3
#         snow class). buffer_data_vs_200.csv / _350.csv: habitat covariates per transect buffer
#         (not shipped: several columns mis-parsed by the authors' export, e.g. "Apr 35").
# Mapping (standard: dynamic community N-mixture, E9 core): unit = TR_ID; cluster_id = QUAD;
#   period = winter 1..4 (2012/13-2015/16, __periods); occasion = RUN 1..2; taxon = species
#   code; y = minimum number of individuals; date = DATE. obs_: the snow covariates and weather
#   station as deposited. Survey evidence: deposited_matrix (NA = not walked). Mouflon, named
#   in the methods, has no column. No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roder_2020_valais_ungulates_count"
dir <- download_dryad("10.5061/dryad.2v6wwpzhx", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fs <- sort(list.files(dir, "^transect_201[2-5]\\.csv$", recursive = TRUE, full.names = TRUE)); stopifnot(length(fs) == 4)
d <- rbindlist(lapply(seq_along(fs), function(i) { x <- fread(fs[i], sep = ";", encoding = "UTF-8"); setnames(x, sub("^﻿", "", names(x))); x[, period := i] }))
SPC <- c(CC = "CAPCAP", CE = "CEREL", RR = "RUPRUP", SS = "SUSSCR", CI = "CAPIBE")
stopifnot(identical(names(d)[1:18], c("DATE", "QUAD", "TRANS", "TR_ID", "CC", "CE", "RR", "SS", "CI", "SNOW_H", "SNOW_C", "SNOW_FO", "SNOW_OP", "RUN", "STAT", "DSLSF", "NWSN", "S_C_C")),
          nrow(d) == 434 + 436 * 3, !anyDuplicated(d[, .(TR_ID, period, RUN)]), all(d$RUN %in% 1:2), d[, uniqueN(QUAD), by = TR_ID][, all(V1 == 1)],
          all(rowSums(is.na(d[, names(SPC), with = FALSE])) %in% c(0, 5)), sum(is.na(d$CC)) == 50)
s <- d[!is.na(CC)]
s[, date := format(as.IDate(DATE, format = "%d.%m.%Y"))]
long <- melt(s[, c("TR_ID", "QUAD", "period", "RUN", "date", "SNOW_H", "SNOW_C", "SNOW_FO", "SNOW_OP", "STAT", "DSLSF", "NWSN", "S_C_C", names(SPC)), with = FALSE],
             measure.vars = names(SPC), variable.name = "sp", value.name = "y", variable.factor = FALSE)
long <- order_eco(long[, .(unit = as.character(TR_ID), taxon = SPC[sp], y = as.integer(y), period, occasion = as.integer(RUN), date, cluster_id = as.character(QUAD),
                           obs_snow_height = SNOW_H, obs_snow_quality = SNOW_C, obs_snow_cover_forest = SNOW_FO, obs_snow_cover_open = SNOW_OP,
                           obs_weather_station = STAT, obs_days_since_snowfall = DSLSF, obs_fresh_snow = NWSN, obs_snow_class = S_C_C)])
stopifnot(nrow(long) == (nrow(d) - 50) * 5, all(long$y >= 0))
periods <- data.table(period = 1:4, period_winter = c("2012-13", "2013-14", "2014-15", "2015-16"))
taxa <- make_taxa(unname(SPC), c("Capreolus capreolus", "Cervus elaphus", "Rupicapra rupicapra", "Sus scrofa", "Capra ibex"),
                  vernacularName = c("Roe deer", "Red deer", "Chamois", "Wild boar", "Alpine ibex"))
dataset <- list(
  title = "Snow-track counts of five ungulates on two visits per winter to 218 transects in the Western Swiss Alps, winters 2012-13 to 2015-16",
  creator = "Roder, Stefanie; Biollaz, François; Mettaz, Stéphane; Zimmermann, Fridolin; Manz, Ralph; Kéry, Marc; Vignali, Sergio; Fumagalli, Luca; Arlettaz, Raphaël; Braunisch, Veronika",
  pubDate = "2020", doi = "10.5061/dryad.2v6wwpzhx", sourceURL = "https://doi.org/10.5061/dryad.2v6wwpzhx",
  citation = "Roder, S. et al. (2020). Data from: Deer density drives habitat use of establishing wolves in the Western European Alps [Dataset]. Dryad. https://doi.org/10.5061/dryad.2v6wwpzhx",
  paperDOI = "10.1111/1365-2664.13609",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Minimum numbers of roe deer, red deer, chamois, wild boar and Alpine ibex estimated from snow tracks on two visits per winter to 218 1-km transects in 34 10 x 10 km squares of the Western Swiss Alps, four winters 2012-13 to 2015-16, with snow height, quality and cover, fresh snow and days since snowfall per visit.",
  samplingProtocol = "Snow-tracking along fixed 1-km transects, each walked twice per winter (December-March) by the same trained observer; minimum number of individuals per species from imprint size and track distribution (conservative).",
  samplingProtocolCode = "track_survey", surveyEvidence = "deposited_matrix", responseType = "count",
  unitKind = "site", closure = "closed", closureNote = "closed within a winter (two visits), open between the four winters", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Western Swiss Alps (canton of Valais and surroundings), Switzerland; no coordinates deposited",
  temporalCoverage = "2013-01/2016-03",
  notShipped = list(buffer_data = "habitat covariates per transect buffer: several columns are mis-parsed in the deposit (values such as 'Apr 35')", mouflon = "named in the methods but no column in the deposit"),
  notes = "y is the observer's minimum number of individuals from tracks. obs_ snow covariates are as deposited (snow height in cm, cover in percent; codes per the paper). 50 transect-visits not walked have no rows.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/roder_2020_valais_ungulates_count.R")
stage_dict_row(TABLE, description = "Snow-track minimum counts of five ungulates on two visits per winter to 218 transects in the Western Swiss Alps, 2012-13 to 2015-16.",
  url = "https://doi.org/10.5061/dryad.2v6wwpzhx", reference = "Roder, S. et al. (2020). Deer density drives habitat use of establishing wolves in the Western European Alps. Journal of Applied Ecology, 57(5).",
  doi_paper = "10.1111/1365-2664.13609", doi_data = "10.5061/dryad.2v6wwpzhx", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic community N-mixture from snow tracks.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community N-mixture (multi-season)",
  sampling_protocol = "track_survey", design = "Multi-season (4 winters x 2 visits)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "Wolf prey ungulates.")
