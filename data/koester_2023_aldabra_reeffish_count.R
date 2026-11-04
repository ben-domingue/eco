#!/usr/bin/env Rscript
# Table:  koester_2023_aldabra_reeffish_count (indicator surveys, 2014, 2016-2019, 2021) and
#         koester_2023_aldabra_reeffishext_count (extended surveys, 2015 and 2020); one script,
#         two tables. They stay two tables under ruling #31 because they are two protocols, not
#         one protocol with two taxon lists: the indicator survey counts its list in six size
#         classes including fish under 8 cm (class 1, midpoint 3 cm), while the extended survey
#         counts every fish of 8 cm or more, sized to the cm, by one trained surveyor; a
#         listed taxon's count therefore measures a different size range in the two, so y is
#         not the same quantity (the ruling covers taxon lists only).
# Source: figshare doi:10.6084/m9.figshare.22792580.v3 (version 3, 2026-02-19 metadata;
#         files "corrected_Oct2024"), Koester, A'Bear, Bielsa, Burt, Chong-Seng, Haupt et al.
#         Licence as shown on the record: CC BY 4.0. The record adds: "All data is owned by the
#         Seychelles Islands Foundation (SIF), the management authority of Aldabra Atoll. SIF must
#         be cited alongside all authors in any works using all or parts of this data" (carried
#         in the citation and reference; consistent with CC BY attribution).
# Paper:  Koester, A., et al. (2023). Frontiers in Marine Science 10, 1230717,
#         doi:10.3389/fmars.2023.1230717 (fish abundance and biomass on Aldabra's reefs before and
#         after the 2016 bleaching event).
# Data:   Data_indicator_surveys_corrected_Oct2024.xlsx, sheet Data_indicator_surveys: 7,664
#           rows, one per taxon x size class x transect (a few taxon-size rows repeat on one
#           transect and are summed): Family, Species ("Genus.species", "Genus.sp" or
#           "other.<group>" = members of that family not on the list), English, Species_indicator_
#           list (all "Yes"), Feeding_guild_code, Survey_Date, Year (the survey season label:
#           "2014" = Nov 2014 - Jan 2015), Transect ("ARM01_5m_2" = site, depth, replicate),
#           Depth, Site, Actual_size (text "NA" except 59 rows of the largest class, 45-100 cm), Amount (fish counted), Size_Class (1-6; the
#           Explanations sheet says five classes, the data have six, with midpoints 3, 7, 14.5,
#           24.5, 34.5, 55 cm), Median_size_class, Biomass_g (derived).
#         Data_extended_surveys_corrected_Oct2024.xlsx, sheet Data_extended_surveys_corrected:
#           3,402 rows, same columns; Actual_size in cm (8-150; fish under 8 cm are not
#           recorded), Size_Class 2-6, Species_indicator_list Yes / No.
#         Both have an Explanations sheet (column definitions and references).
#         Design (record text and paper): 12 sites; nine seaward sites with permanently marked
#         transects at 5 m and 15 m, three lagoon sites at 2 m; one to three 50 x 4 m belt
#         transects per site x depth, the first always the permanent transect, replicates 10 m
#         apart on the same bearing and depth contour, all surveyed in the same dive.
#         Indicator surveys (2014, 2016-2019, 2021) count a predefined list of 84 taxa (the
#         deposit has 82 of them); extended surveys (2015, 2020) count all diurnally active
#         reef-associated fishes (198 taxa in the deposit).
#
# Mapping (E1-E5, community repeated counts):
#   unit = site x depth ("ARM01_5m"; 21 in all), cluster_id = site, period = survey season
#   (indicator 1-6 = 2014, 2016, 2017, 2018, 2019, 2021; extended 1-2 = 2015, 2020; label and
#   date span in __periods), occasion = replicate transect (1-3; spatial replicates in one dive),
#   taxon = a 6-7 letter code built from the source name (species: GENSPE, with the last three epithet letters appended for four colliding pairs; genus: GENSPP;
#   "other.<group>": OTH + first four letters of the group, e.g. OTHGROU), y = fish counted on the transect = sum of Amount over size
#   classes; 0 for every taxon of that method's list on every surveyed transect (both methods
#   count every fish of their list, so the community rule applies). date = the transect's
#   survey date (seven transect-years carry two dates in the deposit, ARM07 15 m in 2018 and
#   ARM12 in 2021: the earliest date is used, asserted). unit_ covariates: site, depth (m),
#   reef zone (seaward / lagoon). Effort is constant (one 200 m2 transect).
#   closure = closed (replicate transects of one dive; closureNote keeps the detail),
#   occasionKind = spatial, taxonInclusion = recorded (each table: the taxa recorded by its
#   own surveys). "other.<group>" family remainders and "Genus.sp" records are their own taxa
#   at family / genus rank, with taxonRemarks in __taxa saying what they pool (E6).
#   surveyEvidence = inferred: the deposit is a record table without zero rows, so a transect
#   is taken to be surveyed in a season iff it has at least one record. A 200 m2 reef transect
#   with no fish of the indicator list would be missing; none is expected (the minimum is 2
#   records on a transect), and the replicate pattern (only the permanent transect in 2014,
#   two replicates at 15 m in 2016) is the design the paper describes (its Table S1, the
#   per-year transect counts, was not retrievable).
#   Coordinates: none in the deposit (site map only in the paper); no coordinates shipped.
#   IUCN categories from GBIF are recorded in __taxa for information (at build time Cheilinus
#   undulatus EN; Bolbometopon muricatum, Epinephelus polyphekadion, E. fuscoguttatus VU); with
#   no coordinates there is nothing to coarsen.
#   Not shipped: size classes, actual sizes and biomass (derived from lengths by published
#   length-weight constants). Feeding guild is shipped in __taxa as every code the deposit
#   gives the taxon ("CI/IN"): in the indicator file it varies across rows of one taxon, and
#   "CI" is not among the codes the Explanations sheet defines (PI, OM, IN, C, PL, HV).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE  <- "koester_2023_aldabra_reeffish_count"
TABLE2 <- "koester_2023_aldabra_reeffishext_count"
f_ind <- download_cached("https://ndownloader.figshare.com/files/49606521", TABLE, "Data_indicator_surveys_corrected_Oct2024.xlsx")
f_ext <- download_cached("https://ndownloader.figshare.com/files/49606518", TABLE, "Data_extended_surveys_corrected_Oct2024.xlsx")
stopifnot(identical(excel_sheets(f_ind), c("Data_indicator_surveys", "Explanations")),
          identical(excel_sheets(f_ext), c("Data_extended_surveys_corrected", "Explanations")))
