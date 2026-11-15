#!/usr/bin/env Rscript
# Table:  nichols_2025_hawaii_acanthophora_edna
# Source: Dryad doi:10.5061/dryad.cfxpnvxjd, version 405464 (version 4, published 2025-11-03), CC0 1.0 (Dryad metadata,
#         asserted). Nichols P, Sherwood A, Fraiola K, Ely T, Hauk B, Counsell C, Porter M, Marko P. Detection of a
#         non-indigenous marine macroalga (Acanthophora spicifera) with environmental DNA from surface seawater.
# Paper:  primary article doi:10.1002/aff2.70135 (Wiley; not readable here, 403). From the Dryad abstract: a qPCR
#         assay (SYBR, primers on a 131 bp rbcL region) for the non-indigenous red alga A. spicifera, run on surface
#         seawater eDNA at sites in the main Hawaiian Islands (MHI) and Papahanaumokuakea Marine National Monument
#         (PMNM); occupancy modelled from eDNA and opportunistic visual surveys.
# Data:   2Cq_data.csv (543 rows): one row per field qPCR well (Content "Unkn", Project "Field"): Cq (NA = no
#           amplification), starting quantity, SampleID (water sample), Site (91), Date (M/D/YYYY), Region (MHI / PMNM),
#           Island, Lat / Long and Depth_m per site, Visual_presence (1 at 14 sites, NA elsewhere), plate and well.
#           The README: "raw qPCR detection data used for modeling of site occupancy".
#         2qPCR_melt_data.csv: melt curves per well. Wells with a Cq peak at 79-80 C (113) or 87 C (1); wells without
#           a Cq peak at 65.5 C (no product) or show small sub-threshold peaks.
#         2qPCR_metadata.csv lists 399 control wells (field blanks, extraction and PCR negatives) whose results are not
#           in the Cq or melt files. 2qPCR_amplification_data.csv (curves), 2standards.csv (standard curve), and the
#           metabarcoding files (2OTU_table.csv, 2sequence_*.csv/zip) are not used.
#         Design: 91 sites, 2 water samples per site (1 at one site), 3 wells per sample; one collection date per
#           sample (one site sampled on two dates, one sample each), 2020-2023.
# Mapping (E9 experimental multi-scale eDNA; eDNA detection-call ruling 2026-11-06): cluster_id = site, unit = water
#   sample (SampleID), occasion = qPCR well 1-3 in well-ID order, taxon ACASPI. y = 1 where the well has a Cq (the
#   deposit gives no other call, and these are the data the authors modelled), y_raw = Cq. obs_melt_peak_c = the
#   temperature of the well's highest melt-curve value (lets a user require the 79-80 C product). date = collection
#   date; unit_region, unit_island, unit_depth_m, coordinates per site. unit_visual_presence = 1 where an opportunistic
#   visual survey saw the alga, NA otherwise (the deposit does not separate "not seen" from "not surveyed"):
#   detectionCertainty. surveyEvidence = deposited_matrix: every sample has three field wells.
#   Coordinates: an introduced alga, not flagged; reef sites, no private land; as deposited.
# Not shipped: starting quantities (a transform of Cq through the standard curve); control wells (results not
#   deposited); amplification and melt curves (summarised by obs_melt_peak_c); metabarcoding data (another method).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "nichols_2025_hawaii_acanthophora_edna"
dir <- download_dryad("10.5061/dryad.cfxpnvxjd", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), basename(dir) == "dryad_405464")
cq <- fread(file.path(dir, "2Cq_data.csv"), na.strings = "NA")
me <- fread(file.path(dir, "2qPCR_melt_data.csv"), na.strings = "NA")
stopifnot(nrow(cq) == 543L, all(cq$Content == "Unkn"), all(cq$Project == "Field"), !anyDuplicated(cq$ID),
          uniqueN(cq$Site) == 91L, uniqueN(cq$SampleID) == 181L, cq[, .N, by = SampleID][, all(N == 3L)],
          cq[, uniqueN(paste(Date, Site, Lat, Long, Depth_m, Visual_presence, Region, Island)), by = SampleID][, all(V1 == 1L)],
          cq[, uniqueN(paste(Lat, Long, Depth_m, Visual_presence, Region, Island)), by = Site][, all(V1 == 1L)],
          sum(!is.na(cq$Cq)) == 114L, all(cq$Cq > 0, na.rm = TRUE), all(cq$Visual_presence %in% c(1L, NA)),
          all(grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", cq$Date)), all(cq$ID %in% me$ID))
pk <- me[, .SD[which.max(value)], by = ID][, .(ID, peak = Temperature)]
cq <- merge(cq, pk, by = "ID")
stopifnot(nrow(cq) == 543L, cq[!is.na(Cq), all(peak %in% c(79, 79.5, 80, 87))], cq[!is.na(Cq), sum(peak == 87)] == 1L)
setorder(cq, SampleID, ID)
cq[, occasion := seq_len(.N), by = SampleID]
d <- as.IDate(cq$Date, format = "%m/%d/%Y")
stopifnot(!anyNA(d))
long <- cq[, .(unit = SampleID, taxon = "ACASPI", y = as.integer(!is.na(Cq)), y_raw = round(Cq, 3), occasion,
               date = as.character(d), cluster_id = Site, unit_region = Region, unit_island = Island,
               unit_depth_m = Depth_m, unit_visual_presence = Visual_presence,
               unit_decimalLatitude = Lat, unit_decimalLongitude = Long, obs_melt_peak_c = peak)]
setorder(long, cluster_id, unit, occasion)
stopifnot(nrow(long) == 543L, sum(long$y) == 114L, uniqueN(long[y == 1L]$cluster_id) == 28L)

taxa <- make_taxa("ACASPI", "Acanthophora spicifera", vernacularName = "Spiny seaweed")
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
print(taxa)
dataset <- list(
  title = sprintf("qPCR eDNA detections of the non-indigenous red alga Acanthophora spicifera in surface seawater at %d reef sites, main Hawaiian Islands and Papahanaumokuakea, %d-%d",
                  uniqueN(long$cluster_id), min(year(d)), max(year(d))),
  creator = "Nichols, Patrick; Sherwood, Alison; Fraiola, Ka'ua'oa; Ely, Taylor; Hauk, Brian; Counsell, Chelsie; Porter, Megan; Marko, Peter",
  pubDate = "2025", doi = "10.5061/dryad.cfxpnvxjd", sourceURL = "https://doi.org/10.5061/dryad.cfxpnvxjd", paperDOI = "10.1002/aff2.70135",
  citation = "Nichols P, Sherwood A, Fraiola K, Ely T, Hauk B, Counsell C, Porter M, Marko P (2025). Detection of a non-indigenous marine macroalga (Acanthophora spicifera) with environmental DNA from surface seawater. Dryad. https://doi.org/10.5061/dryad.cfxpnvxjd",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Environmental DNA survey for Acanthophora spicifera, a red alga introduced to Hawaiian coral reefs: two surface-seawater samples at each of %d reef sites in the main Hawaiian Islands and the Papahanaumokuakea Marine National Monument, each extract run in three qPCR wells with a species-specific rbcL SYBR assay. One row per well: y = 1 where the well amplified (a Cq), y_raw = Cq, obs_melt_peak_c = the melt-curve peak. The unit is the water sample and cluster_id the site; unit_visual_presence marks sites where an opportunistic visual survey saw the alga.",
                     uniqueN(long$cluster_id)),
  samplingProtocol = "Surface seawater filtered for eDNA, two samples per reef site; each extract amplified in three qPCR wells with species-specific primers on a 131 bp rbcL region (SYBR chemistry, melt-curve analysis); opportunistic visual surveys for the alga at some sites.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = three qPCR wells of one water sample's extract; samples nest in reef sites (cluster_id); one visit per site (one site has two dates, one sample each)",
  occasionKind = "spatial", taxonInclusion = "single",
  detectionCertainty = "Opportunistic visual survey at site level: unit_visual_presence = 1 where the alga was seen; NA where it was not seen or not surveyed (the deposit does not separate the two).",
  geographicCoverage = "Hawaiian Archipelago: Oahu, Kauai, Maui and Hawaii (main islands) and Kuaihelani (Midway), Holaniku (Kure), Manawai (Pearl and Hermes), Kapou (Lisianski) and Lalo (French Frigate Shoals) in Papahanaumokuakea",
  temporalCoverage = sprintf("%d/%d", min(year(d)), max(year(d))),
  coordinatesCoarsened = list(value = FALSE, method = "An introduced alga (not a flagged taxon); reef sites; coordinates as deposited."),
  notes = "y follows the eDNA detection-call ruling: the deposit gives Cq values (the data the authors modelled) and no other call. Every amplified well but one has its melt peak at 79-80 C; one (obs_melt_peak_c = 87) peaks elsewhere, likely a non-target product; users who want the authors' melt-curve screen can require obs_melt_peak_c < 81. Field blanks and other controls were run (399 wells in the metadata) but their results are not deposited, so obs_blank_positive cannot be set. The paper reports detections in Papahanaumokuakea that its controls, sequencing and visual surveys suggest are real.",
  notShipped = list(`starting quantities` = "SQ: a transform of Cq through the standard curve",
                    `control wells` = "399 field-blank and negative-control wells listed in the metadata; results not deposited",
                    `amplification and melt curves` = "summarised by obs_melt_peak_c",
                    metabarcoding = "OTU table and reads: a different method (high-throughput sequencing)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("qPCR eDNA detections (three wells per sample, two surface-seawater samples per site) of the non-indigenous red alga Acanthophora spicifera at %d reef sites in the main Hawaiian Islands and Papahanaumokuakea, %d-%d.",
                        uniqueN(long$cluster_id), min(year(d)), max(year(d))),
  url = "https://doi.org/10.5061/dryad.cfxpnvxjd",
  reference = "Nichols P, Sherwood A, Fraiola K, et al. (2025). Detection of a non-indigenous marine macroalga (Acanthophora spicifera) with environmental DNA from surface seawater. doi:10.1002/aff2.70135",
  doi_paper = "10.1002/aff2.70135", doi_data = "10.5061/dryad.cfxpnvxjd", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version 405464. Cq present = detection (eDNA ruling); melt peak shipped; control results not deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Multi-scale occupancy (eDNA; site > water sample > qPCR replicate)",
  sampling_protocol = "eDNA", design = "Single-season (multi-scale: 2 water samples x 3 qPCR wells per site)",
  realm = "Marine", country = "USA", coordinates = "As published",
  notes = "Invasive red alga on Hawaiian reefs; opportunistic visual confirmation at 14 sites.")
