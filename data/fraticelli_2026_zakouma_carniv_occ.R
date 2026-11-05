#!/usr/bin/env Rscript
# Table:  fraticelli_2026_zakouma_carniv_occ
# Source: Dryad doi:10.5061/dryad.j9kd51cvc, version 450760 (published 2026-07-01), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Fraticelli, C., Shams, A., Verschueren, S., Ourde, O.,
#         Fekoua, B., Zayed, A. A., Leirs, H. & Bauer, H. "Data from: Seasonal dynamics of resource availability and
#         human presence shape habitat use of large carnivores in Chad".
# Paper:  Fraticelli, C. et al. (2026). Seasonal dynamics of resource availability and human presence shape habitat
#         use of large carnivores in Chad. Ecology and Evolution 16, doi:10.1002/ece3.73957 (not read; design from
#         the deposited README.md and the files).
# Data:   README.md, five R scripts (spOccupancy analysis), and xlsx files:
#         ZNP2020_carnivore_dataset.xlsx: every large-carnivore detection (1,336 rows: Station, DateTimeOriginal,
#           Date, Species, Season), dry season 2020-01-15..2020-04-12 at 85 stations, wet season 2020-07-01..
#           2020-09-28 at 35 stations. Date differs from the date of DateTimeOriginal on 90 late-evening records
#           (a time-zone shift); the authors' matrices use Date (asserted below).
#         ZNP2020_table5d_effort_{Dry,Wet}2020_wide.xlsx: trap-days active (0..5) per station x 5-day occasion
#           (so11..so28, 18 occasions) and TOTeffort; 95 dry and 55 wet stations.
#         ZNP2020_table5d_{Dry,Wet}2020_<species>_wide.xlsx: 0/1 detection per station x occasion, blank where the
#           camera was not active. Dry: cheetah, leopard, lion, spotted hyaena, striped hyaena. Wet: leopard, lion,
#           spotted hyaena only (the wet season had no cheetah record and one striped hyaena record, so the authors
#           did not model them). The blank pattern is exactly effort == 0 in every matrix (asserted).
#         ZNP2020_covariatesRAI_use.xlsx: 133 stations x 20 site covariates (camera make and flash, road and
#           water placement, distances to boundary and village, road density, NDVI per season, distance to dry-
#           season water, wet-season flooded area, and log relative-abundance indices of prey and livestock).
# Mapping (standard E9 multi-season community occupancy):
#   unit = camera station; period 1 = dry season 2020, 2 = wet season 2020; occasion = 5-day occasion 1..18 from the
#   season's first day; taxon = ACIJUB, PANPAR, PANLEO, CROCRO, HYAHYA; y = detected (0/1).
#   Survey evidence: effort_table (a survey exists where trap-days > 0). y is the deposited matrix for the eight
#   species x season matrices; for wet-season cheetah and striped hyaena, which the camera survey recorded but the
#   authors did not tabulate, y is built from the detection list with the authors' rule (Date into 5-day occasions
#   from the season start), which reproduces seven of the eight deposited matrices exactly and the dry spotted
#   hyaena matrix in all but 4 of 1,598 cells (asserted). Three wet-season spotted hyaena records at Sta05F, a
#   station absent from the wet effort table, are not in the survey set.
#   Covariates: obs_effort_days (trap-days active in the occasion), obs_occasion_start (ISO date);
#   unit_ camera make, flash type, road and water placement, distance to park boundary and to village (m),
#   log road density in a 5 x 5 km cell; period_ndvi (the season's NDVI).
#   Not shipped: the prey and livestock relative-abundance indices (summaries of other species' detections at the
#   same cameras, whose images are not deposited); distance to dry-season water and wet-season flooded area (one
#   season each); the spOccupancy scripts. No station coordinates in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "fraticelli_2026_zakouma_carniv_occ"
dir <- download_dryad("10.5061/dryad.j9kd51cvc", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "450760"), length(list.files(dir)) == 18L)
rx <- function(f) as.data.table(read_excel(file.path(dir, f)))

rec <- rx("ZNP2020_carnivore_dataset.xlsx")
stopifnot(nrow(rec) == 1336L, identical(names(rec), c("Station", "DateTimeOriginal", "Date", "Species", "Season")))
rec[, Date := as.IDate(Date)]
start <- setNames(as.integer(as.IDate(c("2020-01-15", "2020-07-01"))), c("Dry", "Wet"))
rec[, occasion := (as.integer(Date) - start[Season]) %/% 5L + 1L]
stopifnot(all(rec$occasion %in% 1:18), sum(as.IDate(rec$DateTimeOriginal) != rec$Date) == 90L,
          identical(sort(unique(rec$Species)), c("Cheetah", "Leopard", "Lion", "Spotted hyaena", "Striped hyaena")),
          rec[Season == "Wet" & Species == "Cheetah", .N] == 0L, rec[Season == "Wet" & Species == "Striped hyaena", .N] == 1L)

