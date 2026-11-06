#!/usr/bin/env Rscript
# Table:  cove_2018_lowerkeys_dynocc (both taxa, coordinates coarsened) and
#         cove_2018_lowerkeys_exact_dynocc (the unflagged taxon, free-ranging cat, at the source's precision; E7 ruling 3)
# Source: Dryad, doi:10.5061/dryad.748pd64, version 1 (published 2019-03-30), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API). Cove, M. V., Gardner, B., Simons, T. R. & O'Connell, A. F. Data from:
#         Co-occurrence dynamics of endangered Lower Keys marsh rabbits and free-ranging domestic cats: prey
#         responses to an exotic predator removal program.
# Paper:  Cove, M. V., Gardner, B., Simons, T. R. & O'Connell, A. F. (2018). Co-occurrence dynamics of endangered
#         Lower Keys marsh rabbits and free-ranging domestic cats: prey responses to an exotic predator removal
#         program. Ecology and Evolution 8: 4042-4052. doi:10.1002/ece3.3954 (open access, PMC5916284, read).
#         Design (paper section 2.2): 84 camera sites (two opposing cameras 2-5 m apart per site) on the National Key
#         Deer Refuge and other public land on Big Pine Key, Florida, first surveyed in 2013 (45 sites, 16 Jan - 4 Apr)
#         or 2014 (39 sites, 16 Apr - 2 Jun) and resurveyed 28 Mar - 14 May 2015; cameras active 15-16 days; daily
#         detection histories of the marsh rabbit and the free-ranging domestic cat; dynamic (co-)occupancy models;
#         closure within each primary period assumed by the authors.
# Data:   Cove_etal_Ecology_Evolution_2018_data.csv (84 sites x 94 columns, latin-1): Site, UTM N, UTM E, 2015 Start
#           / End Date (m/d/yy), then four blocks of 16 daily cells (0/1, '.' = camera not active that day):
#           Rabbits 2013/2014 (cols 6-21), Rabbits 2015 (22-37), an unnamed column repeating the site id in upper
#           case (38), Cats 2013/2014 (39-54), Cats 2015 (55-70); then site covariates (readme): year_2013,
#           dist_cam_z, Total CatCaps_2013_14, CatIndividuals_2013_14, Total CatCaps_2015, CatIndividuals_2015,
#           RabbitPresence_2013_14, HumanTrail, Rabbitat, Rabbitat_buff, a second HumanTrail, dist_rd_z, dist_dev_z,
#           dist_cat2014_z, dist_cat2015_z, bin_2014cat, bin_2015cat, bin_20142015, DESCRIPTION (habitat),
#           freshwater, salt_button, upland, hectares_z, LiDar_z. '.' is missing throughout.
#         README_for_Cove_etal_Ecology_Evolution_2018_data.txt: column definitions; 2013/14 start and end dates are
#           not deposited ("can be requested from the lead author").
#         Quirks (asserted): the '.' pattern is identical for rabbit and cat in each period (one camera pair surveys
#           both); the 2015 start-end span is 15-17 days for 16 slots, and slot 16 is '.' where the span is 15
#           days, so a slot's calendar date is not recoverable exactly (no date column); one 2015 start date is
#           '4/30/16' (the end is 5/15/15). Total CatCaps_2013_14 equals Total CatCaps_2015 at 83 of 84 sites and
#           CatIndividuals_2013_14 equals CatIndividuals_2015 at all 84; CatIndividuals > 0 exactly where a cat was
#           detected in the 2015 history at 83 of 84 sites, so both pairs hold the 2015 values (the paper's
#           covariates are "2015 caps" and "2015 inds"). The two HumanTrail columns disagree at 10 sites.
#           RabbitPresence_2013_14 (34 sites) disagrees with the deposited 2013/14 rabbit history (30 sites) at 18.
# Mapping (dynamic occupancy; responseType detection, unitKind site): unit = Site (source code), taxon = SYLPAL
#   (Sylvilagus palustris hefneri) / FELCAT (Felis catus), period 1 = first primary survey (2013 or 2014, by site;
#   period_year), period 2 = 2015; occasion = daily slot 1..16; y = the deposited 0/1. surveyEvidence =
#   deposited_matrix: a '.' cell is not surveyed and has no row (same pattern for both taxa, asserted).
#   unit_ covariates as deposited (standardised z-scores where the readme says _z). period_cat_individuals and
#   period_cat_detections: the readme's 2015 individual-cat and cat-detection counts, on period 2 rows only.
#   period_deploy_start / period_deploy_end: 2015 camera start and end dates (ISO), period 2 only.
#   Coordinates (E7): the source calls the Lower Keys marsh rabbit endangered (US federal list; E7 a); the cat is
#   not flagged. Two tables (E7 ruling 3): the whole table with the UTM pair snapped to the centre of its 10 km cell
#   (E7 ruling 1) and LiDar_z (an elevation) not shipped (E7 ruling 4: a standardised elevation cannot be rounded
#   to 100 m); and the cat-only table with UTM as deposited and LiDar_z.
# Not shipped: the repeated upper-case site id column; RabbitPresence_2013_14 (a summary of detections that
#   disagrees with the deposited history at 18 sites); Total CatCaps_2013_14 and CatIndividuals_2013_14 (copies of
#   the 2015 columns; the 2013/14 values are not deposited); both HumanTrail columns (two columns of one name that
#   disagree at 10 sites; which is the readme's is not knowable); the '4/30/16' start date (NA); 2013/14 dates (not
#   deposited); model estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cove_2018_lowerkeys_dynocc"
EXACT <- "cove_2018_lowerkeys_exact_dynocc"
dir <- download_dryad("10.5061/dryad.748pd64", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("README_for_Cove_etal_Ecology_Evolution_2018_data.txt", "Cove_etal_Ecology_Evolution_2018_data.csv")))

