#' Where fetched tables are kept
#'
#' Every table downloaded by [eco_fetch()] and the side-table readers is kept on
#' disk under `tools::R_user_dir("eco", "cache")`, filed by dataset and Redivis
#' version tag. A released version never changes, so a cached file is good
#' until you delete it. Set `options(eco.cache = FALSE)` or `ECO_CACHE=0` to
#' bypass the cache for a session; `ECO_CACHE_DIR` moves it.
#'
#' @return Path to the cache folder (it may not exist yet).
#' @seealso [eco_cache_info()], [eco_clear_cache()]
#' @export
eco_cache_dir <- function() {
  d <- Sys.getenv("ECO_CACHE_DIR", unset = "")
  if (nzchar(d)) return(path.expand(d))
  tools::R_user_dir("eco", which = "cache")
}

.eco_cache_enabled <- function() {
  opt <- getOption("eco.cache")
  if (!is.null(opt)) return(isTRUE(opt))
  env <- tolower(Sys.getenv("ECO_CACHE", unset = "1"))
  !env %in% c("0", "false", "no", "off")
}

.eco_cache_path <- function(dataset, tag, table) {
  file.path(eco_cache_dir(), dataset$name, .eco_tag_path(tag), paste0(table, ".csv"))
}

# The CSV for one table at one tag, from disk when cached.
.eco_table_file <- function(dataset, table, tag) {
  path <- .eco_cache_path(dataset, tag, table)
  if (.eco_cache_enabled() && file.exists(path)) return(path)
  dest <- if (.eco_cache_enabled()) path else tempfile(fileext = ".csv")
  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
  tmp <- paste0(dest, ".part")
  .eco_download_rows(dataset, table, tag, tmp)
  file.rename(tmp, dest)
  dest
}

#' What the cache holds
#'
#' @return A data.frame with one row per cached file: `dataset`, `version`,
#'   `table`, `bytes`, `cached` (time).
#' @export
eco_cache_info <- function() {
  files <- list.files(eco_cache_dir(), pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
  if (!length(files)) return(data.frame(dataset = character(), version = character(), table = character(),
                                        bytes = numeric(), cached = as.POSIXct(character())))
  rel <- strsplit(substring(files, nchar(eco_cache_dir()) + 2), "/", fixed = TRUE)
  info <- file.info(files)
  data.frame(dataset = vapply(rel, `[`, "", 1), version = gsub("_", ".", vapply(rel, `[`, "", 2), fixed = TRUE),
             table = sub("\\.csv$", "", vapply(rel, `[`, "", 3)),
             bytes = info$size, cached = info$mtime, stringsAsFactors = FALSE, row.names = NULL)
}

#' Delete cached tables
#'
#' @param dataset Optionally `"eco"` or `"eco_meta"` to clear only that dataset.
#' @return Invisibly, the number of files removed.
#' @export
eco_clear_cache <- function(dataset = NULL) {
  d <- eco_cache_dir()
  if (!is.null(dataset)) d <- file.path(d, dataset)
  files <- list.files(d, recursive = TRUE, full.names = TRUE)
  unlink(d, recursive = TRUE)
  invisible(length(files))
}
