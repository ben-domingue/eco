#!/usr/bin/env Rscript
# Table:  letourneux_2022_snowgoose_ms
# Source: Dryad, doi:10.5061/dryad.j6q573nh4, version 189196 (version 2, published 2022-07-26), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON).
#   LeTourneux, F., Gauthier, G., Pradel, R., Lefebvre, J. & Legagneux, P. (2022). Evidence for synergistic cumulative
#   impacts of marking and hunting in a wildlife species [Dataset]. Dryad.
# Paper:  LeTourneux, F., Gauthier, G., Pradel, R., Lefebvre, J. & Legagneux, P. (2022). Evidence for synergistic
#         cumulative impacts of marking and hunting in a wildlife species. Journal of Applied Ecology.
#         doi:10.1111/1365-2664.14268. Not supplied; everything below is from the deposit (the Dryad abstract,
#         methods and the two READMEs): >20,000 adult female greater snow geese (Anser caerulescens atlantica)
#         marked with a leg ring alone or a leg ring and a neck collar, 30 yearly occasions 1990-2019, multievent
#         models in E-SURGE partitioning hunting from non-hunting mortality.
# Data:   capture_histories.txt (E-SURGE / Biomeco format): line 1 "2396 31" (unique histories, columns), two "$"
#           lines, then 2396 unique histories: 30 yearly occasions 1990-2019 coded 0 = not observed, 1 = physical
#           recapture of a bird with a leg ring only, 2 = physical recapture or distant observation (resighting) of a
#           bird wearing a leg ring and a collar, 3 = recovery of a dead bird hunted in the interval before the
#           occasion; column 31 = number of birds sharing the history (22,599 birds). The authors removed about 200
#           histories with errors (birds seen before marking, observations after a dead recovery).
#         README_capture_histories.txt (the format, as above).
#         harvest_rate_covariate.txt (E-SURGE external variable): "1", "29", then 29 standardised yearly harvest
#           rates of greater snow geese in Canada and the USA, one per interval between occasions (1990-91 to
#           2018-19), computed by the paper's Appendix 2. README_harvest_rate_covariate.txt.
# Mapping (multi-state capture-recapture with dead recoveries; responseType state, unitKind individual):
#   unit = one bird ("SG00001"..; the deposit's histories expanded by their frequency, in deposit order), taxon =
#   ANSCAA, period = occasion 1..30 (__periods: year 1990..2019), y = the deposited code (stateCodes 0-3).
#   At-risk span (E4.4): adults of unknown age caught in the wild, so every bird has rows from period 1 (1990):
#   y = 0 before the marking occasion; the first non-zero code is the marking (E-SURGE histories begin at release;
#   obs_marking = 1 on that row). A dead recovery (3) ends the history: no rows after it, and obs_removed = 1 on
#   that row (the bird is dead). 344 birds (273 histories) go from 2 to 1: the collar was lost but the leg ring
#   kept, so the bird stays identifiable and its rows continue; the code is shipped as recorded. No bird goes from
#   1 to 2 (asserted). unit_mark_group = "collar" / "leg_ring": the marker at marking (the first code), constant
#   within bird by construction; it is not the marker at every later occasion (collar loss).
#   surveyEvidence = deposited_matrix: every history cell is a yearly occasion of the programme (no missing code).
#   __periods: year. The deposited standardised harvest rate is NOT shipped: it was computed by the paper's
#   Appendix 2 (not supplied), and harvest rates for this population are commonly estimated from recoveries of
#   the same marked birds, so it may be a model output of these histories; it can be added if Appendix 2 shows
#   it comes from separate harvest and population surveys.
# Not shipped: the authors' survival, hunting and non-hunting mortality estimates (model output). The marking
#   location is not stated in the deposit; no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "letourneux_2022_snowgoose_ms"
dir <- download_dryad("10.5061/dryad.j6q573nh4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "189196"),
          setequal(list.files(dir), c("README_capture_histories.txt", "harvest_rate_covariate.txt", "capture_histories.txt",
                                      "README_harvest_rate_covariate.txt")))