raw <- fread(file.path(dir, "Cove_etal_Ecology_Evolution_2018_data.csv"), header = FALSE, skip = 1, colClasses = "character",
             encoding = "Latin-1")
hdr <- unname(unlist(fread(file.path(dir, "Cove_etal_Ecology_Evolution_2018_data.csv"), header = FALSE, nrows = 1, colClasses = "character")))
stopifnot(nrow(raw) == 84L, ncol(raw) == 94L, length(hdr) == 94L,
          identical(hdr[c(1:6, 22, 39, 55, 71)], c("Site", "UTM N", "UTM E", "2015 Start Date", "2015 End Date",
            "Rabbits 2013/2014", "Rabbits 2015", "Cats 2013/2014", "Cats 2015", "year_2013")),
          all(hdr[c(7:21, 23:38, 40:54, 56:70)] == ""),
          identical(hdr[71:94], c("year_2013", "dist_cam_z", "Total CatCaps_2013_14", "CatIndividuals_2013_14",
            "Total CatCaps_2015", "CatIndividuals_2015", "RabbitPresence_2013_14", "HumanTrail", "Rabbitat",
            "Rabbitat_buff", "HumanTrail", "dist_rd_z", "dist_dev_z", "dist_cat2014_z", "dist_cat2015_z", "bin_2014cat",
            "bin_2015cat", "bin_20142015", "DESCRIPTION", "freshwater", "salt_button", "upland", "hectares_z", "LiDar_z")))
M <- as.matrix(raw)
site <- M[, 1]
stopifnot(!anyDuplicated(site), identical(toupper(site), M[, 38]))
blk <- list(SYLPAL = list(`1` = 6:21, `2` = 22:37), FELCAT = list(`1` = 39:54, `2` = 55:70))
num <- function(x) { x[x == "."] <- NA; as.numeric(x) }
Y <- lapply(blk, lapply, function(cols) { m <- M[, cols]; stopifnot(all(m %in% c("0", "1", "."))); m[m == "."] <- NA
  m <- matrix(as.integer(m), nrow(m)); m })
# one camera pair surveys both taxa: the not-active pattern is identical
for (p in c("1", "2")) stopifnot(identical(is.na(Y$SYLPAL[[p]]), is.na(Y$FELCAT[[p]])))
na1 <- is.na(Y$SYLPAL[["1"]]); na2 <- is.na(Y$SYLPAL[["2"]])
stopifnot(all(!na1[, 1:15]), all(!na2[, 1:15]), sum(na1[, 16]) == 52L, sum(na2[, 16]) == 74L)
stopifnot(sum(Y$SYLPAL[["1"]], na.rm = TRUE) > 0, sum(Y$FELCAT[["2"]], na.rm = TRUE) > 0)
det <- function(m) apply(m, 1, max, na.rm = TRUE)
stopifnot(sum(det(Y$SYLPAL[["1"]])) == 30L, sum(det(Y$FELCAT[["1"]])) == 55L, sum(det(Y$FELCAT[["2"]])) == 38L)

