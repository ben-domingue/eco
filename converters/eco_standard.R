# eco_standard.R — converters between native ecological data structures and the
# eco long format (see ../standard.md, clauses E1-E10; ../standard_draft.md has the history).
#
# Core columns: unit, taxon, y [, y_raw, trap, period, occasion, date, observer,
#               treat, cluster_id, unit_*, period_*, obs_*, taxon_*]
# Key: (unit, taxon, trap, period, occasion), absent columns treated as 1.
# Rule: a row exists iff a survey happened. NA in a native matrix -> no row.
# date is ISO 8601 (YYYY-MM-DD or YYYY-MM-DDThh:mm[:ss][Z]); eco_to_irw() turns it into seconds.
# Nomenclature v0.3 (2026-10-31): unit/taxon/y replace IRW's id/item/resp.

suppressPackageStartupMessages({ library(data.table) })

KEY_COLS <- c("unit", "taxon", "trap", "period", "occasion")
CORE_FIXED <- c("unit", "taxon", "y", "y_raw", "trap", "period", "occasion", "date", "observer", "treat", "cluster_id")
PREFIX_RE <- "^(unit_|period_|obs_|taxon_)"
ISO_DATE_RE <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?)?$"

# ---------------------------------------------------------------------------
# Generic: array -> long
# ---------------------------------------------------------------------------

# y: M x J (single species) or M x J x K (species on 3rd dim).
# site_covs: data.frame with M rows (-> unit_*)
# obs_covs: named list of M x J matrices (-> obs_*)
# period: optional integer vector of length J giving the primary period of each
#   column (for M x (T*J) layouts); occasion within period is computed.
# period_covs: named list of M x T matrices (-> period_*)
# taxon_covs: data.frame with K rows (-> taxon_*)
array_to_eco <- function(y, taxon = "SP1", site_ids = NULL, site_covs = NULL,
                         obs_covs = NULL, period = NULL, period_covs = NULL,
                         taxon_covs = NULL, y_raw = NULL) {
  if (length(dim(y)) == 2) y <- array(y, dim = c(dim(y), 1),
                                      dimnames = list(rownames(y), colnames(y), taxon))
  M <- dim(y)[1]; J <- dim(y)[2]; K <- dim(y)[3]
  taxa <- if (!is.null(dimnames(y)[[3]])) dimnames(y)[[3]] else
    if (length(taxon) == K) taxon else paste0(taxon, seq_len(K))
  if (is.null(site_ids)) site_ids <- if (!is.null(rownames(y))) rownames(y) else seq_len(M)
  if (is.null(period)) period <- rep(1L, J)
  occasion <- ave(seq_len(J), period, FUN = seq_along)

  long <- data.table(
    unit       = rep(site_ids, times = J * K),
    taxon     = rep(taxa, each = M * J),
    y     = as.vector(y),
    period   = rep(rep(period,   each = M), times = K),
    occasion = rep(rep(occasion, each = M), times = K),
    .site    = rep(seq_len(M), times = J * K),
    .col     = rep(rep(seq_len(J), each = M), times = K)
  )
  if (!is.null(y_raw)) long[, y_raw := as.vector(y_raw)]
  long <- long[!is.na(y)]                      # the explicit-zero rule

  if (!is.null(site_covs)) {
    sc <- as.data.table(site_covs); setnames(sc, paste0("unit_", names(sc)))
    sc[, .site := seq_len(M)]
    long <- merge(long, sc, by = ".site", sort = FALSE)
  }
  if (!is.null(obs_covs)) for (nm in names(obs_covs)) {
    m <- obs_covs[[nm]]
    long[, (paste0("obs_", nm)) := m[cbind(.site, .col)]]
  }
  if (!is.null(period_covs)) for (nm in names(period_covs)) {
    m <- period_covs[[nm]]
    long[, (paste0("period_", nm)) := m[cbind(.site, period)]]
  }
  if (!is.null(taxon_covs)) {
    ic <- as.data.table(taxon_covs); setnames(ic, paste0("taxon_", names(ic)))
    ic[, taxon := taxa]
    long <- merge(long, ic, by = "taxon", sort = FALSE)
  }
  long[, c(".site", ".col") := NULL]
  if (all(long$period == 1L)) long[, period := NULL]
  order_eco(long)
}

