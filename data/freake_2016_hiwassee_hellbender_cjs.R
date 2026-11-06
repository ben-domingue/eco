#!/usr/bin/env Rscript
# Table:  freake_2016_hiwassee_hellbender_cjs
# Source: Harvard Dataverse doi:10.7910/DVN/YWYWFN, deposited 2016-10-18, released 2016-11-28, licence CC0 1.0 (the
#         dataset's license field, asserted from the cached dataset JSON).
#   Freake, M. (2016). Hiwassee hellbenders mark recapture encounters [Dataset]. Harvard Dataverse.
# Paper:  none named ("Program MARK input text file for hellbender encounters 2004-2008").
# Data:   benders16input.inp (datafile 2903782): one line per marked hellbender, "<5-character 0/1 history>\t1;",
#         one character per year 2004-2008, frequency 1 on every line, no comments, ids or covariates. Every
#         history has a capture (asserted). Hiwassee River (Tennessee / North Carolina, USA) per the title.
# Mapping (CJS): unit = the line number ("hb_<n>"), taxon = CRYALL, period = year (1 = 2004 ... 5 = 2008), y = 0/1.
#   Every animal was caught in the wild at unknown age, so it is at risk from 2004 (E4.4): 5 rows each.
#   surveyEvidence = deposited_matrix. No coordinates deposited; Cryptobranchus alleganiensis is IUCN VU, so the
#   absence of locations matters only as a fact (E7 does not arise).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "freake_2016_hiwassee_hellbender_cjs"
meta_f <- file.path(RAW_DIR, TABLE, "dataverse_dataset.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file("https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/YWYWFN",
                                        meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)$data$latestVersion
stopifnot(identical(meta$license$name, "CC0 1.0"), identical(meta$files$dataFile$id, 2903782L),
          identical(meta$files$dataFile$filename, "benders16input.inp"))
f <- download_cached("https://dataverse.harvard.edu/api/access/datafile/2903782?format=original", TABLE, filename = "benders16input.inp")
l <- trimws(readLines(f, warn = FALSE)); l <- l[nzchar(l)]
m <- regmatches(l, regexec("^([01]{5})\\s+1;$", l))
stopifnot(all(lengths(m) == 2L), length(l) == 197L)
ch <- sapply(m, `[`, 2); stopifnot(all(grepl("1", ch)))
H <- do.call(rbind, strsplit(ch, ""))
long <- data.table(unit = rep(sprintf("hb_%03d", seq_along(ch)), each = 5L), period = rep(1:5, length(ch)), y = as.integer(t(H)), taxon = "CRYALL")
long <- order_eco(long)
stopifnot(nrow(long) == 197L * 5L, sum(long$y) == sum(H == "1"))
cat(sprintf("  %d hellbenders, %d captures; first caught in 2004: %d\n", length(ch), sum(long$y), sum(H[, 1] == "1")))
taxa <- make_taxa("CRYALL", "Cryptobranchus alleganiensis", vernacularName = "Hellbender")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))
periods <- data.table(period = 1:5, year = 2004:2008)
dataset <- list(
  title = "Annual capture histories of 197 hellbenders, Hiwassee River, 2004-2008",
  creator = "Freake, Michael", pubDate = "2016", doi = "10.7910/DVN/YWYWFN", sourceURL = "https://doi.org/10.7910/DVN/YWYWFN",
  citation = "Freake, M. (2016). Hiwassee hellbenders mark recapture encounters [Dataset]. Harvard Dataverse. https://doi.org/10.7910/DVN/YWYWFN",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Program MARK input of annual encounter histories of eastern hellbenders (Cryptobranchus alleganiensis) marked and recaptured in the Hiwassee River, 2004-2008.",
  samplingProtocol = "Annual hand-capture surveys of hellbenders (searching under rocks in the river), individuals marked and recaptured; one encounter occasion per year.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "one annual occasion per year",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Hiwassee River, southeastern USA (no locations deposited)", temporalCoverage = "2004/2008",
  notShipped = list(locations = "no capture locations, sizes or sexes are deposited"),
  notes = "The deposit is a bare MARK history file; the search method is not described in it (hand capture under cover is the standard hellbender method, assumed for the protocol code).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/freake_2016_hiwassee_hellbender_cjs.R")
stage_dict_row(TABLE,
  description = "Annual CJS capture histories of 197 eastern hellbenders (Cryptobranchus alleganiensis) in the Hiwassee River, 2004-2008.",
  url = "https://doi.org/10.7910/DVN/YWYWFN", reference = "", doi_paper = "", doi_data = "10.7910/DVN/YWYWFN",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "Program MARK .inp; no covariates.",
  source_via = "Harvard Dataverse (access API)")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-season (5 years, 2004-2008)",
  realm = "Freshwater", country = "USA", coordinates = "None in source", notes = "IUCN VU; no locations deposited.")
