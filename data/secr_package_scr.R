#!/usr/bin/env Rscript
# Tables: efford_2005_waitarere_possum_scr, byrom_2009_matakitaki_stoat_scr,
#         laufenberg_2013_smokies_blackbear_scr, reid_1978_colorado_deermouse_scr,
#         coulombe_1965_ballona_mouse_scr
# Source: the example datasets of the R package secr (Efford), version 5.5.1 (CRAN, published
#         2026-10-11), licence GPL (>= 2) as shown on the CRAN page and in the package
#         DESCRIPTION (asserted below). The data carry no licence of their own; GPL governs.
#         Efford, M. G. (2026). secr: Spatially explicit capture-recapture models. R package
#         version 5.5.1. https://CRAN.R-project.org/package=secr
#         secr itself is not installed or loaded: it needs terra/sf (GDAL). The script downloads
#         the pinned source tarball and loads data/<name>.RData directly. A capthist object is a
#         base-R array (animal x occasion x detector) with attributes: `traps` (a data.frame of
#         detector x/y, rownames = detector ids, attribute `detector`), `covariates` (one row
#         per animal), `session`. None of the five carries a `usage` attribute, which secr reads
#         as every detector operated on every occasion.
# Papers and data (from each dataset's help page, man/<name>.Rd, read in full):
#   possumCH (possum.Rd): brushtail possums, Waitarere, North Island, New Zealand, April 2002;
#     cage traps in 5 'hollow grids' of 36 traps (20 m spacing on the perimeter of a 180 m
#     square), animals tagged and released daily for 5 days; traps catch at most one animal
#     per day (detector 'single'). 112 histories. Efford, Warburton, Coleman & Barker (2005),
#     Wildlife Society Bulletin 33, 731-738, doi:10.2193/0091-7648(2005)33[731:AFTOTM]2.0.CO;2.
#     Data: Landcare Research. The help page notes that 5 histories are animals that had lost
#     a previous tag and 3 more may be; all 8 are flagged by the covariate prev.tagged.
#     Trap covariate grid (G1-G5). Coordinates: NZ Map Grid metres (range asserted).
#   stoatCH (stoatDNA.Rd): stoats, red beech forest, Matakitaki Valley, South Island, New
#     Zealand; 94 sticky hair tubes on a 3 x 3 km grid (500 m between lines, 250 m along),
#     checked daily for 7 days from 15 December 2001; 30 genotyped hair samples of 20 stoats
#     (detector 'multi'; no animal at two tubes on one day). Data of A. E. Byrom. Efford,
#     Borchers & Byrom (2009), in Modeling Demographic Processes in Marked Populations,
#     doi:10.1007/978-0-387-78151-8_11. Coordinates: local metres centred on the grid.
#   blackbearCH (blackbear.Rd): American black bears, Tennessee sector of Great Smoky
#     Mountains National Park, 9 June-15 August 2003; 65 baited barbed-wire hair snags about
#     1 km apart, visited weekly (10 occasions); 282 detections of 139 bears (81 F, 58 M)
#     (detector 'proximity'). Data of J. Laufenberg, F. van Manen and J. Clark. Laufenberg,
#     van Manen & Clark (2013), Journal of Wildlife Management 77, 1010-1020,
#     doi:10.1002/jwmg.534. Coordinates: UTM metres (zone 17N by range, datum not stated).
#   deermouse.ESG, deermouse.WSG (deermouse.Rd): deer mice of V. H. Reid, Rio Blanco County,
#     Colorado, summer 1975, two sites (East Stuart Gulch; Wet Swizer Gulch, August 1975);
#     9 x 11 grids of Sherman traps 50 ft (15.2 m) apart, 6 consecutive nights (detector
#     'multi': 1 double capture at ESG, 8 at WSG). Covariates: ESG sex, age (y/sa/a), weight
#     (g); WSG sex, age (j/y/sa/a). Otis, Burnham, White & Anderson (1978), Wildlife
#     Monographs 62 (no DOI); CAPTURE 'examples' file. Coordinates: grid metres (0-122, 0-152).
#   housemouse (coulombe.Rd): feral house mice of H. N. Coulombe, salt marsh at 'Ballana'
#     (Ballona) Creek, Los Angeles County, California, mid-December 1962; 10 x 10 grid of 100
#     Sherman traps 3 m apart, trapped morning and evening for 5 days (10 occasions; odd =
#     morning, as the help page's subset(occ = c(1,3,5,7,9)) 'morning' example says); 30
#     double captures and one 4-mouse trap (detector 'multi'). Covariates sex (2 NA), age
#     (j/sa/a). Coulombe's 1965 UCLA MSc thesis via Otis et al. (1978); CAPTURE 'examples'.
#     Coordinates: grid metres (0-27).
# Mapping (standard E9 experimental, spatial capture-recapture; responseType detection,
#   unitKind individual; one session each, so no period):
#   unit = animal id as in the capthist rownames (prefixed by site for the deer mice), trap =
#   detector id (rownames of traps), occasion = day/night/week/half-day index, y = 1 where the
#   capthist cell is 1. Every animal has a row at every detector x occasion of its own grid
#   (deer mice: their site's 99 traps), the full rectangle used for the other SCR tables.
#   Survey evidence = inferred: usage is not deposited; every detector is taken as operated
#   on every occasion, as the help pages describe and as secr assumes when usage is absent.
#   unit_ covariates as in the capthist (prev.tagged as 0/1); possum grid in __traps;
#   deer mouse site = cluster_id. obs_half_day (am/pm) for the house mice.
#   None of the five species is threatened (possum and stoat are introduced pests in New
#   Zealand): coordinates kept as published.
#   Not shipped: the fitted secr models (model outputs), masks and habitat polygons
#   (possummask, possumarea, possumremovalarea, GSM), and the package's simulated
#   demonstration data (captdata), none of which is detection data.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/secr_package_scr.R"
VER <- "5.5.1"
TARBALL <- sprintf("secr_%s.tar.gz", VER)
CRAN_PAGE <- "https://cran.r-project.org/package=secr"
PKG_CITE <- sprintf("Efford, M. G. (2026). secr: Spatially explicit capture-recapture models (Version %s) [R package; dataset %%s]. CRAN. https://CRAN.R-project.org/package=secr", VER)
GPL <- list(spdx = "GPL-2.0-or-later", url = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html")

# the pinned tarball: current CRAN first, then the archive once 5.5.1 is superseded
secr_data <- function(table, name) {
  f <- file.path(RAW_DIR, table, TARBALL)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", TARBALL), table, TARBALL), silent = TRUE)
    if (inherits(ok, "try-error"))
      download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/secr/%s", TARBALL), table, TARBALL)
  }
  ex <- file.path(RAW_DIR, table, "secr")
  if (!dir.exists(ex)) untar(f, files = c("secr/DESCRIPTION", "secr/data"), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == VER, desc[, "License"] == "GPL (>= 2)")
  e <- new.env(); load(file.path(ex, "data", paste0(name, ".RData")), envir = e)
  e
}

