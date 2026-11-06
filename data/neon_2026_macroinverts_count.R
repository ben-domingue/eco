#!/usr/bin/env Rscript
# Table:  neon_2026_macroinverts_count
# Source: NEON (National Ecological Observatory Network). Macroinvertebrate collection
#         (DP1.20120.001), RELEASE-2026. Dataset accessed from
#         https://data.neonscience.org/data-products/DP1.20120.001/RELEASE-2026 on 2026-11-06 through
#         the NEON Data API (token-gated; NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data products
#         and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.003046 (AOS Protocol and Procedure: Aquatic
#         Macroinvertebrate Sampling) and the product user guide, linked from the product page. The
#         product's design description: "Benthic macroinvertebrate samples are collected three times
#         per year at wadeable stream, river, and lake sites ... roughly in spring, summer, and fall ...
#         In wadeable streams, samples are collected in the two most dominant habitat types (e.g.
#         riffles, runs, pools, step pools)", with the sampler suited to the habitat (Surber, Hess,
#         core, modified kicknet, snag).
# Data:   basic package, all 34 aquatic sites and 895 site-months of the release (2014-2024):
#         inv_fieldData: one row per sample (sampleID SITE.DATE.SAMPLER.n, eventID SITE.DATE = the bout,
#           boutNumber 1-3, aquaticSiteType stream / lake / river, habitatType, samplerType,
#           benthicArea m2, substratumSizeClass, samplingImpractical, sampleCondition, reach-centre
#           coordinates as published).
#         inv_persample: one row per sample sorted by the taxonomy laboratory (subsamplePercent = the
#           share of the sample sorted, per cent).
#         inv_taxonomyProcessed: the laboratory's counts per sample x taxon x size class
#           (individualCount = animals counted, subsamplePercent of the fraction they were counted in,
#           estimatedTotalCount = the laboratory's whole-sample estimate, invertebrateLifeStage,
#           acceptedTaxonID, taxonRank, higher classification, sampleCondition).
#         Quirks, each asserted below: the per-row subsamplePercent differs between taxa of one sample in
#           about 4% of samples (large or rare taxa picked from the whole sample) and differs from
#           inv_persample's in about a fifth of samples; a few eventIDs also hold the samples of a second
#           reach coded with another site prefix (STCU, STKG, STMA, STWA), and three '.DNA' samples;
#           some samples carry rows marked targetTaxaPresent N that still name a taxon with no count,
#           and some Y rows have no count (fragments, headless animals).
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture; responseType count):
#   Wadeable streams only (24 sites); the lake and river surveys (petite ponar near the buoy, sweeps in
#   the littoral) are other protocols with their own survey sets and are not in this table.
#   unit = NEON stream site (one reach per site); period = bout (eventID), a global integer
#   index ordered by date (__periods: eventID, site, year, boutNumber, date); occasion = sample within
#   the bout, ordered by sampleID (spatial replicates on one day, one bout over three days; occasionKind
#   spatial, closure closed);
#   y = animals of the taxon counted by the laboratory in the sample, summed over size classes and life
#   stages (the identified fraction, not the whole-sample estimate); date = collectDate as published.
#   obs_habitat_type, obs_sampler_type, obs_benthic_area_m2 (effortColumn), obs_substratum per sample;
#   obs_subsample_fraction (subsampleColumn, E10 ruling 21): for a taxon counted in the sample, its
#   counted animals over NEON's estimatedTotalCount of it (the fraction it was counted in, 1 for a
#   large or rare taxon picked from the whole sample); for a taxon not found, inv_persample's
#   subsamplePercent / 100 (the share of the sample sorted).
#   Survey evidence = sample_table: inv_fieldData lists every sample (with samplingImpractical where a
#   sample was not taken); a survey is a stream sample with samplingImpractical blank or OK, a sampleID,
#   a persample row and laboratory rows. Taxa surveyed for (ruling 19, applied here 2026-11-06, batch 47):
#   the per-site pool, every taxon this table records at the site at any sample, carried by
#   __survey_taxa (unit, taxon); a taxon never recorded at a site has no rows there. The pool is derived
#   from detections (surveyEvidenceNote says so). Batch 38 used the national pool (every taxon at every
#   sample, 4.8 million rows in year parts); the per-site pool needs no parts.
#   Taxa: NEON acceptedTaxonID; subspecies rolled up to the species; records identified to genus,
#   family, ..., phylum, subgenus or a species group are their own taxa at that rank (E6); NEON 'sp.'
#   and 'spp.' codes of one name merged (ruling 20). Life stages (E8 ruling of 2026-11-06, counts split
#   by stage within a visit): y is the total over stages, and the count in each stage NEON records ships
#   as obs_n_stage_larva, _pupa, _adult, _immature, _none (NEON's stage for taxa without one), _unknown,
#   0 where none; a laboratory row with no stage is counted in y and in obs_n_stage_missing.
#   Not shipped: lake and river samples; samples of the second reach filed under another site's
#   eventID and the '.DNA' samples; one MAYF bout whose snag samples were taken 36 days after its
#   cores; samples with a targetTaxaPresent N row, with a counted taxon
#   missing its count, or with a row NEON marks 'damaged, affecting analysis'; the whole-sample
#   estimate estimatedTotalCount (an estimate: y and the fraction are shipped); size classes; the
#   identification history; zeros for taxa never recorded at a site (per-site pool).
# Coordinates (E7; batch 46, #10): Valvata mergella (EN; GBIF IUCN record, asserted) is recorded at Alaskan sites,
#   within its native range. Under the ruling on the publisher (2026-11-06, which withdrew the agency exception) two
#   tables ship (E7 scope, 3): this one, every taxon, with the site coordinates in __units snapped to their 0.1-degree
#   cell centre and elevation rounded to 100 m; and neon_2026_macroinverts_exact_count, at NEON's coordinates, without
#   V. mergella (records identified only to a higher rank stay in both tables).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_macroinverts_count"
PRODUCT <- "DP1.20120.001"; RELEASE <- "RELEASE-2026"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("inv_fieldData", "inv_persample", "inv_taxonomyProcessed"))
DOI <- attr(nx, "productDoi")
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 895L, grepl("^https://doi.org/10.48443/", DOI))
fd <- nx$inv_fieldData; ps <- nx$inv_persample; tx <- nx$inv_taxonomyProcessed
cat(sprintf("  inv_fieldData %d, inv_persample %d, inv_taxonomyProcessed %d rows; product DOI %s\n", nrow(fd), nrow(ps), nrow(tx), DOI))

