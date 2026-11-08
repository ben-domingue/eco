#!/usr/bin/env Rscript
# Tables: barry_2025_sierra_owls_comm (flammulated and northern pygmy owls, ARU units)
#         barry_2025_sierra_gho_occ   (great horned owl, hexagon-cell units)
# Source: Dryad doi:10.5061/dryad.c866t1gkt, version 394914 (published 2025-09-10); licence as shown on the record:
#         CC0 1.0 (asserted from the API). Barry, J., Wood, C., Jones, G., McGinn, K., Kelly, K., Kramer, A.,
#         Hofstadter, D., Kahl, S., Klinck, H., Kryshak, N., Dotters, B., Roberts, K., Keane, J., Ng, E., Peery, Z.
#         (2025). Data from: Divergent responses of native predators to severe wildfire and biological invasion are
#         mediated by life history. Dryad.
# Paper:  Barry, J. et al. (2025). Divergent responses of native predators to severe wildfire and biological invasion
#         are mediated by life history. Ecological Applications 35(7): e70135. doi:10.1002/eap.70135. Not read; the
#         Dryad methods text (the paper's methods) gives the design used here.
# Data as deposited: README.md; barry_etal_owl_occupancy.R (ubms model code); FLM_data_stacked.csv (1,911 rows),
#   NPO_data_stacked.csv (1,910 rows), GHO_data_stacked.csv (1,000 rows): one row per site x year ("stacked" single-
#   season format) with v1..v11 (weekly detection, 0/1, NA = not surveyed), sp, Site, topo_tr, BOpresence,
#   RemovalTreat, FireTreat, pSevYrs, Year (0 = 2018, 1 = 2021, 2 = 2022, 3 = 2023), SeasonBA, PostRemovalImpact,
#   B1-B3, pSev1-pSev3, PostRemovalpSev1-3, PostRemovalpSevYrs, date.1.1-date.1.11, ARUhours1-ARUhours11.
#   The deposited files disagree with each other (held 2026-11-05, queue/human_review.csv): the NA pattern differs
#   between FLM and NPO in 6 site-year-weeks, ARUhours contradicts the NA pattern in 19 cells (6 FLM, 10 GHO, 3 NPO),
#   NPO lacks one site-year (Site 480, 2018), and GHO "Site" ids are not FLM/NPO "Site" ids.
# AUTHOR-CORRECTED DETECTION FILES. The tables are built from corrected files sent by Joshua Barry (first author) by
#   email on 2026-11-06, which supersede the three deposited csvs: FLM_datas_stacked.csv, NPO_datas_stacked.csv,
#   GHO_datas_stacked.csv, staged at .cache/author_supplied/barry_owls_2026-11-06/ (not public; md5s asserted below).
#   His explanation: (1) typos in recorder recovery dates at about a dozen sites put NAs in the wrong weeks; the
#   corrected files fix them; (2) GHO histories are at the hexagon-cell level (Cell_Unit = integer cell id), FLM and
#   NPO at the ARU level (Cell_Unit = cell.ARU, e.g. 1.1, 1.3), so GHO matches FLM/NPO by cell and year, not by Site;
#   (3) one 2018 barred owl detection was recorded at cell level but not at an ARU (a file-naming error); fixed.
#   The corrected files add the columns Cell_Unit, Yearly (calendar year) and FR11, FR22, FR33, FR12, FR23 and keep
#   every deposited column. Differences from the deposit, asserted below (same Site x Year, 11 weeks):
#     FLM: detection cells NA->0 7, NA->1 1, 1->NA 2, 0->1 1; ARUhours cells changed 12; BOpresence 1->0 at 1 row
#          (Site 364, 2018); rows unchanged (1,911).
#     NPO: detection cells NA->0 8, NA->1 1, 1->NA 1; ARUhours cells changed 11; BOpresence 1->0 at 1 row (Site 364,
#          2018); one row added (Site 480, 2018: Cell_Unit 336.x), 1,911 rows.
#     GHO: detection cells NA->0 16, 0->1 1; ARUhours cells changed 9; BOpresence 1->0 at 1 row (Site 268, 2018);
#          rows unchanged (1,000).
#   The author will update the public Dryad copy; when that version appears, this script should read the public files
#   instead of the author-supplied ones (download_dryad() will pick up the new version; replace the md5 assertions
#   and the diff block with assertions on the new deposit).
#   Verified on the corrected files (assertions): (Cell_Unit, Yearly) is unique and Site <-> Cell_Unit is 1:1; FLM
#   and NPO have the same rows and the same NA pattern at every ARU x year x week, and the same ARUhours; in all three
#   files ARUhours > 0 exactly where a week is scored (0 exactly where NA); GHO cell-years equal FLM/NPO ARU-years
#   aggregated by cell, and a GHO cell-week is scored exactly when at least one ARU in the cell was scored;
#   BOpresence is constant within a cell-year and equal across the three files.
# Design: 265 hexagonal 400-ha cells in Lassen and Plumas National Forests, northern Sierra Nevada, California; two
#   ARUs per cell >= 500 m apart (517 ARU locations over the four years); nightly recording 20:00-08:00 PDT; eleven
#   one-week secondary periods from 7 May (week k = 7 May + 7(k-1) days, through 23 July). 2018: three ~1-week
#   deployments per site; 2021-2023: five weeks continuous. 2019-2020 not surveyed in this analysis (removals ran
#   during the surveys). Detections: BirdNET (custom model) with species x year score thresholds chosen for < 1%
#   false positives per weekly period; for FLM and NPO, predictions at thresholds with 15% (NPO) and 42% (FLM) false
#   positive rates were manually validated. The weekly 0/1 is the authors' call (E9 automated detections).
# Mapping:
#   Two survey designs, two tables (one table per design x response type): FLM and NPO are scored per ARU, GHO per
#   cell (two ARUs pooled), so they do not share units.
#   barry_2025_sierra_owls_comm: unit = ARU (Cell_Unit, "cell.ARU"), cluster_id = cell, taxon FLM / NPO, period =
#     year (1 = 2018, 2 = 2021, 3 = 2022, 4 = 2023), occasion = week 1..11, y = v<week>. One ARU records both species
#     and the NA pattern is identical, so a survey is an ARU-week that is scored and each has a row for both taxa.
#   barry_2025_sierra_gho_occ: unit = cell, taxon GHO, period and occasion as above, y = v<week>.
#   surveyEvidence deposited_matrix: NA = not surveyed, 0 = surveyed, not detected (README); ARUhours agrees.
#   Covariates. The fire and removal covariates were computed over species-specific home-range buffers (FLM 50 ha and
#   NPO 300 ha around the ARU, GHO 700 ha around the cell centre), so in the community table they differ between the
#   two species at the same ARU; they ship once per buffer with the buffer in the name (_50ha used with FLM, _300ha
#   with NPO), each constant at its level. unit_: topo_tr (terrain ruggedness within 390 m of the ARU, standardised
#   as deposited), removal_treat, fire_treat, site (the Site id of the deposited files). period_: bo_presence (barred
#   owl detected at either ARU of the cell that year; an observation of another species, not a model output),
#   season_ba (post-removal period; asserted identical to PostRemovalImpact, which ships once), b1-b3, psev_yrs,
#   psev1-3, post_removal_psev1-3, post_removal_psev_yrs. GHO table: the same names without a buffer suffix (700 ha),
#   plus period_n_arus (ARUs scored in the cell that year, from the FLM file). obs_aruhours: ARUhours as deposited;
#   the README calls it total recording hours, but the values are the natural log of hours rounded to 2 dp (confirmed
#   by J. Barry, email received by 2026-11-08; max 4.43 = ln 84, a full 7 x 12 h week; the GHO cell value is ln of the
#   two ARUs' summed hours), with 0 where the week was not recorded; shipped as deposited, described in notes.
# Not shipped: date.1.1-date.1.11 (scaled week index, k/10, identical on every row); Year code (in __periods);
#   FR11, FR22, FR33, FR12, FR23 (in the corrected files only; interaction terms, left out on J. Barry's advice, email
#   received by 2026-11-08; asserted: FRij = Bj x (pSevi > 0), so they follow from shipped columns); the deposited csvs'
#   superseded values; model code. Western screech and northern saw-whet owls were processed by the authors but not
#   deposited. No coordinates are deposited ("All sensitive location information of forest owls has been omitted").
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE  <- "barry_2025_sierra_owls_comm"
TABLE2 <- "barry_2025_sierra_gho_occ"
SCRIPT <- "data/barry_2025_sierra_owls_comm.R"
dir <- download_dryad("10.5061/dryad.c866t1gkt", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("README.md", "barry_etal_owl_occupancy.R", "FLM_data_stacked.csv",
                                      "GHO_data_stacked.csv", "NPO_data_stacked.csv")))
