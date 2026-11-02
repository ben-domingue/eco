#!/usr/bin/env Rscript
# Table:  goldingay_2022_richmond_koala_dynocc
# Source: Dryad doi:10.5061/dryad.j6q573ngp (CC0 1.0, version 177082, published 2022-05-24),
#         "Koala greater glider detection histories: Richmond Range NP". Goldingay, R. L.,
#         McHugh, D. & Parkyn, J. L.
# Paper:  Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Multiyear monitoring of
#         threatened iconic arboreal mammals in a mid-elevation conservation reserve in
#         eastern Australia. Ecology and Evolution 12(5): e8935. doi:10.1002/ece3.8935 (CC BY 4.0).
# Data:   six UTF-16 tab-delimited text files.
#         Koala-detection-histories.txt and Greater-glider-detection-histories.txt: 34 sites
#         (site1..site34, 200 m spotlight transects) x 24 columns "year.survey" (1.1 .. 8.3):
#         1 detected, 0 not detected, "-" transect not surveyed on that occasion. Years 1-8
#         are 2014-2021 (three surveys per year, typically Sep-Dec; the README dates the data
#         Nov 2014 to Dec 2021); transects grew from 20 (2014) to 26 (2016) to 34 (2019).
#         Habitat-data.txt: 7 transect variables (large trees, primary food tree cover, hollow-
#         bearing trees, ridge topography, mean tree height, elevation, rainforest cover) plus
#         an empty trailing column. 5-night-audio-detection-history.txt and
#         Audio-vs-spotlight-surveys.txt: 2021 acoustic-recorder koala detections at 39 of 42
#         sites (31 of the 34 transects plus eight new sites; site numbering differs).
#         No coordinates, no dates finer than the year, no README licence statement.
# Mapping (standard E1-E5; dynamic occupancy): unit = site, taxon = PHACIN, period = year
#   1..8 (calendar year and drought flag in __periods; year 6 = 2019 had 43 % of average
#   rainfall, the paper's "severe drought"), occasion = survey 1..3 within the year, y = 0/1.
#   The seven habitat variables are unit_* covariates as deposited (not standardised).
#   Survey evidence: the deposited matrix; "-" cells are missing rows (E4). The two species'
#   matrices do not share one NA pattern (22 site-occasions have a value for one species
#   and "-" for the other, always a 0), so the community rule (one row per taxon per survey)
#   cannot be met without inventing values; each species is shipped as its own table on its
#   own deposited survey set. Companion table: goldingay_2022_richmond_glider_dynocc.
#   Not shipped: the 2021 acoustic-recorder histories (different method, different site set,
#   koala only); nothing else is in the deposit. No coordinates exist, so nothing is coarsened.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldingay_2022_richmond_koala_dynocc"
SPECIES_FILE <- "Koala-detection-histories.txt"; OTHER_FILE <- "Greater-glider-detection-histories.txt"
TAXON <- "PHACIN"; SCI <- "Phascolarctos cinereus"; VERN <- "koala"; IUCN <- "VU"

dir <- download_dryad("10.5061/dryad.j6q573ngp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("5-night-audio-detection-history.txt", "Audio-vs-spotlight-surveys.txt",
  "Greater-glider-detection-histories.txt", "Habitat-data.txt", "Koala-detection-histories.txt",
  "README_Koala-greater-glider-detection.txt")))
