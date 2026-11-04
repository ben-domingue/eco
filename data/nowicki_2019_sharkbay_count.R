#!/usr/bin/env Rscript
# Table:  nowicki_2019_sharkbay_count (replaces nowicki_2019_sharkbay_megafauna_count,
#         nowicki_2019_sharkbay_turtle_count and nowicki_2019_sharkbay_dolphin_count; ruling #31)
# Source: Dryad doi:10.5061/dryad.7sg523n, version 23816 (published 2019-02-20), Nowicki, Heithaus,
#         Thomson, Burkholder, Gastrich & Wirsing. Licence as shown on the Dryad record: CC0 1.0
#         (https://spdx.org/licenses/CC0-1.0.html). The README tab asks users of the data in further
#         analyses to contact Rob Nowicki (a courtesy request, not a licence term).
# Paper:  Nowicki, R., Heithaus, M., Thomson, J., Burkholder, D., Gastrich, K. & Wirsing, A. (2019).
#         Indirect legacy effects of an extreme climactic event on a marine megafaunal community.
#         Ecological Monographs 89(2), e01365, doi:10.1002/ecm.1365.
# Data:   Nowicki_Transect_Raw_Data_2-19-2019.xlsx, three tabs:
#           "Surface Transect Data": 4,038 rows, one per run of a permanent boat transect ("focal
#             zone" FZ.st, 13 ids) in the Eastern Gulf of Shark Bay, Western Australia, 1997-2014
#             (none in 2000, 2001, 2005). Date (Excel serial), Year / Month / day, prepost (pre /
#             during / post the 2011 heatwave), five usability flags, habitat (shallow / deep /
#             edge), Season (warm / cool), counts of unique animals inside each taxon's sighting
#             band (dol dolphins, dug dugongs, ss sea snakes, cor cormorants, T.total turtles =
#             GT.uncorr green + LT.uncorr loggerhead + unk.T unidentified, asserted), their 0/1
#             versions, densities (count / band area), pre-heatwave seasonal mean densities and
#             relative densities, monthly shark catch per unit effort from the authors' separate
#             drumline fishing (all sharks, sharks > 3 m, tiger sharks, tiger sharks > 3 m),
#             transect length (km), band areas (length x a fixed band width per taxon: dugong 0.2,
#             dolphin 0.4, sea snake 0.01, cormorant and turtle 0.06 km; asserted), mean transect
#             depth, monthly mean water temperature, number of observers, start / end clock times
#             (Excel day fractions, "-" when not recorded), minutes suspended, raw and net
#             duration, Beaufort sea state and a visibility code (both typed inconsistently).
#           "Column Key": the definitions used below. "README": citation, contact, and that the
#             data were curated from the raw entry sheets for the paper's transect analyses.
#         Quirks: the key says Cool = May-August, but every May transect is coded warm and August
#           runs are split between cool and warm (the data are followed; Season is a run covariate). 480 rows are usable = "no" (surface
#           conditions or data not good enough for analysis), including every run of FZ 13 and 14
#           and 23 paired "E"-prefixed 2007 entries. Two usable entries are double: a row with ID
#           "-" at FZ 6 on 2014-04-04 has the same times as 6201444 but no cormorants where the
#           latter has four (the ID-bearing row is kept); 72014625 appears twice on 2014-06-25 with
#           overlapping times and identical counts (one kept). 6201459 is run twice on 2014-05-09
#           (11:29 and 15:58), a genuine second pass. Two Date cells (IDs 122006106, 52014421) are
#           a day or a month off the Year / Month / day columns, which agree with the ID; the
#           ID-consistent date is used (asserted). 122006106 is itself entered twice with identical
#           times and counts (the copy carrying the off Date cell is dropped).
#
# Mapping (standard E1-E5, repeated strip-transect counts / N-mixture):
#   unit = focal zone ("FZ01".."FZ12"; 11 have usable runs), period = survey month (year-month
#   index ordered in time; the field team sampled monthly), occasion = run of the transect
#   within the month, ordered by date and start time (1-12), y = unique animals of the taxon
#   seen inside its sighting band on that run. date = the run's date.
#   Survey sets: ONE table (ruling #31: one deposit x protocol x response type); the deposit's
#   own flags say which taxa each run counted, carried by __survey_taxa (taxon x unit x period
#   x occasion, E4.2):
#     dugong, sea snakes (Hydrophiinae, several species pooled by the source; no GBIF key, the
#       backbone has no Hydrophiinae) and cormorants (Phalacrocorax, pooled) on every usable run
#       (3,555 after the three doubles);
#     green and loggerhead turtles on usable runs with use.for.turts = "yes" (runs where turtles
#       could all be identified to species; the 207 unidentified turtles that remain on those
#       runs are obs_unidentified_turtles, which is shipped on turtle runs only);
#     Indo-Pacific bottlenose dolphins on usable runs with use.for.dol = "yes" (the source says
#       dolphins were not reliably counted in 2002-2007).
#   closure = closed (runs within a month; closureNote: mobile megafauna move between zones,
#   so closure is approximate), occasionKind = time, taxonInclusion = target (the six counted
#   taxa the protocol names).
#   surveyEvidence = sample_table: one row per transect run, counts of zero included.
#   Covariates: unit_habitat (modal habitat of the zone; four zones have one to three runs coded
#   otherwise, asserted), unit_transect_km (constant per zone within a run of years; the run
#   value is obs_transect_km, the effort column), obs_depth_m, obs_start_time,
#   obs_n_observers, obs_beaufort, obs_visibility, obs_season (warm / cool as coded; the switch
#   falls within August, so it is a run fact); period_ covariates: year, month, heatwave phase
#   (pre / during / post), mean water temperature, and the four shark CPUE
#   values (fishing surveys separate from these transects, not derived from these detections).
#   Coordinates: none in the deposit (zones are identified by number only). Dugong and loggerhead
#   are IUCN VU (green turtle LC since the 2025 global reassessment, per GBIF), but there is nothing
#   to coarsen.
#   Not shipped: densities, pre-heatwave mean densities and relative densities (derived from these
#   counts), the 0/1 versions, band areas (length x fixed width), T.total (the sum of the turtle
#   columns), unusable runs, FZ 13 and 14 (never usable), the doubled entries.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
STEM <- "nowicki_2019_sharkbay_count"
dir <- download_dryad("doi:10.5061/dryad.7sg523n", STEM)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "23816")
f <- file.path(dir, "Nowicki_Transect_Raw_Data_2-19-2019.xlsx")
stopifnot(identical(excel_sheets(f), c("Surface Transect Data", "Column Key", "README")))
d <- as.data.table(read_excel(f, "Surface Transect Data", col_types = "text"))
stopifnot(nrow(d) == 4038, ncol(d) == 72)
num <- function(x) suppressWarnings(as.numeric(x))
cnt <- c("dol", "dug", "ss", "cor", "T.total", "GT.uncorr", "LT.uncorr", "unk.T")
for (c in c(cnt, "Year", "Month", "day", "FZ.st")) set(d, j = c, value = as.integer(d[[c]]))
stopifnot(!anyNA(d[, ..cnt]), d[, all(T.total == GT.uncorr + LT.uncorr + unk.T)],
          all(d$usable %in% c("yes", "no")), all(d$use.for.turts %in% c("yes", "no")), all(d$use.for.dol %in% c("yes", "no")),
          sum(d$usable == "yes") == 3558, d[usable == "no", all(use.for.turts == "no" & use.for.dol == "no")],
          d[use.for.dol == "yes", all(!Year %in% 2002:2007)], d[Year %in% 2002:2007, all(use.for.dol == "no")],
          all(d$Season %in% c("warm", "cool")), d[Month == 5, all(Season == "warm")],
          d[, all(dol.bin == as.integer(dol > 0))], d[, uniqueN(FZ.st)] == 13, d[usable == "yes", !any(FZ.st %in% 13:14)])
