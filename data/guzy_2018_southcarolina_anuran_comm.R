#!/usr/bin/env Rscript
# Table:  guzy_2018_southcarolina_anuran_comm
# Source: Dryad doi:10.5061/dryad.9qg57 (CC0 1.0, as shown on the Dryad page; published
#         2018-12-01). Guzy, J.C., Eskew, E.A., Halstead, B.J. & Price, S.J. Data from:
#         Influence of damming on anuran species richness in riparian areas: a test of the serial
#         discontinuity concept.
# Paper:  Guzy, J.C. et al. (2018). Ecology and Evolution 8(4), doi:10.1002/ece3.3750. Repeated,
#         time-constrained anuran calling surveys at 42 locations along the Broad and Pacolet
#         Rivers, South Carolina, USA (abstract); hierarchical community occupancy (WinBUGS).
# Data:   13 per-species files <code>.csv (42 sites x Survey1-Survey9, calling detected 0/1; no
#         missing cells; identical site order, asserted): acrcre, bufame, buffow, bufter, gascar,
#         hylchr, hylcin, psecru, psefer, rancat, rancla, ranpal, ransph; Date.csv (standardized
#         survey date per site-survey); SiteCovariates.csv (standardized distances downstream
#         and upstream of dams, urban land use); the authors' R script. The codes are the first
#         three letters of the genus and species in the authors' (older) nomenclature; the
#         expansion to names is the processor's (Bufo -> Anaxyrus, Rana -> Lithobates).
# Mapping (standard: community occupancy, E9 core): unit = Site; taxon = the code (upper case);
#   occasion = survey 1..9; y = the cell; obs_date_std = Date (standardized as deposited);
#   unit_: the three covariates (standardized). Survey evidence: deposited_matrix. No
#   coordinates; all species IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "guzy_2018_southcarolina_anuran_comm"
dir <- download_dryad("10.5061/dryad.9qg57", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
SP <- c(acrcre = "Acris crepitans", bufame = "Anaxyrus americanus", buffow = "Anaxyrus fowleri", bufter = "Anaxyrus terrestris",
        gascar = "Gastrophryne carolinensis", hylchr = "Hyla chrysoscelis", hylcin = "Hyla cinerea", psecru = "Pseudacris crucifer",
        psefer = "Pseudacris feriarum", rancat = "Lithobates catesbeianus", rancla = "Lithobates clamitans", ranpal = "Lithobates palustris",
        ransph = "Lithobates sphenocephalus")
S <- paste0("Survey", 1:9)
D <- lapply(names(SP), function(k) rf(paste0(k, "\\.csv"))); names(D) <- names(SP)
sites <- D[[1]]$Site
stopifnot(length(sites) == 42, all(sapply(D, function(x) identical(names(x), c("Site", S)) && identical(x$Site, sites) && all(as.matrix(x[, ..S]) %in% 0:1))))
dt <- rf("Date\\.csv"); sc <- rf("SiteCovariates\\.csv")
stopifnot(identical(dt$Site, sites), identical(sc$Site, sites), !anyNA(dt))
Y <- array(NA_integer_, dim = c(42, 9, 13), dimnames = list(as.character(sites), NULL, toupper(names(SP))))
for (k in names(SP)) Y[, , toupper(k)] <- as.matrix(D[[k]][, ..S])
long <- array_to_eco(Y, site_ids = as.character(sites), site_covs = as.data.frame(sc[, .(downstream_dist_std = Downstream, upstream_dist_std = Upstream, urban_std = Urban)]),
                     obs_covs = list(date_std = as.matrix(dt[, ..S])))
long <- order_eco(long)
stopifnot(nrow(long) == 42 * 9 * 13)
taxa <- make_taxa(toupper(names(SP)), unname(SP), taxonRemarks = ifelse(grepl("^(buf|ran)", names(SP)), paste0("deposited code ", names(SP), " (Bufo / Rana in older nomenclature)"), NA))
dataset <- list(
  title = "Anuran calling-survey detections of 13 species at 42 riparian sites along the Broad and Pacolet Rivers, South Carolina, nine surveys",
  creator = "Guzy, Jacquelyn C.; Eskew, Evan A.; Halstead, Brian J.; Price, Steven J.", pubDate = "2018", doi = "10.5061/dryad.9qg57", sourceURL = "https://doi.org/10.5061/dryad.9qg57",
  citation = "Guzy, J. C., Eskew, E. A., Halstead, B. J., & Price, S. J. (2018). Data from: Influence of damming on anuran species richness in riparian areas: a test of the serial discontinuity concept [Dataset]. Dryad. https://doi.org/10.5061/dryad.9qg57",
  paperDOI = "10.1002/ece3.3750",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of 13 frog and toad species on nine time-constrained calling surveys at 42 locations along a 245-km river corridor (Broad and Pacolet Rivers, South Carolina, USA), with standardized survey date and distances downstream and upstream of dams and urban land use.",
  samplingProtocol = "Repeated time-constrained nocturnal anuran calling surveys at riparian locations; each species recorded as calling or not per survey.",
  samplingProtocolCode = "call_survey", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one breeding season of surveys, analysed as single-season community occupancy", occasionKind = "time",
  taxonInclusion = "recorded", geographicCoverage = "Broad and Pacolet Rivers, South Carolina, USA; no coordinates deposited",
  temporalCoverage = "survey year not stated in the deposit (paper 2018)",
  notShipped = list(none = "every deposited data file is shipped"),
  notes = "Species codes are expanded by the processor (three letters of genus and species; Bufo / Rana codes map to Anaxyrus / Lithobates). Date and covariates are standardized as deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/guzy_2018_southcarolina_anuran_comm.R")
stage_dict_row(TABLE, description = "Calling-survey detections of 13 anurans at 42 riparian sites along the Broad and Pacolet Rivers, South Carolina, nine surveys, with dam-distance covariates.",
  url = "https://doi.org/10.5061/dryad.9qg57", reference = "Guzy, J. C., Eskew, E. A., Halstead, B. J., & Price, S. J. (2018). Influence of damming on anuran species richness in riparian areas: A test of the serial discontinuity concept. Ecology and Evolution, 8(4).",
  doi_paper = "10.1002/ece3.3750", doi_data = "10.5061/dryad.9qg57", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy of calling anurans.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community occupancy (single season)",
  sampling_protocol = "call_survey", design = "Single-season (9 calling surveys)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "Dams and anurans.")
