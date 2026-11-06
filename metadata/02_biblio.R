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
# `bibtex` (#11): the deposit's entry, keyed `<table>`, then the paper's, keyed
# `<table>_paper`, from metadata/bibtex/ (filled by metadata/fetch_bibtex.R, which
# needs the network; this stage does not). A table whose deposit has no DOI, or
# whose DOI is not cached, gets a @misc from creator, year, title and source URL.
# `deposit` is the deposit's DOI URL (else its source URL), the key that groups a
# deposit's tables. `derived_license` is the SPDX id the table is redistributed under: eco
# redistributes each table under its source's licence, so it equals `spdx`
# (processing_guide.md); the source's wording stays in `original_license`. IRW names for
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
bib_dir <- file.path(root, "metadata", "bibtex")
clean_doi <- function(x) tolower(trimws(sub("^(https?://(dx\\.)?doi\\.org/|doi:)", "", x, ignore.case = TRUE)))
cached <- function(doi, key) {
  if (is.na(doi) || !nzchar(doi)) return(NA_character_)
  f <- file.path(bib_dir, paste0(gsub("[^a-z0-9._-]", "_", clean_doi(doi)), ".bib"))
  if (!file.exists(f)) return(NA_character_)
  txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  sub("^\\s*(@[A-Za-z]+)\\{[^,]*,", paste0("\\1{", key, ","), txt)
}
misc <- function(r) {
  esc <- function(x) gsub("([&%#])", "\\\\\\1", x)
  f <- c(author = gsub(";\\s*", " and ", r$creator), title = r$title, year = substr(r$pub_date, 1, 4), howpublished = paste0("\\url{", r$source_url, "}"),
         note = paste0("Distributed as eco table ", r$table, "; licence ", r$spdx))
  f <- f[!is.na(f) & nzchar(f)]
  paste0("@misc{", r$table, ",\n", paste0("  ", names(f), " = {", ifelse(names(f) == "howpublished", f, esc(f)), "}", collapse = ",\n"), "\n}")
}
b[, bibtex := vapply(seq_len(.N), function(i) {
  r <- b[i]
  data <- cached(r$doi_data, r$table)
  if (is.na(data)) data <- misc(r)
  paper <- cached(r$doi_paper, paste0(r$table, "_paper"))
  paste(c(data, if (!is.na(paper) && clean_doi(r$doi_paper) != clean_doi(r$doi_data)) paper), collapse = "\n\n")
}, "")]
b[, derived_license := spdx]
# `deposit`: the source deposit's id, so tables from one deposit can be grouped
# and counted ("N tables from M deposits"). The deposit's DOI as a lower-case
# https://doi.org/ URL; with no data DOI (a dataset shipped in an R package),
# the source URL.
b[, deposit := ifelse(!is.na(doi_data) & nzchar(trimws(doi_data)), paste0("https://doi.org/", clean_doi(doi_data)),
                      sub("/+$", "", trimws(source_url)))]
n_misc <- sum(startsWith(b$bibtex, "@misc{") & !vapply(b$doi_data, function(d) !is.na(d) && nzchar(d), TRUE))
message(sprintf("02_biblio.R: bibtex from metadata/bibtex/ for %d tables; %d deposit entries are @misc built here", nrow(b), n_misc))
cols <- c("table", "title", "description", "creator", "pub_date", "reference", "citation", "doi_paper", "doi_data",
          "source_url", "source_via", "deposit", "original_license", "derived_license", "spdx", "license_url", "bibtex",
          "contributor", "date", "notes")
setorder(b, table)
fwrite(b[, cols, with = FALSE], file.path(root, "metadata", "biblio.csv"), quote = TRUE)
cat(sprintf("02_biblio.R: %d tables from %d deposits -> metadata/biblio.csv\n", nrow(b), uniqueN(b$deposit)))
