#!/usr/bin/env Rscript
# Tables: green_2018_ncal_mesocarn_dynocc, green_2018_ncal_fisher_scr
# Source: Dryad doi:10.5061/dryad.qb8m4 (CC0 1.0, as shown on the Dryad page; published
#         2018-12-01). Green, D.S., Matthews, S.M., Swiers, R.C., Callas, R.L., Yaeger, J.S.,
#         Farber, S.L., Schwartz, M.K. & Powell, R.A. Data from: Dynamic occupancy modeling
#         reveals a hierarchy of competition among fishers, grey foxes, and ringtails.
# Paper:  Green, D.S. et al. (2018). Journal of Animal Ecology 87(3), 813-824,
#         doi:10.1111/1365-2656.12791. 100 paired sites in northwestern California monitored
#         each autumn: track plates for fisher, grey fox and ringtail (dynamic occupancy with
#         interactions) and hair snares for genetic spatial capture-recapture of fishers, before
#         and after nine fishers were removed for translocation (abstract).
# Data:   GreenEtAl_JAE.zip: TrackPlates.csv (1,473 rows, 1,472 plate collections: Site, DateCollected, Day,
#         Month, Year 2007-2013, PEPE / URCI / BAAS = fisher / grey fox / ringtail tracks 0/1;
#         one exact duplicate row, collapsed); SiteVisits.csv (3,475 hair-snare checks: Site,
#         date, Time, Surveyor, 2006-2013); GeneticSamples.csv (540 fisher hair samples: date,
#         Site, Sample, GENID (138 individuals), Sex; every sample falls on a recorded visit,
#         asserted); SiteLocations.csv (100 sites, UTM_E / UTM_N, zone not named; the values fit
#         UTM zone 10N). No README.
# Mapping (standard): (1) green_2018_ncal_mesocarn_dynocc, dynamic community occupancy (E9
#   core): unit = Site; taxon = PEKPEN, UROCIN, BASAST; period = year 2007-2013 (__periods);
#   occasion = plate collection k within the site-year in date order; date = collection date;
#   y = tracks on the plate. Survey evidence: row_presence (a row per plate collection).
#   (2) green_2018_ncal_fisher_scr, SCR (E9 experimental; binomial observation as in
#   gardner_2018_nagarahole_tiger_oscr, because hair-snare checks fall on different days at
#   different sites): unit = GENID; trap = Site; period = year 2006-2013; y = number of checks
#   of the snare in that year with a sample of the fisher; obs_trials = checks made
#   (SiteVisits; effortColumn). Every fisher carries a row for every snare checked in every
#   year (full rectangle; fishers removed for translocation are not marked in the deposit).
#   unit_sex. __traps: site UTM as deposited. Coordinates: fisher, grey fox and ringtail are
#   IUCN LC and this northern-California population is not the ESA-listed southern Sierra DPS:
#   as published.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/green_2018_ncal_mesocarnivores.R"
dir <- download_dryad("10.5061/dryad.qb8m4", "green_2018_ncal_mesocarnivores")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^GreenEtAl_JAE\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "GreenEtAl_JAE")
tp <- fread(file.path(b, "TrackPlates.csv")); sv <- fread(file.path(b, "SiteVisits.csv"))
gs <- fread(file.path(b, "GeneticSamples.csv")); sl <- fread(file.path(b, "SiteLocations.csv"))
for (x in list(tp, sv, gs)) x[, dt := as.IDate(sprintf("%d-%02d-%02d", Year, Month, Day))]
stopifnot(nrow(tp) == 1473, sum(duplicated(tp)) == 1, nrow(sl) == 100, !anyDuplicated(sl$Site), all(tp$Site %in% sl$Site),
          all(as.matrix(tp[, .(PEPE, URCI, BAAS)]) %in% 0:1), nrow(sv) == 3475, !anyDuplicated(sv[, .(Site, dt)]),
          nrow(gs) == 540, uniqueN(gs$GENID) == 138, gs[, uniqueN(Sex), by = GENID][, all(V1 == 1)],
          all(paste(gs$Site, gs$dt) %in% paste(sv$Site, sv$dt)))
