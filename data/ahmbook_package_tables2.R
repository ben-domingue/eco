#!/usr/bin/env Rscript
# Tables: rodenhouse_2019_hbef_warblers_count, knaus_2018_swiss_atlasha_comm,
#         kery_2016_flevoland_wagtail_ds, chandler_2009_wmnf_cswa_removal,
#         molinarijobin_2012_alps_lynx_fpocc, kery_2021_britain_willowwarbler_cjs,
#         kery_2021_swiss_mspwoodpecker_binom
# Source: the example datasets of the R package AHMbook (Kéry, Royle, Meredith), version 0.2.12
#         (CRAN, published 2026-04-15), licence GPL (>= 3) as shown on the CRAN page and in the
#         package DESCRIPTION (asserted below); loaded from the pinned source tarball without the
#         package, as in data/ahmbook_package_tables.R. HubbardBrook is a copy of an EDI data
#         package whose licence is CC BY 4.0 (EML intellectualRights of knb-lter-hbr.178.3, read
#         through DataONE because the EDI portal refuses scripted requests): GPL is the stricter
#         and governs, and the CC BY attribution is carried in the citation.
# Data (help pages man/data_<name>.Rd, read in full):
#   HubbardBrook: three 10-min point counts each spring 1999-2018 at 373 points of the
#     Hubbard Brook Experimental Forest, New Hampshire; counts of individuals within 50 m for 13
#     species (AOU codes); dates (ordinal day) and start times; NA where no survey. Site
#     covariates: WGS84 longitude/latitude (2 points missing), elevation, aspect, slope, forest
#     type. From Rodenhouse & Sillett (2019), Valleywide Bird Survey, EDI,
#     doi:10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217 (accessed by the package 2020-01-07).
#     The count array and the date array disagree on 81 cells (36 counts without a date, 45
#     dates without counts; asserted): a survey exists where the counts exist.
#   SwissAtlasHa: replicate counts of 78 passerines on 2,318 1-ha quadrats of the Swiss
#     Breeding Bird Atlas 2013-2016 (Knaus et al. 2018), three surveys (two above the tree line:
#     410 quadrats, asserted), survey dates (1 Jan = 1); species by English name only (mapped
#     to scientific names below); quadrat centre coordinates in a reference system the source
#     'intentionally' does not specify; elevation, slope, northness, forest.
#   wagtail: Sovon grassland-bird points in Flevoland, April-mid July 2011: 235 points x up to 4
#     visits x 6 distance classes of 50 m (0-300 m) of Yellow Wagtail observations (Y), visit
#     date and hour, point covariates (potato, grassland, landscape openness). A visit not made
#     has NA counts; its date is filled in anyway (survey set from the counts).
#   cswa: Chestnut-sided Warbler point counts at 43 points in 38 wildlife openings of the White
#     Mountain National Forest, 2004: 3 visits, each split into removal intervals (0-2], (2-5],
#     (5-10] min; one point surveyed only twice (NA). Visit time, date (days since 1970-01-01),
#     observer; point covariates. Spot-mapping population estimates for the 38 patches.
#     Chandler, King & Chandler (2009), Forest Ecology and Management 258, 1669-1676,
#     doi:10.1016/j.foreco.2009.07.025; Chandler, Royle & King (2011), doi:10.1890/10-2433.1.
#   EurasianLynx: lynx observations summarised per 10 x 10 km cell (942 cells, Swiss and Italian
#     Alps) and per winter 1994-2016, three two-month occasions (Nov-Dec, Jan-Feb, Mar-Apr),
#     as two records per cell-winter: 'certain' (confirmed by experts) and 'uncertain' (public,
#     not confirmed, possibly false positives); NA = no data. Coordinates in km E and N of an
#     unnamed origin (the 10-km grid is consistent with ETRS89-LAEA, EPSG:3035, by range: not
#     stated). KORA (SCALP) and Progetto Lince Italia; Molinari-Jobin et al. (2012), Animal
#     Conservation 15, 266-273; AHM2 7.3.2.
#   willowWarbler: British Trust for Ornithology Constant Effort Sites, 1986-1996: annual
#     capture histories of 10,551 willow warblers with the CES of capture (193 sites, approximate
#     easting and northing); also a 5-km cell grid and 25-km blocks of Britain (prediction
#     covariates, not shipped). AHM2 3.4.
#   spottedWoodpecker: volunteer checklists (Swiss Ornithological Institute) summarised per 1-km2
#     quadrat and day, 20 February-31 July (days 51-212), 1990-2015: number of checklists and
#     number reporting a Middle Spotted Woodpecker, 116,204 quadrat-days from 1,545 quadrats
#     where the species was ever recorded since 1985; coordinates in an unspecified reference
#     system. AHM2 4.11.2.
# Mapping (E1-E9; details in each dataset list):
#   HubbardBrook: count, community of the 13 species; unit = PlotID, period = year, occasion =
#     replicate; rows where counts exist; obs_ day of year and start hour (NA where missing).
#   SwissAtlasHa: count, community of the 78 species; unit = quadrat, occasion = survey; no
#     period; obs_day_of_year; coordinates as unit_ covariates (unspecified CRS), not locations.
#   wagtail: multinomial_cell distance sampling (distanceBreaks 0-300 by 50 m); period = visit
#     (as neon_2026_landbirds_ds: period = the count event), occasion = distance class.
#   cswa: multinomial_cell removal (three time intervals); period = visit, occasion = interval.
#   EurasianLynx: state (false-positive design, as ferguson_2015_macon_bawa_fpocc): y = 0 no
#     record, 1 uncertain only, 2 certain only, 3 both; y_raw = certain and uncertain digits.
#   willowWarbler: CJS; unit = bird, cluster_id = CES, period = year. Survey evidence inferred:
#     a CES is taken as operated in a year iff any willow warbler was caught there that year
#     (CES effort is not in the package); a bird has rows in its CES's operated years from
#     1986 (age unknown, E4.4).
#   spottedWoodpecker: binomial_count (ruling #34); unit = quadrat, period = day (index over
#     the dates present; __periods has year and day), y = checklists reporting the species,
#     obs_trials = checklists that day.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/ahmbook_package_tables2.R"
VER <- "0.2.12"
TARBALL <- sprintf("AHMbook_%s.tar.gz", VER)
CRAN_PAGE <- "https://cran.r-project.org/package=AHMbook"
PKG_CITE <- sprintf("Kéry, M., Royle, J. A., & Meredith, M. (2026). AHMbook: Functions and data for the book 'Applied Hierarchical Modeling in Ecology' Vols 1 and 2 (Version %s) [R package; dataset %%s]. CRAN. https://CRAN.R-project.org/package=AHMbook", VER)
AHM1 <- "Kéry, M. & Royle, J. A. (2016). Applied Hierarchical Modeling in Ecology, Volume 1. Academic Press."
AHM2 <- "Kéry, M. & Royle, J. A. (2021). Applied Hierarchical Modeling in Ecology, Volume 2. Academic Press."
GPL <- list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html")
ahm_data <- function(table, name) {
  f <- file.path(RAW_DIR, table, TARBALL)
  if (!file.exists(f)) {
    ok <- try(download_cached(sprintf("https://cran.r-project.org/src/contrib/%s", TARBALL), table, TARBALL), silent = TRUE)
    if (inherits(ok, "try-error"))
      download_cached(sprintf("https://cran.r-project.org/src/contrib/Archive/AHMbook/%s", TARBALL), table, TARBALL)
  }
  ex <- file.path(RAW_DIR, table, "AHMbook")
  if (!dir.exists(ex)) untar(f, files = c("AHMbook/DESCRIPTION", "AHMbook/data"), exdir = file.path(RAW_DIR, table))
  desc <- read.dcf(file.path(ex, "DESCRIPTION"))
  stopifnot(desc[, "Version"] == VER, desc[, "License"] == "GPL (>= 3)")
  e <- new.env(); load(file.path(ex, "data", paste0(name, ".rda")), envir = e); get(name, envir = e)
}
common <- list(sourceURL = CRAN_PAGE, intellectualRights = GPL)
dict_common <- list(url = CRAN_PAGE, original_license = "GPL (>= 3) (AHMbook R package; the data have no licence of their own)",
                    derived_license = "GPL-3.0-or-later", source_via = sprintf("CRAN source tarball AHMbook %s", VER))
