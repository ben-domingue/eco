#!/usr/bin/env Rscript
# Table:  schorr_2021_yampa_mylu_rd
# Source: Dryad, doi:10.5061/dryad.sj3tx964r, version 252537 (version 5, published 2022-11-18), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Schorr, R. A. & Siemers, J. L.
# Paper:  Schorr, R. A. & Siemers, J. L. (2021). Population dynamics of little brown bats (Myotis lucifugus) at
#         summer roosts: apparent survival, fidelity, abundance, and the influence of winter conditions. Ecology
#         and Evolution 11, doi:10.1002/ece3.7573. The design below is from the Dryad methods (the paper's
#         methods): two roosts in the Yampa Valley, Colorado (house roost at Rehder Ranch, barn roost at Carpenter
#         Ranch); bats caught with harp traps and mist nets in early summer (June) and late summer (late July /
#         early August) 2014-2018 (no late-summer 2017 capture at the house roost) and PIT-tagged; re-encounters
#         from PIT antennas (house roost from summer 2015, down for weeks in late 2015 and early 2016; barn readers
#         changed in 2015) and handheld readers; histories in weeks; Huggins robust design with two closed
#         sessions a year (early summer, late summer).
# Data:   MYLU_robust_2014-2018_Dryad.txt: a MARK input file; header comments say the 49 characters are weeks:
#           2014 (dummy01-02, 03-05), 2015 (06-08, 09-12), 2016 (13-20, 21-24), 2017 (25-31, 32-36),
#           2018 (37-44, 45-49), with character 1 a column of zeros added so the first primary has two
#           secondaries ('set p1 = 0'); 8 groups CarpAF, CarpAM, CarpJF, CarpJM, RehdAF, RehdAM, RehdJF, RehdJM
#           (roost x age at marking x sex, one-hot); six body-condition covariates. 1,741 bats.
#           A further header line gives secondaries per session as 2,3,3,3,8,4,6,4,8,6 (sum 47), which does not
#           match the 49-character histories; the character ranges above (sum 49) are used and asserted.
#         NCEI_NOAA_monthly_weather2013-2019_Dryad.txt: monthly NOAA station weather 2013-2019.
#         README_Dryad.txt.
# Mapping (robust design, individual units): unit = PIT tag, taxon = MYOLUC, cluster_id = roost (carpenter_barn /
#   rehder_house), period = closed session 1..10 (early and late summer of each year), occasion = week within the
#   session, y = captured or detected that week. The dummy character 1 is dropped (all zeros, asserted), so
#   session 1 has one occasion. unit_sex, unit_age_at_marking (adult / juvenile).
#   Survey set (inferred, ruling 2026-11-06): the deposit does not say in which weeks each roost was monitored
#   (antennas were installed, moved and down at different times), so a roost-week is a survey iff any bat of that
#   roost was captured or detected there that week; roost-weeks with no detection of any bat are absent.
#   At-risk span (E4.4): bats marked as adults (wild, unknown age) are at risk from the first session; bats marked
#   as juveniles (young of the year) from the session of their first encounter. Within the span, every surveyed
#   week of the bat's roost is a row.
# Not shipped: the six body-condition covariates (mean-filled for unweighed bats in the deposit, ruling
#   2026-11-06); the monthly weather file (station-month records, not tied to the sessions by the deposit);
#   model estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "schorr_2021_yampa_mylu_rd"

dir <- download_dryad("10.5061/dryad.sj3tx964r", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 3)
ln <- readLines(file.path(dir, "MYLU_robust_2014-2018_Dryad.txt"), warn = FALSE)
stopifnot(length(ln) == 1749L, any(grepl("2014 (dummy01-02,03-05), 2015 (06-08, 09-12), 2016 (13-20, 21-24), 2017(25-31,32-36), 2018(37-44, 45-49)", ln, fixed = TRUE)))
dl <- ln[grepl("^/\\*\t[0-9]+\t\\*/", ln)]
stopifnot(length(dl) == 1741L)
f <- tstrsplit(dl, "\t")
d <- data.table(tag = f[[2]], h = f[[4]])
grp <- sapply(5:12, function(j) as.integer(f[[j]]))
colnames(grp) <- c("CAF", "CAM", "CJF", "CJM", "RAF", "RAM", "RJF", "RJM")
stopifnot(!anyDuplicated(d$tag), all(nchar(d$h) == 49L), all(grepl("^[01]+$", d$h)), all(substr(d$h, 1, 1) == "0"),
          all(rowSums(grp) == 1L))
