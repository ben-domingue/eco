#!/usr/bin/env Rscript
# Tables: thomas_2025_oregon_murrelet_pam_occ, thomas_2025_oregon_murrelet_av_occ
# Source: Zenodo doi:10.5281/zenodo.17497184, published 2025-10-31, licence CC BY 4.0 (record metadata licence id
#         "cc-by-4.0", asserted from the cached record JSON).
#   Thomas, A., Duarte, A., Gostin, M., Peterson, J. & Lesmeister, D. (2025). Detection histories and covariates
#   for marbled murrelet survey comparison [Dataset]. Zenodo.
# Paper:  Thomas, A., Duarte, A., Gostin, M., Peterson, J. & Lesmeister, D. (2025). Passive acoustic monitoring is a
#         cost-effective approach to conduct inland surveys for marbled murrelets. Wildlife Society Bulletin.
#         doi:10.1002/wsb.1640 (not read: the deposit's READ ME defines the columns).
# Data:   READ ME.csv: column A station id; B-BF encounter histories, PAM surveys (Survey 1-53) and audio-visual
#         (AV) survey visits (Survey 54-57); then day of year (DOY 1-57), survey type (surveytype1-57: PAM or AV),
#         temperature (Temp, degrees C), noise (Noise, dBFS) for each survey; Year; StudyArea.
#         detection_histories_covariates_marbled_murrelet_survey_comparison.csv: 88 rows, one per station-year
#         ("<station>-<year>": 44 in 2022, 44 in 2023; 19 stations in both years, 69 stations), study areas JCN, ODFN, ODFS.
#         A blank survey cell is a survey not done: the blanks of the history, DOY and survey type agree exactly
#         (asserted); 3,517 PAM station-days and 294 AV visits (2-4 per station-year). Temperature has 4 values in
#         cells with no survey (ignored); noise is blank on 19 AV visits.
# Mapping: two methods with separate survey sets (PAM days and AV visits on other days) are two protocols, so two
#   tables (ruling #31); they share station names. unit = station (id without the year), period = year (1 = 2022,
#   2 = 2023), occasion = the survey's column index within its method (PAM 1-53, AV 1-4), date = year + DOY (an exact
#   ISO date), taxon = BRAMAR, y = 0/1 as deposited. obs_temp_c, obs_noise_dbfs; unit_study_area (constant within a
#   station, asserted). surveyEvidence = deposited_matrix.
#   No coordinates deposited (the murrelet is IUCN EN; E7 does not arise).
#   Not shipped: the 4 temperature values in cells with no survey; the paper's model estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/thomas_2025_oregon_murrelet_occ.R"
REC <- "17497184"; CACHE <- "thomas_2025_oregon_murrelet_occ"
zen <- function(key, fn = key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), CACHE, filename = fn)
meta_f <- file.path(RAW_DIR, CACHE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
DF <- "detection_histories_covariates_marbled_murrelet_survey_comparison.csv"
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.17497184"),
          setequal(meta$files$key, c("READ ME.csv", DF)))
invisible(zen("READ ME.csv", "READ_ME.csv"))
d <- fread(zen(DF))
n <- names(d)
g <- function(p) { m <- as.matrix(d[, grep(p, n), with = FALSE]); stopifnot(ncol(m) == 57L); m }
Y <- g("^Survey "); D <- g("^DOY "); Ty <- g("^surveytype"); Tm <- g("^Temp"); N <- g("^Noise")
Ty[Ty == ""] <- NA
stopifnot(nrow(d) == 88L, ncol(d) == 288L, identical(n[c(1, 287, 288)], c("StationID", "Year", "StudyArea")),
          !anyDuplicated(d$StationID), all(grepl("-20(22|23)$", d$StationID)),
          identical(as.integer(sub(".*-", "", d$StationID)), d$Year),
          all(Y %in% c(0L, 1L, NA)), all(is.na(Y) == is.na(D)), all(is.na(Y) == is.na(Ty)),
          all(Ty[, 1:53] %in% c("PAM", NA)), all(Ty[, 54:57] %in% c("AV", NA)),
          sum(!is.na(Y[, 1:53])) == 3517L, sum(!is.na(Y[, 54:57])) == 294L,
          sum(!is.na(Tm) & is.na(Y)) == 4L, sum(is.na(N) & !is.na(Y)) == 19L, all(is.na(N[is.na(Y)])),
          all(rowSums(!is.na(Y[, 54:57])) >= 2L), all(rowSums(!is.na(Y[, 1:53])) >= 1L))
