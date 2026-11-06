#!/usr/bin/env Rscript
# Table:  barrueto_2023_nwt_grizzly_scr
# Source: Dryad, doi:10.5061/dryad.p8cz8w9vz, version 228633 (version 3, published 2023-04-05), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON). Code: Zenodo doi:10.5281/zenodo.7792055
#         (Grizzly_Density_Script.R; not used).
# Paper:  Barrueto, M., Jessen, T., Diepstraten, R. & Musiani, M. (2023). Density and genetic diversity of grizzly
#         bears at the northern edge of their distribution. Ecosphere 14: e4523. https://doi.org/10.1002/ecs2.4523
#         (not read; the design is from the deposit's methods on the Dryad page): a 30,000 km2 study area centred at
#         64.2 N, 110.0 W (Southern Arctic / Taiga Shield, Northwest Territories, Canada) divided into 221 cells of
#         144 km2; one barbed-wire hair-snare tripod near the centre of each cell, lured with a non-reward scent
#         (rotten cow's blood and fish oil early and late in summer; bergamot, raspberry and cranberry oil in
#         mid-summer); six sampling occasions (visits) of 10-14 days per year, mid-June to mid-September; the
#         northern half sampled in 2012 and 2013, the southern half in 2013 and 2014; hair genotyped at 8
#         microsatellites + ZFX/ZFY by Wildlife Genetics International. Hair snares are proximity detectors (at
#         most one detection per individual per detector per occasion); density fitted per year in secr.
#         The abstract calls grizzly bears "a species at risk even in Canada's remote North".
# Data:   EH_2012.txt, EH_2013.txt, EH_2014.txt: secr capture files (tab-separated, CRLF; the 2012 and 2014 files
#           carry thousands of empty tab-only lines, dropped): Session (GB2012..), Individual (GB###), Occasion 1..6,
#           Detector (C###), Sex (F / M). 221 + 443 + 102 = 766 detections, 204 individuals (112 / 165 / 46 per
#           year), no duplicate individual x occasion x detector, sex constant per individual (asserted).
#         GBDetector_Layout_{2012,2013,2014}_lure.txt: secr trap files: Detector, X, Y (UTM zone 12, metres), USAGE
#           (a 6-character occasion string; "111111" at every detector every year, asserted), ONE..SIX = the lure
#           at each occasion ("/BLOOD" marks the start of the secr covariates): BLOOD, BLOOD, BERG, BERRY, BERRY,
#           BLOOD at every detector every year (asserted). 113 / 218 / 105 detectors; the 2012 and 2014 sets are
#           disjoint and together are the 2013 set; each detector has one position across years (asserted).
#         Grizzly_IDs_with_Microsats_-_All_years.csv: genotypes of 205 individuals (Individual, Old_Individual, POP,
#           allele pairs at 8 loci). grizzly_sites_60km_Erase.* (shapefile): the secr habitat mask. README.md.
# Mapping (SCR, binary proximity detectors; E4.4, ruling #30): unitKind individual, unit = Individual (ids are
#   linked across years by genotype), taxon = URSARC, trap = Detector, period = year (1 = 2012, 2 = 2013,
#   3 = 2014), occasion = visit 1..6, y = 1 if the individual's hair was at the detector on that visit.
#   Survey set = effort_table (the deposited usage strings): every individual carries every detector x occasion
#   operated in every year (wild-caught, at risk from the study's first period; sessions with no capture keep
#   their rows, ruling #30): 204 x (113 + 218 + 105) x 6 rows. unit_sex = F / M. obs_lure = the occasion's lure.
#   Coordinates (E7): grizzly bear is IUCN LC, but the source calls it a species at risk in Canada (it is
#   listed as Special Concern under Canada's Species at Risk Act), so it is flagged under E7(a): trap
#   coordinates are centred on the all-year array (local metres, the integer UTM mean subtracted, so distances
#   are exact) and the array's location is given at 0.1 degree in geographicCoverage (E7 scope ruling 2).
#   Not shipped: exact UTM coordinates; the genotypes (genetic data, not detections) and old sample ids; the
#   habitat mask (a model input); density and genetic-diversity estimates (model outputs).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "barrueto_2023_nwt_grizzly_scr"

dir <- download_dryad("10.5061/dryad.p8cz8w9vz", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          all(c("EH_2012.txt", "EH_2013.txt", "EH_2014.txt", "GBDetector_Layout_2012_lure.txt",
                "GBDetector_Layout_2013_lure.txt", "GBDetector_Layout_2014_lure.txt",
                "Grizzly_IDs_with_Microsats_-_All_years.csv", "README.md") %in% list.files(dir)))
rd <- function(f) { d <- fread(file.path(dir, f), colClasses = "character", fill = TRUE)
  setnames(d, sub("^#", "", names(d))); d[nzchar(trimws(d[[1]]))] }
