#!/usr/bin/env Rscript
# Table:  jenkins_2019_olympic_fisher_occ
# Source: USGS ScienceBase doi:10.5066/P9Q8SITV (USGS data release, published 2019-11-22, metadata
#         revised 2020-08-19). Licence as shown: "Public domain data from the U.S. Government are
#         freely redistributable with proper metadata and source attribution. The U.S. Geological
#         Survey and the National Park Service request to be contacted prior to the use of these
#         data as well as acknowledged as originator of these data in future products or derivative
#         research." US public domain, recorded as CC0 1.0. The contact-prior-to-use request was
#         held under the 2026-11-06 intake ruling and is satisfied: Ben Domingue wrote to Kurt
#         Jenkins and fresc_outreach@usgs.gov on 2026-11-06, and USGS FRESC replied the same day:
#         "Since these data are in the public domain you are free to modify them to your needs.
#         Citing the data release and including the link ... would be appreciated." The citation
#         and DOI link below carry that attribution (USGS and NPS Olympic National Park as originators).
#   Jenkins, K.J., 2019, Fisher (Pekania pennanti) detections and analysis covariates from
#   Washington's Olympic Peninsula, 2013-2016: U.S. Geological Survey data release,
#   https://doi.org/10.5066/P9Q8SITV.
# Paper:  Happe, P.J., Jenkins, K.J., McCaffery, R.M., Lewis, J.C., Pilgrim, K.L., and Schwartz, M.K.,
#         2020, Occupancy patterns in a reintroduced fisher population during reestablishment.
#         Journal of Wildlife Management 84(2):344-358, doi:10.1002/jwmg.21788 (online 2019-11-20).
# Data:   "Fisher detections by hexagon with covariates_Olympic Peninsula_2013-2016.xlsx", sheet
#         fisherl13-16: 263 hexagon-years (the paper's "263 24-km2 primary sampling units"), one row
#         per hexagon (Hex) x Year, rep = the hexagon's 1st/2nd/3rd sampling year; V1-V3 fisher
#         detected (0/1) in each of three 14-day intervals, pooled over the hexagon's three
#         camera + hair-snare stations (detections confirmed by photographs and DNA); date_V1-V3
#         Julian date of the station check ending each interval; b_V1-V3 proportion of the interval
#         the bait was functional; landscape covariates in the combined 1,262-m station buffers
#         (fnw, fw, other: % federal non-wilderness / wilderness / other ownership; small, med,
#         large tree %; sccdiv Simpson diversity of stand classes; opencc, modcc, m_closedcc canopy
#         closure %), precip (PRISM 30-yr normal, mean of the 3 stations, mm), dist_fw (mean station
#         distance to the wilderness boundary, m), mean_elev (m). The landscape covariates differ
#         slightly between a hexagon's years (stations were re-placed), so they are period_ columns.
#         V2, V3, date_V2-3 and b_V2-3 are the text "NA" in one row (hexagon 630, 2013: no second or
#         third visit, per the metadata's "NA: Not Applicable. There was no second visit").
#         Hexes_primary.zip: shapefile of the 143 primary-area hexagons (NAD83 UTM 10N), with
#         X_Coord / Y_Coord (hexagon centre), place name, landowners, sampling year flags
#         (<year>Sample "<year>_O"; one "2016_i") and the lead crew per year (<year>_Lead), plus an
#         all-zero Occupancy field and field notes. Hexes_expansion.zip: the 36 expansion-area
#         hexagons, sampled 2014-2016, which have no rows in the detection spreadsheet. Fisher
#         detections metadata.xml: FGDC metadata (design, attribute definitions).
# Mapping: unit = hexagon ("H<Hex>"); period = year (2013-2016 -> 1-4; a hexagon is sampled in 1-3
#   years, the design aiming at two years two years apart); occasion = 14-day interval (1-3);
#   taxon = PEPE (Pekania pennanti); y = V<k> (0/1). surveyEvidence = deposited_matrix: a
#   hexagon-year row is a sampled hexagon-year and a non-NA V<k> is a conducted interval (NA =
#   "there was no visit"); single taxon, and the NA pattern is identical across V, date and bait
#   columns (asserted). date = Year + Julian date of the check ending the interval (day of year,
#   1 January = 1), with obs_date_doy as deposited; obs_bait_functional = b_V<k>. period_ covariates:
#   ownership, tree size, canopy, diversity, precipitation, wilderness distance, elevation (as
#   deposited, percentages and raw units) and period_lead (crew lead organisation that year, from
#   the shapefile). unit_x / unit_y = hexagon centre from the shapefile, EPSG:26910, as published;
#   empty for hexagons 199 and 564, which are in the spreadsheet but not in the primary shapefile.
#   unit_name = the shapefile's place name.
# Coordinates: Pekania pennanti is IUCN Least Concern; the data release does not call the taxon or
#   its locations sensitive, and cites no national red list (the species is state-endangered in
#   Washington, which is not one of E7's flags), so it is not flagged and the hexagon centres ship
#   as the source published them (24-km2 hexagons, centres ~4.6 km apart from their edges).
# Not shipped: the expansion-area hexagons (no detection data deposited), the shapefile's all-zero
#   Occupancy field, the hexagon polygons themselves, the 2016 "2016_i" record of hexagon 309
#   (not in the detection spreadsheet), landowner codes, field notes and selection flags.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "jenkins_2019_olympic_fisher_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5cc7803ae4b09b8c0b77e9a2?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
XLSX <- "Fisher detections by hexagon with covariates_Olympic Peninsula_2013-2016.xlsx"
stopifnot(setequal(names(fl), c(XLSX, "Fisher detections metadata.xml", "Hexes_primary.zip", "Hexes_expansion.zip")))
meta <- paste(readLines(download_cached(fl[["Fisher detections metadata.xml"]], TABLE, filename = "Fisher detections metadata.xml"), warn = FALSE), collapse = " ")
stopifnot(grepl("Public domain data from the U.S. Government are freely redistributable", meta, fixed = TRUE),
          grepl("request to be contacted prior to the use of these data", meta, fixed = TRUE))

