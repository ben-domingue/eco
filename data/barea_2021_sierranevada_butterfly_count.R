#!/usr/bin/env Rscript
# Tables: barea_2021_sierranevada_butterfly_count (coarsened) and
#         barea_2021_sierran_butterfly_exact_count (E7.3 sibling without the flagged taxa)
# Source: GBIF sampling-event dataset d7a3df60-e856-438b-851d-74653ef6c0d2, doi:10.15470/tc3gdq,
#         GBIF Spain IPT resource "butterflies", EML packageId .../v1.2, pubDate 2021-12-17.
#         Licence as shown on GBIF and in the EML: CC BY 4.0 ("This work is licensed under a
#         Creative Commons Attribution (CC-BY) 4.0 License"; every event row carries the CC BY 4.0 URL).
#         Citation (GBIF): Barea-Azcón J M (2021). Dataset of butterfly monitoring in Sierra Nevada
#         (Spain). Version 1.2. Sierra Nevada Global-Change Observatory (UGR-JA). Sampling event
#         dataset. https://doi.org/10.15470/tc3gdq
# Paper:  none for the dataset; protocol in Barea-Azcón, Martín-Jaramillo & López (2012), Butterflies,
#         pp. 90-91 in Aspizua et al. (coords.), Observatorio de Cambio Global Sierra Nevada:
#         Monitoring Methodologies (Junta de Andalucía), cited as samplingProtocol on every event.
# Data:   Darwin Core Archive, event core with occurrence and measurementorfact extensions.
#   event.txt (10,369 events): 1,725 parent events, one per transect walk
#     ("OBSNEV:BUTTERFLIES:<date>:<transect>:<walk id>"), 22 transects, 2008-07-07 to 2020-03-08
#     (no walk in 2011; one in 2020), mostly March-October; and 8,644 child events, one per
#     section of a walk in which a butterfly was counted (child ids add ":<section>"). 109 walks
#     have no child: walks with no butterfly. Per transect and constant: centroid coordinates
#     (georeferenceRemarks), footprintWKT of the route, min / max elevation, habitat mix and
#     length (sampleSizeValue, m); transect 25 (5 walks in 2010) has no coordinates,
#     elevation or length. eventTime is the walk's start/end.
#   occurrence.txt (34,137 rows): adults per section (organismQuantity, individuals); 32,122 to
#     species, 500 to the subspecies Coenonympha pamphilus lyllus, 1,239 to genus and 276 to
#     family; 102 species. recordedBy is one name or a "|" list of names, constant per walk.
#   measurementorfact.txt (4,852 rows), on the parent events: wind (Beaufort), cloud cover (%,
#     as 0 or a class 0-25 / 25-50 / 50-75 / 75-100) and air temperature (C), each missing for
#     some walks.
#   EML: Pollard & Yates line transect, every butterfly within 5 m to each side and 5 m ahead and
#     above, counted per section; walks about every two weeks from March to October in suitable
#     weather; transects 300-3,270 m, 700-3,100 m a.s.l.
#
# Mapping (standard E1-E5, community repeated counts / Pollard walks):
#   unit = transect (22, "T<nn>"), taxon = 8-letter code (4 genus + 4 species letters), period =
#   calendar year (1 = 2008 ... 11 = 2020, no 2011; __periods), occasion = walk within the
#   transect-year in date order, y = adults of the species over all sections of the walk; 0 for
#   every species at every walk (all butterflies are counted).
#   surveyEvidence = sample_table: every walk is a parent event, including the 109 with no
#   butterfly; every occurrence belongs to a section of a listed walk (asserted). Section-level
#   zeros are not built: an empty section has no event, and the number of sections a transect
#   has is not stated.
#   date = walk date; observer = the walk's team as pseudonymous ids (OBS01... by first walk,
#   sorted and joined with "+"), NA where recordedBy is empty or the walk had no record;
#   obs_n_observers; obs_start_time / obs_end_time (HH:MM, local); obs_wind_beaufort,
#   obs_cloud_cover_pct (as recorded: "0" or a class), obs_temperature_c. Unit covariates in
#   __units: locality, length, min / max elevation, habitat mix, coordinates.
#   closure = open (walks every two weeks March-October span flight periods; closureNote),
#   occasionKind = time, taxonInclusion = recorded (every species recorded at least once).
#   Coordinates (E7.3, E7.4): the published transect centroids; the script checks each species'
#   IUCN category through GBIF (iucn_category). If any is CR / EN / VU, two tables ship:
#   barea_2021_sierranevada_butterfly_count, all species, every transect coarsened to 0.1 degree,
#   unit_min/maximumElevationInMeters rounded to 100 m and unit_locality (place names) not
#   shipped; and barea_2021_sierran_butterfly_exact_count (the name cut to 40 characters by
#   trimming "sierranevada" from its end, E7.3) without the flagged species, coordinates,
#   elevations and localities as published. Unit ids are codes (T01...) in both.
#   Not shipped: section counts (summed into y); records to genus or family (not taxa of the
#   community; the species zeros at those walks stay as recorded); the subspecies epithet
#   (merged into its species, the only one with a subspecies); observer names; footprintWKT
#   (route geometry finer than the centroid).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "barea_2021_sierranevada_butterfly_count"

