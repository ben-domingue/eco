#!/usr/bin/env Rscript
# Table:  bruce_2021_wisconsin_monarch_nmix
# Source: USGS ScienceBase doi:10.5066/P9BERZ62 (item 613f80cfd34e1449c5d35ca7). Bruce, A.S.,
#   Thogmartin, W.E., Trosen, C., Oberhauser, K. & Gratton, C. (2021). Monarch Butterfly patch
#   and landscape data for Wisconsin, 2018-2019. U.S. Geological Survey data release. Licence: US
#   public domain (USGS data release; the FGDC record states access and use constraints
#   "None"), shipped as CC0 1.0 as for the other USGS tables.
# Paper:  Bruce, A.S., Thogmartin, W.E., Trosen, C., Oberhauser, K. & Gratton, C. (2022).
#   Landscape- and local-level variables affect monarchs in Midwest grasslands. Landscape
#   Ecology 37: 93-108, doi:10.1007/s10980-021-01341-4 (preprint doi:10.21203/rs.3.rs-346846/v1).
# Data:   monarch2020_021920.csv: 352 rows, one per site x year x survey (asserted unique), 60
#           grassland sites (Name), 2018 (60 sites) and 2019 (59 sites), SurveyNo 1-3 within a
#           summer (no dates deposited). Columns: YCoord/XCoord (site latitude/longitude, WGS84
#           decimal degrees, constant per site), NectarSppOnTransect (blooming species on the
#           transect at that survey), Adults (adult monarchs counted on the transect),
#           WIRegion (North/South), EggsLarvaePerStemExcludingWhorled and
#           ...DBPerMSq (immatures per milkweed stem / per m2), MilkweedDensityPerSqM...
#           (milkweed stems per m2, A. verticillata excluded), and nine landscape metrics in a
#           10-km buffer or of the patch (constant per site, asserted).
#         monarchlandscape.xml: FGDC metadata (attribute definitions; IMMP protocols).
# Mapping (N-mixture, open / multi-season): unit = site (Name), taxon = DANPLE, period = year
#   (1 = 2018, 2 = 2019), occasion = SurveyNo, y = Adults. Survey evidence: row_presence: the
#   file has one row per conducted survey with explicit zero counts; 8 site-surveys and one
#   site-year (a site not surveyed in 2019) are absent and have no rows. Closure assumed within
#   a summer across the three surveys (June-August).
#   unit_: region, coordinates (as published), patch and landscape metrics. obs_: nectar species
#   on the transect and milkweed density at the survey (both vary by survey in the file).
#   Not shipped: EggsLarvaePerStem* (eggs and larvae per milkweed stem and per m2: ratios of a
#   second response, the immature stages, whose underlying counts and stem numbers are not
#   deposited, so they are neither a count y nor a clean covariate).
#   Coordinates: USGS-published site coordinates kept as published (E7, agency rule). The
#   migratory monarch is IUCN Vulnerable (2023) and proposed for US ESA listing (2024); these
#   are public grassland properties named in the file.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bruce_2021_wisconsin_monarch_nmix"
SB <- "https://www.sciencebase.gov/catalog/file/get/613f80cfd34e1449c5d35ca7?f=%s"
f <- download_cached(sprintf(SB, "__disk__bc%2F39%2F7e%2Fbc397e360fd7afe1d9e3103d0ef48161380a3fb8"), TABLE, filename = "monarch2020_021920.csv")
x <- fread(f)
stopifnot(identical(names(x), c("Name", "YCoord", "XCoord", "SurveyNo", "Year", "NectarSppOnTransect", "Adults", "WIRegion",
  "EggsLarvaePerStemExcludingWhorled", "EggsLarvaePerStemExcludingWhorledDBPerMSq",
  "MilkweedDensityPerSqMExcludingWhorled.totalsubplotDB100.", "Roads_10km", "patch_area", "avgpatch_area",
  "isolationpatchenn", "isolationavgenn", "cohesion", "lsmgrass10km", "forestED")))
stopifnot(nrow(x) == 352L, uniqueN(x$Name) == 60L, !anyDuplicated(x[, .(Name, Year, SurveyNo)]),
          setequal(x$Year, 2018:2019), setequal(x$SurveyNo, 1:3), !anyNA(x$Adults), all(x$Adults >= 0),
          all(x$Adults == round(x$Adults)), setequal(x$WIRegion, c("North", "South")))
stopifnot(identical(x[, uniqueN(Name), keyby = Year]$V1, c(60L, 59L)))
sitecols <- c("YCoord", "XCoord", "WIRegion", "Roads_10km", "patch_area", "avgpatch_area", "isolationpatchenn",
              "isolationavgenn", "cohesion", "lsmgrass10km", "forestED")
stopifnot(all(x[, lapply(.SD, uniqueN), by = Name, .SDcols = sitecols][, -1] == 1L))
stopifnot(all(x$YCoord > 42 & x$YCoord < 47.5), all(x$XCoord > -93 & x$XCoord < -86.5))
cat(sprintf("  site not surveyed in 2019: %s\n", setdiff(x[Year == 2018, Name], x[Year == 2019, Name])))

