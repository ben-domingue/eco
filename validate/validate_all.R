# Validates every core table in output/ with eco-validate (eco_validate/, the one
# validator: standard.md clauses E1-E10 plus intake policy) and, through --irw,
# irw-validate on the IRW view (unit/taxon/y -> id/item/resp, Unix-second dates),
# so IRW v1.0 conformance stays a tested claim. Writes validate/report.csv, which
# the site reads. The R twin validate_eco() in converters/eco_standard.R still
# runs inside write_table(); this is the gate.
# Usage, from the repo root:  Rscript validate/validate_all.R
#   needs python3 with pandas; the IRW check needs ben-domingue/irw at
#   ~/Dropbox/projects/irw/src or $IRW_SRC (an "irw:unavailable" error otherwise).
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
`%||%` <- function(a, b) if (is.null(a)) b else a

cmd <- sprintf("cd %s && python3 -m eco_validate.cli --json --irw %s", shQuote(ECO_ROOT), shQuote(OUT_DIR))
out <- suppressWarnings(system(cmd, intern = TRUE))
j <- try(fromJSON(paste(out, collapse = "\n"), simplifyVector = FALSE), silent = TRUE)
if (inherits(j, "try-error") || !length(j)) stop("eco-validate produced no parseable output:\n", paste(out, collapse = "\n"))

rows <- lapply(j, function(r) {
  f <- r$findings %||% list()
  grp <- vapply(f, function(x) x$group %||% "", ""); sev <- vapply(f, function(x) x$severity %||% "", "")
  chk <- vapply(f, function(x) x$check %||% "", ""); msg <- vapply(f, function(x) x$message %||% "", "")
  eco <- grp != "irw"
  irw_err <- grp == "irw" & sev == "error"
  irw_conf <- !any(chk == "irw:conformance")
  irw <- paste0(if (any(irw_err)) "blocks" else "passes", if (irw_conf) " (conforms to v1.0)" else " (does not conform)")
  ds <- fromJSON(file.path(OUT_DIR, paste0(r$label, "__dataset.json")))
  s <- r$stats
  data.table(table = r$label, rows = s$n_rows %||% NA_integer_, units = s$n_units %||% NA_integer_, taxa = s$n_taxa %||% NA_integer_,
             eco_valid = isTRUE(r$ok) || !any(eco & sev == "error"),
             eco_problems = paste(sprintf("%s: %s", chk[eco & sev == "error"], msg[eco & sev == "error"]), collapse = "; "),
             eco_warnings = paste(chk[eco & sev == "warn"], collapse = "; "),
             conforms = isTRUE(r$conforms), nonconforming = paste(unlist(r$nonconforming), collapse = ","),
             taxa_table_matches = "taxa" %in% unlist(r$side_tables) && !any(chk == "side_taxa" & sev == "error"),
             sample_floor = ds$sampleFloor %||% "", survey_evidence = ds$surveyEvidence %||% "",
             standard = ds$standardVersion %||% "",
             irw_v1 = irw,  # refers to the IRW view of the table
             irw_warnings = paste(sub("^irw:", "", chk[grp == "irw" & sev == "warn" & chk != "irw:conformance"]), collapse = "; "))
})
rep <- rbindlist(rows)
fwrite(rep, file.path(ECO_ROOT, "validate", "report.csv"))
print(rep[, .(table, rows, units, taxa, eco_valid, conforms, sample_floor, irw_v1)])
if (!all(rep$eco_valid)) quit(status = 1)
