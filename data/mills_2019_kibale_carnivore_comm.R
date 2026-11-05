#!/usr/bin/env Rscript
# Table:  mills_2019_kibale_carnivore_comm
# Source: Dryad doi:10.5061/dryad.6fq3qv7, version 2 (2019-12-20), CC0 1.0 (as shown on the Dryad page).
#   Mills, D., Do Linh San, E., Robinson, H., Isoke, S., Slotow, R. & Hunter, L. (2019). Data from: Competition
#   and specialization in an African forest carnivore community. Dryad.
# Paper:  Mills, D. et al. (2019). Competition and specialization in an African forest carnivore community.
#         Ecology and Evolution 9(18), 10092-10108, doi:10.1002/ece3.5391 (open access). From the Dryad abstract
#         and usage notes: nine systematic camera-trap surveys in Kibale National Park and Maramagambo Forest,
#         Uganda, 2010-2014; all carnivore detections plus three golden-cat prey species are recorded.
# Data:   camera_trap_detections.csv: one row per detection (26,119): Survey, Station, Stationname, DateTime
#           (dd/mm/yyyy hh:mm), Species / ABBR (and HumSpecies / HABBR, identical to them), Order, Individual (an
#           individual id on 2,809 records), Model, FileName, Action (all NA), baitnum (undocumented).
#         camera station trapfunction.csv: 356 stations x 964 calendar days 2010-10-09..2014-07-04, 1 = camera
#           working that day, 0 = not (or not deployed).
#         camera station placement data.csv: 356 stations: Survey (1-9), Surveyname, Placed / Removed / Active_Days,
#           UTM and decimal-degree coordinates (5 decimals), Altitude (mostly NA), Baited, safety, use, Forest,
#           Logging, Logging.type, CurrentUse, WCSCode (vegetation class), Junction, Trail_aim, Trail_cross,
#           Distance inside PA (m).
#         camera station vegetation data.csv: 147 stations (surveys 2, 6, 7, 8), 38 plot vegetation measures.
#         Checked: station names are unique and agree between placement and trapfunction; every detection's
#           survey matches its station's; 26,105 of 26,119 detections fall on days marked working and 14 on days
#           marked 0; ABBR is one code per species.
# Mapping (community occupancy, daily occasions): unit = camera station (each station belongs to one survey);
#   period = survey 1..9 (chronological by start; Surveyname, year and dates in __periods); occasion = day of the
#   survey (1 = the survey's first calendar day in the trapfunction file), date = that day; y = 1 if the species
#   was photographed at the station that day. Survey evidence: effort_table (trapfunction = 1), plus the 14
#   station-days with a detection that the trapfunction file marks 0 (a photograph shows the camera worked; they
#   ship with obs_trapfunction_zero = 1). taxon = ABBR, the 22 species detected (carnivores including domestic
#   dog and cat, and the three prey species: blue duiker, Weyns's duiker, giant pouched rat); taxonInclusion =
#   target. unit_: survey name, baited, forest, logging, current use, WCS vegetation code, trail junction, trail
#   purpose, distance inside the protected area, and the vegetation measures (unit_veg_*, NA at the 209 stations
#   not measured). Coordinates: golden cat, leopard and lion are IUCN VU, so the decimal degrees are coarsened to
#   the 0.1 degree cell; UTM coordinates are not shipped. IUCN categories for ACON, CADU, CAUR, GSAN and GMAC are
#   set by hand from the IUCN records (iucn_category() returns NA or NE for them; see the code).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mills_2019_kibale_carnivore_comm"
dir <- download_dryad("10.5061/dryad.6fq3qv7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fp <- function(x) file.path(dir, paste0("Mills_UG_2010–2014_", x, ".csv"))
pl <- fread(fp("camera station placement data"), na.strings = c("", "NA"))
tf <- fread(fp("camera station trapfunction"))
dt <- fread(fp("camera_trap_detections"), na.strings = c("", "NA"))
vg <- fread(fp("camera station vegetation data"))

stopifnot(nrow(pl) == 356, nrow(tf) == 356, nrow(dt) == 26119, nrow(vg) == 147,
          identical(pl$Stationname, tf$Stationname), !anyDuplicated(pl$Stationname), !anyDuplicated(pl$Station),
          identical(sort(unique(pl$Survey)), 1:9), all(vg$Station %in% pl$Station),
          all(dt$Stationname %in% pl$Stationname), all(dt$Survey == pl$Survey[match(dt$Stationname, pl$Stationname)]),
          identical(dt$Species, dt$HumSpecies), identical(dt$ABBR, dt$HABBR), all(is.na(dt$Action)),
          dt[, uniqueN(Species), by = ABBR][, all(V1 == 1)], uniqueN(dt$ABBR) == 22)
days <- as.Date(names(tf)[-(1:3)], "%d/%m/%Y"); stopifnot(!anyNA(days), all(diff(days) >= 1))   # calendar days, with gaps between surveys
M <- as.matrix(tf[, -(1:3)]); stopifnot(all(M %in% 0:1), sum(M) == 24489)
dt[, day := as.Date(substr(DateTime, 1, 10), "%d/%m/%Y")]; stopifnot(!anyNA(dt$day))
dt[, worked := M[cbind(match(Stationname, tf$Stationname), match(day, days))]]
stopifnot(sum(dt$worked == 0) == 14)

# the survey set: station-days marked working, plus days with a photograph
sv <- data.table(Stationname = rep(tf$Stationname, times = length(days)), date = rep(days, each = nrow(tf)), f = as.vector(M))
sv <- sv[f == 1 | paste(Stationname, date) %in% dt[, paste(Stationname, day)]]
stopifnot(nrow(sv) == 24489 + uniqueN(dt[worked == 0, paste(Stationname, day)]))
sv[, period := pl$Survey[match(Stationname, pl$Stationname)]]
start <- sv[, .(start = min(date), end = max(date), n_stations = uniqueN(Stationname)), by = period][order(period)]
stopifnot(all(diff(start$start) > 0))   # survey numbers are chronological
sv[, occasion := as.integer(date - start$start[match(period, start$period)]) + 1L]
sv[, obs_trapfunction_zero := as.integer(f == 0)]

det <- unique(dt[, .(Stationname, date = day, taxon = ABBR)])
taxa_codes <- sort(unique(dt$ABBR))
long <- sv[, .(taxon = taxa_codes), by = .(Stationname, date, period, occasion, obs_trapfunction_zero)]
long[, y := 0L][det, y := 1L, on = .(Stationname, date, taxon)]
stopifnot(nrow(long) == nrow(sv) * 22, sum(long$y) == nrow(det))

cc <- coarsen_coords(pl$DD_NS, pl$DD_EW)
stopifnot(all(pl$DD_NS > -1 & pl$DD_NS < 1), all(pl$DD_EW > 29 & pl$DD_EW < 31))
uc <- pl[, .(Stationname, unit_survey_name = Surveyname, unit_baited = as.integer(Baited == "Yes"), unit_forest = Forest,
             unit_logging = Logging, unit_current_use = CurrentUse, unit_wcs_vegetation = WCSCode, unit_trail_junction = Junction,
             unit_trail_purpose = Trail_aim, unit_dist_inside_pa_m = `Distance inside PA`,
             unit_lat = cc$lat, unit_lon = cc$lon, unit_coord_uncertainty_m = cc$uncertainty_m)]
stopifnot(all(pl$Baited %in% c("Yes", "No")))
v <- copy(vg); setnames(v, setdiff(names(v), "Station"), paste0("unit_veg_", gsub("[.]", "_", setdiff(names(v), "Station"))))
v[, Stationname := pl$Stationname[match(Station, pl$Station)]][, Station := NULL]
uc <- merge(uc, v, by = "Stationname", all.x = TRUE, sort = FALSE)
long <- merge(long, uc, by = "Stationname", sort = FALSE)
setnames(long, "Stationname", "unit"); long[, date := format(date)]
long <- order_eco(long)
cat(sprintf("  %d rows, %d station-days, %d detections\n", nrow(long), nrow(sv), sum(long$y)))

sp <- unique(dt[, .(ABBR, Species)])[order(ABBR)]; sp[, sci := gsub("[.]", " ", Species)]
taxa <- make_taxa(sp$ABBR, sp$sci)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# iucn_category() returns NA where GBIF's accepted name differs from the IUCN-assessed name, and NE for Genetta
# maculata (GBIF carries no IUCN record for it); set by hand from the IUCN Red List records:
hand <- c(ACON = "NT",   # Aonyx congicus, assessed as Aonyx congicus (GBIF accepts Aonyx capensis)
          CADU = "LC",   # assessed as Lupulella adusta
          CAUR = "VU",   # assessed as Caracal aurata (GBIF accepts Profelis aurata)
          GSAN = "LC",   # assessed as Herpestes sanguineus
          GMAC = "LC")   # Genetta maculata, assessed by IUCN
stopifnot(all(is.na(taxa[match(c("ACON", "CADU", "CAUR", "GSAN"), taxon), taxon_iucnCategory])),
          taxa[taxon == "GMAC", taxon_iucnCategory] == "NE")
taxa[names(hand), taxon_iucnCategory := hand, on = "taxon"]
print(taxa[, .(taxon, scientificName, taxon_iucnCategory)])
stopifnot(all(taxa[scientificName %in% c("Caracal aurata", "Panthera pardus", "Panthera leo"), taxon_iucnCategory] == "VU"))
periods <- start[, .(period, survey_name = pl$Surveyname[match(period, pl$Survey)], start = format(start), end = format(end), n_stations)]

dataset <- list(
  title = "Daily camera-trap detections of 19 carnivores and three prey species at 356 stations in nine surveys of Kibale National Park and Maramagambo Forest, Uganda, 2010-2014",
  creator = "Mills, David; Do Linh San, Emmanuel; Robinson, Hugh; Isoke, Sam; Slotow, Rob; Hunter, Luke", pubDate = "2019",
  doi = "10.5061/dryad.6fq3qv7", sourceURL = "https://doi.org/10.5061/dryad.6fq3qv7",
  citation = "Mills, D., Do Linh San, E., Robinson, H., Isoke, S., Slotow, R., & Hunter, L. (2019). Data from: Competition and specialization in an African forest carnivore community [Dataset]. Dryad. https://doi.org/10.5061/dryad.6fq3qv7",
  paperDOI = "10.1002/ece3.5391",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Nine systematic camera-trap surveys (2010-2014) in Kibale National Park and Maramagambo Forest, Uganda, recording all carnivores and three prey of the African golden cat, used to test habitat and activity segregation among cats, genets and mongooses with occupancy and co-occupancy models.",
  samplingProtocol = "Camera stations on trails in nine surveys of 24-61 stations each (one baited survey); daily camera function recorded per station; a day is an occasion, scored 1 if the species was photographed.",
  samplingProtocolCode = "camera_trap", occasionLength = "1 day",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time",
  closureNote = "Closure is the user's assumption: surveys run 2-5 months; each station belongs to one survey.",
  taxonInclusion = "target",
  geographicCoverage = "Kibale National Park and Maramagambo Forest (Queen Elizabeth NP), western Uganda", temporalCoverage = "2010-10/2014-07",
  coordinatesCoarsened = list(value = TRUE, method = "station decimal degrees (5 decimals in the source) coarsened to the 0.1 degree cell centre with coarsen_coords(): African golden cat, leopard and lion are IUCN VU; UTM coordinates not shipped"),
  notShipped = list(`GPS_EW, GPS_NS, X, X.1, X.2` = "UTM coordinates (finer than the coarsened cell) and empty columns",
                    `Individual` = "individual ids on 2,809 records (no capture-history design stated)",
                    `baitnum, Model, FileName` = "undocumented or camera-file fields",
                    `Altitude` = "NA at most stations",
                    `safety, use, Logging.type, Trail_cross` = "free-text placement notes overlapping the shipped columns"),
  notes = "14 station-days with a photograph are marked not working in the trapfunction file; they are kept as surveyed and flagged obs_trapfunction_zero = 1. Survey 5 is baited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/mills_2019_kibale_carnivore_comm.R")

stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of 22 species (carnivores including domestic dog and cat, plus blue duiker, Weyns's duiker and giant pouched rat) at 356 stations in nine surveys of Kibale National Park and Maramagambo Forest, Uganda (2010-2014), with station habitat and vegetation covariates; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.6fq3qv7",
  reference = "Mills, D., Do Linh San, E., Robinson, H., Isoke, S., Slotow, R., & Hunter, L. (2019). Competition and specialization in an African forest carnivore community. Ecology and Evolution, 9(18), 10092-10108.",
  doi_paper = "10.1002/ece3.5391", doi_data = "10.5061/dryad.6fq3qv7",
  original_license = "CC0 1.0", derived_license = "CC0-1.0",
  notes = "Survey set from the daily trapfunction table. Coordinates coarsened (golden cat, leopard, lion VU). Fetched as the Dryad version zip.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (nine surveys, stations not shared)", realm = "Terrestrial", country = "UGA",
  coordinates = "Coarsened (0.1 deg)", notes = "Daily occasions; one baited survey; golden cat, leopard, lion VU.", status = "tagged")
