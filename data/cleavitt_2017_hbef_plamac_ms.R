#!/usr/bin/env Rscript
# Table:  cleavitt_2017_hbef_plamac_ms
# Source: EDI / LTER knb-lter-hbr.199.2, doi:10.6073/pasta/34dfd925a7ea57985eddce053eb1943b
#         (pubDate 2018), licence CC BY 4.0 (EML intellectualRights: "released under the Creative
#         Commons license - Attribution - CC BY (https://creativecommons.org/licenses/by/4.0/)").
#         Cleavitt, N. "Hubbard Brook Experimental Forest: Orchid Demography". EDI's PASTA API
#         refuses public reads from here (403) and the portal asks for a login, so the EML and both
#         data objects are fetched from the LTER DataONE member node (gmn.lternet.edu), which the
#         DataONE resolver lists as the authoritative copy.
# Paper:  Cleavitt, N. L., Berry, E. J., Hautaniemi, J. & Fahey, T. J. (2017). Life stages,
#         demographic rates, and leaf damage for the round-leaved orchids, Platanthera orbiculata
#         (Pursh.) Lindley and P. macrophylla (Goldie) P.M. Brown in a northern hardwood forest in
#         New Hampshire, USA. Botany 95(1):61-71. doi:10.1139/cjb-2016-0164 (not read; design from
#         the EML methods).
# Data:   orchid_transitions.txt (459 orchids x 5 years): orchidID (flag number; 19 carry a ".1"
#         or ".2" suffix, one is "R"; unique), taxon (USDA PLANTS code PLMA9 = P. macrophylla 218,
#         PLOR4 = P. orbiculata 241), stage_2011..stage_2015. EML codes: 0 underground, 1 one linear
#         leaf, 2 one rounding leaf, 3 two rounded leaves (adult), 3.5 adult initiated flower spike
#         but spike damaged, 4 adult with flower spike, 10 not visible; presumed dead, 11 orchid
#         lost (flag out, not relocated), -999 no observation for this plant / year. The data also
#         hold three cells coded 5, which the EML does not define (orchids 79 in 2013, R in 2012,
#         187 in 2014, each between two stage-3 or stage-2 years).
#         orchid_stage_leafarea.txt (676 rows): orchidID, taxon, Year, stage (1-4; the spike-damaged
#         3.5 is recorded as 4 here), leafArea cm2. 634 rows match a transitions plant-year with an
#         observed stage; 21 orchid ids (42 rows) are not in the transitions table, and orchid 306
#         is PLMA9 here but PLOR4 there (2 rows).
#         Methods (EML): from summer 2011 every round-leaved orchid sighted in the HBEF was flagged,
#         numbered and mapped (groups by handheld GPS, individuals by compass and tape within
#         groups); flowering plants visited three times a season (early spring, July, late August /
#         early September), nonflowering plants at least once, 2011-2015. No coordinates deposited
#         (bounding box only).
#
# Mapping (standard E9 multistate CJS, responseType state, unitKind individual): one table per
#   species (ruling #20: individual units carry one taxon); this one is Platanthera macrophylla (PLMA9,
#   218 orchids), the sibling cleavitt_2017_hbef_plaorb_ms holds P. orbiculata. unit = orchid
#   (orchidID as deposited), taxon = the source's USDA code, period = year 1..5 (2011..2015), no
#   occasion (one state per year, the season's visits pooled by the source), y = state:
#   0 not seen above ground (y_raw 0 = source-inferred underground / dormant, 10 = source-inferred
#   presumed dead), 1 one linear leaf, 2 one rounded leaf, 3 two-leaved adult, 4 adult with a
#   flower spike (y_raw 4, or 3.5 = spike initiated but damaged). y_raw carries the source code.
#   Survey evidence: the deposited matrix. At-risk span (E4.4): every orchid is a wild plant of
#   unknown age (flagged when first sighted, most of the later-flagged ones already adults), so its
#   rows begin in 2011, the study's first census: a -999 before a plant was first recorded is
#   y = 0 (not seen above ground), y_raw "-999" (the deposit does not say whether a later-found
#   plant's spot was searched in earlier years; drop y_raw == "-999" to start at first record).
#   A -999 after the first record (11 mid-history cells in 10 plants: the flag was not visited) has no row. 11 (flag lost, plant not relocated) is censoring:
#   no row from that year on (3 cells, 2 plants). The three undefined code-5 cells are not shipped
#   (no row): the plant was evidently seen but its state is unknown, and a missing row is the
#   standard's "not surveyed", not a guessed state. obs_leaf_area_cm2 from the leaf-area table
#   where the (orchid, taxon, year) matches.
#   Not shipped: the 44 leaf-area rows that match no observed plant-year (ids absent from the
#   transitions table; orchid 306's taxon conflict).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cleavitt_2017_hbef_plamac_ms"
mn <- "https://gmn.lternet.edu/mn/v2/object/"
pid <- function(x) paste0(mn, URLencode(paste0("https://pasta.lternet.edu/package/", x), reserved = TRUE))
eml_f <- download_cached(pid("metadata/eml/knb-lter-hbr/199/2"), TABLE, filename = "knb-lter-hbr.199.2.xml")
tr_f  <- download_cached(pid("data/eml/knb-lter-hbr/199/2/63677d98fade24729194f861119a2517"), TABLE, filename = "orchid_transitions.txt")
la_f  <- download_cached(pid("data/eml/knb-lter-hbr/199/2/a4f27d9814a5cdbbb89ae83d4996bc1c"), TABLE, filename = "orchid_stage_leafarea.txt")
eml <- paste(readLines(eml_f, warn = FALSE), collapse = " ")
stopifnot(grepl('packageId="knb-lter-hbr.199.2"', eml), grepl("creativecommons.org/licenses/by/4.0", eml),
          grepl("doi:10.6073/pasta/34dfd925a7ea57985eddce053eb1943b", eml))

