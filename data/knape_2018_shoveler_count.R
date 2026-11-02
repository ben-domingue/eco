#!/usr/bin/env Rscript
# Table:  knape_2018_shoveler_count
# Source: Zenodo 10.5281/zenodo.1303825, "Northern shoveler data for 'Sensitivity of binomial
#         N-mixture models to overdispersion: the importance of assessing model fit'", Knape,
#         Berg & Part, published 2018-07-03, licence CC BY 4.0 (as shown on the record).
# Paper:  Knape, J., Arlt, D., Barraquand, F., Berg, A., Chevalier, M., Part, T., Ruete, A. &
#         Zmihorski, M. (2018). Sensitivity of binomial N-mixture models to overdispersion: the
#         importance of assessing model fit. Methods in Ecology and Evolution 9(10), 2102-2114.
#         https://doi.org/10.1111/2041-210X.13062 (preprint: bioRxiv 10.1101/194340). The case
#         study of that paper; the same data ship as nmixgof::shoveler.
# Data:   three CSVs, no row ids, sites in the same order in all three.
#         count.csv  50 x 10, columns Northern.Shoveler.1..10 = visits 1..10, counts 0-20,
#                    19 NA cells (45 sites with 10 visits, 1 with 9, 1 with 7, 3 with 5).
#         date.csv   50 x 10 Julian day (124-158) of each count, 14 NA. Visit columns are not
#                    in calendar order within a site (46 of 50 sites have non-monotone dates),
#                    so the column is a visit label, not a rank in time. Six cells have a date
#                    but no count (site 23 visit 7; site 48 visits 6-10); one has a count (0)
#                    but no date (site 12 visit 5).
#         site.csv   50 x 3: water = wetland water area (ha); reedcover = share of the wetland
#                    area covered by reeds (the record says percentage, the values are 0-1
#                    fractions); latitude = northing in the Swedish RT90 grid (metres).
#         The record gives no survey year and no site names; the RT90 northings (6.18-6.71 M)
#         span southern to east-central Sweden. The paper is behind a publisher wall for
#         the agent, so the year and the counting protocol are not stated here.
# Mapping (standard E1-E5; N-mixture family):
#   unit = site row number 1..50, taxon = NSHO (Spatula clypeata), occasion = visit column
#   1..10, y = count; unit_water_ha, unit_reedcover_frac, unit_rt90_northing_m as deposited;
#   obs_julian_day from date.csv (no year is deposited, so E8 forbids an ISO `date`; the one
#   surveyed cell without a date carries NA in the covariate).
#   Survey evidence: deposited_matrix; an NA count is not surveyed and becomes a missing row
#   (E4), whatever date.csv holds for that cell. 500 - 19 = 481 rows.
#   Not shipped: nothing is dropped; a one-axis RT90 northing is not a coordinate pair, so no
#   coarsening question arises (and the taxon is Least Concern).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "knape_2018_shoveler_count"
BASE <- "https://zenodo.org/api/records/1303825/files/%s/content"

f <- sapply(c("count.csv", "date.csv", "site.csv"), function(x) download_cached(sprintf(BASE, x), TABLE, x))
cnt  <- as.matrix(fread(f["count.csv"]))
dat  <- as.matrix(fread(f["date.csv"]))
site <- fread(f["site.csv"])

stopifnot(dim(cnt) == c(50, 10), dim(dat) == c(50, 10), dim(site) == c(50, 3),
          identical(colnames(cnt), paste0("Northern.Shoveler.", 1:10)),
          identical(colnames(dat), paste0("date.", 1:10)),
          identical(names(site), c("water", "reedcover", "latitude")))
stopifnot(sum(is.na(cnt)) == 19, sum(is.na(dat)) == 14, sum(is.na(cnt) & is.na(dat)) == 13,
          all(cnt[!is.na(cnt)] >= 0), all(cnt[!is.na(cnt)] == round(cnt[!is.na(cnt)])), max(cnt, na.rm = TRUE) == 20,
          range(dat, na.rm = TRUE) == c(124, 158), all(dat[!is.na(dat)] == round(dat[!is.na(dat)])),
          identical(as.integer(table(rowSums(!is.na(cnt)))), c(3L, 1L, 1L, 45L)))
# surveyed cell without a date, and dated cells without a count
stopifnot(which(!is.na(cnt) & is.na(dat)) == 12 + 4 * 50,
          identical(as.integer(sort(which(is.na(cnt) & !is.na(dat), arr.ind = TRUE)[, "row"])), c(23L, 48L, 48L, 48L, 48L, 48L)))
stopifnot(all(site$water > 0), all(site$reedcover >= 0 & site$reedcover <= 1),
          all(site$latitude > 6.1e6 & site$latitude < 6.8e6), round(range(site$latitude)) == c(6175880, 6711546))
