#!/usr/bin/env Rscript
# Tables: neon_2026_macroinverts_dna_occ (benthic macroinvertebrate metabarcoding, DP1.20126.001) and
#         neon_2026_zooplankton_dna_occ (lake zooplankton metabarcoding, DP1.20221.001), plus an
#         `_exact` sibling of either if a taxon IUCN CR/EN/VU in its native range is in it (E7 scope, 3).
#         One script for both: the two products share the user guide, the laboratories, the table layout
#         and the processing.
# Source: NEON (National Ecological Observatory Network). Macroinvertebrate metabarcoding (DP1.20126.001),
#         RELEASE-2026, https://doi.org/10.48443/6n5z-z564, and Zooplankton metabarcoding (DP1.20221.001),
#         RELEASE-2026, https://doi.org/10.48443/bgvz-a687. Datasets accessed from
#         https://data.neonscience.org/data-products/DP1.20126.001/RELEASE-2026 and .../DP1.20221.001/RELEASE-2026
#         on 2026-11-12 through the NEON Data API (token-gated; NEON_TOKEN environment variable, see
#         lib/eco_common.R). Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data
#         products and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"). NEON is funded by the U.S. National Science Foundation and operated by Battelle.
# Paper:  no single paper; the user guide NEON_INV_ZOO_DNA_userGuide_vG (2026-03-13), the quick-start guide
#         NEON.QSG.DP1.20126.001v2, the field protocols NEON.DOC.003046 (macroinvertebrates) and NEON.DOC.001194
#         (zooplankton), and the laboratory SOPs (Laragen_invert_bioinformatics_V1.0: Qiime2, DADA2 denoising,
#         BLAST consensus against a BOLD COI reference at 97% identity, features in only one sample removed).
#         From the user guide: three samples per site on one day in each of three bouts a year; only the bout 2
#         (midsummer) samples are sequenced, bouts 1 and 3 are archived; two COI primer sets (BE and F230) per
#         sample; "The bioinformatics table (inv_metabarcodeTaxonomy) will have multiple records per dnaSampleID
#         corresponding to each taxon sequence detected in the analysis."
# Data:   basic package, every site-month of the release (macroinvertebrates 34 sites / 692 site-months,
#         zooplankton 7 lakes / 106 site-months, 2017-2022):
#         *_fieldData: one row per field sample (the macroinvertebrate table lists the morphological samples
#           too; a DNA sample has geneticSampleID = the morphological sampleID + ".DNA"), eventID = the bout,
#           samplerType, habitatType and benthicArea (macroinvertebrates), towsTrapsNumber and towsTrapsVolume
#           (zooplankton), samplingImpractical, coordinates of the named location as published.
#         *_dnaExtraction: one DNA extract per genetic sample (asserted), laboratory (Jonah Ventures to 2021,
#           Laragen 2022), qaqcStatus.
#         *_pcrAmplification, *_markerGeneSequencing: one record per extract x primer set (x replicate); the
#           sequencing record carries sequencerRunID, qaqcStatus, sampleTotalReadNumber (reads) and
#           sampleFilteredReadNumber (reads after quality filtering). The 2022 Laragen samples were sequenced on
#           two runs (230327 and 230413), each listed under replicates 1 and 2 with identical read numbers.
#         *_metabarcodeTaxonomy: one row per extract x primer set (targetSubfragment BE / F230) x exact
#           sequence variant (sequenceName) the laboratory reported, with individualCount = reads, the
#           sequencerRunID, the consensus name the laboratory assigned (scientificName; empty for unassigned
#           variants) and its classification, percentSequenceMatch, and dataQF ('low extraction efficiency' on
#           every 2022 Laragen row). The replicate column is empty: reads are reported per extract x primer set.
# Mapping (standard E9 core: occupancy, multi-species; responseType detection; metabarcoding ruling of
#   2026-11-13, standard E9):
#   unit = NEON site; period = bout (eventID; one sequenced bout per site-year), a global integer index ordered
#   by date (__periods: eventID, site, year, boutNumber, date); occasion = field sample x primer set within the
#   bout (sample outer, BE before F230: occasionKind ["spatial", "method"], closure closed; the samples are
#   taken on one day); obs_genetic_sample_id and obs_marker carry the two components.
#   y = 1 if the taxon has reads in the sample for that primer set in the laboratory's reported sequence
#   variants (NEON's reporting threshold: a variant appears in *_metabarcodeTaxonomy only if it passed the
#   laboratory's denoising and filtering; the smallest reported read count is asserted below), else 0;
#   y_raw = the reads of the taxon's variants summed (0 where none). The read count is never abundance.
#   obs_reads_total (sampleTotalReadNumber) and obs_reads_filtered (sampleFilteredReadNumber) = sequencing depth
#   of the sample x primer set on the run its taxonomy rows come from; obs_n_variants = the taxon's reported
#   variants; obs_max_pct_match = the highest percentSequenceMatch among them (NA where y = 0 or not
#   reported); obs_lab; obs_low_extraction_efficiency (1 where NEON's dataQF says so, else 0); obs_sampler_type
#   (and, for macroinvertebrates, obs_habitat_type, obs_benthic_area_m2; for zooplankton, obs_tows,
#   obs_volume_l); date = collectDate.
#   PCR replicates: the taxonomy table reports one set of reads per extract x primer set (replicate empty),
#   so replicates are not separable and are not occasions; the 2022 duplicate replicate records (identical
#   reads) are one sequencing record (asserted).
#   Survey evidence = sample_table: a survey is an extract x primer set with rows in *_metabarcodeTaxonomy
#   (the laboratory's bioinformatics output for it) from a field sample with samplingImpractical blank. A 0
#   arises where such a survey reported no variant assigned to a taxon of the site's pool.
#   Taxa surveyed for: per-site pool (ruling 19, the metabarcoding ruling): every name the laboratory assigned
#   at the site in any sample by either primer set (__survey_taxa); derived from detections.
#   Taxa: each distinct name the laboratory assigned (scientificName; where it is empty but a classification is
#   given, the finest rank given) is one taxon, at the rank it names: species, a higher rank, "X sp." as the
#   genus (ruling 20), and interim names (BOLD BINs and voucher labels such as "Chironomidae sp.
#   BOLD:ABV1452", "cf.", "aff.", "complex") as unnamed species-rank taxa with no taxonID. Assignments are the
#   laboratory's, at whatever sequence identity it reported; obs_max_pct_match lets a user apply a stricter
#   threshold. Unassigned variants carry no taxon: their reads count in the depth, not in any row.
#   Not shipped: unassigned variants (counted); field samples not sequenced (bouts 1 and 3, archived); the 2017
#   pilot samples sequenced with four PCR replicates but with no taxonomy rows; a sample x primer set whose
#   sequencing failed (no taxonomy rows); the sequences themselves (taxonSequence, in the source); the
#   standard (mock community) samples; raw data files.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
RELEASE <- "RELEASE-2026"
SCRIPT <- "data/neon_2026_dna_occ.R"
SPECS <- list(
  list(table = "neon_2026_macroinverts_dna_occ", product = "DP1.20126.001", pre = "inv", doi = "https://doi.org/10.48443/6n5z-z564",
       name = "Macroinvertebrate metabarcoding", n_sm = 692L, n_sites = 34L, group = "benthic macroinvertebrate"),
  list(table = "neon_2026_zooplankton_dna_occ", product = "DP1.20221.001", pre = "zoo", doi = "https://doi.org/10.48443/bgvz-a687",
       name = "Zooplankton metabarcoding", n_sm = 106L, n_sites = 7L, group = "lake zooplankton"))