sp3 <- c("FLM", "GHO", "NPO")
dep_md5 <- c(FLM = "13872bd0d9ccc9e50fd4882e88ecef88", GHO = "1f47ef6ccd649141a270438b23c7307d", NPO = "78d9522d7ae1a1fbbfd79cac7cf63de0")
dep_f <- setNames(file.path(dir, paste0(sp3, "_data_stacked.csv")), sp3)
if (!identical(unname(tools::md5sum(dep_f)), unname(dep_md5[sp3])))
  stop("The Dryad csvs changed: the public copy may now hold the authors' corrections. Switch this script to the public files.")
rd <- readLines(file.path(dir, "README.md"))
stopifnot(any(grepl("NA = not surveyed", rd, fixed = TRUE)), any(grepl("Glaucidium gnoma", rd, fixed = TRUE)),
          any(grepl("0 = 2018; 1 = 2021; 2 = 2022; 3 = 2023", rd, fixed = TRUE)))
dep <- lapply(dep_f, fread)

# --- the authors' corrected files (J. Barry, email 2026-11-06), superseding the deposited csvs ---
AUTH <- file.path(dirname(RAW_DIR), "author_supplied", "barry_owls_2026-11-06")
cor_md5 <- c(FLM = "91c1bfd1a216bb0295e73d73c348c073", GHO = "6d3c72bbccf5bf25606d75bf2ca09407", NPO = "ad61aa4b792b2f5fe71414ec4f8d25ac")
cor_f <- setNames(file.path(AUTH, paste0(sp3, "_datas_stacked.csv")), sp3)
if (!all(file.exists(cor_f)))
  stop("Author-supplied corrected files missing: ", paste(cor_f[!file.exists(cor_f)], collapse = ", "),
       ". They were sent by J. Barry on 2026-11-06 and are not public; ask Ben for them (or, once the Dryad copy is ",
       "updated, switch this script to the public files).")
