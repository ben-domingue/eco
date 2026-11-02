#!/usr/bin/env Rscript
# Table:  rooney_2025_snapshotusa_comm
# Source: Dryad doi:10.5061/dryad.k0p2ngfhn, "SNAPSHOT USA 2019-2023: The first five years of
#         data from a coordinated camera trap survey of the United States", Rooney, McShea,
#         Kays, Cove et al.; licence CC0 1.0 (Dryad). The current version (6, 2025-04-10,
#         ssusa_finaldeployments.csv 9,694 rows, ssusa_finalsequences.csv 987,979 rows) is not
#         downloadable anonymously (the version zip answers 405, per-file downloads 401), so
#         this table is built from version 3 (2025-01-03, ssusa_alldeployments.csv 9,694 rows,
#         ssusa_allsequences.csv 972,415 rows), the latest version whose zip Dryad serves
#         anonymously. The two versions have the same deployment count; the sequence file grew
#         by 15,564 rows between them (content not compared). Re-run against version 6 when a
#         Dryad token is available.
# Paper:  data papers for the annual releases: Cove et al. 2021 Ecology 102:e03353 (2019),
#         Kays et al. 2022 Ecology 103:e3775 (2020), Shamon et al. 2024 Ecology 105:e4318 (2021);
#         the 2019-2023 compilation paper is not on Crossref as of 2026-11-01.
# Data:   ssusa_alldeployments.csv: one row per camera deployment (Year, Project, Camera_Trap_Array,
#         Site_Name, Deployment_ID, Start_Date, End_Date, Survey_Nights, Latitude, Longitude,
#         Habitat, Development_Level, Feature_Type). Deployment_ID is unique within a year;
#         46 ids recur in two years (the same site re-run). 564 site-years carry more than one
#         deployment row with distinct ids (photo batches uploaded as separate WI deployments).
#         Survey_Nights = End - Start exactly. ssusa_allsequences.csv: one row per species
#         identification per camera sequence (photos within one minute of a trigger), with the
#         Wildlife Insights taxonomy to species where identified, Age, Sex, Group_Size.
#         Every sequence falls inside its deployment's window (asserted); 27 rows name a
#         deployment absent from the deployments file. 514 distinct labels, 382 to species.
# Mapping (standard section 3.6, community detection from a sequence table with a deployment
# table, aggregated to camera-weeks):
#   unit = deployment (Deployment_ID, suffixed with the year for the 46 ids reused across
#   years); cluster_id = Camera_Trap_Array; period = survey year 2019-2023 (each deployment is
#   in one year, so period is redundant with unit_year, but the survey is annual by design and
#   a user filtering a year needs the column); occasion = 7-day window index from the
#   deployment start date (the last window is partial; obs_camera_days = days of the window
#   inside the deployment, 1-7); date = first day of the window. y = 1 if the taxon has at
#   least one sequence in that camera-week, y_raw = number of distinct sequences.
#   taxon = the 87 mammal species with at least 50 sequences over the five years (six-letter
#   genus+species codes, __taxa with GBIF keys and the Wildlife Insights common name).
#   Survey evidence: the deployment table (a camera-day exists iff Start <= day <= End), so
#   surveyEvidence = effort_table; every shipped taxon has a row at every camera-week.
#   Coordinates: the deposit publishes exact camera coordinates. Two shipped taxa are IUCN
#   flagged (red wolf Canis rufus CR, giant kangaroo rat Dipodomys ingens EN), so every unit's
#   coordinates are coarsened to the 0.1-degree cell centre (one unit set serves all taxa;
#   standard E7); __units carries the coarsened coordinates too.
#   Not shipped: labels above species rank (Mammal, Rodent, Bird, Peromyscus Species, ...),
#   humans (Homo sapiens under 12 common names), vehicles, birds (225 species, 27,913 rows:
#   incidental to a mammal survey and not consistently tagged, 14,086 generic "Bird" rows),
#   reptiles, amphibians, invertebrates, the 43 mammal species with fewer than 50 sequences
#         (counts recorded in notShipped), Age/Sex/Group_Size (per-sequence attributes, dropped),
#         Project, Site_Name and Feature_Type beyond __units.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "rooney_2025_snapshotusa_comm"
MIN_SEQ <- 50L
WTD_SEQ <- 222186L        # white-tailed deer sequences (distinct Sequence_ID, or row start time where the id is NA) inside matched deployments
NA_SEQ_ROWS <- 14445L     # sequence rows with an NA Sequence_ID (223 deployments, mostly SCBI 2019 batches)

