#!/usr/bin/env Rscript
# Table:  tsuboi_2020_japan_charr_ms
#         (one of two tables from this deposit: the other species, the red-spotted masu salmon (tsuboi_2020_japan_masu_ms), is its own table
#         because an individual carries only its own taxon, E4 ruling #20)
# Source: Dryad doi:10.5061/dryad.jm63xsj6t, version 54879 (published 2020-02-25), licence CC0 1.0
#         (as shown on the Dryad landing page and in the API record).
#         Tsuboi, J., Morita, K., Koseki, Y., Endo, S., Sahashi, G., Kishi, D., Kikko, T., Ishizaki, D.,
#         Nunokawa, M. & Kanno, Y. "Spatial covariation of fish population vital rates in a stream network".
# Paper:  Tsuboi, J. et al. (2020). Spatial covariation of fish population vital rates in a stream
#         network. Oikos 129(6), doi:10.1111/oik.07169 (paywalled, not read; design, state codes and
#         protocol from the Dryad methods and usage notes, which are complete for the deposit).
# Data:   six files.
#   charr_data_for_CJS.csv   1,373 white-spotted charr; Individual (Ind0001..), Y2009..Y2017 (observed
#                            state per annual survey), ExitOccasion (occasion of confirmed handling
#                            mortality, 9 = none; 9 for every fish in this deposit).
#   salmon_data_for_CJS.csv  1,335 red-spotted masu salmon, same layout.
#   States (usage notes): 1 juvenile in tributary, 2 juvenile in mainstem connected, 3 juvenile in
#   mainstem fragmented, 4 adult in tributary, 5 adult in mainstem connected, 6 adult in mainstem
#   fragmented, 7 not detected. Juvenile = young of the year (YOY), from length-frequency and scales.
#   ms-cjs-call-*.R, ms-cjs-model-*.stan  the authors' Stan multistate CJS (read; it uses ExitOccasion
#                            as each fish's last occasion).
#   Design (Dryad methods): one survey a year (third weekend of October) 2009-2017 in a headwater
#   stream network of tributary and mainstem sections separated by low-head dams; two-pass backpack
#   electrofishing with dip nets per section; fish > 43 mm FL marked with visible implant elastomer
#   (four-colour codes, lost colours re-marked; individuals identified by species, sex, size and
#   section). All fish returned alive.
#   Every history's first capture is in 2009-2016: fish first caught in 2017 are not in the deposit
#   (no recapture possible; the authors' analysis set). No fish ever moves from adult back to juvenile
#   and each fish has at most one juvenile record (asserted).
#
# Mapping (standard E9 multi-state CJS, responseType state, unitKind individual):
#   unit = SLJ_ + Individual, taxon = SLJ (Salvelinus leucomaenis japonicus, charr_data_for_CJS.csv only); period = year
#   1..9 (2009..2017, in __periods); no occasion. y = 0 not detected (source 7), 1..6 the deposited
#   state; y_raw = the deposited code. obs_first_capture = 1 on the marking row.
#   At-risk span (E4.4): a fish first caught as a juvenile (YOY, states 1-3) was born that year, so
#   its rows begin at that first capture; a fish first caught as an adult is of unknown age and its
#   rows begin in 2009. Rows run to 2017 (no handling mortality, no recorded mark loss).
#   Survey evidence: deposited_matrix (the annual survey happened every year 2009-2017; methods).
#   Coordinates: none in the deposit.
#   Not shipped: ExitOccasion (constant 9: no handling mortality); fork length, sex and the depletion
#   counts are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "tsuboi_2020_japan_charr_ms"
dir <- download_dryad("doi:10.5061/dryad.jm63xsj6t", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "54879"), length(list.files(dir)) == 6L)
years <- 2009:2017
one <- function(file, code, n, first_tab) {
  d <- fread(file.path(dir, file))
  stopifnot(identical(names(d), c("Individual", paste0("Y", years), "ExitOccasion")), nrow(d) == n,
            !anyDuplicated(d$Individual), all(d$ExitOccasion == 9L))
  S <- as.matrix(d[, paste0("Y", years), with = FALSE])
  stopifnot(all(S %in% 1:7))
  first <- apply(S, 1, function(r) which(r != 7L)[1])
  stopifnot(!anyNA(first), identical(as.integer(tabulate(first, 9)), first_tab))
  seen <- lapply(seq_len(nrow(S)), function(i) S[i, S[i, ] != 7L])
  stopifnot(all(vapply(seen, function(r) sum(r <= 3L) <= 1L && all(diff(r >= 4L) >= 0), logical(1))))
  juv <- S[cbind(seq_len(nrow(S)), first)] <= 3L
  start <- ifelse(juv, first, 1L)
  rbindlist(lapply(seq_len(nrow(S)), function(i) { t <- start[i]:9L
    data.table(unit = paste0(code, "_", d$Individual[i]), taxon = code, y = ifelse(S[i, t] == 7L, 0L, S[i, t]),
               y_raw = as.character(S[i, t]), period = t, obs_first_capture = as.integer(t == first[i])) }))
}
long <- order_eco(one("charr_data_for_CJS.csv", "SLJ", 1373L, c(212L, 6L, 143L, 177L, 55L, 196L, 314L, 270L, 0L)))
stopifnot(identical(as.integer(table(factor(long[y > 0, y], 1:6))), c(519L, 403L, 244L, 378L, 156L, 140L)),
          sum(long$obs_first_capture) == 1373L, uniqueN(long$unit) == 1373L, !anyNA(long$y))

