#!/usr/bin/env Rscript
# Table:  regmi_2024_madhesh_tiger_binom
# Source: Dryad doi:10.5061/dryad.5tb2rbpbk (CC0 1.0, as shown on the Dryad page and README;
#         published 2024-12-31). Regmi, S. et al. Tiger occurrence in response to prey and
#         anthropogenic disturbances.
# Paper:  Regmi, S. et al. (2025). Proceedings of the Royal Society B, doi:10.1098/rspb.2024.1939.
#         Camera traps in Parsa, Bara and Rautahat districts, Madhesh Province, Nepal, December
#         2022 - March 2023 (README).
# Data:   Tiger.csv (94 camera stations: Way Point; cc (canopy cover); Human, Livestock (counts on
#         the same cameras); distances to road, water, building; then Tiger, Barkingdeer, Bluebull,
#         Chital, Gaur, Sambar, Wildboar = "the number of detected week across total weeks
#         surveyed (three)" (README), 0-3, asserted).
# Mapping (ruling #34, binomial_count; community of tiger and six prey): unit = Way Point; taxon
#   = species code; y = weeks with a detection; obs_trials = 3 at every station (the README's
#   three weeks); unit_: canopy cover, distances. Survey evidence: deposited_matrix.
#   Not shipped: Human and Livestock (detections of people and livestock on the same cameras).
#   Tiger is IUCN EN, gaur and sambar VU; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "regmi_2024_madhesh_tiger_binom"
dir <- download_dryad("10.5061/dryad.5tb2rbpbk", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Tiger\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f)
SP <- c(Tiger = "Panthera tigris", Barkingdeer = "Muntiacus vaginalis", Bluebull = "Boselaphus tragocamelus", Chital = "Axis axis",
        Gaur = "Bos gaurus", Sambar = "Rusa unicolor", Wildboar = "Sus scrofa")
stopifnot(identical(names(d), c("Way Point", "cc", "Human", "Livestock", "Road", "Water", "Building", names(SP))), nrow(d) == 94,
          !anyDuplicated(d$`Way Point`), !anyNA(d), all(as.matrix(d[, names(SP), with = FALSE]) %in% 0:3))
code <- c(Tiger = "PANTIG", Barkingdeer = "MUNVAG", Bluebull = "BOSTRA", Chital = "AXIAXI", Gaur = "BOSGAU", Sambar = "RUSUNI", Wildboar = "SUSSCR")
long <- melt(d[, c("Way Point", "cc", "Road", "Water", "Building", names(SP)), with = FALSE], id.vars = c("Way Point", "cc", "Road", "Water", "Building"),
             variable.name = "sp", value.name = "y", variable.factor = FALSE)
long <- order_eco(long[, .(unit = as.character(`Way Point`), taxon = code[sp], y = as.integer(y), obs_trials = 3L,
                           unit_canopy_cover = cc, unit_dist_road = Road, unit_dist_water = Water, unit_dist_building = Building)])
stopifnot(nrow(long) == 94 * 7)
taxa <- make_taxa(unname(code), unname(SP), vernacularName = c("Tiger", "Northern red muntjac (barking deer)", "Nilgai (blue bull)", "Chital", "Gaur", "Sambar", "Wild boar"),
                  taxonRemarks = c(NA, "deposited as 'Barkingdeer'; Muntiacus vaginalis is the barking deer of the Nepal Tarai", NA, NA, NA, NA, NA))
dataset <- list(
  title = "Camera-trap detections of tiger and six prey species at 94 stations in Madhesh Province, Nepal: weeks with a detection out of three, winter 2022-23",
  creator = "Regmi, Sandeep; Sharma, Hari Prasad; Bhattarai, Bishnu Prasad; Shaner, Pei-Jen Lee; Bhandari, Shivish; Nepali, Amrit; Aryal, Bishnu; Tamang, Krishna; K. C., Sabin; Karki, Ajay; Ram, Ashok Kumar; Belant, Jerrold L.; Katuwal, Hem Bahadur",
  pubDate = "2024", doi = "10.5061/dryad.5tb2rbpbk", sourceURL = "https://doi.org/10.5061/dryad.5tb2rbpbk",
  citation = "Regmi, S. et al. (2024). Tiger occurrence in response to prey and anthropogenic disturbances [Dataset]. Dryad. https://doi.org/10.5061/dryad.5tb2rbpbk",
  paperDOI = "10.1098/rspb.2024.1939",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Weeks with a detection out of three surveyed weeks for tiger and six prey species (barking deer, nilgai, chital, gaur, sambar, wild boar) at 94 camera-trap stations in Parsa, Bara and Rautahat districts, Nepal, December 2022 - March 2023, with canopy cover and distances to roads, water and buildings.",
  samplingProtocol = "Camera-trap stations surveyed for three weeks each in Parsa National Park and adjoining districts; detections collapsed by the authors to the number of weeks with a detection per species.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every station has a value for every species and the README states three surveyed weeks per station; which weeks were detections is not deposited (ruling #34).",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "no occasion column; one three-week deployment per station (the authors' single-season occupancy)", occasionKind = "none",
  taxonInclusion = "target", geographicCoverage = "Parsa, Bara and Rautahat districts, Madhesh Province, Nepal; no coordinates deposited",
  temporalCoverage = "2022-12/2023-03",
  notShipped = list(Human = "people detected on the same cameras", Livestock = "livestock detected on the same cameras"),
  notes = "Tiger is IUCN EN, gaur and sambar VU; no coordinates are deposited. Distances are as deposited (units not stated; metres by their magnitude).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/regmi_2024_madhesh_tiger_binom.R")
stage_dict_row(TABLE, description = "Camera-trap weeks-with-detection out of three for tiger and six prey at 94 stations in Madhesh Province, Nepal, 2022-23.",
  url = "https://doi.org/10.5061/dryad.5tb2rbpbk", reference = "Regmi, S. et al. (2025). Tiger occurrence in response to prey and anthropogenic disturbances. Proceedings of the Royal Society B.",
  doi_paper = "10.1098/rspb.2024.1939", doi_data = "10.5061/dryad.5tb2rbpbk", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "binomial_count (ruling #34).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season, binomial counts)",
  sampling_protocol = "camera_trap", design = "Single-season (3 weeks collapsed to binomial counts)", realm = "Terrestrial",
  country = "NPL", coordinates = "None in source", notes = "binomial_count; tiger and prey.")