tp <- unique(tp)
setorder(tp, Site, dt); tp[, occasion := seq_len(.N), by = .(Site, Year)]
YT <- 2007:2013; stopifnot(setequal(unique(tp$Year), YT))
l1 <- melt(tp[, .(unit = Site, period = match(Year, YT), occasion, date = format(dt), PEKPEN = PEPE, UROCIN = URCI, BASAST = BAAS)],
           measure.vars = c("PEKPEN", "UROCIN", "BASAST"), variable.name = "taxon", value.name = "y", variable.factor = FALSE)
l1[, y := as.integer(y)]; l1 <- order_eco(l1)
stopifnot(nrow(l1) == 1472 * 3)
taxa3 <- make_taxa(c("PEKPEN", "UROCIN", "BASAST"), c("Pekania pennanti", "Urocyon cinereoargenteus", "Bassariscus astutus"),
                   vernacularName = c("Fisher", "Grey fox", "Ringtail"))
base <- list(
  creator = "Green, David S.; Matthews, Sean M.; Swiers, Robert C.; Callas, Richard L.; Yaeger, J. Scott; Farber, Stuart L.; Schwartz, Michael K.; Powell, Roger A.",
  pubDate = "2018", doi = "10.5061/dryad.qb8m4", sourceURL = "https://doi.org/10.5061/dryad.qb8m4",
  citation = "Green, D. S. et al. (2018). Data from: Dynamic occupancy modeling reveals a hierarchy of competition among fishers, grey foxes, and ringtails [Dataset]. Dryad. https://doi.org/10.5061/dryad.qb8m4",
  paperDOI = "10.1111/1365-2656.12791",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  geographicCoverage = "100 paired survey sites in northwestern California, USA (site coordinates in UTM, zone not named)")
ref <- "Green, D. S. et al. (2018). Dynamic occupancy modeling reveals a hierarchy of competition among fishers, grey foxes, and ringtails. Journal of Animal Ecology, 87(3), 813-824."
ds <- write_table(l1, "green_2018_ncal_mesocarn_dynocc", c(base, list(
  title = "Track-plate detections of fisher, grey fox and ringtail at 100 sites in northwestern California, autumn 2007-2013",
  abstract = "Detection/non-detection of fisher (Pekania pennanti), grey fox (Urocyon cinereoargenteus) and ringtail (Bassariscus astutus) on baited track plates collected one to six times each autumn at 100 sites in northwestern California, 2007-2013: the input of the authors' dynamic occupancy model with species interactions.",
  samplingProtocol = "Baited enclosed track plates at fixed paired sites, checked and collected repeatedly each autumn (September-December); tracks identified to species.",
  samplingProtocolCode = "track_plate", surveyEvidence = "row_presence", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "closed within an autumn season, open between years (dynamic occupancy)", occasionKind = "time", taxonInclusion = "target",
  temporalCoverage = "2007-09/2013-12",
  notShipped = list(duplicate = "one exact duplicate plate row (site 40A, 7 October 2013)"),
  notes = "occasion is the k-th plate collection of the site-year in date order (1-6). The fisher hair-snare SCR from the same sites is green_2018_ncal_fisher_scr.")),
  taxa = taxa3, periods = data.table(period = seq_along(YT), period_year = YT), script = SCRIPT)
