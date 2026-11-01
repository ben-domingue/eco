#!/usr/bin/env Rscript
# Table:  raman_2024_nilgiris_birds_ds
# Source: Zenodo record 10540410, doi:10.5281/zenodo.10540410 (CC0 1.0), published 2024-01-20
#   Raman, T. R. Shankar (2024). Line transect data on birds from Mudumalai and Upper
#   Nilgiris, India. Zenodo.
# Paper:  no journal paper is named; the README cites Raman, T. R. S. (2001), PhD thesis,
#         Indian Institute of Science, and Raman (2003) for methods.
# Data:   00_README.txt (column definitions, methods); 01_niltrans.csv: 19 transect surveys
#         (date, transect, stratum, decimalLatitude/Longitude with 500 m uncertainty; one
#         transect has slightly different coordinates in its two field seasons,
#         duration, start/end time, weather, remarks); 02_nilbirds.csv: 1,491 detections
#         (date, transect, species as recorded and as eBird/Clements name, number,
#         perpendicular distance band, heard/seen/flying, mixed flock); 03_nilnames.csv:
#         118 recorded names mapped to eBird/Clements names.
#         Bands as recorded: 0-5, 5-10, 10-15, 15-20, 20-30, 30-50, 50-100 m (the main
#         scheme), plus 5 detections in odd bands (50-75 -> 50-100; 100-125, 100-150,
#         >100 beyond 100 m; 20-50 ambiguous) and 1 with no band.
#
# Mapping (standard E1-E6, E9 declared stretch: community binned line-transect distance
#   sampling): unit = transect (8; 1,200 m each, variable width), period = visit index of
#   that transect in date order (1..4), occasion = distance band 1..7 with y_raw the band
#   label, taxon = species (eBird/Clements scientific name; "sp." records at genus rank),
#   y = number of individuals recorded in the band, summed over detections, with a 0 row
#   for every species x band at every survey; date per row; obs_duration_min, obs_weather,
#   obs_start_time. distanceBreaks = 0,5,10,15,20,30,50,100 m; detections beyond 100 m
#   (3), in the ambiguous 20-50 band (1) and without a band (1) are not shipped.
#   Survey evidence = sample_table (01_niltrans lists the conducted surveys; every bird
#   row joins to one of them).
#   Coordinates: the source gives transect coordinates with a 500 m uncertainty; the
#   species list includes IUCN Vulnerable taxa (Nilgiri pipit Anthus nilghiriensis, Nilgiri
#   wood-pigeon Columba elphinstonii), so coordinates are coarsened to the 0.1 degree cell in
#   __units (E7). unit_stratum (habitat) is kept.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "raman_2024_nilgiris_birds_ds"
BASE <- "https://zenodo.org/api/records/10540410/files/%s/content"
get <- function(f) fread(download_cached(sprintf(BASE, f), TABLE), encoding = "UTF-8")
download_cached(sprintf(BASE, "00_README.txt"), TABLE)
tr <- get("01_niltrans.csv"); birds <- get("02_nilbirds.csv"); names_tab <- get("03_nilnames.csv")
stopifnot(nrow(tr) == 19, nrow(birds) == 1491, nrow(names_tab) == 118, !anyDuplicated(tr[, .(date, transect)]),
          uniqueN(tr$transect) == 8, all(tr$duration > 0), all(tr$coordinateUncertaintyInMeters == 500))
birds[, date := as.character(date)]; tr[, date := as.character(date)]
stopifnot(nrow(birds[!tr, on = .(date, transect)]) == 0)   # every detection joins a listed survey

# distance bands
BANDS <- c("0-5", "5-10", "10-15", "15-20", "20-30", "30-50", "50-100")
BREAKS <- c(0, 5, 10, 15, 20, 30, 50, 100)
band_raw <- trimws(birds$perpendicularDistanceInMetres)
band <- gsub("–", "-", band_raw)                     # en dash in "5–10"
band[band == "50-75"] <- "50-100"
beyond <- band %in% c("100-125", "100-150", ">100"); ambiguous <- band == "20-50"; noband <- band == ""
stopifnot(sum(beyond) == 3, sum(ambiguous) == 1, sum(noband) == 1, all(band[!(beyond | ambiguous | noband)] %in% BANDS))
birds[, bin := match(band, BANDS)]
cat(sprintf("  dropped %d detections beyond 100 m, %d in the ambiguous 20-50 band, %d without a band\n", sum(beyond), sum(ambiguous), sum(noband)))
det <- birds[!is.na(bin)]
stopifnot(all(det$number >= 1), all(det$number == round(det$number)), nrow(det) == 1491 - 5)

