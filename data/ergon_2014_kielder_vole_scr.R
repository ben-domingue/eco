#!/usr/bin/env Rscript
# Table:  ergon_2014_kielder_vole_scr
# Source: Dryad doi:10.5061/dryad.r17n5, version 15883, licence CC0 1.0 (as shown on Dryad and
#         in the DataCite record). Ergon, T. & Gardner, B. "Data from: Separating mortality and
#         emigration: modelling space use, dispersal and survival with robust-design spatial
#         capture-recapture data" (deposited 2013). The same data are openCR::fieldvoleCH (GPL);
#         the deposit is built instead because it is the authors' own release under CC0.
# Paper:  Ergon, T. & Gardner, B. (2014). Separating mortality and emigration: modelling space
#         use, dispersal and survival with robust-design spatial capture-recapture data. Methods
#         in Ecology and Evolution 5, 1327-1336. doi:10.1111/2041-210X.12133 (Appendix S2, with
#         the field details, not read; design below from the README and the openCR help page).
# Data:   README_for_ErgonAndGardner2013.txt and ErgonAndGardner2013.rdat, an R list written by
#         dput(). It is read by parsing the file and evaluating the single expression in an
#         environment that holds only structure(), list(), c() and `:` (asserted to be the only
#         functions it calls), not with dget(). Elements: N = c(8, 158) (individuals seen only in
#         their last primary session; total), n.prim = 4 primary sessions, dt = interval lengths
#         (months of 30 days), tod[k, j] = time of day of secondary session j of primary k (1
#         evening, 2 morning; NA where the session does not exist: 3, 5, 4, 5 sessions), first[i]
#         = first primary session, K[i] = last primary session (censored animals), J[i, k] = last
#         secondary session of i in k, gr[i] = sex (1 female, 2 male), R = 192 traps, X[r, ] = trap
#         x, y (m), H[i, j, k] = trap of capture + 1 (1 = not captured). Individuals are named by
#         their tag codes. Field voles (Microtus agrestis) in a clearcut in Kielder Forest,
#         northern England, June-August 2000: a grid of 192 multi-catch Ugglan traps at 7 m, four
#         primary sessions 21-23 days apart, traps checked about every 12 h (openCR help page).
#         Adults only (118 females, 40 males). Five voles died in traps; their histories end at
#         that capture (K, J).
# Mapping (standard E9 experimental, spatial capture-recapture; responseType detection, unitKind
#   individual): unit = tag code, taxon = MICAGR, trap = T001..T192, period = primary session
#   1-4, occasion = trap check within it, y = 1 if caught in that trap at that check.
#   obs_time_of_day (evening, morning); obs_removed = 1 on the capture at which a vole died.
#   At-risk span (E4.4): adults of unknown age, so from primary session 1, at all 192 traps on
#   every check, to the end of the study or to the check at which the vole died (J, K).
#   Survey evidence = inferred: trap operation is not deposited; every trap is taken as set at
#   every check, as the authors' model assumes. Coordinates: local metres on the grid, as
#   deposited; Microtus agrestis is IUCN Least Concern.
#   Not shipped: N and dt (derivable: N from the histories, dt from the session dates, which are
#   not deposited beyond the interval lengths; dt goes to __periods as interval_months).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ergon_2014_kielder_vole_scr"
dir <- download_dryad("10.5061/dryad.r17n5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "15883"),
          setequal(list.files(dir), c("ErgonAndGardner2013.rdat", "README_for_ErgonAndGardner2013.txt")))
ex <- parse(file.path(dir, "ErgonAndGardner2013.rdat"))
stopifnot(length(ex) == 1L,
          setequal(setdiff(all.names(ex[[1]]), all.vars(ex[[1]])), c("structure", "list", "c", ":")))
d <- eval(ex[[1]], list2env(list(structure = base::structure, list = base::list, c = base::c, `:` = base::`:`), parent = emptyenv()))
H <- d$H; ids <- dimnames(H)[[1]]
nsec <- c(3L, 5L, 4L, 5L)
stopifnot(identical(d$N, c(8L, 158L)), d$n.prim == 4L, d$R == 192L, identical(dim(H), c(158L, 5L, 4L)),
          identical(as.vector(table(d$gr)), c(118L, 40L)), identical(names(d$gr), ids), identical(dimnames(d$J)[[1]], ids),
          identical(as.integer(colSums(!is.na(t(d$tod)))), nsec), all(d$tod %in% c(1, 2, NA)),
          all(H >= 1 & H <= 193), identical(dim(d$X), c(192L, 2L)), !anyDuplicated(ids),
          all(sapply(1:4, function(k) all(H[, seq_len(5) > nsec[k], k] == 1))))   # nothing in sessions that did not happen
K <- as.integer(d$K); J <- d$J
cens <- which(K < 4L | J[cbind(seq_along(K), K)] < nsec[K])
stopifnot(length(cens) == 5L, setequal(ids[cens], c("ma193", "ma239", "ma371", "ma143", "ma348")),
          all(H[cbind(cens, J[cbind(cens, K[cens])], K[cens])] > 1))               # each censored vole was caught at its last check
# no capture after a vole's last check
stopifnot(all(sapply(seq_along(ids), function(i) {
  ok <- TRUE
  for (k in 1:4) for (j in seq_len(nsec[k])) if (k > K[i] || (k == K[i] && j > J[i, k])) ok <- ok && H[i, j, k] == 1
  ok })))
