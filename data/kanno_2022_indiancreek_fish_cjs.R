#!/usr/bin/env Rscript
# Tables: kanno_2022_bluehead_chub_cjs, kanno_2022_creek_chub_cjs, kanno_2022_mottled_sculpin_cjs
#         (one deposit, three species of marked individuals: one table per taxon, ruling #20;
#         one script, as curveirasantos_2026_phinda_carniv_scr.R)
# Source: Dryad doi:10.5061/dryad.np5hqbzxh, version 204474 (published 2022-11-02), licence CC0 1.0
#         (as shown on Dryad). Kanno, Y., Kim, S. & Pregler, K. "Capture history data for:
#         Sub-seasonal correlation between growth and survival in three sympatric aquatic
#         ectotherms". The README asks users to contact Y. Kanno when the data are used (a request,
#         not a licence condition).
# Paper:  Kanno, Y., Kim, S. & Pregler, K. C. (2023). Sub-seasonal correlation between growth and
#         survival in three sympatric aquatic ectotherms. Oikos 2023: e09685. doi:10.1111/oik.09685
#         (the Dryad record's primary article; author order and volume from Crossref).
# Data:   CH_Dryad.csv: 2,021 rows, one per PIT-tagged fish: Obs_ID 1..2021, PIT_Tag_ID (mangled by
#         a spreadsheet into scientific notation: 4 distinct values for 2,021 fish, so not an id),
#         Spp_ID / Spp_Name (1 BHC bluehead chub Nocomis leptocephalus 429 fish; 2 CRC creek chub
#         Semotilus atromaculatus 664; 3 MTS mottled sculpin Cottus bairdii 928), and 15 columns
#         Nov_2015 .. Mar_2018 (1 captured, 0 not). Every fish has at least one capture.
#         Design (Dryad methods): a 740 m study reach of Indian Creek, South Carolina, sampled
#         every two months (mean 61 days, range 48-70) by two-pass backpack electrofishing of
#         20 m sections in an upstream direction, each occasion taking 1-10 days; fish >= 60 mm
#         (chubs) or >= 50 mm (sculpin) PIT-tagged, measured and released in their section.
#
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = "F<Obs_ID>" (one fish), taxon = NOCLEP / SEMATR / COTBAI, period = sampling occasion
#   1..15 (__periods: month and year of the bimonthly occasion; exact dates not deposited), no
#   occasion column (one capture occasion per period), y = captured.
#   Survey evidence: the deposited matrix; every fish carries all 15 occasions, including those
#   before its first capture (y = 0, standard E4; the authors' CJS conditions on first capture:
#   drop rows before the first y = 1 to reproduce it).
#   Not shipped: lengths (the paper's growth data are not in the deposit), PIT tag numbers
#   (destroyed in the deposit).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/kanno_2022_indiancreek_fish_cjs.R"
dir <- download_dryad("10.5061/dryad.np5hqbzxh", "kanno_2022_bluehead_chub_cjs")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
x <- fread(file.path(dir, "CH_Dryad.csv"), colClasses = list(character = "PIT_Tag_ID"))
occ_cols <- c("Nov_2015", "Jan_2016", "Mar_2016", "May_2016", "Jul_2016", "Sep_2016", "Nov_2016", "Jan_2017",
              "Mar_2017", "May_2017", "Jul_2017", "Sep_2017", "Nov_2017", "Jan_2018", "Mar_2018")
stopifnot(nrow(x) == 2021L, identical(names(x), c("Obs_ID", "PIT_Tag_ID", "Spp_ID", "Spp_Name", occ_cols)),
          identical(x$Obs_ID, 1:2021), uniqueN(x$PIT_Tag_ID) == 4L,
          identical(x[, .N, by = .(Spp_ID, Spp_Name)][order(Spp_ID)]$N, c(429L, 664L, 928L)),
          all(as.matrix(x[, ..occ_cols]) %in% 0:1), all(rowSums(as.matrix(x[, ..occ_cols])) > 0),
          sum(as.matrix(x[, ..occ_cols])) == 4163L)
periods <- data.table(period = 1:15, label = occ_cols,
                      month = match(substr(occ_cols, 1, 3), month.abb), year = as.integer(substr(occ_cols, 5, 8)))

spp <- data.table(code = c("BHC", "CRC", "MTS"), taxon = c("NOCLEP", "SEMATR", "COTBAI"),
                  sci = c("Nocomis leptocephalus", "Semotilus atromaculatus", "Cottus bairdii"),
                  vern = c("Bluehead chub", "Creek chub", "Mottled sculpin"),
                  table = c("kanno_2022_bluehead_chub_cjs", "kanno_2022_creek_chub_cjs", "kanno_2022_mottled_sculpin_cjs"),
                  minlen = c(60L, 60L, 50L))
