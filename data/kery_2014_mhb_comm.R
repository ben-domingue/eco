#!/usr/bin/env Rscript
# Tables: kery_2014_mhb_comm (all 158 species, coordinates coarsened to 10 km) and
#         kery_2014_mhb_exact_comm (E7.3 sibling without the turtle dove, coordinates as published)
# Source: AHMbook::MHB2014 (GPL >= 3): the full Swiss breeding bird survey (MHB) 2014 data,
#         267 1-km2 quadrats x up to 3 surveys x 158 species, the community dataset of
#         Kery & Royle, Applied Hierarchical Modeling in Ecology vol. 1 (2016), chapter 11.
# Data:   counts[267, 3, 158] (NA = survey not made: 50 quadrat-surveys incl. one quadrat never
#         surveyed); date[267, 3] (Julian, 1 April = 1), dur[267, 3] minutes; sites: siteID,
#         coordx/coordy (centre of quadrat; CRS intentionally unspecified by the package),
#         elev, rlength, nsurvey (planned), forest, obs14 (observer id); species: specid,
#         latabb, engname, latname, body.length, body.mass, wing.span. 13 of the 158
#         species were never recorded in 2014 and ship as all-zero taxa (taxonInclusion = target:
#         the MHB list is the protocol's target list, E10).
# Mapping (standard E1-E5; community abundance, standard_draft.md section 3.6): unit =
#   siteID, taxon = latabb, occasion = survey 1..3, y = count (not collapsed; a user who
#   wants detection/non-detection applies y > 0); unit_x, unit_y (unspecified CRS), unit_elev,
#   unit_rlength, unit_forest, unit_nsurvey_planned; obs_date_doy, obs_dur_min; observer =
#   obs14; taxon_body_length_cm, taxon_body_mass_g, taxon_wing_span_cm, taxon_specid.
#   surveyEvidence = deposited_matrix (NA pattern identical across species in the array).
#   v1.1: closure = closed, occasionKind = time, taxonInclusion = target. E7: iucn_category()
#   flags the European turtle dove (Streptopelia turtur, VU) and the quadrat centres (1 km grid)
#   are finer than 0.1 degree, so (E7.3) kery_2014_mhb_comm carries every species with
#   unit_x / unit_y snapped to 10 km cell centres (E7.1, uncertainty 7,071 m) and unit_elev
#   rounded to 100 m (E7.4; quadrat ids Q001.. are codes, not place names), and
#   kery_2014_mhb_exact_comm carries the other 157 species at source precision.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(AHMbook))
TABLE <- "kery_2014_mhb_comm"

data(MHB2014)
y <- MHB2014$counts; sp <- MHB2014$species; sites <- MHB2014$sites
stopifnot(dim(y) == c(267, 3, 158), nrow(sp) == 158, nrow(sites) == 267)
na1 <- is.na(y[, , 1]); stopifnot(all(apply(is.na(y), 3, identical, na1)), sum(na1) == 50)
stopifnot(all(y[!is.na(y)] >= 0), all(y[!is.na(y)] == round(y[!is.na(y)])))
stopifnot(all(is.na(MHB2014$date) == na1), all(is.na(MHB2014$dur) == na1))
dimnames(y) <- list(sites$siteID, NULL, sp$latabb)
never_seen <- sp$latabb[apply(y, 3, sum, na.rm = TRUE) == 0]; cat(sprintf("  %d species never recorded in 2014, shipped as all-zero taxa\n", length(never_seen)))
site_covs <- data.frame(x = sites$coordx, y = sites$coordy, elev = sites$elev, rlength = sites$rlength,
                        forest = sites$forest, nsurvey_planned = sites$nsurvey)
taxon_covs <- data.frame(body_length_cm = sp$body.length, body_mass_g = sp$body.mass, wing_span_cm = sp$wing.span, specid = sp$specid)
long <- array_to_eco(y, site_ids = sites$siteID, site_covs = site_covs,
                     obs_covs = list(date_doy = MHB2014$date, dur_min = MHB2014$dur), taxon_covs = taxon_covs)
long[, observer := sites$obs14[match(unit, sites$siteID)]]
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(y)), uniqueN(long$unit) == 266, uniqueN(long$taxon) == 158)

# GBIF's backbone spells the wood warbler with Bechstein's original double l (FUZZY on the
# MHB spelling): look it up as "Phylloscopus sibillatrix", the same species (key 8128385).
lookup <- ifelse(sp$latname == "Phylloscopus sibilatrix", "Phylloscopus sibillatrix", sp$latname)
taxa <- make_taxa(sp$latabb, sp$latname, vernacularName = sp$engname, lookupName = lookup)
# E7(b): IUCN categories through GBIF (iucn_category() checks the assessed name). Six NA
# answers are genus moves or spellings of the same species (Dendrocopos medius -> Leiopicus
# medius, Corvus monedula -> Coloeus, Parus montanus -> Poecile, Sylvia communis / curruca ->
# Curruca, Phylloscopus sibillatrix -> sibilatrix), all LC: none flagged. The European turtle
# dove (Streptopelia turtur, VU, native) is flagged and the quadrat centres are 1 km apart,
# finer than 0.1 degree: E7.3, two tables (below).
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(setequal(taxa[is.na(taxon_iucnCategory), taxon], c("DENMED", "CORMON", "PARMON", "SYLCOM", "SYLCUR", "PHYSIB")))
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := "LC"]
FLAGGED <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(identical(FLAGGED, "STRTUR"))