if (!identical(unname(tools::md5sum(cor_f)), unname(cor_md5[sp3]))) stop("Author-supplied corrected files do not match the md5s of 2026-11-06")
cr <- lapply(cor_f, fread, colClasses = list(character = "Cell_Unit"))

V <- paste0("v", 1:11); H <- paste0("ARUhours", 1:11)
for (s in sp3) {
  x <- cr[[s]]; d <- dep[[s]]
  stopifnot(all(x$sp == s), all(d$sp == s), all(names(d) %in% names(x)),
            setequal(setdiff(names(x), names(d)), c("Cell_Unit", "Yearly", "FR11", "FR22", "FR33", "FR12", "FR23")),
            !anyDuplicated(x[, .(Cell_Unit, Yearly)]), uniqueN(x[, .(Site, Cell_Unit)]) == uniqueN(x$Site),
            uniqueN(x$Site) == uniqueN(x$Cell_Unit), identical(x$Yearly, c(2018L, 2021L, 2022L, 2023L)[x$Year + 1L]),
            all(unlist(x[, ..V]) %in% c(0L, 1L, NA)), all(!is.na(unlist(x[, ..H]))),
            all(sapply(1:11, function(k) all(x[[paste0("date.1.", k)]] == k / 10))),
            identical(x$SeasonBA, x$PostRemovalImpact),
            x[, all(uniqueN(RemovalTreat) == 1, uniqueN(FireTreat) == 1, uniqueN(topo_tr) == 1, uniqueN(Site) == 1), by = Cell_Unit][, all(V1)])
  # FR columns are removal-by-fire interactions: FRij = Bj x (pSevi > 0), recoverable from the shipped columns
  stopifnot(all(sapply(list(c(1, 1), c(2, 2), c(3, 3), c(1, 2), c(2, 3)), function(k)
    all(x[[paste0("FR", k[1], k[2])]] == x[[paste0("B", k[2])]] * (x[[paste0("pSev", k[1])]] > 0)))))
  # ARUhours > 0 exactly where the week is scored
  stopifnot(identical(unname(is.na(as.matrix(x[, ..V]))), unname(as.matrix(x[, ..H]) == 0)))
  stopifnot(if (s == "GHO") all(grepl("^[0-9]+$", x$Cell_Unit)) else all(grepl("^[0-9]+\\.[1-4]$", x$Cell_Unit)))
}
stopifnot(nrow(cr$FLM) == 1911, nrow(cr$NPO) == 1911, nrow(cr$GHO) == 1000,
          nrow(dep$FLM) == 1911, nrow(dep$NPO) == 1910, nrow(dep$GHO) == 1000,
          uniqueN(cr$FLM$Cell_Unit) == 517, uniqueN(cr$GHO$Cell_Unit) == 265,
          max(cr$FLM[, ..H]) == 4.43)                                  # ln(84): a full week of 12-h nights

