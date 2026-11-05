#!/usr/bin/env Rscript
# Table:  iannarilli_2026_snapshoteurope_comm
# Source: Edmond (Max Planck data repository) doi:10.17617/3.7YLWMU, "Dataset associated with
#         'Snapshot Europe 2021-2022: The first public dataset from a Europe-wide camera-trap survey
#         of terrestrial vertebrates'", Iannarilli, Keeves von Wolff, Wikelski, Heurich, Kays,
#         Cagnacci et al.; version 2, released 2026-07-13. Licence shown on Edmond: CC BY-SA 4.0.
#         The Wildlife Insights export inside the deposit states metadata_license = CC-BY and
#         image_license = CC-BY-NC in the projects file, and every sequence row carries
#         license = "CC-BY-NC". The NC field is Wildlife Insights' image licence (no images ship
#         here), but because the deposited rows say CC-BY-NC the stricter combination governs
#         (processing_guide.md): derived_license = CC BY-NC-SA 4.0, all three in original_license.
# Paper:  Iannarilli, F., et al. (in press, accepted 2026-02-27). Snapshot Europe 2021-2022: The first
#         public dataset from a Europe-wide camera-trap survey of terrestrial vertebrates. Ecology.
#         Not on Crossref as of 2026-11-05. Related: Sollmann et al., Zenodo 10.5281/zenodo.17939002,
#         which re-uses a subset of these records (not used here).
# Data:   DataS1.zip (ReadME.txt points to the paper's metadata file, which is not in the deposit):
#           Snapshot_Europe_2021_2022_projects.csv   3 rows: WI project x initiative, licences.
#           Snapshot_Europe_2021_2022_cameras.csv    1,198 camera bodies (make/model mostly blank).
#           Snapshot_Europe_2021_2022_deployments.csv 2,596 deployments (2021: 1,392; 2022: 1,204):
#             deployment_id (unique), placename (camera location; 2,117 names), WGS 84 coordinates
#             (published to 5-6 decimals), start_date and end_date (dates; time 00:00:00, end
#             23:59:59 on 166 rows), camera_functioning (2,503 "Camera Functioning"; 93 declare a
#             failure: Unknown Failure 43, Memory Card 24, Theft 12, Camera Hardware Failure 11,
#             Vandalism 2, Wildlife Damage 1), feature_type, sensor_height, quiet_period,
#             subproject_name (array-year, 136) and subproject_name_no_year (array, 106). bait_type
#             is "None" on every row.
#           Snapshot_Europe_2021_2022_sequences.csv  126,460 rows, one per identification per
#             camera sequence (Mammalia 116,802, Aves 9,658), WI taxonomy, start_time, group_size.
#             A sequence_id can carry several rows (several labels in one sequence). Every row's
#             deployment is in the deployments file and every start_time falls inside its
#             deployment's start-end dates (asserted).
#           Snapshot_Europe_2021_2022_images.csv     420 MB, one row per image: not read (the
#             sequences file is the detection record).
# Mapping (community detection from a sequence table with a deployment table, aggregated to
# camera-weeks, as rooney_2025_snapshotusa_comm):
#   unit = deployment, replaced by a sequential id D0001.. (E7.4: deployment ids, placenames and
#   array names name places: national parks, reserves, estates); cluster_id = array
#   (subproject_name_no_year) as A001..; __units carries a sequential site_id (placename, linking
#   deployments at one location within and across years). period = survey year (1 = 2021,
#   2 = 2022). occasion = 7-day window from the deployment's start date (the last window partial;
#   obs_camera_days = days of the window inside the deployment, start and end dates inclusive);
#   date = first day of the window. y = 1 if the taxon has at least one sequence in that
#   camera-week, y_raw = number of distinct sequences. taxon = every mammal identified to species
#   except humans (domestic animals included), codes from genus + species; __taxa has the GBIF key,
#   the WI common name and the number of sequences.
#   Survey evidence: the deployment table (a camera-day exists iff start <= day <= end), so
#   surveyEvidence = effort_table, for the 2,503 deployments that report "Camera Functioning". The
#   93 deployments that declare a failure are not shipped: end_date is the retrieval date (in some of
#   them the last sequence is up to 36 days before it) and the deposit does not say when the camera
#   stopped, so their camera-days cannot be evidenced. Their sequences are not shipped either.
#   Coordinates: exact in the source. Shipped taxa include the European rabbit (Oryctolagus
#   cuniculus, IUCN EN in its native range; recorded in Portugal and Spain arrays), the mountain
#   gazelle (EN, Israel), garden dormouse and Italian hare (VU), so every unit's coordinates are coarsened to the 0.1-degree
#   cell centre (one unit set serves all taxa; standard E7). No exact-coordinate sibling is built.
#   v1.1: closure = closed (camera-weeks of one deployment), occasionKind = time,
#   taxonInclusion = recorded.
#   Not shipped: birds (78 species-level labels, 9,658 rows; the survey targets mammals and bird
#   tagging differs by contributor), labels above species rank, humans, the failed deployments,
#   group size / age / sex (per-sequence attributes), the images file.
#   Identification note: WI labels are shipped as deposited. "Common Water Rat" (Hydromys
#   chrysogaster, an Australasian species) is recorded at European cameras; it is kept with a
#   taxonRemarks warning rather than reassigned.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "iannarilli_2026_snapshoteurope_comm"

