#!/usr/bin/env Rscript
# Table:  lebeuftaylor_2026_alpac_songbird_dynocc
# Source: Borealis (Canadian Dataverse) doi:10.5683/SP3/OZUBY9, version 2 (released 2026-10-16); licence as shown on the
#         record: CC0 1.0.
#   Lebeuf-Taylor, I. (2026). Replication Data for: Understory protection supports forest songbirds but does not offset
#   regional fire-driven losses to old forest occupancy. Borealis.
# Paper:  the manuscript of the title (not read; the record's description gives the design). Code:
#         github.com/IsabelleLebTay/UP-supports-songbirds.
# Data:   response-1.tab (original CSV): 3,798 recordings: location (162 sites), transect (54 clusters), treatment (UP
#         understory protection harvest, CLH conventional low-retention harvest, OF unharvested old forest), year
#         (2015-2016, 2020-2025), day of year, time of day (minutes after midnight), and 0/1 detections of six songbirds
#         (BBWA, BRCR, BTNW, HETH, TEWA, WIWR) from the HawkEars classifier (v1.0) at species thresholds set for a 0.90
#         probability of a true positive and validated by manual review (hawkears_thresholds_8recs.tab). Up to eight
#         recordings per site-year between 04:45 and 07:45, 25 May - 15 July. predictors-1.tab: distance to treatment
#         edge (m), harvest year, retained understory height (m) per site. Landbase and old-forest rate files are
#         landscape accounting for projections. Asserted: (location, year, doy, tod) unique; every site in the
#         predictors; transect and treatment constant per site; detections 0/1.
# Mapping: dynamic community occupancy. unit = site (location), cluster_id = transect, period = year (1 = 2015 ... 11 =
#   2025; years without recordings have no rows), occasion = recording within the site-year in time order, y = the
#   classifier detection as the authors thresholded it (their call, E9 eDNA-call analogue for classifiers).
#   surveyEvidence row_presence: a row of the response file is a processed recording, with a 0/1 for every species.
#   obs_date_doy, obs_tod_min; unit_treatment, unit_distance_to_edge_m, unit_harvest_year, unit_understory_height_m.
# Not shipped: the classifier threshold table (in the notes), landscape accounting files; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lebeuftaylor_2026_alpac_songbird_dynocc"
meta <- fromJSON(download_cached("https://borealisdata.ca/api/datasets/:persistentId/?persistentId=doi:10.5683/SP3/OZUBY9", TABLE, "record.json"))
stopifnot(identical(meta$data$latestVersion$license$name, "CC0 1.0"))
r <- fread(download_cached("https://borealisdata.ca/api/access/datafile/1243296?format=original", TABLE, "response.csv"))
pr <- fread(download_cached("https://borealisdata.ca/api/access/datafile/1243297?format=original", TABLE, "predictors.csv"))
sp <- c("BBWA", "BRCR", "BTNW", "HETH", "TEWA", "WIWR")
stopifnot(nrow(r) == 3798, uniqueN(r$location) == 162, !anyDuplicated(r[, .(location, year, doy, tod)]), setequal(r$location, pr$location),
          r[, .(uniqueN(transect), uniqueN(treatment)), by = location][, all(V1 == 1 & V2 == 1)], all(unlist(r[, ..sp]) %in% 0:1),
          setequal(r$treatment, c("UP", "CLH", "OF")))
setorder(r, location, year, doy, tod)
r[, occasion := seq_len(.N), by = .(location, year)]
L <- melt(r, id.vars = c("location", "transect", "treatment", "year", "doy", "tod", "occasion"), measure.vars = sp, variable.name = "taxon",
          value.name = "y", variable.factor = FALSE)
L <- merge(L, pr, by = "location")
long <- L[, .(unit = location, taxon, y = as.integer(y), period = year - 2014L, occasion, cluster_id = transect,
              unit_treatment = treatment, unit_distance_to_edge_m = distance_to_edge_m, unit_harvest_year = harvest_year,
              unit_understory_height_m = uheight, obs_date_doy = doy, obs_tod_min = tod)]
stopifnot(nrow(long) == 3798 * 6)
periods <- data.table(period = sort(unique(long$period)))[, year := period + 2014L]
taxa <- make_taxa(sp, c("Setophaga castanea", "Certhia americana", "Setophaga virens", "Catharus guttatus", "Leiothlypis peregrina", "Troglodytes hiemalis"),
                  vernacularName = c("Bay-breasted warbler", "Brown creeper", "Black-throated green warbler", "Hermit thrush", "Tennessee warbler", "Winter wren"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Classifier detections of six old-forest songbirds on ARU recordings at 162 sites in three harvest treatments, north-eastern Alberta, 2015-2025",
  creator = "Lebeuf-Taylor, Isabelle",
  pubDate = "2026", doi = "10.5683/SP3/OZUBY9", sourceURL = "https://doi.org/10.5683/SP3/OZUBY9",
  citation = "Lebeuf-Taylor, I. (2026). Replication Data for: Understory protection supports forest songbirds but does not offset regional fire-driven losses to old forest occupancy. Borealis, V2. https://doi.org/10.5683/SP3/OZUBY9",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Autonomous recording units at 162 sites in 54 clusters, each with understory-protection harvest, conventional harvest and unharvested old forest, in the Alberta-Pacific Forest Management Agreement area, recorded in three of the years 2015-2025; up to eight dawn recordings per site-year were processed with the HawkEars classifier for six old-forest songbirds.",
  samplingProtocol = "Autonomous recording units; up to eight recordings per site-year from 04:45-07:45 between 25 May and 15 July processed with HawkEars v1.0, a species detected on a recording when its score exceeded a threshold set for a 0.90 probability of a true positive (validated by manual review).",
  samplingProtocolCode = "acoustic", surveyEvidence = "row_presence", responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion = recording within a breeding season (25 May - 15 July); period = year.",
  geographicCoverage = "Alberta-Pacific Forest Industries Forest Management Agreement area, north-eastern Alberta, Canada",
  temporalCoverage = "2015/2025",
  notShipped = list(thresholds = "hawkears_thresholds_8recs.tab: per-species classifier thresholds and validation summaries",
                    landscape = "landbase_accounting_2003_2025.tab and annual_old_forest_rates_2003_2025.tab (landscape projections)"),
  notes = "y is the classifier detection at the authors' species thresholds (0.90 precision target), not a manual identification. unit_treatment: UP understory protection harvest, CLH conventional low-retention harvest, OF old forest.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lebeuftaylor_2026_alpac_songbird_dynocc.R")
stage_dict_row(TABLE,
  description = "Per-recording classifier (HawkEars) detections of six old-forest songbirds at 162 ARU sites in understory-protection, conventional harvest and old-forest treatments, north-eastern Alberta, 2015-2025.",
  url = "https://doi.org/10.5683/SP3/OZUBY9",
  reference = "Lebeuf-Taylor, I. (2026). Replication Data for: Understory protection supports forest songbirds but does not offset regional fire-driven losses to old forest occupancy. Borealis.",
  doi_data = "10.5683/SP3/OZUBY9", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Classifier detections at the authors' thresholds.", source_via = "Borealis")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy (community)", sampling_protocol = "acoustic",
  design = "Multi-season (8 years, up to 8 recordings per site-year)", realm = "Terrestrial", country = "CAN", coordinates = "None in source",
  notes = "Forest harvest treatments; automated classifier.")
