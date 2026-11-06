#!/usr/bin/env Rscript
# Table:  barrile_2022_bridgerteton_toad_msrd
# Source: Dryad, doi:10.5061/dryad.rv15dv49j, version 183161 (published 2022-06-15), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API). Barrile, G. M., Chalfoun, A. D., Estes-Zumpf, W. A. & Walters, A. W.
#         Data from: Wildfire influences individual growth and breeding dispersal, but not survival and recruitment in
#         a montane amphibian.
# Paper:  Barrile, G. M., Chalfoun, A. D., Estes-Zumpf, W. A. & Walters, A. W. (2022). Wildfire influences individual
#         growth and breeding dispersal, but not survival and recruitment in a montane amphibian. Ecosphere 13:
#         e4212. doi:10.1002/ecs2.4212 (not in Europe PMC; the publisher refused the scripted request; not read).
#         From the Dryad abstract: capture-mark-recapture of adult boreal toads (n = 1415) 2015-2020 in the
#         Bridger-Teton National Forest, Wyoming, with the 2018 Roosevelt wildfire burning two of the four sites;
#         robust design capture-recapture models.
# Data:   ECS21-0740_Capture-Histories_Aboreas_2015-2020.txt (1415 toads): Capture_History (35 characters, '0' not
#           captured, 'A' captured at the toad's primary site, 'B' captured at an alternative site), Site (Buck,
#           Chall, LowerGypsum, UpperGypsum stream reaches), Mountain_Range, Wildfire (Burned / Unburned), Tag_ID
#           (PIT tag), Avg_Mass_2015..2020 (mean body mass, g, of the toad's weighings that year).
#         ECS21-0740_Capture-Surveys_Aboreas_2015-2020.txt (3362 rows): one row per capture date per toad
#           (Survey_Date m/d/Y, Site, Tag_ID, BodyMass_<year>); no row for a survey with no capture.
#         Structure of the 35 history columns (derived and asserted here, not stated in the readme): matching each
#           toad's capture dates to its history positions gives 2015 = columns 1-6, 2016 = 7-15, 2017 = 16-21,
#           2018 = 22-27, 2019 = 28-32, 2020 = 33-35, the same column for a given site-date across toads; at some
#           site-years several field dates share one column (Chall 2017: 9 dates in 6 columns).
# Mapping (multi-state closed robust design; responseType state, unitKind individual): unit = Tag_ID, taxon =
#   ANABOR, period = year 1..6 (2015-2020), occasion = the history column within the year, y = 0 not captured,
#   1 'A' (primary site), 2 'B' (alternative site); y_raw = the letter. At risk (E4.4): adults of unknown age caught in
#   the wild, so rows from the study's first period to its end (no removals or lost tags are recorded).
#   Survey set (surveyEvidence = inferred): the deposit lists captures, not surveys. A toad has a row at every history
#   column in which its site was surveyed, and a site counts as surveyed at a column where any toad of that site
#   was captured there ('A'). Every 'B' capture falls in a column surveyed at the toad's site (asserted). Columns
#   in which a site was surveyed and nothing was caught are absent. unit_site, unit_mountain_range, unit_wildfire
#   (burned in 2018) are constant per toad (asserted); period_avg_mass_g = Avg_Mass_<year>.
# Not shipped: per-capture dates and body masses of the capture-survey file (where several field dates share one
#   history column the date cannot stand for the occasion, and uncaptured rows have no date); model estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "barrile_2022_bridgerteton_toad_msrd"
dir <- download_dryad("10.5061/dryad.rv15dv49j", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f_h <- file.path(dir, "ECS21-0740_Capture-Histories_Aboreas_2015-2020.txt")
f_s <- file.path(dir, "ECS21-0740_Capture-Surveys_Aboreas_2015-2020.txt")
stopifnot(file.exists(f_h), file.exists(f_s), length(list.files(dir)) == 4L)
h <- fread(f_h, colClasses = list(character = c("Capture_History", "Tag_ID")))
s <- fread(f_s, colClasses = list(character = c("Tag_ID", "Survey_Date")))
stopifnot(nrow(h) == 1415L, nrow(s) == 3362L, !anyDuplicated(h$Tag_ID), all(nchar(h$Capture_History) == 35L),
          setequal(s$Tag_ID, h$Tag_ID), all(grepl("^[0AB]{35}$", h$Capture_History)))
CH <- do.call(rbind, strsplit(h$Capture_History, ""))
stopifnot(sum(CH == "A") == 3364L, sum(CH == "B") == 62L)
stopifnot(identical(as.vector(table(h$Site)[c("Buck", "Chall", "LowerGypsum", "UpperGypsum")]), c(352L, 844L, 141L, 78L)),
          uniqueN(h[, .(Site, Mountain_Range, Wildfire)]) == 4L, uniqueN(h$Site) == 4L)
yr_of_col <- rep(1:6, c(6, 9, 6, 6, 5, 3)); occ_of_col <- sequence(c(6, 9, 6, 6, 5, 3))

# the year blocks: every capture date of a toad falls in the year of the history column it fills
s[, date := as.IDate(Survey_Date, format = "%m/%d/%Y")]
stopifnot(!anyNA(s$date), !anyDuplicated(s[, .(Tag_ID, date)]))
nA <- data.table(Tag_ID = rep(h$Tag_ID, 6), period = rep(1:6, each = nrow(h)),
                 nA = as.vector(sapply(1:6, function(p) rowSums(CH[, yr_of_col == p, drop = FALSE] == "A"))))
nS <- s[, .(nS = .N), by = .(Tag_ID, period = year(date) - 2014L)]
cmp <- merge(nA[nA > 0], nS, by = c("Tag_ID", "period"), all = TRUE)
stopifnot(!anyNA(cmp$period), all(cmp$period %in% 1:6))
cmp[is.na(nA), nA := 0L][is.na(nS), nS := 0L]
stopifnot(sum(cmp$nA > cmp$nS) == 6L, sum(cmp$nA < cmp$nS) == 4L)   # 10 toad-years where history and capture file disagree by one capture

# survey set: site x column with any 'A' capture
surv <- unique(rbindlist(lapply(1:35, function(j) data.table(Site = h$Site[CH[, j] == "A"], col = j))))
stopifnot(identical(surv[, .N, by = Site][order(Site)]$N, c(31L, 35L, 24L, 19L)))
bcap <- data.table(Site = rep(h$Site, 35), col = rep(1:35, each = nrow(h)), v = as.vector(CH))[v == "B"]
stopifnot(nrow(merge(bcap, surv, by = c("Site", "col"))) == 62L)

long <- merge(data.table(unit = h$Tag_ID, Site = h$Site), surv, by = "Site", allow.cartesian = TRUE)
long[, v := CH[cbind(match(unit, h$Tag_ID), col)]]
long[, `:=`(taxon = "ANABOR", y = c(`0` = 0L, A = 1L, B = 2L)[v], y_raw = v, period = yr_of_col[col], occasion = occ_of_col[col])]
stopifnot(nrow(long) == sum(h[, .N, by = Site][surv[, .N, by = Site], on = "Site", N * i.N]), sum(long$y == 1L) == 3364L, sum(long$y == 2L) == 62L)
mass <- melt(h[, c("Tag_ID", paste0("Avg_Mass_", 2015:2020)), with = FALSE], id.vars = "Tag_ID", value.name = "period_avg_mass_g")
mass[, period := as.integer(sub("Avg_Mass_", "", variable)) - 2014L][, variable := NULL]
long <- merge(long, mass, by.x = c("unit", "period"), by.y = c("Tag_ID", "period"), all.x = TRUE)
uc <- h[, .(unit = Tag_ID, unit_site = Site, unit_mountain_range = Mountain_Range, unit_wildfire = Wildfire)]
long <- merge(long, uc, by = "unit")
long[, c("Site", "col", "v") := NULL]
long <- order_eco(long)
cat(sprintf("  %d rows; %d toads; surveyed site-columns %d\n", nrow(long), uniqueN(long$unit), nrow(surv)))

taxa <- make_taxa("ANABOR", "Anaxyrus boreas boreas", vernacularName = "Boreal toad", taxonRank = "subspecies")
periods <- data.table(period = 1:6, year = 2015:2020, n_occasions = c(6L, 9L, 6L, 6L, 5L, 3L),
                      first_capture_date = as.character(s[, min(date), by = .(p = year(date))][order(p)]$V1),
                      last_capture_date = as.character(s[, max(date), by = .(p = year(date))][order(p)]$V1))

dataset <- list(
  title = "Multi-state robust-design capture histories of 1415 adult boreal toads at four breeding sites, two burned by wildfire, Bridger-Teton National Forest, Wyoming, 2015-2020",
  creator = "Barrile, Gabriel M.; Chalfoun, Anna D.; Estes-Zumpf, Wendy A.; Walters, Annika W.", pubDate = "2022-06-15",
  doi = "10.5061/dryad.rv15dv49j", paperDOI = "10.1002/ecs2.4212", sourceURL = "https://doi.org/10.5061/dryad.rv15dv49j",
  citation = "Barrile, G. M., Chalfoun, A. D., Estes-Zumpf, W. A., & Walters, A. W. (2022). Data from: Wildfire influences individual growth and breeding dispersal, but not survival and recruitment in a montane amphibian [Dataset]. Dryad. https://doi.org/10.5061/dryad.rv15dv49j",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-mark-recapture of PIT-tagged adult boreal toads at four stream-reach breeding sites in western Wyoming over six breeding seasons (2015-2020), with three to nine capture occasions per season; the 2018 Roosevelt wildfire burned two sites. Each capture records whether the toad was at its primary site or an alternative breeding site. The authors fitted robust design models of growth, breeding dispersal, survival and recruitment.",
  samplingProtocol = "Repeated capture surveys of adult toads at breeding sites in May-June each year; toads PIT-tagged at first capture, weighed, and recorded as captured at their primary site or an alternative site.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "inferred",
  surveyEvidenceNote = "The deposit lists captures, not surveys. A site counts as surveyed at a history column where any toad of that site was captured at its primary site ('A'); every toad of the site has a row at each such column, from the study's first season (adults of unknown age, E4.4). Columns at which a site was surveyed and no toad was caught are absent (Upper Gypsum has no 2020 capture and so no 2020 rows).",
  responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not captured", `1` = "captured at its primary site (A)", `2` = "captured at an alternative breeding site (B)"),
  closure = "closed", closureNote = "robust design: closure assumed within a breeding season, open between seasons; several field dates share one occasion at some site-years",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Bridger-Teton National Forest, western Wyoming, USA: Buck and Chall creeks (Wyoming Range, burned 2018) and Lower and Upper Gypsum creeks (Wind River Range, unburned); no coordinates deposited",
  temporalCoverage = "2015-05/2020-06",
  covariateNote = "unit_site, unit_mountain_range, unit_wildfire: the toad's primary site, its range, and whether the site burned in the 2018 Roosevelt fire. period_avg_mass_g: the toad's mean body mass (g) over its weighings that season (NA if not weighed).",
  notShipped = list(capture_dates = "per-capture dates and body masses (ECS21-0740_Capture-Surveys): at some site-years several field dates share one history column, so a date does not identify the occasion, and uncaptured rows have none; the season mean mass ships as period_avg_mass_g",
                    model_output = "growth, dispersal, survival and recruitment estimates"),
  notes = "History column layout per season (6, 9, 6, 6, 5, 3) derived from the capture dates and asserted. In 10 toad-seasons the history and the capture file disagree by one capture (6 with an extra history capture, 4 with an extra capture date); the history is shipped.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/barrile_2022_bridgerteton_toad_msrd.R")
stage_dict_row(TABLE,
  description = "Multi-state robust-design capture histories (primary vs alternative breeding site) of 1415 PIT-tagged adult boreal toads at four sites in western Wyoming, 2015-2020, two burned in the 2018 Roosevelt fire.",
  url = "https://doi.org/10.5061/dryad.rv15dv49j",
  reference = "Barrile, G. M., Chalfoun, A. D., Estes-Zumpf, W. A., & Walters, A. W. (2022). Wildfire influences individual growth and breeding dispersal, but not survival and recruitment in a montane amphibian. Ecosphere, 13, e4212.",
  doi_paper = "10.1002/ecs2.4212", doi_data = "10.5061/dryad.rv15dv49j", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Survey set inferred (site surveyed at an occasion where any of its toads was captured); paper not read.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Multi-state closed robust design capture-recapture",
  sampling_protocol = "hand_capture", design = "Robust design (6 breeding seasons x 3-9 occasions; 4 sites)",
  realm = "Freshwater", country = "USA", coordinates = "None in source", notes = "Wildfire before-after-control-impact on amphibian vital rates and breeding dispersal.")
