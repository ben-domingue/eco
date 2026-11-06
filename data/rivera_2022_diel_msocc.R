#!/usr/bin/env Rscript
# Tables: rivera_2022_chicago_coyote_dielocc, rivera_2022_makira_fosa_dielocc,
#         rivera_2022_rnp_fosa_dielocc
# Source: Dryad doi:10.5061/dryad.bvq83bk9w (CC0 1.0, as shown on the Dryad page; published
#         2022-09-01). Rivera, K., Gerber, B., Fidino, M., Magle, S., Farris, Z. & Murphy, A.
#         Multi-state diel occupancy model.
# Paper:  Rivera, K., Fidino, M., Farris, Z.J., Murphy, A., Magle, S.B. & Gerber, B.D. (2022).
#         Rethinking habitat occupancy modeling and the role of diel activity in an
#         anthropogenic world. The American Naturalist, doi:10.1086/720714.
# Data:   Dryad_final.zip (README.pdf describes every file):
#         Chicago coyote/day_night_detections.csv: 105 sites x 13 seasons (JU16 ... JU19:
#         January, April, July, October 2016-2019), Start (first sampling week), Week_01-08 =
#         1 not detected, 2 day only, 3 night only, 4 day and night, NA = not sampled;
#         chicago_covars.csv (tree, impervious cover, housing density within 1000 m; urb = a
#         score from those three); camera_active.csv, coyote_datetime.csv (daily activity and
#         photo times behind the weekly states; not shipped).
#         Makira Fosa2/<grid>/Diel.Occ.<survey>.csv: fosa detections in the same four states,
#         stations x occasions, for 13 grid-surveys in Makira Natural Park (AJB surveyed six
#         times: AJB, 2AJB .. 6AJB; MGB twice), each with a _Hum.csv of human events and trap
#         nights per station.
#         RNP Fosa/RNP2007.csv: fosa in Ranomafana National Park, 2007: 42 stations x 22
#         occasions in the four states, with distances to town, road and non-forest, and dog and
#         human trap success.
# Mapping (standard: multi-state occupancy, E9 core; three tables, one per study system):
#   y = deposited state - 1 (0 not detected, 1 day only, 2 night only, 3 day and night); y_raw =
#   the deposited code; stateCodes. NA = no row. Survey evidence: deposited_matrix.
#   Chicago: unit = Site, period = season 1..13 (__periods: label, month, year), occasion =
#   week, date = Start + 7 (week - 1) (the week's first day, exact from the deposited start);
#   unit_: tree, impervious, housing density. Makira: unit = station id as deposited (ids carry
#   the survey prefix, so a station resurveyed is a separate unit), cluster_id = grid-survey
#   label, one period, occasion = Occ_k. RNP: unit = Site, occasion = Occ_k, unit_: the three
#   distances.
#   Not shipped: urb (a score computed from the three Chicago covariates), human and dog trap
#   success (indices from the same cameras' detections), the Makira trap-night counts and the
#   daily / photo-time files (the weekly states are built from them). No coordinates are in
#   the deposited tables; fosa is IUCN VU, coyote LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/rivera_2022_diel_msocc.R"
dir <- download_dryad("10.5061/dryad.bvq83bk9w", "rivera_2022_diel_msocc")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^Dryad_final\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "Dryad_final")
SC <- list(`0` = "not detected in the occasion (deposited code 1)", `1` = "detected during the day only (code 2)",
           `2` = "detected at night only (code 3)", `3` = "detected both day and night (code 4)")
rd <- function(f) { d <- fread(f, encoding = "UTF-8"); names(d) <- sub("^﻿", "", names(d)); d }
toLong <- function(d, idcol, occcols) {
  m <- melt(d[, c(idcol, occcols), with = FALSE], id.vars = idcol, variable.name = "v", value.name = "code", variable.factor = FALSE)[!is.na(code)]
  stopifnot(all(m$code %in% 1:4))
  m[, `:=`(occasion = match(v, occcols), y = as.integer(code) - 1L, y_raw = as.character(code))][, v := NULL]
  m
}
base <- list(
  creator = "Rivera, Kimberly; Gerber, Brian; Fidino, Mason; Magle, Seth; Farris, Zach; Murphy, Asia", pubDate = "2022",
  doi = "10.5061/dryad.bvq83bk9w", sourceURL = "https://doi.org/10.5061/dryad.bvq83bk9w",
  citation = "Rivera, K., Gerber, B., Fidino, M., Magle, S., Farris, Z., & Murphy, A. (2022). Multi-state diel occupancy model [Dataset]. Dryad. https://doi.org/10.5061/dryad.bvq83bk9w",
  paperDOI = "10.1086/720714",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "state", stateCodes = SC,
  unitKind = "site", occasionKind = "time", taxonInclusion = "single")