x <- as.data.table(read_excel(download_cached(fl[[XLSX]], TABLE, filename = XLSX), sheet = "fisherl13-16"))
setnames(x, gsub(" ", "_", names(x)))
stopifnot(nrow(x) == 263, uniqueN(x$Hex) == 144, !anyDuplicated(x[, .(Hex, Year)]), all(x$Year %in% 2013:2016),
          identical(as.integer(table(x$Year)), c(52L, 68L, 75L, 68L)),
          identical(x$Rep_ID_Text, sprintf("%03d-r%d-(%d)", as.integer(x$Hex), as.integer(x$rep), as.integer(x$Year))),
          x[order(Year), all(rep == seq_len(.N)), by = Hex]$V1)
vk <- c("V", "date_V", "b_V")
for (k in 1:3) for (v in paste0(vk, k)) x[, (v) := suppressWarnings(as.numeric(ifelse(get(v) == "NA", NA, get(v))))]
# NA pattern: identical across detection, date and bait; only hexagon 630 in 2013 lacks visits 2 and 3
na <- x[, lapply(1:3, function(k) is.na(get(paste0("V", k))))]
for (k in 1:3) stopifnot(identical(is.na(x[[paste0("date_V", k)]]), na[[k]]), identical(is.na(x[[paste0("b_V", k)]]), na[[k]]))
stopifnot(!any(na[[1]]), sum(na[[2]]) == 1, identical(na[[2]], na[[3]]), x[na[[2]], Hex == 630 & Year == 2013])
stopifnot(all(unlist(x[, .(V1, V2, V3)]) %in% c(0, 1, NA)),
          all(x[!na[[2]], date_V1 < date_V2 & date_V2 < date_V3]),
          all(unlist(x[, .(b_V1, b_V2, b_V3)]) > 0 & unlist(x[, .(b_V1, b_V2, b_V3)]) <= 1, na.rm = TRUE),
          !anyNA(x[, .(fnw, fw, other, small_tree, med_tree, large_tree, sccdiv, opencc, modcc, m_closedcc, precip, dist_fw, mean_elev)]),
          all(abs(x$fnw + x$fw + x$other - 100) < 0.5))

