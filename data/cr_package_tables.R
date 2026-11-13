#!/usr/bin/env Rscript
# Tables: bishop_1978_cressington_moth_cjs, nichols_1984_patuxent_vole_rd,
#         nichols_1984_patuxent_femvole_cjs, efford_1998_orongorongo_possum_rd,
#         efford_2004_orongorongo_possum_scr, dawson_2009_patuxent_ovenbird_scr,
#         efford_1995_buller_infraskink_scr, efford_1995_buller_lineoskink_scr,
#         royle_2009_nagarahole_tiger_scr
# Sources: example datasets of three CRAN packages, loaded from their pinned source tarballs
#   without the packages (secr needs GDAL here; as in data/secr_package_scr.R), each asserted
#   for Version and License in DESCRIPTION; the data carry no licence of their own:
#     openCR 2.2.8 (Efford), GPL (>= 2): gonodontisCH, microtusRDCH, microtusFCH, FebpossumCH
#     secr 5.5.1 (Efford), GPL (>= 2): OVpossumCH, ovenCH, infraCH, lineoCH
#     multimark 2.1.7 (McClintock), GPL-2: tiger
# Data (help pages read in full: openCR gonodontis.Rd, microtus.Rd, PPNpossums.Rd; secr
#   OVpossum.Rd, ovenbird.Rd, skink.Rd; multimark tiger.Rd):
#   gonodontisCH: 689 non-melanic male Gonodontis (now Odontopera) bidentata moths at Cressington
#     Park, north-west England, caught at 8 pheromone traps over 17 days (24 May-10 June 1970),
#     non-spatial (capture locations not published), marked with date-specific marks so each moth
#     carries its history; no removals; all day-17 captures were recaptures (unmarked moths may
#     not have been recorded that day). Bishop, Cook & Muggleton (1978), Phil. Trans. R. Soc. B
#     281, 517-540, doi:10.1098/rstb.1978.0007; data as used by Crosbie (1979), Link & Barker
#     (2005).
#   microtus: adult (>= 22 g) meadow voles, Patuxent Wildlife Research Center, Laurel, Maryland,
#     27 June-8 December 1981: 10 x 10 live-trap grid (7.6 m), five consecutive nights each
#     month for six months (robust design); capture locations not published; -1 = not released.
#     microtusRDCH = full robust-design histories of adult males (Williams, Nichols & Conroy
#     2002 Table 19.1); microtusFCH = adult females collapsed to the primary session (Table
#     17.5). The other objects (males collapsed, both sexes combined, the JOLLY version) repeat
#     these and are not shipped. Occasions 9 and 10 (second month) had low captures because a
#     raccoon interfered with traps. Nichols, Pollock & Hines (1984), Acta Theriologica 29,
#     357-365, doi:10.4098/AT.arch.84-35.
#   FebpossumCH: brushtail possums of the Orongorongo Valley, New Zealand, February trapping
#     sessions of 1980-1988 (4-10 nights each), 448 animals (175 F, 273 M), non-spatial; sex.
#     Efford (1998), J. Anim. Ecol. 67, 503-517, doi:10.1046/j.1365-2656.1998.00222.x. The two
#     detector columns carry no location (traps NULL) and never both record one animal on one
#     night (asserted); they are pooled to one capture per night.
#   OVpossumCH: the same study, 1996-1997: a 167-trap grid at 30 m (NZ Map Grid) operated 5
#     nights in February, June and September of each year (sessions 49-54); single-catch traps;
#     -1 = removed; Sex, Ageclass (1 first year, 2 older). Efford & Cowan (2004).
#   ovenCH: adult ovenbirds mist-netted at the Patuxent Research Refuge, Maryland, 2005-2009, 44
#     nets 30 m apart on the perimeter of a 600 x 100 m rectangle, 9-10 days a year in late May-
#     June; birds by band number (several caught in more than one year); one bird killed in a net
#     in 2009 (-1); Sex. Dawson & Efford (2009), J. Appl. Ecol. 46, 1201-1209,
#     doi:10.1111/j.1365-2664.2009.01731.x. ovenCH keeps one capture per bird per day (detector
#     'multi'); ovenCHp (same captures, 'proximity') is not shipped.
#   infraCH, lineoCH: skinks Oligosoma infrapunctatum and O. lineoocellatum in two pitfall grids
#     (11 x 21 at 5 m; 462 traps) at Lake Station, Upper Buller Valley, New Zealand, sessions 6
#     (17-20 October 1995) and 7 (14-17 November 1995) of 3 days each; toe-clipped; SVL (mm)
#     per session; trap covariates (grid, ground cover, vegetation, solar radiation, habitat
#     class). M. G. Efford, B. W. Thomas & N. J. Spencer unpublished. Both species are flagged
#     under E7 (GBIF's IUCN category: O. infrapunctatum CR, O. lineoocellatum EN).
#   tiger: camera-trap SCR of 44 tigers at 120 trap stations over 48 occasions, Nagarahole,
#     India (from program SPACECAP; trap positions 'modified by projecting onto a regular
#     rectangular grid' by the multimark authors), with a trap x occasion operation matrix.
#     Coordinates in km consistent with UTM 43N (array centroid about 12.05 N, 76.13 E).
#     Royle, Karanth, Gopalaswamy & Kumar (2009), Ecology 90, 3233-3244, doi:10.1890/08-1481.1;
#     Gopalaswamy et al. (2012), doi:10.1111/j.2041-210x.2012.00241.x. Enc.Mat columns are
#     trap-major (column = (trap - 1) x 48 + occasion): with that order every detection falls on
#     an operating trap-occasion, with the other it does not (asserted).
# Mapping (E1-E9): unit = the source's individual id (row names; tag, band or row number),
#   period = session/year/primary, occasion = night/day/check, trap = detector id where the data
#   are spatial (with __traps), y = 1 if caught. -1 cells: y = 1 and obs_removed = 1, no later
#   rows. At-risk span (E4.4): animals of unknown age from the first session; possums of
#   Ageclass 1 (first year) from the first session of the calendar year of their first capture
#   (the year's influx of independent juveniles arrives at the February trapping, help page).
#   Survey evidence: tiger effort_table (operation matrix); all others inferred (every detector
#   on every occasion of a session, as the source objects carry no usage and secr/openCR assume).
#   E7: tiger (EN) and both skinks (CR, EN): trap coordinates centred on the array centroid by
#   the processor, metres (tiger km x 1000), the centroid given at 0.1 degree in
#   geographicCoverage; the rest kept as published (possum NZMG, ovenbird local).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/cr_package_tables.R"
PKG <- list(openCR = list(ver = "2.2.8", lic = "GPL (>= 2)", spdx = "GPL-2.0-or-later"),
            secr = list(ver = "5.5.1", lic = "GPL (>= 2)", spdx = "GPL-2.0-or-later"),
            multimark = list(ver = "2.1.7", lic = "GPL-2", spdx = "GPL-2.0-only"))
