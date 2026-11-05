#!/usr/bin/env Rscript
# Table:  crunchant_2020_issa_chimp_occ
# Source: Dryad doi:10.5061/dryad.5dv41ns34, version 54114 (published 2020-02-19), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Crunchant, A.-S., Borchers, D., Kuehl, H. & Piel, A. K.
#         "Listening and watching: do camera traps or acoustic sensors more efficiently detect wild chimpanzees in
#         an open habitat?".
# Paper:  Crunchant, A.-S., Borchers, D., Kuehl, H. & Piel, A. K. (2020). Listening and watching: Do camera traps
#         or acoustic sensors more efficiently detect wild chimpanzees in an open habitat? Methods in Ecology and
#         Evolution 11, 542-552, doi:10.1111/2041-210X.13362 (not read; design from the Dryad description and file).
# Data:   one workbook, PresenceAbsence_matrices_-_CT_and_PAM.xlsx, four sheets:
#         CT_PresenceAbsence: 53 cameras (SCT = systematic grid, TCT = targeted placements; one id "TCT0440/4821")
#           x 280 days (header = Excel date serials 43183..43462, 2018-03-24 to 2018-12-28); 1 = chimpanzee
#           detected that day, 0 = not detected, NA = camera not deployed or not working ("detection/non detection
#           per day of deployment", Dryad methods). 66-280 operating days per camera; 47 cameras have gaps.
#         CT_Metadata: Name, Latitude, Longitude (decimal degrees, 5 decimals), Method (systematic/targeted),
#           Vegetation (closed/open), Topography.
#         PAM_PresenceAbsence and PAM_Metadata: passive acoustic monitoring, 12 valleys in 3 clusters, detection per
#           30-min recording 06:00-19:30, March-December 2018; the metadata lists four sensor positions per valley
#           but the matrix has one row per valley. Not built here (see notShipped and queue/human_review.csv).
# Mapping (standard E9 single-season occupancy, daily occasions):
#   unit = camera; taxon = PANTRO; occasion = day index 1..280 from 2018-03-24; date = that day; y = detected (0/1);
#   NA cells are missing rows. Survey evidence: deposited_matrix. unit_method, unit_vegetation, unit_topography.
#   Coordinates: Pan troglodytes is IUCN EN (asserted) in its native range, so camera coordinates are coarsened to
#   the 0.1 degree cell centre with coarsen_coords() (E7), with unit_coord_uncertainty_m.
#   Not shipped: the PAM matrices (unit of the matrix vs four sensor positions per valley unresolved).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "crunchant_2020_issa_chimp_occ"
dir <- download_dryad("10.5061/dryad.5dv41ns34", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "54114"))
f <- file.path(dir, "PresenceAbsence_matrices_-_CT_and_PAM.xlsx")
stopifnot(file.exists(f), identical(excel_sheets(f), c("PAM_PresenceAbsence", "PAM_Metadata", "CT_PresenceAbsence", "CT_Metadata")))
ct <- as.data.table(suppressMessages(read_excel(f, sheet = "CT_PresenceAbsence", na = "NA")))
md <- as.data.table(suppressMessages(read_excel(f, sheet = "CT_Metadata")))
setnames(ct, 1, "cam")
serial <- as.integer(names(ct)[-1])
stopifnot(nrow(ct) == 53L, identical(serial, 43183:43462), !anyDuplicated(ct$cam), identical(ct$cam, md$Name),
          identical(names(md), c("Name", "Latitude", "Longitude", "Method", "Vegetation", "Topography")))
Y <- as.matrix(ct[, -1]); storage.mode(Y) <- "integer"
stopifnot(all(Y %in% c(0L, 1L, NA)), sum(!is.na(Y)) == 11342L, sum(Y, na.rm = TRUE) == 692L, all(rowSums(!is.na(Y)) >= 66L))
days <- as.IDate(serial, origin = "1899-12-30")
stopifnot(format(days[1]) == "2018-03-24", format(days[280]) == "2018-12-28")
long <- data.table(unit = rep(ct$cam, 280L), occasion = rep(1:280, each = 53L), y = c(Y))[!is.na(y)]
long[, `:=`(taxon = "PANTRO", date = format(days[occasion]))]
stopifnot(all(md$Latitude > -5.6 & md$Latitude < -5.3), all(md$Longitude > 30.4 & md$Longitude < 30.7),
          all(md$Method %in% c("systematic", "targeted")), all(md$Vegetation %in% c("closed", "open")), !anyNA(md$Topography))
