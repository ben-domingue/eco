#!/usr/bin/env Rscript
# Table:  higgins_2022_utila_anole_ccr
# Source: Dryad doi:10.5061/dryad.5mkkwh76b (CC0 1.0, as shown on the Dryad page; published
#         2022-07-08). Higgins, E., Boyd, D., Brown, T., Owen, S. & Algar, A. Abundance of
#         Anolis bicaorum, and niche measurements of plots on the island Utila, Honduras.
# Paper:  Higgins, E. et al. (2021). Ecology and Evolution, doi:10.1002/ece3.7930. Mark-recapture
#         of the Critically Endangered Utila anole in plots on Utila, Honduras, "over 4 survey
#         visits (9am, 1pm, 5pm and 9am the following day)" (Dryad methods); abundance per plot
#         from a closed-population multinomial model (unmarked multinomPois, crPiFun).
# Data:   bicao.csv (92 marked anoles: row name = individual, id = plot letter, Int1-Int4 =
#         capture 0/1 at visits 1-4, Plot = P1..P16; 13 plots occur) and Uncal_bicao.csv (a
#         byte-identical copy, asserted); Uncal_bicaCovs.csv / bicaCovs.csv (13 plots: survey
#         time and date indices, leaf area index, sweep-net and leaf-litter prey diversity and
#         biomass, thermal-model deviations from preferred temperature, perches, basal area,
#         Anolis sagrei abundance); Count_Abicaorum.xlsx (the same histories tallied by
#         pattern per plot); A.bicaorum_abundance.csv (model predictions); temperature and
#         invertebrate files; R code. 3 histories are all zero.
# Mapping (standard: closed-population capture-recapture, E9 core): unit = individual
#   ("<plot>_<id>"); taxon = ANOBIC; one period; occasion = visit 1..4; y = Intk; cluster_id =
#   plot (each plot is its own closed population). Every marked individual carries a row for
#   all 4 visits of its plot (all 13 plots had 4 visits). Survey evidence: deposited_matrix.
#   unit_: plot habitat (leaf area index, perches, basal area, prey biomass and diversity),
#   from Uncal_bicaCovs.csv joined by plot code.
#   Not shipped: the 3 all-zero histories (never caught, not units); model predictions
#   (A.bicaorum_abundance.csv) and Sagrei.abundance ("abundance calculated from unmarked
#   models"); the thermal deviation covariates (calibrated and uncalibrated versions disagree,
#   and the README does not say which the paper used); time/date indices (codes the README
#   does not define beyond "used for estimates"); Count_Abicaorum.xlsx (a tally of the same
#   histories). A. bicaorum is IUCN CR; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "higgins_2022_utila_anole_ccr"
dir <- download_dryad("10.5061/dryad.5mkkwh76b", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); f }
b <- fread(rf("bicao\\.csv"))
stopifnot(identical(b, fread(rf("Uncal_bicao\\.csv"))))
setnames(b, 1, "ind"); b <- b[ind != "" | !is.na(Int1)]
stopifnot(identical(names(b), c("ind", "id", "Int1", "Int2", "Int3", "Int4", "Plot")), nrow(b) == 92, uniqueN(b$Plot) == 13)
stopifnot(!anyDuplicated(b$ind), b[, uniqueN(id), by = Plot][, all(V1 == 1)], all(as.matrix(b[, Int1:Int4]) %in% 0:1))
H <- as.matrix(b[, .(Int1, Int2, Int3, Int4)])
stopifnot(sum(rowSums(H) == 0) == 3)
b <- b[rowSums(H) > 0]
cv <- fread(rf("Uncal_bicaCovs\\.csv"))
stopifnot(nrow(cv) == 13, all(b$Plot %in% cv$Plot)); stopifnot(uniqueN(b$Plot) == 10, setequal(setdiff(cv$Plot, b$Plot), c("P6", "P11", "P13")))   # the 3 all-zero rows are those plots' only rows
long <- melt(b[, .(unit = paste(Plot, ind, sep = "_"), cluster_id = Plot, Int1, Int2, Int3, Int4)],
             id.vars = c("unit", "cluster_id"), variable.name = "v", value.name = "y")
