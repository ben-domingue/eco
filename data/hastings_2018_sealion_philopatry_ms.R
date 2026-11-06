#!/usr/bin/env Rscript
# Tables: hastings_2018_seak_philopatry_ms, hastings_2018_forrester_philopatry_ms
# Source: Dryad doi:10.5061/dryad.48j0m, version 17509 (published 2018-04-21), CC0 1.0 (asserted from the Dryad
#         metadata). Hastings, K. K., Jemison, L. A., Pendleton, G. W., Raum-Suryan, K. L. & Pitcher, K. W. Data
#         from: Natal and breeding philopatry of female Steller sea lions in southeastern Alaska. Raw files read
#         from batch 37's cache (no Dryad request in batch 47).
# Paper:  Hastings, K. K., Jemison, L. A., Pendleton, G. W., Raum-Suryan, K. L. & Pitcher, K. W. (2017). Natal
#         and breeding philopatry of female Steller sea lions in southeastern Alaska. PLoS ONE 12, e0176840.
#         doi:10.1371/journal.pone.0176840 (open access; PDF supplied by Ben, not committed). Pups were branded at
#         four rookeries of southeastern Alaska (SEAK: F Forrester Island Complex, H Hazy Islands, W White
#         Sisters, G Graves Rocks; none at B Biali Rocks) in 1994-95 and 2001-05; branded females were resighted
#         May-July 2001-15. Multiple sightings of a female definitively with a pup in a year are one annual
#         sighting, coded as a letter for where she was seen with a pup, else 0. "To address natal philopatry,
#         we artificially created sightings at the natal location in the year prior to females' first year
#         observed with pup, and these served as females' first release" (S and p of the next occasion fixed to
#         1). SEAK analysis: 15 years 2001-15, 369 females (one, W330, excluded), states F, H, B, W, G. F analysis:
#         11 years (2004-15 except 2006, when data collection was halted by injunction), 183 females seen with a
#         pup at F, states LN (Lowrie Island north), LS (Lowrie Island south), CHR (Cape Horn Rocks), SLR (Sea
#         Lion Rocks), NR (North Rocks), ER (East Rocks), and X for the 7 females born at H or W; no pups were
#         branded at LS or ER. Natal sample sizes: SEAK 220 F, 67 H, 60 W, 22 G; F 54 LI, 44 CHR, 16 SLR, 62 NR.
# Data:   SEAK.prn (ch, byr): 369 histories of 15 letters (0, F, H, V, W, Z) with birth year; FI.prn (ch, byr):
#         183 histories of 11 letters (0, C, E, L, N, R, S, X). The letters are not defined in the deposit. They
#         are resolved by the paper's natal counts, since every history starts with the artificial natal sighting
#         (asserted: the first letters are SEAK F 220, H 67, W 60, V 22; FI N 54, C 44, L 16, R 62, X 7):
#         SEAK V = G (Graves Rocks; hastings_2018_seak_sealion_cjs, the same authors' survival deposit, also
#         uses V for Graves), and Z, never a first letter, = B (Biali Rocks, the only other SEAK rookery, where
#         no pups were branded). FI N = LN (Lowrie north, where the Lowrie pups were branded), C = CHR, L = SLR,
#         R = NR, X = born at H or W; the two letters never first, E and S, are the two areas where no pups were
#         branded, ER and LS: E = East Rocks and S = Lowrie south by their initials (an inference, stated in
#         notes). Birth years: SEAK 1995, 2001-2005; FI 1995, 2001-2005 (the paper says 1994-2004; kept as
#         deposited). Every artificial release is followed by a sighting at the next occasion (asserted).
# Mapping (multistate CJS, responseType state): one table per deposited analysis (two spatial scales of the
#   same branded females, overlapping). unit = female (SL0001.. / FI0001.., row order; no brand ids deposited),
#   taxon = EUMJUB, period = year (__periods), y = 0 not seen with a pup, else the location code (stateCodes),
#   y_raw = the deposited letter. obs_release = 1 on the authors' artificial natal sighting (the first
#   non-zero cell), which is not an observation: to reproduce their data drop the rows before it and condition
#   on it (as mcknight_2019_kittiwake_ms). At-risk span (E4.4, marked as pups): rows from the study's first year
#   or the birth year if later, to the last year; the deposit's cells before the release are 0 (not seen with a
#   pup) and are shipped as such. unit_birth_year. surveyEvidence = deposited_matrix (the full annual rectangle;
#   2006 is not a period of the F table). No coordinates.
# Not shipped: nothing of the two files. Sightings within a year (pooled by the authors).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/hastings_2018_sealion_philopatry_ms.R"; CACHE <- "hastings_2018_sealion_philopatry_ms"
DOI <- "10.5061/dryad.48j0m"
dir <- download_dryad(DOI, CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "17509",
          setequal(list.files(dir), c("SEAK.prn", "FI.prn")))