# capthist -> long rectangle (animal x detector x occasion); asserts the cell values and
# the detector type's constraint
ch_long <- function(ch, detector, prefix = "") {
  stopifnot(inherits(ch, "capthist"), length(dim(ch)) == 3L, all(ch %in% c(0, 1)),
            is.null(attr(attr(ch, "traps"), "usage")),
            identical(attr(attr(ch, "traps"), "detector"), detector))
  if (detector %in% c("single", "multi")) stopifnot(all(apply(ch, 1:2, sum) <= 1))
  ids <- paste0(prefix, dimnames(ch)[[1]]); trap_ids <- paste0(prefix, rownames(attr(ch, "traps")))
  stopifnot(!anyDuplicated(ids), !anyDuplicated(trap_ids))
  long <- CJ(i = seq_len(dim(ch)[1]), occasion = seq_len(dim(ch)[2]), k = seq_len(dim(ch)[3]))
  long[, y := as.integer(ch[cbind(i, occasion, k)])]
  long[, `:=`(unit = ids[i], trap = trap_ids[k])]
  stopifnot(nrow(long) == prod(dim(ch)), sum(long$y) == sum(ch))
  long[, .(unit, trap, occasion, y, i)]
}
traps_of <- function(ch, prefix = "") {
  tr <- attr(ch, "traps")
  data.table(trap = paste0(prefix, rownames(tr)), x = as.numeric(tr$x), y = as.numeric(tr$y))
}
common <- list(sourceURL = CRAN_PAGE, intellectualRights = GPL, responseType = "detection",
               unitKind = "individual", closure = "closed", occasionKind = "time", taxonInclusion = "single")
