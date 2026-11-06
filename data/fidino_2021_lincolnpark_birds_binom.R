#!/usr/bin/env Rscript
# Table:  fidino_2021_lincolnpark_birds_binom
# Source: Dryad doi:10.5061/dryad.w3r2280rb (CC0 1.0, as shown on the Dryad page; published
#         2021-07-25). Fidino, M., Bender, J., Limbrick, K., Gallo, T. & Magle, S.B. Strolling
#         through a century: replicating historical bird surveys to explore 100 years of change
#         in an urban bird community.
# Paper:  Fidino, M. et al. (2022). The American Naturalist 199(2), doi:10.1086/717052. Bird walks
#         in Lincoln Park, Chicago, by Walter (1898-1903, from the book "Wild Birds in City
#         Parks"), Dreuth (1927-1932, field notes) and Fidino & Limbrick (2012-2015), each
#         recording the species seen on the day; the authors model the number of days each species
#         was seen per year out of the days walked (dryad_readme.pdf).
# Data:   days_seen_per_year.csv (species, year, daySeen, observer: the cleaned table, "probably
#         the primary dataset used for our analyses"); effort.csv (year, countOfDays: days walked);
#         species_codes.csv (4-letter code, common name, scientific name); raw Dreuth and Fidino
#         daily lists; arrival dates, species seen per day, life-history and EltonTraits tables,
#         Ward et al. (2018) change scores.
# Mapping (standard: binomial_count community, E9 core; ruling #34): unit = Lincoln Park (one
#   site walked by all three observers); taxon = the 4-letter code; period = year (16 years:
#   1898-1903, 1927-1932, 2012-2015) with period_year and period_observer (Walter / Dreuth /
#   Fidino); y = days seen; obs_trials = days walked (effort.csv); no occasion. Rows (E4): every
#   species in the table x every year walked. For Walter and Fidino the deposit lists every species
#   seen in the era for every year of it, zeros included; for Dreuth only years with sightings
#   (asserted). A species-year without a row was seen on 0 days (the walks recorded every species
#   seen). Survey evidence: effort_table.
#   Not shipped: the raw Dreuth and Fidino daily lists (uncleaned names with typos and pooled
#   entries; the cleaning is in the authors' Zenodo code, and Dreuth's 1927 raw dates (20) differ
#   from the 17 days in effort.csv); arrival dates and species per day (derived); trait tables
#   (external); Ward change scores (external). No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fidino_2021_lincolnpark_birds_binom"
dir <- download_dryad("10.5061/dryad.w3r2280rb", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
ds <- rf("days_seen_per_year\\.csv"); ef <- rf("effort\\.csv"); sc <- rf("species_codes\\.csv")
stopifnot(nrow(ds) == 2040, nrow(ef) == 16, identical(ef$year, c(1898:1903, 1927:1932, 2012:2015)), all(ds$year %in% ef$year),
          !anyDuplicated(ds[, .(species, year)]), all(ds$daySeen >= 0L))
# Walter and Fidino list each species seen in their era for every year of it (zeros explicit);
# Dreuth lists only species-years with daySeen > 0; every listed species was seen in its era
era <- ds[, .(N = .N, s = sum(daySeen)), by = .(observer, species)]
stopifnot(all(era$s > 0), all(era[observer == "Walter"]$N == 6L), all(era[observer == "Fidino"]$N == 4L),
          all(ds[observer == "Dreuth"]$daySeen > 0), all(ds[observer != "Dreuth" & daySeen == 0, .N] == 254L))
obs_of <- function(y) ifelse(y < 1910, "Walter", ifelse(y < 2000, "Dreuth", "Fidino"))
stopifnot(identical(ds$observer, obs_of(ds$year)))
sp <- sort(unique(ds$species)); stopifnot(length(sp) == 193)
i <- match(tolower(sp), tolower(sc$species)); stopifnot(!anyNA(i), !anyDuplicated(sc$SPEC[i]))
code <- setNames(sc$SPEC[i], sp)
grid <- CJ(species = sp, year = ef$year)
long <- merge(grid, ds[, .(species, year, daySeen)], by = c("species", "year"), all.x = TRUE)
long[is.na(daySeen), daySeen := 0L]
long <- merge(long, ef, by = "year")
stopifnot(all(long$daySeen <= long$countOfDays))
long <- long[, .(unit = "LINCOLN_PARK", taxon = unname(code[species]), period = match(year, ef$year), y = as.integer(daySeen), obs_trials = countOfDays)]
long <- order_eco(long)
stopifnot(nrow(long) == 193 * 16, sum(long$y) == sum(ds$daySeen))
periods <- data.table(period = 1:16, period_year = ef$year, period_observer = obs_of(ef$year))
taxa <- make_taxa(unname(code), sc$sciName[i], vernacularName = sp)
dataset <- list(
  title = "Days seen out of days walked for 193 bird species in Lincoln Park, Chicago, in 16 years across 1898-2015",
  creator = "Fidino, Mason; Bender, Jared; Limbrick, Kelvin; Gallo, Travis; Magle, Seth B.", pubDate = "2021",
  doi = "10.5061/dryad.w3r2280rb", sourceURL = "https://doi.org/10.5061/dryad.w3r2280rb",
  citation = "Fidino, M., Bender, J., Limbrick, K., Gallo, T., & Magle, S. B. (2021). Strolling through a century: replicating historical bird surveys to explore 100 years of change in an urban bird community [Dataset]. Dryad. https://doi.org/10.5061/dryad.w3r2280rb",
  paperDOI = "10.1086/717052",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "For each of 193 bird species and each survey year, the number of days the species was seen on bird walks in Lincoln Park, Chicago, out of the days walked: Walter (1898-1903), Dreuth (1927-1932) and Fidino and Limbrick (2012-2015, replicating the historical walks).",
  samplingProtocol = "Repeated bird walks through Lincoln Park recording every species seen each day; historical records from a published book (Walter) and field notes (Dreuth), modern walks replicating them; days seen per species per year.",
  samplingProtocolCode = "point_count", surveyEvidence = "effort_table",
  surveyEvidenceNote = "effort.csv gives the days walked each year; Walter and Fidino rows carry explicit zeros for the era's species; Dreuth rows only years with sightings; a species-year without a row was seen on none of the days walked.",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "one count per species-year (days seen of days walked, March-November walks)", occasionKind = "none",
  taxonInclusion = "recorded", geographicCoverage = "Lincoln Park, Chicago, Illinois, USA; no coordinates",
  temporalCoverage = "1898/2015",
  notShipped = list(raw_lists = "the raw Dreuth and Fidino daily lists (uncleaned names; cleaning in the authors' Zenodo code)",
                    derived = "arrival dates and species seen per day (derived)", external = "EltonTraits, life-history and Ward et al. change tables (external)"),
  notes = "One unit: the walks covered one park, so the table is a 193-species x 16-year series of detection frequencies, not a spatial design. Observer changes with the era (period_observer). Species names and codes follow the deposit's species_codes.csv (AOU 4-letter codes).")
ds2 <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fidino_2021_lincolnpark_birds_binom.R")
stage_dict_row(TABLE, description = "Days seen out of days walked for 193 bird species in Lincoln Park, Chicago, in 16 years across 1898-2015 (three observers, a century apart).",
  url = "https://doi.org/10.5061/dryad.w3r2280rb", reference = "Fidino, M., Bender, J., Limbrick, K., Gallo, T., & Magle, S. B. (2022). Strolling through a century: Replicating historical bird surveys to explore 100 years of change in an urban bird community. The American Naturalist, 199(2).",
  doi_paper = "10.1086/717052", doi_data = "10.5061/dryad.w3r2280rb", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Historical bird walks; one site.", source_via = "Dryad")
stage_tag_row(TABLE, ds2, taxon_group = "Birds", model_family = "Community occupancy (binomial counts)",
  sampling_protocol = "point_count", design = "Multi-season (16 years over a century)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Century-scale urban bird change.")