read_u16 <- function(f) {                       # the matrices are UTF-16LE with a BOM
  con <- file(file.path(dir, f), encoding = "UTF-16LE"); x <- readLines(con, warn = FALSE); close(con)
  x <- sub("^﻿", "", x); x <- x[nzchar(trimws(x))]
  fread(text = paste(x, collapse = "\n"), sep = "\t", header = TRUE, na.strings = "-", colClasses = "character")
}
read_hist <- function(f) {
  d <- read_u16(f)
  stopifnot(nrow(d) == 34, ncol(d) == 25, names(d)[1] == "Year-survey",
            identical(names(d)[-1], paste(rep(1:8, each = 3), rep(1:3, 8), sep = ".")),
            identical(d[[1]], paste0("site", 1:34)))
  m <- as.matrix(d[, -1]); m <- matrix(as.integer(m), nrow(m), dimnames = list(d[[1]], names(d)[-1]))
  stopifnot(all(m[!is.na(m)] %in% 0:1)); m
}
m <- read_hist(SPECIES_FILE); other <- read_hist(OTHER_FILE)
# the survey sets differ between the two species' matrices: 22 cells, each a 0 against a "-"
diff_cells <- which(is.na(m) != is.na(other))
stopifnot(length(diff_cells) == 22, all(na.omit(c(m[diff_cells], other[diff_cells])) == 0))
# transects were added over time: 20 in 2014, 26 in 2016, 34 in 2019 (paper, section 2.2)
year_of_col <- rep(1:8, each = 3)
sites_by_year <- sapply(1:8, function(t) sum(rowSums(!is.na(m[, year_of_col == t, drop = FALSE])) > 0))
stopifnot(sites_by_year[1] == 20L, sites_by_year[3] == 26, sites_by_year[6] == 34, all(diff(sites_by_year[1:6]) >= 0))

hab <- read_u16("Habitat-data.txt")
stopifnot(nrow(hab) == 34, identical(hab[[1]], rownames(m)), all(is.na(hab[[9]]) | hab[[9]] == ""),
          identical(names(hab)[2:8], c("Trees (#) >60 cm dbh", "Primary Food Trees (% cover)", "HBTs (#)",
            "Topography (ridge=1; other=0)", "Mean Tree Height (m)", "Elevation (m)", "Rainforest (% cover)")))
site_covs <- data.table(large_trees_n = as.integer(hab[[2]]), primary_food_trees_pct = as.numeric(hab[[3]]),
                        hollow_bearing_trees_n = as.integer(hab[[4]]), ridge = as.integer(hab[[5]]),
                        mean_tree_height_m = as.numeric(hab[[6]]), elevation_m = as.numeric(hab[[7]]),
                        rainforest_pct = as.numeric(hab[[8]]))
stopifnot(!anyNA(site_covs), all(site_covs$ridge %in% 0:1), all(site_covs$primary_food_trees_pct <= 100),
          all(site_covs$rainforest_pct <= 100), all(site_covs$elevation_m >= 300 & site_covs$elevation_m <= 610))

long <- array_to_eco(m, taxon = TAXON, site_ids = rownames(m), site_covs = site_covs, period = year_of_col)
stopifnot(nrow(long) == sum(!is.na(m)), uniqueN(long$unit) == 34, max(long$period) == 8, all(long$occasion %in% 1:3),
          sum(long$y) == sum(m, na.rm = TRUE))

years <- 2013L + 1:8
periods <- data.table(period = 1:8, year = years, drought = as.integer(years == 2019L),
                      n_sites_surveyed = sites_by_year,
                      n_surveys = sapply(1:8, function(t) sum(!is.na(m[, year_of_col == t]))))
taxa <- make_taxa(TAXON, SCI, vernacularName = VERN, taxon_iucnCategory = IUCN)
stopifnot(!is.na(taxa$taxonID))

