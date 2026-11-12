#!/usr/bin/env Rscript
# Table:  jimenezfranco_2023_murcia_birds_binom
# Source: Dryad doi:10.5061/dryad.j9kd51chz (CC0 1.0, as shown on the Dryad page; published 2023-10-27,
#         version 262146). Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Martínez-Ródenas, J.,
#         Robledano, F., Esteve, M. A. & Calvo, J. F. Data from: Evaluating temporal turnover in avian
#         species richness in a Mediterranean semiarid region: different responses to elevation and
#         forest cover.
# Paper:  Jiménez-Franco, M. V. et al. (2024). Diversity and Distributions 30(1), 106-118,
#         doi:10.1111/ddi.13791 (CC BY 4.0; PDF and Supporting Information supplied by Ben 2026-11-12).
#         Breeding forest birds of the region of Murcia (SE Spain) in two periods: a historical survey
#         (1991-1992, 377 one-km transects, the transects of Jiménez-Franco et al. 2019) and a modern
#         survey (2012 and 2017, 198 one-km transects walked by M. León-Ortega or J. Martínez-Ródenas
#         "with a similar protocol"), each transect walked once in May-July recording every species seen
#         or heard. Transects are grouped as spatial replicates into 2 x 2 km grid cells: 226 historical,
#         139 modern. "The locations of the transects between both periods have different spatial
#         coordinates" (Methods 2.2): the periods are separate samples, not a resurvey of the same units.
# Data:   BirdsCC_Historical_period.RData (bdata) and BirdsCC_Modern_period.RData (bdata2), each a
#         list: Ysum (cells x species, transects in the cell with the species), nsite, nrep
#         (transects per cell), nspec, forest and alt (standardised CORINE forest cover and elevation
#         per cell); README.md. Cells are numbered within each file; no coordinates.
#         Species are six-letter codes. The historical file's 73 columns are the 2019 deposit's
#         (dryad.8sf5v66) in the same order, eight respelt (Carchl, Ccorax, Cergal, Embcir, Parate,
#         Parcae, Parcri, Picvir for Chlchl, Ccocor, Erygal, Emccir, Perate, Cyacae, Lopcris, Picsha);
#         the modern file has those 73 in the same order plus four (Bucgit, Regign, Strdec, Sylatr),
#         which the paper names: "Bucanetes githagineus, Regulus ignicapilla, Streptopelia decaocto and
#         Sylvia atricapilla" (Methods 2.1). The 73 are named from Table S1 of Jiménez-Franco et al.
#         (2019), doi:10.1002/ece3.4829, through the 2019 deposit's codes (see
#         data/jimenezfranco_2019_murcia_birds_binom.R for that key).
# Mapping (E2 binomial_count, ruling #34): the modern period only. unit = modern grid cell (C001-C139,
#   the file's order), taxon = the deposit's code, y = transects with the species out of
#   obs_trials = nrep; no occasion, no period (each transect walked once, in 2012 or 2017; which
#   year is not deposited). unit_forest_cover_z, unit_elev_z as deposited (standardised).
#   Survey evidence: effort_table (nrep for every cell; every species column filled for every cell).
#   The 71 species recorded in the modern survey are rows at every cell (taxonInclusion recorded);
#   six on the authors' 77-species list have no modern record and are not shipped.
#   Not shipped: the historical period (the same 377 transects and the same 4,886 detections as
#   jimenezfranco_2019_murcia_birds_binom, regrouped into 226 cells of 2 x 2 km; asserted); its
#   elevation covariate is the only addition. No coordinates in the source.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "jimenezfranco_2023_murcia_birds_binom"
dir <- download_dryad("10.5061/dryad.j9kd51chz", "jimenezfranco_2023_murcia_birds")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("BirdsCC_Historical_period.RData", "BirdsCC_Modern_period.RData", "README.md")))
eh <- new.env(); stopifnot("bdata" %in% load(file.path(dir, "BirdsCC_Historical_period.RData"), envir = eh))
em <- new.env(); stopifnot("bdata2" %in% load(file.path(dir, "BirdsCC_Modern_period.RData"), envir = em))
h <- eh$bdata; m <- em$bdata2

