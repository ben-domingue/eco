#!/usr/bin/env Rscript
# Table:  wang_2019_amazon_ocelot_occ
# Source: Dryad doi:10.5061/dryad.p7410jm (CC0 1.0, as shown on the Dryad page; published
#         2019-04-22). Wang, B., Rocha, D.G., Abrahams, M.I. et al. Data from: Habitat use of the
#         ocelot (Leopardus pardalis) in Brazilian Amazon.
# Paper:  Wang, B. et al. (2019). Ecology and Evolution, doi:10.1002/ece3.5005. 899 camera-trap
#         stations at twelve sites in the Brazilian Amazon, 2010-2017; occupancy with spatial
#         autocorrelation (abstract).
# Data:   data.zip -> data/detection_history.csv (899 stations: site, trap, X, Y (projected
#         coordinates in mixed UTM zones, none named), V1-V10 = ocelot detected 0/1 in each
#         12-day occasion, NA = no occasion), data/effort_camera trap.csv (899 rows, no keys:
#         camera-days per occasion, 0 where no occasion), data/all_site_cov.csv (899 rows: Trap,
#         Site, latitude, longitude and 14 covariates). README_for_data.txt describes the three.
#         Asserted: effort > 0 exactly where V is not NA (rows aligned by position).
#         Quirk: all_site_cov.csv spells some site and trap ids differently (PBDFF vs PDBFF;
#         CT-MA-... vs CT-MAS-...; 101 of 899 keys do not match) and is in a different order, so
#         it cannot be joined by key; it is not shipped.
# Mapping (standard: single-season occupancy, E9 core): unit = "<site>_<trap>"; taxon = LEOPAR;
#   occasion = 12-day occasion 1..10; y = the cell; NA = no row; obs_effort_days = camera-days
#   (effortColumn); cluster_id = site. Survey evidence: effort_table. Ocelot is IUCN LC; the
#   deposited X/Y (unnamed, mixed UTM zones) are not shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "wang_2019_amazon_ocelot_occ"
dir <- download_dryad("10.5061/dryad.p7410jm", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^data\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "data")
d <- fread(file.path(b, "detection_history.csv"), header = TRUE); e <- fread(file.path(b, "effort_camera trap.csv"), header = TRUE)
setnames(d, 1, "row"); setnames(e, 1, "row")   # the unnamed row-index column
V <- paste0("V", 1:10)
stopifnot(nrow(d) == 899, nrow(e) == 899, uniqueN(d$site) == 12, !anyDuplicated(d[, .(site, trap)]),
          identical(names(d), c("row", "site", "trap", "X", "Y", V)), identical(names(e), c("row", V)), identical(d$row, e$row))
Y <- as.matrix(d[, ..V]); E <- as.matrix(e[, ..V])
stopifnot(all(Y %in% c(0, 1, NA)), !anyNA(E), all(is.na(Y) == (E == 0)),
          sum(Y, na.rm = TRUE) == 282)
ids <- paste(d$site, d$trap, sep = "_")
dimnames(Y) <- list(ids, NULL); E[E == 0] <- NA
long <- array_to_eco(Y, taxon = "LEOPAR", site_ids = ids, obs_covs = list(effort_days = E))
long[, cluster_id := d$site[match(unit, ids)]]
long <- order_eco(long)
stopifnot(nrow(long) == sum(!is.na(Y)), !anyNA(long$obs_effort_days))
taxa <- make_taxa("LEOPAR", "Leopardus pardalis", vernacularName = "Ocelot")
dataset <- list(
  title = "Ocelot camera-trap detections at 899 stations in twelve Brazilian Amazon sites, 12-day occasions, 2010-2017",
  creator = "Wang, Bingxin; Rocha, Daniel G.; Abrahams, Mark I.; Antunes, André P.; Costa, Hugo C. M.; Gonçalves, André Luis Sousa; Spironello, Wilson Roberto; de Paula, Milton José; Peres, Carlos A.; Pezzuti, Juarez; Ramalho, Emiliano; Reis, Marcelo Lima; Carvalho Jr, Elildo; Rohe, Fabio; Macdonald, David W.; Tan, Cedric Kai Wei",
  pubDate = "2019", doi = "10.5061/dryad.p7410jm", sourceURL = "https://doi.org/10.5061/dryad.p7410jm",
  citation = "Wang, B. et al. (2019). Data from: Habitat use of the ocelot (Leopardus pardalis) in Brazilian Amazon [Dataset]. Dryad. https://doi.org/10.5061/dryad.p7410jm",
  paperDOI = "10.1002/ece3.5005",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of ocelot (Leopardus pardalis) in 12-day sampling occasions at 899 camera-trap stations in twelve study sites across the Brazilian Amazon, surveyed between 2010 and 2017, with camera-days of effort per occasion.",
  samplingProtocol = "Camera-trap stations at twelve Amazonian sites (protected areas and forest reserves), 2010-2017; detections summarised per 12-day occasion with camera-days operating.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one deployment per station (up to ten 12-day occasions); the authors' single-season occupancy", occasionKind = "time",
  taxonInclusion = "single", effortColumn = "obs_effort_days",
  geographicCoverage = "Twelve sites in the Brazilian Amazon (REMJ, BRA319, Uatuma, PNCA, RDSA, TMES, PNM, PDBFF, ZF2, DUCKE, SBR, PNJU)",
  temporalCoverage = "2010/2017",
  notShipped = list(all_site_cov = "site covariates and lat/long: ids spelled differently from the detection file for 101 stations and in another order, so they cannot be joined by key",
                    XY = "station X/Y in unnamed, mixed UTM zones"),
  notes = "Survey years per site are not deposited (2010-2017 overall). The effort file has no keys and is aligned to the detection file by row (its zeros fall exactly on the NA occasions).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/wang_2019_amazon_ocelot_occ.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of ocelot in 12-day occasions at 899 stations in twelve Brazilian Amazon sites, 2010-2017, with camera-day effort.",
  url = "https://doi.org/10.5061/dryad.p7410jm",
  reference = "Wang, B. et al. (2019). Habitat use of the ocelot (Leopardus pardalis) in Brazilian Amazon. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.5005", doi_data = "10.5061/dryad.p7410jm", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-species occupancy with effort; covariates not joinable.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (up to ten 12-day occasions)", realm = "Terrestrial",
  country = "BRA", coordinates = "None in source", notes = "Coordinates deposited but not shipped (unnamed mixed UTM zones; covariate file not joinable).")
