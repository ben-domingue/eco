#!/usr/bin/env Rscript
# Table:  valente_2024_oregon_murrelet_state
# Source: USGS ScienceBase doi:10.5066/P13DHFQP (USGS data release, published 2024-10-22; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Valente, J.J., Adrean, L.J., Nelson, S.K., Betts, M.G., Roby, D.D., and Rivers, J.W., 2024,
#   Occupancy surveys near Marbled Murrelet (Brachyramphus marmoratus) nest sites and random
#   locations between 2018 and 2022 along the central Oregon coast, USA: U.S. Geological Survey
#   data release.
# Data:   dataReleaseSite.csv: 46 sites (20 centred on a radio-tracked murrelet's nest tree, 26 on a
#         random tree), each sampled in one year (2018, 2019, 2021, 2022), with nest initiation and
#         fledge-or-fail dates for nest sites. dataReleaseStation.csv: 132 survey stations (A, B, C
#         by distance from the focal tree) with the distance (m). dataReleaseSurvey.csv: 447
#         dawn audio-visual surveys (station x date) with the number of murrelet detections, the
#         strongest breeding evidence (SigBehavior: N none, P presence, 3 landing, 4 calling from a
#         stationary position, 5A below-canopy flight in habitat, 6A circling above the stand; the
#         codes 1, 2, 5B, 6B are defined but unused), start, end and length (minutes after
#         midnight), observer notes, and the authors' presence and occupied indicators.
#         dataReleaseVideos.csv: 2,648 nest-camera events at active nests.
#         Asserted: one survey per station x date, every station in the station file surveyed,
#         occupied = 1 exactly for codes 3, 4, 5A, 6A, presence = 1 exactly for codes other than N,
#         and SurveyEnd - SurveyStart = SurveyLength. Two surveys (18-17 A 2018-06-15, 22-5 C
#         2022-08-11) record detections (2 and 14) but SigBehavior N and presence 0: the authors'
#         codes are kept as y and the count as obs_n_detections, as deposited.
# Mapping: unit = station ("<site>_<station>"), cluster_id = site, occasion = survey in date order at
#   the station, taxon = BRAMAR, responseType state: y = 0 no murrelet (N), 1 presence only (P), 2
#   occupied behaviour (3, 4, 5A, 6A), the Pacific Seabird Group protocol's distinction that the
#   paper uses; y_raw = SigBehavior (surveyEvidence sample_table). unit_nest_site, unit_year and
#   the nest dates (site level), unit_distance_m (station); obs_ survey start, length, detections.
#   No coordinates are deposited (the release gives a bounding box only).
# Not shipped: the nest-camera events (dataReleaseVideos.csv: adult and chick behaviour at nests, not
#   a survey of the stations); observer notes (free text).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "valente_2024_oregon_murrelet_state"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/66882dead34e6179d07b1a34?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], TABLE, filename = f))
s <- rd("dataReleaseSite.csv"); st <- rd("dataReleaseStation.csv"); v <- rd("dataReleaseSurvey.csv")
stopifnot(nrow(s) == 46, !anyDuplicated(s$SiteNum), nrow(st) == 132, !anyDuplicated(st[, .(SiteNum, StationNum)]),
          nrow(v) == 447, !anyDuplicated(v[, .(SiteNum, StationNum, SurveyDate)]),
          nrow(fsetdiff(unique(st[, .(SiteNum, StationNum)]), unique(v[, .(SiteNum, StationNum)]))) == 0,
          all(v$SiteNum %in% s$SiteNum), all(v$SigBehavior %in% c("N", "P", "3", "4", "5A", "6A")),
          all(v$occupied == as.integer(v$SigBehavior %in% c("3", "4", "5A", "6A"))),
          all(v$presence == as.integer(v$SigBehavior != "N")), all(v$SurveyEnd - v$SurveyStart == v$SurveyLength),
          sum(v$TotDetections > 0 & v$presence == 0) == 2, all(v$TotDetections[v$presence == 1] > 0))
