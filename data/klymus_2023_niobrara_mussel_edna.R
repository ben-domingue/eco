#!/usr/bin/env Rscript
# Table:  klymus_2023_niobrara_mussel_edna  (transect point > water sample > qPCR replicate; four
#         native freshwater mussel species, Niobrara National Scenic River and Agate Fossil Beds
#         National Monument, Nebraska; a documented all-zero eDNA survey)
# Source: USGS ScienceBase item 655b8b1dd34ee4b6e05cbcd5, doi:10.5066/P96QMW8W (published
#         2023-11-21). USGS data release: US public domain; the FGDC metadata gives no access
#         constraints ("None.") and a use constraint that only asks for citation.
#   Klymus, K.E., Thompson, N.L., Tronstad, L. and Tronstad, B., 2023, Development, testing and use
#   of four species-specific qPCR assays for freshwater mussel eDNA detection in the Niobrara River:
#   U.S. Geological Survey data release, https://doi.org/10.5066/P96QMW8W.
# Paper:  none linked. Everything below is from the FGDC metadata
#         (Metadata_NiobraraMussel_eDNA_Assays.xml): water samples every 0.8 km while canoeing 121 km
#         of the Niobrara National Scenic River (Borman Bridge near Valentine to highway 137) and
#         walking / kayaking 17 km at Agate Fossil Beds (highway 29 to the eastern park boundary);
#         one Whirlpak sample filtered on 0.45 um nitrocellulose (about 250 mL, until clogged); a
#         deionised-water blank "each day at the start of filtering and about every 5 samples
#         thereafter"; extraction blanks per batch; each sample run in quadruplicate with each of the
#         four species assays (Afer Nio5 = Anodontoides ferussacianus, Lcar Nio1 = Lampsilis
#         cardium, Lsil Nio5 = Lampsilis siliquoidea, Pgra Nio4 = Pyganodon grandis), multiplexed
#         with a Hem-T internal positive control; LOD (4 replicates) Afer 0.412, Lcar 0.400, Lsil
#         0.386, Pgra 0.615 copies/reaction. "Due to the lack of amplification in the field collected
#         water samples with any of the four designed assays, we decided to validate the Lsil Nio5
#         assay using previously collected ... samples known to contain L. siliquoidea DNA" (the
#         CompareAssay files). The release's time period is 2019-06-26 to 2023-04-30 (field to lab);
#         sampling dates are not deposited.
# Data:   Niobrara_eDNA_eDNASamples.csv, 3376 rows, one per qPCR well (no well id): 171 field
#         samples ("Unknown"; 2736 rows = 171 x 4 assays x 4 replicates), 22 field blanks
#         ("Control", Niob_e001A-e022A, 352 rows), 18 extraction blanks (288 rows, every one labelled
#         Pgra Nio4 whatever plate it is on). TechRep numbers the sample within its plate, not the
#         replicate: the replicates are the four rows of a sample x assay. Start_Quant = copies per
#         reaction, "A value of 0 indicates no target was amplified": 0 in every row. TransectID keys
#         Niobrara_eDNA_SamplingTransects.csv (169 points: Agate-<km> 20, M-<km> 149, Distance in km);
#         M-34.5 has two samples (Niob_e063A, e077A); Niob_e043A has TransectID and Volume_filtered
#         "N/A". Niobrara_eDNA_eDNAQualityAssurance.csv: the plates' standards, NTC and PTC
#         (standards and PTC amplified, NTC and the "Unkn" rows did not). IPC file: Hem-T Cq per well.
#         LOD_LOQ: the standard-curve dilutions behind the LOD. AssaySpecificity: which non-target
#         mussels each assay amplified. CompareAssay_*: South Dakota samples run with L.sil.2 and
#         Lsil Nio5 (assay validation, not this survey).
# Mapping (standard E9 experimental multi-scale / eDNA): cluster_id = transect point (TransectID;
#   Niob_e043A, with no transect point, is its own cluster "unlocated_e043A"), unit = water sample
#   (Sample_ID), occasion = qPCR replicate 1-4 (row order within sample x assay), taxon = the four
#   target species (taxonInclusion = target), y = 0 everywhere: the authors' rule (Start_Quant at
#   or above the assay's LOD) and any-amplification both call nothing, since Start_Quant is 0 in
#   every field reaction; no y_raw (it would be Start_Quant, 0 = y everywhere). No period (one visit per point).
#   surveyEvidence = deposited_matrix: every sample has four replicates of each assay.
#   obs_blank_positive = 0 on every row: no field blank amplified with any assay (asserted; the
#   blanks carry no date or event, so they cannot be matched to days, but none is positive).
#   unit_: unit_area (Niobrara National Scenic River / Agate Fossil Beds), unit_river_km (distance
#   along the sampled reach, km, from the transect file), unit_volume_filtered_l.
#   Coordinates: none in the deposit (points are identified by distance along the river; the
#   metadata bounding box, at 38.91 N 92.28 W, is the laboratory's, not the river's).
# Not shipped: field and extraction blanks as units (their result is obs_blank_positive / notes),
#   plate standards and controls, the IPC Cq per well (wells are not identified in the sample file,
#   so a well's IPC cannot be joined to its replicate), the LOD_LOQ dilutions, AssaySpecificity,
#   CompareAssay_* (validation samples from another survey), plate file names and curve statistics.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "klymus_2023_niobrara_mussel_edna"
SCRIPT <- "data/klymus_2023_niobrara_mussel_edna.R"
ITEM <- "655b8b1dd34ee4b6e05cbcd5"
it_f <- download_cached(sprintf("https://www.sciencebase.gov/catalog/item/%s?format=json", ITEM), TABLE, filename = "item.json")
it <- jsonlite::fromJSON(it_f)
stopifnot(identical(it$id, ITEM), "doi:10.5066/P96QMW8W" %in% it$identifiers$key,
          grepl("^Development, testing and use of four species-specific qPCR assays", it$title))
