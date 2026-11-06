#!/usr/bin/env Rscript
# Table:  barros_2024_mostela_weasel_occ
# Source: Zenodo doi:10.5281/zenodo.7561951, published 2023-01-23, licence CC BY 4.0 (record metadata
#         license id "cc-by-4.0", asserted from the cached Zenodo record JSON).
#   Barros, A. L., Marques, M., Alcobia, S., MacKenzie, D. I. & Santos-Reis, M. (2023). Comparing the
#   performance of two camera trap-based methods to survey small mustelids [Dataset]. Zenodo.
# Paper:  Barros, A. L., Marques, M., Alcobia, S., MacKenzie, D. I. & Santos-Reis, M. (2024). Comparing the
#         performance of two camera trap-based methods to survey small mustelids. Basic and Applied Ecology
#         75, 18-25. doi:10.1016/j.baae.2024.01.004 (open access, CC BY).
#         What the paper settles (Materials and methods, pp. 19-21; Results and Table 1, p. 21):
#         - the deposit is the 2021 350 m grid field tests only ("We only used the detection data from the
#           350 m grid field tests (both study areas) to model weasel occupancy", p. 20): Companhia das
#           Lezirias (CL), 30 stations, January-February 2021; Herdade da Ribeira Abaixo (HRA), 26 stations,
#           March-April 2021 (p. 19, Field tests; Table 1 caption). The 2020 pilot (2 km grid, 25 stations)
#           is not deposited.
#         - each station has a Mostela (a wooden box with a tracking tube and an internal camera) and a
#           tree-mounted camera ("tree-camera") up to 6 m apart, both run 24 h, no bait (p. 19-20).
#         - "we collapsed detection events into seven occasions of five days each" (p. 21, Statistical
#           analysis); the model is the multi-scale occupancy model (Nichols et al. 2008) in its temporal
#           form: psi = station occupancy, theta = availability near the devices in an occasion, p_d =
#           detection by device d (p. 21).
#         - Table 1 (p. 21): Mostela trap-nights CL 1052, HRA 858; tree-camera HRA 858 (asserted against
#           nM / nC); weasel stations: CL 5 by Mostela, none by tree-camera; HRA 1 by Mostela, 1 (another
#           station) by tree-camera (asserted). The small-mammal trapping rate is events per 100
#           trap-nights inside the Mostela, CL 124.19, HRA 15.82 (p. 21-22; the deposit gives it per
#           trap-night, asserted).
# Data:   Mostela_data_multi-scale_occupancy.csv, 56 rows (one per station): ID 1-56, Area (CL / HRA),
#         CT1-CT7 (tree-camera detection in occasion 1-7), nC (tree-camera trap-nights), Tree.Cover,
#         Shrub.Cover, Herbaceous.Cover (cover rank in a 50 m buffer: 1 low 5-25 %, 2 medium 25-75 %,
#         3 high 75-100 %; p. 20), logSM_TrapRate, Mostela1-Mostela7 (Mostela detection in occasion 1-7),
#         nM (Mostela trap-nights), SM_TrapRate (small-mammal events per trap-night inside the Mostela).
#         Three NA cells: station 19, Mostela1-3, where nM = 19 against nC = 35: the Mostela was not
#         operating for the first three occasions (the only station with nM != nC). The paper does not
#         mention the gap; the effort column is the evidence.
# Mapping (E9 experimental, paired methods at one visit = one table with obs_method, ruling #31 clarified):
#   unit = station ("CL_01".."HRA_56", the deposit's ID with its area), taxon = MUSNIV, occasion =
#   2 * (k - 1) + d for five-day occasion k = 1..7 and device d (1 = Mostela, 2 = tree-camera),
#   occasionKind = c("time", "method"), obs_window = k, obs_method = "mostela" / "tree_camera"; y = the
#   deposited 0/1. The paper's multi-scale model groups rows by (unit, obs_window): availability theta
#   at the window, p_d per device.
#   Covariates: unit_area, unit_tree_cover, unit_shrub_cover, unit_herb_cover (ranks), unit_small_mammal_rate
#   (SM_TrapRate: small-mammal events per trap-night counted from the Mostela camera; a count of other
#   animals, not a model output); obs_station_trap_nights = nM on Mostela rows, nC on tree-camera rows
#   (the station's total for the device; per-occasion effort is not deposited).
#   surveyEvidence = deposited_matrix: NA (station 19, Mostela, occasions 1-3) is distinct from 0 and
#   matches the lower Mostela effort; those three device-occasions have no rows. The tree-camera rows of
#   the same occasions stay: the two devices are separate detectors.
#   Not shipped: logSM_TrapRate (log10 of SM_TrapRate, 0 where the rate is 0; asserted, recomputable);
#   the paper's psi / theta / p estimates (model output). No coordinates, no per-station dates deposited.
#   IUCN: Mustela nivalis LC; no coordinates, so E7 does not arise.
#   Note: nC sums to 1068 at CL, the paper's Table 1 gives 1029 tree-camera trap-nights there; the
#   deposit is shipped as deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "barros_2024_mostela_weasel_occ"

