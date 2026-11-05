#!/usr/bin/env Rscript
# Table:  gelle_2026_mauritius_parakeet_ms
# Source: Dryad doi:10.5061/dryad.dz08kpsdk, version 453837 (version 2, published 2026-07-21),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record).
#         Gellé, A., Nicoll, M. A. C., Kettel, E., Pernetta, A., Gath, ..., Norris, K. &
#         Tollington, S. "Data from: Demographic responses to population recovery illustrated by
#         30-years of monitoring a once critically endangered parrot".
# Paper:  Gellé, A. et al. (2026). Demographic responses to population recovery illustrated by
#         30 years of monitoring a once critically endangered parrot. Journal of Applied Ecology
#         63, doi:10.1111/1365-2664.70523 (title checked on Crossref; not read: the Dryad methods
#         and README carry the design).
# Data:   two files.
#   README.md                          state codes and column list (read).
#   EP_encounter_history_multistate.csv 2,734 rows, one per known-age echo parakeet ringed in the
#                        nest; columns id (1..2734), 1994..2022 (one state per austral breeding
#                        season, September to March, labelled by its starting year in the
#                        deposit), cohort (year fledged, 1994-2021). States: PB = pre-breeder
#                        (never recorded breeding), B = breeder (positively identified as a
#                        parent at a monitored nest with at least one egg), NB = non-breeder
#                        (previously recorded breeding, not this season), 0 = not seen.
#                        Every history's first non-zero cell is PB in the cohort year: the
#                        ringing of the nestling (asserted). Dryad methods: encounters compiled
#                        from field observations, feeding observations, ringing and breeding
#                        data; sightings at supplementary feeding stations excluded by the
#                        authors; birds ringed as adults, translocated (151), taken into
#                        captivity (4), breeding before age 2 (2), and the 2022 cohort (120)
#                        were excluded before deposit.
#
# Mapping (standard E9 multi-state CJS, responseType state, unitKind individual):
#   unit = EP + id, taxon = ALEEQU, period = breeding season 1..29 (1994..2022, in __periods),
#   no occasion (one state per season, compiled by the authors from repeated nest checks and
#   sightings). y: 0 not seen, 1 pre-breeder (PB), 2 breeder (B), 3 non-breeder (NB); y_raw =
#   the deposited letter. unit_cohort = the deposited fledging year.
#   At-risk span (E4.4): ringed as nestlings, so each bird's rows begin in its cohort season
#   (the ringing, y = 1, obs_ringing = 1) and run to 2022; rings are colour combinations and the
#   deposit records no ring loss. The deposit's cells before the cohort year are all 0 and are
#   not rows (asserted).
#   Survey evidence: deposited_matrix (the population was monitored every season 1994-2022).
#   Coordinates: none in the deposit; the species is IUCN VU and confined to ~41 km2 of
#   south-west Mauritius, but nothing is coordinate-level.
#   Not shipped: nothing in the deposit is left out. The paper's population-size and covariate
#   series are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "gelle_2026_mauritius_parakeet_ms"
dir <- download_dryad("doi:10.5061/dryad.dz08kpsdk", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "453837"),
          setequal(list.files(dir), c("EP_encounter_history_multistate.csv", "README.md")))
d <- fread(file.path(dir, "EP_encounter_history_multistate.csv"), colClasses = "character")
years <- 1994:2022
stopifnot(identical(names(d), c("id", as.character(years), "cohort")), nrow(d) == 2734L,
          identical(d$id, as.character(1:2734)))
S <- as.matrix(d[, as.character(years), with = FALSE])
stopifnot(all(S %in% c("0", "PB", "B", "NB")),
          identical(as.integer(table(factor(S, c("0", "PB", "B", "NB")))), c(72213L, 3974L, 2893L, 206L)))
cohort <- as.integer(d$cohort); stopifnot(!anyNA(cohort), all(cohort %in% 1994:2021))
first <- apply(S, 1, function(r) which(r != "0")[1])
stopifnot(!anyNA(first), all(years[first] == cohort), all(S[cbind(seq_len(nrow(S)), first)] == "PB"))
# state logic: NB only after a B; PB never after a B
firstB <- apply(S, 1, function(r) { w <- which(r == "B"); if (length(w)) w[1] else NA_integer_ })
for (i in seq_len(nrow(S))) {
  nb <- which(S[i, ] == "NB"); pb <- which(S[i, ] == "PB")
  stopifnot(!length(nb) || (!is.na(firstB[i]) && min(nb) > firstB[i]),
            is.na(firstB[i]) || !length(pb) || max(pb) < firstB[i])
}
stopifnot(sum(rowSums(S != "0") > 1) == 995L)   # Dryad methods say 997 resighted after ringing; the deposit has 995

codes <- c(`0` = 0L, PB = 1L, B = 2L, NB = 3L)
Y <- matrix(codes[S], nrow(S)); YR <- S
Y[col(Y) < first] <- NA_integer_; YR[is.na(Y)] <- NA_character_
R <- matrix(0L, nrow(S), ncol(S)); R[cbind(seq_len(nrow(S)), first)] <- 1L
ids <- paste0("EP", sprintf("%04d", seq_len(nrow(S))))
long <- array_to_eco(Y, taxon = "ALEEQU", site_ids = ids, site_covs = data.frame(cohort = cohort),
                     period = seq_along(years), obs_covs = list(ringing = R), y_raw = YR)
