#!/usr/bin/env Rscript
# Table:  frank_2017_costarica_bats_comm
# Source: Dryad doi:10.5061/dryad.mb552, version 5129 (2017-03-20), CC0 1.0 (Dryad licence field).
#   Frank, H. K., Frishkoff, L. O., Mendenhall, C. D., Daily, G. C. & Hadly, E. A. (2017). Data from:
#   Phylogeny, traits and biodiversity of a neotropical bat assemblage: close relatives show
#   similar responses to local deforestation. Dryad.
# Paper:  Frank et al. (2017). Phylogeny, traits, and biodiversity of a Neotropical bat assemblage:
#         close relatives show similar responses to local deforestation. The American Naturalist
#         190(2), 200-212, doi:10.1086/692534.
# Data:   array.rdata holds one list, my.data, documented in the Dryad usage notes:
#         X, a 0/1 capture array site (18) x year (2009-2013) x visit (1-3) x species (42), with
#         dimnames (site codes CAGO ... SATE, species as Genus_epithet); nrep, the number of visits
#         conducted at each site x year (1-3); D, pairwise distances between sites (km, 0-11); env,
#         the scaled and centred proportion of tree cover around each site (the deposit holds one
#         spatial scale; the radius is not stated); terrain, relative elevation of the site
#         compared with its surroundings (scaled); coffee.dummy, 1 if the site is a coffee field;
#         VCOV / ID / Tree / Ntree, phylogenetic covariance inputs for the model. X has no NA:
#         visits beyond nrep are padded with 0 (asserted to carry no capture). The two .R files
#         are the authors' JAGS models; they index visits as 1:nrep[site, yr].
#         5,011 captures (the abstract) collapse to 1,710 site x year x visit x species detections.
#
# Mapping (community occupancy, multi-season): unit = site code, taxon = Genus_epithet,
#   period = year (2009 = 1 ... 2013 = 5), occasion = visit, y = 1 if the species was captured
#   at that visit. Survey evidence: effort_table. nrep gives the visits conducted per site x year,
#   and a survey exists for visit <= nrep (185 visits); padded cells beyond nrep are not
#   surveys and get no row. Every species is a row at every survey (taxonInclusion = recorded).
#   Covariates as deposited: unit_coffee (coffee.dummy), unit_terrain_scaled (terrain),
#   unit_tree_cover_scaled (env).
#   Not shipped: D (pairwise site distances; no coordinates are deposited), the phylogenetic
#   inputs VCOV / ID / Tree (model inputs from published trees, not data about these surveys).
#   No dates are deposited. No coordinates, so E7 coarsening does not arise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "frank_2017_costarica_bats_comm"
dir <- download_dryad("10.5061/dryad.mb552", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("array.rdata", "model_notrait_for_supplement.R", "model_with_trait_for_supplement.R")))
e <- new.env(); load(file.path(dir, "array.rdata"), envir = e)
stopifnot(identical(ls(e), "my.data"))
d <- e$my.data
stopifnot(setequal(names(d), c("X", "VCOV", "ID", "D", "nsite", "nyr", "nsp", "nrep", "Ntree", "env", "terrain", "coffee.dummy", "Tree")))

# --- source facts ---------------------------------------------------------------------------
X <- d$X
stopifnot(identical(dim(X), c(18L, 5L, 3L, 42L)), identical(names(dimnames(X)), c("Site", "Year", "Visit", "Species")))
sites <- dimnames(X)$Site; years <- as.integer(dimnames(X)$Year); spp <- dimnames(X)$Species
stopifnot(identical(years, 2009:2013), identical(dimnames(X)$Visit, c("1", "2", "3")), !anyDuplicated(sites), !anyDuplicated(spp))
stopifnot(d$nsite == 18, d$nyr == 5, d$nsp == 42, !anyNA(X), all(X %in% 0:1), sum(X) == 1710)
nrep <- d$nrep
stopifnot(identical(dim(nrep), c(18L, 5L)), identical(dimnames(nrep)[[1]], sites), all(nrep %in% 1:3), sum(nrep) == 185)
pad <- 0; for (s in 1:18) for (y in 1:5) if (nrep[s, y] < 3) pad <- pad + sum(X[s, y, (nrep[s, y] + 1):3, ])
stopifnot(pad == 0)                                                       # padded visits carry no capture
stopifnot(length(d$env) == 18, length(d$terrain) == 18, all(d$coffee.dummy %in% 0:1), sum(d$coffee.dummy) == 6)
stopifnot(identical(dimnames(d$D)[[1]], sites))
stopifnot(all(grepl("^[A-Z][a-z]+_[a-z]+$", spp)))
# the model reads visits as 1:nrep[site, yr]
stopifnot(any(grepl("for(rep in 1:nrep[site, yr])", readLines(file.path(dir, "model_notrait_for_supplement.R")), fixed = TRUE)))

# --- long table: one row per conducted visit x species -------------------------------------
surveys <- rbindlist(lapply(1:18, function(s) rbindlist(lapply(1:5, function(y)
  data.table(si = s, yi = y, occasion = seq_len(nrep[s, y]))))))
