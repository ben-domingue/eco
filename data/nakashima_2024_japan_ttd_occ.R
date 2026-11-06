#!/usr/bin/env Rscript
# Tables: nakashima_2024_kanagawa_nestpred_occ, nakashima_2024_yakumo_scavenger_occ
# Source: Dryad doi:10.5061/dryad.kkwh70sbn, version 308654 (published 2024-08-01), CC0 1.0 (asserted from the
#         Dryad metadata). Nakashima, Y. (2024). Data and code for implementing time-to-detection occupancy
#         model [Dataset]. Dryad. Raw files read from batch 37's cache (no Dryad request in batch 47).
# Paper:  Nakashima, Y., Hashizume, A. & Kanda, A. (2024). A statistical approach to assess interspecific
#         consumptive competition and functional redundancy in ephemeral resource uses using camera traps.
#         Ecology and Evolution 14, e70031. doi:10.1002/ece3.70031 (open access; read from Europe PMC
#         PMC11268935). Section 2.3.1 (Case 1): artificial cup nests with two quail eggs, about 2 m up a tree,
#         at least 300 m apart, in evergreen forest of the Futagoyama region, south-eastern Kanagawa, Japan,
#         April-July 2020, each watched by a camera trap (Browning Strike Force); five rounds of 7-10 nests,
#         32 nests in all (later rounds within 30 m of the earlier nests); the time until the eggs were first
#         preyed upon, by the invasive Formosan (Pallas's) squirrel Callosciurus erythraeus or the large-billed
#         crow Corvus macrorhynchos; a 14-day window. Section 2.3.2 (Case 2): 69 raccoon carcasses placed at
#         least 500 m apart in the Yakumo Study Forest, Hokkaido, 2016-2019 (12-23 a year), watched by camera
#         traps; time to the first visit of a red fox (Vulpes vulpes) or raccoon dog (Nyctereutes procyonoides)
#         (data of Hashizume et al. 2023); one carcass visited first by a crow is censored for both.
#         Paper, Table 2 and s.3.2: 37 carcasses first detected by foxes, 15 by raccoon dogs.
# Data:   README.md; Case_1_data.RData (data_list: N_station = 32, ttd = time to first predation or
#         censoring, days, at most 14; cens_a = 1 if censored for squirrels, cens_b for crows);
#         Case_2_data.RData (data_list: N_station = 69, ttd in days, cens_a red fox, cens_b raccoon dog; plus
#         the carcass wet-mass series N_survey = 279 measurements of N_carcass = 19 carcasses, ID_carcass,
#         measured_t, wet_mass, initial_mass, and gen_seq, a plotting grid). The README's Case 1 comment block
#         says cens_a/cens_b are red foxes / raccoon dogs (copied from Case 2); its table and the analysis code
#         (Species = Squirrel, Crow) say squirrels / crows, which is believed. No station has both species
#         uncensored: the first species to take the resource censors the other at that time (competing
#         risks); both censored = neither came before monitoring ended (or, once in Case 2, a crow came first).
#         Asserted: Case 1 15 stations first taken by squirrels, 5 by crows, 12 by neither, all of these at
#         ttd = 14 days; Case 2 38 by foxes (the paper says 37), 15 by raccoon dogs, 16 by neither.
# Mapping (time to detection, ruling 2026-11-06; single survey per station, replicated within the survey by
#   the time to detection, Intake "Replication"): one table per case (two studies, resources, places).
#   unit = station (the nest or carcass, numbered in deposit order), taxon = the two consumers
#   (taxonInclusion target), y = 1 if the species was the first to take the resource (cens = 0), else 0;
#   obs_ttd_days = ttd as deposited (the time of first detection, or for y = 0 the time the survey of that
#   resource ended: the rival took it, a crow took it, or monitoring stopped), obs_ttd_censored = cens. The
#   ruling sets a censored time to the survey length; here the survey of a resource ends when it is taken,
#   so its length is the deposited censoring time. No occasion, no period (Case 1's five rounds and Case 2's
#   four years are not deposited per station). surveyEvidence = sample_table: N_station rows, one per
#   station monitored. No coordinates, no dates.
# Not shipped: Case 2's carcass wet-mass series (a measurement of the resource, not a detection; its 19
#   carcass ids are not keyed to the 69 stations) and gen_seq (a plotting grid); the Stan and R code.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/nakashima_2024_japan_ttd_occ.R"; CACHE <- "nakashima_2024_japan_ttd_occ"
DOI <- "10.5061/dryad.kkwh70sbn"
dir <- download_dryad(DOI, CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "308654",
          setequal(list.files(dir), c("README.md", "Case_1_data.RData", "Case_2_data.RData")))
