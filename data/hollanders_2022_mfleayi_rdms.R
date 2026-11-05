#!/usr/bin/env Rscript
# Table:  hollanders_2022_mfleayi_rdms
# Source: Dryad doi:10.5061/dryad.g1jwstqtb, version 190141 (published 2022-08-03), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Hollanders, M. et al. "Recovered frog populations coexist
#         with endemic Batrachochytrium dendrobatidis despite load-dependent mortality". Code on Zenodo
#         10.5281/zenodo.6981761 (MIT; m2-cmr.qmd), which fixes the array layout used below; the code is not shipped.
# Paper:  Hollanders, M., Grogan, L. F., Nock, C. J., McCallum, H. I. & Newell, D. A. (2022). Recovered frog
#         populations coexist with endemic Batrachochytrium dendrobatidis despite load-dependent mortality.
#         Ecological Applications 33, e2724, doi:10.1002/eap.2724 (not read; design from README.txt and m2-cmr.qmd).
# Data:   README.txt and ten csv files for a robust-design mark-recapture study of adult Fleay's barred frogs
#         (Mixophyes fleayi, IUCN EN) at three creeks in northern New South Wales (Brindle Creek, Tuntable Creek,
#         Bat Cave Creek), 23 primary occasions 2017-2021, each of 2-3 consecutive nights (secondaries).
#         ch.csv: no header, 462 rows x 207 columns; m2-cmr.qmd reads it as array(c(462, 23 primaries,
#           3 secondaries, 3 sites)) (primary fastest, then secondary, then site), with 462, 136 and 88
#           individuals at the three sites (rows beyond a site's count are NA, asserted). 0 = not captured,
#           1 = captured and Bd-negative, 2 = captured and Bd-positive, NA = missing. A survey that was done is
#           non-NA for every frog from its first capture on; cells before an individual's first capture are NA
#           (histories start at, or a little before, first capture; asserted that no surveyed night from first
#           capture on is NA). In the last primary the frogs were not swabbed (m2-cmr.qmd: "delta is a
#           vector of all 1's except for the last primary when we did not swab"), so its captures are coded 1
#           whatever the infection state (asserted: no 2 in primary 23).
#         dates.csv: first night of each primary per site (d/m/yy); Tuntable primary 22 reads "1/2/20", between
#           28/12/20 and 13/3/21, and is read as 1/2/21 (asserted, the only out-of-order date).
#         sex.csv (0 male, 1 female, NA unknown; rows by site), bw.csv (body weight, g), length.csv (snout-urostyle
#           length, mm) and loads.csv (Bd ITS copies per swab, NA if not infected or not captured): 462 x 69 =
#           individual x (primary, site). covs-surv.csv: 207 rows = (primary, secondary, site), SILO daily maximum
#           and minimum temperature, vapour pressure and rainfall on the survey day. covs-int.csv: 69 rows =
#           (primary, site), SILO mean maximum and minimum temperature and cumulative rainfall over the interval
#           before the primary. ints.csv: intervals between primaries in 6-week units (derivable from dates).
#           community.csv: Bd loads of swabbed frogs of sympatric species (infection data, not detection data).
# Mapping (standard E9 multi-state capture-recapture, robust design):
#   unit = frog, "<site>_<row>" (BR, TU, BC); cluster_id = site; taxon = MIXFLE; period = primary 1..23 (same
#   index at all three sites; dates differ by a few days); occasion = secondary night 1..3; date = first night of
#   the primary + (secondary - 1) (consecutive nights, README). y (state): 0 not captured, 1 captured Bd-negative,
#   2 captured Bd-positive, 3 captured in primary 23, infection not assessed (source code 1; y_raw keeps it).
#   A site's surveys are the (primary, secondary) cells non-NA for at least one of its frogs (Brindle 46, Tuntable
#   41, Bat Cave 47); every frog has a row at every survey of its site (E4.4: wild-caught adults are at risk from
#   the study's first period), so cells before first capture are y = 0 with y_raw = "NA". surveyEvidence =
#   deposited_matrix. unit_sex; obs_weight_g, obs_svl_mm, obs_bd_load (per primary, measured at capture);
#   obs_ SILO weather on the survey day and over the preceding interval (not derived from the detections).
#   No coordinates in the deposit.
#   Not shipped: ints.csv (derivable from dates), community.csv (infection loads of other species, not a
#   detection survey), the analysis code.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "hollanders_2022_mfleayi_rdms"
dir <- download_dryad("10.5061/dryad.g1jwstqtb", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "190141"),
          setequal(list.files(dir), c("bw.csv", "ch.csv", "community.csv", "covs-int.csv", "covs-surv.csv", "dates.csv",
                                      "ints.csv", "length.csv", "loads.csv", "README.txt", "sex.csv")))