d[, date_cell := as.IDate(as.Date(num(Date), origin = "1899-12-30"))]
d[, date := as.IDate(sprintf("%04d-%02d-%02d", Year, Month, day))]
# two Date cells disagree with Year / Month / day, which agree with the ID (FZ + yyyy + m + d): the ID is followed
bad <- d[date_cell != date]
stopifnot(!anyNA(d$date), !anyNA(d$date_cell), nrow(bad) == 2, setequal(bad$ID, c("122006106", "52014421")),
          bad[, all(ID == paste0(FZ.st, Year, Month, day))])
d[, km := num(`TRlng(km)`)]
bands <- c(dug.area = 0.2, dol.area = 0.4, ss.area = 0.01, cor.area = 0.06, turt.area = 0.06)
for (b in names(bands)) stopifnot(d[, all(abs(num(get(b)) - km * bands[[b]]) < 1e-6)])

u <- d[usable == "yes"]
# the two doubled entries (see header)
stopifnot(u[ID == "-", .N] == 1, u[ID == "-", FZ.st == 6 & date == as.IDate("2014-04-04")],
          u[ID == "6201444", .N] == 1, u[ID == "6201444", `Time S` == u[ID == "-", `Time S`] & cor == 4], u[ID == "-", cor == 0],
          u[ID == "72014625", .N] == 2, uniqueN(u[ID == "72014625", ..cnt]) == 1)
