#!/usr/bin/env Rscript
# Tables: rich_2019_mojave_mamm_binom, rich_2019_mojave_birds_binom
# Source: Dryad doi:10.5061/dryad.2806394 (CC0 1.0, as shown on the Dryad page; published
#         2019-06-26). Rich, L.N., Furnas, B.J., Newton, D.S. & Brashares, J.S. Data from:
#         Acoustic and camera surveys inform models of current and future vertebrate
#         distributions in a changing desert ecosystem.
# Paper:  Rich, L.N., Furnas, B.J., Newton, D.S. & Brashares, J.S. (2019). Diversity and
#         Distributions 25(7), doi:10.1111/ddi.12952. Camera traps and acoustic recorders at 210
#         sites in the Mojave Desert, California, March to July 2016; multispecies occupancy.
#         The abstract reports 15 mammal and 68 songbird species detected.
# Data:   DD_data_for_dryad.xlsx (deposited twice under one name; one file read), four sheets:
#         DH_Mammals (210 StudySite x num.nights (camera nights, 26-64) + 15 species: nights
#         with a detection, 0..49, never above num.nights); DH_Birds (210 x num.nights (= 9
#         recording nights at every site) + 44 species: nights with a detection 0..9);
#         Covariates (210 sites: slope, distance to water / pinyon-juniper / developed area
#         (km), maximum temperature (C), human impact (1-7), Julian day and its square,
#         background noise (1-4)); SpeciesCodes (code -> common name; scientific names are the
#         processor's, from the common names, and GBIF-matched). No coordinates, no dates.
#         44 bird species are deposited against the abstract's 68 detected; the deposit does
#         not say how the 44 were chosen.
# Mapping (ruling #34, binomial_count; E9 community occupancy): two tables, one per method
#   (camera / acoustic: "two methods are two tables"). unit = StudySite; taxon = species code;
#   no occasion; y = nights with a detection; obs_trials = num.nights (effortColumn). Every
#   site carries a row for every deposited species (complete matrices, no NA).
#   unit_: the covariates (Julian day and background noise are site-level summaries as
#   deposited). Survey evidence: deposited_matrix (counts + nights surveyed per site).
#   Not shipped: Julian day squared (a recode of Julian day).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/rich_2019_mojave_binom.R"
dir <- download_dryad("10.5061/dryad.2806394", "rich_2019_mojave_binom")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^DD_data_for_dryad\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]; stopifnot(!is.na(f))
suppressMessages(library(readxl))
rd <- function(s) as.data.table(suppressMessages(read_excel(f, s)))
cv <- rd("Covariates")
stopifnot(nrow(cv) == 210, !anyDuplicated(cv$StudySite), !anyNA(cv),
          isTRUE(all.equal(cv$`Julian day`^2, cv$`Julian day²`, tolerance = 1e-6)))
ucov <- cv[, .(unit = as.character(StudySite), unit_slope = Slope, unit_dist_water_km = `Distance to water (km)`,
               unit_dist_pinyon_juniper_km = `Distance to pinyon juniper (km)`, unit_max_temp_c = `Maximum temperature (°C)`,
               unit_dist_developed_km = `Distance to developed area (km)`, unit_human_impact = `Human impact`,
               unit_julian_day = `Julian day`, unit_background_noise = `Background noise`)]
MAM <- c(CANLAT = "Canis latrans", DIDVIR = "Didelphis virginiana", LEPCAL = "Lepus californicus", LYNRUF = "Lynx rufus",
         MEPMEP = "Mephitis mephitis", ODOHEM = "Odocoileus hemionus", OTOBEE = "Otospermophilus beecheyi",
         OTOVAR = "Otospermophilus variegatus", OVICAN = "Ovis canadensis", PROLOT = "Procyon lotor",
         SPIGRA = "Spilogale gracilis", SYLAUD = "Sylvilagus audubonii", TAXTAX = "Taxidea taxus",
         UROCIN = "Urocyon cinereoargenteus", VULMAC = "Vulpes macrotis")
