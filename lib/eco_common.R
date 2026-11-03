# eco_common.R -- shared harness for the per-dataset processing scripts in ../data/.
#
# Mirrors the division of labour in ben-domingue/irw: a data/ script reads one
# source and writes one or more tables in the standard (../standard.md, v1.0-draft);
# this file supplies what every script needs and nothing dataset-specific:
#   * download_cached()  fetch a source file once into .cache/raw/<table>/
#   * download_dryad()    fetch and unzip a whole Dryad deposit (the only anonymous route)
#   * gbif_taxon()       resolve a scientific name to a GBIF usage key (cached)
#   * coarsen_coords()   the sensitive-species coordinate rule (standard section 6)
#   * write_table()      core CSV + __taxa / __periods / __units / __traps side tables + dataset.json
#   * stage_dict_row()   append a Data-Dictionary row to dictionary/dictionary_auto.csv
#   * stage_tag_row()    append a tags row to tags/tags_auto.csv (vocabulary in tags/vocab.md)
# The converters and validator live in ../converters/eco_standard.R and are sourced here.

suppressPackageStartupMessages({ library(data.table); library(jsonlite) })

`%||%` <- function(a, b) if (is.null(a)) b else a
# repo root = nearest ancestor of the working directory holding standard_draft.md
ECO_ROOT <- normalizePath(getwd())
while (!file.exists(file.path(ECO_ROOT, "standard_draft.md")) && ECO_ROOT != dirname(ECO_ROOT)) ECO_ROOT <- dirname(ECO_ROOT)
if (!file.exists(file.path(ECO_ROOT, "standard_draft.md"))) stop("run from inside the eco repo")
source(file.path(ECO_ROOT, "converters", "eco_standard.R"))

OUT_DIR  <- file.path(ECO_ROOT, "output")
RAW_DIR  <- file.path(ECO_ROOT, ".cache", "raw")
GBIF_DIR <- file.path(ECO_ROOT, ".cache", "gbif")
DICT_FILE <- file.path(ECO_ROOT, "dictionary", "dictionary_auto.csv")
TAGS_FILE <- file.path(ECO_ROOT, "tags", "tags_auto.csv")
for (d in c(OUT_DIR, RAW_DIR, GBIF_DIR)) dir.create(d, showWarnings = FALSE, recursive = TRUE)
UA <- "eco-irw-builder/0.1 (ben.domingue@gmail.com)"

# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------
download_cached <- function(url, table, filename = NULL, quiet = TRUE, headers = NULL, subdir = NULL) {
  if (is.null(filename)) {               # Zenodo URLs end in /<file>/content
    path <- sub("\\?.*$", "", url)
    filename <- if (basename(path) == "content") basename(dirname(path)) else basename(path)
  }
  dir <- file.path(RAW_DIR, table); if (!is.null(subdir)) dir <- file.path(dir, subdir)
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  dest <- file.path(dir, filename)
  if (!file.exists(dest) || file.size(dest) == 0) {
    message("  downloading ", filename)
    ok <- try(download.file(url, dest, mode = "wb", quiet = quiet,
                            headers = c("User-Agent" = UA, headers)), silent = TRUE)
    if (inherits(ok, "try-error") || !file.exists(dest) || file.size(dest) == 0)
      stop("download failed: ", url)
  }
  dest
}