# --- source facts ---------------------------------------------------------------------------
for (b in list(h, m)) stopifnot(setequal(names(b), c("Ysum", "nsite", "nrep", "nspec", "forest", "alt")),
                                nrow(b$Ysum) == b$nsite, ncol(b$Ysum) == b$nspec, length(b$nrep) == b$nsite,
                                !anyNA(b$Ysum), all(b$Ysum >= 0), all(b$Ysum == round(b$Ysum)), all(b$Ysum <= b$nrep), all(b$nrep >= 1),
                                length(b$forest) == b$nsite, length(b$alt) == b$nsite, !anyNA(c(b$forest, b$alt)))
stopifnot(h$nsite == 226, sum(h$nrep) == 377, h$nspec == 73, sum(h$Ysum) == 4886,
          m$nsite == 139, sum(m$nrep) == 198, m$nspec == 77, sum(m$Ysum) == 1865,
          identical(as.integer(table(m$nrep)), c(97L, 29L, 10L, 2L, 1L)))
ch <- colnames(h$Ysum); cm <- colnames(m$Ysum)
stopifnot(identical(cm[1:73], ch), identical(cm[74:77], c("Bucgit", "Regign", "Strdec", "Sylatr")))

# --- species key: 2019 deposit codes (same order) -> Table S1 names ------------------------------
d19 <- download_dryad("10.5061/dryad.8sf5v66", "jimenezfranco_2019_murcia_birds")
ex <- file.path(dirname(d19), "unzipped"); dir.create(ex, showWarnings = FALSE)
unzip(file.path(d19, "Avian community data.zip"), exdir = ex)
e19 <- new.env(); load(file.path(ex, "Avian community data AS2x2.RData"), envir = e19)
c19 <- names(e19$Ysum)
stopifnot(sum(colSums(e19$Ysum)) == sum(h$Ysum), identical(which(c19 != ch), c(10L, 11L, 13L, 27L, 48L, 49L, 50L, 58L)))
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
stopifnot(nrow(s1) == 73, !anyDuplicated(s1$sci))
auto <- with(s1, paste0(substr(sci, 1, 3), substr(sub("^\\S+ ", "", sci), 1, 3)))
hand <- c(Ccocor = "Corvus corax", Corcor = "Corvus corone", Emccir = "Emberiza cirlus",
          `Galsp.` = "Galerida cristata/theklae", Lopcris = "Lophophanes cristatus")
sci19 <- setNames(s1$sci[match(tolower(c19), tolower(auto))], c19); sci19["Corcor"] <- NA
stopifnot(sum(!is.na(sci19)) == 68); sci19[names(hand)] <- hand
stopifnot(!anyNA(sci19), setequal(sci19, s1$sci))
new4 <- c(Bucgit = "Bucanetes githagineus", Regign = "Regulus ignicapilla", Strdec = "Streptopelia decaocto", Sylatr = "Sylvia atricapilla")
sci <- c(unname(sci19), unname(new4)); stopifnot(length(sci) == 77, !anyDuplicated(sci))
common <- c(s1$common[match(sci19, s1$sci)], "Trumpeter Finch", "Common Firecrest", "Eurasian Collared Dove", "Eurasian Blackcap")

# --- long table (modern period) ----------------------------------------------------------------
Y <- as.matrix(m$Ysum); code <- sub("\\.$", "", cm)
long <- data.table(unit = rep(sprintf("C%03d", 1:139), times = 77), taxon = rep(code, each = 139),
                   y = as.integer(c(Y)), obs_trials = as.integer(rep(m$nrep, times = 77)),
                   unit_forest_cover_z = rep(unname(m$forest), 77), unit_elev_z = rep(unname(m$alt), 77))