tr <- fread(tr_f, colClasses = list(character = "orchidID"))
la <- fread(la_f, colClasses = list(character = "orchidID"))
yrs <- 2011:2015; sc <- paste0("stage_", yrs)
stopifnot(identical(names(tr), c("orchidID", "taxon", sc)), nrow(tr) == 459L, !anyDuplicated(tr$orchidID),
          identical(as.integer(table(tr$taxon)[c("PLMA9", "PLOR4")]), c(218L, 241L)),
          sum(grepl("\\.", tr$orchidID)) == 19L)
v <- unlist(tr[, ..sc])
stopifnot(all(v %in% c(-999, 0, 1, 2, 3, 3.5, 4, 5, 10, 11)), sum(v == 5) == 3L, sum(v == 11) == 3L,
          sum(v == -999) == 633L, sum(v == 10) == 366L, sum(v == 0) == 37L)
stopifnot(identical(names(la), c("orchidID", "taxon", "Year", "stage", "leafArea")), nrow(la) == 676L,
          !anyDuplicated(la[, .(orchidID, Year)]), all(la$stage %in% 1:4), all(la$leafArea > 0))

L <- melt(tr, id.vars = c("orchidID", "taxon"), measure.vars = sc, variable.name = "yr", value.name = "code")
L[, year := as.integer(sub("stage_", "", yr))][, period := year - 2010L]
setorder(L, orchidID, year)
# 11 = flag lost: censor that year and every later year
L[, lost := cumsum(code == 11) > 0, by = orchidID]
stopifnot(L[lost == TRUE, all(code %in% c(11, -999))], uniqueN(L[code == 11, orchidID]) == 2L)
nogap <- L[code == -999 & !lost, .N]
# E4.4: wild plants of unknown age are at risk from 2011; -999 before the first record is a non-sighting
L[, lead := cumsum(code != -999) == 0, by = orchidID]
n_lead <- L[lead == TRUE, .N]
stopifnot(n_lead == 622L, nogap - n_lead == 11L)                     # the rest: 11 mid-history cells in 10 plants
L <- L[(code != -999 | lead) & !lost & code != 5]
# 10 (presumed dead) is absorbing in the source; 0 (underground) never follows 10
stopifnot(L[, all(cummax(code == 10) <= (code == 10)), by = orchidID]$V1)
L[, y := fcase(code %in% c(0, 10, -999), 0L, code == 1, 1L, code == 2, 2L, code == 3, 3L, code %in% c(3.5, 4), 4L)]
L[, y_raw := as.character(code)]
stopifnot(!anyNA(L$y), all(L[, any(y > 0), by = orchidID]$V1))      # every orchid seen above ground at least once

