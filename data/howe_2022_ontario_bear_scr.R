#!/usr/bin/env Rscript
# Table:  howe_2022_ontario_bear_scr
# Source: Dryad doi:10.5061/dryad.7wm37pvtz, version 12 (2024-06-24), licence CC0 1.0 (as shown on
#         the Dryad page; SPDX CC0-1.0). Howe, E. J. (Ontario Ministry of Natural Resources).
#         "Spatially explicit genetic capture-recapture data from black bears in Ontario, Canada".
#         The deposit is updated annually; this build reads version 12 and asserts its counts.
# Paper:  Howe, E. J., Potter, D., Beauclerc, K. B., Jackson, K. E., & Northrup, J. M. (2022).
#         Estimating animal abundance at multiple scales by spatially explicit capture-recapture.
#         Ecological Applications, 32, e2638. doi:10.1002/eap.2638 (CC BY 4.0; read via Europe PMC
#         PMC9788300). The paper analyses the 73 arrays of 2017-2019; the deposit adds 2022.
# Design (paper, README): black bear hair sampled at baited barbed-wire hair corrals (~50 cm wire,
#         meant to exclude cubs and yearlings) on curvilinear arrays of about 40 corrals ~1.5 km
#         apart along roads and trails, five consecutive weekly occasions in spring and early summer
#         (ShirleyLakeRd 2019: seven; one 2022 session: six). Arrays within a management zone sampled
#         in the same year, spaced to make detection at more than one array unlikely; the authors fit
#         SECR to each array separately and treat arrays as independent replicates. Genotyped at 15
#         microsatellite loci plus a sex marker.
# Data:   README.md; StudyAreas.csv (100 rows: capsfile, trapsfile, bears, detections, n.traps,
#           n.ocns, Year, Forest Region (boreal / GLSL), WLZ (Wildlife Landscape Zone)); per session:
#           caps_<area>_<year>.txt (session, indiv (global BLBR id), ocn, trap, sex fem/mal; two
#           files name the id column "individual"; quoted and unquoted variants) and
#           traps_<area>_<year>_Z<zone>.csv (detectorID, x, y in NAD83 UTM of the zone in the file
#           name, and where effort varied a usage column per occasion in days; 26 files have none,
#           which the README says means effort did not vary; one file names detectorID "trap").
#           Trap file names do not always match the caps file (CedarNarrow / CedarNarrows); the
#           pairing is StudyAreas.csv's. Every count in StudyAreas.csv is reproduced (asserted).
#           Quirks: the session column of caps_CCGP2022_WMU32_2022 and
#           caps_ShirleyLakeRd2022_WMU51_2022 repeats the 2017 / 2018 session name (CCGP,
#           ShirleyLakeRd), so sessions are keyed by the caps file stem; one duplicate detection row (asserted); three 2017 files
#           (81Rd, LarderRaven, GardenLkRd) write bear ids with seven digits (BLBR0000212), kept as
#           deposited (52 would equal a six-digit id elsewhere without the extra zero; not merged); one bear (BLBR000690, 700Rd) recorded
#           fem 8 times and mal once; two detections at corral-weeks whose usage is 0 days.
# Mapping (E9 experimental, closed-population genetic SCR, multi-session):
#   unit = bear within session, "<session>_<indiv>" (ruling, Ben 2026-11-14: option (a) of the
#   human_review row): each session is its own closed population, as in the authors' array-specific
#   SECR. The deposit's ids are global, and 161 bears are detected in more than one session (mostly
#   the same area in a later year; 7 in two different arrays in the same year, although the paper
#   says no genotype was found on more than one array); those are separate units here, linked only
#   by unit_bear_id. An individual is at risk only at its own session's corrals (E4.4).
#   <session> is the caps file stem (e.g. Sowden_2018, CCGP2022_WMU32_2022).
#   trap = "<session>_<detectorID>"; occasion = weekly occasion (1-7); period = sampling year
#   (2017, 2018, 2019, 2022 -> 1-4; __periods); cluster_id = session (array x year).
#   Survey evidence: effort_table. A corral-week is surveyed when its usage is > 0 days, or when the
#   trap file has no usage columns (constant effort, every corral every occasion); the two
#   detections at 0-day corral-weeks make those corral-weeks surveyed (hair was collected there).
#   Rows: every bear of a session x every surveyed corral-week of that session; y = 1 where its
#   hair was genotyped there (several samples at one corral-week are one detection; one duplicate).
#   obs_effort_days = the usage days where deposited, NA in the 26 constant-effort sessions (the
#   number of days is not given). unit_sex (NA for BLBR000690), unit_bear_id (global id),
#   unit_forest_region, unit_wlz (session-level, constant within unit).
#   __traps: x, y as deposited (NAD83 UTM, metres), utm_zone and epsg per trap (zones 15-18), session.
#   Coordinates: black bear is IUCN Least Concern; no sensitivity or private-land statement (corrals
#   near roads and trails), so as deposited.
#   Not shipped: densities (model outputs, not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "howe_2022_ontario_bear_scr"; SCRIPT <- "data/howe_2022_ontario_bear_scr.R"
dir <- download_dryad("10.5061/dryad.7wm37pvtz", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "301227"))