pkg_data <- function(table, pkg, file) {
  tb <- sprintf("%s_%s.tar.gz", pkg, PKG[[pkg]]$ver)
  f <- file.path(RAW_DIR, table, tb)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", tb), table, tb), silent = TRUE)
    if (inherits(ok, "try-error")) download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", pkg, tb), table, tb)
  }
  ex <- file.path(RAW_DIR, table, pkg)
  if (!dir.exists(ex)) untar(f, files = c(file.path(pkg, "DESCRIPTION"), file.path(pkg, "data")), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == PKG[[pkg]]$ver, desc[, "License"] == PKG[[pkg]]$lic)
  e <- new.env(); suppressWarnings(load(file.path(ex, "data", file), envir = e)); e
}
lic <- function(pkg) list(spdx = PKG[[pkg]]$spdx, url = if (PKG[[pkg]]$spdx == "GPL-2.0-only") "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html" else "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html")
dictc <- function(pkg) list(url = sprintf("https://cran.r-project.org/package=%s", pkg),
  original_license = sprintf("%s (%s R package; the data have no licence of their own)", PKG[[pkg]]$lic, pkg),
  derived_license = PKG[[pkg]]$spdx, source_via = sprintf("CRAN source tarball %s %s (data/*.RData)", pkg, PKG[[pkg]]$ver))
cite <- function(pkg, author, title, ds) sprintf("%s. %s (Version %s) [R package; dataset %s]. CRAN. https://CRAN.R-project.org/package=%s", author, title, PKG[[pkg]]$ver, ds, pkg)
CITE_OPENCR <- function(ds) cite("openCR", "Efford, M. G. (2026)", "openCR: Open population capture-recapture", ds)
CITE_SECR <- function(ds) cite("secr", "Efford, M. G. (2026)", "secr: Spatially explicit capture-recapture models", ds)

# Non-spatial histories: a list of session matrices (animal x occasion, values -1/0/1) with row
# names = ids -> rows per animal from its start session to the end or its removal.
nonspatial_long <- function(mats, start) {
  ids <- unique(unlist(lapply(mats, rownames)))
  stopifnot(setequal(names(start), ids))
  rbindlist(lapply(ids, function(id) {
    out <- list(); removed <- FALSE
    for (s in seq_along(mats)) {
      if (s < start[[id]] || removed) next
      m <- mats[[s]]; v <- if (id %in% rownames(m)) m[id, ] else rep(0, ncol(m))
      last <- if (any(v < 0)) which(v < 0) else length(v)
      out[[length(out) + 1]] <- data.table(unit = id, period = s, occasion = seq_len(last), y = as.integer(abs(v[seq_len(last)])),
                                            obs_removed = as.integer(v[seq_len(last)] < 0))
      if (any(v < 0)) removed <- TRUE
    }
    rbindlist(out)
  }))
}
# Spatial capthist sessions (animal x occasion x trap; single/multi: at most one trap per animal
# and occasion; values -1/0/1) -> rows per animal x trap x occasion from its start session.
spatial_long <- function(chs, start, trap_ids) {
  ids <- unique(unlist(lapply(chs, function(x) dimnames(x)[[1]])))
  stopifnot(setequal(names(start), ids))
  K <- length(trap_ids)
  rbindlist(lapply(ids, function(id) {
    out <- list(); removed <- FALSE
    for (s in seq_along(chs)) {
      if (s < start[[id]] || removed) next
      x <- chs[[s]]; nocc <- dim(x)[2]
      cap <- if (id %in% dimnames(x)[[1]]) matrix(x[id, , ], nocc, K) else matrix(0, nocc, K)
      stopifnot(all(rowSums(cap != 0) <= 1))
      rem <- which(rowSums(cap < 0) > 0)
      last <- if (length(rem)) rem else nocc
      r <- CJ(occasion = seq_len(last), k = seq_len(K))
      r[, `:=`(unit = id, period = s, trap = trap_ids[k], y = as.integer(abs(cap[cbind(occasion, k)])),
               obs_removed = as.integer(cap[cbind(occasion, k)] < 0))]
      out[[length(out) + 1]] <- r[, .(unit, period, occasion, trap, y, obs_removed)]
      if (length(rem)) removed <- TRUE
    }
    rbindlist(out)
  }))
}

# =========================================================================================
# 1. Gonodontis moths, Cressington Park, 1970
# =========================================================================================
TABLE <- "bishop_1978_cressington_moth_cjs"
ch <- pkg_data(TABLE, "openCR", "gonodontis.RData")$gonodontisCH
stopifnot(identical(dim(ch), c(689L, 17L, 1L)), all(ch %in% 0:1), is.null(attr(ch, "traps")),
          all(apply(ch[, , 1], 1, sum) >= 1), sum(ch) == sum(ch[, , 1]))
m <- ch[, , 1]; rownames(m) <- sprintf("%03d", seq_len(nrow(m)))
fc <- apply(m, 1, function(r) which(r == 1)[1])
stopifnot(sum(fc == 17L) == 0L)                                                # no first capture on day 17 (help page)
long <- rbindlist(lapply(seq_len(nrow(m)), function(i) data.table(unit = rownames(m)[i], period = 1:17, y = as.integer(m[i, ]))))
stopifnot(nrow(long) == 689L * 17L, sum(long$y) == sum(m))
long <- order_eco(long[, .(unit, taxon = "ODOBID", y, period, date = format(as.Date("1970-05-24") + period - 1L))])
periods <- data.table(period = 1:17, date = format(as.Date("1970-05-24") + 0:16), n_caught = colSums(m), n_new = tabulate(fc, 17))
taxa <- make_taxa("ODOBID", "Odontopera bidentata", vernacularName = "Scalloped hazel", taxon_iucnCategory = "NE",
                  taxonRemarks = "deposited as Gonodontis bidentata (non-melanic males)")