f <- file.path(dir, "capture_histories.txt")
hd <- readLines(f, n = 3L)
stopifnot(identical(trimws(hd), c("2396 31", "$", "$")))
x <- fread(f, skip = 3L, header = FALSE)
stopifnot(nrow(x) == 2396L, ncol(x) == 31L, !anyDuplicated(x[, 1:30]))
H <- as.matrix(x[, 1:30]); n <- x$V31
stopifnot(all(H %in% 0:3), all(n >= 1L), sum(n) == 22599L, all(rowSums(H > 0) >= 1L))
first <- apply(H > 0, 1, function(r) which(r)[1])
fcode <- H[cbind(seq_len(nrow(H)), first)]
stopifnot(all(fcode %in% 1:2), sum(n[fcode == 1L]) + sum(n[fcode == 2L]) == 22599L)
# a dead recovery occurs at most once and nothing follows it
dpos <- apply(H, 1, function(r) { w <- which(r == 3L); if (length(w)) w[1] else NA_integer_ })
after3 <- vapply(seq_len(nrow(H)), function(i) !is.na(dpos[i]) && dpos[i] < 30L && any(H[i, (dpos[i] + 1L):30] > 0L), logical(1))
stopifnot(all(rowSums(H == 3L) <= 1L), !any(after3),
          all(is.na(dpos) | dpos > first), sum(n[!is.na(dpos)]) == 4892L)
# collar loss: 2 then 1 in 273 histories (344 birds); never 1 then 2
has12 <- apply(H, 1, function(r) any(r == 1L) && any(r == 2L))
stopifnot(sum(has12) == 273L, sum(n[has12]) == 344L,
          all(apply(H[has12, , drop = FALSE], 1, function(r) max(which(r == 2L)) < min(which(r == 1L)))))

# expand to birds; rows from period 1 to 30, or to the dead recovery
idx <- rep(seq_len(nrow(H)), n)
last <- ifelse(is.na(dpos), 30L, dpos)
long <- data.table(h = rep(idx, last[idx]), period = unlist(lapply(last[idx], seq_len)))
long[, unit := rep(sprintf("SG%05d", seq_along(idx)), last[idx])]
long[, y := H[cbind(h, period)]]
long[, `:=`(obs_marking = as.integer(period == first[h]), obs_removed = as.integer(y == 3L),
            unit_mark_group = c("leg_ring", "collar")[fcode[h]], taxon = "ANSCAA")]
long[, h := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == sum(n * last), uniqueN(long$unit) == 22599L, !anyDuplicated(long[, .(unit, period)]),
          sum(long$obs_marking) == 22599L, sum(long$y == 3L) == 4892L, sum(long$obs_removed) == 4892L,
          sum(long$y == 1L) == sum(n * rowSums(H == 1L)), sum(long$y == 2L) == sum(n * rowSums(H == 2L)),
          long[, uniqueN(unit_mark_group), by = unit][, all(V1 == 1L)])
cat(sprintf("  %d rows, %d birds (%d collared at marking), %d encounters alive, %d dead recoveries\n", nrow(long),
            uniqueN(long$unit), long[obs_marking == 1L, sum(unit_mark_group == "collar")], sum(long$y %in% 1:2), sum(long$y == 3L)))

hr <- readLines(file.path(dir, "harvest_rate_covariate.txt"))
stopifnot(trimws(hr[1]) == "1", trimws(hr[2]) == "29")
hv <- as.numeric(strsplit(trimws(hr[3]), "\\s+")[[1]])
stopifnot(length(hv) == 29L, !anyNA(hv), abs(mean(hv)) < 0.01, abs(sd(hv) - 1) < 0.05)
stopifnot(length(hv) == 29L)
periods <- data.table(period = 1:30, year = 1990:2019)

taxa <- make_taxa("ANSCAA", "Anser caerulescens atlantica", vernacularName = "Greater snow goose", taxonRank = "subspecies",
                  lookupName = "Anser caerulescens atlanticus",
                  taxonRemarks = "source name Anser caerulescens atlantica; GBIF backbone spelling atlanticus (gender agreement)")

