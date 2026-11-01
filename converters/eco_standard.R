# eco_standard.R -- the converters and the R validator twin, for scripts in this
# repository that source rather than install the package.
#
# The implementation lives in ../Rpkg/R/convert.R (the `eco` R package, issue #7);
# this file sources it so data/ build scripts, the round-trip tests and the package
# share one copy. Functions: array_to_eco, eco_to_array, umf_to_eco, eco_to_umf,
# mpois_to_eco, eco_to_mpois, ch_to_eco, eco_to_ch, order_eco, eco_check
# (validate_eco is kept as an alias), eco_to_unmarked, eco_to_irw. Plus the three
# repository-only helpers below (write_eco, read_eco, same_estimates).
#
# Core columns: unit, taxon, y [, y_raw, trap, period, occasion, date, observer,
#               treat, cluster_id, unit_*, period_*, obs_*, taxon_*]
# Key: (unit, taxon, trap, period, occasion), absent columns treated as 1.
# Rule: a row exists iff a survey happened. NA in a native matrix -> no row.
# date is ISO 8601 (YYYY-MM-DD or YYYY-MM-DDThh:mm[:ss][Z]); eco_to_irw() turns it into seconds.

suppressPackageStartupMessages({ library(data.table) })

local({
  # the repo root: ECO_ROOT when lib/eco_common.R set it, else search upward from
  # the working directory, else relative to this file when sourced with a path
  candidates <- c(if (exists("ECO_ROOT")) ECO_ROOT, getwd(), dirname(getwd()), dirname(dirname(getwd())))
  f <- sys.frame(1)$ofile
  if (!is.null(f)) candidates <- c(candidates, dirname(dirname(f)))
  hit <- NULL
  for (d in candidates) if (file.exists(file.path(d, "Rpkg", "R", "convert.R"))) { hit <- d; break }
  if (is.null(hit)) stop("converters/eco_standard.R: cannot find Rpkg/R/convert.R from ", getwd())
  source(file.path(hit, "Rpkg", "R", "convert.R"), local = globalenv())
})
`%||%` <- function(a, b) if (is.null(a)) b else a
validate_eco <- eco_check

write_eco <- function(long, name, dir = "output", taxa = NULL, dataset = NULL) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  fwrite(long, file.path(dir, paste0(name, ".csv")))
  if (!is.null(taxa)) fwrite(taxa, file.path(dir, paste0(name, "__taxa.csv")))
  if (!is.null(dataset)) jsonlite::write_json(dataset, file.path(dir, paste0(name, "__dataset.json")),
                                              auto_unbox = TRUE, pretty = TRUE)
  invisible(file.path(dir, paste0(name, ".csv")))
}
read_eco <- function(path) fread(path)

# compare two numeric vectors of estimates
same_estimates <- function(a, b, tol = 1e-6) isTRUE(all.equal(unname(a), unname(b), tolerance = tol))
