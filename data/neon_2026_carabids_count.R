#!/usr/bin/env Rscript
# Table:  neon_2026_carabids_count
# Source: NEON (National Ecological Observatory Network). Ground beetles sampled from pitfall
#         traps (DP1.10022.001), RELEASE-2026. https://doi.org/10.48443/q9ne-6b77. Dataset
#         accessed from https://data.neonscience.org/data-products/DP1.10022.001/RELEASE-2026
#         on 2026-11-02 through the NEON Data API (token-gated; NEON_TOKEN environment variable).
#         Licence: CC BY 4.0, stated on https://data.neonscience.org/data-api/ ("NEON data
#         products and sample data are licensed under a Creative Commons Attribution 4.0
#         International License (CC-BY)"); the product page itself is rendered by JavaScript.
#         NEON is funded by the U.S. National Science Foundation and operated by Battelle.
# Data:   per site-month "basic" package CSVs, all 47 sites and all 2183 site-months of the
#         release (2013-07 to 2023-12), four NEON tables:
#         bet_fielddata: one row per pitfall trap per bout (siteID, plotID, trapID N/E/S/W,
#           namedLocation, plotType, nlcdClass, plot-centre decimalLatitude/Longitude as
#           published by NEON with coordinateUncertainty, elevation, setDate, collectDate,
#           eventID site.year.week, trappingDays, sampleCollected Y/N, sampleID, cupStatus,
#           lidStatus, fluidLevel, samplingImpractical).
#         bet_sorting: one row per subsample of a collected sample (sampleID, subsampleID,
#           sampleType carabid / invert bycatch / vert bycatch ..., taxonID, scientificName,
#           taxonRank, morphospeciesID, individualCount) - the counts live here.
#         bet_parataxonomistID: one row per pinned individual (individualID, subsampleID,
#           taxonID) re-identified by the domain parataxonomist.
#         bet_expertTaxonomistIDProcessed: one row per individual sent to an expert
#           taxonomist (individualID, taxonID).
#         Readme: 10 plots per site; 4 traps per plot 2013-2017 and 3 from 2018; biweekly
#           bouts through the growing season; traps are 16 oz cups of propylene glycol.
# Mapping (standard E9 core: repeated counts, multi-species -> community N-mixture):
#   unit = trap "<plotID>_<trapID>"; period = calendar year (index in __periods); occasion =
#   bout index within the site-year, ordered by the bout's first collection date; y = number of
#   carabid individuals of the species in the trap's sample (sum of individualCount over the
#   sorting rows of sampleType carabid, subspecies rolled up to the species); date =
#   collectDate; obs_trapping_days = trappingDays (effortColumn), obs_cup_status and
#   obs_fluid_level = trap condition at collection; unit_site and unit_plot in the core;
#   __units carries site, domain, plot, trap, NEON namedLocation, plot type, NLCD class,
#   plot-centre coordinates (as published), coordinate uncertainty and elevation.
#   Survey evidence = sample_table: bet_fielddata lists every trap-bout; a survey exists iff
#   sampleCollected == "Y" and samplingImpractical is OK or blank. A collected sample with no
#   carabid sorting rows is y = 0 for every species. Species pool: the species with >= MIN_N
#   individuals over the release, every one at every collected sample nationally (E4's full
#   rectangle, as neon_2026_landbirds_count and rooney_2025_snapshotusa_comm; a per-site pool
#   is the alternative, flagged for a ruling). y uses the sorting-level identifications; the
#   parataxonomist and expert re-identifications of pinned individuals are used only to
#   report how often they differ (they cover a subset of individuals, so they cannot be
#   applied to a subsample's count cleanly).
#   Not shipped: bycatch sample types, genus-and-higher and morphospecies carabid rows,
#   species below the cut, traps with no sample collected.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE   <- "neon_2026_carabids_count"
PRODUCT <- "DP1.10022.001"; RELEASE <- "RELEASE-2026"; MIN_N <- 1000L
nx <- download_neon(PRODUCT, TABLE, RELEASE,
                    tables = c("bet_fielddata", "bet_sorting", "bet_parataxonomistID", "bet_expertTaxonomistIDProcessed"))
