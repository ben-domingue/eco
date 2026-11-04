#!/usr/bin/env Rscript
# Tables: symons_2018_bunbury_dolphin_rd, symons_2018_bunbury_femalecalf_msrd (one script, two
#         analysis sets from one deposit)
# Source: Dryad doi:10.5061/dryad.6381477, version 5543 (published 2019-05-30), Symons, Sprogis &
#         Bejder. Licence as shown on the Dryad record: CC0 1.0 (https://spdx.org/licenses/CC0-1.0.html).
# Paper:  Symons, J., Sprogis, K. R. & Bejder, L. (2018). Implications of survey effort on estimating
#         demographic parameters of a long-lived marine top predator. Ecology and Evolution 8(21),
#         10470-10481, doi:10.1002/ece3.4512 (open access, PMC6238146; read for this script).
# Data:   No README in the deposit; the Dryad file descriptions and the paper give the meanings.
#         dryad1.txt "Capture history data": tab-separated, a header of 72 names V1..V72 and 229
#           rows of row-name + 72 values 0/1; each row an individual (row number only, no catalogue
#           id), each column a secondary period, six per primary period, 12 primary periods (austral
#           seasons Dec 2009 - Nov 2012). 28 rows are all zero: catalogue dolphins never photographed
#           in this 3-year subsample (the paper reports 201 dolphins documented; 229 - 28 = 201,
#           asserted). Detections per secondary period 8-59 (the paper's range, asserted).
#         dryad2.txt "Calving event data": 7,200 rows = 100 known (reproductively active) females
#           "female0".."female99" x 12 primary x 6 secondary periods; datesighted (and an identical
#           copy datesighted1) when the female was photographed in that secondary period, NA when
#           not; calfcode and calfsightingdates (= datesighted) when she was photographed with her
#           dependent calf. 40 calf codes = the paper's 40 calving events (4, 17 and 19 new calves in
#           study years 1-3, asserted from each calf's first sighting). 9 females are never seen. The
#           female ids do not link to dryad1's row numbers, and the female sightings are a separate
#           selection (10 of the 91 sighted females match no dryad1 history), so this is a second
#           analysis set, not a recode.
#         Design (paper section 2.2): boat photo-ID along three zig-zag transects off Bunbury,
#           Western Australia (120 km2); completing all three transects is one secondary period
#           (1-12 days, mean 4.1), six per austral season (primary period); closed within seasons,
#           open between.
#
# Mapping (standard E9 robust design, unitKind individual):
#   symons_2018_bunbury_dolphin_rd: unit = dolphin ("BD001".. from the row number), taxon = TURADU,
#     period = primary period 1-12, occasion = secondary period 1-6, y = photographed (0/1). Every
#     secondary period of the study is a survey for every documented dolphin (occasions before a
#     dolphin's first sighting are kept as 0, as in the other robust-design tables; the deposit is
#     the full matrix). surveyEvidence = deposited_matrix. The 28 never-seen rows are not shipped.
#   symons_2018_bunbury_femalecalf_msrd: unit = female ("F00".."F99"), same periods and occasions,
#     y = 0 not photographed / 1 photographed without a calf / 2 photographed with her dependent
#     calf; obs_calf_code = the calf's code on y = 2 rows; obs_date_sighted = the sighting date on
#     y >= 1 rows (secondary periods span several days, so there is no survey date for y = 0 rows).
#     The 9 never-seen females are not shipped. surveyEvidence = deposited_matrix.
#   __periods: season, study year (Dec-Nov), and the first and last female sighting date in the
#   season (the deposit has no survey dates). Coordinates: none deposited. Tursiops aduncus is NT.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
STEM <- "symons_2018_bunbury_dolphin"
dir <- download_dryad("doi:10.5061/dryad.6381477", STEM)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "5543",
          setequal(list.files(dir), c("dryad1.txt", "dryad2.txt")))

