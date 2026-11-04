#!/usr/bin/env Rscript
# Table:  curtis_2021_sannicolas_ziphius_cjs
# Source: Dryad doi:10.5061/dryad.547d7wm4j, version 212724 (version 15, published 2022-12-23),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Curtis, K. A., Falcone, E. A., Schorr, G. S., Moore, J. E., Moretti, D. J., Barlow, J. &
#         Keene, E. "Data from: Abundance, survival, and annual rate of change in Cuvier's beaked
#         whales (Ziphius cavirostris) on a Navy sonar range".
# Paper:  Curtis, K. A. et al. (2021). Marine Mammal Science 37(2), 399-419, doi:10.1111/mms.12747
#         (not read: Wiley; the mapping follows the authors' deposited R code, which built every
#         history the paper analyses, and is checked against the capture-frequency counts their
#         code records for Table 1).
# Data:   17 files in the version zip.
#   SCORE-Zc-Data_20190315.xlsx  sheet SCORE-Zc-Sightings: 146 group sightings (date, vessel,
#                                sighting number, basin SanNic 140 / Catalina 5 / SantaCruz 1,
#                                start position, group size, calves, number of photo IDs);
#                                sheet SCORE-Zc-ID: 347 individual photo-ID records, 318 of them of
#                                188 catalogued whale IDs and 29 with no ID (not catalogued; dropped)
#                                (date, vessel, sighting, age class, sex and confidences,
#                                dorsal-fin damage, and for each side (L, R) of the best photo:
#                                photo quality 1-3 (1 best), distinctiveness 0-5, and the number
#                                of quality aspects scored 3).
#   tSCORE-Zica-Effort_20190315.txt   180,666 vessel GPS fixes at ~5-min intervals, 2006-08-12 to
#                                2018-11-21, five vessels, with depth, >800 m flag, basin flags and
#                                survey conditions (Q quality, Beaufort B 0-6, visibility,
#                                swell).
#   SCORE-Zica-TrackGISCond_20180427.txt  an older effort file; the authors splice in one
#                                vessel-day from it (N2, 2007-10-24 after 11:11).
#   Data_key.docx                field definitions (read).
#   1_ziphius.process.pub.r ... 9_*.r, plots.pub.r, *.bug   the authors' processing, multimark
#                                CJS / closed, Bayesian Pradel and simulation code (read, not
#                                run); SOAR.KML the range boundary (not shipped).
#
# Mapping (standard E9 CJS with two-sided photo-ID, responseType state, unitKind individual):
#   This reproduces the authors' 1_ziphius.process.pub.r selection for the multimark CJS with
#   precaptures (their "pc" history, the one Table 1 summarises): San Nicolas Basin sightings
#   only, minus sighting 2011-05-05 PHY 5 (Tanner Canyon); 2007-08-01 to 2018-07-31; annual
#   occasions running 1 August to 31 July (11 periods); records with an accepted photo (quality
#   <= 2 on either side) whose accepted side is distinctive (marks >= 2), not calves, of whales
#   with at least one photo with no aspect scored 3 anywhere in the catalogue.
#   unit = whale ID (Zc<ID>), taxon = ZIPCAV, period = annual occasion 1..11, no occasion.
#   y = the multimark "sometimes" capture type for the year: 0 not photographed, 1 left side
#   only, 2 right side only, 3 left and right on separate encounters (sides not linked within
#   the year), 4 both sides on one encounter. y_raw not used.
#   unit_identity (E2 partial identity) = the sides from which the whale is identified: "both"
#   for the 87 whales whose sides are linked and for the one unlinked whale photographed on both
#   sides (a code-3 year), "left" for the 18 whales only ever photographed on the left, "right"
#   for the 21 only ever photographed on the right. unit_known keeps the authors' multimark
#   `known` vector (1 = sides linked: a both-sides capture in some year, linked high-quality
#   photos, fin damage with an accepted photo, or ID 16); it differs from unit_identity == "both"
#   only for that one whale. A one-sided whale may be the same animal as another one-sided ID:
#   that is what multimark models.
#   unit_sex = the single sex assigned across the whale's records (Female / Male), "Unknown"
#   when never assigned; obs_age_class = age class assigned in that year (NA where y = 0).
#   obs_precapture = 1 on captures before the year of the whale's first photo with no aspect
#   scored 3 (the authors' precaptures); setting those cells to 0 gives their "npc" history.
#   Survey evidence: effort_table. The effort file gives vessel time inside the San Nicolas
#   Basin over > 800 m depth in every one of the 11 years (asserted), so every whale-year is a
#   surveyed cell. At-risk span (E4.4): the whales are wild adults and juveniles of unknown age
#   (calves excluded), so every whale's rows run from the first year, 2007/08; years before its
#   first capture are 0. No tag loss (natural marks); no never-detected IDs (every ID is in the
#   analysis set because it was photographed).
#   Effort per year (minutes and days, and minutes at Beaufort 0-2 and 0-3, the authors'
#   eff.02 / eff.03) is in __periods.
#   No coordinates in the core (one study basin, a Navy range); IUCN LC.
#   Not shipped: the Pradel left-side / right-side histories (the same captures restricted to one
#   side, rebuildable from the photo scores); eff.bssn (a capture-rate-weighted effort index the
#   authors derive from these captures); the correction factor for unmarked animals; group
#   sightings and positions; calves and records outside the selection above (the authors'
#   analysis set is what ships, so the table is the paper's data); the closed-model subsets.
Sys.setenv(TZ = "UTC"); invisible(Sys.setlocale("LC_TIME", "C"))
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages({ library(readxl); library(readr) })
TABLE <- "curtis_2021_sannicolas_ziphius_cjs"
dir <- download_dryad("doi:10.5061/dryad.547d7wm4j", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "212724"))
stopifnot(length(list.files(dir)) == 17L)