g <- colnames(grp)[max.col(grp)]
d[, `:=`(roost = ifelse(substr(g, 1, 1) == "C", "carpenter_barn", "rehder_house"),
         age = ifelse(substr(g, 2, 2) == "A", "adult", "juvenile"), sex = ifelse(substr(g, 3, 3) == "F", "F", "M"))]
stopifnot(all(grepl("1", substr(d$h, 2, 49))))

# sessions: character ranges from the header (character 1 is the dummy and is dropped)
rng <- list(2, 3:5, 6:8, 9:12, 13:20, 21:24, 25:31, 32:36, 37:44, 45:49)
rng <- lapply(rng, as.integer)
stopifnot(sum(lengths(rng)) == 48L, identical(unlist(rng), 2:49))
pos <- data.table(char = unlist(rng), period = rep(seq_along(rng), lengths(rng)))
pos[, occasion := seq_len(.N), by = period]

H <- do.call(rbind, strsplit(substr(d$h, 2, 49), ""))
storage.mode(H) <- "integer"
full <- data.table(unit = rep(d$tag, 48), roost = rep(d$roost, 48), char = rep(2:49, each = nrow(d)), y = as.vector(H))
full <- merge(full, pos, by = "char")
# inferred survey set: a roost-week is a survey iff any bat of that roost was encountered there
surv <- full[, .(any = max(y)), by = .(roost, char)][any == 1L]
cat(sprintf("  roost-weeks with a detection: %d of %d (carpenter %d, rehder %d)\n", nrow(surv), 2L * 48L,
            surv[roost == "carpenter_barn", .N], surv[roost == "rehder_house", .N]))
full <- full[surv[, .(roost, char)], on = .(roost, char), nomatch = NULL]
# at-risk span: adults from session 1, juveniles from the session of first encounter
first <- full[y == 1L, .(first_period = min(period)), by = unit]
d <- merge(d, first, by.x = "tag", by.y = "unit")
d[, start := ifelse(age == "adult", 1L, first_period)]
full <- merge(full, d[, .(unit = tag, start, unit_sex = sex, unit_age_at_marking = age)], by = "unit")
full <- full[period >= start]
stopifnot(sum(full$y) == sum(H), uniqueN(full$unit) == 1741L)
long <- full[, .(unit, taxon = "MYOLUC", y, period, occasion, cluster_id = roost, unit_sex, unit_age_at_marking)]
long <- order_eco(long)
cat(sprintf("  %d rows, %d bats, %d encounters\n", nrow(long), uniqueN(long$unit), sum(long$y)))

taxa <- make_taxa("MYOLUC", "Myotis lucifugus", vernacularName = "Little brown bat")
periods <- data.table(period = 1:10, year = rep(2014:2018, each = 2), season = rep(c("early_summer", "late_summer"), 5),
                      first_char = sapply(rng, min), last_char = sapply(rng, max), n_weeks = lengths(rng),
                      tagging_week = c(201424L, 201433L, 201524L, 201532L, 201625L, 201633L, 201724L, 201731L, 201823L, 201831L))
periods[period == 1L, n_weeks := 1L]

