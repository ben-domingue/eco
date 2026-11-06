#!/usr/bin/env Rscript
# Table:  silva_2018_scotland_badger_occ
# Source: Dryad doi:10.5061/dryad.n7h91, version 14370 (published 2018-02-28), CC0 1.0 (asserted from the Dryad
#         metadata). Silva, A. P., Curveira-Santos, G., Kilshaw, K., Newman, C., Macdonald, D. W., Simões, L. G.
#         & Rosalino, L. M. Data from: Climate and anthropogenic factors determine site occupancy in Scotland's
#         Northern-range badger population. The file note: "Geographic locations can be provided at the
#         discretion of the authors" (no coordinates deposited). Raw files read from batch 35's cache (no Dryad
#         request in batch 47).
# Paper:  Silva, A. P., Curveira-Santos, G., Kilshaw, K., Newman, C., Macdonald, D. W., Simões, L. G. &
#         Rosalino, L. M. (2017). Climate and anthropogenic factors determine site occupancy in Scotland's
#         Northern-range badger population: implications of context-dependent responses under environmental
#         change. Diversity and Distributions 23, 627-637. doi:10.1111/ddi.12564 (PDF supplied by Ben, not
#         committed). s.2.2: October 2010 to March 2013, 168 camera-trap stations in 11 study areas (about
#         21 km2 each, 10-20 stations a grid, about 1 km apart) across northern Scotland; two cameras per
#         station facing each other, baited and lured; active 60-80 days per session (Table S1, not supplied),
#         checked every 10-14 days. s.2.4: "Capture histories at each site (camera-trap location) were pooled
#         into consecutive 7-day sampling events ... if at least a single badger photograph was obtained ... 1
#         (present); otherwise, a 0". Table 2 defines the covariates (500 m buffer around each station).
# Data:   badger_occupancy_scotland.csv: 168 rows (Camera_ID unique), Group (topo-climatic context: "Warmer and
#         Lower elevation", "Colder and higher elevation", "Undifined"), Stud_area (11 areas), p1-p22 (weekly
#         detection, NA = not surveyed; each station's surveyed weeks are one contiguous run of 4-10, starting at
#         a column shared within a study area: the columns are a common weekly calendar, not each station's own
#         weeks), the Table 2 covariates (Elev, WTemp, WTempA = the paper's WTempV, Rain, DSL, DGF, Agric, Mix,
#         Conif, Grass, Heath, Bog, Water, DistRi, Hdiv = HRich, DistMR, MRext, DistSR, SRext, DistSet, Humans,
#         ALLC) and SA (a 1-11 index of Stud_area, asserted one-to-one).
# Mapping (single-season occupancy, E9 core): unit = Camera_ID, taxon = MELMEL (Meles meles), occasion = the
#   week column (1-22, occasionKind time, closure closed within a station's session), y = the cell.
#   surveyEvidence = deposited_matrix (NA = not surveyed, no row). cluster_id = study area. unit_context =
#   Group as deposited. unit_ covariates: unit_elev_m, unit_wtemp_min_c, unit_wtemp_range_c, unit_rain_mm,
#   unit_snow_days, unit_frost_days, unit_agric_pct, unit_mixed_forest_pct, unit_conifer_pct, unit_grass_pct,
#   unit_heath_pct, unit_bog_pct, unit_water_pct, unit_dist_river_m, unit_habitat_richness,
#   unit_dist_main_road_m, unit_main_road_m, unit_dist_minor_road_m, unit_minor_road_m, unit_dist_settlement_m.
#   No coordinates (withheld by the authors). Badger IUCN LC.
# Not shipped: Humans (human captures per 100 trap nights) and ALLC (fox, wildcat and pine marten captures per
#   100 trap nights): indices computed from the same cameras' detections (ruled 2026-11-06, not covariates);
#   SA (a recode of Stud_area). The survey dates and session per study area (Table S1) are not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "silva_2018_scotland_badger_occ"
dir <- download_dryad("10.5061/dryad.n7h91", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "14370",
          identical(list.files(dir), "badger_occupancy_scotland.csv"))
d <- fread(file.path(dir, "badger_occupancy_scotland.csv"))
PC <- paste0("p", 1:22)
stopifnot(nrow(d) == 168L, !anyDuplicated(d$Camera_ID), uniqueN(d$Stud_area) == 11L, all(PC %in% names(d)),
          d[, uniqueN(SA), by = Stud_area][, all(V1 == 1L)], d[, uniqueN(Stud_area), by = SA][, all(V1 == 1L)],
          setequal(d$Group, c("Warmer and Lower elevation", "Colder and higher elevation", "Undifined")),
          d[, uniqueN(Group), by = Stud_area][, all(V1 == 1L)])
P <- as.matrix(d[, ..PC])
stopifnot(all(P %in% c(0L, 1L, NA)), sum(!is.na(P)) == 1230L, sum(P, na.rm = TRUE) == 183L,
          all(apply(!is.na(P), 1, function(z) { w <- which(z); length(w) >= 4L && all(diff(w) == 1L) })),
          d[, uniqueN(apply(!is.na(as.matrix(.SD)), 1, function(z) min(which(z)))), by = Stud_area, .SDcols = PC][, all(V1 == 1L)])
covs <- c(unit_elev_m = "Elev", unit_wtemp_min_c = "WTemp", unit_wtemp_range_c = "WTempA", unit_rain_mm = "Rain",
          unit_snow_days = "DSL", unit_frost_days = "DGF", unit_agric_pct = "Agric", unit_mixed_forest_pct = "Mix",
          unit_conifer_pct = "Conif", unit_grass_pct = "Grass", unit_heath_pct = "Heath", unit_bog_pct = "Bog",
          unit_water_pct = "Water", unit_dist_river_m = "DistRi", unit_habitat_richness = "Hdiv",
          unit_dist_main_road_m = "DistMR", unit_main_road_m = "MRext", unit_dist_minor_road_m = "DistSR",
          unit_minor_road_m = "SRext", unit_dist_settlement_m = "DistSet")
