#!/usr/bin/env Rscript
# Table:  jimenezfranco_2019_murcia_birds_binom
# Source: Dryad doi:10.5061/dryad.8sf5v66 (CC0 1.0, as shown on the Dryad page; version 16393).
#         Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Robledano, F., Esteve, M. A. & Calvo, J. F.
#         Data from: Use of classical bird census transects as spatial replicates for hierarchical
#         modeling of an avian community.
# Paper:  Jiménez-Franco, M. V. et al. (2019). Ecology and Evolution 9(3), 825-835,
#         doi:10.1002/ece3.4829 (open access, PMC6362445). 377 one-km bird transects walked once
#         each in Mediterranean forest across the region of Murcia (SE Spain) in the breeding
#         seasons (May-July) of 1991 and 1992, every species seen or heard recorded; the transects
#         grouped as spatial replicates into grid cells of 60 x 60 seconds (AS2x2: 246 cells, 1-5
#         transects each) or 90 x 90 seconds (AS3x3: 185 cells, 1-7 transects).
#         Supporting Information (ece34829-sup-0002-SupInfo) Table S1: the 73 species, numbered,
#         with scientific (Calvo et al. 2017 nomenclature) and common names; the deposit's species
#         codes are not expanded anywhere else.
# Data:   "Avian community data.zip" holding two RData files, one per aggregation scheme, each with
#         Ysum (data frame, cells x 73 species: transects in the cell on which the species was
#         recorded), J (transects per cell), forest, temp, prec (standardised CORINE 1990 forest
#         cover, WorldClim 1960-1990 annual mean temperature and precipitation, per cell).
#         Quirks: the species columns are six-letter codes (genus3 + epithet3) in an older
#         taxonomy and NOT in Table S1 order (e.g. Chlchl and Ccocor sit at columns 10 and 11), so
#         they are mapped by code: 68 by genus3 + epithet3 of the Table S1 name, five by hand
#         (Ccocor = Corvus corax, Corcor = Corvus corone, Emccir = Emberiza cirlus (typo), Galsp. = Galerida
#         cristata/theklae, Lopcris = Lophophanes cristatus). Corcor vs Ccocor (Corvus corone / corax) is fixed by the authors' 2023
#         deposit (doi:10.5061/dryad.j9kd51chz), which has the same 73 columns in the same order
#         with Ccorax at column 11. Cells are numbered 1-246; no coordinates are deposited.
# Mapping (E2 binomial_count, ruling #34): unit = AS2x2 grid cell (cell number as deposited),
#   taxon = the deposit's code (Galsp. without the dot), y = transects with the species out of
#   obs_trials = J; no occasion, no period (one breeding-season survey per transect, 1991-1992,
#   transect dates not deposited). unit_forest_cover_z, unit_temp_mean_z, unit_precip_z as
#   deposited (standardised). Survey evidence: effort_table (J > 0 for every cell; every species
#   column is filled for every cell, all transects recording every species seen or heard).
#   Not shipped: AS3x3 (the same 377 transects in coarser cells: the same detections, asserted
#   to sum to the same total). No coordinates in the source, so nothing to coarsen (Streptopelia
#   turtur and Lanius meridionalis are IUCN VU).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "jimenezfranco_2019_murcia_birds_binom"
dir <- download_dryad("10.5061/dryad.8sf5v66", "jimenezfranco_2019_murcia_birds")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(identical(list.files(dir), "Avian community data.zip"))
ex <- file.path(dirname(dir), "unzipped"); dir.create(ex, showWarnings = FALSE)
unzip(file.path(dir, "Avian community data.zip"), exdir = ex)
ld <- function(f) { e <- new.env(); load(file.path(ex, f), envir = e); e }
a2 <- ld("Avian community data AS2x2.RData"); a3 <- ld("Avian community data AS3x3.RData")

# --- source facts ---------------------------------------------------------------------------
for (e in list(a2, a3)) stopifnot(setequal(ls(e), c("forest", "J", "prec", "temp", "Ysum")), ncol(e$Ysum) == 73,
                                  !anyNA(e$Ysum), all(as.matrix(e$Ysum) <= e$J), all(e$J >= 1), all(as.matrix(e$Ysum) >= 0))
stopifnot(nrow(a2$Ysum) == 246, nrow(a3$Ysum) == 185, sum(a2$J) == 377, sum(a3$J) == 377,
          identical(names(a2$Ysum), names(a3$Ysum)), sum(a2$Ysum) == sum(a3$Ysum), sum(a2$Ysum) == 4886,
          identical(as.integer(table(a2$J)), c(148L, 71L, 22L, 4L, 1L)), identical(rownames(a2$Ysum), as.character(1:246)),
          length(a2$forest) == 246, length(a2$temp) == 246, length(a2$prec) == 246, !anyNA(c(a2$forest, a2$temp, a2$prec)))
