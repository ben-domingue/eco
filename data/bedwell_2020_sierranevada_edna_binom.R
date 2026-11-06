#!/usr/bin/env Rscript
# Table:  bedwell_2020_sierranevada_edna_binom
# Source: Dryad, doi:10.5061/dryad.2jm63xsjv, version 86658 (published 2020-11-10), licence CC0 1.0 as shown on
#         the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Bedwell, M. E. & Goldberg, C. S. (2020). Spatial and temporal patterns of environmental DNA detection to
#         inform sampling protocols in lentic and lotic systems. Ecology and Evolution 10(3), 1602-1612.
#         https://doi.org/10.1002/ece3.6014 (open access, PMC7029092). From the paper: five lakes (F-J) and five
#         streams (A-E) in the Sierra Nevada, California, with historical presence of Rana sierrae or R. boylii,
#         sampled monthly May 16 to August 21, 2016 (four sampling occasions). Streams: seven sites 100 m apart
#         (fewer when the bed was dry), a 1 L and a 2 L 0.45 um CN filter per site. Lakes: a 'site' is a composite
#         of five shore grabs 50 m apart; a 1 L and a 2 L CN filter per site (plus PES / MCE test filters). Each
#         filter analysed in triplicate in a qPCR multiplex (R. sierrae, R. boylii and Batrachochytrium
#         dendrobatidis assays); a replicate is positive at Cq <= 45 (section 2.3). For streams a replicate positive
#         for either frog species counts as one detection (section 2.3). The authors' site call (section 2.3.2,
#         README): a site is positive when at least two of the six qPCR replicates of its two CN filters are positive.
# Data:   README.txt; for each target (Bd, YLF = yellow-legged frog) and system (lakes, streams):
#           <t>_<s>_sampling_occ.csv: location x sampling occasion (20 rows each): num_sites (sites analysed),
#             num_pos_sites (sites called positive), percent_pos_sites (= ratio), date (M/D/YYYY), date_value.
#           <t>_<s>_volume.csv: per filter sample, qPCR replicates positive ('detected') out of run ('count'), only
#             for site-occasions the authors kept (the analysis code: 'samples removed that had no difference
#             (detection = 0) between the two volumes'); a filtered subset, so its zeros are not recoverable.
#           Bd_/YLF_eDNA_lake_stream_analysis.R: the authors' GLMMs (lme4). No coordinates deposited.
# Mapping: unit = location (lake F-J, stream A-E), period = sampling occasion 1-4 (May-August 2016), taxon = BATDEN
#   (Bd) or RANA_YLF (yellow-legged frog eDNA, R. sierrae or R. boylii pooled as the source records it),
#   y = num_pos_sites, obs_trials = num_sites (the sites sampled at the location that month): responseType
#   binomial_count, the location-month's spatial replicates collapsed by the source to 'positive on y of
#   obs_trials sites'. date from the deposit (ISO). unit_system = lake / stream.
#   surveyEvidence = sample_table: the sampling_occ files list every location x occasion sampled (num_sites >= 1),
#   identical for Bd and YLF (same water samples, asserted).
#   Check against the volume files (asserted): for YLF the sites with >= 2 positive CN-filter replicates in the
#   volume file equal num_pos_sites at all 40 location-months; for Bd at 38 of 40 (lake F occasion 3 is called
#   positive with no positive CN replicate - its MCE filter had 4 of 6; stream C occasion 1 is 1 in the summary,
#   2 by the rule). The summary files ship as deposited.
#   Not shipped: the per-filter volume files (a subset of filters, zeros removed), percent_pos_sites (a ratio of
#   shipped columns), date_value (days since May 17, recoverable from date), the 2017 filter test (not deposited).
#   IUCN: R. sierrae EN, R. boylii VU, but no coordinates are deposited, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bedwell_2020_sierranevada_edna_binom"

dir <- download_dryad("10.5061/dryad.2jm63xsjv", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 11)

