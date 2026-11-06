#!/usr/bin/env Rscript
# Table:  neon_2026_plants_occ
# Source: NEON (National Ecological Observatory Network). Plant presence and percent cover
#         (DP1.10058.001), RELEASE-2026. Dataset accessed from
#         https://data.neonscience.org/data-products/DP1.10058.001/RELEASE-2026 on 2026-11-06 through
#         the NEON Data API (token-gated; NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data products
#         and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.014042 (TOS Protocol and Procedure: Plant Diversity
#         Sampling) and the product user guide, linked from the product page. The product's design
#         description: "Up to thirty Distributed Plots and three Tower Plots are measured at each site.
#         Plots are sampled annually at most sites to correspond with peak greenness, and twice a year at
#         select sites with bimodal peaks in greenness and species composition."
# Data:   basic package, all 47 terrestrial sites and 1,093 site-months of the release (2013-2025):
#         div_1m2Data: one row per species (divDataType plantSpecies, with percentCover) or ground-cover
#           variable (otherVariables) recorded in a 1 m2 subplot (subplotID 31_1_1, 32_1_2, ...: eight
#           per 400 m2 plot, two in each of the four 100 m2 subplots 31, 32, 40, 41) at a bout (eventID
#           SITE.bout.year, boutNumber 1 or 2, endDate), targetTaxaPresent Y/N, samplingImpractical,
#           identificationQualifier, morphospeciesID, plot-centre coordinates as published.
#         div_10m2Data100m2Data: species present in the 10 m2 and 100 m2 subplots (and the 400 m2 plot)
#           that were not already recorded in the smaller subplots nested in them.
#         The product remarks: "A record (species present) from div_1m2Data_pub is - based on the
#           protocol - also present in corresponding subplots in div_10m2Data100m2Data_pub but the
#           records are not always populated" in the larger subplots; species of concern are 'fuzzed'
#           to a higher rank.
# Scale (ruling 19, 2026-11-06: choose the one design that gives clean repeat visits): the 1 m2
#   subplot. It is the only scale with a complete list of the species in it at each visit: the 10 m2
#   and 100 m2 records hold only species new at that scale, so presence there is a union over nested
#   subplots that NEON says is not always populated, and the 400 m2 plot is that union again. The 1 m2
#   subplots are permanent and revisited every year (median 8 years) by the same method, twice a year
#   at the bimodal sites, and some subplots were listed twice within one bout; each is a survey.
# Mapping (standard E9 core: dynamic occupancy, multi-species; responseType detection):
#   unit = 1 m2 subplot, "<plotID>_<subplotID>"; cluster_id = plotID (the 400 m2 plot); unit_site;
#   period = calendar year (__periods); occasion = visit to the subplot within the year, ordered by
#   (boutNumber, endDate); date = endDate; y = 1 if NEON lists the taxon in the subplot at the visit,
#   else 0; obs_bout = NEON boutNumber; obs_percent_cover = the taxon's percent cover in the subplot,
#   summed over NEON's rows for it (morphospecies, infraspecific taxa), 0 where y = 0, NA where NEON
#   left a cover blank.
#   Survey evidence = sample_table: div_1m2Data has rows for every subplot visit, with samplingImpractical
#   where it was not sampled and targetTaxaPresent N where no plant was rooted in it; a survey is a
#   subplot x eventID x endDate with samplingImpractical blank or OK and data rows.
#   Taxa surveyed for (ruling 19): the per-site pool, every taxon this table records at the subplot's
#   site at any visit, carried by __survey_taxa (unit, taxon); a taxon never recorded at a site has no
#   rows there. The pool is derived from detections, which surveyEvidenceNote says.
#   Taxa: NEON taxonID; varieties and subspecies rolled up to the species; records identified to
#   genus, family, order, superorder or kingdom, and NEON's species groups ('A b/c'), are their own
#   taxa (E6); NEON 'sp.' and 'spp.' codes of one name merged (ruling 20), and NEON's four
#   kingdom-level codes (Unknown plant, Unknown hardwood plant, Unknown softwood plant, Plantae sp.)
#   are one taxon, Plantae, since none identifies anything below the kingdom (E6). Identifications NEON
#   qualifies 'cf.' are kept as recorded. Morphospecies rows are counted under their taxonID.
#   Not shipped: the 10 m2 and 100 m2 records (another scale); subplot visits with only ground-cover rows
#   and no targetTaxaPresent (2013-2016), or with both Y and N; the otherVariables rows (ground cover);
#   plant heights; vouchers and the genetic archive.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_plants_occ"
PRODUCT <- "DP1.10058.001"; RELEASE <- "RELEASE-2026"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("div_1m2Data", "div_10m2Data100m2Data"))
DOI <- attr(nx, "productDoi")
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 1093L, grepl("^https://doi.org/10.48443/", DOI))
d <- nx$div_1m2Data; n_big <- nrow(nx$div_10m2Data100m2Data); rm(nx); invisible(gc(FALSE))
cat(sprintf("  div_1m2Data %d rows (div_10m2Data100m2Data %d rows, not used); product DOI %s\n", nrow(d), n_big, DOI))