build <- function(S) {
  cat(sprintf("== %s\n", S$table))
  tb <- paste0(S$pre, c("_fieldData", "_dnaExtraction", "_pcrAmplification", "_markerGeneSequencing", "_metabarcodeTaxonomy"))
  nx <- download_neon(S$product, S$table, RELEASE, tables = tb)
  stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == S$n_sm, identical(attr(nx, "productDoi"), S$doi),
            identical(attr(nx, "productName"), S$name))
  fd <- nx[[tb[1]]]; ex <- nx[[tb[2]]]; mg <- nx[[tb[4]]]; tx <- nx[[tb[5]]]
  cat(sprintf("  fieldData %d, extraction %d, sequencing %d, taxonomy %d rows\n", nrow(fd), nrow(ex), nrow(mg), nrow(tx)))

  # --- the source as deposited ------------------------------------------------------------------
  gs <- fd[!is.na(geneticSampleID)]
  stopifnot(!anyDuplicated(gs$geneticSampleID), all(ex$geneticSampleID %in% gs$geneticSampleID),
            !anyDuplicated(ex$geneticSampleID), !anyDuplicated(ex$dnaSampleID),           # one extract per genetic sample
            all(tx$dnaSampleID %in% ex$dnaSampleID), all(mg$dnaSampleID %in% ex$dnaSampleID),
            all(tx$targetSubfragment %in% c("BE", "F230")), is.na(tx$replicate),          # reads per extract x primer set
            !anyNA(tx$individualCount), !anyNA(tx$sequenceName), !anyNA(tx$sequencerRunID),
            all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", gs$collectDate)))
  tx[, reads := as.integer(individualCount)]
  stopifnot(all(tx$reads >= 1L), !anyDuplicated(tx[, .(dnaSampleID, targetSubfragment, sequenceName)]),
            tx[, uniqueN(sequencerRunID), by = .(dnaSampleID, targetSubfragment)][, all(V1 == 1L)])
  min_reads <- tx[, .(m = min(reads)), by = laboratoryName]
  cat(sprintf("  smallest reported read count: %s\n", paste(min_reads$laboratoryName, min_reads$m, collapse = ", ")))
  mg[, marker := sub("^CO[1I]_?", "", primerSetID)]
  stopifnot(all(mg$marker %in% c("BE", "F230")))

  # --- surveys: extract x primer set with taxonomy rows -------------------------------------------
  sv <- unique(tx[, .(dnaSampleID, marker = targetSubfragment, run = sequencerRunID, lab = laboratoryName,
                      low_ext = as.integer(any(dataQF %in% "low extraction efficiency"))), by = .(dnaSampleID, targetSubfragment)][, -(1:2)])
  stopifnot(!anyDuplicated(sv[, .(dnaSampleID, marker)]))
  dep <- unique(mg[, .(dnaSampleID, marker, run = sequencerRunID, qaqc = qaqcStatus,
                       reads_total = as.numeric(sampleTotalReadNumber), reads_filtered = as.numeric(sampleFilteredReadNumber))])
  dep <- dep[sv[, .(dnaSampleID, marker, run)], on = .(dnaSampleID, marker, run), nomatch = NULL]
  stopifnot(!anyDuplicated(dep[, .(dnaSampleID, marker, run)]))                    # a survey's replicate records (2022) are identical
  sv <- merge(sv, dep, by = c("dnaSampleID", "marker", "run"), all.x = TRUE)
  stopifnot(!anyNA(sv$reads_total), !anyNA(sv$reads_filtered), all(sv$qaqc %in% c("Pass", "Fail")))
  n_seq_fail <- sv[qaqc == "Fail", .N]                     # taxonomy reported for a sequencing record NEON marks Fail (fewer than 3,000 reads)
  stopifnot(n_seq_fail <= 2L)
  sv <- sv[qaqc == "Pass"]
  seq_only <- fsetdiff(unique(mg[, .(dnaSampleID, marker)]), sv[, .(dnaSampleID, marker)])
  seq_only <- merge(seq_only, ex[, .(dnaSampleID, year = substr(collectDate, 1, 4))], by = "dnaSampleID")
  n_pilot <- seq_only[year == "2017", .N]; n_failed <- seq_only[year != "2017", .N]
  stopifnot(n_failed <= 2L)
  sv <- merge(sv, ex[, .(dnaSampleID, geneticSampleID, ext_qaqc = qaqcStatus)], by = "dnaSampleID")
  sv <- merge(sv, gs, by = "geneticSampleID")
  stopifnot(all(is.na(sv$samplingImpractical)), sv[, uniqueN(substr(collectDate, 1, 10)), by = eventID][, all(V1 == 1L)],
            sv[, uniqueN(siteID), by = eventID][, all(V1 == 1L)])
  n_ext_fail <- sv[ext_qaqc != "Pass", uniqueN(dnaSampleID)]
  cat(sprintf("  %d surveys (extract x primer set) from %d samples in %d bouts at %d sites; not surveys: %d 2017 pilot extract x primer sets with no taxonomy rows, %d failed sequencing; %d extracts NEON marks extraction qaqc Fail kept (taxonomy rows reported)\n",
              nrow(sv), uniqueN(sv$dnaSampleID), uniqueN(sv$eventID), uniqueN(sv$siteID), n_pilot, n_failed, n_ext_fail))
  n_unsequenced <- gs[is.na(samplingImpractical) & !geneticSampleID %in% sv$geneticSampleID, .N]

  # --- taxa: the laboratory's names ---------------------------------------------------------------
  tx <- tx[paste(dnaSampleID, targetSubfragment) %in% sv[, paste(dnaSampleID, marker)]]
  rk <- c("phylum", "class", "order", "family", "tribe", "genus")
  finest <- function(d) { out <- rep(NA_character_, nrow(d)); for (r in rk) out <- fifelse(!is.na(d[[r]]), d[[r]], out); out }
  tx[, name := trimws(scientificName)]
  n_from_class <- tx[is.na(name) & !is.na(finest(tx)), .N]
  tx[is.na(name), name := finest(.SD)]
  n_unassigned <- tx[is.na(name), .N]; reads_unassigned <- tx[is.na(name), sum(as.numeric(reads))]
  tx <- tx[!is.na(name)]
  tx[, name := sub("^(\\S+) spp?\\.$", "\\1", name)]                                 # "X sp." is X (ruling 20)
  tx[, interim := grepl(" sp\\.| cf\\.| aff\\.|BOLD|complex| s\\. ?l\\.|[0-9_]|/", name) | lengths(strsplit(name, " ")) > 2]
  tx[, rank := fcase(grepl(" gr\\.$", name), "species group", name == "Eukaryota", "domain", interim, "species",
                     !is.na(specificEpithet) & name == paste(genus, specificEpithet), "species",
                     grepl("^[A-Z][a-z-]+ [a-z-]+$", name), "species",
                     name %in% genus, "genus", name %in% tribe, "tribe", name %in% family, "family", name %in% order, "order",
                     name %in% class, "class", name %in% phylum, "phylum", default = NA_character_)]
  nm <- tx[, .(rank = rank[!is.na(rank)][1], interim = interim[1], phylum = phylum[!is.na(phylum)][1], class = class[!is.na(class)][1],
               order = order[!is.na(order)][1], family = family[!is.na(family)][1], n_det = .N), by = name]
  nm[is.na(rank), rank := tolower(vapply(name, function(n) gbif_taxon(n)$rank %||% NA_character_, ""))]   # names outside the classification fields
  nm[is.na(rank) | !nzchar(rank) | !rank %in% c(names(TAXON_RANK_ORDER), "species group", "domain"), rank := "unranked"]
  nm[, taxon := paste0(tolower(gsub("[^A-Za-z]", "", substr(name, 1, 4))), "_", substr(vapply(name, function(s) digest_md5(s), ""), 1, 6))]
  stopifnot(!anyDuplicated(nm$taxon), !anyDuplicated(nm$name))
  tx <- merge(tx, nm[, .(name, taxon)], by = "name")
  cat(sprintf("  %d names: %d species, %d interim (BIN / voucher labels), %d higher rank, %d unranked; %d unassigned variants (%s reads) not shipped\n",
              nrow(nm), nm[rank == "species" & !interim, .N], nm[(interim), .N], nm[rank != "species" & rank != "unranked", .N], nm[rank == "unranked", .N],
              n_unassigned, format(reads_unassigned, big.mark = ",")))

  det <- tx[, .(y_raw = sum(as.numeric(reads)), obs_n_variants = .N, obs_max_pct_match = suppressWarnings(max(as.numeric(percentSequenceMatch), na.rm = TRUE))),
            by = .(dnaSampleID, marker = targetSubfragment, taxon)]
  det[!is.finite(obs_max_pct_match), obs_max_pct_match := NA_real_]

  # --- periods, occasions, units ---------------------------------------------------------------------
  ev <- sv[, .(day = substr(collectDate[1], 1, 10), site = siteID[1], bout = as.integer(boutNumber[1])), by = eventID]
  setorder(ev, day, eventID); ev[, period := seq_len(.N)][, year := as.integer(substr(day, 1, 4))]
  sv <- merge(sv, ev[, .(eventID, period)], by = "eventID")
  setorder(sv, period, geneticSampleID, marker); sv[, occasion := seq_len(.N), by = period]
  units <- fd[siteID %in% sv$siteID][order(siteID, -as.numeric(as.Date(substr(collectDate, 1, 10))))][!duplicated(siteID),
            .(unit = siteID, domain = domainID, aquatic_site_type = aquaticSiteType, named_location = namedLocation,
              decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
              coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))]
  base <- sv[, .(unit = siteID, period, occasion, date = collectDate, obs_genetic_sample_id = geneticSampleID, obs_marker = marker,
                 obs_reads_total = reads_total, obs_reads_filtered = reads_filtered, obs_lab = lab, obs_low_extraction_efficiency = low_ext,
                 obs_sampler_type = samplerType, dnaSampleID)]
  if (S$pre == "inv") base[sv, on = .(dnaSampleID), `:=`(obs_habitat_type = i.habitatType, obs_benthic_area_m2 = as.numeric(i.benthicArea))]
  if (S$pre == "zoo") base[sv, on = .(dnaSampleID), `:=`(obs_tows = as.integer(i.towsTrapsNumber), obs_volume_l = as.numeric(i.towsTrapsVolume))]
  stopifnot(!anyNA(base$obs_reads_total), all(base$obs_reads_total > 0))
  pool <- unique(merge(det[, .(dnaSampleID, taxon)], unique(base[, .(dnaSampleID, unit)]), by = "dnaSampleID")[, .(unit, taxon)])
  setorder(pool, unit, taxon); pool_n <- pool[, .N, by = unit]
  long <- merge(base, pool, by = "unit", allow.cartesian = TRUE)
  long <- merge(long, det, by.x = c("dnaSampleID", "obs_marker", "taxon"), by.y = c("dnaSampleID", "marker", "taxon"), all.x = TRUE)
  long[is.na(y_raw), `:=`(y_raw = 0, obs_n_variants = 0L)]
  long[, y := as.integer(y_raw > 0)]
  long[, dnaSampleID := NULL]
  setcolorder(long, c("unit", "taxon", "y", "y_raw", "period", "occasion", "date"))
  stopifnot(nrow(long) == sum(pool_n[base, on = "unit"]$N), sum(long$y) == nrow(det), sum(long$y_raw) == sum(as.numeric(tx$reads)),
            !anyDuplicated(long[, .(unit, taxon, period, occasion)]), all(long$y_raw[long$y == 0] == 0))
  periods <- ev[, .(period, eventID, site, year, bout, date = day)]
  cat(sprintf("  %s rows; %d sites, %d bouts, %d surveys; per-site pools median %d names (range %d-%d); %.1f%% of rows y = 1\n",
              format(nrow(long), big.mark = ","), uniqueN(base$unit), nrow(ev), nrow(base), as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), 100 * mean(long$y)))

  # --- __taxa ---------------------------------------------------------------------------------------------
  nm <- nm[taxon %in% long$taxon][order(name)]
  rem <- fifelse(nm$interim, sprintf("interim name the laboratory assigned (a BOLD BIN, voucher or provisional label: an unnamed species-rank unit in %s); the GBIF backbone holds no such name, so taxonID is empty", sub(" .*$", "", nm$name)), NA_character_)
  nokey <- nm[(interim) | rank %in% c("unranked", "species group", "domain"), taxon]
  rem[nm$rank == "species group"] <- "a species group the laboratory names ('gr.'); the GBIF backbone holds no such taxon, so taxonID is empty"
  rem[nm$rank == "domain"] <- "assigned only to the domain Eukaryota, which the GBIF backbone does not hold, so taxonID is empty"
  rem[nm$rank == "unranked" & !nm$interim] <- "a name the GBIF backbone does not place at a rank (no strict match), so taxonID is empty"
  taxa <- make_taxa(nm$taxon, nm$name, taxonRank = nm$rank, exact = FALSE, no_key = nokey, taxonRemarks = rem,
                    taxon_n_detections = det[, .N, by = taxon][match(nm$taxon, taxon), N])
  taxa[, kingdom := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey || is.na(taxonID[i])) NA_character_ else gbif_kingdom(scientificName[i]), "")]
  # a strict match that is not EXACT, or that GBIF places above the row's rank, is repaired with the laboratory's classification as hints
  taxa[, mr := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey) NA_character_ else gbif_taxon(scientificName[i])$rank %||% NA_character_, "")]
  fix <- taxa[!taxon %in% nokey & !(gbifMatchType == "EXACT" & !is.na(mr) & tolower(mr) == taxonRank), taxon]
  for (tk in fix) {
    h <- nm[taxon == tk]
    r <- gbif_taxon_hinted(h$name, list(phylum = h$phylum, class = h$class, order = h$order, family = h$family))
    if (identical(r$canonicalName, h$name) && identical(r$rank, h$rank)) {
      taxa[taxon == tk, `:=`(taxonID = r$taxonID, gbifMatchType = paste0(r$matchType, " (hinted)"), gbifAcceptedName = r$acceptedName)]
    } else {
      taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = r$matchType,
           taxonRemarks = "no match of this name at its rank on the GBIF backbone (with the laboratory's classification as hints), so taxonID is empty")]
    }
  }
  taxa[, c("kingdom", "mr") := NULL]
  stopifnot(!any(kingdom_taxonID(taxa$taxonID) & taxa$taxonRank != "kingdom"), all(!is.na(taxa$taxonID) | !is.na(taxa$taxonRemarks)))
  cat(sprintf("  GBIF: %d of %d names with a taxonID (%d repaired with hints)\n", taxa[!is.na(taxonID), .N], nrow(taxa), taxa[grepl("hinted", gbifMatchType), .N]))

  # --- E7: IUCN CR/EN/VU in native range ------------------------------------------------------------------
  sp <- taxa[taxonRank == "species" & !is.na(taxonID)]
  sp[, iucn := unname(mapply(iucn_category, taxonID, scientificName))]
  taxa[sp, on = "taxon", taxon_iucnCategory := i.iucn]
  fl <- sp[iucn %in% c("CR", "EN", "VU")]
  fl <- merge(fl, pool[taxon %in% fl$taxon, .(sites = paste(sort(unique(unit)), collapse = " ")), by = taxon], by = "taxon")
  cat("  IUCN CR/EN/VU names assigned:\n"); print(fl[, .(taxon, scientificName, iucn, sites)])
  # E7(b) applies within the native range only. Asserted from the IUCN range of each name against the sites it is
  # assigned at (2026-11-12): in range, Elimia bellacrenata (Alabama endemic) at BLWA (Black Warrior River, Alabama)
  # and Skistodiaptomus carolinensis (south-eastern United States) at BLWA, TOMB (Alabama) and BARC (Florida); far out
  # of range, so laboratory assignments of a related sequence rather than the threatened species there, the African
  # Africallagma quingentum (BARC), the Sri Lankan Ceylonthelphusa cavatrix (CUPE, Puerto Rico), the European
  # Deronectes ferrugineus (SUGG), the Appalachian groundwater Stygobromus indentatus and S. hayi (KING, Kansas), and
  # the Ozark and Appalachian S. ozarkensis and S. morrisoni (CARI, Alaska).
  expect <- if (S$pre == "inv") data.table(scientificName = c("Africallagma quingentum", "Ceylonthelphusa cavatrix", "Deronectes ferrugineus", "Elimia bellacrenata",
                                                              "Skistodiaptomus carolinensis", "Stygobromus indentatus", "Stygobromus ozarkensis", "Stygobromus morrisoni", "Stygobromus hayi"),
                                           sites = c("BARC", "CUPE", "SUGG", "BLWA", "BLWA TOMB", "KING", "CARI", "CARI", "KING"),
                                           native = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
            else data.table(scientificName = "Skistodiaptomus carolinensis", sites = "BARC", native = TRUE)
  stopifnot(nrow(fl) == nrow(expect), all(fl[expect, on = "scientificName", sites == i.sites]))
  fl_out <- fl[scientificName %in% expect[native == FALSE, scientificName]]
  fl <- fl[scientificName %in% expect[native == TRUE, scientificName]]
  list(S = S, long = long, taxa = taxa, units = units, periods = periods, pool = pool, pool_n = pool_n, base = base, ev = ev, nm = nm,
       fl = fl, fl_out = fl_out, n_unassigned = n_unassigned, reads_unassigned = reads_unassigned, n_pilot = n_pilot, n_failed = n_failed,
       n_unsequenced = n_unsequenced, n_ext_fail = n_ext_fail, n_seq_fail = n_seq_fail, min_reads = min_reads, n_from_class = n_from_class, det = det)
}

