#!/usr/bin/env Rscript
# Table:  bauer_2022_neshrubland_birds_count
# Source: Dryad, doi:10.5061/dryad.c866t1g7n, version 164789 (version 6, published 2022-02-21), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Bauer, M. L., O'Brien, K. M. & Kovach, A. I. (2022). Can at-risk species serve as effective conservation
#         surrogates? Case study in northeastern US shrublands. Ecosphere 13: e4081. https://doi.org/10.1002/ecs2.4081
#         (not read: the publisher page refuses scripted requests). Design from the Dryad methods, README.txt and
#         the spreadsheets' metadata tabs: bird point counts in May-July 2015 and 2016 at shrubland sites managed
#         for (or occupied by) New England cottontail in southern Maine, seacoast New Hampshire and Cape Cod,
#         Massachusetts, under the U.S. Fish and Wildlife Service landbird monitoring SOP: 10-minute counts, three
#         visits per point per year, every bird recorded by minute, distance bin (0-25, 26-50, 51-100, >100 m) and
#         detection type (visual, auditory, both, flyover). The authors analysed the 0-25 and 26-50 m bins and
#         excluded flyovers. Vegetation measured at the points in 2017. Coordinates withheld by the source (private
#         landowners; a state-endangered species).
# Data:   pointcount.xls, sheet pointcount (4,673 records): State, PointID, VisitNum (1-3), Date, Observer (LC, ME),
#           Recorder (DS, SC, n/a or blank), Start, End (times), TempF ("NA" in 248 records), Sky, WindSp (-999 = no
#           data), WindDir (n/a, NR = not recorded), Noise (-999 = no data), AlphaCode (AOU 4-letter code, or a
#           "<group> sp." label), Type (V, A, B, F), Distance (25, 50, 100, 101), TotalCount, Min0..Min9 (count per
#           minute). A record is one species x type x distance bin within a visit (248 records repeat a key and are
#           summed). Sheet metadata: the column definitions.
#           330 point-visits: 44 points x 3 visits in 2015 and all 66 points x 3 visits in 2016 (asserted), so every
#           point-year has its three visits. Visit fields agree within a visit except Recorder (blank vs "n/a",
#           both read as none), Start at one visit (Gull3 2015 visit 1: 12 different start times, the earliest used)
#           and End at two visits (the latest used) (asserted).
#           TotalCount equals the sum of Min0..Min9 in all but 7 records, 2 of them within 50 m and not flyovers
#           (Cutts2 2015 visit 2 BCCH: total 1, minute 2 = 3; Houde1 2015 visit 2 PRAW: total 1, no minute);
#           y uses TotalCount, the intervals ship as deposited.
#           WOSP (3 auditory records) is not an AOU / IBP alpha code and is not defined by the source: dropped.
#         vegetation.xls, sheet vegetation: 66 points (PointID "Q_SIte2" there is "Q_Site2" in the counts; asserted
#           as the only mismatch), 2017 means of snags, woody debris, brush piles, stem count, overstory, understory
#           height, woody invasives, vegetation hits by height band, woody plant richness. Sheet patch area: Site
#           (28 management units, = PointID without its trailing point number) and PatchArea (ha). Sheet metadata.
#         README.txt.
# Mapping: repeated point counts (N-mixture / community abundance). unit = PointID, cluster_id = site (management
#   unit), taxon = AOU alpha code (group labels get codes, below), period = year (1 = 2015, 2 = 2016), occasion =
#   VisitNum, date = Date, observer = Observer. y = birds of the species counted within 50 m, flyovers excluded
#   (the authors' analysed set: TotalCount summed over the visit's 0-25 and 26-50 m, non-flyover records);
#   obs_int1..obs_int10 = the same records' minute counts (Min0..Min9; within-visit intervals ruling);
#   obs_n_51_100m, obs_n_over100m = non-flyover birds in the outer bins; obs_n_flyover = flyovers at any distance.
#   Community rule: every taxon counted within 50 m (non-flyover) at least once (79 of 93) carries a row at every
#   point-visit; the 14 taxa recorded only beyond 50 m or as flyovers have no rows (taxonInclusion recorded). surveyEvidence = row_presence
#   (a point-visit exists where it has a record; all 330 expected visits are present, asserted).
#   Visit covariates: obs_recorder, obs_start_time, obs_end_time (HH:MM), obs_temp_f, obs_sky_code,
#   obs_wind_code, obs_wind_dir, obs_noise_code (codes in covariateNote; -999 to NA). unit_state, unit_* the
#   2017 vegetation means, unit_patch_area_ha.
#   Taxa: alpha codes via data/aux/bird_alpha_codes.csv, the 18 codes missing there given here from the
#   IBP-AOS list; YPWA (Yellow Palm Warbler) and YSFL (Yellow-shafted Flicker) at subspecies; group labels at the
#   rank they name (Coccyzus, Empidonax, Icteridae, Anatidae, Accipitridae; gull and tern both Laridae).
#   No coordinates in the source; no taxon-level coarsening question arises.
#   Not shipped: WOSP; model outputs (occupancy and indicator-species results).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "bauer_2022_neshrubland_birds_count"