zip <- download_cached("https://ipt.gbif.es/archive.do?r=butterflies", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "measurementorfact.txt", "eml.xml", "meta.xml")))
eml <- readLines(file.path(dwca, "eml.xml"), warn = FALSE)
stopifnot(any(grepl("Creative Commons Attribution (CC-BY) 4.0", eml, fixed = TRUE)),
          any(grepl("d7a3df60-e856-438b-851d-74653ef6c0d2/v1.2", eml, fixed = TRUE)))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL, encoding = "UTF-8")
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("measurementorfact.txt")
stopifnot(nrow(ev) == 10369, !anyDuplicated(ev$eventID), nrow(oc) == 34137, nrow(mf) == 4852,
          all(ev$license == "https://creativecommons.org/licenses/by/4.0/"))
par <- ev[parentEventID == ""]; ch <- ev[parentEventID != ""]
stopifnot(nrow(par) == 1725, nrow(ch) == 8644, all(ch$parentEventID %in% par$eventID),
          all(grepl("^OBSNEV:BUTTERFLIES:\\d{4}-\\d{2}-\\d{2}:\\d+:\\d+$", par$eventID)),
          all(startsWith(ch$eventID, paste0(ch$parentEventID, ":"))))
par[, `:=`(tr = sub("^OBSNEV:BUTTERFLIES:[0-9-]+:(\\d+):\\d+$", "\\1", eventID), d = as.IDate(substr(eventDate, 1, 10)))]
stopifnot(uniqueN(par$tr) == 22, !anyNA(par$d), all(format(par$d) == sub("^OBSNEV:BUTTERFLIES:([0-9-]+):.*$", "\\1", par$eventID)),
          !anyDuplicated(par[, .(tr, d)]), sum(!par$eventID %in% ch$parentEventID) == 109,
          par[, .(n = uniqueN(paste(decimalLatitude, decimalLongitude, minimumElevationInMeters, maximumElevationInMeters,
                                    habitat, sampleSizeValue, verbatimLocality))), by = tr][, all(n == 1)],
          all(par$georeferenceRemarks == "The decimalLatitude and decimalLongitude correspond to the centroid coordinates of the transect (inside)"),
          all(par$geodeticDatum == "EPSG:4326"), all(par$sampleSizeUnit == "m"))

