#!/usr/bin/env Rscript
# Table:  laramie_2019_bruneau_trout_edna
# Source: USGS ScienceBase doi:10.5066/P9LRD94Y (USGS data release, published 2019-06-05;
#         use constraints: "None. Public domain data from the U.S. Government are freely
#         redistributable with proper metadata and source attribution"; recorded as CC0 1.0)
#   Laramie, M.B. and Pilliod, D.S., 2019, Occupancy data for spatiotemporal distribution
#   assessments of bull trout (Salvelinus confluentus) and rainbow trout (Oncorhynchus mykiss) in
#   the Bruneau and Jarbidge River Basins, Idaho and Nevada, USA, in water year 2016: U.S.
#   Geological Survey data release.
# Paper:  Pilliod, D.S., Laramie, M.B., McCoy, D. & Maclean, S. (2019). Integration of eDNA-based
#         biological monitoring within the U.S. Geological Survey's National Streamgage Network.
#         JAWRA, doi:10.1111/1752-1688.12800.
# Data:   one CSV, 26 stream sites (3 streamgages, intermediate and supplemental sites) x:
#         latitude / longitude (WGS84), site type, stream, description, elevation; for each
#         species and each month October 2015 - September 2016, three replicate eDNA samples
#         (qPCR result reduced by the authors to detection 1 / non-detection 0; the metadata
#         say 2 for non-detection but the file holds 0, asserted), plus an "All 3 replicates
#         combined" column per month; instantaneous stream temperature and discharge per month.
#         Blank = site not sampled that month. The blank pattern is identical for the two
#         species (asserted). One rainbow-trout site-month (February) has replicate 1 = 0 but
#         no combined value; the replicate is kept (asserted). No Ct values or field blanks are deposited: y is the authors' call.
#
# Mapping (standard E9 eDNA form): unit = site, taxon = species, period = month (1-12,
#   __periods gives year and month), occasion = replicate sample (spatial replicate within a
#   monthly visit), y = 0/1 (surveyEvidence deposited_matrix). period_ stream temperature and
#   discharge (one value per site-month); unit_ site type, stream, elevation and coordinates.
#   Bull trout is IUCN VU (GBIF IUCN record, asserted), so coordinates are coarsened to the
#   0.1-degree cell centre on every row (the table is one site set for both species).
#   Not shipped: the "All 3 replicates combined" columns (derived from the replicates; checked
#   equal to their maximum where present), the site description (river mile labels, kept in unit_site_desc).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "laramie_2019_bruneau_trout_edna"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5cdaf739e4b0ab16db3a82e8?format=json", TABLE, filename = "item.json"))
fn <- "Bull trout and rainbow trout eDNA occupancy data.csv"
fl <- setNames(it$files$url, it$files$name)
d <- fread(download_cached(fl[[fn]], TABLE, filename = fn), check.names = FALSE)
stopifnot(nrow(d) == 26, ncol(d) == 127, !anyDuplicated(d$`Site Identification`))
months <- c("October", "November", "December", "January", "February", "March", "April", "May", "June", "July", "August", "September")
sp <- c(SALCON = "Bull trout", ONCMYK = "Rainbow trout")
Y <- array(NA_integer_, dim = c(26, 36, 2), dimnames = list(d$`Site Identification`, NULL, names(sp)))
for (k in names(sp)) {
  cols <- unlist(lapply(months, function(m) sprintf("%s eDNA_%s_Replicate %d", sp[[k]], m, 1:3)))
  comb <- sprintf("%s eDNA_%s_All 3 replicates combined", sp[[k]], months)
  stopifnot(all(c(cols, comb) %in% names(d)))
  Y[, , k] <- as.matrix(d[, ..cols])
  C <- as.matrix(d[, ..comb])
  mx <- sapply(1:12, function(j) apply(Y[, (j - 1) * 3 + 1:3, k, drop = FALSE], 1, function(z) if (all(is.na(z))) NA_integer_ else max(z, na.rm = TRUE)))
  odd <- which(is.na(C) & !is.na(mx))          # a replicate result with no combined value
  stopifnot(all(C == mx, na.rm = TRUE), all(!is.na(mx)[!is.na(C)]), length(odd) == (k == "ONCMYK"))
  if (length(odd)) cat(sprintf("  %s: %d site-month with a replicate result but no combined value (kept)\n", k, length(odd)))
}
stopifnot(all(Y %in% c(0L, 1L, NA)), identical(is.na(Y[, , 1]), is.na(Y[, , 2])), sum(!is.na(Y[, , 1])) == 304)
temp <- as.matrix(d[, paste0("Stream temperature (degrees Celsius)_", months), with = FALSE])
dis  <- as.matrix(d[, paste0("Discharge (cubic feet per second)_", months), with = FALSE])
taxa <- make_taxa(names(sp), c("Salvelinus confluentus", "Oncorhynchus mykiss"), vernacularName = unname(sp))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, c("VU", "LC")))
cc <- coarsen_coords(d$Latitude, d$Longitude)
long <- array_to_eco(Y, site_ids = d$`Site Identification`, period = rep(1:12, each = 3),
                     site_covs = data.table(decimalLatitude = cc$lat, decimalLongitude = cc$lon, site_type = d$`Site Type`,
                                            stream = d$Stream, site_desc = d$`Site Description`, elevation_m = d$`Elevation (meters)`),
                     period_covs = list(stream_temp_c = temp, discharge_cfs = dis))