dataset <- list(
  title = "Daily capture histories of 689 non-melanic male Gonodontis (Odontopera) bidentata moths at pheromone traps, Cressington Park, England, 24 May-10 June 1970",
  creator = "Bishop, J. A.; Cook, L. M.; Muggleton, J. (data); Crosbie, S. F.; Barker, Richard J.; Efford, Murray G. (distributed in the openCR R package)",
  pubDate = "1978", sourceURL = "https://cran.r-project.org/package=openCR", citation = CITE_OPENCR("gonodontisCH"),
  paperDOI = "10.1098/rstb.1978.0007", intellectualRights = lic("openCR"),
  abstract = "Male scalloped hazel moths (Gonodontis, now Odontopera, bidentata) attracted to 8 cages of pheromone-producing females at Cressington Park, north-west England, were marked with date-specific marks and released daily for 17 days in 1970, in a study of the relative fitness of melanic and non-melanic morphs in industrial England. The data are the non-melanic males used by Crosbie (1979) and Link & Barker (2005), as distributed in openCR (gonodontisCH): one row per moth x day, y = 1 if caught.",
  samplingProtocol = "Eight pheromone traps (cages of virgin females surrounded by an enclosure males could enter but not leave), emptied daily; moths marked with a date-specific paint or pen mark under the wing and released.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort is in the data; the traps are taken as operated on all 17 days (help page). All day-17 captures are recaptures: unmarked moths may not have been recorded that day (help page), so day 17 is a survey of marked moths only.",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period = day (open population, Jolly-Seber)",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Cressington Park, Liverpool, England (about 53.36 N, 2.91 W); trap locations not published",
  temporalCoverage = "1970-05-24/1970-06-09", coordinatesCoarsened = NA,
  notes = "Moths were not individually marked; each carries its history as a sequence of date marks. 689 histories, where Bishop et al. (1978) give 690 (help page). Unit ids are row numbers. Age is unknown: every moth has rows from day 1.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Daily capture histories of 689 non-melanic male Gonodontis (Odontopera) bidentata moths at pheromone traps, Cressington Park, England, 17 days in 1970 (openCR::gonodontisCH; Bishop et al. 1978).",
  reference = "Bishop, J. A., Cook, L. M., & Muggleton, J. (1978). The response of two species of moth to industrialization in northwest England. II. Relative fitness of morphs and population size. Philosophical Transactions of the Royal Society of London B, 281, 517-540.",
  doi_paper = "10.1098/rstb.1978.0007", doi_data = "", notes = "openCR package data (GPL). Open population, daily occasions."), dictc("openCR")))
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Jolly-Seber / CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (17 daily occasions)", realm = "Terrestrial",
  country = "GBR", coordinates = "None in source", notes = "From the openCR R package.")

# =========================================================================================
# 2. Meadow voles, Patuxent 1981: adult males, robust design
# =========================================================================================
TABLE <- "nichols_1984_patuxent_vole_rd"
e <- pkg_data(TABLE, "openCR", "microtus.RData")
rd <- e$microtusRDCH
stopifnot(identical(dim(rd), c(180L, 30L, 1L)), all(rd %in% c(-1, 0, 1)), sum(rd < 0) == 10L,
          identical(as.numeric(attr(rd, "intervals")), rep(c(0, 0, 0, 0, 1), 6)[1:29]))
m <- rd[, , 1]; ids <- sprintf("M%03d", seq_len(nrow(m))); rownames(m) <- ids
mats <- lapply(1:6, function(s) m[, (s - 1) * 5 + 1:5, drop = FALSE])
stopifnot(all(sapply(seq_len(nrow(m)), function(i) { r <- m[i, ]; !any(r < 0) || all(r[seq_along(r) > which(r < 0)] == 0) })))
long <- nonspatial_long(mats, setNames(rep(1L, length(ids)), ids))
stopifnot(sum(long$y) == sum(abs(m)), sum(long$obs_removed) == 10L)
long <- order_eco(long[, .(unit, taxon = "MICPEN", y, period, occasion, obs_removed)])
periods <- data.table(period = 1:6, month = c("1981-06/07", "1981-08", "1981-09", "1981-10", "1981-11", "1981-12"),
                      days_to_next = c(35L, 28L, 35L, 28L, 34L, NA))
taxa <- make_taxa("MICPEN", "Microtus pennsylvanicus", vernacularName = "Meadow vole", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Robust-design capture histories of 180 adult male meadow voles at Patuxent, Maryland: six monthly sessions of five nights, June-December 1981",
  creator = "Nichols, James D.; Pollock, Kenneth H.; Hines, James E. (data); Efford, Murray G. (distributed in the openCR R package)",
  pubDate = "1984", sourceURL = "https://cran.r-project.org/package=openCR", citation = CITE_OPENCR("microtusRDCH"),
  paperDOI = "10.4098/AT.arch.84-35", intellectualRights = lic("openCR"),
  abstract = "Adult (>= 22 g) male meadow voles (Microtus pennsylvanicus) live-trapped on a 10 x 10 grid at Patuxent Wildlife Research Center, Laurel, Maryland, on five consecutive nights each month from 27 June to 8 December 1981 (Pollock's robust design), ear-tagged and released; ten were not released. The full robust-design histories of Williams, Nichols & Conroy (2002, Table 19.1), as openCR's microtusRDCH: one row per vole x month x night. The adult females (primary-session level only) are nichols_1984_patuxent_femvole_cjs.",
  samplingProtocol = "100 live traps on a 10 x 10 grid (7.6 m), baited with corn, set in the evening and checked the next morning, five consecutive nights per month for six months.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No trap effort is in the data; every night of every primary session is taken as a survey (help page; 6 x 5 nights). A raccoon interfered with traps on nights 4 and 5 of the second session (help page), which stay surveys with lower capture probability.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (robust design: closed within a monthly session, open between)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  geographicCoverage = "Patuxent Wildlife Research Center, Laurel, Maryland, USA (about 39.05 N, 76.80 W); capture locations not published",
  temporalCoverage = "1981-06-27/1981-12-08", coordinatesCoarsened = NA,
  notes = "Adults only (>= 22 g), as published. -1 in the source = not released: obs_removed = 1 on that capture, no later rows. Unit ids are row numbers (M001-M180). Every vole has rows from the first session (age unknown). Session start dates: true intervals 35, 28, 35, 28 and 34 days (help page; __periods).",
  notShipped = list(microtusMCH_FCH_FMCH_CH = "primary-session collapses of the same histories (the females are shipped separately), and the JOLLY combined-sex version"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Robust-design capture histories of 180 adult male meadow voles, six monthly sessions of five nights, Patuxent Wildlife Research Center, Maryland, June-December 1981 (openCR::microtusRDCH; Williams, Nichols & Conroy 2002 Table 19.1).",
  reference = "Nichols, J. D., Pollock, K. H., & Hines, J. E. (1984). The use of a robust capture-recapture design in small mammal population studies: a field example with Microtus pennsylvanicus. Acta Theriologica, 29, 357-365.",
  doi_paper = "10.4098/AT.arch.84-35", doi_data = "", notes = "openCR package data (GPL). Robust design, losses on capture. Rcapture::mvole is the same study."), dictc("openCR")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture",
  sampling_protocol = "live_trap", design = "Robust design (6 monthly sessions x 5 nights)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the openCR R package.")

