#' Reassemble a deposit shipped as regional tables
#'
#' A deposit normally ships as one table per survey design and response type.
#' The standard makes one narrow exception (issue #72): when that table would
#' be too large to download whole, it ships split by the source's own regional
#' strata. Each regional table is complete for its region, with its own taxon
#' pool (a taxon never recorded in a region has no rows there), and its
#' metadata names the deposit-level table it is a part of (`partition_of` in
#' [eco_metadata()]) and the `unit_` column that is constant within each part
#' (`partition_by`, which may live in the `__units` side table rather than the
#' core). The first case is the North American Breeding Bird Survey, shipped
#' as one table per Bird Conservation Region (`ziolkowski_2026_bbs_bcr<N>_count`).
#'
#' `eco_stack()` fetches the parts and binds them back into one table.
#'
#' @section Coordinates and the `_exact` siblings:
#' Under the coordinate rule (E7) a regional table holding an IUCN-threatened
#' taxon has coarsened coordinates, and an `_exact` sibling holding the same
#' rows without the flagged taxa at the published precision. `exact = FALSE`
#' stacks the plain tables: every taxon, with coordinates coarsened in the
#' regions where a flagged taxon occurs (and as published elsewhere).
#' `exact = TRUE` stacks the `_exact` sibling wherever one exists and the plain
#' table elsewhere: coordinates as published everywhere, without the flagged
#' taxa.
#'
#' @section Zeros between regions:
#' A taxon absent from a region's pool has no rows in that region's table, so
#' the stacked table is not a full taxon-by-survey grid. `fill_zeros = TRUE`
#' adds a `y = 0` row for each taxon (of `taxa`, or of every taxon in the
#' stacked table) at every survey of each region whose table has no rows at
#' all for that taxon. That is a fair zero only for a complete-list protocol,
#' so it is allowed only when every stacked table has `taxon_inclusion ==
#' "recorded"` in [eco_metadata()] (a taxon of the group present would have
#' been recorded) and none has a `__survey_taxa` side table (every taxon is
#' surveyed at every survey); otherwise `eco_stack()` stops and says why. A
#' survey is a distinct combination of the key columns other than `taxon`
#' (`unit`, `trap`, `period`, `occasion`, whichever the table has), taken from
#' the region's full table before `taxa` is applied. A filled row copies the
#' survey-level columns from its survey: those with one value per survey
#' across all fetched rows (`date`, `observer`, survey-level `obs_*`, `unit_*`,
#' `period_*`, ...). `taxon_*` columns are copied from the taxon's rows when
#' they have one value per taxon. Every other column (`y_raw`, and `obs_*`
#' columns that vary by taxon within a survey, such as BBS's
#' `obs_nonbreeder_count`) is `NA` on a filled row. A logical column `filled`
#' marks the added rows. Filled zeros multiply quickly (the Breeding Bird
#' Survey filled for every species is over 100 million rows), so use `taxa`
#' with `fill_zeros`.
#'
#' @param partition The deposit-level name the parts declare in `partition_of`,
#'   e.g. `"ziolkowski_2026_bbs"`.
#' @param taxa Optional character vector of taxon codes (the `taxon` column);
#'   only their rows are kept, and with `fill_zeros` only they are filled.
#' @param fill_zeros `TRUE` adds explicit zeros for taxa absent from a region
#'   (see the section above). Default `FALSE`.
#' @param exact `FALSE` (default) stacks the plain tables, `TRUE` the `_exact`
#'   siblings where they exist (see the section above).
#' @return A data.frame: the stacked core table, columns in the order of the
#'   first part (columns only some parts have are appended, `NA` elsewhere),
#'   plus `filled` when `fill_zeros = TRUE`. Attributes: `tables` (the tables
#'   stacked), `eco_partition` (`partition`), `partition_by`, `taxa` (the
#'   parts' `__taxa` bound and de-duplicated by `taxon`, restricted to `taxa`
#'   when given), `units` (the parts' `__units` bound and de-duplicated by
#'   `unit`, or `NULL`), and `periods` (the parts' `__periods` stacked with a
#'   `table` column naming the part each row describes, since per-region
#'   period summaries such as run counts do not all sum; or `NULL`).
#' @seealso [eco_fetch()] for one part; [eco_metadata()] for `partition_of`,
#'   `partition_by` and `taxon_inclusion`.
#' @examples
#' \donttest{
#' m <- eco_metadata()
#' unique(m$partition_of[!is.na(m$partition_of) & nzchar(m$partition_of)])
#' # two species across every Bird Conservation Region, with zeros where a
#' # region never recorded them
#' bbs <- eco_stack("ziolkowski_2026_bbs", taxa = c("A07610", "A07550"),
#'                  fill_zeros = TRUE)
#' table(bbs$taxon, bbs$filled)
#' head(attr(bbs, "units"))
#' }
#' @export
eco_stack <- function(partition, taxa = NULL, fill_zeros = FALSE, exact = FALSE) {
  if (!is.character(partition) || length(partition) != 1 || is.na(partition) || !nzchar(partition))
    stop("`partition` must be one deposit-level name, e.g. \"ziolkowski_2026_bbs\"", call. = FALSE)
  if (!is.null(taxa)) taxa <- unique(as.character(taxa))
  m <- eco_metadata()
  if (!"partition_of" %in% names(m))
    stop("this eco_meta version records no partitions (no `partition_of` column); see eco_version()", call. = FALSE)
  po <- as.character(m$partition_of)
  rows <- m[!is.na(po) & po == partition, , drop = FALSE]
  if (!nrow(rows)) {
    known <- sort(unique(po[!is.na(po) & nzchar(po)]))
    stop("no table in this eco version is a part of `", partition, "`; ",
         if (length(known)) paste0("partitioned deposits: ", paste(known, collapse = ", ")) else "it holds no partitioned deposits",
         call. = FALSE)
  }
  tables <- .eco_stack_choose(rows$table, exact)
  rows <- rows[match(tables, rows$table), , drop = FALSE]
  if (fill_zeros) .eco_stack_can_fill(rows)

  part_by <- if ("partition_by" %in% names(rows)) unique(stats::na.omit(as.character(rows$partition_by))) else character()

  key <- c("unit", "trap", "period", "occasion")
  cores <- list(); surveys <- list(); pools <- list(); level <- NULL
  for (t in tables) {
    d <- data.table::as.data.table(eco_fetch(t))
    sk <- intersect(key, names(d))
    lv <- .eco_survey_level(d, sk)
    level <- if (is.null(level)) lv else intersect(level, lv)
    if (fill_zeros) {
      surveys[[t]] <- unique(d[, c(sk, lv), with = FALSE], by = sk)
      pools[[t]] <- unique(as.character(d$taxon))
    }
    if (!is.null(taxa)) d <- d[as.character(d$taxon) %in% taxa]
    cores[[t]] <- d
  }
  out <- data.table::rbindlist(cores, use.names = TRUE, fill = TRUE)

  tx <- data.table::rbindlist(lapply(tables, function(t) eco_taxa(t)), use.names = TRUE, fill = TRUE)
  if (nrow(tx)) {
    tx <- unique(tx, by = "taxon")
    if (!is.null(taxa)) tx <- tx[as.character(tx$taxon) %in% taxa]
  }

  if (fill_zeros) {
    want <- if (is.null(taxa)) unique(as.character(out$taxon)) else taxa
    known <- unique(c(unlist(pools), if (nrow(tx)) as.character(tx$taxon)))
    bad <- setdiff(want, known)
    if (length(bad)) stop("no part of `", partition, "` has taxon ", paste(bad, collapse = ", "),
                          "; no zeros filled (see the parts' __taxa",
                          if (exact) "; exact = TRUE leaves out the IUCN-flagged taxa" else "", ")", call. = FALSE)
    out[, filled := FALSE]
    adds <- lapply(tables, function(t) {
      miss <- setdiff(want, pools[[t]])
      s <- surveys[[t]]
      if (!length(miss) || !nrow(s)) return(NULL)
      s <- s[, intersect(names(s), c(intersect(key, names(s)), level)), with = FALSE]
      z <- s[rep(seq_len(nrow(s)), times = length(miss))]
      z[, taxon := rep(miss, each = nrow(s))]
      z
    })
    adds <- data.table::rbindlist(adds, use.names = TRUE, fill = TRUE)
    if (nrow(adds)) {
      adds[, y := if (is.integer(out$y)) 0L else 0]
      adds[, filled := TRUE]
      tcols <- grep("^taxon_", names(out), value = TRUE)
      for (cc in tcols) {
        v <- unique(out[!is.na(out$taxon), c("taxon", cc), with = FALSE])
        if (!anyDuplicated(v$taxon)) adds[v, (cc) := get(paste0("i.", cc)), on = "taxon"]
      }
      out <- data.table::rbindlist(list(out, adds), use.names = TRUE, fill = TRUE)
    }
  }

  un <- data.table::rbindlist(lapply(tables, function(t) eco_units(t)), use.names = TRUE, fill = TRUE)
  un <- if (nrow(un)) as.data.frame(unique(un, by = "unit")) else NULL
  pe <- data.table::rbindlist(lapply(tables, function(t) {
    p <- eco_periods(t)
    if (is.null(p) || !nrow(p)) return(NULL)
    p <- data.table::as.data.table(p); p[, table := t]
    data.table::setcolorder(p, "table"); p
  }), use.names = TRUE, fill = TRUE)
  pe <- if (nrow(pe)) as.data.frame(pe) else NULL

  out <- as.data.frame(out)
  attr(out, "tables") <- tables
  attr(out, "eco_partition") <- partition
  attr(out, "partition_by") <- if (length(part_by)) part_by[1] else NA_character_
  attr(out, "taxa") <- if (nrow(tx)) as.data.frame(tx) else NULL
  attr(out, "units") <- un
  attr(out, "periods") <- pe
  out
}