dict_common <- list(url = CRAN_PAGE, original_license = "GPL (>= 2) (secr R package; the data have no licence of their own)",
                    derived_license = "GPL-2.0-or-later", source_via = sprintf("CRAN source tarball secr %s (data/*.RData)", VER))

# =========================================================================================
# 1. Brushtail possums, Waitarere
# =========================================================================================
TABLE <- "efford_2005_waitarere_possum_scr"
e <- secr_data(TABLE, "possum"); ch <- e$possumCH
stopifnot(identical(dim(ch), c(112L, 5L, 180L)), sum(ch) == 305, attr(ch, "session") == "WaitarerePossums")
cov <- attr(ch, "covariates"); tcov <- attr(attr(ch, "traps"), "covariates")
stopifnot(identical(names(cov), "prev.tagged"), sum(cov$prev.tagged) == 8L, !anyNA(cov$prev.tagged),
          identical(as.vector(table(tcov$grid)), rep(36L, 5)))
long <- ch_long(ch, "single")
long[, unit_prev_tagged := as.integer(cov$prev.tagged[i])]
traps <- traps_of(ch)[, `:=`(grid = as.character(tcov$grid), n_occasions_used = 5L)]
stopifnot(all(traps$x > 2.69e6 & traps$x < 2.71e6), all(traps$y > 6.07e6 & traps$y < 6.09e6))
long <- order_eco(long[, .(unit, taxon = "TRIVUL", y, trap, occasion, unit_prev_tagged)])
taxa <- make_taxa("TRIVUL", "Trichosurus vulpecula", vernacularName = "Common brushtail possum", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Live-trapping spatial capture-recapture of 112 brushtail possums on five 36-trap hollow grids at Waitarere, New Zealand, April 2002 (5 days)",
  creator = "Efford, Murray G.; Warburton, Bruce; Coleman, Morgan C.; Barker, Richard J. (data: Landcare Research; distributed in the secr R package)",
  pubDate = "2005", citation = sprintf(PKG_CITE, "possumCH"),
  paperDOI = "10.2193/0091-7648(2005)33[731:AFTOTM]2.0.CO;2",
  abstract = "Brushtail possums (Trichosurus vulpecula), an introduced pest in New Zealand, were cage-trapped, tagged and released daily for five days in April 2002 in a Pinus radiata plantation on coastal dunes at Waitarere, North Island. 180 traps were set in five 'hollow grids' of 36 (20 m apart around a 180 m square) placed at random in a 300-ha peninsula; the possums were later removed to obtain an independent density (2.26 / ha). The data are the secr package's possumCH: one row per possum x trap x day, y = 1 where it was caught. Eight histories may belong to animals tagged earlier (tag loss), flagged in unit_prev_tagged.",
  samplingProtocol = "Cage traps in five hollow grids of 36 at 20 m spacing, checked and animals tagged and released daily for 5 days (April 2002); one animal per trap per day.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap usage is not deposited (no usage attribute in possumCH). Every one of the 180 traps is taken as set on all 5 days, as the help page describes and secr assumes. Every possum has rows at all 180 traps x 5 days.",
  closureNote = "single session; the 5 days treated as closed, as in the source analyses",
  geographicCoverage = "Waitarere, Manawatu, North Island, New Zealand (about 40.55 S, 175.20 E); trap coordinates in __traps (NZ Map Grid metres)",
  temporalCoverage = "2002-04", crs = "EPSG:27200 (New Zealand Map Grid), by the coordinate range; the help page does not name it",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: Trichosurus vulpecula is IUCN Least Concern and an introduced pest in New Zealand"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps (grid G1-G5 as a trap column). Detector type 'single' (one animal per trap per day; asserted).",
  notes = "Per the secr help page, 5 histories are animals that had lost a previous tag and 3 more may be, flagged unit_prev_tagged = 1; the published analyses treated them as new animals. One female caught twice on one day had one record discarded by the source. Day dates within April 2002 are not given.",
  notShipped = list(possum.model.0_possum.model.Ds = "fitted secr models (model outputs)",
                    possummask_possumarea_possumremovalarea = "habitat mask and polygons, not detection data")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Live-trapping spatial capture-recapture of 112 brushtail possums at 180 cage traps (five hollow grids) over 5 days at Waitarere, New Zealand, April 2002 (secr::possumCH), with trap coordinates in __traps and a tag-loss flag per animal.",
  reference = "Efford, M. G., Warburton, B., Coleman, M. C., & Barker, R. J. (2005). A field test of two methods for density estimation. Wildlife Society Bulletin, 33(2), 731-738.",
  doi_paper = "10.2193/0091-7648(2005)33[731:AFTOTM]2.0.CO;2", doi_data = "",
  notes = "secr package example data (GPL). Survey set inferred (all traps all days). 8 possibly previously tagged animals flagged."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, live traps)",
  sampling_protocol = "live_trap", design = "Single-season (one 5-day session, five hollow grids)", realm = "Terrestrial",
  country = "NZL", coordinates = "As published (NZ Map Grid, in __traps)",
  notes = "Experimental (E9): trap key + __traps. From the secr R package. Survey set inferred.")

