# eco_common.R -- shared harness for the per-dataset processing scripts in ../data/.
#
# Mirrors the division of labour in ben-domingue/irw: a data/ script reads one
# source and writes one or more tables in the standard (../standard.md, v1.1-draft);
# this file supplies what every script needs and nothing dataset-specific:
#   * download_cached()  fetch a source file once into .cache/raw/<table>/
#   * download_dryad()    fetch and unzip a whole Dryad deposit (the only anonymous route)
#   * gbif_taxon()       resolve a scientific name to a GBIF usage key (cached)
#   * make_taxa()        the __taxa side table; asserts EXACT GBIF matches (E6)
#   * iucn_category()    IUCN category per GBIF key, checked against the assessed name (E7)
#   * coarsen_coords()   the sensitive-species coordinate rule (standard section 6)
#   * write_table()      core CSV + __taxa / __periods / __units / __traps / __survey_taxa + dataset.json
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

# Build the `taxa` side table (standard E6) from code -> scientific name.
# lookupName: the spelling sent to GBIF when the source's spelling does not match
# (the source spelling is kept in scientificName).
# exact = TRUE stops unless every GBIF match is EXACT: strict matching can still
# resolve a homonym or an unknown name to a genus, family or kingdom (HIGHERRANK),
# which would put a wrong taxonID on the row (batch 19: Acanthurus, Naso, Chloris).
# allow_higher: taxon codes for which a HIGHERRANK match is intended (a genus-level
# record matched to its genus). no_key: taxon codes deliberately left without a
# taxonID (a pooled group or subfamily the backbone does not hold); they are not sent
# to GBIF and need a non-empty `taxonRemarks` (passed through ...) saying why (E6).
make_taxa <- function(taxon, scientificName, vernacularName = NA_character_, taxonRank = "species",
                       lookupName = scientificName, ..., exact = TRUE, allow_higher = character(),
                       no_key = character()) {
  bad <- setdiff(c(allow_higher, no_key), taxon)
  if (length(bad)) stop("make_taxa(): allow_higher / no_key name unknown taxon code(s): ", paste(bad, collapse = ", "))
  lookupName <- rep_len(lookupName, length(taxon))
  skip <- taxon %in% no_key
  tx <- lapply(seq_along(taxon), function(i)
    if (skip[i]) list(taxonID = NA_character_, acceptedName = NA_character_, rank = NA_character_, matchType = "NONE")
    else gbif_taxon(lookupName[i]))
  it <- data.table(taxon = taxon, scientificName = scientificName, vernacularName = vernacularName,
                   taxonRank = taxonRank,
                   taxonID = sapply(tx, `[[`, "taxonID"),
                   gbifMatchType = sapply(tx, `[[`, "matchType"),
                   gbifAcceptedName = sapply(tx, `[[`, "acceptedName"))
  extra <- list(...)
  for (nm in names(extra)) it[, (nm) := extra[[nm]]]
  # an intended higher-rank match (allow_higher) carries that rank, not the "species" default (E6);
  # taxonRemarks is required only where taxonID is empty
  gr <- sapply(tx, `[[`, "rank")
  up <- it$taxon %in% allow_higher & it$gbifMatchType == "HIGHERRANK" & it$taxonRank == "species" & !is.na(gr)
  if (any(up)) { it[up, taxonRank := gr[up]]
    message("  make_taxa(): taxonRank from GBIF for allow_higher taxa: ", paste(sprintf("%s=%s", it$taxon[up], gr[up]), collapse = ", ")) }
  if (length(no_key)) {
    rem <- if ("taxonRemarks" %in% names(it)) it$taxonRemarks else rep(NA_character_, nrow(it))
    miss <- it$taxon[skip & (is.na(rem) | !nzchar(trimws(rem)))]
    if (length(miss)) stop("make_taxa(): no_key taxa need a taxonRemarks saying why (E6): ", paste(miss, collapse = ", "))
  }
  if (exact) {
    off <- it[!skip & !(gbifMatchType == "EXACT" | (gbifMatchType == "HIGHERRANK" & taxon %in% allow_higher))]
    if (nrow(off)) stop("make_taxa(): GBIF match not EXACT for ",
                        paste(sprintf("%s %s (%s)", off$taxon, off$scientificName, off$gbifMatchType), collapse = "; "),
                        ". Fix the lookupName, or list the code in allow_higher (an intended higher-rank match) ",
                        "or no_key (with taxonRemarks).")
  }
  nomatch <- it[is.na(taxonID) & !skip, scientificName]
  if (length(nomatch)) message("  GBIF: no match for ", paste(nomatch, collapse = ", "))
  it[]
}

