#!/usr/bin/env Rscript
# Table:  burgstahler_2026_wa_shrubsteppe_mamm_occ
# Source: Dryad doi:10.5061/dryad.gf1vhhn0r (CC0 1.0, as shown on the Dryad page; published
#         2026-08-18). Burgstahler, K., Shipley, L., Stift, A., Woodley, S. & Thornton, D. Data
#         and code from: Effects of wildfire on the distribution of mammals and birds in a
#         working shrub-steppe landscape.
# Paper:  Burgstahler, K. et al. (2026). Ecosphere, doi:10.1002/ecs2.70759. Camera traps at
#         shrub-steppe sites in eastern Washington, USA, 2021-2024, four cameras (A-D, spatial
#         replicates) per site for about 30 days; single-species occupancy for five mammals.
# Data:   CSVs.zip -> CSVs/Mammal detection histories/<Species>_dh.csv for Badger, Cottontail,
#         Coyote, Jackrabbit, MuleDeer (141 sites x cameras A-D, 1 = site use during the ~30-day
#         deployment, 0 = none; no missing cells; identical site order across files, asserted);
#         Mammal covariates/Mammal_site_covs_unstand.csv (year 2021-2024, fire occurrence, age,
#         reburns, area of largest burn (acres), field cover of annual grass / perennial grass /
#         forbs / shrubs (%), vertical cover (cm), % unburned sagebrush within 1 km),
#         Active_days_z.csv and Cam_vis_z.csv (per camera: operating days and vegetation cover
#         7 m in front, both deposited only as z-scores). Bird files are one point count per site
#         (single visit) and are not built. Raw_Data.zip and Code.zip not read for the table
#         (raw record tables, problem sheets, vegetation and bird workbooks; R scripts).
#         Quirk: Cam_vis_z.csv lists the same 141 sites in a different row order from the
#         detection histories; it is joined here by site id, not by row position.
#         The README: no species is federally threatened, and the authors are not concerned
#         about publishing locations.
# Mapping (standard: single-season occupancy with spatial replicates; five species in one
#   table, the authors' analysis set): unit = SiteName (each site surveyed in one year);
#   period = year (__periods); taxon = TAXTAX, SYLVIL (cottontail, genus), CANLAT, LEPCAL,
#   ODOHEM; occasion = camera A..D (occasionKind spatial); y = the cell. obs_: active days and
#   camera visibility (z-scores as deposited). unit_: the site covariates.
#   Survey evidence: deposited_matrix (complete; the authors' analysis-ready histories).
#   Cottontail is given only as "Cottontail" and kept at genus Sylvilagus (eastern Washington
#   has Nuttall's cottontail and introduced eastern cottontail).
#   Not shipped: the bird point counts (one survey per site: replication gate, ruling
#   2026-11-06); other mammal species in the raw record tables (no detection histories
#   deposited for them; the five are the authors' cut); camera coordinates (raw sheets).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "burgstahler_2026_wa_shrubsteppe_mamm_occ"
dir <- download_dryad("10.5061/dryad.gf1vhhn0r", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^CSVs\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "CSVs", "CSVs")
SP <- c(TAXTAX = "Badger", SYLVIL = "Cottontail", CANLAT = "Coyote", LEPCAL = "Jackrabbit", ODOHEM = "MuleDeer")
H <- lapply(SP, function(s) { d <- fread(file.path(b, "Mammal detection histories", paste0(s, "_dh.csv"))); names(d)[1] <- "site"; d })
sites <- H[[1]]$site
stopifnot(length(sites) == 141, !anyDuplicated(sites), all(sapply(H, function(d) identical(d$site, sites))),
          all(sapply(H, function(d) identical(names(d), c("site", "A", "B", "C", "D")))),
          all(sapply(H, function(d) all(as.matrix(d[, -1]) %in% 0:1))))
rdz <- function(f) { d <- fread(file.path(b, "Mammal covariates", f)); names(d)[1] <- "site"
  stopifnot(setequal(d$site, sites), !anyDuplicated(d$site), !anyNA(d)); as.matrix(d[match(sites, d$site), -1]) }
