#' Choose tables by what they are
#'
#' Joins [eco_metadata()] and [eco_tags()] and keeps the tables matching every
#' argument given. Character arguments match if the tag contains the value,
#' ignoring case (`model_family = "occupancy"` matches every occupancy family),
#' or any of several values. The result goes straight into [eco_fetch()].
#'
#' @param model_family,response_type,taxon_group,protocol,unit_kind,realm,country
#'   Character, one or more values; `protocol` is the tags column
#'   `sampling_protocol`. `response_type` is one of `detection`, `count`,
#'   `state`, `ordinal`, `multinomial_cell`, `detection_event`, `binomial_count`.
#' @param min_units,min_occasions,min_periods,min_taxa Numeric lower bounds on
#'   the computed counts.
#' @param multi_species `TRUE` keeps tables with more than one taxon, `FALSE`
#'   single-taxon tables, `NULL` (default) both.
#' @param sample_floor `TRUE` keeps only tables meeting the standard's sample
#'   floor (30 units and 2 occasions or periods); `NULL` keeps all.
#' @return A data.frame of the matching tables with their metadata and tags
#'   columns, sorted by `table`. Zero rows when nothing matches.
#' @examples
#' \donttest{
#' eco_filter(model_family = "Single-season occupancy")
#' eco_filter(response_type = "count", min_units = 100)
#' eco_filter(taxon_group = "Amphibians", multi_species = TRUE)
#' }
#' @export
eco_filter <- function(model_family = NULL, response_type = NULL, taxon_group = NULL, protocol = NULL,
                       unit_kind = NULL, realm = NULL, country = NULL,
                       min_units = NULL, min_occasions = NULL, min_periods = NULL, min_taxa = NULL,
                       multi_species = NULL, sample_floor = NULL) {
  m <- eco_metadata(); t <- eco_tags()
  t <- t[, setdiff(names(t), intersect(names(t), setdiff(names(m), "table"))), drop = FALSE]
  d <- merge(m, t, by = "table", all.x = TRUE, sort = TRUE)
  keep <- rep(TRUE, nrow(d))
  like <- function(col, vals) {
    if (is.null(vals)) return(TRUE)
    x <- tolower(d[[col]] %||% rep(NA_character_, nrow(d)))
    Reduce(`|`, lapply(tolower(vals), function(v) !is.na(x) & grepl(v, x, fixed = TRUE)))
  }
  keep <- keep & like("model_family", model_family) & like("response_type", response_type) &
    like("taxon_group", taxon_group) & like("sampling_protocol", protocol) &
    like("unit_kind", unit_kind) & like("realm", realm) & like("country", country)
  if (!is.null(min_units)) keep <- keep & d$n_units >= min_units
  if (!is.null(min_occasions)) keep <- keep & d$n_occasions >= min_occasions
  if (!is.null(min_periods)) keep <- keep & d$n_periods >= min_periods
  if (!is.null(min_taxa)) keep <- keep & d$n_taxa >= min_taxa
  if (!is.null(multi_species)) keep <- keep & if (isTRUE(multi_species)) d$n_taxa > 1 else d$n_taxa == 1
  if (isTRUE(sample_floor)) keep <- keep & d$sample_floor == "meets"
  out <- d[keep %in% TRUE, , drop = FALSE]
  rownames(out) <- NULL
  out
}
