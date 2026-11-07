#!/usr/bin/env Rscript
# Table:  obrist_2024_gooseisland_birds_count
# WITHDRAWN 2026-11-06 (care_review, #150). Removed from the current release pending
#   consultation with the originators; may be reinstated. Kept so it can be rebuilt; its
#   tag status is do_not_publish, so the uploader refuses it. Why, and how to reinstate:
#   notes/decisions/care_e7_screen_held.md and releases/withdrawals.csv.
# Source: Zenodo 10.5281/zenodo.11518182 (CC BY 4.0 as shown on the record), published 2024-06-07.
#   Obrist, D., Field, R. & Reynolds, J. (2024). Avian Point Count Surveys from Yáláƛi (Goose
#   Island) Archipelago, British Columbia, Canada in 2011. Zenodo.
# Paper:  Obrist, D.S., Pendray, J.E., Field, R.D., Housty, W.G., Reynolds, J.D. et al. (2024).
#   Comparing historical and contemporary observations of avian fauna on the Yáláƛi (Goose Island)
#   Archipelago, British Columbia, Canada. Ecology and Evolution 14(12): e70464.
#   doi:10.1002/ece3.70464 (Nature Note; compares 2011 surveys with Guiguet 1953).
# Data:   GooseIslandsBirds_Data.xlsx, six sheets. "Raw Point Counts": 1,802 rows, one per
#         detection, with year (2011), date (Excel serial in the 1904 date system: 39213 =
#         2011-05-12, matching day.julian 132), survey (1-3), time.hour (start time as a day
#         fraction; a few rows carry a +2, +3, ... fill-down offset), temp.c, weather, surveyor,
#         island, point (island prefix + habitat code + number, e.g. gocx01; "la*" points are
#         on Goose Island), species (4-letter alpha code), atlascode (BC Breeding Bird Atlas
#         evidence code), distance.m (estimated, metres; 210 rows free text or "n/a"),
#         time.survey (minute 1-10 within the 10-minute count; 262 "n/a"; "on arrival",
#         "after survey", "~1 hour ago", "on departure", 12, 15 and a few mis-entered clock
#         times mark detections outside the count). "Summarized Point Counts": per species x
#         survey totals ("number"), 204 cells, plus casual observations and the authors' max
#         across surveys. "Locations": 52 rows (island, point without prefix, minutes of
#         latitude N of 51 deg and of longitude W of 128 deg, notes); goose cx02 and cx03 appear
#         twice (one cx02 row empty; the two cx03 rows differ by 0.004 min), the second block
#         of goose rows (lat 57.x min) is the "la*" points. "Casual Observations" and
#         "Relative Abundance Comparisons" are not survey data. "Metadata" defines columns.
#         Protocol (Zenodo description): 50 points in the four Guiguet (1953) habitat types
#         (climax forest cx, ecotone eco, muskeg mu, meadow me) on six islands, each surveyed
#         three times between 12 May and 2 June 2011, one observer, 10 minutes, all birds seen or
#         heard within 100 m, minute-long intervals, within five hours of sunrise (Huff et al.
#         2000). Every one of the 150 point x survey combinations has detections.
#
# Mapping (standard section 3.2, N-mixture community counts built from individual records):
#   unit = point (50), occasion = survey 1-3, taxon = alpha code (40 species), y = number of
#   detections of the species on that point count that fall inside the authors' own rule,
#   minute 1-10 and distance <= 100 m: this rule reproduces every one of the 204 "number"
#   cells of the Summarized Point Counts sheet exactly (asserted), so y is the authors' count.
#   Detections outside the 10 minutes, beyond 100 m or with no usable distance are
#   not shipped and are listed in notShipped. Community rule: a row for every species at every
#   point count. Survey evidence: row_presence, which here equals the stated design (50 points
#   x 3 surveys, all 150 present). taxonInclusion = recorded (v1.1): the 10 species whose
#   detections all fall outside the rule are not listed (notShipped), leaving 40. date = ISO date (1904-system serial, checked against
#   year + day.julian); observer = surveyor; obs_start_time (HH:MM), obs_temp_c, obs_weather
#   per count; unit_island, unit_habitat (from the point code), unit_decimalLatitude /
#   unit_decimalLongitude from Locations (51 deg + min/60, -(128 deg + min/60)), as published,
#   and __units with the Locations notes. No taxon is IUCN CR/EN/VU (olive-sided flycatcher is
#   NT), so coordinates are kept. One period (2011 breeding season).
#   Quirks: SASP is used for Savannah Sparrow (the standard code is SAVS, which the Relative
#   Abundance sheet uses); sneco01 is labelled snipe (Locations and 58 rows) and gull (2 rows),
#   kept as snipe; gosling cx04's latitude is published as 56.705 min with the note "Journal
#   says 55.705", shipped as published with the note in __units.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "obrist_2024_gooseisland_birds_count"
f <- download_cached("https://zenodo.org/records/11518182/files/GooseIslandsBirds_Data.xlsx?download=1", TABLE,
                     filename = "GooseIslandsBirds_Data.xlsx")