# --- the source as deposited --------------------------------------------------------------------
IMPR <- c("OK", "logistical", "location dry", "other", "high water velocity", "location snow covered", "location frozen", "extreme weather", "management")
# six rows carry no aquaticSiteType: a SYCA grab sample and five TOOK macroalgae samples, none a benthic sampler
# of the stream protocol; they are left out with the lake and river samples
stopifnot(sum(is.na(fd$aquaticSiteType)) == 6L, all(grepl("\\.(GRAB|MACROALGAE\\d)\\.", fd[is.na(aquaticSiteType), sampleID])))
n_notype <- fd[is.na(aquaticSiteType), .N]
fd <- fd[!is.na(aquaticSiteType)]
stopifnot(uniqueN(fd$siteID) == 34L, all(fd$aquaticSiteType %in% c("stream", "lake", "river")),
          all(is.na(fd$samplingImpractical) | fd$samplingImpractical %in% IMPR),
          # one river sample (FLNT, 2023) has two persample rows; no stream sample has
          !anyDuplicated(na.omit(fd$sampleID)), sum(duplicated(ps$sampleID)) == 1L, substr(ps$sampleID[duplicated(ps$sampleID)], 1, 4) == "FLNT", all(tx$targetTaxaPresent %in% c("Y", "N")),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", fd$collectDate)),
          !anyNA(ps$subsamplePercent))
