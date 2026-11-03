#!/usr/bin/env Rscript
# Table:  hinneberg_2022_limenitis_ccr
# Source: Dryad doi:10.5061/dryad.s7h44j195 (CC0 1.0 as shown on the dataset JSON), version
#   186482 (published 2022-07-07). Hinneberg, H., Döring, J., Hermann, G., Markl, G., Theobald, J.,
#   Aust, I., Bamann, T., Bertscheit, R., Budach, D., Niedermayer, J., Rissi, A. & Gottschalk, T.
#   Multi-surveyor capture-mark-recapture as a powerful tool for butterfly population monitoring
#   in the pre-imaginal stage. (The analysis scripts are on Zenodo, doi:10.5281/zenodo.6805804;
#   not needed here.)
# Paper:  Hinneberg, H., et al. (2022). Ecology and Evolution 12: e9140, doi:10.1002/ece3.9140
#   (open access, CC BY 4.0; read via Europe PMC PMC9339765).
# Data:   Hinneberg_et_al_2022_Multi_Surveyor_CMR_datafiles.xlsx, five sheets:
#           RMark_Input: 75 hibernacula (ID, species = reducta / camilla / empty, S1..S13, plot
#             A/B/C). 1 = found by that surveyor, 0 = searched the plot and missed it, "." = that
#             surveyor did not search that plot. The "." pattern is constant within plot x
#             surveyor (asserted): plots A, B, C searched by 10, 9 and 10 surveyors, as the paper
#             says. Surveyor S13 searched plot B and found nothing (all 0, kept).
#           CH_plotA/B/C: the same histories split by plot with the "." columns dropped (inputs
#             to the authors' removal analysis); asserted identical to RMark_Input.
#           detections_per_hibernaculum: realized and possible detections per row (row sums of
#             RMark_Input; asserted).
#         ..._resultsfile.xlsx: reduced-effort population estimates (model output).
#         ..._surveyor_experience.xlsx: surveyor id -> expert / novice (6 / 7).
#         README_...txt. Data collected 2021-02-05 to 2021-03-21 (paper: to 2021-03-22) on a
#         spruce clear-cut near Merklingen, Swabian Jura, Germany (48.494 N, 9.788 E).
#
# Mapping (closed-population capture-recapture; standard design_landscape row "closed CR"):
#   unit = hibernaculum (ID), cluster_id = plot (A 916 m2, B 807 m2, C 2952 m2, from the paper),
#   occasion = surveyor number (1..13), observer = surveyor id (S1..S13), one period.
#   y = 1 if that surveyor found the hibernaculum. Survey evidence: deposited_matrix ("." vs 0).
#   The occasion is a surveyor, not a time: the 9-10 surveyors of a plot searched one after the
#   other over six weeks, independently and without seeing the others' marks, and the first
#   author (S1) was always first; the order of the others is not deposited, so occasion order
#   beyond S1 carries no time information (closure says so). The paper fits Huggins closed
#   models with p = c and surveyor-specific p (Mt) or experience-dependent p.
#   Taxon: the marked "individual" is a Limenitis hibernaculum, and the paper's population is
#   all 75 of them (39 L. reducta, 2 L. camilla, 34 empty: the larva died or was predated
#   between hibernation and the survey). The contents were determined after all searches
#   ended, so they are a property of the unit, not of the search: one taxon at genus rank
#   (LIMENI, Limenitis) and unit_contents = reducta / camilla / empty. Splitting by species
#   (ruling #20 would require one table per taxon) would drop the 34 empty hibernacula,
#   which the paper counts as part of the closed population and whose detectability is the
#   same object. A user wanting L. reducta larvae filters unit_contents.
#   obs_experience = surveyor's experience level (expert / novice), constant per surveyor.
#   unit_plot_area_m2 from the paper.
#   Closure: three hibernacula disappeared during the six weeks and were removed by the
#   authors before deposit (paper, 2.2), so the deposited 75 meet closure by construction.
#   Coordinates: no per-hibernaculum GPS positions are deposited; the paper gives one site
#   coordinate. The source calls L. reducta "highly endangered" (German Red List), so the
#   site position in geographicCoverage is given to 0.1 degree only (E7, source-flagged).
#   Not shipped: the results workbook (reduced-effort CMR estimates, model output);
#   detections_per_hibernaculum and CH_plot* (derived from / duplicates of RMark_Input).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "hinneberg_2022_limenitis_ccr"
dir <- download_dryad("10.5061/dryad.s7h44j195", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fd <- file.path(dir, "Hinneberg_et_al_2022_Multi_Surveyor_CMR_datafiles.xlsx")
fe <- file.path(dir, "Hinneberg_et_al_2022_Multi_Surveyor_CMR_surveyor_experience.xlsx")
stopifnot(file.exists(fd), file.exists(fe))
stopifnot(identical(excel_sheets(fd), c("RMark_Input", "CH_plotA", "CH_plotB", "CH_plotC", "detections_per_hibernaculum")))

S <- paste0("S", 1:13)
x <- as.data.table(read_excel(fd, "RMark_Input", col_types = "text"))
stopifnot(identical(names(x), c("ID", "species", S, "plot")), nrow(x) == 75L, !anyDuplicated(x$ID))
stopifnot(all(unlist(x[, ..S]) %in% c("0", "1", ".")))
stopifnot(identical(as.vector(table(x$species, x$plot)), c(2L, 16L, 13L, 0L, 7L, 10L, 0L, 11L, 16L)))  # camilla/empty/reducta x A/B/C
# "." is constant within plot x surveyor: a surveyor searched a whole plot or none of it
dotpat <- x[, lapply(.SD, function(v) { u <- unique(v == "."); stopifnot(length(u) == 1L); u }), by = plot, .SDcols = S]
setorder(dotpat, plot)
searched <- melt(dotpat, id.vars = "plot", variable.name = "surveyor", value.name = "dot")[dot == FALSE]
stopifnot(identical(searched[, .N, keyby = plot]$N, c(10L, 9L, 10L)))
# the per-plot sheets and the detection counts agree with RMark_Input
for (p in c("A", "B", "C")) {
  ch <- as.data.table(read_excel(fd, paste0("CH_plot", p), col_types = "text"))
  cols <- searched[plot == p, as.character(surveyor)]
  stopifnot(identical(names(ch), c("ID", "species", cols)), setequal(ch$ID, x[plot == p, ID]))
  m <- merge(ch, x[, c("ID", cols), with = FALSE], by = "ID")
  for (cc in cols) stopifnot(identical(m[[paste0(cc, ".x")]], m[[paste0(cc, ".y")]]))
}
dph <- as.data.table(read_excel(fd, "detections_per_hibernaculum"))
stopifnot(nrow(dph) == 75L, all(dph$realized_detections == rowSums(x[, ..S] == "1")),
          all(dph$possible_detections == rowSums(x[, ..S] != ".")))
ex <- as.data.table(read_excel(fe))
setnames(ex, c("surveyor", "experience"))
stopifnot(identical(ex$surveyor, S), sum(ex$experience == "expert") == 6L, sum(ex$experience == "novice") == 7L)

long <- melt(x, id.vars = c("ID", "species", "plot"), measure.vars = S, variable.name = "surveyor", value.name = "v")
long <- long[v != "."]
long[, surveyor := as.character(surveyor)]
area <- c(A = 916L, B = 807L, C = 2952L)
long <- long[, .(unit = ID, taxon = "LIMENI", y = as.integer(v), occasion = as.integer(sub("^S", "", surveyor)),
                 observer = surveyor, cluster_id = plot, unit_contents = species,
                 unit_plot_area_m2 = area[plot], obs_experience = ex$experience[match(surveyor, ex$surveyor)])]
stopifnot(nrow(long) == 31L * 10L + 17L * 9L + 27L * 10L, sum(long$y) == sum(dph$realized_detections),
          all(long[, sum(y), by = unit]$V1 >= 1L))
cat(sprintf("  %d hibernacula x surveyors-of-their-plot = %d rows, %d detections\n", uniqueN(long$unit), nrow(long), sum(long$y)))

taxa <- make_taxa("LIMENI", "Limenitis", vernacularName = "Admirals (hibernacula of L. reducta and L. camilla)", taxonRank = "genus")

site <- coarsen_coords(48.494, 9.788)
dataset <- list(
  title = "Multi-surveyor closed capture-recapture of hibernating Limenitis larvae (75 hibernacula, 13 surveyors), Swabian Jura, Germany, 2021",
  creator = "Hinneberg, Heiko; Döring, Jörg; Hermann, Gabriel; Markl, Gregor; Theobald, Jennifer; Aust, Ines; Bamann, Thomas; Bertscheit, Ralf; Budach, Daniela; Niedermayer, Jana; Rissi, Alicia; Gottschalk, Thomas",
  pubDate = "2022", doi = "10.5061/dryad.s7h44j195", sourceURL = "https://doi.org/10.5061/dryad.s7h44j195",
  citation = "Hinneberg, H., Döring, J., Hermann, G., Markl, G., Theobald, J., Aust, I., Bamann, T., Bertscheit, R., Budach, D., Niedermayer, J., Rissi, A., & Gottschalk, T. (2022). Multi-surveyor capture-mark-recapture as a powerful tool for butterfly population monitoring in the pre-imaginal stage [Dataset]. Dryad. https://doi.org/10.5061/dryad.s7h44j195",
  paperDOI = "10.1002/ece3.9140",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Thirteen surveyors (6 experts, 7 novices) independently searched three plots of a spruce clear-cut for the winter hibernacula of Southern White Admiral (Limenitis reducta) larvae, one after the other, February-March 2021; each plot was searched by 9-10 of them. Each of the 75 hibernacula found by anyone has a detection history over the surveyors who searched its plot. Surveyors replace capture occasions: the paper fits Huggins closed-population models with surveyor-specific or experience-specific detection.",
  samplingProtocol = "Independent visual search of a marked plot for larval hibernacula on Lonicera xylosteum, at most 2 h per surveyor per plot; each find marked with tape, recorded by GPS and photograph by the first author, tape removed before the next surveyor; finds matched across surveyors after the last search; hibernacula contents (L. reducta, L. camilla, empty) identified afterwards.",
  samplingProtocolCode = "multi_observer_search", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual",
  closure = "one closed period; occasions are surveyors, not times. Surveyors searched one after the other over six weeks without information about earlier finds; S1 (the first author) was always first, the order of the others is not deposited. Three hibernacula that disappeared during the study were removed by the authors before deposit.",
  geographicCoverage = sprintf("Spruce clear-cut near Merklingen, Alb-Donau district, Baden-Württemberg, Germany; site centre %.2f N, %.2f E (0.1-degree cell); three plots of 916, 807 and 2952 m2", site$lat, site$lon),
  temporalCoverage = "2021-02-05/2021-03-22",
  coordinatesCoarsened = list(value = TRUE, method = "Only a site coordinate exists (the paper's 48.494 N, 9.788 E); given in geographicCoverage as the centre of its 0.1-degree cell because the source calls L. reducta highly endangered. No per-hibernaculum positions are deposited."),
  notShipped = list(resultsfile = "reduced-effort population estimates, SEs and confidence limits per surveyor subset (model output)",
                    detections_per_hibernaculum = "realized and possible detections per hibernaculum (row sums of the histories; asserted equal)",
                    CH_plotA_B_C = "the same histories split by plot (inputs to the authors' removal analysis; asserted identical)"),
  notes = "One taxon at genus rank because the closed population is the set of hibernacula, whose contents were determined after the searches: unit_contents is reducta (39), camilla (2) or empty (34). Filter unit_contents == 'reducta' for L. reducta larvae alive at the end of the survey. occasion = surveyor number; use observer and obs_experience for Mt / experience models. cluster_id = plot; the paper estimates N per plot with plot as a group. 75 units: above the unit floor but a small population; the value of the table is the design.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hinneberg_2022_limenitis_ccr.R")

stage_dict_row(TABLE,
  description = "Closed capture-recapture of 75 hibernacula of Limenitis larvae (L. reducta, L. camilla, and empty) in three plots of a clear-cut in the Swabian Jura, Germany, February-March 2021, with 13 independent surveyors (6 expert, 7 novice) as occasions; surveyor experience and hibernaculum contents as covariates.",
  url = "https://doi.org/10.5061/dryad.s7h44j195",
  reference = "Hinneberg, H., Döring, J., Hermann, G., Markl, G., Theobald, J., Aust, I., Bamann, T., Bertscheit, R., Budach, D., Niedermayer, J., Rissi, A., & Gottschalk, T. (2022). Multi-surveyor capture-mark-recapture as a powerful tool for butterfly population monitoring in the pre-imaginal stage. Ecology and Evolution, 12, e9140.",
  doi_paper = "10.1002/ece3.9140", doi_data = "10.5061/dryad.s7h44j195",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First closed-population CR table: occasions are surveyors (order unknown beyond the first). Genus-level taxon with contents as a unit covariate. Model estimates not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Closed-population capture-recapture (Huggins; surveyors as occasions)",
  sampling_protocol = "multi_observer_search", design = "Single-season (one closed session; 9-10 independent surveyors per plot, 3 plots)",
  realm = "Terrestrial", country = "DEU", coordinates = "Coarsened (0.1 deg) (one site coordinate in metadata, none per hibernaculum)",
  notes = "Pre-imaginal butterfly stage; detection varies by surveyor experience (paper: 16% novice, 35% expert).")