# --- the source as deposited --------------------------------------------------------------------
IMPR <- c("OK", "logistical", "management", "other", "extreme weather", "location flooded")
SUBPLOTS <- c("31_1_1", "31_1_4", "32_1_2", "32_1_4", "40_1_1", "40_1_3", "41_1_1", "41_1_4")
stopifnot(uniqueN(d$siteID) == 47L, all(is.na(d$samplingImpractical) | d$samplingImpractical %in% IMPR),
          all(d$subplotID %in% SUBPLOTS), all(d$divDataType %in% c("plantSpecies", "otherVariables", NA)),
          all(!is.na(d$samplingImpractical[is.na(d$divDataType)]) & d$samplingImpractical[is.na(d$divDataType)] != "OK"),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", d$endDate)), all(d$boutNumber %in% c("1", "2")),
          all(substr(d$endDate, 1, 4) == sub("^.*\\.", "", d$eventID)),
          all(d$targetTaxaPresent %in% c("Y", "N", NA)),
          !anyNA(d[divDataType == "plantSpecies" & targetTaxaPresent == "Y", taxonID]),
          all(is.na(d[divDataType == "plantSpecies" & targetTaxaPresent == "N", taxonID])))
for (cc in c("siteID", "domainID", "plotType", "nlcdClass")) stopifnot(d[, uniqueN(get(cc)), by = plotID][, all(V1 == 1)])

# --- surveys -------------------------------------------------------------------------------------------
n_impr <- nrow(unique(d[!is.na(samplingImpractical) & samplingImpractical != "OK", .(plotID, subplotID, eventID, endDate)]))
d <- d[(is.na(samplingImpractical) | samplingImpractical == "OK") & !is.na(divDataType)]
d[, sk := paste(plotID, subplotID, eventID, endDate)]
s <- d[, .(sp = any(divDataType == "plantSpecies" & targetTaxaPresent %in% "Y"), tY = any(targetTaxaPresent %in% "Y"),
           tN = any(targetTaxaPresent %in% "N"), tNA = all(is.na(targetTaxaPresent))),
       by = .(sk, siteID, plotID, subplotID, eventID, boutNumber, endDate)]
n_na <- s[tNA == TRUE, .N]; n_yn <- s[tY & tN, .N]; n_ynosp <- s[tY & !tN & !sp, .N]
stopifnot(n_na == 68L, n_yn == 2L, n_ynosp == 0L, s[tNA == TRUE, all(substr(endDate, 1, 4) <= "2016")])
s <- s[!tNA & !(tY & tN)]
stopifnot(identical(s$sp, s$tY))
s[, year := as.integer(substr(endDate, 1, 4))]
s[, unit := paste(plotID, subplotID, sep = "_")]
setorder(s, unit, year, boutNumber, endDate)
s[, occasion := seq_len(.N), by = .(unit, year)]
n_rep <- s[, .N, by = .(unit, eventID)][N > 1, sum(N - 1)]
cat(sprintf("  %d subplot visits kept (%d with no plant); %d not sampled; dropped %d visits with ground cover only and no targetTaxaPresent (2013-2016), %d with both Y and N; %d repeat visits within one bout kept as occasions\n",
            nrow(s), s[tN == TRUE, .N], n_impr, n_na, n_yn, n_rep))

# --- taxa ------------------------------------------------------------------------------------------------------
x <- d[sk %in% s$sk & divDataType == "plantSpecies" & targetTaxaPresent == "Y"]
RANKS <- c("species", "variety", "subspecies", "genus", "family", "order", "superorder", "kingdom", "speciesGroup")
stopifnot(all(x$taxonRank %in% RANKS))
x[, rank := fcase(taxonRank %in% c("species", "variety", "subspecies"), "species", default = taxonRank)]
x[, name := fcase(rank == "species", sub("^(\\S+ \\S+).*$", "\\1", scientificName),
                  rank == "kingdom", "Plantae",
                  rank == "speciesGroup", scientificName,
                  default = sub(" spp?\\.$", "", scientificName))]
