#!/usr/bin/env Rscript
# Table:  rees_2023_victoria_cat_smr
# Source: Dryad, doi:10.5061/dryad.69p8cz95w, version 221931 (version 6), licence CC0 1.0 as shown on the Dryad dataset
#         page (asserted from the dataset JSON). Rees, M. W., Pascoe, J. H., Le Pla, M., Robley, A., Birnbaum, E. K.,
#         Wintle, B. A. & Hradsky, B. A. Data from: Mesopredator release among invasive predators: controlling red foxes
#         can increase feral cat density and alter their behaviour [Dataset]. Dryad.
# Paper:  Rees, M. W. et al. (2023). Mesopredator release among invasive predators: controlling red foxes can increase
#         feral cat density and alter their behaviour. Journal of Applied Ecology 60: 1100-1114,
#         doi:10.1111/1365-2664.14402. Not read; the design below is from the deposit.
# Data:   derived_data.zip only (fetched per file by batch 37; raw_data.zip, 7.7 GB of camera images and records, and
#         models.zip, fitted models, were not fetched). It holds, per survey session (Glenelg region 2018: grids Annya
#         'a', Cobboboonee 'c', Hotspur 'h', Mt Clay 'mc'; Otway Ranges 2017-2019: north 'n_17'.. and south 's_17'..):
#   capthists/mrch_<s>.RData: a secr mark-resight capthist (saveRDS format, read with readRDS; secr not needed):
#     a 0/1 array individual x occasion x trap of the identifiable cats (cats with a distinctive coat, tabby or
#     swirl: natural marks), detector 'proximity', attribute traps (station x, y and a 0/1 usage matrix station x
#     occasion; markocc all 0: every occasion is a sighting occasion) and Tu (station x occasion counts of sightings
#     the model treats as unmarked). ch_<s>.RData: the same individuals without Tu (identical array, asserted).
#   capthists/unm_<s>.csv (station x occasion: sightings of unmarked cats, black or otherwise unpatterned) and
#     unid_<s>.csv (sightings of identifiable-coat cats that could not be told apart); Tu = unm + unid exactly
#     (asserted; Mt Clay has no unm file and Tu = unid there). mrch.RData, mrch_otways / mrch_glenelg: the sessions
#     combined (lists of the same capthists, not used). masks*.RData, *_mask_df.RData: SCR habitat masks.
#   cat_id_detections.csv: every cat photograph (17,026: id_status identifiable / unidentifiable / unmarked, cat
#     name, coat type, grid, year, station, date-time), the record the capthists were built from (one detection per
#     cat x station x day). records_matt_lgnp.csv: station-years with coordinates (latitude/longitude and UTM x, y,
#     equal to the capthist trap x, y, asserted), deployment start and end, survey days and fox / cat / potoroo /
#     bandicoot detection flags (and two Lower Glenelg NP grids outside these sessions). cam_models.csv: camera
#     models per region.
# Mapping (spatial mark-resight, ruling 2026-11-06, E9; responseType count, unitKind individual): unit = the
#   source's cat name for an identifiable cat, plus the reserved units 'unmarked' (unm_<s>) and
#   'marked_unidentified' (unid_<s>); taxon FELCAT; trap = station (coordinates constant across years, asserted);
#   period = survey session (1-10, ordered by start date; grid and year in __periods); occasion = the source's
#   occasion, a 24-hour period counted from the station's deployment (every station's usage run starts at occasion 1
#   and lasts its survey days + 1, asserted; every capthist detection has a photograph of that cat at that station
#   on the calendar day occasion - 1 + deployment date or the day after, asserted), so no calendar date is shipped:
#   obs_deployment_date carries the station's deployment date. An identifiable cat has a row at every station x day of each session in whose capthist it
#   appears, with the station operating (usage 1); y = 1 if photographed there that day (the proximity detector:
#   0/1 per day). The reserved units have a row at every operating station x day of every session, y = the number
#   of such sightings (0 included). obs_trap_days = usage (1 on every row: rows exist only where the station
#   operated; effortColumn). surveyEvidence = effort_table (the usage matrix). __units: reserved flag, the cat's
#   coat type and grid, and the sessions it is in; marks are natural (coat pattern), so every identifiable cat is
#   marked for the whole of each session it is in. trap = the capthist's trap name: the station (Glenelg) or
#   station x year ('U080x2017', Otways, where most stations were re-positioned by up to 161 m between years);
#   __traps: x, y as in the capthist (UTM metres, zone 54 south; datum not stated), the station's latitude/longitude
#   as published in records_matt_lgnp (one position per station, so in 2018-2019 Otway sessions it can differ from
#   x, y by up to 161 m), grid and session.
#   Coordinates: as published. Feral cats are introduced in Australia, so IUCN (b) does not apply (non-native ruling);
#   no other taxon is in the table.
#   Two capthist 'individuals' are pairs of cats photographed together ('annya_swirl_ben_&_annya_swirl_motley',
#   'otway_swirl_venus_&_otway_swirl_peter'): the source kept them as individuals in its model; shipped as recorded
#   and flagged in __units (unit_pair = 1).
# Not shipped: the habitat masks (model inputs); the combined capthist lists (the same data); the per-photograph
#   records beyond the daily detections (cat_id_detections: rebuilt into the daily array and checked); the fox and
#   other-species flags of records_matt_lgnp (another survey's summary at the station-year level); fitted models.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "rees_2023_victoria_cat_smr"
meta_f <- file.path(RAW_DIR, TABLE, "dryad_dataset.json")
zip <- file.path(RAW_DIR, TABLE, "dryad_221931.part", "derived_data.zip")
if (!file.exists(meta_f) || !file.exists(zip)) {
  # the version zip holds 7.7 GB of images; fetch the dataset record and derived_data.zip alone
  meta_f <- download_cached("https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.69p8cz95w", TABLE, "dryad_dataset.json")
  fl <- fromJSON(download_cached("https://datadryad.org/api/v2/versions/221931/files", TABLE, "dryad_files.json"), simplifyVector = FALSE)
  f <- Filter(function(x) identical(x$path, "derived_data.zip"), fl[["_embedded"]][["stash:files"]])[[1]]
  zip <- download_cached(paste0("https://datadryad.org", f[["_links"]][["self"]][["href"]], "/download"), TABLE,
                         filename = "derived_data.zip", subdir = "dryad_221931.part")
}
meta <- fromJSON(meta_f)
stopifnot(identical(meta$license, "https://spdx.org/licenses/CC0-1.0.html"),
          identical(basename(meta[["_links"]][["stash:version"]][["href"]]), "221931"))
