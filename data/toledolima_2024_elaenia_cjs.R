#!/usr/bin/env Rscript
# Table:  toledolima_2024_elaenia_cjs
# Source: Zenodo record 11300767, doi:10.5281/zenodo.11300767 (CC BY 4.0)
#   Toledo-Lima, G. & Pichorim, M. (2024). Detection history of 175 adult Plain-crested
#   Elaenia (Elaenia cristata) throughout nine sessions between 2010 and 2014 in the
#   northeastern Brazil.
# Paper:  Toledo-Lima, G.S. et al. (2026). The effects of rainfall patterns and the influx
#         of a migratory congener on the survival of ... Studies on Neotropical Fauna and
#         Environment, doi:10.1080/01650521.2026.2646579 (Crossref match on author +
#         species; the deposit itself names no paper).
# Data:   a Program MARK .inp file: one line per individual,
#           /*<band>*/ <9-character capture history> <freq>;
#         freq is 1 for 171 birds and -1 for 4, MARK's code for an individual removed
#         from the population at its last capture (loss on capture).
#
# Mapping (standard section 3.4, CJS): unit = band number, taxon = ELACRI, period = session
#   1..9, y = 0/1. No `occasion` (one capture occasion per session). Rows before first
#   capture are kept as 0. Losses on capture follow section 2.1: rows end at the removal
#   session and obs_removed = 1 on that row (0 elsewhere). Session dates are not in the
#   deposit, so there is no `date` and the periods side table carries only the index.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "toledolima_2024_elaenia_cjs"
f <- download_cached("https://zenodo.org/api/records/11300767/files/detection_history_Elaenia_cristata.inp/content",
                     TABLE, filename = "detection_history_Elaenia_cristata.inp")
lines <- readLines(f, encoding = "latin1", warn = FALSE)
lines <- trimws(lines[nzchar(trimws(lines))])
m <- regmatches(lines, regexec("^/\\*\\s*([0-9]+)\\s*\\*/\\s*([01]{9})\\s+(-?1);$", lines))
stopifnot(all(lengths(m) == 4))
inp <- data.table(unit = as.integer(sapply(m, `[`, 2)), ch = sapply(m, `[`, 3), freq = as.integer(sapply(m, `[`, 4)))
stopifnot(nrow(inp) == 175, !anyDuplicated(inp$unit), all(inp$freq %in% c(1L, -1L)))
Tn <- 9L
CH <- t(sapply(strsplit(inp$ch, ""), as.integer)); stopifnot(dim(CH) == c(175, Tn))

long <- array_to_eco(CH, taxon = "ELACRI", site_ids = inp$unit, period = seq_len(Tn))
long[, occasion := NULL]
long[, obs_removed := 0L]
# losses on capture: keep rows up to and including the last capture, flag that row
removed <- inp[freq == -1L]
for (i in seq_len(nrow(removed))) {
  last <- max(which(CH[match(removed$unit[i], inp$unit), ] == 1L))
  long <- long[!(unit == removed$unit[i] & period > last)]
  long[unit == removed$unit[i] & period == last, obs_removed := 1L]
}
cat(sprintf("  %d individuals removed at last capture (MARK freq -1); %d rows dropped after removal\n",
            nrow(removed), 175 * Tn - nrow(long)))
stopifnot(sum(long$obs_removed) == nrow(removed))

taxa <- make_taxa("ELACRI", "Elaenia cristata", vernacularName = "Plain-crested Elaenia")
periods <- data.table(period = seq_len(Tn), note = "capture session; calendar dates not deposited (2010-2014)")
dataset <- list(
  title = "Capture histories of 175 adult Plain-crested Elaenia over nine sessions, northeastern Brazil, 2010-2014",
  creator = "Toledo-Lima, Guilherme; Pichorim, Mauro", pubDate = "2024", doi = "10.5281/zenodo.11300767",
  sourceURL = "https://doi.org/10.5281/zenodo.11300767",
  citation = "Toledo-Lima, G., & Pichorim, M. (2024). Detection history of 175 adult Plain-crested Elaenia (Elaenia cristata) throughout nine sessions between 2010 and 2014 in the northeastern Brazil [Data set]. Zenodo. https://doi.org/10.5281/zenodo.11300767",
  paperDOI = "10.1080/01650521.2026.2646579",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "The input file for analysing the detection history of 175 adult Plain-crested Elaenia (Elaenia cristata) throughout nine sessions between 2010 and 2014 in the northeastern Brazil.",
  samplingProtocol = "Mist-net capture-mark-recapture of banded adults; Program MARK input format (CJS).",
  samplingProtocolCode = "mist_net", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "period (one capture occasion per session; state may change between sessions)", occasionKind = "none", taxonInclusion = "single",
  lossesOnCapture = "4 individuals; encoded as obs_removed = 1 on the last row, no later rows",
  geographicCoverage = "northeastern Brazil (no coordinates deposited)", temporalCoverage = "2010/2014",
  coordinatesCoarsened = NA)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/toledolima_2024_elaenia_cjs.R")

stage_dict_row(TABLE,
  description = "Cormack-Jolly-Seber capture histories of 175 banded adult Plain-crested Elaenia (Elaenia cristata) across nine capture sessions in northeastern Brazil, 2010-2014, from a Program MARK input file; four losses on capture flagged in obs_removed.",
  url = "https://doi.org/10.5281/zenodo.11300767",
  reference = "Toledo-Lima, G. S., et al. (2026). The effects of rainfall patterns and the influx of a migratory congener on the survival of Plain-crested Elaenia. Studies on Neotropical Fauna and Environment.",
  doi_paper = "10.1080/01650521.2026.2646579", doi_data = "10.5281/zenodo.11300767",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Paper matched on Crossref by author and species, not named in the deposit; verify. MARK freq = -1 (loss on capture) encoded per standard section 2.1.",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "mist_net", design = "Multi-session (9 primary periods, no secondary)", realm = "Terrestrial",
  country = "BRA", coordinates = "None in source", notes = "Individuals as unit; rows before first capture kept as 0.")
