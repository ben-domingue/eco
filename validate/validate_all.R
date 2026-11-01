# Validates every table in output/ twice: against the draft standard (validate_eco,
# converters/eco_standard.R) and, through its IRW view (eco_to_irw(): id/item/resp
# names, Unix-second dates, written to .cache/irw_view/<table>.csv), against IRW v1.0
# with irw-validate from ben-domingue/irw (skipped if that checkout is absent).
# The uploader reads the same view files. Writes validate/report.csv.
# Usage, from the repo root:  Rscript validate/validate_all.R
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
IRW_SRC <- Sys.getenv("IRW_SRC", unset = path.expand("~/Dropbox/projects/irw/src"))
tables <- sub("\\.csv$", "", grep("__", list.files(OUT_DIR, pattern = "\\.csv$"), value = TRUE, invert = TRUE))
rows <- list()
for (t in tables) {
  long <- fread(file.path(OUT_DIR, paste0(t, ".csv")))
  v <- validate_eco(long)
  view_dir <- file.path(ECO_ROOT, ".cache", "irw_view"); dir.create(view_dir, showWarnings = FALSE, recursive = TRUE)
  view_path <- file.path(view_dir, paste0(t, ".csv")); fwrite(eco_to_irw(long), view_path)
  ds <- fromJSON(file.path(OUT_DIR, paste0(t, "__dataset.json")))
  taxa_ok <- file.exists(file.path(OUT_DIR, paste0(t, "__taxa.csv"))) &&
    setequal(fread(file.path(OUT_DIR, paste0(t, "__taxa.csv")))$taxon, unique(long$taxon))
  irw <- NA_character_; irw_warn <- NA_character_
  if (dir.exists(file.path(IRW_SRC, "irw_validate"))) {
    cmd <- sprintf("cd %s && python3 -m irw_validate.cli --json %s 2>/dev/null",
                   shQuote(IRW_SRC), shQuote(view_path))
    out <- suppressWarnings(system(cmd, intern = TRUE))
    j <- try(fromJSON(paste(out, collapse = "\n"), simplifyVector = FALSE), silent = TRUE)
    if (!inherits(j, "try-error") && length(j)) {
      r <- j[[1]]
      f <- r$findings %||% list()
      sev <- sapply(f, function(x) x$severity %||% "")
      nm <- sapply(f, function(x) x$check %||% "")
      irw <- if (isTRUE(r$ok)) "passes" else "blocks"
      irw <- paste0(irw, if (isTRUE(r$conforms)) " (conforms to v1.0)" else " (does not conform)")
      irw_warn <- paste(nm[sev == "warn"], collapse = "; ")
    } else irw <- "irw-validate: could not parse output"
  }
  rows[[t]] <- data.table(table = t, rows = nrow(long), units = uniqueN(long$unit), taxa = uniqueN(long$taxon),
                          eco_valid = v$ok, eco_problems = paste(v$problems, collapse = "; "),
                          taxa_table_matches = taxa_ok, sample_floor = ds$sampleFloor,
                          irw_v1 = irw, irw_warnings = irw_warn)  # irw_v1 refers to the IRW view of the table
}
rep <- rbindlist(rows)
fwrite(rep, "validate/report.csv")
print(rep[, .(table, rows, units, taxa, eco_valid, sample_floor, irw_v1)])
if (!all(rep$eco_valid)) quit(status = 1)
