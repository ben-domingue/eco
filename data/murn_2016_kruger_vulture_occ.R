#!/usr/bin/env Rscript
# Table:  murn_2016_kruger_vulture_occ
# Source: Dryad doi:10.5061/dryad.72j20 (CC0 1.0, as shown on the Dryad page; published
#         2016-09-08). Murn, C. & Holloway, G.J. Data from: Using areas of known occupancy to
#         identify sources of variation in detection probability of raptors: taking time lowers
#         replication effort for surveys.
# Paper:  Murn, C. & Holloway, G.J. (2016). Royal Society Open Science 3: 160368,
#         doi:10.1098/rsos.160368. White-headed vulture (Trigonoceps occipitalis, IUCN CR)
#         breeding territories of known occupancy; detection histories from 359 territory visits
#         (abstract).
# Data:   "Murn & Holloway data.xls", nine sheets. "Detection history": rows 2-18 = 17 territories
#         (nest names) x 47 visit columns (1 seen / 0 not / "-" no visit) followed by three
#         summary columns (visits, detections, visits per detection); rows 20-21 hold totals
#         (359 visits, 72 detections, asserted); rows 22-37 repeat the histories for 16 of the
#         territories (all but Nkumbe) and are not used. "Site covariates" (ecozone, landscape,
#         habitat rating, ruggedness, drainage and two indices built from them); per-visit
#         sheets "Date", "Entry time", "Duration", "Avg speed", "Travel mode", "Foot time",
#         "Distance" (17 x 47, "-" exactly where no visit, asserted). The deposit has no README;
#         units and the meaning of the Date and Travel mode codes are not stated. The site sheet lists
#         the territories in the same order, spelling two differently (Boeyla 10, Tihongonyeni 09).
# Mapping (standard: single-season occupancy, E9 core; occupancy known = 1 by design):
#   unit = territory; taxon = TRIOCC; occasion = visit 1..47; y = seen. obs_: entry time, visit
#   duration, average speed, time on foot, distance (as deposited, units in the paper);
#   obs_date_code and obs_travel_mode_code as deposited codes (undefined in the deposit). unit_:
#   ecozone, landscape, habitat rating, ruggedness, drainage. Survey evidence: deposited_matrix.
#   Not shipped: the second history block (a copy without Nkumbe), the summary columns and
#   totals, the two site indices (products of the shipped ratings). The vulture is IUCN CR; no
#   coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "murn_2016_kruger_vulture_occ"
dir <- download_dryad("10.5061/dryad.72j20", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "\\.xls$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
rd <- function(s) as.data.frame(suppressMessages(read_excel(f, s, col_names = FALSE, col_types = "text")))
d <- rd("Detection history")
nm <- d[2:18, 1]; H <- as.matrix(d[2:18, 2:48]); dimnames(H) <- list(nm, NULL)
stopifnot(!anyDuplicated(nm), all(H %in% c("0", "1", "-")), sum(H %in% c("0", "1")) == 359, sum(H == "1") == 72,
          as.numeric(d[20, 49]) == 359, as.numeric(d[20, 50]) == 72,
          all(as.integer(d[2:18, 49]) == rowSums(H != "-")), setequal(d[22:37, 1], setdiff(nm, "Nkumbe")))
cov <- function(s) { x <- rd(s); stopifnot(identical(x[1:17, 1], nm)); m <- as.matrix(x[1:17, 2:48]); stopifnot(all((m == "-" | is.na(m)) == (H == "-"))); m[H == "-"] <- NA; m }
num <- function(m) { storage.mode(m) <- "numeric"; m }
Y <- H; Y[Y == "-"] <- NA; Y <- num(Y)
oc <- list(entry_time = num(cov("Entry time")), duration = num(cov("Duration")), avg_speed = num(cov("Avg speed")),
           foot_time = num(cov("Foot time")), distance = num(cov("Distance")), date_code = cov("Date"), travel_mode_code = cov("Travel mode"))
sc <- rd("Site covariates"); hdr <- as.character(sc[1, ]); sc <- sc[-1, ]
stopifnot(identical(hdr[1:6], c("Location, pair name", "Ecozone", "Landscape (Venter)", "Habitat rating", "Ruggedness", "Drainage")))
sc <- sc[!is.na(sc[[1]]), ]
# same order as the histories; two names spelled differently ("Boeyla 10", "Tihongonyeni 09")
stopifnot(nrow(sc) == 17, sum(sc[[1]] != nm) == 2, identical(sc[[1]][sc[[1]] != nm], c("Boeyla 10", "Tihongonyeni 09")))
scv <- data.frame(ecozone = sc[[2]], landscape_venter = sc[[3]], habitat_rating = as.numeric(sc[[4]]), ruggedness = as.numeric(sc[[5]]),
                  drainage = as.numeric(sc[[6]]))
long <- array_to_eco(Y, taxon = "TRIOCC", site_ids = nm, site_covs = scv, obs_covs = oc)
long <- order_eco(long)
stopifnot(nrow(long) == 359, sum(long$y) == 72)
taxa <- make_taxa("TRIOCC", "Trigonoceps occipitalis", vernacularName = "White-headed vulture")
dataset <- list(
  title = "White-headed vulture sightings on 359 visits to 17 known breeding territories in Kruger National Park, South Africa",
  creator = "Murn, Campbell; Holloway, Graham J.", pubDate = "2016", doi = "10.5061/dryad.72j20", sourceURL = "https://doi.org/10.5061/dryad.72j20",
  citation = "Murn, C., & Holloway, G. J. (2016). Data from: Using areas of known occupancy to identify sources of variation in detection probability of raptors: taking time lowers replication effort for surveys [Dataset]. Dryad. https://doi.org/10.5061/dryad.72j20",
  paperDOI = "10.1098/rsos.160368",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the white-headed vulture (Trigonoceps occipitalis, IUCN CR) on 359 visits to 17 breeding territories of known occupancy in Kruger National Park, with visit time, duration, speed, time on foot, distance and travel mode, and territory habitat and topography ratings: data for estimating detection probability where occupancy is 1 by design.",
  samplingProtocol = "Repeated visits by vehicle and on foot to known white-headed vulture breeding territories; the vulture recorded as seen or not on each visit, with entry time, duration, average speed, distance and time on foot.",
  samplingProtocolCode = "territory_survey", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "territories known to be occupied throughout; the authors fixed occupancy at 1", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = "Kruger National Park, South Africa; no coordinates deposited",
  temporalCoverage = "survey dates not stated in the deposit (paper 2016)",
  notShipped = list(second_block = "rows 22-37 of the detection sheet, a copy of the histories without Nkumbe", summaries = "per-territory summary columns and the totals rows",
                    site_indices = "topography and habitat indices, products of the shipped ratings"),
  notes = "Occupancy is known to be 1 at every territory (the study design). Covariate units and the Date and Travel mode codes are not defined in the deposit (see the paper); they are shipped as deposited. The white-headed vulture is IUCN CR; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/murn_2016_kruger_vulture_occ.R")
stage_dict_row(TABLE, description = "White-headed vulture detections on 359 visits to 17 known breeding territories in Kruger National Park, with visit covariates.",
  url = "https://doi.org/10.5061/dryad.72j20", reference = "Murn, C., & Holloway, G. J. (2016). Using areas of known occupancy to identify sources of variation in detection probability of raptors. Royal Society Open Science, 3, 160368.",
  doi_paper = "10.1098/rsos.160368", doi_data = "10.5061/dryad.72j20", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Known-occupancy detection data (occupancy 1 by design).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy (detection only; occupancy known)",
  sampling_protocol = "territory_survey", design = "Single-season (up to 47 visits per territory)", realm = "Terrestrial",
  country = "ZAF", coordinates = "None in source", notes = "IUCN CR vulture.")
