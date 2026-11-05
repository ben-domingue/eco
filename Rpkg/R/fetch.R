.eco_table_names <- function(x) {
  if (is.data.frame(x)) {
    if (!"table" %in% names(x)) stop("a data.frame passed to eco_fetch() needs a `table` column (eco_filter() gives one)", call. = FALSE)
    x <- x$table
  }
  x <- as.character(x)
  if (!length(x)) stop("no tables to fetch", call. = FALSE)
  unique(x)
}

.eco_fetch_one <- function(table) {
  tag <- .eco_resolved_tag(.eco_core)
  d <- .eco_read_csv(.eco_table_file(.eco_core, table, tag))
  attr(d, "eco_table") <- table
  attr(d, "eco_redivis_version") <- tag
  d
}

#' Download tables
#'
#' Reads a core table from the eco version in force (see [eco_version()]) over
#' Redivis' public CSV endpoint. Nothing to log in to. Downloads are cached on
#' disk (see [eco_cache_dir()]).
#'
#' @section Large tables:
#' Redivis serves at most 100 MB to a request without a login, and a few eco
#' tables are bigger (`needs_login` in [eco_list_tables()]). Those are read with
#' the \pkg{redivis} client instead, which needs \pkg{redivis} and \pkg{arrow}
#' installed and a free Redivis account: run `redivis::redivis$authenticate()`
#' once, or set `REDIVIS_API_TOKEN`. The download counts against the account's
#' export quota and is cached like any other. Without a login `eco_fetch()`
#' stops and says what to do; it never opens a browser itself.
#'
#' @param x A table name, a character vector of names, or the data.frame
#'   returned by [eco_filter()] or [eco_list_tables()].
#' @return For one table, a data.frame in the eco format (`unit`, `taxon`,
#'   `y`, ...; see the package help) with attributes `eco_table` and
#'   `eco_redivis_version`. For several, a named list of them.
#' @examples
#' \donttest{
#' d <- eco_fetch("schank_2015_tapir_occ")
#' head(d)
#' both <- eco_fetch(eco_filter(taxon_group = "Mammals"))
#' }
#' @seealso [eco_taxa()] for the side tables, [eco_to_unmarked()] to reshape.
#' @export
eco_fetch <- function(x) {
  tables <- .eco_table_names(x)
  if (length(tables) == 1) return(.eco_fetch_one(tables))
  stats::setNames(lapply(tables, .eco_fetch_one), tables)
}

.eco_side <- function(table, suffix) {
  table <- .eco_table_names(table)
  if (length(table) != 1) stop("one table at a time", call. = FALSE)
  table <- sub("__(taxa|periods|units|traps)$", "", table)
  tag <- .eco_resolved_tag(.eco_core)
  listing <- .eco_table_listing(.eco_core, .eco_tag_for(.eco_core))
  name <- paste0(table, suffix)
  if (!name %in% listing$name) {
    if (!table %in% listing$name) stop("no table `", table, "` in this eco version", call. = FALSE)
    return(NULL)
  }
  .eco_read_csv(.eco_table_file(.eco_core, name, tag))
}

#' Side tables
#'
#' Every core table has a `__taxa` table (taxon code to scientific name, GBIF
#' key, rank, and any `taxon_` traits). Tables with primary periods have
#' `__periods` (period index to calendar); tables whose sampling frame has
#' units that were never surveyed have `__units`; spatial capture-recapture
#' tables have `__traps`.
#'
#' @param table A table name (or the core table's data.frame from [eco_fetch()],
#'   whose `eco_table` attribute names it).
#' @return A data.frame, or `NULL` when the table has no such side table.
#' @examples
#' \donttest{
#' eco_taxa("schank_2015_tapir_occ")
#' eco_periods("frimpong_2017_newriver_dynocc")
#' }
#' @export
eco_taxa <- function(table) .eco_side(.eco_name_of(table), "__taxa")
#' @rdname eco_taxa
#' @export
eco_periods <- function(table) .eco_side(.eco_name_of(table), "__periods")
#' @rdname eco_taxa
#' @export
eco_units <- function(table) .eco_side(.eco_name_of(table), "__units")
#' @rdname eco_taxa
#' @export
eco_traps <- function(table) .eco_side(.eco_name_of(table), "__traps")

