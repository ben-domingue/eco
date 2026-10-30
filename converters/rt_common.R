# shared harness for the round-trip scripts
suppressPackageStartupMessages({ library(unmarked); library(data.table); library(jsonlite) })
source(file.path(dirname(sys.frame(1)$ofile %||% "."), "eco_standard.R"))
OUT <- file.path(dirname(sys.frame(1)$ofile %||% "."), "output")
`%||%` <- function(a, b) if (is.null(a)) b else a
RESULTS <- list()
record <- function(dataset, check, ok, detail = "") {
  RESULTS[[length(RESULTS) + 1]] <<- data.table(dataset = dataset, check = check, ok = ok, detail = detail)
  cat(sprintf("[%s] %-38s %s %s\n", dataset, check, if (ok) "OK  " else "FAIL", detail))
}
# compare numeric matrices allowing NA in the same places
same_matrix <- function(a, b) {
  a <- unname(as.matrix(a)); b <- unname(as.matrix(b)); storage.mode(a) <- "double"; storage.mode(b) <- "double"
  identical(dim(a), dim(b)) && identical(is.na(a), is.na(b)) && isTRUE(all.equal(a, b, check.attributes = FALSE))
}
same_df <- function(a, b) {
  a <- as.data.frame(a); b <- as.data.frame(b); rownames(a) <- rownames(b) <- NULL
  isTRUE(all.equal(a[order(names(a))], b[order(names(b))], check.attributes = FALSE))
}
write_results <- function(name) {
  r <- rbindlist(RESULTS)
  fwrite(r, file.path(OUT, paste0("results_", name, ".csv")))
  invisible(r)
}

# obsCovs comparison restricted to surveyed cells (y non-NA); returns list(ok, n_lost)
compare_obs <- function(oc_native, oc_back, y) {
  surveyed <- as.vector(t(!is.na(y)))         # site-major order as unmarked stores obsCovs
  ok <- TRUE; lost <- 0L
  for (nm in names(oc_native)) {
    a <- oc_native[[nm]]; b <- oc_back[[nm]]
    ok <- ok && isTRUE(all.equal(a[surveyed], b[surveyed], check.attributes = FALSE))
    lost <- lost + sum(!surveyed & !is.na(a))
  }
  list(ok = ok, n_lost = lost)
}
surveyed_sites <- function(y) which(rowSums(!is.na(y)) > 0)
