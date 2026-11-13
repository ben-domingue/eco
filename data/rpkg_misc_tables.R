#!/usr/bin/env Rscript
# Tables: mcclintock_2013_bobcat_cc, augustine_2018_bobcat_scr, naamp_2001_delaware_frog_calls,
#         naamp_2007_massachusetts_peeper_calls, royle_2004_ovenbird_removal
# Sources: example datasets of two CRAN packages, loaded from their pinned source tarballs
#   without the packages, Version and License asserted from DESCRIPTION; the package licence
#   governs (the data have none of their own; NAAMP data are a USGS programme's):
#     multimark 2.1.7 (McClintock), GPL-2: bobcat, bobcatSCR
#     unmarked 1.5.2 (Fiske, Chandler, Kellner et al.), GPL (>= 3): frogs, masspcru, ovendata
# Data (help pages read in full):
#   bobcat: 46 observed encounter histories over 8 occasions from single-camera stations; 0 no
#     detection, 1 left flank, 2 right flank; no animal was ever photographed on both sides at
#     once, so a left-only and a right-only history may be the same bobcat (partial identity).
#     McClintock, Conn, Alonso & Crooks (2013), Ecology 94, 1464-1471, doi:10.1890/12-1613.1.
#     Place and dates not in the package.
#   bobcatSCR: 42 observed histories x 30 single-camera stations x 187 occasions, same codes;
#     the first 15 animals are known from both sides (captured for telemetry before the survey),
#     4 of them photographed on both flanks; a trap x occasion operation matrix (all 1) and trap
#     coordinates 'modified by projecting onto a regular rectangular grid' (0.65 km cells), km
#     values consistent with UTM 11N (centroid about 33.6 N, 117.8 W: Orange County, California;
#     inferred, not stated). From R package SPIM; Augustine et al. (2017/2018), spatial
#     capture-recapture with partial identity. Column order trap-major (help page; asserted
#     against the operation matrix).
#   frogs: 2001 Delaware North American Amphibian Monitoring Program: calling index (0-3) of
#     spring peeper (Pseudacris crucifer) and upland chorus frog (P. feriarum) at 130 stops
#     (13 routes x 10 stops) on up to 3 visits; NA = visit not made (same cells for both
#     species, asserted); per-visit minutes after sunset, wind, sky and temperature.
#   masspcru: Massachusetts NAAMP 2001-2007, spring peeper calling index per stop visit in long
#     format (3,216 visits, 4 without an index, 280 stops, up to 4 visits per stop-year), Julian date, minutes after
#     sunset, temperature (NA in 108 visits).
#   ovendata: Ovenbird removal counts in 4 time intervals at 70 sites (codes CAT003...), with
#     site covariates ufc and trba (understory foliage cover and tree basal area, as named in
#     unmarked's removal examples). Royle (2004), Animal Biodiversity and Conservation 27,
#     375-386. Place, year and interval lengths not in the package.
# Mapping:
#   bobcats: responseType state (E2 partial identity: 'a design that codes which side was seen on
#     each encounter (multimark's 0 to 4) is state'), stateCodes 0/1/2, unitKind individual,
#     unit_identity both / left / right (the sides from which the unit's identity is known:
#     both for the 15 telemetry animals, otherwise the one side photographed). Survey evidence:
#     bobcat inferred (every occasion surveyed), bobcatSCR effort_table (operation matrix).
#   NAAMP: ordinal calling index (stateCodes as carter_2021_louisiana_lamp_calls), unit = stop,
#     cluster_id = route, occasion = visit (Delaware: the package's visit column; Massachusetts:
#     visits ordered by date within stop and year, period = year); taxonInclusion target (the
#     package keeps these species of the NAAMP list).
#   ovenbird: multinomial_cell removal, occasion = interval 1-4, one visit per site.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/rpkg_misc_tables.R"
PKG <- list(multimark = list(ver = "2.1.7", lic = "GPL-2", spdx = "GPL-2.0-only", url = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"),
            unmarked = list(ver = "1.5.2", lic = "GPL (>= 3)", spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"))
pkg_env <- function(table, pkg, file) {
  tb <- sprintf("%s_%s.tar.gz", pkg, PKG[[pkg]]$ver)
  f <- file.path(RAW_DIR, table, tb)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", tb), table, tb), silent = TRUE)
    if (inherits(ok, "try-error")) download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", pkg, tb), table, tb)
  }
  ex <- file.path(RAW_DIR, table, pkg)
  if (!dir.exists(ex)) untar(f, files = c(file.path(pkg, "DESCRIPTION"), file.path(pkg, "data")), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == PKG[[pkg]]$ver, desc[, "License"] == PKG[[pkg]]$lic)
  e <- new.env(); load(file.path(ex, "data", file), envir = e); e
}
lic <- function(pkg) list(spdx = PKG[[pkg]]$spdx, url = PKG[[pkg]]$url)
dictc <- function(pkg) list(url = sprintf("https://cran.r-project.org/package=%s", pkg),
  original_license = sprintf("%s (%s R package; the data have no licence of their own)", PKG[[pkg]]$lic, pkg),
  derived_license = PKG[[pkg]]$spdx, source_via = sprintf("CRAN source tarball %s %s", pkg, PKG[[pkg]]$ver))
MMCITE <- function(ds) sprintf("McClintock, B. T. (2025). multimark: Capture-mark-recapture analysis using multiple non-invasive marks (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=multimark", PKG$multimark$ver, ds)
UMCITE <- function(ds) sprintf("Fiske, I., Chandler, R., Kellner, K., et al. (2026). unmarked: Models for data from unmarked animals (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=unmarked", PKG$unmarked$ver, ds)
SIDE <- list(`0` = "not photographed", `1` = "photographed, left flank", `2` = "photographed, right flank")
side_of <- function(r) { s <- unique(r[r > 0]); if (length(s) == 1L) c("left", "right")[s] else "both" }

# =========================================================================================
# 1. Bobcats, non-spatial, 8 occasions (McClintock et al. 2013)
# =========================================================================================
TABLE <- "mcclintock_2013_bobcat_cc"
b <- pkg_env(TABLE, "multimark", "bobcat.RData")$bobcat
stopifnot(identical(dim(b), c(46L, 8L)), all(b %in% 0:2), all(rowSums(b) > 0),
          all(apply(b, 1, function(r) length(unique(r[r > 0])) == 1L)),                 # one side per history
          identical(as.vector(table(apply(b, 1, side_of))), c(23L, 23L)))
ids <- sprintf("B%02d", 1:46)
long <- data.table(unit = rep(ids, times = 8), occasion = rep(1:8, each = 46), y = as.integer(b),
                   unit_identity = rep(apply(b, 1, side_of), times = 8))
long <- order_eco(long[, .(unit, taxon = "LYNRUF", y, occasion, unit_identity)])
taxa <- make_taxa("LYNRUF", "Lynx rufus", vernacularName = "Bobcat", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Bilateral camera photo-identification histories of bobcats (46 left- or right-flank histories, 8 occasions)",
  creator = "McClintock, Brett T.; Conn, Paul B.; Alonso, Robert S.; Crooks, Kevin R. (data; distributed in the multimark R package)",
  pubDate = "2013", sourceURL = "https://cran.r-project.org/package=multimark", citation = MMCITE("bobcat"),
  paperDOI = "10.1890/12-1613.1", intellectualRights = lic("multimark"),
  abstract = "Bobcats (Lynx rufus) photographed at single-camera stations over 8 sampling occasions and identified from the pelage pattern of one flank. Because a single camera sees one side, left- and right-flank photographs of the same animal cannot be matched: the 46 histories (23 left, 23 right) are observed histories, and a left and a right history may belong to one bobcat. The example data of McClintock et al. (2013) for integrated bilateral photo-ID models, as distributed in multimark (bobcat). One row per history x occasion, y = the side photographed.",
  samplingProtocol = "Single-camera stations; bobcats identified from flank pelage patterns; 8 sampling occasions (details in McClintock et al. 2013).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort in the package; every one of the 8 occasions is taken as a survey of every history.",
  responseType = "state", stateCodes = SIDE, unitKind = "individual", closure = "closed", closureNote = "single closed session of 8 occasions",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Not stated in the package (McClintock et al. 2013); no coordinates", temporalCoverage = "not stated in the package (before 2013)",
  coordinatesCoarsened = NA,
  designNote = "Partial identity (E2): each unit is an observed one-sided history; unit_identity = left or right (no bobcat was photographed on both sides). A left and a right unit may be the same animal; models for partial identity (multimark data.type 'never') reconcile them.",
  notes = "Unit ids are row numbers. augustine_2018_bobcat_scr is spatial bobcat data from the same research group; whether the animals overlap is not stated.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Bilateral photo-ID capture histories of bobcats at single-camera stations: 46 one-sided (left or right flank) histories over 8 occasions, with partial identity (multimark::bobcat; McClintock et al. 2013).",
  reference = "McClintock, B. T., Conn, P. B., Alonso, R. S., & Crooks, K. R. (2013). Integrated modeling of bilateral photo-identification data in mark-recapture analyses. Ecology, 94, 1464-1471.",
  doi_paper = "10.1890/12-1613.1", doi_data = "", notes = "multimark package data (GPL-2). Partial identity: unit_identity, state = side photographed."), dictc("multimark")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Closed capture-recapture (partial identity)",
  sampling_protocol = "camera_trap", design = "Single-season (8 occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the multimark R package. Partial identity (left/right flanks).")

# =========================================================================================
# 2. Bobcats, spatial, 30 cameras x 187 occasions (Augustine et al.)
# =========================================================================================
TABLE <- "augustine_2018_bobcat_scr"
s <- pkg_env(TABLE, "multimark", "bobcatSCR.RData")$bobcatSCR
E <- s$Enc.Mat; TC <- s$trapCoords; op <- TC[, -(1:2)]
stopifnot(identical(dim(E), c(42L, 5610L)), identical(dim(TC), c(30L, 189L)), all(E %in% 0:2), sum(E > 0) == 90L,
          all(op == 1), all(rowSums(E) > 0))
d <- which(E > 0, arr.ind = TRUE)
stopifnot(all(op[cbind((d[, 2] - 1L) %/% 187L + 1L, (d[, 2] - 1L) %% 187L + 1L)] == 1L))
ident <- apply(E, 1, side_of); ident[1:15] <- "both"
stopifnot(sum(apply(E[1:15, ], 1, side_of) == "both") == 4L, all(apply(E[16:42, ], 1, side_of) %in% c("left", "right")))
long <- CJ(i = 1:42, k = 1:30, occasion = 1:187)
long[, `:=`(y = as.integer(E[cbind(i, (k - 1L) * 187L + occasion)]), unit = sprintf("B%02d", i), trap = sprintf("C%02d", k), unit_identity = ident[i])]
stopifnot(nrow(long) == 42L * 30L * 187L, sum(long$y > 0) == 90L)
long <- order_eco(long[, .(unit, taxon = "LYNRUF", y, trap, occasion, unit_identity)])
traps <- data.table(trap = sprintf("C%02d", 1:30), x = TC[, 1] * 1000, y = TC[, 2] * 1000, n_occasions_used = 187L)
dataset <- list(
  title = "Spatial capture-recapture of bobcats with partial identity: 42 histories at 30 single-camera stations over 187 occasions",
  creator = "Augustine, Ben C.; Royle, J. Andrew; Kelly, Marcella J.; Satter, Christopher B.; Alonso, Robert S.; Boydston, Erin E.; Crooks, Kevin R. (data; distributed via SPIM in the multimark R package)",
  pubDate = "2018", sourceURL = "https://cran.r-project.org/package=multimark", citation = MMCITE("bobcatSCR"), paperDOI = "10.1214/17-AOAS1091",
  intellectualRights = lic("multimark"),
  abstract = "Bobcats (Lynx rufus) photographed at 30 single-camera stations over 187 daily occasions and identified from flank pelage patterns, the example data of Augustine et al.'s spatial capture-recapture with partial identity (from R package SPIM, as distributed in multimark: bobcatSCR). Fifteen bobcats were captured for telemetry before the survey, so both of their flanks are known; for the other 27 histories only the side photographed is known, so a left and a right history may be one animal. One row per history x station x occasion, y = the side photographed.",
  samplingProtocol = "Single-camera stations operated over 187 occasions; bobcats identified from flank pelage patterns; 15 previously collared animals known from both sides.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The package gives a station x occasion operation matrix; every station operated on every occasion (asserted), so every history has rows at all 30 stations x 187 occasions.",
  responseType = "state", stateCodes = SIDE, unitKind = "individual", closure = "closed", closureNote = "single closed session of 187 occasions",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Not stated in the package; the station coordinates (km) are consistent with UTM 11N around 33.6 N, 117.8 W (Orange County, California; inferred); __traps x, y in metres as distributed",
  temporalCoverage = "not stated in the package", crs = "km grid as distributed (consistent with UTM 11N; snapped by the multimark authors to 0.65 km cells), shipped in metres",
  coordinatesCoarsened = list(value = FALSE, method = "station positions as distributed (already snapped to a 0.65 km grid by the multimark authors); Lynx rufus is IUCN Least Concern"),
  designNote = "Experimental list of E9 (SCR, trap key + __traps) with partial identity (E2): unit_identity = both for the 15 telemetry bobcats (4 of them photographed on both flanks), left or right for the rest.",
  notes = "Enc.Mat columns are trap-major (the first 187 columns are station 1; asserted against the operation matrix). Station positions were projected onto a regular grid by the multimark authors, so inter-station distances are approximate. Unit ids are row numbers (B01-B15 are the known animals). Source paper: Augustine, B. C., Royle, J. A., Kelly, M. J., et al., Spatial capture-recapture with partial identity: an application to camera traps (bioRxiv doi:10.1101/056804; published 2018 in the Annals of Applied Statistics).",
  notShipped = list(studyArea = "habitat grid of the state space (a model input)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Spatial capture-recapture of bobcats with partial identity: 42 histories (15 known from both flanks) at 30 single-camera stations over 187 occasions, with an operation matrix (multimark::bobcatSCR, from SPIM; Augustine et al.).",
  reference = "Augustine, B. C., Royle, J. A., Kelly, M. J., Satter, C. B., Alonso, R. S., Boydston, E. E., & Crooks, K. R. (2018). Spatial capture-recapture with partial identity: an application to camera traps. Annals of Applied Statistics, 12, 67-95.",
  doi_paper = "10.1214/17-AOAS1091", doi_data = "", notes = "multimark package data (GPL-2). SCR with partial identity (unit_identity)."), dictc("multimark")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (partial identity)",
  sampling_protocol = "camera_trap", design = "Single-season (187 occasions, 30 stations)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (grid-snapped station positions, in __traps)", notes = "Experimental (E9): trap key + __traps. Partial identity. From the multimark R package (SPIM data).")

# =========================================================================================
# 3. NAAMP Delaware 2001: spring peeper and upland chorus frog calling indices
# =========================================================================================
CALL <- list(`0` = "not heard", `1` = "individuals can be counted; calls do not overlap", `2` = "calls of individuals distinguishable with some overlap", `3` = "full chorus; calls continuous and overlapping")
TABLE <- "naamp_2001_delaware_frog_calls"
fr <- pkg_env(TABLE, "unmarked", "frogs.RData")
py <- unclass(fr$pcru.y); fy <- unclass(fr$pfer.y); dimnames(py) <- NULL; dimnames(fy) <- NULL; pd <- fr$pcru.data; fd <- fr$pfer.data
stops <- unname(dimnames(pd)[[1]])
stopifnot(identical(dim(py), c(130L, 3L)), identical(dim(fy), c(130L, 3L)), identical(is.na(py), is.na(fy)), sum(is.na(py)) == 53L,
          all(py %in% c(0:3, NA)), all(fy %in% c(0:3, NA)), identical(pd, fd), !anyDuplicated(stops),
          identical(unname(dimnames(pd)[[3]]), c("MinAfterSunset", "Wind", "Sky", "Temperature")),
          all(grepl("^[0-9]{6}\\.[0-9]{1,2}$", stops)))
# the package stores 'route.stop' as a number, so stop 10 lost its trailing zero ('210302.1'):
# rebuild route_stop ids and assert each route then has stops 1-10
rt <- sub("\\..*", "", stops); sp <- sub(".*\\.", "", stops); sp[nchar(sp) == 1L] <- paste0(sp[nchar(sp) == 1L], "0")
stops_id <- sprintf("%s_%02d", rt, as.integer(sp))
stopifnot(sum(nchar(sub(".*\\.", "", stops)) == 1L) == 13L, all(tapply(as.integer(sp), rt, function(v) setequal(v, 1:10))), !anyDuplicated(stops_id))
stops <- stops_id
long <- rbindlist(lapply(1:3, function(v) rbind(
  data.table(unit = stops, taxon = "PSECRU", occasion = v, y = py[, v]),
  data.table(unit = stops, taxon = "PSEFER", occasion = v, y = fy[, v]))))[!is.na(y)]
cov <- rbindlist(lapply(1:3, function(v) data.table(unit = stops, occasion = v, obs_min_after_sunset = pd[, v, 1], obs_wind = pd[, v, 2],
                                                     obs_sky = pd[, v, 3], obs_temperature_c = pd[, v, 4])))
long <- merge(long, cov, by = c("unit", "occasion"))
long[, `:=`(cluster_id = sub("_.*", "", unit), y = as.integer(y))]
stopifnot(nrow(long) == 2L * (390L - 53L))
long <- order_eco(long[, .(unit, taxon, y, occasion, cluster_id, obs_min_after_sunset, obs_wind, obs_sky, obs_temperature_c)])
taxa <- make_taxa(c("PSECRU", "PSEFER"), c("Pseudacris crucifer", "Pseudacris feriarum"), vernacularName = c("Spring peeper", "Upland chorus frog"),
                  taxon_iucnCategory = c("LC", "LC"))
dataset <- list(
  title = "North American Amphibian Monitoring Program, Delaware 2001: calling indices of spring peeper and upland chorus frog at 130 stops on up to 3 visits",
  creator = "North American Amphibian Monitoring Program (USGS) and Delaware volunteers (data); Fiske, Ian; Chandler, Richard (distributed in the unmarked R package)",
  pubDate = "2001", sourceURL = "https://cran.r-project.org/package=unmarked", citation = UMCITE("frogs"),
  intellectualRights = lic("unmarked"),
  abstract = "Calling surveys of the North American Amphibian Monitoring Program (NAAMP) in Delaware in 2001: at each of 10 stops on 13 roadside routes, observers listened for 5 minutes after sunset on up to three visits through the season and scored each species' calling index (0 none, 1 individuals countable, 2 some overlap, 3 full chorus). The unmarked package keeps two species, the spring peeper (Pseudacris crucifer) and the upland chorus frog (P. feriarum). One row per stop x visit x species, with minutes after sunset, wind, sky and temperature.",
  samplingProtocol = "NAAMP roadside calling survey: 10 stops per route, 5-min listening at each stop after sunset, up to 3 visits per season; calling index 0-3 per species.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The stop x visit matrices have NA where a visit was not made (53 of 390 cells), identically for both species (asserted); every other cell is a survey with a row for both species.",
  responseType = "ordinal", stateCodes = CALL, unitKind = "site", closure = "closed", closureNote = "single season (2001)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Delaware, USA: 13 NAAMP routes (cluster_id) of 10 stops; no coordinates in the package", temporalCoverage = "2001",
  coordinatesCoarsened = NA,
  notes = "Stop ids are route_stop: the package stores route.stop as a number, so stop 10 appears as e.g. 210302.1 (asserted: every route then has stops 1-10); cluster_id = route. The package keeps two of the species NAAMP records; the NAAMP database (USGS) holds the full species list, other states and years, and stop locations. Visit dates are not in the package; obs_min_after_sunset as deposited (some values are negative). obs_wind and obs_sky are NAAMP codes.",
  notShipped = list(pcru.bin_pfer.bin = "detection collapses of the calling indices (index > 0)", other_species = "the NAAMP survey records all calling anurans; the package keeps two"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "NAAMP calling indices (0-3) of spring peeper and upland chorus frog at 130 roadside stops on 13 routes in Delaware, up to 3 visits in 2001, with listening conditions (unmarked::frogs).",
  reference = "Mossman, M. J., & Weir, L. A. (2005). North American Amphibian Monitoring Program (NAAMP). In M. Lannoo (Ed.), Amphibian Declines: The Conservation Status of United States Species (pp. 307-313). University of California Press.",
  doi_paper = "", doi_data = "", notes = "unmarked package data (GPL); NAAMP is a USGS programme. Ordinal calling index."), dictc("unmarked")))
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Occupancy (ordinal calling index)",
  sampling_protocol = "acoustic", design = "Single-season (up to 3 visits)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "From the unmarked R package. NAAMP.")