# --- deposited vs corrected: every difference, counted ---
wk <- function(x) melt(x[, c("Site", "Year", V, H), with = FALSE], id.vars = c("Site", "Year"),
                       measure.vars = list(V, H), value.name = c("v", "h"), variable.name = "week")
lab <- function(v) fifelse(is.na(v), "NA", as.character(v))
diff_counts <- lapply(setNames(sp3, sp3), function(s) {
  m <- merge(wk(dep[[s]]), wk(cr[[s]]), by = c("Site", "Year", "week"))
  m <- m[lab(v.x) != lab(v.y), .N, by = .(tr = paste0(lab(v.x), "->", lab(v.y)))]
  list(v = setNames(m$N, m$tr)[order(m$tr)],
       h = merge(wk(dep[[s]]), wk(cr[[s]]), by = c("Site", "Year", "week"))[h.x != h.y, .N],
       bo = merge(dep[[s]], cr[[s]], by = c("Site", "Year"))[BOpresence.x != BOpresence.y, .(Site, Year, BOpresence.x, BOpresence.y)],
       added = fsetdiff(cr[[s]][, .(Site, Year)], dep[[s]][, .(Site, Year)]),
       dropped = fsetdiff(dep[[s]][, .(Site, Year)], cr[[s]][, .(Site, Year)]))
})
srt <- function(v) v[order(names(v))]
stopifnot(identical(diff_counts$FLM$v, srt(c("0->1" = 1L, "1->NA" = 2L, "NA->0" = 7L, "NA->1" = 1L))),
          identical(diff_counts$NPO$v, srt(c("1->NA" = 1L, "NA->0" = 8L, "NA->1" = 1L))),
          identical(diff_counts$GHO$v, srt(c("0->1" = 1L, "NA->0" = 16L))),
          diff_counts$FLM$h == 12, diff_counts$NPO$h == 11, diff_counts$GHO$h == 9,
          identical(diff_counts$FLM$bo[, c(Site, Year, BOpresence.x, BOpresence.y)], c(364L, 0L, 1L, 0L)),
          identical(diff_counts$NPO$bo[, c(Site, Year, BOpresence.x, BOpresence.y)], c(364L, 0L, 1L, 0L)),
          identical(diff_counts$GHO$bo[, c(Site, Year, BOpresence.x, BOpresence.y)], c(268L, 0L, 1L, 0L)),
          nrow(diff_counts$FLM$added) == 0, nrow(diff_counts$GHO$added) == 0,
          identical(unlist(diff_counts$NPO$added), c(Site = 480L, Year = 0L)),
          all(sapply(diff_counts, function(z) nrow(z$dropped) == 0)))
# the deposited files' own inconsistencies, which the corrections remove
stopifnot(sapply(dep, function(d) sum(is.na(as.matrix(d[, ..V])) != (as.matrix(d[, ..H]) == 0))) == c(FLM = 6, GHO = 10, NPO = 3))

# --- the corrected files agree with each other ---
FL <- cr$FLM; N <- cr$NPO; G <- cr$GHO
setkey(FL, Cell_Unit, Yearly); setkey(N, Cell_Unit, Yearly)
same_cols <- c("Site", "Year", "topo_tr", "BOpresence", H)
stopifnot(identical(FL[, .(Cell_Unit, Yearly)], N[, .(Cell_Unit, Yearly)]),
          identical(is.na(as.matrix(FL[, ..V])), is.na(as.matrix(N[, ..V]))),          # same NA pattern (shared ARU)
          all(sapply(same_cols, function(c) identical(FL[[c]], N[[c]]))))
