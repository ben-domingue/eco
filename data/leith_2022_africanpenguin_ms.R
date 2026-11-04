#!/usr/bin/env Rscript
# Table:  leith_2022_africanpenguin_ms
# Source: Dryad doi:10.5061/dryad.0rxwdbs3z (CC0 1.0 as shown on the dataset JSON), version
#   192681 (published 2022-08-22). Leith, F., Barham, B., Barham, P., Ludynia, K., McGeorge, C.,
#   Mdluli, A., Parsons, N., Waller, L., Grigg, J. & Sherley, R. Intercolony variation in
#   reproductive skipping in the African penguin mark-recapture data.
# Paper:  Leith, F. W., et al. (2022). Intercolony variation in reproductive skipping in the
#   African penguin. Ecology and Evolution 12: e9255, doi:10.1002/ece3.9255 (open access; read
#   via Europe PMC PMC9448970).
# Data:   prebreed_full.inp: a MARK multistrata input file, 899 lines, one per penguin (asserted),
#           "<history> <freq Robben> <freq Stony Point>;" with an 8-character history over the
#           breeding seasons 2013-2020 in the states B (breeder), N (nonbreeder), P (prebreeder)
#           and 0 (not encountered). Each line has frequency 1 in exactly one group: 387 Robben
#           Island, 512 Stony Point (asserted; the paper's Table S1 counts). No PIT ids.
#         README_document_explanation.docx: group 1 = Robben, group 2 = Stony Point.
#         RMARK_Code_African_Penguins.docx: the authors' RMark code, including the DFFE
#           November hydro-acoustic spawner-biomass estimates of sardine and anchovy for
#           2013-2019 (and their sum, "Fish") as time covariates on survival and transition.
# Mapping (multi-state CJS, responseType state, unitKind individual):
#   unit = penguin (line number within colony: RI_001.., SP_001..; the deposit has no tag ids),
#   taxon = SPHDEM, period = breeding season 1..8 (2013..2020; March-October, year in
#   __periods), no occasion (one encounter state per season). unit_colony = Robben Island or
#   Stony Point (the paper's group). y = 0 not encountered, 1 encountered as breeder, 2
#   encountered as nonbreeder; y_raw = the deposited letter. "P" (prebreeder) is the authors'
#   recode of a nonbreeder encounter that precedes the bird's first breeding encounter (paper
#   2.2); asserted that every P precedes the first B. N follows a B except in 13 cells (9
#   birds) where N precedes the first B, a departure from the paper's rule kept as deposited.
#   Both are "encountered as a nonbreeder" and map to y = 2; y_raw keeps the letter for the
#   paper's three-state model. A breeder is a bird attending eggs or chicks at a nest
#   inspection, or recorded >= 6 times over 12-120 days on a ground reader without a nest
#   record (the authors' classification rule, from observations, not a model output).
#   Survey evidence: deposited_matrix. Both colonies were monitored every season 2013-2020
#   (paper 2.1; encounters from 2014, marking from 2013); a 0 is a season in which the bird was
#   not encountered. Rows before first capture are kept as 0 (standard E2, detection note).
#   obs_ground_readers = ground PIT readers operating at the bird's colony that season (paper
#   2.1: one at Robben Island from 2015; Stony Point one from 2016, two from 2017).
#   __periods: year, and the DFFE spawner biomass of sardine and anchovy in November of that
#   year as coded in the authors' RMark script (an external survey of the prey, not derived
#   from these encounters; units as in the source script; NA for 2020).
#   Coordinates: none in the deposit. The paper gives colony positions to the arc-minute;
#   S. demersus is IUCN Critically Endangered (2024; Endangered when the paper was written), so
#   geographicCoverage gives the colony names and 0.1-degree cell centres only.
#   Not shipped: nothing from the data file. The paper's double-marked birds (4) and one
#   inter-colony breeder were removed by the authors before deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "leith_2022_africanpenguin_ms"
dir <- download_dryad("10.5061/dryad.0rxwdbs3z", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("prebreed_full.inp", "README_document_explanation.docx", "RMARK_Code_African_Penguins.docx")))

