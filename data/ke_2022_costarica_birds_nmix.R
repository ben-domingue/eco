#!/usr/bin/env Rscript
# Tables: ke_2022_costarica_birds_nmix (coarsened) and ke_2022_costarica_birds_exact_nmix (E7.3
#         sibling without the IUCN CR / VU species, coordinates as deposited)
# Source: Dryad doi:10.25338/B8VP85, version 165741, CC0 1.0 (Dryad licence field; the README
#         states none).
#   Ke, A., Sollmann, R., Frishkoff, L. O. & Karp, D. S. (2022). Data from: A hierarchical
#   N-mixture model to estimate behavioral variation and a case study of Neotropical birds. Dryad.
# Paper:  Ke, A., Sollmann, R., Frishkoff, L. O. & Karp, D. S. (2022). A hierarchical N-mixture
#         model to estimate behavioral variation and a case study of Neotropical birds. Ecological
#         Applications 32(6), e2632, doi:10.1002/eap.2632.
# Data:   README.txt documents every file. visit-data.csv (1,122 rows): one row per point-count
#         visit: Site (25 four-letter landscape codes), Point (1-6), Date (m/d/yy), Year
#         (2016-2019), Rep (1-3), Time (start, H:MM), people in and near the count, temperature
#         and wind at start and end, Crop_type, Noise (Yes/No), and free-text Noise_Description,
#         Changes, Notes. community-data.csv (12,885 rows): one row per observation instance
#         (a bird or group of one species): Site, Point, Site_ID (Site_Point), Date, Rep, Year,
#         Species (4-letter code), Number1 / Behavior1 and optional Number2-3 / Behavior2-3 (the
#         individuals of the instance seen doing each behaviour), LU (bird in Forest or
#         Agriculture). site-attributes.csv (150 points, Site = SitePoint, e.g. NARA3):
#         Latitude / Longitude (decimal degrees, 8 places; the README calls them UTM easting and
#         northing, but the values are degrees), Elevation (m), AnnualPrecipitation (mm),
#         DistanceToRiver (m), LocalLU (Forest / Agriculture), LocalForestCover (50 m buffer).
#         landscapeforestcover-data.csv: forest cover at 105 buffer radii (60-1000 m by 10 m, 1050-1500 m by 50 m).
#         species-codes.csv: 886 codes (a master list) with ScientificName and Family.
#         behavior-codes.csv, species-vocal-info.csv, aggression-cases.csv: behaviour detail.
#         Design: 25 landscapes x 6 points; 2016: 120 points visited once and 60 of them three
#         times; 2017-2019: 150 points once and 72 of them three times.
#
# Mapping (N-mixture, multi-species, multi-season): unit = Site_ID (point), cluster_id = Site
#   (landscape code), taxon = the 4-letter code, period = Year - 2015 (1-4), occasion = Rep,
#   date = Date (ISO), y = individuals of the species counted at the visit = sum of Number1 over
#   its observation instances. Number1 is the instance's number of individuals; Number2 and
#   Number3 count the same individuals doing a second or third behaviour (Number2 == Number1 in
#   857 of 1,075 instances that have one), so they are not added. This is the authors' own count:
#   Frishkoff et al. (2018, doi:10.5061/dryad.7c652r8) deposited the same 2016 visits with one
#   Number per instance, and its species x visit sums equal the sums of Number1 here in every
#   cell but one. Flyovers (Behavior F) are counted, as in that deposit.
#   Survey evidence: sample_table. A survey is a row of visit-data.csv; 21 visits have no
#   detection and are all-zero surveys; every community-data visit is in visit-data (asserted).
#   Every species recorded anywhere is y = 0 at a visit where it was not counted
#   (taxonInclusion = recorded, community rule E4.2).
#   Covariates: obs_time_hhmm, obs_people_in_count, obs_people_nearby, obs_temp_start_c,
#   obs_temp_end_c, obs_wind_start_ms, obs_wind_end_ms, obs_noise (1/0), obs_crop_type (lower
#   case, as deposited); unit_landuse, unit_forest_cover_50m, unit_annual_precip_mm,
#   unit_dist_river_m, unit_elevation_m, coordinates; __units adds forest cover at every buffer
#   radius in landscapeforestcover-data.csv.
#   Coordinates (E7): Amazona auropalliata (CR), Crax rubra (VU) and Aratinga canicularis
#   (= Eupsittula canicularis, VU) are counted, all in their native range, so in the main table
#   every point is coarsened to its 0.1-degree cell centre with coarsen_coords() and elevation is
#   rounded to 100 m (E7.4). The _exact sibling drops those three species and keeps the deposited
#   coordinates and elevation. Landscape and point ids are the source's codes, kept in both.
#   Not shipped: the behaviour codes and Number2-3 (behaviour detail, the subject of the
#   paper's model; aggression-cases and species-vocal-info likewise), LU per instance, and the
#   free-text Noise_Description, Changes and Notes (they name people living near the points).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ke_2022_costarica_birds_nmix"
EXACT <- "ke_2022_costarica_birds_exact_nmix"
dir <- download_dryad("10.25338/B8VP85", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(all(c("visit-data.csv", "community-data.csv", "site-attributes.csv", "landscapeforestcover-data.csv",
                "species-codes.csv", "README.txt") %in% list.files(dir)))
v  <- fread(file.path(dir, "visit-data.csv"))
cm <- fread(file.path(dir, "community-data.csv"))
st <- fread(file.path(dir, "site-attributes.csv"))
fc <- fread(file.path(dir, "landscapeforestcover-data.csv"))
sp <- fread(file.path(dir, "species-codes.csv"))

# --- source facts ---------------------------------------------------------------------------
stopifnot(nrow(v) == 1122, nrow(cm) == 12885, nrow(st) == 150, nrow(fc) == 150)
v[, Site_ID := paste(Site, Point, sep = "_")]
v[, d := as.Date(Date, "%m/%d/%y")]
stopifnot(!anyNA(v$d), all(year(v$d) == v$Year), all(v$Year %in% 2016:2019), all(v$Rep %in% 1:3))
stopifnot(!anyDuplicated(v[, .(Site_ID, Year, Rep)]), uniqueN(v$Site) == 25, uniqueN(v$Site_ID) == 150)
nv <- v[, .N, by = .(Year, Rep)][order(Year, Rep)]
stopifnot(identical(nv$N, c(120L, 60L, 60L, rep(c(150L, 72L, 72L), 3))))
stopifnot(all(grepl("^[0-9]{1,2}:[0-9]{2}$", v$Time)), all(v$Noise %in% c("Yes", "No")))
stopifnot(all(cm$Site_ID == paste(cm$Site, cm$Point, sep = "_")), !anyNA(cm$Number1), all(cm$Number1 >= 1))
cm[, d := as.Date(Date, "%m/%d/%y")]
ck <- unique(cm[, .(Site_ID, Year, Rep, d)])
stopifnot(nrow(ck[!v, on = .(Site_ID, Year, Rep, d)]) == 0)                # every detection visit is a logged visit
stopifnot(nrow(v[!ck, on = .(Site_ID, Year, Rep)]) == 21)                   # 21 logged visits with no detection
stopifnot(cm[!is.na(Number2), .N] == 1075, cm[!is.na(Number2) & Number2 == Number1, .N] == 857,
          cm[!is.na(Number3), .N] == 86, cm[is.na(Number2) & !is.na(Number3), .N] == 0)
# points: site-attributes and forest cover keyed by SitePoint (no underscore)
st[, Site_ID := sub("^([A-Z]{4})([0-9])$", "\\1_\\2", Site)]
fc[, Site_ID := paste(Site, Point, sep = "_")]
stopifnot(setequal(st$Site_ID, v$Site_ID), setequal(fc$Site_ID, v$Site_ID), all(fc$UnID == st$Site[match(fc$Site_ID, st$Site_ID)]))
stopifnot(all(st$Latitude > 9.8 & st$Latitude < 10.6), all(st$Longitude > -85.7 & st$Longitude < -85.0),
          setequal(st$LocalLU, c("Forest", "Agriculture")), !anyNA(st))
rad <- setdiff(names(fc), c("Site", "Point", "UnID", "Site_ID"))
stopifnot(length(rad) == 105, identical(as.integer(rad), c(seq(60L, 1000L, by = 10L), seq(1050L, 1500L, by = 50L))), !anyNA(fc[, ..rad]))

# --- taxa ------------------------------------------------------------------------------------
sp[, C := toupper(Code)]
spx <- sp[!is.na(C) & nzchar(C)]
stopifnot(!anyDuplicated(spx$C))
species <- sort(unique(cm$Species)); stopifnot(length(species) == 167, all(species %in% spx$C))
sci <- spx$ScientificName[match(species, spx$C)]
stopifnot(all(grepl("^[A-Z][a-z]+ [a-z]+$", sci)), !anyDuplicated(sci))
look <- sci; look[sci == "Amazilia saucerrottei"] <- "Amazilia saucerottei"          # source spelling; GBIF strict match is FUZZY
stopifnot(sum(sci == "Amazilia saucerrottei") == 1)
taxa <- make_taxa(species, sci, lookupName = look, taxon_family = spx$Family[match(species, spx$C)])
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# NA where GBIF's IUCN record is the source's own binomial filed as a synonym of the backbone name:
# that record is the source's species, so its code is used
same_name <- function(id) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- strsplit(r$scientificName %||% "", " ")[[1]]
  paste(head(w, 2), collapse = " ")
}
taxa[is.na(taxon_iucnCategory) & mapply(same_name, taxonID) == scientificName,
     taxon_iucnCategory := sapply(taxonID, function(id) fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))$code)]
