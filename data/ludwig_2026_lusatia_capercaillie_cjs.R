#!/usr/bin/env Rscript
# Table:  ludwig_2026_lusatia_capercaillie_cjs
# Source: Dryad doi:10.5061/dryad.73n5tb3cn, version 443680 (published 2026-05-23), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Ludwig, T., Alexander, E., Ludwig, A., Lieckfeldt, D., Hoglund, J.
#         & Thielemann, L. "Data from: Long-term apparent survival of capercaillie (Tetrao urogallus) translocated from
#         Sweden to East Germany".
# Paper:  Wildlife Biology, doi:10.1002/wlb3.01532 (not read; design from the deposited README).
# Data:   caper_data.csv: 552 capercaillie released in Lower Lusatia, eastern Germany, 2012-2024 (README):
#         ID; origin (SE = adult wild-caught in Sweden at leks with mist nets or along forest roads with dip
#         nets and translocated; btbf = juvenile reared by its translocated mother under the "born to be free"
#         method); sex (455 female, 97 male); release (year) and rel_date; catch_weight (g); mortality (date of
#         confirmed death, 58 birds) and mortyear (its year); radio_track (1 = carried a GPS/radio
#         transmitter, 74 birds, almost all released 2012-2019); 2012..2024: annual encounter, "detected
#         during a given year through genetic monitoring and/or telemetry". Genetic monitoring is annual,
#         June-August, from feathers at dust-bathing sites; telemetry intensive in 2012-2014. The release
#         year's cell is 1 for every bird and no bird is encountered before release (asserted). One bird
#         (ID 212) is encountered in 2020 after a confirmed death on 2019-09-11.
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = ID; taxon = TETURO; period = year - 2011 (2012 = 1 ... 2024 = 13; __periods carries the year);
#   y = the deposited encounter; obs_release = 1 on the release-year row (the release is the marking event,
#   not a monitoring detection). At-risk rows (E4.4): from the release year (marked at release) to 2024, or
#   to the year of confirmed death (a dead bird is no longer in the population); for bird 212 to 2020, its
#   last deposited encounter. unit_origin (SE / btbf), unit_sex, unit_catch_weight_g, unit_radio_track,
#   unit_release_date, unit_death_date (NA where no death was confirmed).
#   Survey evidence: deposited_matrix (the annual columns are the study's monitoring years).
#   Not shipped: mortyear (the year of unit_death_date).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ludwig_2026_lusatia_capercaillie_cjs"
dir <- download_dryad("10.5061/dryad.73n5tb3cn", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "443680"), length(list.files(dir)) == 2L)
x <- fread(file.path(dir, "caper_data.csv"))
yrs <- as.character(2012:2024)
stopifnot(identical(names(x), c("ID", "origin", "sex", "release", "rel_date", "catch_weight", "mortality", "mortyear",
                                "radio_track", yrs)),
          nrow(x) == 552L, !anyDuplicated(x$ID), all(x$origin %in% c("SE", "btbf")), all(x$sex %in% c("female", "male")),
          all(x$release %in% 2012:2024), all(year(x$rel_date) == x$release), all(x$radio_track %in% 0:1),
          identical(is.na(x$mortality), is.na(x$mortyear)), sum(!is.na(x$mortyear)) == 58L,
          all(year(x$mortality) == x$mortyear, na.rm = TRUE), all(x$mortyear >= x$release, na.rm = TRUE))
H <- as.matrix(x[, ..yrs])
stopifnot(!anyNA(H), all(H %in% 0:1), all(H[cbind(seq_len(nrow(x)), x$release - 2011L)] == 1L))
L <- data.table(i = rep(seq_len(nrow(x)), each = 13L), year = rep(2012:2024, nrow(x)), y = as.integer(c(t(H))))
L[, rel := x$release[i]]
stopifnot(L[year < rel, all(y == 0L)])
last_det <- L[y == 1L, .(last = max(year)), by = i]
x[, last := last_det$last[match(seq_len(.N), last_det$i)]]
late <- x[!is.na(mortyear) & last > mortyear]
stopifnot(identical(late$ID, 212L), late$last == 2020L)
x[, end := fifelse(is.na(mortyear), 2024L, pmax(mortyear, last))]
L[, end := x$end[i]]
L <- L[year >= rel & year <= end]
stopifnot(L[, sum(y)] == sum(H))
long <- L[, .(unit = as.character(x$ID[i]), taxon = "TETURO", y, period = year - 2011L,
              obs_release = as.integer(year == rel),
              unit_origin = x$origin[i], unit_sex = x$sex[i], unit_catch_weight_g = x$catch_weight[i],
              unit_radio_track = x$radio_track[i], unit_release_date = as.character(x$rel_date[i]),
              unit_death_date = as.character(x$mortality[i]))]
