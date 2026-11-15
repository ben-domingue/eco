#' Cite the sources behind tables
#'
#' Every eco table rests on fieldwork by the people who deposited it. Cite the
#' original deposits and papers for the tables you used, and eco as well; a
#' paper that cites only eco gives the credit for the data to the warehouse.
#'
#' `eco_cite()` returns one entry per source deposit and one per paper, not one
#' per table: tables built from the same deposit (one DOI, several survey
#' designs) share an entry, as do deposits described by the same paper. An
#' entry's BibTeX key is the name of the deposit's first table (alphabetically,
#' over the whole corpus, so it does not depend on which tables you pass), and
#' `<that>_paper` for its paper. The last entry is eco itself, at the version
#' read (see [eco_version()]); `eco = FALSE` leaves it out.
#'
#' `eco_save_bibtex()` is `eco_cite(tables, "bibtex", file)`.
#'
#' @param tables Table names, or a data.frame with a `table` column (as from
#'   [eco_filter()] or [eco_list_tables()]).
#' @param format `"text"` (a reference list, from the `citation` and
#'   `reference` columns of [eco_biblio()]) or `"bibtex"` (the entries the
#'   pipeline fetched from DataCite and Crossref, or a `@misc` built from the
#'   deposit's metadata where none could be fetched).
#' @param file Path to write to (`.bib` or `.txt`). `NULL` returns the entries
#'   without writing.
#' @param eco Include an entry for eco itself.
#' @return A character vector of entries, deposits and papers sorted by their
#'   text citation, eco last; invisibly when `file` is given.
#' @examples
#' \donttest{
#' eco_cite(c("kery_2008_willowtit_occ", "schank_2015_tapir_occ"))
#' eco_cite(eco_filter(taxon_group = "Amphibians"), "bibtex", file = tempfile(fileext = ".bib"))
#' }
#' @seealso [eco_list_deposits()] for the deposits themselves.
#' @export
eco_cite <- function(tables, format = c("text", "bibtex"), file = NULL, eco = TRUE) {
  format <- match.arg(format)
  tables <- .eco_table_names(tables)
  b <- eco_biblio()
  missing <- setdiff(tables, b$table)
  if (length(missing)) warning("no bibliography row for: ", paste(missing, collapse = ", "), call. = FALSE)
  entries <- .eco_cite_entries(b, intersect(tables, b$table), format)
  if (eco) entries <- c(entries, .eco_self_citation(format))
  entries <- unname(entries)
  if (is.null(file)) return(entries)
  writeLines(paste(entries, collapse = "\n\n"), file)
  invisible(entries)
}

#' @rdname eco_cite
#' @export
eco_save_bibtex <- function(tables, file = NULL) {
  invisible(eco_cite(tables, "bibtex", file))
}

.eco_clean_doi <- function(x) {
  x <- as.character(x); x[is.na(x)] <- ""
  tolower(trimws(sub("^(https?://(dx\\.)?doi\\.org/|doi:)", "", x, ignore.case = TRUE)))
}