# --- source files -------------------------------------------------------------------------
zip <- download_cached("https://edmond.mpg.de/api/access/datafile/345505", TABLE, filename = "DataS1.zip")
stopifnot(file.size(zip) == 77352666)
raw <- file.path(RAW_DIR, TABLE, "DataS1")
need <- paste0("Snapshot_Europe_2021_2022_", c("projects", "cameras", "deployments", "sequences"), ".csv")
if (!all(file.exists(file.path(raw, need)))) unzip(zip, files = file.path("DataS1", need), exdir = file.path(RAW_DIR, TABLE))
stopifnot(setequal(unzip(zip, list = TRUE)$Name[unzip(zip, list = TRUE)$Length > 0],
                   file.path("DataS1", c(need, "Snapshot_Europe_2021_2022_images.csv"))))
rd <- function(f) fread(file.path(raw, paste0("Snapshot_Europe_2021_2022_", f, ".csv")), encoding = "UTF-8",
                        colClasses = list(character = intersect(c("start_date", "end_date", "start_time"),
                          names(fread(file.path(raw, paste0("Snapshot_Europe_2021_2022_", f, ".csv")), nrows = 0)))))
prj <- rd("projects"); dep <- rd("deployments"); seq <- rd("sequences")
stopifnot(nrow(prj) == 3, all(prj$metadata_license == "CC-BY"), all(prj$image_license == "CC-BY-NC"),
          nrow(dep) == 2596, ncol(dep) == 31, !anyDuplicated(dep$deployment_id),
          identical(as.integer(table(dep$year)), c(1392L, 1204L)),
          uniqueN(dep$placename) == 2117, uniqueN(dep$subproject_name) == 136, uniqueN(dep$subproject_name_no_year) == 106,
          all(dep$bait_type == "None"), !anyNA(dep$latitude), !anyNA(dep$longitude),
          nrow(seq) == 126460, all(seq$license == "CC-BY-NC"), all(seq$is_blank == 0),
          identical(sort(unique(seq$class)), c("Aves", "Mammalia")))

# --- deployments: the survey set ----------------------------------------------------------
stopifnot(all(substr(dep$start_date, 12, 19) == "00:00:00"), all(substr(dep$end_date, 12, 19) %in% c("00:00:00", "23:59:59")))
dep[, st := as.IDate(substr(start_date, 1, 10))][, en := as.IDate(substr(end_date, 1, 10))]
stopifnot(!anyNA(dep$st), !anyNA(dep$en), all(dep$en >= dep$st), all(year(dep$st) == dep$year))
fails <- dep[camera_functioning != "Camera Functioning", .N, by = camera_functioning]
stopifnot(sum(fails$N) == 93, dep[camera_functioning == "Camera Functioning", .N] == 2503)
fail_ids <- dep[camera_functioning != "Camera Functioning", deployment_id]
dep <- dep[camera_functioning == "Camera Functioning"]
dep[, span_days := as.integer(en - st) + 1L]
cat(sprintf("  %d functioning deployments (93 with a declared failure dropped) at %d placenames in %d arrays, %d-%d days\n",
            nrow(dep), uniqueN(dep$placename), uniqueN(dep$subproject_name_no_year), min(dep$span_days), max(dep$span_days)))