stopifnot(setequal(excel_sheets(f), c("Relative Abundance Comparisons", "Summarized Point Counts", "Raw Point Counts",
                                      "Casual Observations", "Locations", "Metadata")))
r <- as.data.table(read_excel(f, sheet = "Raw Point Counts", col_types = "text"))
stopifnot(identical(names(r), c("year", "date", "day.julian", "survey", "time.hour", "temp.c", "weather", "surveyor",
                                "island", "point", "species", "atlascode", "distance.m", "time.survey", "notes")),
          nrow(r) == 1802, all(r$year == "2011"), all(r$survey %in% c("1", "2", "3")), !anyNA(r$point), !anyNA(r$species),
          uniqueN(r$point) == 50, uniqueN(r$species) == 50, all(nchar(r$species) == 4))

# dates: the serials are in Excel's 1904 system; they must agree with year + day.julian
r[, date_iso := as.Date(as.numeric(date), origin = "1904-01-01")]
stopifnot(all(format(r$date_iso, "%Y") == "2011"), all(as.integer(format(r$date_iso, "%j")) == as.integer(r$day.julian)),
          min(r$date_iso) == as.Date("2011-05-12"), max(r$date_iso) == as.Date("2011-06-02"))
# per count: date, temperature, weather and surveyor are constant; start time after dropping the fill-down offset
r[, start_min := round((as.numeric(time.hour) %% 1) * 1440)]
pc <- unique(r[, .(point, survey, date_iso, temp.c, weather, surveyor, start_min)])
stopifnot(nrow(pc) == 150, !anyDuplicated(pc[, .(point, survey)]), all(table(pc$point) == 3), all(pc$start_min >= 5 * 60), all(pc$start_min <= 11 * 60))
pc[, occasion := as.integer(survey)]
stopifnot(all(pc[, all(diff(as.numeric(date_iso[order(occasion)])) > 0), by = point]$V1))   # surveys 1 < 2 < 3 in time at every point

# the authors' counting rule: minute 1-10 of the count and distance <= 100 m
r[, dist := suppressWarnings(as.numeric(distance.m))]
r[, counted := time.survey %in% as.character(1:10) & !is.na(dist) & dist <= 100]
s <- as.data.table(read_excel(f, sheet = "Summarized Point Counts", col_types = "text"))[, .(species, survey, number = as.integer(number))]
stopifnot(nrow(s) == 204, uniqueN(s$species) == 68, all(r$species %in% s$species), sum(r$counted) == sum(s$number),
          all(s[!species %in% r$species, number] == 0))   # 18 species seen only casually have 0 on every survey
N_IN <- sum(r$counted); N_OUT <- sum(!r$counted)
chk <- merge(s, r[counted == TRUE, .(n = .N), by = .(species, survey)], by = c("species", "survey"), all.x = TRUE)
chk[is.na(n), n := 0L]
stopifnot(all(chk$number == chk$n))      # 204 of 204 cells reproduced
cat(sprintf("  %d detections, %d inside the authors' rule (minute 1-10, <= 100 m), %d outside; 204/204 summarized cells reproduced\n", nrow(r), N_IN, N_OUT))