u <- u[ID != "-"]
u <- u[!(ID == "72014625" & duplicated(ID))]
stopifnot(u[ID == "122006106", .N] == 2, uniqueN(u[ID == "122006106", c(cnt, "Time S", "Time E"), with = FALSE]) == 1)
u <- u[!(ID == "122006106" & date_cell != date)]                    # the copy with the off-by-one Date cell
stopifnot(nrow(u) == 3555, u[, .N, by = .(FZ.st, date, `Time S`)][, all(N == 1)])

# clock times are Excel day fractions (some with a date part); "-" not recorded
# clock times come as Excel day fractions (some carrying a date serial) or, in 1998, as HHMM integers
tfrac <- function(x) {
  v <- num(x); out <- rep(NA_character_, length(v))
  hhmm <- !is.na(v) & v >= 1 & v < 2400 & v == round(v)
  stopifnot(all(v[hhmm] %% 100 < 60), all(v[!is.na(v) & !hhmm & v >= 1] > 30000))
  out[hhmm] <- sprintf("%02d:%02d", as.integer(v[hhmm] %/% 100), as.integer(v[hhmm] %% 100))
  fr <- !is.na(v) & !hhmm; m <- round((v[fr] %% 1) * 1440)
  out[fr] <- sprintf("%02d:%02d", (m %/% 60) %% 24, m %% 60)
  out
}
u[, start := tfrac(`Time S`)]
u[, `:=`(n_obs = as.integer(num(Obs)), beaufort = num(Beaufort.std), depth = num(Trdepth),
         vis = fifelse(tolower(vis.std) %in% c("good", "bad"), tolower(vis.std), NA_character_))]
stopifnot(u[!is.na(beaufort), all(beaufort >= 0 & beaufort <= 4)], !anyNA(u$km), !anyNA(u$depth),
          sum(num(u$Total) <= 0, na.rm = TRUE) > 200)          # net durations are unreliable (negative, zero raw times): not shipped

# units: modal habitat per zone
hab <- u[, .N, by = .(FZ.st, HAB.st)][order(FZ.st, -N)]
stopifnot(hab[, .(odd = sum(N) - max(N)), by = FZ.st][, all(odd <= 3)])
units <- hab[, .(unit_habitat = HAB.st[1]), by = FZ.st]
u[, unit := sprintf("FZ%02d", FZ.st)]; units[, unit := sprintf("FZ%02d", FZ.st)]

# periods: survey month, ordered in time; period covariates constant within month (asserted)
u[, ym := sprintf("%04d-%02d", Year, Month)]
pm <- u[, .(temp = uniqueN(m.avg.temp), cpue = uniqueN(month.cpue.all), seas = uniqueN(Season), pp = uniqueN(prepost)), by = ym]
stopifnot(pm[, all(temp == 1 & cpue == 1 & pp == 1)], pm[seas > 1, all(substr(ym, 6, 7) == "08")])   # season changes within August: a run fact
per <- unique(u[, .(ym, Year, Month, prepost, temp = num(m.avg.temp), cpue_all = num(month.cpue.all),
                    cpue_3m = num(month.cpue.3m), cpue_tiger = num(month.cpue.GC), cpue_tiger_3m = num(month.cpue.3m.GC))])[order(ym)]
per[, period := seq_len(.N)]
u[, period := per$period[match(ym, per$ym)]]
setorder(u, unit, period, date, start)
u[, occasion := seq_len(.N), by = .(unit, period)]
stopifnot(max(u$occasion) == 12L)
periods_all <- per[, .(period, period_year = Year, period_month = Month, period_heatwave_phase = prepost,
                       period_mean_water_temp_c = temp, period_shark_cpue_all = cpue_all, period_shark_cpue_over3m = cpue_3m,
                       period_tigershark_cpue = cpue_tiger, period_tigershark_cpue_over3m = cpue_tiger_3m)]

surv_cols <- function(s) s[, .(unit, period, occasion, date = format(date), obs_transect_km = round(km, 4), obs_depth_m = round(depth, 3),
                               obs_start_time = start, obs_n_observers = n_obs, obs_beaufort = beaufort,
                               obs_visibility = vis, obs_season = Season, unit_habitat = units$unit_habitat[match(unit, units$unit)])]

