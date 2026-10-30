# eco_standard.R — converters between native ecological data structures and the
# draft "IRW-for-ecology" long format (see ../standard_draft.md).
#
# Core columns: id, item, resp [, resp_raw, period, occasion, date, rater,
#               cov_*, periodcov_*, obs_*, itemcov_*]
# Rule: a row exists iff a survey happened. NA in a native matrix -> no row.

suppressPackageStartupMessages({ library(data.table) })

KEY_COLS <- c("id", "item", "period", "occasion")

# ---------------------------------------------------------------------------
# Generic: array -> long
# ---------------------------------------------------------------------------

# y: M x J (single species) or M x J x K (species on 3rd dim).
# site_covs: data.frame with M rows (-> cov_*)
# obs_covs: named list of M x J matrices (-> obs_*)
# period: optional integer vector of length J giving the primary period of each
#   column (for M x (T*J) layouts); occasion within period is computed.
# period_covs: named list of M x T matrices (-> periodcov_*)
# item_covs: data.frame with K rows (-> itemcov_*)
array_to_eco <- function(y, item = "SP1", site_ids = NULL, site_covs = NULL,
                         obs_covs = NULL, period = NULL, period_covs = NULL,
                         item_covs = NULL, resp_raw = NULL) {
  if (length(dim(y)) == 2) y <- array(y, dim = c(dim(y), 1),
                                      dimnames = list(rownames(y), colnames(y), item))
  M <- dim(y)[1]; J <- dim(y)[2]; K <- dim(y)[3]
  items <- if (!is.null(dimnames(y)[[3]])) dimnames(y)[[3]] else
    if (length(item) == K) item else paste0(item, seq_len(K))
  if (is.null(site_ids)) site_ids <- if (!is.null(rownames(y))) rownames(y) else seq_len(M)
  if (is.null(period)) period <- rep(1L, J)
  occasion <- ave(seq_len(J), period, FUN = seq_along)

  long <- data.table(
    id       = rep(site_ids, times = J * K),
    item     = rep(items, each = M * J),
    resp     = as.vector(y),
    period   = rep(rep(period,   each = M), times = K),
    occasion = rep(rep(occasion, each = M), times = K),
    .site    = rep(seq_len(M), times = J * K),
    .col     = rep(rep(seq_len(J), each = M), times = K)
  )
  if (!is.null(resp_raw)) long[, resp_raw := as.vector(resp_raw)]
  long <- long[!is.na(resp)]                      # the explicit-zero rule

  if (!is.null(site_covs)) {
    sc <- as.data.table(site_covs); setnames(sc, paste0("cov_", names(sc)))
    sc[, .site := seq_len(M)]
    long <- merge(long, sc, by = ".site", sort = FALSE)
  }
  if (!is.null(obs_covs)) for (nm in names(obs_covs)) {
    m <- obs_covs[[nm]]
    long[, (paste0("obs_", nm)) := m[cbind(.site, .col)]]
  }
  if (!is.null(period_covs)) for (nm in names(period_covs)) {
    m <- period_covs[[nm]]
    long[, (paste0("periodcov_", nm)) := m[cbind(.site, period)]]
  }
  if (!is.null(item_covs)) {
    ic <- as.data.table(item_covs); setnames(ic, paste0("itemcov_", names(ic)))
    ic[, item := items]
    long <- merge(long, ic, by = "item", sort = FALSE)
  }
  long[, c(".site", ".col") := NULL]
  if (all(long$period == 1L)) long[, period := NULL]
  order_eco(long)
}