BIRD <- c(ATFL = "Myiarchus cinerascens", BESP = "Artemisiospiza belli", BETH = "Toxostoma bendirei", BEVI = "Vireo bellii",
          BEWR = "Thryomanes bewickii", BGGN = "Polioptila caerulea", BHCO = "Molothrus ater", BLGR = "Passerina caerulea",
          BRBL = "Euphagus cyanocephalus", BRSP = "Spizella breweri", BTGN = "Polioptila melanura", BTSP = "Amphispiza bilineata",
          BUOR = "Icterus bullockii", BUSH = "Psaltriparus minimus", CACW = "Campylorhynchus brunneicapillus",
          CAKI = "Tyrannus vociferans", CANW = "Catherpes mexicanus", COHU = "Calypte costae", COPO = "Phalaenoptilus nuttallii",
          CORA = "Corvus corax", COYE = "Geothlypis trichas", CRTH = "Toxostoma crissale", EUCD = "Streptopelia decaocto",
          GRRO = "Geococcyx californianus", HOFI = "Haemorhous mexicanus", HOLA = "Eremophila alpestris",
          LBWO = "Dryobates scalaris", LENI = "Chordeiles acutipennis", LETH = "Toxostoma lecontei", LOSH = "Lanius ludovicianus",
          MODO = "Zenaida macroura", NOFL = "Colaptes auratus", NOMO = "Mimus polyglottos", PHAI = "Phainopepla nitens",
          RCSP = "Aimophila ruficeps", ROWR = "Salpinctes obsoletus", RWBL = "Agelaius phoeniceus", SAPH = "Sayornis saya",
          SCOR = "Icterus parisorum", VERD = "Auriparus flaviceps", WEKI = "Tyrannus verticalis", WESJ = "Aphelocoma californica",
          WTSW = "Aeronautes saxatalis", WWDO = "Zenaida asiatica")
sc <- as.data.table(suppressMessages(read_excel(f, "SpeciesCodes", col_names = FALSE)))
vern <- c(setNames(sc[[2]], sc[[1]]), setNames(sc[[6]], sc[[5]]))
stopifnot(all(names(MAM) %in% names(vern)), all(names(BIRD) %in% names(vern)))

mk <- function(sheet, sp, table, n_sp, kind) {
  d <- rd(sheet)
  stopifnot(nrow(d) == 210, setequal(d$StudySite, cv$StudySite), identical(names(d), c("StudySite", "num.nights", names(sp))),
            length(sp) == n_sp)
  M <- as.matrix(d[, names(sp), with = FALSE])
  stopifnot(!anyNA(M), all(M >= 0), all(M <= d$num.nights), all(colSums(M) > 0))
  long <- melt(d, id.vars = c("StudySite", "num.nights"), variable.name = "taxon", value.name = "y", variable.factor = FALSE)
  long <- long[, .(unit = as.character(StudySite), taxon, y = as.integer(y), obs_trials = as.integer(num.nights))]
  long <- order_eco(merge(long, ucov, by = "unit"))
  stopifnot(nrow(long) == 210 * n_sp, sum(long$y) == sum(M))
  taxa <- make_taxa(names(sp), unname(sp), vernacularName = unname(vern[names(sp)]))
  list(long = long, taxa = taxa, nights = range(d$num.nights), det = sum(M))
}
TB <- list(
  mamm = c(mk("DH_Mammals", MAM, "rich_2019_mojave_mamm_binom", 15, "camera"), table = "rich_2019_mojave_mamm_binom", what = "15 mammal species",
           proto = "Unbaited camera traps at 210 sites, one deployment per site (26-64 nights), March to July 2016; mammals identified to species from photographs; detections collapsed by the authors to nights with a detection per site and species.",
           code = "camera_trap", grp = "Mammals"),
  birds = c(mk("DH_Birds", BIRD, "rich_2019_mojave_birds_binom", 44, "acoustic"), table = "rich_2019_mojave_birds_binom", what = "44 songbird species",
            proto = "Acoustic recorders at the same 210 sites, nine recording nights' mornings per site, March to July 2016; songbirds identified to species from recordings; detections collapsed by the authors to nights with a detection per site and species.",
            code = "acoustic", grp = "Birds"))
