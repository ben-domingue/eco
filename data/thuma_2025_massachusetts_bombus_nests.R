#!/usr/bin/env Rscript
# Tables: thuma_2025_ma_bimpatiens_nest_cr, thuma_2025_ma_bgriseocollis_nest_cr
# Source: Dryad doi:10.5061/dryad.6t1g1jxbn (CC0 1.0, as shown on the Dryad page; published
#         2025-08-25). Thuma, J., Pugesek, G., Treanore, E., Finn, S. & Crone, E. Bumble bee nest
#         density is lower in drought years.
# Paper:  Thuma, J. et al. (2025). Proceedings of the Royal Society B, doi:10.1098/rspb.2025.1010.
#         Bumble bee nest surveys in coastal Massachusetts, 2018-2024: five surveys a year, each
#         nest's detection history; mark-recapture (RMark) of nest abundance and apparent
#         survival (README, abstract).
# Data:   all_years_capture_history.csv (111 nests: year 2018-2024, Species (Impatiens 58,
#         Griseocollis 46, Bimaculatus 2, Perplexus 2, Vagans 1, Fervidus 1, unknown 1),
#         Habitat Type (Meadow / Forest / Hayfield), S1-S5 = detected on survey 1-5 (0/1), ch =
#         the same five digits, asserted). Palmer drought index files (monthly, regional; a
#         covariate source, not detections) and R code.
# Mapping (standard: capture-recapture of nests within a season; one table per species, as
#   individual-unit tables carry one taxon): unit = nest (N001, file order); period = year
#   (__periods); occasion = survey 1..5; y = detected. A nest exists in one year, so it has rows
#   only in its year (5 rows). unit_habitat. Survey evidence: deposited_matrix.
#   closure = open within the season (nests die: the authors estimate apparent survival).
#   Not shipped: the 9 nests of five rarer or unidentified species (tables of 1-2 nests);
#   Palmer drought indices (regional climate series).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/thuma_2025_massachusetts_bombus_nests.R"
dir <- download_dryad("10.5061/dryad.6t1g1jxbn", "thuma_2025_massachusetts_bombus_nests")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^all_years_capture_history\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, colClasses = list(character = "ch")); setnames(d, trimws(names(d)))
S <- paste0("S", 1:5)
stopifnot(nrow(d) == 111, all(as.matrix(d[, ..S]) %in% 0:1), identical(d$ch, apply(as.matrix(d[, ..S]), 1, paste, collapse = "")),
          all(rowSums(d[, ..S]) > 0), all(d$year %in% 2018:2024), all(d$`Habitat Type` %in% c("Meadow", "Forest", "Hayfield")))
d[, unit := sprintf("N%03d", .I)]
YRS <- 2018:2024
SP <- list(list(key = "Impatiens", table = "thuma_2025_ma_bimpatiens_nest_cr", code = "BOMIMP", sci = "Bombus impatiens", vern = "Common eastern bumble bee", n = 58L),
           list(key = "Griseocollis", table = "thuma_2025_ma_bgriseocollis_nest_cr", code = "BOMGRI", sci = "Bombus griseocollis", vern = "Brown-belted bumble bee", n = 46L))
for (X in SP) {
  x <- d[Species == X$key]; stopifnot(nrow(x) == X$n)
  long <- melt(x[, c("unit", "year", "Habitat Type", S), with = FALSE], id.vars = c("unit", "year", "Habitat Type"), variable.name = "s", value.name = "y", variable.factor = FALSE)
  long <- order_eco(long[, .(unit, taxon = X$code, y = as.integer(y), period = match(year, YRS), occasion = as.integer(sub("S", "", s)), unit_habitat = tolower(`Habitat Type`))])
  stopifnot(nrow(long) == X$n * 5)
  dataset <- list(
    title = sprintf("Detection histories of %d %s nests on five surveys a year in coastal Massachusetts, 2018-2024", X$n, X$sci),
    creator = "Thuma, Jessie; Pugesek, Genevieve; Treanore, Erin; Finn, Sylvana; Crone, Elizabeth", pubDate = "2025",
    doi = "10.5061/dryad.6t1g1jxbn", sourceURL = "https://doi.org/10.5061/dryad.6t1g1jxbn",
    citation = "Thuma, J., Pugesek, G., Treanore, E., Finn, S., & Crone, E. (2025). Bumble bee nest density is lower in drought years [Dataset]. Dryad. https://doi.org/10.5061/dryad.6t1g1jxbn",
    paperDOI = "10.1098/rspb.2025.1010",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Detection (0/1) of each %s nest found on five nest surveys per season in meadow, forest and hayfield habitat in coastal Massachusetts, 2018-2024, with habitat: the mark-recapture input for nest abundance and apparent survival under drought.", X$sci),
    samplingProtocol = "Five systematic nest searches per season in a fixed survey area (meadow, forest, hayfield); each nest found is marked and re-detected or not on later surveys.",
    samplingProtocolCode = "nest_search", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
    closure = "open", closureNote = "nests within a season can die between surveys (the authors estimate apparent survival); each nest exists in one year", occasionKind = "time",
    taxonInclusion = "single", geographicCoverage = "Coastal Massachusetts, USA (see the paper); no coordinates deposited", temporalCoverage = "2018/2024",
    notShipped = list(rare_species = "9 nests of B. bimaculatus (2), B. perplexus (2), B. vagans (1), B. fervidus (1) and unidentified (1): too few per species for a table",
                      drought = "Palmer drought index series (regional climate)"),
    notes = sprintf("Unit = nest; rows only in the nest's year. One of two species tables from this deposit (the other is %s).", setdiff(c(SP[[1]]$table, SP[[2]]$table), X$table)))
  ds <- write_table(long, X$table, dataset, taxa = make_taxa(X$code, X$sci, vernacularName = X$vern), periods = data.table(period = seq_along(YRS), period_year = YRS), script = SCRIPT)
  stage_dict_row(X$table, description = sprintf("Nest detection histories of %d %s nests on five surveys a year in coastal Massachusetts, 2018-2024.", X$n, X$sci),
    url = "https://doi.org/10.5061/dryad.6t1g1jxbn", reference = "Thuma, J. et al. (2025). Bumble bee nest density is lower in drought years. Proceedings of the Royal Society B.",
    doi_paper = "10.1098/rspb.2025.1010", doi_data = "10.5061/dryad.6t1g1jxbn", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Nest capture-recapture within seasons.", source_via = "Dryad")
  stage_tag_row(X$table, ds, taxon_group = "Invertebrates", model_family = "Capture-recapture (nests, within-season)",
    sampling_protocol = "nest_search", design = "Multi-season (7 years x 5 surveys)", realm = "Terrestrial",
    country = "USA", coordinates = "None in source", notes = "Bumble bee nests.")
}
