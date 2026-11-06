#!/usr/bin/env Rscript
# Table:  neon_2026_ticks_count
# Source: NEON (National Ecological Observatory Network). Ticks sampled using drag cloths
#         (DP1.10093.001), RELEASE-2026. https://doi.org/10.48443/5e20-3763. Dataset accessed from
#         https://data.neonscience.org/data-products/DP1.10093.001/RELEASE-2026 on 2026-11-05 through
#         the NEON Data API (token-gated; NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data products
#         and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.014045 (TOS Protocol and Procedure: Tick and
#         Tick-Borne Pathogen Sampling) and the product user guide, linked from the product page.
# Data:   basic package, all 46 sites and 2,316 site-months of the release (2014-2024):
#         tck_fielddata: one row per plot per bout (six distributed plots per site, eventID =
#           SITE.YEAR.week), with samplingImpractical (a bout or plot not sampled has a row with the
#           reason and no sample), samplingMethod drag / flag / drag and flag, totalSampledArea (m2,
#           ~160 m2 of the plot perimeter), targetTaxaPresent Y/N, sampleID, sampleCondition, field
#           adult/nymph/larva counts (until 2018), plot-centre coordinates as published.
#         tck_taxonomyProcessed: the taxonomy laboratory's counts per sample x taxon x sexOrAge
#           (Male, Female, Adult, Nymph, Larva), synonymies resolved (acceptedTaxonID), taxonRank;
#           larvae are mostly identified only to family (Ixodidae); a row with no taxon and no count
#           records that the vial held no tick ("Not a tick", "insects!", "empty vial").
#         The readme's issue log: between 2013 and 2019 the laboratory's counts were possibly
#           incomplete (unreported subsampling to meet invoice limits; >500 larvae subsampled to 500 in
#           2016-2018), flagged only where field and lab counts differ by > 25%. From 2019 field teams
#           no longer count, and the laboratory counts every tick received by life stage, including
#           ticks it does not identify.
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture; responseType count):
#   Collections from 2019-01-01 only (the laboratory counts before 2019 may be subsamples of unknown
#   fraction, so they are not counts of the drag; not shipped).
#   unit = plot (plotID); unit_site; period = calendar year (__periods); occasion = bout index within
#   the site-year, ordered by the bout's first collection date; date = collectDate as published (UTC);
#   y = number of ticks of the taxon in the plot's sample; taxon = species x life stage (E6's life-stage
#   exception: NEON records adults, nymphs and larvae separately in one sample), with Male, Female and
#   Adult pooled as adult; lifeStage in __taxa. obs_area_m2 = totalSampledArea (effortColumn);
#   obs_method = drag / flag / drag and flag. __units: site, domain, plot, plot type, NLCD class,
#   plot-centre coordinates as published, uncertainty, elevation.
#   Survey evidence = sample_table: tck_fielddata lists every plot-bout; a survey is a row with
#   samplingImpractical OK or blank and a sampled area; targetTaxaPresent = N is y = 0 for every taxon;
#   a Y sample's counts are its tck_taxonomyProcessed rows. Taxon pool national (every taxon at every
#   survey, as neon_2026_carabids_count).
#   Not shipped: collections before 2019; samples NEON marks lost, incomplete or with an estimated count;
#   Y samples with no laboratory rows; the second collection of a plot within one bout (the first is
#   kept, as in the carabid table); field counts; the pathogen and archive tables.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_ticks_count"
PRODUCT <- "DP1.10093.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/5e20-3763"
FROM    <- "2019-01-01"
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("tck_fielddata", "tck_taxonomyProcessed"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 2316L, identical(attr(nx, "productDoi"), DOI))
fd <- nx$tck_fielddata; tx <- nx$tck_taxonomyProcessed
cat(sprintf("  tck_fielddata %d, tck_taxonomyProcessed %d rows\n", nrow(fd), nrow(tx)))

# --- the source as deposited --------------------------------------------------------------------
IMPR <- c("OK", "location flooded", "location snow covered", "location wet", "logistical", "management", "other",
          "temperature low", "too windy")
