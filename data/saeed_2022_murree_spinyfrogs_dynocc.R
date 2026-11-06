#!/usr/bin/env Rscript
# Table:  saeed_2022_murree_spinyfrogs_dynocc
# Source: Dryad doi:10.5061/dryad.8sf7m0cqw (CC0 1.0, as shown on the Dryad page; published
#         2023-01-08). Saeed, M., Rais, M., Akram, A., Williams, M.R., Kellner, K.F., Hashsham, S.A.
#         & Davis, D.R. Development and validation of an eDNA protocol for monitoring endemic Asian
#         Spiny Frogs in the Himalayan region of Pakistan.
# Paper:  Saeed, M. et al. (2022). Scientific Reports 12, doi:10.1038/s41598-022-09084-1. 34 stream
#         and spring sites in Tehsil Murree and Ayubia National Park, Pakistan, surveyed by visual
#         encounter (VES) in 2017-2018 and by eDNA in 2018 for the Hazara torrent frog (Allopaa
#         hazarensis) and the Murree Hills frog (Nanorana vicina); two-species occupancy (unmarked).
# Data:   AH_ / NV_VES_Detection.txt (row 1: the date of each visit column; row 2: header; 34 sites
#         with ID, Tehsil, Location, Latitude, Longitude, Elevation(m), naive VES / eDNA flags,
#         wetland and forest type with dummies, then VES1..VES21 detections 0/1; one empty AH cell);
#         (site columns identical in the two files apart from the naive flags and one STPF dummy that
#         disagrees with the Forest text; the text is shipped); AH_ / NV_visit_covariates (water temperature Tem1..Tem21 per visit, identical files,
#         asserted); site covariate files (the same site columns); eDNA detection files (21 columns
#         dated as 7 dates x 3 replicates in 2018); multimethod files (VES and eDNA columns paired);
#         the authors' code.
# Mapping (standard: dynamic two-species occupancy, E9 core): VES only. unit = site ID; taxon =
#   ALLHAZ / NANVIC; period = year (1 = 2017, visits 1-13; 2 = 2018, visits 14-21, from the dated
#   header); occasion = visit within the year; date = the header date of the visit (one date per
#   visit column, applied to every site as deposited); y = the cell. Shared-detector ruling: the one
#   empty AH cell drops that site-visit for both species. obs_water_temp_c = Tem; unit_: tehsil,
#   location, latitude, longitude, elevation, wetland and forest type. Survey evidence:
#   deposited_matrix.
#   Not shipped: the eDNA matrices. Their header dates are seven 2018 dates with three replicates
#   each, but the authors' code reads columns 1-7 as 2017 visits and 14-19 as 2018 visits (the VES
#   calendar), so which survey each eDNA column is cannot be settled from the deposit. The
#   multimethod files pair VES and eDNA columns on that same unresolved alignment. The naive flags
#   are derived. Coordinates: both frogs are IUCN LC (checked below), so site coordinates are kept
#   as published.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "saeed_2022_murree_spinyfrogs_dynocc"
dir <- download_dryad("10.5061/dryad.8sf7m0cqw", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rd <- function(n) {
  f <- list.files(dir, n, recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
  L <- strsplit(sub("^﻿", "", readLines(f, warn = FALSE, encoding = "UTF-8")), "\t", fixed = TRUE)
  hdr <- L[[2]]; rows <- L[-(1:2)]; rows <- rows[vapply(rows, function(z) length(z) > 0 && nzchar(z[1]), TRUE)]
  w <- max(which(nzchar(hdr)))
  m <- t(vapply(rows, function(z) { z <- c(z, rep("", w)); z[1:w] }, character(w))); colnames(m) <- hdr[1:w]
  list(top = L[[1]], d = as.data.table(m))
}
V <- list(ALLHAZ = rd("^AH_VES_Detection\\.txt$"), NANVIC = rd("^NV_VES_Detection\\.txt$"))
T1 <- rd("^AH_visit_covariates\\.txt$"); T2 <- rd("^NV_visit-covariate\\.txt$")
vc <- paste0("VES", 1:21); tc <- paste0("Tem", 1:21)
d1 <- V$ALLHAZ$d; d2 <- V$NANVIC$d
stopifnot(nrow(d1) == 34, identical(d1$ID, d2$ID), identical(d1[, c(1:6, 9:10)], d2[, c(1:6, 9:10)]), all(vc %in% names(d1)),
          identical(T1$d[, ..tc], T2$d[, ..tc]), identical(T1$d$ID, d1$ID))
vi <- match("VES1", names(d1)); dates_raw <- V$ALLHAZ$top[vi:(vi + 20)]
stopifnot(identical(dates_raw, V$NANVIC$top[vi:(vi + 20)]))
dts <- as.IDate(gsub("/", "-", dates_raw), format = "%d-%m-%Y"); stopifnot(!anyNA(dts), !is.unsorted(dts))
yr <- year(dts); stopifnot(identical(yr, c(rep(2017L, 13), rep(2018L, 8))))
ti <- match("Tem1", names(T1$d)); stopifnot(identical(as.IDate(gsub("/", "-", T1$top[ti:(ti + 20)]), format = "%d-%m-%Y"), dts))
M <- lapply(V, function(v) as.matrix(v$d[, ..vc]))
stopifnot(all(unlist(M) %in% c("0", "1", "")), sum(M$ALLHAZ == "") == 1, sum(M$NANVIC == "") == 0)
miss <- M$ALLHAZ == "" | M$NANVIC == ""
temp <- as.matrix(T1$d[, ..tc]); stopifnot(!anyNA(suppressWarnings(as.numeric(temp))))
grid <- CJ(i = 1:34, j = 1:21)[!miss[cbind(i, j)]]
long <- rbindlist(lapply(names(M), function(k) grid[, .(unit = d1$ID[i], taxon = k, period = ifelse(yr[j] == 2017L, 1L, 2L),
  occasion = ifelse(yr[j] == 2017L, j, j - 13L), date = as.character(dts[j]), y = as.integer(M[[k]][cbind(i, j)]),
  obs_water_temp_c = as.numeric(temp[cbind(i, j)]))]))
sc <- d1[, .(unit = ID, unit_tehsil = Tehsil, unit_location = Location, unit_latitude = as.numeric(Latitude), unit_longitude = as.numeric(Longitude),
             unit_elevation_m = as.numeric(`Elevation(m)`), unit_wetland_type = Wetlands, unit_forest_type = Forest)]
long <- order_eco(merge(long, sc, by = "unit"))
stopifnot(nrow(long) == 2 * (34 * 21 - 1), sum(long$y) == sum(M$ALLHAZ == "1") + sum(M$NANVIC == "1") - sum(M$NANVIC == "1" & miss))
periods <- data.table(period = 1:2, period_year = 2017:2018)
taxa <- make_taxa(c("ALLHAZ", "NANVIC"), c("Allopaa hazarensis", "Nanorana vicina"), vernacularName = c("Hazara torrent frog", "Murree Hills frog"))
iu <- iucn_category(taxa$taxonID, taxa$scientificName); print(iu)
stopifnot(!any(iu %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Visual-encounter detections of two endemic spiny frogs at 34 stream and spring sites, Murree and Ayubia, Pakistan, 2017-2018",
  creator = "Saeed, Muhammad; Rais, Muhammad; Akram, Ayesha; Williams, Maggie R.; Kellner, Kenneth F.; Hashsham, Syed A.; Davis, Drew R.", pubDate = "2023",
  doi = "10.5061/dryad.8sf7m0cqw", sourceURL = "https://doi.org/10.5061/dryad.8sf7m0cqw",
  citation = "Saeed, M., Rais, M., Akram, A., Williams, M. R., Kellner, K. F., Hashsham, S. A., & Davis, D. R. (2023). Development and validation of an eDNA protocol for monitoring endemic Asian Spiny Frogs in the Himalayan region of Pakistan [Dataset]. Dryad. https://doi.org/10.5061/dryad.8sf7m0cqw",
  paperDOI = "10.1038/s41598-022-09084-1",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Visual encounter survey detections of the Hazara torrent frog (Allopaa hazarensis) and the Murree Hills frog (Nanorana vicina) on 21 dated visits (13 in 2017, 8 in 2018) to 34 permanent streams, seasonal streams and springs in Tehsil Murree and Ayubia National Park, Pakistan, with water temperature per visit and elevation, wetland and forest type per site.",
  samplingProtocol = "Visual encounter surveys of stream pools and springs stratified by elevation, forest type and wetland type; both species recorded on each visit; water temperature measured.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "visits within each year treated as replicates; the authors used February-June visits of each year and a year effect", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Tehsil Murree (Punjab) and Ayubia National Park (Khyber Pakhtunkhwa), Pakistan; site coordinates as published",
  temporalCoverage = "2017-02-25/2018-07-19",
  notShipped = list(eDNA = "the eDNA detection matrices: header dates (7 dates x 3 replicates in 2018) disagree with the authors' code (columns read as 2017 and 2018 visits), so the survey of each column is unresolved",
                    multimethod = "the multimethod files (VES and eDNA columns paired on the same unresolved alignment)",
                    naive = "the naive VES / eDNA flags and the dummy-coded type columns (derived)"),
  notes = "Visit dates come from the first header row and apply to every site. The authors analysed visits 1-7 (2017) and 14-19 (2018); all 21 visits are shipped.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/saeed_2022_murree_spinyfrogs_dynocc.R")
stage_dict_row(TABLE, description = "Visual-encounter detections of the Hazara torrent frog and Murree Hills frog at 34 streams and springs in northern Pakistan, 21 visits over 2017-2018.",
  url = "https://doi.org/10.5061/dryad.8sf7m0cqw", reference = "Saeed, M. et al. (2022). Development and validation of an eDNA protocol for monitoring endemic Asian Spiny Frogs in the Himalayan region of Pakistan. Scientific Reports, 12.",
  doi_paper = "10.1038/s41598-022-09084-1", doi_data = "10.5061/dryad.8sf7m0cqw", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Two-species occupancy, VES only; eDNA not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Dynamic community occupancy",
  sampling_protocol = "visual_encounter", design = "Multi-season (2 years, 8-13 visits each)", realm = "Freshwater",
  country = "PAK", coordinates = "As published", notes = "Himalayan stream frogs.")
