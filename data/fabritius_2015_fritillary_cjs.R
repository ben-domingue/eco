#!/usr/bin/env Rscript
# Tables: fabritius_2015_siitama_fritillary_cjs, fabritius_2015_sorila_fritillary_cjs,
#         fabritius_2015_merikarvia_fritillary_cjs (one script, one deposit, three populations)
# Source: Dryad doi:10.5061/dryad.j54vv (CC0 1.0 as shown on the dataset JSON), version 2931
#   (version 1, published 2016-01-27). Cabeza, M., Fabritius, H., Lehtomaki, J., Ovaskainen, O.,
#   Ronka, K., & Wahlberg, N. Data from: The dual role of rivers in facilitating or hindering
#   movements of the false heath fritillary butterfly.
# Paper:  Fabritius, H., Ronka, K., & Ovaskainen, O. (2015). The dual role of rivers in
#   facilitating or hindering movements of the false heath fritillary butterfly. Movement
#   Ecology 3: 4, doi:10.1186/s40462-015-0031-z (CC BY 4.0; not read: the deposit README gives
#   the design).
# Data:   False_heath_fritillary_MRR_data.zip, and README_for_False_heath_fritillary_MRR_data.pdf
#           (identical to the Readme.pdf inside the zip). Three populations of Melitaea diamina
#           in Finland, each one season of daily mark-release-recapture by search area:
#           Siitama (REF1, 1995, 14 areas, 29 days of which 25 had a search), Sorila (REF2,
#           2006, 112 areas, 14 days, all searched), Merikarvia (RIPARIAN, 2011, 61 areas, 26
#           days of which 21 had a search).
#         data_long/<pop>/<pop>_effort_long.csv: Area x Day x Searched (0/1), the full grid.
#         data_long/<pop>/<pop>_{males,females}_data_long.csv: Individual x Day x Area, the
#           full individual x day grid; Area = 0 not captured, > 0 the search area of capture.
#           Individual ids restart at 1 for each sex.
#         data/<pop>/: the same effort and capture matrices in Mapper / Disperse format (wide;
#           asserted identical to the long files), and ESRI shapefiles of the search areas and
#           of a habitat classification, both shifted from their true position by the authors
#           for landowner privacy.
#         Counts in the data vs the README (captured / recaptured): Siitama males 557 / 295 (README
#           555 / 298), females 285 / 151 (273 / 151); Sorila males 156 / 69 (156 / 76), females
#           95 / 32 (95 / 29); Merikarvia males 91 / 17, females 58 / 18 (as the README). The
#           data are shipped as deposited; recaptured here = captured on two or more days.
# Mapping (CJS, responseType detection, unitKind individual), one table per population:
#   unit = butterfly ("M001", "F001": sex and the deposit's id), taxon = MELIDIAM, period = the
#   deposit's search-day number (only days on which at least one area was searched; days with
#   no search have no rows, so period has gaps), no occasion (one capture record per day).
#   y = 1 if the butterfly was captured that day, 0 if not. obs_capture_area = the search area
#   of capture (NA when y = 0). unit_sex.
#   Survey evidence: effort_table. The effort file lists the areas searched each day; every
#   capture falls on a searched area-day (asserted). A day is a survey if any area was
#   searched; __periods gives the number and list of areas searched that day
#   (period_areas_searched, ";"-separated ids), so individual x area x day histories with
#   area-level non-detections can be rebuilt from this table. Rows exist for every
#   individual on every searched day of its population, including before first capture (E2).
#   Coordinates: none shipped. The search-area shapefiles are shifted by the authors for
#   landowner privacy, so their coordinates are not locations; the README gives each
#   population's position to about 0.05 degree. The source calls the species endangered
#   (flagged, E7 a; GBIF has no global IUCN assessment), so geographicCoverage gives only the
#   0.1-degree cell centre of that position.
#   Not shipped: the shapefiles (shifted search areas and habitat classes; the deposit has
#   them for movement modelling), the Mapper-format duplicates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
DEP <- "fabritius_2015_fritillary_cjs"
dir <- download_dryad("10.5061/dryad.j54vv", DEP)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "2931")
stopifnot(setequal(list.files(dir), c("False_heath_fritillary_MRR_data.zip", "README_for_False_heath_fritillary_MRR_data.pdf")))
zf <- file.path(dir, "False_heath_fritillary_MRR_data.zip")
zl <- unzip(zf, list = TRUE)
stopifnot(nrow(zl) == 51, all(grepl("^(data|data_long)/|^Readme\\.pdf$", zl$Name)))
ux <- file.path(dirname(dir), "unzipped")
if (!dir.exists(ux)) unzip(zf, exdir = ux)

