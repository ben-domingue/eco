#!/usr/bin/env Rscript
# Table:  hitchcock_2025_garden_hedgehog_count
# Source: Zenodo record 15497666, doi:10.5281/zenodo.15497666 (published 2025-05-23; licence as shown on the record:
#         Creative Commons Attribution 4.0 International).
#   Hitchcock, K. (2025). Food over features: Supplementary feeding has the strongest influence on hedgehog
#   (Erinaceus europaeus) occupancy in urban gardens [data set]. Nottingham Trent University.
# Paper:  not given on the record; the record's description defines both files.
# Data:   NTUCZ01_weekly_observations.csv: 1,446 rows, one per camera-trap site (placename, a code such as A701) x ISO
#         week (2021-W14 ... 2023): days the camera ran in that week (1-7) and the number of hedgehog detections (0-56;
#         larger than the days, so detections, not detection-days). GardenFeatures.csv: the 415 sites with MONTH (1-3)
#         and counts or presence codes of garden features (garden size, boundary, lawn, flowerbed, trees / shrubs, bug
#         hotel, compost heap, hedgehog highway and house, log and rock piles, wild area, pond, shed / greenhouse,
#         vegetable patch, water bowl, wildflower patch, bird feeder, bird food on the ground, hedgehog food, mammal
#         food, front-to-back access) and relative abundance indices of dogs, badgers and foxes from the same cameras.
#         Asserted: the two files list the same 415 sites; (site, week) unique; every site's weeks are one run.
# Mapping: repeated counts, single species. unit = garden site (placename code), occasion = the site's weeks in order
#   (1-8), y = hedgehog detections in the week, obs_effort_days = camera days that week, obs_iso_week (the source's
#   ISO week label). surveyEvidence effort_table: a camera-week with days > 0 is a survey. unit_ garden features as
#   deposited (the record defines no codes beyond the column names; 0/1 columns read as absent / present).
# Not shipped: DOG_RAI, BADGER_RAI, FOX_RAI (indices computed from the same camera detections); no coordinates are
#   deposited (private gardens).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hitchcock_2025_garden_hedgehog_count"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/15497666", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"))
w <- fread(download_cached("https://zenodo.org/api/records/15497666/files/NTUCZ01_weekly_observations.csv/content", TABLE, "weekly.csv"), encoding = "UTF-8")
g <- fread(download_cached("https://zenodo.org/api/records/15497666/files/GardenFeatures.csv/content", TABLE, "features.csv"), encoding = "UTF-8")
setnames(w, 1, "placename"); setnames(g, 1, "placename"); setnames(w, "Erinaceus europaeus", "y")
stopifnot(nrow(w) == 1446, nrow(g) == 415, setequal(w$placename, g$placename), !anyDuplicated(w[, .(placename, date)]),
          all(grepl("^20(21|22|23)-W[0-9]{2}$", w$date)), all(w$days %in% 1:7), all(w$y >= 0), sum(w$y > w$days) == 250)
w[, wk := as.integer(substr(date, 1, 4)) * 100L + as.integer(substr(date, 7, 8))]
setorder(w, placename, wk)
w[, occasion := seq_len(.N), by = placename]
# weeks of a site are consecutive ISO weeks (no week 53 crossing in these data)
stopifnot(w[, all(diff(wk) == 1L), by = placename][, all(V1)])
fc <- setdiff(names(g), c("placename", "DOG_RAI", "BADGER_RAI", "FOX_RAI"))
gu <- g[, c("placename", fc), with = FALSE]; setnames(gu, fc, paste0("unit_", tolower(fc)))
L <- merge(w, gu, by = "placename")
long <- L[, c(list(unit = placename, taxon = "ERIEUR", y = as.integer(y), occasion = occasion), .SD,
              list(obs_effort_days = as.integer(days), obs_iso_week = date)), .SDcols = paste0("unit_", tolower(fc))]
stopifnot(nrow(long) == 1446)
taxa <- make_taxa("ERIEUR", "Erinaceus europaeus", vernacularName = "European hedgehog")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Weekly camera-trap detection counts of hedgehogs in 415 urban gardens, 2021-2023",
  creator = "Hitchcock, Kelly",
  pubDate = "2025", doi = "10.5281/zenodo.15497666", sourceURL = "https://doi.org/10.5281/zenodo.15497666",
  citation = "Hitchcock, K. (2025). Food over features: Supplementary feeding has the strongest influence on hedgehog (Erinaceus europaeus) occupancy in urban gardens [Data set]. Zenodo. https://doi.org/10.5281/zenodo.15497666",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Camera traps in private urban gardens recorded hedgehog detections week by week over deployments of one to eight weeks (2021-2023), with an inventory of garden features and supplementary feeding, to relate hedgehog occupancy to garden management.",
  samplingProtocol = "One camera trap per garden for one to eight consecutive weeks; hedgehog detections counted per ISO week with the number of days the camera ran.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", responseType = "count", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_effort_days",
  closureNote = "occasion = consecutive ISO weeks of a garden's one deployment.",
  geographicCoverage = "Urban gardens (study by Nottingham Trent University; the record gives no locations)",
  temporalCoverage = "2021/2023",
  notShipped = list(rai = "DOG_RAI, BADGER_RAI, FOX_RAI: indices computed from the same camera detections"),
  notes = "y counts detections in the week (up to 56), not days with a detection. Garden-feature columns are the source's codes (the record does not define them beyond their names).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/hitchcock_2025_garden_hedgehog_count.R")
stage_dict_row(TABLE,
  description = "Weekly counts of hedgehog camera-trap detections in 415 urban gardens over one- to eight-week deployments, 2021-2023, with camera days and garden features including supplementary feeding.",
  url = "https://doi.org/10.5281/zenodo.15497666",
  reference = "Hitchcock, K. (2025). Food over features: Supplementary feeding has the strongest influence on hedgehog (Erinaceus europaeus) occupancy in urban gardens. Zenodo.",
  doi_data = "10.5281/zenodo.15497666", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Camera-week counts with days as effort.", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture", sampling_protocol = "camera_trap",
  design = "Single-season (1-8 weeks per garden)", realm = "Terrestrial", country = "GBR", coordinates = "None in source",
  notes = "Private gardens; supplementary feeding study (country from the institution).")
