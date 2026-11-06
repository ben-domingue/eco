#!/usr/bin/env Rscript
# Table:  klmn_2026_klamath_landbird_count
# Source: NPS Integrated Resource Management Applications (IRMA) DataStore, reference 2319461, doi:10.57830/2319461,
#         version 3, issued 2026-08-25; licence: the EML intellectualRights says "This product is released to the
#         'public domain' under Creative Commons CC0 1.0 No Rights Reserved" (asserted from the cached EML).
#   Klamath Inventory and Monitoring Network and Klamath Bird Observatory (2026). Klamath Network Landbird Point Count
#   Monitoring Data Package 2008-2025. National Park Service, Fort Collins, CO.
# Paper:  none; the NPS Klamath Network landbird monitoring protocol (variable circular plot point counts on routes of
#         up to 12 stations) is described in the EML.
# Data:   KLMN_Landbird_PointCount_metadata.xml (EML), KLMN_Landbirds_PointCounts.csv (100,579 rows: Unit_Code, Park_Name,
#         Route, Station, Sample_Date, Event_Notes, Noise, Time (start of the count's time block), Distance_To_Bird_m,
#         Scientific_Name, Common_Name, Species_Code, Detection_Type, Detection_Habitat, Previous_Detection ("Detected at
#         a previous station"), Number_Detected, Breeding_Status, notes, ProtectedStatus (all "Not Protected")); a time
#         block with no bird is a row with Species_Code NONE ("Surveyed - No Birds"), so every surveyed station-visit has
#         rows (9,461 station-dates). KLMN_Landbirds_Stations.csv (station coordinates, WGS84, and elevation, one row per
#         station visit); KLMN_Landbirds_StationWeather.csv (weather per station-date; 50 duplicated station-dates with
#         conflicting values, and 76 / 82 station-dates in one file and not the other: not shipped); Routes, Species
#         checklist (route-level lists), Photos, Vegetation, VegComposition (not detections).
#         Species codes: one scientific name per code except Aphelocoma californica, recorded as WESJ (Western Scrub-Jay)
#         and CASJ (California Scrub-Jay), the source's two names for one species (merged, ruling on synonyms).
#         Codes without a scientific name: NONE (no bird); unidentified bird groups UNKN, UNWA, UNHA, UNOW, UNFL, UNSW,
#         UNCO, UNWR, UNRP, UNSP, USHU, HBWA, UNTH, UPCH, UNGE, XXQU (kept as taxa without a GBIF key, E6); non-birds COWX
#         (cow), SNAK (snake), REFO (red fox) (not shipped). Codes whose scientific name is not a binomial (the `fix`
#         table in the code): subspecies (AUWA, ORJU, RSFL; kept at that rank), genus and family 'sp.' codes (kept at
#         that rank; UNSA 'Sphyrapicus sp.' and XSAP 'Sphyrapicus (sp)' merged), Aves sp., a species pair (HDFL, no
#         key), WEFL 'Western Flycatcher' recorded as 'Empidonax (sp)' (taken as Empidonax difficilis), REJU with names
#         swapped, three spellings GBIF does not hold (Otus kennicottii, Poecile atricapilla, Actitis macularia), and
#         non-birds UNSQ (squirrel), CHIP (chipmunk), BTDE (black-tailed deer), FROG (not shipped).
# Mapping (repeated counts, community): unit = station, cluster_id = route, taxon = species code, period = year
#   (1-15 for 2010-2019 and 2021-2025; no surveys in 2020; __periods; one count per station-year, so no occasion;
#   2008-2009 not shipped: Number_Detected is blank
#   on 7,704 of their 8,520 detection rows, while 544 others say 1, so a blank is not a known count), date, y = sum of Number_Detected over the visit's rows for the taxon (all distances and time blocks);
#   obs_n_previous_station = the part of y flagged "Detected at a previous station". surveyEvidence = row_presence
#   (NONE rows mark visits and blocks with no bird). taxonInclusion = recorded. unit_park, unit_elevation_m and
#   coordinates (the station's median over its records).
#   Coordinates (E7; batch 46, #10): Tricolored Blackbird (EN), Evening Grosbeak and Pinyon Jay (VU) are in the table
#   (asserted from GBIF's IUCN records; all within their native range), so under the ruling on the publisher
#   (2026-11-06, which withdrew the agency exception) two tables ship (E7 scope, 3): this one, every taxon, with station
#   coordinates snapped to their 0.1-degree cell centre and elevation rounded to the nearest 100 m; and
#   klmn_2026_klamath_landbird_exact_count, at the published coordinates and elevations, without the three flagged
#   species (unidentified codes such as UNBL blackbird sp. stay in both tables). Station and route codes are the source's codes (park prefix + number), and
#   unit_park is a park code, kept in both: a park is coarser than the cell for all but Oregon Caves.
#   Not shipped: distance and time block of each detection, detection type, breeding status (a distance-sampling
#   or time-removal table could be built from them); weather (see above); vegetation surveys.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "klmn_2026_klamath_landbird_count"
ids <- c(meta = 761592, pc = 761594, st = 761598)
fn <- c(meta = "KLMN_Landbird_PointCount_metadata.xml", pc = "KLMN_Landbirds_PointCounts.csv", st = "KLMN_Landbirds_Stations.csv")
f <- setNames(sapply(names(ids), function(k) download_cached(sprintf("https://irma.nps.gov/DataStore/DownloadFile/%d", ids[[k]]), TABLE, filename = fn[[k]])), names(ids))
eml <- paste(readLines(f[["meta"]], warn = FALSE), collapse = " ")
stopifnot(grepl("released to the \"public domain\" under Creative Commons CC0 1.0", eml, fixed = TRUE))
p <- fread(f[["pc"]], colClasses = "character")
st <- fread(f[["st"]])
stopifnot(nrow(p) == 100579L, all(p$ProtectedStatus == "Not Protected"))
p[, d := as.IDate(Sample_Date)]
# 2008-2009: Number_Detected is blank on 7,704 of 8,520 detection rows (and 1 on 544 others), so a blank is not a
# known count; those two years are not shipped. From 2010 every detection row has a count.
stopifnot(p[Species_Code != "NONE" & year(d) %in% 2008:2009, sum(Number_Detected == "")] == 7704L,
          p[Species_Code != "NONE" & year(d) >= 2010, all(grepl("^[0-9]+$", Number_Detected))])