ld <- function(f) { e <- new.env(); load(file.path(dir, f), e); stopifnot(identical(ls(e), "data_list")); e$data_list }
c1 <- ld("Case_1_data.RData"); c2 <- ld("Case_2_data.RData")
chk <- function(d, n) {
  stopifnot(d$N_station == n, length(d$ttd) == n, length(d$cens_a) == n, length(d$cens_b) == n,
            all(d$cens_a %in% 0:1), all(d$cens_b %in% 0:1), !any(d$cens_a == 0 & d$cens_b == 0), all(d$ttd > 0))
}
chk(c1, 32L); chk(c2, 69L)
stopifnot(sum(c1$cens_a == 0) == 15L, sum(c1$cens_b == 0) == 5L, sum(c1$cens_a + c1$cens_b == 2) == 12L,
          all(c1$ttd[c1$cens_a + c1$cens_b == 2] == 14), max(c1$ttd) == 14,
          sum(c2$cens_a == 0) == 38L, sum(c2$cens_b == 0) == 15L, sum(c2$cens_a + c2$cens_b == 2) == 16L,
          c2$N_survey == 279L, c2$N_carcass == 19L)

CIT <- "Nakashima, Y. (2024). Data and code for implementing time-to-detection occupancy model [Dataset]. Dryad. https://doi.org/10.5061/dryad.kkwh70sbn"
REF <- "Nakashima, Y., Hashizume, A. & Kanda, A. (2024). A statistical approach to assess interspecific consumptive competition and functional redundancy in ephemeral resource uses using camera traps. Ecology and Evolution 14, e70031. https://doi.org/10.1002/ece3.70031"
build <- function(d, codes, prefix) {
  st <- data.table(unit = sprintf("%s%02d", prefix, seq_len(d$N_station)), ttd = d$ttd, ca = d$cens_a, cb = d$cens_b)
  long <- rbind(st[, .(unit, taxon = codes[1], y = 1L - as.integer(ca), obs_ttd_days = ttd, obs_ttd_censored = as.integer(ca))],
                st[, .(unit, taxon = codes[2], y = 1L - as.integer(cb), obs_ttd_days = ttd, obs_ttd_censored = as.integer(cb))])
  order_eco(long)
}
cases <- list(
  list(table = "nakashima_2024_kanagawa_nestpred_occ", d = c1, prefix = "nest",
       codes = c("CALERY", "CORMAC"), sci = c("Callosciurus erythraeus", "Corvus macrorhynchos"),
       vern = c("Pallas's squirrel (Formosan squirrel)", "Large-billed crow"),
       title = "Time to first predation of 32 camera-monitored artificial nests by the invasive Pallas's squirrel and the large-billed crow, Kanagawa, Japan, 2020",
       abstract = "Artificial cup nests baited with two quail eggs were placed about 2 m up trees in evergreen forest in the Futagoyama region, south-eastern Kanagawa, Japan, in five rounds of 7-10 nests between April and July 2020, and watched by camera traps. The time until the eggs were first taken records which predator came first, the invasive Pallas's (Formosan) squirrel or the native large-billed crow; the first predator censors the other. The authors fitted a two-species time-to-detection occupancy model to estimate the squirrels' net impact on nest success.",
       protocol = "Artificial cup nests (about 10 cm across, 6 cm deep) with two quail eggs, about 2 m up a tree, at least 300 m apart, each watched by a camera trap (Browning Strike Force) for up to 14 days; five rounds of 7-10 nests, April-July 2020; the time until the eggs were first preyed upon and by which species.",
       geo = "Futagoyama region, south-eastern Kanagawa Prefecture, Japan (no coordinates deposited)", time = "2020-04/2020-07",
       group = "Mammals", realm = "Terrestrial", design = "Single-season (one survey per nest, time to detection, competing predators)",
       extra_notes = "Stations are the 32 nest locations of five rounds (rounds not deposited per nest). Censoring is at the nest's 14-day window or at the time the other predator took the eggs (cens_a squirrels, cens_b crows; the README's comment block, which names red foxes and raccoon dogs, is copied from Case 2)."),
  list(table = "nakashima_2024_yakumo_scavenger_occ", d = c2, prefix = "carcass",
       codes = c("VULVUL", "NYCPRO"), sci = c("Vulpes vulpes", "Nyctereutes procyonoides"),
       vern = c("Red fox", "Raccoon dog"),
       title = "Time to first visit of red foxes and raccoon dogs at 69 camera-monitored raccoon carcasses, Yakumo, Hokkaido, Japan, 2016-2019",
       abstract = "Raccoon carcasses were placed at least 500 m apart in the Yakumo Study Forest, Hokkaido, Japan, 12-23 a year from 2016 to 2019, and watched by camera traps. The time to the first visit records which scavenger came first, the red fox or the raccoon dog; the first visitor censors the other. The authors fitted a two-species time-to-detection occupancy model to estimate the competition between the two scavengers for carcasses.",
       protocol = "Raccoon carcasses placed at least 500 m apart in forest, each watched by a camera trap until the first visit of a red fox or raccoon dog or the end of monitoring; 12-23 carcasses a year, 2016-2019 (Hashizume et al. 2023).",
       geo = "Yakumo Study Forest, Hokkaido, Japan (no coordinates deposited)", time = "2016/2019",
       group = "Mammals", realm = "Terrestrial", design = "Single-season (one survey per carcass, time to detection, competing scavengers)",
       extra_notes = "Stations are the 69 carcasses of 2016-2019 pooled (years not deposited per carcass). Censoring is at the end of monitoring or at the time the other scavenger came (one carcass visited first by a crow is censored for both, paper s.2.3.2). The deposit has 38 carcasses first visited by foxes; the paper reports 37. Overlaps the data of Hashizume et al. (2023), which the paper reuses.")
)
for (cs in cases) {
  long <- build(cs$d, cs$codes, cs$prefix)
  n <- cs$d$N_station
  stopifnot(nrow(long) == 2L * n, sum(long$y) == sum(cs$d$cens_a == 0) + sum(cs$d$cens_b == 0),
            all(long[, sum(y), by = unit]$V1 <= 1L))
  taxa <- make_taxa(cs$codes, cs$sci, vernacularName = cs$vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  print(taxa[, .(taxon, scientificName, gbifMatchType, taxon_iucnCategory)])
  stopifnot(all(taxa$taxon_iucnCategory %in% c("LC", "NE", "DD", "NT")))
  dataset <- list(
    title = cs$title, creator = "Nakashima, Yoshihiro", pubDate = "2024", doi = DOI, sourceURL = paste0("https://doi.org/", DOI),
    citation = CIT, paperDOI = "10.1002/ece3.70031",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = cs$abstract, samplingProtocol = cs$protocol, samplingProtocolCode = "camera_trap",
    surveyEvidence = "sample_table", responseType = "detection", unitKind = "site", closure = "none",
    closureNote = "One survey per station (no occasion); the survey ends when the resource is taken or monitoring stops. Replicated within the survey by the time to detection (ruling 2026-11-06).",
    occasionKind = "none", taxonInclusion = "target",
    geographicCoverage = cs$geo, temporalCoverage = cs$time,
    covariateNote = "obs_ttd_days: days from placement to the species' first take (y = 1), or to the end of the survey of that resource (y = 0: the other species took it first, or monitoring ended). obs_ttd_censored: 1 where the time is censored (y = 0), 0 where it is the species' detection time.",
    notShipped = list(code = "the authors' Stan and R code",
                      wet_mass = if (cs$prefix == "carcass") "the carcass wet-mass series (279 measurements of 19 carcasses; a measurement of the resource, its carcass ids not keyed to the stations) and gen_seq (a plotting grid)" else NULL),
    notes = paste("Time to detection (ruling 2026-11-06): y = 1 for the species that took the resource first; the other species is censored at that time (competing risks), so its obs_ttd_days is the time the survey of that resource ended rather than a fixed survey length.", cs$extra_notes))
  dataset$notShipped <- Filter(Negate(is.null), dataset$notShipped)
  ds <- write_table(long, cs$table, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(cs$table,
    description = sprintf("%s; detection and time to first detection of the two species per station, censored by the rival.", sub(",[^,]*$", "", cs$title)),
    url = paste0("https://doi.org/", DOI), reference = REF, doi_paper = "10.1002/ece3.70031", doi_data = DOI,
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Time-to-detection with competing-risk censoring (obs_ttd_days, obs_ttd_censored); read from batch 37's cache.", source_via = "Dryad")
  stage_tag_row(cs$table, ds, taxon_group = cs$group, model_family = "Single-season occupancy (time to detection)",
    sampling_protocol = "camera_trap", design = cs$design, realm = cs$realm, country = "JPN", coordinates = "None in source",
    notes = "Ephemeral resources watched by cameras; the first species to take a resource censors the other.")
}
