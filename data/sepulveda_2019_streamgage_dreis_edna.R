#!/usr/bin/env Rscript
# Table:  sepulveda_2019_streamgage_dreis_edna  (streamgage > sampling event > 2-L water sample > qPCR
#         replicate; dreissenid mussel eDNA, DRE16S assay, below eight Bureau of Reclamation reservoirs and
#         Lake Powell, May-September 2018)
# Source: USGS ScienceBase, doi:10.5066/P9Q8GCLM, child item 5c9c1738e4b0b8a7f62c3617 "Dreissenid mussel eDNA
#         results for streamgage water samples in the Columbia and Colorado River basin". USGS data release, US
#         public domain; the FGDC metadata's access and use constraints are "None" (asserted).
#   Sepulveda, A.J., 2019, Environmental DNA surveillance data for USGS streamgage sampling in the Columbia River
#   Basin, 2018 (ver. 1.1, July 2019): U.S. Geological Survey data release.
# Paper:  Sepulveda, A. J. et al. (2019). Adding invasive species biosurveillance to the U.S. Geological Survey
#         streamgage network. Ecosphere 10(8), e02843, doi:10.1002/ecs2.2843 (not read). The design is from the
#         release's FGDC metadata (Dreissenid_eDNA_data.xml, procedure description): monthly sampling May-September
#         2018 plus a second July event; at each event a 2-L deionised-water field blank exposed for 10 s, then
#         three 2-L river samples (ten at American Falls and Ririe at the second July and September events);
#         Phase 1 screen with the Dreissena-specific 16S qPCR assay (Gingera et al. 2017) in quadruplicate; any
#         sample, blank or control with an amplified replicate goes to Phase 2-4 verification (retest, the
#         species-specific QM / ZM assays, 16S sequencing).
# Data:   Dreissenid_eDNA_data.csv (1,088 rows): Site (9 streamgages + EXTNEG), Month (event label May, June,
#           July_1, July_2, August, September), Date (YYYYMMDD; the June events at Lees Ferry and Island Park are 20180600, day not
#           recorded), SampleType (FieldSample, FieldBlank, ExtractionNegative), Marker (DRE16S screen; QM, ZM and
#           16S_sequencing follow-ups on Jackson Lake and Palisades June samples and blanks), Sample_rep, PCR_rep,
#           Cq (NaN = no amplification), Sq (copies per reaction), Inhibited, Retest (empty), BLAST columns for the
#           sequenced follow-ups. No coordinates.
#         Quirk: at American Falls the samples 5-10 of the second July event have PCR replicates 1 and 3 under
#           20180718 (July_1) and 2 and 4 under 20180730 (July_2); they are shipped as recorded (asserted), so
#           those units have two occasions each. The fish file of the same release puts those ten samples on
#           07-30 only; the two files cannot be joined (see sepulveda_2019_streamgage_fish_edna).
# Mapping (E9 experimental, multi-scale eDNA; eDNA detection-call ruling 2026-11-06): cluster_id = streamgage,
#   period = event 1..6 (the Month label), unit = <site>_<date>_<sample rep> (one 2-L river sample), occasion =
#   qPCR replicate 1..4, taxon = DREISS (Dreissena, the genus the 16S assay targets), y = 1 where the DRE16S
#   replicate amplified (a Cq value), 0 where Cq is NaN; y_raw = Cq as deposited; obs_sq_copies (Sq, 0 where
#   NaN), obs_inhibited (1/0), obs_blank_positive = 1 on every row of an event whose field blank amplified in any
#   of its four replicates (5 of 54 events), else 0. date = the sampling date (empty for the two June events recorded as 20180600).
#   surveyEvidence = sample_table (every field sample x replicate is a row of the deposit).
#   E7: no coordinates in this file; dreissenids are invasive in these basins (not flagged).
# Not shipped: field-blank and extraction-negative rows as units (controls; the blank result is obs_blank_positive);
#   the QM / ZM / 16S-sequencing follow-ups (Phase 2-4 verification of 8 June samples and blanks at Jackson Lake
#   and Palisades; their zebra-mussel reads in blank and sample alike indicate contamination by the release's own
#   evidence, and a second-method confirmation on 4 samples would need detectionCertainty rows for which the
#   release has no survey set); BLAST sequence fields.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sepulveda_2019_streamgage_dreis_edna"
SB <- "https://www.sciencebase.gov/catalog/file/get/5c9c1738e4b0b8a7f62c3617?f=%s"
f  <- download_cached(sprintf(SB, "__disk__d4%2F8f%2Fc1%2Fd48fc1fe1a48869493a33e66307bfdbc22188690"), TABLE, filename = "Dreissenid_eDNA_data.csv")
fx <- download_cached(sprintf(SB, "__disk__d2%2F9f%2Ff9%2Fd29ff9a6ab46514a37ce4c5cd31a88c154cb397e"), TABLE, filename = "Dreissenid_eDNA_data.xml")
xml <- paste(readLines(fx, warn = FALSE), collapse = "\n")
stopifnot(grepl("<useconst>None.", xml, fixed = TRUE), grepl("<accconst>None.", xml, fixed = TRUE))