stopifnot(!any(grepl(" ", x[!rank %in% c("species", "speciesGroup"), name])), x[, uniqueN(rank), by = name][, all(V1 == 1)],
          uniqueN(x[rank == "kingdom", taxonID]) == 4L)
code <- x[, .N, by = .(name, rank, taxonID)][order(-N)][, .(taxon = taxonID[1], codes = paste(sort(unique(taxonID)), collapse = "/"), n_codes = uniqueN(taxonID)), by = .(name, rank)]
stopifnot(!anyDuplicated(code$name), !anyDuplicated(code$taxon))
x <- merge(x, code[, .(name, taxon)], by = "name")
n_spspp <- code[n_codes > 1 & rank %in% c("genus", "family", "order", "superorder"), .N]
n_infra <- code[n_codes > 1 & rank == "species", .N]
det <- x[, .(y = 1L, obs_percent_cover = sum(as.numeric(percentCover))), by = .(sk, taxon)]
tot <- x[, .(n_records = uniqueN(sk), family = family[1]), by = .(taxon, name, rank)][order(-n_records)]
cat(sprintf("  %d taxa (%d species, %d higher rank or species group); %d names with several NEON codes merged (%d sp./spp. pairs, %d species with infraspecific codes); %d detections\n",
            nrow(tot), tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], n_spspp, n_infra, nrow(det)))

# --- per-site pool, periods, units ----------------------------------------------------------------------------
x[, unit := paste(plotID, subplotID, sep = "_")]
pool <- unique(x[, .(siteID, taxon)])
survey_taxa <- merge(unique(s[, .(unit, siteID)]), pool, by = "siteID", allow.cartesian = TRUE)[, .(unit, taxon)]
setorder(survey_taxa, unit, taxon)
pool_n <- pool[, .N, by = siteID]
periods <- data.table(year = sort(unique(s$year)))[, period := seq_len(.N)]
s <- merge(s, periods, by = "year")
pl <- unique(d[order(plotID, -as.numeric(as.Date(endDate)))][, .(plotID, site = siteID, domain = domainID, plot_type = plotType, nlcd_class = nlcdClass,
                 decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                 coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "plotID")
n_moved <- d[sk %in% s$sk, uniqueN(paste(decimalLatitude, decimalLongitude)), by = plotID][V1 > 1, .N]
units <- merge(unique(s[, .(unit, plotID, subplot = subplotID)]), pl, by = "plotID")[, .(unit, site, domain, plot = plotID, subplot, plot_type, nlcd_class,
                 decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, elevation_m)]
stopifnot(nrow(units) == uniqueN(s$unit))
n_rows <- sum(merge(s[, .(unit)], survey_taxa[, .N, by = unit], by = "unit")$N)
cat(sprintf("  per-site pools: median %d taxa (range %d-%d); %d subplots at %d plots, %d sites, %d years; %s rows; __survey_taxa %s rows\n",
            as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N), nrow(units), uniqueN(units$plot), uniqueN(units$site), nrow(periods),
            format(n_rows, big.mark = ","), format(nrow(survey_taxa), big.mark = ",")))

base <- s[, .(unit, period, occasion, date = endDate, cluster_id = plotID, unit_site = siteID, obs_bout = as.integer(boutNumber), sk)]
setkey(det, sk, taxon)
build <- function(pp) {
  b <- base[period %in% pp]
  long <- merge(b, survey_taxa, by = "unit", allow.cartesian = TRUE)
  m <- det[.(long$sk, long$taxon)]
  long[, `:=`(y = m$y, obs_percent_cover = m$obs_percent_cover)]
  long[is.na(y), `:=`(y = 0L, obs_percent_cover = 0)]
  long[, sk := NULL]
  setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date", "cluster_id", "unit_site", "obs_bout", "obs_percent_cover"))
  stopifnot(sum(long$y) == nrow(det[sk %in% b$sk]))
  long
}
stopifnot(nrow(det) == nrow(merge(det, unique(x[, .(sk, unit, siteID)]), by = "sk")))

# --- __taxa: GBIF, with NEON's family as a hint where the plain match is not a plant ------------------------------
nokey <- tot[rank == "speciesGroup", taxon]
rem <- ifelse(tot$rank == "species", ifelse(code$n_codes[match(tot$taxon, code$taxon)] > 1, sprintf("varieties or subspecies rolled up to the species; NEON code(s) %s", code$codes[match(tot$taxon, code$taxon)]), NA_character_),
              sprintf("identified by NEON only to %s (or fuzzed to it to protect a species of concern); NEON code(s) %s", tot$rank, code$codes[match(tot$taxon, code$taxon)]))
rem[tot$rank == "kingdom"] <- sprintf("NEON's four kingdom-level codes (Unknown plant, Unknown hardwood plant, Unknown softwood plant, Plantae sp.) as one taxon, since none identifies anything below the kingdom; NEON code(s) %s", code$codes[code$rank == "kingdom"])
rem[tot$rank == "speciesGroup"] <- paste0(rem[tot$rank == "speciesGroup"], "; NEON records the pair as one species group, which the GBIF backbone does not hold, so taxonID is empty")
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = tot$rank, exact = FALSE, no_key = nokey, taxonRemarks = rem,
                  taxon_n_records = tot$n_records)
