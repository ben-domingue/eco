#!/usr/bin/env Rscript
# Table:  szewczyk_2019_colorado_ants_binom
#         szewczyk_2019_colorado_ants_exact_binom (E7.3 sibling without the IUCN-threatened species)
# Source: Dryad doi:10.5061/dryad.rt679ng (CC0 1.0, as shown on the Dryad page; version 15833).
#         Szewczyk, T. M. & McCain, C. M. Data from: Disentangling elevational richness: a
#         multi-scale hierarchical Bayesian occupancy model of Colorado ant communities.
# Paper:  Szewczyk, T. M. & McCain, C. M. (2019). Ecography 42(5), 977-988, doi:10.1111/ecog.04115.
#         Four elevational transects in Colorado (two in the San Juan Mountains, SJ-1 and SJ-2; two
#         in the Front Range, FR-1 Big Thompson and FR-2 Boulder), 7-8 sites each, 20 pitfall-trap
#         pairs per site, the traps emptied up to 6 times over a 90-day summer, 2010-2012.
#         Supplementary Appendix 1 (Ecography; the publisher's link is dead, the copy used was sent
#         by C. McCain on 2026-11-11 and is byte-identical to the 2019 Wayback Machine copy of
#         ecography.org/sites/ecography.org/files/appendix/ecog-04115.pdf), Table A1: for every
#         site, transect, year sampled, elevation, latitude and longitude (0.01 degree), number of
#         collections, observed species and genus richness; the excluded disturbed sites
#         (SJ-1 3241 m, SJ-2 3517 m, FR-2 3659 m) are in grey italic.
# Data:   Three JAGS input lists (rds), as deposited:
#         SJ_data_for_JAGS.rds: y[92 species, 14 sites, 20 traps] = collections with the species
#           out of k[14 sites, 20 traps]; species named Genus+EPITHET in dimnames(y)[[1]] (the tax
#           data frame holds only numbers: the 2026-11-05 intake missed the names); sites by short
#           codes (Air, WbC, ...); SiteX[14, 6] (HabH, SoilH, lArea, Tmean, MODIS, DayVar) and
#           TrapX[14, 20, 4] (Canopy, nTrees, MnSumVeg, MnBareGrd), standardised; genCov, Im (genus
#           phylogenetic covariance), tax (species -> genus index).
#         FR-all_data_for_JAGS.rds: y[76 species, 15 sites, 20 traps], k[15, 20], Y (site-level
#           species x site detected, derived), elS (Transect, Site, SiteRank, Elevation), tax, genCov.
#           No covariates.
#         FR-shared_data_for_JAGS.rds: the Front Range data cut to the 64 species shared with the
#           San Juan. Quirk: FR-all's species labels slip from its row 69 on (see the assertions); FR-shared
#           is the correctly labelled file there, and FR-all lost TemnothoraxTRICARINATUS.
#         Quirk: the SJ sites carry no transect or elevation. They are two blocks of 7 in the
#           deposit; each block's observed species and genus richness per site equals Table A1's
#           SJ-1 and SJ-2 rows in elevation order exactly (asserted), which fixes every site's
#           transect, elevation, year and coordinates.
# Mapping (E2 binomial_count, ruling #34; community, E4.2; multi-scale, cluster_id = site):
#   unit = one pitfall-trap pair, "<site>_<trap 01-20>"; cluster_id = the site code; taxon =
#   Genus_epithet from the deposited name (Crematogaster_spp at genus rank; Formica_adamsi_alpina
#   a subspecies); period = year sampled (2010 = 1, 2011 = 2, 2012 = 3; each site in one year,
#   Table A1); y = collections in which the species was in the trap, obs_trials = k (collections of
#   that trap). unit_region (SJ / FR), unit_transect (SJ-1, SJ-2, FR-1, FR-2), unit_elev_m,
#   unit_decimalLatitude / unit_decimalLongitude (Table A1, site level); San Juan only (no Front
#   Range covariates deposited, NA there): unit_site_* (SiteX) and unit_* (TrapX), standardised
#   as deposited (suffix _z).
#   Survey evidence: effort_table. A trap was surveyed iff k > 0 (6 SJ and 23 FR trap pairs have
#   k = 0 and y = 0 throughout: no rows). Species lists differ by region (the deposit gives one
#   list per region; 64 shared, 28 SJ-only, 10 FR-only shipped), so __survey_taxa lists each region's
#   species at its traps (ruling #31).
#   Front Range = FR-shared's 64 species + FR-all's 10 FR-only species in rows 1-68 (labels verified).
#   Not shipped: PolyergusMONTIVAGUS and StenammaDIECKI (FR-all rows in unrecoverable order); Y (derived from y); genCov / Im (phylogenetic
#   model inputs); Table A1's ant worker counts and richness (summaries of the same samples).
#   Coordinates (E7): Dorymyrmex insanus is IUCN VU in its native range, so this table ships
#   coordinates coarsened to 0.1 degree and elevations rounded to 100 m; the E7.3 sibling
#   szewczyk_2019_colorado_ants_exact_binom omits D. insanus and keeps Table A1 precision.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "szewczyk_2019_colorado_ants_binom"
dir <- download_dryad("10.5061/dryad.rt679ng", "szewczyk_2019_colorado_ants")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("FR-all_data_for_JAGS.rds", "FR-shared_data_for_JAGS.rds", "SJ_data_for_JAGS.rds")))
sj <- readRDS(file.path(dir, "SJ_data_for_JAGS.rds"))
fr <- readRDS(file.path(dir, "FR-all_data_for_JAGS.rds"))
fs <- readRDS(file.path(dir, "FR-shared_data_for_JAGS.rds"))