# One table per part: the plain table, or with exact = TRUE its `_exact`
# sibling where one exists.
.eco_stack_choose <- function(tables, exact) {
  tables <- sort(unique(as.character(tables)))
  is_exact <- grepl("_exact_", tables, fixed = TRUE) | grepl("_exact$", tables)
  base <- sub("_exact$", "", sub("_exact_", "_", tables, fixed = TRUE))
  pick <- vapply(split(seq_along(tables), base), function(i) {
    e <- i[is_exact[i]]; p <- i[!is_exact[i]]
    if (exact && length(e)) e[1] else if (length(p)) p[1] else e[1]
  }, 1L)
  tables[sort(pick)]
}

# Stop unless zeros between regions are fair: every part a complete list of
# the recorded group (taxon_inclusion "recorded") with no __survey_taxa.
.eco_stack_can_fill <- function(rows) {
  if (!"taxon_inclusion" %in% names(rows))
    stop("cannot fill zeros: this eco_meta version records no taxon_inclusion, so whether a taxon ",
         "absent from a region would have been recorded is unknown", call. = FALSE)
  ti <- as.character(rows$taxon_inclusion)
  bad <- rows$table[is.na(ti) | ti != "recorded"]
  if (length(bad))
    stop("cannot fill zeros: taxon_inclusion is not \"recorded\" for ", paste(bad, collapse = ", "),
         " (", paste(unique(ifelse(is.na(ti[rows$table %in% bad]) | !nzchar(ti[rows$table %in% bad]), "unrecorded", ti[rows$table %in% bad])), collapse = ", "),
         "), so a taxon absent from a region is not known to have been looked for there", call. = FALSE)
  l <- eco_list_tables()
  st <- l$table[l$table %in% rows$table & l$survey_taxa]
  if (length(st))
    stop("cannot fill zeros: ", paste(st, collapse = ", "), " has a __survey_taxa side table, ",
         "so not every taxon was surveyed at every survey", call. = FALSE)
  invisible(TRUE)
}

# Columns with one value per survey (survey = distinct `sk`) in `d`, apart
# from the key, taxon and the response.
.eco_survey_level <- function(d, sk) {
  cand <- setdiff(names(d), c(sk, "taxon", "y", "y_raw", "filled"))
  cand <- cand[!startsWith(cand, "taxon_")]
  if (!length(cand) || !nrow(d)) return(cand)
  s <- unique(d[, c(sk, cand), with = FALSE])
  n <- s[, lapply(.SD, data.table::uniqueN), by = sk, .SDcols = cand]
  cand[vapply(cand, function(cc) all(n[[cc]] <= 1L), TRUE)]
}