dataset <- list(
  title = sprintf("%s spotlight detection histories at 34 transects over 8 years (2014-2021), Richmond Range National Park, NSW, Australia",
                  tools::toTitleCase(VERN)),
  creator = "Goldingay, Ross L.; McHugh, Darren; Parkyn, Jonathan L.", pubDate = "2022",
  doi = "10.5061/dryad.j6q573ngp", sourceURL = "https://doi.org/10.5061/dryad.j6q573ngp",
  citation = "Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Koala greater glider detection histories: Richmond Range NP [Dataset]. Dryad. https://doi.org/10.5061/dryad.j6q573ngp. Paper: Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Multiyear monitoring of threatened iconic arboreal mammals in a mid-elevation conservation reserve in eastern Australia. Ecology and Evolution 12(5): e8935. https://doi.org/10.1002/ece3.8935",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Detection (1) / non-detection (0) of the %s (%s) on 20-minute single-observer spotlight surveys of 200 m road transects in Richmond Range National Park (and adjoining State Forest), New South Wales, three surveys per year (typically September-December, nights at least two weeks apart) in each of eight years 2014-2021. Transects were added over the study (20 in 2014, 26 in 2016, 34 in 2019); a transect not surveyed on an occasion has no row. Year 6 (2019) was a severe drought (43 %% of average rainfall). Seven habitat variables measured along each transect are unit covariates. The deposit's two species matrices differ in 22 surveyed cells, so each species is its own table; the companion is goldingay_2022_richmond_glider_dynocc.", VERN, SCI),
  samplingProtocol = "Spotlight survey: a single observer walked each 200 m transect at ~600 m/h over 20 min, illuminating both sides with a 350-lumen LED torch, recording arboreal mammals seen or heard; four call broadcasts of yellow-bellied glider and powerful owl mid-survey (for another species). Three surveys per transect per year on different nights, at least two weeks apart, usually dry, low-moonlight, low-wind nights 1-5 h after dark.",
  samplingProtocolCode = "spotlight_transect", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A site-year-survey is surveyed iff the deposited cell is 0 or 1 (\"-\" = not surveyed). The koala and greater glider matrices share 34 sites and 24 columns but differ in 22 cells (one species 0, the other \"-\"); each species' table uses its own deposited survey set, so the two tables are not a community table.",
  responseType = "detection", unitKind = "site", closure = "period",
  geographicCoverage = "Richmond Range National Park and adjoining State Forest, north-eastern New South Wales, Australia (mid-elevation, 300-610 m; no coordinates deposited)",
  temporalCoverage = "2014/2021",
  coordinatesCoarsened = NA,
  notes = "Years 1-8 of the deposit are 2014-2021 (paper section 2.1-2.2; README dates the spotlight data Nov 2014 to Dec 2021). __periods.drought flags 2019, the paper's year-6 drought. Habitat values are as deposited: counts within a 0.8 ha strip (large trees >= 60 cm DBH, hollow-bearing trees), mean height of 10 trees, GPS elevation, ridge (1) vs other (0), and % cover of koala primary food trees and of rainforest within a 200 m buffer (NSW forest-type mapping). Within-year survey dates are not deposited.",
  notShipped = list(
    `5-night-audio-detection-history.txt` = "2021 acoustic-recorder koala detections over five nights at 39 of 42 sites (31 of the 34 transects plus 8 new sites, different numbering); a different method and site set, not merged",
    `Audio-vs-spotlight-surveys.txt` = "2021 paired spotlight/audio koala detections for the multi-method comparison; same reason",
    `Greater-glider-detection-histories.txt` = "shipped as goldingay_2022_richmond_glider_dynocc (its survey set differs in 22 cells)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = paste0("data/", TABLE, ".R"))

stage_dict_row(TABLE,
  description = sprintf("%s spotlight detection/non-detection at 34 road transects in Richmond Range National Park, NSW, three surveys per year for eight years (2014-2021; 20 to 34 transects over time), with seven deposited habitat covariates; multi-season occupancy design spanning the 2019 drought.", tools::toTitleCase(VERN)),
  url = "https://doi.org/10.5061/dryad.j6q573ngp",
  reference = "Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Multiyear monitoring of threatened iconic arboreal mammals in a mid-elevation conservation reserve in eastern Australia. Ecology and Evolution 12(5): e8935.",
  doi_paper = "10.1002/ece3.8935", doi_data = "10.5061/dryad.j6q573ngp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "One of two tables from the deposit (companion: the greater glider); the species' survey sets differ in 22 cells so they are not one community table. No coordinates deposited. 2021 acoustic-recorder data not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "spotlight_transect", design = "Multi-season (8 years x 3 surveys)", realm = "Terrestrial", country = "Australia",
  coordinates = "None in source", notes = "Single species; transects added over time (20 -> 34); drought in 2019 flagged in __periods.")
