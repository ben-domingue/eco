#!/usr/bin/env Rscript
# Table:  neon_2026_fish_removal
# Source: NEON (National Ecological Observatory Network). Fish electrofishing, gill netting, and fyke
#         netting counts (DP1.20107.001), RELEASE-2026. https://doi.org/10.48443/s1e6-df79. Dataset
#         accessed from https://data.neonscience.org/data-products/DP1.20107.001/RELEASE-2026 on
#         2026-11-05 through the NEON Data API (token-gated; NEON_TOKEN environment variable, see
#         lib/eco_common.R). Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/
#         ("NEON data products and sample data are licensed under a Creative Commons Attribution 4.0
#         International License (CC-BY)"); the product page itself is rendered by JavaScript.
#         NEON is funded by the U.S. National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.001295 (AOS Protocol and Procedure: Fish
#         Sampling in Wadeable Streams) and the product user guide, linked from the product page.
# Data:   basic package, all 28 aquatic sites and 421 site-months of the release (2016-2024):
#         fsh_fieldData: one row per reach x bout (namedLocation = reach, eventID = SITE.YEAR.season
#           with season spring / fall / other, aquaticSiteType stream / lake, fixedRandomReach,
#           reach-centre decimalLatitude/Longitude as published with coordinateUncertainty,
#           measuredReachLength, samplingImpractical); a reach-bout with samplingImpractical set
#           has no passes.
#         fsh_perPass: one row per pass (passNumber, samplerType electrofisher / two electrofishers
#           / gill net / mini-fyke net, passStartTime, efTime, waterTemp, habitatType,
#           targetTaxaPresent Y/N).
#         fsh_perFish: one row per fish identified and measured on a pass (taxonID, scientificName,
#           taxonRank, morphospeciesID, length, weight, life stage).
#         fsh_bulkCount: fish of a taxon counted but not measured on a pass, once 50 to 100 of that
#           taxon had been measured (bulkFishCount, actualOrEstimated).
#         The readme: species of concern are 'fuzzed' to a higher rank at most sites, and withheld at
#           a few (GRSM); fixed reaches are fished with three-pass removal, random reaches with one
#           pass.
# Mapping (standard E9 declared stretch: removal sampling, responseType multinomial_cell,
#   multinomialType removal; unitKind site):
#   Wadeable-stream electrofishing only (the 23 stream sites); the lake gill-net, fyke-net and
#   shoreline-electrofishing surveys are other protocols and are not in this table.
#   unit = reach (NEON namedLocation; a reach split by a permanent barrier is two namedLocations,
#   '.above' / '.below', as NEON publishes them); unit_site = NEON site; period = bout, a global
#   integer index over the distinct eventIDs ordered by first pass then eventID (__periods: eventID,
#   site, year, season, first and last pass date); occasion = pass 1-3 (the removal cell), y_raw =
#   "pass<k>"; y = fish of the taxon caught on the pass = perFish rows + bulkFishCount; date = the
#   pass start time as published (UTC). obs_sampler_type, obs_ef_time_s, obs_water_temp_c,
#   obs_habitat_type per pass; obs_count_estimated = 1 where y includes a bulk count NEON marks
#   'estimated' (actualOrEstimated), else 0 (ruling 17, 2026-11-06: counts the source labels as
#   estimated are kept with an obs_ flag, not dropped; standard E2); period_reach_type (fixed / random; NEON relabelled a few reaches
#   between bouts) and period_reach_length_m per reach-bout.
#   Survey evidence = sample_table: fsh_fieldData lists every reach-bout and fsh_perPass every pass;
#   a survey is a pass of a reach-bout with samplingImpractical blank. Every taxon has a row on
#   every pass (national pool, as neon_2026_carabids_count); a pass with targetTaxaPresent = N is
#   y = 0 for every taxon.
#   Taxa: NEON taxonID; subspecies rolled up to the species; records NEON identified (or fuzzed)
#   only to genus, family, order, class or phylum are their own taxa at that rank (E6), with NEON's
#   'sp.' and 'spp.' codes for one name merged. Morphospecies rows carry the taxonID of their genus
#   or family and are counted there.
#   Not shipped: lake surveys and gear (other protocols); reach-bouts NEON filed under an eventID
#   ending '.netCompromised' (a block net failed mid-bout and the later passes were split off), and
#   the bout's remaining passes when they are then not numbered 1..k; reach-bouts whose passes are
#   not numbered 1..k; reach-bouts with a
#   pass marked targetTaxaPresent = Y but no fish records; the per-fish lengths, weights, life
#   stages and sample ids; fsh_invertBycatch.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_fish_removal"
PRODUCT <- "DP1.20107.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/s1e6-df79"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("fsh_fieldData", "fsh_perPass", "fsh_perFish", "fsh_bulkCount"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 421L, identical(attr(nx, "productDoi"), DOI))
fd <- nx$fsh_fieldData; pp <- nx$fsh_perPass; pf <- nx$fsh_perFish; bc <- nx$fsh_bulkCount
cat(sprintf("  fsh_fieldData %d, fsh_perPass %d, fsh_perFish %d, fsh_bulkCount %d rows\n", nrow(fd), nrow(pp), nrow(pf), nrow(bc)))

