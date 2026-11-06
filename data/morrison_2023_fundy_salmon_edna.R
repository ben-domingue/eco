#!/usr/bin/env Rscript
# Table:  morrison_2023_fundy_salmon_edna  (station > sampling event > water-sample bottle > qPCR
#         replicate; endangered Inner Bay of Fundy Atlantic salmon eDNA in one New Brunswick river,
#         summer 2020 parr survey, 2020 full-transect survey and spring 2021 smolt survey)
# Source: Dryad doi:10.5061/dryad.9kd51c5n2 (CC0 1.0, as shown on the dataset page and in the API
#         record), version 238853 (published 2023-06-07).
#   Morrison, M. K. et al. (2023). Data from: Including environmental covariates clarifies the
#   relationship between endangered Atlantic salmon (Salmo salar) abundance and environmental DNA.
# Paper:  Morrison, M. K., Lacoursiere-Roussel, A., Wood, Z. T., Trudel, M., Gagne, N., LeBlanc, F.,
#         Samways, K., Kinnison, M. T. & Pavey, S. A. (2023). Including environmental covariates
#         clarifies the relationship between endangered Atlantic salmon (Salmo salar) abundance and
#         environmental DNA. Environmental DNA. doi:10.1002/edn3.424 (not read: Wiley refuses
#         scripted requests). Everything below is from the workbook and its README sheet.
# Data:   edn3424-data.xlsx (README.md says four sheets; it has six):
#         README  column definitions. "Ct_1..Ct_3: Ct of the qPCR replicate; Undetermined = no
#                 amplification"; "Inhibited samples dCt >= 3" (IPC shift against the blanks).
#         All_df  595 rows: 441 field samples (bottles A/B/C at a station on a sampling day) and 154
#                 controls (48 field blanks FB<n><day>, 49 filtration blanks LB<n><day>, 27
#                 extraction blanks, 15 qPCR negative and 15 positive controls). Experiment Spring
#                 = 2021 smolt survey, 4 stations S1-S4 at -50..150 m from a rotary screw trap, 12
#                 days x 3 bottles; Summer = 2020 parr survey, 11 stations around three pools (PP1-3,
#                 BH1-4, TF1-4), 9 days x 3 bottles. SampleID = station + day in roman numerals.
#                 Ct_1..Ct_3 for every sample (no NA). Summer day v carries the EventDate of day iv
#                 (2020-08-07) although it was filtered on 2020-08-14 (every other Summer day is
#                 filtered the day after sampling) and has its own precipitation and mean
#                 temperature: a keying error; its date is not shipped. TotalFish / LocalFish =
#                 estimated smolts in the river and smolts in the screw trap that day (Spring only;
#                 a separate survey). Field blanks: 2 per Spring day (all Undetermined); Summer
#                 day i six (FB1i/FB2i/FB5i with Ct NA, FB3i/FB4i/FB6i "No Ct"), three on days
#                 ii-vi and viii, none on days vii and ix; FB3iv amplified in all three replicates
#                 (as did filtration blank LB3iv). Summer LB1i-LB3i appear twice (NA and "No Ct").
#         Full_trans 614 rows, one per qPCR replicate (Ct; "0" = no amplification), 2020 full
#                 transect on SamplingDay 1-3 = 2020-07-15, 08-27, 09-08 (Summer days i, vii, ix).
#                 96 bottles are the Summer pool samples of those days, repeated from All_df (272
#                 of 288 Ct agree; see the assertion for the 16 that do not); the rest are one bottle (A) at each of 38 transect stations
#                 USR<n> (n.B = tributary or upstream stations), 0-7096 m along the river. Four
#                 transect samples have no qPCR result (Ct NA): USR40Bi and USR41Bi (one row each,
#                 every field empty: not collected), USR15Bi and USR25Bix (three rows, Ct NA).
#                 USR30i has a positive longitude (asserted: within 0.002 degree of the negated
#                 value on the station's other days; sign fixed before coarsening). No blanks in this sheet.
#         Full_rls_mean 70 rows of an October 2020 survey (FR stations): mean Ct and concentration
#                 per sample only, no replicates or blanks. Std_curve: the standard curve plate.
#                 Analyses: the authors' regressions.
# Mapping (standard E9 experimental multi-scale / eDNA, as sepulveda_2019_streamgage_fish_edna):
#   one table: one protocol (bottle grab, filtration, the same salmon qPCR assay in triplicate,
#   ruling #31) across the three surveys. period = sampling event (day), ordered in time: 1-9 =
#   Summer 2020 days i-ix (the full transect shares periods 1, 7 and 9), 10-21 = Spring 2021 days
#   i-xii (__periods: survey, day, date, precipitation, and for Spring the screw-trap TotalFish /
#   LocalFish, a separate survey). cluster_id = station (the source's code; transect stations
#   USR<n> are written FT<n>, since "USR" abbreviates the river's name, E7.4). unit = bottle
#   (<SampleID>_<BottleID>; transect "FT..."), nested in one event. occasion = qPCR replicate 1-3.
#   taxon = SALSAL. y = 1 where the replicate amplified (a Ct value, not "Undetermined" / "0"),
#   else 0 (ruling 2026-11-06: no call or Ct cutoff is stated); y_raw = the Ct as deposited.
#   surveyEvidence = deposited_matrix: every bottle carries three replicate results.
#   obs_blank_positive = 1 on every row of an event whose field blank amplified (Summer day iv),
#   0 where the event's field blanks were run and did not amplify, NA on Summer days vii and ix,
#   which have no field blank in the deposit. obs_quantity_pg_l = the replicate's standard-curve
#   quantity (pg/L) as deposited. unit_ (constant within a bottle): survey, reach (PP/BH/TF codes),
#   distance from the screw trap (Spring), from the pool (Summer) or along the transect,
#   transect position (main / tributary / upstream), water quality (temperature, day mean
#   temperature, conductivity, salinity, pH, turbidity, chlorophyll), velocity, depth, width,
#   discharge, sampling time, filtration volume and hours to filtration, IPC Ct, dCt and the
#   README's inhibition rule (dCt >= 3), coarsened coordinates.
#   Coordinates: the Inner Bay of Fundy population is listed as endangered under Canada's Species
#   at Risk Act, as the source's title says (E7(a)); positions (5-6 decimals per bottle) are given
#   as the 0.1-degree cell with coarsen_coords(); the river and pool names are not shipped (E7.4).
# Not shipped: the controls as units (their result is obs_blank_positive), the Full_trans repeats of
#   the pool samples, the four transect samples without a qPCR result, Full_rls_mean (means only:
#   no replicate-level detections, no blanks), Std_curve and Analyses (calibration and model
#   output), RecordedBy (people's initials), Site / place names, filtration and extraction dates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "morrison_2023_fundy_salmon_edna"
SCRIPT <- "data/morrison_2023_fundy_salmon_edna.R"
dir <- download_dryad("10.5061/dryad.9kd51c5n2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "edn3424-data.xlsx")
stopifnot(identical(excel_sheets(f), c("Full_rls_mean", "README", "All_df", "Full_trans", "Std_curve", "Analyses")))
num <- function(x) suppressWarnings(as.numeric(x))
xdate <- function(x) as.IDate(as.Date(num(x), origin = "1899-12-30"))
na_str <- function(d) { for (v in names(d)) set(d, which(d[[v]] %in% c("NA", "N/A")), v, NA_character_); d }   # literal "NA" / "N/A" cells
ROMAN <- c("i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii")

# ---- All_df ---------------------------------------------------------------------------------
a <- na_str(as.data.table(read_excel(f, "All_df", col_types = "text")))
stopifnot(nrow(a) == 595L, ncol(a) == 43L, identical(names(a)[35:43], c("Ct_1", "Ct_2", "Ct_3", "Quantity_1", "Quantity_2",
          "Quantity_3", "IPC_Ct", "IPC_neg_Ct", "ΔCt")))
setnames(a, c("Temperature_°C", "MeanTemp_°C", "ΔCt"), c("Temp", "MeanTemp", "dCt"))
stopifnot(identical(as.vector(table(a$ControlType)), c(27L, 48L, 49L, 15L, 15L, 441L)),
          identical(names(table(a$ControlType)), c("Extraction blank", "Field blank", "Filtration blank", "qPCR negative", "qPCR positive", "Sample")))
a[, day := sub("^[A-Z]+[0-9]*", "", SampleID)]
a[, dnum := match(day, ROMAN)]

# field blanks per event (survey x day)
fb <- a[ControlType == "Field blank"]
stopifnot(all(grepl("^FB[0-9][ivx]+$", fb$SampleID)), !anyNA(fb$dnum))
fb[, ct_res := fcase(Ct_1 == "Undetermined" & Ct_2 == "Undetermined" & Ct_3 == "Undetermined", "neg",
                     Ct_1 == "No Ct" & Ct_2 == "No Ct" & Ct_3 == "No Ct", "neg",
                     is.na(Ct_1) & is.na(Ct_2) & is.na(Ct_3), "not_run",
                     !is.na(num(Ct_1)) | !is.na(num(Ct_2)) | !is.na(num(Ct_3)), "pos")]
stopifnot(!anyNA(fb$ct_res))
fbe <- fb[, .(n_fb = .N, n_run = sum(ct_res != "not_run"), n_pos = sum(ct_res == "pos")), keyby = .(Experiment, dnum)]
stopifnot(identical(fbe[Experiment == "Spring", n_fb], rep(2L, 12L)), fbe[Experiment == "Spring", all(n_pos == 0)],
          identical(fbe[Experiment == "Summer", dnum], c(1:6, 8L)),
          identical(fbe[Experiment == "Summer", n_fb], c(6L, 3L, 3L, 3L, 3L, 3L, 3L)),
          identical(fbe[Experiment == "Summer", n_run], c(3L, 3L, 3L, 3L, 3L, 3L, 3L)),
          identical(fbe[Experiment == "Summer", n_pos], c(0L, 0L, 0L, 1L, 0L, 0L, 0L)),
          identical(fb[ct_res == "pos", SampleID], "FB3iv"),
          a[ControlType == "Filtration blank" & !is.na(num(Ct_1)), SampleID] == "LB3iv")
# other controls: negatives never amplify, positives always do
stopifnot(a[ControlType %in% c("Extraction blank", "qPCR negative"), all(Ct_1 %in% c("Undetermined", "No Ct") & Ct_2 == Ct_1 & Ct_3 == Ct_1)],
          a[ControlType == "qPCR positive", all(!is.na(num(Ct_1)) & !is.na(num(Ct_2)) & !is.na(num(Ct_3)))])

s <- a[ControlType == "Sample"]
stopifnot(nrow(s) == 441L, !anyDuplicated(s[, .(SampleID, BottleID)]), all(s$BottleID %in% c("A", "B", "C")),
          identical(s[, .N, keyby = Experiment]$N, c(144L, 297L)),
          s[, .N, by = .(Experiment, Station, dnum)][, all(N == 3L)],
          identical(s[, uniqueN(dnum), keyby = Experiment]$V1, c(12L, 9L)),
          identical(s[, uniqueN(Station), keyby = Experiment]$V1, c(4L, 11L)),
          identical(paste0(s$Station, s$day), s$SampleID),
          s[Experiment == "Spring", all(Year == "2021")], s[Experiment == "Summer", all(Year == "2020")])
ct <- unlist(s[, .(Ct_1, Ct_2, Ct_3)])
stopifnot(!anyNA(ct), all(ct == "Undetermined" | !is.na(num(ct))), sum(ct == "Undetermined") == 183L,
          all(num(ct[ct != "Undetermined"]) %between% c(29, 48)))
s[, date := xdate(EventDate)]
s[, fdate := xdate(FiltrationDate)]
# Summer day v: EventDate keyed as day iv's
stopifnot(!anyNA(s$date), s[, uniqueN(date), by = .(Experiment, dnum)][, all(V1 == 1)],
          s[Experiment == "Spring", all(fdate == date)],
          s[Experiment == "Summer" & dnum != 5, all(fdate == date + 1L)],
          s[Experiment == "Summer" & dnum == 5, all(date == as.IDate("2020-08-07") & fdate == as.IDate("2020-08-14"))],
          s[Experiment == "Summer" & dnum == 4, all(date == as.IDate("2020-08-07"))],
          s[Experiment == "Summer" & dnum %in% 4:5, uniqueN(Precipitation_mm), by = dnum][, all(V1 == 1)],
          uniqueN(s[Experiment == "Summer" & dnum %in% 4:5, .(dnum, Precipitation_mm)]$Precipitation_mm) == 2L)
s[Experiment == "Summer" & dnum == 5, date := NA]

# ---- Full_trans -----------------------------------------------------------------------------
ft <- na_str(as.data.table(read_excel(f, "Full_trans", col_types = "text")))
stopifnot(nrow(ft) == 614L, ncol(ft) == 33L, all(ft$Experiment == "FullTrans"), all(ft$Year == "2020"))
setnames(ft, c("Temperature_°C", "MeanTemp_°C", "ΔCt"), c("Temp", "MeanTemp", "dCt"))
ft[, day := sub("^[A-Z]+[0-9]+B?", "", SampleID)]
ft[, dnum := match(day, ROMAN)]
ft[, r := seq_len(.N), by = .(SampleID, BottleID)]
stopifnot(identical(unique(ft[, .(SamplingDay, JulianDay, dnum)])[order(SamplingDay)],
                    data.table(SamplingDay = c("1", "2", "3"), JulianDay = c("197", "240", "252"), dnum = c(1L, 7L, 9L))))
# the pool samples repeat All_df, replicate for replicate ("0" there = "Undetermined" here)
pool <- ft[!grepl("^USR", SampleID)]
stopifnot(nrow(pool) == 96L * 3L, pool[, .N, by = .(SampleID, BottleID)][, all(N == 3L)])
cmp <- merge(pool[, .(SampleID, BottleID, r, Ct)],
             melt(s[, .(SampleID, BottleID, Ct_1, Ct_2, Ct_3)], id.vars = c("SampleID", "BottleID"), value.name = "Ct_a")[
               , r := as.integer(sub("Ct_", "", variable))], by = c("SampleID", "BottleID", "r"))
cmp[, same := (Ct == "0" & Ct_a == "Undetermined") | (!is.na(num(Ct)) & !is.na(num(Ct_a)) & abs(num(Ct) - num(Ct_a)) < 1e-6)]
# 272 of 288 replicates agree; the rest: one PP1i B replicate (35.95 here, 35.86 in All_df) and the
# day-ix bottles TF1ix A-C and TF2ix B-C, whose results sit one bottle earlier in Full_trans than in
# All_df (Full_trans TF1ix A = All_df TF1ix B, B = C, ...). All_df, the survey's own sheet, is shipped.
stopifnot(nrow(cmp) == 288L, sum(!cmp$same) == 16L,
          identical(unique(cmp[same == FALSE, paste(SampleID, BottleID)]), c("PP1i B", "TF1ix A", "TF1ix B", "TF1ix C", "TF2ix B", "TF2ix C")),
          all(abs(num(cmp[SampleID == "TF1ix" & BottleID == "A", Ct]) - num(cmp[SampleID == "TF1ix" & BottleID == "B", Ct_a])) < 1e-6),
          all(abs(num(cmp[SampleID == "TF1ix" & BottleID == "B", Ct]) - num(cmp[SampleID == "TF1ix" & BottleID == "C", Ct_a])) < 1e-6))
# the transect samples
u <- ft[grepl("^USR", SampleID)]
stopifnot(all(u$BottleID == "A"), nrow(u) == 326L)
nodata <- u[is.na(Ct), .(n = .N), by = SampleID]
stopifnot(identical(sort(nodata$SampleID), c("USR15Bi", "USR25Bix", "USR40Bi", "USR41Bi")),
          identical(u[SampleID %in% nodata$SampleID, .N, keyby = SampleID]$N, c(3L, 3L, 1L, 1L)),
          u[SampleID %in% c("USR40Bi", "USR41Bi"), all(is.na(Temp) & is.na(FiltrationVol_mL) & is.na(IPC_Ct))])
u <- u[!SampleID %in% nodata$SampleID]
NZERO <- 93L   # transect replicates with no amplification
stopifnot(u[, .N, by = SampleID][, all(N == 3L)], uniqueN(u$SampleID) == 106L,
          all(u$Ct == "0" | !is.na(num(u$Ct))), sum(u$Ct == "0") == NZERO,
          identical(u[, uniqueN(SampleID), keyby = dnum]$V1, c(33L, 37L, 36L)))
u[, Station := sub("[ivx]+$", "", SampleID)]
stopifnot(uniqueN(u$Station) == 38L)
# USR30i: longitude keyed without its sign
u[, `:=`(la = num(Latitude), lo = num(Longitude))]
stopifnot(u[lo > 0, all(SampleID == "USR30i")], u[lo > 0, .N] == 3L,
          all(abs(unique(u[SampleID == "USR30i", lo]) + u[Station == "USR30" & SampleID != "USR30i", lo]) < 0.002))
u[lo > 0, lo := -lo]
u[, date := fcase(dnum == 1L, as.IDate("2020-07-15"), dnum == 7L, as.IDate("2020-08-27"), dnum == 9L, as.IDate("2020-09-08"))]
stopifnot(identical(sort(unique(s[Experiment == "Summer" & dnum %in% c(1, 7, 9), date])), sort(unique(u$date))))
# per-bottle values constant across the three replicate rows (IPC differs in the 15th digit once)
# dCt: USR36ix differs in the 15th digit; USR40ix's third row has another dCt, but its IPC_Ct and
# IPC_neg_Ct are those of the other two rows, whose dCt = IPC_Ct - IPC_neg_Ct: the first row is shipped
stopifnot(u[, lapply(.SD, uniqueN), by = SampleID, .SDcols = c("Latitude", "Longitude", "Distance_m", "Temp", "pH", "FiltrationVol_mL")][
            , all(unlist(.SD) == 1L), .SDcols = -1],
          u[, .(a = diff(range(num(IPC_Ct))), b = diff(range(num(IPC_neg_Ct)))), by = SampleID][, all(is.na(a) | a < 1e-9) & all(is.na(b) | b < 1e-9) & sum(is.na(a)) == 1L],
          identical(u[, max(num(dCt)) - min(num(dCt)), by = SampleID][V1 > 1e-9, SampleID], "USR40ix"),
          u[SampleID == "USR40ix" & r <= 2, all(abs(num(dCt) - (num(IPC_Ct) - num(IPC_neg_Ct))) < 1e-6)])
# position by station: USR25Bi has Distance_m NA where the station's other visits say "tributary"
u[, pos := fcase(Distance_m == "tributary", "tributary", Distance_m == "upstream", "upstream", default = NA_character_)]
u[, pos := if (all(is.na(pos))) "main" else unique(na.omit(pos)), by = Station]
stopifnot(u[pos == "main", sum(is.na(num(Distance_m)))] == 0L, u[pos != "main", uniqueN(Station)] == 6L,
          identical(u[is.na(Distance_m), unique(SampleID)], "USR25Bi"), u[Station == "USR25B", all(pos == "tributary")])

# ---- long table ------------------------------------------------------------------------------
s[, `:=`(la = num(Latitude), lo = num(Longitude))]
stopifnot(!anyNA(s$la), !anyNA(s$lo), all(c(s$la, u$la) %between% c(45.60, 45.70)), all(c(s$lo, u$lo) %between% c(-65.01, -64.95)))
tod <- function(x) { m <- round(num(x) * 1440); ifelse(is.na(m), NA_character_, sprintf("%02d:%02d", m %/% 60, m %% 60)) }
bottle <- function(d, survey, reps) {
  cc <- coarsen_coords(d$la, d$lo)
  d[, .(unit = paste0(sub("^USR", "FT", SampleID), "_", BottleID), cluster_id = sub("^USR", "FT", Station),
        survey, dnum, date = format(date),
        unit_survey = survey, unit_reach = if ("Site" %in% names(d)) Site else NA_character_,
        unit_transect_position = if (survey == "full_transect_2020") pos else NA_character_,
        unit_distance_m = num(Distance_m),
        unit_temp_c = num(Temp), unit_daymean_temp_c = num(MeanTemp), unit_conductivity_us_cm = num(`Conductivity_uS/cm`),
        unit_salinity_psu = num(Salinity_psu), unit_ph = num(pH), unit_turbidity_fnu = num(Turbidity_FNU),
        unit_chlorophyll_ug_l = num(`Chlorophyll_ug/L`), unit_velocity_m_s = num(`Velocity_m/s`), unit_depth_m = num(Depth_m),
        unit_width_m = num(Width_m), unit_discharge_m3_s = num(`Discharge_m^3/s`),
        unit_sampling_time = if ("EventTime" %in% names(d)) tod(EventTime) else NA_character_,
        unit_filtration_vol_ml = num(FiltrationVol_mL), unit_hrs_to_filtration = num(HrsAfter),
        unit_ipc_ct = num(IPC_Ct), unit_ipc_dct = num(dCt), unit_inhibited = as.integer(num(dCt) >= 3),
        unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]
}
lab <- rbind(bottle(s[Experiment == "Summer"], "parr_summer_2020"), bottle(s[Experiment == "Spring"], "smolt_spring_2021"))
ub <- u[r == 1]
lab <- rbind(lab, bottle(ub, "full_transect_2020"))
lab[, survey := NULL]
reps <- rbind(
  melt(s[, .(unit = paste0(SampleID, "_", BottleID), Ct_1, Ct_2, Ct_3)], id.vars = "unit", value.name = "y_raw")[
    , .(unit, occasion = as.integer(sub("Ct_", "", variable)), y_raw)],
  u[, .(unit = paste0(sub("^USR", "FT", SampleID), "_", BottleID), occasion = r, y_raw = Ct)])
qty <- rbind(s[, .(unit = rep(paste0(SampleID, "_", BottleID), 3), occasion = rep(1:3, each = .N), q = c(Quantity_1, Quantity_2, Quantity_3))],
             u[, .(unit = paste0(sub("^USR", "FT", SampleID), "_", BottleID), occasion = r, q = Quantity)])
reps <- merge(reps, qty, by = c("unit", "occasion"))
stopifnot(nrow(reps) == (441L + 106L) * 3L, !anyDuplicated(reps[, .(unit, occasion)]))
long <- merge(reps, lab, by = "unit")
long[, y := as.integer(!is.na(num(y_raw)) & num(y_raw) > 0)]
long[, obs_quantity_pg_l := num(q)]
stopifnot(long[y == 0, all(y_raw %in% c("Undetermined", "0"))], long[y == 1, all(num(y_raw) > 29)])
# periods: Summer 2020 days i-ix = 1-9 (full transect on 1, 7, 9), Spring 2021 days i-xii = 10-21
long[, period := ifelse(unit_survey == "smolt_spring_2021", 9L + dnum, dnum)]
# field-blank flag per event
fbe[, period := ifelse(Experiment == "Spring", 9L + dnum, dnum)]
long <- merge(long, fbe[, .(period, obs_blank_positive = as.integer(n_pos > 0))], by = "period", all.x = TRUE)
stopifnot(long[is.na(obs_blank_positive), all(period %in% c(7L, 9L))], long[obs_blank_positive == 1, all(period == 4L)])
long[, c("q", "dnum") := NULL]
long <- long[, .(unit, taxon = "SALSAL", y, y_raw, period, occasion, date, cluster_id,
                 obs_blank_positive, obs_quantity_pg_l,
                 unit_survey, unit_reach, unit_transect_position, unit_distance_m, unit_temp_c, unit_daymean_temp_c,
                 unit_conductivity_us_cm, unit_salinity_psu, unit_ph, unit_turbidity_fnu, unit_chlorophyll_ug_l,
                 unit_velocity_m_s, unit_depth_m, unit_width_m, unit_discharge_m3_s, unit_sampling_time,
                 unit_filtration_vol_ml, unit_hrs_to_filtration, unit_ipc_ct, unit_ipc_dct, unit_inhibited,
                 unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)]
long <- order_eco(long)
stopifnot(nrow(long) == 1641L, uniqueN(long$unit) == 547L, uniqueN(long$cluster_id) == 4L + 11L + 38L,
          uniqueN(long$period) == 21L, sum(long$y) == 1140L + sum(u$Ct != "0"),
          long[, uniqueN(period), by = unit][, all(V1 == 1L)],
          long[is.na(date), all(period == 5L)], long[, uniqueN(unit_inhibited, na.rm = TRUE)] == 2L,
          identical(sort(long[is.na(unit_inhibited), unique(unit)]), c("BH1ix_A", "FT29Bi_A")))
cat(sprintf("  %d rows, %d bottles at %d stations on %d events; %d of %d replicates amplified; %d of %d bottles positive\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), uniqueN(long$period), sum(long$y), nrow(long),
            long[, any(y == 1), by = unit][, sum(V1)], uniqueN(long$unit)))

# ---- side tables ------------------------------------------------------------------------------
pd <- unique(s[, .(Experiment, dnum, date, Precipitation_mm, TotalFish, LocalFish)])
stopifnot(nrow(pd) == 21L)
pd[, period := ifelse(Experiment == "Spring", 9L + dnum, dnum)]
setorder(pd, period)
periods <- pd[, .(period, period_label = sprintf("%s day %s", ifelse(Experiment == "Spring", "Smolt survey 2021", "Parr survey 2020"), ROMAN[dnum]),
                  period_year = ifelse(Experiment == "Spring", 2021L, 2020L), period_date = format(date),
                  period_full_transect = as.integer(Experiment == "Summer" & dnum %in% c(1L, 7L, 9L)),
                  period_precip_mm = num(Precipitation_mm),
                  period_smolts_in_river = num(TotalFish), period_smolts_in_trap = num(LocalFish))]
stopifnot(periods[period <= 9, all(is.na(period_smolts_in_river))], periods[period > 9, !anyNA(period_smolts_in_river)],
          all(diff(as.IDate(periods$period_date[!is.na(periods$period_date)])) > 0))
taxa <- make_taxa("SALSAL", "Salmo salar", vernacularName = "Atlantic salmon (Inner Bay of Fundy population)")
iucn <- iucn_category(taxa$taxonID, taxa$scientificName)
message("  IUCN category of Salmo salar: ", iucn)

coarse_note <- sprintf("Bottle positions (5-6 decimals in the deposit) given as the 0.1-degree cell centre (coarsen_coords()), uncertainty the cell half-diagonal: the Inner Bay of Fundy Atlantic salmon population is listed as endangered under Canada's Species at Risk Act, as the source's title says (E7(a); global IUCN category via GBIF: %s). One transect position keyed with a positive longitude (USR30, 2020-07-15) is given the sign of the station's other visits before coarsening. River, pool and station names are not shipped (E7.4): pool reaches keep the source's codes (PP, BH, TF) and transect stations are FT<n> for the source's USR<n>.", iucn)

dataset <- list(
  title = "Endangered Inner Bay of Fundy Atlantic salmon eDNA: three qPCR replicates of 547 water samples at 53 river stations on 21 sampling days, New Brunswick, 2020-2021",
  creator = "Morrison, Melissa K.; Lacoursière-Roussel, Anaïs; Wood, Zachary T.; Trudel, Marc; Gagné, Nellie; LeBlanc, Francis; Samways, Kurt; Kinnison, Michael T.; Pavey, Scott A.",
  pubDate = "2023", doi = "10.5061/dryad.9kd51c5n2",
  sourceURL = "https://doi.org/10.5061/dryad.9kd51c5n2", paperDOI = "10.1002/edn3.424",
  citation = "Morrison, M. K., Lacoursière-Roussel, A., Wood, Z. T., Trudel, M., Gagné, N., LeBlanc, F., Samways, K., Kinnison, M. T., & Pavey, S. A. (2023). Data from: Including environmental covariates clarifies the relationship between endangered Atlantic salmon (Salmo salar) abundance and environmental DNA [Dataset]. Dryad. https://doi.org/10.5061/dryad.9kd51c5n2",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Water samples for Atlantic salmon eDNA in one Inner Bay of Fundy river, New Brunswick, Canada, from three surveys with one protocol: a summer 2020 parr survey (three bottles at each of 11 stations around three pools, nine days), a 2020 full-transect survey (one bottle at 38 stations along 7 km of river, tributaries and upstream, on three of those days), and a spring 2021 smolt survey (three bottles at each of four stations near a rotary screw trap, twelve days, with the trap's daily smolt counts). Each bottle was filtered and assayed in three salmon qPCR replicates. cluster_id = station, period = sampling day, unit = bottle, occasion = qPCR replicate; y = 1 where the replicate amplified, with the Ct in y_raw. Water quality, flow, inhibition, field-blank result and coarsened coordinates ship as covariates.",
  samplingProtocol = "Environmental DNA: water grab samples (bottles A, B, C per station; one bottle per transect station), filtered (volume in unit_filtration_vol_ml, hours from collection in unit_hrs_to_filtration), DNA extracted after LeBlanc et al. (2020), and assayed in three qPCR replicates with an Atlantic salmon assay and an internal positive control; field blanks (2-6 per day), filtration, extraction and qPCR controls. No detection call is stated: a replicate with a Ct value is a detection (y = 1), 'Undetermined' (All_df) or '0' (Full_trans) is not.",
  samplingProtocolCode = "eDNA", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = three qPCR replicates of one bottle's extract; a bottle belongs to one sampling day; days (3-14 days apart) are open periods; stations are revisited across days (cluster_id)",
  occasionKind = "spatial", taxonInclusion = "single", surveyEvidence = "deposited_matrix",
  temporalCoverage = "2020-07/2021-06",
  geographicCoverage = "One river of the Inner Bay of Fundy, New Brunswick, Canada (about 45.6-45.7 N, 65.0 W); coordinates coarsened to 0.1 degree",
  crs = "EPSG:4326 (datum not stated)",
  coordinatesCoarsened = list(value = TRUE, method = coarse_note),
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = station, period = sampling day, unit = bottle (nested in one day), occasion = qPCR replicate. The three surveys share the protocol and the assay (one table, ruling #31); unit_survey says which survey a bottle belongs to and period_full_transect which days carry the transect.",
  notShipped = list(
    controls = "48 field blanks, 49 filtration blanks, 27 extraction blanks and 30 qPCR controls are not units; the field-blank result is obs_blank_positive (field blank FB3iv, Summer day iv, amplified in all three replicates, as did filtration blank LB3iv); every extraction blank and qPCR negative is Undetermined / No Ct and every qPCR positive amplified",
    full_trans_pool_repeats = "the 96 pool bottles of Summer days i, vii and ix that Full_trans repeats from All_df (shipped once, from All_df); 272 of their 288 replicates agree, the rest are one PP1i B replicate (35.95 in Full_trans, 35.86 in All_df) and day-ix bottles TF1ix A-C and TF2ix B-C, whose results Full_trans lists one bottle earlier than All_df (Full_trans TF1ix A = All_df TF1ix B)",
    transect_samples_without_qpcr = "USR40Bi and USR41Bi (2020-07-15; one row each, every field empty) and USR15Bi (2020-07-15) and USR25Bix (2020-09-08) (three rows, Ct NA): no qPCR result, so no survey rows",
    Full_rls_mean = "an October 2020 survey (70 rows, FR stations) deposited as per-sample mean Ct and concentration only: no replicate-level results and no blanks",
    Std_curve = "the standard-curve plate (calibration of the quantities in obs_quantity_pg_l)",
    Analyses = "the authors' regressions of concentration on environmental covariates (model output)",
    RecordedBy = "people's initials",
    place_names = "river, pool and station names (E7.4; coordinates coarsened for the endangered population); pool reaches keep the source's codes",
    exact_coordinates = "bottle positions at 5-6 decimals (coarsened to 0.1 degree)",
    filtration_extraction_dates = "lab dates (filtration time and duration, extraction date); hours to filtration ships as unit_hrs_to_filtration",
    summer_day_v_date = "Summer day v carries the EventDate of day iv (2020-08-07) but was filtered on 2020-08-14 and has its own precipitation and day mean temperature; the date is a keying error, so date and period_date are empty for period 5"),
  notes = "obs_blank_positive is NA on Summer days vii and ix (periods 7 and 9), which have no field blank in the deposit, 1 on Summer day iv (period 4), whose field blank FB3iv amplified, and 0 on the other days, whose field blanks were run and did not amplify (on Summer day i three of six field blanks have a result). unit_distance_m is the distance from the rotary screw trap (smolt survey, -50 to 150 m, sign as deposited), from the station's pool (parr survey, 0-500 m), or along the river (full transect, 0-7096 m; NA at the six tributary and upstream stations, unit_transect_position). unit_inhibited follows the README's rule (IPC dCt >= 3; NA for the 2 bottles without a dCt, BH1ix A and FT29Bi A). y_raw keeps the sheet's own no-amplification code: 'Undetermined' for parr and smolt bottles, '0' for full-transect bottles. obs_quantity_pg_l is the deposited standard-curve quantity per replicate. period_smolts_in_river and period_smolts_in_trap are the screw trap's estimated smolt run and daily catch (smolt survey only; a separate survey, not derived from the eDNA).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Endangered Inner Bay of Fundy Atlantic salmon eDNA in New Brunswick: three qPCR replicates (Ct in y_raw) of 547 water samples at 53 river stations on 21 sampling days of a 2020 parr survey, a 2020 full-river transect and a 2021 smolt survey (multi-scale, cluster_id = station); coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.9kd51c5n2",
  reference = "Morrison, M. K., Lacoursière-Roussel, A., Wood, Z. T., Trudel, M., Gagné, N., LeBlanc, F., Samways, K., Kinnison, M. T., & Pavey, S. A. (2023). Including environmental covariates clarifies the relationship between endangered Atlantic salmon (Salmo salar) abundance and environmental DNA. Environmental DNA.",
  doi_paper = "10.1002/edn3.424", doi_data = "10.5061/dryad.9kd51c5n2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental (E9): cluster_id = station, period = sampling day, unit = bottle, occasion = qPCR replicate; y = 1 where a replicate amplified (no call stated), field-blank flag per day; October 2020 means-only survey not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale occupancy (station > day > bottle > qPCR replicate, eDNA)",
  sampling_protocol = "eDNA", design = "Multi-season (21 sampling days over two years; 1 or 3 bottles x 3 qPCR replicates)",
  realm = "Freshwater", country = "CAN", coordinates = "Coarsened (0.1 deg)",
  notes = "Experimental (E9): multi-scale via cluster_id = station. SARA-endangered population: coordinates coarsened, place names withheld. Field-blank flag, inhibition and water quality as covariates.")