stopifnot(all(colSums(a2$Ysum) > 0))

# --- Table S1 (Supporting Information, doi:10.1002/ece3.4829), species 1-73 in order -----------
s1 <- matrix(c(
  "Aegithalos caudatus", "Long-tailed Tit",
  "Alauda arvensis", "Eurasian Skylark",
  "Alectoris rufa", "Red-legged Partridge",
  "Anthus campestris", "Tawny Pipit",
  "Athene noctua", "Little Owl",
  "Calandrella brachydactyla", "Greater Short-toed Lark",
  "Calandrella rufescens", "Lesser Short-toed Lark",
  "Carduelis cannabina", "Common Linnet",
  "Carduelis carduelis", "European Goldfinch",
  "Certhia brachydactyla", "Short-toed Treecreeper",
  "Cettia cetti", "Cetti's Warbler",
  "Chloris chloris", "European Greenfinch",
  "Clamator glandarius", "Great Spotted Cuckoo",
  "Columba livia", "Rock Dove",
  "Columba oenas", "Stock Dove",
  "Columba palumbus", "Common Wood Pigeon",
  "Coracias garrulus", "European Roller",
  "Corvus corax", "Northern Raven",
  "Corvus corone", "Carrion Crow",
  "Corvus monedula", "Western Jackdaw",
  "Coturnix coturnix", "Common Quail",
  "Cuculus canorus", "Common Cuckoo",
  "Cyanistes caeruleus", "Blue Tit",
  "Dendrocopos major", "Great Spotted Woodpecker",
  "Emberiza calandra", "Corn Bunting",
  "Emberiza cia", "Rock Bunting",
  "Emberiza cirlus", "Cirl Bunting",
  "Erithacus rubecula", "European Robin",
  "Erythropygia galactotes", "Rufous-tailed Scrub Robin",
  "Ficedula hypoleuca", "European Pied Flycatcher",
  "Fringilla coelebs", "Common Chaffinch",
  "Galerida cristata/theklae", "Crested/Thekla Lark",
  "Garrulus glandarius", "Eurasian Jay",
  "Hippolais polyglotta", "Melodious Warbler",
  "Lanius meridionalis", "Southern Grey Shrike",
  "Lanius senator", "Woodchat Shrike",
  "Lophophanes cristatus", "European Crested Tit",
  "Loxia curvirostra", "Red Crossbill",
  "Lullula arborea", "Woodlark",
  "Luscinia megarhynchos", "Common Nightingale",
  "Melanocorypha calandra", "Calandra Lark",
  "Monticola solitarius", "Blue Rock Thrush",
  "Motacilla alba", "White Wagtail",
  "Motacilla cinerea", "Grey Wagtail",
  "Muscicapa striata", "Spotted Flycatcher",
  "Oenanthe hispanica", "Black-eared Wheatear",
  "Oenanthe leucura", "Black Wheatear",
  "Oenanthe oenanthe", "Northern Wheatear",
  "Oriolus oriolus", "Eurasian Golden Oriole",
  "Parus major", "Great Tit",
  "Passer domesticus", "House Sparrow",
  "Periparus ater", "Coal Tit",
  "Petronia petronia", "Rock Sparrow",
  "Phoenicurus ochruros", "Black Redstart",
  "Phylloscopus bonelli", "Western Bonelli's Warbler",
  "Phylloscopus collybita", "Common Chiffchaff",
  "Pica pica", "Common Magpie",
  "Picus sharpei", "Iberian Green Woodpecker",
  "Pyrrhocorax pyrrhocorax", "Red-billed Chough",
  "Saxicola torquatus", "Common Stonechat",
  "Serinus serinus", "European Serin",
  "Streptopelia turtur", "European Turtle Dove",
  "Sturnus unicolor", "Spotless Starling",
  "Sylvia borin", "Garden Warbler",
  "Sylvia cantillans", "Subalpine Warbler",
  "Sylvia conspicillata", "Spectacled Warbler",
  "Sylvia hortensis", "Western Orphean Warbler",
  "Sylvia melanocephala", "Sardinian Warbler",
  "Sylvia undata", "Dartford Warbler",
  "Troglodytes troglodytes", "Winter Wren",
  "Turdus merula", "Common Blackbird",
  "Turdus viscivorus", "Mistle Thrush",
  "Upupa epops", "Hoopoe"
), ncol = 2, byrow = TRUE, dimnames = list(NULL, c("sci", "common")))
s1 <- as.data.table(s1)[, n := .I]
stopifnot(nrow(s1) == 73, !anyDuplicated(s1$sci), s1[n == 32, sci] == "Galerida cristata/theklae")
codes <- names(a2$Ysum)
auto <- with(s1, paste0(substr(sci, 1, 3), substr(sub("^\\S+ ", "", sci), 1, 3)))
hand <- c(Ccocor = "Corvus corax", Corcor = "Corvus corone", Emccir = "Emberiza cirlus", `Galsp.` = "Galerida cristata/theklae", Lopcris = "Lophophanes cristatus")
# genus3 + epithet3 is ambiguous only for Corvus corax / corone (both "Corcor"): those go by hand
stopifnot(identical(auto[duplicated(auto) | duplicated(auto, fromLast = TRUE)], c("Corcor", "Corcor")))
sci_of <- setNames(s1$sci[match(tolower(codes), tolower(auto))], codes); sci_of["Corcor"] <- NA
stopifnot(sum(!is.na(sci_of)) == 68, setequal(names(sci_of)[is.na(sci_of)], names(hand)))
sci_of[names(hand)] <- hand
stopifnot(!anyNA(sci_of), !anyDuplicated(sci_of), setequal(sci_of, s1$sci))
stopifnot(sci_of[["Corcor"]] == "Corvus corone")
# the authors' 2023 deposit has the same columns in the same order, with unambiguous Ccorax at 11
d23 <- download_dryad("10.5061/dryad.j9kd51chz", "jimenezfranco_2023_murcia_birds")
e23 <- new.env(); load(file.path(d23, "BirdsCC_Historical_period.RData"), envir = e23)
c23 <- colnames(e23$bdata$Ysum); diff <- which(codes != c23)
stopifnot(length(c23) == 73, identical(diff, c(10L, 11L, 13L, 27L, 48L, 49L, 50L, 58L)), c23[11] == "Ccorax", codes[11] == "Ccocor")