rdm <- function(f) as.matrix(read.csv(file.path(dir, f), header = FALSE, fileEncoding = "UTF-8-BOM"))
n_ind <- c(462L, 136L, 88L); NP <- 23L; NS <- 3L; sites <- c("BR", "TU", "BC")
site_names <- c("Brindle Creek", "Tuntable Creek", "Bat Cave Creek")
chm <- rdm("ch.csv"); stopifnot(dim(chm) == c(462L, 207L), all(chm %in% c(0, 1, 2, NA)))
ch <- array(chm, c(462L, NP, NS, 3L))
stopifnot(identical(unname(chm[, 1 + NP * 1 + NP * NS * 1]), unname(ch[, 1, 2, 2])))   # layout: col = p + 23(s-1) + 69(m-1)
bw <- array(rdm("bw.csv"), c(462L, NP, 3L)); svl <- array(rdm("length.csv"), c(462L, NP, 3L))
ld <- array(rdm("loads.csv"), c(462L, NP, 3L))
sex <- read.csv(file.path(dir, "sex.csv"), fileEncoding = "UTF-8-BOM"); stopifnot(dim(sex) == c(462L, 3L), all(as.matrix(sex) %in% c(0, 1, NA)))
dates <- read.csv(file.path(dir, "dates.csv"), fileEncoding = "UTF-8-BOM", colClasses = "character")
stopifnot(nrow(dates) == NP, identical(names(dates), c("brindle", "tuntable", "batcave")), dates$tuntable[22] == "1/2/20")
dates$tuntable[22] <- "1/2/21"
D <- sapply(dates, function(x) as.IDate(x, format = "%d/%m/%y"))
stopifnot(!anyNA(D), all(apply(D, 2, function(x) all(diff(x) > 0))), min(D) >= as.IDate("2017-08-01"), max(D) <= as.IDate("2021-03-31"))
cs <- read.csv(file.path(dir, "covs-surv.csv"), fileEncoding = "UTF-8-BOM"); stopifnot(nrow(cs) == NP * NS * 3L, !anyNA(cs))
ci <- read.csv(file.path(dir, "covs-int.csv"), fileEncoding = "UTF-8-BOM"); stopifnot(nrow(ci) == NP * 3L, !anyNA(ci))
# no captures in primary 23 are coded infected (not swabbed)
stopifnot(!any(ch[, 23, , ] == 2, na.rm = TRUE), any(ch[, 23, , ] == 1, na.rm = TRUE))

