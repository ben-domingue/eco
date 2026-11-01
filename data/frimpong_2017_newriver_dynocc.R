#!/usr/bin/env Rscript
# Table:  frimpong_2017_newriver_dynocc
# Source: Harvard Dataverse doi:10.7910/DVN/KS4HIR (CC0 1.0), published 2017-10-23
#   Frimpong, E. (2017). Fish Detection Histories and Covariates, Upper and Middle New
#   River Drainage Basin (Virginia and North Carolina, USA). Harvard Dataverse, V1.
# Data:   UMNR_FishDetectionsPerHucYear.tab: 74 species x 100 HUC12 watersheds x years
#         1938-2014; 1 = detected, 0 = not detected, blank = HUC not sampled that year.
#         Effort.tab: number of fish collections per HUC-year (blank = none).
#         HucMedianYr.tab: median year of each 3-year primary sampling period per HUC
#         (identical for all HUCs: 1938, 1941, ..., 2013).
#         Checked: the blank pattern is identical across species within a HUC, a HUC-year
#         is non-blank exactly when Effort > 0, and every sampled year lies within +-1
#         of a median year.
#
# Mapping (standard section 3.5, dynamic occupancy, multi-species):
#   unit = HUC12 code, taxon = 6-letter species code (first three letters of genus and
#   species; see taxa table), period = 3-year primary period 1..26, occasion = year
#   within period 1..3 (median year = 2), y = 0/1, obs_effort = collections that
#   HUC-year. The periods side table gives start / median / end calendar years.
#   Detection histories were compiled from museum / database records and the authors'
#   collections, so "surveyed" means "at least one collection that year".
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "frimpong_2017_newriver_dynocc"
DV <- "https://dataverse.harvard.edu/api/access/datafile/%s?format=original"
det <- fread(download_cached(sprintf(DV, 3065920), TABLE, filename = "UMNR_FishDetectionsPerHucYear.csv"), header = TRUE)
eff <- fread(download_cached(sprintf(DV, 3065921), TABLE, filename = "Effort.csv"))
med <- fread(download_cached(sprintf(DV, 3065922), TABLE, filename = "HucMedianYr.csv"))
stopifnot(nrow(det) == 7400, uniqueN(det$Species) == 74, uniqueN(det$HUC) == 100)

# primary periods: same grid for every HUC
grid <- sort(unique(med$Year)); stopifnot(all(diff(grid) == 3), med[, .N, by = HUC][, all(N == length(grid))])
periods <- data.table(period = seq_along(grid), start_year = grid - 1L, median_year = grid, end_year = grid + 1L)

ycols <- setdiff(names(det), c("Species", "HUC")); for (cc in ycols) set(det, j = cc, value = as.integer(det[[cc]]))
long <- melt(det, unit.vars = c("Species", "HUC"), variable.name = "year", value.name = "y", variable.factor = FALSE)
long <- long[!is.na(y)]
long[, year := as.integer(year)]
stopifnot(all(long$y %in% c(0L, 1L)))
long[, period := findInterval(year, grid - 1L)]
long[, occasion := year - (grid[period] - 1L) + 1L]
stopifnot(all(long$occasion %in% 1:3))
# effort
eff <- eff[!is.na(Effort) & Effort > 0]
long <- merge(long, eff, by.x = c("HUC", "year"), by.y = c("HUC", "Year"), all.x = TRUE)
stopifnot(!anyNA(long$Effort))                       # every surveyed HUC-year has effort
stopifnot(nrow(unique(long[, .(HUC, year)])) == nrow(eff))   # and vice versa

# species codes
sp <- data.table(scientificName = sort(unique(det$Species)))
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", scientificName), 1, 3), substr(sub("^[^ ]+ ", "", scientificName), 1, 3)))]
# disambiguate collisions (e.g. Notropis ... ) with a trailing digit, in alphabetical order
sp[, n := .N, by = taxon][n > 1, taxon := paste0(taxon, seq_len(.N)), by = taxon][, n := NULL]
stopifnot(!anyDuplicated(sp$taxon), all(nchar(sp$taxon) <= 7))
long <- merge(long, sp, by.x = "Species", by.y = "scientificName")
long <- long[, .(unit = HUC, taxon, y = as.integer(y), period, occasion, obs_effort = as.integer(Effort))]

taxa <- make_taxa(sp$taxon, sp$scientificName)
dataset <- list(
  title = "Fish detection histories per HUC12 watershed and year, Upper and Middle New River basin (VA/NC, USA), 1938-2014",
  creator = "Frimpong, Emmanuel", pubDate = "2017", doi = "10.7910/DVN/KS4HIR",
  sourceURL = "https://doi.org/10.7910/DVN/KS4HIR",
  citation = "Frimpong, E. (2017). Fish Detection Histories and Covariates, Upper and Middle New River Drainage Basin (Virginia and North Carolina, USA) (V1) [Data set]. Harvard Dataverse. https://doi.org/10.7910/DVN/KS4HIR",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Species detection histories spanning 77 years (1938-2014) compiled from online databases and authors' collections. Covariate data used for occupancy models include number of collections per HUC per year and the median year of each 3-yr primary sampling period.",
  samplingProtocol = "Compiled fish collection records (museum databases and authors' collections); a HUC-year counts as surveyed when at least one collection exists; number of collections is the effort covariate.",
  samplingProtocolCode = "compiled_collections", effortColumn = "obs_effort",
  surveyEvidence = "effort_table", responseType = "detection", unitKind = "site",
  closure = "occasion (years within a 3-year primary period)",
  geographicCoverage = "Upper and Middle New River drainage, Virginia and North Carolina, USA (HUC12 codes; no coordinates deposited)",
  temporalCoverage = "1938/2014", coordinatesCoarsened = NA)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/frimpong_2017_newriver_dynocc.R")

stage_dict_row(TABLE,
  description = "Detection/non-detection of 74 fish species in 100 HUC12 watersheds of the Upper and Middle New River basin (Virginia/North Carolina) across 26 three-year primary periods (1938-2014), compiled from collection records; years within a period are secondary occasions and the number of collections per HUC-year is the effort covariate.",
  url = "https://doi.org/10.7910/DVN/KS4HIR",
  reference = "Frimpong, E. (2017). Fish Detection Histories and Covariates, Upper and Middle New River Drainage Basin (Virginia and North Carolina, USA). Harvard Dataverse, V1.",
  doi_data = "10.7910/DVN/KS4HIR", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "No associated paper identified on Crossref. Surveyed = at least one collection record that HUC-year.",
  source_via = "Harvard Dataverse")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "compiled_collections", design = "Multi-season (26 periods x up to 3 years)", realm = "Freshwater",
  country = "USA", coordinates = "None in source (HUC12 codes)", notes = "Opportunistic sampling: 1,008 of 7,700 HUC-years surveyed.")
