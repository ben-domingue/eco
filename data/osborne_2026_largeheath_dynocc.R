#!/usr/bin/env Rscript
# Table:  osborne_2026_largeheath_dynocc
# Source: Manchester Metropolitan University research repository (figshare), doi:10.83056/mmu.33070517.v1,
#         version 1 (published 2026-07-24), licence ODC-By 1.0 (Open Data Commons Attribution) as shown on the
#         record and in the README (asserted from the figshare API). Osborne, A. W., Marsden, S., Griffiths, S. M.,
#         Caporn, S. J. M. & Coulthard, E. Multi-year occupancy and habitat use in a threatened butterfly
#         reintroduced onto a restored peatland [Dataset].
# Paper:  Osborne, A. W. et al. (2026). Multi-year occupancy and habitat use in a threatened butterfly reintroduced
#         onto a restored peatland. Restoration Ecology (in press per the README; not read). Design from the record
#         description: Large Heath (Coenonympha tullia) surveyed repeatedly each year 2021-2025 in 380 nine-metre
#         square compartments ('sites') of a restored lowland bog; multi-season occupancy (unmarked colext).
# Data:   y_LHB_Detections.csv: rows 'Individuals' and 'Detections' (whole-site totals per visit), 'DayOfMonth', then
#           380 sites; columns V21.01-V25.25 = 25 visit slots per year; cell = 1 if the butterfly was detected
#           at the site on the visit (0/1 only, asserted; the README calls it a record of detections), NA = site not surveyed on that visit (whole slots are NA where fewer than 25
#           visits were made in a year).
#         obsCovs_AirTemp.csv, obsCovs_5DayTemp.csv: air temperature at the visit and mean air temperature of the 5
#           days before, the same slots plus a 26th slot per year (and two unnamed columns) that the authors' script
#           drops by position; DfPeakPres.csv / DfPeakDets.csv: days of the visit from the peak of butterfly presence /
#           of detections across the whole site.
#         siteCovs.csv: UTM northing / easting, cover and counts of Eriophorum vaginatum (hare's-tail cottongrass)
#           and Erica tetralix (cross-leaved heath), and C.tullia_Count / C.tullia_Pres / Presence (summaries of the
#           detections). siteCovs_SiteCentroidDist.csv: distance (m) from the colony centroid.
#         Site ids: compartment 17 is 'site1.17' in the detection and visit-covariate files and 'site1.017' in
#           siteCovs; ids are padded to three digits (asserted at row 17).
#         Multiseason_LHB_5Y_umdf.R: the authors' unmarkedMultFrame build (rows 4-383 of y; sites 1-380 of covs).
# Mapping (dynamic occupancy; responseType detection, unitKind site): unit = Site, taxon = COETUL, period = year
#   1..5 (2021-2025), occasion = visit slot 1..25 within the year, y = the deposited 0/1. surveyEvidence = deposited_matrix (NA = not surveyed). obs_day_of_month (the
#   deposit gives the day of month only, no month, so there is no date column), obs_air_temp_c, obs_5day_temp_c,
#   obs_days_from_peak_presence, obs_days_from_peak_detections (computed by the authors from the whole site's
#   detections and visit dates; they carry the visit timing the deposit otherwise lacks). unit_ habitat covariates
#   and unit_centroid_dist_m.
#   Coordinates (E7; re-checked in batch 46, #10, under the 2026-11-06 wording of (a), where a word in a paper's title
#   is not enough): the deposit's own text about the data, the README summary (and the identical record description),
#   states the aim as monitoring "a reintroduction programme for the threatened Large Heath butterfly Coenonympha
#   tullia" (asserted), so the source says the taxon is threatened in its own text about the data and (a) still holds
#   (it is IUCN LC globally). The projected UTM pair is snapped to the centre of its 10 km cell (E7 scope 1,
#   floor(x / 10000) * 10000 + 5000, uncertainty 7,071 m). The
#   compartments' relative layout is not shipped; the distance from the colony centroid is.
# Not shipped: the 'Individuals' and 'Detections' total rows and siteCovs' C.tullia_Count / C.tullia_Pres / Presence
#   (summaries of the detections); the 26th temperature slot of each year and the two unnamed columns (no visit);
#   exact compartment coordinates (E7); model code and estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "osborne_2026_largeheath_dynocc"
api <- download_cached("https://api.figshare.com/v2/articles/33070517", TABLE, filename = "figshare_article.json")
meta <- fromJSON(api)
stopifnot(identical(meta$license$name, "ODC-By"), identical(meta$doi, "10.83056/mmu.33070517.v1"))
fid <- setNames(as.character(meta$files$id), meta$files$name)
get <- function(n) download_cached(paste0("https://ndownloader.figshare.com/files/", fid[[n]]), TABLE, filename = n)
rd <- function(n) { d <- fread(get(n), na.strings = c("NA", ""), encoding = "UTF-8"); setnames(d, 1, "Site"); d }
# site ids: 'site1.17' in some files is 'site1.017' in siteCovs (a dropped leading zero); pad the number to 3 digits
norm <- function(s) { s <- tolower(s); k <- grepl("^site[12]\\.[0-9]+$", s)
  s[k] <- sprintf("%s.%03d", sub("\\..*$", "", s[k]), as.integer(sub("^.*\\.", "", s[k]))); s }
