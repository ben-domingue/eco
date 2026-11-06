#!/usr/bin/env Rscript
# Tables: messerman_2020_amb_annulatum_cjs, messerman_2020_amb_maculatum_cjs, messerman_2020_amb_texanum_cjs
#         (one per species, ruling #20)
# Source: Zenodo record 4081978, doi:10.5061/dryad.jm63xsj65 (the Dryad deposit as served by Zenodo, published
#         2020-10-12; licence as shown on the record: CC0 1.0). Fetched from Zenodo, no Dryad request.
#   Messerman, A. F., Semlitsch, R. D. & Leal, M. Data from: Estimating survival for elusive juvenile pond-breeding
#   salamanders.
# Paper:  Messerman, A. F., Semlitsch, R. D. & Leal, M. (2020), Journal of Wildlife Management, doi:10.1002/jwmg.21815 (abstract read via Crossref: an
#         11-month mark-recapture study, 2016-2017, of juveniles of three Ambystoma species in
#         semi-natural enclosures, Bayesian CJS with time-dependent recapture; about a year of opportunistic data was
#         appended afterwards).
# Data:   Ambystoma_Primary.txt (CR line endings): 174 juveniles, a 22-occasion history (1 captured, 0 not), species
#         (AMAN A. annulatum 60, AMMA A. maculatum 60, AMTE A. texanum 54), PIT tag, block (1-5) and pen (enclosure).
#         Abiotic.txt: occasions 1-21 labelled by half-month (early August ... early June) with mean temperature,
#         its sd and precipitation (weather records, not derived from the captures).
#         intervals.txt: the 39 intervals between the 40 occasions of the secondary histories (the first 21 are the
#         primary study's). Ambystoma_Secondary
#         .txt: the same 174 tags with 40-occasion histories (study period plus the appended opportunistic sampling)
#         and mass (their first 22 characters equal the primary history for 170 of the 174 tags). Other files are model code, abiotic covariates, dissections and body-size data.
#         Asserted: 174 unique tags, histories of 22 characters in {0, 1}, every history with a capture, the same tags
#         in both history files.
# Mapping: CJS. unit = PIT tag, cluster_id = pen, period = occasion 1..22, y = captured. The juveniles were marked and
#   released into the enclosures, so a history starts at its first capture (the release; E4.4, marked individuals
#   have no rows before marking) and runs to occasion 22. surveyEvidence deposited_matrix. unit_block; unit_mass_g
#   from the secondary file. __periods: half-month label, interval to the next occasion, temperature, precipitation.
# Not shipped: the 40-occasion secondary histories (they add opportunistic sampling of unstated effort); model code,
#   dissections and body-size files; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "messerman_2020_ambystoma_cjs"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/4081978", CACHE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-zero"), identical(rec$doi, "10.5061/dryad.jm63xsj65"))
rl <- function(f) { x <- readLines(download_cached(sprintf("https://zenodo.org/api/records/4081978/files/%s/content", f), CACHE, f), warn = FALSE)
  x <- unlist(strsplit(paste(x, collapse = "\n"), "[\r\n]+")); x[nzchar(trimws(x))] }
P <- fread(text = rl("Ambystoma_Primary.txt"), colClasses = "character")
S <- fread(text = rl("Ambystoma_Secondary.txt"), colClasses = "character")
iv <- fread(text = rl("intervals.txt"))
ab <- rl("Abiotic.txt")[-1]
ab <- as.data.table(do.call(rbind, regmatches(ab, regexec("^([0-9]+) ((?:Early|Mid) [A-Za-z]+) ([0-9]+) (\\S+) (\\S+) (\\S+)$", ab, perl = TRUE)))[, -1])
setnames(ab, c("row", "period", "event", "tempc", "temp.sd", "precip"))
ab[, event := as.integer(event)]
stopifnot(nrow(P) == 174, !anyDuplicated(P$tag), all(grepl("^[01]{22}$", P$history)), all(grepl("1", P$history)),
          setequal(P$tag, S$tag), nrow(iv) == 39, identical(iv$event, 1:39), identical(as.vector(table(P$spp)[c("AMAN", "AMMA", "AMTE")]), c(60L, 60L, 54L)))