# --- source facts ---------------------------------------------------------------------------
stopifnot(identical(dim(sj$y), c(92L, 14L, 20L)), identical(dim(sj$k), c(14L, 20L)),
          identical(dim(fr$y), c(76L, 15L, 20L)), identical(dim(fr$k), c(15L, 20L)),
          identical(dim(fs$y), c(64L, 15L, 20L)), identical(fs$k, fr$k), identical(dimnames(fs$y)[[2]], dimnames(fr$y)[[2]]))
for (d in list(sj, fr, fs)) {
  stopifnot(!anyNA(d$y), !anyNA(d$k), all(d$y == round(d$y)), all(d$y >= 0), all(d$k %in% 0:6))
  stopifnot(all(sweep(d$y, 2:3, d$k, "<=")))                         # y <= k everywhere
  stopifnot(all(apply(d$y, 1, function(m) all(m[d$k == 0] == 0))))   # unsurveyed traps hold no detections
}
stopifnot(sum(sj$k == 0) == 6, sum(fr$k == 0) == 23)
sp_sj <- dimnames(sj$y)[[1]]; sp_fr <- dimnames(fr$y)[[1]]; sp_fs <- dimnames(fs$y)[[1]]
stopifnot(!anyDuplicated(sp_sj), !anyDuplicated(sp_fr), all(grepl("^[A-Z][a-z]+[A-Z]+$", c(sp_sj, sp_fr))),
          length(intersect(sp_sj, sp_fr)) == 64, identical(sp_fs, intersect(sp_fr, sp_sj)),
          identical(sp_fs, as.character(fs$tax$Binomial)), identical(sp_fr, as.character(fr$tax$Binomial)))

