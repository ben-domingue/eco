#!/usr/bin/env Rscript
# Table:  sepulveda_2019_streamgage_fish_edna  (streamgage > sampling event > 2-L water sample >
#         qPCR replicate; kokanee and yellow perch eDNA below eight Bureau of Reclamation
#         reservoirs and Lake Powell, May-September 2018)
# Source: USGS ScienceBase, doi:10.5066/P9Q8GCLM, ver. 1.1 (2019-07-19), child item
#         5c9c17eae4b0b8a7f62c361d "Fish eDNA results for streamgage water samples in the
#         Columbia and Colorado River basins". USGS data release: US public domain; the FGDC
#         metadata gives no access or use constraints ("None").
#   Sepulveda, A.J., 2019, Environmental DNA surveillance data for USGS streamgage sampling in
#   the Columbia River Basin, 2018 (ver. 1.1, July 2019): U.S. Geological Survey data release.
# Paper:  Sepulveda, A. J., Schmidt, C., Amberg, J., Hutchins, P., Stratton, C., Mebane, C.,
#         Laramie, M. B. & Pilliod, D. S. (2019). Adding invasive species biosurveillance to the
#         U.S. Geological Survey streamgage network. Ecosphere 10(8), e02843.
#         doi:10.1002/ecs2.2843 (CC BY 3.0; not read: Wiley refuses scripted requests). Everything
#         below is from the release's FGDC metadata (Kokanee_Perch_eDNA_data.xml).
# Data:   Kokanee_Perch_eDNA_data.csv, 488 rows = 244 samples x 2 target species. SampleID =
#         <site acronym>_<date>_<n>, n = 1..3 river samples (1..10 at American Falls on
#         2018-07-30 and 2018-09-25 and at Ririe on 2018-07-30 and 2018-09-19, a test of sample
#         size), FB = the 2-L deionised-water field blank of that event, plus one "Extraction
#         blank" row; the six Lake Powell (LF) dates after July are written MMDDYYYY
#         (08282018, 09132018), the rest YYYYMMDD. PCR1..PCR4 = four qPCR replicates of the
#         sample's extract, 1 = the replicate reached the assay's four-replicate LOD (kokanee
#         1.2, perch 1.9 copies/reaction); Inhibited = PCR inhibition in the sample; Latitude,
#         Longitude = the USGS streamgage; Target_RelativeAbundance (Low/Mid/High) and
#         Target_RelativeAbundance_Comment = fisheries managers' view of the species in the
#         upstream reservoir; GageDistanceFromReservoir_km; ReservoirStorage_m^3, Reservoir
#         Inflow_cms and Outflow_cms on the sampling date. Six sampling events per gage (monthly
#         May-September 2018 with two in July); Ririe 2018-07-18 has no field blank.
#         Dreissenid_eDNA_data.csv (child item 5c9c1738e4b0b8a7f62c3617) reports a third assay on
#         samples from the same events but its sample sets and dates do not match this file
#         (American Falls has ten samples on 07-18 there and on 07-30 here; Island Park's
#         September event is 09-10 there and 09-24 here; Ririe August has four samples there),
#         so the two cannot be joined; it is held (queue/human_review.csv).
# Mapping (standard E1-E5; E9 experimental: multi-scale occupancy / eDNA):
#   cluster_id = streamgage (8 Columbia-basin gages named for the reservoir above them, and
#   Lees Ferry below Lake Powell); period = sampling event 1..6 at that gage, in date order
#   (May, June, July 1, July 2, August, September; __periods); unit = river water sample
#   (SampleID as deposited), occasion = qPCR replicate 1..4, taxon = KOK (kokanee, Oncorhynchus
#   nerka) or YEPE (yellow perch, Perca flavescens), y = 0/1 as deposited, date = sampling
#   date. Both assays were run on every sample, so every sample carries both taxa.
#   unit_: gage latitude/longitude (agency-published streamgage locations, kept as published),
#   distance of the gage from the reservoir outlet, reservoir storage, inflow and outflow on the
#   sampling date (constant within a sample). obs_ (vary by taxon at one sample, E5): the
#   sample's inhibition flag for that assay (differs between the assays for 2 samples); the
#   number of the event's four field-blank replicates that amplified for that target (NA at
#   Ririe 2018-07-18, which has no blank); the managers' relative-abundance class of the
#   target in the upstream reservoir (Low/Mid/High, NA = none given; external to these
#   detections). Survey evidence = deposited_matrix: every sample x target row carries four
#   0/1 replicate results, none missing.
#   NOT shipped: field-blank rows as units (controls, not river samples; their result is the
#   obs_ count above), the extraction blank, Target_RelativeAbundance_Comment (free-text
#   personal communications; one includes a manager's telephone number).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sepulveda_2019_streamgage_fish_edna"
SCRIPT <- "data/sepulveda_2019_streamgage_fish_edna.R"
SB <- "https://www.sciencebase.gov/catalog/file/get/5c9c17eae4b0b8a7f62c361d?f=%s"
f <- download_cached(sprintf(SB, "__disk__48%2Fe9%2F81%2F48e9816be6fff0eb7ab4dd6d9ff7686151399905"),
                     "sepulveda_2019_columbia_streamgage_edna", filename = "Kokanee_Perch_eDNA_data.csv")
