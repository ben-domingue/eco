#!/usr/bin/env Rscript
# Table:  dooley_2025_agapostemon_cjs
# Source: Dryad doi:10.5061/dryad.80gb5mm2j (CC0 1.0, as shown on the Dryad page; published
#         2025-07-29). Dooley, K., Murphy, A. & Crone, E. (2025). Landscape context affects both
#         capture probability and abundance of solitary bees in cities.
# Paper:  Dooley, K.A., Murphy, A.W. & Crone, E.E. (2025). Landscape context affects both capture
#         probability and abundance of solitary bees in cities. Ecological Applications 35(6),
#         e70099, doi:10.1002/eap.70099. Mark-resight of the bicolored sweat bee (Agapostemon
#         virescens) at experimental Echinacea purpurea patches, one inside ("G") and one outside
#         ("N") each of seven community gardens in Cambridge, Somerville and Medford,
#         Massachusetts, July 2023; CJS models in RMark (CMR_04.04.2024.R, groups pot x site).
# Data:   README.md (codebook); captures_for_Mark_03.01.2024.csv: 150 rows, one per individual
#         bee at one patch: ch (16 characters, 1 seen / 0 patch monitored, bee not seen / "."
#         patch not monitored), pot (G/N), site (7 gardens), imperv (% impervious surface within
#         100 m of the patch), int (15 survey intervals in days: 1,1,1,1,2 repeated; the
#         authors' approximation, not the calendar, see below). Mark_recap_raw.csv: 256 rows,
#         one per capture (Date day-month, Site, Time_start of the 30-min watch, Capture_time,
#         Pot, Mark_ID colour code, Recap 0/1), plus two all-zero rows (TIS, no bee seen);
#         includes three sites not in the capture histories (BAR, TIS, WIN; WIN dropped by the
#         authors because its landscape is mostly river) and the bees that moved between patches.
#         Imp_vals_perpot.csv and Gard_size.csv: impervious surface and garden size/flowers per
#         site. Two R scripts (analysis code).
#         The 16 survey days (from the raw dates): gardens BIK, POW, TUF were watched on July
#         5, 6, 9, 11, 14, 15, 19, 20 and LIN, MCM, SAC, WAL on July 7, 8, 12, 13, 17, 18, 21, 23,
#         alternating in pairs; this matches the ch "." pattern (xx..xx.. and ..xx..xx) exactly.
# Mapping: unit = one bee at one patch (site_pot_MarkID; the authors' history unit, see the two-patch note); taxon =
#         AGAVIR; period = survey day 1-16 in calendar order, one row per bee for each of the 8
#         days its patch was watched (ch "." = no row, E4); y = 1 seen during the watch, 0 not
#         seen. Rows run over the full study for every bee (caught in the wild, E4.4), which is
#         the deposited history rectangle. date = the survey day (ISO). unit_site, unit_pot
#         (G garden / N non-garden), unit_imperv_pct (patch-level impervious %, constant within
#         unit), unit_garden_area_m2 and unit_garden_flowers (Gard_size.csv).
#         surveyEvidence = deposited_matrix: the ch strings distinguish 0 from ".".
#         The unit labels come from Mark_recap_raw.csv: the script rebuilds every history from
#         the raw captures and asserts that, site by site and patch by patch, the multiset of
#         rebuilt histories equals the deposited ch file (so the raw-to-history mapping is the
#         authors' own).
#         Seven bees were seen at both patches of their garden. The README says such bees were
#         left out of the histories, but the deposited file carries each of them twice, once per
#         patch (the multiset assertion proves it); the table follows the file, so these are 14
#         units, flagged unit_two_patch = 1 and joinable by unit_site + unit_mark_id.
# Not shipped: captures at BAR, TIS and WIN (no history file entry; WIN excluded by the
#         authors); the int column (approximate; the calendar dates are shipped); capture times
#         within the watch; all model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dooley_2025_agapostemon_cjs"
dir <- download_dryad("10.5061/dryad.80gb5mm2j", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

ch <- fread(file.path(dir, "captures_for_Mark_03.01.2024.csv"), colClasses = c(ch = "character"))
raw <- fread(file.path(dir, "Mark_recap_raw.csv"), colClasses = "character")
gs <- fread(file.path(dir, "Gard_size.csv"), encoding = "UTF-8"); setnames(gs, 1, "Site")
stopifnot(nrow(ch) == 150, all(nchar(ch$ch) == 16), all(grepl("^[01.]+$", ch$ch)), nrow(raw) == 256)

# the 16 survey days, in order, and which sites were watched on each
raw[, d := as.IDate(sprintf("2023-07-%02d", as.integer(sub("-Jul$", "", Date))))]
stopifnot(all(grepl("-Jul$", raw$Date)))
days <- sort(unique(raw$d)); stopifnot(length(days) == 16)
grpA <- c("BIK", "POW", "TUF"); grpB <- c("LIN", "MCM", "SAC", "WAL")
patA <- "11..11..11..11.."; patB <- "..11..11..11..11"
watched <- function(s) if (s %in% grpA) strsplit(patA, "")[[1]] == "1" else strsplit(patB, "")[[1]] == "1"
stopifnot(identical(sort(unique(ch$site)), sort(c(grpA, grpB))))
for (s in unique(ch$site)) {   # the ch "." pattern is the site's watch schedule
  w <- watched(s)
  stopifnot(all(sapply(strsplit(ch[site == s]$ch, ""), function(x) identical(x != ".", w))))
  stopifnot(all(raw[Site == s, unique(d)] %in% days[w]))
}

# rebuild histories from the raw captures
cap <- raw[Site %in% c(grpA, grpB) & Mark_ID != "0"]
stopifnot(all(cap$Pot %in% c("G", "N")))
# bees seen at both patches of a garden: the README says they were left out, but the
# deposited history file carries them once per patch (asserted below by the multiset match)
movers <- cap[, .(np = uniqueN(Pot)), by = .(Site, Mark_ID)][np > 1]
stopifnot(nrow(movers) == 7)
cap[, per := match(d, days)]
hist <- cap[, .(ch = {
  w <- watched(Site[1]); x <- ifelse(w, "0", "."); x[unique(per)] <- "1"; paste(x, collapse = "")
}), by = .(Site, Pot, Mark_ID)]
for (s in unique(ch$site)) for (p in c("G", "N"))
  stopifnot(identical(sort(hist[Site == s & Pot == p]$ch), sort(ch[site == s & pot == p]$ch)))
stopifnot(nrow(hist) == 150)
hist <- merge(hist, unique(ch[, .(site, pot, imperv)]), by.x = c("Site", "Pot"), by.y = c("site", "pot"))
stopifnot(nrow(hist) == 150)
hist <- merge(hist, gs[, .(Site, Area_m2, Fl_counts_ingard)], by = "Site", all.x = TRUE)
stopifnot(!anyNA(hist$Area_m2))
hist[, unit := paste(Site, Pot, Mark_ID, sep = "_")]
hist[, two_patch := as.integer(paste(Site, Mark_ID) %in% paste(movers$Site, movers$Mark_ID))]
stopifnot(sum(hist$two_patch) == 14)
stopifnot(!anyDuplicated(hist$unit))

long <- hist[, {
  x <- strsplit(ch, "")[[1]]; k <- which(x != ".")
  .(period = k, y = as.integer(x[k]))
}, by = .(unit, Site, Pot, Mark_ID, two_patch, imperv, Area_m2, Fl_counts_ingard)]
long <- long[, .(unit, taxon = "AGAVIR", period, y, date = as.character(days[period]),
                 unit_site = Site, unit_pot = Pot, unit_mark_id = Mark_ID, unit_two_patch = two_patch, unit_imperv_pct = round(imperv, 3),
                 unit_garden_area_m2 = Area_m2, unit_garden_flowers = Fl_counts_ingard)]
setorder(long, unit, period)
stopifnot(nrow(long) == 150 * 8, sum(long$y) == sum(nchar(gsub("[^1]", "", ch$ch))))

taxa <- make_taxa("AGAVIR", "Agapostemon virescens", vernacularName = "Bicolored sweat bee")
periods <- data.table(period = 1:16, date = as.character(days),
                      sites_watched = ifelse(strsplit(patA, "")[[1]] == "1", "BIK POW TUF", "LIN MCM SAC WAL"))

dataset <- list(
  title = "Mark-resight histories of 143 bicolored sweat bees (150 bee-patch histories) at 14 flower patches over 16 survey days, greater Boston, July 2023",
  creator = "Dooley, Karen; Murphy, Atticus; Crone, Elizabeth", pubDate = "2025",
  doi = "10.5061/dryad.80gb5mm2j", sourceURL = "https://doi.org/10.5061/dryad.80gb5mm2j",
  citation = "Dooley, K., Murphy, A., & Crone, E. (2025). Landscape context affects both capture probability and abundance of solitary bees in cities [Dataset]. Dryad. https://doi.org/10.5061/dryad.80gb5mm2j",
  paperDOI = "10.1002/eap.70099",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Individually colour-marked Agapostemon virescens watched for 30 minutes at experimental Echinacea purpurea patches inside and outside seven community gardens along an impervious-surface gradient in Cambridge, Somerville and Medford, Massachusetts. Each garden pair of patches was watched on 8 of 16 days in July 2023.",
  samplingProtocol = "Colour-marked bees resighted during 30-minute morning watches at potted Echinacea patches; each patch watched on 8 of 16 survey days (two groups of gardens alternating in pairs of days).",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "open population across the 16 days (CJS); one watch per patch per survey day",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Cambridge, Somerville and Medford, Massachusetts, USA (no coordinates deposited)",
  temporalCoverage = "2023-07/2023-07",
  notShipped = list(
    other_sites = "captures at BAR, TIS and WIN, which have no capture histories (WIN excluded by the authors because the surrounding landscape is mostly river)",
    int = "the deposited 15 survey intervals (approximate); the calendar dates are shipped in date and __periods",
    capture_time = "time of each capture within the 30-minute watch",
    model_output = "RMark estimates"),
  notes = "Unit = one bee at one patch (site_pot_colour code), the authors' history unit; 7 bees seen at both patches of their garden appear as two units each (unit_two_patch = 1), as in the deposited history file although its README says they were excluded. The script rebuilds every history from the raw capture file and asserts it equals the deposited capture-history file patch by patch.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dooley_2025_agapostemon_cjs.R")
stage_dict_row(TABLE,
  description = "Cormack-Jolly-Seber resight histories of colour-marked bicolored sweat bees (Agapostemon virescens) at garden and non-garden Echinacea patches in seven Boston-area community gardens, 16 survey days in July 2023, with patch impervious surface.",
  url = "https://doi.org/10.5061/dryad.80gb5mm2j",
  reference = "Dooley, K. A., Murphy, A. W., & Crone, E. E. (2025). Landscape context affects both capture probability and abundance of solitary bees in cities. Ecological Applications, 35(6), e70099.",
  doi_paper = "10.1002/eap.70099", doi_data = "10.5061/dryad.80gb5mm2j",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Histories rebuilt from the raw captures and asserted equal to the deposited MARK file; 7 bees seen at both patches appear once per patch, as in the deposited file (README says excluded).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "CJS capture-recapture",
  sampling_protocol = "tag_resight", design = "Multi-session (16 survey days, each patch watched on 8)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Urban bee mark-resight; unit is a bee at a patch.")
