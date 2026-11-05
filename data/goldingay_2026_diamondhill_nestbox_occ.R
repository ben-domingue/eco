#!/usr/bin/env Rscript
# Table:  goldingay_2026_diamondhill_nestbox_occ
# Source: Dryad, doi:10.5061/dryad.j3tx95xwd, version 462723 (version 5, published 2026-09-10), licence CC0 1.0
#         as shown on the Dryad page.
# Paper:  Goldingay, R., Thomas, K. & Quin, D. (2026). Can artificial tree cavities provide population support to
#         cavity-dependent non-flying mammals? Ecology and Evolution. https://doi.org/10.1002/ece3.74280
# Data:   Table_1_All_phascogales_nest_box_detections.csv: 74 nest-box clusters ("Sites" 1..74, "Number of
#           boxes" 2-4, 165 boxes in all; the paper says 164) x 12 censuses labelled May-18, Oct-18, May-19,
#           Oct-19, May-20, Oct-20, Jun-21, Oct-21, May-22, Nov-22, May-23, Oct-23; 1 = a brush-tailed phascogale
#           in any box of the cluster, 0 = none, "-" = cluster not surveyed (14 cells: 6 clusters before
#           May-19, cluster 74 before May-20).
#         Table_3_Sugar_gliders_nest_box_detections.csv: the same 74 x 12 for the inland sugar glider (no box
#           count column); same "-" pattern except cluster 74 at May-20, "-" for gliders and 0 for phascogales
#           (asserted); census 10 labelled Oct-22 instead of Nov-22.
#         Table_2_Female_phascogales_nest_box_detections.csv: 74 x 10 censuses from May-19 (sexing began in
#           2019), last labelled Nov-23; female detection is 1 where the all-phascogale file has 0 in 9 cells
#           (asserted), so the two files cannot both be per-census box checks of the same animals; not shipped.
#         Table_4/5_*_camera-detection-histories.csv: a separate camera study (30 sites near / far from nest
#           boxes and in Sedgwick State Forest, 60 weeks from January 2023); not in this table (see BATCH_LOG).
#         README.md. No coordinates are deposited.
# Mapping: unit = cluster (Sites), taxon = PHATAP / PETNOT, period = census 1..12 in time order, no occasion
#   (one box check per census), y = 0/1. Community rule: both species have a row at every surveyed cluster-
#   census. Cluster 74 at May-20 (glider "-", phascogale 0) is treated as not surveyed for both: a box check
#   surveys both species, and the "-" is the only record that says whether it happened. unit_n_boxes. __periods carries the census month as labelled in the
#   phascogale file and the glider file's label. No date column (month only). surveyEvidence = deposited_matrix.
#   IUCN (iucn_category()): Phascogale tapoatafa NT, Petaurus notatus NE (split from P. breviceps in 2020;
#   asserted). Neither is CR/EN/VU, and there are no coordinates in the source in any case.
#   Not shipped: the female-phascogale file (inconsistent with the all-phascogale file); the camera study.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldingay_2026_diamondhill_nestbox_occ"

dir <- download_dryad("10.5061/dryad.j3tx95xwd", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 6)
rd <- function(f) { d <- fread(file.path(dir, f), na.strings = "-", encoding = "UTF-8"); setnames(d, 1, "site"); d }
a <- rd("Table_1_All_phascogales_nest_box_detections.csv")
g <- rd("Table_3_Sugar_gliders_nest_box_detections.csv")
fe <- rd("Table_2_Female_phascogales_nest_box_detections.csv")
lab_a <- c("May-18", "Oct-18", "May-19", "Oct-19", "May-20", "Oct-20", "Jun-21", "Oct-21", "May-22", "Nov-22", "May-23", "Oct-23")
lab_g <- replace(lab_a, 10, "Oct-22")
stopifnot(identical(names(a), c("site", "Number of boxes", lab_a)), identical(names(g), c("site", lab_g)),
          identical(names(fe), c("site", replace(lab_a[3:12], 10, "Nov-23"))),
          identical(a$site, 1:74), identical(g$site, 1:74), identical(fe$site, 1:74),
          all(a[["Number of boxes"]] %in% 2:4), sum(a[["Number of boxes"]]) == 165)
A <- unname(as.matrix(a[, lab_a, with = FALSE])); G <- unname(as.matrix(g[, lab_g, with = FALSE])); Fm <- unname(as.matrix(fe[, -1]))
stopifnot(sum(is.na(A)) == 14, sum(is.na(G)) == 15, all(is.na(G)[is.na(A)]), is.na(G[74, 5]), identical(A[74, 5], 0L),
          all(c(A, G) %in% c(0L, 1L, NA)),
          sum(Fm > A[, 3:12], na.rm = TRUE) == 9)