# =========================================================================================
# 4. NAAMP Massachusetts 2001-2007: spring peeper
# =========================================================================================
TABLE <- "naamp_2007_massachusetts_peeper_calls"
mp <- as.data.table(pkg_env(TABLE, "unmarked", "masspcru.RData")$masspcru)
stopifnot(nrow(mp) == 3216L, identical(names(mp), c("SurveyYear", "RouteNumStopNum", "JulianDate", "Pcru", "MinAfterSunset", "Temperature")),
          !anyDuplicated(mp[, .(SurveyYear, RouteNumStopNum, JulianDate)]), all(mp$Pcru %in% c(0:3, NA)), sum(is.na(mp$Pcru)) == 4L,
          uniqueN(mp$RouteNumStopNum) == 280L,
          identical(sort(unique(mp$SurveyYear)), 2001:2007), !anyNA(mp$JulianDate), sum(is.na(mp$Temperature)) == 108L,
          all(grepl("^[0-9]+_[0-9]+$", mp$RouteNumStopNum)))
mp[, RouteNumStopNum := as.character(RouteNumStopNum)]
mp <- mp[!is.na(Pcru)]                                                        # 4 visits with no calling index recorded
setorder(mp, RouteNumStopNum, SurveyYear, JulianDate)
mp[, occasion := seq_len(.N), by = .(RouteNumStopNum, SurveyYear)]
stopifnot(max(mp$occasion) == 4L)
long <- mp[, .(unit = RouteNumStopNum, taxon = "PSECRU", y = as.integer(Pcru), period = SurveyYear - 2000L, occasion,
               date = format(as.Date(sprintf("%d-01-01", SurveyYear)) + JulianDate - 1L), cluster_id = sub("_.*", "", RouteNumStopNum),
               obs_min_after_sunset = MinAfterSunset, obs_temperature_c = Temperature)]