# --- source files (version 3 zip, fetched once; see header) --------------------------------
raw <- file.path(RAW_DIR, TABLE, "dryad_337591")
if (!dir.exists(raw) || length(list.files(raw)) < 3) {
  zip <- download_cached("https://datadryad.org/api/v2/versions/337591/download", TABLE, filename = "dryad_337591.zip")
  dir.create(raw, showWarnings = FALSE); unzip(zip, exdir = raw)
}
stopifnot(setequal(list.files(raw), c("README.md", "ssusa_alldeployments.csv", "ssusa_allsequences.csv")))
dep <- fread(file.path(raw, "ssusa_alldeployments.csv"), encoding = "UTF-8")
seq <- fread(file.path(raw, "ssusa_allsequences.csv"), encoding = "UTF-8")
setnames(dep, sub("^﻿", "", names(dep))); setnames(seq, sub("^﻿", "", names(seq)))
stopifnot(nrow(dep) == 9694, ncol(dep) == 13, nrow(seq) == 972415, ncol(seq) == 16,
          uniqueN(dep$Deployment_ID) == 9648, !anyDuplicated(dep[, .(Deployment_ID, Year)]),
          uniqueN(dep$Camera_Trap_Array) == 263, uniqueN(dep$Site_Name) == 6712, uniqueN(dep$Project) == 20,
          identical(sort(unique(dep$Year)), 2019:2023), !anyNA(dep$Latitude), !anyNA(dep$Longitude))

# --- deployments: the survey set ----------------------------------------------------------
dep[, st := as.IDate(Start_Date, "%m/%d/%Y")][, en := as.IDate(End_Date, "%m/%d/%Y")]
stopifnot(!anyNA(dep$st), !anyNA(dep$en), all(dep$en >= dep$st), all(year(dep$st) == dep$Year),
          all(as.integer(dep$en - dep$st) == dep$Survey_Nights))
dep[, span_days := as.integer(en - st) + 1L]
reused <- dep[, .N, by = Deployment_ID][N > 1, Deployment_ID]
stopifnot(length(reused) == 46, dep[Deployment_ID %in% reused, all(uniqueN(Year) == .N), by = Deployment_ID][, all(V1)])
dep[, unit := ifelse(Deployment_ID %in% reused, paste0(Deployment_ID, "_", Year), Deployment_ID)]
stopifnot(!anyDuplicated(dep$unit))
cat(sprintf("  %d deployments (%d ids, %d reused across years) in %d arrays, %d-%d, %d-%d days each\n",
            nrow(dep), uniqueN(dep$Deployment_ID), length(reused), uniqueN(dep$Camera_Trap_Array),
            min(dep$Year), max(dep$Year), min(dep$span_days), max(dep$span_days)))

# camera-weeks: 7-day windows from the start date, last window partial
weeks <- dep[, .(occasion = seq_len(ceiling(span_days / 7))), by = .(unit, Year, st, en, span_days)]
weeks[, wstart := st + (occasion - 1L) * 7L]
weeks[, wend := pmin(wstart + 6L, en)]
weeks[, obs_camera_days := as.integer(wend - wstart) + 1L]
stopifnot(all(weeks$obs_camera_days >= 1L), all(weeks$obs_camera_days <= 7L),
          weeks[, sum(obs_camera_days), by = unit][dep, on = "unit"][, all(V1 == span_days)],
          nrow(weeks) == 59182)
cat(sprintf("  %d camera-weeks (%d camera-days)\n", nrow(weeks), sum(weeks$obs_camera_days)))

# --- sequences ----------------------------------------------------------------------------
seq[, t := as.POSIXct(Start_Time, format = "%m/%d/%Y %H:%M:%S", tz = "UTC")]
stopifnot(!anyNA(seq$t))
seq[, dt := as.IDate(t)]
# Sequence_ID is NA on 223 deployments (14,445 rows): there each row is its own sequence, keyed by its start time
seq[, seqkey := fifelse(is.na(Sequence_ID) | Sequence_ID == "", paste0("t:", Start_Time), Sequence_ID)]
orphan <- seq[!dep, on = .(Deployment_ID, Year)]
stopifnot(nrow(orphan) == 27)
seq <- seq[dep[, .(Deployment_ID, Year, unit, st, en)], on = .(Deployment_ID, Year), nomatch = NULL]
stopifnot(nrow(seq) == 972415 - 27, all(seq$dt >= seq$st & seq$dt <= seq$en))   # every sequence inside its window
cat(sprintf("  %d sequence rows matched to a deployment-year (%d orphan rows dropped), all inside the deployment windows\n", nrow(seq), nrow(orphan)))
stopifnot(identical(sort(unique(na.omit(seq$Class))), c("Amphibia", "Arachnida", "Aves", "Gastropoda", "Insecta", "Mammalia", "Reptilia")))

