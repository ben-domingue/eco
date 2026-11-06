#!/usr/bin/env Rscript
# Table:  neon_2026_mosquitoes_count
# Source: NEON (National Ecological Observatory Network). Mosquitoes sampled from CO2 traps
#         (DP1.10043.001), RELEASE-2026. https://doi.org/10.48443/rmw1-me46. Dataset accessed from
#         https://data.neonscience.org/data-products/DP1.10043.001/RELEASE-2026 on 2026-11-05 through
#         the NEON Data API (token-gated; NEON_TOKEN environment variable, see lib/eco_common.R).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data products
#         and sample data are licensed under a Creative Commons Attribution 4.0 International License
#         (CC-BY)"); the product page itself is rendered by JavaScript. NEON is funded by the U.S.
#         National Science Foundation and operated by Battelle.
# Paper:  no single paper; the protocol is NEON.DOC.014049 (TOS Protocol and Procedure: Mosquito
#         Sampling) and the product user guide, linked from the product page.
# Data:   basic package, all 47 sites and 3,824 site-months of the release (2014-2024):
#         mos_trapping: one row per trap collection (plotID, setDate, collectDate, trapHours,
#           nightOrDay, eventID, samplingImpractical, targetTaxaPresent Y / N / U, sampleID (only
#           when a sample was kept), sampleCondition, fan / catch cup / CO2 status, trapType dry ice
#           or CO2 canister, plot-centre coordinates as published). A collection with no mosquitoes
#           (targetTaxaPresent N) keeps no sample; a plot not trapped has a row with the reason and
#           no sample.
#         mos_sorting: one row per kept sample (subsampleID, proportionIdentified = share of the
#           sample, by wet weight, that went to the taxonomist; sampleCondition).
#         mos_expertTaxonomistIDProcessed: the taxonomist's counts per subsample x taxon x sex
#           (individualCount, taxonID, taxonRank, sex F / M / U); a subsample with no mosquitoes has
#           one row with targetTaxaPresent N.
#         The readme: the taxonomist identifies "a representative subsample"; proportionIdentified
#           "can be used to estimate the total number of mosquitoes in a sample". Two nights and one
#           day of trapping per bout until 2017, one night (about 24 hours) from 2018.
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture; responseType count):
#   unit = plot (one CO2 light trap per plot, about ten plots per site); unit_site; period = calendar
#   year (__periods); occasion = trap collection within the plot-year, ordered by setDate; date =
#   setDate as published (UTC); y = mosquitoes of the taxon counted in the identified subsample, all
#   sexes pooled (a count of identified individuals, not an estimate of the trap's catch: the
#   estimate y / proportionIdentified is not shipped); obs_proportion_identified (NA where the trap
#   held no mosquitoes and no sample was kept), named by subsampleColumn (E10, ruling 21, 2026-11-06); obs_trap_hours (effortColumn); obs_night_or_day,
#   obs_trap_type, obs_fan_status, obs_co2_status, obs_cup_status, obs_sample_timing (field season
#   / off season) as published. __units: site, domain, plot type, NLCD class, plot-centre
#   coordinates as published (latest where NEON re-surveyed a plot), uncertainty, elevation.
#   Survey evidence = sample_table: mos_trapping lists every trap collection; a survey is a row with
#   samplingImpractical OK or blank, targetTaxaPresent Y or N, and trapHours > 0. N is y = 0 for
#   every taxon; a Y sample's counts are its taxonomist rows. Taxon pool national, cut to taxa with
#   >= MIN_N identified individuals in the release (as neon_2026_carabids_count); the table is
#   written as year parts (E4, > 5M rows).
#   Not shipped: collections with targetTaxaPresent U, Y collections with no sorting or no
#   taxonomist rows, samples NEON marks damaged, handled in error or incomplete (trap or sorting
#   record), trapHours = 0, N records that kept a sample anyway (contradictory); the second record of a plot with two collections set at the same time;
#   exact duplicate taxonomist rows (counted once); collections whose taxonomist rows give two
#   different counts for one taxon x sex (additive or an entry error is not knowable); taxa below the cut; the pathogen, barcoding and
#   archive tables.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_mosquitoes_count"
PRODUCT <- "DP1.10043.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/rmw1-me46"
MIN_N   <- 1000L
nx <- download_neon(PRODUCT, TABLE, RELEASE, tables = c("mos_trapping", "mos_sorting", "mos_expertTaxonomistIDProcessed"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 3824L, identical(attr(nx, "productDoi"), DOI))
tr <- nx$mos_trapping; so <- nx$mos_sorting; id <- nx$mos_expertTaxonomistIDProcessed
rm(nx); invisible(gc(FALSE))
cat(sprintf("  mos_trapping %d, mos_sorting %d, mos_expertTaxonomistIDProcessed %d rows\n", nrow(tr), nrow(so), nrow(id)))

# --- the source as deposited --------------------------------------------------------------------
IMPR <- c("OK", "extreme weather", "location flooded", "location snow covered", "logistical", "management", "other", "temperature low")
BAD  <- c("Damaged, analysis affected", "Handling error", "Sample incomplete")
stopifnot(uniqueN(tr$siteID) == 47L, all(is.na(tr$samplingImpractical) | tr$samplingImpractical %in% IMPR),
          !anyDuplicated(na.omit(tr$sampleID)), !anyDuplicated(so$sampleID), !anyDuplicated(so$subsampleID),
          all(so$sampleID %in% tr$sampleID), all(id$subsampleID %in% so$subsampleID),
          all(tr$targetTaxaPresent %in% c("Y", "N", "U", NA)),
          # a kept sample exactly where mosquitoes were present or uncertain, but for 8 N records with a sample
          all(!is.na(tr$sampleID[tr$targetTaxaPresent %in% c("Y", "U")])), sum(!is.na(tr$sampleID[tr$targetTaxaPresent %in% "N"])) == 8L,
          all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}Z$", tr$setDate[!is.na(tr$targetTaxaPresent)])),
          all(id$targetTaxaPresent %in% c("Y", "N")), all(id$targetTaxaPresent[is.na(id$taxonID)] == "N"),
          # one BART 2022 row says N but carries a taxon and a count; the taxon row is used
          sum(id$targetTaxaPresent == "N" & !is.na(id$taxonID)) == 1L,
          all(id$sex[!is.na(id$taxonID)] %in% c("F", "M", "U")), !anyNA(id$individualCount[!is.na(id$taxonID)]),
          !anyNA(so$proportionIdentified), all(as.numeric(so$proportionIdentified) > 0 & as.numeric(so$proportionIdentified) <= 1))

