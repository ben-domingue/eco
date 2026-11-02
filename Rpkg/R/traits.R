# Species traits fetched at use time from two open trait databases. Nothing
# from either is stored in eco or eco_meta (issue #35): the files are
# downloaded into the package cache the first time they are asked for and
# joined onto a table's __taxa by scientific name.

.eco_trait_sources <- list(
  AVONET = list(
    version = "v7 (figshare 10.6084/m9.figshare.16586228.v7)",
    url = "https://ndownloader.figshare.com/files/34480856",
    file = file.path("avonet_v7", "AVONET_Supplementary_dataset_1.xlsx"),
    citation = "Tobias, J. A. et al. (2022). AVONET: morphological, ecological and geographical data for all birds. Ecology Letters 25, 581-597. doi:10.1111/ele.13898. CC BY 4.0.",
    taxon_group = "Birds"),
  COMBINE = list(
    version = "v4 (figshare 10.6084/m9.figshare.13028255.v4)",
    url = "https://ndownloader.figshare.com/files/27703263",
    file = file.path("combine_v4", "trait_data_reported.csv"),
    citation = "Soria, C. D., Pacifici, M., Di Marco, M., Stephen, S. M. and Rondinini, C. (2021). COMBINE: a coalesced mammal database of intrinsic and extrinsic traits. Ecology 102, e03344. doi:10.1002/ecy.3344. CC BY 4.0.",
    taxon_group = "Mammals"))

.eco_trait_file <- function(src, refresh = FALSE) {
  path <- file.path(eco_cache_dir(), "traits", src$file)
  if (!refresh && file.exists(path)) return(path)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  tmp <- paste0(path, ".part")
  old <- options(HTTPUserAgent = .eco_user_agent(), timeout = max(300, getOption("timeout")))
  on.exit(options(old), add = TRUE)
  status <- tryCatch(suppressWarnings(utils::download.file(src$url, tmp, quiet = TRUE, mode = "wb")),
                     error = function(e) conditionMessage(e))
  if (!identical(status, 0L)) {
    if (file.exists(tmp)) unlink(tmp)
    stop("could not download ", basename(src$file), " from figshare (", src$url, ")",
         if (is.character(status)) paste0(": ", status) else "", call. = FALSE)
  }
  file.rename(tmp, path)
  path
}

.eco_traits_avonet <- function(refresh = FALSE) {
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("reading AVONET needs the readxl package: install.packages(\"readxl\")", call. = FALSE)
  src <- .eco_trait_sources$AVONET
  path <- .eco_trait_file(src, refresh)
  # The BirdLife taxonomy sheet: one row per species, Mass in grams (the mean of
  # the sexes, mostly from Dunning 2007); Mass.Source says where it came from.
  a <- suppressWarnings(readxl::read_excel(path, sheet = "AVONET1_BirdLife",
                                           col_types = "text", progress = FALSE))
  need <- c("Species1", "Order1", "Family1", "Mass", "Mass.Source")
  if (!all(need %in% names(a)))
    stop("AVONET sheet AVONET1_BirdLife does not have the columns expected (", paste(need, collapse = ", "),
         "); the figshare file may have changed", call. = FALSE)
  data.frame(scientific_name = a$Species1, taxon_group = "Birds", order = a$Order1, family = a$Family1,
             body_mass_g = suppressWarnings(as.numeric(a$Mass)), body_mass_source = a$Mass.Source,
             source = "AVONET", source_version = src$version, stringsAsFactors = FALSE)
}

.eco_traits_combine <- function(refresh = FALSE) {
  src <- .eco_trait_sources$COMBINE
  path <- .eco_trait_file(src, refresh)
  # Reported (not imputed) traits, one row per species of the IUCN 2020 list.
  cb <- .eco_read_csv(path)
  need <- c("iucn2020_binomial", "order", "family", "adult_mass_g")
  if (!all(need %in% names(cb)))
    stop("COMBINE trait_data_reported.csv does not have the columns expected (", paste(need, collapse = ", "),
         "); the figshare file may have changed", call. = FALSE)
  data.frame(scientific_name = cb$iucn2020_binomial, taxon_group = "Mammals", order = cb$order, family = cb$family,
             body_mass_g = as.numeric(cb$adult_mass_g), body_mass_source = "COMBINE reported",
             source = "COMBINE", source_version = src$version, stringsAsFactors = FALSE)
}