dataset <- list(
  title = "Multi-state capture, resighting and dead-recovery histories of 22,599 adult female greater snow geese marked with leg rings or leg rings and neck collars, 1990-2019",
  creator = "LeTourneux, Frédéric; Gauthier, Gilles; Pradel, Roger; Lefebvre, Josée; Legagneux, Pierre", pubDate = "2022",
  doi = "10.5061/dryad.j6q573nh4", sourceURL = "https://doi.org/10.5061/dryad.j6q573nh4",
  citation = "LeTourneux, F., Gauthier, G., Pradel, R., Lefebvre, J., & Legagneux, P. (2022). Evidence for synergistic cumulative impacts of marking and hunting in a wildlife species [Dataset]. Dryad. https://doi.org/10.5061/dryad.j6q573nh4",
  paperDOI = "10.1111/1365-2664.14268",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Adult female greater snow geese were marked with a leg ring alone or with a leg ring and a neck collar over 30 years (1990-2019) while hunting regulations were liberalised twice (spring hunt from 1999, winter hunt from 2009). Each yearly occasion records a physical recapture of a leg-ringed bird, a recapture or resighting of a collared bird, or the recovery of a bird shot in the preceding interval. The authors fit multievent models in E-SURGE to compare survival with and without collars and to partition hunting from non-hunting mortality.",
  samplingProtocol = "Long-term marking programme: adult females caught and marked with a metal leg ring or a leg ring plus a coded neck collar; yearly occasions pool physical recaptures, distant resightings of collars and hunter recoveries of dead birds.",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not observed",
                    `1` = "physical recapture of a bird with a leg ring only (also the marking of a bird ringed without a collar)",
                    `2` = "physical recapture or distant resighting of a bird with a leg ring and a neck collar (also the marking of a collared bird)",
                    `3` = "recovery of a dead bird hunted in the interval before the occasion (ends the history; obs_removed = 1)"),
  closure = "none", closureNote = "one yearly occasion per period; recaptures, resightings and recoveries within a year pooled by the authors",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Greater snow goose population of eastern North America (harvested in Canada and the USA); the marking location is not stated in the deposit; no coordinates",
  temporalCoverage = "1990/2019",
  covariateNote = "unit_mark_group: marker at marking (leg_ring or collar), from the first code; a collared bird can later lose the collar (code 2 then 1). obs_marking: 1 on the marking row. obs_removed: 1 on a dead-recovery row.",
  notShipped = list(model_output = "the authors' survival and cause-specific mortality estimates", harvest_rate = "harvest_rate_covariate.txt: 29 standardised yearly harvest rates computed by the paper's Appendix 2 (not supplied); not shipped because it may be estimated from recoveries of these same birds (a model output); add if Appendix 2 shows an independent source"),
  notes = "Histories expanded from the deposit's unique histories x frequency; unit ids are sequential in deposit order. Every bird has rows from 1990 (wild adults of unknown age, E4.4), y = 0 before its marking row (obs_marking = 1). A dead recovery (y = 3) ends the history. 344 birds marked with collars were later seen with the leg ring only (collar lost); their rows continue. The authors removed about 200 histories with errors before deposit. The paper was not read; the design is from the deposit's metadata.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/letourneux_2022_snowgoose_ms.R")
stage_dict_row(TABLE,
  description = "Multi-state recapture, collar resighting and hunter dead-recovery histories of 22,599 adult female greater snow geese marked with or without neck collars, 30 yearly occasions 1990-2019.",
  url = "https://doi.org/10.5061/dryad.j6q573nh4",
  reference = "LeTourneux, F., Gauthier, G., Pradel, R., Lefebvre, J., & Legagneux, P. (2022). Evidence for synergistic cumulative impacts of marking and hunting in a wildlife species. Journal of Applied Ecology. https://doi.org/10.1111/1365-2664.14268",
  doi_paper = "10.1111/1365-2664.14268", doi_data = "10.5061/dryad.j6q573nh4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "E-SURGE unique histories expanded by frequency; dead recovery ends the history; histories padded to 1990 (E4.4).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state capture-recapture with dead recoveries (multievent)",
  sampling_protocol = "live_trap", design = "Multi-season (30 yearly occasions, 1990-2019)",
  realm = "Terrestrial", country = "CAN,USA", coordinates = "None in source",
  notes = "Marker effect (neck collar vs leg ring) under changing hunting regulations; hunter recoveries as state 3.")