# visit columns are labels, not a time order
stopifnot(sum(apply(dat, 1, function(d) { d <- d[!is.na(d)]; is.unsorted(d) })) == 46)

dimnames(cnt) <- list(seq_len(50), seq_len(10))
long <- array_to_eco(cnt, taxon = "NSHO", site_ids = seq_len(50),
                     site_covs = data.frame(water_ha = site$water, reedcover_frac = site$reedcover,
                                            rt90_northing_m = site$latitude),
                     obs_covs = list(julian_day = dat))
stopifnot(nrow(long) == 481, uniqueN(long$unit) == 50, sum(is.na(long$obs_julian_day)) == 1,
          sum(long$y) == sum(cnt, na.rm = TRUE), !anyNA(long$y))

taxa <- make_taxa("NSHO", "Spatula clypeata", vernacularName = "Northern Shoveler")
dataset <- list(
  title = "Northern shoveler repeated counts at 50 Swedish wetlands x 10 visits (Knape et al. 2018)",
  creator = "Knape, Jonas; Berg, Ake; Part, Tomas",
  pubDate = "2018", sourceURL = "https://doi.org/10.5281/zenodo.1303825",
  citation = "Knape, J., Arlt, D., Barraquand, F., Berg, A., Chevalier, M., Part, T., Ruete, A. & Zmihorski, M. (2018). Sensitivity of binomial N-mixture models to overdispersion: the importance of assessing model fit. Methods in Ecology and Evolution 9(10), 2102-2114. https://doi.org/10.1111/2041-210X.13062. Data: Zenodo https://doi.org/10.5281/zenodo.1303825 (CC BY 4.0).",
  paperDOI = "10.1111/2041-210X.13062", dataDOI = "10.5281/zenodo.1303825",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "The N-mixture case study of Knape et al. (2018): northern shoveler counts on up to 10 visits to each of 50 wetlands in southern and east-central Sweden within one breeding season (Julian days 124-158), with wetland water area, reed cover and RT90 northing as site covariates and the Julian day of each visit. 481 of 500 site-visits were surveyed.",
  samplingProtocol = "Repeated counts of northern shovelers at wetlands, up to 10 visits per wetland within one season; protocol details (what was counted, visit duration) are in the paper, which the deposit does not restate.",
  samplingProtocolCode = "site_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "occasion",
  geographicCoverage = "Southern to east-central Sweden (RT90 northings 6.18-6.71 million m); no eastings or site names deposited",
  temporalCoverage = "one breeding season, Julian days 124-158; the year is not stated in the deposit",
  coordinatesCoarsened = NA,
  covariateNote = "unit_water_ha = wetland water area (ha); unit_reedcover_frac = share of wetland area covered by reeds (0-1; the record calls it a percentage); unit_rt90_northing_m = northing in the Swedish RT90 grid, a single axis and not a coordinate pair. obs_julian_day is the day of year of the visit; one surveyed cell (site 12, visit 5) has no date and carries NA. Visit columns are labels: within a site the dates are not in calendar order.",
  notes = "Columns in count.csv and date.csv are visit labels 1-10, kept as occasion; order visits by obs_julian_day for a time-ordered analysis. Six cells have a date but no count and are treated as not surveyed. The same data are bundled as nmixgof::shoveler.",
  notShipped = list(none = "every deposited value is shipped"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/knape_2018_shoveler_count.R")

stage_dict_row(TABLE,
  description = "Northern shoveler counts on up to 10 visits to 50 wetlands in southern and east-central Sweden within one breeding season, with wetland water area, reed cover, RT90 northing and the Julian day of each visit (Knape et al. 2018, N-mixture overdispersion case study).",
  url = "https://doi.org/10.5281/zenodo.1303825",
  reference = "Knape, J., Arlt, D., Barraquand, F., Berg, A., Chevalier, M., Part, T., Ruete, A. & Zmihorski, M. (2018). Sensitivity of binomial N-mixture models to overdispersion: the importance of assessing model fit. Methods in Ecology and Evolution 9(10), 2102-2114.",
  doi_paper = "10.1111/2041-210X.13062", doi_data = "10.5281/zenodo.1303825",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Clean 50 x 10 count matrix with per-visit Julian days (no year deposited, so no ISO date) and three site covariates; 19 unsurveyed cells. Same data as nmixgof::shoveler.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture",
  sampling_protocol = "site_count", design = "Single-season (10 visits)", realm = "Freshwater", country = "SWE",
  coordinates = "None in source (RT90 northing only, one axis)", notes = "N-mixture overdispersion case study (Knape et al. 2018). Year not deposited.")