stopifnot(any(grepl("ODC_BY Open Data Commons Attribution", readLines(get("README_MultiSeasonOccupancy.txt"), warn = FALSE), useBytes = TRUE)))
# E7 (a): the README's summary calls the species threatened in the deposit's own text (not only in the title)
stopifnot(any(grepl("reintroduction programme for the threatened Large Heath butterfly", readLines(get("README_MultiSeasonOccupancy.txt"), warn = FALSE), useBytes = TRUE)))

slots <- sprintf("V%d.%02d", rep(21:25, each = 25), rep(1:25, 5))
y <- rd("y_LHB_Detections.csv")
stopifnot(identical(names(y), c("Site", slots)), identical(y$Site[1:3], c("Individuals", "Detections", "DayOfMonth")), nrow(y) == 383L)
dom <- as.integer(unlist(y[3, -1])); y <- y[-(1:3)]
stopifnot(sum(y$Site == "site1.17") == 1L, which(y$Site == "site1.17") == 17L, !"site1.017" %in% y$Site)
y[, Site := norm(Site)]
stopifnot(nrow(y) == 380L, !anyDuplicated(y$Site), all(grepl("^site[12]\\.[0-9]+$", y$Site)))
Y <- as.matrix(y[, -1]); storage.mode(Y) <- "integer"
stopifnot(all(Y %in% c(0L, 1L, NA)), sum(!is.na(Y)) == 27508L, sum(Y, na.rm = TRUE) == 283L)
# a visit slot with any site surveyed has a day of month; empty slots have none
used <- colSums(!is.na(Y)) > 0
stopifnot(identical(!is.na(dom), unname(used)), identical(as.vector(tapply(used, rep(1:5, each = 25), sum)), c(19L, 23L, 20L, 9L, 13L)))

ob <- function(n, rows_have_dom = TRUE) {
  d <- rd(n); if (rows_have_dom) { stopifnot(d$Site[1] == "DayOfMonth"); d <- d[-1] }
  stopifnot(identical(norm(d$Site), y$Site), all(slots %in% names(d)))
  m <- as.matrix(d[, slots, with = FALSE]); storage.mode(m) <- "double"; m }
AT <- ob("obsCovs_AirTemp.csv"); FT <- ob("obsCovs_5DayTemp.csv", FALSE)
PP <- ob("DfPeakPres.csv"); PD <- ob("DfPeakDets.csv")
sc <- rd("siteCovs.csv"); cd <- rd("siteCovs_SiteCentroidDist.csv")
stopifnot(identical(norm(sc$Site), y$Site), identical(norm(cd$Site), y$Site),
          nrow(sc) == 380L)

long <- rbindlist(lapply(seq_along(slots), function(j) {
  if (!used[j]) return(NULL)
  k <- !is.na(Y[, j])
  data.table(unit = y$Site[k], taxon = "COETUL", y = Y[k, j],
             period = (j - 1L) %/% 25L + 1L, occasion = (j - 1L) %% 25L + 1L,
             obs_day_of_month = dom[j], obs_air_temp_c = AT[k, j], obs_5day_temp_c = FT[k, j],
             obs_days_from_peak_presence = PP[k, j], obs_days_from_peak_detections = PD[k, j]) }))
cx <- floor(sc$UTM_Easting / 10000) * 10000 + 5000; cy <- floor(sc$UTM_Northing / 10000) * 10000 + 5000
cat(sprintf("  10 km cells: %d\n", uniqueN(paste(cx, cy))))
uc <- sc[, .(unit = Site, unit_x = cx, unit_y = cy, unit_coordinateUncertaintyInMeters = 7071,
             unit_eriovag_cover = E.v_Cover, unit_eriovag_tussock_count = E.v_TussockCount,
             unit_eriovag_nearest_tussock = E.v_NearestTussock, unit_eriovag_closest_tussocks = E.v_ClosestTussocks,
             unit_erictet_cover = E.t_Cover, unit_erictet_shrub_count = E.t_ShrubCount,
             unit_erictet_nearest_shrub = E.t_NearestShrub, unit_erictet_closest_shrubs = E.t_ClosestShrubs,
             unit_eriovag_to_erictet_dist = E.v_to_E.t_Distance, unit_eriovag_presence = E.v_Presence,
             unit_erictet_presence = E.t_Presence, unit_both_presence = E.t_plus_E.v_Presence)]
uc[, unit_centroid_dist_m := cd$Centroid.Dist]
long <- merge(long, uc, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(Y)), sum(long$y) == 283L, uniqueN(long$unit) == 380L)
cat(sprintf("  %d rows (site-visits), %d with a detection\n", nrow(long), sum(long$y)))