dd <- file.path(RAW_DIR, TABLE, "derived")
if (!dir.exists(file.path(dd, "derived_data"))) unzip(zip, exdir = dd)
dd <- file.path(dd, "derived_data")
ch_dir <- file.path(dd, "capthists")

S <- data.table(code = c("a", "c", "h", "mc", "n_17", "n_18", "n_19", "s_17", "s_18", "s_19"),
                grid = c("Annya", "Cobboboonee", "Hotspur", "Mt Clay", "North_2017", "North_2018", "North_2019",
                         "South_2017", "South_2018", "South_2019"),
                region = c(rep("Glenelg", 4), rep("Otway Ranges", 6)),
                grid_det = c("annya", "cobb", "hotspur", "mtclay", rep("north", 3), rep("south", 3)),
                year = c(rep(2018L, 4), 2017:2019, 2017:2019))
rec <- fread(file.path(dd, "records_matt_lgnp.csv"))
stopifnot(all(S$grid %in% rec$grid))
rec <- rec[grid %in% S$grid]
stopifnot(!anyDuplicated(rec[, .(grid, station)]),
          rec[, .(n = uniqueN(paste(latitude, longitude, x, y))), by = station][, all(n == 1L)])
det <- fread(file.path(dd, "cat_id_detections.csv"))
stopifnot(nrow(det) == 17026L, setequal(det$id_status, c("identifiable", "unidentifiable", "unmarked")))