iso <- function(year, doy) ifelse(is.na(doy), NA_character_, format(as.Date(sprintf("%d-01-01", year)) + doy - 1L))

# =========================================================================================
# 1. Hubbard Brook Valleywide Bird Survey counts, 1999-2018
# =========================================================================================
TABLE <- "rodenhouse_2019_hbef_warblers_count"
hb <- ahm_data(TABLE, "HubbardBrook")
cn <- hb$counts; sc <- as.data.table(hb$sitecov)
SP <- c(AMRE = "Setophaga ruticilla", BAWW = "Mniotilta varia", BHVI = "Vireo solitarius", BLBW = "Setophaga fusca",
        BLPW = "Setophaga striata", BTBW = "Setophaga caerulescens", BTNW = "Setophaga virens", CAWA = "Cardellina canadensis",
        MAWA = "Setophaga magnolia", MYWA = "Setophaga coronata", NAWA = "Leiothlypis ruficapilla", OVEN = "Seiurus aurocapilla",
        REVI = "Vireo olivaceus")
stopifnot(identical(dim(cn), c(373L, 3L, 20L, 13L)), identical(dimnames(cn)[[3]], as.character(1999:2018)),
          identical(dimnames(cn)[[4]], names(SP)), identical(as.character(sc$PlotID), dimnames(cn)[[1]]), max(sc$PlotID) == 400L, sum(cn, na.rm = TRUE) == 48064,
          all(cn %in% c(0:6, NA)),
          all(apply(is.na(cn), 1:3, function(v) all(v) || !any(v))),                # NA identical across species
          sum(!is.na(cn[, , , 1])) == 17032L,
          sum(!is.na(cn[, , , 1]) & is.na(hb$dates)) == 36L, sum(is.na(cn[, , , 1]) & !is.na(hb$dates)) == 45L,
          sum(is.na(sc$Latitude)) == 2L)
long <- as.data.table(as.table(cn))
setnames(long, c("site", "rep", "year", "taxon", "y"))
long <- long[!is.na(y)]
long[, `:=`(row = match(as.character(site), dimnames(cn)[[1]]), unit = sprintf("%03d", as.integer(as.character(site))), occasion = as.integer(as.character(rep)),
            year = as.integer(as.character(year)), taxon = as.character(taxon), y = as.integer(y))]
long[, period := year - 1998L]
idx <- cbind(long$row, long$occasion, long$period)
long[, `:=`(obs_day_of_year = hb$dates[idx], obs_start_hour = hb$times[idx])]
long <- merge(long, sc[, .(unit = sprintf("%03d", PlotID), unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude,
                           unit_elevation_m = Elev, unit_aspect_deg = Aspect, unit_slope = Slope,
                           unit_forest_type = fifelse(as.character(Forest) == "", NA_character_, as.character(Forest)))], by = "unit")
stopifnot(nrow(long) == 17032L * 13L)
long <- order_eco(long[, .(unit, taxon, y, period, occasion, unit_decimalLatitude, unit_decimalLongitude, unit_elevation_m,
                           unit_aspect_deg, unit_slope, unit_forest_type, obs_day_of_year, obs_start_hour)])