A[74, 5] <- NA_integer_   # cluster 74, May-20: phascogale 0 but glider "-"; one box check cannot survey one species only

long <- rbindlist(list(
  array_to_eco(A, taxon = "PHATAP", site_ids = a$site, site_covs = data.frame(n_boxes = a[["Number of boxes"]]), period = 1:12),
  array_to_eco(G, taxon = "PETNOT", site_ids = a$site, site_covs = data.frame(n_boxes = a[["Number of boxes"]]), period = 1:12)))
long[, occasion := NULL]
setorder(long, period, unit, taxon)
stopifnot(nrow(long) == 2 * (74 * 12 - 15), uniqueN(long$unit) == 74)

taxa <- make_taxa(c("PHATAP", "PETNOT"), c("Phascogale tapoatafa", "Petaurus notatus"),
                  vernacularName = c("Brush-tailed phascogale", "Inland sugar glider (Krefft's glider)"))
iucn <- unname(mapply(iucn_category, taxa$taxonID, taxa$scientificName))
stopifnot(identical(iucn, c("NT", "NE")))
mon <- c(May = 5L, Jun = 6L, Oct = 10L, Nov = 11L)
periods <- data.table(period = 1:12, census_label = lab_a, glider_file_label = lab_g,
                      year = 2000L + as.integer(sub(".*-", "", lab_a)), month = mon[sub("-.*", "", lab_a)])

dataset <- list(
  title = "Nest-box detections of brush-tailed phascogale and inland sugar glider at 74 box clusters, Diamond Hill, Victoria, 12 censuses 2018-2023",
  creator = "Goldingay, Ross; Thomas, Karen; Quin, Darren", pubDate = "2026",
  doi = "10.5061/dryad.j3tx95xwd", sourceURL = "https://doi.org/10.5061/dryad.j3tx95xwd",
  citation = "Goldingay, R., Thomas, K., & Quin, D. (2026). Can artificial tree cavities provide population support to cavity-dependent non-flying mammals? [Dataset]. Dryad. https://doi.org/10.5061/dryad.j3tx95xwd",
  paperDOI = "10.1002/ece3.74280",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Nest boxes in 74 clusters of 2-4 boxes along management trails of a 600-ha block of Bendigo Regional Park (Diamond Hill), Victoria, Australia, checked twice a year (May/June and October/November) from May 2018 to October 2023. Detection of the brush-tailed phascogale and the inland sugar glider in any box of a cluster at each census.",
  samplingProtocol = "Box inspection from a ladder at each census; animals in the boxes recorded (phascogales hand-captured and sexed from 2019). A cluster counts as a detection if any of its boxes held the species.",
  samplingProtocolCode = "nest_box_check", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "none", closureNote = "one box check per census; censuses five to seven months apart",
  occasionKind = "none", taxonInclusion = "target",
  geographicCoverage = "Diamond Hill, Bendigo Regional Park, Victoria, Australia (no coordinates deposited)",
  temporalCoverage = "2018-05/2023-10",
  coordinatesCoarsened = NA,
  covariateNote = "unit_n_boxes: boxes in the cluster (the box counts sum to 165; the paper says 164 boxes).",
  notShipped = list(
    female_file = "Table_2 female phascogale detections: 1 where the all-phascogale file has 0 in 9 cells, so not a subset of it as the README implies",
    camera_study = "Table_4/5 weekly camera detection histories (30 sites, 60 weeks from January 2023): a separate design, not built in this batch",
    model_output = "occupancy and population-support estimates"),
  notes = "Cluster 74 at census 5 (May-20) has no rows: the glider file says not surveyed and the phascogale file 0; treated as not surveyed for both. Census months are as labelled in the phascogale file; the glider file labels census 10 Oct-22 where the phascogale file has Nov-22 (both in __periods).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/goldingay_2026_diamondhill_nestbox_occ.R")
stage_dict_row(TABLE,
  description = "Detection of brush-tailed phascogale and inland sugar glider in nest boxes at 74 box clusters, Diamond Hill, Bendigo Regional Park, Victoria, Australia, at 12 twice-yearly censuses from May 2018 to October 2023.",
  url = "https://doi.org/10.5061/dryad.j3tx95xwd",
  reference = "Goldingay, R., Thomas, K. & Quin, D. (2026). Can artificial tree cavities provide population support to cavity-dependent non-flying mammals? Ecology and Evolution. https://doi.org/10.1002/ece3.74280",
  doi_paper = "10.1002/ece3.74280", doi_data = "10.5061/dryad.j3tx95xwd",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Cluster-level detection per census; female-phascogale file and camera study not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "nest_box_check", design = "Multi-season (12 censuses, one check each)",
  realm = "Terrestrial", country = "AUS", coordinates = "None in source",
  notes = "Nest-box occupancy of two arboreal marsupials.")
