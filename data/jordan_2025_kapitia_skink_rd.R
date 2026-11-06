#!/usr/bin/env Rscript
# Table:  jordan_2025_kapitia_skink_rd
# Source: Dryad doi:10.5061/dryad.bvq83bkkh, version 3 (2025-01-30), CC0 1.0 as shown on the
#         Dryad record. "Data from: Supplementing human observation with artificial
#         intelligence impacts demographic estimates for a Critically Endangered lizard."
# Paper:  Jordan, E. A., Ewen, J., Hitchmough, R., Moran, L. R., Murrell, D. J., Rowcliffe,
#         J. M. & Adams, L. K. (2025). Supplementing human observation with artificial
#         intelligence impacts demographic estimates for a critically endangered lizard.
#         Ecological Solutions and Evidence, doi:10.1002/2688-8319.70018.
#         p. 3, s. 2.2: robust design; five primary periods 2019-2021 after cyclone Fehi (2018),
#           each spanning 12 days, 2-10 months apart; "Either 10 or 11 surveys (secondary
#           occasions) were conducted within each primary sampling period"; at each survey
#           every artificial cover object (ACO) was checked, skinks caught, photographed (left
#           side) and released; identification by scale pattern.
#         p. 3-4, s. 2.3: two identification sets from the same photographs: human-only
#           (catalogue matched by four surveyors) and AI-supplemented (HotSpotter candidate
#           matches reviewed by a researcher); every image on which they disagreed was
#           re-inspected to give a "Verified data set".
#         p. 4, s. 3.1 and Table 1: human-only 402 individuals, AI-supplemented 360; "The
#           verified data set inferred that our true sample consisted of 360 individuals";
#           AI-supplemented FAR = FRR = 0, human-only FRR = 0.17 (42 recaptured animals
#           assigned as new individuals). p. 6, s. 4: the authors recommend the
#           AI-supplemented estimates for the species' conservation.
#         p. 5, Table 3: primaries in January 2019, March 2019, January 2020, November 2020
#           and February 2021.
# Data:   Four MARK .inp files (CRLF), "/* id */ history 1;", ids integers plus one "578A":
#           AI_SupplementedEncounterHistory.inp: 360 skinks x 52 secondary occasions, 793
#             captures; every column has a capture; no all-zero history.
#           AI_SupplementedEncounterHistory_Collapsed.inp: the same 360 ids, 5 characters, one
#             per primary (for RELEASE goodness-of-fit tests).
#           HumanOnlyEncounterHistory.inp (390 skinks, 792 captures) and its _Collapsed twin.
#         The split of the 52 secondaries into primaries is not in the deposit; the paper says
#         10 or 11 each (so two primaries have 11). Of the ten such splits only 10, 10, 11, 10,
#         11 reproduces the collapsed files exactly (for both sets; asserted), so that is the
#         split, and the collapsed files are recodes of the full ones (rebuilt and asserted
#         identical: shipped once, as the full histories).
#
# Mapping (robust design, standard E9; responseType detection, unitKind individual):
#   unit = skink (S + MARK id) of the AI-supplemented set, taxon = OLISAL, period = primary
#   (1-5), occasion = survey (secondary) within the primary (1-10 or 1-11), y = captured.
#   Which set ships: the two sets are two identifications of the same photographs, not a
#   recode of one another (they cannot be rebuilt from each other: 2 AI ids are not in the
#   human-only file, 32 human-only ids are not in the AI file, and 31 shared ids have
#   different histories). The paper presents the AI-supplemented set as the corrected
#   identities (360 individuals, equal to the Verified set, no false rejections), so it
#   ships; the human-only set is recorded in notShipped (a question for Ben: second table
#   or not).
#   surveyEvidence = deposited_matrix: every one of the 52 secondaries is a survey (each has
#   a capture; the paper reports 10 or 11 surveys per primary). At-risk span (E4.4): skinks
#   are wild-caught with age unknown (no age or size deposited), so every skink is at risk
#   from the first primary: full 360 x 52 rectangle, zeros before first capture included.
#   No removals deposited. __periods: month of each primary (Table 3), n_occasions.
#   Coordinates: none deposited. Oligosoma salmo is IUCN CR (flagged, E7); the paper's site
#   location is not carried (geographicCoverage is at region level).
#   Not shipped: the collapsed files (recodes), the human-only set, the paper's estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "jordan_2025_kapitia_skink_rd"
dir <- download_dryad("10.5061/dryad.bvq83bkkh", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

rd <- function(f, n, nch) {
  L <- sub("\r$", "", readLines(file.path(dir, f), warn = FALSE)); L <- L[nzchar(trimws(L))]
  m <- regmatches(L, regexec("^/\\* ([0-9]+A?) \\*/ ([01]+) 1;$", L))
  stopifnot(length(L) == n, all(lengths(m) == 3))
  d <- data.table(id = sapply(m, `[`, 2), ch = sapply(m, `[`, 3))
  stopifnot(!anyDuplicated(d$id), all(nchar(d$ch) == nch))
  d
}
mat <- function(ch) { X <- do.call(rbind, strsplit(ch, "")); storage.mode(X) <- "integer"; X }
AI  <- rd("AI_SupplementedEncounterHistory.inp", 360, 52)
AIc <- rd("AI_SupplementedEncounterHistory_Collapsed.inp", 360, 5)
HO  <- rd("HumanOnlyEncounterHistory.inp", 390, 52)
HOc <- rd("HumanOnlyEncounterHistory_Collapsed.inp", 390, 5)
XA <- mat(AI$ch); XH <- mat(HO$ch)
stopifnot(sum(XA) == 793, sum(XH) == 792, all(rowSums(XA) > 0), all(colSums(XA) > 0))

# the secondaries-per-primary split: the only 10-or-11 split that reproduces the collapsed files
collapse <- function(X, k) { pr <- rep(seq_along(k), k); sapply(seq_along(k), function(p) as.integer(rowSums(X[, pr == p, drop = FALSE]) > 0)) }
splits <- lapply(combn(5, 2, simplify = FALSE), function(pos) { k <- rep(10L, 5); k[pos] <- 11L; k })
fits <- sapply(splits, function(k) identical(collapse(XA, k), mat(AIc$ch)) && identical(collapse(XH, k), mat(HOc$ch)))
stopifnot(identical(AI$id, AIc$id), identical(HO$id, HOc$id), sum(fits) == 1)
K <- splits[[which(fits)]]
stopifnot(identical(K, c(10L, 10L, 11L, 10L, 11L)))
prim <- rep(1:5, K)

# the two identification sets are not recodes of one another
sh <- merge(AI, HO, by = "id")
stopifnot(length(setdiff(AI$id, HO$id)) == 2, length(setdiff(HO$id, AI$id)) == 32, nrow(sh) == 358, sum(sh$ch.x != sh$ch.y) == 31)

units <- paste0("S", AI$id)
long <- array_to_eco(XA, taxon = "OLISAL", site_ids = units, period = prim)
long <- order_eco(long)
stopifnot(nrow(long) == 360 * 52, sum(long$y) == 793, uniqueN(long$unit) == 360,
          identical(long[, .(k = max(occasion)), by = period]$k, K),
          identical(as.integer(long[, uniqueN(unit[y == 1]), by = period]$V1), as.integer(colSums(mat(AIc$ch)))))

periods <- data.table(period = 1:5, month = c("2019-01", "2019-03", "2020-01", "2020-11", "2021-02"), n_occasions = K,
                      note = "primary sampling period spanning 12 days; month from the paper's Table 3; secondaries per primary from the deposited collapsed histories")
taxa <- make_taxa("OLISAL", "Oligosoma salmo", vernacularName = "Kapitia skink")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "CR"))

