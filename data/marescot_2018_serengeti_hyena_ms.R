#!/usr/bin/env Rscript
# Tables: marescot_2018_serengeti_hyena_f_ms, marescot_2018_serengeti_hyena_m_ms
# Source: figshare doi:10.6084/m9.figshare.5840970.v1, published 2018-01-31, licence CC BY 4.0 (as shown on the
#         figshare item, asserted from the cached article JSON).
#   Benhaiem, S., Marescot, L., Gimenez, O., Hofer, H., Lebreton, J.-D. & Olarte-Castillo, X. A. (2018).
#   Capture-Mark-Recapture (CMR) datasets of Serengeti spotted hyenas infected with CDV [Dataset]. figshare.
# Paper:  Marescot, L., Benhaiem, S., Gimenez, O., Hofer, H., Lebreton, J.-D., Olarte-Castillo, X. A.,
#         Kramer-Schadt, S. & East, M. L. (2018). Social status mediates the fitness costs of infection with canine
#         distemper virus in Serengeti spotted hyenas. Functional Ecology 32, 1237-1250. doi:10.1111/1365-2435.13059.
#         Not read: the deposit's definition sheets give every code.
# Data:   "CMR_Datasets_Females and Males.xlsx", four sheets:
#         females_data: 625 females (ID1 ...), one column per year 1990-2010 (21), cell = event code 0-32;
#         females_states&events_def: codes 1-24 = age class (Cub, Subadult, Non-Breeder, Breeder) x social rank (Low,
#           High) x CDV infection status (Susceptible, Infected, Recovered); 25-32 = age x rank with infection status
#           Unknown (an observation of the individual whose infection status was not determined). 0 = not observed.
#         males_data: 815 males, codes 0-24; males_states&events_def: 1-18 = age (Cub, Pre-Breeder, Breeder) x rank x
#           status, 19-24 = age x rank, status unknown.
#         Every history has an observation (asserted); ids are unique within each sheet.
# Mapping (multi-event capture-recapture, responseType = state with the event codes; one table per sheet, since
#   the sexes have different state spaces and were deposited and analysed separately, ruling #31): unit = the
#   individual ("F_<id>" / "M_<id>"), taxon = CROCRO, period = year (1 = 1990 ... 21 = 2010), y = the event code.
#   At-risk span (E4.4): an individual first recorded as a cub (born in or near the study, its first record within
#   its first year) has rows from that year; one first recorded at an older age class has rows from 1990.
#   surveyEvidence = deposited_matrix. No coordinates; Crocuta crocuta IUCN LC.
#   Not shipped: the paper's multi-event estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/marescot_2018_serengeti_hyena_ms.R"; CACHE <- "marescot_2018_serengeti_hyena_ms"
mf <- file.path(RAW_DIR, CACHE, "figshare_article.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file("https://api.figshare.com/v2/articles/5840970", mf, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(mf)
stopifnot(identical(meta$license$name, "CC BY 4.0"), identical(meta$doi, "10.6084/m9.figshare.5840970.v1"),
          identical(meta$files$name, "CMR_Datasets_Females and Males.xlsx"))
f <- download_cached("https://ndownloader.figshare.com/files/10349481", CACHE, filename = "CMR_Datasets_Females_and_Males.xlsx")
stopifnot(identical(readxl::excel_sheets(f), c("females_data", "females_states&events_def", "males_data", "males_states&events_def")))
taxa <- make_taxa("CROCRO", "Crocuta crocuta", vernacularName = "Spotted hyena")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:21, year = 1990:2010)
sx <- list(f = list(sheet = "females_data", def = "females_states&events_def", n = 625L, K = 32L, cub = c(1:6, 25:26), lab = "female", pre = "F"),
           m = list(sheet = "males_data", def = "males_states&events_def", n = 815L, K = 24L, cub = c(1:6, 19:20), lab = "male", pre = "M"))
