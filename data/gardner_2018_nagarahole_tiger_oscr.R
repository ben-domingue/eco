#!/usr/bin/env Rscript
# Table:  gardner_2018_nagarahole_tiger_oscr
# Source: Dryad doi:10.5061/dryad.bcc2fqzd2 (CC0 1.0), version 145169 (published 2021-10-15)
#   Gardner, B., Sollmann, R., Kumar, N. S., Jathanna, D. & Karanth, K. U. (2021). Ten year
#   camera trap dataset of tigers in India. Dryad. Data collected by the Wildlife
#   Conservation Society under K. U. Karanth (readme).
# Paper:  Gardner, B., Sollmann, R., Kumar, N. S., Jathanna, D. & Karanth, K. U. (2018). State
#         space and movement specification in open population spatial capture-recapture
#         models. Ecology and Evolution 8(20), 10336-10344. doi:10.1002/ece3.4509 (open
#         access, PMC6206188). Earlier non-spatial analyses: Karanth 1995; Karanth & Nichols
#         1998; Karanth, Nichols, Kumar & Hines 2006 (Ecology 87:2925-2937; its Table 1
#         gives the days per primary period, copied into the readme).
# Data:   four files. EERecords.csv (343 rows): one row per capture of an individual tiger
#         (Ind 1..75) at a camera station (Trap_ID) on a sampling occasion (a trap day
#         within the primary period) in a primary period 1..10. EECam_act.csv (195 stations
#         x 10 periods): the NUMBER of occasions each station was active in each primary
#         period, 0 = not operated (station 188 absent). EEtraplocs.csv: station x, y in
#         metres, centred by the authors on an undisclosed origin because some stations are
#         still in use. ReadMeTigers.txt: the above plus the days per primary period
#         (162, 127, 75, 197, 78, 118, 33, 39, 47, 54).
#         Quirks asserted below: occasion numbers run up to the period's length (1..166 in
#         period 1), while a station's active count is typically much smaller (e.g. station
#         4 was active 31 occasions in period 1 and photographed tiger 1 on occasions 44 and
#         52), so WHICH occasions a station was active is not deposited and cannot be
#         reconstructed (283 of 343 records have occasion > the station's active count).
#         Period 7 records carry occasions 96-115 although the readme gives it 33 days.
#         An individual is recorded at most once per station per occasion (asserted), up to
#         4 times per station per period.
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture, open population):
#   The paper's observation model is exactly the trap x primary-period count:
#   y_ijt ~ Binomial(p(x_j, s_it), K_jt), K_jt = days station j was active in period t,
#   "model counts y_ijt = sum_k y_ijkt" (Gardner et al. 2018, section 2.1). The table is
#   built at that level because the per-occasion survey set does not exist in the deposit:
#   unit = individual tiger (75), trap = camera station, period = primary period 1..10
#   (1991-2000, 10 periods over 9 years, unevenly spaced; calendar years per period are in
#   Karanth et al. 2006 Table 1 and NOT in the deposit, so __periods carries the period's
#   length in days and no year), no occasion column (one row per unit x trap x period),
#   y = number of trap-days on which the individual was photographed at that station in
#   that period (responseType count), obs_trap_days_active = K_jt (effortColumn), the
#   binomial denominator. taxon = PANTIG. unitKind = individual.
#   Survey set = effort_table: a station-period is surveyed iff EECam_act > 0 (458
#   station-periods); every individual carries the full rectangle of surveyed
#   station-periods, including periods before its first and after its last capture (the
#   CJS / SCR convention, BATCH_LOG batch 5), 75 x 458 = 34,350 rows.
#   __traps: trap, x, y in the authors' centred local metres; crs = "local: centred by
#   the authors, metres" (no geographic coordinates exist in the deposit; the tiger is
#   IUCN EN and the centring is the source's own masking, so nothing further to coarsen).
#   NOT shipped: the per-record Occasion column (the day within the period), because the
#   matching per-occasion effort is not deposited; it survives only as the count y. Station
#   188 (in neither the activity nor the location file) is absent from the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "gardner_2018_nagarahole_tiger_oscr"
SCRIPT <- "data/gardner_2018_nagarahole_tiger_oscr.R"
dir <- download_dryad("10.5061/dryad.bcc2fqzd2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("EECam_act.csv", "EERecords.csv", "EEtraplocs.csv", "ReadMeTigers.txt")))

rec <- fread(file.path(dir, "EERecords.csv"))
act <- fread(file.path(dir, "EECam_act.csv"))
loc <- fread(file.path(dir, "EEtraplocs.csv"))
setnames(rec, c("ind", "trap", "occasion", "period"))
setnames(loc, c("trap", "x", "y"))
setnames(act, "Trap_ID", "trap")

# --- source facts -------------------------------------------------------------------------
stopifnot(nrow(rec) == 343, uniqueN(rec$ind) == 75, uniqueN(rec$trap) == 111,          # readme: 75 tigers, 111 stations
          all(rec$period %in% 1:10), all(rec$occasion >= 1), !anyNA(rec))
stopifnot(nrow(act) == 195, nrow(loc) == 195, setequal(act$trap, loc$trap),            # readme: 195 stations, 188 absent
          !188 %in% act$trap, identical(names(act)[-1], as.character(1:10)))
stopifnot(all(rec$trap %in% act$trap))
stopifnot(!anyDuplicated(rec[, .(ind, trap, period, occasion)]))                        # <= 1 capture per station-day
stopifnot(max(rec[, .N, by = .(ind, trap, period)]$N) == 4)
stopifnot(abs(mean(loc$x)) < 1 && abs(mean(loc$y)) < 1)                                 # centred on the station mean (metres)
stopifnot(diff(range(loc$x)) < 30000, diff(range(loc$y)) < 30000)

# effort: station x period, active occasions
eff <- melt(act, id.vars = "trap", variable.name = "period", value.name = "k", variable.factor = FALSE)
eff[, period := as.integer(period)]
stopifnot(all(eff$k >= 0), all(eff$k == round(eff$k)))
eff <- eff[k > 0]
stopifnot(nrow(eff) == 458, identical(eff[, .N, by = period][order(period)]$N, c(17L, 7L, 7L, 45L, 59L, 86L, 59L, 60L, 58L, 60L)))
# every capture is at a station active in that period; which occasions were active is NOT recoverable
rk <- merge(rec, eff, by = c("trap", "period"))
stopifnot(nrow(rk) == nrow(rec), sum(rk$occasion > rk$k) == 283)
cat(sprintf("  %d captures, %d tigers, %d stations; %d surveyed station-periods; %d captures on an occasion index above the station's active count (per-occasion effort not deposited)\n",
            nrow(rec), uniqueN(rec$ind), uniqueN(rec$trap), nrow(eff), sum(rk$occasion > rk$k)))

# --- the table: individual x surveyed station-period, y = trap-days with a capture -------
counts <- rec[, .(y = .N), by = .(ind, trap, period)]
long <- CJ(ind = sort(unique(rec$ind)), i = seq_len(nrow(eff)))
long <- cbind(long[, .(ind)], eff[long$i])
long <- merge(long, counts, by = c("ind", "trap", "period"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == 75 * 458, sum(long$y) == nrow(rec), all(long$y <= long$k))
long <- long[, .(unit = sprintf("T%02d", ind), taxon = "PANTIG", y = as.integer(y), trap = sprintf("S%03d", trap),
                 period, obs_trap_days_active = as.integer(k))]
long <- order_eco(long)

traps <- loc[, .(trap = sprintf("S%03d", trap), x, y)][order(trap)]
taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger", taxon_iucnCategory = "EN")
periods <- data.table(period = 1:10, n_days = c(162L, 127L, 75L, 197L, 78L, 118L, 33L, 39L, 47L, 54L),
                      n_stations_active = eff[, .N, by = period][order(period)]$N,
                      note = "primary periods 1-10 span 1991-2000 (10 periods over 9 years, unevenly spaced; Gardner et al. 2018); calendar dates per period are in Karanth et al. 2006 Table 1, not in the deposit; n_days from the readme")

dataset <- list(
  title = "Open-population spatial capture-recapture of tigers at Nagarahole Reserve, India: 75 individuals x 195 camera stations x 10 primary periods, 1991-2000",
  creator = "Gardner, Beth; Sollmann, Rahel; Kumar, N. Samba; Jathanna, Devcharan; Karanth, K. Ullas",
  pubDate = "2021", doi = "10.5061/dryad.bcc2fqzd2", sourceURL = "https://doi.org/10.5061/dryad.bcc2fqzd2",
  citation = "Gardner, B., Sollmann, R., Kumar, N. S., Jathanna, D., & Karanth, K. U. (2021). Ten year camera trap dataset of tigers in India [Data set]. Dryad. https://doi.org/10.5061/dryad.bcc2fqzd2",
  paperDOI = "10.1002/ece3.4509",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap captures of individually identified tigers (Panthera tigris) in the central part of Nagarahole Reserve, Karnataka, India, from the Wildlife Conservation Society study begun in 1991: ten primary sampling periods between 1991 and 2000 at up to 195 camera stations. The deposit gives each capture with its station, trap day and primary period, the number of trap days each station was active in each primary period, and station coordinates centred on an undisclosed origin. The table follows the authors' observation model: one row per tiger x station x primary period in which the station operated, y = number of trap days with a capture, obs_trap_days_active = the number of active trap days (the binomial denominator). Tigers carry rows for all ten periods, including before first and after last capture.",
  samplingProtocol = "Paired passive camera traps at stations along roads and trails in the central part of Nagarahole; individuals identified from stripe patterns; one detection per individual per station per trap day at most (Karanth 1995; Karanth & Nichols 1998; Karanth et al. 2006). Station activity recorded as trap days per primary period.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  surveyEvidenceNote = "EECam_act.csv gives trap days active per station x primary period; a station-period is surveyed iff that count is > 0 (458 of 1,950). Which trap days were active is not deposited (capture occasion indices exceed the station's active count in 283 of 343 records), so the table is at the station-period level with the active-day count as effort, which is the paper's own y_ijt ~ Binomial(p, K_jt).",
  effortColumn = "obs_trap_days_active",
  responseType = "count", unitKind = "individual",
  closure = "period (population closed within a primary period of 33-197 days; open between the ten periods, 1991-2000)",
  geographicCoverage = "Central Nagarahole Reserve (Nagarahole / Rajiv Gandhi National Park), Karnataka, southwestern India; station coordinates in __traps are centred local metres, no geographic position deposited",
  temporalCoverage = "1991/2000",
  crs = "local: centred by the authors on an undisclosed origin, metres (not a geographic CRS)",
  coordinatesCoarsened = list(value = TRUE, method = "by the source: station coordinates are centred on an undisclosed origin (metres) because stations are still in use; the tiger is IUCN EN; no geographic coordinates exist in the deposit, nothing further applied"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Open population across period. No occasion column: y is the count of capture days per station-period with effort in obs_trap_days_active (the design_landscape 'trap arrays summed per session' shape), because per-occasion effort is not deposited.",
  notes = "Period 7 captures carry occasion indices 96-115 although the readme gives the period 33 days; the indices are not shipped, only the counts. Station 188 is absent from the deposit. Tiger ids are the deposit's integers prefixed T, stations prefixed S.",
  notShipped = list(Occasion = "the trap day index of each capture: per-occasion station activity is not deposited, so the day cannot be given a survey set; it survives as the count y",
                    station_188 = "absent from the activity and location files (readme)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)

stage_dict_row(TABLE,
  description = "Open-population spatial capture-recapture of tigers at Nagarahole Reserve, India (WCS, 1991-2000): 75 photo-identified individuals x 195 camera stations x 10 primary periods, y = trap days with a capture per station-period, effort = active trap days; station coordinates centred by the authors (local metres).",
  url = "https://doi.org/10.5061/dryad.bcc2fqzd2",
  reference = "Gardner, B., Sollmann, R., Kumar, N. S., Jathanna, D., & Karanth, K. U. (2018). State space and movement specification in open population spatial capture-recapture models. Ecology and Evolution, 8(20), 10336-10344.",
  doi_paper = "10.1002/ece3.4509", doi_data = "10.5061/dryad.bcc2fqzd2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First open-population SCR table (E9 experimental). Station-period level (count + effort), no occasion: per-day effort not deposited. Coordinates centred by the source.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Open-population spatial capture-recapture (binomial counts with trap-day effort)",
  sampling_protocol = "camera_trap", design = "Multi-session (10 primary periods 1991-2000, 195 camera stations, effort per station-period)", realm = "Terrestrial",
  country = "IND", coordinates = "As published (station coordinates centred by the authors on an undisclosed origin, local metres, in __traps)",
  notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle incl. periods without capture. y = capture days per station-period, obs_trap_days_active = effort.")
