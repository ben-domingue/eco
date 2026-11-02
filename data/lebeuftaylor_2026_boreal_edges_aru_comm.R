#!/usr/bin/env Rscript
# Table:  lebeuftaylor_2026_boreal_edges_aru_comm
# Source: Borealis (Canadian Dataverse) doi:10.5683/SP4/FH7WY6, version 1.0 (2026-09-23),
#         licence CC0 1.0 (SPDX CC0-1.0 in the Dataverse record).
#         Lebeuf-Taylor, I. (2026). Replication Data for: Contrast between adjoining stands
#         drives timber harvest edge effects on boreal birds. Borealis.
# Paper:  Lebeuf-Taylor, I., Lebeuf-Taylor, E. & Bayne, E. "Contrast between adjoining
#         stands drives timber harvest edge effects on boreal birds", in prep (the analysis
#         repository's CITATION.cff gives the working title "Weak edge structuring of boreal
#         bird communities at regenerating harvest-forest boundaries"). No DOI yet
#         (Crossref searched 2026-11-01). Code: github.com/IsabelleLebTay/regenerating-harvest-edges.
# Data:   Six .rds files. jsdm_tables_150m_34spp.rds is the primary analysis input, a list
#         of five: spp_cols (34 alpha codes), loc_tbl (564 ARU locations: location id,
#         transect_id, position E0/N15/P15, forest_type ASPEN/SPRUCE, tsh = years since
#         harvest, latitude, longitude to 6 dp, i_idx, x_NP, x_edge, t_idx), transect_tbl
#         (189 transects: forest_type, tsh, tsh_z, BWSpr_N15 / BWSpr_P15 = percent black/white
#         spruce cover on the regenerating and the forest side, their z-scores x_Ncov /
#         x_Pcov), stan_data (y_obs 1,627 visits x 34 species 0/1; visit_loc; loc_transect;
#         the covariate vectors; day_v and time_v = standardised Julian day and time of day
#         of each visit, means not deposited) and species_names (code, common and scientific
#         name). The Stan model (MSOM.stan in the repository) documents the design: three
#         ARU positions per transect, N15 = 150 m into the regenerating harvest, E0 = the
#         edge, P15 = 150 m into undisturbed forest; "single-season sampling per transect",
#         no year effect; detections within 150 m. The four jsdm_tables_*_25spp.rds files
#         are the same visits for 25 of the species at 75 / 100 / 125 / 150 m detection
#         radii (the 150 m one is a column subset of the main file, asserted).
#         hill_numbers_prepared_data.rds holds per-location maximum counts of 64 species
#         (across visits) and Hill-number diversity data for the community analyses.
#         Not deposited: survey dates or year, raw Julian day or time, recording length,
#         the WildTrax exports, audio.
#
# Mapping (standard E9 community occupancy): unit = ARU location (564), cluster_id =
#   transect (189; three positions each, three transects have two), occasion = visit index
#   within the location in deposited order (1-5; day_v is non-decreasing within location,
#   asserted), y = 0/1, a row for every species at every visit (the deposited y_obs is that
#   matrix). surveyEvidence = deposited_matrix: the visit rows of y_obs are the survey set.
#   unit_position (E0 / N15 / P15), unit_position_m (signed distance from the edge, -150
#   regenerating side, 0, +150 forest side), unit_forest_type, unit_tsh_years (transect
#   level, constant within unit), unit_spruce_pct_regen_side / unit_spruce_pct_forest_side
#   (transect level), unit_decimalLatitude / unit_decimalLongitude as published (no taxon
#   CR/EN/VU; Canada Warbler is LC). obs_day_z and obs_time_z are the authors' standardised
#   visit covariates, shipped because no raw values exist (means and SDs not deposited).
#   Not shipped: the standardised duplicates tsh_z, x_Ncov, x_Pcov and the position
#   codings x_NP, x_edge (recoverable from unit_position); the 25-species radius files
#   (alternative truncation radii of the same detections); the Hill-number file (maximum
#   counts across visits, no per-visit survey set; diversity indices are derived).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lebeuftaylor_2026_boreal_edges_aru_comm"