# occurrences
stopifnot(all(oc$eventID %in% ch$eventID), all(ch$eventID %in% oc$eventID), all(oc$organismQuantityType == "individuals"),
          all(oc$lifeStage == "adult"), all(as.integer(oc$organismQuantity) >= 1),
          identical(as.vector(table(oc$taxonRank)[c("species", "subspecies", "genus", "family")]), c(32122L, 500L, 1239L, 276L)),
          oc[taxonRank == "subspecies", all(scientificName == "Coenonympha pamphilus lyllus")],
          !anyDuplicated(oc[, .(eventID, scientificName)]))
oc[, walk := ch$parentEventID[match(eventID, ch$eventID)]]
stopifnot(oc[, uniqueN(recordedBy), by = walk][, all(V1 == 1)])
spo <- oc[taxonRank %in% c("species", "subspecies")]
spo[, binomial := paste(genus, specificEpithet)]
sp <- data.table(binomial = sort(unique(spo$binomial)))
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", binomial), 1, 4), substr(sub("^\\S+ ", "", binomial), 1, 4)))]
stopifnot(nrow(sp) == 102, !anyDuplicated(sp$taxon), all(grepl("^[A-Z][a-z]+ [a-z-]+$", sp$binomial)))
counts <- spo[, .(y = sum(as.integer(organismQuantity))), by = .(walk, binomial)]
counts[, taxon := sp$taxon[match(binomial, sp$binomial)]]

# walks (the survey set)
years <- sort(unique(year(par$d)))
stopifnot(identical(years, c(2008:2010, 2012:2020)) || identical(years, c(2008L:2010L, 2012L:2020L)))
setorder(par, tr, d)
par[, `:=`(period = match(year(d), years), occasion = seq_len(.N)), by = .(tr, year(d))]
par[, period := match(year(d), years)]
tm <- tstrsplit(par$eventTime, "/", fixed = TRUE, fill = "")
hm <- function(x) { x <- substr(x, 1, 5); fifelse(grepl("^\\d{2}:\\d{2}$", x), x, NA_character_) }
par[, `:=`(obs_start_time = hm(tm[[1]]), obs_end_time = hm(tm[[2]]))]
stopifnot(mean(!is.na(par$obs_end_time)) > 0.98)
# observers: pseudonymous ids per person, team = sorted ids
rb <- oc[!duplicated(walk), .(walk, recordedBy)]
par[, rec := rb$recordedBy[match(eventID, rb$walk)]]
par[is.na(rec) | rec == "", rec := NA_character_]
people <- par[!is.na(rec), .(person = trimws(gsub("\\s+", " ", unlist(strsplit(rec, "|", fixed = TRUE))))), by = .(eventID, d)]
first <- people[, .(f = min(d)), by = person][order(f, person)]
first[, id := sprintf("OBS%02d", seq_len(.N))]
people[, id := first$id[match(person, first$person)]]
team <- people[, .(observer = paste(sort(unique(id)), collapse = "+"), obs_n_observers = uniqueN(id)), by = eventID]
par <- merge(par, team, by = "eventID", all.x = TRUE)
stopifnot(sum(is.na(par$observer)) == 109 + par[eventID %in% oc[recordedBy == "", walk], .N])
cat(sprintf("  %d observers, %d walks without a recorded observer\n", nrow(first), sum(is.na(par$observer))))

# weather (parent events)
stopifnot(all(mf$id %in% par$eventID), !anyDuplicated(mf[, .(id, measurementType)]),
          setequal(unique(mf$measurementType), c("wind", "cloud cover", "air temperature")),
          all(mf[measurementType == "wind", measurementValue] %in% as.character(0:12)),
          all(mf[measurementType == "cloud cover", measurementValue] %in% c("0", "0-25", "25-50", "50-75", "75-100")))
