#!/usr/bin/env Rscript
# Tables: tjornlov_2020_christianso_eider_ld, tjornlov_2020_vlieland_eider_ld
# Source: Dryad doi:10.5061/dryad.97h25b0 (CC0 1.0, as shown on the Dryad page; published
#         2020-09-30). Tjornlov, R., Pradel, R., Choquet, R., Christensen, T.K. & Frederiksen, M.
#         Data from: Consequences of past and present harvest management in a declining flyway
#         population of common eiders.
# Paper:  Tjornlov, R.S. et al. (2019). Ecology and Evolution, doi:10.1002/ece3.5707. Common eider
#         (Somateria mollissima) ringing, recapture and dead recovery in the Baltic-Wadden Sea
#         flyway; MARK live-dead models and an E-SURGE multievent model of cause of death.
# Data:   four files. Step1_Christianso_data_for_duckling_survival.inp: MARK, "LDLD format",
#         "First year is 1973, last year is 1997" (25 years, 50 characters), groups "1: AD
#         FEMALES, 2: DUCKLINGS (used in publication)", 11,192 histories, each with frequency 1 in
#         exactly one group. Step1_Vlieland_data_for_AD_male_survival.inp: LDLD, 1974-2006 (33
#         years, 66 characters), groups "1: AD MALES (used in publication), 2: AD FEMALES, 3:
#         DUCKLINGS of various stages of age", 10,244 histories. Step1_Colonyspecific_capture_
#         recapture_recovery.inp (46 occasions, 11 group columns with no group legend) and
#         Step2_ESURGE_multievent_cause_of__death_with_unknowns.txt (event codes undefined in the
#         deposit) are not built. Quirk: 8 Vlieland histories have two dead recoveries or an
#         encounter after a dead recovery (impossible; dropped, counted).
# Mapping (standard: E9 dead recovery / Burnham live-dead, as moe_2020_hunder_trout_ld): unit =
#   bird (deposit order, C/V prefix); taxon = SOMMOL; period = year (__periods); y = state of the
#   year's LD pair: 0 = 00 neither, 1 = 10 live encounter, 2 = 01 recovered dead, 3 = 11 both;
#   y_raw = the pair. unit_group = the MARK group. Rows (E4.4): adults (caught in the wild) from
#   the study's first year; ducklings (marked at hatch) from their first encounter; to the year
#   of dead recovery, or to the last year. Survey evidence: deposited_matrix (MARK LDLD input).
#   No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/tjornlov_2020_eider_ld.R"
dir <- download_dryad("10.5061/dryad.97h25b0", "tjornlov_2020_eider_ld")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
readinp <- function(pat) {
  f <- list.files(dir, pat, recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
  t <- paste(readLines(f, encoding = "latin1", warn = FALSE), collapse = "\n")
  hdr <- regmatches(t, gregexpr("/\\*.*?\\*/", t))[[1]]
  body <- gsub("/\\*.*?\\*/", "", t)
  recs <- strsplit(trimws(unlist(strsplit(body, ";"))), "\\s+"); recs <- recs[lengths(recs) > 1]
  list(hdr = hdr, ch = sapply(recs, `[`, 1), g = do.call(rbind, lapply(recs, function(r) as.integer(r[-1]))))
}
SET <- list(
  list(table = "tjornlov_2020_christianso_eider_ld", pat = "^Step1_Christians.*duckling_survival\\.inp$", years = 1973:1997, n = 11192L,
       groups = c("adult female", "duckling"), duck = 2L, prefix = "C", nbad = 0L, place = "Christianso, Denmark (Baltic Sea)", iso = "DNK"),
  list(table = "tjornlov_2020_vlieland_eider_ld", pat = "^Step1_Vlieland_data_for_AD_male_survival\\.inp$", years = 1974:2006, n = 10244L,
       groups = c("adult male", "adult female", "duckling"), duck = 3L, prefix = "V", nbad = 8L, place = "Vlieland, the Netherlands (Wadden Sea)", iso = "NLD"))
taxa <- make_taxa("SOMMOL", "Somateria mollissima", vernacularName = "Common eider")
for (S in SET) {
  x <- readinp(S$pat); TY <- length(S$years)
  stopifnot(length(x$ch) == S$n, all(nchar(x$ch) == 2 * TY), all(grepl("^[01]+$", x$ch)), ncol(x$g) == length(S$groups),
            all(rowSums(x$g) == 1), all(x$g %in% 0:1), any(grepl(as.character(S$years[1]), x$hdr)), any(grepl(as.character(S$years[TY]), x$hdr)))
  P <- t(sapply(x$ch, function(s) substring(s, seq(1, 2 * TY, 2), seq(2, 2 * TY, 2)))); dimnames(P) <- NULL
  nD <- rowSums(substr(P, 2, 2) == "1")
  after <- apply(P, 1, function(r) { d <- which(substr(r, 2, 2) == "1"); length(d) > 0 && any(r[seq_len(TY) > d[1]] != "00") })
  bad <- nD > 1 | after
  stopifnot(sum(bad) == S$nbad, all(rowSums(P != "00") > 0))
  grp <- max.col(x$g)
  keep <- which(!bad)
  long <- rbindlist(lapply(keep, function(i) {
    r <- P[i, ]; first <- if (grp[i] == S$duck) which(r != "00")[1] else 1L
    d <- which(substr(r, 2, 2) == "1"); last <- if (length(d)) d[1] else TY
    data.table(unit = sprintf("%s%05d", S$prefix, i), period = first:last, y_raw = r[first:last])
  }))
  long[, `:=`(taxon = "SOMMOL", y = c(`00` = 0L, `10` = 1L, `01` = 2L, `11` = 3L)[y_raw])]
  long <- merge(long, data.table(unit = sprintf("%s%05d", S$prefix, keep), unit_group = S$groups[grp[keep]]), by = "unit")
  long <- order_eco(long)
  stopifnot(!anyNA(long$y), uniqueN(long$unit) == S$n - S$nbad)
  periods <- data.table(period = seq_len(TY), period_year = S$years)
  ng <- table(S$groups[grp[keep]])
  dataset <- list(
    title = sprintf("Live-dead encounter histories of %s common eiders ringed at %s, %d-%d", format(S$n - S$nbad, big.mark = ","), sub(" \\(.*", "", S$place), S$years[1], S$years[TY]),
    creator = "Tjørnløv, Rune S.; Pradel, Roger; Choquet, Rémi; Christensen, Thomas Kjær; Frederiksen, Morten", pubDate = "2020",
    doi = "10.5061/dryad.97h25b0", sourceURL = "https://doi.org/10.5061/dryad.97h25b0",
    citation = "Tjørnløv, R., Pradel, R., Choquet, R., Christensen, T. K., & Frederiksen, M. (2020). Data from: Consequences of past and present harvest management in a declining flyway population of common eiders [Dataset]. Dryad. https://doi.org/10.5061/dryad.97h25b0",
    paperDOI = "10.1002/ece3.5707",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Burnham live-dead (LDLD) histories of common eiders (Somateria mollissima) ringed at %s, %d-%d: %s; per year, whether the bird was encountered alive at the colony and whether it was recovered dead (mostly by hunters) in the following interval. The MARK input of Tjornlov et al.'s harvest analysis.",
                       S$place, S$years[1], S$years[TY], paste(sprintf("%d %ss", as.integer(ng), names(ng)), collapse = ", ")),
    samplingProtocol = "Ringing of breeding adults and ducklings at the colony with annual recapture or resighting at the colony and dead recoveries reported through the ringing scheme (mostly hunting); one live occasion and one recovery interval per year.",
    samplingProtocolCode = "tag_recovery", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "individual",
    closure = "none", closureNote = "open between years (Burnham live-dead model; one live occasion and one recovery interval per year)", occasionKind = "none",
    taxonInclusion = "single",
    stateCodes = list(`0` = "not encountered in year t (live 0, dead 0)", `1` = "encountered alive at the colony in year t (live 1, dead 0)",
                      `2` = "recovered dead in the interval after year t (live 0, dead 1)", `3` = "encountered alive in year t and recovered dead in the following interval (live 1, dead 1)"),
    geographicCoverage = sprintf("%s; recoveries along the Baltic-Wadden Sea flyway; no coordinates deposited", S$place),
    temporalCoverage = sprintf("%d/%d", S$years[1], S$years[TY]),
    notShipped = c(list(colony_file = "Step1_Colonyspecific_capture_recapture_recovery.inp: 11 group columns with no legend in the deposit",
                        esurge_file = "Step2 E-SURGE multievent cause-of-death file: event codes not defined in the deposit"),
                   if (S$nbad) list(impossible_histories = sprintf("%d histories with two dead recoveries or an encounter after a dead recovery", S$nbad)) else list()),
    notes = sprintf("Adults are at risk from %d (caught in the wild); ducklings from their year of ringing (E4.4). Rows end at the year of dead recovery. unit_group is the MARK group. Unit ids follow the deposit order.", S$years[1]))
  ds <- write_table(long, S$table, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(S$table, description = sprintf("Burnham live-dead histories of common eiders ringed at %s, %d-%d (adults and ducklings).", S$place, S$years[1], S$years[TY]),
    url = "https://doi.org/10.5061/dryad.97h25b0",
    reference = "Tjørnløv, R. S., Pradel, R., Choquet, R., Christensen, T. K., & Frederiksen, M. (2019). Consequences of past and present harvest management in a declining flyway population of common eiders Somateria mollissima. Ecology and Evolution.",
    doi_paper = "10.1002/ece3.5707", doi_data = "10.5061/dryad.97h25b0", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Dead-recovery (live-dead) capture-recapture; one of two colony tables.", source_via = "Dryad")
  stage_tag_row(S$table, ds, taxon_group = "Birds", model_family = "Dead recovery (Burnham live-dead)",
    sampling_protocol = "tag_recovery", design = sprintf("Multi-season (%d years)", TY), realm = "Marine",
    country = S$iso, coordinates = "None in source", notes = "Harvested sea duck; recoveries mostly hunting.")
}
