# The logged-in route, for tables over Redivis' 100 MB cap on anonymous requests.
#
# Everything under the cap goes over the anonymous CSV endpoint in http.R. A table
# over it is read with the redivis client (tbl$to_arrow_table()), which is what the
# IRW package does for every table. That needs the redivis and arrow packages and a
# Redivis login, and it counts against the account's export quota. This file never
# starts a login itself: a browser flow opened from inside eco_fetch() is a
# surprise, and in a script it hangs. It says how to log in and stops.

#: Packages the logged-in route needs (both in Suggests).
.eco_auth_pkgs <- c("redivis", "arrow")

# Whether Redivis credentials are in place without a login prompt. Mirrors the
# redivis client's own check, as IRW's .irw_redivis_credentials_available() does:
# a token in the environment, the cached-credentials file, or credentials already
# loaded this session. The client is read, never modified.
.eco_redivis_credentials_available <- function() {
  if (nzchar(Sys.getenv("REDIVIS_API_TOKEN"))) return(TRUE)
  if (file.exists(file.path(Sys.getenv("HOME"), ".redivis", "r_credentials"))) return(TRUE)
  auth_vars <- tryCatch(get("auth_vars", envir = asNamespace("redivis")), error = function(e) NULL)
  if (is.environment(auth_vars)) {
    if (!is.null(auth_vars$cached_credentials)) return(TRUE)
    cf <- auth_vars$credentials_file
    if (is.character(cf) && length(cf) == 1 && file.exists(cf)) return(TRUE)
  }
  FALSE
}

.eco_missing_auth_pkgs <- function() {
  .eco_auth_pkgs[!vapply(.eco_auth_pkgs, requireNamespace, logical(1), quietly = TRUE)]
}

.eco_mb <- function(bytes) paste0(format(round(bytes / 1024^2), big.mark = ","), " MB")

# Why the logged-in route cannot run here, or NULL when it can.
.eco_auth_problem <- function(table, bytes) {
  head <- paste0("`", table, "` is ", .eco_mb(bytes), " on Redivis, over the 100 MB that Redivis ",
                 "serves without a login. Tables this size need a free Redivis account.\n")
  missing <- .eco_missing_auth_pkgs()
  if (length(missing))
    return(paste0(head, "  1. install.packages(c(", paste0('"', missing, '"', collapse = ", "), "))\n",
                  "  2. redivis::redivis$authenticate()   (once; opens a browser), or set REDIVIS_API_TOKEN\n",
                  "  3. eco_fetch(\"", table, "\") again"))
  if (!.eco_redivis_credentials_available())
    return(paste0(head, "  1. redivis::redivis$authenticate()   (once; opens a browser), or set REDIVIS_API_TOKEN\n",
                  "  2. eco_fetch(\"", table, "\") again"))
  NULL
}

# Classify a redivis client error so the message says something useful.
.eco_auth_error_kind <- function(msg) {
  if (grepl("401|invalid_token|unauthori[sz]ed|No credentials", msg, ignore.case = TRUE)) return("auth")
  if (grepl("quota|429|rate.?limit|exceed", msg, ignore.case = TRUE)) return("quota")
  "other"
}

# Download one table over the logged-in route and write it to `dest` as CSV, so
# the cache and .eco_read_csv() treat it exactly like an anonymous download.
.eco_download_rows_auth <- function(dataset, table, tag, bytes, dest) {
  problem <- .eco_auth_problem(table, bytes)
  if (!is.null(problem)) stop(problem, call. = FALSE)
  message("eco: `", table, "` is ", .eco_mb(bytes), "; downloading with your Redivis login ",
          "(counts against your export quota; cached afterwards)")
  arrow_tbl <- tryCatch(
    .eco_redivis_arrow(dataset, table, tag),
    error = function(e) {
      msg <- conditionMessage(e)
      kind <- .eco_auth_error_kind(msg)
      stop(switch(kind,
        auth = paste0("Redivis did not accept your login while reading `", table, "`. Run ",
                      "redivis::redivis$authenticate(force_reauthentication = TRUE) and try again."),
        quota = paste0("Redivis refused `", table, "` on your account's export quota: ", msg),
        paste0("could not download `", table, "` from Redivis: ", msg)), call. = FALSE)
    })
  data.table::fwrite(as.data.frame(arrow_tbl), dest, na = "")
  invisible(dest)
}

# The one call into the redivis client. A separate function so tests can stub it.
.eco_redivis_arrow <- function(dataset, table, tag) {
  ref <- paste0(dataset$name, ":", dataset$ref, if (!is.null(tag)) paste0(":", .eco_tag_path(tag)))
  ds <- redivis::redivis$organization(.eco_owner)$dataset(ref)
  withCallingHandlers(
    ds$table(table)$to_arrow_table(),
    warning = function(w) if (grepl("reference id", conditionMessage(w))) invokeRestart("muffleWarning"))
}
