# Table:  feng_2021_nechina_mamm_binom
# Source: Dryad doi:10.5061/dryad.2jm63xsnp, version 4 (2021-02-10), licence CC0 1.0 (as shown on
#         Dryad). "Assessing mammal species richness and occupancy in a Northeast Asian temperate
#         forest shared by cattle" (Feng, Sun, Li, Xiao, Zhang, Smith, Ge & Wang).
# Paper:  Feng, J.-W., Sun, Y.-F., Li, H., Xiao, Y., Zhang, D., Smith, J. L. D., Ge, J., & Wang, T.-M.
#         (2021). Assessing mammal species richness and occupancy in a Northeast Asian temperate
#         forest shared by cattle. Diversity and Distributions, 27(5), 857-872.
#         doi:10.1111/ddi.13237 (CC BY 4.0; the publisher returns 403 to the agent, so the study
#         year and exact study area come from the Dryad abstract only: 138 cameras, 22,976 trap
#         days, "across the China-Russia border", Northeast China).
# Data:   detection_history_with_effort_14_days-2.csv: 138 rows (CamID SITE01..SITE138), k = the
#           number of 14-day windows the station was surveyed (4-13), then one column per species
#           code (18 of S01..S23; S06, S08, S16, S18, S21 are not in the file) holding the NUMBER
#           of 14-day windows in which the species was detected at least once (0-12). This is the
#           authors' summarised matrix y_ij (readme); the window-level histories are not deposited.
#         site_covariates.csv: 138 rows in the same order; Cam (Single / Both = paired cameras),
#           Days (trap days, 45-184; sums to the abstract's 22,976), HumanDetectionRate and
#           CattleDetectionRate (detections per unit effort of humans and cattle at the station),
#           Elev (m), Dist.settlement / Dist.border / Dist.road / Dist.river (m), NDVI, BA (basal
#           area) and Transparent (canopy transparency), none standardised. No coordinates.
#         speciesCode.csv: SppCode, CommName, SciName, Family for the 18 species; three are given
#           as subspecies (Amur tiger, Amur leopard, Amur leopard cat) and the black bear at genus.
# Mapping (standard E2 `binomial_count`, ruling #34, 2026-11-01): the deposit collapsed the
#   occasions, so one row per station x species, no `occasion`: unit = CamID, taxon = six-letter
#   code from the scientific name (deposit code in __taxa.taxon_sourceCode), y = windows with a
#   detection, obs_trials = k (windows surveyed; effortColumn). surveyEvidence = deposited_matrix:
#   every station has k >= 4, so every station x species pair is a row (community rule holds by
#   construction). unitKind = site, one season (closure = the whole deployment). Site covariates
#   ship as unit_* under descriptive names; the human and cattle detection rates are detections
#   of other species at the same cameras, used by the authors as disturbance covariates, not
#   outputs of the target-species model, so they are kept. Not shipped: nothing (the deposit has
#   no model outputs). Taxa: Amur tiger (Panthera tigris, EN), Amur leopard (P. pardus, VU at
#   species level; the subspecies is CR) and Siberian musk deer (VU) are flagged, but the deposit
#   has no coordinates, so there is nothing to coarsen.