xl <- file.path(dir, "SCORE-Zc-Data_20190315.xlsx")
stopifnot(identical(excel_sheets(xl), c("SCORE-Zc-Sightings", "SCORE-Zc-ID")))
sight <- as.data.table(read_excel(xl, sheet = "SCORE-Zc-Sightings"))
indiv <- as.data.table(read_excel(xl, sheet = "SCORE-Zc-ID"))
stopifnot(nrow(sight) == 146L, nrow(indiv) == 347L, sum(is.na(indiv$ID)) == 29L, uniqueN(na.omit(indiv$ID)) == 188L,
          identical(sort(unique(sight$Basin)), c("Catalina", "SanNic", "SantaCruz")), !anyNA(indiv$AgeClass))
indiv <- indiv[!is.na(ID)]      # 29 photo records not admitted to the catalogue (no ID)
setnames(sight, c("Grp Size"), c("grpsize"))
setnames(indiv, c("Qual L", "Qual R", "Marks L", "Marks R", "Q3 L", "Q3 R"), c("qL", "qR", "mL", "mR", "q3L", "q3R"))
sight[, Date := as.Date(Date)]
indiv[, Date := as.Date(Date, format = "%d-%b-%y")]
stopifnot(!anyNA(indiv$Date))
sight[, SightID := paste(Date, Vessel, Sighting, sep = "_")]
indiv[, SightID := paste(Date, Vessel, Sighting, sep = "_")]
stopifnot(all(indiv$SightID %in% sight$SightID))

# --- effort: GPS fixes; minutes to the next fix within vessel-day; the authors' splice ---------
rd_eff <- function(f, basin_names) {
  e <- as.data.table(read_csv(f, col_types = cols(.default = col_character()), progress = FALSE))
  setnames(e, basin_names, c("Cat", "SN", "SC"))
  e[, DateTime := as.POSIXct(paste(sub(" ?0:00:00$", "", Date), sub("^\\S+ ", "", Time)), format = "%m/%d/%Y %H:%M:%S", tz = "UTC")]
  stopifnot(!anyNA(e$DateTime))
  e[, `:=`(Date = as.Date(DateTime), X800m = as.integer(`800m`), SN = as.numeric(SN), B = as.integer(B))]
  e[, .(Vessel, Date, DateTime, X800m, SN, B, Q)]
}
eff <- rd_eff(file.path(dir, "tSCORE-Zica-Effort_20190315.txt"), c("CatalinaBasin", "SanNic", "SantaCruz"))
old <- rd_eff(file.path(dir, "SCORE-Zica-TrackGISCond_20180427.txt"), c("Cat", "SN", "SC"))
stopifnot(nrow(eff) == 180666L, nrow(old) == 127459L)
# the last N2 fix before 2007-10-24 11:11 (file order) "turns effort off"; then the old file's N2
# fixes for the rest of that day are added (1_ziphius.process.pub.r lines 64-71)
cut_t <- as.POSIXct("2007-10-24 11:11", tz = "UTC")
ri <- tail(which(eff$Vessel == "N2" & eff$DateTime < cut_t), 1)
eff[ri, `:=`(X800m = 0L, SN = 0)]
eff <- rbind(old[Vessel == "N2" & DateTime > cut_t & Date < as.Date("2007-10-25")], eff)
setorder(eff, Vessel, DateTime)
eff[, Minutes := as.numeric(difftime(shift(DateTime, type = "lead"), DateTime, units = "mins")), by = .(Vessel, Date)]
eff <- eff[SN > 0 & X800m > 0]

