#!/usr/bin/env Rscript
# Stage 01: metadata.csv, one row per core table, computed from output/ alone.
#
# Everything here is derivable from the shipped files (the CSV and its
# __dataset.json), so nothing is typed by hand and a rebuilt table cannot
# disagree with its row. Human-entered attributes live in tags (03); origin and
# licence in biblio (02). This is the eco analogue of irw/src/metadata/01_metadata.R
# without the Redivis round trip: the corpus is small enough to recompute whole.
#
#   Rscript metadata/01_metadata.R          # from the repo root; writes metadata/metadata.csv
#
# Columns: table, n_rows, n_units, n_taxa, n_periods, n_occasions, n_traps,
# n_surveys, density (rows / (n_surveys x n_taxa); 1 means every survey carries
# every taxon), prop_zero, naive_occupancy (share of units with any y > 0),
# mean_detection (share of rows with y > 0), max_y, response_type, unit_kind,
# survey_evidence, sample_floor, has_effort, has_coordinates, coordinates_coarsened,
# variables (pipe-joined column list), standard_version, build_date, script; from v1.1-draft also
# closure, occasion_kind, taxon_inclusion, and components (the other core tables whose __dataset.json
# names the same sourceURL, i.e. built from the same deposit; E10), pipe-joined.
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
options(scipen = 999)
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
out_dir <- file.path(root, "output")
`%||%` <- function(a, b) if (is.null(a)) b else a

source(file.path(root, "metadata", "tables.R"))
tables <- eco_tables(out_dir)   # by __dataset.json, so a gitignored core does not drop its table (#66)
# The counts of one core file, as pieces that add up across the period parts of a parted table (standard E4).
file_stats <- function(f) {
  d <- fread(f)
  surv <- intersect(c("unit", "trap", "period", "occasion"), names(d))
  list(cols = names(d), n_rows = nrow(d), units = unique(d$unit), taxa = unique(d$taxon),
       periods = if ("period" %in% names(d)) unique(d$period), occasions = if ("occasion" %in% names(d)) unique(d$occasion),
       traps = if ("trap" %in% names(d)) unique(d$trap), n_surveys = nrow(unique(d[, surv, with = FALSE])),
       n_zero = sum(d$y == 0), n_pos = sum(d$y > 0), max_y = max(d$y), unit_hit = d[, .(hit = any(y > 0)), by = unit])
}
core_stats <- function(t) {
  pd <- file.path(out_dir, paste0(t, ".parts"))
  files <- if (dir.exists(pd)) sort(list.files(pd, "^part-.*\\.csv$", full.names = TRUE)) else file.path(out_dir, paste0(t, ".csv"))
  acc <- NULL
  for (f in files) {
    x <- file_stats(f)
    acc <- if (is.null(acc)) x else list(cols = acc$cols, n_rows = acc$n_rows + x$n_rows, units = union(acc$units, x$units),
      taxa = union(acc$taxa, x$taxa), periods = union(acc$periods, x$periods), occasions = union(acc$occasions, x$occasions),
      traps = union(acc$traps, x$traps), n_surveys = acc$n_surveys + x$n_surveys, n_zero = acc$n_zero + x$n_zero,
      n_pos = acc$n_pos + x$n_pos, max_y = max(acc$max_y, x$max_y),
      unit_hit = rbind(acc$unit_hit, x$unit_hit)[, .(hit = any(hit)), by = unit])
    rm(x); gc(FALSE)
  }
  acc
}
# A table whose core is not on this machine (gitignored, not rebuilt here) keeps its
# existing metadata.csv row: its counts can only be computed where the core is (#66).
meta_f <- file.path(root, "metadata", "metadata.csv")
old <- if (file.exists(meta_f)) fread(meta_f, colClasses = "character") else NULL
absent <- tables[!vapply(tables, function(t) has_core(out_dir, t), TRUE)]
no_row <- setdiff(absent, old$table)
if (length(no_row)) stop("no core in output/ and no existing metadata.csv row, so nothing to compute or keep: ",
                         paste(no_row, collapse = ", "), "\n  build it first (Rscript data/<table>.R)", call. = FALSE)
if (length(absent)) message("01_metadata.R: core not present here, keeping the existing row for ", length(absent),
                            " table(s): ", paste(absent, collapse = ", "))
rows <- lapply(tables, function(t) {
  ds <- fromJSON(file.path(out_dir, paste0(t, "__dataset.json")), simplifyVector = FALSE)
  if (t %in% absent) {
    r <- old[table == t]
    if (!identical(r$build_date, as.character(ds$buildDate %||% "")))
      warning(t, ": the kept row is from build ", r$build_date, " but __dataset.json says ", ds$buildDate,
              "; rebuild the core here to refresh its counts", call. = FALSE)
    r[, components := NULL][, source_url := ds$sourceURL %||% ""]
    return(r)
  }
  x <- core_stats(t)
  n_surveys <- x$n_surveys
  n_taxa <- length(x$taxa)
  up <- file.path(out_dir, paste0(t, "__units.csv"))
  d <- setnames(data.table(matrix(nrow = 0, ncol = length(x$cols))), x$cols)   # column names only, for the tests below
  cols <- c(names(d), if (file.exists(up)) names(fread(up, nrows = 0)))
  data.table(
    table = t, n_rows = x$n_rows, n_units = length(x$units), n_taxa = n_taxa,
    n_periods = if (length(x$periods)) length(x$periods) else 1L,
    n_occasions = if (length(x$occasions)) length(x$occasions) else 1L,
    n_traps = if (length(x$traps)) length(x$traps) else 1L,
    n_surveys = n_surveys,
    density = round(x$n_rows / (n_surveys * n_taxa), 4),
    prop_zero = round(x$n_zero / x$n_rows, 4),
    naive_occupancy = round(mean(x$unit_hit$hit), 4),
    mean_detection = round(x$n_pos / x$n_rows, 4),
    max_y = x$max_y,
    response_type = ds$responseType %||% "", unit_kind = ds$unitKind %||% "",
    survey_evidence = ds$surveyEvidence %||% "", sample_floor = ds$sampleFloor %||% "",
    has_effort = !is.null(ds$effortColumn) || any(grepl("^obs_(effort|.*nights|.*days|duration|.*_min)$", names(d))),
    has_coordinates = any(grepl("^(unit_)?(decimalLatitude|decimalLongitude)$|^unit_[xy]$", cols)),
    coordinates_coarsened = isTRUE(ds$coordinatesCoarsened$value),   # {value, method} object, or null
    variables = paste(names(d), collapse = "|"),
    closure = ds$closure %||% "", occasion_kind = paste(unlist(ds$occasionKind), collapse = " x "),
    taxon_inclusion = ds$taxonInclusion %||% "", source_url = ds$sourceURL %||% "",
    standard_version = ds$standardVersion %||% "", build_date = ds$buildDate %||% "", script = ds$script %||% "")
})
meta <- rbindlist(rows, use.names = TRUE, fill = TRUE)
# components (E10): siblings from the same deposit, by sourceURL
meta[, components := vapply(seq_len(.N), function(i)
  paste(setdiff(table[source_url == source_url[i] & source_url[i] != ""], table[i]), collapse = "|"), "")]
meta[, source_url := NULL]
fwrite(meta, file.path(root, "metadata", "metadata.csv"))
cat(sprintf("01_metadata.R: %d tables -> metadata/metadata.csv\n", nrow(meta)))