long <- order_eco(long)
periods <- mp[, .(n_stops = uniqueN(RouteNumStopNum), n_visits = .N), by = SurveyYear][order(SurveyYear)][, .(period = SurveyYear - 2000L, year = SurveyYear, n_stops, n_visits)]
taxa <- make_taxa("PSECRU", "Pseudacris crucifer", vernacularName = "Spring peeper", taxon_iucnCategory = "LC")
dataset <- list(
  title = "North American Amphibian Monitoring Program, Massachusetts 2001-2007: spring peeper calling index at 280 stops, up to 4 visits a year",
  creator = "North American Amphibian Monitoring Program (USGS) and Massachusetts volunteers (data); Fiske, Ian; Chandler, Richard (distributed in the unmarked R package)",
  pubDate = "2007", sourceURL = "https://cran.r-project.org/package=unmarked", citation = UMCITE("masspcru"),
  intellectualRights = lic("unmarked"),
  abstract = "NAAMP roadside calling surveys in Massachusetts, 2001-2007: spring peeper (Pseudacris crucifer) calling index (0-3) at 280 stops, up to four visits per stop and year, with date, minutes after sunset and temperature, in the raw long format the unmarked package uses for its formatting examples. One row per stop visit.",
  samplingProtocol = "NAAMP roadside calling survey: stops on routes, 5-min listening after sunset, several visits per season; calling index 0-3.",
  samplingProtocolCode = "acoustic", surveyEvidence = "row_presence",
  surveyEvidenceNote = "Each row of the long-format data is a stop visit; occasion orders a stop's visits within a year by date.",
  responseType = "ordinal", stateCodes = CALL, unitKind = "site", closure = "closed", closureNote = "period (closed within a year's calling season)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Massachusetts, USA: NAAMP routes (cluster_id) and stops; no coordinates in the package", temporalCoverage = "2001/2007",
  coordinatesCoarsened = NA,
  notes = "Stop ids as in the package (route_stop); cluster_id = route. Temperature is missing for 108 visits. Only the spring peeper is in the package; the NAAMP database holds the other species and stop locations.",
  notShipped = list(other_species = "the survey records all calling anurans; the package keeps the spring peeper",
                    missing_index = "4 visits with no calling index recorded (Pcru NA) are dropped: y is never NA (E4); occasion numbers the remaining visits in date order"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "NAAMP spring peeper calling index (0-3) at 280 roadside stops in Massachusetts, up to 4 visits per year 2001-2007, with dates and listening conditions (unmarked::masspcru).",
  reference = "Mossman, M. J., & Weir, L. A. (2005). North American Amphibian Monitoring Program (NAAMP). In M. Lannoo (Ed.), Amphibian Declines: The Conservation Status of United States Species (pp. 307-313). University of California Press.",
  doi_paper = "", doi_data = "", notes = "unmarked package data (GPL); NAAMP is a USGS programme. Ordinal calling index, multi-year."), dictc("unmarked")))
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Dynamic occupancy (ordinal calling index)",
  sampling_protocol = "acoustic", design = "Multi-season (7 years x up to 4 visits)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "From the unmarked R package. NAAMP.")

