#!/usr/bin/env Rscript
# Table:  finnegan_2024_afognak_deer_scr  (spatial capture-recapture of individually identified
#         Sitka black-tailed deer bucks at 26 cameras, 1 September - 2 October 2022,
#         Afognak Island, Alaska)
# Source: Dryad doi:10.5061/dryad.brv15dvk2 (CC0 1.0), version 325665 (published 2024-11-01).
#   Finnegan, S. (2024). Sitka Black-tailed Deer Camera trap data for density estimation from
#   Afognak Island, Alaska. Dryad.
#   Code: Zenodo doi:10.5281/zenodo.13936331 (supplemental, not read).
# Paper:  Finnegan, S. P., Hinojo, A., Monod, S., Wall, W. A., Olsen, P. & Allen, M. L. (2024).
#         A comparison of thermal drones and camera trap population estimates for Sitka
#         black-tailed deer in Alaska. Wildlife Biology, e01360. doi:10.1002/wlb3.01360
#         (title checked on Crossref; not read). Design from the Dryad methods text: 26 unbaited cameras about
#         400 m apart along inactive logging roads, active 1 September - 6 October 2022, 24 h a
#         day; independent events at a 6-minute cutoff; bucks identified individually from
#         antlers and natural marks by one observer; camera SCR compared with thermal-drone
#         counts.
# Data:   README.md defines the four csvs. Bucks_capture_history.csv (117 rows): Site (camera),
#         Time (YYYY-MM-DD HH:MM), Deer_Name (buck id M1..M24; 23 ids, no M10).
#         Trap_nights.csv: Site x Night1..Night32, 1 = camera worked that night, 0 = not; 25
#         cameras worked all 32 nights, WAW24 nights 1-18 only (832 - 14 = 818 camera-nights).
#         Camera_locations_.csv: Site, x, y (easting, northing; no CRS given; the range places
#         the cameras on Afognak Island at about 58.3 N, 152.3 W in UTM zone 5N).
#         Bucks_does_fawns.csv (600 rows): every deer event with Sex_age (Male, Female, Mother
#         with Young), Group Size and Deer_ID (buck id, UM/UF = unidentified male/female, F1..
#         for a few females), plus an empty column and a header-only legend column.
#         Night k is read as calendar day 2022-09-01 + (k - 1): the 117 captures fall on days 1
#         to 32 and every one is on a night its camera worked (asserted); WAW24's last capture
#         is on day 3, before its cut-off.
# Mapping (standard E1-E6; E9 experimental: SCR, closed population): unit = buck (deposited id),
#   taxon = ODOHSI (Odocoileus hemionus sitkensis), trap = camera (WAW1..WAW26), occasion =
#   night 1..32, date = the calendar day, y = 1 if the buck was photographed at that camera
#   that day, else 0; y_raw = the number of independent events (6-minute cutoff) behind y
#   (104 buck-camera-days with a detection: 93 with one event, 9 with two, 2 with three). Survey set = effort_table (Trap_nights.csv): every
#   buck carries every worked camera-night (23 x 818 = 18,814 rows). __traps: camera, x, y
#   (UTM, as published), n_nights_operating. Deer are not a flagged taxon; coordinates kept.
#   NOT shipped: Bucks_does_fawns.csv (an event list of unmarked does, fawns and unidentified
#   bucks with group sizes; it is not a per-survey record of the identified bucks and its 121
#   identified-buck events differ from the 117 in the capture history the authors deposited
#   for SCR), the drone counts (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "finnegan_2024_afognak_deer_scr"
SCRIPT <- "data/finnegan_2024_afognak_deer_scr.R"
dir <- download_dryad("10.5061/dryad.brv15dvk2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("Bucks_capture_history.csv", "Bucks_does_fawns.csv", "Camera_locations_.csv",
                                      "README.md", "Trap_nights.csv")))

cp <- fread(file.path(dir, "Bucks_capture_history.csv"))
tn <- fread(file.path(dir, "Trap_nights.csv")); setnames(tn, trimws(names(tn)))
lc <- fread(file.path(dir, "Camera_locations_.csv")); setnames(lc, c("Site", "x", "y"))
for (d in list(tn, lc)) d[, Site := trimws(Site)]
stopifnot(identical(names(cp), c("Site", "Time", "Deer_Name")), nrow(cp) == 117,
          identical(names(tn), c("Site", paste0("Night", 1:32))), nrow(tn) == 26, nrow(lc) == 26,
          setequal(tn$Site, lc$Site), setequal(tn$Site, paste0("WAW", 1:26)),
          all(unlist(tn[, -1]) %in% 0:1), all(cp$Site %in% tn$Site),
          uniqueN(cp$Deer_Name) == 23, all(grepl("^M[0-9]+$", cp$Deer_Name)),
          all(lc$x > 538e3 & lc$x < 541e3), all(lc$y > 6464e3 & lc$y < 6467e3))
op <- melt(tn, id.vars = "Site", variable.name = "night", value.name = "on")
op[, occasion := as.integer(sub("Night", "", night))]
nights <- op[, sum(on), by = Site]
stopifnot(nights[V1 < 32, Site] == "WAW24", nights[Site == "WAW24", V1] == 18,
          op[Site == "WAW24", identical(on, c(rep(1L, 18), rep(0L, 14)))], sum(op$on) == 818)
op <- op[on == 1, .(trap = Site, occasion)]