streams <- sort(unique(fd[aquaticSiteType == "stream", siteID]))
# one lake sample (SUGG, a floating sweep) has subsamplePercent 0; every stream sample's is in (0, 100]
stopifnot(length(streams) == 24L, !anyDuplicated(ps[substr(sampleID, 1, 4) %in% streams, sampleID]),
          ps[substr(sampleID, 1, 4) %in% streams, all(as.numeric(subsamplePercent) > 0 & as.numeric(subsamplePercent) <= 100)], fd[siteID %in% streams, all(aquaticSiteType == "stream")],
          fd[siteID %in% streams, uniqueN(namedLocation), by = siteID][, all(V1 == 1)])

# --- surveys -------------------------------------------------------------------------------------------
sv <- fd[siteID %in% streams & (is.na(samplingImpractical) | samplingImpractical == "OK") & !is.na(sampleID)]
n_impr <- fd[siteID %in% streams & !is.na(samplingImpractical) & samplingImpractical != "OK", .N]
other_reach <- sv[substr(sampleID, 1, 4) != siteID, sampleID]
dna <- sv[grepl("\\.DNA$", sampleID), sampleID]
stopifnot(length(other_reach) == 27L, length(dna) == 3L, all(substr(other_reach, 1, 2) == "ST"))
sv <- sv[!sampleID %in% c(other_reach, dna)]
n_nops <- sv[!sampleID %in% ps$sampleID, .N]
sv <- sv[sampleID %in% ps$sampleID]
lab <- tx[sampleID %in% sv$sampleID]
n_nolab <- sv[!sampleID %in% lab$sampleID, .N]
bad_n    <- unique(lab[targetTaxaPresent == "N", sampleID])                       # an N row that names a taxon: unclear
bad_cnt  <- unique(lab[targetTaxaPresent == "Y" & is.na(individualCount), sampleID])  # a counted taxon with no count
bad_dmg  <- unique(lab[sampleCondition %in% "damaged, affecting analysis", sampleID])
stopifnot(all(is.na(lab[targetTaxaPresent == "N", individualCount])), all(!is.na(lab[targetTaxaPresent == "Y", acceptedTaxonID])))
drop_s <- unique(c(bad_n, bad_cnt, bad_dmg))
sv <- sv[sampleID %in% lab$sampleID & !sampleID %in% drop_s]
lab <- lab[sampleID %in% sv$sampleID]
stopifnot(all(lab$targetTaxaPresent == "Y"), !anyNA(lab$individualCount), all(as.integer(lab$individualCount) >= 1),
          !anyNA(lab$estimatedTotalCount), all(as.numeric(lab$estimatedTotalCount) >= as.numeric(lab$individualCount) - 1e-9))
cat(sprintf("  %d stream samples kept; %d not taken (samplingImpractical); %d of another reach, %d DNA; %d with no persample row, %d with no laboratory rows; dropped: %d with an N row, %d with a counted taxon missing its count, %d damaged affecting analysis (%d distinct)\n",
            nrow(sv), n_impr, length(other_reach), length(dna), n_nops, n_nolab, length(bad_n), length(bad_cnt), length(bad_dmg), length(drop_s)))
span <- sv[, as.numeric(diff(range(as.Date(substr(collectDate, 1, 10))))), by = eventID]
# a bout's samples are taken on one day, but for two MAYF bouts: one split over three days (kept) and
# one whose snag samples were taken 36 days after its cores (not one bout: dropped whole)
stopifnot(span[V1 > 0, .N] == 2L, span[V1 > 3, .N] == 1L)
ev_split <- span[V1 > 3, eventID]; n_split <- sv[eventID %in% ev_split, .N]
sv <- sv[!eventID %in% ev_split]; lab <- lab[sampleID %in% sv$sampleID]
stopifnot(sv[, uniqueN(siteID), by = eventID][, all(V1 == 1)])

