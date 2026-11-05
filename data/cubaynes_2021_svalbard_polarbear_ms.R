#!/usr/bin/env Rscript
# Table:  cubaynes_2021_svalbard_polarbear_ms
# Source: Dryad doi:10.5061/dryad.fn2z34tsq, version 139162 (version 4, published 2022-09-09),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Cubaynes, S. "Modeling the demography of species providing extended parental care: A
#         capture-recapture approach with a case study on Polar Bears (Ursus maritimus)".
# Paper:  Cubaynes, S., Aars, J., Yoccoz, N. G., Pradel, R., Wiig, Ø., Ims, R. A. & Gimenez, O.
#         (2021). Modeling the demography of species providing extended parental care: A
#         capture-recapture multievent model with a case study on polar bears (Ursus maritimus).
#         Ecology and Evolution 11(7), 3380-3392, doi:10.1002/ece3.7296 (open access, PMC8019049;
#         read: Table 1 gives the event codes, section 2.3 the data).
# Data:   three space-separated files, row names = bear id.
#   CR.txt          158 family units (an adult or independent female with any dependent
#                   offspring) x 28 spring capture seasons 1992-2019 (X1992..X2019), one event
#                   code per year (paper Table 1): 1 / 2 = 2- / 3-year-old independent juvenile
#                   female, 3 / 4 = 4- / 5-year-old independent subadult female (the Dryad text
#                   calls 4 "four-year-old" too; the paper's Table 1 says 5), 5 / 6 = mother with
#                   one / two cubs of the year, 7 / 8 = with one / two yearlings, 9 / 10 = with one
#                   / two dependent two-year-olds, 11 = adult female without dependent offspring,
#                   0 = not captured. Triplets are coded as twins (paper). Independent bears
#                   captured only once were excluded by the authors (paper section 2.3).
#   captureday.txt  same shape: capture day of year, NA exactly where CR is 0 (asserted).
#   weaning.txt     120 two-year-old offspring: whether independent of the mother at capture, and
#                   the date; these are the offspring, not the family-unit histories; not shipped.
#
# Mapping (standard E9 multi-state capture-recapture, responseType state, unitKind individual):
#   unit = PB + bear id (the female heading the family unit), taxon = URSMAR, period = spring
#   season 1..28 (1992..2019, in __periods), no occasion (one capture event per female per spring,
#   helicopter darting after den emergence). y = the deposited event code 0..11 (stateCodes from
#   paper Table 1); y_raw not needed (y is the deposit's code). date = the capture date,
#   reconstructed exactly from the year and the deposited day of year, on capture rows only.
#   At-risk span (E4.4): a female first captured as an adult (codes 5-11) is of unknown age and
#   is at risk from 1992. A female first captured at known age a (codes 1-4, a = code + 1) joins
#   the model's state space as an independent juvenile at age 2 (paper Table 1: J2 is the first
#   state; younger bears are dependent offspring inside their mother's unit), so her rows begin
#   in the year she was 2 (first capture year - a + 2), or 1992 if earlier; unit_birthyear =
#   first capture year - a. The known-age codes advance by one per year (asserted).
#   Survey evidence: deposited_matrix (the population was captured each spring 1992-2019).
#   Coordinates: none deposited (Svalbard, Norway); Ursus maritimus is IUCN VU, nothing is
#   coordinate-level.
#   Not shipped: weaning.txt (offspring independence records, not family-unit histories).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cubaynes_2021_svalbard_polarbear_ms"
dir <- download_dryad("doi:10.5061/dryad.fn2z34tsq", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "139162"),
          setequal(list.files(dir), c("captureday.txt", "CR.txt", "weaning.txt")))
years <- 1992:2019
H <- as.matrix(read.table(file.path(dir, "CR.txt"), header = TRUE))
D <- as.matrix(read.table(file.path(dir, "captureday.txt"), header = TRUE))
stopifnot(identical(colnames(H), paste0("X", years)), identical(colnames(D), colnames(H)),
          nrow(H) == 158L, identical(rownames(H), rownames(D)), !anyDuplicated(rownames(H)),
          all(H %in% 0:11), identical((H > 0), !is.na(D)), all(D[!is.na(D)] >= 1 & D[!is.na(D)] <= 366),
          identical(as.integer(table(factor(H, 0:11))), c(3923L, 15L, 14L, 28L, 24L, 63L, 84L, 50L, 23L, 15L, 4L, 181L)),
          all(rowSums(H > 0) >= 2))
# paper section 2.3: 81 juvenile/subadult captures, 231 cubs, 96 yearlings, 23 dependent two-year-olds
stopifnot(sum(H %in% 1:4) == 81L, sum(H == 5) + 2 * sum(H == 6) == 231L,
          sum(H == 7) + 2 * sum(H == 8) == 96L, sum(H == 9) + 2 * sum(H == 10) == 23L)
first <- apply(H, 1, function(r) which(r > 0)[1])
fcode <- H[cbind(seq_len(nrow(H)), first)]
known <- fcode %in% 1:4
birth <- ifelse(known, years[first] - (fcode + 1L), NA_integer_)
# known-age codes advance one per year
for (i in which(known)) {
  w <- which(H[i, ] %in% 1:4); stopifnot(all(H[i, w] == (years[w] - birth[i] - 1L)))
}
start <- ifelse(known, pmax(1L, match(birth + 2L, years, nomatch = 1L)), 1L)
stopifnot(all(start <= first), sum(known) == 56L)