d[, station := sub("-20(22|23)$", "", StationID)]
stopifnot(d[, uniqueN(StudyArea), by = station][, all(V1 == 1L)], uniqueN(d$station) == 69L, d[, .N, by = station][N == 2, .N] == 19L)
build <- function(cols) {
  rbindlist(lapply(seq_along(cols), function(k) { j <- cols[k]
    data.table(unit = d$station, period = d$Year - 2021L, occasion = k, y = Y[, j],
               date = format(as.Date(sprintf("%d-01-01", d$Year)) + D[, j] - 1L),
               unit_study_area = d$StudyArea, obs_temp_c = Tm[, j], obs_noise_dbfs = N[, j]) }))[!is.na(y)][, taxon := "BRAMAR"]
}
taxa <- make_taxa("BRAMAR", "Brachyramphus marmoratus", vernacularName = "Marbled murrelet")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "EN"))
periods <- data.table(period = 1:2, year = 2022:2023)
common <- list(
  creator = "Thomas, Alaina; Duarte, Adam; Gostin, Matt; Peterson, James; Lesmeister, Damon",
  pubDate = "2025", doi = "10.5281/zenodo.17497184", sourceURL = "https://doi.org/10.5281/zenodo.17497184",
  citation = "Thomas, A., Duarte, A., Gostin, M., Peterson, J., & Lesmeister, D. (2025). Detection histories and covariates for marbled murrelet survey comparison [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.17497184",
  paperDOI = "10.1002/wsb.1640",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = "Oregon, USA: study areas JCN, ODFN and ODFS (Oregon Department of Forestry state forests; no station coordinates deposited)",
  temporalCoverage = "2022/2023")
tabs <- list(
  pam = list(cols = 1:53, nrow = 3517L, code = "acoustic",
    title = "Marbled murrelet daily passive acoustic detections at 69 inland stations in two years, Oregon, 2022-2023",
    proto = "Autonomous recording units at inland forest stations; each recorded day is a survey with a detection (1) or not (0) of marbled murrelet calls, as deposited.",
    closure = "open", cnote = "Daily acoustic surveys over up to 53 days per station-year in the breeding season; station use may change over that span. Same stations as the audio-visual table (thomas_2025_oregon_murrelet_av_occ).",
    other = "thomas_2025_oregon_murrelet_av_occ"),
  av = list(cols = 54:57, nrow = 294L, code = "point_count",
    title = "Marbled murrelet audio-visual survey detections, 2-4 visits per station-year at 69 inland stations, Oregon, 2022-2023",
    proto = "Audio-visual station surveys (observers recording murrelet detections by sight or sound at dawn) of the standard inland murrelet protocol; 2-4 visits per station-year.",
    closure = "closed", cnote = "Occupancy assumed closed across the 2-4 visits of a breeding season. Same stations as the passive acoustic table (thomas_2025_oregon_murrelet_pam_occ), surveyed on other days.",
    other = "thomas_2025_oregon_murrelet_pam_occ"))
for (k in names(tabs)) {
  S <- tabs[[k]]; TABLE <- sprintf("thomas_2025_oregon_murrelet_%s_occ", k)
  long <- order_eco(build(S$cols))
  stopifnot(nrow(long) == S$nrow, !anyDuplicated(long[, .(unit, period, occasion)]), !anyNA(long$date))
  cat(sprintf("  %s: %d rows, %d stations, %d detections\n", k, nrow(long), uniqueN(long$unit), sum(long$y)))
  dataset <- c(common, list(
    title = S$title,
    abstract = "Passive acoustic monitoring (PAM) and audio-visual (AV) surveys for marbled murrelets at inland stations in three study areas on the Oregon coast in 2022 and 2023, deposited as one encounter-history matrix to compare the two methods' cost and detection. eco ships the two methods as two tables because their surveys were on different days.",
    samplingProtocol = S$proto, samplingProtocolCode = S$code, closure = S$closure, closureNote = S$cnote,
    covariateNote = "unit_study_area: JCN, ODFN or ODFS. obs_temp_c: temperature (degrees C) of the survey. obs_noise_dbfs: background noise (dBFS) of the survey, as deposited (blank on 19 AV visits).",
    notShipped = list(stray_temperature = "4 temperature values in cells with no survey (no detection, date or survey type)",
                      other_method = sprintf("the other method's surveys are in %s", S$other),
                      model_output = "the paper's occupancy and detection estimates"),
    notes = sprintf("Companion table: %s (same stations, other method). Station identity across years from the station id without its year suffix.", S$other)))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Marbled murrelet (Brachyramphus marmoratus) %s detections at 69 inland stations in Oregon, 2022-2023, with temperature and noise.", if (k == "pam") "daily passive acoustic" else "audio-visual survey"),
    url = "https://doi.org/10.5281/zenodo.17497184",
    reference = "Thomas, A., Duarte, A., Gostin, M., Peterson, J. & Lesmeister, D. (2025). Passive acoustic monitoring is a cost-effective approach to conduct inland surveys for marbled murrelets. Wildlife Society Bulletin. https://doi.org/10.1002/wsb.1640",
    doi_paper = "10.1002/wsb.1640", doi_data = "10.5281/zenodo.17497184",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "One deposited matrix split by method into two tables (separate survey sets, ruling #31).", source_via = "Zenodo (file API)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy (per year)",
    sampling_protocol = S$code, design = sprintf("Multi-season (2 years, %s)", if (k == "pam") "up to 53 daily acoustic surveys" else "2-4 audio-visual visits"),
    realm = "Terrestrial", country = "USA", coordinates = "None in source",
    notes = sprintf("IUCN EN; no coordinates. Companion: %s.", S$other))
}