stopifnot(uniqueN(fd$siteID) == 46L, all(is.na(fd$samplingImpractical) | fd$samplingImpractical %in% IMPR),
          !anyDuplicated(na.omit(fd$sampleID)), all(tx$sampleID %in% fd$sampleID),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", fd$collectDate)),
          all(grepl("^[A-Z]{4}\\.\\d{4}\\.\\d{1,2}$", fd$eventID)),
          # targetTaxaPresent is blank exactly on the rows recording a plot not sampled, but for one
          # SERC 2022 row marked "location wet" that carries a sample (not a survey here: impractical)
          sum(is.na(fd$targetTaxaPresent) != (!is.na(fd$samplingImpractical) & fd$samplingImpractical != "OK")) == 1L,
          all(!is.na(fd$targetTaxaPresent) | (!is.na(fd$samplingImpractical) & fd$samplingImpractical != "OK")),
          all(tx$sexOrAge %in% c("Male", "Female", "Adult", "Nymph", "Larva", NA)),
          identical(is.na(tx$sexOrAge), is.na(tx$acceptedTaxonID)), all(grepl("^(not a tick!?|insects!|empty vial)$", tx$remarks[is.na(tx$acceptedTaxonID)], ignore.case = TRUE)),
          all(is.na(tx$individualCount[is.na(tx$acceptedTaxonID)])))
fd[, day := substr(collectDate, 1, 10)][, year := as.integer(substr(day, 1, 4))]

# --- surveys -------------------------------------------------------------------------------------------
sv <- fd[day >= FROM & (is.na(samplingImpractical) | samplingImpractical == "OK") & !is.na(totalSampledArea)]
stopifnot(all(sv$targetTaxaPresent %in% c("Y", "N")), all(!is.na(sv$sampleID) | sv$targetTaxaPresent == "N"),
          all(as.numeric(sv$totalSampledArea) > 0), all(sv$samplingMethod %in% c("drag", "flag", "drag and flag")))
n_pre <- fd[day < FROM & (is.na(samplingImpractical) | samplingImpractical == "OK") & !is.na(totalSampledArea), .N]
n_impr <- fd[day >= FROM & !is.na(samplingImpractical) & samplingImpractical != "OK", .N]
BAD_COND <- c("Entire sample lost", "Tick count estimated (error and instar specified in remarks)",
              "Sample incomplete by < 10% (described in remarks)", "Sample incomplete by > 10% (described in remarks)")
n_cond <- sv[sampleCondition %in% BAD_COND, .N]
lab_ids <- unique(tx$sampleID)
n_nolab <- sv[targetTaxaPresent == "Y" & !sampleID %in% lab_ids, .N]
# an N sample sent to the laboratory has no tick rows there
stopifnot(!any(sv[targetTaxaPresent == "N" & !is.na(sampleID), sampleID] %in% tx[!is.na(acceptedTaxonID), sampleID]))
sv <- sv[!sampleCondition %in% BAD_COND | is.na(sampleCondition)]
sv <- sv[targetTaxaPresent == "N" | sampleID %in% lab_ids]
setorder(sv, plotID, eventID, collectDate)
n_dup <- sum(duplicated(sv, by = c("plotID", "eventID")))
sv <- sv[!duplicated(sv, by = c("plotID", "eventID"))]
cat(sprintf("  from %s: %d surveys kept; %d plot-bouts not sampled; %d samples lost / incomplete / estimated, %d Y samples with no laboratory rows, %d repeat collections of a plot in one bout dropped; %d surveys before %s not shipped\n",
            FROM, nrow(sv), n_impr, n_cond, n_nolab, n_dup, n_pre, FROM))
stopifnot(n_dup == 7L, n_nolab == 11L, n_cond == 13L)
bouts <- sv[, .(first = min(day)), by = .(siteID, year, eventID)]
setorder(bouts, siteID, year, first, eventID)
bouts[, occasion := seq_len(.N), by = .(siteID, year)]
sv <- merge(sv, bouts[, .(eventID, occasion)], by = "eventID")
stopifnot(!anyDuplicated(sv[, .(plotID, year, occasion)]))
for (cc in c("siteID", "domainID", "plotType", "nlcdClass"))
  stopifnot(sv[, uniqueN(get(cc)), by = plotID][, all(V1 == 1)])
# NEON re-surveyed a few plot centres (shifts of a few metres); __units keeps the latest
n_moved <- sv[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = plotID][V1 > 1, .N]
stopifnot(n_moved == 5L)

