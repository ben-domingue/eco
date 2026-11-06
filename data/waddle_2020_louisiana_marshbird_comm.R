#!/usr/bin/env Rscript
# Table:  waddle_2020_louisiana_marshbird_comm
# Source: USGS ScienceBase doi:10.5066/P9RRIIR2 (USGS data release, published 2020-09-14;
#         metadata use constraints "None"; US public domain, recorded as CC0 1.0)
#   Waddle, H., Jones, L.R., Vasseur, P.L., and Jeske, C.W., 2020, Estimating detection and
#   occupancy of secretive marsh bird species in low and high saline marshes in southwestern
#   Louisiana using automated recording units: U.S. Geological Survey data release.
# Paper:  Waddle, J.H., Jones, L.R., Vasseur, P.L. & Jeske, C.W. (2022). Wetlands 42: 26,
#         doi:10.1007/s13157-022-01548-4.
# Data:   Sites.csv: 33 ARU sites (of 40 deployed; 7 failed) with latitude, longitude, marsh
#         type and habitat class (brackish-salt vs fresh-intermediate). Samples.csv: 20 sample
#         periods, each a 48-hour window centred on midnight at the start of its date, with the
#         date, precipitation (cm) and minimum air temperature. One CSV per species (AMBI,
#         AMCO, CLRA, COGA, KIRA, LEBI, MAWR, PIGR, PUGA, SESP, SORA): 33 sites x 20 sample
#         periods, 1 detected / 0 not detected / NULL no recording. The NULL pattern is
#         identical across the eleven species files (asserted). The sample-period numbers are
#         not in date order: periods 13-16 fall on 7-28 May and 17-20 on 4-25 May 2012.
#
# Mapping: unit = ARU site, taxon = the source's 4-letter code, one season (no period),
#   occasion = sample period renumbered in date order (obs_sample_period keeps the source's
#   number), y = 0/1, NULL = no row (surveyEvidence deposited_matrix). date = the sample
#   period's date (the window's centre). obs_precip_cm and obs_min_air_temp_c from
#   Samples.csv; unit_ marsh type, habitat class and coordinates from Sites.csv (kept as
#   published; no target species is IUCN CR/EN/VU). Not shipped: nothing dropped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "waddle_2020_louisiana_marshbird_comm"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5ecf119d82ce30fd980854bd?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], TABLE, filename = f), header = TRUE, na.strings = "NULL")
sites <- rd("Sites.csv"); samp <- rd("Samples.csv")
stopifnot(nrow(sites) == 33, !anyDuplicated(sites$Site), nrow(samp) == 20, identical(samp$`Sample Period`, 1:20))
samp[, date := as.IDate(Date, "%m/%d/%Y")]
stopifnot(!anyNA(samp$date), !anyDuplicated(samp$date), all(year(samp$date) == 2012))
codes <- c("AMBI", "AMCO", "CLRA", "COGA", "KIRA", "LEBI", "MAWR", "PIGR", "PUGA", "SESP", "SORA")
Y <- array(NA_integer_, dim = c(33, 20, length(codes)), dimnames = list(sites$Site, NULL, codes))
for (k in codes) {
  x <- rd(paste0(k, ".csv"))
  stopifnot(identical(x$Site, sites$Site), identical(names(x)[-1], as.character(1:20)))
  Y[, , k] <- as.matrix(x[, -1])
}
stopifnot(all(Y %in% c(0L, 1L, NA)), all(apply(is.na(Y), 3, identical, is.na(Y[, , 1]))), sum(!is.na(Y[, , 1])) == 301)
ord <- order(samp$date)                       # occasions in date order
stopifnot(identical(ord, c(1:12, 17L, 13L, 18L, 14L, 19L, 15L, 20L, 16L)))
Y <- Y[, ord, , drop = FALSE]; s2 <- samp[ord]
rep_mat <- function(v) matrix(v, nrow = 33, ncol = 20, byrow = TRUE)
long <- array_to_eco(Y, site_ids = sites$Site,
                     site_covs = sites[, .(decimalLatitude = Latitude, decimalLongitude = Longitude, marsh_type = Marsh, habitat = Habitat)],
                     obs_covs = list(sample_period = rep_mat(s2$`Sample Period`), precip_cm = rep_mat(s2$Precipitation),
                                     min_air_temp_c = rep_mat(s2$MinAirTemp), .date = rep_mat(format(s2$date))))