YEARS <- c("2012", "2013", "2014")
E <- rbindlist(lapply(YEARS, function(y) { d <- rd(paste0("EH_", y, ".txt"))
  stopifnot(identical(names(d), c("Session", "Individual", "Occasion", "Detector", "Sex")), all(d$Session == paste0("GB", y)))
  d[, year := y] }))
E[, Occasion := as.integer(Occasion)]
stopifnot(identical(as.vector(table(E$year)), c(221L, 443L, 102L)), all(E$Occasion %in% 1:6),
          all(grepl("^GB[0-9]{3}$", E$Individual)), all(E$Sex %in% c("F", "M")),
          !anyDuplicated(E[, .(year, Individual, Occasion, Detector)]), uniqueN(E$Individual) == 204L,
          identical(E[, uniqueN(Individual), by = year]$V1, c(112L, 165L, 46L)), E[, uniqueN(Sex), by = Individual][, all(V1 == 1L)])

LURE <- c("BLOOD", "BLOOD", "BERG", "BERRY", "BERRY", "BLOOD")
OCC <- c("ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX")
Tr <- rbindlist(lapply(YEARS, function(y) { t <- rd(sprintf("GBDetector_Layout_%s_lure.txt", y))
  stopifnot(identical(names(t), c("Detector", "X", "Y", "USAGE", OCC)), all(t$USAGE == "111111"),
            all(sub("^/", "", t$ONE) == LURE[1]), all(t$TWO == LURE[2]), all(t$THREE == LURE[3]),
            all(t$FOUR == LURE[4]), all(t$FIVE == LURE[5]), all(t$SIX == LURE[6]), !anyDuplicated(t$Detector))
  t[, .(Detector, X = as.numeric(X), Y = as.numeric(Y), year = y)] }))
stopifnot(identical(as.vector(table(Tr$year)), c(113L, 218L, 105L)), uniqueN(Tr$Detector) == 218L,
          Tr[, uniqueN(paste(X, Y)), by = Detector][, all(V1 == 1L)],
          !length(intersect(Tr[year == "2012", Detector], Tr[year == "2014", Detector])),
          setequal(Tr[year == "2013", Detector], Tr[year != "2013", Detector]),
          all(paste(E$year, E$Detector) %in% paste(Tr$year, Tr$Detector)),
          all(Tr$X > 4.6e5 & Tr$X < 6.4e5), all(Tr$Y > 7.0e6 & Tr$Y < 7.23e6))
gen <- fread(file.path(dir, "Grizzly_IDs_with_Microsats_-_All_years.csv"))
stopifnot(nrow(gen) == 205L, all(E$Individual %in% gen$Individual))

# every individual x every detector-occasion operated in every year
sv <- Tr[, .(trap = Detector, year)][, .(occasion = 1:6), by = .(trap, year)]
ind <- unique(E[, .(unit = Individual, unit_sex = Sex)])
long <- CJ(unit = ind$unit, k = seq_len(nrow(sv)))
long <- cbind(long[, .(unit)], sv[long$k])
long <- merge(long, E[, .(unit = Individual, trap = Detector, year, occasion = Occasion, y = 1L)],
              by = c("unit", "trap", "year", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, ind, by = "unit")
long[, `:=`(taxon = "URSARC", period = match(year, YEARS), obs_lure = tolower(LURE[occasion]))]
long[, year := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 204L * (113L + 218L + 105L) * 6L, sum(long$y) == 766L)
cat(sprintf("  %d rows, %d detections, %d individuals\n", nrow(long), sum(long$y), uniqueN(long$unit)))

utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM, northern hemisphere
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  list(lat = lat * 180 / pi, lon = (zone - 1) * 6 - 180 + 3 + lon * 180 / pi)
}
tr1 <- unique(Tr[, .(trap = Detector, X, Y)])
cx <- round(mean(tr1$X)); cy <- round(mean(tr1$Y))
ctr <- utm_to_ll(cx, cy, zone = 12)
stopifnot(abs(ctr$lat - 64.2) < 0.5, abs(ctr$lon + 110.0) < 1)
ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
yrs <- Tr[, .(years_operated = paste(year, collapse = ";")), by = .(trap = Detector)]
traps <- tr1[, .(trap, x_m = X - cx, y_m = Y - cy)][yrs, on = "trap"]
traps[, occasions_operated := 6L * lengths(strsplit(years_operated, ";"))]
stopifnot(nrow(traps) == 218L, max(abs(traps$x_m)) < 1e5, max(abs(traps$y_m)) < 1.2e5)

taxa <- make_taxa("URSARC", "Ursus arctos", vernacularName = "Grizzly bear (brown bear)")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:3, year = as.integer(YEARS), season = "mid-June to mid-September",
                      area_sampled = c("northern half", "whole study area", "southern half"),
                      n_detectors = c(113L, 218L, 105L), n_individuals_detected = c(112L, 165L, 46L),
                      n_detections = c(221L, 443L, 102L))