.eco_name_of <- function(x) {
  if (is.data.frame(x) && !is.null(attr(x, "eco_table"))) return(attr(x, "eco_table"))
  x
}

# One line for eco_info() when a table is over the anonymous cap, else "".
.eco_login_note <- function(table) {
  l <- tryCatch(.eco_table_listing(.eco_core, .eco_tag_for(.eco_core)), error = function(e) NULL)
  b <- if (is.null(l)) NA else l$bytes[l$name == table][1]
  if (isTRUE(b > .eco_anon_cap)) paste0("\n  size:     ", .eco_mb(b), " on Redivis; needs a Redivis login (see ?eco_fetch)") else ""
}

#' Describe a table, or the corpus
#'
#' With a table name, prints its title, dimensions, model family, response
#' type, licence and citation. Without one, prints the corpus totals.
#'
#' @param table A table name, or `NULL`.
#' @return Invisibly, the merged metadata row (or the totals as a list).
#' @examples
#' \donttest{
#' eco_info()
#' eco_info("schank_2015_tapir_occ")
#' }
#' @export
eco_info <- function(table = NULL) {
  m <- eco_metadata()
  if (is.null(table)) {
    v <- suppressMessages(eco_version())
    out <- list(n_tables = nrow(m), n_rows = sum(m$n_rows), n_units = sum(m$n_units),
                families = length(unique(eco_tags()$model_family)), eco = v$eco, eco_meta = v$eco_meta)
    message(sprintf("eco: %d tables, %s rows, %s units, %d model families\n",
                    out$n_tables, format(out$n_rows, big.mark = ","), format(out$n_units, big.mark = ","), out$families),
            sprintf("Redivis eco %s, eco_meta %s%s\n", out$eco, out$eco_meta,
                    if (is.na(v$eco_version)) "" else sprintf(" (eco version %d)", v$eco_version)),
            "standard: ", .eco_site, "standard.html\ndata: https://redivis.com/datasets/", .eco_core$ref)
    return(invisible(out))
  }
  table <- .eco_name_of(table)
  row <- m[m$table == table, , drop = FALSE]
  if (nrow(row) == 0) stop("no table `", table, "` in this eco version; see eco_list_tables()", call. = FALSE)
  b <- eco_biblio(); b <- b[b$table == table, , drop = FALSE]
  t <- eco_tags(); t <- t[t$table == table, , drop = FALSE]
  g <- function(d, col) if (nrow(d) && col %in% names(d) && !is.na(d[[col]][1]) && nzchar(d[[col]][1])) d[[col]][1] else "-"
  message(table, "\n  ", g(b, "title"),
          sprintf("\n  %s units x %s taxa x %s periods x %s occasions; %s rows; y in 0..%s",
                  row$n_units, row$n_taxa, row$n_periods, row$n_occasions, format(row$n_rows, big.mark = ","), row$max_y),
          "\n  family:   ", g(t, "model_family"), "\n  response: ", row$response_type, " (unit = ", row$unit_kind, ")",
          "\n  protocol: ", g(t, "sampling_protocol"), "; taxa: ", g(t, "taxon_group"), "; ", g(t, "country"),
          "\n  floor:    ", row$sample_floor, "; surveys rest on: ", row$survey_evidence,
          if (isTRUE(as.logical(row$coordinates_coarsened))) "\n  coordinates coarsened (sensitive taxon)" else "",
          .eco_login_note(table),
          "\n  licence:  ", g(b, "spdx"), " (source shows: ", g(b, "original_license"), ")",
          "\n  cite:     ", g(b, "citation"),
          "\n  columns:  ", gsub("|", ", ", row$variables, fixed = TRUE),
          "\n  script:   https://github.com/ben-domingue/eco/blob/main/", row$script)
  invisible(merge(merge(row, b, by = "table", all.x = TRUE), t, by = "table", all.x = TRUE))
}