dir <- download_dryad("10.5061/dryad.c866t1g7n", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("pointcount.xls", "README.txt", "vegetation.xls")))
pc <- as.data.table(read_excel(file.path(dir, "pointcount.xls"), sheet = "pointcount"))
MIN <- paste0("Min", 0:9)
stopifnot(identical(names(pc), c("State", "PointID", "VisitNum", "Date", "Observer", "Recorder", "Start", "End", "TempF",
                                 "Sky", "WindSp", "WindDir", "Noise", "AlphaCode", "Type", "Distance", "TotalCount", MIN)),
          nrow(pc) == 4673L, all(pc$VisitNum %in% 1:3), all(pc$Type %in% c("V", "A", "B", "F")),
          all(pc$Distance %in% c(25, 50, 100, 101)), all(pc$TotalCount >= 1), !anyNA(pc[, ..MIN]),
          all(pc$Observer %in% c("LC", "ME")), all(pc$State %in% c("MA", "ME", "NH")))
pc[, date := as.IDate(Date)][, yr := year(date)]
stopifnot(all(pc$yr %in% 2015:2016), all(month(pc$date) %in% 5:7))
smin <- rowSums(pc[, ..MIN])
stopifnot(sum(pc$TotalCount != smin) == 7L, sum(pc$TotalCount != smin & pc$Type != "F" & pc$Distance <= 50) == 2L)
stopifnot(sum(pc$AlphaCode == "WOSP") == 3L)
pc <- pc[AlphaCode != "WOSP"]

# visits
pc[, Recorder := ifelse(is.na(Recorder) | Recorder == "n/a", NA_character_, Recorder)]
hm <- function(x) format(x, "%H:%M")
vis <- pc[, .(State = unique(State), date = unique(date), observer = unique(Observer),
              obs_recorder = unique(na.omit(Recorder))[1], n_rec = uniqueN(na.omit(Recorder)),
              n_start = uniqueN(Start), n_end = uniqueN(End),
              obs_start_time = hm(min(Start)), obs_end_time = hm(max(End)),
              TempF = unique(TempF), Sky = unique(Sky), WindSp = unique(WindSp), WindDir = unique(WindDir),
              Noise = unique(Noise)), by = .(PointID, yr, VisitNum)]
stopifnot(nrow(vis) == 330L, all(vis$n_rec <= 1L), sum(vis$n_start > 1L) == 1L, sum(vis$n_end > 1L) == 2L,
          vis[n_start > 1L, PointID] == "Gull3",
          identical(as.vector(table(vis$yr)), c(132L, 198L)),
          vis[, uniqueN(VisitNum), by = .(PointID, yr)][, all(V1 == 3L)],
          uniqueN(vis[yr == 2015, PointID]) == 44L, uniqueN(vis[yr == 2016, PointID]) == 66L,
          all(vis[yr == 2015, PointID] %in% vis[yr == 2016, PointID]), vis[, uniqueN(State), by = PointID][, all(V1 == 1L)])
nomiss <- function(x, miss) { x <- suppressWarnings(as.numeric(x)); x[x %in% miss] <- NA; x }
vis[, `:=`(obs_temp_f = nomiss(TempF, numeric()), obs_sky_code = as.integer(Sky), obs_wind_code = as.integer(nomiss(WindSp, -999)),
           obs_wind_dir = WindDir, obs_noise_code = as.integer(nomiss(Noise, -999)))]
stopifnot(sum(is.na(vis$obs_temp_f)) == uniqueN(pc[TempF == "NA", .(PointID, yr, VisitNum)]))

# per visit x taxon
inn <- pc[Type != "F" & Distance <= 50]
agg <- inn[, c(list(y = sum(TotalCount)), lapply(.SD, sum)), by = .(PointID, yr, VisitNum, AlphaCode), .SDcols = MIN]
setnames(agg, MIN, paste0("obs_int", 1:10))
out <- pc[, .(obs_n_51_100m = sum(TotalCount[Type != "F" & Distance == 100]),
              obs_n_over100m = sum(TotalCount[Type != "F" & Distance == 101]),
              obs_n_flyover = sum(TotalCount[Type == "F"])), by = .(PointID, yr, VisitNum, AlphaCode)]