# hexagon centres from the primary shapefile's attribute table
td <- file.path(tempdir(), TABLE); dir.create(td, showWarnings = FALSE)
unzip(download_cached(fl[["Hexes_primary.zip"]], TABLE, filename = "Hexes_primary.zip"), exdir = td)
unzip(download_cached(fl[["Hexes_expansion.zip"]], TABLE, filename = "Hexes_expansion.zip"), exdir = td)
hp <- as.data.table(suppressMessages(suppressWarnings(foreign::read.dbf(file.path(td, "Hexes_primary", "Hexes_primary.dbf"), as.is = TRUE))))
he <- as.data.table(suppressMessages(suppressWarnings(foreign::read.dbf(file.path(td, "Hexes_expansion", "Hexes_expansion.dbf"), as.is = TRUE))))
stopifnot(grepl("NAD_1983_UTM_Zone_10N", readLines(file.path(td, "Hexes_primary", "Hexes_primary.prj"), warn = FALSE)),
          nrow(hp) == 143, nrow(he) == 36, !anyDuplicated(hp$Hex_ID), all(hp$Occupancy == 0), all(he$Occupancy == 0),
          !any(x$Hex %in% he$Hex_ID), setequal(setdiff(x$Hex, hp$Hex_ID), c(199, 564)),
          sum(!hp$Hex_ID %in% x$Hex) == 1)
# the shapefile's sampling flags agree with the spreadsheet's hexagon-years, except 309 in 2016 ("2016_i")
sf <- rbindlist(lapply(2013:2016, function(yr) hp[!is.na(get(paste0("X", yr, "Sample"))),
       .(Hex = Hex_ID, Year = yr, flag = get(paste0("X", yr, "Sample")), lead = get(paste0("X", yr, "_Lead")))]))
stopifnot(identical(sf[flag != paste0(Year, "_O"), paste(Hex, Year, flag)], "309 2016 2016_i"),
          setequal(sf[flag == paste0(Year, "_O"), paste(Hex, Year)], x[Hex %in% hp$Hex_ID, paste(Hex, Year)]))
x <- merge(x, sf[flag == paste0(Year, "_O"), .(Hex, Year, lead)], by = c("Hex", "Year"), all.x = TRUE)
x <- merge(x, hp[, .(Hex = Hex_ID, unit_x = X_Coord, unit_y = Y_Coord, unit_name = Name)], by = "Hex", all.x = TRUE)
stopifnot(nrow(x) == 263, sum(is.na(x$unit_x)) == 3, identical(is.na(x$lead), is.na(x$unit_x)))

long <- rbindlist(lapply(1:3, function(k) x[!is.na(get(paste0("V", k))), .(
  unit = sprintf("H%03d", as.integer(Hex)), taxon = "PEPE", y = as.integer(get(paste0("V", k))),
  period = as.integer(Year) - 2012L, occasion = k,
  date = format(as.IDate(sprintf("%d-01-01", as.integer(Year))) + as.integer(get(paste0("date_V", k))) - 1L),
  obs_date_doy = as.integer(get(paste0("date_V", k))), obs_bait_functional = get(paste0("b_V", k)),
  unit_x, unit_y, unit_name,
  period_rep = as.integer(rep), period_lead = lead,
  period_pct_fed_nonwilderness = fnw, period_pct_fed_wilderness = fw, period_pct_other_ownership = other,
  period_pct_small_tree = small_tree, period_pct_medium_tree = med_tree, period_pct_large_tree = large_tree,
  period_stand_class_simpson = sccdiv, period_pct_open_canopy = opencc, period_pct_moderate_canopy = modcc,
  period_pct_dense_canopy = m_closedcc, period_precip_mm = precip, period_dist_wilderness_m = dist_fw,
  period_elev_m = mean_elev)]))
setorder(long, unit, period, occasion)
stopifnot(nrow(long) == 263 * 3 - 2, uniqueN(long$unit) == 144, uniqueN(long[, .(unit, period)]) == 263,
          sum(long$y) == 56, uniqueN(long[y == 1, .(unit, period)]) == 30)

