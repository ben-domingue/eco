#!/usr/bin/env Rscript
# Table:  uherkoch_2021_npraloon_dynocc
# Source: USGS ScienceBase doi:10.5066/P9Z3AGXS (CC0 1.0 / US public domain)
#   Uher-Koch, B.D. (2021). Survey data for loon occupancy in freshwater lakes, National
#   Petroleum Reserve-Alaska, 2011-2014: U.S. Geological Survey data release.
# Paper:  Uher-Koch, B.D., Wright, K.G. & Uher-Koch, H.R. (2020). Effects of fish
#         populations on Pacific Loon and Yellow-billed Loon ... Arctic 73(4),
#         doi:10.14430/arctic71533 (Crossref match; the release names no paper).
# Data:   one CSV, 117 loon territories (mostly whole lakes) x: Territory_Lat/Long,
#         yearly territory status 2011-2014 coded 0 unoccupied / 1 Pacific Loon pair /
#         2 Pacific pair with chicks / 3 Yellow-billed pair / 4 Yellow-billed with chicks
#         / NA no survey; presence (0/1) of five fish species in the lake; TotalSpp.
#
# Mapping (standard sections 2.1 "multi-state" + 3.5): unit = territory, taxon = loon
#   species (GAVPAC, GAVADA), period = year 1..4 (periods side table has the calendar
#   year), one survey per year so no `occasion`. y is the per-species state:
#   0 = not holding the territory, 1 = territorial pair, 2 = territorial pair with
#   reproduction; y_raw keeps the source code 0-4. A territory held by one species is
#   a 0 for the other, so each surveyed territory-year has two rows. stateCodes in
#   dataset.json. Fish presence and TotalSpp are lake-level unit_*; coordinates are kept
#   as published (the source publishes them; neither species is flagged sensitive there).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "uherkoch_2021_npraloon_dynocc"
f <- download_cached("https://www.sciencebase.gov/catalog/file/get/61a59cb7d34eb622f6974db6?f=__disk__d9%2F06%2Fcf%2Fd906cfc3f32b01900d4d9f6f15c349bb831dfca1",
                     TABLE, filename = "loonFish_lakeOccupancy_NPRA_2011_2014_uherKoch.csv")
raw <- fread(f, encoding = "UTF-8")
setnames(raw, 1, "TerritoryID")      # strip the BOM if fread kept it in the name
stopifnot(nrow(raw) == 117, !anyDuplicated(raw$TerritoryID))
years <- as.character(2011:2014)
state <- as.matrix(raw[, ..years]); stopifnot(all(state %in% c(0:4, NA)))

# species-specific state: 0 absent, 1 territorial, 2 territorial with reproduction
y <- array(NA_integer_, dim = c(117, 4, 2), dimnames = list(raw$TerritoryID, NULL, c("GAVPAC", "GAVADA")))
y[, , "GAVPAC"] <- ifelse(is.na(state), NA_integer_, ifelse(state %in% 1:2, state, 0L))
y[, , "GAVADA"] <- ifelse(is.na(state), NA_integer_, ifelse(state %in% 3:4, state - 2L, 0L))
raw_code <- array(state, dim = dim(y))     # same source code on both species' rows
site_covs <- raw[, .(decimalLatitude = Territory_Lat, decimalLongitude = Territory_Long,
                     fish_least_cisco = LeastCiscoPres, fish_broad_whitefish = BWhitefishPres,
                     fish_arctic_grayling = AGraylingPres, fish_alaska_blackfish = AKBlackfishPres,
                     fish_ninespine_stickleback = NsSticklebackPres, fish_n_species = TotalSpp)]
long <- array_to_eco(y, site_ids = raw$TerritoryID, site_covs = site_covs, period = 1:4, y_raw = raw_code)
long[, occasion := NULL]
stopifnot(nrow(long) == 2 * sum(!is.na(state)))

taxa <- make_taxa(c("GAVPAC", "GAVADA"), c("Gavia pacifica", "Gavia adamsii"),
                    vernacularName = c("Pacific Loon", "Yellow-billed Loon"))
periods <- data.table(period = 1:4, year = 2011:2014)
dataset <- list(
  title = "Loon territory occupancy and breeding status in freshwater lakes, National Petroleum Reserve-Alaska, 2011-2014",
  creator = "Uher-Koch, Brian D.", pubDate = "2021", doi = "10.5066/P9Z3AGXS",
  sourceURL = "https://doi.org/10.5066/P9Z3AGXS",
  citation = "Uher-Koch, B.D., 2021, Survey data for loon occupancy in freshwater lakes, National Petroleum Reserve-Alaska, 2011-2014: U.S. Geological Survey data release, https://doi.org/10.5066/P9Z3AGXS.",
  paperDOI = "10.14430/arctic71533",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; public domain"),
  abstract = "Territory occupancy data for Pacific and Yellow-billed Loons and presence/absence of five fish species from freshwater lakes on the Arctic Coastal Plain, northern Alaska, 2011-2014, collected to understand how fish communities affect loon occupancy and breeding success.",
  samplingProtocol = "Annual lake surveys of loon territories; status recorded once per year.",
  samplingProtocolCode = "territory_survey", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "site",
  closure = "period (one survey per year; territory status may change between years)",
  stateCodes = list(`0` = "species does not hold the territory", `1` = "territorial pair", `2` = "territorial pair with reproduction (chicks >= 3 weeks)"),
  respRawCodes = list(`0` = "Unoccupied", `1` = "Pacific Loon pair", `2` = "Pacific Loon pair with reproduction", `3` = "Yellow-billed Loon pair", `4` = "Yellow-billed Loon pair with reproduction"),
  geographicCoverage = list(description = "National Petroleum Reserve-Alaska, Arctic Coastal Plain",
                            boundingBox = list(west = -155.53, east = -155.16, south = 70.36, north = 70.72)),
  temporalCoverage = "2011/2014",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by the source"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/uherkoch_2021_npraloon_dynocc.R")

stage_dict_row(TABLE,
  description = "Yearly territory status (absent / territorial pair / pair with chicks) of Pacific and Yellow-billed Loons at 117 lake territories in the National Petroleum Reserve-Alaska, 2011-2014, with lake coordinates and presence of five fish species as site covariates.",
  url = "https://doi.org/10.5066/P9Z3AGXS",
  reference = "Uher-Koch, B.D., Wright, K.G., & Uher-Koch, H.R. (2020). Effects of fish populations on Pacific Loon (Gavia pacifica) and Yellow-billed Loon (G. adamsii) lake occupancy and chick production in northern Alaska. Arctic, 73(4).",
  doi_paper = "10.14430/arctic71533", doi_data = "10.5066/P9Z3AGXS",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "USGS data release (public domain, CC0 stated in metadata). Multi-state response: y is the per-species state 0/1/2, y_raw the source code 0-4. Paper matched on Crossref; verify.",
  source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state dynamic occupancy",
  sampling_protocol = "territory_survey", design = "Multi-season (4 years, 1 survey each)", realm = "Freshwater",
  country = "USA", coordinates = "As published", notes = "Two species share a territory exclusively, so each surveyed territory-year has one non-zero row at most.")