ind <- as.data.table(read_excel(f_ind, 1)); ext <- as.data.table(read_excel(f_ext, 1))
cols <- c("Family", "Species", "English", "Species_indicator_list", "Feeding_guild_code", "Survey_Date", "Year",
          "Transect", "Depth", "Site", "Actual_size", "Amount", "Size_Class", "Median_size_class", "Biomass_g")
stopifnot(identical(names(ind), cols), identical(names(ext), cols), nrow(ind) == 7664, nrow(ext) == 3402,
          all(ind$Species_indicator_list == "Yes"), setequal(ext$Species_indicator_list, c("Yes", "No")),
          ind[Actual_size != "NA", all(Size_Class == 6)], ind[Actual_size == "NA", .N] == 7605,   # sizes only for some > 39 cm fish (text "NA" otherwise)
          !anyNA(ext$Actual_size), min(ext$Actual_size) == 8,
          setequal(ind$Size_Class, 1:6), setequal(ext$Size_Class, 2:6),
          setequal(ind$Year, c(2014, 2016:2019, 2021)), setequal(ext$Year, c(2015, 2020)),
          !anyNA(ind$Amount), !anyNA(ext$Amount), all(ind$Amount >= 1), all(ext$Amount >= 1))

prep <- function(d) {
  d <- copy(d)
  stopifnot(all(grepl("^ARM[0-9]{2}_(2|5|15)m_[1-3]$", d$Transect)),
            all(d$Site == sub("_.*$", "", d$Transect)), all(d$Depth == sub("^ARM[0-9]{2}_([0-9]+m)_.*$", "\\1", d$Transect)))
  d[, `:=`(unit = sub("_[1-3]$", "", Transect), occasion = as.integer(sub(".*_", "", Transect)),
           depth_m = as.integer(sub("m$", "", Depth)), date = as.IDate(Survey_Date))]
  # site zones: seaward ARM01-08 and ARM12 at 5 and 15 m, lagoon ARM09-11 at 2 m
  stopifnot(all(d[Site %in% sprintf("ARM%02d", 9:11), depth_m == 2]), all(d[!Site %in% sprintf("ARM%02d", 9:11), depth_m %in% c(5, 15)]))
  d[]
}
ind <- prep(ind); ext <- prep(ext)

