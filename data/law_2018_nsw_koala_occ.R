#!/usr/bin/env Rscript
# Table:  law_2018_nsw_koala_occ
# Source: Zenodo record 4950882, doi:10.5061/dryad.m8q8bn3 (the Dryad deposit as served by Zenodo, published
#         2018-11-07; licence as shown on the record: CC0 1.0). Fetched from Zenodo, no Dryad request.
#   Law, B.S., Brassil, T., Gonsalves, L., Roe, P., Truskinger, A. & McConville, A. (2018). Data from:
#   Passive acoustics and sound recognition provide new insights on status and resilience of an iconic endangered
#   marsupial (koala Phascolarctos cinereus) to timber harvesting.
# Paper:  Law, B. et al. (2018). PLOS ONE 13(10): e0205075, doi:10.1371/journal.pone.0205075 (not read; the
#         workbook's Metadata sheet describes every sheet).
# Data:   Raw PRESENCE data for PONE-D-18-22682.xlsx. PA: 171 sites x PA1..PA14, koala detected (1) or not (0) by
#         call recognition on acoustic recorders on each of up to 14 consecutive nights, "." = not sampled. Site
#         covariates: standardised elevation^2, month (9-12), harvest treatment code TRT (1 koala high-use area,
#         3 old growth, 4-9 light-medium or heavy harvest by years since), year 2015-2017, standardised landscape
#         fire, old-growth, cleared, recent and heavy harvest extents, NDVI^2, feed-tree cover, topographic position
#         (1 upper, 2 mid, 3 lower slope), sample_nights, year and treatment dummies and their interactions. Min. temp.,
#         Rainfall, Moon: per site-night (moon phase 1 new, 2 last quarter, 3 first quarter, 4 full; "." where not
#         sampled, and some sampled nights have no rainfall). Code sheets. Asserted: 931 ".", 1,034 zeros, 429
#         ones; sample_nights equals the non-"." count per site; site lists identical across sheets.
# Mapping: single-season occupancy. unit = site, occasion = night 1..14, y = koala calls recognised that night.
#   surveyEvidence deposited_matrix ("." not sampled, 0 not detected). unit_ covariates as deposited (standardised
#   where the source standardised them, so named *_std): elevation^2, fire area, old growth, cleared, NDVI^2, recent
#   and heavy harvest, feed trees; unit_trt, unit_topo, unit_month, unit_year (codes as deposited). obs_min_temp_c,
#   obs_rain_mm, obs_moon.
# Not shipped: the year and treatment dummy columns and the covariate interactions (recomputable from the
#   shipped columns); no coordinates are deposited (Phascolarctos cinereus is IUCN VU).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "law_2018_nsw_koala_occ"
xf <- download_cached("https://zenodo.org/api/records/4950882/files/Raw%20PRESENCE%20data%20for%20PONE-D-18-22682.xlsx/content", TABLE, "koala.xlsx")
rec <- fromJSON(download_cached("https://zenodo.org/api/records/4950882", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-zero"), identical(rec$doi, "10.5061/dryad.m8q8bn3"))
rs <- function(s) as.data.table(suppressMessages(read_excel(xf, s, col_types = "text")))
pa <- rs("PA"); sc <- as.data.table(read_excel(xf, "Site covariates")); tmin <- rs("Min. temp."); rain <- rs("Rainfall"); moon <- rs("Moon")
nc <- paste0("PA", 1:14)
stopifnot(nrow(pa) == 171, identical(names(pa), c("Sites", nc)), identical(pa$Sites, sc$Site), identical(pa$Sites, tmin$Site),
          identical(pa$Sites, rain$Site), identical(pa$Sites, moon$Site))
tab <- table(unlist(pa[, ..nc]))
stopifnot(identical(as.vector(tab[c(".", "0", "1")]), c(931L, 1034L, 429L)), sum(tab) == 171 * 14,
          all(rowSums(pa[, ..nc] != ".") == sc$sample_nights))
lng <- function(d, v) { setnames(d, 1, "Site"); x <- melt(d, id.vars = "Site", variable.name = "occ", value.name = v, variable.factor = FALSE); x[, occasion := as.integer(sub("PA", "", occ))][, occ := NULL] }
L <- lng(copy(pa), "y")[y != "."]
L <- merge(L, lng(copy(tmin), "tmin"), by = c("Site", "occasion"))
L <- merge(L, lng(copy(rain), "rain"), by = c("Site", "occasion"))
L <- merge(L, lng(copy(moon), "moon"), by = c("Site", "occasion"))
stopifnot(nrow(L) == 1463, all(L$tmin != "."), all(L$moon %in% c("1", "2", "3", "4")))
num <- function(z) suppressWarnings(as.numeric(ifelse(z == ".", NA, z)))
L <- merge(L, sc[, .(Site, dem2 = `DEM^2`, month, trt = TRT, year, fire = fire_area, topo, oldg = per_oldgrowth, clear = per_clear, ndvi2 = `NDVI^2`,
                     recent = per_recent_harv, heavy = per_heavy_harv, feed = per_feed_trees)], by = "Site")
long <- L[, .(unit = Site, taxon = "PHACIN", y = as.integer(y), occasion,
              unit_year = as.integer(year), unit_month = as.integer(month), unit_trt = as.integer(trt), unit_topo = as.integer(topo),
              unit_elev2_std = dem2, unit_fire_area_std = fire, unit_oldgrowth_std = oldg, unit_cleared_std = clear, unit_ndvi2_std = ndvi2,
              unit_recent_harvest_std = recent, unit_heavy_harvest_std = heavy, unit_feed_trees_std = feed,
              obs_min_temp_c = num(tmin), obs_rain_mm = num(rain), obs_moon = as.integer(moon))]
stopifnot(sum(long$y) == 429)
taxa <- make_taxa("PHACIN", "Phascolarctos cinereus", vernacularName = "Koala")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Nightly acoustic detections of koalas at 171 sites in harvested and unharvested state forests of north-east New South Wales, 2015-2017",
  creator = "Law, Bradley S.; Brassil, Traecey; Gonsalves, Leroy; Roe, Paul; Truskinger, Anthony; McConville, Anna",
  pubDate = "2018", doi = "10.5061/dryad.m8q8bn3", sourceURL = "https://doi.org/10.5061/dryad.m8q8bn3", paperDOI = "10.1371/journal.pone.0205075",
  citation = "Law, B.S., Brassil, T., Gonsalves, L., Roe, P., Truskinger, A. & McConville, A. (2018). Data from: Passive acoustics and sound recognition provide new insights on status and resilience of an iconic endangered marsupial (koala Phascolarctos cinereus) to timber harvesting. Dryad (served by Zenodo), https://doi.org/10.5061/dryad.m8q8bn3.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Acoustic recorders with automated recognition of male koala bellows were deployed for up to 14 nights at 171 sites across timber-harvest treatments (old growth, light-medium and heavy harvesting of different ages, koala high-use areas) in north-east New South Wales state forests in spring 2015-2017.",
  samplingProtocol = "Passive acoustic recorders run for up to 14 consecutive nights per site in September-December; koala bellows identified by call-recognition software and verified; a night is a detection when any bellow was recognised.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "occasion = consecutive nights of one deployment per site; each site was sampled in one year.",
  geographicCoverage = "State forests of north-east New South Wales, Australia",
  temporalCoverage = "2015-09/2017-12",
  notShipped = list(dummies_interactions = "Yr1-Yr3 and trt1-trt8 dummies and every covariate interaction column (recomputable)"),
  notes = "unit_*_std covariates are standardised as deposited. Codes: unit_trt 1 koala high-use area, 3 old growth, 4/5/6 light-medium harvest <11 / 11-25 / >25 years ago, 7/8/9 heavy harvest likewise; unit_topo 1 upper, 2 mid, 3 lower slope; obs_moon 1 new, 2 last quarter, 3 first quarter, 4 full. No coordinates are deposited (koala IUCN VU).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/law_2018_nsw_koala_occ.R")
stage_dict_row(TABLE,
  description = "Nightly koala detections from acoustic recorders with call recognition at 171 sites across timber-harvest treatments in north-east New South Wales, 2015-2017, with site landscape covariates and nightly weather and moon.",
  url = "https://doi.org/10.5061/dryad.m8q8bn3",
  reference = "Law, B.S., Brassil, T., Gonsalves, L., Roe, P., Truskinger, A. & McConville, A. (2018). Passive acoustics and sound recognition provide new insights on status and resilience of an iconic endangered marsupial (koala Phascolarctos cinereus) to timber harvesting. PLOS ONE 13(10): e0205075.",
  doi_paper = "10.1371/journal.pone.0205075", doi_data = "10.5061/dryad.m8q8bn3", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Fetched from the Zenodo copy of the Dryad deposit (record 4950882).", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy", sampling_protocol = "acoustic",
  design = "Single season (up to 14 nights)", realm = "Terrestrial", country = "AUS", coordinates = "None in source",
  notes = "Timber-harvest treatments; automated call recognition.")