zero <- code[colSums(Y) == 0]; stopifnot(length(zero) == 6)
zero_sci <- sci[colSums(Y) == 0]
cat("  not recorded in the modern survey (not shipped):", paste(zero_sci, collapse = ", "), "\n")
long <- order_eco(long[!taxon %in% zero])
stopifnot(nrow(long) == 139 * 71, sum(long$y) == 1865, all(long$y <= long$obs_trials))

# --- taxa ---------------------------------------------------------------------------------------
gal <- code == "Galsp"
rem <- rep(NA_character_, 77)
rem[gal] <- "Galerida cristata and G. theklae, not separated by the source (2019 Table S1 no. 32)"
rem[code == "Ccorax"] <- "Corvus corax (the 2019 deposit's Ccocor)"
rem[code == "Carchl"] <- "homonym on the GBIF backbone; key set below by a hinted match"
rem[74:77] <- "a species new in the modern survey, named in the paper (Methods 2.1); not in the 2019 Table S1"
taxa <- make_taxa(code, sci, vernacularName = common, lookupName = ifelse(gal, "Galerida", sci),
                  taxonRank = ifelse(gal, "genus", "species"), taxonRemarks = rem,
                  allow_higher = "Galsp", no_key = "Carchl")
hh <- gbif_taxon_hinted("Chloris chloris", list(kingdom = "Animalia", class = "Aves"))
stopifnot(identical(hh$canonicalName, "Chloris chloris"), identical(hh$rank, "species"), identical(hh$kingdom, "Animalia"))
taxa[taxon == "Carchl", `:=`(taxonID = hh$taxonID, gbifMatchType = paste0(hh$matchType, " (hinted)"),
                             taxonRemarks = "Chloris chloris (the deposit's code is for Carduelis chloris); a homonym with the grass genus Chloris on the GBIF backbone, matched with class Aves as a hint")]
taxa[, taxon_tableS1_2019 := s1$n[match(sci, s1$sci)]]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
na <- taxa[is.na(taxon_iucnCategory), taxon]
print(taxa[is.na(taxon_iucnCategory) | taxon_iucnCategory %in% c("CR", "EN", "VU"), .(taxon, scientificName, taxon_iucnCategory)])
syn <- c(Cergal = "LC", Cormon = "LC", Sylcan = "LC", Sylcon = "LC", Sylhor = "LC", Sylmel = "LC", Sylund = "NT")
stopifnot(all(na %in% names(syn)))
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := syn[taxon]]
stopifnot(!any(kingdom_taxonID(taxa$taxonID)))
taxa <- taxa[!taxon %in% zero]; stopifnot(nrow(taxa) == 71)

