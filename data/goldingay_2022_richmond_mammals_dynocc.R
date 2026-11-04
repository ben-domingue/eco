#!/usr/bin/env Rscript
# Table:  goldingay_2022_richmond_mammals_dynocc (replaces goldingay_2022_richmond_glider_dynocc
#         and goldingay_2022_richmond_koala_dynocc; ruling #31)
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
# Mapping (standard v1.1 E1-E5; dynamic occupancy): ONE table for the two species (ruling #31:
#   one deposit, one spotlight protocol, one response type). unit = site, taxon = PHACIN
#   (koala, IUCN VU) and PETARM (Petauroides armillatus, the central greater glider, the taxon
#   the paper names; the README's nominate P. volans sensu lato is the IUCN-assessed unit, VU,
#   so taxon_iucnCategory is left empty), period = year 1..8 (calendar year and drought flag in
#   __periods; year 6 = 2019 had 43 % of average rainfall, the paper's "severe drought"),
#   occasion = survey 1..3 within the year, y = 0/1. The seven habitat variables are unit_*
#   covariates as deposited (not standardised).
#   Survey evidence: the deposited matrices; "-" cells are missing rows (E4). The two species'
#   matrices do not share one NA pattern (22 site-occasions have a value for one species and
#   "-" for the other, always a 0), so __survey_taxa (taxon x unit x period x occasion, E4.2)
#   lists the species each deposited survey scored; nothing is invented. closure = closed
#   (three surveys within a season), occasionKind = time, taxonInclusion = target.
#   Not shipped: the 2021 acoustic-recorder histories (different method, different site set,
#   koala only); nothing else is in the deposit. No coordinates exist, so nothing is coarsened.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "goldingay_2022_richmond_mammals_dynocc"
SP <- data.table(file = c("Koala-detection-histories.txt", "Greater-glider-detection-histories.txt"),
                 taxon = c("PHACIN", "PETARM"), sci = c("Phascolarctos cinereus", "Petauroides armillatus"),
                 vern = c("koala", "central greater glider"), iucn = c("VU", NA_character_), year1_sites = c(20L, 19L))

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
mats <- setNames(lapply(SP$file, read_hist), SP$taxon)
# the survey sets differ between the two species' matrices: 22 cells, each a 0 against a "-"
diff_cells <- which(is.na(mats$PHACIN) != is.na(mats$PETARM))
stopifnot(length(diff_cells) == 22, all(na.omit(c(mats$PHACIN[diff_cells], mats$PETARM[diff_cells])) == 0))
# transects were added over time: 20 in 2014, 26 in 2016, 34 in 2019 (paper, section 2.2)
year_of_col <- rep(1:8, each = 3)
any_m <- !is.na(mats$PHACIN) | !is.na(mats$PETARM)
sites_by_year <- sapply(1:8, function(t) sum(rowSums(any_m[, year_of_col == t, drop = FALSE]) > 0))
for (i in seq_len(nrow(SP))) {          # (the glider matrix has "-" for site3 in all of year 1, so its year-1 count is 19, not the paper's 20)
  sy <- sapply(1:8, function(t) sum(rowSums(!is.na(mats[[SP$taxon[i]]][, year_of_col == t, drop = FALSE])) > 0))
  stopifnot(sy[1] == SP$year1_sites[i], sy[3] == 26, sy[6] == 34, all(diff(sy[1:6]) >= 0))
}
stopifnot(identical(sites_by_year[c(1, 3, 6)], c(20L, 26L, 34L)))
m <- mats$PHACIN

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

long <- rbindlist(lapply(SP$taxon, function(tx) {
  mm <- mats[[tx]]
  l <- array_to_eco(mm, taxon = tx, site_ids = rownames(mm), site_covs = site_covs, period = year_of_col)
  stopifnot(nrow(l) == sum(!is.na(mm)), sum(l$y) == sum(mm, na.rm = TRUE)); l }))
stopifnot(uniqueN(long$unit) == 34, max(long$period) == 8, all(long$occasion %in% 1:3),
          nrow(long) == sum(!is.na(mats$PHACIN)) + sum(!is.na(mats$PETARM)))
long <- order_eco(long)
survey_taxa <- unique(long[, .(taxon, unit, period, occasion)])
stopifnot(nrow(unique(survey_taxa[, .(unit, period, occasion)])) == sum(any_m))

years <- 2013L + 1:8
periods <- data.table(period = 1:8, year = years, drought = as.integer(years == 2019L),
                      n_sites_surveyed = sites_by_year,
                      n_surveys = sapply(1:8, function(t) sum(any_m[, year_of_col == t])))
taxa <- make_taxa(SP$taxon, SP$sci, vernacularName = SP$vern, taxon_iucnCategory = SP$iucn)
stopifnot(!anyNA(taxa$taxonID))

