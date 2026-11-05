#!/usr/bin/env Rscript
# Table:  moinet_2024_nz_mouse_scr
# Source: Dryad doi:10.5061/dryad.x69p8czsq, version 297564 (version 3, published 2024-06-04),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Moinet, M., Abrahão, C., Gasparotto, V., Wilkinson, D., Vallee, E., Benschop, J. &
#         Russell, J. "Data from: Density matters: How population dynamics of house mice (Mus
#         musculus) inform the epidemiology of Leptospira".
# Paper:  Moinet, M., Abrahão, C. R., Gasparotto, V. P. O., Wilkinson, D. A., Vallée, E.,
#         Benschop, J. & Russell, J. C. (2024). Density matters: How population dynamics of house
#         mice (Mus musculus) inform the epidemiology of Leptospira. Journal of Applied Ecology
#         61(9), 2194-2206, doi:10.1111/1365-2664.14714 (not read; the design below is from the
#         Dryad methods, the README and the authors' SECR_script.R).
# Data:   README.md; SECR_script.R (the authors' secr models, read: noccasions per session and
#         the session covariates come from it); CA1.txt, one row per capture (344): secrSession
#         (1Ls1, 1Ls2, 3Ls1, 3Ls2, 4Ls1, 4Ls2, 5Ls1, 5Ls2 = session 1/3/4/5 x grid s1/s2; sessions
#         are not consecutive because the PhD's other sites are omitted), FKAnimalID (MM0001..,
#         230 mice), Occasion (night within the session; negative = euthanised, not released),
#         FKTrapID, Age, Sex, Weight, newage (Ad > 11 g, else J), Leptospira test results (MAT,
#         MAT serovar Ballum, culture, PCR and summaries), phase (CMR phase only, removal phase
#         only, both), FirstCapt/LastCapt/Occaz (derived). LA1S1..LA2S5.txt: the 36 Longworth
#         traps of each grid x session with anonymised x/y (metres; a different anonymisation
#         per session, so trap ids carry the session: S1L01..S1L36 grid 1, S1L37..S1L72 grid 2).
#         Each session: a 5-night capture-mark-recapture phase (mice ear-tagged, sexed, weighed,
#         released) then a removal phase (mice blood-sampled and euthanised), 10 nights in
#         sessions 1, 3, 4 and 12 in session 5 (secr noccasions). Session labels from the
#         authors' script: 1 = spring 2016, 3 = autumn 2017, 4 = spring 2017, 5 = autumn 2018.
#
# Mapping (standard E9 experimental, spatial capture-recapture; responseType detection,
# unitKind individual):
#   unit = mouse id, taxon = MUSMUS, trap = trap id, period = session 1..4 (deposit sessions
#   1, 3, 4, 5; __periods), occasion = night, y = 1 if caught in that trap that night;
#   cluster_id = grid (s1, s2). obs_removed = 1 on the capture row of a mouse euthanised
#   (negative Occasion); it has no rows after that night.
#   At-risk span (E4.4): each mouse is at risk at the 36 traps of its own grid. A mouse first
#   caught as an adult (newage Ad, unknown age) is at risk from session 1; one caught as a
#   juvenile (newage J, <= 11 g) from its capture session. A mouse not euthanised stays at risk
#   to the last session (no rows are dropped for sessions without capture, ruling #30).
#   Covariates (each constant per mouse in the deposit, asserted): unit_sex, unit_age,
#   unit_newage, unit_weight, unit_mat_positive, unit_ballum_positive, unit_culture_positive,
#   unit_pcr_positive, unit_tested, unit_exposed (laboratory results on the same mouse, not
#   model outputs), unit_phase.
#   Survey evidence = inferred: trap usage is not deposited; every trap of a grid is taken as
#   set on every night of the session (the authors' secr script treats all traps as operating
#   on all noccasions).
#   Coordinates: anonymised by the source (local metres per session) and shipped as such in
#   __traps; Mus musculus is not threatened.
#   Not shipped: FirstCapt, LastCapt, Occaz (derived from the capture rows), CultPCR and ballum
#   (recodes of the shipped test columns).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "moinet_2024_nz_mouse_scr"
dir <- download_dryad("doi:10.5061/dryad.x69p8czsq", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "297564"))
SESS <- data.table(code = c("1L", "3L", "4L", "5L"), period = 1:4, src_session = c(1L, 3L, 4L, 5L),
                   nocc = c(10L, 10L, 10L, 12L), season = c("spring", "autumn", "spring", "autumn"),
                   year = c(2016L, 2017L, 2017L, 2018L))
scr <- readLines(file.path(dir, "SECR_script.R"), warn = FALSE)
stopifnot(any(grepl("noccasions=c(10,10,10,10,12,12,12,12)", scr, fixed = TRUE)))

