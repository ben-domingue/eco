#!/usr/bin/env Rscript
# Table:  henden_2013_finnmark_birds_dynocc
# Source: Dryad doi:10.5061/dryad.bs87m (CC0 1.0, as shown on the Dryad page; published
#         2013-08-27). Henden, J.-A., Yoccoz, N.G., Ims, R.A. & Langeland, K. Data from: How
#         spatial variation in areal extent and configuration of labile vegetation states affect
#         the riparian bird community in Arctic tundra.
# Paper:  Henden, J.-A. et al. (2013). PLoS ONE 8(5): e63312, doi:10.1371/journal.pone.0063312.
#         Riparian willow thickets in low-arctic tundra, Finnmark, northern Norway: a 4-year
#         series of repeated bird counts per plot; hierarchical community occupancy models
#         (abstract).
# Data:   PlosOne-DataFinnmark.txt (629 rows = 37 plots x 17 species: Y05.1..Y08.3 = detection
#         0/1 on visit 1-3 of 2005-2008, NA = not surveyed; Plot; Species (common names as
#         deposited, with the spellings "Bluethrout" and "Eurasian Golden Plower"); Pland (% of
#         the plot in willow), ed (edge density), wheight (willow height), wpf (willow patch
#         ... index), constant per plot); DayOfYearCoVar.txt (37 rows x 12: day of year of each
#         visit, in the data file's plot order; its NA pattern equals the detections', asserted).
#         Asserted: the NA pattern is identical for all 17 species of a plot.
# Mapping (standard: dynamic community occupancy, E9 core): unit = Plot; taxon = species code;
#   period = year (2005-2008, __periods); occasion = visit 1..3; y = the cell; NA = no row;
#   date = year + day of year (exact). unit_: Pland, ed, wheight, wpf as deposited (the README
#   is the column names only; units follow the paper). Survey evidence: deposited_matrix.
#   Scientific names are the processor's, from the common names. No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "henden_2013_finnmark_birds_dynocc"
dir <- download_dryad("10.5061/dryad.bs87m", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
d <- rf("PlosOne-DataFinnmark\\.txt"); D <- rf("DayOfYearCoVar\\.txt")
Y <- paste0("Y0", rep(5:8, each = 3), ".", 1:3)
stopifnot(identical(names(d), c(Y, "Plot", "Species", "Pland", "ed", "wheight", "wpf")), nrow(d) == 629,
          uniqueN(d$Plot) == 37, uniqueN(d$Species) == 17, !anyDuplicated(d[, .(Plot, Species)]),
          identical(names(D), Y), nrow(D) == 37, all(as.matrix(d[, ..Y]) %in% c(0, 1, NA)),
          d[, .(a = uniqueN(Pland), b = uniqueN(ed), c = uniqueN(wheight), e = uniqueN(wpf)), by = Plot][, all(a == 1 & b == 1 & c == 1 & e == 1)])
plots <- unique(d$Plot)
na1 <- is.na(as.matrix(d[match(plots, Plot), ..Y]))
stopifnot(identical(na1, is.na(as.matrix(D))), d[, all(apply(is.na(as.matrix(.SD)), 2, function(v) all(v) || !any(v))), by = Plot, .SDcols = Y][, all(V1)])
SP <- c(Bluethrout = "Luscinia svecica", Brambling = "Fringilla montifringilla", `Common Redpoll` = "Acanthis flammea",
        `Eurasian Golden Plower` = "Pluvialis apricaria", Fieldfare = "Turdus pilaris", `Lapland Bunting` = "Calcarius lapponicus",
        `Long-tailed Skua` = "Stercorarius longicaudus", `Meadow Pipit` = "Anthus pratensis", `Northern Wheatear` = "Oenanthe oenanthe",
        `Red-throated Pipit` = "Anthus cervinus", Redwing = "Turdus iliacus", `Reed Bunting` = "Emberiza schoeniclus",
        `Rough-legged Buzzard` = "Buteo lagopus", `Temminck's Stint` = "Calidris temminckii", `White Wagtail` = "Motacilla alba",
        `Willow Ptarmigan` = "Lagopus lagopus", `Willow Warbler` = "Phylloscopus trochilus")
stopifnot(setequal(names(SP), d$Species))
code <- toupper(paste0(substr(sub(" .*", "", SP), 1, 3), substr(sub(".* ", "", SP), 1, 3))); names(code) <- names(SP)
stopifnot(!anyDuplicated(code))
long <- melt(d, id.vars = c("Plot", "Species", "Pland", "ed", "wheight", "wpf"), measure.vars = Y, variable.name = "v", value.name = "y", variable.factor = FALSE)[!is.na(y)]
long[, `:=`(year = 2000L + as.integer(substr(v, 2, 3)), occasion = as.integer(substr(v, 5, 5)))]
DL <- melt(cbind(Plot = plots, D), id.vars = "Plot", variable.name = "v", value.name = "doy", variable.factor = FALSE)
long <- merge(long, DL, by = c("Plot", "v"))
stopifnot(!anyNA(long$doy))
long <- long[, .(unit = Plot, taxon = unname(code[Species]), y = as.integer(y), period = year - 2004L, occasion,
                 date = format(as.IDate(paste0(year - 1L, "-12-31")) + as.integer(doy)),
                 unit_pland_willow = Pland, unit_edge_density = ed, unit_willow_height = wheight, unit_wpf = wpf)]
long <- order_eco(long)
stopifnot(nrow(long) == 629 * 12 - 68, sum(long$y) == 1454)
periods <- data.table(period = 1:4, period_year = 2005:2008)
taxa <- make_taxa(unname(code), unname(SP), vernacularName = names(SP))
dataset <- list(
  title = "Detections of 17 riparian tundra bird species on three visits per year to 37 willow-thicket plots in Finnmark, Norway, 2005-2008",
  creator = "Henden, John-André; Yoccoz, Nigel G.; Ims, Rolf A.; Langeland, Knut", pubDate = "2013",
  doi = "10.5061/dryad.bs87m", sourceURL = "https://doi.org/10.5061/dryad.bs87m",
  citation = "Henden, J.-A., Yoccoz, N. G., Ims, R. A., & Langeland, K. (2013). Data from: How spatial variation in areal extent and configuration of labile vegetation states affect the riparian bird community in Arctic tundra [Dataset]. Dryad. https://doi.org/10.5061/dryad.bs87m",
  paperDOI = "10.1371/journal.pone.0063312",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of 17 bird species on three visits per breeding season to 37 riparian willow-thicket plots in low-arctic tundra of Finnmark, northern Norway, 2005-2008, with visit dates and plot willow extent, edge density, willow height and patch configuration.",
  samplingProtocol = "Repeated bird counts in fixed riparian plots, three visits per year in late June to July, 2005-2008; species recorded as detected or not per visit.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a season's three visits, open between years", occasionKind = "time",
  taxonInclusion = "recorded", geographicCoverage = "Riparian tundra, Finnmark, northern Norway; no coordinates deposited",
  temporalCoverage = "2005/2008",
  notShipped = list(none = "every deposited column is shipped (day of year as date)"),
  notes = "Scientific names are the processor's, from the deposited common names ('Bluethrout' = bluethroat, 'Eurasian Golden Plower' = Eurasian golden plover). The column wpf is shipped as deposited (unit_wpf); its definition is in the paper. 4 plot-visits were not surveyed (68 NA cells).")
dataset$temporalCoverage <- paste(substr(min(long$date), 1, 7), substr(max(long$date), 1, 7), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/henden_2013_finnmark_birds_dynocc.R")
stage_dict_row(TABLE,
  description = "Detections of 17 riparian bird species on three visits per year to 37 willow plots in Finnmark, Norway, 2005-2008, with willow habitat covariates.",
  url = "https://doi.org/10.5061/dryad.bs87m",
  reference = "Henden, J.-A., Yoccoz, N. G., Ims, R. A., & Langeland, K. (2013). How spatial variation in areal extent and configuration of labile vegetation states affect the riparian bird community in Arctic tundra. PLoS ONE, 8(5), e63312.",
  doi_paper = "10.1371/journal.pone.0063312", doi_data = "10.5061/dryad.bs87m", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic community occupancy.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic community occupancy",
  sampling_protocol = "point_count", design = "Multi-season (4 years x 3 visits)", realm = "Terrestrial",
  country = "NOR", coordinates = "None in source", notes = "Arctic riparian birds.")
