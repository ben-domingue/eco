#!/usr/bin/env Rscript
# Stage 11: status.json (the current numbers) and status_history.tsv (one row
# appended per run, so the trend is visible). Both are tracked in git. Computed
# from metadata.csv, tags.csv, biblio.csv and validate/report.csv in the same run
# that writes them, so it cannot disagree with the files it ships beside (the
# failure irw's 11_status.R exists to prevent).
#
#   Rscript metadata/11_status.R          # from the repo root
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
md <- file.path(root, "metadata")
meta <- fread(file.path(md, "metadata.csv")); tags <- fread(file.path(md, "tags.csv"), colClasses = "character")
val_f <- file.path(root, "validate", "report.csv")
val <- if (file.exists(val_f)) fread(val_f) else NULL
fam <- sub(" \\(.*", "", tags$model_family)
status <- list(
  date = format(Sys.Date()), n_tables = nrow(meta), n_rows = sum(meta$n_rows), n_units = sum(meta$n_units),
  n_taxa_rows = sum(meta$n_taxa), n_surveys = sum(meta$n_surveys),
  n_families = uniqueN(fam), families = as.list(table(fam)),
  response_types = as.list(table(meta$response_type)), taxon_groups = as.list(table(tags$taxon_group)),
  survey_evidence = as.list(table(meta$survey_evidence)),
  n_below_floor = sum(meta$sample_floor != "meets"), n_with_coordinates = sum(meta$has_coordinates),
  n_do_not_publish = sum(grepl("do_not_publish", tags$status)), n_human_tagged = sum(tags$rater != "claude-auto"),
  n_valid = if (!is.null(val)) sum(val$eco_valid) else NA, n_irw_conforms = if (!is.null(val)) sum(grepl("conforms", val$irw_v1)) else NA,
  standard_versions = as.list(table(meta$standard_version)))
write_json(status, file.path(md, "status.json"), auto_unbox = TRUE, pretty = TRUE)
hist_f <- file.path(md, "status_history.tsv")
row <- data.table(date = status$date, n_tables = status$n_tables, n_rows = status$n_rows, n_units = status$n_units,
                  n_families = status$n_families, n_below_floor = status$n_below_floor,
                  n_do_not_publish = status$n_do_not_publish, n_valid = status$n_valid, n_irw_conforms = status$n_irw_conforms)
hist <- if (file.exists(hist_f)) rbind(fread(hist_f, colClasses = list(character = "date")), row, fill = TRUE) else row
fwrite(hist, hist_f, sep = "\t")
cat(sprintf("11_status.R: %d tables, %s rows -> metadata/status.json (+1 row in status_history.tsv)\n", status$n_tables, format(status$n_rows, big.mark = ",")))
