#!/usr/bin/env Rscript
# Table:  hastings_2018_seak_sealion_cjs
# Source: Dryad doi:10.5061/dryad.541r5, version 9081 (published 2018-01-05), licence CC0 1.0
#         (as shown on Dryad). Hastings, K. K., Jemison, L. A. & Pendleton, G. W. "Data from:
#         Survival of adult Steller sea lions in Alaska: senescence, annual variation and
#         covariation with male reproductive success".
# Paper:  Hastings, K. K., Jemison, L. A. & Pendleton, G. W. (2018). Survival of adult Steller
#         sea lions in Alaska: senescence, annual variation and covariation with male
#         reproductive success. Royal Society Open Science 5:170665. doi:10.1098/rsos.170665
#         (open access; PMC5792871). Section 2 supplied the occasion years and the marking design.
# Data:   caphist1.prn: header `ch nr sex`, 2,795 rows, one per pup; ch is an 18-character 0/1
#           history over the occasions 1994, 1995, 2000-2015 (paper section 2.1: multiple
#           sightings per summer, June-August at haul-outs or May-August at rookeries, pooled to
#           one annual observation); nr = natal rookery (F Forrester Island complex, H Hazy
#           Islands, W White Sisters, V = the paper's G, Graves Rocks: 93 pups in two cohorts,
#           the paper's G total); sex F/M (11 animals of unknown sex were assigned a sex at
#           random by the authors, not identified in the file). The first 1 of every history is
#           the branding of the pup at 2-4 weeks of age (cohorts 1994, 1995, 2001-2005).
#         caphist2.prn: 1,522 adult-male multi-state histories (`ch nr coh`) for the territoriality
#           analysis (paper section 2.3), with letters Z, N, S, T, A, B, C and a `coh` column
#           (A/B). Not shipped: Z, S and coh are not defined in the deposit or the paper (the
#           paper's states are A, B, C, N, T, H; Z and S do not appear in it), so the state codes
#           cannot be mapped.
#
# Mapping (standard E9 CJS, responseType detection):
#   unit = SSL0001.. (row order of caphist1; the deposit has no brand ids), taxon = EUMJUB,
#   period = 1..18 (the history's columns; __periods gives the calendar year: 1994, 1995,
#   2000-2015, so the intervals are unequal), y = the history cell. No `occasion` (one pooled
#   annual observation per period). unit_sex, unit_natal_rookery (the deposit's code),
#   unit_cohort_year (year of the first 1).
#   At-risk span (E4.4): every animal was branded as a pup, so it has no rows before its marking
#   period; its marking row is y = 1. The 1994 cohort has no row in 1995: the paper did not use
#   resightings of the 1994-1995 cohorts before 2000 (not photo-documented) and modelled
#   survival from birth to 2000 as one cumulative interval, so the 1995 column is only the
#   branding of the 1995 cohort, not a resighting survey of the 1994 cohort (asserted: every
#   1994-cohort 1995 cell is 0). From 2000 to 2015 every animal has a row each year. No mark
#   loss: the paper used only photo-confirmed resightings and states that mark loss did not
#   occur. No losses on capture.
#   Survey evidence: deposited_matrix. The deposited history is the authors' full rectangle over
#   the surveyed occasions (no NA cells exist); which column is a survey of which animal follows
#   the paper's design, stated above.
#   Coordinates: none in the deposit. Eumetopias jubatus is IUCN Near Threatened (GBIF answer
#   cached); the eastern distinct population segment (south-east Alaska) was removed from the US
#   Endangered Species Act list in 2013. Rookery names are published colony names, kept.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hastings_2018_seak_sealion_cjs"
dir <- download_dryad("10.5061/dryad.541r5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("caphist1.prn", "caphist2.prn")))

d <- fread(file.path(dir, "caphist1.prn"), colClasses = "character")
stopifnot(identical(names(d), c("ch", "nr", "sex")), nrow(d) == 2795L,
          all(nchar(d$ch) == 18L), all(grepl("^[01]+$", d$ch)),
          all(d$nr %in% c("F", "H", "V", "W")), all(d$sex %in% c("F", "M")))
YEARS <- c(1994L, 1995L, 2000:2015)
Tn <- length(YEARS); stopifnot(Tn == 18L)
CH <- t(sapply(strsplit(d$ch, ""), as.integer)); stopifnot(dim(CH) == c(2795L, Tn))
first <- apply(CH, 1, function(r) which(r == 1L)[1])
stopifnot(!anyNA(first))
d[, `:=`(unit = sprintf("SSL%04d", .I), first = first, cohort = YEARS[first])]

# the paper's marking design (section 2): cohorts by rookery, totals per rookery, 1,207 resighted after the birth year
stopifnot(setequal(d$cohort, c(1994L, 1995L, 2001:2005)),
          identical(d[, .N, keyby = nr]$N, c(1795L, 539L, 93L, 368L)),          # F, H, V(=G), W
          identical(d[, uniqueN(cohort), keyby = nr]$V1, c(6L, 3L, 2L, 3L)),
          d[nr == "F", .N, by = cohort][, range(N)] == c(141L, 400L),
          d[nr == "H", .N, by = cohort][, range(N)] == c(101L, 225L),
          d[nr == "W", .N, by = cohort][, range(N)] == c(94L, 147L),
          d[nr == "V", .N, by = cohort][, range(N)] == c(43L, 50L),
          sum(rowSums(CH) > 1L) == 1207L,
          all(CH[d$cohort == 1994L, 2] == 0L),          # 1994 cohort never "seen" in 1995 (no resighting used)
          sum(CH[, 3]) == sum(d$cohort <= 1995L & CH[, 3] == 1L))  # nobody marked in 2000

grid <- d[, .(period = seq_len(Tn)), by = .(unit, first, cohort, nr, sex)]
grid <- grid[period >= first]                                   # E4.4: no rows before the marking period
grid <- grid[!(cohort == 1994L & period == 2L)]                 # 1995 is not a resighting survey of the 1994 cohort
grid[, y := CH[cbind(match(unit, d$unit), period)]]
stopifnot(nrow(grid) == sum((Tn - d$first + 1L) - (d$cohort == 1994L)),
          sum(grid$y) == sum(CH), all(grid[period == first, y] == 1L))

long <- grid[, .(unit, taxon = "EUMJUB", y = as.integer(y), period,
                 unit_sex = sex, unit_natal_rookery = nr, unit_cohort_year = cohort)]
long <- order_eco(long)
stopifnot(!anyDuplicated(long[, .(unit, period)]), uniqueN(long$unit) == 2795L)
cat(sprintf("  %d pups, %d periods, %d rows, %d detections (%d of them marking rows)\n",
            uniqueN(long$unit), Tn, nrow(long), sum(long$y), nrow(d)))

taxa <- make_taxa("EUMJUB", "Eumetopias jubatus", vernacularName = "Steller sea lion")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "NT"))

