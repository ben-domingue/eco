#!/usr/bin/env Rscript
# Tables: direnzo_2025_elcope_espadarana_cjs (pre-Bd, 2000-2004, annual detection histories)
#         direnzo_2025_elcope_espadarana_ms  (post-Bd, 2010-2014, nine surveys, detection with
#                                             infection state)
# Source: USGS ScienceBase doi:10.5066/P1A8KDTE (USGS data release, published 2025-06-17;
#         "This work is marked with Creative Commons Zero v1.0 Universal")
#   DiRenzo, G.V., McCaffery, R., Longo, A.V., Zamudio, K.R., and Lips, K.R., 2025, Ten years of
#   capture-mark-recapture data for Espadarana prosoblepon in El Cope, Cocle Province, Panama
#   before and after a chytridiomycosis outbreak (2000-2014): U.S. Geological Survey data release.
#   Code: doi:10.5066/P1DWG6GZ (not used).
# Data:   Epannual_PreBd2000-2004.csv (CR line endings): 415 male frogs x Y1-Y5, detected (1) or not
#         (0) in each wet season 2000-2004 (Bd arrived September 2004); no frog ids. CH_month2.csv:
#         267 frogs (id) x survey_1-9 (July 2010, July 2011, June 2012, July 2012, Feb 2013, March
#         2013, June 2013, July 2013, March 2014): 1 detected uninfected, 2 detected infected,
#         3 detected not tested, 4 not detected. Infection_months2.csv: Bd load per frog x survey
#         (0 where not detected or not infected). Stream transects surveyed repeatedly within each
#         season (pre-Bd roughly weekly May-August); the deposit collapses each season to one
#         occasion.
#
# Mapping: unit = frog, taxon = ESPPRO, period = season (one occasion each, no occasion column).
#   _cjs: y = 0/1 as deposited, unit = "pre<row>" (no ids in the release); every history starts
#   at 2000 (the full rectangle as deposited; E4.4). _ms (responseType state): y = 0 not
#   detected, 1 detected uninfected, 2 detected infected, 3 detected with infection not tested
#   (y_raw = source code 1-4), obs_bd_load = the deposited Bd load. Eight post-Bd frogs that are
#   never detected (all 4) are not units (dropped, asserted). No coordinates (single site,
#   8.57 N 80.59 W, in the metadata). Survey evidence: deposited_matrix (one column per season).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "direnzo_2025_elcope_espadarana"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/660590e9d34e64ff1549916f?format=json", SRC, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
dl <- function(f) download_cached(fl[[f]], SRC, filename = f)
f <- dl("Epannual_PreBd2000-2004.csv")
pre <- fread(text = gsub("\r", "\n", readChar(f, file.size(f), useBytes = TRUE), fixed = TRUE))
ch <- fread(dl("CH_month2.csv")); inf <- fread(dl("Infection_months2.csv"))
stopifnot(identical(names(pre), paste0("Y", 1:5)), nrow(pre) == 415, all(as.matrix(pre) %in% 0:1), all(rowSums(pre) >= 1),
          nrow(ch) == 267, ncol(ch) == 10, !anyDuplicated(ch$V1), identical(ch$V1, inf$V1))
M <- as.matrix(ch[, -1]); B <- as.matrix(inf[, -1])
stopifnot(all(M %in% 1:4), !anyNA(B), all(B[M == 4] == 0), sum(rowSums(M != 4) == 0) == 8)
taxa <- make_taxa("ESPPRO", "Espadarana prosoblepon", vernacularName = "Emerald glass frog")
common <- list(
  creator = "DiRenzo, Graziella V.; McCaffery, Rebecca; Longo, Ana V.; Zamudio, Kelly R.; Lips, Karen R.", pubDate = "2025",
  doi = "10.5066/P1A8KDTE", sourceURL = "https://doi.org/10.5066/P1A8KDTE",
  citation = "DiRenzo, G.V., McCaffery, R., Longo, A.V., Zamudio, K.R., and Lips, K.R., 2025, Ten years of capture-mark-recapture data for Espadarana prosoblepon in El Cope, Cocle Province, Panama before and after a chytridiomycosis outbreak (2000-2014): U.S. Geological Survey data release, https://doi.org/10.5066/P1A8KDTE.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
  abstract = "Five years (2000-2004) of capture-mark-recapture data for male Espadarana prosoblepon before Batrachochytrium dendrobatidis arrived in El Cope, Panama in September 2004, and five years (2010-2014) after the outbreak in the same population, with infection status and load.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", unitKind = "individual", taxonInclusion = "single",
  closure = "none", closureNote = "one occasion per season as deposited", occasionKind = "none",
  geographicCoverage = list(description = "Stream transects at El Cope, Cocle Province, Panama (8.571 N, 80.587 W)"))
ref <- "DiRenzo, G.V., McCaffery, R., Longo, A.V., Zamudio, K.R., and Lips, K.R. (2025). Ten years of capture-mark-recapture data for Espadarana prosoblepon in El Cope, Panama before and after a chytridiomycosis outbreak (2000-2014). U.S. Geological Survey data release."

