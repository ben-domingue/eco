#!/usr/bin/env Rscript
# Table:  battaile_2023_sacramento_sturgeon_count
# Source: Dryad, doi:10.7291/D1738V (UC Santa Cruz Dryad), version 228830 of 2023-04-06, licence CC0 1.0
#         as shown on the Dryad page. Code at Zenodo doi:10.5281/zenodo.7783467 (not used).
# Paper:  Battaile, B., Mora, E., Lehman, B. & Dudley, P. Estimating spawning Green Sturgeon (Acipenser
#         medirostris) abundance using side scan sonar and N-mixture models. Canadian Journal of Fisheries
#         and Aquatic Sciences. https://doi.org/10.1139/cjfas-2023-0228
# Data:   Count2020.csv, Count2021.csv, Count2022.csv: 88 numbered pools ("sites", 1 = most southerly,
#           numbering consistent across years) x 7 columns = replicate side scan sonar (SSS) passes within
#           one day at the pool; cell = number of fish images counted as Green Sturgeon on that pass
#           (QGIS dots on the rendered SSS image); NA = pass not made. A pool with all 7 NA was not
#           surveyed that year. 30, 38 and 69 pools surveyed (the Dryad methods say 32, 38 and 69; the
#           files are followed). 2020-2021: 3 SSS passes per pool (after 7 DIDSON/ARIS passes, which are
#           not deposited); 2022: 3 passes, then up to 4 more where fish were seen. Six 2021 pools have
#           only 1 or 2 passes and two 2022 pools only 2 (the methods do not say why; shipped as deposited).
#         Count2022S.csv: the same 2022 passes recounted keeping only fish images >= 1.5 m long (the
#           authors' "more selective" adult-spawner set); same NA pattern as Count2022.csv (asserted),
#           larger than it in only 2 of 295 cells (asserted; pool 30 pass 1, 8 vs 6; pool 31 pass 5,
#           98 vs 93), which the source does not explain: a size filter cannot add fish. Shipped as deposited.
#         UpDownStream.txt: 2022 only, 1 = pass recorded heading downstream, 0 = upstream; rows are the
#           69 surveyed 2022 pools, NA pattern identical to Count2022.csv (asserted).
#         README.md. Pools are deliberately not geolocated (poaching risk); river-mile range only.
# Mapping: unit = pool number, taxon = ACIMED, period = year (1 = 2020, 2 = 2021, 3 = 2022),
#   occasion = SSS pass, y = count of sturgeon images on the pass (Count<year>.csv).
#   obs_n_ge_1_5m = the 2022S recount of the same pass (images >= 1.5 m), NA in 2020-2021: a measured
#   subset of y, not a model output. obs_downstream = pass direction, 2022 only (NA otherwise).
#   surveyEvidence = deposited_matrix: a non-NA cell is a pass made; NA cells and all-NA pools have no
#   rows. Survey dates only to the per-year window (June 1-5 2020, June 7-18 2021, July 18-21 2022), in
#   __periods; no per-pool date is deposited.
#   E7: Acipenser medirostris is EN on the IUCN Red List (asserted below) and the southern DPS is ESA
#   threatened, so the taxon is flagged; the source has no coordinates (pools are numbered, not located,
#   by the authors' choice), so there is nothing to coarsen.
#   Not shipped: the N-mixture abundance estimates and the plot-sampling density estimates (model
#   outputs); the DIDSON/ARIS counts (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "battaile_2023_sacramento_sturgeon_count"

dir <- download_dryad("10.7291/D1738V", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Count2020.csv", "Count2021.csv", "Count2022.csv", "Count2022S.csv",
                                      "README.md", "UpDownStream.txt")))

rd <- function(f) {
  x <- fread(file.path(dir, f), header = TRUE)
  setnames(x, 1, "site")
  stopifnot(nrow(x) == 88, ncol(x) == 8, identical(x$site, 1:88))
  m <- as.matrix(x[, -1]); storage.mode(m) <- "integer"; rownames(m) <- x$site; m
}
years <- 2020:2022
C <- lapply(sprintf("Count%d.csv", years), rd); names(C) <- years
CS <- rd("Count2022S.csv")
ud <- fread(file.path(dir, "UpDownStream.txt"), header = TRUE)
stopifnot(names(ud)[1] == "Area", ncol(ud) == 8)

surveyed <- sapply(C, function(m) sum(rowSums(!is.na(m)) > 0))
stopifnot(identical(unname(surveyed), c(30L, 38L, 69L)))
for (m in C) {
  stopifnot(all(m[!is.na(m)] >= 0))
  # passes are contiguous from pass 1
  stopifnot(all(apply(m, 1, function(r) { k <- sum(!is.na(r)); k == 0 || all(!is.na(r[seq_len(k)])) })))
}
stopifnot(all(rowSums(!is.na(C[["2020"]])) %in% c(0, 3)), all(rowSums(!is.na(C[["2021"]])) %in% 0:3), sum(rowSums(!is.na(C[["2021"]])) %in% 1:2) == 6,
          all(rowSums(!is.na(C[["2022"]])) %in% c(0, 2:7)), sum(rowSums(!is.na(C[["2022"]])) == 2) == 2)
stopifnot(all(is.na(CS) == is.na(C[["2022"]])), sum(CS > C[["2022"]], na.rm = TRUE) == 2)  # pools 30 (pass 1: 8 vs 6) and 31 (pass 5: 98 vs 93)
s22 <- as.integer(rownames(C[["2022"]]))[rowSums(!is.na(C[["2022"]])) > 0]
stopifnot(identical(ud$Area, s22))
U <- as.matrix(ud[, -1]); storage.mode(U) <- "integer"
stopifnot(all(is.na(U) == is.na(C[["2022"]][s22, ])), all(U %in% c(0L, 1L, NA)))

