#!/usr/bin/env Rscript
# Tables: mellado_2021_carollia_tagloss_ms (tag states), mellado_2021_carollia_injury_ms (arm-band injury states)
# Source: Zenodo record 5643915, doi:10.5281/zenodo.5643915 (published 2021-11-03; licence as shown on the record:
#         Creative Commons Attribution 4.0 International).
#   Mellado, B., Carneiro, L. O., Nogueira, M. R. & Monteiro, L. R. Data for Mellado et al. The impacts of marking on
#   bats: mark-recapture models for assessing injury rates and tag loss.
# Paper:  Mellado, B. et al. (2022). Journal of Mammalogy 103: 100-110, doi:10.1093/jmammal/gyab153 (abstract read via
#         Crossref: two colonies of Carollia perspicillata at Uniao Biological Reserve, south-eastern Brazil, 2013-2019,
#         captured every other month; marked with arm bands, collars or both).
# Data:   CapHistTagLoss.txt: 1,598 bats, a 31-character history (A captured with arm band only, C collar only, B both,
#         0 not captured, "." not monitored), sex, forearm length (mm), scaled mass index (g). 355 bats have "." on
#         occasions 14-31 (the colony monitored for 13 occasions), the rest none. CaptHistTagInj.txt: 1,183 arm-banded
#         bats, histories with A no lesion, I minor injury, M major injury, 0, "."; same covariates. LesionOccurrence,
#         RingCondition (time-to-event) and SMI.txt (longitudinal body condition) are derived analysis files.
#         Asserted: histories of 31 characters from the stated alphabets, each with at least one capture; "." only as a
#         trailing block (tag loss file: none, or occasions 14-31; injury file: also 11 bats whose arm-band monitoring
#         ends earlier).
# Mapping: multi-state CJS (E9 core), one table per analysis set (the source deposited them separately). unit = bat
#   ("T0001" / "I0001" in file order: the files carry no ids and cannot be linked), period = capture occasion 1..31
#   (every other month from 2013), y = state (tag loss: 1 A, 2 C, 3 B; injury: 1 A, 2 I, 3 M; 0 not captured), y_raw =
#   the letter. surveyEvidence deposited_matrix ("." = not monitored: no row). Histories start at occasion 1 as
#   deposited (E4.4; the files do not say which bats were marked as juveniles). unit_sex, unit_forearm_mm, unit_smi_g.
# Not shipped: the time-to-event and longitudinal files (derived from the same captures); no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "mellado_2021_carollia_ms"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/5643915", CACHE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"))
rd <- function(f) {
  x <- fread(download_cached(sprintf("https://zenodo.org/api/records/5643915/files/%s/content", f), CACHE, f), skip = "ch\t", colClasses = c(ch = "character"))
  stopifnot(identical(names(x), c("ch", "Sex", "ForL", "SMI")), all(nchar(x$ch) == 31))
  x
}
emit <- function(x, codes, prefix, TABLE, what, n_expect) {
  stopifnot(nrow(x) == n_expect, all(grepl(sprintf("^[0.%s]{31}$", paste(names(codes), collapse = "")), x$ch)), all(grepl(sprintf("[%s]", paste(names(codes), collapse = "")), x$ch)))
  stopifnot(all(grepl("^[^.]*[.]*$", x$ch)))   # "." only as a trailing block (not monitored from then on)
  nd <- table(31 - nchar(sub("[.]+$", "", x$ch)))
  long <- rbindlist(lapply(seq_len(nrow(x)), function(i) {
    ch <- strsplit(x$ch[i], "")[[1]]; k <- which(ch != ".")
    data.table(unit = sprintf("%s%04d", prefix, i), taxon = "CARPER", y = ifelse(ch[k] == "0", 0L, unname(codes[ch[k]])), y_raw = ifelse(ch[k] == "0", "", ch[k]),
               period = k, unit_sex = x$Sex[i], unit_forearm_mm = x$ForL[i], unit_smi_g = round(x$SMI[i], 4))
  }))
  stopifnot(sum(long$y > 0) == sum(nchar(gsub("[0.]", "", x$ch))))
  taxa <- make_taxa("CARPER", "Carollia perspicillata", vernacularName = "Seba's short-tailed bat")
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  sc <- c(list(`0` = "not captured"), setNames(as.list(sprintf("captured, %s", what)), as.character(unname(codes))))
  dataset <- list(
    title = sprintf("Bimonthly multi-state capture histories (%s) of %s Seba's short-tailed bats at two colonies, Uniao Biological Reserve, Brazil, 2013-2019",
                    if (prefix == "T") "tag carried" else "arm-band injury", format(nrow(x), big.mark = ",")),
    creator = "Mellado, B.; Carneiro, L. O.; Nogueira, M. R.; Monteiro, L. R.",
    pubDate = "2021", doi = "10.5281/zenodo.5643915", sourceURL = "https://doi.org/10.5281/zenodo.5643915", paperDOI = "10.1093/jmammal/gyab153",
    citation = "Mellado, B., Carneiro, L. O., Nogueira, M. R. & Monteiro, L. R. (2021). Data for Mellado et al. The impacts of marking on bats: mark-recapture models for assessing injury rates and tag loss. Zenodo, https://doi.org/10.5281/zenodo.5643915.",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = "Two colonies of Carollia perspicillata at Uniao Biological Reserve, south-eastern Brazil, were captured every other month from 2013 to 2019; bats were marked with metal arm bands, ball-chain collars or both, and arm-band injuries were scored, to estimate tag loss, injury rates and their effect on survival.",
    samplingProtocol = "Bimonthly captures at two roost colonies; bats marked with arm bands, collars or both, sexed, measured (forearm) and weighed, and arm-band lesions scored at each recapture.",
    samplingProtocolCode = "roost_capture", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "individual",
    stateCodes = sc, closure = "none", occasionKind = "none", taxonInclusion = "single",
    closureNote = "period = capture occasion (every other month); one colony was monitored for occasions 1-13 only ('.' in the deposit, no rows).",
    geographicCoverage = "Uniao Biological Reserve, south-eastern Brazil (two colonies; per the paper abstract)",
    temporalCoverage = "2013/2019",
    notShipped = list(derived = "LesionOccurrence.txt, RingCondition.txt (time-to-event) and SMI.txt (longitudinal body condition)",
                      link = "the two capture-history files carry no ids and cannot be linked"),
    notes = sprintf("States: %s. Units are anonymous, numbered in file order. unit_smi_g: scaled mass index as deposited.",
                    paste(sprintf("%s = %s", unname(codes), names(codes)), collapse = ", ")))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:31), script = "data/mellado_2021_carollia_ms.R")
  stage_dict_row(TABLE,
    description = sprintf("Multi-state capture histories (%s) of %s Seba's short-tailed bats captured every other month at two colonies in south-eastern Brazil, 2013-2019, with sex, forearm and body condition.",
                          if (prefix == "T") "arm band, collar or both" else "arm-band lesion none, minor or major", format(nrow(x), big.mark = ",")),
    url = "https://doi.org/10.5281/zenodo.5643915",
    reference = "Mellado, B., Carneiro, L. O., Nogueira, M. R. & Monteiro, L. R. (2022). The impacts of marking on bats: mark-recapture models for assessing injury rates and tag loss. Journal of Mammalogy 103: 100-110.",
    doi_paper = "10.1093/jmammal/gyab153", doi_data = "10.5281/zenodo.5643915", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "From the deposited RMark capture-history files.", source_via = "Zenodo")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state CJS", sampling_protocol = "roost_capture",
    design = "Multi-session (31 bimonthly occasions)", realm = "Terrestrial", country = "BRA", coordinates = "None in source",
    notes = "Marking-effect study (tag loss and injury).")
}
emit(rd("CapHistTagLoss.txt"), c(A = 1L, C = 2L, B = 3L), "T", "mellado_2021_carollia_tagloss_ms", c("arm band only", "collar only", "both tags"), 1598)
emit(rd("CaptHistTagInj.txt"), c(A = 1L, I = 2L, M = 3L), "I", "mellado_2021_carollia_injury_ms", c("no lesion", "minor injury", "major injury"), 1183)
