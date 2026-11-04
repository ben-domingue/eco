#!/usr/bin/env Rscript
# Tables: martinezvillegas_2024_flaveria_cjs, martinezvillegas_2024_mammillaria_cjs,
#         martinezvillegas_2024_neobuxbaumia_cjs, martinezvillegas_2024_govenia_cjs,
#         martinezvillegas_2024_castilleja_cjs: one deposit, five marked plant species, one table per
#         taxon (ruling #20: unitKind = individual tables carry one taxon each).
# Source: Dryad doi:10.5061/dryad.b5mkkwhnk, version 307942 (published 2024-07-29), licence CC0 1.0 (as
#         shown on Dryad). Martinez-Villegas, J.A., Pisanty, I., Martorell, C., Hernandez-Apolinar, M.,
#         Valverde, T., Granados-Hernandez, L.A., Rodriguez-Sanchez, M. & Zuniga-Vega, J.J. Data from:
#         Importance of accounting for imperfect detection of plants in the estimation of population
#         growth rates.
# Paper:  Martinez-Villegas, J.A. et al. (2024). Importance of accounting for imperfect detection of
#         plants in the estimation of population growth rates. Oikos 2024(12), e10708.
#         doi:10.1111/oik.10708 (paywalled; the abstract says the histories are field data of five
#         plant species, analysed with temporal-symmetry (Pradel) models; census years and sites are
#         not in the deposit).
# Data:   Data_(Martinez-Villegas_et_al.).zip inside the Dryad zip, five Program MARK .inp files
#         (CRLF), named by the first four letters of genus and epithet:
#           /* <species> */ header line, then one line per individual: <history>  <freq>;
#         Flav_chlo (Flaveria chlorifolia) 12 censuses, 809 individuals; Mamm_hern (Mammillaria
#         hernandezii) 5, 1,139; Neob_macr (Neobuxbaumia macrocephala) 6, 211; Gove_lage (Govenia
#         lagenophora, an orchid) 4, 319; Cast_tenu (Castilleja tenuiflora) 9, 271 (the last line of each file has no newline). Every freq is 1
#         (one line per individual; asserted) and every history has at least one 1. One Govenia line
#         is typed "11O0" with a capital letter O for a zero; read as 1100 (asserted: exactly one).
#         README.md describes the columns.
#
# Mapping (standard E9 core, CJS / Pradel; as toledolima_2024_elaenia_cjs): unit = individual (the
#   line number within the species' file; the deposit has no tag ids), taxon = 6-letter code,
#   period = census 1..T (annual censuses per the paper; calendar years not deposited, so no
#   `date` and __periods carries only the index), y = 0/1 (detected above ground at the census).
#   No `occasion` (one census per period). Rows before first detection are kept as 0, the full
#   individual x census rectangle the history strings give (E4.4: plants first found after census 1
#   are wild of unknown age, since the deposit and README say nothing of seedlings or age at marking,
#   so they are at risk from census 1; no lost tags recorded; every history has a 1). Survey evidence: deposited_matrix (the
#   0s inside MARK histories are censuses at which the marked plant was not found).
#   No losses on capture (no negative freq). No coordinates or covariates deposited; Mammillaria
#   hernandezii is IUCN EN (GBIF) but there is nothing to coarsen.
#   Not shipped: nothing in the deposit (the simulation inputs in the paper are not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/martinezvillegas_2024_plants_cjs.R"
CACHE <- "martinezvillegas_2024_plants_cjs"
dir <- download_dryad("10.5061/dryad.b5mkkwhnk", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
inner <- list.files(dir, pattern = "\\.zip$", full.names = TRUE); stopifnot(length(inner) == 1L)
idir <- file.path(dir, "inp"); if (!dir.exists(idir)) unzip(inner, exdir = idir)

spp <- data.table(
  file = c("Flav_chlo.inp", "Mamm_hern.inp", "Neob_macr.inp", "Gove_lage.inp", "Cast_tenu.inp"),
  sci = c("Flaveria chlorifolia", "Mammillaria hernandezii", "Neobuxbaumia macrocephala", "Govenia lagenophora", "Castilleja tenuiflora"),
  code = c("FLACHL", "MAMHER", "NEOMAC", "GOVLAG", "CASTEN"),
  table = paste0("martinezvillegas_2024_", c("flaveria", "mammillaria", "neobuxbaumia", "govenia", "castilleja"), "_cjs"),
  Tn = c(12L, 5L, 6L, 4L, 9L), n = c(809L, 1139L, 211L, 319L, 271L),
  family = c("Asteraceae", "Cactaceae", "Cactaceae", "Orchidaceae", "Orobanchaceae"),
  form = c("gypsophilous shrub", "small globose cactus", "columnar cactus", "terrestrial orchid", "hemiparasitic herb"),
  iucn = c("NE", "EN", "LC", "NE", "NE"))          # GBIF iucnRedListCategory, checked 2026-11-02
stopifnot(all(file.exists(file.path(idir, spp$file))))
common <- list(
  creator = "Martinez-Villegas, Jorge A.; Pisanty, Irene; Martorell, Carlos; Hernandez-Apolinar, Mariana; Valverde, Teresa; Granados-Hernandez, Luisa A.; Rodriguez-Sanchez, Mariana; Zuniga-Vega, Jaime J.",
  pubDate = "2024", doi = "10.5061/dryad.b5mkkwhnk", sourceURL = "https://doi.org/10.5061/dryad.b5mkkwhnk",
  citation = "Martinez-Villegas, J. A., Pisanty, I., Martorell, C., Hernandez-Apolinar, M., Valverde, T., Granados-Hernandez, L. A., Rodriguez-Sanchez, M., & Zuniga-Vega, J. J. (2024). Data from: Importance of accounting for imperfect detection of plants in the estimation of population growth rates [Dataset]. Dryad. https://doi.org/10.5061/dryad.b5mkkwhnk",
  paperDOI = "10.1111/oik.10708",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Censuses of individually marked plants in permanent study populations in Mexico; at each census every marked plant is searched for and recorded as found (1) or not found (0). Program MARK input for temporal-symmetry (Pradel) models.",
  samplingProtocolCode = "marked_plant_census", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "individual", closure = "none", closureNote = "period (one census per period; survival and recruitment between censuses)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Mexico (study populations not located in the deposit; no coordinates deposited)",
  temporalCoverage = "annual censuses (4 to 12 per species) before 2024; calendar years not stated in the deposit", coordinatesCoarsened = NA)

for (i in seq_len(nrow(spp))) {
  r <- spp[i]
  L <- readLines(file.path(idir, r$file), warn = FALSE); L <- trimws(sub("\r$", "", L)); L <- L[nzchar(L)]
  stopifnot(L[1] == sprintf("/* %s */", r$sci))
  L <- L[-1]
  typo <- grepl("O", L)
  stopifnot(sum(typo) == as.integer(r$code == "GOVLAG"))
  if (any(typo)) { stopifnot(L[typo] == "11O0  1;"); L[typo] <- "1100  1;" }
  m <- regmatches(L, regexec("^([01]+)\\s+(-?[0-9]+);$", L))
  stopifnot(all(lengths(m) == 3L))
  ch <- sapply(m, `[`, 2); fq <- as.integer(sapply(m, `[`, 3))
  stopifnot(length(ch) == r$n, all(nchar(ch) == r$Tn), all(fq == 1L), all(grepl("1", ch)))
  CH <- do.call(rbind, lapply(strsplit(ch, ""), as.integer))
  ids <- sprintf("%s_%04d", r$code, seq_len(r$n))
  long <- array_to_eco(CH, taxon = r$code, site_ids = ids, period = seq_len(r$Tn))
  long[, occasion := NULL]
  stopifnot(nrow(long) == r$n * r$Tn, sum(long$y) == sum(CH))
  taxa <- make_taxa(r$code, r$sci, taxon_family = r$family, taxon_growthForm = r$form, taxon_iucnCategory = r$iucn)
  periods <- data.table(period = seq_len(r$Tn), note = "annual census; calendar year not deposited",
                        n_detected = colSums(CH), n_first_detected = tabulate(apply(CH, 1, function(h) which(h == 1L)[1]), r$Tn))
  ds <- write_table(long, r$table, c(common, list(
    title = sprintf("Census histories of %d individually marked %s plants over %d censuses, Mexico", r$n, r$sci, r$Tn),
    abstract = sprintf("Detection histories (found / not found at each census) of %d individually marked %s (%s, %s) over %d censuses, one of five plant species used by Martinez-Villegas et al. (2024) to show that plant detection is imperfect and that ignoring it biases population growth rates; analysed there with temporal-symmetry (Pradel) models.", r$n, r$sci, r$family, r$form, r$Tn),
    notes = paste0("Individuals are numbered by line in the MARK file (no tag ids deposited). Census years, study site and plot structure are not in the deposit (see the paper).",
                   if (r$code == "GOVLAG") " One history typed '11O0' (letter O) in the deposit is read as 1100." else "",
                   if (r$iucn %in% c("CR", "EN", "VU")) sprintf(" IUCN %s (flagged under E7); no coordinates deposited, so nothing to coarsen.", r$iucn) else ""),
    components = as.list(setdiff(spp$table, r$table)))),
    taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(r$table,
    description = sprintf("Capture-recapture (CJS / Pradel) census histories of %d individually marked %s (%s) over %d censuses in Mexico, from Program MARK input; found / not found at each census.", r$n, r$sci, r$form, r$Tn),
    url = "https://doi.org/10.5061/dryad.b5mkkwhnk",
    reference = "Martinez-Villegas, J. A., et al. (2024). Importance of accounting for imperfect detection of plants in the estimation of population growth rates. Oikos, 2024(12), e10708.",
    doi_paper = "10.1111/oik.10708", doi_data = "10.5061/dryad.b5mkkwhnk", original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = "One of five per-species tables from one deposit; census years not deposited (period index only).", source_via = "Dryad")
  stage_tag_row(r$table, ds, taxon_group = "Plants", model_family = "CJS capture-recapture (marked plants; Pradel in the paper)",
    sampling_protocol = "marked_plant_census", design = sprintf("Multi-session (%d annual censuses, no secondary)", r$Tn),
    realm = "Terrestrial", country = "MEX", coordinates = "None in source",
    notes = sprintf("Marked %s; individuals numbered by file line.", r$form), status = "tagged")
}