TAXA <- data.table(
  col = c("dug", "ss", "cor", "GT.uncorr", "LT.uncorr", "dol"),
  taxon = c("DUGDUG", "HYDROPHIINAE", "PHALACROCORAX", "CHEMYD", "CARCAR", "TURADU"),
  sci = c("Dugong dugon", "Hydrophiinae", "Phalacrocorax", "Chelonia mydas", "Caretta caretta", "Tursiops aduncus"),
  vern = c("dugong", "sea snakes", "cormorants", "green turtle", "loggerhead turtle", "Indo-Pacific bottlenose dolphin"),
  rank = c("species", "subfamily", "genus", "species", "species", "species"),
  band = c(0.2, 0.01, 0.06, 0.06, 0.06, 0.4),
  run_flag = c("all", "all", "all", "use.for.turts", "use.for.turts", "use.for.dol"),
  remarks = c(NA, "Several sea snake species (Hydrophiinae) pooled by the source; the GBIF backbone holds no Hydrophiinae (it treats Hydrophiidae as a synonym of Elapidae), so no taxonID rather than a family match",
              "Cormorants pooled to genus by the source", NA, NA, NA))
taxa_all <- make_taxa(TAXA$taxon, TAXA$sci, vernacularName = TAXA$vern, taxonRank = TAXA$rank,
                      taxon_band_width_km = TAXA$band, taxonRemarks = TAXA$remarks, no_key = "HYDROPHIINAE")