FL[, cell := sub("\\..*$", "", Cell_Unit)]
Fc <- FL[, c(.(n_arus = .N, bo = uniqueN(BOpresence), BOpresence = BOpresence[1]),
            lapply(.SD, function(v) any(!is.na(v)))), by = .(cell, Yearly), .SDcols = V]
stopifnot(all(Fc$bo == 1), !any(rowSums(!is.na(as.matrix(FL[, ..V]))) == 0))   # every ARU-year row has a scored week, so n_arus counts ARUs that recorded
Gk <- G[, c(list(cell = Cell_Unit, Yearly = Yearly, BOpresence = BOpresence), lapply(.SD, function(v) !is.na(v))), .SDcols = V]
cc <- merge(Fc, Gk, by = c("cell", "Yearly"), all = TRUE)
stopifnot(nrow(cc) == 1000, !anyNA(cc$n_arus), !anyNA(cc$BOpresence.y),               # GHO cell-years = FLM cell-years
          identical(cc$BOpresence.x, cc$BOpresence.y),
          all(sapply(V, function(v) identical(cc[[paste0(v, ".x")]], cc[[paste0(v, ".y")]]))))  # cell scored iff any ARU scored

# --- long tables ---
years <- c(2018L, 2021L, 2022L, 2023L)
to_long <- function(x) {
  L <- melt(x, id.vars = setdiff(names(x), c(V, H)), measure.vars = list(V, H), value.name = c("y", "aruhours"),
            variable.name = "occasion")
  L[, occasion := as.integer(occasion)][, period := match(Yearly, years)]
  L[!is.na(y)]
}
pcov <- c(season_ba = "SeasonBA", b1 = "B1", b2 = "B2", b3 = "B3", psev_yrs = "pSevYrs", psev1 = "pSev1", psev2 = "pSev2",
          psev3 = "pSev3", post_removal_psev1 = "PostRemovalpSev1", post_removal_psev2 = "PostRemovalpSev2",
          post_removal_psev3 = "PostRemovalpSev3", post_removal_psev_yrs = "PostRemovalpSevYrs")
ucov <- c(removal_treat = "RemovalTreat", fire_treat = "FireTreat")
buf_cols <- function(L, buf) {
  out <- L[, c(ucov, pcov), with = FALSE]
  setnames(out, c(paste0("unit_", names(ucov), "_", buf), paste0("period_", names(pcov), "_", buf)))
  out
}
LF <- to_long(FL); LN <- to_long(N)
setkey(LF, Cell_Unit, period, occasion); setkey(LN, Cell_Unit, period, occasion)
stopifnot(identical(LF[, .(Cell_Unit, period, occasion)], LN[, .(Cell_Unit, period, occasion)]))
base <- LF[, .(unit = Cell_Unit, period, occasion, cluster_id = cell, unit_site = Site, unit_topo_tr = topo_tr,
               period_bo_presence = BOpresence, obs_aruhours = aruhours)]
wide <- cbind(base, FLM = LF$y, NPO = LN$y, buf_cols(LF, "50ha"), buf_cols(LN, "300ha"))
long <- melt(wide, measure.vars = c("FLM", "NPO"), variable.name = "taxon", value.name = "y", variable.factor = FALSE)
long[, y := as.integer(y)]
n_surveys <- sum(!is.na(as.matrix(FL[, ..V])))
stopifnot(nrow(long) == 2 * n_surveys, uniqueN(long$unit) == 517, uniqueN(long$cluster_id) == 265,
          long[taxon == "FLM", sum(y)] == sum(as.matrix(FL[, ..V]), na.rm = TRUE),
          long[taxon == "NPO", sum(y)] == sum(as.matrix(N[, ..V]), na.rm = TRUE))