rd <- function(f) if (file.exists(f)) as.matrix(read.csv(f, row.names = 1, check.names = FALSE)) else NULL
rows <- list(); units <- list(); traps_all <- list(); per <- list()
for (k in seq_len(nrow(S))) {
  s <- S$code[k]
  o <- readRDS(file.path(ch_dir, sprintf("mrch_%s.RData", s)))
  ch <- readRDS(file.path(ch_dir, sprintf("ch_%s.RData", s)))
  tr <- attr(o, "traps"); u <- attr(tr, "usage"); Tu <- attr(o, "Tu")
  unm <- rd(file.path(ch_dir, sprintf("unm_%s.csv", s))); unid <- rd(file.path(ch_dir, sprintf("unid_%s.csv", s)))
  if (is.null(unm)) { stopifnot(s == "mc"); unm <- unid * 0L }
  stopifnot(inherits(o, "capthist"), attr(tr, "detector")[1] == "proximity", all(attr(tr, "markocc") == 0L),
            identical(unclass(ch)[, , ], unclass(o)[, , ]), all(o %in% 0:1), all(u %in% 0:1),
            identical(rownames(unm), rownames(tr)), identical(rownames(unid), rownames(tr)),
            isTRUE(all.equal(unname(Tu), unname(unm + unid))), all(Tu[u == 0] == 0),
            all(apply(o, c(2, 3), sum)[t(u) == 0] == 0), all(apply(o, 1, sum) >= 1L))
  rs <- rec[grid == S$grid[k]]
  # capthist trap names: the station (Glenelg) or station_year with an 'x' (Otways, 'U080x2017')
  key <- if (S$region[k] == "Glenelg") rs$station else rs$station_year
  stopifnot(setequal(key, rownames(tr)))
  rs <- rs[match(rownames(tr), key)]
  rs[, trap := rownames(tr)]
  # the capthist's trap x, y (the model's) equal the records' x, y except in the 2018-2019 Otway sessions, where
  # most stations were re-positioned by up to 161 m and records_matt_lgnp keeps one position per station
  dxy <- sqrt((rs$x - tr$x)^2 + (rs$y - tr$y)^2)
  cat(sprintf("    traps whose capthist x, y differ from records_matt_lgnp: %d (max %.0f m)\n", sum(dxy > 0.01), max(dxy)))
  stopifnot(max(dxy) < 200)
  # occasion = day of the station's own deployment: every station's usage run starts at occasion 1 and lasts
  # survey_duration + 1 days (deployment and retrieval days inclusive), so occasion k at a station is its date_start
  # + k - 1 (asserted; the authors aligned deployments, so one occasion is not one calendar day across stations)
  first <- apply(u, 1, function(r) which(r == 1L)[1]); last <- apply(u, 1, function(r) max(which(r == 1L)))
  off <- rowSums(u) - rs$survey_duration
  cat(sprintf("  %s: station usage days - survey_duration: %s\n", S$grid[k], paste(names(table(off)), table(off), sep = " x", collapse = ", ")))
  stopifnot(all(first == 1L), all(last == rowSums(u)))
  d0 <- min(as.IDate(rs$date_start))
  nocc <- ncol(u)
  ids <- dimnames(o)[[1]]
  # daily detections rebuilt from the photographs: identifiable cats per station x day
  dk <- det[grid == S$grid_det[k] & year == S$year[k]]
  dk[, occ := as.integer(as.IDate(substr(date_time, 1, 10)) - as.IDate(rs$date_start[match(station, rs$station)]) + 1L)]
  re <- unique(dk[id_status == "identifiable", .(individual, station, occ)])
  w <- which(unclass(o) == 1L, arr.ind = TRUE)
  ob <- data.table(individual = ids[w[, 1]], occ = w[, 2], station = rs$station[w[, 3]])
  stopifnot(identical(rownames(u), rs$trap), identical(rownames(unm), rs$trap))
  re <- re[, .(individual, station, occ)]; ob <- ob[, .(individual, station, occ)]
  # lag between the photo's calendar day (counted from the deployment date) and the capthist occasion
  lag <- merge(ob, re[, .(individual, station, pocc = occ)], by = c("individual", "station"), allow.cartesian = TRUE)[
    , .(lag = min(abs(pocc - occ - 1L))), by = .(individual, station, occ)]
  cat(sprintf("    capthist detections with a photo at photo-day = occasion + 1 (+-0, 1, 2+): %s\n", paste(tabulate(pmin(lag$lag, 2L) + 1L, 3L), collapse = ", ")))
  stopifnot(nrow(lag) == nrow(ob), all(lag$lag <= 1L))
  cat(sprintf("  %-12s %2d cats, %3d stations, %2d days, %4d station-days, cat-days %d, unmarked %d, marked unidentified %d\n",
              S$grid[k], length(ids), nrow(tr), nocc, sum(u), sum(o), sum(unm), sum(unid)))
  op <- which(u == 1L, arr.ind = TRUE)
  op <- data.table(trap = rownames(u)[op[, 1]], occasion = op[, 2])
  cats <- CJ(unit = ids, k2 = seq_len(nrow(op)))
  cats[, `:=`(trap = op$trap[k2], occasion = op$occasion[k2])]
  cats[, y := unclass(o)[cbind(match(unit, ids), occasion, match(trap, rownames(tr)))]]
  res <- rbind(op[, .(unit = "unmarked", trap, occasion, y = unm[cbind(match(trap, rownames(unm)), occasion)])],
               op[, .(unit = "marked_unidentified", trap, occasion, y = unid[cbind(match(trap, rownames(unid)), occasion)])])
  r <- rbind(cats[, .(unit, trap, occasion, y)], res)
  r[, `:=`(session = s, obs_deployment_date = rs$date_start[match(trap, rs$trap)])]
  stopifnot(nrow(r) == (length(ids) + 2L) * sum(u), sum(r[!unit %in% c("unmarked", "marked_unidentified"), y]) == sum(o),
            sum(r[unit == "unmarked", y]) == sum(unm), sum(r[unit == "marked_unidentified", y]) == sum(unid))
  rows[[k]] <- r
  coat <- unique(det[individual %in% ids, .(individual, coat_type)])
  units[[k]] <- data.table(unit = ids, session = s, grid = S$grid_det[k], coat = coat$coat_type[match(ids, coat$individual)])
  traps_all[[k]] <- data.table(trap = rs$trap, station = rs$station, x = tr$x, y = tr$y, decimalLatitude = rs$latitude,
                               decimalLongitude = rs$longitude, grid = S$grid_det[k], session = s)
  per[[k]] <- data.table(session = s, grid = S$grid[k], region = S$region[k], year = S$year[k], start = format(d0),
                         end = format(max(as.IDate(rs$date_end))), n_days = nocc, n_stations = nrow(tr), n_station_days = sum(u),
                         n_identified_cats = length(ids))
}
long <- rbindlist(rows)
per <- rbindlist(per)[order(start)]
per[, period := seq_len(.N)]
long[, period := per$period[match(session, per$session)]]
long[, `:=`(taxon = "FELCAT", obs_trap_days = 1L)]
long <- order_eco(long[, .(unit, taxon, trap, period, occasion, y, obs_trap_days, obs_deployment_date = format(as.IDate(obs_deployment_date)))])
stopifnot(!anyDuplicated(long[, .(unit, trap, period, occasion)]),
          long[!unit %in% c("unmarked", "marked_unidentified"), max(y), by = unit][, all(V1 == 1L)])