sa <- fread(file.path(dir, "StudyAreas.csv"), encoding = "UTF-8"); setnames(sa, 1, "index")
stopifnot(identical(names(sa), c("index", "capsfile", "trapsfile", "bears", "detections", "n.traps", "n.ocns", "Year", "Forest Region", "WLZ")),
          nrow(sa) == 100L, identical(sa$index, 1:100), all(file.exists(file.path(dir, c(sa$capsfile, sa$trapsfile)))),
          setequal(list.files(dir), c("README.md", "StudyAreas.csv", sa$capsfile, sa$trapsfile)),
          identical(sa[, .N, keyby = Year]$N, c(20L, 32L, 30L, 18L)), all(sa$`Forest Region` %in% c("boreal", "GLSL")),
          identical(sort(unique(sa$n.ocns)), 5:7), all(grepl("_Z1[5-8]\\.csv$", sa$trapsfile)))
sa[, zone := as.integer(sub(".*_Z(1[5-8])\\.csv$", "\\1", trapsfile))]

cap <- rbindlist(lapply(seq_len(nrow(sa)), function(i) {
  x <- fread(file.path(dir, sa$capsfile[i]), header = TRUE, colClasses = "character")
  stopifnot(ncol(x) == 5L, names(x)[c(1, 3:5)] == c("session", "ocn", "trap", "sex"), names(x)[2] %in% c("indiv", "individual"))
  setnames(x, c("session", "indiv", "ocn", "trap", "sex")); x[, file := i]
}))
cap[, ocn := as.integer(ocn)]
# session key = the caps file stem: two 2022 files reuse their area's first-year session name
# (CCGP, ShirleyLakeRd), against the README's naming rule
stopifnot(all(cap[, uniqueN(session), by = file]$V1 == 1L),
          identical(sort(unique(cap[, .(file, session)])[duplicated(session), session]), c("CCGP", "ShirleyLakeRd")),
          all(grepl("^BLBR[0-9]{6,7}$", cap$indiv)), all(cap$sex %in% c("fem", "mal")))
# three 2017 files write ids with seven digits (BLBR0000212); 52 of those 161 ids would equal a six-digit
# id elsewhere without the extra zero, but nothing says they are the same bears: ids kept as deposited
id7 <- unique(cap[grepl("^BLBR[0-9]{7}$", indiv), .(file, indiv)])
stopifnot(setequal(sa$capsfile[unique(id7$file)], c("caps_81Rd_2017.txt", "caps_LarderRaven_2017.txt", "caps_GardenLkRd_2017.txt")),
          uniqueN(id7$indiv) == 161L, sum(sub("^BLBR0", "BLBR", unique(id7$indiv)) %in% cap$indiv) == 52L)
