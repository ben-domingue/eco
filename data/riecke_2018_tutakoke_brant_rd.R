#!/usr/bin/env Rscript
# Table:  riecke_2018_tutakoke_brant_rd
# Source: Dryad doi:10.5061/dryad.c54h30c, version 22693 (published 2019-07-16), licence CC0 1.0
#         (as shown on Dryad). Riecke, T. V., Leach, A. G., Gibson, D. & Sedinger, J. S. "Data from:
#         Parameterizing the robust design in the BUGS language: lifetime carry-over effects of
#         environmental conditions during growth on a long-lived bird".
# Paper:  Riecke, T. V., Leach, A. G., Gibson, D. & Sedinger, J. S. (2018). Parameterizing the robust
#         design in the BUGS language: Lifetime carry-over effects of environmental conditions during
#         growth on a long-lived bird. Methods in Ecology and Evolution 9(11):2294-2305.
#         doi:10.1111/2041-210X.13065 (Wiley, not open access; abstract via Crossref).
# Data:   Riecke_RData.RData (an R workspace, 9 MB) plus biological_model.R (the JAGS robust-design
#         model the paper fitted) and two simulation scripts. Objects used:
#           obs   [7845 x 27 x 3] 0/1: female i detected in breeding season t (1988..2014) by
#                 secondary capture method j (1 nest searches, 2 tower / ground resighting of
#                 tarsal bands, 3 banding drives); identical to the data frames nest, tower, band.
#           tut   [7845 x 27] 0/1 = any j; this is dat$ch, the primary-period history the model uses.
#           first [7845] first primary period with a detection (= first column of tut that is 1).
#           ind   data.frame: band (plastic tarsal-band code, not unique), sex (all F), bandedyear
#                 (1967..2013), bandedage (A adult 5237, L local = gosling 2327, S second-year 281),
#                 ltar (gosling tarsus at ~30 days in 0.1 mm, 713 L birds; the paper's carry-over
#                 covariate; zltar / dat$ltar is its standardisation with 0 for missing).
#           age, age.band [7845 x 27]: year - bandedyear + 2 (A), + 1 (S), + 0 (L): a minimum-age
#                 index derived from the banding record (not shipped; derivable).
#           yes, total [27 x 3]: the authors' secondary-occasion aggregates (birds detected by method
#                 j among those detected by another method that year, and that denominator); they
#                 differ from the recomputation from obs by 1-2 birds per cell (not shipped, aggregates).
#           master (42,057 x 1,016): the raw banding database with metal band numbers; not shipped.
#           Everything else is simulation output, MCMC output (msrd) or scratch.
#         No dates within a season, no coordinates (one colony), no site covariates.
#
# Mapping (standard E9 robust design, responseType detection, unitKind individual):
#   unit = female brant B0001..B7845 (row of obs; the tarsal-band code is unit_band_code because
#   codes are reused and not unique), taxon = BRABER, period = breeding season 1..27 (1988..2014,
#   in __periods), occasion = secondary capture method 1 nest, 2 tower, 3 banding (design
#   categories, all three run every year: n.sec = 3 in the model; order within the season is
#   nesting (May-June), tower observation (June-July), banding drives (July-August)), y = 0/1.
#   Survey evidence: the deposited matrix; every individual carries the full 27 x 3 rectangle,
#   including seasons before first detection (kept as 0, E4; the model conditions on `first`,
#   reproducible by dropping rows before the first detection). unit_sex, unit_banded_year,
#   unit_banded_age_class, unit_band_code, unit_gosling_tarsus_mm (= ltar / 10, NA unless banded
#   as a gosling and measured) as deposited.
#   Not shipped: master (raw banding database), age / age.band (derivable), zltar (standardised
#   ltar), yes / total (aggregates), simulation and MCMC objects, the 663 x 10 simulated history ch.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "riecke_2018_tutakoke_brant_rd"
dir <- download_dryad("10.5061/dryad.c54h30c", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Riecke_RData.RData"); stopifnot(file.exists(f))
e <- new.env(); suppressWarnings(load(f, envir = e))          # the workspace references rjags / jagsUI, which are not installed
stopifnot(all(c("obs", "tut", "first", "ind", "nest", "tower", "band", "ltar", "zltar") %in% ls(e)))

obs <- e$obs; ind <- e$ind
n_ind <- 7845L; n_yr <- 27L; years <- 1988L:2014L
stopifnot(identical(dim(obs), c(n_ind, n_yr, 3L)), all(obs %in% c(0, 1)))
stopifnot(identical(obs[, , 1], unname(as.matrix(e$nest))), identical(obs[, , 2], unname(as.matrix(e$tower))),
          identical(obs[, , 3], unname(as.matrix(e$band))))
anyj <- apply(obs, 1:2, max)
stopifnot(identical(unname(as.matrix(e$tut)), anyj), identical(e$dat$ch, anyj),
          all(rowSums(anyj) > 0),                                        # every female detected at least once
          all(e$first == apply(anyj, 1, function(r) which(r == 1)[1])),
          identical(unname(apply(obs, 3, sum)), c(17031, 3295, 7927)), sum(anyj) == 22510)
stopifnot(nrow(ind) == n_ind, all(ind$sex == "F"), all(ind$bandedyear >= 1967 & ind$bandedyear <= 2013),
          all(ind$bandedyear <= years[e$first]),                          # banded no later than first detection
          identical(as.integer(table(factor(ind$bandedage, levels = c("A", "L", "S")))), c(5237L, 2327L, 281L)),
          identical(e$ltar, ind$ltar), sum(!is.na(ind$ltar)) == 713, all(ind$bandedage[!is.na(ind$ltar)] == "L"),
          all(range(ind$ltar, na.rm = TRUE) == c(500L, 797L)),
          all(e$dat$ltar[is.na(ind$ltar)] == 0))                          # the model's covariate is 0 where unmeasured
yrm <- matrix(years, n_ind, n_yr, byrow = TRUE)
off <- c(A = 2L, L = 0L, S = 1L)[as.character(ind$bandedage)]
stopifnot(all(e$age == yrm - ind$bandedyear + off))                      # age is derivable from the banding record
cat(sprintf("  %d females x %d breeding seasons x 3 capture methods; %d detections (nest %d, tower %d, banding %d)\n",
            n_ind, n_yr, sum(anyj), sum(obs[, , 1]), sum(obs[, , 2]), sum(obs[, , 3])))

# individual x (season, method) with method fastest, so occasion = method within season
Y <- matrix(0L, n_ind, n_yr * 3L)
for (j in 1:3) Y[, seq(j, by = 3L, length.out = n_yr)] <- as.integer(obs[, , j])
period <- rep(seq_len(n_yr), each = 3L)
units <- data.table(unit = sprintf("B%04d", seq_len(n_ind)))
site_covs <- data.frame(sex = as.character(ind$sex), banded_year = as.integer(ind$bandedyear),
                        banded_age_class = as.character(ind$bandedage), band_code = as.character(ind$band),
                        gosling_tarsus_mm = ind$ltar / 10)
long <- array_to_eco(Y, taxon = "BRABER", site_ids = units$unit, period = period, site_covs = site_covs)
stopifnot(nrow(long) == n_ind * n_yr * 3L, all(long$occasion %in% 1:3), sum(long$y) == sum(obs),
          uniqueN(long$unit) == n_ind, max(long$period) == n_yr)

taxa <- make_taxa("BRABER", "Branta bernicla", vernacularName = "Black brant (Pacific black brent)",
                  taxon_subspecies = "nigricans", taxon_iucnCategory = "LC")
periods <- data.table(period = seq_len(n_yr), year = years, n_occasions = 3L,
                      n_detected = as.integer(rowSums(t(anyj))),
                      note = "breeding season at the Tutakoke River colony; occasions 1 nest searches, 2 tower / ground resighting, 3 banding drives")
stopifnot(sum(periods$n_detected) == sum(anyj))

dataset <- list(
  title = "Robust-design capture histories of 7,845 female black brant at the Tutakoke River colony, Yukon-Kuskokwim Delta, Alaska, breeding seasons 1988-2014",
  creator = "Riecke, Thomas V.; Leach, Alan G.; Gibson, Daniel; Sedinger, James S.", pubDate = "2019",
  doi = "10.5061/dryad.c54h30c", sourceURL = "https://doi.org/10.5061/dryad.c54h30c",
  citation = "Riecke, T. V., Leach, A. G., Gibson, D., & Sedinger, J. S. (2019). Data from: Parameterizing the robust design in the BUGS language: lifetime carry-over effects of environmental conditions during growth on a long-lived bird [Dataset]. Dryad. https://doi.org/10.5061/dryad.c54h30c",
  paperDOI = "10.1111/2041-210X.13065",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Encounter histories of 7,845 female Pacific black brant (Branta bernicla nigricans) marked with plastic tarsal bands at the Tutakoke River colony, Yukon-Kuskokwim Delta, western Alaska, and detected in 27 breeding seasons (1988-2014) by three capture methods within each season: nest searches, tower and ground resighting of tarsal bands, and banding drives. The deposit is the R workspace of the paper's Bayesian robust-design model (survival and breeding probability with a lifetime carry-over effect of gosling tarsus length); here each season is three rows per female, one per capture method, y = detected. Females banded as goslings carry their tarsus length at about 30 days.",
  samplingProtocol = "Annual breeding-season capture-recapture of adult female brant: nest searches on the colony (May-June), resighting of individually coded plastic tarsal bands from towers and the ground (June-July), and banding drives of flightless adults with broods (July-August); goslings banded and measured (tarsus) at about 30 days.",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "occasion within period (robust design: three capture methods per breeding season; a female alive and breeding is available to all three; nonbreeders are temporary emigrants from the colony)",
  occasionCodes = list(`1` = "nest searches (p_nest in the paper)", `2` = "tower and ground resighting of tarsal bands (p_tower)", `3` = "banding drives (p_banding)"),
  geographicCoverage = "Tutakoke River colony, Yukon-Kuskokwim Delta, western Alaska, USA (about 61.25 N, 165.6 W); no coordinates deposited",
  temporalCoverage = "1988/2014",
  coordinatesCoarsened = NA,
  notes = "Rows before a female's first detection are kept as 0 (E4); the paper's model conditions on first detection (object `first`), so drop rows before the first y = 1 to reproduce its data. Birds banded as adults (A) or second-years (S) have unknown hatch year; unit_gosling_tarsus_mm is available only for the 713 of 2,327 gosling-banded (L) birds that were measured, and the paper's standardised covariate sets it to 0 where missing. The deposit's secondary-occasion aggregates (yes, total) differ from a recomputation from the individual histories by 1-2 birds per cell. The tarsal-band code (unit_band_code) is reused across birds and is not a key.",
  notShipped = list(master = "the raw banding database (42,057 x 1,016, metal band numbers)",
                    `age, age.band` = "minimum-age indices derivable from banded_year and banded_age_class",
                    zltar = "standardised gosling tarsus (derivable)",
                    `yes, total` = "the authors' per-season secondary-occasion aggregates",
                    `ch (663 x 10), avail, estimate*, msrd, p1-p3` = "simulation inputs and MCMC output"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/riecke_2018_tutakoke_brant_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design capture histories of 7,845 female black brant (Branta bernicla nigricans) at the Tutakoke River colony, Alaska, 27 breeding seasons (1988-2014) x 3 capture methods (nest searches, tower resighting, banding drives); y = detected; banding year and age class, and gosling tarsus length for 713 females, as covariates.",
  url = "https://doi.org/10.5061/dryad.c54h30c",
  reference = "Riecke, T. V., Leach, A. G., Gibson, D., & Sedinger, J. S. (2018). Parameterizing the robust design in the BUGS language: Lifetime carry-over effects of environmental conditions during growth on a long-lived bird. Methods in Ecology and Evolution, 9(11), 2294-2305.",
  doi_paper = "10.1111/2041-210X.13065", doi_data = "10.5061/dryad.c54h30c",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Built from the deposited R workspace (obs array). Occasions are capture methods within a season. Leading zeros before first detection kept; the paper conditions on first detection.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Robust design capture-recapture (survival, breeding probability, temporary emigration)",
  sampling_protocol = "tag_resight", design = "Robust design (27 breeding seasons x 3 capture methods)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Individuals as unit; secondary occasions are capture methods, not time replicates; all females.")