pops <- list(
  list(code = "REF1", folder = "Siitama_REF1", table = "fabritius_2015_siitama_fritillary_cjs", place = "Siitama", region = "Pirkanmaa",
       year = 1995L, lat = 61.6, lon = 24.2, areas = 14L, days = 29L, sdays = 25L, nm = 557L, nf = 285L, rm = 295L, rf = 151L,
       readme = "555 (298) males, 273 (151) females", coord = "Niklas Wahlberg"),
  list(code = "REF2", folder = "Sorila_REF2", table = "fabritius_2015_sorila_fritillary_cjs", place = "Sorila", region = "Pirkanmaa",
       year = 2006L, lat = 61.55, lon = 23.9, areas = 112L, days = 14L, sdays = 14L, nm = 156L, nf = 95L, rm = 69L, rf = 32L,
       readme = "156 (76) males, 95 (29) females", coord = "Mar Cabeza, Otso Ovaskainen"),
  list(code = "RIPARIAN", folder = "Merikarvia_RIPARIAN", table = "fabritius_2015_merikarvia_fritillary_cjs", place = "Merikarvia", region = "Satakunta",
       year = 2011L, lat = 61.86, lon = 21.56, areas = 61L, days = 26L, sdays = 21L, nm = 91L, nf = 58L, rm = 17L, rf = 18L,
       readme = "91 (17) males, 58 (18) females", coord = "Katja Ronka, Henna Fabritius"))

taxa <- make_taxa("MELIDIAM", "Melitaea diamina", vernacularName = "False heath fritillary")
stopifnot(taxa$gbifMatchType == "EXACT", taxa$taxonID == "https://www.gbif.org/species/7768674")
key <- sub(".*/", "", taxa$taxonID); fp <- file.path(GBIF_DIR, paste0("iucn_", key, ".json"))
if (!file.exists(fp)) {
  txt <- paste(readLines(sprintf("https://api.gbif.org/v1/species/%s/iucnRedListCategory", key), warn = FALSE), collapse = "")
  writeLines(if (nzchar(txt)) txt else '{"code": "NE"}', fp)   # HTTP 204 = no assessment in GBIF
}
r <- fromJSON(fp); taxa[, taxon_iucnCategory := if (is.list(r) && length(r) && !is.null(r$code)) r$code else "NE"]
cat("  IUCN (GBIF):", taxa$taxon_iucnCategory, "\n")

wide_check <- function(f, long, idcol, valcol) {   # Mapper-format matrix == long file
  w <- fread(f, header = FALSE, skip = 1, fill = TRUE)
  w <- w[, which(colSums(!is.na(w)) > 0), with = FALSE]
  m <- melt(w, id.vars = "V1", variable.name = "col", value.name = "v")
  m[, Day := as.integer(sub("V", "", col)) - 1L]
  x <- merge(long[, c(idcol, "Day", valcol), with = FALSE], m[, .(id = V1, Day, v)], by.x = c(idcol, "Day"), by.y = c("id", "Day"))
  nrow(x) == nrow(long) && all(x[[valcol]] == x$v)
}