# --- the source as deposited --------------------------------------------------------------------
fd[, rb := paste(namedLocation, eventID)]; pp[, rb := paste(namedLocation, eventID)]
pp[, pass_key := paste(rb, passNumber)]; pf[, pass_key := paste(namedLocation, eventID, passNumber)]
bc[, pass_key := paste(namedLocation, eventID, passNumber)]
stopifnot(uniqueN(fd$siteID) == 28L, !anyDuplicated(fd$rb), all(fd$aquaticSiteType %in% c("stream", "lake")),
          !anyDuplicated(pp$pass_key), all(pp$rb %in% fd$rb), all(pf$pass_key %in% pp$pass_key), all(bc$pass_key %in% pp$pass_key),
          # a reach-bout has passes iff samplingImpractical is blank
          identical(fd$rb %in% pp$rb, is.na(fd$samplingImpractical)),
          !anyNA(pf$taxonID), !anyNA(bc$taxonID), !anyNA(bc$bulkFishCount), all(as.integer(bc$bulkFishCount) >= 1),
          all(bc$actualOrEstimated %in% c("actual", "estimated", NA)), all(pp$targetTaxaPresent %in% c("Y", "N")),
          !anyDuplicated(pf[, .(pass_key, specimenNumber)]),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", pp$passStartTime)))
streams <- sort(unique(fd[aquaticSiteType == "stream", siteID]))
stopifnot(length(streams) == 23L, !length(intersect(streams, fd[aquaticSiteType == "lake", siteID])))
fs <- fd[siteID %in% streams]; ps <- pp[siteID %in% streams]
stopifnot(all(ps$samplerType %in% c("electrofisher", "two electrofishers")), all(ps$passNumber %in% c("1", "2", "3")))
ps[, pass := as.integer(passNumber)]
n_impr <- fs[!is.na(samplingImpractical), .N]

# --- reach-bouts dropped, and why -----------------------------------------------------------------
recs <- unique(c(pf$pass_key, bc$pass_key))
stopifnot(!any(ps$targetTaxaPresent == "N" & ps$pass_key %in% recs))
rb_net  <- unique(ps[grepl("\\.netCompromised$", eventID), rb])
rb_gap  <- setdiff(ps[, .(ok = identical(sort(pass), seq_len(.N))), by = rb][ok == FALSE, rb], rb_net)
rb_miss <- unique(ps[targetTaxaPresent == "Y" & !pass_key %in% recs, rb])
rb_est  <- unique(bc[actualOrEstimated == "estimated" & siteID %in% streams, paste(namedLocation, eventID)])
n_est_fish <- bc[actualOrEstimated == "estimated" & siteID %in% streams, sum(as.integer(bulkFishCount))]
drop_rb <- unique(c(rb_net, rb_gap, rb_miss))
cat(sprintf("  stream reach-bouts: %d with passes, %d sampling impractical; dropped: %d net-compromised, %d other with passes not 1..k, %d with a Y pass and no fish records; %d dropped in all; %d with an estimated bulk count (%d fish), kept and flagged\n",
            uniqueN(ps$rb), n_impr, length(rb_net), length(rb_gap), length(rb_miss), length(drop_rb), length(rb_est), n_est_fish))
stopifnot(length(rb_gap) == 5L, length(rb_miss) == 1L, length(rb_est) == 23L)
sv <- ps[!rb %in% drop_rb]
sv <- merge(sv, fs[, .(rb, period_reach_type = fixedRandomReach, period_reach_length_m = as.numeric(measuredReachLength))], by = "rb")

# --- counts per pass x taxon ------------------------------------------------------------------------
recs_f <- rbind(pf[pass_key %in% sv$pass_key, .(pass_key, taxonID, scientificName, taxonRank, n = 1L, est = 0L)],
                bc[pass_key %in% sv$pass_key, .(pass_key, taxonID, scientificName, taxonRank = NA_character_, n = as.integer(bulkFishCount),
                                                est = as.integer(actualOrEstimated %in% "estimated"))])
# bulk rows carry no rank: take it from the per-fish rows of the same taxonID, else from the name
rk <- unique(pf[, .(taxonID, rk = taxonRank)]); stopifnot(!anyDuplicated(rk$taxonID))
recs_f[is.na(taxonRank), taxonRank := rk$rk[match(taxonID, rk$taxonID)]]
recs_f[is.na(taxonRank), taxonRank := ifelse(grepl(" spp?\\.$", scientificName), "genus", "species")]
stopifnot(all(recs_f$taxonRank %in% c("species", "subspecies", "genus", "family", "order", "class", "phylum")))
recs_f[, name := fifelse(taxonRank %in% c("species", "subspecies"), sub("^(\\S+ \\S+).*$", "\\1", scientificName),
                         sub(" spp?\\.$", "", scientificName))]
recs_f[taxonRank == "subspecies", taxonRank := "species"]
stopifnot(!any(grepl(" ", recs_f[taxonRank != "species", name])))
# one code per name: the most frequent NEON code among the rows of that name and rank
code <- recs_f[, .N, by = .(name, taxonRank, taxonID)][order(-N)][, .(taxon = taxonID[1], codes = paste(sort(unique(taxonID)), collapse = "/")), by = .(name, taxonRank)]
stopifnot(!anyDuplicated(code$name), !anyDuplicated(code$taxon))
recs_f <- merge(recs_f, code[, .(name, taxon)], by = "name")
counts <- recs_f[, .(y = sum(n), obs_count_estimated = as.integer(any(est == 1L))), by = .(pass_key, taxon)]
n_est_rows <- counts[obs_count_estimated == 1L, .N]; n_est_kept <- recs_f[est == 1L, sum(n)]
stopifnot(n_est_kept == n_est_fish)      # every estimated bulk count is on a shipped pass
tot <- recs_f[, .(n_fish = sum(n)), by = .(taxon, name, taxonRank)][order(-n_fish)]
cat(sprintf("  %d taxa (%d species, %d higher rank); %d fish on the shipped passes\n", nrow(tot), tot[taxonRank == "species", .N], tot[taxonRank != "species", .N], sum(tot$n_fish)))

# --- periods, units, long table ---------------------------------------------------------------------
sv[, date := passStartTime]
ev <- sv[, .(first = min(substr(passStartTime, 1, 10)), last = max(substr(passStartTime, 1, 10))), by = .(eventID, siteID)]
setorder(ev, first, eventID); ev[, period := seq_len(.N)]
ev[, `:=`(year = as.integer(sub("^[A-Z]+\\.(\\d{4})\\..*$", "\\1", eventID)), season = sub("^[A-Z]+\\.\\d{4}\\.", "", eventID))]
stopifnot(all(ev$season %in% c("spring", "fall", "other")), all(ev$year == as.integer(substr(ev$first, 1, 4))))
sv <- merge(sv, ev[, .(eventID, period)], by = "eventID")
span <- sv[, as.numeric(diff(range(as.Date(substr(passStartTime, 1, 10))))), by = rb]
stopifnot(max(span$V1) <= 3)
# reach coordinates: NEON re-surveyed a few reaches (shifts of a few metres); __units keeps the latest
fs[, first_date := substr(startDate, 1, 10)]
units <- fs[rb %in% sv$rb][order(namedLocation, -as.numeric(as.Date(first_date)))][!duplicated(namedLocation),
            .(unit = namedLocation, site = siteID, domain = domainID, decimalLatitude = as.numeric(decimalLatitude),
              decimalLongitude = as.numeric(decimalLongitude), coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty),
              elevation_m = as.numeric(elevation))]