out <- list()
for (m in 1:3) {
  n <- n_ind[m]
  if (n < 462L) stopifnot(all(is.na(ch[(n + 1):462, , , m])))
  a <- ch[seq_len(n), , , m, drop = FALSE]
  sv <- apply(!is.na(a), 2:4, any)[, , 1]
  # each frog: captured at least once; no NA at a surveyed secondary from its first capture on
  for (i in seq_len(n)) {
    r <- a[i, , , 1]; ord <- row(r) * 10L + col(r)              # survey order: primary, then night
    fc <- min(ord[!is.na(r) & r > 0])
    stopifnot(is.finite(fc), !anyNA(r[sv & ord >= fc]), all(is.na(r[!sv])))
  }
  S <- which(sv, arr.ind = TRUE); colnames(S) <- c("period", "occasion")
  g <- CJ(i = seq_len(n), k = seq_len(nrow(S)))
  g[, `:=`(period = S[k, "period"], occasion = S[k, "occasion"])]
  g[, src := a[cbind(i, period, occasion, 1L)]]
  g[, `:=`(unit = sprintf("%s_%03d", sites[m], i), cluster_id = site_names[m],
           y = fifelse(is.na(src), 0L, as.integer(src)), y_raw = fifelse(is.na(src), "NA", as.character(src)))]
  g[period == 23L & src == 1, y := 3L]
  g[, date := format(as.IDate(D[period, m]) + occasion - 1L)]
  g[, `:=`(unit_sex = sex[[m]][i], obs_weight_g = bw[cbind(i, period, m)], obs_svl_mm = svl[cbind(i, period, m)],
           obs_bd_load = ld[cbind(i, period, m)])]
  ri <- g$period + NP * (g$occasion - 1L) + NP * NS * (m - 1L)
  g[, `:=`(obs_temp_max_c = cs$temp.max[ri], obs_temp_min_c = cs$temp.min[ri], obs_vp_hpa = cs$vp[ri], obs_rain_mm = cs$dailyrain[ri])]
  ii <- g$period + NP * (m - 1L)
  g[, `:=`(obs_int_temp_max_c = ci$temp.max[ii], obs_int_temp_min_c = ci$temp.min[ii], obs_int_rain_mm = ci$rain[ii])]
  out[[m]] <- g
  cat(sprintf("  %s: %d frogs, %d surveys in %d primaries\n", site_names[m], n, nrow(S), uniqueN(S[, "period"])))
}
long <- rbindlist(out)
stopifnot(nrow(long) == 462L * 46L + 136L * 41L + 88L * 47L, sum(long$y > 0) == sum(chm > 0, na.rm = TRUE),
          sum(long$y == 3L) == sum(ch[, 23, , ] == 1, na.rm = TRUE))
long[, `:=`(i = NULL, k = NULL, src = NULL, taxon = "MIXFLE")]
long <- order_eco(long)
cat(sprintf("  %d rows, %d captures (%d Bd-positive, %d unswabbed in primary 23)\n", nrow(long), sum(long$y > 0), sum(long$y == 2), sum(long$y == 3)))

taxa <- make_taxa("MIXFLE", "Mixophyes fleayi", vernacularName = "Fleay's barred frog")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "EN"))
periods <- data.table(period = seq_len(NP), period_first_night_brindle = format(as.IDate(D[, 1])),
                      period_first_night_tuntable = format(as.IDate(D[, 2])), period_first_night_batcave = format(as.IDate(D[, 3])))

