#!/usr/bin/env Rscript
# Table:  zamuda_2022_yalemyers_mesopred_dynocc
# Source: Dryad, doi:10.5061/dryad.7d7wm37xs, version 180973 (published 2022-06-01), licence CC0 1.0 as shown on
#         the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Zamuda, K., Duguid, M. C. & Schmitz, O. J. (2022). Human land-use effects on mammalian mesopredator
#         occupancy of a northeastern Connecticut landscape. Ecology and Evolution 12, e9015.
#         https://doi.org/10.1002/ece3.9015 (open access, PMC9251285). Section 2.3: April 2018 to February 2019, four
#         seasons (spring April-May, summer June-August, fall September-November, winter December-February); within
#         each season cameras were moved to new sites three times (three 21-day sampling periods); two cameras per
#         site within 25 m (pooled); daily presence condensed into seven 3-day surveys. Sites in forest reserve,
#         shelterwood harvests and fields (24 / 24 / 12 in the paper).
# Data:   Mesopredator_Presence_Absence_data.xlsx: 16 sheets '<Species> <Season>' (Coyote, Bobcat, Fisher, Raccoon x
#           Spring, Summer, Fall, Winter), each 56 sites x 7 surveys, 0/1, no blank or NA cell (asserted); header
#           spellings vary ('survey 1', 'survey1', 'Survey 1').
#         Habitat_Variables.xlsx: 56 sites (same order): CC (canopy cover %) and FHD (foliage height diversity) per
#           season, CWD (coarse woody debris volume), snag density, distances to river, public road and skid road,
#           NED_1km (elevation), and percent forest / deciduous / evergreen / mixed / field / developed / wetland in
#           1 km. One NA (CC_Fall). README.csv. No coordinates; the site's land-use type is not deposited.
# Mapping: dynamic occupancy, four species. unit = Site, period = season in time order (1 spring 2018, 2 summer,
#   3 fall, 4 winter 2018-19), occasion = 3-day survey 1-7, y = 0/1. CC and FHD per season are period_; the other
#   habitat variables are unit_. surveyEvidence = deposited_matrix: the deposit gives a value for every site x
#   season x survey (the README: 'each survey has a presence (1) or an absence (0) for each site'), so every cell
#   is a survey; no cell is marked not surveyed.
#   The paper describes 60 sites (24 per 21-day period); the deposit has 56, each with seven surveys in every
#   season: shipped as deposited, the discrepancy in notes.
#   IUCN: all four LC; no coordinates, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "zamuda_2022_yalemyers_mesopred_dynocc"

dir <- download_dryad("10.5061/dryad.7d7wm37xs", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("Mesopredator_Presence_Absence_data.xlsx", "Habitat_Variables.xlsx", "README.csv")))
pa <- file.path(dir, "Mesopredator_Presence_Absence_data.xlsx")
spp <- c(Coyote = "CANLAT", Bobcat = "LYNRUF", Fisher = "PEKPEN", Raccoon = "PROLOT")
sea <- c("Spring", "Summer", "Fall", "Winter")
stopifnot(identical(excel_sheets(pa), as.vector(outer(sea, names(spp), function(s, k) paste(k, s)))))
hv <- as.data.table(read_excel(file.path(dir, "Habitat_Variables.xlsx")))
stopifnot(nrow(hv) == 56L, !anyDuplicated(hv$Site), ncol(hv) == 22L, sum(is.na(hv)) == 1L, is.na(hv[Site == hv$Site[is.na(hv$CC_Fall)]]$CC_Fall))
sites <- as.character(hv$Site)

parts <- list()
for (k in names(spp)) for (j in seq_along(sea)) {
  d <- as.data.table(read_excel(pa, paste(k, sea[j])))
  stopifnot(ncol(d) == 8L, identical(as.character(d$Site), sites), identical(tolower(gsub(" ", "", names(d)[-1])), paste0("survey", 1:7)))
  m <- as.matrix(d[, -1]); stopifnot(!anyNA(m), all(m %in% c(0, 1)))
  parts[[length(parts) + 1]] <- data.table(unit = rep(sites, 7), taxon = spp[[k]], y = as.integer(m), period = j,
                                           occasion = rep(1:7, each = 56))
}
long <- rbindlist(parts)
dets <- long[, sum(y), by = taxon][order(taxon)]
stopifnot(nrow(long) == 56L * 4L * 7L * 4L,
          identical(dets$V1[match(c("CANLAT", "LYNRUF", "PEKPEN", "PROLOT"), dets$taxon)], c(313L, 147L, 110L, 276L)))

pc <- rbindlist(lapply(seq_along(sea), function(j) data.table(unit = sites, period = j,
  period_canopy_cover_pct = hv[[c("CC_Spring", "CC_Summer", "CC_Fall", "CC winter")[j]]],
  period_foliage_height_div = hv[[c("FHD_Spring", "FHD Summer", "FHD_Fall", "FHD_Winter")[j]]])))