n_0809 <- uniqueN(p[year(d) %in% 2008:2009, .(Station, d)])
p <- p[year(d) >= 2010]
vis <- unique(p[, .(Unit_Code, Route, Station, d)])
stopifnot(!anyDuplicated(vis[, .(Station, d)]))
# codes needing a decision (everything else is a binomial matched EXACT on GBIF, asserted below):
#   non-birds, not shipped; synonyms and 'sp.' codes merged (rulings on synonyms and 'sp.'/'spp.'); higher-rank and
#   unidentified bird groups kept as their own taxa (E6); subspecies kept at that rank; spellings GBIF needs fixed
nonbird <- c("COWX", "SNAK", "REFO", "UNSQ", "CHIP", "BTDE", "FROG")
merge_to <- c(WESJ = "CASJ", XSAP = "UNSA")
unid <- c("UNKN", "UNWA", "UNHA", "UNOW", "UNFL", "UNSW", "UNCO", "UNWR", "UNRP", "UNSP", "USHU", "HBWA", "UNTH", "UPCH", "UNGE", "XXQU", "HDFL")
fix <- rbindlist(list(
  list("AUWA", "Dendroica c. auduboni", "Setophaga coronata auduboni", "subspecies", "source name Dendroica c. auduboni (Audubon's Warbler); matched as Setophaga coronata auduboni"),
  list("ORJU", "Junco h. oreganus", "Junco hyemalis oreganus", "subspecies", "source name Junco h. oreganus (Oregon Junco)"),
  list("RSFL", "Colaptes a. cafer", "Colaptes auratus cafer", "subspecies", "source name Colaptes a. cafer (Red-shafted Flicker)"),
  list("UYRW", "Setophaga coronata coronata/auduboni", "Setophaga coronata", "species", "source: Yellow-rumped Warbler, subspecies not determined (coronata or auduboni)"),
  list("WEFL", "Empidonax (sp)", "Empidonax difficilis", "species", "source code WEFL 'Western Flycatcher' with scientific name 'Empidonax (sp)'; Western Flycatcher is Empidonax difficilis (AOS 2023, which merged Pacific-slope and Cordilleran)"),
  list("REJU", "Gallus gallus", "Gallus gallus", "species", "source has the scientific and common names swapped ('Red Junglefowl' / 'Gallus gallus')"),
  list("WESO", "Otus kennicottii", "Megascops kennicottii", "species", "source name Otus kennicottii; matched as Megascops kennicottii"),
  list("BCCH", "Poecile atricapilla", "Poecile atricapillus", "species", "source spelling Poecile atricapilla"),
  list("SPSA", "Actitis macularia", "Actitis macularius", "species", "source spelling Actitis macularia"),
  list("UNSA", "Sphyrapicus sp.", "Sphyrapicus", "genus", "source codes UNSA 'Sphyrapicus sp.' and XSAP 'Sphyrapicus (sp)' merged"),
  list("UAHA", "Accipiter (sp)", "Accipiter", "genus", "source: Unknown Accipiter Hawk Species"),
  list("OJTI", "Baeolophus sp.", "Baeolophus", "genus", "source: Unidentified Oak/Juniper Titmouse"),
  list("UEFL", "Empidonax sp.", "Empidonax", "genus", "source: Empidonax Flycatcher sp."),
  list("UNGF", "Carduelis sp.", "Carduelis", "genus", "source: Goldfinch sp. (genus as recorded)"),
  list("UNPI", "Columba sp.", "Columba", "genus", "source: Pigeon sp."),
  list("UNWO", "Picidae sp.", "Picidae", "family", "source: Woodpecker sp."),
  list("UNHU", "Trochilidae sp.", "Trochilidae", "family", "source: Hummingbird sp."),
  list("UNFI", "Fringillidae sp.", "Fringillidae", "family", "source: Finch sp."),
  list("UNBL", "Icteridae sp.", "Icteridae", "family", "source: Blackbird sp."),
  list("UNDU", "Anatidae sp.", "Anatidae", "family", "source: Duck sp."),
  list("UNGU", "Laridae sp.", "Laridae", "family", "source: Gull sp."),
  list("UNAH", "Accipitridae sp.", "Accipitridae", "family", "source: Unknown Hawk Species"),
  list("UNBI", "Aves sp.", "Aves", "class", "source: Bird sp.")))