dataset <- list(
  title = "Robust-design capture histories with Bd infection state for 686 adult Fleay's barred frogs at three creeks in New South Wales, 2017-2021",
  creator = "Hollanders, Matthijs; Grogan, Laura F.; Nock, Catherine J.; McCallum, Hamish I.; Newell, David A.",
  pubDate = "2022", doi = "10.5061/dryad.g1jwstqtb", sourceURL = "https://doi.org/10.5061/dryad.g1jwstqtb",
  citation = "Hollanders, M., Grogan, L. F., Nock, C. J., McCallum, H. I., & Newell, D. A. (2022). Recovered frog populations coexist with endemic Batrachochytrium dendrobatidis despite load-dependent mortality [Dataset]. Dryad. https://doi.org/10.5061/dryad.g1jwstqtb",
  paperDOI = "10.1002/eap.2724",
  abstract = "Mark-recapture of adult Fleay's barred frogs (Mixophyes fleayi, IUCN EN) at Brindle, Tuntable and Bat Cave Creeks in northern New South Wales, Australia, from August 2017 to March 2021: 23 primary occasions of 2-3 consecutive nights, about six weeks apart in the breeding seasons. Each captured frog was swabbed and the swab assayed by qPCR for the amphibian chytrid fungus Batrachochytrium dendrobatidis (Bd), giving an observed infection state per capture; frogs were weighed and measured, and the Bd load is recorded. The authors fitted a multisite robust-design multistate model to ask how Bd infection and load affect survival in these recovered populations.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Night-time capture surveys of creek transects on 2-3 consecutive nights per primary occasion; frogs individually marked, sexed, weighed, measured and swabbed for Bd (qPCR); no swabs in the last primary.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
  responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not captured", `1` = "captured, Bd-negative", `2` = "captured, Bd-positive",
                    `3` = "captured in the last primary (23), not swabbed: infection state not assessed"),
  closure = "closed", closureNote = "occasion = night within a primary occasion (robust design); open between primaries, about six weeks apart",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "none",
  geographicCoverage = "Brindle Creek, Tuntable Creek and Bat Cave Creek, northern New South Wales, Australia (no coordinates deposited; IUCN EN taxon)",
  temporalCoverage = "2017-08/2021-03",
  designNote = "Three populations stacked, with the site in cluster_id and as the unit prefix; the period index is shared, and each site's own primary dates are in __periods and on date. Not every primary was surveyed at every site (Brindle 21, Tuntable 19, Bat Cave 21 primaries), and the number of nights per primary is 1-3.",
  covariateNote = "unit_sex: 0 male, 1 female (NA unknown). obs_weight_g, obs_svl_mm, obs_bd_load (Bd ITS copies per swab, NA when negative or not swabbed): measured at capture in the primary and repeated on each of its nights. obs_temp_max_c, obs_temp_min_c, obs_vp_hpa, obs_rain_mm: SILO interpolated weather on the survey day. obs_int_*: SILO mean maximum and minimum temperature and cumulative rainfall over the interval before the primary.",
  notes = "Every frog has a row at every survey of its site from the study's first primary (E4.4); the deposit's histories start at or near first capture, and those earlier cells are y = 0 with y_raw = 'NA'. The date of the second and third night is the primary's first night plus one or two days (the README: consecutive nights). Tuntable primary 22 is dated 1/2/20 in the deposit, between 28/12/20 and 13/3/21, and is read as 2021-02-01. A survey shows in the deposit only through frogs already marked, so a survey before a site's first capture is invisible: Tuntable primary 1 and Bat Cave primaries 1-2 have dates in dates.csv but no rows (the authors' code treats them as unsurveyed too). A juvenile study at Brindle Creek by the same first author is hollanders_2022_brindle_mfleayi_msdis.",
  notShipped = list(ints = "intervals between primaries in 6-week units: derivable from the dates",
                    community = "community.csv: Bd loads of swabbed frogs of sympatric species, an infection survey without a detection design",
                    code = "the authors' Quarto/NIMBLE code (Zenodo 10.5281/zenodo.6981761)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/hollanders_2022_mfleayi_rdms.R")
stage_dict_row(TABLE,
  description = "Robust-design capture histories of 686 adult Fleay's barred frogs at three creeks in northern New South Wales, 2017-2021, with the Bd infection state per capture, body size, Bd load and survey weather.",
  url = "https://doi.org/10.5061/dryad.g1jwstqtb",
  reference = "Hollanders, M., Grogan, L. F., Nock, C. J., McCallum, H. I., & Newell, D. A. (2022). Recovered frog populations coexist with endemic Batrachochytrium dendrobatidis despite load-dependent mortality. Ecological Applications, 33, e2724.",
  doi_paper = "10.1002/eap.2724", doi_data = "10.5061/dryad.g1jwstqtb",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; array layout from the authors' m2-cmr.qmd (Zenodo); histories padded to the study start; last primary not swabbed (state 3).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Multi-state (disease) robust design capture-recapture",
  sampling_protocol = "hand_capture", design = "Robust design (23 primary occasions x 1-3 nights, three sites)",
  realm = "Freshwater", country = "AUS", coordinates = "None in source",
  notes = "Endangered frog; Bd infection state per capture; three populations as clusters.")