uc <- hv[, .(unit = as.character(Site), unit_cwd_volume = CWD, unit_snag_density = `Snag Density`, unit_dist_river_m = Dist_River,
             unit_dist_public_road_m = Dist_PublicROad, unit_dist_skid_road_m = `Dist_Skid Road`, unit_elev_1km_m = NED_1km,
             unit_pct_forest_1km = percentFor_1km, unit_pct_deciduous_1km = percentDec_1km, unit_pct_evergreen_1km = percent_Ever_1km,
             unit_pct_mixed_forest_1km = percent_mixfor_1km, unit_pct_field_1km = percent_field_1km,
             unit_pct_developed_1km = percent_dev_1km, unit_pct_wetland_1km = percent_Wet_1km)]
long <- merge(merge(long, pc, by = c("unit", "period")), uc, by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 6272L, uniqueN(long$unit) == 56L)
cat(sprintf("  %d rows; detections: %s\n", nrow(long), paste(dets$taxon, dets$V1, collapse = ", ")))

taxa <- make_taxa(unname(spp), c("Canis latrans", "Lynx rufus", "Pekania pennanti", "Procyon lotor"),
                  vernacularName = c("Coyote", "Bobcat", "Fisher", "Raccoon"))
periods <- data.table(period = 1:4, season = tolower(sea), months = c("2018-04/2018-05", "2018-06/2018-08", "2018-09/2018-11", "2018-12/2019-02"))

dataset <- list(
  title = "Camera detections of coyote, bobcat, fisher and raccoon at 56 sites in four seasons, Yale Myers Forest and surrounding land, Connecticut, April 2018 to February 2019",
  creator = "Zamuda, Kimberly; Duguid, Marlyse C.; Schmitz, Oswald", pubDate = "2022",
  doi = "10.5061/dryad.7d7wm37xs", sourceURL = "https://doi.org/10.5061/dryad.7d7wm37xs",
  citation = "Zamuda, K., Duguid, M. C., & Schmitz, O. (2022). Human land-use effects on mammalian mesopredator occupancy of a northeastern Connecticut landscape [Dataset]. Dryad. https://doi.org/10.5061/dryad.7d7wm37xs",
  paperDOI = "10.1002/ece3.9015",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Paired camera traps at sites in forest reserve, shelterwood harvests and fields in and around the 3200-ha Yale Myers Forest, northeastern Connecticut, sampled in each of four seasons from April 2018 to February 2019 to model mesopredator occupancy by land use. Each site-season is a 21-day deployment condensed into seven 3-day surveys; detection of coyote, bobcat, fisher and raccoon per survey, with seasonal canopy cover and foliage height diversity and fixed local and 1-km landscape covariates.",
  samplingProtocol = "Two Bushnell Trophy Cam HD cameras per site within 25 m of each other, 0.4-0.6 m above ground, run for a 21-day period in each season; daily presence condensed into seven 3-day surveys (a survey is 1 if the species was photographed on any of its days at either camera).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the seven 3-day surveys of a 21-day deployment within one season are the occasions; seasons (spring, summer, fall, winter) are periods. The authors fit single-season models per season.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Yale Myers Forest and adjacent public and private land, Eastford, northeastern Connecticut, USA (no coordinates deposited)",
  temporalCoverage = "2018-04/2019-02",
  covariateNote = "period_canopy_cover_pct and period_foliage_height_div (Shannon index of vegetation in four height classes) are measured per season. unit_cwd_volume (coarse woody debris), unit_snag_density (snags in a 50 m radius plot), unit_dist_river_m / _public_road_m / _skid_road_m, unit_elev_1km_m (National Elevation Data, 1 km buffer), unit_pct_<cover>_1km (proportion of the 1 km buffer in forest, deciduous, evergreen, mixed forest, field, developed, wetland; as deposited, 0-1).",
  notShipped = list(
    other_species = "red fox, gray fox, striped skunk and otter were photographed but excluded by the authors for low capture numbers and are not in the deposit",
    land_use_type = "the site's land-use type (reserve, shelterwood, field) is not in the deposit",
    weather = "daily precipitation and temperature used by the authors are not deposited",
    model_output = "occupancy and detection estimates"),
  notes = "The paper describes 60 sites (24 reserve, 24 shelterwood, 12 field; 24 per 21-day period); the deposit holds 56 sites with seven surveys in each of the four seasons, shipped as deposited. No cell of the deposited matrices is marked not surveyed. Deployment dates per site are not deposited.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/zamuda_2022_yalemyers_mesopred_dynocc.R")
stage_dict_row(TABLE,
  description = "Camera-trap detections of coyote, bobcat, fisher and raccoon at 56 sites over four seasons (seven 3-day surveys each) in and around Yale Myers Forest, Connecticut, April 2018 to February 2019, with habitat covariates.",
  url = "https://doi.org/10.5061/dryad.7d7wm37xs",
  reference = "Zamuda, K., Duguid, M. C. & Schmitz, O. J. (2022). Human land-use effects on mammalian mesopredator occupancy of a northeastern Connecticut landscape. Ecology and Evolution 12, e9015. https://doi.org/10.1002/ece3.9015",
  doi_paper = "10.1002/ece3.9015", doi_data = "10.5061/dryad.7d7wm37xs",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "16 species x season sheets joined into one multi-season table; land-use type not deposited.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "camera_trap", design = "Multi-season (4 seasons; 56 sites, seven 3-day surveys each)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Four mesopredators across forest reserve, shelterwood and field; no coordinates.")
