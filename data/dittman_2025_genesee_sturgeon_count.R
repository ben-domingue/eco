#!/usr/bin/env Rscript
# Table:  dittman_2025_genesee_sturgeon_count
# Source: USGS ScienceBase doi:10.5066/P9OFB4P1 (USGS data release, revised 2025 with data to
#         2023; use constraints "No data use constraints."; US public domain, recorded as
#         CC0 1.0)
#   Dittman, D.E., Chalupnicki, M.A., Rubenstein, S.R., Hoffman, G., and Turk, M., 2025, Assessment
#   of Released Lake Sturgeon in the Genesee River, NY: 2003-2023: U.S. Geological Survey data release.
# Data:   Genesee_LakeSturgeonCaptures_2003-2023_revised.csv: 3,516 rows, one per lake sturgeon caught
#         or, for a net with no catch, one empty row per net: river, site code, coordinates, date and
#         time set and pulled, Floy and PIT tag, length, weight, girth, new / recapture, scute mark,
#         year class, life stage, gill-net mesh. 158 rows are blank padding. Asserted: 430 net rows
#         with every fish field NA (no catch) and one row with only a life stage (counted as a fish);
#         "WaterFall" and "Waterfall" are one site; nets were fished overnight at standard index sites
#         (abstract), several nets (meshes) at a site on one date in some years.
# Mapping: unit = index site code as deposited (numbered codes such as "104 Bridge 1" / "2" are
#   separate net locations; cluster_id = the code without its number), period = year (1 = 2003 ...
#   21 = 2023), occasion = the site's visits in the year (by date set, in date order), y = lake
#   sturgeon caught in the nets set at the site that date (rows with any fish field filled).
#   surveyEvidence row_presence: a net fished with no catch has its own empty row, so every
#   site-date with a row was netted. obs_gear (the meshes of the nets fished, as deposited, joined),
#   obs_n_nets (distinct mesh x set-time combinations: an approximate net count), obs_time_set
#   (earliest), obs_date_pulled, obs_n_recap (fish recorded as recaptures). Lake sturgeon is IUCN EN
#   (GBIF's IUCN record, asserted) and the river is in its native range, so the published net
#   positions are coarsened to the 0.1-degree cell (obs_latitude / obs_longitude, the visit's first
#   position; a few sites straddle two cells), following the bull trout and moccasinshell precedent for agency coordinates.
# Not shipped: the per-fish records (tags, length, weight, girth, scute mark, year class, life stage):
#   individual histories need a Floy-to-PIT tag reconciliation the release does not deposit, so no
#   CJS is built; nets are not separated (mesh is given per fish but the net of an empty row is
#   not always distinguishable from a second set at the site that date), so the survey is the
#   site visit, summing its nets.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dittman_2025_genesee_sturgeon_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/63223702d34e71c6d67ab655?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
x <- fread(download_cached(fl[["Genesee_LakeSturgeonCaptures_2003-2023_revised.csv"]], TABLE, filename = "captures.csv"),
           encoding = "UTF-8", colClasses = "character", na.strings = NULL)
setnames(x, trimws(sub("^﻿", "", names(x))))
stopifnot(nrow(x) == 3516)
for (c in names(x)) set(x, j = c, value = trimws(x[[c]]))
stopifnot(sum(x$Site_code == "") == 158, all(unlist(x[Site_code == ""]) == ""))
x <- x[Site_code != ""]
x[Site_code == "WaterFall", Site_code := "Waterfall"]
fc <- c("Floy_tag", "Pit_tag", "Length_mm", "Weight_kg", "Girth_mm", "New_recapture", "Scute_mark", "Year_class", "Life_stage")
x[, nfill := rowSums(matrix(!(as.matrix(.SD) %in% c("NA", "")), ncol = length(fc))), .SDcols = fc]
stopifnot(sum(x$nfill == 0) == 430, sum(x$nfill == 1) == 1)
x[, fish := nfill > 0]
x[, d := as.IDate(Date_set, format = "%m/%d/%Y")]
stopifnot(!anyNA(x$d), sum(x$fish) == 2928)
v <- x[, .(y = sum(fish), n_recap = sum(fish & tolower(New_recapture) == "recap"),
           gear = paste(sort(unique(GillNet[GillNet != "NA"])), collapse = "; "),
           n_nets = uniqueN(paste(GillNet, Time_set)), time_set = min(Time_set), date_pulled = format(min(as.IDate(Date_pulled, format = "%m/%d/%Y"))),
           lat = as.numeric(Latitude[1]), lon = as.numeric(Longitude[1])), by = .(Site_code, d)]
