#!/usr/bin/env Rscript
# Table:  leone_2019_minnesota_monarch_nmix
# Source: USGS ScienceBase doi:10.5066/P940ICLS (item 5d487e82e4b01d82ce8dddb1, published
#   2019-08-06). Leone, J.B., Larson, D.L., Larson, J.L., Pennarola, N.P. & Oberhauser, K.
#   (2019). Monarch densities in burned or grazed Minnesota remnant prairie, 2016-2017. U.S.
#   Geological Survey data release. Licence: US public domain (USGS data release; no licence
#   restriction in the FGDC record), shipped as CC0 1.0 as for the other USGS tables.
# Paper:  Leone, J.B., Larson, D.L., Larson, J.L., Pennarola, N. & Oberhauser, K. (2019). Adult
#   monarch (Danaus plexippus) abundance is higher in burned sites than in grazed sites.
#   Frontiers in Ecology and Evolution 7: 435, doi:10.3389/fevo.2019.00435 (open access).
# Data:   MonarchAbundanceBySite.csv: 117 rows, one per site x survey visit (asserted unique):
#           20 remnant prairies (SiteID B-1..B-10 burned, G-1..G-10 grazed), three visits per
#           summer (Survey E/M/L) with Date, in 2016 and 2017; G-1 was surveyed in 2017 only
#           (paper: "60 surveys at burned sites and 57 at grazed sites"). NumMonarchs = adult
#           monarchs on the visit's Pollard walk. ForbFreq, MilkweedFreq (frequency of
#           occurrence in 0.5 x 2 m vegetation plots, once per site-year), TimeSinceMgmt (per
#           site-year), PctPrairie (1.5-km buffer), MgmtType, SiteArea (ha), YearsManaged
#           (2005-2017), StockingRate (grazed sites; 0 at burned sites) per site.
#           CommonName/ButterflySpeciesID/Genus/Species are constant (Monarch, Danple): the
#           deposit is the monarch subset of a full butterfly survey.
#         FGDC metadata xml (attribute definitions).
# Mapping (N-mixture, open / multi-season): unit = site, taxon = DANPLE, period = year
#   (1 = 2016, 2 = 2017), occasion = visit (E = 1, M = 2, L = 3), date = visit date (ISO),
#   y = NumMonarchs. Survey evidence: row_presence: one row per conducted visit with explicit
#   zero counts; G-1 in 2016 was not surveyed and has no rows. Kept separate from the Wisconsin
#   monarch table (bruce_2021_wisconsin_monarch_nmix): different protocol (400-m Pollard walk
#   by one observer vs IMMP transects), region, sites and years.
#   unit_: management (burned / grazed), site area, years managed, stocking rate, percent
#   prairie within 1.5 km. period_: forb and milkweed frequency, years since last management.
#   Not shipped: nothing; the species-name columns are constant and live in __taxa.
#   Coordinates: none deposited (sites include private land; ids only).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "leone_2019_minnesota_monarch_nmix"
SB <- "https://www.sciencebase.gov/catalog/file/get/5d487e82e4b01d82ce8dddb1?f=%s"
f <- download_cached(sprintf(SB, "__disk__93%2F11%2F97%2F93119776283c868c26ba340fc2a451da781c00dc"), TABLE, filename = "MonarchAbundanceBySite.csv")
x <- fread(f)
stopifnot(identical(names(x), c("CommonName", "ButterflySpeciesID", "Genus", "Species", "SiteID", "ForbFreq", "MilkweedFreq",
  "PctPrairie", "MgmtType", "Year", "Date", "Survey", "SiteArea", "YearsManaged", "TimeSinceMgmt", "StockingRate", "NumMonarchs")))
stopifnot(nrow(x) == 117L, uniqueN(x$SiteID) == 20L, !anyDuplicated(x[, .(SiteID, Year, Survey)]),
          all(x$CommonName == "Monarch"), all(x$ButterflySpeciesID == "Danple"), all(x$Genus == "Danaus"), all(x$Species == "plexippus"),
          setequal(x$Survey, c("E", "M", "L")), setequal(x$Year, 2016:2017), setequal(x$MgmtType, c("B", "G")),
          all(substr(x$SiteID, 1, 1) == x$MgmtType), !anyNA(x$NumMonarchs), all(x$NumMonarchs >= 0))
stopifnot(identical(x[, .N, keyby = MgmtType]$N, c(60L, 57L)),
          identical(setdiff(paste(rep(unique(x$SiteID), 2), rep(2016:2017, each = 20)), paste(x$SiteID, x$Year)), "G-1 2016"))
