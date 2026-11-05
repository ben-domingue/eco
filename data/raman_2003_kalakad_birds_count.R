#!/usr/bin/env Rscript
# Table:  raman_2003_kalakad_birds_count
# Source: Dryad doi:10.5061/dryad.0gb5mkm3n, version 176731 (version 1, published 2022-05-09), licence
#         CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Raman, T. R. S. "Data on rainforest birds from line transect surveys in the Kalakad -
#         Mundathurai Tiger Reserve, Tamil Nadu, India".
# Paper:  Raman, T. R. S. (2003). Assessment of census techniques for inter-specific comparisons of
#         tropical rainforest bird densities. Ibis 145, 9-21, doi:10.1046/j.1474-919X.2003.00105.x
#         (uses transects T2 and T3; not read: design from the Dryad methods and README). The whole
#         deposit is from Raman's 2001 PhD thesis (Indian Institute of Science).
# Data:   four files.
#   README.TXT                 column definitions (read).
#   01_transectlocations.csv   12 transects (600 m line transects): approximate midpoint latitude and
#                              longitude (WGS 84, 6 decimals), location description.
#   02_transectbirds.csv       4,857 records, one per detection on a transect walk: Transect, Date, Start
#                              and End time of the walk, weather at start and end, time of the record,
#                              old and 2022 eBird India common name, Bird or Mammal, Flock ("detection":
#                              Number individuals counted; "flock": a flock that could not be counted,
#                              Number = 1), Number, perpendicular distance class, heard / seen / flying,
#                              25 m segment, side, remarks, mixed-species flock flag. 104 walks (transect x
#                              date), 15 March 1997 to 27 February 1999; 1 to 30 walks per transect.
#                              The README's distance classes list 30-40 and 40-50; the data use 30-50.
#   03_birdnames.csv           63 bird names with eBird / Clements scientific names; four are not
#                              species (leafbird sp., woodpecker sp., bird sp., and the Green/Greenish
#                              Warbler pair); "Malabar Trogon" is truncated to "Harpac" (Harpactes
#                              fasciatus, the only trogon of the Western Ghats).
#   Design (Dryad methods): 600 m transects walked in about an hour at a slow uniform pace in the first
#   three hours after sunrise; all birds seen (perched or flying under the canopy) or heard recorded
#   with number and perpendicular distance class. Transects lie in mature rainforest, plantations and
#   plantation-forest edges at mid elevation.
#
# Mapping (standard E9 community abundance / N-mixture, responseType count, unitKind site):
#   unit = transect, taxon = 6-letter code from the scientific name, occasion = the walk's order on
#   that transect (by date), no period, y = individuals recorded (sum of Number over the species'
#   records on the walk; an uncountable flock counts 1, so y is a minimum where obs_uncounted_flock = 1);
#   date; obs_start_time; obs_duration_min; obs_weather_start; obs_uncounted_flock (varies across taxa
#   within a walk, E5); unit_location (the deposited description), unit_lat, unit_lon (coarsened).
#   Survey evidence: row_presence. A walk is a survey where the record table has at least one row for it
#   (every walk recorded birds); every identified bird taxon gets a row at every walk.
#   Coordinates: IUCN-threatened species are present in their native range (asserted from
#   taxon_iucnCategory), so the transect midpoints are coarsened to the 0.1 degree cell (E7).
#   Not shipped: mammal records (146: the bird protocol's incidental mammals, no scientific names
#   deposited); unidentified birds (bird sp., woodpecker sp., leafbird sp.; counted below); the
#   per-record distance class, heard/seen/flying code, segment, side, remarks and mixed-flock flag
#   (per detection, not per survey taxon); end-of-walk weather; exact coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "raman_2003_kalakad_birds_count"
dir <- download_dryad("doi:10.5061/dryad.0gb5mkm3n", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "176731"), length(list.files(dir)) == 4L)
loc <- fread(file.path(dir, "01_transectlocations.csv"))
d   <- fread(file.path(dir, "02_transectbirds.csv"), na.strings = c("NA", ""))
nm  <- fread(file.path(dir, "03_birdnames.csv"))
stopifnot(nrow(loc) == 12L, !anyDuplicated(loc$Transect), nrow(d) == 4857L, all(d$Transect %in% loc$Transect),
          identical(sort(unique(d$BirdMamm)), c("Bird", "Mammal")), d[BirdMamm == "Mammal", .N] == 146L,
          all(d$Flock %in% c("detection", "flock")), d[, all(Number >= 1L)], d[Flock == "flock", all(Number == 1L)],
          nrow(nm) == 63L, !anyDuplicated(nm$Species), all(d[BirdMamm == "Bird", Species] %in% nm$Species))
