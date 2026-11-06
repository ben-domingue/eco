#!/usr/bin/env Rscript
# Tables: feldman_2023_quebec_wetland_comm (all 56 taxa, latitude coarsened) and
#         feldman_2023_quebec_wetland_exact_comm (the 55 unflagged taxa, latitude as deposited; E7 ruling 3)
# Source: Dryad, doi:10.5061/dryad.jsxksn0g4, version 287938 (published 2023-10-10), licence CC0 1.0 (as shown on the
#         Dryad record; asserted from the API; README: "Licenses/restrictions placed on the data: None"). Feldman,
#         M. J., Mazerolle, M. J., Imbeau, L. & Fenton, N. J. Data from: Using camera traps to estimate habitat
#         preferences and occupancy patterns of vertebrates in boreal wetlands.
# Paper:  Feldman, M. J., Mazerolle, M. J., Imbeau, L. & Fenton, N. J. (2024). Using camera traps to estimate habitat
#         preferences and occupancy patterns of vertebrates in boreal wetlands. Wetlands. doi:10.1007/s13157-024-01773-z
#         (not read). Design from the Dryad methods: 50 ponds (beaver and peatland ponds) in northern Quebec, three
#         lured cameras per pond, two sessions of seven consecutive days in each of 2018 and 2019; the three cameras'
#         records of a species at a pond on a day combined into one daily detection; multispecies occupancy model
#         (JAGS) with pond-year as the site and 14 daily visits.
# Data:   Cam_multisp_v4.Rdata: one object cam.array3, numeric array 100 pond-years ("CASA_ECA_1 2018", ...) x 14
#           visits (vis1..vis14) x 56 species (French common names); 0/1, NA = not surveyed (read with load() into an
#           environment; data only).
#         cam_ocsite_v3.csv (';'): id_site (pond-year), anne (0 = 2018, 1 = 2019), type_hab (castor = beaver pond,
#           tourb = peatland pond), chemin_dist (m to the nearest road), latitud (decimal degrees, 0.01 deg),
#           foret (% forest cover within 1 km; NA for 3 ponds).
#         det_precip_acum.csv, det_degel.csv, det_cam_active.csv (';'): pond-year x vis1..vis14 cumulative rainfall,
#           days since snowmelt, number of active cameras (1-3). The README says vis1-7 are 2018 and vis8-14 2019,
#           but the rows are pond-years and days since snowmelt runs 7 consecutive days, then jumps about 50 days,
#           within each row: vis1-7 and vis8-14 are the two 7-day sessions of the row's year (asserted).
#         Code_Multispecies_model.docx: the JAGS model (read as text).
# Mapping (community occupancy; responseType detection, unitKind site): unit = pond (id_site without the year),
#   taxon = a code from the scientific name, period = year (1 = 2018, 2 = 2019), occasion = visit 1..14 (day within
#   the two sessions), y = the deposited 0/1. surveyEvidence = deposited_matrix: the NA pattern is identical across
#   species and matches the three detection-covariate files (one pond-year session, CASA_TO_8 2019 vis8-14, is NA);
#   active cameras > 0 at every surveyed cell (asserted). obs_session (1, 2), obs_rain_cumulative,
#   obs_days_since_snowmelt, obs_cameras_active; unit_pond_type, unit_dist_road_m, unit_forest_cover_pct (constant
#   across years, asserted), unit_decimalLatitude.
#   Coordinates (E7): the Rusty Blackbird (Euphagus carolinus) is IUCN VU and breeds in boreal Quebec (native range),
#   so it is flagged (E7 b); the deposit gives latitude only (0.01 deg). Two tables (E7 ruling 3): all taxa with the
#   latitude snapped to the centre of its 0.1 deg band; and the 55 other taxa with the latitude as deposited.
# Not shipped: model estimates; dates (not deposited; May-August 2018 and 2019).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "feldman_2023_quebec_wetland_comm"
EXACT <- "feldman_2023_quebec_wetland_exact_comm"
dir <- download_dryad("10.5061/dryad.jsxksn0g4", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Cam_multisp_v4.Rdata", "cam_ocsite_v3.csv", "Code_Multispecies_model.docx",
  "det_cam_active.csv", "det_degel.csv", "det_precip_acum.csv", "README.md")))
e <- new.env()
stopifnot(identical(load(file.path(dir, "Cam_multisp_v4.Rdata"), envir = e), "cam.array3"))
X <- e$cam.array3
stopifnot(is.array(X), identical(dim(X), c(100L, 14L, 56L)), all(X %in% c(0, 1, NA)), sum(X, na.rm = TRUE) == 955)
py <- dimnames(X)[[1]]
NA1 <- is.na(X[, , 1])
stopifnot(all(apply(is.na(X), 3, function(m) identical(m, NA1))), sum(NA1) == 7L,
          all(NA1[py == "CASA_TO_8 2019", 8:14]), all(apply(X, 3, sum, na.rm = TRUE) >= 1))