long[, `:=`(occasion = as.integer(sub("Int", "", v)), taxon = "ANOBIC", y = as.integer(y))][, v := NULL]
long <- merge(long, cv[, .(cluster_id = Plot, unit_lai = LAI.Transects, unit_sweep_shannon = Shannon.Div.Sweep,
                           unit_sweep_simpson = Sweep.Simpson.Index, unit_sweep_biomass_g = Sweep.net.biomass,
                           unit_prey_shannon = combined.prey.shannon, unit_prey_simpson = combined.prey.simpson,
                           unit_prey_biomass_g = Combined.biomass, unit_n_perches = No.perches,
                           unit_basal_area_m2 = Basal.area)], by = "cluster_id")
long <- order_eco(long)
stopifnot(nrow(long) == 89 * 4, sum(long$y) == 195, uniqueN(long$unit) == 89)
taxa <- make_taxa("ANOBIC", "Anolis bicaorum", vernacularName = "Utila anole")
dataset <- list(
  title = "Mark-recapture histories of 89 Critically Endangered Utila anoles in 10 plots on Utila, Honduras, four visits per plot",
  creator = "Higgins, Emma; Boyd, Doreen; Brown, Tom; Owen, Sarah; Algar, Adam", pubDate = "2022",
  doi = "10.5061/dryad.5mkkwh76b", sourceURL = "https://doi.org/10.5061/dryad.5mkkwh76b",
  citation = "Higgins, E., Boyd, D., Brown, T., Owen, S., & Algar, A. (2022). Abundance of Anolis bicaorum, and niche measurements of plots on the island Utila, Honduras [Dataset]. Dryad. https://doi.org/10.5061/dryad.5mkkwh76b",
  paperDOI = "10.1002/ece3.7930",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture histories of individually marked Utila anoles (Anolis bicaorum, IUCN CR) in 10 forest and urban plots on Utila, Honduras (13 plots surveyed; 3 with no capture), each plot surveyed four times (9 am, 1 pm, 5 pm and 9 am the next day), with plot leaf area index, perch counts, basal area and invertebrate prey diversity and biomass: the input of a closed-population multinomial abundance model per plot.",
  samplingProtocol = "Visual search and capture-mark-recapture of anoles in fixed plots, four visits per plot over about 24 hours (9 am, 1 pm, 5 pm, 9 am next day); each individual recorded as captured or not at each visit.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "individual", closure = "closed", closureNote = "four visits within about 24 hours per plot; each plot a closed population",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Utila, Bay Islands, Honduras; no coordinates deposited",
  temporalCoverage = "survey dates not stated in the deposit (about 10 weeks of fieldwork; paper 2021)",
  designNote = "Closed-population capture-recapture: cluster_id = plot (10 plots with captures, each an independent closed population), occasion = visit. Individual ids are unique within the deposit.",
  notShipped = list(all_zero_histories = "3 all-zero rows, the only rows of plots P6, P11 and P13 (no anole captured there; not units)",
                    model_outputs = "A.bicaorum_abundance.csv predictions and Sagrei.abundance (from unmarked models)",
                    thermal_covariates = "Tpref.Dev, Tpref.3, Dev.Above, Dev.Below: calibrated and uncalibrated files disagree",
                    time_date_indices = "time.k / date.k codes, not defined beyond 'used for estimates'",
                    pattern_tally = "Count_Abicaorum.xlsx, a tally of the same histories by capture pattern"),
  notes = "Anolis bicaorum is IUCN CR; no coordinates are deposited. Unit ids are '<plot>_<deposited row name>'.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/higgins_2022_utila_anole_ccr.R")
stage_dict_row(TABLE,
  description = "Closed-population mark-recapture histories of 89 Critically Endangered Utila anoles in 10 plots on Utila, Honduras, four visits per plot, with plot habitat and prey covariates.",
  url = "https://doi.org/10.5061/dryad.5mkkwh76b",
  reference = "Higgins, E., Boyd, D., Brown, T., Owen, S., & Algar, A. (2021). Ecology and Evolution.",
  doi_paper = "10.1002/ece3.7930", doi_data = "10.5061/dryad.5mkkwh76b", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed CR, plots as clusters; CR species, no coordinates.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Closed-population capture-recapture",
  sampling_protocol = "visual_encounter", design = "Single-season (4 visits per plot, 10 plots with captures)", realm = "Terrestrial",
  country = "HND", coordinates = "None in source", notes = "IUCN CR lizard.")
