#!/usr/bin/env Rscript
# Tables: 39 from one script and one deposit. Run `Rscript data/ziolkowski_2026_bbs.R` for all of them, or
#   `Rscript data/ziolkowski_2026_bbs.R 15` / `... 1 15` for the tables of those Bird Conservation Regions only
#   (BCR 15 also builds the block and stop tables; data/run_all.R forwards no argument, so it builds everything).
#     ziolkowski_2026_bbs_bcr<N>_count   N = 1 to 37 (no zero padding): every run in the BCR, 1966-2025
#     ziolkowski_2026_bbs_bcr15_block    BCR 15, RPID 101, 50-stop routes, five 10-stop blocks per run, 1968-2025
#     ziolkowski_2026_bbs_bcr15_stop     BCR 15, RPID 101, 50-stop routes, 2009-2025, one row per stop
#   Why one script: the 37 count tables differ only in which BCR's runs and taxa they hold, and the three BCR 15
#   tables share every file read, the stop-evidence rule and the non-breeder merge. Thirty-nine near-identical files
#   would repeat 400 lines each and drift apart; the multi-table precedent is data/sandercock_2022_norway_alien.R.
#   The reading of the six large files happens once per run, so the full build is one pass over the deposit.
# Source: U.S. Geological Survey data release, "2026 Release - North American Breeding Bird Survey Dataset
#   (1966 - 2025)", doi:10.5066/P144YU3S, ScienceBase item 6a0b0b0ab66b0188da36aedd, release metadata dated
#   2026-05-28. Ziolkowski, D.J., Lutmerding, M., Skalos, S.M., English, W.B., and Hudson, M-A.R., 2026, North American
#   Breeding Bird Survey Dataset 1966 - 2025: U.S. Geological Survey data release, https://doi.org/10.5066/P144YU3S
#   (the release's own useconst writes "2025" in this sentence: a typo in the source; the release year is 2026).
#   Licence, as shown on each source read (the saved ScienceBase page was not part of the download):
#     - DataCite record of the DOI (read 2026-11-04, outside this script): Creative Commons Zero v1.0 Universal.
#     - USGS data page (archived 2026-08-13): "This work is marked with CC0 1.0 Universal".
#     - The release's FGDC metadata XML (in the download, asserted below): accconst "No access constraints"; useconst
#       names no licence and no public-domain wording, says USGS and ECCC approved the release, disclaims liability, and asks
#       that use be recognised "via appropriate citation and acknowledgements", acknowledging the participants.
#     Shipped as CC0 1.0 with the citation and the acknowledgement kept in the citation and the licence note.
#     ECCC (Canadian Wildlife Service) co-approves the release and names no Canadian licence: flagged for the maintainer.
# Paper:  none specific. The design papers: Sauer, J.R., Link, W.A., Ziolkowski, D.J., Pardieck, K.L., Twedt, D.J. (2019).
#   Consistency counts: modeling the effects of a change in protocol on Breeding Bird Survey counts. The Condor 121,
#   doi:10.1093/condor/duz009 (the experimental 501/502 protocol); Rushing, C.S., Royle, J.A., Ziolkowski, D.J., Pardieck, K.L.
#   (2019). Modeling spatially and temporally complex range dynamics when detection is imperfect. Sci. Rep. 9:12805,
#   doi:10.1038/s41598-019-48851-5 (stops as spatial replicates, with a spatial-correlation model).
# Access: ScienceBase refused direct downloads with HTTP 403 on
#   2026-11-04, so the URL pattern in the download calls below, "https://www.sciencebase.gov/catalog/file/get/<item>?name=<file>", is
#   untested: a best guess, unlike the "?f=__disk__<hash>" URLs of older scripts, whose hashes need the item's JSON. The files were downloaded by hand on 2026-11-04 into .cache/raw/ziolkowski_2026_bbs/ (download_cached() skips
#   the network when a file is there) and their sha256 is asserted below. A fresh rebuild from an empty cache will hit the same
#   403; the raw files must be in the cache. The metadata XML and the two PDFs (RunType.pdf, the Completeness Report)
#   were read directly; the XML is also asserted (licence wording, citation, route length, stop spacing).
# Data:   files as deposited, all fields space-padded and read with the padding stripped; codes read as text.
#   Weather.csv: 144,146 rows, one per run (a route surveyed by one observer in one year under one protocol, RPID):
#     RouteDataID (unique, one per run key CountryNum+StateNum+Route+RPID+Year in every file), date parts, ObsN (observer),
#     TotalSpp, start and end temperature with TempScale (F 127,858, C 16,173, NULL 63, blank 50, lower-case f 1 and c 1),
#     wind and sky codes (9 = no data), StartTime/EndTime as HHMM text (blank in 103 and 383 runs), Assistant (NULL in
#     15,056), QualityCurrentID, RunType. No row has Year 2020 (field work cancelled).
#   Routes.csv (Windows-1252): 5,845 routes, one BCR and one stratum each, start point (decimal degrees, NAD 83),
#     RouteTypeID, RouteTypeDetailID (1 random, 2 non-random, 3 fewer than 50 stops), Active; 5,655 routes have a run.
#   States.zip (62 state or province files): 7,562,439 breeding-category records (run x AOU): Count10..Count50 (stops
#     1-10 ... 41-50), StopTotal, SpeciesTotal. 50-StopData.zip (Fifty1..10): 4,551,591 records of 86,503 runs with Stop1..50;
#     complete for every run from 1997, 293 runs before. MigrantNonBreeder.zip: MigrantSummary.csv (10,638 records, the
#     10-stop version, of 6,638 runs) and Migrants.csv (10,548 records, 50-stop) hold every record not in the breeding
#     category. VehicleData.csv: 85,132 runs, RecordedCar (1 69,639, NULL 11,702, 0 3,769, 2 22) and Car1..50, Noise1..50.
#     SpeciesList.csv (Windows-1252): 764 taxa, including unidentified groups, forms and hybrids (ranks asserted below).
# Quirks asserted below: StopTotal in pre-1997 States is impossible in 322 records (not shipped); a run x taxon can sit
#   in a breeding and a non-breeder file (18 pairs, 17 Cedar Waxwing); TotalSpp counts breeding records only; StartTime is the
#   single character "0" in one run and EndTime in seven (kept as recorded, 0 minutes); temperatures reach 562 and 999 (kept);
#   non-breeder records are nearly absent before 1999.
# Mapping (all tables; responseType count; unit = route "840_46_012" = CountryNum_StateNum_Route; taxon = "A" + the AOU
#   code, e.g. A04650; period = year - 1965, the same index in every table, year in __periods; date = the run's ISO date;
#   observer = ObsN):
#   Count tables: one row per run x taxon. occasion = rank of the run in its route-year by date, start time (blank last),
#     RPID: 103 route-years have 2 to 4 runs, so occasion is needed. y = States SpeciesTotal + MigrantSummary SpeciesTotal,
#     the whole-run total over the route's stops, as the source publishes it. obs_nonbreeder_count = the recorded
#     non-breeder count where a non-breeder record exists, 0 from 1999 where none does, NA before 1999 where none does
#     (the deposit cannot say). So y - obs_nonbreeder_count (NA read as 0) is the published breeding count in every year.
#     obs_last_stop = K (below) from 1997, NA before. Pool = every taxon recorded in this table's runs, in the breeding or
#     the non-breeder file, in any year. Survey evidence sample_table: Weather.csv lists every run; every bird is recorded at
#     every run, so a zero for a taxon recorded in the region is a fair zero.
#   Block table (BCR 15, RPID 101, RouteTypeDetailID 1 or 2): occasion 1 to 5 = 10-stop block, y = Count10..Count50 of States
#     + MigrantSummary. Blocks after ceiling(K/10) have no row. Before 1997 K is unknown and the last non-zero block of the run
#     is the last block. obs_block_stops = stops of the block up to K (1 to 10), from 1997; NA before.
#   Stop table (same runs, 2009 on): occasion = stop 1 to K; y = Stop1..Stop50 of 50-StopData + Migrants. obs_cars and
#     obs_noise from VehicleData (obs_cars = Car where RecordedCar = 1 or Car > 0, else NA; obs_noise = Noise, NA for a run with
#     no VehicleData row).
#   Survey set at stop and block level (surveyEvidence inferred): K = the highest stop with a bird in 50-StopData or Migrants,
#     or Car > 0 or Noise > 0 in VehicleData. Stops 1 to K are surveys; a zero before K is fair because the observer went on.
#     Stops after K have no row and their number is in notShipped. A mid-route skip inside a run cannot be seen in this deposit.
#   Covariates: obs_ = the run's Weather fields (obs_start_minute and obs_end_minute are minutes after midnight); the route's
#     fields sit in __units (unit_*), joined by unit, to keep the core small. __taxa = make_taxa() plus taxon_aou and
#     national taxon_first_year, taxon_last_year and taxon_nonbreeder_share_1999on.
# Not shipped (counts per table in notShipped): TotalSpp (breeding records only: an assertion); per-taxon StopTotal (322
#   impossible values before 1997); block and stop tables outside BCR 15 and stop rows of BCR 15 before 2009 (size); the 90
#   MigrantSummary records without a Migrants twin are in the count and block tables and cannot enter the stop table (all are
#   from before 1997); the experimental distance bands and one-minute periods of RPID 501/502 (pooled in the deposit).
# Coordinates: USGS-published route start points kept as published (E7 agency rule); not bird locations.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/ziolkowski_2026_bbs.R"
CACHE <- "ziolkowski_2026_bbs"
DOWNLOAD_DATE <- "2026-11-04"
args <- unlist(strsplit(commandArgs(trailingOnly = TRUE), "[ ,]+")); args <- args[nzchar(args)]
BCRS <- if (length(args)) sort(unique(as.integer(args))) else 1:37
stopifnot(!anyNA(BCRS), all(BCRS %in% 1:37))
DO_SET_B <- 15L %in% BCRS
T0 <- Sys.time()
say <- function(...) message(sprintf("[%6.1f min] ", as.numeric(difftime(Sys.time(), T0, units = "mins"))), sprintf(...))
chk <- function(ok, what) if (!isTRUE(ok)) stop("assertion failed: ", what, call. = FALSE)
# counts of each value of x, as a named integer vector in name order, for comparison with an expected set
vcount <- function(x) { t <- table(x, useNA = "ifany"); nm <- names(t); nm[is.na(nm)] <- "NA"; v <- setNames(as.integer(t), nm); v[order(names(v))] }
same_counts <- function(x, exp) identical(vcount(x), exp[order(names(exp))])

# ---- files: names, real ScienceBase URLs, sha256 ------------------------------------------------
SB <- "https://www.sciencebase.gov/catalog/file/get/6a0b0b0ab66b0188da36aedd?name=%s"
SHA256 <- c(
  "50-StopData.zip" = "eed5fc264a1af6074783685de96b433b1d5ce4a1f8e09528449dbd4f9ba03204",
  "Completeness_Report_NABBS_Dataset_1966-2025.pdf" = "ed307d352abc31ce6f4e66f61909c806680ae2b113e1872467804f8eedadec4a",
  "MigrantNonBreeder.zip" = "c4bad82013f8c75d8ad37c52ea94e06fab01f34c6b62a53392a7499184077c8f",
  "North American Breeding Bird Survey Dataset (1966-2025).xml" = "c16e9785a9e7fdf29b084fa2bd151710a662837a64c340fb7ab443c159402172",
  "Routes.csv" = "8ac35620930b0bc758ed3fcb33c689ebe08840edd04f840050b13dd1a56e8362",
  "RunType.pdf" = "5d3e3effe5cae326a3f63a870c7425b5ea2d15bcd0cc5825e0c6257692cc9618",
  "SpeciesList.csv" = "e54e4b5b1eb6fc5fc5941a8e31876ecc17675f229265f60c4dbfed742fb35274",
  "States.zip" = "568053a412e42f2974642d1961956174e8eaad6bc85c278ef50d6191cc56adcf",
  "VehicleData.csv" = "3c10db0928adb5134db99a918bb84bffd725b284ddb9d7d35ef46b6ff26e1664",
  "Weather.csv" = "4bcdb3346dcc44839690702f76c10306a19329260e99e16576b1a92f4465f67d")