taxa[, kingdom := vapply(seq_len(.N), function(i) if (taxon[i] %in% nokey) NA_character_ else gbif_kingdom(scientificName[i]), "")]
fix <- taxa[!taxon %in% nokey & !(gbifMatchType == "EXACT" & kingdom %in% "Plantae"), taxon]
for (tk in fix) {
  h <- tot[taxon == tk]
  r <- gbif_taxon_hinted(h$name, list(kingdom = "Plantae", family = if (h$rank %in% c("species", "genus")) h$family else NA))
  if (identical(r$canonicalName, h$name) && identical(r$kingdom, "Plantae")) {
    taxa[taxon == tk, `:=`(taxonID = r$taxonID, gbifMatchType = paste0(r$matchType, " (hinted)"), gbifAcceptedName = r$acceptedName)]
  } else {
    taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = r$matchType,
         taxonRemarks = paste0(fifelse(is.na(taxonRemarks), "", paste0(taxonRemarks, "; ")), "no match of this name among plants on the GBIF backbone (with NEON's family as a hint), so taxonID is empty"))]
  }
}
n_fixed <- taxa[taxon %in% fix & !is.na(taxonID), .N]; n_unmatched <- taxa[!taxon %in% nokey & is.na(taxonID), .N]
cat(sprintf("  GBIF: %d taxa re-matched with NEON's family as a hint, %d without a key (plus %d species groups)\n", n_fixed, n_unmatched, length(nokey)))
taxa[, kingdom := NULL]
stopifnot(!any(taxa$taxonID %in% "https://www.gbif.org/species/1"), all(!is.na(taxa$taxonID) | !is.na(taxa$taxonRemarks)))