emit <- function(TABLE, long, taxa, extra, periods = NULL) {
  dataset <- c(base, extra)
  ds <- write_table(order_eco(long), TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE, description = dataset$abstract, url = "https://doi.org/10.5061/dryad.bvq83bk9w",
    reference = "Rivera, K., Fidino, M., Farris, Z. J., Murphy, A., Magle, S. B., & Gerber, B. D. (2022). Rethinking habitat occupancy modeling and the role of diel activity in an anthropogenic world. The American Naturalist.",
    doi_paper = "10.1086/720714", doi_data = "10.5061/dryad.bvq83bk9w", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Multi-state diel occupancy (day / night / both); one of three tables from this deposit.", source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state occupancy (diel)",
    sampling_protocol = "camera_trap", design = extra$design_tag, realm = "Terrestrial", country = extra$iso,
    coordinates = "None in source", notes = "States: not detected, day only, night only, both.")
}

# --- Chicago coyote -------------------------------------------------------------------------
cd <- rd(file.path(b, "Chicago coyote", "day_night_detections.csv"))
SEAS <- c("JU16", "OC16", "JA17", "AP17", "JU17", "OC17", "JA18", "AP18", "JU18", "OC18", "JA19", "AP19", "JU19")
wk <- sprintf("Week_%02d", 1:8)
stopifnot(identical(names(cd), c("Site", "Season", "Start", wk)), nrow(cd) == 1365, uniqueN(cd$Site) == 105,
          identical(unique(cd$Season), SEAS), !anyDuplicated(cd[, .(Site, Season)]),
          all(!is.na(cd$Start) | !rowSums(!is.na(as.matrix(cd[, ..wk])))),
          sum(!is.na(cd$Start) & !rowSums(!is.na(as.matrix(cd[, ..wk])))) == 93)   # 93 site-seasons with a start date but no week sampled
cv <- rd(file.path(b, "Chicago coyote", "chicago_covars.csv"))
stopifnot(setequal(cv$LocationName, cd$Site))
lc <- toLong(cd, c("Site", "Season", "Start"), wk)
lc[, `:=`(period = match(Season, SEAS), date = format(as.IDate(Start, format = "%m/%d/%Y") + 7L * (occasion - 1L)))]
lc <- merge(lc, cv[, .(Site = LocationName, unit_tree_1km = tree, unit_impervious_1km = imperv, unit_housing_density_km2 = HU10)], by = "Site")
lc <- lc[, .(unit = Site, taxon = "CANLAT", y, y_raw, period, occasion, date, unit_tree_1km, unit_impervious_1km, unit_housing_density_km2)]
stopifnot(!anyNA(lc$date), nrow(lc) == sum(!is.na(as.matrix(cd[, ..wk]))))
pc <- data.table(period = 1:13, period_label = SEAS, period_month = c(JA = 1L, AP = 4L, JU = 7L, OC = 10L)[substr(SEAS, 1, 2)],
                 period_year = 2000L + as.integer(substr(SEAS, 3, 4)))
emit("rivera_2022_chicago_coyote_dielocc", lc, make_taxa("CANLAT", "Canis latrans", vernacularName = "Coyote"),
  list(title = "Weekly diel detection states of coyotes (not detected, day, night, both) at 105 Chicago camera sites over 13 seasons, 2016-2019",
       abstract = "Weekly multi-state detections of coyotes (not detected, day only, night only, day and night) at 105 Urban Wildlife Information Network camera sites in the Chicago region, sampled in January, April, July and October from July 2016 to July 2019 (13 seasons, up to 8 weeks each), with tree cover, impervious cover and housing density.",
       samplingProtocol = "Camera traps of the Chicago Urban Wildlife Information Network, sampled for up to eight weeks in each of four seasons a year; each week classified by whether coyotes were photographed in the day, at night, both or neither.",
       closure = "closed", closureNote = "closed within a season, open between the 13 seasons (dynamic multi-state diel occupancy)",
       geographicCoverage = "Chicago metropolitan region, Illinois, USA; site coordinates not in the deposited tables", temporalCoverage = "2016-06/2019-08",
       notShipped = list(urb = "an urbanization score computed from the three shipped covariates", daily_files = "camera_active.csv and coyote_datetime.csv, the daily activity and photo times behind the weekly states"),
       notes = "date is the first day of the sampling week (Start + 7 x (week - 1)). The same camera network's earlier coyote, opossum and raccoon days are fidino_2018_chicago_mesocarn_dynocc (2010-2013).",
       design_tag = "Multi-season (13 seasons x 8 weeks)", iso = "USA"), periods = pc)

