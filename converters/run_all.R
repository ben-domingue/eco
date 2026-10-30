# Runs every round-trip script and collates results into output/roundtrip_results.csv
scripts <- sort(list.files(pattern = "^rt_[0-9]+_.*\\.R$"))
for (s in scripts) { cat("\n==== ", s, "\n"); source(s, local = new.env()) }
suppressPackageStartupMessages(library(data.table))
res <- rbindlist(lapply(list.files("output", pattern = "^results_.*\\.csv$", full.names = TRUE), fread))
fwrite(res, "output/roundtrip_results.csv")
print(res[, .(checks = .N, failed = sum(!ok)), by = dataset])
