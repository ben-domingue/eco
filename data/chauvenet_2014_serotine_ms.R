#!/usr/bin/env Rscript
# Tables: chauvenet_2014_crundale_serotine_ms, chauvenet_2014_hollingbury_serotine_ms
# Source: Dryad, doi:10.5061/dryad.6kp2j, version 24986 (published 2014-09-20), licence CC0 1.0 as shown on the Dryad
#         dataset page (asserted from the dataset JSON). Chauvenet, A. L. M., Hutson, A. M., Smith, G. C. & Aegerter, J. N.
# Paper:  Chauvenet, A. L. M., Hutson, A. M., Smith, G. C. & Aegerter, J. N. (2014). Demographic variation in the U.K.
#         serotine bat: filling gaps in knowledge for management. Ecology and Evolution 4(19), 3820-3829,
#         doi:10.1002/ece3.1174 (open access; read from Europe PMC PMC4301045). Methods, "Study sites and field
#         methodology": two maternity roosts in south-east England, Hollingbury (Brighton, East Sussex; a ringing study)
#         and Crundale (Kent; the Kent bat group), annual or ad hoc visits (usually twice between May and August, or
#         once in August), 1987-2011, with missing years (2 at Crundale, 11 at Hollingbury); bats caught by hand in the
#         roost or with hand nets / harp traps outside, ringed. "Analysis": males excluded (0 / 1 male recaptures);
#         each capture assigned to one of three stages, juvenile (J), immature/unknown (U: adult-looking, breeding not
#         recorded or not determinable) and breeder (B); multistate CJS in MARK with uneven intervals, then POPAN.
# Data:   CJS analysis- Crundale.zip / CJS analysis- Hollingbury.zip: <site>_MS_noNnomale.inp, MARK multistate
#           histories (J / U / B / 0), one row per female, frequency 1; 23 annual occasions at Crundale, 12 at
#           Hollingbury; the MARK .DBF / .FPT project files. POPAN analysis.zip: <site>_popan_nomale.inp (the same
#           histories as 0/1: rebuilt exactly from the MS files and asserted, so not shipped) and the RMark scripts,
#           whose process.data() calls give the occasion years: Crundale begin.time 1987, intervals
#           1,1,1,1,2,1,2,1,...,1 (1987-2011 without 1992 and 1995); Hollingbury begin.time 1989, intervals
#           7,1,2,3,1,1,1,1,1,3,1 (1989, 1996, 1997, 1999, 2002-2007, 2010, 2011). IBM R script (simulation).
# Mapping (multi-state CJS, one table per population as deposited; ruling #20 / #31): unit = the female (row of the
#   site's file), taxon = EPTSER, period = occasion year index (__periods: year), y = state code 0 not caught,
#   1 juvenile (J), 2 immature/unknown (U), 3 breeder (B); y_raw = the letter. At-risk span (E4.4): a female first
#   caught as a juvenile (marked as young of the year) has rows from that period; one first caught as U or B
#   (wild, unknown age) from the study's first period. surveyEvidence = deposited_matrix (each history character is
#   a capture year of the site; MARK histories have no missing cells). No coordinates in the deposit.
# Not shipped: the POPAN 0/1 files (a recode of the MS files, asserted); MARK project files and model output; the
#   IBM simulation script; males (excluded by the authors, not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/chauvenet_2014_serotine_ms.R"
dir <- download_dryad("10.5061/dryad.6kp2j", "chauvenet_2014_serotine_ms")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
x <- file.path(dir, "x")
for (z in list.files(dir, pattern = "\\.zip$", full.names = TRUE)) if (!dir.exists(file.path(x, sub("\\.zip$", "", basename(z))))) unzip(z, exdir = file.path(x, sub("\\.zip$", "", basename(z))))
rd_inp <- function(f) { l <- trimws(readLines(f, warn = FALSE)); l <- l[nzchar(l)]
  h <- sub("\\s.*$", "", l); stopifnot(all(grepl("\\s1;$", l))); h }
sites <- list(
  crundale = list(name = "Crundale", years = as.integer(1987L + c(0L, cumsum(c(1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)))), n = 228L,
                  place = "Crundale, Kent, England (roof void of a family home, rural)"),
  hollingbury = list(name = "Hollingbury", years = as.integer(1989L + c(0L, cumsum(c(7,1,2,3,1,1,1,1,1,3,1)))), n = 102L,
                     place = "Hollingbury, Brighton, East Sussex, England (roof void of a former golf clubhouse)"))
stopifnot(identical(sites$crundale$years, setdiff(1987:2011, c(1992L, 1995L))), length(sites$hollingbury$years) == 12L,
          identical(sites$hollingbury$years, c(1989L, 1996L, 1997L, 1999L, 2002:2007, 2010L, 2011L)))