# ScienceBase refuses direct downloads, so rebuild.yml can only build these tables if the raw files are in its cache. Without them,
# skip loudly rather than stop data/run_all.R, which would also stop the workflow's drift check for every other table.
if (nzchar(Sys.getenv("GITHUB_ACTIONS")) && !all(file.exists(file.path(RAW_DIR, CACHE, names(SHA256))))) {
  message("SKIPPED ", SCRIPT, ": the raw files are not in .cache/raw/", CACHE, " and ScienceBase refuses direct downloads. Nothing was rebuilt.")
  quit(save = "no", status = 0)
}
options(timeout = 3600)
RAWF <- vapply(names(SHA256), function(fn) download_cached(sprintf(SB, URLencode(fn, reserved = TRUE)), CACHE, filename = fn), "")
if (getRversion() < "4.5.0") stop("this script needs R >= 4.5 for tools::sha256sum")
got_sha <- unname(tools::sha256sum(RAWF))
bad <- names(SHA256)[got_sha != unname(SHA256)]
if (length(bad)) stop("sha256 mismatch (the release changed or the download is damaged; delete the file from .cache/raw/", CACHE, " and rerun): ", paste(bad, collapse = ", "))
say("10 files present, sha256 verified")
rawf <- function(fn) RAWF[[fn]]
zread <- function(zip, member, ...) fread(cmd = sprintf("unzip -p %s %s", shQuote(rawf(zip)), shQuote(member)), ...)
zmembers <- function(zip) { m <- system2("unzip", c("-Z1", shQuote(rawf(zip))), stdout = TRUE); m[!grepl("/$", m)] }

