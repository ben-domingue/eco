#!/usr/bin/env Rscript
# Table:  hamer_2021_kooragang_amph_comm
# Source: Dryad doi:10.5061/dryad.b8gtht7b5, version 87334 (version 2, published 2020-10-16),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Hamer, A. J., Schmera, D. & Mahony, M. J. "Multi-species occupancy modeling provides novel
#         insights into amphibian metacommunity structure and wetland restoration".
# Paper:  Hamer, A. J., Schmera, D. & Mahony, M. J. (2021). Multi-species occupancy modeling provides
#         novel insights into amphibian metacommunity structure and wetland restoration. Ecological
#         Applications 31(4), e02293, doi:10.1002/eap.2293 (open access; read from the author copy at
#         real.mtak.hu/138023). Design, species names and covariate definitions from the paper.
# Data:   Model_1_MSOM_Hamer_et_al_Ecol_Appl.R (the authors' WinBUGS script, read: it stacks the eleven
#         species files into a 55 x 28 x 11 array);
#   crisig.csv ... plaorn.csv  one file per species (codes expanded in the paper's Figs 2-3), Site 1..55
#                             x survey1..survey28, 0/1 detection, NA = no survey. Surveys are packed to
#                             the left: a site surveyed five times has columns 1-5 filled.
#   year.csv                  survey year per cell (1 = 2000-01, 2 = 2001-02 breeding season), 0 where
#                             no survey; exactly the non-NA cells of ten species.
#   days.csv                  days since 1 September, standardised by the authors (mean and sd not
#                             deposited); no-survey cells mean-filled.
#   days2.csv                 the quadratic term (the authors' derivation).
#   temp.csv                  air temperature at the start of the survey, standardised; the paper says
#                             a missing reading was replaced by the mean of other sites that night or
#                             the nearby weather station's minimum.
#   wet.csv                   standing water at the site during the survey (0 dry, 1 wet); 0.9 (the
#                             authors' fill) in every no-survey cell.
#   Kooragang_site_covariates.csv  per site: distance to the nearest wetland site, wetland area,
#                             Gambusia presence (0/1), emergent vegetation cover, ephemerality (0/1),
#                             canopy cover; the continuous ones standardised by the authors.
#   Design (paper): 55 waterbodies on Kooragang Island (Hunter River estuary, NSW), two breeding seasons
#   (September-April 2000-01 and 2001-02). 32 sites in a Litoria aurea mark-recapture study were
#   surveyed up to 14 times a year (the deposit has 15 in 2001-02 at two sites, 2 + 15 surveys); the other 23 mostly five times (two then three). A nocturnal survey
#   is about 10 minutes of listening for calling males, then a head-torch visual encounter search of
#   the waterbody and the terrestrial habitat within 10 m. 11 species detected.
#
# Mapping (standard E9 community occupancy, multi-season; responseType detection, unitKind site):
#   unit = site (1..55), taxon = the authors' codes in upper case, period = survey year (1, 2),
#   occasion = the survey's order within the site-year (the column order, which is the order within the
#   year), y = detection. obs_days_std, obs_temp_std (as deposited, standardised), obs_wet (0/1);
#   unit_distsite_std, unit_area_std, unit_gambusia, unit_aqveg_std,
#   unit_ephemeral, unit_canopy_std.
#   Survey evidence: deposited_matrix. A survey exists where year.csv is non-zero; ten species are NA
#   exactly elsewhere. crisig.csv carries ten further cells (sites 47 and 48, 2001-02) as 0 where
#   every other species is NA, year is 0 and the covariates are mean-filled: these are not surveys and
#   are dropped (asserted all 0).
#   Not shipped: days2 (derived), the ten padded crisig cells.
#   Coordinates: none deposited (the paper calls Litoria aurea endangered; it is listed in NSW).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hamer_2021_kooragang_amph_comm"
dir <- download_dryad("doi:10.5061/dryad.b8gtht7b5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "87334"), length(list.files(dir)) == 18L)

species <- c(crisig = "Crinia signifera", limper = "Limnodynastes peronii", limtas = "Limnodynastes tasmaniensis",
             litaur = "Litoria aurea", litcae = "Litoria caerulea", litden = "Litoria dentata",
             litfal = "Litoria fallax", litjer = "Litoria jervisiensis", litlat = "Litoria latopalmata",
             litper = "Litoria peronii", plaorn = "Platyplectrum ornatum")
vern <- c("Eastern froglet", "Striped marsh frog", "Spotted grass frog", "Green and golden bell frog",
          "Green tree frog", "Bleating tree frog", "Eastern dwarf tree frog", "Jervis Bay tree frog",
          "Broad-palmed frog", "Peron's tree frog", "Ornate burrowing frog")
rd <- function(f) { d <- fread(file.path(dir, paste0(f, ".csv")))
  stopifnot(identical(d$Site, 1:55), identical(names(d)[-1], paste0("survey", 1:28))); unname(as.matrix(d[, -1])) }
Y <- lapply(names(species), rd); names(Y) <- names(species)
yr <- rd("year"); days <- rd("days"); temp <- rd("temp"); wet <- rd("wet")
surv <- yr > 0
stopifnot(all(yr %in% 0:2), sum(surv) == 980L,
          all(vapply(Y[-1], function(m) identical(!is.na(m), surv), logical(1))),
          all(unlist(Y) %in% c(0, 1, NA)))
# the ten padded crisig cells: zeros outside the survey set, all at sites 47-48
pad <- !is.na(Y$crisig) & !surv
stopifnot(sum(pad) == 10L, all(Y$crisig[pad] == 0), all(which(pad, arr.ind = TRUE)[, 1] %in% 47:48),
          !any(is.na(Y$crisig) & surv))
# surveys packed left, year non-decreasing along the row
stopifnot(all(apply(surv, 1, function(r) all(diff(r) <= 0))),
          all(apply(yr, 1, function(r) all(diff(r[r > 0]) >= 0))),
          identical(as.integer(table(rowSums(surv))), c(1L, 22L, 1L, 1L, 1L, 4L, 25L)),
          all(wet[surv] %in% 0:1), all(abs(wet[!surv] - 0.9) < 1e-9),
          !anyNA(days[surv]), !anyNA(temp[surv]))
sc <- fread(file.path(dir, "Kooragang_site_covariates.csv"))
stopifnot(identical(sc$Site, 1:55), all(sc$Gambusia %in% 0:1), all(sc$Ephem %in% 0:1))

idx <- which(surv, arr.ind = TRUE)
base <- data.table(unit = idx[, 1], col = idx[, 2], period = yr[idx], obs_days_std = days[idx],
                   obs_temp_std = temp[idx], obs_wet = as.integer(wet[idx]))
setorder(base, unit, col)
base[, occasion := seq_len(.N), by = .(unit, period)]
long <- rbindlist(lapply(names(species), function(s) base[, .(unit, taxon = toupper(s), y = as.integer(Y[[s]][cbind(unit, col)]),
  period = as.integer(period), occasion, obs_days_std, obs_temp_std, obs_wet)]))
long <- merge(long, sc[, .(unit = Site, unit_distsite_std = Distsite, unit_area_std = Area, unit_gambusia = Gambusia,
                           unit_aqveg_std = Aqveg, unit_ephemeral = Ephem, unit_canopy_std = Canopy)], by = "unit")
long[, unit := as.character(unit)]
long <- order_eco(long)
stopifnot(nrow(long) == 980L * 11L, !anyNA(long$y),
          identical(as.numeric(long[order(taxon), sum(y), by = taxon]$V1),
                    unname(vapply(Y, function(m) sum(m[surv]), numeric(1))[order(toupper(names(species)))])),
          uniqueN(long[y == 1, .(unit, taxon)]) == 39L + 42L + 34L + 28L + 4L + 8L + 39L + 1L + 3L + 14L + 3L,
          max(long$occasion) == 15L, long[, uniqueN(occasion), by = .(unit, period)][V1 == 15L, .N] == 2L)

taxa <- make_taxa(toupper(names(species)), unname(species), vernacularName = vern)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# NA = GBIF's accepted name (Ranoidea) differs from the IUCN record's; for these two the record carries
# the deposit's own name (same species), and its category is taken (GBIF IUCN endpoint, checked 2026-11-05)
same_sp <- c("Litoria aurea" = "NT", "Litoria caerulea" = "LC")
taxa[is.na(taxon_iucnCategory) & scientificName %in% names(same_sp), taxon_iucnCategory := same_sp[scientificName]]
stopifnot(!anyNA(taxa$taxon_iucnCategory))
periods <- data.table(period = 1:2, season = c("2000-2001", "2001-2002"), months = "September-April")

dataset <- list(
  title = "Detection/non-detection of eleven frog species at 55 wetlands on Kooragang Island, New South Wales, Australia, over two breeding seasons, 2000-2002",
  creator = "Hamer, Andrew J.; Schmera, Dénes; Mahony, Michael J.",
  pubDate = "2020", doi = "10.5061/dryad.b8gtht7b5", sourceURL = "https://doi.org/10.5061/dryad.b8gtht7b5",
  citation = "Hamer, A. J., Schmera, D., & Mahony, M. J. (2020). Multi-species occupancy modeling provides novel insights into amphibian metacommunity structure and wetland restoration [Dataset]. Dryad. https://doi.org/10.5061/dryad.b8gtht7b5",
  paperDOI = "10.1002/eap.2293",
  abstract = "Repeated nocturnal frog surveys (call listening then visual encounter search) at 55 waterbodies on Kooragang Island in the Hunter River estuary, New South Wales, over the 2000-01 and 2001-02 breeding seasons: 32 sites surveyed up to 14 times a year as part of a green and golden bell frog mark-recapture study, the other 23 mostly five times. Eleven species from three families were detected; the paper fits a multi-species occupancy model with wetland area, connectivity, Gambusia presence, emergent vegetation, ephemerality and canopy cover.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Nocturnal surveys, mostly by one person: about 10 minutes of quiet listening for calling males at the waterbody, then a head-torch visual encounter search of the waterbody and of trees and shrubs within 10 m, effort in proportion to waterbody area and vegetation complexity; air temperature and water level recorded at the start.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occupancy assumed constant within each breeding season (September-April); the paper treats the species pool as closed across both years with a year effect on detection",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "2000-09/2002-04",
  geographicCoverage = "Kooragang Island, Hunter River estuary, Newcastle, New South Wales, Australia (no site coordinates deposited)",
  notes = "occasion is the survey's order within the site and season as deposited (surveys are packed left in the source matrices). obs_days_std (days since 1 September) and obs_temp_std are the authors' standardised values; the means and sds are not deposited. Some temperatures were filled by the authors from other sites that night or the nearest weather station (paper). Site covariates other than the 0/1 ones are standardised as deposited. taxon_iucnCategory from the IUCN record via GBIF; Litoria aurea is the green and golden bell frog.",
  notShipped = list(days2 = "quadratic term of days (derived by the authors)",
                    crisig_padding = "10 cells of crisig.csv (sites 47-48, 2001-02) coded 0 where no survey happened (all other species NA, year 0, covariates mean-filled)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hamer_2021_kooragang_amph_comm.R")
stage_dict_row(TABLE,
  description = "Detection/non-detection of eleven frog species at 55 wetlands on Kooragang Island, NSW, Australia, over the 2000-01 and 2001-02 breeding seasons (5 to 28 nocturnal call and visual surveys per site), with standardised date and temperature and six wetland covariates.",
  url = "https://doi.org/10.5061/dryad.b8gtht7b5",
  reference = "Hamer, A. J., Schmera, D., & Mahony, M. J. (2021). Multi-species occupancy modeling provides novel insights into amphibian metacommunity structure and wetland restoration. Ecological Applications, 31(4), e02293.",
  doi_paper = "10.1002/eap.2293", doi_data = "10.5061/dryad.b8gtht7b5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. Ten zero cells in crisig.csv outside the survey set dropped; covariates standardised as deposited.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "visual_encounter", design = "Multi-season (2 breeding seasons, 2-14 surveys per season)",
  realm = "Freshwater", country = "AUS", coordinates = "None in source",
  notes = "Eleven frog species incl. the green and golden bell frog; unbalanced visits (mark-recapture sites surveyed far more often).")