dataset <- list(
  title = "Forest birds on 198 one-km transects grouped into 139 grid cells in Murcia, south-east Spain, 2012 and 2017: transects with the species out of transects walked (binomial counts)",
  creator = "Jiménez-Franco, María V.; Kéry, Marc; León-Ortega, Mario; Martínez-Ródenas, Jacinto; Robledano, Francisco; Esteve, Miguel A.; Calvo, José F.",
  pubDate = "2023", doi = "10.5061/dryad.j9kd51chz", sourceURL = "https://doi.org/10.5061/dryad.j9kd51chz",
  citation = "Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Martínez-Ródenas, J., Robledano, F., Esteve, M. A., & Calvo, J. F. (2023). Data from: Evaluating temporal turnover in avian species richness in a Mediterranean semiarid region: different responses to elevation and forest cover [Dataset]. Dryad. https://doi.org/10.5061/dryad.j9kd51chz",
  paperDOI = "10.1111/ddi.13791",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "The modern survey of Jiménez-Franco et al. (2024, Diversity and Distributions): 198 one-km transects in Mediterranean forest and scrub across the region of Murcia (south-east Spain), each walked once in May-July of 2012 or 2017 recording every bird species seen or heard, grouped by the authors into 139 grid cells of 2 x 2 km as spatial replicates. For each cell and each of the 71 species recorded in the modern survey (of the authors' 77), the number of the cell's transects on which the species was recorded, out of the transects in the cell (binomial_count), with standardised forest cover and elevation per cell. The historical survey (1991-1992) of the same paper is jimenezfranco_2019_murcia_birds_binom; the two periods used different transects.",
  samplingProtocol = "1-km line transects walked once each in the breeding season (May-July) of 2012 or 2017 by one of two observers, recording every bird species seen or heard; transects grouped into 2 x 2 km grid cells, each transect a spatial replicate of its cell (Jiménez-Franco et al. 2024, Methods 2.2-2.3).",
  samplingProtocolCode = "line_transect", surveyEvidence = "effort_table",
  surveyEvidenceNote = "nrep (transects per cell, 1-5, summing to 198) is deposited for every cell; every species column is filled for every cell, so a species not recorded in a cell is y = 0 out of nrep.",
  effortColumn = "obs_trials", responseType = "binomial_count", unitKind = "site",
  closure = "none", closureNote = "no occasion column (binomial_count): the replicates are transects within a cell (spatial), walked in 2012 or 2017 and treated by the authors as one closed survey",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Region of Murcia, south-east Spain (about 37.4-38.8 N, 0.7-2.3 W): forested areas; cell coordinates not deposited",
  temporalCoverage = "2012/2017",
  notShipped = list(historical = "BirdsCC_Historical_period.RData: the 1991-1992 survey, the same 377 transects and 4,886 detections as jimenezfranco_2019_murcia_birds_binom regrouped into 226 cells of 2 x 2 km (asserted); its standardised elevation is the only addition",
                    `transect year` = "which transects were walked in 2012 and which in 2017 is not deposited",
                    `unrecorded species` = paste0("six species of the authors' 77-species list (recorded only in the historical survey) have no modern record: ", paste(zero_sci, collapse = ", "), " (taxonInclusion = recorded)")),
  notes = "Species codes are the deposit's six-letter codes; the 73 shared with the historical survey are named from Table S1 of Jiménez-Franco et al. (2019) through the 2019 deposit's codes (same column order), and the four new species from the paper's text. Six species of the authors' list were not recorded in the modern survey and are not shipped. Covariates (suffix _z) are standardised as deposited. Streptopelia turtur and Lanius meridionalis are IUCN VU; the source deposits no coordinates.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/jimenezfranco_2023_murcia_birds_binom.R")
stage_dict_row(TABLE,
  description = "Modern (2012 and 2017) breeding forest-bird survey of the region of Murcia, Spain: 198 one-km transects grouped into 139 grid cells, transects with the species out of transects per cell, 71 species, with standardised forest cover and elevation.",
  url = "https://doi.org/10.5061/dryad.j9kd51chz",
  reference = "Jiménez-Franco, M. V., Kéry, M., León-Ortega, M., Martínez-Ródenas, J., Robledano, F., Esteve, M. A., & Calvo, J. F. (2024). Evaluating temporal turnover in avian species richness in a Mediterranean semiarid region: Different responses to elevation and forest cover. Diversity and Distributions, 30(1), 106-118.",
  doi_paper = "10.1111/ddi.13791", doi_data = "10.5061/dryad.j9kd51chz",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "binomial_count (ruling #34); modern period only (the historical period duplicates jimenezfranco_2019_murcia_birds_binom; the periods used different transects). Codes named via the 2019 Table S1 and the paper's text.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (spatial replicates, binomial counts)",
  sampling_protocol = "line_transect", design = "Single-season (2012 and 2017 breeding seasons; transects as spatial replicates within grid cells)",
  realm = "Terrestrial", country = "ESP", coordinates = "None in source", notes = "Mediterranean forest bird community; modern resurvey of jimenezfranco_2019_murcia_birds_binom's region.", status = "tagged")
