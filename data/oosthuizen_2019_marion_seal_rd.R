#!/usr/bin/env Rscript
# Table:  oosthuizen_2019_marion_seal_rd
# Source: Dryad doi:10.5061/dryad.gd23252, version 10605 (published 2019-09-07), licence CC0 1.0
#         (as shown on Dryad). Oosthuizen, W. C., Pradel, R., Bester, M. N. & de Bruyn, P. J. N.
#         "Data from: Making use of multiple surveys: estimating breeding probability using a
#         multievent-robust design capture-recapture model".
# Paper:  Oosthuizen, W. C., Pradel, R., Bester, M. N. & de Bruyn, P. J. N. (2019). Making use of
#         multiple surveys: Estimating breeding probability using a multievent-robust design
#         capture-recapture model. Ecology and Evolution 9:836-848. doi:10.1002/ece3.4828
#         (open access, CC BY; PMC6362610).
# Data:   one file, "1729 PhD data.txt": 1,729 lines, 29 space-separated integers each. Columns
#         1-28 are one composite event code per "seal year" (September of year t to August of
#         t+1) for the 28 breeding seasons 1986-2013; column 29 is an E-SURGE frequency, 1 on
#         every line. Each line is one female southern elephant seal tagged as a weaned pup at
#         Marion Island (1983-2009 cohorts) and encountered at least once as a breeder; the
#         histories condition on that first breeding encounter (paper section 2.5), so the first
#         non-zero code is never 4 (seen outside the breeding season only). Event codes (paper
#         Table 1) combine three capture periods within the seal year: kappa_U = the uneven
#         weekly breeding-season surveys (weeks 1,3,5,7), kappa_E = the even weeks (2,4,6,8),
#         kappa_M = every 10-day survey outside the breeding season (moult and winter):
#           0 not seen; 1 seen in U, E and M; 2 U and M; 3 E and M; 4 M only; 5 U and E;
#           6 U only; 7 E only.
#         No covariates, no dates, no coordinates are deposited.
#
# Mapping (standard E9 robust design, responseType detection, unitKind individual):
#   The eight events are exactly the 2^3 combinations of seen / not seen in the three capture
#   periods, so each seal-year is decomposed losslessly into three rows:
#   unit = line number (individual female), taxon = MIRLEO, period = seal year 1..28 (breeding
#   season 1986..2013, in __periods), occasion = capture period 1 = kappa_U, 2 = kappa_E,
#   3 = kappa_M (the two breeding-season periods interleave in time; kappa_M follows them),
#   y = 1 if the female was seen in that capture period, y_raw = the deposited event code
#   (identical on the three rows of a seal-year). A detection at occasion 1 or 2 implies the
#   female bred that year (only breeders are ashore in the breeding season); a detection at
#   occasion 3 carries no reproductive state, which is the paper's state uncertainty.
#   Survey evidence: the deposited matrix; every capture period was surveyed in every seal
#   year (weekly breeding-season surveys 1986-2013, 10-day non-breeding surveys 1984-2014), so
#   every individual carries the full 28 x 3 rectangle, including the seal years before its
#   first breeding encounter (kept as 0, standard E4; the paper's conditioning on first
#   breeding is a model choice, reproducible by dropping rows before the first y_raw > 0).
#   Not shipped: nothing is omitted. The weekly secondary surveys themselves are not in the
#   deposit (the authors collapsed them to the three capture periods before archiving).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "oosthuizen_2019_marion_seal_rd"
dir <- download_dryad("10.5061/dryad.gd23252", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "1729 PhD data.txt"); stopifnot(file.exists(f))

raw <- strsplit(trimws(readLines(f, warn = FALSE)), "\\s+")
raw <- raw[lengths(raw) > 0]
stopifnot(length(raw) == 1729, all(lengths(raw) == 29))
M <- do.call(rbind, lapply(raw, as.integer))
freq <- M[, 29]; EV <- M[, 1:28]
stopifnot(all(freq == 1L), all(EV %in% 0:7), !any(rowSums(EV > 0) == 0))
first <- apply(EV, 1, function(h) h[h > 0][1])
stopifnot(all(first %in% c(1L, 2L, 3L, 5L, 6L, 7L)))      # histories condition on a breeding encounter
stopifnot(sum(EV > 0) == 6015, identical(as.integer(table(factor(EV[EV > 0], levels = 1:7))),
                                         c(3180L, 325L, 422L, 803L, 804L, 257L, 224L)))
cat(sprintf("  %d females x %d seal years; %d encounters\n", nrow(EV), ncol(EV), sum(EV > 0)))

# event -> seen in each capture period (paper Table 1)
seenU <- EV %in% c(1L, 2L, 5L, 6L); seenE <- EV %in% c(1L, 3L, 5L, 7L); seenM <- EV %in% c(1L, 2L, 3L, 4L)
n_ind <- nrow(EV); n_per <- ncol(EV)
Y <- array(0L, dim = c(n_ind, n_per * 3L))
Y[, seq(1, by = 3, length.out = n_per)] <- as.integer(seenU)
Y[, seq(2, by = 3, length.out = n_per)] <- as.integer(seenE)
Y[, seq(3, by = 3, length.out = n_per)] <- as.integer(seenM)
RAW <- EV[, rep(seq_len(n_per), each = 3L)]
period <- rep(seq_len(n_per), each = 3L)
# lossless check: the three bits reconstruct the event code
code <- matrix(c(0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L), 8, 1)
recon <- array(NA_integer_, dim(EV))
for (e in 0:7) recon[EV == e] <- e
bits <- cbind(as.vector(seenU), as.vector(seenE), as.vector(seenM))
map <- c("000" = 0L, "111" = 1L, "101" = 2L, "011" = 3L, "001" = 4L, "110" = 5L, "100" = 6L, "010" = 7L)
stopifnot(all(map[paste0(bits[, 1] + 0L, bits[, 2] + 0L, bits[, 3] + 0L)] == as.vector(EV)))