# long -> array (M x J x K), padding unsurveyed cells with NA.
# Returns list(y, site_ids, taxa, period (per column), obs_covs, site_covs, ...)
eco_to_array <- function(long, site_ids = NULL, taxa = NULL, drop_species = TRUE) {
  long <- as.data.table(long)
  if (!"period" %in% names(long)) long[, period := 1L]
  if (!"occasion" %in% names(long)) long[, occasion := 1L]
  if (is.null(site_ids)) site_ids <- unique(long$unit)
  if (is.null(taxa)) taxa <- unique(long$taxon)
  cols <- unique(long[, .(period, occasion)])[order(period, occasion)]
  cols[, .col := .I]
  long <- merge(long, cols, by = c("period", "occasion"))
  long[, .site := match(unit, site_ids)]
  long[, .k := match(taxon, taxa)]
  M <- length(site_ids); J <- nrow(cols); K <- length(taxa)
  y <- array(NA_real_, dim = c(M, J, K), dimnames = list(site_ids, NULL, taxa))
  y[cbind(long$.site, long$.col, long$.k)] <- long$y

  pull_matrix <- function(col, by_cols = c(".site", ".col")) {
    m <- matrix(NA, M, J)
    v <- long[[col]]
    m[cbind(long$.site, long$.col)] <- v
    if (is.character(v) || is.factor(v)) { mm <- matrix(NA_character_, M, J); mm[cbind(long$.site, long$.col)] <- as.character(v); m <- mm }
    m
  }
  obs_names <- grep("^obs_", names(long), value = TRUE)
  obs_covs <- setNames(lapply(obs_names, pull_matrix), sub("^obs_", "", obs_names))
  unit_names <- grep("^unit_", names(long), value = TRUE)
  site_covs <- NULL
  if (length(unit_names)) {
    u <- unique(long[, c(".site", unit_names), with = FALSE])
    stopifnot(!anyDuplicated(u$.site))          # unit_ must be constant within unit
    site_covs <- as.data.frame(matrix(NA, M, length(unit_names), dimnames = list(NULL, unit_names)))
    for (cc in unit_names) site_covs[[cc]] <- u[[cc]][match(seq_len(M), u$.site)]   # NA for units with no rows
    names(site_covs) <- sub("^unit_", "", unit_names)
  }
  pc_names <- grep("^period_", names(long), value = TRUE)
  period_covs <- NULL
  if (length(pc_names)) {
    Tn <- max(cols$period)
    period_covs <- setNames(lapply(pc_names, function(nm) {
      m <- matrix(NA, M, Tn); m[cbind(long$.site, long$period)] <- long[[nm]]; m
    }), sub("^period_", "", pc_names))
  }
  ic_names <- grep("^taxon_", names(long), value = TRUE)
  taxon_covs <- NULL
  if (length(ic_names)) {
    taxon_covs <- unique(long[, c(".k", ic_names), with = FALSE])[order(.k)]
    taxon_covs <- as.data.frame(taxon_covs[, ic_names, with = FALSE])
    names(taxon_covs) <- sub("^taxon_", "", ic_names)
  }
  if (drop_species && K == 1) y <- y[, , 1, drop = TRUE]
  list(y = y, site_ids = site_ids, taxa = taxa, period = cols$period,
       occasion = cols$occasion, obs_covs = obs_covs, site_covs = site_covs,
       period_covs = period_covs, taxon_covs = taxon_covs)
}

# ---------------------------------------------------------------------------
# unmarked frames
# ---------------------------------------------------------------------------

