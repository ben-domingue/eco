#!/usr/bin/env Rscript
# Tables: roberts_2025_arkansas_birds_count (every taxon, coordinates coarsened) and
#         roberts_2025_arkansas_birds_exact_count (without chimney swift, coordinates as published)
# Source: USGS ScienceBase, doi:10.5066/P1IL2ZRC (item 67bcd8bcd34e1a2e835b99bd), 2025-03-06. Roberts, C. P., Berry,
#         L. L. and DeGregorio, B. A. (2025). Spatial covariance tracks grassland bird community occupancy in
#         fragmented grasslands. U.S. Geological Survey data release. Licence: USGS data release marked CC0 1.0
#         (ScienceBase; the FGDC record states no access or use constraints).
# Paper:  "Finding the (small) cores: spatial covariance tracks grassland bird community occupancy in fragmented
#         grasslands" (named in the FGDC record; not read).
# Data:   SSP_AllBirdData_NewPointNums_NAOMIT.csv: 7,742 rows, one per species (group) recorded at a point-visit: Obs,
#           Date (M/D/YYYY), PtNum, Survey (visit 1-3), StartTime, Wind (Beaufort), Sky (BBS sky code), SpeciesCode
#           (alpha code), Dist_50, Dist_100, Dist_400 (birds at 0-50 m, 51-100 m, 101-400 m), FlyOver.
#         FieldVeg50m_RemoteVeg_JUNMASK_forDataRelease.csv: 416 points: Site (BK Bald Knob NWR, CR Camp Robinson SUA,
#           HO Howell tract and DC Dark Corner tract of Cache River NWR, HB Holla Bend NWR), Roadside (0/1), latitude,
#           longitude (WGS84), spatial covariance at three window sizes (2022 imagery), Robel height, stem densities,
#           DBH and ground-cover percentages within 50 m. GrasslandBirdOccupancy_DataRelease_Metadata.xml (FGDC).
#         FGDC: points 400 m apart on a grid in each site plus roadside points; every point visited three times
#           (2022: 1 June - 30 July; 2023: 15 May - 10 June); counts 30 min before to 5 h after sunrise.
#         Quirks (asserted): each point is surveyed in one year only (285 in 2022, 131 in 2023), and every point has
#           visits 1-3 in the file, so although the file name says NAOMIT no visit is missing; 50 rows repeat
#           another row exactly; point-visits HO95 2022 visits 1 and 2 hold a block of rows entered twice that
#           differ only in StartTime (5:45 / 8:40); after those are dropped 4 species still have two rows in one
#           visit (groups); StartTime varies within 365 point-visits (up to three times), so it is not a property
#           of the visit; 6 count cells are blank (1 Dist_50, 5 FlyOver); codes 'EUST ' and ' FISP' carry spaces;
#           BAOW (barred owl, IBP code BADO) and NHWR (northern house wren, the 2025 split of house wren) are not
#           in the IBP 2021 list; two point-visits have one row with another date (DC67 2022 visit 1; HO55 2022
#           visit 3, also another observer): the visit takes the date and observer of most of its rows.
# Mapping (repeated counts, community; responseType count): unit = point (PtNum), cluster_id = site code, taxon =
#   alpha code (trimmed), period = year (2022 = 1, 2023 = 2), occasion = visit, date (ISO). Repeated rows within a
#   visit (ruling 2026-11-06): one row per taxon per point-visit, y = the total over the taxon's rows and all four
#   cells (0-50 m, 51-100 m, 101-400 m, flyover), each cell's total in obs_n_d0_50, obs_n_d50_100,
#   obs_n_d100_400, obs_n_flyover, 0 where nothing was recorded; a blank cell counts 0 and is counted in
#   obs_n_blank_cells. Community: every taxon recorded in the release at every point-visit (taxonInclusion recorded).
#   surveyEvidence = row_presence (every point has its three visits in the file, asserted). observer (as recorded,
#   may list several), obs_wind_beaufort, obs_sky_code. unit_roadside; unit_ coordinates.
#   Coordinates (E7): chimney swift (Chaetura pelagica) is IUCN VU (GBIF IUCN record, asserted) and is recorded here,
#   within its native breeding range; so two tables ship (E7 scope, 3): roberts_2025_arkansas_birds_count with every
#   taxon and point coordinates snapped to their 0.1-degree cell centre, and roberts_2025_arkansas_birds_exact_count
#   without chimney swift at the published coordinates. Point and site codes are the source's codes (site
#   abbreviations), kept in both.
# Not shipped: StartTime (varies within a third of the point-visits); the 50 exact repeats and the 6 HO95 rows
#   entered twice (source errors); the vegetation and spatial-covariance covariates (measured once per point, the
#   spatial covariance from imagery; not a survey record and partly model-derived).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roberts_2025_arkansas_birds_count"
EXACT <- "roberts_2025_arkansas_birds_exact_count"
SB <- "https://www.sciencebase.gov/catalog/file/get/67bcd8bcd34e1a2e835b99bd?f=%s"
fb <- download_cached(sprintf(SB, "__disk__e7%2Feb%2Feb%2Fe7ebebfd10597d177f6d8ad03ce0d7d236140446"), TABLE, filename = "SSP_AllBirdData_NewPointNums_NAOMIT.csv")
fv <- download_cached(sprintf(SB, "__disk__9c%2F0b%2F25%2F9c0b25e9a2fb60b4b3514c07832f163d15df02be"), TABLE, filename = "FieldVeg50m_RemoteVeg_JUNMASK_forDataRelease.csv")
fx <- download_cached(sprintf(SB, "__disk__00%2Fd8%2Fef%2F00d8ef8a77f304d3ef838cad3deb2b0c84393425"), TABLE, filename = "GrasslandBirdOccupancy_DataRelease_Metadata.xml")
xml <- paste(readLines(fx, warn = FALSE), collapse = " ")
stopifnot(grepl("https://doi.org/10.5066/P1IL2ZRC", xml, fixed = TRUE), grepl("Each point was sampled three times", xml, fixed = TRUE))
d <- fread(fb, encoding = "UTF-8", na.strings = "", colClasses = list(character = c("Obs", "Date", "PtNum", "StartTime", "SpeciesCode")))
setnames(d, 1L, sub("^﻿", "", names(d)[1L]))
v <- fread(fv, encoding = "UTF-8")
setnames(v, 1L, sub("^﻿", "", names(v)[1L]))
cells <- c("Dist_50", "Dist_100", "Dist_400", "FlyOver")
stopifnot(identical(names(d), c("Obs", "Date", "PtNum", "Survey", "StartTime", "Wind", "Sky", "SpeciesCode", cells)),
          nrow(d) == 7742L, nrow(v) == 416L, !anyDuplicated(v$PtNum), setequal(d$PtNum, v$PtNum),
          sum(is.na(d$Dist_50)) == 1L, sum(is.na(d$FlyOver)) == 5L, !anyNA(d[, .(Dist_100, Dist_400, Wind, Sky)]),
          all(d$Survey %in% 1:3))
