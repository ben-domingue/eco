#!/usr/bin/env Rscript
# Table:  neon_2026_smallmammals_count
# Source: NEON (National Ecological Observatory Network), data product DP1.10072.001 "Small mammal
#         box trapping", RELEASE-2026 (generated 2026-01-23), https://doi.org/10.48443/a83h-tb34,
#         accessed through the NEON Data API (https://data.neonscience.org/api/v0) on 2026-11-02 with
#         an API token (the data endpoints answer 403 without one; tokens are free with a NEON
#         account and are read from the NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, as stated on the NEON Data API documentation page
#         https://data.neonscience.org/data-api/ ("NEON data products and sample data are licensed
#         under a Creative Commons Attribution 4.0 International License (CC-BY)") and in NEON's data
#         citation guidance (https://www.neonscience.org/data-samples/data-policies-citation); the
#         product page itself is rendered by JavaScript and states no licence text.
#         Citation required by NEON: "NEON (National Ecological Observatory Network). Small mammal
#         box trapping (DP1.10072.001), RELEASE-2026. https://doi.org/10.48443/a83h-tb34. Dataset
#         accessed from https://data.neonscience.org/data-products/DP1.10072.001/RELEASE-2026 on
#         2026-11-02".
# Paper:  no single paper; the protocol is NEON.DOC.000481 (TOS Protocol and Procedure: Small Mammal
#         Sampling) and the product's user guide, both linked from the product page.
# Data:   basic download package, one site-month at a time (46 sites, 1,859 site-months, 2013-06 to
#         2024-11 in the release): mam_perplotnight (one row per trapping grid per night: nightuid,
#         eventID = site.year.ISO-week of the bout, plotID, mammalGridSamplingMethod pathogen (three
#         consecutive nights per bout), diversity (one night) or recapture (2014-15, up to three), collectDate, samplingImpractical,
#         gridCompletion) and mam_pertrapnight (one row per trap per night, plus one row per extra
#         capture when a trap held more than one animal: nightuid, plotID, trapCoordinate A1-J10 on
#         the 10 x 10 grid at 10 m spacing, trapStatus 1-6, collectDate, and for captures tagID,
#         taxonID, scientificName, taxonRank, recapture, fate, sex, lifeStage, measurements, samples;
#         plot-level decimalLatitude/Longitude, coordinateUncertainty, elevation, nlcdClass,
#         plotType). The expanded package adds mam_voucher; mam_identificationHistory and the
#         per-individual sample tables are not used.
# Mapping (standard E9 repeated counts, community, responseType count, unitKind site):
#   unit = trapping grid (plotID); cluster_id = NEON site; period = trapping bout, a global integer
#   index over distinct eventIDs ordered by first night then eventID (__periods: eventID, site,
#   year, bout_start, bout_end, n_nights); occasion = night within the bout at that grid (1-6, usually 1 or 3, by
#   date); date = the night's collectDate; y = number of captures of the species at the grid that
#   night (each capture row counts one animal; an animal caught twice in a night is one row per
#   trap-night in the source, so no de-duplication is needed); obs_traps_set = traps on the grid
#   with trapStatus other than "1 - trap not set" that night (effortColumn); obs_grid_method =
#   pathogen / diversity for that night (grids switched method over the years at some sites, so it
#   is an obs_ covariate); unit_* = plot centre coordinates as published by NEON with their
#   uncertainty, elevation, NLCD class, plot type, site, domain.
#   Survey evidence (sample_table): mam_perplotnight. A grid-night is a survey iff its row has
#   samplingImpractical NA or "OK", a non-NA gridCompletion and at least one trap set in
#   mam_pertrapnight (nights recorded as impractical carry 100 "trap not set" rows and are not
#   surveys). Species pool: national (E4's full rectangle, which both validators enforce): every
#   species-rank taxon has a row at every surveyed grid-night, so eastern species are zeros on
#   Alaskan grids. A site-level pool (the species ever captured at that site) would be the
#   ecological truth but fails the gate; __taxa carries taxon_sites so a user can apply it. Ruling
#   requested in BATCH_LOG.md.
#   Taxa: captures identified to species rank (NEON taxonID, four letters; __taxa resolves them in
#   GBIF). Not shipped: captures identified to genus, species group (e.g. PEKEPEMA) or class
#   (counts in notShipped); the per-animal measurements and samples (the companion robust-design
#   table neon_2026_smallmammals_rd carries sex, life stage and weight per capture); mam_voucher,
#   mam_identificationHistory, the DNA and pathogen sample tables.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "neon_2026_smallmammals_count"
PRODUCT <- "DP1.10072.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/a83h-tb34"
SITES <- NULL