# =========================================================================================
# 2. Stoats, Matakitaki Valley (hair tubes, DNA)
# =========================================================================================
TABLE <- "byrom_2009_matakitaki_stoat_scr"
e <- secr_data(TABLE, "stoatDNA"); ch <- e$stoatCH
stopifnot(identical(dim(ch), c(20L, 7L, 94L)), sum(ch) == 30, is.null(attr(ch, "covariates")) || ncol(attr(ch, "covariates")) == 0L)
long <- ch_long(ch, "multi")
traps <- traps_of(ch)[, n_occasions_used := 7L]
stopifnot(all(abs(traps$x) <= 1500), all(abs(traps$y) <= 1500))
long <- order_eco(long[, .(unit, taxon = "MUSERM", y, trap, occasion)])
taxa <- make_taxa("MUSERM", "Mustela erminea", vernacularName = "Stoat", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Hair-tube DNA spatial capture-recapture of 20 stoats at 94 tubes over 7 days, Matakitaki Valley, New Zealand, December 2001",
  creator = "Byrom, Andrea E.; Efford, Murray G.; Borchers, David L. (distributed in the secr R package)",
  pubDate = "2009", citation = sprintf(PKG_CITE, "stoatCH"), paperDOI = "10.1007/978-0-387-78151-8_11",
  abstract = "A pilot study of stoats (Mustela erminea), an introduced predator in New Zealand, in red beech forest in the Matakitaki Valley, South Island. 94 baited sticky hair tubes on a 3 x 3 km grid were checked daily for 7 days from 15 December 2001; hair was genotyped to individual at six microsatellite loci. 30 genotyped samples identify 20 stoats (of 40 samples collected; the rest presumably failed genotyping). The data are the secr package's stoatCH: one row per stoat x tube x day.",
  samplingProtocol = "94 sticky hair-sampling tubes baited with rabbit meat on a 3 km x 3 km grid (500 m between lines, 250 m along lines), checked daily for 7 days from 15 December 2001; individuals identified from DNA.",
  samplingProtocolCode = "hair_snag", surveyEvidence = "inferred",
  surveyEvidenceNote = "Tube usage is not deposited (no usage attribute in stoatCH). Every tube is taken as set on all 7 days, as the help page describes and secr assumes. Every stoat has rows at all 94 tubes x 7 days.",
  closureNote = "single session of 7 daily checks, treated as closed",
  geographicCoverage = "Matakitaki Valley, Buller district, South Island, New Zealand (about 41.9 S, 172.4 E); tube coordinates in __traps are local metres centred on the grid",
  temporalCoverage = "2001-12-15/2001-12-21", crs = "local metres centred on the grid (as distributed)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (local grid coordinates); Mustela erminea is IUCN Least Concern and an introduced pest in New Zealand"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Hair tubes are proximity detectors; the source stores them as 'multi' and no stoat was detected at two tubes on one day (asserted).",
  notes = "Genotyping: six loci, mean 7.3 alleles per locus; not all loci amplified in 27% of samples (help page). 10 of the 40 hair samples collected are not in the data. The paper's '98 sampling sites' is an error per A. E. Byrom (help page).",
  notShipped = list(stoat.model.HN_stoat.model.EX = "fitted secr models (model outputs)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Hair-tube DNA spatial capture-recapture of 20 stoats at 94 tubes over 7 daily checks, Matakitaki Valley, New Zealand, December 2001 (secr::stoatCH), local grid coordinates in __traps.",
  reference = "Efford, M. G., Borchers, D. L., & Byrom, A. E. (2009). Density estimation by spatially explicit capture-recapture: likelihood-based methods. In D. L. Thomson, E. G. Cooch & M. J. Conroy (Eds.), Modeling Demographic Processes in Marked Populations (pp. 255-269). Springer.",
  doi_paper = "10.1007/978-0-387-78151-8_11", doi_data = "",
  notes = "secr package example data (GPL). Survey set inferred (all tubes all days). Below floor (20 individuals)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic)",
  sampling_protocol = "hair_snag", design = "Single-season (one 7-day session of hair tubes)", realm = "Terrestrial",
  country = "NZL", coordinates = "As published (local grid coordinates, in __traps)",
  notes = "Experimental (E9): trap key + __traps. From the secr R package. Survey set inferred.")

# =========================================================================================
# 3. Black bears, Great Smoky Mountains
# =========================================================================================
TABLE <- "laufenberg_2013_smokies_blackbear_scr"
e <- secr_data(TABLE, "blackbear"); ch <- e$blackbearCH
cov <- attr(ch, "covariates")
stopifnot(identical(dim(ch), c(139L, 10L, 65L)), sum(ch) == 282, identical(names(cov), "sex"),
          identical(as.vector(table(cov$sex)), c(81L, 58L)), identical(levels(cov$sex), c("F", "M")))
long <- ch_long(ch, "proximity")
long[, unit_sex := as.character(cov$sex[i])]
traps <- traps_of(ch)[, n_occasions_used := 10L]
stopifnot(all(traps$x > 247e3 & traps$x < 270e3), all(traps$y > 3940e3 & traps$y < 3953e3))
long <- order_eco(long[, .(unit, taxon = "URSAME", y, trap, occasion, unit_sex)])
taxa <- make_taxa("URSAME", "Ursus americanus", vernacularName = "American black bear", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Hair-snag DNA spatial capture-recapture of 139 black bears at 65 snags over 10 weekly occasions, Great Smoky Mountains National Park, 2003",
  creator = "Laufenberg, Jared S.; van Manen, Frank T.; Clark, Joseph D. (distributed in the secr R package)",
  pubDate = "2013", citation = sprintf(PKG_CITE, "blackbearCH"), paperDOI = "10.1002/jwmg.534",
  abstract = "American black bears (Ursus americanus) were sampled with 65 baited barbed-wire hair snags about 1 km apart, mostly near trails, in the Tennessee sector of Great Smoky Mountains National Park from 9 June to 15 August 2003. Snags were visited weekly (10 occasions); hair was genotyped to individual and sex. 282 detections of 139 bears (81 females, 58 males). The data are the secr package's blackbearCH: one row per bear x snag x week.",
  samplingProtocol = "65 baited hair snags (barbed-wire enclosures, bakery bait, raspberry scent lure) about 1 km apart, visited weekly for 10 weeks, 9 June-15 August 2003; hair genotyped to individual and sex (Settlage et al. 2008; Laufenberg et al. 2013).",
  samplingProtocolCode = "hair_snag", surveyEvidence = "inferred",
  surveyEvidenceNote = "Snag usage is not deposited (no usage attribute in blackbearCH). Every snag is taken as operated on all 10 weekly occasions, as the help page describes ('operated for 10 weeks at 65 sites') and secr assumes. Every bear has rows at all 65 snags x 10 weeks.",
  closureNote = "single session of 10 weekly occasions, treated as closed as in the source analyses",
  geographicCoverage = "Tennessee sector of Great Smoky Mountains National Park, USA (about 35.6 N, 83.6 W); snag coordinates in __traps (UTM metres)",
  temporalCoverage = "2003-06-09/2003-08-15", crs = "UTM zone 17N metres by the coordinate range (datum not stated in the help page)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: Ursus americanus is IUCN Least Concern"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Binary proximity detectors (a bear can be detected at several snags in one week).",
  notes = "The help page notes that female 15 apparently moved 17 km between occasions 1 and 3, and that unforested land outside the park on the north-west boundary is not bear habitat. Genotyping of a subset was described by Settlage et al. (2008, doi:10.2193/2006-297); sex and further samples were added later (Laufenberg et al. 2013).",
  notShipped = list(blackbear.0_blackbear.h2bk = "fitted secr models (model outputs)", GSM = "park boundary polygon, not detection data")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Hair-snag DNA spatial capture-recapture of 139 American black bears at 65 snags over 10 weekly occasions, Great Smoky Mountains National Park, Tennessee, June-August 2003 (secr::blackbearCH), with sex and snag coordinates.",
  reference = "Laufenberg, J. S., van Manen, F. T., & Clark, J. D. (2013). Effects of sampling conditions on DNA-based estimates of American black bear abundance. Journal of Wildlife Management, 77(5), 1010-1020.",
  doi_paper = "10.1002/jwmg.534", doi_data = "",
  notes = "secr package example data (GPL). Survey set inferred (all snags all weeks)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic)",
  sampling_protocol = "hair_snag", design = "Single-season (one session of 10 weekly occasions, hair snags)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (UTM 17N, in __traps)",
  notes = "Experimental (E9): trap key + __traps. From the secr R package. Survey set inferred.")

# =========================================================================================
# 4. Deer mice, Rio Blanco County, Colorado (two grids)
# =========================================================================================
TABLE <- "reid_1978_colorado_deermouse_scr"
e <- secr_data(TABLE, "deermouse")
esg <- e$deermouse.ESG; wsg <- e$deermouse.WSG
stopifnot(identical(dim(esg), c(38L, 6L, 99L)), identical(dim(wsg), c(51L, 6L, 99L)),
          sum(esg) == 120, sum(wsg) == 171,
          identical(names(attr(esg, "covariates")), c("sex", "age", "weight")),
          identical(names(attr(wsg, "covariates")), c("sex", "age")))
build_site <- function(ch, site) {
  cv <- attr(ch, "covariates")
  l <- ch_long(ch, "multi", prefix = paste0(site, "_"))
  l[, `:=`(cluster_id = site, unit_sex = as.character(cv$sex[i]), unit_age = as.character(cv$age[i]),
           unit_weight = if ("weight" %in% names(cv)) as.numeric(cv$weight[i]) else NA_real_)]
  l
}
long <- rbind(build_site(esg, "ESG"), build_site(wsg, "WSG"))
traps <- rbind(traps_of(esg, "ESG_")[, site := "ESG"], traps_of(wsg, "WSG_")[, site := "WSG"])[, n_occasions_used := 6L]
stopifnot(nrow(long) == 38 * 6 * 99 + 51 * 6 * 99, sum(long$y) == 291, all(traps$x >= 0 & traps$x <= 122.5),
          all(traps$y >= 0 & traps$y <= 152.5), all(long$unit_sex %in% c("f", "m")))
long <- order_eco(long[, .(unit, taxon = "PERMAN", y, trap, occasion, cluster_id, unit_sex, unit_age, unit_weight)])
taxa <- make_taxa("PERMAN", "Peromyscus maniculatus", vernacularName = "Deer mouse", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Live-trapping spatial capture-recapture of 89 deer mice on two 99-trap grids over 6 nights, Rio Blanco County, Colorado, summer 1975",
  creator = "Reid, V. H. (data); Otis, David L.; Burnham, Kenneth P.; White, Gary C.; Anderson, David R. (distributed with program CAPTURE and in the secr R package)",
  pubDate = "1978", citation = sprintf(PKG_CITE, "deermouse.ESG and deermouse.WSG"),
  abstract = "V. H. Reid live-trapped deer mice (Peromyscus maniculatus) for 6 consecutive nights at two sites in Rio Blanco County, Colorado, in summer 1975: East Stuart Gulch (sagebrush, gambel oak and serviceberry with pinyon-juniper uplands) and Wet Swizer Gulch (August 1975). Each site had a 9 x 11 grid of Sherman traps 15.2 m apart. The data were published by Otis et al. (1978) and distributed with program CAPTURE; they are the secr package's deermouse.ESG and deermouse.WSG. One row per mouse x trap of its site x night; site is cluster_id.",
  samplingProtocol = "9 x 11 grid of Sherman live traps at 50 ft (15.2 m) spacing at each of two sites, 6 consecutive nights; captures recorded by grid column and row.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap usage is not deposited (no usage attribute). Every one of the 99 traps of a site is taken as set on all 6 nights, as the help page describes and secr assumes. Each mouse has rows at its own site's 99 traps x 6 nights.",
  closureNote = "one closed session per site (6 nights); the two sites are separate populations (cluster_id)",
  geographicCoverage = "East Stuart Gulch and Wet Swizer Gulch, Rio Blanco County, Colorado, USA (about 39.9 N, 108.2 W); trap coordinates in __traps are grid metres per site",
  temporalCoverage = "1975-06/1975-08", crs = "local grid metres per site (as distributed)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (local grid coordinates); Peromyscus maniculatus is IUCN Least Concern"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps; site is cluster_id and prefixes unit and trap ids. Sherman traps hold one animal, but the data have 1 double capture at ESG and 8 at WSG, so the source stores them as 'multi' detectors.",
  notes = "Covariates as in the capthists: ESG sex, age (y, sa, a) and weight (g); WSG sex and age (j, y, sa, a), no weight (unit_weight NA). The aging criteria are not recorded. The help page notes that Otis et al. described morning clearances while the CAPTURE file tags every record 'pm', and that WSG was trapped twice daily, yet the data have 6 occasions per site; the exact month at ESG is not stated. Huggins (1991) reused ESG omitting two histories.",
  notShipped = list(none = "nothing: both capthists are shipped")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Live-trapping spatial capture-recapture of deer mice on two 9 x 11 Sherman-trap grids (East Stuart Gulch, Wet Swizer Gulch) over 6 nights, Rio Blanco County, Colorado, 1975 (V. H. Reid; Otis et al. 1978; secr::deermouse), with sex, age and weight.",
  reference = "Otis, D. L., Burnham, K. P., White, G. C., & Anderson, D. R. (1978). Statistical inference from capture data on closed animal populations. Wildlife Monographs, 62, 1-135.",
  doi_paper = "", doi_data = "",
  notes = "secr package example data (GPL), originally CAPTURE's examples file. Two sites as cluster_id. Survey set inferred."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, live traps)",
  sampling_protocol = "live_trap", design = "Single-season (two sites, one 6-night session each)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (local grid coordinates, in __traps)",
  notes = "Experimental (E9): trap key + __traps. From the secr R package (CAPTURE examples). Survey set inferred.")

