#!/usr/bin/env Rscript
# Table:  calhoun_2023_hopland_mamm_dynocc
# Source: Dryad doi:10.6078/D1W70R, version 9 (published 2023-05-22), licence CC0 1.0 (as shown on
#         the Dryad page; SPDX CC0-1.0). Calhoun, K. L., Goldstein, B. R., Gaynor, K. M., McInturff, A.,
#         Solorio, L., & Brashares, J. S. "Mammalian resilience to megafire in western U.S. woodland
#         savannas".
# Paper:  Calhoun, K. L., Goldstein, B. R., Gaynor, K. M., McInturff, A., Solorio, L., & Brashares,
#         J. S. (2023). Mammalian resilience to megafire in western U.S. woodland savannas. Ecosphere,
#         14, e4613. doi:10.1002/ecs2.4613
# Data:   a 36-camera grid (cells 750 m apart) at the UC Hopland Research and Extension Center,
#         Mendocino County, California; the 2018 River Fire (Mendocino Complex) burned 25 of the
#         36 stations. Files as deposited:
#           <Species>_detection_history.csv (9 files: Bear, Bobcat, Coyote, Deer, Fox,
#               Gray_squirrel, Jack_Rabbit, Raccoon, Skunk): 180 rows = camera-year ("A03_2016"),
#               218 weekly columns "2016-10-01_2016-10-07" .. "2020-11-28_2020-12-01" spanning all
#               five years; a row has values only in its own year's October-November weeks (8
#               weeks, 7 in 2017); 0 = not detected, 1 = detected, NA = camera not operating.
#               The NA pattern is identical across the nine files (asserted).
#           metadata.csv: 180 camera-years, vegetation class, pasture, camera direction (5 NA),
#               attractant, canopy, burn status in three codings (burn, burn2, burn3) and 10 0/1
#               dummies recoding them, detection distance, camera height, ruggedness, elevation,
#               chaparral / woodland / grassland cover within 100 m, burn severity (dNBR).
#           cam_op.csv: deployment and malfunction dates per camera-year.
#           species_groups.csv: 12 species with size and diet group.
#           species_recordtable_OctNov_15min.csv: 24,300 independent records (15-min) of 13
#               species, the raw detections behind the histories.
# Mapping (dynamic community occupancy): unit = camera (36), taxon = 6-letter code, period =
#   year (1 = 2016 .. 5 = 2020), occasion = week within the year's October-November window
#   (1..8), y = detected 0/1. The camera-year rows are combined per camera (each row has values
#   only in its own year, asserted). Survey evidence: the deposited matrix; NA (camera not
#   operating) is a missing row (E4); every one of the nine species has a row at every
#   operating camera-week. obs_week_start / obs_week_end = the week's bounds.
#   unit_: metadata columns constant within camera across years (asserted); period_: those
#   varying by year (burn status, canopy, detection distance, camera height, burn severity).
#   burn3's "Unburned Post" (2018) and "Unburned_Post" (2019-2020) are one level, written
#   Unburned_Post. No coordinates are deposited.
#   Not shipped: the ten fac* dummies (recodings of burn / burn2 / burn3); the record table
#   (Ground_Squirrel, Mountain_Lion, Pig and Brush_Rabbit have records but no deposited
#   history, and the record table does not reproduce the deposited histories cell for cell:
#   records fall in weeks the authors set to NA and a few cells differ, so a history derived
#   from it would not be comparable); cam_op.csv (its information is the NA pattern).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "calhoun_2023_hopland_mamm_dynocc"
dir <- download_dryad("10.6078/D1W70R", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

sp <- data.table(file = c("Bear", "Bobcat", "Coyote", "Deer", "Fox", "Gray_squirrel", "Jack_Rabbit", "Raccoon", "Skunk"),
                 taxon = c("URSAME", "LYNRUF", "CANLAT", "ODOHEM", "UROCIN", "SCIGRI", "LEPCAL", "PROLOT", "MEPMEP"),
                 sci = c("Ursus americanus", "Lynx rufus", "Canis latrans", "Odocoileus hemionus", "Urocyon cinereoargenteus",
                         "Sciurus griseus", "Lepus californicus", "Procyon lotor", "Mephitis mephitis"),
                 vern = c("American black bear", "Bobcat", "Coyote", "Black-tailed deer", "Gray fox",
                          "Western gray squirrel", "Black-tailed jackrabbit", "Raccoon", "Striped skunk"))
stopifnot(setequal(paste0(sp$file, "_detection_history.csv"), grep("_detection_history.csv$", list.files(dir), value = TRUE)))
read_h <- function(f) fread(file.path(dir, paste0(f, "_detection_history.csv")))
h1 <- read_h(sp$file[1])
cy <- names(h1)[1]; cols <- names(h1)[-1]
stopifnot(nrow(h1) == 180L, length(cols) == 218L, cols[1] == "2016-10-01_2016-10-07")
rid <- h1[[1]]
cam <- sub("_\\d{4}$", "", rid); yr <- as.integer(sub(".*_", "", rid))
stopifnot(uniqueN(cam) == 36L, all(table(yr) == 36L), all(yr %in% 2016:2020))
mats <- lapply(sp$file, function(f) { h <- read_h(f); stopifnot(identical(h[[1]], rid), identical(names(h)[-1], cols))
  m <- as.matrix(h[, -1]); stopifnot(all(m[!is.na(m)] %in% 0:1)); m })
for (m in mats) stopifnot(identical(is.na(m), is.na(mats[[1]])))        # identical NA pattern across species
na <- is.na(mats[[1]])
col_yr <- as.integer(substr(cols, 1, 4))
stopifnot(all(na[outer(yr, col_yr, "!=")]))                               # a row has values only in its own year
keep <- which(colSums(!na) > 0)
stopifnot(length(keep) == 39L, identical(as.vector(table(col_yr[keep])), c(8L, 7L, 8L, 8L, 8L)))
stopifnot(sum(rowSums(!na) == 0) == 5L)                                   # five camera-years never operated
wk_start <- as.Date(sub("_.*", "", cols[keep])); wk_end <- as.Date(sub(".*_", "", cols[keep]))
stopifnot(all(wk_end - wk_start == 6))

cams <- sort(unique(cam))
y <- array(NA_integer_, c(36, length(keep), nrow(sp)), dimnames = list(cams, cols[keep], sp$taxon))
for (k in seq_len(nrow(sp))) for (i in seq_along(rid)) {
  v <- mats[[k]][i, keep]; w <- which(!is.na(v))
  stopifnot(all(is.na(y[cam[i], w, k]))); y[cam[i], w, k] <- v[w]
}
stopifnot(sum(!is.na(y)) == sum(!na) * nrow(sp), sum(y, na.rm = TRUE) == sum(sapply(mats, sum, na.rm = TRUE)))
obs_start <- matrix(rep(format(wk_start), each = 36), 36); obs_end <- matrix(rep(format(wk_end), each = 36), 36)

# ---- covariates
md <- fread(file.path(dir, "metadata.csv"))
stopifnot(identical(md$Site_ID, rid), identical(md$Site, cam), identical(md$Year, yr))
md[burn3 == "Unburned Post", burn3 := "Unburned_Post"]
stopifnot(setequal(unique(md$burn3), c("Unburned", "Burned", "Unburned_Post", "Burned_Lag1", "Burned_Lag2")),
          md[Year == 2018, sum(burn3 == "Burned")] == 25L)
const <- function(x) md[, uniqueN(.SD[[1]]), by = Site, .SDcols = x][, all(V1 == 1L)]
unit_map <- c(veg_cover = "Veg_Cover_General", veg_cover_broad = "Veg_Cover_Fewer_Categories", pasture = "Pasture",
              camera_direction = "Camera_Direction", attractant = "Attractant", ruggedness = "Ruggedness",
              elevation_m = "Elevation", chaparral_100m = "chap", woodland_100m = "wood", grassland_100m = "grass")
per_map <- c(burn = "burn", burn2 = "burn2", burn3 = "burn3", canopy_100m = "Canopy",
             detection_distance_m = "Detection_Distance", camera_height_cm = "Height (cm)", severity_dnbr = "severity")
fac <- grep("^fac", names(md), value = TRUE)
stopifnot(length(fac) == 10L, setequal(names(md), c("Site", "Site_ID", "Year", unit_map, per_map, fac)),
          all(sapply(unit_map, const)), !all(sapply(per_map, const)))
uc <- md[match(cams, Site), ..unit_map]; setnames(uc, names(unit_map))
pc <- md[, c("Site", "Year", per_map), with = FALSE]; setnames(pc, c("unit", "year", paste0("period_", names(per_map))))

long <- array_to_eco(y, site_ids = cams, site_covs = as.data.frame(uc), period = col_yr[keep] - 2015L,
                     obs_covs = list(week_start = obs_start, week_end = obs_end))
pc[, period := year - 2015L][, year := NULL]
long <- merge(long, pc, by = c("unit", "period"), all.x = TRUE, sort = FALSE)
stopifnot(!anyNA(long$period_burn3))
setorder(long, taxon, period, occasion, unit)
stopifnot(nrow(long) == sum(!na) * 9L, uniqueN(long$unit) == 36L, max(long$occasion) == 8L)

taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$vern)
stopifnot(!anyNA(taxa$taxonID))
grp <- fread(file.path(dir, "species_groups.csv"))
taxa[, `:=`(taxon_size_group = grp$Size_Group[match(sp$sci[match(taxon, sp$taxon)], grp$scientificNameStd)],
            taxon_diet_group = grp$Diet_Group[match(sp$sci[match(taxon, sp$taxon)], grp$scientificNameStd)])]
