#!/usr/bin/env Rscript
# Tables: dominoni_2024_glasgow_bluetit_cjs, dominoni_2024_glasgow_greattit_cjs
# Source: NERC Environmental Information Data Centre (EIDC) doi:10.5285/9982cf52-7144-4877-9e17-1335f14140d8,
#         published 2024-08-14, licence Open Government Licence v3 ("This resource is available under the terms of
#         the Open Government Licence"; catalogue record and readme.html, asserted from the cached catalogue JSON);
#         required attribution "Contains data supplied by UK Centre for Ecology & Hydrology".
#   Dominoni, D.M., Capilla-Lasheras, P. & Branston, C.J. (2024). Mark-recapture data of individual birds from ringing records, Glasgow, UK, 2014-2022.
#   NERC EDS Environmental Information Data Centre.
# Paper:  none named in the record.
# Data:   the EIDC data package zip: data/dominoni_highlight_topics_mark-recapture.csv, 13,452 capture records (one
#         row per capture event) of blue tits (bluti) and great tits (greti), 2019-2023 (the title says 2014-2022;
#         the file holds yr 2019-2023), with ring_number (BTO ring), retrap (N new, R retrap, C control, X found dead,
#         U unknown), age (BTO code; 1 = nestling, with X added for "a bird ringed as a chick (age 1) that did not
#         reach fledging (i.e. died in the nest)"), sex, date, site (21-27 nest-box and mist-net sites per year along a
#         35 km Glasgow city centre to Loch Lomond gradient), biometrics, nest box, parent rings, RFID and colour
#         rings, CES visit number. The supporting document: nest boxes monitored 1 April-20 June each year, adults
#         caught on the nest 2-10 days after hatching, nestlings ringed at 13 days; opportunistic mist netting outside
#         the breeding season.
#         Quirks: rows whose ring_number is not a BTO ring (1-3 letters then 4+ digits: notes such as "no_rings_COVID",
#         "too small", "unringed", "escape", blank; 355 rows, 338 of them nestlings) are dropped; sex has a stray
#         non-breaking-space value (read as blank); the age code X is also written x (taken as X); retrap x is taken as X.
# Mapping (CJS, one table per species, ruling #20): unit = ring_number, taxon = CYACAE / PARMAJ, period = year
#   (1 = 2019 ... 5 = 2023), y = 1 if the bird was caught alive in that year (any live capture), else 0. At-risk span
#   (E4.4): a bird first ringed as a nestling (age 1 or X) has rows from its ringing year; a bird first caught as a
#   fledged bird from 2019. A nestling that died in the nest (age X) and a bird found dead (retrap X) end their
#   history in that year with obs_removed = 1 (y = 1 only if also caught alive that year; obs_found_dead = 1 marks
#   a dead recovery). cluster_id = the site of first capture (birds can move between sites). unit_first_age (BTO
#   age code at first capture), unit_sex (the most frequent recorded M/F, else U). surveyEvidence = row_presence:
#   a site was monitored in a year when the deposit has any record there that year (either species, ringed or not;
#   site names compared in lower case, "GCU" = "gcu"). A bird-year is a survey when the bird's site of first capture
#   was monitored that year, or the bird itself has a record that year (a capture elsewhere is evidence it was
#   surveyed). The sites with any record vary between years (21 to 27 a year), so under the 2026-11-06 ruling on
#   protocol-only zeros a bird has no row in a year its site has no record and it was not caught; batch 43 had taken
#   every year as surveyed for every marked bird. The rows dropped are counted in notShipped.
#   No coordinates (site names only). Both species IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/dominoni_2024_glasgow_tit_cjs.R"; CACHE <- "dominoni_2024_glasgow_tit_cjs"
ID <- "9982cf52-7144-4877-9e17-1335f14140d8"
mf <- file.path(RAW_DIR, CACHE, "eidc_record.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file(paste0("https://catalogue.ceh.ac.uk/documents/", ID), mf, quiet = TRUE, headers = c("User-Agent" = UA, Accept = "application/json"))
meta <- fromJSON(mf)
stopifnot(any(grepl("Open Government Licence", meta$useConstraints$value)), paste0("10.5285/", ID) %in% meta$resourceIdentifiers$code)
z <- download_cached(sprintf("https://data-package.ceh.ac.uk/data/%s.zip", ID), CACHE, filename = "data_package.zip")
ex <- file.path(dirname(z), "x"); if (!dir.exists(ex)) unzip(z, exdir = ex)
d <- fread(file.path(ex, "data", "dominoni_highlight_topics_mark-recapture.csv"), colClasses = list(character = c("ring_number", "age", "retrap", "sex")))
stopifnot(nrow(d) == 13452L, setequal(d$species, c("bluti", "greti")), setequal(d$yr, 2019:2023))
# Evidence of monitoring (ruling 2026-11-06): any record at a site in a year, before the ring filter.
mon <- unique(d[, .(site = tolower(site), per = yr - 2018L)])
cr <- d[, sum(!grepl("^[A-Z]{1,3}[0-9]{4,}$", ring_number))]
d <- d[grepl("^[A-Z]{1,3}[0-9]{4,}$", ring_number)]
cat(sprintf("  dropped %d records without a ring number\n", cr))
d[, `:=`(age = toupper(age), retrap = toupper(retrap), sex = trimws(iconv(sex, "latin1", "UTF-8"), whitespace = "[\\h\\v]"))]
stopifnot(d[, uniqueN(species), by = ring_number][, all(V1 == 1L)])
creators <- paste(meta$authors$fullName, collapse = "; ")
stopifnot(identical(creators, "Dominoni, D.M.; Capilla-Lasheras, P.; Branston, C.J."))
YR <- 2019:2023
sp <- list(bluti = list(taxon = "CYACAE", sci = "Cyanistes caeruleus", vern = "Blue tit", name = "bluetit"),
           greti = list(taxon = "PARMAJ", sci = "Parus major", vern = "Great tit", name = "greattit"))
for (s in names(sp)) {
  S <- sp[[s]]; TABLE <- sprintf("dominoni_2024_glasgow_%s_cjs", S$name)
  x <- d[species == s]
  x[, `:=`(per = yr - 2018L, dead = age == "X" | retrap == "X", live = !(retrap == "X"))]
  setorder(x, ring_number, yr, date)
  ind <- x[, .(first = min(per), nestling = age[1] %in% c("1", "X"), age1 = age[1], site1 = site[1],
               last_dead = if (any(dead)) min(per[dead]) else NA_integer_,
               sex = { s2 <- gsub("[()]", "", sex); s2 <- s2[s2 %in% c("M", "F")]; if (length(s2)) names(sort(table(s2), decreasing = TRUE))[1] else "U" }),
           by = ring_number]
  ind[, `:=`(start = ifelse(nestling, first, 1L), end = ifelse(is.na(last_dead), 5L, last_dead))]
  stopifnot(all(ind$end >= ind$first))
  long <- ind[, .(period = start:end), by = .(ring_number, start, end, site1, age1, sex)]
  caps <- unique(x[live == TRUE, .(ring_number, period = per)])
  dd <- unique(x[retrap == "X", .(ring_number, period = per)])
  long[, y := 0L][caps, on = .(ring_number, period), y := 1L]
  long[, obs_found_dead := 0L][dd, on = .(ring_number, period), obs_found_dead := 1L]
  long[, obs_removed := as.integer(period == end & ring_number %in% ind[!is.na(last_dead), ring_number])]
  deadonly <- long[, .(any = any(y == 1L)), by = ring_number][any == FALSE, ring_number]
  ind <- ind[!ring_number %in% deadonly]; long <- long[!ring_number %in% deadonly]
  cat(sprintf("  %d bird(s) known only from a dead recovery dropped (never caught alive)\n", length(deadonly)))
  # Keep a bird-year only where its first site was monitored that year or the bird has a record that year.
  rec <- unique(x[, .(ring_number, period = per)])
  long[, site_l := tolower(site1)]
  keep <- long[mon, on = .(site_l = site, period = per), which = TRUE, nomatch = NULL]
  keep <- union(keep, long[rec, on = .(ring_number, period), which = TRUE, nomatch = NULL])
  n_unmon <- nrow(long) - length(keep)
  stopifnot(long[-keep, all(y == 0L & obs_found_dead == 0L & obs_removed == 0L)])
  long <- long[sort(keep)][, site_l := NULL]
  cat(sprintf("  %d bird-years dropped: the bird's site had no record that year and the bird was not caught\n", n_unmon))
  long <- long[, .(unit = ring_number, taxon = S$taxon, y, period, cluster_id = site1, unit_first_age = age1, unit_sex = sex, obs_found_dead, obs_removed)]
  long <- order_eco(long)
  stopifnot(uniqueN(long$unit) == nrow(ind), !anyDuplicated(long[, .(unit, period)]),
            sum(long$y) == nrow(caps[ring_number %in% long$unit & period <= 5L]) - nrow(caps[ring_number %in% ind[!is.na(last_dead), ring_number]][ind, on = "ring_number", nomatch = 0][period > end]),
            long[obs_removed == 1L, .N] == ind[!is.na(last_dead), .N])
  cat(sprintf("  %s: %d birds (%d first ringed as nestlings, %d dead in nest or found dead), %d rows, %d live captures\n", TABLE, nrow(ind),
              sum(ind$nestling), sum(!is.na(ind$last_dead)), nrow(long), sum(long$y)))
  taxa <- make_taxa(S$taxon, S$sci, vernacularName = S$vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
  periods <- data.table(period = 1:5, year = YR, n_sites_with_records = x[, uniqueN(site), by = yr][order(yr), V1])
  dataset <- list(
    title = sprintf("Annual capture histories of %d %ss ringed at nest boxes and mist-net sites along an urban gradient, Glasgow to Loch Lomond, 2019-2023", nrow(ind), tolower(S$vern)),
    creator = creators, pubDate = "2024", doi = paste0("10.5285/", ID), sourceURL = paste0("https://doi.org/10.5285/", ID),
    citation = sprintf("%s (2024). Mark-recapture data of individual birds from ringing records, Glasgow, UK, 2014-2022. NERC EDS Environmental Information Data Centre. https://doi.org/10.5285/%s. Contains data supplied by UK Centre for Ecology & Hydrology.", creators, ID),
    intellectualRights = list(spdx = "OGL-UK-3.0", url = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"),
    abstract = sprintf("Ringing records of %ss from nest-box populations (adults caught on the nest, nestlings ringed at 13 days) and opportunistic mist netting at 21-27 sites a year along a 35 km urban-to-rural gradient from Glasgow city centre to Loch Lomond, Scotland, collapsed to annual capture histories for survival analysis.", tolower(S$vern)),
    samplingProtocol = "Nest boxes monitored 1 April-20 June each year; breeding adults caught on the nest 2-10 days after hatching and nestlings ringed at 13 days with BTO metal rings; opportunistic mist netting outside the breeding season; captures pooled to one annual occasion.",
    samplingProtocolCode = "nest_box", surveyEvidence = "row_presence",
    responseType = "detection", unitKind = "individual", closure = "none", closureNote = "one annual occasion per year",
    occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = "Glasgow city centre to Loch Lomond and the Trossachs National Park, Scotland, UK (site names only, no coordinates)",
    temporalCoverage = "2019/2023",
    covariateNote = "cluster_id: site of first capture. unit_first_age: BTO age code at first capture (1 nestling, X nestling that died in the nest, 3/3J juvenile, 4-6 adult). unit_sex: most frequent M/F recorded, else U. obs_found_dead: 1 if the bird was found dead that year. obs_removed: 1 on the last row of a bird that died in the nest or was found dead.",
    surveyEvidenceNote = "A site was monitored in a year when the deposit has any record there that year (either species). A bird-year is a survey when the bird's site of first capture (cluster_id) was monitored that year or the bird has a record that year; other bird-years have no row (ruling 2026-11-06, protocol-only zeros).",
    notShipped = list(unmonitored = sprintf("%d bird-years at sites with no record that year, where the bird was not caught (protocol-only zeros, ruling 2026-11-06)", n_unmon),
                      no_ring = sprintf("%d records (both species) whose ring_number is a note ('too small', 'unringed', ...) or blank", cr),
                      dead_only = "birds known only from a dead recovery (never caught alive): not units (E4.4)",
                      within_year = "capture dates, times, biometrics, nest box, parents, RFID and colour rings (one annual occasion is shipped)"),
    notes = sprintf("The deposit holds 2019-2023 although its title says 2014-2022. Sites with records per year (in __periods) vary from %d to %d, so detection varies by year; a bird has a row in a year only when its site of first capture has a record that year or it was caught (surveyEvidenceNote; rebuilt 2026-11-06, batch 47). Nestlings have rows from their ringing year, other birds from 2019 (E4.4).",
                    min(periods$n_sites_with_records), max(periods$n_sites_with_records)))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Annual CJS capture histories of %d %ss (%s) from nest boxes and mist netting along the Glasgow urban gradient, 2019-2023.", nrow(ind), tolower(S$vern), S$sci),
    url = paste0("https://doi.org/10.5285/", ID), reference = "", doi_paper = "", doi_data = paste0("10.5285/", ID),
    original_license = "Open Government Licence v3 (attribution: Contains data supplied by UK Centre for Ecology & Hydrology)",
    derived_license = "OGL-UK-3.0", notes = "One table per species; annual occasions from capture records.", source_via = "EIDC data package (zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
    sampling_protocol = "nest_box", design = "Multi-season (5 years, 2019-2023)",
    realm = "Terrestrial", country = "GBR", coordinates = "None in source", notes = "Urban gradient; site of first capture as cluster_id.")
}