# covariate facts
cv <- function(n) M[, 70 + match(n, hdr[71:94])]
y13 <- as.integer(cv("year_2013")); stopifnot(all(y13 %in% 0:1), sum(y13) == 45L)
stopifnot(sum(M[, 73] == M[, 75]) == 83L, sum(M[, 74] == M[, 76]) == 84L,
          sum((as.integer(M[, 76]) > 0) == (det(Y$FELCAT[["2"]]) > 0)) == 83L,
          sum(M[, 78] != M[, 81]) == 10L,
          sum(as.integer(M[, 77]) != det(Y$SYLPAL[["1"]])) == 18L)
st <- as.IDate(M[, 4], format = "%m/%d/%y"); en <- as.IDate(M[, 5], format = "%m/%d/%y")
stopifnot(!anyNA(st), !anyNA(en), sum(year(st) == 2016L) == 1L, all(year(en) == 2015L))
st[year(st) == 2016L] <- NA
span <- as.integer(en - st)
stopifnot(all(span[!is.na(span)] %in% 15:17), all(na2[!is.na(span) & span == 15L, 16]))

uc <- data.table(unit = site, utm_n = as.numeric(M[, 2]), utm_e = as.numeric(M[, 3]),
  unit_dist_cameras_z = num(cv("dist_cam_z")),
  unit_rabbit_habitat = as.integer(M[, 79]), unit_rabbit_habitat_buffer = as.integer(M[, 80]),
  unit_dist_road_z = num(cv("dist_rd_z")), unit_dist_development_z = num(cv("dist_dev_z")),
  unit_dist_cat_removed_2014_z = num(cv("dist_cat2014_z")), unit_dist_cat_removed_2015_z = num(cv("dist_cat2015_z")),
  unit_cat_removed_500m_2014 = as.integer(cv("bin_2014cat")), unit_cat_removed_500m_2015 = as.integer(cv("bin_2015cat")),
  unit_cat_removed_500m_2014_2015 = as.integer(cv("bin_20142015")),
  unit_habitat = cv("DESCRIPTION"), unit_freshwater = as.integer(cv("freshwater")),
  unit_coastal_salt_buttonwood = as.integer(cv("salt_button")), unit_upland = as.integer(cv("upland")),
  unit_patch_size_z = num(cv("hectares_z")), unit_lidar_elevation_z = num(cv("LiDar_z")))
stopifnot(!anyNA(uc$utm_n), !anyNA(uc$utm_e), all(uc$utm_n > 2.7e6 & uc$utm_n < 2.75e6), all(uc$utm_e > 4.5e5 & uc$utm_e < 4.7e5),
          sum(is.na(uc$unit_dist_cameras_z)) > 0, uniqueN(uc$unit_habitat) == 7L,
          all(uc$unit_freshwater + uc$unit_coastal_salt_buttonwood + uc$unit_upland == 1L))
pc <- data.table(unit = rep(site, 2), period = rep(1:2, each = 84),
  period_year = c(ifelse(y13 == 1L, 2013L, 2014L), rep(2015L, 84)),
  period_deploy_start = c(rep(NA_character_, 84), as.character(st)),
  period_deploy_end = c(rep(NA_character_, 84), as.character(en)),
  period_cat_individuals = c(rep(NA_integer_, 84), as.integer(M[, 76])),
  period_cat_detections = c(rep(NA_integer_, 84), as.integer(M[, 75])))

build <- function(taxa_codes) {
  long <- rbindlist(lapply(taxa_codes, function(tx) rbindlist(lapply(1:2, function(p) {
    m <- Y[[tx]][[as.character(p)]]
    rbindlist(lapply(1:16, function(j) { k <- !is.na(m[, j])
      data.table(unit = site[k], taxon = tx, y = m[k, j], period = p, occasion = j) })) }))))
  long <- merge(merge(long, pc, by = c("unit", "period")), uc, by = "unit")
  stopifnot(nrow(long) == length(taxa_codes) * (sum(!na1) + sum(!na2)))
  long
}
n_surv <- sum(!na1) + sum(!na2)
stopifnot(n_surv == 84L * 32L - 52L - 74L)

# coarsened whole table: UTM snapped to the 10 km cell of the source grid; LiDar_z not shipped
full <- build(c("SYLPAL", "FELCAT"))
full[, `:=`(unit_x = floor(utm_e / 10000) * 10000 + 5000, unit_y = floor(utm_n / 10000) * 10000 + 5000,
            unit_coordinateUncertaintyInMeters = 7071)]
cat(sprintf("  10 km cells: %d\n", uniqueN(full[, paste(unit_x, unit_y)])))
full[, c("utm_e", "utm_n", "unit_lidar_elevation_z") := NULL]
full <- order_eco(full)
ex <- build("FELCAT")
ex[, `:=`(unit_x = utm_e, unit_y = utm_n)]
ex[, c("utm_e", "utm_n") := NULL]
ex <- order_eco(ex)