stopifnot(!anyNA(d[, unname(covs), with = FALSE]))
long <- melt(d[, c("Camera_ID", "Stud_area", "Group", unname(covs), PC), with = FALSE],
             measure.vars = PC, variable.name = "pcol", value.name = "y", na.rm = TRUE)
long[, occasion := as.integer(sub("^p", "", pcol))]
setnames(long, unname(covs), names(covs))
long <- long[, c(list(unit = Camera_ID, taxon = "MELMEL", y = as.integer(y), occasion = occasion, cluster_id = Stud_area,
                      unit_context = Group), .SD), .SDcols = names(covs)]
long <- order_eco(long)
stopifnot(nrow(long) == 1230L, sum(long$y) == 183L, uniqueN(long$unit) == 168L)
taxa <- make_taxa("MELMEL", "Meles meles", vernacularName = "European badger")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
dataset <- list(
  title = "Weekly camera-trap detections of European badgers at 168 baited stations in 11 study areas across northern Scotland, 2010-2013",
  creator = "Silva, André P.; Curveira-Santos, Gonçalo; Kilshaw, Kerry; Newman, Chris; Macdonald, David W.; Simões, Luciana G.; Rosalino, Luís M.",
  pubDate = "2018", doi = "10.5061/dryad.n7h91", sourceURL = "https://doi.org/10.5061/dryad.n7h91",
  citation = "Silva, A. P., Curveira-Santos, G., Kilshaw, K., Newman, C., Macdonald, D. W., Simões, L. G. & Rosalino, L. M. (2018). Data from: Climate and anthropogenic factors determine site occupancy in Scotland's Northern-range badger population: implications of context-dependent responses under environmental change [Dataset]. Dryad. https://doi.org/10.5061/dryad.n7h91",
  paperDOI = "10.1111/ddi.12564",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap survey of the European badger at the northern edge of its range: 168 baited stations of paired cameras in 11 study areas across northern Scotland, October 2010 to March 2013, each active 60-80 days, with detections pooled into 7-day occasions. Station covariates describe topography, winter climate, land cover and roads and settlements within 500 m. The authors fitted single-season occupancy models within two topo-climatic contexts.",
  samplingProtocol = "Grids of 10-20 camera-trap stations about 1 km apart in each study area; two opposing cameras per station, baited (bait on a stake) and lured, active 60-80 days and checked every 10-14 days; a station-week is a detection if at least one badger photograph was taken.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "closed within a station's 4-10 surveyed weeks (one session per station)", occasionKind = "time",
  taxonInclusion = "single",
  geographicCoverage = "Northern Scotland, UK: 11 study areas (Darnaway, Dundreggan, Dunrobin, Fetteresso, Hope, Inchnadamph, Inverewe, Inverlael, Seafield and Strathspey, Spinningdale, Trossachs); station coordinates not deposited (available from the authors)",
  temporalCoverage = "2010-10/2013-03",
  covariateNote = "cluster_id: study area. unit_context: the authors' topo-climatic context as deposited ('Undifined' as spelled). Within 500 m of the station (paper Table 2): unit_elev_m; winter (Nov-Apr 2007-2011) means unit_wtemp_min_c (daily minimum), unit_wtemp_range_c (daily range, WTempV), unit_rain_mm, unit_snow_days (excluded by the authors), unit_frost_days; land cover per cent unit_agric_pct, unit_mixed_forest_pct, unit_conifer_pct, unit_grass_pct, unit_heath_pct, unit_bog_pct, unit_water_pct; unit_dist_river_m; unit_habitat_richness (land-cover classes); unit_dist_main_road_m, unit_main_road_m (length within 500 m), unit_dist_minor_road_m, unit_minor_road_m, unit_dist_settlement_m.",
  notShipped = list(Humans = "human captures per 100 trap nights: an index from the same cameras (ruled 2026-11-06, not a covariate)",
                    ALLC = "red fox, wildcat and pine marten captures per 100 trap nights: an index from the same cameras",
                    SA = "a 1-11 index of the study area (cluster_id)",
                    dates = "session dates per study area (the paper's Table S1) are not deposited"),
  notes = "The 22 week columns are a calendar shared within each study area (every station of an area starts at the same column); which calendar weeks or years they are is not deposited. Badger detection rule from the paper (s.2.4).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/silva_2018_scotland_badger_occ.R")
stage_dict_row(TABLE,
  description = "Weekly camera-trap detection of European badgers at 168 baited stations in 11 study areas across northern Scotland, 2010-2013, with winter climate, land cover and road and settlement covariates.",
  url = "https://doi.org/10.5061/dryad.n7h91",
  reference = "Silva, A. P. et al. (2017). Climate and anthropogenic factors determine site occupancy in Scotland's Northern-range badger population: implications of context-dependent responses under environmental change. Diversity and Distributions 23, 627-637. https://doi.org/10.1111/ddi.12564",
  doi_paper = "10.1111/ddi.12564", doi_data = "10.5061/dryad.n7h91", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Occasion length (7 days) from the paper (PDF supplied by Ben); read from batch 35's cache.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (4-10 weekly occasions per station)", realm = "Terrestrial",
  country = "GBR", coordinates = "None in source", notes = "Northern range edge; baited paired cameras.")
