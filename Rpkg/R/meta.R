# The three tables of eco_meta (metadata, biblio, tags), built by the repository's
# metadata/ pipeline from the tables themselves. They describe every table the
# pipeline has built, which can run ahead of what Redivis has released; the
# readers below keep only rows for tables in the eco version being read, so
# eco_filter() never offers a table eco_fetch() cannot get.

.eco_meta_table <- function(name) {
  key <- paste0("meta:", name)
  if (!is.null(.eco_env[[key]])) return(.eco_env[[key]])
  tag <- .eco_resolved_tag(.eco_meta)
  d <- .eco_read_csv(.eco_table_file(.eco_meta, name, tag))
  released <- .eco_core_names()
  extra <- setdiff(d$table, released)
  d <- d[d$table %in% released, , drop = FALSE]
  d <- d[order(d$table), , drop = FALSE]; rownames(d) <- NULL
  attr(d, "unreleased") <- extra
  .eco_env[[key]] <- d
  d
}

.eco_is_side <- function(name) grepl(paste0("(", paste(names(.eco_side_keys), collapse = "|"), ")$"), name)
.eco_core_names <- function() {
  l <- .eco_table_listing(.eco_core, .eco_tag_for(.eco_core))
  l$name[!.eco_is_side(l$name)]
}

#' The tables in the corpus
#'
#' One row per core table in the eco version being read (see [eco_version()]),
#' with its size on Redivis and which side tables it has.
#'
#' @return A data.frame: `table`, `n_rows`, `bytes`, `needs_login` (over the
#'   100 MB Redivis serves without a login; see [eco_fetch()]), `taxa`,
#'   `periods`, `units`, `traps` (logical: the side table exists).
#' @examples
#' \donttest{
#' eco_list_tables()
#' }
#' @export
eco_list_tables <- function() {
  l <- .eco_table_listing(.eco_core, .eco_tag_for(.eco_core))
  core <- l[!.eco_is_side(l$name), , drop = FALSE]
  out <- data.frame(table = core$name, n_rows = core$rows, bytes = core$bytes,
                    needs_login = !is.na(core$bytes) & core$bytes > .eco_anon_cap, stringsAsFactors = FALSE)
  for (s in names(.eco_side_keys)) out[[sub("^__", "", s)]] <- paste0(core$name, s) %in% l$name
  rownames(out) <- NULL
  out
}

#' Computed metadata, bibliography and tags
#'
#' `eco_metadata()` is what the pipeline computes from each table: counts
#' (`n_rows`, `n_units`, `n_taxa`, `n_periods`, `n_occasions`, `n_surveys`),
#' density, the proportion of zeros, naive occupancy, `response_type`,
#' `unit_kind`, `survey_evidence`, `sample_floor`, whether the table has effort
#' and coordinates, the columns, and the standard version it was built under.
#' `eco_biblio()` is the citation side: title, creator, DOIs, licence (as shown
#' on the source page, and the licence the table ships under). `eco_tags()` is
#' the hand-checked classification: `taxon_group`, `model_family`,
#' `sampling_protocol`, `design`, `realm`, `country`.
#'
#' Rows are limited to tables in the eco version being read; tables the pipeline
#' has built but Redivis has not yet released are in `attr(x, "unreleased")`.
#'
#' @return A data.frame with one row per table.
#' @examples
#' \donttest{
#' m <- eco_metadata()
#' m[m$sample_floor == "meets", c("table", "n_units", "n_occasions")]
#' }
#' @export
eco_metadata <- function() .eco_meta_table("metadata")

#' @rdname eco_metadata
#' @export
eco_biblio <- function() .eco_meta_table("biblio")

#' @rdname eco_metadata
#' @export
eco_tags <- function() .eco_meta_table("tags")

#' Values a tag column takes, with counts
#'
#' @param column A column of [eco_tags()], e.g. `"model_family"`. Omit it to
#'   see the column names.
#' @return A data.frame `tag`, `count`, most frequent first.
#' @examples
#' \donttest{
#' eco_tag_options("model_family")
#' }
#' @export
eco_tag_options <- function(column) {
  tags <- eco_tags()
  cols <- setdiff(names(tags), c("table", "rater", "notes", "status"))
  if (missing(column)) { message("tag columns: ", paste(cols, collapse = ", ")); return(invisible(cols)) }
  if (!column %in% names(tags)) stop("`", column, "` is not a column of eco_tags(); one of ", paste(cols, collapse = ", "), call. = FALSE)
  v <- tags[[column]]; v <- v[!is.na(v) & nzchar(v)]
  tab <- sort(table(v), decreasing = TRUE)
  data.frame(tag = names(tab), count = as.integer(tab), stringsAsFactors = FALSE)
}