# unmarkedFrameOccu / unmarkedFramePCount / unmarkedMultFrame -> long
umf_to_eco <- function(umf, taxon = "SP1", site_ids = NULL) {
  y <- unmarked::getY(umf)
  M <- nrow(y); J <- ncol(y)
  sc <- unmarked::siteCovs(umf)
  oc <- unmarked::obsCovs(umf)      # data.frame, M*J rows, site-major (site varies slowest)
  obs_list <- NULL
  if (!is.null(oc)) obs_list <- lapply(oc, function(v) matrix(v, M, J, byrow = TRUE))
  period <- NULL; period_covs <- NULL
  if (methods::is(umf, "unmarkedMultFrame")) {
    Tn <- umf@numPrimary
    period <- rep(seq_len(Tn), each = J / Tn)
    ysc <- unmarked::yearlySiteCovs(umf)
    if (!is.null(ysc)) period_covs <- lapply(ysc, function(v) matrix(v, M, Tn, byrow = TRUE))
  }
  array_to_eco(y, taxon = taxon, site_ids = site_ids, site_covs = sc,
               obs_covs = obs_list, period = period, period_covs = period_covs)
}

# long -> unmarked frame of the requested type
eco_to_umf <- function(long, type = c("occu", "pcount", "colext"), site_ids = NULL) {
  type <- match.arg(type)
  a <- eco_to_array(long, site_ids = site_ids)
  y <- a$y; M <- nrow(y); J <- ncol(y)
  obsCovs <- NULL
  if (length(a$obs_covs)) obsCovs <- as.data.frame(lapply(a$obs_covs, function(m) as.vector(t(m))))
  if (type == "occu")   return(unmarked::unmarkedFrameOccu(y = y, siteCovs = a$site_covs, obsCovs = obsCovs))
  if (type == "pcount") return(unmarked::unmarkedFramePCount(y = y, siteCovs = a$site_covs, obsCovs = obsCovs))
  Tn <- max(a$period)
  ysc <- NULL
  if (length(a$period_covs)) ysc <- as.data.frame(lapply(a$period_covs, function(m) as.vector(t(m))))
  unmarked::unmarkedMultFrame(y = y, siteCovs = a$site_covs, obsCovs = obsCovs,
                              yearlySiteCovs = ysc, numPrimary = Tn)
}

# ---------------------------------------------------------------------------
# Multinomial N-mixture (unmarkedFrameMPois): cells on `occasion`, label in y_raw
# ---------------------------------------------------------------------------
mpois_to_eco <- function(umf, taxon = "SP1") {
  y <- unmarked::getY(umf); M <- nrow(y); C <- ncol(y)
  labs <- if (!is.null(colnames(y))) colnames(y) else as.character(seq_len(C))
  oc <- unmarked::obsCovs(umf)
  obs_list <- if (!is.null(oc)) lapply(oc, function(v) matrix(v, M, C, byrow = TRUE)) else NULL
  raw <- matrix(labs, M, C, byrow = TRUE)
  long <- array_to_eco(y, taxon = taxon, site_covs = unmarked::siteCovs(umf),
                       obs_covs = obs_list, y_raw = raw)
  attr(long, "multinomialType") <- umf@piFun
  long
}
eco_to_mpois <- function(long, type, obsToY = NULL) {
  a <- eco_to_array(long)
  y <- a$y
  colnames(y) <- as.data.table(long)[order(occasion), unique(y_raw)]
  obsCovs <- NULL
  if (length(a$obs_covs)) obsCovs <- as.data.frame(lapply(a$obs_covs, function(m) as.vector(t(m))))
  unmarked::unmarkedFrameMPois(y = y, siteCovs = a$site_covs, obsCovs = obsCovs,
                               type = type, obsToY = obsToY)
}