dataset <- list(
  title = "Robust-design PIT-tag capture and antenna histories of 1,741 little brown bats at two summer roosts, Yampa Valley, Colorado, 2014-2018",
  creator = "Schorr, Robert A.; Siemers, Jeremy L.", pubDate = "2022",
  doi = "10.5061/dryad.sj3tx964r", sourceURL = "https://doi.org/10.5061/dryad.sj3tx964r",
  citation = "Schorr, R. A., & Siemers, J. L. (2022). Population dynamics of little brown bats (Myotis lucifugus) at summer roosts: apparent survival, fidelity, abundance, and the influence of winter conditions [Dataset]. Dryad. https://doi.org/10.5061/dryad.sj3tx964r",
  paperDOI = "10.1002/ece3.7573",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Little brown bats PIT-tagged at a house roost (Rehder Ranch) and a barn roost (Carpenter Ranch) in the Yampa Valley, northwest Colorado, in early and late summer 2014-2018, and re-encountered by capture, PIT antennas at the roost entrances and handheld readers. Weekly histories in two closed sessions per year (early summer, late summer), fitted by the authors with a Huggins robust design to estimate survival, fidelity and abundance.",
  samplingProtocol = "Harp traps and mist nets at the roosts twice a summer, PIT tags; continuous PIT antennas at the roost entrances (house roost from summer 2015) and handheld reader scans; an encounter is a capture or detection in a week of the closed sessions the authors defined (from the week more than 30 bats arrived to the week after the June capture; from the July/August capture to the week fewer than 30 bats remained).",
  samplingProtocolCode = "pit_tag_antenna", surveyEvidence = "inferred",
  surveyEvidenceNote = "The deposit does not record in which weeks each roost's antenna or readers operated. A roost-week is a survey iff any bat of that roost was captured or detected there that week (ruling 2026-11-06); roost-weeks with no detection of any bat are absent, including any operated week in which nothing was detected.",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "the authors' closed sessions (early and late summer each year); weeks are the occasions within a session",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Rehder Ranch near Catamount Lake (about 17 km S of Steamboat Springs) and Carpenter Ranch (about 7 km E of Hayden), Yampa Valley, Routt County, Colorado, USA",
  temporalCoverage = "2014/2018",
  covariateNote = "cluster_id: the bat's roost (one roost per bat in the deposit's groups). unit_age_at_marking: adult or juvenile (young of the year) when first marked; unit_sex.",
  notShipped = list(body_condition = "six body-condition covariates (forearm / mass), mean-filled for bats not weighed",
                    weather = "NCEI_NOAA_monthly_weather2013-2019_Dryad.txt: monthly NOAA station weather, not tied to sessions by the deposit",
                    dummy_column = "character 1 of each history, a column of zeros the authors added to give session 1 two secondaries",
                    model_output = "survival, fidelity and abundance estimates"),
  notes = "Session 1 (early summer 2014) has one real week. The header line giving secondaries per session (2,3,3,3,8,4,6,4,8,6) does not sum to the 49 characters; the character ranges of the other header line are used. Juveniles have rows from the session of their first encounter (marked as young of the year), adults from session 1.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/schorr_2021_yampa_mylu_rd.R")
stage_dict_row(TABLE,
  description = "Weekly capture and PIT-antenna encounter histories of 1,741 little brown bats at two summer roosts in the Yampa Valley, Colorado, in early- and late-summer closed sessions, 2014-2018 (robust design).",
  url = "https://doi.org/10.5061/dryad.sj3tx964r",
  reference = "Schorr, R. A., & Siemers, J. L. (2021). Population dynamics of little brown bats (Myotis lucifugus) at summer roosts: apparent survival, fidelity, abundance, and the influence of winter conditions. Ecology and Evolution, 11. https://doi.org/10.1002/ece3.7573",
  doi_paper = "10.1002/ece3.7573", doi_data = "10.5061/dryad.sj3tx964r",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Robust design; survey set inferred (a roost-week with any detection); mean-filled body condition not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture",
  sampling_protocol = "pit_tag_antenna", design = "Robust design (10 closed sessions, 2014-2018; weekly occasions; 2 roosts)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "PIT-tag antennas at maternity roosts; survey set inferred from detections.")