# --- taxa --------------------------------------------------------------------------------------------------
lab[, rank := taxonRank]
stopifnot(!anyNA(lab$rank))
lab[, name := fifelse(rank %in% c("species", "subspecies"), sub("^(\\S+ \\S+).*$", "\\1", scientificName), sub(" spp?\\.$", "", scientificName))]
lab[rank == "subspecies", rank := "species"]
stopifnot(lab[, uniqueN(rank), by = name][, all(V1 == 1)])
code <- lab[, .N, by = .(name, rank, acceptedTaxonID)][order(-N)][, .(taxon = acceptedTaxonID[1], codes = paste(sort(unique(acceptedTaxonID)), collapse = "/"), n_codes = uniqueN(acceptedTaxonID)), by = .(name, rank)]
stopifnot(!anyDuplicated(code$name), !anyDuplicated(code$taxon))
lab <- merge(lab, code[, .(name, taxon)], by = "name")
counts <- lab[, .(y = sum(as.integer(individualCount)), est = sum(as.numeric(estimatedTotalCount))), by = .(sampleID, taxon)]
counts[, frac := pmin(1, y / est)]
stopifnot(all(counts$frac > 0))
# life-stage split (E8, 2026-11-06): one obs_ column per stage NEON records, 0 where none
STAGES <- c("larva", "pupa", "adult", "immature", "none", "unknown")
stopifnot(all(lab$invertebrateLifeStage %in% c(STAGES, NA)))
lab[, stage := fifelse(is.na(invertebrateLifeStage), "missing", invertebrateLifeStage)]
STAGES <- c(STAGES, if (any(lab$stage == "missing")) "missing")
st <- dcast(lab, sampleID + taxon ~ stage, value.var = "individualCount", fun.aggregate = function(v) sum(as.integer(v)), fill = 0L)
for (k in setdiff(STAGES, names(st))) st[, (k) := 0L]
setnames(st, STAGES, paste0("obs_n_stage_", STAGES))
STAGE_COLS <- paste0("obs_n_stage_", STAGES)
counts <- merge(counts, st[, c("sampleID", "taxon", STAGE_COLS), with = FALSE], by = c("sampleID", "taxon"))
stopifnot(counts[, all(y == Reduce(`+`, .SD))  , .SDcols = STAGE_COLS])
n_stage <- vapply(STAGE_COLS, function(k) sum(counts[[k]]), 0)
cat("  animals by stage:", paste(sprintf("%s %d", STAGES, n_stage), collapse = ", "), "\n")
tot <- lab[, .(n_ind = sum(as.integer(individualCount)), n_samples = uniqueN(sampleID)), by = .(taxon, name, rank)][order(-n_ind)]
tot <- merge(tot, lab[, .(phylum = phylum[1], class = class[1], order = order[1], family = family[1]), by = taxon], by = "taxon")[order(-n_ind)]
cat(sprintf("  %d taxa (%d species, %d higher rank); %d sp./spp. code pairs merged; %d animals counted\n",
            nrow(tot), tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], sum(tot$n_ind)))

# --- periods, occasions, units -------------------------------------------------------------------------
sv[, day := substr(collectDate, 1, 10)]
ev <- sv[, .(day = day[1], site = siteID[1], bout = as.integer(boutNumber[1])), by = eventID]
setorder(ev, day, eventID); ev[, period := seq_len(.N)][, year := as.integer(substr(day, 1, 4))]
stopifnot(all(ev$bout %in% 1:3))
sv <- merge(sv, ev[, .(eventID, period)], by = "eventID")
setorder(sv, period, sampleID); sv[, occasion := seq_len(.N), by = period]
sv <- merge(sv, ps[, .(sampleID, ps_frac = as.numeric(subsamplePercent) / 100)], by = "sampleID")
units <- fd[siteID %in% streams][order(siteID, -as.numeric(as.Date(substr(collectDate, 1, 10))))][!duplicated(siteID),
          .(unit = siteID, domain = domainID, named_location = namedLocation, decimalLatitude = as.numeric(decimalLatitude),
            decimalLongitude = as.numeric(decimalLongitude), coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty),
            elevation_m = as.numeric(elevation))]
