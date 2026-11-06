# Versions. Redivis versions each dataset separately (the core shards `eco`,
# `eco_2`, ... and `eco_meta`); the repository's releases/manifest.csv pairs them
# into numbered eco versions (1, 2, ...), one `<dataset>_redivis_version` column
# each. By default every read goes to the current release of each dataset.
# eco_set_version(n) pins every dataset to the tags the manifest records for eco
# version n; a core shard with no tag there was not part of that version.

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
#' the core shards (`eco`, `eco_2`, ...) and `eco_meta` it is, how many tables,
#' and a note. Read from the
#' repository (`releases/manifest.csv`), which is updated after each release.
#'
#' @return A data.frame.
#' @export
eco_manifest <- function() .eco_manifest()

#' Pin reads to an eco version
#'
#' After `eco_set_version(1)`, every fetch and every metadata read goes to the
#' Redivis versions of the datasets that eco version 1 consists of, so a
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

.eco_manifest_col <- function(dataset) paste0(dataset$name, "_redivis_version")

.eco_is_core <- function(dataset) any(vapply(.eco_cores, function(d) identical(d$name, dataset$name), logical(1)))

# Tag to read `dataset` at: the pin's, or NULL (current release).
.eco_tag_for <- function(dataset) {
  pin <- .eco_env$pin
  if (is.null(pin)) return(NULL)
  tag <- pin[[.eco_manifest_col(dataset)]]
  if (is.null(tag) || is.na(tag) || !nzchar(tag)) NULL else tag
}

# The tag actually being read (resolves "current" to a real tag, one API call).
.eco_resolved_tag <- function(dataset) {
  if (.eco_is_core(dataset)) {
    tag <- .eco_core_tags()[[dataset$name]]
    if (is.na(tag)) stop("Redivis ", dataset$name, " is not part of the eco version being read", call. = FALSE)
    return(tag)
  }
  tag <- .eco_tag_for(dataset)
  if (!is.null(tag)) return(tag)
  as.character(.eco_dataset_props(dataset)$version$tag)
}

# The tag of every core shard in the version being read, newest last; NA for a
# shard that is not part of it. Pinned: the manifest row's tags, NA where blank.
# Current: each shard's latest release. A shard Redivis will not show anonymously
# is skipped only when the manifest has never recorded a release of it (a shard
# registered before its first release); any other failure is an error, so a
# network problem never silently drops a shard.
.eco_core_tags <- function() {
  if (!is.null(.eco_env$core_tags)) return(.eco_env$core_tags)
  pin <- .eco_env$pin
  tags <- vapply(.eco_cores, function(d) {
    if (!is.null(pin)) return(.eco_tag_for(d) %||% NA_character_)
    tryCatch(as.character(.eco_dataset_props(d)$version$tag), error = function(e) {
      if (identical(d$name, .eco_core$name) || .eco_ever_released(d)) stop(e)
      NA_character_
    })
  }, character(1))
  names(tags) <- vapply(.eco_cores, `[[`, "", "name")
  .eco_env$core_tags <- tags
  tags
}

.eco_ever_released <- function(dataset) {
  col <- .eco_manifest_col(dataset)
  m <- tryCatch(.eco_manifest(), error = function(e) NULL)
  !is.null(m) && col %in% names(m) && any(nzchar(m[[col]]) & !is.na(m[[col]]))
}

# The core shards in the version being read, newest first.
.eco_cores_in_force <- function() {
  tags <- .eco_core_tags()
  rev(.eco_cores[!is.na(tags)])
}

#' Which versions are being read
#'
#' @return Invisibly, a list with `eco_version` (the pinned eco version, or
#'   `NA` when reading current releases), one element per core shard (`eco`,
#'   `eco_2`, ...: its Redivis version tag in force, `NA` when the shard is not
#'   part of this version), `eco_meta`, and `released` (that release's date,
#'   from the manifest, when it is a numbered eco version). Prints a summary.
#' @export
eco_version <- function() {
  pin <- .eco_env$pin
  cores <- .eco_core_tags(); meta <- .eco_resolved_tag(.eco_meta)
  m <- .eco_manifest()
  match <- rep(TRUE, nrow(m))
  for (d in .eco_cores) {
    col <- .eco_manifest_col(d)
    have <- if (col %in% names(m)) ifelse(is.na(m[[col]]), "", m[[col]]) else rep("", nrow(m))
    want <- cores[[d$name]]; if (is.na(want)) want <- ""
    match <- match & have == want
  }
  hit <- m[match, , drop = FALSE]
  out <- c(list(eco_version = if (nrow(hit)) hit$eco_version[nrow(hit)] else NA_integer_),
           as.list(cores),
           list(eco_meta = meta, released = if (nrow(hit)) hit$date[nrow(hit)] else NA_character_,
                pinned = !is.null(pin)))
  shown <- cores[!is.na(cores)]
  message(if (out$pinned) "pinned to " else "reading current release: ",
          if (is.na(out$eco_version)) "" else paste0("eco v", out$eco_version, " "),
          "(Redivis ", paste(names(shown), shown, collapse = ", "), ", eco_meta ", meta, ")",
          if (!is.na(out$released)) paste0(", released ", substr(out$released, 1, 10)) else "")
  invisible(out)
}