d[, dt := as.IDate(Date, "%d %b %Y")]
stopifnot(!anyNA(d$dt), min(d$dt) == as.IDate("1997-03-15"), max(d$dt) == as.IDate("1999-02-27"))
walks <- unique(d[, .(unit = Transect, dt, StartTime, EndTime, Startweather)])
stopifnot(nrow(walks) == 104L, !anyDuplicated(walks[, .(unit, dt)]))
setorder(walks, unit, dt)
walks[, occasion := seq_len(.N), by = unit]
walks[, obs_duration_min := as.integer(difftime(as.POSIXct(EndTime, format = "%H:%M", tz = "UTC"),
                                                as.POSIXct(StartTime, format = "%H:%M", tz = "UTC"), units = "mins"))]
stopifnot(all(walks$obs_duration_min > 0), max(walks$occasion) == 30L)

nm[ScientificName == "Harpac", ScientificName := "Harpactes fasciatus"]
nonsp <- c("leafbird sp.", "woodpecker sp.", "bird sp.")
stopifnot(all(nonsp %in% nm$Species), nm[Species == "Green/Greenish Warbler", ScientificName] == "Phylloscopus nitidus/trochiloides")
b <- d[BirdMamm == "Bird"]
unid <- b[Species %in% nonsp]
b <- b[!Species %in% nonsp]
sp <- nm[!Species %in% nonsp, .(com = Species, sci = ScientificName)]
sp[, taxon := fifelse(com == "Green/Greenish Warbler", "PHYNTR",
                      vapply(strsplit(sci, " "), function(w) toupper(paste0(substr(w[1], 1, 3), substr(w[2], 1, 3))), ""))]
stopifnot(nrow(sp) == 60L, !anyDuplicated(sp$taxon), all(b$Species %in% sp$com))
rec <- b[, .(y = sum(Number), fl = as.integer(any(Flock == "flock"))), by = .(unit = Transect, dt, com = Species)]
rec[, taxon := sp$taxon[match(com, sp$com)]]

long <- CJ(k = seq_len(nrow(walks)), taxon = sp$taxon)
long <- cbind(walks[long$k], taxon = long$taxon)
long <- merge(long, rec[, .(unit, dt, taxon, y, fl)], by = c("unit", "dt", "taxon"), all.x = TRUE)
long[is.na(y), `:=`(y = 0L, fl = 0L)]
cc <- coarsen_coords(loc$LatitudeN, loc$LongitudeE)
uc <- data.table(unit = loc$Transect, unit_location = loc$LocationDetails, unit_lat = cc$lat, unit_lon = cc$lon)
long <- merge(long, uc, by = "unit")
long <- order_eco(long[, .(unit, taxon, y = as.integer(y), occasion, date = as.character(dt), obs_start_time = StartTime,
                           obs_duration_min, obs_weather_start = Startweather, obs_uncounted_flock = fl,
                           unit_location, unit_lat, unit_lon)])
stopifnot(nrow(long) == 104L * 60L, sum(long$y) == sum(b$Number), long[y > 0, .N] == nrow(rec),
          all(loc$LatitudeN > 8.4 & loc$LatitudeN < 8.9), all(loc$LongitudeE > 77.1 & loc$LongitudeE < 77.6))

taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$com,
                  taxonRank = fifelse(sp$taxon == "PHYNTR", "species complex", "species"),
                  lookupName = fifelse(sp$taxon == "PHYNTR", "Phylloscopus", sp$sci), allow_higher = "PHYNTR")
taxa[taxon == "PHYNTR", taxonRank := "species complex"]
sp_rows <- taxa$taxonRank == "species"
taxa[sp_rows, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
same_name <- function(id, nm) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- paste(head(strsplit(r$scientificName %||% "", " ")[[1]], 2), collapse = " ")
  if (identical(w, nm)) r$code %||% NA_character_ else NA_character_
}
# NA = GBIF's accepted name differs from the IUCN record's; where the record carries the deposit's own
# name it is the same species and its category is taken (checked 2026-11-05)
taxa[sp_rows & is.na(taxon_iucnCategory), taxon_iucnCategory := mapply(same_name, taxonID, scientificName)]
threat <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), scientificName]
stopifnot(length(threat) >= 1L)

