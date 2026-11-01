# Versions. Redivis versions `eco` and `eco_meta` separately; the repository's
# releases/manifest.csv pairs them into numbered eco versions (1, 2, ...). By
# default every read goes to the current release of each dataset. eco_set_version(n)
# pins both datasets to the Redivis tags the manifest records for eco version n.

.eco_manifest <- function() {
  if (!is.null(.eco_env$manifest)) return(.eco_env$manifest)
  tmp <- tempfile(fileext = ".csv"); on.exit(unlink(tmp), add = TRUE)
  .eco_download(.eco_manifest_url, tmp, what = "the release manifest")
  m <- utils::read.csv(tmp, stringsAsFactors = FALSE, colClasses = "character")
  m$eco_version <- as.integer(m$eco_version)
  .eco_env$manifest <- m
  m
}

#' The release manifest
#'
#' One row per eco version: when it was released, which Redivis versions of
#' `eco` and `eco_meta` it is, how many tables, and a note. Read from the
#' repository (`releases/manifest.csv`), which is updated after each release.
#'
#' @return A data.frame.
#' @export
eco_manifest <- function() .eco_manifest()

#' Pin reads to an eco version
#'
#' After `eco_set_version(1)`, every fetch and every metadata read goes to the
#' Redivis versions of `eco` and `eco_meta` that eco version 1 consists of, so a
#' script reproduces what it read then. [eco_reset_version()] returns to the
#' current releases. [eco_version()] says what is in force.
#'
#' @param version An integer eco version from [eco_manifest()].
#' @return Invisibly, the manifest row pinned.
#' @export
eco_set_version <- function(version) {
  m <- .eco_manifest()
  row <- m[m$eco_version == as.integer(version), , drop = FALSE]
  if (nrow(row) != 1)
    stop("no eco version ", version, "; eco_manifest() lists ", paste(m$eco_version, collapse = ", "), call. = FALSE)
  if (!nzchar(row$eco_meta_redivis_version))
    message("eco version ", version, " has no eco_meta release of its own; metadata reads use the current eco_meta release")
  .eco_env$pin <- row
  .eco_clear_session_cache()
  invisible(row)
}

#' @rdname eco_set_version
#' @export
eco_reset_version <- function() {
  .eco_env$pin <- NULL
  .eco_clear_session_cache()
  invisible(NULL)
}

.eco_clear_session_cache <- function() {
  keep <- c("pin", "manifest")
  rm(list = setdiff(ls(.eco_env, all.names = TRUE), keep), envir = .eco_env)
}

# Tag to read `dataset` at: the pin's, or NULL (current release).
.eco_tag_for <- function(dataset) {
  pin <- .eco_env$pin
  if (is.null(pin)) return(NULL)
  tag <- if (identical(dataset$name, .eco_core$name)) pin$eco_redivis_version else pin$eco_meta_redivis_version
  if (!nzchar(tag)) NULL else tag
}

# The tag actually being read (resolves "current" to a real tag, one API call).
.eco_resolved_tag <- function(dataset) {
  tag <- .eco_tag_for(dataset)
  if (!is.null(tag)) return(tag)
  as.character(.eco_dataset_props(dataset)$version$tag)
}

#' Which versions are being read
#'
#' @return Invisibly, a list with `eco_version` (the pinned eco version, or
#'   `NA` when reading current releases), `eco` and `eco_meta` (the Redivis
#'   version tags in force) and `released` (that release's date, from the
#'   manifest, when it is a numbered eco version). Prints a summary.
#' @export
eco_version <- function() {
  pin <- .eco_env$pin
  core <- .eco_resolved_tag(.eco_core); meta <- .eco_resolved_tag(.eco_meta)
  m <- .eco_manifest()
  hit <- m[m$eco_redivis_version == core, , drop = FALSE]
  out <- list(eco_version = if (nrow(hit)) hit$eco_version[nrow(hit)] else NA_integer_,
              eco = core, eco_meta = meta, released = if (nrow(hit)) hit$date[nrow(hit)] else NA_character_,
              pinned = !is.null(pin))
  message(if (out$pinned) "pinned to " else "reading current release: ",
          if (is.na(out$eco_version)) "" else paste0("eco v", out$eco_version, " "),
          "(Redivis eco ", core, ", eco_meta ", meta, ")",
          if (!is.na(out$released)) paste0(", released ", substr(out$released, 1, 10)) else "")
  invisible(out)
}
