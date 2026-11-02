#!/usr/bin/env Rscript
# Table:  swedberg_2023_springfish_occ
# Source: Dryad doi:10.5061/dryad.hmgqnk9m3, version 259497 (published 2023-10-10), licence CC0 1.0
#         (as shown on Dryad). Swedberg, D., Brewer, S. & Mollenhauer, R. "Physicochemical habitat
#         data and multi-scale occupancy data for spring-associated fishes in Oklahoma streams".
# Paper:  The README cites the thesis "Assessing the distribution and habitat needs of the Least
#         Darter and sympatric species of the Ozark Highlands and Arbuckle Mountain ecoregions"
#         (Swedberg, Oklahoma State University) and the manuscript "The context dependency of
#         fish-habitat associations in separated karst ecoregions"; the Dryad record links no DOI.
# Data:   DATA.csv: 1,736 rows, one per sampling site (channel-unit complex: riffle-run-pool) x
#         species, 77 columns: ID (reach + site), Ecoregion (Arbuckle Uplift, Ozark Highlands),
#         Reach, Stream; four surveys per site (Date_y.1..4 as M/D/YYYY, Time_y.1..4 duration,
#         y.1..4 detection 0/1/NA, gear.1..4 snorkel or seine, and per-survey coarse wood, coarse
#         substrate, vegetation, velocity, depth, clarity, temperature); site habitat (fine
#         substrate, mesohabitat areas and proportions, residual pool depth, seepage, discharge,
#         two-week temperature, drainage area, land-use disturbance indices, agriculture). Surveys
#         1 and 2 are a snorkel and a seine pass on the first visit, 3 and 4 on the second visit
#         about a week later; summers 2018 and 2019. Species: the six target taxa (least darter
#         LD, southern redbelly dace SRBD, redspot chub RSC, orangethroat darter OTD, smallmouth
#         bass sub-adult SMB_JUV and adult SMB_AD) and ten other darters (CHD, OBD, LP, GSD, BND,
#         SBD, ARD, FNTL, DD, SHD) listed per reach (README: "other darter species encountered").
#         Quirks: site 2K_03's SRBD row is keyed "2k_03"; site 1N_02's OTD row is keyed "1N_12"
#         (no site 1N_12 exists; every survey and habitat column equals 1N_02's: asserted); 16
#         Arbuckle sites carry two identical CHD rows; site 4C_04's Area_Run runs 0, 1, 2, ...
#         down its 13 rows (a spreadsheet fill-down), and Total_Area and the Prop_* columns
#         computed from it vary accordingly; site 1B_02's Temp.2 is 23.6 on the LD row and 24.1
#         on its other eight rows (set to NA). Time_y.* is documented as hours.minutes ("1.15 is one hour
#         and fifteen minutes"), but 291 of 6,363 values have a fractional part of .60 or more, so
#         the encoding is mixed and the value is shipped as recorded.
#
# Mapping (standard E9 multi-scale community occupancy; responseType detection, unitKind site):
#   cluster_id = Reach (61 reaches; the authors' reach scale), unit = site ID (153 channel-unit
#   complexes), taxon = the six target taxa, occasion = survey 1..4 (1 snorkel / 2 seine on the
#   first visit, 3 snorkel / 4 seine on the second), y = detection. date = the survey date (ISO).
#   Survey evidence: the deposited matrix. A survey cell is surveyed iff y is not NA; the NA
#   pattern is identical across species within a site and equals the NA pattern of gear.* (both
#   asserted), so a row exists for every surveyed site x survey x target taxon.
#   Taxa: the six targets occur at every site (after the two key repairs); the ten other darters
#   are listed only for the reaches in which they were encountered, so their taxon sets differ
#   between sites (standard E4.2: one taxon set per community table) and they are not shipped
#   (rows counted in notShipped). Smallmouth bass sub-adults and adults keep the source's two
#   codes as two taxa, both Micropterus dolomieu, with taxon_life_stage in __taxa.
#   Covariates: obs_gear, obs_coarse_wood_pct, obs_coarse_substrate_pct, obs_vegetation_pct,
#   obs_velocity_m_s, obs_depth_m, obs_clarity_m, obs_water_temp_c, obs_duration_recorded (as
#   deposited, see above); unit_ecoregion, unit_stream, unit_year and the site habitat columns
#   (unit_*; Area_Run, Prop_Pool, Prop_Run, Prop_Riffle and Total_Area NA at 4C_04);
#   obs_water_temp_c NA for 1B_02 survey 2 (conflicting values).
#   Coordinates: none in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "swedberg_2023_springfish_occ"
dir <- download_dryad("10.5061/dryad.hmgqnk9m3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
x <- fread(file.path(dir, "DATA.csv"))
stopifnot(nrow(x) == 1736L, ncol(x) == 77L, uniqueN(x$ID) == 155L, uniqueN(x$Reach) == 61L,
          setequal(unique(x$Ecoregion), c("Arbuckle", "Ozark")))
TARGET <- c("LD", "SRBD", "RSC", "OTD", "SMB_JUV", "SMB_AD")
OTHER <- c("CHD", "OBD", "LP", "GSD", "BND", "SBD", "ARD", "FNTL", "DD", "SHD")
stopifnot(setequal(unique(x$Species), c(TARGET, OTHER)))
sc <- setdiff(names(x), c("ID", "Species", paste0("y.", 1:4)))
# key repairs (see header)
stopifnot(x[ID == "2k_03", .N] == 1L, x[ID == "2k_03", Species] == "SRBD", x[ID == "2K_03" & Species == "SRBD", .N] == 0L,
          x[ID == "1N_12", .N] == 1L, x[ID == "1N_12", Species] == "OTD", x[ID == "1N_02" & Species == "OTD", .N] == 0L,
          isTRUE(all.equal(unique(x[ID == "1N_12", ..sc]), unique(x[ID == "1N_02", ..sc]))),
          isTRUE(all.equal(unique(x[ID == "2k_03", ..sc]), unique(x[ID == "2K_03", ..sc]))))
x[ID == "2k_03", ID := "2K_03"]; x[ID == "1N_12", ID := "1N_02"]
n_chd_dup <- sum(duplicated(x[, .(ID, Species)]))
stopifnot(n_chd_dup == 16L, all(x[duplicated(x[, .(ID, Species)]), Species] == "CHD"),
          nrow(unique(x)) == nrow(x) - 16L)
x <- unique(x)
stopifnot(uniqueN(x$ID) == 153L, all(x[Species %in% TARGET, .N, by = ID]$N == 6L), x[Species %in% TARGET, uniqueN(ID)] == 153L)
# NA pattern of y identical across species within a site and equal to the gear NA pattern
for (k in 1:4) {
  yk <- paste0("y.", k); gk <- paste0("gear.", k)
  stopifnot(all(is.na(x[[yk]]) == is.na(x[[gk]])), all(x[, uniqueN(is.na(get(yk))), by = ID]$V1 == 1L),
            all(x[[yk]] %in% c(0L, 1L, NA)), all(x[[gk]] %in% c(ifelse(k %% 2 == 1, "snorkel", "seine"), NA)))
}
# site covariates constant within site except the documented 4C_04 fill-down and 1B_02 Temp.2
area_cols <- c("Area_Run", "Prop_Pool", "Prop_Run", "Prop_Riffle", "Total_Area")
var <- melt(x[, lapply(.SD, uniqueN), by = ID, .SDcols = sc], id.vars = "ID")[value > 1]
stopifnot(setequal(paste(var$ID, var$variable), c(paste("4C_04", area_cols), "1B_02 Temp.2")),
          identical(sort(unique(x[ID == "1B_02", Temp.2])), c(23.6, 24.1)))
n_other <- x[Species %in% OTHER, .N]
site <- x[Species == "LD"]                                     # one row per site carries every site and survey column
site[ID == "4C_04", (area_cols) := NA]
site[ID == "1B_02", Temp.2 := NA]

surv <- rbindlist(lapply(1:4, function(k) site[, .(ID, occasion = k, date = as.IDate(get(paste0("Date_y.", k)), "%m/%d/%Y"),
  obs_gear = get(paste0("gear.", k)), obs_duration_recorded = get(paste0("Time_y.", k)),
  obs_coarse_wood_pct = get(paste0("CW.", k)), obs_coarse_substrate_pct = get(paste0("CS.", k)),
  obs_vegetation_pct = get(paste0("Vegetation.", k)), obs_velocity_m_s = get(paste0("Velocity.", k)),
  obs_depth_m = get(paste0("Depth.", k)), obs_clarity_m = get(paste0("Clarity.", k)), obs_water_temp_c = get(paste0("Temp.", k)))]))
surv <- surv[!is.na(obs_gear)]
stopifnot(!anyNA(surv$date), all(year(surv$date) %in% 2018:2019), all(surv[, uniqueN(year(date)), by = ID]$V1 == 1L))
det <- melt(x[Species %in% TARGET, c("ID", "Species", paste0("y.", 1:4)), with = FALSE], id.vars = c("ID", "Species"),
            variable.name = "occ", value.name = "y", na.rm = TRUE)
det[, occasion := as.integer(sub("y.", "", occ, fixed = TRUE))]
long <- merge(det[, .(ID, Species, occasion, y)], surv, by = c("ID", "occasion"))
stopifnot(nrow(long) == nrow(det), nrow(long) == nrow(surv) * 6L)
ucov <- site[, .(ID, cluster_id = Reach, unit_ecoregion = ifelse(Ecoregion == "Ozark", "Ozark Highlands", "Arbuckle Uplift"),
                 unit_stream = Stream, unit_fine_substrate_pct = Fine_Substrate, unit_area_pool_m2 = Area_Pool,
                 unit_area_run_m2 = Area_Run, unit_area_riffle_m2 = Area_Riffle, unit_area_backwater_m2 = Area_BW,
                 unit_pool_depth_cm = Pool_Depth, unit_riffle_crest_cm = Riffle_Crest, unit_residual_pool_depth_cm = RPD,
                 unit_seepage_up = Seepage_Up, unit_seepage_down = Seepage_Down, unit_seepage_difference = Seepage_Difference,
                 unit_gaining_losing = ifelse(`Gaining/Losing` == 1L, "gaining", ifelse(`Gaining/Losing` == 2L, "losing", NA_character_)),
                 unit_discharge = Discharge, unit_two_week_temp_c = `2_Week_Temp`, unit_drainage_area_km2 = Drainage_Area,
                 unit_disturbance_250m = Disturbance_Index_250M, unit_disturbance_catch = Disturbance_Index_Catch,
                 unit_disturbance_sub = Disturbance_Index_Sub, unit_prop_pool = Prop_Pool, unit_prop_run = Prop_Run,
                 unit_prop_riffle = Prop_Riffle, unit_prop_backwater = Prop_BW,
                 unit_backwater_present = ifelse(BW_Pres == 2L, 1L, ifelse(BW_Pres == 1L, 0L, NA_integer_)),
                 unit_total_area_m2 = Total_Area, unit_velocity_occ_m_s = Velocity_OCC, unit_vegetation_occ_pct = Vegetation_OCC,
                 unit_coarse_wood_occ_pct = CW_OCC, unit_prop_agriculture = Prop_AG)]
yrs <- surv[, .(unit_year = year(date[1])), by = ID]
long <- merge(long, merge(ucov, yrs, by = "ID"), by = "ID")
long <- long[, c(list(unit = ID, taxon = Species, y = as.integer(y), occasion = occasion, date = as.character(date), cluster_id = cluster_id),
                 .SD), .SDcols = patterns("^(obs_|unit_)")]
long <- order_eco(long)
stopifnot(uniqueN(long$unit) == 153L, uniqueN(long$cluster_id) == 61L, setequal(unique(long$taxon), TARGET),
          !anyDuplicated(long[, .(unit, taxon, occasion)]), all(long[, uniqueN(taxon), by = .(unit, occasion)]$V1 == 6L))
cat(sprintf("  %d rows: %d sites in %d reaches, %d site-surveys, 6 taxa, %d detections; %d other-darter rows not shipped\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), nrow(surv), sum(long$y), n_other))

taxa <- make_taxa(TARGET, c("Etheostoma microperca", "Chrosomus erythrogaster", "Nocomis asper", "Etheostoma spectabile",
                            "Micropterus dolomieu", "Micropterus dolomieu"),
                  vernacularName = c("Least darter", "Southern redbelly dace", "Redspot chub", "Orangethroat darter",
                                     "Smallmouth bass (sub-adult)", "Smallmouth bass (adult)"))
taxa[, taxon_life_stage := c(NA, NA, NA, NA, "sub-adult", "adult")]

dataset <- list(
  title = "Spring-associated stream fishes, snorkel and seine detections at 153 channel-unit complexes in 61 reaches, Arbuckle Uplift and Ozark Highlands, Oklahoma, 2018-2019",
  creator = "Swedberg, Dusty; Brewer, Shannon; Mollenhauer, Robert (Oklahoma State University)", pubDate = "2023",
  doi = "10.5061/dryad.hmgqnk9m3", sourceURL = "https://doi.org/10.5061/dryad.hmgqnk9m3",
  citation = "Swedberg, D., Brewer, S. & Mollenhauer, R. (2023). Physicochemical habitat data and multi-scale occupancy data for spring-associated fishes in Oklahoma streams [Dataset]. Dryad. https://doi.org/10.5061/dryad.hmgqnk9m3",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection histories of four spring-associated fishes (least darter, southern redbelly dace, redspot chub, smallmouth bass as sub-adults and adults) and the orangethroat darter at 153 riffle-run-pool complexes in 61 stream reaches of the Arbuckle Uplift and Ozark Highlands, Oklahoma, summers 2018-2019: two visits about a week apart, each a snorkel survey and a seine survey (occasions 1-4). Per-survey habitat (depth, velocity, clarity, temperature, cover) and site and reach habitat (mesohabitat areas, residual pool depth, seepage, discharge, land-use disturbance). Multi-scale: cluster_id = reach, unit = site.",
  samplingProtocol = "Channel-unit complexes (riffle-run-pool sequences) within each reach were surveyed twice, about a week apart; each visit comprised a snorkel survey followed by a seine survey, recording presence of target species and other darters. Habitat measured per survey along three transects (depth, velocity), with horizontal clarity per reach and visual cover estimates; site and reach habitat measured once (Swedberg thesis; Dryad README).",
  samplingProtocolCode = "visual_and_seine", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "A site x survey is surveyed iff its y cell is not NA; the NA pattern is identical for every species at a site and matches the gear column (asserted). 21 sites lack the fourth survey and others lack one of the first three.",
  responseType = "detection", unitKind = "site",
  closure = "site closed across the two visits (about one week); occasions are four surveys (snorkel and seine on each visit); reach = cluster_id is the coarser occupancy scale",
  occasionCodes = list(`1` = "visit 1, snorkel", `2` = "visit 1, seine", `3` = "visit 2, snorkel", `4` = "visit 2, seine"),
  designNote = "Experimental list of E9 (multi-scale): cluster_id = reach, unit = channel-unit complex, occasion = survey (gear alternates; obs_gear).",
  geographicCoverage = "Arbuckle Uplift (Arbuckle Mountains) and Ozark Highlands ecoregions, Oklahoma, USA: 47 streams; no coordinates deposited",
  temporalCoverage = sprintf("%s/%s", min(surv$date), max(surv$date)),
  coordinatesCoarsened = NA,
  notes = "Two key repairs: 2k_03 -> 2K_03 (SRBD row) and 1N_12 -> 1N_02 (OTD row; every covariate equal, asserted). Site 4C_04's run area and the proportions and total area derived from it are NA (a spreadsheet fill-down in the deposit); site 1B_02's survey-2 water temperature is NA (23.6 on one species row, 24.1 on eight). obs_duration_recorded is the deposit's Time_y value: documented as hours.minutes but 291 values have fractional parts of .60 or more, so it is not converted. Smallmouth bass are two taxa by life stage (taxon_life_stage in __taxa).",
  notShipped = list(`other darters` = sprintf("%d rows for ten non-target darters (CHD, OBD, LP, GSD, BND, SBD, ARD, FNTL, DD, SHD), listed only at sites of reaches where they were encountered, so their taxon sets differ between sites (E4.2)", n_other),
                    `duplicate rows` = sprintf("%d identical duplicate CHD rows", n_chd_dup)))

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/swedberg_2023_springfish_occ.R")
stage_dict_row(TABLE,
  description = "Snorkel and seine detection histories of six spring-associated fish taxa (least darter, southern redbelly dace, redspot chub, orangethroat darter, smallmouth bass sub-adult and adult) at 153 channel-unit complexes in 61 Oklahoma stream reaches, 2018-2019, four surveys per site, with per-survey and site habitat; multi-scale (cluster_id = reach).",
  url = "https://doi.org/10.5061/dryad.hmgqnk9m3",
  reference = "Swedberg, D., Brewer, S., & Mollenhauer, R. (2023). Physicochemical habitat data and multi-scale occupancy data for spring-associated fishes in Oklahoma streams. Dryad.",
  doi_paper = "", doi_data = "10.5061/dryad.hmgqnk9m3",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Target taxa only (non-target darters have reach-specific species lists); two ID key repairs; survey-duration column shipped as recorded (mixed encoding).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale community occupancy (reach, site, survey; snorkel vs seine)",
  sampling_protocol = "visual_and_seine", design = "Single-season", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "Multi-scale via cluster_id = reach; gear alternates by occasion.")