sp <- c(cheetah = "Cheetah", leopard = "Leopard", lion = "Lion", spottedhy = "Spotted hyaena", stripedhy = "Striped hyaena")
code <- c(Cheetah = "ACIJUB", Leopard = "PANPAR", Lion = "PANLEO", `Spotted hyaena` = "CROCRO", `Striped hyaena` = "HYAHYA")
occ_names <- paste0("so", 11:28)
long <- list(); ndiff <- 0L
for (s in c("Dry", "Wet")) {
  e <- rx(sprintf("ZNP2020_table5d_effort_%s2020_wide.xlsx", s))
  stopifnot(identical(names(e), c("Station", paste0(occ_names, "_effort_", s, "2020"), "TOTeffort")), !anyDuplicated(e$Station))
  E <- unname(as.matrix(e[, 2:19])); stopifnot(all(E %in% 0:5), all(rowSums(E) == e$TOTeffort), all(e$TOTeffort > 0))
  for (k in names(sp)) {
    # rebuild from the detection list with the authors' rule
    R <- matrix(0L, nrow(e), 18); x <- unique(rec[Season == s & Species == sp[[k]], .(i = match(Station, e$Station), occasion)])
    stopifnot(sum(is.na(x$i)) == if (s == "Wet" && k == "spottedhy") 1L else 0L)   # Sta05F, wet, no effort row
    x <- x[!is.na(i)]; R[cbind(x$i, x$occasion)] <- 1L; R[E == 0] <- NA
    f <- sprintf("ZNP2020_table5d_%s2020_%s_wide.xlsx", s, k)
    if (file.exists(file.path(dir, f))) {
      d <- rx(f); stopifnot(identical(d$Station, e$Station), identical(names(d)[-1], occ_names))
      Y <- unname(as.matrix(d[, -1])); storage.mode(Y) <- "integer"
      stopifnot(all(Y %in% c(0L, 1L, NA)), identical(is.na(Y), E == 0))
      ndiff <- ndiff + sum(R != Y, na.rm = TRUE)
    } else {
      stopifnot(s == "Wet", k %in% c("cheetah", "stripedhy")); Y <- R
    }
    long[[paste(s, k)]] <- data.table(unit = rep(e$Station, 18), period = if (s == "Dry") 1L else 2L,
                                      occasion = rep(1:18, each = nrow(e)), taxon = code[[sp[[k]]]], y = c(Y),
                                      obs_effort_days = c(E))[!is.na(y)]
  }
}
stopifnot(ndiff == 4L)
long <- rbindlist(long)
long[, obs_occasion_start := format(as.IDate(start[period] + 5L * (occasion - 1L)))]
stopifnot(nrow(long) == 5L * (1598L + 430L), long[y == 1, .N] == 14 + 91 + 130 + 477 + 105 + 0 + 10 + 22 + 77 + 1,
          all(long$obs_effort_days > 0))

cv <- rx("ZNP2020_covariatesRAI_use.xlsx")
stopifnot(nrow(cv) == 133L, !anyDuplicated(cv$Station), all(unique(long$unit) %in% cv$Station))
ucov <- cv[, .(unit = Station, unit_camera_model = MakeModel, unit_flash = Flash,
               unit_on_road = as.integer(as.logical(hab_road)), unit_near_water = as.integer(as.logical(hab_water)),
               unit_dist_border_m = Dist_border_m, unit_dist_village_m = Dist_Villa_m,
               unit_road_density_log = X5x5_parkroad_m_log)]
pcov <- rbind(cv[, .(unit = Station, period = 1L, period_ndvi = NDVI_Dry20)], cv[, .(unit = Station, period = 2L, period_ndvi = NDVI_Wet20)])
long <- merge(merge(long, ucov, by = "unit"), pcov, by = c("unit", "period"), all.x = TRUE)
stopifnot(all(long$unit_flash %in% c("CV", "IR", "W")), !anyNA(long$unit_on_road), !anyNA(long$period_ndvi))
long <- order_eco(long)

taxa <- make_taxa(unname(code), c("Acinonyx jubatus", "Panthera pardus", "Panthera leo", "Crocuta crocuta", "Hyaena hyaena"),
                  vernacularName = names(code))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, c("VU", "VU", "VU", "LC", "NT")))
