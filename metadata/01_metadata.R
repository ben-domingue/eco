#!/usr/bin/env Rscript
# Stage 01: metadata.csv, one row per table, from tracked files alone.
#
# Everything here comes from each table's __dataset.json (the `summary` and
# `columns` and `sideTables` that write_table() records from the data at build
# time), the only part of a table tracked in git. No table CSV is read: tables
# live on Redivis, and the metadata must not depend on which of them happen to
# be on this machine (#66, #88). Nothing is typed by hand,
# and a rebuilt table rewrites its own summary, so it cannot disagree with its row. Human-entered attributes live in tags (03); origin and
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
rows <- lapply(tables, function(t) {
  ds <- fromJSON(file.path(out_dir, paste0(t, "__dataset.json")), simplifyVector = FALSE)
  s <- ds$summary
  need <- c("n_rows", "n_units", "n_taxa", "n_periods", "n_occasions", "n_traps", "n_surveys",
            "n_zero", "n_positive", "n_units_detected", "max_y")
  miss <- setdiff(need, names(s))
  if (length(miss)) stop(t, ": __dataset.json summary lacks ", paste(miss, collapse = ", "),
                         "; rebuild the table (Rscript data/<table>.R) so write_table() records them", call. = FALSE)
  vars <- unlist(ds$columns)
  if (is.null(ds$sideTables)) stop(t, ": __dataset.json has no sideTables; rebuild the table (Rscript data/<table>.R)", call. = FALSE)
  cols <- c(vars, unlist(ds$sideTables$units$columns))   # the __units header, as write_table() recorded it (#88)
  data.table(
    table = t, n_rows = s$n_rows, n_units = s$n_units, n_taxa = s$n_taxa,
    n_periods = s$n_periods, n_occasions = s$n_occasions, n_traps = s$n_traps,
    n_surveys = s$n_surveys,
    density = round(s$n_rows / (s$n_surveys * s$n_taxa), 4),
    prop_zero = round(s$n_zero / s$n_rows, 4),
    naive_occupancy = round(s$n_units_detected / s$n_units, 4),
    mean_detection = round(s$n_positive / s$n_rows, 4),
    max_y = s$max_y,
    response_type = ds$responseType %||% "", unit_kind = ds$unitKind %||% "",
    survey_evidence = ds$surveyEvidence %||% "", sample_floor = ds$sampleFloor %||% "",
    has_effort = !is.null(ds$effortColumn) || any(grepl("^obs_(effort|.*nights|.*days|duration|.*_min)$", vars)),
    has_coordinates = any(grepl("^(unit_)?(decimalLatitude|decimalLongitude)$|^unit_[xy]$", cols)),
    coordinates_coarsened = isTRUE(ds$coordinatesCoarsened$value),   # {value, method} object, or null
    variables = paste(vars, collapse = "|"),
    closure = ds$closure %||% "", occasion_kind = paste(unlist(ds$occasionKind), collapse = " x "),
    taxon_inclusion = ds$taxonInclusion %||% "", source_url = ds$sourceURL %||% "",
    standard_version = ds$standardVersion %||% "", build_date = ds$buildDate %||% "", script = ds$script %||% "")
})
meta <- rbindlist(rows)
# components (E10): siblings from the same deposit, by sourceURL
meta[, components := vapply(seq_len(.N), function(i)
  paste(setdiff(table[source_url == source_url[i] & source_url[i] != ""], table[i]), collapse = "|"), "")]
meta[, source_url := NULL]
fwrite(meta, file.path(root, "metadata", "metadata.csv"))
cat(sprintf("01_metadata.R: %d tables -> metadata/metadata.csv\n", nrow(meta)))
