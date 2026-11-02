#!/usr/bin/env Rscript
# Tables: tumursukh_2016_tost_ibex_dobs, tumursukh_2016_tost_argali_dobs
# Source: Dryad doi:10.5061/dryad.v61m2 (CC0 1.0, shown on the dataset page and in the API
#         record), version 11861 (published 2016-05-21).
#   Tumursukh, L., Suryawanshi, K. R., Mishra, C., McCarthy, T. M. & Boldgiv, B. (2016).
#   Data from: Status of the mountain ungulate prey of the endangered snow leopard Panthera
#   uncia in the Tost Local Protected Area, South Gobi, Mongolia. Dryad.
# Paper:  Tumursukh, L. et al. (2016). Oryx 50(2), 214-219. doi:10.1017/S0030605314001203.
# Data:   one zip, "Data for Editor Oryx.zip", holding four Excel 97 workbooks, one per
#         species x year: Double observer {ibex,argali} {2012,2013}.xls. Each has an
#         "Information" sheet (what the columns mean), an "Output" sheet whose columns A-C
#         list every group detected (Group Size, Observer one detections 0/1, Observer two
#         detections 0/1) and whose columns E-F hold the authors' estimates (groups seen by
#         both / by one only / by two only, estimated groups, mean group size, population,
#         variances, detection probabilities), and a "Back end calculator" sheet of
#         intermediate sums for the variance of mean group size. No site, transect, date or
#         coordinate is deposited: a row is a group of animals seen during the year's
#         double-observer survey of the protected area's mountain blocks.
#
# Mapping (standard E9 declared stretch: independent double-observer, multinomialType =
#   double_observer; one table per species because the unit is an animal group, so
#   unitKind = individual and ruling #20 applies):
#   unit = group (the year and its row number in the Output sheet), taxon = CAPSIB (Siberian
#   ibex) or OVIAMM (argali), period = survey year (1 = 2012, 2 = 2013, in __periods),
#   occasion = detection cell 1 = "10" (observer one only), 2 = "01" (observer two only),
#   3 = "11" (both), y = 1 in the group's cell and 0 in the other two, y_raw = the cell label.
#   A group appears in one period only (groups are not identified across years).
#   unit_group_size = number of animals in the group (the authors' group-size data).
#   Groups missed by both observers are, by design, not in the deposit (the conditional
#   multinomial the double-observer estimator uses).
#   Survey evidence = row_presence: every deposited row is a group that both observers
#   surveyed, and its three cells are all defined by the two 0/1 columns.
#   Not shipped: the authors' estimates (columns E-F; model output) and the back-end
#   calculator sheet (derived sums). The groups-by-cell counts in column F are asserted
#   against the rows, so the deposit's own summary checks the parse.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
SCRIPT <- "data/tumursukh_2016_tost_ungulates_dobs.R"
CACHE  <- "tumursukh_2016_tost_ibex_dobs"
dir <- download_dryad("10.5061/dryad.v61m2", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zip <- file.path(dir, "Data for Editor Oryx.zip"); stopifnot(file.exists(zip))
xdir <- file.path(dir, "unzipped"); if (!dir.exists(xdir)) unzip(zip, exdir = xdir)
wb <- file.path(xdir, "Data for Editor Oryx")
stopifnot(setequal(list.files(wb), sprintf("Double observer %s %d.xls", rep(c("ibex", "argali"), each = 2), c(2012L, 2013L))))

read_year <- function(species, year) {
  f <- file.path(wb, sprintf("Double observer %s %d.xls", species, year))
  sh <- excel_sheets(f); stopifnot(length(sh) == 3L, identical(sh[1:2], c("Information", "Output")), startsWith(sh[3], "Back end calculator"))
  o <- as.data.frame(read_excel(f, "Output", col_names = FALSE, .name_repair = "minimal"))
  stopifnot(identical(as.character(o[2, 1:3]), c("Group Size", "Observer one detections", "Observer two detections")),
            identical(as.character(o[2:4, 5]), c("# groups sighted by both observers", "# groups sighted by observer one only",
                                                  "# groups sighted by observer two only")))
  g <- o[-(1:2), 1:3]; g <- g[!is.na(g[[1]]), ]
  d <- data.table(row = seq_len(nrow(g)), size = as.integer(g[[1]]), o1 = as.integer(g[[2]]), o2 = as.integer(g[[3]]))
  stopifnot(!anyNA(d), all(d$size >= 1), all(d$o1 %in% 0:1), all(d$o2 %in% 0:1), all(d$o1 + d$o2 >= 1),
            # the authors' own cell counts (column F) agree with the rows
            sum(d$o1 == 1 & d$o2 == 1) == as.numeric(o[2, 6]), sum(d$o1 == 1 & d$o2 == 0) == as.numeric(o[3, 6]),
            sum(d$o1 == 0 & d$o2 == 1) == as.numeric(o[4, 6]))
  d[, year := year]
  d
}

SP <- list(
  ibex   = list(table = "tumursukh_2016_tost_ibex_dobs", code = "CAPSIB", sci = "Capra sibirica", vern = "Siberian ibex",
                n = c(`2012` = 124L, `2013` = 143L), animals = c(`2012` = 650L, `2013` = 721L)),
  argali = list(table = "tumursukh_2016_tost_argali_dobs", code = "OVIAMM", sci = "Ovis ammon", vern = "Argali",
                n = c(`2012` = 11L, `2013` = 22L), animals = c(`2012` = 85L, `2013` = 165L)))
CELLS <- c("10", "01", "11")

build <- function(sp) {
  s <- SP[[sp]]
  g <- rbindlist(lapply(c(2012L, 2013L), function(yr) read_year(sp, yr)))
  stopifnot(identical(g[, .N, by = year]$N, unname(s$n)), identical(g[, sum(size), by = year]$V1, unname(s$animals)))
  g[, `:=`(unit = sprintf("%d_g%03d", year, row), period = year - 2011L,
           cell = fifelse(o1 == 1 & o2 == 1, 3L, fifelse(o1 == 1, 1L, 2L)))]
  long <- g[, .(occasion = 1:3, y = as.integer(1:3 == cell), y_raw = CELLS), by = .(unit, period, unit_group_size = size)]
  long[, taxon := s$code]
  long <- order_eco(long)
  stopifnot(nrow(long) == 3L * nrow(g), long[, sum(y), by = unit][, all(V1 == 1L)], !anyDuplicated(long[, .(unit, occasion)]),
            !any(grepl("^unit_unit_", names(long))))
  periods <- data.table(period = 1:2, year = c(2012L, 2013L),
                        n_groups = as.integer(s$n), n_animals = as.integer(s$animals))
  taxa <- make_taxa(s$code, s$sci, vernacularName = s$vern)
  dataset <- list(
    title = sprintf("Independent double-observer detections of %s groups, Tost Local Protected Area, South Gobi, Mongolia, 2012-2013", s$vern),
    creator = "Tumursukh, Lkhagvasumberel; Suryawanshi, Kulbhushansingh R.; Mishra, Charudutt; McCarthy, Thomas M.; Boldgiv, Bazartseren",
    pubDate = "2016", doi = "10.5061/dryad.v61m2", sourceURL = "https://doi.org/10.5061/dryad.v61m2",
    paperDOI = "10.1017/S0030605314001203",
    citation = "Tumursukh, L., Suryawanshi, K. R., Mishra, C., McCarthy, T. M., & Boldgiv, B. (2016). Data from: Status of the mountain ungulate prey of the endangered snow leopard Panthera uncia in the Tost Local Protected Area, South Gobi, Mongolia [Data set]. Dryad. https://doi.org/10.5061/dryad.v61m2",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Double-observer surveys of %s in the mountain blocks of the Tost Local Protected Area (South Gobi, Mongolia) in 2012 and 2013: two observers searched independently and every group either detected was recorded with its size and with which observer saw it. %d groups (%d animals) in 2012 and %d groups (%d animals) in 2013. The authors estimate groups and population size with the Forsyth-Hickling / Suryawanshi double-observer estimator; prey of the snow leopard.",
                       tolower(s$vern), s$n[1], s$animals[1], s$n[2], s$animals[2]),
    samplingProtocol = "Independent double-observer survey of mountain ungulates (Suryawanshi et al. 2012): two observers walk the same route separated in time so neither cues the other, record every group with its size, and groups are matched afterwards on size, composition and location.",
    samplingProtocolCode = "double_observer", surveyEvidence = "row_presence",
    surveyEvidenceNote = "Each deposited row is a group seen by at least one observer; both observers surveyed it, so all three detection cells are defined. Groups missed by both observers are not in the deposit by design.",
    responseType = "multinomial_cell", multinomialType = "double_observer", unitKind = "individual",
    closure = "occasion (the three detection cells of one group within the year's survey); groups are not matched across years",
    occasionCodes = list(`1` = "10: observer one only", `2` = "01: observer two only", `3` = "11: both observers"),
    geographicCoverage = "Tost Local Protected Area, South Gobi province, Mongolia (about 43.1 N, 100.6 E); no coordinates deposited",
    temporalCoverage = "2012/2013",
    notes = sprintf("Unit = a detected group (id = year_row). y = 1 in the group's detection cell, 0 in the other two; unit_group_size = animals in the group. To recover the authors' cell counts sum y by period and occasion; the population estimate multiplies estimated groups by mean group size. Sibling table: %s (components).",
                    SP[[setdiff(names(SP), sp)]]$table),
    components = c(SP$ibex$table, SP$argali$table),
    notShipped = list(estimates = "Output sheet columns E-F: estimated groups, mean group size, population, variances and detection probabilities (model output)",
                      back_end_calculator = "intermediate sums for the variance of mean group size (derived)",
                      demographic_surveys = "the paper's ibex sex-ratio and young-survival surveys are not in the deposit"))
  ds <- write_table(long, s$table, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(s$table,
    description = sprintf("Independent double-observer detections of %s groups in the Tost Local Protected Area, South Gobi, Mongolia, 2012 and 2013: one unit per detected group with its size, three detection cells (observer one only, observer two only, both).", tolower(s$vern)),
    url = "https://doi.org/10.5061/dryad.v61m2",
    reference = "Tumursukh, L., Suryawanshi, K. R., Mishra, C., McCarthy, T. M., & Boldgiv, B. (2016). Status of the mountain ungulate prey of the endangered snow leopard Panthera uncia in the Tost Local Protected Area, South Gobi, Mongolia. Oryx, 50(2), 214-219.",
    doi_paper = "10.1017/S0030605314001203", doi_data = "10.5061/dryad.v61m2",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Declared stretch (E9): occasion = double-observer cell, multinomialType = double_observer; group as unit (unitKind individual) so group size is kept; one table per species (ruling #20). Authors' estimates not shipped.",
    source_via = "Dryad (version zip)")
  stage_tag_row(s$table, ds, taxon_group = "Mammals", model_family = "Double-observer (independent), multinomial",
    sampling_protocol = "double_observer", design = "Multi-session (2 survey years, groups not matched across years)", realm = "Terrestrial",
    country = "MNG", coordinates = "None in source",
    notes = "Group as unit with group size; three detection cells; snow leopard prey.")
  invisible(ds)
}
for (sp in names(SP)) build(sp)