# --- sightings and records the authors analyse ------------------------------------------------
sight <- sight[Basin == "SanNic" & SightID != "2011-05-05_PHY_5"]
indiv <- indiv[SightID %in% sight$SightID]
d0 <- as.Date("2007-08-01"); d1 <- as.Date("2018-08-01")
indiv <- indiv[Date >= d0 & Date < d1]; eff <- eff[Date >= d0 & Date < d1]
breaks <- seq(d0, d1, by = "year"); stopifnot(length(breaks) == 12L)
n_occ <- length(breaks) - 1L
occ_of <- function(d) findInterval(as.numeric(d), as.numeric(breaks))
indiv[, occ := occ_of(Date)]; eff[, occ := occ_of(Date)]
stopifnot(all(indiv$occ %in% seq_len(n_occ)), all(eff$occ %in% seq_len(n_occ)))

nz <- function(x) !is.na(x)
indiv[, `:=`(RQ2 = nz(qR) & qR <= 2, LQ2 = nz(qL) & qL <= 2, R2 = nz(mR) & mR >= 2, L2 = nz(mL) & mL >= 2,
             Q30L = nz(q3L) & q3L == 0, Q30R = nz(q3R) & q3R == 0, nC = AgeClass != "Calf")]
indiv[, Q30 := Q30L | Q30R]
indiv[, `:=`(Q30.i = any(Q30)), by = ID]
setorder(indiv, ID, Date, Sighting)
indiv[Q30.i == TRUE, cap.Q30.occ := occ[which.max(Q30)], by = ID]
indiv[, precap := Q30.i & occ < cap.Q30.occ]
indiv[is.na(precap), precap := FALSE]
indiv[, linkrl := any(((L2 & LQ2) | Q30L) & ((R2 & RQ2) | Q30R) | (FinDmg == 1 & (LQ2 | RQ2)) | ID == 16, na.rm = TRUE), by = ID]
sel <- indiv[(RQ2 | LQ2) & ((RQ2 & R2) | (LQ2 & L2)) & nC & Q30.i]

yy <- sel[, .(T1 = any(LQ2 & !RQ2), T2 = any(RQ2 & !LQ2), T4 = any(RQ2 & LQ2), precap = all(precap),
              age = paste(sort(unique(AgeClass)), collapse = "/")), by = .(ID, occ, linkrl)]
stopifnot(all(sel[, uniqueN(precap), by = .(ID, occ)]$V1 == 1L))     # precapture status is per year
yy[, captype := ifelse(T4, 4L, T1 * 1L + T2 * 2L)]
stopifnot(all(yy$captype %in% 1:4))
known <- yy[, .(kn = any(captype == 4L | linkrl)), by = ID]
ids <- sort(unique(yy$ID))
CH <- matrix(0L, length(ids), n_occ); CH[cbind(match(yy$ID, ids), yy$occ)] <- yy$captype
PC <- matrix(0L, length(ids), n_occ); PC[cbind(match(yy$ID, ids), yy$occ)] <- as.integer(yy$precap)
AG <- matrix(NA_character_, length(ids), n_occ); AG[cbind(match(yy$ID, ids), yy$occ)] <- yy$age
kn <- known$kn[match(ids, known$ID)]