mw <- dcast(mf, id ~ measurementType, value.var = "measurementValue")
setnames(mw, c("id", "air temperature", "cloud cover", "wind"), c("eventID", "t", "cc", "w"))
mw[, `:=`(obs_temperature_c = as.numeric(t), obs_cloud_cover_pct = cc, obs_wind_beaufort = as.integer(w))]
stopifnot(all(mw$obs_temperature_c[!is.na(mw$obs_temperature_c)] > 0 & mw$obs_temperature_c[!is.na(mw$obs_temperature_c)] < 45))
par <- merge(par, mw[, .(eventID, obs_wind_beaufort, obs_cloud_cover_pct, obs_temperature_c)], by = "eventID", all.x = TRUE)

# units
units <- par[!duplicated(tr), .(unit = sprintf("T%02d", as.integer(tr)), unit_locality = verbatimLocality,
             unit_length_m = suppressWarnings(as.numeric(sampleSizeValue)),
             unit_minimumElevationInMeters = suppressWarnings(as.numeric(minimumElevationInMeters)), unit_maximumElevationInMeters = suppressWarnings(as.numeric(maximumElevationInMeters)),
             unit_habitat = habitat, unit_decimalLatitude = decimalLatitude, unit_decimalLongitude = decimalLongitude)]
units[, `:=`(unit_decimalLatitude = suppressWarnings(as.numeric(unit_decimalLatitude)), unit_decimalLongitude = suppressWarnings(as.numeric(unit_decimalLongitude)))]
# transect 25 (Robledal de Cáñar, 5 walks in 2010) has no coordinates, elevation or length in the source
stopifnot(nrow(units) == 22, identical(units[is.na(unit_length_m), unit], "T25"), identical(units[is.na(unit_decimalLatitude), unit], "T25"),
          all(between(units[unit != "T25", unit_decimalLatitude], 36.9, 37.2)), all(between(units[unit != "T25", unit_decimalLongitude], -3.7, -2.9)))
setorder(units, unit)

# taxa and the IUCN check
# two source spellings use the feminine / other ending: GBIF strict matching is FUZZY on them
lk <- c("Colias crocea" = "Colias croceus", "Hyponephele lupina" = "Hyponephele lupinus")
stopifnot(all(names(lk) %in% sp$binomial))
taxa <- make_taxa(sp$taxon, sp$binomial, lookupName = fifelse(sp$binomial %in% names(lk), lk[sp$binomial], sp$binomial))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# iucn_category() returns NA where the GBIF key's accepted species differs from the name on the
# IUCN record (GBIF places Polyommatus golgus in Plebicula, P. panoptes under P. baton, ...). The
# record applies to the source's taxon when the name it carries is the source's own binomial:
# then its code is used (asserted for every NA; 14 at build time, incl. Polyommatus golgus EN).
same_name <- function(id, nm) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- strsplit(r$scientificName %||% "", " ")[[1]]
  if (identical(paste(head(w, 2), collapse = " "), nm)) r$code %||% NA_character_ else NA_character_
}
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := mapply(same_name, taxonID, scientificName)]
stopifnot(!anyNA(taxa$taxon_iucnCategory))
print(taxa[, .N, by = taxon_iucnCategory])
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
cat("  IUCN flagged:", if (nrow(flagged)) paste(flagged$scientificName, flagged$taxon_iucnCategory, collapse = "; ") else "none", "\n")
COARSEN <- nrow(flagged) > 0
stopifnot(COARSEN)                      # Polyommatus golgus EN, Carcharodus baeticus VU at build time: the _exact sibling ships
units_exact <- copy(units)
cc <- coarsen_coords(units$unit_decimalLatitude, units$unit_decimalLongitude)
units[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m,
             unit_minimumElevationInMeters = round(unit_minimumElevationInMeters, -2), unit_maximumElevationInMeters = round(unit_maximumElevationInMeters, -2))]
units[, unit_locality := NULL]

# long table
surveys <- par[, .(eventID, unit = sprintf("T%02d", as.integer(tr)), period, occasion, date = format(d), observer, obs_n_observers,
                   obs_start_time, obs_end_time, obs_wind_beaufort, obs_cloud_cover_pct, obs_temperature_c)]
