#!/usr/bin/env Rscript
# Tables: lazenby_2021_tasmania_swamprat_scr, lazenby_2021_tasmania_ltmouse_scr
#         (one script, two tables: same traps and sessions, one species each; see the
#         note on E4.2 below)
# Source: Dryad doi:10.5061/dryad.crjdfn337 (CC0 1.0), version 3 (2021-01-29)
#   Lazenby, B., Mooney, N. & Dickman, C. (2021). Spatially explicit capture histories
#   for small mammals and predators in a Tasmanian forest system. Dryad.
# Paper:  Lazenby, B. T., Mooney, N. J. & Dickman, C. R. (2021). Raiders of the last ark:
#         the impacts of feral cats on small mammals in Tasmanian forest ecosystems.
#         Ecological Applications 31(6), e02362. doi:10.1002/eap.2362 (paywalled; the
#         design facts below come from the deposit and its readme, not the paper).
# Data:   one xlsx, six sheets. SR_capt / LTM_capt: one row per capture of a swamp rat /
#         long-tailed mouse (Session 1..6, Individual no., Trap night 1..5, Trap no. 1..60,
#         Site_month_year). Elliott_traps_coords: 60 Elliott traps x 4 sites with WGS 84
#         UTM easting/northing. TD_capt / FC_capt and Camera_coords_masked: camera-trap
#         captures of Tasmanian devils and feral cats (NOT shipped, see below).
#         Sites: SW (Southwest), MtF (Mt Field), WR (Wellington Ranges), TP (Tasman
#         Peninsula). Sessions 1..6 = Mar 2009, May 2009, Mar 2010, May 2010, Mar 2011,
#         May 2011 at every site (asserted from the Site_month_year labels).
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture):
#   unit = individual (site-prefixed, because ear-mark numbers restart at each site),
#   trap = Elliott trap (site-prefixed, 1..60), period = session 1..6, occasion = trap
#   night 1..5, y = 1 if the individual was caught in that trap on that night, else 0;
#   cluster_id = site (the trapping grid). Every individual carries the full rectangle
#   of its site's 60 traps x 5 nights x 6 sessions, including sessions before its first
#   and after its last capture (the convention of the CJS tables, toledolima / dipper).
#   __traps: trap, x, y (EPSG:32755), site. unitKind = individual.
#   Survey evidence = inferred: trap usage is not deposited. Rule: all 60 traps of a
#   site are taken as set on all five nights of every session, because the capture
#   files record nights 1-5 and trap numbers spanning 1-60 at every site and the
#   readme describes successive 24 h periods; no trap failures are recorded.
#   One species per table because E4.2 (every taxon at every survey) reads an
#   individual-unit table as a community table; see BATCH_LOG.md, batch 5.
#   NOT shipped: TD_capt and FC_capt (camera-trap captures of Sarcophilus harrisii and
#   Felis catus): camera-night usage per session is not deposited and the recorded
#   nights per site-session vary from 2 to 20, so the survey set cannot be inferred;
#   camera coordinates are masked by the source for the threatened devil. Held for a
#   predator table once effort is known.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
SCRIPT <- "data/lazenby_2021_tasmania_smallmammal_scr.R"
CACHE <- "lazenby_2021_tasmania_smallmammal_scr"
dir <- download_dryad("10.5061/dryad.crjdfn337", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
xlsx <- list.files(dir, "secr_files.*\\.xlsx$", full.names = TRUE); stopifnot(length(xlsx) == 1)
stopifnot(setequal(excel_sheets(xlsx), c("SR_capt", "LTM_capt", "Elliott_traps_coords", "Camera_coords_masked", "TD_capt", "FC_capt")))

SITES <- c("SW", "MtF", "WR", "TP")
SESSIONS <- data.table(period = 1:6, month = c("Mar", "May", "Mar", "May", "Mar", "May"),
                       year = c(2009L, 2009L, 2010L, 2010L, 2011L, 2011L))
SESSIONS[, label := paste(month, year)]
NIGHTS <- 1:5

tr <- as.data.table(read_excel(xlsx, sheet = "Elliott_traps_coords"))
setnames(tr, c("trap_no", "x", "y", "site"))
stopifnot(nrow(tr) == 240, all(tr[, .N, by = site]$N == 60), all(tr$site %in% SITES),
          tr[, all(sort(trap_no) == 1:60), by = site][, all(V1)],
          all(tr$x > 4e5 & tr$x < 6e5), all(tr$y > 5.2e6 & tr$y < 5.4e6))   # UTM zone 55S, southern Tasmania
traps <- tr[, .(trap = paste(site, trap_no, sep = "_"), x = as.numeric(x), y = as.numeric(y), site)]

read_capt <- function(sheet) {
  d <- as.data.table(read_excel(xlsx, sheet = sheet, col_types = "text"))
  setnames(d, c("session", "ind", "night", "trap_no", "smy"))
  # two LTM rows are prose ("no LTM during third session"), not captures
  prose <- d[is.na(night) & grepl("^no LTM|^No LTM", ind)]
  d <- d[!is.na(night)]
  d[, session := as.integer(sub("^#", "", session))]
  d[, smy := gsub(" ", "", smy)]                      # "TP_ Mar_2009"
  d[, c("site", "month", "year") := tstrsplit(smy, "_")]
  d[, `:=`(night = as.integer(night), trap_no = as.integer(trap_no), year = as.integer(year))]
  stopifnot(all(d$session %in% 1:6), all(d$night %in% NIGHTS), all(d$trap_no %in% 1:60), all(d$site %in% SITES),
            !anyNA(d$ind))
  # session index <-> month/year is the same at every site
  m <- unique(d[, .(session, month, year)])
  stopifnot(nrow(m) == 6, nrow(merge(m, SESSIONS, by.x = c("session", "month", "year"), by.y = c("period", "month", "year"))) == 6)
  stopifnot(!anyDuplicated(d[, .(site, session, ind, night, trap_no)]))
  list(capt = d, n_prose = nrow(prose))
}

build <- function(sheet, taxon, sci, vern, table) {
  r <- read_capt(sheet); capt <- r$capt
  cat(sprintf("  %s: %d capture rows, %d individuals (site-scoped), %d prose rows dropped\n",
              sheet, nrow(capt), uniqueN(capt[, .(site, ind)]), r$n_prose))
  # an animal cannot be in two Elliott traps on one night
  two <- capt[, .N, by = .(site, session, ind, night)][N > 1]
  if (nrow(two)) cat(sprintf("  NOTE %d individual-nights with captures in two traps (kept as two y = 1 rows)\n", nrow(two)))
  inds <- unique(capt[, .(site, ind)])
  # the rectangle: individual x its site's traps x 6 sessions x 5 nights
  long <- merge(inds[, .(site, ind, k = 1)], traps[, .(site, trap)], by = "site", allow.cartesian = TRUE)
  long <- merge(long, CJ(period = 1:6, occasion = NIGHTS)[, k := 1], by = "k", allow.cartesian = TRUE)[, k := NULL]
  capt[, `:=`(trap = paste(site, trap_no, sep = "_"), period = session, occasion = night, y = 1L)]
  long <- merge(long, capt[, .(site, ind, trap, period, occasion, y)], by = c("site", "ind", "trap", "period", "occasion"), all.x = TRUE)
  long[is.na(y), y := 0L]
  stopifnot(sum(long$y) == nrow(capt), nrow(long) == nrow(inds) * 60 * 6 * 5)
  long <- long[, .(unit = paste(site, ind, sep = "_"), taxon = taxon, y, trap, period, occasion, cluster_id = site)]
  long <- order_eco(long)

  taxa <- make_taxa(taxon, sci, vernacularName = vern)
  periods <- copy(SESSIONS)[, .(period, label, month, year, note = "trapping session, 5 consecutive nights; calendar day not deposited")]
  dataset <- list(
    title = sprintf("Spatial capture-recapture of %s (%s) in 60-trap Elliott grids at four Tasmanian forest sites, 6 sessions 2009-2011", vern, sci),
    creator = "Lazenby, Billie; Mooney, Nicholas; Dickman, Christopher",
    pubDate = "2021", doi = "10.5061/dryad.crjdfn337", sourceURL = "https://doi.org/10.5061/dryad.crjdfn337",
    citation = "Lazenby, B., Mooney, N., & Dickman, C. (2021). Spatially explicit capture histories for small mammals and predators in a Tasmanian forest system [Data set]. Dryad. https://doi.org/10.5061/dryad.crjdfn337",
    paperDOI = "10.1002/eap.2362",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Three years of capture-recapture records of individually marked %s from four spatially independent cool temperate forest sites in southern Tasmania (Southwest, Mt Field, Wellington Ranges, Tasman Peninsula), trapped in Elliott live traps in six sessions (March and May of 2009, 2010 and 2011) of five nights. Part of a study of feral cat impacts on small mammals; the co-occurring species (%s) is the companion table, and the camera-trap captures of Tasmanian devils and feral cats in the same deposit are not shipped.",
                       vern, if (taxon == "RATLUT") "lazenby_2021_tasmania_ltmouse_scr" else "lazenby_2021_tasmania_swamprat_scr"),
    samplingProtocol = "Elliott live capture-and-release traps, 60 per site, checked over five successive 24 h trap nights per session; individuals ear-marked. Detection history is individual x trap x night.",
    samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
    surveyEvidenceNote = "Trap usage is not deposited. Every one of the 60 Elliott traps at a site is taken as set on all five nights of every session; the capture files record nights 1-5 and trap numbers 1-60 at every site, and no failures are recorded. Each individual carries rows for all six sessions at its site.",
    responseType = "detection", unitKind = "individual", closure = "period (population closed within a 5-night session; open between sessions)",
    geographicCoverage = "Four forest sites in southern Tasmania, Australia: Southwest (SW), Mt Field (MtF), Wellington Ranges (WR), Tasman Peninsula (TP); Elliott trap coordinates in __traps",
    temporalCoverage = "2009-03/2011-05",
    crs = "EPSG:32755", coordinatesCoarsened = NA,
    designNote = "Experimental list of E9: spatial capture-recapture with a trap key and a __traps side table (easting/northing, WGS 84 / UTM zone 55S as the readme states WGS 84 and the coordinate range places). cluster_id = site is the trapping grid. One species per table because E4.2 reads an individual-unit table with two taxa as a community table.",
    notShipped = list(TD_capt_FC_capt = "camera-trap captures of Sarcophilus harrisii and Felis catus: camera-night usage per session not deposited (recorded nights per site-session span 2-20), coordinates masked by the source; held for a predator table once effort is known",
                      Camera_coords_masked = "with the camera captures",
                      prose_rows = sprintf("%d LTM rows that are notes ('no LTM during third session'), not captures", r$n_prose)))
  ds <- write_table(long, table, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
  stage_dict_row(table,
    description = sprintf("Spatial capture-recapture histories of %s (%s) in four 60-trap Elliott grids in southern Tasmanian forests over six 5-night sessions (March and May 2009-2011), individual x trap x night, with trap coordinates (UTM 55S). Companion table for the other small mammal; devil and cat camera captures in the deposit not shipped.", vern, sci),
    url = "https://doi.org/10.5061/dryad.crjdfn337",
    reference = "Lazenby, B. T., Mooney, N. J., & Dickman, C. R. (2021). Raiders of the last ark: the impacts of feral cats on small mammals in Tasmanian forest ecosystems. Ecological Applications, 31(6), e02362.",
    doi_paper = "10.1002/eap.2362", doi_data = "10.5061/dryad.crjdfn337",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "First SCR table (E9 experimental). Trap usage inferred (all 60 traps x 5 nights every session). One script writes two tables (one per species); camera-trap predators held.",
    source_via = "Dryad (version zip)")
  stage_tag_row(table, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (multi-session, Elliott traps)",
    sampling_protocol = "live_trap", design = "Multi-session (6 sessions x 5 nights, 4 trapping grids)", realm = "Terrestrial",
    country = "AUS", coordinates = "As published (trap coordinates in __traps, UTM 55S)",
    notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle incl. sessions without capture. Survey set inferred.")
  invisible(ds)
}

build("SR_capt",  "RATLUT", "Rattus lutreolus",   "Swamp rat",         "lazenby_2021_tasmania_swamprat_scr")
build("LTM_capt", "PSEHIG", "Pseudomys higginsi", "Long-tailed mouse", "lazenby_2021_tasmania_ltmouse_scr")