periods <- data.table(period = 1:2, period_label = c("Dry season 2020", "Wet season 2020"),
                      period_start = c("2020-01-15", "2020-07-01"), period_end = c("2020-04-12", "2020-09-28"))

dataset <- list(
  title = "Camera-trap detections of five large carnivores in Zakouma National Park, Chad, dry and wet seasons 2020",
  creator = "Fraticelli, Chiara; Shams, Ali; Verschueren, Stijn; Ourde, Ousmane; Fekoua, Baudin; Zayed, Abdoulaye Abakar; Leirs, Herwig; Bauer, Hans",
  pubDate = "2026", doi = "10.5061/dryad.j9kd51cvc", sourceURL = "https://doi.org/10.5061/dryad.j9kd51cvc",
  citation = "Fraticelli, C., Shams, A., Verschueren, S., Ourde, O., Fekoua, B., Zayed, A. A., Leirs, H., & Bauer, H. (2026). Data from: Seasonal dynamics of resource availability and human presence shape habitat use of large carnivores in Chad [Dataset]. Dryad. https://doi.org/10.5061/dryad.j9kd51cvc",
  paperDOI = "10.1002/ece3.73957",
  abstract = "A systematic camera-trap survey of Zakouma National Park, Chad, in the dry season (January to April 2020) and the wet season (July to September 2020). Detections of cheetah, leopard, lion, spotted hyaena and striped hyaena are pooled into 5-day occasions, 18 per season, at the stations active in each season, with trap-days of effort per occasion, camera type, placement on roads or near water, distances to the park boundary and villages, road density and seasonal NDVI. The authors fitted occupancy models to compare carnivore space use between seasons.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Camera traps at fixed stations run continuously through each season; detections pooled into consecutive 5-day occasions from the season's first day; obs_effort_days gives the trap-days active (1 to 5) in each occasion, and occasions with no active days are not surveys.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occupancy assumed constant within each roughly 90-day season; the two seasons are separate periods",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Zakouma National Park, southeastern Chad (no station coordinates in the deposit)",
  temporalCoverage = "2020-01-15/2020-09-28",
  covariateNote = "obs_effort_days: trap-days the camera was active in the 5-day occasion. obs_occasion_start: first day of the occasion. unit_camera_model and unit_flash (W white, CV covert, IR infra-red) as deposited. unit_on_road, unit_near_water: 1 if the camera was on a park road / near surface water. unit_road_density_log: log density of park roads in the 5 x 5 km cell. Continuous covariates are as deposited (the README says the authors standardised them for analysis). period_ndvi: mean Sentinel-2 NDVI of the cell over the season.",
  notShipped = list(
    rai = "Log relative abundance indices of prey (all, large, medium, small) and livestock per season: summaries of other species' detections at the same cameras, whose records are not deposited.",
    single_season_covs = "DryWater_GEEdist_m_log (dry season only) and Flood_area (wet season only).",
    sta05f = "Three wet-season spotted hyaena records at Sta05F, a station with no row in the wet-season effort table.",
    scripts = "The spOccupancy analysis scripts."),
  notes = "Wet-season cheetah (no records) and striped hyaena (one record) are in the table although the authors did not model them: the camera survey recorded every large carnivore, and their rows are built from the detection list with the rule that reproduces the deposited matrices. The deposited dry-season spotted hyaena matrix is shipped as deposited; it differs from the rebuilt one in 4 cells.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fraticelli_2026_zakouma_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection of five large carnivores in 5-day occasions at stations in Zakouma National Park, Chad, dry and wet seasons 2020, with effort and site covariates.",
  url = "https://doi.org/10.5061/dryad.j9kd51cvc",
  reference = "Fraticelli, C., Shams, A., Verschueren, S., Ourde, O., Fekoua, B., Zayed, A. A., Leirs, H., & Bauer, H. (2026). Seasonal dynamics of resource availability and human presence shape habitat use of large carnivores in Chad. Ecology and Evolution, 16.",
  doi_paper = "10.1002/ece3.73957", doi_data = "10.5061/dryad.j9kd51cvc",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; effort table is the survey set; wet-season cheetah and striped hyaena rebuilt from the detection list; prey RAI not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-species, two seasons)",
  sampling_protocol = "camera_trap", design = "Multi-season (two seasons of 18 five-day occasions)",
  realm = "Terrestrial", country = "TCD", coordinates = "None in source",
  notes = "Central African savanna carnivores; lion, leopard and cheetah IUCN VU; no coordinates in source.")
