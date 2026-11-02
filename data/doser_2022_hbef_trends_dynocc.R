#!/usr/bin/env Rscript
# Table:  doser_2022_hbef_trends_dynocc
# Source: spOccupancy package dataset hbefTrends (GPL >= 3; CRAN spOccupancy 0.8.2, data/
#         hbefTrends.rda fetched from github.com/doserjef/spOccupancy, main branch). The
#         package's subset of the Hubbard Brook Valleywide Bird Survey (Rodenhouse & Sillett
#         2019, EDI doi:10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217, accessed by the package
#         authors 2021-09-07; the EDI deposit itself sits behind an access wall for this
#         builder, queue row "Valleywide Bird Survey"), as analysed in Doser, Leuenberger,
#         Sillett, Hallworth & Zipkin (2022, MEE, doi:10.1111/2041-210X.13811) and used in the
#         spOccupancy vignettes (Doser, Finley, Kery & Zipkin 2022, MEE, doi:10.1111/2041-210X.13897).
# Data:   hbefTrends is a list: y[12 species, 373 sites, 9 years (2010-2018), 3 replicates] of
#         0/1/NA; occ.covs$elev (373), occ.covs$years (373 x 9, the calendar year),
#         occ.covs$site.effect (1:373); det.covs$day and det.covs$tod (373 x 9 x 3: day of year
#         and time of day in minutes after midnight); coords (373 x 2, UTM zone 19 NAD83,
#         Easting/Northing). Site dimnames are the survey's plot numbers 1..400 with 27 gaps.
#         The package's hbef2015 object is exactly the 2015 slice of this array (asserted), so
#         it is not shipped as a second table: filter period 6 (2015).
# Mapping (standard E1-E5, E9 core: dynamic community occupancy): unit = plot number, taxon =
#   AOU alpha code, period = year 1..9 (calendar year in __periods), occasion = replicate 1..3,
#   y = 0/1, date = ISO date from year and day of year, obs_day_of_year, obs_time_of_day_min;
#   unit_elevation_m, unit_decimalLatitude / unit_decimalLongitude converted in-script from UTM
#   19N (NAD83 ~ WGS84 at this precision), unit_utm19_easting_m / _northing_m as published.
#   surveyEvidence = deposited_matrix: a plot-year-replicate is a survey iff y is not NA (the NA
#   pattern is identical across the 12 species). 45 cells carry a survey day and time but no
#   detection data; they are not surveyed here (no observation exists) and are recorded.
#   Not shipped: occ.covs$site.effect (an index), hbefElev (a prediction grid, not detection data).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "doser_2022_hbef_trends_dynocc"
CACHE <- "doser_2022_spoccupancy"   # shared with doser_2022_neon2015_removal

rda <- download_cached("https://raw.githubusercontent.com/doserjef/spOccupancy/main/data/hbefTrends.rda", CACHE, "hbefTrends.rda")
rda15 <- download_cached("https://raw.githubusercontent.com/doserjef/spOccupancy/main/data/hbef2015.rda", CACHE, "hbef2015.rda")
e <- new.env(); load(rda, e); load(rda15, e)
h <- e$hbefTrends; h15 <- e$hbef2015
y <- h$y
stopifnot(dim(y) == c(12, 373, 9, 3), identical(dimnames(y)[[3]], as.character(2010:2018)), length(dimnames(y)[[2]]) == 373)
stopifnot(all(y[!is.na(y)] %in% 0:1), sum(is.na(y)) == 15612)
na1 <- is.na(y[1, , , ]); stopifnot(all(apply(is.na(y), 1, identical, na1)), sum(na1) == 1301)
stopifnot(identical(y[, , "2015", ], h15$y), identical(h$coords, h15$coords))           # hbef2015 is the 2015 slice
stopifnot(all(apply(h$occ.covs$years, 2, function(v) uniqueN(v) == 1)), identical(h$occ.covs$years[1, ], 2010:2018))
stopifnot(identical(h$occ.covs$site.effect, 1:373), length(h$occ.covs$elev) == 373, all(h$occ.covs$elev > 239 & h$occ.covs$elev < 933))
day <- h$det.covs$day; tod <- h$det.covs$tod
stopifnot(dim(day) == c(373, 9, 3), dim(tod) == c(373, 9, 3), all(is.na(day) == is.na(tod)))
stopifnot(!any(!na1 & is.na(day)), sum(na1 & !is.na(day)) == 45)                        # every survey has covariates; 45 covariate-only cells
stopifnot(all(day[!is.na(day)] >= 138 & day[!is.na(day)] <= 188), all(tod[!is.na(tod)] >= 295 & tod[!is.na(tod)] <= 630))
sites <- dimnames(y)[[2]]; stopifnot(!anyDuplicated(sites), !"36" %in% sites, max(as.integer(sites)) == 400)
stopifnot(nrow(h$coords) == 373, !anyDuplicated(h$coords), all(h$coords[, 1] > 275990 & h$coords[, 1] < 283010),
          all(h$coords[, 2] > 4866290 & h$coords[, 2] < 4871210))
