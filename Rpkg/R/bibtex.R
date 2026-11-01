#' Write BibTeX entries for tables
#'
#' One entry per table from [eco_biblio()]: the pipeline's own entry when it
#' has one, otherwise a `@misc` built from creator, year, title, DOI and
#' source URL. Cite the data, not just the warehouse.
#'
#' @param tables Table names, or a data.frame with a `table` column.
#' @param file Path to write to (`.bib`). `NULL` returns the entries without writing.
#' @return Invisibly, the entries as a character vector.
#' @examples
#' \donttest{
#' eco_save_bibtex("schank_2015_tapir_occ", file = tempfile(fileext = ".bib"))
#' }
#' @export
eco_save_bibtex <- function(tables, file = NULL) {
  tables <- .eco_table_names(tables)
  b <- eco_biblio()
  missing <- setdiff(tables, b$table)
  if (length(missing)) warning("no bibliography row for: ", paste(missing, collapse = ", "), call. = FALSE)
  entries <- vapply(intersect(tables, b$table), function(tb) {
    r <- b[b$table == tb, , drop = FALSE]
    if ("bibtex" %in% names(r) && !is.na(r$bibtex) && nzchar(r$bibtex)) return(r$bibtex)
    esc <- function(x) if (is.na(x) || !nzchar(x)) NULL else gsub("([&%])", "\\\\\\1", x)
    fields <- c(author = esc(r$creator), title = esc(r$title), year = esc(substr(r$pub_date %||% "", 1, 4)),
                doi = esc(r$doi_data %||% r$doi_paper), url = esc(r$source_url),
                note = esc(paste0("Table `", tb, "` of the eco warehouse, ", .eco_site, "; licence ", r$spdx)))
    fields <- fields[!vapply(fields, is.null, TRUE)]
    paste0("@misc{", tb, ",\n", paste0("  ", names(fields), " = {", unlist(fields), "}", collapse = ",\n"), "\n}")
  }, character(1))
  if (!is.null(file)) writeLines(paste(entries, collapse = "\n\n"), file)
  invisible(unname(entries))
}