long <- order_eco(long)
stopifnot(uniqueN(long$unit) == 552L, sum(long$obs_release) == 552L)

periods <- data.table(period = 1:13, period_year = 2012:2024)
taxa <- make_taxa("TETURO", "Tetrao urogallus", vernacularName = "Western capercaillie")
stopifnot(identical(iucn_category(taxa$taxonID, taxa$scientificName), "LC"))

dataset <- list(
  title = "Annual encounter histories of 552 capercaillie released in Lower Lusatia, Germany, 2012-2024",
  creator = "Ludwig, Tobias; Alexander, Erdbeer; Ludwig, Arne; Lieckfeldt, Dietmar; Höglund, Jacob; Thielemann, Lars",
  pubDate = "2026", doi = "10.5061/dryad.73n5tb3cn", sourceURL = "https://doi.org/10.5061/dryad.73n5tb3cn",
  citation = "Ludwig, T., Alexander, E., Ludwig, A., Lieckfeldt, D., Höglund, J., & Thielemann, L. (2026). Data from: Long-term apparent survival of capercaillie (Tetrao urogallus) translocated from Sweden to East Germany [Dataset]. Dryad. https://doi.org/10.5061/dryad.73n5tb3cn",
  paperDOI = "10.1002/wlb3.01532",
  abstract = "Every capercaillie released in a reintroduction programme in Lower Lusatia, eastern Germany, 2012-2024: adults caught in Sweden and translocated, and juveniles reared by translocated hens under the 'born to be free' method. Each bird's release, sex, body mass, transmitter, confirmed death and annual encounters from summer feather genotyping and telemetry; the authors used the histories to estimate apparent survival after release.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Birds ringed and released (the release year is the marking occasion); thereafter encountered each year by non-invasive genetic monitoring (feathers collected at dust-bathing and other sites, June-August, identified by mitochondrial sequencing and microsatellite genotyping) and, for transmitter-carrying birds, by telemetry (intensive in 2012-2014).",
  samplingProtocolCode = "feather_genotyping", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one encounter record per bird per year (genetic and telemetry detections pooled in the deposit)",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none",
  geographicCoverage = "Lower Lusatia (Niederlausitz), Brandenburg, Germany; no coordinates deposited",
  temporalCoverage = "2012/2024",
  covariateNote = "obs_release: 1 on the release-year row (y = 1 there is the release, not a monitoring detection). unit_origin: SE (wild-caught adult from Sweden) or btbf (reared by its translocated mother, 'born to be free'). unit_radio_track: 1 if the bird carried a GPS/radio transmitter (telemetry detections are near-certain while it worked). unit_death_date: confirmed death, NA otherwise.",
  notShipped = list(mortyear = "the year of unit_death_date"),
  notes = "Rows run from the release year to 2024, or to the year of a confirmed death. Bird 212 was confirmed dead on 2019-09-11 but is encountered in 2020 in the deposit (possibly a feather shed before death); its rows run to 2020 as deposited. 40 of the 58 confirmed deaths fall in the release year.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ludwig_2026_lusatia_capercaillie_cjs.R")
stage_dict_row(TABLE,
  description = "Annual encounter histories (feather genotyping and telemetry) of 552 capercaillie translocated from Sweden or reared by translocated hens and released in Lower Lusatia, Germany, 2012-2024, with origin, sex, mass, transmitter and confirmed deaths.",
  url = "https://doi.org/10.5061/dryad.73n5tb3cn",
  reference = "Ludwig, T., et al. (2026). Long-term apparent survival of capercaillie (Tetrao urogallus) translocated from Sweden to East Germany. Wildlife Biology. https://doi.org/10.1002/wlb3.01532",
  doi_paper = "10.1002/wlb3.01532", doi_data = "10.5061/dryad.73n5tb3cn",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; release year flagged obs_release; histories end at confirmed death.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "feather_genotyping", design = "Multi-season (13 annual periods, release cohorts 2012-2024)",
  realm = "Terrestrial", country = "DEU", coordinates = "None in source",
  notes = "Reintroduced grouse; detections mix genetic sampling and telemetry.")