weeks <- dep[, .(occasion = seq_len(ceiling(span_days / 7))), by = .(deployment_id, year, st, en, span_days)]
weeks[, wstart := st + (occasion - 1L) * 7L][, wend := pmin(wstart + 6L, en)]
weeks[, obs_camera_days := as.integer(wend - wstart) + 1L]
stopifnot(all(weeks$obs_camera_days %between% c(1L, 7L)),
          weeks[, sum(obs_camera_days), by = deployment_id][dep, on = "deployment_id"][, all(V1 == span_days)])

# --- sequences ----------------------------------------------------------------------------
seq[, dt := as.IDate(as.POSIXct(start_time, tz = "UTC"))]
stopifnot(!anyNA(seq$dt), nrow(seq[!rd("deployments"), on = .(deployment_id, year)]) == 0)
win <- rd("deployments")[, .(deployment_id, st = as.IDate(substr(start_date, 1, 10)), en = as.IDate(substr(end_date, 1, 10)))]
stopifnot(seq[win, on = "deployment_id", nomatch = NULL][, all(dt >= st & dt <= en)])   # every sequence inside its deployment
n_fail_rows <- seq[deployment_id %in% fail_ids, .N]
seq <- seq[deployment_id %in% dep$deployment_id]

mam <- seq[class == "Mammalia" & species != "" & genus != "" & genus != "Homo"]
species <- mam[, .(n_rows = .N, n_seq = uniqueN(sequence_id), common_name = paste(unique(common_name), collapse = " / ")),
               by = .(order, family, genus, species)][order(-n_seq)]
species[, scientificName := paste(genus, species)][, lookupName := scientificName]
species[scientificName == "Capra aegagrus hircus", `:=`(scientificName = "Capra hircus", lookupName = "Capra hircus")]   # WI trinomial, domestic goat
species[scientificName == "Sus scrofa scrofa", `:=`(scientificName = "Sus scrofa domesticus", lookupName = "Sus scrofa domesticus")]  # WI "Domestic Pig"
species[, taxon := toupper(paste0(substr(genus, 1, 3), substr(sub(".* ", "", scientificName), 1, 3)))]
species[scientificName == "Marmota marmota", taxon := "MARMOM"]   # MARMAR is Martes martes
stopifnot(!anyDuplicated(species$taxon), !anyDuplicated(species$scientificName))
cat(sprintf("  %d mammal species (excluding humans), %d sequence rows\n", nrow(species), sum(species$n_rows)))

# --- long table: camera-week x taxon ------------------------------------------------------
sp <- mam[species, on = .(genus, species), nomatch = NULL][, .(deployment_id, dt, taxon, sequence_id)]
stopifnot(nrow(sp) == sum(species$n_rows))
sp <- sp[weeks, on = .(deployment_id, dt >= wstart, dt <= wend), nomatch = NULL, .(deployment_id, taxon, sequence_id, occasion = i.occasion)]
stopifnot(nrow(sp) == sum(species$n_rows))                      # every sequence lands in exactly one week
counts <- sp[, .(y_raw = uniqueN(sequence_id)), by = .(deployment_id, occasion, taxon)]
long <- weeks[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(weeks))]
long <- merge(long, counts, by = c("deployment_id", "occasion", "taxon"), all.x = TRUE)
long[is.na(y_raw), y_raw := 0L]
stopifnot(nrow(long) == nrow(weeks) * nrow(species), sum(long$y_raw) == sum(counts$y_raw))

