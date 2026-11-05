#!/usr/bin/env Rscript
# Stage 02: biblio.csv, one origin / licence / citation row per core table.
#
# Sources: dictionary/dictionary_auto.csv (the staged description, reference,
# DOIs, licences, how fetched) joined to __dataset.json (the formal citation,
# creator, pubDate, SPDX id). Only tables with an output/<t>__dataset.json are
# kept (metadata/tables.R; a gitignored core does not count as gone, #66): a
# dictionary row for a table that no longer exists is dropped here, not
# published (the liveness rule of irw's 02_biblio.R). A core table with no
# dictionary row is an error: stage_dict_row() is part of every data/ script.
#
# The `bibtex` column is reserved for #11 and is empty until then. IRW names for
# the same fields, for anyone unioning: DOI__for_paper_ = doi_paper,
# DOI__for_data_ = doi_data, Original_License = original_license,
# Derived_License = derived_license, Source_via = source_via, BibTex = bibtex.
#
#   Rscript metadata/02_biblio.R          # from the repo root; writes metadata/biblio.csv
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
out_dir <- file.path(root, "output")
`%||%` <- function(a, b) if (is.null(a)) b else a

source(file.path(root, "metadata", "tables.R"))
tables <- eco_tables(out_dir)   # by __dataset.json, so a gitignored core does not drop its table (#66)
dict <- fread(file.path(root, "dictionary", "dictionary_auto.csv"), colClasses = "character")
missing <- setdiff(tables, dict$table)
if (length(missing)) stop("core table(s) without a dictionary row: ", paste(missing, collapse = ", "))
dropped <- setdiff(dict$table, tables)
if (length(dropped)) message("02_biblio.R: dropping dictionary row(s) with no __dataset.json: ", paste(dropped, collapse = ", "))
dict <- dict[table %in% tables]

ds <- rbindlist(lapply(tables, function(t) {
  j <- fromJSON(file.path(out_dir, paste0(t, "__dataset.json")), simplifyVector = FALSE)
  data.table(table = t, title = j$title %||% "", creator = j$creator %||% "", pub_date = as.character(j$pubDate %||% ""),
             citation = j$citation %||% "", spdx = j$intellectualRights$spdx %||% "",
             license_url = j$intellectualRights$url %||% "", paper_doi_meta = j$paperDOI %||% "")
}))
b <- merge(dict, ds, by = "table")
b[doi_paper == "" & paper_doi_meta != "", doi_paper := paper_doi_meta]
b[, bibtex := ""]
cols <- c("table", "title", "description", "creator", "pub_date", "reference", "citation", "doi_paper", "doi_data",
          "source_url", "source_via", "original_license", "derived_license", "spdx", "license_url", "bibtex",
          "contributor", "date", "notes")
setorder(b, table)
fwrite(b[, cols, with = FALSE], file.path(root, "metadata", "biblio.csv"), quote = TRUE)
cat(sprintf("02_biblio.R: %d tables -> metadata/biblio.csv\n", nrow(b)))
