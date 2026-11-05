#!/usr/bin/env Rscript
# Table:  cayuela_2020_bombina_cjs
# Source: Dryad doi:10.5061/dryad.vt4b8gtnm version 47415 (published 2019-12-19), licence CC0 1.0 (as shown on the Dryad
#         landing page and in the API record). Cayuela, H., Lemaitre, J.-F., Bonnaire, E., Pichenot, J. &
#         Schmidt, B. R. "Capture-recapture data with partially known birth date in four populations of
#         yellow-bellied toads".
# Paper:  Cayuela, H., Lemaitre, J.-F., Bonnaire, E., Pichenot, J. & Schmidt, B. R. (2020). Population position
#         along the fast-slow life-history continuum predicts intraspecific variation in actuarial
#         senescence. Journal of Animal Ecology 89, doi:10.1111/1365-2656.13172 (not read; the
#         design is from the Dryad record).
# Data:   one workbook, Cayuela_et_al_Bombina_capture-recapture.xlsx, one sheet per population of yellow-
#         bellied toad (Bombina variegata) in France: SLOW1 (768 toads, 2010-2014), SLOW2 (1,154, 2010-2014),
#         FAST1 (9,418, 2008-2014), FAST2 (579, 2000-2008). Dryad usage notes: FAST1/FAST2 experience
#         unpredictable environments (harvested woodland), SLOW1/SLOW2 predictable ones (riverine habitat);
#         "the first column is the individual ID. In the second and third columns, there is the birth date
#         and death date ('0' is given if the date is unknown). Then come the capture histories." Histories
#         are one 0/1 column per calendar year (consecutive within a sheet; every year has captures). Birth
#         "date" is a year, known for 6,714 toads, always one or two years before first capture (asserted).
#         Death is 0 (unknown) for every toad. No toad has an all-zero history; ids are unique within a sheet.
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = "<population>_<ID>"; taxon = BOMVAR; period = calendar year - 1999 (2000 = 1 ... 2014 = 15;
#   __periods carries the year); y = captured that year (0/1); cluster_id = population; unit_population,
#   unit_environment (fast = harvested woodland, slow = riverine), unit_birth_year (NA where unknown).
#   At-risk rows (E4.4): every surveyed year of the toad's population from the population's first study
#   year, or from its birth year when that is later (a toad is not in the population before it is born);
#   rows before first capture are 0. Survey evidence: deposited_matrix (the year columns of each sheet are
#   that population's capture years).
#   Not shipped: Death (0 = unknown for every toad).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "cayuela_2020_bombina_cjs"
dir <- download_dryad("10.5061/dryad.vt4b8gtnm", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "47415"), length(list.files(dir)) == 1L)
f <- file.path(dir, "Cayuela_et_al_Bombina_capture-recapture.xlsx")
stopifnot(identical(excel_sheets(f), c("SLOW1", "SLOW2", "FAST1", "FAST2")))
expect <- list(SLOW1 = list(n = 768L, yrs = 2010:2014), SLOW2 = list(n = 1154L, yrs = 2010:2014),
               FAST1 = list(n = 9418L, yrs = 2008:2014), FAST2 = list(n = 579L, yrs = 2000:2008))
rows <- list(); n_birth <- 0L
for (pop in names(expect)) {
  r <- as.data.table(read_excel(f, pop))
  e <- expect[[pop]]
  stopifnot(nrow(r) == e$n, identical(names(r), c("ID", "Birth", "Death", as.character(e$yrs))),
            !anyDuplicated(r$ID), all(r$Death == 0))
  H <- as.matrix(r[, as.character(e$yrs), with = FALSE]); storage.mode(H) <- "integer"
  stopifnot(!anyNA(H), all(H %in% 0:1), all(rowSums(H) > 0), all(colSums(H) > 0))
  fc <- e$yrs[apply(H, 1, function(z) which(z == 1L)[1])]
  b <- as.integer(r$Birth); kb <- b != 0L
  stopifnot(all((fc - b)[kb] %in% 1:2))
  n_birth <- n_birth + sum(kb)
  start <- pmax(min(e$yrs), ifelse(kb, b, min(e$yrs)))
  L <- data.table(i = rep(seq_len(nrow(r)), each = length(e$yrs)), year = rep(e$yrs, nrow(r)), y = c(t(H)))
  L <- L[year >= start[i]]
  stopifnot(L[, sum(y)] == sum(H))
  rows[[pop]] <- L[, .(unit = paste0(pop, "_", r$ID[i]), taxon = "BOMVAR", y, period = year - 1999L,
                       cluster_id = pop, unit_population = pop,
                       unit_environment = if (startsWith(pop, "FAST")) "fast" else "slow",
                       unit_birth_year = ifelse(kb[i], b[i], NA_integer_))]
}
long <- order_eco(rbindlist(rows))
stopifnot(uniqueN(long$unit) == 11919L, n_birth == 6714L, !anyDuplicated(long[, .(unit, period)]))

