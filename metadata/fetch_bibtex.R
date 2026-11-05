#!/usr/bin/env Rscript
# Fetch BibTeX for every DOI in dictionary/dictionary_auto.csv (doi_data and
# doi_paper) by DOI content negotiation (Accept: application/x-bibtex at
# https://doi.org/<doi>; DataCite for deposits, Crossref for papers) into
# metadata/bibtex/<doi>.bib, one file per DOI (#11). Tracked, so stage 02 and CI
# build the bibtex column offline and the entry a release shipped is the one in
# git. A DOI already cached is not fetched again; delete its file to refresh.
# Run by hand after a batch, before metadata/run_pipeline.sh. Not part of the
# pipeline because it needs the network.
#
#   Rscript metadata/fetch_bibtex.R           # from the repo root
suppressPackageStartupMessages(library(data.table))
root <- normalizePath(if (file.exists("standard.md")) "." else "..")
cache <- file.path(root, "metadata", "bibtex")
dir.create(cache, showWarnings = FALSE)
dict <- fread(file.path(root, "dictionary", "dictionary_auto.csv"), colClasses = "character")
clean <- function(x) { x <- tolower(trimws(sub("^(https?://(dx\\.)?doi\\.org/|doi:)", "", x, ignore.case = TRUE))); x[nzchar(x) & !is.na(x)] }
dois <- sort(unique(clean(c(dict$doi_data, dict$doi_paper))))
bib_file <- function(doi) file.path(cache, paste0(gsub("[^a-z0-9._-]", "_", doi), ".bib"))
todo <- dois[!file.exists(bib_file(dois))]
cat(sprintf("fetch_bibtex.R: %d DOIs, %d cached, %d to fetch\n", length(dois), length(dois) - length(todo), length(todo)))
ua <- "eco-bibtex (https://github.com/ben-domingue/eco)"
failed <- character()
for (d in todo) {
  tmp <- tempfile()
  ok <- tryCatch({
    suppressWarnings(utils::download.file(paste0("https://doi.org/", utils::URLencode(d, reserved = FALSE)), tmp, quiet = TRUE,
      headers = c(Accept = "application/x-bibtex; charset=utf-8", `User-Agent` = ua)))
    txt <- paste(readLines(tmp, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    grepl("^\\s*@[A-Za-z]+\\{", txt)
  }, error = function(e) FALSE)
  if (ok) writeLines(trimws(txt), bib_file(d), useBytes = TRUE) else failed <- c(failed, d)
  Sys.sleep(0.3)
}
if (length(failed)) cat("fetch_bibtex.R: no BibTeX for", length(failed), "DOI(s); stage 02 writes @misc for them:\n ", paste(failed, collapse = "\n  "), "\n")
cat("fetch_bibtex.R: done\n")
