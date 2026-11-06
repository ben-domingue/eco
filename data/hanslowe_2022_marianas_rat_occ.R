#!/usr/bin/env Rscript
# Table:  hanslowe_2022_marianas_rat_occ
# Source: USGS ScienceBase doi:10.5066/P9FOS7Z8 (USGS data release, published 2022-06-09; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Hanslowe, E.B., Page, D.A., Bailey, L.L., and Yackel Adams, A.A., 2022, Spatial mark-recapture
#   and chew card rat data on Guam and Rota, 2018-2019: U.S. Geological Survey data release.
# Paper:  Hanslowe, E.B., Yackel Adams, A.A., Nafus, M.G., Page, D.A., Bradke, D.R., Erickson, F.T.,
#   and Bailey, L.L., 2022, Chew-cards can accurately index invasive rat densities in Mariana Island
#   forests. NeoBiota 74:29-56, doi:10.3897/neobiota.74.80242.
# Data:   Chewcards.csv: 6,945 card-nights, one per grid x date x card, CHEWED 0/1 (rat chew), on nine
#         forest grids (Guam G1-G4, Rota R1-R5; 121 cards on an 11 x 11 grid, 100 on R1-R3), five
#         consecutive nights per sampling; G2 and G3 sampled twice (G2.1 / G2.2, G3.1 / G3.2: the
#         second three months after lethal snake treatments expected to raise rat density) and R4
#         twice under one code (20-24 June 2019, then 9-13 July 2019 after rats were trapped and
#         euthanized, 28 June to 7 July). Grid layout.csv: UTM (WGS84 zone 55N) coordinates of the
#         trap and card stations, absent for G4. Chewcard camera verification.csv: 28 card-nights
#         with a camera, field chew call vs camera. Mark recapture trapping effort.csv: live-trap
#         nights (see notShipped). Asserted: no missing CHEWED, one row per grid-session x card x
#         night, every card on every night of its session.
# Mapping: unit = card station ("<grid>_<card>", the station is the same across a grid's two
#   samplings), period = sampling of the grid (1, 2), occasion = night within the sampling (1-5),
#   taxon = RATTUS (rats; the chew cards do not separate species), y = CHEWED (surveyEvidence
#   sample_table: a row of the chew-card file is a card-night). treat = 1 on the second sampling of
#   G2, G3 (after snake removal) and R4 (after rat removal), 0 otherwise; period_manipulation names
#   it. cluster_id = grid; unit_island. Coordinates: unit_x / unit_y in UTM 55N (EPSG:32655), as
#   published; empty for G4 (no layout deposited). Rats are invasive in the Marianas.
# Not shipped: the live-trap spatial mark-recapture data: some stations hold two traps in the same
#   night with no trap key (duplicate grid x date x station rows) and G4 has no trap layout, so a
#   spatial capture-recapture table needs a rule (held in queue/human_review.csv); the camera
#   verification (28 card-nights, a validation subset).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hanslowe_2022_marianas_rat_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/6088475cd34e5611588f8da1?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
cc <- fread(download_cached(fl[["Chewcards.csv"]], TABLE, filename = "Chewcards.csv"), encoding = "UTF-8")
gl <- fread(download_cached(fl[["Grid layout.csv"]], TABLE, filename = "Grid layout.csv"), encoding = "UTF-8")
setnames(cc, 1, "GRID"); setnames(gl, c("GRID", "TRAP", "x", "y"))
cc[, d := as.IDate(as.Date(DATE, tryFormats = c("%d-%b-%Y", "%d-%b-%y")))]
stopifnot(nrow(cc) == 6945, !anyNA(cc$CHEWED), all(cc$CHEWED %in% 0:1), !anyNA(cc$d), !anyDuplicated(cc[, .(GRID, d, TRAP)]),
          !anyDuplicated(gl$TRAP), all(cc[!startsWith(GRID, "G4"), TRAP] %in% gl$TRAP), !any(startsWith(gl$GRID, "G4")))