# transect-years with two dates (ind only): ARM07 15 m reps 2-3 in 2018, ARM12 (both depths) in 2021
twodates <- ind[, uniqueN(date), by = .(Year, Transect)][V1 > 1]
stopifnot(nrow(twodates) == 7, setequal(twodates$Transect[twodates$Year == 2018], c("ARM07_15m_2", "ARM07_15m_3")),
          all(grepl("^ARM12_", twodates$Transect[twodates$Year == 2021])), ext[, uniqueN(date), by = .(Year, Transect)][, all(V1 == 1)])

# taxon codes from the source names
code_of <- function(fam, sp) {
  g <- sub("\\..*$", "", sp); s <- sub("^[^.]*\\.", "", sp)
  fifelse(g == "other", paste0("OTH", toupper(substr(s, 1, 4))),
  fifelse(s == "sp", paste0(toupper(substr(g, 1, 3)), "SPP"), toupper(paste0(substr(g, 1, 3), substr(s, 1, 3)))))
}
# Codes are fixed over the union of both files, so a taxon has one code in both tables. Where
# two species share a GENSPE code (Chaetodon trifasciatus / trifascialis, Ctenochaetus strigosus /
# striatus, Acanthurus nigrofuscus / nigricauda, A. leucosternon / leucocheilus) the last three
# letters of the epithet are appended (CHATRITUS / CHATRILIS).
all_sp <- unique(rbind(ind[, .(Family, Species)], ext[, .(Family, Species)]))
stopifnot(!anyDuplicated(all_sp$Species))
all_sp[, taxon := code_of(Family, Species)]
dup <- all_sp[duplicated(taxon) | duplicated(taxon, fromLast = TRUE)]
stopifnot(nrow(dup) == 8, !any(grepl("^other\\.|\\.sp$", dup$Species)))
ep <- sub("^[^.]*\\.", "", dup$Species)
all_sp[match(dup$Species, Species), taxon := paste0(taxon, toupper(substring(ep, nchar(ep) - 2)))]
stopifnot(!anyDuplicated(all_sp$taxon))
build_taxa <- function(d) {
  # Feeding_guild_code is not constant within a taxon in the indicator file (e.g. Chaetodon
  # kleinii both CI and IN; CI is not among the documented codes): every code seen is kept
  sp <- d[, .(Feeding_guild_code = paste(sort(unique(Feeding_guild_code)), collapse = "/")), by = .(Family, Species, English)]
  stopifnot(!anyDuplicated(sp$Species))
  sp[, taxon := all_sp$taxon[match(Species, all_sp$Species)]]
  stopifnot(!anyDuplicated(sp$taxon))
  sp[, g := sub("\\..*$", "", Species)][, s := sub("^[^.]*\\.", "", Species)]
  sp[, rank := fifelse(g == "other", "family", fifelse(s == "sp", "genus", "species"))]
  sp[, sci := fifelse(rank == "family", sprintf("%s (other, not on the list)", Family),
              fifelse(rank == "genus", paste(g, "sp."), paste(g, s)))]
  sp[, lookup := fifelse(rank == "family", Family, fifelse(rank == "genus", g, paste(g, s)))]
  sp[Species == "Balistodes.viridescens", lookup := "Balistoides viridescens"]     # source misspellings
  sp[Species == "Chaetodon.benetti", lookup := "Chaetodon bennetti"]
  # homonyms the strict match sends to the kingdom: name the fish authority
  sp[lookup == "Acanthurus", lookup := "Acanthurus Forsskål, 1775"]
  sp[lookup == "Naso", lookup := "Naso Lacepède, 1801"]
  sp[lookup == "Aprion virescens", lookup := "Aprion virescens Valenciennes, 1830"]
  sp[, remarks := fifelse(rank == "family", sprintf("Members of %s not on the indicator list, pooled by the source (\"%s\"); taxonID is the family", Family, Species),
                  fifelse(rank == "genus", sprintf("Recorded only to genus by the source (\"%s\")", Species), NA_character_))]
  sp[, vern := fifelse(English %in% c("N/A", "") | is.na(English), NA_character_, gsub("\\.", " ", English))]
  sp[]
}
mk_taxa <- function(sp) {
  tx <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$vern, taxonRank = sp$rank, lookupName = sp$lookup,
                  taxon_family = sp$Family, taxon_sourceName = sp$Species, taxon_feeding_guild = sp$Feeding_guild_code, taxonRemarks = sp$remarks)
  stopifnot(!anyNA(tx$taxonID), all(tx$gbifMatchType == "EXACT"), !any(grepl("/species/[0-9]$", tx$taxonID)))
  tx[taxonRank == "species", taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  # GBIF's IUCN record for Aethaloperca rogaa is filed under the accepted Cephalopholis rogaa: the
  # same species after a genus transfer (same epithet), assessed LC; every other species resolves
  stopifnot(identical(tx[taxonRank == "species" & is.na(taxon_iucnCategory), taxon], "AETROG"))
  tx[taxon == "AETROG", taxon_iucnCategory := "LC"]
  tx[]
}

