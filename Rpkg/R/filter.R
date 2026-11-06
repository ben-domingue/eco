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
#' @param licence The licence a table is redistributed under (the `spdx`
#'   column of [eco_biblio()]; each table keeps its source's licence). One or
#'   more SPDX ids (`"CC0-1.0"`, `"CC-BY-4.0"`, ...), or a shortcut:
#'   `"permissive"` keeps tables whose licence allows commercial use and asks
#'   at most for attribution (no NonCommercial, ShareAlike, NoDerivatives,
#'   ODbL or GPL clause); `"public-domain"` keeps CC0 and public-domain
#'   dedications only. A table with no recorded licence is never kept by a
#'   licence filter. Attribution is still owed under CC BY, and citing the
#'   deposit is asked of every use (see [eco_cite()]).
#' @return A data.frame of the matching tables with their metadata and tags
#'   columns and `licence` (SPDX id), sorted by `table`. Zero rows when nothing matches.
#' @examples
#' \donttest{
#' eco_filter(model_family = "Single-season occupancy")
#' eco_filter(response_type = "count", min_units = 100)
#' eco_filter(taxon_group = "Amphibians", multi_species = TRUE)
#' eco_filter(model_family = "occupancy", licence = "permissive")   # e.g. commercial use
#' }
#' @export
eco_filter <- function(model_family = NULL, response_type = NULL, taxon_group = NULL, protocol = NULL,
                       unit_kind = NULL, realm = NULL, country = NULL,
                       min_units = NULL, min_occasions = NULL, min_periods = NULL, min_taxa = NULL,
                       multi_species = NULL, sample_floor = NULL, licence = NULL) {
  m <- eco_metadata(); t <- eco_tags()
  t <- t[, setdiff(names(t), intersect(names(t), setdiff(names(m), "table"))), drop = FALSE]
  d <- merge(m, t, by = "table", all.x = TRUE, sort = TRUE)
  b <- eco_biblio()
  lic <- if ("spdx" %in% names(b)) as.character(b$spdx) else rep(NA_character_, nrow(b))
  d$licence <- lic[match(d$table, b$table)]
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
  if (!is.null(licence)) keep <- keep & .eco_licence_ok(d$licence, licence)
  out <- d[keep %in% TRUE, , drop = FALSE]
  rownames(out) <- NULL
  out
}

# Which SPDX ids pass a licence filter: the shortcuts "permissive" and
# "public-domain", else exact SPDX ids (case-insensitive). NA never passes.
# "permissive": public domain, CC BY (any version, no NC/SA/ND), ODC-By, the
# UK Open Government Licence.
.eco_licence_ok <- function(spdx, licence) {
  x <- toupper(trimws(as.character(spdx))); x[is.na(x)] <- ""
  pd <- x %in% c("CC0-1.0", "PDDL-1.0", "CC-PDDC")
  # an allow-list, so a licence eco has not classified is excluded, not let through
  attribution <- grepl("^CC-BY-[0-9.]+(-[A-Z]+)?$", x) & !grepl("-(NC|SA|ND)", x) |
    grepl("^ODC-BY-|^OGL-", x)
  ok <- rep(FALSE, length(x))
  for (v in licence) {
    ok <- ok | switch(tolower(v),
      "public-domain" = pd,
      "permissive" = pd | attribution,
      x == toupper(v))
  }
  ok
}