n_moved <- fs[rb %in% sv$rb, uniqueN(paste(decimalLatitude, decimalLongitude)), by = namedLocation][V1 > 1, .N]
base <- sv[, .(unit = namedLocation, period, occasion = pass, y_raw = paste0("pass", pass), date,
               unit_site = siteID, period_reach_type, period_reach_length_m,
               obs_sampler_type = samplerType, obs_ef_time_s = as.numeric(efTime), obs_water_temp_c = as.numeric(waterTemp),
               obs_habitat_type = habitatType, pass_key)]
taxa_codes <- tot$taxon
long <- base[rep(seq_len(.N), each = length(taxa_codes))][, taxon := rep(taxa_codes, times = nrow(base))]
long <- merge(long, counts, by = c("pass_key", "taxon"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_count_estimated = 0L)]; long[, pass_key := NULL]
setcolorder(long, c("unit", "taxon", "y", "y_raw", "period", "occasion", "date"))
stopifnot(long[obs_count_estimated == 1L, .N] == n_est_rows, all(long[obs_count_estimated == 1L, y] >= 1))
stopifnot(nrow(long) == nrow(sv) * length(taxa_codes), sum(long$y) == sum(tot$n_fish),
          !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d passes in %d reach-bouts at %d reaches, %d sites, %d bouts; %d rows\n",
            nrow(sv), uniqueN(sv$rb), uniqueN(sv$namedLocation), uniqueN(sv$siteID), nrow(ev), nrow(long)))

