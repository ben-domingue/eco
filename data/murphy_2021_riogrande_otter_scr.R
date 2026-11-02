#!/usr/bin/env Rscript
# Table:  murphy_2021_riogrande_otter_scr
# Source: Dryad doi:10.5061/dryad.kkwh70s51 (CC0 1.0), version 241119 (published 2022-09-17)
#   Murphy, S. M. & Cox, J. J. (2021). Data from: Evaluating otter reintroduction outcomes
#   using genetic spatial capture-recapture modified for dendritic networks. Dryad.
# Paper:  Murphy, S. M., Adams, J. R., Waits, L. P. & Cox, J. J. (2021). Evaluating otter
#         reintroduction outcomes using genetic spatial capture-recapture modified for
#         dendritic networks. Ecology and Evolution 11, 15047-15061. doi:10.1002/ece3.8187
#         (open access, CC BY 4.0; read in full on Europe PMC, PMC8571598).
# Data:   four files. Murphy_et_al_Otter_Genotypes_Detections.xlsx, sheet "Genotypes": a
#         four-line colour legend, then a block of 77 genotyped fecal samples of Upper Rio
#         Grande otters with two individual-id columns ("Conservative": 30 individuals,
#         samples matching at >= 8 loci; "Lenient": 37, genotypes differing at one locus
#         split), filled down as merged cells, Latrine ID, Sampling Occasion (1-8),
#         Sample ID, Sex per sample (F / M confirmed / U unconfirmed male), number of
#         amplifications, a reliability score, 20 allele columns and notes; below it the
#         19 Washington source-population tissue genotypes. The legend's colour codes
#         (an allele seen once, a duplicate sample) are cell fills, not values, and are not
#         read. Murphy_et_al_Otter_Latrine_Locations.xlsx: 20 latrines with UTM eastings and
#         northings and a Usage string of 8 digits (one per occasion; Excel dropped the
#         leading zeros of six of them, restored by left-padding to 8, which the detections
#         confirm). Murphy_et_al_Otter_Genotyping_Error_Rates.xlsx: per-locus PIsibs and
#         error rates (not detection data). Murphy_et_al_Otter_Metadata.docx: one paragraph
#         per file.
#         Asserted below: 77 sample rows, 30 conservative and 37 lenient individuals with
#         lenient nested in conservative, occasions 1-8, 20 latrines with 123 used
#         latrine-occasions, every detection but one at a latrine-occasion with usage 1,
#         UTM ranges in zone 13N over the Rio Grande gorge.
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture, closed population,
#   genetic (scat) detections at latrines):
#   unit = individual otter under the LENIENT matching rule (L01..L37), the finer partition;
#   unit_conservative_id carries the conservative individual (C01..C30), constant within
#   each lenient individual (asserted), so the authors' preferred conservative history is a
#   deterministic collapse (merge units by unit_conservative_id, y = max). trap = latrine
#   (the deposit's id), occasion = survey occasion 1-8 (7-10 day revisits, Feb-Apr 2018),
#   one session (period omitted), y = 1 if at least one genotyped sample of the individual
#   came from that latrine on that occasion, y_raw = the number of genotyped samples (the
#   deposit lists each sample; "duplicate" samples in the legend's sense collapse here).
#   Survey set = effort_table: the Usage string, a latrine-occasion is surveyed iff its
#   digit is 1 (123 of 160). Full rectangle 37 x 123 (BATCH_LOG batch 5 convention).
#   unit_sex: M if any sample of the individual is a confirmed male (the paper's rule),
#   F if every sample is F, U otherwise (unconfirmed male or conflicting F/U samples); the
#   paper's own tallies (lenient 17 M, 18 F, 2 unconfirmed M) are not exactly reproduced
#   by any per-sample rule, so the rule is stated, not asserted. unitKind = individual.
#   __traps: trap, x, y (UTM zone 13N metres as deposited), n_occasions_used. Otter is IUCN
#   Least Concern; coordinates kept as published.
#   NOT shipped: one detection (sample 11ZYJ, conservative Lcan08 / lenient Lcan13,
#   occasion 2) recorded at "RGDB03", a latrine that is not among the 20 surveyed latrines
#   of the deposit or the paper (no coordinates, no usage), so it has no survey row; the
#   individual keeps its three other detections. Also not shipped: the allele columns,
#   amplification counts and reliability scores (genotyping, not detection), the Washington
#   tissue genotypes (no detection design), the error-rate workbook.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "murphy_2021_riogrande_otter_scr"
SCRIPT <- "data/murphy_2021_riogrande_otter_scr.R"
dir <- download_dryad("10.5061/dryad.kkwh70s51", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Murphy_et_al_Otter_Genotypes_Detections.xlsx", "Murphy_et_al_Otter_Genotyping_Error_Rates.xlsx",
                                      "Murphy_et_al_Otter_Latrine_Locations.xlsx", "Murphy_et_al_Otter_Metadata.docx")))

