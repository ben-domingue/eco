#!/usr/bin/env Rscript
# Table:  katuwal_2025_parsakoshi_leopard_binom
# Source: Dryad, doi:10.5061/dryad.w3r2280z2, version 337861 (published 2025-01-06), licence CC0 1.0 as shown on
#         the Dryad dataset page (asserted from the dataset JSON) and in the deposited README.
# Paper:  Katuwal, H. B., Bhattarai, B. P., Regmi, S., Bhandari, S., et al. (2025). Leopard occupancy correlates
#         with tiger and prey occurrences in the Parsa-Koshi Complex, Nepal. Journal of Zoology 325, 312-322.
#         https://doi.org/10.1111/jzo.13251 (not open access in Europe PMC; not read). The design is from the
#         Dryad abstract and README: 154 cameras on wildlife trails throughout the Parsa-Koshi Complex (Parsa
#         National Park to Koshi Tappu Wildlife Reserve, Madhesh Province), 21 days each, December 2022 to March
#         2023; weekly leopard detection.
# Data:   Leopard_data2.csv (154 rows x 9): Way Point (camera site id), Leopard (number of weeks, of the three
#           sampled, with a leopard detection), Building (distance to nearest settlement, m), Human (humans
#           detected at the camera, n), Livestock (livestock detected, n), Tiger (tiger detected at the camera,
#           1/0), prey (prey species detected, 1/0; the prey species are not listed), Water_1 (area of water
#           within 500 m, m2), Trees (forest area within 500 m, m2). README.md. No coordinates, no dates per camera.
# Mapping: responseType binomial_count (ruling #34): the weekly histories were collapsed by the source to 'weeks
#   with a detection'; unit = Way Point, taxon = PANPAR, y = Leopard, obs_trials = 3 (the README's three weeks
#   per camera; the abstract's 21 days each; per-camera operation days are not deposited, so 3 is the
#   protocol value for every camera). surveyEvidence = deposited_matrix: every camera of the deposit has a row.
#   Covariates ship as unit_* under descriptive names. Human, livestock, tiger and prey are detections at the
#   same cameras (other taxa), not outputs of the leopard model, so they ship (as feng_2021_nechina_mamm_binom).
#   IUCN: Panthera pardus VU, but no coordinates are deposited, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "katuwal_2025_parsakoshi_leopard_binom"

dir <- download_dryad("10.5061/dryad.w3r2280z2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("Leopard_data2.csv", "README.md")))
d <- fread(file.path(dir, "Leopard_data2.csv"))
stopifnot(identical(names(d), c("Way Point", "Leopard", "Building", "Human", "Livestock", "Tiger", "prey", "Water_1", "Trees")),
          nrow(d) == 154L, !anyDuplicated(d[["Way Point"]]), !anyNA(d),
          all(d$Leopard %in% 0:3), identical(as.vector(table(factor(d$Leopard, 0:3))), c(121L, 14L, 14L, 5L)),
          all(d$Tiger %in% 0:1), all(d$prey %in% 0:1), all(d$Human >= 0), all(d$Livestock >= 0),
          all(d$Building > 0), all(d$Water_1 >= 0), all(d$Trees >= 0), max(d$Trees) == 785900)   # just above pi * 500^2 = 785398 m2 (raster cells)

long <- d[, .(unit = as.character(`Way Point`), taxon = "PANPAR", y = as.integer(Leopard), obs_trials = 3L,
              unit_dist_settlement_m = Building, unit_humans_detected = as.integer(Human),
              unit_livestock_detected = as.integer(Livestock), unit_tiger_detected = as.integer(Tiger),
              unit_prey_detected = as.integer(prey), unit_water_area_500m_m2 = Water_1, unit_forest_area_500m_m2 = Trees)]
long <- order_eco(long)
stopifnot(nrow(long) == 154L, sum(long$y) == 57L, sum(long$y > 0) == 33L)

taxa <- make_taxa("PANPAR", "Panthera pardus", vernacularName = "Leopard")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))