# ---------------------------------------------------------------------------
# Capture histories (marked / RMark style data.frame with ch, freq, covariates)
# ---------------------------------------------------------------------------
ch_to_eco <- function(df, taxon = "SP1", ch_col = "ch", freq_col = "freq") {
  df <- as.data.frame(df)
  ch <- as.character(df[[ch_col]])
  Tn <- unique(nchar(ch)); stopifnot(length(Tn) == 1)
  freq <- if (freq_col %in% names(df)) df[[freq_col]] else rep(1L, nrow(df))
  if (any(freq < 0)) stop("negative freq (losses on capture) not handled in this converter")
  # expand frequency-aggregated histories into individuals
  idx <- rep(seq_len(nrow(df)), times = freq)
  covs <- df[idx, setdiff(names(df), c(ch_col, freq_col)), drop = FALSE]
  CH <- do.call(rbind, strsplit(ch[idx], ""))
  storage.mode(CH) <- "integer"
  long <- array_to_eco(CH, taxon = taxon, site_ids = seq_along(idx), site_covs = covs,
                       period = seq_len(Tn))
  # with one secondary occasion per primary period, occasion is redundant
  long[, occasion := NULL]
  long
}
eco_to_ch <- function(long, collapse_freq = TRUE) {
  long <- as.data.table(long)
  if (!"occasion" %in% names(long)) long[, occasion := 1L]
  a <- eco_to_array(long)
  CH <- a$y
  if (any(is.na(CH))) stop("capture history has unsurveyed cells; marked cannot represent this")
  ch <- apply(CH, 1, paste, collapse = "")
  out <- data.frame(ch = ch, stringsAsFactors = FALSE)
  if (!is.null(a$site_covs)) out <- cbind(out, a$site_covs)
  if (collapse_freq) {
    out <- as.data.table(out)[, .(freq = .N), by = names(out)]
    out <- as.data.frame(out)
  }
  out
}

# ---------------------------------------------------------------------------
# Validation and I/O
# ---------------------------------------------------------------------------
order_eco <- function(long) {
  long <- as.data.table(long)
  first <- intersect(CORE_FIXED, names(long))
  rest <- c(grep("^unit_", names(long), value = TRUE),
            grep("^period_", names(long), value = TRUE),
            grep("^obs_", names(long), value = TRUE),
            grep("^taxon_", names(long), value = TRUE))
  other <- setdiff(names(long), c(first, rest))
  setcolorder(long, c(first, rest, other))
  keycols <- intersect(c("taxon", "trap", "period", "occasion", "unit"), names(long))
  setorderv(long, keycols)
  long[]
}

validate_eco <- function(long) {
  long <- as.data.table(long)
  problems <- character()
  req <- c("unit", "taxon", "y")
  if (!all(req %in% names(long))) problems <- c(problems, "E1: missing required column(s) unit, taxon, y")
  if (!is.numeric(long$y)) problems <- c(problems, "E2: y not numeric")
  if (anyNA(long$y)) problems <- c(problems, "E4: NA in y (a missing row, not an NA, encodes 'not surveyed')")
  key <- intersect(KEY_COLS, names(long))
  if (anyDuplicated(long, by = key)) problems <- c(problems, sprintf("E3: duplicate key (%s)", paste(key, collapse = ",")))
  bad <- setdiff(names(long), CORE_FIXED)
  bad <- bad[!grepl(PREFIX_RE, bad)]
  if (length(bad)) problems <- c(problems, paste("E1/E5: undefined column(s):", paste(bad, collapse = ", ")))
  if ("date" %in% names(long)) {
    d <- as.character(long$date); d <- d[!is.na(d) & nzchar(d)]
    if (!all(grepl(ISO_DATE_RE, d))) problems <- c(problems, "E8: date not ISO 8601 (YYYY-MM-DD[Thh:mm[:ss]Z])")
  }
  for (cc in intersect(c("period", "occasion", "trap"), names(long)))
    if (!is.numeric(long[[cc]]) && cc != "trap") problems <- c(problems, sprintf("E8: %s must be an integer index", cc))
  # covariate level checks
  for (cc in grep("^unit_", names(long), value = TRUE))
    if (nrow(unique(long[, c("unit", cc), with = FALSE])) > uniqueN(long$unit))
      problems <- c(problems, sprintf("E5: %s varies within unit (should be obs_ or period_)", cc))
  for (cc in grep("^taxon_", names(long), value = TRUE))
    if (nrow(unique(long[, c("taxon", cc), with = FALSE])) > uniqueN(long$taxon))
      problems <- c(problems, sprintf("E5: %s varies within taxon", cc))
  if ("period" %in% names(long)) for (cc in grep("^period_", names(long), value = TRUE))
    if (nrow(unique(long[, c("unit", "period", cc), with = FALSE])) > nrow(unique(long[, .(unit, period)])))
      problems <- c(problems, sprintf("E5: %s varies within unit x period", cc))
  # explicit-zero for multi-species: every surveyed (unit,trap,period,occasion) has all taxa
  if (uniqueN(long$taxon) > 1) {
    occ <- intersect(c("unit", "trap", "period", "occasion"), names(long))
    per_survey <- long[, .N, by = occ]
    if (any(per_survey$N != uniqueN(long$taxon)))
      problems <- c(problems, "E4: some surveys lack rows for some taxa (explicit-zero rule)")
  }
  list(ok = length(problems) == 0, problems = problems,
       n_rows = nrow(long), n_units = uniqueN(long$unit), n_taxa = uniqueN(long$taxon))
}

