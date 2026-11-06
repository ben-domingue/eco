#!/usr/bin/env Rscript
# Tables: husemann_2015_<fragment>_greenbul_cjs for the five Taita Hills fragments (ch, fu, mb,
#         nd, ng)
# Source: Dryad doi:10.5061/dryad.8n5d7 (CC0 1.0, as shown on the Dryad page; published
#         2015-02-09). Husemann, M., Cousseau, L., Callens, T., Matthysen, E., Vangestel, C.,
#         Hallmann, C. & Lens, L. Data from: Post-fragmentation population structure in a
#         cooperative breeding Afrotropical cloud forest bird: emergence of a source-sink
#         population network.
# Paper:  Husemann, M. et al. (2015). Molecular Ecology 24(6), doi:10.1111/mec.13105. Cabanis's
#         greenbul (Phyllastrephus cabanisi) mist-netted and colour-ringed in five cloud-forest
#         fragments of the Taita Hills, Kenya (Chawia CH, Fururu FU, Mbololo MB, Ndiwenyi ND,
#         Ngangao NG; expansions as in the paper's study area), in two periods (P1 1996-2000, P2
#         2005-2009); capture-recapture used to estimate census sizes and survival.
# Data:   CMR_data.zip / MR_data/: <frag>_inputData_P1/P2.txt (eh = capture history string, one
#         character per session; Period; Fragment) and <frag>_intervalLength_P1/P2.txt (Interval,
#         IntervalStart date, Days to the next session, YearFrac): each fragment and period has its
#         own session calendar (7-14 intervals). Microsatellite genotypes and nestling data (not
#         survey data, not shipped).
# Mapping (standard: CJS, E9 core): one table per fragment, since calendars differ by fragment.
#   unit = bird (<period>_<row>; birds are not linked between P1 and P2); taxon = PHYCAB; period
#   = session, numbered through P1 then P2 (__periods: period_sampling_period, period_session and
#   period_session_start as deposited, often the 15th of a month); y = captured 0/1. Rows (E4.4):
#   from the bird's first capture to the last session of its sampling period. No occasion.
#   Survey evidence: deposited_matrix. Kenya's Taita Hills; species IUCN LC; no coordinates.
#   The FU P2 calendar has 24May2007 after 15Oct2007 (a date out of order, kept as deposited);
#   period order follows the history columns.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
dir <- download_dryad("10.5061/dryad.8n5d7", "husemann_2015_taita_greenbul_cjs")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
z <- list.files(dir, "^CMR_data\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(z) == 1)
ex <- file.path(dirname(z), "unzipped"); if (!dir.exists(ex)) unzip(z, exdir = ex)
rf <- function(n) { f <- list.files(ex, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f, colClasses = list(character = "eh")) }
FR <- c(ch = "Chawia", fu = "Fururu", mb = "Mbololo", nd = "Ndiwenyi", ng = "Ngangao")
taxa <- make_taxa("PHYCAB", "Phyllastrephus cabanisi", vernacularName = "Cabanis's greenbul")
for (fr in names(FR)) {
  FRU <- toupper(fr); parts <- list(); per <- list(); off <- 0L
  for (P in c("P1", "P2")) {
    h <- rf(sprintf("%s_inputData_%s\\.txt", FRU, P)); iv <- fread(list.files(ex, sprintf("^%s_intervalLength_%s\\.txt$", FRU, P), recursive = TRUE, full.names = TRUE))
    ns <- nrow(iv) + 1L
    stopifnot(all(h$Period == P), all(h$Fragment == FRU), all(nchar(h$eh) == ns), all(grepl("^[01]+$", h$eh)), all(grepl("1", h$eh)),
              identical(iv$Interval, seq_len(nrow(iv))), all(iv$Fragment == FRU), all(iv$Period == as.integer(sub("P", "", P))))
    H <- do.call(rbind, strsplit(h$eh, "")); storage.mode(H) <- "integer"
    first <- apply(H, 1, function(r) which(r == 1L)[1])
    ids <- sprintf("%s_%03d", P, seq_len(nrow(H)))
    parts[[P]] <- rbindlist(lapply(seq_len(nrow(H)), function(i) data.table(unit = ids[i], period = off + (first[i]:ns), y = H[i, first[i]:ns])))
    per[[P]] <- data.table(period = off + seq_len(ns), period_sampling_period = P, period_session = seq_len(ns),
                           period_session_start = c(iv$IntervalStart, NA_character_), period_days_to_next = c(iv$Days, NA_integer_))
    off <- off + ns
  }
  long <- rbindlist(parts)[, taxon := "PHYCAB"]
  long <- order_eco(long); periods <- rbindlist(per)
  stopifnot(sum(long$y) == sum(sapply(c("P1", "P2"), function(P) sum(nchar(gsub("0", "", rf(sprintf("%s_inputData_%s\\.txt", FRU, P))$eh))))))
  TABLE <- sprintf("husemann_2015_%s_greenbul_cjs", fr)
  nb <- uniqueN(long$unit)
  dataset <- list(
    title = sprintf("Capture-recapture histories of %d Cabanis's greenbuls in the %s forest fragment, Taita Hills, Kenya, 1996-2000 and 2005-2009", nb, FR[[fr]]),
    creator = "Husemann, Martin; Cousseau, Laurence; Callens, Tom; Matthysen, Erik; Vangestel, Carl; Hallmann, Caspar; Lens, Luc", pubDate = "2015",
    doi = "10.5061/dryad.8n5d7", sourceURL = "https://doi.org/10.5061/dryad.8n5d7",
    citation = "Husemann, M., Cousseau, L., Callens, T., Matthysen, E., Vangestel, C., Hallmann, C., & Lens, L. (2015). Data from: Post-fragmentation population structure in a cooperative breeding Afrotropical cloud forest bird: emergence of a source-sink population network [Dataset]. Dryad. https://doi.org/10.5061/dryad.8n5d7",
    paperDOI = "10.1111/mec.13105",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Mist-net capture-recapture histories of Cabanis's greenbul (Phyllastrephus cabanisi) in the %s cloud-forest fragment of the Taita Hills, Kenya, over two sampling periods (1996-2000 and 2005-2009) with irregular sessions; birds of the two periods are not linked.", FR[[fr]]),
    samplingProtocol = "Repeated mist-netting sessions in the forest fragment; birds individually colour-ringed; one capture record per bird per session.",
    samplingProtocolCode = "mist_net", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
    closure = "none", closureNote = "sessions months apart; open population (CJS)", occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = sprintf("%s fragment, Taita Hills, Taita-Taveta County, Kenya; no coordinates deposited", FR[[fr]]),
    temporalCoverage = "1996/2009",
    notShipped = list(genetics = "microsatellite genotypes and nestling / fledgling records (not survey data)"),
    notes = "Periods number the sessions through P1 then P2; session start dates are as deposited (often the 15th of the month, so approximate) and are in __periods, not a date column. Each bird's rows run from its first capture to the last session of its sampling period.")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/husemann_2015_taita_greenbul_cjs.R")
  stage_dict_row(TABLE, description = sprintf("Capture-recapture histories of %d Cabanis's greenbuls in the %s fragment, Taita Hills, Kenya, 1996-2009.", nb, FR[[fr]]),
    url = "https://doi.org/10.5061/dryad.8n5d7", reference = "Husemann, M. et al. (2015). Post-fragmentation population structure in a cooperative breeding Afrotropical cloud forest bird: emergence of a source-sink population network. Molecular Ecology, 24(6).",
    doi_paper = "10.1111/mec.13105", doi_data = "10.5061/dryad.8n5d7", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "CJS per forest fragment.", source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Cormack-Jolly-Seber",
    sampling_protocol = "mist_net", design = sprintf("Multi-season (%d sessions in two periods)", nrow(periods)), realm = "Terrestrial",
    country = "KEN", coordinates = "None in source", notes = "Fragmented cloud forest.")
}
