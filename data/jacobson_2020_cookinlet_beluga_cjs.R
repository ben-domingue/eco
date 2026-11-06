#!/usr/bin/env Rscript
# Table:  jacobson_2020_cookinlet_beluga_cjs
# Source: Dryad doi:10.5061/dryad.9zw3r229w (CC0 1.0, as shown on the Dryad page; published
#         2020). Jacobson, E.K., Boyd, C., McGuire, T.L., Shelden, K.E.W., Himes Boor, G.K. &
#         Punt, A.E. Data from: Assessing cetacean populations using integrated population
#         models: an example with Cook Inlet beluga whales.
# Paper:  Jacobson, E.K. et al. (2020). Ecological Applications, doi:10.1002/eap.2114. Integrated
#         population model of the Cook Inlet beluga (ESA-endangered population): aerial counts,
#         hunt records and photo-identification capture-recapture.
# Data:   JacobsonEtAl2020_DryadArchive.zip -> Data/CIBW_RSideCapHist_McGuire&Stephens.csv: "a
#         matrix of right side capture histories (1 = captured, 0 = not captured) for each
#         individual (rows) and year (columns)" (README), 12 columns = 2005-2016 (the authors'
#         CIBW_02_LoadData.R names them so). The file has no header row: the authors' read.csv()
#         takes the first history as column names, so their analysis has 385 animals; all 386
#         rows are shipped here (asserted). The README asks users to contact Tamara McGuire
#         about how the histories were built (a request, not a licence term; the deposit is
#         CC0). Other files: aerial abundance posteriors and estimates, hunt records (model
#         inputs and literature summaries, not detection histories), JAGS model and scripts.
# Mapping (standard: CJS, E9 core): unit = whale (W001..W386, file order); taxon = DELLEU; period
#   = year 1..12 (2005-2016, __periods); y = right-side photo-identification 0/1. Full rectangle
#   from 2005 (E4.4). Survey evidence: deposited_matrix. No coordinates; beluga is IUCN LC, the
#   Cook Inlet population is listed as endangered under the US ESA.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "jacobson_2020_cookinlet_beluga_cjs"
dir <- download_dryad("10.5061/dryad.9zw3r229w", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
f <- list.files(ex, "^CIBW_RSideCapHist_McGuire&Stephens\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
H <- as.matrix(read.csv(f, header = FALSE))
stopifnot(identical(dim(H), c(386L, 12L)), all(H %in% 0:1), all(rowSums(H) > 0))
ids <- sprintf("W%03d", seq_len(386))
long <- data.table(unit = rep(ids, 12), period = rep(1:12, each = 386), y = as.integer(as.vector(H)), taxon = "DELLEU")
long <- order_eco(long)
stopifnot(nrow(long) == 386 * 12)
periods <- data.table(period = 1:12, period_year = 2005:2016)
taxa <- make_taxa("DELLEU", "Delphinapterus leucas", vernacularName = "Beluga")
dataset <- list(
  title = "Photo-identification (right side) capture histories of 386 Cook Inlet beluga whales, Alaska, 2005-2016",
  creator = "Jacobson, Eiren K.; Boyd, Charlotte; McGuire, Tamara L.; Shelden, Kim E. W.; Himes Boor, Gina K.; Punt, André E.", pubDate = "2020",
  doi = "10.5061/dryad.9zw3r229w", sourceURL = "https://doi.org/10.5061/dryad.9zw3r229w",
  citation = "Jacobson, E. K., Boyd, C., McGuire, T. L., Shelden, K. E. W., Himes Boor, G. K., & Punt, A. E. (2020). Data from: Assessing cetacean populations using integrated population models: an example with Cook Inlet beluga whales [Dataset]. Dryad. https://doi.org/10.5061/dryad.9zw3r229w",
  paperDOI = "10.1002/eap.2114",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual right-side photo-identification capture histories of 386 Cook Inlet beluga whales (Delphinapterus leucas), Alaska, 2005-2016, collected by T. McGuire: the capture-recapture component of an integrated population model for this endangered population.",
  samplingProtocol = "Boat-based photo-identification of belugas in Cook Inlet; individuals identified from right-side photographs (marks and scars); one encounter record per whale per year.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one record per whale per year; open between years (CJS)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Cook Inlet, Alaska, USA; no coordinates deposited", temporalCoverage = "2005/2016",
  notShipped = list(model_inputs = "aerial survey abundance posteriors and estimates, hunt records, JAGS model and scripts"),
  notes = "The file has no header; the authors' script reads it with a header and so drops the first whale (385 in their analysis); all 386 are shipped. The README asks users to contact T. McGuire about how the histories were processed. The Cook Inlet population is listed as endangered under the US ESA; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/jacobson_2020_cookinlet_beluga_cjs.R")
stage_dict_row(TABLE, description = "Right-side photo-ID capture histories of 386 Cook Inlet beluga whales, 2005-2016.",
  url = "https://doi.org/10.5061/dryad.9zw3r229w", reference = "Jacobson, E. K. et al. (2020). Assessing cetacean populations using integrated population models: an example with Cook Inlet beluga whales. Ecological Applications.",
  doi_paper = "10.1002/eap.2114", doi_data = "10.5061/dryad.9zw3r229w", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "CJS photo-ID; endangered population, no coordinates.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Cormack-Jolly-Seber",
  sampling_protocol = "photo_id", design = "Multi-season (12 years)", realm = "Marine",
  country = "USA", coordinates = "None in source", notes = "ESA-endangered beluga population.")
