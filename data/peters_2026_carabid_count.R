#!/usr/bin/env Rscript
# Tables: peters_2026_carabid_pitfall_count (pitfall traps) and peters_2026_carabid_emergence_count
#         (emergence tents), both built by this script.
# Source: Zenodo record 20523452, doi:10.5281/zenodo.20523452, "Overwintering in the field: carabid
#         communities", Péters J, Boeraeve F, Dufrêne M, published 2026-06-03. Licence as shown on
#         the record: Creative Commons Attribution 4.0 International (cc-by-4.0).
# Paper:  none linked from the record (no related identifiers). The record describes the study:
#         carabid communities of commercial arable plots in Belgium through a sugar beet - winter
#         cereal succession, two independent crop cycles (2023-2024 and 2024-2025); Barber pitfall
#         traps (vinegar, propylene glycol or brine) for the active fauna and emergence tents for
#         beetles emerging from the soil; three seasonal periods (April, July, October) with
#         repeated sampling weeks and several within-plot positions.
# Data:   one file, "Data - Carabids owerwintering.xlsm" (macro-enabled workbook; read with readxl,
#         macros never run), one sheet Feuil1: 4,923 rows (one per trap collection) x 112 columns.
#   Year (2023-2025), Culture (Sugar_beet / Cereal), Période (A / J / G), Sampling (week 1-3),
#   Parcelle (plot 1-40), Ligne (within-plot position A, B, C, C1, C2, D, E), Type (V vinegar,
#   P propylene glycol, S brine pitfalls; T emergence tent), Etat (trap status: ok 4,599, Absent /
#   absent 296, Inonde / Inondé 15 flooded, Trouée 9 torn, Vide / VIDE 3, Retire 1), then 104 species
#   columns of integer counts (no blanks). 31 species columns are 0 in every row (a checklist
#   template). Plots 1-20: sugar beet 2023 (A, J, G), cereal 2024 (A, J); plots 21-40: sugar beet
#   2024 (A, J, G), cereal 2025 (A, J; plots 23, 35, 38 absent). Période letters are not explained
#   in the record; the description's April, July, October and the pattern (G only in sugar beet,
#   which is harvested in autumn, cereal by July) give A = April, J = July, G = October.
#   Two rows (1830, 1854; 2024 cereal J, plots 3 and 8, line E, brine) sit in the Sampling 3 block
#   of the sheet but are typed Sampling 2, duplicating a week-2 key and leaving week 3 empty; they
#   are read as week 3 (asserted).
#   Pitfall preservative: 2023 lines A, C1, D vinegar and B, C2, E propylene glycol; 2024-2025
#   vinegar and brine. Emergence tents at lines A-E.
#
# Mapping (standard E1-E5, community counts per trap x sampling week):
#   Two tables, one per method: a pitfall trap measures activity-density, an emergence tent the
#   beetles emerging from the enclosed soil, so the detection processes differ.
#   unit = trap (plot x line x type, e.g. "P03-E-S"), cluster_id = plot ("P03"), taxon = 8-letter
#   code (4 genus + 4 species letters of the name as corrected below), period = year x seasonal
#   period in time order (1 = 2023 April ... 8 = 2025 July; __periods), occasion = sampling week
#   (1-3), y = beetles of the species in the collection; 0 for every species at every collection
#   (all carabids identified and counted). obs_crop = the plot's crop that year (sugar_beet /
#   cereal); unit_preservative (pitfalls), unit_line, unit_cycle (1 = plots 1-20, 2 = plots 21-40).
#   surveyEvidence = sample_table: the sheet lists every collection with its status; a survey is a
#   row with Etat = ok. Absent, flooded, torn, removed and "Vide" traps are not surveys (Vide is
#   ambiguous: one of the three Vide rows holds 7 beetles).
#   Taxa: the 73 species with at least one beetle anywhere in the deposit, in both tables (a species
#   may be 0 throughout one method); the 31 template columns with no beetle are not shipped.
#   No coordinates or dates in the deposit (period and week only).
#   Not shipped: non-ok collections (328 rows, 255 beetles); the 31 empty species columns.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
CACHE <- "peters_2026_carabid_count"

