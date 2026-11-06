#!/usr/bin/env Rscript
# Tables: saracco_2019_saipan_<species>_cjs for five species (fantail, goldwhiteeye, bridwhiteeye,
#         kingfisher, myzomela)
# Source: Harvard Dataverse doi:10.7910/DVN/5SW2HJ, deposited and released 2019-09-27, licence CC0 1.0 (the dataset's
#         license field, asserted from the cached dataset JSON).
#   Saracco, J. (2019). Replication data for Recent dynamics and trends of landbird populations on Saipan, Northern
#   Marianas Islands [Dataset]. Harvard Dataverse.
# Paper:  "Saracco, J. F., et al. Recent dynamics and trends of landbird populations on Saipan, Northern Marianas
#         Islands. to be submitted to Pacific Science" (the dataset's publication field); not found published.
# Data:   ch.tab (datafile 3594617, original ch.csv): 2,196 rows, SPEC (BRWE, GOWE, MICK, MIHO, RUFA), STATION (BICA,
#           KIFI, LATA, MTAP, OBYA, SATA), BAND, 2008 ... 2018 (0/1 captured that year). Every row has a capture.
#           4 rows have no band number; one band (MICK 162361744) has a row at BICA and one at LATA, both captured
#           only in 2016 (one bird caught at two stations, kept as the source's two histories).
#         ecov.tab (standardized effort) and int.tab (interval length, standardized): 7 x 11 and 7 x 10 numeric
#           matrices with no row key, while ch has 6 stations; not shipped (rows cannot be assigned to stations).
#         SAIP2018_dv.R: the authors' JAGS reverse-symmetry (Pradel-type) model; names the codes: RUFA Rufous
#           fantail, GOWE Golden white-eye, BRWE Bridled white-eye, MICK Marianas kingfisher (previously Micronesian
#           kingfisher), MIHO Micronesian myzomela (previously Micronesian honeyeater). The script's description:
#           "Saipan TMAPS data" (Tropical Monitoring Avian Productivity and Survivorship mist-netting).
# Mapping (CJS, one table per species, ruling #20): unit = "<STATION>_<BAND>" ("<STATION>_noband<n>" where BAND is
#   empty), cluster_id = STATION, taxon = the source code, period = year (1 = 2008 ... 11 = 2018), y = 0/1. No age
#   is deposited, so every bird is treated as caught in the wild at unknown age and at risk from 2008 (E4.4).
#   surveyEvidence = deposited_matrix. No coordinates deposited (station codes only); Golden white-eye is IUCN CR/EN,
#   but there are no coordinates, so E7 does not arise.
#   Not shipped: ecov and int (no station key, 7 rows for 6 stations); the authors' model estimates.
#   BRWE is given the scientific name Zosterops saypani: the source names it only "Bridled white-eye"; on Saipan that
#   population is now Z. saypani, while Z. conspicillatus in the narrow sense is the extinct Guam white-eye (taxonRemarks).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/saracco_2019_saipan_cjs.R"; CACHE <- "saracco_2019_saipan_cjs"
meta_f <- file.path(RAW_DIR, CACHE, "dataverse_dataset.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file("https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/5SW2HJ",
                                        meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)$data$latestVersion
stopifnot(identical(meta$license$name, "CC0 1.0"), setequal(meta$files$dataFile$id, c(3594617L, 3594614L, 3594615L, 3594616L)))
dv <- function(id, fn) download_cached(sprintf("https://dataverse.harvard.edu/api/access/datafile/%d?format=original", id), CACHE, filename = fn)
ch <- fread(dv(3594617L, "ch.csv"), colClasses = list(character = c("SPEC", "STATION", "BAND")))
ec <- fread(dv(3594614L, "ecov.csv")); it <- fread(dv(3594615L, "int.csv")); invisible(dv(3594616L, "SAIP2018_dv.R"))
YRS <- as.character(2008:2018)
stopifnot(identical(names(ch), c("SPEC", "STATION", "BAND", YRS)), nrow(ch) == 2196L,
          setequal(ch$SPEC, c("BRWE", "GOWE", "MICK", "MIHO", "RUFA")),
          setequal(ch$STATION, c("BICA", "KIFI", "LATA", "MTAP", "OBYA", "SATA")),
          all(as.matrix(ch[, ..YRS]) %in% 0:1), all(rowSums(ch[, ..YRS]) > 0),
          sum(is.na(ch$BAND) | ch$BAND == "") == 4L, dim(ec) == c(7L, 11L), dim(it) == c(7L, 10L))