units <- units[unit %in% sv$siteID]
n_moved <- fd[siteID %in% streams, uniqueN(paste(decimalLatitude, decimalLongitude)), by = siteID][V1 > 1, .N]
base <- sv[, .(unit = siteID, period, occasion, date = collectDate,
               obs_habitat_type = habitatType, obs_sampler_type = samplerType, obs_benthic_area_m2 = as.numeric(benthicArea),
               obs_substratum = substratumSizeClass, ps_frac, sampleID)]
stopifnot(!anyNA(base$obs_benthic_area_m2), all(base$obs_benthic_area_m2 > 0))
setkey(counts, sampleID, taxon)
periods <- ev[, .(period, eventID, site, year, bout, date = day)]
# per-site pool (ruling 19): the taxa this table records at the site at any sample
pool <- unique(merge(counts[, .(sampleID, taxon)], base[, .(sampleID, unit)], by = "sampleID")[, .(unit, taxon)])
setorder(pool, unit, taxon)
survey_taxa <- pool
pool_n <- pool[, .N, by = unit]
stopifnot(setequal(pool$taxon, tot$taxon), setequal(pool$unit, base$unit))
build <- function(pp) {
  b <- base[period %in% pp]
  long <- merge(b, pool, by = "unit", allow.cartesian = TRUE)
  m <- counts[.(long$sampleID, long$taxon)]
  long[, `:=`(y = m$y, obs_subsample_fraction = m$frac)]
  for (k in STAGE_COLS) set(long, j = k, value = m[[k]])
  long[is.na(y), `:=`(y = 0L, obs_subsample_fraction = ps_frac)]
  for (k in STAGE_COLS) set(long, i = which(is.na(long[[k]])), j = k, value = 0L)
  long[, c("ps_frac", "sampleID") := NULL]
  setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
  stopifnot(nrow(long) == sum(pool_n[b, on = "unit"]$N))
  long
}
n_rows <- sum(pool_n[base, on = "unit"]$N)
stopifnot(sum(counts[sampleID %in% base$sampleID, y]) == sum(tot$n_ind))
cat(sprintf("  %d samples in %d bouts at %d sites, %d-%d; %d rows; per-site pools median %d taxa (range %d-%d), __survey_taxa %d rows\n", nrow(base), nrow(ev), uniqueN(base$unit), min(ev$year), max(ev$year), n_rows,
            as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), nrow(survey_taxa)))
stopifnot(n_rows < 5e6)

# --- __taxa: GBIF, with NEON's classification as hints where the plain match is not an animal ------------
nokey_rank <- c("speciesGroup", "subgenus")
nokey <- tot[rank %in% nokey_rank, taxon]
rem <- ifelse(tot$rank == "species", NA_character_,
              sprintf("identified by the NEON taxonomy laboratory only to %s; NEON code(s) %s", tot$rank, code$codes[match(tot$taxon, code$taxon)]))
rem[tot$rank == "speciesGroup"] <- paste0(rem[tot$rank == "speciesGroup"], "; a species group or genus pair NEON records as one; the GBIF backbone holds no such taxon, so taxonID is empty")
rem[tot$rank == "subgenus"] <- paste0(rem[tot$rank == "subgenus"], "; a subgenus, not matched on the GBIF backbone, so taxonID is empty")
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = tot$rank, exact = FALSE, no_key = nokey, taxonRemarks = rem,
                  taxon_n_counted = tot$n_ind)