chk <- cap[, .(b = uniqueN(indiv), d = .N, o = max(ocn)), keyby = file]
stopifnot(identical(chk$file, 1:100), identical(chk$b, sa$bears), identical(chk$d, sa$detections), all(chk$o <= sa$n.ocns),
          sum(sa$bears) == 4906L, sum(sa$detections) == 15556L, uniqueN(cap$indiv) == 4702L)
sa[, session := sub("^caps_(.*)\\.txt$", "\\1", capsfile)]
stopifnot(!anyDuplicated(sa$session))

trp <- rbindlist(lapply(seq_len(nrow(sa)), function(i) {
  x <- fread(file.path(dir, sa$trapsfile[i])); setnames(x, 1, "detectorID")
  stopifnot(identical(names(x)[2:3], c("x", "y")), !anyDuplicated(x$detectorID), nrow(x) == sa$n.traps[i])
  u <- setdiff(names(x), c("detectorID", "x", "y"))
  stopifnot(length(u) %in% c(0L, sa$n.ocns[i]))
  occ <- seq_len(sa$n.ocns[i])
  m <- if (length(u)) as.matrix(x[, ..u]) else matrix(NA_real_, nrow(x), length(occ))
  data.table(file = i, detectorID = rep(as.character(x$detectorID), each = length(occ)), occasion = rep(occ, nrow(x)),
             days = as.vector(t(m)), has_usage = length(u) > 0, x = rep(x$x, each = length(occ)), y = rep(x$y, each = length(occ)))
}))
sa[, file_has_usage := trp[, has_usage[1], keyby = file]$V1]
stopifnot(sum(!sa$file_has_usage) == 26L, all(trp[has_usage == TRUE, days] %in% c(0, 5:9)),
          sum(trp$days == 0, na.rm = TRUE) == 107L, all(sa[!(file_has_usage), n.ocns] == 5L))
trp[, used := !has_usage | days > 0]
# detections at deposited trap ids only; the two at 0-day corral-weeks
stopifnot(nrow(cap[!trp, on = .(file, trap = detectorID, ocn = occasion)]) == 0L)
z <- cap[trp[used == FALSE], on = .(file, trap = detectorID, ocn = occasion), nomatch = NULL]
stopifnot(nrow(z) == 2L, setequal(paste(z$session, z$indiv, z$ocn, z$trap), c("WMU50ParrySound BLBR001098 4 26", "NipissingRd BLBR004356 5 3")))
trp[z, on = .(file, detectorID = trap, occasion = ocn), used := TRUE]
# one duplicate detection row
stopifnot(sum(duplicated(cap[, .(file, indiv, ocn, trap)])) == 1L)
det <- unique(cap[, .(file, indiv, ocn, trap)])
# sex: one conflict
sx <- cap[, .(sex = if (uniqueN(sex) == 1L) sex[1] else NA_character_, n_sex = uniqueN(sex)), by = indiv]
stopifnot(sum(sx$n_sex > 1L) == 1L, sx[n_sex > 1L, indiv] == "BLBR000690",
          identical(cap[indiv == "BLBR000690", .N, keyby = .(session, sex)]$N, c(8L, 1L)))
# bears across sessions
ms <- cap[, .(n_sess = uniqueN(file), n_yr = uniqueN(sa$Year[file])), by = indiv]
stopifnot(sum(ms$n_sess > 1L) == 161L, sum(ms$n_sess > ms$n_yr) == 7L)