stopifnot(nrow(surveys) == 185)
long <- surveys[rep(seq_len(.N), each = 42)][, ti := rep(1:42, times = nrow(surveys))]
long[, y := X[cbind(si, yi, occasion, ti)]]
long <- long[, .(unit = sites[si], taxon = spp[ti], period = yi, occasion, y = as.integer(y),
                 unit_coffee = as.integer(d$coffee.dummy[si]), unit_terrain_scaled = d$terrain[si], unit_tree_cover_scaled = d$env[si])]
long <- order_eco(long)
stopifnot(nrow(long) == 185 * 42, sum(long$y) == sum(X))
stopifnot(long[, .(n = sum(y)), by = .(unit, period, occasion)][, all(n >= 1)])   # every conducted visit caught a bat

periods <- data.table(period = 1:5, period_year = years, period_n_visits = as.integer(colSums(nrep)))
sci <- sub("_", " ", spp)
stopifnot(sum(sci == "Rhogeesa tumida") == 1)                            # source spelling of Rhogeessa tumida
taxa <- make_taxa(spp, sci, lookupName = sub("^Rhogeesa ", "Rhogeessa ", sci))
stopifnot(nrow(taxa) == 42)

dataset <- list(
  title = "Mist-net captures of 42 bat species at 18 forest and farmland sites in southern Costa Rica, 2009-2013, one to three visits per site per year",
  creator = "Frank, Hannah K.; Frishkoff, Luke O.; Mendenhall, Chase D.; Daily, Gretchen C.; Hadly, Elizabeth A.",
  pubDate = "2017", doi = "10.5061/dryad.mb552", sourceURL = "https://doi.org/10.5061/dryad.mb552",
  citation = "Frank, H. K., Frishkoff, L. O., Mendenhall, C. D., Daily, G. C., & Hadly, E. A. (2017). Data from: Phylogeny, traits and biodiversity of a neotropical bat assemblage: close relatives show similar responses to local deforestation [Data set]. Dryad. https://doi.org/10.5061/dryad.mb552",
  paperDOI = "10.1086/692534",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Five years (2009-2013) of bat mist-netting at 18 sites in a countryside landscape of southern Costa Rica, forest and farmland including coffee (Frank et al. 2017, American Naturalist; Daily and Hadly labs, Stanford). 5,011 captures, collapsed by the authors to whether each species was caught at each visit; every site was visited three times in 2009, and one to three times in later years. Site covariates as deposited: whether the site is a coffee field, relative elevation (scaled) and tree cover (scaled; one spatial scale). The authors fit a phylogenetic multi-species occupancy model to these detections.",
  samplingProtocol = "Mist nets at fixed sites, one to three netting visits per site per year; captured bats identified to species; detections are capture (1) or no capture (0) of a species at a visit (Frank et al. 2017, Am Nat 190:200).",
  samplingProtocolCode = "mist_net", surveyEvidence = "effort_table",
  surveyEvidenceNote = "nrep in the deposit gives the visits conducted per site x year (1-3; 185 in all); a survey exists for visit <= nrep. The capture array pads later visits with 0, which carry no capture (asserted) and are not surveys.",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = "occasion = netting visit within a year; period = year",
  geographicCoverage = "Southern Costa Rica countryside: 18 sites within about 11 km of one another; no coordinates deposited",
  temporalCoverage = "2009/2013",
  notShipped = list(D = "pairwise distances between sites (km); a spatial model input, and no coordinates are deposited",
                    `VCOV, ID, Tree, Ntree` = "phylogenetic covariance inputs for the model, built from published trees"),
  notes = "No dates are deposited. unit_tree_cover_scaled is env as deposited: the scaled and centred proportion of tree cover at one spatial scale whose radius the deposit does not state. Site codes are the authors'.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/frank_2017_costarica_bats_comm.R")

stage_dict_row(TABLE,
  description = "Mist-net detection / non-detection of 42 bat species at 18 forest and farmland sites (6 coffee) in southern Costa Rica, 2009-2013 (185 netting visits, one to three per site per year), with coffee, terrain and tree-cover covariates.",
  url = "https://doi.org/10.5061/dryad.mb552",
  reference = "Frank, H. K., Frishkoff, L. O., Mendenhall, C. D., Daily, G. C., & Hadly, E. A. (2017). Phylogeny, traits, and biodiversity of a Neotropical bat assemblage: close relatives show similar responses to local deforestation. The American Naturalist, 190(2), 200-212.",
  doi_paper = "10.1086/692534", doi_data = "10.5061/dryad.mb552",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Built from the deposited JAGS input array (array.rdata); visits per site-year (nrep) are the survey set. Site distances and phylogenetic inputs not shipped. Fetched as the Dryad version zip.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "mist_net", design = "Multi-season (5 years x 1-3 visits; 18 sites)",
  realm = "Terrestrial", country = "CRI", coordinates = "None in source",
  notes = "Bats; forest and coffee countryside, Daily / Hadly labs (Stanford).", status = "tagged")