# =========================================================================================
# 3. Meadow voles, Patuxent 1981: adult females, monthly
# =========================================================================================
TABLE <- "nichols_1984_patuxent_femvole_cjs"
fch <- e$microtusFCH
stopifnot(identical(dim(fch), c(137L, 6L, 1L)), all(fch %in% c(-1, 0, 1)), sum(fch < 0) == 6L,
          all(attr(fch, "covariates")$sex == "F"))
m <- fch[, , 1]; ids <- sprintf("F%03d", seq_len(nrow(m))); rownames(m) <- ids
long <- nonspatial_long(list(m), setNames(rep(1L, length(ids)), ids))
setnames(long, c("period", "occasion"), c("session", "period"))
stopifnot(sum(long$y) == sum(abs(m)), sum(long$obs_removed) == 6L)
long <- order_eco(long[, .(unit, taxon = "MICPEN", y, period, obs_removed)])
periods <- data.table(period = 1:6, month = c("1981-06/07", "1981-08", "1981-09", "1981-10", "1981-11", "1981-12"))
dataset <- list(
  title = "Monthly capture histories of 137 adult female meadow voles at Patuxent, Maryland, June-December 1981",
  creator = "Nichols, James D.; Pollock, Kenneth H.; Hines, James E. (data); Efford, Murray G. (distributed in the openCR R package)",
  pubDate = "1984", sourceURL = "https://cran.r-project.org/package=openCR", citation = CITE_OPENCR("microtusFCH"),
  paperDOI = "10.4098/AT.arch.84-35", intellectualRights = lic("openCR"),
  abstract = "Adult (>= 22 g) female meadow voles (Microtus pennsylvanicus) from the Patuxent robust-design study of 1981 (five nights a month for six months), collapsed by the source to whether each vole was caught in each monthly session (Williams, Nichols & Conroy 2002, Table 17.5; openCR's microtusFCH). Six were not released. The adult males, with nightly histories, are nichols_1984_patuxent_vole_rd.",
  samplingProtocol = "As nichols_1984_patuxent_vole_rd (10 x 10 live-trap grid, five nights per month); the source keeps only the monthly result.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort is in the data; every monthly session is taken as a survey (help page).",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period = monthly session, collapsed by the source",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  geographicCoverage = "Patuxent Wildlife Research Center, Laurel, Maryland, USA (about 39.05 N, 76.80 W); capture locations not published",
  temporalCoverage = "1981-06-27/1981-12-08", coordinatesCoarsened = NA,
  notes = "Adults only. -1 = not released: obs_removed = 1, no later rows. Unit ids are row numbers (F001-F137); the nightly histories of the females are not in the source.",
  notShipped = list(none = "the males' collapsed histories repeat nichols_1984_patuxent_vole_rd"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Monthly capture histories of 137 adult female meadow voles, Patuxent Wildlife Research Center, Maryland, June-December 1981 (openCR::microtusFCH; Williams, Nichols & Conroy 2002 Table 17.5).",
  reference = "Nichols, J. D., Pollock, K. H., & Hines, J. E. (1984). The use of a robust capture-recapture design in small mammal population studies: a field example with Microtus pennsylvanicus. Acta Theriologica, 29, 357-365.",
  doi_paper = "10.4098/AT.arch.84-35", doi_data = "", notes = "openCR package data (GPL). CJS at the monthly level, losses on capture."), dictc("openCR")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "CJS capture-recapture",
  sampling_protocol = "live_trap", design = "Multi-session (6 monthly occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the openCR R package.")

# =========================================================================================
# 4. Brushtail possums, Orongorongo Valley, February sessions 1980-1988 (non-spatial RD)
# =========================================================================================
TABLE <- "efford_1998_orongorongo_possum_rd"
fb <- pkg_data(TABLE, "openCR", "PPNpossums.RData")$FebpossumCH
stopifnot(length(fb) == 9L, identical(names(fb), as.character(1980:1988)), all(sapply(fb, function(x) is.null(attr(x, "traps")))),
          identical(sapply(fb, function(x) dim(x)[2]), setNames(c(10L, 8L, 6L, 4L, 4L, 4L, 5L, 5L, 6L), 1980:1988)),
          all(sapply(fb, function(x) all(x %in% 0:1) && all(apply(x, 1:2, sum) <= 1))))
mats <- lapply(fb, function(x) { m <- apply(x, 1:2, max); rownames(m) <- dimnames(x)[[1]]; m })
sexes <- rbindlist(lapply(fb, function(x) data.table(unit = dimnames(x)[[1]], sex = as.character(attr(x, "covariates")$sex))))
stopifnot(sexes[, uniqueN(sex), by = unit][, all(V1 == 1L)], uniqueN(sexes$unit) == 448L,
          identical(as.vector(table(unique(sexes)$sex)), c(175L, 273L)))
ids <- unique(sexes$unit)
long <- nonspatial_long(mats, setNames(rep(1L, length(ids)), ids))
stopifnot(sum(long$y) == sum(sapply(mats, sum)), sum(long$obs_removed) == 0L)
long <- merge(long, unique(sexes)[, .(unit, unit_sex = sex)], by = "unit")
long <- order_eco(long[, .(unit, taxon = "TRIVUL", y, period, occasion, unit_sex)])
periods <- data.table(period = 1:9, year = 1980:1988, month = "February", n_nights = sapply(mats, ncol), n_caught = sapply(mats, nrow))
taxa <- make_taxa("TRIVUL", "Trichosurus vulpecula", vernacularName = "Common brushtail possum", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Capture histories of 448 brushtail possums in February trapping sessions (4-10 nights) in the Orongorongo Valley, New Zealand, 1980-1988",
  creator = "Efford, Murray G. (data; distributed in the openCR R package)",
  pubDate = "1998", sourceURL = "https://cran.r-project.org/package=openCR", citation = CITE_OPENCR("FebpossumCH"),
  paperDOI = "10.1046/j.1365-2656.1998.00222.x", intellectualRights = lic("openCR"),
  abstract = "Brushtail possums (Trichosurus vulpecula), an introduced pest in New Zealand, live-trapped in the Orongorongo Valley near Wellington in the February session of each year 1980-1988 (4-10 nights), part of a capture-recapture study running since 1966: 448 animals independent of their mothers (175 females, 273 males). The data are openCR's FebpossumCH, used by Pledger, Pollock & Norris (2010): one row per possum x year x night, without capture locations.",
  samplingProtocol = "Live traps on the Orongorongo study grid, set for 4-10 consecutive nights each February; animals tagged and tattooed and released.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No effort is in the data; every night of each February session is taken as a survey (the session lengths are the capthist's occasions). Two detector columns without locations are pooled (never both 1 for one animal and night, asserted).",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (closed within a February session, open between years)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Orongorongo Valley, Wellington, New Zealand (about 41.35 S, 174.97 E); capture locations not in the data",
  temporalCoverage = "1980-02/1988-02", coordinatesCoarsened = NA,
  notes = "Age is not distinguished beyond independence from the mother: every possum has rows from 1980 (E4.4). Unit ids are the source's animal ids. Removals are not recorded. efford_2004_orongorongo_possum_scr is a later selection (1996-1997) from the same study, with trap locations.",
  notShipped = list(none = "nothing"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Robust-design capture histories of 448 brushtail possums in the February trapping sessions (4-10 nights) of 1980-1988, Orongorongo Valley, New Zealand, with sex (openCR::FebpossumCH; Efford 1998).",
  reference = "Efford, M. G. (1998). Demographic consequences of sex-biased dispersal in a population of brushtail possums. Journal of Animal Ecology, 67, 503-517.",
  doi_paper = "10.1046/j.1365-2656.1998.00222.x", doi_data = "", notes = "openCR package data (GPL). Robust design without capture locations."), dictc("openCR")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture",
  sampling_protocol = "live_trap", design = "Robust design (9 annual sessions x 4-10 nights)", realm = "Terrestrial",
  country = "NZL", coordinates = "None in source", notes = "From the openCR R package.")