# two left: IUCN files them under the other gender ending (Aramides cajaneus, Porphyrio martinicus), both LC
gender <- c(GNWR = "Aramides cajaneus", PUGA = "Porphyrio martinicus")
stopifnot(identical(sort(taxa[is.na(taxon_iucnCategory), taxon]), sort(names(gender))),
          identical(unname(mapply(same_name, taxa[match(names(gender), taxon), taxonID])), unname(gender)))
taxa[taxon %in% names(gender), taxon_iucnCategory := sapply(taxonID, function(id) fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))$code)]
stopifnot(!anyNA(taxa$taxon_iucnCategory))
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
stopifnot(setequal(flagged$taxon, c("YNPA", "GRCU", "OFPA")))              # Amazona auropalliata CR; Crax rubra, Aratinga canicularis VU
cat(sprintf("  IUCN flagged: %s\n", paste(sprintf("%s %s (%s)", flagged$taxon, flagged$scientificName, flagged$taxon_iucnCategory), collapse = "; ")))

# --- counts and the zero fill ----------------------------------------------------------------
counts <- cm[, .(y = sum(Number1)), by = .(Site_ID, Year, Rep, taxon = Species)]
surveys <- v[, .(unit = Site_ID, cluster_id = Site, period = Year - 2015L, occasion = Rep, date = format(d),
                 obs_time_hhmm = Time, obs_people_in_count = X._ppl_in_count, obs_people_nearby = X._ppl_nearby,
                 obs_temp_start_c = Temp_start, obs_temp_end_c = Temp_end,
                 obs_wind_start_ms = Wind_quant_start, obs_wind_end_ms = Wind_quant_end,
                 obs_noise = as.integer(Noise == "Yes"),
                 obs_crop_type = fifelse(nzchar(Crop_type), tolower(Crop_type), NA_character_),
                 Site_ID, Year, Rep)]
