#!/usr/bin/env Rscript
# Table:  botsch_2020_tits_territory_count
# Source: Dryad, doi:10.5061/dryad.fttdz08nx, version 45264 (version 2, published 2019-12-02), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Bötsch, Y., Jenni, L. & Kéry, M.
# Paper:  Bötsch, Y., Jenni, L. & Kéry, M. (2020). Field evaluation of abundance estimates under binomial and
#         multinomial N-mixture models. Ibis 162, doi:10.1111/ibi.12802. From the Dryad abstract: conventional
#         territory mapping, three surveys in 2014 and four in 2015, of Great Tit and Eurasian Blue Tit; three
#         independent ornithologists ('territory editors') assigned territories from the same field records.
# Data:   data_CR_subsite.csv, data_DH_subsite.csv, data_YB_subsite.csv (semicolon-separated, 'na'): one file per
#           territory editor (CR, DH, YB); one row per territory the editor delineated: territory, plot (12),
#           splitplot (24 subsites, two per plot), year, observer (the field surveyor, HL or YB), species (BT, GT),
#           area (subsite area, ha), plotarea (CR and DH files only), juliandate1-4 (day of year of visit k),
#           Start.time / End.time / time (start, minutes after midnight) / duration (minutes) per visit, squared
#           terms, round1-4 (1 = the territory was recorded on visit k; 'na' for visit 4 in 2014).
#         CoeffofVar_Surveydata_Editoreffect.csv: number of territories per splitplot (1..24) x year x species for
#           each editor (Editor_1 YB, Editor_2 CR, Editor_3 DH): equal to the row counts of the files in 287 of 288
#           cells (asserted); subsite 340, Great Tit, 2015 has 2 for DH where the DH file has 5 territories (files used).
# Mapping (repeated counts, territory editors as observers; ruling 2026-11-06, E3): unit = splitplot (subsite),
#   cluster_id = plot, taxon = BT / GT, period = year (1 = 2014, 2 = 2015), occasion = visit x editor
#   ((visit - 1) x 3 + editor index, editors CR, DH, YB), observer = the editor, y = the number of the editor's
#   territories recorded on that visit (the binomial N-mixture count). obs_visit, obs_date_doy, obs_start_min,
#   obs_duration_min, obs_field_observer (the surveyor who walked the visit, the same for all editors).
#   unit_area_ha. occasionKind = [time, observer], closure = dependent (the editors share the field records).
#   surveyEvidence = sample_table: the visits of every subsite-year are the files' juliandate columns (identical
#   across territories of a subsite-year and across the three files, asserted); every subsite-year-species has at
#   least one territory in every file, so every count, zeros included, is defined.
# Not shipped: the per-territory detection histories (the multinomial N-mixture input): the counts here are their
#   sums per visit, and a territory is the editor's construct, not a unit of the survey; the squared date and time
#   terms (derivable); the editors' season totals (CoeffofVar file; equal to the territory counts but one cell, which are not a
#   per-visit observation and cover no survey the per-visit series lacks); model estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "botsch_2020_tits_territory_count"

dir <- download_dryad("10.5061/dryad.fttdz08nx", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 4)
eds <- c("CR", "DH", "YB")
f <- rbindlist(lapply(eds, function(e) {
  d <- fread(file.path(dir, sprintf("data_%s_subsite.csv", e)), sep = ";", na.strings = "na")
  if ("plotarea" %in% names(d)) d[, plotarea := NULL]
  d[, editor := e] }), use.names = TRUE)
stopifnot(identical(f[, .N, by = editor]$N, c(298L, 347L, 401L)), uniqueN(f$splitplot) == 24L, uniqueN(f$plot) == 12L,
          all(f$splitplot %/% 10L == f$plot), setequal(f$year, 2014:2015), setequal(f$species, c("BT", "GT")),
          all(f$observer %in% c("HL", "YB")),
          all(is.na(f[year == 2014]$round4)), all(is.na(f[year == 2014]$juliandate4)), !anyNA(f[year == 2015, .(round4, juliandate4)]),
          all(unlist(f[, .(round1, round2, round3)]) %in% 0:1), all(f[year == 2015]$round4 %in% 0:1))