d <- fread(f, colClasses = "character")
stopifnot(nrow(d) == 1088L, identical(d[, .N, by = Marker][order(Marker)]$N, c(8L, 1016L, 32L, 32L)))
x <- d[Marker == "DRE16S" & SampleType != "ExtractionNegative"]
stopifnot(nrow(x) == 992L, all(x$SampleType %in% c("FieldSample", "FieldBlank")), uniqueN(x$Site) == 9L,
          all(x$Cq == "NaN" | grepl("^[0-9]+(\\.[0-9]+)?$", x$Cq)), all(x$Inhibited %in% c("Yes", "No")),
          all(is.na(x$Retest) | x$Retest %in% c("NA", "NaN")), all(x$PCR_rep %in% as.character(1:4)))
ev <- c("May", "June", "July_1", "July_2", "August", "September")
stopifnot(all(x$Month %in% ev), x[, uniqueN(Month), by = Site][, all(V1 == 6L)], x[, uniqueN(Date), by = .(Site, Month)][, all(V1 == 1L)],
          identical(sort(x[Date == "20180600", unique(paste(Site, Month))]), c("Colorado_LeesFerry June", "Island_Park June")))
x[, period := match(Month, ev)]
# dates increase with the event label at every gage
stopifnot(x[, .(d = Date[1]), by = .(Site, period)][order(Site, period)][, all(diff(as.integer(d)) > 0), by = Site][, all(V1)])
# field blanks: one per event, four replicates
fb <- x[SampleType == "FieldBlank"]
stopifnot(nrow(fb) == 216L, fb[, .N, by = .(Site, period)][, .N == 54L && all(N == 4L)], all(fb$Sample_rep == "1"))
bp <- fb[, .(obs_blank_positive = as.integer(any(Cq != "NaN"))), by = .(Site, period)]
stopifnot(sum(bp$obs_blank_positive) == 5L)
s <- x[SampleType == "FieldSample"]
stopifnot(nrow(s) == 776L)
# the American Falls split: samples 5-10 have replicates 1,3 under July_1 and 2,4 under July_2
af <- s[Site == "American_Falls" & as.integer(Sample_rep) >= 5L & Month %in% c("July_1", "July_2")]
stopifnot(nrow(af) == 24L, all(af[Month == "July_1"]$PCR_rep %in% c("1", "3")), all(af[Month == "July_2"]$PCR_rep %in% c("2", "4")),
          s[!(Site == "American_Falls" & as.integer(Sample_rep) >= 5L & Month %in% c("July_1", "July_2")), .N, by = .(Site, Date, Sample_rep)][, all(N == 4L)])
s <- merge(s, bp, by = c("Site", "period"))
s[, date := ifelse(Date == "20180600", NA_character_, format(as.IDate(Date, "%Y%m%d")))]
long <- s[, .(unit = paste(Site, Date, Sample_rep, sep = "_"), taxon = "DREISS", y = as.integer(Cq != "NaN"), y_raw = Cq,
              period, occasion = as.integer(PCR_rep), date, cluster_id = Site,
              obs_sq_copies = ifelse(Sq == "NaN", 0, as.numeric(Sq)), obs_inhibited = as.integer(Inhibited == "Yes"), obs_blank_positive)]
long <- order_eco(long)
stopifnot(nrow(long) == 776L, !anyDuplicated(long[, .(unit, occasion)]), sum(long$y) == 91L,
          sum(long[cluster_id == "Colorado_LeesFerry"]$y) == 72L, sum(long$obs_blank_positive) == 60L)
cat(sprintf("  %d rows, %d samples, %d positive replicates (%d at Lees Ferry), %d rows in blank-positive events\n",
            nrow(long), uniqueN(long$unit), sum(long$y), sum(long[cluster_id == "Colorado_LeesFerry"]$y), sum(long$obs_blank_positive)))

taxa <- make_taxa("DREISS", "Dreissena", vernacularName = "Dreissenid mussels (zebra and quagga mussels)", taxonRank = "genus",
                  allow_higher = "DREISS", taxonRemarks = "The DRE16S assay (Gingera et al. 2017) amplifies both Dreissena polymorpha and D. rostriformis bugensis; the screen does not separate them")