# Join a trait table onto a __taxa table by name. Three attempts, in order:
# the exact scientificName; GBIF's accepted name when the deposit's name is a
# synonym; and the binomial when the deposit names a subspecies. Rank below
# species (a genus, a family, an "sp.") is never matched.
.eco_match_traits <- function(taxa, traits) {
  if (!"scientificName" %in% names(taxa))
    stop("the taxa table has no scientificName column", call. = FALSE)
  traits <- traits[!is.na(traits$scientific_name), , drop = FALSE]
  traits <- traits[!duplicated(traits$scientific_name), , drop = FALSE]
  idx <- function(x) match(x, traits$scientific_name)
  name <- as.character(taxa$scientificName)
  acc <- if ("gbifAcceptedName" %in% names(taxa)) as.character(taxa$gbifAcceptedName) else rep(NA_character_, nrow(taxa))
  binom <- ifelse(lengths(strsplit(name, " ", fixed = TRUE)) >= 2,
                  vapply(strsplit(name, " ", fixed = TRUE), function(w) paste(w[1:2], collapse = " "), ""), NA_character_)
  sub_species <- if ("taxonRank" %in% names(taxa)) !is.na(taxa$taxonRank) & !taxa$taxonRank %in% c("species", "subspecies") else rep(FALSE, nrow(taxa))
  hit <- idx(name); how <- ifelse(is.na(hit), NA_character_, "exact")
  h2 <- idx(acc); use <- is.na(hit) & !is.na(h2); hit[use] <- h2[use]; how[use] <- "accepted_name"
  h3 <- idx(binom); use <- is.na(hit) & !is.na(h3) & binom != name; hit[use] <- h3[use]; how[use] <- "binomial"
  hit[sub_species] <- NA_integer_; how[sub_species] <- NA_character_
  how[is.na(how)] <- "none"
  out <- taxa
  out$body_mass_g <- traits$body_mass_g[hit]
  out$trait_name <- traits$scientific_name[hit]
  out$trait_source <- traits$source[hit]
  out$trait_match <- how
  out
}

#' Species traits from AVONET and COMBINE
#'
#' Body mass for birds (AVONET, Tobias et al. 2022) and mammals (COMBINE, Soria
#' et al. 2021), fetched from figshare at use time. eco does not store traits:
#' they are not detection data, and both sources are open (CC BY 4.0), stable
#' and keyed on the scientific names every `__taxa` table already carries. The
#' two files are downloaded once into `file.path(eco_cache_dir(), "traits")`
#' and read from there afterwards. AVONET is an xlsx, so reading it needs the
#' `readxl` package.
#'
#' With no `x`, the two sources are returned stacked as one data.frame. With a
#' table name or a `__taxa` data.frame, the traits are joined onto that table
#' by name. Three attempts are made for each row, in order: the exact
#' `scientificName`; the `gbifAcceptedName` when the deposit's name is a
#' synonym; and the binomial when the deposit names a subspecies. Codes above
#' species rank (a genus, a family, "sp.") are never matched. `trait_match`
#' says which attempt succeeded, or `"none"`.
#'
#' @param x `NULL` for the full trait table; otherwise a core table name, the
#'   data.frame [eco_fetch()] returned, or a `__taxa` data.frame from
#'   [eco_taxa()].
#' @param group Which sources to fetch: `"birds"` (AVONET), `"mammals"`
#'   (COMBINE), or both. Fetching only what a table needs saves the 21 MB
#'   AVONET download for a mammal table.
#' @param refresh Re-download even when the files are cached.
#' @return With `x = NULL`: a data.frame with `scientific_name`, `taxon_group`,
#'   `order`, `family`, `body_mass_g`, `body_mass_source`, `source`,
#'   `source_version`, with the citations of the sources used in
#'   `attr(, "citations")`. Otherwise the `__taxa` table with `body_mass_g`,
#'   `trait_name` (the name matched in the source), `trait_source` and
#'   `trait_match` added.
#' @references
#' Tobias, J. A. et al. (2022). AVONET: morphological, ecological and
#' geographical data for all birds. *Ecology Letters* 25, 581–597.
#' \doi{10.1111/ele.13898}. Data: \doi{10.6084/m9.figshare.16586228}.
#'
#' Soria, C. D., Pacifici, M., Di Marco, M., Stephen, S. M. and Rondinini, C.
#' (2021). COMBINE: a coalesced mammal database of intrinsic and extrinsic
#' traits. *Ecology* 102, e03344. \doi{10.1002/ecy.3344}. Data:
#' \doi{10.6084/m9.figshare.13028255}.
#' @examples
#' \donttest{
#' tr <- eco_traits(group = "mammals")
#' head(tr)
#' eco_traits("mctigue_2023_nwarkansas_comm", group = "mammals")
#' }
#' @seealso [eco_taxa()], [eco_cache_dir()]
#' @export
eco_traits <- function(x = NULL, group = c("birds", "mammals"), refresh = FALSE) {
  group <- match.arg(group, several.ok = TRUE)
  parts <- list()
  if ("birds" %in% group) parts$AVONET <- .eco_traits_avonet(refresh)
  if ("mammals" %in% group) parts$COMBINE <- .eco_traits_combine(refresh)
  traits <- do.call(rbind, unname(parts))
  rownames(traits) <- NULL
  attr(traits, "citations") <- vapply(.eco_trait_sources[names(parts)], `[[`, "", "citation")
  if (is.null(x)) return(traits)
  taxa <- if (is.data.frame(x) && "scientificName" %in% names(x)) x else eco_taxa(x)
  if (is.null(taxa)) stop("no __taxa table for `", .eco_name_of(x), "`", call. = FALSE)
  .eco_match_traits(taxa, traits)
}