f <- download_cached("https://zenodo.org/api/records/20523452/files/Data%20-%20Carabids%20owerwintering.xlsm/content", CACHE,
                     "carabids_overwintering.xlsm")
stopifnot(identical(excel_sheets(f), "Feuil1"))
x <- as.data.table(suppressMessages(read_excel(f, sheet = "Feuil1", col_types = "text")))
ctx <- c("Year", "Culture", "Période", "Sampling", "Parcelle", "Ligne", "Type", "Etat")
stopifnot(nrow(x) == 4923, ncol(x) == 112, identical(names(x)[1:8], ctx))
spc <- names(x)[9:112]
m <- as.matrix(x[, ..spc]); stopifnot(!anyNA(m), all(grepl("^[0-9]+$", m)))
x[, (spc) := lapply(.SD, as.integer), .SDcols = spc]
x[, row := .I]
stopifnot(setequal(x$Year, c("2023", "2024", "2025")), setequal(x$Culture, c("Sugar_beet", "Cereal")),
          setequal(x$Période, c("A", "J", "G")), setequal(x$Sampling, c("1", "2", "3")), setequal(x$Type, c("V", "P", "S", "T")),
          setequal(x$Ligne, c("A", "B", "C", "C1", "C2", "D", "E")),
          identical(as.vector(table(x$Etat)[c("ok", "Absent", "absent", "Inonde", "Inondé", "Trouée", "Vide", "VIDE", "Retire")]),
                    c(4599L, 292L, 4L, 8L, 7L, 9L, 2L, 1L, 1L)))

# the two mistyped sampling weeks
fix <- x[row %in% c(1830L, 1854L)]
stopifnot(nrow(fix) == 2, all(fix$Year == "2024" & fix$Culture == "Cereal" & fix$Période == "J" & fix$Sampling == "2" &
                              fix$Ligne == "E" & fix$Type == "S"), setequal(fix$Parcelle, c("3", "8")),
          x[row %in% c(1826L, 1827L, 1850L, 1852L), all(Sampling == "3")],
          nrow(x[Year == "2024" & Culture == "Cereal" & Période == "J" & Sampling == "3" & Parcelle %in% c("3", "8") & Ligne == "E" & Type == "S"]) == 0)
x[row %in% c(1830L, 1854L), Sampling := "3"]
stopifnot(!anyDuplicated(x[, .(Year, Culture, Période, Sampling, Parcelle, Ligne, Type)]))

# design facts
x[, plot := as.integer(Parcelle)]
stopifnot(all(x[plot <= 20, (Year == "2023" & Culture == "Sugar_beet") | (Year == "2024" & Culture == "Cereal")]),
          all(x[plot > 20, (Year == "2024" & Culture == "Sugar_beet") | (Year == "2025" & Culture == "Cereal")]),
          all(x[Période == "G", Culture == "Sugar_beet"]), all(x[Type == "T", Ligne %in% c("A", "B", "C", "D", "E")]),
          all(x[Type == "P", Year == "2023"]), all(x[Type == "S", Year != "2023"]), uniqueN(x$plot) == 40)

# species: names as written, corrected spellings for the code and GBIF
nm <- data.table(col = spc, written = gsub("_", " ", spc))
nm[, name := written]
corr <- c("Philochtus biggatus" = "Philochthus biguttatus", "Poecilius cupreus" = "Poecilus cupreus",
          "Poecilius kugelanni" = "Poecilus kugelanni", "Poecilius versicolor" = "Poecilus versicolor",
          "Diacromus germanus" = "Diachromus germanus", "Carabus violaceus purpurascens" = "Carabus violaceus",
          "Leistus fluvibarbaris" = "Leistus fulvibarbis", "Parophonus malunicornis" = "Parophonus maculicornis")
nm[written %in% names(corr), name := corr[written]]
tot <- colSums(x[, ..spc])
nm[, n_all := tot[col]]
stopifnot(sum(nm$n_all == 0) == 31)
sp <- nm[n_all > 0]
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", name), 1, 4), substr(sub("^\\S+ ", "", name), 1, 4)))]
stopifnot(nrow(sp) == 73, !anyDuplicated(sp$taxon), !anyDuplicated(sp$name))