# --- latrines and usage (the survey set) ---------------------------------------------------
lat <- as.data.table(read_excel(file.path(dir, "Murphy_et_al_Otter_Latrine_Locations.xlsx"), col_types = "text"))
stopifnot(identical(names(lat), c("Latrine_ID", "UTM_E", "UTM_N", "Usage")), nrow(lat) == 20, !anyDuplicated(lat$Latrine_ID),
          all(nchar(lat$Usage) %in% c(6L, 8L)), all(grepl("^[01]+$", lat$Usage)))
lat[, usage8 := sprintf("%08d", as.integer(Usage))]                        # Excel dropped leading zeros
lat[, `:=`(x = as.numeric(UTM_E), y = as.numeric(UTM_N))]
stopifnot(all(lat$x > 427e3 & lat$x < 442e3), all(lat$y > 4013e3 & lat$y < 4095e3))   # UTM 13N, Rio Grande gorge, NM
usage <- lat[, .(occasion = 1:8, used = as.integer(strsplit(usage8, "")[[1]])), by = .(trap = Latrine_ID)][used == 1L]
stopifnot(nrow(usage) == 123)
traps <- lat[, .(trap = Latrine_ID, x, y, n_occasions_used = nchar(gsub("0", "", usage8)))]

# --- genotyped samples ----------------------------------------------------------------------
g <- as.data.table(read_excel(file.path(dir, "Murphy_et_al_Otter_Genotypes_Detections.xlsx"), sheet = "Genotypes",
                              col_types = "text", skip = 8, n_max = 77, .name_repair = "minimal"))
stopifnot(identical(names(g)[1:8], c("Conservative", "Lenient", "Latrine ID", "Sampling Occasion", "Sample ID", "Sex", "#Amplifications", "Reliability")),
          nrow(g) == 77)
g <- g[, 1:8]; setnames(g, c("cons", "len", "trap", "occasion", "sample", "sex", "n_amp", "reliability"))
fill <- function(x) { i <- cumsum(!is.na(x)); x[!is.na(x)][i] }                       # merged cells: id on the first row of a block
g[, cons := fill(cons)][, len := fill(len)][, occasion := as.integer(occasion)]
stopifnot(!anyNA(g), uniqueN(g$cons) == 30, uniqueN(g$len) == 37, all(g$occasion %in% 1:8), all(g$sex %in% c("F", "M", "U")),
          !anyDuplicated(g$sample), all(g[, uniqueN(cons), by = len]$V1 == 1))         # lenient nests within conservative
stopifnot(identical(sort(unique(g$trap)), sort(c(setdiff(lat$Latrine_ID, c("RGBL14", "RGDB02")), "RGDB03"))))
# every detection falls on a used latrine-occasion, except the one at RGDB03 (not a surveyed latrine)
chk <- merge(g, usage, by = c("trap", "occasion"), all.x = TRUE)
bad <- chk[is.na(used)]
stopifnot(nrow(bad) == 1, bad$trap == "RGDB03", bad$occasion == 2L, bad$sample == "11ZYJ")
dropped <- g[trap == "RGDB03"]
g <- g[trap != "RGDB03"]
cat(sprintf("  77 genotyped samples, 30 conservative / 37 lenient individuals; 1 sample at unsurveyed latrine RGDB03 not shipped\n"))