# NEON: the data endpoints (/api/v0/data/<product>/<site>/<month>) return 403
# without an API token; tokens are free with a NEON account and are read from
# the NEON_TOKEN environment variable (never from the repo). One release tag is
# pinned so a rebuild sees the same files; NEON's citation names it. Every
# site-month of the release is listed from the product endpoint, each month's
# file list is cached, and only the basic-package CSVs of the NEON tables asked
# for are fetched into .cache/raw/<table>/neon/<site>/<month>/. Returns a named
# list of data.tables, one per NEON table, stacked over site-months with
# `neon_site` and `neon_month` columns added, plus attributes `release`,
# `n_site_months`, `site_months`, `productDoi`. The token rate limit is 8
# requests/s (burst 2000); sequential downloads stay under it without sleeping.
download_neon <- function(product, table, release, tables, sites = NULL, months = NULL) {
  token <- Sys.getenv("NEON_TOKEN")
  if (!nzchar(token)) stop("NEON data downloads need an API token: set NEON_TOKEN (free with a NEON account: https://data.neonscience.org, My Account > API Tokens)")
  hdr <- c("X-API-Token" = token)
  api <- "https://data.neonscience.org/api/v0"
  prod_f <- download_cached(sprintf("%s/products/%s?release=%s", api, product, release), table,
                            filename = sprintf("product_%s_%s.json", product, release), subdir = "neon")
  prod <- fromJSON(prod_f, simplifyVector = FALSE)$data
  stopifnot(identical(prod$productCode, product))
  sm <- rbindlist(lapply(prod$siteCodes, function(s)
    data.table(site = s$siteCode, month = unlist(s$availableMonths))))
  if (!is.null(sites)) sm <- sm[site %in% sites]
  if (!is.null(months)) sm <- sm[month %in% months]
  if (!nrow(sm)) stop("no site-months for ", product, " in ", release)
  setorder(sm, site, month)
  message(sprintf("  NEON %s %s: %d site-month(s) at %d site(s)", product, release, nrow(sm), uniqueN(sm$site)))
  out <- setNames(vector("list", length(tables)), tables)
  for (i in seq_len(nrow(sm))) {
    s <- sm$site[i]; m <- sm$month[i]
    sub <- file.path("neon", s, m)
    lst_f <- download_cached(sprintf("%s/data/%s/%s/%s?release=%s", api, product, s, m, release), table,
                             filename = "files.json", subdir = sub, headers = hdr)
    fl <- fromJSON(lst_f, simplifyVector = FALSE)$data
    if (!identical(fl$release, release)) stop("NEON returned release ", fl$release, " for ", s, " ", m)
    files <- unique(rbindlist(lapply(fl$files, function(f) data.table(name = f$name, url = f$url))), by = "name")
    for (tb in tables) {
      hit <- files[grepl(paste0("\\.", tb, "\\."), name) & grepl("\\.basic\\.", name)]
      if (nrow(hit) > 1) hit <- hit[order(-as.numeric(sub(".*\\.(\\d{8})T(\\d{6})Z\\.csv$", "\\1\\2", name)))][1]
      if (!nrow(hit)) next
      f <- try(download_cached(hit$url, table, filename = hit$name, subdir = sub, headers = hdr), silent = TRUE)
      if (inherits(f, "try-error")) {       # the signed URLs in a cached files.json expire after 7 days: relist once
        unlink(lst_f)
        lst_f <- download_cached(sprintf("%s/data/%s/%s/%s?release=%s", api, product, s, m, release), table,
                                 filename = "files.json", subdir = sub, headers = hdr)
        url2 <- Filter(function(x) identical(x$name, hit$name), fromJSON(lst_f, simplifyVector = FALSE)$data$files)[[1]]$url
        f <- download_cached(url2, table, filename = hit$name, subdir = sub, headers = hdr)
      }
      d <- fread(f, colClasses = "character", na.strings = c("", "NA"))
      d[, `:=`(neon_site = s, neon_month = m)]
      out[[tb]] <- c(out[[tb]], list(d))
    }
    if (i %% 100 == 0) message(sprintf("  ... %d / %d site-months", i, nrow(sm)))
  }
  out <- lapply(out, function(l) if (length(l)) rbindlist(l, fill = TRUE) else NULL)
  rel <- Filter(function(x) identical(x$release, release), prod$releases)
  attr(out, "release") <- release; attr(out, "n_site_months") <- nrow(sm); attr(out, "site_months") <- sm
  attr(out, "productDoi") <- if (length(rel)) rel[[1]]$productDoi$url else NA_character_
  attr(out, "productName") <- prod$productName
  out
}

