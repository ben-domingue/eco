#!/usr/bin/env Rscript
# Table:  ademola_2021_ukaguru_praomys_cjs
# Source: Dryad doi:10.5061/dryad.j6q573ncr (source of record), CC0 1.0, fetched from its Zenodo mirror (record 5907851,
#         which carries the Dryad DOI; licence id "cc-zero", asserted). No request was made to Dryad.
#   Ademola, O. J. (2021). Praomys delectorum capture-mark-recapture dataset from fieldwork on the Ukaguru Mountains,
#   Tanzania [Dataset]. Dryad.
# Paper:  Ademola, O. J., Vanden Broecke, B., Leirs, H., Mulungu, L. S., Massawe, A. W. & Makundi, R. H. (2021).
#         Effects of forest disturbance on the fitness of an endemic rodent in a biodiversity hotspot. Ecology and
#         Evolution 11, 2391-2401. doi:10.1002/ece3.7214 (open access; read from Europe PMC PMC7920783). Section 2.2:
#         capture-mark-recapture June 2018 to February 2020 on four 70 x 70 m grids, two in intact forest (H2, L2) and
#         two in disturbed forest (D1, D2), 600 m apart; 7 x 7 Sherman traps per grid, 10 m apart; "Trapping of rodents
#         was conducted for three consecutive nights every month"; toe clipping for identification; monthly CJS with
#         time-dependent recapture per grid.
# Data:   ADEMOLA_et_al._2021.txt (readme); Data_Ademola_et_al._2021.xlsx (sheet Blad1): 1,467 Praomys delectorum
#         captures: Grid, Habitat_Type, Trap_Date (Excel date), Species, Toe Codes (individual id; unique within a
#         grid, no code used on two grids, asserted; one code is written "16106070b" and kept as recorded), Trap Line
#         (1-7), Trap Station (A-G), Weight (g), Sex Condition, Sex, and an unnamed column with "*" on 2 rows
#         (undefined; not shipped). Data_Ademola_et_al._2021_all_spp.xlsx: 1,672 captures of all small mammals on the
#         same grids (10 taxa), dates as Excel serials or dd/mm/yyyy; used here only to check which grid-months had
#         captures of anything.
# Mapping (CJS, monthly sessions): unit = "<grid>_<toe code>", cluster_id = grid, taxon = PRADEL, period = month
#   (1 = June 2018 ... 21 = February 2020), y = 1 if the animal was caught in that grid's session, else 0 (the three
#   nights pooled, as the authors' monthly model does). Survey set (surveyEvidence = inferred): a grid-month is a
#   session where the all-species file has a capture of any small mammal on that grid. The paper's protocol schedules
#   every grid every month from June 2018 to February 2020 (84 grid-months); four have no capture of any species
#   (D1 and D2 in June 2018, L2 in March and April 2019) and are not shipped (ruling 2026-11-06, protocol-only zeros;
#   batch 43 had kept L2's two months as surveyed with no capture), leaving 80. Each animal has rows from its grid's
#   first session at every session of its grid (wild-caught, unknown age, E4.4). unit_habitat (intact / disturbed
#   forest), unit_sex (as recorded; constant per animal, asserted). No coordinates deposited (grid names only).
#   Praomys delectorum IUCN LC.
#   Not shipped: trap line and station of each capture (SCR would need every trap's nights, which are not
#   deposited); weight and reproductive condition per capture; the other species (all-species file).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ademola_2021_ukaguru_praomys_cjs"
REC <- "5907851"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-zero"), identical(meta$doi, "10.5061/dryad.j6q573ncr"),
          setequal(meta$files$key, c("Data_Ademola_et_al._2021.xlsx", "ADEMOLA_et_al._2021.txt", "Data_Ademola_et_al._2021_all_spp.xlsx")))