periods <- data.table(period = 1:15, period_year = 2000:2014)
taxa <- make_taxa("BOMVAR", "Bombina variegata", vernacularName = "Yellow-bellied toad")
stopifnot(identical(iucn_category(taxa$taxonID, taxa$scientificName), "LC"))

dataset <- list(
  title = "Annual capture histories of 11,919 yellow-bellied toads in four French populations, 2000-2014",
  creator = "Cayuela, Hugo; Lemaitre, Jean-Francois; Bonnaire, Eric; Pichenot, Julian; Schmidt, Benedikt R.",
  pubDate = "2019", doi = "10.5061/dryad.vt4b8gtnm", sourceURL = "https://doi.org/10.5061/dryad.vt4b8gtnm",
  citation = "Cayuela, H., Lemaitre, J.-F., Bonnaire, E., Pichenot, J., & Schmidt, B. R. (2019). Capture-recapture data with partially known birth date in four populations of yellow-bellied toads [Dataset]. Dryad. https://doi.org/10.5061/dryad.vt4b8gtnm",
  paperDOI = "10.1111/1365-2656.13172",
  abstract = "Capture-recapture histories of yellow-bellied toads (Bombina variegata) from four populations in France, two in harvested woodland with unpredictable breeding habitat (FAST1, 2008-2014; FAST2, 2000-2008) and two in riverine habitat (SLOW1 and SLOW2, 2010-2014), with birth year for the toads first caught young. The authors used them to compare actuarial senescence along the fast-slow life-history continuum.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Capture-mark-recapture of toads in each population's study area every year; captures within a year pooled to one annual capture record per toad, as deposited.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one record per toad per year (captures within the year pooled in the deposit)",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none recorded",
  geographicCoverage = "Four populations of Bombina variegata in France (locations not deposited)",
  temporalCoverage = "2000/2014",
  covariateNote = "cluster_id and unit_population: SLOW1, SLOW2, FAST1, FAST2; unit_environment: fast (harvested woodland, unpredictable) or slow (riverine, predictable); unit_birth_year: year of birth where known (NA otherwise), one or two years before first capture.",
  notShipped = list(death = "Death column, 0 (unknown) for every toad"),
  notes = "Rows start at the population's first study year, or at the toad's birth year when that is later, and run to the population's last year; rows before first capture are 0. Populations were studied over different years (period indexes 2000-2014 across all four), so each toad has rows only in its own population's years.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cayuela_2020_bombina_cjs.R")
stage_dict_row(TABLE,
  description = "Annual capture histories of 11,919 yellow-bellied toads in four French populations (two in harvested woodland, two riverine), 2000-2014, with birth year where known.",
  url = "https://doi.org/10.5061/dryad.vt4b8gtnm",
  reference = "Cayuela, H., Lemaitre, J.-F., Bonnaire, E., Pichenot, J., & Schmidt, B. R. (2020). Population position along the fast-slow life-history continuum predicts intraspecific variation in actuarial senescence. Journal of Animal Ecology, 89.",
  doi_paper = "10.1111/1365-2656.13172", doi_data = "10.5061/dryad.vt4b8gtnm",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; four sheets stacked with population as cluster_id; rows start at birth year where it is later than the study start.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-season (5-9 annual sessions per population)",
  realm = "Freshwater", country = "FRA", coordinates = "None in source",
  notes = "Four populations, known-age subset; senescence studies.")
