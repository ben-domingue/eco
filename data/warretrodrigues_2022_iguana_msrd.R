#!/usr/bin/env Rscript
# Table:  warretrodrigues_2022_iguana_msrd
# Source: Dryad doi:10.5061/dryad.9p8cz8wgv (CC0 1.0, as shown on the Dryad page; published
#         2022-08-03). Warret Rodrigues, C., Angin, B. & Besnard, A. Favoring recruitment as a
#         conservation strategy to improve the resilience of long-lived reptile populations:
#         insights from a population viability analysis.
# Paper:  Warret Rodrigues, C., Angin, B. & Besnard, A. (2021). Ecology and Evolution,
#         doi:10.1002/ece3.8021. Lesser Antillean iguana (Iguana delicatissima, IUCN CR) on an
#         islet: a yearly mark-recapture survey 2012-2020 at the end of the males' reproductive
#         peak, "9 primary sessions", each "five secondary sessions (i.e. 5 consecutive days of
#         sampling for 7.5 hours per day)", 45 secondary sessions in all; hand or noose capture,
#         PIT tags; robust-design Pradel model on adults (Dryad methods).
# Data:   ViabilityLesserAntilleanIguanaPopulation_CaptureHistory_20122020.csv: 1,156 PIT-tagged
#         iguanas x 45 columns J1..J45 (the secondary sessions in order), each cell a state code
#         (README): 0 not captured, 1 juvenile, 2 subadult female, 3 subadult male, 4 subadult of
#         undetermined sex, 5 adult female, 6 adult male, 7 adult of undetermined sex, 8 found
#         dead. Observed: codes 0-7 only (no 8); every history has a capture.
# Mapping (standard: multi-state robust design capture-recapture, E9 core): unit = row (I0001
#   ..., deposited order); taxon = IGUDEL; period = year 1..9 (2012-2020, __periods), occasion =
#   secondary session 1..5 within the year (J(5(t-1)+k)); y = the state code; stateCodes from the
#   README. Full rectangle (E4.4): every animal has rows for all 45 sessions (caught in the
#   wild; no removals or deaths recorded). Survey evidence: deposited_matrix (all 45 sessions
#   were sampled). The state is the class at capture as the source records it; a few histories
#   change sex or class across sessions as deposited. No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "warretrodrigues_2022_iguana_msrd"
dir <- download_dryad("10.5061/dryad.9p8cz8wgv", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "CaptureHistory_20122020\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f)
stopifnot(identical(names(d), paste0("J", 1:45)), nrow(d) == 1156)
M <- as.matrix(d)
stopifnot(all(M %in% 0:7), all(rowSums(M > 0) > 0), sum(M > 0) == 3339)
ids <- sprintf("I%04d", seq_len(nrow(M)))
long <- data.table(unit = rep(ids, 45), j = rep(1:45, each = nrow(M)), y = as.integer(as.vector(M)))
long[, `:=`(taxon = "IGUDEL", period = (j - 1L) %/% 5L + 1L, occasion = (j - 1L) %% 5L + 1L)][, j := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 1156 * 45, sum(long$y > 0) == 3339, max(long$period) == 9)
periods <- data.table(period = 1:9, period_year = 2012:2020)
taxa <- make_taxa("IGUDEL", "Iguana delicatissima", vernacularName = "Lesser Antillean iguana")
dataset <- list(
  title = "Multi-state robust-design capture histories of 1,156 Lesser Antillean iguanas on an islet, 9 years x 5 capture days, 2012-2020",
  creator = "Warret Rodrigues, Chloé; Angin, Baptiste; Besnard, Aurélien", pubDate = "2022",
  doi = "10.5061/dryad.9p8cz8wgv", sourceURL = "https://doi.org/10.5061/dryad.9p8cz8wgv",
  citation = "Warret Rodrigues, C., Angin, B., & Besnard, A. (2022). Favoring recruitment as a conservation strategy to improve the resilience of long-lived reptile populations: insights from a population viability analysis [Dataset]. Dryad. https://doi.org/10.5061/dryad.9p8cz8wgv",
  paperDOI = "10.1002/ece3.8021",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture histories of PIT-tagged Lesser Antillean iguanas (Iguana delicatissima, IUCN CR) from a yearly mark-recapture survey of an islet population, 2012-2020: nine primary sessions of five consecutive capture days each, with the age-sex class (juvenile, subadult or adult; female, male or undetermined) recorded at each capture.",
  samplingProtocol = "Yearly survey at the end of the males' reproductive peak: five consecutive days of 7.5 hours of systematic search by two-person teams rotating among five zones of the islet; iguanas caught by hand or noose, scanned and PIT-tagged.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "state",
  stateCodes = list(`0` = "not captured", `1` = "captured as a juvenile", `2` = "captured as a subadult female", `3` = "captured as a subadult male",
                    `4` = "captured as a subadult of undetermined sex", `5` = "captured as an adult female", `6` = "captured as an adult male",
                    `7` = "captured as an adult of undetermined sex"),
  unitKind = "individual", closure = "closed", closureNote = "closed within a year's five capture days, open between the nine years (robust design; the authors fit a robust-design Pradel model to adults)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "An islet population of Iguana delicatissima in the Lesser Antilles (see the paper); no coordinates deposited",
  temporalCoverage = "2012/2020",
  designNote = "Multi-state robust design: period = year, occasion = capture day within the year, y = age-sex class at capture.",
  notShipped = list(none = "the whole history file is shipped; README code 8 (found dead) does not occur"),
  notes = "Unit ids I0001-I1156 follow the deposited row order (no tag numbers are deposited). States are the class recorded at each capture; a few histories change class or sex between captures, as deposited. Iguana delicatissima is IUCN CR; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/warretrodrigues_2022_iguana_msrd.R")
stage_dict_row(TABLE,
  description = "Multi-state robust-design capture histories (age-sex class at capture) of 1,156 Lesser Antillean iguanas, 9 years x 5 capture days, 2012-2020.",
  url = "https://doi.org/10.5061/dryad.9p8cz8wgv",
  reference = "Warret Rodrigues, C., Angin, B., & Besnard, A. (2021). Favoring recruitment as a conservation strategy to improve the resilience of long-lived reptile populations: insights from a population viability analysis. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.8021", doi_data = "10.5061/dryad.9p8cz8wgv", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-state robust design; IUCN CR, no coordinates.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Multi-state robust design capture-recapture",
  sampling_protocol = "visual_encounter", design = "Robust design (9 years x 5 days)", realm = "Terrestrial",
  country = "", coordinates = "None in source", notes = "IUCN CR iguana; state = age-sex class at capture.")
