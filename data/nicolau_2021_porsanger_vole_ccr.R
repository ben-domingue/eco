#!/usr/bin/env Rscript
# Table:  nicolau_2021_porsanger_vole_ccr
# Source: Dryad doi:10.5061/dryad.fj6q573rr (CC0 1.0 as shown on the dataset JSON), version 73081
#   (published 2021-07-14). Nicolau, P. G., Sørbye, S. H. & Yoccoz, N. G. Data from: Incorporating
#   capture heterogeneity in the estimation of autoregressive coefficients of animal population
#   dynamics using capture-recapture data.
# Paper:  Nicolau, P. G., Sørbye, S. H. & Yoccoz, N. G. (2020). Ecology and Evolution 10(23),
#   12710-12726, doi:10.1002/ece3.6642 (open access; read via Europe PMC PMC7713978). Section 4.1:
#   gray-sided voles captured alive at 20 stations spaced along 155 km of road in Porsanger,
#   northern Norway, 2000-2017, sampled in spring and autumn, each capture session two visits;
#   animals captured dead on the first visit were excluded; 3,090 voles analysed.
# Data:   Read_ME_general.txt; Vole_dataset.zip (unzipped here) holding
#           Dataset/vole_data_porsanger_2000-2017.csv: semicolon-separated, decimal comma, 3,145
#             rows, one per vole and capture session: year, seas (SPRING / FALL), timepoint (1..36,
#             the session in time order, two per year), station ("1".."20" and "8B"), ID (unique
#             per row: the Dryad usage notes say animals caught at different time points are
#             assumed to be different animals), c1 / c2 (captured on visit 1 / 2; never both 0),
#             weight (mean of the two visits' weights, g; NA on some), sex (F / M, NA on 52).
#           Dataset/Read_ME_metadata.txt: the variables and the station coordinates (UTM zone 33,
#             northing then easting) for S1-S8 and S10-S20; S9 and 8B have none.
#           Data Analysis/: the authors' processing and INLA code and two .rds files derived from
#             the csv (counts per station x timepoint, and the INLA multinomial frame).
#         AR2-Simulation-code.zip: simulation code, no data.
# Mapping (closed-population capture-recapture, multi-session; responseType detection,
#   unitKind individual): unit = the deposit's ID (one vole in one session), taxon = MYORUF,
#   period = timepoint (session 1..36), occasion = visit 1 / 2, y = c1 / c2, cluster_id = station
#   (each station x session is its own closed population in the paper). Two rows per vole.
#   At-risk span (E4.4): identities are not linked across sessions (the source treats animals in
#   different sessions as different; no ID recurs, asserted), so a vole has rows only in its own
#   session, as in broekhuis_2020_mara_cheetah_scr. Within the session it was at risk on both
#   visits. Survey evidence = row_presence: the deposit is the capture record, every row is an
#   animal caught at least once, and both visits of every session are recorded.
#   Covariates: unit_sex, unit_weight_g (mean over the visits, as deposited), unit_x / unit_y
#   (station UTM 33N easting / northing from the readme; NA at stations 9 and 8B). Season and
#   year are __periods facts.
#   Coordinates: the gray-sided vole is IUCN LC, not flagged; station coordinates kept as the
#   readme gives them.
# Not shipped: countdata.rds and data4inla.rds (derived from the csv by the authors' script);
#   the simulation code. Station x session combinations with no capture are not in the deposit,
#   so whether a station was trapped and caught nothing, or not trapped, is not recorded; the
#   authors' countdata.rds fills them with 0, which this table does not (no animal, no row).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "nicolau_2021_porsanger_vole_ccr"
dir <- download_dryad("10.5061/dryad.fj6q573rr", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
vz <- file.path(dir, "Vole_dataset")
if (!dir.exists(vz)) unzip(file.path(dir, "Vole_dataset.zip"), exdir = vz)
f <- file.path(vz, "Vole dataset", "Dataset", "vole_data_porsanger_2000-2017.csv")
rm_f <- file.path(vz, "Vole dataset", "Dataset", "Read_ME_metadata.txt")
stopifnot(file.exists(f), file.exists(rm_f))

d <- fread(f, sep = ";", dec = ",", colClasses = list(character = c("station", "seas", "sex")))
setnames(d, 1, "row")
stopifnot(identical(names(d), c("row", "year", "seas", "timepoint", "station", "ID", "c1", "c2", "weight", "sex")),
          nrow(d) == 3145L, !anyDuplicated(d$ID), all(d$c1 %in% 0:1), all(d$c2 %in% 0:1), all(d$c1 + d$c2 >= 1L),
          all(d$seas %in% c("SPRING", "FALL")), all(d$timepoint %in% 1:36), all(d$year %in% 2000:2017),
          setequal(d$station, c(as.character(1:20), "8B")), sum(is.na(d$sex)) == 52L, all(d$sex %in% c("F", "M", NA)),
          sum(d$c1 == 1 & d$c2 == 1) == 1035L, sum(d$c1 == 1 & d$c2 == 0) == 713L, sum(d$c1 == 0 & d$c2 == 1) == 1397L)
# timepoint is the session in time order: spring then autumn of each year
tp <- unique(d[, .(timepoint, year, seas)])
stopifnot(nrow(tp) == 36L, !anyDuplicated(tp$timepoint),
          all(tp$timepoint == 2L * (tp$year - 2000L) + ifelse(tp$seas == "SPRING", 1L, 2L)))

# station coordinates from the readme (UTM zone 33: northing, easting)
rl <- grep("^S[0-9]+\\s", readLines(rm_f, warn = FALSE), value = TRUE)
st <- rbindlist(lapply(strsplit(trimws(rl), "\\s+"), function(z) data.table(station = sub("^S", "", z[1]), north = as.numeric(z[2]), east = as.numeric(z[3]))))
stopifnot(nrow(st) == 19L, setequal(st$station, setdiff(as.character(1:20), "9")),
          all(st$north %between% c(7.7e6, 7.9e6)), all(st$east %between% c(8.4e5, 9.2e5)))
d <- merge(d, st, by = "station", all.x = TRUE, sort = FALSE)
stopifnot(identical(sort(unique(d[is.na(north)]$station)), c("8B", "9")))

long <- rbindlist(lapply(1:2, function(k) d[, .(unit = as.character(ID), taxon = "MYORUF", y = if (k == 1L) c1 else c2,
  period = timepoint, occasion = k, cluster_id = station, unit_sex = sex, unit_weight_g = weight,
  unit_x = east, unit_y = north)]))
long <- order_eco(long)
stopifnot(nrow(long) == 2L * 3145L, sum(long$y) == 1748L + 2432L, all(long[, sum(y), by = unit]$V1 >= 1L),
          all(long[, uniqueN(period), by = unit]$V1 == 1L))
cat(sprintf("  %d voles x 2 visits = %d rows, %d captures, %d station-sessions\n",
            uniqueN(long$unit), nrow(long), sum(long$y), uniqueN(long[, .(cluster_id, period)])))

taxa <- make_taxa("MYORUF", "Myodes rufocanus", vernacularName = "Gray-sided vole")
periods <- tp[order(timepoint), .(period = timepoint, year, season = tolower(seas))]
periods[season == "fall", season := "autumn"]

dataset <- list(
  title = "Two-visit live-trapping capture-recapture of gray-sided voles at 21 stations in Porsanger, northern Norway, spring and autumn 2000-2017",
  creator = "Nicolau, Pedro G.; Sørbye, Sigrunn H.; Yoccoz, Nigel G.",
  pubDate = "2021", doi = "10.5061/dryad.fj6q573rr", sourceURL = "https://doi.org/10.5061/dryad.fj6q573rr",
  citation = "Nicolau, P. G., Sørbye, S. H., & Yoccoz, N. G. (2021). Data from: Incorporating capture heterogeneity in the estimation of autoregressive coefficients of animal population dynamics using capture-recapture data [Dataset]. Dryad. https://doi.org/10.5061/dryad.fj6q573rr",
  paperDOI = "10.1002/ece3.6642",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Gray-sided voles (Myodes rufocanus) live-trapped at stations along 155 km of road in Porsanger, Finnmark, Norway, in spring and autumn of every year from 2000 to 2017 (36 sessions). Each capture session has two visits; each row of the deposit is a vole with its two-visit capture history, sex and mean weight. The paper estimates individual capture probabilities with a heterogeneity model and Horvitz-Thompson abundance per station and session, then fits autoregressive models of population dynamics.",
  samplingProtocol = "Live trapping at fixed stations spaced along a road, two capture visits per session, sessions in spring and autumn; voles identified within a session, weighed and sexed; animals dead on the first visit excluded by the authors.",
  samplingProtocolCode = "live_trap", surveyEvidence = "row_presence",
  responseType = "detection", unitKind = "individual",
  closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "each station x session is a closed population over its two visits (the paper's model); identities are not linked across sessions, so a vole has rows only in its own session",
  geographicCoverage = "Porsanger, Finnmark, northern Norway (about 70 N, 25 E), stations from Lillefjord to Karasjok",
  temporalCoverage = "2000/2017",
  crs = "UTM zone 33 metres as the deposited readme states (northing and easting; datum not stated, ETRS89 / WGS 84 UTM 33N assumed): unit_x = easting, unit_y = northing",
  coordinatesCoarsened = list(value = FALSE, method = "Station coordinates kept as the readme gives them (gray-sided vole IUCN LC, not flagged); stations 9 and 8B have no coordinates in the deposit"),
  designNote = "Multi-session closed capture-recapture: cluster_id = station, period = session (spring / autumn), occasion = visit. Each vole id exists in one session only; station x session is the closed population.",
  notShipped = list(derived_rds = "countdata.rds (captures per station x session, zeros filled for every combination) and data4inla.rds (the INLA multinomial frame), both derived from the csv by the authors' script",
                    simulation_code = "AR2-Simulation-code.zip (no data)"),
  notes = "Station x session combinations with no capture are not in the deposit: such a session has no rows, and the table cannot say whether the station was trapped. Station 8B (3 voles, session 2) and station 9 (sessions 3-8) are as deposited and have no coordinates; the paper speaks of 20 stations. 52 voles have no sex (the paper excluded them, leaving 3,093 of which it reports 3,090). unit_weight_g is the mean of the visits' weights, as deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/nicolau_2021_porsanger_vole_ccr.R")

stage_dict_row(TABLE,
  description = "Two-visit live-trapping capture histories of 3,145 gray-sided voles (Myodes rufocanus) at 21 roadside stations in Porsanger, northern Norway, in 36 spring and autumn sessions, 2000-2017, with sex, weight and station coordinates; each station x session a closed population.",
  url = "https://doi.org/10.5061/dryad.fj6q573rr",
  reference = "Nicolau, P. G., Sørbye, S. H., & Yoccoz, N. G. (2020). Incorporating capture heterogeneity in the estimation of autoregressive coefficients of animal population dynamics using capture-recapture data. Ecology and Evolution, 10(23), 12710-12726.",
  doi_paper = "10.1002/ece3.6642", doi_data = "10.5061/dryad.fj6q573rr",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-session closed CR (cluster_id station, period session, occasion visit); session-scoped ids; zero-capture station-sessions not in the deposit.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Closed-population capture-recapture (multi-session, two visits)",
  sampling_protocol = "live_trap", design = "Multi-season (36 spring and autumn sessions, 2000-2017; 2 visits per session; 21 stations)",
  realm = "Terrestrial", country = "NOR", coordinates = "As published",
  notes = "Rodent cycle time series at the station level; session-scoped ids.")