s <- fread(file.path(dir, "cam_ocsite_v3.csv"), sep = ";")
stopifnot(identical(names(s), c("id_site", "anne", "type_hab", "chemin_dist", "latitud", "foret")), identical(s$id_site, py),
          setequal(s$type_hab, c("castor", "tourb")), all(s$anne == as.integer(sub("^.* ", "", py)) - 2018L),
          sum(is.na(s$foret)) == 6L, !anyNA(s[, .(chemin_dist, latitud)]))
s[, pond := sub(" 20(18|19)$", "", id_site)]
stopifnot(uniqueN(s$pond) == 50L, all(s[, .N, by = pond]$N == 2L),
          all(s[, uniqueN(paste(type_hab, chemin_dist, latitud, foret)), by = pond]$V1 == 1L))
oc <- function(f) { d <- fread(file.path(dir, f), sep = ";"); stopifnot(identical(d$ident, py), identical(names(d)[-1], paste0("vis", 1:14)))
  m <- unname(as.matrix(d[, -1])); stopifnot(identical(is.na(m), unname(NA1))); m }
RAIN <- oc("det_precip_acum.csv"); MELT <- oc("det_degel.csv"); CAM <- oc("det_cam_active.csv")
stopifnot(all(CAM[!NA1] %in% 1:3), all(MELT[, 2:7] - MELT[, 1:6] == 1), all(MELT[!NA1[, 14], 9:14] - MELT[!NA1[, 14], 8:13] == 1),
          all(MELT[!NA1[, 8], 8] - MELT[!NA1[, 8], 7] > 20))

sp <- c("Bec-croisse bifascie"="Loxia leucoptera","Becasseau minuscule"="Calidris minutilla","Becassine de Wilson"="Gallinago delicata",
"Bernache du Canada"="Branta canadensis","Bruant a couronne blanche"="Zonotrichia leucophrys","Bruant a gorge blanche"="Zonotrichia albicollis",
"Bruant des marais"="Melospiza georgiana","Bruant des pres"="Passerculus sandwichensis","Bruant fauve"="Passerella iliaca",
"Buse a queue rose"="Buteo jamaicensis","Butor d´Amerique"="Botaurus lentiginosus","Canard branchu"="Aix sponsa","Canard colvert"="Anas platyrhynchos",
"Canard d'Amerique"="Mareca americana","Canard noir"="Anas rubripes","Carouge a epaulettes"="Agelaius phoeniceus","Castor"="Castor canadensis",
"Chevalier grivele"="Actitis macularius","Chevalier solitaire"="Tringa solitaria","Grand corbeau"="Corvus corax","Corneille d´Amerique"="Corvus brachyrhynchos",
"Faucon emerillon"="Falco columbarius","Fuligule a collier"="Aythya collaris","Garrot a oeil d'or"="Bucephala clangula","Grand chevalier"="Tringa melanoleuca",
"Grand harle"="Mergus merganser","Grive a dos olive"="Catharus ustulatus","Grive a joues grises"="Catharus minimus","Grive solitaire"="Catharus guttatus",
"Grue du Canada"="Antigone canadensis","Harle couronne"="Lophodytes cucullatus","Junco ardoise"="Junco hyemalis","Lievre d´Amerique"="Lepus americanus",
"Loup gris"="Canis lupus","Loutre de riviere"="Lontra canadensis","Lynx du Canada"="Lynx canadensis","Macreause a font blanc"="Melanitta perspicillata",
"Martin pecheur d´Amerique"="Megaceryle alcyon","Martre d´Amerique"="Martes americana","Merle d'Amerique"="Turdus migratorius",
"Mesangeai du Canada"="Perisoreus canadensis","Mouette de bonaparte"="Chroicocephalus philadelphia","Orignal"="Alces alces","Ours noir"="Ursus americanus",
"Paruline a couronne rousse"="Setophaga palmarum","Paruline a croupion jaune"="Setophaga coronata","Paruline des ruisseaux"="Parkesia noveboracensis",
"Paruline masquee"="Geothlypis trichas","Pipit d´amerique"="Anthus rubescens","Quiscale bronze"="Quiscalus quiscula","Quiscale rouilleux"="Euphagus carolinus",
"Rat mouske"="Ondatra zibethicus","Renard roux"="Vulpes vulpes","Sarcelle d´hiver"="Anas crecca","Tetra du Canada"="Canachites canadensis","Vison d´Amerique"="Neogale vison")
stopifnot(setequal(names(sp), dimnames(X)[[3]]), !anyDuplicated(sp))
sci <- unname(sp[dimnames(X)[[3]]])
code <- toupper(paste0(substr(sub(" .*", "", sci), 1, 4), substr(sub("^\\S+ ", "", sci), 1, 4)))
stopifnot(!anyDuplicated(code))
MAMMALS <- c("Castor canadensis", "Lepus americanus", "Canis lupus", "Lontra canadensis", "Lynx canadensis", "Martes americana",
             "Alces alces", "Ursus americanus", "Ondatra zibethicus", "Vulpes vulpes", "Neogale vison")