# periods: year x seasonal period in time order
x[, pkey := paste(Year, Période)]
pk <- data.table(Year = c("2023", "2023", "2023", "2024", "2024", "2024", "2025", "2025"),
                 Période = c("A", "J", "G", "A", "J", "G", "A", "J"))
pk[, `:=`(period = .I, pkey = paste(Year, Période))]
stopifnot(setequal(pk$pkey, x$pkey))
periods <- pk[, .(period, period_year = as.integer(Year), period_code = Période,
                  period_season = c(A = "April", J = "July", G = "October")[Période])]

build <- function(method) {
  types <- if (method == "pitfall") c("V", "P", "S") else "T"
  d <- x[Type %in% types]
  ok <- d[Etat == "ok"]
  ok[, `:=`(unit = sprintf("P%02d-%s-%s", plot, Ligne, Type), cluster_id = sprintf("P%02d", plot),
            period = pk$period[match(pkey, pk$pkey)], occasion = as.integer(Sampling),
            obs_crop = fifelse(Culture == "Sugar_beet", "sugar_beet", "cereal"))]
  stopifnot(!anyDuplicated(ok[, .(unit, period, occasion)]))
  long <- melt(ok[, c("unit", "cluster_id", "period", "occasion", "obs_crop", sp$col), with = FALSE],
               id.vars = c("unit", "cluster_id", "period", "occasion", "obs_crop"), variable.name = "col", value.name = "y",
               variable.factor = FALSE)
  long[, taxon := sp$taxon[match(col, sp$col)]][, col := NULL]
  stopifnot(nrow(long) == nrow(ok) * 73, sum(long$y) == sum(as.matrix(ok[, sp$col, with = FALSE])))
  units <- ok[!duplicated(unit), .(unit, unit_plot = plot, unit_line = Ligne, unit_cycle = fifelse(plot <= 20, 1L, 2L),
                                    unit_preservative = c(V = "vinegar", P = "propylene_glycol", S = "brine", T = NA_character_)[Type])]
  if (method == "emergence") units[, unit_preservative := NULL]
  setorder(units, unit)
  list(long = order_eco(long), units = units, n_ok = nrow(ok), n_dropped = nrow(d) - nrow(ok),
       dropped_beetles = sum(as.matrix(d[Etat != "ok", sp$col, with = FALSE])),
       dropped_tab = d[Etat != "ok", .N, by = Etat])
}

taxa <- make_taxa(sp$taxon, sp$name,
                  lookupName = fifelse(sp$name == "Parastachys bistriatus", "Tachys bistriatus",
                               fifelse(sp$name == "Pseudophonus rufipes", "Harpalus rufipes", sp$name)),
                  taxon_writtenAs = fifelse(sp$written == sp$name, NA_character_, sp$written))
stopifnot(!anyNA(taxa$taxonID))

common <- list(
  creator = "Péters, Julien; Boeraeve, Fanny; Dufrêne, Marc", pubDate = "2026-06-03",
  sourceURL = "https://doi.org/10.5281/zenodo.20523452",
  citation = "Péters J, Boeraeve F, Dufrêne M (2026). Overwintering in the field: carabid communities [Data set]. Zenodo. https://doi.org/10.5281/zenodo.20523452 (CC BY 4.0).",
  dataDOI = "10.5281/zenodo.20523452",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site",
  closure = "within a seasonal period (three consecutive sampling weeks); populations change between April, July and October and between crops",
  geographicCoverage = list(description = "Commercial arable plots in Belgium (locations not given in the deposit)"),
  temporalCoverage = "2023/2025",
  coordinatesCoarsened = NA)

