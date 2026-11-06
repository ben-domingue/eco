#!/usr/bin/env Rscript
# Table:  manzo_2024_pedregulho_tayra_dog_occ
# Source: Dryad, doi:10.5061/dryad.zgmsbccn3, version 316853 (published 2024-09-17), licence CC0 1.0 as shown on
#         the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Manzo, I. A., Gonçalves da Silva, R. & Bianchi, R. C. (2024). The influence of domestic dogs on the spatial
#         and temporal distribution of tayra. Wildlife Biology 2025, e01298. https://doi.org/10.1002/wlb3.01298
#         (CC BY 3.0; the publisher returns 403 to the agent, so the design is from the deposit's README and
#         abstract): 40 camera traps rotated over 73 sampling points about 2 km apart in an agricultural landscape
#         (protected area, agro-livestock areas, an urban area, rural households), December 2020 to August 2022,
#         30-40 cm above ground, 24 h a day for at least 60 consecutive days; 43,665 camera-days in all.
# Data:   occu_dog.csv, occu_tayra.csv (';'-separated, 69 points x 21 occasions; an occasion is 5 consecutive days;
#           1 = presence, 0 = absence, '-' = not surveyed). The dog file spells the last point 'Pontp_100'.
#         varocc.csv (69 x 42, rows in the same order, no id column): t1..t21 mean temperature and p1..p21
#           precipitation per occasion, normalized (README), 'n/a' where not surveyed.
#         varsite.csv (69 x 16, same order): land-use percentages at buffers of 200-1000 m, normalized; the eight
#           '*ms' columns are identical to the eight plain ones (asserted).
#         Activitypattern2.csv: 132 photographic records (species, date, locality 'Pedregulho', point_camera code,
#           time, time as radians) used for the activity-overlap analysis. No coordinates deposited.
# Mapping: two-species single-season occupancy. unit = point (Ponto_NN; 'Pontp_100' read as Ponto_100), taxon =
#   EIRBAR / CANFAM, occasion = 5-day block 1..21, y = detection 0/1. obs_temp_std, obs_precip_std from varocc;
#   unit_* land use from varsite (eight columns, normalized as deposited). surveyEvidence = deposited_matrix ('-').
#   The NA pattern of the two matrices differs in 20 cells (asserted); the tayra pattern equals the covariate
#   pattern of varocc. One camera surveys both species, so under the shared-detector ruling (2026-11-06, E4) a
#   point-occasion marked '-' for either species has no rows for either: 20 point-occasions are dropped (19 marked
#   for tayra only, 1 for dog only; every one of them is 0 for the other species, so no detection is lost).
#   Not shipped: Activitypattern2.csv (record-level times for the activity analysis; the detection histories
#   already carry the detections), the duplicate '*ms' land-use columns, model outputs.
#   README says 73 sampling points; the matrices hold 69 (the other four are not in the deposit).
#   IUCN: Eira barbara LC; Canis familiaris domestic. No coordinates, so E7 does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "manzo_2024_pedregulho_tayra_dog_occ"