f <- download_cached("https://zenodo.org/api/records/7561951/files/Mostela_data_multi-scale_occupancy.csv/content", TABLE)
meta_f <- file.path(dirname(f), "zenodo_record.json")
if (!file.exists(meta_f)) download.file("https://zenodo.org/api/records/7561951", meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.7561951"),
          identical(meta$files$key, "Mostela_data_multi-scale_occupancy.csv"))

d <- fread(f)
setnames(d, trimws(names(d)))
CT <- paste0("CT", 1:7); MO <- paste0("Mostela", 1:7)
stopifnot(identical(names(d), c("ID", "Area", CT, "nC", "Tree.Cover", "Shrub.Cover", "Herbaceous.Cover", "logSM_TrapRate",
                                MO, "nM", "SM_TrapRate")),
          nrow(d) == 56L, identical(d$ID, 1:56), identical(d$Area, rep(c("CL", "HRA"), c(30L, 26L))),
          all(unlist(d[, c(CT, MO), with = FALSE]) %in% c(0L, 1L, NA)), !anyNA(d[, CT, with = FALSE]),
          sum(is.na(d[, MO, with = FALSE])) == 3L, d[ID == 19, all(is.na(c(Mostela1, Mostela2, Mostela3)))],
          d[ID != 19, all(nC == nM)], d[ID == 19, nC == 35L & nM == 19L],
          d[, all(nC >= 32L & nC <= 37L)],
          # Table 1, p. 21: Mostela trap-nights CL 1052, HRA 858; tree-camera HRA 858
          d[Area == "CL", sum(nM)] == 1052L, d[Area == "HRA", sum(nM)] == 858L, d[Area == "HRA", sum(nC)] == 858L,
          d[Area == "CL", sum(nC)] == 1068L,
          all(unlist(d[, .(Tree.Cover, Shrub.Cover, Herbaceous.Cover)]) %in% 1:3),
          d[, all(abs(logSM_TrapRate - ifelse(SM_TrapRate == 0, 0, log10(SM_TrapRate))) < 1e-6)],
          # p. 21-22: small-mammal rate per 100 trap-nights, CL 124.19, HRA 15.82
          abs(d[Area == "CL", mean(SM_TrapRate)] * 100 - 124.19) < 0.01, abs(d[Area == "HRA", mean(SM_TrapRate)] * 100 - 15.82) < 0.01)
detM <- d[, rowSums(.SD, na.rm = TRUE) > 0, .SDcols = MO]; detC <- d[, rowSums(.SD) > 0, .SDcols = CT]
stopifnot(identical(d$ID[detM], c(1L, 12L, 14L, 15L, 22L, 33L)), identical(d$ID[detC], 37L))

d[, unit := sprintf("%s_%02d", Area, ID)]
mk <- function(cols, dev, meth, eff) {
  x <- melt(d, id.vars = "unit", measure.vars = cols, variable.name = "w", value.name = "y")
  x[, obs_window := as.integer(sub("\\D+", "", w))][, w := NULL]
  x[, `:=`(occasion = 2L * (obs_window - 1L) + dev, obs_method = meth)]
  x <- merge(x, d[, .(unit, obs_station_trap_nights = get(eff))], by = "unit")
  x[!is.na(y)] }
long <- rbindlist(list(mk(MO, 1L, "mostela", "nM"), mk(CT, 2L, "tree_camera", "nC")))
long <- merge(long, d[, .(unit, unit_area = Area, unit_tree_cover = Tree.Cover, unit_shrub_cover = Shrub.Cover,
                          unit_herb_cover = Herbaceous.Cover, unit_small_mammal_rate = SM_TrapRate)], by = "unit")
long[, taxon := "MUSNIV"]
long[, y := as.integer(y)]
long <- order_eco(long)
stopifnot(nrow(long) == 56L * 14L - 3L, uniqueN(long$unit) == 56L, !anyDuplicated(long[, .(unit, occasion)]),
          sum(long[obs_method == "mostela"]$y) == 7L, sum(long[obs_method == "tree_camera"]$y) == 1L)
cat(sprintf("  %d rows, %d stations, detections: Mostela %d, tree-camera %d\n", nrow(long), uniqueN(long$unit),
            sum(long[obs_method == "mostela"]$y), sum(long[obs_method == "tree_camera"]$y)))

taxa <- make_taxa("MUSNIV", "Mustela nivalis", vernacularName = "Least weasel")
stopifnot(identical(iucn_category(taxa$taxonID, taxa$scientificName), "LC"))
taxa[, taxon_iucnCategory := "LC"]

