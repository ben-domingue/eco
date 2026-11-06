#!/usr/bin/env Rscript
# Table:  peron_2017_sabap2_broodparasites_occ
# Source: Dryad doi:10.5061/dryad.5b8t8 (CC0 1.0, as shown on the Dryad page; published
#         2017-05-02). Peron, G., Altwegg, R., Jamie, G.A. & Spottiswoode, C.N. Data from:
#         Coupled range dynamics of brood parasites and their hosts responding to climate and
#         vegetation changes.
# Paper:  Peron, G. et al. (2016). Journal of Animal Ecology 85(5), doi:10.1111/1365-2656.12546.
#         Second Southern African Bird Atlas Project (SABAP2) checklists, 2007-2013, for four
#         brood parasites and their hosts; multi-species dynamic occupancy (abstract).
# Data:   BroodParasites_dataSABAP2_ForArchivalOnDryad.csv (82,189 atlas cards: Cardno, Year
#         2007-2013, Month, lat / long = upper-left corner of the card's quarter-degree grid cell
#         (README), and for 8 species <code>_IIH (1 if detected during the initial intensive
#         period) and <code>_OnCard (1 if detected after the initial period); README defines all
#         columns). Card numbers come in mixed formats (pentad, observer and date parse for most,
#         not all), so cards are placed by their grid cell, year and month. SABAP1 file: its
#         columns (data1, V2-V6, two named) do not match its README; not built.
# Mapping (standard: dynamic community occupancy, E9 core): unit = quarter-degree cell
#   ("<lat>_<long>"); period = year (__periods); occasion = card k within the cell-year, ordered
#   by month then card number (the rule; same-month cards are not ordered in time); taxon =
#   species code; y = 1 if detected on the card (IIH or OnCard); obs_iih and obs_oncard = the
#   deposited flags (within-visit periods, ruling 2026-11-06); obs_month. unit_: cell corner
#   lat / long (quarter-degree resolution, as published). Survey evidence: row_presence (an
#   atlas card is a complete checklist; every species has a value on every card).
#   Not shipped: card numbers (contain observer numbers); SABAP1 file (columns undefined).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "peron_2017_sabap2_broodparasites_occ"
dir <- download_dryad("10.5061/dryad.5b8t8", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^BroodParasites_dataSABAP2_ForArchivalOnDryad\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, colClasses = list(character = c("Cardno", "Month")))
SPN <- c(`851` = "Vidua chalybeata", `849` = "Vidua funerea", `850` = "Vidua purpurascens", `837` = "Lagonosticta senegala",
         `833` = "Lagonosticta rubricata", `835` = "Lagonosticta rhodopareia", `431` = "Indicator minor", `442` = "Lybius torquatus")
VN <- c("Village indigobird", "Dusky indigobird", "Purple indigobird", "Red-billed firefinch", "African firefinch", "Jameson's firefinch", "Lesser honeyguide", "Black-collared barbet")
cols <- as.vector(rbind(paste0(names(SPN), "_IIH"), paste0(names(SPN), "_OnCard")))
stopifnot(identical(names(d), c("V1", "Cardno", "Year", "Month", "lat", "long", cols)), nrow(d) == 82189, !anyDuplicated(d$Cardno),
          all(d$Year %in% 2007:2013), all(d$Month %in% sprintf("%02d", 1:12)), all(as.matrix(d[, ..cols]) %in% 0:1), !anyNA(d[, .(lat, long)]))
d[, unit := sprintf("%.2f_%.2f", lat, long)]
setorder(d, unit, Year, Month, Cardno)
d[, occasion := seq_len(.N), by = .(unit, Year)]
code <- c(`851` = "VIDCHA", `849` = "VIDFUN", `850` = "VIDPUR", `837` = "LAGSEN", `833` = "LAGRUB", `835` = "LAGRHO", `431` = "INDMIN", `442` = "LYBTOR")
long <- rbindlist(lapply(names(SPN), function(k) d[, .(unit, period = Year - 2006L, occasion, taxon = code[[k]], obs_iih = get(paste0(k, "_IIH")), obs_oncard = get(paste0(k, "_OnCard")),
                                                       obs_month = as.integer(Month), unit_cell_lat = lat, unit_cell_long = long)]))