# --- individuals: lenient ids, conservative id, sex -----------------------------------------
ids <- unique(g[, .(len, cons)])
ids <- merge(ids, data.table(len = sort(unique(g$len)), unit = sprintf("L%02d", seq_along(unique(g$len)))), by = "len")
ids <- merge(ids, data.table(cons = sort(unique(g$cons)), cons_id = sprintf("C%02d", seq_along(unique(g$cons)))), by = "cons")
sexr <- function(s) if (any(s == "M")) "M" else if (all(s == "F")) "F" else "U"
sx <- g[, .(sex = sexr(sex)), by = len]
inds <- merge(ids, sx, by = "len")[order(unit), .(unit, cons_id, sex)]
stopifnot(nrow(inds) == 37, uniqueN(inds$cons_id) == 30)
cat(sprintf("  sex by the paper's rule (lenient): %s\n", paste(names(table(inds$sex)), table(inds$sex), sep = "=", collapse = ", ")))

# --- detections: collapse samples to individual x latrine x occasion -------------------------
enc <- merge(g, ids[, .(len, unit)], by = "len")[, .(n_samples = .N), by = .(unit, trap, occasion)]
stopifnot(sum(enc$n_samples) == 76, nrow(enc) == 69, nrow(enc) - 37 == 32)                 # the paper: 32 lenient recaptures
cat(sprintf("  %d detections (individual x latrine x occasion) from %d samples; %d spatial/temporal recaptures of 37 lenient individuals\n",
            nrow(enc), sum(enc$n_samples), nrow(enc) - 37))

# --- the rectangle: individual x used latrine-occasion ----------------------------------------
long <- CJ(unit = inds$unit, i = seq_len(nrow(usage)))
long <- cbind(long[, .(unit)], usage[long$i, .(trap, occasion)])
long <- merge(long, enc, by = c("unit", "trap", "occasion"), all.x = TRUE)
long[is.na(n_samples), n_samples := 0L]
long <- merge(long, inds, by = "unit")
stopifnot(nrow(long) == 37 * 123, sum(long$n_samples) == 76, sum(long$n_samples > 0) == 69)
long <- long[, .(unit, taxon = "LONCAN", y = as.integer(n_samples > 0), y_raw = n_samples, trap, occasion,
                 unit_conservative_id = cons_id, unit_sex = sex)]
long <- order_eco(long)

taxa <- make_taxa("LONCAN", "Lontra canadensis", vernacularName = "North American river otter", taxon_iucnCategory = "LC")