# taxa: eBird/Clements scientific names; "sp." at genus rank
sp <- unique(det[, .(scientificName, eBirdIndiaName)])[order(scientificName)]
stopifnot(!anyDuplicated(sp$scientificName), all(nzchar(sp$scientificName)))
is_sp <- grepl(" sp\\.$", sp$scientificName)
code_of <- function(n) { w <- strsplit(n, " ")[[1]]; if (length(w) >= 2 && w[2] != "sp.") toupper(paste0(substr(w[1], 1, 3), substr(w[2], 1, 3))) else toupper(substr(w[1], 1, 6)) }
sp[, taxon := sapply(scientificName, code_of)]
dups <- sp[, .N, by = taxon][N > 1, taxon]
sp[taxon %in% dups, taxon := paste0(taxon, seq_len(.N)), by = taxon]
stopifnot(!anyDuplicated(sp$taxon))
taxa <- make_taxa(sp$taxon, sp$scientificName, vernacularName = sp$eBirdIndiaName,
                  taxonRank = ifelse(is_sp, "genus", "species"), lookupName = sub(" sp\\.$", "", sp$scientificName))
det <- merge(det, sp[, .(scientificName, taxon)], by = "scientificName")

# surveys -> period = visit index per transect
setorder(tr, transect, date)
tr[, period := seq_len(.N), by = transect]
tr[, unit := transect]
surveys <- tr[, .(unit, period, date, duration, weather, startTime)]
# full community x band grid, then add the counts
grid <- CJ(unit = tr$unit, taxon = sp$taxon, occasion = seq_along(BANDS), unique = TRUE)
grid <- merge(surveys[, .(unit, period, date)], grid, by = "unit", allow.cartesian = TRUE)
cnt <- merge(det, tr[, .(date, transect, period)], by.x = c("date", "transect"), by.y = c("date", "transect"))[
  , .(y = sum(number)), by = .(unit = transect, period, taxon, occasion = bin)]