stopifnot(!anyNA(taxa$taxon_size_group))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))

periods <- data.table(period = 1:5, year = 2016:2020, n_occasions = c(8L, 7L, 8L, 8L, 8L),
                      first_week_start = tapply(format(wk_start), col_yr[keep], min),
                      last_week_end = tapply(format(wk_end), col_yr[keep], max),
                      fire = c("pre-fire", "pre-fire", "fire year (River Fire, 27 July 2018)", "post-fire", "post-fire"),
                      n_cameras_operating = sapply(1:5, function(t) uniqueN(long[period == t, unit])))

dataset <- list(
  title = "Camera-trap detections of 9 mammal species at 36 stations on the UC Hopland Research and Extension Center, California, October-November 2016-2020, before and after the 2018 Mendocino Complex megafire",
  creator = "Calhoun, Kendall L.; Goldstein, Benjamin R.; Gaynor, Kaitlyn M.; McInturff, Alex; Solorio, Leonel; Brashares, Justin S.",
  pubDate = "2023", doi = "10.6078/D1W70R", sourceURL = "https://doi.org/10.6078/D1W70R",
  citation = "Calhoun, K. L., Goldstein, B. R., Gaynor, K. M., McInturff, A., Solorio, L., & Brashares, J. S. (2023). Mammalian resilience to megafire in western U.S. woodland savannas [Dataset]. Dryad. https://doi.org/10.6078/D1W70R",
  paperDOI = "10.1002/ecs2.4613",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Weekly detection histories of nine mammal species (black bear, bobcat, coyote, black-tailed deer, gray fox, western gray squirrel, black-tailed jackrabbit, raccoon, striped skunk) at a grid of 36 camera traps 750 m apart on the 5,300-acre UC Hopland Research and Extension Center, Mendocino County, California, over the October-November window of five years (2016-2020). The 2018 River Fire, part of the Mendocino Complex megafire, burned 25 of the 36 stations in July 2018, so the table spans two pre-fire and two post-fire years. Used to estimate the short-term effects of megafire on mammal occupancy and detection with single-species occupancy models.",
  samplingProtocol = "Motion-triggered trail cameras (Reconyx Hyperfire HC600) at the centroid of hexagonal grid cells (750 m spacing), placed at the most suitable location within 50 m of the centroid; photographs classified to species and aggregated into weekly detection / non-detection over October-November of each year (Calhoun et al. 2023).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = "closure assumed within each year's eight-week October-November window; occupancy changes between years (dynamic)",
  geographicCoverage = "UC Hopland Research and Extension Center, Mendocino County, California, USA (about 39.00 N, 123.07 W); no station coordinates deposited",
  temporalCoverage = "2016-10-01/2020-11-27",
  coordinatesCoarsened = NA,
  notes = "Camera-year rows of the deposit are combined into one unit per camera; the five camera-years with no operating week have no rows. burn3 'Unburned Post' (2018 rows) and 'Unburned_Post' (2019-2020) written as one level, Unburned_Post. Deer is Odocoileus hemionus columbianus in the paper, matched at species rank.",
  notShipped = list(
    `fac* dummies` = "ten 0/1 recodings of burn, burn2 and burn3 (shipped as period_burn, period_burn2, period_burn3)",
    `species_recordtable_OctNov_15min.csv` = "raw independent records (15 min); Ground_Squirrel (34 records), Mountain_Lion (16), Pig (39) and Brush_Rabbit (1) have records but no deposited history, and the record table does not reproduce the deposited histories cell for cell (records in weeks set to NA, a few cells differ), so no history is derived for them",
    `cam_op.csv` = "camera operation dates; the deposited NA pattern is the authors' operation record",
    `species_groups.csv rows without a history` = "Ground_Squirrel, Mountain_Lion, Pig (size and diet groups of the nine shipped species are in __taxa)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/calhoun_2023_hopland_mamm_dynocc.R")

stage_dict_row(TABLE,
  description = "Weekly camera-trap detection/non-detection of 9 mammal species at 36 stations on the UC Hopland Research and Extension Center, California, in October-November 2016-2020 (8 weeks a year), spanning the 2018 Mendocino Complex megafire, which burned 25 stations; burn status and severity by station-year, vegetation, canopy and terrain.",
  url = "https://doi.org/10.6078/D1W70R",
  reference = "Calhoun, K. L., Goldstein, B. R., Gaynor, K. M., McInturff, A., Solorio, L., & Brashares, J. S. (2023). Mammalian resilience to megafire in western U.S. woodland savannas. Ecosphere, 14, e4613.",
  doi_paper = "10.1002/ecs2.4613", doi_data = "10.6078/D1W70R",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "No station coordinates deposited. Burn status by station-year as period_ covariates (before-after-control-impact). Four species in the record table without a deposited history are not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy",
  sampling_protocol = "camera_trap", design = "Multi-season (5 years x 8 weekly occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Megafire before-after design; burn status and dNBR severity as period_ covariates.")