dataset <- list(
  title = "Repeated line-transect counts of 60 rainforest bird taxa on 12 transects in Kalakad-Mundanthurai Tiger Reserve, Western Ghats, India, 1997-1999",
  creator = "Raman, T. R. Shankar",
  pubDate = "2022", doi = "10.5061/dryad.0gb5mkm3n", sourceURL = "https://doi.org/10.5061/dryad.0gb5mkm3n",
  citation = "Raman, T. R. S. (2022). Data on rainforest birds from line transect surveys in the Kalakad - Mundathurai Tiger Reserve, Tamil Nadu, India [Dataset]. Dryad. https://doi.org/10.5061/dryad.0gb5mkm3n",
  paperDOI = "10.1046/j.1474-919X.2003.00105.x",
  abstract = "Bird detections from 104 walks of 600 m line transects in mid-elevation rainforest, plantations and forest edges of Kalakad-Mundanthurai Tiger Reserve, southern Western Ghats, March 1997 to February 1999, collected for T. R. S. Raman's doctoral research on rainforest bird communities; transects T2 and T3 were used to compare census techniques (Raman 2003, Ibis).",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "600 m line transects walked in about one hour at a slow, uniform pace within three hours after sunrise; every bird seen (perched or flying under the canopy) or heard recorded with its number (an uncountable flock as 1) and perpendicular distance class (0-5 to 50-100 m).",
  samplingProtocolCode = "line_transect", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "walks spread over two years (March 1997 to February 1999); no within-season grouping is given",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "1997-03/1999-02",
  geographicCoverage = "Kalakad-Mundanthurai Tiger Reserve (Sengaltheri, Kakachi, Neterikal, Kannikatti areas), Tamil Nadu, India; transect midpoints coarsened to 0.1 degree",
  coordinatesCoarsened = list(value = TRUE, method = paste0("approximate transect midpoints (WGS 84, 6 decimals) coarsened to the 0.1 degree cell centre with coarsen_coords(): IUCN threatened species present in their native range (", paste(sort(threat), collapse = ", "), ")")),
  notes = "y is the sum of Number over a taxon's records on the walk; a flock that could not be counted is recorded as 1 (obs_uncounted_flock = 1), so y is a lower bound there. Walks per transect range from 1 (T13, T15, T16) to 30 (T2, T3). PHYNTR is the Green/Greenish Warbler pair (Phylloscopus nitidus / trochiloides), not separated in the field. The Malabar Trogon's scientific name is truncated in the deposit ('Harpac') and is Harpactes fasciatus. Common names are eBird India 2022 (vernacularName). taxon_iucnCategory from GBIF's IUCN record.",
  notShipped = list(mammals = "146 mammal records (squirrels, primates, mouse deer, wild boar) recorded incidentally, without scientific names",
                    unidentified = sprintf("%d records of birds not identified to species or species pair (bird sp., woodpecker sp., leafbird sp.)", nrow(unid)),
                    detection_details = "per-record distance class, heard/seen/flying code, 25 m segment, side, remarks, mixed-flock flag",
                    end_weather = "weather at the end of the walk",
                    exact_coordinates = "coarsened to 0.1 degree (threatened species present)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/raman_2003_kalakad_birds_count.R")
stage_dict_row(TABLE,
  description = "Repeated counts of 60 bird taxa from 104 walks of 12 line transects (600 m) in rainforest, plantations and edges of Kalakad-Mundanthurai Tiger Reserve, Western Ghats, India, 1997-1999, with walk times and weather; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.0gb5mkm3n",
  reference = "Raman, T. R. S. (2003). Assessment of census techniques for inter-specific comparisons of tropical rainforest bird densities. Ibis, 145, 9-21.",
  doi_paper = "10.1046/j.1474-919X.2003.00105.x", doi_data = "10.5061/dryad.0gb5mkm3n",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. Birds only (mammals and unidentified birds dropped); uncountable flocks flagged; coordinates coarsened.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community counts, single season)",
  sampling_protocol = "line_transect", design = "Single-season (1-30 walks per transect over two years)",
  realm = "Terrestrial", country = "IND", coordinates = "Coarsened (0.1 deg)",
  notes = "Western Ghats rainforest birds; very unbalanced walks per transect; distance classes not shipped.")