fl <- setNames(it$files$url, it$files$name)
get <- function(n) download_cached(fl[[n]], TABLE, filename = n)
xml <- readLines(get("Metadata_NiobraraMussel_eDNA_Assays.xml"), warn = FALSE)
xmlv <- function(tag) trimws(sub(sprintf(".*<%s>(.*)</%s>.*", tag, tag), "\\1", grep(sprintf("<%s>", tag), xml, value = TRUE)))
stopifnot(identical(xmlv("accconst"), "None.  Please see 'Distribution Info' for details."),
          startsWith(xmlv("useconst"), "It is requested that the authors and the USGS Columbia Environmental Research Center be cited"),
          identical(xmlv("begdate"), "20190626"), identical(xmlv("enddate"), "20230430"),
          any(grepl("Due to the lack of amplification in the field collected water samples", xml)),
          any(grepl("Afer Nio5:4 rep, LOD = 0.412, LOQ = 6.0; Lcar Nio1: 4 rep, LOD = 0.400, LOQ = 10.0; Lsil Nio5: 4 rep, LOD = 0.386, LOQ = 10.0; Pgra Nio4: 4 rep, LOD = 0.615", xml, fixed = TRUE)),
          any(grepl("A value of 0 indicates no target was amplified in the sample", xml, fixed = TRUE)))
LOD <- c("Afer Nio5" = 0.412, "Lcar Nio1" = 0.400, "Lsil Nio5" = 0.386, "Pgra Nio4" = 0.615)

d <- fread(get("Niobrara_eDNA_eDNASamples.csv"), colClasses = list(character = c("Volume_filtered", "TransectID", "Start_Quant")))
stopifnot(nrow(d) == 3376L, identical(names(d), c("Filename", "Sample_ID", "TransectID", "Samp_type", "Site", "Assay", "Volume_filtered",
          "BioRep", "TechRep", "Start_Quant", "Efficiency", "Slope", "Y_Intercept", "R2")),
          identical(d[, .N, keyby = Samp_type]$N, c(352L, 288L, 2736L)), all(d$Start_Quant == "0"),
          all(d$Assay %in% names(LOD)))
# controls: 22 field blanks, 18 extraction blanks, none amplified
fb <- d[Samp_type == "Control"]; eb <- d[Samp_type == "Extraction blank"]
stopifnot(uniqueN(fb$Sample_ID) == 22L, fb[, .N, by = .(Sample_ID, Assay)][, all(N == 4L) && .N == 88L],
          all(fb$Start_Quant == "0"), uniqueN(eb$Sample_ID) == 18L, all(eb$Assay == "Pgra Nio4"), all(eb$Start_Quant == "0"))
s <- d[Samp_type == "Unknown"]
stopifnot(uniqueN(s$Sample_ID) == 171L, s[, .N, by = .(Sample_ID, Assay)][, all(N == 4L) && .N == 171L * 4L],
          s[, uniqueN(Filename), by = .(Sample_ID, Assay)][, all(V1 == 1L)],
          identical(s[, uniqueN(Sample_ID), keyby = Site]$V1, c(20L, 151L)),
          s[, lapply(.SD, uniqueN), by = Sample_ID, .SDcols = c("TransectID", "Site", "Volume_filtered", "BioRep")][, all(unlist(.SD) == 1L), .SDcols = -1],
          all(s$BioRep == 1L))
