#!/usr/bin/env Rscript
# Table:  furnas_2021_ncalifornia_carniv_comm
# Source: Dryad doi:10.6078/D1DT4S (CC0 1.0, as shown on the Dryad page; published 2021-06-28).
#         Furnas, B.J., Goldstein, B.R. & Figura, P. Intermediate fire severity diversity
#         promotes richness of forest carnivores in California.
# Paper:  Furnas, B.J., Goldstein, B.R. & Figura, P.J. (2022). Diversity and Distributions,
#         doi:10.1111/ddi.13374. Camera traps at 1,451 site-years in northern California,
#         2009-2018; each annual season early August to late November/early December, 2-5 week
#         surveys; "a detection history for each site that indicated whether ('1') or not ('0')
#         a species was observed for each 24-hour survey day up to 30 days" (Dryad methods).
# Data:   Furnas_etal_2021_DD_data.RData: y (1451 site-years x 30 days x 15 species, 0/1/NA),
#         yday (1451 x 30, day of year of each day, consecutive, never NA), lag (1451 x 30 x 15,
#         0/1: the authors' previous-day detection term, a function of y), covars.site (site,
#         year, lat, lon, evc, elev, ppt, coast and fire severity / time-since-fire /
#         pyrodiversity metrics at 10- and 25-year windows, whrsize), project (0/1, undefined),
#         spec_transl (code -> common name), standards (scaling constants), rands.out
#         (random prediction points). Asserted: the NA pattern of y is identical across species;
#         (site, year) is unique; 1,340 distinct sites, 111 revisited in later years.
# Mapping (standard: dynamic community occupancy, E9 core): unit = site; period = year
#   2009-2018 (__periods); occasion = survey day 1..30; date = year + yday (exact); taxon =
#   the 15 codes; y = the cell, NA = no row (camera not operating). Survey evidence:
#   deposited_matrix. Covariates: period_ (evc, elev, ppt, coast and the fire metrics, which
#   the authors computed per site-year, and the coordinates, which differ between years at
#   some revisited sites).
#   Coordinates (E7): no species is IUCN CR/EN/VU, but fisher (Pekania pennanti; southern
#   Sierra Nevada DPS) and Sierra Nevada red fox (Vulpes vulpes necator DPS) are listed as
#   endangered under the US Endangered Species Act, and both may be among these detections,
#   so site coordinates (deposited to ~8 dp) are coarsened to the 0.1 degree cell centre with
#   coarsen_coords() as a precaution.
#   Not shipped: lag (derived from y), project (undefined 0/1 flag), rands.out (prediction
#   points, not data), standards.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "furnas_2021_ncalifornia_carniv_comm"
dir <- download_dryad("10.6078/D1DT4S", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "\\.RData$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
e <- new.env(); load(f, envir = e)
stopifnot(setequal(ls(e), c("covars.site", "lag", "project", "rands.out", "spec_transl", "standards", "y", "yday")))
y <- e$y; yday <- e$yday; cs <- as.data.table(lapply(e$covars.site, as.vector)); st <- as.data.table(e$spec_transl)
stopifnot(identical(dim(y), c(1451L, 30L, 15L)), nrow(cs) == 1451, identical(cs$site, dimnames(y)[[1]]),
          !anyDuplicated(cs[, .(site, year)]), uniqueN(cs$site) == 1340, all(cs$year %in% 2009:2018),
          setequal(st$species, dimnames(y)[[3]]), !anyNA(yday), all(apply(yday, 1, diff) == 1),
          all(y %in% c(0, 1, NA)))
na <- is.na(y[, , 1]); stopifnot(all(sapply(2:15, function(k) identical(is.na(y[, , k]), na))))
# coordinates can differ between a revisited site's years (camera moved), so they are period_
nmov <- cs[, .(a = uniqueN(paste(lat, lon))), by = site][a > 1, .N]; stopifnot(nmov > 0, nmov <= 111)
long <- rbindlist(lapply(seq_len(15), function(k) {
  w <- which(!na, arr.ind = TRUE)
  data.table(i = w[, 1], occasion = w[, 2], taxon = dimnames(y)[[3]][k], y = as.integer(y[, , k][w]))
}))
long[, `:=`(unit = cs$site[i], period = cs$year[i] - 2008L,
            date = format(as.IDate(paste0(cs$year[i] - 1L, "-12-31")) + as.integer(yday[cbind(i, occasion)])))]
cc <- coarsen_coords(cs$lat, cs$lon)
pc <- cs[, .(period_evc = evc, period_elev_m = elev, period_ppt_mm = ppt, period_coast = coast,
             period_fire_lo_10 = fire.lo.10, period_fire_mod_10 = fire.mod.10, period_fire_hi_10 = fire.hi.10,
             period_fire_lo_25 = fire.lo.25, period_fire_mod_25 = fire.mod.25, period_fire_hi_25 = fire.hi.25,
             period_fire_mohi_25 = fire.mohi.25, period_pyro_10 = pyro.10, period_pyro_25 = pyro.25,
             period_fire_0_10 = fire_0_10, period_fire_10_20 = fire_10_20, period_fire_20_30 = fire_20_30,
             period_fire_30_40 = fire_30_40, period_fire_40 = fire_40, period_pyro_time = pyro.time,
             period_whrsize = whrsize)]
pc[, `:=`(i = seq_len(.N), period_decimalLatitude = cc$lat, period_decimalLongitude = cc$lon,
          period_coordinateUncertaintyInMeters = cc$uncertainty_m)]
long <- merge(long, pc, by = "i")[, i := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == sum(!na) * 15, sum(long$y) == sum(y, na.rm = TRUE),
          all(substr(long$date, 1, 4) %in% as.character(long$period + 2008L + 0:1)))
stopifnot(uniqueN(long[substr(date, 1, 4) != as.character(period + 2008L), .(unit, period, occasion)]) == 2)   # day of year > 365: two survey days fall in the next January
periods <- data.table(period = 1:10, period_year = 2009:2018)
SCI <- c(BASAST = "Bassariscus astutus", CANLAT = "Canis latrans", LYNRUF = "Lynx rufus", MARAME = "Martes americana",
         MARPEN = "Pekania pennanti", MEPMEP = "Mephitis mephitis", MUSERM = "Mustela erminea", MUSFRE = "Mustela frenata",
         PROLOT = "Procyon lotor", PUMCON = "Puma concolor", SPIGRA = "Spilogale gracilis", TAXTAX = "Taxidea taxus",
         UROCIN = "Urocyon cinereoargenteus", URSAME = "Ursus americanus", VULVUL = "Vulpes vulpes")
codes <- dimnames(y)[[3]]
taxa <- make_taxa(codes, unname(SCI[codes]), vernacularName = st$name[match(codes, st$species)],
                  taxonRemarks = ifelse(codes == "MARPEN", "deposited code MARPEN (Martes pennanti); current name Pekania pennanti",
                                 ifelse(codes == "MUSFRE", "long-tailed weasel; deposited code MUSFRE (Mustela frenata), also placed in Neogale", NA)))
dataset <- list(
  title = "Daily camera-trap detections of 15 carnivore species at 1,340 sites in northern California forests, 2009-2018 (one to three years per site)",
  creator = "Furnas, Brett J.; Goldstein, Benjamin R.; Figura, Peter J.", pubDate = "2021",
  doi = "10.6078/D1DT4S", sourceURL = "https://doi.org/10.6078/D1DT4S",
  citation = "Furnas, B. J., Goldstein, B. R., & Figura, P. (2021). Intermediate fire severity diversity promotes richness of forest carnivores in California [Dataset]. Dryad. https://doi.org/10.6078/D1DT4S",
  paperDOI = "10.1111/ddi.13374",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily detection/non-detection of 15 mammalian carnivores from camera traps at 1,340 sites across northern California forests, surveyed between early August and early December in 2009-2018 for up to 30 days, with day of year, climate, vegetation and fire severity / pyrodiversity covariates per site-year and site-year coordinates coarsened to 0.1 degree.",
  samplingProtocol = "Paired camera traps per hexagon surveyed concurrently for 2-5 weeks between early August and early December each year; all mammal detections identified to species; detection per species per 24-hour survey day, up to 30 days.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a site's annual survey (up to 30 days), open between years; 111 sites were surveyed in more than one year",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Northern California forests, USA (about 38.2-42.0 N, 120-124 W)",
  temporalCoverage = "2009-08/2018-12", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = TRUE, method = "site coordinates (deposited to about 8 decimal places) coarsened to the 0.1 degree cell centre with coarsen_coords(): fisher (southern Sierra Nevada DPS) and Sierra Nevada red fox (DPS) are listed as endangered under the US Endangered Species Act; a precaution, as no species is IUCN CR/EN/VU"),
  notShipped = list(lag = "the authors' previous-day detection term, a function of y", project = "a 0/1 per site-year flag the deposit does not define",
                    rands.out = "random prediction points (not observations)", standards = "covariate scaling constants",
                    exact_coordinates = "site coordinates finer than 0.1 degree (E7 precaution)"),
  notes = paste0("Coordinates differ between years at ", nmov, " revisited sites and are given per site-year (period_). Covariates are per site-year as the authors computed them (period_). Day of year is deposited for all 30 days; y is NA on days the camera was not operating, so a site-year's surveyed days need not be consecutive. Two survey days carry a day of year above 365 and so fall in the following January."))
dataset$temporalCoverage <- paste(substr(min(long$date), 1, 7), substr(max(long$date), 1, 7), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/furnas_2021_ncalifornia_carniv_comm.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of 15 carnivores at 1,340 sites in northern California, 2009-2018 (one to three years per site), with fire severity and pyrodiversity covariates; coordinates coarsened.",
  url = "https://doi.org/10.6078/D1DT4S",
  reference = "Furnas, B. J., Goldstein, B. R., & Figura, P. J. (2022). Intermediate fire severity diversity promotes richness of forest carnivores in California. Diversity and Distributions.",
  doi_paper = "10.1111/ddi.13374", doi_data = "10.6078/D1DT4S", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community camera-trap occupancy over 10 years; coordinates coarsened as a precaution (ESA-listed DPSs).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "camera_trap", design = "Multi-season (10 years, up to 30 daily occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "Coarsened (0.1 deg)", notes = "15 forest carnivores including fisher and Sierra Nevada red fox (ESA DPSs).")
