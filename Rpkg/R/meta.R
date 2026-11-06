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
  .eco_env[[paste0("meta_full:", name)]] <- d
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
  l <- .eco_core_listing()
  l$name[!.eco_is_side(l$name)]
}

# Every table in every core shard of the version being read, with the shard it
# is in (`dataset`). Shards are searched newest-first and the first match wins,
# as in IRW; the uploader keeps a name out of a second shard, so a duplicate
# means someone broke that rule by hand.
.eco_core_listing <- function() {
  if (!is.null(.eco_env$core_listing)) return(.eco_env$core_listing)
  parts <- lapply(.eco_cores_in_force(), function(d) {
    l <- .eco_table_listing(d, .eco_tag_for(d))
    l$dataset <- rep(d$name, nrow(l))
    l
  })
  l <- do.call(rbind, parts)
  l <- l[!duplicated(l$name), , drop = FALSE]
  l <- l[order(l$name), , drop = FALSE]; rownames(l) <- NULL
  .eco_env$core_listing <- l
  l
}

# The core shard (a dataset list) holding `table`, or NULL.
.eco_shard_of <- function(table) {
  l <- .eco_core_listing()
  hit <- l$dataset[l$name == table]
  if (!length(hit)) return(NULL)
  .eco_cores[[which(vapply(.eco_cores, `[[`, "", "name") == hit[1])]]
}

#' The tables in the corpus
#'
#' One row per core table in the eco version being read (see [eco_version()]),
#' with its size on Redivis and which side tables it has.
#'
#' @return A data.frame: `table`, `n_rows`, `bytes`, `needs_login` (over the
#'   100 MB Redivis serves without a login; see [eco_fetch()]), `taxa`,
#'   `periods`, `units`, `traps`, `survey_taxa` (logical: the side table
#'   exists), and `dataset`, the Redivis core shard holding it (`eco`,
#'   `eco_2`, ...).
#' @examples
#' \donttest{
#' eco_list_tables()
#' }
#' @export
eco_list_tables <- function() {
  l <- .eco_core_listing()
  core <- l[!.eco_is_side(l$name), , drop = FALSE]
  out <- data.frame(table = core$name, n_rows = core$rows, bytes = core$bytes,
                    needs_login = !is.na(core$bytes) & core$bytes > .eco_anon_cap, stringsAsFactors = FALSE)
  for (s in names(.eco_side_keys)) out[[sub("^__", "", s)]] <- paste0(core$name, s) %in% l$name
  out$dataset <- core$dataset
  rownames(out) <- NULL
  out
}

#' The source deposits
#'
#' One row per deposit: the source record (one DOI, or one archive record such
#' as an R package) that one or more eco tables were built from. A deposit
#' yields one table per survey design and response type, so it can yield
#' several; `n_tables` counts them. Built from [eco_biblio()], so it covers the
#' same tables as [eco_list_tables()] in the eco version being read (see
#' [eco_version()]).
#'
#' @return A data.frame, one row per deposit, most tables first: `deposit` (the
#'   deposit's DOI as a `https://doi.org/` URL, or its source URL when it has
#'   no data DOI), `doi` (the data DOI, `NA` without one), `source_via`,
#'   `citation`, `creator`, `n_tables`, and `tables` (the table names,
#'   separated by `", "`). Deposits whose tables are built but not yet released
#'   are in `attr(x, "unreleased")`, as deposit ids.
#' @seealso [eco_list_tables()] for the tables themselves; the glossary at
#'   <https://ben-domingue.github.io/eco/glossary.html>.
#' @examples
#' \donttest{
#' d <- eco_list_deposits()
#' nrow(d)                     # deposits
#' sum(d$n_tables)             # tables
#' head(d[d$n_tables > 1, c("deposit", "n_tables", "tables")])
#' }
#' @export
eco_list_deposits <- function() {
  b <- eco_biblio()
  b$deposit <- .eco_deposit_id(b)
  first <- function(x) { x <- x[!is.na(x) & nzchar(x)]; if (length(x)) x[1] else NA_character_ }
  ids <- unique(b$deposit)
  out <- do.call(rbind, lapply(ids, function(id) {
    r <- b[b$deposit == id, , drop = FALSE]
    col <- function(n) if (n %in% names(r)) first(as.character(r[[n]])) else NA_character_
    data.frame(deposit = id, doi = col("doi_data"), source_via = col("source_via"),
               citation = col("citation"), creator = col("creator"),
               n_tables = nrow(r), tables = paste(sort(r$table), collapse = ", "),
               stringsAsFactors = FALSE)
  }))
  if (is.null(out)) out <- data.frame(deposit = character(), doi = character(), source_via = character(),
                                      citation = character(), creator = character(), n_tables = integer(),
                                      tables = character(), stringsAsFactors = FALSE)
  out <- out[order(-out$n_tables, out$deposit), , drop = FALSE]; rownames(out) <- NULL
  attr(out, "unreleased") <- .eco_unreleased_deposits(b)
  out
}

# The deposit a biblio row's table came from: the pipeline's `deposit` column
# (metadata/02_biblio.R) when the eco_meta version has it, else the same rule
# here: the data DOI as a lower-case https://doi.org/ URL, else the source URL.
.eco_deposit_id <- function(b) {
  if ("deposit" %in% names(b)) {
    d <- as.character(b$deposit)
    if (all(!is.na(d) & nzchar(d))) return(d)
  }
  doi <- if ("doi_data" %in% names(b)) as.character(b$doi_data) else rep(NA_character_, nrow(b))
  url <- if ("source_url" %in% names(b)) as.character(b$source_url) else rep(NA_character_, nrow(b))
  clean <- tolower(trimws(sub("^(https?://(dx\\.)?doi\\.org/|doi:)", "", doi, ignore.case = TRUE)))
  ifelse(!is.na(doi) & nzchar(trimws(doi)), paste0("https://doi.org/", clean), sub("/+$", "", trimws(url)))
}

# Deposits with no released table: their tables are all in the biblio's
# "unreleased" attribute. The rows for those tables were dropped by
# .eco_meta_table(), so they are re-read from the cached full table if present.
.eco_unreleased_deposits <- function(b) {
  extra <- attr(b, "unreleased")
  full <- .eco_env[["meta_full:biblio"]]
  if (!length(extra) || is.null(full)) return(character())
  f <- full[full$table %in% extra, , drop = FALSE]
  setdiff(unique(.eco_deposit_id(f)), unique(b$deposit))
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
