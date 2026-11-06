#!/usr/bin/env Rscript
# Table:  marshall_2020_saltmarshsparrow_nmix
# Source: Dryad doi:10.5061/dryad.vhhmgqnqg (CC0 1.0, as shown on the dataset page and in the API
#         record), version 54798 (published 2021-02-24).
#   Marshall, H., Blomberg, E., Watson, V., Conway, M., Cohen, J., Correll, M., Elphick, C.,
#   Hodgman, T., Kocek, A., Kovach, A., Shriver, W. G., Wiest, W. & Olsen, B. (2021). Habitat
#   openness and edge avoidance predict saltmarsh sparrow abundance better than habitat area. Dryad.
# Paper:  Marshall, H., Blomberg, E. J., Watson, V., Conway, M., Cohen, J. B., Correll, M. D.,
#         Elphick, C. S., Hodgman, T. P., Kocek, A. R., Kovach, A. I., Shriver, W. G., Wiest, W. A.
#         & Olsen, B. J. (2020). Habitat openness and edge avoidance predict Saltmarsh Sparrow
#         abundance better than habitat area. The Condor: Ornithological Applications 122(3),
#         duaa019. doi:10.1093/condor/duaa019. What the paper supplies: p. 3 Methods "Survey design":
#         SHARP point counts of 5 min passive observation, Saltmarsh Sparrows within 50 m recorded,
#         points at least 400 m apart in marsh patches chosen by a 2-stage GRTS design, 2-3
#         replicate surveys per point from April 15 to July 31, 2012, at least 10 days apart,
#         between 30 min before sunrise and 11:00; "Survey covariates": noise (0-4), wind
#         (Beaufort), sky (US Weather Bureau codes), temperature, hours after midnight, survey
#         window (Early / Mid / Late Summer); p. 4: openness measured in 2014 on Long Island
#         (70 of 913 points), the counts are 2012; p. 5 Results: 2,718 surveys at 913 points in
#         413 patches, 663 Saltmarsh Sparrows counted in all, 0 to 11 per survey.
# Data:   SALS_Abundance_Counts.csv: 913 points x Survey 1-3 counts (NA = no third survey, 21
#         points). Site_Covariates.csv: State, Region Number (SHARP ecogeographic region 1-5, 7),
#         Latitude (6 decimals; no longitude deposited), Angle to Max Horizon and Avg Horizon
#         Angle (degrees), Patch # (SHARP marsh patch id), Patch Area (ha), High Marsh Percent
#         Cover, Distance to Edge (m), and z-standardised copies of these. Survey_Covariates.csv:
#         z-standardised Temperature (F), Sky Condition, Wind, Noise, Hours Past Midnight and
#         Survey Window for each of the three surveys, only as z-scores; at the 21 missing third
#         surveys all six are 0 (the mean), and at 4 conducted surveys all six are exactly 0 too
#         (a missing record filled with the mean, presumably; asserted, set NA). Row names 1..913
#         agree across the three files.
# Mapping (N-mixture, repeated counts): unit = point (row number), taxon = AMMCAU, occasion =
#         survey 1-3, y = Saltmarsh Sparrows counted within 50 m. No period column: one breeding
#         season (2012; temporalCoverage). cluster_id = Patch #. surveyEvidence = deposited_matrix
#         (NA = no third survey). unit_ covariates: unit_state, unit_region, unit_angle_max_horizon_deg,
#         unit_avg_horizon_angle_deg, unit_patch_area_ha, unit_high_marsh_pct, unit_dist_edge_m,
#         unit_decimalLatitude (coarsened). obs_ covariates as the deposit gives them, z-standardised:
#         obs_temp_z, obs_sky_z, obs_wind_z, obs_noise_z, obs_hours_z, obs_window_z (the window
#         z-score takes five equally spaced values, not the three windows the paper names, so it
#         is not decoded).
#         Coordinates: Saltmarsh Sparrow is IUCN Endangered (checked with iucn_category()), so the
#         latitude is coarsened to the centre of its 0.1-degree band (coarsen_coords()).
# Not shipped: the z-standardised copies of the site covariates (recomputable); model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "marshall_2020_saltmarshsparrow_nmix"
dir <- download_dryad("10.5061/dryad.vhhmgqnqg", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

a <- fread(file.path(dir, "SALS_Abundance_Counts.csv"))
s <- fread(file.path(dir, "Site_Covariates.csv"))
v <- fread(file.path(dir, "Survey_Covariates.csv"))
stopifnot(identical(names(a), c("V1", "Survey 1", "Survey 2", "Survey 3")),
          identical(names(s), c("V1", "State", "Region Number", "Latitude", "Angle to Max Horizon", "Avg Horizon Angle",
                                "Patch #", "Patch Area (ha)", "High Marsh Percent Cover", "Distance to Edge (m)",
                                "Latitude (Z-Standardized)", "Max Horizon (Z)", "Patch Area (Z)", "Avg Horizon (Z)",
                                "High Marsh (Z)", "Dist to Edge (Z)")),
          ncol(v) == 19L, nrow(a) == 913L, nrow(s) == 913L, nrow(v) == 913L,
          identical(a$V1, 1:913), identical(s$V1, a$V1), identical(v$V1, a$V1), !anyNA(s))
A <- as.matrix(a[, 2:4])
stopifnot(!anyNA(A[, 1:2]), sum(is.na(A[, 3])) == 21L, sum(!is.na(A)) == 2718L,   # paper: 2,718 surveys
          sum(A, na.rm = TRUE) == 663L, max(A, na.rm = TRUE) == 11L,               # paper: 663 birds, 0-11 per survey
          uniqueN(s$`Patch #`) == 413L,                                           # paper: 413 patches
          setequal(s$State, c("ME", "NH", "MA", "RI", "CT", "NY", "NJ", "MD")), setequal(s$`Region Number`, c(1:5, 7L)))
# survey covariates: six z-scores per survey, in survey order 1, 2, 3
vn <- c("temp", "sky", "wind", "noise", "hours", "window")
V <- lapply(1:3, function(k) setNames(as.data.table(v[, 1 + (0:5) * 3 + k, with = FALSE]), vn))
stopifnot(grepl("Temp", names(v)[2]), grepl("S2", names(v)[3]), grepl("S3", names(v)[4]), grepl("Window", names(v)[17]),
          !anyNA(v))
allzero <- sapply(V, function(x) rowSums(x == 0) == 6L)
stopifnot(all(allzero[is.na(A[, 3]), 3]), sum(allzero[!is.na(A)]) == 4L)
# the window z-score takes five equally spaced values (not the paper's three windows; not decoded)
win <- sort(unique(round(unlist(lapply(1:3, function(k) V[[k]]$window[!allzero[, k] & !is.na(A[, k])])), 6)))
stopifnot(length(win) == 5L, all(abs(diff(diff(win))) < 1e-5))

taxa <- make_taxa("AMMCAU", "Ammospiza caudacuta", vernacularName = "Saltmarsh Sparrow")
iucn <- iucn_category(taxa$taxonID, taxa$scientificName)
stopifnot(identical(iucn, "EN"))
cl <- coarsen_coords(s$Latitude, rep(0, nrow(s)))$lat
stopifnot(all(s$Latitude %between% c(38, 45)))

long <- rbindlist(lapply(1:3, function(k) {
  x <- V[[k]]; z <- allzero[, k]
  for (c in vn) x[z, (c) := NA_real_]
  data.table(unit = sprintf("P%03d", s$V1), taxon = "AMMCAU", occasion = k, y = A[, k], cluster_id = s$`Patch #`,
             obs_temp_z = x$temp, obs_sky_z = x$sky, obs_wind_z = x$wind, obs_noise_z = x$noise, obs_hours_z = x$hours,
             obs_window_z = x$window,
             unit_state = s$State, unit_region = s$`Region Number`, unit_angle_max_horizon_deg = s$`Angle to Max Horizon`,
             unit_avg_horizon_angle_deg = s$`Avg Horizon Angle`, unit_patch_area_ha = s$`Patch Area (ha)`,
             unit_high_marsh_pct = s$`High Marsh Percent Cover`, unit_dist_edge_m = s$`Distance to Edge (m)`,
             unit_decimalLatitude = cl)[!is.na(y)]
}))
long <- order_eco(long)
stopifnot(nrow(long) == 2718L, uniqueN(long$unit) == 913L, sum(long$y) == 663L, sum(is.na(long$obs_window_z)) == 4L)
cat(sprintf("  %d rows, %d points in %d patches, %d birds\n", nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), sum(long$y)))

