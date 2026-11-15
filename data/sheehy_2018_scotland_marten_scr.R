#!/usr/bin/env Rscript
# Tables: sheehy_2018_scotland_marten_scr (pine marten genetic SCR) and
#         sheehy_2018_scotland_feeder_comm (red squirrel, grey squirrel and pine marten
#         detection / non-detection at the same feeders, Central Scotland and Borders)
# Source: Dryad doi:10.5061/dryad.478kp63, version 1 (published 2018-02-16), licence CC0 1.0 (as
#         shown on the Dryad page; SPDX CC0-1.0). Sheehy, E., Sutherland, C., O'Reilly, C. & Lambin,
#         X. "Data from: The enemy of my enemy is my friend: native pine marten recovery reverses
#         the decline of the red squirrel by suppressing grey squirrel populations".
# Paper:  Sheehy, E., Sutherland, C., O'Reilly, C., & Lambin, X. (2018). The enemy of my enemy is my
#         friend: native pine marten recovery reverses the decline of the red squirrel by
#         suppressing grey squirrel populations. Proceedings of the Royal Society B, 285, 20172603.
#         doi:10.1098/rspb.2017.2603 (CC BY 4.0; read via Europe PMC PMC5879625).
# Design (paper): three regions of Scotland differing in time since pine marten recolonisation,
#         Highlands (HI), Central Scotland (CS) and Scottish Borders (BO); 2 x 2 km grid cells (10
#         in CS, 7 in BO, 2 in HI) holding 5-21 permanently deployed multi-species feeders (223 in
#         all, about 325 m apart). Feeders carry glue strips that take hair from squirrels and
#         martens; each site was visited four times between January and May 2016 at about
#         four-week intervals, plus a fifth visit in June in HI. Hair identified to species under
#         the microscope; marten hair genotyped to individual and sex. Trail cameras were rotated
#         among a subset of feeders (METHOD = camera and feeder, or feeder only).
# Data:   four files, no README:
#           Sheehy_et_al_Data_S9_enc_ESM.csv (390 rows): marten encounters, Year (2016), id (42
#               individuals, F../M..), occasion (1-5), trapID, sex (f/m), session (region: LL,
#               BO, HI), site (grid cell). Two HI rows give site "D" for traps DDSQ04 and DDSQ17,
#               whose cell is DD (the trap file is followed).
#           Sheehy_et_al_Data_S10_traps_ESM.csv (223 rows): trapID, X, Y (British National Grid
#               metres, EPSG:27700: the coordinates fall at 55.7-57.3 N, the paper's regions),
#               o1-o5 usage 0/1, site (grid cell), region (LL = the paper's CS, BO, HI).
#           Sheehy_et_al_Data_S11_detections_red_ESM.csv (223 rows): red squirrel, one row per
#               feeder, visit1-visit5 (0/1/NA; visit5 only in HI), cover, bl, gs, tCov1-tCov5
#               (hair / both), region (CS, BO, HI), coordinates to 0.0001 m.
#           Sheehy_et_al_Data_S12_detections_grey_ESM.csv (561 rows): despite the name, three
#               rows per CS and BO feeder (187 feeders x grey, marten, red), visit1-visit4, the
#               same covariates. Its red rows equal S11's for those feeders (asserted), and the
#               NA pattern is identical across the three species (asserted).
# Mapping, marten SCR (E9 experimental, closed population, genetic hair detections):
#   unit = individual marten (42), trap = feeder (trapID), occasion = visit (1-5), no period
#   (one 2016 session); cluster_id = region (CS, BO, HI). Each region is its own trap array and
#   no individual was detected in two regions (asserted), so an individual is at risk at the
#   traps of its own region only (E4.4: outside the trapped area elsewhere). Survey set =
#   effort_table: the o1-o5 usage columns; the rectangle is every individual x every used
#   (trap, occasion) of its region, y = 1 where its hair was genotyped there. unit_sex as
#   deposited. __traps: x, y in EPSG:27700 as deposited, region, grid cell, occasions used.
# Mapping, feeder community occupancy: unit = feeder, cluster_id = grid cell, taxon = red
#   squirrel (SCIVUL), grey squirrel (SCICAR), pine marten (MARMAR), occasion = visit 1-4, y =
#   hair of the species on the glue strips (0/1); obs_method = hair (feeder only) or both
#   (feeder and camera), the paper's METHOD. Survey evidence: the deposited matrix (S12); an NA
#   visit is not surveyed for all three taxa (identical NA pattern). unit_: region,
#   cover_prop (proportion forest cover within 100 m), broadleaf_prop (proportion broadleaved
#   or mixed mainly broadleaved, 100 m), x, y (EPSG:27700).
#   HI is not in this table: the deposit gives only red squirrel for the 36 HI feeders (grey
#   squirrels are absent from HI and the authors modelled only red there), and the feeder is
#   one detector for all three taxa, so by the shared-detector ruling (2026-11-06) a survey not
#   surveyed for some taxa has no rows; the 36 HI feeders x 5 visits are in notShipped.
#   Coordinates: no taxon is flagged (red squirrel, pine marten and grey squirrel are IUCN Least
#   Concern; the source states no sensitivity), and no private-land statement, so coordinates
#   are as deposited.
#   Not shipped: gs (the paper's GS, a grey squirrel covariate for red squirrel occupancy; its
#   construction is given neither in the deposit nor in the paper, it varies within grid cells
#   and is not the feeder's own share of grey detections, 0 throughout HI); the S11 coordinates at 0.0001 m (the trap file's whole metres are used, the same
#   points); DENS and DWC (model outputs of the SCR, not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/sheehy_2018_scotland_marten_scr.R"
T_SCR <- "sheehy_2018_scotland_marten_scr"; T_OCC <- "sheehy_2018_scotland_feeder_comm"
dir <- download_dryad("10.5061/dryad.478kp63", T_SCR)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
fn <- function(s) file.path(dir, sprintf("Sheehy_et_al_Data_%s_ESM.csv", s))
stopifnot(setequal(list.files(dir), basename(fn(c("S9_enc", "S10_traps", "S11_detections_red", "S12_detections_grey")))))
en <- fread(fn("S9_enc")); tr <- fread(fn("S10_traps")); gr <- fread(fn("S12_detections_grey"))
stopifnot(identical(names(en), c("Year", "id", "occasion", "trapID", "sex", "session", "site")),
          identical(names(tr), c("trapID", "X", "Y", "o1", "o2", "o3", "o4", "o5", "site", "region")),
          nrow(en) == 390L, nrow(tr) == 223L, nrow(gr) == 561L)
