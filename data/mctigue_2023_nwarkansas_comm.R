#!/usr/bin/env Rscript
# Table:  mctigue_2023_nwarkansas_comm
# Source: Dryad doi:10.5061/dryad.7m0cfxq1r (CC0 1.0), version 4 (2023-11-29)
#   McTigue, L.E. & DeGregorio, B.A. (2023). Data from: Nine-banded Armadillo occupancy and
#   density across an urban to rural gradient. Dryad.
# Paper:  McTigue, L.E. & DeGregorio, B.A. (2024). Nine-banded Armadillo (Dasypus
#         novemcinctus) occupancy and density across an urban-to-rural gradient.
#         Southeastern Naturalist 23(4), 529-548, doi:10.1656/058.023.0413
# Data:   ..._Occupancy_Data_2023.csv: 38,025 rows, one per wildlife detection (5-minute
#         episode) on a game camera: Camera ID (site name + camera number; 355 cameras across
#         the study sites, with inconsistent site spelling), Date of Detection, Study Year
#         (1 = Dec 2020-Mar 2021, 2 = Nov 2021-Mar 2022), Species (26 labels incl. Person,
#         Unknown, Other, Bird, Mouse, Rat), Number of individuals, Start Date / End Date of
#         that camera's deployment, Week of year, Survey (1-week survey period within the
#         year: 16 in year 1, 22 in year 2), WID. ..._Density_2023.csv: REM density estimates
#         and GIS covariates for 288 cameras at 12 sites -- its Camera IDs do not match the
#         detection file (different site labels), so it is NOT used.
#         Checked: survey periods are consecutive Sunday-start calendar weeks, split at
#         1 January (asserted from the detection dates). The Start/End deployment fields are NOT reliable: 4,349 detections at 67
#         camera-years fall outside their own row's window (e.g. windows dated Jan-Mar 2022
#         on cameras whose detections run Nov-Dec 2021), so they are not used.
#
# Mapping (standard section 3.6, community occupancy from a camera-trap record table):
#   unit = camera, cluster_id = study site (spelling normalised), taxon = species (20
#   taxa identified at least to species; Grey Fox -> Gray Fox, Groundhog -> Woodchuck),
#   period = study year, occasion = survey week, y = 1 if the species was detected in that
#   camera-week, y_raw = number of detection episodes. The operating span of a camera-year
#   is inferred as first to last detection of anything (people and unidentified animals
#   included; deer trigger these cameras almost daily); a camera-week is a survey iff it
#   overlaps that span, so interior weeks with no detection are explicit zeros. Weeks before
#   the first or after the last photo, and cameras that never recorded anything, cannot be
#   recovered from this file (noted in dataset.json). obs_camera_days = days of the week
#   inside the inferred span. Person, Unknown, Other, Bird, Mouse, Rat (not
#   resolved to a taxon) are dropped and logged. No coordinates or covariates shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mctigue_2023_nwarkansas_comm"
dir <- download_dryad("10.5061/dryad.7m0cfxq1r", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
raw <- fread(file.path(dir, "McTigue_and_DeGregorio_Armadillo_Occupancy_Data_2023.csv"), encoding = "UTF-8")
setnames(raw, c("cam", "date", "year", "species", "n", "start", "end", "week", "survey", "wid"))
stopifnot(nrow(raw) == 38025, all(raw$year %in% 1:2), uniqueN(raw$cam) == 355)
for (cc in c("date", "start", "end")) set(raw, j = cc, value = as.IDate(raw[[cc]], "%m/%d/%Y"))
stopifnot(!anyNA(raw$date), !anyNA(raw$start), !anyNA(raw$end))
n_out <- sum(!(raw$date >= raw$start & raw$date <= raw$end)); stopifnot(n_out == 4349)
cat(sprintf("  %d detections fall outside their row's Start/End window: deployment fields not used\n", n_out))
raw[, cam := trimws(cam)]

# survey weeks: Sunday-to-Saturday calendar weeks, split at 1 January (survey 5 of year 1 is
# 27-31 Dec 2020 and survey 6 is 1-2 Jan 2021), exactly as the Week / Survey columns encode
wk <- raw[, .(first = min(date), last = max(date), week = unique(week)), by = .(year, survey)][order(year, survey)]
wk[, sun := first - (wday(first) - 1L)]
wk[, wstart := pmax(sun, as.IDate(sprintf("%d-01-01", year(first))))]
wk[, wend := pmin(sun + 6L, as.IDate(sprintf("%d-12-31", year(first))))]
stopifnot(all(wk$first >= wk$wstart & wk$last <= wk$wend), wk[, .N, by = year][, all(N == c(16L, 22L))])
stopifnot(wk[, all(wstart[-1] == wend[-.N] + 1L), by = year][, all(V1)])    # consecutive, no gaps
stopifnot(all(raw[wk, on = .(year, survey), date >= i.wstart & date <= i.wend]))

# operating span per camera-year = first .. last detection -> surveyed camera-weeks and camera-days
span <- raw[, .(start = min(date), end = max(date)), by = .(cam, year)]
cat(sprintf("  %d camera-years; median operating span %d days\n", nrow(span), as.integer(median(span$end - span$start + 1))))
grid <- merge(span, wk[, .(year, survey, wstart, wend)], by = "year", allow.cartesian = TRUE)
grid[, days := pmax(0L, as.integer(pmin(end, wend) - pmax(start, wstart)) + 1L)]
surveys <- grid[days > 0, .(cam, year, survey, camera_days = days)]
missing_det <- unique(raw[, .(cam, year, survey)])[!surveys, on = .(cam, year, survey)]
stopifnot(nrow(missing_det) == 0)                         # every detection falls in a surveyed camera-week

# taxa
drop <- c("Person", "Unknown", "Other", "Bird", "Mouse", "Rat")
raw[species == "Grey Fox", species := "Gray Fox"]; raw[species == "Groundhog", species := "Woodchuck"]
cat(sprintf("  dropped %d rows not resolved to a taxon: %s\n", sum(raw$species %in% drop), paste(drop, collapse = ", ")))
det <- raw[!species %in% drop]
species <- data.table(label = c("White-tailed Deer", "Gray Squirrel", "Raccoon", "Armadillo", "Cottontail", "Opossum", "Coyote", "Fox Squirrel",
                                "Chipmunk", "Dog", "Bobcat", "Gray Fox", "Cat", "Red Fox", "Striped Skunk", "Wild Hog", "Woodchuck", "Beaver"),
                      taxon = c("ODOVIR", "SCICAR", "PROLOT", "DASNOV", "SYLFLO", "DIDVIR", "CANLAT", "SCINIG", "TAMSTR", "CANFAM", "LYNRUF",
                                "UROCIN", "FELCAT", "VULVUL", "MEPMEP", "SUSSCR", "MARMON", "CASCAN"),
                      scientificName = c("Odocoileus virginianus", "Sciurus carolinensis", "Procyon lotor", "Dasypus novemcinctus", "Sylvilagus floridanus",
                                         "Didelphis virginiana", "Canis latrans", "Sciurus niger", "Tamias striatus", "Canis familiaris", "Lynx rufus",
                                         "Urocyon cinereoargenteus", "Felis catus", "Vulpes vulpes", "Mephitis mephitis", "Sus scrofa", "Marmota monax", "Castor canadensis"))
stopifnot(setequal(det$species, species$label))
det <- merge(det, species, by.x = "species", by.y = "label")
counts <- det[, .(episodes = .N), by = .(cam, year, survey, taxon)]

site_of <- function(cam) { s <- sub("\\s*[0-9]+$", "", cam); s <- sub("\\s*[0-9]A$", "", s); s <- gsub("\\s+", " ", trimws(s))
  s <- gsub("HIll", "Hill", s); s <- sub("^Markham Woods$|^MarkhamHill$", "Markham", s); s <- sub("^Lake Seqouyah$", "Lake Sequoyah", s)
  s <- sub("^SequoyahWoods$", "Sequoyah Woods", s); s <- sub("^Eyebrow$|^DevilsDen$", "Devils Eyebrow", s); s <- sub("^WilsonSprings$|^LakeWilson$", "Lake Wilson", s); s }
surveys[, site := site_of(cam)]
cat("  study sites:", paste(sort(unique(surveys$site)), collapse = "; "), "\n")
long <- surveys[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(surveys))]
long <- merge(long, counts, by = c("cam", "year", "survey", "taxon"), all.x = TRUE)
long[is.na(episodes), episodes := 0L]
long <- long[, .(unit = cam, taxon, y = as.integer(episodes > 0), y_raw = episodes, period = year, occasion = survey, cluster_id = site,
                 obs_camera_days = camera_days)]
