#!/usr/bin/env Rscript
# Table:  holcomb_2017_suwannee_moccasinshell_occ
# Source: USGS ScienceBase doi:10.5066/F7VX0DPM (USGS data release, 2017; use constraints "None";
#         US public domain, recorded as CC0 1.0)
#   Holcomb, J.M., Shea, C.P., and Johnson, N.A., 2017, Cumulative spring discharge and survey effort
#   influence threatened Suwannee moccasinshell, Medionidus walkeri, occupancy and detection: U.S.
#   Geological Survey data release.
# Paper:  Holcomb, J.M., Shea, C.P., and Johnson, N.A., 2018, Cumulative spring discharge and survey
#   effort influence occupancy and detection of a threatened freshwater mussel, the Suwannee
#   moccasinshell. Journal of Fish and Wildlife Management 9(1):95-105, doi:10.3996/052017-JFWM-042.
# Data:   M_walkeri_Occupancy_Data_for_Sciencebase_11172016.csv: 220 survey sites in the Suwannee
#         River basin (Florida, Georgia), each surveyed once (2013-2016) by two to eight surveyors who
#         each searched a separate stretch (snorkelling and tactile search along 30-50 m of shore;
#         "no overlap of search area between surveyors"). Columns: counts of upstream springs by
#         magnitude and the cumulative minimum spring discharge (cfs, cms, standardised cms),
#         latitude / longitude, stream, survey date, total effort (person-hours), total M. walkeri
#         found, nOccasions (twice), Occasion1..8 (detection by surveyor, NA beyond nOccasions),
#         Effort1..8 (TotalEffort / nOccasions, 0 where no surveyor) and stEffort1..8 (standardised).
#         Asserted: Occasion_k is non-NA exactly for k <= nOccasions and Effort_k > 0 exactly there,
#         Effort_k = TotalEffort / nOccasions, and any detection by a surveyor iff Total_MW > 0.
# Mapping: unit = site, taxon = MEDWAL, occasion = surveyor (1..nOccasions), occasionKind observer,
#   y = that surveyor's detection (surveyEvidence deposited_matrix: NA and 0 are distinct).
#   obs_effort_ph = the surveyor's effort (person-hours, the authors' equal split of the total);
#   date = survey date; unit_ spring counts and discharge, stream. Total_MW (count over all
#   surveyors) is unit_total_mw_count: the site total at its single visit, not a per-surveyor count.
#   Coordinates: M. walkeri is federally threatened (US ESA, cited by the source) and IUCN CR (asserted),
#   so the site coordinates are coarsened to the 0.1-degree cell centre (E7 (a)/(c)), following the
#   batch 40 bull trout precedent for USGS-published sites (open question for Ben in
#   queue/human_review.csv).
# Not shipped: stSpringQcms and stEffort1..8 (standardised copies), SpringQcfs (the same discharge in
#   cfs), the duplicate nOccasions column.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "holcomb_2017_suwannee_moccasinshell_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/583c8e0fe4b0d9329c80c492?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
f <- "M_walkeri_Occupancy_Data_for_Sciencebase_11172016.csv"
d <- fread(download_cached(fl[[f]], TABLE, filename = f))
stopifnot(nrow(d) == 220, !anyDuplicated(d$SiteID), identical(d[[16]], d[[25]]), names(d)[16] == "nOccasions")
d <- d[, unique(names(d)), with = FALSE]
O <- as.matrix(d[, paste0("Occasion", 1:8), with = FALSE]); E <- as.matrix(d[, paste0("Effort", 1:8), with = FALSE])
k <- d$nOccasions
inn <- outer(k, 1:8, ">=")
stopifnot(all(!is.na(O) == inn), all((E > 0) == inn), all(O[inn] %in% 0:1),
          all(abs(E[inn] - (d$TotalEffort / k)[row(E)[inn]]) < 1e-6),
          identical(apply(O, 1, max, na.rm = TRUE) > 0, d$Total_MW > 0), sum(d$Total_MW > 0) == 26)