# =========================================================================================
# 5. House mice, Ballona Creek salt marsh
# =========================================================================================
TABLE <- "coulombe_1965_ballona_mouse_scr"
e <- secr_data(TABLE, "housemouse"); ch <- e$housemouse
cov <- attr(ch, "covariates")
stopifnot(identical(dim(ch), c(173L, 10L, 100L)), sum(ch) == 585, identical(names(cov), c("sex", "age")),
          sum(is.na(cov$sex)) == 2L, all(levels(cov$age) %in% c("j", "sa", "a")))
long <- ch_long(ch, "multi")
long[, `:=`(unit_sex = as.character(cov$sex[i]), unit_age = as.character(cov$age[i]),
            obs_half_day = ifelse(occasion %% 2L == 1L, "am", "pm"))]
traps <- traps_of(ch)[, n_occasions_used := 10L]
stopifnot(all(traps$x >= 0 & traps$x <= 27), all(traps$y >= 0 & traps$y <= 27))
long <- order_eco(long[, .(unit, taxon = "MUSMUS", y, trap, occasion, unit_sex, unit_age, obs_half_day)])
taxa <- make_taxa("MUSMUS", "Mus musculus", vernacularName = "House mouse", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Live-trapping spatial capture-recapture of 173 feral house mice on a 100-trap grid, morning and evening for 5 days, Ballona Creek salt marsh, California, December 1962",
  creator = "Coulombe, H. N. (data); Otis, David L.; Burnham, Kenneth P.; White, Gary C.; Anderson, David R. (distributed with program CAPTURE and in the secr R package)",
  pubDate = "1965", citation = sprintf(PKG_CITE, "housemouse"),
  abstract = "H. N. Coulombe live-trapped an outbreak of feral house mice (Mus musculus) in a salt marsh at Ballona Creek ('Ballana Creek' in the source), Los Angeles County, California, in mid-December 1962: a 10 x 10 grid of 100 Sherman traps 3 m apart, checked morning and evening for 5 days (10 occasions). Described by Otis et al. (1978) from Coulombe's 1965 UCLA MSc thesis and distributed with program CAPTURE; the secr package's housemouse. One row per mouse x trap x half-day.",
  samplingProtocol = "10 x 10 grid of Sherman live traps at 3 m spacing, checked twice daily (morning, evening) for 5 days in mid-December 1962.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "Trap usage is not deposited (no usage attribute). Every one of the 100 traps is taken as set on all 10 half-day occasions, as the help page describes and secr assumes. Every mouse has rows at all 100 traps x 10 occasions.",
  closureNote = "single session of 10 half-day occasions; Otis et al. (1978) tested closure on the full data and used the mornings for model selection",
  geographicCoverage = "Salt marsh at Ballona Creek, Los Angeles County, California, USA (about 33.97 N, 118.43 W); trap coordinates in __traps are grid metres",
  temporalCoverage = "1962-12", crs = "local grid metres (as distributed)",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published (local grid coordinates); Mus musculus is IUCN Least Concern"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Sherman traps hold one animal, but the data have 30 double captures and one trap with 4 mice, so the source stores them as 'multi' detectors. obs_half_day: odd occasions are mornings (the help page's morning subset is occasions 1, 3, 5, 7, 9).",
  notes = "Covariates as in the capthist: sex (f, m; 2 NA) and age (j, sa, a). The place is spelled 'Ballana Creek' in the source; Ballona Creek is the salt marsh of that name in Los Angeles County.",
  notShipped = list(none = "nothing: the capthist is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Live-trapping spatial capture-recapture of 173 feral house mice on a 10 x 10 Sherman-trap grid, checked morning and evening for 5 days, Ballona Creek salt marsh, California, December 1962 (H. N. Coulombe; Otis et al. 1978; secr::housemouse), with sex and age.",
  reference = "Otis, D. L., Burnham, K. P., White, G. C., & Anderson, D. R. (1978). Statistical inference from capture data on closed animal populations. Wildlife Monographs, 62, 1-135.",
  doi_paper = "", doi_data = "",
  notes = "secr package example data (GPL), originally CAPTURE's examples file (Coulombe 1965 MSc thesis). Survey set inferred."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, live traps)",
  sampling_protocol = "live_trap", design = "Single-season (one session of 10 half-day occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (local grid coordinates, in __traps)",
  notes = "Experimental (E9): trap key + __traps. From the secr R package (CAPTURE examples). Survey set inferred.")
