#!/usr/bin/env Rscript
# Table:  kyaw_2024_myanmar_mamm_comm
# Source: Dryad doi:10.5061/dryad.0gb5mkm6w, version 4 (2024-10-03), CC0 1.0 (Dryad page and
#         deposited README agree; the README carries no separate licence).
#   Kyaw, P. P., Cushman, S. A., Kaszta, Z., Burnham, D., Zaw, T., Naing, H., ... Macdonald, D. W.
#   (2024). Myanmar mammal occupancy baseline assessment dataset. Dryad.
# Paper:  Kyaw et al. (2024). Seeing the big- to fine-grained picture: exploring the baseline
#         status of mammal occupancy across Myanmar using scale-optimised modelling. Diversity
#         and Distributions 30(11), e13934, doi:10.1111/ddi.13934 (CC BY 4.0; the publisher
#         returns 403 to the agent, so survey dates come from the deposit's own site codes).
# Data:   one .rar (read with libarchive via the R package `archive`) holding 14 folders and
#         an example unmarked script. <SITE>_o10/: one csv per species detected at that site,
#         Station x o1..ok (the README says V1..Vk), 0/1/NA, k 10-day occasions. Myan_o10/: the authors' pooled
#         national matrices, 46 species x 518 stations x 17 occasions, with 0 for a species
#         at a site where it was never detected. EffortMatrix/: Station x o1..ok, camera
#         days per occasion (0.5-10), NA = not operating; one file per survey plus the pooled
#         Myan_Effort_NotScaled.csv. Covariates/: Station x 30 (six GEE-derived predictors at
#         500/1000/1500/2000/4000 m buffers) per survey plus the pooled MyanCovs.csv. No
#         coordinates and no dates are deposited.
#         Checked: the 46 pooled matrices share one station order and one NA pattern
#         (5,746 of 8,806 station-occasions); effort is NA exactly where detections are NA
#         and is never 0; the pooled effort file and covariate file have the same stations
#         in the same order. The 11 per-survey effort files partition the 518 stations
#         (MMLK_Effort is the union of the five MMLK subsets; MMLKSD1718_Effort holds the
#         SD stations that ST_o10 calls Say Taung). Per-survey matrices match the pooled
#         ones on their shared occasions; HMT's per-site files stop at occasion 16 while
#         the pooled files carry a 17th HMT occasion (pooled wins). The moonrat
#         (Echinosorex gymnura) has per-site files in three MMLK surveys but no pooled
#         matrix, so the pooled table has 46 of the paper's 47 species.
#
# Mapping (standard section 3.6, community occupancy): unit = camera station (deposited
#   name), taxon = the README's species code upper-cased, occasion = 1..17 (10-day windows,
#   indexed within each survey, not calendar-aligned across surveys), y = 0/1, one period
#   (every station was surveyed once; the 2014-2020 span is across surveys, not repeat
#   visits). obs_camera_days = effort per station-occasion (surveyEvidence = effort_table).
#   unit_survey = the deposit's survey code (AKNP17, HKNP17, HMT, MMLK1415, MMLK16, MMLK17,
#   MMLKBC1718, MMLKPW20, RYER, ST), unit_site = the protected area / KBA it belongs to,
#   unit_<var>_<m> = the 30 deposited covariates (not standardised). PANGOLIN is genus-level
#   (Manis; the README says "Pangolin species"). BMONITOR is a reptile the authors kept in
#   the mammal community; shipped as deposited.
#   Not shipped: per-site folders (subsets of the pooled matrices), MMLK_o10 regional
#   combination, the *_noMMLK16 variants (analysis subsets), moonrat (no pooled matrix),
#   the example R script.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "kyaw_2024_myanmar_mamm_comm"
dir <- download_dryad("10.5061/dryad.0gb5mkm6w", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rar <- file.path(dir, "MyanmarMammalOccupancyData.rar"); stopifnot(file.exists(rar))
ex <- file.path(dir, "rar")
if (!dir.exists(file.path(ex, "Myan_o10"))) archive::archive_extract(rar, dir = ex)
stopifnot(length(list.files(ex, recursive = TRUE)) == 329)

# --- species: README code -> name; the pooled folder has 46 of the README's 47 codes -----
sp <- fread(text = "
code,scientificName,vernacularName,rank
Abbear,Ursus thibetanus,Asiatic black bear,species
Abtporcupine,Atherurus macrourus,Asiatic brush-tailed porcupine,species
Aelephant,Elephas maximus,Asian elephant,species
Agcat,Catopuma temminckii,Asiatic golden cat,species
Amacaque,Macaca assamensis,Assam macaque,species
Apcivet,Paradoxurus hermaphroditus,Asian palm civet,species
Ascotter,Aonyx cinereus,Asian small-clawed otter,species
banteng,Bos javanicus,Banteng,species
Bfbadger,Melogale personata,Burmese ferret-badger,species
binturong,Arctictis binturong,Binturong,species
blinsang,Prionodon linsang,Banded linsang,species
Bmonitor,Varanus bengalensis,Bengal monitor,species
cemongoose,Urva urva,Crab-eating mongoose,species
Cfbadger,Melogale moschata,Chinese ferret-badger,species
cleopard,Neofelis nebulosa,Clouded leopard,species
dhole,Cuon alpinus,Dhole,species
Ewpig,Sus scrofa,Eurasian wild pig,species
Fmuntjac,Muntiacus feae,Fea's muntjac,species
gaur,Bos gaurus,Gaur,species
Gmuntjac,Muntiacus gongshanensis,Gongshan muntjac,species
hbadger,Arctonyx collaris,Hog badger,species
lcat,Prionailurus bengalensis,Leopard cat,species
leopard,Panthera pardus,Leopard,species
lIcivet,Viverra zibetha,Large Indian civet,species
lmdeer,Tragulus kanchil,Lesser mouse-deer,species
lscivet,Viverra megaspila,Large-spotted civet,species
mcat,Pardofelis marmorata,Marbled cat,species
mpcivet,Paguma larvata,Masked palm civet,species
Mporcupine,Hystrix brachyura,Malayan porcupine,species
Msbear,Helarctos malayanus,Malayan sun bear,species
Mserow,Capricornis sumatraensis,Mainland serow,species
Mtapir,Tapirus indicus,Malayan tapir,species
Nptmacaque,Macaca leonina,Northern pig-tailed macaque,species
pangolin,Manis,Pangolin (species not separated),genus
rmacaque,Macaca mulatta,Rhesus macaque,species
rmuntjac,Muntiacus vaginalis,Northern red muntjac,species
rpanda,Ailurus fulgens,Red panda,species
rserow,Capricornis rubidus,Red serow,species
sambar,Rusa unicolor,Sambar,species
sIcivet,Viverricula indica,Small Indian civet,species
slangur,Trachypithecus shortridgei,Shortridge's langur,species
slinsang,Prionodon pardicolor,Spotted linsang,species
stmacaque,Macaca arctoides,Stump-tailed macaque,species
takin,Budorcas taxicolor,Takin,species
tiger,Panthera tigris,Tiger,species
ytmarten,Martes flavigula,Yellow-throated marten,species")
stopifnot(nrow(sp) == 46, !anyDuplicated(toupper(sp$code)))
files <- file.path(ex, "Myan_o10", paste0("Myan", sp$code, "_o10.csv"))
stopifnot(all(file.exists(files)), length(list.files(file.path(ex, "Myan_o10"))) == 46)

hist <- lapply(files, fread)
stations <- hist[[1]]$Station
stopifnot(length(stations) == 518, !anyDuplicated(stations), all(sapply(hist, ncol) == 18),
          all(sapply(hist, function(h) identical(h$Station, stations) && identical(names(h)[-1], paste0("o", 1:17)))))
y <- array(unlist(lapply(hist, function(h) as.matrix(h[, -1]))), dim = c(518, 17, 46),
           dimnames = list(stations, NULL, toupper(sp$code)))
stopifnot(all(y %in% c(0, 1, NA)))
na_hist <- is.na(y[, , 1]); stopifnot(all(apply(is.na(y), 3, identical, na_hist)), sum(na_hist) == 5746)
stopifnot(all(apply(y, 3, sum, na.rm = TRUE) >= 1))   # every pooled species has at least one detection

# --- effort: camera days per station-occasion, the survey evidence --------------------------
eff <- fread(file.path(ex, "EffortMatrix", "Myan_Effort_NotScaled.csv"))
stopifnot(identical(eff$Station, stations), identical(names(eff)[-1], paste0("o", 1:17)))
e <- as.matrix(eff[, -1])
stopifnot(all(is.na(e) == na_hist), all(e > 0, na.rm = TRUE), all(e <= 10, na.rm = TRUE))
cat(sprintf("  %d of %d stations have non-trailing gaps in camera operation\n",
            sum(apply(na_hist, 1, function(r) any(diff(as.integer(r)) < 0))), nrow(na_hist)))

# --- survey membership from the per-survey effort files --------------------------------------
surveys <- c(AKNP17 = "AKNP17_Effort_NoScaled.csv", HKNP17 = "HKNP17_Effort_NotScaled.csv",
             HMT = "HMT_Effort_NoScaled.csv", MMLK1415 = "MMLK1415_Effort_NoScaled.csv",
             MMLK16 = "MMLK16_Effort_NotScaled.csv", MMLK17 = "MMLK17_Effort_NoScaled.csv",
             MMLKBC1718 = "MMLKBC1718_Effort_NoScaled.csv", MMLKPW20 = "MMLKPW20_Effort_NotScaled.csv",
             RYER = "RYER_Effort_NoScaled.csv", ST = "MMLKSD1718_Effort_NoScaled.csv")
site_of <- c(AKNP17 = "Alaungdaw Kathapa National Park", HKNP17 = "Hkakaborazi National Park",
             HMT = "Htamanthi Wildlife Sanctuary", MMLK1415 = "Myinmoletkhat Key Biodiversity Area",
             MMLK16 = "Myinmoletkhat Key Biodiversity Area", MMLK17 = "Myinmoletkhat Key Biodiversity Area",
             MMLKBC1718 = "Myinmoletkhat Key Biodiversity Area", MMLKPW20 = "Myinmoletkhat Key Biodiversity Area",
             RYER = "Rakhine Yoma Elephant Range", ST = "Say Taung Key Biodiversity Area")
memb <- rbindlist(lapply(names(surveys), function(s) {
  se <- fread(file.path(ex, "EffortMatrix", surveys[[s]]))
  k <- ncol(se) - 1
  m <- e[match(se$Station, stations), 1:k, drop = FALSE]
  stopifnot(all(se$Station %in% stations), isTRUE(all.equal(as.matrix(se[, -1]), m, check.attributes = FALSE)))
  data.table(unit = se$Station, survey = s)
}))
stopifnot(nrow(memb) == 518, !anyDuplicated(memb$unit), setequal(memb$unit, stations))
stopifnot(identical(sort(unique(fread(file.path(ex, "ST_o10", "STdhole_o10.csv"))$Station)), sort(memb[survey == "ST", unit])))
stopifnot(nrow(fread(file.path(ex, "EffortMatrix", "MMLK_Effort_NotScaled.csv"))) == 238,
          memb[grepl("^MMLK", survey), .N] == 238)
memb <- memb[match(stations, unit)]

# --- covariates: the 30 deposited columns, not standardised ----------------------------------
cv <- fread(file.path(ex, "Covariates", "MyanCovs.csv"))
stopifnot(identical(cv$Station, stations), ncol(cv) == 31, !anyNA(cv))
vars <- c("dwater", "ele", "rough", "popu", "gpp", "ndvi"); scales <- c(500, 1000, 1500, 2000, 4000)
cov_cols <- as.vector(outer(vars, scales, paste, sep = "_"))
stopifnot(setequal(names(cv)[-1], cov_cols))
long_names <- c(dwater = "water_density", ele = "elevation_m", rough = "terrain_roughness",
                popu = "population_density", gpp = "gpp", ndvi = "ndvi")
site_covs <- data.table(survey = memb$survey, site = site_of[memb$survey])
for (v in vars) for (s in scales) site_covs[, (paste0(long_names[[v]], "_", s, "m")) := cv[[paste0(v, "_", s)]]]

long <- array_to_eco(y, site_ids = stations, site_covs = site_covs, obs_covs = list(camera_days = e))
stopifnot(nrow(long) == 46 * sum(!na_hist), !anyNA(long$obs_camera_days), uniqueN(long$taxon) == 46)

taxa <- make_taxa(toupper(sp$code), sp$scientificName, vernacularName = sp$vernacularName, taxonRank = sp$rank)
stopifnot(!anyNA(taxa$taxonID))

dataset <- list(
  title = "Camera-trap detection histories of 46 terrestrial mammal taxa (and the Bengal monitor) at 518 stations in six protected areas across Myanmar, 2014-2020, 10-day occasions",
  creator = "Kyaw, Pyae Phyoe; Cushman, Samuel A.; Kaszta, Zaneta; Burnham, Dawn; Zaw, Than; Naing, Hla; Htun, Saw; Moe, Kyaw; Tun, Aung Ye; Myo, Okka; Aung, Zarni; Myo, Khin Myo; Aung, Htet Arkar; Po, Saw Htoo Tha; Po, Saw Ehkhu; Nay, Saw Hay; Tun, Saw William L.; Macdonald, David W.",
  pubDate = "2024",
  doi = "10.5061/dryad.0gb5mkm6w", sourceURL = "https://doi.org/10.5061/dryad.0gb5mkm6w",
  citation = "Kyaw, P. P., Cushman, S. A., Kaszta, Z., Burnham, D., Zaw, T., Naing, H., Htun, S., Moe, K., Tun, A. Y., Myo, O., Aung, Z., Myo, K. M., Aung, H. A., Po, S. H. T., Po, S. E., Nay, S. H., Tun, S. W. L., & Macdonald, D. W. (2024). Myanmar mammal occupancy baseline assessment dataset [Dataset]. Dryad. https://doi.org/10.5061/dryad.0gb5mkm6w",
  paperDOI = "10.1111/ddi.13934",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://spdx.org/licenses/CC0-1.0.html"),
  abstract = "Wildlife Conservation Society Myanmar camera-trap surveys (2014-2020) in Hkakaborazi National Park, Htamanthi Wildlife Sanctuary, Alaungdaw Kathapa National Park, Rakhine Yoma Elephant Range and the Say Taung and Myinmoletkhat Key Biodiversity Areas, pooled by the authors into one national detection matrix of 518 camera stations x 17 ten-day occasions x 46 taxa, with camera days per station-occasion and six Google Earth Engine predictors (water density, elevation, terrain roughness, human population density, GPP, NDVI) at five buffer scales (500-4000 m). Surveys targeted different focal species, so station spacing varies (1-3 km, or 2-km2 and 16-km2 grids). Occasions are indexed within each survey and are not calendar-aligned across surveys. The paper reports 47 species; the moonrat appears only in three per-site folders and not in the pooled matrix, so it is not here.",
  samplingProtocol = "Passive camera traps at stations 1000-3000 m apart or on 2-km2 / 16-km2 grids, depending on the survey's focal species; detection history at 10 days per occasion; camera days per occasion is the effort covariate.",
  samplingProtocolCode = "camera_trap", occasionLength = "10 days", effortColumn = "obs_camera_days",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "occasion",
  geographicCoverage = "Six protected areas and Key Biodiversity Areas across Myanmar (no coordinates deposited)",
  temporalCoverage = "2014/2020",
  coordinatesCoarsened = NA,
  notes = "unit_survey is the deposit's survey code (the year, where the code carries one, is the survey year: AKNP17 and HKNP17 = 2017, MMLK1415 = 2014-15, MMLK16 = 2016, MMLK17 = 2017, MMLKBC1718 and ST = 2017-18, MMLKPW20 = 2020; HMT and RYER are undated in the deposit). Each station was surveyed in one survey only, so the table has one period. Covariate definitions are the README's; values are as deposited, not standardised.",
  notShipped = list(`<SITE>_o10/ folders` = "per-survey subsets of the pooled matrices (HMT's stop one occasion short of the pooled file)",
                    `MMLK_o10/` = "the authors' regional combination of the five MMLK surveys",
                    `*_noMMLK16_o10.csv` = "analysis variants dropping one survey",
                    moonrat = "Echinosorex gymnura has per-site files in MMLK16, MMLK17 and MMLKPW20 but no pooled matrix",
                    ExampleCode_AKNP17Agcat.R = "the authors' unmarked workflow"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/kyaw_2024_myanmar_mamm_comm.R")

stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of 46 taxa (45 mammals incl. tiger, Asian elephant, dhole, clouded leopard, pangolin, plus the Bengal monitor) at 518 camera stations in six protected areas across Myanmar over up to 17 ten-day occasions (2014-2020), with camera days per occasion and six environmental predictors at five buffer scales per station.",
  url = "https://doi.org/10.5061/dryad.0gb5mkm6w",
  reference = "Kyaw, P. P., Cushman, S. A., Kaszta, Z., Burnham, D., Zaw, T., Naing, H., ... Macdonald, D. W. (2024). Seeing the big- to fine-grained picture: exploring the baseline status of mammal occupancy across Myanmar using scale-optimised modelling. Diversity and Distributions, 30(11), e13934.",
  doi_paper = "10.1111/ddi.13934", doi_data = "10.5061/dryad.0gb5mkm6w",
  original_license = "CC0 1.0", derived_license = "CC0-1.0",
  notes = "Built from the authors' pooled national matrices (Myan_o10, Myan_Effort, MyanCovs); survey membership from the per-survey effort files. 5,746 of 8,806 station-occasions not surveyed. No coordinates in the deposit. Moonrat (per-site only) not shipped. Deposited as a .rar; fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy",
  sampling_protocol = "camera_trap", design = "Single-season", realm = "Terrestrial", country = "MMR",
  coordinates = "None in source",
  notes = "Ten surveys in six protected areas pooled by the authors; occasions indexed within survey. PANGOLIN is genus-level; BMONITOR is a reptile kept by the authors. Many IUCN-threatened taxa, no coordinates to coarsen.",
  status = "tagged")
