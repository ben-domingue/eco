#!/usr/bin/env Rscript
# Table:  ruppel_2025_richmond_pollinator_comm
# Source: Dryad doi:10.5061/dryad.nzs7h450q (CC0 1.0, as shown on the Dryad page; published
#         2025-10-17). Ruppel, N., Nipko, R.B., Dingus, M., Ortiz, A.C., Weir, T., Kelly, M.J. &
#         Coster, S.S. (2025). Influence of environmental covariates on pollinator community
#         occupancy, detection, and richness across urban gardens in Richmond, Virginia (U.S.A.).
# Paper:  Ruppel, N.J. et al. (2025). Influence of Environmental Covariates on Pollinator Community
#         Occupancy, Detection, and Richness Across Urban Gardens in Richmond, Virginia, USA.
#         Ecology and Evolution 15(11), e72502, doi:10.1002/ece3.72502. Multi-species occupancy
#         model (JAGS) with the inflorescence watches of both plant species as replicates.
# Data:   README.md (codebook) and Ruppel_et_al_2024_archive.zip holding: L.spicataDetection.xlsx
#         and P.muticumDetection.xlsx, 14 sheets each (one per taxon detected at least once), 50
#         rows (Site, 50 arbitrary ids 1-52 without 28 and 48) x Flower1-Flower5 (five inflorescences on different plants, each watched
#         5 minutes), 0/1, blank = that plant type not surveyed at the garden (identical blank
#         pattern on every sheet, asserted: L. spicata at 30 gardens, P. muticum at 40, both at
#         20). SiteCovariates.xlsx: Longitude/Latitude (WGS84, to 1e-10 degree), UrbanDistance
#         (m to the Virginia State Capitol), GardenArea (m2). <plant>SurveyCovariates.xlsx: sheet
#         ByPlantType (JulianDay of 2021, Temperature C, BloomRichness, one value per garden x
#         plant visit), Illuminence (lux per inflorescence), StartTime (HH:MM per inflorescence).
#         data_processing.R / JAGS_code.R / parallelization.R are analysis code.
# Mapping: unit = garden (Site); taxon = the 14 deposited codes; occasion = 1-5 the P. muticum
#         inflorescences, 6-10 the L. spicata inflorescences (the authors' stacking order,
#         abind(pm, ls)); occasionKind = [method, spatial], recoverable from obs_plant and
#         obs_flower. y = 1 if the taxon visited the inflorescence during the 5-minute watch.
#         A row exists iff the plant type was surveyed at the garden (non-blank), for every taxon
#         (taxonInclusion = recorded: every visitor was identified, and the 14 sheets are the
#         taxa ever detected). date = 2021-01-01 + JulianDay - 1 (exact). obs_temp_c,
#         obs_bloom_richness (per garden x plant visit), obs_lux, obs_start_time (per flower).
#         unit_lat, unit_lon (as published; no taxon is flagged under E7: the genus- and
#         family-level groups and the named species are not CR/EN/VU), unit_urban_distance_m,
#         unit_garden_area_m2. surveyEvidence = deposited_matrix (blank vs 0).
# Not shipped: model output; nothing else.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "ruppel_2025_richmond_pollinator_comm"
dir <- download_dryad("10.5061/dryad.nzs7h450q", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
x <- file.path(dir, "x"); if (!dir.exists(x)) unzip(file.path(dir, "Ruppel_et_al_2024_archive.zip"), exdir = x)

codes <- c("Bombus.spp.", "XyVi", "Apis", "Halictidae", "CoOc", "AnOb", "Wasps", "ErHo", "MaLi", "HaHa",
           "PiRa", "AtCa", "Megachile.spp.", "EpBo")
plants <- c(pm = "Pycnanthemum muticum", ls = "Liatris spicata")
pf <- c(pm = "P.muticum", ls = "L.spicata")
rd <- function(f, s) as.data.table(read_excel(file.path(x, f), sheet = s))
sc <- rd("SiteCovariates.xlsx", "Sheet1"); SITES <- sc$Site; stopifnot(setequal(as.integer(SITES), setdiff(1:52, c(28, 48))))   # 50 arbitrary ids (1-52 without 28 and 48), same order in every file
stopifnot(length(SITES) == 50, !anyDuplicated(SITES), !anyNA(sc))

long <- rbindlist(lapply(names(plants), function(pl) {
  f <- paste0(pf[pl], "Detection.xlsx")
  stopifnot(identical(excel_sheets(file.path(x, f)), codes))
  sv <- rd(paste0(pf[pl], "SurveyCovariates.xlsx"), "ByPlantType")
  lux <- rd(paste0(pf[pl], "SurveyCovariates.xlsx"), "Illuminence")
  st <- rd(paste0(pf[pl], "SurveyCovariates.xlsx"), "StartTime")
  pat <- NULL
  out <- rbindlist(lapply(codes, function(cd) {
    d <- rd(f, cd); stopifnot(identical(d$Site, SITES), identical(names(d), c("Site", paste0("Flower", 1:5))))
    m <- as.matrix(d[, -1]); stopifnot(all(m %in% c(NA, 0, 1)))
    if (is.null(pat)) pat <<- is.na(m) else stopifnot(identical(is.na(m), pat))
    rbindlist(lapply(1:5, function(k) data.table(Site = d$Site, flower = k, y = as.integer(m[, k]))))
  }), idcol = "ti")
  stopifnot(all(rowSums(pat) %in% c(0, 5)))
  surveyed <- sv$Site[!is.na(sv$JulianDay)]
  stopifnot(identical(sort(as.integer(surveyed)), sort(as.integer(SITES[rowSums(pat) == 0]))),
            identical(lux$Site, SITES), identical(st$Site, SITES), identical(sv$Site, SITES))
  out[, taxon := codes[ti]][, ti := NULL]
  out <- out[!is.na(y)]
  lx <- melt(lux, id.vars = "Site", variable.name = "flower", value.name = "obs_lux")[, flower := as.integer(sub("Flower", "", flower))]
  tm <- melt(st, id.vars = "Site", variable.name = "flower", value.name = "obs_start_time")[, flower := as.integer(sub("Flower", "", flower))]
  out <- merge(out, lx, by = c("Site", "flower")); out <- merge(out, tm, by = c("Site", "flower"))
  out <- merge(out, sv, by = "Site")
  stopifnot(!anyNA(out$JulianDay), !anyNA(out$obs_lux), all(grepl("^[0-9]{1,2}:[0-9]{2}$", out$obs_start_time)))
  out[, `:=`(occasion = flower + if (pl == "pm") 0L else 5L, obs_plant = plants[[pl]], obs_flower = flower,
             date = as.character(as.IDate("2021-01-01") + JulianDay - 1L),
             obs_temp_c = Temperature, obs_bloom_richness = BloomRichness)]
  out[, c("JulianDay", "Temperature", "BloomRichness", "flower") := NULL]
  out
}))
long <- merge(long, sc[, .(Site, unit_lat = Latitude, unit_lon = Longitude, unit_urban_distance_m = UrbanDistance,
                           unit_garden_area_m2 = GardenArea)], by = "Site")
setnames(long, "Site", "unit"); long[, unit := as.integer(unit)]
long <- order_eco(long)
stopifnot(nrow(long) == (30 + 40) * 5 * 14, uniqueN(long$unit) == 50,
          sum(long$y) == 130 + 231, all(substr(long$date, 1, 7) %in% c("2021-06", "2021-07")))

taxa <- make_taxa(codes,
  c("Bombus", "Xylocopa virginica", "Apis mellifera", "Halictidae", "Coelioxys octodentatus", "Anthidium oblongatum",
    "Vespoidea", "Erynnis horatius", "Macrosiagon limbatum", "Halyomorpha halys", "Pieris rapae",
    "Atalopedes campestris", "Megachile", "Epilachna borealis"),
  vernacularName = c("bumble bees", "eastern carpenter bee", "western honey bee", "sweat bees", "a cuckoo leaf-cutter bee",
                     "oblong woolcarder bee", "wasps", "Horace's duskywing", "a wedge-shaped beetle", "brown marmorated stink bug",
                     "cabbage white", "sachem", "leafcutter bees", "squash lady beetle"),
  taxonRank = c("genus", "species", "species", "family", "species", "species", "superfamily", "species", "species",
                "species", "species", "species", "genus", "species"),
  allow_higher = c("Bombus.spp.", "Halictidae", "Megachile.spp."), no_key = "Wasps",
  taxonRemarks = c("Bombus spp. as deposited", NA, "source spelling 'Apis Mellifera'", "family as deposited", NA, NA,
                   "Vespoidea superfamily as deposited; superfamily not in the GBIF backbone, no taxonID", NA, NA, NA, NA, NA, "Megachile spp. as deposited", NA))

dataset <- list(
  title = "Pollinator visits to five watched inflorescences of two native plants in 50 urban gardens, Richmond, Virginia, summer 2021",
  creator = "Ruppel, Nicholas; Nipko, Robert B.; Dingus, Mackenzie; Ortiz, Allison C.; Weir, Teresa; Kelly, Marcella J.; Coster, Stephanie S.",
  pubDate = "2025", doi = "10.5061/dryad.nzs7h450q", sourceURL = "https://doi.org/10.5061/dryad.nzs7h450q",
  citation = "Ruppel, N., Nipko, R. B., Dingus, M., Ortiz, A. C., Weir, T., Kelly, M. J., & Coster, S. S. (2025). Influence of environmental covariates on pollinator community occupancy, detection, and richness across urban gardens in Richmond, Virginia (U.S.A.) [Dataset]. Dryad. https://doi.org/10.5061/dryad.nzs7h450q",
  paperDOI = "10.1002/ece3.72502",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Visual pollinator surveys at 50 Richmond-area gardens, 28 June to 27 July 2021: at each garden five inflorescences of Liatris spicata and/or Pycnanthemum muticum were each watched for 5 minutes and every visitor identified to the lowest possible level (14 taxa detected).",
  samplingProtocol = "Five-minute visual watches of five inflorescences on different plants of each study plant species present at a garden (one visit per plant species), all flower visitors identified.",
  samplingProtocolCode = "visual_survey", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one season; the two plant species were watched on different days at the 20 gardens with both, and the authors treat all ten watches as replicates of garden occupancy",
  occasionKind = c("method", "spatial"), taxonInclusion = "recorded",
  geographicCoverage = "greater Richmond, Virginia, USA (garden coordinates as published)",
  temporalCoverage = "2021-06/2021-07",
  coordinatesCoarsened = list(value = FALSE, method = "Garden coordinates shipped as published (WGS84); no taxon is flagged under E7 (CR/EN/VU)."),
  crs = "EPSG:4326",
  notShipped = list(model_output = "JAGS occupancy and richness estimates"),
  notes = "Taxa are those detected at least once (the deposit's 14 sheets); four are genus, family or superfamily groups. Wasps, ErHo, MaLi and HaHa were seen only on P. muticum, PiRa, AtCa, Megachile and EpBo only on L. spicata.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/ruppel_2025_richmond_pollinator_comm.R")
stage_dict_row(TABLE,
  description = "Detection of 14 pollinator taxa in 5-minute watches of five Liatris spicata and/or Pycnanthemum muticum inflorescences at 50 urban gardens in Richmond, Virginia, summer 2021, with light, start time, temperature, bloom richness and garden covariates.",
  url = "https://doi.org/10.5061/dryad.nzs7h450q",
  reference = "Ruppel, N. J., Nipko, R. B., Dingus, M., Ortiz, A. C., Weir, T., Kelly, M. J., & Coster, S. S. (2025). Influence of Environmental Covariates on Pollinator Community Occupancy, Detection, and Richness Across Urban Gardens in Richmond, Virginia, USA. Ecology and Evolution, 15(11), e72502.",
  doi_paper = "10.1002/ece3.72502", doi_data = "10.5061/dryad.nzs7h450q",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Occasions stack the two plant species (method) x five inflorescences (spatial), in the authors' order.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy (single season)",
  sampling_protocol = "visual_survey", design = "Single-season (2 plant species x 5 inflorescence watches)",
  realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Urban pollinators; plant species as a method on occasions.")
