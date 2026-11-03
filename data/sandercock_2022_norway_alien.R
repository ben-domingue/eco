#!/usr/bin/env Rscript
# Tables: sandercock_2022_norway_plants_comm (alien vascular plants, two independent botanists per
#         plot) and sandercock_2022_norway_insects_edna (alien insects from Malaise-trap
#         metabarcoding, multi-scale): one deposit, two survey designs x response types, one script.
# Source: Dryad doi:10.5061/dryad.0rxwdbs4f, version 250869 (published 2022-11-21), licence CC0 1.0
#         (Dryad and the deposited README agree; the README adds a non-binding request that re-users
#         contact the authors about collaboration).
#         Sandercock, B.K., Davey, M.L., Endrestol, A., Blaalid, R., Fossoy, F., Hegre, H., Majaneva,
#         M.A.M., Often, A., Astrom, J. & Jacobsen, R.M. Dataset for: Designing a surveillance program
#         for early detection of alien plants and insects in Norway.
# Paper:  Sandercock, B.K. et al. (2023). Designing a surveillance program for early detection of alien
#         plants and insects in Norway. Biological Invasions 25, 917-944. doi:10.1007/s10530-022-02957-6
#         (design from the Dryad abstract and methods fields).
# Data:   EncHistPlants_Dec2020.csv (Latin-1): 14,520 rows, one per alien plant taxon x plot-year:
#         CorrectRisk (Norwegian Alien Species List 2018 risk: NW, NK, LO, PH, HI, SE), CorrectSpecies,
#         year, location (plot id; each of the 60 ids is surveyed in one year only: 15 in 2018, 20 in
#         2019, 25 in 2020), site (name), AndersO and HanneH (botanist A. Often / H. Hegre: NA not
#         surveyed, 0 surveyed not detected, 1 detected). 241 taxa; "Pilosella aurantiaca aurantiaca"
#         is listed twice per plot (once SE, once HI) with identical detections (asserted), so 242 rows
#         per plot-year. One botanist surveyed 25 plot-years alone (NA for the whole plot, asserted).
#         SiteCovar2020.csv (Latin-1): one row per plot: year, history (New / Repeat: a site re-surveyed
#         in a later year under a new location id), site and alternative names, municipality, county,
#         UTM33 easting/northing, latitude/longitude (5 decimals), selection (Manual expert choice /
#         Auto weighted random), location, human population, buildings, hotspot-model prediction used
#         for selection weights (Olsen et al. 2017; external occurrence data, not these detections),
#         mean precipitation and temperature, and areas (m2) of ten land-cover classes within 1 km.
#         The string "na" was replaced by "0" throughout this file in the deposit ("Al0" = Alna,
#         "0nnestad" = Nannestad, header "alter0tive 0mes"); names are shipped as deposited.
#         enchist_knust2018.csv (crushed insects, 2018), enchist_ETOH2019.csv (DNA from the ethanol
#         preservative, 2019), enchist_lysering2019.csv (lysis buffer, 2019), enchist_lysering2020.csv
#         (lysis buffer, 2020), UTF-8 with the risk labels' Norwegian letters already broken in the
#         deposit: risk, taxa (143 alien taxa, the same list in every file), year, site (= plot
#         location), R1D-R4D = Malaise-trap sampling rounds (NA not sampled, 0, 1). 2018 had three
#         weekly rounds (R4D NA everywhere, asserted); 2019 and 2020 four biweekly rounds. The NA pattern
#         is the same for every taxon within a plot-round (asserted).
#         Not data: *.R scripts (authors' analyses), README.
#
# Mapping, sandercock_2022_norway_plants_comm (E9 core, community occupancy; E3: two observers on one
#   visit are two occasions with `observer` giving identity, not a double-observer multinomial: the
#   source records each botanist's own 0/1 for every taxon, which is the detection history the
#   multinomial cells would be derived from): unit = plot (location), taxon = code from the
#   scientific name, period = year 1..3 (2018-2020; each plot is in one period), occasion = 1 (Often)
#   / 2 (Hegre), observer = AO / HH, y = 0/1. Survey evidence: deposited_matrix (NA = not surveyed).
#   Occasion order is not temporal: the two surveys were independent and within the same month.
#   taxon_alienRisk from CorrectRisk (in __taxa). unit_ covariates from SiteCovar2020.csv.
# Mapping, sandercock_2022_norway_insects_edna (E9 experimental, multi-scale / eDNA): cluster_id =
#   plot, unit = Malaise-trap sample (plot x round), taxon = code, period = year 1..3,
#   occasion = DNA source: 1 crushed bulk sample (2018), 2 ethanol preservative (2019), 3 lysis buffer
#   (2019, 2020), with obs_method; y = metabarcoding detection 0/1. In 2019 each sample was
#   sequenced from both sources, so it has two occasions (where lysis was sequenced). unit_round =
#   sampling round. Survey evidence: deposited_matrix.
# Coordinates (both tables): plot coordinates are deposited to 5 decimals. Two taxa in the plant list
#   are IUCN-listed on GBIF (Aesculus hippocastanum VU, Syringa josikaea EN), which makes them flagged
#   under E7 (b), so plot coordinates are coarsened to 0.1 degree with coarsen_coords() in both tables
#   (the insect table shares the plots, and finer coordinates there would undo the coarsening).
# Not shipped: UTM33 easting/northing (finer than the coarsened cell); the duplicate Pilosella row;
#   the authors' pooled 2019 insect histories (ethanol OR lysis, computed in their script), not a
#   deposit file.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/sandercock_2022_norway_alien.R"
CACHE <- "sandercock_2022_norway_plants_comm"
T1 <- "sandercock_2022_norway_plants_comm"; T2 <- "sandercock_2022_norway_insects_edna"
dir <- download_dryad("10.5061/dryad.0rxwdbs4f", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

## ---- plots ------------------------------------------------------------------------------
to_utf8 <- function(x) { for (j in names(x)) if (is.character(x[[j]])) set(x, j = j, value = enc2utf8(x[[j]])); x }
s <- to_utf8(fread(file.path(dir, "SiteCovar2020.csv"), encoding = "Latin-1"))
setnames(s, trimws(names(s)))
stopifnot(nrow(s) == 60L, !anyDuplicated(s$location), all(s$year %in% 2018:2020),
          identical(as.integer(table(s$year)), c(15L, 20L, 25L)), all(s$zone == 33L),
          all(s$history %in% c("New", "Repeat")), all(s$selection %in% c("Manual", "Auto")),
          sum(s$selection == "Manual") == 27L, sum(s$selection == "Auto") == 33L,
          all(s$latitude %between% c(59, 60.3)), all(s$longitude %between% c(9.6, 11.4)))
cc <- coarsen_coords(s$latitude, s$longitude)
landcov <- c("FieldsFullDepth", "FieldsShallowDepth", "Forest", "Freshwater", "Housing", "Mire", "OpenLand",
             "Pasture", "Roads", "Sea")
plots <- s[, .(location, plot_year = year, unit_site_name = site, unit_alt_name = fifelse(`alter0tive 0mes` == "", NA_character_, `alter0tive 0mes`),
               unit_municipality = kommune, unit_county = fylke, unit_history = history, unit_selection = selection,
               unit_population = sum_pop_tot, unit_buildings = sum_bui2det, unit_hotspot_prediction = model_prediction,
               unit_mean_precip_mm = mean_prec, unit_mean_temp_c = mean_temp)]
for (lc in landcov) plots[, (paste0("unit_area_", tolower(lc), "_m2")) := s[[lc]]]
plots[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]

code_of <- function(nm) {
  x <- gsub("[×'\"]", "", nm); w <- strsplit(x, " +")
  toupper(sapply(w, function(v) paste0(substr(v[1], 1, 4), substr(v[2], 1, 4), if (length(v) > 2) substr(v[3], 1, 3) else "")))
}
risk_lab <- c(NW = "newly detected in Norway", NK = "no known effect", LO = "low risk", PH = "potentially high risk",
              HI = "high risk", SE = "severe risk", NR = "not risk assessed")
coarse_note <- "Plot coordinates (5 decimals in the deposit) coarsened to the 0.1-degree cell centre with coarsen_coords(): the plant list includes two taxa that are IUCN-listed on GBIF (Aesculus hippocastanum VU, Syringa josikaea EN), so E7 (b) flags them; both tables share the plots and are coarsened alike. UTM33 coordinates not shipped."
common <- list(
  creator = "Sandercock, Brett K.; Davey, Marie L.; Endrestol, Anders; Blaalid, Rakel; Fossoy, Frode; Hegre, Hanne; Majaneva, Markus A.M.; Often, Anders; Astrom, Jens; Jacobsen, Rannveig M.",
  pubDate = "2022", doi = "10.5061/dryad.0rxwdbs4f", sourceURL = "https://doi.org/10.5061/dryad.0rxwdbs4f",
  citation = "Sandercock, B. K., Davey, M. L., Endrestol, A., Blaalid, R., Fossoy, F., Hegre, H., Majaneva, M. A. M., Often, A., Astrom, J., & Jacobsen, R. M. (2022). Dataset for: Designing a surveillance program for early detection of alien plants and insects in Norway [Dataset]. Dryad. https://doi.org/10.5061/dryad.0rxwdbs4f",
  paperDOI = "10.1007/s10530-022-02957-6",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  geographicCoverage = "60 study plots (6.25 ha) in the Oslofjord region (Oslo, Akershus, Buskerud, Vestfold, Telemark, Ostfold), southern Norway; coordinates coarsened to 0.1 degree",
  coordinatesCoarsened = list(value = TRUE, method = coarse_note))
periods_base <- data.table(period = 1:3, year = 2018:2020, n_plots = c(15L, 20L, 25L))

## ---- table 1: plants ---------------------------------------------------------------------
pl <- to_utf8(fread(file.path(dir, "EncHistPlants_Dec2020.csv"), encoding = "Latin-1"))
stopifnot(nrow(pl) == 14520L, all(pl$CorrectRisk %in% names(risk_lab)), setequal(pl$location, s$location),
          all(pl$AndersO %in% c(0L, 1L, NA)), all(pl$HanneH %in% c(0L, 1L, NA)),
          all(pl[, .N, by = .(year, location)]$N == 242L), uniqueN(pl$CorrectSpecies) == 241L)
stopifnot(all(merge(unique(pl[, .(location, year)]), s[, .(location, y2 = year)], by = "location")[, year == y2]))
pil <- pl[CorrectSpecies == "Pilosella aurantiaca aurantiaca"]
pil[, i := seq_len(.N), by = location]
pw <- dcast(pil, location ~ i, value.var = c("CorrectRisk", "AndersO", "HanneH"))
stopifnot(nrow(pw) == 60L, all(pw$CorrectRisk_1 == "SE" & pw$CorrectRisk_2 == "HI"),
          identical(pw$AndersO_1, pw$AndersO_2), identical(pw$HanneH_1, pw$HanneH_2))
pl <- pl[!(CorrectSpecies == "Pilosella aurantiaca aurantiaca" & CorrectRisk == "HI")]
stopifnot(!anyDuplicated(pl[, .(CorrectSpecies, location)]), all(pl[, uniqueN(CorrectRisk), by = CorrectSpecies]$V1 == 1L))
# NA is a whole-plot property (one botanist did not survey that plot)
na_chk <- pl[, .(a = uniqueN(is.na(AndersO)), h = uniqueN(is.na(HanneH)), na_a = is.na(AndersO[1]), na_h = is.na(HanneH[1])), by = location]
stopifnot(all(na_chk$a == 1L & na_chk$h == 1L), !any(na_chk$na_a & na_chk$na_h), sum(na_chk$na_a) == 5L, sum(na_chk$na_h) == 20L)
sp <- sort(unique(pl$CorrectSpecies)); code <- code_of(sp)
stopifnot(!anyDuplicated(code), all(nchar(code) >= 5))
lp <- melt(pl, id.vars = c("CorrectSpecies", "year", "location"), measure.vars = c("AndersO", "HanneH"),
           variable.name = "obs", value.name = "y")[!is.na(y)]
lp[, `:=`(occasion = fifelse(obs == "AndersO", 1L, 2L), observer = fifelse(obs == "AndersO", "AO", "HH"),
          taxon = code[match(CorrectSpecies, sp)], period = year - 2017L)]
lp <- merge(lp, plots, by = "location")
long1 <- lp[, c(list(unit = location, taxon = taxon, y = as.integer(y), period = period, occasion = occasion, observer = observer),
               .SD), .SDcols = patterns("^unit_")]
long1 <- order_eco(long1)
stopifnot(nrow(long1) == 95L * 241L, uniqueN(long1$unit) == 60L,
          all(long1[, .N, by = .(unit, occasion)]$N == 241L), uniqueN(long1[, .(unit, occasion)]) == 95L)
cat(sprintf("  plants: %d plot-surveys (botanist visits), %d detections of %d taxa\n",
            uniqueN(long1[, .(unit, occasion)]), sum(long1$y), uniqueN(long1[y == 1, taxon])))

rank_of <- function(nm) fifelse(grepl("'", nm), "cultivar", fifelse(grepl("×", nm), "hybrid",
                         fifelse(lengths(strsplit(nm, " +")) > 2, "subspecies", "species")))
lookup <- sub("^Sorbus Koehneana$", "Sorbus koehneana", sp)      # source capitalises the epithet
risk1 <- unique(pl[, .(CorrectSpecies, CorrectRisk)])[match(sp, CorrectSpecies), CorrectRisk]
taxa1 <- make_taxa(code, sp, taxonRank = rank_of(sp), lookupName = lookup,
                   taxon_alienRisk = risk1, taxon_alienRiskLabel = unname(risk_lab[risk1]))
taxa1[gbifMatchType == "HIGHERRANK", taxonID := NA_character_]     # do not ship a genus key for a species-rank name
taxa1[scientificName == "Pilosella aurantiaca aurantiaca", `:=`(taxon_alienRisk = "SE", taxon_alienRiskLabel = "severe risk (listed twice in the source, as SE and HI)")]
taxa1[scientificName == "Aesculus hippocastanum", taxon_iucnCategory := "VU"]
taxa1[scientificName == "Syringa josikaea", taxon_iucnCategory := "EN"]
periods1 <- copy(periods_base)[, protocol := c("four transects offset at 45 degrees, 10 m strip each, then about 30 min over the rest of the plot; maximum 2 h per plot",
                                               "random walk over the whole plot; maximum 5 h per plot", "random walk over the whole plot; maximum 5 h per plot")]
periods1[, n_plot_surveys := long1[, uniqueN(paste(unit, occasion)), by = period][order(period), V1]]
ds1 <- write_table(long1, T1, c(common, list(
  title = "Alien vascular plant detections by two independent botanists in 60 plots around the Oslofjord, Norway, 2018-2020",
  abstract = "Surveillance for alien vascular plants in 60 study plots (6.25 ha; 27 chosen by experts, 33 by weighted random selection from a hotspot model) in southern Norway, 15 to 25 plots per year 2018-2020, each plot in one year. Two experienced botanists (A. Often, H. Hegre) searched each plot independently within one month (mid-August to mid-September); 35 plots were searched by both and 25 by one, 95 surveys in all. One row per plot x botanist x taxon for 241 alien taxa on the Norwegian Alien Species List (2018), with the list's risk category in __taxa.",
  samplingProtocol = "Independent searches of each 6.25-ha plot by two botanists in mid-August to mid-September; in 2018 along four transects (10 m strips) plus about 30 minutes elsewhere (maximum 2 h), in 2019-2020 a random walk over the whole plot (maximum 5 h). The search list is the 241 alien taxa of the Norwegian Alien Species List (2018).",
  samplingProtocolCode = "visual_survey", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "occasion within plot (the two botanists searched the plot independently within one month); each plot is surveyed in one year only",
  temporalCoverage = "2018-08/2020-09",
  occasionCodes = list(`1` = "botanist Anders Often (observer AO)", `2` = "botanist Hanne Hegre (observer HH)"),
  designNote = "Standard E3: two observers on one visit are two occasions with `observer`; the source records each botanist's own 0/1, so a double-observer multinomial view (cells 10/01/11) is a derived pivot of this table. Occasion order is not temporal. Repeat plots (unit_history = Repeat, 5 plots) re-survey a site from an earlier year under a new plot id; unit_site_name links them (coordinates differ by 0 to about 1.6 km).",
  notes = "Taxon codes are built from the scientific name (4 + 4 letters, plus 3 of an infraspecific epithet). Hybrids (x), one cultivar (Salix 'Brekkavier') and subspecies are kept at the source's rank; GBIF matches above the source's rank are not shipped as taxonID. Pilosella aurantiaca aurantiaca appears twice in the source with identical detections and two risk categories (SE, HI): one row kept. Site names are as deposited, with the deposit's 'na' -> '0' substitution (Al0 = Alna). unit_hotspot_prediction is the external hotspot model's predicted suitability used for the selection weights (Olsen et al. 2017), not an estimate from these detections; land-cover areas are m2 within 1 km of the plot centre.",
  components = list(T2),
  notShipped = list(`UTM33 coordinates` = "finer than the coarsened 0.1-degree cell",
                    `duplicate Pilosella row` = "Pilosella aurantiaca aurantiaca listed a second time (risk HI) with detections identical to the SE row"))),
  taxa = taxa1, periods = periods1, script = SCRIPT)
stage_dict_row(T1,
  description = "Alien vascular plant surveillance in 60 plots around the Oslofjord, southern Norway, 2018-2020: detection/non-detection of 241 listed alien taxa by two independent botanists per plot (95 plot surveys), with plot selection method, housing, climate and land-cover covariates.",
  url = "https://doi.org/10.5061/dryad.0rxwdbs4f",
  reference = "Sandercock, B. K., et al. (2023). Designing a surveillance program for early detection of alien plants and insects in Norway. Biological Invasions, 25, 917-944.",
  doi_paper = "10.1007/s10530-022-02957-6", doi_data = "10.5061/dryad.0rxwdbs4f",
  original_license = "CC0 1.0 (Dryad and README; README asks re-users to contact the authors)", derived_license = "CC0 1.0",
  notes = "Botanists as occasions (E3), observer column. Coordinates coarsened (two IUCN-listed taxa on the list). Companion of sandercock_2022_norway_insects_edna.",
  source_via = "Dryad")
stage_tag_row(T1, ds1, taxon_group = "Plants", model_family = "Community occupancy (two independent observers)",
  sampling_protocol = "visual_survey", design = "Single-season (2 observers per plot; plots in 3 annual cohorts)",
  realm = "Terrestrial", country = "NOR", coordinates = "Coarsened (0.1 deg)",
  notes = "First plant community table; alien species surveillance; risk category in __taxa.", status = "tagged")

## ---- table 2: insects --------------------------------------------------------------------
files <- c(knust2018 = "enchist_knust2018.csv", ETOH2019 = "enchist_ETOH2019.csv",
           lysering2019 = "enchist_lysering2019.csv", lysering2020 = "enchist_lysering2020.csv")
src <- data.table(f = names(files), year = c(2018L, 2019L, 2019L, 2020L), occasion = c(1L, 2L, 3L, 3L),
                  method = c("crushed bulk sample", "ethanol preservative", "lysis buffer", "lysis buffer"))
ins <- rbindlist(lapply(seq_along(files), function(i) {
  x <- fread(file.path(dir, files[i]), encoding = "UTF-8"); x[, f := names(files)[i]]; x }))
stopifnot(identical(names(ins), c("risk", "taxa", "year", "site", "R1D", "R2D", "R3D", "R4D", "f")),
          all(ins[, uniqueN(taxa), by = f]$V1 == 143L), all(ins[, .N, by = .(f, site)]$N == 143L),
          all(merge(ins[, .(fy = year[1]), by = f], src, by = "f")[, fy == year]))
tl <- lapply(names(files), function(k) sort(unique(ins[f == k, taxa]))); stopifnot(all(sapply(tl, identical, tl[[1]])))
for (k in names(files)) stopifnot(setequal(ins[f == k, site], s[year == src[f == k, year], location]))
ins[, risk2 := substr(risk, 1, 2)]
stopifnot(all(ins$risk2 %in% names(risk_lab)), all(ins[, uniqueN(risk2), by = taxa]$V1 == 1L))
li <- melt(ins, id.vars = c("f", "taxa", "year", "site", "risk2"), measure.vars = paste0("R", 1:4, "D"),
           variable.name = "round", value.name = "y")
li[, round := as.integer(substr(round, 2, 2))]
stopifnot(all(li$y %in% c(0L, 1L, NA)), all(li[, uniqueN(is.na(y)), by = .(f, site, round)]$V1 == 1L),
          all(is.na(li[f == "knust2018" & round == 4L, y])), !anyNA(li[f == "knust2018" & round < 4L, y]),
          !anyNA(li[f %in% c("ETOH2019", "lysering2020"), y]))
li <- li[!is.na(y)]
li <- merge(li, src[, .(f, occasion, method)], by = "f")
li[, unit := sprintf("%d_R%d", site, round)]
stopifnot(all(li[f == "lysering2019", unit] %in% li[f == "ETOH2019", unit]))     # lysis was a second extraction of the same samples
sp2 <- sort(unique(li$taxa)); code2 <- code_of(sp2); stopifnot(!anyDuplicated(code2))
li[, `:=`(taxon = code2[match(taxa, sp2)], period = year - 2017L)]
li <- merge(li, plots, by.x = "site", by.y = "location")
long2 <- li[, c(list(unit = unit, taxon = taxon, y = as.integer(y), period = period, occasion = occasion,
                     cluster_id = as.character(site), unit_round = round, obs_method = method), .SD), .SDcols = patterns("^unit_")]
long2 <- order_eco(long2)
n_samp <- long2[, uniqueN(unit)]; n_ext <- uniqueN(long2[, .(unit, occasion)])
stopifnot(n_samp == 15L * 3L + 20L * 4L + 25L * 4L, n_ext == 45L + 80L + 70L + 100L, nrow(long2) == n_ext * 143L,
          all(long2[, .N, by = .(unit, occasion)]$N == 143L), uniqueN(long2$cluster_id) == 60L)
cat(sprintf("  insects: %d samples, %d sequenced extractions, %d detections of %d taxa\n",
            n_samp, n_ext, sum(long2$y), uniqueN(long2[y == 1, taxon])))
risk2 <- unique(ins[, .(taxa, risk2)])[match(sp2, taxa), risk2]
taxa2 <- make_taxa(code2, sp2, taxon_alienRisk = risk2, taxon_alienRiskLabel = unname(risk_lab[risk2]))
taxa2[gbifMatchType == "HIGHERRANK", taxonID := NA_character_]
periods2 <- copy(periods_base)[, `:=`(
  rounds = c("3 weekly rounds, weeks 36-39 (traps set week 35)", "4 biweekly rounds, weeks 29-35 (traps set week 25)", "4 biweekly rounds, weeks 29-35 (traps set week 25)"),
  dna_source = c("crushed bulk sample (occasion 1)", "ethanol preservative (occasion 2) and lysis buffer (occasion 3)", "lysis buffer (occasion 3)"),
  preservative = c("water, ethanol and propylene glycol 1:1:3", "96% ethanol", "96% ethanol"))]
ds2 <- write_table(long2, T2, c(common, list(
  title = "Alien insect detections by DNA metabarcoding of Malaise-trap samples in 60 plots around the Oslofjord, Norway, 2018-2020",
  abstract = "One Malaise trap per study plot (the plots of sandercock_2022_norway_plants_comm), emptied in 3 weekly (2018) or 4 biweekly (2019-2020) rounds; each sample metabarcoded from crushed insects (2018), from the ethanol preservative and from a lysis buffer (2019, both, the lysis buffer missing for 10 samples) or from the lysis buffer (2020). One row per sample x DNA source x taxon for 143 alien insect and other invertebrate taxa from the Norwegian Alien Species List (2018) or new to Norway.",
  samplingProtocol = "Single Malaise trap per plot, mid-June to late August (2019-2020) or September (2018); DNA metabarcoding of each round's sample from the crushed bulk sample (2018), the ethanol preservative and a lysis buffer (2019), or the lysis buffer (2020); detections reported for the alien-species list.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "plot occupancy within the season (cluster_id); unit = trap sample (round), occasion = DNA source sequenced from that sample",
  temporalCoverage = "2018-06/2020-08",
  occasionCodes = list(`1` = "crushed bulk sample (2018)", `2` = "ethanol preservative (2019)", `3` = "lysis buffer (2019, 2020)"),
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = plot (occupancy), unit = Malaise-trap sample per round (availability), occasion = DNA source (detection). Occasion indexes a method, not a time. The authors pooled the two 2019 sources by OR into one history per plot-round; this table keeps them apart.",
  notes = "Taxon codes built from the scientific name (4 + 4 letters). Risk labels in the deposit have broken Norwegian letters; only the two-letter code is shipped. Plot covariates as in the plant table. The Dryad abstract reports 255 rounds of sampling; the deposited files hold 225 trap samples (45 + 80 + 100) and 295 sequenced extractions.",
  components = list(T1),
  notShipped = list(`UTM33 coordinates` = "finer than the coarsened 0.1-degree cell",
                    `pooled 2019 histories` = "the authors' ethanol-OR-lysis combination (computed in InsectOccupancy2020.R, not a deposit file)"))),
  taxa = taxa2, periods = periods2, script = SCRIPT)
stage_dict_row(T2,
  description = "Alien insect surveillance by Malaise-trap DNA metabarcoding in 60 plots around the Oslofjord, southern Norway, 2018-2020: detection of 143 listed alien taxa per trap sample and DNA source (crushed insects, ethanol preservative, lysis buffer); multi-scale eDNA layout with the plot as cluster.",
  url = "https://doi.org/10.5061/dryad.0rxwdbs4f",
  reference = "Sandercock, B. K., et al. (2023). Designing a surveillance program for early detection of alien plants and insects in Norway. Biological Invasions, 25, 917-944.",
  doi_paper = "10.1007/s10530-022-02957-6", doi_data = "10.5061/dryad.0rxwdbs4f",
  original_license = "CC0 1.0 (Dryad and README; README asks re-users to contact the authors)", derived_license = "CC0 1.0",
  notes = "Experimental multi-scale form: plot = cluster_id, sample = unit, DNA source = occasion. Coordinates coarsened with the plant table. Companion of sandercock_2022_norway_plants_comm.",
  source_via = "Dryad")
stage_tag_row(T2, ds2, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (eDNA metabarcoding, community)",
  sampling_protocol = "eDNA", design = "Single-season (3-4 trap rounds x 1-2 DNA sources; plots in 3 annual cohorts)",
  realm = "Terrestrial", country = "NOR", coordinates = "Coarsened (0.1 deg)",
  notes = "Alien insects from Malaise-trap metabarcoding; 2019 samples sequenced from two DNA sources.", status = "tagged")