# --- surveys ---------------------------------------------------------------------------------------------
sv <- tr[(is.na(samplingImpractical) | samplingImpractical == "OK") & targetTaxaPresent %in% c("Y", "N")]
n_u <- tr[(is.na(samplingImpractical) | samplingImpractical == "OK") & targetTaxaPresent == "U", .N]
n_impr <- tr[!is.na(samplingImpractical) & samplingImpractical != "OK", .N]
n_nsamp <- sv[targetTaxaPresent == "N" & !is.na(sampleID), .N]          # N with a kept sample: contradictory, dropped
sv <- sv[!(targetTaxaPresent == "N" & !is.na(sampleID))]
stopifnot(!anyNA(sv$trapHours))
n_h0 <- sv[as.numeric(trapHours) <= 0, .N]
sv <- sv[as.numeric(trapHours) > 0]
so_bad <- so[sampleCondition %in% BAD, sampleID]
n_bad <- sv[sampleCondition %in% BAD | sampleID %in% so_bad, .N]
sv <- sv[!(sampleCondition %in% BAD) & !(sampleID %in% so_bad)]
so_ok <- so[sampleID %in% sv$sampleID]
n_noso <- sv[targetTaxaPresent == "Y" & !sampleID %in% so_ok$sampleID, .N]
n_noid <- so_ok[!subsampleID %in% id$subsampleID, .N]
sv <- sv[targetTaxaPresent == "N" | sampleID %in% so_ok[subsampleID %in% id$subsampleID, sampleID]]
setorder(sv, plotID, setDate, collectDate)
n_dup <- sum(duplicated(sv, by = c("plotID", "setDate")))
sv <- sv[!duplicated(sv, by = c("plotID", "setDate"))]
cat(sprintf("  %d surveys; dropped: %d not trapped, %d targetTaxaPresent U, %d trapHours = 0, %d damaged / handling error / incomplete, %d Y with no sorting, %d sorted with no taxonomist rows, %d repeat records of one set, %d N with a kept sample\n",
            nrow(sv), n_impr, n_u, n_h0, n_bad, n_noso, n_noid, n_dup, n_nsamp))