for (i in seq_len(nrow(spp))) {
  s <- spp[i]; d <- x[Spp_Name == s$code]
  long <- melt(d[, c("Obs_ID", occ_cols), with = FALSE], id.vars = "Obs_ID", variable.name = "lab", value.name = "y")
  long[, period := match(as.character(lab), occ_cols)]
  long <- long[, .(unit = sprintf("F%04d", Obs_ID), taxon = s$taxon, y = as.integer(y), period)]
  long <- order_eco(long)
  stopifnot(nrow(long) == nrow(d) * 15L, sum(long$y) == sum(as.matrix(d[, ..occ_cols])), !anyDuplicated(long[, .(unit, period)]))
  per <- copy(periods)[, n_captured := long[, sum(y), by = period][order(period)]$V1]
  others <- setdiff(spp$table, s$table)
  cat(sprintf("  %s: %d fish, %d rows, %d captures\n", s$table, nrow(d), nrow(long), sum(long$y)))
  taxa <- make_taxa(s$taxon, s$sci, vernacularName = s$vern)
  dataset <- list(
    title = sprintf("%s capture histories, Indian Creek, South Carolina: PIT-tagged fish, 15 bimonthly electrofishing occasions, November 2015 - March 2018", s$vern),
    creator = "Kanno, Yoichiro; Kim, Seoghyun; Pregler, Kasey (Colorado State University)", pubDate = "2022",
    doi = "10.5061/dryad.np5hqbzxh", sourceURL = "https://doi.org/10.5061/dryad.np5hqbzxh",
    citation = "Kanno, Y., Kim, S. & Pregler, K. (2022). Capture history data for: Sub-seasonal correlation between growth and survival in three sympatric aquatic ectotherms [Dataset]. Dryad. https://doi.org/10.5061/dryad.np5hqbzxh",
    paperDOI = "10.1111/oik.09685",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Cormack-Jolly-Seber capture histories of %d PIT-tagged %s (%s, >= %d mm total length) in a 740 m reach of Indian Creek, South Carolina, sampled every two months by two-pass backpack electrofishing, November 2015 - March 2018 (15 occasions). One row per fish per occasion, y = captured; rows before first capture are 0. Sibling tables hold the other two species of the same survey.", nrow(d), tolower(s$vern), s$sci, s$minlen),
    samplingProtocol = "Every two months (mean 61 days, range 48-70) the 740 m reach, divided into 20 m sections, was sampled upstream by two-pass backpack electrofishing (Smith Root LR-24, Halltech HT-2000), each occasion taking 1-10 days; fish at or above the tagging length were PIT-tagged (8 mm), measured and returned to their section (Dryad methods; Kanno et al. 2023).",
    samplingProtocolCode = "electrofishing", surveyEvidence = "deposited_matrix",
    surveyEvidenceNote = "The deposited capture-history matrix has 15 occasion columns and every fish is surveyed at every occasion, including occasions before its first capture (y = 0).",
    responseType = "detection", unitKind = "individual",
    closure = "open between periods (bimonthly occasions; survival and emigration between occasions, CJS)",
    geographicCoverage = "Indian Creek, Sumter National Forest, South Carolina, USA (a 740 m study reach); no coordinates deposited",
    temporalCoverage = "2015-11/2018-03",
    coordinatesCoarsened = NA,
    components = as.list(others),
    notes = sprintf("One of three tables from one deposit (ruling #20: one table per taxon of marked individuals); the others are %s. Periods are the bimonthly occasions (month and year in __periods; occasion dates and the 1-10 day sampling windows are not deposited). Rows before first capture are 0: drop them to condition on first capture. PIT tag numbers are not usable (the deposit stores them in scientific notation); units are the deposit's Obs_ID.", paste(others, collapse = " and ")),
    notShipped = list(`PIT tag ids` = "PIT_Tag_ID is stored in scientific notation (4 distinct values for 2,021 fish); Obs_ID is the key",
                      `lengths` = "total lengths at capture used for the paper's growth models are not in the deposit",
                      `other species` = paste("in the sibling tables", paste(others, collapse = ", "))))
  ds <- write_table(long, s$table, dataset, taxa = taxa, periods = per, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("CJS capture histories of %d PIT-tagged %s (%s) in Indian Creek, South Carolina, 15 bimonthly two-pass electrofishing occasions Nov 2015 - Mar 2018; one of three species tables from one deposit.", nrow(d), tolower(s$vern), s$sci),
    url = "https://doi.org/10.5061/dryad.np5hqbzxh",
    reference = "Kanno, Y., Kim, S., & Pregler, K. C. (2023). Sub-seasonal correlation between growth and survival in three sympatric aquatic ectotherms. Oikos, 2023, e09685.",
    doi_paper = "10.1111/oik.09685", doi_data = "10.5061/dryad.np5hqbzxh",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = sprintf("Per-species table under ruling #20; siblings %s. Full 15-occasion rectangle incl. pre-capture zeros; PIT ids unusable in the deposit.", paste(others, collapse = ", ")),
    source_via = "Dryad")
  stage_tag_row(s$table, ds, taxon_group = "Fish", model_family = "CJS capture-recapture",
    sampling_protocol = "electrofishing", design = "Multi-session (15 bimonthly occasions)", realm = "Freshwater",
    country = "USA", coordinates = "None in source", notes = "Individuals as unit; one species of a three-species deposit; pre-capture zeros kept.")
}