stopifnot(identical(attr(nx, "release"), RELEASE), attr(nx, "n_site_months") == 2183L,
          identical(attr(nx, "productDoi"), "https://doi.org/10.48443/q9ne-6b77"))
fd <- nx$bet_fielddata; so <- nx$bet_sorting; pa <- nx$bet_parataxonomistID; ex <- nx$bet_expertTaxonomistIDProcessed
cat(sprintf("  bet_fielddata %d, bet_sorting %d, bet_parataxonomistID %d, bet_expertTaxonomistIDProcessed %d rows\n",
            nrow(fd), nrow(so), nrow(pa), nrow(ex)))
IMPRACTICAL <- c("OK", "logistical", "temperature low", "location flooded", "management", "other", "location snow covered",
                 "extreme weather", "safety hazard", "location burned")
stopifnot(uniqueN(fd$siteID) == 47, all(fd$sampleCollected %in% c("Y", "N")), all(fd$trapID %in% c("N", "E", "S", "W")),
          all(is.na(fd$samplingImpractical) | fd$samplingImpractical %in% IMPRACTICAL),
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", fd$collectDate)), !anyNA(fd$decimalLatitude),
          !anyNA(fd$trappingDays[fd$sampleCollected == "Y"]), !anyNA(fd$sampleID[fd$sampleCollected == "Y"]),
          !anyDuplicated(fd$sampleID[fd$sampleCollected == "Y"]))

# --- surveys: one collected sample per trap-bout ---------------------------------------------
fd[, unit := paste(plotID, trapID, sep = "_")][, day := collectDate][, year := as.integer(substr(day, 1, 4))][, days := as.numeric(trappingDays)]
n_impr <- sum(fd$sampleCollected == "Y" & !is.na(fd$samplingImpractical) & fd$samplingImpractical != "OK")
n_zero <- sum(fd$sampleCollected == "Y" & fd$days == 0)
sv <- fd[sampleCollected == "Y" & (is.na(samplingImpractical) | samplingImpractical == "OK") & days > 0]
cat(sprintf("  %d of %d trap-bouts collected a sample under OK conditions with effort > 0 (%d collected but samplingImpractical != OK, %d with trappingDays = 0 dropped); trappingDays median %.0f, %d above 30 kept as published\n",
            nrow(sv), nrow(fd), n_impr, n_zero, median(sv$days), sum(sv$days > 30)))
# bout = NEON eventID "SITE.YEAR.week"; 22 rows at HARV and BART 2014-15 carry a placeholder
# instead and take the eventID of the site's other collections on the same day, else are dropped
ok <- grepl("^[A-Z]{4}\\.\\d{4}\\.\\d{1,2}$", sv$eventID)
fix <- sv[ok, .(ev2 = names(sort(table(eventID), decreasing = TRUE))[1]), by = .(siteID, day)]
sv[!ok, eventID := fix[.SD, on = .(siteID, day), ev2]]
n_noev <- sum(is.na(sv$eventID))
cat(sprintf("  %d surveys with a malformed eventID: %d re-keyed to the site's bout that day, %d dropped\n", sum(!ok), sum(!ok) - n_noev, n_noev))
stopifnot(sum(!ok) == 22L)
sv <- sv[!is.na(eventID)]
# a trap is collected once per bout; the few repeats within a bout keep the first collection
rep_tb <- sv[, .N, by = .(unit, eventID)][N > 1]
cat(sprintf("  %d trap-bouts with more than one collected sample; first kept\n", nrow(rep_tb)))
setorder(sv, unit, eventID, collectDate)
sv <- sv[!duplicated(sv, by = c("unit", "eventID"))]
# occasion = bout index within the site-year, by the bout's first collection day
bouts <- sv[, .(first = min(day)), by = .(siteID, year, eventID)]
setorder(bouts, siteID, year, first, eventID)
bouts[, occasion := seq_len(.N), by = .(siteID, year)]
sv <- merge(sv, bouts[, .(eventID, occasion)], by = "eventID")
stopifnot(!anyDuplicated(sv[, .(unit, year, occasion)]))
traps_per_plot <- sv[, uniqueN(trapID), by = .(plotID, year)]
cat(sprintf("  traps per plot-year: %s; max bouts in a site-year: %d\n",
            paste(names(table(traps_per_plot$V1)), table(traps_per_plot$V1), collapse = ", "), max(sv$occasion)))