stopifnot(n_u == 1665L, n_noso == 209L, n_dup == 12L, n_bad == 592L)
sv[, year := as.integer(substr(setDate, 1, 4))]
setorder(sv, plotID, year, setDate)
sv[, occasion := seq_len(.N), by = .(plotID, year)]
for (cc in c("siteID", "domainID", "plotType", "nlcdClass"))
  stopifnot(sv[, uniqueN(get(cc)), by = plotID][, all(V1 == 1)])
n_moved <- sv[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = plotID][V1 > 1, .N]

# --- counts per sample x taxon ------------------------------------------------------------------------------
sv <- merge(sv, so_ok[, .(sampleID, subsampleID, prop = as.numeric(proportionIdentified))], by = "sampleID", all.x = TRUE)
stopifnot(identical(is.na(sv$subsampleID), sv$targetTaxaPresent == "N"))
lab <- id[subsampleID %in% sv$subsampleID & !is.na(taxonID)]
n_iddup <- sum(duplicated(lab, by = c("subsampleID", "taxonID", "sex", "individualCount")))
lab <- lab[!duplicated(lab, by = c("subsampleID", "taxonID", "sex", "individualCount"))]
# two rows of one subsample x taxon x sex with different counts: additive or an entry error is not
# knowable, so the collection is dropped
conf <- unique(lab[duplicated(lab, by = c("subsampleID", "taxonID", "sex")), subsampleID])
n_conf <- length(conf); stopifnot(n_conf == 24L)
sv <- sv[!subsampleID %in% conf | is.na(subsampleID)]; lab <- lab[!subsampleID %in% conf]
setorder(sv, plotID, year, setDate); sv[, occasion := seq_len(.N), by = .(plotID, year)]
stopifnot(!anyDuplicated(lab[, .(subsampleID, taxonID, sex)]), all(lab$taxonRank %in% c("species", "subspecies", "genus", "family")),
          all(as.integer(lab$individualCount) >= 0))
n_zero_rows <- lab[as.integer(individualCount) == 0, .N]          # a taxon row with count 0 adds nothing
cat(sprintf("  %d taxonomist rows with individualCount 0\n", n_zero_rows))
lab[, name := fifelse(taxonRank %in% c("species", "subspecies"), sub("^(\\S+ \\S+).*$", "\\1", scientificName), sub(" spp?\\.$", "", scientificName))]
lab[taxonRank == "subspecies", taxonRank := "species"]
stopifnot(!any(grepl(" ", lab[taxonRank != "species", name])), lab[, uniqueN(taxonRank), by = name][, all(V1 == 1)])
code <- lab[, .N, by = .(name, taxonRank, taxonID)][order(-N)][, .(taxon = taxonID[1], codes = paste(sort(unique(taxonID)), collapse = "/")), by = .(name, taxonRank)]
stopifnot(!anyDuplicated(code$taxon))
lab <- merge(lab, code[, .(name, taxon)], by = "name")
tot <- lab[, .(n_ind = sum(as.integer(individualCount)), n_samples = uniqueN(subsampleID)), by = .(taxon, name, taxonRank)][order(-n_ind)]
keep <- tot[n_ind >= MIN_N]; below <- tot[n_ind < MIN_N]
counts <- lab[taxon %in% keep$taxon, .(y = sum(as.integer(individualCount))), by = .(subsampleID, taxon)]
cat(sprintf("  %d taxa (%d species); %d with >= %d identified individuals shipped (%.1f%% of individuals), %d below the cut; %d duplicate taxonomist rows counted once\n",
            nrow(tot), tot[taxonRank == "species", .N], nrow(keep), MIN_N, 100 * sum(keep$n_ind) / sum(tot$n_ind), nrow(below), n_iddup))

