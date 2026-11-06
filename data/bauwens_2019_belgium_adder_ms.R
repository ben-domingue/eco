#!/usr/bin/env Rscript
# Table:  bauwens_2019_belgium_adder_ms
# Source: Zenodo record 2527132, doi:10.5281/zenodo.2527132 (published 2018-12-26; licence as shown on the record:
#         Creative Commons Attribution 4.0 International).
#   Bauwens, D. & Claus, K. Raw data for: Intermittent reproduction, mortality patterns and lifetime breeding
#   frequency of females in a population of the adder (Vipera berus).
# Paper:  Bauwens, D. & Claus, K. (2019). PeerJ 7: e6912, doi:10.7717/peerj.6912 (not read; the record's description
#         defines both files).
# Data:   CH_data_AdultFemaleAdders.inp: MARK input, 908 lines, one per adult female adder, an 18-character history
#         (one character per year 2000-2017: B breeding, N non-breeding, 0 not captured) and a group count of 1; no
#         individual labels. SVL_BCI_RawData.xlsx: 584 measurements (IndivCode, year, SVL, mass, body condition,
#         breeding state, season) that cannot be linked to the anonymous MARK lines.
#         Asserted: 908 histories of 18 characters in {B, N, 0}, each with at least one capture, group count 1.
# Mapping: multi-state CJS (E9 core). unit = female ("F001"... in the file's line order), period = year 1..18
#   (2000-2017), y = 0 not captured, 1 captured non-breeding, 2 captured breeding; y_raw = the source letter.
#   surveyEvidence deposited_matrix: the history string has a character for every year of the study; adult females
#   caught in the wild are at risk from 2000 (E4.4), as the MARK file has them.
# Not shipped: SVL_BCI_RawData.xlsx (no key to the histories); no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bauwens_2019_belgium_adder_ms"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/2527132", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"))
inp <- readLines(download_cached("https://zenodo.org/api/records/2527132/files/CH_data_AdultFemaleAdders.inp/content", TABLE, "adders.inp"))
inp <- trimws(inp[nzchar(trimws(inp))])
stopifnot(length(inp) == 908, all(grepl("^[BN0]{18} 1;$", inp)))
h <- substr(inp, 1, 18)
stopifnot(all(grepl("[BN]", h)))
long <- rbindlist(lapply(seq_along(h), function(i) {
  ch <- strsplit(h[i], "")[[1]]
  data.table(unit = sprintf("F%03d", i), taxon = "VIPBER", y = unname(c(`0` = 0L, N = 1L, B = 2L)[ch]), y_raw = ifelse(ch == "0", "", ch), period = 1:18)
}))
stopifnot(nrow(long) == 908 * 18, sum(long$y > 0) == sum(nchar(gsub("0", "", h))))
periods <- data.table(period = 1:18, year = 2000:2017)
taxa <- make_taxa("VIPBER", "Vipera berus", vernacularName = "Adder")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Annual capture and breeding-state histories of 908 adult female adders in a Belgian population, 2000-2017",
  creator = "Bauwens, Dirk; Claus, Katja",
  pubDate = "2018", doi = "10.5281/zenodo.2527132", sourceURL = "https://doi.org/10.5281/zenodo.2527132", paperDOI = "10.7717/peerj.6912",
  citation = "Bauwens, D. & Claus, K. (2018). Raw data for: Intermittent reproduction, mortality patterns and lifetime breeding frequency of females in a population of the adder (Vipera berus). Zenodo, https://doi.org/10.5281/zenodo.2527132.",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Adult female adders of one Belgian population were captured each year from 2000 to 2017 and scored as breeding or non-breeding, to estimate survival and transition rates between reproductive states (intermittent reproduction).",
  samplingProtocol = "Yearly capture-recapture of adders by visual search in spring and late summer; adult females individually identified and scored as breeding (gravid) or non-breeding.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not captured", `1` = "captured, non-breeding (N)", `2` = "captured, breeding (B)"),
  closure = "none", occasionKind = "none", taxonInclusion = "single",
  closureNote = "period = year; the MARK histories start in 2000 for every female.",
  geographicCoverage = "One adder population in Belgium",
  temporalCoverage = "2000/2017",
  notShipped = list(svl_bci = "SVL_BCI_RawData.xlsx: size, mass and body condition per measured female (no key to the anonymous MARK histories)"),
  notes = "Units are anonymous (the MARK file has no labels); F001... follow the file's line order.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/bauwens_2019_belgium_adder_ms.R")
stage_dict_row(TABLE,
  description = "Multi-state (non-breeding / breeding) annual capture histories of 908 adult female adders (Vipera berus) in one Belgian population, 2000-2017.",
  url = "https://doi.org/10.5281/zenodo.2527132",
  reference = "Bauwens, D. & Claus, K. (2019). Intermittent reproduction, mortality patterns and lifetime breeding frequency of females in a population of the adder (Vipera berus). PeerJ 7: e6912.",
  doi_paper = "10.7717/peerj.6912", doi_data = "10.5281/zenodo.2527132", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "From the deposited MARK .inp file.", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Multi-state CJS", sampling_protocol = "visual_encounter",
  design = "Multi-season (18 years)", realm = "Terrestrial", country = "BEL", coordinates = "None in source",
  notes = "Intermittent reproduction in a viviparous snake.")