long[, y := as.integer(obs_iih == 1 | obs_oncard == 1)]
long <- order_eco(long)
stopifnot(nrow(long) == 82189 * 8)
periods <- data.table(period = 1:7, period_year = 2007:2013)
taxa <- make_taxa(unname(code), unname(SPN), vernacularName = VN,
                  taxonRemarks = c(rep(NA, 7), "the README names species 442 \"black-breasted barbet\" (Lybius rolleti, not a southern African species); taken as the black-collared barbet Lybius torquatus, the lesser honeyguide host in the SABAP2 region (processor's reading)"))
dataset <- list(
  title = "SABAP2 atlas-card detections of three indigobirds, three firefinches, lesser honeyguide and black-collared barbet in southern African quarter-degree cells, 2007-2013",
  creator = "Péron, Guillaume; Altwegg, Res; Jamie, Gabriel A.; Spottiswoode, Claire N.", pubDate = "2017", doi = "10.5061/dryad.5b8t8", sourceURL = "https://doi.org/10.5061/dryad.5b8t8",
  citation = "Péron, G., Altwegg, R., Jamie, G. A., & Spottiswoode, C. N. (2017). Data from: Coupled range dynamics of brood parasites and their hosts responding to climate and vegetation changes [Dataset]. Dryad. https://doi.org/10.5061/dryad.5b8t8",
  paperDOI = "10.1111/1365-2656.12546",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of four brood parasites (village, dusky and purple indigobirds; lesser honeyguide) and their hosts (red-billed, African and Jameson's firefinches; black-collared barbet) on 82,189 Second Southern African Bird Atlas Project checklists (atlas cards) in 2007-2013, grouped by quarter-degree grid cell and year, with detection in the initial intensive period and later on the card kept separately.",
  samplingProtocol = "SABAP2 atlas cards: an observer records every species found in a pentad, with an initial intensive period of at least two hours and further species added during up to five days; each card a complete checklist.",
  samplingProtocolCode = "checklist", surveyEvidence = "row_presence", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors model annual occupancy dynamics; cards within a cell-year are treated as replicates", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "South Africa, Lesotho and Swaziland (SABAP2 region); quarter-degree cell corners in decimal degrees",
  temporalCoverage = "2007/2013", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "as published: quarter-degree cell corners; all eight species IUCN LC"),
  notShipped = list(card_numbers = "Cardno (pentad, observer number and date in mixed formats)", sabap1 = "the SABAP1 file, whose columns do not match its README"),
  notes = "unit is the quarter-degree cell (the card's pentad is not reliably parseable for all cards). Occasions are the cell-year's cards ordered by month then card number; cards within a month are not ordered in time. y = detected anywhere on the card; obs_iih and obs_oncard are the deposited initial-period and later flags (both 1 on many cards). The species are the authors' selection from complete checklists. Species 442 is named \"black-breasted barbet\" in the README and taken here as the black-collared barbet (see __taxa).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/peron_2017_sabap2_broodparasites_occ.R")
stage_dict_row(TABLE, description = "SABAP2 atlas-card detections of eight brood-parasite and host bird species in southern African quarter-degree cells, 2007-2013.",
  url = "https://doi.org/10.5061/dryad.5b8t8", reference = "Péron, G., Altwegg, R., Jamie, G. A., & Spottiswoode, C. N. (2016). Coupled range dynamics of brood parasites and their hosts responding to climate and vegetation changes. Journal of Animal Ecology, 85(5).",
  doi_paper = "10.1111/1365-2656.12546", doi_data = "10.5061/dryad.5b8t8", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Atlas checklists as surveys; SABAP1 file not built.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic community occupancy (interactions)",
  sampling_protocol = "checklist", design = "Multi-season (7 years, atlas cards as replicates)", realm = "Terrestrial",
  country = "ZAF,LSO,SWZ", coordinates = "As published (quarter-degree cell corners)", notes = "Citizen-science atlas.")