ch[is.na(BAND) | BAND == "", BAND := paste0("noband", seq_len(.N))]
ch[, unit := paste(STATION, BAND, sep = "_")]
stopifnot(!anyDuplicated(ch$unit), ch[, .N, by = .(SPEC, BAND)][N > 1, .N] == 1L)
sp <- data.table(code = c("RUFA", "GOWE", "BRWE", "MICK", "MIHO"),
                 name = c("fantail", "goldwhiteeye", "bridwhiteeye", "kingfisher", "myzomela"),
                 sci = c("Rhipidura rufifrons", "Cleptornis marchei", "Zosterops saypani", "Todiramphus albicilla", "Myzomela rubratra"),
                 vern = c("Rufous fantail", "Golden white-eye", "Bridled white-eye", "Mariana kingfisher", "Micronesian myzomela"),
                 n = c(1077L, 486L, 414L, 85L, 134L))
stopifnot(identical(ch[, .N, by = SPEC][match(sp$code, SPEC), N], sp$n))
for (i in seq_len(nrow(sp))) {
  S <- sp[i]; TABLE <- sprintf("saracco_2019_saipan_%s_cjs", S$name)
  d <- ch[SPEC == S$code]
  long <- melt(d, id.vars = c("unit", "STATION"), measure.vars = YRS, variable.name = "yr", value.name = "y")
  long[, `:=`(period = match(as.character(yr), YRS), taxon = S$code, cluster_id = STATION, y = as.integer(y))][, c("yr", "STATION") := NULL]
  long <- order_eco(long)
  stopifnot(nrow(long) == S$n * 11L, sum(long$y) == sum(as.matrix(d[, ..YRS])))
  taxa <- make_taxa(S$code, S$sci, vernacularName = S$vern,
                    taxonRemarks = if (S$code == "MICK") "source: Marianas kingfisher (previously Micronesian kingfisher)" else if (S$code == "MIHO") "source: Micronesian myzomela (previously Micronesian honeyeater)" else if (S$code == "BRWE") "source: Bridled white-eye (code BRWE); the Saipan population of the former Zosterops conspicillatus, now Zosterops saypani (Saipan white-eye); Z. conspicillatus in the narrow sense is the extinct Guam white-eye" else NA_character_)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  print(taxa[, .(taxon, scientificName, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
  periods <- data.table(period = 1:11, year = 2008:2018)
  cat(sprintf("  %s: %d birds, %d rows, %d captures\n", TABLE, S$n, nrow(long), sum(long$y)))
  dataset <- list(
    title = sprintf("Annual mist-net capture histories of %d %ss at six TMAPS stations, Saipan, 2008-2018", S$n, S$vern),
    creator = "Saracco, James", pubDate = "2019", doi = "10.7910/DVN/5SW2HJ", sourceURL = "https://doi.org/10.7910/DVN/5SW2HJ",
    citation = "Saracco, J. (2019). Replication data for Recent dynamics and trends of landbird populations on Saipan, Northern Marianas Islands [Dataset]. Harvard Dataverse. https://doi.org/10.7910/DVN/5SW2HJ",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Annual capture histories of five landbird species banded at six Tropical Monitoring Avian Productivity and Survivorship (TMAPS) mist-netting stations on Saipan, Northern Mariana Islands, 2008-2018, deposited with the authors' JAGS reverse-symmetry model of survival and population growth.",
    samplingProtocol = "Constant-effort mist netting at TMAPS stations; birds banded and recaptured; captures pooled to one annual occasion per year and station.",
    samplingProtocolCode = "mist_net", surveyEvidence = "deposited_matrix",
    responseType = "detection", unitKind = "individual", closure = "none", closureNote = "one annual occasion per year",
    occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = "Saipan, Northern Mariana Islands (six stations: BICA, KIFI, LATA, MTAP, OBYA, SATA; no coordinates deposited)",
    temporalCoverage = "2008/2018",
    notShipped = list(effort_interval = "ecov.csv (standardized effort) and int.csv (interval length): 7-row matrices with no station key for 6 stations",
                      age_sex = "no age or sex deposited", model_output = "the authors' survival and population growth estimates"),
    notes = paste("Unit = station x band; cluster_id = the station. No age is deposited, so every bird has rows from 2008 (E4.4).",
                  if (S$code == "MICK") "Band 162361744 has a history at BICA and at LATA (both 2016 only): kept as the source's two histories." else "",
                  if (any(grepl("noband", d$unit))) "Rows with no band number in the source have unit '<station>_noband<n>'." else ""))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Annual CJS capture histories of %d %ss (%s) at six TMAPS mist-netting stations on Saipan, 2008-2018.", S$n, S$vern, S$sci),
    url = "https://doi.org/10.7910/DVN/5SW2HJ", reference = "", doi_paper = "", doi_data = "10.7910/DVN/5SW2HJ",
    original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "One table per species (ruling #20); effort covariates not shipped (no station key).",
    source_via = "Harvard Dataverse (access API)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
    sampling_protocol = "mist_net", design = "Multi-season (11 years, 6 stations)",
    realm = "Terrestrial", country = "MNP", coordinates = "None in source", notes = "TMAPS mist netting; station as cluster_id.")
}