stopifnot(nrow(long) == 2 * 304)
periods <- data.table(period = 1:12, year = c(rep(2015L, 3), rep(2016L, 9)), month = c(10:12, 1:9))
dataset <- list(
  title = "Bull trout and rainbow trout eDNA detections in monthly replicate water samples at 26 stream sites, Bruneau and Jarbidge rivers, Idaho and Nevada, water year 2016",
  creator = "Laramie, Matthew B.; Pilliod, David S.", pubDate = "2019", doi = "10.5066/P9LRD94Y", sourceURL = "https://doi.org/10.5066/P9LRD94Y",
  citation = "Laramie, M.B. and Pilliod, D.S., 2019, Occupancy data for spatiotemporal distribution assessments of bull trout (Salvelinus confluentus) and rainbow trout (Oncorhynchus mykiss) in the Bruneau and Jarbidge River Basins, Idaho and Nevada, USA, in water year 2016: U.S. Geological Survey data release, https://doi.org/10.5066/P9LRD94Y.",
  paperDOI = "10.1111/1752-1688.12800",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, freely redistributable with attribution"),
  abstract = "eDNA-based spatiotemporal distribution data in occupancy-model format for rainbow trout and bull trout in the Bruneau-Jarbidge Rivers Wilderness, southern Idaho and northern Nevada, collected monthly October 2015 - September 2016, with stream discharge and temperature at sampling.",
  samplingProtocol = "Monthly visits to streamgage, intermediate and supplemental sites; three replicate water samples filtered per visit (Laramie et al. 2015 protocol) and analysed by species-specific qPCR; a sample amplifying above the Cq threshold is a detection.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = replicate water sample within one monthly visit; period = month", occasionKind = "spatial",
  taxonInclusion = "target",
  geographicCoverage = list(description = "Bruneau and Jarbidge river basins, Idaho and Nevada, USA",
                            boundingBox = list(west = round(min(d$Longitude), 1) - 0.1, east = round(max(d$Longitude), 1) + 0.1, south = round(min(d$Latitude), 1) - 0.1, north = round(max(d$Latitude), 1) + 0.1)),
  temporalCoverage = "2015-10/2016-09",
  coordinatesCoarsened = list(value = TRUE, method = "coarsen_coords(): 0.1-degree cell centre, because bull trout (Salvelinus confluentus) is IUCN VU"),
  notes = "y is the authors' detection call per sample (Cq above threshold); no Ct values or field-blank results are deposited.",
  notShipped = list(replicates_combined = "the per-month 'All 3 replicates combined' columns: derived from the replicates (asserted equal to their maximum)",
                    exact_coordinates = "coarsened to 0.1 degree (bull trout IUCN VU)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/laramie_2019_bruneau_trout_edna.R")
stage_dict_row(TABLE,
  description = "eDNA detection / non-detection of bull trout and rainbow trout in three replicate water samples per monthly visit at 26 stream sites in the Bruneau and Jarbidge river basins, Idaho and Nevada, October 2015 - September 2016, with stream temperature and discharge.",
  url = "https://doi.org/10.5066/P9LRD94Y",
  reference = "Pilliod, D. S., Laramie, M. B., McCoy, D., & Maclean, S. (2019). Integration of eDNA-based biological monitoring within the U.S. Geological Survey's National Streamgage Network. Journal of the American Water Resources Association.",
  doi_paper = "10.1111/1752-1688.12800", doi_data = "10.5066/P9LRD94Y",
  original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "eDNA occupancy: period = month, occasion = replicate sample. Coordinates coarsened to 0.1 degree (bull trout VU).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "eDNA occupancy (multi-season)", sampling_protocol = "eDNA",
  design = "Multi-season (12 months x 3 replicate samples)", realm = "Freshwater", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Authors' detection call per sample; no Ct values.")
