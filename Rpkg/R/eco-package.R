#' eco: ecological detection data in one long format
#'
#' Tables live on Redivis in the core shards `datapages.eco`, `eco_2`, ... and
#' are served as CSV to anyone, no account needed. Describe the corpus with
#' [eco_list_tables()], [eco_list_deposits()],
#' [eco_metadata()], [eco_tags()] and [eco_biblio()]; narrow it with
#' [eco_filter()]; download with [eco_fetch()] (side tables: [eco_taxa()],
#' [eco_periods()], [eco_units()], [eco_traps()]); reshape with
#' [eco_to_array()], [eco_to_unmarked()], [eco_to_ch()]; pin a release with
#' [eco_set_version()]. The standard the tables follow is at
#' <https://ben-domingue.github.io/eco/standard.html>.
#'
#' @section The format:
#' One row per taxon per survey. `unit` is the thing with the latent state (a
#' site, camera, pond, transect, or an individual animal), `taxon` a short
#' species code resolved in the `__taxa` side table, `y` the observation.
#' `period` and `occasion` are the primary and secondary survey indices;
#' covariates are prefixed by the level at which they are constant (`unit_`,
#' `period_`, `obs_`, `taxon_`). A row exists iff a survey happened: `y = 0` is
#' surveyed and not detected, a missing row is not surveyed, `y` is never `NA`.
#'
#' @section Words:
#' A **table** is one eco table: a **core** (the long `unit, taxon, y` file)
#' plus its **side tables** (`__taxa`, `__periods`, `__units`, `__traps`,
#' `__survey_taxa`), for one survey design and response type. A **deposit** is
#' the source it was built from, one DOI or archive record; one deposit can
#' yield several tables. On Redivis, a **shard** is one of the core datasets
#' (`eco`, `eco_2`, ...) and an **entry** is one physical Redivis table, side
#' tables and parts included. Code keeps its own names (`sideTables` in
#' `__dataset.json`, the `dataset` column of [eco_list_tables()], which names
#' the shard). More at <https://ben-domingue.github.io/eco/glossary.html>.
#'
#' @keywords internal
"_PACKAGE"

#' @import data.table
#' @importFrom stats ave setNames
NULL

# data.table's non-standard evaluation symbols, so R CMD check does not flag them
utils::globalVariables(c(
  ".", ".col", ".k", ".site", "N", "occasion", "period", "taxon", "unit", "y", "y_raw",
  "n_units", "n_occasions", "n_periods", "n_taxa", "model_family", "response_type",
  "taxon_group", "sampling_protocol", "sample_floor"
))

.eco_env <- new.env(parent = emptyenv())