periods <- long[taxon == "AMRE", .(n_surveys = .N, n_points = uniqueN(unit)), by = period][order(period)][, year := period + 1998L][, .(period, year, n_points, n_surveys)]
taxa <- make_taxa(names(SP), unname(SP), taxon_alpha_code = names(SP))
dataset <- c(common, list(
  title = "Point counts of 13 warblers and vireos at 373 points of the Hubbard Brook Experimental Forest, 3 counts a year, 1999-2018",
  creator = "Rodenhouse, Nicholas L.; Sillett, T. Scott (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2019", citation = paste0(sprintf(PKG_CITE, "HubbardBrook"), ". Original data: Rodenhouse, N. L. & Sillett, T. S. (2019). Valleywide Bird Survey, Hubbard Brook Experimental Forest, 1999-2016 (ongoing). Environmental Data Initiative. https://doi.org/10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217 (CC BY 4.0)."),
  paperDOI = "10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217",
  abstract = "The Valleywide Bird Survey of the Hubbard Brook Experimental Forest, New Hampshire: three 10-minute point counts each spring at 373 points on a grid across the valley, 1999-2018. The AHMbook package's HubbardBrook copy gives, for 13 warblers and vireos, the number of individuals detected within 50 m per count, with count date and start time and point covariates (WGS84 coordinates, elevation, aspect, slope, forest type). One row per point x year x count x species.",
  samplingProtocol = "Three 10-min point counts per breeding season at each of 373 points, unlimited radius to 100 m; the package's counts are individuals within 50 m.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The count array has NA where no survey was carried out (help page), identically across species (asserted). It disagrees with the date array on 81 cells: 36 counts without a date (kept, obs_day_of_year NA) and 45 dates without counts (not surveys: nothing was recorded).",
  responseType = "count", unitKind = "site", closure = "closed", closureNote = "period (the three counts of a year)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Hubbard Brook Experimental Forest, New Hampshire, USA (43.9 N, 71.7 W); point coordinates as unit_decimalLatitude/Longitude (WGS84; 2 points without)",
  temporalCoverage = "1999/2018", crs = "EPSG:4326",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: none of the 13 species is IUCN CR, EN or VU"),
  notes = "Overlaps doser_2022_hbef_trends_dynocc (spOccupancy::hbefTrends: detection/non-detection of 12 species from the same survey, 2010-2018); both ship under the overlap ruling. The package covers 1999-2018 though the cited EDI version is titled 1999-2016; it has no counts at all in 2003 and 2004 (no rows, so periods 5 and 6 are absent) and one count per point in 2002 (__periods). taxon = AOU alpha code (MYWA = myrtle warbler, Setophaga coronata). Counts are within 50 m only. The 13 species are those the package keeps, not the survey's full list.",
  notShipped = list(other_species = "the survey records all species; the package keeps 13 (the EDI source has the rest)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Counts (within 50 m) of 13 warblers and vireos on three 10-min point counts a year at 373 points of the Hubbard Brook Experimental Forest, New Hampshire, 1999-2018, with point coordinates and count dates (AHMbook::HubbardBrook, from the Valleywide Bird Survey on EDI).",
  reference = "Rodenhouse, N. L., & Sillett, T. S. (2019). Valleywide Bird Survey, Hubbard Brook Experimental Forest, 1999-2016 (ongoing). Environmental Data Initiative.",
  doi_paper = "", doi_data = "10.6073/pasta/faca2b2cf2db9d415c39b695cc7fc217",
  notes = "AHMbook package data (GPL); the EDI source is CC BY 4.0. Overlaps doser_2022_hbef_trends_dynocc."),
  modifyList(dict_common, list(original_license = "GPL (>= 3) (AHMbook package); source data CC BY 4.0 (EDI knb-lter-hbr.178)"))))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community, dynamic)",
  sampling_protocol = "point_count", design = "Multi-season (1999-2018, 3 counts a year; no counts 2003-2004)", realm = "Terrestrial",
  country = "USA", coordinates = "As published (WGS84 points)", notes = "From the AHMbook R package (AHM2 8.2); source EDI Valleywide Bird Survey.")

# =========================================================================================
# 2. Swiss Breeding Bird Atlas, 1-ha quadrats, 78 passerines
# =========================================================================================
TABLE <- "knaus_2018_swiss_atlasha_comm"
at <- ahm_data(TABLE, "SwissAtlasHa")
cn <- at$counts; sc <- as.data.table(at$sitecovs)
# English names as in the package -> scientific names (taxonomy of the Swiss atlas)
EN <- c("Skylark" = "Alauda arvensis", "Barn Swallow" = "Hirundo rustica", "Crag Martin" = "Ptyonoprogne rupestris",
  "House Martin" = "Delichon urbicum", "Golden Oriole" = "Oriolus oriolus", "Raven" = "Corvus corax", "Carrion Crow" = "Corvus corone",
  "Magpie" = "Pica pica", "Spotted Nutcracker" = "Nucifraga caryocatactes", "Jay" = "Garrulus glandarius",
  "Alpine Chough" = "Pyrrhocorax graculus", "Great Tit" = "Parus major", "Blue Tit" = "Cyanistes caeruleus", "Coal Tit" = "Periparus ater",
  "Crested Tit" = "Lophophanes cristatus", "Marsh Tit" = "Poecile palustris", "Willow Tit" = "Poecile montanus",
  "Long-tailed Bushtit" = "Aegithalos caudatus", "Nuthatch" = "Sitta europaea", "Eurasian Treecreeper" = "Certhia familiaris",
  "Short-toed Treecreeper" = "Certhia brachydactyla", "Wallcreeper" = "Tichodroma muraria", "Dipper" = "Cinclus cinclus",
  "Winter Wren" = "Troglodytes troglodytes", "Robin" = "Erithacus rubecula", "Nightingale" = "Luscinia megarhynchos",
  "Black Redstart" = "Phoenicurus ochruros", "Common Redstart" = "Phoenicurus phoenicurus", "Whinchat" = "Saxicola rubetra",
  "Stonechat" = "Saxicola rubicola", "Wheatear" = "Oenanthe oenanthe", "Rock Thrush" = "Monticola saxatilis",
  "Ring Ouzel" = "Turdus torquatus", "Blackbird" = "Turdus merula", "Fieldfare" = "Turdus pilaris", "Song Thrush" = "Turdus philomelos",
  "Mistle Thrush" = "Turdus viscivorus", "Reed Warbler" = "Acrocephalus scirpaceus", "Marsh Warbler" = "Acrocephalus palustris",
  "Blackcap" = "Sylvia atricapilla", "Garden Warbler" = "Sylvia borin", "Whitethroat" = "Curruca communis",
  "Lesser Whitethroat" = "Curruca curruca", "Willow Warbler" = "Phylloscopus trochilus", "Chiffchaff" = "Phylloscopus collybita",
  "Bonelli's Warbler" = "Phylloscopus bonelli", "Wood Warbler" = "Phylloscopus sibilatrix", "Goldcrest" = "Regulus regulus",
  "Firecrest" = "Regulus ignicapilla", "Spotted Flycatcher" = "Muscicapa striata", "Pied Flycatcher" = "Ficedula hypoleuca",
  "Dunnock" = "Prunella modularis", "Alpine Accentor" = "Prunella collaris", "Tree Pipit" = "Anthus trivialis",
  "Water Pipit" = "Anthus spinoletta", "White Wagtail" = "Motacilla alba", "Grey Wagtail" = "Motacilla cinerea",
  "Red-backed Shrike" = "Lanius collurio", "Starling" = "Sturnus vulgaris", "House Sparrow" = "Passer domesticus",
  "Italian Sparrow" = "Passer italiae", "Tree Sparrow" = "Passer montanus", "White-winged Snowfinch" = "Montifringilla nivalis",
  "Hawfinch" = "Coccothraustes coccothraustes", "Greenfinch" = "Chloris chloris", "Goldfinch" = "Carduelis carduelis",
  "Siskin" = "Spinus spinus", "Linnet" = "Linaria cannabina", "Redpoll" = "Acanthis flammea", "Citril Finch" = "Carduelis citrinella",
  "Serin" = "Serinus serinus", "Bullfinch" = "Pyrrhula pyrrhula", "Red Crossbill" = "Loxia curvirostra", "Chaffinch" = "Fringilla coelebs",
  "Yellowhammer" = "Emberiza citrinella", "Cirl Bunting" = "Emberiza cirlus", "Rock Bunting" = "Emberiza cia",
  "Reed Bunting" = "Emberiza schoeniclus")