# the authors' Table 1 capture frequencies (2_summarystats.CMR.pub.r, recorded in comments):
# linked whales by number of years captured 1:54 2:16 3:11 4:4 5:1 7:1; right-only 1:18 2:3;
# left-only 1:17 2:1
nyr <- rowSums(CH > 0)
stopifnot(identical(as.vector(table(factor(nyr[kn], levels = c(1:5, 7)))), c(54L, 16L, 11L, 4L, 1L, 1L)))
sides <- yy[, .(r = all(captype == 2L & !linkrl), l = all(captype == 1L & !linkrl)), by = ID]
r_ids <- match(sides[r == TRUE]$ID, ids); l_ids <- match(sides[l == TRUE]$ID, ids)
stopifnot(identical(as.vector(table(nyr[r_ids])), c(18L, 3L)), identical(as.vector(table(nyr[l_ids])), c(17L, 1L)))
# 87 linked + 21 right-only + 18 left-only + 1 unlinked whale photographed on each side in different years
stopifnot(length(ids) == 127L, sum(kn) == 87L, length(r_ids) == 21L, length(l_ids) == 18L)
# the npc history (precaptures removed) keeps every whale (each has a non-precapture year)
stopifnot(all(rowSums(CH * (1L - PC) > 0) > 0))

# whale-level sex: one assigned value across all records (or Unknown)
sx <- indiv[ID %in% ids, .(s = { v <- setdiff(unique(na.omit(Sex)), "Unknown"); if (length(v) == 0) "Unknown" else if (length(v) == 1) v else "conflict" }), by = ID]
stopifnot(!any(sx$s == "conflict"))
side <- ifelse(apply(CH, 1, function(r) any(r %in% 3:4)) | kn, "both",
               ifelse(apply(CH, 1, function(r) all(r %in% c(0L, 1L))), "left", "right"))
stopifnot(all(apply(CH[side == "right", , drop = FALSE], 1, function(r) all(r %in% c(0L, 2L)))),
          identical(as.vector(table(factor(side, c("both", "left", "right")))), c(88L, 18L, 21L)),
          sum(side == "both" & !kn) == 1L)
covs <- data.frame(identity = side, known = as.integer(kn), sex = sx$s[match(ids, sx$ID)])

long <- array_to_eco(CH, taxon = "ZIPCAV", site_ids = sprintf("Zc%03d", ids), site_covs = covs,
                     period = seq_len(n_occ),
                     obs_covs = list(precapture = PC, age_class = AG))
long[, occasion := NULL]
stopifnot(nrow(long) == length(ids) * n_occ, sum(long$y > 0) == nrow(yy), all(long$y %in% 0:4))

# --- effort per annual occasion -> __periods; every occasion surveyed ---------------------------
ep <- eff[, .(effort_min = round(sum(Minutes, na.rm = TRUE), 1),
              effort_min_bss02 = round(sum(Minutes[B <= 2], na.rm = TRUE), 1),
              effort_min_bss03 = round(sum(Minutes[B <= 3], na.rm = TRUE), 1),
              effort_days = uniqueN(Date)), by = occ][order(occ)]
stopifnot(identical(ep$occ, seq_len(n_occ)), all(ep$effort_min > 0))
periods <- data.table(period = seq_len(n_occ), start = format(breaks[-12]), end = format(breaks[-1] - 1),
                      label = sprintf("%d/%02d", 2007:2017, (2008:2018) %% 100),
                      effort_min = ep$effort_min, effort_min_bss02 = ep$effort_min_bss02,
                      effort_min_bss03 = ep$effort_min_bss03, effort_days = ep$effort_days,
                      n_captured = as.integer(colSums(CH > 0)))
cat(sprintf("  %d whales (%d linked) x %d annual occasions; %d captures; effort %s days\n",
            length(ids), sum(kn), n_occ, sum(CH > 0), paste(ep$effort_days, collapse = ",")))

taxa <- make_taxa("ZIPCAV", "Ziphius cavirostris", vernacularName = "Cuvier's beaked whale",
                  taxon_iucnCategory = "LC")