LG <- to_long(G)
LG <- merge(LG, Fc[, .(Cell_Unit = cell, Yearly, period_n_arus = n_arus)], by = c("Cell_Unit", "Yearly"))
gcols <- c(setNames(paste0("unit_", names(ucov)), ucov), setNames(paste0("period_", names(pcov)), pcov))
setnames(LG, names(gcols), gcols)
long2 <- LG[, c(list(unit = Cell_Unit, taxon = "GHO", y = as.integer(y), period = period, occasion = occasion,
                     unit_topo_tr = topo_tr), .SD, list(period_bo_presence = BOpresence, period_n_arus = period_n_arus,
                     obs_aruhours = aruhours)), .SDcols = unname(gcols)]
stopifnot(nrow(long2) == sum(!is.na(as.matrix(G[, ..V]))), uniqueN(long2$unit) == 265,
          sum(long2$y) == sum(as.matrix(G[, ..V]), na.rm = TRUE))

# --- side tables ---
taxa <- make_taxa(c("FLM", "NPO"), c("Psiloscops flammeolus", "Glaucidium gnoma"),
                  vernacularName = c("Flammulated owl", "Northern pygmy owl"))
taxa[taxon == "NPO", taxonRemarks := "Glaucidium gnoma as in the deposited README; the Dryad abstract writes Glaucidium californicum."]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
taxa2 <- make_taxa("GHO", "Bubo virginianus", vernacularName = "Great horned owl")
taxa2[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(c(taxa$taxon_iucnCategory, taxa2$taxon_iucnCategory) %in% c("CR", "EN", "VU")))
periods <- data.table(period = 1:4, year = years, source_year_code = 0:3,
                      deployment = c("three ~1-week deployments per ARU (mean 26 days apart)", rep("five weeks continuous", 3)))

# --- metadata ---
creator <- "Barry, Joshua; Wood, Connor; Jones, Gavin; McGinn, Kate; Kelly, Kevin; Kramer, Anu; Hofstadter, Daniel; Kahl, Stefan; Klinck, Holger; Kryshak, Nicholas; Dotters, Brian; Roberts, Kevin; Keane, John; Ng, Elizabeth; Peery, Zach"
citation <- "Barry, J., Wood, C., Jones, G., McGinn, K., Kelly, K., Kramer, A., Hofstadter, D., Kahl, S., Klinck, H., Kryshak, N., Dotters, B., Roberts, K., Keane, J., Ng, E., Peery, Z. (2025). Data from: Divergent responses of native predators to severe wildfire and biological invasion are mediated by life history. Dryad. https://doi.org/10.5061/dryad.c866t1gkt"
provenance <- "Detection histories, ARUhours and BOpresence are from the authors' corrected files (FLM/NPO/GHO_datas_stacked.csv), sent by J. Barry by email on 2026-11-06, which supersede the deposited csvs of Dryad version 394914: typos in recorder recovery dates at about a dozen sites had put not-surveyed weeks in the wrong place, and one 2018 barred owl detection was assigned to the wrong ARU. Changes against the deposit (same Site x Year x week): FLM 11 detection cells (NA->0 7, NA->1 1, 1->NA 2, 0->1 1), 12 ARUhours cells, BOpresence 1->0 at one site-year; NPO 10 detection cells (NA->0 8, NA->1 1, 1->NA 1), 11 ARUhours cells, the same BOpresence change, and one site-year the deposit lacked (Site 480, 2018); GHO 17 detection cells (NA->0 16, 0->1 1), 9 ARUhours cells, BOpresence 1->0 at one cell-year. The authors will update the public copy; the table will be rebuilt from it then."
common <- list(
  creator = creator, pubDate = "2025", doi = "10.5061/dryad.c866t1gkt", sourceURL = "https://doi.org/10.5061/dryad.c866t1gkt",
  citation = citation, paperDOI = "10.1002/eap.70135",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocolCode = "acoustic", responseType = "detection", unitKind = "site", surveyEvidence = "deposited_matrix",
  closure = "closed", occasionKind = "time", temporalCoverage = "2018/2023",
  geographicCoverage = "Lassen and Plumas National Forests (and adjacent private land), northern Sierra Nevada, California, USA; > 6,000 km2; no coordinates deposited",
  closureNote = "occasion = one-week secondary period k (7 May + 7(k-1) days, k = 1..11, to 23 July); period = survey year (2018, 2021, 2022, 2023: 2019-2020 not used because barred owl removals overlapped the surveys). The authors assume closure within a year and fit stacked single-season models.")