files <- c(jsdm_tables_150m_34spp = 1226655, hill_numbers_prepared_data = 1226653, jsdm_tables_100m_25spp = 1226658,
           jsdm_tables_125m_25spp = 1226656, jsdm_tables_150m_25spp = 1226657, jsdm_tables_75m_25spp = 1226654)
paths <- sapply(names(files), function(n)
  download_cached(sprintf("https://borealisdata.ca/api/access/datafile/%d", files[[n]]), TABLE, paste0(n, ".rds")))

x <- readRDS(paths[["jsdm_tables_150m_34spp"]])
stopifnot(setequal(names(x), c("spp_cols", "loc_tbl", "transect_tbl", "stan_data", "species_names")))
sd <- x$stan_data
loc <- as.data.table(x$loc_tbl); tr <- as.data.table(x$transect_tbl); spn <- as.data.table(x$species_names)
stopifnot(sd$N_species == 34, sd$N_loc == 564, sd$N_transect == 189, sd$N_visits_total == 1627,
          identical(dim(sd$y_obs), c(1627L, 34L)), all(sd$y_obs %in% 0:1), sum(sd$y_obs) == 5130,
          nrow(loc) == 564, nrow(tr) == 189, !anyDuplicated(loc$location), !anyDuplicated(tr$transect_id),
          identical(loc$i_idx, 1:564), identical(tr$t_idx, 1:189),
          all(loc$t_idx == match(loc$transect_id, tr$transect_id)), identical(sd$loc_transect, loc$t_idx),
          length(x$spp_cols) == 34, setequal(x$spp_cols, spn$species_code), !anyDuplicated(spn$species_code))
# positions and their codings
stopifnot(all(loc$position %in% c("E0", "N15", "P15")),
          all(loc[position == "E0", x_NP == 0 & x_edge == 1]), all(loc[position == "N15", x_NP == -0.5 & x_edge == 0]),
          all(loc[position == "P15", x_NP == 0.5 & x_edge == 0]),
          identical(as.integer(table(loc$position)), c(186L, 189L, 189L)))
stopifnot(all(loc[, .N, by = transect_id]$N %in% 2:3), sum(loc[, .N, by = transect_id]$N == 2) == 3)
# transect-level facts are constant within transect, standardised columns are z-scores of the raw ones
lt <- merge(loc, tr, by = "transect_id", suffixes = c("", ".t"))
stopifnot(all(lt$forest_type == lt$forest_type.t), all(lt$tsh == lt$tsh.t), all(loc$forest_type %in% c("ASPEN", "SPRUCE")),
          all(loc$tsh >= 1 & loc$tsh <= 42), isTRUE(all.equal(as.numeric(scale(tr$tsh)), tr$tsh_z)),
          isTRUE(all.equal(as.numeric(scale(tr$BWSpr_N15)), tr$x_Ncov)), isTRUE(all.equal(as.numeric(scale(tr$BWSpr_P15)), tr$x_Pcov)),
          all(tr$BWSpr_N15 >= 0 & tr$BWSpr_N15 <= 100), all(tr$BWSpr_P15 >= 0 & tr$BWSpr_P15 <= 100))
# coordinates: Alberta, 6 decimals as deposited
stopifnot(all(loc$latitude > 49 & loc$latitude < 60), all(loc$longitude > -120.5 & loc$longitude < -110), !anyNA(loc$latitude))
# visits: every location visited, visits grouped by location in file order, day non-decreasing within location
v <- data.table(visit = seq_len(1627), i_idx = sd$visit_loc, day_z = sd$day_v, time_z = sd$time_v)
stopifnot(!is.unsorted(v$i_idx), all(1:564 %in% v$i_idx), all(v[, all(diff(day_z) >= 0), by = i_idx]$V1),
          !anyDuplicated(v[, .(i_idx, day_z, time_z)]), abs(mean(v$day_z)) < 1e-9, abs(sd(v$day_z) - 1) < 1e-9,
          abs(mean(v$time_z)) < 1e-9, abs(sd(v$time_z) - 1) < 1e-9)
