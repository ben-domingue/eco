# Runs every data/ script from the repo root. Usage: Rscript data/run_all.R
scripts <- sort(setdiff(list.files("data", pattern = "\\.R$", full.names = TRUE), "data/run_all.R"))
for (s in scripts) { cat("\n==== ", s, "\n"); status <- system2("Rscript", s); if (status != 0) stop("failed: ", s) }
