# The converters between native ecological data structures and the eco long
# format (standard clauses E1-E10; https://ben-domingue.github.io/eco/standard.html).
# This file is also sourced directly by the repository's converters/eco_standard.R
# shim, so the data/ build scripts and the package share one implementation.
#
# Core columns: unit, taxon, y [, y_raw, trap, period, occasion, date, observer,
#               treat, cluster_id, unit_*, period_*, obs_*, taxon_*]
# Key: (unit, taxon, trap, period, occasion), absent columns treated as 1.
# Rule: a row exists iff a survey happened. NA in a native matrix -> no row.

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
#' Native arrays to the long format and back
#'
#' `array_to_eco()` takes a site x occasion (x taxon) array as `unmarked` and
#' the Bayesian model code expect it, with `NA` for cells never surveyed, and
#' returns the long table: one row per surveyed cell, no `NA` in `y`.
#' `eco_to_array()` is its inverse: unsurveyed cells come back as `NA`, and
#' `site_ids` / `taxa` fix the order (and pad units or taxa that have no rows).
#'
#' @param y Numeric matrix M x J, or array M x J x K with taxa on the third
#'   dimension (dimnames supply unit ids and taxon codes when present).
#' @param taxon Taxon code(s) when `y` has no third dimnames.
#' @param site_ids Unit ids, length M (default rownames or 1..M).
#' @param site_covs data.frame with M rows, becomes `unit_*`.
#' @param obs_covs Named list of M x J matrices, becomes `obs_*`.
#' @param period Integer vector of length J: the primary period of each column
#'   of `y` (for M x (T*J) layouts); occasion within period is computed.
#' @param period_covs Named list of M x T matrices, becomes `period_*`.
#' @param taxon_covs data.frame with K rows, becomes `taxon_*`.
#' @param y_raw Optional array like `y` of the recorded values behind a recode.
#' @return `array_to_eco()`: a data.table in the eco format. `eco_to_array()`:
#'   a list with `y` (M x J, or M x J x K when there are several taxa and
#'   `drop_species` is `FALSE` or K > 1), `site_ids`, `taxa`, `period` and
#'   `occasion` (per column of `y`), `obs_covs`, `site_covs`, `period_covs`,
#'   `taxon_covs`.
#' @examples
#' a <- eco_to_array(schank_2015_tapir_occ)
#' dim(a$y)
#' back <- array_to_eco(a$y, taxon = a$taxa, site_ids = a$site_ids, site_covs = a$site_covs)
#' nrow(back) == nrow(schank_2015_tapir_occ)
#' @export
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
  # The level prefix is added here; a name that already carries it would come out
  # doubled (unit_unit_sex), which E5 rejects (#38).
  for (a in list(list(site_covs, "site_covs", "unit_"), list(obs_covs, "obs_covs", "obs_"),
                 list(period_covs, "period_covs", "period_"), list(taxon_covs, "taxon_covs", "taxon_"))) {
    pre <- grep(paste0("^", a[[3]]), names(a[[1]]), value = TRUE)
    if (length(pre)) stop(sprintf("%s names already carry the `%s` prefix (%s); array_to_eco() adds it, pass bare names",
                                  a[[2]], a[[3]], paste(pre, collapse = ", ")), call. = FALSE)
  }

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
#' @param long A table in the eco format (data.frame or data.table).
#' @param taxa Taxon codes in the order wanted on the third dimension.
#' @param drop_species Drop the third dimension when there is one taxon.
#' @rdname array_to_eco
#' @export
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
  # Drop only the taxon dimension: y[, , 1, drop = TRUE] would also drop a
  # single occasion (or a single unit) and return a vector (#33).
  if (drop_species && K == 1) y <- matrix(y[, , 1], M, J, dimnames = list(site_ids, NULL))
  list(y = y, site_ids = site_ids, taxa = taxa, period = cols$period,
       occasion = cols$occasion, obs_covs = obs_covs, site_covs = site_covs,
       period_covs = period_covs, taxon_covs = taxon_covs)
}

# ---------------------------------------------------------------------------
# unmarked frames
# ---------------------------------------------------------------------------