# capture histories
raw <- readLines(file.path(dir, "dryad1.txt"))
hdr <- scan(text = raw[1], what = "", quiet = TRUE); stopifnot(identical(hdr, paste0("V", 1:72)), length(raw) == 230)
m <- do.call(rbind, lapply(raw[-1], function(l) as.integer(scan(text = l, what = "", quiet = TRUE))))
stopifnot(ncol(m) == 73, identical(m[, 1], 1:229))
ch <- m[, -1]; stopifnot(all(ch %in% 0:1))
seen <- rowSums(ch) > 0
stopifnot(sum(!seen) == 28, sum(seen) == 201, min(colSums(ch)) == 8, max(colSums(ch)) == 59,
          max(rowSums(ch)) == 42, min(rowSums(ch[seen, ])) == 1)                     # paper: 201 dolphins, 8-59 per secondary, 1-42 sightings
ids <- sprintf("BD%03d", seq_len(nrow(ch)))
rd <- data.table(unit = rep(ids[seen], each = 72), col = rep(1:72, times = sum(seen)), y = as.integer(t(ch[seen, ])))
rd[, `:=`(period = (col - 1L) %/% 6L + 1L, occasion = (col - 1L) %% 6L + 1L, taxon = "TURADU")][, col := NULL]
stopifnot(nrow(rd) == 201 * 72, sum(rd$y) == sum(ch))

# females with calves
fe <- fread(file.path(dir, "dryad2.txt"), na.strings = "NA", skip = 1, header = FALSE)   # header lacks the row-name column
setnames(fe, c("row", scan(file.path(dir, "dryad2.txt"), what = "", nlines = 1, quiet = TRUE)))
stopifnot(identical(fe$row, 1:7200)); fe[, row := NULL]
stopifnot(nrow(fe) == 7200, uniqueN(fe$individual) == 100, all(fe$primaryperiod %in% 1:12), all(fe$secondaryperiod %in% 1:6),
          !anyDuplicated(fe[, .(individual, primaryperiod, secondaryperiod)]),
          fe[!is.na(datesighted), all(datesighted == datesighted1)], fe[, all(is.na(datesighted) == is.na(datesighted1))],
          fe[, all(is.na(calfcode) == is.na(calfsightingdates))], fe[!is.na(calfcode), all(!is.na(datesighted) & calfsightingdates == datesighted)])
fe[, d := as.IDate(datesighted)]
stopifnot(fe[!is.na(datesighted), !anyNA(d)], min(fe$d, na.rm = TRUE) >= as.IDate("2009-12-01"), max(fe$d, na.rm = TRUE) <= as.IDate("2012-11-30"))
calf1 <- fe[!is.na(calfcode), .(first = min(primaryperiod)), by = calfcode]
stopifnot(nrow(calf1) == 40, identical(as.integer(table(factor((calf1$first - 1L) %/% 4L + 1L, levels = 1:3))), c(4L, 17L, 19L)),
          fe[!is.na(calfcode), uniqueN(individual), by = calfcode][, all(V1 == 1)])
fseen <- fe[, .(n = sum(!is.na(datesighted))), by = individual]
stopifnot(fseen[n == 0, .N] == 9)
fe[, num := as.integer(sub("female", "", individual))]; stopifnot(setequal(fe$num, 0:99))
# a separate selection: count sighted females whose 72-cell pattern matches no dryad1 history
fpat <- fe[order(num, primaryperiod, secondaryperiod), .(p = paste(as.integer(!is.na(datesighted)), collapse = "")), by = num]
chp <- apply(ch, 1, paste, collapse = "")
stopifnot(fpat[!(p %in% chp), .N] == 10)
fs <- fe[individual %in% fseen[n > 0, individual]]
ms <- fs[, .(unit = sprintf("F%02d", num), taxon = "TURADU", period = primaryperiod, occasion = secondaryperiod,
             y = fifelse(is.na(datesighted), 0L, fifelse(is.na(calfcode), 1L, 2L)),
             obs_calf_code = calfcode, obs_date_sighted = fifelse(is.na(d), NA_character_, format(d)))]