for (P in pops) {
  TABLE <- P$table
  ld <- file.path(ux, "data_long", P$folder); wd <- file.path(ux, "data", P$folder)
  eff <- fread(file.path(ld, paste0(P$code, "_effort_long.csv")))
  stopifnot(identical(names(eff), c("Area", "Day", "Searched")), uniqueN(eff$Area) == P$areas, uniqueN(eff$Day) == P$days,
            nrow(eff) == P$areas * P$days, all(eff$Searched %in% 0:1),
            wide_check(file.path(wd, paste0(P$code, "_effort.txt")), eff, "Area", "Searched"))
  sday <- eff[, .(n = sum(Searched)), by = Day][n > 0, Day]
  stopifnot(length(sday) == P$sdays)
  cap <- rbindlist(lapply(c(males = "M", females = "F"), function(s) {
    f <- file.path(ld, sprintf("%s_%s_data_long.csv", P$code, if (s == "M") "males" else "females"))
    x <- fread(f); stopifnot(identical(names(x), c("Individual", "Day", "Area")), nrow(x) == uniqueN(x$Individual) * P$days,
                             all(x$Area == 0 | x$Area %in% eff$Area),
                             wide_check(sub("_long\\.csv$", ".txt", sub("data_long", "data", f)), x, "Individual", "Area"))
    x[, sex := s]; x }))
  stopifnot(cap[sex == "M", uniqueN(Individual)] == P$nm, cap[sex == "F", uniqueN(Individual)] == P$nf,
            cap[Area > 0, .N, by = .(sex, Individual)][, all(N >= 1)],
            cap[Area > 0, .N, by = .(sex, Individual)][N > 1, .N, by = sex][order(sex), all(N == c(P$rf, P$rm))],
            cap[, .(k = sum(Area > 0)), by = .(sex, Individual)][, all(k >= 1)])   # every listed butterfly was captured at least once
  hit <- merge(cap[Area > 0], eff, by = c("Area", "Day"), all.x = TRUE)
  stopifnot(all(hit$Searched == 1))                                           # captures only on searched area-days
  stopifnot(nrow(cap[Area > 0 & !Day %in% sday]) == 0)
  cap[, unit := sprintf("%s%03d", sex, Individual)]
  long <- cap[Day %in% sday, .(unit, taxon = "MELIDIAM", y = as.integer(Area > 0), period = Day,
                               obs_capture_area = fifelse(Area > 0, Area, NA_integer_), unit_sex = fifelse(sex == "M", "male", "female"))]
  stopifnot(nrow(long) == (P$nm + P$nf) * P$sdays, sum(long$y) == nrow(cap[Area > 0]))
  long <- order_eco(long)
  cc <- coarsen_coords(P$lat, P$lon)
  periods <- eff[Day %in% sday, .(period_year = P$year, period_n_areas_searched = sum(Searched),
                                  period_areas_searched = paste(sort(Area[Searched == 1]), collapse = ";")), by = .(period = Day)]
  setorder(periods, period)
  dataset <- list(
    title = sprintf("Daily mark-release-recapture histories of %d false heath fritillaries (Melitaea diamina) in %d search areas, %s, Finland, %d",
                    P$nm + P$nf, P$areas, P$place, P$year),
    creator = "Cabeza, Mar; Fabritius, Henna; Lehtomaki, Joona; Ovaskainen, Otso; Ronka, Katja; Wahlberg, Niklas",
    pubDate = "2016-01-27", doi = "10.5061/dryad.j54vv", sourceURL = "https://doi.org/10.5061/dryad.j54vv",
    citation = "Cabeza, M., Fabritius, H., Lehtomaki, J., Ovaskainen, O., Ronka, K., & Wahlberg, N. (2016). Data from: The dual role of rivers in facilitating or hindering movements of the false heath fritillary butterfly [Dataset]. Dryad. https://doi.org/10.5061/dryad.j54vv",
    paperDOI = "10.1186/s40462-015-0031-z",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Mark-release-recapture of the endangered false heath fritillary in its %s population (%s, %d; coordinator %s), one of three Finnish populations (two inland reference populations and a riparian population on the coast) compared in Fabritius et al. (2015) with habitat-specific diffusion models of movement. Butterflies were netted, individually marked and released in mapped search areas; each day a subset of the areas was searched and the area of every capture recorded. The paper estimates movement and mortality parameters per habitat type with Mapper / Disperse (Ovaskainen et al. 2008).",
                       P$place, P$region, P$year, P$coord),
    samplingProtocol = sprintf("Daily searches of mapped search areas (%d areas in %s) during the flight season; captured butterflies marked individually and released; the searched areas recorded each day (effort file) and the area of each capture or recapture. Males and females recorded separately.", P$areas, P$place),
    samplingProtocolCode = "net_mark_recapture", occasionLength = "one search day",
    surveyEvidence = "effort_table",
    surveyEvidenceNote = sprintf("The deposited effort file lists, for each of the %d search days, which of the %d areas were searched; %d days had a search and are the periods. Every capture lies on a searched area-day. Rows exist for every marked butterfly on every searched day; __periods lists the areas searched that day, so area-level non-detections can be rebuilt with obs_capture_area.", P$days, P$areas, P$sdays),
    responseType = "detection", unitKind = "individual",
    closure = "period (one search day; survival, emigration and movement between days)",
    lossesOnCapture = "none recorded",
    geographicCoverage = sprintf("%s, %s, Finland (0.1-degree cell centre %.2f N, %.2f E); search-area shapefiles in the deposit are shifted for landowner privacy", P$place, P$region, cc$lat, cc$lon),
    temporalCoverage = as.character(P$year),
    coordinatesCoarsened = list(value = TRUE, method = "No coordinates in the table: the deposit's search-area coordinates are shifted by the authors for landowner privacy. The README's approximate population position is given in geographicCoverage as a 0.1-degree cell centre (coarsen_coords), because the source calls the species endangered (E7 a)."),
    notShipped = list(shapefiles = "search-area and habitat-classification polygons (ESRI shapefiles), shifted from the true location by the authors; area ids in obs_capture_area and period_areas_searched match their MR_ID field",
                      `Mapper-format files` = "data/<pop>/*.txt, the same effort and capture matrices in wide form (asserted identical)"),
    notes = sprintf("Population %s of three in the deposit (Siitama, Sorila, Merikarvia; separate tables, different years and landscapes). Counts differ slightly from the README (%s): shipped as deposited, recaptured = captured on two or more days. Unit ids are sex + the deposit's id (ids restart per sex). period is the deposit's day number; days with no search are absent. No calendar dates are deposited.", P$place, P$readme))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fabritius_2015_fritillary_cjs.R")
  stage_dict_row(TABLE,
    description = sprintf("Daily capture histories of %d individually marked false heath fritillaries (%d males, %d females) over %d search days in %d mapped search areas at %s, Finland, %d, with the area of each capture and the areas searched each day.",
                          P$nm + P$nf, P$nm, P$nf, P$sdays, P$areas, P$place, P$year),
    url = "https://doi.org/10.5061/dryad.j54vv",
    reference = "Fabritius, H., Ronka, K., & Ovaskainen, O. (2015). The dual role of rivers in facilitating or hindering movements of the false heath fritillary butterfly. Movement Ecology, 3, 4.",
    doi_paper = "10.1186/s40462-015-0031-z", doi_data = "10.5061/dryad.j54vv",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "One of three populations from one deposit (sibling tables). Effort per area per day in __periods. Search-area shapefiles (shifted for privacy) not shipped.",
    source_via = "Dryad (version zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "CJS capture-recapture (daily MRR by search area; movement models in the paper)",
    sampling_protocol = "net_mark_recapture", design = sprintf("Multi-session (%d search days in one flight season, %d search areas)", P$sdays, P$areas),
    realm = "Terrestrial", country = "FIN", coordinates = "None in source (search areas shifted by the authors for landowner privacy)",
    notes = "Endangered butterfly; area of capture per record and areas searched per day allow area-level histories.", status = "tagged")
}
