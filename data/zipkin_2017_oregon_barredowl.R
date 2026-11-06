#!/usr/bin/env Rscript
# Tables: zipkin_2017_oregon_barredowl_dynocc (1995-2014 detection / non-detection)
#         zipkin_2017_oregon_barredowl_count  (2015-2016 counts of territorial pairs)
# Source: USGS ScienceBase doi:10.5066/F7348J9M (USGS data release, published 2017-08-31;
#         metadata use constraints "None"; US public domain, recorded as CC0 1.0)
#   Zipkin, E.F., Rossman, S., Yackulic, C.B., Wiens, J.D., Thorson, J.T., Davis, R.J., and
#   Grant, E.H.C., 2017, Count and detection-nondetection survey data of Barred Owls (Strix
#   varia) in historical breeding territories of Northern Spotted Owls (Strix occidentalis
#   caurina) in the Oregon Coast Ranges, 1995-2016: U.S. Geological Survey data release.
# Paper:  Zipkin, E.F. et al. (2017). Integrating count and detection-nondetection data to
#         model population dynamics. Ecology 98: 1640-1650, doi:10.1002/ecy.1831.
# Data:   Barred_owl_survey_data.csv, 106 sites (historical Northern Spotted Owl territories)
#         x: BO95_1 ... BO14_12, incidental detection (1) / non-detection (0) of Barred Owls
#         during Spotted Owl surveys in twelve 2-week periods (1 Mar - 31 Aug) a year,
#         NA = not surveyed in that period; BO15_1 ... BO16_3, counts of territorial Barred Owl
#         pairs found on Barred-Owl-specific surveys in three 2-month periods of 2015 and 2016,
#         NA = not surveyed; OV15_1 ... OV16_3, the proportion of the site surveyed in each
#         2-month period; PHAB_95 ... PHAB_16, proportion of the site in older (>= ~80 yr)
#         coniferous forest each year (1995-2015; no 2016 column). No coordinates.
#         Quirk (asserted): 27 site-periods of 2015-2016 have a positive surveyed proportion
#         but a count of NA; the count's NA governs (not surveyed for the count), and the
#         proportion is not shipped there.
#
# Mapping: two tables, one per protocol x response type (incidental detection during Spotted
#   Owl surveys vs dedicated Barred Owl surveys counting pairs), as in the paper's integrated
#   model. unit = site, taxon = STRVAR, period = year (index; calendar year in __periods),
#   occasion = 2-week (dynocc) or 2-month (count) period within the year; NA cells are
#   missing rows (surveyEvidence deposited_matrix). period_old_forest = PHAB of that year
#   (site x year). Count table: y = number of territorial pairs, obs_prop_surveyed = OV.
#   Not shipped: nothing dropped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "zipkin_2017_oregon_barredowl"
f <- download_cached("https://www.sciencebase.gov/catalog/file/get/599db7e4e4b012c075b965d0?f=__disk__c5%2Fc6%2Fe2%2Fc5c6e27ca5be7980ed0c7e5c17bd4d5f768cba1b",
                     SRC, filename = "Barred_owl_survey_data.csv")
d <- fread(f)
stopifnot(nrow(d) == 106, ncol(d) == 274, !anyDuplicated(d$SITE))
yy <- sprintf("%02d", c(95:99, 0:16)); years <- 1995:2016
det_cols <- unlist(lapply(yy[1:20], function(y) paste0("BO", y, "_", 1:12)))
cnt_cols <- unlist(lapply(yy[21:22], function(y) paste0("BO", y, "_", 1:3)))
ov_cols  <- sub("^BO", "OV", cnt_cols)
hab_cols <- paste0("PHAB_", yy[1:21])   # PHAB_95 ... PHAB_15; no PHAB_16 in the release
stopifnot(all(c(det_cols, cnt_cols, ov_cols, hab_cols) %in% names(d)))
D <- as.matrix(d[, ..det_cols]); C <- as.matrix(d[, ..cnt_cols]); OV <- as.matrix(d[, ..ov_cols])
H <- as.matrix(d[, ..hab_cols])
stopifnot(all(D %in% c(0, 1, NA)), sum(D == 1, na.rm = TRUE) == 1750, sum(!is.na(D)) == 8806,
          all(C %in% c(0:9, NA)), sum(!is.na(C)) == 406, !anyNA(OV), all(OV >= 0 & OV <= 1), !anyNA(H))
