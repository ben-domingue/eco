#!/usr/bin/env Rscript
# Table:  swanson_2018_iowa_amph_occ
# Source: USGS ScienceBase doi:10.5066/F7D799PV (USGS data release, 2018; use constraints "None";
#         US public domain, recorded as CC0 1.0)
#   Swanson, J., 2018, Amphibian occupancy and effects of habitat use on pesticide exposure in Iowa
#   wetlands: U.S. Geological Survey data release.
# Paper:  Swanson, J.E., 2017, Amphibian occupancy and effects of habitat use on pesticide exposure in
#   Iowa agricultural wetlands (MS thesis, Iowa State University).
# Data:   Swanson_IOWACOOP_DataRelease.zip: the spreadsheet as CSVs (and the .xlsx itself).
#         "<SP> <stage>.csv": 14 site x survey matrices (27 wetlands x Survey 1..7, 1 = present,
#         0 = absent, no missing cells) for American toad (ANAM), gray treefrog (HYVE, Hyla spp.),
#         northern leopard frog (LIPI) and boreal chorus frog (PSMA), by life stage: adult, egg mass,
#         tadpole, metamorph (no HYVE or PSMA egg file: per the deposited Meta Data.csv completeness
#         report, "We did not report detections of Gray treefrog (Hyla spp.) or Boreal chorus frog
#         (Pseudacris maculata) egg masses because they were not detected in any surveys").
#         Survey Temperatures.csv: air temperature at each survey. Site Information.csv: county,
#         latitude / longitude in degrees-minutes-seconds (the degree sign is mis-encoded), owner.
#         Meta Data.csv: methodology: each wetland surveyed four times in 2015 and three times in
#         2016 by one or two observers walking the perimeter (adults, egg masses, calling males)
#         with a dipnet sample every 3 m (tadpoles, metamorphs); coordinates of privately owned
#         wetlands are approximate (2014 Farm Bill). Tracked Frog Information, PSDs, Frog PSDs and
#         Frog Tissue: radio telemetry of 72 leopard frogs and pesticide samplers / tissue.
#         Asserted: every matrix is 27 sites x 7 surveys of 0/1 with the same site list.
# Mapping: unit = wetland, period = year (1 = 2015: surveys 1-4; 2 = 2016: surveys 5-7), occasion =
#   survey within the year, taxon = species x life stage (E6: stages recorded separately at one
#   survey), y = presence (surveyEvidence deposited_matrix). HYVE_EGG and PSMA_EGG were searched
#   for at every survey and never found (the completeness report above): they carry y = 0 at every
#   survey (taxonInclusion target). obs_air_temp_c; unit_county, unit_ownership; coordinates as
#   published (private sites displaced by the source, E7.5).
# Not shipped: telemetry and pesticide data (movement and exposure, not detection surveys).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "swanson_2018_iowa_amph_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5a8c8a44e4b069906054deee?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
z <- download_cached(fl[["Swanson_IOWACOOP_DataRelease.zip"]], TABLE, filename = "Swanson_IOWACOOP_DataRelease.zip")
ud <- file.path(dirname(z), "unz"); if (!dir.exists(ud)) unzip(z, exdir = ud)
dd <- file.path(ud, "Swanson_IOWACOOP_DataRelease")
rd <- function(f) fread(file.path(dd, f), encoding = "Latin-1", header = TRUE)
stg <- c(Ad = "AD", Egg = "EGG", Tad = "TAD", Meta = "MET")
files <- CJ(sp = c("ANAM", "HYVE", "LIPI", "PSMA"), st = names(stg))[file.exists(file.path(dd, paste0(sp, " ", st, ".csv")))]
stopifnot(nrow(files) == 14, !nrow(files[sp %in% c("HYVE", "PSMA") & st == "Egg"]))
sites <- NULL
m <- rbindlist(lapply(seq_len(nrow(files)), function(i) {
  d <- rd(paste0(files$sp[i], " ", files$st[i], ".csv"))[, 1:8]
  setnames(d, c("Site", paste0("s", 1:7)))
  d[, Site := trimws(Site)]
  if (is.null(sites)) sites <<- d$Site
  stopifnot(nrow(d) == 27, identical(d$Site, sites), all(unlist(d[, -1]) %in% 0:1))
  melt(d[, lapply(.SD, as.integer), by = Site], id.vars = "Site", variable.name = "s", value.name = "y")[, taxon := paste0(files$sp[i], "_", stg[[files$st[i]]])]
}))
# the two egg stages searched for and never detected (completeness report)
ne <- CJ(Site = sites, s = paste0("s", 1:7), taxon = c("HYVE_EGG", "PSMA_EGG"))[, y := 0L]
m <- rbind(m, ne[, .(Site, s, y, taxon)])
m[, sn := as.integer(sub("s", "", s))]
tp <- rd("Survey Temperatures.csv")[, 1:8]; setnames(tp, c("Site", paste0("s", 1:7))); tp[, Site := trimws(Site)]
stopifnot(setequal(tp$Site, sites))
tp <- melt(tp, id.vars = "Site", variable.name = "s", value.name = "temp")[, sn := as.integer(sub("s", "", s))]
si <- rd("Site Information.csv"); si[, Site := trimws(Site)]
stopifnot(setequal(si$Site, sites))
dms <- function(x) { n <- regmatches(x, gregexpr("[0-9]+(\\.[0-9]+)?", x)); sapply(n, function(v) { v <- as.numeric(v); stopifnot(length(v) == 3); v[1] + v[2] / 60 + v[3] / 3600 }) }
si[, `:=`(lat = round(dms(Latitude), 5), lon = -round(dms(Longitude), 5))]
stopifnot(all(grepl("N", si$Latitude)), all(grepl("W", si$Longitude)), all(si$lat > 42.9 & si$lat < 43.5), all(si$lon > -93.8 & si$lon < -93.1))
m <- merge(merge(m, tp[, .(Site, sn, temp)], by = c("Site", "sn")), si[, .(Site, County, Ownership, lat, lon)], by = "Site")
long <- m[, .(unit = Site, taxon, y = as.integer(y), period = ifelse(sn <= 4, 1L, 2L), occasion = ifelse(sn <= 4, sn, sn - 4L),
              unit_county = County, unit_ownership = Ownership, unit_decimalLatitude = lat, unit_decimalLongitude = lon,
              unit_private = as.integer(Ownership == "Private Owner"), obs_air_temp_c = temp)]
