# The table list every metadata stage uses (sourced by 01, 02 and 03).
#
# A table is listed by its output/<t>__dataset.json, which is always tracked in
# git, not by its core CSV: cores over GitHub's 100 MB limit and period parts
# are gitignored (.gitignore), so on a fresh clone, or any machine that has not
# rebuilt them, the core is simply absent. Listing by core made stages 02 and 03
# drop those tables' rows and stage 01 lose their counts (#66). Withdrawing a
# table is now an explicit act: delete its __dataset.json (with a
# releases/withdrawals.csv row), not a side effect of a missing file.
eco_tables <- function(out_dir) {
  tabs <- sort(sub("__dataset\\.json$", "", list.files(out_dir, "__dataset\\.json$")))
  cores <- c(sub("\\.csv$", "", grep("__", list.files(out_dir, "\\.csv$"), value = TRUE, invert = TRUE)),
             sub("\\.parts$", "", list.files(out_dir, "\\.parts$")))   # period parts (standard E4)
  orphan <- setdiff(cores, tabs)
  if (length(orphan)) stop("core table(s) without a __dataset.json: ", paste(orphan, collapse = ", "), call. = FALSE)
  tabs
}
# Is the core (a CSV, or a directory of period parts) present on this machine?
has_core <- function(out_dir, t)
  file.exists(file.path(out_dir, paste0(t, ".csv"))) || dir.exists(file.path(out_dir, paste0(t, ".parts")))
