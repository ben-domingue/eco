#!/usr/bin/env Rscript
# Table:  grant_2023_canaanvalley_amph_count
# Source: USGS ScienceBase doi:10.5066/P9APRBB8 (USGS data release, published 2023-05-23; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Grant, E.H.C., and Brand, A.B., 2023, Long-term effects of timber harvest on vernal pool
#   availability and occupancy of two obligate amphibians: U.S. Geological Survey data release.
# Data:   CVNWR_pool surveys.csv: 1,715 rows, one per pool visit, 108 vernal pools at Canaan Valley
#         National Wildlife Refuge, West Virginia, 2004-2016 (March to June, one to five visits a
#         year), with harvest treatment, whether the pool was dry, water temperature and pH (empty
#         when dry), maximum wet width, length and depth, and the counts of wood frog (RSYL) and
#         spotted salamander (AMAC) egg masses and larvae by the first and by the second observer.
#         One record (CVNWR32 I-9, 2016-03-25) is deposited twice, identically. ACS data.csv: plot
#         searches for pools (pools found per 50 x 50 m plot), a pool-density design, not an
#         amphibian survey. Landscape data.csv: estimated pool numbers and densities by treatment.
#         Asserted: dates parse, no counts missing, treatment constant within a pool, one record
#         per pool x date after the identical duplicate is dropped.
# Mapping: unit = pool, period = calendar year (2004-2016), occasion = visit (date order within the
#   year) x observer slot (two per visit: occasion = 2 * (visit - 1) + slot), occasionKind
#   [time, observer]; taxon = species x stage (E6 life stages counted separately at one survey):
#   RSYL_EM / AMAC_EM (egg masses) and RSYL_L / AMAC_L (larvae); y = that observer's count
#   (surveyEvidence sample_table: a row of the survey file is a visit, and both observers counted
#   every stage of both species at it). A dry pool is a visit, recorded with obs_pool_dry = 1: 65
#   wood frog egg masses were counted in dry pools, so its zeros are recorded counts. obs_visit,
#   obs_observer_slot, water temperature, pH and pool dimensions are obs_; unit_harvested from the
#   treatment. No coordinates are deposited.
# Not shipped: the duplicate record (identical); the plot searches (ACS) and landscape estimates
#   (pool density, a model of pool availability, not an amphibian observation).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "grant_2023_canaanvalley_amph_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/622b933ad34ec9f19eea4313?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
v <- fread(download_cached(fl[["CVNWR_pool surveys.csv"]], TABLE, filename = "CVNWR_pool surveys.csv"), check.names = FALSE)
cnt <- grep("^#", names(v), value = TRUE)
stopifnot(nrow(v) == 1715, length(cnt) == 8, !anyNA(v[, ..cnt]), all(unlist(v[, ..cnt]) >= 0),
          all(v$`Pool Dry` %in% c(TRUE, FALSE)), uniqueN(v$`Pool Name`) == 108,
          v[, uniqueN(Treatment), by = `Pool Name`][, all(V1 == 1)], all(v$Treatment %in% c("Harvested", "Unharvested")))
v[, date := as.IDate(`Survey Date`, format = "%m/%d/%Y")]
stopifnot(!anyNA(v$date), all(year(v$date) %in% 2004:2016))
dup <- duplicated(v); stopifnot(sum(dup) == 1, sum(duplicated(v[, .(`Pool Name`, date)])) == 1)
v <- v[!dup]
setorder(v, `Pool Name`, date)
v[, `:=`(yr = year(date), visit = seq_len(.N)), by = .(`Pool Name`, year(date))]
stopifnot(max(v$visit) == 5, sum(v[`Pool Dry` == TRUE, `#RSYL Eggmass_obs1`]) == 34)
m <- melt(v, id.vars = c("Pool Name", "Treatment", "date", "yr", "visit", "Pool Dry", "Water Temp_C", "pH", "Width_m", "Length_m", "Depth_cm"),
          measure.vars = cnt, variable.name = "col", value.name = "y")