stopifnot(nrow(ms) == 91 * 72, ms[, sum(y == 2)] == 231, ms[, sum(y >= 1)] == 1232)

# periods: austral seasons from December 2009 (paper section 2.2); female sighting dates fall inside them
season <- rep(c("summer", "autumn", "winter", "spring"), 3)
start <- seq(as.IDate("2009-12-01"), by = "3 months", length.out = 12)
stop_ <- c(start[-1] - 1L, as.IDate("2012-11-30"))
rng <- fe[!is.na(d), .(first = min(d), last = max(d)), keyby = primaryperiod]
stopifnot(nrow(rng) == 12, all(rng$first >= start), all(rng$last <= stop_))
periods <- data.table(period = 1:12, period_season = season, period_study_year = rep(1:3, each = 4),
                      period_start = format(start), period_end = format(stop_),
                      period_first_female_sighting = format(rng$first), period_last_female_sighting = format(rng$last))

taxa <- make_taxa("TURADU", "Tursiops aduncus", vernacularName = "Indo-Pacific bottlenose dolphin")
stopifnot(taxa$gbifMatchType == "EXACT")

COMMON <- list(
  creator = "Symons, John; Sprogis, Kate R.; Bejder, Lars",
  pubDate = "2019-05-30", sourceURL = "https://doi.org/10.5061/dryad.6381477",
  citation = "Symons, J., Sprogis, K. R. & Bejder, L. (2018). Implications of survey effort on estimating demographic parameters of a long-lived marine top predator. Ecology and Evolution 8(21), 10470-10481. https://doi.org/10.1002/ece3.4512. Data: Dryad https://doi.org/10.5061/dryad.6381477 (CC0).",
  paperDOI = "10.1002/ece3.4512", dataDOI = "10.5061/dryad.6381477",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Boat-based photo-identification along three systematic zig-zag transects covering a 120 km2 coastal study area off Bunbury, Western Australia, in Beaufort <= 3 with two to five observers scanning about 250 m either side; every dolphin in an encountered group photographed for dorsal-fin identification; only distinctive fins in high-quality images enter the histories. Completing the three transects is one secondary period (1-12 days); six per austral season.",
  samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix", unitKind = "individual",
  closure = "occasion within period (robust design: secondary periods within an austral season, assumed closed; open between seasons, with Markovian temporary emigration in the paper's models)",
  geographicCoverage = "Coastal waters off Bunbury, south-western Australia (about 33.3 S, 115.6 E; 50 km of coast, 2 km offshore); no coordinates deposited",
  temporalCoverage = "2009-12/2012-11",
  coordinatesCoarsened = NA)

TABLE <- "symons_2018_bunbury_dolphin_rd"
long <- order_eco(rd)
ds <- write_table(long, TABLE, c(COMMON, list(
  title = "Robust-design photo-identification histories of 201 Indo-Pacific bottlenose dolphins off Bunbury, Western Australia, 12 seasons x 6 secondary periods, 2009-2012",
  abstract = "Three-year subsample (December 2009 - November 2012) of the Bunbury long-term dolphin monitoring programme: 201 distinctively marked Indo-Pacific bottlenose dolphins photographed in 72 secondary periods (six per austral season), the data the paper used to show how reducing secondary periods inflates the CV of abundance and delays trend detection.",
  responseType = "detection",
  notes = "Dolphin ids are dryad1 row numbers (no catalogue ids deposited). Occasions before a dolphin's first sighting are kept as 0 (E4). The paper's survey-effort simulations (removing secondary periods) are analyses of this table, not data.",
  notShipped = list(`dryad1.txt rows of zeros` = "28 catalogue dolphins with no photograph in the subsample (the paper documents 201)",
                    `dryad2.txt` = "shipped as symons_2018_bunbury_femalecalf_msrd"))),
  taxa = taxa, periods = periods, script = "data/symons_2018_bunbury_dolphin.R")
