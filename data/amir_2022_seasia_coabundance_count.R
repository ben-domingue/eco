#!/usr/bin/env Rscript
# Table:  amir_2022_seasia_coabundance_count
# Source: Dryad doi:10.5061/dryad.b8gtht7h3 (CC0 1.0, as shown on the Dryad page; published
#         2022-12-20). Amir, Z., Sovie, A. & Luskin, M.S. Inferring predator-prey interactions from
#         camera traps: A Bayesian co-abundance modeling approach.
# Paper:  Amir, Z., Sovie, A. & Luskin, M.S. (2022). Ecology and Evolution 12(12),
#         doi:10.1002/ece3.9627. Twenty systematic camera-trap sessions in ten Southeast Asian
#         primary-forest landscapes; detections aggregated to 3-km cells ("sampling units", SU) and
#         5-day occasions ("Used a 5 day shrink", the authors' script), analysed with a
#         co-abundance N-mixture model.
# Data:   fetched per file (the deposit's 8 GB tutorial zip and fitted-model RData were not
#         downloaded): 1_Panthera_tigris_, 4_Neofelis_nebulosa_, 7_Rusa_unicolor_,
#         8_Muntiacus_muntjak_count_matrix_final_20211006.csv (SU x occasions 1-40, counts, NA =
#         not sampled); ECL_meta_3km_res_co-abundance_20220131.csv (shrink_id = SU, survey_id,
#         landscape, Cell_Effort, forest_integrity, human_foot); Final_Co-Abundance_model_20221201.R.
# Mapping (standard: repeated counts, community, E9 core): unit = SU (cell x survey); taxon =
#   PANTIG / NEONEB / RUSUNI / MUNMUN; occasion = 5-day occasion 1-40; y = the deposited count
#   (the count history the authors fit; the defining README is inside the zip). The three prey and
#   clouded leopard files share 416 SUs and one NA pattern (asserted); the tiger file omits the 18
#   Bornean SUs (Lambir, Danum: outside the tiger's range) and otherwise has the same NA pattern
#   (asserted), so __survey_taxa lists tiger only at the 398 SUs in its file. unit_: survey,
#   landscape, cell effort (camera-nights), forest integrity and human footprint. Survey evidence:
#   deposited_matrix. Tiger (EN), clouded leopard and sambar (VU): the deposit has no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "amir_2022_seasia_coabundance_count"
dir <- download_dryad("10.5061/dryad.b8gtht7h3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, n, recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f, header = TRUE) }
SP <- c(PANTIG = "^1_Panthera_tigris_count_matrix_final_20211006\\.csv$", NEONEB = "^4_Neofelis_nebulosa_count_matrix_final_20211006\\.csv$",
        RUSUNI = "^7_Rusa_unicolor_count_matrix_final_20211006\\.csv$", MUNMUN = "^8_Muntiacus_muntjak_count_matrix_final_20211006\\.csv$")
D <- lapply(SP, rf); O <- as.character(1:40)
stopifnot(all(sapply(D, function(x) identical(names(x), c("SU", O)))))
ref <- D$RUSUNI; RN <- is.na(as.matrix(ref[, ..O]))
for (k in c("NEONEB", "MUNMUN")) stopifnot(identical(D[[k]]$SU, ref$SU), identical(is.na(as.matrix(D[[k]][, ..O])), RN))
stopifnot(nrow(ref) == 416, nrow(D$PANTIG) == 398, all(D$PANTIG$SU %in% ref$SU), all(grepl("Lambir|Danum", setdiff(ref$SU, D$PANTIG$SU))),
          identical(is.na(as.matrix(D$PANTIG[, ..O])), RN[match(D$PANTIG$SU, ref$SU), ]))
m <- rf("^ECL_meta_3km_res_co-abundance_20220131\\.csv$"); stopifnot(all(ref$SU %in% m$shrink_id), !anyDuplicated(m$shrink_id))
long <- rbindlist(lapply(names(SP), function(k) {
  x <- melt(D[[k]], id.vars = "SU", variable.name = "occasion", value.name = "y", variable.factor = FALSE)[!is.na(y)]
  x[, .(unit = SU, taxon = k, occasion = as.integer(occasion), y = as.integer(y))]
}))
stopifnot(all(long$y >= 0))
mm <- m[match(long$unit, shrink_id)]
long[, `:=`(unit_survey = mm$survey_id, unit_landscape = mm$landscape, unit_cell_effort = mm$Cell_Effort,
            unit_forest_integrity = mm$forest_integrity, unit_human_footprint = mm$human_foot)]
long <- order_eco(long)
stopifnot(nrow(long) == 3 * sum(!RN) + sum(!is.na(as.matrix(D$PANTIG[, ..O]))))
survey_taxa <- unique(long[, .(taxon, unit)])
taxa <- make_taxa(names(SP), c("Panthera tigris", "Neofelis nebulosa", "Rusa unicolor", "Muntiacus muntjak"),
                  vernacularName = c("Tiger", "Clouded leopard", "Sambar", "Red muntjac"))
dataset <- list(
  title = "Camera-trap counts of tiger, clouded leopard, sambar and red muntjac in 416 3-km cells across Southeast Asian forests, 5-day occasions",
  creator = "Amir, Zachary; Sovie, Adia; Luskin, Matthew S.", pubDate = "2022", doi = "10.5061/dryad.b8gtht7h3", sourceURL = "https://doi.org/10.5061/dryad.b8gtht7h3",
  citation = "Amir, Z., Sovie, A., & Luskin, M. S. (2022). Inferring predator-prey interactions from camera traps: A Bayesian co-abundance modeling approach [Dataset]. Dryad. https://doi.org/10.5061/dryad.b8gtht7h3",
  paperDOI = "10.1002/ece3.9627",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Count histories of two predators (tiger, clouded leopard) and two prey (sambar, red muntjac) on up to forty 5-day occasions in 3-km cells of 23 camera-trap surveys across ten primary-forest landscapes in Sumatra, Peninsular Malaysia, Thailand, Singapore and Borneo, with camera-nights, forest integrity and human footprint per cell.",
  samplingProtocol = "Systematic camera-trap sessions; detections aggregated by the authors to 3-km cells and 5-day occasions as count histories for co-abundance N-mixture models.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "one session per cell (up to 200 days), as the authors' N-mixture model assumes", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Southeast Asia (Sumatra, Peninsular Malaysia, southern Thailand, Singapore, Borneo); no coordinates deposited",
  temporalCoverage = "dates not deposited (survey names carry years 2013-2019)",
  notShipped = list(zip = "the 8 GB tutorial zip (code, the same CSVs, fitted models) and the fitted-model RData files: not downloaded"),
  notes = "Counts are the deposited count histories per 5-day occasion; their exact definition (independent detections) is in the README inside the tutorial zip. Tiger has no rows in the 18 Bornean cells (outside its range; __survey_taxa).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, survey_taxa = survey_taxa, script = "data/amir_2022_seasia_coabundance_count.R")
stage_dict_row(TABLE, description = "Camera-trap count histories of tiger, clouded leopard, sambar and red muntjac in 416 3-km cells across Southeast Asian forests.",
  url = "https://doi.org/10.5061/dryad.b8gtht7h3", reference = "Amir, Z., Sovie, A., & Luskin, M. S. (2022). Inferring predator-prey interactions from camera traps: A Bayesian co-abundance modeling approach. Ecology and Evolution, 12(12).",
  doi_paper = "10.1002/ece3.9627", doi_data = "10.5061/dryad.b8gtht7h3", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Co-abundance count histories.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community N-mixture (repeated counts)",
  sampling_protocol = "camera_trap", design = "Single-season (up to 40 five-day occasions)", realm = "Terrestrial",
  country = "IDN; MYS; THA; SGP", coordinates = "None in source", notes = "Predator-prey co-abundance.")