taxa <- make_taxa("PEPE", "Pekania pennanti", vernacularName = "Fisher")
periods <- data.table(period = 1:4, label = as.character(2013:2016), year = 2013:2016)
dataset <- list(
  title = "Fisher detections in three 14-day intervals at 144 hexagons on the Olympic Peninsula, Washington, 2013-2016",
  creator = "Jenkins, Kurt J.",
  pubDate = "2019", doi = "10.5066/P9Q8SITV", sourceURL = "https://doi.org/10.5066/P9Q8SITV",
  citation = "Jenkins, K.J., 2019, Fisher (Pekania pennanti) detections and analysis covariates from Washington's Olympic Peninsula, 2013-2016: U.S. Geological Survey data release, https://doi.org/10.5066/P9Q8SITV.",
  paperDOI = "10.1002/jwmg.21788",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
    note = "USGS data release, US public domain; USGS and NPS ask to be acknowledged as originators. Their request to be contacted before use was met on 2026-11-06 (USGS FRESC: free to modify; citing the data release with its link appreciated)."),
  abstract = "Ninety fishers were translocated from British Columbia to Olympic National Park in 2008-2010. From 2013 to 2016, three baited camera and hair-snare stations were run for six weeks in each sampled 24-km2 hexagon of a systematic grid over the primary study area, checked every 14 days, to measure occupancy of the reestablishing population and its habitat associations. Each hexagon was sampled in one to three years.",
  samplingProtocol = "Three stations per 24-km2 hexagon, each a motion-sensing camera paired with a hair-snaring box, baited with chicken and lure, checked at three 14-day intervals; a fisher detection in an interval is a fisher photographed or genotyped from hair at any of the hexagon's stations.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "six weeks within a year at a hexagon; period = calendar year, each hexagon sampled in 1-3 of the 4 years",
  occasionKind = "time", taxonInclusion = "single", crs = "EPSG:26910",
  geographicCoverage = list(description = "Primary study area of the Olympic Peninsula, Washington, USA (Olympic National Park, Olympic National Forest and surrounding state, tribal and private land)",
                            boundingBox = list(west = -124.7607, east = -122.5854, south = 47.0701, north = 48.4292)),
  temporalCoverage = "2013-05/2016-11",
  coordinatesCoarsened = list(value = FALSE, method = "Hexagon centres (NAD83 UTM 10N) as published in the source shapefile; Pekania pennanti is IUCN Least Concern and the source flags no sensitivity, so not coarsened (state-endangered in Washington, not an E7 flag). Hexagons 199 and 564 have no centre in the source."),
  notShipped = list(expansion_hexagons = "Hexes_expansion.zip: 36 expansion-area hexagons sampled 2014-2016; no detection data deposited for them",
                    occupancy_field = "the shapefiles' Occupancy field (all 0; not a measurement)",
                    incidental_2016 = "hexagon 309 flagged '2016_i' in the shapefile; no detection row in the spreadsheet",
                    shapefile_attributes = "hexagon polygons, landowner codes, selection flags and field notes"),
  notes = "y pools the three stations of a hexagon (no station-level detections deposited). Landscape covariates are measured in the combined 1,262-m station buffers each year and vary slightly between a hexagon's years, so they are period_ columns. The data release's acknowledgement request: cite the release and acknowledge USGS and the National Park Service (Olympic National Park) as originators.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/jenkins_2019_olympic_fisher_occ.R")
stage_dict_row(TABLE,
  description = "Fisher detection / non-detection in three 14-day intervals at camera and hair-snare stations in 144 24-km2 hexagons of the Olympic Peninsula, Washington, 2013-2016 (263 hexagon-years), after the 2008-2010 reintroduction, with bait and landscape covariates.",
  url = "https://doi.org/10.5066/P9Q8SITV",
  reference = "Happe, P.J., Jenkins, K.J., McCaffery, R.M., Lewis, J.C., Pilgrim, K.L., & Schwartz, M.K. (2020). Occupancy patterns in a reintroduced fisher population during reestablishment. Journal of Wildlife Management 84(2):344-358.",
  doi_paper = "10.1002/jwmg.21788", doi_data = "10.5066/P9Q8SITV",
  original_license = "US public domain (USGS data release); USGS and NPS request contact prior to use and acknowledgement as originators",
  derived_license = "CC0 1.0",
  notes = "Contact-prior-to-use request satisfied: Ben Domingue emailed Kurt Jenkins and fresc_outreach@usgs.gov 2026-11-06; USGS FRESC replied 2026-11-06 that the data are public domain and free to modify, citing the release with its link appreciated. Expansion-area hexagons not in the detection spreadsheet.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (annual, hexagons revisited across years)", sampling_protocol = "camera_trap",
  design = "Multi-season (1-3 years per hexagon x 3 14-day intervals)", realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Reintroduced population (2008-2010 translocation); camera plus hair-snare stations, three per hexagon, pooled.")