higher <- tot[taxonRank != "species", taxon]
# GBIF needs: the current spelling of the cutthroat trout, the author to separate the goby genus from a
# plant homonym; it does not match the class Actinopterygii strictly (one fish, no key). Three genera need their
# authors too: without them the strict match falls through to the kingdom (gbif.org/species/1)
look <- c("Oncorhynchus clarki" = "Oncorhynchus clarkii", "Sicydium" = "Sicydium Valenciennes, 1837",
          "Cyprinella" = "Cyprinella Girard, 1856", "Fundulus" = "Fundulus Lacepède, 1803", "Micropterus" = "Micropterus Lacepède, 1802")
stopifnot(all(names(look) %in% tot$name), "Actinopterygii" %in% tot$name)
nokey <- tot[name == "Actinopterygii", taxon]
rem <- ifelse(tot$taxonRank == "species", NA_character_,
              sprintf("identified by NEON only to %s (or fuzzed to it to protect a species of concern); NEON code(s) %s",
                      tot$taxonRank, code$codes[match(tot$taxon, code$taxon)]))
rem[tot$taxon %in% nokey] <- paste0(rem[tot$taxon %in% nokey], "; the GBIF backbone gives no strict match for the class Actinopterygii, so taxonID is empty")
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = tot$taxonRank, lookupName = ifelse(tot$name %in% names(look), look[tot$name], tot$name),
                  allow_higher = setdiff(higher, nokey), no_key = nokey, taxonRemarks = rem,
                  taxon_n_fish = tot$n_fish)
