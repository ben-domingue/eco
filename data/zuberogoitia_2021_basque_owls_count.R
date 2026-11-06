#!/usr/bin/env Rscript
# Table:  zuberogoitia_2021_basque_owls_count
# Source: Dryad doi:10.5061/dryad.dncjsxkwg (CC0 1.0, as shown on the Dryad page; published
#         2021-04-27). Zuberogoitia, I. et al. Maximizing detection probability to optimize
#         nocturnal bird surveys in large areas.
# Paper:  Zuberogoitia, I., Martinez, J.E., Gonzalez-Oreja, J.A. et al. (2020). Maximizing
#         detection probability for effective large-scale nocturnal bird monitoring. Diversity
#         and Distributions, doi:10.1111/ddi.13075. Basque Country, northern Spain, 2018: 65
#         random 5 x 5 km UTM squares, eight survey points (SP) per square >= 1 km apart, monthly
#         survey periods January to July, 4-8 SPs per square per period; each survey 15 min
#         after dusk (5 min spontaneous, 5 min playback of one species, 5 min silence), counting
#         all owls and nightjars (Dryad methods text).
# Data:   one xlsx, two sheets. "raw database " (read here): one row per SP (527, keys 5x5 km
#         square + SP, unique) plus a final totals row (no province; asserted equal to the
#         column sums, dropped), Province, Xcoord/Ycoord (decimal degrees, 4 dp), then eight
#         survey blocks in deposited order: JANUARY, FEBRUARY, MARCH, MARCH-2, APRIL, MAY, EXTRA,
#         JUNE/JULY, each with Date, Observer, Hour (fraction of a day), broadcast spp, the
#         broadcast species' response (spontaneous / during broadcast / after broadcast, 0-2),
#         and counts of individuals of 9 species (Bubo bubo, Strix aluco, Tyto alba, Otus scops,
#         Athene noctua, Asio otus, Asio flammeus, Aegolius funereus, Caprimulgus europaeus).
#         "Database used for the analysis": the same SPs with region, altitude and % vegetation
#         types per 1 km2 (read for unit covariates), plus the authors' recoded per-visit
#         matrices for six species (not read: they are a model input derived from the raw sheet,
#         in different visit slots).
#         Quirks: 9 dated survey cells have no count at all; 9 cells have counts for some
#         species and NA for others (8 in FEBRUARY at square 30TWN25NW, 1 in MARCH at
#         30TVN78NW); 1 January cell has counts but no date.
# Mapping (standard: repeated counts, community; E9 core N-mixture): unit = "<square>_<SP>";
#   taxon = species code; occasion = survey block 1..8 in deposited order (the dates give the
#   timing); y = individuals counted; date = Date; observer = Observer; obs_: hour as hh:mm,
#   broadcast species and its response columns (they describe the playback species only).
#   Survey evidence: row_presence on the raw sheet: a survey is a block with a count for every
#   one of the 9 species. Not surveys: dated cells with no count (9); cells with a partial
#   count (9, dropped whole and listed in notShipped: a community table needs every species at
#   every survey, and the NA species were not recorded). The undated January survey with counts
#   is kept (date empty). unit_: province, region, lat/lon as deposited, altitude, vegetation %.
#   Coordinates: all nine species are IUCN LC; kept as published (4 dp).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "zuberogoitia_2021_basque_owls_count"
dir <- download_dryad("10.5061/dryad.dncjsxkwg", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
sh <- excel_sheets(f); stopifnot(identical(sh, c("Database used for the analysis", "raw database ")))
rd <- function(s, skip) as.data.frame(suppressWarnings(suppressMessages(read_excel(f, s, col_names = FALSE, skip = skip))))
hdr <- rd(sh[2], 0)[1:2, ]
r <- rd(sh[2], 2)
SPP <- c("Bubo bubo", "Strix aluco", "Tyto alba", "Otus scops", "Athene noctua", "Asio otus", "Asio flammeus",
         "Aegolius funereus", "Caprimulgus europaeus")
CODE <- c("BUBBUB", "STRALU", "TYTALB", "OTUSCO", "ATHNOC", "ASIOTU", "ASIFLA", "AEGFUN", "CAPEUR")
BLK <- c("JANUARY", "FEBRUARY", "MARCH", "MARCH-2", "APRIL", "MAY", "EXTRA", "JUNE/JULY")
starts <- c(6, 22, 38, 54, 70, 86, 102, 118)
stopifnot(ncol(r) == 133, identical(as.character(hdr[1, starts]), BLK),
          all(sapply(starts, function(s) identical(as.character(hdr[2, s + 7:15]), SPP))),
          all(tolower(as.character(hdr[2, starts])) == "date"), all(as.character(hdr[2, starts + 3]) == "broadcast spp"))
tot <- which(is.na(r[[1]])); stopifnot(length(tot) == 1, tot == nrow(r))
totals <- r[tot, ]; r <- r[-tot, ]
stopifnot(nrow(r) == 527, !anyDuplicated(paste(r[[2]], r[[3]])))
r$unit <- paste(r[[2]], r[[3]], sep = "_")
num <- function(x) suppressWarnings(as.numeric(x))
toDate <- function(x) if (inherits(x, "POSIXct")) as.IDate(x) else as.IDate(num(x), origin = "1899-12-30")
rows <- list(); drop_partial <- 0L; drop_empty <- 0L
for (b in seq_along(starts)) {
  s <- starts[b]
  C <- sapply(s + 7:15, function(j) num(r[[j]])); colnames(C) <- CODE
  stopifnot(isTRUE(all.equal(unname(colSums(C, na.rm = TRUE)), num(totals[s + 7:15]))), all(C %in% c(NA, 0:20)))
  dt <- toDate(r[[s]]); nC <- rowSums(!is.na(C))
  drop_empty <- drop_empty + sum(!is.na(dt) & nC == 0)
  drop_partial <- drop_partial + sum(nC > 0 & nC < 9)
  keep <- which(nC == 9)
  if (!length(keep)) next
  hr <- num(r[[s + 2]])
  rows[[b]] <- data.table(unit = r$unit[keep], occasion = b, date = format(dt[keep]),
                          observer = as.character(r[[s + 1]])[keep],
                          obs_time = ifelse(is.na(hr[keep]), NA_character_, sprintf("%02d:%02d", floor(round(hr[keep] * 1440) / 60) %% 24, round(hr[keep] * 1440) %% 60)),
                          obs_broadcast_species = as.character(r[[s + 3]])[keep],
                          obs_broadcast_resp_spontaneous = num(r[[s + 4]])[keep], obs_broadcast_resp_during = num(r[[s + 5]])[keep],
                          obs_broadcast_resp_after = num(r[[s + 6]])[keep], C[keep, , drop = FALSE])
}
sv <- rbindlist(rows)
stopifnot(drop_empty == 9, drop_partial == 9, nrow(sv) == 2575, sum(is.na(sv$date)) == 1,
          sum(substr(sv$date, 1, 4) == "2019", na.rm = TRUE) == 4, all(substr(na.omit(sv$date), 1, 4) %in% c("2018", "2019")))
long <- melt(sv, measure.vars = CODE, variable.name = "taxon", value.name = "y", variable.factor = FALSE)
long[, y := as.integer(y)]
a <- rd(sh[1], 3); stopifnot(nrow(a) == 527)
a$unit <- paste(a[[3]], a[[4]], sep = "_"); stopifnot(setequal(a$unit, r$unit))
uc <- data.table(unit = r$unit, unit_province = r[[1]], unit_decimalLongitude = num(r[[4]]), unit_decimalLatitude = num(r[[5]]))
ac <- data.table(unit = a$unit, unit_region = a[[7]], unit_altitude_m = num(a[[8]]), unit_pct_field = num(a[[9]]),
                 unit_pct_agriculture = num(a[[10]]), unit_pct_urban = num(a[[11]]), unit_pct_forest = num(a[[12]]),
                 unit_pct_scrub = num(a[[13]]), unit_pct_holm_oak = num(a[[14]]), unit_pct_deciduous = num(a[[15]]),
                 unit_pct_pine = num(a[[16]]), unit_pct_eucalyptus = num(a[[17]]))
stopifnot(!anyNA(uc), all(uc$unit_decimalLatitude > 42 & uc$unit_decimalLatitude < 44))
long <- merge(merge(long, uc, by = "unit"), ac, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 2575 * 9, sum(long$y) == sum(as.matrix(sv[, ..CODE])))
taxa <- make_taxa(CODE, SPP)
dataset <- list(
  title = "Counts of nine owl and nightjar species on up to eight playback surveys at 526 points in the Basque Country, Spain, January-July 2018",
  creator = "Zuberogoitia, Iñigo; Martínez, José Enrique; González-Oreja, José Antonio; González de Buitrago, Carlos; Belamendia, Gorka; Zabala, Jabi; Laso, Maite; Pagaldai, Nerea; Jiménez-Franco, María Victoria",
  pubDate = "2021", doi = "10.5061/dryad.dncjsxkwg", sourceURL = "https://doi.org/10.5061/dryad.dncjsxkwg",
  citation = "Zuberogoitia, I. et al. (2021). Maximizing detection probability to optimize nocturnal bird surveys in large areas [Dataset]. Dryad. https://doi.org/10.5061/dryad.dncjsxkwg",
  paperDOI = "10.1111/ddi.13075",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of individuals of nine nocturnal bird species (seven owls, long- and short-eared owl, Tengmalm's owl and European nightjar) on 15-minute playback surveys after dusk at 526 survey points (one more deposited point was never surveyed) in 65 random 5 x 5 km UTM squares across the Basque Country, northern Spain, in up to eight survey rounds from January to July 2018, with date, observer, time, playback species and its response, and point covariates (altitude, vegetation types).",
  samplingProtocol = "15-minute surveys in the first hours after dusk: 5 min listening for spontaneous calls, 5 min playback of one species' call, 5 min silent listening; all owls and nightjars counted; 4-8 of the 8 points per 5 x 5 km square surveyed per monthly round, January to July 2018.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site", closure = "open",
  closureNote = "seven months of the breeding cycle; the authors fit hierarchical abundance models with survey-level detection covariates",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Basque Country (Araba, Bizkaia, Gipuzkoa) and adjoining Burgos, northern Spain; point coordinates in decimal degrees as deposited",
  temporalCoverage = "2018-01/2019-03", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "as published (4 decimal places): all nine species are IUCN LC"),
  notShipped = list(partial_surveys = "9 survey cells with counts for some species and NA for the others (8 in the February round at square 30TWN25NW, 1 in March at 30TVN78NW), dropped whole",
                    empty_dated_cells = "9 dated survey cells with no counts (not surveys)",
                    totals_row = "the sheet's column-total row (asserted equal to the column sums)",
                    analysis_matrices = "the 'Database used for the analysis' per-visit matrices, a recoded model input in different visit slots; only its site covariates are used"),
  notes = "occasion is the deposited survey block in sheet order (JANUARY, FEBRUARY, MARCH, MARCH-2, APRIL, MAY, EXTRA, JUNE/JULY); EXTRA surveys fall on 30-31 May, so occasion order is not strictly date order: use date. The obs_broadcast_resp_ columns describe the playback species named in obs_broadcast_species (0-2, as deposited). One January survey has counts but no date. Four MARCH-2 surveys are dated March 2019 in the deposit (the study ran January-July 2018), and a few dates fall outside their block's month; dates are shipped as deposited. The paper reports 521 survey points; the deposit has 527 rows, of which 526 have a survey.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/zuberogoitia_2021_basque_owls_count.R")
stage_dict_row(TABLE,
  description = "Counts of nine owl and nightjar species on up to eight playback surveys at 526 points in the Basque Country, Spain, January-July 2018, with survey and point covariates.",
  url = "https://doi.org/10.5061/dryad.dncjsxkwg",
  reference = "Zuberogoitia, I. et al. (2020). Maximizing detection probability for effective large-scale nocturnal bird monitoring. Diversity and Distributions.",
  doi_paper = "10.1111/ddi.13075", doi_data = "10.5061/dryad.dncjsxkwg", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community repeated counts from the raw sheet; partial surveys dropped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community N-mixture (repeated counts)",
  sampling_protocol = "point_count", design = "Single-season (up to 8 monthly playback surveys)", realm = "Terrestrial",
  country = "ESP", coordinates = "As published", notes = "Owls and nightjar; playback species per survey as obs_.")