periods <- data.table(period = seq_len(Tn), year = YEARS)
periods[, n_marked := sapply(period, function(t) sum(d$first == t))]
periods[, n_resighted := colSums(CH) - n_marked]
periods[, n_at_risk := sapply(period, function(t) long[period == t, .N])]
periods[, kind := fifelse(year %in% c(1994L, 1995L), "branding of that year's cohort only (no resighting data used)",
                  fifelse(year == 2000L, "resighting (boat surveys, field camp at F); no branding",
                          fifelse(year <= 2005L, "resighting and branding of that year's cohort", "resighting")))]
stopifnot(all(periods[year %in% c(1994L, 1995L), n_resighted] == 0L))

dataset <- list(
  title = "Steller sea lion resighting histories, south-east Alaska: 2,795 pups branded at four rookeries (1994-1995, 2001-2005), annual resighting 2000-2015",
  creator = "Hastings, Kelly K.; Jemison, Lauri A.; Pendleton, Grey W. (Alaska Department of Fish and Game)",
  pubDate = "2018", doi = "10.5061/dryad.541r5", sourceURL = "https://doi.org/10.5061/dryad.541r5",
  citation = "Hastings, K. K., Jemison, L. A., & Pendleton, G. W. (2018). Data from: Survival of adult Steller sea lions in Alaska: senescence, annual variation and covariation with male reproductive success [Dataset]. Dryad. https://doi.org/10.5061/dryad.541r5",
  paperDOI = "10.1098/rsos.170665",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Cormack-Jolly-Seber histories of 2,795 Steller sea lion (Eumetopias jubatus) pups branded by the Alaska Department of Fish and Game at four of five rookeries in south-east Alaska (Forrester Island complex, Hazy Islands, White Sisters, Graves Rocks) in 1994-1995 and 2001-2005, and resighted each summer 2000-2015 from photo-confirmed sightings (dedicated boat surveys of all rookeries and major haul-outs, a near-daily field camp at Forrester, and contributed photographs from Oregon to Russia). Multiple sightings per summer are pooled to one annual observation. Each animal's rows begin at its branding; the 1994 cohort has no 1995 row because resightings before 2000 were not used.",
  samplingProtocol = "Hot-iron branding of pups (2-4 weeks old, late June-early July) with unique alphanumeric marks; resighting of branded animals from photographs taken during 1-3 dedicated boat surveys per summer (May-July) visiting every rookery and major haul-out in south-east Alaska, an annual May-July field camp at Forrester Island, dedicated surveys in northern British Columbia in 11 years and contributed photographs; only photo-confirmed resightings used; one annual observation per animal.",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The deposited 0/1 history covers the paper's 18 occasions (1994, 1995, 2000-2015) with no missing cells. Rows begin at each animal's branding (marked at birth, E4.4). The 1995 cell of the 1994 cohort is not a survey (the paper used no resightings before 2000) and has no row; every such cell is 0 in the deposit.",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one pooled annual observation per period; survival is estimated between periods, and the 1995-2000 interval is five years", occasionKind = "none",
  taxonInclusion = "single",
  geographicCoverage = "South-east Alaska, USA (natal rookeries Forrester Island complex, Hazy Islands, White Sisters, Graves Rocks); resightings from Oregon to the Bering Sea and Russia; no coordinates deposited",
  temporalCoverage = "1994/2015",
  notes = "unit_natal_rookery codes as deposited: F Forrester Island complex, H Hazy Islands, W White Sisters, V Graves Rocks (the paper's G; 93 pups in two cohorts, matching the paper). unit_sex: 11 animals of unrecorded sex were assigned a sex at random by the authors and are not identified. 39 misshapen-brand resightings (3.2% of resighted animals) were assigned to individuals at random among the possible matches (paper section 2). No mark loss (paper section 2). Unit ids are row numbers of caphist1; the deposit carries no brand codes. Eastern DPS; IUCN NT for the species.",
  notShipped = list(`caphist2.prn (adult-male territorial multi-state histories)` = "1,522 histories with state letters Z, N, S, T, A, B, C and a coh column (A/B); Z, S and coh are not defined in the deposit or the paper (whose states are A, B, C, N, T, H), so the codes cannot be mapped to a stateCodes list",
                    `resightings of the 1994-1995 cohorts before 2000` = "not in the deposit (the paper excluded them: not photo-documented)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hastings_2018_seak_sealion_cjs.R")

stage_dict_row(TABLE,
  description = "Cormack-Jolly-Seber resighting histories of 2,795 Steller sea lions (Eumetopias jubatus) branded as pups at four rookeries in south-east Alaska (cohorts 1994-1995 and 2001-2005) and resighted annually 2000-2015 from photo-confirmed sightings; rows begin at branding, with sex, natal rookery and cohort as unit covariates.",
  url = "https://doi.org/10.5061/dryad.541r5",
  reference = "Hastings, K. K., Jemison, L. A., & Pendleton, G. W. (2018). Survival of adult Steller sea lions in Alaska: senescence, annual variation and covariation with male reproductive success. Royal Society Open Science, 5, 170665.",
  doi_paper = "10.1098/rsos.170665", doi_data = "10.5061/dryad.541r5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "caphist1 shipped; caphist2 (male territorial states) not shipped: state letters Z and S and the coh column are undefined. 1994 cohort has no 1995 row (no resighting data used before 2000). Rookery code V = the paper's G (Graves Rocks).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "tag_resight", design = "Multi-session (18 annual periods, 1994, 1995, 2000-2015; unequal intervals)",
  realm = "Marine", country = "USA", coordinates = "None in source",
  notes = "Individuals marked at birth: rows from the branding period (E4.4). Pooled annual resighting.")