# --- Makira fosa ------------------------------------------------------------------------------
mf <- list.files(file.path(b, "Makira Fosa2"), "^Diel\\.Occ\\..*\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(mf) == 13)
lm <- rbindlist(lapply(mf, function(f) {
  d <- rd(f); setnames(d, 1, "Station"); oc <- grep("^Occ_", names(d), value = TRUE)
  stopifnot(identical(oc, paste0("Occ_", seq_along(oc))), !anyDuplicated(d$Station))
  l <- toLong(d, "Station", oc); l[, cluster_id := sub("^Diel\\.Occ\\.(.*)\\.csv$", "\\1", basename(f))]; l
}))
stopifnot(!anyDuplicated(lm[, .(Station, occasion)]), uniqueN(lm$cluster_id) == 13)
lm <- lm[, .(unit = Station, taxon = "CRYFER", y, y_raw, occasion, cluster_id)]
emit("rivera_2022_makira_fosa_dielocc", lm, make_taxa("CRYFER", "Cryptoprocta ferox", vernacularName = "Fosa"),
  list(title = sprintf("Diel detection states of fosa at %d camera stations in 13 grid-surveys of Makira Natural Park, Madagascar", uniqueN(lm$unit)),
       abstract = "Multi-state detections of fosa (Cryptoprocta ferox, IUCN VU; not detected, day only, night only, day and night) per sampling occasion at camera stations of 13 grid-surveys in Makira Natural Park, Madagascar (grid AJB surveyed six times, MGB twice); cluster_id names the grid-survey.",
       samplingProtocol = "Camera-trap grids in Makira Natural Park, each survey up to 14 sampling occasions; each occasion classified by whether fosa was photographed in the day, at night, both or neither.",
       closure = "closed", closureNote = "each grid-survey analysed as a static (single-season) multi-state diel occupancy model",
       geographicCoverage = "Makira Natural Park, northeastern Madagascar; no coordinates deposited",
       temporalCoverage = "survey years not stated in the deposit (paper 2022)",
       notShipped = list(human_events = "human events and trap success per station (_Hum.csv), indices from the same cameras", trap_nights = "trap nights per station"),
       notes = "Station ids carry the survey prefix (e.g. 2AJB01 for the second AJB survey), so a resurveyed location is a separate unit; the deposit does not link them. Survey dates and the occasion length are not in the deposit.",
       design_tag = "Single-season (13 grid-surveys, up to 14 occasions)", iso = "MDG"))

# --- Ranomafana fosa ---------------------------------------------------------------------------
r <- rd(file.path(b, "RNP Fosa", "RNP2007.csv"))
oc <- paste0("Occ", 1:22)
stopifnot(nrow(r) == 42, !anyDuplicated(r$Site), all(oc %in% names(r)))
lr <- toLong(r, "Site", oc)
lr <- merge(lr, r[, .(Site, unit_dist_town_m = `Distance to closest Town (GIS) (meters)`, unit_dist_road_m = `Distance to closest Road (GIS) (metes)`,
                      unit_dist_nonforest_m = `Distance Matrix`)], by = "Site")
lr <- lr[, .(unit = Site, taxon = "CRYFER", y, y_raw, occasion, unit_dist_town_m, unit_dist_road_m, unit_dist_nonforest_m)]
emit("rivera_2022_rnp_fosa_dielocc", lr, make_taxa("CRYFER", "Cryptoprocta ferox", vernacularName = "Fosa"),
  list(title = "Diel detection states of fosa at 42 camera stations in Ranomafana National Park, Madagascar, 22 occasions, 2007",
       abstract = "Multi-state detections of fosa (Cryptoprocta ferox, IUCN VU; not detected, day only, night only, day and night) on up to 22 sampling occasions at 42 camera stations in Ranomafana National Park, Madagascar, 2007, with distances to the nearest town, road and non-forest area.",
       samplingProtocol = "Camera-trap stations in Ranomafana National Park, 2007, up to 22 sampling occasions; each occasion classified by whether fosa was photographed in the day, at night, both or neither.",
       closure = "closed", closureNote = "one survey, analysed as a static multi-state diel occupancy model",
       geographicCoverage = "Ranomafana National Park, southeastern Madagascar; no coordinates deposited", temporalCoverage = "2007",
       notShipped = list(Dog = "dog trap success on the same cameras", Human = "human trap success on the same cameras"),
       notes = "Fosa is IUCN VU; no coordinates are deposited.",
       design_tag = "Single-season (42 stations x 22 occasions)", iso = "MDG"))