long <- array_to_eco(Y, taxon = "MIRLEO", site_ids = seq_len(n_ind), period = period, y_raw = RAW)
stopifnot(nrow(long) == n_ind * n_per * 3L, all(long$occasion %in% 1:3), sum(long$y) == sum(seenU) + sum(seenE) + sum(seenM))

taxa <- make_taxa("MIRLEO", "Mirounga leonina", vernacularName = "Southern elephant seal")
periods <- data.table(period = seq_len(n_per), year = 1985L + seq_len(n_per),
                      label = sprintf("%d/%02d", 1985L + seq_len(n_per), (1986L + seq_len(n_per)) %% 100),
                      note = "seal year: breeding season (Sept-Nov of `year`, occasions 1-2) then moult and winter to August of year+1 (occasion 3)")
dataset <- list(
  title = "Multievent-robust design encounter histories of 1,729 female southern elephant seals, Marion Island, breeding seasons 1986-2013",
  creator = "Oosthuizen, W. Chris; Pradel, Roger; Bester, Marthan N.; de Bruyn, P. J. Nico", pubDate = "2019",
  doi = "10.5061/dryad.gd23252", sourceURL = "https://doi.org/10.5061/dryad.gd23252",
  citation = "Oosthuizen, W. C., Pradel, R., Bester, M. N., & de Bruyn, P. J. N. (2019). Data from: Making use of multiple surveys: estimating breeding probability using a multievent-robust design capture-recapture model [Dataset]. Dryad. https://doi.org/10.5061/dryad.gd23252",
  paperDOI = "10.1002/ece3.4828",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Encounter histories of 1,729 female southern elephant seals tagged as weaned pups at Marion Island (1983-2009 cohorts) and resighted in 28 breeding seasons (1986-2013) plus the moult and winter surveys that follow each. The deposit encodes each seal year as one of eight composite events (seen or not in the uneven breeding-season weeks, the even weeks, and outside the breeding season); here each seal year is three rows, one per capture period, y = seen, y_raw = the event code. Histories condition on the first encounter as a breeder.",
  samplingProtocol = "Weekly island-wide tag-resight surveys of all breeding beaches during the breeding season (8 per season, collapsed by the authors to uneven and even weeks), and 10-day tag-resight surveys of all beaches during the moult and winter; hind-flipper livestock tags on weaned pups.",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "occasion within period (robust design: three capture periods per seal year; breeder / nonbreeder state is fixed within a seal year and may change between years; nonbreeders are assumed unavailable in occasions 1-2)",
  occasionCodes = list(`1` = "kappa_U: breeding-season surveys in weeks 1,3,5,7 (Sept-Nov)", `2` = "kappa_E: breeding-season surveys in weeks 2,4,6,8 (Sept-Nov)", `3` = "kappa_M: moult and winter surveys (Nov-Aug), no reproductive state"),
  respRawCodes = list(`0` = "not seen in any capture period (NS)", `1` = "seen in U, E and M (MUE)", `2` = "seen in U and M (MU)", `3` = "seen in E and M (ME)", `4` = "seen in M only (M)", `5` = "seen in U and E (UE)", `6` = "seen in U only (U)", `7` = "seen in E only (E)"),
  geographicCoverage = "Marion Island, Prince Edward Islands, southern Indian Ocean (46.9 S, 37.7 E); no coordinates deposited",
  temporalCoverage = "1986-09/2014-08",
  coordinatesCoarsened = NA,
  notes = "Rows before an individual's first breeding encounter are kept as 0 (E4); the paper conditions on that encounter, so drop rows before the first y_raw > 0 to reproduce its data. A detection at occasion 1 or 2 implies the female bred that year. The weekly secondary surveys are not in the deposit. Frequency column is 1 throughout; no covariates deposited.",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/oosthuizen_2019_marion_seal_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design tag-resight histories of 1,729 female southern elephant seals (Mirounga leonina) at Marion Island over 28 seal years (breeding seasons 1986-2013), three capture periods per year (uneven breeding weeks, even breeding weeks, moult and winter); y = seen, y_raw = the authors' 8-level composite event code used in their multievent-robust design model.",
  url = "https://doi.org/10.5061/dryad.gd23252",
  reference = "Oosthuizen, W. C., Pradel, R., Bester, M. N., & de Bruyn, P. J. N. (2019). Making use of multiple surveys: Estimating breeding probability using a multievent-robust design capture-recapture model. Ecology and Evolution, 9, 836-848.",
  doi_paper = "10.1002/ece3.4828", doi_data = "10.5061/dryad.gd23252",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First robust-design table. Composite event codes decomposed losslessly into three capture-period rows per seal year; the event code is y_raw. Histories condition on first breeding encounter; leading zeros kept.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multievent / multi-state robust design capture-recapture",
  sampling_protocol = "tag_resight", design = "Robust design (28 seal years x 3 capture periods)", realm = "Marine",
  country = "ZAF", coordinates = "None in source", notes = "Individuals as unit; breeder state implied by breeding-season detection; occasion 3 has no state.")
