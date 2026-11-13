#!/usr/bin/env Rscript
# Tables: neon_2026_<gen><spe>_rd for the nine species with the most marked individuals (ruling #20:
#         an individual-unit deposit with several species ships one table per taxon); all written by
#         this script, which shares its download with neon_2026_smallmammals_count.
# Source: NEON (National Ecological Observatory Network), data product DP1.10072.001 "Small mammal
#         box trapping", RELEASE-2026 (generated 2026-01-23), https://doi.org/10.48443/a83h-tb34,
#         accessed through the NEON Data API on 2026-11-02 with an API token (NEON_TOKEN; the data
#         endpoints answer 403 without one). Licence CC BY 4.0 as stated on
#         https://data.neonscience.org/data-api/ ("NEON data products and sample data are licensed
#         under a Creative Commons Attribution 4.0 International License (CC-BY)"). Citation
#         required by NEON: "NEON (National Ecological Observatory Network). Small mammal box
#         trapping (DP1.10072.001), RELEASE-2026. https://doi.org/10.48443/a83h-tb34. Dataset
#         accessed from https://data.neonscience.org/data-products/DP1.10072.001/RELEASE-2026 on
#         2026-11-02". Same download as neon_2026_smallmammals_count (shared cache directory).
# Paper:  no single paper; protocol NEON.DOC.000481 and the product user guide.
# Data:   see data/neon_2026_smallmammals_count.R for the two NEON tables used (mam_perplotnight,
#         mam_pertrapnight). Individuals are marked with ear tags (tagID NEON.MAM.Dxx.L#### or
#         R####, left or right ear; a replaced tag is recorded in replacedTag) or PIT tags
#         (NEON.MAM.Dxx.<digits>); animals released unmarked carry a provisional id built from
#         plot, trap and date (NEON.MAM.Dxx.O<plot><trap><date>[.<time>] or the same without the
#         O), which does not identify them across nights.
# Mapping (standard E9 robust design, responseType detection, unitKind individual; ruling #20 lets
# a multi-taxon individual-unit table carry one taxon per individual):
#   unit = tagID of a persistently marked animal (ear or PIT tag); taxon = the species-rank
#   taxonID of that animal (modal over its captures; a tag whose captures carry two species labels
#   is resolved to the modal one, ties to the first capture, and counted in notes); cluster_id =
#   the animal's home grid (plotID of first capture); period = trapping bout, the same global
#   eventID index as the count table (asserted equal to its __periods when that file exists);
#   occasion = night within the bout at the home grid; date = the night; y = 1 if captured on the
#   home grid that night. At-risk span (E4.4): the animals are wild-caught and of unknown age
#   (live-trapped and tagged at first capture, whatever their life stage), so each is at risk
#   from the home grid's first surveyed bout in the release: rows are every surveyed night of the
#   home grid from its first bout through its last surveyed bout, 0 before first capture
#   (unit_first_capture marks it; drop earlier rows to condition on first capture). A replaced
#   tag (replacedTag) is the same animal, not a lost mark ending one history and a new animal
#   starting another: the old tag's captures are relabelled to the new tag (chains followed),
#   so one unit carries the animal's whole history. A tag lost without replacement is not
#   recorded, so no history is cut short. A capture on a grid other than the home grid is not representable on
#   the home grid's rows and is dropped (counted). unit_sex (modal), unit_site, unit_domain,
#   unit_first_capture (date); obs_weight_g, obs_life_stage, obs_recapture_flag on capture nights
#   (NA otherwise); obs_traps_set and obs_grid_method per night as in the count table.
#   Survey evidence (sample_table): as the count table (mam_perplotnight rows with
#   samplingImpractical NA/OK, gridCompletion recorded, at least one trap set).
#   Not shipped: captures with provisional ids (unmarked animals), captures identified above
#   species rank, captures away from the home grid, tags caught on more than one grid's history
#   beyond the home grid, measurements other than weight, samples, mam_voucher,
#   mam_identificationHistory.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/neon_2026_smallmammals_rd.R"           # one script, one table per species (ruling #20)
N_TABLES <- 9L                                          # the nine species with the most marked individuals (4 until batch 58, raised by Ben 2026-11-13); the rest in notShipped
CACHE_TABLE <- "neon_2026_smallmammals_count"            # one download serves both tables
PRODUCT <- "DP1.10072.001"; RELEASE <- "RELEASE-2026"; DOI <- "https://doi.org/10.48443/a83h-tb34"
SITES <- NULL
MAX_ROWS <- 8e6