# --- side tables and parts -----------------------------------------------------------------------------------
periods <- data.table(year = sort(unique(sv$year)))[, period := seq_len(.N)]
sv <- merge(sv, periods, by = "year")
units <- unique(sv[order(plotID, -as.numeric(as.Date(substr(setDate, 1, 10))))][, .(unit = plotID, site = siteID, domain = domainID,
                  plot_type = plotType, nlcd_class = nlcdClass, named_location = namedLocation,
                  decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                  coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "unit")
stopifnot(nrow(units) == uniqueN(sv$plotID))
base <- sv[, .(unit = plotID, period, occasion, date = setDate, unit_site = siteID,
               obs_trap_hours = as.numeric(trapHours), obs_proportion_identified = prop, obs_night_or_day = nightOrDay,
               obs_trap_type = trapType, obs_fan_status = fanStatus, obs_co2_status = CO2Status, obs_cup_status = catchCupStatus,
               obs_sample_timing = sampleTiming, subsampleID)]
stopifnot(!anyDuplicated(base[, .(unit, period, occasion)]))
setkey(counts, subsampleID, taxon)
build <- function(pp) {
  b <- base[period %in% pp]
  long <- b[rep(seq_len(.N), each = nrow(keep))][, taxon := rep(keep$taxon, times = nrow(b))]
  long[, y := counts[.(long$subsampleID, long$taxon), y]]
  long[is.na(y), y := 0L]; long[, subsampleID := NULL]
  setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
  stopifnot(nrow(long) == nrow(b) * nrow(keep))
  long
}
n_rows <- nrow(base) * nrow(keep)
stopifnot(sum(counts[subsampleID %in% base$subsampleID, y]) == sum(keep$n_ind))
cat(sprintf("  %d surveys at %d plots, %d sites, %d years; %d rows\n", nrow(base), uniqueN(base$unit), uniqueN(sv$siteID), nrow(periods), n_rows))

higher <- keep[taxonRank != "species", taxon]
taxa <- make_taxa(keep$taxon, keep$name, taxonRank = keep$taxonRank, allow_higher = higher,
                  taxonRemarks = ifelse(keep$taxonRank == "species", NA_character_,
                    sprintf("identified by the NEON taxonomist only to %s; NEON code(s) %s", keep$taxonRank, code$codes[match(keep$taxon, code$taxon)])),
                  taxon_n_identified = keep$n_ind)
dataset <- list(
  title = sprintf("NEON mosquitoes from CO2 light traps, RELEASE-2026: identified mosquitoes of %d taxa per trap collection at %d plots across %d NEON sites, %d-%d", nrow(keep), uniqueN(base$unit), uniqueN(sv$siteID), min(sv$year), max(sv$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/rmw1-me46",
  sourceURL = "https://data.neonscience.org/data-products/DP1.10043.001/RELEASE-2026",
  citation = "NEON (National Ecological Observatory Network). Mosquitoes sampled from CO2 traps (DP1.10043.001), RELEASE-2026. https://doi.org/10.48443/rmw1-me46. Dataset accessed from https://data.neonscience.org/data-products/DP1.10043.001/RELEASE-2026 on 2026-11-05",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's mosquito survey: CO2-baited light traps at about ten plots per terrestrial site, set every two weeks through the season (every four weeks off season at some sites), overnight and, until 2017, also by day. A taxonomist identifies a subsample of each catch (by wet weight; obs_proportion_identified gives its share) to species where possible. This table is the number of identified mosquitoes of each taxon per trap collection, all sexes pooled, for the %d taxa with at least %d identified individuals in the release; every shipped taxon has a row at every collection, and a trap with no mosquitoes is y = 0. y counts the identified subsample, not the whole catch. Plot-centre coordinates are as NEON publishes them.", nrow(keep), MIN_N),
  samplingProtocol = "CDC-style CO2 light trap (dry ice, or a CO2 canister from 2022-2024) hung about 1.5 m high at a plot, set at dusk and collected after about 12 hours (night) or set in the morning and collected at dusk (day); catch frozen, sorted, and a subsample identified and counted by sex by a taxonomist (NEON TOS mosquito sampling protocol)",
  samplingProtocolCode = "light_trap", surveyEvidence = "sample_table",
  surveyEvidenceNote = "mos_trapping lists every trap collection (with samplingImpractical where a plot was not trapped); a survey is a row with samplingImpractical OK or blank, targetTaxaPresent Y or N and trapHours > 0. N keeps no sample and is y = 0 for every taxon; a Y sample's counts are its taxonomist rows (a subsample with no mosquitoes is y = 0). Taxon pool national.",
  responseType = "count", unitKind = "site", effortColumn = "obs_trap_hours", subsampleColumn = "obs_proportion_identified",
  closure = "open", closureNote = "occasion = trap collection within the plot-year (bouts every two to four weeks through the season, each one to three collections), ordered by set time; period = calendar year", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = sprintf("%d NEON terrestrial sites, continental USA, Alaska, Hawaii and Puerto Rico; plot-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", uniqueN(sv$siteID), min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", substr(min(sv$setDate), 1, 7), substr(max(sv$setDate), 1, 7)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("As published by NEON (agency-published plot-centre coordinates with coordinateUncertaintyInMeters); no coarsening; %d plots were re-surveyed by a few metres and __units carries the latest", n_moved)),
  covariateNote = "obs_trap_hours = hours between set and collection (effort); obs_proportion_identified = share of the catch (by wet weight) the taxonomist identified, NA where the trap held no mosquitoes (subsampleColumn); obs_night_or_day, obs_trap_type (dry ice / CO2 canister, blank before NEON recorded it), obs_fan_status, obs_co2_status, obs_cup_status and obs_sample_timing as published.",
  notes = sprintf("y = identified individuals in the subsample, all sexes pooled (taxon is never species x sex, E6); the whole-catch estimate y / obs_proportion_identified is not shipped. Taxa: the %d taxa (species with subspecies rolled up, and records identified only to genus or family, E6) with >= %d identified individuals; %d below the cut are listed in notShipped. Surveys dropped: %d targetTaxaPresent U, %d trapHours = 0, %d samples marked damaged / handling error / incomplete, %d Y collections with no sorting record, %d sorted samples with no taxonomist rows, %d repeat records of one set, %d targetTaxaPresent N records that nevertheless kept a sample, %d collections whose taxonomist rows give two different counts for one taxon x sex; %d exact duplicate taxonomist rows counted once.", nrow(keep), MIN_N, nrow(below), n_u, n_h0, n_bad, n_noso, n_noid, n_dup, n_nsamp, n_conf, n_iddup),
  notShipped = list(
    `taxa below the cut` = paste(sprintf("%s (%s, %d)", below$taxon, below$name, below$n_ind), collapse = "; "),
    `unusable collections` = sprintf("%d targetTaxaPresent U; %d trapHours = 0; %d damaged / handling error / incomplete; %d Y with no sorting record; %d with no taxonomist rows; %d repeat records; %d N with a kept sample; %d with two different counts for one taxon x sex", n_u, n_h0, n_bad, n_noso, n_noid, n_dup, n_nsamp, n_conf),
    `whole-catch estimate` = "y / proportionIdentified (an estimate, not an observation; both terms are shipped)",
    `other tables` = "mos_subsampling, mos_archivepooling, mos_barcoding, pathogen pooling; sex (pooled in y)"))
parts <- as.list(periods$period)
ds <- write_table_parts(parts, build, TABLE, dataset, taxa = taxa, periods = periods[, .(period, year)], units = units,
                        script = "data/neon_2026_mosquitoes_count.R")

stage_dict_row(TABLE,
  description = sprintf("Number of identified mosquitoes of %d taxa per CO2 light-trap collection (subsample share and trap hours given) at %d plots on %d NEON terrestrial sites, %d-%d, built from NEON's trapping, sorting and taxonomist records (RELEASE-2026), with trap condition and plot-centre coordinates as published.", nrow(keep), uniqueN(base$unit), uniqueN(sv$siteID), min(sv$year), max(sv$year)),
  url = "https://data.neonscience.org/data-products/DP1.10043.001/RELEASE-2026",
  reference = "NEON (National Ecological Observatory Network). Mosquitoes sampled from CO2 traps (DP1.10043.001), RELEASE-2026. https://doi.org/10.48443/rmw1-me46",
  doi_paper = "", doi_data = "10.48443/rmw1-me46",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = sprintf("Token-gated NEON API (NEON_TOKEN); release pinned. y = identified subsample count, proportionIdentified as obs_; national pool cut at >= %d individuals; year parts.", MIN_N),
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "light_trap", design = sprintf("Multi-season (%d years x up to %d collections)", nrow(periods), max(base$occasion)), realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; identified-subsample counts per trap collection; every taxon at every collection.",
  status = "tagged")
