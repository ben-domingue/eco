# Table:  whittington_2015_banff_tracks_comm
# Source: Dryad doi:10.5061/dryad.v4p20 (version 4080), licence CC0 1.0 as shown on Dryad,
#         "Data from: Estimating occupancy using spatially and temporally replicated snow
#         surveys", Whittington J, Heuer K, Hunt B, Hebblewhite M, Lukacs PM.
# Paper:  Whittington, J., Heuer, K., Hunt, B., Hebblewhite, M., & Lukacs, P. M. (2015).
#         Estimating occupancy using spatially and temporally replicated snow surveys.
#         Animal Conservation, 18(1), 92-101. doi:10.1111/acv.12140
# Data:   Banff_2012.csv: one row per species x 1 km transect segment x survey date, winter
#         2011-12 (2011-11-19 to 2012-04-09) in Banff National Park. 7 species (cougar,
#         coyote, deer, fox, lynx, moose, wolverine) x 872 segment-dates = 6,104 rows; 443
#         segments (TransectName x Interval) on 43 transects, nested in 39 hexagonal 100 km2
#         cells (the paper's sites; segments are the spatial replicates). 266 segments were
#         walked once, 177 more than once (up to 14 times): the temporal replicates. Columns:
#         y (track detected 0/1), x.centre / y.centre (segment centre, UTM NAD83 zone 11),
#         DaysSnow (days since snowfall, the sampling window; the carnivore and ungulate
#         values differ because ungulate tracks were aged over a longer window), days.snow
#         (DaysSnow standardised within carnivores / ungulates), and the authors' derived
#         Markov-model columns y.lag, y.lag.i, y.seg, y.seg.lag (functions of y) and use.lag,
#         use.seg.lag (whether the previous record / segment lies within 1.5 km). README
#         lists six species; the file has seven (fox).
# Mapping (standard E1-E5; E9 experimental, multi-scale occupancy):
#   cluster_id = hexagonal cell C01..C39 (the paper's occupancy unit), unit = segment
#   S001..S443 (the spatial replicate), occasion = rank of the survey date within the
#   segment (1 = first walk), date = survey date, taxon = species code, y = 0/1. Community
#   rule: every species has a row at every segment-date (asserted identical survey sets).
#   obs_days_snow = DaysSnow as deposited (varies between the carnivore and ungulate rows of
#   one survey, which E5 allows for obs_). unit_transect, unit_interval (position along the
#   transect), unit_prev_segment_within_1500m = use.seg.lag (constant per segment, asserted),
#   unit_decimalLatitude / unit_decimalLongitude converted in-script from UTM 11N (national
#   park, no CR/EN/VU taxon: kept as published precision, 5 dp). The deposited UTM values are
#   in __units.
#   Survey evidence = row_presence: the file carries a 0 row for every species at every
#   segment-date surveyed; a segment-date absent from the file was not surveyed.
#   NOT shipped: days.snow (a standardisation of obs_days_snow), y.lag, y.lag.i, y.seg,
#   y.seg.lag (derived from y), use.lag (record-order geometry, reconstructible from the
#   coordinates and unit_interval). "deer" is not resolved to species (mule and white-tailed
#   deer both occur; taxonRank genus); "fox" is taken as red fox (the only fox in Banff).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "whittington_2015_banff_tracks_comm"
dir <- download_dryad("10.5061/dryad.v4p20", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "Banff_2012.csv", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
d <- fread(f)
setnames(d, c("species", "transect", "interval", "date", "x", "y_utm", "cell", "segment", "y", "y_lag", "y_lag_i",
              "use_lag", "y_seg", "y_seg_lag", "use_seg_lag", "days_snow", "days_snow_std"))

# ---- source facts -----------------------------------------------------------------------
stopifnot(nrow(d) == 6104, ncol(d) == 17, !anyNA(d),
          setequal(d$species, c("cougar", "coyote", "deer", "fox", "lynx", "moose", "wolverine")),
          d[, .N, by = species][, all(N == 872)],
          uniqueN(d$segment) == 443, uniqueN(d$cell) == 39, uniqueN(d$transect) == 43,
          all(d$y %in% 0:1), !anyDuplicated(d[, .(species, segment, date)]),
          min(d$date) == as.IDate("2011-11-19"), max(d$date) == as.IDate("2012-04-09"))
# the same 872 segment-dates for every species (community survey set)
sv <- unique(d[, .(segment, date)])
stopifnot(nrow(sv) == 872, d[, .N, by = .(segment, date)][, all(N == 7)])
# segment is a key for transect, interval, cell, coordinates and use.seg.lag
stopifnot(d[, uniqueN(paste(transect, interval, cell, x, y_utm, use_seg_lag)), by = segment][, all(V1 == 1)],
          d[, uniqueN(segment), by = .(transect, interval)][, all(V1 == 1)])
# the derived columns are functions of y (not shipped)
stopifnot(all(d$y_lag_i == d$y_lag + 1L),
          d[, .(a = max(y), b = max(y_seg), c = min(y_seg)), by = .(species, segment)][, all(a == b & b == c)])
# days since snow: carnivores share one value per survey, ungulates another
stopifnot(d[species %in% c("deer", "moose"), uniqueN(days_snow), by = .(segment, date)][, all(V1 == 1)],
          d[!species %in% c("deer", "moose"), uniqueN(days_snow), by = .(segment, date)][, all(V1 == 1)],
          all(d$days_snow > 0))
cat(sprintf("  %d rows, %d species x %d segment-dates, %d segments in %d cells; detections: %s\n",
            nrow(d), uniqueN(d$species), nrow(sv), uniqueN(d$segment), uniqueN(d$cell),
            paste(d[, sum(y), by = species][order(species)][, paste0(species, "=", V1)], collapse = " ")))

# ---- taxa --------------------------------------------------------------------------------
species <- data.table(
  species = c("cougar", "coyote", "deer", "fox", "lynx", "moose", "wolverine"),
  taxon = c("PUMCON", "CANLAT", "ODOSPP", "VULVUL", "LYNCAN", "ALCALC", "GULGUL"),
  scientificName = c("Puma concolor", "Canis latrans", "Odocoileus", "Vulpes vulpes", "Lynx canadensis", "Alces alces", "Gulo gulo"),
  vernacularName = c("cougar", "coyote", "deer (mule or white-tailed, not distinguished)", "red fox", "Canada lynx", "moose", "wolverine"),
  taxonRank = c("species", "species", "genus", "species", "species", "species", "species"),
  taxon_group = c("carnivore", "carnivore", "ungulate", "carnivore", "carnivore", "ungulate", "carnivore"))
taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$vernacularName,
                  taxonRank = species$taxonRank, taxon_group = species$taxon_group,
                  taxon_sourceName = species$species)