# visit facts are per subsite-year, identical across territories, species and editors
vis_cols <- c(paste0("juliandate", 1:4), paste0("time", 1:4), paste0("duration", 1:4), "observer", "area")
stopifnot(all(f[, lapply(.SD, uniqueN), by = .(splitplot, year), .SDcols = vis_cols][, -(1:2)] == 1L))
# editors' totals file
tot <- fread(file.path(dir, "CoeffofVar_Surveydata_Editoreffect.csv"), sep = ";")
stopifnot(nrow(tot) == 96L, all(tot$Editor_1 == "YB"), all(tot$Editor_2 == "CR"), all(tot$Editor_3 == "DH"))
sp_ids <- sort(unique(f$splitplot))
cnt <- dcast(f[, .N, by = .(splitplot, year, species, editor)], splitplot + year + species ~ editor, value.var = "N", fill = 0L)
cnt[, Splitplot := match(splitplot, sp_ids)]
m <- merge(tot, cnt, by.x = c("Splitplot", "Year", "Species"), by.y = c("Splitplot", "year", "species"))
bad <- m[numberofTerritories_1 != YB | numberofTerritories_2 != CR | numberofTerritories_3 != DH]
stopifnot(nrow(m) == 96L, nrow(bad) == 1L, bad$splitplot == 340L, bad$Year == 2015L, bad$Species == "GT",
          bad$numberofTerritories_3 == 2L, bad$DH == 5L, bad$numberofTerritories_1 == bad$YB, bad$numberofTerritories_2 == bad$CR)

# per-visit counts: territories of the editor recorded on visit k
lg <- melt(f, id.vars = c("splitplot", "plot", "year", "species", "editor"), measure.vars = paste0("round", 1:4),
           variable.name = "visit", value.name = "rec")
lg <- lg[!is.na(rec)]
lg[, visit := as.integer(sub("round", "", visit))]
y <- lg[, .(y = sum(rec)), by = .(splitplot, plot, year, species, editor, visit)]
grid <- unique(f[, .(splitplot, plot, year)])[, .(visit = if (year == 2014) 1:3 else 1:4), by = .(splitplot, plot, year)]
grid <- rbindlist(lapply(c("BT", "GT"), function(sp) rbindlist(lapply(eds, function(e) grid[, .(splitplot, plot, year, visit, species = sp, editor = e)]))))
stopifnot(nrow(grid) == 24L * (3L + 4L) * 2L * 3L)
y <- y[grid, on = .(splitplot, plot, year, species, editor, visit)]
stopifnot(!anyNA(y$y))
vf <- unique(f[, c("splitplot", "year", vis_cols), with = FALSE])
vl <- rbindlist(lapply(1:4, function(k) vf[, .(splitplot, year, visit = k, obs_date_doy = get(paste0("juliandate", k)),
  obs_start_min = get(paste0("time", k)), obs_duration_min = get(paste0("duration", k)), obs_field_observer = observer,
  unit_area_ha = area)]))
y <- merge(y, vl, by = c("splitplot", "year", "visit"))
stopifnot(!anyNA(y$obs_date_doy), uniqueN(y[, .(splitplot, unit_area_ha)]) == 24L)
long <- y[, .(unit = as.character(splitplot), taxon = species, y, period = year - 2013L,
              occasion = (visit - 1L) * 3L + match(editor, eds), observer = editor, cluster_id = as.character(plot),
              unit_area_ha, obs_visit = visit, obs_date_doy, obs_start_min, obs_duration_min, obs_field_observer)]
long <- order_eco(long)
stopifnot(nrow(long) == 1008L, sum(long$y) == sum(unlist(f[, .(round1, round2, round3, round4)]), na.rm = TRUE))
cat(sprintf("  %d rows; counts sum %d\n", nrow(long), sum(long$y)))

taxa <- make_taxa(c("BT", "GT"), c("Cyanistes caeruleus", "Parus major"), vernacularName = c("Eurasian Blue Tit", "Great Tit"))
periods <- data.table(period = 1:2, year = 2014:2015, n_visits = c(3L, 4L))

