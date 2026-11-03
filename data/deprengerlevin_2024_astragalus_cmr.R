#!/usr/bin/env Rscript
# Tables: deprengerlevin_2024_astragalus_msrd (multi-state robust design, 2013-2015, within-season
#         visits) and deprengerlevin_2024_astragalus_ms (multi-state annual census histories,
#         1995-2022): one deposit, two survey designs, one script.
# Source: Dryad doi:10.5061/dryad.pzgmsbcxp, version 333127 (published 2024-12-09), licence CC0 1.0 (as
#         shown on Dryad). DePrenger-Levin, M., Dawson, C., Grant III, T. & Wunder, M. Imperfect detection
#         in plant populations can cause misestimates of demographic rates and missed population trends:
#         the case for Astragalus microcymbus. Analysis code: Zenodo doi:10.5281/zenodo.14254219 (CC0;
#         MPM_and_Mark-Recapture_-_2024.Rmd), read for the design, not used.
# Paper:  DePrenger-Levin, M. et al. (2025). Imperfect detection in plant populations can cause
#         misestimates of demographic rates and missed population trends. Journal of Applied Ecology.
#         doi:10.1111/1365-2664.14862
# Data:   dataCJS3yrs.Rdata, object dataCJS (tibble, 9,345 rows): one row per tagged plant x visit
#         2013-2015: Day (day of year), Year, Site, Plot, Tag (numeric; some tags carry a decimal for
#         a plant added under an existing tag), Ln (longest stem, cm), Fl (1 flowers or fruit, 0 none),
#         Fr (fruits), Br (browsed), Comments, encounter (the day binned into ten encounter periods per
#         year; each encounter is one day in a year, asserted), PlotTag, Obs (0/1). 2013 records
#         every tagged plant at every plot visit (Obs = 0 rows); 2014 and 2015 record only plants found
#         (4 and 0 Obs = 0 rows), so the not-found visits are absent. 17 plant-visits have two rows.
#         asmi.rdata, object asmi.all2 (18,147 rows): annual stage-fate rows for tagged plants in 30 plots
#         at 6 sites, 1995-2022: tag, year, length, fruits, stage (seedling, vegetative, reproductive,
#         dormant), plot, site, fenced (y/n, plot-year), browse, length1 and fate (stage in year + 1, or
#         dead). Per the README a stage is "dormant" when no above-ground growth was seen that year but
#         the plant was seen in an earlier and a later year: the source infers it from later sightings.
#         "dead" is likewise inferred (never seen again). fate(t) equals stage(t + 1) wherever both
#         exist (asserted).
#
# Ruling for this batch (2026-11-02): y records only what was observed above ground; a dormant state
#   the source infers from later sightings is not an observation, so it is y = 0 with the source's
#   code in y_raw.
#
# Mapping, deprengerlevin_2024_astragalus_msrd (E9 core, multi-state robust design; individual
#   units, as chabanne_2017_perth_dolphin_msrd): unit = plant (plot_tag), taxon = ASTMIC,
#   period = year 1..3 (2013-2015), occasion = encounter period 1..10 (the source's within-year bins;
#   only those visited occur), date = Year + Day, cluster_id = plot, unit_site. y = 0 not found above
#   ground, 1 vegetative (found, no flowers or fruit), 2 reproductive (Fl = 1), 3 found, reproductive
#   status not recorded (Fl missing). y_raw = the source's code: V, R, F (found, Fl missing), 0 for a
#   deposited not-found row, empty where the source has no row (an inferred not-found).
#   Survey set (inferred, the authors' own rule in the Zenodo code): a plot was visited at an
#   encounter iff any plant of that plot has a row at that encounter (their `plotssurveyed` table);
#   every plant tagged in the plot (anywhere in 2013-2015) is a survey row at every visit of its
#   plot in all three years, 0 where it has no row (their tidyr::complete(..., fill = "0")), rows
#   before first detection included (E2). Two rows for one plant-visit (17) are one visit: y = the
#   highest state, covariates from the reproductive (or first) record.
#   obs_: length_cm, fruits, browsed (from the plant's row; NA where there is none), comment.
# Mapping, deprengerlevin_2024_astragalus_ms (E9 core, multi-state CJS / Pradel; individual units):
#   unit = tag, taxon = ASTMIC, period = year 1..28 (1995-2022), no occasion. y = 0 not seen above
#   ground (source stage or fate dormant or dead, or no observation), 1 seedling, 2 vegetative, 3 reproductive. y_raw = the source's stage or fate
#   label for the year, empty where the source has none.
#   The observation for plant-year t is the stage of the t row, or else the fate of the t - 1 row:
#   a year-t row exists only when the t -> t+1 transition was recorded, so a plot's last census
#   (e.g. plot 89 in 2019) and single missing years appear only as fates (3,765 plant-years).
#   Survey set (inferred): a plot was censused in a year iff any of its plants has an observation
#   then (stage or fate, including the source's dormant and dead); spans are contiguous (asserted):
#   from 1995 (plots 238 and 300 from 1996, 598 from 2004, the 11 Cebolla Creek plots at sites 1-2
#   from 2014, as the authors' code states) to 2022, except plots 581, 89 and 578, last censused in
#   2011, 2019 and 2020. Every plant of a plot is a row in every census year of its plot, 0 where it
#   has no observation, rows before first sighting included (E2). The authors' Pradel layout fills
#   zeros over 1995-2022 for every plot; the three plots are not extended here, because nothing in
#   the deposit shows they were censused later.
#   period_fenced (plot-year), obs_length_cm, obs_fruits, obs_browsed, cluster_id = plot, unit_site.
# No coordinates are deposited (A. microcymbus is ESA-listed endangered); nothing to coarsen.
# Not shipped: length1 and fate except as y_raw (they duplicate the next year's row); the 2023 fates
#   of 2022 rows (a 2023 period would contain no plants first found in 2023, because the stage-fate
#   file has no 2023 rows); one tag (3947) recorded only as dormant (no above-ground observation,
#   an all-zero history).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/deprengerlevin_2024_astragalus_cmr.R"
CACHE <- "deprengerlevin_2024_astragalus_msrd"
T1 <- "deprengerlevin_2024_astragalus_msrd"; T2 <- "deprengerlevin_2024_astragalus_ms"
dir <- download_dryad("10.5061/dryad.pzgmsbcxp", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
e <- new.env()
stopifnot(identical(load(file.path(dir, "dataCJS3yrs.Rdata"), envir = e), "dataCJS"),
          identical(load(file.path(dir, "asmi.rdata"), envir = e), "asmi.all2"))
d <- as.data.table(e$dataCJS); a <- as.data.table(e$asmi.all2)

taxa <- make_taxa("ASTMIC", "Astragalus microcymbus", vernacularName = "Skiff milkvetch",
                  taxon_family = "Fabaceae", taxon_status = "ESA endangered (US)", taxon_iucnCategory = "NE")
common <- list(
  creator = "DePrenger-Levin, Michelle; Dawson, Carol; Grant III, Thomas; Wunder, Michael", pubDate = "2024",
  doi = "10.5061/dryad.pzgmsbcxp", sourceURL = "https://doi.org/10.5061/dryad.pzgmsbcxp",
  citation = "DePrenger-Levin, M., Dawson, C., Grant III, T., & Wunder, M. (2024). Imperfect detection in plant populations can cause misestimates of demographic rates and missed population trends: the case for Astragalus microcymbus [Dataset]. Dryad. https://doi.org/10.5061/dryad.pzgmsbcxp",
  paperDOI = "10.1111/1365-2664.14862", relatedWorks = c("10.5281/zenodo.14254219"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocolCode = "marked_plant_census", responseType = "state", unitKind = "individual",
  geographicCoverage = "Gunnison Basin, Colorado, USA: 3-m-radius circular plots at six sites (no coordinates deposited; the species is ESA-listed)",
  coordinatesCoarsened = NA)

## ---- table 1: robust design 2013-2015 ------------------------------------------------------
stopifnot(nrow(d) == 9345L, all(d$Year %in% 2013:2015), all(d$Obs %in% 0:1), all(d$encounter %in% 1:10),
          setequal(unique(d$Site), c(1, 2, 5, 15, 19, 26)), all(d[, uniqueN(Day), by = .(Year, encounter)]$V1 == 1L),
          all(d[, uniqueN(Site), by = Plot]$V1 == 1L),
          all((d$Obs == 1) == (d$Ln > 0)), all(d[Obs == 1, Fl %in% c(0L, 1L, NA)]), all(d[Obs == 0, Fl %in% c(0L, NA)]))
stopifnot(identical(as.integer(d[, sum(Obs == 0), by = Year][order(Year), V1]), c(1281L, 4L, 0L)))
d[, unit := paste0(Plot, "_", as.character(Tag))]
stopifnot(uniqueN(d$unit) == uniqueN(d$PlotTag), all(d[, uniqueN(PlotTag), by = unit]$V1 == 1L))
d[, state := fifelse(Obs == 0, 0L, fifelse(is.na(Fl), 3L, fifelse(Fl == 1L, 2L, 1L)))]
d[, code := fifelse(Obs == 0, "0", fifelse(is.na(Fl), "F", fifelse(Fl == 1L, "R", "V")))]
d[, comment := fifelse(is.na(Comments) | trimws(Comments) == "", NA_character_, trimws(Comments))]
setorder(d, unit, Year, encounter, -state)
nd <- d[, .N, by = .(unit, Year, encounter)]; stopifnot(sum(nd$N > 1) == 17L, max(nd$N) == 2L)
v1 <- d[, .SD[1], by = .(unit, Year, encounter)]                 # highest state first
visits <- unique(d[, .(Plot, Site, Year, encounter, Day)])
plants <- unique(d[, .(unit, Plot)])
grid <- merge(plants, visits, by = "Plot", allow.cartesian = TRUE)
grid <- merge(grid, v1[, .(unit, Year, encounter, state, code, Ln, Fr, Br, comment)], by = c("unit", "Year", "encounter"), all.x = TRUE)
stopifnot(nrow(v1) == nrow(d) - 17L, all(v1$unit %in% plants$unit), nrow(grid[!is.na(code)]) == nrow(v1))
long1 <- grid[, .(unit, taxon = "ASTMIC", y = fifelse(is.na(state), 0L, state), y_raw = code,
                  period = as.integer(Year - 2012), occasion = as.integer(encounter),
                  date = as.character(as.IDate(sprintf("%d-01-01", Year)) + Day - 1L), cluster_id = as.character(Plot),
                  obs_length_cm = Ln, obs_fruits = Fr, obs_browsed = Br, obs_comment = comment, unit_site = as.integer(Site))]
long1 <- order_eco(long1)
stopifnot(!anyDuplicated(long1[, .(unit, period, occasion)]), sum(long1$y > 0) == sum(v1$state > 0),
          uniqueN(long1$unit) == 1970L, all(long1$y %in% 0:3))
cat(sprintf("  robust design: %d plants, %d plot-visits, %d rows (%d found, %d deposited not-found, %d inferred not-found)\n",
            uniqueN(long1$unit), nrow(visits), nrow(long1), sum(long1$y > 0), sum(long1$y_raw == "0", na.rm = TRUE), sum(is.na(long1$y_raw))))
periods1 <- data.table(period = 1:3, year = 2013:2015,
                       encounters = visits[, paste(sort(unique(encounter)), collapse = ","), by = Year][order(Year), V1],
                       first_date = long1[, min(date), by = period][order(period), V1],
                       last_date = long1[, max(date), by = period][order(period), V1],
                       n_plots = visits[, uniqueN(Plot), by = Year][order(Year), V1])
ds1 <- write_table(long1, T1, c(common, list(
  title = "Multi-state robust-design histories of 1,970 tagged Astragalus microcymbus plants, Gunnison Basin, Colorado, 2013-2015",
  abstract = "Within-season visits (up to ten encounter periods per year, March to October) to permanently tagged plants of the endangered skiff milkvetch in 18 (2013) and 28 (2014-2015) plots at six sites. y = the plant's observed above-ground state at the visit: 0 not found (vegetative dormancy or missed), 1 vegetative, 2 reproductive (flowers or fruit), 3 found, status not recorded. The paper fits a Huggins closed robust design with multi-state probabilities to these visits.",
  samplingProtocol = "Tagged plants (10-inch nails and numbered metal tags) in 3-m-radius circular plots searched at each visit; stem length, flowering or fruiting, fruit count and browsing recorded for each plant found.",
  surveyEvidence = "inferred",
  surveyEvidenceNote = "2013 records every tagged plant at every plot visit (deposited zeros, y_raw = 0); 2014 and 2015 record only plants found. A plot was visited at an encounter iff any of its plants has a row then, and every plant tagged in the plot in 2013-2015 is a row at every visit of its plot in all three years, 0 where the plant has no row (y_raw empty). This is the authors' own layout (tidyr::complete with fill 0 and their plotssurveyed table, Zenodo code). Rows before a plant's first detection are kept (E2).",
  closure = "occasion within period (robust design: closed within a growing season, open between years); the plant's flowering state changes within a season (the authors assign a season-level stratum, R if ever reproductive)",
  stateCodes = list(`0` = "not found above ground at the visit", `1` = "vegetative (found, no flowers or fruit)", `2` = "reproductive (flowers or fruit)", `3` = "found, reproductive status not recorded"),
  temporalCoverage = "2013-03/2015-10",
  occasionCodes = list(note = "occasion = the source's encounter period (1-10), a fixed within-year calendar bin; only visited bins occur"),
  designNote = "The authors restrict the robust design to sites 5, 15, 19 and 26 (the Cebolla Creek sites 1 and 2 enter in 2014); all six are shipped, with unit_site. Their season-level stratum (R if ever reproductive that year) is a derived collapse of y here.",
  notes = "Individual ids are plot_tag; decimal tags (e.g. 6.1) are plants added under an existing tag. 17 plant-visits with two rows are one visit (y = the higher state, covariates from that row). obs_comment is the field comment as recorded (browsing, cotyledons, 'missed'). The July visit of each year is also the annual census of deprengerlevin_2024_astragalus_ms; plant ids are not linked between the two files.",
  components = list(T2))),
  taxa = taxa, periods = periods1, script = SCRIPT)
stage_dict_row(T1,
  description = "Multi-state closed robust design histories of 1,970 tagged plants of the endangered Astragalus microcymbus in 28 plots in Colorado, 2013-2015: up to ten within-season visits per year, y = observed above-ground state (not found, vegetative, reproductive).",
  url = "https://doi.org/10.5061/dryad.pzgmsbcxp",
  reference = "DePrenger-Levin, M., Dawson, C., Grant III, T., & Wunder, M. (2025). Imperfect detection in plant populations can cause misestimates of demographic rates and missed population trends. Journal of Applied Ecology.",
  doi_paper = "10.1111/1365-2664.14862", doi_data = "10.5061/dryad.pzgmsbcxp", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Survey set inferred for 2014-2015 (only found plants recorded) by the authors' plot-visit rule. Companion of deprengerlevin_2024_astragalus_ms.",
  source_via = "Dryad")
stage_tag_row(T1, ds1, taxon_group = "Plants", model_family = "Multi-state closed robust design capture-recapture (vegetative dormancy)",
  sampling_protocol = "marked_plant_census", design = "Robust design (3 years x up to 10 within-season visits)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "First plant robust design; dormancy is unobservable (y = 0). Survey set inferred for 2014-2015.", status = "tagged")

## ---- table 2: annual census 1995-2022 ------------------------------------------------------
stopifnot(nrow(a) == 18147L, !anyDuplicated(a[, .(tag, year)]), all(a[, uniqueN(plot), by = tag]$V1 == 1L),
          all(a[, uniqueN(site), by = plot]$V1 == 1L), range(a$year) == c(1995L, 2022L), uniqueN(a$plot) == 30L,
          identical(levels(a$stage), c("seedling", "vegetative", "reproductive", "dormant")),
          identical(levels(a$fate), c("seedling", "vegetative", "reproductive", "dormant", "dead")),
          all(a[stage == "dormant", length == 0]), all(a$fenced %in% c("y", "n")), all(a[, uniqueN(fenced), by = .(plot, year)]$V1 == 1L))
setorder(a, tag, year)
a[, `:=`(nyr = shift(year, -1L), nst = shift(as.character(stage), -1L)), by = tag]
stopifnot(all(a[!is.na(nyr) & nyr == year + 1L, as.character(fate) == nst]), all(a[!is.na(nyr), fate != "dead"]))
ag <- a[, .(ag = any(stage != "dormant")), by = tag]; stopifnot(identical(ag[ag == FALSE, tag], 3947L))
a <- a[tag != 3947L]
# observation per plant-year: the stage of the year's row, or else the fate of the previous year's row
# (a year-t row exists only when the t -> t+1 transition was recorded, so a plot's last census and
# some single years appear only as fates)
ob <- rbind(a[, .(tag, plot, site, year, lab = as.character(stage), src = "stage")],
            a[, .(tag, plot, site, year = year + 1L, lab = as.character(fate), src = "fate")])
ob <- ob[order(tag, year, src != "stage")][, .SD[1], by = .(tag, year)]       # stage row wins (they agree, asserted above)
ob <- ob[year <= 2022L]
stopifnot(nrow(ob[src == "stage"]) == nrow(a))
census <- unique(ob[, .(site, plot, year)])                                    # a plot was censused in a year iff a plant has an observation then
pspan <- census[, .(first = min(year), last = max(year), n = .N), by = .(site, plot)]
stopifnot(all(pspan[site %in% c(5, 15, 19, 26) & !plot %in% c(238, 300, 598), first] == 1995L),
          all(pspan[plot %in% c(238, 300), first] == 1996L), pspan[plot == 598, first] == 2004L,
          all(pspan[site %in% 1:2, first] == 2014L),
          identical(pspan[last < 2022L][order(plot), .(plot, last)], data.table(plot = c(89L, 578L, 581L), last = c(2019L, 2020L, 2011L))),
          all(pspan[, n == last - first + 1L]))                                # no gap years within a plot's span
fen <- unique(a[, .(plot, year, fenced)])
census <- merge(census, fen, by = c("plot", "year"), all.x = TRUE)
pl_tags <- unique(a[, .(tag, plot)])
g <- merge(pl_tags, census, by = "plot", allow.cartesian = TRUE)
g <- merge(g, ob[, .(tag, year, lab, src)], by = c("tag", "year"), all.x = TRUE)
g <- merge(g, a[, .(tag, year, length, fruits, browse)], by = c("tag", "year"), all.x = TRUE)
stopifnot(nrow(g[!is.na(lab)]) == nrow(ob))
smap <- c(seedling = 1L, vegetative = 2L, reproductive = 3L, dormant = 0L)
long2 <- g[, .(unit = as.character(tag), taxon = "ASTMIC", y = fifelse(is.na(lab), 0L, unname(c(smap, dead = 0L)[lab])),
               y_raw = lab, period = year - 1994L, cluster_id = as.character(plot),
               period_fenced = as.integer(fenced == "y"), obs_length_cm = length, obs_fruits = fruits,
               obs_browsed = as.integer(browse), unit_site = site)]
long2 <- order_eco(long2)
stopifnot(!anyDuplicated(long2[, .(unit, period)]), uniqueN(long2$unit) == 4042L, !anyNA(long2$y),
          sum(long2$y > 0) == ob[lab %in% names(smap)[1:3], .N], sum(long2$y_raw == "dead", na.rm = TRUE) == ob[lab == "dead", .N])
cat(sprintf("  annual: %d plant-years observed only through the previous row's fate\n", ob[src == "fate", .N]))
cat(sprintf("  annual: %d plants, %d plot-years, %d rows (%d seen above ground, %d source-dormant, %d source-dead, %d no source row)\n",
            uniqueN(long2$unit), nrow(census), nrow(long2), sum(long2$y > 0), sum(long2$y_raw == "dormant", na.rm = TRUE),
            sum(long2$y_raw == "dead", na.rm = TRUE), sum(is.na(long2$y_raw))))
periods2 <- data.table(period = 1:28, year = 1995:2022, n_plots = census[, .N, by = year][order(year), N],
                       n_plots_fenced = census[, sum(fenced == "y", na.rm = TRUE), by = year][order(year), V1])
ds2 <- write_table(long2, T2, c(common, list(
  title = "Annual multi-state census histories of 4,042 tagged Astragalus microcymbus plants in 30 plots, Colorado, 1995-2022",
  abstract = "Every July since 1995, all plants of the endangered skiff milkvetch in 3-m-radius plots at four (from 2014 six) sites were tagged and their stage recorded. y = the stage observed above ground that year (0 not seen, 1 seedling, 2 vegetative, 3 reproductive). The source's inferred dormant stage (no growth seen but the plant seen before and after) and inferred death are kept in y_raw and are y = 0, so the table is the observation record a Pradel or multi-state CJS model needs, with vegetative dormancy unobservable.",
  samplingProtocol = "Annual census during fruiting (late July) of all plants in 3-m-radius circular plots; plants marked with 10-inch nails and numbered metal tags; stem length, fruits and browsing recorded; plots fenced against mammal browsing in some years.",
  surveyEvidence = "inferred",
  surveyEvidenceNote = "A plant-year observation is the stage of that year's row or, failing that, the fate of the previous year's row (a row exists only when the next year's transition was recorded, so a plot's last census and some single years appear only as fates). A plot was censused in a year iff any of its plants has an observation then (including the source's dormant and dead); spans are contiguous, from 1995 (238 and 300 from 1996, 598 from 2004, sites 1-2 from 2014) to 2022, except plots 581, 89 and 578 (last censused 2011, 2019, 2020). Every plant of a plot is a row in every census year of the plot, 0 where it has no observation (y_raw empty); rows before first sighting are kept (E2). The authors' Pradel layout instead fills zeros over 1995-2022 for all plots.",
  closure = "period (one census per year; survival, recruitment and stage transitions between years)",
  stateCodes = list(`0` = "not seen above ground (y_raw dormant = source-inferred dormancy; dead = source-inferred death; empty = no source observation)", `1` = "seedling", `2` = "vegetative", `3` = "reproductive (flowers or fruit)"),
  temporalCoverage = "1995/2022",
  designNote = "Ruling 2026-11-02: y records only what was observed above ground; the source's dormant code, inferred from later sightings, goes in y_raw.",
  notes = "Individual ids are the source's tag numbers (unique across plots, asserted). 22 rows with an above-ground stage have stem length 0 as recorded. obs_length_cm, obs_fruits and obs_browsed come from the source row (NA where there is none; fruits NA for 250 dormant rows). period_fenced = plot fenced against mammals that year (NA in a plot's last census year, known only from fates). Plant ids are not linked to deprengerlevin_2024_astragalus_msrd.",
  components = list(T1),
  notShipped = list(`2023 fates` = "fate of 2022 rows (the 2023 census): the stage-fate file has no 2023 rows, so plants first found in 2023 are absent and a 2023 period would be incomplete",
                    length1 = "next year's stem length, duplicated in the next row",
                    `tag 3947` = "recorded only as dormant in five years, never above ground: an all-zero history"))),
  taxa = taxa, periods = periods2, script = SCRIPT)
stage_dict_row(T2,
  description = "Annual census histories (1995-2022) of 4,042 tagged plants of the endangered Astragalus microcymbus in 30 plots in the Gunnison Basin, Colorado: observed stage (seedling, vegetative, reproductive, not seen); the source's inferred dormancy and death kept as y_raw.",
  url = "https://doi.org/10.5061/dryad.pzgmsbcxp",
  reference = "DePrenger-Levin, M., Dawson, C., Grant III, T., & Wunder, M. (2025). Imperfect detection in plant populations can cause misestimates of demographic rates and missed population trends. Journal of Applied Ecology.",
  doi_paper = "10.1111/1365-2664.14862", doi_data = "10.5061/dryad.pzgmsbcxp", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Stage-fate data reshaped to annual histories; dormancy (unobservable) is y = 0 with the source code in y_raw (batch ruling 2026-11-02). Survey set inferred (plots censused annually from establishment).",
  source_via = "Dryad")
stage_tag_row(T2, ds2, taxon_group = "Plants", model_family = "Multi-state CJS capture-recapture (vegetative dormancy; Pradel in the paper)",
  sampling_protocol = "marked_plant_census", design = "Multi-session (28 annual censuses, no secondary)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "28-year plant demography; dormant and dead are source inferences kept in y_raw.", status = "tagged")
