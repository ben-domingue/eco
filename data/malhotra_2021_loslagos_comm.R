#!/usr/bin/env Rscript
# Table:  malhotra_2021_loslagos_comm
# Source: Dryad doi:10.5061/dryad.3xsj3txfv (CC0 1.0), files served from the Zenodo
#         mirror of the same deposit, https://zenodo.org/records/5106824
#   Malhotra, R., Jimenez, J. & Harris, N. (2021). Detection histories for Lycalopex
#   griseus, Lycalopex culpaeus, Leopardus guigna, and Canis familiaris and habitat
#   destruction covariate data for Los Lagos Chile (2019). Dryad.
# Paper:  Malhotra, Jimenez & Harris (2021). Patch characteristics and domestic dogs
#         differentially affect carnivore space use in fragmented landscapes in southern
#         Chile. Diversity and Distributions 27, doi:10.1111/ddi.13391
# Data:   four 48 x 12 detection-history CSVs (one per species, rows in the order of the
#         covariate file; o1..o12 = 7-day occasions; NA = camera not operating) and
#         chile_covars_dryad.csv (48 cameras x 7 covariates + a model-derived dog
#         occupancy estimate).
#
# Mapping (standard_draft.md section 3.6, community occupancy):
#   unit = camera (Cam label), taxon = species code, occasion = 7-day period 1..12,
#   y = 0/1 detection. The NA pattern is identical across the four species, so
#   every surveyed camera x occasion has four rows (explicit-zero rule).
#   unit_: trapnights, understory_10m (X10mtr_uds), smallmammal_rate (sm), forest,
#         isolation (iso), edge.
#   NOT shipped: Dog_occu -- the camera-level dog occupancy estimate from the authors'
#   own model. It is a model output, and the dog detections it was fit to are in the
#   table as taxon DOG.
#   No coordinates in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "malhotra_2021_loslagos_comm"
BASE <- "https://zenodo.org/api/records/5106824/files/%s/content"

species <- c(CHILLA = "Lycalopex griseus", CULPEO = "Lycalopex culpaeus",
             GUIGNA = "Leopardus guigna", DOG = "Canis familiaris")
vern <- c(CHILLA = "Chilla (South American grey fox)", CULPEO = "Culpeo", GUIGNA = "Guigna (kodkod)", DOG = "Domestic dog")

cov <- fread(download_cached(sprintf(BASE, "chile_covars_dryad.csv"), TABLE))
stopifnot(nrow(cov) == 48, !anyDuplicated(cov$Cam))
mats <- lapply(names(species), function(sp) {
  m <- as.matrix(fread(download_cached(sprintf(BASE, paste0(sp, ".csv")), TABLE)))
  stopifnot(dim(m) == c(48, 12), all(m %in% c(0, 1, NA)))
  m
})
y <- array(unlist(mats), dim = c(48, 12, 4), dimnames = list(cov$Cam, NULL, names(species)))
# NA = not surveyed, identical across species (checked), and only trailing occasions
na_pat <- is.na(y[, , 1])
stopifnot(all(apply(is.na(y), 3, identical, na_pat)))
stopifnot(all(apply(na_pat, 1, function(r) all(diff(as.integer(r)) >= 0))))

site_covs <- cov[, .(trapnights = Trapnights, understory_10m = X10mtr_uds, smallmammal_rate = sm,
                     forest = forest, isolation = iso, edge = edge)]
cat("  skipped Dog_occu: model-derived dog occupancy estimate (a model output; dog detections are taxon DOG)\n")

long <- array_to_eco(y, site_ids = cov$Cam, site_covs = site_covs)
stopifnot(nrow(long) == sum(!is.na(y)))

taxa <- make_taxa(names(species), unname(species), vernacularName = unname(vern[names(species)]))
dataset <- list(
  title = "Camera-trap detection histories of three native carnivores and domestic dogs, Los Lagos, Chile, 2019",
  creator = "Malhotra, Rumaan; Jimenez, Jaime; Harris, Nyeema",
  pubDate = "2021", doi = "10.5061/dryad.3xsj3txfv", sourceURL = "https://doi.org/10.5061/dryad.3xsj3txfv",
  mirrorURL = "https://zenodo.org/records/5106824",
  citation = "Malhotra, R., Jimenez, J., & Harris, N. (2021). Patch characteristics and domestic dogs differentially affect carnivore space use in fragmented landscapes in southern Chile. Diversity and Distributions, 27(12). https://doi.org/10.1111/ddi.13391",
  paperDOI = "10.1111/ddi.13391",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera-trap survey of a fragmented native-forest / pasture landscape in the central valley-Andean foothills transition of Los Lagos, Chile. Single-species occupancy models for culpeo, chilla and guigna with domestic-dog occupancy and habitat destruction as covariates.",
  samplingProtocol = "Camera traps; detection histories built from trigger histories with a 30-minute quiet period between triggers of the same species; each occasion is 7 camera-days.",
  samplingProtocolCode = "camera_trap", occasionLength = "7 days", effortColumn = "unit_trapnights",
  surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "Los Lagos Region, Chile (no coordinates deposited)", temporalCoverage = "2019",
  coordinatesCoarsened = NA, notShipped = list(Dog_occu = "model-derived covariate"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/malhotra_2021_loslagos_comm.R")

stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of chilla fox, culpeo fox, guigna and domestic dog at 48 camera stations over up to 12 seven-day occasions in a fragmented agricultural landscape of Los Lagos, Chile (2019), with six camera-level habitat covariates.",
  url = "https://doi.org/10.5061/dryad.3xsj3txfv",
  reference = "Malhotra, R., Jimenez, J., & Harris, N. (2021). Patch characteristics and domestic dogs differentially affect carnivore space use in fragmented landscapes in southern Chile. Diversity and Distributions, 27(12).",
  doi_paper = "10.1111/ddi.13391", doi_data = "10.5061/dryad.3xsj3txfv",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Files fetched from the Zenodo mirror (record 5106824) because anonymous Dryad downloads return 401. Dog_occu (model output) not shipped.",
  source_via = "Dryad via Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy",
  sampling_protocol = "camera_trap", design = "Single-season", realm = "Terrestrial", country = "CHL",
  coordinates = "None in source", notes = "Four species incl. domestic dog; occasion = 7 camera-days; 18.75% of camera-occasions not surveyed.")