# The entries for `tables`, deduplicated: deposits by the deposit id, papers by
# DOI (or, with no DOI, by the citation / reference text). `b` is the whole biblio, so a
# deposit's key is the same whichever of its tables are asked for.
.eco_cite_entries <- function(b, tables, format) {
  col <- function(n) if (n %in% names(b)) { v <- as.character(b[[n]]); v[is.na(v)] <- ""; trimws(v) } else rep("", nrow(b))
  b$deposit <- .eco_deposit_id(b)
  cit <- col("citation"); ref <- col("reference"); bib <- col("bibtex")
  dpaper <- .eco_clean_doi(col("doi_paper")); ddata <- .eco_clean_doi(col("doi_data"))
  # a paper is a separate entry when it has its own DOI, or (no DOI) a reference
  # that is not just the deposit's citation restated (R package data cite the paper)
  norm <- function(x) sub("[[:space:].,;]+$", "", tolower(gsub("https?://\\S+", "", x)))
  restated <- nzchar(ref) & startsWith(norm(cit), norm(ref))
  has_paper <- (nzchar(dpaper) & dpaper != ddata) | (!nzchar(dpaper) & nzchar(ref) & !restated)
  paper_id <- ifelse(nzchar(dpaper), paste0("doi:", dpaper), paste0("ref:", ref))
  paper_id[!has_paper] <- NA
  key_of <- function(group, id) min(b$table[!is.na(group) & group == id])
  pieces <- function(x) if (nzchar(x)) strsplit(x, "\n\n(?=@)", perl = TRUE)[[1]] else character()
  rekey <- function(entry, key) sub("^\\s*(@[A-Za-z]+)\\{[^,]*,", paste0("\\1{", key, ","), entry)
  # deposits with a DOI group by it; without one (an R package's example data,
  # one source URL for many datasets) each distinct citation is its own source
  dep <- ifelse(nzchar(ddata), b$deposit, paste0("cit:", cit))
  sel <- b$table %in% tables
  out <- list(); sort_by <- character()

  for (id in unique(dep[sel])) {
    i <- which(sel & dep == id)[1]
    key <- key_of(dep, id)
    text <- if (nzchar(cit[i])) cit[i] else b$table[i]
    entry <- if (format == "text") text else {
      p <- pieces(bib[i]); p <- p[!grepl("^\\s*@[A-Za-z]+\\{[^,]*_paper,", p)]
      if (length(p)) rekey(p[1], key) else .eco_misc_bibtex(b[i, , drop = FALSE], key)
    }
    out[[length(out) + 1]] <- entry; sort_by <- c(sort_by, text)
  }
  for (id in unique(paper_id[sel & has_paper])) {
    i <- which(sel & has_paper & paper_id %in% id)[1]
    key <- paste0(key_of(paper_id, id), "_paper")
    text <- if (nzchar(ref[i])) ref[i] else paste0("https://doi.org/", dpaper[i])
    if (format == "text") entry <- text else {
      p <- pieces(bib[i]); p <- p[grepl("^\\s*@[A-Za-z]+\\{[^,]*_paper,", p)]
      if (!length(p)) next          # no cached entry for the paper: the deposit's entry carries the data
      entry <- rekey(p[1], key)
    }
    out[[length(out) + 1]] <- entry; sort_by <- c(sort_by, text)
  }
  unlist(out[order(tolower(sort_by))])
}

.eco_misc_bibtex <- function(r, key) {
  g <- function(n) if (n %in% names(r) && !is.na(r[[n]]) && nzchar(r[[n]])) as.character(r[[n]]) else NULL
  esc <- function(x) if (is.null(x)) NULL else gsub("([&%#])", "\\\\\\1", x)
  doi <- g("doi_data") %||% g("doi_paper")
  fields <- c(author = esc(g("creator")), title = esc(g("title")), year = esc(substr(g("pub_date") %||% "", 1, 4)),
              doi = esc(if (is.null(doi)) NULL else .eco_clean_doi(doi)), url = g("source_url"),
              note = esc(paste0("Distributed as eco table ", r$table, if (!is.null(g("spdx"))) paste0("; licence ", g("spdx")))))
  fields <- fields[nzchar(fields)]
  paste0("@misc{", key, ",\n", paste0("  ", names(fields), " = {", fields, "}", collapse = ",\n"), "\n}")
}

# eco itself, at the version being read. Offline (no manifest), the version is
# left out rather than failing the citation.
.eco_self_citation <- function(format) {
  v <- tryCatch(suppressMessages(eco_version()), error = function(e) NULL)
  ver <- if (!is.null(v) && !is.na(v$eco_version)) as.character(v$eco_version) else NA_character_
  year <- if (!is.null(v) && !is.na(v$released)) substr(v$released, 1, 4) else format(Sys.Date(), "%Y")
  title <- "eco: a warehouse of ecological detection data"
  if (format == "text")
    return(paste0("Domingue, B. W. (", year, "). ", title, if (!is.na(ver)) paste0(" (version ", ver, ")"),
                  ". ", .eco_site))
  paste0("@misc{eco", if (!is.na(ver)) paste0("_v", ver), ",\n",
         "  author = {Domingue, Benjamin W.},\n",
         "  title = {", title, "},\n",
         "  year = {", year, "},\n",
         if (!is.na(ver)) paste0("  version = {", ver, "},\n"),
         "  url = {", .eco_site, "},\n",
         "  note = {Cite the original deposits and papers as well; see eco\\_cite() in the R package}\n}")
}

# Once per session, the first time a table is fetched. options(eco.cite_reminder = FALSE) silences it.
.eco_cite_reminder <- function() {
  if (isFALSE(getOption("eco.cite_reminder")) || isTRUE(.eco_env$cite_reminded)) return(invisible())
  .eco_env$cite_reminded <- TRUE
  message("eco tables rest on other people's fieldwork: please cite the original deposits ",
          "(eco_cite(tables)). Silence with options(eco.cite_reminder = FALSE).")
}
