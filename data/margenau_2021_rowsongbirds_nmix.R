#!/usr/bin/env Rscript
# Table:  margenau_2021_rowsongbirds_nmix
# Source: Dryad doi:10.5061/dryad.gb5mkkwqr (CC0 1.0), version 3 (2021-10-19)
#   Margenau, E.L. (2021). Bayesian N-mixture and occupancy modeling code for songbirds.
#   Dryad. (Code also on Zenodo, doi:10.5281/zenodo.5579573.)
# Paper:  Margenau, E.L., Wood, P.B. & Rota, C.T. (2022). Habitat management for stopover
#         and breeding songbird communities along rights-of-way in forest-dominated
#         landscapes. Ecological Applications 32(3), e2540, doi:10.1002/eap.2540
# Data:   Data.csv: one row per individual bird detected on a breeding-season point count
#         (20,554 rows): Site, Treatment (right-of-way width/edge treatment or control
#         code), PointID (A, B, C, PC ... within a site x treatment plot), Observer, Date,
#         Year (0 = pre-treatment, 1 / 2 = years post-treatment; calendar years 2016-2019
#         differ by site), TimeofSurvey (HHMM), Visit (1, 2), Species (4-letter alpha code),
#         Count (1; four rows carry 0), Distance band, Sex, Detection (S song, C call,
#         V visual, F flyover, combinations). Data_stopover.csv (spring migration counts, no
#         Visit column) is NOT converted here. The README describes 154 points; the file
#         holds 260 Site x Treatment x PointID points over 1,205 point-year-visits.
#         Checked: every point-year-visit has exactly one Date/Observer/Time except one
#         (SC2 CtlRg PC, year 0, visit 2: two dates) -- kept as two occasions 2 and 3.
#
# Mapping (standard section 3.2 N-mixture, multi-species -> community abundance):
#   unit = point (Site_Treatment_PointID), cluster_id = Site_Treatment (the plot),
#   taxon = alpha code, period = Year 0/1/2 (treatment-relative; calendar year is
#   period_calendar_year), occasion = Visit, y = number of individuals detected (sum of
#   Count), all distance bands. A survey exists iff at least one row exists for the
#   point-year-visit; breeding-season point counts in eastern forest essentially never
#   record zero birds, and the four Count = 0 rows show that empty detections were still
#   logged. Pure flyovers (Detection == "F", 75 rows) are excluded from y, following the
#   authors' detection codes and point-count convention; everything else is counted.
#   UNCH / UNWO (unidentified chickadee / woodpecker, 28 rows) are dropped, as is BARO (not
#   an IBP code; Barred Owl is BADO, Barn Owl BNOW, both plausible). CAGO is the retired
#   code for Canada Goose and is merged into CANG. date, observer,
#   obs_time_hhmm, unit_treatment shipped; distance band, sex and detection type are
#   lost by aggregation (noted in dataset.json).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "margenau_2021_rowsongbirds_nmix"
dir <- download_dryad("10.5061/dryad.gb5mkkwqr", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
raw <- fread(file.path(dir, "Data.csv"))
stopifnot(nrow(raw) == 20554, all(raw$Count %in% 0:1), sum(raw$Count == 0) == 4, all(raw$Visit %in% 1:2), all(raw$Year %in% 0:2))
raw[, Treatment := as.character(Treatment)]
raw[, unit := paste(Site, Treatment, PointID, sep = "_")]
raw[, plot := paste(Site, Treatment, sep = "_")]
raw[, date := as.Date(Date, "%m/%d/%y")]; stopifnot(!anyNA(raw$date), all(year(raw$date) %in% 2016:2019))
stopifnot(uniqueN(raw$unit) == 260)

# surveys: one row per point-year-visit-date (one point has two dates for one visit)
surveys <- unique(raw[, .(unit, plot, Treatment, Year, Visit, date, Observer, TimeofSurvey)])
stopifnot(nrow(surveys) == 1206, nrow(unique(surveys[, .(unit, Year, Visit)])) == 1205)
stopifnot(surveys[, .N, by = .(unit, Year, Visit)][N > 1, unique(unit)] == "SC2_CtlRg_PC")
setorder(surveys, unit, Year, Visit, date)
surveys[, occasion := seq_len(.N), by = .(unit, Year)]
stopifnot(all(surveys$occasion %in% 1:3))
# calendar year is constant within point x Year (period_ covariate)
stopifnot(surveys[, uniqueN(year(date)), by = .(unit, Year)][, all(V1 == 1)])

flyover <- raw$Detection == "F"; unid <- raw$Species %in% c("UNCH", "UNWO", "BARO")
cat(sprintf("  excluded from y: %d pure flyovers (Detection == F); dropped %d unidentified/ambiguous rows (UNCH, UNWO, BARO)\n", sum(flyover), sum(unid)))
raw[Species == "CAGO", Species := "CANG"]            # retired alpha code, same species
det <- raw[!flyover & !unid]
det <- merge(det, surveys[, .(unit, Year, Visit, date, occasion)], by = c("unit", "Year", "Visit", "date"))
counts <- det[, .(y = sum(Count)), by = .(unit, taxon = Species, Year, occasion)]
species <- sort(unique(counts$taxon)); stopifnot(length(species) == 112)

long <- CJ(unit = surveys$unit, taxon = species, unique = FALSE)   # placeholder, rebuilt below
long <- surveys[, .(unit, cluster_id = plot, period = Year + 1L, occasion, date = format(date), observer = Observer,
                    unit_treatment = Treatment, period_calendar_year = year(date), obs_time_hhmm = TimeofSurvey)]
long <- long[rep(seq_len(.N), each = length(species))][, taxon := rep(species, times = nrow(surveys))]
long <- merge(long, counts[, .(unit, taxon, period = Year + 1L, occasion, y)], by = c("unit", "taxon", "period", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == nrow(surveys) * length(species), sum(long$y) == sum(det$Count))

# taxa: alpha codes -> scientific names via the IBP-AOS list in data/aux/ (then GBIF)
alpha <- fread(file.path(ECO_ROOT, "data", "aux", "bird_alpha_codes.csv"))
stopifnot(all(species %in% alpha$code))
alpha <- alpha[match(species, code)]
taxa <- make_taxa(species, alpha$scientificName, vernacularName = alpha$commonName)
periods <- data.table(period = 1:3, treatment_year = 0:2, note = c("pre-treatment", "1 year post-treatment", "2 years post-treatment"))
dataset <- list(
  title = "Breeding-season point counts of songbirds along forest rights-of-way, central Appalachians, 2016-2019 (pre- and post-treatment)",
  creator = "Margenau, Eric L.", pubDate = "2021", doi = "10.5061/dryad.gb5mkkwqr", sourceURL = "https://doi.org/10.5061/dryad.gb5mkkwqr",
  citation = "Margenau, E. L. (2021). Bayesian N-mixture and occupancy modeling code for songbirds [Dataset]. Dryad. https://doi.org/10.5061/dryad.gb5mkkwqr",
  paperDOI = "10.1002/eap.2540",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point-count data from summer breeding songbird surveys at points along electric-transmission rights-of-way and forest controls, used in N-mixture and species-richness models comparing right-of-way width and edge treatments before and after treatment.",
  samplingProtocol = "Point counts, two visits per breeding season per point, three treatment-relative years; each detected individual recorded with distance band, sex and detection type; y is the number of individuals per species per count excluding pure flyovers.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "occasion (two visits within a breeding season); period = treatment-relative year",
  geographicCoverage = "Central Appalachian forest, USA (no coordinates deposited; Site codes only)", temporalCoverage = "2016-05/2019-06",
  coordinatesCoarsened = NA,
  notShipped = list(Distance = "distance band per individual (lost by aggregation to counts)", Sex = "per individual", Detection = "type per individual; pure flyovers excluded from y",
                    Data_stopover.csv = "spring-migration counts, separate design (no Visit column); candidate for its own table"),
  notes = "Year 0/1/2 is relative to the treatment date, so period 1 spans 2016-2018 across sites; period_calendar_year gives the calendar year. One point (SC2_CtlRg_PC) has two counts for visit 2 of year 0, kept as occasions 2 and 3.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/margenau_2021_rowsongbirds_nmix.R")

stage_dict_row(TABLE,
  description = "Counts of 112 bird species on breeding-season point counts at 260 points along forest rights-of-way and controls in the central Appalachians (2016-2019), two visits per point per treatment-relative year (pre, +1, +2), with date, observer, time and treatment code; built from per-individual detection records, flyovers excluded.",
  url = "https://doi.org/10.5061/dryad.gb5mkkwqr",
  reference = "Margenau, E. L., Wood, P. B., & Rota, C. T. (2022). Habitat management for stopover and breeding songbird communities along rights-of-way in forest-dominated landscapes. Ecological Applications, 32(3), e2540.",
  doi_paper = "10.1002/eap.2540", doi_data = "10.5061/dryad.gb5mkkwqr",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Zeros inferred: a point-year-visit is a survey iff it has at least one detection row (four explicit Count = 0 rows show empty counts were logged). Flyovers (75 rows) excluded; UNCH/UNWO/BARO dropped; CAGO merged into CANG. Stopover file not converted. Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (3 treatment-relative years x 2 visits)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Counts per species per point count; manipulative design (unit_treatment). Rows = 1,206 surveys x 112 species.",
  status = "tagged")
