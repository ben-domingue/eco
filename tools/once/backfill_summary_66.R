#!/usr/bin/env Rscript
# One-time backfill (#66): add the exact counts write_table() now records in
# __dataset.json `summary` (n_traps, n_zero, n_positive, n_units_detected, max_y)
# to every table built before it did, so metadata/01_metadata.R can read
# __dataset.json alone and never the core. Kept as the record of how the values
# got there; a rebuild of any table writes them itself.
#
#   Rscript tools/once/backfill_summary_66.R [extra_output_dir ...]
#
# The core is read from output/, or from the first extra directory that has it
# (e.g. ~/eco-pr57/output for the gitignored cores). Before writing, the copy is
# checked against the summary already in __dataset.json (n_rows, n_units, n_taxa,
# n_surveys, prop_zero), so a core from a different build is refused. The new
# keys are inserted as text after "prop_zero", leaving the rest of the file
# byte-for-byte as it was.
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
out_dir <- "output"; extra <- commandArgs(TRUE)
find_core <- function(t) {
  for (d in c(out_dir, extra)) {
    pd <- file.path(d, paste0(t, ".parts")); f <- file.path(d, paste0(t, ".csv"))
    if (dir.exists(pd)) return(sort(list.files(pd, "^part-.*\\.csv$", full.names = TRUE)))
    if (file.exists(f)) return(f)
  }
  character()
}
tabs <- sort(sub("__dataset\\.json$", "", list.files(out_dir, "__dataset\\.json$")))
done <- 0L; skipped <- character()
for (t in tabs) {
  jf <- file.path(out_dir, paste0(t, "__dataset.json"))
  ds <- fromJSON(jf, simplifyVector = FALSE); s <- ds$summary
  if (!is.null(s$n_zero)) { skipped <- c(skipped, paste(t, "(already has them)")); next }
  files <- find_core(t)
  if (!length(files)) stop(t, ": no core in output/ or ", paste(extra, collapse = ", "))
  n_rows <- 0; n_zero <- 0; n_pos <- 0; max_y <- -Inf; units <- character(); hit <- character(); taxa <- character()
  traps <- character(); n_surveys <- 0
  for (f in files) {
    d <- fread(f)
    n_rows <- n_rows + nrow(d); n_zero <- n_zero + sum(d$y == 0); n_pos <- n_pos + sum(d$y > 0)
    max_y <- max(max_y, d$y); units <- union(units, unique(as.character(d$unit)))
    hit <- union(hit, unique(as.character(d$unit[d$y > 0]))); taxa <- union(taxa, unique(d$taxon))
    if ("trap" %in% names(d)) traps <- union(traps, unique(as.character(d$trap)))
    n_surveys <- n_surveys + nrow(unique(d[, intersect(c("unit", "trap", "period", "occasion"), names(d)), with = FALSE]))
    rm(d); gc(FALSE)
  }
  chk <- c(n_rows = n_rows == s$n_rows, n_units = length(units) == s$n_units, n_taxa = length(taxa) == s$n_taxa,
           n_surveys = n_surveys == s$n_surveys, prop_zero = abs(round(n_zero / n_rows, 3) - s$prop_zero) < 1e-9)
  if (!all(chk)) stop(t, ": the core found (", files[1], ") does not match __dataset.json on ",
                      paste(names(chk)[!chk], collapse = ", "))
  add <- list(n_traps = if (length(traps)) length(traps) else 1L, n_zero = n_zero, n_positive = n_pos,
              n_units_detected = length(hit), max_y = max_y)
  fmt <- function(v) if (v == round(v)) format(v, scientific = FALSE) else as.character(v)
  lines <- readLines(jf)
  i <- grep('^    "prop_zero": ', lines)
  stopifnot(length(i) == 1, !grepl(",$", lines[i]))
  new <- sprintf('    "%s": %s', names(add), vapply(add, fmt, ""))
  new[-length(new)] <- paste0(new[-length(new)], ",")
  lines <- c(lines[1:i - 1], paste0(lines[i], ","), new, lines[(i + 1):length(lines)])
  writeLines(lines, jf)
  stopifnot(identical(fromJSON(jf, simplifyVector = FALSE)$summary[names(add)], lapply(add, function(v) fromJSON(toJSON(v, auto_unbox = TRUE)))))
  done <- done + 1L
}
cat(sprintf("backfill_summary_66.R: %d __dataset.json updated, %d skipped\n", done, length(skipped)))