stopifnot(all(traps_per_plot$V1 <= 4), traps_per_plot[year <= 2017, mean(V1 == 4)] > 0.9, traps_per_plot[year >= 2018, mean(V1 == 3)] > 0.9)
for (cc in c("siteID", "domainID", "plotID", "trapID", "namedLocation", "plotType", "nlcdClass", "decimalLatitude", "decimalLongitude"))
  stopifnot(sv[, uniqueN(get(cc)), by = unit][, all(V1 == 1)])

# --- carabid counts per sample, species rank, subspecies rolled up -----------------------------
type_tab <- table(so$sampleType)
stopifnot(identical(sort(names(type_tab)), c("carabid", "invert bycatch", "other carabid", "vert bycatch herp", "vert bycatch mam")),
          all(so$sampleID[so$sampleType %in% c("carabid", "other carabid")] %in% fd$sampleID))
# "other carabid" = carabids recovered from the bycatch fraction (mostly family-level, a few species)
car <- so[sampleType %in% c("carabid", "other carabid") & sampleID %in% sv$sampleID]
car[, n := as.integer(individualCount)]
n_na_count <- sum(is.na(car$n)); stopifnot(n_na_count == 1L)
car <- car[!is.na(n)]
stopifnot(all(car$n >= 1), !anyNA(car$taxonRank))
rank_tab <- table(car$taxonRank)
morpho <- sum(!is.na(car$morphospeciesID) & nzchar(car$morphospeciesID))
sp <- car[taxonRank %in% c("species", "subspecies")]
sp[, species_name := sub("^(\\S+ \\S+).*$", "\\1", scientificName)]
# species-level code: the species-rank taxonID where NEON uses one, else the subspecies code without its trailing digit(s)
code <- sp[, { s <- taxonID[taxonRank == "species"]
               .(code = if (length(s)) names(sort(table(s), decreasing = TRUE))[1] else sub("\\d+$", "", taxonID[1])) }, by = species_name]
stopifnot(!anyDuplicated(code$code), !anyDuplicated(code$species_name))
sp <- merge(sp, code, by = "species_name")
counts <- sp[, .(y = sum(n)), by = .(sampleID, code)]
sp_tot <- sp[, .(n_ind = sum(n), n_samples = uniqueN(sampleID)), by = .(code, species_name)][order(-n_ind)]
species <- sp_tot[n_ind >= MIN_N]; below <- sp_tot[n_ind < MIN_N]
cat(sprintf("  carabid sorting rows by rank: %s; %d morphospecies rows; %d species, %d with >= %d individuals shipped (%.1f%% of individuals), %d below the cut\n",
            paste(names(rank_tab), rank_tab, collapse = ", "), morpho, nrow(sp_tot), nrow(species), MIN_N,
            100 * species[, sum(n_ind)] / sp_tot[, sum(n_ind)], nrow(below)))

# --- how often the pinned subset was re-identified differently (reported, not applied) ----------
pa_sub <- pa[subsampleID %in% car$subsampleID]
pa_cmp <- merge(pa_sub[, .(subsampleID, individualID, para = taxonID)], car[, .(subsampleID, sort = taxonID)], by = "subsampleID")
ex_cmp <- merge(ex[, .(individualID, expert = taxonID)], pa_cmp, by = "individualID")
cat(sprintf("  parataxonomist re-ids: %d pinned individuals, %.1f%% differ from the sorting id; expert re-ids: %d individuals, %.1f%% differ from the parataxonomist\n",
            nrow(pa_cmp), 100 * mean(pa_cmp$para != pa_cmp$sort), nrow(ex_cmp), 100 * mean(ex_cmp$expert != ex_cmp$para)))