# the authors' call (Start_Quant >= LOD) and any amplification agree: nothing
s[, y := as.integer(as.numeric(Start_Quant) >= LOD[Assay])]
stopifnot(all(s$y == 0L), all(as.numeric(s$Start_Quant) == 0))

tr <- fread(get("Niobrara_eDNA_SamplingTransects.csv"))
stopifnot(nrow(tr) == 169L, !anyDuplicated(tr$TransectID), identical(tr[, .N, keyby = Site]$N, c(20L, 149L)),
          tr[Site == "Agate", all(startsWith(TransectID, "Agate-"))], tr[Site != "Agate", all(startsWith(TransectID, "M-"))],
          all(abs(as.numeric(sub("^(Agate|M)-", "", tr$TransectID)) - tr$Distance) < 1e-9))
stopifnot(identical(sort(setdiff(unique(s$TransectID), tr$TransectID)), "N/A"), all(tr$TransectID %in% s$TransectID),
          identical(s[TransectID == "N/A", unique(Sample_ID)], "Niob_e043A"),
          identical(s[TransectID == "M-34.5", sort(unique(Sample_ID))], c("Niob_e063A", "Niob_e077A")),
          identical(s[Volume_filtered == "N/A", unique(Sample_ID)], "Niob_e043A"),
          s[TransectID != "N/A", all((Site == "Agate") == startsWith(TransectID, "Agate-"))])
s <- merge(s, tr[, .(TransectID, Distance)], by = "TransectID", all.x = TRUE)

TX <- c("Afer Nio5" = "ANOFER", "Lcar Nio1" = "LAMCAR", "Lsil Nio5" = "LAMSIL", "Pgra Nio4" = "PYGGRA")
s[, occasion := seq_len(.N), by = .(Sample_ID, Assay)]
long <- s[, .(unit = Sample_ID, taxon = unname(TX[Assay]), y, occasion,
              cluster_id = ifelse(TransectID == "N/A", "unlocated_e043A", TransectID),
              obs_blank_positive = 0L,
              unit_area = ifelse(Site == "Agate", "Agate Fossil Beds National Monument", "Niobrara National Scenic River"),
              unit_river_km = Distance,
              unit_volume_filtered_l = suppressWarnings(as.numeric(Volume_filtered)))]
long <- order_eco(long)
stopifnot(nrow(long) == 2736L, uniqueN(long$unit) == 171L, uniqueN(long$cluster_id) == 170L, uniqueN(long$taxon) == 4L,
          all(long$y == 0L), long[, .N, by = .(unit, taxon)][, all(N == 4L)],
          sum(is.na(long$unit_volume_filtered_l)) == 16L, sum(is.na(long$unit_river_km)) == 16L)

taxa <- make_taxa(c("ANOFER", "LAMCAR", "LAMSIL", "PYGGRA"),
                  c("Anodontoides ferussacianus", "Lampsilis cardium", "Lampsilis siliquoidea", "Pyganodon grandis"),
                  vernacularName = c("cylindrical papershell", "plain pocketbook", "fatmucket", "giant floater"))
iucn <- iucn_category(taxa$taxonID, taxa$scientificName)
message("  IUCN categories: ", paste(taxa$scientificName, iucn, sep = " = ", collapse = "; "))