d <- fread(f, colClasses = list(character = "SampleID"))
setnames(d, c("ReservoirStorage_m^3", "Reservoir Inflow_cms"), c("ReservoirStorage_m3", "ReservoirInflow_cms"))
stopifnot(nrow(d) == 488, identical(sort(unique(d$TargetSpecies)), c("Kokanee", "YellowPerch")),
          all(unlist(d[, PCR1:PCR4]) %in% c(0, 1)), all(d$Inhibited %in% c("No", "Yes")))
d <- d[Site != "Extraction blank"]
stopifnot(nrow(d) == 486)
d[, c("acr", "dstr", "rep") := tstrsplit(SampleID, "_", fixed = TRUE)]
stopifnot(all(nchar(d$dstr) == 8))
d[, date := as.IDate(ifelse(substr(dstr, 1, 4) == "2018", dstr, paste0(substr(dstr, 5, 8), substr(dstr, 1, 4))), "%Y%m%d")]
stopifnot(!anyNA(d$date), all(d$date >= as.IDate("2018-05-16") & d$date <= as.IDate("2018-09-25")),
          d[substr(dstr, 1, 4) != "2018", all(acr == "LF")])
# one acronym, one gage location per site; six events per gage; both targets on every sample
stopifnot(d[, uniqueN(acr), by = Site][, all(V1 == 1)], d[, uniqueN(paste(Latitude, Longitude)), by = Site][, all(V1 == 1)],
          d[, uniqueN(date), by = Site][, all(V1 == 6)], uniqueN(d$Site) == 9,
          d[, .N, by = .(SampleID)][, all(N == 2)], !anyDuplicated(d[, .(SampleID, TargetSpecies)]))
# reservoir and gage covariates are constant within a site-date
stopifnot(d[, lapply(.SD, uniqueN), by = .(Site, date),
            .SDcols = c("GageDistanceFromReservoir_km", "ReservoirStorage_m3", "ReservoirInflow_cms", "Outflow_cms")][, all(unlist(.SD) == 1), .SDcols = -(1:2)])
setorder(d, Site, date)
d[, period := match(date, sort(unique(date))), by = Site]

fb <- d[rep == "FB", .(Site, date, TargetSpecies, obs_fieldblank_pcr_pos = PCR1 + PCR2 + PCR3 + PCR4)]
stopifnot(nrow(fb) == 53 * 2, sum(fb$obs_fieldblank_pcr_pos) == 8,
          fb[obs_fieldblank_pcr_pos > 0, all(TargetSpecies == "Kokanee")])
s <- d[rep != "FB"]
stopifnot(all(s$rep %in% as.character(1:10)), nrow(s) == 2 * (54 * 3 + 4 * 7))   # 190 samples
s <- merge(s, fb, by = c("Site", "date", "TargetSpecies"), all.x = TRUE)
stopifnot(s[is.na(obs_fieldblank_pcr_pos), all(Site == "Ririe" & date == as.IDate("2018-07-18"))])