m[, `:=`(sp = sub("^#(\\w+) .*", "\\1", col), stage = ifelse(grepl("Eggmass", col), "EM", "L"), slot = as.integer(sub(".*_obs", "", col)))]
long <- m[, .(unit = `Pool Name`, taxon = paste0(sp, "_", stage), y = as.integer(y), period = yr - 2003L,
              occasion = 2L * (visit - 1L) + slot, date = format(date),
              unit_harvested = as.integer(Treatment == "Harvested"),
              obs_visit = visit, obs_observer_slot = slot, obs_pool_dry = as.integer(`Pool Dry`),
              obs_water_temp_c = `Water Temp_C`, obs_ph = pH, obs_width_m = Width_m, obs_length_m = Length_m, obs_depth_cm = Depth_cm)]
stopifnot(nrow(long) == 1714 * 8, !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
taxa <- make_taxa(c("AMAC_EM", "AMAC_L", "RSYL_EM", "RSYL_L"),
                  c("Ambystoma maculatum", "Ambystoma maculatum", "Lithobates sylvaticus", "Lithobates sylvaticus"),
                  vernacularName = c("Spotted salamander", "Spotted salamander", "Wood frog", "Wood frog"),
                  lifeStage = c("egg", "larva", "egg", "larva"),
                  taxonRemarks = c("count of egg masses", "count of larvae", "count of egg masses", "count of larvae"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Wood frog and spotted salamander egg-mass and larval counts by two observers at 108 vernal pools, Canaan Valley NWR, West Virginia, 2004-2016",
  creator = "Grant, Evan H. Campbell; Brand, Adrianne B.",
  pubDate = "2023", doi = "10.5066/P9APRBB8", sourceURL = "https://doi.org/10.5066/P9APRBB8",
  citation = "Grant, E.H.C., and Brand, A.B., 2023, Long-term effects of timber harvest on vernal pool availability and occupancy of two obligate amphibians: U.S. Geological Survey data release, https://doi.org/10.5066/P9APRBB8.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Vernal pool surveys at Canaan Valley National Wildlife Refuge, West Virginia, 2004-2016, in harvested and unharvested forest. At each visit (one to five a year, March to June) two observers each counted wood frog and spotted salamander egg masses and larvae, and the pool's water temperature, pH, dimensions and whether it was dry were recorded.",
  samplingProtocol = "Repeated spring visits to vernal pools; at each visit two observers each searched the pool and counted egg masses and larvae of wood frogs and spotted salamanders.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "visits span late March to June, over which egg masses are laid and hatch and larvae develop; within a visit the two observers' counts are of the same pool at the same time (their independence is not stated)",
  occasionKind = c("time", "observer"), taxonInclusion = "target",
  geographicCoverage = list(description = "Canaan Valley National Wildlife Refuge, Tucker County, West Virginia, USA",
                            boundingBox = list(west = -79.4428, east = -79.3254, south = 39.0272, north = 39.1546)),
  temporalCoverage = "2004-03/2016-06",
  notShipped = list(duplicate_record = "CVNWR32 I-9 on 2016-03-25 deposited twice, identically; one copy kept",
                    plot_searches = "ACS data.csv: pools found per 50 x 50 m plot, a pool-availability survey, not an amphibian survey",
                    landscape_estimates = "Landscape data.csv: estimated pool numbers and densities, model-based estimates"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:13, year = 2004:2016),
                  script = "data/grant_2023_canaanvalley_amph_count.R")
stage_dict_row(TABLE,
  description = "Counts of wood frog and spotted salamander egg masses and larvae by each of two observers on 1,714 visits to 108 vernal pools at Canaan Valley National Wildlife Refuge, West Virginia, 2004-2016, with harvest treatment, pool dryness, water chemistry and pool size.",
  url = "https://doi.org/10.5066/P9APRBB8",
  reference = "Grant, E.H.C., and Brand, A.B. (2023). Long-term effects of timber harvest on vernal pool availability and occupancy of two obligate amphibians. U.S. Geological Survey data release.",
  doi_data = "10.5066/P9APRBB8", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "taxon = species x stage (egg masses, larvae); occasion = visit x observer slot.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Open N-mixture / dynamic occupancy (double observer)", sampling_protocol = "visual_encounter",
  design = "Multi-season (13 years x up to 5 visits x 2 observers)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Harvested vs unharvested forest pools; dry pools recorded as visits.")
