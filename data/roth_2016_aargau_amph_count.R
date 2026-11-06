#!/usr/bin/env Rscript
# Table:  roth_2016_aargau_amph_count
# Source: Dryad doi:10.5061/dryad.7gt4m (CC0 1.0, as shown on the Dryad page; published
#         2015-10-20). Roth, T., Buhler, C. & Amrhein, V. Data from: Estimating effects of species
#         interactions on populations of endangered species.
# Paper:  Roth, T., Buhler, C. & Amrhein, V. (2016). The American Naturalist 187(4), 457-467,
#         doi:10.1086/685095. Amphibian Monitoring Program of the canton of Aargau, northern
#         Switzerland (Schmidt 2005; Tanadini & Schmidt 2011); two-species N-mixture models.
# Data:   amphibian_monitoring_AG.xlsx (481 sites x 16 columns; README_for_amphibian_monitoring_AG
#         .txt defines all): counts on two visits of yellow-bellied toad (YBT), common midwife
#         toad (CMT), natterjack toad (NJT) ("the three endangered toad species", README) and
#         the water frog complex (WF: Pelophylax ridibundus, P. lessonae and hybrids P.
#         esculentus, "phenotypically similar"); elevation (m), surface (m2 of water), fish
#         (0/1), fluct (strong water-level fluctuation between visits, 0/1), cover (vegetation
#         cover, 0/1), julian_1 / julian_2 (day of year of each visit). No missing values. No
#         survey year and no coordinates in the deposit.
# Mapping (standard: repeated counts, community N-mixture, E9 core): unit = SITE_ID; taxon =
#   BOMVAR, ALYOBS, EPICAL, PELOPH (water frog complex, genus rank); occasion = visit 1..2; y =
#   count; obs_date_doy = julian_k (no year is deposited, so no ISO date). unit_: elevation,
#   surface, fish, fluct, cover. Survey evidence: deposited_matrix (two visits at every site).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roth_2016_aargau_amph_count"
dir <- download_dryad("10.5061/dryad.7gt4m", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^amphibian_monitoring_AG\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
d <- as.data.table(read_excel(f))
stopifnot(identical(names(d), c("SITE_ID", "YBT_1", "YBT_2", "CMT_1", "CMT_2", "NJT_1", "NJT_2", "WF_1", "WF_2", "elevation", "surface", "fish", "fluct", "cover", "julian_1", "julian_2")),
          nrow(d) == 481, !anyDuplicated(d$SITE_ID), !anyNA(d), all(d$julian_1 < d$julian_2))
SP <- c(YBT = "BOMVAR", CMT = "ALYOBS", NJT = "EPICAL", WF = "PELOPH")
Y <- array(NA_integer_, dim = c(481, 2, 4), dimnames = list(as.character(d$SITE_ID), NULL, unname(SP)))
for (k in names(SP)) Y[, , SP[k]] <- as.matrix(d[, paste0(k, "_", 1:2), with = FALSE])
stopifnot(all(Y >= 0), all(Y == round(Y)))
J <- as.matrix(d[, .(julian_1, julian_2)])
sc <- as.data.frame(d[, .(elevation_m = elevation, water_surface_m2 = surface, fish, water_fluctuation = fluct, vegetation_cover = cover)])
long <- array_to_eco(Y, site_ids = as.character(d$SITE_ID), site_covs = sc, obs_covs = list(date_doy = J))
long <- order_eco(long)
stopifnot(nrow(long) == 481 * 2 * 4)
taxa <- make_taxa(unname(SP), c("Bombina variegata", "Alytes obstetricans", "Epidalea calamita", "Pelophylax"),
                  vernacularName = c("Yellow-bellied toad", "Common midwife toad", "Natterjack toad", "Water frogs"),
                  taxonRank = c("species", "species", "species", "genus"), allow_higher = "PELOPH",
                  taxonRemarks = c(NA, NA, NA, "the water frog complex: Pelophylax ridibundus, P. lessonae and their hybrid P. esculentus, counted together (phenotypically similar)"))
dataset <- list(
  title = "Counts of three endangered toads and the water frog complex on two visits to 481 sites of the Aargau amphibian monitoring, Switzerland",
  creator = "Roth, Tobias; Bühler, Christoph; Amrhein, Valentin", pubDate = "2015", doi = "10.5061/dryad.7gt4m", sourceURL = "https://doi.org/10.5061/dryad.7gt4m",
  citation = "Roth, T., Bühler, C., & Amrhein, V. (2015). Data from: Estimating effects of species interactions on populations of endangered species [Dataset]. Dryad. https://doi.org/10.5061/dryad.7gt4m",
  paperDOI = "10.1086/685095",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of yellow-bellied toad, common midwife toad, natterjack toad and the invasive water frog complex on two visits to each of 481 sites of the Amphibian Monitoring Program of the canton of Aargau, northern Switzerland, with the day of year of each visit and site elevation, water surface, fish presence, water-level fluctuation and vegetation cover.",
  samplingProtocol = "Two visits per site in spring (Amphibian Monitoring Program of the canton of Aargau; Schmidt 2005); calling and visual counts of each species per visit.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "count",
  unitKind = "site", closure = "closed", closureNote = "two visits in one breeding season, analysed as closed N-mixture", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Canton of Aargau, northern Switzerland; no coordinates deposited",
  temporalCoverage = "survey year not stated in the deposit (paper 2016)",
  notShipped = list(none = "every deposited column is shipped (julian days as obs_date_doy)"),
  notes = "The three toads are endangered in Switzerland (README; national red list); no coordinates are deposited. The survey year is not in the deposit, so day of year is shipped as obs_date_doy and no ISO date is built.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/roth_2016_aargau_amph_count.R")
stage_dict_row(TABLE, description = "Two-visit counts of three endangered toads and water frogs at 481 sites of the Aargau amphibian monitoring, Switzerland, with site covariates.",
  url = "https://doi.org/10.5061/dryad.7gt4m", reference = "Roth, T., Bühler, C., & Amrhein, V. (2016). Estimating effects of species interactions on populations of endangered species. The American Naturalist, 187(4), 457-467.",
  doi_paper = "10.1086/685095", doi_data = "10.5061/dryad.7gt4m", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community N-mixture counts; no year or coordinates deposited.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community N-mixture (repeated counts)",
  sampling_protocol = "visual_encounter", design = "Single-season (2 visits)", realm = "Freshwater",
  country = "CHE", coordinates = "None in source", notes = "Nationally endangered toads.")
