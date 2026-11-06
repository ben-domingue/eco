#!/usr/bin/env Rscript
# Table:  mackenzie_2021_stexas_mesocarniv_dynocc
# Source: Dryad doi:10.5061/dryad.59zw3r26t (CC0 1.0, as shown on the Dryad page; published
#         2021-11-26). MacKenzie, D.I., Lombardi, J.V. & Tewes, M.E. Investigating cooccurrence
#         patterns and dynamics for many imperfectly detected species, using a log-linear
#         modelling parameterisation.
# Paper:  MacKenzie, D.I., Lombardi, J.V. & Tewes, M.E. (2021). Ecology and Evolution,
#         doi:10.1002/ece3.7604. Example data: camera trapping of ocelot, bobcat and coyote in
#         South Texas (the camera data of Lombardi et al., Dryad doi:10.5061/dryad.931zcrjgp).
# Data:   cooccurrence_data.RData: det_idx (28 sites x 70 columns = 14 seasons x 5 four-week
#         occasions, values 1-8 or NA), k (5 surveys per season, 14 seasons), nSpec = 3;
#         functions.R (state_code(): code c is row c of expand.grid(spA, spB, spC) over {0, 1}, so
#         spA = ocelot is the fastest-varying bit); analysis_code.R ("ocelot=spA, bobcat=spB,
#         coyote=spC"; "the value '1' indicates no species detected in survey").
# Mapping (standard: dynamic multi-species occupancy, E9 core): unit = site 1-28 (row order);
#   taxon = LEOPAR / LYNRUF / CANLAT; period = season 1-14; occasion = 4-week occasion 1-5; y =
#   the species' bit of the code (state_code decoded and asserted against functions.R). NA = not
#   surveyed, for all three (one camera). Survey evidence: deposited_matrix. No dates, no
#   coordinates. Ocelot IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mackenzie_2021_stexas_mesocarniv_dynocc"
dir <- download_dryad("10.5061/dryad.59zw3r26t", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^cooccurrence_data\\.RData$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
e <- new.env(); stopifnot(identical(sort(load(f, e)), c("det_idx", "k", "nSpec")))
fn <- new.env(); sys.source(list.files(dir, "^functions\\.R$", recursive = TRUE, full.names = TRUE), envir = fn)
sc <- fn$state_code(3)
X <- e$det_idx; stopifnot(identical(dim(X), c(28L, 70L)), all(e$k == 5), length(e$k) == 14, e$nSpec == 3, all(X %in% c(1:8, NA)))
stopifnot(identical(as.integer(sc$det_code), 1:8), identical(as.integer(sc$spA), rep(0:1, 4)), identical(as.integer(sc$spB), rep(rep(0:1, each = 2), 2)),
          identical(as.integer(sc$spC), rep(0:1, each = 4)))
SP <- c(LEOPAR = "spA", LYNRUF = "spB", CANLAT = "spC")
g <- CJ(i = 1:28, j = 1:70)[!is.na(X[cbind(i, j)])]
long <- rbindlist(lapply(names(SP), function(t) g[, .(unit = sprintf("S%02d", i), taxon = t, period = (j - 1L) %/% 5L + 1L, occasion = (j - 1L) %% 5L + 1L,
                                                    y = as.integer(sc[[SP[[t]]]][X[cbind(i, j)]]))]))
long <- order_eco(long)
stopifnot(nrow(long) == 3 * sum(!is.na(X)), sum(long[taxon == "LEOPAR"]$y) == sum(X %in% c(2, 4, 6, 8)))
taxa <- make_taxa(names(SP), c("Leopardus pardalis", "Lynx rufus", "Canis latrans"), vernacularName = c("Ocelot", "Bobcat", "Coyote"))
dataset <- list(
  title = "Camera detections of ocelot, bobcat and coyote at 28 South Texas sites over 14 seasons of five 4-week occasions",
  creator = "MacKenzie, Darryl I.; Lombardi, Jason V.; Tewes, Michael E.", pubDate = "2021", doi = "10.5061/dryad.59zw3r26t", sourceURL = "https://doi.org/10.5061/dryad.59zw3r26t",
  citation = "MacKenzie, D. I., Lombardi, J. V., & Tewes, M. E. (2021). Investigating cooccurrence patterns and dynamics for many imperfectly detected species, using a log-linear modelling parameterisation [Dataset]. Dryad. https://doi.org/10.5061/dryad.59zw3r26t",
  paperDOI = "10.1002/ece3.7604",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of ocelot, bobcat and coyote at 28 camera sites in South Texas over 14 seasons, each of five four-week occasions, decoded from the multi-species detection codes of the authors' log-linear co-occurrence example.",
  samplingProtocol = "Camera traps; detections of the three mesocarnivores collapsed to four-week occasions, five per season, and coded jointly as which species were detected.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "five four-week occasions per season, the authors' dynamic co-occurrence model", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "South Texas, USA; no coordinates deposited", temporalCoverage = "seasons not dated in the deposit (14 seasons)",
  notShipped = list(none = "every data object is shipped (decoded)"),
  notes = "The joint codes 1-8 are decoded with the deposit's state_code(): code c is row c of expand.grid over ocelot, bobcat, coyote. The underlying camera data are Lombardi et al., Dryad doi:10.5061/dryad.931zcrjgp (not built here).")
periods <- data.table(period = 1:14, period_season = 1:14)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/mackenzie_2021_stexas_mesocarniv_dynocc.R")
stage_dict_row(TABLE, description = "Camera detections of ocelot, bobcat and coyote at 28 South Texas sites over 14 seasons of five 4-week occasions.",
  url = "https://doi.org/10.5061/dryad.59zw3r26t", reference = "MacKenzie, D. I., Lombardi, J. V., & Tewes, M. E. (2021). Investigating cooccurrence patterns and dynamics for many imperfectly detected species, using a log-linear modelling parameterisation. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.7604", doi_data = "10.5061/dryad.59zw3r26t", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic co-occurrence, three mesocarnivores.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy (co-occurrence)",
  sampling_protocol = "camera_trap", design = "Multi-season (14 seasons x 5 occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Ocelot co-occurrence.")