# long -> array (M x J x K), padding unsurveyed cells with NA.
# Returns list(y, site_ids, items, period (per column), obs_covs, site_covs, ...)
eco_to_array <- function(long, site_ids = NULL, items = NULL, drop_species = TRUE) {
  long <- as.data.table(long)
  if (!"period" %in% names(long)) long[, period := 1L]
  if (!"occasion" %in% names(long)) long[, occasion := 1L]
  if (is.null(site_ids)) site_ids <- unique(long$id)
  if (is.null(items)) items <- unique(long$item)
  cols <- unique(long[, .(period, occasion)])[order(period, occasion)]
  cols[, .col := .I]
  long <- merge(long, cols, by = c("period", "occasion"))
  long[, .site := match(id, site_ids)]
  long[, .k := match(item, items)]
  M <- length(site_ids); J <- nrow(cols); K <- length(items)
  y <- array(NA_real_, dim = c(M, J, K), dimnames = list(site_ids, NULL, items))
  y[cbind(long$.site, long$.col, long$.k)] <- long$resp

  pull_matrix <- function(col, by_cols = c(".site", ".col")) {
    m <- matrix(NA, M, J)
    v <- long[[col]]
    m[cbind(long$.site, long$.col)] <- v
    if (is.character(v) || is.factor(v)) { mm <- matrix(NA_character_, M, J); mm[cbind(long$.site, long$.col)] <- as.character(v); m <- mm }
    m
  }
  obs_names <- grep("^obs_", names(long), value = TRUE)
  obs_covs <- setNames(lapply(obs_names, pull_matrix), sub("^obs_", "", obs_names))
  cov_names <- grep("^cov_", names(long), value = TRUE)
  site_covs <- NULL
  if (length(cov_names)) {
    u <- unique(long[, c(".site", cov_names), with = FALSE])
    stopifnot(!anyDuplicated(u$.site))          # cov_ must be constant within id
    site_covs <- as.data.frame(matrix(NA, M, length(cov_names), dimnames = list(NULL, cov_names)))
    for (cc in cov_names) site_covs[[cc]] <- u[[cc]][match(seq_len(M), u$.site)]   # NA for units with no rows
    names(site_covs) <- sub("^cov_", "", cov_names)
  }
  pc_names <- grep("^periodcov_", names(long), value = TRUE)
  period_covs <- NULL
  if (length(pc_names)) {
    Tn <- max(cols$period)
    period_covs <- setNames(lapply(pc_names, function(nm) {
      m <- matrix(NA, M, Tn); m[cbind(long$.site, long$period)] <- long[[nm]]; m
    }), sub("^periodcov_", "", pc_names))
  }
  ic_names <- grep("^itemcov_", names(long), value = TRUE)
  item_covs <- NULL
  if (length(ic_names)) {
    item_covs <- unique(long[, c(".k", ic_names), with = FALSE])[order(.k)]
    item_covs <- as.data.frame(item_covs[, ic_names, with = FALSE])
    names(item_covs) <- sub("^itemcov_", "", ic_names)
  }
  if (drop_species && K == 1) y <- y[, , 1, drop = TRUE]
  list(y = y, site_ids = site_ids, items = items, period = cols$period,
       occasion = cols$occasion, obs_covs = obs_covs, site_covs = site_covs,
       period_covs = period_covs, item_covs = item_covs)
}

# ---------------------------------------------------------------------------
# unmarked frames
# ---------------------------------------------------------------------------