taxa_all <- make_taxa(c("SYLPAL", "FELCAT"), c("Sylvilagus palustris hefneri", "Felis catus"),
  vernacularName = c("Lower Keys marsh rabbit", "Domestic cat (free-ranging)"), taxonRank = c("subspecies", "species"))
taxa_all[, taxonRemarks := c("US federally listed as endangered; the source calls it endangered (coordinates coarsened, E7 a)",
                             "Introduced (exotic predator) on Big Pine Key")]
periods <- data.table(period = 1:2, label = c("first primary survey (2013: 16 Jan - 4 Apr, 45 sites; 2014: 16 Apr - 2 Jun, 39 sites)",
                                              "2015 resurvey (28 Mar - 14 May per the paper)"),
                      year_start = c(2013L, 2015L), year_end = c(2014L, 2015L))

base <- list(
  creator = "Cove, Michael V.; Gardner, Beth; Simons, Theodore R.; O'Connell, Allan F.", pubDate = "2019-03-30",
  doi = "10.5061/dryad.748pd64", paperDOI = "10.1002/ece3.3954", sourceURL = "https://doi.org/10.5061/dryad.748pd64",
  citation = "Cove, M. V., Gardner, B., Simons, T. R., & O'Connell, A. F. (2019). Data from: Co-occurrence dynamics of endangered Lower Keys marsh rabbits and free-ranging domestic cats: prey responses to an exotic predator removal program [Dataset]. Dryad. https://doi.org/10.5061/dryad.748pd64",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap surveys of the endangered Lower Keys marsh rabbit and free-ranging domestic cats at 84 sites on Big Pine Key, Florida, first in 2013 or 2014 and again in 2015, during a cat removal programme; daily detection histories over 15-16 days per survey, with habitat, distance and cat-removal covariates. The authors fitted dynamic occupancy and dynamic co-occurrence models.",
  samplingProtocol = "Two opposing camera traps 2-5 m apart on game trails at each site, active 15-16 days per primary period; a photograph of the species on a day is a detection for that day; sites surveyed once in 2013 or 2014 and again in 2015.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors assume closure within each 15-16 day primary period (gestation and movement arguments, paper section 2.2); period 1 is 2013 for some sites and 2014 for others (period_year)",
  occasionKind = "time", temporalCoverage = "2013/2015",
  crs = "EPSG:26917 (NAD83 / UTM zone 17N assumed: the deposit gives UTM northing and easting without zone or datum; the values fall in zone 17 over Big Pine Key)",
  covariateNote = "unit_*_z: standardised z-scores as deposited (distance between the paired cameras, to the nearest road, development, and cat removed in 2014 / 2015; habitat patch size; LiDAR mean elevation within 25 m). unit_rabbit_habitat(_buffer): patch (and its 100 m buffer) is marsh rabbit habitat. unit_cat_removed_500m_*: a cat was trapped and removed within 500 m. unit_freshwater / unit_coastal_salt_buttonwood / unit_upland: the paper's three habitat groups. period_cat_individuals / period_cat_detections: individual cats (by pelage) and cat detections at the site in 2015 (period 2 only; the 2013/14 values are not deposited). period_deploy_start / _end: 2015 camera dates (period 2 only).")

nsh <- list(site_id_copy = "an unnamed column repeating the site id in upper case",
  rabbit_presence = "RabbitPresence_2013_14, a summary of detections that disagrees with the deposited 2013/14 rabbit history at 18 of 84 sites",
  cat_2013_14_counts = "Total CatCaps_2013_14 and CatIndividuals_2013_14: copies of the 2015 columns (equal at 83 and 84 of 84 sites; CatIndividuals > 0 where a cat was detected in 2015 at 83 sites); the 2013/14 values are not in the deposit",
  human_trail = "both HumanTrail columns: two columns of one name that disagree at 10 sites; which one the readme defines is not knowable",
  bad_date = "the 2015 start date '4/30/16' of one site (end 5/15/15): shipped as NA",
  dates_2013_14 = "2013/14 camera dates: not deposited (readme: on request from the lead author); slot dates in 2015 are not exactly recoverable (start-end spans of 15-17 days for 16 slots)",
  model_output = "occupancy, colonisation, extinction and co-occurrence estimates")