# taxa: mammals identified to species, excluding humans, with >= MIN_SEQ sequences
lab <- seq[, .(n_rows = .N, n_seq = uniqueN(paste(unit, seqkey)), common_name = Common_Name[1], n_common = uniqueN(Common_Name)),
           by = .(Class, Order, Family, Genus, Species)]
sp_level <- lab[!is.na(Species) & Species != "" & !is.na(Genus) & Genus != ""]
cat(sprintf("  %d distinct taxonomic labels, %d to species\n", nrow(lab), nrow(sp_level)))
stopifnot(nrow(lab) == 492, nrow(sp_level) == 366, sp_level[Genus == "Homo", n_common] == 12, seq[is.na(Sequence_ID) | Sequence_ID == "", .N] == NA_SEQ_ROWS)   # 382 labels to species incl. 12 Homo and 5 other duplicate common names
mam <- sp_level[Class == "Mammalia" & Genus != "Homo"]
stopifnot(nrow(mam) == 130)
species <- mam[n_seq >= MIN_SEQ][order(-n_seq)]
stopifnot(nrow(species) == 87, species[Genus == "Odocoileus" & Species == "virginianus", n_seq] == WTD_SEQ)
species[, scientificName := paste(Genus, Species)]
species[, lookupName := scientificName]
species[scientificName == "Capra aegagrus hircus", `:=`(scientificName = "Capra hircus", lookupName = "Capra hircus")]   # WI trinomial for the domestic goat
species[, taxon := toupper(paste0(substr(Genus, 1, 3), substr(Species, 1, 3)))]
stopifnot(!anyDuplicated(species$taxon), !anyDuplicated(species$scientificName))
# IUCN Red List categories (2026 assessments) for the non-LC shipped species; everything else is LC or domestic
iucn <- c(CANRUF = "CR", DIPING = "EN", BISBIS = "NT")
stopifnot(all(names(iucn) %in% species$taxon))
species[, iucn := iucn[taxon]]
cat(sprintf("  %d of %d mammal species have >= %d sequences and are shipped (%s of %s species-level mammal rows); flagged: %s\n",
            nrow(species), nrow(mam), MIN_SEQ, format(sum(species$n_rows), big.mark = ","), format(sum(mam$n_rows), big.mark = ","),
            paste(species[!is.na(iucn), paste0(scientificName, " ", iucn)], collapse = ", ")))

# --- long table: camera-week x taxon ------------------------------------------------------
sp <- seq[species, on = .(Genus, Species), nomatch = NULL][, .(unit, dt, taxon, seqkey)]
stopifnot(nrow(sp) == sum(species$n_rows))
sp <- sp[weeks, on = .(unit, dt >= wstart, dt <= wend), nomatch = NULL, .(unit, taxon, seqkey, occasion = i.occasion)]
stopifnot(nrow(sp) == sum(species$n_rows))                        # every sequence lands in exactly one week
counts <- sp[, .(y_raw = uniqueN(seqkey)), by = .(unit, occasion, taxon)]
long <- weeks[rep(seq_len(.N), each = nrow(species))][, taxon := rep(species$taxon, times = nrow(weeks))]
long <- merge(long, counts, by = c("unit", "occasion", "taxon"), all.x = TRUE)
long[is.na(y_raw), y_raw := 0L]
stopifnot(nrow(long) == nrow(weeks) * nrow(species), sum(long$y_raw) == sum(counts$y_raw),
          sum(counts$y_raw) == sp[, uniqueN(seqkey), by = .(unit, taxon)][, sum(V1)])   # Sequence_ID is unique within a deployment, not globally

# unit facts and coarsened coordinates
cc <- coarsen_coords(dep$Latitude, dep$Longitude)
dep[, `:=`(lat_c = cc$lat, lon_c = cc$lon, unc_m = cc$uncertainty_m)]
periods <- data.table(period = 1:5, year = 2019:2023)
periods <- merge(periods, dep[, .(n_deployments = .N, n_arrays = uniqueN(Camera_Trap_Array), first_start = format(min(st)), last_end = format(max(en))), by = .(year = Year)], by = "year")[order(period)]
setcolorder(periods, c("period", "year"))
long <- merge(long, dep[, .(unit, cluster_id = Camera_Trap_Array, period = match(Year, periods$year), unit_year = Year,
                            unit_decimalLatitude = lat_c, unit_decimalLongitude = lon_c, unit_coordinateUncertaintyInMeters = unc_m,
                            unit_habitat = Habitat, unit_development_level = Development_Level)], by = "unit")