# Cyprinidae: the strict match resolves to the kingdom whatever the authorship (a bivalve homonym in the backbone);
# the accepted fish family is backbone key 7336, set by hand and recorded
stopifnot(taxa[scientificName == "Cyprinidae", taxonID] == "https://www.gbif.org/species/1")
taxa[scientificName == "Cyprinidae", `:=`(taxonID = "https://www.gbif.org/species/7336", gbifMatchType = "MANUAL",
     taxonRemarks = paste0(taxonRemarks, "; GBIF's strict match for Cyprinidae falls to the kingdom (a homonym), so taxonID is the accepted fish family's backbone key, set by hand"))]
stopifnot(!any(taxa$taxonID %in% "https://www.gbif.org/species/1"))
periods <- ev[, .(period, eventID, site = siteID, year, season, first_pass_date = first, last_pass_date = last)]
dataset <- list(
  title = sprintf("NEON wadeable-stream fish, three-pass electrofishing removal, RELEASE-2026: fish of %d taxa per pass at %d reaches on %d NEON stream sites, %d-%d", nrow(tot), uniqueN(sv$namedLocation), uniqueN(sv$siteID), min(ev$year), max(ev$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/s1e6-df79",
  sourceURL = "https://data.neonscience.org/data-products/DP1.20107.001/RELEASE-2026",
  citation = "NEON (National Ecological Observatory Network). Fish electrofishing, gill netting, and fyke netting counts (DP1.20107.001), RELEASE-2026. https://doi.org/10.48443/s1e6-df79. Dataset accessed from https://data.neonscience.org/data-products/DP1.20107.001/RELEASE-2026 on 2026-11-05",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's fish survey in wadeable streams: ten reaches of about 100 m per site, three fixed reaches fished by three-pass electrofishing removal and the others by a single pass, in spring and fall bouts. Every fish is identified (to species where possible) and up to 50-100 per taxon per pass are measured; the rest are bulk-counted. This table is the number of fish of each taxon per pass, with every taxon on every pass (national pool, %d taxa). Reach-centre coordinates are as NEON publishes them.", nrow(tot)),
  samplingProtocol = "Backpack (or two-unit) electrofishing of a ~100 m reach in an upstream direction; fixed reaches fished in three consecutive removal passes, random reaches in one; fish netted, identified, a subset measured and weighed, and released after the bout (NEON AOS fish sampling protocol, NEON.DOC.001295)",
  samplingProtocolCode = "electrofishing", surveyEvidence = "sample_table",
  surveyEvidenceNote = "fsh_fieldData lists every reach-bout (with samplingImpractical where it was not fished) and fsh_perPass every pass; a survey is a pass of a reach-bout with samplingImpractical blank. A pass with targetTaxaPresent = N is y = 0 for every taxon.",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site",
  closure = "closed", closureNote = "occasion = removal pass within one reach-bout; passes are consecutive, almost all on one day (at most 3 days apart, asserted); period = bout (spring or fall, a few 'other'), indexed globally by first pass date", occasionKind = "cell",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("23 NEON wadeable-stream sites in the continental USA, Alaska and Puerto Rico; reach-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(ev$first), 1, 7), substr(max(ev$last), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("As published by NEON (agency-published reach-centre coordinates with coordinateUncertaintyInMeters; NEON fuzzes species of concern to a higher rank rather than the coordinates); %d reaches were re-surveyed by a few metres between bouts and __units carries the latest", n_moved)),
  covariateNote = "obs_sampler_type electrofisher / two electrofishers; obs_ef_time_s = electrofisher operating seconds on the pass (effort, NA where not recorded); obs_water_temp_c and obs_habitat_type per pass as published; period_reach_type = fixed (three-pass) or random (one-pass) reach as NEON labels the reach-bout; period_reach_length_m = measured reach length (NA where not measured); obs_count_estimated = 1 where y includes a bulk count NEON marks 'estimated' (ruling 17), else 0.",
  notes = sprintf("y = per-fish records plus bulk counts of the taxon on the pass. Taxa: %d species (subspecies rolled up) and %d records identified, or fuzzed by NEON, only to a higher rank, each its own taxon (E6); NEON 'sp.' and 'spp.' codes of one name merged; morphospecies counted under their genus or family code. Surveys: %d passes in %d reach-bouts; %d reach-bouts sampling impractical have no rows; %d filed by NEON as net-compromised, %d other whose passes are not numbered 1..k and %d with a pass marked targetTaxaPresent = Y but no fish records were dropped whole. Estimated counts (ruling 17, 2026-11-06): %d reach-bouts carry a bulk count NEON marks estimated (%d fish); they are kept, and obs_count_estimated = 1 on the %d pass x taxon rows whose y includes one. Bulk counts with actualOrEstimated blank (before the field was recorded) are kept as counts, flag 0. Passes after the first are present only on fixed reaches, so a random reach-bout has one removal cell.", tot[taxonRank == "species", .N], tot[taxonRank != "species", .N], nrow(sv), uniqueN(sv$rb), n_impr, length(rb_net), length(rb_gap), length(rb_miss), length(rb_est), n_est_fish, n_est_rows),
  notShipped = list(
    `lake surveys` = sprintf("gill net, mini-fyke net and shoreline electrofishing at the %d lake sites (%s): other protocols", length(setdiff(unique(fd$siteID), streams)), paste(setdiff(sort(unique(fd$siteID)), streams), collapse = ", ")),
    `net-compromised bouts` = sprintf("%d reach-bouts NEON filed under an eventID ending .netCompromised (a block net failed; the passes after the failure are split from the bout)", length(rb_net)),
    `incomplete pass series` = sprintf("%d other reach-bouts whose passes are not numbered 1..k; %d reach-bouts with a pass marked targetTaxaPresent = Y but no fish records", length(rb_gap), length(rb_miss)),
    `per-fish measurements` = "fsh_perFish lengths, weights, life stages, DELT and injury flags, voucher and DNA sample ids",
    `invertebrate bycatch` = "fsh_invertBycatch (D04 decapods)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/neon_2026_fish_removal.R")

stage_dict_row(TABLE,
  description = sprintf("Fish of %d taxa per electrofishing pass (three-pass removal at fixed reaches, one pass at random reaches) at %d reaches on 23 NEON wadeable-stream sites, spring and fall bouts %d-%d, built from NEON's per-fish and bulk-count records (RELEASE-2026), with electrofishing time, water temperature, habitat and reach-centre coordinates as published.", nrow(tot), uniqueN(sv$namedLocation), min(ev$year), max(ev$year)),
  url = "https://data.neonscience.org/data-products/DP1.20107.001/RELEASE-2026",
  reference = "NEON (National Ecological Observatory Network). Fish electrofishing, gill netting, and fyke netting counts (DP1.20107.001), RELEASE-2026. https://doi.org/10.48443/s1e6-df79",
  doi_paper = "", doi_data = "10.48443/s1e6-df79",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Token-gated NEON API (NEON_TOKEN); release pinned. Streams only; estimated bulk counts kept with obs_count_estimated (ruling 17); higher-rank (incl. fuzzed) ids are their own taxa.",
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Removal (multi-species, multinomial N-mixture)",
  sampling_protocol = "electrofishing", design = sprintf("Multi-season (%d bouts, 1 or 3 removal passes)", nrow(ev)), realm = "Freshwater", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; wadeable streams; every taxon on every pass.",
  status = "tagged")
