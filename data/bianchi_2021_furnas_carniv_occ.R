#!/usr/bin/env Rscript
# Table:  bianchi_2021_furnas_carniv_occ
# Source: Dryad doi:10.5061/dryad.0cfxpnw2g (CC0 1.0, as shown on the Dryad page; published
#         2021-06-16). Bianchi, R., Jenkins, J., Lesmeister, D. et al. Tayra (Eira barbara)
#         landscape use as a function of cover types, forest protection, and the presence of puma
#         and free-ranging dogs.
# Paper:  Bianchi, R. et al. (2021). Biotropica, doi:10.1111/btp.13005. Unbaited camera traps at
#         60 intersections of a 1 km2 grid inside (44) and outside (16) Furnas do Bom Jesus State
#         Park, Sao Paulo, Brazil, January - August 2017; three cameras failed (57 sites);
#         60-132 days per camera, "nine 12-day sampling occasions" (Dryad methods).
# Data:   Covariates_detection.xlsx: tayra_detection, puma_detection, dog_detection (57 units x
#         occasions 1-9: 0/1, "-" = no occasion; identical "-" pattern in the three, asserted);
#         day, prec, temp (per occasion: day index, precipitation, temperature; "-" where no
#         occasion); covariates (57 units: dense / open vegetation, coffee, pasture, buildings
#         within 500 / 200 / 100 m; slope, road, urban, water; preyTayra, preyDog, preyPuma; IN =
#         inside the park).
# Mapping (standard: community / multi-species occupancy, E9 core): unit = unit id; taxon =
#   EIRBAR, PUMCON, CANFAM; occasion = 12-day occasion 1..9; y = the cell; "-" = no row. obs_:
#   day, precipitation, temperature as deposited. unit_: land-cover proportions, slope, road,
#   urban, water, inside_park. Survey evidence: deposited_matrix. Not shipped: preyTayra,
#   preyDog, preyPuma (prey indices; their source is not stated and they may come from the same
#   cameras). No coordinates; all three taxa are IUCN LC (dog domestic).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bianchi_2021_furnas_carniv_occ"
dir <- download_dryad("10.5061/dryad.0cfxpnw2g", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Covariates_detection\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
rd <- function(s) { d <- as.data.frame(suppressMessages(read_excel(f, s, col_names = FALSE, col_types = "text"))); m <- as.matrix(d[-1, 2:10]); dimnames(m) <- list(d[-1, 1], NULL); m }
SP <- c(tayra = "EIRBAR", puma = "PUMCON", dog = "CANFAM")
D <- lapply(names(SP), function(s) rd(paste0(s, "_detection"))); names(D) <- names(SP)
ids <- rownames(D$tayra)
stopifnot(length(ids) == 57, !anyDuplicated(ids), all(sapply(D, function(m) identical(rownames(m), ids) && identical(m == "-", D$tayra == "-"))),
          all(unlist(D) %in% c("0", "1", "-")))
Y <- array(NA_integer_, dim = c(57, 9, 3), dimnames = list(ids, NULL, unname(SP)))
for (s in names(SP)) { m <- D[[s]]; m[m == "-"] <- NA; Y[, , SP[s]] <- matrix(as.integer(m), 57) }
oc <- function(s) { m <- rd(s); stopifnot(identical(rownames(m), ids)); m[D$tayra == "-" | m == "-"] <- NA; matrix(as.numeric(m), 57) }
cv <- as.data.frame(suppressMessages(read_excel(f, "covariates", col_names = TRUE)))
names(cv)[1] <- "unit"; stopifnot(identical(cv$unit, ids))
sc <- cv[, c("dense500", "dense200", "dense100", "open500", "open200", "open100", "coffee500", "coffee200", "coffee100",
             "pasto500", "pasto200", "pasto100", "builds500", "builds200", "builds100", "slope", "road", "urban", "water", "IN")]
names(sc) <- c(names(sc)[1:9], "pasture500", "pasture200", "pasture100", names(sc)[13:19], "inside_park")
long <- array_to_eco(Y, site_ids = ids, site_covs = sc, obs_covs = list(day = oc("day"), precipitation = oc("prec"), temperature = oc("temp")))
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(Y[, , 1])) * 3, sum(long$y) == 45 + 13 + 55)
taxa <- make_taxa(unname(SP), c("Eira barbara", "Puma concolor", "Canis familiaris"), vernacularName = c("Tayra", "Puma", "Free-ranging domestic dog"))
dataset <- list(
  title = "Camera-trap detections of tayra, puma and free-ranging dogs at 57 sites in and around Furnas do Bom Jesus State Park, Brazil, nine 12-day occasions, 2017",
  creator = "Bianchi, Rita; Jenkins, Julianna; Lesmeister, Damon; Gouvea, Jéssica; Cesário, Clarice; Fornitano, Larissa; Oliveira, Mateus; Morais, Kimberly; Ribeiro, Renan; Gompper, Matthew",
  pubDate = "2021", doi = "10.5061/dryad.0cfxpnw2g", sourceURL = "https://doi.org/10.5061/dryad.0cfxpnw2g",
  citation = "Bianchi, R. et al. (2021). Tayra (Eira barbara) landscape use as a function of cover types, forest protection, and the presence of puma and free-ranging dogs [Dataset]. Dryad. https://doi.org/10.5061/dryad.0cfxpnw2g",
  paperDOI = "10.1111/btp.13005",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of tayra, puma and free-ranging domestic dogs in up to nine 12-day occasions at 57 unbaited camera-trap sites on a 1 km2 grid inside and outside Furnas do Bom Jesus State Park, a cerrado landscape in São Paulo State, Brazil, January - August 2017, with occasion day, precipitation and temperature and land-cover covariates.",
  samplingProtocol = "Unbaited camera traps at 1 km2 grid intersections, operating 24 h for 60-132 days, checked every 15-20 days; detections summarised in 12-day occasions.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one deployment per site; the authors' single-season multi-species occupancy", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Furnas do Bom Jesus State Park and surroundings, Pedregulho, São Paulo State, Brazil; no coordinates deposited",
  temporalCoverage = "2017-01/2017-08",
  notShipped = list(prey_indices = "preyTayra, preyDog, preyPuma: prey indices whose source the deposit does not state (possibly the same cameras)"),
  notes = "obs_day, obs_precipitation and obs_temperature are as deposited per occasion (day index and units as in the paper).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bianchi_2021_furnas_carniv_occ.R")
stage_dict_row(TABLE, description = "Camera-trap detections of tayra, puma and free-ranging dogs at 57 sites around Furnas do Bom Jesus State Park, Brazil, 2017, nine 12-day occasions.",
  url = "https://doi.org/10.5061/dryad.0cfxpnw2g", reference = "Bianchi, R. et al. (2021). Tayra (Eira barbara) landscape use as a function of cover types, forest protection, and the presence of puma and free-ranging dogs. Biotropica.",
  doi_paper = "10.1111/btp.13005", doi_data = "10.5061/dryad.0cfxpnw2g", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-species occupancy (three species).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-species occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (nine 12-day occasions)", realm = "Terrestrial",
  country = "BRA", coordinates = "None in source", notes = "Tayra, puma, dogs.")