for (method in c("pitfall", "emergence")) {
  TABLE <- sprintf("peters_2026_carabid_%s_count", method)
  b <- build(method)
  cat(sprintf("  %s: %d collections kept, %d not surveys (%d beetles)\n", method, b$n_ok, b$n_dropped, b$dropped_beetles))
  print(b$dropped_tab)
  per <- periods[period %in% b$long$period]
  per[, period_n_collections := sapply(period, function(pp) uniqueN(b$long[period == pp, .(unit, occasion)]))]
  is_pit <- method == "pitfall"
  dataset <- c(common, list(
    title = if (is_pit) "Pitfall-trap counts of 73 ground beetle species per trap and sampling week in Belgian sugar beet and winter cereal plots, 2023-2025"
            else "Emergence-tent counts of 73 ground beetle species per tent and sampling week in Belgian sugar beet and winter cereal plots, 2023-2025",
    abstract = sprintf("Carabid beetles in %d commercial arable plots in Belgium followed through a sugar beet - winter cereal succession in two crop cycles (plots 1-20: sugar beet 2023, cereal 2024; plots 21-40: sugar beet 2024, cereal 2025), sampled in April, July and (sugar beet) October, three sampling weeks each. %s %d collections with status ok; 73 species.",
                       uniqueN(b$units$unit_plot),
                       if (is_pit) "Barber pitfall traps at six within-plot positions, with vinegar, propylene glycol (2023) or brine (2024-2025) as preservative." else "Emergence tents at five within-plot positions, catching beetles emerging from the enclosed soil.",
                       b$n_ok),
    samplingProtocol = if (is_pit) "Barber pitfall traps at fixed positions in each plot (lines A, B, C1, C2, D, E), preservative vinegar, propylene glycol or brine (unit_preservative), emptied after each sampling week; three weeks per seasonal period."
                       else "Emergence tents at fixed positions in each plot (lines A-E) enclosing the soil surface, collected after each sampling week; three weeks per seasonal period.",
    samplingProtocolCode = if (is_pit) "pitfall_trap" else "emergence_trap",
    occasionLength = "one sampling week",
    surveyEvidenceNote = sprintf("The deposited sheet has one row per trap collection with its status (Etat); a survey is a row with Etat = ok (%d of %d %s rows). Absent, flooded (Inonde / Inondé), torn (Trouée), removed (Retire) and Vide collections are not surveys. Two rows mistyped as sampling week 2 are read as week 3 from their position in the sheet.",
                                 b$n_ok, b$n_ok + b$n_dropped, if (is_pit) "pitfall" else "tent"),
    notShipped = list(`collections not ok` = sprintf("%d rows (%d beetles) with Etat Absent, flooded, torn, removed or Vide", b$n_dropped, b$dropped_beetles),
                      `empty species columns` = "31 species columns that hold no beetle in any row (a checklist template)",
                      `other method` = if (is_pit) "emergence-tent collections are peters_2026_carabid_emergence_count" else "pitfall collections are peters_2026_carabid_pitfall_count",
                      `Carabus violaceus purpurascens` = "subspecies written in the column name, shipped as Carabus violaceus")))
  ds <- write_table(b$long, TABLE, dataset, taxa = taxa, periods = per, units = b$units, script = "data/peters_2026_carabid_count.R")
  stage_dict_row(TABLE,
    description = sprintf("Counts of 73 ground beetle species per %s and sampling week in %d Belgian arable plots through a sugar beet - winter cereal succession (two crop cycles, 2023-2025), sampled in April, July and October, with the crop per survey%s.",
                          if (is_pit) "pitfall trap" else "emergence tent", uniqueN(b$units$unit_plot), if (is_pit) " and the trap's preservative" else ""),
    url = "https://doi.org/10.5281/zenodo.20523452",
    reference = "Péters J, Boeraeve F, Dufrêne M (2026). Overwintering in the field: carabid communities [Data set]. Zenodo.",
    doi_data = "10.5281/zenodo.20523452", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = sprintf("Zeros from the collection sheet (Etat = ok). %s Periode letters A/J/G read as April/July/October. No coordinates or dates deposited.",
                    if (is_pit) "Sibling of peters_2026_carabid_emergence_count." else "Sibling of peters_2026_carabid_pitfall_count."),
    source_via = "Zenodo")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
    sampling_protocol = if (is_pit) "pitfall_trap" else "emergence_trap",
    design = sprintf("Multi-season (%d year x seasonal periods x 3 sampling weeks); %s per plot", nrow(per), if (is_pit) "six pitfalls" else "five emergence tents"),
    realm = "Terrestrial", country = "Belgium", coordinates = "None in source",
    notes = if (is_pit) "Arable carabids, pitfall activity-density; preservative differs by trap and year." else "Arable carabids emerging from overwintering in the field (emergence tents).",
    status = "tagged")
}