nsc <- list(
  author_corrections = "The deposited FLM/NPO/GHO_data_stacked.csv values superseded by the authors' corrected files (see notes; differences counted in the script).",
  date_covariates = "date.1.1-date.1.11: a scaled week index (k/10), identical on every row; occasion carries it.",
  year_code = "Year (0-3): in __periods as source_year_code.",
  FR_columns = "FR11, FR22, FR33, FR12, FR23: present only in the corrected files. Removal-by-fire interaction terms, left out on the first author's advice (email); each is FRij = Bj x (pSevi > 0) (asserted), so it can be recomputed from period_b1-b3 and period_psev1-3.",
  other_owls = "Western screech owl and northern saw-whet owl were processed but excluded by the authors for few detections; not deposited.",
  model_code = "barry_etal_owl_occupancy.R (ubms model code).")
aru_note <- "obs_aruhours is ARUhours as deposited: the README calls it total recording hours in the week, but the values are the natural log of the hours (confirmed by the first author by email), rounded to 2 dp (4.43 = ln 84, a full week of 12-hour nights), and 0 where the week was not recorded; exp(obs_aruhours) recovers the hours."
cov_note <- "Fire and removal covariates are computed over species-specific home-range buffers (flammulated owl 50 ha and northern pygmy owl 300 ha around the ARU; great horned owl 700 ha around the cell centre). unit_removal_treat: buffer overlaps a barred owl removal home range (2,004 ha around each removal); unit_fire_treat: any high-severity fire (MTBS) in the buffer; period_psev_yrs: proportion of the buffer burned at high severity, any year post-fire; period_psev1-3: that proportion in year 1, 2, 3 after the fire (0 otherwise); period_season_ba: removal site in its post-removal years (the deposit's SeasonBA, identical to PostRemovalImpact); period_b1-b3: removal site 1, 2, 3+ years after removal; period_post_removal_psev1-3, period_post_removal_psev_yrs: removal followed by high-severity fire, by years since fire and for all post-fire years. period_bo_presence: a barred owl detected at either ARU of the cell that year (the authors' acoustic survey; a detection covariate in their models). unit_topo_tr: terrain ruggedness within 390 m of the ARU (cell centre for GHO), standardised as deposited."
det_note <- "y is the authors' weekly detection call from BirdNET (custom model) at species x year score thresholds chosen for < 1% false positives per week"

dataset <- c(list(
  title = "Weekly ARU detections of flammulated and northern pygmy owls at 517 recorder sites in 265 cells, northern Sierra Nevada, 2018 and 2021-2023",
  abstract = "Passive acoustic monitoring of 265 hexagonal 400-ha cells (two ARUs per cell) in the northern Sierra Nevada, California, before and after the 2020 North Complex and 2021 Dixie fires and a 2018-2022 barred owl lethal-removal experiment. Weekly detection histories (11 weeks, May to July) for flammulated owl and northern pygmy owl at each ARU, with fire-severity, removal-treatment and barred owl covariates."),
  common, list(
  samplingProtocol = "Autonomous recording units (two per 400-ha hexagonal cell, >= 500 m apart) recorded nightly 20:00-08:00 from early May to late July; audio scored with BirdNET at species x year thresholds for < 1% false positives per week, with predictions at lower thresholds manually validated for these two species; a survey is an ARU-week with recording.",
  taxonInclusion = "target",
  surveyEvidenceNote = "v1-v11: NA = not surveyed (no recording that week), 0/1 = surveyed; ARUhours is > 0 exactly where a week is scored, and the two species share the NA pattern at every ARU-week (asserted on the corrected files).",
  notShipped = c(nsc, list(great_horned_owl = "Great horned owl histories are at the cell level (two ARUs pooled), a different unit: they ship as barry_2025_sierra_gho_occ.")),
  notes = paste0(det_note, "; for these two species, predictions at thresholds with 15% (pygmy owl) and 42% (flammulated owl) false-positive rates were manually validated. ",
                 provenance, " ", aru_note, " ", cov_note, " Covariates suffixed _50ha belong with taxon FLM and _300ha with NPO; each is constant at its level. unit_site is the Site id of the deposited files. Sibling table: barry_2025_sierra_gho_occ (great horned owl, cell units).")))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)