v[, date := as.IDate(SurveyDate)]
setorder(v, SiteNum, StationNum, date)
v[, occasion := seq_len(.N), by = .(SiteNum, StationNum)]
v <- merge(merge(v, st, by = c("SiteNum", "StationNum")), s, by = "SiteNum")
stopifnot(all(year(v$date) == v$Year))
long <- v[, .(unit = paste0(SiteNum, "_", StationNum), taxon = "BRAMAR", y = presence + occupied, y_raw = SigBehavior, occasion,
              date = format(date), cluster_id = SiteNum, unit_nest_site = as.integer(Treatment == "nest"), unit_year = Year,
              unit_nest_initiation = as.character(NestInitiationDate), unit_nest_end = as.character(FledgeFailDate),
              unit_station = StationNum, unit_distance_m = Distance,
              obs_start_min = SurveyStart, obs_length_min = SurveyLength, obs_n_detections = TotDetections)]
stopifnot(nrow(long) == 447, all(long$y %in% 0:2), sum(long$y == 2) == 101)
taxa <- make_taxa("BRAMAR", "Brachyramphus marmoratus", vernacularName = "Marbled murrelet")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Marbled murrelet audio-visual station surveys at 20 nest sites and 26 random sites, central Oregon coast, 2018-2022",
  creator = "Valente, Jonathon J.; Adrean, Lindsay J.; Nelson, S. Kim; Betts, Matthew G.; Roby, Daniel D.; Rivers, James W.",
  pubDate = "2024", doi = "10.5066/P13DHFQP", sourceURL = "https://doi.org/10.5066/P13DHFQP",
  citation = "Valente, J.J., Adrean, L.J., Nelson, S.K., Betts, M.G., Roby, D.D., and Rivers, J.W., 2024, Occupancy surveys near Marbled Murrelet (Brachyramphus marmoratus) nest sites and random locations between 2018 and 2022 along the central Oregon coast, USA: U.S. Geological Survey data release, https://doi.org/10.5066/P13DHFQP.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "A test of whether Pacific Seabird Group presence / occupancy surveys identify murrelet nesting stands: up to three stations at increasing distance from 20 known nest trees (found by radio-tracking) and from 26 random trees were surveyed repeatedly at dawn in the breeding seasons of 2018, 2019, 2021 and 2022, recording murrelet detections and the strongest evidence of breeding (occupied behaviour: landing, stationary calling, below-canopy flight, circling).",
  samplingProtocol = "Pacific Seabird Group inland dawn audio-visual surveys, about two hours from before sunrise, at stations 36-300 m from a focal tree, repeated through the breeding season; each survey records detections and the strongest breeding behaviour seen.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "state",
  stateCodes = list(`0` = "no murrelet recorded (N)", `1` = "presence only (P)", `2` = "occupied behaviour: landing (3), calling from a stationary position (4), below-canopy flight in habitat (5A) or circling above the stand (6A)"),
  unitKind = "site", closure = "closed", closureNote = "repeat dawn surveys of a station within one breeding season (May to August); a site was sampled in one year only",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = list(description = "Oregon Coast Range near Newport, central Oregon coast, USA",
                            boundingBox = list(west = -125.3320, east = -123.0469, south = 42.3261, north = 45.6448)),
  temporalCoverage = "2018-05/2022-08",
  notShipped = list(nest_videos = "dataReleaseVideos.csv: nest-camera events at active nests, not a survey of the stations",
                    notes = "observer notes (free text)"),
  notes = "Two surveys record murrelet detections (obs_n_detections 2 and 14) but the authors coded them N (presence 0); y follows the authors' codes.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/valente_2024_oregon_murrelet_state.R")
stage_dict_row(TABLE,
  description = "Marbled murrelet survey outcome (none, presence, occupied behaviour) on 447 dawn audio-visual surveys at 132 stations around 20 nest trees and 26 random trees on the central Oregon coast, 2018-2022.",
  url = "https://doi.org/10.5066/P13DHFQP",
  reference = "Valente, J.J., et al. (2024). Occupancy surveys near Marbled Murrelet (Brachyramphus marmoratus) nest sites and random locations between 2018 and 2022 along the central Oregon coast, USA. U.S. Geological Survey data release.",
  doi_data = "10.5066/P13DHFQP", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Multi-state: 0 none, 1 presence, 2 occupied behaviour; station units clustered in sites.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state occupancy", sampling_protocol = "point_count",
  design = "Single-season (up to 5 surveys per station)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Pacific Seabird Group inland survey protocol; IUCN EN; nest vs random sites.")