taxa <- make_taxa("EPTSER", "Eptesicus serotinus", vernacularName = "Serotine bat")
for (s in names(sites)) {
  S <- sites[[s]]; TABLE <- sprintf("chauvenet_2014_%s_serotine_ms", s); K <- length(S$years)
  ms <- rd_inp(file.path(x, sprintf("CJS analysis- %s/CJS analysis- %s/%s_MS_noNnomale.inp", S$name, S$name, S$name)))
  pp <- rd_inp(file.path(x, sprintf("POPAN analysis/POPAN analysis/%s_popan_nomale.inp", S$name)))
  stopifnot(length(ms) == S$n, all(nchar(ms) == K), all(grepl("^[0JUB]+$", ms)), all(grepl("[JUB]", ms)),
            identical(gsub("[JUB]", "1", ms), pp))          # the POPAN file is the MS file recoded to 0/1
  H <- do.call(rbind, strsplit(ms, ""))
  first <- apply(H != "0", 1, function(r) which(r)[1]); fst <- H[cbind(seq_len(nrow(H)), first)]
  start <- ifelse(fst == "J", first, 1L)
  # a J appears only at first capture (juveniles are young of the year)
  stopifnot(all(H[H == "J"] == "J"), sum(H == "J") == sum(fst == "J"))
  long <- rbindlist(lapply(seq_len(nrow(H)), function(i) data.table(unit = sprintf("%s_%03d", s, i), period = start[i]:K,
                                                               y_raw = H[i, start[i]:K])))
  long[, `:=`(taxon = "EPTSER", y = match(y_raw, c("0", "J", "U", "B")) - 1L)]
  long <- order_eco(long)
  stopifnot(sum(long$y > 0) == sum(H != "0"), uniqueN(long$unit) == S$n)
  cat(sprintf("  %s: %d females x %d years -> %d rows, %d captures (first caught as J: %d)\n", s, S$n, K, nrow(long),
              sum(long$y > 0), sum(fst == "J")))
  periods <- data.table(period = seq_len(K), year = S$years)
  dataset <- list(
    title = sprintf("Multi-state capture histories (juvenile, immature/unknown, breeder) of %d female serotine bats at the %s maternity roost, England, %d-%d", S$n, S$name, min(S$years), max(S$years)),
    creator = "Chauvenet, Aliénor L. M.; Hutson, Anthony M.; Smith, Graham C.; Aegerter, James N.", pubDate = "2014",
    doi = "10.5061/dryad.6kp2j", sourceURL = "https://doi.org/10.5061/dryad.6kp2j",
    citation = "Chauvenet, A. L. M., Hutson, A. M., Smith, G. C., & Aegerter, J. N. (2014). Data from: Demographic variation in the U.K. serotine bat: filling gaps in knowledge for management [Dataset]. Dryad. https://doi.org/10.5061/dryad.6kp2j",
    paperDOI = "10.1002/ece3.1174",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Female serotine bats (Eptesicus serotinus) ringed and recaptured at the %s maternity roost in south-east England in %d capture years between %d and %d, each capture assigned to a life stage (juvenile, immature/unknown, breeder). The authors fitted multistate CJS and POPAN models to estimate stage-specific survival, transitions and abundance.", S$name, K, min(S$years), max(S$years)),
    samplingProtocol = "Annual or ad hoc capture visits to a maternity roost (usually twice between May and August, or once in August), bats caught by hand in the roost or with hand nets / harp traps outside, ringed, aged by ossification and assessed for breeding; captures pooled to one annual occasion per year.",
    samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
    responseType = "state", unitKind = "individual",
    stateCodes = list(`0` = "not caught", `1` = "caught as a juvenile (J)", `2` = "caught as immature or unknown stage (U: adult-looking, breeding not recorded or not determinable)", `3` = "caught as a breeder (B)"),
    closure = "none", closureNote = "one annual occasion per capture year (visits within a year pooled by the authors); capture years are unevenly spaced (__periods)",
    occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = S$place, temporalCoverage = sprintf("%d/%d", min(S$years), max(S$years)),
    notShipped = list(popan_files = "the POPAN 0/1 histories: the MS histories with J/U/B recoded to 1 (asserted)",
                      mark_projects = "MARK .DBF / .FPT project files and model results",
                      ibm = "the individual-based simulation script", males = "males, excluded by the authors and not deposited"),
    notes = "Females only. A female first caught as a juvenile has rows from that year; one first caught as U or B from the first capture year (E4.4). The authors assumed a bat once recorded as a breeder stays a breeder; U after B occurs in the data as recorded (y_raw).")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Multi-state (juvenile, immature/unknown, breeder) capture histories of %d female serotine bats at the %s maternity roost, England, %d-%d.", S$n, S$name, min(S$years), max(S$years)),
    url = "https://doi.org/10.5061/dryad.6kp2j",
    reference = "Chauvenet, A. L. M., Hutson, A. M., Smith, G. C., & Aegerter, J. N. (2014). Demographic variation in the U.K. serotine bat: filling gaps in knowledge for management. Ecology and Evolution, 4(19), 3820-3829.",
    doi_paper = "10.1002/ece3.1174", doi_data = "10.5061/dryad.6kp2j",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "One table per roost as deposited; POPAN files are a recode of the MS files (not shipped).",
    source_via = "Dryad (version zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-state capture-recapture (CJS)",
    sampling_protocol = "live_trap", design = sprintf("Multi-season (%d capture years, %d-%d)", K, min(S$years), max(S$years)),
    realm = "Terrestrial", country = "GBR", coordinates = "None in source",
    notes = "Bat maternity roost; life-stage states.")
}