for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "feng_2021_nechina_mamm_binom"
SCRIPT <- "data/feng_2021_nechina_mamm_binom.R"
dir <- download_dryad("10.5061/dryad.2jm63xsnp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

det <- fread(file.path(dir, "detection_history_with_effort_14_days-2.csv"))
cov <- fread(file.path(dir, "site_covariates.csv"))
spp <- fread(file.path(dir, "speciesCode.csv"))

# ---- source facts -----------------------------------------------------------------------
codes <- setdiff(names(det), c("CamID", "k"))
stopifnot(nrow(det) == 138, nrow(cov) == 138, identical(det$CamID, cov$CamID), !anyDuplicated(det$CamID),
          length(codes) == 18, setequal(codes, spp$SppCode), nrow(spp) == 18,
          all(det$k >= 4 & det$k <= 13), !anyNA(det), sum(cov$Days) == 22976,
          all(cov$Cam %in% c("Single", "Both")), all(cov$Days >= 45 & cov$Days <= 184))
m <- as.matrix(det[, ..codes])
stopifnot(all(m == round(m)), all(m >= 0), all(m <= det$k), max(m) == 12, sum(m) == 2712)
# k is not a deterministic function of Days (7 stations have k > ceiling(Days / 14)); both are shipped
cat(sprintf("  138 stations, 18 species, %d station-windows surveyed, %d species-windows with a detection\n", sum(det$k), sum(m)))

# ---- taxa --------------------------------------------------------------------------------
tx <- data.table(code = c("S01", "S02", "S03", "S04", "S05", "S07", "S09", "S10", "S11", "S12", "S13", "S14", "S15", "S17", "S19", "S20", "S22", "S23"),
                 taxon = c("PANTIG", "PANPAR", "SUSSCR", "CAPPYG", "CERNIP", "URSUS", "VULVUL", "MELLEU", "NYCPRO", "MOSMOS", "MUSSIB", "MARZIB", "MARFLA", "PRIBEN", "SCIVUL", "TAMSIB", "ERIAMU", "LEPMAN"),
                 lookup = c("Panthera tigris", "Panthera pardus", "Sus scrofa", "Capreolus pygargus", "Cervus nippon", "Ursus", "Vulpes vulpes", "Meles leucurus", "Nyctereutes procyonoides", "Moschus moschiferus", "Mustela sibirica", "Martes zibellina", "Martes flavigula", "Prionailurus bengalensis", "Sciurus vulgaris", "Tamias sibiricus", "Erinaceus amurensis", "Lepus mandshuricus"),
                 rank = c("subspecies", "subspecies", "species", "species", "species", "genus", "species", "species", "species", "species", "species", "species", "species", "subspecies", "species", "species", "species", "species"),
                 iucn = c("EN", "VU", NA, NA, NA, NA, NA, NA, NA, "VU", NA, NA, NA, NA, NA, NA, NA, NA))
tx <- merge(tx, spp, by.x = "code", by.y = "SppCode")
stopifnot(nrow(tx) == 18, !anyDuplicated(tx$taxon))
taxa <- make_taxa(tx$taxon, tx$SciName, vernacularName = tx$CommName, taxonRank = tx$rank, lookupName = tx$lookup,
                  taxon_family = tx$Family, taxon_sourceCode = tx$code, taxon_iucnCategory = tx$iucn)
stopifnot(!anyNA(taxa$taxonID))

# ---- long table ----------------------------------------------------------------------------
long <- melt(det, id.vars = c("CamID", "k"), measure.vars = codes, variable.name = "code", value.name = "y", variable.factor = FALSE)
long <- merge(long, tx[, .(code, taxon)], by = "code")
long <- merge(long, cov, by = "CamID")
long <- long[, .(unit = CamID, taxon, y = as.integer(y), obs_trials = as.integer(k),
                 unit_cam_type = Cam, unit_trap_days = as.integer(Days),
                 unit_human_detection_rate = HumanDetectionRate, unit_cattle_detection_rate = CattleDetectionRate,
                 unit_elev_m = as.integer(Elev), unit_dist_settlement_m = Dist.settlement, unit_dist_border_m = Dist.border,
                 unit_dist_road_m = Dist.road, unit_dist_river_m = Dist.river, unit_ndvi = NDVI,
                 unit_basal_area = BA, unit_canopy_transparency = Transparent)]
long <- order_eco(long)
stopifnot(nrow(long) == 138 * 18, sum(long$y) == sum(m), all(long$y <= long$obs_trials), uniqueN(long$unit) == 138)

dataset <- list(
  title = "Camera-trap detections of 18 mammal species at 138 stations in a cattle-grazed temperate forest, Northeast China: 14-day windows with a detection out of windows surveyed",
  creator = "Feng, Jia-Wei; Sun, Yi-Fei; Li, Hailong; Xiao, Yuqian; Zhang, Dandan; Smith, James L. D.; Ge, Jianping; Wang, Tian-Ming",
  pubDate = "2021", doi = "10.5061/dryad.2jm63xsnp", sourceURL = "https://doi.org/10.5061/dryad.2jm63xsnp",
  citation = "Feng, J.-W., Sun, Y.-F., Li, H., Xiao, Y., Zhang, D., Smith, J. L. D., Ge, J., & Wang, T.-M. (2021). Assessing mammal species richness and occupancy in a Northeast Asian temperate forest shared by cattle [Data set]. Dryad. https://doi.org/10.5061/dryad.2jm63xsnp",
  paperDOI = "10.1111/ddi.13237",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "The authors' summarised camera-trap detection matrix for a terrestrial mammal community in temperate forest along the China-Russia border, Northeast China: 138 camera stations, 22,976 trap days, 18 species used in their multi-species occupancy model (21 photographed). For each station and species the deposit gives the number of 14-day windows in which the species was detected at least once and the number of windows the station was surveyed (4-13); the window-level histories were not deposited. One row per station x species, y = windows with a detection, obs_trials = windows surveyed (responseType binomial_count). Twelve site covariates as deposited, including human and cattle detection rates at the same cameras, elevation, distances to settlement, border, road and river, NDVI, basal area and canopy transparency. No coordinates.",
  samplingProtocol = "Camera traps (single or paired, 'Cam') at 138 stations for 45-184 trap days each; detections summarised by the authors into 14-day windows per station (k windows surveyed, 0-k windows with a detection per species).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  effortColumn = "obs_trials",
  responseType = "binomial_count", unitKind = "site",
  closure = "one season (the whole deployment of each station, 45-184 trap days, is one closed period; the 14-day windows are collapsed into obs_trials)",
  geographicCoverage = "Temperate forest across the China-Russia border, Northeast China (the paper's study area; no coordinates deposited)",
  temporalCoverage = "not deposited: one camera-trapping season of up to 184 trap days per station; the year is in Feng et al. 2021 (doi:10.1111/ddi.13237), which the agent could not fetch",
  coordinatesCoarsened = list(value = FALSE, method = "no coordinates in the deposit; Amur tiger (EN), leopard (VU, Amur subspecies CR) and Siberian musk deer (VU) are present, so none can be added"),
  notes = "Species codes are six letters from the scientific name; the deposit's S-codes are in __taxa.taxon_sourceCode (S06, S08, S16, S18 and S21 are not in the deposit: 21 species photographed, 18 modelled). Three taxa are deposited as subspecies and the black bear at genus ('Ursus'); GBIF keys are at the species or genus level accordingly. unit_human_detection_rate and unit_cattle_detection_rate are detections of humans and cattle at the same cameras, the authors' disturbance covariates. k is not a deterministic function of trap days (7 stations have k > ceiling(Days/14)); both are shipped as deposited.",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)

stage_dict_row(TABLE,
  description = "Camera-trap community data for 18 mammal species at 138 stations in cattle-grazed temperate forest along the China-Russia border, Northeast China: per station x species the number of 14-day windows with a detection and the number of windows surveyed (binomial_count), with 12 site covariates as deposited; no coordinates.",
  url = "https://doi.org/10.5061/dryad.2jm63xsnp",
  reference = "Feng, J.-W., Sun, Y.-F., Li, H., Xiao, Y., Zhang, D., Smith, J. L. D., Ge, J., & Wang, T.-M. (2021). Assessing mammal species richness and occupancy in a Northeast Asian temperate forest shared by cattle. Diversity and Distributions, 27(5), 857-872.",
  doi_paper = "10.1111/ddi.13237", doi_data = "10.5061/dryad.2jm63xsnp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First binomial_count table (ruling #34): occasions collapsed by the authors to 14-day windows with a detection out of k surveyed. Held in batch 7, built in batch 10. Study year only in the paper (not fetchable).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (binomial counts over 14-day windows)",
  sampling_protocol = "camera_trap", design = "Single-season (138 stations, 4-13 fourteen-day windows collapsed to a count)", realm = "Terrestrial",
  country = "CHN", coordinates = "None in source",
  notes = "responseType binomial_count (#34): y = windows with a detection, obs_trials = windows surveyed. 18 species incl. Amur tiger (EN) and leopard; no coordinates.")