build_long <- function(d, sp, years) {
  d[, taxon := sp$taxon[match(Species, sp$Species)]]
  sv <- d[, .(date = min(date)), by = .(Year, unit, occasion, Site, depth_m)]
  sv[, period := match(Year, years)]
  long <- sv[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(sv))]
  cnt <- d[, .(y = sum(Amount)), by = .(Year, unit, occasion, taxon)]
  long <- merge(long, cnt, by = c("Year", "unit", "occasion", "taxon"), all.x = TRUE)
  long[is.na(y), y := 0]
  stopifnot(nrow(long) == nrow(sv) * nrow(sp), sum(long$y) == sum(d$Amount))
  out <- long[, .(unit, taxon, y = as.integer(y), period, occasion, date = format(date), cluster_id = Site,
                  unit_site = Site, unit_depth_m = depth_m,
                  unit_reef_zone = fifelse(depth_m == 2, "lagoon", "seaward"))]
  list(long = order_eco(out), surveys = sv)
}
periods_of <- function(sv, years) {
  sv[, .(period_season_label = as.integer(Year[1]), period_first_date = format(min(date)), period_last_date = format(max(date)),
         period_n_transects = .N), by = period][order(period)]
}

## indicator table ----------------------------------------------------------
sp_i <- build_taxa(ind)
print(sp_i[, .N, by = rank]); stopifnot(nrow(sp_i) == 82)
yrs_i <- c(2014, 2016, 2017, 2018, 2019, 2021)
b_i <- build_long(ind, sp_i, yrs_i)
stopifnot(identical(b_i$surveys[, .N, by = Year][order(Year), N], c(20L, 54L, 60L, 62L, 60L, 62L)),
          nrow(b_i$surveys) == 318, uniqueN(b_i$long$unit) == 21, ind[, .N, by = .(Year, Transect)][, min(N)] >= 2)
taxa_i <- mk_taxa(sp_i)
per_i <- periods_of(b_i$surveys, yrs_i)

