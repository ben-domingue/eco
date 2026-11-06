#!/usr/bin/env Rscript
# Table:  macario_2026_serido_sparrow_rd
# Source: Zenodo doi:10.5281/zenodo.20130217, published 2026-05-12, licence CC BY 4.0 (record metadata licence id
#         "cc-by-4.0", asserted from the cached record JSON).
#   Macario, P., Toledo-Lima, G. & Pichorim, M. (2026). Robust design capture-recapture history of 103 individuals
#   of Grassland Sparrow (Ammodramus humeralis) throughout seven sessions between 2012 and 2015 in the Brazilian
#   Caatinga [Dataset]. Zenodo.
# Paper:  none named by the deposit, and none found on Crossref (2026-11-06). Companion of
#         toledolima_2024_elaenia_cjs (same group, same Program MARK format, same reserve).
# Data:   "Grassland Sparrow.inp", a Program MARK input file. Header comment: 103 individuals, 1 group (adult
#         birds); 42 occasions (7 sessions x 6 occasions/session); 12-ha plot, 48 capture sites, June 2012 to July
#         2015; ESEC Serido, Rio Grande do Norte, Brazil. Then one line per bird: /*<band>*/ <42-character 0/1
#         history> 1; (frequency 1 for every bird, so no losses on capture). Session dates are not deposited.
# Mapping (robust design, E8): unit = band number, taxon = AMMHUM, period = session 1-7, occasion = secondary
#   occasion 1-6 within the session, y = 0/1. Every bird is an adult caught in the wild, so it was at risk from the
#   first session (E4.4): every bird has 42 rows. surveyEvidence = deposited_matrix (MARK histories have no missing
#   cells; every occasion was sampled). No coordinates deposited beyond the reserve. Ammodramus humeralis IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "macario_2026_serido_sparrow_rd"
REC <- "20130217"
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.20130217"),
          identical(meta$files$key, "Grassland Sparrow.inp"))
f <- download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode("Grassland Sparrow.inp", reserved = TRUE)),
                     TABLE, filename = "Grassland_Sparrow.inp")
l <- trimws(readLines(f, encoding = "latin1", warn = FALSE)); l <- l[nzchar(l)]
stopifnot(any(grepl("42 occasions \\(7 sessions x 6 occasions/session\\)", l)), any(grepl("103 individuals", l)))
l <- l[grepl("^/\\*[0-9]+\\*/", l)]
m <- regmatches(l, regexec("^/\\*([0-9]+)\\*/\\s+([01]{42})\\s+1;$", l))
stopifnot(length(l) == 103L, all(lengths(m) == 3L))
inp <- data.table(band = sapply(m, `[`, 2), ch = sapply(m, `[`, 3))
stopifnot(!anyDuplicated(inp$band), all(grepl("1", inp$ch)))
CH <- do.call(rbind, strsplit(inp$ch, ""))
long <- rbindlist(lapply(seq_len(nrow(inp)), function(i) data.table(unit = inp$band[i], k = 1:42, y = as.integer(CH[i, ]))))
long[, `:=`(period = (k - 1L) %/% 6L + 1L, occasion = (k - 1L) %% 6L + 1L, taxon = "AMMHUM")][, k := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 103L * 42L, sum(long$y) == sum(CH == "1"), !anyDuplicated(long[, .(unit, period, occasion)]))
cat(sprintf("  %d birds, %d rows, %d captures, %d birds caught in >1 session\n", nrow(inp), nrow(long), sum(long$y),
            long[y == 1, uniqueN(period), by = unit][V1 > 1, .N]))

taxa <- make_taxa("AMMHUM", "Ammodramus humeralis", vernacularName = "Grassland Sparrow")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:7, note = "capture session of six occasions; calendar dates not deposited (June 2012 to July 2015)")

dataset <- list(
  title = "Robust-design capture histories of 103 adult Grassland Sparrows over seven sessions of six occasions, ESEC Serido, Brazilian Caatinga, 2012-2015",
  creator = "Macario, Phoeve; Toledo-Lima, Guilherme; Pichorim, Mauro",
  pubDate = "2026", doi = "10.5281/zenodo.20130217", sourceURL = "https://doi.org/10.5281/zenodo.20130217",
  citation = "Macario, P., Toledo-Lima, G., & Pichorim, M. (2026). Robust design capture-recapture history of 103 individuals of Grassland Sparrow (Ammodramus humeralis) throughout seven sessions between 2012 and 2015 in the Brazilian Caatinga [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.20130217",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Robust design capture-recapture histories of 103 adult Grassland Sparrows (Ammodramus humeralis) captured and banded on a 12-ha plot with 48 capture sites at the Serido Ecological Station (ESEC Serido), Rio Grande do Norte, Brazil, in seven sessions of six capture occasions each between June 2012 and July 2015, for survival and abundance estimation.",
  samplingProtocol = "Capture and banding at 48 capture sites on a 12-ha plot; seven sessions of six capture occasions each, June 2012 to July 2015 (Program MARK robust design input).",
  samplingProtocolCode = "mist_net", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual", closure = "closed",
  closureNote = "Robust design: the population is assumed closed across the six occasions of a session and open between sessions.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Estacao Ecologica do Serido (ESEC Serido), Rio Grande do Norte, Brazil (12-ha plot; no coordinates deposited)",
  temporalCoverage = "2012-06/2015-07",
  notShipped = list(session_dates = "session dates are not in the deposit"),
  notes = "All birds are adults caught in the wild, so every bird has rows from the first session (E4.4). The capture method is described only as 48 capture sites on a 12-ha plot; mist_net is assumed from the group's companion elaenia deposit.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/macario_2026_serido_sparrow_rd.R")
stage_dict_row(TABLE,
  description = "Robust-design capture histories (7 sessions x 6 occasions) of 103 adult Grassland Sparrows (Ammodramus humeralis) at ESEC Serido, Caatinga, Brazil, 2012-2015.",
  url = "https://doi.org/10.5281/zenodo.20130217", reference = "",
  doi_paper = "", doi_data = "10.5281/zenodo.20130217",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Program MARK .inp; no paper named.", source_via = "Zenodo (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Robust design capture-recapture",
  sampling_protocol = "mist_net", design = "Robust design (7 sessions x 6 occasions)",
  realm = "Terrestrial", country = "BRA", coordinates = "None in source",
  notes = "Session dates not deposited.")