cc[, grid := sub("\\..*$", "", GRID)]
cc[, period := ifelse(grepl("\\.2$", GRID) | (GRID == "R4" & d >= as.IDate("2019-07-01")), 2L, 1L)]
setorder(cc, grid, period, d)
cc[, occasion := match(d, sort(unique(d))), by = .(grid, period)]
stopifnot(all(cc$occasion %in% 1:5), cc[, .N, by = .(grid, period, d)][, all(N == uniqueN(cc[grid == .BY$grid, TRAP])), by = grid]$V1)
man <- c(G2 = "after lethal snake treatments", G3 = "after lethal snake treatments", R4 = "after rats were trapped and euthanized")
long <- merge(cc, gl[, .(TRAP, x, y)], by = "TRAP", all.x = TRUE)
long <- long[, .(unit = TRAP, taxon = "RATTUS", y = as.integer(CHEWED), period, occasion, date = format(d),
                 treat = as.integer(period == 2L), cluster_id = grid, unit_island = ifelse(startsWith(grid, "G"), "Guam", "Rota"),
                 unit_x = x, unit_y = y, period_manipulation = ifelse(period == 2L, man[grid], "none"))]
stopifnot(nrow(long) == 6945, sum(is.na(long$unit_x)) == 605, uniqueN(long$unit) == 121 * 6 + 100 * 3)
taxa <- make_taxa("RATTUS", "Rattus", vernacularName = "Rats", taxonRank = "genus",
                  taxonRemarks = "chew-card marks identify rats, not the species (Rattus spp.)")
dataset <- list(
  title = "Rat detections on chew cards over five-night samplings at nine forest grids on Guam and Rota, 2018-2019",
  creator = "Hanslowe, Emma B.; Page, Douglas A.; Bailey, Larissa L.; Yackel Adams, Amy A.",
  pubDate = "2022", doi = "10.5066/P9FOS7Z8", sourceURL = "https://doi.org/10.5066/P9FOS7Z8",
  citation = "Hanslowe, E.B., Page, D.A., Bailey, L.L., and Yackel Adams, A.A., 2022, Spatial mark-recapture and chew card rat data on Guam and Rota, 2018-2019: U.S. Geological Survey data release, https://doi.org/10.5066/P9FOS7Z8.",
  paperDOI = "10.3897/neobiota.74.80242",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Chew-track cards on 100- or 121-station grids in nine forest plots on Guam and Rota, Mariana Islands, checked each night for five nights, to test whether chew cards index invasive rat density measured by spatial capture-recapture on the same grids. Three grids were sampled a second time after a density manipulation (snake removal on Guam, rat removal on Rota).",
  samplingProtocol = "Chew-track cards at every station of an 11 x 11 (or 10 x 10) grid, checked each morning for five consecutive nights and scored as chewed by a rat or not.",
  samplingProtocolCode = "chew_card", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "five consecutive nights within a sampling; period = the grid's first or second sampling", occasionKind = "time",
  taxonInclusion = "single", crs = "EPSG:32655",
  geographicCoverage = list(description = "Forest plots on Guam (4 grids) and Rota (5 grids), Mariana Islands",
                            boundingBox = list(west = 144.5361, east = 145.5084, south = 13.1651, north = 14.2697)),
  temporalCoverage = "2018-06/2019-07",
  coordinatesCoarsened = list(value = FALSE, method = "station UTM coordinates as published; none deposited for grid G4"),
  notShipped = list(live_trapping = "Mark recapture trapping effort.csv: live-trap SCR data; some stations hold two traps per night with no trap key and G4 has no layout (held for a ruling)",
                    camera_verification = "28 card-nights with a camera (validation subset)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:2, label = c("first sampling", "second sampling (after manipulation, G2, G3, R4 only)")),
                  script = "data/hanslowe_2022_marianas_rat_occ.R")
stage_dict_row(TABLE,
  description = "Rat chew-card detections on five consecutive nights at each of 1,026 card stations on nine forest grids on Guam and Rota, 2018-2019, with second samplings of three grids after density manipulations.",
  url = "https://doi.org/10.5066/P9FOS7Z8",
  reference = "Hanslowe, E.B., et al. (2022). Chew-cards can accurately index invasive rat densities in Mariana Island forests. NeoBiota 74:29-56.",
  doi_paper = "10.3897/neobiota.74.80242", doi_data = "10.5066/P9FOS7Z8", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Chew cards only; the live-trap SCR data are held (stations with two unkeyed traps, no G4 layout).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (with manipulation)", sampling_protocol = "chew_card",
  design = "Multi-session (1-2 samplings x 5 nights)", realm = "Terrestrial", country = "USA", coordinates = "As published",
  notes = "Invasive rats; Guam (US territory) and Rota (Northern Mariana Islands, US commonwealth).")