emit <- function(TABLE, exact) {
  lg <- copy(long); tx <- copy(taxa)
  if (exact) {
    lg <- lg[!taxon %in% FLAGGED]; tx <- tx[!taxon %in% FLAGGED]
  } else {
    # E7.1 projected pair: centre of the 10 km cell of the source grid; E7.4 elevation to 100 m
    lg[, `:=`(unit_x = floor(unit_x / 10000) * 10000 + 5000, unit_y = floor(unit_y / 10000) * 10000 + 5000,
              unit_coordinateUncertainty_m = 7071, unit_elev = round(unit_elev, -2))]
  }
  dataset <- list(
  title = paste0("Swiss breeding bird survey MHB 2014: counts of ", nrow(tx), " species on up to 3 surveys of 267 quadrats (AHMbook::MHB2014)",
                 if (exact) ", without the turtle dove, coordinates as published" else ", coordinates coarsened to 10 km"),
  creator = "Schweizerische Vogelwarte (Swiss Ornithological Institute); Kery, Marc; Royle, J. Andrew (package)",
  pubDate = "2016", sourceURL = "https://cran.r-project.org/package=AHMbook",
  citation = "Kery, M. & Royle, J. A. (2016). Applied Hierarchical Modeling in Ecology: Analysis of distribution, abundance and species richness in R and BUGS. Volume 1. Academic Press. Chapter 11. Data: AHMbook::MHB2014 (Kery, Royle & Meredith), from the Swiss breeding bird survey MHB, Schweizerische Vogelwarte.",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook community dataset: counts of 158 bird species (13 never recorded that year) on up to three territory-mapping surveys of 267 1-km2 MHB quadrats in 2014, with quadrat coordinates (unspecified CRS), elevation, route length, forest cover, survey date and duration, observer, and three species traits. AHM1 chapter 11 collapses the counts to detection/non-detection for community occupancy; the counts are shipped.",
  samplingProtocol = "Simplified territory mapping along a fixed 4-6 km transect in each 1-km2 quadrat, three surveys per breeding season (two above ~2000 m); count of territories/individuals per species per survey.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Switzerland, 267 MHB 1-km2 quadrats on a national grid", temporalCoverage = "2014",
  crs = "unspecified: the package states the coordinate reference system is intentionally not given; values are metres in a Swiss projected grid",
  coordinatesCoarsened = if (exact) list(value = FALSE, method = "as published in AHMbook (quadrat centres, unspecified CRS); the flagged turtle dove (Streptopelia turtur, IUCN VU) is not in this table (E7.3); the coarsened table with every species is kery_2014_mhb_comm")
                         else list(value = TRUE, method = "E7.1 projected pair: unit_x / unit_y snapped to the centre of the 10 km cell of the source grid (floor(x / 10000) * 10000 + 5000), uncertainty 7,071 m (unit_coordinateUncertainty_m), because the table includes the turtle dove (Streptopelia turtur, IUCN VU); unit_elev rounded to 100 m (E7.4). The table without the turtle dove at source precision is kery_2014_mhb_exact_comm (E7.3)"),
  notShipped = c(list(unsurveyed_quadrat = "1 quadrat with no survey in 2014 has no rows"),
                 if (exact) list(STRTUR = "the turtle dove (IUCN VU) is withheld from this precise-coordinate table (E7.3); it is in kery_2014_mhb_comm with coordinates coarsened to 10 km")))
  ds <- write_table(lg, TABLE, dataset, taxa = tx, script = "data/kery_2014_mhb_comm.R")
  stage_dict_row(TABLE,
    description = sprintf("Counts of %d bird species on up to 3 surveys of 267 Swiss MHB 1-km2 quadrats in 2014, with quadrat coordinates (unspecified CRS%s), elevation, route length, forest, survey date and duration, observer and species traits (AHMbook::MHB2014; the AHM1 ch. 11 community dataset)%s.",
                          nrow(tx), if (exact) "" else "; coarsened to 10 km cells", if (exact) "; without the turtle dove (IUCN VU), coordinates as published" else ""),
    url = "https://cran.r-project.org/package=AHMbook",
    reference = "Kery, M. & Royle, J. A. (2016). Applied Hierarchical Modeling in Ecology, vol. 1. Academic Press. Ch. 11.",
    original_license = "GPL-3", derived_license = "GPL-3",
    notes = paste0("Textbook dataset bundled with an R package. Counts shipped (the book collapses to 0/1). 13 species never recorded ship as all-zero taxa (target list). Round-trip tested (as 0/1) in converters/rt_06_mhb2014_community.R. ",
                   if (exact) "E7.3 sibling of kery_2014_mhb_comm without the flagged turtle dove." else "Coordinates coarsened (turtle dove VU); precise sibling kery_2014_mhb_exact_comm."),
    source_via = "R package (AHMbook)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community abundance (N-mixture) / community occupancy",
    sampling_protocol = "line_transect", design = "Single-season", realm = "Terrestrial", country = "CHE",
    coordinates = if (exact) "As published (unspecified CRS)" else "Coarsened (10 km grid cells, E7.1)",
    notes = sprintf("Textbook dataset (AHMbook). %d species incl. 13 all-zero; 50 unsurveyed quadrat-surveys.", nrow(tx)))
}
emit("kery_2014_mhb_comm", exact = FALSE)
emit("kery_2014_mhb_exact_comm", exact = TRUE)