invisible(zen("ADEMOLA_et_al._2021.txt"))
p <- as.data.table(suppressMessages(readxl::read_excel(zen("Data_Ademola_et_al._2021.xlsx"), col_types = "text")))
a <- as.data.table(suppressMessages(readxl::read_excel(zen("Data_Ademola_et_al._2021_all_spp.xlsx"), col_types = "text")))
stopifnot(nrow(p) == 1467L, identical(names(p)[1:10], c("Grid", "Habitat_Type", "Trap_Date", "Species", "Toe Codes", "Trap Line", "Trap Station", "Weight (g)", "Sex Condition", "Sex")),
          all(p$Species == "Praomys delectorum"), setequal(p$Grid, c("D1", "D2", "H2", "L2")), all(p$Sex %in% c("F", "M")),
          sum(!is.na(p[[11]])) == 2L, nrow(a) == 1672L)
p[, d := as.Date(as.numeric(Trap_Date), origin = "1899-12-30")]
a[, d := suppressWarnings(as.Date(as.numeric(Trap_Date), origin = "1899-12-30"))][is.na(d), d := as.Date(Trap_Date, "%d/%m/%Y")]
stopifnot(!anyNA(p$d), !anyNA(a$d), all(p$d >= as.Date("2018-06-01") & p$d <= as.Date("2020-02-29")))
mon <- function(x) (as.integer(format(x, "%Y")) - 2018L) * 12L + as.integer(format(x, "%m")) - 5L
p[, period := mon(d)]; a[, period := mon(d)]
stopifnot(all(p$period %in% 1:21), all(a$period %in% 1:21))
first <- a[, .(first = min(period)), by = Grid]
stopifnot(identical(first[order(Grid)]$first, c(2L, 2L, 1L, 1L)))
cov <- a[, .(n = .N), by = .(Grid, period)]
gaps <- CJ(Grid = first$Grid, period = 1:21)[first, on = "Grid"][period >= first][!cov, on = .(Grid, period)]
stopifnot(nrow(gaps) == 2L, all(gaps$Grid == "L2"), identical(sort(gaps$period), c(10L, 11L)))
# Protocol-only sessions (ruling 2026-11-06): scheduled by the protocol, no capture of any species there.
sessions <- unique(a[, .(Grid, period)])
proto <- CJ(Grid = first$Grid, period = 1:21)[!sessions, on = .(Grid, period)]
stopifnot(nrow(sessions) == 80L, nrow(proto) == 4L,
          identical(proto[order(Grid, period), paste(Grid, period)], c("D1 1", "D2 1", "L2 10", "L2 11")))