v[, occasion := seq_len(.N), by = i_idx]
stopifnot(identical(as.integer(table(table(v$i_idx))), c(13L, 43L, 505L, 2L, 1L)))   # locations with 1..5 visits
cat(sprintf("  %d locations on %d transects, %d visits (1-5 per location), %d detections of %d species\n",
            nrow(loc), nrow(tr), nrow(v), sum(sd$y_obs), ncol(sd$y_obs)))

# the 25-species files are column subsets of the same visits at other radii (not shipped)
s25 <- readRDS(paths[["jsdm_tables_150m_25spp"]])
stopifnot(s25$stan_data$N_visits_total == 1627, all(s25$spp_cols %in% x$spp_cols),
          identical(s25$stan_data$y_obs, sd$y_obs[, match(s25$spp_cols, x$spp_cols)]))
for (r in c("75m", "100m", "125m")) {
  s <- readRDS(paths[[paste0("jsdm_tables_", r, "_25spp")]])
  stopifnot(s$stan_data$N_visits_total == 1627, identical(s$stan_data$visit_loc, sd$visit_loc),
            all(s$stan_data$y_obs <= sd$y_obs[, match(s$spp_cols, x$spp_cols)]))   # a smaller radius never adds a detection
}

# long table: visit x species
ymat <- sd$y_obs; colnames(ymat) <- x$spp_cols
long <- data.table(visit = rep(v$visit, times = 34), taxon = rep(colnames(ymat), each = 1627), y = as.integer(as.vector(ymat)))
long <- merge(long, v, by = "visit")
long <- merge(long, loc[, .(i_idx, unit = location, cluster_id = transect_id, unit_position = position,
                            unit_position_m = as.integer(x_NP * 300), unit_forest_type = forest_type, unit_tsh_years = as.integer(tsh),
                            unit_decimalLatitude = latitude, unit_decimalLongitude = longitude)], by = "i_idx")
long <- merge(long, tr[, .(cluster_id = transect_id, unit_spruce_pct_regen_side = BWSpr_N15, unit_spruce_pct_forest_side = BWSpr_P15)],
              by = "cluster_id")
long <- long[, .(unit, taxon, y, occasion, cluster_id, unit_position, unit_position_m, unit_forest_type, unit_tsh_years,
                 unit_spruce_pct_regen_side, unit_spruce_pct_forest_side, unit_decimalLatitude, unit_decimalLongitude,
                 obs_day_z = round(day_z, 6), obs_time_z = round(time_z, 6))]
long <- order_eco(long)
stopifnot(nrow(long) == 1627 * 34, sum(long$y) == 5130, uniqueN(long$unit) == 564, uniqueN(long$cluster_id) == 189,
          all(long[, .N, by = .(unit, occasion)]$N == 34), all(long$unit_position_m %in% c(-150L, 0L, 150L)))

taxa <- make_taxa(spn$species_code, spn[["Scientific name"]], vernacularName = spn$species_common_name)
stopifnot(!anyNA(taxa$taxonID))