stopifnot(!identical(fread(file.path(b, "Mammal covariates", "Cam_vis_z.csv"))[[1]], sites))   # Cam_vis is in a different site order: joined by id
AD <- rdz("Active_days_z.csv"); CV <- rdz("Cam_vis_z.csv")
sc <- fread(file.path(b, "Mammal covariates", "Mammal_site_covs_unstand.csv"), encoding = "UTF-8")
names(sc) <- sub("^﻿", "", names(sc))
stopifnot(identical(sc$SiteName, sites), all(sc$year %in% 2021:2024), identical(as.integer(table(sc$year)), c(14L, 29L, 70L, 28L)))
Y <- array(unlist(lapply(H, function(d) as.matrix(d[, -1]))), dim = c(141, 4, 5), dimnames = list(sites, NULL, names(SP)))
ucov <- data.frame(fire_occurrence = sc$fire_occurence, age_of_burn_yr = sc$age_of_burn, reburns = sc$reburns,
                   area_of_burn_acres = sc$area_of_burn, annual_grass_pct = sc$`annual_grass_%`,
                   perennial_grass_pct = sc$`perrenial_grass_%`, forb_pct = sc$`forb_%`, vertical_cover_cm = sc$vertical_cover,
                   shrub_pct = sc$`shrub_%`, unburned_sagebrush_1km = sc$burn_buffer)
long <- array_to_eco(Y, site_ids = sites, site_covs = ucov, obs_covs = list(active_days_z = AD, camera_visibility_z = CV))
long[, period := match(sc$year[match(unit, sites)], 2021:2024)]
long <- order_eco(long)
stopifnot(nrow(long) == 141 * 4 * 5, sum(long$y) == sum(Y))
periods <- data.table(period = 1:4, period_year = 2021:2024)
taxa <- make_taxa(names(SP), c("Taxidea taxus", "Sylvilagus", "Canis latrans", "Lepus californicus", "Odocoileus hemionus"),
                  vernacularName = c("American badger", "Cottontail", "Coyote", "Black-tailed jackrabbit", "Mule deer"),
                  taxonRank = c("species", "genus", "species", "species", "species"), allow_higher = "SYLVIL",
                  taxonRemarks = c(NA, "deposited as 'Cottontail' only; Nuttall's and eastern cottontail both occur in eastern Washington", NA, NA, NA))
dataset <- list(
  title = "Camera-trap site use of five mammals at 141 shrub-steppe sites in eastern Washington, four cameras per site, 2021-2024",
  creator = "Burgstahler, Katherine; Shipley, Lisa; Stift, Allison; Woodley, Steven; Thornton, Daniel", pubDate = "2026",
  doi = "10.5061/dryad.gf1vhhn0r", sourceURL = "https://doi.org/10.5061/dryad.gf1vhhn0r",
  citation = "Burgstahler, K., Shipley, L., Stift, A., Woodley, S., & Thornton, D. (2026). Data and code from: Effects of wildfire on the distribution of mammals and birds in a working shrub-steppe landscape [Dataset]. Dryad. https://doi.org/10.5061/dryad.gf1vhhn0r",
  paperDOI = "10.1002/ecs2.70759",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of American badger, cottontail, coyote, black-tailed jackrabbit and mule deer at four camera traps (spatial replicates) per site, deployed about 30 days at 141 burned and unburned shrub-steppe sites in eastern Washington, USA, in one of 2021-2024 each, with fire history and field vegetation covariates and per-camera operating days and visibility (z-scores).",
  samplingProtocol = "Four unbaited camera traps per site (A-D, spatial replicates) deployed for about 30 days; a camera's value is 1 if the species was recorded during its deployment.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one ~30-day deployment per site; cameras are simultaneous spatial replicates (the authors' single-season occupancy)",
  occasionKind = "spatial", taxonInclusion = "recorded",
  geographicCoverage = "Shrub-steppe of eastern Washington, USA; no coordinates in the analysis files",
  temporalCoverage = "2021/2024",
  notShipped = list(other_mammals = "species in the raw camera record tables other than the five the authors modelled (no detection histories deposited for them)",
                    birds = "bird point counts: one survey per site (single visit, not eligible)",
                    camera_coordinates = "camera coordinates in the raw problem sheets (not joined to the analysis files)"),
  notes = "The five species are the authors' analysis set, not every mammal recorded. Active days and camera visibility are deposited only as z-scores and are shipped so; Cam_vis_z.csv is in a different site order from the detection files and is joined by site id. Each site was surveyed in one year; period is that year. Cottontail at genus rank.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/burgstahler_2026_wa_shrubsteppe_mamm_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of five mammals at 141 burned and unburned shrub-steppe sites in eastern Washington (four cameras per site, 2021-2024), with fire and vegetation covariates.",
  url = "https://doi.org/10.5061/dryad.gf1vhhn0r",
  reference = "Burgstahler, K., Shipley, L., Stift, A., Woodley, S., & Thornton, D. (2026). Effects of wildfire on the distribution of mammals and birds in a working shrub-steppe landscape. Ecosphere.",
  doi_paper = "10.1002/ecs2.70759", doi_data = "10.5061/dryad.gf1vhhn0r", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Spatial-replicate occupancy from the analysis-ready histories; single-visit bird counts not built.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (spatial replicates)",
  sampling_protocol = "camera_trap", design = "Single-season (4 cameras per site)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Wildfire gradient; five mammals.")