ca <- fread(file.path(dir, "CA1.txt"), colClasses = list(character = c("MAT_Positives")))
stopifnot(nrow(ca) == 344L, uniqueN(ca$FKAnimalID) == 230L,
          all(ca$secrSession %in% paste0(rep(SESS$code, each = 2), c("s1", "s2"))))
ca[, `:=`(code = substr(secrSession, 1, 2), grid = substr(secrSession, 3, 4), night = abs(Occasion), removed = as.integer(Occasion < 0))]
ca <- merge(ca, SESS, by = "code")
stopifnot(all(ca$night >= 1L & ca$night <= ca$nocc),
          ca[, uniqueN(secrSession), by = FKAnimalID][, all(V1 == 1L)],          # one session-grid per mouse
          !anyDuplicated(ca[, .(FKAnimalID, night)]),                             # at most one capture per night
          ca[, .(nrem = sum(removed)), by = FKAnimalID][, all(nrem <= 1L)],
          ca[, if (any(removed == 1L)) night[removed == 1L] == max(night) else TRUE, by = FKAnimalID][, all(V1)],
          sum(ca$removed) == 186L,
          all(substr(ca$FKTrapID, 2, 2) == as.character(ca$src_session)),
          all(ifelse(ca$grid == "s1", as.integer(substring(ca$FKTrapID, 4)) <= 36L, as.integer(substring(ca$FKTrapID, 4)) >= 37L)))
ucov <- c("Age", "Sex", "Weight", "newage", "MAT_Positives", "BallumPositive", "CulturePos", "PCRpositive", "Tested", "Exposed", "phase")
stopifnot(ca[, lapply(.SD, uniqueN), by = FKAnimalID, .SDcols = ucov][, all(unlist(.SD) == 1L), .SDcols = ucov],
          all(ca$newage %in% c("Ad", "J")), all(ca$Sex %in% c("M", "F")))

# traps
traps <- rbindlist(lapply(seq_len(nrow(SESS)), function(i) rbindlist(lapply(1:2, function(g) {
  t <- fread(file.path(dir, sprintf("LA%dS%d.txt", g, SESS$src_session[i])), header = FALSE, col.names = c("trap", "y", "x"))
  stopifnot(nrow(t) == 36L, all(grepl(sprintf("^S%dL", SESS$src_session[i]), t$trap)))
  t[, `:=`(grid = paste0("s", g), period = SESS$period[i])]
}))))
stopifnot(!anyDuplicated(traps$trap), all(ca$FKTrapID %in% traps$trap))

# one row per mouse x trap of its grid x night, for every session it was at risk
ind <- unique(ca[, .(grid = grid[1], cap_period = period[1], newage = newage[1], removed_any = max(removed),
                     rem_night = if (any(removed == 1L)) night[removed == 1L] else NA_integer_), by = .(unit = FKAnimalID)])
ind[, `:=`(p0 = ifelse(newage == "J", cap_period, 1L), p1 = ifelse(removed_any == 1L, cap_period, 4L))]
sv <- traps[, .(trap, grid, period)][SESS[, .(period, nocc)], on = "period"]
sv <- sv[, .(occasion = seq_len(nocc)), by = .(trap, grid, period)]
long <- ind[sv, on = .(grid), allow.cartesian = TRUE, nomatch = NULL][period >= p0 & period <= p1]
long <- long[is.na(rem_night) | period < cap_period | occasion <= rem_night]
ca[, `:=`(unit = FKAnimalID, trap = FKTrapID, occasion = night)]
long <- merge(long, ca[, .(unit, trap, period, occasion, y = 1L, obs_removed = removed)],
              by = c("unit", "trap", "period", "occasion"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_removed = 0L)]
stopifnot(sum(long$y) == 344L, sum(long$obs_removed) == 186L)
uc <- unique(ca[, .(unit, unit_sex = Sex, unit_age = Age, unit_newage = newage, unit_weight = Weight,
                    unit_mat_positive = as.integer(MAT_Positives), unit_ballum_positive = BallumPositive,
                    unit_culture_positive = CulturePos, unit_pcr_positive = PCRpositive,
                    unit_tested = Tested, unit_exposed = Exposed, unit_phase = phase)])
stopifnot(nrow(uc) == 230L)
long <- merge(long, uc, by = "unit")
long <- long[, c(list(unit = unit, taxon = "MUSMUS", y = y, trap = trap, period = period, occasion = occasion,
                      cluster_id = grid), .SD, list(obs_removed = obs_removed)), .SDcols = setdiff(names(uc), "unit")]
long <- order_eco(long)
# the at-risk rows: per mouse, (sessions at risk) x 36 traps x nights, truncated at removal
exp_rows <- ind[, sum(sapply(p0:p1, function(p) 36L * (if (!is.na(rem_night) && p == cap_period) rem_night else SESS$nocc[p]))), by = unit]$V1
stopifnot(nrow(long) == sum(exp_rows))