Y <- H; storage.mode(Y) <- "integer"; Y[col(Y) < start] <- NA_integer_
DT <- matrix(NA_character_, nrow(H), ncol(H))
cap <- which(H > 0, arr.ind = TRUE)
DT[cap] <- format(as.Date(sprintf("%d-01-01", years[cap[, 2]])) + D[cap] - 1L)
ids <- paste0("PB", rownames(H))
long <- array_to_eco(Y, taxon = "URSMAR", site_ids = ids, site_covs = data.frame(birthyear = birth),
                     period = seq_along(years))
long[, occasion := NULL]
ix <- cbind(match(long$unit, ids), long$period)
long[, date := DT[ix]]
setcolorder(long, c("unit", "taxon", "y", "period", "date"))
stopifnot(nrow(long) == sum(!is.na(Y)), sum(long$y > 0) == 501L, identical(!is.na(long$date), long$y > 0))

taxa <- make_taxa("URSMAR", "Ursus maritimus", vernacularName = "Polar bear")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))
periods <- data.table(period = seq_along(years), year = years,
                      n_captured = as.integer(colSums(H > 0)),
                      n_with_cubs = as.integer(colSums(matrix(H %in% 5:6, nrow(H)))))

dataset <- list(
  title = "Annual family-unit capture histories (11 reproductive and age states) of 158 female polar bears in Svalbard, 1992-2019",
  creator = "Cubaynes, Sarah", pubDate = "2022", doi = "10.5061/dryad.fn2z34tsq",
  sourceURL = "https://doi.org/10.5061/dryad.fn2z34tsq",
  citation = "Cubaynes, S. (2022). Modeling the demography of species providing extended parental care: A capture-recapture approach with a case study on Polar Bears (Ursus maritimus) [Dataset]. Dryad. https://doi.org/10.5061/dryad.fn2z34tsq",
  paperDOI = "10.1002/ece3.7296",
  abstract = "Female polar bears and their dependent offspring captured each spring in Svalbard as part of the Norwegian Polar Institute's long-term monitoring, coded by the female's age class (independent juvenile or subadult) or by the number and age of the dependent offspring with her. The paper fits a multievent capture-recapture model of survival, breeding, litter size and the timing of offspring independence.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Each spring after den emergence (mostly day of year 80-130), bears one year or older were darted from a helicopter and immobilised, cubs of the year injected by syringe; dependent offspring were captured with their mother. Bears were individually marked; each female's family unit is coded once per spring by her age class or the number and age of her dependent offspring.",
  samplingProtocolCode = "live_capture", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "period (one capture event per female per spring; survival and reproductive transitions between years)",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none",
  stateCodes = list(`0` = "not captured",
                    `1` = "2-year-old independent juvenile female", `2` = "3-year-old independent juvenile female",
                    `3` = "4-year-old independent subadult female", `4` = "5-year-old independent subadult female",
                    `5` = "mother with one dependent cub of the year", `6` = "mother with two dependent cubs of the year (triplets coded as twins)",
                    `7` = "mother with one dependent yearling", `8` = "mother with two dependent yearlings",
                    `9` = "mother with one dependent two-year-old", `10` = "mother with two dependent two-year-olds",
                    `11` = "adult female without dependent offspring"),
  temporalCoverage = "1992/2019",
  geographicCoverage = "Svalbard, Norway (Barents Sea subpopulation)",
  notes = "Unit ids are the deposited bear ids. Females first captured as adults (codes 5-11) are of unknown age and have rows from 1992; females first captured at known age (codes 1-4) have rows from the year they were 2, the first state of the paper's model (younger bears are dependent offspring in their mother's unit), and unit_birthyear. Codes 3 and 4 follow the paper's Table 1 (4- and 5-year-old subadults); the Dryad description calls both four-year-old. Capture dates rebuilt exactly from year and the deposited day of year; a few fall outside the spring window (day 3 to 295). Independent bears captured only once were excluded by the authors. The deposit has 420 adult-female captures (paper: 444).",
  coordinatesCoarsened = NA,
  notShipped = list(weaning.txt = "independence status at capture of 120 two-year-old offspring: records of the offspring, not family-unit histories"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cubaynes_2021_svalbard_polarbear_ms.R")
stage_dict_row(TABLE,
  description = "Annual spring capture histories of 158 female polar bear family units in Svalbard, 1992-2019, coded in 11 states by the female's age class or the number and age of her dependent offspring; capture dates per row.",
  url = "https://doi.org/10.5061/dryad.fn2z34tsq",
  reference = "Cubaynes, S., Aars, J., Yoccoz, N. G., Pradel, R., Wiig, Ø., Ims, R. A., & Gimenez, O. (2021). Modeling the demography of species providing extended parental care: A capture-recapture multievent model with a case study on polar bears (Ursus maritimus). Ecology and Evolution, 11(7), 3380-3392.",
  doi_paper = "10.1002/ece3.7296", doi_data = "10.5061/dryad.fn2z34tsq",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multievent family-unit coding; known-age females start at age 2. Species IUCN VU; no coordinates in the deposit.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state (multievent) capture-recapture (reproductive state, family units)",
  sampling_protocol = "live capture", design = "Multi-session (28 annual spring capture seasons)",
  realm = "Marine", country = "NOR", coordinates = "None in source",
  notes = "Female-headed family units; states code litter size and offspring age.")
