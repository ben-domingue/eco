#!/usr/bin/env Rscript
# Table:  steinmetz_2025_maewong_tiger_rd
# Source: figshare article 29631782, doi:10.6084/m9.figshare.29631782.v1 (published 2025-07-24; licence as shown on the
#         record: CC BY 4.0).
#   Steinmetz, R. & Phumanee, W. (2025). Tiger capture-recapture data from Mae Wong Khlong Lan National Parks, Thailand,
#   2012-2022. figshare.
# Paper:  Steinmetz, R., Phumanee, W., Phoonjampa, R., Keawsrisod, T., Bunchornratana, K., Dawrueng, T., Bejraburnin, T.
#         & Bhumpakphan, N. Investigating the demography and dynamics of a low-density tiger population in Southeast
#         Asia: what limits recovery? Ecological Applications (named in the workbook; not read).
# Data:   Data.from_Tiger.Pop.Dynamics_Tiger.capture.history.xlsx, one sheet: ten header lines ("Tigers were sampled using
#         camera traps. Sampling occasions are weeks. '1' represents a capture (photo) in that week. '0' is no
#         detection."; "M = males; F = females"; row colours mark tenure), then 33 tigers (M1..M25, F1..F19 with gaps)
#         x 72 weekly occasions in six sessions headed 2012, 2014, 2016, 2018, 2020, 2022 (12 weeks each).
#         Asserted: 33 tigers, 72 cells each, values only 0 / 1, the session headers at every 12th column.
# Mapping: robust design. unit = tiger (M1...), period = session (1 = 2012 ... 6 = 2022), occasion = week 1-12 within
#   the session, y = photographed that week; unit_sex from the id. surveyEvidence deposited_matrix: every tiger has a
#   cell for every week (the deposit has no not-surveyed code); tigers of unknown age are at risk from 2012 (E4.4).
# Not shipped: tenure (row colours, lost in a tabular read); no camera locations are deposited (tiger IUCN EN).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
library(readxl)
TABLE <- "steinmetz_2025_maewong_tiger_rd"
meta <- fromJSON(download_cached("https://api.figshare.com/v2/articles/29631782", TABLE, "record.json"))
stopifnot(identical(meta$license$name, "CC BY 4.0"))
xf <- download_cached("https://ndownloader.figshare.com/files/56501891", TABLE, "tiger.xlsx")
d <- as.data.table(suppressMessages(read_excel(xf, col_names = FALSE, col_types = "text")))
h <- unlist(d[11]); stopifnot(identical(unname(h[c(2, 14, 26, 38, 50, 62)]), as.character(seq(2012, 2022, 2))), sum(!is.na(h[-1])) == 6, ncol(d) == 73)
m <- d[12:44]; stopifnot(nrow(m) == 33, all(grepl("^/\\*[MF][0-9]+\\*/$", m[[1]])), all(unlist(m[, 2:73]) %in% c("0", "1")))
ids <- gsub("[/*]", "", m[[1]])
long <- rbindlist(lapply(seq_along(ids), function(i) data.table(unit = ids[i], taxon = "PANTIG", y = as.integer(unlist(m[i, 2:73])),
                                                              period = rep(1:6, each = 12), occasion = rep(1:12, 6), unit_sex = substr(ids[i], 1, 1))))
stopifnot(nrow(long) == 33 * 72, sum(long$y) == 223)
periods <- data.table(period = 1:6, year = seq(2012L, 2022L, 2L))
taxa <- make_taxa("PANTIG", "Panthera tigris", vernacularName = "Tiger")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Weekly camera-trap capture histories of 33 tigers in six biennial sessions, Mae Wong and Khlong Lan National Parks, Thailand, 2012-2022",
  creator = "Steinmetz, Robert; Phumanee, Worrapan",
  pubDate = "2025", doi = "10.6084/m9.figshare.29631782.v1", sourceURL = "https://doi.org/10.6084/m9.figshare.29631782.v1",
  citation = "Steinmetz, R. & Phumanee, W. (2025). Tiger capture-recapture data from Mae Wong Khlong Lan National Parks, Thailand, 2012-2022. figshare. Dataset. https://doi.org/10.6084/m9.figshare.29631782.v1",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Tigers in the Mae Wong and Khlong Lan National Parks, western Thailand, were photographed by camera traps and identified from stripe patterns in six biennial sessions from 2012 to 2022; weekly capture histories support estimates of survival, recruitment and population dynamics of a low-density, recovering population.",
  samplingProtocol = "Camera-trap surveys in 2012, 2014, 2016, 2018, 2020 and 2022, each analysed as 12 weekly occasions; tigers identified individually from photographs; a week is a capture when the tiger was photographed.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The workbook gives a 0/1 cell for every tiger and week of every session, with no not-surveyed code.",
  responseType = "detection", unitKind = "individual", closure = "closed", occasionKind = "time", taxonInclusion = "single",
  closureNote = "Robust design: period = biennial session, occasion = week of the session; ids are valid across sessions.",
  geographicCoverage = "Mae Wong and Khlong Lan National Parks, western Thailand (no camera locations deposited)",
  temporalCoverage = "2012/2022",
  notShipped = list(tenure = "tenure of individuals marked by row colours in the workbook"),
  notes = "Tiger (Panthera tigris) is IUCN EN; the deposit has no trap identities or locations, so the table is a robust design, not SCR.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/steinmetz_2025_maewong_tiger_rd.R")
stage_dict_row(TABLE,
  description = "Weekly camera-trap capture histories of 33 individually identified tigers in six biennial 12-week sessions, Mae Wong and Khlong Lan National Parks, Thailand, 2012-2022.",
  url = "https://doi.org/10.6084/m9.figshare.29631782.v1",
  reference = "Steinmetz, R. et al. Investigating the demography and dynamics of a low-density tiger population in Southeast Asia: what limits recovery? Ecological Applications.",
  doi_data = "10.6084/m9.figshare.29631782.v1", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Robust design from the deposited weekly matrix.", source_via = "figshare")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design", sampling_protocol = "camera_trap",
  design = "Multi-season (6 biennial sessions x 12 weeks)", realm = "Terrestrial", country = "THA", coordinates = "None in source",
  notes = "Low-density recovering tiger population.")