TX <- c(Kokanee = "KOK", YellowPerch = "YEPE")
long <- melt(s, id.vars = c("SampleID", "Site", "TargetSpecies", "period", "date", "Latitude", "Longitude",
                            "GageDistanceFromReservoir_km", "ReservoirStorage_m3", "ReservoirInflow_cms", "Outflow_cms",
                            "Inhibited", "obs_fieldblank_pcr_pos", "Target_RelativeAbundance"),
             measure.vars = paste0("PCR", 1:4), variable.name = "pcr", value.name = "y")
long <- long[, .(unit = SampleID, taxon = unname(TX[TargetSpecies]), y = as.integer(y),
                 period = as.integer(period), occasion = as.integer(sub("PCR", "", pcr)), date = format(date),
                 cluster_id = gsub(" ", "_", Site),
                 unit_latitude = Latitude, unit_longitude = Longitude, unit_gage_dist_reservoir_km = GageDistanceFromReservoir_km,
                 unit_reservoir_storage_m3 = ReservoirStorage_m3, unit_reservoir_inflow_cms = ReservoirInflow_cms,
                 unit_outflow_cms = Outflow_cms,
                 obs_inhibited = as.integer(Inhibited == "Yes"), obs_fieldblank_pcr_pos,
                 obs_target_rel_abundance = Target_RelativeAbundance)]
long <- order_eco(long)
stopifnot(nrow(long) == 190 * 2 * 4, uniqueN(long$unit) == 190, uniqueN(long$cluster_id) == 9,
          sum(long$y) == sum(unlist(s[, PCR1:PCR4])),
          long[, sum(y), by = taxon][order(taxon)]$V1 == c(sum(unlist(s[TargetSpecies == "Kokanee", PCR1:PCR4])),
                                                           sum(unlist(s[TargetSpecies == "YellowPerch", PCR1:PCR4]))))

periods <- data.table(period = 1:6, label = c("May", "June", "July (first)", "July (second)", "August", "September"),
                      year = 2018L)
stopifnot(long[, .(m = as.integer(substr(date, 6, 7))), by = period][, .(lo = min(m), hi = max(m)), by = period][order(period)][
          , all(lo >= c(5, 6, 7, 7, 8, 9) & hi <= c(5, 6, 7, 7, 8, 9))])
taxa <- make_taxa(c("KOK", "YEPE"), c("Oncorhynchus nerka", "Perca flavescens"),
                  vernacularName = c("kokanee (landlocked sockeye salmon)", "yellow perch"))