dataset <- list(
  title = "Territory-mapping counts of Great Tit and Blue Tit per visit and territory editor at 24 forest subsites, Switzerland, 2014-2015",
  creator = "Bötsch, Yves; Jenni, Lukas; Kéry, Marc", pubDate = "2019",
  doi = "10.5061/dryad.fttdz08nx", sourceURL = "https://doi.org/10.5061/dryad.fttdz08nx",
  citation = "Bötsch, Y., Jenni, L., & Kéry, M. (2019). Field evaluation of abundance estimates under binomial and multinomial N-mixture models [Dataset]. Dryad. https://doi.org/10.5061/dryad.fttdz08nx",
  paperDOI = "10.1111/ibi.12802",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Conventional territory mapping of two cavity-nesting tits in 24 forest subsites (12 plots) in Switzerland, three visits in 2014 and four in 2015. Three ornithologists independently assigned territories from the same field records; for each editor the count is the number of that editor's territories recorded on a visit, the binomial N-mixture input the paper compares across editors.",
  samplingProtocol = "Territory mapping: a surveyor walked each subsite on 3 (2014) or 4 (2015) mornings in the breeding season and mapped every registration of the two species; three territory editors (CR, DH, YB) then delineated territories from the same maps, and each territory's visit-by-visit record is the editor's interpretation.",
  samplingProtocolCode = "territory_survey", surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site",
  closure = "dependent", closureNote = "occasion = visit x editor; the editors' counts of one visit are interpretations of the same field record, not independent surveys. Across visits, the authors assumed closure within a breeding season.",
  occasionKind = list("time", "observer"), taxonInclusion = "target",
  geographicCoverage = "Forest plots in Switzerland (study area of Bötsch et al., with a dense nest-box scheme); no coordinates deposited",
  temporalCoverage = "2014/2015",
  covariateNote = "observer: the territory editor. obs_visit: visit 1..4 within the year (occasion = (obs_visit - 1) x 3 + editor index, editors CR, DH, YB). obs_date_doy: day of year of the visit (the deposit's juliandate). obs_start_min: start time in minutes after midnight; obs_duration_min: minutes. obs_field_observer: the surveyor (HL or YB). unit_area_ha: subsite area.",
  notShipped = list(territory_histories = "per-territory visit records (the multinomial N-mixture input); the counts are their per-visit sums, and territories are each editor's construct",
                    squared_terms = "squared date and time columns (derivable)",
                    editor_totals = "CoeffofVar_Surveydata_Editoreffect.csv, territories per subsite-year-species and editor (equal to the files' row counts in 287 of 288 cells); covers no survey the per-visit counts lack",
                    plot_area = "plotarea (CR and DH files only; twice the subsite area)",
                    model_output = "N-mixture abundance estimates"),
  notes = "The editors' totals file gives DH 2 Great Tit territories at subsite 340 in 2015 where the DH file has 5; the file is used. One territory per editor file has no record on any visit (a delineated territory never mapped on a visit); it adds 0 to every count. The editor YB is also one of the two field surveyors.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/botsch_2020_tits_territory_count.R")
stage_dict_row(TABLE,
  description = "Per-visit territory-mapping counts of Great Tit and Eurasian Blue Tit at 24 forest subsites in Switzerland, 2014-2015, as interpreted by each of three territory editors (occasion = visit x editor).",
  url = "https://doi.org/10.5061/dryad.fttdz08nx",
  reference = "Bötsch, Y., Jenni, L., & Kéry, M. (2020). Field evaluation of abundance estimates under binomial and multinomial N-mixture models. Ibis, 162. https://doi.org/10.1111/ibi.12802",
  doi_paper = "10.1111/ibi.12802", doi_data = "10.5061/dryad.fttdz08nx",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Territory editors as observers (ruling 2026-11-06): one table, occasion = visit x editor, closure dependent; per-territory histories not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "territory_survey", design = "Multi-season (2 breeding seasons; 3-4 visits x 3 territory editors)",
  realm = "Terrestrial", country = "CHE", coordinates = "None in source",
  notes = "Territory-editor effect on counts; occasion = visit x editor.")