x <- download_neon(PRODUCT, CACHE_TABLE, RELEASE, tables = c("mam_perplotnight", "mam_pertrapnight"), sites = SITES)
stopifnot(identical(attr(x, "productDoi"), DOI), identical(attr(x, "productName"), "Small mammal box trapping"))
pp <- x$mam_perplotnight; pt <- x$mam_pertrapnight
sm <- attr(x, "site_months")
if (is.null(SITES)) stopifnot(nrow(sm) == 1859L, uniqueN(sm$site) == 46L)

# --- survey set and bouts (identical to the count table) ---------------------------------------
stopifnot(!anyDuplicated(pp$nightuid), all(pt$nightuid %in% pp$nightuid), !anyNA(pp$eventID),
          all(grepl("^[A-Z]{4}\\.\\d{4}\\.\\d{1,2}$", pp$eventID)))
pp[, night_date := substr(collectDate, 1, 10)]; pt[, night_date := substr(collectDate, 1, 10)]
stopifnot(pt[pp, on = "nightuid", uniqueN(nightuid[night_date != i.night_date])] <= 5L, pt[pp, on = "nightuid", all(plotID == i.plotID)])
pt[, night_date := NULL]                                                  # the night's date is the plot-night's date
cap_status <- c("4 - more than 1 capture in one trap", "5 - capture")
pt[, on_grid := grepl("^[A-J]([1-9]|10)$", trapCoordinate)]
set <- pt[on_grid & trapStatus != "1 - trap not set", .(obs_traps_set = uniqueN(trapCoordinate)), by = nightuid]
pp <- merge(pp, set, by = "nightuid", all.x = TRUE); pp[is.na(obs_traps_set), obs_traps_set := 0L]
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
nights[, year := as.integer(substr(eventID, 6, 9))]
bouts <- nights[, .(site = siteID[1], year = year[1], bout_start = min(night_date), bout_end = max(night_date),
                    n_nights = uniqueN(night_date), n_grids = uniqueN(plotID)), by = eventID]
setorder(bouts, bout_start, eventID); bouts[, period := seq_len(.N)]
nights <- merge(nights, bouts[, .(eventID, period)], by = "eventID")
setorder(nights, period, plotID, night_date); nights[, occasion := seq_len(.N), by = .(period, plotID)]
periods <- bouts[, .(period, eventID, site, year, bout_start, bout_end, n_nights, n_grids)]
sib <- file.path(OUT_DIR, paste0(CACHE_TABLE, "__periods.csv"))
if (file.exists(sib) && is.null(SITES)) {
  sp_ <- fread(sib, colClasses = "character")
  stopifnot(nrow(sp_) == nrow(periods), all(sp_$eventID == periods$eventID), all(as.integer(sp_$period) == periods$period))
}

# --- captures of marked animals ----------------------------------------------------------------
cap <- pt[trapStatus %in% cap_status & !is.na(tagID) & !is.na(taxonID)][nights[, .(nightuid, period, occasion, night_date)], on = "nightuid", nomatch = NULL]
stopifnot(nrow(cap) >= nrow(pt[trapStatus %in% cap_status]) - 10L)
# E4.4: a replaced tag is the same animal; relabel the old tag's captures to the current tag
rp <- if ("replacedTag" %in% names(cap)) unique(cap[!is.na(replacedTag) & nzchar(replacedTag) & replacedTag != tagID, .(old = replacedTag, new = tagID)]) else data.table(old = character(), new = character())
rp_amb <- rp[, .N, by = old][N > 1L, old]                                  # one old tag replaced by two new ones: ambiguous, left alone
rp <- rp[!old %in% rp_amb & old %in% cap$tagID]
m <- setNames(rp$new, rp$old)                                              # follow chains old -> new -> newer
for (i in 1:20) { hit <- m %in% names(m); if (!any(hit)) break; m[hit] <- m[m[hit]] }
m <- m[!m %in% names(m) & m != names(m)]                                    # drop cycles, if any
rp <- data.table(old = names(m), new = unname(m))
stopifnot(!anyDuplicated(rp$old), !any(rp$new %in% rp$old))
n_relabel <- cap[rp, on = .(tagID = old), .N, nomatch = NULL]
cap[rp, on = .(tagID = old), tagID := i.new]
cat(sprintf("  replaced tags: %d old tags relabelled to their replacement (%d captures); %d ambiguous left as recorded\n", nrow(rp), n_relabel, length(rp_amb)))
cap[, mark := fcase(grepl("^NEON\\.MAM\\.D\\d{2}\\.[LR]\\d+[A-Z]?$", tagID), "ear tag",
                    grepl("^NEON\\.MAM\\.D\\d{2}\\.\\d+$", tagID), "PIT tag",
                    grepl("^NEON\\.MAM\\.D\\d{2}\\.O", tagID), "provisional id (O prefix)",
                    default = "provisional id (plot-trap-date)")]