write_eco <- function(long, name, dir = "output", taxa = NULL, dataset = NULL) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  fwrite(long, file.path(dir, paste0(name, ".csv")))
  if (!is.null(taxa)) fwrite(taxa, file.path(dir, paste0(name, "__taxa.csv")))
  if (!is.null(dataset)) jsonlite::write_json(dataset, file.path(dir, paste0(name, "__dataset.json")),
                                              auto_unbox = TRUE, pretty = TRUE)
  invisible(file.path(dir, paste0(name, ".csv")))
}
read_eco <- function(path) fread(path)

# ---------------------------------------------------------------------------
# IRW view: the same table under the IRW v1.0 names, so IRW tooling (irw-validate,
# the irw R/Python packages' readers) can consume it. unit->id, taxon->item, y->resp,
# y_raw->resp_raw, observer->rater, unit_->cov_, taxon_->itemcov_, period_->periodcov_,
# obs_ kept (an IRW-unknown prefix, warned not blocked), date -> Unix seconds (UTC),
# trap -> a C5 occasion column named trap.
# ---------------------------------------------------------------------------
eco_to_irw <- function(long) {
  long <- copy(as.data.table(long))
  ren <- c(unit = "id", taxon = "item", y = "resp", y_raw = "resp_raw", observer = "rater")
  for (nm in intersect(names(ren), names(long))) setnames(long, nm, ren[[nm]])
  nn <- names(long)
  nn <- sub("^unit_", "cov_", nn); nn <- sub("^taxon_", "itemcov_", nn); nn <- sub("^period_", "periodcov_", nn)
  setnames(long, nn)
  if ("date" %in% names(long)) {
    d <- as.character(long$date)
    dt <- suppressWarnings(as.POSIXct(ifelse(nchar(d) == 10, paste0(d, "T00:00:00Z"), d), format = "%Y-%m-%dT%H:%M", tz = "UTC"))
    dt2 <- suppressWarnings(as.POSIXct(d, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
    long[, date := as.integer(ifelse(is.na(dt), as.numeric(dt2), as.numeric(dt)))]
  }
  first <- intersect(c("id", "item", "resp", "resp_raw", "trap", "period", "occasion", "date", "rater", "treat", "cluster_id"), names(long))
  setcolorder(long, c(first, setdiff(names(long), first)))
  long[]
}

# compare two numeric vectors of estimates
same_estimates <- function(a, b, tol = 1e-6) isTRUE(all.equal(unname(a), unname(b), tolerance = tol))