rd <- function(tx, s, k) fread(file.path(dir, sprintf("%s_%s_%s.csv", tx, s, k)))
so <- list(); vchk <- c()
for (tx in c("Bd", "YLF")) for (s in c("lakes", "streams")) {
  d <- rd(tx, s, "sampling_occ")
  setnames(d, sub("^num_pos$", "num_pos_sites", names(d)))
  stopifnot(identical(names(d), c("location", "sampling_occ", "num_sites", "num_pos_sites", "percent_pos_sites", "date", "date_value")),
            nrow(d) == 20L, uniqueN(d[, .(location, sampling_occ)]) == 20L, all(d$sampling_occ %in% 1:4),
            all(d$num_sites >= 1L), all(d$num_pos_sites >= 0L & d$num_pos_sites <= d$num_sites),
            isTRUE(all.equal(d$percent_pos_sites, d$num_pos_sites / d$num_sites, tolerance = 1e-6)))
  v <- rd(tx, s, "volume")
  if ("filter_type" %in% names(v)) v <- v[filter_type == 1L]
  stopifnot(all(v$volume %in% 1:2), all(v$detected <= v$count))
  b <- v[, .(det = sum(detected)), by = .(location, site, sampling_occ)][, .(npos = sum(det >= 2L)), by = .(location, sampling_occ)]
  m <- merge(d, b, by = c("location", "sampling_occ"), all.x = TRUE); m[is.na(npos), npos := 0L]
  vchk[paste(tx, s)] <- sum(m$npos != m$num_pos_sites)
  so[[paste(tx, s)]] <- d[, `:=`(target = tx, system = sub("s$", "", s))]
}
stopifnot(identical(unname(vchk), c(1L, 1L, 0L, 0L)))
so <- rbindlist(so)
stopifnot(identical(sort(unique(so[system == "lake"]$location)), LETTERS[6:10]),
          identical(sort(unique(so[system == "stream"]$location)), LETTERS[1:5]))
# the Bd and YLF summaries describe the same water samples
k <- c("location", "sampling_occ", "num_sites", "date", "date_value")
stopifnot(isTRUE(all.equal(so[target == "Bd", ..k], so[target == "YLF", ..k], check.attributes = FALSE)))
so[, date := format(as.Date(date, "%m/%d/%Y"))]
stopifnot(!anyNA(so$date), all(so$date >= "2016-05-16" & so$date <= "2016-08-21"),
          all(as.integer(as.Date(so$date) - as.Date("2016-05-16")) == so$date_value))

long <- so[, .(unit = location, taxon = ifelse(target == "Bd", "BATDEN", "RANA_YLF"), y = as.integer(num_pos_sites),
               period = as.integer(sampling_occ), date, unit_system = system, obs_trials = as.integer(num_sites))]
long <- order_eco(long)
stopifnot(nrow(long) == 80L, uniqueN(long$unit) == 10L, all(long$y <= long$obs_trials),
          sum(long[taxon == "BATDEN"]$y) == 20L, sum(long[taxon == "RANA_YLF"]$y) == 90L)
cat(sprintf("  %d rows; positive sites: Bd %d, YLF %d\n", nrow(long), sum(long[taxon == "BATDEN"]$y), sum(long[taxon == "RANA_YLF"]$y)))

taxa <- make_taxa(c("BATDEN", "RANA_YLF"), c("Batrachochytrium dendrobatidis", "Rana sierrae / Rana boylii"),
                  vernacularName = c("Amphibian chytrid fungus (Bd)", "Yellow-legged frogs (Sierra Nevada and foothill)"),
                  taxonRank = c("species", "species aggregate"), no_key = "RANA_YLF",
                  taxonRemarks = c(NA, "Pooled as the source records it: a qPCR replicate positive for the R. sierrae or the R. boylii assay (multiplexed) counts as one yellow-legged frog detection (paper section 2.3); the README says lakes had detections of R. sierrae only, and streams of one species or the other. Not a GBIF backbone taxon."))
periods <- data.table(period = 1:4, month = c("2016-05", "2016-06", "2016-07", "2016-08"),
                      first_date = so[, min(date), by = sampling_occ][order(sampling_occ)]$V1,
                      last_date = so[, max(date), by = sampling_occ][order(sampling_occ)]$V1)

