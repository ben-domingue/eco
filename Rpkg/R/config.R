# Where the data lives. The reference ids (4j5q, 241c) survive a rename on Redivis;
# the names are what people read. Nothing here is a credential: both datasets are
# public at access level "data", which is what makes the anonymous CSV route work.

.eco_owner <- "datapages"
.eco_core <- list(name = "eco", ref = "4j5q")
.eco_meta <- list(name = "eco_meta", ref = "241c")

#: Redivis refuses an unauthenticated rows request over 100 MB. Most eco tables
#: are far under it; the few over it are read with a Redivis login (auth.R).
.eco_anon_cap <- 100 * 1024^2

.eco_api <- "https://redivis.com/api/v1"

#: The release manifest, one row per eco version (releases/manifest.csv in the
#: repository). It maps an eco version to the Redivis versions of both datasets.
.eco_manifest_url <- "https://raw.githubusercontent.com/ben-domingue/eco/main/releases/manifest.csv"

.eco_site <- "https://ben-domingue.github.io/eco/"

#: Suffixes of the side tables that may sit beside a core table, with the key
#: column each must carry.
.eco_side_keys <- c("__taxa" = "taxon", "__periods" = "period", "__units" = "unit", "__traps" = "trap",
                    "__survey_taxa" = "taxon")   # v1.1-draft E4.2, E6

.eco_user_agent <- function() {
  paste0("eco-R/", as.character(utils::packageVersion("eco")), " (https://github.com/ben-domingue/eco)")
}

`%||%` <- function(a, b) if (is.null(a)) b else a