en_pkg <- trimws(dimnames(cn)[[3]])                                   # 'Firecrest ' has a trailing space in the package
stopifnot(identical(dim(cn), c(2318L, 3L, 78L)), length(EN) == 78L, setequal(en_pkg, names(EN)), !anyDuplicated(EN),
          !anyDuplicated(dimnames(cn)[[1]]), identical(dimnames(cn)[[1]], dimnames(at$dates)[[1]]) || is.null(dimnames(at$dates)[[1]]),
          all(apply(is.na(cn), 1:2, function(v) all(v) || !any(v))),
          identical(as.vector(table(sc$nsurveys)), c(410L, 1908L)),
          all(rowSums(!is.na(cn[, , 1])) == sc$nsurveys), all(is.na(at$dates) == is.na(cn[, , 1])),
          sum(cn, na.rm = TRUE) == 12593)
code6 <- function(s) toupper(paste0(substr(sub(" .*", "", s), 1, 3), substr(sub(".* ", "", s), 1, 3)))
CODE <- setNames(code6(EN), names(EN))
CODE[c("Raven", "Carrion Crow")] <- c("CORCRX", "CORCRN"); CODE[c("Whinchat", "Stonechat")] <- c("SAXRBT", "SAXRBC")
stopifnot(!anyDuplicated(CODE))
dimnames(cn)[[3]] <- CODE[en_pkg]
long <- as.data.table(as.table(cn))
setnames(long, c("site", "rep", "taxon", "y"))
long <- long[!is.na(y)]
long[, `:=`(site = as.character(site), occasion = match(as.character(rep), c("count1", "count2", "count3")),
            taxon = as.character(taxon), y = as.integer(y))]
stopifnot(!anyNA(long$occasion), all(long$y >= 0))
sc[, site := dimnames(at$counts)[[1]]]
long[, obs_day_of_year := at$dates[cbind(match(site, sc$site), occasion)]]
long <- merge(long, sc[, .(site, unit_x_unspecified_crs = x, unit_y_unspecified_crs = y, unit_elevation_m = elevation,
                           unit_slope = slope, unit_northness = north, unit_forest_prop = forest)], by = "site")
long[, unit := site]
stopifnot(nrow(long) == (410L * 2L + 1908L * 3L) * 78L)
long <- order_eco(long[, .(unit, taxon, y, occasion, unit_x_unspecified_crs, unit_y_unspecified_crs, unit_elevation_m,
                           unit_slope, unit_northness, unit_forest_prop, obs_day_of_year)])
LOOK <- EN
LOOK["Wood Warbler"] <- "Phylloscopus sibillatrix"           # GBIF backbone keeps the original spelling
LOOK["Greenfinch"] <- "Chloris chloris (Linnaeus, 1758)"     # the bare binomial is ambiguous with the grass genus in a strict match
taxa <- make_taxa(unname(CODE), unname(EN[names(CODE)]), vernacularName = names(CODE), lookupName = unname(LOOK[names(CODE)]))
dataset <- c(common, list(
  title = "Swiss Breeding Bird Atlas 2013-2016: counts of 78 passerines on 2 or 3 surveys of 2,318 one-hectare quadrats",
  creator = "Swiss Ornithological Institute (Knaus, Peter; Antoniazza, Sylvain; Wechsler, Samuel; Guélat, Jérôme; Kéry, Marc; Strebel, Nicolas; Sattler, Thomas) (data); distributed in the AHMbook R package",
  pubDate = "2018", citation = sprintf(PKG_CITE, "SwissAtlasHa"), paperDOI = "10.1016/B978-0-12-809585-0.00008-9",
  abstract = "A 1-ha-scale subset of the Swiss Breeding Bird Atlas 2013-2016 (Knaus et al. 2018): replicate counts of 78 passerine species on 2,318 one-hectare quadrats, each surveyed three times in a breeding season (twice above the tree line). The data are the AHMbook package's SwissAtlasHa (AHM2 section 8.4.2): one row per quadrat x survey x species, with survey date and quadrat elevation, slope, aspect and forest cover. Quadrat coordinates are in a reference system the source intentionally does not specify and ship as covariates only.",
  samplingProtocol = "Atlas surveys of 1-ha quadrats, three visits in the breeding season (two above the tree line), all birds counted; the package keeps 78 passerines.",
  samplingProtocolCode = "area_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The count array has NA for the third survey of the 410 quadrats surveyed twice (nsurveys, asserted), identically across species and matching the date array; every other cell is a survey with a row for all 78 species.",
  responseType = "count", unitKind = "site", closure = "closed", closureNote = "single season (one breeding season per quadrat, 2013-2016)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Switzerland, 2,318 one-hectare atlas quadrats; coordinates in an unspecified reference system (unit_x_unspecified_crs, unit_y_unspecified_crs)",
  temporalCoverage = "2013/2016",
  coordinatesCoarsened = list(value = FALSE, method = "no locations shipped: the source's coordinates have an unspecified reference system and ship as covariates; none of the 78 species is IUCN CR, EN or VU"),
  notes = "The package gives English names only; scientific names are mapped in the script (taxonomy as in the Swiss atlas: Curruca for the whitethroats, Acanthis flammea for redpoll s.l., Carduelis citrinella for citril finch) and resolved in __taxa. The year of each quadrat's survey is not in the package (2013-2016). obs_day_of_year: 1 = 1 January. The 78 species are those the package keeps: an atlas subset, not the full species list.",
  notShipped = list(other_species = "non-passerines and passerines the package does not keep")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Counts of 78 passerine species on two or three surveys of 2,318 one-hectare quadrats of the Swiss Breeding Bird Atlas 2013-2016, with survey dates and quadrat covariates (AHMbook::SwissAtlasHa).",
  reference = "Knaus, P., Antoniazza, S., Wechsler, S., Guélat, J., Kéry, M., Strebel, N., & Sattler, T. (2018). Swiss Breeding Bird Atlas 2013-2016. Swiss Ornithological Institute, Sempach.",
  doi_paper = "10.1016/B978-0-12-809585-0.00008-9", doi_data = "",
  notes = "AHMbook package data (GPL). Community counts; coordinates in an unspecified CRS shipped as covariates."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community)",
  sampling_protocol = "area_count", design = "Single-season (2-3 surveys per quadrat)", realm = "Terrestrial",
  country = "CHE", coordinates = "As published (unspecified CRS, shipped as covariates)", notes = "From the AHMbook R package (AHM2 8.4.2).")

