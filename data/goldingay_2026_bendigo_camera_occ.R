#!/usr/bin/env Rscript
# Table:  goldingay_2026_bendigo_camera_occ
# Source: Dryad, doi:10.5061/dryad.j3tx95xwd, version 462723 (version 5, published 2026-09-10), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Goldingay, R., Thomas, K. & Quin, D. (2026). Can artificial tree cavities provide population support to
#         cavity-dependent non-flying mammals? Ecology and Evolution. https://doi.org/10.1002/ece3.74280
#         The design is from the deposit's methods (Dryad page): camera trapping January 2023 to February 2024
#         at 10 sites of each of three types: 'near' a nest-box site used by maternal phascogales in 2022
#         (camera within 10 m of the box), 'far' (at least 300 m from a nest-box site, at a tree with a cavity),
#         and Sedgwick State Forest (4.6 km SE, no nest boxes, at a tree with a cavity); one camera per site,
#         baited canister, serviced about every 2 months, 5 images per trigger, 1 min quiet period.
# Data:   Table_4_Phascogales_camera-detection-histories.csv and Table_5_SugarGliders_camera-detection-histories.csv:
#           a header row of weeks 1..60, four rows assigning each week to Summer / Autumn / Winter / Spring
#           (0/1 indicators: weeks 1-7 summer, 8-21 autumn, 22-34 winter, 35-47 spring, 48-60 summer again),
#           then 30 site rows labelled '<type>; <code>' (CL1-10 near nest box, DH1-10 far from nest box,
#           SED1-10 Sedgwick); cells 1 = detected in the week, 0 = not, '-' = site not surveyed that week.
#         Tables 1-3 (nest-box censuses) are goldingay_2026_diamondhill_nestbox_occ. README.md. No coordinates.
# Mapping: community occupancy over seasons, cameras. unit = site code (CL1.., DH1.., SED1..), taxon = PHATAP /
#   PETNOT, period = the five season blocks in time order (summer 2023, autumn, winter, spring, summer 2023-24),
#   occasion = the week within its block, obs_week = the deposit's week 1..60, y = weekly detection 0/1.
#   unit_site_type = near_nestbox / far_nestbox / sedgwick_no_nestbox. surveyEvidence = deposited_matrix ('-').
#   Shared-detector ruling (2026-11-06, E4): one camera surveys both species, so a site-week marked '-' for
#   either species has no rows for either; the number removed is asserted below and listed in notShipped
#   (in every such cell the other species has 0, never 1).
#   IUCN: Phascogale tapoatafa NT, Petaurus notatus NE; no coordinates deposited, so E7 does not arise.
#   No date column: week k is the k-th week from January 2023 but the start day is not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldingay_2026_bendigo_camera_occ"

dir <- download_dryad("10.5061/dryad.j3tx95xwd", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 6)
rd <- function(f) {
  d <- fread(file.path(dir, f), na.strings = "-", encoding = "UTF-8", header = TRUE)
  setnames(d, 1, "row"); d }
ph <- rd("Table_4_Phascogales_camera-detection-histories.csv")
sg <- rd("Table_5_SugarGliders_camera-detection-histories.csv")
stopifnot(identical(names(ph), c("row", as.character(1:60))), identical(names(sg), names(ph)),
          nrow(ph) == 34L, nrow(sg) == 34L, identical(ph$row, sg$row),
          identical(ph$row[1:4], c("Summer", "Autumn", "Winter", "Spring")))
seas <- as.matrix(ph[1:4, -1]); stopifnot(identical(seas, as.matrix(sg[1:4, -1])), all(colSums(seas) == 1L))
season_of_week <- c("Summer", "Autumn", "Winter", "Spring")[apply(seas, 2, which.max)]
block <- cumsum(c(TRUE, season_of_week[-1] != season_of_week[-60]))
stopifnot(identical(as.integer(table(block)), c(7L, 14L, 13L, 13L, 13L)), max(block) == 5L)

lab <- ph$row[-(1:4)]
code <- sub("^.*; *", "", lab)
type <- ifelse(grepl("^Near nest box", lab), "near_nestbox", ifelse(grepl("^Far from nest box", lab), "far_nestbox",
               ifelse(grepl("^Sedgwick", lab), "sedgwick_no_nestbox", NA)))
stopifnot(identical(code, c(paste0("CL", 1:10), paste0("DH", 1:10), paste0("SED", 1:10))), !anyNA(type),
          identical(as.vector(table(type)[c("near_nestbox", "far_nestbox", "sedgwick_no_nestbox")]), c(10L, 10L, 10L)))
P <- unname(as.matrix(ph[-(1:4), -1])); G <- unname(as.matrix(sg[-(1:4), -1]))
stopifnot(all(c(P, G) %in% c(0L, 1L, NA)))
oneNA <- xor(is.na(P), is.na(G))
stopifnot(sum(is.na(P) & is.na(G)) == 243L, sum(oneNA) == 14L, sum(is.na(P)) == 250L, sum(is.na(G)) == 250L,
          all(P[oneNA & !is.na(P)] == 0L), all(G[oneNA & !is.na(G)] == 0L))
P[oneNA] <- NA_integer_; G[oneNA] <- NA_integer_      # shared detector: not surveyed for either species

