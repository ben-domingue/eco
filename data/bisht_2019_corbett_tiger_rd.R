#!/usr/bin/env Rscript
# Table:  bisht_2019_corbett_tiger_rd
# Source: Dryad doi:10.5061/dryad.vc3143h, version 1 (2019-05-01), CC0 1.0 as shown on the
#         Dryad record. "Data from: Demography of a high density tiger population and its
#         implications for tiger recovery." Bisht, Banerjee, Qureshi & Jhala.
# Paper:  Bisht, S., Banerjee, S., Qureshi, Q. & Jhala, Y. (2019). Demography of a high-density
#         tiger population and its implications for tiger recovery. Journal of Applied Ecology,
#         doi:10.1111/1365-2664.13410.
#         p. 4, s. 2.2: camera traps in pairs at stations 1-1.5 km apart over 521 km2 of Corbett
#           National Park, 2010-2015; in 2010-2012 the area was sampled in two blocks of ~250 km2
#           "sampled 120-150 days apart", in 2013-2015 the whole area simultaneously.
#         p. 4-5, s. 2.4: robust design, "6 years (2010-2015) of data with each year as a
#           'primary period'"; "Each of our primary period consisted of 42 camera trap nights
#           (secondary periods)". Cubs (<1 year) excluded; one age class. The two blocks of
#           2010-2012 were merged into one primary per year for analysis (the paper's combined
#           analysis); 4-5 tigers were common to both blocks (p. 8, s. 4).
#         p. 7, Table 2: per year camera density (low 2010-2012, high 2013-2015) and trap-nights
#           4,326, 4,410, 4,410, 6,300, 9,324, 7,014 (each divisible by 42); 307 individuals,
#           cumulative 89, 129, 162, 201, 251, 307; 130 females, 118 males, 59 unsexed (p. 7, s. 3).
# Data:   Pollock_MARK.inp (the only file): 307 lines, one per tiger, CRLF, a 252-character
#         0/1 history then six group columns (Dryad usage notes: block 1 male, block 1 female,
#         block 1 unidentified, block 2 male, block 2 female, block 2 unidentified), exactly one
#         1 per line, then ";". No ids, dates, traps or coordinates. 2,910 detection-nights
#         (the paper's 6,202 photo-captures collapse to one detection per tiger-night).
#         Group totals: 115 male, 133 female, 59 unidentified (paper: 118, 130, 59), block 1 164,
#         block 2 143.
#         The deposit does not reproduce Table 2's per-year counts. Split into 42-night years
#         it gives 90, 85, 79, 78, 104, 116 tigers detected per year (Table 2 Mt+1: 89, 98,
#         93, 109, 118, 115) and cumulative 90, 130, 163, 199, 249, 307 (Table 2: 89, 129, 162,
#         201, 251, 307). No contiguous split of the 252 columns reproduces Table 2 (the
#         cumulative 201 is not reached at any column), so the 42-night split is the paper's
#         stated design and the per-year differences are between the deposit and the table;
#         asserted below and recorded in notes.
#
# Mapping (robust design, standard E9; responseType detection, unitKind individual):
#   unit = tiger (T001-T307, file order), taxon = PANTIG, period = primary (1-6 = 2010-2015),
#   occasion = camera-trap night 1-42 within the year's session, y = photo-captured that night.
#   In 2010-2012 the session ran in two blocks 120-150 days apart, and occasion k is the k-th
#   night of the tiger's block (as the deposit merged them); closureNote says so.
#   surveyEvidence = deposited_matrix: every one of the 252 nights is a survey (42 per year,
#   Table 2 trap-nights). At-risk span (E4.4): every tiger was photographed in the wild with
#   age unknown (>1 year), so it is at risk from the first period: full 307 x 252 rectangle,
#   zeros before first capture included; no removals are deposited.
#   unit_sex (male / female / unknown) and cluster_id (B1 / B2, the MARK block group) from the
#   group columns. __periods: year, camera density class and trap-nights from Table 2, and
#   the block design. Coordinates: none deposited. Panthera tigris is IUCN EN (flagged under
#   E7) but there is nothing to coarsen.
#   Not shipped: the paper's estimates (abundance, survival, density, breeding females);
#   Table 2's per-year counts (they disagree with the deposit, see above).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bisht_2019_corbett_tiger_rd"
dir <- download_dryad("10.5061/dryad.vc3143h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

L <- readLines(file.path(dir, "Pollock_MARK.inp"), warn = FALSE)
L <- sub("\r$", "", L); L <- L[nzchar(trimws(L))]
m <- regmatches(L, regexec("^([01]{252}) ([01]) ([01]) ([01]) ([01]) ([01]) ([01]);$", L))
stopifnot(length(L) == 307, all(lengths(m) == 8))
G <- sapply(3:8, function(j) as.integer(sapply(m, `[`, j)))
stopifnot(all(rowSums(G) == 1), identical(as.integer(colSums(G)), c(66L, 72L, 26L, 49L, 61L, 33L)))
sex <- c("male", "female", "unknown")[max.col(G[, 1:3] + G[, 4:6], ties.method = "first")]
block <- ifelse(rowSums(G[, 1:3]) == 1, "B1", "B2")
stopifnot(identical(as.integer(table(factor(sex, c("male", "female", "unknown")))), c(115L, 133L, 59L)),
          identical(as.integer(table(block)), c(164L, 143L)))
CH <- do.call(rbind, strsplit(sapply(m, `[`, 2), "")); storage.mode(CH) <- "integer"
prim <- rep(1:6, each = 42)
cap <- sapply(1:6, function(p) rowSums(CH[, prim == p]) > 0)
first <- apply(cap, 1, function(r) which(r)[1])
stopifnot(sum(CH) == 2910, all(rowSums(CH) > 0),
          identical(as.integer(colSums(cap)), c(90L, 85L, 79L, 78L, 104L, 116L)),
          identical(as.integer(cumsum(table(factor(first, 1:6)))), c(90L, 130L, 163L, 199L, 249L, 307L)),
          identical(which(colSums(CH) == 0), c(212L, 251L)),
          # in 2010-2012 both block groups are detected across the 42 nights (blocks merged into one primary)
          all(sapply(1:3, function(p) sum(CH[block == "B1", prim == p]) > 0 && sum(CH[block == "B2", prim == p]) > 0)))
tn <- c(4326L, 4410L, 4410L, 6300L, 9324L, 7014L)   # Table 2 trap-nights
stopifnot(all(tn %% 42L == 0L))

units <- sprintf("T%03d", seq_len(307))
long <- array_to_eco(CH, taxon = "PANTIG", site_ids = units, period = prim,
                     site_covs = list(sex = sex, cluster_id = block))
setnames(long, "unit_cluster_id", "cluster_id", skip_absent = TRUE)
long <- order_eco(long)
stopifnot(nrow(long) == 307 * 252, sum(long$y) == 2910, uniqueN(long$unit) == 307,
          identical(sort(unique(long$period)), 1:6), max(long$occasion) == 42,
          all(long[, .N, by = .(unit, period)]$N == 42), all(long[, uniqueN(cluster_id), by = unit]$V1 == 1))

periods <- data.table(period = 1:6, year = 2010:2015, n_occasions = 42L,
                      camera_density = rep(c("low (1 per 5 km2)", "high (2 per 5 km2)"), each = 3),
                      trap_nights = tn,
                      sampling = rep(c("two blocks of ~250 km2 sampled 120-150 days apart, 42 nights each", "whole 521 km2 sampled simultaneously, 42 nights"), each = 3),
                      note = "trap_nights and camera_density from the paper's Table 2")
taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "EN"))

