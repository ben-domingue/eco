#!/usr/bin/env Rscript
# Table:  wiens_2021_socal_goldeneagle_dynocc
# Source: USGS ScienceBase doi:10.5066/P9OIPLHH (USGS data release, published 2021-12-28;
#         metadata use constraints "No use constraints"; US public domain, recorded as CC0 1.0)
#   Wiens, J.D., Bloom, P.H., Madden, M.C., Kolar, P.S., Tracey, J.A., and Fisher, R.N., 2021,
#   Detection/non-detection data on territorial pairs of golden eagles in coastal southern
#   California, 2016-2017: U.S. Geological Survey data release.
# Paper:  Wiens, J.D. et al. (2022). Golden Eagle occupancy surveys and monitoring strategy in
#         coastal southern California, United States. Frontiers in Ecology and Evolution 9,
#         doi:10.3389/fevo.2021.665792.
# Data:   SoCal_GOEA_OccupancyData.csv (also deposited as .xlsx, same content): 175 survey sites
#         (13.9 km2 hexagons drawn at random from a grid) x v1_2016 ... v4_2017, detection (1) /
#         non-detection (0) of a territorial pair of Golden Eagles in four breeding-cycle windows
#         a season (courtship 15 Dec-28 Feb, incubation 1 Mar-30 Apr, nestling 1 May-15 Jun,
#         fledging-dependency 16 Jun-30 Jul), NA = not surveyed; urban, grass, forest, scrub
#         (proportions of the hexagon) and tri (mean terrain ruggedness). No coordinates.
#
# Mapping: unit = site (Unit_ID), taxon = AQUCHR, period = season (2016, 2017; __periods),
#   occasion = breeding-cycle window 1-4, y = 0/1; NA cells are missing rows (surveyEvidence
#   deposited_matrix). The land-cover proportions and tri are unit_ covariates (one value per
#   site for both years, per the metadata). Not shipped: nothing dropped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "wiens_2021_socal_goldeneagle_dynocc"
f <- download_cached("https://www.sciencebase.gov/catalog/file/get/6192db12d34eb622f68e44ef?f=__disk__77%2Ff6%2Fec%2F77f6ec82c60244eae0e32959437bc7d7c1a29c45",
                     TABLE, filename = "SoCal_GOEA_OccupancyData.csv")
d <- fread(f)
vcols <- c(paste0("v", 1:4, "_2016"), paste0("v", 1:4, "_2017"))
stopifnot(nrow(d) == 175, !anyDuplicated(d$Unit_ID), identical(names(d)[2:9], vcols))
Y <- as.matrix(d[, ..vcols])
stopifnot(all(Y %in% c(0, 1, NA)), sum(Y == 1, na.rm = TRUE) == 53, sum(!is.na(Y)) == 1252,
          all(rowSums(!is.na(Y)) >= 3))
long <- array_to_eco(Y, taxon = "AQUCHR", site_ids = d$Unit_ID, period = rep(1:2, each = 4),
                     site_covs = d[, .(prop_urban = urban, prop_grass = grass, prop_forest = forest, prop_scrub = scrub, tri)])
stopifnot(nrow(long) == 1252)
taxa <- make_taxa("AQUCHR", "Aquila chrysaetos", vernacularName = "Golden Eagle")
dataset <- list(
  title = "Golden Eagle territorial-pair detection / non-detection at 175 random survey sites, coastal southern California, 2016-2017",
  creator = "Wiens, J. David; Bloom, Peter H.; Madden, Melanie C.; Kolar, Patrick S.; Tracey, Jeff A.; Fisher, Robert N.",
  pubDate = "2021", doi = "10.5066/P9OIPLHH", sourceURL = "https://doi.org/10.5066/P9OIPLHH",
  citation = "Wiens, J.D., Bloom, P.H., Madden, M.C., Kolar, P.S., Tracey, J.A., and Fisher, R.N., 2021, Detection/non-detection data on territorial pairs of golden eagles in coastal southern California, 2016-2017: U.S. Geological Survey data release, https://doi.org/10.5066/P9OIPLHH.",
  paperDOI = "10.3389/fevo.2021.665792",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, no use constraints"),
  abstract = "Detection-nondetection data for territorial pairs of Golden Eagles at survey sites randomly selected from a grid of 13.9 km2 hexagonal cells in coastal southern California during 2016 and 2017, with surveys partitioned into four breeding-cycle windows per season, and the land-cover composition and terrain ruggedness of each site.",
  samplingProtocol = "Repeated surveys of each hexagon from 1-4 ridge-top observation points giving complete coverage, searching for territorial pairs, nests and reproduction for up to 4 hours per survey, in four breeding-cycle windows per season.",
  samplingProtocolCode = "territory_survey", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = breeding-cycle window within a season; occupancy by a territorial pair assumed constant within a season (the source fits colext)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = list(description = "Coastal southern California (Orange, Riverside and San Diego counties), USA", boundingBox = list(west = -117.85, east = -116.14, south = 32.53, north = 33.97)),
  temporalCoverage = "2016/2017",
  notShipped = list(xlsx_copy = "SoCal_GOEA_OccupancyData.xlsx duplicates the CSV"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:2, year = 2016:2017),
                  script = "data/wiens_2021_socal_goldeneagle_dynocc.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection of territorial Golden Eagle pairs in four breeding-cycle windows per season at 175 random hexagonal survey sites in coastal southern California, 2016 and 2017, with land-cover proportions and terrain ruggedness.",
  url = "https://doi.org/10.5066/P9OIPLHH",
  reference = "Wiens, J. D., Bloom, P. H., Madden, M. C., Kolar, P. S., Tracey, J. A., & Fisher, R. N. (2022). Golden Eagle occupancy surveys and monitoring strategy in coastal southern California, United States. Frontiers in Ecology and Evolution, 9, 665792.",
  doi_paper = "10.3389/fevo.2021.665792", doi_data = "10.5066/P9OIPLHH",
  original_license = "US public domain (USGS data release; no use constraints)", derived_license = "CC0 1.0",
  notes = "Site = random 13.9 km2 hexagon; no coordinates in the release.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy", sampling_protocol = "territory_survey",
  design = "Multi-season (2 seasons x 4 breeding-cycle windows)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Detection of territorial pairs, not individuals.")
