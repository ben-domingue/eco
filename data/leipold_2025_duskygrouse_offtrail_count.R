#!/usr/bin/env Rscript
# Table:  leipold_2025_duskygrouse_offtrail_count
# Source: Dryad doi:10.5061/dryad.hqbzkh1s7 (CC0 1.0, as shown on the Dryad page; published
#         2025-04-07). Leipold, E., Gower, C. & McNew, L.B. (2025). Data from: Maximizing the
#         detection probabilities of dusky grouse for population monitoring.
# Paper:  Leipold, E., Gower, C. & McNew, L.B. Maximizing the detection probabilities of dusky
#         grouse for population monitoring. Wildlife Biology, doi:10.1002/wlb3.01411.
# Data:   README.md is the codebook. The 2019 off-trail playback experiment: each point visited
#         on three mornings within two weeks; at each visit two consecutive 4-minute counts, the
#         first without and the second with electronic playback (spring: female call; summer:
#         chick distress call). DuskySpringSurveys.csv: 540 rows = 90 points (18 transects in
#         FWP region 3) x 3 visits x 2 playback treatments; DUGR = dusky grouse counted, NA = "the
#         point-count was not successfully completed" (5 points at visit 2, both treatments).
#         DuskySummerSurveys.csv: 650 rows = 110 points (22 transects; 50 also surveyed in
#         spring) x visits 1-2 (110) and visit 3 (105; the other five have no row), no NA.
#         route_type_data.csv rows with SurveyYear 2019 (Type Off-trail) are the 90 spring
#         points with per-visit Days (10 April = day 1), Minutes since sunrise, CloudCover,
#         Precip, Temp and Wind; their X1-X3 are a per-visit count whose relation to the two
#         treatment counts is not stated (it equals their sum at 84 of 90 visit-1 points) and is
#         not shipped. The 2020-2021 road/trail counts in the same deposit are
#         leipold_2025_duskygrouse_roads_count.
# Mapping: unit = point (Point ID); taxon = DUGR; period = season (1 = spring 2019,
#         2 = summer 2019); occasion = 2 x (visit - 1) + treatment (1 no playback, 2 playback),
#         occasionKind = [time, method], recoverable from obs_visit and obs_playback (0/1);
#         y = dusky grouse counted in the 4-minute count. A row exists iff the count has a
#         non-NA DUGR (NA = not completed; a missing summer visit-3 row = not surveyed).
#         unit_transect. Spring rows carry date (10 April + Days - 1, exact),
#         obs_minutes_since_sunrise, obs_cloud_cover, obs_precip, obs_wind_kmh, obs_temp_c from
#         route_type_data.csv (one value per visit, both treatments); summer rows have them NA
#         because the deposit has no summer survey conditions. surveyEvidence = row_presence.
# Not shipped: route_type_data.csv's 2019 X1-X3 (undocumented relation to the treatment
#         counts); model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "leipold_2025_duskygrouse_offtrail_count"
dir <- download_dryad("10.5061/dryad.hqbzkh1s7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

sp <- fread(file.path(dir, "DuskySpringSurveys.csv")); su <- fread(file.path(dir, "DuskySummerSurveys.csv"))
cnt <- rbind(sp, su); setnames(cnt, c("Point ID"), c("Point"))
stopifnot(nrow(sp) == 540, nrow(su) == 650, all(cnt$Year == 2019), all(cnt$Playback %in% c("NoPlayback", "Playback")),
          !anyDuplicated(cnt[, .(Season, Point, Visit, Playback)]),
          uniqueN(sp$`Point ID`) == 90, uniqueN(su$`Point ID`) == 110,
          length(intersect(sp$`Point ID`, su$`Point ID`)) == 50,
          sum(is.na(sp$DUGR)) == 10, !anyNA(su$DUGR), all(cnt$DUGR %in% c(NA, 0:2)))
# NA is the same visit for both treatments
na <- cnt[is.na(DUGR)]; stopifnot(identical(na[Playback == "NoPlayback", .(Point, Visit)], na[Playback == "Playback", .(Point, Visit)]))
stopifnot(all(cnt[, uniqueN(Transect), by = Point]$V1 == 1))

rt <- fread(file.path(dir, "route_type_data.csv"))[SurveyYear == 2019]
stopifnot(nrow(rt) == 90, all(rt$Type == "Off-trail"), setequal(rt$PointName, sp$`Point ID`), all(is.na(rt$X4)))
cov <- rbindlist(lapply(1:3, function(k) rt[, .(Point = PointName, Visit = k,
  date = as.character(as.IDate("2019-04-10") + get(paste0("Days", k)) - 1L),
  obs_minutes_since_sunrise = get(paste0("Minutes", k)), obs_cloud_cover = get(paste0("CloudCover", k)),
  obs_precip = get(paste0("Precip", k)), obs_wind_kmh = get(paste0("Wind", k)), obs_temp_c = get(paste0("Temp", k)))]))
stopifnot(!anyNA(cov$date), all(substr(cov$date, 6, 7) %in% c("04", "05")))

cnt <- cnt[!is.na(DUGR)]
cnt[, Season := factor(Season, c("Spring", "Summer"))]
long <- cnt[, .(unit = Point, taxon = "DUGR", period = as.integer(Season),
                occasion = 2L * (Visit - 1L) + (Playback == "Playback") + 1L, y = DUGR,
                unit_transect = Transect, obs_visit = Visit, obs_playback = as.integer(Playback == "Playback"),
                Visit, Point, Season)]
long <- merge(long, cov, by = c("Point", "Visit"), all.x = TRUE, sort = FALSE)
long[Season == "Summer", c("date", "obs_minutes_since_sunrise", "obs_cloud_cover", "obs_precip", "obs_wind_kmh", "obs_temp_c") := NA]
long[, c("Point", "Visit", "Season") := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 530 + 650, sum(long$y) == 36 + 2 * 3 + 8, !anyNA(long[period == 1]$date))

taxa <- make_taxa("DUGR", "Dendragapus obscurus", vernacularName = "Dusky grouse")
periods <- data.table(period = 1:2, year = 2019L, season = c("spring", "summer"),
                      playback_call = c("female dusky/sooty grouse calls (cantus, whinny, cackle)", "dusky grouse chick distress call"))

dataset <- list(
  title = "Paired no-playback and playback point counts of dusky grouse at 150 off-trail points, western Montana, spring and summer 2019",
  creator = "Leipold, Elizabeth; Gower, Claire; McNew, Lance B.", pubDate = "2025",
  doi = "10.5061/dryad.hqbzkh1s7", sourceURL = "https://doi.org/10.5061/dryad.hqbzkh1s7",
  citation = "Leipold, E., Gower, C., & McNew, L. B. (2025). Data from: Maximizing the detection probabilities of dusky grouse for population monitoring [Dataset]. Dryad. https://doi.org/10.5061/dryad.hqbzkh1s7",
  paperDOI = "10.1002/wlb3.01411",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Off-trail point counts in Montana FWP region 3 in 2019: each point visited on three mornings within two weeks, with a 4-minute count without playback followed by a 4-minute count with electronic playback (female calls in spring, chick distress call in summer).",
  samplingProtocol = "Point counts at off-trail transect points, three visits on different mornings within two weeks per season; at each visit a 4-minute count without playback then a 4-minute count with playback.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "three visits within two weeks per season; spring and summer are separate periods",
  occasionKind = c("time", "method"), taxonInclusion = "single",
  geographicCoverage = "western Montana, USA, Montana FWP region 3 (no coordinates deposited)",
  temporalCoverage = "2019-04/2019-08",
  notShipped = list(
    route_type_X = "route_type_data.csv's 2019 per-visit counts X1-X3, whose relation to the two treatment counts is not documented",
    model_output = "detection-model estimates"),
  notes = "Survey conditions (date, time, weather) are deposited for the spring visits only; summer rows have them NA. The 2020-2021 road/trail counts in the same deposit are leipold_2025_duskygrouse_roads_count.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/leipold_2025_duskygrouse_offtrail_count.R")
stage_dict_row(TABLE,
  description = "Off-trail point counts of dusky grouse (Dendragapus obscurus) in western Montana, spring and summer 2019: three visits per season, each a 4-minute count without and then with electronic playback.",
  url = "https://doi.org/10.5061/dryad.hqbzkh1s7",
  reference = "Leipold, E., Gower, C., & McNew, L. B. Maximizing the detection probabilities of dusky grouse for population monitoring. Wildlife Biology. https://doi.org/10.1002/wlb3.01411",
  doi_paper = "10.1002/wlb3.01411", doi_data = "10.5061/dryad.hqbzkh1s7",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Playback treatment on obs_playback; spring survey conditions from route_type_data.csv; summer conditions not deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "point_count", design = "Multi-season (spring and summer 2019, 3 visits x 2 playback treatments)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Playback experiment; occasion crosses visit and treatment.")