# unmarkedFrameOccu / unmarkedFramePCount / unmarkedMultFrame -> long
#' `unmarked` frames to the long format and back
#'
#' `eco_to_unmarked()` builds the frame a single-taxon table calls for:
#' `unmarkedFrameOccu` for detections in one period, `unmarkedFramePCount` for
#' counts, `unmarkedMultFrame` when there are several primary periods,
#' `unmarkedFrameMPois` for `multinomial_cell` tables. Pass `family` to
#' choose. A table with several taxa must be split by `taxon` first (or use
#' [eco_to_array()], which keeps the taxon dimension). `umf_to_eco()` and
#' `mpois_to_eco()` go the other way.
#'
#' @param umf An `unmarkedFrameOccu`, `unmarkedFramePCount`, `unmarkedMultFrame`
#'   or (for `mpois_to_eco`) `unmarkedFrameMPois`.
#' @param taxon Taxon code for the single species in the frame.
#' @param site_ids Unit ids for the rows of the frame.
#' @return `eco_to_unmarked()`, `eco_to_umf()`, `eco_to_mpois()`: an `unmarked`
#'   frame. `umf_to_eco()`, `mpois_to_eco()`: a data.table in the eco format.
#' @examples
#' umf <- eco_to_unmarked(schank_2015_tapir_occ)
#' umf
#' if (requireNamespace("unmarked", quietly = TRUE)) unmarked::occu(~1 ~1, umf)
#' @export
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
#' @param long A table in the eco format.
#' @param type For `eco_to_umf()`: `"occu"`, `"pcount"` or `"colext"`
#'   (multi-period). For `eco_to_mpois()`: `"removal"`, `"double"` or
#'   `"depDouble"`, as `unmarked::unmarkedFrameMPois()` takes it.
#' @rdname umf_to_eco
#' @export
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
#' @rdname umf_to_eco
#' @export
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
#' @param obsToY For `eco_to_mpois()`: passed to `unmarked::unmarkedFrameMPois()`.
#' @rdname umf_to_eco
#' @export
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
#' Capture histories to the long format and back
#'
#' `ch_to_eco()` expands a `marked` / `RMark` style data.frame (a `ch` string per
#' row, optional `freq`, covariates) into one row per individual per occasion,
#' with the occasion on `period` (capture-recapture primary periods).
#' `eco_to_ch()` collapses it back.
#'
#' @param df data.frame with a capture-history column and optional frequency.
#' @param taxon Taxon code.
#' @param ch_col,freq_col Names of the capture-history and frequency columns.
#' @param long A table in the eco format with `period` as the occasion index.
#' @param collapse_freq Aggregate identical histories into a `freq` column.
#' @return `ch_to_eco()`: a data.table in the eco format. `eco_to_ch()`: a
#'   data.frame with `ch`, the unit covariates, and `freq` when collapsed.
#' @examples
#' d <- data.frame(ch = c("1011", "0101", "1011"), sex = c("f", "m", "f"))
#' long <- ch_to_eco(d, taxon = "CINCIN")
#' eco_to_ch(long)
#' @export
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
#' @param by_period For `eco_to_ch()`: `FALSE` (the default) gives one history
#'   per individual across all periods and occasions (CJS, MARK); `TRUE` gives one
#'   history per individual x period across that period's occasions, with a
#'   `period` column, for closed models fitted session by session (`secr`, M0/Mt/Mh).
#' @param fill For `eco_to_ch()`: what to write in a history cell that has no row
#'   because the individual was not at risk (standard E4.4). A named character
#'   vector `c(before = "0", gap = ".", after = ".")` (the default): `before` the
#'   individual's first row (an animal marked at birth or hatching, whose rows begin
#'   at its marking period) a `"0"`, which CJS ignores because it conditions on
#'   first capture and which MARK and `marked` expect, since histories have one
#'   length; within the history (`gap`) and `after` its last row (removed, mark lost)
#'   a `"."`, MARK's code for an occasion at which the animal could not be
#'   encountered, because a `"0"` there would be read as a missed detection of a
#'   live, marked animal and bias survival low. `fill = NULL` stops on any absent
#'   cell, as before.
#' @param drop_zero_sessions With `by_period = TRUE`, drop the individual x period
#'   histories with no capture (standard E4.4, ruling #30): the table keeps them,
#'   because the individual was at risk and the session happened, but a closed
#'   model conditioned on capture cannot use them. A message says how many.
#' @rdname ch_to_eco
#' @export
eco_to_ch <- function(long, collapse_freq = TRUE, by_period = FALSE, drop_zero_sessions = TRUE,
                      fill = c(before = "0", gap = ".", after = ".")) {
  long <- as.data.table(long)
  if (by_period && "period" %in% names(long)) {
    per <- sort(unique(long$period))
    out <- lapply(per, function(p) {
      sub <- long[period == p]
      sub[, period := NULL]
      if (drop_zero_sessions) {
        hit <- sub[, .(any_y = any(y > 0)), by = unit]
        sub <- sub[unit %in% hit[any_y == TRUE, unit]]
      }
      if (!nrow(sub)) return(NULL)
      h <- eco_to_ch(sub, collapse_freq = collapse_freq, fill = fill)
      cbind(period = p, h)
    })
    if (drop_zero_sessions) {
      n_all <- nrow(unique(long[, .(unit, period)]))
      n_hit <- nrow(unique(long[y > 0, .(unit, period)]))
      if (n_all > n_hit) message(sprintf("eco_to_ch(): dropped %d of %d individual x period histories with no capture (drop_zero_sessions = TRUE)",
                                         n_all - n_hit, n_all))
    }
    return(do.call(rbind, out))
  }
  if (!"occasion" %in% names(long)) long[, occasion := 1L]
  a <- eco_to_array(long)
  CH <- a$y
  if (any(is.na(CH))) {
    if (is.null(fill)) stop("capture history has cells with no row (not at risk, E4.4); pass `fill` to write them")
    dflt <- c(before = "0", gap = ".", after = ".")
    if (is.null(names(fill))) dflt[] <- rep_len(as.character(fill), 3)
    else dflt[intersect(names(fill), names(dflt))] <- as.character(fill[intersect(names(fill), names(dflt))])
    fill <- dflt
    ch <- apply(CH, 1, function(r) {
      have <- which(!is.na(r))
      out <- as.character(r)
      if (!length(have)) return(paste(rep(fill[["before"]], length(r)), collapse = ""))
      first <- min(have); last <- max(have)
      idx <- which(is.na(r))
      out[idx] <- ifelse(idx < first, fill[["before"]], ifelse(idx > last, fill[["after"]], fill[["gap"]]))
      paste(out, collapse = "")
    })
  } else ch <- apply(CH, 1, paste, collapse = "")
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
#' Put a table in the standard's column and row order
#'
#' Fixed columns first (`unit`, `taxon`, `y`, `y_raw`, `trap`, `period`,
#' `occasion`, `date`, `observer`, `treat`, `cluster_id`), then `unit_*`,
#' `period_*`, `obs_*`, `taxon_*`; rows sorted by taxon, trap, period,
#' occasion, unit.
#'
#' @param long A table in the eco format.
#' @return A data.table.
#' @export
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

# R twin of eco_validate/checks.py, kept so write_table() can refuse a table before it
# is written. The gate is `eco-validate` (eco_validate/); add a rule there first, here
# second, and keep the clause ids in the messages aligned.
#' Check a table against the standard
#'
#' The R twin of `eco-validate`, the repository's Python gate: required
#' columns (E1), numeric `y` (E2), unique key (E3), no `NA` in `y` and the
#' explicit-zero rule for multi-taxon tables (E4), covariates constant at their
#' level (E5), ISO 8601 dates and integer indices (E8). The Python validator is
#' the authority and checks more (side tables, `__dataset.json`); this is the
#' quick check for a table you built or edited yourself.
#'
#' @param long A table in the eco format.
#' @param survey_taxa Optional `__survey_taxa` side table: which taxa were
#'   surveyed for at which surveys (E4.2, E6).
#' @param unit_kind Optional `"site"` or `"individual"`; with `"individual"` an
#'   individual with no detection is a problem (E4.4).
#' @return A list: `ok`, `problems` (character, each starting with its clause
#'   id), `n_rows`, `n_units`, `n_taxa`.
#' @examples
#' eco_check(schank_2015_tapir_occ)$ok
#' bad <- schank_2015_tapir_occ; bad$y[1] <- NA
#' eco_check(bad)$problems
#' @export
eco_check <- function(long, survey_taxa = NULL, unit_kind = NULL) {
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
  # binomial_count (E2, ruling #34): obs_trials on every row, y <= obs_trials, no occasion
  if ("obs_trials" %in% names(long)) {
    k <- long$obs_trials
    if (anyNA(k) || !is.numeric(k) || any(k < 1) || any(k != round(k)))
      problems <- c(problems, "E2: obs_trials must be an integer >= 1 on every row (binomial_count, #34)")
    else if (any(long$y > k)) problems <- c(problems, "E2: y > obs_trials (binomial_count, #34)")
    if ("occasion" %in% names(long)) problems <- c(problems, "E2: binomial_count tables have no occasion column (#34)")
  }
  # explicit-zero (E4.2): every surveyed (unit,trap,period,occasion) carries the SET of
  # taxa surveyed for there: all taxa, or those __survey_taxa lists for it
  occ <- intersect(c("unit", "trap", "period", "occasion"), names(long))
  if (!is.null(survey_taxa)) {
    st <- unique(as.data.table(survey_taxa))
    m <- setdiff(names(st), "taxon")
    if (!"taxon" %in% names(st) || !length(m) || !all(m %in% occ)) {
      problems <- c(problems, "E6: __survey_taxa needs taxon plus one or more of the core survey columns")
    } else {
      chr <- function(d) { d <- copy(d); for (cc in names(d)) set(d, j = cc, value = as.character(d[[cc]])); d }
      surveys <- chr(unique(long[, occ, with = FALSE]))
      exp <- merge(surveys, chr(st), by = m, allow.cartesian = TRUE, all.x = TRUE)
      if (anyNA(exp$taxon)) problems <- c(problems, "E4: some surveys match no __survey_taxa row")
      exp <- unique(exp[!is.na(taxon), c(occ, "taxon"), with = FALSE])
      obs <- chr(unique(long[, c(occ, "taxon"), with = FALSE]))
      if (nrow(fsetdiff(exp, obs)))
        problems <- c(problems, "E4: some surveys lack rows for taxa __survey_taxa lists (explicit-zero rule)")
      if (nrow(fsetdiff(obs, exp)))
        problems <- c(problems, "E4: some surveys carry taxa __survey_taxa does not list for them")
    }
  } else if (uniqueN(long$taxon) > 1) {
    per_survey <- long[, .(n = uniqueN(taxon)), by = occ]
    if (any(per_survey$n != uniqueN(long$taxon)))
      problems <- c(problems, "E4: some surveys lack rows for some taxa (explicit-zero rule)")
  }
  # E4.4: an individual never detected in the table is not a unit
  if (identical(unit_kind, "individual")) {
    never <- long[, .(best = max(y)), by = unit][best <= 0]
    if (nrow(never)) problems <- c(problems, sprintf("E4: %d individual(s) never detected (every y = 0)", nrow(never)))
  }
  list(ok = length(problems) == 0, problems = problems,
       n_rows = nrow(long), n_units = uniqueN(long$unit), n_taxa = uniqueN(long$taxon))
}


#' @param family For `eco_to_unmarked()`: `"occu"`, `"pcount"`, `"colext"` or
#'   `"mpois"`; `NULL` infers it from the table (several periods: colext;
#'   `y` beyond 0/1: pcount; `y_raw` category labels on `occasion`: mpois;
#'   otherwise occu).
#' @param ... For `eco_to_unmarked()`: passed on to `eco_to_umf()` or
#'   `eco_to_mpois()` (`site_ids`, `type`, `obsToY`).
#' @rdname umf_to_eco
#' @export
eco_to_unmarked <- function(long, family = NULL, ...) {
  if (is.list(long) && !is.data.frame(long))
    return(lapply(long, eco_to_unmarked, family = family, ...))
  long <- as.data.table(long)
  nt <- uniqueN(long$taxon)
  if (nt > 1)
    stop("this table has ", nt, " taxa; unmarked frames hold one. Split it, e.g. ",
         "eco_to_unmarked(long[long$taxon == long$taxon[1], ]), or use eco_to_array() to keep the taxon dimension.",
         call. = FALSE)
  if ("obs_trials" %in% names(long) && !"occasion" %in% names(long)) {
    message("eco_to_unmarked: binomial_count table; expanding each row to an exchangeable history of obs_trials occasions")
    long <- binomial_to_history(long)
  }
  if (is.null(family)) {
    multi_period <- "period" %in% names(long) && uniqueN(long$period) > 1
    family <- if ("y_raw" %in% names(long) && "occasion" %in% names(long) &&
                  is.character(long$y_raw) && all(long[, uniqueN(y_raw), by = occasion]$V1 == 1) &&
                  uniqueN(long$y_raw) == uniqueN(long$occasion) && uniqueN(long$occasion) > 1 &&
                  any(long$y > 1)) "mpois"
              else if (multi_period) "colext"
              else if (any(long$y > 1)) "pcount"
              else "occu"
    message("eco_to_unmarked: family = \"", family, "\" (pass family= to override)")
  }
  if (family == "mpois") return(eco_to_mpois(long, ...))
  if (family == "occu" && "occasion" %in% names(long) && uniqueN(long$occasion) == 1)
    warning("eco_to_unmarked: one occasion per unit; occu() cannot separate psi from p ",
            "without repeat surveys (the frame is built, but only psi*p is identified)", call. = FALSE)
  eco_to_umf(long, type = family, ...)
}

#' Expand a `binomial_count` table to detection rows
#'
#' A `responseType = binomial_count` table (E2, ruling #34) has one row per
#' `(unit, taxon[, trap][, period])` with `y` = occasions with a detection out of
#' `obs_trials` surveyed. For a constant detection probability the count is a
#' sufficient statistic, so the row can be expanded to an exchangeable history:
#' `occasion` 1..`obs_trials`, `y = 1` for the first `y` occasions and 0 after.
#' The order of ones is arbitrary; only constant-`p` models should be fitted.
#' `obs_trials` is dropped from the result.
#' @param long A table in the eco format with `obs_trials` and no `occasion`.
#' @return A data.table in the eco format with `occasion` and 0/1 `y`.
#' @export
binomial_to_history <- function(long) {
  long <- as.data.table(long)
  stopifnot("obs_trials" %in% names(long), !"occasion" %in% names(long), all(long$y <= long$obs_trials))
  out <- long[rep(seq_len(.N), obs_trials)]
  out[, occasion := seq_len(.N), by = c(intersect(c("unit", "taxon", "trap", "period"), names(long)))]
  out[, y := as.integer(occasion <= long$y[rep(seq_len(nrow(long)), long$obs_trials)])]
  out[, obs_trials := NULL]
  order_eco(out)
}

# ---------------------------------------------------------------------------
# IRW view: the same table under the IRW v1.0 names, so IRW tooling (irw-validate,
# the irw R/Python packages' readers) can consume it. unit->id, taxon->item, y->resp,
# y_raw->resp_raw, observer->rater, unit_->cov_, taxon_->itemcov_, period_->periodcov_,
# obs_ kept (an IRW-unknown prefix, warned not blocked), date -> Unix seconds (UTC),
# trap -> folded into item as taxon:trap (IRW has no trap key).
# ---------------------------------------------------------------------------
#' The IRW view of a table
#'
#' The same table under the Item Response Warehouse's v1.0 names, so IRW
#' tooling can read it: `unit` becomes `id`, `taxon` `item`, `y` `resp`,
#' `y_raw` `resp_raw`, `observer` `rater`; `unit_` becomes `cov_`, `taxon_`
#' `itemcov_`, `period_` `periodcov_` (`obs_` is kept); `date` becomes Unix
#' seconds in UTC. IRW has no trap key, so in a spatial capture-recapture table
#' `item` is `"<taxon>:<trap>"` (traps as items) and `trap` is dropped.
#'
#' @param long A table in the eco format.
#' @return A data.table.
#' @examples
#' head(eco_to_irw(schank_2015_tapir_occ))
#' @export
eco_to_irw <- function(long) {
  long <- copy(as.data.table(long))
  # SCR: IRW has no trap key; traps become part of the item (item = "<taxon>:<trap>")
  if ("trap" %in% names(long)) {
    long[, taxon := paste0(taxon, ":", trap)]
    long[, trap := NULL]
  }
  ren <- c(unit = "id", taxon = "item", y = "resp", y_raw = "resp_raw", observer = "rater")
  for (nm in intersect(names(ren), names(long))) setnames(long, nm, ren[[nm]])
  nn <- names(long)
  nn <- sub("^unit_", "cov_", nn); nn <- sub("^taxon_", "itemcov_", nn); nn <- sub("^period_", "periodcov_", nn)
  setnames(long, nn)
  if ("date" %in% names(long)) {
    # YYYY-MM-DD, YYYY-MM-DDThh:mm[Z], YYYY-MM-DDThh:mm:ss[Z]; the most specific
    # format is tried first because as.POSIXct ignores trailing characters.
    d <- sub("Z$", "", as.character(long$date))
    d <- ifelse(nchar(d) == 10, paste0(d, "T00:00:00"), d)
    d <- ifelse(nchar(d) == 16, paste0(d, ":00"), d)
    dt <- suppressWarnings(as.POSIXct(d, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"))
    long[, date := as.integer(round(as.numeric(dt)))]
  }
  first <- intersect(c("id", "item", "resp", "resp_raw", "period", "occasion", "date", "rater", "treat", "cluster_id"), names(long))
  setcolorder(long, c(first, setdiff(names(long), first)))
  long[]
}

