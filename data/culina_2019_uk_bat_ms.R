#!/usr/bin/env Rscript
# Tables: culina_2019_uk_daubenton_ms, culina_2019_uk_natterer_ms
# Source: Zenodo doi:10.5281/zenodo.2222410, published 2018-12-12, licence CC BY 4.0 (record metadata licence id
#         "cc-by-4.0", asserted from the cached record JSON).
#   Culina, A., Linton, D. M., Pradel, R., Bouwhuis, S. & Macdonald, D. W. (2018). Dataset (encounter histories of
#   female bats) used in the analysis for the paper Culina et al.: Live fast, don't die young: survival-reproduction
#   trade-offs in long-lived income breeders [Dataset]. Zenodo.
# Paper:  Culina, A., Linton, D. M., Pradel, R., Bouwhuis, S. & Macdonald, D. W. (2019). Live fast, don't die young:
#         Survival-reproduction trade-offs in long-lived income breeders. Journal of Animal Ecology 88, 746-756.
#         doi:10.1111/1365-2656.12957. The deposit's readme defines the event codes; the paper was not needed.
# Data:   readme.txt: a multi-event model with eight life-cycle states; each female's history has one event code per
#         year, 2007 to 2015 (nine years), coded from early (pregnancy) and late (post-parturition) maternity-period
#         observations:
#           0 not captured; 1 captured lactating (SB1, SB2+); 2 captured pregnant, not captured late (FB1, FB2+, SB1,
#           SB2+); 3 captured pregnant, then captured not lactating (FB1, FB2+); 4 not captured early, captured not
#           lactating (PB, FB1, FB2+, Skip); 5 captured not pregnant (or not captured) early, captured not lactating
#           late (PB, Skip); 6 contradictory or uncertain information (any live state); 7 captured as juvenile.
#         Md_capture_H.txt (Myotis daubentonii, 583 females) and Mn_capture_H.txt (Myotis nattereri, 474 females),
#         tab-separated: H (history, 9 characters), S (frequency, all 1), $COV:social_group (ga-gf for Md, g1-g7
#         for Mn), $COV:first_capture_age (a juvenile, b adult). Code 7 occurs only at first capture and exactly for
#         the 'a' females (asserted).
# Mapping (multi-event capture-recapture: responseType = state with the event codes, one table per species, ruling
#   #20): unit = the female ("<species>_<row>"), taxon = MYODAU / MYONAT, period = year (1 = 2007 ... 9 = 2015),
#   y = the event code (0-7) as deposited, stateCodes from the readme. At-risk span (E4.4): a female first caught as a
#   juvenile (code 7, born that season) has rows from that year; one first caught as an adult (wild, unknown age)
#   from 2007. unit_social_group, unit_first_capture_age as deposited. surveyEvidence = deposited_matrix (one
#   annual occasion per year for every female; MARK-style histories have no missing cells).
#   No coordinates deposited. Both species IUCN LC.
#   Not shipped: the paper's multi-event model estimates (model output). Males are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/culina_2019_uk_bat_ms.R"
REC <- "2222410"; CACHE <- "culina_2019_uk_bat_ms"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), CACHE, filename = key)
meta_f <- file.path(RAW_DIR, CACHE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.2222410"),
          setequal(meta$files$key, c("Mn_capture_H.txt", "Md_capture_H.txt", "readme.txt")))
invisible(zen("readme.txt"))
YEARS <- 2007:2015
codes <- list(`0` = "not captured (all states possible, including dead)",
              `1` = "captured lactating, early capture pregnant or none (successful breeder: SB1, SB2+)",
              `2` = "captured pregnant early, not captured or unreliable late (FB1, FB2+, SB1, SB2+)",
              `3` = "captured pregnant early, captured not lactating late (failed breeder: FB1, FB2+)",
              `4` = "not captured or unreliable early, captured not lactating late (PB, FB1, FB2+, Skip)",
              `5` = "captured not pregnant or not captured early, captured not lactating late (pre-breeder or skipper: PB, Skip)",
              `6` = "contradictory or uncertain information (any live state)",
              `7` = "captured as a juvenile (born in the current season)")
sp <- list(
  daubenton = list(file = "Md_capture_H.txt", taxon = "MYODAU", sci = "Myotis daubentonii", vern = "Daubenton's bat", n = 583L,
                   groups = paste0("g", letters[1:6]), juv = 280L),
  natterer  = list(file = "Mn_capture_H.txt", taxon = "MYONAT", sci = "Myotis nattereri", vern = "Natterer's bat", n = 474L,
                   groups = paste0("g", 1:7), juv = 203L))
