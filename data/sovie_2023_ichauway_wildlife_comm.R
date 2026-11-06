#!/usr/bin/env Rscript
# Table:  sovie_2023_ichauway_wildlife_comm
# Source: Dryad, doi:10.5061/dryad.c59zw3rdb, version 237508 (version 5, published 2023-05-29), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Sovie, A. R. et al. (2023). At a fine scale, hardwood patches support wildlife diversity in longleaf
#         pine woodlands. Wildlife Letters. https://doi.org/10.1002/wll2.12018 (not read: the publisher page
#         refuses scripted requests). The design is from the deposit's methods (Dryad page) and the comments of
#         the deposited R script: camera traps in and around hardwood patches in a longleaf pine woodland at
#         The Jones Center at Ichauway, Newton, Georgia; within each patch four perpendicular transects of three
#         cameras (10 m into the pine, at the patch edge, 10 m into the hardwood), baited with pecans and
#         cracked corn (re-baited every 5 days), deployed five times per patch for 10-15 days each; detections
#         collapsed by the authors to 5-day occasions; camera failure = NA. The methods say five patches and
#         that community data stopped after two deployments in two patches; the deposit (README and R script)
#         has 6 patches x 12 cameras x 8 occasions.
# Data:   Sovie_etal_2023_MSOM_detection_matrix.csv: header Patch, Site, then 11 blocks of 8 columns named by
#           species (Armadillo, Chipmunk, Deer, Flying_Squirrel, Fox_Squirrel, Gray_Squirrel, Opossum, Quail,
#           Rabbit, Raccoon, Turkey); 72 rows = cameras (Site "<Patch><n>.accdb", 12 per patch: Box, Control,
#           Cow, MFM, Pond, Road); cells 0 / 1 / NA (NA = camera inactive). NA pattern identical across the 11
#           species (asserted): 198 camera-occasions NA; Box and Control cameras have all 8 occasions; one MFM
#           camera is NA throughout (never active: no rows, so 71 units).
#         VegCovs.csv: Site, vo (mean Robel-pole visual obstruction), patch, loc (1 open pine, 2 edge, 3 closed
#           hardwood canopy); 4 cameras of each loc per patch (asserted).
#         Sovie_etal_2023_MSOM_r_code.R (the authors' JAGS MSOM; not used). README.md.
# Mapping: community occupancy, single season. unit = camera (Site without ".accdb"), cluster_id = patch,
#   taxon = 11 codes, occasion = 5-day occasion 1..8 (no dates deposited), y = 0/1. unit_canopy_position =
#   loc as open_pine / edge / hardwood, unit_visual_obstruction = vo. surveyEvidence = deposited_matrix (NA).
#   Taxa: the deposit gives common names only. Armadillo, fox squirrel, gray squirrel and opossum are named
#   in the abstract; Chipmunk, Deer, Flying_Squirrel, Quail, Raccoon and Turkey are resolved to the one
#   species of that name in southwest Georgia (taxonRemarks says so); Rabbit is kept at genus Sylvilagus
#   (eastern cottontail and marsh rabbit both occur there). No coordinates; no flagged taxon (bobwhite NT).
#   Not shipped: occupancy and detection estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sovie_2023_ichauway_wildlife_comm"

dir <- download_dryad("10.5061/dryad.c59zw3rdb", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("README.md", "Sovie_etal_2023_MSOM_detection_matrix.csv",
                                      "Sovie_etal_2023_MSOM_r_code.R", "VegCovs.csv")))
raw <- fread(file.path(dir, "Sovie_etal_2023_MSOM_detection_matrix.csv"), header = FALSE, colClasses = "character")
hdr <- unlist(raw[1]); raw <- raw[-1]
SPN <- c("Armadillo", "Chipmunk", "Deer", "Flying_Squirrel", "Fox_Squirrel", "Gray_Squirrel", "Opossum", "Quail",
         "Rabbit", "Raccoon", "Turkey")
stopifnot(identical(unname(hdr), c("Patch", "Site", rep(SPN, each = 8))), nrow(raw) == 72L,
          identical(as.vector(table(raw$V1)), rep(12L, 6)), all(grepl("^[A-Za-z]+[0-9]+\\.accdb$", raw$V2)),
          all(sub("[0-9]+\\.accdb$", "", raw$V2) == raw$V1), !anyDuplicated(raw$V2))
M <- as.matrix(raw[, -(1:2)])
stopifnot(all(M %in% c("0", "1", NA)))
A <- array(NA_integer_, c(72, 8, 11))
for (i in seq_along(SPN)) A[, , i] <- suppressWarnings(as.integer(M[, hdr[-(1:2)] == SPN[i]]))
NAp <- is.na(A[, , 1])
stopifnot(all(apply(is.na(A), 3, identical, NAp)), sum(NAp) == 198L, sum(rowSums(NAp) == 8L) == 1L, raw$V1[rowSums(NAp) == 8L] == "MFM",
          all(rowSums(!NAp)[raw$V1 %in% c("Box", "Control")] == 8L))
det <- apply(A, 3, sum, na.rm = TRUE)
stopifnot(identical(as.integer(det), c(40L, 10L, 8L, 11L, 20L, 166L, 106L, 7L, 3L, 197L, 2L)))

veg <- fread(file.path(dir, "VegCovs.csv"))
stopifnot(nrow(veg) == 72L, setequal(veg$Site, raw$V2), all(veg$patch == raw$V1[match(veg$Site, raw$V2)]),
          all(veg$loc %in% 1:3), veg[, .N, by = .(patch, loc)][, all(N == 4L)], !anyNA(veg$vo), all(veg$vo >= 0))
veg <- veg[match(raw$V2, Site)]

