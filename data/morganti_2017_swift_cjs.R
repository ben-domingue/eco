#!/usr/bin/env Rscript
# Tables: morganti_2017_modena_commonswift_cjs, morganti_2017_carmagnola_pallidswift_cjs
# Source: Dryad doi:10.5061/dryad.b1t42 (CC0 1.0, as shown on the Dryad page; published
#         2017-09-15). Morganti, M., Rubolini, D., Akesson, S. et al. Data from: Effect of
#         light-level geolocators on apparent survival of two highly aerial swift species.
# Paper:  Morganti, M. et al. (2018). Journal of Avian Biology, doi:10.1111/jav.01521. Swifts
#         at 14 breeding colonies fitted with geolocators and unequipped controls; return rates
#         (GLMM) for all colonies, and capture-recapture (MARK) for two colonies.
# Data:   "capture recapture histories for MARK.xlsx", sheet "all histories": 306 six-occasion
#         histories (one per bird, column `histories`) with group columns mod0 / mod1 / car0 /
#         car1 (legend on the sheet: common swift from Modena without / with geolocator, pallid
#         swift from Carmagnola without / with geolocator; exactly one is 1 per bird, asserted).
#         Other workbooks (all geolocator birds, biometries, return rates) cover the GLMM part
#         of the study and are not capture-recapture histories. The sheet does not give the
#         calendar year of each of the six occasions (annual breeding-season captures).
# Mapping (standard: CJS, E9 core): one table per species and colony (an individual-unit table
#   holds one taxon per survey set). unit = bird (B001..., sheet order); taxon = APUAPU (Modena)
#   or APUPAL (Carmagnola); period = occasion 1..6 of the history (annual); y = 0/1. Full
#   rectangle from the study's first period (E4.4: wild-caught breeding adults); no losses on
#   capture are recorded. unit_geolocator = 1 for the mod1 / car1 groups; unit_colony.
#   Survey evidence: deposited_matrix (MARK histories). No coordinates; both species IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
dir <- download_dryad("10.5061/dryad.b1t42", "morganti_2017_swift_geolocator_cjs")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^capture recapture histories for MARK\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
d <- as.data.table(suppressMessages(read_excel(f, "all histories", col_types = "text")))[, 1:5]
setnames(d, c("h", "mod0", "mod1", "car0", "car1"))
d <- d[!is.na(h) & grepl("^[01]+$", h)]
G <- as.matrix(d[, .(mod0, mod1, car0, car1)]); storage.mode(G) <- "integer"
stopifnot(nrow(d) == 306, all(nchar(d$h) == 6), all(rowSums(G) == 1), identical(as.integer(colSums(G)), c(185L, 28L, 39L, 54L)))
H <- do.call(rbind, strsplit(d$h, "")); storage.mode(H) <- "integer"
stopifnot(all(rowSums(H) > 0))
grp <- c("mod0", "mod1", "car0", "car1")[max.col(G)]
ids <- sprintf("B%03d", seq_len(nrow(H)))
long <- data.table(unit = rep(ids, 6), period = rep(1:6, each = nrow(H)), y = as.vector(H),
                   taxon = rep(ifelse(substr(grp, 1, 3) == "mod", "APUAPU", "APUPAL"), 6),
                   unit_colony = rep(ifelse(substr(grp, 1, 3) == "mod", "Modena", "Carmagnola"), 6),
                   unit_geolocator = rep(as.integer(substr(grp, 4, 4)), 6))
stopifnot(nrow(long) == 306 * 6, sum(long$y) == sum(H))
ALL <- long
periods <- data.table(period = 1:6, period_note = "annual breeding-season capture occasion; calendar year not given in the deposit")
SP <- list(list(table = "morganti_2017_modena_commonswift_cjs", code = "APUAPU", sci = "Apus apus", vern = "Common swift", plural = "common swifts", colony = "Modena", other = "morganti_2017_carmagnola_pallidswift_cjs"),
           list(table = "morganti_2017_carmagnola_pallidswift_cjs", code = "APUPAL", sci = "Apus pallidus", vern = "Pallid swift", plural = "pallid swifts", colony = "Carmagnola", other = "morganti_2017_modena_commonswift_cjs"))
for (S in SP) {
TABLE <- S$table
long <- order_eco(ALL[taxon == S$code][, unit_colony := NULL])
n <- uniqueN(long$unit)
taxa <- make_taxa(S$code, S$sci, vernacularName = S$vern)
dataset <- list(
  title = sprintf("Capture-recapture histories of %d %s with and without geolocators at %s, Italy, six annual occasions", n, S$plural, S$colony),
  creator = "Morganti, Michelangelo; Rubolini, Diego; Åkesson, Susanne; Bermejo, Ana; De la Puente, Javier; Lardelli, Roberto; Liechti, Felix; Boano, Giovanni; Tomassetto, Erika; Ferri, Mauro; Caffi, Mario; Saino, Nicola; Ambrosini, Roberto",
  pubDate = "2017", doi = "10.5061/dryad.b1t42", sourceURL = "https://doi.org/10.5061/dryad.b1t42",
  citation = "Morganti, M. et al. (2017). Data from: Effect of light-level geolocators on apparent survival of two highly aerial swift species [Dataset]. Dryad. https://doi.org/10.5061/dryad.b1t42",
  paperDOI = "10.1111/jav.01521",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Six-occasion annual capture-recapture histories of %d breeding %s (%s) at %s, Italy, each bird either fitted with a light-level geolocator or an unequipped control: part of the MARK input of Morganti et al.'s survival comparison (the other species and colony is %s).", n, S$plural, S$sci, S$colony, S$other),
  samplingProtocol = "Annual capture of breeding adults at colony nest sites; birds ringed and a subset fitted with light-level geolocators; recapture recorded at later annual occasions.",
  samplingProtocolCode = "nest_capture", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "individual", closure = "none", closureNote = "one capture occasion per year; open between years (CJS)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = sprintf("Breeding colony at %s, Italy; no coordinates deposited", S$colony),
  temporalCoverage = "six annual occasions; calendar years not stated in the deposit (paper 2018)",
  notShipped = list(glmm_workbooks = "all geolocator birds, biometries and return-rate workbooks (return-rate GLMM data for 14 colonies, not capture histories)"),
  notes = "Unit ids follow the sheet order of the combined MARK sheet. unit_geolocator marks birds fitted with a geolocator (the treatment groups mod1 / car1).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/morganti_2017_swift_cjs.R")
stage_dict_row(TABLE,
  description = sprintf("CJS capture histories of %d %s with and without geolocators at %s, Italy, six annual occasions.", n, S$plural, S$colony),
  url = "https://doi.org/10.5061/dryad.b1t42",
  reference = "Morganti, M. et al. (2018). Effect of light-level geolocators on apparent survival of two highly aerial swift species. Journal of Avian Biology.",
  doi_paper = "10.1111/jav.01521", doi_data = "10.5061/dryad.b1t42", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "CJS with a device-effect treatment; years not deposited.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Cormack-Jolly-Seber",
  sampling_protocol = "nest_capture", design = "Multi-season (6 annual occasions)", realm = "Terrestrial",
  country = "ITA", coordinates = "None in source", notes = "Geolocator vs control.")
}