# the release metadata: licence wording, citation, route length and stop spacing, read from the XML in the download
xml <- paste(readLines(rawf("North American Breeding Bird Survey Dataset (1966-2025).xml"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
chk(grepl("<title>2026 Release - North American Breeding Bird Survey Dataset (1966 - 2025)", xml, fixed = TRUE) &&
    grepl("<onlink>https://doi.org/10.5066/P144YU3S", xml, fixed = TRUE) && grepl("<pubdate>20260528", xml, fixed = TRUE), "XML names the 2026 release, its DOI and date")
chk(grepl("<accconst>No access constraints.", xml, fixed = TRUE) && grepl("appropriate citation and acknowledgements", xml, fixed = TRUE) &&
    grepl("acknowledge the thousands of dedicated U.S. and Canadian participants", xml, fixed = TRUE), "XML: no access constraints; citation and acknowledgement asked")
chk(!grepl("CC0|public domain|Creative Commons", xml, ignore.case = TRUE), "XML names no licence")
chk(grepl("2025, North American Breeding Bird Survey Dataset 1966 - 2025", xml, fixed = TRUE), "XML citation sentence says 2025 (source typo)")
chk(grepl("(39.2 km) long with counting locations placed at approximately half-mile (800-m) intervals, for a total of 50 stops", xml, fixed = TRUE) &&
    grepl("Routes are surveyed once per year", xml, fixed = TRUE) && grepl("No data are provided for 2020", xml, fixed = TRUE), "XML: route length, stop spacing, once a year, no 2020")
chk(grepl("decimal degrees, NAD 83", xml, fixed = TRUE), "XML: NAD 83 coordinates")
chk(grepl("conducts a 3-minute point count, recording all birds seen within a quarter-mile (400-m) radius and all birds heard", xml, fixed = TRUE) &&
    grepl("primarily in June", xml, fixed = TRUE) && grepl("Surveys begin 30 minutes before local sunrise and take approximately 5 hours", xml, fixed = TRUE), "XML: the protocol as the text below states it")

# ---- Weather: one row per run ----------------------------------------------------------------------
cw <- c("RouteDataID", "CountryNum", "StateNum", "Route", "RPID", "Year", "Month", "Day", "ObsN", "TotalSpp", "StartTemp", "EndTemp", "TempScale",
        "StartWind", "EndWind", "StartSky", "EndSky", "StartTime", "EndTime", "Assistant", "QualityCurrentID", "RunType")
W0 <- fread(rawf("Weather.csv"), colClasses = "character", na.strings = NULL)
chk(identical(names(W0), cw) && nrow(W0) == 144146L, "Weather.csv: 22 columns, 144,146 runs")
chk(all(nchar(W0$CountryNum) == 3L & nchar(W0$StateNum) == 2L & nchar(W0$Route) == 3L) && all(grepl("^[0-9]+$", W0$CountryNum)) &&
    all(grepl("^[0-9]+$", W0$StateNum)) && all(grepl("^[0-9]+$", W0$Route)), "Weather codes are zero-padded digits (3, 2, 3)")
chk(all(grepl("^[0-9]{6,7}$", W0$ObsN)) && uniqueN(W0$ObsN) == 11068L, "ObsN is 6 or 7 digits; 11,068 observers")
na_int <- function(x, nulls = "NULL") { x[x %in% nulls] <- NA_character_; chk(all(grepl("^-?[0-9]+$", x[!is.na(x)])), "integer field"); as.integer(x) }
W <- W0[, .(id = as.integer(RouteDataID), cn = as.integer(CountryNum), st = as.integer(StateNum), rt = as.integer(Route),
            unit = paste(CountryNum, StateNum, Route, sep = "_"), ckey = paste(CountryNum, StateNum, Route, sep = "_"),
            rpid = as.integer(RPID), year = as.integer(Year), month = as.integer(Month), day = as.integer(Day), observer = ObsN,
            totalspp = as.integer(TotalSpp), start_temp = na_int(StartTemp), end_temp = na_int(EndTemp),
            temp_scale_raw = TempScale, start_wind = as.integer(StartWind), end_wind = as.integer(EndWind),
            start_sky = as.integer(StartSky), end_sky = as.integer(EndSky), st_raw = StartTime, et_raw = EndTime,
            assistant = na_int(Assistant), quality = as.integer(QualityCurrentID), runtype = as.integer(RunType))]
rm(W0)
chk(!anyDuplicated(W$id) && !anyDuplicated(W[, .(cn, st, rt, rpid, year)]), "RouteDataID and the run key are one-to-one")
chk(setequal(W$year, setdiff(1966:2025, 2020L)) && !any(W$year == 2020L), "years 1966-2025 without 2020: no run in 2020")
W[, date := sprintf("%04d-%02d-%02d", year, month, day)]
chk(!anyNA(as.Date(W$date, format = "%Y-%m-%d")) && identical(format(as.Date(W$date)), W$date), "every date is a valid calendar date")
chk(all(W$month %in% 4:8), "months April to August")
# recoded fields: value sets with counts
W[, temp_scale := toupper(trimws(temp_scale_raw))][temp_scale %in% c("NULL", ""), temp_scale := NA_character_]
chk(same_counts(W$temp_scale_raw, setNames(c(127858L, 16173L, 63L, 50L, 1L, 1L), c("F", "C", "NULL", "", "f", "c"))), "TempScale values and counts")
chk(same_counts(W$temp_scale[!is.na(W$temp_scale)], c(F = 127859L, C = 16174L)) && sum(is.na(W$temp_scale)) == 113L, "temp_scale after recoding: F, C, 113 without")
chk(sum(is.na(W$start_temp)) == 177L && sum(is.na(W$end_temp)) == 293L, "NULL temperatures 177 and 293")
chk(range(W$start_temp, na.rm = TRUE)[2] == 562L && range(W$end_temp, na.rm = TRUE)[2] == 999L && sum(W$start_temp > 130L, na.rm = TRUE) == 2L &&
    sum(W$end_temp > 130L, na.rm = TRUE) == 5L, "impossible temperatures kept: 562, 999; 2 and 5 above 130")
chk(same_counts(W$start_wind, c("0" = 74571L, "1" = 36723L, "2" = 21766L, "3" = 8868L, "4" = 1644L, "5" = 517L, "9" = 57L)) &&
    same_counts(W$end_wind, c("0" = 27306L, "1" = 40965L, "2" = 42116L, "3" = 24638L, "4" = 6743L, "5" = 2248L, "6" = 13L, "7" = 1L, "9" = 116L)) &&
    same_counts(W$start_sky, c("0" = 71888L, "1" = 31158L, "2" = 32865L, "4" = 5569L, "5" = 1991L, "7" = 26L, "8" = 559L, "9" = 90L)) &&
    same_counts(W$end_sky, c("0" = 67763L, "1" = 41681L, "2" = 30346L, "4" = 923L, "5" = 2049L, "7" = 34L, "8" = 1202L, "9" = 148L)), "wind and sky values and counts (9 = no data)")
for (v in c("start_wind", "end_wind", "start_sky", "end_sky")) set(W, which(W[[v]] == 9L), v, NA_integer_)
chk(same_counts(W$assistant, c("0" = 103908L, "1" = 25182L, "NA" = 15056L)), "Assistant values and counts (NULL = no data)")
chk(same_counts(W$quality, c("0" = 8333L, "1" = 135813L)) && same_counts(W$runtype, c("0" = 13843L, "1" = 130303L)), "QualityCurrentID and RunType counts")
chk(same_counts(W$rpid, c("101" = 143678L, "102" = 80L, "103" = 38L, "104" = 12L, "203" = 27L, "501" = 308L, "502" = 3L)), "RPID values and counts")
hhmm <- function(x, n_blank, n_short) {
  chk(sum(x == "") == n_blank && sum(nchar(x) %in% 1:3) == n_short && all(nchar(x) <= 4L) && all(grepl("^[0-9]*$", x)), "clock time field: blanks and short values")
  v <- suppressWarnings(as.integer(x)); h <- v %/% 100L; m <- v %% 100L
  chk(all(h <= 23L & m <= 59L, na.rm = TRUE), "every clock time is a valid time"); h * 60L + m
}
W[, start_minute := hhmm(st_raw, 103L, 1L)][, end_minute := hhmm(et_raw, 383L, 7L)]
chk(sum(is.na(W$start_minute)) == 103L && sum(is.na(W$end_minute)) == 383L, "blank start times 103, end times 383")
# Routes
RO <- fread(rawf("Routes.csv"), colClasses = "character", na.strings = NULL)
chk(identical(names(RO), c("CountryNum", "StateNum", "Route", "RouteName", "Active", "Latitude", "Longitude", "Stratum", "BCR", "RouteTypeID", "RouteTypeDetailID")) &&
    nrow(RO) == 5845L, "Routes.csv: 11 columns, 5,845 routes")
RO[, `:=`(RouteName = trimws(iconv(RouteName, "CP1252", "UTF-8")), ckey = paste(CountryNum, StateNum, Route, sep = "_"))]
chk(!anyDuplicated(RO$ckey) && !anyNA(RO$RouteName), "route keys unique; names decode from Windows-1252")
RO <- RO[, .(ckey, route_name = RouteName, country_num = as.integer(CountryNum), state_num = as.integer(StateNum), route = as.integer(Route),
             active = as.integer(Active), lat = as.numeric(Latitude), lon = as.numeric(Longitude), stratum = as.integer(Stratum), bcr = as.integer(BCR),
             route_type_id = as.integer(RouteTypeID), detail = as.integer(RouteTypeDetailID), route_s = Route)]
chk(!anyNA(RO[, .(lat, lon, stratum, bcr, route_type_id, detail, active)]) && setequal(RO$bcr, 1:37) && all(RO$active %in% 0:1), "Routes: no NA; BCR values 1 to 37; one BCR per route")
chk(all(RO$lat > 24 & RO$lat < 82) && all(RO$lon > -177 & RO$lon < -52), "route start points within North America (Adak to Hazen Lake)")
chk(same_counts(RO$detail, c("1" = 5523L, "2" = 303L, "3" = 19L)) && same_counts(RO$route_type_id, c("1" = 5820L, "2" = 25L)), "RouteTypeDetailID and RouteTypeID counts")
chk(setequal(RO$country_num, c(124L, 840L)), "routes in Canada (124) and the United States (840)")
chk(!anyNA(match(W$ckey, RO$ckey)) && uniqueN(W$ckey) == 5655L, "every run's route is in Routes.csv; 5,655 routes have a run")
ri <- match(W$ckey, RO$ckey); W[, `:=`(bcr = RO$bcr[ri], detail = RO$detail[ri])]
chk(all((W$runtype == 1L) == (W$detail == 1L & W$rpid == 101L & W$quality == 1L)), "RunType = 1 exactly when Detail 1 + RPID 101 + Quality 1 (0 exceptions)")
chk(same_counts(W$detail, c("1" = 138502L, "2" = 5502L, "3" = 142L)), "runs by RouteTypeDetailID")
# runs, routes and pool per BCR (pool = taxa recorded in the BCR's runs, breeding or non-breeder, any year), measured from the release
EXP <- data.table(bcr = 1:37,
  routes = c(1,24,13,130,222,169,19,174,298,320,342,314,191,308,40,245,140,137,130,21,74,278,161,166,111,74,348,406,172,164,82,122,89,37,57,28,48),
  runs = c(14,358,145,2261,4914,2354,160,1803,7402,6945,7932,7219,5924,7990,1095,5573,3392,3662,3663,656,2470,9103,5739,5441,2723,1788,9582,13055,4618,5157,2093,2997,1781,969,1464,648,1056),
  pool = c(44,185,153,243,370,325,180,265,381,376,354,283,260,273,234,347,301,321,303,226,282,272,278,225,238,226,281,253,211,277,244,325,311,286,296,256,315))
chk(identical(as.integer(W[, .N, keyby = bcr]$N), as.integer(EXP$runs)) && sum(EXP$runs) == 144146L, "runs per BCR")
chk(identical(as.integer(W[, uniqueN(ckey), keyby = bcr]$V1), as.integer(EXP$routes)), "routes with a run per BCR")
# occasion: rank of the run in its route-year by date, start time (blank last), RPID. W is sorted once; run index = row.
setorderv(W, c("unit", "year", "date", "start_minute", "rpid"), na.last = TRUE)
W[, occasion := seq_len(.N), by = .(unit, year)]
chk(!anyDuplicated(W[, .(unit, year, rpid)]) && sum(W[, .N, by = .(unit, year)]$N > 1L) == 103L && max(W$occasion) == 4L, "RPID breaks ties: 103 route-years have 2 to 4 runs")
ry_all <- W[, .(n = .N, first_not_101 = rpid[1] != 101L, has_101 = any(rpid == 101L)), by = .(unit, year)]
chk(ry_all[n > 1L & has_101, sum(first_not_101)] == 26L && ry_all[n > 1L & !has_101, .N] == 4L, "of 103 multi-run route-years, 26 have a run other than RPID 101 as occasion 1 although a 101 run exists; 4 have no 101 run")
rm(ry_all)
W[, run := .I]
NRUN <- nrow(W); NTAX <- 764L

# ---- species list ---------------------------------------------------------------------------------
SPL <- fread(rawf("SpeciesList.csv"), colClasses = "character", na.strings = NULL)
chk(nrow(SPL) == 764L && !anyDuplicated(SPL$AOU) && all(nchar(trimws(SPL$AOU)) == 5L), "SpeciesList.csv: 764 taxa, unique 5-character AOU")
SPL[, AOU := trimws(AOU)]
chk(uniqueN(SPL$English_Common_Name) == 764L, "764 distinct English names")
AOU <- SPL$AOU; TAXON <- paste0("A", AOU)

# ---- breeding records: States ------------------------------------------------------------------------
read_counts <- function(zip, member) {   # run key as integers, AOU as text, Count10..50, StopTotal, SpeciesTotal
  d <- zread(zip, member, colClasses = list(integer = c(1:6, 8:14), character = 7))
  run <- match(d$RouteDataID, W$id)
  chk(!anyNA(run), paste(member, ": no orphan RouteDataID"))
  chk(all(d$CountryNum == W$cn[run] & d$StateNum == W$st[run] & d$Route == W$rt[run] & d$RPID == W$rpid[run] & d$Year == W$year[run]), paste(member, ": run key agrees with Weather"))
  tax <- match(d$AOU, AOU); chk(!anyNA(tax), paste(member, ": every AOU is in SpeciesList.csv"))
  chk(all(d$SpeciesTotal == d$Count10 + d$Count20 + d$Count30 + d$Count40 + d$Count50) && all(d$StopTotal >= 0L & d$StopTotal <= 50L) &&
      all(d$Count10 >= 0L & d$Count20 >= 0L & d$Count30 >= 0L & d$Count40 >= 0L & d$Count50 >= 0L), paste(member, ": SpeciesTotal = block sum"))
  r <- data.table(run = run, tax = tax, c1 = d$Count10, c2 = d$Count20, c3 = d$Count30, c4 = d$Count40, c5 = d$Count50, stoptot = d$StopTotal, spp = d$SpeciesTotal)
  setattr(r, "cs", unique(sprintf("%03d_%02d", d$CountryNum, d$StateNum))); r
}
sm <- grep("^States/.*\\.csv$", zmembers("States.zip"), value = TRUE)
chk(length(sm) == 62L, "States.zip holds 62 state files")
st_parts <- lapply(sm, function(m) read_counts("States.zip", m))
STATE_OF_FILE <- data.table(file = sm, cs = vapply(seq_along(sm), function(i) { a <- attr(st_parts[[i]], "cs"); chk(length(a) == 1L, paste(sm[i], ": one country and state per file")); a }, ""))
ST <- rbindlist(st_parts); rm(st_parts)
ST[, key := (run - 1L) * NTAX + tax]
chk(nrow(ST) == 7562439L && !anyDuplicated(ST$key) && uniqueN(ST$run) == NRUN && uniqueN(ST$tax) == 748L, "States: 7,562,439 records, no duplicate run x taxon, all 144,146 runs, 748 taxa")
chk(identical(tabulate(ST$run, NRUN), W$totalspp), "TotalSpp = number of breeding records of the run, for every run")
# the pre-1997 StopTotal defect, counted (StopTotal is not shipped)
nzb <- (ST$c1 > 0L) + (ST$c2 > 0L) + (ST$c3 > 0L) + (ST$c4 > 0L) + (ST$c5 > 0L)
bad_st <- (ST$stoptot < nzb) | (ST$stoptot > 10L * nzb) | (ST$stoptot == 0L & ST$spp > 0L)
chk(sum(nzb > 0 & ST$stoptot < nzb) == 289L && sum(nzb > 0 & ST$stoptot > 10L * nzb) == 33L && sum(ST$stoptot == 0L & ST$spp > 0L) == 1L, "StopTotal: 289 below the non-zero blocks, 33 above ten times them, 1 zero with birds")
N_BAD_STOPTOTAL <- sum(bad_st)   # 322 distinct records: the zero-with-birds record is one of the 289
chk(N_BAD_STOPTOTAL == 322L && all(W$year[ST$run[bad_st]] < 1997L) && all(W$rpid[ST$run[bad_st]] == 101L), "StopTotal: 322 distinct impossible records, all RPID 101, all before 1997")
rm(nzb, bad_st)
state_names <- c(Alabama = "Alabama", Alaska = "Alaska", Alberta = "Alberta", Arizona = "Arizona", Arkansa = "Arkansas", BritCol = "British Columbia", Califor = "California",
  Colorad = "Colorado", Connect = "Connecticut", Delawar = "Delaware", Florida = "Florida", Georgia = "Georgia", Idaho = "Idaho", Illinoi = "Illinois", Indiana = "Indiana",
  Iowa = "Iowa", Kansas = "Kansas", Kentuck = "Kentucky", Louisia = "Louisiana", Maine = "Maine", Manitob = "Manitoba", Marylan = "Maryland", Massach = "Massachusetts",
  Michiga = "Michigan", Minneso = "Minnesota", Mississ = "Mississippi", Missour = "Missouri", Montana = "Montana", NBrunsw = "New Brunswick", NCaroli = "North Carolina",
  NDakota = "North Dakota", Nebrask = "Nebraska", Nevada = "Nevada", Newfoun = "Newfoundland and Labrador", NHampsh = "New Hampshire", NJersey = "New Jersey",
  NMexico = "New Mexico", NovaSco = "Nova Scotia", Nunavut = "Nunavut", NWTerri = "Northwest Territories", NYork = "New York", Ohio = "Ohio", Oklahom = "Oklahoma",
  Ontario = "Ontario", Oregon = "Oregon", PEI = "Prince Edward Island", Pennsyl = "Pennsylvania", Quebec = "Quebec", RhodeIs = "Rhode Island", Saskatc = "Saskatchewan",
  SCaroli = "South Carolina", SDakota = "South Dakota", Tenness = "Tennessee", Texas = "Texas", Utah = "Utah", Vermont = "Vermont", Virgini = "Virginia",
  Washing = "Washington", Wiscons = "Wisconsin", Wyoming = "Wyoming", W_Virgi = "West Virginia", Yukon = "Yukon")
stem <- sub("\\.csv$", "", basename(STATE_OF_FILE$file))
chk(setequal(stem, names(state_names)), "the 62 state file names are the 62 names used here")
STATE_OF_FILE[, state := unname(state_names[stem])]
RO[, cs := sprintf("%03d_%02d", country_num, state_num)]
chk(setequal(STATE_OF_FILE$cs, unique(RO$cs)) && !anyDuplicated(STATE_OF_FILE$cs), "62 states and provinces: the files and Routes.csv agree on them")
RO[, state := STATE_OF_FILE$state[match(cs, STATE_OF_FILE$cs)]]
say("States read: %s records", format(nrow(ST), big.mark = ","))

# ---- non-breeder records: MigrantSummary (10-stop) and Migrants (50-stop) -----------------------------------
MS <- read_counts("MigrantNonBreeder.zip", "MigrantNonBreeder/MigrantSummary.csv")
MS[, key := (run - 1L) * NTAX + tax]
chk(nrow(MS) == 10638L && !anyDuplicated(MS$key) && uniqueN(MS$run) == 6638L && uniqueN(MS$tax) == 462L, "MigrantSummary: 10,638 records, 6,638 runs, 462 taxa, no duplicates")
read_stops <- function(zip, member) {
  d <- zread(zip, member, colClasses = list(integer = c(1:6, 8:57), character = 7))
  run <- match(d$RouteDataID, W$id); chk(!anyNA(run), paste(member, ": no orphan RouteDataID"))
  chk(all(d$CountryNum == W$cn[run] & d$StateNum == W$st[run] & d$Route == W$rt[run] & d$RPID == W$rpid[run] & d$Year == W$year[run]), paste(member, ": run key agrees with Weather"))
  tax <- match(d$AOU, AOU); chk(!anyNA(tax), paste(member, ": every AOU is in SpeciesList.csv"))
  M <- as.matrix(d[, .SD, .SDcols = 8:57]); chk(min(M) >= 0L && max(M) <= 9999L && all(rowSums(M > 0L) >= 1L), paste(member, ": stop counts in 0..9999, no all-zero record"))
  list(run = run, tax = tax, M = M)
}
MG <- read_stops("MigrantNonBreeder.zip", "MigrantNonBreeder/Migrants.csv")
MG$key <- (MG$run - 1L) * NTAX + MG$tax
chk(length(MG$run) == 10548L && !anyDuplicated(MG$key) && uniqueN(MG$run) == 6556L, "Migrants: 10,548 records, 6,556 runs, no duplicates")
mi <- match(MG$key, MS$key); chk(!anyNA(mi), "every Migrants record has a MigrantSummary twin")
blk <- function(M, b) rowSums(M[, (10L * (b - 1L) + 1L):(10L * b), drop = FALSE])
chk(all(blk(MG$M, 1) == MS$c1[mi] & blk(MG$M, 2) == MS$c2[mi] & blk(MG$M, 3) == MS$c3[mi] & blk(MG$M, 4) == MS$c4[mi] & blk(MG$M, 5) == MS$c5[mi]) &&
    all(rowSums(MG$M) == MS$spp[mi]) && all(rowSums(MG$M > 0L) == MS$stoptot[mi]), "Migrants stops sum to MigrantSummary blocks, SpeciesTotal and StopTotal")
no_twin <- setdiff(seq_len(nrow(MS)), mi)
chk(length(no_twin) == 90L && all(W$year[MS$run[no_twin]] < 1997L), "90 MigrantSummary records without a Migrants twin, all before 1997")
# overlap of the breeding and non-breeder files
ov <- MS$key %in% ST$key
chk(sum(ov) == 18L && sum(AOU[MS$tax[ov]] == "06190") == 17L && sum(AOU[MS$tax[ov]] == "04880") == 1L &&
    all(W$rpid[MS$run[ov]] == 101L) && all(W$year[MS$run[ov]] %in% 1999:2007), "18 run x taxon pairs in both files: 17 Cedar Waxwing, 1 American Crow, RPID 101, 1999-2007")
chk(sum(W$year[MS$run] < 1999L) == 162L, "162 non-breeder records before 1999")
# non-breeder records per year (the 1999 step), used in the notes
NB_RUN_SHARE_1999 <- uniqueN(MS$run[W$year[MS$run] >= 1999L]) / sum(W$year >= 1999L)
NB_RATE_1999 <- sum(W$year[MS$run] >= 1999L) / sum(W$year >= 1999L)
NB_SHARE_REC_1999 <- sum(W$year[MS$run] >= 1999L) / (sum(W$year[MS$run] >= 1999L) + sum(W$year[ST$run] >= 1999L))
NB_RUN_SHARE_9798 <- uniqueN(MS$run[W$year[MS$run] %in% 1997:1998]) / sum(W$year %in% 1997:1998)
NB_RUN_SHARE_PRE97 <- uniqueN(MS$run[W$year[MS$run] < 1997L]) / sum(W$year < 1997L)
chk(round(100 * NB_RUN_SHARE_9798, 2) == 0.63 && round(100 * NB_RUN_SHARE_PRE97, 2) == 0.17, "non-breeder records on 0.63% of runs in 1997-98 and 0.17% before 1997")
chk(round(NB_RATE_1999, 3) == 0.130 && round(100 * NB_SHARE_REC_1999, 2) == 0.25 && round(100 * NB_RUN_SHARE_1999, 1) == 8.1, "non-breeder rate 0.130 a run from 1999; 0.25% of records; 8.1% of runs")
NB_NOTE_TOTAL_PRE <- 162L; RUNS_PRE1999 <- sum(W$year < 1999L)
chk(RUNS_PRE1999 == 63817L, "63,817 runs before 1999")
EXPECTED_HIDDEN <- NB_RATE_1999 * RUNS_PRE1999 - NB_NOTE_TOTAL_PRE
chk(abs(EXPECTED_HIDDEN - 8160) < 5, "about 8,160 non-breeder records expected unseen before 1999")

# ---- vehicle data ---------------------------------------------------------------------------------
VE0 <- fread(rawf("VehicleData.csv"), colClasses = list(integer = c(1:6, 8:107), character = 7))
chk(nrow(VE0) == 85132L && ncol(VE0) == 107L, "VehicleData.csv: 85,132 runs, 107 columns")
ve_run <- match(VE0$RouteDataID, W$id); chk(!anyNA(ve_run) && !anyDuplicated(ve_run), "VehicleData: no orphan, one row per run")
chk(all(VE0$CountryNum == W$cn[ve_run] & VE0$StateNum == W$st[ve_run] & VE0$Route == W$rt[ve_run] & VE0$RPID == W$rpid[ve_run] & VE0$Year == W$year[ve_run]), "VehicleData run key agrees with Weather")
chk(same_counts(VE0$RecordedCar, c("1" = 69639L, "NULL" = 11702L, "0" = 3769L, "2" = 22L)), "RecordedCar values and counts")
VE_CAR <- as.matrix(VE0[, .SD, .SDcols = 8:57]); VE_NOI <- as.matrix(VE0[, .SD, .SDcols = 58:107])
chk(min(VE_CAR) >= 0L && min(VE_NOI) >= 0L && all(VE_NOI %in% 0:1), "Car >= 0; Noise is 0 or 1")
VE_REC <- VE0$RecordedCar; rm(VE0)
last_true <- function(B) { r <- max.col(B * 1L, ties.method = "last"); r[rowSums(B) == 0L] <- 0L; r }
VE_LAST <- last_true((VE_CAR > 0L) | (VE_NOI > 0L))

# ---- 50-stop data: K per run, reconciliation, rows of the stop table ----------------------------------------
STOP_RUNS <- which(W$bcr == 15L & W$rpid == 101L & W$detail %in% 1:2 & W$year >= 2009L)
chk(length(STOP_RUNS) == 367L && uniqueN(W$ckey[STOP_RUNS]) == 34L, "stop table runs: BCR 15, RPID 101, Detail 1 or 2, 2009 on: 367 runs on 34 routes")
is_stop_run <- logical(NRUN); is_stop_run[STOP_RUNS] <- TRUE
fm <- zmembers("50-StopData.zip"); fm <- fm[order(as.integer(gsub("\\D", "", basename(fm))))]
chk(identical(fm, sprintf("50-StopData/Fifty%d.csv", 1:10)), "50-StopData.zip holds Fifty1..Fifty10")
K_BIRD <- integer(NRUN); keys_all <- vector("list", 10); keep <- vector("list", 10)
bump <- function(cur, run, last) { a <- data.table(run, last)[, .(m = max(last)), by = run]; cur[a$run] <- pmax(cur[a$run], a$m); cur }
for (i in seq_along(fm)) {
  s <- read_stops("50-StopData.zip", fm[i])
  key <- (s$run - 1L) * NTAX + s$tax; mj <- match(key, ST$key)
  chk(!anyNA(mj), paste(fm[i], ": every 50-stop record has a States twin"))
  M <- s$M
  chk(all(blk(M, 1) == ST$c1[mj] & blk(M, 2) == ST$c2[mj] & blk(M, 3) == ST$c3[mj] & blk(M, 4) == ST$c4[mj] & blk(M, 5) == ST$c5[mj]) &&
      all(rowSums(M) == ST$spp[mj]) && all(rowSums(M > 0L) == ST$stoptot[mj]), paste(fm[i], ": 50-stop sums = blocks = SpeciesTotal, StopTotal = stops with birds"))
  K_BIRD <- bump(K_BIRD, s$run, last_true(M > 0L))
  keys_all[[i]] <- key
  sel <- is_stop_run[s$run]; keep[[i]] <- list(run = s$run[sel], tax = s$tax[sel], M = M[sel, , drop = FALSE])
  rm(s, M, key, mj); gc(FALSE)
  say("  %s done", fm[i])
}
fkeys <- unlist(keys_all); rm(keys_all)
chk(length(fkeys) == 4551591L && !anyDuplicated(fkeys), "50-StopData: 4,551,591 records, no record in two files")
f_runs <- tabulate((fkeys - 1L) %/% NTAX + 1L, NRUN)
chk(sum(f_runs > 0L) == 86503L && all(f_runs[W$year >= 1997L] > 0L) && sum(f_runs > 0L & W$year < 1997L) == 293L, "50-StopData: 86,503 runs, every run from 1997 and 293 before")
chk(all(f_runs[W$year >= 1997L] == tabulate(ST$run, NRUN)[W$year >= 1997L]), "from 1997 every breeding record has a 50-stop record")
K_MIG <- bump(integer(NRUN), MG$run, last_true(MG$M > 0L))
K_VEH <- integer(NRUN); K_VEH[ve_run] <- VE_LAST
K <- pmax(K_BIRD, K_MIG, K_VEH)
Y97 <- W$year >= 1997L
chk(all(K[Y97] >= 1L & K[Y97] <= 50L), "from 1997 every run has stop evidence: K in 1..50")
chk(sum(Y97 & K_VEH > pmax(K_BIRD, K_MIG)) == 450L && sum(Y97 & K_MIG > K_BIRD) == 13L, "VehicleData moves K in 450 runs (0.52%), non-breeder stop records in 13")
chk(sum(Y97 & K < 50L) == 2402L, "2,402 runs from 1997 have K below 50")
K_STOPS <- ifelse(Y97, K, NA_integer_)
W[, last_stop := K_STOPS]
# last non-zero block of a run (breeding or non-breeder 10-stop records)
lastblk <- function(d) fifelse(d$c5 > 0L, 5L, fifelse(d$c4 > 0L, 4L, fifelse(d$c3 > 0L, 3L, fifelse(d$c2 > 0L, 2L, fifelse(d$c1 > 0L, 1L, 0L)))))
L_BLK <- bump(bump(integer(NRUN), ST$run, lastblk(ST)), MS$run, lastblk(MS))
chk(all(L_BLK >= 1L) && all(L_BLK[Y97] <= ceiling(K[Y97] / 10)), "last non-zero block <= ceiling(K/10) from 1997: no recorded bird lies past K")
chk(sum(Y97 & L_BLK < ceiling(K / 10)) == 17L, "the pre-1997 block rule agrees with K on all but 17 of 86,210 runs from 1997 (99.98%)")
NBLK <- ifelse(Y97, as.integer(ceiling(K / 10)), L_BLK)
# stop-eligible runs nationally: what the K rule drops (Detail 1 or 2, RPID 101, from 1997)
ELIG <- which(W$rpid == 101L & W$detail %in% 1:2 & Y97)
chk(length(ELIG) == 85668L && sum(50L - K[ELIG]) == 16088L, "85,668 stop-eligible runs; K drops 16,088 of 4,283,400 stops (0.38%)")
chk(mean(W$quality[ELIG][K[ELIG] < 45L] == 0L) > 0.85, "from 1997 QualityCurrentID = 0 marks more than 85% of runs with K below 45")
rm(fkeys, f_runs); gc(FALSE)
say("50-stop data read; K and block counts computed")

# ---- master taxa table (GBIF through the cache), national first and last year and non-breeder share -------------------
build_master_taxa <- function(d) {
  stopifnot(exists("make_taxa"), exists("gbif_taxon"), exists("GBIF_DIR"))
  d <- copy(d)[, lapply(.SD, function(x) trimws(iconv(x, "CP1252", "UTF-8")))]
  stopifnot(identical(names(d), c("Seq", "AOU", "English_Common_Name", "French_Common_Name", "Order", "Family", "Genus", "Species")),
            nrow(d) == 764L, !anyDuplicated(d$AOU), all(nchar(d$AOU) == 5L), !anyNA(d), !any(d$Genus == "" | d$Species == ""))
  d[, taxon := paste0("A", AOU)]
  whole_family    <- c("04402", "03920")   # unid. hummingbird / woodpecker: the source Genus is a placeholder; the group is the whole family
  subset_of_genus <- c("02429", "07351")   # "sp." groups that are only part of their genus (peeps within Calidris; western chickadees within Poecile)
  # source spelling GBIF rejects -> the spelling sent to GBIF (scientificName keeps the source's): the AOS names of 2024+ against GBIF's backbone
  lookup_fix <- c("02800" = "Charadrius wilsonia", "02810" = "Charadrius montanus", "02780" = "Charadrius nivosus", "01910" = "Ixobrychus exilis")
  slash <- grepl("/", d$Genus, fixed = TRUE) | grepl("/", d$Species, fixed = TRUE)
  real_genera <- unique(d[Species != "sp." & !slash & !grepl(" x ", Species, fixed = TRUE), Genus])
  placeholder <- d$Species == "sp." & !d$Genus %in% real_genera
  d[, taxonRank := fcase(
       grepl(" x ", Species, fixed = TRUE), "hybrid",
       slash, "species complex",
       placeholder & AOU %in% whole_family, "family",
       placeholder, "functional group",
       Species == "sp." & AOU %in% subset_of_genus, "species complex",
       Species == "sp.", "genus",
       grepl(" ", Species, fixed = TRUE), "subspecies",
       default = "species")]
  g2 <- tstrsplit(d$Genus, " / ", fixed = TRUE); e2 <- tstrsplit(d$Species, " / ", fixed = TRUE)
  d[, scientificName := fcase(
       taxonRank == "genus", Genus,
       taxonRank == "family", Family,
       grepl("/", Genus, fixed = TRUE), sprintf("%s %s / %s %s", g2[[1]], e2[[1]], g2[[2]], e2[[2]]),
       default = paste(Genus, Species))]
  d[, lookupName := scientificName]
  d[AOU %in% names(lookup_fix), lookupName := lookup_fix[AOU]]
  parent_if_needed <- function(nm) {   # a subspecies goes to GBIF as the trinomial when GBIF has it as a subspecies, else as its parent species
    g <- gbif_taxon(nm)
    if (identical(g$matchType, "EXACT") && identical(g$rank, "subspecies")) nm else sub("^(\\S+ \\S+).*$", "\\1", nm)
  }
  d[taxonRank == "subspecies", lookupName := vapply(lookupName, parent_if_needed, "")]
  taxa <- make_taxa(d$taxon, d$scientificName, vernacularName = d$English_Common_Name, taxonRank = d$taxonRank,
                    lookupName = d$lookupName, taxon_aou = d$AOU)
  stopifnot(!any(taxa$gbifMatchType == "ERROR"))   # a transient failure is cached as ERROR: delete .cache/gbif/<name>.json and rerun
  gj <- lapply(d$lookupName, function(nm) fromJSON(file.path(GBIF_DIR, paste0(gsub("[^A-Za-z0-9]+", "_", nm), ".json"))))
  gbif_rank <- vapply(gj, function(x) tolower(x$rank %||% NA_character_), "")
  gbif_class <- vapply(gj, function(x) x$class %||% NA_character_, "")
  no_id <- taxa$taxonRank %in% c("species complex", "hybrid", "functional group") |
           (taxa$taxonRank %in% c("species", "genus", "family") & taxa$gbifMatchType == "HIGHERRANK")
  taxa[no_id, taxonID := NA_character_]
  taxa[, taxon_gbifRank := fifelse(is.na(taxonID), NA_character_, gbif_rank)]
  stopifnot(all(gbif_class[!is.na(taxa$taxonID)] == "Aves"))    # homonym guard: every kept key is a bird
  stopifnot(all(taxa[taxonRank %in% c("genus", "family"), taxon_gbifRank == taxonRank]))
  taxa[]
}
MASTER <- build_master_taxa(SPL)
chk(identical(MASTER$taxon, TAXON) && nrow(MASTER) == 764L && !anyDuplicated(MASTER$taxon), "764 taxa in the master table, in SpeciesList order")
chk(identical(vcount(MASTER$taxonRank), c(family = 2L, "functional group" = 3L, genus = 8L, hybrid = 8L, species = 676L, "species complex" = 50L, subspecies = 17L)[c("family", "functional group", "genus", "hybrid", "species", "species complex", "subspecies")][order(c("family", "functional group", "genus", "hybrid", "species", "species complex", "subspecies"))]),
    "taxon ranks: 676 species, 17 subspecies/forms, 8 hybrids, 50 species complexes, 8 genus, 3 functional group, 2 family rows")
chk(!anyNA(MASTER[taxonRank == "species", taxonID]), "every species-rank taxon has a GBIF key")
rec <- rbind(data.table(tax = ST$tax, year = W$year[ST$run], nb = 0L), data.table(tax = MS$tax, year = W$year[MS$run], nb = 1L))
tx_year <- rec[, .(taxon_first_year = min(year), taxon_last_year = max(year)), keyby = tax]
chk(nrow(tx_year) == 764L, "every one of 764 taxa has a record in the breeding or the non-breeder files")
tx_share <- rec[year >= 1999L, .(s = sum(nb) / .N), keyby = tax]
MASTER[, `:=`(taxon_first_year = tx_year$taxon_first_year, taxon_last_year = tx_year$taxon_last_year,
              taxon_nonbreeder_share_1999on = round(tx_share$s[match(seq_len(764L), tx_share$tax)], 6))]   # NA for a taxon with no record from 1999 on
bsp <- data.table(tax = ST$tax, y = W$year[ST$run])[, .(f = min(y), l = max(y)), by = tax]
chk(sum(bsp$l < 1997L) == 11L && sum(bsp$f >= 1997L) == 71L && nrow(bsp) == 748L, "breeding files: 11 taxa only before 1997, 71 only from 1997")
chk(all(tx_year$taxon_first_year[match(c("00010", "00011"), AOU)] == 1986L), "Western and Clark's Grebe have no record before 1986")
chk(sum(tx_year$taxon_last_year < 1997L) == 10L && sum(tx_year$taxon_first_year >= 1997L) == 86L, "breeding or non-breeder files: 10 taxa only before 1997, 86 only from 1997")
rm(rec)
say("master taxa ready")

# ---- shared text ------------------------------------------------------------------------------------
CITATION <- paste0("Ziolkowski, D.J., Lutmerding, M., Skalos, S.M., English, W.B., and Hudson, M-A.R., 2026, North American Breeding Bird Survey Dataset 1966 - 2025: ",
                   "U.S. Geological Survey data release, https://doi.org/10.5066/P144YU3S. All work using these data should acknowledge the thousands of dedicated ",
                   "U.S. and Canadian participants who annually perform and coordinate the survey.")
CREATOR <- paste0("Ziolkowski, David J., Jr.; Lutmerding, Michael; Skalos, Shannon M. (U.S. Geological Survey, Eastern Ecological Science Center); ",
                  "English, Willow B.; Hudson, Marie-Anne R. (Environment and Climate Change Canada, Canadian Wildlife Service)")
RIGHTS <- list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
  note = paste0("DataCite (doi:10.5066/P144YU3S) and the USGS data page mark the release CC0 1.0 Universal. The release metadata XML names no licence, states 'No access constraints', ",
                "approves the release for USGS and ECCC (Canadian Wildlife Service), disclaims liability, and asks for citation and an acknowledgement of the participants; both are in the citation. ",
                "ECCC co-approves the release and names no Canadian licence."))
ORIGINAL_LICENSE <- paste0("CC0 1.0 Universal (DataCite and the USGS data page, 2026). The release metadata names no licence, has no access constraints, and asks that use be recognised via ",
                           "citation and an acknowledgement of the U.S. and Canadian participants; ECCC co-approves the release.")
STOP_POINTS <- paste0("Stops are sequential spatial points about 800 m apart along a route of about 39.2 km, counted once, in one morning of about five hours, by one moving observer: ",
  "they are not temporal repeats at one place, so no closure of the kind that N-mixture or occupancy models assume holds across stops.")
STOP_GEOMETRY <- paste0(STOP_POINTS, " A bird can be counted at two stops. On spatial subunits as replicates see Kendall and White (2009, doi:10.1111/j.1365-2664.2009.01732.x); on N-mixture reliability, Barker et al. (2018, doi:10.1111/biom.12734) and Link et al. (2018, doi:10.1002/ecy.2362).")
# BCR names come from the release XML's own domain for the BCR column of Routes.csv
bcr_attr <- substr(xml, regexpr("<attrlabl>BCR", xml, fixed = TRUE), nchar(xml))
bcr_attr <- substr(bcr_attr, 1L, regexpr("</attr>", bcr_attr, fixed = TRUE))
bcr_dom <- regmatches(bcr_attr, gregexpr("<edomv>[0-9]+</edomv>\\s*<edomvd>[^<]*</edomvd>", bcr_attr))[[1]]
chk(length(bcr_dom) == 37L, "the XML lists 37 BCR values")
chk(identical(as.integer(sub(".*<edomv>([0-9]+)</edomv>.*", "\\1", bcr_dom)), 1:37), "the XML's BCR codes are 1 to 37 in order")
BCR_NAMES <- gsub("/ ", "/", sub(".*<edomvd>([^<]*)</edomvd>.*", "\\1", bcr_dom), fixed = TRUE)
chk(BCR_NAMES[15] == "Sierra Nevada" && BCR_NAMES[26] == "Mississippi Alluvial Valley", "BCR names read from the XML")
ISO3 <- c("124" = "CAN", "840" = "USA")
nice <- function(x) format(x, big.mark = ",", trim = TRUE)
np <- function(n, w) sprintf("%d %s%s", n, w, ifelse(n == 1L, "", "s"))   # "1 route", "40 routes"
PERIODS_NOTE <- function(runs) paste0("period = year - 1965 in every table, with the calendar year in __periods, which lists every year from the table's first to its last; a year without a run has n_runs = 0.",
  if (min(W$year[runs]) < 2020L && max(W$year[runs]) > 2020L) " 2020 had no field work (no row in any data file), so period 55 never occurs." else "")
COLEXT <- paste("eco_to_unmarked(family = \"colext\") builds numPrimary = max(period) and one column per (period, occasion) present, so a year without a run breaks it or misaligns it:",
                "filter to occasion == 1 and pad the periods yourself before fitting a dynamic occupancy model.")

# helpers ---------------------------------------------------------------------------------------------
run_level <- function(runs) {   # the run-level columns of a table, one row per run in `runs`
  W[runs, .(unit, period = year - 1965L, occasion = occasion, date, observer, obs_rpid = rpid, obs_run_type = runtype, obs_quality_current = quality,
            obs_start_temp = start_temp, obs_end_temp = end_temp, obs_temp_scale = temp_scale, obs_start_wind = start_wind, obs_end_wind = end_wind,
            obs_start_sky = start_sky, obs_end_sky = end_sky, obs_start_minute = start_minute, obs_end_minute = end_minute, obs_assistant = assistant)]
}
units_table <- function(runs) {
  u <- RO[ckey %in% W$ckey[runs]]; setorder(u, ckey)
  data.table(unit = u$ckey, unit_route_name = u$route_name, unit_country_num = u$country_num, unit_state_num = u$state_num, unit_route = u$route,
             unit_stratum = u$stratum, unit_bcr = u$bcr, unit_route_type_id = u$route_type_id, unit_route_type_detail_id = u$detail, unit_active = u$active,
             unit_decimalLatitude = u$lat, unit_decimalLongitude = u$lon, unit_coordinateUncertaintyInMeters = 39200L)
}
periods_table <- function(runs, block = FALSE) {
  yrs <- min(W$year[runs]):max(W$year[runs])
  p <- data.table(period = yrs - 1965L, year = yrs,
                  n_runs = as.integer(tabulate(match(W$year[runs], yrs), length(yrs))),
                  n_routes = vapply(yrs, function(y) uniqueN(W$unit[runs][W$year[runs] == y]), 1L),
                  nonbreeder_records_preserved = as.integer(yrs >= 1999L))
  if (block) p[, stop_data_complete := as.integer(year >= 1997L)]
  p[n_runs == 0L, nonbreeder_records_preserved := NA_integer_]
  if (block) p[n_runs == 0L, stop_data_complete := NA_integer_]
  chk(all(p$n_runs[p$year == 2020L] == 0L) && all(p$n_routes[p$year == 2020L] == 0L) && sum(p$n_runs) == length(runs), "__periods: 2020 listed with 0 runs; runs add up")
  p
}
dense_long <- function(lvl, tx, yv, nbv) {   # lvl: one row per survey, tx: taxon codes of the pool; rows are survey-major, taxon-minor
  m <- length(tx)
  long <- lvl[rep(seq_len(nrow(lvl)), each = m)]
  long[, `:=`(taxon = rep(tx, times = nrow(lvl)), y = yv, obs_nonbreeder_count = nbv)]
  setcolorder(long, c("unit", "taxon", "y"))
  long
}
states_of <- function(runs) sort(unique(RO$state[match(W$ckey[runs], RO$ckey)]))
countries_of <- function(runs) paste(ISO3[as.character(sort(unique(W$cn[runs])))], collapse = ",")
bcr_label <- function(b) sprintf("BCR %d, %s", b, BCR_NAMES[b])
cover <- function(b, runs) sprintf("Bird Conservation Region %d (%s; BCR code and name as in this release's Routes.csv and metadata), roadside routes in %s; route start points as published",
                                   b, BCR_NAMES[b], paste(states_of(runs), collapse = ", "))
nb_flag <- function(runs) if (any(W$year[runs] < 1999L)) "NA before 1999 where no non-breeder record exists, 0 from 1999 where none does" else "0 where no non-breeder record exists"

NOTES_COMMON <- function(runs, extra = NULL) {
  pre99 <- any(W$year[runs] < 1999L)
  paste(c(
    "BCR codes and names are this release's (1 to 37); bbsBayes2 has since renumbered some.",
    "USGS and bbsBayes2 analyse RunType 1 only: filter obs_run_type == 1. RPID 501/502 (experimental) lower counts on average (Sauer et al. 2019, doi:10.1093/condor/duz009).",
    if (pre99) "Non-breeder records are nearly absent before 1999, when the survey began to keep them: a zero then with obs_nonbreeder_count NA cannot exclude a non-breeder, and y steps up at 1999 for such taxa. y - obs_nonbreeder_count (NA as 0) is the published breeding count in every year. taxon_nonbreeder_share_1999on in __taxa is the national share of a taxon's records from 1999 that are non-breeder records (records, not birds; NA with no record from 1999)." else
      "y - obs_nonbreeder_count is the published breeding count.",
    "taxon_first_year and taxon_last_year in __taxa are national; a zero before taxon_first_year can mean the category did not exist yet. Unidentified groups, forms and hybrids are their own taxa, with nothing rolled up.",
    "Route covariates and route start points (not bird locations) are in __units, so eco_to_unmarked() starts with empty siteCovs; join on unit.",
    "Temperatures are as recorded, value plus scale; impossible values are kept.",
    PERIODS_NOTE(runs), COLEXT, extra, "Rationale: notes/decisions/bbs_design.md."), collapse = " ")
}
CODES_NOTE <- " Codes, from the release metadata: wind is Beaufort 0 to 8; sky is 0 clear or few clouds, 1 partly cloudy or variable, 2 cloudy or overcast, 4 fog or smoke, 5 drizzle, 7 snow, 8 showers; obs_assistant is 1 if an assistant recorded the data; obs_quality_current is 1 if the run met all quality criteria (manual inspection before 1997, by rule from 1997); minutes are after midnight; wind or sky code 9 (no data) is NA."

# ---- the count tables --------------------------------------------------------------------------------
ST_BCR <- W$bcr[ST$run]; MS_BCR <- W$bcr[MS$run]
build_count <- function(b) {
  name <- sprintf("ziolkowski_2026_bbs_bcr%d_count", b)
  runs <- which(W$bcr == b); n <- length(runs)
  sst <- which(ST_BCR == b); sms <- which(MS_BCR == b)
  pool <- sort(unique(c(ST$tax[sst], MS$tax[sms]))); m <- length(pool)
  chk(n == EXP$runs[b] && m == EXP$pool[b] && uniqueN(W$unit[runs]) == EXP$routes[b], sprintf("BCR %d: runs, pool and routes as measured", b))
  rpos <- match(seq_len(NRUN), runs)                      # run -> position in this table
  y <- integer(n * m); nbv <- rep(fifelse(W$year[runs] >= 1999L, 0L, NA_integer_), each = m)
  p1 <- (rpos[ST$run[sst]] - 1) * m + match(ST$tax[sst], pool); y[p1] <- ST$spp[sst]
  p2 <- (rpos[MS$run[sms]] - 1) * m + match(MS$tax[sms], pool); y[p2] <- y[p2] + MS$spp[sms]; nbv[p2] <- MS$spp[sms]
  chk(sum(as.numeric(y)) == sum(as.numeric(ST$spp[sst])) + sum(as.numeric(MS$spp[sms])), sprintf("BCR %d: sum(y) = breeding + non-breeder SpeciesTotal", b))
  chk(sum(as.numeric(y) - ifelse(is.na(nbv), 0, nbv)) == sum(as.numeric(ST$spp[sst])), sprintf("BCR %d: y - obs_nonbreeder_count = published breeding total", b))
  lvl <- run_level(runs); lvl[, obs_last_stop := W$last_stop[runs]]
  long <- dense_long(lvl, TAXON[pool], y, nbv)
  chk(nrow(long) == n * m, sprintf("BCR %d: rows = runs x pool", b))
  nz <- sum(y > 0L); chk(nz == length(unique(c(ST$key[sst], MS$key[sms]))), sprintf("BCR %d: one non-zero row per source run x taxon", b))
  rm(y, nbv, lvl); gc(FALSE)
  taxa <- MASTER[taxon %in% TAXON[pool]]; setorder(taxa, taxon)
  units <- units_table(runs); periods <- periods_table(runs)
  dates <- range(W$date[runs]); sts <- states_of(runs)
  yrs <- range(W$year[runs]); nr1 <- sum(W$runtype[runs] == 1L); n_u <- uniqueN(W$unit[runs])
  n_rows_taxa <- length(pool)
  sib <- if (b == 15L) c("ziolkowski_2026_bbs_bcr15_block", "ziolkowski_2026_bbs_bcr15_stop") else NULL
  dataset <- list(
    title = sprintf("North American Breeding Bird Survey, %s: run totals of %d bird taxa on %s, %d-%d", bcr_label(b), m, np(n_u, "roadside route"), yrs[1], yrs[2]),
    creator = CREATOR, pubDate = "2026-05-28", doi = "10.5066/P144YU3S", sourceURL = "https://doi.org/10.5066/P144YU3S", citation = CITATION,
    intellectualRights = RIGHTS,
    abstract = sprintf("The North American Breeding Bird Survey: each breeding season, mostly in June, a skilled observer drives a roadside route of about 39.2 km and counts every bird seen within 400 m or heard at 50 stops per route, one run per route and year (a route-year can have a replicate or secondary-observer run). This table holds the %s runs on the %s of Bird Conservation Region %d (%s) in %s, %d-%d. One row per run and bird taxon: y is the run total over the stops (breeding-category plus non-breeder records), zero for each of the %d taxa recorded in this region's runs and not seen on that run. The run's date, observer, weather, start and end time, the last stop with evidence of sampling and the non-breeder part of y come with it; route coordinates are in the __units table.",
                       nice(n), np(n_u, "route"), b, BCR_NAMES[b], paste(sts, collapse = ", "), yrs[1], yrs[2], m),
    samplingProtocol = "North American Breeding Bird Survey: 3-minute point counts of all birds seen within 400 m or heard at 50 stops per route, spaced about 800 m along a roadside route of about 39.2 km, once per year in the breeding season (mostly June), beginning 30 minutes before local sunrise, by one observer (an assistant may record); y is the run total over the stops.",
    samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
    closure = paste("period = year (index year - 1965); occasion = rank of the run within its route-year by date, start time and RPID, so a route-year with several runs is several occasions and a route-year with one run has occasion 1. A table's rows across years are not a closed population, and the run is a total over its stops.", STOP_POINTS),
    surveyEvidenceNote = sprintf("Weather.csv lists every run (one row per run, %s here), so the survey set is a sample table. Pool: every taxon recorded in this table's runs in the breeding (States) or the non-breeder (MigrantSummary) files, in any year; observers record every bird at every run, so a zero against a taxon recorded in the region is a fair not-detected, and a taxon never recorded in this region's runs has no rows. Before 1999 the non-breeder files hold almost nothing, so a zero then with obs_nonbreeder_count NA cannot exclude a non-breeder.", nice(n)),
    temporalCoverage = sprintf("%s/%s", dates[1], dates[2]),
    geographicCoverage = cover(b, runs), crs = "EPSG:4269 (NAD83)",
    coordinatesCoarsened = list(value = FALSE, method = "route start points as USGS publishes them; agency coordinates are kept as published under E7"),
    covariateNote = paste0("obs_nonbreeder_count: ", nb_flag(runs), ". obs_last_stop: the last stop with evidence of sampling, 1997 on (NA before).", CODES_NOTE),
    designNote = paste0(sprintf("One row per run and taxon; y = run total. occasion orders runs within a route-year. %s of the %s runs have RunType 1 (obs_run_type).", nice(nr1), nice(n)),
                        if (any(W$detail[runs] == 3L)) " RouteTypeDetailID 3 routes (see __units) count fewer than the standard stops, so their run totals are not comparable; obs_run_type == 1 excludes them." else ""),
    components = sib,
    notShipped = Filter(Negate(is.null), list(
      TotalSpp = sprintf("per-run count of breeding records; equals the number of breeding records of every one of the %s runs (asserted); not shipped", nice(n)),
      StopTotal = sprintf("per-taxon number of stops with the taxon, %s breeding records of this table's runs; before 1997 it is impossible in %d records nationally; not shipped (it would also need a stop-level merge for the 18 breeding/non-breeder pairs)", nice(length(sst)), N_BAD_STOPTOTAL),
      stop_and_block_level = if (b == 15L) "shipped in the sibling block and stop tables" else
        sprintf("the 10-stop blocks and per-stop counts of this table's runs (%s runs from 1997 have 50-StopData rows) are in the deposit; only BCR 15 is built at that level, for size", nice(sum(W$year[runs] >= 1997L))),
      experimental_protocol_detail = if (any(W$rpid[runs] %in% c(501L, 502L))) sprintf("distance bands and one-minute periods of the %s here (RPID 501/502) are pooled in the deposit", np(sum(W$rpid[runs] %in% c(501L, 502L)), "run")))),
    notes = NOTES_COMMON(runs, c(
      { ry <- W[runs, .(n = .N, first101 = rpid[1] == 101L), by = .(unit, year)]   # W is sorted by occasion within a route-year
        if (any(ry$n > 1L)) sprintf("occasion is the rank of the run in its route-year; %d route-years here have several runs, and in %d of them occasion 1 is not the RPID 101 run, so use obs_rpid.", sum(ry$n > 1L), sum(ry$n > 1L & !ry$first101)) else
          "occasion is the rank of the run in its route-year; every route-year here has one run." })))
  dataset <- Filter(Negate(is.null), dataset)
  ds <- write_table(long, name, dataset, taxa = taxa, periods = periods, units = units, script = SCRIPT)
  stage_dict_row(name,
    description = sprintf("Run totals of %d bird taxa on %s Breeding Bird Survey runs of %s in Bird Conservation Region %d (%s), %d-%d, one row per run and taxon with date, observer, weather and the non-breeder part of the count; route coordinates in __units.", m, nice(n), np(n_u, "roadside route"), b, BCR_NAMES[b], yrs[1], yrs[2]),
    url = "https://doi.org/10.5066/P144YU3S", reference = CITATION, doi_paper = "", doi_data = "10.5066/P144YU3S",
    original_license = ORIGINAL_LICENSE, derived_license = "CC0 1.0",
    notes = "Pool = taxa recorded in the region's runs in the breeding or non-breeder files. y = run total including non-breeder records (obs_nonbreeder_count NA before 1999 where none is recorded). All runs shipped; filter obs_run_type == 1 for the standard set. Raw files downloaded by hand (ScienceBase refuses direct downloads), sha256 asserted.",
    source_via = "USGS ScienceBase (downloaded by hand 2026-11-04)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture / annual count index (multi-species, multi-season)", sampling_protocol = "point_count",
    design = "Multi-season (annual route runs; a route-year can have several runs; stops summed within the run)", realm = "Terrestrial", country = countries_of(runs),
    coordinates = "As published (USGS route start points, kept as published)",
    notes = sprintf("Route runs of Bird Conservation Region %d; all runs shipped, RunType in obs_run_type; non-breeder counts in y with obs_nonbreeder_count.", b))
  rm(long); gc(FALSE)
  invisible(list(rows = n * m, runs = n))
}
if (any(BCRS %in% 1:37)) {
  tot <- 0
  for (b in BCRS) { r <- build_count(b); tot <- tot + r$rows; say("BCR %d count table done: %s rows", b, nice(r$rows)) }
  if (length(BCRS) == 37L) chk(tot == 42067219, "37 count tables hold 42,067,219 rows")
}

# ---- BCR 15: block and stop tables ---------------------------------------------------------------------
build_block <- function() {
  name <- "ziolkowski_2026_bbs_bcr15_block"; sib <- "ziolkowski_2026_bbs_bcr15_stop"; cnt <- "ziolkowski_2026_bbs_bcr15_count"
  runs <- which(W$bcr == 15L & W$rpid == 101L & W$detail %in% 1:2); n <- length(runs)
  all15 <- which(W$bcr == 15L)
  sst <- which(W$bcr[ST$run] == 15L & W$rpid[ST$run] == 101L & W$detail[ST$run] %in% 1:2); sms <- which(W$bcr[MS$run] == 15L & W$rpid[MS$run] == 101L & W$detail[MS$run] %in% 1:2)
  pool <- sort(unique(c(ST$tax[sst], MS$tax[sms]))); m <- length(pool)
  nb <- NBLK[runs]; off <- cumsum(c(0, nb))[seq_len(n)]; S <- sum(nb)
  rpos <- match(seq_len(NRUN), runs)
  y <- integer(S * m); yr <- W$year[runs]
  nbv <- rep(rep(fifelse(yr >= 1999L, 0L, NA_integer_), times = nb), each = m)
  place <- function(d, sel, is_nb) {
    ri <- rpos[d$run[sel]]; pj <- match(d$tax[sel], pool)
    for (bk in 1:5) {
      cb <- d[[paste0("c", bk)]][sel]
      chk(all(cb[nb[ri] < bk] == 0L), "no count lies in a block after ceiling(K/10)")
      if (is_nb) { s2 <- nb[ri] >= bk; pos <- (off[ri[s2]] + bk - 1) * m + pj[s2]; nbv[pos] <<- cb[s2]; y[pos] <<- y[pos] + cb[s2] }
      else { s2 <- cb > 0L; pos <- (off[ri[s2]] + bk - 1) * m + pj[s2]; y[pos] <<- y[pos] + cb[s2] }
    }
  }
  place(ST, sst, FALSE); place(MS, sms, TRUE)
  chk(sum(as.numeric(y)) == sum(as.numeric(ST$spp[sst])) + sum(as.numeric(MS$spp[sms])), "block table: sum(y) = breeding + non-breeder SpeciesTotal of its runs")
  chk(sum(as.numeric(y) - ifelse(is.na(nbv), 0, nbv)) == sum(as.numeric(ST$spp[sst])), "block table: y - obs_nonbreeder_count = published breeding total")
  rr <- rep(seq_len(n), times = nb); bk <- sequence(nb)
  lvl <- run_level(runs)[rr]; lvl[, occasion := bk]
  lvl[, obs_block_stops := fifelse(is.na(W$last_stop[runs][rr]), NA_integer_, pmin(10L, W$last_stop[runs][rr] - 10L * (bk - 1L)))]
  chk(all(is.na(lvl$obs_block_stops) | (lvl$obs_block_stops >= 1L & lvl$obs_block_stops <= 10L)), "obs_block_stops in 1..10")
  long <- dense_long(lvl, TAXON[pool], y, nbv)
  chk(nrow(long) == S * m && nrow(long) <= n * m * 5L, "block table: rows = blocks with evidence x pool")
  rm(y, nbv, lvl); gc(FALSE)
  taxa <- MASTER[taxon %in% TAXON[pool]]; setorder(taxa, taxon)
  units <- units_table(runs); periods <- periods_table(runs, block = TRUE)
  dates <- range(W$date[runs]); yrs <- range(W$year[runs]); n_u <- uniqueN(W$unit[runs])
  chk(uniqueN(long[, .(unit, period)]) == n, "block table: one run per route-year")
  dropped_blocks <- sum(5L - nb)
  dataset <- list(
    title = sprintf("North American Breeding Bird Survey, BCR 15, Sierra Nevada: 10-stop block counts of %d bird taxa on %d routes, %d-%d", m, n_u, yrs[1], yrs[2]),
    creator = CREATOR, pubDate = "2026-05-28", doi = "10.5066/P144YU3S", sourceURL = "https://doi.org/10.5066/P144YU3S", citation = CITATION,
    intellectualRights = RIGHTS,
    abstract = sprintf("The standard runs (RPID 101) of the 50-stop routes of Bird Conservation Region 15 (Sierra Nevada; %s), %d-%d, as five 10-stop blocks per run. One row per run, block and bird taxon: y is the count of the taxon over the block's stops (breeding-category plus non-breeder records), zero for each of the %d taxa recorded in these runs and not seen in that block. Blocks after the last stop with evidence of sampling have no row. Blocks are consecutive stretches of a route about 8 km long, not temporal repeats.",
                       paste(states_of(runs), collapse = ", "), yrs[1], yrs[2], m),
    samplingProtocol = "North American Breeding Bird Survey: 3-minute point counts of all birds seen within 400 m or heard at 50 stops per route; counts are published per 10-stop block (stops 1-10, 11-20, ... 41-50) for the whole record from 1966.",
    samplingProtocolCode = "point_count", surveyEvidence = "inferred", responseType = "count", unitKind = "site",
    closure = paste("period = year (index year - 1965); occasion = 10-stop block along the route (1 to 5). Blocks are consecutive stretches of the route, counted in sequence once in a morning, not temporal repeats. Across years a route's rows are not a closed population.", STOP_GEOMETRY),
    surveyEvidenceNote = "Weather.csv lists every run but no file says how many stops a run sampled. Evidence that a stop was sampled: a bird record in the 50-stop or non-breeder stop files, or Car > 0 or Noise > 0 in VehicleData. K = the last stop with evidence, from 1997 (when stop data are complete); before 1997 the last block with a non-zero count (breeding or non-breeder) is the last block. Blocks 1 to ceiling(K/10) are surveys; a zero in an empty block before the last is fair because the observer went on past it. Blocks after have no row. A mid-route skip inside a run cannot be seen, so a zero there could be unsupported; nationally obs_quality_current = 0 marks more than 85% of runs from 1997 with K below 45. Pool: every taxon recorded in this table's runs, in the breeding or the non-breeder files; observers record every bird at every run.",
    temporalCoverage = sprintf("%s/%s", dates[1], dates[2]),
    geographicCoverage = cover(15L, runs), crs = "EPSG:4269 (NAD83)",
    coordinatesCoarsened = list(value = FALSE, method = "route start points as USGS publishes them; agency coordinates are kept as published under E7"),
    covariateNote = paste0("obs_nonbreeder_count: the non-breeder count in this block; ", nb_flag(runs), ". obs_block_stops: stops of the block up to K (1 to 10), 1997 on; NA before.", CODES_NOTE),
    designNote = "Five blocks per run at most; occasion = block. Blocks past the last stop with evidence of sampling have no row.",
    components = c(cnt, sib),
    notShipped = list(
      runs_outside_the_design = if (length(all15) == n) sprintf("none: all %d runs of BCR 15 are RPID 101 on a Detail 1 or 2 route and are in this table", n) else
        sprintf("%d of the %d runs in BCR 15 are not RPID 101 on a Detail 1 or 2 route (Detail 3: %d); they are in the count table", length(all15) - n, length(all15), sum(W$detail[all15] == 3L)),
      blocks_after_last_stop_with_evidence = sprintf("%s blocks of this table's runs, past ceiling(K/10) from 1997 or past the last non-zero block before 1997", nice(dropped_blocks)),
      TotalSpp = "per-run count of breeding records; an assertion; not shipped",
      StopTotal = sprintf("per-taxon number of stops with the taxon; impossible in %d records before 1997 nationally; not shipped", N_BAD_STOPTOTAL),
      stop_level_counts = "shipped for 2009 on in ziolkowski_2026_bbs_bcr15_stop; before 2009 for size"),
    notes = NOTES_COMMON(runs, c(
      "Block table: the 50-stop data are complete only from 1997 (86,210 of 86,210 runs from 1997; 293 before), so blocks before 1997 come from States and MigrantSummary and obs_block_stops is NA there; stop_data_complete in __periods says which years.",
      "Several runs of one route-year: this table keeps RPID 101 only, so each route-year has one run and occasion is the block.")))
  dataset <- Filter(Negate(is.null), dataset)
  ds <- write_table(long, name, dataset, taxa = taxa, periods = periods, units = units, script = SCRIPT)
  stage_dict_row(name,
    description = sprintf("Five 10-stop block counts of %d bird taxa on %s standard Breeding Bird Survey runs of %d routes in Bird Conservation Region 15 (Sierra Nevada), %d-%d, blocks past the last stop with evidence of sampling omitted; date, observer, weather and non-breeder part of the count; route coordinates in __units.", m, nice(n), n_u, yrs[1], yrs[2]),
    url = "https://doi.org/10.5066/P144YU3S", reference = CITATION, doi_paper = "", doi_data = "10.5066/P144YU3S",
    original_license = ORIGINAL_LICENSE, derived_license = "CC0 1.0",
    notes = "Survey set inferred: blocks up to the last stop with a bird, car or noise record (from 1997) or the last non-zero block (before). Blocks are spatial, not temporal, replicates. Raw files downloaded by hand (ScienceBase refuses direct downloads), sha256 asserted.",
    source_via = "USGS ScienceBase (downloaded by hand 2026-11-04)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture (spatial replicates: blocks along a route; closure not met)", sampling_protocol = "point_count",
    design = "Multi-season (annual runs; five consecutive 10-stop blocks per run as spatial replicates)", realm = "Terrestrial", country = countries_of(runs),
    coordinates = "As published (USGS route start points, kept as published)", notes = "Pilot region for replicated counts; survey set inferred from stop-level evidence.")
  rm(long); gc(FALSE)
  invisible(list(rows = S * m))
}

build_stop <- function() {
  name <- "ziolkowski_2026_bbs_bcr15_stop"; sib <- "ziolkowski_2026_bbs_bcr15_block"; cnt <- "ziolkowski_2026_bbs_bcr15_count"
  runs <- STOP_RUNS; n <- length(runs)
  all15 <- which(W$bcr == 15L)
  br <- list(run = unlist(lapply(keep, `[[`, "run")), tax = unlist(lapply(keep, `[[`, "tax")), M = do.call(rbind, lapply(keep, `[[`, "M")))
  sst <- which(W$bcr[ST$run] == 15L & W$rpid[ST$run] == 101L & W$detail[ST$run] %in% 1:2 & W$year[ST$run] >= 2009L)
  sms <- which(W$bcr[MS$run] == 15L & W$rpid[MS$run] == 101L & W$detail[MS$run] %in% 1:2 & W$year[MS$run] >= 2009L)
  chk(setequal((br$run - 1L) * NTAX + br$tax, ST$key[sst]), "stop table: 50-stop records = breeding records of its runs")
  chk(!any(MS$key[sms] %in% ST$key[sst]), "stop table: none of its runs has a taxon in both the breeding and non-breeder files")
  chk(all(MS$key[sms] %in% MG$key) && length(sms) == sum(is_stop_run[MG$run]), "stop table: every non-breeder record of its runs has a Migrants record")
  sg <- is_stop_run[MG$run]; nmr <- list(run = MG$run[sg], tax = MG$tax[sg], M = MG$M[sg, , drop = FALSE])
  pool <- sort(unique(c(br$tax, nmr$tax))); m <- length(pool)
  Kr <- K[runs]; off <- cumsum(c(0, Kr))[seq_len(n)]; S <- sum(Kr)
  rpos <- match(seq_len(NRUN), runs)
  y <- integer(S * m); nbv <- integer(S * m)
  put <- function(d, arr_is_nb) {
    ri <- rpos[d$run]; pj <- match(d$tax, pool)
    w <- which(d$M > 0L, arr.ind = TRUE); v <- d$M[w]
    chk(all(w[, 2] <= Kr[ri[w[, 1]]]), "every non-zero stop count lies at or before K")
    pos <- (off[ri[w[, 1]]] + w[, 2] - 1) * m + pj[w[, 1]]
    y[pos] <<- y[pos] + v
    if (arr_is_nb) nbv[pos] <<- v
    sum(as.numeric(d$M))
  }
  tot_br <- put(br, FALSE); tot_nb <- put(nmr, TRUE)
  chk(tot_br == sum(as.numeric(ST$spp[sst])) && tot_nb == sum(as.numeric(MS$spp[sms])) && sum(as.numeric(y)) == tot_br + tot_nb, "stop table: sum(y) = breeding + non-breeder SpeciesTotal of its runs")
  chk(sum(as.numeric(y) - nbv) == tot_br, "stop table: y - obs_nonbreeder_count = published breeding total")
  rr <- rep(seq_len(n), times = Kr); sp <- sequence(Kr)
  lvl <- run_level(runs)[rr]; lvl[, occasion := sp]
  vmap <- integer(NRUN); vmap[ve_run] <- seq_along(ve_run); vrow <- vmap[runs]; vrow[vrow == 0L] <- NA_integer_
  car <- noise <- rep(NA_integer_, length(rr))
  has <- !is.na(vrow[rr]); vr_i <- vrow[rr][has]; sp_i <- sp[has]
  carv <- VE_CAR[cbind(vr_i, sp_i)]; noisev <- VE_NOI[cbind(vr_i, sp_i)]
  recd <- VE_REC[vr_i] == "1"
  car[has] <- fifelse(recd | carv > 0L, carv, NA_integer_); noise[has] <- noisev
  lvl[, `:=`(obs_cars = car, obs_noise = noise)]
  long <- dense_long(lvl, TAXON[pool], y, nbv)
  chk(nrow(long) == S * m, "stop table: rows = stops with evidence x pool")
  rm(y, nbv, lvl); gc(FALSE)
  taxa <- MASTER[taxon %in% TAXON[pool]]; setorder(taxa, taxon)
  units <- units_table(runs); periods <- periods_table(runs)
  dates <- range(W$date[runs]); yrs <- range(W$year[runs]); n_u <- uniqueN(W$unit[runs])
  dropped_stops <- sum(50L - Kr)
  dataset <- list(
    title = sprintf("North American Breeding Bird Survey, BCR 15, Sierra Nevada: stop counts of %d bird taxa on %d routes, %d-%d", m, n_u, yrs[1], yrs[2]),
    creator = CREATOR, pubDate = "2026-05-28", doi = "10.5066/P144YU3S", sourceURL = "https://doi.org/10.5066/P144YU3S", citation = CITATION,
    intellectualRights = RIGHTS,
    abstract = sprintf("The standard runs (RPID 101) of the 50-stop routes of Bird Conservation Region 15 (Sierra Nevada; %s), %d-%d, one row per run, stop and bird taxon: y is the count at that stop (breeding-category plus non-breeder records), zero for each of the %d taxa recorded in these runs and not seen at the stop. Stops after the last stop with evidence of sampling have no row. Vehicle and noise records per stop come with it. Stops are sequential points about 800 m apart, counted once in one morning, not temporal repeats.",
                       paste(states_of(runs), collapse = ", "), yrs[1], yrs[2], m),
    samplingProtocol = "North American Breeding Bird Survey: a 3-minute point count of all birds seen within 400 m or heard at each of up to 50 stops per route; the stop-level record exists for every run from 1997, here from 2009.",
    samplingProtocolCode = "point_count", surveyEvidence = "inferred", responseType = "count", unitKind = "site",
    closure = paste("period = year (index year - 1965); occasion = stop number along the route (1 to the last stop with evidence).", STOP_GEOMETRY, "Across years a route's rows are not a closed population."),
    surveyEvidenceNote = "Weather.csv lists every run but no file says how many stops a run sampled. Evidence that a stop was sampled: a bird record in 50-StopData or Migrants, or Car > 0 or Noise > 0 in VehicleData. K = the last stop with evidence; stops 1 to K are surveys, and a zero at an empty stop before K is fair because the observer went on past it. Stops after K have no row and their number is in notShipped. A mid-route skip inside a run cannot be seen in this deposit, so a stop zero there could be unsupported; nationally obs_quality_current = 0 marks more than 85% of runs from 1997 with K below 45. Pool: every taxon recorded in this table's runs, in the breeding or the non-breeder stop files.",
    temporalCoverage = sprintf("%s/%s", dates[1], dates[2]),
    geographicCoverage = cover(15L, runs), crs = "EPSG:4269 (NAD83)",
    coordinatesCoarsened = list(value = FALSE, method = "route start points as USGS publishes them; agency coordinates are kept as published under E7"),
    covariateNote = paste0("obs_nonbreeder_count: the recorded non-breeder count at the stop, 0 where none. obs_cars: the vehicle count at the stop where RecordedCar = 1 (the metadata: recorded at all sampled stops) or Car > 0, else NA, because the metadata makes no promise for a 0 there. obs_noise: 1 if excessive noise from sources other than passing vehicles (more than 45 seconds, interfering with hearing birds) was recorded at the stop, 0 if not, NA where the run has no VehicleData row.", CODES_NOTE),
    designNote = "One row per run, stop and taxon; occasion = stop. Stops past the last stop with evidence of sampling have no row.",
    components = c(cnt, sib),
    notShipped = list(
      runs_outside_the_design = sprintf("%d of the %d runs in BCR 15 are outside this table: %d before 2009 and %d from 2009 that are not RPID 101 on a Detail 1 or 2 route; they are in the count table",
                                        length(all15) - n, length(all15), sum(W$year[all15] < 2009L), sum(W$year[all15] >= 2009L) - n),
      stops_after_last_stop_with_evidence = sprintf("%s stops of this table's runs, past K", nice(dropped_stops)),
      stop_rows_before_2009 = "stop-level rows of BCR 15 before 2009 are in the deposit and not shipped, for size; the block table covers all years",
      TotalSpp = "per-run count of breeding records; an assertion; not shipped",
      StopTotal = "per-taxon number of stops with the taxon; derivable from y; not shipped"),
    notes = NOTES_COMMON(runs, c(
      "Stop table: runs from 2009 on, so non-breeder records are preserved throughout (obs_nonbreeder_count is 0 where none) and stop data are complete.")))
  dataset <- Filter(Negate(is.null), dataset)
  ds <- write_table(long, name, dataset, taxa = taxa, periods = periods, units = units, script = SCRIPT)
  stage_dict_row(name,
    description = sprintf("Stop-level counts of %d bird taxa on %s standard Breeding Bird Survey runs of %d routes in Bird Conservation Region 15 (Sierra Nevada), %d-%d, stops past the last stop with evidence of sampling omitted; vehicle and noise per stop, date, observer and weather; route coordinates in __units.", m, nice(n), n_u, yrs[1], yrs[2]),
    url = "https://doi.org/10.5066/P144YU3S", reference = CITATION, doi_paper = "", doi_data = "10.5066/P144YU3S",
    original_license = ORIGINAL_LICENSE, derived_license = "CC0 1.0",
    notes = "Survey set inferred: stops up to the last stop with a bird, car or noise record. Stops are sequential spatial points, not temporal replicates. Raw files downloaded by hand (ScienceBase refuses direct downloads), sha256 asserted.",
    source_via = "USGS ScienceBase (downloaded by hand 2026-11-04)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture (spatial replicates: stops along a route; closure not met)", sampling_protocol = "point_count",
    design = "Multi-season (annual runs; consecutive stops along the route as spatial replicates)", realm = "Terrestrial", country = countries_of(runs),
    coordinates = "As published (USGS route start points, kept as published)", notes = "Pilot region for stop-level counts; survey set inferred from stop-level evidence.")
  rm(long); gc(FALSE)
  invisible(list(rows = S * m))
}
if (DO_SET_B) {
  r <- build_block(); say("BCR 15 block table done: %s rows", nice(r$rows))
  r <- build_stop();  say("BCR 15 stop table done: %s rows", nice(r$rows))
}
say("done")