# =========================================================================================
# 5. Brushtail possums, Orongorongo Valley, 1996-1997 (spatial, six sessions)
# =========================================================================================
TABLE <- "efford_2004_orongorongo_possum_scr"
ov <- pkg_data(TABLE, "secr", "OVpossum.RData")$OVpossumCH
tr <- attr(ov[[1]], "traps")
stopifnot(length(ov) == 6L, identical(names(ov), as.character(49:54)), all(sapply(ov, function(x) dim(x)[2] == 5L && dim(x)[3] == 167L)),
          all(sapply(ov, function(x) identical(attr(x, "traps"), tr))), identical(attr(tr, "detector"), "single"),
          is.null(attr(tr, "usage")), all(unlist(ov) %in% c(-1, 0, 1)))
cv <- rbindlist(lapply(seq_along(ov), function(s) data.table(unit = dimnames(ov[[s]])[[1]], session = s,
        sex = as.character(attr(ov[[s]], "covariates")$Sex), age = as.integer(as.character(attr(ov[[s]], "covariates")$Ageclass)))))
stopifnot(uniqueN(cv$unit) == 309L, cv[, uniqueN(sex), by = unit][, all(V1 == 1L)], all(cv$age %in% 1:2))
first <- cv[, .SD[which.min(session)], by = unit]
yr_first <- c(1L, 1L, 1L, 4L, 4L, 4L)                                         # first session of the calendar year (Feb 1996 = 1, Feb 1997 = 4)
start <- setNames(ifelse(first$age == 1L, yr_first[first$session], 1L), first$unit)
trap_ids <- rownames(tr)
long <- spatial_long(ov, start, trap_ids)
stopifnot(sum(long$y) == sum(sapply(ov, function(x) sum(abs(x)))), sum(long$obs_removed) == sum(sapply(ov, function(x) sum(x < 0))))
long <- merge(long, first[, .(unit, unit_sex = sex, unit_ageclass_first = age)], by = "unit")
long <- order_eco(long[, .(unit, taxon = "TRIVUL", y, trap, period, occasion, unit_sex, unit_ageclass_first, obs_removed)])
traps <- data.table(trap = trap_ids, x = tr$x, y = tr$y, n_occasions_used = 30L)
periods <- data.table(period = 1:6, deposited_session = 49:54, month = c("1996-02", "1996-06", "1996-09", "1997-02", "1997-06", "1997-09"),
                      n_caught = sapply(ov, function(x) dim(x)[1]))
dataset <- list(
  title = "Spatial capture-recapture of 309 brushtail possums on a 167-trap grid in the Orongorongo Valley, New Zealand: six 5-night sessions, 1996-1997",
  creator = "Efford, Murray G.; Cowan, P. E. (data; distributed in the secr R package)",
  pubDate = "2004", sourceURL = "https://cran.r-project.org/package=secr", citation = CITE_SECR("OVpossumCH"),
  paperDOI = "10.1046/j.1365-2656.1998.00222.x", intellectualRights = lic("secr"),
  abstract = "Brushtail possums (Trichosurus vulpecula) live-trapped on a grid of 167 single-catch cage traps at 30-m spacing (about 14 ha) in mixed broadleaf and beech forest of the Orongorongo Valley near Wellington, New Zealand, for five nights in February, June and September of 1996 and 1997, a time of high and declining density; part of the study running since 1966. The data are secr's OVpossumCH: one row per possum x trap x night, with sex and age class at first capture.",
  samplingProtocol = "167 cage traps on the ground at 30 m spacing, set for 5 consecutive nights three times a year; animals tagged and tattooed and released at the trap.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap usage is not deposited; every trap is taken as set on all 5 nights of each session, as secr assumes. Each possum has rows at all 167 traps x 5 nights for every session from its start to the end of 1997 or its removal.",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (closed within a 5-night session, open between)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  geographicCoverage = "Orongorongo Valley, Wellington, New Zealand (about 41.35 S, 174.97 E); trap coordinates in __traps (NZ Map Grid metres)",
  temporalCoverage = "1996-02/1997-09", crs = "EPSG:27200 (New Zealand Map Grid), as stated on the help page",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: Trichosurus vulpecula is IUCN Least Concern and an introduced pest in New Zealand"),
  designNote = "Experimental list of E9: multi-session spatial capture-recapture with a trap key and __traps. Single-catch traps.",
  notes = "At-risk span: possums of age class 1 (first year) at first capture have rows from the first session of that calendar year (the year's newly independent juveniles enter at the February trapping, help page); older possums from February 1996. -1 = removed (obs_removed = 1, no later rows). Unit ids are the source's animal ids. efford_1998_orongorongo_possum_rd is an earlier selection (February 1980-1988) from the same study.",
  notShipped = list(OVforest_leftbank = "habitat map and riverbank line in the package's extdata: not detection data"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Multi-session spatial capture-recapture of 309 brushtail possums on a 167-trap grid (30 m), six 5-night sessions in 1996-1997, Orongorongo Valley, New Zealand, with sex and age class (secr::OVpossumCH).",
  reference = "Efford, M. G., & Cowan, P. E. (2004). Long-term population trend of Trichosurus vulpecula in the Orongorongo Valley, New Zealand. In R. L. Goldingay & S. M. Jackson (Eds.), The Biology of Australian Possums and Gliders (pp. 471-483). Surrey Beatty & Sons.",
  doi_paper = "10.1046/j.1365-2656.1998.00222.x", doi_data = "", notes = "secr package data (GPL). Multi-session SCR, removals."), dictc("secr")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (multi-session, open)",
  sampling_protocol = "live_trap", design = "Multi-session (6 sessions x 5 nights, 167 traps)", realm = "Terrestrial",
  country = "NZL", coordinates = "As published (NZ Map Grid, in __traps)", notes = "Experimental (E9): trap key + __traps. From the secr R package.")