dataset <- list(
  title = "Hair-snag spatial capture-recapture of 204 grizzly bears at 218 lured detectors over three summers, northern edge of the range, Northwest Territories, Canada, 2012-2014",
  creator = "Barrueto, Mirjam; Jessen, Tyler; Diepstraten, Rianne; Musiani, Marco", pubDate = "2023",
  doi = "10.5061/dryad.p8cz8w9vz", sourceURL = "https://doi.org/10.5061/dryad.p8cz8w9vz",
  citation = "Barrueto, M., Jessen, T., Diepstraten, R., & Musiani, M. (2023). Density and genetic diversity of grizzly bears at the northern edge of their distribution [Dataset]. Dryad. https://doi.org/10.5061/dryad.p8cz8w9vz",
  paperDOI = "10.1002/ecs2.4523",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Non-invasive genetic sampling of grizzly bears with barbed-wire hair-snare tripods, one per 144 km2 cell over a 30,000 km2 tundra and taiga study area in the Northwest Territories, six 10-14-day occasions each summer 2012-2014 (northern half 2012-2013, southern half 2013-2014); individuals identified from microsatellite genotypes. The authors estimated density per year with spatial capture-recapture (secr). One row per bear x detector x visit operated.",
  samplingProtocol = "Barbed-wire hair-snare tripods (helicopter-deployed) near the centre of each 144 km2 grid cell, lured with a non-reward scent (cow's blood and fish oil, or bergamot / raspberry / cranberry oil in mid-summer), visited six times per summer at 10-14-day intervals; hair genotyped at 8 microsatellites and a sex marker; a proximity detector (at most one detection per bear per detector per visit).",
  samplingProtocolCode = "hair_snag", surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "each year (period) is a closed session of six visits, as in the authors' per-year secr fits; individuals are linked across years by genotype, so the table also supports open multi-session models. Every bear carries rows in all three years (ruling #30), including years with no capture and years whose detectors were in the other half of the study area.",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "none",
  geographicCoverage = sprintf("Coppermine River Upland and Takijuq Lake Upland ecoregions, Northwest Territories, Canada (tree line to the Nunavut border); detector-array centroid %.2f, %.2f (0.1 degree cell centre)", ctr_c$lat, ctr_c$lon),
  temporalCoverage = "2012-06/2014-09",
  crs = "local metres centred on the detector-array centroid (source: UTM zone 12, metres; the integer mean subtracted, so distances are exact)",
  coordinatesCoarsened = list(value = TRUE, method = "detector coordinates centred on the all-year array centroid by the processor (local metres; exact UTM zone 12 positions withheld) because the source calls the grizzly bear a species at risk in Canada (Special Concern under the Species at Risk Act; E7(a)); the centroid is given at 0.1 degree in geographicCoverage"),
  covariateNote = "unit_sex: F / M from the ZFX/ZFY marker. obs_lure: the occasion's lure as deposited (blood = rotten cow's blood and fish oil; berg = bergamot oil; berry = raspberry and cranberry oil), the same at every detector. __traps: x_m, y_m (local metres), years_operated, occasions_operated.",
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; binary proximity detectors; every detector operated all six visits in each year it was deployed (deposited usage strings all 1).",
  notShipped = list(utm_coordinates = "exact UTM zone 12 detector positions (flagged taxon, E7(a)); shipped centred in local metres",
                    genotypes = "Grizzly_IDs_with_Microsats_-_All_years.csv: microsatellite genotypes of 205 individuals and old sample ids (genetic data, not detections; one genotyped individual has no detection in the capture files)",
                    mask = "grizzly_sites_60km_Erase.shp: the secr habitat mask (a model input)",
                    model_output = "density, detection, sigma and genetic-diversity estimates"),
  notes = "The 2012 and 2014 detector sets are disjoint halves of the 2013 set. 221 grid cells are described in the methods; 218 detectors are in the deposit.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps,
                  script = "data/barrueto_2023_nwt_grizzly_scr.R")
stage_dict_row(TABLE,
  description = "Hair-snag spatial capture-recapture of 204 genotyped grizzly bears at 218 lured barbed-wire detectors, six visits per summer 2012-2014, Northwest Territories, Canada; one row per bear x detector x visit, trap coordinates centred.",
  url = "https://doi.org/10.5061/dryad.p8cz8w9vz",
  reference = "Barrueto, M., Jessen, T., Diepstraten, R., & Musiani, M. (2023). Density and genetic diversity of grizzly bears at the northern edge of their distribution. Ecosphere, 14, e4523. https://doi.org/10.1002/ecs2.4523",
  doi_paper = "10.1002/ecs2.4523", doi_data = "10.5061/dryad.p8cz8w9vz",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "secr capture and trap files; detectors centred in local metres (species at risk in Canada, E7(a)); genotypes and habitat mask not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (multi-session, proximity detectors)",
  sampling_protocol = "hair_snag", design = "Multi-session (3 summers x 6 visits; 218 detectors)",
  realm = "Terrestrial", country = "CAN", coordinates = "Coarsened (trap coordinates centred on the detector array, local metres; species at risk in Canada)",
  notes = "Experimental (E9): genetic hair-snag SCR; ids linked across years.")
