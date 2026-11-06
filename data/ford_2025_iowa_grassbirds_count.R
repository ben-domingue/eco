#!/usr/bin/env Rscript
# Table:  ford_2025_iowa_grassbirds_count
# Source: USGS ScienceBase, doi:10.5066/P133ZS4T (item 67a4e037d34e63325c2b7abe), version 1, 2025-02-13. Ford, J. M.
#         and Tucker, A. (2025). Bird point count and vegetation survey data from grassland sites in southern Iowa.
#         U.S. Geological Survey data release. Licence: USGS data release marked CC0 1.0 (ScienceBase; the FGDC record
#         states no access or use constraints).
# Paper:  none named in the release; the study assessed whether northern bobwhite is an umbrella species (FGDC purpose).
# Data:   ford_bird-point-counts_22-23.csv: 10,346 rows, one per species group recorded at a point-visit: Site_ID
#           (site code + year), Point_ID (1-3 points per site), Visit_num (1-3), Site_type (public / private),
#           Practice (management practice), Jul_day (ordinal day), Observer, Wind (mph), Temp (F), Cloud_coverage (%),
#           Species_name, Species_code (alpha code), and 12 count cells: Time.<i>_0_25, _25_50, _>50, _FO = individuals
#           first detected in interval i (1 = minutes 0-2, 2 = 3-5, 3 = 6-8) at 0-25 m, 25-50 m, beyond 50 m, or
#           flying over. A species can have several rows in one point-visit (groups detected separately: 77 rows).
#         ford_veg-surveys_22-23.csv (site-year vegetation and land-cover covariates); ford_metadata.xml (FGDC).
#         Quirks (asserted): one row is an exact duplicate (PABE-22, PABE-2 visit 2, MODO); the whole of point-visit
#         LABE-1 visit 1 2023 is entered twice, identical but for temperature (55.1 and 56.3 F); one row of TML-EF-1
#         2022 visit 3 is entered twice, once under Site_ID TMLE-NGS-22 (16 identical species rows); four alpha codes are typing variants of the species' usual code under the same
#         common name (AMR0, CEWA, EAWO, NOCO), and six rows pair a code with another species' common name (AMRE /
#         American Robin, EAME / Eastern Wood-Pewee, RBGR and RWBL / Red-bellied Woodpecker, RBWO and RHWO /
#         Red-winged Blackbird); 'Unknown' (UNK) is a bird not identified; 9 rows have every cell 0.
# Mapping (repeated counts, community; responseType count): unit = point (Point_ID), cluster_id = site (Point_ID
#   without its point number), taxon = the usual alpha code of the source's common name (the common name is taken as
#   the identification: the code variants and the six code / name mismatches follow the name), period = year
#   (2022 = 1, 2023 = 2), occasion = visit, date = year + Jul_day (an exact date). Repeated rows within a visit
#   (ruling 2026-11-06): one row per taxon per point-visit, y = the total over the species' rows and all 12 cells,
#   and each cell's total ships as obs_n_int<i>_<band> (bands d0_25, d25_50, gt50, flyover), 0 where nothing was
#   recorded. Community: every taxon recorded in the release at every point-visit (taxonInclusion recorded).
#   observer, obs_wind_mph, obs_temp_f, obs_cloud_pct; obs_site_type, obs_practice (recorded on every row and
#   changing between visits at 9 points, so kept at the visit level as deposited).
#   surveyEvidence = inferred: a point-visit exists where the release has a row; the protocol is three visits a
#   year, and 29 point-years have fewer than three, so a visit at which no bird was recorded, if any, is missing.
#   Coordinates: none deposited (points are on public and private land; the FGDC record gives a bounding box only).
# Not shipped: the duplicate row, the second copy of LABE-1 visit 1 2023 (that visit's temperature is NA because the
#   copies disagree) and the copy of TML-EF-1 visit 3 2022 under TMLE-NGS-22 (source errors); the vegetation file (site-year covariates measured once, with land cover from
#   imagery; not a survey record).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ford_2025_iowa_grassbirds_count"
SB <- "https://www.sciencebase.gov/catalog/file/get/67a4e037d34e63325c2b7abe?f=%s"
fx <- download_cached(sprintf(SB, "__disk__26%2F07%2F06%2F2607061192bbaf5cd2146046d79b5ac5de89e88d"), TABLE, filename = "ford_metadata.xml")
fb <- download_cached(sprintf(SB, "__disk__68%2F97%2F6b%2F68976b415fb0b2979de069c9f8d6a9e10ff9cbdb"), TABLE, filename = "ford_bird-point-counts_22-23.csv")
xml <- paste(readLines(fx, warn = FALSE), collapse = " ")
stopifnot(grepl("https://doi.org/10.5066/P133ZS4T", xml, fixed = TRUE), grepl("Johanna M. Ford", xml, fixed = TRUE))
d <- fread(fb, na.strings = "NA", colClasses = list(character = c("Site_ID", "Point_ID", "Observer", "Species_name", "Species_code")))
cells <- grep("^Time\\.", names(d), value = TRUE)
stopifnot(nrow(d) == 10346L, length(cells) == 12L,
          all(d$Visit_num %in% 1:3), all(substr(d$Site_ID, nchar(d$Site_ID) - 2L, nchar(d$Site_ID)) %in% c("-22", "-23")))