mark_n <- cap[, .N, by = mark][order(-N)]
marked <- cap[mark %in% c("ear tag", "PIT tag") & taxonRank == "species"]
setorder(marked, nightuid, tagID, trapCoordinate)
dup_night <- marked[, .N, by = .(tagID, nightuid)][N > 1L, .N]            # a tag recorded in two traps on one night (or old and new tag on the replacement night): one capture
marked <- marked[!duplicated(marked[, .(tagID, nightuid)])]
stopifnot(dup_night <= 200L + n_relabel)
cat(sprintf("  %s captures on surveyed nights: %s; %s species-rank captures of marked animals\n",
            format(nrow(cap), big.mark = ","), paste(mark_n$mark, mark_n$N, collapse = ", "), format(nrow(marked), big.mark = ",")))

# individuals: home grid, species, sex
setorder(marked, period, occasion, tagID)
ind <- marked[, {
  sp <- names(which.max(table(factor(taxonID, levels = unique(taxonID)))))   # modal, ties to first capture
  sx <- table(factor(sex, levels = c("F", "M", "U")))
  .(home = plotID[1], site = siteID[1], domain = domainID[1], taxon = sp, n_species_labels = uniqueN(taxonID),
    sex = if (sum(sx[c("F", "M")]) == 0) "U" else names(which.max(sx[c("F", "M")])),
    first_period = period[1], last_period = max(period), first_capture = night_date[1], n_captures = .N,
    n_grids = uniqueN(plotID))
}, by = tagID]
stopifnot(!anyDuplicated(ind$tagID), all(ind$sex %in% c("F", "M", "U")))
away <- marked[ind[, .(tagID, home)], on = "tagID"][plotID != home]
marked <- marked[ind[, .(tagID, home)], on = "tagID"][plotID == home]
lr_both <- cap[mark == "ear tag", .(n = uniqueN(substr(tagID, 14, 14))), by = .(num = sub("^NEON\\.MAM\\.D\\d{2}\\.[LR]", "", tagID), dom = substr(tagID, 10, 12))][n > 1, .N]
cat(sprintf("  %s marked individuals (%d with two or more species labels, %d caught on more than one grid; %d captures away from the home grid dropped)\n",
            format(nrow(ind), big.mark = ","), sum(ind$n_species_labels > 1), sum(ind$n_grids > 1), nrow(away)))   # all species (before the shipped-species cut)

# --- the species shipped: the N_TABLES with the most marked individuals --------------------------
sp_rank <- ind[, .(n_individuals = .N), by = .(taxonID = taxon)]
sp_rank <- merge(sp_rank, marked[, .(scientificName = scientificName[1]), by = taxonID], by = "taxonID")[order(-n_individuals)]
ship_taxa <- sp_rank[seq_len(min(N_TABLES, .N)), taxonID]
stopifnot(identical(ship_taxa, c("PEMA", "PELE", "SIHI", "MIPE", "MYRU", "MYGA", "NAIN", "DIME", "PEGO")))   # ranking checked against the 2026-11-13 ruling
ind <- ind[taxon %in% ship_taxa]                          # histories are built only for shipped species

