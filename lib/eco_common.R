# eco_common.R -- shared harness for the per-dataset processing scripts in ../data/.
#
# Mirrors the division of labour in ben-domingue/irw: a data/ script reads one
# source and writes one or more tables in the draft standard (../standard_draft.md);
# this file supplies what every script needs and nothing dataset-specific:
#   * download_cached()  fetch a source file once into .cache/raw/<table>/
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
download_cached <- function(url, table, filename = NULL, quiet = TRUE) {
  if (is.null(filename)) {               # Zenodo URLs end in /<file>/content
    path <- sub("\\?.*$", "", url)
    filename <- if (basename(path) == "content") basename(dirname(path)) else basename(path)
  }
  dir <- file.path(RAW_DIR, table); dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  dest <- file.path(dir, filename)
  if (!file.exists(dest) || file.size(dest) == 0) {
    message("  downloading ", filename)
    ok <- try(download.file(url, dest, mode = "wb", quiet = quiet,
                            headers = c("User-Agent" = UA)), silent = TRUE)
    if (inherits(ok, "try-error") || !file.exists(dest) || file.size(dest) == 0)
      stop("download failed: ", url)
  }
  dest
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
       n_surveys = nrow(unique(long[, intersect(c("unit", "period", "occasion"), names(long)), with = FALSE])),
       y_values = if (uniqueN(long$y) <= 12) paste(sort(unique(long$y)), collapse = ",") else
         sprintf("%s-%s (%d distinct)", min(long$y), max(long$y), uniqueN(long$y)),
       prop_zero = round(mean(long$y == 0), 3))
}

# Proposed intake floor (standard section 10, open question 2): >= 30 units and
# >= 2 occasions (or >= 2 periods). Returns "meets" / "below (reason)".
floor_status <- function(s) {
  reasons <- character()
  if (s$n_units < 30) reasons <- c(reasons, sprintf("%d units < 30", s$n_units))
  if (max(s$n_occasions, s$n_periods) < 2) reasons <- c(reasons, "no replication")
  if (length(reasons)) paste0("below (", paste(reasons, collapse = "; "), ")") else "meets"
}

write_table <- function(long, name, dataset, taxa = NULL, periods = NULL, units = NULL, traps = NULL, script = NULL) {
  stopifnot(nchar(name) <= 40, grepl("^[a-z0-9_]+$", name))
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
               list(summary = s, sampleFloor = floor_status(s),
                    columns = names(long),
                    standardVersion = "eco draft v0.3 (2026-10-31)",
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
TAG_COLS <- c("table", "rater", "taxon_group", "response_type", "model_family", "unit_kind",
              "sampling_protocol", "design", "realm", "country", "coordinates", "sample_floor",
              "n_units", "n_taxa", "n_periods", "n_occasions", "n_rows", "notes", "status")

.upsert_row <- function(file, cols, row) {
  row <- as.list(row)
  missing <- setdiff(cols, names(row)); for (m in missing) row[[m]] <- ""
  extra <- setdiff(names(row), cols); if (length(extra)) stop("unknown column(s): ", paste(extra, collapse = ", "))
  new <- as.data.table(lapply(row[cols], function(x) { x <- as.character(x); if (!length(x) || is.na(x)) "" else x }))
  # guard against spreadsheet formula injection on paste
  for (cc in cols) if (grepl("^[=+@-]", new[[cc]])) new[[cc]] <- paste0("'", new[[cc]])
  old <- if (file.exists(file)) fread(file, colClasses = "character") else as.data.table(setNames(replicate(length(cols), character(), simplify = FALSE), cols))
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
  s <- dataset$summary
  .upsert_row(TAGS_FILE, TAG_COLS, list(
    table = table, rater = "claude-auto", taxon_group = taxon_group,
    response_type = dataset$responseType, model_family = model_family, unit_kind = dataset$unitKind,
    sampling_protocol = sampling_protocol, design = design, realm = realm, country = country,
    coordinates = coordinates, sample_floor = dataset$sampleFloor,
    n_units = s$n_units, n_taxa = s$n_taxa, n_periods = s$n_periods,
    n_occasions = s$n_occasions, n_rows = s$n_rows, notes = notes, status = status))
}