dataset <- list(
  title = "Boreal bird detections within 150 m at ARU recorders on 189 harvest-edge transects, Alberta: 34 species x 1,627 visits",
  creator = "Lebeuf-Taylor, Isabelle", pubDate = "2026", doi = "10.5683/SP4/FH7WY6",
  sourceURL = "https://doi.org/10.5683/SP4/FH7WY6",
  citation = "Lebeuf-Taylor, I. (2026). Replication Data for: Contrast between adjoining stands drives timber harvest edge effects on boreal birds [Dataset]. Borealis, V1. https://doi.org/10.5683/SP4/FH7WY6",
  paperDOI = NA,
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Autonomous recording units at three positions on each of 189 transects crossing the boundary between a regenerating timber harvest (1-42 years since harvest) and undisturbed aspen or spruce forest in boreal Alberta: 150 m into the regenerating stand (N15), on the edge (E0) and 150 m into the forest (P15). Each location was visited (one recording interpreted) one to five times in a single season; 34 songbird species identified within 150 m of the recorder, 0/1 per visit. The deposit is the analysis-ready input of the authors' 34-species multispecies occupancy model; the sampling year, calendar dates and recording length are not deposited.",
  samplingProtocol = "Autonomous recording units (ARUs; WildTrax processing) at 150 m spacing across harvest-forest edges; detections within a 150 m radius; one to five recordings per location interpreted as visits; the deposit is the Stan input of the authors' multispecies occupancy model.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "Boreal forest of Alberta, Canada, 49-59 N, 111-120 W; recorder coordinates as published",
  temporalCoverage = "not deposited (one season per transect; the Stan model has no year effect; the deposit was published 2026-09)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (6 decimals); no taxon is IUCN CR/EN/VU"),
  designNote = "Multi-scale layout (transect > recorder position > visit) read as community occupancy with unit = recorder location and cluster_id = transect, following E9's cluster_id convention; the authors' model treats position as a location covariate, not a nested level.",
  covariateNote = "obs_day_z and obs_time_z are the authors' standardised Julian day and time of day of each visit (mean 0, SD 1 over the 1,627 visits); raw values, means and SDs are not deposited. All other covariates are raw as deposited. unit_tsh_years and the two spruce-cover percentages are transect-level facts repeated on each of the transect's locations.",
  notes = "unit_position_m is the signed distance from the edge implied by the position code (-150 regenerating side, 0 edge, +150 forest side), not a measured distance. Three transects (273, 2A, 48) have two positions instead of three. Species codes are the deposit's IBP-AOS alpha codes.",
  notShipped = list(
    `tsh_z, x_Ncov, x_Pcov` = "standardised duplicates of unit_tsh_years and the spruce-cover percentages",
    `x_NP, x_edge` = "numeric codings of unit_position used by the Stan model",
    `jsdm_tables_{75,100,125,150}m_25spp.rds` = "the same 1,627 visits for 25 of the species at other detection radii (alternative truncations of one detection set; the 150 m file is a column subset of the shipped table, asserted)",
    `hill_numbers_prepared_data.rds` = "per-location maximum counts of 64 species across visits (no per-visit survey set) and derived Hill-number diversity and dissimilarity data"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/lebeuftaylor_2026_boreal_edges_aru_comm.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of 34 boreal songbird species within 150 m of autonomous recording units at 564 locations (three positions across each of 189 regenerating harvest edges in Alberta), 1-5 visits per location in one season; position, forest type, years since harvest, spruce cover on each side, coordinates, standardised visit day and time.",
  url = "https://doi.org/10.5683/SP4/FH7WY6",
  reference = "Lebeuf-Taylor, I., Lebeuf-Taylor, E., & Bayne, E. (in prep). Contrast between adjoining stands drives timber harvest edge effects on boreal birds. Data: Borealis, doi:10.5683/SP4/FH7WY6.",
  doi_paper = "", doi_data = "10.5683/SP4/FH7WY6",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Analysis-ready Stan input (.rds); survey year, dates and recording length not deposited; visit day and time only as z-scores. Paper in prep (no DOI, 2026-11-01).",
  source_via = "Borealis (Canadian Dataverse)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multispecies, edge design)",
  sampling_protocol = "acoustic", design = "Single-season (1-5 ARU visits per location; 3 positions per transect)", realm = "Terrestrial", country = "CAN",
  coordinates = "As published", notes = "189 harvest-edge transects x 3 recorder positions (cluster_id = transect); year not deposited; obs_ covariates are z-scores.",
  status = "tagged")
