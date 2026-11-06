# The Redivis core shards (eco, eco_2, ...), read from the package's own list in
# Rpkg/R/config.R, which tools/check_config_parity.py keeps equal to
# redivis_config.py. Sourced by prerender.R and the pages that link the shards,
# so a new shard reaches the site without a prose edit. Paths are relative to site/.
local({
  `%||%` <- function(a, b) if (is.null(a)) b else a
  e <- environment()
  sys.source("../Rpkg/R/config.R", envir = e)
  cores <- get(".eco_cores", envir = e)
  shard_names <<- vapply(cores, `[[`, "", "name")
  shard_refs <<- paste0(shard_names, ":", vapply(cores, `[[`, "", "ref"))
  shard_urls <<- paste0("https://redivis.com/datasets/", vapply(cores, `[[`, "", "ref"))
  shard_links_md <<- paste0("[`datapages.", shard_names, "`](", shard_urls, ")", collapse = ", ")
})
