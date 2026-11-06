#!/usr/bin/env Rscript
# Table:  ruiz_2021_oaxaca_wetbirds_count
# Source: Dryad doi:10.5061/dryad.x95x69pk6 (source of record), CC0 1.0, published 2021-10-31, fetched from its
#         Zenodo mirror (record 5635554, which carries the Dryad DOI; licence id "cc-zero", asserted). No request
#         was made to Dryad.
#   Ruiz, M. D. M. (2021). Thirty-six consecutive months of bird point count data from twenty count sites in a
#   Mexican wetland [Dataset]. Dryad.
# Paper:  Ruiz, M. D. M. & Rangel Salazar, J. L. (2022). Guild-level response to Hurricane Carlotta among birds in a
#         Mexican wetland. Ibis 164, 587-595. doi:10.1111/ibi.13028. Not needed: the readme states the design.
# Data:   READ_ME_Ruiz_Rangel.txt: point-count abundances of birds over 36 consecutive months (June 2010 to May 2013)
#         at 20 point-count sites in a coastal lagoon in Oaxaca, southwest Mexico (15 49' N, 96 34' W); 24 months
#         before Hurricane Carlotta (June 2010-May 2012) and 12 after (June 2012-May 2013). Each cell is the number
#         of individuals of a species in one 10-minute, 25 m fixed-radius point count in the first two hours of
#         daylight. Sites with letters a-c are in mature mangrove forest, d-f in unwooded marsh. Row 2 is a trophic
#         guild (readme codes a1, t1, a2, t2, a2.5, a3, t3; written 1a, 1t, ... in the file).
#         Wetland_birds_Ruiz_Rangel.txt: tab-separated, header "Species" + 149 species (Genus.species, AOU names),
#         row 2 the guilds, then 720 rows named "<MM>.<YY>.<site>.yr<k>" (20 sites x 36 months, asserted), cells
#         non-negative integers with no blanks (every site counted every month).
# Mapping (repeated counts, community): unit = count site, taxon = a code from the name (first three letters of
#   genus and species), period = month index 1-36 (June 2010 = 1; __periods: year, month, study year, before or
#   after the hurricane), no occasion (one count per site-month), y = count. unit_habitat (mangrove for a-c, marsh
#   for d-f). Guild in __taxa as taxon_trophic_guild. surveyEvidence = deposited_matrix (complete; every site-month
#   is a row in the file). taxonInclusion = recorded. No coordinates per site deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ruiz_2021_oaxaca_wetbirds_count"
REC <- "5635554"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-zero"), identical(meta$doi, "10.5061/dryad.x95x69pk6"),
          setequal(meta$files$key, c("READ_ME_Ruiz_Rangel.txt", "Wetland_birds_Ruiz_Rangel.txt")))
invisible(zen("READ_ME_Ruiz_Rangel.txt"))
raw <- fread(zen("Wetland_birds_Ruiz_Rangel.txt"), header = FALSE, sep = "\t", colClasses = "character")
sp <- unlist(raw[1, -1]); guild <- unlist(raw[2, -1])
stopifnot(raw[[1]][1] == "Species", raw[[1]][2] == "Trophic.guild", length(sp) == 149L, !anyDuplicated(sp),
          all(guild %in% c("1a", "1t", "2a", "2t", "2.5a", "3a", "3t")), nrow(raw) == 722L)
d <- raw[-(1:2)]; setnames(d, c("row", sp))
m <- as.matrix(d[, -1]); storage.mode(m) <- "integer"
stopifnot(!anyNA(m), all(m >= 0L), all(grepl("^[0-9]{2}\\.[0-9]{2}\\.[a-f][1-4]\\.yr[1-3]$", d$row)))
key <- d[, tstrsplit(row, ".", fixed = TRUE)]; setnames(key, c("mm", "yy", "site", "yr"))
key[, `:=`(month = as.integer(mm), year = 2000L + as.integer(yy))]
key[, period := (year - 2010L) * 12L + month - 5L]
stopifnot(all(key$period %in% 1:36), uniqueN(key$site) == 20L, !anyDuplicated(key[, .(site, period)]),
          nrow(key) == 720L, all(key$yr == paste0("yr", (key$period - 1L) %/% 12L + 1L)))
code <- toupper(sapply(strsplit(sp, ".", fixed = TRUE), function(w) paste0(substr(w[1], 1, 3), substr(w[2], 1, 3))))
dup <- code[duplicated(code)]
code[code %in% dup] <- toupper(sapply(strsplit(sp[code %in% dup], ".", fixed = TRUE), function(w) paste0(substr(w[1], 1, 4), substr(w[2], 1, 4))))
stopifnot(!anyDuplicated(code))
colnames(m) <- code
long <- data.table(unit = rep(key$site, times = ncol(m)), period = rep(key$period, times = ncol(m)),
                   taxon = rep(code, each = nrow(m)), y = as.vector(m))