# =========================================================================================
# 6. Ovenbirds, Patuxent Research Refuge, 2005-2009 (mist nets)
# =========================================================================================
TABLE <- "dawson_2009_patuxent_ovenbird_scr"
oc <- pkg_data(TABLE, "secr", "ovenbird.RData")$ovenCH
tr <- attr(oc[[1]], "traps")
stopifnot(length(oc) == 5L, identical(names(oc), as.character(2005:2009)), all(sapply(oc, function(x) dim(x)[3] == 44L)),
          identical(unname(sapply(oc, function(x) dim(x)[2])), c(9L, 10L, 10L, 10L, 10L)),
          all(sapply(oc, function(x) identical(attr(x, "traps"), tr))), identical(attr(tr, "detector"), "multi"),
          all(unlist(oc) %in% c(-1, 0, 1)), sum(sapply(oc, function(x) sum(x < 0))) == 1L)
cv <- rbindlist(lapply(seq_along(oc), function(s) data.table(unit = dimnames(oc[[s]])[[1]], sex = as.character(attr(oc[[s]], "covariates")$Sex))))
stopifnot(uniqueN(cv$unit) == 70L, cv[, uniqueN(sex), by = unit][, all(V1 == 1L)])
ids <- unique(cv$unit)
long <- spatial_long(oc, setNames(rep(1L, length(ids)), ids), rownames(tr))
stopifnot(sum(long$y) == sum(sapply(oc, function(x) sum(abs(x)))), sum(long$obs_removed) == 1L)
long <- merge(long, unique(cv)[, .(unit, unit_sex = sex)], by = "unit")
long <- order_eco(long[, .(unit, taxon = "SEIAUR", y, trap = paste0("N", trap), period, occasion, unit_sex, obs_removed)])
traps <- data.table(trap = paste0("N", rownames(tr)), x = tr$x, y = tr$y, n_occasions_used = 49L)
periods <- data.table(period = 1:5, year = 2005:2009, n_days = sapply(oc, function(x) dim(x)[2]), n_birds = sapply(oc, function(x) dim(x)[1]))
taxa <- make_taxa("SEIAUR", "Seiurus aurocapilla", vernacularName = "Ovenbird", taxon_iucnCategory = "LC")
dataset <- list(
  title = "Mist-net spatial capture-recapture of 70 adult ovenbirds at 44 nets, Patuxent Research Refuge, Maryland, 9-10 days a year, 2005-2009",
  creator = "Dawson, Deanna K.; Efford, Murray G. (data; distributed in the secr R package)",
  pubDate = "2009", sourceURL = "https://cran.r-project.org/package=secr", citation = CITE_SECR("ovenCH"),
  paperDOI = "10.1111/j.1365-2664.2009.01731.x", intellectualRights = lic("secr"),
  abstract = "Adult ovenbirds (Seiurus aurocapilla) mist-netted in deciduous forest at the Patuxent Research Refuge, Laurel, Maryland: 44 mist nets 30 m apart on the perimeter of a 600 x 100 m rectangle, operated about 9 hours on 9-10 non-consecutive days in late May and June of each year 2005-2009, without playback; birds banded and sexed. The data are secr's ovenCH (one capture per bird per day): one row per bird x net x day for every year from 2005, with sex; one bird was killed by a predator in a net in 2009.",
  samplingProtocol = "44 passive mist nets (12 m, 30 mm mesh) at 30 m spacing on a 600 x 100 m rectangle, about 9 h per day on 9-10 days per breeding season; birds banded, sexed by brood patch or cloacal protuberance, released at the net.",
  samplingProtocolCode = "mist_net", surveyEvidence = "inferred",
  surveyEvidenceNote = "Net usage is not deposited; every net is taken as open on every netting day of the main session of each year (9 days in 2005, 10 later), as secr assumes. Each bird has rows at all 44 nets on every day of every year from 2005 to 2009 (or to its death).",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (closed within a breeding season, open between years)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "obs_removed",
  geographicCoverage = "Patuxent Research Refuge, Laurel, Maryland, USA (about 39.05 N, 76.80 W); net coordinates in __traps are local metres centred on the array",
  temporalCoverage = "2005/2009", crs = "local metres (as distributed)",
  coordinatesCoarsened = list(value = FALSE, method = "local array coordinates as distributed; Seiurus aurocapilla is IUCN Least Concern"),
  designNote = "Experimental list of E9: multi-session spatial capture-recapture with a trap key and __traps. ovenCH keeps one capture per bird per day (detector multi); repeat captures at another net on the same day are in ovenCHp, not shipped.",
  notes = "Birds are linked across years by band number (unit id), so the table supports open models; secr's own analyses treat years separately. Adults of unknown age: rows from 2005. Netting dates within each season are not in the package. Males tended to avoid nets after first capture within a season (Dawson & Efford 2009).",
  notShipped = list(ovenCHp = "the same captures as proximity detectors (adds repeat same-day captures at other nets)", models_mask = "fitted secr models and habitat mask"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Mist-net spatial capture-recapture of 70 adult ovenbirds at 44 nets over 9-10 days per breeding season, Patuxent Research Refuge, Maryland, 2005-2009, birds linked across years, with sex (secr::ovenCH).",
  reference = "Dawson, D. K., & Efford, M. G. (2009). Bird population density estimated from acoustic signals. Journal of Applied Ecology, 46, 1201-1209.",
  doi_paper = "10.1111/j.1365-2664.2009.01731.x", doi_data = "", notes = "secr package data (GPL). Multi-session SCR (mist nets)."), dictc("secr")))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Spatial capture-recapture (multi-session, mist nets)",
  sampling_protocol = "mist_net", design = "Multi-session (5 years x 9-10 days, 44 nets)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (local array metres, in __traps)", notes = "Experimental (E9): trap key + __traps. From the secr R package.")