# --- counts per sample x species x life stage -------------------------------------------------------------
lab <- tx[sampleID %in% sv$sampleID & !is.na(acceptedTaxonID)]
stopifnot(!anyNA(lab$individualCount), all(as.integer(lab$individualCount) >= 1), all(lab$taxonRank %in% c("species", "genus", "family")))
lab[, stage := c(Male = "adult", Female = "adult", Adult = "adult", Nymph = "nymph", Larva = "larva")[sexOrAge]]
lab[, name := fifelse(taxonRank == "species", scientificName, sub(" spp?\\.$", "", scientificName))]
stopifnot(!any(grepl(" ", lab[taxonRank != "species", name])), lab[, uniqueN(taxonRank), by = name][, all(V1 == 1)])
# one code per name: the most frequent NEON accepted code (NEON gives 'sp.' and 'spp.' their own codes)
code <- lab[, .N, by = .(name, taxonRank, acceptedTaxonID)][order(-N)][, .(code = acceptedTaxonID[1], codes = paste(sort(unique(acceptedTaxonID)), collapse = "/")), by = .(name, taxonRank)]
stopifnot(!anyDuplicated(code$code))
lab <- merge(lab, code[, .(name, code)], by = "name")
lab[, taxon := paste(code, toupper(substr(stage, 1, 1)), sep = "_")]
counts <- lab[, .(y = sum(as.integer(individualCount))), by = .(sampleID, taxon)]
tot <- lab[, .(n_ticks = sum(as.integer(individualCount)), n_samples = uniqueN(sampleID)), by = .(taxon, code, name, taxonRank, stage)][order(-n_ticks)]
cat(sprintf("  %d species x stage taxa (%d names); %d ticks in %d positive samples\n", nrow(tot), uniqueN(tot$name), sum(tot$n_ticks), uniqueN(counts$sampleID)))