ds_full <- c(list(title = "Daily camera detections of Lower Keys marsh rabbits and free-ranging cats at 84 sites on Big Pine Key, Florida, 2013-2015 (coordinates coarsened)"),
  base, list(taxonInclusion = "target",
  geographicCoverage = "Big Pine Key, Lower Florida Keys, USA (about 24.7 N, 81.4 W); National Key Deer Refuge and adjacent public land; site coordinates coarsened to 10 km cells",
  coordinatesCoarsened = list(value = TRUE, method = "The source calls the Lower Keys marsh rabbit endangered (E7 a); the UTM pair is snapped to the centre of its 10 km cell of the UTM grid (E7 ruling 1), uncertainty 7,071 m; LiDar_z (elevation) not shipped (E7 ruling 4). The cat-only table cove_2018_lowerkeys_exact_dynocc keeps the deposited coordinates."),
  notShipped = c(nsh, list(exact_coordinates = "site UTM coordinates (coarsened, E7; exact in cove_2018_lowerkeys_exact_dynocc for the cat)",
                           lidar_elevation = "LiDar_z, a standardised elevation (E7 ruling 4 in a coarsened table; shipped in the _exact sibling)")),
  notes = "Each site has one 15-16 day survey in period 1 (2013 or 2014) and one in 2015; slot 16 is not surveyed where the cameras ran 15 days. Sibling: cove_2018_lowerkeys_exact_dynocc (cat only, exact coordinates)."))
ds_ex <- c(list(title = "Daily camera detections of free-ranging cats at 84 sites on Big Pine Key, Florida, 2013-2015 (exact coordinates)"),
  base, list(taxonInclusion = "single",
  geographicCoverage = "Big Pine Key, Lower Florida Keys, USA (about 24.7 N, 81.4 W); National Key Deer Refuge and adjacent public land",
  coordinatesCoarsened = list(value = FALSE, method = "The cat is not flagged; the UTM pair is as deposited. The marsh rabbit (flagged, E7 a) is in cove_2018_lowerkeys_dynocc with coarsened coordinates."),
  notShipped = c(nsh, list(flagged_taxon = "the Lower Keys marsh rabbit (endangered; in cove_2018_lowerkeys_dynocc with coarsened coordinates, E7 ruling 3)")),
  notes = "The _exact sibling of cove_2018_lowerkeys_dynocc (E7 ruling 3): the cat, at the source's precision."))

ds <- write_table(full, TABLE, ds_full, taxa = taxa_all, periods = periods, script = "data/cove_2018_lowerkeys_dynocc.R")
ds2 <- write_table(ex, EXACT, ds_ex, taxa = taxa_all[taxon == "FELCAT"], periods = periods, script = "data/cove_2018_lowerkeys_dynocc.R")

ref <- "Cove, M. V., Gardner, B., Simons, T. R., & O'Connell, A. F. (2018). Co-occurrence dynamics of endangered Lower Keys marsh rabbits and free-ranging domestic cats: prey responses to an exotic predator removal program. Ecology and Evolution, 8, 4042-4052."
stage_dict_row(TABLE,
  description = "Daily camera-trap detections of the endangered Lower Keys marsh rabbit and free-ranging cats at 84 sites on Big Pine Key, Florida, in 2013/2014 and 2015, during cat removal; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.748pd64", reference = ref, doi_paper = "10.1002/ece3.3954", doi_data = "10.5061/dryad.748pd64",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Two primary periods per site; '.' cells not surveyed; marsh rabbit flagged (endangered, E7 a), UTM snapped to 10 km cells; cat-only _exact sibling.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy", sampling_protocol = "camera_trap",
  design = "Multi-season (2 primary periods, 15-16 daily occasions; 84 sites)", realm = "Terrestrial", country = "USA",
  coordinates = "Coarsened (10 km cell of the source's UTM grid)", notes = "Prey and introduced predator, co-occurrence during predator removal.")
stage_dict_row(EXACT,
  description = "Daily camera-trap detections of free-ranging cats at 84 sites on Big Pine Key, Florida, in 2013/2014 and 2015, during cat removal; exact coordinates (sibling of cove_2018_lowerkeys_dynocc).",
  url = "https://doi.org/10.5061/dryad.748pd64", reference = ref, doi_paper = "10.1002/ece3.3954", doi_data = "10.5061/dryad.748pd64",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "_exact sibling (E7 ruling 3): the unflagged cat at the deposited UTM coordinates.", source_via = "Dryad")
stage_tag_row(EXACT, ds2, taxon_group = "Mammals", model_family = "Dynamic occupancy", sampling_protocol = "camera_trap",
  design = "Multi-season (2 primary periods, 15-16 daily occasions; 84 sites)", realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "Introduced predator during a removal programme; _exact sibling.")