codes <- sort(unique(pc$AlphaCode))
stopifnot(length(codes) == 93L)
grid <- CJ(k = seq_len(nrow(vis)), AlphaCode = codes)
grid <- cbind(vis[grid$k, .(PointID, yr, VisitNum)], grid[, .(AlphaCode)])
long <- merge(grid, agg, by = c("PointID", "yr", "VisitNum", "AlphaCode"), all.x = TRUE)
long <- merge(long, out, by = c("PointID", "yr", "VisitNum", "AlphaCode"), all.x = TRUE)
num <- c("y", paste0("obs_int", 1:10), "obs_n_51_100m", "obs_n_over100m", "obs_n_flyover")
for (c in num) set(long, which(is.na(long[[c]])), c, 0)
for (c in num) set(long, j = c, value = as.integer(long[[c]]))
stopifnot(sum(long$y) == sum(inn$TotalCount), sum(long$obs_n_flyover) == sum(pc[Type == "F"]$TotalCount),
          sum(long$y) + sum(long$obs_n_51_100m) + sum(long$obs_n_over100m) + sum(long$obs_n_flyover) == sum(pc$TotalCount))

# units
veg <- as.data.table(read_excel(file.path(dir, "vegetation.xls"), sheet = "vegetation"))
pa <- as.data.table(read_excel(file.path(dir, "vegetation.xls"), sheet = "patch area"))
stopifnot(nrow(veg) == 66L, identical(setdiff(veg$PointID, vis$PointID), "Q_SIte2"),
          identical(setdiff(vis$PointID, veg$PointID), "Q_Site2"), nrow(pa) == 28L, !anyNA(veg))
veg[PointID == "Q_SIte2", PointID := "Q_Site2"]
setnames(veg, c("PointID", "unit_snags_small", "unit_snags_medium", "unit_snags_large", "unit_debris_small",
                "unit_debris_medium", "unit_debris_large", "unit_brushpiles", "unit_stem_count", "unit_prop_overstory",
                "unit_understory_height", "unit_prop_woody_invasives", "unit_hits_0_1m", "unit_hits_1_2m",
                "unit_hits_2_3m", "unit_woody_richness"))
site <- data.table(PointID = unique(vis$PointID))[, site := sub("[0-9]+$", "", PointID)]
stopifnot(setequal(site$site, pa$Site))
site <- merge(site, pa[, .(site = Site, unit_patch_area_ha = PatchArea)], by = "site")
site <- merge(site, unique(vis[, .(PointID, unit_state = State)]), by = "PointID")
site <- merge(site, veg, by = "PointID")
stopifnot(nrow(site) == 66L)

long <- merge(long, vis[, .(PointID, yr, VisitNum, date, observer, obs_recorder, obs_start_time, obs_end_time, obs_temp_f,
                            obs_sky_code, obs_wind_code, obs_wind_dir, obs_noise_code)], by = c("PointID", "yr", "VisitNum"))
long <- merge(long, site, by = "PointID")
setnames(long, c("PointID", "AlphaCode", "site", "VisitNum"), c("unit", "taxon_src", "cluster_id", "occasion"))
long[, `:=`(period = yr - 2014L, occasion = as.integer(occasion))][, yr := NULL]

# taxa
GROUP <- data.table(
  taxon_src = c("Blackbird sp.", "Cuckoo sp.", "Duck sp.", "Empidonax sp.", "Gull sp.", "Hawk sp.", "Tern sp."),
  taxon = c("BLACKBIRD_SP", "CUCKOO_SP", "DUCK_SP", "EMPIDONAX_SP", "GULL_SP", "HAWK_SP", "TERN_SP"),
  scientificName = c("Icteridae", "Coccyzus", "Anatidae", "Empidonax", "Laridae", "Accipitridae", "Laridae"),
  commonName = c("blackbird, unidentified", "cuckoo, unidentified", "duck, unidentified", "Empidonax flycatcher, unidentified",
                 "gull, unidentified", "hawk, unidentified", "tern, unidentified"),
  taxonRank = c("family", "genus", "family", "genus", "family", "family", "family"),
  taxonRemarks = c("deposited as 'Blackbird sp.'; family Icteridae", "deposited as 'Cuckoo sp.'; genus Coccyzus (the only cuckoos of the region)",
                   "deposited as 'Duck sp.'; family Anatidae", "deposited as 'Empidonax sp.'",
                   "deposited as 'Gull sp.'; family Laridae (the backbone holds no gull subfamily)", "deposited as 'Hawk sp.'; family Accipitridae",
                   "deposited as 'Tern sp.'; family Laridae (the backbone holds no tern subfamily)"))