# --- long table ---------------------------------------------------------------------------------------------
periods <- data.table(year = sort(unique(sv$year)))[, period := seq_len(.N)]
sv <- merge(sv, periods, by = "year")
units <- unique(sv[order(plotID, -as.numeric(as.Date(day)))][, .(unit = plotID, site = siteID, domain = domainID, plot_type = plotType, nlcd_class = nlcdClass,
                       named_location = namedLocation, decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                       coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "unit")
stopifnot(nrow(units) == uniqueN(sv$plotID))
base <- sv[, .(unit = plotID, period, occasion, date = collectDate, unit_site = siteID,
               obs_area_m2 = as.numeric(totalSampledArea), obs_method = samplingMethod, sampleID)]
long <- base[rep(seq_len(.N), each = nrow(tot))][, taxon := rep(tot$taxon, times = nrow(base))]
long <- merge(long, counts, by = c("sampleID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, sampleID := NULL]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == nrow(sv) * nrow(tot), sum(long$y) == sum(tot$n_ticks), !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
n_round <- long[y >= 1000 & y %% 1000 == 0, .N]; n_big <- long[y >= 1000, .N]
cat(sprintf("  %d counts >= 1000 (all %s), %d of them whole thousands\n", n_big, paste(unique(long[y >= 1000, taxon]), collapse = ", "), n_round))
cat(sprintf("  %d surveys at %d plots, %d sites, %d years; %d rows\n", nrow(sv), uniqueN(sv$plotID), uniqueN(sv$siteID), nrow(periods), nrow(long)))

higher <- tot[taxonRank != "species", taxon]
taxa <- make_taxa(tot$taxon, tot$name, taxonRank = tot$taxonRank, allow_higher = higher,
                  lifeStage = tot$stage,
                  taxonRemarks = ifelse(tot$taxonRank == "species", NA_character_,
                    sprintf("identified by the NEON taxonomy laboratory only to %s; NEON code(s) %s", tot$taxonRank, code$codes[match(tot$code, code$code)])),
                  taxon_n_ticks = tot$n_ticks)
periods <- periods[, .(period, year)]
dataset <- list(
  title = sprintf("NEON ticks from drag and flag sampling, RELEASE-2026: ticks of %d species x life-stage taxa per plot-bout at %d plots across %d NEON sites, %d-%d", nrow(tot), uniqueN(sv$plotID), uniqueN(sv$siteID), min(sv$year), max(sv$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/5e20-3763",
  sourceURL = "https://data.neonscience.org/data-products/DP1.10093.001/RELEASE-2026",
  citation = "NEON (National Ecological Observatory Network). Ticks sampled using drag cloths (DP1.10093.001), RELEASE-2026. https://doi.org/10.48443/5e20-3763. Dataset accessed from https://data.neonscience.org/data-products/DP1.10093.001/RELEASE-2026 on 2026-11-05",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's tick survey: a 1 m2 drag cloth (or a flag where vegetation prevents dragging) is pulled along the ~160 m perimeter of six distributed plots per terrestrial site, every three weeks through the growing season at sites with ticks and every six weeks elsewhere; every tick collected is counted by life stage and identified by a taxonomy laboratory (larvae mostly only to family). This table is the number of ticks of each species x life stage per plot-bout from 2019, when the laboratory began counting every tick received; every taxon has a row at every survey (%d taxa). Plot-centre coordinates are as NEON publishes them.", nrow(tot)),
  samplingProtocol = "Drag sampling (1 m2 cloth pulled along the 160 m perimeter of a 40 x 40 m plot, checked every 5 m) or flagging where dragging is impossible; ticks removed into ethanol and sent to a taxonomy laboratory for life-stage counts and identification (NEON TOS tick and tick-borne pathogen sampling protocol)",
  samplingProtocolCode = "drag_sampling", surveyEvidence = "sample_table",
  surveyEvidenceNote = "tck_fielddata lists every plot-bout (with samplingImpractical where a plot was not sampled); a survey is a row with samplingImpractical OK or blank and a sampled area. targetTaxaPresent = N is y = 0 for every taxon; a Y sample's counts are its tck_taxonomyProcessed rows. Taxon pool national.",
  responseType = "count", unitKind = "site", effortColumn = "obs_area_m2",
  closure = "open", closureNote = "occasion = bout (every three or six weeks through the growing season), indexed within the site-year by first collection date; tick life stages quest in different seasons, so the counts are not closed across occasions; period = calendar year", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON terrestrial sites, continental USA, Alaska, Hawaii and Puerto Rico; plot-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", uniqueN(sv$siteID), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(sv$day), 1, 7), substr(max(sv$day), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("As published by NEON (agency-published plot-centre coordinates with coordinateUncertaintyInMeters); no coarsening; %d plots were re-surveyed by a few metres and __units carries the latest", n_moved)),
  covariateNote = "obs_area_m2 = area dragged or flagged (m2; effort); obs_method = drag, flag or drag and flag. Plot-level facts (site, domain, plot type, NLCD class, NEON namedLocation, plot-centre coordinates, uncertainty, elevation) are in __units.",
  notes = sprintf("Taxa: species x life stage (adult = Male + Female + Adult; nymph; larva), lifeStage in __taxa; records identified only to genus or family (most larvae: Ixodidae) are their own taxa (E6), NEON's 'sp.' and 'spp.' codes of one name merged. From %s only: before 2019 the laboratory's counts may be subsamples (NEON issue log), %d earlier surveys not shipped. Surveys dropped: %d samples NEON marks lost, incomplete or with an estimated count; %d targetTaxaPresent = Y samples with no laboratory rows; %d repeat collections of a plot within one bout (first kept). Very large larval counts: %d rows have y >= 1000 and %d of them are whole thousands (10000, 20000, 35000), which look like the laboratory's estimates for larval clumps; NEON publishes them as individualCount without a flag, and they are shipped as published. Laboratory rows with no taxon (remarks 'Not a tick', 'insects!', 'empty vial') contribute nothing.", FROM, n_pre, n_cond, n_nolab, n_dup, n_big, n_round),
  notShipped = list(
    `collections before 2019` = sprintf("%d surveys, 2014-2018: the laboratory counts of that period may be unreported subsamples (invoice limits; >500 larvae subsampled to 500 in 2016-2018), so y would not be the count in the drag", n_pre),
    `unusable samples` = sprintf("%d samples marked Entire sample lost, Sample incomplete or Tick count estimated; %d Y samples with no laboratory rows; %d repeat collections of a plot within one bout", n_cond, n_nolab, n_dup),
    `field counts` = "tck_fielddata adultCount / nymphCount / larvaCount (field counts, discontinued in 2019; the laboratory counts are y)",
    `other tables` = "tck_taxonomyRaw (pre-synonymy names), tck_identificationHistory, pathogen and archive tables"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/neon_2026_ticks_count.R")

stage_dict_row(TABLE,
  description = sprintf("Number of ticks of %d species x life-stage taxa per drag or flag sample (~160 m2 per plot, every three or six weeks through the growing season) at %d plots on %d NEON terrestrial sites, %d-%d, built from NEON's taxonomy-laboratory counts (RELEASE-2026), with area sampled, method and plot-centre coordinates as published.", nrow(tot), uniqueN(sv$plotID), uniqueN(sv$siteID), min(sv$year), max(sv$year)),
  url = "https://data.neonscience.org/data-products/DP1.10093.001/RELEASE-2026",
  reference = "NEON (National Ecological Observatory Network). Ticks sampled using drag cloths (DP1.10093.001), RELEASE-2026. https://doi.org/10.48443/5e20-3763",
  doi_paper = "", doi_data = "10.48443/5e20-3763",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Token-gated NEON API (NEON_TOKEN); release pinned. 2019 onward only (earlier lab counts may be subsamples); species x life stage taxa; national pool.",
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "drag_sampling", design = sprintf("Multi-season (%d years x up to %d bouts)", nrow(periods), max(sv$occasion)), realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; tick counts per plot-bout by species and life stage; every taxon at every survey.",
  status = "tagged")