stopifnot(!anyNA(taxa$taxonID))

# ---- units: segments, with UTM 11N -> WGS84 ---------------------------------------------
utm_to_ll <- function(E, N, zone = 11) {
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  lon0 <- (zone - 1) * 6 - 180 + 3
  list(lat = lat * 180 / pi, lon = lon0 + lon * 180 / pi)
}
seg <- unique(d[, .(segment, transect, interval, cell, x, y_utm, use_seg_lag)])
stopifnot(nrow(seg) == 443, !anyDuplicated(seg$segment))
ll <- utm_to_ll(seg$x, seg$y_utm)
seg[, `:=`(lat = round(ll$lat, 5), lon = round(ll$lon, 5))]
stopifnot(all(seg$lat > 50.6 & seg$lat < 52.0), all(seg$lon > -117.2 & seg$lon < -115.0))   # Banff National Park
seg[, `:=`(unit = sprintf("S%03d", segment), cluster_id = sprintf("C%02d", cell))]
n_visits <- sv[, .N, by = segment]
seg <- merge(seg, n_visits[, .(segment, n_surveys = N)], by = "segment")
units <- seg[order(unit), .(unit, cluster_id, transect, interval, utm_easting = x, utm_northing = y_utm,
                            decimalLatitude = lat, decimalLongitude = lon, prev_segment_within_1500m = use_seg_lag, n_surveys)]

# ---- long table --------------------------------------------------------------------------
sv <- sv[order(segment, date)][, occasion := seq_len(.N), by = segment]
stopifnot(max(sv$occasion) == 14, sum(sv$occasion == 1) == 443)
long <- merge(d[, .(segment, date, species, y, days_snow)], sv, by = c("segment", "date"))
long <- merge(long, species[, .(species, taxon)], by = "species")
long <- merge(long, seg[, .(segment, unit, cluster_id, transect, interval, lat, lon, use_seg_lag)], by = "segment")
long <- long[, .(unit, taxon, y = as.integer(y), occasion, date = format(date), cluster_id,
                 unit_transect = transect, unit_interval = as.integer(interval),
                 unit_prev_segment_within_1500m = as.integer(use_seg_lag),
                 unit_decimalLatitude = lat, unit_decimalLongitude = lon,
                 obs_days_snow = days_snow)]
long <- order_eco(long)
stopifnot(nrow(long) == 6104, uniqueN(long$unit) == 443, uniqueN(long$taxon) == 7, uniqueN(long$cluster_id) == 39,
          sum(long$y) == sum(d$y), long[, .N, by = .(unit, occasion)][, all(N == 7)])