long <- merge(grid, cnt, by = c("unit", "period", "taxon", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, y := as.integer(y)]
long[, y_raw := paste(BANDS[occasion], "m")]
long <- merge(long, surveys[, .(unit, period, obs_duration_min = duration, obs_weather = weather, obs_start_time = startTime)], by = c("unit", "period"))
long[, unit_stratum := tr$stratum[match(unit, tr$unit)]]
long <- order_eco(long)
stopifnot(nrow(long) == 19 * nrow(sp) * 7, sum(long$y) == sum(det$number),
          long[, .N, by = .(unit, period, occasion)][, all(N == nrow(sp))])

# units: coarsened coordinates (Vulnerable taxa present), stratum
# Teppakkadu is listed with two coordinate pairs (one per field season); they fall in the
# same 0.1-degree cell, and the first survey's pair is used for the cell centre
u <- unique(tr[, .(unit, stratum, decimalLatitude, decimalLongitude)])
stopifnot(nrow(u) == 9, u[, .N, by = unit][N > 1, unit] == "Teppakkadu Dry Deciduous Forest")
cc_all <- coarsen_coords(u$decimalLatitude, u$decimalLongitude)
u[, cell := paste(cc_all$lat, cc_all$lon)]
stopifnot(u[, uniqueN(cell), by = unit][, all(V1 == 1)])
u <- u[!duplicated(unit)]
cc <- coarsen_coords(u$decimalLatitude, u$decimalLongitude)
units <- u[, .(unit, stratum, decimalLatitude = cc$lat, decimalLongitude = cc$lon, coordinateUncertaintyInMeters = cc$uncertainty_m,
               transect_length_m = 1200L)]
periods <- data.table(period = 1:4, note = "visit index of a transect in date order (1995-11 to 1996); dates per row in the core table")

dataset <- list(
  title = "Bird community line-transect distance sampling in seven distance bands, 8 transects x 19 surveys, Mudumalai and Upper Nilgiris, Tamil Nadu, India, 1995-1996",
  creator = "Raman, T. R. Shankar", pubDate = "2024", doi = "10.5281/zenodo.10540410", sourceURL = "https://doi.org/10.5281/zenodo.10540410",
  citation = "Raman, T. R. S. (2024). Line transect data on birds from Mudumalai and Upper Nilgiris, India [Data set]. Zenodo. https://doi.org/10.5281/zenodo.10540410",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Variable-width line-transect surveys of bird communities in 1995-96 in the Mudumalai Wildlife Sanctuary (now Tiger Reserve) and the Upper Nilgiris, Tamil Nadu, India, on a project of the Centre for Ecological Sciences, Indian Institute of Science. Eight 1,200 m transects in eight habitat strata (shola, grassland, wattle, eucalyptus, coffee and teak plantations, dry and moist deciduous forest) were walked one to four times in the first three hours after sunrise; all birds seen or heard were recorded to species with number and perpendicular distance band.",
  samplingProtocol = "1,200 m line transects walked at a slow uniform pace in the first 3 h after sunrise (about 100-120 min); every bird seen or heard recorded with number and perpendicular distance in bands 0-5, 5-10, 10-15, 15-20, 20-30, 30-50, 50-100 m (wider with distance). Methods as in Raman (2001, PhD thesis, IISc) and Raman (2003).",
  samplingProtocolCode = "line_transect", surveyEvidence = "sample_table", effortColumn = "obs_duration_min",
  responseType = "multinomial_cell", distanceBreaks = BREAKS, distanceUnits = "m", transectType = "line",
  unitKind = "site", closure = "occasion (bands of one walk); period = repeat visit",
  geographicCoverage = "Mudumalai Wildlife Sanctuary and Upper Nilgiris, Nilgiris district, Tamil Nadu, India (transect coordinates coarsened to 0.1 degree in __units)",
  temporalCoverage = "1995-11/1996-05",
  coordinatesCoarsened = list(value = TRUE, method = "0.1-degree grid cell centre for all transects; the community includes IUCN Vulnerable taxa (Anthus nilghiriensis, Columba elphinstonii); source coordinates carried a 500 m uncertainty"),
  notes = "Community distance sampling: a 0 row for every species x band at every survey. Heard-only detections are included with their recorded band, as the source does. Transects were visited 1-4 times; period is the visit index, so most units have fewer than 4 periods.",
  notShipped = list(beyond_100m = "3 detections recorded beyond 100 m (bands 100-125, 100-150, >100), outside the band scheme",
                    ambiguous_band = "1 detection in a 20-50 band that spans two scheme bands",
                    no_band = "1 detection with no distance band",
                    per_detection_fields = "heardSeenFlying, leftRight, mixedFlock, location and remarks are per detection and do not survive aggregation to band counts"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/raman_2024_nilgiris_birds_ds.R")
stage_dict_row(TABLE,
  description = sprintf("Line-transect distance sampling counts of %d bird taxa in seven perpendicular-distance bands (0-100 m) on 19 surveys of eight 1,200 m transects across habitat strata in Mudumalai and the Upper Nilgiris, Tamil Nadu, India, 1995-96, with survey duration and weather; transect coordinates coarsened to 0.1 degree.", nrow(sp)),
  url = "https://doi.org/10.5281/zenodo.10540410",
  reference = "Raman, T. R. S. (2001). Community ecology and conservation of mid-elevation tropical rainforest bird communities in the southern Western Ghats, India. PhD thesis, Indian Institute of Science, Bangalore.",
  doi_data = "10.5281/zenodo.10540410",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = distance band, distanceBreaks in metadata; period = visit index (1-4 visits per transect). 5 of 1,491 detections dropped (beyond 100 m, ambiguous or missing band). 'sp.' records at genus rank.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Distance sampling (community, line transect, 7 bands)",
  sampling_protocol = "line_transect", design = "Multi-season (1-4 visits per transect, 1995-96)", realm = "Terrestrial",
  country = "IND", coordinates = "Coarsened (0.1 deg)",
  notes = "Declared stretch: occasion = distance band. 8 transects, below floor. Community table with heard-only detections included.")