stopifnot(taxa_all[taxon != "HYDROPHIINAE", !anyNA(taxonID) && all(gbifMatchType == "EXACT")], taxa_all[taxon == "HYDROPHIINAE", is.na(taxonID)])
taxa_all[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
cat("  IUCN:", paste(taxa_all$taxon, taxa_all$taxon_iucnCategory, collapse = "; "), "\n")
flagged <- taxa_all[taxon_iucnCategory %in% c("CR", "EN", "VU")]
stopifnot(nrow(flagged) >= 1)                                        # dugong and loggerhead VU at build time

TABLE <- "nowicki_2019_sharkbay_count"
base <- surv_cols(u)
base[, obs_unidentified_turtles := fifelse(u$use.for.turts == "yes", u$unk.T, NA_integer_)]
on_run <- function(flag) if (flag == "all") rep(TRUE, nrow(u)) else u[[flag]] == "yes"
long <- rbindlist(lapply(seq_len(nrow(TAXA)), function(i) {
  k <- on_run(TAXA$run_flag[i]); x <- copy(base[k]); x[, `:=`(taxon = TAXA$taxon[i], y = u[[TAXA$col[i]]][k])]; x }))
stopifnot(!anyNA(long$y), nrow(long) == 3 * nrow(u) + 2 * sum(u$use.for.turts == "yes") + sum(u$use.for.dol == "yes"),
          nrow(long) == 10665 + 6180 + 2338)
for (i in seq_len(nrow(TAXA))) stopifnot(long[taxon == TAXA$taxon[i], sum(y)] == sum(u[[TAXA$col[i]]][on_run(TAXA$run_flag[i])]))
long <- order_eco(long)
survey_taxa <- unique(long[, .(taxon, unit, period, occasion)])
periods <- periods_all[period %in% long$period]
dataset <- list(
  title = "Strip-transect counts of dugongs, sea snakes, cormorants, green and loggerhead turtles and Indo-Pacific bottlenose dolphins on 11 permanent boat transects, Shark Bay, Western Australia, 1997-2014",
  creator = "Nowicki, Robert; Heithaus, Michael; Thomson, Jordan; Burkholder, Derek; Gastrich, Kirk; Wirsing, Aaron",
  pubDate = "2019-02-20", sourceURL = "https://doi.org/10.5061/dryad.7sg523n",
  citation = "Nowicki, R., Heithaus, M., Thomson, J., Burkholder, D., Gastrich, K. & Wirsing, A. (2019). Indirect legacy effects of an extreme climactic event on a marine megafaunal community. Ecological Monographs 89(2), e01365. https://doi.org/10.1002/ecm.1365. Data: Dryad https://doi.org/10.5061/dryad.7sg523n (CC0).",
  paperDOI = "10.1002/ecm.1365", dataDOI = "10.5061/dryad.7sg523n",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = paste0("Monthly boat strip-transect surveys of permanent focal zones in the Eastern Gulf of Shark Bay over 15 years spanning the 2011 Ningaloo Nino marine heatwave and seagrass die-off. Counts of unique animals inside taxon-specific sighting bands on ", nrow(u),
                    " usable runs: dugongs, sea snakes and cormorants on every run; green and loggerhead turtles on the ", sum(u$use.for.turts == "yes"),
                    " runs where turtles could be identified to species; Indo-Pacific bottlenose dolphins on the ", sum(u$use.for.dol == "yes"), " runs outside 2002-2007."),
  samplingProtocol = "Boat-based strip transects along permanent focal zones in the Eastern Gulf of Shark Bay, run at low speed in good conditions by two to six observers; every unique animal of the target taxa seen inside a taxon-specific sighting band was counted (band widths: dugong 0.2 km, dolphin 0.4 km, cormorant and turtle 0.06 km, sea snake 0.01 km); zones were run one to twelve times per monthly field period.",
  samplingProtocolCode = "line_transect", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  effortColumn = "obs_transect_km",
  closure = "closed", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion within period: the runs of one focal zone within a calendar month; mobile megafauna move between zones, so closure is approximate; open between months",
  surveyTaxaNote = "The source's run flags say which taxa a run counted: dugong, sea snakes and cormorants on every usable run; green and loggerhead turtles only where use.for.turts = yes; dolphins only where use.for.dol = yes (not reliably counted 2002-2007). __survey_taxa lists the taxa per run.",
  temporalCoverage = sprintf("%s/%s", min(u$date), max(u$date)),
  surveyEvidenceNote = "Each row of the Surface Transect Data tab is one run of a permanent transect, with zero counts recorded; the source's usability flags select the runs (usable = yes) and the taxa counted on each (use.for.turts, use.for.dol).",
  geographicCoverage = list(description = "Eastern Gulf of Shark Bay, Western Australia (Monkey Mia region), shallow seagrass banks and deep channels; focal-zone coordinates not deposited"),
  coordinatesCoarsened = list(value = FALSE, method = sprintf("None in source: focal zones are numbered only; %s flagged (IUCN via GBIF) but no coordinates exist to coarsen",
                                                               paste(sprintf("%s (%s)", flagged$scientificName, flagged$taxon_iucnCategory), collapse = " and "))),
  notShipped = list(`*.d, *.d.old, *.rd, shg.d` = "densities, pre-heatwave seasonal mean densities and relative densities: derived from these counts",
                    `*.bin` = "0/1 versions of the counts", `*.area` = "band areas: transect length x a fixed band width per taxon (widths in __taxa)",
                    T.total = "the sum of the turtle columns",
                    `turtle and dolphin counts on unflagged runs` = "runs with use.for.turts = no (turtles not all identifiable) or use.for.dol = no (2002-2007) are not surveys for those taxa; their cells are not shipped",
                    `usable = no` = "480 runs the source marks as not meeting minimum requirements (sighting conditions, data reliability), incl. every run of FZ 13 and 14 and 23 E-prefixed 2007 entries",
                    `doubled entries` = "ID '-' at FZ 6 on 2014-04-04 (same times as 6201444, which is kept), the second 72014625 row on 2014-06-25 and the second 122006106 row (identical times and counts)",
                    `min out, Raw Time, Total, Time E` = "suspension minutes, raw and net duration (over 250 usable runs have zero or negative net minutes, the raw time being 0) and end time: not reliable enough to ship as effort; transect length is the effort column"))
ds <- write_table(long, TABLE, dataset, taxa = taxa_all, periods = periods, survey_taxa = survey_taxa,
                  script = "data/nowicki_2019_sharkbay_count.R")
stage_dict_row(TABLE,
  description = paste0(dataset$title, ": ", nrow(u), " runs of permanent focal zones, one to twelve per month, with transect length, depth, sea state, observers, heatwave phase, water temperature and shark catch rates; the taxa counted per run follow the source's flags (__survey_taxa)."),
  url = "https://doi.org/10.5061/dryad.7sg523n",
  reference = "Nowicki, R., Heithaus, M., Thomson, J., Burkholder, D., Gastrich, K. & Wirsing, A. (2019). Indirect legacy effects of an extreme climactic event on a marine megafaunal community. Ecological Monographs 89(2), e01365.",
  doi_paper = "10.1002/ecm.1365", doi_data = "10.5061/dryad.7sg523n", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Replaces nowicki_2019_sharkbay_megafauna_count, _turtle_count and _dolphin_count (ruling #31). Survey set and taxa per run from the source's usability flags; densities and relative densities not shipped (derived). No coordinates deposited.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Multiple",
  model_family = "N-mixture (open / multi-season)", sampling_protocol = "line_transect",
  design = sprintf("Multi-season (%d monthly periods x 1-12 runs per focal zone)", nrow(periods)),
  realm = "Marine", country = "AUS", coordinates = "None in source",
  notes = "Dugong, sea snakes, cormorants, turtles (species-identified runs), dolphins (not 2002-2007); heatwave phase and shark CPUE as period covariates.", status = "tagged")