# unmarkedFrameOccu / unmarkedFramePCount / unmarkedMultFrame -> long
umf_to_eco <- function(umf, item = "SP1", site_ids = NULL) {
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
  array_to_eco(y, item = item, site_ids = site_ids, site_covs = sc,
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
# Multinomial N-mixture (unmarkedFrameMPois): cells on `occasion`, label in resp_raw
# ---------------------------------------------------------------------------
mpois_to_eco <- function(umf, item = "SP1") {
  y <- unmarked::getY(umf); M <- nrow(y); C <- ncol(y)
  labs <- if (!is.null(colnames(y))) colnames(y) else as.character(seq_len(C))
  oc <- unmarked::obsCovs(umf)
  obs_list <- if (!is.null(oc)) lapply(oc, function(v) matrix(v, M, C, byrow = TRUE)) else NULL
  raw <- matrix(labs, M, C, byrow = TRUE)
  long <- array_to_eco(y, item = item, site_covs = unmarked::siteCovs(umf),
                       obs_covs = obs_list, resp_raw = raw)
  attr(long, "multinomialType") <- umf@piFun
  long
}
eco_to_mpois <- function(long, type, obsToY = NULL) {
  a <- eco_to_array(long)
  y <- a$y
  colnames(y) <- as.data.table(long)[order(occasion), unique(resp_raw)]
  obsCovs <- NULL
  if (length(a$obs_covs)) obsCovs <- as.data.frame(lapply(a$obs_covs, function(m) as.vector(t(m))))
  unmarked::unmarkedFrameMPois(y = y, siteCovs = a$site_covs, obsCovs = obsCovs,
                               type = type, obsToY = obsToY)
}

# ---------------------------------------------------------------------------
# Capture histories (marked / RMark style data.frame with ch, freq, covariates)
# ---------------------------------------------------------------------------
ch_to_eco <- function(df, item = "SP1", ch_col = "ch", freq_col = "freq") {
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
  long <- array_to_eco(CH, item = item, site_ids = seq_along(idx), site_covs = covs,
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
  first <- intersect(c("id", "item", "resp", "resp_raw", "period", "occasion", "date",
                       "rater", "treat", "cluster_id"), names(long))
  rest <- c(grep("^cov_", names(long), value = TRUE),
            grep("^periodcov_", names(long), value = TRUE),
            grep("^obs_", names(long), value = TRUE),
            grep("^itemcov_", names(long), value = TRUE))
  other <- setdiff(names(long), c(first, rest))
  setcolorder(long, c(first, rest, other))
  keycols <- intersect(c("item", "period", "occasion", "id"), names(long))
  setorderv(long, keycols)
  long[]
}

validate_eco <- function(long) {
  long <- as.data.table(long)
  problems <- character()
  req <- c("id", "item", "resp")
  if (!all(req %in% names(long))) problems <- c(problems, "C1: missing required column(s)")
  if (!is.numeric(long$resp)) problems <- c(problems, "C4: resp not numeric")
  if (anyNA(long$resp)) problems <- c(problems, "C4/explicit-zero: NA in resp (a missing row, not an NA, encodes 'not surveyed')")
  key <- intersect(KEY_COLS, names(long))
  if (anyDuplicated(long, by = key)) problems <- c(problems, sprintf("C5: duplicate (%s)", paste(key, collapse = ",")))
  allowed <- c("id", "item", "resp", "resp_raw", "period", "occasion", "date", "rater",
               "treat", "cluster_id")
  bad <- setdiff(names(long), allowed)
  bad <- bad[!grepl("^(cov_|periodcov_|obs_|itemcov_)", bad)]
  if (length(bad)) problems <- c(problems, paste("C6: undefined column(s):", paste(bad, collapse = ", ")))
  # covariate level checks
  for (cc in grep("^cov_", names(long), value = TRUE))
    if (nrow(unique(long[, c("id", cc), with = FALSE])) > uniqueN(long$id))
      problems <- c(problems, sprintf("%s varies within id (should be obs_ or periodcov_)", cc))
  for (cc in grep("^itemcov_", names(long), value = TRUE))
    if (nrow(unique(long[, c("item", cc), with = FALSE])) > uniqueN(long$item))
      problems <- c(problems, sprintf("%s varies within item", cc))
  if ("period" %in% names(long)) for (cc in grep("^periodcov_", names(long), value = TRUE))
    if (nrow(unique(long[, c("id", "period", cc), with = FALSE])) > nrow(unique(long[, .(id, period)])))
      problems <- c(problems, sprintf("%s varies within id x period", cc))
  # explicit-zero for multi-species: every surveyed (id,period,occasion) has all items
  if (uniqueN(long$item) > 1) {
    occ <- intersect(c("id", "period", "occasion"), names(long))
    per_survey <- long[, .N, by = occ]
    if (any(per_survey$N != uniqueN(long$item)))
      problems <- c(problems, "explicit-zero: some surveys lack rows for some items")
  }
  list(ok = length(problems) == 0, problems = problems,
       n_rows = nrow(long), n_id = uniqueN(long$id), n_item = uniqueN(long$item))
}

write_eco <- function(long, name, dir = "output", items = NULL, dataset = NULL) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  fwrite(long, file.path(dir, paste0(name, ".csv")))
  if (!is.null(items)) fwrite(items, file.path(dir, paste0(name, "__items.csv")))
  if (!is.null(dataset)) jsonlite::write_json(dataset, file.path(dir, paste0(name, "__dataset.json")),
                                              auto_unbox = TRUE, pretty = TRUE)
  invisible(file.path(dir, paste0(name, ".csv")))
}
read_eco <- function(path) fread(path)

# compare two numeric vectors of estimates
same_estimates <- function(a, b, tol = 1e-6) isTRUE(all.equal(unname(a), unname(b), tolerance = tol))