cp[, dt := as.POSIXct(Time, format = "%Y-%m-%d %H:%M", tz = "UTC")]
cp[, occasion := as.integer(as.IDate(dt) - as.IDate("2022-09-01")) + 1L]
stopifnot(!anyNA(cp$dt), all(cp$occasion %in% 1:32), min(cp$occasion) == 1, max(cp$occasion) == 32,
          nrow(cp[!op, on = .(Site = trap, occasion)]) == 0)            # every capture on a worked camera-night
ev <- cp[, .(y_raw = .N), by = .(unit = Deer_Name, trap = Site, occasion)]
stopifnot(sum(ev$y_raw) == 117, nrow(ev) == 104, ev[, .N, by = y_raw][order(y_raw), N] == c(93L, 9L, 2L))

long <- CJ(unit = sort(unique(cp$Deer_Name)), k = seq_len(nrow(op)))
long <- cbind(long[, .(unit)], op[long$k])
long <- merge(long, ev, by = c("unit", "trap", "occasion"), all.x = TRUE)
long[is.na(y_raw), y_raw := 0L]
long <- long[, .(unit, taxon = "ODOHSI", y = as.integer(y_raw > 0), y_raw, trap, occasion,
                 date = format(as.IDate("2022-09-01") + occasion - 1L))]
long <- order_eco(long)
stopifnot(nrow(long) == 23 * 818, sum(long$y) == 104, sum(long$y_raw) == 117)

traps <- lc[, .(trap = Site, x = as.numeric(x), y = as.numeric(y))][nights, on = .(trap = Site)][
  , .(trap, x, y, n_nights_operating = as.integer(V1))][order(as.integer(sub("WAW", "", trap)))]
taxa <- make_taxa("ODOHSI", "Odocoileus hemionus sitkensis", vernacularName = "Sitka black-tailed deer",
                  taxonRank = "subspecies", allow_higher = character())

dataset <- list(
  title = "Spatial capture-recapture of 23 Sitka black-tailed deer bucks at 26 cameras over 32 nights, Afognak Island, Alaska, September-October 2022",
  creator = "Finnegan, Shannon",
  pubDate = "2024", doi = "10.5061/dryad.brv15dvk2", sourceURL = "https://doi.org/10.5061/dryad.brv15dvk2",
  paperDOI = "10.1002/wlb3.01360",
  citation = "Finnegan, S. (2024). Sitka Black-tailed Deer Camera trap data for density estimation from Afognak Island, Alaska [Data set]. Dryad. https://doi.org/10.5061/dryad.brv15dvk2",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Twenty-six unbaited camera traps about 400 m apart along inactive logging roads on Afognak Island, Alaska, photographed Sitka black-tailed deer from 1 September 2022; bucks were identified individually from antler characteristics and natural markings, with independent events separated by six minutes. The deposit gives each buck's capture events, a camera x night operating matrix (32 nights; one camera failed after night 18) and camera coordinates, the inputs of a closed spatial capture-recapture density estimate that the authors compared with thermal-drone counts. The table is one row per buck x camera x worked night, y = 1 on detection, y_raw = the number of independent events that night.",
  samplingProtocol = "26 Browning Strike Force HD cameras on poles or stumps about 100 cm high along inactive logging roads, about 400 m apart, unbaited, operating 24 h with a three-photo burst; events at one camera separated by at least six minutes; bucks identified from antler shape, length, points, brow tines and scars by one observer.",
  samplingProtocolCode = "camera_trap", responseType = "detection", unitKind = "individual",
  surveyEvidence = "effort_table",
  closure = "closed", closureNote = "one period of 32 nights treated as a closed population for SCR density", occasionKind = "time",
  taxonInclusion = "single",
  temporalCoverage = "2022-09/2022-10",
  geographicCoverage = "Afognak Island, Kodiak Archipelago, Alaska, USA (about 58.3 N, 152.3 W); camera coordinates in __traps",
  crs = "UTM zone 5N (EPSG:32605 assumed; the deposit gives eastings and northings without a CRS, and the zone is inferred from the island's location)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (deer are not a flagged taxon)"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; closed population, nightly occasions. Night k of the operating matrix is calendar day 2022-09-01 + k - 1 (every capture falls on a worked night under this reading).",
  notShipped = list(bucks_does_fawns = "Bucks_does_fawns.csv: an event list of does, fawns and unidentified bucks with group sizes (not individual histories); its identified-buck events (121) differ from the deposited capture history (117)",
                    drone_counts = "not deposited"),
  notes = "Bucks only: does and fawns were not individually identified. The Dryad methods say cameras were active to 6 October; the deposited operating matrix covers 32 nights (to 2 October).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Spatial capture-recapture detections of 23 individually identified Sitka black-tailed deer bucks at 26 camera traps over 32 nights (September-October 2022) on Afognak Island, Alaska, one row per buck x camera x worked night, with camera coordinates in __traps.",
  url = "https://doi.org/10.5061/dryad.brv15dvk2",
  reference = "Finnegan, S. P., Hinojo, A., Monod, S., Wall, W. A., Olsen, P., & Allen, M. L. (2024). A comparison of thermal drones and camera trap population estimates for Sitka black-tailed deer in Alaska. Wildlife Biology, e01360.",
  doi_paper = "10.1002/wlb3.01360", doi_data = "10.5061/dryad.brv15dvk2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population SCR (E9 experimental): trap key + __traps. Survey set = deposited camera x night operating matrix. y_raw = independent events (6-min cutoff) per buck-camera-night. Night-to-date mapping read from the captures.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed, camera traps)",
  sampling_protocol = "Camera trap", design = "Single-season (32 nightly occasions, 26 cameras)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (camera coordinates in __traps, UTM 5N)",
  notes = "Experimental (E9): trap key + __traps. Bucks identified from antlers; full rectangle of worked camera-nights.")