stopifnot(sum(is.na(C) & OV > 0) == 27, all(OV[!is.na(C)] > 0))   # NA count with a surveyed share: not a count survey
taxa <- make_taxa("STRVAR", "Strix varia", vernacularName = "Barred Owl")
common <- list(
  creator = "Zipkin, Elise F.; Rossman, Sam; Yackulic, Charles B.; Wiens, J. David; Thorson, James T.; Davis, Raymond J.; Grant, Evan H. Campbell",
  pubDate = "2017", doi = "10.5066/F7348J9M", sourceURL = "https://doi.org/10.5066/F7348J9M",
  citation = "Zipkin, E.F., Rossman, S., Yackulic, C.B., Wiens, J.D., Thorson, J.T., Davis, R.J., and Grant, E.H.C., 2017, Count and detection-nondetection survey data of Barred Owls (Strix varia) in historical breeding territories of Northern Spotted Owls (Strix occidentalis caurina) in the Oregon Coast Ranges, 1995-2016: U.S. Geological Survey data release, https://doi.org/10.5066/F7348J9M.",
  paperDOI = "10.1002/ecy.1831",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, use constraints none"),
  abstract = "Count and detection-nondetection data of Barred Owls from 106 historical Northern Spotted Owl breeding territories in the Oregon Coast Ranges, 1995-2016: incidental detections during Spotted Owl surveys in 2-week periods (1995-2014) and counts of territorial pairs from Barred Owl surveys in 2-month periods (2015-2016), with the proportion of each site in older coniferous forest each year.",
  unitKind = "site", taxonInclusion = "single", surveyEvidence = "deposited_matrix",
  geographicCoverage = list(description = "Oregon Coast Ranges, Oregon, USA", boundingBox = list(west = -124.05, east = -123.34, south = 43.84, north = 44.55)))
ref <- "Zipkin, E. F., Rossman, S., Yackulic, C. B., Wiens, J. D., Thorson, J. T., Davis, R. J., & Grant, E. H. C. (2017). Integrating count and detection-nondetection data to model population dynamics. Ecology, 98(6), 1640-1650."

## 1. detection / non-detection, 1995-2014
T1 <- "zipkin_2017_oregon_barredowl_dynocc"
long1 <- array_to_eco(D, taxon = "STRVAR", site_ids = d$SITE, period = rep(1:20, each = 12),
                      period_covs = list(old_forest = H[, 1:20]))
stopifnot(nrow(long1) == 8806)
ds1 <- write_table(long1, T1, c(list(
  title = "Barred Owl incidental detection / non-detection in 106 Northern Spotted Owl territories, Oregon Coast Ranges, 1995-2014"), common, list(
  samplingProtocol = "Incidental detections of Barred Owls recorded during annual Northern Spotted Owl territory surveys (calling and searching), partitioned into twelve 2-week periods from 1 March to 31 August each year.",
  samplingProtocolCode = "call_playback", responseType = "detection",
  closure = "closed", closureNote = "occasion = 2-week period within a breeding season (year); the paper's model treats the season as closed", occasionKind = "time",
  temporalCoverage = "1995/2014",
  notes = "Companion of zipkin_2017_oregon_barredowl_count (same sites, 2015-2016 counts from dedicated surveys).",
  notShipped = list(counts_2015_2016 = "shipped as zipkin_2017_oregon_barredowl_count"))),
  taxa = taxa, periods = data.table(period = 1:20, year = years[1:20]), script = "data/zipkin_2017_oregon_barredowl.R")