# --- units, ids, coordinates --------------------------------------------------------------
cc <- coarsen_coords(dep$latitude, dep$longitude)
dep[, `:=`(lat_c = cc$lat, lon_c = cc$lon, unc_m = cc$uncertainty_m)]
setorder(dep, year, subproject_name_no_year, placename, st, deployment_id)
dep[, uid := sprintf("D%04d", seq_len(.N))]
arr <- sort(unique(dep$subproject_name_no_year)); dep[, aid := sprintf("A%03d", match(subproject_name_no_year, arr))]
pl <- sort(unique(dep$placename)); dep[, sid := sprintf("S%04d", match(placename, pl))]
periods <- dep[, .(n_deployments = .N, n_arrays = uniqueN(aid), first_start = format(min(st)), last_end = format(max(en))), by = year][order(year)]
periods[, period := seq_len(.N)]; setcolorder(periods, c("period", "year"))
long <- merge(long, dep[, .(deployment_id, unit = uid, cluster_id = aid, period = match(year, periods$year),
                            unit_decimalLatitude = lat_c, unit_decimalLongitude = lon_c, unit_coordinateUncertaintyInMeters = unc_m,
                            unit_feature_type = feature_type)], by = "deployment_id")
long <- order_eco(long[, .(unit, taxon, y = as.integer(y_raw > 0L), y_raw, period, occasion, date = format(wstart), cluster_id,
                           unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters, unit_feature_type, obs_camera_days)])
stopifnot(uniqueN(long$unit) == 2503, uniqueN(long$cluster_id) == uniqueN(dep$aid), uniqueN(long$taxon) == nrow(species),
          long[taxon == "CERELA", sum(y_raw)] == species[taxon == "CERELA", n_seq])
units <- dep[, .(unit = uid, cluster_id = aid, site_id = sid, year,
                 decimalLatitude = lat_c, decimalLongitude = lon_c, coordinateUncertaintyInMeters = unc_m,
                 start_date = format(st), end_date = format(en), camera_days = span_days, n_weeks = ceiling(span_days / 7),
                 feature_type, sensor_height, quiet_period_s = quiet_period)][order(unit)]

# --- taxa and IUCN ------------------------------------------------------------------------
remarks <- ifelse(species$taxon == "HYDCHR", "Wildlife Insights label 'Common Water Rat' (an Australasian species) recorded at European cameras; shipped as deposited, likely a misapplied label for a European rodent", NA_character_)
taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$common_name, lookupName = species$lookupName,
                  taxon_class = "Mammalia", taxon_order = species$order, taxon_family = species$family,
                  taxon_n_sequences = species$n_seq, taxonRemarks = remarks)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# Ovis orientalis (WI "Mouflon"): GBIF's key is assessed by IUCN under a different species (Ovis vignei),
# so iucn_category() returns NA; IUCN assesses the mouflon as Ovis gmelini, NT (2020). Set by hand.
stopifnot(is.na(taxa[taxon == "OVIORI", taxon_iucnCategory])); taxa[taxon == "OVIORI", taxon_iucnCategory := "NT"]
FLAG <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), scientificName]
stopifnot(setequal(FLAG, c("Oryctolagus cuniculus", "Gazella gazella", "Hydropotes inermis", "Eliomys quercinus", "Lepus corsicanus")))
FLAG_TXT <- "European rabbit (Oryctolagus cuniculus, EN, recorded in its native Iberian range), mountain gazelle (Gazella gazella, EN, Israel), garden dormouse (Eliomys quercinus, VU) and Italian hare (Lepus corsicanus, VU) in their native ranges; water deer (Hydropotes inermis, VU) is recorded only outside its native range"

yrs <- range(dep$st); yre <- max(dep$en)
iso <- c(AT = "AUT", BE = "BEL", CH = "CHE", CZ = "CZE", DE = "DEU", EE = "EST", ES = "ESP", FR = "FRA", GB = "GBR", GR = "GRC",
         HR = "HRV", HU = "HUN", IE = "IRL", IL = "ISR", IT = "ITA", LT = "LTU", LV = "LVA", MK = "MKD", NO = "NOR", PL = "POL",
         PT = "PRT", RO = "ROU", SE = "SWE", SI = "SVN", TR = "TUR")
