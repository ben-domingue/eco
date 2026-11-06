#!/usr/bin/env Rscript
# Table:  hamer_2017_wtp_growlingfrog_dynocc
# Source: Dryad doi:10.5061/dryad.f83c6 (CC0 1.0, as shown on the Dryad page; published
#         2017-06-21). Hamer, A.J., Heard, G.W., Urlus, J., Ricciardello, J., Schmidt, B.,
#         Quin, D. & Steele, W.K. Data from: Manipulating wetland hydroperiod to improve occupancy
#         rates by an endangered amphibian: modelling management scenarios.
# Paper:  Hamer, A.J. et al. (2016). Journal of Applied Ecology, doi:10.1111/1365-2664.12729.
#         Growling grass frog (Litoria raniformis, IUCN VU) wetland occupancy at a wastewater
#         treatment plant in southern Victoria, Australia; dynamic occupancy (Bayesian), four
#         seasons 2010/11-2013/14 (abstract).
# Data:   "Hamer et al_2016_JAPPLE_Habitat&Detection_Data.xlsx", one sheet, 33 sites (rows 3-35):
#         Site ID; site number; Effective Area per season (4 columns); Mean Cover of Aquatic
#         Vegetation per season (4); log(EC); Turbidity; Detection: 2010/2011 surveys 1-3,
#         2011/2012 surveys 1-2, 2012/2013 surveys 1-3, 2013/2014 surveys 1-2 (0/1, NA = not
#         surveyed); a 33 x 33 site distance matrix (m). Two WinBUGS model files (.odc).
# Mapping (standard: dynamic occupancy, E9 core): unit = Site ID; taxon = LITRAN; period = season
#   1..4 (__periods); occasion = survey within the season; y = the cell; NA = no row.
#   period_: effective area and aquatic vegetation cover (per season); unit_: log(EC), turbidity.
#   Survey evidence: deposited_matrix. Not shipped: the site distance matrix (a derived spatial
#   structure, no coordinates), the model files. No coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hamer_2017_wtp_growlingfrog_dynocc"
dir <- download_dryad("10.5061/dryad.f83c6", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "Habitat&Detection_Data\\.xlsx$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
suppressMessages(library(readxl))
d <- as.data.frame(suppressMessages(read_excel(f, col_names = FALSE, col_types = "text")))
stopifnot(
          d[1, 1] == "Site ID", d[1, 3] == "Effective Area", d[1, 9] == "Mean Cover of Aquatic Vegetation", d[1, 15] == "log(EC)", d[1, 18] == "Turbidity", d[1, 20] == "Detection",
          identical(as.character(d[2, 3:6]), c("2010/2011", "2011/2012", "2012/2013", "2013/2014")))
x <- d[3:35, ]; stopifnot(nrow(x) == 33, !anyDuplicated(x[[1]]), all(as.integer(x[[2]]) == 1:33))
num <- function(v) as.numeric(v)
DC <- 21:30; per <- c(1, 1, 1, 2, 2, 3, 3, 3, 4, 4); occ <- c(1, 2, 3, 1, 2, 1, 2, 3, 1, 2)
stopifnot(identical(as.character(d[2, DC]), c("Survey 1", "Survey 2", "Survey 3", "Survey 1", "Survey 2", "Survey 1", "Survey 2", "Survey 3", "Survey 1", "Survey 2")),
          identical(as.character(d[1, c(21, 24, 26, 29)]), c("2010/2011", "2011/2012", "2012/2013", "2013/2014")))
stopifnot(all(unlist(x[DC]) %in% c("0", "1", "NA")))   # "NA" written as text = not surveyed
Y <- sapply(DC, function(j) suppressWarnings(num(x[[j]]))); stopifnot(all(Y %in% c(0, 1, NA)), sum(is.na(Y)) == 97)
long <- data.table(unit = rep(x[[1]], 10), k = rep(1:10, each = 33), y = as.vector(Y))[!is.na(y)]
long[, `:=`(period = per[k], occasion = occ[k], y = as.integer(y), taxon = "LITRAN")]
pc <- data.table(unit = rep(x[[1]], 4), period = rep(1:4, each = 33), period_effective_area = num(unlist(x[3:6])), period_aquatic_veg_cover = num(unlist(x[9:12])))
long <- merge(long[, k := NULL], pc, by = c("unit", "period"))
long <- merge(long, data.table(unit = x[[1]], unit_log_ec = num(x[[15]]), unit_turbidity = num(x[[18]])), by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(Y)))
periods <- data.table(period = 1:4, period_season = c("2010/2011", "2011/2012", "2012/2013", "2013/2014"))
taxa <- make_taxa("LITRAN", "Litoria raniformis", vernacularName = "Growling grass frog")
dataset <- list(
  title = "Growling grass frog detections at 33 wetlands of a wastewater treatment plant in Victoria, Australia, four seasons 2010/11-2013/14",
  creator = "Hamer, Andrew J.; Heard, Geoffrey W.; Urlus, Jake; Ricciardello, Jonathon; Schmidt, Bernadette; Quin, Darren; Steele, William K.", pubDate = "2017",
  doi = "10.5061/dryad.f83c6", sourceURL = "https://doi.org/10.5061/dryad.f83c6",
  citation = "Hamer, A. J. et al. (2017). Data from: Manipulating wetland hydroperiod to improve occupancy rates by an endangered amphibian: modelling management scenarios [Dataset]. Dryad. https://doi.org/10.5061/dryad.f83c6",
  paperDOI = "10.1111/1365-2664.12729",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the growling grass frog (Litoria raniformis, IUCN VU) on two or three surveys per breeding season at 33 wetlands of a wastewater treatment plant in southern Victoria, Australia, 2010/11-2013/14, with effective wetland area and aquatic vegetation cover per season and water conductivity and turbidity.",
  samplingProtocol = "Repeated surveys of wetlands for growling grass frogs (two or three per breeding season); detection recorded per survey.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "closed within a breeding season, open between the four seasons (dynamic occupancy)", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = "Western Treatment Plant, southern Victoria, Australia; no coordinates deposited", temporalCoverage = "2010/2014",
  notShipped = list(distance_matrix = "33 x 33 inter-site distances (m)", models = "WinBUGS model files"),
  notes = "Growling grass frog is IUCN VU; no coordinates are deposited. Survey methods (call / visual) per the paper.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hamer_2017_wtp_growlingfrog_dynocc.R")
stage_dict_row(TABLE, description = "Growling grass frog detections at 33 wetlands of the Western Treatment Plant, Victoria, four breeding seasons 2010/11-2013/14, with wetland covariates.",
  url = "https://doi.org/10.5061/dryad.f83c6", reference = "Hamer, A. J. et al. (2016). Manipulating wetland hydroperiod to improve occupancy rates by an endangered amphibian: modelling management scenarios. Journal of Applied Ecology.",
  doi_paper = "10.1111/1365-2664.12729", doi_data = "10.5061/dryad.f83c6", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic occupancy of a VU frog.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Dynamic occupancy",
  sampling_protocol = "visual_encounter", design = "Multi-season (4 seasons x 2-3 surveys)", realm = "Freshwater",
  country = "AUS", coordinates = "None in source", notes = "IUCN VU frog.")
