#!/usr/bin/env Rscript
# Table:  malachowski_2026_koloa_rd
# Source: Zenodo doi:10.5281/zenodo.21516105 (CC BY 4.0, as shown on the Zenodo record),
#   published 2026-07-31. Malachowski, C. P., Uyehara, K. J., Reynolds, M. H. & Dugger, B. D.
#   Data for: Heavily male-biased adult sex ratio is associated with lower female survival in
#   the federally endangered Anas wyvilliana (Koloa Maoli or Hawaiian Duck) on north Kaua'i.
# Paper:  Malachowski, C. P., et al. (2026). Ornithological Applications, doi:10.1093/ornithapp/duag068
#         (the record's isSupplementTo link; abstract in the deposited README).
# Data:   "Malachowski_2026_RDCMR_Koloa encounter histories.inp": Program MARK input, 792
#         individuals (one line each, /*id*/ then a 37-character history then the group
#         frequencies: females "1 0" 150, males "0 1" 642; no negative frequencies, so no
#         losses on capture). Header comments: 11 primary occasions with 4,5,2,6,5,2,5,2,2,2,2
#         secondaries, 12/26/2010 to 11/15/2015. "." marks the same 8 secondaries in every
#         history (primaries 3, 6, 9 and 10), which have effort 0 in the covariates file.
#         Malachowski_2026_RDCMR_Covariates.csv (37 rows, one per secondary): prim_occ,
#         sec_occ, season (0 winter, 1 summer), effort (trap-days), rainPO (mean daily rain
#         in the primary), rain30 (rain in the 30 days before the primary), rainSO (mean daily
#         rain in the secondary), and natural logs of each. "..._Time intervals.csv" (36
#         rows): elapsed time between consecutive secondaries in 6-month units (0 within a
#         primary). The R script processes MARK outputs (not data).
#
# Mapping (robust design, standard E9; responseType detection, unitKind individual):
#   unit = individual (K + MARK id), taxon = ANAWYV, period = primary occasion (source
#   numbering 1-11; primaries 3, 6, 9, 10 were not trapped and have no rows), occasion =
#   secondary within the primary (1..k), y = captured 0/1. Survey evidence:
#   deposited_matrix: a secondary is a survey iff it is not "." in the histories, asserted
#   to be exactly where effort > 0. At-risk span (E4.4): all birds were caught in the wild
#   (adults and first-years; age at capture is not deposited), so every individual carries
#   every surveyed secondary of the study, zeros before first capture included; no
#   removals. unit_sex from the MARK group. obs_effort_trapdays and obs_rain_mm_day per
#   secondary; season, rainPO, rain30 and the cumulative elapsed time are period facts in
#   __periods. Logged covariates are not shipped (derivable).
#   Coordinates: none deposited (one refuge). Anas wyvilliana is IUCN Vulnerable (federally
#   endangered under the US Endangered Species Act); with no
#   coordinates there is nothing to coarsen.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "malachowski_2026_koloa_rd"
base <- "https://zenodo.org/records/21516105/files/"
f_inp <- download_cached(paste0(base, "Malachowski_2026_RDCMR_Koloa%20encounter%20histories.inp?download=1"), TABLE,
                         filename = "Malachowski_2026_RDCMR_Koloa encounter histories.inp")
f_cov <- download_cached(paste0(base, "Malachowski_2026_RDCMR_Covariates.csv?download=1"), TABLE, filename = "Malachowski_2026_RDCMR_Covariates.csv")
f_int <- download_cached(paste0(base, "Malachowski_2026_RDCMR_Time%20intervals.csv?download=1"), TABLE, filename = "Malachowski_2026_RDCMR_Time intervals.csv")

L <- readLines(f_inp, warn = FALSE)
hdr <- grep("^/\\* ", L, value = TRUE)
stopifnot(any(grepl("Primary occasions = 11, Secondary occasions = 37 (4,5,2,6,5,2,5,2,2,2,2)", hdr, fixed = TRUE)),
          any(grepl("START date = 12/26/2010, END date = 11/15/2015", hdr, fixed = TRUE)))
L <- grep("^/\\*[0-9]+\\*/", L, value = TRUE)
m <- regmatches(L, regexec("^/\\*([0-9]+)\\*/ ([01.]{37}) ([01]) ([01]);$", L))
stopifnot(all(lengths(m) == 5))
inp <- data.table(id = as.integer(sapply(m, `[`, 2)), ch = sapply(m, `[`, 3), f = as.integer(sapply(m, `[`, 4)), mm = as.integer(sapply(m, `[`, 5)))
stopifnot(nrow(inp) == 792, !anyDuplicated(inp$id), all(inp$f + inp$mm == 1), sum(inp$f) == 150, sum(inp$mm) == 642)
CH <- do.call(rbind, strsplit(inp$ch, ""))
dots <- CH == "."
stopifnot(all(apply(dots, 2, function(v) all(v) || !any(v))), sum(CH == "1") == 1236, all(rowSums(CH == "1") > 0))

cov <- fread(f_cov); int <- fread(f_int)
stopifnot(nrow(cov) == 37, identical(cov$sec_occ, 1:37), identical(as.integer(table(cov$prim_occ)), c(4L, 5L, 2L, 6L, 5L, 2L, 5L, 2L, 2L, 2L, 2L)),
          identical(cov$effort > 0, !dots[1, ]), nrow(int) == 36,
          identical(which(int$duration_6mo > 0), cumsum(c(4L, 5L, 2L, 6L, 5L, 2L, 5L, 2L, 2L, 2L))),
          cov[, uniqueN(season), by = prim_occ][, all(V1 == 1)], cov[, uniqueN(rainPO), by = prim_occ][, all(V1 == 1)],
          cov[, uniqueN(rain30), by = prim_occ][, all(V1 == 1)])
