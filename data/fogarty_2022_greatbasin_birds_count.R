#!/usr/bin/env Rscript
# Table:  fogarty_2022_greatbasin_birds_count
# Source: Dryad doi:10.25338/B8VD1R (CC0 1.0, as shown on the Dryad page; published 2022-05-18).
#         Fogarty, F. Riparian land-cover data and model code for: Multiple-region, N-mixture
#         community models to assess associations of riparian area, fragmentation, and species
#         richness.
# Paper:  Fogarty, F.A., Yen, J.D.L., Fleishman, E., Sollmann, R. & Ke, A. (2022). Ecological
#         Applications, doi:10.1002/eap.2698. Point counts in 23 canyons of the Shoshone,
#         Toiyabe, Toquima and Monitor ranges, central Great Basin, Nevada, 2001-2018;
#         multi-region N-mixture community models of riparian-obligate birds (Dryad methods).
# Data:   DataS1.zip -> bird_data.RDS (array: 33 species (four-letter codes, Pyle & DeSante 2020)
#         x 23 canyons x 21 points x 3 visits x 15 years (2001-2014, 2018); counts, NA = not
#         surveyed; NA pattern identical across species, asserted) and cov_data.RDS (23 rows, no
#         canyon ids: Cov1 woody riparian area, Cov2 meadow riparian area, Cov3 woody riparian
#         nLSI, Cov4-Cov6 their squares (asserted), standardized). DataS2.zip holds model results.
#         README.txt describes both.
# Mapping (standard: dynamic community N-mixture, E9 core): unit = "<canyon>_<point>"; cluster_id
#   = canyon; period = year (__periods); occasion = visit 1..3; taxon = species code; y = count;
#   NA = no row. unit_: Cov1-Cov3 (standardized) joined to canyons by row order (the authors'
#   model code does the same; cov_data has no ids). Survey evidence: deposited_matrix.
#   The code BTAH is not a Pyle & DeSante alpha code and the deposit does not define it: no
#   rows (notShipped). Scientific names are the processor's, from the alpha codes. No
#   coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fogarty_2022_greatbasin_birds_count"
dir <- download_dryad("10.25338/B8VD1R", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^DataS1\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
y <- readRDS(file.path(ex, "bird_data.RDS")); cv <- readRDS(file.path(ex, "cov_data.RDS"))
dn <- dimnames(y)
stopifnot(identical(dim(y), c(33L, 23L, 21L, 3L, 15L)), identical(dn[[4]], c("V1", "V2", "V3")), identical(dn[[5]], as.character(c(2001:2014, 2018))),
          nrow(cv) == 23, all(abs(cv$Cov4 - cv$Cov1^2) < 1e-6), all(abs(cv$Cov5 - cv$Cov2^2) < 1e-6), all(abs(cv$Cov6 - cv$Cov3^2) < 1e-6))
na <- is.na(y[1, , , , ]); stopifnot(all(sapply(1:33, function(k) identical(is.na(y[k, , , , ]), na))), sum(!na) == 8258)
SP <- c(BBMA = "Pica hudsonia", BCHU = "Archilochus alexandri", BHGR = "Pheucticus melanocephalus", BRCR = "Certhia americana",
        BUOR = "Icterus bullockii", CEDW = "Bombycilla cedrorum", COFL = "Empidonax occidentalis", COHA = "Accipiter cooperii",
        DOWO = "Dryobates pubescens", DUFL = "Empidonax oberholseri", DUGR = "Dendragapus obscurus", FOSP = "Passerella iliaca",
        HETH = "Catharus guttatus", HOWR = "Troglodytes aedon", LAZB = "Passerina amoena", MALL = "Anas platyrhynchos",
        MGWA = "Geothlypis tolmiei", NRWS = "Stelgidopteryx serripennis", OCWA = "Leiothlypis celata", RNSA = "Sphyrapicus nuchalis",
        RWBL = "Agelaius phoeniceus", SOSP = "Melospiza melodia", SPSA = "Actitis macularius", SWTH = "Catharus ustulatus",
        VGSW = "Tachycineta thalassina", VIWA = "Leiothlypis virginiae", WAVI = "Vireo gilvus", WCSP = "Zonotrichia leucophrys",
        WEWP = "Contopus sordidulus", YBCH = "Icteria virens", YEWA = "Setophaga petechia", YRWA = "Setophaga coronata")
stopifnot(setequal(c(names(SP), "BTAH"), dn[[1]]))
w <- which(!na, arr.ind = TRUE)   # canyon, point, visit, year
sv <- data.table(canyon = dn[[2]][w[, 1]], point = dn[[3]][w[, 2]], occasion = w[, 3], period = w[, 4], ci = w[, 1])
long <- rbindlist(lapply(names(SP), function(k) cbind(sv, taxon = k, y = as.integer(y[k, , , , ][w]))))
long <- long[, .(unit = paste(canyon, point, sep = "_"), taxon, y, period, occasion, cluster_id = canyon,
                 unit_woody_riparian_area_std = cv$Cov1[ci], unit_meadow_riparian_area_std = cv$Cov2[ci], unit_woody_riparian_nlsi_std = cv$Cov3[ci])]
long <- order_eco(long)
stopifnot(nrow(long) == 8258 * 32, !anyNA(long$y))
periods <- data.table(period = 1:15, period_year = c(2001:2014, 2018))
taxa <- make_taxa(names(SP), unname(SP), vernacularName = c("Black-billed magpie", "Black-chinned hummingbird", "Black-headed grosbeak", "Brown creeper",
  "Bullock's oriole", "Cedar waxwing", "Cordilleran flycatcher", "Cooper's hawk", "Downy woodpecker", "Dusky flycatcher", "Dusky grouse",
  "Fox sparrow", "Hermit thrush", "House wren", "Lazuli bunting", "Mallard", "MacGillivray's warbler", "Northern rough-winged swallow",
  "Orange-crowned warbler", "Red-naped sapsucker", "Red-winged blackbird", "Song sparrow", "Spotted sandpiper", "Swainson's thrush",
  "Violet-green swallow", "Virginia's warbler", "Warbling vireo", "White-crowned sparrow", "Western wood-pewee", "Yellow-breasted chat",
  "Yellow warbler", "Yellow-rumped warbler"))
dataset <- list(
  title = "Counts of 32 riparian bird species on three visits to 275 points in 23 central Great Basin canyons, Nevada, 15 years 2001-2018",
  creator = "Fogarty, Frank A.", pubDate = "2022", doi = "10.25338/B8VD1R", sourceURL = "https://doi.org/10.25338/B8VD1R",
  citation = "Fogarty, F. (2022). Riparian land-cover data and model code for: Multiple-region, N-mixture community models to assess associations of riparian area, fragmentation, and species richness [Dataset]. Dryad. https://doi.org/10.25338/B8VD1R",
  paperDOI = "10.1002/eap.2698",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point counts of riparian birds on three visits per year at points in 23 canyons of the Shoshone Mountains and Toiyabe, Toquima and Monitor ranges, central Great Basin, Nevada, in 15 years between 2001 and 2018, with canyon woody and meadow riparian area and woody-riparian fragmentation (standardized).",
  samplingProtocol = "Repeated point counts along canyon bottoms (up to 21 points per canyon), three visits per breeding season; all individuals of each species counted.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "count",
  unitKind = "site", closure = "closed", closureNote = "closed within a breeding season (three visits), open between years", occasionKind = "time",
  taxonInclusion = "recorded", geographicCoverage = "Central Great Basin (Shoshone, Toiyabe, Toquima and Monitor ranges), Nevada, USA; no coordinates deposited",
  temporalCoverage = "2001/2018",
  notShipped = list(BTAH = "species code BTAH, not a Pyle & DeSante alpha code and not defined in the deposit", squares = "Cov4-Cov6, squares of Cov1-Cov3 (asserted)",
                    model_results = "DataS2.zip model results", other_species = "the array holds the authors' 33 analysed species, not every species counted"),
  notes = "Canyon covariates are joined by row order (cov_data.RDS has no canyon ids; the authors' code does the same). Scientific names are the processor's, from the four-letter alpha codes. Survey years are 2001-2014 and 2018.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fogarty_2022_greatbasin_birds_count.R")
stage_dict_row(TABLE, description = "Repeated point counts of 32 riparian bird species at 275 points in 23 Great Basin canyons, Nevada, 2001-2018, with canyon riparian covariates.",
  url = "https://doi.org/10.25338/B8VD1R", reference = "Fogarty, F. A., Yen, J. D. L., Fleishman, E., Sollmann, R., & Ke, A. (2022). Multiple-region, N-mixture community models to assess associations of riparian area, fragmentation, and species richness. Ecological Applications.",
  doi_paper = "10.1002/eap.2698", doi_data = "10.25338/B8VD1R", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic community N-mixture; BTAH (undefined code) dropped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community N-mixture (multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (15 years x 3 visits)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Great Basin riparian birds.")