sv <- rbindlist(lapply(1:4, function(k) data.table(period = k, occasion = seq_len(nsec[k]), tod = d$tod[k, seq_len(nsec[k])])))
long <- rbindlist(lapply(seq_along(ids), function(i) {
  s <- sv[period < K[i] | (period == K[i] & occasion <= J[i, K[i]])]
  r <- CJ(trap = 1:192, row = seq_len(nrow(s)))
  r[, `:=`(period = s$period[row], occasion = s$occasion[row], tod = s$tod[row])]
  r[, y := as.integer(H[cbind(i, occasion, period)] == trap + 1L)]
  r[, obs_removed := as.integer(i %in% cens & period == K[i] & occasion == J[i, K[i]] & y == 1L)]
  r[, unit := ids[i]]
  r
}))
stopifnot(sum(long$y) == sum(H > 1), sum(long$obs_removed) == 5L)
long <- long[, .(unit, taxon = "MICAGR", y, trap = sprintf("T%03d", trap), period, occasion,
                 unit_sex = c("F", "M")[d$gr[unit]], obs_time_of_day = c("evening", "morning")[tod], obs_removed)]
long <- order_eco(long)
traps <- data.table(trap = sprintf("T%03d", 1:192), x = as.numeric(d$X[, 1]), y = as.numeric(d$X[, 2]), n_occasions_used = sum(nsec))
periods <- data.table(period = 1:4, n_checks = nsec, interval_months_to_next = c(d$dt, NA),
                      n_caught = sapply(1:4, function(k) sum(apply(H[, , k] > 1, 1, any))))
taxa <- make_taxa("MICAGR", "Microtus agrestis", vernacularName = "Field vole", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Robust-design spatial capture-recapture of 158 adult field voles on a 192-trap grid in Kielder Forest, England, June-August 2000",
  creator = "Ergon, Torbjørn; Gardner, Beth", pubDate = "2013", doi = "10.5061/dryad.r17n5", sourceURL = "https://doi.org/10.5061/dryad.r17n5",
  citation = "Ergon, T., & Gardner, B. (2013). Data from: Separating mortality and emigration: modelling space use, dispersal and survival with robust-design spatial capture-recapture data [Dataset]. Dryad. https://doi.org/10.5061/dryad.r17n5",
  paperDOI = "10.1111/2041-210X.12133",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Adult field voles (Microtus agrestis) live-trapped on a grid of 192 multi-catch traps at 7-m spacing in a clearcut in Kielder Forest, northern England, in four primary sessions 21-23 days apart between 10 June and 15 August 2000, with traps checked about every 12 hours (3, 5, 4 and 5 checks). The authors used the data to separate mortality from emigration with robust-design spatial capture-recapture. One row per vole x trap x check while at risk, with sex and the time of day of the check; five voles died in traps.",
  samplingProtocol = "Ugglan Special multi-catch live traps baited with barley and carrot on a 192-trap grid (7 m), checked at about 06:00 and 18:00; voles ear-tagged; four primary sessions in summer 2000.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap operation is not deposited. Every trap is taken as set at every check of every primary session (3, 5, 4, 5 checks, from the deposited time-of-day matrix), as the authors' RD-SCR model assumes. Each vole has rows at all 192 traps for every check from the first primary session to the end, or to the check at which it died.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (robust design: closed within a primary session, open between)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  geographicCoverage = "A clearcut in Kielder Forest, Northumberland, England (about 55.2 N, 2.6 W); trap coordinates in __traps are local grid metres",
  temporalCoverage = "2000-06-10/2000-08-15", crs = "local grid metres (as deposited)",
  coordinatesCoarsened = list(value = FALSE, method = "local grid coordinates as deposited; Microtus agrestis is IUCN Least Concern"),
  designNote = "Experimental list of E9: robust-design spatial capture-recapture with a trap key and __traps. Five voles that died in traps have obs_removed = 1 on that capture and no later rows.",
  notes = "Adults only, as deposited (118 females, 40 males; the paper's selection); captures of a vole before it was classed adult may not be in the deposit (Appendix S2 not read), so rows before an adult's first capture rest on E4.4's unknown-age rule. The same data are openCR::fieldvoleCH. obs_time_of_day from the deposit's tod (1 evening, 2 morning). Unit ids are the deposit's tag codes.",
  notShipped = list(N = "counts derivable from the histories", dt = "interval lengths between primary sessions, shipped in __periods as interval_months_to_next"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = "data/ergon_2014_kielder_vole_scr.R")
stage_dict_row(TABLE,
  description = "Robust-design spatial capture-recapture histories of 158 adult field voles on a 192-trap grid in Kielder Forest, England, four primary sessions of 3-5 trap checks, June-August 2000, with sex and five deaths in traps.",
  url = "https://doi.org/10.5061/dryad.r17n5",
  reference = "Ergon, T., & Gardner, B. (2014). Separating mortality and emigration: modelling space use, dispersal and survival with robust-design spatial capture-recapture data. Methods in Ecology and Evolution, 5, 1327-1336.",
  doi_paper = "10.1111/2041-210X.12133", doi_data = "10.5061/dryad.r17n5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Robust-design SCR (E9 experimental). Survey set inferred (all traps at all checks). Deposit is an R dput file, read by safe parsing. Same data as openCR::fieldvoleCH.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (robust design, open)",
  sampling_protocol = "live_trap", design = "Robust design (4 primary sessions x 3-5 checks)", realm = "Terrestrial",
  country = "GBR", coordinates = "As published (local grid metres, in __traps)",
  notes = "Experimental (E9): trap key + __traps. Deaths in traps as obs_removed. Survey set inferred.")