x <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("mam_perplotnight", "mam_pertrapnight"), sites = SITES)
stopifnot(identical(attr(x, "productDoi"), DOI), identical(attr(x, "productName"), "Small mammal box trapping"))
pp <- x$mam_perplotnight; pt <- x$mam_pertrapnight
sm <- attr(x, "site_months")
if (is.null(SITES)) stopifnot(nrow(sm) == 1859L, uniqueN(sm$site) == 46L, min(sm$month) == "2013-06", max(sm$month) == "2024-11")

# --- the source as deposited -----------------------------------------------------------------
stopifnot(!anyDuplicated(pp$nightuid), all(pt$nightuid %in% pp$nightuid), !anyNA(pp$eventID), !anyNA(pp$plotID),
          all(grepl("^[A-Z]{4}\\.\\d{4}\\.\\d{1,2}$", pp$eventID)),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}", pp$collectDate)), all(grepl("^\\d{4}-\\d{2}-\\d{2}", pt$collectDate)),
          setequal(na.omit(unique(pp$mammalGridSamplingMethod)), c("pathogen", "diversity", "recapture")),
          all(pt$trapStatus %in% c("1 - trap not set", "2 - trap disturbed/door closed but empty",
                                   "3 - trap door open or closed w/ spoor left", "4 - more than 1 capture in one trap",
                                   "5 - capture", "6 - trap set and empty")),
          all(na.omit(unique(pp$gridCompletion)) %in% paste0(rep(c("setting complete", "setting not complete"), each = 4), ", ",
                                                             c("processing complete", "processing not complete", "no small mammals captured",
                                                               "no targeted or opportunistic small mammals captured"))))
pp[, night_date := substr(collectDate, 1, 10)]; pt[, night_date := substr(collectDate, 1, 10)]
n_date_off <- pt[pp, on = "nightuid", uniqueN(nightuid[night_date != i.night_date])]   # a few plot-nights whose trap rows carry another date
stopifnot(n_date_off <= 5L, pt[pp, on = "nightuid", all(plotID == i.plotID)])
pt[, night_date := NULL]                                                  # the night's date is the plot-night's (mam_perplotnight) date

# --- survey set: grid-nights --------------------------------------------------------------------
cap_status <- c("4 - more than 1 capture in one trap", "5 - capture")
cap_all <- pt[trapStatus %in% cap_status]
n_cap_no_taxon <- cap_all[is.na(taxonID), .N]
stopifnot(n_cap_no_taxon <= 10L, !anyNA(cap_all[!is.na(taxonID), scientificName]), !anyNA(cap_all[!is.na(taxonID), taxonRank]))
pt[, on_grid := grepl("^[A-J]([1-9]|10)$", trapCoordinate)]           # X marks an unknown row or column (a few hundred rows, mostly captures)
set <- pt[on_grid & trapStatus != "1 - trap not set", .(obs_traps_set = uniqueN(trapCoordinate)), by = nightuid]
pp <- merge(pp, set, by = "nightuid", all.x = TRUE)
pp[is.na(obs_traps_set), obs_traps_set := 0L]
imp <- pp[!(is.na(samplingImpractical) | samplingImpractical == "OK")]
stopifnot(all(is.na(imp$gridCompletion)), all(imp$obs_traps_set == 0L))   # impractical nights have no trap set
nights <- pp[(is.na(samplingImpractical) | samplingImpractical == "OK") & !is.na(gridCompletion) & obs_traps_set > 0L]