cat(sprintf("  %s rows, %d identifiable cats, %d sightings of identified cats, %d unmarked, %d marked unidentified\n",
            format(nrow(long), big.mark = ","), uniqueN(long$unit) - 2L, sum(long[!unit %in% c("unmarked", "marked_unidentified"), y]),
            sum(long[unit == "unmarked", y]), sum(long[unit == "marked_unidentified", y])))

tr <- unique(rbindlist(traps_all))
stopifnot(!anyDuplicated(tr$trap))
traps <- tr[, .(trap, station, x, y, decimalLatitude, decimalLongitude, grid, session)]
uu <- rbindlist(units)
ucat <- uu[, .(unit_reserved = 0L, unit_mark = "natural (distinctive coat)", unit_coat = unique(coat), unit_grid = unique(grid),
               unit_sessions = paste(per$period[match(session, per$session)], collapse = ";"),
               unit_pair = as.integer(grepl("_&_", unit))), by = unit]
stopifnot(!anyNA(ucat$unit_coat), sum(ucat$unit_pair) == 2L)
units <- rbind(ucat,
               data.table(unit = c("unmarked", "marked_unidentified"), unit_reserved = 1L,
                          unit_mark = c("reserved: sightings of cats without a distinctive coat", "reserved: sightings of distinctive-coat cats that could not be identified"),
                          unit_coat = NA_character_, unit_grid = NA_character_, unit_sessions = paste(per$period, collapse = ";"), unit_pair = 0L))