dataset <- list(
  title = "Kokanee and yellow perch eDNA in four qPCR replicates of 190 water samples at nine USGS streamgages below reservoirs, Columbia and Colorado River basins, May-September 2018",
  creator = "Sepulveda, Adam J.", pubDate = "2019", doi = "10.5066/P9Q8GCLM",
  sourceURL = "https://doi.org/10.5066/P9Q8GCLM", paperDOI = "10.1002/ecs2.2843",
  citation = "Sepulveda, A.J., 2019, Environmental DNA surveillance data for USGS streamgage sampling in the Columbia River Basin, 2018 (ver. 1.1, July 2019): U.S. Geological Survey data release, https://doi.org/10.5066/P9Q8GCLM.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
                            note = "USGS data release; US public domain, no access or use constraints"),
  abstract = "USGS hydrologic technicians collected eDNA water samples at streamgages downstream of eight Bureau of Reclamation reservoirs in the Columbia River Basin (Idaho, Montana, Oregon, Washington, Wyoming) and at Lees Ferry below Lake Powell, Arizona, six times between May and September 2018, to test whether streamgages can carry early-detection surveillance of what lives in the reservoir upstream. Each event took three 2-L river samples (ten at American Falls and Ririe on two events) and a field blank; each sample was assayed in quadruplicate qPCR for kokanee and for yellow perch, fish known from many of the reservoirs. A replicate is 1 when it reached the assay's limit of detection. Gage coordinates, distance from the reservoir outlet, reservoir storage and flows, inhibition, the field blank's result and fisheries managers' relative-abundance class ship as covariates.",
  samplingProtocol = "Field blank of 2 L deionised water exposed for 10 s, then three (or ten) 2-L grab samples from the river's edge near the streamgage, each filtered on site through one 1.5 um mixed cellulose ester filter, desiccated and shipped to USGS UMESC; DNA extracted (Qiagen Investigator Lyse & Spin with IBI gMAX); kokanee and yellow perch TaqMan qPCR in four 25 ul reactions each, 45 cycles; a replicate at or above the four-replicate LOD (kokanee 1.2, perch 1.9 copies/reaction) is a detection.",
  samplingProtocolCode = "eDNA", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = four qPCR replicates of one extract; periods (sampling events about two to six weeks apart) are open",
  occasionKind = "spatial", taxonInclusion = "target", surveyEvidence = "deposited_matrix",
  temporalCoverage = "2018-05/2018-09",
  geographicCoverage = "Nine USGS streamgages below reservoirs: American Falls, Island Park, Jackson Lake, Palisades and Ririe (upper Snake River, Idaho and Wyoming), Owyhee (Oregon), Hungry Horse (Montana), Lake Roosevelt / Grand Coulee (Washington) and Lees Ferry below Lake Powell (Arizona), USA",
  crs = "EPSG:4326 (datum not stated; streamgage locations as published by USGS)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by USGS (streamgage locations; neither target is a flagged taxon)"),
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = streamgage, period = sampling event at that gage, unit = water sample (nested in one event), occasion = qPCR replicate. A sample is a unit of one period only; the gage's state across events is read through cluster_id x period.",
  notShipped = list(field_blanks = "the 53 field blanks are controls, not river samples; their replicate count for each target is obs_fieldblank_pcr_pos (8 positive replicates, all kokanee, at Owyhee and Lees Ferry)",
                    extraction_blank = "one laboratory extraction blank row (all negative)",
                    relative_abundance_comment = "free-text personal communications from fisheries managers (one includes a telephone number); the Low/Mid/High class ships as obs_target_rel_abundance",
                    dreissenid_assay = "the dreissenid mussel results (a separate file whose samples and dates do not match this one; held)"),
  notes = "Two assays per sample: the taxa are the two targets, not a community survey (taxonInclusion = target). Sample-size test: 10 samples at American Falls (2018-07-30, 2018-09-25) and Ririe (2018-07-30, 2018-09-19).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Kokanee and yellow perch eDNA (0/1 per qPCR replicate, four per sample) in 190 water samples taken on six events (May-September 2018) at nine USGS streamgages below reservoirs in the Columbia and Colorado River basins, with gage, reservoir, inhibition and field-blank covariates.",
  url = "https://doi.org/10.5066/P9Q8GCLM",
  reference = "Sepulveda, A. J., Schmidt, C., Amberg, J., Hutchins, P., Stratton, C., Mebane, C., Laramie, M. B., & Pilliod, D. S. (2019). Adding invasive species biosurveillance to the U.S. Geological Survey streamgage network. Ecosphere, 10(8), e02843.",
  doi_paper = "10.1002/ecs2.2843", doi_data = "10.5066/P9Q8GCLM",
  original_license = "US public domain (USGS data release; no use constraints)", derived_license = "CC0 1.0",
  notes = "Experimental (E9): cluster_id = streamgage, period = sampling event, unit = water sample, occasion = qPCR replicate. The release's dreissenid file cannot be joined to this one and is held.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale occupancy (streamgage > event > sample > qPCR replicate, eDNA)",
  sampling_protocol = "eDNA", design = "Multi-season (six sampling events; 3 or 10 samples x 4 qPCR replicates)", realm = "Freshwater",
  country = "USA", coordinates = "As published",
  notes = "Experimental (E9): multi-scale via cluster_id = streamgage. Field-blank result and inhibition as obs_ covariates.")
