#!/usr/bin/env Rscript
# Tables: goldingay_2022_grafton_underpass_occ, goldingay_2022_port_underpass_occ
# Source: Dryad doi:10.5061/dryad.cvdncjt6m (CC0 1.0, as shown on the Dryad page). Goldingay,
#         R.L., Rohweder, D., Taylor, B.D. & Parkyn, J.L. Use of road underpasses by mammals and a
#         monitor lizard in eastern Australia and consideration of the prey-trap hypothesis.
# Paper:  Goldingay, R.L. et al. (2022). Ecology and Evolution, doi:10.1002/ece3.9075 (the README
#         gives the citation "in press"). Camera traps in road underpasses (U) and at random forest
#         sites (F) near the Pacific Motorway at Grafton (7 underpasses, 6 forest sites) and the
#         Oxley Highway at Port Macquarie (5 underpasses, 6 forest sites), NSW, 2013-2017; passes
#         collated per site and converted to weekly detection histories (README).
# Data:   one tab-separated file per species and location, <Species>_<Location>_detection_
#         histor(y|ies).txt: rows site1..siteN with the U/F label, columns weeks 1..201 (Grafton;
#         week 1 ends 7 March 2013) or 1..165 (Port; week 1 ends 24 June 2013); cells 1 detected, 0
#         not detected, "-" camera not installed or malfunctioning (two Port files also have empty
#         cells, read as "-"). The lace monitor files add a "season" row (spr/sum flag), not shipped.
#         README_Underpass-investigation.txt.
# Mapping (standard: community occupancy, E9 core): one table per location (different sites,
#   calendars and species lists). unit = the U/F label; taxon = species code; occasion = week;
#   date = the week's last day (from the README's anchor); y = the cell. Shared-detector ruling:
#   the cameras record every species at once, so a site-week that is "-" (or empty) for any species
#   is dropped for all (asserted small). unit_site_type = underpass / forest. closure = open
#   (weekly use over 3-4 years). Survey evidence: deposited_matrix ("-" marks no survey).
#   Taxa: "Bandicoots" pools Perameles nasuta and Isoodon macrourus (family Peramelidae); the Port
#   "Brushtail possum" file pools Trichosurus caninus and T. vulpecula (genus), the Grafton file is
#   the common brushtail possum. No species is IUCN threatened; no site coordinates deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
dir <- download_dryad("10.5061/dryad.cvdncjt6m", "goldingay_2022_nsw_underpass_mamm_occ")
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
SPP <- data.table(
  file = c("Bandicoots", "Cat", "Common_brushtail_possum", "Brushtail_possum", "Dingo-dog", "Eastern_grey_kangaroo", "Echidna", "Fox",
           "LaceMonitor", "Red-necked_pademelon", "Red-necked_wallaby", "Rufous_bettong", "SwampWallaby"),
  code = c("PERAMELIDAE", "FELCAT", "TRIVUL", "TRICHOSURUS", "CANFAM", "MACGIG", "TACACU", "VULVUL", "VARVAR", "THYTHE", "NOTRUF", "AEPRUF", "WALBIC"),
  sci = c("Peramelidae", "Felis catus", "Trichosurus vulpecula", "Trichosurus", "Canis familiaris", "Macropus giganteus", "Tachyglossus aculeatus",
          "Vulpes vulpes", "Varanus varius", "Thylogale thetis", "Notamacropus rufogriseus", "Aepyprymnus rufescens", "Wallabia bicolor"),
  vern = c("Bandicoots (long-nosed and northern brown)", "Feral cat", "Common brushtail possum", "Brushtail possums (northern mountain and common)",
           "Dingo / dog", "Eastern grey kangaroo", "Short-beaked echidna", "Red fox", "Lace monitor", "Red-necked pademelon", "Red-necked wallaby",
           "Rufous bettong", "Swamp wallaby"),
  rank = c("family", rep("species", 2), "genus", rep("species", 9)))
LOC <- list(grafton = list(name = "Grafton", nsite = 13L, nweek = 201L, end1 = as.IDate("2013-03-07"), nU = 7L),
            port = list(name = "Port", nsite = 11L, nweek = 165L, end1 = as.IDate("2013-06-24"), nU = 5L))