d[, date := as.IDate(SurveyDate, format = "%m/%d/%Y")]
stopifnot(!anyNA(d$date), all(year(d$date) %in% 2013:2016))
cc <- coarsen_coords(d$Latitude, d$Longitude)
d[, `:=`(lat = cc$lat, lon = cc$lon, unc = cc$uncertainty_m)]
long <- rbindlist(lapply(1:8, function(j) d[nOccasions >= j, .(unit = as.character(SiteID), taxon = "MEDWAL", y = as.integer(get(paste0("Occasion", j))),
        occasion = j, date = format(date), unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = unc,
        unit_stream = Stream, unit_n_springs_mag1 = nMagnitude1, unit_n_springs_mag2 = nMagnitude2, unit_n_springs_mag3 = nMagnitude3,
        unit_n_springs_mag4 = nMagnitude4, unit_n_springs = nSprings, unit_spring_q_cms = SpringQcms, unit_total_effort_ph = TotalEffort,
        unit_n_surveyors = nOccasions, unit_total_mw_count = Total_MW, obs_effort_ph = get(paste0("Effort", j)))]))
stopifnot(nrow(long) == sum(k), nrow(long) == 662)
taxa <- make_taxa("MEDWAL", "Medionidus walkeri", vernacularName = "Suwannee moccasinshell")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "CR"))
dataset <- list(
  title = "Suwannee moccasinshell detection by each surveyor at 220 mussel survey sites, Suwannee River basin, Florida and Georgia, 2013-2016",
  creator = "Holcomb, Jordan M.; Shea, Colin P.; Johnson, Nathan A.",
  pubDate = "2017", doi = "10.5066/F7VX0DPM", sourceURL = "https://doi.org/10.5066/F7VX0DPM",
  citation = "Holcomb, J.M., Shea, C.P., and Johnson, N.A., 2017, Cumulative spring discharge and survey effort influence threatened Suwannee moccasinshell, Medionidus walkeri, occupancy and detection: U.S. Geological Survey data release, https://doi.org/10.5066/F7VX0DPM.",
  paperDOI = "10.3996/052017-JFWM-042",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Mussel surveys at 220 locations in the Suwannee River basin, 2013-2016, compiled to model the occupancy of the federally threatened Suwannee moccasinshell against cumulative upstream spring discharge. Each site was surveyed once by two to eight surveyors, each searching a separate stretch of shoreline; each surveyor's detection of M. walkeri is recorded with the survey effort.",
  samplingProtocol = "Two to eight surveyors snorkelled and searched by touch all available habitat to about 2.5 m depth along 30-50 m of shoreline, each in a separate area with no overlap; total effort generally about one person-hour, and each surveyor's catch recorded separately.",
  samplingProtocolCode = "visual_search", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasions are surveyors searching separate stretches of the site at one visit", occasionKind = "observer",
  taxonInclusion = "single", effortColumn = "obs_effort_ph",
  geographicCoverage = list(description = "Suwannee River basin, Florida and Georgia, USA",
                            boundingBox = list(west = min(cc$lon), east = max(cc$lon), south = min(cc$lat), north = max(cc$lat))),
  temporalCoverage = "2013-10/2016-07",
  coordinatesCoarsened = list(value = TRUE, method = "coarsen_coords(): 0.1-degree cell centre, because Medionidus walkeri is IUCN CR and federally threatened (US ESA, cited by the source); USGS published the exact sites (batch 40 bull trout precedent, open question for Ben)"),
  notShipped = list(standardised = "stSpringQcms and stEffort1..8: standardised copies of shipped columns",
                    spring_q_cfs = "SpringQcfs: the same discharge in cfs (unit_spring_q_cms shipped)",
                    exact_coordinates = "coarsened to 0.1 degree (IUCN CR, federally threatened)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/holcomb_2017_suwannee_moccasinshell_occ.R")
stage_dict_row(TABLE,
  description = "Detection / non-detection of the Suwannee moccasinshell by each of two to eight surveyors at 220 mussel survey sites in the Suwannee River basin, 2013-2016, with surveyor effort and cumulative upstream spring discharge.",
  url = "https://doi.org/10.5066/F7VX0DPM",
  reference = "Holcomb, J.M., Shea, C.P., and Johnson, N.A. (2018). Cumulative spring discharge and survey effort influence occupancy and detection of a threatened freshwater mussel, the Suwannee moccasinshell. Journal of Fish and Wildlife Management 9(1):95-105.",
  doi_paper = "10.3996/052017-JFWM-042", doi_data = "10.5066/F7VX0DPM", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "occasion = surveyor at a single visit; coordinates coarsened to 0.1 degree (IUCN CR, federally threatened).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Single-season occupancy", sampling_protocol = "visual_search",
  design = "Single-season (2 to 8 surveyors per visit)", realm = "Freshwater", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Freshwater mussel, federally threatened; spatial replicates by surveyor.")