# taxa: alpha codes; 17 of the 50 are in data/aux/bird_alpha_codes.csv, the rest given here (IBP-AOS list)
species <- sort(unique(r$species))
# taxonInclusion = recorded (E10): a species detected only outside the counting rule is not
# recorded by this table's surveys and is not listed
outside_only <- setdiff(species, r[counted == TRUE, unique(species)])
stopifnot(length(outside_only) == 10)
alpha <- fread(file.path(ECO_ROOT, "data", "aux", "bird_alpha_codes.csv"))[, .(code, commonName, scientificName)]
extra <- fread(text = '
code,commonName,scientificName
BAEA,Bald Eagle,Haliaeetus leucocephalus
BLOY,Black Oystercatcher,Haematopus bachmani
BLTU,Black Turnstone,Arenaria melanocephala
CAGO,Canada Goose,Branta canadensis
CBCH,Chestnut-backed Chickadee,Poecile rufescens
CEWA,Cedar Waxwing,Bombycilla cedrorum
COLO,Common Loon,Gavia immer
COME,Common Merganser,Mergus merganser
DUNL,Dunlin,Calidris alpina
FOSP,Fox Sparrow,Passerella iliaca
GCKI,Golden-crowned Kinglet,Regulus satrapa
GCSP,Golden-crowned Sparrow,Zonotrichia atricapilla
GRYE,Greater Yellowlegs,Tringa melanoleuca
GWGU,Glaucous-winged Gull,Larus glaucescens
LISP,Lincoln\'s Sparrow,Melospiza lincolnii
NOCR,Northwestern Crow,Corvus caurinus
OCWA,Orange-crowned Warbler,Leiothlypis celata
PAWR,Pacific Wren,Troglodytes pacificus
PEFA,Peregrine Falcon,Falco peregrinus
PGPL,Pacific Golden-Plover,Pluvialis fulva
PSFL,Pacific-slope Flycatcher,Empidonax difficilis
RBSA,Red-breasted Sapsucker,Sphyrapicus ruber
RECR,Red Crossbill,Loxia curvirostra
RUHU,Rufous Hummingbird,Selasphorus rufus
SACR,Sandhill Crane,Antigone canadensis
SAND,Sanderling,Calidris alba
SASP,Savannah Sparrow,Passerculus sandwichensis
SEPL,Semipalmated Plover,Charadrius semipalmatus
SPSA,Spotted Sandpiper,Actitis macularius
TOWA,Townsend\'s Warbler,Setophaga townsendi
VATH,Varied Thrush,Ixoreus naevius
WESA,Western Sandpiper,Calidris mauri
WHIM,Whimbrel,Numenius phaeopus
')
stopifnot(!any(extra$code %in% alpha$code), nrow(extra) == 33)
alpha <- rbind(alpha[code %in% species], extra)
stopifnot(setequal(alpha$code, species), !anyDuplicated(alpha$code))
alpha <- alpha[match(species, code)]
species <- setdiff(species, outside_only); alpha <- alpha[code %in% species]
taxa <- make_taxa(species, alpha$scientificName, vernacularName = alpha$commonName)
stopifnot(!anyNA(taxa$taxonID))

# units: island, habitat from the point code, coordinates from Locations (minutes N of 51 / W of 128)
loc <- as.data.table(read_excel(f, sheet = "Locations", col_types = "text"))
setnames(loc, c("island", "suffix", "lat_min", "lon_min", "note"))
stopifnot(nrow(loc) == 52)
loc[, `:=`(lat_min = suppressWarnings(as.numeric(lat_min)), lon_min = suppressWarnings(as.numeric(lon_min)))]
loc <- loc[!is.na(lat_min)]                                   # goose cx02's empty row
loc <- loc[!duplicated(loc[, .(island, suffix)])]             # goose cx03: two rows 0.004 min apart, first kept
stopifnot(nrow(loc) == 50, all(loc$lat_min > 54.9 & loc$lat_min < 57.6), all(loc$lon_min > 25.6 & loc$lon_min < 28.9))
pts <- unique(r[, .(point, island)])
pts <- pts[!(point == "sneco01" & island == "gull")]           # 2 of 60 rows label sneco01 "gull"; Locations and 58 rows say snipe
stopifnot(nrow(pts) == 50, !anyDuplicated(pts$point))
pts[, suffix := sub("^[a-z]{2}", "", point)]
pts[, habitat := c(cx = "climax forest", eco = "ecotone", mu = "muskeg", me = "meadow")[sub("[0-9]+$", "", suffix)]]
stopifnot(!anyNA(pts$habitat))
units <- merge(pts, loc, by = c("island", "suffix"), all.x = TRUE)
stopifnot(nrow(units) == 50, !anyNA(units$lat_min))
units <- units[, .(unit = point, island, habitat, decimalLatitude = round(51 + lat_min / 60, 6),
                   decimalLongitude = round(-(128 + lon_min / 60), 6), source_note = note)][order(unit)]
cat(sprintf("  50 points on %d islands; habitats: %s\n", uniqueN(units$island), paste(names(table(units$habitat)), table(units$habitat), collapse = ", ")))

# long table: every species at every point count
counts <- r[counted == TRUE, .(y = .N), by = .(unit = point, occasion = as.integer(survey), taxon = species)]
long <- CJ(unit = units$unit, occasion = 1:3, taxon = species)
long <- merge(long, counts, by = c("unit", "occasion", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, pc[, .(unit = point, occasion, date = format(date_iso), observer = surveyor,
                           obs_start_time = sprintf("%02d:%02d", start_min %/% 60, start_min %% 60),
                           obs_temp_c = as.numeric(temp.c), obs_weather = weather)], by = c("unit", "occasion"))
long <- merge(long, units[, .(unit, unit_island = island, unit_habitat = habitat,
                              unit_decimalLatitude = decimalLatitude, unit_decimalLongitude = decimalLongitude)], by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 150 * 40, sum(long$y) == N_IN, uniqueN(long$unit) == 50, uniqueN(long$taxon) == 40, !anyNA(long$y),
          all(long[, sum(y), by = taxon]$V1 > 0))

dataset <- list(
  title = "Point counts of 40 bird species at 50 points on six islands of the Yalalii (Goose Island) Archipelago, British Columbia, three surveys in May-June 2011",
  creator = "Obrist, Debora; Field, Rachel; Reynolds, John",
  pubDate = "2024", doi = "10.5281/zenodo.11518182", sourceURL = "https://doi.org/10.5281/zenodo.11518182",
  citation = "Obrist, D., Field, R. & Reynolds, J. (2024). Avian Point Count Surveys from Yalalii (Goose Island) Archipelago, British Columbia, Canada in 2011. Zenodo. https://doi.org/10.5281/zenodo.11518182. Paper: Obrist, D.S. et al. (2024). Comparing historical and contemporary observations of avian fauna on the Yalalii (Goose Island) Archipelago, British Columbia, Canada. Ecology and Evolution 14(12): e70464, https://doi.org/10.1002/ece3.70464",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Ten-minute point counts by Simon Fraser University researchers at 50 points in the four Guiguet (1953) habitat types (climax forest, ecotone, muskeg, meadow) on Goose, Gosling, Duck, Snipe, Swan and Gull Islands, Yalalii (Goose Island) Archipelago, British Columbia, each surveyed three times between 12 May and 2 June 2011 within five hours of sunrise. y is the number of individuals of a species detected within the 10 minutes and within 100 m, the authors' own counting rule, which reproduces every species x survey total in the deposit's summary sheet. The paper compares these counts with Guiguet's 1948 observations.",
  samplingProtocol = "10-minute point counts, one observer, all birds seen or heard within 100 m, detections assigned to minute-long intervals with estimated distance; three surveys per point in one breeding season (Huff et al. 2000 protocol).",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion (three surveys within one breeding season)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Yalalii (Goose Island) Archipelago, Heiltsuk territory, central coast of British Columbia, Canada; 50 points on six islands, coordinates as published",
                            westBoundingCoordinate = min(units$decimalLongitude), eastBoundingCoordinate = max(units$decimalLongitude),
                            southBoundingCoordinate = min(units$decimalLatitude), northBoundingCoordinate = max(units$decimalLatitude)),
  temporalCoverage = "2011-05-12/2011-06-02",
  crs = "WGS84 assumed (Locations sheet: minutes of latitude N of 51 deg and of longitude W of 128 deg, three decimals)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published; no taxon is IUCN CR, EN or VU (olive-sided flycatcher is NT)"),
  surveyEvidenceNote = "The raw sheet has one row per detection and no separate visit list, but the record states every point was surveyed three times and all 150 point x survey combinations carry detections, so the row-presence survey set equals the stated design.",
  notes = "y follows the authors' rule (minute 1-10 of the count, estimated distance <= 100 m), which reproduces all 204 species x survey totals of the Summarized Point Counts sheet. Dates are Excel 1904-system serials (checked against day.julian). SASP is the deposit's code for Savannah Sparrow (standard SAVS). sneco01 is labelled snipe in Locations and 58 of 60 rows, gull in 2; kept as snipe. Goose cx03 has two Locations rows 0.004 arc-minutes apart (first kept); gosling cx04 is published with latitude 56.705 min and the note 'Journal says 55.705' (shipped as published, note in __units). Start time is the fractional part of time.hour (a few rows carry an integer fill-down offset).",
  notShipped = list(`detections outside the authors' rule` = paste0(N_OUT, " of 1,802 rows: time.survey outside minutes 1-10 (on arrival, after survey, ~1 hour ago, on departure, minute 12 or 15, unrecorded 'n/a', or a clock time) or distance beyond 100 m, free text or 'n/a'; the deposit's metadata treats these as casual observations"),
                    `Casual Observations sheet` = "535 incidental records without a survey set",
                    `Relative Abundance Comparisons` = "the paper's 1948 vs 2011 totals (derived)",
                    `species recorded only outside the rule` = paste0(length(outside_only), " species (", paste(outside_only, collapse = ", "), ") have detections only outside the counting rule, so this table's surveys did not record them (taxonInclusion = recorded)"),
                    atlascode = "BC Breeding Bird Atlas evidence code per detection (per-detection, not per count)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, units = units, script = "data/obrist_2024_gooseisland_birds_count.R")

stage_dict_row(TABLE,
  description = "Counts of 40 bird species on 150 ten-minute, 100 m point counts (50 points x 3 surveys, 12 May-2 June 2011) in four habitat types on six islands of the Yalalii (Goose Island) Archipelago, British Columbia, built from the deposited per-detection records under the authors' own counting rule; start time, temperature, weather, observer and point coordinates.",
  url = "https://doi.org/10.5281/zenodo.11518182",
  reference = "Obrist, D.S., Pendray, J.E., Field, R.D., Housty, W.G., Reynolds, J.D. et al. (2024). Comparing historical and contemporary observations of avian fauna on the Yalalii (Goose Island) Archipelago, British Columbia, Canada. Ecology and Evolution 14(12): e70464.",
  doi_paper = "10.1002/ece3.70464", doi_data = "10.5281/zenodo.11518182",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Per-detection deposit; y = detections in minutes 1-10 within 100 m (reproduces the authors' summary sheet). Detections outside that rule not shipped. Coordinates as published (no flagged taxa).",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species)",
  sampling_protocol = "point_count", design = "Single-season (3 surveys)", realm = "Terrestrial", country = "CAN",
  coordinates = "As published", notes = "Island archipelago, four habitat types; 2011 resurvey of Guiguet's 1948 observations.",
  status = "tagged; do_not_publish: care_review (#150), withdrawn 2026-11-06")