long <- surveys[rep(seq_len(.N), each = length(species))][, taxon := rep(species, times = nrow(surveys))]
long <- merge(long, counts, by = c("Site_ID", "Year", "Rep", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long[, c("Site_ID", "Year", "Rep") := NULL]
stopifnot(nrow(long) == 1122 * 167, sum(long$y) == sum(cm$Number1), sum(long$y > 0) == nrow(counts))

# --- units: exact and coarsened --------------------------------------------------------------
fcl <- fc[, c("Site_ID", rad), with = FALSE]
setnames(fcl, rad, paste0("unit_forest_cover_", rad, "m"))
base <- st[, .(unit = Site_ID, unit_landuse = tolower(LocalLU), unit_forest_cover_50m = LocalForestCover,
               unit_annual_precip_mm = AnnualPrecipitation, unit_dist_river_m = DistanceToRiver)]
cc <- coarsen_coords(st$Latitude, st$Longitude)
stopifnot(uniqueN(paste(cc$lat, cc$lon)) < 150)
u_exact <- cbind(base, st[, .(unit_elevation_m = Elevation, unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude)])
u_coarse <- cbind(base, data.table(unit_elevation_m = round(st$Elevation, -2), unit_decimalLatitude = cc$lat,
                                   unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m))
mk_units <- function(u) merge(u, setnames(copy(fcl), "Site_ID", "unit"), by = "unit")
core_cols <- function(u) u[, intersect(c("unit", "unit_landuse", "unit_forest_cover_50m", "unit_annual_precip_mm", "unit_dist_river_m",
                                          "unit_elevation_m", "unit_decimalLatitude", "unit_decimalLongitude",
                                          "unit_coordinateUncertaintyInMeters"), names(u)), with = FALSE]

periods <- data.table(period = 1:4, period_year = 2016:2019,
                      period_n_points = v[, uniqueN(Site_ID), by = Year][order(Year), V1],
                      period_n_visits = v[, .N, by = Year][order(Year), N])

emit <- function(name, lg, tx, un, exact) {
  lg <- order_eco(merge(lg, core_cols(un), by = "unit"))
  flag_txt <- paste(sprintf("%s (%s)", flagged$scientificName, flagged$taxon_iucnCategory), collapse = ", ")
  dataset <- list(
    title = sprintf("Point counts of %d bird species at 150 points in 25 forest and farm landscapes of northwest Costa Rica, 2016-2019, one to three visits per year%s",
                    nrow(tx), if (exact) " (without IUCN CR/VU species, coordinates as deposited)" else ""),
    creator = "Ke, Alison; Sollmann, Rahel; Frishkoff, Luke O.; Karp, Daniel S.",
    pubDate = "2022", doi = "10.25338/B8VP85", sourceURL = "https://doi.org/10.25338/B8VP85",
    citation = "Ke, A., Sollmann, R., Frishkoff, L. O., & Karp, D. S. (2022). Data from: A hierarchical N-mixture model to estimate behavioral variation and a case study of Neotropical birds [Data set]. Dryad. https://doi.org/10.25338/B8VP85",
    paperDOI = "10.1002/eap.2632",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = paste0("Breeding-season point counts in northwest Costa Rica (Guanacaste), from the Daily and Karp labs' countryside bird surveys: 25 landscapes of six points each in forest and agriculture, counted in May to July of 2016 to 2019. Every point was counted once a year (120 points in 2016, 150 from 2017), and a subset (60 in 2016, 72 later) three times. The deposit logs every visit with time, weather, people and noise, and records each observation instance with the number of individuals and their behaviours. y is the number of individuals of a species at a visit; the 21 visits with no bird recorded are all-zero surveys. Ke et al. (2022) used the behaviours to fit a behavioural N-mixture model. ",
                      if (exact) sprintf("This table omits %s so that point coordinates and elevations ship as deposited; %s has all 167 species with coarsened coordinates.", flag_txt, TABLE)
                      else sprintf("Point coordinates are coarsened to 0.1-degree cells and elevations rounded to 100 m because %s are counted; %s has the other 164 species at the deposited coordinates.", flag_txt, EXACT)),
    samplingProtocol = "Point counts at fixed points, one observer recording every bird seen or heard with the number of individuals and their behaviours; one to three visits per point per breeding season (Ke et al. 2022, Ecological Applications 32:e2632).",
    samplingProtocolCode = "point_count", surveyEvidence = "sample_table",
    surveyEvidenceNote = "visit-data.csv lists every visit (1,122); a survey is a row of it. 21 visits have no detections and are all-zero surveys.",
    responseType = "count", unitKind = "site",
    closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
    closureNote = "occasion = repeat visit within a breeding season (May to July); period = year",
    geographicCoverage = paste0("Northwest Costa Rica (Guanacaste), latitude 9.9 to 10.5, longitude -85.6 to -85.1; 25 landscapes (cluster_id); point coordinates ",
                                if (exact) "as deposited" else "coarsened to 0.1-degree cells"),
    temporalCoverage = "2016-05/2019-07",
    crs = "EPSG:4326",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("As deposited (8 decimal places): the IUCN-flagged species %s are not in this table (E7.3)", flag_txt))
                           else list(value = TRUE, method = sprintf("0.1-degree grid cell centre (coarsen_coords) for all 150 points, uncertainty = cell half-diagonal; elevation rounded to 100 m (E7.4); flagged taxa in their native range: %s; the deposit has coordinates to 8 decimal places", flag_txt)),
    notShipped = c(if (exact) list(`IUCN CR/VU species` = sprintf("%s: in %s only, whose coordinates are coarsened", paste(flagged$taxon, collapse = ", "), TABLE)) else list(),
                   list(`Behavior1-3, Number2-3` = "behaviour codes and the individuals per behaviour (the paper's behavioural detail; the same individuals as Number1)",
                        LU = "per-instance land use the bird was in (forest or agriculture)",
                        `aggression-cases.csv, species-vocal-info.csv, behavior-codes.csv` = "behaviour detail",
                        `Noise_Description, Changes, Notes` = "free text; names people living near the points")),
    notes = "y = sum of Number1 over a species' observation instances at the visit; flyovers counted. The same 2016 visits are in Frishkoff et al. 2018 (doi:10.5061/dryad.7c652r8), whose counts match. obs_crop_type is as deposited (one 'pature' typo kept). The README calls Latitude/Longitude UTM; they are decimal degrees. __units carries forest cover at 105 buffer radii (60-1500 m).")
  ds <- write_table(lg, name, dataset, taxa = tx, periods = periods, units = mk_units(un), script = "data/ke_2022_costarica_birds_nmix.R")
  stage_dict_row(name,
    description = sprintf("Breeding-season point counts of %d bird species at 150 points in 25 forest and agricultural landscapes of Guanacaste, Costa Rica, 2016-2019 (1,122 visits, one to three per point per year), with a full visit log (time, weather, people, noise, crop), land use, forest cover at 50-1500 m and %s.",
                          nrow(tx), if (exact) "coordinates as deposited (IUCN CR/VU species omitted)" else "coordinates coarsened to 0.1 degree"),
    url = "https://doi.org/10.25338/B8VP85",
    reference = "Ke, A., Sollmann, R., Frishkoff, L. O., & Karp, D. S. (2022). A hierarchical N-mixture model to estimate behavioral variation and a case study of Neotropical birds. Ecological Applications, 32(6), e2632.",
    doi_paper = "10.1002/eap.2632", doi_data = "10.25338/B8VP85",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste0(if (exact) sprintf("E7.3 sibling of %s without %s. ", TABLE, flag_txt) else sprintf("Coordinates coarsened (%s counted). ", flag_txt),
                   "Zeros from the visit log (sample_table). y = individuals per species per visit (Number1 summed); behaviours not shipped. Fetched as the Dryad version zip."),
    source_via = "Dryad (version zip)")
  stage_tag_row(name, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
    sampling_protocol = "point_count", design = "Multi-season (4 years x 1-3 visits; 25 landscapes x 6 points)",
    realm = "Terrestrial", country = "CRI", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = "Daily / Karp lab countryside bird surveys, Guanacaste; forest vs agriculture; visit log with weather.", status = "tagged")
}
emit(TABLE, long, taxa, u_coarse, exact = FALSE)
emit(EXACT, long[!taxon %in% flagged$taxon], taxa[!taxon %in% flagged$taxon], u_exact, exact = TRUE)