T1 <- paste0(SRC, "_cjs")
long1 <- array_to_eco(as.matrix(pre), taxon = "ESPPRO", site_ids = paste0("pre", seq_len(nrow(pre))), period = 1:5)
long1[, occasion := NULL]
stopifnot(nrow(long1) == 415 * 5, sum(long1$y) == 617)
ds1 <- write_table(long1, T1, c(list(title = "Annual capture histories of 415 male Espadarana prosoblepon glass frogs before the chytrid outbreak, El Cope, Panama, 2000-2004"), common, list(
  samplingProtocol = "Night visual encounter surveys of stream transects about weekly May-August each wet season; males captured and individually marked; each season collapsed to detected / not detected by the authors.",
  responseType = "detection", temporalCoverage = "2000/2004",
  notes = "The release gives no frog ids for 2000-2004; units are numbered by row. Companion: direnzo_2025_elcope_espadarana_ms (post-outbreak).",
  notShipped = list(within_season_occasions = "the weekly surveys are not deposited; the authors collapsed each season to one occasion"))),
  taxa = taxa, periods = data.table(period = 1:5, year = 2000:2004), script = "data/direnzo_2025_elcope_espadarana.R")
stage_dict_row(T1, description = "Annual detection histories of 415 marked male Espadarana prosoblepon glass frogs on stream transects at El Cope, Panama, in the five wet seasons before Batrachochytrium dendrobatidis arrived (2000-2004).",
  url = "https://doi.org/10.5066/P1A8KDTE", reference = ref, doi_data = "10.5066/P1A8KDTE", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "No frog ids in the release (units numbered). Companion: direnzo_2025_elcope_espadarana_ms.", source_via = "USGS ScienceBase")
stage_tag_row(T1, ds1, taxon_group = "Amphibians", model_family = "CJS", sampling_protocol = "visual_encounter",
  design = "Multi-season (5 annual occasions)", realm = "Freshwater", country = "PAN", coordinates = "None in source", notes = "Pre-chytrid baseline.")

T2 <- paste0(SRC, "_ms")
keep <- rowSums(M != 4) > 0
M2 <- M[keep, ]; B2 <- B[keep, ]
Y <- ifelse(M2 == 4L, 0L, M2)
long2 <- array_to_eco(Y, taxon = "ESPPRO", site_ids = as.character(ch$V1[keep]), period = 1:9, obs_covs = list(bd_load = B2), y_raw = M2)
long2[, occasion := NULL]
stopifnot(nrow(long2) == 259 * 9, sum(long2$y > 0) == 481)
months <- c("2010-07", "2011-07", "2012-06", "2012-07", "2013-02", "2013-03", "2013-06", "2013-07", "2014-03")
ds2 <- write_table(long2, T2, c(list(title = "Capture histories with chytrid infection state of 259 male Espadarana prosoblepon glass frogs after the outbreak, El Cope, Panama, 2010-2014"), common, list(
  samplingProtocol = "Night visual encounter surveys of stream transects in nine survey bouts (July 2010 to March 2014, wet and dry seasons); males captured, marked and swabbed for Batrachochytrium dendrobatidis (qPCR); each bout collapsed to one occasion by the authors.",
  responseType = "state", temporalCoverage = "2010-07/2014-03",
  stateCodes = list(`0` = "not detected", `1` = "detected, Bd negative", `2` = "detected, Bd positive", `3` = "detected, not tested for Bd"),
  notes = "Multi-state capture-recapture (infection state). obs_bd_load is the deposited Bd infection intensity (0 where not detected or uninfected). Companion: direnzo_2025_elcope_espadarana_cjs (pre-outbreak).",
  notShipped = list(never_detected = "8 frogs in CH_month2 never detected in any survey (not units, E4.4)"))),
  taxa = taxa, periods = data.table(period = 1:9, year = as.integer(substr(months, 1, 4)), month = as.integer(substr(months, 6, 7))),
  script = "data/direnzo_2025_elcope_espadarana.R")
stage_dict_row(T2, description = "Detection and Batrachochytrium dendrobatidis infection state of 259 marked male Espadarana prosoblepon glass frogs in nine survey bouts after the chytrid outbreak at El Cope, Panama, 2010-2014, with infection load.",
  url = "https://doi.org/10.5066/P1A8KDTE", reference = ref, doi_data = "10.5066/P1A8KDTE", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-state (uninfected / infected / not tested). Companion: direnzo_2025_elcope_espadarana_cjs.", source_via = "USGS ScienceBase")
stage_tag_row(T2, ds2, taxon_group = "Amphibians", model_family = "Multi-state capture-recapture", sampling_protocol = "visual_encounter",
  design = "Multi-season (9 survey bouts)", realm = "Freshwater", country = "PAN", coordinates = "None in source", notes = "Disease state as the multi-state variable.")