stopifnot(nrow(long) == 27 * 7 * 16, sum(long$y) == 456, sum(long$unit_private) == 4 * 7 * 16)
sp <- c(ANAM = "Anaxyrus americanus", HYVE = "Hyla", LIPI = "Lithobates pipiens", PSMA = "Pseudacris maculata")
vn <- c(ANAM = "American toad", HYVE = "Gray treefrog", LIPI = "Northern leopard frog", PSMA = "Boreal chorus frog")
ls <- c(AD = "adult", EGG = "egg", TAD = "tadpole", MET = "metamorph")
tx <- sort(unique(long$taxon)); s4 <- sub("_.*", "", tx); st <- sub(".*_", "", tx)
taxa <- make_taxa(tx, unname(sp[s4]), lookupName = ifelse(s4 == "HYVE", "Hyla Laurenti, 1768", unname(sp[s4])), vernacularName = unname(vn[s4]), taxonRank = ifelse(s4 == "HYVE", "genus", "species"),
                  lifeStage = unname(ls[st]),
                  taxonRemarks = paste0(ifelse(s4 == "HYVE", "source: Gray treefrog (Hyla spp.), H. versicolor and H. chrysoscelis not separated; ", ""),
                                        ifelse(st == "EGG", "egg masses", ""),
                                        ifelse(tx %in% c("HYVE_EGG", "PSMA_EGG"), "; never detected (source completeness report), all zeros", "")))
taxa[taxonRemarks == "", taxonRemarks := NA_character_]
dataset <- list(
  title = "Presence of four anuran species by life stage at 27 agricultural wetlands in north-central Iowa, 2015-2016",
  creator = "Swanson, Jennifer",
  pubDate = "2018", doi = "10.5066/F7D799PV", sourceURL = "https://doi.org/10.5066/F7D799PV",
  citation = "Swanson, J., 2018, Amphibian occupancy and effects of habitat use on pesticide exposure in Iowa wetlands: U.S. Geological Survey data release, https://doi.org/10.5066/F7D799PV.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Repeat surveys of 27 wetlands in Cerro Gordo, Hancock, Winnebago and Worth counties, Iowa, four times in 2015 and three times in 2016, recording the presence of adults, egg masses, tadpoles and metamorphs of American toad, gray treefrog, northern leopard frog and boreal chorus frog, for single-season occupancy models of anuran wetland use in an agricultural landscape.",
  samplingProtocol = "One or two observers walked the wetland perimeter, searching for adults and egg masses and listening for calling males, with a dipnet sample every 3 m for tadpoles and metamorphs; surveys lasted 1-2 hours.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors fit single-season occupancy models within each year; surveys span May to August", occasionKind = "time",
  taxonInclusion = "target",
  geographicCoverage = list(description = "Cerro Gordo, Hancock, Winnebago and Worth counties, north-central Iowa, USA",
                            boundingBox = list(west = min(si$lon), east = max(si$lon), south = min(si$lat), north = max(si$lat))),
  temporalCoverage = "2015-05/2016-08",
  coordinatesCoarsened = list(value = FALSE, method = "as published; the source states that coordinates of the four privately owned wetlands (unit_private = 1) are approximate (2014 Farm Bill)"),
  notShipped = list(telemetry = "Tracked Frog Information: radio telemetry of 72 leopard frogs (movement, habitat use, fate)",
                    pesticides = "PSDs, Frog PSDs and Frog Tissue: pesticide samplers and tissue concentrations"),
  notes = "HYVE_EGG and PSMA_EGG are all zeros: the source's completeness report says these egg masses were searched for and never detected.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:2, year = 2015:2016), script = "data/swanson_2018_iowa_amph_occ.R")
stage_dict_row(TABLE,
  description = "Presence of adults, egg masses, tadpoles and metamorphs of four anuran species on seven surveys (2015-2016) of 27 agricultural wetlands in north-central Iowa, with survey air temperature, county, ownership and coordinates.",
  url = "https://doi.org/10.5066/F7D799PV",
  reference = "Swanson, J. (2018). Amphibian occupancy and effects of habitat use on pesticide exposure in Iowa wetlands. U.S. Geological Survey data release.",
  doi_data = "10.5066/F7D799PV", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "taxon = species x life stage; private-site coordinates approximate, as published.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Single-season occupancy (multi-species, by life stage)", sampling_protocol = "visual_encounter",
  design = "Multi-season (2 years x 3-4 surveys)", realm = "Freshwater", country = "USA", coordinates = "As published",
  notes = "Agricultural wetlands; four private sites have approximate coordinates (source).")