long[, unit_habitat := ifelse(substr(unit, 1, 1) %in% c("a", "b", "c"), "mangrove", "marsh")]
long <- order_eco(long)
stopifnot(nrow(long) == 720L * 149L, sum(long$y) == sum(m))
cat(sprintf("  %d rows, %d sites, %d taxa, %d birds counted; taxa never counted: %d\n", nrow(long), uniqueN(long$unit),
            uniqueN(long$taxon), sum(long$y), sum(colSums(m) == 0)))
stopifnot(all(colSums(m) > 0))

sci <- gsub(".", " ", sp, fixed = TRUE)
look <- sci
fix <- c("Vireo belli" = "Vireo bellii")
look[sci %in% names(fix)] <- fix[sci[sci %in% names(fix)]]
gl <- c("1a" = "aquatic plant-consumer", "1t" = "terrestrial plant-consumer", "2a" = "aquatic insectivore", "2t" = "terrestrial insectivore",
        "2.5a" = "aquatic secondary consumer", "3a" = "piscivore", "3t" = "carnivore")
taxa <- make_taxa(code, sci, lookupName = look, taxon_trophic_guild = unname(gl[guild]),
                  taxonRemarks = ifelse(sci %in% names(fix), paste0("source spelling '", sci, "'; matched as ", look), NA_character_))
periods <- data.table(period = 1:36)
periods[, `:=`(year = 2010L + (period + 4L) %/% 12L, month = (period + 4L) %% 12L + 1L, study_year = (period - 1L) %/% 12L + 1L)]
periods[, hurricane := ifelse(period <= 24L, "before", "after")]
stopifnot(periods[1, year == 2010L & month == 6L], periods[36, year == 2013L & month == 5L])

dataset <- list(
  title = "Monthly 10-minute point counts of 149 bird species at 20 sites in mangrove and marsh, coastal lagoon in Oaxaca, Mexico, June 2010-May 2013",
  creator = "Ruiz, Mateo D. M.", pubDate = "2021", doi = "10.5061/dryad.x95x69pk6", sourceURL = "https://doi.org/10.5061/dryad.x95x69pk6",
  citation = "Ruiz, M. D. M. (2021). Thirty-six consecutive months of bird point count data from twenty count sites in a Mexican wetland [Dataset]. Dryad. https://doi.org/10.5061/dryad.x95x69pk6",
  paperDOI = "10.1111/ibi.13028",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point-count abundances of every bird species recorded at 20 sites (10 in mature mangrove, 10 in unwooded marsh) in a coastal lagoon of Oaxaca, Mexico, counted every month for 36 months: 24 months before Hurricane Carlotta (June 2012) and 12 after. Species carry the trophic guild used by the authors.",
  samplingProtocol = "One 10-minute, 25 m fixed-radius point count per site per month in the first two hours of daylight; birds identified by sight and sound; sites reached on foot or by paddle boat.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "none", closureNote = "one count per site per month; the community changes between months (migrants)",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Coastal lagoon in Oaxaca, southwest Mexico (about 15.82 N, 96.58 W; no site coordinates deposited)",
  temporalCoverage = "2010-06/2013-05",
  covariateNote = "unit_habitat: mangrove (sites a-c) or marsh (sites d-f). __periods: calendar year and month, study year (June-May), and whether the month is before or after Hurricane Carlotta (June 2012). __taxa: taxon_trophic_guild from Ruiz et al. (2017).",
  notShipped = list(none = "nothing in the deposit is left out"),
  notes = "Every site was counted every month (720 site-months).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ruiz_2021_oaxaca_wetbirds_count.R")
stage_dict_row(TABLE,
  description = "Monthly point counts of 149 bird species at 20 mangrove and marsh sites in a coastal lagoon in Oaxaca, Mexico, June 2010-May 2013, spanning Hurricane Carlotta.",
  url = "https://doi.org/10.5061/dryad.x95x69pk6",
  reference = "Ruiz, M. D. M. & Rangel Salazar, J. L. (2022). Guild-level response to Hurricane Carlotta among birds in a Mexican wetland. Ibis 164, 587-595. https://doi.org/10.1111/ibi.13028",
  doi_paper = "10.1111/ibi.13028", doi_data = "10.5061/dryad.x95x69pk6",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad deposit fetched from its Zenodo mirror (record 5635554, carrying the Dryad DOI).",
  source_via = "Zenodo mirror of Dryad (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community abundance (open N-mixture / repeated counts)",
  sampling_protocol = "point_count", design = "Multi-season (36 monthly counts, 20 sites)",
  realm = "Freshwater", country = "MEX", coordinates = "None in source",
  notes = "Hurricane Carlotta (June 2012) in __periods.")