dataset <- list(
  title = "Koala and central greater glider spotlight detection histories at 34 transects over 8 years (2014-2021), Richmond Range National Park, NSW, Australia",
  creator = "Goldingay, Ross L.; McHugh, Darren; Parkyn, Jonathan L.", pubDate = "2022",
  doi = "10.5061/dryad.j6q573ngp", sourceURL = "https://doi.org/10.5061/dryad.j6q573ngp",
  citation = "Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Koala greater glider detection histories: Richmond Range NP [Dataset]. Dryad. https://doi.org/10.5061/dryad.j6q573ngp. Paper: Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Multiyear monitoring of threatened iconic arboreal mammals in a mid-elevation conservation reserve in eastern Australia. Ecology and Evolution 12(5): e8935. https://doi.org/10.1002/ece3.8935",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Detection (1) / non-detection (0) of the koala (Phascolarctos cinereus) and the central greater glider (Petauroides armillatus) on 20-minute single-observer spotlight surveys of 200 m road transects in Richmond Range National Park (and adjoining State Forest), New South Wales, three surveys per year (typically September-December, nights at least two weeks apart) in each of eight years 2014-2021. Transects were added over the study (20 in 2014, 26 in 2016, 34 in 2019); a transect not surveyed on an occasion has no row. Year 6 (2019) was a severe drought (43 %% of average rainfall). Seven habitat variables measured along each transect are unit covariates. The deposit's two species matrices differ in 22 surveyed cells (one species scored 0, the other not scored); __survey_taxa lists the species scored at each survey."),
  samplingProtocol = "Spotlight survey: a single observer walked each 200 m transect at ~600 m/h over 20 min, illuminating both sides with a 350-lumen LED torch, recording arboreal mammals seen or heard; four call broadcasts of yellow-bellied glider and powerful owl mid-survey (for another species). Three surveys per transect per year on different nights, at least two weeks apart, usually dry, low-moonlight, low-wind nights 1-5 h after dark.",
  samplingProtocolCode = "spotlight_transect", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A site-year-survey is surveyed iff the deposited cell is 0 or 1 (\"-\" = not surveyed). The koala and greater glider matrices share 34 sites and 24 columns but differ in 22 cells (one species 0, the other \"-\"); __survey_taxa lists, per survey, the species whose matrix scored it.",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Richmond Range National Park and adjoining State Forest, north-eastern New South Wales, Australia (mid-elevation, 300-610 m; no coordinates deposited)",
  temporalCoverage = "2014/2021",
  coordinatesCoarsened = NA,
  notes = "The deposit README names the species \"central greater glider (Petauroides armillatus)\"; the paper follows McGregor et al. (2020) in splitting P. volans into three species. taxon_iucnCategory is left empty because the IUCN Red List assesses P. volans sensu lato (VU, 2016), not P. armillatus. Years 1-8 of the deposit are 2014-2021 (paper section 2.1-2.2; README dates the spotlight data Nov 2014 to Dec 2021). __periods.drought flags 2019, the paper's year-6 drought. Habitat values are as deposited: counts within a 0.8 ha strip (large trees >= 60 cm DBH, hollow-bearing trees), mean height of 10 trees, GPS elevation, ridge (1) vs other (0), and % cover of koala primary food trees and of rainforest within a 200 m buffer (NSW forest-type mapping). Within-year survey dates are not deposited.",
  notShipped = list(
    `5-night-audio-detection-history.txt` = "2021 acoustic-recorder koala detections over five nights at 39 of 42 sites (31 of the 34 transects plus 8 new sites, different numbering); a different method and site set, not merged",
    `Audio-vs-spotlight-surveys.txt` = "2021 paired spotlight/audio koala detections for the multi-method comparison; same reason"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = paste0("data/", TABLE, ".R"))

stage_dict_row(TABLE,
  description = "Koala and central greater glider spotlight detection/non-detection at 34 road transects in Richmond Range National Park, NSW, three surveys per year for eight years (2014-2021; 20 to 34 transects over time), with seven deposited habitat covariates; multi-season occupancy design spanning the 2019 drought.",
  url = "https://doi.org/10.5061/dryad.j6q573ngp",
  reference = "Goldingay, R. L., McHugh, D. & Parkyn, J. L. (2022). Multiyear monitoring of threatened iconic arboreal mammals in a mid-elevation conservation reserve in eastern Australia. Ecology and Evolution 12(5): e8935.",
  doi_paper = "10.1002/ece3.8935", doi_data = "10.5061/dryad.j6q573ngp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Replaces goldingay_2022_richmond_glider_dynocc and goldingay_2022_richmond_koala_dynocc (ruling #31); the species' survey sets differ in 22 cells, carried by __survey_taxa. No coordinates deposited. 2021 acoustic-recorder data not shipped.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy",
  sampling_protocol = "spotlight_transect", design = "Multi-season (8 years x 3 surveys)", realm = "Terrestrial", country = "Australia",
  coordinates = "None in source", notes = "Koala and central greater glider (Petauroides armillatus, split from P. volans by McGregor et al. 2020; the IUCN assesses P. volans sensu lato as VU); transects added over time (20 -> 34); drought in 2019 flagged in __periods.")
