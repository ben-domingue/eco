#!/usr/bin/env Rscript
# Table:  king_2018_lakeerie_watersnake_cjs
# Source: Dryad doi:10.5061/dryad.kh022n1, version 22483 (published 2019-05-03), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). King, R. B., Stanford, K. M. & Jones, P. C. "Data
#         from: Sunning themselves in heaps, knots, and snarls: the extraordinary abundance and demography of
#         island watersnakes".
# Paper:  King, R. B., Stanford, K. M. & Jones, P. C. (2018). Sunning themselves in heaps, knots,
#         and snarls: the extraordinary abundance and demography of island watersnakes. Ecology and
#         Evolution 8, 7500-7521, doi:10.1002/ece3.4191 (open access, PMC6106160; sections 2.1-2.2 read: intensive annual
#         censuses of about two weeks, late May to mid-June, from 2001; 14 intensive study sites (0.7-2.8 km
#         of shoreline each) on Kelleys, South Bass, Middle Bass, North Bass and Gibraltar islands by 2005,
#         two dropped in 2011-2012 for low and inconsistent captures; area-constrained shoreline searches,
#         hand capture, PIT tags, release at the site of capture).
# Data:   one MARK input file, "Nesi CJS 2017.inp": 13,198 lines, one per snake: a 16-character 0/1 history
#         for 2000-2015, then 28 group columns (0/1, exactly one 1 per snake: asserted) in the order of the
#         Dryad usage notes, site x sex: Gibraltar Island; Kelleys Island South Shore, State Park, Southeast
#         Shore, Long Point, Minshall; Middle Bass Island East Point, State Park, West End; North Bass Island
#         NNEE Shore, South Shore; South Bass Island East Point, East Shore, State Park; male then female
#         within each. No losses on capture (no -1). Every history has at least one capture.
# Mapping (standard E9 CJS, responseType detection, unitKind individual):
#   unit = "S" + line number (the file carries no snake ids); taxon = NERSIPINS (Nerodia sipedon insularum,
#   subspecies); period = year - 1999 (2000 = 1 ... 2015 = 16; __periods carries the year); y = encountered
#   that year; cluster_id = unit_site (the snake's group site); unit_island; unit_sex.
#   Survey evidence: inferred. A site-year is a surveyed year when at least one snake of that site was
#   captured in it (the file has no census list; sites joined the programme between 2000 and 2004 and two
#   were dropped in 2011-2012, which the capture totals show as leading and trailing years with no
#   captures). Each snake has a row in every surveyed year of its site from the site's first (E4.4:
#   wild-caught); rows before first capture are 0.
#   Not shipped: nothing; SVL, mass and capture dates are not in the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "king_2018_lakeerie_watersnake_cjs"
dir <- download_dryad("10.5061/dryad.kh022n1", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "22483"), identical(list.files(dir), "Nesi CJS 2017.inp"))
ln <- readLines(file.path(dir, "Nesi CJS 2017.inp"), warn = FALSE)
ln <- trimws(sub(";\\s*$", "", ln[nzchar(trimws(ln))]))
tok <- strsplit(ln, "\\s+")
stopifnot(length(ln) == 13198L, all(lengths(tok) == 29L))
ch <- vapply(tok, `[`, "", 1L)
G <- do.call(rbind, lapply(tok, function(t) as.integer(t[-1])))
stopifnot(all(nchar(ch) == 16L), all(grepl("^[01]+$", ch)), all(G %in% 0:1), all(rowSums(G) == 1L), all(grepl("1", ch)))
H <- do.call(rbind, lapply(strsplit(ch, ""), as.integer))
sites <- c("Gibraltar Island", "Kelleys Island South Shore", "Kelleys Island State Park", "Kelleys Island Southeast Shore",
           "Kelleys Island Long Point", "Kelleys Island Minshall", "Middle Bass Island East Point",
           "Middle Bass Island State Park", "Middle Bass Island West End", "North Bass Island NNEE Shore",
           "North Bass Island South Shore", "South Bass Island East Point", "South Bass Island East Shore",
           "South Bass Island State Park")
