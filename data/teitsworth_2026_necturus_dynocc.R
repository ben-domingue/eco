#!/usr/bin/env Rscript
# Table:  teitsworth_2026_necturus_dynocc
# Source: Dryad doi:10.5061/dryad.63xsj3vgg (CC0 1.0, as shown on the Dryad page; published
#         2026-03-17). Teitsworth, E., Hall, J., Archambault, J., Humphries, W.J. & Pacifici,
#         K. (2026). Data from: Multiscale threats shape the occurrence dynamics of a
#         threatened aquatic salamander and reveal a possible extinction debt. Also on GitHub
#         (ericteitsworth/Multiscale-Dynamic-Occupancy_N.-lewisi).
# Paper:  Teitsworth, E. et al. (2026). Multiscale threats shape the occurrence dynamics of a
#         threatened aquatic salamander and reveal a possible extinction debt. Ecology and
#         Evolution, doi:10.1002/ece3.73225. Dynamic occupancy (unmarked::colext) of the Neuse
#         River waterdog (Necturus lewisi; ESA threatened 2021) at 176 stream sites over five
#         consecutive years.
# Data:   Data.csv, 176 rows (Site 1..176) x 70 columns: Day1-Day20 detection history (1/0,
#         blank = not surveyed; four consecutive overnight trap checks in each of five years);
#         site covariates Bottom Substrate, Cover Score, Total (rapid habitat assessment
#         scores), devel, grass, crop, wetland, forest (proportion of the watershed in each
#         NLCD 2019 class, inverse-distance weighted; README calls them %, values are 0-1),
#         MU (management unit / subpopulation, 13 codes); Discharge1-20 (daily mean stream
#         discharge m3/s on the day before each check, interpolated for ungauged sites;
#         present also for unsurveyed days); Bait1-20 (bait age in days, 0-7).
#         YearlySiteCovs.csv, 880 rows with columns TQ (a yearly streamflow metric the
#         script calls "Yearly TQmean") and DI (yearly maximum drought intensity, 0-3), no
#         site or year column; the README says the file is "formatted ... to match the
#         format required of yearly dynamic covariates in the unmarked framework", i.e. 176
#         sites x 5 years with years varying fastest, and model_script.R passes it to
#         unmarkedMultFrame that way. model_script.R and turnover_equilibrium_script.R are
#         code. The calendar years are not stated in the deposit or its README.
#
# Mapping (standard: dynamic occupancy, E9 core):
#   unit = site (1..176); taxon = NECLEW; period = study year 1..5 (__periods; calendar years
#   unknown); occasion = check 1..4 within the year; y = detection. obs_: discharge (m3/s,
#   previous day), bait age (days). unit_: the three habitat scores, the five land-cover
#   proportions, management unit. period_ (site x year): TQ and DI read in the order the
#   README and the authors' code state (row = (site - 1) * 5 + year). Survey evidence: the
#   deposited site x visit matrix (blank = not surveyed). No dates, no coordinates.
#   Not shipped: discharge and bait values on unsurveyed days (no survey), the code files.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "teitsworth_2026_necturus_dynocc"
dir <- download_dryad("10.5061/dryad.63xsj3vgg", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fd <- list.files(dir, "^Data\\.csv$", recursive = TRUE, full.names = TRUE)
fy <- list.files(dir, "^YearlySiteCovs\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(fd) == 1, length(fy) == 1)
d <- fread(fd); yc <- fread(fy)

# facts about the source
SITEC <- c("Bottom Substrate", "Cover Score", "Total", "devel", "grass", "crop", "wetland", "forest", "MU")
stopifnot(identical(names(d), c("Site", paste0("Day", 1:20), SITEC, paste0("Discharge", 1:20), paste0("Bait", 1:20))),
          nrow(d) == 176, identical(d$Site, 1:176), !anyNA(d[, SITEC, with = FALSE]), uniqueN(d$MU) == 13,
          identical(names(yc), c("TQ", "DI")), nrow(yc) == 176 * 5, !anyNA(yc), all(yc$DI %in% 0:3))
Y <- as.matrix(d[, paste0("Day", 1:20), with = FALSE]); Q <- as.matrix(d[, paste0("Discharge", 1:20), with = FALSE])
B <- as.matrix(d[, paste0("Bait", 1:20), with = FALSE])
stopifnot(all(Y %in% c(0, 1, NA)), sum(!is.na(Y)) == 1341, sum(Y, na.rm = TRUE) == 321,
          !anyNA(Q[!is.na(Y)]), !anyNA(B[!is.na(Y)]), all(B[!is.na(Y)] %in% 0:7),
          all(rowSums(!is.na(Y)) > 0), all(as.matrix(d[, .(devel, grass, crop, wetland, forest)]) >= 0 & as.matrix(d[, .(devel, grass, crop, wetland, forest)]) <= 1))
dimnames(Y) <- list(d$Site, NULL)

period <- rep(1:5, each = 4)
yc[, `:=`(unit = rep(1:176, each = 5), period = rep(1:5, times = 176))]
sc <- d[, .(habitat_substrate_score = `Bottom Substrate`, habitat_cover_score = `Cover Score`, habitat_total_score = Total,
            developed_prop = devel, grass_pasture_prop = grass, crop_prop = crop, wetland_prop = wetland, forest_prop = forest,
            management_unit = MU)]
long <- array_to_eco(Y, taxon = "NECLEW", site_ids = d$Site, site_covs = sc, period = period,
                     obs_covs = list(discharge_m3s_prev_day = Q, bait_age_days = B))
long <- merge(long, yc[, .(unit, period, period_tq_mean = TQ, period_drought_index_max = DI)], by = c("unit", "period"))
stopifnot(nrow(long) == 1341, sum(long$y) == 321, !any(grepl("^unit_unit_", names(long))), all(long$occasion %in% 1:4))

taxa <- make_taxa("NECLEW", "Necturus lewisi", vernacularName = "Neuse River waterdog",
                  taxon_conservationStatus = "Threatened (US ESA, 2021)")
periods <- data.table(period = 1:5, study_year = 1:5, year = NA_integer_,
                      n_sites_surveyed = sapply(1:5, function(k) sum(rowSums(!is.na(Y[, period == k])) > 0)),
                      n_checks = sapply(1:5, function(k) sum(!is.na(Y[, period == k]))))

dataset <- list(
  title = "Trap detections of the Neuse River waterdog at 176 stream sites in North Carolina over five consecutive years, four checks per year",
  creator = "Teitsworth, Eric; Hall, Jeffrey; Archambault, Jennifer; Humphries, W. Jeffrey; Pacifici, Krishna",
  pubDate = "2026", doi = "10.5061/dryad.63xsj3vgg", sourceURL = "https://doi.org/10.5061/dryad.63xsj3vgg",
  citation = "Teitsworth, E., Hall, J., Archambault, J., Humphries, W. J., & Pacifici, K. (2026). Data from: Multiscale threats shape the occurrence dynamics of a threatened aquatic salamander and reveal a possible extinction debt [Dataset]. Dryad. https://doi.org/10.5061/dryad.63xsj3vgg",
  paperDOI = "10.1002/ece3.73225",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the Neuse River waterdog (Necturus lewisi), an aquatic salamander endemic to the Neuse and Tar-Pamlico basins of eastern North Carolina and listed as threatened in 2021, at 176 stream sites in 13 management units over five consecutive years with up to four overnight trap checks per year, with stream discharge and bait age per check, rapid habitat assessment scores and watershed land cover per site, and a yearly streamflow metric and drought intensity per site-year. The paper fit dynamic occupancy models: extinction rose with developed land cover and drought and fell with habitat quality, suggesting an extinction debt in urban subpopulations.",
  samplingProtocol = "Baited traps set at each site and checked on up to four consecutive mornings per year (captures overnight), in five consecutive years; discharge is the daily mean of the day before each check (USGS gauges, interpolated for ungauged sites).",
  samplingProtocolCode = "baited_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "period (study year; colext primary period)", occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Neuse and Tar-Pamlico River basins, eastern North Carolina, USA; no coordinates deposited",
  temporalCoverage = "five consecutive years before 2026 (calendar years not stated in the deposit)",
  coordinatesCoarsened = NA,
  notShipped = list(`discharge and bait on unsurveyed days` = "deposited for every day of the design; shipped only where a check happened",
                    `model_script.R, turnover_equilibrium_script.R` = "analysis code (model outputs and derived turnover/equilibrium estimates are not deposited as data)"),
  notes = "period is the study year 1..5; the deposit does not give calendar years. period_tq_mean and period_drought_index_max come from YearlySiteCovs.csv, which has no site or year column; they are assigned as row = (site - 1) * 5 + year, the unmarked yearlySiteCovs order that the README states and the authors' code uses. A check of that order is equivocal: under the alternative (years outer, sites inner) the drought index takes 2-3 values per year instead of 4 and TQ correlates 0.28 instead of -0.03 with mean visit discharge, so the alignment should be confirmed with the authors before relying on these two columns. The habitat scores and land-cover proportions are as deposited (the README's '%' are proportions).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/teitsworth_2026_necturus_dynocc.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of the threatened Neuse River waterdog (Necturus lewisi) in baited trap checks at 176 stream sites in eastern North Carolina over five consecutive years (up to four checks per year), with discharge and bait age per check, habitat scores, watershed land cover and management unit per site, and yearly streamflow and drought covariates.",
  url = "https://doi.org/10.5061/dryad.63xsj3vgg",
  reference = "Teitsworth, E., Hall, J., Archambault, J., Humphries, W. J., & Pacifici, K. (2026). Multiscale threats shape the occurrence dynamics of a threatened aquatic salamander and reveal a possible extinction debt. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.73225", doi_data = "10.5061/dryad.63xsj3vgg",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Calendar years not in the deposit. Yearly covariates lack site/year keys; assigned in the order the README states, with a caveat. No coordinates.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Dynamic occupancy (colext)",
  sampling_protocol = "baited_trap", design = "Multi-season (5 years x 4 checks)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "321 detections in 1,341 checks; ESA-threatened salamander.")