# ---- long table: every bear x every used corral-week of its session ----
bears <- unique(cap[, .(file, indiv)])
long <- bears[trp[used == TRUE, .(file, detectorID, occasion, days)], on = "file", allow.cartesian = TRUE]
long <- merge(long, det[, .(file, indiv, detectorID = trap, occasion = ocn, y = 1L)], by = c("file", "indiv", "detectorID", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(sum(long$y) == nrow(det), nrow(det) == 15555L,
          nrow(long) == sum(sa$bears * trp[used == TRUE, .N, keyby = file]$N))
yr_idx <- c(`2017` = 1L, `2018` = 2L, `2019` = 3L, `2022` = 4L)
long[, `:=`(session = sa$session[file], period = yr_idx[as.character(sa$Year[file])])]
long <- long[, .(unit = paste0(session, "_", indiv), taxon = "URSAME", y, trap = paste0(session, "_", detectorID),
                 period, occasion, cluster_id = session, obs_effort_days = days,
                 unit_sex = c(fem = "female", mal = "male")[sx$sex[match(indiv, sx$indiv)]], unit_bear_id = indiv,
                 unit_forest_region = sa$`Forest Region`[file], unit_wlz = sa$WLZ[file])]
long <- order_eco(long)
stopifnot(uniqueN(long$unit) == 4906L, sum(is.na(long[, unit_sex[1], by = unit]$V1)) == 1L)
cat(sprintf("  %d sessions, %d bear-sessions (%d bears), %d detections, %d rows\n", nrow(sa), uniqueN(long$unit), uniqueN(long$unit_bear_id), sum(long$y), nrow(long)))

traps <- trp[, .(x = as.numeric(x[1]), y = as.numeric(y[1]), n_occasions_used = sum(used)), keyby = .(file, detectorID)]
traps <- traps[, .(trap = paste0(sa$session[file], "_", detectorID), x, y, utm_zone = sa$zone[file], epsg = 26900L + sa$zone[file],
                   session = sa$session[file], year = sa$Year[file], n_occasions_used)]
stopifnot(nrow(traps) == sum(sa$n.traps), !anyDuplicated(traps$trap), all(traps$x > 2e5 & traps$x < 8e5), all(traps$y > 4.9e6 & traps$y < 5.8e6))
traps <- traps[trap %in% long$trap]

periods <- data.table(period = 1:4, year = c(2017L, 2018L, 2019L, 2022L),
                      n_sessions = sa[, .N, keyby = Year]$N, n_bears = sa[, sum(bears), keyby = Year]$V1,
                      season = "spring and early summer (dates not deposited)")

taxa <- make_taxa("URSAME", "Ursus americanus", vernacularName = "American black bear")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))