dataset <- list(
  title = "Genetic spatial capture-recapture of river otters at 20 latrines, Upper Rio Grande, New Mexico, 2018: 37 individuals x 20 latrines x 8 occasions",
  creator = "Murphy, Sean M.; Adams, Jennifer R.; Waits, Lisette P.; Cox, John J.",
  pubDate = "2022", doi = "10.5061/dryad.kkwh70s51", sourceURL = "https://doi.org/10.5061/dryad.kkwh70s51",
  citation = "Murphy, S. M., & Cox, J. J. (2021). Data from: Evaluating otter reintroduction outcomes using genetic spatial capture-recapture modified for dendritic networks [Data set]. Dryad. https://doi.org/10.5061/dryad.kkwh70s51",
  paperDOI = "10.1002/ece3.8187",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Non-invasive genetic detections of individually identified North American river otters (Lontra canadensis) from scats collected at 20 latrines along 259 km of the Upper Rio Grande dendritic network, northern New Mexico, over eight survey occasions at 7-10 day intervals in February-April 2018, ten years after a 33-otter reintroduction. The deposit lists each genotyped sample with its latrine, occasion and sex, under two individual-matching rules (conservative, 30 individuals; lenient, 37, splitting genotypes that differ at one locus), and the latrine coordinates with a per-occasion usage string. The table is one row per lenient individual x surveyed latrine-occasion, y = 1 where at least one of the individual's samples came from that latrine on that occasion, y_raw = the number of samples; unit_conservative_id gives the coarser individual so the conservative history can be rebuilt by merging units. 37 individuals, 69 detections at 18 latrines, 76 samples.",
  samplingProtocol = "Scats and anal jellies collected at active otter latrines found in a 14-day scouting period (latrines cleared), then revisited at 7-10 day intervals for eight occasions; 3-4 samples per latrine-occasion genotyped at 10 microsatellite loci plus the SRY2 sex marker; individuals matched at >= 8 loci (conservative) or split where genotypes differed at one locus (lenient).",
  samplingProtocolCode = "scat_genotyping", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The latrine file's Usage string gives, per latrine, one digit per occasion (1 surveyed); 123 of 160 latrine-occasions were surveyed. Every individual carries all 123, including occasions without a detection. Excel dropped the leading zeros of six strings; left-padding to eight digits is the only padding under which every detection falls on a surveyed latrine-occasion.",
  responseType = "detection", unitKind = "individual",
  closure = "single session (one period, omitted): the eight occasions are treated as a closed population, as in the authors' SCR; occasion = survey occasion 1-8",
  geographicCoverage = "Upper Rio Grande River Basin, Taos County, New Mexico, USA; 20 latrines along 259 km of the Rio Grande and tributaries, coordinates in __traps (UTM zone 13N)",
  temporalCoverage = "2018-02/2018-04",
  crs = "EPSG:26913 or EPSG:32613 (UTM zone 13N, metres); the deposit says 'UTMs' without a zone or datum, zone 13N follows from the coordinate range over the Rio Grande gorge",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: river otter is IUCN Least Concern; latrine locations are the authors' own survey sites"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Closed population, eight occasions, genetic (scat) detections at latrines. The authors fit the secr network-distance (non-Euclidean) detection function on a one-dimensional dendritic state space of 359 river km; the state space and the river network are analysis inputs, not shipped (USGS NHD perennial waterways). unit is the lenient individual; the conservative history the authors prefer is the collapse by unit_conservative_id.",
  notes = "Occasion calendar dates are not deposited (the paper gives February-April 2018, 7-10 day intervals). unit_sex: M if any sample is a confirmed male (the paper's rule), F if all samples are F, U otherwise (unconfirmed male or F/U conflict); the paper reports 17 M, 18 F, 2 unconfirmed M under the lenient rule, which no per-sample rule reproduces exactly from the deposited sex column. The paper counts 77 detections (one per genotyped sample); collapsed to distinct individual x latrine x occasion the lenient history has 69 detections and 32 recaptures, which matches the paper's 32; the conservative collapse gives 37 recaptures against the paper's 41, a difference not resolved from the deposit.",
  notShipped = list(`RGDB03 detection` = "sample 11ZYJ (lenient Lcan13 / conservative Lcan08, occasion 2) is recorded at latrine RGDB03, which is not among the 20 surveyed latrines in the latrine file or the paper (no coordinates, no usage); no survey row exists for it",
                    `allele columns, #Amplifications, Reliability, Notes` = "genotyping detail behind the individual assignments, not detection data",
                    `Washington source-population genotypes` = "19 tissue genotypes with no detection design",
                    Murphy_et_al_Otter_Genotyping_Error_Rates.xlsx = "per-locus PIsibs and error rates"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Genetic (scat) spatial capture-recapture detections of 37 river otters at 20 latrines over 8 occasions, Upper Rio Grande, New Mexico, 2018 (one row per otter x surveyed latrine-occasion), with UTM latrine coordinates in __traps and the conservative individual id as a unit covariate.",
  url = "https://doi.org/10.5061/dryad.kkwh70s51",
  reference = "Murphy, S. M., Adams, J. R., Waits, L. P., & Cox, J. J. (2021). Evaluating otter reintroduction outcomes using genetic spatial capture-recapture modified for dendritic networks. Ecology and Evolution, 11, 15047-15061.",
  doi_paper = "10.1002/ece3.8187", doi_data = "10.5061/dryad.kkwh70s51",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population genetic SCR (E9 experimental): trap key + __traps; the authors used a dendritic (network-distance) state space, not shipped. unit = lenient individual (37); unit_conservative_id collapses to the authors' preferred 30. One detection at an unlisted latrine not shipped.",
  source_via = "Dryad (version zip, xlsx)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic, dendritic network)",
  sampling_protocol = "scat_genotyping", design = "Single-season (8 occasions, 20 latrines)", realm = "Freshwater",
  country = "USA", coordinates = "As published (latrine coordinates in __traps, UTM 13N)",
  notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle. Two individual-matching rules in the deposit: lenient as unit, conservative as unit covariate.")