for (k in names(TB)) {
  b <- TB[[k]]
  dataset <- list(
    title = sprintf("%s detections of %s at 210 Mojave Desert sites, California, 2016: nights with a detection out of nights surveyed", if (k == "mamm") "Camera-trap" else "Acoustic", b$what),
    creator = "Rich, Lindsey N.; Furnas, Brett J.; Newton, D. Scott; Brashares, Justin S.", pubDate = "2019",
    doi = "10.5061/dryad.2806394", sourceURL = "https://doi.org/10.5061/dryad.2806394",
    citation = "Rich, L. N., Furnas, B. J., Newton, D. S., & Brashares, J. S. (2019). Data from: Acoustic and camera surveys inform models of current and future vertebrate distributions in a changing desert ecosystem [Dataset]. Dryad. https://doi.org/10.5061/dryad.2806394",
    paperDOI = "10.1111/ddi.12952",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("%s survey of %s at 210 sites in the Mojave Desert, California, March to July 2016 (Rich et al. 2019): the number of nights with a detection out of the nights surveyed per site and species, with seven site covariates.", if (k == "mamm") "Camera-trap" else "Acoustic", b$what),
    samplingProtocol = b$proto, samplingProtocolCode = b$code, surveyEvidence = "deposited_matrix",
    surveyEvidenceNote = "Every site has an explicit count for every deposited species and its nights surveyed (num.nights); which nights were surveyed is not deposited, so there is no occasion column (ruling #34).",
    effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
    closure = "none", closureNote = "single season; one deployment per site, which the authors analysed as single-season multispecies occupancy",
    occasionKind = "none", taxonInclusion = "recorded",
    geographicCoverage = "Mojave Desert, California, USA; no coordinates deposited", temporalCoverage = "2016-03/2016-07",
    notShipped = c(list(`Julian day squared` = "the square of Julian day (asserted), a model term"),
                   if (k == "birds") list(`other songbirds` = "the abstract reports 68 songbird species detected; 24 are not in the deposit (the source's cut, not stated)") else list()),
    notes = paste0(if (k == "birds") "The abstract reports 68 songbird species detected; the deposit holds 44, and does not say how they were chosen. " else "",
                   "Scientific names are the processor's, from the deposited common names (SpeciesCodes sheet). Julian day and background noise are site-level values as deposited (non-integer Julian days suggest a mean over visits). The other table from this deposit is ",
                   if (k == "mamm") "rich_2019_mojave_birds_binom (acoustic)." else "rich_2019_mojave_mamm_binom (camera)."))
  ds <- write_table(b$long, b$table, dataset, taxa = b$taxa, script = SCRIPT)
  stage_dict_row(b$table,
    description = sprintf("%s nights-with-detection out of nights surveyed for %s at 210 Mojave Desert sites, California, 2016, with site covariates.", if (k == "mamm") "Camera-trap" else "Acoustic", b$what),
    url = "https://doi.org/10.5061/dryad.2806394",
    reference = "Rich, L. N., Furnas, B. J., Newton, D. S., & Brashares, J. S. (2019). Acoustic and camera surveys inform models of current and future vertebrate distributions in a changing desert ecosystem. Diversity and Distributions, 25(7).",
    doi_paper = "10.1111/ddi.12952", doi_data = "10.5061/dryad.2806394", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "binomial_count (ruling #34); one of two method tables from this deposit.", source_via = "Dryad")
  stage_tag_row(b$table, ds, taxon_group = b$grp, model_family = "Community occupancy (single season, binomial counts)",
    sampling_protocol = b$code, design = "Single-season (210 sites, nights collapsed to binomial counts)", realm = "Terrestrial",
    country = "USA", coordinates = "None in source", notes = "binomial_count (ruling #34).")
}