stopifnot(nrow(surveys) == 1725, !anyDuplicated(surveys[, .(unit, period, occasion)]))
long <- surveys[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(surveys))]
long <- merge(long, counts[, .(eventID = walk, taxon, y)], by = c("eventID", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]; long[, eventID := NULL]
stopifnot(nrow(long) == 1725 * 102, sum(long$y) == sum(as.integer(spo$organismQuantity)))
long <- order_eco(long)

periods <- data.table(period = seq_along(years), period_year = years,
                      period_n_walks = sapply(years, function(yy) sum(year(par$d) == yy)),
                      period_n_transects = sapply(years, function(yy) uniqueN(par[year(d) == yy, tr])))
emit <- function(TABLE, lg, tx, u, exact) {
  bb <- u[!is.na(unit_decimalLatitude), .(w = min(unit_decimalLongitude), e = max(unit_decimalLongitude), s = min(unit_decimalLatitude), n = max(unit_decimalLatitude))]
  dataset <- list(
    title = sprintf("Pollard-walk counts of %d butterfly species on 22 transects of the Sierra Nevada Global-Change Observatory, Spain, 2008-2020%s", nrow(tx), if (exact) " (without IUCN-threatened species, coordinates as published)" else ""),
    creator = "Barea-Azcón, José Miguel; Ros Candeira, Andrea", pubDate = "2021-12-17", sourceURL = "https://doi.org/10.15470/tc3gdq",
    citation = "Barea-Azcón J M (2021). Dataset of butterfly monitoring in Sierra Nevada (Spain). Version 1.2. Sierra Nevada Global-Change Observatory (UGR-JA). Sampling event dataset. https://doi.org/10.15470/tc3gdq (CC BY 4.0).",
    dataDOI = "10.15470/tc3gdq",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = paste0("Butterfly line transects of the Sierra Nevada Global-Change Observatory (Andalusia, Spain): 22 transects from 700 to 3,100 m a.s.l. in high-mountain grassland and scrub, oak and pine forest, pastures and wetlands, walked about every two weeks from March to October, 2008-2020 (none in 2011). 1,725 walks, 109 with no butterfly; counts summed over the sections of a walk; 102 species.", if (exact) sprintf(" This table omits %s (IUCN %s) so that the transect centroids, elevations and localities ship as published; barea_2021_sierranevada_butterfly_count has every species with coarsened locations.", paste(flagged$scientificName, collapse = " and "), paste(flagged$taxon_iucnCategory, collapse = ", ")) else sprintf(" Locations coarsened because %s are IUCN-threatened; barea_2021_sierran_butterfly_exact_count has the other species at published precision.", paste(flagged$scientificName, collapse = " and "))),
    samplingProtocol = "Pollard & Yates line transect: every butterfly within 5 m to each side and 5 m ahead and above counted per section, netted and released where identification needed it; walks in suitable weather; transects 300-3,270 m (mean 1,900 m).",
    samplingProtocolCode = "transect_count", occasionLength = "one transect walk (start and end time in obs_start_time / obs_end_time)",
    surveyEvidence = "sample_table",
    surveyEvidenceNote = "Every walk is a parent event in event.txt (1,725), including 109 with no section event and no occurrence (walks with no butterfly); section events exist only where a butterfly was counted, and every occurrence belongs to a section of a listed walk.",
    responseType = "count", unitKind = "site",
    closure = "open", occasionKind = "time", taxonInclusion = "recorded",
    closureNote = "not assumed: walks every two weeks from March to October follow each species' flight period; period = calendar year",
    geographicCoverage = list(description = "Sierra Nevada National and Natural Park, Granada and Almería, Spain (22 transects, 700-3,100 m a.s.l.)",
                              boundingBox = list(west = bb$w, east = bb$e, south = bb$s, north = bb$n)),
    temporalCoverage = sprintf("%s/%s", min(par$d), max(par$d)),
    coordinatesCoarsened = if (!exact) list(value = TRUE, method = sprintf("0.1 degree cell centres (coarsen_coords) for every transect, because %s (IUCN %s per GBIF) occur in the table; elevations rounded to 100 m, localities not shipped (E7.4)", paste(flagged$scientificName, collapse = ", "), paste(flagged$taxon_iucnCategory, collapse = ", "))) else
      list(value = FALSE, method = sprintf("As published (transect centroids): the IUCN-threatened %s are not in this table (E7.3)", paste(flagged$scientificName, collapse = ", "))),
    notShipped = c(list(`section counts` = "summed over the sections of each walk into y; empty sections have no event and the section count per transect is not stated",
                      `records to genus or family` = "1,239 genus-level and 276 family-level records of butterflies not identified to species; the species zeros at those walks stay as recorded",
                      `infraspecificEpithet` = "Coenonympha pamphilus lyllus (500 records), merged into Coenonympha pamphilus",
                      `recordedBy` = "observer names, replaced by pseudonymous team ids",
                      `footprintWKT` = "route geometry of each transect, finer than the published centroid"),
                    if (exact) list(`threatened species` = sprintf("%s (IUCN %s): in barea_2021_sierranevada_butterfly_count only, whose locations are coarsened", paste(flagged$scientificName, collapse = ", "), paste(flagged$taxon_iucnCategory, collapse = ", ")))
                    else list(unit_locality = "transect place names (E7.4: a coarsened table names no place); in barea_2021_sierran_butterfly_exact_count",
                              `elevation precision` = "unit_minimum/maximumElevationInMeters rounded to 100 m (E7.4)")))
  ds <- write_table(lg, TABLE, dataset, taxa = tx, periods = periods, units = u, script = "data/barea_2021_sierranevada_butterfly_count.R")

  stage_dict_row(TABLE,
    description = paste0(if (exact) sprintf("Precise-location sibling without %s: c", paste(flagged$scientificName, collapse = " and ")) else "C", sprintf("ounts of %d butterfly species on 1,725 Pollard walks of 22 transects (700-3,100 m a.s.l.) of the Sierra Nevada Global-Change Observatory, Spain, March-October 2008-2020, summed over the sections of each walk, with pseudonymous observer team, start and end time, wind, cloud cover and temperature.", nrow(tx))),
    url = "https://doi.org/10.15470/tc3gdq",
    reference = "Barea-Azcón J M (2021). Dataset of butterfly monitoring in Sierra Nevada (Spain). Version 1.2. Sierra Nevada Global-Change Observatory (UGR-JA). Sampling event dataset.",
    doi_data = "10.15470/tc3gdq", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste("Zeros from the walk list (parent events, 109 with no butterfly). Sections summed. Genus- and family-level records not shipped. No walks in 2011.", if (exact) "E7.3 sibling of barea_2021_sierranevada_butterfly_count without the IUCN-threatened species, locations as published." else "Locations coarsened; barea_2021_sierran_butterfly_exact_count has the unthreatened species at published precision."),
    source_via = "GBIF (GBIF Spain IPT)")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
    sampling_protocol = "transect_count", design = sprintf("Multi-season (%d years x up to %d walks per transect)", length(years), max(par$occasion)),
    realm = "Terrestrial", country = "Spain", coordinates = if (!exact) "Coarsened (0.1 deg)" else "As published (transect centroids)",
    notes = "Mountain butterfly monitoring, Pollard walks; counts are per walk, summed over sections.", status = "tagged")
}
emit(TABLE, long, taxa, units, exact = FALSE)
keep <- setdiff(taxa$taxon, flagged$taxon)
emit("barea_2021_sierran_butterfly_exact_count", long[taxon %in% keep], taxa[taxon %in% keep], units_exact, exact = TRUE)
