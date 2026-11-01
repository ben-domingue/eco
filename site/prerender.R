# Pre-render step for the eco site.
#
dir.create("data", showWarnings = FALSE)
tags <- read.csv("../tags/tags_auto.csv", check.names = FALSE, stringsAsFactors = FALSE)
val  <- read.csv("../validate/report.csv", stringsAsFactors = FALSE)
stats <- list(
  n_tables   = nrow(tags),
  n_rows     = sum(as.numeric(tags$n_rows)),
  n_units    = sum(as.numeric(tags$n_units)),
  n_species  = sum(as.numeric(tags$n_taxa)),
  n_families = length(unique(sub(" \\(.*", "", tags$model_family))),
  n_valid    = sum(val$eco_valid & grepl("passes", val$irw_v1)),
  n_below_floor = sum(tags$sample_floor != "meets"),
  built      = max(vapply(list.files("../output", "__dataset.json$", full.names = TRUE),
                 function(f) jsonlite::read_json(f)$buildDate, ""))
)
jsonlite::write_json(stats, "data/site_stats.json", auto_unbox = TRUE, pretty = TRUE)
cat("prerender.R: data/site_stats.json written\n")