dataset <- list(
  title = "Saltmarsh Sparrow repeated point counts at 913 tidal-marsh points from Maine to Maryland, 2012",
  creator = "Marshall, Hallie; Blomberg, Erik; Watson, Valerie; Conway, Meaghan; Cohen, Jonathan; Correll, Maureen; Elphick, Chris; Hodgman, Thomas; Kocek, Alison; Kovach, Adrienne; Shriver, W. Gregory; Wiest, Whitney; Olsen, Brian",
  pubDate = "2021", doi = "10.5061/dryad.vhhmgqnqg", sourceURL = "https://doi.org/10.5061/dryad.vhhmgqnqg",
  paperDOI = "10.1093/condor/duaa019",
  citation = "Marshall, H., Blomberg, E., Watson, V., Conway, M., Cohen, J., Correll, M., Elphick, C., Hodgman, T., Kocek, A., Kovach, A., Shriver, W. G., Wiest, W., & Olsen, B. (2021). Habitat openness and edge avoidance predict saltmarsh sparrow abundance better than habitat area [Dataset]. Dryad. https://doi.org/10.5061/dryad.vhhmgqnqg",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "SHARP (Saltmarsh Habitat and Avian Research Program) point counts of the endangered Saltmarsh Sparrow at 913 GRTS-sampled points in 413 tidal-marsh patches across six ecogeographic regions from Maine to Maryland, each surveyed 2-3 times between 15 April and 31 July 2012 (2,718 surveys, 663 birds). Site covariates (angle to the maximum horizon, average horizon angle, patch area, high-marsh cover, distance to edge, state, region) and z-standardised survey covariates (temperature, sky, wind, noise, hours after midnight, survey window) as the paper's N-mixture models used them.",
  samplingProtocol = "SHARP point counts: 5 min of passive observation following a modified North American Marsh Bird Monitoring Protocol, all aural and visual detections of Saltmarsh Sparrows within 50 m, 2-3 replicate surveys at least 10 days apart between 30 min before sunrise and 11:00.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "2-3 surveys within one breeding season (15 April-31 July 2012); the authors timed survey windows by region to approximate closure",
  geographicCoverage = "Tidal marshes from Maine to Maryland, USA (about 38.0-44.9 N), six SHARP ecogeographic regions; latitude coarsened to 0.1 degree, no longitude deposited",
  temporalCoverage = "2012-04/2012-07",
  coordinatesCoarsened = list(value = TRUE, method = sprintf("Latitude (6 decimals in the deposit; no longitude is deposited) coarsened to the centre of its 0.1-degree band with coarsen_coords(): Saltmarsh Sparrow is IUCN %s.", iucn)),
  crs = "EPSG:4326",
  notShipped = list(
    z_site_covariates = "the z-standardised copies of latitude, horizon angles, patch area, high-marsh cover and distance to edge (recomputable from the shipped values)",
    model_output = "N-mixture abundance and detection estimates"),
  notes = "Survey covariates are deposited only as z-scores and ship as given (obs_*_z); obs_window_z takes five equally spaced values although the paper names three windows (early, mid, late summer; regional definitions in Wiest et al. 2016), so it is not decoded. At 4 conducted surveys all six survey covariates are exactly 0 (the mean, as at the 21 surveys that did not happen), taken to be a filled missing record and set NA. Survey dates are not deposited. Openness was measured in 2014 for the 70 Long Island points; the counts are from 2012.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/marshall_2020_saltmarshsparrow_nmix.R")
