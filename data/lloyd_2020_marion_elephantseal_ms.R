#!/usr/bin/env Rscript
# Table:  lloyd_2020_marion_elephantseal_ms
# Source: Dryad doi:10.5061/dryad.bcc2fqz7h (CC0 1.0, as shown on the Dryad page; published
#         2020-10-30). Lloyd, K.J., Oosthuizen, W.C., Bester, M.N. & de Bruyn, P.J.N. Data from:
#         Trade-offs between age-related breeding improvement and survival senescence in highly
#         polygynous elephant seals.
# Paper:  Lloyd, K.J. et al. (2020). Journal of Animal Ecology 89(3), doi:10.1111/1365-2656.13145.
#         All elephant seal pups weaned at Marion Island 1983-2009 were double-tagged (27 cohorts,
#         6,245 male pups); all breeding beaches surveyed every 7 days in the breeding season and
#         every 10 days otherwise, 1983-2016; one event per seal year: 0 not seen; 1 / 2
#         pre-breeder with two / one tags; 3 / 4 subordinate breeder; 5 / 6 dominant breeder; 7 / 8
#         unknown breeding state (Dryad methods).
# Data:   Male_SES_encounter_history_matrix.txt (E-SURGE / MARK layout: H:C1 .. H:C34 = seal years
#         1983-2016, codes 0-8; S:Sample (a single sample, always 1); $COV:Tag = tag position IIT
#         (inner interdigital webbing, 1983-1999) or OIT
#         (outer, 2000-2009)). 6,245 histories.
# Mapping (standard: multi-state / multi-event capture-recapture, E9 core): unit = seal (M0001,
#   file order); taxon = MIRLEO; period = seal year 1..34 (__periods); y = the event code with
#   stateCodes from the methods. Rows (E4.4): pups marked at weaning are at risk from their
#   tagging year (the first non-zero event, asserted to be a pre-breeder event) to 2016; no
#   deaths or removals are recorded. unit_tag_position. Survey evidence: deposited_matrix.
#   Southern elephant seal is IUCN LC; no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lloyd_2020_marion_elephantseal_ms"
dir <- download_dryad("10.5061/dryad.bcc2fqz7h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Male_SES_encounter_history_matrix\\.txt$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, header = TRUE)
stopifnot(ncol(d) == 36, identical(names(d)[1:34], paste0("H:C", 1:34)), identical(names(d)[35:36], c("S:Sample", "$COV:Tag")), nrow(d) == 6245, all(d[[35]] == 1), all(d[[36]] %in% c("IIT", "OIT")))
H <- as.matrix(d[, 1:34]); stopifnot(all(H %in% 0:8))
first <- apply(H, 1, function(r) which(r > 0)[1])
stopifnot(!anyNA(first), all(H[cbind(seq_len(nrow(H)), first)] %in% 1:2), max(first) <= 27)   # tagged as pups (pre-breeder) in 1983-2009
ids <- sprintf("M%04d", seq_len(nrow(H)))
long <- rbindlist(lapply(seq_len(nrow(H)), function(i) data.table(unit = ids[i], period = first[i]:34, y = as.integer(H[i, first[i]:34]))))
long[, `:=`(taxon = "MIRLEO", unit_tag_position = d[[36]][match(unit, ids)])]
long <- order_eco(long)
stopifnot(nrow(long) == sum(35 - first), sum(long$y > 0) == sum(H > 0))
periods <- data.table(period = 1:34, period_seal_year = 1983:2016)
taxa <- make_taxa("MIRLEO", "Mirounga leonina", vernacularName = "Southern elephant seal")
dataset <- list(
  title = "Multi-event resighting histories of 6,245 male southern elephant seals tagged as pups at Marion Island, 1983-2016",
  creator = "Lloyd, Kyle J.; Oosthuizen, W. Chris; Bester, Marthán N.; de Bruyn, P. J. Nico", pubDate = "2020",
  doi = "10.5061/dryad.bcc2fqz7h", sourceURL = "https://doi.org/10.5061/dryad.bcc2fqz7h",
  citation = "Lloyd, K. J., Oosthuizen, W. C., Bester, M. N., & de Bruyn, P. J. N. (2020). Data from: Trade-offs between age-related breeding improvement and survival senescence in highly polygynous elephant seals [Dataset]. Dryad. https://doi.org/10.5061/dryad.bcc2fqz7h",
  paperDOI = "10.1111/1365-2656.13145",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual resighting events of 6,245 male southern elephant seals (Mirounga leonina) double-tagged as weaned pups at Marion Island (27 cohorts, 1983-2009) and resighted on beach surveys through 2016, each event coding breeding status (pre-breeder, subordinate, dominant or unknown) and whether one or both tags remained.",
  samplingProtocol = "Every elephant seal breeding beach at Marion Island surveyed every 7 days in the breeding season and every 10 days outside it, 1983-2016; tagged males recorded with breeding status (harem association) and number of tags; one event per seal year.",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "state",
  stateCodes = list(`0` = "not seen", `1` = "seen as a pre-breeder with two tags", `2` = "seen as a pre-breeder with one tag",
                    `3` = "seen as a subordinate breeder with two tags", `4` = "seen as a subordinate breeder with one tag",
                    `5` = "seen as a dominant breeder with two tags", `6` = "seen as a dominant breeder with one tag",
                    `7` = "seen with an unknown breeding state and two tags", `8` = "seen with an unknown breeding state and one tag"),
  unitKind = "individual", closure = "none", closureNote = "one event per seal year; open between years (multi-event model)", occasionKind = "none",
  taxonInclusion = "single", geographicCoverage = "Marion Island (Prince Edward Islands), Southern Ocean; no coordinates deposited", temporalCoverage = "1983/2016",
  notShipped = list(sample = "the E-SURGE sample column S:Sample (always 1)"),
  notes = "Rows run from each seal's tagging year (its first event, a pre-breeder code) to 2016. Female elephant seals from the same programme are oosthuizen_2019_marion_seal_rd (a different deposit).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lloyd_2020_marion_elephantseal_ms.R")
stage_dict_row(TABLE, description = "Multi-event resighting histories (breeding status and tag loss) of 6,245 male southern elephant seals tagged as pups at Marion Island, 1983-2016.",
  url = "https://doi.org/10.5061/dryad.bcc2fqz7h", reference = "Lloyd, K. J., Oosthuizen, W. C., Bester, M. N., & de Bruyn, P. J. N. (2020). Trade-offs between age-related breeding improvement and survival senescence in highly polygynous elephant seals. Journal of Animal Ecology, 89(3).",
  doi_paper = "10.1111/1365-2656.13145", doi_data = "10.5061/dryad.bcc2fqz7h", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-event CMR; rows from tagging year.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state / multi-event capture-recapture",
  sampling_protocol = "tag_resight", design = "Multi-season (34 seal years)", realm = "Marine",
  country = "ZAF", coordinates = "None in source", notes = "Breeding status and tag loss.")