la[, period := Year - 2010L]
m <- merge(L[, .(orchidID, taxon, period, code)], la, by = c("orchidID", "period"), all.y = TRUE, suffixes = c("", "_la"))
ok <- m[!is.na(code) & code != -999 & taxon == taxon_la]
stopifnot(nrow(ok) == 632L, nrow(m) - nrow(ok) == 44L, ok[, all((code == 3.5 & stage == 4) | code == stage)])
L[ok, on = .(orchidID, period), leaf_area_cm2 := i.leafArea]

long <- L[, .(unit = orchidID, taxon, y, y_raw, period, obs_leaf_area_cm2 = leaf_area_cm2)]
stopifnot(nrow(long) == 459L * 5L - 633L + n_lead - 3L - 3L, uniqueN(long$unit) == 459L,
          long[, min(period) == 1L, by = unit]$V1)
SP <- "PLMA9"
long <- long[taxon == SP]
stopifnot(uniqueN(long$unit) == 218L)
cat(sprintf("  %d orchids, %d plant-years; states %s; %d no-observation cells, %d lost, %d undefined code 5 dropped\n",
            uniqueN(long$unit), nrow(long), paste(names(table(long$y)), table(long$y), sep = ":", collapse = " "),
            nogap, 3L, 3L))

taxa <- make_taxa(SP, "Platanthera macrophylla", vernacularName = "Large round-leaved orchid")
iucn <- function(id) {
  key <- sub(".*/", "", id); fp <- file.path(GBIF_DIR, paste0("iucn_", key, ".json"))
  if (!file.exists(fp)) {
    txt <- paste(readLines(sprintf("https://api.gbif.org/v1/species/%s/iucnRedListCategory", key), warn = FALSE), collapse = "")
    writeLines(if (nzchar(txt)) txt else '{"code": "NE"}', fp)   # HTTP 204 = no assessment in GBIF
  }
  r <- fromJSON(fp); if (is.list(r) && length(r) && !is.null(r$code)) r$code else "NE"
}
stopifnot(!anyNA(taxa$taxonID))
taxa[, taxon_iucnCategory := sapply(taxonID, iucn)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
periods <- data.table(period = 1:5, year = yrs, n_observed = as.integer(table(factor(long$period, 1:5))),
                      n_above_ground = as.integer(table(factor(long[y > 0]$period, 1:5))))

dataset <- list(
  title = "Annual life-stage histories of 218 marked Platanthera macrophylla orchids, Hubbard Brook Experimental Forest, New Hampshire, 2011-2015",
  creator = "Cleavitt, Natalie L.", pubDate = "2018", doi = "10.6073/pasta/34dfd925a7ea57985eddce053eb1943b",
  sourceURL = "https://doi.org/10.6073/pasta/34dfd925a7ea57985eddce053eb1943b",
  citation = "Cleavitt, N. (2018). Hubbard Brook Experimental Forest: Orchid Demography ver 2. Environmental Data Initiative. https://doi.org/10.6073/pasta/34dfd925a7ea57985eddce053eb1943b",
  paperDOI = "10.1139/cjb-2016-0164",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Life stages of every flagged individual of two round-leaved orchids, Platanthera macrophylla and P. orbiculata, in the Hubbard Brook Experimental Forest, recorded each year 2011-2015 (underground, one linear leaf, one rounded leaf, two-leaved adult, adult with a flower spike, presumed dead), with leaf area per plant-year; used to estimate stage-based demographic rates and leaf damage.",
  samplingProtocol = "From summer 2011 every round-leaved orchid sighted in the HBEF was marked with a numbered PVC flag and mapped; flowering plants were visited three times a season (early spring, July for flowers, late August to early September for capsules) and nonflowering plants at least once, to record life stage and leaf measurements, through 2015.",
  samplingProtocolCode = "marked_plant_census", surveyEvidence = "deposited_matrix", responseType = "state", unitKind = "individual",
  closure = "none", closureNote = "period (one stage per year; survival, dormancy and stage transitions between years)", occasionKind = "none", taxonInclusion = "single",
  stateCodes = list(`0` = "not seen above ground (y_raw 0 = source-inferred underground / dormant; 10 = source-inferred presumed dead; -999 = before the plant was first recorded)",
                    `1` = "one linear leaf", `2` = "one rounded leaf", `3` = "two rounded leaves (adult)",
                    `4` = "adult with a flower spike (y_raw 3.5 = spike initiated but damaged)"),
  geographicCoverage = "Hubbard Brook Experimental Forest, New Hampshire, USA (43.914-43.959 N, 71.702-71.806 W); no coordinates per plant deposited",
  temporalCoverage = "2011/2015",
  coordinatesCoarsened = NA,
  notes = "One species of the deposit's two; cleavitt_2017_hbef_plaorb_ms is the other (P. orbiculata), from the same flags and census. Every orchid's rows begin in 2011 (E4.4: wild plants of unknown age are at risk from the study's first census): a year before the plant was first recorded (source -999) is y = 0 with y_raw -999; the deposit does not say whether a later-found plant's spot was searched in earlier years, so filter y_raw == '-999' to start histories at first record. A -999 after the first record (11 mid-history cells in 10 plants) has no row. Source codes 0 (underground) and 10 (presumed dead) are inferences the authors made from later years and are both y = 0 with the code in y_raw; 10 is absorbing in the source, so a model that treats it as a true death should read it from y_raw. Code 11 (flag lost, plant not relocated; 3 cells in 2 plants, after years coded 10) censors the history: no rows from that year on. Three cells coded 5, a code the EML does not define, have no row. obs_leaf_area_cm2 is the leaf-area table's value for the plant-year where it matches (632 of 676 rows; the leaf table records 3.5 as 4).",
  notShipped = list(`code 5 cells` = "3 plant-years (orchids 79 / 2013, R / 2012, 187 / 2014) with a stage code the EML does not define",
                    `leaf-area rows without a plant-year` = "42 rows for 21 orchid ids absent from the transitions table, and 2 rows for orchid 306 whose taxon differs between the two tables"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cleavitt_2017_hbef_plamac_ms.R")

stage_dict_row(TABLE,
  description = "Annual life-stage histories (multistate: not seen / one linear leaf / one rounded leaf / two-leaved adult / flower spike) of 218 marked Platanthera macrophylla orchids at Hubbard Brook Experimental Forest, 2011-2015, with leaf area per plant-year; source-inferred dormancy and death are y = 0 with the code kept.",
  url = "https://doi.org/10.6073/pasta/34dfd925a7ea57985eddce053eb1943b",
  reference = "Cleavitt, N. L., Berry, E. J., Hautaniemi, J., & Fahey, T. J. (2017). Life stages, demographic rates, and leaf damage for the round-leaved orchids, Platanthera orbiculata (Pursh.) Lindley and P. macrophylla (Goldie) P.M. Brown in a northern hardwood forest in New Hampshire, USA. Botany, 95(1), 61-71.",
  doi_paper = "10.1139/cjb-2016-0164", doi_data = "10.6073/pasta/34dfd925a7ea57985eddce053eb1943b",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Sibling of cleavitt_2017_hbef_plaorb_ms (same census, one table per species under ruling #20). Fetched from the LTER DataONE member node (EDI PASTA refuses public reads). Lost flags censor the history; three undefined code-5 cells dropped.",
  source_via = "EDI via DataONE")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Multi-state CJS capture-recapture (vegetative dormancy; stage-structured)",
  sampling_protocol = "marked_plant_census", design = "Multi-session (5 annual censuses, no secondary)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "One of two sibling species tables from the same census (cleavitt_2017_hbef_plaorb_ms); dormancy and death are source inferences kept in y_raw.")