raw <- readLines(file.path(dir, "prebreed_full.inp"))
stopifnot(length(raw) == 899L, all(grepl("^[BNP0]{8}\t[01]\t[01];$", raw)))
f <- tstrsplit(sub(";$", "", raw), "\t")
ch <- f[[1]]; g1 <- as.integer(f[[2]]); g2 <- as.integer(f[[3]])
stopifnot(all(g1 + g2 == 1L), sum(g1) == 387L, sum(g2) == 512L)
colony <- ifelse(g1 == 1L, "Robben Island", "Stony Point")
ids <- ifelse(g1 == 1L, sprintf("RI_%03d", cumsum(g1)), sprintf("SP_%03d", cumsum(g2)))
M <- do.call(rbind, strsplit(ch, ""))
stopifnot(all(rowSums(M != "0") >= 1L))
# P is a nonbreeder encounter before the first breeding encounter (paper 2.2). N is a nonbreeder
# encounter after one, except in 13 cells of 9 birds where N precedes the first B (one of them the
# bird's first encounter): a departure from the paper's rule, kept as deposited.
n_early_N <- 0L
for (i in seq_len(nrow(M))) {
  b <- which(M[i, ] == "B"); fb <- if (length(b)) min(b) else Inf
  stopifnot(all(which(M[i, ] == "P") < fb))
  n_early_N <- n_early_N + sum(which(M[i, ] == "N") < fb)
}
stopifnot(n_early_N == 13L)
# only breeders were marked in 2013 (paper)
stopifnot(all(M[, 1] %in% c("B", "0")))
cat(sprintf("  states: %s\n", paste(names(table(M)), table(M), collapse = ", ")))

yrs <- 2013:2020
Y <- matrix(c(`0` = 0L, B = 1L, N = 2L, P = 2L)[M], nrow(M))
long <- array_to_eco(Y, taxon = "SPHDEM", site_ids = ids, site_covs = data.frame(colony = colony),
                     period = seq_along(yrs), y_raw = M)
long[, occasion := NULL]
readers <- function(col, yr) ifelse(col == "Robben Island", as.integer(yr >= 2015), (yr >= 2016) + (yr >= 2017))
long[, obs_ground_readers := as.integer(readers(unit_colony, yrs[period]))]
stopifnot(nrow(long) == 899L * 8L, sum(long$y > 0) == sum(M != "0"))

# DFFE November spawner biomass, year t, as coded in the authors' RMark script
periods <- data.table(period = seq_along(yrs), year = yrs,
  sardine_spawner_biomass = c(581763, 444501, 363230, 258575, 334804, 90768, 193629, NA),
  anchovy_spawner_biomass = c(3819666, 2970760, 1944258, 1733041, 1568398, 1559546, 843745, NA),
  fish_spawner_biomass    = c(4401429, 3415261, 2307488, 1991616, 1903202, 1650314, 1037374, NA))
stopifnot(all.equal(periods$sardine_spawner_biomass + periods$anchovy_spawner_biomass, periods$fish_spawner_biomass))
periods[, n_encountered := as.integer(colSums(M != "0"))]
periods[, note := "breeding season March-October of year; biomass = DFFE November hydro-acoustic survey of spawners (fish >= 1 yr), year t, as in the authors' RMark code (relates to survival t to t+1)"]

taxa <- make_taxa("SPHDEM", "Spheniscus demersus", vernacularName = "African Penguin")
ri <- coarsen_coords(-(33 + 48/60), 18 + 22/60); sp <- coarsen_coords(-(34 + 22/60), 18 + 53/60)