stopifnot(all(GROUP$taxon_src %in% codes))
alpha <- fread(file.path(ECO_ROOT, "data", "aux", "bird_alpha_codes.csv"))[, .(code, commonName, scientificName)]
extra <- data.table(
  code = c("ABDU", "BOBO", "COLO", "DCCO", "EUST", "GBBG", "GLIB", "GREG", "GRHE", "HERG", "HOSP", "KILL", "OSPR",
           "PUFI", "WILL", "WTSP", "YPWA", "YSFL"),
  commonName = c("American Black Duck", "Bobolink", "Common Loon", "Double-crested Cormorant", "European Starling",
                 "Great Black-backed Gull", "Glossy Ibis", "Great Egret", "Green Heron", "Herring Gull", "House Sparrow",
                 "Killdeer", "Osprey", "Purple Finch", "Willet", "White-throated Sparrow", "Yellow Palm Warbler",
                 "Yellow-shafted Flicker"),
  scientificName = c("Anas rubripes", "Dolichonyx oryzivorus", "Gavia immer", "Phalacrocorax auritus", "Sturnus vulgaris",
                     "Larus marinus", "Plegadis falcinellus", "Ardea alba", "Butorides virescens", "Larus argentatus",
                     "Passer domesticus", "Charadrius vociferus", "Pandion haliaetus", "Haemorhous purpureus",
                     "Tringa semipalmata", "Zonotrichia albicollis", "Setophaga palmarum hypochrysea", "Colaptes auratus auratus"))
stopifnot(!any(extra$code %in% alpha$code))
sp <- setdiff(codes, GROUP$taxon_src)
alpha <- rbind(alpha[code %in% sp], extra)
stopifnot(setequal(alpha$code, sp), !anyDuplicated(alpha$code), length(sp) == 86L)
alpha <- alpha[match(sp, code)]
tx <- rbind(alpha[, .(taxon_src = code, taxon = code, scientificName, commonName,
                      taxonRank = ifelse(code %in% c("YPWA", "YSFL"), "subspecies", "species"),
                      taxonRemarks = ifelse(code == "YPWA", "IBP alpha code for the yellow (eastern) subspecies group of Palm Warbler",
                                            ifelse(code == "YSFL", "IBP alpha code for the yellow-shafted subspecies group of Northern Flicker", NA_character_)))],
            GROUP)
long <- merge(long, tx[, .(taxon_src, taxon)], by = "taxon_src")[, taxon_src := NULL]
# taxonInclusion = recorded: a taxon is on the list if it was counted within 50 m (not flying over) at least once
pos <- long[, sum(y), by = taxon][V1 > 0, taxon]
outer_only <- setdiff(tx$taxon, pos)
stopifnot(length(outer_only) == 14L, length(pos) == 79L)
cat("  recorded only beyond 50 m or as flyovers (no rows):", paste(sort(outer_only), collapse = ", "), "\n")
long <- long[taxon %in% pos]; tx <- tx[taxon %in% pos]
taxa <- make_taxa(tx$taxon, tx$scientificName, vernacularName = tx$commonName, taxonRank = tx$taxonRank,
                  taxonRemarks = tx$taxonRemarks)
long <- order_eco(long)
stopifnot(nrow(long) == 330L * 79L, uniqueN(long$unit) == 66L, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d rows, %d point-visits, %d taxa, %d birds within 50 m (non-flyover)\n", nrow(long), 330L,
            uniqueN(long$taxon), sum(long$y)))
periods <- data.table(period = 1:2, year = 2015:2016, season = "May-July (breeding season)", n_points = c(44L, 66L))

