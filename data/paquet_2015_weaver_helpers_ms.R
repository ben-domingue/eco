#!/usr/bin/env Rscript
# Table:  paquet_2015_weaver_helpers_ms
# Source: Dryad doi:10.5061/dryad.mk44c (CC0 1.0, as shown on the Dryad page; published
#         2016-03-30). Paquet, M., Doutrelant, C., Hatchwell, B.J., Spottiswoode, C.N. & Covas, R.
#         Data from: Antagonistic effect of helpers on breeding male and female survival in a
#         cooperatively breeding bird.
# Paper:  Paquet, M. et al. (2015). Journal of Animal Ecology 84(5), 1354-1362,
#         doi:10.1111/1365-2656.12377. Multi-event capture-mark-recapture of breeding sociable
#         weavers (Philetairus socius) with the number of helpers at the nest as the event.
# Data:   data_dryad.xlsx, sheet data (168 breeders: 13-character capture history, Sexe, Mass and
#         Minimum age at first entry into the history) and sheet legend (1 captured, no helpers;
#         2 captured, 1 helper; 3, 2 helpers; 4, 3 helpers; 5, 4 helpers; 6 captured, number of
#         helpers not known; 0 not captured). The calendar years of the 13 occasions are not in
#         the deposit (annual breeding seasons, paper).
# Mapping (standard: multi-state / multi-event capture-recapture, E9 core): unit = breeder (B001,
#   sheet order); taxon = PHISOC; period = occasion 1..13; y = the history code with stateCodes
#   from the legend (6 = captured with unknown helper number, an uncertain event kept as
#   deposited). Full rectangle from the first occasion (E4.4: breeders caught in the wild).
#   unit_: sex; mass and minimum age at first capture (unit_mass_first_g, unit_min_age_first).
#   Survey evidence: deposited_matrix. IUCN LC; no coordinates deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "paquet_2015_weaver_helpers_ms"
dir <- download_dryad("10.5061/dryad.mk44c", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^data_dryad\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
lg <- as.data.frame(suppressMessages(read_excel(f, "legend", col_names = FALSE)))
stopifnot(identical(lg[[2]][2:8], c("captured, no helpers", "captured, 1 helper", "captured, 2 helpers", "captured, 3 helpers",
                                    "captured, 4 helpers", "captured, number of helpers not known", "not captured")))
d <- as.data.table(read_excel(f, "data", col_types = "text")); setnames(d, c("ch", "sex", "mass", "min_age"))
stopifnot(nrow(d) == 168, all(nchar(d$ch) == 13), all(grepl("^[0-6]+$", d$ch)), all(d$sex %in% c("Female", "Male")))
H <- do.call(rbind, strsplit(d$ch, "")); storage.mode(H) <- "integer"
stopifnot(all(rowSums(H > 0) > 0), sum(H > 0) == 432)
ids <- sprintf("B%03d", seq_len(168))
long <- data.table(unit = rep(ids, 13), period = rep(1:13, each = 168), y = as.vector(H), taxon = "PHISOC",
                   unit_sex = rep(tolower(d$sex), 13), unit_mass_first_g = rep(as.numeric(d$mass), 13), unit_min_age_first = rep(as.numeric(d$min_age), 13))
long <- order_eco(long)
stopifnot(nrow(long) == 168 * 13)
taxa <- make_taxa("PHISOC", "Philetairus socius", vernacularName = "Sociable weaver")
dataset <- list(
  title = "Multi-event capture histories of 168 breeding sociable weavers with the number of helpers at the nest, 13 annual occasions",
  creator = "Paquet, Matthieu; Doutrelant, Claire; Hatchwell, Ben J.; Spottiswoode, Claire N.; Covas, Rita", pubDate = "2016",
  doi = "10.5061/dryad.mk44c", sourceURL = "https://doi.org/10.5061/dryad.mk44c",
  citation = "Paquet, M., Doutrelant, C., Hatchwell, B. J., Spottiswoode, C. N., & Covas, R. (2016). Data from: Antagonistic effect of helpers on breeding male and female survival in a cooperatively breeding bird [Dataset]. Dryad. https://doi.org/10.5061/dryad.mk44c",
  paperDOI = "10.1111/1365-2656.12377",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual capture histories of 168 breeding sociable weavers (Philetairus socius), each capture coded by the number of helpers at the breeder's nest (none, 1-4, or unknown), with sex and mass and minimum age at first capture: the input of a multi-event model of helper effects on breeder survival.",
  samplingProtocol = "Annual capture of colony members at sociable weaver colonies during the breeding season; breeders' nests monitored to count helpers.",
  samplingProtocolCode = "net_capture", surveyEvidence = "deposited_matrix", responseType = "state",
  stateCodes = list(`0` = "not captured", `1` = "captured, no helpers", `2` = "captured, 1 helper", `3` = "captured, 2 helpers",
                    `4` = "captured, 3 helpers", `5` = "captured, 4 helpers", `6` = "captured, number of helpers not known"),
  unitKind = "individual", closure = "none", closureNote = "one record per breeder per year; open between years (multi-event CMR)", occasionKind = "none",
  taxonInclusion = "single", geographicCoverage = "Sociable weaver colonies in the Northern Cape, South Africa (see the paper); no coordinates deposited",
  temporalCoverage = "13 annual occasions; calendar years not stated in the deposit (paper 2015)",
  notShipped = list(none = "the whole sheet is shipped"),
  notes = "Unit ids follow the sheet order. Mass (g) and minimum age (years) are the values at first entry into the history (legend sheet). Code 6 is a capture whose helper number is unknown (an uncertain event in the multi-event model).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:13, period_note = "annual breeding-season occasion; year not deposited"),
                  script = "data/paquet_2015_weaver_helpers_ms.R")
stage_dict_row(TABLE, description = "Multi-event capture histories of 168 breeding sociable weavers coded by helper number, 13 annual occasions.",
  url = "https://doi.org/10.5061/dryad.mk44c", reference = "Paquet, M. et al. (2015). Antagonistic effect of helpers on breeding male and female survival in a cooperatively breeding bird. Journal of Animal Ecology, 84(5), 1354-1362.",
  doi_paper = "10.1111/1365-2656.12377", doi_data = "10.5061/dryad.mk44c", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-event CMR; years not deposited.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state / multi-event capture-recapture",
  sampling_protocol = "net_capture", design = "Multi-season (13 annual occasions)", realm = "Terrestrial",
  country = "ZAF", coordinates = "None in source", notes = "Cooperative breeder; helper number as event.")