taxa <- make_taxa("MUSMUS", "Mus musculus", vernacularName = "House mouse")
periods <- SESS[, .(period, deposit_session = src_session, season, year, nights = nocc,
                    label = sprintf("%s %d", season, year))]
periods <- merge(periods, ca[, .(n_mice = uniqueN(unit), n_captures = .N, n_euthanised = sum(removed)), by = period], by = "period")
traps_out <- traps[, .(trap, x, y, grid, period)]

dataset <- list(
  title = "Spatial capture-recapture of 230 house mice on two 36-trap Longworth grids in New Zealand farmland, 4 sessions 2016-2018",
  creator = "Moinet, Marie; Abrahão, Carlos; Gasparotto, Vinícius; Wilkinson, David; Vallee, Emilie; Benschop, Jackie; Russell, James",
  pubDate = "2024", doi = "10.5061/dryad.x69p8czsq", sourceURL = "https://doi.org/10.5061/dryad.x69p8czsq",
  citation = "Moinet, M., Abrahão, C., Gasparotto, V., Wilkinson, D., Vallee, E., Benschop, J., & Russell, J. (2024). Data from: Density matters: How population dynamics of house mice (Mus musculus) inform the epidemiology of Leptospira [Dataset]. Dryad. https://doi.org/10.5061/dryad.x69p8czsq",
  paperDOI = "10.1111/1365-2664.14714",
  abstract = "Introduced house mice live-trapped on two grids in spring and autumn sessions between 2016 and 2018 near Massey University, New Zealand: a five-night capture-mark-recapture phase followed by a removal phase in which mice were sampled and euthanised and tested for Leptospira (MAT, culture, PCR). The paper estimates density and activity areas with SECR and relates them to infection status.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Two grids of 36 Longworth live traps, four sessions; each session a five-night capture-mark-recapture phase (mice ear-tagged, sexed, weighed and released) followed by a removal phase (mice blood-sampled, euthanised and their kidneys tested for Leptospira), 10 nights in total (12 in the last session). History is mouse x trap x night.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap usage is not deposited. Every trap of a grid is taken as set on every night of the session (10 nights; 12 in the last), as in the authors' secr script (noccasions 10,10,10,10,12,12,12,12 and no usage). Each mouse has rows at its own grid's 36 traps for every session it was at risk.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "period (closed within a session, removals on capture; open between sessions)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  temporalCoverage = "2016-10/2018-04",
  geographicCoverage = "Two trapping grids on farmland near Massey University, Palmerston North, New Zealand (trap coordinates anonymised by the source)",
  crs = "local anonymised metres (a different anonymisation per session)",
  coordinatesCoarsened = list(value = FALSE, method = "trap coordinates anonymised by the source (local metres, per session); shipped as deposited"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Trap ids carry the session because the source anonymised coordinates per session; grids are cluster_id. Removal phase: obs_removed = 1 on the capture of a euthanised mouse, no rows after it.",
  notes = "Mice first caught as adults (unknown age) have rows from session 1 at their grid's traps; juveniles (<= 11 g) from their capture session; mice not euthanised to session 4. 186 of 230 mice were euthanised. Leptospira results are laboratory tests on the same mouse (unit_ columns, NA when not tested). Session dates are not deposited; season and year per session from the authors' script.",
  notShipped = list(FirstCapt_LastCapt_Occaz = "derived from the capture rows",
                    CultPCR_ballum = "recodes of the shipped culture, PCR and Ballum MAT columns"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps_out, script = "data/moinet_2024_nz_mouse_scr.R")
stage_dict_row(TABLE,
  description = "Spatial capture-recapture histories (mouse x trap x night) of 230 house mice on two 36-trap Longworth grids near Palmerston North, New Zealand, in four capture-mark-recapture-then-removal sessions 2016-2018, with Leptospira test results per mouse; trap coordinates anonymised by the source.",
  url = "https://doi.org/10.5061/dryad.x69p8czsq",
  reference = "Moinet, M., Abrahão, C. R., Gasparotto, V. P. O., Wilkinson, D. A., Vallée, E., Benschop, J., & Russell, J. C. (2024). Density matters: How population dynamics of house mice (Mus musculus) inform the epidemiology of Leptospira. Journal of Applied Ecology, 61(9), 2194-2206.",
  doi_paper = "10.1111/1365-2664.14714", doi_data = "10.5061/dryad.x69p8czsq",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "SCR with a removal phase (obs_removed); trap usage inferred; anonymised trap coordinates.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (multi-session, live traps with removal phase)",
  sampling_protocol = "live_trap", design = "Multi-session (4 sessions x 10-12 nights, 2 trapping grids)",
  realm = "Terrestrial", country = "NZL", coordinates = "As published (anonymised trap coordinates in __traps)",
  notes = "Experimental (E9): trap key + __traps. Removal phase flagged by obs_removed. Survey set inferred.")