stage_dict_row(TABLE,
  description = "Endangered Saltmarsh Sparrow (Ammospiza caudacuta) SHARP point counts, 2-3 surveys at each of 913 tidal-marsh points in 413 patches from Maine to Maryland, 2012, with habitat openness, patch and z-standardised survey covariates; latitude coarsened.",
  url = "https://doi.org/10.5061/dryad.vhhmgqnqg",
  reference = "Marshall, H., Blomberg, E. J., Watson, V., Conway, M., Cohen, J. B., Correll, M. D., Elphick, C. S., Hodgman, T. P., Kocek, A. R., Kovach, A. I., Shriver, W. G., Wiest, W. A., & Olsen, B. J. (2020). Habitat openness and edge avoidance predict Saltmarsh Sparrow abundance better than habitat area. The Condor: Ornithological Applications, 122(3), duaa019.",
  doi_paper = "10.1093/condor/duaa019", doi_data = "10.5061/dryad.vhhmgqnqg",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "N-mixture repeated counts; survey year and window from the paper (2012); survey covariates z-scores only; latitude coarsened (IUCN EN).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture",
  sampling_protocol = "point_count", design = "Single-season (2-3 repeat counts per point)",
  realm = "Terrestrial", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Endangered tidal-marsh sparrow; latitude only, coarsened; survey covariates standardised.")