taxa <- make_taxa("COETUL", "Coenonympha tullia", vernacularName = "Large Heath")
periods <- data.table(period = 1:5, year = 2021:2025, n_visits = as.integer(tapply(used, rep(1:5, each = 25), sum)))

dataset <- list(
  title = "Repeated visit detections of the reintroduced Large Heath butterfly in 380 compartments of a restored lowland bog, north-west England, 2021-2025",
  creator = "Osborne, Andrew W.; Marsden, Stuart; Griffiths, Sarah M.; Caporn, Simon J. M.; Coulthard, Emma", pubDate = "2026",
  doi = "10.83056/mmu.33070517.v1", sourceURL = "https://doi.org/10.83056/mmu.33070517.v1",
  citation = "Osborne, A. W., Marsden, S., Griffiths, S. M., Caporn, S. J. M., & Coulthard, E. (2026). Multi-year occupancy and habitat use in a threatened butterfly reintroduced onto a restored peatland [Dataset]. Manchester Metropolitan University. https://doi.org/10.83056/mmu.33070517.v1",
  intellectualRights = list(spdx = "ODC-By-1.0", url = "https://opendatacommons.org/licenses/by/1-0/"),
  abstract = "Large Heath butterflies (Coenonympha tullia) reintroduced onto a restored lowland bog were surveyed on 9 to 23 visits each flight season 2021-2025 in 380 nine-metre compartments; detection per compartment and visit, with air temperature, days from the site-wide peak, and cover of the larval and nectar plants Eriophorum vaginatum and Erica tetralix. The authors fitted multi-season occupancy models of the reintroduction.",
  samplingProtocol = "Repeated walked surveys of a grid of 9 x 9 m compartments during the flight season; a sighting of the butterfly in a compartment on a visit is a detection; not every compartment was surveyed on every visit.",
  samplingProtocolCode = "transect_count", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "visits span a flight season of several weeks; the authors fitted colext with closure within a year",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "A restored lowland raised bog in north-west England (UTM zone 30N, 10 km cell centred near 53.4 N, 2.5 W); compartment coordinates coarsened",
  temporalCoverage = "2021/2025",
  crs = "EPSG:32630 (UTM zone 30N assumed: the deposit gives UTM northing and easting without the zone; the values fall in zone 30 over north-west England)",
  coordinatesCoarsened = list(value = TRUE, method = "The deposit's README summary calls the Large Heath threatened in its own text about the data (E7 a; IUCN LC globally); the UTM pair is snapped to the centre of its 10 km cell (E7 ruling 1), uncertainty 7,071 m. unit_centroid_dist_m keeps each compartment's distance from the colony centroid."),
  covariateNote = "obs_day_of_month: day of the month of the visit (month not deposited). obs_air_temp_c, obs_5day_temp_c: air temperature at the visit and mean of the 5 days before. obs_days_from_peak_presence / _detections: days of the visit from the site-wide peak of presence / detections (computed by the authors from all compartments' detections). unit_eriovag_*: Eriophorum vaginatum cover (%), tussock counts and nearest distances; unit_erictet_*: Erica tetralix likewise; *_presence 0/1.",
  notShipped = list(totals = "the 'Individuals' and 'Detections' rows of the detection file (site-wide totals per visit) and siteCovs C.tullia_Count / C.tullia_Pres / Presence (summaries of the detections)",
                    extra_temperature_slots = "a 26th visit slot per year and two unnamed columns in the temperature files, which have no detection slot and which the authors' script drops",
                    exact_coordinates = "compartment UTM coordinates (coarsened, E7)",
                    model_output = "occupancy, colonisation and extinction estimates"),
  notes = "Visit slots with no compartment surveyed have no rows; the deposit gives the day of month of each visit but not the month, so there is no date column.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/osborne_2026_largeheath_dynocc.R")
stage_dict_row(TABLE,
  description = "Detections of the reintroduced Large Heath butterfly on 9-23 visits a year in 380 compartments of a restored lowland bog in north-west England, 2021-2025, with visit temperature, phenology and habitat-plant covariates.",
  url = "https://doi.org/10.83056/mmu.33070517.v1",
  reference = "Osborne, A. W., Marsden, S., Griffiths, S. M., Caporn, S. J. M., & Coulthard, E. (2026). Multi-year occupancy and habitat use in a threatened butterfly reintroduced onto a restored peatland. Restoration Ecology.",
  doi_paper = "", doi_data = "10.83056/mmu.33070517.v1",
  original_license = "ODC-By 1.0 (Open Data Commons Attribution)", derived_license = "ODC-By 1.0",
  notes = "ODC-By proceeds like CC BY (ruling 2026-11-06). y = detection 0/1 as deposited; coordinates coarsened (source calls the species threatened).",
  source_via = "figshare (MMU repository)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Dynamic occupancy",
  sampling_protocol = "transect_count", design = "Multi-season (5 flight seasons, 9-23 visits each; 380 compartments)",
  realm = "Terrestrial", country = "GBR", coordinates = "Coarsened (10 km cell of the source's UTM grid)",
  notes = "Insect reintroduction monitored by multi-season occupancy.")
