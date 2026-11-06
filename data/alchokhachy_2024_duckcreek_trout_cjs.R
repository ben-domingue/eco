#!/usr/bin/env Rscript
# Tables: alchokhachy_2024_duckcreek_yct_cjs, alchokhachy_2024_duckcreek_bnt_cjs
# Source: USGS ScienceBase doi:10.5066/P1WUVM5S (USGS data release, published 2024-12-19; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Al-Chokhachy, R., Heinle, K.B., Sepulveda, A.J., and Verhille, C., 2024, Trout mark-recapture and
#   stream temperature and streamflow data from Duck Creek, Montana: U.S. Geological Survey data
#   release.
# Data:   Fish mark-recapture data from Duck Creek, MT.csv: 6,288 fish captured by backpack
#         electrofishing in 100 m reaches of Henrys Fork and East Fork Duck Creek, 2013-2022, twice
#         a year (mid-late July after spawning, mid-late October; "summer" visits fall from May to
#         August): date, stream, reach, pass (1-4; multi-pass with block nets on some visits),
#         reach type (allopatric above the waterfall / sympatric), taxon (YCT Yellowstone cutthroat
#         trout, BNT brown trout), PIT tag (NA for fish too small to tag, < 80 mm), length, weight,
#         reach coordinates and length. streamflow and temperature data ... .csv: logger series at
#         three gauges (not used). Asserted: 18 tags recorded under both species; a tag caught twice
#         in a season (two passes or dates) is one capture with obs_n_captures; reaches entered the
#         study at different times (East Fork reaches from 2017).
# Mapping: one table per species (ruling #20). unit = PIT tag, period = sampling season (1 =
#   summer 2013, 2 = October 2013, ... 20 = October 2022), y = captured in the season in any reach.
#   surveyEvidence inferred: a season was sampled where any fish was caught in it (every one of the
#   20 has catches), and a reach was sampled in a season where any fish was caught there
#   (__periods: n_reaches); a reach-season with no catch would be absent. At risk (E4.4): the fish
#   are wild and of unknown age, so a history begins at the first season in which the reach of its
#   first capture was sampled (before that the fish's reach was outside the trapped area), and
#   runs to October 2022. obs_reach, obs_pass (first pass of the season's capture), obs_length_mm,
#   obs_weight_g, obs_n_captures; unit_stream, unit_reach_type (of the first capture; reach B3 is
#   filed under both streams in the release, so the stream is the capture row's, not the reach's).
# Not shipped: untagged fish (no identity); the 18 two-species tags; reach coordinates (14 reach
#   points, published; Yellowstone cutthroat trout is a subspecies with no IUCN assessment of its
#   own, and the reaches can be located from the release); the streamflow and temperature series.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "alchokhachy_2024_duckcreek_trout_cjs"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/66df2b70d34eef5af66da40e?format=json", CACHE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
x <- fread(download_cached(fl[["Fish mark-recapture data from Duck Creek, MT.csv"]], CACHE, filename = "fish.csv"), na.strings = "NA",
           colClasses = list(character = "PITTag"))
stopifnot(nrow(x) == 6288, setequal(unique(x$taxa), c("YCT", "BNT")), setequal(unique(x$pass), 1:4))
x[, d := as.IDate(survey_date, format = "%m/%d/%y")]
stopifnot(!anyNA(x$d), all(month(x$d) %in% c(5:8, 10)))
x[, period := (year(d) - 2013L) * 2L + ifelse(month(x$d) == 10, 2L, 1L)]
stopifnot(setequal(unique(x$period), 1:20))
reach_first <- x[, .(rp = min(period)), by = reach]
nreach <- x[, .(n_reaches = uniqueN(reach)), by = period]
t <- x[!is.na(PITTag)]
two <- t[, uniqueN(taxa), by = PITTag][V1 > 1, PITTag]; stopifnot(length(two) == 18)
t <- t[!PITTag %in% two]
setorder(t, PITTag, d, pass)
caps <- t[, .(reach = reach[1], stream = stream[1], reach_type = reach_type[1], pass = pass[1], len = len[1], wt = wt[1], date = d[1], n = .N), by = .(PITTag, taxa, period)]
stopifnot(sum(caps$n > 1) == 99)
first <- caps[order(period)][, .(taxa = taxa[1], reach1 = reach[1], stream = stream[1], reach_type = reach_type[1], p1 = period[1]), by = PITTag]
first <- merge(first, reach_first, by.x = "reach1", by.y = "reach")
stopifnot(!anyDuplicated(first$PITTag), all(first$rp <= first$p1))
nm <- c(YCT = "Oncorhynchus clarkii bouvieri", BNT = "Salmo trutta")
vn <- c(YCT = "Yellowstone cutthroat trout", BNT = "Brown trout")
pdates <- x[, .(first_date = format(min(d)), last_date = format(max(d))), by = period]
periods <- merge(data.table(period = 1:20)[, `:=`(year = 2013L + (period - 1L) %/% 2L, season = ifelse(period %% 2 == 1, "summer", "October"))],
                 merge(nreach, pdates, by = "period"), by = "period")