stage_dict_row(T1,
  description = "Incidental detection / non-detection of Barred Owls in twelve 2-week periods a year at 106 historical Northern Spotted Owl territories in the Oregon Coast Ranges, 1995-2014, with the yearly share of older coniferous forest per site.",
  url = "https://doi.org/10.5066/F7348J9M", reference = ref, doi_paper = "10.1002/ecy.1831", doi_data = "10.5066/F7348J9M",
  original_license = "US public domain (USGS data release; use constraints none)", derived_license = "CC0 1.0",
  notes = "Detections are incidental to Spotted Owl surveys. Companion: zipkin_2017_oregon_barredowl_count.", source_via = "USGS ScienceBase")
stage_tag_row(T1, ds1, taxon_group = "Birds", model_family = "Dynamic occupancy", sampling_protocol = "call_playback",
  design = "Multi-season (20 years x 12 two-week periods)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Invasive Barred Owl in Spotted Owl territories; detections incidental to Spotted Owl surveys.")

## 2. counts of territorial pairs, 2015-2016
T2 <- "zipkin_2017_oregon_barredowl_count"
OVm <- OV; OVm[is.na(C)] <- NA
long2 <- array_to_eco(C, taxon = "STRVAR", site_ids = d$SITE, period = rep(1:2, each = 3),
                      obs_covs = list(prop_surveyed = OVm), period_covs = list(old_forest = cbind(H[, 21], NA_real_)))   # 2016 not deposited
stopifnot(nrow(long2) == 406, !anyNA(long2$obs_prop_surveyed))
ds2 <- write_table(long2, T2, c(list(
  title = "Counts of territorial Barred Owl pairs in 106 Northern Spotted Owl territories, Oregon Coast Ranges, 2015-2016"), common, list(
  samplingProtocol = "Dedicated Barred Owl surveys (calling) counting territorial pairs (one or more territorial owls at one location) per site in three 2-month periods (March-August) of 2015 and 2016, with the proportion of the site covered.",
  samplingProtocolCode = "call_playback", responseType = "count", effortColumn = "obs_prop_surveyed",
  closure = "closed", closureNote = "occasion = 2-month period within a breeding season (year)", occasionKind = "time",
  temporalCoverage = "2015/2016",
  notes = "Companion of zipkin_2017_oregon_barredowl_dynocc (incidental detections 1995-2014). 27 site-periods with a surveyed proportion but no count are treated as not surveyed for the count.",
  notShipped = list(prop_surveyed_without_count = "27 site-periods have OV > 0 but a count of NA; no row, so their OV is not shipped",
                    detections_1995_2014 = "shipped as zipkin_2017_oregon_barredowl_dynocc"))),
  taxa = taxa, periods = data.table(period = 1:2, year = years[21:22]), script = "data/zipkin_2017_oregon_barredowl.R")
stage_dict_row(T2,
  description = "Counts of territorial Barred Owl pairs in three 2-month periods of 2015 and 2016 at 106 historical Northern Spotted Owl territories in the Oregon Coast Ranges, with the proportion of each site surveyed and its share of older coniferous forest.",
  url = "https://doi.org/10.5066/F7348J9M", reference = ref, doi_paper = "10.1002/ecy.1831", doi_data = "10.5066/F7348J9M",
  original_license = "US public domain (USGS data release; use constraints none)", derived_license = "CC0 1.0",
  notes = "Counts of pairs from dedicated surveys; effort as proportion of site surveyed. Companion: zipkin_2017_oregon_barredowl_dynocc.", source_via = "USGS ScienceBase")
stage_tag_row(T2, ds2, taxon_group = "Birds", model_family = "N-mixture", sampling_protocol = "call_playback",
  design = "Multi-season (2 years x 3 two-month periods)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Counts of territorial pairs, not individuals.")