cov[, occasion := seq_len(.N), by = prim_occ]
cov[, t6 := c(0, cumsum(int$duration_6mo))]
surv <- which(!dots[1, ])
stopifnot(length(surv) == 29)

Y <- matrix(as.integer(CH[, surv]), nrow(CH))
units <- sprintf("K%04d", inp$id)
long <- array_to_eco(Y, taxon = "ANAWYV", site_ids = units, period = cov$prim_occ[surv],
                     site_covs = data.frame(sex = ifelse(inp$f == 1L, "female", "male")))
stopifnot(nrow(long) == 792 * 29)
# array_to_eco numbers occasions within period in column order; check against the source's secondary index
oc <- cov[surv, .(period = prim_occ, occasion, obs_effort_trapdays = effort, obs_rain_mm_day = rainSO)]
long <- merge(long, oc, by = c("period", "occasion"))
setcolorder(long, c("unit", "taxon", "period", "occasion", "y"))
setorder(long, unit, period, occasion)
stopifnot(nrow(long) == 792 * 29, sum(long$y) == 1236, uniqueN(long$period) == 7, setequal(long$period, c(1, 2, 4, 5, 7, 8, 11)))

periods <- cov[prim_occ %in% unique(long$period), .(n_occasions = .N, season = c("winter", "summer")[season[1] + 1L],
                                                    rain_mean_mm_day = rainPO[1], rain_prev30_mm = rain30[1],
                                                    start_6mo = t6[1], trapdays = sum(effort)), by = .(period = prim_occ)]
periods[, note := "primary occasion (source numbering); start_6mo = elapsed time since the first secondary in 6-month units, from the deposited intervals"]
taxa <- make_taxa("ANAWYV", "Anas wyvilliana", vernacularName = "Hawaiian Duck (Koloa maoli)")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))

dataset <- list(
  title = "Robust-design capture histories of 792 Hawaiian Ducks (Koloa maoli), Hanalei National Wildlife Refuge, Kaua'i, 2010-2015",
  creator = "Malachowski, Christopher P.; Uyehara, Kimberly J.; Reynolds, Michelle H.; Dugger, Bruce D.", pubDate = "2026",
  doi = "10.5281/zenodo.21516105", sourceURL = "https://doi.org/10.5281/zenodo.21516105",
  citation = "Malachowski, C. P., Uyehara, K. J., Reynolds, M. H., & Dugger, B. D. (2026). Data for: Heavily male-biased adult sex ratio is associated with lower female survival in the federally endangered Anas wyvilliana (Koloa Maoli or Hawaiian Duck) on north Kaua'i, Hawai'i, USA [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.21516105",
  paperDOI = "10.1093/ornithapp/duag068",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Capture-mark-recapture of the endangered Hawaiian Duck at Hanalei National Wildlife Refuge, north Kaua'i: 792 adult and first-year birds (150 females, 642 males) captured 1,236 times in 29 trapping secondaries within 7 trapped primary occasions (winter and summer seasons) between December 2010 and November 2015, used in robust-design models of abundance, sex ratio, survival and temporary emigration.",
  samplingProtocol = "Robust-design live trapping of ducks on the refuge: primary occasions in winter and summer, each with 2-6 secondary trapping occasions; trap-days and rainfall recorded per secondary. Four of the eleven primaries in the study's MARK design had no trapping.",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix", effortColumn = "obs_effort_trapdays",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "occasion = secondary trapping occasion within a primary (robust design); the paper finds random temporary emigration between primaries",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Hanalei National Wildlife Refuge, north Kaua'i, Hawai'i, USA (no coordinates deposited)", temporalCoverage = "2010-12/2015-11",
  notShipped = list(log_covariates = "effort_log, rainPO_log, rain30_log, rainSO_log (derivable)",
                    R_script = "processing of MARK model outputs (not data)"),
  notes = "Periods keep the source's primary numbering (1-11); primaries 3, 6, 9 and 10 were not trapped and have no rows. All birds were wild-caught (age at capture not deposited), so each carries every surveyed secondary of the study (E4.4); condition on first capture to reproduce MARK's robust design. __periods start_6mo gives the elapsed time for survival intervals.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/malachowski_2026_koloa_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design capture histories of 792 Hawaiian Ducks (150 female, 642 male) at Hanalei NWR, Kaua'i, 2010-2015: 29 trapping secondaries in 7 primary occasions, with trap-days and rainfall per secondary and season per primary.",
  url = "https://doi.org/10.5281/zenodo.21516105",
  reference = "Malachowski, C. P., Uyehara, K. J., Reynolds, M. H., & Dugger, B. D. (2026). Heavily male-biased adult sex ratio is associated with lower female survival in the federally endangered Anas wyvilliana (Koloa Maoli or Hawaiian Duck) on north Kaua'i, Hawai'i, USA. Ornithological Applications.",
  doi_paper = "10.1093/ornithapp/duag068", doi_data = "10.5281/zenodo.21516105",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "From the MARK .inp; untrapped secondaries ('.') have no rows. IUCN VU, US-endangered species; no coordinates in source. Fetched from Zenodo.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Robust design",
  sampling_protocol = "live_trap", design = "Robust design (7 primaries, 2-6 secondaries)", realm = "Freshwater", country = "USA",
  coordinates = "None in source", notes = "US-endangered (IUCN VU) Hawaiian endemic; sex as unit covariate.", status = "tagged")
