#!/usr/bin/env Rscript
# Table:  hamer_2024_hungary_amph_comm
# Source: Dryad doi:10.5061/dryad.70rxwdc6w (CC0 1.0), version 5 (2024-10-09)
#   Hamer, A.J. & Horanyi, J. (2024). Multi-species occupancy model for estimating the
#   probability of detecting amphibian species in Hungary. Dryad.
# Paper:  Hamer, A.J. & Horanyi, J. (2024). Improving inference within freshwater
#         community studies: accounting for variable detection rates of amphibians and
#         fish. Ecology and Evolution 14(10), doi:10.1002/ece3.70383
# Data:   species_data.zip: nine CSVs (one per species), 100 ponds x survey1..survey3,
#         1/0, NA = no survey (one cell: pond T9, survey 1). survey_covariates.zip: eight
#         CSVs of 100 x 3 survey covariates (days since 19 March 2023, VES minutes, water
#         temperature, water level %, wind 0/1, rain 0/1, fish detected 0/1, emergent
#         vegetation %); the covariate files carry values even for the one unsurveyed
#         cell (T9, survey 1), so the species files define what was surveyed. fish.csv and
#         wind.csv label pond MOD1 as "MO1" (row 28 in every file); matched by position. Each survey combined visual encounter + aural census, dip-netting
#         and newt trapping; a detection is eggs, larvae or post-metamorphic animals.
#
# Mapping (standard section 3.6, community occupancy): unit = pond, taxon = 6-letter
#   species code from the deposit (upper case), occasion = survey 1..3, y = 0/1.
#   obs_: all eight survey covariates; `date` = 2023-03-19 + days (the deposit gives the
#   day offset exactly, so the date is not fabricated). PELCOM is the Pelophylax
#   water-frog complex (taxonRank = "species complex", matched to the genus on GBIF).
#   No coordinates or pond covariates in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hamer_2024_hungary_amph_comm"
dir <- download_dryad("10.5061/dryad.70rxwdc6w", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
for (z in c("species_data.zip", "survey_covariates.zip")) unzip(file.path(dir, z), exdir = file.path(dir, sub("\\.zip$", "", z)))

species <- c(bombom = "Bombina bombina", bufbuf = "Bufo bufo", bufvir = "Bufotes viridis", hylarb = "Hyla arborea",
             lisvul = "Lissotriton vulgaris", pelfus = "Pelobates fuscus", pelcom = "Pelophylax", randal = "Rana dalmatina",
             tridob = "Triturus dobrogicus")
vern <- c("European fire-bellied toad", "Common toad", "European green toad", "European tree frog", "Smooth newt",
          "Common spadefoot", "Water frogs (Pelophylax esculentus complex)", "Agile frog", "Danube crested newt")
read_mat <- function(f) { d <- fread(f); list(site = d[[1]], m = as.matrix(d[, -1])) }
sp <- lapply(names(species), function(s) read_mat(file.path(dir, "species_data", paste0(s, ".csv"))))
sites <- sp[[1]]$site
stopifnot(length(sites) == 100, !anyDuplicated(sites), all(sapply(sp, function(x) identical(x$site, sites))))
y <- array(unlist(lapply(sp, `[[`, "m")), dim = c(100, 3, 9), dimnames = list(sites, NULL, toupper(names(species))))
stopifnot(all(y %in% c(0, 1, NA)))
na_pat <- is.na(y[, , 1])
stopifnot(all(apply(is.na(y), 3, identical, na_pat)), sum(na_pat) == 1, sites[which(na_pat, arr.ind = TRUE)[1]] == "T9")

covs <- c(days_since_19mar = "days", effort_ves_min = "effort", water_temp_c = "water temp", water_level_pct = "water",
          wind = "wind", rain = "rain", fish_detected = "fish", emergent_veg_pct = "emerg")
obs <- lapply(covs, function(f) { x <- read_mat(file.path(dir, "survey_covariates", paste0(f, ".csv")))
  stopifnot(all(x$site == sites | (x$site == "MO1" & sites == "MOD1")), !anyNA(x$m))
  m <- unname(x$m); m[na_pat] <- NA; m })
stopifnot(all(obs$wind %in% c(0, 1, NA)), all(obs$rain %in% c(0, 1, NA)), all(obs$fish_detected %in% c(0, 1, NA)))
stopifnot(all(obs$days_since_19mar >= 0, na.rm = TRUE), all(apply(obs$days_since_19mar, 1, function(r) all(diff(na.omit(r)) > 0))))
date_m <- matrix(format(as.Date("2023-03-19") + obs$days_since_19mar), 100)

long <- array_to_eco(y, site_ids = sites, obs_covs = c(obs, list(date = date_m)))
setnames(long, "obs_date", "date")
stopifnot(nrow(long) == 9 * sum(!na_pat), !anyNA(long$date))

taxa <- make_taxa(toupper(names(species)), unname(species), vernacularName = vern,
                  taxonRank = ifelse(names(species) == "pelcom", "species complex", "species"))
dataset <- list(
  title = "Detection/non-detection of nine amphibian species at 100 ponds in Hungary over three combined-method surveys, 2023",
  creator = "Hamer, Andrew J.; Horanyi, Julia", pubDate = "2024", doi = "10.5061/dryad.70rxwdc6w",
  sourceURL = "https://doi.org/10.5061/dryad.70rxwdc6w",
  citation = "Hamer, A. J., & Horanyi, J. (2024). Multi-species occupancy model for estimating the probability of detecting amphibian species in Hungary [Dataset]. Dryad. https://doi.org/10.5061/dryad.70rxwdc6w",
  paperDOI = "10.1002/ece3.70383",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Field surveys of 100 ponds in Hungary in spring-summer 2023 using three methods (visual encounter survey with aural census, dip-netting, newt trapping) on each of three visits, with environmental and climatic conditions recorded per survey, used to estimate community and species-specific detection probabilities of nine amphibian species.",
  samplingProtocol = "Three surveys per pond (19 March to late July 2023); each survey combined a time-constrained visual encounter survey and aural census, dip-netting and newt trapping; detection of eggs, larvae or post-metamorphic animals counts as a detection.",
  samplingProtocolCode = "ves_dipnet_trap", effortColumn = "obs_effort_ves_min",
  surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Ponds in Hungary (no coordinates deposited)", temporalCoverage = "2023-03/2023-07",
  coordinatesCoarsened = NA,
  notes = "PELCOM = Pelophylax water-frog complex, not resolved to species by the authors. Continuous covariates are shipped unstandardised (the deposited model code standardises them).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hamer_2024_hungary_amph_comm.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of nine amphibian species (eggs, larvae or adults) at 100 ponds in Hungary over three combined visual/dip-net/trap surveys in 2023, with eight per-survey covariates (date, VES effort, water temperature and level, wind, rain, fish, emergent vegetation).",
  url = "https://doi.org/10.5061/dryad.70rxwdc6w",
  reference = "Hamer, A. J., & Horanyi, J. (2024). Improving inference within freshwater community studies: Accounting for variable detection rates of amphibians and fish. Ecology and Evolution, 14(10), e70383.",
  doi_paper = "10.1002/ece3.70383", doi_data = "10.5061/dryad.70rxwdc6w",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Fetched as the Dryad version zip (per-file API downloads need a bearer token). One pond-survey (T9, survey 1) not conducted.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community occupancy",
  sampling_protocol = "ves_dipnet_trap", design = "Single-season (3 surveys)", realm = "Freshwater", country = "HUN",
  coordinates = "None in source", notes = "Nine species incl. the Pelophylax complex; all eight survey covariates shipped as obs_.",
  status = "tagged")