setnames(gr, "0", "cell")
reg_map <- c(LL = "CS", BO = "BO", HI = "HI")
tr[, reg := reg_map[region]]
stopifnot(!anyNA(tr$reg), !anyDuplicated(tr$trapID), identical(tr[, .N, by = reg][order(reg), N], c(80L, 107L, 36L)))
stopifnot(all(tr$X > 1.8e5 & tr$X < 3.8e5), all(tr$Y > 6.2e5 & tr$Y < 8.6e5))   # BNG, 55.7-57.3 N

# ===================== pine marten SCR =====================
use <- melt(tr[, .(trapID, reg, o1, o2, o3, o4, o5)], id.vars = c("trapID", "reg"), variable.name = "occasion", value.name = "used")
stopifnot(all(use$used %in% 0:1))
use <- use[used == 1L][, occasion := as.integer(sub("o", "", occasion))]
stopifnot(all(use[occasion == 5L, reg] == "HI"), nrow(use) == sum(as.matrix(tr[, .(o1, o2, o3, o4, o5)])))
rd0 <- fread(fn("S11_detections_red")); setnames(rd0, "0", "cell"); rd <- rd0
stopifnot(all(en$Year == 2016L), all(en$sex %in% c("f", "m")), all(en$trapID %in% tr$trapID),
          all(en$occasion %in% 1:5), !anyDuplicated(en[, .(id, occasion, trapID)]), uniqueN(en$id) == 42L)