g <- max.col(G)
snk <- data.table(i = seq_len(nrow(H)), site = sites[(g + 1L) %/% 2L], sex = c("female", "male")[(g %% 2L) + 1L])
snk[, island := sub(" Island.*", " Island", site)]
stopifnot(identical(snk[, .N, by = sex][order(sex), N], c(sum(G[, c(FALSE, TRUE)]), sum(G[, c(TRUE, FALSE)]))))
L <- data.table(i = rep(snk$i, each = 16L), year = rep(2000:2015, nrow(H)), y = c(t(H)))
L[, site := snk$site[i]]
surveyed <- L[, .(n = sum(y)), by = .(site, year)][n > 0L]
stopifnot(nrow(surveyed) == 193L, uniqueN(surveyed$site) == 14L)
L <- merge(L, surveyed[, .(site, year)], by = c("site", "year"))
stopifnot(L[, sum(y)] == sum(H))
long <- L[, .(unit = paste0("S", i), taxon = "NERSIPINS", y, period = year - 1999L, cluster_id = site)]
long[, `:=`(unit_site = snk$site[as.integer(substring(unit, 2))], unit_island = snk$island[as.integer(substring(unit, 2))],
            unit_sex = snk$sex[as.integer(substring(unit, 2))])]
long <- order_eco(long)
stopifnot(uniqueN(long$unit) == 13198L, long[, all(cluster_id == unit_site)])

periods <- data.table(period = 1:16, period_year = 2000:2015)
taxa <- make_taxa("NERSIPINS", "Nerodia sipedon insularum", vernacularName = "Lake Erie watersnake", taxonRank = "subspecies")

dataset <- list(
  title = "Annual capture histories of 13,198 Lake Erie watersnakes at 14 island shoreline sites, western Lake Erie, 2000-2015",
  creator = "King, Richard B.; Stanford, Kristin M.; Jones, Peter C.",
  pubDate = "2019", doi = "10.5061/dryad.kh022n1", sourceURL = "https://doi.org/10.5061/dryad.kh022n1",
  citation = "King, R. B., Stanford, K. M., & Jones, P. C. (2019). Data from: Sunning themselves in heaps, knots, and snarls: the extraordinary abundance and demography of island watersnakes [Dataset]. Dryad. https://doi.org/10.5061/dryad.kh022n1",
  paperDOI = "10.1002/ece3.4191",
  abstract = "Mark-recapture of the Lake Erie watersnake (Nerodia sipedon insularum), an island endemic listed as threatened under the US Endangered Species Act in 1999 and delisted in 2011, at 14 shoreline study sites on five US islands in western Lake Erie: annual two-week spring censuses of area-constrained searches, every snake PIT-tagged. The authors used the histories to estimate population size, annual survival and population growth through listing, recovery and delisting.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Annual census of about two weeks (late May to mid-June) at each study site: area-constrained searches of shoreline habitat by teams of about 3-8 people; snakes captured by hand, sexed, measured, PIT-tagged and released at the site of capture. Captures within a year pooled to one annual record per snake, as deposited.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "inferred",
  surveyEvidenceNote = "A site-year is surveyed when at least one snake of that site was captured in it (193 site-years). The deposit has no census list; sites joined the programme in 2000-2004 and two were dropped in 2011-2012, which appears as leading and trailing years without captures. Gibraltar Island has no captures in 2002, between captures in 2001 and 2003, and that year is treated as not surveyed.",
  responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one record per snake per year (the census captures pooled in the deposit)",
  occasionKind = "none", taxonInclusion = "single", lossesOnCapture = "none recorded",
  geographicCoverage = "Kelleys, South Bass, Middle Bass, North Bass and Gibraltar islands, western Lake Erie, Ohio, USA; no coordinates deposited",
  temporalCoverage = "2000/2015",
  covariateNote = "cluster_id and unit_site: the snake's study site (its MARK group); unit_island; unit_sex. Groups are fixed per snake in the deposit, so movement between sites is not represented.",
  notes = "unit ids are the line numbers of the MARK file (S1 ... S13198); the deposit has no tag numbers. Rows run over the surveyed years of the snake's own site from that site's first surveyed year.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/king_2018_lakeerie_watersnake_cjs.R")
stage_dict_row(TABLE,
  description = "Annual capture histories of 13,198 PIT-tagged Lake Erie watersnakes at 14 shoreline sites on five islands in western Lake Erie, Ohio, 2000-2015, with site and sex.",
  url = "https://doi.org/10.5061/dryad.kh022n1",
  reference = "King, R. B., Stanford, K. M., & Jones, P. C. (2018). Sunning themselves in heaps, knots, and snarls: the extraordinary abundance and demography of island watersnakes. Ecology and Evolution, 8, 7500-7521. https://doi.org/10.1002/ece3.4191",
  doi_paper = "10.1002/ece3.4191", doi_data = "10.5061/dryad.kh022n1",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; MARK .inp with site x sex groups; surveyed site-years inferred from captures.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "CJS capture-recapture",
  sampling_protocol = "hand_capture", design = "Multi-season (16 annual censuses, sites joined 2000-2004)",
  realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "ESA-delisted island endemic; very large marked sample; survey years inferred per site.")