long[, occasion := NULL]
stopifnot(nrow(long) == sum(!is.na(Y)), nrow(long) == sum(2023L - cohort), sum(long$obs_ringing) == 2734L,
          uniqueN(long$unit) == 2734L)

taxa <- make_taxa("ALEEQU", "Alexandrinus eques", vernacularName = "Echo parakeet",
                  lookupName = "Psittacula eques")
# GBIF's IUCN endpoint has no record for this key (returns NE, checked 2026-11-05); the IUCN
# category is VU (downlisted from EN in 2019; the Dryad abstract calls the species "vulnerable").
stopifnot(identical(iucn_category(taxa$taxonID, "Psittacula eques"), "NE"))
taxa[, taxon_iucnCategory := "VU"]
periods <- data.table(period = seq_along(years), season_start_year = years,
                      season = sprintf("%d/%02d", years, (years + 1L) %% 100L),
                      n_ringed = as.integer(tabulate(first, length(years))),
                      n_resighted = as.integer(colSums(!is.na(Y) & Y > 0 & R == 0)))

dataset <- list(
  title = "Annual multistate encounter histories (pre-breeder / breeder / non-breeder) of 2,734 echo parakeets ringed as nestlings in Mauritius, 1994-2022",
  creator = "Gellé, Adrien; Nicoll, Malcolm A. C.; Kettel, Esther; Pernetta, Angelo; Gath, Christopher; Groombridge, Jim J.; Henshaw, Sion; Jones, Carl G.; Ruhomaun, Kevin; Tatayah, Vikash; Norris, Ken; Tollington, Simon",
  pubDate = "2026", doi = "10.5061/dryad.dz08kpsdk", sourceURL = "https://doi.org/10.5061/dryad.dz08kpsdk",
  citation = "Gellé, A., Nicoll, M. A. C., Kettel, E., Pernetta, A., Gath, C., Groombridge, J. J., Henshaw, S., Jones, C. G., Ruhomaun, K., Tatayah, V., Norris, K., & Tollington, S. (2026). Data from: Demographic responses to population recovery illustrated by 30-years of monitoring a once critically endangered parrot [Dataset]. Dryad. https://doi.org/10.5061/dryad.dz08kpsdk",
  paperDOI = "10.1111/1365-2664.70523",
  abstract = "Echo parakeets (Alexandrinus eques, formerly Psittacula eques), endemic to Mauritius, recovered from fewer than 20 to over 500 birds during the study. Known-age birds ringed in the nest (1994-2021 cohorts) were encountered each breeding season through 2022 in one of three states; the paper fits multistate CJS models of age- and state-specific survival and breeding transitions.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Mauritian Wildlife Foundation biologists checked all known nest boxes and natural cavities several times each austral breeding season (September to March), identifying parents by unique colour-ring combinations and ringing nestlings before fledging; further sightings came from field and feeding observations. Encounters were summarised into one state per bird per season; sightings at supplementary feeding stations were excluded by the authors.",
  samplingProtocolCode = "resighting", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "period (one state per breeding season; survival and state transitions between seasons)",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none",
  stateCodes = list(`0` = "not seen",
                    `1` = "pre-breeder (y_raw PB): never recorded breeding; also the ringing of the nestling (obs_ringing = 1)",
                    `2` = "breeder (y_raw B): identified as a parent at a monitored nest with at least one egg laid",
                    `3` = "non-breeder (y_raw NB): previously recorded breeding, not breeding this season"),
  temporalCoverage = "1994/2023",
  geographicCoverage = "Black River Gorges and surrounding upland forest, south-west Mauritius (the species' range, about 41 km2)",
  notes = "Unit ids are the deposited row ids. Rows begin in each bird's cohort season (ringed as a nestling, E4.4): that row is the ringing (y = 1, obs_ringing = 1); unit_cohort is the deposited fledging year. Period labels are the starting year of the September-March season (season in __periods). 995 of 2,734 birds were seen after ringing (the Dryad methods say 997). The deposit is the authors' analysis set: birds ringed as adults, translocated, taken into captivity, breeding before age 2, and the 2022 cohort were removed before deposit, and encounters at supplementary feeding stations are excluded.",
  coordinatesCoarsened = NA,
  notShipped = list(none = "every deposited history is shipped; excluded birds and feeding-station sightings were removed by the authors before deposit"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/gelle_2026_mauritius_parakeet_ms.R")
stage_dict_row(TABLE,
  description = "Annual multistate encounter histories (pre-breeder / breeder / non-breeder) of 2,734 known-age echo parakeets ringed as nestlings in Mauritius (1994-2021 cohorts), one state per breeding season 1994-2022; rows from the ringing season.",
  url = "https://doi.org/10.5061/dryad.dz08kpsdk",
  reference = "Gellé, A., et al. (2026). Demographic responses to population recovery illustrated by 30 years of monitoring a once critically endangered parrot. Journal of Applied Ecology, 63.",
  doi_paper = "10.1111/1365-2664.70523", doi_data = "10.5061/dryad.dz08kpsdk",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Authors' analysis set (known-age wild birds only). Species IUCN VU; no coordinates in the deposit.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS capture-recapture (breeding state)",
  sampling_protocol = "resighting", design = "Multi-session (29 annual breeding seasons)",
  realm = "Terrestrial", country = "MUS", coordinates = "None in source",
  notes = "Parrot ringed as nestlings; rows from the ringing season; IUCN VU island endemic.")