en <- merge(en, tr[, .(trapID, reg, tsite = site)], by = "trapID")
stopifnot(nrow(en[site != tsite]) == 2L, all(en[site != tsite, .(site, tsite)] == c("D", "D", "DD", "DD")),
          all(reg_map[en$session] == en$reg),                                  # session = the trap's region
          all(en[, uniqueN(reg), by = id]$V1 == 1L), all(en[, uniqueN(sex), by = id]$V1 == 1L))
# one encounter (ND1D, 1DSQ02, visit 1) is at a trap-occasion the trap file marks unused; the squirrel
# file has that feeder-visit surveyed (visit1 = 0, not NA) and the hair was collected, so it is used
off <- en[!use, on = .(trapID, occasion)]
stopifnot(nrow(off) == 1L, off$id == "ND1D", off$trapID == "1DSQ02", off$occasion == 1L,
          tr[trapID == "1DSQ02", o1] == 0L, identical(rd[Feeder == "1DSQ02", visit1], 0L))
use <- rbind(use, data.table(trapID = "1DSQ02", reg = "CS", occasion = 1L, used = 1L))
tr[trapID == "1DSQ02", o1 := 1L]
inds <- unique(en[, .(unit = id, reg, sex)])
long <- inds[use, on = "reg", allow.cartesian = TRUE, nomatch = NULL]
long <- merge(long, en[, .(unit = id, trapID, occasion, y = 1L)], by = c("unit", "trapID", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
stopifnot(sum(long$y) == 390L, nrow(long) == sum(sapply(inds$reg, function(r) nrow(use[reg == r]))))
long <- long[, .(unit, taxon = "MARMAR", y, trap = trapID, occasion, cluster_id = reg, unit_sex = sex)]
long <- order_eco(long)
cat(sprintf("  marten SCR: %d individuals (%d f, %d m), %d encounters, %d rows\n", nrow(inds),
            sum(inds$sex == "f"), sum(inds$sex == "m"), 390L, nrow(long)))
traps <- tr[, .(trap = trapID, x = as.numeric(X), y = as.numeric(Y), region = reg, grid_cell = site,
                n_occasions_used = o1 + o2 + o3 + o4 + o5)]
traps <- traps[trap %in% long$trap]
taxa_m <- make_taxa("MARMAR", "Martes martes", vernacularName = "European pine marten")
taxa_m[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa_m$taxon_iucnCategory, "LC"))

cite <- "Sheehy, E., Sutherland, C., O'Reilly, C., & Lambin, X. (2018). Data from: The enemy of my enemy is my friend: native pine marten recovery reverses the decline of the red squirrel by suppressing grey squirrel populations [Dataset]. Dryad. https://doi.org/10.5061/dryad.478kp63"
ref <- "Sheehy, E., Sutherland, C., O'Reilly, C., & Lambin, X. (2018). The enemy of my enemy is my friend: native pine marten recovery reverses the decline of the red squirrel by suppressing grey squirrel populations. Proceedings of the Royal Society B, 285, 20172603."
common <- list(creator = "Sheehy, Emma; Sutherland, Chris; O'Reilly, Catherine; Lambin, Xavier", pubDate = "2018",
  doi = "10.5061/dryad.478kp63", sourceURL = "https://doi.org/10.5061/dryad.478kp63", citation = cite,
  paperDOI = "10.1098/rspb.2017.2603",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  temporalCoverage = "2016-01/2016-06", crs = "EPSG:27700",
  coordinatesCoarsened = list(value = FALSE, method = "British National Grid metres as deposited: no taxon flagged (pine marten, red and grey squirrel IUCN Least Concern; no sensitivity statement in the source) and no private-land statement"))

ds_m <- write_table(long, T_SCR, c(list(
  title = "Genetic spatial capture-recapture of pine martens at 223 hair-sampling feeders in three regions of Scotland, January-June 2016: 42 individuals, 4-5 visits",
  abstract = sprintf("Pine marten (Martes martes) hair genotyped to individual and sex from glue strips in multi-species feeders at 222 sites (one further feeder never sampled) in 2 x 2 km grid cells in three regions of Scotland that differ in time since marten recolonisation: the Highlands (2 cells), Central Scotland (10) and the Scottish Borders (7). Visited four times between January and May 2016 at about four-week intervals, with a fifth visit in June in the Highlands. %d martens (%s), 390 detections. Used with spatial capture-recapture to estimate regional marten density and density-weighted connectivity, which were then related to red and grey squirrel occupancy (sibling table sheehy_2018_scotland_feeder_comm).", nrow(inds), paste(inds[, .N, by = reg][order(reg), sprintf("%d in %s", N, reg)], collapse = ", ")),
  samplingProtocol = "Permanently deployed baited multi-species feeders (15 cm wooden boxes with a liftable lid carrying glue strips) about 325 m apart within 2 x 2 km grid cells; hair collected and strips replaced at each visit; marten hair genotyped at microsatellite loci to individual and sex (Sheehy et al. 2018).",
  samplingProtocolCode = "hair_snag", surveyEvidence = "effort_table",
  surveyEvidenceNote = "The trap file's o1-o5 usage columns give which feeders were sampled on which visit; each individual has a row at every used feeder-visit of its own region (no individual was detected in two regions).",
  responseType = "detection", unitKind = "individual", closure = "closed",
  closureNote = "one 2016 session per region, treated as closed over the January-June visits as in the authors' SCR; the three regions are separate arrays (cluster_id) and an individual has rows only at its own region's feeders",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Scotland, UK: Highlands (about 57.3 N, 4.7 W), Central Scotland (56.1 N, 4.4 W) and Scottish Borders (55.7 N, 3.2 W); feeder coordinates in __traps (EPSG:27700)",
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Three regional arrays sampled concurrently; region as cluster_id.",
  notes = "Feeder 1DSQ02 is marked unused on visit 1 in the trap file, but marten ND1D was genotyped there on that visit and the squirrel file has the visit surveyed; it is treated as used. Two encounter rows give grid cell D for traps DDSQ04 and DDSQ17, whose cell is DD; the trap file is followed. Occasion dates are not deposited (four visits January-May at about four-week intervals, a fifth in June in HI). The trap file labels Central Scotland LL; region is written CS as in the paper.",
  notShipped = list(`DENS, DWC` = "pine marten density and density-weighted connectivity surfaces are SCR model outputs (not deposited)",
                    `squirrel detections` = "shipped as sheehy_2018_scotland_feeder_comm"))
  , common), taxa = taxa_m, traps = traps, script = SCRIPT)
stage_dict_row(T_SCR,
  description = sprintf("Genetic spatial capture-recapture of %d pine martens at %d hair-sampling feeders in three Scottish regions (Highlands, Central Scotland, Borders), four to five visits January-June 2016; one row per marten x feeder x visit of its region, feeder coordinates (British National Grid) in __traps.", nrow(inds), nrow(traps)),
  url = "https://doi.org/10.5061/dryad.478kp63", reference = ref,
  doi_paper = "10.1098/rspb.2017.2603", doi_data = "10.5061/dryad.478kp63",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population genetic SCR (E9 experimental), three concurrent regional arrays as cluster_id. Sibling: sheehy_2018_scotland_feeder_comm (squirrel and marten detection at the same feeders). Below the sample floor (42 individuals).",
  source_via = "Dryad")
stage_tag_row(T_SCR, ds_m, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic)",
  sampling_protocol = "hair_snag", design = "Single-season (4-5 visits, 3 regional arrays)", realm = "Terrestrial",
  country = "GBR", coordinates = "As published (feeder coordinates in __traps, EPSG:27700)",
  notes = "Experimental (E9): trap key + __traps; individuals at risk only in their own region's array.")

