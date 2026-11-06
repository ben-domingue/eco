#!/usr/bin/env Rscript
# Table:  sossover_2026_outerbanks_coyote_ms
# Source: Dryad, doi:10.5061/dryad.kwh70rzmn, version 466284 (version 3, published 2026-09-29), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON). Sossover, D., Kays, R. & Kierepka, E.
# Paper:  none linked on the Dryad record (the deposit's title: "Coyote density, demography, and genetic structure
#         across North Carolina's barrier islands"). The design is from the Dryad abstract and README: scat
#         surveys on seven barrier islands of the Outer Banks, North Carolina, in three primary periods (Winter
#         2024, Summer 2024, Winter 2025), four secondary occasions per island per period; individuals identified
#         by microsatellite genotyping of fecal DNA (62 coyotes); the authors fit a Bayesian multistate
#         robust-design (Jolly-Seber) model with the island as the state (abundance, apparent survival, per-capita
#         recruitment, inter-island movement). Coyotes there are subject to lethal removal by federal agencies.
# Data:   obx_coyote_capture_histories.csv: 62 rows (recapture_id, a genotype id), 12 columns w11..w14, s11..s14,
#           w21..w24 (period x secondary occasion); a cell is the island code (1-7) where the coyote was detected
#           on that occasion, 0 = not detected. Every coyote is detected on one island only (asserted); per the
#           README the authors removed one detection of individual HH (Ocracoke, within a period in which she was
#           also on North Core) before deposit, so it is not recoverable.
#         obx_coyote_island_key.csv: island x period survey indicator; all islands surveyed in all periods except
#           Bodie (1) in Winter 2024 (asserted), and no detection on Bodie then (asserted).
#         obx_coyote_island_covariates.csv: island x survival interval lethal-management indicator (t1, t2) and
#           roads_det (road-based scat surveys on the island): state-level covariates, given in covariateNote.
#         OuterBanksCoyote_MarkRecapture_Script_for_dryad.R (JAGS model), obx_coyote_jags_output.rds (posterior).
# Mapping (multi-state robust design, E2 state, E4.4): unitKind individual, unit = recapture_id, taxon = CANLAT,
#   period = primary period (1 = Winter 2024, 2 = Summer 2024, 3 = Winter 2025), occasion = secondary 1..4,
#   y = island code where detected (stateCodes), 0 = not detected. Wild coyotes of unknown age, at risk from the
#   first period: every coyote has a row at every one of the 12 occasions (62 x 12). surveyEvidence =
#   effort_table (the island x period survey key: every period had surveys on at least six islands, four
#   occasions each); state 1 (Bodie) was not surveyed in period 1, recorded in __periods
#   (states_not_surveyed), so a y = 0 there is not evidence of absence from Bodie. No individual removal or
#   death records are deposited, so no obs_removed.
#   No coordinates; island names are in stateCodes. Coyote is IUCN LC.
#   Not shipped: the JAGS posterior (.rds) and the model's estimates; the removed HH detection (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sossover_2026_outerbanks_coyote_ms"

dir <- download_dryad("10.5061/dryad.kwh70rzmn", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("obx_coyote_capture_histories.csv", "obx_coyote_island_covariates.csv",
                                      "obx_coyote_island_key.csv", "obx_coyote_jags_output.rds",
                                      "OuterBanksCoyote_MarkRecapture_Script_for_dryad.R", "README.md")))
ch <- fread(file.path(dir, "obx_coyote_capture_histories.csv"), colClasses = list(character = "recapture_id"))
key <- fread(file.path(dir, "obx_coyote_island_key.csv"))
cov <- fread(file.path(dir, "obx_coyote_island_covariates.csv"))
OCC <- c(paste0("w1", 1:4), paste0("s1", 1:4), paste0("w2", 1:4))
ISL <- c("Bodie", "Pea", "Hatteras", "Ocracoke", "North Core", "South Core", "Shackleford")
stopifnot(identical(names(ch), c("recapture_id", OCC)), nrow(ch) == 62L, !anyDuplicated(ch$recapture_id), "HH" %in% ch$recapture_id,
          identical(names(key), c("island", "w1", "s1", "w2", "island_name")), identical(key$island, 1:7),
          identical(key$island_name, tolower(ISL)), identical(key$w1, c(0L, rep(1L, 6))), all(key$s1 == 1L), all(key$w2 == 1L),
          identical(names(cov), c("island", "t1", "t2", "roads_det")), identical(cov$island, 1:7))
M <- as.matrix(ch[, ..OCC])
stopifnot(all(M %in% 0:7), all(rowSums(M > 0) >= 1L),
          all(apply(M, 1, function(r) length(unique(r[r > 0]))) == 1L),      # one island per coyote
          !any(M[, 1:4] == 1L),                                                  # nothing on Bodie when it was not surveyed
          identical(as.vector(table(factor(M, levels = 0:7))), c(603L, 34L, 16L, 36L, 3L, 9L, 37L, 6L)))

long <- data.table(unit = rep(ch$recapture_id, 12), k = rep(1:12, each = 62), y = as.vector(M))
long[, `:=`(taxon = "CANLAT", period = (k - 1L) %/% 4L + 1L, occasion = (k - 1L) %% 4L + 1L)]
long[, k := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 62L * 12L, sum(long$y > 0) == 141L)
cat(sprintf("  %d rows, %d coyotes, %d detections\n", nrow(long), uniqueN(long$unit), sum(long$y > 0)))