# =========================================================================================
# 3. Yellow Wagtail distance sampling, Flevoland 2011
# =========================================================================================
TABLE <- "kery_2016_flevoland_wagtail_ds"
wg <- ahm_data(TABLE, "wagtail")
Y <- wg$Y
stopifnot(identical(dim(Y), c(235L, 24L)), identical(as.numeric(wg$breaks), seq(0, 300, 50)), sum(Y, na.rm = TRUE) == 913,
          all(sapply(0:3, function(k) all(rowSums(is.na(Y[, k * 6 + 1:6])) %in% c(0L, 6L)))),
          identical(sapply(0:3, function(k) sum(is.na(Y[, k * 6 + 1]))), c(0L, 6L, 9L, 14L)), !anyNA(wg$date))
long <- rbindlist(lapply(1:4, function(k) rbindlist(lapply(1:6, function(b)
  data.table(i = 1:235, period = k, occasion = b, y = Y[, (k - 1) * 6 + b])))))[!is.na(y)]
long[, `:=`(unit = sprintf("%03d", i), date = format(as.Date("2011-01-01") + wg$date[cbind(i, period)] - 1),
            obs_hour = wg$hour[cbind(i, period)], unit_potato_pct = as.numeric(wg$potato)[i],
            unit_grassland_pct = as.numeric(wg$grass)[i], unit_landscape_closed = as.numeric(wg$lscale)[i], y = as.integer(y))]
stopifnot(nrow(long) == (235L * 4L - 29L) * 6L, all(substr(long$date, 1, 4) == "2011"))
long <- order_eco(long[, .(unit, taxon = "MOTFLA", y, period, occasion, date, unit_potato_pct, unit_grassland_pct, unit_landscape_closed, obs_hour)])
periods <- data.table(period = 1:4, visit = 1:4)
taxa <- make_taxa("MOTFLA", "Motacilla flava", vernacularName = "Western yellow wagtail", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Yellow Wagtail point counts in six 50-m distance classes on up to 4 visits to 235 grassland points, Flevoland, Netherlands, 2011",
  creator = "Sovon Dutch Centre for Field Ornithology (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2016", citation = sprintf(PKG_CITE, "wagtail"), paperDOI = "10.1016/B978-0-12-801378-6.00009-6",
  abstract = "Sovon monitored grassland birds at 235 points in Flevoland, the Netherlands, between April and mid-July 2011, visiting each point up to four times and recording observations in 50-m distance classes out to 300 m. The data are the AHMbook package's wagtail (AHM1 section 9.5.3), for the Yellow Wagtail: one row per point x visit x distance class, y = observations in the class, with visit date and hour and the point's potato and grassland cover and landscape openness.",
  samplingProtocol = "Point counts with observations assigned to 50-m distance classes (0-300 m), up to four visits per point, April to mid-July 2011.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The count matrix has NA in all six classes of a visit that was not made (6, 9 and 14 points miss visits 2, 3 and 4; asserted). The package fills a date for those visits anyway, so the survey set is taken from the counts.",
  responseType = "multinomial_cell", distanceBreaks = seq(0, 300, 50), unitKind = "site",
  closure = "closed", closureNote = "occasion = distance class of one count; period = the visit (1-4) within the 2011 season, as in neon_2026_landbirds_ds",
  occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Flevoland, Netherlands (no point coordinates in the package)", temporalCoverage = "2011-04/2011-07",
  coordinatesCoarsened = NA,
  notes = "Birds beyond 300 m are not in the data. unit_landscape_closed: 0 open to 100 closed (help page). Period is the visit within one season: a single-season model pools periods. Point ids are row numbers.",
  notShipped = list(rep = "the visit number as a character matrix (redundant with period)")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Yellow Wagtail observations in six 50-m distance classes (0-300 m) on up to 4 visits to 235 grassland points in Flevoland, Netherlands, April-July 2011, with visit date and hour and point land cover (AHMbook::wagtail; Sovon).",
  reference = AHM1, doi_paper = "10.1016/B978-0-12-801378-6.00009-6", doi_data = "",
  notes = "AHMbook package data (GPL). Binned distance sampling; period = visit."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Distance sampling (binned, repeated visits)",
  sampling_protocol = "point_count", design = "Single-season (up to 4 visits, 6 distance classes)", realm = "Terrestrial",
  country = "NLD", coordinates = "None in source", notes = "From the AHMbook R package (AHM1 9.5.3).")

# =========================================================================================
# 4. Chestnut-sided Warbler removal counts, White Mountain NF 2004
# =========================================================================================
TABLE <- "chandler_2009_wmnf_cswa_removal"
cw <- ahm_data(TABLE, "cswa")
cn <- cw$counts; cv <- as.data.table(cw$covs)
stopifnot(identical(dim(cn), c(43L, 3L, 3L)), identical(dimnames(cn)[[2]], c("int1", "int2", "int3")),
          identical(dimnames(cn)[[3]], c("occ1", "occ2", "occ3")), sum(is.na(cn)) == 3L, all(is.na(cn[12, , 1])),
          sum(cn, na.rm = TRUE) == 75, !anyDuplicated(dimnames(cn)[[1]]), nrow(cv) == 43L,
          sum(is.na(cv[, .(date1, date2, date3)])) == 1L, is.na(cv$date1[12]),
          all(as.Date(unlist(cv[, .(date1, date2, date3)]), origin = "1970-01-01") >= as.Date("2004-05-27"), na.rm = TRUE))
long <- rbindlist(lapply(1:3, function(k) rbindlist(lapply(1:3, function(b)
  data.table(i = 1:43, period = k, occasion = b, y = cn[, b, k])))))[!is.na(y)]
dt <- as.matrix(cv[, .(date1, date2, date3)]); tm <- as.matrix(cv[, .(time1, time2, time3)])
ob <- sapply(cv[, .(obs1, obs2, obs3)], as.character)
long[, `:=`(unit = dimnames(cn)[[1]][i], date = format(as.Date(dt[cbind(i, period)], origin = "1970-01-01")),
            observer = ob[cbind(i, period)], obs_start_hour = tm[cbind(i, period)],
            unit_patch_area_ha = cv$patchArea[i], unit_plot_area_ha = cv$plotArea[i],
            unit_woody_height_m = cv$woodHt[i], unit_woody_cover = cv$woodCov[i], y = as.integer(y))]