# ===================== feeder community occupancy (CS, BO) =====================
stopifnot(identical(names(gr), c("cell", "region", "Feeder", "X", "Y", "Species", paste0("visit", 1:4), "cover", "bl", "gs", paste0("tCov", 1:4))),
          all(gr[, .N, by = Feeder]$N == 3L), all(gr[, sort(Species), by = Feeder][, .(ok = identical(V1, c("grey", "marten", "red"))), by = Feeder]$ok),
          uniqueN(gr$Feeder) == 187L, setequal(gr$region, c("CS", "BO")), all(gr$Feeder %in% tr$trapID),
          all(tr[match(gr$Feeder, trapID), reg] == gr$region), all(rd$Feeder %in% tr$trapID))
vis <- paste0("visit", 1:4)
for (v in vis) stopifnot(all(gr[[v]] %in% c(0L, 1L, NA)))
w <- dcast(melt(gr[, c("Feeder", "Species", vis), with = FALSE], id.vars = c("Feeder", "Species")), Feeder + variable ~ Species)
stopifnot(all(is.na(w$grey) == is.na(w$red)), all(is.na(w$grey) == is.na(w$marten)), sum(is.na(w$red)) == 21L)
# S12 red rows equal S11 for the same feeders
rr <- merge(gr[Species == "red"], rd, by = "Feeder", suffixes = c("", ".r"))
stopifnot(nrow(rr) == 187L, all(sapply(vis, function(v) identical(rr[[v]], rr[[paste0(v, ".r")]]))),
          isTRUE(all.equal(rr$cover, rr$cover.r)), isTRUE(all.equal(rr$bl, rr$bl.r)))
