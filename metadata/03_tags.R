#!/usr/bin/env Rscript
# Stage 03: tags.csv, the filterable attributes per table, human over automated.
#
# Inputs: tags/tags_auto.csv (rater claude-auto, written by stage_tag_row() from
# each data/ script) and tags/tags_human.csv (rater = a person's initials, edited
# by hand; same columns). Union keyed on `table`; a non-blank human cell wins the
# cell it occupies and nothing else (cell-level, from the start: IRW implemented
# this at row level first and a human row then erased every auto cell the human
# had left blank, #1863). `rater` on the output row says who wrote the winning
# cells: `claude-auto`, the initials, or `initials+claude-auto` when mixed.
#
# Vocabulary is enforced for the closed columns (tags/vocab.md); the run halts
# on an unknown value rather than publishing it, as irw's tag_normalize.R does.
# The counts and sample_floor no longer live in tags: 01_metadata.R computes them.
#
#   Rscript metadata/03_tags.R          # from the repo root; writes metadata/tags.csv
suppressPackageStartupMessages({ library(data.table) })
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
out_dir <- file.path(root, "output")

TAG_COLS <- c("table", "rater", "taxon_group", "response_type", "model_family", "unit_kind",
              "sampling_protocol", "design", "realm", "country", "coordinates", "notes", "status")
VOCAB <- list(
  taxon_group   = c("Mammals", "Birds", "Fish", "Amphibians", "Reptiles", "Invertebrates", "Plants", "Multiple"),
  response_type = c("detection", "count", "state", "ordinal", "multinomial_cell", "detection_event", "binomial_count"),   # standard E2
  unit_kind     = c("site", "individual"),
  realm         = c("Terrestrial", "Freshwater", "Marine"))
# Prefix-controlled: a qualifier in parentheses is allowed after the controlled value.
PREFIX_VOCAB <- list(
  coordinates = c("None in source", "As published", "Coarsened (0.1 deg)", "Coarsened (by the source", "Coarsened (trap coordinates centred", "Coarsened (10 km", "Coarsened (0.01 deg"),   # SCR centring and source-coarsened grids (E7, batch 13); 0.01 deg for private residential sites (batch 27)
  design      = c("Single-season", "Multi-season", "Multi-session", "Robust design"),
  status      = c("tagged"))

source(file.path(root, "metadata", "tables.R"))
tables <- eco_tables(out_dir)   # by __dataset.json, so a gitignored core does not drop its table (#66)
read_tags <- function(f) {
  if (!file.exists(f)) return(as.data.table(setNames(replicate(length(TAG_COLS), character(), simplify = FALSE), TAG_COLS)))
  d <- fread(f, colClasses = "character")
  extra <- setdiff(names(d), TAG_COLS); miss <- setdiff(TAG_COLS, names(d))
  if (length(extra)) stop(basename(f), ": unknown column(s) ", paste(extra, collapse = ", "), " (counts belong to metadata.csv)")
  for (m in miss) d[[m]] <- ""
  d[, TAG_COLS, with = FALSE]
}
auto  <- read_tags(file.path(root, "tags", "tags_auto.csv"))
human <- read_tags(file.path(root, "tags", "tags_human.csv"))
if (nrow(auto[rater != "claude-auto"])) stop("tags_auto.csv has a row not written by claude-auto; human rows go in tags_human.csv")
if (nrow(human[rater == "claude-auto" | rater == ""])) stop("tags_human.csv rows need a person's initials in `rater`")
if (anyDuplicated(auto$table) || anyDuplicated(human$table)) stop("duplicate table in a tags file")

missing <- setdiff(tables, union(auto$table, human$table))
if (length(missing)) stop("core table(s) without a tags row: ", paste(missing, collapse = ", "))
dropped <- setdiff(union(auto$table, human$table), tables)
if (length(dropped)) message("03_tags.R: dropping tags row(s) with no __dataset.json: ", paste(dropped, collapse = ", "))

tags <- rbindlist(lapply(tables, function(t) {
  a <- auto[table == t]; h <- human[table == t]
  if (!nrow(h)) return(a)
  if (!nrow(a)) return(h)
  out <- copy(a); won <- FALSE
  for (cc in setdiff(TAG_COLS, c("table", "rater"))) if (nzchar(h[[cc]])) { out[[cc]] <- h[[cc]]; won <- TRUE }
  out$rater <- if (won) paste0(h$rater, "+claude-auto") else "claude-auto"
  out
}))

bad <- character()
for (cc in names(VOCAB)) { v <- tags[[cc]]; b <- unique(v[nzchar(v) & !v %in% VOCAB[[cc]]])
  if (length(b)) bad <- c(bad, sprintf("%s: %s", cc, paste(b, collapse = ", "))) }
for (cc in names(PREFIX_VOCAB)) { v <- tags[[cc]]; ok <- Reduce(`|`, lapply(PREFIX_VOCAB[[cc]], function(p) startsWith(v, p)))
  if (cc == "status") ok <- ok & grepl("^tagged(; do_not_publish: .+)?$", v)
  b <- unique(v[nzchar(v) & !ok]); if (length(b)) bad <- c(bad, sprintf("%s: %s", cc, paste(b, collapse = ", "))) }
if (length(bad)) stop("tag value(s) outside tags/vocab.md:\n  ", paste(bad, collapse = "\n  "))
for (cc in c("taxon_group", "response_type", "unit_kind", "status")) if (any(!nzchar(tags[[cc]]))) stop("empty `", cc, "` for: ", paste(tags$table[!nzchar(tags[[cc]])], collapse = ", "))

setorder(tags, table)
fwrite(tags, file.path(root, "metadata", "tags.csv"), quote = TRUE)
cat(sprintf("03_tags.R: %d tables -> metadata/tags.csv (%d with human cells)\n", nrow(tags), sum(tags$rater != "claude-auto")))