dataset <- list(
  title = "Repeated 10-minute bird point counts (three visits a year) at 66 points in New England cottontail shrublands, Maine, New Hampshire and Massachusetts, 2015-2016",
  creator = "Bauer, Melissa; O'Brien, Kathleen; Kovach, Adrienne", pubDate = "2022",
  doi = "10.5061/dryad.c866t1g7n", sourceURL = "https://doi.org/10.5061/dryad.c866t1g7n",
  citation = "Bauer, M., O'Brien, K., & Kovach, A. (2022). Can at-risk species serve as effective conservation surrogates? Case study in northeastern US shrublands [Dataset]. Dryad. https://doi.org/10.5061/dryad.c866t1g7n",
  paperDOI = "10.1002/ecs2.4081",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Bird point counts at shrubland sites managed for, or occupied by, the New England cottontail in southern Maine, seacoast New Hampshire and Cape Cod, to test whether management for this at-risk rabbit benefits shrubland-obligate birds. Three 10-minute counts per point in May-July of 2015 (44 points) and 2016 (66 points), birds recorded by minute, distance bin and detection type; vegetation measured at the points in 2017.",
  samplingProtocol = "U.S. Fish and Wildlife Service landbird monitoring SOP: 10-minute point counts, three visits per point per breeding season, every bird recorded by minute, distance bin (0-25, 26-50, 51-100, >100 m) and detection type (visual, auditory, both, flyover), with weather and noise; y is the count within 50 m excluding flyovers (the authors' analysed set).",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "three visits per point within one breeding season (May-July) are the occasions; years are periods",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Southern Maine, seacoast New Hampshire and Cape Cod, Massachusetts, USA (coordinates withheld by the source to protect private landowners and a state-endangered species)",
  temporalCoverage = "2015-05/2016-07",
  covariateNote = "y: birds within 50 m, flyovers excluded. obs_int1..obs_int10: the same birds by minute 0..9 of the count (as deposited; sum equals y except two records, see notes). obs_n_51_100m, obs_n_over100m: non-flyover birds at 51-100 m and >100 m. obs_n_flyover: flyovers at any distance. obs_sky_code: 0 clear or few clouds, 1 partly cloudy, 2 cloudy or overcast, 4 fog or smoke, 5 drizzle, 7 snow, 8 showers. obs_wind_code: 0 <1 mph, 1 1-3, 2 4-7, 3 8-12, 4 13-18, 5 19-24, 6 >=25 mph (NA = no data). obs_wind_dir as deposited (n/a = calm, NR = not recorded, VBL = variable). obs_noise_code: 0 none (<40 dB), 1 faint, 2 moderate, 3 loud, 4 intense (NA = no data). obs_temp_f: degrees F at start. obs_recorder: assistant's initials (NA = none). unit_* vegetation: 2017 means over 20 plots within 50 m of the point (snags and woody debris by size class, brush piles, stems per 1x2 m plot, overstory proportion, representative understory height, proportion woody invasive, pole hits by height band, woody plant richness); unit_patch_area_ha: area of the management unit (cluster_id).",
  notShipped = list(outer_only_taxa = "14 taxa recorded only beyond 50 m or as flyovers, never in the analysed set (BLACKBIRD_SP, BWHA, CUCKOO_SP, DCCO, DUCK_SP, GBBG, GLIB, GREG, GULL_SP, HAWK_SP, RTHA, TERN_SP, TUVU, WOTH): no rows, since taxonInclusion = recorded lists taxa counted within 50 m",
                    WOSP = "3 auditory records under WOSP, which is not an AOU / IBP alpha code and is not defined by the source",
                    model_output = "indicator-species, occupancy and richness model results"),
  notes = "Every taxon counted within 50 m at least once (79 of the 93 labels in the deposit) has a row at every point-visit; the obs_ distance and flyover columns carry those taxa's other records, and the 14 taxa recorded only beyond 50 m or as flyovers are not in the table. TotalCount and the minute counts disagree in two within-50-m records (Cutts2 2015 visit 2 BCCH: total 1, minute 2 = 3; Houde1 2015 visit 2 PRAW: total 1, no minute recorded); y uses the total. Gull3 2015 visit 1 has 12 different start times in the deposit (the earliest is obs_start_time); two visits have two end times (the latest is used). Vegetation was measured in 2017, after the counts. 22 points were counted in 2016 only.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/bauer_2022_neshrubland_birds_count.R")
stage_dict_row(TABLE,
  description = "Repeated 10-minute bird point counts (three visits per year, 2015-2016) at 66 points in shrublands managed for New England cottontail, Maine, New Hampshire and Massachusetts; counts within 50 m with minute intervals, outer-bin and flyover counts, weather and vegetation.",
  url = "https://doi.org/10.5061/dryad.c866t1g7n",
  reference = "Bauer, M. L., O'Brien, K. M., & Kovach, A. I. (2022). Can at-risk species serve as effective conservation surrogates? Case study in northeastern US shrublands. Ecosphere, 13, e4081. https://doi.org/10.1002/ecs2.4081",
  doi_paper = "10.1002/ecs2.4081", doi_data = "10.5061/dryad.c866t1g7n",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Record table to point-visit x taxon counts (within 50 m, no flyovers, as the authors analysed); all 330 visits present; WOSP dropped (undefined code).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species)",
  sampling_protocol = "point_count", design = "Multi-season (2 years x 3 visits; 66 points)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Shrubland birds at New England cottontail management sites; minute intervals and distance bins as obs_ columns.")