stopifnot(nrow(rd[region == "HI"]) == 36L, all(!is.na(rd[region == "HI", visit5])))
# covariates constant within feeder; tCov the same for the three species rows
for (cc in c("cover", "bl", "gs", paste0("tCov", 1:4))) stopifnot(all(gr[, uniqueN(get(cc)), by = Feeder]$V1 == 1L))
tc <- as.matrix(gr[Species == "red", paste0("tCov", 1:4), with = FALSE]); vm <- as.matrix(gr[Species == "red", ..vis])
stopifnot(!anyNA(tc), all(tc %in% c("hair", "both")), all(tc[is.na(vm)] == "hair"))   # filled "hair" also where the visit is NA
# gs: the paper's GS covariate for red squirrel occupancy, undocumented; not the feeder's own share of grey detections
gm <- as.matrix(gr[Species == "grey", ..vis])
stopifnot(sum(abs(gr[Species == "grey", gs] - rowMeans(gm, na.rm = TRUE)) > 0.006, na.rm = TRUE) > 50L, all(rd[region == "HI", gs] == 0))

sp <- c(red = "SCIVUL", grey = "SCICAR", marten = "MARMAR")
fe <- gr[Species == "red"][order(region, cell, Feeder)]
y <- array(NA_integer_, c(nrow(fe), 4, 3), dimnames = list(fe$Feeder, NULL, unname(sp)))
for (s in names(sp)) { x <- gr[Species == s][match(fe$Feeder, Feeder)]; y[, , sp[s]] <- as.matrix(x[, ..vis]) }
xy <- tr[match(fe$Feeder, trapID)]
site_covs <- data.frame(region = fe$region, cover_prop = fe$cover, broadleaf_prop = fe$bl, x = as.numeric(xy$X), y = as.numeric(xy$Y))
meth <- as.matrix(fe[, paste0("tCov", 1:4), with = FALSE])
occ <- array_to_eco(y, site_ids = fe$Feeder, site_covs = site_covs, obs_covs = list(method = meth))
occ[, cluster_id := fe$cell[match(unit, fe$Feeder)]]
setcolorder(occ, c("unit", "taxon", "y", "occasion", "cluster_id"))
stopifnot(nrow(occ) == (187L * 4L - 21L) * 3L, uniqueN(occ$unit) == 186L, !anyNA(occ$obs_method), !anyNA(occ$cluster_id))
taxa_o <- make_taxa(unname(sp), c("Sciurus vulgaris", "Sciurus carolinensis", "Martes martes"),
                    vernacularName = c("Eurasian red squirrel", "Eastern grey squirrel", "European pine marten"))
