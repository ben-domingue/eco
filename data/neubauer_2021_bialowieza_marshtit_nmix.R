#!/usr/bin/env Rscript
# Table:  neubauer_2021_bialowieza_marshtit_nmix
# Source: Dryad doi:10.5061/dryad.3bk3j9kkv, version 4 (2021-11-05), CC0 1.0 (as shown on the Dryad page).
#   Neubauer, G., Wolska, A., Rowinski, P. & Wesolowski, T. (2021). Data from: N-mixture models estimate
#   abundance reliably: a field test on Marsh Tit using time-for-space substitution. Dryad.
# Paper:  Neubauer, G., Wolska, A., Rowinski, P. & Wesolowski, T. (2022). N-mixture models estimate abundance
#         reliably: a field test on Marsh Tit using time-for-space substitution. Ornithological Applications
#         124(1), duab054, doi:10.1093/ornithapp/duab054. From the abstract and readme: four permanent plots in
#         the strictly protected part of Bialowieza National Park, Poland, each counted six times every spring
#         (April-May) from 1987 to 2019; the true number of breeding pairs per plot-year comes from an
#         exhaustive population study (territory mapping and nest searching), not from the counts.
# Data:   pl_nc_v5_1987-2019.txt (tab): Powierzchnia (plot CM / K / MS / WW), Rok (year), Area (ha), 1..6 =
#           singing males counted in survey 1..6. 132 rows = 4 plots x 33 years, no NA.
#         countersinging.txt (tab): rok, pow (plot c / k / ms / w), c1..c6 = countersinging events recorded in
#           survey 1..6, m1..m6 = males involved in them, Total_cases / Total_males = their season sums.
#         True_state.txt (tab): year, plot (c / k / ms / w), NpairsWithin (pairs breeding within the plot, half
#           pairs for territories straddling the boundary), Npairsmax (pairs within plus adjacent).
#         The R code files listed in the readme are on Zenodo (doi:10.5281/zenodo.5585708), not in this version.
#         Checked: every plot x year has one row in each file, plot codes map one to one (CM=c, K=k, MS=ms,
#         WW=w), area is constant within a plot, Total_males equals the sum of m1..m6, and Total_cases equals the sum
#         of c1..c6 except at WW 2004 (11 vs 4) and CM 2011 (3 vs 1); the per-survey values ship, the totals do not.
# Mapping (N-mixture, repeated counts, multi-season): unit = plot, period = year (1987 = 1 ... 2019 = 33;
#   year in __periods), occasion = survey 1..6, y = singing males counted. Survey evidence: deposited_matrix
#   (the counts file has all six surveys for every plot-year and no NA). unit_area_ha = plot area.
#   obs_countersinging_events = c_k and obs_countersinging_males = m_k (recorded at the survey; the paper uses
#   the events as a detection covariate). period_pairs_within / period_pairs_with_adjacent = the true state from
#   the independent population study (a field census, not a model estimate and not derived from these counts),
#   constant within plot x year. Survey dates are not deposited. Marsh Tit is LC; no coordinates deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "neubauer_2021_bialowieza_marshtit_nmix"
dir <- download_dryad("10.5061/dryad.3bk3j9kkv", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

nc <- fread(file.path(dir, "pl_nc_v5_1987-2019.txt"))
cs <- fread(file.path(dir, "countersinging.txt"))
ts <- fread(file.path(dir, "True_state.txt"))
stopifnot(identical(names(nc), c("Powierzchnia", "Rok", "Area", as.character(1:6))),
          identical(names(cs), c("rok", "pow", paste0("c", 1:6), paste0("m", 1:6), "Total_cases", "Total_males")),
          identical(names(ts), c("year", "plot", "NpairsWithin", "Npairsmax")),
          nrow(nc) == 132, nrow(cs) == 132, nrow(ts) == 132, !anyNA(nc), !anyNA(cs), !anyNA(ts))
code <- c(c = "CM", k = "K", ms = "MS", w = "WW")
cs[, plot := code[pow]]; ts[, plot := code[plot]]
stopifnot(!anyNA(cs$plot), !anyNA(ts$plot), setequal(unique(nc$Powierzchnia), code),
          !anyDuplicated(nc[, .(Powierzchnia, Rok)]), all(table(nc$Powierzchnia) == 33), identical(sort(unique(nc$Rok)), 1987:2019),
          nc[, uniqueN(Area), by = Powierzchnia][, all(V1 == 1)],
          identical(cs[Total_cases != rowSums(cs[, paste0("c", 1:6), with = FALSE]), paste(rok, pow)], c("2004 w", "2011 c")),
          all(cs$Total_males == rowSums(cs[, paste0("m", 1:6), with = FALSE])))
setkey(nc, Powierzchnia, Rok)
cs <- cs[nc[, .(Powierzchnia, Rok)], on = c(plot = "Powierzchnia", rok = "Rok")]
ts <- ts[nc[, .(Powierzchnia, Rok)], on = c(plot = "Powierzchnia", year = "Rok")]
stopifnot(!anyNA(cs$c1), !anyNA(ts$NpairsWithin))

long <- rbindlist(lapply(1:6, function(k) data.table(
  unit = nc$Powierzchnia, taxon = "POEPAL", y = nc[[as.character(k)]], period = nc$Rok - 1986L, occasion = k,
  unit_area_ha = nc$Area, period_pairs_within = ts$NpairsWithin, period_pairs_with_adjacent = ts$Npairsmax,
  obs_countersinging_events = cs[[paste0("c", k)]], obs_countersinging_males = cs[[paste0("m", k)]])))
stopifnot(all(long$y >= 0), all(long$y == round(long$y)), nrow(long) == 4 * 33 * 6)
stopifnot(sum(long$obs_countersinging_males > long$y) == 62)   # males in countersinging bouts can exceed the count (bouts with birds outside the plot, presumably); shipped as recorded
long <- order_eco(long)

taxa <- make_taxa("POEPAL", "Poecile palustris", vernacularName = "Marsh Tit")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
periods <- data.table(period = 1:33, year = 1987:2019, season = "April-May")

dataset <- list(
  title = "Repeated counts of singing Marsh Tit males on four plots in Bialowieza National Park, Poland, 1987-2019, with the breeding pairs from an independent census",
  creator = "Neubauer, Grzegorz; Wolska, Alicja; Rowinski, Patryk; Wesolowski, Tomasz", pubDate = "2021",
  doi = "10.5061/dryad.3bk3j9kkv", sourceURL = "https://doi.org/10.5061/dryad.3bk3j9kkv",
  citation = "Neubauer, G., Wolska, A., Rowinski, P., & Wesolowski, T. (2021). Data from: N-mixture models estimate abundance reliably: a field test on Marsh Tit using time-for-space substitution [Dataset]. Dryad. https://doi.org/10.5061/dryad.3bk3j9kkv",
  paperDOI = "10.1093/ornithapp/duab054",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Six springtime counts of singing Marsh Tit males per year on four permanent plots (24-33 ha) in the strictly protected primaeval forest of Bialowieza National Park, 1987-2019, with countersinging events per survey and the true number of breeding pairs from an exhaustive population study, used to test binomial N-mixture abundance estimates against known abundance.",
  samplingProtocol = "Six whole-plot counts of singing males per plot each April-May; the true number of pairs per plot-year comes from intensive territory mapping and nest searching on the same plots.",
  samplingProtocolCode = "site_count",
  surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "closed", occasionKind = "time",
  closureNote = "Closed within a breeding season (April-May); open between years.",
  taxonInclusion = "single",
  geographicCoverage = "Bialowieza National Park, Poland (no coordinates deposited)", temporalCoverage = "1987/2019",
  notShipped = list(`Total_cases, Total_males` = "season sums of the per-survey countersinging columns, which ship; Total_cases disagrees with the per-survey sum at WW 2004 and CM 2011",
                    `R code` = "on Zenodo (doi:10.5281/zenodo.5585708), not data"),
  notes = "The paper treats plot-year as the site (time-for-space substitution); here unit = plot and period = year, so either view can be recovered. period_pairs_within counts half pairs for boundary territories.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/neubauer_2021_bialowieza_marshtit_nmix.R")

stage_dict_row(TABLE,
  description = "Six repeated counts of singing Marsh Tit males per spring on four permanent plots in Bialowieza National Park, Poland, 1987-2019, with countersinging per survey and the true number of breeding pairs per plot-year from an independent census.",
  url = "https://doi.org/10.5061/dryad.3bk3j9kkv",
  reference = "Neubauer, G., Wolska, A., Rowinski, P., & Wesolowski, T. (2022). N-mixture models estimate abundance reliably: a field test on Marsh Tit using time-for-space substitution. Ornithological Applications, 124(1), duab054.",
  doi_paper = "10.1093/ornithapp/duab054", doi_data = "10.5061/dryad.3bk3j9kkv",
  original_license = "CC0 1.0", derived_license = "CC0-1.0",
  notes = "Known-truth N-mixture benchmark: breeding pairs per plot-year as period_ covariates. Fetched as the Dryad version zip.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture",
  sampling_protocol = "site_count", design = "Multi-season (33 years x 6 counts)", realm = "Terrestrial", country = "POL",
  coordinates = "None in source", notes = "Four plots only (below the 30-unit floor); 33 years. True abundance from territory mapping ships as period_pairs_within.", status = "tagged")
