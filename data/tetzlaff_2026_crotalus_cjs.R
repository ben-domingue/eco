#!/usr/bin/env Rscript
# Table:  tetzlaff_2026_crotalus_cjs
# Source: Dryad doi:10.5061/dryad.41ns1rnsk (CC0 1.0 as shown on the dataset JSON), version
#   419034 (published 2026-01-14). Tetzlaff, S. J., Hileman, E. T., Simon, M. G., Schuett,
#   G. W., Davis, M. A. & Brown, W. S. Data from: Population dynamics of a long-lived
#   pitviper inferred from capture-recapture data spanning four decades.
# Paper:  Tetzlaff, S. J., Hileman, E. T., et al. (2026). Population dynamics of a long-lived
#         pitviper inferred from capture-recapture data spanning four decades. Ecosphere,
#         doi:10.1002/ecs2.70560 (Dryad primary_article).
# Data:   one Program MARK .inp file (CRLF) with a free-text preamble, then:
#           lines 7-33   the 25 inter-sampling intervals in years (unequal: 1983 -> 1985 is 1.99);
#           lines 35-47  12 groups = 6 dens (BIC, DL, EB, FP, HP, LA) x 2 colour morphs (B black,
#                        Y yellow);
#           lines 49-111 two interval-level population covariates (mean adult female mass,
#                        precipitation 11 years earlier), real scale (24 intervals, 1983-1985
#                        missing) and standardised (25 intervals);
#           then 707 lines /*<id>*/<26-character history> <12 group frequencies>;
#         26 occasions = the sampling years 1983, 1985-1988, 1992-1994, 1996, 1998, 2000, 2002,
#         2004-2009, 2011-2016, 2018, 2019; adult females >= 500 g at dens in the southeastern
#         Adirondack Mountains, New York. 698 snakes carry a 1 in exactly one group and nine carry
#         a 1 in two den groups of the same morph (recorded at two dens); no history has a negative
#         frequency (no losses on capture coded).
#
# Mapping (standard section 3.4, CJS): unit = snake id, taxon = CROHOR, period = sampling year
#   index 1..26 (calendar year in __periods), y = 0/1, no `occasion`. Rows before first capture
#   are kept as 0 (E4); the paper fits Pradel's model, which uses the whole history.
#   Survey evidence: the deposited matrix (every listed year was sampled; the history has a
#   character for each). unit_den = the den group(s), ";"-joined for the nine snakes recorded at
#   two dens (MARK counts those snakes once in each group); unit_morph = colour morph (asserted
#   identical across a snake's groups). The interval lengths and the two population-level
#   covariates go in __periods as columns of the period that starts the interval
#   (interval_to_next_yr, popmass_g, precip_11yr_mm); the real-scale covariates lack 1983-1985 and
#   are NA there; the standardised versions are not shipped (a transform of the same values).
#   No coordinates are deposited (the dens of a threatened snake are not located).
#   Not shipped: the standardised covariates (derivable), the den x morph indicator layout.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "tetzlaff_2026_crotalus_cjs"
dir <- download_dryad("10.5061/dryad.41ns1rnsk", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "C_horridus__NY_USA_1983-2019_F.inp")
stopifnot(file.exists(f))
L <- sub("\r$", "", readLines(f, warn = FALSE, encoding = "latin1"))

years <- c(1983L, 1985:1988, 1992:1994, 1996L, 1998L, 2000L, 2002L, 2004:2009, 2011:2016, 2018L, 2019L)
Tn <- length(years); stopifnot(Tn == 26L)

# --- intervals (lines like "1983-1985<TAB>1.987671233"), first block only
iv_lines <- grep("^[0-9]{4}-[0-9]{4}\t[0-9.]+$", L, value = TRUE)
iv <- data.table(from = as.integer(substr(iv_lines, 1, 4)), to = as.integer(substr(iv_lines, 6, 9)),
                 interval = as.numeric(sub(".*\t", "", iv_lines)))
stopifnot(nrow(iv) == Tn - 1L, identical(iv$from, years[-Tn]), identical(iv$to, years[-1]))

# --- real-scale covariates block: "1985-1986\t\t670\t\t\t1057.96"
cv_start <- grep("^50 population-level temporal covariates on real scale", L)
cv_end <- grep("^50 population-level temporal covariates, standardized", L)
stopifnot(length(cv_start) == 1, length(cv_end) == 1)
cv_lines <- grep("^[0-9]{4}-[0-9]{4}\t", L[cv_start:cv_end], value = TRUE)
cv <- rbindlist(lapply(strsplit(cv_lines, "\t+"), function(x)
  data.table(from = as.integer(substr(x[1], 1, 4)), popmass_g = as.numeric(x[2]), precip_11yr_mm = as.numeric(x[3]))))
stopifnot(nrow(cv) == 24L, identical(cv$from, years[2:(Tn - 1)]))

# --- groups
grp <- c("BIC_B", "BIC_Y", "DL_B", "DL_Y", "EB_B", "EB_Y", "FP_B", "FP_Y", "HP_B", "HP_Y", "LA_B", "LA_Y")
for (i in seq_along(grp)) stopifnot(any(grepl(sprintf("^%d\\. %s ", i, grp[i]), L)))