dataset <- list(
  title = "Multistate encounter histories (breeder / nonbreeder) of 899 PIT-tagged African penguins, Robben Island and Stony Point, South Africa, 2013-2020",
  creator = "Leith, Freddie; Barham, Barbara; Barham, Peter; Ludynia, Katrin; McGeorge, Cuan; Mdluli, Andile; Parsons, Nola; Waller, Lauren; Grigg, Jennifer; Sherley, Richard",
  pubDate = "2022", doi = "10.5061/dryad.0rxwdbs3z", sourceURL = "https://doi.org/10.5061/dryad.0rxwdbs3z",
  citation = "Leith, F., Barham, B., Barham, P., Ludynia, K., McGeorge, C., Mdluli, A., Parsons, N., Waller, L., Grigg, J., & Sherley, R. (2022). Intercolony variation in reproductive skipping in the African penguin mark-recapture data [Dataset]. Dryad. https://doi.org/10.5061/dryad.0rxwdbs3z",
  paperDOI = "10.1002/ece3.9255",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Adult African penguins marked with passive integrated transponders at two Western Cape colonies from 2013 and encountered on nest inspections (hand-held readers) and colony ground readers each breeding season to 2020, with breeding status at each encounter. The paper fits multistate CJS models (breeder, nonbreeder, prebreeder) with colony groups and prey biomass covariates to estimate survival and reproductive skipping.",
  samplingProtocol = "PIT tagging of adults captured in the colony; each breeding season (March-October) tagged birds were encountered with hand-held transponder readers during routine nest monitoring and, from 2015 (Robben Island) and 2016 (Stony Point), by ground readers on paths to the sea. A bird attending eggs or chicks, or read >= 6 times over 12-120 days by a ground reader without a nest record, was classed a breeder; otherwise a nonbreeder.",
  samplingProtocolCode = "pit_resight", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not encountered in the season", `1` = "encountered as a breeder (y_raw B)",
                    `2` = "encountered as a nonbreeder (y_raw N after the bird's first breeding encounter, P before it: the authors' prebreeder state)"),
  closure = "none", closureNote = "period (one state per breeding season; survival and state transitions between seasons)", occasionKind = "none", taxonInclusion = "single",
  lossesOnCapture = "none recorded",
  geographicCoverage = sprintf("Robben Island (cell centre %.2f, %.2f) and Stony Point, Betty's Bay (cell centre %.2f, %.2f), Western Cape, South Africa", ri$lat, ri$lon, sp$lat, sp$lon),
  temporalCoverage = "2013/2020",
  coordinatesCoarsened = list(value = TRUE, method = "No coordinates in the deposit; colony positions from the paper (arc-minute) are given in geographicCoverage as 0.1-degree cell centres because S. demersus is IUCN Critically Endangered."),
  notShipped = list(none = "every deposited history is shipped; the authors removed 4 double-marked birds and 1 inter-colony breeder before deposit"),
  notes = "Unit ids are line numbers within colony (no PIT ids in the deposit). Rows before a bird's first encounter are 0; condition on first capture as the authors do. Only breeders were marked in 2013, and no nonbreeders at Robben Island in 2014 (the paper fixes the matching parameters to 0). Detection effort fell in 2018 (avian influenza) and 2020 (COVID-19), especially at Robben Island; obs_ground_readers gives reader coverage. For the paper's three-state model, recode y_raw P to a third state; 13 N cells (9 birds) precede the bird's first breeding encounter, against the paper's P definition, and are kept as deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/leith_2022_africanpenguin_ms.R")

stage_dict_row(TABLE,
  description = "Annual multistate encounter histories (breeder / nonbreeder, with the authors' prebreeder recode in y_raw) of 899 PIT-tagged adult African penguins at Robben Island (387) and Stony Point (512), South Africa, 2013-2020, with ground-reader coverage per colony-season and DFFE sardine and anchovy spawner biomass per year in __periods.",
  url = "https://doi.org/10.5061/dryad.0rxwdbs3z",
  reference = "Leith, F. W., Grigg, J. L., Barham, B. J., Barham, P. J., Ludynia, K., McGeorge, C., Mdluli, A., Parsons, N. J., Waller, L. J., & Sherley, R. B. (2022). Intercolony variation in reproductive skipping in the African penguin. Ecology and Evolution, 12, e9255.",
  doi_paper = "10.1002/ece3.9255", doi_data = "10.5061/dryad.0rxwdbs3z",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Critically Endangered seabird; no coordinates in the deposit (colony cells to 0.1 degree in metadata). Unit ids are line numbers.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS capture-recapture (breeding state; reproductive skipping)",
  sampling_protocol = "pit_resight", design = "Multi-session (8 breeding seasons), two colonies",
  realm = "Marine", country = "ZAF", coordinates = "None in source (colony cells in metadata)",
  notes = "Seabird; breeder / nonbreeder states with prebreeder recode in y_raw.")