# --- the two Front Range files disagree; FR-shared is the correctly labelled one ----------------
# FR-all and FR-shared agree, species by species, on the first 58 shared species (FR-all rows
# 1-68). From there FR-all's labels slip: FR-shared's SolenopsisMOLESTA .. TemnothoraxRUGATULUS
# (rows 59-63) are FR-all's rows 71, 73, 74, 75, 76, and FR-shared's TemnothoraxTRICARINATUS (row 64)
# is in no FR-all row. That species is detected at exactly Syl, CCp, CPk and B1, four of the five
# Front Range sites where Table A1's observed richness exceeds FR-all's by one, so FR-all lost it.
# FR-all's rows 69, 70 and 72 hold two FR-only species (PolyergusMONTIVAGUS, StenammaDIECKI) and
# one unnamed row, in an order that cannot be recovered: not shipped. The Front Range data are the
# 64 species of FR-shared plus the 10 FR-only species in FR-all rows 1-68, where the labels are
# verified by the agreement above.
same <- sapply(seq_along(sp_fr), function(r) { i <- match(sp_fr[r], sp_fs); !is.na(i) && identical(fr$y[r, , ], fs$y[i, , ]) })
stopifnot(identical(which(same), which(sp_fr %in% sp_fs & seq_along(sp_fr) <= 68)), sum(same) == 58)
hits <- function(i) which(sapply(seq_along(sp_fr), function(r) all(fr$y[r, , ] == fs$y[i, , ])))
stopifnot(identical(sapply(59:63, hits), c(71L, 73L, 74L, 75L, 76L)), length(hits(64)) == 0)
stopifnot(identical(dimnames(fs$y)[[2]][apply(fs$y[64, , ], 1, sum) > 0], c("Syl", "CCp", "CPk", "B1")))
fr_only <- which(!sp_fr %in% sp_fs & seq_along(sp_fr) <= 68)
stopifnot(length(fr_only) == 10, identical(sp_fr[setdiff(69:76, c(71, 73:76))], c("PolyergusMONTIVAGUS", "SolenopsisMOLESTA", "StenammaHUACHUCANUM")))
fr_drop <- c("PolyergusMONTIVAGUS", "StenammaDIECKI")
stopifnot(setequal(setdiff(sp_fr, c(sp_fs, sp_fr[fr_only])), fr_drop))
y_fr <- array(0, c(74, 15, 20), dimnames = list(c(sp_fs, sp_fr[fr_only]), dimnames(fr$y)[[2]], NULL))
y_fr[sp_fs, , ] <- fs$y; y_fr[sp_fr[fr_only], , ] <- fr$y[fr_only, , ]
fr$y <- y_fr; sp_fr <- dimnames(fr$y)[[1]]

# --- Table A1 (Appendix 1), the analysed sites in elevation order within transect -------------
a1 <- data.table(
  transect = rep(c("SJ-1", "SJ-2", "FR-1", "FR-2"), c(7, 7, 8, 7)),
  year = c(rep(2012L, 7), rep(2011L, 6), 2012L, 2010L, 2011L, 2010L, 2011L, 2011L, 2011L, 2012L, 2011L, rep(2010L, 7)),
  elev = c(1796, 1970, 2349, 2580, 2887, 3386, 3508, 1493, 1717, 2240, 2528, 3038, 3228, 3390,
           1728, 1938, 2153, 2410, 2811, 3022, 3364, 3640, 1811, 1904, 2215, 2712, 2881, 3117, 3466),
  lat = c(37.30, 37.24, 37.47, 37.52, 37.54, 37.72, 37.71, 37.33, 37.43, 37.55, 37.69, 37.80, 37.82, 37.84,
          40.43, 40.46, 40.45, 40.42, 40.40, 40.38, 40.39, 40.40, 40.02, 40.01, 40.01, 40.02, 40.02, 40.03, 40.05),
  lon = c(-108.67, -108.30, -108.39, -108.31, -108.22, -107.93, -107.91, -109.03, -109.02, -108.46, -108.33, -108.12, -108.13, -108.03,
          -105.23, -105.28, -105.30, -105.50, -105.64, -105.66, -105.67, -105.70, -105.30, -105.33, -105.37, -105.48, -105.53, -105.55, -105.58),
  rich = c(27, 43, 42, 32, 16, 3, 6, 34, 27, 44, 37, 21, 15, 3, 43, 46, 37, 27, 13, 16, 15, 2, 17, 16, 35, 34, 24, 12, 3),
  genr = c(15, 16, 14, 9, 7, 3, 4, 16, 14, 15, 15, 7, 6, 3, 15, 14, 10, 8, 7, 7, 5, 1, 12, 11, 10, 7, 6, 5, 3))