stopifnot(all(MAMMALS %in% sci), length(sci) - length(MAMMALS) == 45L)

long <- rbindlist(lapply(seq_along(sci), function(k) rbindlist(lapply(1:14, function(j) { r <- !NA1[, j]
  data.table(row = which(r), taxon = code[k], y = as.integer(X[r, j, k]), occasion = j,
             obs_session = if (j <= 7) 1L else 2L, obs_rain_cumulative = RAIN[r, j], obs_days_since_snowmelt = MELT[r, j],
             obs_cameras_active = CAM[r, j]) }))))
long[, `:=`(unit = s$pond[row], period = s$anne[row] + 1L)]
uc <- unique(s[, .(unit = pond, unit_pond_type = c(castor = "beaver", tourb = "peatland")[type_hab], unit_dist_road_m = chemin_dist,
                   unit_forest_cover_pct = foret, lat = latitud)])
stopifnot(nrow(uc) == 50L)
long <- merge(long[, !"row"], uc, by = "unit")
stopifnot(nrow(long) == 56L * (100L * 14L - 7L), sum(long$y) == 955L)

tx <- make_taxa(code, sci, vernacularName = names(sp[dimnames(X)[[3]]]), lookupName = ifelse(sci == "Neogale vison", "Neovison vison", sci))
tx[, taxonRemarks := NA_character_]
tx[scientificName == "Neogale vison", taxonRemarks := "GBIF backbone holds the American mink as Neovison vison"]
tx[scientificName == "Euphagus carolinus", taxonRemarks := "IUCN VU (native breeding range): flagged, latitude coarsened (E7 b)"]
tx[, taxon_class := ifelse(scientificName %in% MAMMALS, "Mammalia", "Aves")]
setnames(tx, "vernacularName", "vernacularName")
tx[, vernacularName := paste0(vernacularName, " (French, as deposited)")]
FLAG <- tx[scientificName == "Euphagus carolinus", taxon]
stopifnot(identical(iucn_category(tx[taxon == FLAG, taxonID], "Euphagus carolinus"), "VU"))

full <- copy(long)[, unit_decimalLatitude := floor(lat / 0.1) * 0.1 + 0.05][, lat := NULL]
full[, unit_decimalLatitude := round(unit_decimalLatitude, 2)]
full <- order_eco(full)
ex <- copy(long[taxon != FLAG])[, unit_decimalLatitude := lat][, lat := NULL]
ex <- order_eco(ex)
periods <- data.table(period = 1:2, year = 2018:2019)

base <- list(
  creator = "Feldman, Mariano J.; Mazerolle, Marc J.; Imbeau, Louis; Fenton, Nicole J.", pubDate = "2023-10-10",
  doi = "10.5061/dryad.jsxksn0g4", paperDOI = "10.1007/s13157-024-01773-z", sourceURL = "https://doi.org/10.5061/dryad.jsxksn0g4",
  citation = "Feldman, M. J., Mazerolle, M. J., Imbeau, L., & Fenton, N. J. (2023). Data from: Using camera traps to estimate habitat preferences and occupancy patterns of vertebrates in boreal wetlands [Dataset]. Dryad. https://doi.org/10.5061/dryad.jsxksn0g4",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Lured camera arrays (three cameras per pond) at 50 beaver and peatland ponds in northern Quebec, two 7-day sessions in each of 2018 and 2019; daily detection of 56 taxa (11 mammals, the rest birds), with rainfall, days since snowmelt, active cameras, pond type, distance to road, forest cover and latitude. The authors fitted a multispecies occupancy model.",
  samplingProtocol = "Three infrared cameras per pond in a triangle at the pond edge with a scent lure, run 24 h for two sessions of seven consecutive days each summer; records of a species from any of the three cameras on a day are one daily detection.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors treat each pond-year as a closed site over its 14 daily visits, although its two 7-day sessions are about seven weeks apart (obs_session; days since snowmelt jumps about 50 days between them); open between years",
  occasionKind = "time", taxonInclusion = "recorded", temporalCoverage = "2018-05/2019-08",
  covariateNote = "obs_session: 7-day session 1 or 2 within the year. obs_rain_cumulative: cumulative rainfall on the day (units not given). obs_days_since_snowmelt. obs_cameras_active: cameras of the three that were working that day. unit_pond_type: beaver or peatland pond. unit_dist_road_m: distance to the nearest road. unit_forest_cover_pct: forest cover within 1 km (NA for 3 ponds). unit_decimalLatitude: latitude only (no longitude deposited).",
  notes = "Pond-year CASA_TO_8 2019 has no second session (no rows). Taxa are those recorded (11 mammals, 45 birds); vernacular names are the deposit's French names.")