# --- long table --------------------------------------------------------------------------------
Y <- as.matrix(a2$Ysum); code <- sub("\\.$", "", codes)
long <- data.table(unit = rep(sprintf("C%03d", 1:246), times = 73), taxon = rep(code, each = 246),
                   y = as.integer(c(Y)), obs_trials = as.integer(rep(a2$J, times = 73)),
                   unit_forest_cover_z = rep(a2$forest, 73), unit_temp_mean_z = rep(a2$temp, 73), unit_precip_z = rep(a2$prec, 73))
long <- order_eco(long)
stopifnot(nrow(long) == 246 * 73, sum(long$y) == 4886, all(long$y <= long$obs_trials))

# --- taxa ---------------------------------------------------------------------------------------
sci <- unname(sci_of); common <- s1$common[match(sci, s1$sci)]
gal <- code == "Galsp"
taxa <- make_taxa(code, sci, vernacularName = common, lookupName = ifelse(gal, "Galerida", sci),
                  taxonRank = ifelse(gal, "genus", "species"),
                  taxonRemarks = ifelse(gal, "Galerida cristata and G. theklae, not separated by the source (Table S1 no. 32)",
                                 ifelse(code == "Ccocor", "Corvus corax; the deposit's code (Corcor is Corvus corone)",
                                 ifelse(code == "Emccir", "Emberiza cirlus; the deposit's code as spelt",
                                 ifelse(code == "Chlchl", "homonym on the GBIF backbone; key set below by a hinted match", NA_character_)))),
                  allow_higher = "Galsp", no_key = "Chlchl")
