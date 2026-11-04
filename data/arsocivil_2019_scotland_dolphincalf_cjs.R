#!/usr/bin/env Rscript
# Table:  arsocivil_2019_scotland_dolphincalf_cjs
# Source: Dryad doi:10.5061/dryad.8qm8r4m, version 13298 (published 2018-12-19), licence CC0 1.0
#         (as shown on Dryad). Arso Civil, M. et al. "Data from: Variations in age- and sex-specific
#         survival rates help explain population trend in a discrete marine mammal population".
# Paper:  Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V., Graves, J. A., Janik,
#         V. M., Thompson, P. M. & Hammond, P. S. (2019). Ecology and Evolution 9(1):533-544.
#         doi:10.1002/ece3.4772 (open access; read via Europe PMC PMC6342117).
# Data:   calf_age CJS models.txt (one of five files; the others are described in the sibling
#         script arsocivil_2019_scotland_dolphin_rd.R): 56 lines "history g1 g2;", history of 26
#         annual sightings (1990..2015: the paper's "116 calves with known year of birth and known
#         mother were identified between 1990 and 2015. Of these, 56 calves had mothers sighted in
#         the 3 years following birth"), then two MARK group indicator columns (1 0 for 19 calves,
#         0 1 for 37). The paper's calf groups are first-born versus subsequently born calves; the
#         deposit does not say which column is which. time_intervals.txt: calf data are annual
#         sightings (primary occasions only). Calves were identified by size, colouration, fetal
#         folds and repeated association with their mother, not by permanent marks.
#
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = calf C01..C56 (row of the file), taxon = TURTRU, period = year 1..26 (1990..2015, in
#   __periods), no occasion (one per period), y = 0/1 sighted that year. Survey evidence: the
#   deposited matrix. At-risk span (E4.4): a calf is identified in its birth year (the paper's
#   inclusion rule: known year of birth, mother seen in the birth year and the 3 following), so
#   it is marked at birth and has no rows before its first sighting; rows run from the birth
#   year to 2015, with y = 0 in years not sighted. Calves carry no permanent marks, but the
#   deposit gives no censoring, so no history is cut short. unit_mark_group = "g1" (deposit's 1 0) or "g2" (0 1), labels deliberately neutral.
#   Not shipped: nothing else in this file.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "arsocivil_2019_scotland_dolphincalf_cjs"
dir <- download_dryad("10.5061/dryad.8qm8r4m", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
l <- trimws(gsub("\r", "", readLines(file.path(dir, "calf_age CJS models.txt"), warn = FALSE))); l <- l[nzchar(l)]
stopifnot(length(l) == 56L, all(grepl("^[01]{26} [01] [01];$", l)))
p <- strsplit(sub(";$", "", l), " ")
ch <- sapply(p, `[`, 1); g <- paste(sapply(p, `[`, 2), sapply(p, `[`, 3))
stopifnot(all(g %in% c("1 0", "0 1")), sum(g == "1 0") == 19L, sum(g == "0 1") == 37L, all(grepl("1", ch)))
years <- 1990L:2015L; n_yr <- length(years)
Y <- do.call(rbind, lapply(strsplit(ch, ""), as.integer))
first <- apply(Y, 1, function(r) which(r == 1)[1])
# mothers were seen in the birth year and the 3 following years; the last possible birth year is 2012
stopifnot(max(first) <= n_yr - 3L)
cat(sprintf("  %d calves x %d years; %d sightings; groups g1 %d, g2 %d; first sighting %d-%d\n",
            nrow(Y), n_yr, sum(Y), sum(g == "1 0"), sum(g == "0 1"), years[min(first)], years[max(first)]))

units <- sprintf("C%02d", seq_len(nrow(Y)))
long <- array_to_eco(Y, taxon = "TURTRU", site_ids = units, period = seq_len(n_yr),
                     site_covs = data.frame(mark_group = ifelse(g == "1 0", "g1", "g2")))
long[, occasion := NULL]
stopifnot(nrow(long) == 56L * n_yr, sum(long$y) == sum(Y))
# E4.4: marked at birth -> no rows before the birth (first-sighting) year
long <- long[period >= first[match(unit, units)]]
stopifnot(nrow(long) == sum(n_yr - first + 1L), sum(long$y) == sum(Y))

taxa <- make_taxa("TURTRU", "Tursiops truncatus", vernacularName = "Common bottlenose dolphin",
                  taxon_iucnCategory = "LC")
periods <- data.table(period = seq_len(n_yr), year = years, n_detected = as.integer(colSums(Y)),
                      n_first_sighted = as.integer(tabulate(first, n_yr)),
                      note = "annual field season May-September, sightings pooled within the year")

dataset <- list(
  title = "Annual sighting histories of 56 bottlenose dolphin calves of known mother and birth year, east coast of Scotland, 1990-2015",
  creator = "Arso Civil, Monica; Cheney, Barbara; Quick, Nicola J.; Islas-Villanueva, Valentina; Graves, Jeff A.; Janik, Vincent M.; Thompson, Paul M.; Hammond, Philip S.",
  pubDate = "2018", doi = "10.5061/dryad.8qm8r4m", sourceURL = "https://doi.org/10.5061/dryad.8qm8r4m",
  citation = "Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V., Graves, J. A., Janik, V. M., Thompson, P. M., & Hammond, P. S. (2018). Data from: Variations in age- and sex-specific survival rates help explain population trend in a discrete marine mammal population [Dataset]. Dryad. https://doi.org/10.5061/dryad.8qm8r4m",
  paperDOI = "10.1002/ece3.4772",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual photo-identification sighting histories of 56 bottlenose dolphin calves with known mother and year of birth whose mothers were seen in the birth year and the three following years, east coast of Scotland, 1990-2015, used for age-specific CJS models of survival in the first three years of life and for comparing first-born with subsequently born calves.",
  samplingProtocol = "Boat-based photo-identification surveys May-September each year; calves (no permanent marks) identified by body size, skin colouration, fetal folds and repeated association with a known mother; sightings pooled within each year.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "period (annual sightings; survival between years)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "East coast of Scotland, UK: Moray Firth SAC and St Andrews Bay / Tay estuary; no coordinates deposited",
  temporalCoverage = "1990/2015",
  coordinatesCoarsened = NA,
  notes = "Calf ids are row numbers. Each calf's rows begin in its birth year (its first sighting, by the paper's inclusion rule), E4.4 for individuals marked at birth; this is the paper's conditioning on first sighting. unit_mark_group carries the deposit's two MARK group columns (g1 = '1 0', 19 calves; g2 = '0 1', 37 calves); the paper's groups are first-born and subsequently born calves, but the deposit does not say which is which. Calf detection depends strongly on sighting the mother (inclusion requires the mother seen in the three years after birth). Calves may later appear among the marked juveniles/adults of the sibling robust-design table; the deposit has no ids to link them.",
  notShipped = list(`group labels` = "the deposit's group columns are unlabelled; not mapped to first-born / subsequent"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/arsocivil_2019_scotland_dolphincalf_cjs.R")

stage_dict_row(TABLE,
  description = "Annual sighting histories of 56 bottlenose dolphin calves of known mother and birth year off the east coast of Scotland, 26 years (1990-2015); y = sighted; for age-specific CJS survival in the first three years of life; the deposit's two (unlabelled) MARK groups as a covariate.",
  url = "https://doi.org/10.5061/dryad.8qm8r4m",
  reference = "Arso Civil, M., Cheney, B., Quick, N. J., Islas-Villanueva, V., Graves, J. A., Janik, V. M., Thompson, P. M., & Hammond, P. S. (2019). Variations in age- and sex-specific survival rates help explain population trend in a discrete marine mammal population. Ecology and Evolution, 9(1), 533-544.",
  doi_paper = "10.1002/ece3.4772", doi_data = "10.5061/dryad.8qm8r4m",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Sibling of arsocivil_2019_scotland_dolphin_rd (same deposit). Group columns unlabelled in the deposit (first-born vs subsequent per the paper).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture (age-specific calf survival)",
  sampling_protocol = "photo_id", design = "Multi-session (26 annual primary periods, no secondary)", realm = "Marine",
  country = "GBR", coordinates = "None in source", notes = "Calves of known mothers; ids are row numbers; group columns unlabelled.")