cc2 <- substr(dep$subproject_name, 1, 2)
stopifnot(all(cc2 %in% names(iso)), length(unique(cc2)) == 25)   # array names start with the ISO 3166-1 alpha-2 code
countries <- paste(sort(unname(iso[unique(cc2)])), collapse = ",")
dataset <- list(
  title = sprintf("Snapshot Europe 2021-2022: weekly camera-trap detections of %d mammal species at %s deployments in %d arrays across Europe and Israel",
                  nrow(species), format(nrow(dep), big.mark = ","), length(arr)),
  creator = "Iannarilli, Fabiola; Keeves von Wolff, Brigitta; Wikelski, Martin; Heurich, Marco; Kays, Roland; Cagnacci, Francesca; and the Snapshot Europe contributors",
  pubDate = "2026", doi = "10.17617/3.7YLWMU", sourceURL = "https://doi.org/10.17617/3.7YLWMU",
  citation = "Iannarilli, F., et al. (2026). Dataset associated with \"Snapshot Europe 2021-2022: The first public dataset from a Europe-wide camera-trap survey of terrestrial vertebrates\" (version 2) [Data set]. Edmond. https://doi.org/10.17617/3.7YLWMU",
  intellectualRights = list(spdx = "CC-BY-NC-SA-4.0", url = "https://creativecommons.org/licenses/by-nc-sa/4.0/",
                            note = "Edmond record: CC BY-SA 4.0; Wildlife Insights export: metadata CC-BY, every sequence row license = CC-BY-NC (the image licence). The stricter combination governs."),
  abstract = sprintf("Snapshot Europe is a coordinated camera-trap survey run each autumn (mid-August to mid-November) by more than 160 contributors with a shared protocol: arrays of unbaited cameras at knee height, images classified in Wildlife Insights and reviewed by a contributor. This table aggregates the 2021 and 2022 sequence file to camera-weeks: one row per deployment x 7-day window x species for the %d mammal species identified to species (humans excluded, domestic animals included), y = detected in that week, y_raw = number of sequences, obs_camera_days = days of the window inside the deployment. The deployment table is the survey set; the 93 deployments that declare a camera failure are not shipped because their operating days are unknown. Camera coordinates are coarsened to 0.1-degree cells and deployment, location and array names replaced by sequential ids because IUCN-flagged species are among the taxa.", nrow(species)),
  samplingProtocol = "Unbaited passive-infrared camera traps, mostly at knee height, in arrays of about 10-60 cameras per area, deployed for several weeks between mid-August and mid-November; sequences of images identified in Wildlife Insights (AI pre-classification reviewed by at least one participant)",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days (last window of a deployment partial)", effortColumn = "obs_camera_days",
  surveyEvidence = "effort_table",
  surveyEvidenceNote = "A camera-day exists iff start_date <= day <= end_date (inclusive) in Snapshot_Europe_2021_2022_deployments.csv, for deployments whose camera_functioning is 'Camera Functioning'; camera-days are grouped into 7-day windows from the start date. Every sequence in the deposit falls inside its deployment's dates. The 93 deployments declaring a failure (Unknown Failure, Memory Card, Theft, Camera Hardware Failure, Vandalism, Wildlife Damage) are excluded with their sequences.",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = sprintf("period = survey year (2021, 2022; a deployment is in one year); occasion = camera-week within the deployment, 1-%d weeks", max(weeks$occasion)),
  geographicCoverage = sprintf("Europe (24 countries from Portugal to Turkey, Norway to Greece) and Israel; camera coordinates coarsened to 0.1-degree cells; latitude %.1f to %.1f, longitude %.1f to %.1f",
                               min(dep$latitude), max(dep$latitude), min(dep$longitude), max(dep$longitude)),
  temporalCoverage = sprintf("%s/%s", format(yrs[1]), format(yre)),
  crs = "EPSG:4326 (WGS 84, as published), coarsened",
  coordinatesCoarsened = list(value = TRUE, method = sprintf("0.1-degree grid cell centre for every deployment (one unit set serves all taxa); IUCN-flagged species among the shipped taxa: %s; the source publishes camera coordinates to 5-6 decimals; deployment ids, placenames and array names replaced by sequential ids (E7.4)", FLAG_TXT)),
  covariateNote = "unit_feature_type is the contributor's description of the camera placement (None, Trail game, Trail hiking, Road dirt, Water source, ...). site_id in __units links deployments at one camera location (placename) within and across years; sensor height, quiet period and deployment dates are in __units.",
  designNote = "Community detection table aggregated to camera-weeks (E9 core). The deposit is sequence-level with timestamps, so daily occasions can be rebuilt from the source. A location can have several consecutive deployments (card or camera swaps) in one year, each its own unit; a dynamic or multi-deployment model needs site_id from __units.",
  notes = sprintf("Taxa are every mammal identified to species except humans (%d species, %s sequences in functioning deployments). Identifications are Wildlife Insights labels as deposited; Hydromys chrysogaster ('Common Water Rat', Australasian) is kept with a taxonRemarks warning. y_raw counts distinct sequence_ids (a sequence with two rows for one species counts once). Sequence rows in failed deployments not shipped: %d.",
                  nrow(species), format(sum(species$n_seq), big.mark = ","), n_fail_rows),
  notShipped = list(
    `failed deployments` = sprintf("93 deployments with camera_functioning other than 'Camera Functioning' (%s): end_date is the retrieval date and the failure date is not recorded, so operating days cannot be evidenced",
                                   paste(sprintf("%s %d", fails$camera_functioning, fails$N), collapse = ", ")),
    birds = "78 species-level bird labels (9,658 sequence rows): the survey and its project objective target mammals; bird tagging differs by contributor",
    `labels above species rank` = "Rodent, Mammal, Cervidae Family, Mustelidae Family, etc.",
    humans = "Homo sapiens under 11 common names (Human-Camera Trapper, Human-Pedestrian, Horseback Rider, ...)",
    `place names` = "deployment_id, placename and subproject names name places (E7.4): replaced by sequential unit, cluster_id and site_id",
    `per-sequence attributes` = "group_size, age, sex, behaviour, identified_by",
    images = "Snapshot_Europe_2021_2022_images.csv (420 MB, one row per image): the sequences file is the detection record"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("Weekly camera-trap detection/non-detection (sequence counts in y_raw) of %d mammal species at %s Snapshot Europe deployments in %d arrays across 24 European countries and Israel, autumn 2021-2022, with camera-days per week as effort, array as cluster_id, camera placement, and 0.1-degree coarsened coordinates.",
                    nrow(species), format(nrow(dep), big.mark = ","), length(arr)),
  url = "https://doi.org/10.17617/3.7YLWMU",
  reference = "Iannarilli, F., et al. (in press). Snapshot Europe 2021-2022: The first public dataset from a Europe-wide camera-trap survey of terrestrial vertebrates. Ecology.",
  doi_paper = "", doi_data = "10.17617/3.7YLWMU",
  original_license = "CC BY-SA 4.0 (Edmond) / Wildlife Insights metadata CC-BY, sequence rows CC-BY-NC (image licence)",
  derived_license = "CC BY-NC-SA 4.0",
  notes = "Edmond version 2 (2026-07-13), DataS1.zip. 93 deployments declaring a camera failure dropped. Mammals to species, humans excluded; birds not shipped. Coordinates coarsened (European rabbit and mountain gazelle EN, garden dormouse and Italian hare VU, in their native ranges). Mouflon IUCN category set by hand (Ovis gmelini NT) because GBIF's key is assessed under another name.",
  source_via = "Edmond (Dataverse) file access API")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (annual single-season)",
  sampling_protocol = "camera_trap", design = sprintf("Multi-season (2 annual surveys x 1-%d camera-weeks per deployment)", max(weeks$occasion)), realm = "Terrestrial", country = countries,
  coordinates = "Coarsened (0.1 deg)", notes = "Wildlife Insights export; sequence-level source allows daily occasions; derived licence NC-SA from the deposit's row-level licence field.",
  status = "tagged")