for (s in names(sp)) {
  S <- sp[[s]]; TABLE <- sprintf("culina_2019_uk_%s_ms", s)
  d <- fread(zen(S$file), colClasses = "character")
  stopifnot(identical(names(d), c("H:", "S:", "$COV:social_group", "$COV:first_capture_age")), nrow(d) == S$n,
            all(d[["S:"]] == "1"), all(nchar(d[["H:"]]) == 9L), all(grepl("^[0-7]+$", d[["H:"]])),
            setequal(d[["$COV:social_group"]], S$groups), all(d[["$COV:first_capture_age"]] %in% c("a", "b")))
  H <- do.call(rbind, strsplit(d[["H:"]], ""))
  first <- apply(H != "0", 1, function(r) which(r)[1]); fst <- H[cbind(seq_len(nrow(H)), first)]
  stopifnot(!anyNA(first), sum(H == "7") == S$juv, identical(fst == "7", d[["$COV:first_capture_age"]] == "a"))
  start <- ifelse(fst == "7", first, 1L)
  long <- rbindlist(lapply(seq_len(nrow(H)), function(i) data.table(unit = sprintf("%s_%03d", S$taxon, i), period = start[i]:9L,
                    y = as.integer(H[i, start[i]:9L]), unit_social_group = d[["$COV:social_group"]][i],
                    unit_first_capture_age = ifelse(d[["$COV:first_capture_age"]][i] == "a", "juvenile", "adult"))))
  long[, taxon := S$taxon]
  long <- order_eco(long)
  stopifnot(sum(long$y > 0) == sum(H != "0"), uniqueN(long$unit) == S$n, !anyDuplicated(long[, .(unit, period)]))
  cat(sprintf("  %s: %d females, %d rows, %d encounters\n", s, S$n, nrow(long), sum(long$y > 0)))
  taxa <- make_taxa(S$taxon, S$sci, vernacularName = S$vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
  periods <- data.table(period = 1:9, year = YEARS)
  dataset <- list(
    title = sprintf("Multi-event reproductive encounter histories of %d female %s, %d social groups, 2007-2015", S$n, S$vern, length(S$groups)),
    creator = "Culina, Antica; Linton, Danielle M.; Pradel, Roger; Bouwhuis, Sandra; Macdonald, David W.",
    pubDate = "2018", doi = "10.5281/zenodo.2222410", sourceURL = "https://doi.org/10.5281/zenodo.2222410",
    citation = "Culina, A., Linton, D. M., Pradel, R., Bouwhuis, S., & Macdonald, D. W. (2018). Dataset (encounter histories of female bats) used in the analysis for the paper Culina et al.: Live fast, don't die young: survival-reproduction trade-offs in long-lived income breeders [Dataset]. Zenodo. https://doi.org/10.5281/zenodo.2222410",
    paperDOI = "10.1111/1365-2656.12957",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("Annual encounter histories of female %s (%s) in %d social groups, 2007-2015, each year's capture coded as an event that relates early (pregnancy) and late (lactation) maternity-period observations to the female's reproductive state. The authors fitted a multi-event capture-recapture model with eight states (juvenile, pre-breeder, failed and successful first-time and experienced breeders, skipped breeder, dead) to estimate survival-reproduction trade-offs.", S$vern, S$sci, length(S$groups)),
    samplingProtocol = "Females captured during the maternity period each year and assessed for reproductive condition (weight and/or examination for pregnancy, nipple condition: nulliparous, lactating, post-lactating, parous non-breeding); the year's observations are summarised as one event code.",
    samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
    responseType = "state", unitKind = "individual", stateCodes = codes,
    closure = "none", closureNote = "One annual occasion per year (the year's captures summarised as one event by the authors).",
    occasionKind = "none", taxonInclusion = "single",
    designNote = "Multi-event capture-recapture: y is the event code, not the latent state; the readme's table maps each event to its possible states (in stateCodes).",
    geographicCoverage = "United Kingdom: social groups of two sympatric Myotis species (no locations deposited)",
    temporalCoverage = "2007/2015",
    covariateNote = "unit_social_group: the social group (colony) of the female, as coded in the deposit. unit_first_capture_age: juvenile (born in the year of first capture) or adult.",
    notShipped = list(model_output = "the paper's multi-event survival and transition estimates",
                      males = "males are not in the deposit"),
    notes = "Females only. A female first caught as a juvenile has rows from that year; one first caught as an adult from 2007 (E4.4).")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Multi-event (reproductive state) annual encounter histories of %d female %s (%s), 2007-2015, with social group and age at first capture.", S$n, S$vern, S$sci),
    url = "https://doi.org/10.5281/zenodo.2222410",
    reference = "Culina, A., Linton, D. M., Pradel, R., Bouwhuis, S. & Macdonald, D. W. (2019). Live fast, don't die young: Survival-reproduction trade-offs in long-lived income breeders. Journal of Animal Ecology 88, 746-756. https://doi.org/10.1111/1365-2656.12957",
    doi_paper = "10.1111/1365-2656.12957", doi_data = "10.5281/zenodo.2222410",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = "One table per species (ruling #20); event codes as deposited.",
    source_via = "Zenodo (file API)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-event capture-recapture (reproductive states)",
    sampling_protocol = "live_trap", design = "Multi-season (9 years, 2007-2015)",
    realm = "Terrestrial", country = "GBR", coordinates = "None in source",
    notes = "Event codes summarise early and late maternity-period observations.")
}