CIT <- "Hastings, K. K., Jemison, L. A., Pendleton, G. W., Raum-Suryan, K. L. & Pitcher, K. W. (2018). Data from: Natal and breeding philopatry of female Steller sea lions in southeastern Alaska [Dataset]. Dryad. https://doi.org/10.5061/dryad.48j0m"
REF <- "Hastings, K. K., Jemison, L. A., Pendleton, G. W., Raum-Suryan, K. L. & Pitcher, K. W. (2017). Natal and breeding philopatry of female Steller sea lions in southeastern Alaska. PLoS ONE 12, e0176840. https://doi.org/10.1371/journal.pone.0176840"
specs <- list(
  list(file = "SEAK.prn", table = "hastings_2018_seak_philopatry_ms", prefix = "SL", n = 369L, years = 2001:2015,
       letters = c(F = 1L, H = 2L, Z = 3L, W = 4L, V = 5L),
       first = c(F = 220L, H = 67L, V = 22L, W = 60L),
       codes = list(`0` = "not seen with a pup that year", `1` = "with a pup at F, Forrester Island Complex (letter F)", `2` = "with a pup at H, Hazy Islands (letter H)",
                    `3` = "with a pup at B, Biali Rocks (letter Z)", `4` = "with a pup at W, White Sisters (letter W)", `5` = "with a pup at G, Graves Rocks (letter V)"),
       title = "Annual multistate histories of 369 branded female Steller sea lions seen with a pup at five southeastern Alaska rookeries, 2001-2015 (natal and breeding philopatry)",
       geo = "Southeastern Alaska rookeries: Forrester Island Complex, Hazy Islands, Biali Rocks, White Sisters, Graves Rocks (no coordinates deposited)",
       design = "Multi-season (15 years, 2001-2015)", scale = "rookery",
       extra = "Overlaps hastings_2018_forrester_philopatry_ms (the same deposit's Forrester Island analysis, at island scale, of females that pupped at F) and hastings_2018_seak_sealion_cjs (the same authors' survival deposit, dryad.541r5, whose branded pups include these females)."),
  list(file = "FI.prn", table = "hastings_2018_forrester_philopatry_ms", prefix = "FI", n = 183L, years = c(2004L, 2005L, 2007:2015),
       letters = c(N = 1L, S = 2L, C = 3L, L = 4L, R = 5L, E = 6L, X = 7L),
       first = c(C = 44L, L = 16L, N = 54L, R = 62L, X = 7L),
       codes = list(`0` = "not seen with a pup that year", `1` = "with a pup at LN, Lowrie Island north (letter N)", `2` = "with a pup at LS, Lowrie Island south (letter S; inferred, see notes)",
                    `3` = "with a pup at CHR, Cape Horn Rocks (letter C)", `4` = "with a pup at SLR, Sea Lion Rocks (letter L)", `5` = "with a pup at NR, North Rocks (letter R)",
                    `6` = "with a pup at ER, East Rocks (letter E; inferred, see notes)", `7` = "natal release of a female born at Hazy Islands or White Sisters, outside F (letter X; release rows only)"),
       title = "Annual multistate histories of 183 branded female Steller sea lions seen with a pup at six pupping areas of the Forrester Island Complex, Alaska, 2004-2015 (island philopatry)",
       geo = "Forrester Island Complex rookery, southeastern Alaska: Lowrie Island (north, south), Cape Horn Rocks, Sea Lion Rocks, North Rocks, East Rocks (no coordinates deposited)",
       design = "Multi-season (11 years, 2004-2015 without 2006)", scale = "island",
       extra = "Letters E and S, never a natal letter, are the two areas where no pups were branded (ER and LS); E = East Rocks and S = Lowrie south is read from the initials, not stated in the deposit or paper. No 2006 period: data collection was halted by legal injunction. Overlaps hastings_2018_seak_philopatry_ms (the same deposit's SEAK-wide analysis at rookery scale) and hastings_2018_seak_sealion_cjs (dryad.541r5).")
)
for (sp in specs) {
  d <- fread(file.path(dir, sp$file), colClasses = c("character", "integer"))
  J <- length(sp$years)
  stopifnot(identical(names(d), c("ch", "byr")), nrow(d) == sp$n, all(nchar(d$ch) == J),
            all(strsplit(paste(d$ch, collapse = ""), "")[[1]] %in% c("0", names(sp$letters))))
  d[, `:=`(unit = sprintf("%s%04d", sp$prefix, .I), rel = as.integer(regexpr("[^0]", ch)))]
  d[, first := substr(ch, rel, rel)]
  ft <- d[, .N, by = first]
  stopifnot(all(d$rel >= 1L), setequal(ft$first, names(sp$first)), all(ft$N == sp$first[ft$first]),
            all(substr(d$ch, d$rel + 1L, d$rel + 1L) != "0"))
  if ("X" %in% names(sp$letters)) stopifnot(sum(strsplit(paste(d$ch, collapse = ""), "")[[1]] == "X") == sp$first[["X"]])
  d[, start := vapply(byr, function(b) min(which(sp$years >= b)), 1L)]
  stopifnot(all(d$start <= d$rel), all(substr(d$ch, 1, d$start - 1L) == strrep("0", d$start - 1L)))
  long <- d[, .(period = start:J), by = .(unit, ch, byr, rel)]
  long[, y_raw := substr(ch, period, period)]
  long[, `:=`(y = fifelse(y_raw == "0", 0L, sp$letters[y_raw]), obs_release = as.integer(period == rel))]
  long <- long[, .(unit, taxon = "EUMJUB", y, y_raw, period, unit_birth_year = byr, obs_release)]
  long <- order_eco(long)
  stopifnot(sum(long$obs_release) == sp$n, sum(long$y > 0) == sum(nchar(gsub("0", "", d$ch))))
  cat(sprintf("  %s: %d females, %d rows, %d sightings with pup (incl. %d releases)\n", sp$table, sp$n, nrow(long), sum(long$y > 0), sp$n))
  taxa <- make_taxa("EUMJUB", "Eumetopias jubatus", vernacularName = "Steller sea lion")
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  periods <- data.table(period = seq_len(J), year = sp$years)
  dataset <- list(
    title = sp$title, creator = "Hastings, Kelly K.; Jemison, Lauri A.; Pendleton, Grey W.; Raum-Suryan, Kimberly L.; Pitcher, Kenneth W.",
    pubDate = "2018", doi = DOI, sourceURL = paste0("https://doi.org/", DOI), citation = CIT, paperDOI = "10.1371/journal.pone.0176840",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Female Steller sea lions branded as pups at southeastern Alaska rookeries were resighted each breeding season (May-July); a female definitively seen with a pup in a year is coded by where she was seen. The authors fitted multistate mark-recapture models in which the first release is an artificial sighting at the natal location in the year before a female's first pup, so that the first transition estimates natal philopatry and later transitions breeding philopatry.",
    samplingProtocol = "Resighting of branded females from land and boat surveys of rookeries, May-July each year; a female's sightings definitively with a pup (birth, nursing and similar behaviour) in a year are pooled to one annual record of where she pupped.",
    samplingProtocolCode = "resighting", surveyEvidence = "deposited_matrix", responseType = "state",
    stateCodes = sp$codes, unitKind = "individual", closure = "none", closureNote = "one pooled annual record per year",
    occasionKind = "none", taxonInclusion = "single", geographicCoverage = sp$geo,
    temporalCoverage = sprintf("%d/%d", min(sp$years), max(sp$years)),
    covariateNote = "unit_birth_year: year of birth and branding. obs_release: 1 on the authors' artificial natal sighting in the year before a female's first pup (not an observation), else 0. y_raw: the deposited letter.",
    notShipped = list(within_year = "individual sightings within a year (pooled by the authors; not deposited)"),
    notes = paste("Unit ids are line numbers (no brand ids in the deposit). Rows begin at the study's first year or the birth year if later (E4.4); the row with obs_release = 1 is the authors' artificial natal release, and to reproduce their data drop the rows before it and condition on it. Only females ever seen with a pup are included, so survival to first pupping is 1 by construction. State letters resolved from the paper's natal sample sizes (header).", sp$extra))
  ds <- write_table(long, sp$table, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(sp$table,
    description = sprintf("%s; state = %s where a female was seen with a pup, the first record being the authors' artificial natal release.", sub(" \\(.*$", "", sp$title), sp$scale),
    url = paste0("https://doi.org/", DOI), reference = REF, doi_paper = "10.1371/journal.pone.0176840", doi_data = DOI,
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "State letters resolved against the paper's natal counts (PDF supplied by Ben); read from batch 37's cache.", source_via = "Dryad")
  stage_tag_row(sp$table, ds, taxon_group = "Mammals", model_family = "Multi-state CJS",
    sampling_protocol = "resighting", design = sp$design, realm = "Marine", country = "USA", coordinates = "None in source",
    notes = "Natal and breeding philopatry; artificial natal release flagged (obs_release).")
}