periods <- data.table(period = 1:3, label = c("w1", "s1", "w2"), season = c("Winter 2024", "Summer 2024", "Winter 2025"),
                      states_surveyed = c("2;3;4;5;6;7", "1;2;3;4;5;6;7", "1;2;3;4;5;6;7"),
                      states_not_surveyed = c("1 (Bodie)", "", ""),
                      n_detections = as.integer(tapply(long$y > 0, long$period, sum)),
                      n_individuals_detected = as.integer(long[, sum(y > 0) > 0, by = .(unit, period)][, sum(V1), by = period]$V1))
taxa <- make_taxa("CANLAT", "Canis latrans", vernacularName = "Coyote")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))

mgmt <- function(col) paste(ISL[cov[[col]] == 1L], collapse = ", ")
dataset <- list(
  title = "Multi-state robust-design capture histories of 62 coyotes identified from fecal DNA on seven barrier islands of the Outer Banks, North Carolina, Winter 2024 to Winter 2025",
  creator = "Sossover, Daniel; Kays, Roland; Kierepka, Elizabeth", pubDate = "2026",
  doi = "10.5061/dryad.kwh70rzmn", sourceURL = "https://doi.org/10.5061/dryad.kwh70rzmn",
  citation = "Sossover, D., Kays, R., & Kierepka, E. (2026). Data and code from: Coyote density, demography, and genetic structure across North Carolina's barrier islands [Dataset]. Dryad. https://doi.org/10.5061/dryad.kwh70rzmn",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Scat surveys for coyotes on seven barrier islands of North Carolina's Outer Banks, where recently established coyotes depredate protected shorebird and sea turtle nests and are lethally removed by federal agencies; three primary periods (Winter 2024, Summer 2024, Winter 2025) of four secondary occasions; 62 individuals identified by microsatellite genotyping of fecal DNA. The authors fit a Bayesian multistate robust-design model with island as the state. One row per coyote per secondary occasion; y is the island of detection.",
  samplingProtocol = "Noninvasive genetic sampling: searches for coyote scat on each island (including road-based scat surveys on some islands), four secondary occasions per island in each primary period; scats genotyped at microsatellite loci to identify individuals.",
  samplingProtocolCode = "scat_genotyping", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The deposit's island x period survey key: every island was surveyed in every period except Bodie (state 1) in Winter 2024, with four secondary occasions per island per period. Every coyote carries all 12 occasions; Bodie's gap in period 1 is a missing state, not a missing survey, and is listed in __periods (states_not_surveyed).",
  responseType = "state", unitKind = "individual",
  stateCodes = setNames(as.list(c("not detected", sprintf("detected on %s Island", ISL))), as.character(0:7)),
  closure = "closed", closureNote = "robust design: the population (and each coyote's island) is assumed closed within a primary period across its four secondary occasions; open between periods (survival, recruitment, inter-island movement)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "none",
  geographicCoverage = "Outer Banks barrier islands, North Carolina, USA: Bodie, Pea, Hatteras, Ocracoke, North Core, South Core and Shackleford (no coordinates deposited)",
  temporalCoverage = "2024/2025",
  covariateNote = sprintf("State-level covariates from obx_coyote_island_covariates.csv (not row columns): lethal removal of coyotes by island managers during survival interval 1 (Winter 2024 to Summer 2024) on %s; during interval 2 (Summer 2024 to Winter 2025) on %s; road-based scat surveys (a detection covariate) on %s.",
                          mgmt("t1"), mgmt("t2"), mgmt("roads_det")),
  designNote = "Multi-state robust design (E9 core: robust design and multi-state capture-recapture): period and occasion both present; state = island.",
  notShipped = list(model_output = "obx_coyote_jags_output.rds: posterior chains of abundance, survival, recruitment, movement and detection",
                    hh_detection = "one detection of coyote HH on Ocracoke, removed by the authors before deposit (README) so that no coyote moves between islands within a period"),
  notes = "Every coyote was detected on one island only. Rows before a coyote's first detection are 0 (wild coyotes at risk from the first period, E4.4); drop them to condition on first capture. No individual removal or death records are deposited, although lethal removal occurred on some islands (covariateNote).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/sossover_2026_outerbanks_coyote_ms.R")
stage_dict_row(TABLE,
  description = "Multi-state robust-design capture histories (state = island) of 62 coyotes identified from fecal DNA on seven Outer Banks barrier islands, North Carolina, three primary periods x four occasions, Winter 2024 to Winter 2025.",
  url = "https://doi.org/10.5061/dryad.kwh70rzmn",
  reference = "Sossover, D., Kays, R., & Kierepka, E. (2026). Data and code from: Coyote density, demography, and genetic structure across North Carolina's barrier islands [Dataset]. Dryad. https://doi.org/10.5061/dryad.kwh70rzmn",
  doi_paper = "", doi_data = "10.5061/dryad.kwh70rzmn",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Island x period survey key as effort; Bodie not surveyed in Winter 2024 (in __periods); island management covariates in covariateNote.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state robust design (Jolly-Seber)",
  sampling_protocol = "scat_genotyping", design = "Robust design (3 primary periods x 4 secondary occasions; 7 islands as states)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Fecal-DNA genotypes; state = island; lethal removal on some islands.")