read_hist <- function(f, L) {
  x <- strsplit(readLines(f, warn = FALSE, encoding = "latin1"), "\t", fixed = TRUE)
  hdr <- x[[1]]; stopifnot(hdr[2] == "Weeks", identical(as.integer(hdr[3:(L$nweek + 2)]), seq_len(L$nweek)))
  r <- x[vapply(x, function(z) length(z) > 0 && startsWith(z[1], "site"), TRUE)]
  other <- x[vapply(x, function(z) length(z) > 0 && nzchar(z[1]) && !startsWith(z[1], "site"), TRUE)]
  stopifnot(length(r) == L$nsite, identical(vapply(r, `[`, "", 1), paste0("site", seq_len(L$nsite))),
            all(vapply(other, `[`, "", 1) == "season"))
  lab <- vapply(r, `[`, "", 2); stopifnot(identical(lab, c(paste0("U", seq_len(L$nU)), paste0("F", 1:6))))
  M <- t(vapply(r, function(z) { v <- z[3:(L$nweek + 2)]; v[is.na(v)] <- ""; v }, character(L$nweek)))
  stopifnot(all(M %in% c("0", "1", "-", "")))
  M[M == ""] <- "-"; rownames(M) <- lab; M
}
build <- function(key) {
  L <- LOC[[key]]; TABLE <- sprintf("goldingay_2022_%s_underpass_occ", key)
  fs <- list.files(dir, sprintf("_%s_detection_histor(y|ies)\\.txt$", L$name), recursive = TRUE, full.names = TRUE)
  sp <- sub(sprintf("_%s_detection_histor(y|ies)\\.txt$", L$name), "", basename(fs)); stopifnot(all(sp %in% SPP$file))
  M <- lapply(fs, read_hist, L = L); names(M) <- SPP$code[match(sp, SPP$file)]
  na_any <- Reduce(`|`, lapply(M, function(m) m == "-")); na_all <- Reduce(`&`, lapply(M, function(m) m == "-"))
  stopifnot(sum(na_any & !na_all) <= 40)   # the few cells "-" for some species only
  Y <- array(NA_integer_, dim = c(L$nsite, L$nweek, length(M)), dimnames = list(rownames(M[[1]]), NULL, names(M)))
  for (k in names(M)) { m <- M[[k]]; v <- suppressWarnings(as.integer(m)); v[as.vector(na_any)] <- NA; Y[, , k] <- matrix(v, L$nsite) }
  wk_end <- L$end1 + 7L * (seq_len(L$nweek) - 1L)
  long <- array_to_eco(Y, site_ids = rownames(M[[1]]))
  long[, `:=`(date = as.character(wk_end[occasion]), unit_site_type = ifelse(startsWith(unit, "U"), "underpass", "forest"))]
  long <- order_eco(long)
  stopifnot(nrow(long) == sum(!na_any) * length(M), sum(long$y) == sum(vapply(M, function(m) sum(m == "1" & !na_any), 0)))
  sel <- SPP[match(names(M), code)]
  taxa <- make_taxa(sel$code, sel$sci, vernacularName = sel$vern, taxonRank = sel$rank,
                    taxonRemarks = ifelse(sel$code == "PERAMELIDAE", "pools Perameles nasuta and Isoodon macrourus",
                                   ifelse(sel$code == "TRICHOSURUS", "pools Trichosurus caninus and T. vulpecula", NA)))
  place <- if (key == "grafton") "Pacific Motorway at Glenugie near Grafton (7 underpasses, 6 forest sites; 29.82 S, 153.04 E)" else
    "Oxley Highway at Port Macquarie (5 underpasses, 6 forest sites; 31.46 S, 152.84 E)"
  nU <- L$nU
  dataset <- list(
    title = sprintf("Weekly camera detections of %d mammal and lizard taxa at %d road underpasses and 6 forest sites, %s, NSW, %d weeks",
                    length(M), nU, if (key == "grafton") "Grafton" else "Port Macquarie", L$nweek),
    creator = "Goldingay, Ross L.; Rohweder, David; Taylor, Brendan D.; Parkyn, Jonathan L.", pubDate = "2022",
    doi = "10.5061/dryad.cvdncjt6m", sourceURL = "https://doi.org/10.5061/dryad.cvdncjt6m",
    citation = "Goldingay, R. L., Rohweder, D., Taylor, B. D., & Parkyn, J. L. (2022). Use of road underpasses by mammals and a monitor lizard in eastern Australia and consideration of the prey-trap hypothesis [Dataset]. Dryad. https://doi.org/10.5061/dryad.cvdncjt6m",
    paperDOI = "10.1002/ece3.9075",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Weekly detection/non-detection of macropods, bandicoots, possums, predators and the lace monitor from camera traps in road underpasses and at random forest sites along the %s, New South Wales, Australia, 2013-2017.", place),
    samplingProtocol = "Reconyx (and one KeepGuard) cameras inside underpasses and at random forest clearings within 100 m of the road; passes of each species collated per site (30-minute independence) and converted to weekly detection histories; weeks without a working camera marked missing.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
    closure = "open", closureNote = "weekly detections over three to four years; the authors compared the proportion of weeks used, not a closed-season occupancy",
    occasionKind = "time", taxonInclusion = "target",
    geographicCoverage = place, temporalCoverage = sprintf("%s/%s", wk_end[1] - 6L, wk_end[L$nweek]),
    notShipped = list(season_row = "the lace monitor files' spring/summer flag row (derivable from date)",
                      inconsistent_weeks = "site-weeks marked missing for some species but not others: dropped for all (shared-detector ruling)"),
    notes = "Forest cameras ran in different weeks from the underpass cameras (at Grafton they overlapped for 11 weeks), so most weeks have only one site type. taxonInclusion = target: the species analysed by the authors, not every species photographed.")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/goldingay_2022_nsw_underpass_mamm_occ.R")
  stage_dict_row(TABLE, description = sprintf("Weekly camera detections of mammals and the lace monitor in road underpasses and forest, %s, NSW, 2013-2017.", if (key == "grafton") "Grafton" else "Port Macquarie"),
    url = "https://doi.org/10.5061/dryad.cvdncjt6m", reference = "Goldingay, R. L., Rohweder, D., Taylor, B. D., & Parkyn, J. L. (2022). Use of road underpasses by mammals and a monitor lizard in eastern Australia and consideration of the prey-trap hypothesis. Ecology and Evolution.",
    doi_paper = "10.1002/ece3.9075", doi_data = "10.5061/dryad.cvdncjt6m", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "Road underpass use; weekly detections.", source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy (single season)",
    sampling_protocol = "camera_trap", design = sprintf("Single-season (%d weekly occasions over 3-4 years)", L$nweek), realm = "Terrestrial",
    country = "AUS", coordinates = "None in source", notes = "Road underpasses versus forest.")
}
for (k in names(LOC)) build(k)
