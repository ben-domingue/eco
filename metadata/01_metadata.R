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
# variables (pipe-joined column list), standard_version, build_date, script.
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
options(scipen = 999)
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
out_dir <- file.path(root, "output")
`%||%` <- function(a, b) if (is.null(a)) b else a

tables <- sort(sub("\\.csv$", "", grep("__", list.files(out_dir, "\\.csv$"), value = TRUE, invert = TRUE)))
rows <- lapply(tables, function(t) {
  d <- fread(file.path(out_dir, paste0(t, ".csv")))
  ds <- fromJSON(file.path(out_dir, paste0(t, "__dataset.json")), simplifyVector = FALSE)
  surv <- intersect(c("unit", "trap", "period", "occasion"), names(d))
  n_surveys <- nrow(unique(d[, surv, with = FALSE]))
  n_taxa <- uniqueN(d$taxon)
  up <- file.path(out_dir, paste0(t, "__units.csv"))
  cols <- c(names(d), if (file.exists(up)) names(fread(up, nrows = 0)))
  data.table(
    table = t, n_rows = nrow(d), n_units = uniqueN(d$unit), n_taxa = n_taxa,
    n_periods = if ("period" %in% names(d)) uniqueN(d$period) else 1L,
    n_occasions = if ("occasion" %in% names(d)) uniqueN(d$occasion) else 1L,
    n_traps = if ("trap" %in% names(d)) uniqueN(d$trap) else 1L,
    n_surveys = n_surveys,
    density = round(nrow(d) / (n_surveys * n_taxa), 4),
    prop_zero = round(mean(d$y == 0), 4),
    naive_occupancy = round(mean(d[, any(y > 0), by = unit]$V1), 4),
    mean_detection = round(mean(d$y > 0), 4),
    max_y = max(d$y),
    response_type = ds$responseType %||% "", unit_kind = ds$unitKind %||% "",
    survey_evidence = ds$surveyEvidence %||% "", sample_floor = ds$sampleFloor %||% "",
    has_effort = !is.null(ds$effortColumn) || any(grepl("^obs_(effort|.*nights|.*days|duration|.*_min)$", names(d))),
    has_coordinates = any(grepl("^(unit_)?(decimalLatitude|decimalLongitude)$|^unit_[xy]$", cols)),
    coordinates_coarsened = isTRUE(ds$coordinatesCoarsened$value),   # {value, method} object, or null
    variables = paste(names(d), collapse = "|"),
    standard_version = ds$standardVersion %||% "", build_date = ds$buildDate %||% "", script = ds$script %||% "")
})
meta <- rbindlist(rows)
fwrite(meta, file.path(root, "metadata", "metadata.csv"))
cat(sprintf("01_metadata.R: %d tables -> metadata/metadata.csv\n", nrow(meta)))