# IUCN Red List category for GBIF keys (standard E7(b)), from GBIF's
# /species/{key}/iucnRedListCategory, cached as .cache/gbif/iucn_<key>.json.
# HTTP 204 / an empty body means not assessed: "NE". The endpoint can answer for a
# different species through a synonym (batch 17: Calathus mollis came back as the
# extinct St Helena C. extensicollis: the record's name is a SYNONYM whose acceptedName
# is another species), so the category is returned only when the assessed species'
# genus + epithet (acceptedName for a synonym record) equal the key's accepted species name (from
# /species/{key}, cached as species_<key>.json); otherwise NA, with a message, and
# the script must decide. taxonID: GBIF species URLs or bare keys; NA gives NA.
iucn_category <- function(taxonID, scientificName = NULL) {
  binom <- function(x) { w <- strsplit(trimws(as.character(x %||% "")), "\\s+")[[1]]; paste(head(w, 2), collapse = " ") }
  fetch <- function(url, f) {
    if (!file.exists(f)) {
      txt <- tryCatch(paste(readLines(url, warn = FALSE), collapse = ""), error = function(e) NULL)
      if (is.null(txt)) stop("iucn_category(): request failed: ", url)
      writeLines(if (nzchar(txt)) txt else "[]", f)
    }
    txt <- paste(readLines(f, warn = FALSE), collapse = "")
    if (!nzchar(txt) || txt %in% c("[]", "{}")) NULL else fromJSON(txt, simplifyVector = FALSE)
  }
  one <- function(id, nm) {
    if (is.na(id) || !nzchar(id)) return(NA_character_)
    key <- sub(".*/", "", id)
    r <- fetch(sprintf("https://api.gbif.org/v1/species/%s/iucnRedListCategory", key),
               file.path(GBIF_DIR, paste0("iucn_", key, ".json")))
    if (is.null(r) || is.null(r$code)) return("NE")
    sp <- fetch(sprintf("https://api.gbif.org/v1/species/%s", key),
                file.path(GBIF_DIR, paste0("species_", key, ".json")))
    want <- binom(sp$species %||% sp$canonicalName)
    # the record names the species assessed: its acceptedName when the matched
    # IUCN name is a synonym (Calathus mollis Marsh. -> C. extensicollis), else its name
    got <- binom(if (identical(r$taxonomicStatus, "SYNONYM")) r$acceptedName %||% r$scientificName else r$scientificName)
    if (!nzchar(want) || !identical(want, got)) {
      message(sprintf("  iucn_category(): key %s (%s) was assessed as `%s`, not `%s`; returning NA",
                      key, nm %||% want, got, want))
      return(NA_character_)
    }
    r$code
  }
  nms <- if (is.null(scientificName)) rep(list(NULL), length(taxonID)) else as.list(scientificName)
  vapply(seq_along(taxonID), function(i) one(taxonID[i], nms[[i]]), character(1))
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
       prop_zero = round(mean(long$y == 0), 3),
       # exact counts, so metadata/01_metadata.R reads __dataset.json and never the core (#66)
       n_traps = if ("trap" %in% names(long)) uniqueN(long$trap) else 1L,
       n_zero = sum(long$y == 0), n_positive = sum(long$y > 0),
       n_units_detected = uniqueN(long$unit[long$y > 0]), max_y = max(long$y))
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
CLOSURE         <- c("closed", "open", "dependent", "none")
OCCASION_KINDS  <- c("time", "observer", "method", "spatial", "cell", "none")
TAXON_INCLUSION <- c("recorded", "target", "single")
UNIT_IDENTITY   <- c("both", "left", "right")
STANDARD_VERSION <- "eco v1.1-draft (2026-11-03)"