# =========================================================================================
# 7-8. Skinks, Lake Station, Upper Buller Valley, October-November 1995 (two species)
# =========================================================================================
sk <- pkg_data("efford_1995_buller_infraskink_scr", "secr", "skink.RData")
skink_table <- function(TABLE, chs, sp, code, sci, vern, iucn, other) {
  tr <- attr(chs[[1]], "traps")
  stopifnot(length(chs) == 2L, identical(names(chs), c("6", "7")), all(sapply(chs, function(x) dim(x)[2] == 3L && dim(x)[3] == 462L)),
            all(sapply(chs, function(x) identical(rownames(attr(x, "traps")), rownames(tr)))),
            all(unlist(chs) %in% 0:1), identical(attr(tr, "detector"), "multi"))
  cv <- rbindlist(lapply(seq_along(chs), function(s) data.table(unit = dimnames(chs[[s]])[[1]], session = s,
          species = as.character(attr(chs[[s]], "covariates")$Species), svl = attr(chs[[s]], "covariates")$SVL)))
  stopifnot(all(cv$species == sp))
  ids <- unique(cv$unit)
  long <- spatial_long(chs, setNames(rep(1L, length(ids)), ids), rownames(tr))
  stopifnot(sum(long$y) == sum(sapply(chs, sum)), sum(long$obs_removed) == 0L)
  first <- cv[, .SD[which.min(session)], by = unit]
  long <- merge(long, first[, .(unit, unit_svl_first_mm = svl)], by = "unit")
  long <- order_eco(long[, .(unit, taxon = code, y, trap = paste0("P", trap), period, occasion, unit_svl_first_mm)])
  tc <- as.data.table(attr(tr, "covariates"))
  cx <- mean(tr$x); cy <- mean(tr$y)
  traps <- cbind(data.table(trap = paste0("P", rownames(tr)), x = round(tr$x - cx, 1), y = round(tr$y - cy, 1), n_occasions_used = 6L),
                 tc[, .(trap_grid = as.character(Grid), trap_bare_pct = BarePct, trap_stones_pct = StonesPct, trap_piles_pct = PilesPct,
                        trap_grasses_pct = GrassesPct, trap_forbs_pct = ForbsPct, trap_canopy_bracken_pct = CanBrackPct,
                        trap_bracken_height_cm = HtBrack, trap_coriaria = Tutu01, trap_leucopogon = Cyathodes01,
                        trap_sedges_rushes = SedgesRushes01, trap_rubus = Black01, trap_solar_radiation = SOLARRAD,
                        trap_habitat_class = class, trap_habitat_class2_prob = membership2)])
  periods <- data.table(period = 1:2, deposited_session = 6:7, dates = c("1995-10-17/1995-10-20", "1995-11-14/1995-11-17"),
                        n_caught = sapply(chs, function(x) dim(x)[1]))
  taxa <- make_taxa(code, sci, vernacularName = vern, taxon_iucnCategory = iucn)
  dataset <- list(
    title = sprintf("Pitfall spatial capture-recapture of %d %s (%s) on two 231-trap grids at Lake Station, New Zealand, October and November 1995", length(ids), vern, sci),
    creator = "Efford, Murray G.; Thomas, B. W.; Spencer, N. J. (data, unpublished; distributed in the secr R package)",
    pubDate = "1995", sourceURL = "https://cran.r-project.org/package=secr", citation = CITE_SECR(if (code == "OLIINF") "infraCH" else "lineoCH"),
    intellectualRights = lic("secr"),
    abstract = sprintf("Skinks were pitfall-trapped on two grids of 11 x 21 baited cans 5 m apart on a bracken hillside at Lake Station, Upper Buller Valley, South Island, New Zealand, in a study of habitat use and competition between %s and %s. Sessions 6 (17-20 October 1995) and 7 (14-17 November 1995) of the 1995-1996 study, 3 daily checks each; skinks toe-clipped and released. The data are secr's %s, with snout-vent length and trap-site habitat. One row per skink x trap x day.",
                       sci, other, if (code == "OLIINF") "infraCH" else "lineoCH"),
    samplingProtocol = "Two grids of 11 x 21 pitfall traps (sunken cans baited with fruit in syrup) at 5 m, cleared daily for 3 days per session; skinks marked by toe clipping; captures with uncertain identity, and same-day recaptures at a different trap, dropped by the source.",
    samplingProtocolCode = "pitfall_trap", surveyEvidence = "inferred",
    surveyEvidenceNote = "Trap usage is not deposited; every pitfall is taken as open on all 3 days of both sessions, as secr assumes (the help page says some sessions of the wider study were incomplete, not these two). Each skink has rows at all 462 traps x 3 days x 2 sessions.",
    responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "period (closed within a 3-day session, open between the two)",
    occasionKind = "time", taxonInclusion = "single",
    geographicCoverage = "Lake Station, Upper Buller Valley, South Island, New Zealand; the trap array centroid is at about 41.8 S, 172.7 E (0.1 degree); trap coordinates in __traps are centred on it",
    temporalCoverage = "1995-10-17/1995-11-17", crs = "local metres centred on the array centroid (NZ Map Grid positions withheld)",
    coordinatesCoarsened = list(value = TRUE, method = sprintf("trap coordinates centred on the array centroid by the processor (metres; exact NZ Map Grid positions withheld) because %s is IUCN %s (GBIF's IUCN category) and %s shares the array; the centroid is given at 0.1 degree in geographicCoverage", sci, iucn, other)),
    designNote = "Experimental list of E9: two-session spatial capture-recapture with a trap key and __traps; the two grids are trap_grid in __traps. One table per species (ruling #20); the sibling table holds the other species on the same traps.",
    notes = sprintf("unit_svl_first_mm = snout-vent length at the first session caught. Trap-site habitat in __traps (1-m radius plots; definitions on the help page; trap_habitat_class from fuzzy clustering). The third species, O. polychroma, was seldom caught and is not in the data. Unit ids are the source's. Sibling: %s.", if (code == "OLIINF") "efford_1995_buller_lineoskink_scr" else "efford_1995_buller_infraskink_scr"),
    notShipped = list(trap_totals = "per-trap total captures of each species Apr 1995-Mar 1996 (INFRA, LINEO, POLY): summaries over sessions not in the data"))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = SCRIPT)
  do.call(stage_dict_row, c(list(TABLE,
    description = sprintf("Pitfall spatial capture-recapture of %s on two 11 x 21 pitfall grids (5 m) at Lake Station, Upper Buller Valley, New Zealand, two 3-day sessions in October-November 1995, with snout-vent length and trap habitat (secr::%s); trap coordinates centred (E7).", sci, if (code == "OLIINF") "infraCH" else "lineoCH"),
    reference = "Efford, M. G., Thomas, B. W., & Spencer, N. J. Unpublished data distributed in the secr R package (Efford, Spencer, Thomas, Mason & Williams, in prep., Distribution of sympatric skink species in relation to habitat).",
    doi_paper = "", doi_data = "", notes = sprintf("secr package data (GPL). Two-session SCR; IUCN %s, coordinates centred.", iucn)), dictc("secr")))
  stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Spatial capture-recapture (multi-session)",
    sampling_protocol = "pitfall_trap", design = "Multi-session (2 sessions x 3 days, 462 pitfalls)", realm = "Terrestrial",
    country = "NZL", coordinates = "Coarsened (trap coordinates centred on the array; centroid at 0.1 deg)",
    notes = "Experimental (E9): trap key + __traps. From the secr R package. E7: IUCN-flagged species.")
}
skink_table("efford_1995_buller_infraskink_scr", sk$infraCH, "INFRA", "OLIINF", "Oligosoma infrapunctatum", "speckled skink", "CR", "Oligosoma lineoocellatum")
skink_table("efford_1995_buller_lineoskink_scr", sk$lineoCH, "LINEO", "OLILIN", "Oligosoma lineoocellatum", "spotted skink", "EN", "Oligosoma infrapunctatum")