band <- c("0_25" = "d0_25", "25_50" = "d25_50", ">50" = "gt50", "FO" = "flyover")
newc <- sprintf("obs_n_int%s_%s", sub("^Time\\.(\\d)_.*$", "\\1", cells), band[sub("^Time\\.\\d_", "", cells)])
setnames(d, cells, newc)
stopifnot(!anyNA(newc))
cells <- newc
stopifnot(all(unlist(d[, ..cells]) >= 0L), !anyNA(d[, ..cells]))
# source errors: one exact duplicate row; one point-visit entered twice (identical except temperature)
stopifnot(sum(duplicated(d)) == 1L)
d <- unique(d)
lb <- d[Site_ID == "LABE-23" & Point_ID == "LABE-1" & Visit_num == 1L]
stopifnot(nrow(lb) == 32L, setequal(lb$Temp, c(55.1, 56.3)),
          fsetequal(lb[Temp == 55.1, !"Temp"], lb[Temp == 56.3, !"Temp"]), nrow(unique(lb[, !"Temp"])) == 16L)
d <- d[!(Site_ID == "LABE-23" & Point_ID == "LABE-1" & Visit_num == 1L & Temp == 56.3)]
d[Site_ID == "LABE-23" & Point_ID == "LABE-1" & Visit_num == 1L, Temp := NA_real_]
d[, year := 2000L + as.integer(substr(Site_ID, nchar(Site_ID) - 1L, nchar(Site_ID)))]
# point-visit TML-EF-1 2022 visit 3 is entered twice, once under its own site and once under TMLE-NGS-22
tm <- d[Point_ID == "TML-EF-1" & year == 2022L & Visit_num == 3L]
stopifnot(nrow(tm) == 32L, setequal(tm$Site_ID, c("TML-EF-22", "TMLE-NGS-22")),
          fsetequal(tm[Site_ID == "TML-EF-22", .SD, .SDcols = !c("Site_ID", "Site_type", "Practice")],
                    tm[Site_ID == "TMLE-NGS-22", .SD, .SDcols = !c("Site_ID", "Site_type", "Practice")]))
d <- d[!(Point_ID == "TML-EF-1" & Site_ID == "TMLE-NGS-22")]
d[, site := sub("-[0-9]+$", "", Point_ID)]
# visit covariates: one value per point-visit
vk <- c("Point_ID", "year", "Visit_num")
vis <- unique(d[, .(Point_ID, site, year, Visit_num, Jul_day, Observer, Wind, Temp, Cloud_coverage, Site_type, Practice)])
stopifnot(!anyDuplicated(vis[, ..vk]), !anyNA(vis$Jul_day), !anyNA(vis$Observer))
# ownership and practice are recorded per visit and change between visits of 9 points (as deposited): obs_ columns
cat(sprintf("  points whose Site_type or Practice changes between visits: %d\n",
            vis[, .(n = uniqueN(paste(Site_type, Practice))), by = Point_ID][n > 1L, .N]))
py <- vis[, .N, by = .(Point_ID, year)]
cat(sprintf("  %d point-visits, %d points, %d point-years (%d with fewer than 3 visits)\n", nrow(vis), uniqueN(vis$Point_ID), nrow(py), sum(py$N < 3L)))
stopifnot(nrow(vis) == 605L, sum(py$N < 3L) == 29L)