common <- list(
  creator = "Koester, Anna; A'Bear, Luke; Bielsa, Maria; Burt, April Jasmine; Chong-Seng, Karen; Haupt, Philip; et al.; Seychelles Islands Foundation",
  pubDate = "2026-02-19", sourceURL = "https://doi.org/10.6084/m9.figshare.22792580.v3",
  citation = "Koester, A., A'Bear, L., Bielsa, M., Burt, A. J., Chong-Seng, K., Haupt, P., et al. (2023). Reef fish abundance, size and biomass from Aldabra Atoll (Seychelles) between 2014 and 2021 collected by the Seychelles Islands Foundation. figshare, version 3. https://doi.org/10.6084/m9.figshare.22792580.v3 (CC BY 4.0; data owned by the Seychelles Islands Foundation, which must be cited). Paper: Koester et al. (2023), Frontiers in Marine Science 10, 1230717, https://doi.org/10.3389/fmars.2023.1230717.",
  paperDOI = "10.3389/fmars.2023.1230717", dataDOI = "10.6084/m9.figshare.22792580.v3",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  samplingProtocolCode = "visual_census", occasionLength = "one 50 x 4 m belt transect (200 m2)",
  surveyEvidence = "inferred", responseType = "count", unitKind = "site",
  closure = "closed", occasionKind = "spatial", taxonInclusion = "recorded",
  closureNote = "occasion within period: the one to three replicate transects of a site x depth are surveyed in the same dive, 10 m apart (spatial replicates); open between annual seasons",
  geographicCoverage = list(description = "Aldabra Atoll, Seychelles, western Indian Ocean: nine seaward-reef sites (5 m and 15 m) and three lagoon sites (2 m)",
                            boundingBox = list(west = 46.15, east = 46.55, south = -9.55, north = -9.35)),
  coordinatesCoarsened = NA)

dataset_i <- c(common, list(
  title = "Indicator-taxa belt-transect fish counts at Aldabra Atoll (Seychelles), 21 site-depths, six seasons 2014-2021",
  abstract = "Seychelles Islands Foundation Aldabra Reef Monitoring: underwater visual census of a predefined list of indicator fish taxa (species, genera and 'other' family remainders) on one to three 50 x 4 m belt transects per site and depth, at nine seaward-reef sites (5 and 15 m) and three lagoon sites (2 m), in the 2014, 2016, 2017, 2018, 2019 and 2021 survey seasons (before and after the 2016 bleaching).",
  samplingProtocol = "Belt-transect underwater visual census (50 x 4 m), large mobile fish on the outward pass and small site-attached fish on the return; every fish of the 84-taxon indicator list counted in five or six size classes. One to three replicate transects per site x depth in one dive; the first is the permanently marked transect.",
  temporalCoverage = sprintf("%s/%s", min(ind$date), max(ind$date)),
  surveyEvidenceNote = "The deposit lists fish records only. A transect (site x depth x replicate) is taken as surveyed in a season iff it has at least one record (318 transect-seasons; minimum 2 records). Both methods count every fish of their list, so a listed taxon without a record on a surveyed transect is a zero. A transect with no listed fish at all would be missing; the paper's per-year transect counts (Table S1) could not be retrieved to check.",
  notShipped = list(`Size_Class, Median_size_class` = "size-class breakdown of each count (y sums the classes); six classes in the data though the Explanations sheet lists five",
                    Biomass_g = "derived from size by published length-weight constants (FishBase)",
                    `two taxa of the 84-taxon list` = "the deposit has 82 indicator taxa; the two never recorded are not named, so they cannot carry zeros",
                    `Survey_Date on 7 transect-seasons` = "ARM07 15 m replicates 2-3 (2018) and ARM12 transects (2021) carry two dates; the earliest is shipped")))
ds <- write_table(b_i$long, TABLE, dataset_i, taxa = taxa_i, periods = per_i, script = "data/koester_2023_aldabra_reeffish_count.R")
stage_dict_row(TABLE,
  description = "Belt-transect visual-census counts of 82 indicator reef fish taxa at Aldabra Atoll, Seychelles: 21 site-depths (seaward 5 and 15 m, lagoon 2 m), one to three replicate transects in each of six survey seasons 2014-2021 spanning the 2016 bleaching event.",
  url = "https://doi.org/10.6084/m9.figshare.22792580.v3",
  reference = "Koester, A., et al. (2023). Reef fish abundance, size and biomass from Aldabra Atoll (Seychelles) between 2014 and 2021 collected by the Seychelles Islands Foundation. figshare. Data owned by the Seychelles Islands Foundation (SIF), which must be cited.",
  doi_paper = "10.3389/fmars.2023.1230717", doi_data = "10.6084/m9.figshare.22792580.v3", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Survey set inferred (a transect with at least one record was surveyed). Size classes and biomass not shipped. Sibling of koester_2023_aldabra_reeffishext_count (extended surveys, all fishes, 2015 and 2020). SIF asks to be cited.",
  source_via = "figshare")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (community counts, multi-season)",
  sampling_protocol = "visual_census", design = "Multi-season (6 seasons x 1-3 replicate transects)",
  realm = "Marine", country = "SYC", coordinates = "None in source",
  notes = "Indicator-list UVC (species, genera and family remainders); spatial replicate transects; survey set inferred.", status = "tagged")