v[, yr := year(d)]
setorder(v, Site_code, d)
v[, occasion := seq_len(.N), by = .(Site_code, yr)]
stopifnot(sum(v$y) == 2928, !anyNA(v$lat), nrow(v) == uniqueN(x[, .(Site_code, d)]))
cc <- coarsen_coords(v$lat, v$lon); v[, `:=`(clat = cc$lat, clon = cc$lon)]
long <- v[, .(unit = Site_code, taxon = "ACIFUL", y = as.integer(y), period = yr - 2002L, occasion, date = format(d),
              cluster_id = trimws(sub(" [0-9]+$", "", Site_code)),
              obs_gear = gear, obs_n_nets = n_nets, obs_time_set = time_set, obs_date_pulled = date_pulled,
              obs_latitude = clat, obs_longitude = clon, obs_n_recap = n_recap)]
periods <- data.table(period = sort(unique(long$period)))[, year := period + 2002L]
taxa <- make_taxa("ACIFUL", "Acipenser fulvescens", vernacularName = "Lake sturgeon")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "EN"))
dataset <- list(
  title = sprintf("Gill-net counts of reintroduced lake sturgeon on %s site visits at %d index sites, Genesee River, New York, 2003-2023",
                  format(nrow(long), big.mark = ","), uniqueN(long$unit)),
  creator = "Dittman, Dawn E.; Chalupnicki, Marc A.; Rubenstein, Sarah R.; Hoffman, Georgia; Turk, Marisa",
  pubDate = "2025", doi = "10.5066/P9OFB4P1", sourceURL = "https://doi.org/10.5066/P9OFB4P1",
  citation = "Dittman, D.E., Chalupnicki, M.A., Rubenstein, S.R., Hoffman, G., and Turk, M., 2025, Assessment of Released Lake Sturgeon in the Genesee River, NY: 2003-2023: U.S. Geological Survey data release, https://doi.org/10.5066/P9OFB4P1.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Hatchery-reared young-of-year lake sturgeon were released into the Genesee River, New York, from 2003; their presence was assessed by systematic overnight gill netting at standard index sites from 2003 to 2023, with every sturgeon caught checked for scute marks and tags, measured and tagged.",
  samplingProtocol = "Monofilament gill nets of several meshes fished overnight at standard index sites selected as juvenile lake sturgeon habitat; set and pull times recorded; every lake sturgeon caught counted, measured and tagged.",
  samplingProtocolCode = "gill_net", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "open", occasionKind = "time",
  closureNote = "occasion = the site's netting dates within the year, which span spring to autumn in most years.",
  taxonInclusion = "single",
  geographicCoverage = list(description = "Lower Genesee River, Rochester, New York, USA",
                            boundingBox = list(west = round(min(v$lon), 1), east = round(max(v$lon), 1), south = round(min(v$lat), 1), north = round(max(v$lat), 1))),
  temporalCoverage = "2003/2023",
  coordinatesCoarsened = list(value = TRUE, method = "coarsen_coords(): 0.1-degree cell centre of the site's net positions, because lake sturgeon (Acipenser fulvescens) is IUCN EN (GBIF IUCN record, asserted) in its native range; USGS published the positions exactly (bull trout / moccasinshell precedent, an open question for Ben)"),
  effortColumn = "obs_n_nets",
  notShipped = list(exact_coordinates = "net positions coarsened to 0.1 degree (lake sturgeon IUCN EN)", blank_rows = "158 blank padding rows", fish_records = "per-fish tag, size, scute mark, year class and life stage (no CJS built: Floy and PIT tags are not reconciled in the release)",
                    nets = "nets within a site visit are summed: an empty net row cannot always be told from a second set"),
  notes = "obs_n_nets counts distinct mesh x set-time combinations at the visit; it approximates the number of nets. The reintroduced fish are hatchery-released; counts include recaptures (obs_n_recap).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dittman_2025_genesee_sturgeon_count.R")
stage_dict_row(TABLE,
  description = "Counts of reintroduced lake sturgeon in overnight gill nets at index sites in the lower Genesee River, New York, 2003-2023, per site visit, with meshes fished and net positions.",
  url = "https://doi.org/10.5066/P9OFB4P1",
  reference = "Dittman, D.E., Chalupnicki, M.A., Rubenstein, S.R., Hoffman, G., and Turk, M. (2025). Assessment of Released Lake Sturgeon in the Genesee River, NY: 2003-2023. U.S. Geological Survey data release.",
  doi_data = "10.5066/P9OFB4P1", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Count per site visit (nets summed); empty nets recorded as empty rows.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (open)", sampling_protocol = "gill_net",
  design = "Multi-season (21 years, visits within years)", realm = "Freshwater", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Reintroduction monitoring; per-fish tag records not built.")