setnames(long, "obs_.date", "date")
stopifnot(nrow(long) == 301 * 11)
names_sp <- c(AMBI = "Botaurus lentiginosus", AMCO = "Fulica americana", CLRA = "Rallus crepitans", COGA = "Gallinula galeata",
              KIRA = "Rallus elegans", LEBI = "Ixobrychus exilis", MAWR = "Cistothorus palustris", PIGR = "Podilymbus podiceps",
              PUGA = "Porphyrio martinica", SESP = "Ammospiza maritima", SORA = "Porzana carolina")
vern <- c("American Bittern", "American Coot", "Clapper Rail", "Common Gallinule", "King Rail", "Least Bittern", "Marsh Wren",
          "Pied-billed Grebe", "Purple Gallinule", "Seaside Sparrow", "Sora")
taxa <- make_taxa(codes, unname(names_sp[codes]), vernacularName = vern)
dataset <- list(
  title = "Secretive marsh bird detections from automated recording units at 33 marsh sites, southwestern Louisiana, February-May 2012",
  creator = "Waddle, Hardin; Jones, Landon R.; Vasseur, Phillip L.; Jeske, Clinton W.", pubDate = "2020",
  doi = "10.5066/P9RRIIR2", sourceURL = "https://doi.org/10.5066/P9RRIIR2",
  citation = "Waddle, H., Jones, L.R., Vasseur, P.L., and Jeske, C.W., 2020, Estimating detection and occupancy of secretive marsh bird species in low and high saline marshes in southwestern Louisiana using automated recording units: U.S. Geological Survey data release, https://doi.org/10.5066/P9RRIIR2.",
  paperDOI = "10.1007/s13157-022-01548-4",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, use constraints none"),
  abstract = "Detection histories of 11 secretive marsh bird species across 20 sampling occasions at 33 randomly selected automated-recording-unit sites in two wildlife refuges in southwestern Louisiana, with site marsh type and coordinates and sample-period weather.",
  samplingProtocol = "Automated recording units at randomly selected marsh sites; each sample period is a 48-hour recording window centred on midnight at the start of its date, listened to and spectrogram-scanned for vocalisations of 11 target species.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one breeding season (February-May 2012); the source fits single-season occupancy", occasionKind = "time",
  taxonInclusion = "target",
  geographicCoverage = list(description = "Rockefeller Wildlife Refuge and White Lake Wetlands Conservation Area, southwestern Louisiana, USA",
                            boundingBox = list(west = min(sites$Longitude), east = max(sites$Longitude), south = min(sites$Latitude), north = max(sites$Latitude))),
  temporalCoverage = "2012-02/2012-05",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS; no target species is IUCN CR/EN/VU"),
  notes = "Occasions are renumbered in date order; the source's sample-period number is obs_sample_period (its periods 13-20 interleave in time). date is the centre of the 48-hour window.",
  notShipped = list(failed_recorders = "7 of 40 recorders failed and are not in the release"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/waddle_2020_louisiana_marshbird_comm.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection of 11 secretive marsh bird species (rails, bitterns, gallinules, grebe, wren, sparrow) in 48-hour automated recordings over 20 sample periods at 33 marsh sites in southwestern Louisiana, February-May 2012, with marsh type, coordinates and sample weather.",
  url = "https://doi.org/10.5066/P9RRIIR2",
  reference = "Waddle, J. H., Jones, L. R., Vasseur, P. L., & Jeske, C. W. (2022). Estimating detection and occupancy of secretive marsh bird species in low and high saline marshes in southwestern Louisiana using automated recording units. Wetlands, 42, 26.",
  doi_paper = "10.1007/s13157-022-01548-4", doi_data = "10.5066/P9RRIIR2",
  original_license = "US public domain (USGS data release; use constraints none)", derived_license = "CC0 1.0",
  notes = "ARU detection histories; occasions renumbered in date order.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy", sampling_protocol = "acoustic",
  design = "Single-season (20 recording windows)", realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Automated recording units; 11 target species.")
