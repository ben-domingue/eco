#!/usr/bin/env Rscript
# Table:  banik_2025_dollyvarden_ms
# WITHDRAWN 2026-11-06 (care_review, #150). Removed from the current release pending
#   consultation with the originators; may be reinstated. Kept so it can be rebuilt; its
#   tag status is do_not_publish, so the uploader refuses it. Why, and how to reinstate:
#   notes/decisions/care_e7_screen_held.md and releases/withdrawals.csv.
# Source: Dryad doi:10.5061/dryad.bzkh189pw, version 397201 (published 2025-09-22), licence CC0 1.0
#         (as shown on Dryad). Banik, A., Gallagher, C., Howland, K., Lea, E., Dillon, F.,
#         McLeod, R., Muthukumarana, S. & Cowen, L. "Assessing the effects of changes in
#         reproductive condition on the survival of anadromous Dolly Varden (Salvelinus malma)
#         using Bayesian multistate capture-recapture modelling".
# Paper:  Banik, A. et al. (2025). Canadian Journal of Fisheries and Aquatic Sciences.
#         doi:10.1139/cjfas-2025-0047 (the Dryad record's primary article).
# Data:   Fisheries and Oceans Canada monitoring of anadromous Northern Dolly Varden (Salvelinus
#         malma malma) in five rivers of the western Canadian Arctic (Yukon and Northwest
#         Territories): Firth River and Joe Creek 2014-2020, Babbage River 2010-2020, Big Fish River
#         2009-2020, Rat River 2007-2020. Fish seined each fall, tagged, sexed where possible and
#         scored as spawner or non-spawner, and released. Per river, three deposited matrices
#         with one row per tagged fish (no fish id) and one column per fall (Fall_YYYY):
#         <River>_Capture_Data.csv (1 captured, 0 not), <River>_Breeding_Data.csv (1 captured as
#         a spawner, 2 captured as a non-spawner, 0 not captured) and <River>_Breeding_Sex_Data.csv
#         (the breeding matrix plus Sex: 1 male, 0 female, NA unknown). Firth 3,429 fish, Joe 3,112,
#         Babbage 5,088, Big Fish 5,156, Rat 4,645; every row has at least one capture.
#         Dolly_Varden_Codes.zip holds the authors' nimble model code (not shipped).
#
# Mapping (standard E9 multi-state capture-recapture, Arnason-Schwarz with reproductive state;
# responseType state, unitKind individual):
#   unit = "<river>_<row>" (row number in the river's deposited matrices; the deposit has no tag
#   ids), taxon = SALMAL, period = fall 2007..2020 (index 1..14; __periods), no occasion,
#   y = the breeding-matrix code: 0 not captured, 1 captured as a spawner, 2 captured as a
#   non-spawner (stateCodes). One table for the five rivers: same protocol and state coding;
#   unit_river says which population a fish belongs to; each fish has rows only for its river's
#   sampled falls.
#   Survey evidence: the deposited matrices (deposited_matrix). Every fall of a river's program
#   is a column of its matrix and therefore a survey of every fish of that river, including
#   falls before the fish's first capture (y = 0, standard E4; the authors condition on first
#   capture, drop those rows to reproduce their likelihood). Rat River falls 2008, 2011 and 2012
#   and Joe Creek fall 2020 have few captures (11, 18, 23, 74 fish against ~400-500 in other
#   years): reduced effort, kept, with per-river capture counts in __periods.
#   Covariates: unit_river, unit_sex (male / female / NA) from the breeding-sex matrices.
#   The capture-only matrices are the breeding matrices collapsed (y > 0) except in Rat River,
#   where 10 cells in 8 rows disagree (capture file one fall off the breeding file); the breeding
#   file, which the sex file matches cell for cell, is used.
#   Not shipped: the capture-only matrices (redundant: y > 0), the model code.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "banik_2025_dollyvarden_ms"
dir <- download_dryad("10.5061/dryad.bzkh189pw", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

rivers <- data.table(file = c("Firth", "Joe", "Babbage", "Big", "Rat"),
                     river = c("Firth River", "Joe Creek", "Babbage River", "Big Fish River", "Rat River"),
                     n = c(3429L, 3112L, 5088L, 5156L, 4645L), y0 = c(2014L, 2014L, 2010L, 2009L, 2007L))
n_mismatch <- 0L
long <- rbindlist(lapply(seq_len(nrow(rivers)), function(i) {
  r <- rivers[i]
  ca <- fread(file.path(dir, paste0(r$file, "_Capture_Data.csv")))
  br <- fread(file.path(dir, paste0(r$file, "_Breeding_Data.csv")))
  bs <- fread(file.path(dir, paste0(r$file, "_Breeding_Sex_Data.csv")))
  yrs <- as.integer(sub("Fall_", "", names(br)))
  stopifnot(nrow(br) == r$n, nrow(ca) == r$n, nrow(bs) == r$n, identical(names(ca), names(br)),
            identical(names(bs), c(names(br), "Sex")), identical(yrs, r$y0:2020L),
            all(as.matrix(br) %in% 0:2), all(bs$Sex %in% c(0L, 1L, NA)),
            all(as.matrix(br) == as.matrix(bs[, !"Sex"])),          # breeding = breeding-sex matrix
            all(rowSums(as.matrix(br)) > 0))                         # every fish captured at least once
  mm <- sum(as.matrix(ca) != (as.matrix(br) > 0))
  if (r$file == "Rat") stopifnot(mm == 10L) else stopifnot(mm == 0L)
  n_mismatch <<- n_mismatch + mm
  B <- as.matrix(br)
  data.table(unit = sprintf("%s_%04d", r$file, rep(seq_len(r$n), times = length(yrs))),
             year = rep(yrs, each = r$n), y = as.integer(B),
             unit_river = r$river, unit_sex = rep(c("female", "male")[bs$Sex + 1L], times = length(yrs)))
}))
long <- long[, .(unit, taxon = "SALMAL", y, period = year - 2006L, unit_river, unit_sex)]
long <- order_eco(long)
stopifnot(nrow(long) == sum(rivers$n * (2021L - rivers$y0)), uniqueN(long$unit) == sum(rivers$n),
          !anyDuplicated(long[, .(unit, period)]), n_mismatch == 10L)
cat(sprintf("  %d fish in 5 rivers, %d rows, %d spawner and %d non-spawner captures\n",
            uniqueN(long$unit), nrow(long), sum(long$y == 1L), sum(long$y == 2L)))

cnt <- dcast(long[y > 0, .N, by = .(period, unit_river)], period ~ unit_river, value.var = "N", fill = 0L)
setnames(cnt, setdiff(names(cnt), "period"), paste0("n_captured_", tolower(gsub(" ", "_", setdiff(names(cnt), "period")))))
periods <- merge(data.table(period = 1:14, year = 2007:2020), cnt, by = "period", all.x = TRUE)
for (c in grep("^n_captured_", names(periods), value = TRUE)) set(periods, which(is.na(periods[[c]])), c, 0L)
periods[, rivers_sampled := sapply(year, function(yy) paste(rivers[y0 <= yy, river], collapse = "; "))]

taxa <- make_taxa("SALMAL", "Salvelinus malma", vernacularName = "Dolly Varden (northern form, anadromous)")

dataset <- list(
  title = "Anadromous Dolly Varden multi-state (spawner / non-spawner) capture histories, five rivers of the western Canadian Arctic, falls 2007-2020",
  creator = "Banik, Arjun (University of Victoria); Gallagher, Colin; Howland, Kimberly; Lea, Ellen (Fisheries and Oceans Canada); Dillon, Frank; McLeod, Ryan; Muthukumarana, Saman; Cowen, Laura", pubDate = "2025",
  doi = "10.5061/dryad.bzkh189pw", sourceURL = "https://doi.org/10.5061/dryad.bzkh189pw",
  citation = "Banik, A., Gallagher, C., Howland, K., Lea, E., Dillon, F., McLeod, R., Muthukumarana, S. & Cowen, L. (2025). Assessing the effects of changes in reproductive condition on the survival of anadromous Dolly Varden (Salvelinus malma) using Bayesian multistate capture-recapture modelling [Dataset]. Dryad. https://doi.org/10.5061/dryad.bzkh189pw",
  paperDOI = "10.1139/cjfas-2025-0047",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual fall capture histories of 21,430 tagged anadromous Dolly Varden from Fisheries and Oceans Canada monitoring in the Firth, Babbage, Big Fish and Rat rivers and Joe Creek (Yukon and Northwest Territories), with reproductive state at capture: y = 0 not captured, 1 captured as a spawner, 2 captured as a non-spawner. One row per fish per fall of its river's program (Rat 2007-2020 to Firth and Joe 2014-2020); sex where identified.",
  samplingProtocol = "Fall seining on the spawning and overwintering reaches of each river; captured fish are tagged, sexed where possible, assessed as spawner or non-spawner, and released (Fisheries and Oceans Canada; Banik et al. 2025).",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Each river's deposited matrix has one column per sampled fall; every fish of that river is surveyed in every column, including falls before its first capture (y = 0). Rat River falls 2008, 2011, 2012 and Joe Creek fall 2020 have very few captures (reduced effort); per-river capture counts are in __periods.",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "open between periods (annual fall sampling; reproductive state may change between years, CJS multi-state)", occasionKind = "none", taxonInclusion = "single",
  stateCodes = list(`0` = "not captured", `1` = "captured as a spawner", `2` = "captured as a non-spawner"),
  geographicCoverage = "Firth River and Joe Creek (Yukon North Slope), Babbage River (Yukon), Big Fish River and Rat River (Northwest Territories), western Canadian Arctic; no coordinates deposited",
  temporalCoverage = "2007-09/2020-10",
  coordinatesCoarsened = NA,
  notes = "Units are row numbers of each river's deposited matrices (no tag ids in the deposit). Rows before a fish's first capture are 0 (drop to condition on first capture, as the authors do). Rat River's capture-only matrix disagrees with its breeding matrix in 10 cells of 8 rows (a one-fall offset); the breeding matrix, matched cell for cell by the sex matrix, is used. Per-river capture counts per fall in __periods.",
  notShipped = list(`capture-only matrices` = "redundant with y > 0 (see notes for the Rat River discrepancy)",
                    `model code` = "Dolly_Varden_Codes.zip (nimble models, simulations, prior sensitivity)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/banik_2025_dollyvarden_ms.R")
stage_dict_row(TABLE,
  description = "Multi-state capture histories (0 not captured, 1 spawner, 2 non-spawner) of 21,430 tagged anadromous Dolly Varden (Salvelinus malma) in five western Canadian Arctic rivers, falls 2007-2020 (river-specific spans), with sex.",
  url = "https://doi.org/10.5061/dryad.bzkh189pw",
  reference = "Banik, A., Gallagher, C., Howland, K., Lea, E., Dillon, F., McLeod, R., Muthukumarana, S., & Cowen, L. (2025). Assessing the effects of changes in reproductive condition on the survival of anadromous Dolly Varden (Salvelinus malma) using Bayesian multistate capture-recapture modelling. Canadian Journal of Fisheries and Aquatic Sciences.",
  doi_paper = "10.1139/cjfas-2025-0047", doi_data = "10.5061/dryad.bzkh189pw",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Five rivers in one table (unit_river); deposited matrices without tag ids; Rat River capture/breeding discrepancy (10 cells) resolved to the breeding matrix.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-state capture-recapture (reproductive state, Arnason-Schwarz / CJS)",
  sampling_protocol = "live_trap", design = "Multi-session (7-14 falls per river)", realm = "Freshwater",
  country = "CAN", coordinates = "None in source", notes = "Individuals as unit; five river populations; full deposited rectangle incl. pre-first-capture rows.",
  status = "tagged; do_not_publish: care_review (#150), withdrawn 2026-11-06")