mk <- function(M, tx) {
  d <- data.table(unit = rep(code, 60), unit_site_type = rep(type, 60), obs_week = rep(1:60, each = 30),
                  y = as.vector(M))
  d[, `:=`(taxon = tx, period = block[obs_week])]
  d[, occasion := obs_week - min(which(block == period[1])) + 1L, by = period]
  d[!is.na(y)] }
long <- rbindlist(list(mk(P, "PHATAP"), mk(G, "PETNOT")))
long <- order_eco(long)
stopifnot(nrow(long) == 2L * (30L * 60L - 243L - 14L), uniqueN(long$unit) == 30L,
          sum(long[taxon == "PHATAP"]$y) == sum(P, na.rm = TRUE), sum(long[taxon == "PETNOT"]$y) == sum(G, na.rm = TRUE))
cat(sprintf("  %d rows, %d site-weeks surveyed, detections: phascogale %d, glider %d\n", nrow(long),
            nrow(long) / 2L, sum(long[taxon == "PHATAP"]$y), sum(long[taxon == "PETNOT"]$y)))

taxa <- make_taxa(c("PHATAP", "PETNOT"), c("Phascogale tapoatafa", "Petaurus notatus"),
                  vernacularName = c("Brush-tailed phascogale", "Inland sugar glider (Krefft's glider)"))
periods <- data.table(period = 1:5, season = c("summer", "autumn", "winter", "spring", "summer"),
                      first_week = as.integer(tapply(1:60, block, min)), last_week = as.integer(tapply(1:60, block, max)),
                      season_years = c("2023", "2023", "2023", "2023", "2023-2024"))

dataset <- list(
  title = "Weekly camera detections of brush-tailed phascogale and inland sugar glider at 30 sites near and away from nest boxes, Bendigo, Victoria, January 2023 to February 2024",
  creator = "Goldingay, Ross; Thomas, Karen; Quin, Darren", pubDate = "2026",
  doi = "10.5061/dryad.j3tx95xwd", sourceURL = "https://doi.org/10.5061/dryad.j3tx95xwd",
  citation = "Goldingay, R., Thomas, K., & Quin, D. (2026). Can artificial tree cavities provide population support to cavity-dependent non-flying mammals? [Dataset]. Dryad. https://doi.org/10.5061/dryad.j3tx95xwd",
  paperDOI = "10.1002/ece3.74280",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps at 30 sites, 10 near nest boxes used by maternal phascogales in Diamond Hill (Bendigo Regional Park), 10 at least 300 m from a nest-box site, and 10 in Sedgwick State Forest with no nest boxes, run for 60 weeks from January 2023 to February 2024 to test whether nest boxes raise the local abundance of two cavity-dependent marsupials. Weekly detection of each species per site.",
  samplingProtocol = "One baited camera per site (Swift Enduro / Swift 3C, 5 images per trigger, 1 min quiet period) aimed at a canister of bait on a tree 2-3 m away, serviced about every two months; a week with any image of the species is a detection.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "weeks within a season block are the occasions; the deposit assigns each week to a season, and blocks are the periods. Closure within a season is the user's assumption.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Diamond Hill (Bendigo Regional Park) and Sedgwick State Forest, near Bendigo, Victoria, Australia (no coordinates deposited)",
  temporalCoverage = "2023-01/2024-02",
  covariateNote = "unit_site_type: near_nestbox (camera within 10 m of a nest box used by maternal phascogales in 2022), far_nestbox (>= 300 m from a nest-box site), sedgwick_no_nestbox. obs_week: week 1..60 of the deposit, counted from January 2023 (start day not deposited).",
  notShipped = list(
    shared_detector = "14 site-weeks marked not surveyed ('-') for one species and 0 for the other: one camera surveys both, so they have no rows for either species (shared-detector ruling, 2026-11-06)",
    nest_box_censuses = "Tables 1-3, the nest-box censuses: shipped as goldingay_2026_diamondhill_nestbox_occ",
    model_output = "occupancy and abundance estimates"),
  notes = "Week k is the k-th week from January 2023; the deposit gives no start day, so there is no date column. The fifth period is the second summer (December 2023 to February 2024).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/goldingay_2026_bendigo_camera_occ.R")
stage_dict_row(TABLE,
  description = "Weekly camera detections of brush-tailed phascogale and inland sugar glider at 30 sites (near nest boxes, away from them, and in a forest without nest boxes), Bendigo, Victoria, Australia, January 2023 to February 2024.",
  url = "https://doi.org/10.5061/dryad.j3tx95xwd",
  reference = "Goldingay, R., Thomas, K. & Quin, D. (2026). Can artificial tree cavities provide population support to cavity-dependent non-flying mammals? Ecology and Evolution. https://doi.org/10.1002/ece3.74280",
  doi_paper = "10.1002/ece3.74280", doi_data = "10.5061/dryad.j3tx95xwd",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Camera study of the deposit (Tables 4-5); 14 site-weeks with no camera for one species dropped for both (shared-detector ruling).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "camera_trap", design = "Multi-season (5 season blocks, 7-14 weekly occasions each; 30 sites)",
  realm = "Terrestrial", country = "AUS", coordinates = "None in source",
  notes = "Camera test of nest-box effects on two arboreal marsupials; three site types.")