for (s in names(sx)) {
  S <- sx[[s]]; TABLE <- sprintf("marescot_2018_serengeti_hyena_%s_ms", s)
  x <- as.data.table(suppressMessages(readxl::read_excel(f, S$sheet, col_names = FALSE)))
  df <- as.data.table(suppressMessages(readxl::read_excel(f, S$def)))
  setnames(df, c("code", "definition", "abbrev"))
  yrs <- unlist(x[1, -1])
  stopifnot(identical(as.integer(yrs), 1990:2010), is.na(x[[1]][1]))
  x <- x[-1]; ids <- x[[1]]; H <- as.matrix(x[, -1]); H <- matrix(as.integer(H), nrow(H))
  stopifnot(nrow(H) == S$n, !anyDuplicated(ids), !anyNA(H), all(H %in% 0:S$K), all(rowSums(H > 0) > 0),
            identical(as.integer(df$code), 1:S$K), all(grepl("^Cub", df$definition[S$cub])),
            sum(grepl("^Cub", df$definition)) == length(S$cub))
  first <- apply(H > 0, 1, function(r) which(r)[1]); fst <- H[cbind(seq_len(nrow(H)), first)]
  start <- ifelse(fst %in% S$cub, first, 1L)
  long <- rbindlist(lapply(seq_len(nrow(H)), function(i) data.table(unit = paste0(S$pre, "_", ids[i]), period = start[i]:21L,
                                                                     y = H[i, start[i]:21L])))
  long[, taxon := "CROCRO"]
  long <- order_eco(long)
  stopifnot(sum(long$y > 0) == sum(H > 0), uniqueN(long$unit) == S$n)
  cat(sprintf("  %s: %d individuals (%d first seen as cubs), %d rows, %d observations\n", TABLE, S$n, sum(fst %in% S$cub), nrow(long), sum(long$y > 0)))
  codes <- c(list(`0` = "not observed"), setNames(as.list(sprintf("%s (%s)", df$definition, df$abbrev)), as.character(df$code)))
  dataset <- list(
    title = sprintf("Annual multi-event histories (age, social rank, canine distemper status) of %d %s spotted hyenas, Serengeti National Park, 1990-2010", S$n, S$lab),
    creator = "Benhaiem, Sarah; Marescot, Lucile; Gimenez, Olivier; Hofer, Heribert; Lebreton, Jean-Dominique; Olarte-Castillo, Ximena A.",
    pubDate = "2018", doi = "10.6084/m9.figshare.5840970.v1", sourceURL = "https://doi.org/10.6084/m9.figshare.5840970.v1",
    citation = "Benhaiem, S., Marescot, L., Gimenez, O., Hofer, H., Lebreton, J.-D., & Olarte-Castillo, X. A. (2018). Capture-Mark-Recapture (CMR) datasets of Serengeti spotted hyenas infected with CDV [Dataset]. figshare. https://doi.org/10.6084/m9.figshare.5840970.v1",
    paperDOI = "10.1111/1365-2435.13059",
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = sprintf("Yearly encounter histories of individually known %s spotted hyenas in three Serengeti clans, 1990-2010, each observation coded by age class, social rank and canine distemper virus (CDV) infection status (susceptible, infected, recovered, or unknown), used in a multi-event capture-recapture model of the fitness costs of CDV infection by social status.", S$lab),
    samplingProtocol = "Long-term individual-based monitoring of clan members, identified by their spot patterns, with non-invasive sampling to determine CDV infection status; observations pooled to one annual occasion and coded by age class, rank and infection status.",
    samplingProtocolCode = "photo_id", surveyEvidence = "deposited_matrix",
    responseType = "state", unitKind = "individual", stateCodes = codes,
    closure = "none", closureNote = "one annual occasion per year", occasionKind = "none", taxonInclusion = "single",
    designNote = "Multi-event: y is the observed event; codes with infection status Unknown are observations whose CDV status was not determined.",
    geographicCoverage = "Serengeti National Park, Tanzania (no locations deposited)", temporalCoverage = "1990/2010",
    notShipped = list(model_output = "the paper's survival, breeding and infection-transition estimates"),
    notes = sprintf("%s only; the other sex is marescot_2018_serengeti_hyena_%s_ms. Individuals first recorded as cubs have rows from that year; others from 1990 (E4.4).",
                    tools::toTitleCase(paste0(S$lab, "s")), if (s == "f") "m" else "f"))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Annual multi-event histories of %d %s spotted hyenas (Crocuta crocuta) in the Serengeti, 1990-2010, coded by age class, social rank and canine distemper status.", S$n, S$lab),
    url = "https://doi.org/10.6084/m9.figshare.5840970.v1",
    reference = "Marescot, L., Benhaiem, S., Gimenez, O., Hofer, H., Lebreton, J.-D., Olarte-Castillo, X. A., Kramer-Schadt, S. & East, M. L. (2018). Social status mediates the fitness costs of infection with canine distemper virus in Serengeti spotted hyenas. Functional Ecology 32, 1237-1250. https://doi.org/10.1111/1365-2435.13059",
    doi_paper = "10.1111/1365-2435.13059", doi_data = "10.6084/m9.figshare.5840970.v1",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0", notes = "One table per sex sheet (different state spaces).",
    source_via = "figshare (ndownloader)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Multi-event capture-recapture (disease and social states)",
    sampling_protocol = "photo_id", design = "Multi-season (21 years, 1990-2010)",
    realm = "Terrestrial", country = "TZA", coordinates = "None in source", notes = sprintf("%s only.", tools::toTitleCase(paste0(S$lab, "s"))))
}