dataset <- list(
  title = "Leopard detections over three weekly occasions at 154 camera sites, Parsa-Koshi Complex, Nepal, December 2022 to March 2023",
  creator = "Katuwal, Hem Bahadur; Bhattarai, Bishnu Prasad; Regmi, Sandeep; Bhandari, Shivish; Aryal, Bishnu; Tamang, Krishna; Nepali, Amrit; K.C., Sabin; Adhikari, Dipendra; Baral, Basu; Devkota, Surya; Koirala, Sabina; Mandal, Dev Narayan; Belant, Jerrold L.; Sharma, Hari Prasad; Quan, Rui-Chang",
  pubDate = "2025",
  doi = "10.5061/dryad.w3r2280z2", sourceURL = "https://doi.org/10.5061/dryad.w3r2280z2",
  citation = "Katuwal, H. B., Bhattarai, B. P., Regmi, S., Bhandari, S., Aryal, B., Tamang, K., Nepali, A., K.C., S., Adhikari, D., Baral, B., Devkota, S., Koirala, S., Mandal, D. N., Belant, J. L., Sharma, H. P., & Quan, R.-C. (2025). Leopard occupancy correlates with tiger and prey occurrences [Dataset]. Dryad. https://doi.org/10.5061/dryad.w3r2280z2",
  paperDOI = "10.1111/jzo.13251",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps at 154 stations on wildlife trails throughout the Parsa-Koshi Complex, Nepal (Parsa National Park to Koshi Tappu Wildlife Reserve), each run for 21 days between December 2022 and March 2023, to model leopard occupancy against tigers, prey and human activity. The deposit gives, per camera, the number of the three weeks in which a leopard was photographed (the weekly histories are not deposited), with distance to settlement, humans, livestock, tiger and prey detected at the camera, and water and forest area within 500 m.",
  samplingProtocol = "One camera trap per station on a wildlife trail, run for 21 days; the deployment split into three one-week occasions, y = weeks with a leopard photograph.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "binomial_count", effortColumn = "obs_trials", unitKind = "site",
  closure = "none", closureNote = "one season; the three weekly occasions of each 21-day deployment are collapsed by the source into obs_trials = 3 (the protocol value; per-camera operation days are not deposited).",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Parsa-Koshi Complex (Parsa National Park to Koshi Tappu Wildlife Reserve), Madhesh Province, Nepal (no coordinates deposited)",
  temporalCoverage = "2022-12/2023-03",
  covariateNote = "unit_dist_settlement_m: distance to nearest human settlement (m). unit_humans_detected, unit_livestock_detected: humans and livestock detected at the camera (counts as deposited; the counting rule is not stated). unit_tiger_detected, unit_prey_detected: tiger / any prey species detected at the camera (1/0; the prey species are not listed). unit_water_area_500m_m2, unit_forest_area_500m_m2: area of water bodies and of forest within 500 m of the camera (m2).",
  notShipped = list(model_output = "occupancy and detection estimates and the temporal-overlap analysis (not deposited)"),
  notes = "obs_trials = 3 for every camera is the protocol value (three weeks of a 21-day deployment); the deposit does not record camera failures. Panthera pardus is IUCN VU; no coordinates are deposited.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/katuwal_2025_parsakoshi_leopard_binom.R")
stage_dict_row(TABLE,
  description = "Number of weeks (of three) with a leopard camera detection at 154 camera stations in the Parsa-Koshi Complex, Nepal, December 2022 to March 2023, with human, livestock, tiger, prey and habitat covariates.",
  url = "https://doi.org/10.5061/dryad.w3r2280z2",
  reference = "Katuwal, H. B., Bhattarai, B. P., Regmi, S., Bhandari, S., et al. (2025). Leopard occupancy correlates with tiger and prey occurrences in the Parsa-Koshi Complex, Nepal. Journal of Zoology 325, 312-322. https://doi.org/10.1111/jzo.13251",
  doi_paper = "10.1111/jzo.13251", doi_data = "10.5061/dryad.w3r2280z2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Collapsed weekly detections (binomial_count, obs_trials = 3 per the README).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (binomial counts over weekly occasions)",
  sampling_protocol = "camera_trap", design = "Single-season (154 cameras, 3 weekly occasions collapsed to a count)",
  realm = "Terrestrial", country = "NPL", coordinates = "None in source",
  notes = "Leopard (VU), one species; tiger and prey detections as site covariates; no coordinates.")