# three SRER plot-nights are deposited twice (two nightuids, same grid and date, different capture lists):
# one night, the larger trap-set count, the union of capture rows
nights[, nkey := paste(plotID, night_date)]
n_dup_nights <- nights[, .N, by = nkey][N > 1L, .N]
stopifnot(n_dup_nights <= 5L)
setorder(nights, nkey, -obs_traps_set, nightuid)
uid_map <- nights[, .(nightuid, nightuid_keep = nightuid[1]), by = nkey][, .(nightuid, nightuid_keep)]
nights <- nights[!duplicated(nkey)][, nkey := NULL]
pt[uid_map, on = "nightuid", nightuid := i.nightuid_keep]
cap <- pt[trapStatus %in% cap_status & !is.na(taxonID)]
cap <- cap[!duplicated(cap[, .(nightuid, trapCoordinate, tagID, taxonID)])]
stopifnot(all(pt[nightuid %in% nights$nightuid & on_grid, uniqueN(trapCoordinate), by = nightuid]$V1 <= 100L),
          all(cap$nightuid %in% nights$nightuid))                            # every capture is on a surveyed night
cat(sprintf("  %d grid-nights in mam_perplotnight: %d impractical, %d without a trap set, %d surveyed (%d grids, %d sites)\n",
            nrow(pp), nrow(imp), nrow(pp) - nrow(imp) - nrow(nights), nrow(nights), uniqueN(nights$plotID), uniqueN(nights$siteID)))

# bouts: eventID, ordered by first surveyed night; occasion = night within bout at the grid
nights[, year := as.integer(substr(eventID, 6, 9))]
stopifnot(all(nights$year == as.integer(substr(nights$night_date, 1, 4))))
bouts <- nights[, .(site = siteID[1], year = year[1], bout_start = min(night_date), bout_end = max(night_date),
                    n_nights = uniqueN(night_date), n_grids = uniqueN(plotID)), by = eventID]
stopifnot(nights[, uniqueN(siteID), by = eventID][, all(V1 == 1L)])
setorder(bouts, bout_start, eventID)
bouts[, period := seq_len(.N)]
nights <- merge(nights, bouts[, .(eventID, period)], by = "eventID")
setorder(nights, period, plotID, night_date)
nights[, occasion := seq_len(.N), by = .(period, plotID)]
stopifnot(!anyDuplicated(nights[, .(plotID, period, night_date)]), max(nights$occasion) <= 6L,
          all(as.integer(as.IDate(bouts$bout_end) - as.IDate(bouts$bout_start)) <= 11L))   # a grid's nights can split across two windows of one eventID
cat(sprintf("  %d bouts (eventIDs), %d-%d; nights per grid-bout: %s\n", nrow(bouts), min(bouts$year), max(bouts$year),
            paste(names(table(nights[, .N, by = .(period, plotID)]$N)), table(nights[, .N, by = .(period, plotID)]$N), sep = "x", collapse = ", ")))

# --- taxa: species-rank captures, site-level pools --------------------------------------------
cap <- cap[nights[, .(nightuid, period, occasion)], on = "nightuid", nomatch = NULL]
stopifnot(nrow(cap) >= nrow(cap_all) - n_cap_no_taxon - 100L)
rank_n <- cap[, .N, by = taxonRank][order(-N)]
spc <- cap[taxonRank == "species"]
stopifnot(spc[, uniqueN(scientificName), by = taxonID][, all(V1 == 1L)])
species <- spc[, .(scientificName = scientificName[1], n_captures = .N, n_sites = uniqueN(siteID)), by = taxonID][order(-n_captures)]
stopifnot(!anyDuplicated(species$scientificName), all(grepl("^[A-Z]{4}$", species$taxonID)))
site_pool <- unique(spc[, .(siteID, taxonID)])
cat(sprintf("  %s captures: %s; %d species-rank taxa; site-level pools would be %d-%d species (mean %.1f), the table carries the national pool\n",
            format(nrow(cap), big.mark = ","), paste(rank_n$taxonRank, rank_n$N, collapse = ", "),
            nrow(species), min(site_pool[, .N, by = siteID]$N), max(site_pool[, .N, by = siteID]$N), mean(site_pool[, .N, by = siteID]$N)))

