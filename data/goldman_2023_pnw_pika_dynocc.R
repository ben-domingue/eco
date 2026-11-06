#!/usr/bin/env Rscript
# Table:  goldman_2023_pnw_pika_dynocc
# Source: Dryad doi:10.5061/dryad.ttdz08m2n (CC0 1.0 as shown on the dataset JSON), version 235059
#   (version 2.0.0 of the README, 2023-04-28). Goldman, M. R., Shinderman, M., Jeffress, M. R.,
#   Rodhouse, T. J. & Shoemaker, K. T. Data from: Integrating multiple sign types to improve
#   occupancy estimation for inconspicuous species. The README asks that use of the data
#   attribute the OSU-Cascades Human and Ecosystem Resilience and Sustainability (HERS) Lab; the
#   licence is CC0, so this is a request, carried in notes.
# Paper:  Goldman, M. R., Shinderman, M., Jeffress, M. R., Rodhouse, T. J. & Shoemaker, K. T.
#   (2023). Ecology and Evolution 13(5), e10019, doi:10.1002/ece3.10019 (open access; Europe PMC
#   PMC10183821). American pika surveys 2010-2014 (National Park Service) and 2017-2021 (OSU-Cascades
#   HERS Lab) in five park units; 12 m radius plots searched for up to 30 min, up to 10 sign
#   observations recorded per survey; at least 30% of surveys are resurveys within two weeks of
#   the original survey "to ensure no occupancy turnover". Multi-sign dynamic occupancy models
#   (fresh scat, fresh haypile, call, sighting) with and without false positives.
# Data:   post_process.csv: 5,126 rows, one per survey (asserted unique Survey_ID = plot_date):
#           plot (771 plots, park prefix), Park (CRLA, CRMO, LABE, LAVO, NEWB), Plot_ID, Location_ID
#           (plot_year), Field_Date (DD/MM/YYYY), ssn / Season (summer / "autumm"), Year, Month,
#           Yday (all asserted consistent with Field_Date), OS / OH / FH / PS / PC / FS = counts of
#           old scat, old haypiles, fresh haypiles, pika sightings, pika calls, fresh scat; FS_U =
#           unambiguous fresh scat (NA on 682 surveys); hassign = any sign (asserted equal to any
#           of OS..FS > 0); resurv (1 = resurvey); PerClass_Rock / Bare / Grass / Shrub / Tree /
#           Forb = Daubenmire cover class codes (0-7, T = trace; NA where not recorded; a few typos
#           "o", "r"); lava_complx (0-3 substrate complexity, constant per plot, NA at LAVO);
#           tmaxmean and dailysumppt (publicly sourced mean maximum temperature, C, and summed
#           precipitation, mm, per plot and year).
#         DataForJAGS_MultiSign.RData: the same surveys reshaped for the authors' JAGS model
#           (binary sign arrays, scaled covariates); nonfpmodel_cplx_EE.R: model code.
# Mapping (dynamic occupancy, single species): unit = plot, taxon = OCHPRI, period = year - 2009
#   (2010 = 1, ..., 2021 = 12; no surveys in 2015-2016), occasion = survey within plot-year in date
#   order (1-3), y = any fresh sign (FS, FH, PC or PS > 0), date = Field_Date. The sign counts ship as
#   obs_n_old_scat, obs_n_old_haypile, obs_n_fresh_haypile, obs_n_sighting, obs_n_call,
#   obs_n_fresh_scat, obs_n_fresh_scat_unambiguous, so the paper's multi-sign model (a detection
#   process per sign type) can be refitted from the rows; obs_resurvey, obs_season; obs_cover_*
#   (cover class codes as deposited, character); unit_park, unit_lava_complexity;
#   obs_tmax_mean_c and obs_precip_sum_mm (plot-year values; tmaxmean varies within a plot-year
#   in a few cases, so both are obs_). Survey evidence = sample_table: post_process.csv lists the
#   conducted surveys, with explicit zero counts.
#   y follows the paper's detection definition (ruling 2026-11-06, #10): "Observations of old
#   sign were not included in our analyses", so y = any fresh sign, not the deposited hassign
#   (which also counts old scat and old haypiles). hassign is not shipped; it is obs_n_old_* > 0
#   or y. The sign counts let a user refit the multi-sign and false-positive models.
#   No coordinates are deposited (plot ids only); the pika is IUCN LC.
# Not shipped: ssn and Month / Yday (recodes of Season and the shipped date); Location_ID and
#   Survey_ID (concatenations of plot, year and date); Plot_ID (the plot number within the park,
#   part of plot); hassign (see above); the RData file (the same surveys reshaped and scaled for JAGS).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldman_2023_pnw_pika_dynocc"
dir <- download_dryad("10.5061/dryad.ttdz08m2n", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
d <- fread(file.path(dir, "post_process.csv"), colClasses = list(character = c("PerClass_Rock", "PerClass_Bare", "PerClass_Grass", "PerClass_Shrub", "PerClass_Tree", "PerClass_Forb")))
stopifnot(nrow(d) == 5126L, !anyDuplicated(d$Survey_ID), uniqueN(d$plot) == 771L,
          setequal(d$Park, c("CRLA", "CRMO", "LABE", "LAVO", "NEWB")), all(d[, uniqueN(Park), by = plot]$V1 == 1L),
          all(substr(d$plot, 1, 4) == d$Park), setequal(d$Year, c(2010:2014, 2017:2021)),
          all(d$Season %in% c("summer", "autumm")), all(d$resurv %in% 0:1), all(d$hassign %in% 0:1))
d[, dt := as.IDate(Field_Date, format = "%d/%m/%Y")]
stopifnot(!anyNA(d$dt), all(year(d$dt) == d$Year), all(month(d$dt) == d$Month), all(yday(d$dt) == d$Yday),
          all(d$Survey_ID == paste0(d$plot, "_", format(d$dt, "%Y-%m-%d"))), all(d$Location_ID == paste0(d$plot, "_", d$Year)))
C <- c("OS", "OH", "FH", "PS", "PC", "FS")
stopifnot(all(unlist(d[, ..C]) >= 0), !anyNA(d[, ..C]), sum(is.na(d$FS_U)) == 682L,
          all(d$hassign == as.integer(rowSums(d[, ..C]) > 0)), sum(d$hassign) == 2793L)
stopifnot(all(d[, uniqueN(lava_complx), by = plot]$V1 == 1L), all(is.na(d[Park == "LAVO"]$lava_complx)),
          all(d[, uniqueN(dailysumppt), by = .(plot, Year)]$V1 == 1L))
setorder(d, plot, dt)
d[, occasion := seq_len(.N), by = .(plot, Year)]
stopifnot(identical(as.integer(table(d$occasion)), c(4012L, 1107L, 7L)), all(d[occasion == 2L]$resurv == 1L))

d[, fresh := as.integer(FS + FH + PC + PS > 0)]
stopifnot(all(d$fresh <= d$hassign))
long <- d[, .(unit = plot, taxon = "OCHPRI", y = fresh, period = Year - 2009L, occasion, date = as.character(dt),
              unit_park = Park, unit_lava_complexity = lava_complx,
              obs_n_old_scat = OS, obs_n_old_haypile = OH, obs_n_fresh_haypile = FH, obs_n_sighting = PS, obs_n_call = PC,
              obs_n_fresh_scat = FS, obs_n_fresh_scat_unambiguous = FS_U, obs_resurvey = resurv,
              obs_season = ifelse(Season == "autumm", "autumn", "summer"),
              obs_cover_rock = PerClass_Rock, obs_cover_bare = PerClass_Bare, obs_cover_grass = PerClass_Grass,
              obs_cover_shrub = PerClass_Shrub, obs_cover_tree = PerClass_Tree, obs_cover_forb = PerClass_Forb,
              obs_tmax_mean_c = tmaxmean, obs_precip_sum_mm = dailysumppt)]
for (cc in grep("^obs_cover_", names(long), value = TRUE)) set(long, which(long[[cc]] == ""), cc, NA_character_)
long <- order_eco(long)
stopifnot(nrow(long) == 5126L, uniqueN(long[, .(unit, period)]) == 4012L)

taxa <- make_taxa("OCHPRI", "Ochotona princeps", vernacularName = "American pika")
periods <- data.table(period = sort(unique(long$period)))[, year := period + 2009L]

dataset <- list(
  title = "American pika sign surveys at 771 plots in five national park units of Oregon, Idaho and California, 2010-2014 and 2017-2021, with counts by sign type",
  creator = "Goldman, Mia R.; Shinderman, Matthew; Jeffress, Mackenzie R.; Rodhouse, Thomas J.; Shoemaker, Kevin T.",
  pubDate = "2023", doi = "10.5061/dryad.ttdz08m2n", sourceURL = "https://doi.org/10.5061/dryad.ttdz08m2n",
  citation = "Goldman, M. R., Shinderman, M., Jeffress, M. R., Rodhouse, T. J., & Shoemaker, K. T. (2023). Data from: Integrating multiple sign types to improve occupancy estimation for inconspicuous species [Dataset]. Dryad. https://doi.org/10.5061/dryad.ttdz08m2n",
  paperDOI = "10.1002/ece3.10019",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual surveys for American pika sign in 12 m radius plots at Crater Lake National Park, Craters of the Moon, Lava Beds and Newberry National Monuments and Lassen Volcanic National Park (2010-2014 by the National Park Service, 2017-2021 by the OSU-Cascades HERS Lab), with a resurvey of about a third of plots within weeks of the first visit. Each survey records counts of old and fresh scat, old and fresh haypiles, calls and sightings, with cover classes and substrate complexity. The paper fits multi-sign dynamic occupancy models with sign-specific detection and false positives.",
  samplingProtocol = "Sign survey of a 12 m radius circular plot on talus or lava, up to 30 minutes, recording up to 10 sign observations (old / fresh scat, old / fresh haypile, call, sighting) and Daubenmire cover classes; about 30% of plots resurveyed within two weeks to a month of the original survey each year.",
  samplingProtocolCode = "sign_survey", surveyEvidence = "sample_table",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "surveys within a plot-year are treated as closed (the paper: resurveys within two weeks to ensure no occupancy turnover); years are periods. Seven plot-years have three surveys.",
  geographicCoverage = "Crater Lake NP (Oregon), Newberry National Volcanic Monument (Oregon), Craters of the Moon NM&P (Idaho), Lava Beds NM and Lassen Volcanic NP (California), USA",
  temporalCoverage = "2010/2021",
  notShipped = list(recodes = "ssn, Month and Yday (recodes of Season and the date)",
                    identifiers = "Survey_ID, Location_ID and Plot_ID (concatenations or parts of plot, year and date)",
                    hassign = "the source's any-sign flag, which counts old sign the paper did not analyse; recoverable as y or any obs_n_old_* > 0",
                    jags_data = "DataForJAGS_MultiSign.RData: the same surveys reshaped and scaled for the authors' JAGS model"),
  notes = "y = any fresh sign (fresh scat, fresh haypile, call or sighting), the paper's detection definition (old sign was not analysed); the source's hassign also counts old scat and old haypiles and is not shipped (it equals y or any obs_n_old_* > 0). For the paper's multi-sign or false-positive models use the obs_n_* counts. obs_n_fresh_scat_unambiguous is NA on 682 surveys where it was not recorded. obs_cover_* are Daubenmire class codes as deposited (T = trace). No coordinates are deposited. The README asks that use of the data attribute the OSU-Cascades Human and Ecosystem Resilience and Sustainability Lab, with support from the National Park Service.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/goldman_2023_pnw_pika_dynocc.R")

stage_dict_row(TABLE,
  description = "American pika (Ochotona princeps) sign surveys at 771 plots in five national park units of Oregon, Idaho and California, 2010-2014 and 2017-2021, with partial within-year resurveys and per-survey counts of each sign type (old and fresh scat and haypiles, calls, sightings).",
  url = "https://doi.org/10.5061/dryad.ttdz08m2n",
  reference = "Goldman, M. R., Shinderman, M., Jeffress, M. R., Rodhouse, T. J., & Shoemaker, K. T. (2023). Integrating multiple sign types to improve occupancy estimation for inconspicuous species. Ecology and Evolution, 13(5), e10019.",
  doi_paper = "10.1002/ece3.10019", doi_data = "10.5061/dryad.ttdz08m2n",
  original_license = "CC0 1.0 (README requests attribution to the OSU-Cascades HERS Lab)", derived_license = "CC0 1.0",
  notes = "Dynamic occupancy with sign-type counts as obs_ columns (multi-sign model refittable); y = any fresh sign, as in the paper (old sign in obs_ columns).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-sign; sign-type counts per survey)",
  sampling_protocol = "sign_survey", design = "Multi-season (10 years, 2010-2021; 1-3 surveys per plot-year)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Climate-sensitive talus mammal; resurveys on about a third of plots.")