d[, date := as.IDate(Date, format = "%m/%d/%Y")]
d[, year := year(date)]
stopifnot(!anyNA(d$date), setequal(d$year, 2022:2023))
# source errors: exact repeats, and the HO95 2022 block entered twice with another StartTime
n_exact <- sum(duplicated(d)); stopifnot(n_exact == 50L)
d <- unique(d)
k <- setdiff(names(d), "StartTime")
nd <- d[duplicated(d, by = k)]
stopifnot(nrow(nd) == 6L, all(nd$PtNum == "HO95"), all(nd$year == 2022L), setequal(nd$Survey, 1:2))
d <- d[!duplicated(d, by = k)]
d[, code := toupper(trimws(SpeciesCode))]
stopifnot(!any(grepl(" ", d$code)), all(nchar(d$code) == 4L))   # fread strips the spaces of "EUST " and " FISP"
# the visit: one date, observer, wind and sky per point-visit; StartTime is not (not shipped)
# two point-visits have a minority row with another date (DC67 2022 visit 1: one row dated 8 June, five 7 June;
# HO55 2022 visit 3: one row dated 20 June by KAS, nine 6 July by LLB): the rows stay in the visit as the source
# numbers them, and the visit takes the date and observer of most of its rows
mix <- d[, .(n = uniqueN(paste(date, Obs, Wind, Sky))), by = .(PtNum, year, Survey)][n > 1L]
stopifnot(nrow(mix) == 2L, setequal(mix$PtNum, c("DC67", "HO55")))
maj <- d[, .N, by = .(PtNum, year, Survey, date, Obs, Wind, Sky)][order(-N)][!duplicated(data.table(PtNum, year, Survey))]
vis <- maj[, .(PtNum, year, Survey, date, Obs, Wind, Sky)]
stopifnot(!anyDuplicated(vis[, .(PtNum, year, Survey)]), vis[, uniqueN(year), by = PtNum][, all(V1 == 1L)],
          vis[, .N, by = .(PtNum, year)][, all(N == 3L)], nrow(vis) == 3L * 416L)