cc <- coarsen_coords(md$Latitude, md$Longitude, cell = 0.1)
cov <- data.table(unit = md$Name, unit_lat = cc$lat, unit_lon = cc$lon, unit_coord_uncertainty_m = cc$uncertainty_m,
                  unit_method = md$Method, unit_vegetation = md$Vegetation, unit_topography = md$Topography)
long <- order_eco(merge(long, cov, by = "unit"))
stopifnot(nrow(long) == 11342L)

taxa <- make_taxa("PANTRO", "Pan troglodytes", vernacularName = "Chimpanzee")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "EN"))

dataset <- list(
  title = "Daily camera-trap detections of chimpanzees at 53 cameras in the Issa Valley, western Tanzania, March to December 2018",
  creator = "Crunchant, Anne-Sophie; Borchers, David; Kuehl, Hjalmar; Piel, Alex K.",
  pubDate = "2020", doi = "10.5061/dryad.5dv41ns34", sourceURL = "https://doi.org/10.5061/dryad.5dv41ns34",
  citation = "Crunchant, A.-S., Borchers, D., Kuehl, H., & Piel, A. K. (2020). Listening and watching: do camera traps or acoustic sensors more efficiently detect wild chimpanzees in an open habitat? [Dataset]. Dryad. https://doi.org/10.5061/dryad.5dv41ns34",
  paperDOI = "10.1111/2041-210X.13362",
  abstract = "Camera traps in the savanna-woodland mosaic of the Issa Valley, western Tanzania, from March to December 2018: 21 on a systematic grid and 32 at targeted places, with videos checked by hand for chimpanzees and summarised as detection or non-detection per day of deployment. The authors compared these cameras with passive acoustic monitoring in occupancy models, using the number of sampling days needed to establish chimpanzee absence with 95% probability as the measure of efficacy.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Video camera traps, systematic (grid) and targeted (trails, feeding trees) placements, run for up to 280 days; chimpanzee presence confirmed by hand per day; days a camera was not deployed or not working are missing.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors treat the nine months as one season (8-day occasions in their models)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Issa Valley, Greater Mahale Ecosystem, western Tanzania; camera coordinates coarsened to 0.1 degree",
  temporalCoverage = "2018-03/2018-12",
  coordinatesCoarsened = list(value = TRUE, method = "camera coordinates (deposited to 5 decimals) coarsened to the 0.1 degree cell centre with coarsen_coords(); Pan troglodytes is IUCN Endangered in its native range"),
  covariateNote = "unit_method: systematic (grid) or targeted placement; unit_vegetation: closed or open; unit_topography as deposited (valley, plateau, slope, ...). unit_coord_uncertainty_m: half-diagonal of the 0.1 degree cell.",
  notShipped = list(pam = "PAM_PresenceAbsence and PAM_Metadata (12 valleys x 3,741 30-min recordings): the matrix has one row per valley but the metadata lists four sensor positions per valley, and the deposit does not say whether a row pools four recorders or one recorder moved among them; held with a question in queue/human_review.csv."),
  notes = "occasion is the day index from 2018-03-24 (date gives the day). The authors pooled days into 8-day occasions for their models; pooling is left to the user.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/crunchant_2020_issa_chimp_occ.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detection of chimpanzees at 53 systematic and targeted cameras in the Issa Valley, Tanzania, March-December 2018.",
  url = "https://doi.org/10.5061/dryad.5dv41ns34",
  reference = "Crunchant, A.-S., Borchers, D., Kuehl, H., & Piel, A. K. (2020). Listening and watching: Do camera traps or acoustic sensors more efficiently detect wild chimpanzees in an open habitat? Methods in Ecology and Evolution, 11, 542-552.",
  doi_paper = "10.1111/2041-210X.13362", doi_data = "10.5061/dryad.5dv41ns34",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; camera sheet only (acoustic sheet held); coordinates coarsened to 0.1 degree (IUCN EN).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (280 daily occasions)",
  realm = "Terrestrial", country = "TZA", coordinates = "Coarsened (0.1 deg)",
  notes = "Endangered great ape in savanna-woodland; systematic vs targeted camera placement.")