## extended table -----------------------------------------------------------
sp_x <- build_taxa(ext)
stopifnot(nrow(sp_x) == 198)
yrs_x <- c(2015, 2020)
b_x <- build_long(ext, sp_x, yrs_x)
stopifnot(identical(b_x$surveys[, .N, by = Year][order(Year), N], c(35L, 49L)), ext[, .N, by = .(Year, Transect)][, min(N)] >= 2)
taxa_x <- mk_taxa(sp_x)
taxa_x[, taxon_on_indicator_list := unique(ext[, .(Species, Species_indicator_list)])[match(taxa_x$taxon_sourceName, Species), Species_indicator_list]]
per_x <- periods_of(b_x$surveys, yrs_x)
dataset_x <- c(common, list(
  title = "All-fish belt-transect counts at Aldabra Atoll (Seychelles), extended surveys of 2015 and 2020",
  abstract = "Seychelles Islands Foundation Aldabra Reef Monitoring, extended surveys: every diurnally active reef-associated fish of 8 cm or more identified (198 taxa), counted and sized to the cm on one to three 50 x 4 m belt transects per site and depth, in the 2015 (just before the 2016 bleaching) and 2020 survey seasons.",
  samplingProtocol = "Belt-transect underwater visual census (50 x 4 m) by one experienced, extensively trained surveyor per season; all diurnally active reef-associated fishes counted, lengths estimated to the nearest cm for fish of 8 cm and more (smaller fish are not in the deposit).",
  temporalCoverage = sprintf("%s/%s", min(ext$date), max(ext$date)),
  surveyEvidenceNote = "The deposit lists fish records only. A transect is taken as surveyed in a season iff it has at least one record (84 transect-seasons; minimum 2 records). Every fish of 8 cm or more is counted, so a taxon of the 198 without a record on a surveyed transect is a zero.",
  notShipped = list(`Actual_size, Size_Class, Median_size_class` = "length of each counted fish (y sums them)",
                    Biomass_g = "derived from length by published length-weight constants (FishBase)")))
ds2 <- write_table(b_x$long, TABLE2, dataset_x, taxa = taxa_x, periods = per_x, script = "data/koester_2023_aldabra_reeffish_count.R")
stage_dict_row(TABLE2,
  description = "Belt-transect visual-census counts of all 198 reef fish taxa (fish of 8 cm or more) at Aldabra Atoll, Seychelles, in the 2015 and 2020 extended surveys: 21 site-depths, one to three replicate transects.",
  url = "https://doi.org/10.6084/m9.figshare.22792580.v3",
  reference = "Koester, A., et al. (2023). Reef fish abundance, size and biomass from Aldabra Atoll (Seychelles) between 2014 and 2021 collected by the Seychelles Islands Foundation. figshare. Data owned by the Seychelles Islands Foundation (SIF), which must be cited.",
  doi_paper = "10.3389/fmars.2023.1230717", doi_data = "10.6084/m9.figshare.22792580.v3", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Survey set inferred. Sibling of koester_2023_aldabra_reeffish_count (indicator list, six seasons); whether a taxon is on the indicator list is in __taxa. SIF asks to be cited.",
  source_via = "figshare")
stage_tag_row(TABLE2, ds2, taxon_group = "Fish", model_family = "N-mixture (community counts, multi-season)",
  sampling_protocol = "visual_census", design = "Multi-season (2 seasons x 1-3 replicate transects)",
  realm = "Marine", country = "SYC", coordinates = "None in source",
  notes = "All-fish UVC (fish >= 8 cm); spatial replicate transects; survey set inferred.", status = "tagged")
