#!/usr/bin/env Rscript
# Tables: jones_2021_mdg_kittlitzplover_cjs, jones_2021_mdg_madagascarplover_cjs,
#         jones_2021_mdg_whitefrontplover_cjs
# Source: Dryad doi:10.5061/dryad.8931zcrrv (CC0 1.0, as shown on the Dryad page; published
#         2021-11-11). Jones, W., Eberhart-Hertel, L., Freckleton, R., Hoffmann, J., Kruger, O.,
#         Sandercock, B., Vincze, O., Zefania, S. & Szekely, T. Exceptionally high apparent adult
#         survival in three tropical species of plovers in Madagascar.
# Paper:  Jones, W. et al. (2022). Journal of Avian Biology, doi:10.1111/jav.02911. Colour-ringed
#         adult plovers breeding at an intensely monitored saltmarsh in south-west Madagascar,
#         2008-2020 (13 years); CJS apparent survival (abstract).
# Data:   Dryad.xlsx, Sheet4: 1,843 birds (ID = species name + number: Kittlitz 1,071, Madagascar
#         373, Whitefronted 399), Sex (Female / Male / Unknown), 2008..2020 = resighted or
#         recaptured that year (0/1). "This survival matrix contains the resighting/recapture
#         information for each of the 1843 adult plovers" (Dryad methods). Every bird has an
#         encounter.
# Mapping (standard: CJS, E9 core): one table per species. unit = ID; period = year 1..13
#   (__periods); y = 0/1; unit_sex. Rows: the full rectangle from 2008 (E4.4: adults caught in
#   the wild). Survey evidence: deposited_matrix. Madagascar plover is IUCN VU; no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/jones_2021_madagascar_plovers_cjs.R"
dir <- download_dryad("10.5061/dryad.8931zcrrv", "jones_2021_madagascar_plovers_cjs")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Dryad\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
d <- as.data.table(read_excel(f, "Sheet4"))
YR <- as.character(2008:2020)
stopifnot(identical(names(d), c("ID", "Sex", YR)), nrow(d) == 1843, !anyDuplicated(d$ID), all(d$Sex %in% c("Female", "Male", "Unknown")),
          all(as.matrix(d[, ..YR]) %in% 0:1), all(rowSums(d[, ..YR]) > 0))
d[, sp := sub("[0-9]+$", "", ID)]
stopifnot(identical(as.integer(table(d$sp)[c("Kittlitz", "Madagascar", "Whitefronted")]), c(1071L, 373L, 399L)))
SP <- list(list(key = "Kittlitz", table = "jones_2021_mdg_kittlitzplover_cjs", code = "CHAPEC", sci = "Charadrius pecuarius", vern = "Kittlitz's plover", iucn = "LC"),
           list(key = "Madagascar", table = "jones_2021_mdg_madagascarplover_cjs", code = "CHATHO", sci = "Charadrius thoracicus", vern = "Madagascar plover", iucn = "VU"),
           list(key = "Whitefronted", table = "jones_2021_mdg_whitefrontplover_cjs", code = "CHAMAR", sci = "Charadrius marginatus", vern = "White-fronted plover", iucn = "LC"))
periods <- data.table(period = 1:13, period_year = 2008:2020)
for (S in SP) {
  x <- d[sp == S$key]
  long <- melt(x[, c("ID", "Sex", YR), with = FALSE], id.vars = c("ID", "Sex"), variable.name = "yr", value.name = "y", variable.factor = FALSE)
  long <- order_eco(long[, .(unit = ID, taxon = S$code, y = as.integer(y), period = match(yr, YR), unit_sex = tolower(Sex))])
  stopifnot(nrow(long) == nrow(x) * 13)
  taxa <- make_taxa(S$code, S$sci, vernacularName = S$vern)
  dataset <- list(
    title = sprintf("Annual resighting histories of %d colour-ringed adult %ss at a saltmarsh in south-west Madagascar, 2008-2020", nrow(x), S$vern),
    creator = "Jones, William; Eberhart-Hertel, Luke; Freckleton, Robert; Hoffmann, Joseph; Krüger, Oliver; Sandercock, Brett; Vincze, Orsolya; Zefania, Sama; Székely, Tamás",
    pubDate = "2021", doi = "10.5061/dryad.8931zcrrv", sourceURL = "https://doi.org/10.5061/dryad.8931zcrrv",
    citation = "Jones, W. et al. (2021). Exceptionally high apparent adult survival in three tropical species of plovers in Madagascar [Dataset]. Dryad. https://doi.org/10.5061/dryad.8931zcrrv",
    paperDOI = "10.1111/jav.02911",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Annual recapture or resighting (0/1) of %d colour-ringed adult %ss (%s, IUCN %s) breeding at an intensely monitored saltmarsh in south-west Madagascar, 13 years 2008-2020, with sex; one of three species tables from this deposit.", nrow(x), S$vern, S$sci, S$iucn),
    samplingProtocol = "Breeding adults captured at nests and fitted with unique colour-ring combinations; annual resighting and recapture during the breeding season.",
    samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
    closure = "none", closureNote = "one encounter record per bird per year; open between years (CJS)", occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = "Saltmarsh breeding site in south-west Madagascar; no coordinates deposited", temporalCoverage = "2008/2020",
    notShipped = list(none = "the survival matrix is shipped whole"),
    notes = "Rows run from 2008 for every bird (adults caught in the wild); condition on first capture by dropping years before a bird's first 1.")
  ds <- write_table(long, S$table, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(S$table, description = sprintf("CJS resighting histories of %d adult %ss in south-west Madagascar, 2008-2020, with sex.", nrow(x), S$vern),
    url = "https://doi.org/10.5061/dryad.8931zcrrv",
    reference = "Jones, W. et al. (2022). Exceptionally high apparent adult survival in three tropical species of plovers in Madagascar. Journal of Avian Biology.",
    doi_paper = "10.1111/jav.02911", doi_data = "10.5061/dryad.8931zcrrv", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "CJS; one of three plover tables.", source_via = "Dryad")
  stage_tag_row(S$table, ds, taxon_group = "Birds", model_family = "Cormack-Jolly-Seber",
    sampling_protocol = "tag_resight", design = "Multi-season (13 years)", realm = "Terrestrial",
    country = "MDG", coordinates = "None in source", notes = sprintf("IUCN %s.", S$iucn))
}