CODE <- c("DASNOV", "TAMSTR", "ODOVIR", "GLAVOL", "SCINIG", "SCICAR", "DIDVIR", "COLVIR", "SYLVIL", "PROLOT", "MELGAL")
unit <- sub("\\.accdb$", "", raw$V2)
long <- rbindlist(lapply(seq_along(SPN), function(i) data.table(
  unit = rep(unit, 8), cluster_id = rep(raw$V1, 8), taxon = CODE[i], occasion = rep(1:8, each = 72),
  y = as.vector(A[, , i]),
  unit_canopy_position = rep(c("open_pine", "edge", "hardwood")[veg$loc], 8),
  unit_visual_obstruction = rep(veg$vo, 8))))
long <- long[!is.na(y)]
long <- order_eco(long)
stopifnot(nrow(long) == 11L * (72L * 8L - 198L), sum(long$y) == sum(det))
cat(sprintf("  %d rows, %d camera-occasions, %d detections\n", nrow(long), nrow(long) / 11L, sum(long$y)))

one <- "the deposit gives the common name only; resolved to the only species of that name in southwest Georgia"
taxa <- make_taxa(CODE,
  c("Dasypus novemcinctus", "Tamias striatus", "Odocoileus virginianus", "Glaucomys volans", "Sciurus niger",
    "Sciurus carolinensis", "Didelphis virginiana", "Colinus virginianus", "Sylvilagus", "Procyon lotor",
    "Meleagris gallopavo"),
  vernacularName = c("Nine-banded armadillo", "Eastern chipmunk", "White-tailed deer", "Southern flying squirrel",
                     "Fox squirrel", "Eastern gray squirrel", "Virginia opossum", "Northern bobwhite",
                     "Rabbit (cottontail or marsh rabbit)", "Raccoon", "Wild turkey"),
  taxonRank = c(rep("species", 8), "genus", rep("species", 2)),
  taxon_deposited_name = SPN,
  taxonRemarks = c(NA, one, one, one, NA, NA, NA, one,
                   "deposited as 'Rabbit'; kept at genus: eastern cottontail and marsh rabbit both occur at Ichauway",
                   one, one))
iu <- iucn_category(taxa$taxonID, taxa$scientificName)
print(setNames(iu, taxa$taxon))
stopifnot(!any(iu %in% c("CR", "EN", "VU")))

dataset <- list(
  title = "Five-day camera detections of 11 mammal and game-bird species at 71 working baited cameras (72 deployed) across longleaf pine to hardwood-patch edges, Ichauway, Georgia",
  creator = "Sovie, Adia", pubDate = "2023",
  doi = "10.5061/dryad.c59zw3rdb", sourceURL = "https://doi.org/10.5061/dryad.c59zw3rdb",
  citation = "Sovie, A. (2023). Data for: At a fine scale, hardwood patches support wildlife diversity in longleaf pine woodlands [Dataset]. Dryad. https://doi.org/10.5061/dryad.c59zw3rdb",
  paperDOI = "10.1002/wll2.12018",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps on transects across the edges of hardwood patches embedded in longleaf pine woodland at The Jones Center at Ichauway, Georgia (a camera 10 m into the pine, one at the edge, one 10 m into the hardwood), to test how mid-sized mammals and game birds use the pine-hardwood transition. Detection/non-detection of 11 species per camera and 5-day occasion.",
  samplingProtocol = "Baited camera traps (pecans and cracked corn, re-baited every 5 days), 50 cm above ground, 3-photo bursts with a 3-minute rest, deployed repeatedly for 10-15 days; photos of a species more than 20 minutes apart are independent; the authors collapsed detections to 5-day occasions; camera failure is NA.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "eight 5-day occasions treated by the authors as one closed season (a single-season multi-species occupancy model); the dates of the occasions are not deposited.",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "The Jones Center at Ichauway, Newton, Baker County, Georgia, USA (no coordinates deposited)",
  temporalCoverage = "field dates not stated in the deposit (IACUC protocol 201709855; deposit published 2023-05)",
  covariateNote = "cluster_id: hardwood patch (12 cameras each; four transects of three cameras). unit_canopy_position: open_pine (10 m into the longleaf pine), edge, hardwood (10 m into the patch), the source's loc 1/2/3. unit_visual_obstruction: mean Robel-pole visual obstruction in front of the camera, as deposited.",
  notShipped = list(model_output = "occupancy and detection estimates", analysis_script = "Sovie_etal_2023_MSOM_r_code.R (JAGS MSOM)"),
  notes = "Occasion dates are not deposited. The deposit's methods describe five patches; the data (and README) hold six (Box, Control, Cow, MFM, Pond, Road). Cameras in Box and Control have all 8 occasions; the others 2 to 7, and one MFM camera has none (no rows; 71 cameras in the table). Rabbit is at genus Sylvilagus. The deposit gives no field dates.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/sovie_2023_ichauway_wildlife_comm.R")
stage_dict_row(TABLE,
  description = "Five-day camera detections of 11 mammal and game-bird species at 71 working baited cameras (72 deployed) on open-pine / edge / hardwood transects across six hardwood patches, Ichauway, Georgia, USA.",
  url = "https://doi.org/10.5061/dryad.c59zw3rdb",
  reference = "Sovie, A. R. et al. (2023). At a fine scale, hardwood patches support wildlife diversity in longleaf pine woodlands. Wildlife Letters. https://doi.org/10.1002/wll2.12018",
  doi_paper = "10.1002/wll2.12018", doi_data = "10.5061/dryad.c59zw3rdb",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Common names only in the deposit; species assigned where one species of the name occurs regionally, rabbit at genus.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Community occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (8 five-day occasions; 71 working cameras in 6 patches)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Edge-gradient camera transects (pine, edge, hardwood); occasion dates not deposited.")