dir <- download_dryad("10.5061/dryad.zgmsbccn3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("Activitypattern2.csv", "occu_dog.csv", "occu_tayra.csv", "README.md", "varocc.csv", "varsite.csv")))
dg <- fread(file.path(dir, "occu_dog.csv"), na.strings = "-", header = TRUE)
ty <- fread(file.path(dir, "occu_tayra.csv"), na.strings = "-", header = TRUE)
vo <- fread(file.path(dir, "varocc.csv"), na.strings = "n/a", header = TRUE)
vs <- fread(file.path(dir, "varsite.csv"), header = TRUE)
ap <- fread(file.path(dir, "Activitypattern2.csv"), header = TRUE)
stopifnot(identical(names(dg), c("Name", as.character(1:21))), identical(names(ty), c("Name", paste0("O", 1:21))),
          identical(names(vo), c(paste0("t", 1:21), paste0("p", 1:21))),
          nrow(dg) == 69L, nrow(ty) == 69L, nrow(vo) == 69L, nrow(vs) == 69L, nrow(ap) == 132L,
          identical(sub("^Pontp_", "Ponto_", dg$Name), ty$Name), sum(dg$Name != ty$Name) == 1L, !anyDuplicated(ty$Name))
D <- unname(as.matrix(dg[, -1])); Tt <- unname(as.matrix(ty[, -1]))
TM <- unname(as.matrix(vo[, 1:21])); PM <- unname(as.matrix(vo[, 22:42]))
stopifnot(all(D %in% c(0L, 1L, NA)), all(Tt %in% c(0L, 1L, NA)), sum(D, na.rm = TRUE) == 68L, sum(Tt, na.rm = TRUE) == 27L,
          identical(is.na(Tt), is.na(TM)), identical(is.na(Tt), is.na(PM)), identical(which(is.na(D[, 1])), 22L), identical(which(is.na(Tt[, 1])), 22L))   # Ponto_28 starts at occasion 7
# the ms columns of varsite duplicate the plain ones
stopifnot(identical(unname(as.matrix(vs[, 1:8])), unname(as.matrix(vs[, 9:16]))), !anyNA(vs),
          identical(names(vs)[9:16], paste0(names(vs)[1:8], "ms")))
# shared detector: a cell not surveyed for one species is not surveyed for either
one <- xor(is.na(D), is.na(Tt))
stopifnot(sum(one) == 20L, sum(is.na(Tt) & !is.na(D)) == 19L, sum(is.na(D) & !is.na(Tt)) == 1L,
          all(D[one & !is.na(D)] == 0L), all(Tt[one & !is.na(Tt)] == 0L))
D[one] <- NA_integer_; Tt[one] <- NA_integer_
stopifnot(sum(D, na.rm = TRUE) == 68L, sum(Tt, na.rm = TRUE) == 27L)

pts <- ty$Name
Y <- array(c(Tt, D), dim = c(69, 21, 2), dimnames = list(pts, NULL, c("EIRBAR", "CANFAM")))
sc <- data.frame(vs[, 1:8]); names(sc) <- paste0("landuse_", tolower(names(sc)), "_std")
long <- array_to_eco(Y, site_covs = sc, obs_covs = list(temp_std = TM, precip_std = PM))
long <- order_eco(long)
nsurv <- sum(!is.na(Tt))
stopifnot(nrow(long) == 2L * nsurv, nsurv == 69L * 21L - 496L - 1L, uniqueN(long$unit) == 69L,
          sum(long[taxon == "EIRBAR"]$y) == 27L, sum(long[taxon == "CANFAM"]$y) == 68L, !anyNA(long$obs_temp_std))
cat(sprintf("  %d rows, %d point-occasions; detections tayra %d, dog %d\n", nrow(long), nsurv,
            sum(long[taxon == "EIRBAR"]$y), sum(long[taxon == "CANFAM"]$y)))

taxa <- make_taxa(c("EIRBAR", "CANFAM"), c("Eira barbara", "Canis familiaris"), vernacularName = c("Tayra", "Domestic dog"))

dataset <- list(
  title = "Five-day camera detections of tayra and domestic dog at 69 sampling points in an agricultural landscape, Pedregulho, Brazil, 2020 to 2022",
  creator = "Manzo, Isabele Aparecida; Gonçalves da Silva, Rodolpho; Bianchi, Rita de Cassia", pubDate = "2024",
  doi = "10.5061/dryad.zgmsbccn3", sourceURL = "https://doi.org/10.5061/dryad.zgmsbccn3",
  citation = "Manzo, I., da Silva, R. G., & Bianchi, R. de C. (2024). The influence of domestic dogs on the spatial and temporal distribution of tayra [Dataset]. Dryad. https://doi.org/10.5061/dryad.zgmsbccn3",
  paperDOI = "10.1002/wlb3.01298",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps rotated over sampling points about 2 km apart in an agricultural landscape (a protected area, agro-livestock areas, an urban area and rural households) between December 2020 and August 2022, to test whether domestic dogs displace tayras. Detection of each species per point per 5-day occasion (up to 21 occasions), with normalized temperature and precipitation per occasion and normalized land-use percentages per point.",
  samplingProtocol = "One camera trap per sampling point, 30-40 cm above ground, running 24 h a day for at least 60 consecutive days; the deployment split into 5-day occasions, y = 1 when the species was photographed in the occasion.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "single-season occupancy as the authors fit it; points were surveyed at different times between December 2020 and August 2022 (40 cameras rotated over the points), and the deposit does not give each point's deployment dates.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Agricultural landscape around Pedregulho, Brazil (the deposit's locality); no coordinates deposited",
  temporalCoverage = "2020-12/2022-08",
  covariateNote = "obs_temp_std, obs_precip_std: mean temperature and precipitation of the 5-day occasion, normalized as deposited (varocc t1..t21, p1..p21). unit_landuse_<class>_<buffer m>_std: percentage of the land-use class within the buffer, normalized as deposited (varsite).",
  notShipped = list(
    shared_detector = "20 point-occasions marked not surveyed ('-') for one species and 0 for the other (19 for tayra, 1 for dog): one camera surveys both, so they have no rows for either species (shared-detector ruling, 2026-11-06)",
    activity_records = "Activitypattern2.csv: 132 record-level times (date, time, radians) for the activity-overlap analysis",
    duplicate_columns = "the eight '*ms' columns of varsite.csv, identical to the plain land-use columns",
    model_output = "occupancy estimates and activity-overlap coefficients"),
  notes = "The README describes 73 sampling points; the deposited matrices hold 69. Occasion k is the k-th 5-day block of a point's own deployment; deployment dates are not deposited, so there is no date column.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/manzo_2024_pedregulho_tayra_dog_occ.R")
stage_dict_row(TABLE,
  description = "Five-day camera-trap detections of tayra and domestic dog at 69 points in an agricultural landscape around Pedregulho, Brazil, December 2020 to August 2022, with weather and land-use covariates.",
  url = "https://doi.org/10.5061/dryad.zgmsbccn3",
  reference = "Manzo, I. A., Gonçalves da Silva, R. & Bianchi, R. C. (2024). The influence of domestic dogs on the spatial and temporal distribution of tayra. Wildlife Biology, e01298. https://doi.org/10.1002/wlb3.01298",
  doi_paper = "10.1002/wlb3.01298", doi_data = "10.5061/dryad.zgmsbccn3",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Two deposited detection matrices joined; 20 point-occasions not surveyed for one species dropped for both (shared-detector ruling).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (two species)",
  sampling_protocol = "camera_trap", design = "Single-season (69 points, up to 21 five-day occasions)",
  realm = "Terrestrial", country = "BRA", coordinates = "None in source",
  notes = "Tayra and domestic dog, for dog-wildlife interaction models; no coordinates.")