long <- long[, .(unit, taxon, y = as.integer(y_raw > 0L), y_raw, period, occasion, date = format(wstart), cluster_id,
                 unit_year, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters,
                 unit_habitat, unit_development_level, obs_camera_days)]
long <- order_eco(long)
stopifnot(nrow(long) == 59182L * 87L, uniqueN(long$unit) == 9694, uniqueN(long$taxon) == 87, uniqueN(long$period) == 5,
          long[taxon == "ODOVIR", sum(y_raw)] == WTD_SEQ)
cat(sprintf("  %s rows, %d camera-weeks x %d taxa, %s detection-weeks\n", format(nrow(long), big.mark = ","), nrow(weeks), nrow(species),
            format(sum(long$y), big.mark = ",")))

taxa <- make_taxa(species$taxon, species$scientificName, vernacularName = species$common_name, lookupName = species$lookupName,
                  taxon_class = "Mammalia", taxon_order = species$Order, taxon_family = species$Family,
                  taxon_iucnCategory = species$iucn, taxon_n_sequences = species$n_seq)
units <- dep[, .(unit, cluster_id = Camera_Trap_Array, project = Project, site = Site_Name, deployment_id = Deployment_ID, year = Year,
                 decimalLatitude = lat_c, decimalLongitude = lon_c, coordinateUncertaintyInMeters = unc_m,
                 start_date = format(st), end_date = format(en), survey_nights = Survey_Nights, n_weeks = ceiling(span_days / 7),
                 habitat = Habitat, development_level = Development_Level, feature_type = Feature_Type)]