stopifnot(p[, uniqueN(Grid), by = `Toe Codes`][, all(V1 == 1L)], p[, uniqueN(Sex), by = .(Grid, `Toe Codes`)][, all(V1 == 1L)])
ind <- unique(p[, .(unit = paste0(Grid, "_", `Toe Codes`), Grid, unit_habitat = tolower(sub(" forest$", "", Habitat_Type)), unit_sex = Sex)])
stopifnot(!anyDuplicated(ind$unit))
ind <- merge(ind, first, by = "Grid")
long <- ind[, .(period = first:21L), by = .(unit, Grid, unit_habitat, unit_sex)]
n_before <- nrow(long)
long <- long[sessions, on = .(Grid, period), nomatch = NULL]
n_proto_rows <- n_before - nrow(long)
stopifnot(n_proto_rows == ind[Grid == "L2", .N] * 2L)
caps <- unique(p[, .(unit = paste0(Grid, "_", `Toe Codes`), period)])
long[, y := 0L][caps, on = .(unit, period), y := 1L]
long[, `:=`(taxon = "PRADEL", cluster_id = Grid)][, Grid := NULL]
long <- order_eco(long)
stopifnot(sum(long$y) == nrow(caps), uniqueN(long$unit) == nrow(ind))
cat(sprintf("  %d animals, %d rows, %d animal-sessions caught (%d captures)\n", nrow(ind), nrow(long), sum(long$y), nrow(p)))
taxa <- make_taxa("PRADEL", "Praomys delectorum", vernacularName = "Delectable soft-furred mouse")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, gbifMatchType, taxon_iucnCategory)])
periods <- data.table(period = 1:21, month = format(seq(as.Date("2018-06-01"), by = "month", length.out = 21), "%Y-%m"))
dataset <- list(
  title = "Monthly capture histories of 622 Praomys delectorum on four live-trapping grids in intact and disturbed forest, Ukaguru Mountains, Tanzania, June 2018-February 2020",
  creator = "Ademola, Olaoluwa John", pubDate = "2021", doi = "10.5061/dryad.j6q573ncr", sourceURL = "https://doi.org/10.5061/dryad.j6q573ncr",
  citation = "Ademola, O. J. (2021). Praomys delectorum capture-mark-recapture dataset from fieldwork on the Ukaguru Mountains, Tanzania [Dataset]. Dryad. https://doi.org/10.5061/dryad.j6q573ncr",
  paperDOI = "10.1002/ece3.7214",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-mark-recapture of the endemic rodent Praomys delectorum on four 7 x 7 Sherman-trap grids (two in intact, two in disturbed montane forest) in the Ukaguru Mountains, Eastern Arc, Tanzania, trapped for three consecutive nights every month from June 2018 to February 2020; animals individually marked by toe clipping. The authors modelled survival and maturation by forest type.",
  samplingProtocol = "Four 70 x 70 m grids of 49 Sherman LFA live traps (7 lines x 7 stations, 10 m apart), baited with peanut butter and maize bran, run for three consecutive nights every month and checked each morning; animals toe-clipped, sexed, weighed and aged.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Sessions are grid-months, inferred from detections: a grid-month is a session where the deposit's all-species file has a capture of any small mammal on that grid (80 grid-months). Sessions with no capture of anything are absent: the paper's protocol ('three consecutive nights every month', June 2018 to February 2020) also schedules D1 and D2 in June 2018 and L2 in March and April 2019, which have no capture of any species and are not shipped (ruling 2026-11-06). The deposit has no list of trapping sessions.",
  responseType = "detection", unitKind = "individual", closure = "none",
  closureNote = "One period per monthly session; the three nights of a session are pooled (the deposit's dates allow nights, but nights with no capture on a grid are not recorded).",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Ukaguru Mountains, Gairo District, Morogoro, Tanzania (about 6.4-7.0 S, 36.95-38.0 E; grids H2, L2, D1, D2, no coordinates deposited)",
  temporalCoverage = "2018-06/2020-02",
  covariateNote = "cluster_id: trapping grid. unit_habitat: intact or disturbed forest. unit_sex: F or M.",
  notShipped = list(trap_station = "trap line and station of each capture", per_capture = "weight and reproductive condition at each capture",
                    star_column = "an unnamed column with '*' on 2 rows (undefined)",
                    other_species = "captures of 9 other small-mammal taxa in the all-species file (used only to check session coverage)",
                    protocol_only_sessions = sprintf("4 grid-months the protocol schedules but with no capture of any species (D1 and D2 June 2018, L2 March and April 2019; ruling 2026-11-06, protocol-only zeros), %d animal rows at L2", n_proto_rows)),
  notes = "Animals have rows from their grid's first session (E4.4), at every session of their grid. Sessions are grid-months with a capture of any species; L2 has no session in March and April 2019 (surveyEvidenceNote). Rebuilt 2026-11-06 (batch 47) to drop those two protocol-only sessions.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ademola_2021_ukaguru_praomys_cjs.R")
stage_dict_row(TABLE,
  description = "Monthly CJS capture histories of Praomys delectorum on four live-trapping grids in intact and disturbed forest, Ukaguru Mountains, Tanzania, 2018-2020.",
  url = "https://doi.org/10.5061/dryad.j6q573ncr",
  reference = "Ademola, O. J., Vanden Broecke, B., Leirs, H., Mulungu, L. S., Massawe, A. W. & Makundi, R. H. (2021). Effects of forest disturbance on the fitness of an endemic rodent in a biodiversity hotspot. Ecology and Evolution 11, 2391-2401. https://doi.org/10.1002/ece3.7214",
  doi_paper = "10.1002/ece3.7214", doi_data = "10.5061/dryad.j6q573ncr", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad deposit fetched from its Zenodo mirror (record 5907851, carrying the Dryad DOI). Sessions inferred from captures of any species.",
  source_via = "Zenodo mirror of Dryad (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (21 monthly sessions, 4 grids)",
  realm = "Terrestrial", country = "TZA", coordinates = "None in source", notes = "Survey set inferred from captures of any species.")