dataset <- list(
  title = "Sites positive for yellow-legged frog and Bd eDNA at five lakes and five streams, monthly May to August 2016, Sierra Nevada, California",
  creator = "Bedwell, Mallory E.; Goldberg, Caren S.", pubDate = "2020",
  doi = "10.5061/dryad.2jm63xsjv", sourceURL = "https://doi.org/10.5061/dryad.2jm63xsjv",
  citation = "Bedwell, M. E., & Goldberg, C. S. (2020). Data from: Spatial and temporal patterns of environmental DNA detection to inform sampling protocols in lentic and lotic systems [Dataset]. Dryad. https://doi.org/10.5061/dryad.2jm63xsjv",
  paperDOI = "10.1002/ece3.6014",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "eDNA sampling-design study for the Sierra Nevada yellow-legged frog (Rana sierrae) and the foothill yellow-legged frog (R. boylii), with the chytrid fungus Bd from the same filters: five lakes and five streams sampled monthly from May to August 2016. At each visit the authors called each sampling site (a stream point, or a lake composite of five shore grabs) positive when at least two of six qPCR replicates from its 1 L and 2 L filters amplified. One row per location x month x target: y = sites called positive, obs_trials = sites sampled (1-7).",
  samplingProtocol = "Water filtered through 0.45 um cellulose nitrate filters (1 L and 2 L per site) at up to seven stream sites 100 m apart or at lake sites each made of five shore grabs 50 m apart; each filter run in triplicate in a qPCR multiplex (R. sierrae, R. boylii, Bd); a replicate is positive at Cq <= 45 and a site is positive with >= 2 of its 6 replicates positive (the authors' call).",
  samplingProtocolCode = "eDNA", surveyEvidence = "sample_table",
  responseType = "binomial_count", effortColumn = "obs_trials", unitKind = "site",
  closure = "none", closureNote = "one row per location x month (period); the spatial replicates within the visit (sampling sites) are collapsed by the source into obs_trials. Months are periods, across which occupancy may change.",
  occasionKind = "none", taxonInclusion = "target",
  geographicCoverage = "Five lakes and five streams with historical yellow-legged frog presence, Sierra Nevada, California, USA (locations given only as letters; no coordinates deposited)",
  temporalCoverage = "2016-05/2016-08",
  covariateNote = "unit_system: lake (sampling site = composite of five shore grabs 50 m apart) or stream (sampling site = one point, seven points 100 m apart). obs_trials: sites sampled that month (streams: fewer than 7 when the bed was dry).",
  notShipped = list(
    volume_files = "<target>_<system>_volume.csv, per-filter qPCR replicates: a subset of filter samples (the analysis code removed samples with no detection at either volume), so the filter-level survey set and its zeros cannot be recovered; the location-month summaries are shipped instead",
    percent_pos_sites = "the ratio num_pos_sites / num_sites of two shipped columns",
    date_value = "days since the first sampling day, recoverable from date",
    test_filters = "PES and MCE test filters at lakes (in the volume files only) and the 2017 filter comparison (not deposited)",
    model_output = "GLMM estimates of volume, filter and season effects"),
  notes = "The authors' site calls are shipped as deposited. Rebuilt from the volume files by the stated rule (>= 2 of 6 CN-filter replicates), the YLF calls agree at all 40 location-months and the Bd calls at 38: lake F in July is called Bd-positive with no positive CN replicate (its MCE test filter had 4 of 6), and stream C in May has 1 positive site in the summary and 2 by the rule. RANA_YLF pools the two frog assays as the source does.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/bedwell_2020_sierranevada_edna_binom.R")
stage_dict_row(TABLE,
  description = "Number of eDNA sampling sites positive for yellow-legged frogs (Rana sierrae / R. boylii) and for Bd, out of the sites sampled, at five lakes and five streams in the Sierra Nevada, California, monthly May to August 2016.",
  url = "https://doi.org/10.5061/dryad.2jm63xsjv",
  reference = "Bedwell, M. E. & Goldberg, C. S. (2020). Spatial and temporal patterns of environmental DNA detection to inform sampling protocols in lentic and lotic systems. Ecology and Evolution 10, 1602-1612. https://doi.org/10.1002/ece3.6014",
  doi_paper = "10.1002/ece3.6014", doi_data = "10.5061/dryad.2jm63xsjv",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Location x month summaries of the authors' site calls (binomial_count over sampling sites); the filter-level volume files are a zero-removed subset and are not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Dynamic occupancy (binomial counts over sampling sites, eDNA)",
  sampling_protocol = "eDNA", design = "Multi-season (4 monthly visits; 10 lakes and streams; 1-7 sites per visit collapsed to a count)",
  realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "eDNA protocol study; yellow-legged frogs (EN / VU) pooled as the source does, plus Bd from the same filters; no coordinates.")
