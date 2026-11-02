#!/usr/bin/env Rscript
# Table:  ferguson_2015_macon_bawa_fpocc
# Source: Dryad doi:10.5061/dryad.t68v8 (CC0 1.0, as shown on the Dryad page; version 1,
#         published 2016-07-14). Ferguson, P.F.B., Conroy, M.J. & Hepinstall-Cymerman, J.
#         (2016). Data from: Occupancy models for data with false positive and false
#         negative errors and heterogeneity across sites and surveys.
# Paper:  Ferguson, P.F.B., Conroy, M.J. & Hepinstall-Cymerman, J. (2015). Occupancy
#         models for data with false positive and false negative errors and heterogeneity
#         across sites and surveys. Methods in Ecology and Evolution 6, 1395-1406,
#         doi:10.1111/2041-210X.12442 (Crossref; the Dryad record's primary article).
#         The paper's example application: Black-and-white Warbler occupancy against
#         residential development, fitted with the CP (confirmed-presence) model.
# Data:   MergeBirdSiteData-Final.csv, 272 rows (sites) x 10 columns: Xcoord, Ycoord,
#         y1..y3 (BAWA detected on visit 1..3, 0/1), certain1..certain3 (a confirmed
#         detection on that visit, 0/1), Year (0 = sampled in 2010, 1 = 2011), Pforest
#         (percent forest within 200 m). README_for_MergeBirdSiteData-Final.csv defines
#         the columns. No cell is missing: every site has three visits. A confirmed
#         detection always coincides with a detection (certain = 1 implies y = 1).
#         The README says the coordinates are NAD 1983 UTM zone 17N, but the values are
#         decimal degrees (longitude -83.6 to -83.1, latitude 35.0 to 35.3: Macon County,
#         North Carolina, southern Appalachians); shipped as decimal degrees with the
#         README's datum recorded in `crs`. No site ids are deposited; unit = row number.
#
# Mapping (standard: multi-state occupancy incl. false positives, E9 core; occuFP
#   "type 2" data where every survey is one of 0 / uncertain / certain):
#   unit = site (row index 1..272), occasion = visit 1..3, one period (each site was
#   surveyed in one breeding season, 2010 or 2011; the year is a unit covariate),
#   taxon = BAWA (Mniotilta varia). y is the per-survey state: 0 not detected,
#   1 detected but not confirmed (may be a false positive), 2 confirmed detection
#   (certain). y is a recode of two deposited 0/1 columns, so there is no single
#   y_raw; the rule is stated in `notes`. unit_decimalLatitude/Longitude, unit_pforest_pct,
#   unit_year_sampled as deposited. Survey evidence: the deposited matrix is complete
#   (272 x 3 with no NA), so every site-visit is a survey. The warbler is IUCN LC and
#   the coordinates are the authors' own; kept as published. Nothing in the deposit is a
#   model output. The paper's "confirmed absence" (CACP) design is not in this deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ferguson_2015_macon_bawa_fpocc"
dir <- download_dryad("10.5061/dryad.t68v8", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^MergeBirdSiteData-Final\\.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
raw <- fread(f)

# facts about the source
stopifnot(identical(names(raw), c("Xcoord", "Ycoord", "y1", "y2", "y3", "certain1", "certain2", "certain3", "Year", "Pforest")),
          nrow(raw) == 272, !anyNA(raw), !anyDuplicated(raw[, .(Xcoord, Ycoord)]))
det <- as.matrix(raw[, .(y1, y2, y3)]); cert <- as.matrix(raw[, .(certain1, certain2, certain3)])
stopifnot(all(det %in% 0:1), all(cert %in% 0:1), all(det[cert == 1] == 1),
          sum(det) == 157, sum(cert) == 23, all(raw$Year %in% 0:1), sum(raw$Year) == 161,
          all(raw$Pforest >= 0 & raw$Pforest <= 100),
          all(raw$Xcoord > -83.7 & raw$Xcoord < -83.0), all(raw$Ycoord > 34.9 & raw$Ycoord < 35.4))  # decimal degrees, not UTM

# per-survey state: 0 none, 1 uncertain detection, 2 confirmed detection
state <- det + cert
stopifnot(all(state %in% 0:2), sum(state == 1) == 134, sum(state == 2) == 23)
dimnames(state) <- list(seq_len(nrow(raw)), NULL)
site_covs <- raw[, .(decimalLatitude = Ycoord, decimalLongitude = Xcoord,
                     pforest_pct = Pforest, year_sampled = 2010L + Year)]
long <- array_to_eco(state, taxon = "BAWA", site_ids = seq_len(nrow(raw)), site_covs = site_covs)
stopifnot(nrow(long) == 272 * 3, uniqueN(long$unit) == 272, all(long$occasion %in% 1:3))

taxa <- make_taxa("BAWA", "Mniotilta varia", vernacularName = "Black-and-white Warbler")
dataset <- list(
  title = "Black-and-white Warbler point-count detections with confirmed and unconfirmed detections at 272 sites, Macon County, North Carolina, 2010-2011",
  creator = "Ferguson, Paige F. B.; Conroy, Michael J.; Hepinstall-Cymerman, Jeffrey",
  pubDate = "2016", doi = "10.5061/dryad.t68v8", sourceURL = "https://doi.org/10.5061/dryad.t68v8",
  citation = "Ferguson, P.F.B., Conroy, M.J. & Hepinstall-Cymerman, J. (2016). Data from: Occupancy models for data with false positive and false negative errors and heterogeneity across sites and surveys. Dryad, dataset, https://doi.org/10.5061/dryad.t68v8.",
  paperDOI = "10.1111/2041-210X.12442",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point counts for Black-and-white Warbler (Mniotilta varia) at 272 sites in Macon County, North Carolina, each visited three times in one breeding season (2010 or 2011), recording for every visit whether the species was detected and whether that detection was confirmed. The example application of Ferguson et al. (2015), which fit a confirmed-presence (CP) false-positive occupancy model relating occupancy to residential development; percent forest cover within 200 m is the deposited site covariate.",
  samplingProtocol = "Point counts, three visits per site within one breeding season; each visit records detection (0/1) and whether the detection was confirmed (0/1). The deposit and README do not state count duration, radius or what constituted confirmation; see the paper.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "site",
  closure = "occasion (three visits within one breeding season per site; sites sampled in 2010 or 2011, never both)",
  stateCodes = list(`0` = "not detected", `1` = "detected, not confirmed (possible false positive)", `2` = "detected and confirmed (certain detection)"),
  geographicCoverage = list(description = "Macon County, North Carolina, USA (southern Appalachians), from the deposited coordinates",
                            boundingBox = list(west = round(min(raw$Xcoord), 2), east = round(max(raw$Xcoord), 2),
                                               south = round(min(raw$Ycoord), 2), north = round(max(raw$Ycoord), 2))),
  temporalCoverage = "2010/2011",
  crs = "README states NAD 1983 (UTM zone 17N), but the deposited values are decimal degrees; shipped as decimal degrees on that datum",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published by the authors; Mniotilta varia is IUCN LC, not flagged"),
  notes = "y = y_k + certain_k from the deposit's two 0/1 columns per visit (certain = 1 never occurs without y = 1, asserted), i.e. occuFP type-2 data: 0 / uncertain / certain. No y_raw because the recode combines two deposited columns. unit_year_sampled is 2010 or 2011 from the deposit's Year indicator. Site ids are row numbers (none deposited).",
  notShipped = list(none = "every deposited column is shipped"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/ferguson_2015_macon_bawa_fpocc.R")

stage_dict_row(TABLE,
  description = "Black-and-white Warbler point counts at 272 sites in Macon County, North Carolina (2010 or 2011), three visits each, with every visit coded 0 not detected / 1 unconfirmed detection / 2 confirmed detection; site coordinates, percent forest within 200 m and survey year as covariates. The false-positive occupancy example of Ferguson et al. (2015).",
  url = "https://doi.org/10.5061/dryad.t68v8",
  reference = "Ferguson, P.F.B., Conroy, M.J., & Hepinstall-Cymerman, J. (2015). Occupancy models for data with false positive and false negative errors and heterogeneity across sites and surveys. Methods in Ecology and Evolution, 6(12), 1395-1406.",
  doi_paper = "10.1111/2041-210X.12442", doi_data = "10.5061/dryad.t68v8",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-state response (0/1/2 = none / uncertain / certain detection) for false-positive occupancy models (occuFP type 2). README labels the coordinates UTM but they are decimal degrees. Count protocol details are only in the paper.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state occupancy (false positives, occuFP type 2 / CP model)",
  sampling_protocol = "point_count", design = "Single-season (3 visits; sites in 2010 or 2011)", realm = "Terrestrial",
  country = "USA", coordinates = "As published", notes = "23 confirmed and 134 unconfirmed detections over 816 surveys.")