periods <- per[, .(period, session, grid, region, year, start, end, n_days, n_stations, n_station_days, n_identified_cats)]
taxa <- make_taxa("FELCAT", "Felis catus", vernacularName = "Feral cat")

n_cats <- nrow(ucat)
dataset <- list(
  title = sprintf("Spatial mark-resight of feral cats at camera stations in ten surveys of the Glenelg region and Otway Ranges, Victoria, Australia, 2017-2019 (%d identifiable cats)", n_cats),
  creator = "Rees, Matthew W.; Pascoe, Jack H.; Le Pla, Mark; Robley, Alan; Birnbaum, Emily K.; Wintle, Brendan A.; Hradsky, Bronwyn A.",
  pubDate = "2023", doi = "10.5061/dryad.69p8cz95w", sourceURL = "https://doi.org/10.5061/dryad.69p8cz95w",
  citation = "Rees, M. W., Pascoe, J. H., Le Pla, M., Robley, A., Birnbaum, E. K., Wintle, B. A., & Hradsky, B. A. (2023). Data from: Mesopredator release among invasive predators: controlling red foxes can increase feral cat density and alter their behaviour [Dataset]. Dryad. https://doi.org/10.5061/dryad.69p8cz95w",
  paperDOI = "10.1111/1365-2664.14402",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap surveys of feral cats in three paired fox-baited and unbaited landscapes of the Glenelg region (2018) and a before-after control-impact series in the Otway Ranges (2017-2019), Victoria, Australia, analysed by the authors with spatial mark-resight models: cats with a distinctive coat (tabby, swirl) are identified individually from photographs; sightings of unpatterned cats and of patterned cats that could not be identified are counted per station and day.",
  samplingProtocol = "Camera traps at stations on grids within each landscape, deployed for about two to three months per survey; cat photographs sorted into identified individuals (natural coat marks), identifiable-coat cats that could not be identified, and unmarked (unpatterned) cats; one detection per cat per station per day.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "count", unitKind = "individual",
  closure = "closed", closureNote = "occasion = a 24-hour period counted from each station's deployment within a survey session (period), as the source aligned them (obs_deployment_date gives the station's deployment date); the authors' spatial mark-resight models treat each session as closed. Sessions in one grid (Otway north and south, 2017-2019) share cats, and an identifiable cat keeps its name across them.",
  occasionKind = "time", taxonInclusion = "single", effortColumn = "obs_trap_days",
  geographicCoverage = "Glenelg region (Annya, Cobboboonee, Hotspur, Mt Clay) and Otway Ranges (north and south grids), south-west Victoria, Australia",
  temporalCoverage = sprintf("%s/%s", min(per$start), max(per$end)),
  crs = "__traps x, y: UTM metres, zone 54 south (as in the source's capthists; datum not stated); decimalLatitude/decimalLongitude: WGS84 station positions from records_matt_lgnp",
  coordinatesCoarsened = list(value = FALSE, method = "Station coordinates as published. The feral cat is introduced in Australia, so its IUCN category does not flag it (E7, non-native ruling); the source states no sensitivity."),
  covariateNote = "obs_trap_days = 1 on every row (the station operated in that occasion; rows exist only where it did). obs_deployment_date = the station's deployment date in the session (occasion 1 begins then). __units: unit_reserved (1 for 'unmarked' and 'marked_unidentified'), unit_mark, unit_coat (the source's coat type), unit_grid, unit_sessions (the periods whose capthist lists the cat), unit_pair (1 for the two source 'individuals' that are a pair of cats photographed together). __periods: the survey session's grid, region, year and dates.",
  designNote = "Spatial mark-resight (E9 ruling 2026-11-06) with natural marks: each identifiable cat has a row at every operating station x day of the sessions it is in (marks are natural, so it is marked throughout); 'unmarked' and 'marked_unidentified' have a row at every operating station x day. The authors' model pooled the two reserved counts as unmarked sightings (Tu = unmarked + marked unidentified, asserted).",
  notes = "Identified cats are recorded as detected or not per station and day (0/1, the source's proximity detector); the reserved units count sightings per station and day. Two source 'individuals' are pairs of cats photographed together and are kept as the source modelled them (unit_pair = 1).",
  notShipped = list(masks = "SCR habitat masks (model inputs)", combined_capthists = "mrch.RData, mrch_otways, mrch_glenelg: lists of the same session capthists",
                    photographs = "cat_id_detections.csv photograph records beyond the daily detections they were reduced to",
                    other_species = "fox, potoroo and bandicoot station-year flags in records_matt_lgnp.csv (another survey summary)",
                    raw_and_models = "raw_data.zip (camera records, 7.7 GB) and models.zip (fitted models) were not fetched"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, traps = traps,
                  script = "data/rees_2023_victoria_cat_smr.R")
stage_dict_row(TABLE,
  description = sprintf("Spatial mark-resight of feral cats at camera stations in ten surveys of south-west Victoria, Australia, 2017-2019: daily detections of %d cats identified by coat pattern, and daily counts of unmarked and unidentifiable sightings, per station.", n_cats),
  url = "https://doi.org/10.5061/dryad.69p8cz95w",
  reference = "Rees, M. W., Pascoe, J. H., Le Pla, M., Robley, A., Birnbaum, E. K., Wintle, B. A., & Hradsky, B. A. (2023). Mesopredator release among invasive predators: controlling red foxes can increase feral cat density and alter their behaviour. Journal of Applied Ecology, 60, 1100-1114.",
  doi_paper = "10.1111/1365-2664.14402", doi_data = "10.5061/dryad.69p8cz95w",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Spatial mark-resight (ruling 2026-11-06): natural marks; reserved units unmarked and marked_unidentified. derived_data.zip only.",
  source_via = "Dryad (file download)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial mark-resight (camera traps)",
  sampling_protocol = "camera_trap", design = sprintf("Multi-session (%d surveys x %d-%d days)", nrow(per), min(per$n_days), max(per$n_days)),
  realm = "Terrestrial", country = "AUS", coordinates = "As published",
  notes = "Experimental (E9): spatial mark-resight, natural marks, trap key + __traps + __units.")