x[, d := as.IDate(Date, format = "%m/%d/%Y")]
stopifnot(!anyNA(x$d), all(year(x$d) == x$Year))
# visits are in E < M < L order within each site-year
x[, occ := match(Survey, c("E", "M", "L"))]
stopifnot(x[, !is.unsorted(d[order(occ)]), by = .(SiteID, Year)][, all(V1)])
stopifnot(all(x[, lapply(.SD, uniqueN), by = SiteID, .SDcols = c("PctPrairie", "MgmtType", "SiteArea", "YearsManaged", "StockingRate")][, -1] == 1L),
          all(x[, lapply(.SD, uniqueN), by = .(SiteID, Year), .SDcols = c("ForbFreq", "MilkweedFreq", "TimeSinceMgmt")][, -(1:2)] == 1L),
          all(x[MgmtType == "B", StockingRate] == 0))

long <- x[, .(unit = SiteID, taxon = "DANPLE", y = as.integer(NumMonarchs), period = Year - 2015L, occasion = occ,
              date = format(d), unit_management = ifelse(MgmtType == "B", "burned", "grazed"), unit_area_ha = SiteArea,
              unit_years_managed_2005_2017 = YearsManaged, unit_stocking_rate = StockingRate, unit_pct_prairie_1500m = PctPrairie,
              period_forb_freq = ForbFreq, period_milkweed_freq = MilkweedFreq, period_years_since_mgmt = TimeSinceMgmt)]
stopifnot(nrow(long) == 117L, sum(long$y) == sum(x$NumMonarchs))

periods <- data.table(period = 1:2, year = 2016:2017, n_sites = x[, uniqueN(SiteID), keyby = Year]$V1,
                      note = "summer; three Pollard walks per site (early, mid, late)")
taxa <- make_taxa("DANPLE", "Danaus plexippus", vernacularName = "Monarch")

dataset <- list(
  title = "Repeated Pollard-walk counts of adult monarchs at 20 burned or grazed Minnesota remnant prairies, 2016-2017",
  creator = "Leone, Julia B.; Larson, Diane L.; Larson, Jennifer L.; Pennarola, Nora P.; Oberhauser, Karen",
  pubDate = "2019", doi = "10.5066/P940ICLS", sourceURL = "https://doi.org/10.5066/P940ICLS",
  citation = "Leone, J.B., Larson, D.L., Larson, J.L., Pennarola, N.P., and Oberhauser, K., 2019, Monarch densities in burned or grazed Minnesota remnant prairie, 2016-2017: U.S. Geological Survey data release, https://doi.org/10.5066/P940ICLS.",
  paperDOI = "10.3389/fevo.2019.00435",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
                            note = "USGS data release; US public domain"),
  abstract = "Adult monarchs counted on three 400-m Pollard walks per summer at 10 burned and 10 grazed remnant tallgrass prairies in Minnesota in 2016 and 2017 (117 visits), with forb and milkweed frequency per site-year and management history, stocking rate, site area and surrounding prairie per site. The paper finds monarchs more abundant at burned than at grazed sites.",
  samplingProtocol = "Modified Pollard walk: one observer walked 400 m of transects at 10 m/min, recording monarchs within 2.5 m either side, 5 m ahead and 5 m above, between 09:30 and 18:30 in suitable weather; three visits (early, mid, late) per summer. Vegetation frequency from 0.5 x 2 m plots on stratified random transects, once per site-year.",
  samplingProtocolCode = "pollard_walk", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion (three visits within a summer, May-August); period = year", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "20 remnant tallgrass prairies in the Prairie Parkland Province of western Minnesota, USA (state, federal, TNC and private land); site coordinates not deposited",
  temporalCoverage = "2016-06-15/2017-08-18",
  coordinatesCoarsened = NA,
  notShipped = list(species_columns = "CommonName, ButterflySpeciesID, Genus, Species: constant (the deposit is the monarch subset of a full butterfly survey); in __taxa"),
  notes = "Site G-1 was surveyed in 2017 only. All butterfly surveys were by one observer. 20 units: below the 30-unit floor. Kept apart from bruce_2021_wisconsin_monarch_nmix (different protocol and region).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/leone_2019_minnesota_monarch_nmix.R")

stage_dict_row(TABLE,
  description = "Adult monarch counts on three 400-m Pollard walks per summer at 10 burned and 10 grazed Minnesota remnant prairies, 2016-2017 (117 visits, dated), with management, stocking rate, site area, surrounding prairie, and forb and milkweed frequency per site-year.",
  url = "https://doi.org/10.5066/P940ICLS",
  reference = "Leone, J.B., Larson, D.L., Larson, J.L., Pennarola, N., & Oberhauser, K. (2019). Adult monarch (Danaus plexippus) abundance is higher in burned sites than in grazed sites. Frontiers in Ecology and Evolution, 7, 435.",
  doi_paper = "10.3389/fevo.2019.00435", doi_data = "10.5066/P940ICLS",
  original_license = "CC0 1.0 (US public domain)", derived_license = "CC0 1.0",
  notes = "20 sites (below floor). No coordinates deposited.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (open / multi-season)",
  sampling_protocol = "pollard_walk", design = "Multi-season (2 summers x 3 visits), burned vs grazed", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Single species, monarch adults; management contrast (fire vs grazing).")