setnames(fix, c("taxon", "src", "lookup", "rank", "remark"))
blank <- p[Scientific_Name == "", unique(Species_Code)]
stopifnot(setequal(blank, c("NONE", "COWX", "SNAK", "REFO", setdiff(unid, "HDFL"))),
          p[Scientific_Name != "", uniqueN(Scientific_Name), by = Species_Code][, all(V1 == 1L)],
          identical(p[Scientific_Name == "Aphelocoma californica", sort(unique(Species_Code))], c("CASJ", "WESJ")),
          identical(p[Species_Code %in% c("XSAP", "UNSA"), sort(unique(Scientific_Name))], c("Sphyrapicus (sp)", "Sphyrapicus sp.")),
          all(fix$taxon %in% p$Species_Code), all(fix[!taxon %in% c("REJU")]$src == p$Scientific_Name[match(fix[!taxon %in% c("REJU")]$taxon, p$Species_Code)]),
          p[Species_Code == "REJU", all(Scientific_Name == "Red Junglefowl" & Common_Name == "Gallus gallus")],
          p[Species_Code == "NONE", all(Number_Detected %in% c("0", "1", "10"))])
n_nonbird <- p[Species_Code %in% nonbird, .N]
r <- p[!Species_Code %in% c("NONE", nonbird)]
for (k in names(merge_to)) r[Species_Code == k, Species_Code := merge_to[[k]]]
r[, `:=`(n = as.integer(Number_Detected), prev = Previous_Detection == "Detected at a previous station")]
cnt <- r[, .(y = sum(n), obs_n_previous_station = sum(n[prev])), by = .(Station, d, taxon = Species_Code)]
tx <- unique(r[, .(taxon = Species_Code, sci = Scientific_Name, vern = Common_Name)])[, .SD[1], by = taxon]
tx[taxon == "CASJ", vern := "California Scrub-Jay"]
tx[taxon == "REJU", `:=`(sci = "Gallus gallus", vern = "Red Junglefowl")]
stopifnot(!anyDuplicated(tx$taxon), all(tx[!taxon %in% c(unid, fix$taxon)]$sci %like% "^[A-Z][a-z]+ [a-z]+$"))
# visits: year -> period, visit within station-year
yrs <- sort(unique(year(vis$d)))
stopifnot(identical(yrs, c(2010:2019, 2021:2025)))
vis[, `:=`(period = match(year(d), yrs))]
setorder(vis, Station, d); vis[, occasion := seq_len(.N), by = .(Station, period)]
stopifnot(max(vis$occasion) == 1L)   # from 2010 every station is counted once in a year it is surveyed
# coordinates and elevation: the station's median over its records
stc <- st[, .(lat = median(Latitude, na.rm = TRUE), lon = median(Longitude, na.rm = TRUE), elev = median(suppressWarnings(as.numeric(Elevation_m)), na.rm = TRUE),
              spread = if (all(is.na(Latitude))) NA_real_ else max(diff(range(Latitude, na.rm = TRUE)), diff(range(Longitude, na.rm = TRUE)))), by = Station]