ds_full <- c(list(title = "Daily lured-camera detections of 56 mammal and bird species at 50 boreal ponds, northern Quebec, 2018-2019 (latitude coarsened)"),
  base, list(geographicCoverage = "Northern Quebec, Canada, about 49.1-52.8 N (beaver and peatland ponds); latitude coarsened to 0.1 deg, no longitude deposited",
  coordinatesCoarsened = list(value = TRUE, method = "The Rusty Blackbird is IUCN VU in its native range (E7 b); the deposited latitude (0.01 deg; no longitude) is snapped to the centre of its 0.1 deg band. feldman_2023_quebec_wetland_exact_comm keeps the deposited latitude for the other 55 taxa."),
  notShipped = list(exact_latitude = "latitude at the deposited 0.01 deg (coarsened, E7; exact in feldman_2023_quebec_wetland_exact_comm without the flagged taxon)",
                    model_output = "occupancy and detection estimates", dates = "not deposited")))
ds_ex <- c(list(title = "Daily lured-camera detections of 55 mammal and bird species at 50 boreal ponds, northern Quebec, 2018-2019 (exact latitude)"),
  base, list(geographicCoverage = "Northern Quebec, Canada, about 49.1-52.8 N (beaver and peatland ponds); latitude as deposited, no longitude",
  coordinatesCoarsened = list(value = FALSE, method = "No taxon in this table is flagged; latitude as deposited. The Rusty Blackbird (IUCN VU) is only in feldman_2023_quebec_wetland_comm, with coarsened latitude."),
  notShipped = list(flagged_taxon = "Euphagus carolinus (Rusty Blackbird, IUCN VU; in feldman_2023_quebec_wetland_comm, E7 ruling 3)",
                    model_output = "occupancy and detection estimates", dates = "not deposited")))

ds <- write_table(full, TABLE, ds_full, taxa = tx, periods = periods, script = "data/feldman_2023_quebec_wetland_comm.R")
ds2 <- write_table(ex, EXACT, ds_ex, taxa = tx[taxon != FLAG], periods = periods, script = "data/feldman_2023_quebec_wetland_comm.R")
ref <- "Feldman, M. J., Mazerolle, M. J., Imbeau, L., & Fenton, N. J. (2024). Using camera traps to estimate habitat preferences and occupancy patterns of vertebrates in boreal wetlands. Wetlands."
for (t in list(list(TABLE, ds, "Daily lured-camera detections of 56 taxa (11 mammals, the rest birds) at 50 beaver and peatland ponds in northern Quebec, two 7-day sessions in 2018 and 2019; latitude coarsened.", "Rusty Blackbird IUCN VU: latitude coarsened to 0.1 deg; _exact sibling without it.", "Coarsened (0.1 deg)"),
               list(EXACT, ds2, "Daily lured-camera detections of 55 taxa (11 mammals, the rest birds) at 50 beaver and peatland ponds in northern Quebec, two 7-day sessions in 2018 and 2019; exact latitude (sibling of feldman_2023_quebec_wetland_comm without the Rusty Blackbird).", "_exact sibling (E7 ruling 3): the unflagged taxa at the deposited latitude.", "As published"))) {
  stage_dict_row(t[[1]], description = t[[3]], url = "https://doi.org/10.5061/dryad.jsxksn0g4", reference = ref,
    doi_paper = "10.1007/s13157-024-01773-z", doi_data = "10.5061/dryad.jsxksn0g4", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste(t[[4]], "Array read from .Rdata with load(); paper not read."), source_via = "Dryad")
  stage_tag_row(t[[1]], t[[2]], taxon_group = "Multiple", model_family = "Community occupancy", sampling_protocol = "camera_trap",
    design = "Multi-season (2 years x 2 sessions of 7 daily occasions; 50 ponds)", realm = "Freshwater", country = "CAN",
    coordinates = t[[5]], notes = "Boreal wetland vertebrate community, lured cameras.")
}