# taxa: the source's common name is the identification; its usual code is the taxon code
d[, code := toupper(Species_code)]
usual <- d[, .N, by = .(Species_name, code)][order(-N)][!duplicated(Species_name), .(Species_name, taxon = code)]
d <- merge(d, usual, by = "Species_name")
variants <- unique(d[code != taxon, .(code, taxon, Species_name)])
print(d[code != taxon, .N, by = .(code, taxon)])
stopifnot(nrow(d[code != taxon]) == 13L, setequal(variants$code, c("AMR0", "CEWA", "EAWO", "NOCO", "AMRE", "EAME", "RBGR", "RWBL", "RBWO", "RHWO")),
          !anyDuplicated(usual$taxon), usual[Species_name == "Unknown", taxon] == "UNK")
cat("  codes following the common name:", paste(sprintf("%s->%s", variants$code, variants$taxon), collapse = ", "), "\n")

# repeated rows within a visit: the cells summed per point-visit x taxon (ruling 2026-11-06)
agg <- d[, lapply(.SD, sum), by = .(Point_ID, year, Visit_num, taxon), .SDcols = newc]
cat(sprintf("  %d species rows -> %d point-visit x taxon records (%d repeats summed)\n", nrow(d), nrow(agg), nrow(d) - nrow(agg)))
tx <- sort(unique(d$taxon))
grid <- CJ(k = seq_len(nrow(vis)), taxon = tx)
grid[, `:=`(Point_ID = vis$Point_ID[k], year = vis$year[k], Visit_num = vis$Visit_num[k])]
long <- merge(grid, agg, by = c("Point_ID", "year", "Visit_num", "taxon"), all.x = TRUE)
for (c in newc) set(long, which(is.na(long[[c]])), c, 0L)
long[, y := as.integer(rowSums(.SD)), .SDcols = newc]
long <- merge(long, vis, by = vk)
yrs <- 2022:2023
long <- long[, c(list(unit = Point_ID, taxon = taxon, y = y, period = match(year, yrs), occasion = Visit_num,
                 date = format(as.IDate(sprintf("%d-01-01", year)) + Jul_day - 1L), cluster_id = site, observer = Observer,
                 obs_site_type = Site_type, obs_practice = Practice, obs_wind_mph = Wind, obs_temp_f = Temp,
                 obs_cloud_pct = Cloud_coverage), .SD), .SDcols = newc]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(vis) * length(tx), sum(long$y) == sum(as.matrix(d[, ..newc])))
cat(sprintf("  %s rows = %d point-visits x %d taxa; %d birds\n", format(nrow(long), big.mark = ","), nrow(vis), length(tx), sum(long$y)))

ibp <- fread(download_cached("https://raw.githubusercontent.com/trashbirdecology/bbsAssistant/main/data-raw/IBP-AOS-LIST21.csv", TABLE, filename = "IBP-AOS-LIST21.csv"), fill = TRUE)
ibp <- ibp[is.na(SP) | SP == ""]
norm <- function(s) gsub("[^a-z]", "", tolower(s))
nm <- usual[taxon != "UNK"]
i <- match(norm(nm$Species_name), norm(ibp$COMMONNAME))
stopifnot(!anyNA(i))
nm[, `:=`(sci = ibp$SCINAME[i], ibp_code = ibp$SPEC[i])]
# the source's code for Carolina Wren is CAWR (IBP: CARW); kept as the source writes it
stopifnot(identical(nm[taxon != ibp_code, taxon], "CAWR"))
taxa <- make_taxa(c(nm$taxon, "UNK"), c(nm$sci, "Aves"), vernacularName = c(nm$Species_name, "Unknown bird"),
                  taxonRank = c(rep("species", nrow(nm)), "class"), allow_higher = "UNK",
                  taxonRemarks = c(rep(NA_character_, nrow(nm)), "source code UNK ('Unknown'): a bird not identified"))
taxa <- taxa[match(tx, taxon)]
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa[taxon_iucnCategory %in% c("CR", "EN", "VU", "NT"), .(taxon, scientificName, taxon_iucnCategory)])
periods <- data.table(period = 1:2, year = yrs, n_point_visits = vis[, .N, keyby = year]$N)