nst <- d[, uniqueN(StartTime), by = .(PtNum, year, Survey)][V1 > 1L, .N]
cat(sprintf("  point-visits whose rows give more than one StartTime: %d of %d\n", nst, nrow(vis)))
stopifnot(nst == 365L)   # after the HO95 double entry is dropped
# repeated rows within a visit (ruling 2026-11-06): cells summed; blank cells count 0 and are counted
d[, blanks := as.integer(is.na(Dist_50)) + as.integer(is.na(FlyOver))]
for (c in cells) set(d, which(is.na(d[[c]])), c, 0)
stopifnot(all(unlist(d[, ..cells]) >= 0), all(unlist(d[, ..cells]) == round(unlist(d[, ..cells]))))
agg <- d[, .(obs_n_d0_50 = as.integer(sum(Dist_50)), obs_n_d50_100 = as.integer(sum(Dist_100)), obs_n_d100_400 = as.integer(sum(Dist_400)),
             obs_n_flyover = as.integer(sum(FlyOver)), obs_n_blank_cells = sum(blanks), nrow = .N), by = .(PtNum, year, Survey, taxon = code)]
cat(sprintf("  %d species rows -> %d point-visit x taxon records (%d groups summed)\n", nrow(d), nrow(agg), sum(agg$nrow > 1L)))
stopifnot(sum(agg$nrow > 1L) == 4L)
agg[, nrow := NULL]
tx <- sort(unique(d$code))
grid <- CJ(k = seq_len(nrow(vis)), taxon = tx)
grid[, `:=`(PtNum = vis$PtNum[k], year = vis$year[k], Survey = vis$Survey[k])]
long <- merge(grid, agg, by = c("PtNum", "year", "Survey", "taxon"), all.x = TRUE)
cc <- c("obs_n_d0_50", "obs_n_d50_100", "obs_n_d100_400", "obs_n_flyover", "obs_n_blank_cells")
for (c in cc) set(long, which(is.na(long[[c]])), c, 0L)
long[, y := obs_n_d0_50 + obs_n_d50_100 + obs_n_d100_400 + obs_n_flyover]
long <- merge(long, vis, by = c("PtNum", "year", "Survey"))
long <- merge(long, v[, .(PtNum, Site, Roadside, latitude, longitude)], by = "PtNum")
yrs <- 2022:2023
long <- long[, .(unit = PtNum, taxon = taxon, y = y, period = match(year, yrs), occasion = Survey, date = format(date),
                 cluster_id = Site, observer = Obs, unit_roadside = Roadside, unit_decimalLatitude = latitude,
                 unit_decimalLongitude = longitude, obs_wind_beaufort = Wind, obs_sky_code = Sky,
                 obs_n_d0_50, obs_n_d50_100, obs_n_d100_400, obs_n_flyover, obs_n_blank_cells)]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(vis) * length(tx), sum(long$y) == sum(as.matrix(d[, ..cells])), sum(long$obs_n_blank_cells) == 6L)