nocoord <- setdiff(unique(vis$Station), stc[!is.na(lat), Station])
cat(sprintf("  %d surveyed stations have no coordinates in the Stations file: %s\n", length(nocoord), paste(head(nocoord, 10), collapse = ", ")))
cat(sprintf("  station coordinate spread over records: %d of %d stations > 0.001 deg\n", stc[!is.na(spread) & spread > 0.001, .N], nrow(stc)))
grid <- CJ(k = seq_len(nrow(vis)), taxon = tx$taxon)
grid[, `:=`(Station = vis$Station[k], d = vis$d[k])]
long <- merge(grid, cnt, by = c("Station", "d", "taxon"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, obs_n_previous_station = 0L)]
long <- merge(long, vis[, .(Station, d, Unit_Code, Route, period, occasion)], by = c("Station", "d"))
long <- merge(long, stc[, .(Station, unit_elevation_m = elev, unit_decimalLatitude = round(lat, 6), unit_decimalLongitude = round(lon, 6))], by = "Station", all.x = TRUE)
long <- long[, .(unit = Station, taxon, y, period, date = format(d), cluster_id = Route, unit_park = Unit_Code,
                 unit_elevation_m, unit_decimalLatitude, unit_decimalLongitude, obs_n_previous_station)]
long <- order_eco(long)
stopifnot(nrow(long) == nrow(vis) * nrow(tx), sum(long$y) == sum(r$n))
cat(sprintf("  %d rows, %d stations, %d taxa, %d birds\n", nrow(long), uniqueN(long$unit), nrow(tx), sum(long$y)))
isunid <- tx$taxon %in% unid
fx <- fix[match(tx$taxon, fix$taxon)]
rank <- ifelse(isunid, ifelse(tx$taxon == "HDFL", "species aggregate", "unidentified group"), ifelse(is.na(fx$rank), "species", fx$rank))
look <- ifelse(is.na(fx$lookup), tx$sci, fx$lookup)
rem <- ifelse(isunid, sprintf("source code %s ('%s'): a bird not identified to species; no GBIF key", tx$taxon, tx$vern),
       ifelse(tx$taxon == "CASJ", "recorded as WESJ (Western Scrub-Jay) and CASJ (California Scrub-Jay), the source's names for Aphelocoma californica before and after the split; merged",
       ifelse(is.na(fx$remark), NA_character_, fx$remark)))
