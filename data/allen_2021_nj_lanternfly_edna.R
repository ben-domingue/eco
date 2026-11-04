#!/usr/bin/env Rscript
# Table:  allen_2021_nj_lanternfly_edna
# Source: Dryad doi:10.5061/dryad.ghx3ffbp5 (CC0 1.0, as shown on the Dryad page and in the API
#         record), version 126419 (published 2021-06-23).
#   Allen, M. C., Nielsen, A. L., Peterson, D. L. & Lockwood, J. L. (2021). Data and code for:
#   Terrestrial eDNA survey outperforms conventional approach for detecting an invasive pest
#   insect within an agricultural ecosystem. Dryad.
# Paper:  Allen, M. C., Nielsen, A. L., Peterson, D. L. & Lockwood, J. L. (2021). Terrestrial eDNA
#         survey outperforms conventional approach for detecting an invasive pest insect within an
#         agricultural ecosystem. Environmental DNA. doi:10.1002/edn3.231.
# Data:   NJ_vineyards.csv: one row per plot survey (94 rows): site (vineyard name, 12), date,
#         sample (plot code: two-letter vineyard code + plot number 1-4, "-2" appended in round
#         two; Tomasello is TO in round one and TS in round two), number.filters, volume.filtered
#         (ml), volume.collected (ml of spray-aggregation rinse water), number.SLF.visual (spotted
#         lanternflies counted in the visual survey of the plot), how.preserved (ethanol /
#         freezer), extract.vol, qpcr.run, ctmean / ctsd / qmean / qsd (Ct and DNA quantity over the
#         replicates that amplified, NA where none did), pcr1-pcr3 (amplification in each of three
#         qPCR technical replicates, 0/1), pres (any replicate amplified).
#         NJ_vineyards_metadata.txt defines the columns; README.txt; NJ_vineyards.Rmd is the
#         authors' analysis (JAGS multi-method and multi-scale occupancy models).
#         Quirks: 14 round-one rows (Terhune, Working Dog, Tomasello, Bellview) are dated
#         2016-09-09, impossible for a 2019 study (round one was September 2019 by the paper and
#         by the Rmd's own date split); Bellview plots 3 and 4 were surveyed in round two only
#         (the paper: "two plots that were only sampled once, during round two").
#         Dryad methods: four plots in each of 12 vineyards, each sampled twice (round one 9-18
#         September, round two 30 September-14 October 2019); per plot survey, spray aggregation
#         of 12-24 vines for eDNA (one filter tested per plot, three qPCR replicates, positive if any
#         replicate amplified) while the same vines were inspected visually and lanternflies
#         counted. The primary analysis treats three "suspected false positives" (round-one samples
#         AV2, AV3, TO4) as negatives; a parallel analysis keeps them positive.
#
# Mapping (standard E9 experimental: multi-scale / eDNA with a second method, as
#   dougherty_2016_rustycrayfish_edna; responseType detection, unitKind site):
#   cluster_id = vineyard (the paper's primary "sample unit"), unit = plot ("<vineyard code>_<plot
#   number>", the same plot in both rounds; Tomasello's two codes unified as TO), period = survey
#   round (1, 2; the authors' plot-level occupancy changes between rounds as lanternflies disperse
#   into vineyards), occasion 1-3 = qPCR technical replicate of the plot's eDNA sample (y = pcrk),
#   occasion 4 = visual survey of the same vines (y = 1 if any lanternfly counted, y_raw = count);
#   obs_method = "eDNA qPCR" / "visual". occasionKind = c("method", "spatial") (method x replicate,
#   E8). date as deposited, empty for the 14 plot surveys dated 2016-09-09 (not corrected: the day may also
#   be wrong). Sample covariates on the qPCR rows (NA on visual rows): obs_filters,
#   obs_volume_filtered_ml, obs_volume_collected_ml, obs_preservation, obs_extract_volume_ul,
#   obs_qpcr_run; obs_suspected_false_positive = 1 on the qPCR rows of AV2, AV3, TO4 (the authors'
#   primary analysis sets them to 0; the rows ship as deposited).
#   Survey evidence = sample_table: every row of NJ_vineyards.csv is a conducted plot survey with
#   both methods (no NA in pcr1-3 or the visual count, asserted). No coordinates in the deposit
#   (the paper gives only the latitude / longitude range); the species is an invasive, not flagged.
#   Not shipped: pres (the any-replicate summary, rebuilt exactly from pcr1-3 and asserted), ctmean,
#   ctsd, qmean, qsd (summaries over the amplified replicates; the authors' per-sample DNA quantity
#   is derived from them), the field positive / negative controls (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "allen_2021_nj_lanternfly_edna"
dir <- download_dryad("10.5061/dryad.ghx3ffbp5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("NJ_vineyards.csv", "NJ_vineyards_metadata.txt", "NJ_vineyards.Rmd", "README.txt")))
d <- fread(file.path(dir, "NJ_vineyards.csv"), colClasses = list(character = c("date", "sample", "qpcr.run")))

# facts about the source
stopifnot(identical(names(d), c("site", "date", "sample", "number.filters", "volume.filtered", "volume.collected",
                                "number.SLF.visual", "how.preserved", "extract.vol", "qpcr.run", "ctmean", "ctsd", "qmean",
                                "qsd", "pcr1", "pcr2", "pcr3", "pres")),
          nrow(d) == 94L, uniqueN(d$site) == 12L, !anyDuplicated(d$sample),
          !anyNA(d[, .(site, date, sample, number.SLF.visual, pcr1, pcr2, pcr3, pres, number.filters, volume.filtered,
                       volume.collected, how.preserved, extract.vol, qpcr.run)]),
          all(unlist(d[, .(pcr1, pcr2, pcr3, pres)]) %in% 0:1), d[, all(pres == pmax(pcr1, pcr2, pcr3))],
          all(d$number.SLF.visual >= 0), all(d$number.SLF.visual == round(d$number.SLF.visual)),
          setequal(d$how.preserved, c("ethanol", "freezer")),
          d[, all(is.na(ctmean) == (pres == 0))],                         # Ct only where a replicate amplified
          all(grepl("^[A-Z]{2}[1-4](-2)?$", d$sample)),
          all(substr(d$date, 1, 4) %in% c("2016", "2019")))
d[, round := ifelse(grepl("-2$", sample), 2L, 1L)]
d[, plot := as.integer(substr(sample, 3, 3))]
d[, code := substr(sample, 1, 2)]
# the 2016 dates are all round one; the round split by date (the Rmd's rule) agrees with the -2 suffix
stopifnot(d[substr(date, 1, 4) == "2016", all(round == 1L)], d[substr(date, 1, 4) == "2016", .N] == 14L,
          d[substr(date, 1, 4) == "2016", setequal(site, c("Terhune", "Working Dog", "Tomasello", "Bellview"))],
          d[substr(date, 1, 4) == "2019", all((date > "2019-09-29") == (round == 2L))])
# vineyard codes: one per vineyard, except Tomasello (TO in round one, TS in round two)
stopifnot(d[site != "Tomasello", uniqueN(code), by = site][, all(V1 == 1)],
          identical(d[site == "Tomasello", sort(unique(paste(round, code)))], c("1 TO", "2 TS")))
d[site == "Tomasello", code := "TO"]
stopifnot(d[, uniqueN(site), by = code][, all(V1 == 1)], d[, uniqueN(code), by = site][, all(V1 == 1)])
d[, unit := paste0(code, "_", plot)]
stopifnot(uniqueN(d$unit) == 48L, !anyDuplicated(d[, .(unit, round)]), d[round == 2L, .N] == 48L, d[round == 1L, .N] == 46L,
          identical(sort(setdiff(d[round == 2L, unit], d[round == 1L, unit])), c("BV_3", "BV_4")))
# the three suspected false positives of the paper's primary analysis
SFP <- c("AV2", "AV3", "TO4")
stopifnot(d[sample %in% SFP, all(pres == 1L & round == 1L & number.SLF.visual == 0)])

base <- d[, .(unit, period = round, date = ifelse(substr(date, 1, 4) == "2019", date, NA_character_), cluster_id = site, sample)]
q <- rbindlist(lapply(1:3, function(k) d[, .(unit, period = round, occasion = k, y = as.integer(get(paste0("pcr", k))),
                                               obs_method = "eDNA qPCR", obs_filters = as.integer(number.filters),
                                               obs_volume_filtered_ml = volume.filtered, obs_volume_collected_ml = volume.collected,
                                               obs_preservation = how.preserved, obs_extract_volume_ul = extract.vol,
                                               obs_qpcr_run = qpcr.run,
                                               obs_suspected_false_positive = as.integer(sample %in% SFP))]))
v <- d[, .(unit, period = round, occasion = 4L, y = as.integer(number.SLF.visual > 0), y_raw = as.integer(number.SLF.visual),
           obs_method = "visual")]
long <- rbindlist(list(q, v), fill = TRUE)
long <- merge(long, base, by = c("unit", "period"))
long[, sample := NULL]
long[, taxon := "LYCDEL"]
long <- order_eco(long)
stopifnot(nrow(long) == 94L * 4L, !anyDuplicated(long[, .(unit, period, occasion)]),
          long[obs_method == "visual", sum(y)] == d[, sum(number.SLF.visual > 0)],
          long[obs_method != "visual", sum(y)] == d[, sum(pcr1 + pcr2 + pcr3)])
cat(sprintf("  %d rows, %d plots in %d vineyards; eDNA-positive plot surveys %d of 94 (replicates %d of 282); visual %d of 94\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), d[, sum(pres)], long[occasion <= 3, sum(y)],
            long[occasion == 4, sum(y)]))

taxa <- make_taxa("LYCDEL", "Lycorma delicatula", vernacularName = "Spotted lanternfly")
periods <- data.table(period = 1:2, period_label = c("Round 1", "Round 2"),
                      period_start = c("2019-09-04", "2019-09-30"), period_end = c("2019-09-18", "2019-10-14"))
stopifnot(long[period == 1L & !is.na(date), all(date >= "2019-09-04" & date <= "2019-09-18")],
          long[period == 2L, all(date >= "2019-09-30" & date <= "2019-10-14")])
dataset <- list(
  title = "Spotted lanternfly eDNA qPCR replicates and paired visual surveys in 48 plots at 12 New Jersey vineyards, two rounds, autumn 2019",
  creator = "Allen, Michael C.; Nielsen, Anne L.; Peterson, Donnie L.; Lockwood, Julie L.",
  pubDate = "2021", doi = "10.5061/dryad.ghx3ffbp5", sourceURL = "https://doi.org/10.5061/dryad.ghx3ffbp5", paperDOI = "10.1002/edn3.231",
  citation = "Allen, M. C., Nielsen, A. L., Peterson, D. L., & Lockwood, J. L. (2021). Data and code for: Terrestrial eDNA survey outperforms conventional approach for detecting an invasive pest insect within an agricultural ecosystem [Data set]. Dryad. https://doi.org/10.5061/dryad.ghx3ffbp5",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Paired terrestrial eDNA (spray aggregation of grapevine foliage, three qPCR technical replicates) and visual surveys for the invasive spotted lanternfly (Lycorma delicatula) in four plots at each of 12 vineyards along the invasion front in New Jersey, USA, in two rounds (September and early October 2019; two plots in round two only). The authors' multi-method occupancy model put per-plot detection at 84% for eDNA against 36% for visual search; eDNA detected lanternflies at five plots in three vineyards in round one, when visual search found one individual.",
  samplingProtocol = "Each plot (12-24 grapevines) was sprayed with deionized water at about 2 m/min while the rinse was collected in buckets, filtered on site (10-micron filter), and one filter per plot extracted (HotSHOT) and tested with a species-specific TaqMan qPCR assay (ITS1) in three technical replicates; during spraying the same vines were inspected and lanternflies counted. Sampling at least 24 h after rain.",
  samplingProtocolCode = "eDNA", surveyEvidence = "sample_table",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = c("method", "spatial"), taxonInclusion = "single",
  closureNote = "plot state closed within one plot survey: occasions 1-3 are qPCR replicates of the plot's eDNA sample and occasion 4 the visual search of the same vines at the same visit; the state may change between rounds (period)",
  occasionCodes = list(`1` = "qPCR technical replicate 1", `2` = "qPCR technical replicate 2", `3` = "qPCR technical replicate 3",
                       `4` = "visual survey (y_raw = lanternflies counted)"),
  designNote = "Experimental list of E9 (multi-scale / eDNA, multi-method): cluster_id = vineyard (the paper's sample unit), unit = plot, period = survey round, occasion = qPCR replicate or visual survey, obs_method distinguishes the two methods. The authors' eDNA detection per plot survey is any of occasions 1-3.",
  geographicCoverage = "12 vineyards in New Jersey, USA, along the spotted lanternfly invasion front by the Pennsylvania border (latitude 39.540 to 40.616, longitude -74.536 to -75.411, from the paper)",
  temporalCoverage = "2019-09/2019-10",
  notes = "obs_suspected_false_positive = 1 marks the qPCR rows of the three round-one samples (AV2, AV3, TO4) the paper's primary analysis treats as negatives; they ship as deposited (a parallel analysis in the paper keeps them positive). 14 round-one plot surveys are dated 2016-09-09 in the deposit (Terhune, Working Dog, Tomasello, Bellview), impossible for this 2019 study; their date is left empty. Deposited round-one dates run 4-18 September, though the paper says 9-18 September. Bellview plots 3 and 4 were surveyed in round two only. Tomasello's plot codes are TO in round one and TS in round two; unit uses TO. Sample covariates (filters, volumes, preservation, extraction volume, qPCR run) are on the qPCR rows and NA on visual rows.",
  notShipped = list(pres = "any-replicate eDNA detection per plot survey; rebuilt exactly from pcr1-pcr3 (asserted)",
                    `ctmean, ctsd, qmean, qsd` = "Ct and DNA quantity summarised over the replicates that amplified (per-sample summaries across occasions)",
                    controls = "field positive and negative controls per vineyard visit are described in the paper but not deposited"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/allen_2021_nj_lanternfly_edna.R")
stage_dict_row(TABLE,
  description = "Invasive spotted lanternfly (Lycorma delicatula) in 48 plots at 12 New Jersey vineyards, two rounds in autumn 2019: three eDNA qPCR replicates of spray-aggregation samples plus the paired visual count of the same vines (multi-method, cluster_id = vineyard).",
  url = "https://doi.org/10.5061/dryad.ghx3ffbp5",
  reference = "Allen, M. C., Nielsen, A. L., Peterson, D. L., & Lockwood, J. L. (2021). Terrestrial eDNA survey outperforms conventional approach for detecting an invasive pest insect within an agricultural ecosystem. Environmental DNA. https://doi.org/10.1002/edn3.231",
  doi_paper = "10.1002/edn3.231", doi_data = "10.5061/dryad.ghx3ffbp5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental E9 (multi-scale eDNA, multi-method): qPCR replicates as occasions 1-3, visual survey as occasion 4 (obs_method); period = round. Three suspected false positives flagged, not recoded.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (terrestrial eDNA qPCR with visual survey)",
  sampling_protocol = "eDNA", design = "Multi-season (2 survey rounds, 4 plots per vineyard)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source",
  notes = "Invasive insect; eDNA from foliage spray aggregation paired with visual counts at the same plot survey.")
