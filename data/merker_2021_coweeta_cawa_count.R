#!/usr/bin/env Rscript
# Table:  merker_2021_coweeta_cawa_count
# Source: Zenodo doi:10.5281/zenodo.4238700, version v1.1, published 2020-11-02 (Merker, S., & Chandler, R.).
#         Licence as shown on the record: "Other (Open)", with no licence text (unclear terms, held 2026-11-05).
#         The same files are on GitHub (smerker/Merker_Chandler_JAE, the record's isSupplementTo link), whose
#         repository licence is GPL-3.0. PERMISSION: Richard Chandler (second author) wrote on 2026-11-13, in reply
#         to Ben's request of 2026-11-06: "Yes, please add our data to your repository under whatever license you
#         prefer." Derived licence CC BY 4.0, as proposed in the request. The same email gave the array layout
#         (below).
# Paper:  Merker, S. A., & Chandler, R. B. (2021). An experimental test of the Allee effect range limitation
#         hypothesis. Journal of Animal Ecology 90(3): 585-593. doi:10.1111/1365-2656.13389 (PMC7984094).
#         Read (PMC) for the design: Nantahala National Forest, in and around the Coweeta Hydrologic Laboratory,
#         southwestern North Carolina; 71 points on a 500 m grid, about 800 to 1,400 m elevation; one 10-min count
#         per point per breeding season, 2014 to 2017, split into four 2.5-min periods; every individual seen or
#         heard within 100 m recorded; wind, noise and time of day recorded on a 0-5 scale, Julian date; all
#         detection covariates scaled and centred. Playback of conspecific song at 10 sites in 2016 and 8 in 2017.
# Data:   JAE-data.gzip: an R save file (gzip) with seven objects, none with year labels:
#           cawa.count.3D2  int [71, 4, 4]  Canada warbler count per point x 2.5-min interval x year; NA only at
#                           point 38 (PCCow038) in year 1, all four intervals (not surveyed).
#           wind3D2, noise3D2, time3D2.mat, date3D.pbs2  num [71, 4, 4]  scaled detection covariates, constant
#                           across the four intervals of a point-year (asserted); filled (not NA) at the
#                           unsurveyed point-year.
#           treat.mat       num [71, 4, 4] 0/1 with point ids as row names ("PCCow001".."PCCow049" without 046,
#                           "PCDry001".."PCDry023"); constant across intervals; 0 sites in years 1-2, 11 in year 3,
#                           14 in year 4.
#           climate.var.new num [71]  PC1 of PRISM 1981-2010 temperature and precipitation normals (negative =
#                           cooler and wetter).
#         Allee effects Nmixture.R, Abundance_EN_clim-trt-D.jag, Merker_Chandler_Appendices.Rmd: model code. The
#         JAGS model fits each interval as a binomial count of the point's N for the year (repeated counts).
#         Array dimensions, per Chandler's email: (71 sites) x (4 2.5-min intervals) x (4 years), in that order;
#         years 1-4 are 2014-2017 (paper).
# Mapping: unit = point id (treat.mat row names), taxon = CARCAN (Cardellina canadensis), period = year
#   (1 = 2014 .. 4 = 2017), occasion = 2.5-min interval 1..4 of the year's single 10-min count, y = count in the
#   interval. surveyEvidence = deposited_matrix (NA = point not surveyed that year). obs_wind_scaled,
#   obs_noise_scaled, obs_time_scaled, obs_date_scaled: as deposited (point-year level; the centring constants
#   are not deposited, so the raw values are not recoverable). unit_climate_pc1: as deposited. No coordinates
#   are deposited.
#   Not shipped: treat.mat, pending the authors: it flags 11 points in 2016 and 14 in 2017 (the 10 of 2016
#   minus PCDry014 plus 4 more), where the paper reports playback at 10 sites in 2016 and 8 in 2017, so it is
#   not the playback indicator as described; the authors' model uses it as the treatment covariate on growth
#   into year t. Model outputs (N, density, growth rates) are not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "merker_2021_coweeta_cawa_count"
ZEN <- "https://zenodo.org/api/records/4238700/files/"

f <- download_cached(paste0(ZEN, "JAE-data.gzip/content"), TABLE)
stopifnot(identical(unname(tools::md5sum(f)), "68286cb293f8812587d8af507d132b47"))
e <- new.env(); load(f, envir = e)
stopifnot(setequal(ls(e), c("cawa.count.3D2", "climate.var.new", "date3D.pbs2", "noise3D2", "time3D2.mat",
                            "treat.mat", "wind3D2")))
Y <- e$cawa.count.3D2
ids <- dimnames(e$treat.mat)[[1]]
stopifnot(identical(unname(dim(Y)), c(71L, 4L, 4L)), length(ids) == 71, !anyDuplicated(ids),
          identical(ids, c(sprintf("PCCow%03d", setdiff(1:49, 46)), sprintf("PCDry%03d", 1:23))),
          length(e$climate.var.new) == 71, !anyNA(e$climate.var.new))
na <- which(is.na(Y), arr.ind = TRUE)
stopifnot(nrow(na) == 4, all(na[, 1] == 38), all(na[, 3] == 1), ids[38] == "PCCow038",
          all(Y >= 0, na.rm = TRUE), max(Y, na.rm = TRUE) == 5, sum(Y, na.rm = TRUE) == 290,
          identical(as.vector(apply(Y, 3, sum, na.rm = TRUE)), c(83L, 67L, 81L, 59L)))
covs <- c(wind = "wind3D2", noise = "noise3D2", time = "time3D2.mat", date = "date3D.pbs2")
for (v in c(covs, "treat.mat")) {
  x <- e[[v]]
  stopifnot(identical(unname(dim(x)), unname(dim(Y))), !anyNA(x),
            all(apply(x, c(1, 3), function(r) length(unique(r)) == 1)))    # point-year level
}
tr <- e$treat.mat[, 1, ]
stopifnot(identical(unname(colSums(tr)), c(0, 0, 11, 14)))

