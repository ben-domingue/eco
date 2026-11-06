#!/usr/bin/env Rscript
# Tables: arango_2026_rhionaeschna_dry_cjs, arango_2026_rhionaeschna_rainy_cjs,
#         arango_2025_mesamphiagrion_apr_cjs, arango_2025_mesamphiagrion_junjul_cjs
# Sources (both CC BY 4.0 as shown on the figshare item, asserted from the cached article JSON):
#   Arango Quintero, S. & Bota-Sierra, C. A. (2026). Capture histories of the dragonfly Rhionaeschna caligo
#     Bota-Sierra, 2014 (Odonata: Aeshnidae) [Dataset]. figshare. doi:10.6084/m9.figshare.31120483.v1
#   Arango Quintero, S. & Bota-Sierra, C. A. (2025). Capture histories of the damselfly Mesamphiagrion
#     gaudiimontanum Bota-Sierra, 2013 (Odonata: Coenagrionidae) [Dataset]. figshare.
#     doi:10.6084/m9.figshare.30117457.v2
# Paper:  none linked. The item descriptions: species endemic to the high mountains of the Colombian Central (and,
#         for Rhionaeschna, Occidental) Cordillera; CJS capture-mark-recapture; a first season in April 2024 and a
#         second in June-July 2024 ("18 days" and "22 days of effective sampling" for Rhionaeschna; 21 and 23 for
#         Mesamphiagrion).
# Data:   tab-separated text files, one row per marked individual, the history in the last column as a 0/1 string,
#         one character per sampling day:
#         Rhionaeschna: "Dry season.txt" (192 individuals, 22 days) and "Rainy season.txt" (70, 18 days); columns
#           sex, wing (wing length, mm), wingcat (big / medium / small), ch. The description's April season has 18
#           days and the June-July season 22, but the files are labelled by season, not month; the tables follow
#           the file labels.
#         Mesamphiagrion: "Capture history (April).txt" (660, 21 days) and "Capture history (June-July).txt"
#           (1,591, 23 days); columns Sex, Age_class (Adult, Juvenile / Juvenil, Teneral), Acari (mites counted),
#           Wing_length (mm), Capture_history.
#         Every history has at least one capture; there are no individual ids, and the two seasons' files are not
#         linked, so each season is its own analysis set.
# Mapping (CJS, one table per species x season as deposited, ruling #31 on separate analysis sets): unit =
#   "<season>_<row>", taxon = the species code, period = sampling day 1..K (dates not deposited), y = 0/1.
#   At-risk span (E4.4): a teneral individual (newly emerged, the odonate's equivalent of marking at birth) has
#   rows from the day it was marked; adults and juveniles (immature, of unknown age) were at risk from day 1.
#   Covariates: unit_sex, unit_wing_mm, unit_wing_class (Rhionaeschna), unit_age_class (Juvenil recoded to
#   Juvenile), unit_acari (Mesamphiagrion), all as recorded at marking. surveyEvidence = deposited_matrix.
#   No coordinates deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/arango_odonata_andes_cjs.R"
fs_meta <- function(id, cache) {
  f <- file.path(RAW_DIR, cache, "figshare_article.json"); dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(f)) download.file(paste0("https://api.figshare.com/v2/articles/", id), f, quiet = TRUE, headers = c("User-Agent" = UA))
  fromJSON(f) }
deps <- list(
  rhio = list(id = 31120483, cache = "arango_2026_rhionaeschna_cjs", doi = "10.6084/m9.figshare.31120483.v1", year = "2026",
              taxon = "RHICAL", sci = "Rhionaeschna caligo", vern = "Rhionaeschna caligo (a darner)",
              title = "Capture histories of the dragonfly Rhionaeschna caligo Bota-Sierra, 2014 (Odonata: Aeshnidae)",
              files = list(dry = list(name = "Dry season.txt", fid = 61210696, n = 192L, K = 22L, label = "dry season"),
                           rainy = list(name = "Rainy season.txt", fid = 61210699, n = 70L, K = 18L, label = "rainy season")),
              range = "Colombian Central and Occidental Cordillera, Andes"),
  mesa = list(id = 30117457, cache = "arango_2025_mesamphiagrion_cjs", doi = "10.6084/m9.figshare.30117457.v2", year = "2025",
              taxon = "MESGAU", sci = "Mesamphiagrion gaudiimontanum", vern = "Mesamphiagrion gaudiimontanum (a damselfly)",
              title = "Capture histories of the damselfly Mesamphiagrion gaudiimontanum Bota-Sierra, 2013 (Odonata: Coenagrionidae)",
              files = list(apr = list(name = "Capture history (April).txt", fid = 58776667, n = 660L, K = 21L, label = "April 2024"),
                           junjul = list(name = "Capture history (June-July).txt", fid = 58776670, n = 1591L, K = 23L, label = "June-July 2024")),
              range = "Colombian Central Cordillera, Andes"))