cite <- "Howe, E. J. (2024). Spatially explicit genetic capture-recapture data from black bears in Ontario, Canada (Version 12) [Dataset]. Dryad. https://doi.org/10.5061/dryad.7wm37pvtz"
ref <- "Howe, E. J., Potter, D., Beauclerc, K. B., Jackson, K. E., & Northrup, J. M. (2022). Estimating animal abundance at multiple scales by spatially explicit capture-recapture. Ecological Applications, 32, e2638."
n_cross <- 161L
ds <- write_table(long, TABLE, list(
  title = "Genetic spatial capture-recapture of American black bears at barbed-wire hair corrals on 100 study-area sessions across Ontario, Canada, 2017-2019 and 2022",
  creator = "Howe, Eric J.", pubDate = "2024",
  doi = "10.5061/dryad.7wm37pvtz", sourceURL = "https://doi.org/10.5061/dryad.7wm37pvtz", citation = cite,
  paperDOI = "10.1002/eap.2638",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Black bear (Ursus americanus) hair snagged at baited barbed-wire corrals (about 40 per array, ~1.5 km apart along roads and trails) on 100 array x year sessions across Ontario's bear range, sampled over five (one session six, one seven) weekly occasions in spring and early summer of 2017, 2018, 2019 and 2022 by the Ontario Ministry of Natural Resources, and genotyped to individual and sex at 15 microsatellite loci. %d bear-sessions (%d distinct bears) and %d detections. The wire height is meant to exclude cubs and yearlings. Collected to estimate local and regional bear density from spatially replicated, independently analysed SECR surveys.", uniqueN(long$unit), uniqueN(long$unit_bear_id), sum(long$y)),
  samplingProtocol = "Baited barbed-wire hair corrals (single strand ~50 cm high) in curvilinear arrays of 27-46 corrals ~1.5 km apart near roads and trails; hair collected weekly over five consecutive weeks; samples of at least five hairs genotyped at 15 microsatellite loci and a sex marker and grouped into individuals with allelematch (Howe et al. 2022).",
  samplingProtocolCode = "hair_snag", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The trap files' usage columns (days per weekly occasion) give which corrals were operated each week; a file without them has every corral operated every occasion (README). Each bear has a row at every operated corral-week of its own session. Two detections at corral-weeks with 0 days of usage make those corral-weeks operated.",
  responseType = "detection", unitKind = "individual", closure = "closed",
  closureNote = sprintf("Each session (an array in one year, cluster_id) is a closed population, as in the authors' array-specific SECR, and a bear is a unit within its session (ruling 2026-11-14): unit = <session>_<bear id>, at risk only at that session's corrals. The deposit's bear ids are global and %d bears are detected in more than one session, mostly the same area resampled in a later year and 7 at two arrays in the same year; unit_bear_id links them, but the table does not treat them as one history.", n_cross),
  occasionKind = "time", taxonInclusion = "single",
  temporalCoverage = "2017/2022 (spring and early summer; no sampling 2020-2021)",
  geographicCoverage = "Ontario, Canada, black bear range about 44 to 52 N and 72 to 96 W (UTM zones 15-18); corral coordinates in __traps",
  crs = "NAD83 / UTM zones 15N-18N (EPSG:26915-26918), as deposited: __traps gives utm_zone and epsg per trap; x and y are comparable only within a zone",
  coordinatesCoarsened = list(value = FALSE, method = "UTM metres as deposited: black bear IUCN Least Concern, no sensitivity or private-land statement in the source"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Multi-session: 100 independent arrays x years; period = year, cluster_id = session.",
  notes = "Bear BLBR000690 (700Rd, 2017) is recorded female in 8 detections and male in 1; unit_sex is NA. Three 2017 sessions (81Rd, LarderRaven, GardenLkRd) write bear ids with seven digits (BLBR0000212); they are kept as deposited, and 52 of them would equal a six-digit id of another session if the extra zero were dropped, which the source does not say to do. One detection row is duplicated in the deposit and counted once. obs_effort_days is the deposited days of operation per corral-week; it is NA in the 26 sessions whose trap files give no usage (constant effort, number of days not stated). Sessions (cluster_id, and the prefix of unit and trap) are keyed by the deposited caps file name without caps_ and .txt (e.g. Sowden_2018, CCGP2022_WMU32_2022), because two 2022 files repeat the first-year session name of their area (CCGP, ShirleyLakeRd). Resampled areas are not matched across years (OpeongoLine_2018 / Opeongo2022_WMU55A_2022). unit_wlz is the Wildlife Landscape Zone sampled.",
  notShipped = list(`density estimates` = "SECR model outputs in the paper, not deposited")),
  taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
stage_dict_row(TABLE,
  description = sprintf("Genetic spatial capture-recapture of American black bears at baited barbed-wire hair corrals on 100 array x year sessions across Ontario, 2017-2019 and 2022 (5-7 weekly occasions); %d bear-sessions of %d distinct bears, one row per bear x operated corral-week of its session, corral coordinates (UTM) in __traps.", uniqueN(long$unit), uniqueN(long$unit_bear_id)),
  url = "https://doi.org/10.5061/dryad.7wm37pvtz", reference = ref,
  doi_paper = "10.1002/eap.2638", doi_data = "10.5061/dryad.7wm37pvtz",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population genetic SCR (E9 experimental), 100 independent sessions; unit = bear within session (ruling 2026-11-14), global id in unit_bear_id. Ontario Ministry of Natural Resources.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic, multi-session)",
  sampling_protocol = "hair_snag", design = "Multi-session (100 arrays x year, 5-7 weekly occasions)", realm = "Terrestrial",
  country = "CAN", coordinates = "As published (UTM zones 15-18 in __traps)",
  notes = "Experimental (E9): trap key + __traps; bear within session as unit, global id kept.")