long <- x[, .(unit = Name, taxon = "DANPLE", y = as.integer(Adults), period = Year - 2017L, occasion = as.integer(SurveyNo),
              unit_region = WIRegion, unit_decimalLatitude = YCoord, unit_decimalLongitude = XCoord,
              unit_patch_area_ha = patch_area, unit_avgpatch_area_10km_ha = avgpatch_area,
              unit_isolation_patch_enn_m = isolationpatchenn, unit_isolation_avg_enn_10km_m = isolationavgenn,
              unit_cohesion_10km = cohesion, unit_grass_prop_10km = lsmgrass10km, unit_road_density_10km = Roads_10km,
              unit_forest_edge_density_10km = forestED,
              obs_nectar_species = as.integer(NectarSppOnTransect),
              obs_milkweed_per_m2 = `MilkweedDensityPerSqMExcludingWhorled.totalsubplotDB100.`)]
stopifnot(nrow(long) == 352L, sum(long$y) == 680L)

periods <- data.table(period = 1:2, year = 2018:2019, n_sites = x[, uniqueN(Name), keyby = Year]$V1,
                      note = "summer survey season (June-August); three surveys per site")
taxa <- make_taxa("DANPLE", "Danaus plexippus", vernacularName = "Monarch")

dataset <- list(
  title = "Repeated transect counts of adult monarch butterflies at 60 Wisconsin grassland sites, 2018-2019",
  creator = "Bruce, Alexis S.; Thogmartin, Wayne E.; Trosen, Claudia; Oberhauser, Karen; Gratton, Claudio",
  pubDate = "2021", doi = "10.5066/P9BERZ62", sourceURL = "https://doi.org/10.5066/P9BERZ62",
  citation = "Bruce, A.S., Thogmartin, W.E., Trosen, C., Oberhauser, K., and Gratton, C., 2021, Monarch Butterfly patch and landscape data for Wisconsin, 2018-2019: U.S. Geological Survey data release, https://doi.org/10.5066/P9BERZ62.",
  paperDOI = "10.1007/s10980-021-01341-4",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
                            note = "USGS data release; US public domain, no access or use constraints"),
  abstract = "Adult monarchs counted on transects three times per summer at 60 grassland sites in northern and southern Wisconsin in 2018 and 2019, with blooming-species richness and milkweed density per survey and patch and landscape metrics (10-km buffers) per site. The paper relates monarch occurrence to patch quality and landscape context.",
  samplingProtocol = "Integrated Monarch Monitoring Program (IMMP 2018; Cariveau et al. 2019) adult monarch transect survey by trained surveyors, three surveys per site per summer; milkweed (A. verticillata excluded) and blooming species recorded at the survey.",
  samplingProtocolCode = "transect_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "occasion (three surveys within a summer, June-August); period = year",
  geographicCoverage = list(description = "Grassland sites in northern and southern Wisconsin, USA",
                            boundingBox = list(west = min(x$XCoord), east = max(x$XCoord), south = min(x$YCoord), north = max(x$YCoord))),
  temporalCoverage = "2018-06-01/2019-08-09", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "USGS-published site coordinates kept as published (E7 agency rule); the migratory monarch is IUCN Vulnerable, and the sites are public or agency grassland properties named in the source"),
  notShipped = list(EggsLarvaePerStemExcludingWhorled = "monarch eggs and larvae per milkweed stem: a ratio of a second response (immature stages) whose counts and stem numbers are not deposited",
                    EggsLarvaePerStemExcludingWhorledDBPerMSq = "monarch eggs and larvae per m2: as above"),
  notes = "Survey dates are not deposited (occasion = survey number within the summer). One site was surveyed in 2018 only; 8 site-surveys are absent (no rows). obs_milkweed_per_m2 excludes whorled milkweed (Asclepias verticillata), as in the source.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/bruce_2021_wisconsin_monarch_nmix.R")

stage_dict_row(TABLE,
  description = "Adult monarch counts on IMMP transects, three surveys per summer at 60 Wisconsin grassland sites in 2018 and 2019 (352 surveys), with nectar-species richness and milkweed density per survey, site coordinates and patch/landscape metrics.",
  url = "https://doi.org/10.5066/P9BERZ62",
  reference = "Bruce, A.S., Thogmartin, W.E., Trosen, C., Oberhauser, K., & Gratton, C. (2022). Landscape- and local-level variables affect monarchs in Midwest grasslands. Landscape Ecology, 37, 93-108.",
  doi_paper = "10.1007/s10980-021-01341-4", doi_data = "10.5066/P9BERZ62",
  original_license = "CC0 1.0 (US public domain)", derived_license = "CC0 1.0",
  notes = "Survey dates not deposited. Egg/larva per-stem ratios not shipped.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "transect_count", design = "Multi-season (2 summers x 3 surveys)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (agency-published, USGS)", notes = "Single species, monarch adults; IMMP protocol.")