richness <- function(d) { g <- sub("[A-Z]+$", "", dimnames(d$y)[[1]]); det <- apply(d$y, 1:2, sum) > 0
  list(sp = colSums(det), gen = apply(det, 2, function(v) uniqueN(g[v]))) }
# San Juan: the deposit's two blocks of 7 sites are SJ-1 and SJ-2 in elevation order (richness identical)
r <- richness(sj)
stopifnot(identical(as.integer(unname(r$sp)), as.integer(a1[substr(transect, 1, 2) == "SJ", rich])),
          identical(as.integer(unname(r$gen)), as.integer(a1[substr(transect, 1, 2) == "SJ", genr])))
# Front Range: elS gives transect and elevation; Big Thompson = FR-1, Boulder = FR-2 (elevations match)
stopifnot(identical(as.character(fr$elS$Transect), rep(c("Big Thompson", "Boulder"), c(8, 7))),
          identical(as.numeric(fr$elS$Elevation), a1[substr(transect, 1, 2) == "FR", elev]),
          identical(as.character(fr$elS$Site), dimnames(fr$y)[[2]]))
sites <- cbind(a1, site = c(dimnames(sj$y)[[2]], dimnames(fr$y)[[2]]))
stopifnot(!anyDuplicated(sites$site))

# --- long table --------------------------------------------------------------------------------
to_long <- function(d, region) {
  sp <- dimnames(d$y)[[1]]; st <- dimnames(d$y)[[2]]
  g <- CJ(s = seq_along(sp), i = seq_along(st), j = 1:20)
  g[, `:=`(species = sp[s], site = st[i], y = d$y[cbind(s, i, j)], k = d$k[cbind(i, j)])]
  g <- g[k > 0]
  if (region == "SJ") {
    sx <- d$SiteX; tx <- d$TrapX
    stopifnot(identical(colnames(sx), c("HabH", "SoilH", "lArea", "Tmean", "MODIS", "DayVar")),
              identical(dimnames(tx)[[3]], c("Canopy", "nTrees", "MnSumVeg", "MnBareGrd")), !anyNA(sx), !anyNA(tx))
    g[, `:=`(unit_site_habitat_div_z = sx[i, "HabH"], unit_site_soil_div_z = sx[i, "SoilH"], unit_site_log_area_z = sx[i, "lArea"],
             unit_site_temp_mean_z = sx[i, "Tmean"], unit_site_npp_z = sx[i, "MODIS"], unit_site_temp_dayvar_z = sx[i, "DayVar"],
             unit_canopy_z = tx[cbind(i, j, 1)], unit_n_trees_z = tx[cbind(i, j, 2)],
             unit_veg_volume_z = tx[cbind(i, j, 3)], unit_bare_ground_z = tx[cbind(i, j, 4)])]
  }
  g[, `:=`(s = NULL, i = NULL, unit = sprintf("%s_%02d", site, j))][, j := NULL]
}
code_of <- function(x) { g <- sub("[A-Z]+$", "", x); e <- tolower(sub("^[A-Z][a-z]+", "", x))
  e[e == "adamsialpina"] <- "adamsi_alpina"; paste0(g, "_", e) }
