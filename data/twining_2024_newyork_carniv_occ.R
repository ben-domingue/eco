#!/usr/bin/env Rscript
# Tables: twining_2024_ny_bobcat_coyote_occ, twining_2024_ny_blackbear_occ
# Source: Dryad doi:10.5061/dryad.ghx3ffbwf (CC0 1.0, as shown on the Dryad page; published
#         2024-03-08). Twining, J.P., Fuller, A.K., Sun, C.C., Calderon-Acevedo, C.A., Schlesinger,
#         M.D., Berger, M., Kramer, D. & Frair, J.L. Integrating presence-only and
#         detection/non-detection data to estimate distributions and expected abundance of
#         difficult-to-monitor species on a landscape-scale.
# Paper:  Twining, J.P. et al. (2024). Journal of Applied Ecology, doi:10.1111/1365-2664.14633.
#         Winter baited camera-trap surveys in southern New York (2013-2015, 2019-2021) and the
#         Northern Zone (2016-2018), one camera per 15-km2 cell, three weekly occasions per
#         site-year; summer camera + hair-snare surveys for black bears (5 two-week occasions,
#         one detection per two weeks; Dryad methods).
# Data:   allNY_2013-2021_bobcatPArecords_ / coyotePArecords_pixelID_10kmgrid.csv (3,879
#         site-years: FID_allNY_10km, sitename, o1-o3 0/1/NA, year, x, y in UTM NAD83; identical
#         keys, asserted); juliandays_allNY_2013-2021.csv (ordinal day of each occasion per
#         site-year, same row order); allNY_2016-2018_bearPAdata_pixelID_10kmgrid_final.csv (674
#         site-years, Station, o1-o5, year, x, y) and NY_blackbears_ordinaldates.csv (ordinal day
#         per occasion); allNY_10kmgrid_alllandscapecovs_final_dryad.csv (14,008 10-km2 cells: X,
#         Y and landscape proportions, road density, elevation, forest edge, and a presence-only
#         density); presence-only bear records; nimble models and scripts.
# Mapping (standard: occupancy, E9 core): two tables (winter two-species; summer black bear).
#   unit = site-year ("<year>_<sitename>"): site names are reused across years at different
#   coordinates and a few coordinates hold two site names in one year, so the stacked site-year is
#   the unit, as the authors fit it (year-indexed random effects); unit_year, unit_utm_x / _y (UTM
#   NAD83 as published; zone not stated), unit_grid10km and the cell's landscape covariates joined
#   on FID_allNY_10km = plot_id (asserted: every camera lies within 2.3 km of its cell's
#   centroid). occasion = week (winter) or two-week period (bear); y = the cell. Winter: the two
#   species come from the same cameras, so a site-week NA for either species is dropped for both
#   (shared-detector ruling; 47 cells differ). Dates: bear occasions are 14 days apart, so date =
#   1 January of the year + ordinal - 1; the winter ordinal days are not monotone in places (gaps of
#   -3 to 10 days), so they ship as obs_ordinal_day as deposited and no date column. Survey
#   evidence: deposited_matrix (NA = no survey). All three species are IUCN LC: coordinates kept as
#   published.
#   One bear site-year has no surveyed occasion and has no rows (673 units).
#   Not shipped: PO_join_count_truncated (density of presence-only records, other data); the
#   presence-only bear records (not surveys).
#   Overlap: the Northern Zone 2016-2018 winter coyote detections are the same cameras as
#   twining_2024_adirondack_carniv_occ (doi:10.5061/dryad.pc866t1rz); bobcat and the southern
#   surveys are not elsewhere in eco.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
dir <- download_dryad("10.5061/dryad.ghx3ffbwf", "twining_2024_newyork_carniv_occ")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
g <- rf("allNY_10kmgrid_alllandscapecovs_final_dryad\\.csv"); stopifnot(nrow(g) == 14008, identical(g$plot_id, 1:14008))
gcov <- function(fid, x, y) {
  i <- match(fid, g$plot_id); stopifnot(!anyNA(i), all(sqrt((g$X[i] - x)^2 + (g$Y[i] - y)^2) < 2300))
  g[i, .(unit_grid10km = plot_id, unit_deciduous = Deciduous, unit_coniferous = Coniferous, unit_mixed_forest = Mixed, unit_scrub = Scrub,
         unit_grassland = Grassland, unit_pasture = Pasture, unit_crops = Cultivated.Crops, unit_road_density = road_density,
         unit_elevation_m = elevation, unit_forest_edge = forest_edge)]
}
citation <- "Twining, J. P., Fuller, A. K., Sun, C. C., Calderón-Acevedo, C. A., Schlesinger, M. D., Berger, M., Kramer, D., & Frair, J. L. (2024). Integrating presence-only and detection/non-detection data to estimate distributions and expected abundance of difficult-to-monitor species on a landscape-scale [Dataset]. Dryad. https://doi.org/10.5061/dryad.ghx3ffbwf"
ref <- "Twining, J. P. et al. (2024). Integrating presence-only and detection/non-detection data to estimate distributions and expected abundance of difficult-to-monitor species on a landscape-scale. Journal of Applied Ecology."
common <- list(creator = "Twining, Joshua P.; Fuller, Angela K.; Sun, Catherine C.; Calderón-Acevedo, Camilo A.; Schlesinger, Matthew D.; Berger, Melanie; Kramer, David; Frair, Jacqueline L.",
  pubDate = "2024", doi = "10.5061/dryad.ghx3ffbwf", sourceURL = "https://doi.org/10.5061/dryad.ghx3ffbwf", citation = citation, paperDOI = "10.1111/1365-2664.14633",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site", occasionKind = "time", taxonInclusion = "target")

## winter: bobcat and coyote
b <- rf("allNY_2013-2021_bobcatPArecords_pixelID_10kmgrid\\.csv"); cy <- rf("allNY_2013-2021_coyotePArecords_pixelID_10kmgrid\\.csv"); jd <- rf("juliandays_allNY_2013-2021\\.csv")
k <- c("FID_allNY_10km", "sitename", "year", "x", "y"); O <- c("o1", "o2", "o3")
stopifnot(nrow(b) == 3879, identical(b[, ..k], cy[, ..k]), identical(as.character(jd$Station), as.character(b$sitename)), identical(jd$year, b$year),
          all(unlist(b[, ..O]) %in% c(0L, 1L, NA)), all(unlist(cy[, ..O]) %in% c(0L, 1L, NA)), !anyNA(jd))
uid <- paste0(b$year, "_", b$sitename); stopifnot(!anyDuplicated(uid))
MB <- as.matrix(b[, ..O]); MC <- as.matrix(cy[, ..O]); na <- is.na(MB) | is.na(MC)
stopifnot(sum(is.na(MB) != is.na(MC)) == 47)
Y <- array(NA_integer_, dim = c(nrow(b), 3, 2), dimnames = list(uid, NULL, c("LYNRUF", "CANLAT")))
MB[na] <- NA; MC[na] <- NA; Y[, , "LYNRUF"] <- MB; Y[, , "CANLAT"] <- MC
sc <- cbind(data.table(year = b$year, sitename = as.character(b$sitename), utm_x = b$x, utm_y = b$y), gcov(b$FID_allNY_10km, b$x, b$y))
setnames(sc, sub("^unit_", "", names(sc)))
long <- array_to_eco(Y, site_ids = uid, site_covs = as.data.frame(sc),
                     obs_covs = list(ordinal_day = as.matrix(jd[, .(julianset, juliancheck1, juliancheck2)])))
long <- order_eco(long)
stopifnot(nrow(long) == 2 * sum(!na), sum(long$y) == sum(MB, na.rm = TRUE) + sum(MC, na.rm = TRUE))
TABLE <- "twining_2024_ny_bobcat_coyote_occ"
taxa <- make_taxa(c("LYNRUF", "CANLAT"), c("Lynx rufus", "Canis latrans"), vernacularName = c("Bobcat", "Coyote"))
ds <- write_table(long, TABLE, c(common, list(
  title = sprintf("Weekly baited camera detections of bobcat and coyote at %s site-years across New York State, winters 2013-2021", format(uniqueN(long$unit), big.mark = ",")),
  abstract = "Detection/non-detection of bobcat and coyote on three weekly occasions at baited winter camera traps in southern New York (2013-2015, 2019-2021) and the Northern Zone (2016-2018), one camera per 15-km2 cell, with UTM coordinates and 10-km2 landscape covariates.",
  samplingProtocol = "Winter camera traps deployed opposite baited stations on trees near the centre of each 15-km2 grid cell; weekly detection records over three weeks per site-year.",
  closure = "closed", closureNote = "three weeks of one winter deployment per site-year",
  geographicCoverage = "New York State, USA (southern tier and Northern Zone); camera UTM coordinates as published",
  temporalCoverage = "2013/2021",
  notShipped = list(po_density = "PO_join_count_truncated (presence-only density)", presence_only = "presence-only records"),
  notes = "unit = site-year: site names are reused across years at different coordinates. The Northern Zone 2016-2018 coyote detections overlap twining_2024_adirondack_carniv_occ. obs_ordinal_day is the deposited ordinal day of each occasion (relative to 1 January; negative in December); it is not monotone for some site-years, so no ISO date is derived.")),
  taxa = taxa, script = "data/twining_2024_newyork_carniv_occ.R")
stage_dict_row(TABLE, description = "Weekly baited camera detections of bobcat and coyote at 3,849 site-years across New York State, winters 2013-2021.",
  url = "https://doi.org/10.5061/dryad.ghx3ffbwf", reference = ref, doi_paper = "10.1111/1365-2664.14633", doi_data = "10.5061/dryad.ghx3ffbwf",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "Statewide stacked winter occupancy.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-species occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (stacked site-years, 3 weekly occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "As published", notes = "Statewide winter carnivore survey.")

## summer: black bear
br <- rf("allNY_2016-2018_bearPAdata_pixelID_10kmgrid_final\\.csv"); bd <- rf("NY_blackbears_ordinaldates\\.csv")
O5 <- paste0("o", 1:5); D5 <- paste0("date", 1:5)
stopifnot(nrow(br) == 674, identical(bd$Station, br$Station), identical(bd$year, br$year), all(br$x == bd$utm_x & br$y == bd$utm_y),
          all(unlist(br[, ..O5]) %in% c(0L, 1L, NA)), !anyNA(bd[, ..D5]), all(diff(t(as.matrix(bd[, ..D5]))) == 14))
uid <- paste0(br$year, "_", br$Station); stopifnot(!anyDuplicated(uid))
Y <- array(as.matrix(br[, ..O5]), dim = c(674, 5, 1), dimnames = list(uid, NULL, "URSAME"))
dt <- as.matrix(bd[, ..D5]); dmat <- matrix(as.character(as.IDate(sprintf("%d-01-01", br$year)) + as.vector(dt) - 1L), nrow = 674)
sc <- cbind(data.table(year = br$year, station = br$Station, utm_x = br$x, utm_y = br$y), gcov(br$FID_allNY_10km, br$x, br$y)); setnames(sc, sub("^unit_", "", names(sc)))
long <- array_to_eco(Y, site_ids = uid, site_covs = as.data.frame(sc), obs_covs = list(dt = dmat))
setnames(long, "obs_dt", "date"); long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(as.matrix(br[, ..O5]))), sum(long$y) == sum(as.matrix(br[, ..O5]), na.rm = TRUE))
TABLE <- "twining_2024_ny_blackbear_occ"
taxa <- make_taxa("URSAME", "Ursus americanus", vernacularName = "American black bear")
ds <- write_table(long, TABLE, modifyList(common, list(
  title = "Two-week camera and hair-snare detections of black bears at 673 site-years in southern New York, summers 2016-2018",
  abstract = "Detection/non-detection of American black bears on five two-week occasions at camera traps set opposite hair snares in the High Allegheny Plateau, Western Allegheny Plateau and Lower New England ecoregions of New York, summers 2016-2018, with UTM coordinates and 10-km2 landscape covariates.",
  samplingProtocol = "Camera trap opposite a barbed-wire hair snare encircling 3-6 trees near the centre of each 25-km2 cell; checked and re-baited every two weeks for ten weeks; at most one detection per two-week period.",
  closure = "closed", closureNote = "ten weeks of one summer deployment per site-year", taxonInclusion = "single",
  geographicCoverage = "Southern New York State, USA; camera UTM coordinates as published", temporalCoverage = sprintf("%s/%s", min(long$date), max(long$date)),
  notShipped = list(po_density = "PO_join_count_truncated (presence-only density)", presence_only = "presence-only bear records (iSeeMammals and online repositories)"),
  notes = "unit = site-year. date is the deposited ordinal day of each occasion converted from 1 January of the year. The Dryad methods mention 2017 and 2018 surveys; the file also has 2016.")),
  taxa = taxa, script = "data/twining_2024_newyork_carniv_occ.R")
stage_dict_row(TABLE, description = "Two-week camera detections of American black bears at 673 site-years in southern New York, summers 2016-2018.",
  url = "https://doi.org/10.5061/dryad.ghx3ffbwf", reference = ref, doi_paper = "10.1111/1365-2664.14633", doi_data = "10.5061/dryad.ghx3ffbwf",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "Stacked summer occupancy.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (stacked site-years, 5 two-week occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "As published", notes = "Black bear summer survey.")