digest_md5 <- function(s) { f <- tempfile(); writeBin(charToRaw(s), f); on.exit(unlink(f)); unname(tools::md5sum(f)) }

res <- lapply(SPECS, build)
if (nzchar(Sys.getenv("ECO_DNA_DEBUG"))) { saveRDS(res, Sys.getenv("ECO_DNA_DEBUG")); quit(save = "no") }

# --- write the tables ---------------------------------------------------------------------------------------
emit <- function(r, exact) {
  S <- r$S; fl <- r$fl$taxon
  flag <- r$fl[, sprintf("%s (%s, at %s)", scientificName, iucn, sites)]
  TABLE <- if (exact) sub("_dna_occ$", "_dna_exact_occ", S$table) else S$table
  lt <- if (exact) r$long[!taxon %in% fl] else r$long
  tt <- if (exact) r$taxa[!taxon %in% fl] else r$taxa
  st <- if (exact) r$pool[!taxon %in% fl] else r$pool
  ut <- copy(r$units)
  if (length(fl) && !exact) {
    cg <- coarsen_coords(ut$decimalLatitude, ut$decimalLongitude, 0.1)
    ut[, `:=`(decimalLatitude = cg$lat, decimalLongitude = cg$lon, coordinateUncertaintyInMeters = cg$uncertainty_m, elevation_m = round(elevation_m, -2))]
  }
  outside <- if (nrow(r$fl_out)) sprintf(" Not a trigger: %s, assigned at sites far outside the species' native range (a related sequence, not the threatened species; E7(b) applies in the native range only).", paste(r$fl_out[, sprintf("%s (%s, %s)", scientificName, iucn, sites)], collapse = ", ")) else ""
  nt <- nrow(tt); base <- r$base; ev <- r$ev; pn <- st[, .N, by = unit]
  inv <- S$pre == "inv"
  what <- if (inv) "benthic macroinvertebrate samples (Surber, Hess, core, kicknet, snag, sweep and large-woody-debris samplers by habitat) from wadeable streams, rivers and lakes" else "lake zooplankton samples (vertical tow net in water deeper than 4 m, Schindler-Patalas trap elsewhere)"
  dataset <- list(
    title = paste0(sprintf("NEON %s metabarcoding, RELEASE-2026: detection of %s names (COI reads, two primer sets) per field sample at %d NEON %s, %d-%d",
                           if (inv) "aquatic macroinvertebrate" else "lake zooplankton", format(nt, big.mark = ","), uniqueN(base$unit), if (inv) "aquatic sites" else "lakes", min(ev$year), max(ev$year)),
                   if (exact) " (without IUCN-threatened taxa; coordinates as published)" else ""),
    creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = sub("^https://doi.org/", "", S$doi),
    sourceURL = sprintf("https://data.neonscience.org/data-products/%s/%s", S$product, RELEASE),
    citation = sprintf("NEON (National Ecological Observatory Network). %s (%s), %s. %s. Dataset accessed from https://data.neonscience.org/data-products/%s/%s on 2026-11-12", S$name, S$product, RELEASE, S$doi, S$product, RELEASE),
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("NEON's %s metabarcoding: in the midsummer bout each year, three %s are taken on one day beside the morphological samples, homogenised, and their DNA extracted and amplified with two COI primer sets (BE and F230); the laboratory (Jonah Ventures to 2021, Laragen in 2022) sequences the amplicons, denoises them into exact sequence variants, and assigns each variant a name by BLAST consensus against a BOLD COI reference. y = 1 when a name has reads in a sample for a primer set (any variant the laboratory reported, NEON's reporting threshold), else 0; y_raw is the read count, which is not abundance. One occasion per sample x primer set; sequencing depth (obs_reads_total, obs_reads_filtered), the number of variants and the best percent match ride on each row. The names surveyed for at a site are every name assigned there in any sample (median %d of %d; __survey_taxa). %s",
                       S$group, what, as.integer(median(pn$N)), nt,
                       if (!length(fl)) "Coordinates are as NEON publishes them." else if (exact) "Coordinates are as NEON publishes them; the IUCN-threatened names are not in this table." else "Coordinates are coarsened to the 0.1-degree cell because IUCN-threatened names are in the table; the _exact sibling has the other names at NEON's coordinates."),
    samplingProtocol = sprintf("%s; bulk DNA extraction, PCR with the COI primer sets BE and F230, Illumina MiSeq sequencing, DADA2 exact sequence variants, BLAST consensus naming against BOLD (NEON user guide NEON_INV_ZOO_DNA_userGuide_vG and laboratory SOPs)",
                               if (inv) "Three benthic macroinvertebrate DNA samples per site on one day in the midsummer bout (NEON AOS macroinvertebrate protocol NEON.DOC.003046, sampler by habitat)" else "Three zooplankton DNA samples per lake on one day in the midsummer bout, near the buoy and two littoral sensor sets (NEON AOS zooplankton protocol NEON.DOC.001194)"),
    samplingProtocolCode = "eDNA", surveyEvidence = "sample_table",
    surveyEvidenceNote = sprintf("A survey is an extract x primer set with rows in %s_metabarcodeTaxonomy (the laboratory's bioinformatics output for it), from a field sample in %s_fieldData with samplingImpractical blank and a sequencing record NEON marks Pass. A 0 arises where such a survey reported no sequence variant assigned to a name of the site's pool. The pool is derived from detections (ruling 19; metabarcoding ruling of 2026-11-13): every name the laboratory assigned at the site in any sample by either primer set (__survey_taxa), not a list NEON deposited.", S$pre, S$pre),
    responseType = "detection", unitKind = "site",
    closure = "closed", closureNote = "occasion = field sample x primer set within one bout (samples taken on one day at the site; each primer set is a separate amplification and sequencing of the sample's extract); period = the sequenced (midsummer) bout, one a year per site, indexed globally by date",
    occasionKind = c("spatial", "method"),
    taxonInclusion = "recorded",
    geographicCoverage = sprintf("%d NEON %s in the United States (contiguous states, Alaska, Puerto Rico); coordinates of the most recent sample's named location in __units (WGS 84); latitude %.1f to %.1f, longitude %.1f to %.1f",
                                 nrow(ut), if (inv) "aquatic sites (wadeable streams, rivers, lakes)" else "lakes", min(ut$decimalLatitude), max(ut$decimalLatitude), min(ut$decimalLongitude), max(ut$decimalLongitude)),
    temporalCoverage = sprintf("%s/%s", substr(min(ev$day), 1, 7), substr(max(ev$day), 1, 7)),
    crs = "EPSG:4326 (WGS 84), as published",
    coordinatesCoarsened = if (!length(fl)) list(value = FALSE, method = "As published by NEON (named-location coordinates with coordinateUncertaintyInMeters in __units): no species-rank name in the table is IUCN CR, EN or VU (GBIF IUCN records, asserted), and NEON obfuscates federally listed taxa upstream.")
      else if (exact) list(value = FALSE, method = sprintf("As published by NEON (named-location coordinates with coordinateUncertaintyInMeters in __units). The names IUCN-threatened in their native range (%s) are not in this table (E7 scope, 3); %s has them, with coordinates coarsened.%s", paste(flag, collapse = ", "), S$table, outside))
      else list(value = TRUE, rule = "taxon", method = sprintf("coarsen_coords(): NEON's published coordinates in __units snapped to their 0.1-degree cell centre, uncertainty the cell half-diagonal, elevation rounded to 100 m, because names IUCN CR/EN/VU in their native range are in the table (%s; E7, ruling on the publisher 2026-11-06). NEON site codes are kept. %s keeps the other names at published precision.%s", paste(flag, collapse = ", "), sub("_dna_occ$", "_dna_exact_occ", S$table), outside)),
    covariateNote = paste0("obs_genetic_sample_id = NEON geneticSampleID (the morphological sampleID + '.DNA': join to the morphological product of the same sample); obs_marker = COI primer set (BE or F230); obs_reads_total and obs_reads_filtered = the sample x primer set's reads (sampleTotalReadNumber) and reads after quality filtering (sampleFilteredReadNumber) on the sequencing run its taxonomy comes from: the sequencing depth; obs_n_variants = the name's reported sequence variants in the survey (0 where y = 0); obs_max_pct_match = the highest percentSequenceMatch among them (NA where y = 0 or not reported), to apply a stricter identity threshold than the laboratory's; obs_lab = laboratory; obs_low_extraction_efficiency = 1 where NEON's dataQF reads 'low extraction efficiency' (every 2022 Laragen sample: an extraction that favoured bacterial DNA), else 0; obs_sampler_type",
                           if (inv) ", obs_habitat_type, obs_benthic_area_m2 = the sampler and habitat of the field sample and the benthic area it covered." else ", obs_tows (tows or traps composited), obs_volume_l (litres sampled) of the field sample."),
    notes = sprintf("Metabarcoding ruling (Ben, 2026-11-13; standard E9): detection, reads in y_raw, depth as obs_ columns; the read count is not abundance. NEON's reporting threshold is the laboratory's: a variant is reported only after denoising and filtering (smallest reported read count %s). Names are the laboratory's assignments at whatever identity it reported (obs_max_pct_match ships it): %d species names, %d interim names (BOLD BINs and voucher labels, species-rank, no taxonID), %d at a higher rank. PCR replicates are not separable in the taxonomy table (reads are reported per extract x primer set), so they are not occasions; the 2022 sequencing records listed under replicates 1 and 2 are identical. Per-site pools (ruling 19): median %d names (range %d-%d). %d extract(s) NEON marks extraction qaqc Fail are kept, since the laboratory reported taxonomy for them. The morphological counts of the companion samples are %s.%s",
                    paste(r$min_reads$laboratoryName, r$min_reads$m, collapse = ", "), tt[taxonRank == "species" & is.na(taxonRemarks), .N], tt[grepl("^interim", taxonRemarks), .N], tt[taxonRank != "species", .N],
                    as.integer(median(pn$N)), min(pn$N), max(pn$N), r$n_ext_fail, if (inv) "neon_2026_macroinverts_count (wadeable streams)" else "neon_2026_zooplankton_count",
                    if (uniqueN(base$unit) < 30) sprintf(" %d sites: below the sample floor of 30 units.", uniqueN(base$unit)) else ""),
    notShipped = c(if (exact) list(threatened = sprintf("%s (E7 scope, 3)", paste(flag, collapse = ", "))), list(
      `unassigned sequence variants` = sprintf("%s variant rows (%s reads) the laboratory did not name; their reads are in the depth columns, not in any row", format(r$n_unassigned, big.mark = ","), format(r$reads_unassigned, big.mark = ",")),
      `samples not sequenced` = sprintf("%d field DNA samples with no extract in the release (bouts 1 and 3 are archived at the NEON Biorepository, not sequenced)", r$n_unsequenced),
      `surveys not used` = sprintf("%d extract x primer sets of the 2017 pilot sequenced (four PCR replicates) with no taxonomy rows; %d with no taxonomy rows after failed sequencing; %d whose taxonomy comes from a sequencing record NEON marks Fail (fewer than 3,000 reads)", r$n_pilot, r$n_failed, r$n_seq_fail),
      `sequences and raw data` = "taxonSequence (the variant's sequence), sequenceName, raw sequence files (expanded package links), the standard (mock community) samples, inv_metabarcodeTaxonList and inv_metabarcodeSummary",
      `zeros outside the site pool` = "a name never assigned at a site has no rows there (per-site pool)")))
  ds <- write_table(lt, TABLE, dataset, taxa = tt, periods = r$periods, units = ut, survey_taxa = st, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Detection (COI metabarcoding reads at or above NEON's reporting threshold) of %s names per field sample x primer set at %d NEON %s, %d-%d (one sequenced bout a year, three samples, two primer sets), with the read count in y_raw, sequencing depth and percent match as covariates, coordinates %s.",
                          format(nt, big.mark = ","), uniqueN(base$unit), if (inv) "aquatic sites (benthic macroinvertebrate samples)" else "lakes (zooplankton samples)", min(ev$year), max(ev$year),
                          if (!length(fl) || exact) "as published" else "coarsened to 0.1 degree"),
    url = sprintf("https://data.neonscience.org/data-products/%s/%s", S$product, RELEASE),
    reference = sprintf("NEON (National Ecological Observatory Network). %s (%s), %s. %s", S$name, S$product, RELEASE, S$doi),
    doi_paper = "", doi_data = sub("^https://doi.org/", "", S$doi), original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "Token-gated NEON API (NEON_TOKEN); release pinned. Metabarcoding ruling 2026-11-13: y = reads present, reads in y_raw, depth obs_; per-site name pool from detections.",
    source_via = "NEON Data API, basic package")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Occupancy (multi-species, multi-season; eDNA metabarcoding)",
    sampling_protocol = "eDNA", design = sprintf("Multi-season (%d bouts x 3 samples x 2 primer sets)", nrow(ev)), realm = "Freshwater", country = "USA",
    coordinates = if (!length(fl) || exact) "As published" else "Coarsened (0.1 deg)",
    notes = "NEON national scheme; COI metabarcoding of bulk samples; y = reads present, read count in y_raw (not abundance); per-site name pools (__survey_taxa).", status = "tagged")
  invisible(ds)
}
for (r in res) {
  emit(r, exact = FALSE)
  if (nrow(r$fl)) emit(r, exact = TRUE)
}