# The metadata contract of standard E10: required fields, controlled vocabularies,
# (R twin of eco_validate/checks.py; its test asserts RESPONSE_TYPES, SURVEY_EVIDENCE,
# CLOSURE, OCCASION_KINDS, TAXON_INCLUSION, UNIT_IDENTITY and `req` below match the
# Python vocabularies.)
# conditional fields. Returns a character vector of problems (empty when fine).
check_dataset_meta <- function(dataset, long, units = NULL, part = FALSE) {
  p <- character()
  req <- c("title", "creator", "pubDate", "citation", "sourceURL", "intellectualRights",
           "samplingProtocol", "samplingProtocolCode", "responseType", "unitKind", "closure",
           "surveyEvidence", "temporalCoverage", "geographicCoverage", "occasionKind",
           "taxonInclusion")
  miss <- setdiff(req, names(dataset)); if (length(miss)) p <- c(p, paste("E10: missing", paste(miss, collapse = ", ")))
  vocab <- list(closure = CLOSURE, taxonInclusion = TAXON_INCLUSION)
  okd <- unlist(dataset$occasionKind)
  # E8: one kind, or two distinct kinds other than none, outer first, for crossed occasions
  if (!is.null(okd) && !((length(okd) == 1 && okd %in% OCCASION_KINDS) ||
                         (length(okd) == 2 && !anyDuplicated(okd) && all(okd %in% setdiff(OCCASION_KINDS, "none")))))
    p <- c(p, sprintf("E8: occasionKind `%s` must be one of {%s} or two distinct kinds (outer first) for crossed occasions",
                      paste(okd, collapse = ","), paste(OCCASION_KINDS, collapse = ", ")))
  for (k in names(vocab)) { v <- dataset[[k]]
    if (!is.null(v) && !(length(v) == 1 && v %in% vocab[[k]]))
      p <- c(p, sprintf("E8/E10: %s `%s` not in {%s}", k, paste(v, collapse = ","), paste(vocab[[k]], collapse = ", "))) }
  has_occ <- "occasion" %in% names(long)
  if (!is.null(okd) && identical(okd, "none") == has_occ)
    p <- c(p, sprintf("E8: occasionKind = %s but the table %s an occasion column", paste(okd, collapse = ","), if (has_occ) "has" else "has no"))
  if (!has_occ && !is.null(dataset$closure) && !identical(dataset$closure, "none"))
    p <- c(p, "E8: no occasion column, so closure = none")
  if (has_occ && identical(dataset$closure, "none")) {
    grp <- intersect(c("unit", "taxon", "trap", "period"), names(long))
    if (any(as.data.table(long)[, uniqueN(occasion), by = grp]$V1 > 1)) p <- c(p, "E8: closure = none but some unit x taxon x period has several occasions")
  }
  # part = TRUE: `long` is one period part of a larger table; which taxa the table
  # holds is checked on the union by write_table_parts()
  if (!part && !is.null(dataset$taxonInclusion) && identical(dataset$taxonInclusion, "single") != (uniqueN(long$taxon) == 1))
    p <- c(p, sprintf("E10: taxonInclusion = %s with %d taxa (single exactly when one taxon)", dataset$taxonInclusion, uniqueN(long$taxon)))
  if (!part && identical(dataset$taxonInclusion, "recorded")) {
    never <- as.data.table(long)[, .(best = max(y)), by = taxon][best <= 0, taxon]
    if (length(never)) p <- c(p, sprintf("E10: taxonInclusion = recorded but %d taxon/taxa never recorded: %s",
                                         length(never), paste(head(never, 10), collapse = ", ")))
  }
  tw <- dataset$taxaWithheld
  if (!is.null(tw)) {
    if (!is.character(tw) || !length(tw) || any(!nzchar(trimws(tw)))) p <- c(p, "E10: taxaWithheld must be a character vector of taxon names")
    else if (any(tw %in% long$taxon)) p <- c(p, "E10: taxaWithheld names taxa that have core rows")
  }
  if ("unit_identity" %in% names(long) && !all(long$unit_identity %in% UNIT_IDENTITY))
    p <- c(p, sprintf("E2: unit_identity must be one of {%s}", paste(UNIT_IDENTITY, collapse = ", ")))
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

write_table <- function(long, name, dataset, taxa = NULL, periods = NULL, units = NULL, traps = NULL,
                        survey_taxa = NULL, script = NULL) {
  stopifnot(nchar(name) <= 40, grepl("^[a-z0-9_]+$", name))
  mp <- check_dataset_meta(dataset, long, units)
  if (length(mp)) stop(sprintf("%s fails the metadata contract: %s", name, paste(mp, collapse = "; ")))
  long <- order_eco(long)
  v <- validate_eco(long, survey_taxa = survey_taxa, unit_kind = dataset$unitKind)
  if (!v$ok) stop(sprintf("%s fails validate_eco: %s", name, paste(v$problems, collapse = "; ")))
  if (!is.null(taxa) && "taxonID" %in% names(taxa)) {
    rem <- if ("taxonRemarks" %in% names(taxa)) taxa$taxonRemarks else rep(NA_character_, nrow(taxa))
    nokey <- taxa$taxon[(is.na(taxa$taxonID) | !nzchar(taxa$taxonID)) & (is.na(rem) | !nzchar(trimws(rem)))]
    if (length(nokey)) stop(sprintf("%s: __taxa row(s) with no taxonID need taxonRemarks saying why (E6): %s",
                                    name, paste(nokey, collapse = ", ")))
  }
  if (!is.null(survey_taxa) && !all(survey_taxa$taxon %in% long$taxon))
    stop(sprintf("%s: __survey_taxa lists taxa with no core rows", name))
  if (!is.null(taxa)) {
    stopifnot(setequal(taxa$taxon, unique(long$taxon)))
    fwrite(taxa, file.path(OUT_DIR, paste0(name, "__taxa.csv")))
  }
  if (!is.null(periods)) fwrite(periods, file.path(OUT_DIR, paste0(name, "__periods.csv")))
  if (!is.null(units))   fwrite(units,   file.path(OUT_DIR, paste0(name, "__units.csv")))
  if (!is.null(traps))   fwrite(traps,   file.path(OUT_DIR, paste0(name, "__traps.csv")))
  if (!is.null(survey_taxa)) {
    fwrite(survey_taxa, file.path(OUT_DIR, paste0(name, "__survey_taxa.csv")))
  }
  s <- table_summary(long)
  if (!is.null(dataset$taxaWithheld)) dataset$taxaWithheld <- I(as.character(dataset$taxaWithheld))   # a JSON array even with one name
  if (length(unlist(dataset$occasionKind)) == 2) dataset$occasionKind <- I(as.character(unlist(dataset$occasionKind)))   # crossed: a JSON array
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

# A table too large for one file (standard E4: about five million rows) is stored
# as period parts: output/<name>.parts/part-NN.csv, each holding whole periods,
# with one set of side tables and one __dataset.json beside the directory, as for
# any table; on Redivis it is one table. `parts` is a list of period sets (one per
# part) and `build(periods)` returns the core rows of those periods, so only one
# part is in memory at a time. Each part is validated as written; what needs the
# whole table (taxonInclusion, __taxa against the core, the E4.2 taxon set across
# parts, the summary) is checked on the union. __dataset.json gains `parts`
# (file, periods, n_rows), which eco-validate checks against the files.
write_table_parts <- function(parts, build, name, dataset, taxa = NULL, periods = NULL, units = NULL,
                              traps = NULL, script = NULL) {
  stopifnot(nchar(name) <= 40, grepl("^[a-z0-9_]+$", name), is.list(parts), length(parts) >= 2,
            is.function(build), !anyDuplicated(unlist(parts)))
  dir <- file.path(OUT_DIR, paste0(name, ".parts"))
  unlink(dir, recursive = TRUE); dir.create(dir)
  unlink(file.path(OUT_DIR, paste0(name, ".csv")))       # never a stale single-file twin
  cols <- NULL; taxa_set <- NULL; best <- NULL; units_seen <- character(); occ_seen <- integer()
  traps_seen <- character(); units_hit <- character(); n_pos <- 0; max_y <- -Inf
  n_rows <- 0; n_surveys <- 0; n_zero <- 0; yvals <- numeric(); manifest <- vector("list", length(parts))
  for (k in seq_along(parts)) {
    long <- order_eco(build(parts[[k]]))
    tag <- sprintf("%s part %d of %d", name, k, length(parts))
    if (!nrow(long)) stop(tag, ": no rows")
    if (!all(unique(long$period) %in% parts[[k]])) stop(tag, ": rows outside the part's periods")
    mp <- check_dataset_meta(dataset, long, units, part = TRUE)
    if (length(mp)) stop(sprintf("%s fails the metadata contract: %s", tag, paste(mp, collapse = "; ")))
    v <- validate_eco(long, unit_kind = dataset$unitKind)
    if (!v$ok) stop(sprintf("%s fails validate_eco: %s", tag, paste(v$problems, collapse = "; ")))
    if (is.null(cols)) cols <- names(long) else if (!identical(names(long), cols)) stop(tag, ": columns differ from part 1")
    tx <- sort(unique(long$taxon))
    if (is.null(taxa_set)) taxa_set <- tx else if (!identical(tx, taxa_set))
      stop(tag, ": taxon set differs from part 1 (E4.2: every survey carries every taxon)")
    b <- long[, .(m = max(y)), by = taxon]
    best <- if (is.null(best)) b else rbind(best, b)[, .(m = max(m)), by = taxon]
    units_seen <- union(units_seen, unique(long$unit))
    if ("occasion" %in% names(long)) occ_seen <- union(occ_seen, unique(long$occasion))
    n_rows <- n_rows + nrow(long); n_zero <- n_zero + sum(long$y == 0)
    n_pos <- n_pos + sum(long$y > 0); max_y <- max(max_y, long$y)
    units_hit <- union(units_hit, unique(long$unit[long$y > 0]))
    if ("trap" %in% names(long)) traps_seen <- union(traps_seen, unique(as.character(long$trap)))
    n_surveys <- n_surveys + nrow(unique(long[, intersect(c("unit", "trap", "period", "occasion"), names(long)), with = FALSE]))
    if (length(yvals) <= 12) yvals <- union(yvals, unique(long$y))
    yr <- if (k == 1) range(long$y) else range(c(yr, range(long$y)))
    fn <- sprintf("part-%02d.csv", k)
    fwrite(long, file.path(dir, fn))
    manifest[[k]] <- list(file = fn, periods = I(sort(unique(as.integer(long$period)))), n_rows = nrow(long))
    cat(sprintf("  %s: %s rows, periods %d-%d\n", tag, format(nrow(long), big.mark = ",", scientific = FALSE), min(long$period), max(long$period)))
    rm(long, b); gc(FALSE)
  }
  ti <- dataset$taxonInclusion
  if (identical(ti, "single") != (length(taxa_set) == 1)) stop(sprintf("%s: taxonInclusion = %s with %d taxa", name, ti, length(taxa_set)))
  if (identical(ti, "recorded") && any(best$m <= 0))
    stop(sprintf("%s: taxonInclusion = recorded but %d taxa never recorded: %s", name, sum(best$m <= 0), paste(head(best[m <= 0, taxon], 10), collapse = ", ")))
  if (!is.null(taxa) && "taxonID" %in% names(taxa)) {
    rem <- if ("taxonRemarks" %in% names(taxa)) taxa$taxonRemarks else rep(NA_character_, nrow(taxa))
    nokey <- taxa$taxon[(is.na(taxa$taxonID) | !nzchar(taxa$taxonID)) & (is.na(rem) | !nzchar(trimws(rem)))]
    if (length(nokey)) stop(sprintf("%s: __taxa row(s) with no taxonID need taxonRemarks saying why (E6): %s", name, paste(nokey, collapse = ", ")))
  }
  if (!is.null(taxa)) { stopifnot(setequal(taxa$taxon, taxa_set)); fwrite(taxa, file.path(OUT_DIR, paste0(name, "__taxa.csv"))) }
  if (!is.null(periods)) fwrite(periods, file.path(OUT_DIR, paste0(name, "__periods.csv")))
  if (!is.null(units))   fwrite(units,   file.path(OUT_DIR, paste0(name, "__units.csv")))
  if (!is.null(traps))   fwrite(traps,   file.path(OUT_DIR, paste0(name, "__traps.csv")))
  s <- list(n_rows = n_rows, n_units = length(units_seen), n_taxa = length(taxa_set),
            n_periods = length(unique(unlist(lapply(manifest, `[[`, "periods")))),
            n_occasions = if (length(occ_seen)) length(occ_seen) else 1L, n_surveys = n_surveys,
            y_values = if (length(yvals) <= 12) paste(sort(yvals), collapse = ",") else sprintf("%s-%s (more than 12 distinct)", yr[1], yr[2]),
            prop_zero = round(n_zero / n_rows, 3),
            n_traps = if (length(traps_seen)) length(traps_seen) else 1L,
            n_zero = n_zero, n_positive = n_pos, n_units_detected = length(units_hit), max_y = max_y)
  if (length(unlist(dataset$occasionKind)) == 2) dataset$occasionKind <- I(as.character(unlist(dataset$occasionKind)))
  dataset <- c(list(table = name), dataset,
               list(summary = s, sampleFloor = floor_status(s, dataset$responseType), columns = cols,
                    parts = manifest, standardVersion = STANDARD_VERSION,
                    builtBy = "data/ script, see `script`", script = script %||% NA_character_,
                    buildDate = format(Sys.Date())))
  write_json(dataset, file.path(OUT_DIR, paste0(name, "__dataset.json")), auto_unbox = TRUE, pretty = TRUE, na = "null")
  cat(sprintf("%s.parts: %d parts, rows=%s units=%d taxa=%d periods=%d occasions=%d zeros=%.0f%% floor=%s\n",
              name, length(parts), format(n_rows, big.mark = ",", scientific = FALSE), s$n_units, s$n_taxa, s$n_periods, s$n_occasions,
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