# =========================================================================================
# 5. Ovenbird removal counts (Royle 2004)
# =========================================================================================
TABLE <- "royle_2004_ovenbird_removal"
ov <- pkg_env(TABLE, "unmarked", "ovendata.RData")$ovendata.list
od <- ov$data; oc <- as.data.table(ov$covariates)
stopifnot(identical(dim(od), c(70L, 4L)), !anyNA(od), all(od %in% 0:3), sum(od) == 77, nrow(oc) == 70L,
          identical(names(oc), c("site", "ufc", "trba")), !anyDuplicated(oc$site))
long <- data.table(unit = rep(as.character(oc$site), times = 4), occasion = rep(1:4, each = 70), y = as.integer(od),
                   y_raw = rep(paste0("interval", 1:4), each = 70),
                   unit_ufc = rep(oc$ufc, times = 4), unit_trba = rep(oc$trba, times = 4))
long <- order_eco(long[, .(unit, taxon = "SEIAUR", y, y_raw, occasion, unit_ufc, unit_trba)])
taxa <- make_taxa("SEIAUR", "Seiurus aurocapilla", vernacularName = "Ovenbird", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Ovenbird removal counts in four time intervals at 70 point-count sites (Royle 2004)",
  creator = "Royle, J. Andrew (data; distributed in the unmarked R package)",
  pubDate = "2004", sourceURL = "https://cran.r-project.org/package=unmarked", citation = UMCITE("ovendata"),
  intellectualRights = lic("unmarked"),
  abstract = "Ovenbirds (Seiurus aurocapilla) counted at 70 point-count sites, each new bird recorded in the time interval in which it was first detected (four intervals; removal sampling), with two site covariates (ufc, trba). The example data of Royle (2004) for removal-sampling abundance models, as distributed in unmarked (ovendata). One row per site x interval.",
  samplingProtocol = "Point counts split into four time intervals, birds removed after first detection (removal design); interval lengths, dates and place are not in the package.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The site x interval matrix has no NA: every site was counted once in four intervals.",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site", closure = "closed", closureNote = "occasion (removal intervals of one count)",
  occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Not stated in the package (site codes CAT...; Royle 2004); no coordinates", temporalCoverage = "not stated in the package (before 2004)",
  coordinatesCoarsened = NA,
  notes = "unit_ufc and unit_trba as named in the package (understory foliage cover and tree basal area in unmarked's examples; units not stated). Site ids as in the package. Interval lengths are not in the package.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Ovenbird removal counts (first detections in four time intervals) at 70 point-count sites, with two site covariates (unmarked::ovendata; Royle 2004).",
  reference = "Royle, J. A. (2004). Generalized estimators of avian abundance from count survey data. Animal Biodiversity and Conservation, 27, 375-386.",
  doi_paper = "", doi_data = "", notes = "unmarked package data (GPL). Removal multinomial; place, year and interval lengths not in the package."), dictc("unmarked")))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Removal sampling",
  sampling_protocol = "point_count", design = "Single-season (one count in 4 removal intervals)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the unmarked R package.")
