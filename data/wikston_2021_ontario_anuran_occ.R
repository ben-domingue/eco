#!/usr/bin/env Rscript
# Tables: wikston_2021_ontario_anuran_call_occ, wikston_2021_ontario_anuran_dipnet_occ, wikston_2021_ontario_anuran_ves_occ
# Source: Borealis (Canadian Dataverse) doi:10.5683/SP3/DCUGTW, released 2023-03-02, licence CC BY-NC 4.0 (the
#         dataset's license field, asserted from the cached dataset JSON; derived licence CC BY-NC 4.0).
#   Wikston, M., Wilson, C. & Murray, D. (2023). Amphibian detections via eDNA and conventional methods in southern
#   Ontario wetlands [Dataset]. Borealis.
# Paper:  Wikston, M. J. H. (2021). Comparative efficacy of eDNA and conventional methods for monitoring wetland
#         anuran communities [master's thesis]. Trent University, Peterborough, Ontario (the dataset's publication
#         field; not read).
# Data:   "raw and managed data for amphibian detections via Visual Encounter Surveys, Larval Dipnet Surveys, Breeding
#         Call Surveys, and qPCR-amplified eDNA samples. Data collected in southern Ontario in 2016."
#         Per method, a raw record file and a managed "SpeciesDetected_ByVisit" matrix (species x "<site>_<visit>",
#         0/1, no blanks; nine anuran codes AMTO, CHFR, GRFR, GRTR, NLFR, SPPE, WOFR, MIFR, AMBU):
#           BreedingCallSurveys_Raw (one row per species heard per visit: date, cloud, temperature, wind, noise,
#             abundance code 1-3) and _ByVisit: 30 sites x 3 visits = 90 site-visits;
#           DipnetSurveys_Raw and _ByVisit: 29 sites, 2 or 4 visits, 98 site-visits (site NMW "unable to be sampled
#             at all due to early-season drying" is in the raw file only, with no visit);
#           VisualEncounterSurveys_Raw and _ByVisit: 30 sites, 4 or 6 visits, 162 site-visits.
#         Every matrix column is a visit in the raw file (asserted), whose day, month and year give the date. The
#         raw files also record salamanders (AMBY, NEWT, SPOT, FOUR, REBA, ...), which the managed matrices omit.
#         eDNAdata_SummarybySite, Positive_qPCR_replicate_details, SummaryOfqPCRControls, Synthetic Oligonucleotides:
#         the eDNA arm (see notShipped). FieldSites2016 is restricted (author's permission) and was not requested.
# Mapping: one table per method (each method has its own visits, so each is a protocol with its own survey set,
#   ruling #31). unit = site code, taxon = the source's anuran code, occasion = visit number, date = the visit's date
#   from the raw file, y = the managed 0/1. No period (one season, 2016). surveyEvidence = deposited_matrix (the
#   managed matrix lists every visit). taxonInclusion = target: the nine anurans the managed matrices carry, all of
#   them, including taxa never detected by a method.
#   Not shipped: the eDNA arm (field and filter controls amplified for green frog in 3 of 68 controls, and the
#   eDNA summary has no filter day or date, so a blank cannot be matched to its sampling event as the eDNA ruling
#   needs: held in queue/human_review.csv); salamander records (raw files only; not in the managed matrices);
#   abundance codes and counts of the raw files (y is the authors' per-visit detection); visit weather (varies
#   within some visits in the raw files).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/wikston_2021_ontario_anuran_occ.R"; CACHE <- "wikston_2021_ontario_anuran_occ"
mf <- file.path(RAW_DIR, CACHE, "dataverse_dataset.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file("https://borealisdata.ca/api/datasets/:persistentId/?persistentId=doi:10.5683/SP3/DCUGTW",
                                    mf, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(mf)$data$latestVersion
stopifnot(identical(meta$license$name, "CC BY-NC 4.0"), nrow(meta$files) == 11L)
bf <- function(id, fn) download_cached(sprintf("https://borealisdata.ca/api/access/datafile/%d?format=original", id), CACHE, filename = fn)
codes <- data.table(taxon = c("GRFR", "GRTR", "NLFR", "AMTO", "WOFR", "CHFR", "SPPE", "MIFR", "AMBU"),
                    sci = c("Lithobates clamitans", "Hyla versicolor", "Lithobates pipiens", "Anaxyrus americanus", "Lithobates sylvaticus",
                            "Pseudacris maculata", "Pseudacris crucifer", "Lithobates septentrionalis", "Lithobates catesbeianus"),
                    vern = c("Green frog", "Grey treefrog", "Northern leopard frog", "American toad", "Wood frog",
                             "Boreal chorus frog", "Spring peeper", "Mink frog", "American bullfrog"))
taxa <- make_taxa(codes$taxon, codes$sci, vernacularName = codes$vern)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, scientificName, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
M <- list(call = list(raw = 352465L, rawf = "BreedingCallSurveys_Raw.csv", mat = 352474L, matf = "BreedingCallSurveys_SpeciesDetected_ByVisit.csv",
                      n = 90L, sites = 30L, code = "acoustic", label = "breeding call surveys",
                      proto = "Breeding (anuran) call surveys at wetland sites, three visits in spring 2016; species heard and their abundance code recorded; the managed matrix gives detection per visit."),
          dipnet = list(raw = 352463L, rawf = "DipnetSurveys_Raw.csv", mat = 352476L, matf = "DipnetSurveys_SpeciesDetected_ByVisit.csv",
                        n = 98L, sites = 29L, code = "dipnet", label = "larval dipnet surveys",
                        proto = "Timed larval dipnet surveys along the wetland edge, two or four visits per site in 2016; larvae identified to species; the managed matrix gives detection per visit."),
          ves = list(raw = 352478L, rawf = "VisualEncounterSurveys_Raw.csv", mat = 352477L, matf = "VisualEncounterSurveys_SpeciesDetected_ByVisit.csv",
                     n = 162L, sites = 30L, code = "visual_encounter", label = "visual encounter surveys",
                     proto = "Timed visual encounter surveys of the wetland, four or six visits per site in 2016; adults, juveniles and calls noted; the managed matrix gives detection per visit."))
for (k in names(M)) {
  S <- M[[k]]; TABLE <- sprintf("wikston_2021_ontario_anuran_%s_occ", k)
  r <- fread(bf(S$raw, S$rawf)); setnames(r, trimws(sub("^﻿", "", names(r))))
  m <- fread(bf(S$mat, S$matf))
  stopifnot(identical(names(m)[1], "Species"), setequal(m$Species, codes$taxon), ncol(m) - 1L == S$n)
  x <- as.matrix(m[, -1]); stopifnot(all(x %in% 0:1))
  r[, Month := c(apr = "Apr", april = "Apr", may = "May", june = "June", july = "July", august = "August")[tolower(Month)]]   # VES writes April / august
  v <- unique(r[!is.na(`Visit No.`), .(Code, V = `Visit No.`, Day, Month, Year)])
  v[, key := paste0(Code, "_", V)]
  stopifnot(!anyDuplicated(v$key), all(names(m)[-1] %in% v$key), all(v$Year == 2016L), all(v$Month %in% c("Apr", "May", "June", "July", "August")))
  v[, date := sprintf("2016-%02d-%02d", match(Month, c("Jan", "Feb", "Mar", "Apr", "May", "June", "July", "August")), Day)]
  long <- melt(m, id.vars = "Species", variable.name = "key", value.name = "y")
  long[, key := as.character(key)]
  long <- merge(long, v[, .(key, date)], by = "key")
  long[, `:=`(unit = sub("_[0-9]+$", "", key), occasion = as.integer(sub("^.*_", "", key)), taxon = Species, y = as.integer(y))]
  long[, c("key", "Species") := NULL]
  long <- order_eco(long)
  stopifnot(nrow(long) == S$n * 9L, uniqueN(long$unit) == S$sites, !anyDuplicated(long[, .(unit, taxon, occasion)]))
  cat(sprintf("  %s: %d rows, %d sites, %d site-visits, detections %d\n", TABLE, nrow(long), uniqueN(long$unit), S$n, sum(long$y)))
  others <- setdiff(sprintf("wikston_2021_ontario_anuran_%s_occ", names(M)), TABLE)
  dataset <- list(
    title = sprintf("Anuran detections by %s at %d wetlands in southern Ontario, %d site-visits, 2016", S$label, S$sites, S$n),
    creator = "Wikston, Madison; Wilson, Chris; Murray, Dennis", pubDate = "2023",
    doi = "10.5683/SP3/DCUGTW", sourceURL = "https://doi.org/10.5683/SP3/DCUGTW",
    citation = "Wikston, M., Wilson, C., & Murray, D. (2023). Amphibian detections via eDNA and conventional methods in southern Ontario wetlands [Dataset]. Borealis. https://doi.org/10.5683/SP3/DCUGTW",
    intellectualRights = list(spdx = "CC-BY-NC-4.0", url = "https://creativecommons.org/licenses/by-nc/4.0/"),
    abstract = sprintf("An MSc study comparing eDNA with conventional surveys (breeding call surveys, larval dipnet surveys and visual encounter surveys) for wetland anuran communities in southern Ontario wetlands in 2016. This table is one conventional method (%d wetlands); the managed per-visit detection matrices cover nine anuran species.", S$sites),
    samplingProtocol = S$proto, samplingProtocolCode = S$code, surveyEvidence = "deposited_matrix",
    responseType = "detection", unitKind = "site", closure = "closed",
    closureNote = "Occupancy assumed closed across the visits of the 2016 season. The other methods' visits are separate tables.",
    occasionKind = "time", taxonInclusion = "target",
    geographicCoverage = "Southern Ontario, Canada (site locations are in a restricted file of the deposit and are not shipped)",
    temporalCoverage = "2016-04/2016-08",
    notShipped = list(edna = "the eDNA arm: blanks cannot be matched to sampling events (held for review)",
                      salamanders = "salamander records in the raw files (not in the authors' managed matrices)",
                      raw_values = "abundance codes or counts and visit weather in the raw files",
                      site_locations = "FieldSites2016 is restricted by the author",
                      other_methods = paste("the other conventional methods are", paste(others, collapse = " and "))),
    notes = sprintf("Companion tables: %s.", paste(others, collapse = ", ")))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Detection of nine anuran species by %s at %d southern Ontario wetlands, 2016 (%d site-visits).", S$label, S$sites, S$n),
    url = "https://doi.org/10.5683/SP3/DCUGTW",
    reference = "Wikston, M. J. H. (2021). Comparative efficacy of eDNA and conventional methods for monitoring wetland anuran communities [master's thesis]. Trent University.",
    doi_paper = "", doi_data = "10.5683/SP3/DCUGTW", original_license = "CC BY-NC 4.0", derived_license = "CC BY-NC 4.0",
    notes = "One table per conventional method (separate survey sets); eDNA arm held.", source_via = "Borealis Dataverse (access API)")
  stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Community occupancy",
    sampling_protocol = S$code, design = sprintf("Single-season (%d sites, %s)", S$sites, k),
    realm = "Freshwater", country = "CAN", coordinates = "None in source", notes = "CC BY-NC 4.0.")
}