dataset <- list(
  title = sprintf("Point counts of birds at %d points on %d grassland sites managed for northern bobwhite in southern Iowa, 2022-2023, with time-interval and distance cells", uniqueN(long$unit), uniqueN(long$cluster_id)),
  creator = "Ford, Johanna M.; Tucker, Anna", pubDate = "2025", doi = "10.5066/P133ZS4T", sourceURL = "https://doi.org/10.5066/P133ZS4T",
  citation = "Ford, J.M., and Tucker, A., 2025, Bird point count and vegetation survey data from grassland sites in southern Iowa: U.S. Geological Survey data release, https://doi.org/10.5066/P133ZS4T.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
  abstract = "Nine-minute point counts at 1-3 points per site on grassland sites in southern Iowa where a management practice for northern bobwhite had recently been implemented (native grass seeding, edge feathering, tree and shrub establishment, field borders and others), each point visited three times between 15 May and 31 July in 2022 and 2023. Each bird is recorded by the interval (minutes 0-2, 3-5, 6-8) and distance band (0-25 m, 25-50 m, beyond 50 m, flyover) of its first detection.",
  samplingProtocol = "Nine-minute point count at a station (points at least 200 m apart), all birds recorded by the three-minute interval and the distance band (0-25 m, 25-50 m, >50 m, flyover) in which they were first detected; three visits per point between 15 May and 31 July each year; wind, temperature and cloud cover recorded.",
  samplingProtocolCode = "point_count", surveyEvidence = "inferred",
  surveyEvidenceNote = "A point-visit exists where the release has at least one bird row; the protocol is three visits per point-year and 29 point-years have fewer than three in the release, so a visit at which no bird was recorded (if any happened) is missing.",
  responseType = "count", unitKind = "site", closure = "closed",
  closureNote = "occasion = visit (three between mid-May and July); period = year; closure within the breeding season as in the study's occupancy and abundance design",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Grassland sites in southern Iowa, USA (no point coordinates deposited)",
                            boundingBox = list(west = -94.4659, east = -92.4994, south = 40.5722, north = 41.3149)),
  temporalCoverage = sprintf("%s/%s", min(long$date), max(long$date)),
  covariateNote = "obs_n_int<i>_<band>: individuals first detected in interval i (1 = minutes 0-2, 2 = 3-5, 3 = 6-8) in band d0_25 (0-25 m), d25_50 (25-50 m), gt50 (beyond 50 m) or flyover; y is their sum. obs_site_type: public or private land, and obs_practice: the management practice, as recorded at the visit (they change between visits at 9 points). obs_wind_mph, obs_temp_f, obs_cloud_pct: weather at the visit.",
  distanceBreaks = list(units = "m", breaks = c(0, 25, 50), note = "a third band beyond 50 m (unbounded) and a flyover category are also recorded"),
  notes = "Repeated rows within a visit (ruling 2026-11-06): a species recorded on several rows of a point-visit (groups detected separately) has one row, y the total over its rows and all 12 interval x band cells; each cell's total is an obs_n_ column, so interval, removal and distance models can rebuild the cells. Cells: interval 1-3 = minutes 0-2, 3-5, 6-8; bands 0-25 m, 25-50 m, beyond 50 m, flyover. Taxa follow the source's common names: four code variants (AMR0, CEWA, EAWO, NOCO) and six rows whose code names another species follow the name. UNK is an unidentified bird.",
  notShipped = list(duplicates = "one exact duplicate row (PABE-2, 2022 visit 2, MODO) and the second copy of LABE-1 2023 visit 1 (all 16 species rows repeated, temperature 56.3 F against 55.1 F; that visit's temperature is NA), and the copy of TML-EF-1 2022 visit 3 filed under site TMLE-NGS-22 (16 species rows identical to the one under TML-EF-22): source errors",
                    vegetation = "ford_veg-surveys_22-23.csv: site-year vegetation and land-cover covariates (not fetched by this script; measured once per site-year)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ford_2025_iowa_grassbirds_count.R")
stage_dict_row(TABLE,
  description = "Bird point counts at grassland sites managed for northern bobwhite in southern Iowa, three visits a year in 2022-2023, with counts by three-minute interval and distance band of first detection.",
  url = "https://doi.org/10.5066/P133ZS4T", reference = "", doi_paper = "", doi_data = "10.5066/P133ZS4T",
  original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
  notes = "Repeated species rows within a visit summed (ruling 2026-11-06), interval x band cells as obs_ columns.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community abundance (repeated counts; removal / distance cells)",
  sampling_protocol = "point_count", design = "Multi-season (2 years x 3 visits)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Interval x distance-band cells as obs_ columns.")