# --- histories: home-grid nights from the grid's first bout on (E4.4: wild-caught, unknown age) ----
gn <- nights[, .(plotID, period, occasion, nightuid, night_date, obs_traps_set, obs_grid_method = mammalGridSamplingMethod)]
rows_to_last_bout <- ind[, .N, by = home][gn[, .N, by = plotID], on = .(home = plotID), nomatch = NULL][, sum(as.numeric(N) * i.N)]
cat(sprintf("  rows from the home grid's first bout to its last bout (shipped species): %s\n", format(rows_to_last_bout, big.mark = ",")))
if (rows_to_last_bout <= MAX_ROWS) {
  ROW_RULE <- "last surveyed bout at the home grid in the release"
  long <- ind[, .(tagID, home, first_period, taxon, sex, site, domain, first_capture)][gn, on = .(home = plotID), nomatch = NULL, allow.cartesian = TRUE,
              .(unit = tagID, taxon, period = i.period, occasion = i.occasion, nightuid = i.nightuid, date = i.night_date, cluster_id = home,
                unit_site = site, unit_domain = domain, unit_sex = sex, unit_first_capture = first_capture, obs_traps_set = i.obs_traps_set, obs_grid_method = i.obs_grid_method)]
} else {
  ROW_RULE <- "fourth surveyed bout at the home grid after the last capture (table capped at 8 million rows)"
  nb <- unique(gn[, .(plotID, period)])[order(plotID, period)][, k := seq_len(.N), by = plotID]
  lim <- merge(ind[, .(tagID, home, last_period)], nb, by.x = c("home", "last_period"), by.y = c("plotID", "period"))[, .(tagID, kmax = k + 4L)]
  gnk <- merge(gn, nb, by = c("plotID", "period"))
  long <- merge(ind[, .(tagID, home, first_period, taxon, sex, site, domain, first_capture)], lim, by = "tagID")[gnk, on = .(home = plotID, kmax >= k), nomatch = NULL, allow.cartesian = TRUE,
              .(unit = tagID, taxon, period = i.period, occasion = i.occasion, nightuid = i.nightuid, date = i.night_date, cluster_id = home,
                unit_site = site, unit_domain = domain, unit_sex = sex, unit_first_capture = first_capture, obs_traps_set = i.obs_traps_set, obs_grid_method = i.obs_grid_method)]
}
stopifnot(!anyDuplicated(long[, .(unit, period, occasion)]), nrow(long) <= MAX_ROWS)
obs <- marked[tagID %in% ind$tagID, .(unit = tagID, nightuid, y = 1L, obs_weight_g = as.numeric(weight), obs_life_stage = lifeStage, obs_recapture_flag = recapture)]
stopifnot(!anyDuplicated(obs[, .(unit, nightuid)]))
long <- merge(long, obs, by = c("unit", "nightuid"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(sum(long$y) == nrow(marked[tagID %in% ind$tagID]))                                     # every home-grid capture lands on a row
first_rows <- long[, .(p = min(period)), by = .(unit, cluster_id)]
stopifnot(all(first_rows$p == gn[, .(p = min(period)), by = plotID][first_rows, on = .(plotID = cluster_id), p]))   # history starts at the grid's first bout
long <- long[, .(unit, taxon, y = as.integer(y), period, occasion, date, cluster_id, unit_site, unit_domain, unit_sex, unit_first_capture,
                 obs_traps_set = as.integer(obs_traps_set), obs_grid_method, obs_weight_g, obs_life_stage, obs_recapture_flag)]
long <- order_eco(long)
cat(sprintf("  %s rows: %s individuals of %d species, %d bouts, %s captures (%.1f%% of rows); rows run to the %s\n",
            format(nrow(long), big.mark = ","), format(uniqueN(long$unit), big.mark = ","), uniqueN(long$taxon), uniqueN(long$period),
            format(sum(long$y), big.mark = ","), 100 * mean(long$y), ROW_RULE))

species <- copy(sp_rank)                                                    # modal labels drop a few rare ids
stopifnot(setequal(ship_taxa, unique(long$taxon)), species[, .N, by = scientificName][, all(N == 1L)])
species <- merge(species, long[, .(n_captures = sum(y), n_rows = .N), by = .(taxonID = taxon)], by = "taxonID", all.x = TRUE)[order(-n_individuals)]
stopifnot(identical(species[taxonID %in% ship_taxa, n_individuals], long[, uniqueN(unit), by = taxon][match(species[taxonID %in% ship_taxa, taxonID], taxon), V1]))
species[, table := paste0("neon_2026_", tolower(paste0(substr(sub(" .*$", "", scientificName), 1, 3), substr(sub("^[^ ]+ ", "", scientificName), 1, 3))), "_rd")]
ship <- species[seq_len(min(N_TABLES, nrow(species)))]
stopifnot(setequal(ship$taxonID, ship_taxa))
stopifnot(nrow(ship) >= 1L, !anyDuplicated(ship$table), all(nchar(ship$table) <= 40L))
cat(sprintf("  the %d species with the most marked individuals shipped as one table each: %s; %d other species (%s individuals) not shipped\n",
            nrow(ship), paste(ship$taxonID, ship$n_individuals, collapse = ", "), nrow(species) - nrow(ship), format(species[-seq_len(nrow(ship)), sum(n_individuals)], big.mark = ",")))
below <- species[-seq_len(nrow(ship)), paste0(scientificName, " (", taxonID, ": ", n_individuals, ")", collapse = "; ")]

build <- function(k) {
  s <- ship[k]
  sp_long <- long[taxon == s$taxonID]
  sp_units <- ind[tagID %in% sp_long$unit, .(unit = tagID, home_grid = home, site, domain, sex, mark = fifelse(grepl("\\.[LR]", tagID), "ear tag", "PIT tag"),
                                              first_capture, n_species_labels, n_grids_caught = n_grids)]
  sp_units <- merge(sp_units, sp_long[, .(n_captures_home = sum(y), n_bouts = uniqueN(period), n_nights = .N, last_night = max(date)), by = unit], by = "unit")
  sp_periods <- periods[period %in% sp_long$period]
  taxa <- make_taxa(s$taxonID, s$scientificName, taxon_n_individuals = s$n_individuals, taxon_n_captures = s$n_captures)
  stopifnot(!is.na(taxa$taxonID))
  others <- ship[-k, paste(table, collapse = ", ")]
  dataset <- list(
    title = sprintf("NEON small mammal box trapping, RELEASE-2026: robust-design capture histories of %s %s on %d trapping grids at %d NEON sites, %d-%d",
                    format(s$n_individuals, big.mark = ","), s$scientificName, uniqueN(sp_long$cluster_id), uniqueN(sp_long$unit_site), min(sp_periods$year), max(sp_periods$year)),
    creator = "NEON (National Ecological Observatory Network)", pubDate = "2026",
    doi = sub("https://doi.org/", "", DOI), sourceURL = sprintf("https://data.neonscience.org/data-products/%s/%s", PRODUCT, RELEASE),
    citation = sprintf("NEON (National Ecological Observatory Network). Small mammal box trapping (%s), %s. %s. Dataset accessed from https://data.neonscience.org/data-products/%s/%s on 2026-11-02", PRODUCT, RELEASE, DOI, PRODUCT, RELEASE),
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/",
                              note = "Licence stated on https://data.neonscience.org/data-api/ (NEON data products are CC BY 4.0); attribution per NEON's citation guidance"),
    abstract = sprintf("Capture histories of %s ear- or PIT-tagged on NEON's 10 x 10 Sherman-trap grids (10 m spacing) at terrestrial sites across the United States, trapped in bouts of one or three consecutive nights four to six times a year. One row per marked individual x night its home grid (grid of first capture) was trapped, from the grid's first bout in the release (wild-caught animals of unknown age, at risk from the start; E4.4) through the %s; y = captured on the home grid that night. %s individuals, %s captures, %d bouts. Bouts are the primary periods of a robust design and nights the secondary occasions; weight, life stage and the technician's recapture flag ride on capture rows. One of %d species tables written by one script (ruling #20: one taxon per individual-unit table); the companion table neon_2026_smallmammals_count holds the grid-night capture counts of all species and the grid coordinates.",
                       s$scientificName, ROW_RULE, format(s$n_individuals, big.mark = ","), format(s$n_captures, big.mark = ","), nrow(sp_periods), nrow(ship)),
    samplingProtocol = "Sherman box traps (LFA/XLK) on 10 x 10 grids at 10 m spacing, set in the evening and checked at dawn; bouts within 10 days of the new moon, 1 night (diversity grids) or 3 consecutive nights (pathogen grids); captures identified, ear-tagged (left or right) or PIT-tagged, sexed, aged and weighed; NEON protocol NEON.DOC.000481",
    samplingProtocolCode = "live_trap", occasionLength = "one trap-night", effortColumn = "obs_traps_set",
    surveyEvidence = "sample_table",
    surveyEvidenceNote = "mam_perplotnight: a grid-night is a survey iff samplingImpractical is NA or OK, gridCompletion is recorded, and at least one trap was set; an individual's rows are the surveyed nights of its home grid from the grid's first bout onward (E4.4: wild-caught, unknown age), 0 before first capture.",
    responseType = "detection", unitKind = "individual",
    closure = "closed", closureNote = "period = trapping bout (eventID, 1-6 nights per grid, usually 1 or 3, within at most 12 days, closed); occasion = night within the bout at the home grid; population open between bouts (robust design)", occasionKind = "time", taxonInclusion = "single",
    geographicCoverage = sprintf("%d NEON terrestrial sites in the contiguous United States and Alaska; grid coordinates in neon_2026_smallmammals_count__units (as published by NEON)", uniqueN(sp_long$unit_site)),
    temporalCoverage = sprintf("%s/%s", min(sp_long$date), max(sp_long$date)),
    coordinatesCoarsened = NA,
    covariateNote = "unit_sex is the modal sex over the animal's captures (U when never sexed); obs_weight_g (grams, spring scale), obs_life_stage and obs_recapture_flag (NEON technician's Y/N/U) are present on capture rows and NA otherwise; obs_traps_set and obs_grid_method describe the night's trapping as in the count table. __periods lists the bouts this species has rows in; the count table's __periods is the full list with the same indices.",
    designNote = sprintf("Robust-design capture-recapture (survival, temporary emigration, abundance per bout); rows begin at the home grid's first surveyed bout in the release (E4.4: wild-caught animals of unknown age; zeros before first capture, which unit_first_capture dates; drop earlier rows to condition on first capture) and run to the %s. A replaced tag is relabelled to its replacement, so one animal is one unit (%d old tags, %d captures). A tag whose captures carry two species labels is assigned the modal label (n_species_labels in __units). Captures of a marked animal on a grid other than its home grid are not shipped (%d across all species).", ROW_RULE, nrow(rp), n_relabel, nrow(away)),
    components = list(siblings = paste0("neon_2026_smallmammals_count (grid-night counts, grid coordinates, full __periods)", if (nzchar(others)) paste0("; ", others) else "")),
    notes = sprintf("Histories start at the home grid's first surveyed bout (E4.4), not at first capture; drop rows before unit_first_capture to condition on it. Unmarked animals (provisional ids) are in the count table's y but not here. Ear-tag numbers are domain-level; %d numbers appear with both L and R prefixes across the deposit and are kept as separate units. %d tag-nights across the deposit carried the same tag in two traps and count as one capture.", lr_both, dup_night),
    notShipped = list(
      `other species` = sprintf("the %d species not among the %d with the most marked individuals (individuals in parentheses): %s", nrow(species) - nrow(ship), nrow(ship), below),
      `unmarked captures` = paste0(mark_n[grepl("provisional", mark), paste0(mark, ": ", N, collapse = "; ")], " (all species; in the count table's y)"),
      `captures not at species rank` = sprintf("%d marked-animal captures identified to genus, species group, subspecies, family, order or class (all species)", nrow(cap[mark %in% c("ear tag", "PIT tag") & taxonRank != "species"])),
      `captures away from the home grid` = sprintf("%d (all species)", nrow(away)),
      `measurements and samples` = "hindfootLength, earLength, tailLength, totalLength, ticks, blood/ear/hair/fecal samples, reproductive condition",
      `other NEON tables` = "mam_voucher, mam_identificationHistory, mam_voucherIdentificationHistory"))
  ds <- write_table(sp_long, s$table, dataset, taxa = taxa, periods = sp_periods, units = sp_units, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("Robust-design capture histories of %s ear- or PIT-tagged %s on %d NEON Sherman-trap grids at %d sites across the United States, %d-%d: one row per individual x surveyed night of its home grid from the grid's first bout on (bout = period, night = occasion), y = captured, with sex, weight, life stage, traps set and grid method. One of %d species tables from the same deposit.",
                          format(s$n_individuals, big.mark = ","), s$scientificName, uniqueN(sp_long$cluster_id), uniqueN(sp_long$unit_site), min(sp_periods$year), max(sp_periods$year), nrow(ship)),
    url = sprintf("https://data.neonscience.org/data-products/%s/%s", PRODUCT, RELEASE),
    reference = sprintf("NEON (National Ecological Observatory Network). Small mammal box trapping (%s), %s. %s", PRODUCT, RELEASE, DOI),
    doi_paper = "", doi_data = sub("https://doi.org/", "", DOI),
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = sprintf("Rows from the home grid's first bout (E4.4, unknown age) to the %s; replaced tags merged. One script writes %d species tables (ruling #20). Sibling: neon_2026_smallmammals_count (grid counts, coordinates).", ROW_RULE, nrow(ship)),
    source_via = "NEON Data API (RELEASE-2026 basic package)")
  stage_tag_row(s$table, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture (survival, temporary emigration)",
    sampling_protocol = "live_trap", design = sprintf("Robust design (%d bouts x 1-3 trap-nights)", nrow(sp_periods)), realm = "Terrestrial",
    country = "USA", coordinates = "None in source (grid coordinates in the sibling count table)",
    notes = "Individuals as unit, home grid as cluster_id; histories start at the grid's first bout (zeros before first capture); unmarked animals excluded; one species per table.", status = "tagged")
  invisible(ds)
}
for (k in seq_len(nrow(ship))) build(k)
