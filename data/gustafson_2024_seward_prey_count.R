#!/usr/bin/env Rscript
# Table:  gustafson_2024_seward_prey_count
# Source: Dryad doi:10.5061/dryad.djh9w0w94 (CC0 1.0, asserted from the Dryad metadata; published
#         2024-12-19). Gustafson, M. et al. Gyrfalcon prey abundance and their habitat associations in a
#         changing Arctic [Dataset]. Raw files read from batch 37's cache (no Dryad request in batch 47).
# Paper:  Gustafson, M., McCabe, J., Rolek, B., Booms, T., Henderson, M., Dunn, L., Anderson, D. & Cruz, J.
#         (2025). Gyrfalcon prey abundance and their habitat associations in a changing Arctic. Ecology and
#         Evolution 15, e70763. doi:10.1002/ece3.70763 (open access; read from Europe PMC PMC11710894).
#         s.2.3: point counts along the three road corridors of the southern Seward Peninsula, Alaska, in
#         2019, 2021 and 2022, each point surveyed once; a 2-minute quiet period, then 10 minutes of
#         counting, recording the first detection of each individual (auditory or visual) less than 400 m
#         away; repeat detections of an individual not counted; a time-removal design with five 2-minute
#         intervals. s.2.6.1: ptarmigan counts are adult males only (< 5% / < 7% of counts were female or
#         unknown sex; juveniles not counted); all Arctic ground squirrels counted (sex and age not
#         distinguishable). The paper reports 983 point counts; the deposit has 988 points.
# Data:   ropt.csv (male rock ptarmigan), wipt.csv (male willow ptarmigan), squir.csv (Arctic ground
#         squirrels): 988 rows each, one per point (id unique, the same 988 ids in all three files), counts
#         in columns 1-5 (the 2-minute intervals; new individuals first detected in that interval), observer
#         (DS, KW, MG), wind, julian, min_after_sun (standardized survey covariates, identical across the
#         three files, asserted), and standardized habitat covariates within 800 m of the point (ropt and
#         squir: lowshrub, tundra, sparseveg, elev; wipt: tallshrub, tundra, tussock, elev; shared columns
#         identical across files, asserted; elev NA at 5 points). widedf.csv: Gyrfalcon territory occupancy
#         (built as gustafson_2024_seward_gyrfalcon_dynocc). The README's column descriptions for squir.csv
#         and wipt.csv repeat the rock ptarmigan text; the paper's description is used.
# Mapping (repeated counts within one visit: E8 within-visit intervals ruling, admitted by the Intake
#   "Replication" ruling of 2026-11-06): one table, the three species counted at the same visits (one
#   protocol, one survey set). unit = point (id), taxon = LAGMUT / LAGLAG / UROPAR (taxonInclusion target),
#   y = individuals first detected in the 10 minutes (sum of the five intervals), obs_int1 ... obs_int5 =
#   the count in each 2-minute interval (time removal), observer = primary observer. No occasion, no period
#   (each point surveyed once; the survey year is not deposited per point). obs_wind_std, obs_julian_std,
#   obs_min_after_sun_std (standardized, as deposited); unit_lowshrub_std, unit_tallshrub_std,
#   unit_tundra_std, unit_sparseveg_std, unit_tussock_std, unit_elev_std (standardized, as deposited).
#   surveyEvidence = row_presence: each file has a row for every point surveyed, zeros included.
#   No coordinates deposited. All three species IUCN LC.
# Not shipped: nothing of the point-count files; unstandardized covariates and dates are not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "gustafson_2024_seward_prey_count"
dir <- download_dryad("10.5061/dryad.djh9w0w94", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rd <- function(f) { p <- list.files(dir, paste0("^", f, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(p) == 1); fread(p) }
sp <- list(LAGMUT = rd("ropt.csv"), LAGLAG = rd("wipt.csv"), UROPAR = rd("squir.csv"))
INT <- as.character(1:5)
for (k in names(sp)) {
  x <- sp[[k]]
  stopifnot(nrow(x) == 988L, !anyDuplicated(x$id), all(INT %in% names(x)), all(unlist(x[, ..INT]) >= 0),
            !anyNA(x[, c(INT, "observer", "wind", "julian", "min_after_sun"), with = FALSE]),
            all(x$observer %in% c("DS", "KW", "MG")), sum(is.na(x$elev)) == 5L)
  setkey(x, id)
}
stopifnot(identical(sp$LAGMUT$id, sp$LAGLAG$id), identical(sp$LAGMUT$id, sp$UROPAR$id))
for (v in c("observer", "wind", "julian", "min_after_sun", "tundra", "elev"))
  stopifnot(identical(sp$LAGMUT[[v]], sp$LAGLAG[[v]]), identical(sp$LAGMUT[[v]], sp$UROPAR[[v]]))
stopifnot(identical(sp$LAGMUT$lowshrub, sp$UROPAR$lowshrub), identical(sp$LAGMUT$sparseveg, sp$UROPAR$sparseveg))
pts <- merge(sp$LAGMUT[, .(id, observer, obs_wind_std = wind, obs_julian_std = julian, obs_min_after_sun_std = min_after_sun,
                           unit_lowshrub_std = lowshrub, unit_tundra_std = tundra, unit_sparseveg_std = sparseveg, unit_elev_std = elev)],
             sp$LAGLAG[, .(id, unit_tallshrub_std = tallshrub, unit_tussock_std = tussock)], by = "id")
long <- rbindlist(lapply(names(sp), function(k) {
  x <- sp[[k]]
  data.table(unit = x$id, taxon = k, y = as.integer(rowSums(x[, ..INT])),
             obs_int1 = x[["1"]], obs_int2 = x[["2"]], obs_int3 = x[["3"]], obs_int4 = x[["4"]], obs_int5 = x[["5"]])
}))
long <- merge(long, pts, by.x = "unit", by.y = "id")
setcolorder(long, c("unit", "taxon", "y", "observer"))
long <- order_eco(long)
tot <- long[, .(n = sum(y), sites = sum(y > 0)), by = taxon]
print(tot)
stopifnot(nrow(long) == 3L * 988L, tot[taxon == "LAGMUT", n] == 55L, all(long$y == long$obs_int1 + long$obs_int2 + long$obs_int3 + long$obs_int4 + long$obs_int5))
taxa <- make_taxa(c("LAGMUT", "LAGLAG", "UROPAR"), c("Lagopus muta", "Lagopus lagopus", "Urocitellus parryii"),
                  vernacularName = c("Rock ptarmigan", "Willow ptarmigan", "Arctic ground squirrel"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, gbifMatchType, taxon_iucnCategory)])
stopifnot(all(taxa$taxon_iucnCategory == "LC"))
dataset <- list(
  title = "Time-removal point counts of rock and willow ptarmigan and Arctic ground squirrels at 988 points on the Seward Peninsula, Alaska, 2019-2022, five 2-minute intervals",
  creator = "Gustafson, Michaela; McCabe, Jennifer; Rolek, Brian; Booms, Travis; Henderson, Michael; Dunn, Leah; Anderson, David; Cruz, Jennyffer",
  pubDate = "2024", doi = "10.5061/dryad.djh9w0w94", sourceURL = "https://doi.org/10.5061/dryad.djh9w0w94",
  citation = "Gustafson, M. et al. (2024). Gyrfalcon prey abundance and their habitat associations in a changing Arctic [Dataset]. Dryad. https://doi.org/10.5061/dryad.djh9w0w94",
  paperDOI = "10.1002/ece3.70763",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point counts of three small herbivores that Gyrfalcons prey on, at 988 points along the road corridors of the southern Seward Peninsula, Alaska, in 2019, 2021 and 2022, each point surveyed once for 10 minutes after a 2-minute quiet period. The first detection of each individual within 400 m was recorded in one of five 2-minute intervals (a time-removal design); ptarmigan counts are adult males. The authors fitted time-removal N-mixture models relating abundance to habitat.",
  samplingProtocol = "One 10-minute point count per point (after a 2-minute quiet period), recording the first detection of each individual (auditory or visual) within 400 m in five 2-minute intervals; male rock and willow ptarmigan and all Arctic ground squirrels counted; surveys from 30 minutes before sunrise to about midday, May-July 2019, 2021 and 2022.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "none", closureNote = "One visit per point (no occasion column); the five 2-minute intervals within it are the time-removal replicates, shipped as obs_int1-obs_int5 (E8 within-visit intervals ruling); the population is assumed closed within the 10-minute count.",
  occasionKind = "none", taxonInclusion = "target",
  geographicCoverage = "Southern Seward Peninsula, Alaska, USA, along the road corridors from Nome (no coordinates deposited)",
  temporalCoverage = "2019-05/2022-07",
  covariateNote = "obs_int1-obs_int5: individuals first detected in each 2-minute interval (they sum to y). observer: primary observer (DS, KW, MG). obs_wind_std, obs_julian_std (day of year), obs_min_after_sun_std: standardized as deposited. unit_lowshrub_std, unit_tallshrub_std, unit_tundra_std, unit_sparseveg_std, unit_tussock_std: standardized percent cover within 800 m of the point; unit_elev_std: standardized mean elevation (NA at 5 points). The authors used tallshrub and tussock for willow ptarmigan and lowshrub and sparseveg for the others; all are shipped for every row.",
  notShipped = list(gyrfalcon = "widedf.csv, the Gyrfalcon territory occupancy, is its own table (gustafson_2024_seward_gyrfalcon_dynocc)"),
  notes = "Single visit replicated within the visit by five recorded 2-minute intervals (Intake Replication ruling 2026-11-06). Ptarmigan y counts adult males only (the authors' filter; the deposit holds no females or juveniles); ground squirrel y counts all individuals. The survey year of each point (2019, 2021 or 2022) is not deposited. The paper reports 983 point counts; the deposit has 988 points.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/gustafson_2024_seward_prey_count.R")
stage_dict_row(TABLE,
  description = "Time-removal point counts (five 2-minute intervals, one visit) of male rock and willow ptarmigan and Arctic ground squirrels at 988 points on the Seward Peninsula, Alaska, 2019-2022, with standardized habitat and survey covariates.",
  url = "https://doi.org/10.5061/dryad.djh9w0w94",
  reference = "Gustafson, M. et al. (2025). Gyrfalcon prey abundance and their habitat associations in a changing Arctic. Ecology and Evolution 15, e70763.",
  doi_paper = "10.1002/ece3.70763", doi_data = "10.5061/dryad.djh9w0w94", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-visit time-removal counts, intervals as obs_int1-5 (admitted 2026-11-06); read from batch 37's cache.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "N-mixture (time removal)",
  sampling_protocol = "point_count", design = "Single-season (one visit per point, five 2-minute removal intervals)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Gyrfalcon prey; two ptarmigan and a ground squirrel counted at the same points.")