long <- rbindlist(lapply(seq_along(years), function(k) {
  m <- C[[k]]
  d <- data.table(unit = rep(as.integer(rownames(m)), 7), occasion = rep(1:7, each = 88), y = as.vector(m),
                  obs_n_ge_1_5m = NA_integer_, obs_downstream = NA_integer_)
  if (years[k] == 2022) {
    d[, obs_n_ge_1_5m := as.vector(CS)]
    Ufull <- matrix(NA_integer_, 88, 7); Ufull[s22, ] <- U
    d[, obs_downstream := as.vector(Ufull)]
  }
  d[!is.na(y)][, period := k]
}))
long[, taxon := "ACIMED"]
setcolorder(long, c("unit", "taxon", "period", "occasion", "y"))
setorder(long, period, unit, occasion)
stopifnot(nrow(long) == sum(sapply(C, function(m) sum(!is.na(m)))), uniqueN(long$unit) == 70)
stopifnot(long[period < 3, all(is.na(obs_n_ge_1_5m) & is.na(obs_downstream))],
          long[period == 3, !anyNA(obs_n_ge_1_5m) && !anyNA(obs_downstream)])

taxa <- make_taxa("ACIMED", "Acipenser medirostris", vernacularName = "Green sturgeon")
iucn <- iucn_category(taxa$taxonID[1], "Acipenser medirostris")
stopifnot(identical(iucn, "EN"))
periods <- data.table(period = 1:3, year = years,
                      period_start = c("2020-06-01", "2021-06-07", "2022-07-18"),
                      period_end = c("2020-06-05", "2021-06-18", "2022-07-21"),
                      n_pools_surveyed = as.integer(surveyed),
                      upper_river_mile = c(280L, 270L, 296L),
                      didson_aris_also_used = c(1L, 1L, 0L))

dataset <- list(
  title = "Side scan sonar counts of spawning Green Sturgeon in 70 upper Sacramento River pools, 2020-2022, 3 to 7 passes per pool",
  creator = "Battaile, Brian; Mora, Ethan; Lehman, Brendan; Dudley, Peter", pubDate = "2023",
  doi = "10.7291/D1738V", sourceURL = "https://doi.org/10.7291/D1738V",
  citation = "Battaile, B., Mora, E., Lehman, B., & Dudley, P. (2023). Estimating spawning Green Sturgeon (Acipenser medirostris Ayres, 1854) abundance using side scan sonar and N-mixture models [Dataset]. Dryad. https://doi.org/10.7291/D1738V",
  paperDOI = "10.1139/cjfas-2023-0228",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Adult Green Sturgeon (southern distinct population segment) counted on side scan sonar images of deep pools (> 5 m) in the upper Sacramento River, California, in June 2020, June 2021 and July 2022. Each pool was ensonified on 3 passes in one day (in 2022 up to 4 more where fish were seen), and the fish images on each pass counted; the 2022 passes were also recounted keeping only images at least 1.5 m long.",
  samplingProtocol = "Humminbird Helix 10 side scan sonar (1.2 MHz) from a jet boat at 4-8 knots, passes alternating upstream and downstream through each pool; each pass rendered to one image (SonarTRX) and every fish image showing Green Sturgeon behaviour marked in QGIS.",
  samplingProtocolCode = "sonar_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "all passes at a pool on one day; the authors fit closed N-mixture models per year",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "upper Sacramento River, California, USA, river miles ~200 to 296; pools deliberately not geolocated by the authors (poaching risk)",
  temporalCoverage = "2020-06-01/2022-07-21",
  coordinatesCoarsened = NA,
  covariateNote = "obs_n_ge_1_5m (2022 only) is the authors' recount of the same pass keeping fish images >= 1.5 m (approximate minimum adult spawner length); it exceeds y in 2 of 295 passes (pool 30 pass 1, pool 31 pass 5), unexplained by the source and shipped as deposited. obs_downstream (2022 only): 1 = pass heading downstream, 0 = upstream.",
  notShipped = list(
    model_output = "N-mixture and plot-sampling abundance/density estimates",
    didson_aris = "the 7 DIDSON/ARIS passes per pool in 2020-2021 are not deposited",
    pass_dates = "no per-pool survey date; the year's survey window is in __periods"),
  notes = "Taxon flagged under E7 (IUCN EN; southern DPS ESA threatened); no coordinates exist in the source, the authors having deliberately not geolocated the pools. The Dryad methods give 32 surveyed pools in 2020; Count2020.csv has 30 non-empty rows, which the table follows.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/battaile_2023_sacramento_sturgeon_count.R")
stage_dict_row(TABLE,
  description = "Side scan sonar counts of adult Green Sturgeon (Acipenser medirostris) in 70 pools of the upper Sacramento River, California, 2020-2022: 3 to 7 passes per pool per year; 2022 passes also recounted for fish >= 1.5 m.",
  url = "https://doi.org/10.7291/D1738V",
  reference = "Battaile, B., Mora, E., Lehman, B. & Dudley, P. Estimating spawning Green Sturgeon (Acipenser medirostris) abundance using side scan sonar and N-mixture models. Canadian Journal of Fisheries and Aquatic Sciences. https://doi.org/10.1139/cjfas-2023-0228",
  doi_paper = "10.1139/cjfas-2023-0228", doi_data = "10.7291/D1738V",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Pools not geolocated (by the source). 2022 size-filtered recount and pass direction as obs covariates.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "sonar_count", design = "Multi-season (3 years, 3-7 sonar passes per pool)",
  realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Side scan sonar image counts; threatened southern DPS (ESA), pools deliberately not located.")