taxa[, kingdom := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey) NA_character_ else gbif_kingdom(scientificName[i]), "")]
fix <- taxa[!taxon %in% nokey & !(gbifMatchType == "EXACT" & kingdom %in% "Animalia"), taxon]
for (tk in fix) {
  h <- tot[taxon == tk]
  r <- gbif_taxon_hinted(h$name, list(kingdom = "Animalia", phylum = h$phylum, class = h$class, order = h$order, family = h$family))
  if (identical(r$canonicalName, h$name) && identical(r$kingdom, "Animalia")) {
    taxa[taxon == tk, `:=`(taxonID = r$taxonID, gbifMatchType = paste0(r$matchType, " (hinted)"), gbifAcceptedName = r$acceptedName)]
  } else {
    taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = r$matchType,
         taxonRemarks = paste0(fifelse(is.na(taxonRemarks), "", paste0(taxonRemarks, "; ")), "no match of this name among animals on the GBIF backbone (with NEON's classification as hints), so taxonID is empty"))]
  }
}
n_fixed <- taxa[taxon %in% fix & !is.na(taxonID), .N]; n_unmatched <- taxa[!taxon %in% nokey & is.na(taxonID), .N]
cat(sprintf("  GBIF: %d taxa re-matched with NEON's classification as hints, %d without a key (plus %d species groups and subgenera)\n", n_fixed, n_unmatched, length(nokey)))
taxa[, kingdom := NULL]
stopifnot(!any(taxa$taxonID %in% "https://www.gbif.org/species/1"), all(!is.na(taxa$taxonID) | !is.na(taxa$taxonRemarks)))