for (sp in c("YCT", "BNT")) {
  TABLE <- sprintf("alchokhachy_2024_duckcreek_%s_cjs", tolower(sp))
  f1 <- first[taxa == sp]
  g <- f1[, .(period = rp:20), by = .(PITTag, stream, reach_type)]
  g <- merge(g, caps[taxa == sp, !c("stream", "reach_type")], by = c("PITTag", "period"), all.x = TRUE)
  g[, y := as.integer(!is.na(n))]
  stopifnot(sum(g$y) == nrow(caps[taxa == sp]))
  long <- g[, .(unit = PITTag, taxon = sp, y, period, obs_capture_date = ifelse(is.na(date), NA_character_, format(date)),
                unit_stream = stream, unit_reach_type = reach_type, obs_reach = reach, obs_pass = pass,
                obs_length_mm = len, obs_weight_g = wt, obs_n_captures = n)]
  taxa <- make_taxa(sp, nm[[sp]], vernacularName = vn[[sp]], taxonRank = if (sp == "YCT") "subspecies" else "species",
                    lookupName = if (sp == "YCT") "Oncorhynchus clarki bouvieri" else nm[[sp]])
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
  nu <- uniqueN(long$unit)
  dataset <- list(
    title = sprintf("Seasonal capture histories of %s PIT-tagged %s in electrofishing reaches of Duck Creek, Montana, 2013-2022", format(nu, big.mark = ","), tolower(vn[[sp]])),
    creator = "Al-Chokhachy, Robert; Heinle, Kadie B.; Sepulveda, Adam J.; Verhille, Christine",
    pubDate = "2024", doi = "10.5066/P1WUVM5S", sourceURL = "https://doi.org/10.5066/P1WUVM5S",
    citation = "Al-Chokhachy, R., Heinle, K.B., Sepulveda, A.J., and Verhille, C., 2024, Trout mark-recapture and stream temperature and streamflow data from Duck Creek, Montana: U.S. Geological Survey data release, https://doi.org/10.5066/P1WUVM5S.",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
    abstract = "Native Yellowstone cutthroat trout and non-native brown trout were sampled by backpack electrofishing in systematic 100 m reaches of two Duck Creek tributaries, Montana, each July and October from 2013 to 2022, and PIT-tagged to study how interannual temperature, discharge and brown trout occurrence affect the cutthroat trout.",
    samplingProtocol = "Backpack electrofishing of 100 m reaches about 450 m apart (systematic, random start) twice a year, single or multiple passes with block nets; fish measured, weighed and PIT-tagged (12 mm tags 80-119 mm, 23 mm tags from 120 mm).",
    samplingProtocolCode = "electrofishing", surveyEvidence = "inferred",
    surveyEvidenceNote = "No survey list is deposited. A season was sampled where any fish was caught in it (all 20 seasons have catches) and a reach in a season where any fish was caught there (__periods n_reaches); a reach-season with no catch would be missing.",
    responseType = "detection", unitKind = "individual", closure = "none", occasionKind = "none", taxonInclusion = "single",
    closureNote = "period = sampling season (July or October); passes and dates within a season are collapsed to captured or not (obs_n_captures). A history starts when the reach of the fish's first capture entered the study.",
    geographicCoverage = list(description = "Henrys Fork and East Fork Duck Creek, Yellowstone River tributaries, Montana, USA",
                              boundingBox = list(west = min(x$longitude), east = max(x$longitude), south = min(x$latitude), north = max(x$latitude))),
    temporalCoverage = "2013-05/2022-10",
    notShipped = list(untagged = "fish below tagging size (no identity)", two_species_tags = "18 PIT tags recorded under both species",
                      coordinates = "reach coordinates (not needed for an individual table; obs_reach names the reach)",
                      loggers = "stream temperature and discharge series"),
    notes = "Reaches A1-A5 lie above an impassable waterfall (allopatric cutthroat trout); B and EF reaches below it (sympatric with brown trout).")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods[period %in% long$period], script = "data/alchokhachy_2024_duckcreek_trout_cjs.R")
  stage_dict_row(TABLE,
    description = sprintf("Seasonal (July and October) capture histories of %s PIT-tagged %s from backpack electrofishing reaches in Duck Creek tributaries, Montana, 2013-2022, with reach, length and weight.", format(nu, big.mark = ","), tolower(vn[[sp]])),
    url = "https://doi.org/10.5066/P1WUVM5S",
    reference = "Al-Chokhachy, R., Heinle, K.B., Sepulveda, A.J., and Verhille, C. (2024). Trout mark-recapture and stream temperature and streamflow data from Duck Creek, Montana. U.S. Geological Survey data release.",
    doi_data = "10.5066/P1WUVM5S", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
    notes = "CJS per species; seasons inferred from catches.", source_via = "USGS ScienceBase")
  stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "CJS", sampling_protocol = "electrofishing",
    design = "Multi-season (20 seasons)", realm = "Freshwater", country = "USA", coordinates = "None in source",
    notes = if (sp == "YCT") "Native cutthroat trout; brown trout invasion study." else "Non-native brown trout.")
}