stage_dict_row("green_2018_ncal_mesocarn_dynocc", description = "Track-plate detections of fisher, grey fox and ringtail at 100 sites in northwestern California, autumn 2007-2013.",
  url = "https://doi.org/10.5061/dryad.qb8m4", reference = ref, doi_paper = "10.1111/1365-2656.12791", doi_data = "10.5061/dryad.qb8m4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "Dynamic co-occurrence of three mesocarnivores.", source_via = "Dryad")
stage_tag_row("green_2018_ncal_mesocarn_dynocc", ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy (interactions)",
  sampling_protocol = "track_plate", design = "Multi-season (7 autumns, 1-6 plate collections)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Track plates; fisher, grey fox, ringtail.")

# --- fisher genetic SCR ------------------------------------------------------------------------
YS <- 2006:2013
eff <- sv[, .(k = .N), by = .(Site, Year)]
cap <- unique(gs[, .(GENID, Site, Year, dt)])[, .(y = .N), by = .(GENID, Site, Year)]
l2 <- merge(CJ(GENID = sort(unique(gs$GENID)), i = seq_len(nrow(eff)))[, c(.(GENID = GENID), eff[i])], cap,
            by = c("GENID", "Site", "Year"), all.x = TRUE)[is.na(y), y := 0L]
l2 <- merge(l2, unique(gs[, .(GENID, unit_sex = Sex)]), by = "GENID")
l2 <- order_eco(l2[, .(unit = GENID, taxon = "PEKPEN", y = as.integer(y), trap = Site, period = match(Year, YS), obs_trials = as.integer(k), unit_sex)])
stopifnot(nrow(l2) == 138 * nrow(eff), sum(l2$y) == nrow(unique(gs[, .(GENID, Site, dt)])), all(l2$y <= l2$obs_trials), setequal(unique(sv$Year), YS))
traps <- sl[, .(trap = Site, x = UTM_E, y = UTM_N)]
ds2 <- write_table(l2, "green_2018_ncal_fisher_scr", c(base, list(
  title = "Hair-snare genetic spatial capture-recapture of 138 fishers at 100 sites in northwestern California, 2006-2013",
  abstract = "Fisher (Pekania pennanti) individuals identified from hair samples at 100 hair-snare sites in northwestern California, checked three to seven times each autumn 2006-2013: one row per fisher x snare x year the snare was checked, y = checks with a sample of that fisher, obs_trials = checks made, with sex and snare coordinates.",
  samplingProtocol = "Hair snares at 100 fixed sites checked repeatedly each autumn (3-7 checks per site-year); hair genotyped to individual and sex.",
  samplingProtocolCode = "noninvasive_genetic", surveyEvidence = "effort_table",
  surveyEvidenceNote = "SiteVisits.csv lists every snare check (3,475); a snare-year is surveyed with obs_trials = its number of checks. Checks fall on different days at different snares, so the table is at the snare-year level (binomial count), not by check.",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "individual",
  closure = "none", closureNote = "no occasion column; closed within an autumn, open between the eight years (the authors' multi-session SCR)", occasionKind = "none",
  taxonInclusion = "single", crs = "UTM as deposited, zone not named (values consistent with UTM zone 10N)", temporalCoverage = "2006-09/2013-12",
  coordinatesCoarsened = list(value = FALSE, method = "as published: fisher is IUCN LC and this population is not the ESA-listed southern Sierra Nevada DPS"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; binomial observation per snare-year (checks are not aligned across snares).",
  notShipped = list(sample_ids = "individual hair-sample ids and check times / surveyors (several samples of one fisher at one check count once)"),
  notes = "Fishers removed for translocation are not flagged in the deposit; every fisher has rows in all eight years. The track-plate occupancy data from the same sites are green_2018_ncal_mesocarn_dynocc.")),
  taxa = make_taxa("PEKPEN", "Pekania pennanti", vernacularName = "Fisher"), periods = data.table(period = seq_along(YS), period_year = YS), traps = traps, script = SCRIPT)
stage_dict_row("green_2018_ncal_fisher_scr", description = "Hair-snare genetic SCR of 138 fishers at 100 northwestern California sites, 2006-2013 (snare-year binomial counts).",
  url = "https://doi.org/10.5061/dryad.qb8m4", reference = ref, doi_paper = "10.1111/1365-2656.12791", doi_data = "10.5061/dryad.qb8m4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = "SCR (E9 experimental), binomial per snare-year.", source_via = "Dryad")
stage_tag_row("green_2018_ncal_fisher_scr", ds2, taxon_group = "Mammals", model_family = "Spatial capture-recapture (binomial counts)",
  sampling_protocol = "noninvasive_genetic", design = "Multi-session (8 autumns, 100 hair snares)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (UTM in __traps)", notes = "Experimental (E9).")
