#!/usr/bin/env Rscript
# Table:  wong_2022_sabah_acacia_mamm_comm
# Source: Dryad doi:10.5061/dryad.tqjq2bw30 (CC0 1.0, as shown on the Dryad page; published
#         2023-04-11). Wong, S.T. et al. Input data and model implementation from: How do
#         terrestrial wildlife communities respond to small-scale Acacia plantations embedded
#         in harvested tropical forest?
# Paper:  Wong, S.T., Guharajan, R., Petrus, A. et al. (2022). Ecology and Evolution 12(9),
#         doi:10.1002/ece3.9337. Camera-trap stations in two forest management units (Pasin and
#         Raplex FMU), Sabah, Malaysian Borneo, in natural forest and small Acacia plantations;
#         Bayesian community occupancy.
# Data:   modeldata.rds (README.txt): species (25 common names), det_hist (25 species x 142
#         stations x 31 occasions, 0/1, never NA), effort (142 x 31 camera-days per occasion,
#         1-10, NA = camera not operating), site (1 Pasin / 2 Raplex FMU), road (1 off-road /
#         2 at least one camera on-road), forest (1 natural / 2 planted), sci (structural
#         condition index), access (distance to road or large river), elevation, tri (all four
#         scaled). Quirk: det_hist is 0 where effort is NA (2,259 station-occasions), i.e. the
#         zeros there are not surveys (asserted no detection falls on them). No coordinates,
#         no dates.
# Mapping (standard: community occupancy, E9 core): unit = station S001-S142 (deposited order);
#   taxon = species code; occasion = sampling occasion 1..31 (blocks of up to 10 camera-days,
#   from the effort maximum); y = det_hist; obs_effort_days = effort (effortColumn).
#   Survey evidence: effort_table: a survey exists where effort is not NA (and > 0, asserted).
#   unit_: fmu, road setup, forest type, and the four scaled covariates as deposited.
#   Scientific names are the processor's, from the deposited common names; "Mongoose spp",
#   "Muntjac spp" and "Mousedeer spp" are kept at genus. Several taxa are IUCN CR/EN/VU (Sunda
#   pangolin CR; bay cat, pig-tailed and long-tailed macaques EN; sun bear, sambar, Hose's
#   civet, small-clawed otter VU); no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "wong_2022_sabah_acacia_mamm_comm"
dir <- download_dryad("10.5061/dryad.tqjq2bw30", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^modeldata\\.rds$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
x <- readRDS(f)
SP <- data.table(common = x$species,
  code = c("TRIFAS", "VIVTAN", "HERPES", "MACNEM", "RUSUNI", "HYSCRA", "MUNTIA", "ROLROU", "HELMAL", "MARFLA",
           "HEMDER", "PRIBEN", "MACFAS", "TRAGUL", "LOPIGN", "ARGARG", "CATBAD", "PARMAR", "RHEMAC", "HYSBRA",
           "PAGLAR", "MANJAV", "DIPHOS", "PARHER", "AONCIN"),
  sci = c("Trichys fasciculata", "Viverra tangalunga", "Herpestes", "Macaca nemestrina", "Rusa unicolor",
          "Hystrix crassispinis", "Muntiacus", "Rollulus rouloul", "Helarctos malayanus", "Martes flavigula",
          "Hemigalus derbyanus", "Prionailurus bengalensis", "Macaca fascicularis", "Tragulus", "Lophura ignita",
          "Argusianus argus", "Catopuma badia", "Pardofelis marmorata", "Rheithrosciurus macrotis", "Hystrix brachyura",
          "Paguma larvata", "Manis javanica", "Diplogale hosei", "Paradoxurus hermaphroditus", "Aonyx cinereus"))
stopifnot(identical(SP$common, c("Long-tailed porcupine", "Malay civet", "Mongoose spp", "Pig-tailed macaque", "Sambar deer",
  "Thick-spined porcupine", "Muntjac spp", "Crested wood partridge", "Sun bear", "Yellow-throated marten", "Banded civet",
  "Leopard cat", "Long-tailed macaque", "Mousedeer spp", "Crested fireback", "Great argus", "Bay cat", "Marbled cat",
  "Tufted ground squirrel", "Common porcupine", "Masked palm civet", "Sunda pangolin", "Hose's civet", "Common palm civet",
  "Asian small-clawed otter")))
y <- x$det_hist; E <- as.matrix(x$effort)
stopifnot(identical(dim(y), c(25L, 142L, 31L)), identical(dim(E), c(142L, 31L)), !anyNA(y), all(y %in% 0:1),
          all(E[!is.na(E)] >= 1 & E[!is.na(E)] <= 10), sum(is.na(E)) == 2259,
          all(apply(y, 1, function(m) all(m[is.na(E)] == 0))),
          all(lengths(x[c("site", "road", "forest", "sci", "access", "elevation", "tri")]) == 142))
ids <- sprintf("S%03d", 1:142)
Y <- aperm(y, c(2, 3, 1)); Y[rep(is.na(E), 25)] <- NA
dimnames(Y) <- list(ids, NULL, SP$code)
sc <- data.frame(fmu = c("Pasin", "Raplex")[x$site], road_setup = c("off-road", "on-road")[x$road],
                 forest_type = c("natural", "planted")[x$forest], sci_scaled = x$sci, access_scaled = x$access,
                 elevation_scaled = x$elevation, tri_scaled = x$tri)
stopifnot(!anyNA(sc))
long <- array_to_eco(Y, site_ids = ids, site_covs = sc, obs_covs = list(effort_days = E))
stopifnot(nrow(long) == sum(!is.na(E)) * 25, sum(long$y) == sum(y), all(long$obs_effort_days >= 1))
gen <- c("HERPES", "MUNTIA", "TRAGUL")
taxa <- make_taxa(SP$code, SP$sci, vernacularName = sub(" spp$", "", SP$common),
                  taxonRank = ifelse(SP$code %in% gen, "genus", "species"), allow_higher = setdiff(gen, "HERPES"), no_key = "HERPES",
                  taxonRemarks = ifelse(SP$code == "HERPES", "deposited as 'Mongoose spp'; genus Herpestes, no taxonID (GBIF reports multiple equal matches for the name)", ifelse(SP$code %in% gen, paste0("deposited as '", SP$common, "'"),
                                 ifelse(SP$code == "PRIBEN", "Bornean leopard cats are often placed in P. javanensis (Sunda leopard cat)",
                                 ifelse(SP$code == "HYSBRA", "deposited as 'Common porcupine' (Malayan porcupine)", NA)))))
dataset <- list(
  title = "Camera-trap detections of 25 mammal and ground-bird taxa at 142 stations in natural forest and Acacia plantations, Sabah, Borneo",
  creator = "Wong, Seth T.; Guharajan, Roshan; Petrus, Azrie; Jubili, Jaffly; Lietz, Robin; Abrams, Jesse F.; Hon, Jason; Alen, Lukmann; Ting, Nicholas; Wong, George; Tchin, Ling; Bijack, Nelson; Kramer-Schadt, Stephanie; Wilting, Andreas; Sollmann, Rahel",
  pubDate = "2023", doi = "10.5061/dryad.tqjq2bw30", sourceURL = "https://doi.org/10.5061/dryad.tqjq2bw30",
  citation = "Wong, S. T. et al. (2023). Input data and model implementation from: How do terrestrial wildlife communities respond to small-scale Acacia plantations embedded in harvested tropical forest? [Dataset]. Dryad. https://doi.org/10.5061/dryad.tqjq2bw30",
  paperDOI = "10.1002/ece3.9337",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of 25 terrestrial mammal and ground-dwelling bird taxa at 142 camera-trap stations in harvested natural forest and small Acacia plantations of the Pasin and Raplex forest management units, Sabah, Malaysian Borneo, in up to 31 sampling occasions with camera-days of effort per occasion, and station covariates.",
  samplingProtocol = "Camera-trap stations (one or two cameras, on or off road) in natural forest and Acacia plantation; detections summarised per sampling occasion of up to 10 camera-days, with the operating camera-days recorded per occasion.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "one deployment per station; the authors' single-season community occupancy",
  occasionKind = "time", taxonInclusion = "recorded", effortColumn = "obs_effort_days",
  geographicCoverage = "Pasin and Raplex Forest Management Units, Sabah, Malaysian Borneo; no coordinates deposited",
  temporalCoverage = "survey dates not stated in the deposit (paper 2022)",
  notShipped = list(zero_effort_cells = "2,259 station-occasions where effort is NA (camera not operating) but det_hist holds 0: not surveys, no rows"),
  notes = "Scientific names are the processor's, from the deposited common names; three taxa at genus. The taxa are those in the authors' model input (25), not necessarily every species photographed. Station ids follow the deposited order. Covariates sci, access, elevation and tri are scaled as deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/wong_2022_sabah_acacia_mamm_comm.R")
stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of 25 mammal and ground-bird taxa at 142 stations in natural forest and Acacia plantation, Sabah, Borneo, with camera-day effort per occasion.",
  url = "https://doi.org/10.5061/dryad.tqjq2bw30",
  reference = "Wong, S. T. et al. (2022). How do terrestrial wildlife communities respond to small-scale Acacia plantations embedded in harvested tropical forest? Ecology and Evolution, 12(9).",
  doi_paper = "10.1002/ece3.9337", doi_data = "10.5061/dryad.tqjq2bw30", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy with effort; zero-effort zeros dropped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season)",
  sampling_protocol = "camera_trap", design = "Single-season (up to 31 occasions of 10 camera-days)", realm = "Terrestrial",
  country = "MYS", coordinates = "None in source", notes = "Includes CR/EN/VU taxa; no coordinates deposited.")