dataset <- list(
  title = "Robust-design photo-identification capture histories of 360 Kapitia skinks (AI-supplemented identities), West Coast, New Zealand, 2019-2021",
  creator = "Jordan, Emily A.; Ewen, John; Hitchmough, Rod; Moran, Les R.; Murrell, David J.; Rowcliffe, J. Marcus; Adams, Lynn K.", pubDate = "2025",
  doi = "10.5061/dryad.bvq83bkkh", sourceURL = "https://doi.org/10.5061/dryad.bvq83bkkh",
  citation = "Jordan, E. A., Ewen, J., Hitchmough, R., Moran, L. R., Murrell, D. J., Rowcliffe, J. M., & Adams, L. K. (2025). Data from: Supplementing human observation with artificial intelligence impacts demographic estimates for a Critically Endangered lizard [Dataset]. Dryad. https://doi.org/10.5061/dryad.bvq83bkkh",
  paperDOI = "10.1002/2688-8319.70018",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-recapture of the critically endangered Kapitia skink (Oligosoma salmo) across its only wild site, a strip of coastal grass and scrub on the West Coast of South Island, New Zealand, after cyclone Fehi: five primary periods (January 2019 to February 2021) of 10 or 11 artificial-cover-object surveys each, skinks identified from photographs of their scale pattern with the aid of HotSpotter (AI-supplemented identities, which the paper's verification found to be the 360 true individuals). 793 captures. Used in Huggins robust-design models of abundance, survival and temporary emigration.",
  samplingProtocol = "At each survey (about 1.5 h, starting 09:00-13:00) every artificial cover object along the site was lifted inside a bottomless box; skinks were caught, measured, photographed on the left side and released. Five 12-day primary periods, 10 or 11 surveys each, 2-10 months apart. Individuals identified from photographs with HotSpotter candidate matches reviewed by a researcher.",
  samplingProtocolCode = "cover_object_search", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every one of the 52 history columns is a survey (each has a capture). The split into primaries (10, 10, 11, 10, 11) is the only 10-or-11 split (paper s. 2.2) that reproduces the deposited collapsed per-primary histories.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "occasion = survey within a 12-day primary period (robust design; closed within primaries, open between). Ids are valid across the study.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "The species' only wild site, a coastal strip about 1 km long on the West Coast of South Island, New Zealand (no coordinates deposited; IUCN CR, so none are given here)",
  temporalCoverage = "2019-01/2021-02",
  notShipped = list(human_only = "HumanOnlyEncounterHistory.inp: the same photographs identified by human observers alone (390 histories in the deposit, 402 individuals in the paper's Table 1, 792 captures). Not a recode of the AI-supplemented set (32 ids absent from it, 31 shared ids with different histories); the paper's verification found the AI-supplemented identities correct (360 individuals, no false rejections) and the human-only set to split 42 recaptured animals into new individuals.",
                    collapsed = "the two _Collapsed.inp files: per-primary presence, rebuilt exactly from the full histories (asserted)",
                    model_estimates = "abundance, survival, temporary emigration and capture-probability estimates (model outputs)"),
  notes = "unit ids are the deposit's MARK ids with an S prefix (one id is 578A). The skinks were wild-caught with unknown age, so each carries all 52 surveys (E4.4); condition on first capture to reproduce MARK's robust design. Oligosoma salmo is IUCN CR; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/jordan_2025_kapitia_skink_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design photo-identification capture histories of 360 critically endangered Kapitia skinks (AI-supplemented identities) under artificial cover objects, West Coast, New Zealand: five primaries 2019-2021, 52 surveys.",
  url = "https://doi.org/10.5061/dryad.bvq83bkkh",
  reference = "Jordan, E. A., Ewen, J., Hitchmough, R., Moran, L. R., Murrell, D. J., Rowcliffe, J. M., & Adams, L. K. (2025). Supplementing human observation with artificial intelligence impacts demographic estimates for a critically endangered lizard. Ecological Solutions and Evidence.",
  doi_paper = "10.1002/2688-8319.70018", doi_data = "10.5061/dryad.bvq83bkkh",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "AI-supplemented set only; human-only set in notShipped. Secondaries per primary recovered from the collapsed files. IUCN CR, no coordinates. Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Robust design",
  sampling_protocol = "cover_object_search", design = "Robust design (5 primaries x 10-11 surveys)", realm = "Terrestrial", country = "NZL",
  coordinates = "None in source", notes = "IUCN CR endemic; photo-identification with AI-supplemented matching.", status = "tagged")
