#!/usr/bin/env Rscript
# Table:  mattioli_2018_arezzo_wolf_scr
# Source: figshare doi:10.6084/m9.figshare.7164929.v1 ("Additional file 5" of the article, published 2018-10-03),
#         licence "CC BY + CC0" as shown on the figshare item (BioMed Central: article CC BY 4.0, data CC0 1.0;
#         asserted from the cached article JSON). The stricter, CC BY 4.0, is carried.
#   Mattioli, L., Canu, A., Passilongo, D., Scandura, M. & Apollonio, M. (2018). Additional file 5: of Estimation
#   of pack density in grey wolf (Canis lupus) by applying spatially explicit capture-recapture models to camera
#   trap data supported by genetic monitoring [Dataset]. figshare.
# Paper:  Mattioli, L., Canu, A., Passilongo, D., Scandura, M. & Apollonio, M. (2018). Estimation of pack density
#         in grey wolf (Canis lupus) by applying spatially explicit capture-recapture models to camera trap data
#         supported by genetic monitoring. Frontiers in Zoology 15, 38. doi:10.1186/s12983-018-0281-x (open access).
#         The deposit's own script settles the format: proximity detectors, one occasion per day, sessions 2014 and
#         2015, Arezzo province, Italy.
# Data:   12983_2018_281_MOESM5_ESM.rar (read with archive::, as in kyaw_2024_myanmar_mamm_comm), holding the same
#         five CSVs twice (SPACECAP/ and SECR/; identical, asserted) and "scripts for secr analysis.docx":
#         Trap_deployment_<year>_s.csv: LOC_ID, X_Coord, Y_Coord (UTM metres), then one 0/1 column per day (trap
#           operating): 2014 26 traps x 71 days (1,533 trap-days operating), 2015 48 traps x 153 days (2,570).
#         Animal_capture_<year>_s.csv: LOC_ID, ANIMAL_ID, SO (day): 98 (2014) and 128 (2015) detections of 10 and 12
#           identified wolves; no duplicate rows; every detection on an operating trap-day (asserted).
#         state_space.csv: the 666 m habitat mask (X, Y, HABITAT), a model input, not shipped.
# Mapping (SCR, E9 experimental): unit = "<year>_<ANIMAL_ID>" (the ids are numbered from 1 in each session and the
#   deposit does not link them, so an id is valid only within its session; closureNote), trap = "<year>_<LOC_ID>"
#   (the two sessions' trap sets differ), taxon = CANLUP, period = session (1 = 2014, 2 = 2015), occasion = day,
#   y = 1 if the wolf was photographed at the trap that day, else 0. One row per individual x trap x day the trap
#   operated in the individual's session. surveyEvidence = effort_table (the deployment matrix). __traps: x, y as
#   deposited (UTM; crs below), session, LOC_ID, days operating. Canis lupus IUCN LC, so the coordinates are kept as
#   published (E7 does not flag the taxon).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mattioli_2018_arezzo_wolf_scr"
mf <- file.path(RAW_DIR, TABLE, "figshare_article.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file("https://api.figshare.com/v2/articles/7164929", mf, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(mf)
stopifnot(identical(meta$license$name, "CC BY + CC0"), identical(meta$doi, "10.6084/m9.figshare.7164929.v1"),
          identical(meta$files$name, "12983_2018_281_MOESM5_ESM.rar"))
rar <- download_cached("https://ndownloader.figshare.com/files/13181804", TABLE, filename = "12983_2018_281_MOESM5_ESM.rar")
ex <- file.path(dirname(rar), "x")
if (!dir.exists(file.path(ex, "SECR"))) archive::archive_extract(rar, dir = ex)
for (y in c(2014, 2015)) stopifnot(
  identical(unname(tools::md5sum(file.path(ex, "SECR", sprintf("Animal_capture_%d_s.csv", y)))), unname(tools::md5sum(file.path(ex, "SPACECAP", sprintf("Animal_capture_%d.csv.csv", y))))),
  identical(unname(tools::md5sum(file.path(ex, "SECR", sprintf("Trap_deployment_%d_s.csv", y)))), unname(tools::md5sum(file.path(ex, "SPACECAP", sprintf("Trap_deployment_%d.csv.csv", y))))))
S <- list(`2014` = list(nt = 26L, nd = 71L, use = 1533L, ncap = 98L, nid = 10L), `2015` = list(nt = 48L, nd = 153L, use = 2570L, ncap = 128L, nid = 12L))
rows <- list(); traps <- list()
for (yr in names(S)) {
  s <- S[[yr]]; per <- match(yr, names(S))
  t <- fread(file.path(ex, "SECR", sprintf("Trap_deployment_%s_s.csv", yr)))
  a <- fread(file.path(ex, "SECR", sprintf("Animal_capture_%s_s.csv", yr)))
  setnames(t, 1:3, toupper(names(t)[1:3])); setnames(t, 2:3, c("X_Coord", "Y_Coord"))   # 2014 X_Coord, 2015 X_COORD
  u <- as.matrix(t[, -(1:3)])
  stopifnot(identical(names(t)[1], "LOC_ID"), nrow(t) == s$nt, ncol(u) == s$nd, all(u %in% 0:1),
            sum(u) == s$use, !anyDuplicated(t$LOC_ID), identical(names(a), c("LOC_ID", "ANIMAL_ID", "SO")), nrow(a) == s$ncap,
            !anyDuplicated(a), identical(sort(unique(a$ANIMAL_ID)), seq_len(s$nid)), all(a$LOC_ID %in% t$LOC_ID),
            all(u[cbind(match(a$LOC_ID, t$LOC_ID), a$SO)] == 1L))
  op <- which(u == 1L, arr.ind = TRUE)
  td <- data.table(LOC_ID = t$LOC_ID[op[, 1]], occasion = op[, 2])
  g <- CJ(ANIMAL_ID = seq_len(s$nid), k = seq_len(nrow(td)))
  g[, `:=`(LOC_ID = td$LOC_ID[k], occasion = td$occasion[k])][, k := NULL]
  g[, y := 0L][a, on = .(ANIMAL_ID, LOC_ID, occasion = SO), y := 1L]
  stopifnot(nrow(g) == s$nid * s$use, sum(g$y) == s$ncap)
  g[, `:=`(unit = sprintf("%s_%02d", yr, ANIMAL_ID), trap = sprintf("%s_%02d", yr, LOC_ID), period = per)]
  rows[[yr]] <- g[, .(unit, trap, period, occasion, y)]
  traps[[yr]] <- t[, .(trap = sprintf("%s_%02d", yr, LOC_ID), x = X_Coord, y = Y_Coord, period = per, loc_id = LOC_ID, days_operating = rowSums(u))]
}
long <- rbindlist(rows)[, taxon := "CANLUP"]
long <- order_eco(long)
traps <- rbindlist(traps)
stopifnot(nrow(long) == 10L * 1533L + 12L * 2570L, sum(long$y) == 226L, !anyDuplicated(long[, .(unit, trap, period, occasion)]))
taxa <- make_taxa("CANLUP", "Canis lupus", vernacularName = "Grey wolf")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:2, year = 2014:2015, n_traps = c(26L, 48L), n_days = c(71L, 153L), trap_days = c(1533L, 2570L), n_wolves = c(10L, 12L))
dataset <- list(
  title = "Spatial capture-recapture of 22 wolf identifications on camera-trap arrays over 71 and 153 days, Arezzo province, Italy, 2014 and 2015",
  creator = "Mattioli, Luca; Canu, Antonio; Passilongo, Daniela; Scandura, Massimo; Apollonio, Marco",
  pubDate = "2018", doi = "10.6084/m9.figshare.7164929.v1", sourceURL = "https://doi.org/10.6084/m9.figshare.7164929.v1",
  citation = "Mattioli, L., Canu, A., Passilongo, D., Scandura, M., & Apollonio, M. (2018). Additional file 5: of Estimation of pack density in grey wolf (Canis lupus) by applying spatially explicit capture-recapture models to camera trap data supported by genetic monitoring [Dataset]. figshare. https://doi.org/10.6084/m9.figshare.7164929.v1",
  paperDOI = "10.1186/s12983-018-0281-x",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Camera-trap spatial capture-recapture data for grey wolves in Arezzo province, Italy, in 2014 (71 days) and 2015 (153 days), 74 trap locations in all (per-session counts in __periods), with individually identified wolves (camera identifications supported by genetic monitoring), deposited as secr and SPACECAP inputs for estimating pack density.",
  samplingProtocol = "Camera traps (proximity detectors) along wolf travel routes; a wolf photographed at a trap on a day is a detection for that trap-day; trap operation per day from the deployment matrix.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "individual", closure = "closed",
  closureNote = "Each session is assumed closed across its days. Individual ids are numbered from 1 within each session and are not linked between sessions, so a unit is '<year>_<id>' with rows only in its session; trap ids are also per session.",
  occasionKind = "time", taxonInclusion = "single", crs = "EPSG:32632 (UTM zone 32N; the deposit gives metres without naming the datum, WGS 84 assumed)",
  geographicCoverage = "Arezzo province, Tuscany, Italy (trap coordinates in __traps)",
  temporalCoverage = "2014/2015",
  notShipped = list(state_space = "state_space.csv: the 666 m habitat mask used as the model's state space (a model input)",
                    duplicates = "the SPACECAP folder repeats the SECR files (identical, asserted)",
                    model_output = "the paper's density estimates"),
  notes = "Calendar dates of the days are not in the deposit (day index only).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = "data/mattioli_2018_arezzo_wolf_scr.R")
stage_dict_row(TABLE,
  description = "Camera-trap spatial capture-recapture of grey wolves (Canis lupus) in Arezzo province, Italy: 26 and 48 traps, 71 and 153 daily occasions, 2014 and 2015.",
  url = "https://doi.org/10.6084/m9.figshare.7164929.v1",
  reference = "Mattioli, L., Canu, A., Passilongo, D., Scandura, M. & Apollonio, M. (2018). Estimation of pack density in grey wolf (Canis lupus) by applying spatially explicit capture-recapture models to camera trap data supported by genetic monitoring. Frontiers in Zoology 15, 38. https://doi.org/10.1186/s12983-018-0281-x",
  doi_paper = "10.1186/s12983-018-0281-x", doi_data = "10.6084/m9.figshare.7164929.v1",
  original_license = "CC BY 4.0 + CC0 1.0 (figshare 'CC BY + CC0'; BMC additional file)", derived_license = "CC BY 4.0",
  notes = "RAR archive read with archive::; ids per session.", source_via = "figshare (ndownloader)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture",
  sampling_protocol = "camera_trap", design = "Multi-session (2 sessions, daily occasions)",
  realm = "Terrestrial", country = "ITA", coordinates = "As published", notes = "Experimental (E9): SCR.")