dataset <- list(
  title = "Snow-track detections of seven mammals on 1 km transect segments nested in 100 km2 cells, Banff National Park, winter 2011-12 (spatially and temporally replicated occupancy dataset)",
  creator = "Whittington, Jesse; Heuer, Karsten; Hunt, Barb; Hebblewhite, Mark; Lukacs, Paul M.",
  pubDate = "2014", doi = "10.5061/dryad.v4p20", sourceURL = "https://doi.org/10.5061/dryad.v4p20",
  paperDOI = "10.1111/acv.12140",
  citation = "Whittington, J., Heuer, K., Hunt, B., Hebblewhite, M., & Lukacs, P. M. (2014). Data from: Estimating occupancy using spatially and temporally replicated snow surveys [Data set]. Dryad. https://doi.org/10.5061/dryad.v4p20",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Snow-tracking surveys for cougar, coyote, deer, red fox, Canada lynx, moose and wolverine in Banff National Park between 19 November 2011 and 9 April 2012. Transects were walked on snow and split into 1 km segments; segments are nested in 100 km2 hexagonal cells, the occupancy unit of the paper, so segments are spatial replicates and repeat walks of a segment (266 segments once, 177 up to 14 times) are temporal replicates. Each row is one species on one segment on one date, with the number of days since the last snowfall (the track-accumulation window, which the authors set longer for ungulates than for carnivores), the segment's centre coordinates and its position along the transect. The authors fitted spatially replicated, Markovian-detection occupancy models to these data; the lag columns they derived from the detections are not shipped.",
  samplingProtocol = "Snow-track surveys on skis or foot along transects in Banff National Park, divided into 1 km segments (intervals); tracks identified to species and recorded as present or absent per segment; days since snowfall recorded per survey (longer window for ungulates). Segments nested in 100 km2 hexagonal cells; many segments resurveyed on later dates.",
  samplingProtocolCode = "snow_track", responseType = "detection", unitKind = "site",
  closure = "period (one winter); the authors treat the 100 km2 cell as the occupancy unit and the segment as a spatial replicate, with a Markovian dependence between consecutive segments",
  surveyEvidence = "row_presence",
  surveyEvidenceNote = "The deposit is a long table with a 0 or 1 for every one of seven species at every surveyed segment-date (asserted: 872 segment-dates x 7); a segment-date not in the file was not surveyed.",
  temporalCoverage = "2011-11-19/2012-04-09",
  geographicCoverage = "Banff National Park, Alberta, Canada; 39 hexagonal 100 km2 cells, 43 transects (segment centres 50.6-52.0 N, 117.2-115.0 W)",
  crs = "EPSG:4326 (converted in-script from the deposited UTM NAD83 zone 11 segment centres, which are kept in __units)",
  coordinatesCoarsened = list(value = FALSE, method = "segment centres as deposited (UTM 11N -> WGS84, 5 dp); no taxon is IUCN CR/EN/VU (wolverine, lynx, cougar, coyote, red fox, moose, deer all LC) and the sites are inside a national park"),
  designNote = "Experimental list of E9 (multi-scale occupancy): cluster_id = 100 km2 cell is the authors' occupancy unit (psi), unit = 1 km segment the spatial replicate, occasion = repeat walk of the segment (temporal replicate). A single-scale reading (unit = segment) is also valid. Transects cross up to four cells; unit_interval orders the segments along a transect for the authors' Markovian detection model, with unit_prev_segment_within_1500m flagging whether the previous segment is adjacent.",
  notes = "obs_days_snow differs between the carnivore and ungulate rows of the same survey (the authors aged ungulate tracks over a longer window); E5 allows obs_ covariates to vary across taxa within a survey. 'deer' is not resolved to species (genus Odocoileus); 'fox' is taken as red fox, the only fox in Banff. The README lists six species; the file has seven.",
  notShipped = list(days.snow = "DaysSnow standardised within carnivores and ungulates; obs_days_snow is the raw value",
                    `y.lag, y.lag.i, y.seg, y.seg.lag` = "the authors' lag indicators, deterministic functions of y and the segment order",
                    use.lag = "whether the previous data record lies within 1.5 km; reconstructible from the coordinates and unit_interval (the segment-level use.seg.lag is shipped)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, units = units, script = "data/whittington_2015_banff_tracks_comm.R")

stage_dict_row(TABLE,
  description = "Snow-track detections (0/1) of cougar, coyote, deer, red fox, Canada lynx, moose and wolverine on 443 one-km transect segments nested in 39 hexagonal 100 km2 cells in Banff National Park, winter 2011-12, with repeat walks of 177 segments; days since snowfall per survey, segment coordinates and transect position. The authors' spatially and temporally replicated occupancy input.",
  url = "https://doi.org/10.5061/dryad.v4p20",
  reference = "Whittington, J., Heuer, K., Hunt, B., Hebblewhite, M., & Lukacs, P. M. (2015). Estimating occupancy using spatially and temporally replicated snow surveys. Animal Conservation, 18(1), 92-101.",
  doi_paper = "10.1111/acv.12140", doi_data = "10.5061/dryad.v4p20",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental (E9): multi-scale via cluster_id = 100 km2 cell, unit = 1 km segment, occasion = repeat walk. Community rule holds (7 species x 872 segment-dates). Days since snow differs between carnivore and ungulate rows. Fetched as the Dryad version zip.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-scale: cell > segment > repeat walk; Markovian detection)",
  sampling_protocol = "snow_track", design = "Single-season (one winter; 443 spatial replicates in 39 cells, 1-14 temporal replicates)",
  realm = "Terrestrial", country = "Canada", coordinates = "As published (UTM 11N converted to decimal degrees)",
  notes = "Experimental (E9): cluster_id = cell is the authors' occupancy unit, unit = segment the spatial replicate. Lag columns derived from y not shipped.",
  status = "tagged")