higher <- tx$taxon[rank %in% c("genus", "family", "class")]
taxa <- make_taxa(tx$taxon, ifelse(isunid & tx$sci == "", tx$vern, tx$sci), vernacularName = tx$vern, taxonRank = rank, lookupName = look,
                  no_key = tx$taxon[isunid], allow_higher = higher, taxonRemarks = rem, exact = FALSE)
# Columba (a plant homonym too) and any higher-rank row that fell to a kingdom: re-match with Aves as the hint
for (tk in taxa[taxon %in% higher & (is.na(taxonID) | kingdom_taxonID(taxonID) | gbifMatchType == "NONE"), taxon]) {
  h <- gbif_taxon_hinted(look[tx$taxon == tk], list(kingdom = "Animalia", class = "Aves"))
  stopifnot(identical(h$canonicalName, look[tx$taxon == tk]), identical(h$kingdom, "Animalia"))
  taxa[taxon == tk, `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"))]
}
bad <- taxa[!taxon %in% unid & !(gbifMatchType == "EXACT" | (gbifMatchType %like% "^HIGHERRANK|hinted" & taxon %in% higher)) | kingdom_taxonID(taxonID)]
if (nrow(bad)) print(bad[, .(taxon, scientificName, taxonRank, gbifMatchType, taxonID)])
stopifnot(nrow(bad) == 0L)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[taxon_iucnCategory %in% c("CR", "EN", "VU", "NT"), .(taxon, scientificName, taxon_iucnCategory)])
periods <- data.table(period = seq_along(yrs), year = yrs, n_visits = vis[, .N, by = period][order(period), N])
fl_sp <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(setequal(fl_sp, c("TRBL", "EVGR", "PIJA")))
fl <- fl_sp   # E7 scope 3: the sibling drops the flagged species; unidentified codes (blackbird sp., ...) stay in both
stopifnot(all(fl %in% taxa$taxon))
flag <- taxa[taxon %in% fl_sp, sprintf("%s (%s)", scientificName, taxon_iucnCategory)]
cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude, 0.1)
long_c <- copy(long)[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                             unit_coordinateUncertaintyInMeters = cc$uncertainty_m,
                             unit_elevation_m = round(unit_elevation_m, -2))]
long_c <- order_eco(long_c)
EXACT <- "klmn_2026_klamath_landbird_exact_count"
emit <- function(TABLE, exact) {
  lt <- if (exact) long[!taxon %in% fl] else long_c
  tt <- if (exact) taxa[!taxon %in% fl] else taxa
  stopifnot(nrow(lt) == nrow(vis) * nrow(tt))
  dataset <- list(
    title = paste0("Point counts of landbirds at stations on park routes of the NPS Klamath Network (Crater Lake, Lava Beds, Lassen Volcanic, Oregon Caves, Redwood, Whiskeytown), 2010-2025", if (exact) " (without IUCN-threatened species; coordinates as published)" else ""),
    creator = "Klamath Inventory and Monitoring Network; Klamath Bird Observatory", pubDate = "2026",
    doi = "10.57830/2319461", sourceURL = "https://doi.org/10.57830/2319461",
    citation = "Klamath Inventory and Monitoring Network and Klamath Bird Observatory (2026). Klamath Network Landbird Point Count Monitoring Data Package 2008-2025. National Park Service, Fort Collins, CO. https://doi.org/10.57830/2319461",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = "Long-term landbird monitoring by the National Park Service Klamath Inventory and Monitoring Network with the Klamath Bird Observatory: variable circular plot point counts at stations along routes in six park units of northern California and southern Oregon, 2008-2025, with species, time block, distance, detection type and breeding status per detection.",
    samplingProtocol = "Variable circular plot point counts at stations on routes of up to 12 stations in a rotating panel of routes per park; each detection recorded with time block, distance, detection type and whether the bird was already detected at a previous station; time blocks with no birds recorded as 'Surveyed - No Birds'.",
    samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
    responseType = "count", unitKind = "site", closure = "none",
    closureNote = "Each station is counted once in a year it is surveyed (2010-2025); years are periods. Routes are surveyed in rotating panels, so a station's periods are not consecutive; replication is across years (and across a route's stations, cluster_id).",
    occasionKind = "none", taxonInclusion = "recorded",
    geographicCoverage = "Six NPS units of the Klamath Network: Crater Lake NP and Oregon Caves NM (Oregon), Lava Beds NM, Lassen Volcanic NP, Redwood National and State Parks, Whiskeytown NRA (California), USA",
    temporalCoverage = "2010-05/2025-08",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = sprintf("Station coordinates as published by the National Park Service (median of the station's records; 5 surveyed stations have no coordinates in the source). The IUCN-threatened species (%s) are not in this table (E7 scope, 3); klmn_2026_klamath_landbird_count has them, coarsened.", paste(flag, collapse = ", "))) else
      list(value = TRUE, method = sprintf("coarsen_coords(): station coordinates (median of the station's records) snapped to the 0.1-degree cell centre, uncertainty the cell half-diagonal, and elevation rounded to the nearest 100 m, because IUCN-threatened species are in the table within their native range (%s; E7, ruling on the publisher 2026-11-06, which withdrew the agency exception); 5 surveyed stations have no coordinates in the source. klmn_2026_klamath_landbird_exact_count keeps the other taxa at published precision.", paste(flag, collapse = ", "))),
    covariateNote = "cluster_id: route. unit_park: NPS unit code. unit_elevation_m: station elevation. obs_n_previous_station: individuals of the taxon in y that were flagged as detected at a previous station on the route.",
    notShipped = c(if (exact) list(threatened = sprintf("%s: in klmn_2026_klamath_landbird_count only, with coarsened coordinates (E7 scope, 3)", paste(flag, collapse = ", "))), list(years_2008_2009 = sprintf("%d station-visits of 2008-2009: Number_Detected is blank on most detection rows, so counts are unknown", n_0809),
                      detection_detail = "distance, time block, detection type, habitat and breeding status of each detection",
                      non_birds = sprintf("%d records of mammals, a snake or a frog (cow, red fox, squirrel, chipmunk, deer)", n_nonbird),
                      weather = "station weather (duplicated and unmatched station-dates in the weather file)",
                      vegetation = "vegetation and composition surveys; route species checklists; photographs")),
    notes = "y sums all individuals of the taxon over the visit's time blocks and distances, including birds flagged as detected at a previous station (their number is in obs_n_previous_station). Unidentified bird groups (e.g. warbler sp.) are taxa without a GBIF key.")
  ds <- write_table(lt, TABLE, dataset, taxa = tt, periods = periods, script = "data/klmn_2026_klamath_landbird_count.R")
  stage_dict_row(TABLE,
    description = paste0("Landbird point counts at stations on routes in six NPS Klamath Network parks, northern California and southern Oregon, 2010-2025 (2008-2009 counts incomplete in the source)", if (exact) "; without IUCN-threatened species, coordinates as published." else "; coordinates coarsened to 0.1 degree."),
    url = "https://doi.org/10.57830/2319461", reference = "", doi_paper = "", doi_data = "10.57830/2319461",
    original_license = "CC0 1.0 (public domain, NPS EML intellectualRights)", derived_license = "CC0 1.0",
    notes = paste0("NPS IRMA DataStore data package, version 3.", if (exact) " E7 sibling without IUCN-threatened species." else " Coordinates coarsened to 0.1 degree (IUCN EN/VU species)."), source_via = "NPS IRMA DataStore (DownloadFile)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community abundance (repeated counts)",
    sampling_protocol = "point_count", design = "Multi-season (15 years, rotating route panels)",
    realm = "Terrestrial", country = "USA", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)", notes = "Distance data not shipped.")
}
emit("klmn_2026_klamath_landbird_count", exact = FALSE)
emit(EXACT, exact = TRUE)
