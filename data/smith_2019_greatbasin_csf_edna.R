#!/usr/bin/env Rscript
# Tables: smith_2019_greatbasin_csf_edna  (watershed > site > filter sample; sample-level
#                                           eDNA detection with covariates; the paper's
#                                           multi-scale dataset)
#         smith_2019_greatbasin_csf_qpcr  (site > filter sample > qPCR replicate, with the
#                                           visual/dipnet confirmation; the paper's
#                                           false-positive dataset)
#         One script, two tables: the deposit gives the same 168 sites at two nesting
#         levels in two files with no key to join them (see below).
# Source: Dryad doi:10.5061/dryad.bk3j9kd6q (CC0 1.0), version 2 (2019-12-04)
#   Smith, M. M. & Goldberg, C. S. (2019). Occupancy in dynamic systems: accounting for
#   multiple scales and false positives using environmental DNA to inform monitoring. Dryad.
# Paper:  Smith, M. M. & Goldberg, C. S. (2020). Ecography 43(3), 376-386.
#         doi:10.1111/ecog.04743 (CC BY; read from queue/papers/).
# Data:   no readme. Smith_Goldberg_MARK_input.csv: 61 rows = watersheds (the multi-scale
#         units of Program MARK), rep1..rep24 = up to 8 sites x 3 filter samples (0/1
#         sample-level eDNA detection, "." = no such site), X = MARK group/frequency (all 1),
#         watershed covariates ppt_mean, temp_mean, streams (perennial stream length), slope,
#         and per-site slots 1..8 of wt (water temperature C), pH, em_veg (emergent
#         vegetation class 1-4), live (livestock impact class 1-4), ppt, temp, elev, and
#         water-type indicators pond, stream, bpond (0/1). Smith_Goldberg_fp_occu_input.csv:
#         504 rows = 168 sites x 3 filter samples ("<site>_<sample>"), visual (0 or 2:
#         unmarked occuFP coding, 2 = certain detection by the visual/dipnet survey, constant
#         within site) and CSF_rep1..3 (qPCR replicates, 0/1). The .inp/.txt files are MARK
#         copies of the same data (final_dcomp*: the 30 false-positive resamples of the paper).
#         Site identities, coordinates and the survey year of each site are not deposited.
#         Paper: 220 sites surveyed May-August 2015 (areas A, B, C, G) and 2016 (B, D, E, F);
#         three temporally replicated 250 ml filter samples per site, each run in triplicate
#         qPCR; 61 watersheds with 2-8 sites (168 sites) in the multi-scale analysis.
#
# Mapping (standard E1-E5, E9 experimental: multi-scale occupancy / eDNA):
#   _edna: cluster_id = watershed W01..W61, unit = site W01_1.., occasion = filter sample
#          1..3, y = 0/1 sample-level eDNA detection (any of three qPCR replicates). unit_:
#          site covariates and the watershed covariates (constant within a site), as deposited.
#   _qpcr: cluster_id = site S001..S168, unit = filter sample S001_1.., occasion = qPCR
#          replicate 1..3, y = 0/1 amplification; unit_visual_dipnet_detected = 1 where the
#          site-level visual/dipnet survey detected the frog (deposited code 2), 0 otherwise.
#          The confirmation survey is an observation of the same species by another method,
#          carried as a covariate because it sits at a different level (site) from the rows
#          (qPCR replicate); declared in detectionCertainty (E9 false-positive form 1, #23).
#   Survey evidence = deposited_matrix for both (the matrices code not-surveyed as "." and
#   non-detection as 0; the qPCR file is rectangular).
#   NOT shipped: the MARK .inp copies; the 30 false-positive resamples (final_dcomp*,
#   derived data); the join between the two files (not deposited; the two tables describe
#   the same 168 sites but cannot be linked).
#   v1.1: closure = closed, occasionKind = spatial (filter samples; qPCR replicates),
#   taxonInclusion = single, for both tables.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/smith_2019_greatbasin_csf_edna.R"
CACHE <- "smith_2019_greatbasin_csf_edna"
dir <- download_dryad("10.5061/dryad.bk3j9kd6q", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
TAXON <- "RANLUT"; SCI <- "Rana luteiventris"; VERN <- "Columbia spotted frog (Great Basin clade)"
taxa <- make_taxa(TAXON, SCI, vernacularName = VERN)
common <- list(
  creator = "Smith, Matthew M.; Goldberg, Caren S.", pubDate = "2019", doi = "10.5061/dryad.bk3j9kd6q",
  sourceURL = "https://doi.org/10.5061/dryad.bk3j9kd6q", paperDOI = "10.1111/ecog.04743",
  citation = "Smith, M. M., & Goldberg, C. S. (2019). Occupancy in dynamic systems: accounting for multiple scales and false positives using environmental DNA to inform monitoring [Data set]. Dryad. https://doi.org/10.5061/dryad.bk3j9kd6q",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  geographicCoverage = "Great Basin range of the Columbia spotted frog: southeastern Oregon, southwestern Idaho and Nevada, USA (no coordinates deposited)",
  temporalCoverage = "2015-05/2016-08")

# ---- table 1: watershed > site > filter sample ---------------------------------------
mk <- fread(file.path(dir, "Smith_Goldberg_MARK_input.csv"), na.strings = ".", colClasses = "character")
if (names(mk)[ncol(mk)] %in% c("", "V110")) mk[, (ncol(mk)) := NULL]      # trailing comma
stopifnot(nrow(mk) == 61, all(mk$X == "1"), identical(names(mk)[1:24], paste0("rep", 1:24)))
reps <- as.matrix(mk[, paste0("rep", 1:24), with = FALSE]); storage.mode(reps) <- "integer"
stopifnot(all(reps %in% c(0L, 1L, NA)))
n_site <- rowSums(!is.na(reps)) / 3
stopifnot(all(n_site == round(n_site)), all(n_site >= 2 & n_site <= 8), sum(n_site) == 168)
# a site's three samples are consecutive columns; a missing slot is missing for all three
stopifnot(all(sapply(seq_len(nrow(reps)), function(i) all(!is.na(reps[i, seq_len(3 * n_site[i])])))))
site_cov_names <- c(wt = "water_temp_c", pH = "ph", em_veg = "emergent_veg_class", live = "livestock_class",
                    ppt = "ppt", temp = "temp", elev = "elev", pond = "pond", stream = "stream", bpond = "bpond")
col_of <- function(stem, k) { nm <- c(paste0(stem, "_", k), paste0(stem, k)); nm[nm %in% names(mk)][1] }
ws_cov <- mk[, .(ws_ppt_mean = as.numeric(ppt_mean), ws_temp_mean = as.numeric(temp_mean),
                 ws_stream_length = as.numeric(streams), ws_slope = as.numeric(slope))]
rows <- rbindlist(lapply(seq_len(nrow(mk)), function(i) {
  rbindlist(lapply(seq_len(n_site[i]), function(k) {
    covs <- lapply(names(site_cov_names), function(stem) as.numeric(mk[[col_of(stem, k)]][i]))
    names(covs) <- paste0("unit_", site_cov_names)
    stopifnot(!anyNA(unlist(covs)))                        # site slots carry a full covariate set
    data.table(unit = sprintf("W%02d_%d", i, k), taxon = TAXON, y = reps[i, 3 * (k - 1) + 1:3], occasion = 1:3,
               cluster_id = sprintf("W%02d", i), as.data.table(covs),
               unit_ws_ppt_mean = ws_cov$ws_ppt_mean[i], unit_ws_temp_mean = ws_cov$ws_temp_mean[i],
               unit_ws_stream_length = ws_cov$ws_stream_length[i], unit_ws_slope = ws_cov$ws_slope[i])
  }))
}))
long1 <- order_eco(rows)
stopifnot(nrow(long1) == 168 * 3, uniqueN(long1$unit) == 168, uniqueN(long1$cluster_id) == 61,
          long1[, any(y == 1), by = unit][, sum(V1)] == 64)             # 64 eDNA-positive sites
T1 <- "smith_2019_greatbasin_csf_edna"
ds1 <- write_table(long1, T1, c(list(
  title = "Columbia spotted frog eDNA detection in three filter samples at 168 sites nested in 61 Great Basin watersheds, 2015-2016 (multi-scale occupancy dataset)",
  abstract = "Environmental DNA survey of the Great Basin clade of the Columbia spotted frog: three temporally replicated 250 ml filter samples at each wetland, pond or pooled-water site, each run in triplicate qPCR; a sample is a detection if any replicate amplified. Sites are nested in 12th-level hydrologic units (watersheds) with 2-8 sites each, the structure of the authors' Nichols et al. (2008) multi-scale occupancy model in Program MARK. Site covariates (water temperature, pH, emergent vegetation and livestock classes, climate, elevation, water type) and watershed covariates (mean precipitation and temperature, perennial stream length, slope) as deposited; definitions in the paper's Appendix 1 Table A2.",
  samplingProtocol = "eDNA: three 250 ml water samples filtered in succession at one location per site (pooled from 2-6 locations at 14 large sites), 0.45 um cellulose nitrate filters, species-specific qPCR in triplicate; sample-level detection = any replicate positive. Visual and dipnet surveys at the same sites are in the companion table smith_2019_greatbasin_csf_qpcr.",
  closure = "closed", closureNote = "occasion (three samples taken seconds apart)", occasionKind = "spatial", taxonInclusion = "single",
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = watershed is the coarse scale (psi), unit = site the fine scale (theta), occasion = filter sample (p). Watershed covariates are repeated on every site of the watershed with the unit_ws_ prefix. Which of the two field seasons a site belongs to is not deposited.",
  notShipped = list(MARK_inp_copies = "Smith_Goldberg_MARK.inp and final_dcomp*.inp/.txt are MARK copies and the 30 false-positive resamples (derived data)",
                    site_identity = "site names, coordinates and survey year are not in the deposit; the link to the qPCR-level file is not deposited")),
  common), taxa = taxa, script = SCRIPT)
stage_dict_row(T1,
  description = "Sample-level eDNA detection (0/1, any of three qPCR replicates) of the Columbia spotted frog in three filter samples at each of 168 sites nested in 61 Great Basin watersheds (Oregon, Idaho, Nevada), 2015-2016, with site and watershed covariates; the authors' multi-scale occupancy input. First eDNA / multi-scale table.",
  url = "https://doi.org/10.5061/dryad.bk3j9kd6q",
  reference = "Smith, M. M., & Goldberg, C. S. (2020). Occupancy in dynamic systems: accounting for multiple scales and false positives using environmental DNA to inform monitoring. Ecography, 43(3), 376-386.",
  doi_paper = "10.1111/ecog.04743", doi_data = "10.5061/dryad.bk3j9kd6q",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental (E9): cluster_id = watershed, unit = site, occasion = filter sample. No readme in the deposit; column meanings from the paper. Companion qPCR-level table from the same deposit cannot be joined to this one.",
  source_via = "Dryad (version zip)")
stage_tag_row(T1, ds1, taxon_group = "Amphibians", model_family = "Multi-scale occupancy (watershed > site > sample, eDNA)",
  sampling_protocol = "eDNA", design = "Single-season (two field seasons pooled by the authors; 3 filter samples per site)", realm = "Freshwater",
  country = "USA", coordinates = "None in source",
  notes = "Experimental (E9): multi-scale via cluster_id = watershed. Sample-level detection; qPCR replicates in the companion table.")

# ---- table 2: site > filter sample > qPCR replicate, with visual/dipnet confirmation --
fp <- fread(file.path(dir, "Smith_Goldberg_fp_occu_input.csv"), colClasses = "character", fill = TRUE)
fp <- fp[, 1:5]; setnames(fp, c("sample", "visual", "rep1", "rep2", "rep3"))
fp <- fp[nzchar(sample)]
stopifnot(nrow(fp) == 504, all(fp$visual %in% c("0", "2")), all(unlist(fp[, rep1:rep3]) %in% c("0", "1")))
fp[, c("site", "k") := tstrsplit(sample, "_", fixed = TRUE)]
stopifnot(uniqueN(fp$site) == 168, all(fp$k %in% c("1", "2", "3")), !anyDuplicated(fp[, .(site, k)]),
          fp[, uniqueN(visual) == 1, by = site][, all(V1)])          # visual is a site-level result
site_ids <- unique(fp$site); fp[, site_no := match(site, site_ids)]
long2 <- fp[, .(unit = sprintf("S%03d_%s", site_no, k), taxon = TAXON,
                y = c(as.integer(rep1), as.integer(rep2), as.integer(rep3)), occasion = rep(1:3, each = .N),
                cluster_id = sprintf("S%03d", site_no), unit_visual_dipnet_detected = as.integer(visual == "2"))]
long2 <- order_eco(long2)
stopifnot(nrow(long2) == 504 * 3, sum(long2$y) == 389, uniqueN(long2$cluster_id) == 168,
          long2[, any(y == 1), by = cluster_id][, sum(V1)] == 64, long2[, uniqueN(unit_visual_dipnet_detected), by = cluster_id][, all(V1 == 1)],
          long2[, sum(unit_visual_dipnet_detected > 0), by = cluster_id][, sum(V1 > 0)] == 31)
T2 <- "smith_2019_greatbasin_csf_qpcr"
ds2 <- write_table(long2, T2, c(list(
  title = "Columbia spotted frog eDNA qPCR replicate detections (3 per filter sample, 3 samples per site, 168 sites) with visual/dipnet confirmation, Great Basin, 2015-2016 (false-positive occupancy dataset)",
  abstract = "The qPCR-replicate level of the same Great Basin Columbia spotted frog eDNA survey: each of three filter samples per site was run in triplicate qPCR (1 = exponential amplification of the target, 0 = none). The site-level visual and dipnet survey, treated by the authors as an unambiguous detection method in the Miller et al. (2011) false-positive occupancy model (unmarked occuFP coding 2), is carried as the site covariate unit_visual_dipnet_detected. 31 of 168 sites had a visual/dipnet detection, 64 had at least one positive qPCR; the paper estimates a false-positive rate of 0.023 per qPCR replicate.",
  samplingProtocol = "Species-specific qPCR of eDNA filter samples in triplicate (3 ul extract in 15 ul, 50 cycles); visual survey of the whole site by two biologists followed by dipnetting along the shoreline about every 1 m.",
  closure = "closed", closureNote = "occasion (three qPCR replicates of one extract)", occasionKind = "spatial", taxonInclusion = "single",
  detectionCertainty = list(column = "unit_visual_dipnet_detected", method = "visual and dipnet survey of the whole site", level = "unit (site)",
                            note = "1 = the certain method detected the frog at the site (deposited occuFP code 2); qPCR rows are the ambiguous method"),
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = site, unit = filter sample, occasion = qPCR replicate. The visual/dipnet result is a second, certain detection method at the site level carried as a unit_ covariate (E9 false-positive form 1; ruling #23) because the rows are qPCR replicates.",
  notShipped = list(watershed = "the watershed of each site is only in the other deposited file, which cannot be joined to this one",
                    MARK_inp_copies = "MARK copies and the 30 false-positive resamples")),
  common), taxa = taxa, script = SCRIPT)
stage_dict_row(T2,
  description = "qPCR-replicate detections (0/1; 3 replicates x 3 filter samples) of Columbia spotted frog eDNA at 168 Great Basin sites, 2015-2016, with the site-level visual/dipnet confirmation as a covariate; the authors' false-positive occupancy input. Companion to smith_2019_greatbasin_csf_edna.",
  url = "https://doi.org/10.5061/dryad.bk3j9kd6q",
  reference = "Smith, M. M., & Goldberg, C. S. (2020). Occupancy in dynamic systems: accounting for multiple scales and false positives using environmental DNA to inform monitoring. Ecography, 43(3), 376-386.",
  doi_paper = "10.1111/ecog.04743", doi_data = "10.5061/dryad.bk3j9kd6q",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental (E9): cluster_id = site, unit = filter sample, occasion = qPCR replicate. Visual/dipnet confirmation (occuFP code 2) recoded to a 0/1 site covariate. No watershed key in this file.",
  source_via = "Dryad (version zip)")
stage_tag_row(T2, ds2, taxon_group = "Amphibians", model_family = "Multi-scale occupancy with false positives (site > sample > qPCR replicate, eDNA)",
  sampling_protocol = "eDNA", design = "Single-season (3 filter samples x 3 qPCR replicates per site)", realm = "Freshwater",
  country = "USA", coordinates = "None in source",
  notes = "Experimental (E9): multi-scale via cluster_id = site. Site-level visual/dipnet detection as covariate for false-positive models.")