cat(sprintf("  12 species x 373 plots x 9 years x 3 replicates; %d surveyed plot-year-replicates; %d plot-years never surveyed\n",
            sum(!na1), sum(apply(na1, c(1, 2), all))))

# UTM 19N (NAD83) -> lat/lon; NAD83 and WGS84 differ by < 1 m here
utm_to_ll <- function(E, N, zone = 19) {
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
ll <- utm_to_ll(h$coords[, 1], h$coords[, 2])
stopifnot(all(ll$lat > 43.9 & ll$lat < 44.0), all(ll$lon > -71.8 & ll$lon < -71.68))   # Hubbard Brook valley

# array for the converter: sites x (year x replicate) x species, period = year per column
Y <- aperm(y, c(2, 4, 3, 1))                       # 373 x 3 x 9 x 12: replicate fastest, then year
dim(Y) <- c(373, 27, 12); dimnames(Y) <- list(sites, NULL, dimnames(y)[[1]])
period <- rep(1:9, each = 3)                       # column j = replicate (j - 1) %% 3 + 1 of year (j - 1) %/% 3 + 1
flat <- function(a) { a <- aperm(a, c(1, 3, 2)); dim(a) <- c(373, 27); a }
obs_day <- flat(day); obs_tod <- flat(tod)
stopifnot(identical(Y[, 2, "OVEN"], y["OVEN", , 1, 2]), identical(Y[, 27, "REVI"], y["REVI", , 9, 3]))
stopifnot(isTRUE(all.equal(unname(obs_day[, 5]), unname(day[, 2, 2]))), isTRUE(all.equal(unname(obs_tod[, 27]), unname(tod[, 9, 3]))))
site_covs <- data.frame(elevation_m = round(h$occ.covs$elev, 2), decimalLatitude = round(ll$lat, 5), decimalLongitude = round(ll$lon, 5),
                        utm19_easting_m = round(h$coords[, 1], 2), utm19_northing_m = round(h$coords[, 2], 2))
long <- array_to_eco(Y, site_ids = sites, site_covs = site_covs, period = period,
                     obs_covs = list(day_of_year = obs_day, time_of_day_min = obs_tod))
long[, date := format(as.Date(obs_day_of_year - 1, origin = paste0(2009 + period, "-01-01")))]
long <- order_eco(long)
stopifnot(nrow(long) == 12 * sum(!na1), uniqueN(long$unit) == 373, uniqueN(long$taxon) == 12, max(long$period) == 9, max(long$occasion) == 3,
          !anyNA(long$obs_day_of_year), !anyNA(long$date), all(grepl("^201[0-8]-0[5-7]-", long$date)))
stopifnot(sum(long$y) == sum(y, na.rm = TRUE))
periods <- data.table(period = 1:9, year = 2010:2018,
                      plots_surveyed = sapply(1:9, function(t) sum(!apply(na1[, t, ], 1, all))),
                      plot_replicates_surveyed = sapply(1:9, function(t) sum(!na1[, t, ])))

codes <- fread("data/aux/bird_alpha_codes.csv")
sp <- dimnames(y)[[1]]; stopifnot(all(sp %in% codes$code))
taxa <- make_taxa(sp, codes$scientificName[match(sp, codes$code)], vernacularName = codes$commonName[match(sp, codes$code)])
dataset <- list(
  title = "Hubbard Brook Valleywide Bird Survey 2010-2018: detection/non-detection of 12 foliage-gleaning species on 3 replicate point counts at 373 plots (spOccupancy::hbefTrends)",
  creator = "Rodenhouse, Nicholas L.; Sillett, T. Scott (Hubbard Brook Valleywide Bird Survey); Doser, Jeffrey W. (spOccupancy subset)",
  pubDate = "2022", sourceURL = "https://cran.r-project.org/package=spOccupancy",
  citation = "Doser, J. W., Leuenberger, W., Sillett, T. S., Hallworth, M. T. & Zipkin, E. F. (2022). Integrated community occupancy models: A framework to assess occurrence and biodiversity dynamics using multiple data sources. Methods in Ecology and Evolution 13, 919-932. https://doi.org/10.1111/2041-210X.13811. Data: spOccupancy::hbefTrends (Doser, Finley, Kery & Zipkin 2022, MEE 13, 1670-1678, https://doi.org/10.1111/2041-210X.13897), from Rodenhouse, N. & Sillett, S. (2019) Valleywide Bird Survey, Hubbard Brook Experimental Forest, 1999-2016 (ongoing) ver 3, Environmental Data Initiative, https://doi.org/10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217.",
  paperDOI = "10.1111/2041-210X.13811",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook dynamic community occupancy dataset: 12 foliage-gleaning songbirds detected or not on up to three 10-minute, 100 m radius point counts per year at 373 plots in the Hubbard Brook Experimental Forest, New Hampshire, 2010-2018, with plot elevation and coordinates, survey day of year and time of day. The spOccupancy package's hbef2015 object is the 2015 slice of this array (period 6) and is not shipped separately.",
  samplingProtocol = "10-minute point counts with a 100 m detection radius, up to three replicates per plot per breeding season (late May to early July); species detection/non-detection per count.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "period",
  geographicCoverage = "Hubbard Brook Experimental Forest, White Mountains, New Hampshire, USA (373 plots on a valleywide grid)",
  temporalCoverage = "2010/2018",
  crs = "EPSG:4269 (NAD83) UTM zone 19N as published in unit_utm19_*; unit_decimalLatitude/Longitude converted in-script, NAD83 ~ WGS84",
  coordinatesCoarsened = list(value = FALSE, method = "as published in spOccupancy (plot coordinates to the metre); common species, none IUCN CR/EN/VU"),
  effortColumn = NA,
  notes = "period = year index (2010 = 1); occasion = replicate within year. 45 plot-year-replicates have a survey day and time but no detection data in the package array and are not surveyed here. Site ids are the survey's plot numbers (1-400, 27 unused). hbef2015 (the package's single-season example) is identical to period 6 of this table.",
  notShipped = list(hbef2015 = "the package's 2015 single-season object: identical to the 2015 slice of hbefTrends (asserted), so filter period = 6 instead of a duplicate table",
                    hbefElev = "a 46,090-cell elevation grid for prediction, not detection data",
                    site.effect = "an integer site index", covariate_only_cells = "45 plot-year-replicates with day and time but NA detections"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/doser_2022_hbef_trends_dynocc.R")
stage_dict_row(TABLE,
  description = "Detection/non-detection of 12 foliage-gleaning bird species on up to 3 replicate 10-minute point counts per year at 373 Hubbard Brook plots, 2010-2018, with elevation, coordinates (UTM 19N and WGS84), survey day and time (spOccupancy::hbefTrends; Doser et al. 2022 integrated community occupancy data). The package's hbef2015 is the 2015 slice.",
  url = "https://cran.r-project.org/package=spOccupancy",
  reference = "Doser, J. W., Leuenberger, W., Sillett, T. S., Hallworth, M. T. & Zipkin, E. F. (2022). Integrated community occupancy models. Methods in Ecology and Evolution 13, 919-932. Package: Doser, Finley, Kery & Zipkin (2022) MEE 13, 1670-1678.",
  doi_paper = "10.1111/2041-210X.13811", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package (spOccupancy); the underlying EDI deposit (edi.348) is behind an access wall for the builder. 45 covariate-only cells not surveyed. hbef2015 not shipped separately (identical 2015 slice).",
  source_via = "R package (spOccupancy, via GitHub source)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (9 years x up to 3 replicates)", realm = "Terrestrial", country = "USA",
  coordinates = "As published (plot coordinates, UTM 19N and WGS84)", notes = "Textbook dataset (spOccupancy). Unbalanced: 273 plot-years unsurveyed, 353 partial.")