# [site, year, interval] -> [site, year x interval] with intervals nested in years
flat <- function(a) matrix(a, nrow = 71)   # column (t-1)*4 + j: interval j of year t
obs <- lapply(covs, function(v) { m <- flat(e[[v]]); m[is.na(flat(Y))] <- NA; m })
names(obs) <- paste0(names(covs), "_scaled")
long <- array_to_eco(flat(Y), taxon = "CARCAN", site_ids = ids,
                     site_covs = data.frame(climate_pc1 = e$climate.var.new),
                     obs_covs = obs, period = rep(1:4, each = 4))
stopifnot(nrow(long) == 71 * 16 - 4, uniqueN(long$unit) == 71, sum(long$y) == 290,
          identical(sort(unique(long$occasion)), 1:4),
          long[, .N, by = .(unit, period)][, all(N == 4)],
          !anyNA(long[, .(obs_wind_scaled, obs_noise_scaled, obs_time_scaled, obs_date_scaled)]))
# interval j of year t really is cell [ , j, t]
stopifnot(long[unit == "PCCow001" & period == 3 & occasion == 2, y] == Y[1, 2, 3],
          long[unit == "PCDry023" & period == 4 & occasion == 4, y] == Y[71, 4, 4])

taxa <- make_taxa("CARCAN", "Cardellina canadensis", vernacularName = "Canada Warbler")
stopifnot(identical(iucn_category(taxa$taxonID[1], "Cardellina canadensis"), "LC"))
periods <- data.table(period = 1:4, year = 2014:2017,
                      n_points_surveyed = as.integer(long[, uniqueN(unit), by = period][order(period), V1]))
stopifnot(identical(periods$n_points_surveyed, c(70L, 71L, 71L, 71L)))

dataset <- list(
  title = "Canada warbler counts in four 2.5-min intervals at 71 points near Coweeta, North Carolina, 2014 to 2017",
  creator = "Merker, Samuel; Chandler, Richard", pubDate = "2020",
  doi = "10.5281/zenodo.4238700", sourceURL = "https://doi.org/10.5281/zenodo.4238700",
  citation = "Merker, S., & Chandler, R. (2020). An experimental test of the Allee effects range limitation hypothesis (v1.1) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.4238700",
  paperDOI = "10.1111/1365-2656.13389",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Point counts of Canada warbler (Cardellina canadensis) at its trailing-edge range boundary in the southern Appalachians: 71 points on a 500 m grid in Nantahala National Forest, in and around the Coweeta Hydrologic Laboratory, about 800 to 1,400 m elevation. One 10-minute count per point per breeding season, 2014 to 2017, recorded in four 2.5-minute intervals, with scaled wind, noise, time-of-day and date covariates and a PRISM climate principal component per point. The study added conspecific playback at some points in 2016 and 2017 to test for Allee effects; the treatment indicator is not in this table (see notes).",
  samplingProtocol = "10-minute point count by expert observers between 06:00 and 11:00 on days with little wind or rain, every individual seen or heard within 100 m recorded, split into four 2.5-minute intervals; one count per point per year.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the four intervals are consecutive parts of one 10-minute count; the authors fit each as a binomial count of the point's abundance for the year (dynamic N-mixture across years)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Nantahala National Forest at and around the Coweeta Hydrologic Laboratory, Macon County, North Carolina, USA",
  temporalCoverage = "2014/2017",
  covariateNote = "obs_* are the authors' scaled and centred values (wind, noise and time of day recorded on a 0-5 scale; Julian date), constant across a point-year's four intervals; the centring constants are not deposited. unit_climate_pc1 is PC1 of PRISM 1981-2010 temperature and precipitation normals (negative = cooler and wetter).",
  notShipped = list(
    treatment = "treat.mat (0/1 point x year) flags 11 points in 2016 and 14 in 2017, where the paper reports conspecific playback at 10 sites in 2016 and 8 in 2017; held until the authors say what it encodes",
    model_output = "abundance, density and growth-rate estimates (not deposited)"),
  notes = "The deposit has no year labels and no interval labels; Richard Chandler gave the array order (sites x 2.5-min intervals x years) by email on 2026-11-13, and the paper gives the years 2014-2017. Point PCCow038 was not surveyed in 2014. Licence: the Zenodo record says 'Other (Open)' with no text; the authors gave written permission (2026-11-13) to redistribute under a licence of eco's choice, and the table is CC BY 4.0.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/merker_2021_coweeta_cawa_count.R")
stage_dict_row(TABLE,
  description = "Canada warbler (Cardellina canadensis) counts in four 2.5-minute intervals of one 10-minute point count per year at 71 points near the Coweeta Hydrologic Laboratory, North Carolina, 2014 to 2017, with scaled detection covariates and a climate index.",
  url = "https://doi.org/10.5281/zenodo.4238700",
  reference = "Merker, S. A., & Chandler, R. B. (2021). An experimental test of the Allee effect range limitation hypothesis. Journal of Animal Ecology, 90(3), 585-593.",
  doi_paper = "10.1111/1365-2656.13389", doi_data = "10.5281/zenodo.4238700",
  original_license = "Zenodo 'Other (Open)' with no licence text (GitHub copy GPL-3.0); authors' written permission 2026-11-13 to redistribute under any licence",
  derived_license = "CC BY 4.0",
  notes = "Array layout from the authors by email; playback treatment indicator held pending the authors.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "point_count", design = "Multi-season (4 years; four 2.5-min intervals of one count per year)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Trailing-edge range boundary; playback experiment (treatment not yet shipped).")