dataset2 <- c(list(
  title = "Weekly ARU detections of great horned owl in 265 hexagonal cells, northern Sierra Nevada, 2018 and 2021-2023",
  abstract = "Passive acoustic monitoring of 265 hexagonal 400-ha cells (two ARUs per cell) in the northern Sierra Nevada, California, before and after the 2020 North Complex and 2021 Dixie fires and a 2018-2022 barred owl lethal-removal experiment. Weekly detection histories (11 weeks, May to July) for great horned owl per cell, the two ARUs pooled, with fire-severity, removal-treatment and barred owl covariates."),
  common, list(
  samplingProtocol = "Autonomous recording units (two per 400-ha hexagonal cell, >= 500 m apart) recorded nightly 20:00-08:00 from early May to late July; audio scored with BirdNET at species x year thresholds for < 1% false positives per week; a survey is a cell-week with recording at either ARU, the two ARUs pooled.",
  taxonInclusion = "single",
  surveyEvidenceNote = "v1-v11: NA = not surveyed, 0/1 = surveyed; ARUhours is > 0 exactly where a week is scored, and a cell-week is scored exactly when at least one of its ARUs is scored in the flammulated/pygmy owl files (asserted on the corrected files).",
  notShipped = c(nsc, list(small_owls = "Flammulated and northern pygmy owl histories are at the ARU level, a different unit: they ship as barry_2025_sierra_owls_comm.")),
  notes = paste0(det_note, ". ", provenance, " ", aru_note, " For this table it is ln of the two ARUs' summed hours. ", cov_note,
                 " Covariates here use the 700-ha buffer. period_n_arus: ARUs of the cell with any recording that year (from the corrected FLM file). The deposited GHO Site id is the cell id (Cell_Unit), not the Site id of the FLM/NPO files. Sibling table: barry_2025_sierra_owls_comm (flammulated and northern pygmy owls, ARU units).")))
ds2 <- write_table(long2, TABLE2, dataset2, taxa = taxa2, periods = periods, script = SCRIPT)

ref <- "Barry, J., Wood, C., Jones, G., McGinn, K., Kelly, K., Kramer, A., Hofstadter, D., Kahl, S., Klinck, H., Kryshak, N., Dotters, B., Roberts, K., Keane, J., Ng, E., Peery, Z. (2025). Divergent responses of native predators to severe wildfire and biological invasion are mediated by life history. Ecological Applications 35(7): e70135."
dnote <- "Built from the authors' corrected detection files (J. Barry, email 2026-11-06), superseding the Dryad csvs; rebuild from Dryad when the public copy is updated."
stage_dict_row(TABLE,
  description = "Weekly ARU detections (BirdNET, manually validated) of flammulated and northern pygmy owls at 517 recorder sites in 265 cells across fire and barred owl removal treatments, northern Sierra Nevada, 2018 and 2021-2023.",
  url = "https://doi.org/10.5061/dryad.c866t1gkt", reference = ref, doi_paper = "10.1002/eap.70135",
  doi_data = "10.5061/dryad.c866t1gkt", original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = dnote, source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (stacked single-season)", sampling_protocol = "acoustic",
  design = "Multi-season (4 years, 11 weekly occasions)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Wildfire and barred owl removal BACI; automated classifier with manual validation; author-corrected files.")
stage_dict_row(TABLE2,
  description = "Weekly ARU detections (BirdNET) of great horned owl in 265 hexagonal cells (two ARUs pooled) across fire and barred owl removal treatments, northern Sierra Nevada, 2018 and 2021-2023.",
  url = "https://doi.org/10.5061/dryad.c866t1gkt", reference = ref, doi_paper = "10.1002/eap.70135",
  doi_data = "10.5061/dryad.c866t1gkt", original_license = "CC0 1.0", derived_license = "CC0 1.0", notes = dnote, source_via = "Dryad")
stage_tag_row(TABLE2, ds2, taxon_group = "Birds", model_family = "Single-season occupancy (stacked)", sampling_protocol = "acoustic",
  design = "Multi-season (4 years, 11 weekly occasions)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Wildfire and barred owl removal BACI; automated classifier; author-corrected files.")