dataset <- list(
  title = "Robust-design camera-trap capture histories of 307 tigers, Corbett National Park, India, 2010-2015",
  creator = "Bisht, Shikha; Banerjee, Sudip; Qureshi, Qamar; Jhala, Yadavendradev", pubDate = "2019",
  doi = "10.5061/dryad.vc3143h", sourceURL = "https://doi.org/10.5061/dryad.vc3143h",
  citation = "Bisht, S., Banerjee, S., Qureshi, Q., & Jhala, Y. (2019). Data from: Demography of a high density tiger population and its implications for tiger recovery [Dataset]. Dryad. https://doi.org/10.5061/dryad.vc3143h",
  paperDOI = "10.1111/1365-2664.13410",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap capture-recapture of tigers (Panthera tigris) over 521 km2 of Corbett National Park, Uttarakhand, India: 307 individuals (115 male, 133 female, 59 of unknown sex in the deposit) photographed on 2,910 tiger-nights in six annual primary periods (2010-2015) of 42 camera-trap nights each, used in Pollock's robust design to estimate abundance, sex-specific survival, temporary emigration and recruitment.",
  samplingProtocol = "Paired camera traps at stations 1-1.5 km apart along trails, run for 42 nights per year; tigers identified from stripe patterns (EXTRACTCOMPARE). In 2010-2012 the area was trapped in two blocks of ~250 km2 sampled 120-150 days apart (low camera density, 1 per 5 km2); in 2013-2015 the whole area at once (2 per 5 km2). Cubs under one year excluded.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every one of the 252 history columns is a camera-trap night of the 42-night annual session (paper s. 2.4 and Table 2 trap-nights); the deposit has no missing-occasion code.",
  responseType = "detection", unitKind = "individual",
  closure = "closed",
  closureNote = "occasion = camera-trap night within the annual primary (robust design, closed within a year as the paper assumes). In 2010-2012 the two blocks were trapped 120-150 days apart and merged into one primary, so occasion k is the k-th night of the tiger's block, not one calendar night; the paper notes this may violate closure within those primaries (s. 4) and that block-2 tigers had a 6-month interval between the 2012 and 2013 primaries (s. 2.4). Ids are valid across the whole study.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Corbett National Park (521 km2), Uttarakhand, India (no coordinates deposited)", temporalCoverage = "2010/2015",
  notShipped = list(model_estimates = "abundance, density, survival, temporary emigration, recruitment and breeding-female estimates (model outputs)",
                    table2_counts = "the paper's per-year individual counts (Table 2 Mt+1, #M, #F): the deposit does not reproduce them (see notes)"),
  notes = "unit ids T001-T307 follow the order of the MARK file. cluster_id is the MARK block group (B1, B2) the authors assigned each tiger; in 2013-2015 both blocks were trapped together. The deposit gives 90, 85, 79, 78, 104, 116 tigers detected per year and 115 male / 133 female / 59 unknown, against the paper's Table 2 (89, 98, 93, 109, 118, 115) and text (118 / 130 / 59); the cumulative counts nearly agree (deposit 90, 130, 163, 199, 249, 307; paper 89, 129, 162, 201, 251, 307). All tigers were wild-caught with unknown age, so each carries all 252 nights (E4.4); condition on first capture to reproduce MARK's robust design. Tiger is IUCN EN; no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/bisht_2019_corbett_tiger_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design camera-trap capture histories of 307 tigers in Corbett National Park, India, 2010-2015: six annual primaries of 42 trap-nights, with sex and sampling block per tiger.",
  url = "https://doi.org/10.5061/dryad.vc3143h",
  reference = "Bisht, S., Banerjee, S., Qureshi, Q., & Jhala, Y. (2019). Demography of a high-density tiger population and its implications for tiger recovery. Journal of Applied Ecology.",
  doi_paper = "10.1111/1365-2664.13410", doi_data = "10.5061/dryad.vc3143h",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "From the MARK .inp; 42 nights per primary from the paper (s. 2.4). Deposit's per-year counts differ from the paper's Table 2. IUCN EN, no coordinates. Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design",
  sampling_protocol = "camera_trap", design = "Robust design (6 annual primaries x 42 camera-trap nights)", realm = "Terrestrial", country = "IND",
  coordinates = "None in source", notes = "IUCN EN; 2010-2012 primaries merge two blocks trapped 120-150 days apart.", status = "tagged")