dataset <- list(
  title = "Annual two-sided photo-ID capture histories of 127 Cuvier's beaked whales on the San Nicolas Basin Navy range, southern California, 2007-2018",
  creator = "Curtis, K. Alexandra; Falcone, Erin A.; Schorr, Gregory S.; Moore, Jeffrey E.; Moretti, David J.; Barlow, Jay; Keene, Erin",
  pubDate = "2022", doi = "10.5061/dryad.547d7wm4j", sourceURL = "https://doi.org/10.5061/dryad.547d7wm4j",
  citation = "Curtis, K. A., Falcone, E. A., Schorr, G. S., Moore, J. E., Moretti, D. J., Barlow, J., & Keene, E. (2022). Data from: Abundance, survival, and annual rate of change in Cuvier's beaked whales (Ziphius cavirostris) on a Navy sonar range [Dataset]. Dryad. https://doi.org/10.5061/dryad.547d7wm4j",
  paperDOI = "10.1111/mms.12747",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Photo-identification of Cuvier's beaked whales on the Southern California Offshore Range (San Nicolas Basin), where the Navy's hydrophone array was used to direct small-boat effort to vocalising groups, August 2007 to July 2018. Annual capture histories (August-July occasions) record which side(s) of each whale were photographed, for two-sided (multimark) CJS models of apparent survival, with vessel effort per year.",
  samplingProtocol = "Small-vessel surveys in the San Nicolas Basin guided by real-time acoustic detections from the range hydrophone array; groups approached and both sides photographed where possible. Photos scored for quality (1-3) and distinctiveness (0-5) per side; analysis set as in the authors' processing code (accepted quality <= 2, distinctiveness >= 2, non-calves, whales with at least one top-quality photo).",
  samplingProtocolCode = "photo_id", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The deposited GPS effort track gives vessel time inside the San Nicolas Basin over > 800 m depth in each of the 11 annual occasions (effort_min > 0 in __periods), so every whale-year is a survey.",
  responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not photographed in the year", `1` = "left side only", `2` = "right side only",
                    `3` = "left and right sides on separate encounters (not linked within the year)",
                    `4` = "both sides on one encounter"),
  closure = "none", closureNote = "period (annual occasions August-July; survival between years)", occasionKind = "none", taxonInclusion = "single",
  lossesOnCapture = "none",
  geographicCoverage = "San Nicolas Basin, Southern California Offshore Range (SOAR), California Bight, USA (about 32.8 N, 118.9 W); coordinates of sightings not shipped",
  temporalCoverage = "2007-08-01/2018-07-31",
  coordinatesCoarsened = NA,
  notShipped = list(
    `Pradel left / right histories` = "the same captures restricted to one side (rebuildable from the deposited photo scores)",
    `eff.bssn` = "capture-rate-weighted effort index derived from these captures",
    `group sightings` = "group sizes, calves and positions per sighting",
    `records outside the analysis set` = "calves, low-quality or indistinct photos, sightings outside San Nicolas Basin, 2006-2007 and post-July-2018 records",
    `model inputs` = "unmarked-animal correction factor and closed-model subsets"),
  notes = "Unit ids are the catalogue IDs. y follows multimark data.type 'sometimes' (0-4). unit_identity (both / left / right) is the sides from which each whale is identified; unit_known is the authors' known vector (sides linked), 0 for the 39 one-sided whales and for one whale photographed on both sides in a year without the sides being linked (unit_identity both). One-sided whales may duplicate another ID. obs_precapture = 1 marks the authors' precaptures; set those y to 0 for their 'npc' history. Years before first capture are 0; condition on first capture for CJS.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/curtis_2021_sannicolas_ziphius_cjs.R")

stage_dict_row(TABLE,
  description = "Annual two-sided photo-ID capture histories (left / right / both sides, multimark coding) of 127 Cuvier's beaked whales on the San Nicolas Basin Navy sonar range, southern California, 11 annual occasions 2007-08 to 2017-18, with side-linkage, sex, age class, precapture flags and vessel effort per year.",
  url = "https://doi.org/10.5061/dryad.547d7wm4j",
  reference = "Curtis, K. A., Falcone, E. A., Schorr, G. S., Moore, J. E., Moretti, D. J., Barlow, J., & Keene, E. (2021). Abundance, survival, and annual rate of change of Cuvier's beaked whales (Ziphius cavirostris) on a Navy sonar range. Marine Mammal Science, 37(2), 399-419.",
  doi_paper = "10.1111/mms.12747", doi_data = "10.5061/dryad.547d7wm4j",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Histories built from the individual photo-ID records with the authors' deposited selection code; checked against their Table 1 capture frequencies.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture with two-sided photo-ID (multimark; partial identity)",
  sampling_protocol = "photo_id", design = "Multi-session (11 annual occasions, August-July)",
  realm = "Marine", country = "USA", coordinates = "None in source",
  notes = "Beaked whale on a Navy sonar range; one-sided IDs may be the same animal.")