# --- long table: grid-night x species (national pool, E4 full rectangle) ------------------------
counts <- spc[, .(y = .N), by = .(nightuid, taxonID)]
long <- CJ(nightuid = nights$nightuid, taxonID = species$taxonID)
long <- merge(long, nights[, .(nightuid, siteID, plotID, period, occasion, night_date, obs_traps_set, mammalGridSamplingMethod)], by = "nightuid")
long <- merge(long, counts, by = c("nightuid", "taxonID"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(nrow(long) == nrow(nights) * nrow(species), sum(long$y) == nrow(spc), !anyDuplicated(long[, .(plotID, taxonID, period, occasion)]))

# plot facts: coordinates as published (NEON publishes its plot centres; modal value where a plot has two)
plots <- pt[nightuid %in% nights$nightuid, .(unit_decimalLatitude = as.numeric(names(which.max(table(decimalLatitude)))),
                                             unit_decimalLongitude = as.numeric(names(which.max(table(decimalLongitude)))),
                                             unit_coordinateUncertaintyInMeters = as.numeric(names(which.max(table(coordinateUncertainty)))),
                                             unit_elevation = as.numeric(names(which.max(table(elevation)))),
                                             unit_nlcdClass = names(which.max(table(nlcdClass))), unit_plotType = names(which.max(table(plotType))),
                                             unit_site = siteID[1], unit_domain = domainID[1],
                                             n_coord = uniqueN(decimalLatitude)), by = plotID]
stopifnot(!anyNA(plots$unit_decimalLatitude), !anyNA(plots$unit_decimalLongitude), all(plots$unit_plotType == "distributed"),
          all(abs(plots$unit_decimalLatitude) <= 72), all(plots$unit_decimalLongitude < -66))
cat(sprintf("  %d grids; %d with more than one published coordinate (modal kept)\n", nrow(plots), sum(plots$n_coord > 1)))

long <- merge(long, plots[, !"n_coord"], by = "plotID")
long <- long[, .(unit = plotID, taxon = taxonID, y = as.integer(y), period, occasion, date = night_date, cluster_id = siteID,
                 unit_site, unit_domain, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters,
                 unit_elevation, unit_nlcdClass, unit_plotType, obs_traps_set = as.integer(obs_traps_set), obs_grid_method = mammalGridSamplingMethod)]
long <- order_eco(long)
stopifnot(!anyNA(long$obs_grid_method), all(long$obs_traps_set >= 1L & long$obs_traps_set <= 100L))
cat(sprintf("  %s rows: %d grids x %d bouts (%d grid-nights) x %d taxa, %s captures\n", format(nrow(long), big.mark = ","),
            uniqueN(long$unit), uniqueN(long$period), nrow(nights), uniqueN(long$taxon), format(sum(long$y), big.mark = ",")))

taxa <- make_taxa(species$taxonID, species$scientificName, taxon_n_captures = species$n_captures, taxon_n_sites = species$n_sites,
                  taxon_sites = site_pool[, paste(sort(siteID), collapse = ";"), by = taxonID][match(species$taxonID, taxonID), V1])
periods <- bouts[, .(period, eventID, site, year, bout_start, bout_end, n_nights, n_grids)]
units <- plots[, .(unit = plotID, site = unit_site, domain = unit_domain, decimalLatitude = unit_decimalLatitude, decimalLongitude = unit_decimalLongitude,
                   coordinateUncertaintyInMeters = unit_coordinateUncertaintyInMeters, elevation = unit_elevation, nlcdClass = unit_nlcdClass,
                   plotType = unit_plotType, n_published_coordinates = n_coord)]
units <- merge(units, nights[, .(n_bouts = uniqueN(period), n_nights = .N, first_night = min(night_date), last_night = max(night_date)), by = .(unit = plotID)], by = "unit")

not_sp <- cap[taxonRank != "species", .N, by = .(taxonRank, taxonID, scientificName)][order(-N)]
dataset <- list(
  title = sprintf("NEON small mammal box trapping, RELEASE-2026: nightly capture counts of %d species on %d trapping grids at %d NEON sites, %d-%d", nrow(species), nrow(plots), uniqueN(long$cluster_id), min(bouts$year), max(bouts$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026",
  doi = sub("https://doi.org/", "", DOI), sourceURL = sprintf("https://data.neonscience.org/data-products/%s/%s", PRODUCT, RELEASE),
  citation = sprintf("NEON (National Ecological Observatory Network). Small mammal box trapping (%s), %s. %s. Dataset accessed from https://data.neonscience.org/data-products/%s/%s on 2026-11-02", PRODUCT, RELEASE, DOI, PRODUCT, RELEASE),
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/",
                            note = "Licence stated on https://data.neonscience.org/data-api/ (NEON data products are CC BY 4.0); attribution per NEON's citation guidance"),
  abstract = sprintf("NEON samples small mammals (nonvolant, nocturnal, 5-500 g) on 10 x 10 grids of Sherman box traps at 10 m spacing, three to eight grids per terrestrial site, in bouts of one night (diversity grids) or three consecutive nights (pathogen grids) timed to the new moon, four to six bouts a year. This table is one row per trapping grid x bout x night x species for the %d species-rank taxa, y = number of captures of the species on the grid that night, obs_traps_set = traps set, with every species carried as a zero on every surveyed grid-night (national pool; the sites where each species was captured are listed in __taxa). Built from the RELEASE-2026 basic package through the NEON API: %s grid-nights, %s bouts, %s captures.", nrow(species), format(nrow(nights), big.mark = ","), format(nrow(bouts), big.mark = ","), format(nrow(spc), big.mark = ",")),
  samplingProtocol = "Sherman box traps (LFA/XLK) on 10 x 10 grids at 10 m spacing, set in the evening and checked at dawn; bouts within 10 days of the new moon, 1 night (diversity grids) or 3 consecutive nights (pathogen grids); captured animals identified, ear-tagged (or PIT-tagged) and measured; NEON protocol NEON.DOC.000481",
  samplingProtocolCode = "live_trap", occasionLength = "one trap-night", effortColumn = "obs_traps_set",
  surveyEvidence = "sample_table",
  surveyEvidenceNote = "mam_perplotnight: a grid-night is a survey iff samplingImpractical is NA or OK, gridCompletion is recorded, and at least one trap was set (mam_pertrapnight trapStatus other than '1 - trap not set'); impractical nights are deposited with 100 'trap not set' rows and are dropped. Species pool is national (E4 full rectangle): every species-rank taxon has a row at every surveyed grid-night, so a species outside its range at a site is a structural zero there; taxon_sites in __taxa lists the sites where each species was captured.",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "period = trapping bout (eventID, 1-6 nights per grid, usually 1 or 3, within at most 12 days); occasion = night within the bout at the grid; population open between bouts (robust design)", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON terrestrial sites in the contiguous United States and Alaska (no Hawaii or Puerto Rico); plot centres latitude %.2f to %.2f, longitude %.2f to %.2f, as published by NEON", uniqueN(long$cluster_id), min(plots$unit_decimalLatitude), max(plots$unit_decimalLatitude), min(plots$unit_decimalLongitude), max(plots$unit_decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", min(nights$night_date), max(nights$night_date)),
  crs = "EPSG:4326 (WGS 84, as published)",
  coordinatesCoarsened = list(value = FALSE, method = "As published by NEON: agency-published plot centres with coordinateUncertainty (the E7 agency exception). The Florida mouse Podomys floridanus (IUCN VU) is among the shipped taxa; NEON publishes these plot coordinates itself, and its own obfuscation of listed taxa (D01 state-listed species to higher rank, per the product issue log) is applied upstream"),
  covariateNote = "obs_grid_method is the grid's sampling method that bout (pathogen = 3 nights with blood/ear/hair samples, diversity = 1 night); grids changed method across years at some sites. unit_* are NEON's plot attributes; a few grids carry two published coordinates across the years (modal kept, n_published_coordinates in __units).",
  designNote = "Repeated counts within closed bouts (N-mixture per bout) and an open population across bouts (robust-design counts). The companion table neon_2026_smallmammals_rd carries the individual capture histories (same __periods).",
  components = list(sibling = "neon_2026_smallmammals_rd (same deposit, same bouts and __periods; individual robust-design histories)"),
  notes = "Species pool is national (see surveyEvidenceNote); a community model should restrict each site to the species that can occur there (taxon_sites in __taxa gives the sites with at least one capture) rather than read the out-of-range zeros as surveyed absences. taxon is NEON's four-letter taxonID. Captures identified above species rank are not shipped and their counts are not in y.",
  notShipped = list(
    `captures not at species rank` = paste0(not_sp$scientificName, " (", not_sp$taxonID, ", ", not_sp$taxonRank, ": ", not_sp$N, ")", collapse = "; "),
    `captures without a taxon` = sprintf("%d capture rows with no taxonID", n_cap_no_taxon),
    `per-capture attributes` = "sex, lifeStage, weight, hindfootLength, earLength, tailLength, totalLength, ticks, samples (in the _rd sibling where per individual)",
    `other NEON tables` = "mam_voucher (expanded package), mam_identificationHistory, mam_voucherIdentificationHistory",
    `impractical grid-nights` = sprintf("%d plot-nights with samplingImpractical set (no traps set)", nrow(imp)),
    `duplicate plot-nights` = sprintf("%d grid-nights deposited under two nightuids (merged: union of captures, larger trap count)", n_dup_nights),
    `trap-night dates` = sprintf("%d plot-nights whose mam_pertrapnight rows carry a collectDate other than the plot-night's (the plot-night date is used)", n_date_off)))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/neon_2026_smallmammals_count.R")

stage_dict_row(TABLE,
  description = sprintf("Nightly capture counts of %d small mammal species on %d NEON Sherman-trap grids (10 x 10, 10 m) at %d sites across the United States, %d-%d, in %d bouts of 1-3 nights (robust-design counts: bout = period, night = occasion), with traps set per night as effort and NEON plot coordinates as published; national species pool, sites per species in __taxa.", nrow(species), nrow(plots), uniqueN(long$cluster_id), min(bouts$year), max(bouts$year), nrow(bouts)),
  url = sprintf("https://data.neonscience.org/data-products/%s/%s", PRODUCT, RELEASE),
  reference = sprintf("NEON (National Ecological Observatory Network). Small mammal box trapping (%s), %s. %s", PRODUCT, RELEASE, DOI),
  doi_paper = "", doi_data = sub("https://doi.org/", "", DOI),
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "First NEON table; built through the token-gated NEON API (download_neon in lib). National species pool (E4 rectangle); taxon_sites in __taxa. Captures above species rank (genus, species group) not shipped. Sibling: neon_2026_smallmammals_rd.",
  source_via = "NEON Data API (RELEASE-2026 basic package)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture / robust-design counts (community)",
  sampling_protocol = "live_trap", design = sprintf("Robust design (%d bouts x 1-3 trap-nights)", nrow(bouts)), realm = "Terrestrial",
  country = "USA", coordinates = "As published (NEON plot centres, agency-published; Podomys floridanus VU among the taxa)",
  notes = "National scheme; national species pool (out-of-range zeros are structural); obs_traps_set effort; grids changed method (1 vs 3 nights) over time.", status = "tagged")
