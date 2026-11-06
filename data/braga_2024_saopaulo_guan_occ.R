#!/usr/bin/env Rscript
# Table:  braga_2024_saopaulo_guan_occ
# Source: Dryad doi:10.5061/dryad.kprr4xhdj (CC0 1.0, as shown on the Dryad page; published
#         2024-09-24). Braga, P.R., Ponzio, M.C., Pasqualotto, N., Alberici, V., Paolino, R.M.,
#         Rodrigues, R.C. & Chiarello, A.G. Anthropogenic landscape features affect the ground
#         habitat use of Penelope superciliaris (Cracidae), a large seed disperser bird in
#         southeastern Brazil.
# Paper:  Braga, P.R. et al. (2024). Biotropica, doi:10.1111/btp.13382. One camera trap at each of
#         205 sites in southeastern Brazil; occupancy (unmarked) (README).
# Data:   Rusty-margined_guan_data_covariates.csv (";"-separated, 205 sites: c1-c6 = detection
#         0/1 on six sampling occasions, c6 empty = "missing data for this sampling occasion" (3
#         sites); covariates with units in README.md: EdgeDist (m), Sug_12_5ha, ManF_12_5ha,
#         OpenNat_25ha, ClosedNat_200ha (%), Edist (m), landscape (1 = JES/LAES), UnpRoad (1 = on
#         unpaved road / trail / edge), DistW (m), InOut (1 = inside protected area)).
# Mapping (standard: single-season occupancy, E9 core): unit = sites; taxon = PENSUP; occasion =
#   1..6; y = the cell; empty = no row. unit_: all covariates. Survey evidence: deposited_matrix.
#   The guan is IUCN LC; no coordinates are deposited. Occasion length and dates are not in the
#   deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "braga_2024_saopaulo_guan_occ"
dir <- download_dryad("10.5061/dryad.kprr4xhdj", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Rusty-margined_guan_data_covariates\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, sep = ";")
oc <- paste0("c", 1:6)
stopifnot(nrow(d) == 205, !anyDuplicated(d$sites), all(as.matrix(d[, ..oc]) %in% c(0, 1, NA)), sum(is.na(d$c6)) == 3, !anyNA(d[, c1:c5]))
Y <- as.matrix(d[, ..oc]); dimnames(Y) <- list(d$sites, NULL)
sc <- as.data.frame(d[, .(edge_dist_m = EdgeDist, sugarcane_pct_12_5ha = Sug_12_5ha, managed_forest_pct_12_5ha = ManF_12_5ha,
                          open_native_pct_25ha = OpenNat_25ha, closed_native_pct_200ha = ClosedNat_200ha, dist_farmhouse_m = Edist,
                          landscape_jes_laes = landscape, unpaved_road = UnpRoad, dist_water_m = DistW, inside_protected = InOut)])
long <- order_eco(array_to_eco(Y, taxon = "PENSUP", site_ids = d$sites, site_covs = sc))
stopifnot(nrow(long) == 205 * 6 - 3, sum(long$y) == 38)
taxa <- make_taxa("PENSUP", "Penelope superciliaris", vernacularName = "Rusty-margined guan")
dataset <- list(
  title = "Camera-trap detections of the rusty-margined guan at 205 sites in southeastern Brazil, six occasions",
  creator = "Braga, Pâmela Rodrigues; Pônzio, Marcella do Carmo; Pasqualotto, Nielson; Alberici, Vinicius; Paolino, Roberta Montanheiro; Rodrigues, Rodolpho Credo; Chiarello, Adriano Garcia",
  pubDate = "2024", doi = "10.5061/dryad.kprr4xhdj", sourceURL = "https://doi.org/10.5061/dryad.kprr4xhdj",
  citation = "Braga, P. R. et al. (2024). Anthropogenic landscape features affect the ground habitat use of Penelope superciliaris (Cracidae), a large seed disperser bird in southeastern Brazil [Dataset]. Dryad. https://doi.org/10.5061/dryad.kprr4xhdj",
  paperDOI = "10.1111/btp.13382",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of the rusty-margined guan (Penelope superciliaris) on six sampling occasions of one camera trap at each of 205 sites in an agricultural (sugarcane, managed forest) and native-vegetation landscape of southeastern Brazil, with distances to edges, farmhouses and water, land-cover proportions and placement covariates.",
  samplingProtocol = "One camera trap per site on or off unpaved roads and trails, inside and outside protected native vegetation; detections summarised per sampling occasion (six per site).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one deployment per site; the authors' single-season occupancy", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = "Southeastern Brazil (São Paulo state; JES/LAES and surrounding landscapes); no coordinates deposited",
  temporalCoverage = "survey dates not stated in the deposit (paper 2024)",
  notShipped = list(none = "every deposited column is shipped"),
  notes = "Occasion length and survey dates are in the paper, not the deposit. Three sites lack the sixth occasion.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/braga_2024_saopaulo_guan_occ.R")
stage_dict_row(TABLE, description = "Camera-trap detection/non-detection of the rusty-margined guan at 205 sites in southeastern Brazil, six occasions, with landscape covariates.",
  url = "https://doi.org/10.5061/dryad.kprr4xhdj", reference = "Braga, P. R. et al. (2024). Anthropogenic landscape features affect the ground habitat use of Penelope superciliaris (Cracidae). Biotropica.",
  doi_paper = "10.1111/btp.13382", doi_data = "10.5061/dryad.kprr4xhdj", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Single-species occupancy.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Single-season occupancy",
  sampling_protocol = "camera_trap", design = "Single-season (6 occasions)", realm = "Terrestrial",
  country = "BRA", coordinates = "None in source", notes = "Ground-dwelling cracid on cameras.")
