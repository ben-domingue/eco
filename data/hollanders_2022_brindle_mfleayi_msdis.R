#!/usr/bin/env Rscript
# Table:  hollanders_2022_brindle_mfleayi_msdis
# Source: Dryad doi:10.5061/dryad.s7h44j19h, version 193669 (2022-08-29), CC0 1.0 as shown on
#         the Dryad page. "Know what you don't know: Embracing state uncertainty in
#         disease-structured multistate models." Hollanders, M.
# Paper:  Hollanders, M. & Royle, J.A. (2022). Know what you don't know: Embracing state
#         uncertainty in disease-structured multistate models. Methods in Ecology and
#         Evolution 13(12), 2827-2837, doi:10.1111/2041-210X.13993. Code: Zenodo 7039520
#         (multievent-mfleayi.qmd), which fixes the array layout used below.
# Data:   ch.csv (no header, 116 rows = marked juvenile Fleay's barred frogs, 64 columns =
#         8 primary periods x 2 weekly secondary surveys x 4 qPCR runs, diagnostic run
#         fastest, then secondary, then primary; qmd: array(ch, c(n.ind, 4, 2, 8))).
#         Cell codes (README): -1 = not captured on that survey; 0 = captured, qPCR run
#         negative for Batrachochytrium dendrobatidis (Bd); > 0 = captured, run positive,
#         the value is the raw ITS gene copies per swab for that run; NA = the survey was
#         skipped, or the occasion is before the individual's first capture, or fewer
#         than 4 runs were done for that swab. Two surveys (primary 4 secondary 2, primary
#         7 secondary 2) are NA for every individual and run: the README's "16, including
#         missing surveys" against "14 weekly surveys". README.txt (study summary, codes).
#         Site: Brindle Creek, northern New South Wales (one site; no coordinates, no
#         dates, no covariates deposited). The qmd uses tau = 2 (weeks) between primaries.
#
# Mapping (standard E9 core: multi-state capture-recapture with a disease state, robust
#   design; the authors' multievent model adds a fourth level, the qPCR run, which the
#   key cannot hold, so the runs are summarised per survey):
#   unit = individual (row number, "F001".."F116"), taxon = MIXFLE, period = primary
#   period 1..8 (__periods: index, secondaries surveyed, nominal interval 2 weeks),
#   occasion = secondary weekly survey 1..2 within the primary; the two skipped surveys
#   are missing rows (deposited_matrix). responseType = state: y = 0 not captured,
#   1 captured and every qPCR run negative (observed uninfected), 2 captured and at least
#   one run positive (observed infected) = the authors' "highest observed diagnostic
#   state" per survey (qmd, o.init.me). No y_raw: the file holds up to four values per
#   survey, not one. The run-level information rides as obs_qpcr_runs (runs performed),
#   obs_qpcr_positive (runs > 0) and obs_its_copies_mean (mean ITS copies over the runs,
#   zeros included, the qmd's x.ms), all NA on rows where the frog was not captured.
#   Occasions before an individual's first capture (NA in the file) are rows with y = 0:
#   the survey happened (E2). Full rectangle 116 x 14 surveys. surveyEvidence =
#   deposited_matrix. No coordinates (IUCN EN species; none deposited anyway).
#   Not shipped: the per-run ITS values as separate rows (a fourth nesting level) and
#   the analysis code.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hollanders_2022_brindle_mfleayi_msdis"
dir <- download_dryad("10.5061/dryad.s7h44j19h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("ch.csv", "README.txt")))

ch <- as.matrix(read.csv(file.path(dir, "ch.csv"), header = FALSE, na.strings = "NA", fileEncoding = "UTF-8-BOM"))
stopifnot(dim(ch) == c(116L, 64L), is.numeric(ch), all(ch[!is.na(ch)] >= -1))
n_ind <- 116L; n_prim <- 8L; n_sec <- 2L; n_diag <- 4L

# long over runs, then summarise per individual x survey
long_runs <- CJ(ind = seq_len(n_ind), period = seq_len(n_prim), occasion = seq_len(n_sec), run = seq_len(n_diag))
long_runs[, col := (period - 1L) * n_sec * n_diag + (occasion - 1L) * n_diag + run]
long_runs[, v := ch[cbind(ind, col)]]
# layout check against the README: columns 1-4 are survey 1 (primary 1, secondary 1)
stopifnot(identical(long_runs[ind == 1 & period == 1 & occasion == 1, v], unname(ch[1, 1:4])))

# skipped surveys: NA for every individual and run
surv <- long_runs[, .(all_na = all(is.na(v))), by = .(period, occasion)]
skipped <- surv[all_na == TRUE]
stopifnot(nrow(skipped) == 2L, identical(skipped[, paste(period, occasion)], c("4 2", "7 2")))
surveyed <- surv[all_na == FALSE, .(period, occasion)]
stopifnot(nrow(surveyed) == 14L)

obs <- long_runs[surveyed, on = .(period, occasion)][, {
  v1 <- v[run == 1L]
  captured <- !is.na(v1) && v1 >= 0
  runs <- v[!is.na(v) & v >= 0]
  if (!is.na(v1) && v1 == -1) stopifnot(all(is.na(v[run > 1L])))       # not captured: no runs
  if (is.na(v1)) stopifnot(all(is.na(v)))                               # before first capture: nothing
  list(captured = captured,
       obs_qpcr_runs = if (captured) length(runs) else NA_integer_,
       obs_qpcr_positive = if (captured) sum(runs > 0) else NA_integer_,
       obs_its_copies_mean = if (captured) round(mean(runs), 3) else NA_real_)
}, by = .(ind, period, occasion)]
stopifnot(nrow(obs) == n_ind * 14L, all(obs[captured == TRUE, obs_qpcr_runs] >= 1L))
# NA-before-first-capture: every NA run-1 cell precedes the individual's first capture
first_cap <- obs[captured == TRUE, .(first = min((period - 1L) * n_sec + occasion)), by = ind]
stopifnot(nrow(first_cap) == n_ind)                                     # every frog captured at least once
na_cells <- long_runs[surveyed, on = .(period, occasion)][run == 1L & is.na(v), .(ind, s = (period - 1L) * n_sec + occasion)]
stopifnot(nrow(na_cells) > 0, all(merge(na_cells, first_cap, by = "ind")[, s < first]))
obs[, y := as.integer(captured) + as.integer(captured & obs_qpcr_positive > 0)]
stopifnot(all(obs$y %in% 0:2), sum(obs$captured) == sum(!is.na(ch[, seq(1, 64, by = 4)]) & ch[, seq(1, 64, by = 4)] >= 0, na.rm = TRUE))   # captures = run-1 cells >= 0
n_cap <- sum(obs$captured); n_inf <- sum(obs$y == 2)
recap <- obs[captured == TRUE, .N, by = ind][N > 1, .N]
cat(sprintf("  %d frogs, 14 surveyed of 16 weekly occasions in 8 primary periods; %d captures (%d with a Bd-positive run), %d frogs recaptured\n",
            n_ind, n_cap, n_inf, recap))
stopifnot(n_cap > n_ind, n_inf > 0)

long <- obs[, .(unit = sprintf("F%03d", ind), taxon = "MIXFLE", y, period, occasion,
                obs_qpcr_runs, obs_qpcr_positive, obs_its_copies_mean)]
long <- order_eco(long)
stopifnot(nrow(long) == n_ind * 14L, !anyDuplicated(long[, .(unit, period, occasion)]))

taxa <- make_taxa("MIXFLE", "Mixophyes fleayi", vernacularName = "Fleay's barred frog", taxon_iucnCategory = "EN")
periods <- data.table(period = seq_len(n_prim),
                      n_secondaries_surveyed = surveyed[, .N, by = period][order(period), N],
                      nominal_interval_weeks = 2L,
                      note = "weekly surveys; the second survey of primary periods 4 and 7 was skipped; calendar dates are not deposited")

dataset <- list(
  title = "Disease-structured robust-design capture histories of 116 juvenile Fleay's barred frogs with per-survey Bd qPCR outcomes, Brindle Creek, NSW",
  creator = "Hollanders, Matthijs", pubDate = "2022", doi = "10.5061/dryad.s7h44j19h",
  sourceURL = "https://doi.org/10.5061/dryad.s7h44j19h",
  citation = "Hollanders, M. (2022). Know what you don't know: Embracing state uncertainty in disease-structured multistate models [Dataset]. Dryad. https://doi.org/10.5061/dryad.s7h44j19h",
  paperDOI = "10.1111/2041-210X.13993",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Mark-recapture of juvenile Fleay's barred frogs (Mixophyes fleayi, IUCN EN) at one site, Brindle Creek, northern New South Wales: 14 weekly surveys arranged as 8 primary periods of 2 secondary surveys (two secondaries skipped), each captured frog swabbed for the amphibian chytrid fungus Batrachochytrium dendrobatidis and the swab run in up to four qPCR replicates. The deposit gives the per-run ITS gene copies; this table summarises them per capture: y = 0 not captured, 1 captured with every run negative, 2 captured with at least one positive run (the authors' observed state), with the number of runs, the number positive and the mean ITS copies as observation covariates. The authors' multievent model treats the runs as a further detection level with false positives and false negatives.",
  samplingProtocol = "Night-time visual-encounter surveys of a creek reach with hand capture of juvenile frogs, individual marking, and a skin swab per capture assayed by qPCR for Bd (up to 4 runs per swab); weekly surveys grouped as 8 primary periods of 2 (robust design)",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  closure = "closed", closureNote = "occasion within period (robust design: infection state fixed within a primary period, open between; nominal interval 2 weeks)", occasionKind = "time", taxonInclusion = "single",
  stateCodes = list(`0` = "not captured", `1` = "captured, all qPCR runs Bd-negative (observed uninfected)",
                    `2` = "captured, at least one qPCR run Bd-positive (observed infected)"),
  geographicCoverage = "Brindle Creek, northern New South Wales, Australia, one site (no coordinates deposited; IUCN EN taxon)",
  temporalCoverage = "calendar dates not deposited: 16 weekly occasions (14 surveyed) in 8 primary periods",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit (IUCN EN taxon)"),
  designNote = "Disease-structured multi-state capture-recapture under a robust design (period = primary, occasion = weekly secondary). The deposit's fourth level, qPCR run within swab, is summarised on each row (obs_qpcr_runs, obs_qpcr_positive, obs_its_copies_mean); the authors' multievent model uses the runs themselves to estimate false-positive and false-negative state assignment, which this table supports only through those summaries.",
  notes = "Cells NA before an individual's first capture are rows with y = 0 (the survey happened; asserted that every such cell precedes the first capture). Surveys (primary 4, secondary 2) and (primary 7, secondary 2) are NA for all frogs and are not rows. obs_its_copies_mean is the mean over the runs performed, zeros included (the qmd's x.ms), on captured rows only. Row order of the deposit is the unit id.",
  notShipped = list(`qPCR run level` = "the up-to-four ITS copy values per swab as separate observations: a fourth nesting level (individual > primary > secondary > run) that the key does not hold; summarised per capture instead",
                    `multievent-mfleayi.qmd` = "the authors' NIMBLE code (Zenodo 7039520)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hollanders_2022_brindle_mfleayi_msdis.R")

stage_dict_row(TABLE,
  description = "Disease-structured robust-design capture histories of 116 juvenile Fleay's barred frogs (Mixophyes fleayi, IUCN EN) at Brindle Creek, NSW: 8 primary periods x 2 weekly secondary surveys (14 surveyed), y = 0 not captured / 1 captured Bd-negative / 2 captured Bd-positive from up to four qPCR runs per swab, with runs, positives and mean ITS copies per capture.",
  url = "https://doi.org/10.5061/dryad.s7h44j19h",
  reference = "Hollanders, M. & Royle, J.A. (2022). Know what you don't know: Embracing state uncertainty in disease-structured multistate models. Methods in Ecology and Evolution 13(12), 2827-2837.",
  doi_paper = "10.1111/2041-210X.13993", doi_data = "10.5061/dryad.s7h44j19h",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "qPCR runs (the authors' multievent fourth level) summarised per capture; two skipped surveys are missing rows; no dates, coordinates or covariates deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Multi-state (disease) robust design capture-recapture; multievent with state uncertainty",
  sampling_protocol = "hand_capture", design = "Robust design (8 primary periods x 1-2 weekly secondary occasions)",
  realm = "Freshwater", country = "AUS", coordinates = "None in source",
  notes = "First disease-state capture-recapture table; infection state from Bd qPCR per capture, run-level summaries as obs_ covariates.")