for (dn in names(deps)) {
  D <- deps[[dn]]; m <- fs_meta(D$id, D$cache)
  stopifnot(identical(m$license$name, "CC BY 4.0"), identical(m$doi, D$doi),
            setequal(m$files$name, sapply(D$files, `[[`, "name")))
  taxa <- make_taxa(D$taxon, D$sci, vernacularName = D$vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  print(taxa[, .(taxon, gbifMatchType, taxon_iucnCategory)])
  for (sn in names(D$files)) {
    S <- D$files[[sn]]; TABLE <- sprintf("arango_%s_%s_%s_cjs", D$year, if (dn == "rhio") "rhionaeschna" else "mesamphiagrion", sn)
    f <- download_cached(sprintf("https://ndownloader.figshare.com/files/%d", S$fid), D$cache, filename = gsub("[ ()]+", "_", S$name))
    d <- fread(f, colClasses = "character"); setnames(d, trimws(names(d)))
    chc <- names(d)[ncol(d)]; ch <- d[[chc]]
    stopifnot(nrow(d) == S$n, all(nchar(ch) == S$K), all(grepl("^[01]+$", ch)), all(grepl("1", ch)))
    d[, (names(d)) := lapply(.SD, trimws)]
    if (dn == "rhio") {
      stopifnot(identical(names(d), c("sex", "wing", "wingcat", "ch")), all(d$sex %in% c("Male", "Female")),
                all(d$wingcat %in% c("big", "medium", "small")), !anyNA(as.numeric(d$wing)))
      cov <- d[, .(unit_sex = tolower(sex), unit_wing_mm = as.numeric(wing), unit_wing_class = wingcat)]
      teneral <- rep(FALSE, nrow(d))
    } else {
      stopifnot(identical(names(d), c("Sex", "Age_class", "Acari", "Wing_length", "Capture_history")),
                all(d$Sex %in% c("Male", "Female")), all(d$Age_class %in% c("Adult", "Juvenile", "Juvenil", "Teneral")),
                !anyNA(as.integer(d$Acari)), !anyNA(as.numeric(d$Wing_length)))
      cov <- d[, .(unit_sex = tolower(Sex), unit_age_class = tolower(sub("^Juvenil$", "Juvenile", Age_class)),
                   unit_acari = as.integer(Acari), unit_wing_mm = as.numeric(Wing_length))]
      teneral <- d$Age_class == "Teneral"
    }
    H <- do.call(rbind, strsplit(ch, ""))
    first <- apply(H == "1", 1, function(r) which(r)[1]); start <- ifelse(teneral, first, 1L)
    long <- rbindlist(lapply(seq_len(nrow(H)), function(i) cbind(data.table(unit = sprintf("%s_%04d", sn, i), period = start[i]:S$K,
                                                                             y = as.integer(H[i, start[i]:S$K])), cov[i])))
    long[, taxon := D$taxon]
    long <- order_eco(long)
    stopifnot(sum(long$y) == sum(H == "1"), uniqueN(long$unit) == S$n)
    cat(sprintf("  %s: %d individuals, %d days, %d rows, %d captures, %d teneral\n", TABLE, S$n, S$K, nrow(long), sum(long$y), sum(teneral)))
    periods <- data.table(period = seq_len(S$K), note = sprintf("sampling day %d of the %s season; date not deposited", seq_len(S$K), S$label))
    dataset <- list(
      title = sprintf("Daily capture histories of %d marked %s, %s, high Andes of Colombia, 2024", S$n, D$sci, S$label),
      creator = "Arango Quintero, Sebastian; Bota-Sierra, Cornelio Andres",
      pubDate = D$year, doi = D$doi, sourceURL = paste0("https://doi.org/", D$doi),
      citation = sprintf("Arango Quintero, S., & Bota-Sierra, C. A. (%s). %s [Dataset]. figshare. https://doi.org/%s", D$year, D$title, D$doi),
      intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
      abstract = sprintf("Capture-mark-recapture of %s, an odonate endemic to the high mountains of the %s, sampled daily in two seasons of 2024 (April and June-July) for Cormack-Jolly-Seber survival estimation. This table is the %s file (%d sampling days).", D$sci, D$range, S$label, S$K),
      samplingProtocol = "Daily capture, marking and recapture of adult odonates over a sampling season (days of effective sampling); sex, wing length and (for the damselfly) age class and mite load recorded at marking.",
      samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix",
      responseType = "detection", unitKind = "individual", closure = "none",
      closureNote = "Each sampling day is a period (CJS over days). The other season is a separate table with unlinked individuals.",
      occasionKind = "none", taxonInclusion = "single",
      geographicCoverage = sprintf("High mountains of the %s (no site or coordinates deposited)", D$range),
      temporalCoverage = "2024-04/2024-07",
      covariateNote = paste("unit_sex: male or female. unit_wing_mm: wing length (mm).",
                            if (dn == "rhio") "unit_wing_class: the source's wing-length class (big, medium, small)." else "unit_age_class: adult, juvenile (immature) or teneral (newly emerged), at marking. unit_acari: number of water mites on the individual at marking."),
      notShipped = list(dates = "the calendar dates of the sampling days are not deposited"),
      notes = paste("Teneral individuals have rows from the day they were marked; adults and juveniles from day 1 (E4.4).",
                    if (dn == "rhio") "The item description gives 18 days for April and 22 for June-July; the deposited files are labelled dry season (22 days) and rainy season (18 days)." else ""))
    ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
    stage_dict_row(TABLE,
      description = sprintf("Daily CJS capture histories of %d %s (%s), %s, Colombian Andes, 2024, with sex and wing length.", S$n, D$sci, if (dn == "rhio") "Aeshnidae" else "Coenagrionidae", S$label),
      url = paste0("https://doi.org/", D$doi), reference = "", doi_paper = "", doi_data = D$doi,
      original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
      notes = "One table per season file (separate analysis sets, no individual ids).", source_via = "figshare (ndownloader)")
    stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "CJS capture-recapture",
      sampling_protocol = "hand_capture", design = sprintf("Multi-session (%d daily occasions)", S$K),
      realm = "Terrestrial", country = "COL", coordinates = "None in source",
      notes = "Endemic high-Andean odonate; dates of days not deposited.")
  }
}
