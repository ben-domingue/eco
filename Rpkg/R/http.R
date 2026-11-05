# One thin layer over the Redivis REST API, anonymous. Two calls are used:
#   GET /datasets/<owner>.<dataset>[:<tag>]            -> dataset properties (version tag)
#   GET /datasets/<owner>.<dataset>[:<tag>]/tables     -> table listing (paged)
#   GET /tables/<owner>.<dataset>[:<tag>].<table>       -> table properties (numRows, numBytes)
#   GET /tables/<owner>.<dataset>[:<tag>].<table>/rows?format=csv -> the data
# The Stata package in ben-domingue/irw found this route; it needs no token for a
# dataset whose public access level is "data" and refuses results over 100 MB.
# A table over that goes through the redivis client with a login instead (auth.R).

# "v1.0" -> "v1_0", the form Redivis takes inside a path.
.eco_tag_path <- function(tag) if (is.null(tag)) NULL else gsub(".", "_", tag, fixed = TRUE)

.eco_dataset_ref <- function(dataset, tag = NULL) {
  ref <- paste0(.eco_owner, ".", dataset$name, ":", dataset$ref)
  if (!is.null(tag)) ref <- paste0(ref, ":", .eco_tag_path(tag))
  ref
}

.eco_download <- function(url, dest, what = url) {
  old <- options(HTTPUserAgent = .eco_user_agent()); on.exit(options(old), add = TRUE)
  status <- tryCatch(
    suppressWarnings(utils::download.file(url, dest, quiet = TRUE, mode = "wb")),
    error = function(e) conditionMessage(e))
  if (!identical(status, 0L)) {
    if (file.exists(dest)) unlink(dest)
    stop("could not download ", what, " from Redivis",
         if (is.character(status)) paste0(": ", status) else "",
         "\n  (is the network up? is the table in a released version of the dataset?)",
         call. = FALSE)
  }
  invisible(dest)
}

.eco_get_json <- function(path, query = NULL) {
  url <- paste0(.eco_api, path)
  if (length(query)) url <- paste0(url, "?", paste0(names(query), "=", utils::URLencode(as.character(query), reserved = TRUE), collapse = "&"))
  tmp <- tempfile(fileext = ".json"); on.exit(unlink(tmp), add = TRUE)
  .eco_download(url, tmp, what = path)
  jsonlite::fromJSON(tmp, simplifyVector = TRUE)
}

# Properties of a dataset at a tag (NULL = current release). Memoised per session.
.eco_dataset_props <- function(dataset, tag = NULL) {
  key <- paste0("dataset:", dataset$name, ":", tag %||% "current")
  if (!is.null(.eco_env[[key]])) return(.eco_env[[key]])
  p <- .eco_get_json(paste0("/datasets/", .eco_dataset_ref(dataset, tag)))
  if (!is.null(tag) && !identical(as.character(p$version$tag), tag))
    stop("Redivis resolved ", dataset$name, " ", tag, " to ", p$version$tag,
         "; that version does not exist or is not released", call. = FALSE)
  .eco_env[[key]] <- p
  p
}

# Every table in a dataset at a tag: data.frame(name, rows, bytes, hash, updated).
.eco_table_listing <- function(dataset, tag = NULL) {
  key <- paste0("tables:", dataset$name, ":", tag %||% "current")
  if (!is.null(.eco_env[[key]])) return(.eco_env[[key]])
  path <- paste0("/datasets/", .eco_dataset_ref(dataset, tag), "/tables")
  out <- list(); token <- NULL
  repeat {
    q <- list(maxResults = 500); if (!is.null(token)) q$pageToken <- token
    page <- .eco_get_json(path, q)
    r <- page$results
    if (length(r)) out[[length(out) + 1]] <- data.frame(
      name = r$name, rows = as.numeric(r$numRows %||% NA), bytes = as.numeric(r$numBytes %||% NA),
      hash = r$hash %||% NA_character_,
      updated = as.POSIXct((r$updatedAt %||% NA) / 1000, origin = "1970-01-01", tz = "UTC"),
      stringsAsFactors = FALSE)
    token <- page$nextPageToken
    if (is.null(token) || !nzchar(token)) break
  }
  res <- if (length(out)) do.call(rbind, out) else
    data.frame(name = character(), rows = numeric(), bytes = numeric(), hash = character(),
               updated = as.POSIXct(character(), tz = "UTC"), stringsAsFactors = FALSE)
  res <- res[order(res$name), , drop = FALSE]; rownames(res) <- NULL
  .eco_env[[key]] <- res
  res
}

# Download one table's rows as CSV into `dest`.
.eco_download_rows <- function(dataset, table, tag, dest) {
  listing <- .eco_table_listing(dataset, tag)
  row <- listing[listing$name == table, , drop = FALSE]
  if (nrow(row) == 0)
    stop("no table `", table, "` in ", dataset$name, " ", tag,
         ". eco_list_tables() shows what this version holds.", call. = FALSE)
  if (isTRUE(row$bytes > .eco_anon_cap))
    return(.eco_download_rows_auth(dataset, table, tag, row$bytes, dest))
  url <- paste0(.eco_api, "/tables/", .eco_dataset_ref(dataset, tag), ".", table, "/rows?format=csv")
  .eco_download(url, dest, what = table)
}

.eco_table_url <- function(dataset, table) {
  paste0("https://redivis.com/datasets/", dataset$ref, "/tables?name=", table)
}

.eco_read_csv <- function(path) {
  as.data.frame(data.table::fread(path, na.strings = c("", "NA"), encoding = "UTF-8", showProgress = FALSE))
}