# Chloris is also a grass genus: the unhinted match fails; matched with class Aves as a hint and
# accepted only when GBIF returns the greenfinch itself
h <- gbif_taxon_hinted("Chloris chloris", list(kingdom = "Animalia", class = "Aves"))
stopifnot(identical(h$canonicalName, "Chloris chloris"), identical(h$rank, "species"), identical(h$kingdom, "Animalia"))
taxa[taxon == "Chlchl", `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"),
                             taxonRemarks = "Chloris chloris; a homonym with the grass genus Chloris on the GBIF backbone, matched with class Aves as a hint")]
taxa[, taxon_tableS1 := s1$n[match(sci, s1$sci)]]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
invisible(taxa[gbifMatchType != "EXACT" | !is.na(gbifAcceptedName) | is.na(taxon_iucnCategory) | taxon_iucnCategory %in% c("CR", "EN", "VU"),
           .(taxon, scientificName, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
# seven keys whose backbone name differs from IUCN's (Curruca, Coloeus, Cercotrichas): iucn_category()
# cannot confirm the assessed name and returns NA; GBIF's IUCN record for each key gives these codes
syn <- c(Erygal = "LC", Cormon = "LC", Sylcan = "LC", Sylcon = "LC", Sylhor = "LC", Sylmel = "LC", Sylund = "NT")
stopifnot(setequal(taxa[is.na(taxon_iucnCategory), taxon], names(syn)))
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := syn[taxon]]
stopifnot(identical(sort(taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]), c("Lanmer", "Strtur")))
stopifnot(!any(kingdom_taxonID(taxa$taxonID)))

dataset <- list(
  title = "Forest birds on 377 one-km transects grouped into 246 grid cells in Murcia, south-east Spain, 1991-1992: transects with the species out of transects walked (binomial counts)",
  creator = "Jiménez-Franco, María V.; Kéry, Marc; León-Ortega, Mario; Robledano, Francisco; Esteve, Miguel A.; Calvo, José F.",
  pubDate = "2019", doi = "10.5061/dryad.8sf5v66", sourceURL = "https://doi.org/10.5061/dryad.8sf5v66",
  citation = "Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Robledano, F., Esteve, M. A., & Calvo, J. F. (2019). Data from: Use of classical bird census transects as spatial replicates for hierarchical modeling of an avian community [Dataset]. Dryad. https://doi.org/10.5061/dryad.8sf5v66",
  paperDOI = "10.1002/ece3.4829",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Breeding-bird transects of a 1991-1992 forestry plan in the region of Murcia (south-east Spain): 377 one-km transects in Mediterranean forest, each walked once in May-July with every species seen or heard recorded, grouped by the authors into 246 grid cells of 60 x 60 seconds (1-5 transects per cell) as spatial replicates. For each cell and each of 73 species (Table S1), the number of the cell's transects on which the species was recorded, out of the transects in the cell (binomial_count), with standardised forest cover, mean annual temperature and annual precipitation per cell.",
  samplingProtocol = "1-km line transects walked once each in the breeding season (May-July) of 1991 or 1992, recording every bird species seen or heard; transects grouped into 60 x 60 second grid cells, each transect a spatial replicate of its cell (Jiménez-Franco et al. 2019, Methods 2.2-2.3).",
  samplingProtocolCode = "line_transect", surveyEvidence = "effort_table",
  surveyEvidenceNote = "J (transects per cell, 1-5, summing to 377) is deposited for every cell; every species column is filled for every cell, so a species not recorded in a cell is y = 0 out of J.",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "no occasion column (binomial_count): the replicates are transects within a cell (spatial), walked in the breeding seasons of 1991 and 1992 and treated by the authors as one closed survey",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Region of Murcia, south-east Spain (about 37.4-38.8 N, 0.7-2.3 W): forested areas; cell coordinates not deposited",
  temporalCoverage = "1991/1992",
  notShipped = list(AS3x3 = "the same 377 transects grouped into 185 cells of 90 x 90 seconds (the same 4,886 detections, coarser cells)",
                    transects = "transect-level records and positions are not in the deposit"),
  notes = "Species codes are the deposit's six-letter codes (old taxonomy); __taxa gives Table S1's names and numbers. The columns are not in Table S1 order and were mapped by code (five by hand, see the script). Covariates (suffix _z) are standardised as deposited. Streptopelia turtur and Lanius meridionalis are IUCN VU; the source deposits no coordinates. The authors' later deposit doi:10.5061/dryad.j9kd51chz uses the same transects with a modern resurvey.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/jimenezfranco_2019_murcia_birds_binom.R")
stage_dict_row(TABLE,
  description = "Breeding forest birds on 377 one-km transects (1991-1992) in the region of Murcia, Spain, grouped into 246 grid cells: transects with the species out of transects per cell, 73 species, with standardised forest cover and climate.",
  url = "https://doi.org/10.5061/dryad.8sf5v66",
  reference = "Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Robledano, F., Esteve, M. A., & Calvo, J. F. (2019). Use of classical bird census transects as spatial replicates for hierarchical modeling of an avian community. Ecology and Evolution, 9(3), 825-835.",
  doi_paper = "10.1002/ece3.4829", doi_data = "10.5061/dryad.8sf5v66",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "binomial_count (ruling #34); transects as spatial replicates of AS2x2 cells. Species codes expanded from Supporting Information Table S1 (fetched by Ben, 2026-11-11). AS3x3 not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (spatial replicates, binomial counts)",
  sampling_protocol = "line_transect", design = "Single-season (1991-1992 breeding seasons; transects as spatial replicates within grid cells)",
  realm = "Terrestrial", country = "ESP", coordinates = "None in source", notes = "Mediterranean forest bird community.", status = "tagged")