taxa <- make_taxa("SLJ", "Salvelinus leucomaenis japonicus", vernacularName = "White-spotted charr (Japanese subspecies)", taxonRank = "subspecies",
                  lookupName = "Salvelinus leucomaensis japonicus")  # GBIF backbone spelling
periods <- data.table(period = seq_along(years), year = years, survey = "third weekend of October",
                      n_detected = as.integer(long[y > 0, tabulate(period, 9)]),
                      n_first_capture = as.integer(long[obs_first_capture == 1L, tabulate(period, 9)]))

dataset <- list(
  title = "Annual multistate capture histories (age class x stream location) of 1,373 white-spotted charr in a Japanese headwater stream network, 2009-2017",
  creator = "Tsuboi, Jun-ichi; Morita, Kentaro; Koseki, Yusuke; Endo, Shinsuke; Sahashi, Genki; Kishi, Daisuke; Kikko, Takeshi; Ishizaki, Daisuke; Nunokawa, Masanori; Kanno, Yoichiro",
  pubDate = "2020", doi = "10.5061/dryad.jm63xsj6t", sourceURL = "https://doi.org/10.5061/dryad.jm63xsj6t",
  citation = "Tsuboi, J., Morita, K., Koseki, Y., Endo, S., Sahashi, G., Kishi, D., Kikko, T., Ishizaki, D., Nunokawa, M., & Kanno, Y. (2020). Spatial covariation of fish population vital rates in a stream network [Dataset]. Dryad. https://doi.org/10.5061/dryad.jm63xsj6t",
  paperDOI = "10.1111/oik.07169",
  abstract = "Nine-year annual mark-recapture of two native Japanese salmonids, white-spotted charr (Salvelinus leucomaenis japonicus) and red-spotted masu salmon (Oncorhynchus masou ishikawae), in a headwater stream network of tributary and mainstem habitats split by low-head dams. Each encounter records age class (young of the year or adult) and location (tributary, connected mainstem, fragmented mainstem); the paper fits multistate CJS models of state-specific survival, capture and movement.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "One survey a year (third weekend of October, 2009-2017): two-pass backpack electrofishing (300-400 V DC) with 3 mm dip nets in each study section; fish over 43 mm fork length marked individually with four-colour visible implant elastomer (lost colours re-marked), aged as young of the year or adult from length-frequency and scales, and returned to the capture site.",
  samplingProtocolCode = "electrofishing", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "one state per fish per annual survey; survival and state transitions between years",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none",
  stateCodes = list(`0` = "not detected (source 7)",
                    `1` = "juvenile (young of the year) in a tributary", `2` = "juvenile in the connected mainstem",
                    `3` = "juvenile in the fragmented mainstem", `4` = "adult (age 1+) in a tributary",
                    `5` = "adult in the connected mainstem", `6` = "adult in the fragmented mainstem"),
  temporalCoverage = "2009-10/2017-10",
  geographicCoverage = "A headwater stream network (tributaries and a dammed mainstem) in Japan; the deposit gives no location",
  notes = "Unit = SLJ_ + the deposited Individual id. The red-spotted masu salmon (tsuboi_2020_japan_masu_ms) from the same surveys is a separate table (E4 ruling #20). Rows begin at first capture for fish first caught as young of the year (born that year) and in 2009 for fish first caught as adults (unknown age, E4.4); obs_first_capture marks the marking row. The deposit holds the authors' analysis set: fish first caught in 2017 are absent, and no fish has a handling mortality (ExitOccasion = 9 throughout). The taxon is a Japanese subspecies, matched on GBIF at subspecies rank: the backbone spells it 'leucomaensis' and treats it as a synonym of Salvelinus japonicus (gbifAcceptedName).",
  coordinatesCoarsened = NA,
  notShipped = list(ExitOccasion = "constant 9 (no handling mortality); represented by rows running to 2017"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/tsuboi_2020_japan_charr_ms.R")
stage_dict_row(TABLE,
  description = "Annual multistate capture histories of 1,373 white-spotted charr in a Japanese headwater stream network, 2009-2017; states cross age class (young of the year, adult) with location (tributary, connected or fragmented mainstem).",
  url = "https://doi.org/10.5061/dryad.jm63xsj6t",
  reference = "Tsuboi, J., Morita, K., Koseki, Y., Endo, S., Sahashi, G., Kishi, D., Kikko, T., Ishizaki, D., Nunokawa, M., & Kanno, Y. (2020). Spatial covariation of fish population vital rates in a stream network. Oikos, 129(6).",
  doi_paper = "10.1111/oik.07169", doi_data = "10.5061/dryad.jm63xsj6t",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. Adults padded back to 2009 (unknown age); YOY start at marking. No location in the deposit. Sibling table for the red-spotted masu salmon (tsuboi_2020_japan_masu_ms).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-state CJS capture-recapture (age x location; movement)",
  sampling_protocol = "electrofishing", design = "Multi-session (9 annual surveys)",
  realm = "Freshwater", country = "JPN", coordinates = "None in source",
  notes = "Native salmonid subspecies; states combine age class and stream section type; the red-spotted masu salmon is a sibling table.")