taxa_o[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(all(taxa_o$taxon_iucnCategory == "LC"))
ds_o <- write_table(occ, T_OCC, c(list(
  title = "Red squirrel, grey squirrel and pine marten hair detections at 186 multi-species feeders in Central Scotland and the Scottish Borders, four visits January-May 2016",
  abstract = "Detection / non-detection of red squirrel (Sciurus vulgaris), introduced grey squirrel (Sciurus carolinensis) and pine marten (Martes martes) from hair on glue strips in baited multi-species feeders at 186 sites in 17 2 x 2 km grid cells in Central Scotland (10 cells) and the Scottish Borders (7), visited four times between January and May 2016. With proportion forest cover and proportion broadleaved cover within 100 m, and whether a camera was also deployed at the feeder on the visit. Collected to test whether the recovering native pine marten reverses the outcome of competition between red and grey squirrels.",
  samplingProtocol = "Permanently deployed baited multi-species feeders about 325 m apart within 2 x 2 km grid cells, visited about every four weeks; hair on the glue strips identified to species under a microscope; trail cameras rotated among a subset of feeders (obs_method = both on those visits) (Sheehy et al. 2018).",
  samplingProtocolCode = "hair_snag", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "the authors assume closure over the January-May visits",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Central Scotland (about 56.1 N, 4.4 W) and the Scottish Borders (55.7 N, 3.2 W), UK; feeder coordinates as unit_x / unit_y (EPSG:27700)",
  notes = "The Dryad file named for grey squirrels (S12) holds all three species for the CS and BO feeders; the red squirrel file (S11) repeats the red rows (identical) and adds the Highlands. obs_method is the paper's METHOD: hair = feeder only, both = feeder and camera. The deposit lists 187 CS and BO feeders; one (all four visits NA) was never surveyed and has no rows.",
  notShipped = list(`Highlands red squirrel rows` = "36 HI feeders x 5 visits of red squirrel only (S11): the deposit has no grey squirrel or marten rows for HI, and the feeder detects all three at once, so by the shared-detector ruling (2026-11-06) those surveys have no rows",
                    gs = "the paper's GS covariate for red squirrel occupancy (a grey squirrel measure, 0-1); how it was built is given neither in the deposit nor in the paper, and it is not the feeder's own share of grey detections, so it is not shipped without a definition",
                    `S11 coordinates` = "the same points to 0.0001 m; the trap file's whole metres are used",
                    `marten individual identities` = "shipped as sheehy_2018_scotland_marten_scr"))
  , common), taxa = taxa_o, script = SCRIPT)
stage_dict_row(T_OCC,
  description = "Hair-based detection / non-detection of red squirrel, grey squirrel and pine marten at 186 multi-species feeders in 17 grid cells in Central Scotland and the Scottish Borders, four visits January-May 2016, with forest and broadleaf cover and camera deployment per visit.",
  url = "https://doi.org/10.5061/dryad.478kp63", reference = ref,
  doi_paper = "10.1098/rspb.2017.2603", doi_data = "10.5061/dryad.478kp63",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Sibling of sheehy_2018_scotland_marten_scr (individual martens at the same feeders). Highlands feeders not shipped (red squirrel only in the deposit; shared-detector ruling).",
  source_via = "Dryad")
stage_tag_row(T_OCC, ds_o, taxon_group = "Mammals", model_family = "Community occupancy (single season)",
  sampling_protocol = "hair_snag", design = "Single-season (4 visits)", realm = "Terrestrial",
  country = "GBR", coordinates = "As published (EPSG:27700)",
  notes = "Native prey, invasive competitor and recovering predator at the same detectors; grid cell as cluster_id.")