P <- merge(P, S[, .(tag, mass)], by = "tag")
L <- P[, .(period = 1:22, y = as.integer(strsplit(history, "")[[1]])), by = .(tag, spp, block, pen, mass)]
L[, first := min(period[y == 1L]), by = tag]
L <- L[period >= first]
stopifnot(sum(L$y) == sum(nchar(gsub("0", "", P$history))))
stopifnot(nrow(ab) == 21, identical(ab$event, 1:21))
stopifnot(sum(substr(S$history[match(P$tag, S$tag)], 1, 22) == P$history) == 170)
periods <- merge(data.table(period = 1:22, interval_to_next = c(iv$interval[1:21], NA)),
                 ab[, .(period = event, label = period, temp_c = as.numeric(tempc), temp_sd = as.numeric(temp.sd), precip = as.numeric(precip))], by = "period", all.x = TRUE)
info <- list(AMAN = c("Ambystoma annulatum", "Ringed salamander", "messerman_2020_amb_annulatum_cjs"),
             AMMA = c("Ambystoma maculatum", "Spotted salamander", "messerman_2020_amb_maculatum_cjs"),
             AMTE = c("Ambystoma texanum", "Small-mouthed salamander", "messerman_2020_amb_texanum_cjs"))
for (sp in names(info)) {
  nm <- info[[sp]]; TABLE <- nm[3]
  long <- L[spp == sp, .(unit = tag, taxon = sp, y, period, cluster_id = pen, unit_block = as.integer(block), unit_mass_g = as.numeric(mass))]
  taxa <- make_taxa(sp, nm[1], vernacularName = nm[2])
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  nu <- uniqueN(long$unit)
  dataset <- list(
    title = sprintf("Capture histories of %d PIT-tagged juvenile %ss in semi-natural enclosures, half-monthly recaptures over 11 months, 2016-2017", nu, tolower(nm[2])),
    creator = "Messerman, Arianne F.; Semlitsch, Raymond D.; Leal, Manuel",
    pubDate = "2020", doi = "10.5061/dryad.jm63xsj65", sourceURL = "https://doi.org/10.5061/dryad.jm63xsj65", paperDOI = "10.1002/jwmg.21815",
    citation = "Messerman, A. F., Semlitsch, R. D. & Leal, M. (2020). Data from: Estimating survival for elusive juvenile pond-breeding salamanders. Dryad (served by Zenodo), https://doi.org/10.5061/dryad.jm63xsj65.",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Juveniles of three pond-breeding Ambystoma salamanders were PIT-tagged and released into semi-natural terrestrial enclosures, then recaptured over an 11-month mark-recapture study to estimate juvenile survival with Bayesian CJS models.",
    samplingProtocol = "PIT-tagged juvenile salamanders released into replicated semi-natural enclosures (pens within five blocks) and searched for on 22 recapture occasions over 11 months.",
    samplingProtocolCode = "enclosure_recapture", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
    closure = "none", occasionKind = "none", taxonInclusion = "single",
    closureNote = "period = recapture occasion; intervals between occasions in __periods as deposited. Histories start at release.",
    geographicCoverage = "Semi-natural terrestrial enclosures, USA (no location in the deposit)",
    temporalCoverage = "2016/2017",
    notShipped = list(secondary = "Ambystoma_Secondary.txt: 40-occasion histories including appended opportunistic sampling of unstated effort",
                      other = "model code, abiotic covariates, dissections and body-size files"),
    notes = "Enclosure (pen) study of released juveniles; unit_mass_g from the secondary file.")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods[period %in% long$period], script = "data/messerman_2020_ambystoma_cjs.R")
  stage_dict_row(TABLE,
    description = sprintf("Capture histories of %d PIT-tagged juvenile %s (%s) released into semi-natural enclosures and recaptured half-monthly over 11 months (2016-2017).", nu, tolower(nm[2]), nm[1]),
    url = "https://doi.org/10.5061/dryad.jm63xsj65",
    reference = "Messerman, A. F., Semlitsch, R. D. & Leal, M. (2020). Estimating survival for elusive juvenile pond-breeding salamanders. Journal of Wildlife Management.",
    doi_paper = "10.1002/jwmg.21815", doi_data = "10.5061/dryad.jm63xsj65", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Fetched from the Zenodo copy of the Dryad deposit (record 4081978).", source_via = "Zenodo")
  stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS", sampling_protocol = "enclosure_recapture",
    design = "Multi-session (22 occasions)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
    notes = "Semi-natural enclosures; released juveniles.")
}