stopifnot(nrow(long) == (43L * 3L - 1L) * 3L, !anyNA(long$date))
long <- order_eco(long[, .(unit, taxon = "SETPEN", y, period, occasion, date, observer, unit_patch_area_ha, unit_plot_area_ha,
                           unit_woody_height_m, unit_woody_cover, obs_start_hour)])
periods <- data.table(period = 1:3, visit = 1:3)
taxa <- make_taxa("SETPEN", "Setophaga pensylvanica", vernacularName = "Chestnut-sided warbler", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Chestnut-sided Warbler removal point counts (three time intervals) on 3 visits to 43 points in wildlife openings, White Mountain National Forest, 2004",
  creator = "Chandler, Richard B.; King, David I.; Chandler, Carol C. (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2009", citation = sprintf(PKG_CITE, "cswa"), paperDOI = "10.1016/j.foreco.2009.07.025",
  abstract = "Chestnut-sided Warblers (Setophaga pensylvanica) singing at 43 points in 38 wildlife openings of the White Mountain National Forest, New Hampshire, were counted on three 10-minute visits between late May and July 2004 (one point visited twice), each count split into the intervals 0-2, 2-5 and 5-10 min (removal design). The data are the AHMbook package's cswa (Chandler, King & Chandler 2009; Chandler, Royle & King 2011; AHM2 chapter 2): one row per point x visit x interval, with date, start time, observer and point vegetation.",
  samplingProtocol = "10-min point counts of singing birds, new birds assigned to the interval of first detection (0-2, 2-5, 5-10 min), three visits per point in 2004.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The count array has NA for the one missing visit (point 12, visit 1; also NA date, time and observer); every other point-visit is a survey with three interval cells.",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site",
  closure = "closed", closureNote = "occasion = removal interval of one count; period = the visit (1-3) within the 2004 season",
  occasionKind = "cell", taxonInclusion = "single",
  geographicCoverage = "Wildlife openings in the White Mountain National Forest, New Hampshire and Maine, USA (no point coordinates in the package)",
  temporalCoverage = "2004-05-27/2004-07-09", coordinatesCoarsened = NA,
  notes = "Removal intervals: occasion 1 = (0,2], 2 = (2,5], 3 = (5,10] min. Point ids as in the package (patch name plus a letter where an opening had several points). unit_plot_area_ha: most count areas are 50-m radius, smaller where they overlapped adjacent forest. Dates from the package's days since 1970-01-01.",
  notShipped = list(spotMaps = "spot-mapping territory estimates for the 38 patches: the package gives no key from points to patches (only patch area), so they cannot be joined; they are also derived estimates, not detections")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Chestnut-sided Warbler removal point counts (0-2, 2-5, 5-10 min) on three visits to 43 points in wildlife openings of the White Mountain National Forest, 2004, with observer, date and vegetation (AHMbook::cswa; Chandler et al. 2009).",
  reference = "Chandler, R. B., King, D. I., & Chandler, C. C. (2009). Effects of management regime on the abundance and nest survival of shrubland birds in wildlife openings in northern New England, USA. Forest Ecology and Management, 258, 1669-1676.",
  doi_paper = "10.1016/j.foreco.2009.07.025", doi_data = "",
  notes = "AHMbook package data (GPL). Removal multinomial; period = visit. Spot-map estimates not shipped."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Removal sampling (repeated visits)",
  sampling_protocol = "point_count", design = "Single-season (3 visits x 3 removal intervals)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "From the AHMbook R package (AHM2 2).")

# =========================================================================================
# 5. Eurasian lynx, Swiss and Italian Alps, certain and uncertain records, 1994-2016
# =========================================================================================
TABLE <- "molinarijobin_2012_alps_lynx_fpocc"
lx <- as.data.table(ahm_data(TABLE, "EurasianLynx"))
stopifnot(nrow(lx) == 43332L, identical(levels(lx$type), c("certain", "uncertain")), uniqueN(lx$site.nr) == 942L,
          identical(range(lx$Year), c(1994L, 2016L)), lx[, .N, by = .(site.nr, Year)][, all(N == 2L)],
          lx[, .N, by = .(site.nr, Year, type)][, all(N == 1L)],
          lx[, uniqueN(paste(xcoord, ycoord, Cntry, forest)), by = site.nr][, all(V1 == 1L)],
          all(unlist(lx[, .(y.1, y.2, y.3)]) %in% c(0L, 1L, NA)))
cer <- lx[type == "certain"]; unc <- lx[type == "uncertain"]
m <- merge(cer, unc, by = c("site.nr", "Year"), suffixes = c(".c", ".u"))
stopifnot(nrow(m) == 21666L)
long <- rbindlist(lapply(1:3, function(k) {
  cc <- m[[sprintf("y.%d.c", k)]]; uu <- m[[sprintf("y.%d.u", k)]]
  stopifnot(all(is.na(cc) == is.na(uu)))                                     # both records are missing together
  data.table(site.nr = m$site.nr, Year = m$Year, occasion = k, cc = cc, uu = uu)
}))[!is.na(cc)]
long[, `:=`(y = as.integer(2L * cc + uu), y_raw = paste0(cc, uu))]
site <- unique(lx[, .(site.nr, unit_x_km = xcoord, unit_y_km = ycoord, unit_country = as.character(Cntry), unit_forest_pct = forest)])
long <- merge(long, site, by = "site.nr")
long[, `:=`(unit = sprintf("%04d", site.nr), period = Year - 1993L)]
stopifnot(nrow(long) == 62172L, sum(long$cc) == 2334L, sum(long$uu) == 1090L)
long <- order_eco(long[, .(unit, taxon = "LYNLYN", y, y_raw, period, occasion, unit_x_km, unit_y_km, unit_country, unit_forest_pct)])
periods <- long[, .(n_cells = uniqueN(unit), n_certain = sum(y >= 2L), n_uncertain = sum(y %in% c(1L, 3L))), by = period][order(period)][
  , year := period + 1993L][, .(period, year, n_cells, n_certain, n_uncertain)]
taxa <- make_taxa("LYNLYN", "Lynx lynx", vernacularName = "Eurasian lynx", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Eurasian lynx records per 10-km cell and winter in the Swiss and Italian Alps, confirmed and unconfirmed, 3 occasions a winter, 1994-2016",
  creator = "KORA Foundation (SCALP project); Progetto Lince Italia (Molinari-Jobin, Anja; Breitenmoser, Urs; Zimmermann, Fridolin) (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2012", citation = sprintf(PKG_CITE, "EurasianLynx"), paperDOI = "10.1016/B978-0-12-809585-0.00007-7",
  abstract = "Lynx (Lynx lynx) observations in the Swiss and Italian Alps from the SCALP monitoring (KORA, Progetto Lince Italia), summarised per 10 x 10 km cell and per winter, 1994-2016, for three two-month occasions (Nov-Dec, Jan-Feb, Mar-Apr), and split into records confirmed by experts ('certain') and reports by the public not confirmed ('uncertain', possibly false positives). The data are the AHMbook package's EurasianLynx (Molinari-Jobin et al. 2012; AHM2 7.3.2): one row per cell x winter x occasion, y coding both record types.",
  samplingProtocol = "Opportunistic and structured lynx records (signs, sightings, kills, camera traps) collected by the national monitoring programmes and classified by verification status (SCALP criteria), summarised per 10-km cell and two-month occasion.",
  samplingProtocolCode = "sign_survey", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The package gives each cell-winter one 'certain' and one 'uncertain' record of three occasions, with NA where there are no data; the two are NA together (asserted). A row exists where they are not NA.",
  responseType = "state", unitKind = "site", closure = "closed", closureNote = "period (closed within a winter)",
  occasionKind = "time", taxonInclusion = "single",
  stateCodes = list(`0` = "no lynx record", `1` = "uncertain (unconfirmed) record only", `2` = "certain (expert-confirmed) record only", `3` = "both certain and uncertain records"),
  respRawCodes = list(`00` = "certain 0, uncertain 0", `01` = "certain 0, uncertain 1", `10` = "certain 1, uncertain 0", `11` = "certain 1, uncertain 1"),
  detectionCertainty = "y >= 2: a 'certain' (expert-confirmed) record; y = 1: only 'uncertain' records, which may be false positives",
  geographicCoverage = "The Alps of Switzerland and Italy, 942 cells of 10 x 10 km; cell coordinates in km (unit_x_km, unit_y_km; consistent with ETRS89-LAEA, EPSG:3035, by range, not stated by the source)",
  temporalCoverage = "1994/2016", crs = "km E and N of an unnamed origin; consistent with EPSG:3035 (ETRS89-LAEA) in km, inferred from the range",
  coordinatesCoarsened = list(value = FALSE, method = "10-km cells as published; Lynx lynx is IUCN Least Concern globally"),
  notes = "y combines the two deposited records per occasion: y = 2 x certain + uncertain, y_raw the pair of digits (certain then uncertain), as in ferguson_2015_macon_bawa_fpocc but with both streams kept. Year is the package's winter label (whether 1994 is winter 1993/94 or 1994/95 is not stated). The sampling is partly opportunistic.",
  notShipped = list(none = "nothing: both record types are shipped")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Eurasian lynx records in 942 10-km cells of the Swiss and Italian Alps, three two-month occasions per winter 1994-2016, coded as none / unconfirmed only / confirmed only / both (AHMbook::EurasianLynx; KORA SCALP and Progetto Lince Italia).",
  reference = "Molinari-Jobin, A., Kéry, M., Marboutin, E., Molinari, P., Koren, I., Fuxjäger, C., Breitenmoser-Würsten, C., Wölfl, S., Fasel, M., Kos, I., Wölfl, M., & Breitenmoser, U. (2012). Monitoring in the presence of species misidentification: the case of the Eurasian lynx in the Alps. Animal Conservation, 15, 266-273.",
  doi_paper = "10.1016/B978-0-12-809585-0.00007-7", doi_data = "",
  notes = "AHMbook package data (GPL). False-positive design as a state table (certain / uncertain)."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "False-positive dynamic occupancy",
  sampling_protocol = "sign_survey", design = "Multi-season (23 winters x 3 occasions)", realm = "Terrestrial",
  country = "CHE; ITA", coordinates = "As published (10-km cell centres, km)", notes = "From the AHMbook R package (AHM2 7.3.2).")

# =========================================================================================
# 6. Willow warblers, British Constant Effort Sites, 1986-1996
# =========================================================================================
TABLE <- "kery_2021_britain_willowwarbler_cjs"
ww <- ahm_data(TABLE, "willowWarbler")
b <- as.data.table(ww$birds); yr <- as.character(1986:1996); ces <- as.data.table(ww$CES)
ch <- as.matrix(b[, ..yr])
stopifnot(nrow(b) == 10551L, all(ch %in% 0:1), all(rowSums(ch) >= 1), sum(ch) == 12520, nrow(ces) == 193L,
          all(b$cesID %in% seq_len(193)))
active <- sapply(yr, function(y) tapply(b[[y]], factor(b$cesID, levels = 1:193), sum) > 0)    # CES x year
active[is.na(active)] <- FALSE
stopifnot(sum(active) == 963L)
long <- rbindlist(lapply(seq_len(nrow(b)), function(i) {
  t <- which(active[b$cesID[i], ])
  data.table(i = i, period = t, y = as.integer(ch[i, t]))
}))
stopifnot(sum(long$y) == sum(ch))                                              # every capture is in an operated year
long[, `:=`(unit = sprintf("%05d", i), cluster_id = sprintf("CES%03d", b$cesID[i]),
            unit_ces_easting = ces$cesx[b$cesID[i]], unit_ces_northing = ces$cesy[b$cesID[i]])]
long <- order_eco(long[, .(unit, taxon = "PHYTRO", y, period, cluster_id, unit_ces_easting, unit_ces_northing)])
periods <- data.table(period = 1:11, year = 1986:1996, n_ces_operated = colSums(active), n_birds_caught = colSums(ch))
taxa <- make_taxa("PHYTRO", "Phylloscopus trochilus", vernacularName = "Willow warbler", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Annual capture histories of 10,551 willow warblers at 193 British Constant Effort ringing Sites, 1986-1996",
  creator = "British Trust for Ornithology, Constant Effort Sites scheme (data); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2021", citation = sprintf(PKG_CITE, "willowWarbler"), paperDOI = "10.1016/B978-0-12-809585-0.00003-X",
  abstract = "Willow warblers (Phylloscopus trochilus) mist-netted at 193 Constant Effort Sites of the British Trust for Ornithology in England, Wales and Scotland, 1986-1996, before the species' decline in southern Britain. The data are the AHMbook package's willowWarbler (AHM2 section 3.4): one capture history per bird with its site. One row per bird x year in which its site operated (inferred), y = 1 if the bird was caught.",
  samplingProtocol = "Constant Effort Sites: standardised mist-netting with the same nets at the same places on a fixed number of visits each breeding season; one occasion per year.",
  samplingProtocolCode = "mist_net", surveyEvidence = "inferred",
  surveyEvidenceNote = "CES operation is not in the package. A site is taken as operated in a year iff at least one willow warbler was caught there that year (963 of 2,123 site-years); a year in which a site operated but caught no willow warbler is therefore missing. Each bird has a row in every operated year of its site, from 1986 (age not given: at risk from the study's start, E4.4).",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "period", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "England, Wales and Scotland: 193 Constant Effort Sites, approximate British National Grid easting and northing as unit_ces_easting/northing",
  temporalCoverage = "1986/1996", crs = "British National Grid (EPSG:27700), approximate site positions as given",
  coordinatesCoarsened = list(value = FALSE, method = "site positions approximate (5-km precision) as published; Phylloscopus trochilus is IUCN Least Concern"),
  notes = "cluster_id = Constant Effort Site; each bird belongs to one site. Ages and sexes are not in the package, so juveniles are treated as of unknown age (rows from 1986); users wanting first-capture conditioning drop rows before a bird's first capture. The package's 5-km cell grid and 25-km blocks of Britain (with growing degree days) are prediction covariates, not shipped.",
  notShipped = list(cells_blocks = "5-km cells and 25-km blocks covering Britain with growing degree days: prediction grid, not survey data")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Annual capture histories of 10,551 willow warblers at 193 British Constant Effort Sites, 1986-1996, with site positions; site operation inferred from captures (AHMbook::willowWarbler; BTO).",
  reference = AHM2, doi_paper = "10.1016/B978-0-12-809585-0.00003-X", doi_data = "",
  notes = "AHMbook package data (GPL). CJS; site-years operated inferred from any willow warbler capture."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "mist_net", design = "Multi-season (11 annual occasions, 193 sites)", realm = "Terrestrial",
  country = "GBR", coordinates = "As published (approximate site positions)", notes = "From the AHMbook R package (AHM2 3.4).")

# =========================================================================================
# 7. Middle Spotted Woodpecker checklists, Switzerland, 1990-2015 (binomial counts)
# =========================================================================================
TABLE <- "kery_2021_swiss_mspwoodpecker_binom"
sw <- as.data.table(ahm_data(TABLE, "spottedWoodpecker"))
stopifnot(nrow(sw) == 116204L, !anyDuplicated(sw[, .(site, year, jdate)]), all(sw$y >= 0 & sw$y <= sw$nsurvey),
          all(sw$nsurvey >= 1), sum(sw$nsurvey) == 144517L, uniqueN(sw$site) == 1545L, identical(range(sw$year), c(1990L, 2015L)),
          identical(range(sw$jdate), c(51L, 212L)), sw[, uniqueN(paste(coordx, coordy)), by = site][, all(V1 == 1L)])
days <- unique(sw[, .(year, jdate)])[order(year, jdate)][, period := .I]
stopifnot(nrow(days) == 4207L)
long <- merge(sw, days, by = c("year", "jdate"))
long <- long[, .(unit = sprintf("%04d", site), taxon = "LEIMED", y = as.integer(y), period, date = iso(year, jdate),
                 unit_x_unspecified_crs = coordx, unit_y_unspecified_crs = coordy, obs_trials = as.integer(nsurvey))]
long <- order_eco(long)
periods <- days[, .(period, year, day_of_year = jdate, date = iso(year, jdate))]
taxa <- make_taxa("LEIMED", "Leiopicus medius", vernacularName = "Middle spotted woodpecker", taxon_iucnCategory = "LC")
dataset <- c(common, list(
  title = "Middle Spotted Woodpecker on volunteer checklists per 1-km2 quadrat and day in Switzerland, 20 February-31 July, 1990-2015",
  creator = "Swiss Ornithological Institute (data, courtesy of Nicolas Strebel); Kéry, Marc; Royle, J. Andrew (distributed in the AHMbook R package)",
  pubDate = "2021", citation = sprintf(PKG_CITE, "spottedWoodpecker"), paperDOI = "10.1016/B978-0-12-809585-0.00004-1",
  abstract = "Checklists submitted by volunteers to the Swiss Ornithological Institute, summarised per 1-km2 quadrat and day between 20 February and 31 July (days 51-212) of 1990-2015: the number of checklists and the number on which a Middle Spotted Woodpecker (Leiopicus medius) was recorded. 144,517 checklists on 116,204 quadrat-days from the 1,545 quadrats where the species was ever recorded since 1985. The data are the AHMbook package's spottedWoodpecker (AHM2 section 4.11.2): one row per quadrat-day, y = checklists with the species out of obs_trials.",
  samplingProtocol = "Volunteer bird checklists (complete lists of species seen on a trip) summarised by the source to quadrat and day.",
  samplingProtocolCode = "visual_survey", surveyEvidence = "row_presence",
  surveyEvidenceNote = "Each row of the package is a quadrat-day with at least one checklist; a quadrat-day without one is absent and not surveyed.",
  responseType = "binomial_count", effortColumn = "obs_trials", unitKind = "site",
  closure = "none", closureNote = "period = calendar day (index over the 4,207 dates with a checklist anywhere; __periods gives year and day); a seasonal or annual model groups periods by __periods$year",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Switzerland, 1,545 1-km2 quadrats; coordinates in an unspecified reference system (unit_x_unspecified_crs, unit_y_unspecified_crs)",
  temporalCoverage = "1990/2015", coordinatesCoarsened = list(value = FALSE, method = "no locations shipped: the source's coordinates have an unspecified reference system and ship as covariates"),
  notes = "Selection: only quadrats where the species was recorded at least once since 1985 are included (help page). Checklists are opportunistic: obs_trials varies widely and checklist completeness is not recorded. The help page's 26 years run 1990-2015.",
  notShipped = list(none = "nothing: the data frame is shipped whole")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
do.call(stage_dict_row, c(list(TABLE,
  description = "Number of volunteer checklists reporting the Middle Spotted Woodpecker out of all checklists per 1-km2 quadrat and day, Switzerland, 20 Feb-31 Jul 1990-2015, at the 1,545 quadrats where it was ever recorded (AHMbook::spottedWoodpecker).",
  reference = AHM2, doi_paper = "10.1016/B978-0-12-809585-0.00004-1", doi_data = "",
  notes = "AHMbook package data (GPL). binomial_count per quadrat-day; quadrats conditioned on detection."), dict_common))
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy (binomial counts)",
  sampling_protocol = "visual_survey", design = "Multi-season (26 years, daily checklist summaries)", realm = "Terrestrial",
  country = "CHE", coordinates = "As published (unspecified CRS, shipped as covariates)", notes = "From the AHMbook R package (AHM2 4.11.2).")