dataset <- list(
  title = "Four native freshwater mussel eDNA assays, four qPCR replicates each, in 171 water samples along the Niobrara River and at Agate Fossil Beds, Nebraska: no detection",
  creator = "Klymus, Katy E.; Thompson, Nathan L.; Tronstad, Lusha; Tronstad, Bryan", pubDate = "2023", doi = "10.5066/P96QMW8W",
  sourceURL = "https://doi.org/10.5066/P96QMW8W",
  citation = "Klymus, K.E., Thompson, N.L., Tronstad, L. and Tronstad, B., 2023, Development, testing and use of four species-specific qPCR assays for freshwater mussel eDNA detection in the Niobrara River: U.S. Geological Survey data release, https://doi.org/10.5066/P96QMW8W.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/",
                            note = "USGS data release; US public domain, no access constraints; citation requested"),
  abstract = "USGS and University of Wyoming developed species-specific qPCR assays for four native freshwater mussels (cylindrical papershell, plain pocketbook, fatmucket, giant floater) and ran them on water samples taken every 0.8 km along 121 km of the Niobrara National Scenic River and 17 km of the Niobrara at Agate Fossil Beds National Monument, Nebraska. Each of 171 samples at 169 transect points (plus one unlocated) was assayed in four qPCR replicates per species. No field reaction amplified with any assay, and no field or extraction blank did either; the standards and positive controls did. cluster_id = transect point, unit = water sample, occasion = qPCR replicate.",
  samplingProtocol = "Environmental DNA: one water sample (Whirlpak, 30 cm deep, upstream of the vessel) every 0.8 km, filtered on a 0.45 um nitrocellulose filter until clogged (about 0.25 L), deionised-water field blanks each day and about every five samples; DNA extracted (PowerWater bead tubes, MDT lysis, QuickGen Auto12S) and run in four 20 ul qPCR replicates with each species assay multiplexed with a Hem-T internal positive control, 40 cycles; the authors' detection rule is Start_Quant at or above the assay's LOD (Afer Nio5 0.412, Lcar Nio1 0.400, Lsil Nio5 0.386, Pgra Nio4 0.615 copies/reaction).",
  samplingProtocolCode = "eDNA", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = four qPCR replicates of one sample's extract; one sample per transect point (two at M-34.5), one visit",
  occasionKind = "spatial", taxonInclusion = "target", surveyEvidence = "deposited_matrix",
  temporalCoverage = "2019/2023",
  geographicCoverage = "Niobrara River, Nebraska, USA: Niobrara National Scenic River from Borman Bridge near Valentine to highway 137 (121 km), and Agate Fossil Beds National Monument from highway 29 to the eastern park boundary (17 km)",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit: transect points are identified by distance along the river (unit_river_km); the FGDC bounding box (38.91 N, 92.28 W) is the laboratory's location, not the survey's"),
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = transect point, unit = water sample, occasion = qPCR replicate, four target taxa (one assay each).",
  notShipped = list(
    controls = "22 field blanks (Niob_e001A-e022A) and 18 extraction blanks, all four replicates of every assay at Start_Quant 0; plate standards, NTC and PTC (standards and PTC amplified, NTC did not)",
    ipc = "Hem-T internal positive control Cq per well: the sample file has no well id, so a well's IPC cannot be joined to its replicate",
    LOD_LOQ = "standard-curve dilutions behind the authors' LOD and LOQ (the LOD values are cited in samplingProtocol)",
    AssaySpecificity = "which non-target mussel species each assay amplified (assay validation)",
    CompareAssay = "South Dakota samples known to contain L. siliquoidea, run with the L.sil.2 and Lsil Nio5 assays to validate the new assay (another survey, not this one)",
    plate_statistics = "plate file names, efficiency, slope, intercept and R2 of each plate's standard curve"),
  notes = "No detection in any survey; detection probability is not estimable from this table alone. Start_Quant is 0 in all 2,736 field reactions (no y_raw: it would equal y), so the authors' LOD rule and an any-amplification rule both give y = 0; the release says so ('Due to the lack of amplification in the field collected water samples with any of the four designed assays'). Sampling dates are not deposited; temporalCoverage is the release's time period (2019-06-26 to 2023-04-30, field collection to laboratory). Niob_e043A has no transect point or filtered volume in the deposit (cluster_id unlocated_e043A, unit_river_km and unit_volume_filtered_l NA); transect point M-34.5 has two samples. unit_river_km is the distance along the sampled reach as the transect file gives it (M- points on the Niobrara National Scenic River, Agate- points at Agate Fossil Beds).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Four native freshwater mussel eDNA assays (Anodontoides ferussacianus, Lampsilis cardium, Lampsilis siliquoidea, Pyganodon grandis) in four qPCR replicates of 171 water samples every 0.8 km along the Niobrara River, Nebraska; no reaction amplified (a documented all-zero survey).",
  url = "https://doi.org/10.5066/P96QMW8W",
  reference = "Klymus, K.E., Thompson, N.L., Tronstad, L. and Tronstad, B., 2023, Development, testing and use of four species-specific qPCR assays for freshwater mussel eDNA detection in the Niobrara River: U.S. Geological Survey data release, https://doi.org/10.5066/P96QMW8W.",
  doi_paper = "", doi_data = "10.5066/P96QMW8W",
  original_license = "US public domain (USGS data release; no use constraints beyond a citation request)", derived_license = "CC0 1.0",
  notes = "All-zero table (ruling 2026-11-06): no detection with any of the four assays; p is not estimable from this table alone. Experimental (E9): cluster_id = transect point, unit = water sample, occasion = qPCR replicate.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (transect point > sample > qPCR replicate, eDNA)",
  sampling_protocol = "eDNA", design = "Single-season (one sample per point every 0.8 km, 4 qPCR replicates x 4 assays)", realm = "Freshwater",
  country = "USA", coordinates = "None in source",
  notes = "All-zero: no detection in any of 2,736 field reactions. Experimental (E9) multi-scale via cluster_id = transect point.")