dataset <- list(
  title = sprintf("NEON plant presence in 1 m2 subplots, RELEASE-2026: detection of %d plant taxa per subplot visit at %d permanent subplots across %d NEON sites, %d-%d, per-site species pools", nrow(tot), nrow(units), uniqueN(units$site), min(periods$year), max(periods$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = sub("^https://doi.org/", "", DOI),
  sourceURL = "https://data.neonscience.org/data-products/DP1.10058.001/RELEASE-2026",
  citation = sprintf("NEON (National Ecological Observatory Network). Plant presence and percent cover (DP1.10058.001), RELEASE-2026. %s. Dataset accessed from https://data.neonscience.org/data-products/DP1.10058.001/RELEASE-2026 on 2026-11-06", DOI),
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's plant diversity survey: in up to 30 distributed and 3 tower plots of 400 m2 per terrestrial site, botanists list every plant species rooted in eight permanent 1 m2 subplots and estimate its percent cover, once a year at peak greenness or twice a year at sites with two peaks; larger nested subplots (10 m2, 100 m2) record only the species new at that scale. This table is the 1 m2 scale, the only one with a complete species list at every visit: y = 1 when NEON lists the taxon in the subplot, 0 otherwise, with its cover. The taxa surveyed for at a subplot are the per-site pool of taxa this table records at its site (median %d; __survey_taxa), so a taxon never found at a site has no zeros there. Plot-centre coordinates are as NEON publishes them.", as.integer(median(pool_n$N))),
  samplingProtocol = "Every vascular plant species rooted in a permanent 1 m2 subplot listed and its percent cover estimated, eight subplots per 400 m2 plot, at peak greenness once a year (twice at sites with two peaks) (NEON TOS plant diversity sampling protocol, NEON.DOC.014042); species of concern fuzzed by NEON to a higher rank",
  samplingProtocolCode = "botanical_survey", surveyEvidence = "sample_table",
  surveyEvidenceNote = "div_1m2Data has rows for every 1 m2 subplot visit (samplingImpractical where it was not sampled, targetTaxaPresent N where no plant was rooted in it); a survey is a subplot x eventID x endDate with samplingImpractical blank or OK and data rows. The zeros rest on a per-site species pool derived from detections (ruling 19): the taxa surveyed for at a subplot are every taxon this table records at the subplot's site at any visit (__survey_taxa), not a list NEON deposited, so a taxon never recorded at a site has no rows there and a taxon recorded once at a site is a zero at every other visit to that site.",
  responseType = "detection", unitKind = "site",
  closure = "open", closureNote = "occasion = visit to the subplot within the calendar year, ordered by bout and date; at the bimodal sites the two bouts are timed to two peaks in greenness and species composition (product design description), so presence may change between them; a few subplots were listed twice within one bout (both kept). Most site-years have one visit; period = calendar year", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON terrestrial sites, continental USA, Alaska, Hawaii and Puerto Rico; plot-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", uniqueN(units$site), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(s$endDate), 1, 7), substr(max(s$endDate), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("As published by NEON (agency-published plot-centre coordinates with coordinateUncertaintyInMeters; NEON fuzzes species of concern to a higher rank rather than the coordinates); subplots carry their plot's centre; %d plots were re-surveyed by a few metres and __units carries the latest", n_moved)),
  covariateNote = "cluster_id = NEON plotID (the 400 m2 plot holding the subplot); unit_site = NEON site; obs_bout = NEON boutNumber (1, or 2 at bimodal sites); obs_percent_cover = the taxon's percent cover in the subplot at the visit, summed over NEON's rows for it (morphospecies, infraspecific taxa), 0 where y = 0, empty where NEON left a cover blank; it varies across taxa within a visit (E5).",
  notes = sprintf("Scale: the 1 m2 subplot (ruling 19), the only NEON plant scale with a complete list per visit; the 10 m2 and 100 m2 records (div_10m2Data100m2Data, %d rows) are not used. Taxa: %d species (varieties and subspecies rolled up) and %d records identified, or fuzzed by NEON, only to a higher rank, or to a species group, each its own taxon (E6); %d names carried several NEON codes and were merged (%d sp./spp. pairs, ruling 20; %d species with infraspecific codes; the four kingdom-level codes as Plantae), taxonRemarks lists the codes. Surveys: %d subplot visits; %d not sampled have no rows; %d visits with only ground-cover rows and no targetTaxaPresent (2013-2016) and %d with both Y and N dropped; %d repeat visits within one bout kept as occasions. Per-site pools: median %d taxa (range %d-%d).", n_big, tot[rank == "species", .N], tot[rank != "species", .N], code[n_codes > 1, .N], n_spspp, n_infra, nrow(s), n_impr, n_na, n_yn, n_rep, as.integer(median(pool_n$N)), min(pool_n$N), max(pool_n$N)),
  notShipped = list(
    `larger nested subplots` = sprintf("div_10m2Data100m2Data (%d rows): species new at the 10 m2, 100 m2 and 400 m2 scales; another scale, whose presence lists are unions over nested subplots that NEON says are not always populated", n_big),
    `unusable visits` = sprintf("%d visits with only ground-cover rows and no targetTaxaPresent (2013-2016); %d with both targetTaxaPresent Y and N", n_na, n_yn),
    `other fields` = "otherVariables rows (ground cover of litter, rock, soil, wood, water), plant heights, vouchers, genetic archive, identification history"))
parts <- as.list(periods$period)
ds <- write_table_parts(parts, build, TABLE, dataset, taxa = taxa, periods = periods[, .(period, year)], units = units,
                        survey_taxa = survey_taxa, script = "data/neon_2026_plants_occ.R")

stage_dict_row(TABLE,
  description = sprintf("Detection of %d plant taxa per visit to %d permanent 1 m2 subplots in 400 m2 plots at %d NEON terrestrial sites, %d-%d (once a year, twice at bimodal sites), with percent cover, built from NEON's plant presence and percent cover records (RELEASE-2026); per-site species pools in __survey_taxa; plot-centre coordinates as published.", nrow(tot), nrow(units), uniqueN(units$site), min(periods$year), max(periods$year)),
  url = "https://data.neonscience.org/data-products/DP1.10058.001/RELEASE-2026",
  reference = sprintf("NEON (National Ecological Observatory Network). Plant presence and percent cover (DP1.10058.001), RELEASE-2026. %s", DOI),
  doi_paper = "", doi_data = sub("^https://doi.org/", "", DOI),
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Token-gated NEON API (NEON_TOKEN); release pinned. 1 m2 scale only; per-site pool from detections (ruling 19); year parts.",
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "botanical_survey", design = sprintf("Multi-season (%d years x 1-2 visits)", nrow(periods)), realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; 1 m2 subplot presence lists; per-site species pools (__survey_taxa).",
  status = "tagged")