dataset <- list(
  title = "Least weasel detections by a Mostela box and a tree-mounted camera at 56 paired stations over seven five-day occasions, Companhia das Lezirias and Herdade da Ribeira Abaixo, Portugal, 2021",
  creator = "Barros, Ana Luisa; Marques, Margarida; Alcobia, Sandra; MacKenzie, Darryl I.; Santos-Reis, Margarida",
  pubDate = "2023", doi = "10.5281/zenodo.7561951", sourceURL = "https://doi.org/10.5281/zenodo.7561951",
  citation = "Barros, A. L., Marques, M., Alcobia, S., MacKenzie, D. I., & Santos-Reis, M. (2023). Comparing the performance of two camera trap-based methods to survey small mustelids [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.7561951",
  paperDOI = "10.1016/j.baae.2024.01.004",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "A test of the Mostela (a wooden box with a tracking tube and an internal camera trap) against a tree-mounted camera trap for detecting the least weasel. At each of 30 stations on a 350 m grid at Companhia das Lezirias (January-February 2021) and 26 at Herdade da Ribeira Abaixo (March-April 2021), Portugal, a Mostela and a tree-camera were set up to 6 m apart; detections were collapsed into seven five-day occasions per device. The authors fit a multi-scale occupancy model with device-specific detection. Vegetation cover ranks and the small-mammal trapping rate inside the Mostela are station covariates.",
  samplingProtocol = "Paired devices at each station, run 24 h without bait for about 35 days and visited every 15 days: a Mostela box with an internal camera (Browning Dark Ops HD Pro-X) and a tree-camera (Cuddelink J-1521) 20-30 cm above ground; a weasel photographed by a device in a five-day occasion is a detection.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "dependent",
  closureNote = "Station occupancy is assumed closed across the seven five-day occasions (the authors note it may be read as use). The two devices at one occasion are simultaneous and the authors model their dependence through an availability parameter per station-occasion (temporal multi-scale model, Nichols et al. 2008): group rows by unit and obs_window.",
  occasionKind = c("time", "method"), taxonInclusion = "single",
  designNote = "Experimental list of E9 (paired methods, multi-scale): occasion = 2 * (window - 1) + device, device 1 = Mostela, 2 = tree-camera; obs_window and obs_method recover both components.",
  geographicCoverage = "Companhia das Lezirias (38.84 N, 8.83 W) and Herdade da Ribeira Abaixo (38.11 N, 8.57 W), Portugal (no station coordinates deposited)",
  temporalCoverage = "2021-01/2021-04",
  covariateNote = "unit_area: CL (Companhia das Lezirias, January-February 2021) or HRA (Herdade da Ribeira Abaixo, March-April 2021). unit_tree_cover, unit_shrub_cover, unit_herb_cover: cover rank of the stratum in a 50 m buffer, 1 low (5-25 %), 2 medium (25-75 %), 3 high (75-100 %). unit_small_mammal_rate: small-mammal (rodent and insectivore) independent events (30 min apart) per trap-night recorded inside the Mostela. obs_window: five-day occasion 1-7. obs_method: mostela or tree_camera. obs_station_trap_nights: the device's total trap-nights at the station (per-occasion effort not deposited).",
  notShipped = list(
    mostela_not_operating = "3 device-occasions with NA (station 19, Mostela, occasions 1-3; the Mostela ran 19 trap-nights against 35 for the tree-camera): no rows; the tree-camera rows of those occasions are kept",
    logSM_TrapRate = "log10 of SM_TrapRate (0 where the rate is 0): recomputable from unit_small_mammal_rate",
    pilot_2020 = "the 2020 pilot (25 stations on a 2 km grid at CL) is not in the deposit",
    model_output = "the authors' multi-scale occupancy, availability and detection estimates"),
  notes = "Sparse: seven Mostela detections at six stations and one tree-camera detection. The deposit's tree-camera trap-nights sum to 1068 at CL against 1029 in the paper's Table 1; Mostela and HRA totals agree with Table 1. No dates per station: CL ran January-February 2021, HRA March-April 2021.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/barros_2024_mostela_weasel_occ.R")
stage_dict_row(TABLE,
  description = "Least weasel (Mustela nivalis) detections by a Mostela box and a tree-mounted camera at 56 paired stations in two Portuguese montado areas, seven five-day occasions, 2021, with vegetation cover and small-mammal rate covariates.",
  url = "https://doi.org/10.5281/zenodo.7561951",
  reference = "Barros, A. L., Marques, M., Alcobia, S., MacKenzie, D. I. & Santos-Reis, M. (2024). Comparing the performance of two camera trap-based methods to survey small mustelids. Basic and Applied Ecology 75, 18-25. https://doi.org/10.1016/j.baae.2024.01.004",
  doi_paper = "10.1016/j.baae.2024.01.004", doi_data = "10.5281/zenodo.7561951",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Paired-method multi-scale design in one table (obs_method); 3 NA Mostela occasions at station 19 have no rows.",
  source_via = "Zenodo (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-scale occupancy (paired methods: Mostela box vs tree-camera)",
  sampling_protocol = "camera_trap", design = "Single-season (56 stations, 7 five-day occasions x 2 devices)",
  realm = "Terrestrial", country = "PRT", coordinates = "None in source",
  notes = "Experimental (E9): paired devices per station-occasion; one tree-camera detection in total.")
