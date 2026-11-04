#!/usr/bin/env Rscript
# Table:  schleimer_2019_gsl_finwhale_cjs
# Source: Dryad doi:10.5061/dryad.pv93760, version 23667 (2019-03-19), CC0 1.0 (as shown on
#         the Dryad landing page and in the API record).
#   Schleimer, A., Ramp, C., Delarue, J., Carpentier, A., Berube, M., Palsboll, P. J.,
#   Sears, R. & Hammond, P. S. (2019). Data from: Decline in abundance and apparent survival
#   rates of fin whales (Balaenoptera physalus) in the northern Gulf of St. Lawrence.
# Paper:  Schleimer et al. (2019). Ecology and Evolution 9(7), 4231-4244,
#         doi:10.1002/ece3.5055.
# Data:   one zip, Schleimer_et_al_2019_fin_whale_mark_recapture_data_code.zip, holding
#   Data/Chall19822016.txt      507 photo-identified whales x 35-character annual history
#                               (1982-2016), ID as a MARK comment /*IDnnn*/; the full set.
#   Data/Chsexed19902015.txt    227 genetically sexed whales, sex F/M, history cut to 1990-2015;
#                               136 of these histories have some early sightings zeroed (an
#                               analysis subset), so only the sex column is used.
#   Data/ChPopan20042010.txt,   POPAN windows of the same histories (subsets of Chall: same
#   Data/ChPopan20102016.txt    whales, 7 years each); not shipped (redundant).
#   Data/Calves.txt             44 IDs first identified as calves; 41 of them are in Chall.
#                               The authors drop them from every model (a calf's sightings
#                               follow its mother's).
#   Data/SightingHist.txt       5,191 raw sightings (Year, ID, Date dd/mm/yyyy, Zone); one
#                               zone (MING, the Mingan Islands / Jacques Cartier Passage study
#                               area), 52 exact duplicate rows, and one row whose Date year (1983)
#                               disagrees with its Year (1984). The Year column is what built
#                               the histories: the per-year sighting set equals Chall exactly.
#   Rcode/Schleimer_et_al_2019_Rmark.R   the authors' RMark analysis.
#
# Mapping (standard E1-E5, CJS): unit = whale ID, taxon = BALPHY, period = year 1..35
#   (1982..2016, in __periods), y = 0/1 from Chall19822016, y_raw = number of distinct
#   sighting dates that year in SightingHist (the uncollapsed count behind y; 0 where y = 0).
#   No occasion (one annual occasion per period), no date (several sightings per year).
#   unit_sex = F/M from Chsexed19902015 for the 227 sexed whales, NA otherwise (sex is a
#   property of the whale, so it applies to the whole 1982-2016 history). unit_calf = 1 for
#   the 41 whales listed in Calves.txt, which the authors exclude; kept here so the user can
#   choose. At-risk span (E4.4): the whales are wild animals of unknown age (rows from 1982,
#   zeros before first capture; a field season happened every year), except the 41 calves,
#   first identified as calves with their mothers: born in the year of first identification,
#   so no rows before it. Natural marks (no tag loss); every whale has a sighting.
#   surveyEvidence = deposited_matrix: a photo-ID season ran every year 1982-2016 (the
#   paper's 35 years of surveys); the deposit has no effort per year.
#   No coordinates (one study zone). Balaenoptera physalus is IUCN VU, but nothing to coarsen.
#   Not shipped: the POPAN window files (subsets of Chall), the authors' residency clusters
#   (derived by clustering the same sighting histories, and not deposited per whale).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "schleimer_2019_gsl_finwhale_cjs"
dir <- download_dryad("doi:10.5061/dryad.pv93760", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
inner <- file.path(dir, "Schleimer_et_al_2019_fin_whale_mark_recapture_data_code.zip")
stopifnot(file.exists(inner))
xdir <- file.path(dir, "x")
if (!dir.exists(xdir)) unzip(inner, exdir = xdir)
dd <- file.path(xdir, "Schleimer_et_al_2019_fin_whale_mark_recapture_data_code", "Data")
stopifnot(setequal(list.files(dd), c("Calves.txt", "Chall19822016.txt", "ChPopan20042010.txt",
                                     "ChPopan20102016.txt", "Chsexed19902015.txt", "SightingHist.txt")))

years <- 1982:2016; Tn <- length(years)
ch <- fread(file.path(dd, "Chall19822016.txt"), colClasses = "character")
stopifnot(identical(names(ch), c("ID", "ch")), grepl("^/\\*ID[0-9]{3}\\*/$", ch$ID))
ch[, ID := gsub("[/*]", "", ID)]
stopifnot(nrow(ch) == 507, !anyDuplicated(ch$ID), all(nchar(ch$ch) == Tn), all(grepl("^[01]+$", ch$ch)),
          all(grepl("1", ch$ch)))
CH <- do.call(rbind, lapply(strsplit(ch$ch, ""), as.integer)); stopifnot(dim(CH) == c(507, Tn))

sx <- fread(file.path(dd, "Chsexed19902015.txt"), colClasses = "character")
sx[, ID := gsub("[/*]", "", ID)]
stopifnot(nrow(sx) == 227, !anyDuplicated(sx$ID), all(sx$sex %in% c("F", "M")), all(sx$ID %in% ch$ID),
          sum(sx$sex == "F") == 90)
# the sexed file is Chall cut to 1990-2015 (positions 9..34) with some early sightings set to 0
# (136 of 227 differ, always by 1 -> 0; 4 sexed histories are all zero): it is an analysis
# subset, so only sex is taken from it, and the histories come from Chall
sxb <- do.call(rbind, lapply(strsplit(sx$ch, ""), as.integer))
chb <- do.call(rbind, lapply(strsplit(substr(ch$ch[match(sx$ID, ch$ID)], 9, 34), ""), as.integer))
stopifnot(all(sxb <= chb), sum(rowSums(sxb != chb) > 0) == 136)

cal <- fread(file.path(dd, "Calves.txt"), header = FALSE, colClasses = "character")
stopifnot(nrow(cal) == 44, sum(cal$V1 %in% ch$ID) == 41)

s <- fread(file.path(dd, "SightingHist.txt"), colClasses = "character")
stopifnot(identical(names(s), c("Year", "ID", "Date", "Zone")), nrow(s) == 5191, all(s$Zone == "MING"),
          setequal(s$ID, ch$ID), all(grepl("^[0-9]{2}/[0-9]{2}/[0-9]{4}$", s$Date)),
          sum(duplicated(s)) == 52, sum(substr(s$Date, 7, 10) != s$Year) == 1)
s <- unique(s)
nsight <- s[, .(n = uniqueN(Date)), by = .(ID, Year = as.integer(Year))]
YR <- matrix(0L, nrow(ch), Tn)
YR[cbind(match(nsight$ID, ch$ID), match(nsight$Year, years))] <- nsight$n
stopifnot(identical(YR > 0, CH == 1L))           # the raw sightings rebuild Chall exactly

covs <- data.frame(sex = sx$sex[match(ch$ID, sx$ID)], calf = as.integer(ch$ID %in% cal$V1))
long <- array_to_eco(CH, taxon = "BALPHY", site_ids = ch$ID, site_covs = covs, period = seq_len(Tn), y_raw = YR)
long[, occasion := NULL]
stopifnot(nrow(long) == 507 * Tn, sum(long$y) == sum(CH), sum(long$unit_calf) == 41 * Tn)
# E4.4: a calf is marked in its birth year (first identification): no rows before it
first <- apply(CH, 1, function(r) which(r == 1L)[1])
start <- ifelse(covs$calf == 1L, first, 1L)
long <- long[period >= start[match(unit, ch$ID)]]
stopifnot(nrow(long) == sum(Tn - start + 1L), sum(long$y) == sum(CH))

taxa <- make_taxa("BALPHY", "Balaenoptera physalus", vernacularName = "Fin Whale", taxon_iucnCategory = "VU")
periods <- data.table(period = seq_len(Tn), year = years)
dataset <- list(
  title = "Photo-identification capture histories of 507 fin whales, northern Gulf of St. Lawrence, 1982-2016",
  creator = "Schleimer, Anna; Ramp, Christian; Delarue, Julien; Carpentier, Alain; Berube, Martine; Palsboll, Per J.; Sears, Richard; Hammond, Philip S.",
  pubDate = "2019", doi = "10.5061/dryad.pv93760", sourceURL = "https://doi.org/10.5061/dryad.pv93760",
  citation = "Schleimer, A., Ramp, C., Delarue, J., Carpentier, A., Berube, M., Palsboll, P. J., Sears, R., & Hammond, P. S. (2019). Data from: Decline in abundance and apparent survival rates of fin whales (Balaenoptera physalus) in the northern Gulf of St. Lawrence. Dryad. https://doi.org/10.5061/dryad.pv93760",
  paperDOI = "10.1002/ece3.5055",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual photo-identification histories of 507 fin whales identified by the Mingan Island Cetacean Study in the northern Gulf of St. Lawrence over 35 years (1982-2016), from more than 5,000 identifications. The authors fit CJS models (survival with a linear trend and a sharp late decline) and POPAN super-population models.",
  samplingProtocol = "Boat-based photo-identification surveys each summer (June-October) in the Mingan Islands / Jacques Cartier Passage study area; one annual capture occasion per whale per year, y_raw = number of days the whale was photographed that year.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "period (one annual occasion; survival and emigration between years)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Northern Gulf of St. Lawrence, Quebec, Canada: Mingan Islands and Jacques Cartier Passage (one study zone; no coordinates deposited)",
  temporalCoverage = "1982/2016", coordinatesCoarsened = NA,
  notes = "unit_calf = 1 marks the 41 whales listed in Calves.txt, which the authors exclude from all models because a calf's sightings follow its mother's; filter them out to reproduce the paper. Their rows begin in the year of first identification (born that year; E4.4); every other whale is of unknown age, with rows from 1982 and zeros before first capture. unit_sex is NA for the 280 whales not genetically sexed. The authors' CJS analyses use 1990-2016 subsets of these histories.",
  notShipped = list(
    `ChPopan20042010.txt, ChPopan20102016.txt` = "7-year windows of the same histories for POPAN; recoverable from this table by period",
    `residency clusters` = "the authors' visitor / core-regular grouping is a clustering of the same sighting histories and is not deposited per whale",
    `SightingHist.txt Zone` = "constant (MING)",
    `Calves.txt IDs not in Chall` = "3 calf IDs have no history (ID140, ID188, ID451)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/schleimer_2019_gsl_finwhale_cjs.R")

stage_dict_row(TABLE,
  description = "Annual photo-ID capture histories (CJS) of 507 fin whales in the northern Gulf of St. Lawrence, 1982-2016, with genetic sex for 227, a calf flag, and the number of sighting days per year as y_raw (Schleimer et al. 2019).",
  url = "https://doi.org/10.5061/dryad.pv93760",
  reference = "Schleimer, A., Ramp, C., Delarue, J., Carpentier, A., Berube, M., Palsboll, P. J., Sears, R., & Hammond, P. S. (2019). Decline in abundance and apparent survival rates of fin whales (Balaenoptera physalus) in the northern Gulf of St. Lawrence. Ecology and Evolution 9(7), 4231-4244.",
  doi_paper = "10.1002/ece3.5055", doi_data = "10.5061/dryad.pv93760",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip (version 23667) holds an inner zip; histories from Chall19822016.txt, y_raw from SightingHist.txt (rebuilds Chall exactly). Calves kept and flagged (authors exclude them).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "photo_id", design = "Multi-session (35 annual primary periods, no secondary)", realm = "Marine",
  country = "CAN", coordinates = "None in source",
  notes = "Individuals as unit; rows from 1982 with zeros before first capture, except calves (from their first identification); unit_calf flags calves the authors exclude.")