# --- long table: every shipped species at every collected sample -------------------------------
periods <- data.table(year = sort(unique(sv$year)))[, period := seq_len(.N)]
sv <- merge(sv, periods, by = "year")
units <- unique(sv[, .(unit, site = siteID, domain = domainID, plot = plotID, trap = trapID, named_location = namedLocation,
                       plot_type = plotType, nlcd_class = nlcdClass,
                       decimalLatitude = as.numeric(decimalLatitude), decimalLongitude = as.numeric(decimalLongitude),
                       coordinateUncertaintyInMeters = as.numeric(coordinateUncertainty), elevation_m = as.numeric(elevation))], by = "unit")
stopifnot(nrow(units) == uniqueN(sv$unit))
base <- sv[, .(unit, period, occasion, date = day, unit_site = siteID, unit_plot = plotID,
               obs_trapping_days = as.numeric(trappingDays), obs_cup_status = cupStatus, obs_fluid_level = fluidLevel, sampleID)]
long <- base[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$code, times = nrow(base))]
long <- merge(long, counts[code %in% species$code, .(sampleID, taxon = code, y)], by = c("sampleID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, sampleID := NULL]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "date"))
stopifnot(nrow(long) == nrow(sv) * nrow(species), sum(long$y) == counts[code %in% species$code, sum(y)],
          !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d collected samples at %d traps, %d plots, %d sites, %d years; %d rows\n",
            nrow(sv), uniqueN(sv$unit), uniqueN(sv$plotID), uniqueN(sv$siteID), nrow(periods), nrow(long)))

taxa <- make_taxa(species$code, species$species_name)
periods <- periods[, .(period, year)]
dataset <- list(
  title = sprintf("NEON ground beetles from pitfall traps, RELEASE-2026: carabid individuals of %d species per trap-bout sample at %d traps across %d NEON sites, %d-%d", nrow(species), uniqueN(sv$unit), uniqueN(sv$siteID), min(sv$year), max(sv$year)),
  creator = "NEON (National Ecological Observatory Network)", pubDate = "2026", doi = "10.48443/q9ne-6b77",
  sourceURL = "https://data.neonscience.org/data-products/DP1.10022.001/RELEASE-2026",
  citation = "NEON (National Ecological Observatory Network). Ground beetles sampled from pitfall traps (DP1.10022.001), RELEASE-2026. https://doi.org/10.48443/q9ne-6b77. Dataset accessed from https://data.neonscience.org/data-products/DP1.10022.001/RELEASE-2026 on 2026-11-02",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = sprintf("NEON's ground beetle survey: pitfall traps (propylene glycol cups) at 10 plots per terrestrial site, four traps per plot through 2017 and three from 2018, collected every two weeks through the growing season; every carabid in a sample is sorted and identified to species or morphospecies by NEON technicians. This table is the number of carabid individuals of each species per trap-bout sample for the %d species with at least %d individuals over the release; every shipped species carries a row at every collected sample. Unit coordinates are the plot centres NEON publishes.", nrow(species), MIN_N),
  samplingProtocol = "Pitfall traps (16 oz cups, 150-250 mL propylene glycol) ~20 m from plot centre in the cardinal directions, set for ~14 days (trappingDays recorded per trap), collected biweekly when temperatures exceed 4 C; carabids sorted and identified in the domain lab, a pinned subset re-identified by a parataxonomist and an expert (NEON TOS protocol for ground beetle sampling)",
  samplingProtocolCode = "pitfall_trap", surveyEvidence = "sample_table",
  surveyEvidenceNote = "bet_fielddata lists every trap-bout; a survey exists iff sampleCollected == Y and samplingImpractical is OK or blank. A collected sample with no carabid rows in bet_sorting is y = 0 for every species. Species pool is national: every shipped species at every collected sample.",
  responseType = "count", unitKind = "site", effortColumn = "obs_trapping_days",
  closure = "open", closureNote = "occasion = biweekly bout within the growing season, indexed within the site-year by first collection date; period = calendar year", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = sprintf("47 NEON terrestrial sites in 20 domains, continental USA, Alaska, Hawaii and Puerto Rico; plot-centre coordinates as published by NEON (WGS 84) in __units; latitude %.1f to %.1f, longitude %.1f to %.1f", min(units$decimalLatitude), max(units$decimalLatitude), min(units$decimalLongitude), max(units$decimalLongitude)),
  temporalCoverage = sprintf("%s/%s", min(sv$day), max(sv$day)),
  crs = "EPSG:4326 (WGS 84), as published",
  coordinatesCoarsened = list(value = FALSE, method = "As published by NEON (agency-published plot-centre coordinates with coordinateUncertaintyInMeters); no coarsening"),
  occasionLength = "one trap-bout, ~14 days (obs_trapping_days)",
  covariateNote = "obs_trapping_days is the decimal days the trap was open (effort); obs_cup_status and obs_fluid_level are the trap's condition at collection (NEON categorical values as published). Trap-level facts (site, domain, plot, trap, NEON namedLocation, plot type, NLCD class, plot-centre coordinates shared by a plot's traps, coordinate uncertainty, elevation) are in __units.",
  notes = sprintf("Taxa: the %d carabid species with >= %d individuals over the release, subspecies rolled up to the species; %d species below the cut are listed in notShipped. y uses NEON's sorting-level identifications (where the counts are); a pinned subset is re-identified by a parataxonomist and an expert taxonomist, and the share that differ is reported in the build log, not applied. Surveys: collected samples under OK conditions with trappingDays > 0 (%d collected samples with samplingImpractical != OK and %d with zero days dropped; %d trap-bouts collected twice keep the first record; 22 rows with a placeholder eventID re-keyed to the site's bout that day or dropped). Counts include the 'other carabid' sorting rows (carabids recovered from the bycatch fraction, %d rows) and %d sorting row(s) without individualCount are dropped. Period = calendar year; occasion = bout index within the site-year (max %d), so sites with short seasons have fewer occasions.", nrow(species), MIN_N, nrow(below), n_impr, n_zero, nrow(rep_tb), type_tab[["other carabid"]], n_na_count, max(sv$occasion)),
  notShipped = list(
    `bycatch` = paste(sprintf("%s: %d sorting rows", names(type_tab), type_tab)[!names(type_tab) %in% c("carabid", "other carabid")], collapse = "; "),
    `carabid rows above species rank or morphospecies` = paste(c(sprintf("%s: %d rows", names(rank_tab)[!names(rank_tab) %in% c("species", "subspecies")], rank_tab[!names(rank_tab) %in% c("species", "subspecies")]), sprintf("morphospecies: %d rows", morpho)), collapse = "; "),
    `species below the cut` = paste(sprintf("%s (%s, %d)", below$code, below$species_name, below$n_ind), collapse = "; "),
    `traps without a survey` = sprintf("%d trap-bouts with sampleCollected = N; %d collected under samplingImpractical != OK; %d with trappingDays = 0", sum(fd$sampleCollected == "N"), n_impr, n_zero),
    `re-identifications` = "bet_parataxonomistID and bet_expertTaxonomistIDProcessed (per pinned individual; not applied to counts)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/neon_2026_carabids_count.R")

stage_dict_row(TABLE,
  description = sprintf("Number of carabid beetle individuals of %d species per pitfall-trap sample (~14-day bouts, biweekly through the growing season) at %d traps on 47 NEON terrestrial sites, %d-%d, built from NEON's sorting records (RELEASE-2026) with trapping days, trap condition and plot-centre coordinates as published.", nrow(species), uniqueN(sv$unit), min(sv$year), max(sv$year)),
  url = "https://data.neonscience.org/data-products/DP1.10022.001/RELEASE-2026",
  reference = "NEON (National Ecological Observatory Network). Ground beetles sampled from pitfall traps (DP1.10022.001), RELEASE-2026. https://doi.org/10.48443/q9ne-6b77",
  doi_paper = "", doi_data = "10.48443/q9ne-6b77",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = sprintf("Token-gated NEON API (NEON_TOKEN); release pinned. National species pool (>= %d individuals); sorting-level ids; bycatch and morphospecies not shipped.", MIN_N),
  source_via = "NEON Data API, basic package")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "pitfall_trap", design = sprintf("Multi-season (%d years x up to %d bouts)", nrow(periods), max(sv$occasion)), realm = "Terrestrial", country = "USA",
  coordinates = "As published", notes = "NEON national scheme; carabid counts per trap-bout from sorting records; every species at every sample.",
  status = "tagged")
