#!/usr/bin/env Rscript
# Tables: chambert_2018_pigfrog_acoustic_count, chambert_2018_treefrog_acoustic_count
# Source: Dryad doi:10.5061/dryad.949nc (CC0 1.0, as shown on the Dryad page; published
#         2018-10-18). Chambert, T., Waddle, J.H., Miller, D.A.W., Walls, S.C. & Nichols, J.D.
#         Data from: A new framework for analysing automated acoustic species detection data:
#         occupancy estimation and optimization of recordings post-processing.
# Paper:  Chambert, T. et al. (2018). Methods in Ecology and Evolution 9(3), 560-570,
#         doi:10.1111/2041-210X.12910. Acoustic recorders at sites surveyed for frogs; an
#         automated classifier's detections, a subset validated by a human; occupancy with false
#         positives using counts of detections (abstract).
# Data:   Data S1 - Pig Frog.txt and Data S2 - Green Treefrog.txt, each three whitespace blocks
#         of 60 sites x occasions (8 for pig frog, 6 for green treefrog): "All detections",
#         "All True Detections (true positives)", "All False Positives" (counts of automated
#         detections per site-occasion; all = true + false, asserted). No site ids, dates or
#         locations are deposited; Appendix S1/S2 are model and simulation code.
# Mapping (standard: repeated counts, E9 core; one table per species, as the two have different
#   occasion counts): unit = site row S01-S60 (deposited order); occasion = 1..T; y = all
#   automated detections; obs_true_positives and obs_false_positives = the validated split.
#   Survey evidence: deposited_matrix (complete). y counts classifier detections (calls), not
#   individuals.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/chambert_2018_frogs_acoustic_count.R"
dir <- download_dryad("10.5061/dryad.949nc", "chambert_2018_frogs_acoustic_count")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
readblocks <- function(pat) {
  f <- list.files(dir, pat, recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
  L <- readLines(f, warn = FALSE); h <- grep("^##", L); stopifnot(length(h) == 3)
  lapply(seq_along(h), function(i) { r <- L[(h[i] + 1):(if (i < 3) h[i + 1] - 1 else length(L))]; r <- r[nzchar(trimws(r))]
    do.call(rbind, lapply(strsplit(trimws(r), "\\s+"), as.integer)) })
}
SP <- list(list(pat = "^Data S1 - Pig Frog\\.txt$", table = "chambert_2018_pigfrog_acoustic_count", code = "LITGRY", sci = "Lithobates grylio", vern = "Pig frog", T = 8L, tot = 1595L),
           list(pat = "^Data S2 - Green Treefrog\\.txt$", table = "chambert_2018_treefrog_acoustic_count", code = "HYLCIN", sci = "Hyla cinerea", vern = "Green treefrog", T = 6L, tot = 20705L))
for (S in SP) {
  b <- readblocks(S$pat); A <- b[[1]]; TP <- b[[2]]; FP <- b[[3]]
  stopifnot(all(sapply(b, function(m) identical(dim(m), c(60L, S$T)))), all(A == TP + FP), sum(A) == S$tot, all(A >= 0))
  ids <- sprintf("S%02d", 1:60); dimnames(A) <- list(ids, NULL)
  long <- order_eco(array_to_eco(A, taxon = S$code, site_ids = ids, obs_covs = list(true_positives = TP, false_positives = FP)))
  stopifnot(nrow(long) == 60 * S$T)
  taxa <- make_taxa(S$code, S$sci, vernacularName = S$vern)
  dataset <- list(
    title = sprintf("Automated acoustic detections of the %s at 60 sites, %d occasions, with the validated split into true and false positives", tolower(S$vern), S$T),
    creator = "Chambert, Thierry; Waddle, J. Hardin; Miller, David A. W.; Walls, Susan C.; Nichols, James D.", pubDate = "2018",
    doi = "10.5061/dryad.949nc", sourceURL = "https://doi.org/10.5061/dryad.949nc",
    citation = "Chambert, T., Waddle, J. H., Miller, D. A. W., Walls, S. C., & Nichols, J. D. (2018). Data from: A new framework for analysing automated acoustic species detection data: occupancy estimation and optimization of recordings post-processing [Dataset]. Dryad. https://doi.org/10.5061/dryad.949nc",
    paperDOI = "10.1111/2041-210X.12910",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Counts of automated classifier detections of %s (%s) calls on acoustic recorders at 60 sites over %d occasions, with each count split by human post-validation into true and false positives: the data for occupancy models with false positives that use the number of detections.", tolower(S$vern), S$sci, S$T),
    samplingProtocol = "Autonomous acoustic recorders at wetland sites; recordings processed by an automated species classifier and the detections post-validated by a human observer; counts per site and occasion.",
    samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix", responseType = "count", unitKind = "site",
    closure = "closed", closureNote = "occasions within one season; the authors' single-season occupancy with false positives", occasionKind = "time",
    taxonInclusion = "single", geographicCoverage = "Wetland sites of the USGS amphibian monitoring program, south-eastern USA (see the paper); no locations deposited",
    temporalCoverage = "survey dates not stated in the deposit (paper 2018)",
    notShipped = list(code = "model and simulation code (Appendix S1, S2)"),
    notes = "Site ids S01-S60 follow the deposited row order; the deposit has no site names, dates or locations. y counts calls detected by the classifier, not individuals.")
  ds <- write_table(long, S$table, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(S$table, description = sprintf("Automated acoustic detection counts of the %s at 60 sites x %d occasions, with validated true / false positives.", tolower(S$vern), S$T),
    url = "https://doi.org/10.5061/dryad.949nc", reference = "Chambert, T. et al. (2018). A new framework for analysing automated acoustic species detection data. Methods in Ecology and Evolution, 9(3), 560-570.",
    doi_paper = "10.1111/2041-210X.12910", doi_data = "10.5061/dryad.949nc", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Counts of classifier detections with false-positive validation.", source_via = "Dryad")
  stage_tag_row(S$table, ds, taxon_group = "Amphibians", model_family = "Occupancy with false positives (detection counts)",
    sampling_protocol = "acoustic", design = sprintf("Single-season (%d occasions)", S$T), realm = "Freshwater",
    country = "USA", coordinates = "None in source", notes = "Automated acoustic classifier; validated subsets.")
}