L <- rbind(to_long(sj, "SJ"), to_long(fr, "FR"), fill = TRUE)
L <- merge(L, sites[, .(site, transect, year, elev, lat, lon)], by = "site")
L[, taxon := code_of(species)]
long <- L[, .(unit, taxon, period = year - 2009L, y = as.integer(y), obs_trials = as.integer(k), cluster_id = site,
              unit_region = substr(transect, 1, 2), unit_transect = transect, unit_elev_m = as.integer(elev),
              unit_decimalLatitude = lat, unit_decimalLongitude = lon,
              unit_site_habitat_div_z, unit_site_soil_div_z, unit_site_log_area_z, unit_site_temp_mean_z,
              unit_site_npp_z, unit_site_temp_dayvar_z, unit_canopy_z, unit_n_trees_z, unit_veg_volume_z, unit_bare_ground_z)]
long <- order_eco(long)
n_sj <- sum(sj$k > 0); n_fr <- sum(fr$k > 0)
stopifnot(n_sj == 274, n_fr == 277, nrow(long) == n_sj * 92 + n_fr * 74,
          sum(long$y) == sum(sj$y) + sum(fr$y), uniqueN(long$taxon) == 102, uniqueN(long$unit) == n_sj + n_fr, !anyDuplicated(long[, .(unit, taxon)]),
          long[unit_region == "FR", all(is.na(unit_canopy_z))], long[unit_region == "SJ", !anyNA(unit_canopy_z)])

periods <- data.table(period = 1:3, period_year = 2010:2012)
periods[, period_n_sites := sites[, .N, by = year][match(2010:2012, year), N]]

# --- taxa ---------------------------------------------------------------------------------------
sp_all <- sort(union(sp_sj, sp_fr)); code <- code_of(sp_all); stopifnot(length(sp_all) == 102, !anyDuplicated(code))
sci <- gsub("_", " ", code); sci[code == "Crematogaster_spp"] <- "Crematogaster"
rank <- ifelse(code == "Crematogaster_spp", "genus", ifelse(code == "Formica_adamsi_alpina", "subspecies", "species"))
# GBIF's backbone holds these two under their original genus (Leptothorax; now Temnothorax)
look <- sci; look[code == "Temnothorax_furunculus"] <- "Leptothorax furunculus"; look[code == "Temnothorax_obliquicanthus"] <- "Leptothorax obliquicanthus"
taxa <- make_taxa(code, sci, lookupName = look, taxonRank = rank,
                  taxonRemarks = ifelse(code == "Crematogaster_spp", "Recorded only to genus by the source (CrematogasterSPP)", NA_character_),
                  allow_higher = "Crematogaster_spp")
taxa[, taxon_region := ifelse(sp_all %in% sp_sj & sp_all %in% sp_fr, "both", ifelse(sp_all %in% sp_sj, "SJ", "FR"))]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# Three Temnothorax keys are homotypic synonyms on the GBIF backbone, so iucn_category() cannot
# confirm the assessed name and returns NA; GBIF's IUCN record for each says NE.
syn <- c("Temnothorax_neomexicanus", "Temnothorax_nitens", "Temnothorax_rugatulus")
stopifnot(setequal(taxa[is.na(taxon_iucnCategory), taxon], syn))
taxa[taxon %in% syn, taxon_iucnCategory := "NE"]
stopifnot(!any(kingdom_taxonID(taxa$taxonID)))
# E7(b): Dorymyrmex insanus is IUCN VU (1996) and Colorado is in its native range (south-western
# and Great Plains USA). The table is coarsened; the _exact sibling omits it (E7 scope 3).
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
stopifnot(identical(flagged$taxon, "Dorymyrmex_insanus"), identical(flagged$taxon_iucnCategory, "VU"))
cat(sprintf("  Dorymyrmex insanus: %d trap pairs with a detection, region %s\n", long[taxon == "Dorymyrmex_insanus" & y > 0, uniqueN(unit)],
            taxa[taxon == "Dorymyrmex_insanus", taxon_region]))

long_exact <- long[!taxon %in% flagged$taxon]
cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude)
long[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m,
            unit_elev_m = as.integer(round(unit_elev_m / 100) * 100))]