stage_dict_row(TABLE,
  description = "Robust-design photo-ID capture histories of 201 Indo-Pacific bottlenose dolphins off Bunbury, Western Australia: 12 austral seasons (Dec 2009 - Nov 2012) x 6 secondary periods, each a completion of three boat transects.",
  url = "https://doi.org/10.5061/dryad.6381477",
  reference = "Symons, J., Sprogis, K. R. & Bejder, L. (2018). Implications of survey effort on estimating demographic parameters of a long-lived marine top predator. Ecology and Evolution 8(21), 10470-10481.",
  doi_paper = "10.1002/ece3.4512", doi_data = "10.5061/dryad.6381477", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "No README deposited; meanings from the Dryad file descriptions and the open-access paper. 28 never-seen rows dropped (the paper documents 201 dolphins). Sibling table symons_2018_bunbury_femalecalf_msrd.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture (survival, Markovian temporary emigration)",
  sampling_protocol = "photo_id", design = "Robust design (12 austral seasons x 6 secondary periods)", realm = "Marine",
  country = "AUS", coordinates = "None in source", notes = "Individuals as unit; ids are row numbers; sibling female-calf multistate table from the same deposit.", status = "tagged")

TABLE <- "symons_2018_bunbury_femalecalf_msrd"
long <- order_eco(ms)
ds <- write_table(long, TABLE, c(COMMON, list(
  title = "Robust-design sighting histories of 91 female Indo-Pacific bottlenose dolphins with and without dependent calves, Bunbury, Western Australia, 2009-2012",
  abstract = "Sighting histories of the reproductively active females of the Bunbury study, with each photograph coded by whether the female's dependent calf was present: 40 calving events (4, 17 and 19 new calves in study years 1-3), used in the paper to show how fewer secondary periods leave calves undocumented in their birth year.",
  responseType = "state",
  stateCodes = list(`0` = "not photographed in the secondary period", `1` = "photographed without a dependent calf", `2` = "photographed with her dependent calf (obs_calf_code names the calf)"),
  notes = "Female ids are the deposit's female0..female99 and do not link to the dolphin ids of symons_2018_bunbury_dolphin_rd; the female sightings are a separate selection (10 of the 91 sighted females match no history in the capture-history file). obs_date_sighted is the photograph date; secondary periods span 1-12 days, so unphotographed rows carry no date.",
  notShipped = list(`9 females never photographed` = "known females with no sighting in the subsample",
                    `datesighted1, calfsightingdates` = "identical copies of datesighted (asserted)"))),
  taxa = taxa, periods = periods, script = "data/symons_2018_bunbury_dolphin.R")
stage_dict_row(TABLE,
  description = "Sighting histories of 91 reproductively active female Indo-Pacific bottlenose dolphins off Bunbury, Western Australia, 12 austral seasons x 6 secondary periods (Dec 2009 - Nov 2012): 0 not seen / 1 seen without calf / 2 seen with her dependent calf, 40 calves.",
  url = "https://doi.org/10.5061/dryad.6381477",
  reference = "Symons, J., Sprogis, K. R. & Bejder, L. (2018). Implications of survey effort on estimating demographic parameters of a long-lived marine top predator. Ecology and Evolution 8(21), 10470-10481.",
  doi_paper = "10.1002/ece3.4512", doi_data = "10.5061/dryad.6381477", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Calving-event file of the deposit; 40 calf codes match the paper's 40 calving events (asserted by study year). Female ids do not link to the capture-history file. Sibling of symons_2018_bunbury_dolphin_rd.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state closed robust design capture-recapture (reproductive state: with / without calf)",
  sampling_protocol = "photo_id", design = "Robust design (12 austral seasons x 6 secondary periods)", realm = "Marine",
  country = "AUS", coordinates = "None in source", notes = "Females as unit; state = seen with dependent calf; calf codes per sighting; sibling of the full capture-history table.", status = "tagged")