cat(sprintf("  %s rows = %d point-visits x %d taxa; %d birds\n", format(nrow(long), big.mark = ","), nrow(vis), length(tx), sum(long$y)))

ibp <- fread(download_cached("https://raw.githubusercontent.com/trashbirdecology/bbsAssistant/main/data-raw/IBP-AOS-LIST21.csv", TABLE, filename = "IBP-AOS-LIST21.csv"), fill = TRUE)
ibp <- ibp[is.na(SP) | SP == ""]
extra <- data.table(SPEC = c("BAOW", "NHWR"), SCINAME = c("Strix varia", "Troglodytes aedon"), COMMONNAME = c("Barred Owl", "Northern House Wren"),
                    remark = c("source code BAOW; IBP code BADO (Barred Owl)", "source code NHWR, Northern House Wren (AOS 2025 split of House Wren; not in the IBP 2021 list)"))
i <- match(tx, ibp$SPEC)
stopifnot(identical(tx[is.na(i)], extra$SPEC))
sci <- ifelse(is.na(i), extra$SCINAME[match(tx, extra$SPEC)], ibp$SCINAME[i])
vern <- ifelse(is.na(i), extra$COMMONNAME[match(tx, extra$SPEC)], ibp$COMMONNAME[i])
taxa <- make_taxa(tx, sci, vernacularName = vern, taxonRemarks = extra$remark[match(tx, extra$SPEC)])
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[taxon_iucnCategory %in% c("CR", "EN", "VU", "NT"), .(taxon, scientificName, taxon_iucnCategory)])
fl <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(identical(fl, "CHSW"))
periods <- data.table(period = 1:2, year = yrs, n_points = vis[, uniqueN(PtNum), keyby = year]$V1,
                      season = c("1 June - 30 July", "15 May - 10 June"))