long <- order_eco(long)

EXACT <- "szewczyk_2019_colorado_ants_exact_binom"
fl <- sprintf("%s (IUCN %s)", flagged$scientificName, flagged$taxon_iucnCategory)
emit <- function(TBL, lg, exact) {
  tx <- taxa[taxon %in% lg$taxon]
  st <- unique(lg[, .(taxon, unit)])
  stopifnot(nrow(st) == nrow(lg))
  dataset <- list(
    title = sprintf("Ant detections in %d pitfall-trap pairs at 29 sites on four elevational transects in Colorado, 2010-2012: collections with the species out of collections made (binomial counts)%s",
                    uniqueN(lg$unit), if (exact) ", without the IUCN-threatened species, coordinates as published" else ""),
    creator = "Szewczyk, Tim M.; McCain, Christy M.", pubDate = "2019",
    doi = "10.5061/dryad.rt679ng", sourceURL = "https://doi.org/10.5061/dryad.rt679ng",
    citation = "Szewczyk, T. M., & McCain, C. M. (2019). Data from: Disentangling elevational richness: a multi-scale hierarchical Bayesian occupancy model of Colorado ant communities [Dataset]. Dryad. https://doi.org/10.5061/dryad.rt679ng",
    paperDOI = "10.1111/ecog.04115",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = paste0("Pitfall-trap ant surveys behind Szewczyk and McCain (2019, Ecography): four elevational transects in Colorado, two in the San Juan Mountains (1493-3508 m) and two in the Front Range (1728-3640 m), 7-8 sites each, 20 pitfall-trap pairs per site emptied up to six times over a 90-day summer, one summer per site in 2010-2012. For each trap pair and species, the number of collections containing the species out of the collections made (binomial_count). ",
                      sprintf("%d taxa, on per-region lists (San Juan and Front Range), with site elevation, coordinates and, for the San Juan only, the authors' standardised site and trap covariates.", nrow(tx)),
                      if (exact) sprintf(" This table omits %s so that site coordinates and elevations ship as published; %s has every species with coarsened locations.", fl, TABLE)
                      else sprintf(" Locations coarsened to 0.1 degree because %s occurs in the table; %s has the other species at published precision.", fl, EXACT)),
    samplingProtocol = "At each site, 20 pairs of pitfall traps run for about 90 days in summer and emptied 1-6 times; ants identified to species. The authors collapsed each trap's collections to the number containing each species (Szewczyk & McCain 2019, Methods and Appendix 1).",
    samplingProtocolCode = "pitfall", surveyEvidence = "effort_table",
    surveyEvidenceNote = "k (collections per trap pair) is deposited for every trap; a trap pair is a survey iff k > 0 (6 San Juan and 23 Front Range pairs have k = 0 and no detections). Species lists are per region as deposited (__survey_taxa); a species not detected in a surveyed trap is y = 0.",
    surveyTaxaNote = "The deposit gives one species list per region (San Juan 92; Front Range 74 as shipped; 64 on both); __survey_taxa lists each region's species at its trap pairs, and taxon_region in __taxa says which list a taxon is on.",
    effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
    closure = "none", closureNote = "no occasion column (binomial_count): one summer per site, collections collapsed by the authors, who treat site and trap-pair occupancy as closed over the 90-day season",
    occasionKind = "none", taxonInclusion = "recorded",
    geographicCoverage = "Colorado, USA: San Juan Mountains (37.2-37.9 N, 107.9-109.1 W) and Front Range (40.0-40.5 N, 105.2-105.7 W)",
    temporalCoverage = "2010/2012",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("as published: site coordinates at 0.01 degree and elevations from Appendix 1 Table A1, repeated on each trap pair; %s omitted (in %s, coarsened)", fl, TABLE))
                           else list(value = TRUE, rule = "taxon", method = sprintf("site coordinates (0.01 degree, Appendix 1 Table A1) coarsened to 0.1 degree cell centres with coarsen_coords(), elevations rounded to 100 m, because %s occurs in the table (E7(b), native range); the site codes are the source's", fl)),
    notShipped = c(list(`FR-all rows 69, 70, 72` = "FR-all's labels slip from row 69 (its rows 71, 73-76 are FR-shared's SolenopsisMOLESTA to TemnothoraxRUGATULUS, and it has no row for TemnothoraxTRICARINATUS); rows 69, 70 and 72 hold PolyergusMONTIVAGUS, StenammaDIECKI and one unnamed species in an unrecoverable order, so those two Front Range species are not shipped. The Front Range data are FR-shared's 64 species plus FR-all's 10 FR-only species in rows 1-68, where the two files agree",
                        Y = "site x species detected, derived from y",
                        `genCov, Im` = "genus-level phylogenetic covariance and identity matrices (model inputs)",
                        `Table A1 summaries` = "ant worker counts, number of collections and observed richness per site (summaries of the same samples; richness used only to place the San Juan sites)",
                        `excluded sites` = "the three disturbed sites the authors excluded (SJ-1 3241 m, SJ-2 3517 m, FR-2 3659 m) are not in the deposit"),
                   if (exact) list(`threatened species` = sprintf("%s: in %s only, whose locations are coarsened", fl, TABLE))),
    notes = "Site, transect, year, elevation and coordinates of the San Juan sites come from Appendix 1 Table A1, matched to the deposit's two blocks of seven site codes by observed species and genus richness, which agree exactly at all 14 sites. Covariates with suffix _z are the authors' standardised values as deposited (San Juan only; NA in the Front Range, where none were deposited). Taxon codes are Genus_epithet from the deposited Genus+EPITHET names.")
  ds <- write_table(lg, TBL, dataset, taxa = tx, periods = periods, survey_taxa = st, script = "data/szewczyk_2019_colorado_ants_binom.R")
  stage_dict_row(TBL,
    description = paste0(if (exact) sprintf("Precise-location sibling without %s: p", fl) else "P",
                         sprintf("itfall-trap ant surveys on four elevational transects in Colorado (San Juan Mountains and Front Range), 2010-2012: collections with the species out of collections made, per trap pair, %d taxa, with site elevation and coordinates.", nrow(tx))),
    url = "https://doi.org/10.5061/dryad.rt679ng",
    reference = "Szewczyk, T. M., & McCain, C. M. (2019). Disentangling elevational richness: a multi-scale hierarchical Bayesian occupancy model of Colorado ant communities. Ecography, 42(5), 977-988.",
    doi_paper = "10.1111/ecog.04115", doi_data = "10.5061/dryad.rt679ng",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste("binomial_count (ruling #34), multi-scale (cluster_id = site, unit = trap pair). San Juan site identities from Appendix 1 Table A1 (sent by C. McCain), matched by observed richness. Per-region species lists in __survey_taxa. FR-all mislabels its last rows; Front Range built from FR-shared plus the verified FR-only rows (two FR-only species not shipped).",
                  if (exact) sprintf("E7.3 sibling of %s without %s, locations as published.", TABLE, fl) else sprintf("Locations coarsened (%s); %s has the other species at published precision.", fl, EXACT)),
    source_via = "Dryad (version zip)")
  stage_tag_row(TBL, ds, taxon_group = "Invertebrates", model_family = "Community occupancy (multi-scale, binomial counts)",
    sampling_protocol = "pitfall", design = "Single-season (one summer per site, 2010-2012; 1-6 collections per trap collapsed to binomial counts)",
    realm = "Terrestrial", country = "USA", coordinates = if (exact) "As published (site, 0.01 deg)" else "Coarsened (0.1 deg)",
    notes = "Elevational gradients; ants.", status = "tagged")
}
emit(TABLE, long, exact = FALSE)
emit(EXACT, long_exact, exact = TRUE)
