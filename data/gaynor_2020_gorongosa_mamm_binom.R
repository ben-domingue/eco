#!/usr/bin/env Rscript
# Table:  gaynor_2020_gorongosa_mamm_binom
# Source: Dryad doi:10.25349/D9CK5Q (CC0 1.0, as shown on the Dryad page; published 2020-11-10).
#         Gaynor, K.M., Daskin, J.H., Rich, L.N. & Brashares, J.S. Data from: Postwar wildlife
#         recovery in an African savanna: Evaluating patterns and drivers of species occupancy
#         and richness.
# Paper:  Gaynor, K.M., Daskin, J.H., Rich, L.N. & Brashares, J.S. (2021). Animal Conservation
#         24(3), doi:10.1111/acv.12661. A grid of 60 camera traps in Gorongosa National Park,
#         Mozambique; hierarchical multi-species occupancy.
# Data:   gaynor-animcons.zip -> gaynor-animcons-detections.csv (60 StudySite x 38 species:
#         "the number of days during the sample period for which that species was detected at
#         that location", README.pdf), gaynor-animcons-cammetadata.csv (60 sites: Operation =
#         length of the operation period in days (17-91), detect.obscured, cover.ground,
#         termite.count.100m, tree.hansen, fire.interval, road.major.distance, urema.distance,
#         hunting), gaynor-animcons-species.csv (code, genus, species, common name, family,
#         order, functional group), and the authors' JAGS scripts (N = Operation). The raw
#         detections are "available upon request". No coordinates; no survey dates.
# Mapping (ruling #34, binomial_count; E9 community occupancy): unit = StudySite; taxon =
#   SppCode; no occasion; y = days with a detection; obs_trials = Operation (effortColumn),
#   asserted y <= Operation everywhere. Every site carries all 38 species (complete matrix).
#   unit_: the eight site covariates; detect.obscured is the authors' detection covariate
#   (camera view obscured, 0/1) and is constant per site, so unit_. __taxa: family, order,
#   functional group. Survey evidence: deposited_matrix. Elephant (EN), lion and hippo (VU)
#   are included; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "gaynor_2020_gorongosa_mamm_binom"
dir <- download_dryad("10.25349/D9CK5Q", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^gaynor-animcons\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "gaynor-animcons")
det <- fread(file.path(b, "gaynor-animcons-detections.csv"))
cm <- fread(file.path(b, "gaynor-animcons-cammetadata.csv"))
sp <- fread(file.path(b, "gaynor-animcons-species.csv"))
stopifnot(nrow(det) == 60, nrow(cm) == 60, setequal(det$StudySite, cm$StudySite), !anyDuplicated(cm$StudySite),
          nrow(sp) == 38, identical(names(det)[-1], sp$SppCode), !anyNA(det), !anyNA(cm),
          all(cm$Operation >= 17 & cm$Operation <= 91), all(cm$detect.obscured %in% 0:1))
M <- as.matrix(det[, -1]); op <- cm$Operation[match(det$StudySite, cm$StudySite)]
stopifnot(all(M >= 0), all(M <= op), all(colSums(M) > 0))
long <- melt(det, id.vars = "StudySite", variable.name = "taxon", value.name = "y", variable.factor = FALSE)
long <- merge(long[, .(unit = StudySite, taxon, y = as.integer(y))],
              cm[, .(unit = StudySite, obs_trials = as.integer(Operation), unit_detect_obscured = detect.obscured,
                     unit_cover_ground = cover.ground, unit_termite_count_100m = termite.count.100m,
                     unit_tree_cover_hansen = tree.hansen, unit_fire_interval = fire.interval,
                     unit_road_major_distance_m = road.major.distance, unit_urema_distance_m = urema.distance,
                     unit_hunting = hunting)], by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 60 * 38, sum(long$y) == sum(M))
sci <- paste(trimws(sp$GenusLatin), trimws(sp$SpeciesLatin))
taxa <- make_taxa(sp$SppCode, sci, vernacularName = gsub("_", " ", sp$CommName),
                  taxon_family = sp$Family, taxon_order = sp$Order, taxon_functional_group = sp$FunctionalGroup)
dataset <- list(
  title = "Camera-trap detections of 38 mammal species at 60 stations in Gorongosa National Park, Mozambique: days with a detection out of days operated",
  creator = "Gaynor, Kaitlyn M.; Daskin, Joshua H.; Rich, Lindsey N.; Brashares, Justin S.", pubDate = "2020",
  doi = "10.25349/D9CK5Q", sourceURL = "https://doi.org/10.25349/D9CK5Q",
  citation = "Gaynor, K. M., Daskin, J. H., Rich, L. N., & Brashares, J. S. (2020). Data from: Postwar wildlife recovery in an African savanna: Evaluating patterns and drivers of species occupancy and richness [Dataset]. Dryad. https://doi.org/10.25349/D9CK5Q",
  paperDOI = "10.1111/acv.12661",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap survey of the large and medium mammal community on a grid of 60 camera traps in Gorongosa National Park, Mozambique (Gaynor et al. 2021): the number of days each of 38 species was detected at each camera out of the days the camera operated (17-91), with site covariates (ground cover, termite mounds, tree cover, fire interval, distances to road and Lake Urema, hunting) and species' functional groups.",
  samplingProtocol = "A grid of 60 passive camera traps in the woodland savanna of southern Gorongosa National Park, each operated for up to 91 days; species identified from photographs and detections collapsed by the authors to days with a detection per camera and species.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every camera has an explicit day count for all 38 species and its operation period in days (Operation, the authors' binomial N); which days it operated is not deposited, so there is no occasion column (ruling #34).",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "single season; one deployment per camera analysed as single-season multi-species occupancy",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Gorongosa National Park, Sofala Province, Mozambique; no coordinates deposited",
  temporalCoverage = "survey year not stated in the deposit (paper 2021; cameras operated up to 91 days)",
  notShipped = list(raw_detections = "image-level records, not deposited (available from the authors on request)"),
  notes = "Elephant (IUCN EN), lion and hippopotamus (VU) are among the 38 species; no coordinates are deposited. 'Helogale ' carries a trailing space in the deposit (trimmed). unit_detect_obscured is the authors' detection covariate, constant per camera.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/gaynor_2020_gorongosa_mamm_binom.R")
stage_dict_row(TABLE,
  description = "Camera-trap days-with-detection out of days operated for 38 mammal species at 60 stations in Gorongosa National Park, Mozambique, with site covariates and functional groups.",
  url = "https://doi.org/10.25349/D9CK5Q",
  reference = "Gaynor, K. M., Daskin, J. H., Rich, L. N., & Brashares, J. S. (2021). Postwar wildlife recovery in an African savanna: Evaluating patterns and drivers of species occupancy and richness. Animal Conservation, 24(3).",
  doi_paper = "10.1111/acv.12661", doi_data = "10.25349/D9CK5Q", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "binomial_count (ruling #34).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season, binomial counts)",
  sampling_protocol = "camera_trap", design = "Single-season (60 cameras, days collapsed to binomial counts)", realm = "Terrestrial",
  country = "MOZ", coordinates = "None in source", notes = "binomial_count (ruling #34); functional groups in __taxa.")