# Dryad: anonymous per-file downloads return 401/403, and most deposits have no
# Zenodo mirror. The version "download" endpoint (a zip of the whole deposit) is
# served anonymously. Fetch it once into .cache/raw/<table>/dryad_<version>/ and
# return that directory; the caller asserts on the file names it expects.
download_dryad <- function(doi, table) {
  doi <- sub("^doi:", "", doi)
  api <- "https://datadryad.org/api/v2"
  meta_f <- file.path(RAW_DIR, table, "dryad_dataset.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(meta_f))
    download.file(paste0(api, "/datasets/doi%3A", URLencode(doi, reserved = TRUE)), meta_f, quiet = TRUE,
                  headers = c("User-Agent" = UA))
  meta <- fromJSON(meta_f)
  ver <- basename(meta[["_links"]][["stash:version"]][["href"]])
  lic <- meta$license %||% NA_character_
  dir <- file.path(RAW_DIR, table, paste0("dryad_", ver))
  if (!dir.exists(dir) || !length(list.files(dir))) {
    zip <- download_cached(paste0(api, "/versions/", ver, "/download"), table, filename = paste0("dryad_", ver, ".zip"))
    dir.create(dir, showWarnings = FALSE); unzip(zip, exdir = dir)
  }
  message(sprintf("  Dryad %s: version %s, licence %s, %d file(s)", doi, ver, lic, length(list.files(dir, recursive = TRUE))))
  attr(dir, "license") <- lic; attr(dir, "version") <- ver
  dir
}

# ---------------------------------------------------------------------------
# Taxonomy: GBIF backbone match, cached per name
# ---------------------------------------------------------------------------
gbif_taxon <- function(name) {
  key <- gsub("[^A-Za-z0-9]+", "_", name)
  f <- file.path(GBIF_DIR, paste0(key, ".json"))
  if (!file.exists(f)) {
    url <- paste0("https://api.gbif.org/v1/species/match?strict=true&name=", URLencode(name, reserved = TRUE))
    res <- try(fromJSON(url), silent = TRUE)
    if (inherits(res, "try-error")) res <- list(matchType = "ERROR")
    write_json(res, f, auto_unbox = TRUE)
  }
  res <- fromJSON(f)
  if (is.null(res$usageKey) || identical(res$matchType, "NONE"))
    return(list(taxonID = NA_character_, acceptedName = NA_character_, rank = NA_character_, matchType = res$matchType %||% "NONE"))
  list(taxonID = paste0("https://www.gbif.org/species/", res$usageKey),
       acceptedName = if (identical(res$status, "SYNONYM")) sub(" \\(.*$|, [0-9]{4}$", "", res$species %||% res$scientificName) else NA_character_,
       rank = tolower(res$rank %||% NA_character_), matchType = res$matchType)
}

# Build the `taxa` side table (standard section 5.1) from code -> scientific name.
# lookupName: the spelling sent to GBIF when the source's spelling does not match
# (the source spelling is kept in scientificName).
make_taxa <- function(taxon, scientificName, vernacularName = NA_character_, taxonRank = "species",
                       lookupName = scientificName, ...) {
  tx <- lapply(lookupName, gbif_taxon)
  it <- data.table(taxon = taxon, scientificName = scientificName, vernacularName = vernacularName,
                   taxonRank = taxonRank,
                   taxonID = sapply(tx, `[[`, "taxonID"),
                   gbifMatchType = sapply(tx, `[[`, "matchType"),
                   gbifAcceptedName = sapply(tx, `[[`, "acceptedName"))
  extra <- list(...)
  for (nm in names(extra)) it[, (nm) := extra[[nm]]]
  nomatch <- it[is.na(taxonID), scientificName]
  if (length(nomatch)) message("  GBIF: no match for ", paste(nomatch, collapse = ", "))
  it[]
}

# ---------------------------------------------------------------------------
# Coordinates: never finer than the source; coarsen flagged taxa to a 0.1 degree grid
# (standard section 6) and report the half-diagonal of the cell as the uncertainty.
# ---------------------------------------------------------------------------
coarsen_coords <- function(lat, lon, cell = 0.1) {
  clat <- floor(lat / cell) * cell + cell / 2
  clon <- floor(lon / cell) * cell + cell / 2
  m_per_deg <- 111320
  unc <- 0.5 * sqrt((cell * m_per_deg)^2 + (cell * m_per_deg * cos(clat * pi / 180))^2)
  list(lat = round(clat, 2), lon = round(clon, 2), uncertainty_m = round(unc))
}

# ---------------------------------------------------------------------------
# Output: core table + side tables + dataset.json. Validates before writing.
# ---------------------------------------------------------------------------
table_summary <- function(long) {
  long <- as.data.table(long)
  list(n_rows = nrow(long), n_units = uniqueN(long$unit), n_taxa = uniqueN(long$taxon),
       n_periods = if ("period" %in% names(long)) uniqueN(long$period) else 1L,
       n_occasions = if ("occasion" %in% names(long)) uniqueN(long$occasion) else 1L,
       n_surveys = nrow(unique(long[, intersect(c("unit", "trap", "period", "occasion"), names(long)), with = FALSE])),
       y_values = if (uniqueN(long$y) <= 12) paste(sort(unique(long$y)), collapse = ",") else
         sprintf("%s-%s (%d distinct)", min(long$y), max(long$y), uniqueN(long$y)),
       prop_zero = round(mean(long$y == 0), 3))
}

# Sample floor (standard section 10, ruled 2026-11-01 a reported attribute, not an
# intake gate): >= 30 units and >= 2 occasions (or >= 2 periods). Returns
# "meets" / "below (reason)"; a below-floor table is published and filterable.
floor_status <- function(s, response_type = NULL) {
  reasons <- character()
  if (s$n_units < 30) reasons <- c(reasons, sprintf("%d units < 30", s$n_units))
  # binomial_count (#34): replication is inside obs_trials, not on occasion/period
  if (max(s$n_occasions, s$n_periods) < 2 && !identical(response_type, "binomial_count")) reasons <- c(reasons, "no replication")
  if (length(reasons)) paste0("below (", paste(reasons, collapse = "; "), ")") else "meets"
}

RESPONSE_TYPES  <- c("detection", "count", "state", "ordinal", "multinomial_cell", "detection_event", "binomial_count")
SURVEY_EVIDENCE <- c("sample_table", "effort_table", "deposited_matrix", "row_presence", "inferred")
STANDARD_VERSION <- "eco v1.0-draft (2026-11-01)"

# The metadata contract of standard E10: required fields, controlled vocabularies,
# (R twin of eco_validate/checks.py; its test asserts RESPONSE_TYPES, SURVEY_EVIDENCE
# and `req` below match the Python vocabularies.)
# conditional fields. Returns a character vector of problems (empty when fine).
check_dataset_meta <- function(dataset, long, units = NULL) {
  p <- character()
  req <- c("title", "creator", "pubDate", "citation", "sourceURL", "intellectualRights",
           "samplingProtocol", "samplingProtocolCode", "responseType", "unitKind", "closure",
           "surveyEvidence", "temporalCoverage", "geographicCoverage")
  miss <- setdiff(req, names(dataset)); if (length(miss)) p <- c(p, paste("E10: missing", paste(miss, collapse = ", ")))
  rt <- dataset$responseType; se <- dataset$surveyEvidence
  if (!is.null(rt) && !rt %in% RESPONSE_TYPES) p <- c(p, sprintf("E2: responseType `%s` not in {%s}", rt, paste(RESPONSE_TYPES, collapse = ", ")))
  if (!is.null(se) && !se %in% SURVEY_EVIDENCE) p <- c(p, sprintf("E4: surveyEvidence `%s` not in {%s}", se, paste(SURVEY_EVIDENCE, collapse = ", ")))
  if (identical(se, "inferred") && is.null(dataset$surveyEvidenceNote)) p <- c(p, "E4: surveyEvidence = inferred needs surveyEvidenceNote")
  if (!is.null(rt) && rt %in% c("state", "ordinal") && is.null(dataset$stateCodes)) p <- c(p, sprintf("E2: responseType %s needs stateCodes", rt))
  if (identical(rt, "multinomial_cell") && is.null(dataset$multinomialType) && is.null(dataset$distanceBreaks))
    p <- c(p, "E2/E9: multinomial_cell needs multinomialType or distanceBreaks")
  if (identical(rt, "binomial_count")) {
    if (!identical(dataset$effortColumn, "obs_trials")) p <- c(p, "E10: binomial_count needs effortColumn = \"obs_trials\" (#34)")
    if (!"obs_trials" %in% names(long) || "occasion" %in% names(long)) p <- c(p, "E2: binomial_count needs obs_trials and no occasion column (#34)")
  }
  if (identical(rt, "detection") && !all(long$y %in% c(0, 1))) p <- c(p, "E2: responseType detection but y is not 0/1")
  if (identical(rt, "count") && any(long$y < 0 | long$y != round(long$y))) p <- c(p, "E2: responseType count but y is not a non-negative integer")
  if (!is.null(dataset$unitKind) && !dataset$unitKind %in% c("site", "individual")) p <- c(p, "E10: unitKind must be site or individual")
  has_coords <- any(grepl("^(unit_)?(decimalLatitude|x)$", c(names(long), names(units))))   # core or __units
  if (has_coords && is.null(dataset$coordinatesCoarsened)) p <- c(p, "E7: coordinates present but coordinatesCoarsened not declared")
  cc <- dataset$coordinatesCoarsened                       # null/NA, or list(value = TRUE/FALSE, method = "...") (#38)
  if (!is.null(cc) && !identical(cc, NA) &&
      !(is.list(cc) && is.logical(cc$value) && length(cc$value) == 1 && !is.na(cc$value) &&
        is.character(cc$method) && length(cc$method) == 1 && nzchar(trimws(cc$method))))
    p <- c(p, "E7/E10: coordinatesCoarsened must be NA or list(value = TRUE/FALSE, method = \"...\")")
  dbl <- grep("^(unit_unit_|period_period_|obs_obs_|taxon_taxon_)", c(names(long), names(units)), value = TRUE)
  if (length(dbl)) p <- c(p, paste("E5: level prefix doubled:", paste(dbl, collapse = ", ")))
  p
}

write_table <- function(long, name, dataset, taxa = NULL, periods = NULL, units = NULL, traps = NULL, script = NULL) {
  stopifnot(nchar(name) <= 40, grepl("^[a-z0-9_]+$", name))
  mp <- check_dataset_meta(dataset, long, units)
  if (length(mp)) stop(sprintf("%s fails the metadata contract: %s", name, paste(mp, collapse = "; ")))
  long <- order_eco(long)
  v <- validate_eco(long)
  if (!v$ok) stop(sprintf("%s fails validate_eco: %s", name, paste(v$problems, collapse = "; ")))
  if (!is.null(taxa)) {
    stopifnot(setequal(taxa$taxon, unique(long$taxon)))
    fwrite(taxa, file.path(OUT_DIR, paste0(name, "__taxa.csv")))
  }
  if (!is.null(periods)) fwrite(periods, file.path(OUT_DIR, paste0(name, "__periods.csv")))
  if (!is.null(units))   fwrite(units,   file.path(OUT_DIR, paste0(name, "__units.csv")))
  if (!is.null(traps))   fwrite(traps,   file.path(OUT_DIR, paste0(name, "__traps.csv")))
  s <- table_summary(long)
  dataset <- c(list(table = name), dataset,
               list(summary = s, sampleFloor = floor_status(s, dataset$responseType),
                    columns = names(long),
                    standardVersion = STANDARD_VERSION,
                    builtBy = "data/ script, see `script`", script = script %||% NA_character_,
                    buildDate = format(Sys.Date())))
  write_json(dataset, file.path(OUT_DIR, paste0(name, "__dataset.json")), auto_unbox = TRUE, pretty = TRUE, na = "null")
  fwrite(long, file.path(OUT_DIR, paste0(name, ".csv")))
  cat(sprintf("%s.csv: rows=%d units=%d taxa=%d periods=%d occasions=%d y={%s} zeros=%.0f%% floor=%s\n",
              name, s$n_rows, s$n_units, s$n_taxa, s$n_periods, s$n_occasions, s$y_values,
              100 * s$prop_zero, dataset$sampleFloor))
  invisible(dataset)
}

# ---------------------------------------------------------------------------
# Staging rows for the dictionary and the tags file.
# Same header as ben-domingue/irw automated_finding/dictionary_auto.csv, so a row
# could be unioned into an IRW-style dictionary unchanged. One row per table;
# re-running a script replaces that table's row.
# ---------------------------------------------------------------------------
DICT_COLS <- c("table", "description", "source_url", "reference", "doi_paper", "doi_data",
               "original_license", "derived_license", "notes", "contributor", "date", "source_via")
# Counts and sample_floor are NOT tag columns: metadata/01_metadata.R computes them
# from output/, so the two can never disagree (ARCHITECTURE.md, rule 1).
TAG_COLS <- c("table", "rater", "taxon_group", "response_type", "model_family", "unit_kind",
              "sampling_protocol", "design", "realm", "country", "coordinates", "notes", "status")

.upsert_row <- function(file, cols, row) {
  row <- as.list(row)
  missing <- setdiff(cols, names(row)); for (m in missing) row[[m]] <- ""
  extra <- setdiff(names(row), cols); if (length(extra)) stop("unknown column(s): ", paste(extra, collapse = ", "))
  new <- as.data.table(lapply(row[cols], function(x) { x <- as.character(x); if (!length(x) || is.na(x)) "" else x }))
  # guard against spreadsheet formula injection on paste
  for (cc in cols) if (grepl("^[=+@-]", new[[cc]])) new[[cc]] <- paste0("'", new[[cc]])
  # read.csv, not fread: data.table 1.18.4 fread does not unescape doubled quotes inside a
  # quoted field, so every upsert round trip doubled them (the Kleiven reference grew to 262 kB)
  old <- if (file.exists(file)) as.data.table(read.csv(file, colClasses = "character", check.names = FALSE, na.strings = character())) else as.data.table(setNames(replicate(length(cols), character(), simplify = FALSE), cols))
  old <- old[table != new$table]
  out <- rbind(old, new, fill = TRUE)[, cols, with = FALSE]
  setorder(out, table)
  fwrite(out, file, quote = TRUE)
  invisible(out)
}

stage_dict_row <- function(table, description, url, reference = "", doi_paper = "", doi_data = "",
                           original_license, derived_license = original_license, notes = "", source_via = "") {
  stopifnot(nzchar(original_license))
  .upsert_row(DICT_FILE, DICT_COLS, list(
    table = table, description = description, source_url = url, reference = reference,
    doi_paper = doi_paper, doi_data = doi_data, original_license = original_license,
    derived_license = derived_license, notes = notes, contributor = "automated",
    date = format(Sys.Date()), source_via = source_via))
}

stage_tag_row <- function(table, dataset, taxon_group, model_family, sampling_protocol, design, realm,
                          country, coordinates, notes = "", status = "tagged") {
  .upsert_row(TAGS_FILE, TAG_COLS, list(
    table = table, rater = "claude-auto", taxon_group = taxon_group,
    response_type = dataset$responseType, model_family = model_family, unit_kind = dataset$unitKind,
    sampling_protocol = sampling_protocol, design = design, realm = realm, country = country,
    coordinates = coordinates, notes = notes, status = status))
}