periods <- data.table(period = 1:6, event = ev, month = c(5L, 6L, 7L, 7L, 8L, 9L), year = 2018L)

dataset <- list(
  title = "Dreissenid mussel eDNA (16S qPCR) in water samples at nine USGS streamgages below reservoirs, Columbia and Colorado River basins, May-September 2018",
  creator = "Sepulveda, Adam J.", pubDate = "2019",
  doi = "10.5066/P9Q8GCLM", sourceURL = "https://doi.org/10.5066/P9Q8GCLM",
  citation = "Sepulveda, A.J., 2019, Environmental DNA surveillance data for USGS streamgage sampling in the Columbia River Basin, 2018 (ver. 1.1, July 2019): U.S. Geological Survey data release, https://doi.org/10.5066/P9Q8GCLM.",
  paperDOI = "10.1002/ecs2.2843",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain, no access or use constraints"),
  abstract = "Early-detection eDNA surveillance for invasive zebra and quagga mussels at USGS streamgages below eight Bureau of Reclamation reservoirs in the Columbia River Basin and at Lees Ferry below Lake Powell (invaded), with six sampling events May-September 2018. Each 2-L river sample was screened with the Dreissena 16S qPCR assay in four replicates; one row per sample x replicate, with the event's field-blank result.",
  samplingProtocol = "USGS hydrologic technicians took a 2-L deionised-water field blank and then three (or ten) 2-L grab samples of river water at each gage and event, filtered on site (1.5 um MCE); DNA extracted at UMESC and screened with the DRE16S qPCR assay in quadruplicate reactions.",
  samplingProtocolCode = "eDNA", surveyEvidence = "sample_table",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "qPCR replicates of one extract; sampling events (periods) are about a month apart",
  occasionKind = "spatial", taxonInclusion = "single",
  geographicCoverage = "USGS streamgages below American Falls, Grand Coulee, Hungry Horse, Island Park, Jackson Lake, Owyhee, Palisades and Ririe reservoirs (Idaho, Montana, Oregon, Washington, Wyoming) and at Lees Ferry, Arizona (Colorado River); no coordinates in this file",
  temporalCoverage = "2018-05/2018-09",
  covariateNote = "obs_sq_copies: estimated copies per 25-ul reaction (0 where no amplification). obs_inhibited: 1 if the sample was inhibited. obs_blank_positive: 1 on every row of an event whose field blank amplified in any of its four DRE16S replicates (Jackson Lake and Palisades June, Grand Coulee June, Owyhee July_1, Lees Ferry July_2).",
  notShipped = list(controls = "field blanks (54 events x 4 replicates; summarised in obs_blank_positive) and the extraction negatives",
                    verification = "QM and ZM species assays and 16S sequencing of the June Jackson Lake and Palisades samples and blanks (Phase 2-4 verification); they read zebra mussel in blank and sample alike, i.e. contamination",
                    sequences = "BLAST query length, coverage, identity, species and sequence fields"),
  notes = "Positive replicates outside Lees Ferry (Lake Powell is invaded) are single replicates and several come from events whose field blank also amplified; the release's own verification treats the June Jackson Lake and Palisades positives as contamination. American Falls samples 5-10 of the second July event have replicates 1 and 3 under 2018-07-18 and 2 and 4 under 2018-07-30, as deposited. The June dates at Lees Ferry and Island Park are recorded as 20180600, so those rows have no date.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/sepulveda_2019_streamgage_dreis_edna.R")
stage_dict_row(TABLE,
  description = "Dreissenid mussel eDNA qPCR replicates for 2-L water samples at nine USGS streamgages below reservoirs in the Columbia and Colorado River basins, six events May-September 2018, with field-blank flags.",
  url = "https://doi.org/10.5066/P9Q8GCLM",
  reference = "Sepulveda, A. J., Schmidt, C., Amberg, J., Hutchins, P., Stratton, C., Mebane, C., Laramie, M. B., & Pilliod, D. S. (2019). Adding invasive species biosurveillance to the U.S. Geological Survey streamgage network. Ecosphere, 10(8), e02843.",
  doi_paper = "10.1002/ecs2.2843", doi_data = "10.5066/P9Q8GCLM",
  original_license = "US Government public domain (USGS data release; no use constraints)", derived_license = "CC0 1.0",
  notes = "DRE16S screen replicates; y = amplified (eDNA detection-call ruling 2026-11-06), Cq in y_raw; obs_blank_positive for events whose field blank amplified.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (eDNA)",
  sampling_protocol = "eDNA", design = "Multi-season (6 sampling events; 3-10 samples x 4 qPCR replicates; 9 streamgages)",
  realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Experimental (E9) multi-scale eDNA; invasive-species surveillance; field-blank flags.")