cg <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude, 0.1)
long_c <- copy(long)[, `:=`(unit_decimalLatitude = cg$lat, unit_decimalLongitude = cg$lon, unit_coordinateUncertaintyInMeters = cg$uncertainty_m)]
long_c <- order_eco(long_c)
emit <- function(name, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long_c
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  stopifnot(nrow(lt) == nrow(vis) * nrow(tt))
  dataset <- list(
    title = paste0(sprintf("Point counts of birds at %d points on five refuge and military grassland sites in Arkansas, 2022-2023, with distance bands", uniqueN(long$unit)),
                   if (exact) " (without chimney swift; coordinates as published)" else ""),
    creator = "Roberts, Caleb P.; Berry, Lauren L.; DeGregorio, Brett A.", pubDate = "2025", doi = "10.5066/P1IL2ZRC",
    sourceURL = "https://doi.org/10.5066/P1IL2ZRC",
    citation = "Roberts, C.P., Berry, L.L., and DeGregorio, B.A., 2025, Spatial covariance tracks grassland bird community occupancy in fragmented grasslands: U.S. Geological Survey data release, https://doi.org/10.5066/P1IL2ZRC.",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
    abstract = "Point counts of all birds at 416 points (400 m grids plus roadside points) in remnant grasslands of Holla Bend, Cache River (Howell and Dark Corner tracts) and Bald Knob National Wildlife Refuges and Camp Robinson Special Use Area, Arkansas; each point counted three times in one year (2022 or 2023), birds recorded by distance band (0-50 m, 51-100 m, 101-400 m) or as flyovers. The authors modelled the occupancy of six declining grassland species against spatial covariance of tree and grass cover.",
    samplingProtocol = "Point count at a station (points 400 m apart on a grid, plus roadside points around each site), all birds counted by distance band (0-50, 51-100, 101-400 m) or as flyovers; three visits per point in one season, from 30 minutes before to 5 hours after sunrise on days with wind under 19.3 km/h and no rain; wind (Beaufort) and sky (BBS code) recorded.",
    samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
    responseType = "count", unitKind = "site", closure = "closed",
    closureNote = "occasion = visit (three in one season per point); period = year (each point is surveyed in one year only)",
    occasionKind = "time", taxonInclusion = "recorded",
    geographicCoverage = "Holla Bend, Cache River (Howell and Dark Corner tracts) and Bald Knob National Wildlife Refuges and Camp Robinson Special Use Area, north-central Arkansas, USA",
    temporalCoverage = sprintf("%s/%s", min(long$date), max(long$date)), crs = "EPSG:4326",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "Point coordinates as published (latitude/longitude in the vegetation file). Chimney swift (IUCN VU) is not in this table (E7 scope, 3); roberts_2025_arkansas_birds_count has it, with coordinates coarsened.") else
      list(value = TRUE, method = "coarsen_coords(): point coordinates snapped to their 0.1-degree cell centre, uncertainty the cell half-diagonal, because chimney swift (Chaetura pelagica, IUCN VU, GBIF IUCN record) is recorded within its native range (E7). roberts_2025_arkansas_birds_exact_count keeps every other taxon at the published coordinates."),
    covariateNote = "obs_n_d0_50, obs_n_d50_100, obs_n_d100_400, obs_n_flyover: birds of the taxon at the visit in each distance band or flying over; y is their sum. obs_n_blank_cells: count cells left blank in the source for the taxon at the visit (counted as 0). obs_wind_beaufort, obs_sky_code (BBS sky codes as recorded). unit_roadside: 1 for a roadside point. cluster_id: site code (BK, CR, DC, HB, HO).",
    distanceBreaks = list(units = "m", breaks = c(0, 50, 100, 400), note = "flyovers are recorded separately"),
    notes = "Repeated rows within a visit (ruling 2026-11-06): a species recorded on several rows of a point-visit has one row, y the total over its rows and the four cells; each cell's total is an obs_n_ column. The file name says empty visits were omitted (NAOMIT), but every point has its three visits in the file. BAOW and NHWR are the source's codes for barred owl and northern house wren. Two point-visits have one row with another date (DC67 2022 visit 1; HO55 2022 visit 3, another observer too); the rows stay in the visit the source gives, and the visit's date and observer are those of most of its rows.",
    notShipped = c(if (exact) list(CHSW = "chimney swift (IUCN VU): in roberts_2025_arkansas_birds_count only, with coarsened coordinates (E7 scope, 3)"),
                   list(StartTime = sprintf("start time varies within %d of %d point-visits, so it is not a property of the visit", nst, nrow(vis)),
                        duplicates = sprintf("%d rows repeating another row exactly, and 6 rows of HO95 (2022 visits 1 and 2) entered twice with a different StartTime: source errors", n_exact),
                        vegetation = "FieldVeg50m_RemoteVeg_JUNMASK_forDataRelease.csv covariates (spatial covariance from imagery, Robel height, stem densities, ground cover); only Site, Roadside and coordinates are used")))
  ds <- write_table(lt, name, dataset, taxa = tt, periods = periods, script = "data/roberts_2025_arkansas_birds_count.R")
  stage_dict_row(name,
    description = paste0("Bird point counts at 416 points in grassland on five Arkansas refuges and military land, three visits per point in 2022 or 2023, with counts by distance band",
                         if (exact) "; without chimney swift, coordinates as published." else "; coordinates coarsened to 0.1 degree."),
    url = "https://doi.org/10.5066/P1IL2ZRC", reference = "", doi_paper = "", doi_data = "10.5066/P1IL2ZRC",
    original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
    notes = "Repeated species rows within a visit summed (ruling 2026-11-06), distance cells as obs_ columns; exact repeats dropped.",
    source_via = "USGS ScienceBase")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "Community abundance (repeated counts; distance cells)",
    sampling_protocol = "point_count", design = "Single-season per point (3 visits; points split across 2022 and 2023)", realm = "Terrestrial",
    country = "USA", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = if (exact) "E7 sibling without chimney swift (VU)." else "Coordinates coarsened (chimney swift VU).")
}
emit(TABLE, exact = FALSE)
emit(EXACT, exact = TRUE)