# =========================================================================================
# 9. Tigers, Nagarahole (multimark, from SPACECAP)
# =========================================================================================
TABLE <- "royle_2009_nagarahole_tiger_scr"
tg <- pkg_data(TABLE, "multimark", "tiger.RData")$tiger
E <- tg$Enc.Mat; TC <- tg$trapCoords
op <- TC[, -(1:2)]
stopifnot(identical(dim(E), c(44L, 5760L)), identical(dim(TC), c(120L, 50L)), all(E %in% 0:1), sum(E) == 68,
          all(op %in% 0:1), sum(op) == 1435L, all(rowSums(E) >= 1))
d <- which(E > 0, arr.ind = TRUE)
k <- (d[, 2] - 1L) %/% 48L + 1L; t <- (d[, 2] - 1L) %% 48L + 1L
stopifnot(all(op[cbind(k, t)] == 1L), !all(op[cbind((d[, 2] - 1L) %% 120L + 1L, (d[, 2] - 1L) %/% 120L + 1L)] == 1L))
sv <- which(op == 1L, arr.ind = TRUE); colnames(sv) <- c("k", "t")
long <- CJ(i = 1:44, s = seq_len(nrow(sv)))
long[, `:=`(k = sv[s, "k"], occasion = sv[s, "t"])]
long[, y := as.integer(E[cbind(i, (k - 1L) * 48L + occasion)])]
long[, `:=`(unit = sprintf("TIG%02d", i), trap = sprintf("S%03d", k))]
stopifnot(nrow(long) == 44L * 1435L, sum(long$y) == 68L)
long <- order_eco(long[, .(unit, taxon = "PANTIG", y, trap, occasion)])
cx <- mean(TC[, 1]); cy <- mean(TC[, 2])
traps <- data.table(trap = sprintf("S%03d", 1:120), x = round((TC[, 1] - cx) * 1000), y = round((TC[, 2] - cy) * 1000),
                    n_occasions_used = as.integer(rowSums(op)))
taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger", taxon_iucnCategory = "EN")
dataset <- list(
  title = "Camera-trap spatial capture-recapture of 44 tigers at 120 stations over 48 occasions, Nagarahole, India",
  creator = "Karanth, K. Ullas; Wildlife Conservation Society (data); Royle, J. Andrew; Gopalaswamy, Arjun M.; Kumar, N. Samba; McClintock, Brett T. (distributed in the multimark R package)",
  pubDate = "2009", sourceURL = "https://cran.r-project.org/package=multimark",
  citation = "McClintock, B. T. (2025). multimark: Capture-mark-recapture analysis using multiple non-invasive marks (Version 2.1.7) [R package; dataset tiger]. CRAN. https://CRAN.R-project.org/package=multimark",
  paperDOI = "10.1890/08-1481.1", intellectualRights = lic("multimark"),
  abstract = "Tigers (Panthera tigris) photographed by camera traps at 120 stations in Nagarahole, India, over 48 sampling occasions and identified by stripe patterns, the SPACECAP example data of Royle et al. (2009) and Gopalaswamy et al. (2012), as distributed in multimark (tiger), with each station's operation per occasion. One row per tiger x operating station-occasion (1,435 of 5,760), y = 1 if photographed.",
  samplingProtocol = "Paired camera traps at 120 stations, 48 sampling occasions; tigers identified individually from stripe patterns; stations operated on a subset of occasions (operation matrix).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The data give a station x occasion operation matrix (1 operating, 0 not); a station-occasion is surveyed iff 1 (1,435). Every detection falls on an operating station-occasion (asserted).",
  responseType = "detection", unitKind = "individual", closure = "closed", closureNote = "single session of 48 occasions, treated as closed as in the source analyses",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Nagarahole (Rajiv Gandhi) National Park, Karnataka, India; the station array centroid is at about 12.1 N, 76.1 E (0.1 degree); station coordinates in __traps are centred on it",
  temporalCoverage = "survey year not stated in the package (Royle et al. 2009)", crs = "local metres centred on the array centroid (source km grid, consistent with UTM 43N, withheld)",
  coordinatesCoarsened = list(value = TRUE, method = "station coordinates centred on the array centroid by the processor (km x 1000 = metres; the source's grid positions withheld) because Panthera tigris is IUCN EN; the centroid is given at 0.1 degree in geographicCoverage. The multimark authors had already snapped stations to a regular grid (0.336 km2 cells)"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Enc.Mat columns are trap-major (asserted against the operation matrix).",
  notes = "The package's station positions were 'modified by projecting onto a regular rectangular grid' (help page), so inter-station distances are approximate. The study year is not in the package. gardner_2018_nagarahole_tiger_oscr is a different deposit from the same reserve (1991-2000); whether this survey overlaps it is not stated. Tiger ids are row numbers (TIG01-TIG44).",
  notShipped = list(studyArea = "habitat grid of the state space (0.336 km2 cells): a model input, not detection data"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Camera-trap spatial capture-recapture of 44 tigers at 120 stations over 48 occasions in Nagarahole, India, with the station operation matrix (multimark::tiger, from SPACECAP; Royle et al. 2009); station coordinates centred (E7).",
  reference = "Royle, J. A., Karanth, K. U., Gopalaswamy, A. M., & Kumar, N. S. (2009). Bayesian inference in camera trapping studies for a class of spatial capture-recapture models. Ecology, 90, 3233-3244.",
  doi_paper = "10.1890/08-1481.1", doi_data = "", notes = "multimark package data (GPL-2). Effort table; IUCN EN, coordinates centred."), dictc("multimark")))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population)",
  sampling_protocol = "camera_trap", design = "Single-season (48 occasions, 120 stations)", realm = "Terrestrial",
  country = "IND", coordinates = "Coarsened (trap coordinates centred on the array; centroid at 0.1 deg)",
  notes = "Experimental (E9): trap key + __traps. From the multimark R package (SPACECAP data). E7: IUCN EN.")