not_shipped_mammals <- mam[n_seq < MIN_SEQ][order(-n_seq), paste0(Genus, " ", Species, " (", n_seq, ")")]
dataset <- list(
  title = "Snapshot USA 2019-2023: weekly camera-trap detections of 87 mammal species at 9,694 deployments in 263 arrays across the United States",
  creator = "Rooney, Brigit; McShea, William J.; Kays, Roland; Cove, Michael V.; and the Snapshot USA contributors",
  pubDate = "2025", doi = "10.5061/dryad.k0p2ngfhn", sourceURL = "https://doi.org/10.5061/dryad.k0p2ngfhn",
  citation = "Rooney, B., McShea, W. J., Kays, R., Cove, M. V., et al. (2025). SNAPSHOT USA 2019-2023: The first five years of data from a coordinated camera trap survey of the United States [Data set]. Dryad. https://doi.org/10.5061/dryad.k0p2ngfhn (version 3, 2025-01-03)",
  paperDOI = "10.1002/ecy.4318",
  relatedPapers = c("10.1002/ecy.3353", "10.1002/ecy.3775", "10.1002/ecy.4318"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = sprintf("Snapshot USA is an annual, multi-contributor camera-trap survey of mammals across the United States, run each autumn (deployments between 1 August and 29 December) since 2019 with a shared protocol: arrays of about ten cameras per site type, cameras run for several weeks, images identified in Wildlife Insights to species where possible. This table aggregates the 2019-2023 sequence file to camera-weeks: one row per deployment x 7-day window x species for the %d mammal species with at least %d sequences over the five years, y = detected in that week, y_raw = number of sequences, obs_camera_days = days of the window inside the deployment (the last window is partial). The deployment table is the survey set. Camera coordinates are coarsened to 0.1-degree cell centres because two shipped species are IUCN flagged (red wolf CR, giant kangaroo rat EN). Built from Dryad version 3 (2025-01-03); the current version 6 is not downloadable without a token.", nrow(species), MIN_SEQ),
  samplingProtocol = "Unbaited passive-infrared camera traps at knee height facing trails or random points, 10+ cameras per array spaced >= 200 m, run for several weeks between August and December; sequences = photos within one minute of a trigger; species identified by the contributors in Wildlife Insights",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days (last window of a deployment partial)", effortColumn = "obs_camera_days",
  surveyEvidence = "effort_table",
  surveyEvidenceNote = "A camera-day exists iff Start_Date <= day <= End_Date in ssusa_alldeployments.csv (Survey_Nights = End - Start for every row); camera-days are grouped into 7-day windows from the start date. Every sequence in the file falls inside its deployment's window; 27 sequence rows naming a deployment absent from the deployments file are dropped.",
  responseType = "detection", unitKind = "site",
  closure = "period = survey year (one deployment per unit, so a unit has rows in one period only); occasion = camera-week within the deployment, 1-21 weeks",
  geographicCoverage = "United States (all 50 states), camera coordinates coarsened to 0.1-degree cells; latitude 21.4 to 59.5, longitude -157.7 to -68.6",
  temporalCoverage = "2019-08-01/2023-12-29",
  crs = "EPSG:4326 (WGS 84, as published), coarsened",
  coordinatesCoarsened = list(value = TRUE, method = "0.1-degree grid cell centre for every deployment (one unit set serves all taxa); red wolf (Canis rufus, IUCN CR) and giant kangaroo rat (Dipodomys ingens, IUCN EN) are among the shipped taxa; the source publishes exact camera coordinates (WGS 84, 4-6 decimals)"),
  covariateNote = "unit_habitat and unit_development_level are the contributors' array-level classifications as deposited; Project, Site_Name, Deployment_ID, Feature_Type and the deployment dates are in __units.",
  designNote = "Community detection table aggregated to camera-weeks (E9 core). The deposit is sequence-level with timestamps, so daily or finer occasions can be rebuilt from the source; weeks were chosen to keep the table at 5.1 million rows. period duplicates unit_year because the survey is an annual design with new deployments each year; a dynamic model across years needs the site, not the deployment, as the unit (Site_Name in __units; 6,712 sites, most sampled in several years).",
  notes = sprintf("Taxa are the %d mammal species with >= %d sequences; the %d mammal species below that cut are not shipped (see notShipped). 46 Deployment_IDs recur in two years and carry a _<year> suffix in unit. The deposit's version 3 is used (see abstract). y_raw counts distinct Sequence_IDs (a sequence with two rows for one species, e.g. age/sex groups, counts once); on 223 deployments (14,445 rows) the Sequence_ID is NA and each row's start time stands in for it.", nrow(species), MIN_SEQ, nrow(mam) - nrow(species)),
  notShipped = list(
    `mammals below 50 sequences` = paste(not_shipped_mammals, collapse = "; "),
    birds = sprintf("225 species-level bird labels (27,913 sequence rows) plus 14,086 generic 'Bird' rows: incidental to a mammal-focused survey and not consistently tagged across contributors"),
    `reptiles, amphibians, invertebrates` = "13 reptile and 1 amphibian species (209 rows), Insecta, Arachnida, Gastropoda",
    `labels above species rank` = "Mammal, Rodent, Peromyscus Species, Sciuridae Family, Sylvilagus Species, Animal, Unknown, etc. (132 labels)",
    `humans and vehicles` = "Homo sapiens under 12 common names, Vehicle, Official Vehicle",
    `Age, Sex, Group_Size` = "per-sequence attributes (mostly Unknown), not carried at the camera-week level",
    `orphan sequences` = "27 rows whose Deployment_ID x Year is not in the deployments file"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/rooney_2025_snapshotusa_comm.R")

stage_dict_row(TABLE,
  description = sprintf("Weekly camera-trap detection/non-detection (sequence counts in y_raw) of %d mammal species at 9,694 Snapshot USA deployments in 263 arrays across the United States, autumn 2019-2023, with camera-days per week as effort, array as cluster_id, habitat and development class, and 0.1-degree coarsened coordinates.", nrow(species)),
  url = "https://doi.org/10.5061/dryad.k0p2ngfhn",
  reference = "Shamon, H., Maor, R., Cove, M. V., Kays, R., et al. (2024). SNAPSHOT USA 2021: A third coordinated national camera trap survey of the United States. Ecology, 105(6), e4318; Cove et al. (2021) Ecology 102:e03353; Kays et al. (2022) Ecology 103:e3775.",
  doi_paper = "10.1002/ecy.4318", doi_data = "10.5061/dryad.k0p2ngfhn",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Built from Dryad version 3 (2025-01-03; version 6 needs a token). 87 of 130 mammal species (>= 50 sequences); birds and higher-rank labels not shipped. Coordinates coarsened (red wolf CR, giant kangaroo rat EN among the taxa).",
  source_via = "Dryad version zip")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (annual single-season; dynamic across years by site)",
  sampling_protocol = "camera_trap", design = "Multi-season (5 annual surveys x 1-21 camera-weeks per deployment)", realm = "Terrestrial", country = "USA",
  coordinates = "Coarsened (0.1 deg)", notes = "Largest table in the corpus (5.1M rows). Sequence-level source allows daily occasions. 46 deployment ids reused across years suffixed with the year.",
  status = "tagged")