stopifnot(nrow(long) == nrow(surveys) * nrow(species), sum(long$y_raw) == nrow(det))

taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$label)
periods <- data.table(period = 1:2, label = c("Study year 1", "Study year 2"), start = c("2020-12", "2021-11"), end = c("2021-03", "2022-03"), n_weeks = c(16L, 22L))
dataset <- list(
  title = "Camera-trap detections of 18 mammal species across an urban-to-rural gradient, Northwest Arkansas, winters 2020-21 and 2021-22",
  creator = "McTigue, Leah E.; DeGregorio, Brett A.", pubDate = "2023", doi = "10.5061/dryad.7m0cfxq1r", sourceURL = "https://doi.org/10.5061/dryad.7m0cfxq1r",
  citation = "McTigue, L. E., & DeGregorio, B. A. (2023). Data from: Nine-banded Armadillo occupancy and density across an urban to rural gradient [Dataset]. Dryad. https://doi.org/10.5061/dryad.7m0cfxq1r",
  paperDOI = "10.1656/058.023.0413",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Wildlife detections from motion-triggered game cameras at study sites in Northwest Arkansas ranging from urban green space in downtown Fayetteville to natural sites in the Ozark Mountain ecoregion, over two winter field seasons, used for armadillo occupancy and random-encounter-model density estimation.",
  samplingProtocol = "Motion-triggered game cameras; detections grouped into 5-minute episodes; weekly survey periods within each winter season; the surveyed camera-weeks are inferred from each camera's first and last detection in the season (the deposited deployment dates are inconsistent with the detections).",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days", effortColumn = "obs_camera_days",
  surveyEvidence = "inferred",
  surveyEvidenceNote = "Surveyed camera-weeks = calendar weeks overlapping the first-to-last detection span of each camera-year (all detections, people included). The deposited deployment Start/End fields were not believed: 4,349 detections fall outside their own row's window.",
  responseType = "detection", unitKind = "site", closure = "occasion (weeks within a winter season)",
  geographicCoverage = "Northwest Arkansas, USA (Fayetteville to the Ozark Mountains; no coordinates deposited)", temporalCoverage = "2020-12/2022-03",
  coordinatesCoarsened = NA,
  notShipped = list(Density_2023.csv = "REM density estimates and GIS covariates; camera IDs do not match the detection file",
                    `Person, Unknown, Other, Bird, Mouse, Rat` = "detections not resolved to a taxon", Number = "individuals per episode (y_raw counts episodes)"),
  notes = "Zeros inferred from the first-to-last-detection span of each camera-year (deployment Start/End fields contradict 4,349 detection dates and are not used); weeks outside that span and cameras that recorded nothing are unrecoverable.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/mctigue_2023_nwarkansas_comm.R")

stage_dict_row(TABLE,
  description = "Weekly camera-trap detection/non-detection (with the number of detection episodes in y_raw) of 18 mammal species at 355 game cameras across an urban-to-rural gradient in Northwest Arkansas over two winter seasons (16 and 22 weeks), with camera-days per week as effort and study site as cluster.",
  url = "https://doi.org/10.5061/dryad.7m0cfxq1r",
  reference = "McTigue, L. E., & DeGregorio, B. A. (2024). Nine-banded Armadillo (Dasypus novemcinctus) occupancy and density across an urban-to-rural gradient. Southeastern Naturalist, 23(4), 529-548.",
  doi_paper = "10.1656/058.023.0413", doi_data = "10.5061/dryad.7m0cfxq1r", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Built from a per-detection record table: surveyed camera-weeks inferred from first/last detection per camera-year (deployment dates in the file are inconsistent). Density/covariate file unjoinable (site labels differ). Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "camera_trap", design = "Multi-season (2 winters x 16/22 weeks)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Record-table source; zeros inferred from first/last detection spans. Includes domestic dog and cat.",
  status = "tagged")