long <- build(periods$period)
stopifnot(nrow(long) == n_rows, sum(long$y) == sum(tot$n_ind))
# E7 (batch 46, #10; ruling on the publisher, 2026-11-06, which withdrew the agency exception): taxa IUCN CR/EN/VU in
# their native range are in the table, so it ships with coarsened reach / plot coordinates, and neon_2026_macroinverts_exact_count without them
# (and without the higher-rank taxa that could be one of them) at NEON's published coordinates (E7 scope, 3)
NONNATIVE <- character()
taxa[, taxon_iucnCategory := unname(mapply(iucn_category, taxonID, scientificName))]
fl_sp <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU") & !taxon %in% NONNATIVE, taxon]
stopifnot(setequal(fl_sp, c("VALMER")))
fl <- fl_sp   # E7 scope 3: the sibling drops the flagged taxa; records identified only to a higher rank stay
flag <- taxa[taxon %in% fl_sp, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cat("  flagged:", paste(flag, collapse = "; "), "\n")
cg <- coarsen_coords(units$decimalLatitude, units$decimalLongitude, 0.1)
units_c <- copy(units)[, `:=`(decimalLatitude = cg$lat, decimalLongitude = cg$lon, coordinateUncertaintyInMeters = cg$uncertainty_m)]
if ("elevation_m" %in% names(units_c)) units_c[, elevation_m := round(elevation_m, -2)]
EXACT <- "neon_2026_macroinverts_exact_count"
emit <- function(TABLE, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  ut <- if (exact) units else units_c
  nt <- nrow(tt)
  dataset <- list(
    title = paste0(sprintf("NEON wadeable-stream benthic macroinvertebrates, RELEASE-2026: animals of %d taxa counted per sample, about eight samples per bout and three bouts a year at %d NEON stream sites, %d-%d", nt, uniqueN(base$unit), min(ev$year), max(ev$year)), if (exact) " (without IUCN-threatened taxa; coordinates as published)" else ""),
    creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = sub("^https://doi.org/", "", DOI),
    sourceURL = "https://data.neonscience.org/data-products/DP1.20120.001/RELEASE-2026",
    citation = sprintf("NEON (National Ecological Observatory Network). Macroinvertebrate collection (DP1.20120.001), RELEASE-2026. %s. Dataset accessed from https://data.neonscience.org/data-products/DP1.20120.001/RELEASE-2026 on 2026-11-06", DOI),
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("NEON's benthic macroinvertebrate survey of wadeable streams: in spring, summer and fall bouts, about eight samples are taken in the two dominant habitat types of the reach (riffles, runs, pools, step pools) with the sampler suited to each (Surber, Hess, core, modified kicknet, snag), preserved, and sent to a taxonomy laboratory, which sorts a fraction of each sample and counts and identifies every animal in it (large or rare taxa are picked from the whole sample). This table is the number of animals of each taxon counted in each sample, with each life stage's count beside it; the taxa surveyed for at a site are the per-site pool of taxa this table records there (median %d of %d; __survey_taxa), so a taxon never found at a site has no zeros there. obs_subsample_fraction gives the fraction they were counted in. Reach-centre coordinates are as NEON publishes them.", as.integer(median(pool_n$N)), nt),
    samplingProtocol = "Benthic samples in the two dominant habitat types of a wadeable-stream reach, with a Surber, Hess, core, modified kicknet or snag sampler of known area, three bouts a year; samples preserved in ethanol and sorted, counted and identified by a taxonomy laboratory from a subsample (NEON AOS aquatic macroinvertebrate sampling protocol, NEON.DOC.003046)",
    samplingProtocolCode = "benthic_sampler", surveyEvidence = "sample_table",
    surveyEvidenceNote = "inv_fieldData lists every sample (with samplingImpractical where one was not taken); a survey is a stream sample with samplingImpractical blank or OK, a sampleID, an inv_persample row and laboratory rows in inv_taxonomyProcessed. The zeros rest on a per-site species pool derived from detections (ruling 19): the taxa surveyed for at a site are every taxon this table records at that site in any sample (__survey_taxa), not a list NEON deposited, so a taxon never recorded at a site has no rows there and a taxon recorded once at a site is a zero at every other sample there.",
    responseType = "count", unitKind = "site", effortColumn = "obs_benthic_area_m2", subsampleColumn = "obs_subsample_fraction",
    closure = "closed", closureNote = "occasion = sample within one bout, taken on one day in different patches of the two dominant habitat types (asserted: one bout spread over three days; a bout whose samples are 36 days apart is dropped); period = bout (spring, summer, fall), indexed globally by date", occasionKind = "spatial",
    taxonInclusion = "recorded",
    geographicCoverage = sprintf("%d NEON wadeable-stream sites in the continental USA, Alaska and Puerto Rico; reach-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", nrow(units), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
    temporalCoverage = sprintf("%s/%s", substr(min(ev$day), 1, 7), substr(max(ev$day), 1, 7)),
    crs = "EPSG:4326 (WGS 84), as published",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("As published by NEON (coordinates with coordinateUncertaintyInMeters in __units). The IUCN-threatened taxa (%s) are not in this table (E7 scope, 3); neon_2026_macroinverts_count has them, with coordinates coarsened.", paste(flag, collapse = ", "))) else
      list(value = TRUE, method = sprintf("coarsen_coords(): NEON's published coordinates in __units snapped to their 0.1-degree cell centre, uncertainty the cell half-diagonal, elevation rounded to 100 m, because taxa IUCN CR/EN/VU in their native range are in the table (%s; E7, ruling on the publisher 2026-11-06, which withdrew the agency exception). NEON site and location codes are kept: they locate a site, not a plot or reach, without NEON's own lookup. neon_2026_macroinverts_exact_count keeps the other taxa at published precision.", paste(flag, collapse = ", "))),
    covariateNote = "obs_habitat_type (riffle, run, pool, step pool) and obs_sampler_type (surber, hess, core, modifiedKicknet, snag) per sample; obs_benthic_area_m2 = area sampled (effort); obs_substratum = dominant substratum size class; obs_subsample_fraction (subsampleColumn) = for a counted taxon, its counted animals over NEON's whole-sample estimate of it (the fraction it was counted in), for a taxon not found, the share of the sample sorted (inv_persample subsamplePercent / 100). It may vary across taxa within a sample (E5). obs_n_stage_<stage> = animals of the taxon counted in that life stage (larva, pupa, adult, immature, none = NEON's stage for taxa without one, unknown; missing = no stage on the laboratory row, where present); they sum to y.",
    notes = sprintf("y = animals counted by the laboratory, summed over size classes and life stages, with each stage's count as obs_n_stage_<stage> (E8 ruling of 2026-11-06); the whole-sample estimate (estimatedTotalCount) is not shipped. Per-site pools (ruling 19; rebuilt 2026-11-06, batch 47, from the national pool of batch 38): median %d taxa a site (range %d-%d). Taxa: %d species (subspecies rolled up) and %d records identified only to a higher rank, a subgenus or a species group, each its own taxon (E6); %d pairs of NEON 'sp.' and 'spp.' codes for one name merged (ruling 20, taxonRemarks lists the codes); life stages pooled. Subsample fractions: NEON's per-row subsamplePercent differs between taxa of one sample (large or rare taxa picked from the whole sample) and from inv_persample's in a fifth of samples, so the fraction is given per row, as above. Surveys: %d samples in %d bouts; %d samples not taken; %d samples of a second reach filed under another site's bout and %d DNA samples not in the table; %d with no persample row and %d with no laboratory rows; %d dropped (%d with a targetTaxaPresent N row naming a taxon, %d with a counted taxon missing its count, %d marked damaged, affecting analysis).", as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], nrow(base), nrow(ev), n_impr, length(other_reach), length(dna), n_nops, n_nolab, length(drop_s), length(bad_n), length(bad_cnt), length(bad_dmg)),
    notShipped = c(if (exact) list(threatened = sprintf("%s; records identified only to a higher rank stay in both tables: in neon_2026_macroinverts_count only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "))), list(
      `lake and river samples` = sprintf("%d lake and river sites (petite ponar near the buoy and other deep-water points, sweeps in the littoral): other protocols; %d samples with no aquaticSiteType (a grab sample and macroalgae samples)", length(setdiff(unique(fd$siteID), streams)), n_notype),
      `excluded samples` = sprintf("%d samples of a second reach (site prefixes STCU, STKG, STMA, STWA) filed under another site's eventID; %d '.DNA' samples; %d samples of the bout %s, whose snag samples were taken 36 days after its cores; %d with a targetTaxaPresent N row naming a taxon; %d with a counted taxon missing its count (fragments, headless animals); %d marked damaged, affecting analysis", length(other_reach), length(dna), n_split, ev_split, length(bad_n), length(bad_cnt), length(bad_dmg)),
      `whole-sample estimate` = "estimatedTotalCount (the laboratory's estimate of the whole sample; y and obs_subsample_fraction are shipped)",
      `other fields` = "size classes (sizeClass, mm), sorting QC, identification history, inv_taxonomyRaw (expanded package)",
      `zeros outside the site pool` = "a taxon never recorded at a site has no rows there (per-site pool, ruling 19)")))
  st <- if (exact) survey_taxa[!taxon %in% fl] else survey_taxa
  ds <- write_table(lt, TABLE, dataset, taxa = tt, periods = periods, units = ut, survey_taxa = st,
                    script = "data/neon_2026_macroinverts_count.R")

  stage_dict_row(TABLE,
    description = sprintf("Animals of %d benthic macroinvertebrate taxa counted per sample (about eight samples per bout in the two dominant habitats, spring, summer and fall bouts) at %d NEON wadeable-stream sites, %d-%d, built from NEON's field, sorting and taxonomy-laboratory records (RELEASE-2026), with habitat, sampler, area sampled, the fraction counted and reach-centre coordinates as published.", nt, uniqueN(base$unit), min(ev$year), max(ev$year)),
    url = "https://data.neonscience.org/data-products/DP1.20120.001/RELEASE-2026",
    reference = sprintf("NEON (National Ecological Observatory Network). Macroinvertebrate collection (DP1.20120.001), RELEASE-2026. %s", DOI),
    doi_paper = "", doi_data = sub("^https://doi.org/", "", DOI),
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "Token-gated NEON API (NEON_TOKEN); release pinned. Streams only; y = counted subsample with obs_subsample_fraction (subsampleColumn) and life-stage counts as obs_; per-site pool from detections (ruling 19).",
    source_via = "NEON Data API, basic package")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
    sampling_protocol = "benthic_sampler", design = sprintf("Multi-season (%d bouts x about 8 samples)", nrow(ev)), realm = "Freshwater", country = "USA",
    coordinates = if (exact) "As published" else "Coarsened (0.1 deg)", notes = "NEON national scheme; wadeable streams; counted-subsample counts per benthic sample; per-site species pools (__survey_taxa); life-stage counts as obs_.",
    status = "tagged")
}
emit("neon_2026_macroinverts_count", exact = FALSE)
emit(EXACT, exact = TRUE)