# --- histories
h <- grep("^/\\*[0-9]+[A-Za-z]*\\*/", L, value = TRUE)
m <- regmatches(h, regexec("^/\\*([0-9]+[A-Za-z]*)\\*/([01]{26}) ((?:[01] ){11}[01]);$", h, perl = TRUE))
stopifnot(length(h) == 707L, all(lengths(m) == 4L))
id <- sapply(m, `[`, 2); stopifnot(!anyDuplicated(id))
CH <- t(sapply(strsplit(sapply(m, `[`, 3), ""), as.integer)); stopifnot(dim(CH) == c(707L, Tn))
G <- t(sapply(strsplit(sapply(m, `[`, 4), " "), as.integer)); stopifnot(dim(G) == c(707L, 12L))
stopifnot(all(rowSums(CH) >= 1L))                       # every snake was caught at least once
ng <- rowSums(G)
stopifnot(sum(ng == 1L) == 698L, sum(ng == 2L) == 9L, sum(ng == 0L) == 0L)
den <- sapply(seq_len(nrow(G)), function(i) paste(sub("_.$", "", grp[G[i, ] == 1L]), collapse = ";"))
morph <- sapply(seq_len(nrow(G)), function(i) unique(sub("^.*_", "", grp[G[i, ] == 1L])))
stopifnot(is.character(morph), length(morph) == 707L)   # one morph per snake, even when two dens
cat(sprintf("  707 snakes, %d detections, 9 recorded at two dens; morphs: %s\n", sum(CH),
            paste(names(table(morph)), table(morph), collapse = ", ")))

covs <- data.frame(unit_den = den, unit_morph = ifelse(morph == "B", "black", "yellow"))
long <- array_to_eco(CH, taxon = "CROHOR", site_ids = id, site_covs = covs, period = seq_len(Tn))
long[, occasion := NULL]
stopifnot(nrow(long) == 707L * Tn, sum(long$y) == sum(CH))

taxa <- make_taxa("CROHOR", "Crotalus horridus", vernacularName = "Timber Rattlesnake")
periods <- data.table(period = seq_len(Tn), year = years)
periods[iv, on = .(year = from), interval_to_next_yr := i.interval]
periods[cv, on = .(year = from), `:=`(popmass_g = i.popmass_g, precip_11yr_mm = i.precip_11yr_mm)]
periods[, note := "annual den survey season; interval_to_next_yr as deposited (MARK time intervals); popmass_g = mean adult female mass over the interval starting this year; precip_11yr_mm = precipitation 11 years before"]

dataset <- list(
  title = "Capture histories of 707 adult female timber rattlesnakes over 26 sampling years at six dens, Adirondack Mountains, New York, 1983-2019",
  creator = "Tetzlaff, Sasha J.; Hileman, Eric T.; Simon, Matthew G.; Schuett, Gordon W.; Davis, Mark A.; Brown, William S.",
  pubDate = "2026", doi = "10.5061/dryad.41ns1rnsk", sourceURL = "https://doi.org/10.5061/dryad.41ns1rnsk",
  citation = "Tetzlaff, S. J., Hileman, E. T., Simon, M. G., Schuett, G. W., Davis, M. A., & Brown, W. S. (2026). Data from: Population dynamics of a long-lived pitviper inferred from capture-recapture data spanning four decades [Dataset]. Dryad. https://doi.org/10.5061/dryad.41ns1rnsk",
  paperDOI = "10.1002/ecs2.70560",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-recapture histories of adult female Crotalus horridus (>= 500 g) at six dens in the southeastern Adirondack Mountains, New York, over 26 sampling years between 1983 and 2019, deposited as a Program MARK input file for Pradel's survival and recruitment model with den x colour-morph groups, unequal interval lengths, and two population-level annual covariates.",
  samplingProtocol = "Den-based hand capture and individual marking of adult females during the active season; one occasion per sampling year (Program MARK input, 26 occasions with unequal intervals).",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "period (one occasion per sampling year; survival and recruitment between years)",
  lossesOnCapture = "none coded (no negative frequencies in the deposit)",
  geographicCoverage = "southeastern Adirondack Mountains, New York, USA (den locations not deposited)",
  temporalCoverage = "1983/2019",
  coordinatesCoarsened = NA,
  covariateNote = "unit_den lists both dens for the nine snakes recorded at two (MARK counts them once in each den group); __periods carries the deposited interval lengths and the two population-level covariates on the real scale (NA for 1983-1985 and for the last year).",
  notShipped = list(standardised_covariates = "the 2*SD-standardised versions of popmass and precipitation (a transform of the shipped values)",
                    group_layout = "the 12-column den x morph frequency layout (replaced by unit_den and unit_morph)"),
  notes = "Sampling years are unequally spaced (gaps of 2 to 4 years); use __periods$interval_to_next_yr as MARK time intervals. Rows before first capture are kept as 0 (E4); drop them for CJS conditioning. Fit in the paper is Pradel's time-symmetric model.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/tetzlaff_2026_crotalus_cjs.R")

stage_dict_row(TABLE,
  description = "Annual capture histories of 707 adult female timber rattlesnakes (Crotalus horridus) at six dens in the southeastern Adirondacks, New York, over 26 sampling years 1983-2019 (unequal intervals), with den and colour morph per snake and two population-level annual covariates in __periods.",
  url = "https://doi.org/10.5061/dryad.41ns1rnsk",
  reference = "Tetzlaff, S. J., Hileman, E. T., Simon, M. G., Schuett, G. W., Davis, M. A., & Brown, W. S. (2026). Population dynamics of a long-lived pitviper inferred from capture-recapture data spanning four decades. Ecosphere.",
  doi_paper = "10.1002/ecs2.70560", doi_data = "10.5061/dryad.41ns1rnsk",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First reptile capture-recapture table. MARK .inp with den x morph groups; nine snakes recorded at two dens kept as one unit with both dens listed. Unequal sampling intervals in __periods.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-session (26 sampling years, unequal intervals)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Individuals as unit; adult females only; Pradel model in the paper.")
