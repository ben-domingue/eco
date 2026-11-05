#!/usr/bin/env Rscript
# Table:  neateclegg_2018_cusuco_birds_count
# Source: Dryad doi:10.5061/dryad.b025kp0, version 5562 (published 2018-06-26), licence CC0 1.0 (as shown
#         on the Dryad landing page and in the API record). Neate-Clegg, M. H. C., Jones, S. E. I.,
#         Burdekin, O., Jocque, M. & Sekercioglu, C. H. "Data from: Elevational changes in the avian
#         community of a Mesoamerican cloud forest park".
# Paper:  Neate-Clegg, M. H. C., Jones, S. E. I., Burdekin, O., Jocque, M. & Sekercioglu, C. H. (2018).
#         Elevational changes in the avian community of a Mesoamerican cloud forest park. Biotropica 50,
#         805-815, doi:10.1111/btp.12596 (paywalled, not read; design from the Dryad record).
# Data:   one file, "Neate-Clegg et al 2018 Biotropica.csv": 713 rows, one per transect survey (Dryad usage
#         notes: "the counts of every species from every transect survey from 2007 to 2016 including
#         abundance and species richness. For each transect survey there is also the number of point count
#         sites (NoSS), mean elevation, elevational range, year, survey occasion and number of observers").
#         Columns: Order (a row id), Side (East/West of the park), Camp, Transect (25 transects), NoSS,
#         Elev, Range (constant within transect), Year (2007-2016), Sample (the survey occasion within the
#         year, 1-7, contiguous within every transect-year), NoObs (1-7 observers), Abund and SR (row total
#         and species richness, both asserted equal to the species columns), then 210 species columns of
#         counts (no NA). Two are genus-level ("Amaurospiza sp.", "Polioptila sp."), one carries a
#         subspecies ("Accipiter striatus chionogaster"), and one ("Dendroica nigrescens") is zero in
#         every survey. Names are as deposited (older taxonomy: Dendroica, Basileuterus, ...). Survey dates
#         are not deposited. The program is Operation Wallacea's annual summer field season in Cusuco
#         National Park, Honduras.
# Mapping (standard E9 community abundance / N-mixture, responseType count, unitKind site):
#   unit = Transect; period = Year (2007 = 1 ... 2016 = 10, __periods carries the year); occasion = Sample;
#   taxon = 6-letter code from genus + epithet (CYOCYA and HENLEC split two collisions) (genus-level: genus + "SP"); y = the deposited count of the
#   species on that transect survey (over its NoSS point-count stations); obs_n_observers = NoObs;
#   unit_side, unit_camp, unit_n_stations (NoSS), unit_mean_elev_m (Elev), unit_elev_range_m (Range),
#   all constant within transect (asserted).
#   Survey evidence: row_presence. A survey is a row of the file (one per transect x year x occasion);
#   every species column is a count at every survey, so every taxon gets a row at every survey.
#   Not shipped: Abund and SR (sums of the species columns); Order (a row id); "Dendroica nigrescens",
#   never counted in any survey (a column of zeros, not a recorded taxon).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "neateclegg_2018_cusuco_birds_count"
dir <- download_dryad("doi:10.5061/dryad.b025kp0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "5562"), length(list.files(dir)) == 1L)
x <- fread(file.path(dir, "Neate-Clegg et al 2018 Biotropica.csv"))
meta <- c("Order", "Side", "Camp", "Transect", "NoSS", "Elev", "Range", "Year", "Sample", "NoObs", "Abund", "SR")
stopifnot(nrow(x) == 713L, ncol(x) == 222L, identical(names(x)[1:12], meta))
spc <- names(x)[13:222]
m <- as.matrix(x[, ..spc])
stopifnot(!anyNA(m), all(m >= 0), all(m == round(m)), all(rowSums(m) == x$Abund), all(rowSums(m > 0) == x$SR),
          !anyDuplicated(x[, .(Transect, Year, Sample)]), uniqueN(x$Transect) == 25L,
          identical(sort(unique(x$Year)), 2007:2016), all(x$Sample %in% 1:7), all(x$NoObs >= 1L),
          x[, identical(sort(Sample), seq_len(.N)), by = .(Transect, Year)][, all(V1)],
          x[, .(a = uniqueN(Side), b = uniqueN(Camp), c = uniqueN(NoSS), d = uniqueN(Elev), e = uniqueN(Range)),
            by = Transect][, all(c(a, b, c, d, e) == 1L)])
zero <- spc[colSums(m) == 0]
stopifnot(identical(zero, "Dendroica nigrescens"))
spc <- setdiff(spc, zero)

sp <- data.table(sci = spc)
sp[, w := strsplit(sci, " ")]
sp[, genus_only := grepl(" sp\\.$", sci)]
sp[, taxon := toupper(vapply(seq_len(.N), function(i) { w <- w[[i]]
  if (genus_only[i]) paste0(substr(w[1], 1, 4), "SP") else paste0(substr(w[1], 1, 3), substr(w[2], 1, 3)) }, ""))]
# two 6-letter collisions (CYACYA, HENLEU) are split by hand
sp[sci == "Cyanocompsa cyanoides", taxon := "CYOCYA"]; sp[sci == "Henicorhina leucosticta", taxon := "HENLEC"]
sp[, lookup := fifelse(genus_only, sub(" sp\\.$", "", sci), vapply(w, function(v) paste(v[1:2], collapse = " "), ""))]
# two deposited misspellings, matched under the correct spelling (scientificName keeps the source's)
sp[sci == "Leptotila cassini", lookup := "Leptotila cassinii"]; sp[sci == "Piranga olivaceus", lookup := "Piranga olivacea"]
stopifnot(nrow(sp) == 209L, !anyDuplicated(sp$taxon), sum(sp$genus_only) == 2L)

xl <- melt(x[, c("Transect", "Year", "Sample", "NoObs", spc), with = FALSE],
           id.vars = c("Transect", "Year", "Sample", "NoObs"), variable.name = "sci", value.name = "y",
           variable.factor = FALSE)
xl[, taxon := sp$taxon[match(sci, sp$sci)]]
uc <- unique(x[, .(unit = Transect, unit_side = Side, unit_camp = Camp, unit_n_stations = NoSS,
                   unit_mean_elev_m = Elev, unit_elev_range_m = Range)])
long <- xl[, .(unit = Transect, taxon, y = as.integer(y), period = as.integer(Year - 2006L),
               occasion = as.integer(Sample), obs_n_observers = as.integer(NoObs))]
long <- order_eco(merge(long, uc, by = "unit"))
stopifnot(nrow(long) == 713L * 209L, sum(long$y) == sum(x$Abund), long[y > 0, .N] == sum(x$SR))

periods <- data.table(period = 1:10, period_year = 2007:2016)
taxa <- make_taxa(sp$taxon, sp$sci, taxonRank = fifelse(sp$genus_only, "genus", "species"),
                  lookupName = sp$lookup, allow_higher = sp[genus_only == TRUE, taxon])

dataset <- list(
  title = "Repeated point-count transect surveys of 209 bird taxa on 25 transects in Cusuco National Park, Honduras, 2007-2016",
  creator = "Neate-Clegg, Montague H. C.; Jones, Simon E. I.; Burdekin, Oliver; Jocque, Merlijn; Sekercioglu, Cagan H.",
  pubDate = "2018", doi = "10.5061/dryad.b025kp0", sourceURL = "https://doi.org/10.5061/dryad.b025kp0",
  citation = "Neate-Clegg, M. H. C., Jones, S. E. I., Burdekin, O., Jocque, M., & Sekercioglu, C. H. (2018). Data from: Elevational changes in the avian community of a Mesoamerican cloud forest park [Dataset]. Dryad. https://doi.org/10.5061/dryad.b025kp0",
  paperDOI = "10.1111/btp.12596",
  abstract = "Bird counts from ten years (2007-2016) of annual Operation Wallacea field seasons in Cusuco National Park, a cloud forest park in north-western Honduras: 25 transects of 2 to 8 point-count stations with mean elevations from 775 to 2,113 m, each surveyed 1 to 7 times a year, every species counted at every survey. The authors used the series to show that the community's diversity peak moved upslope over the decade.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Transects of 2 to 8 point-count stations (unit_n_stations) walked by 1 to 7 observers; every bird species counted, the counts deposited per transect survey (the stations of one survey together).",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "a period is one year's summer field season; the paper treats years as the time series, surveys within a season as replicates",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "2007/2016",
  geographicCoverage = "Cusuco National Park, Cortes, Honduras (Merendon mountains); no coordinates deposited",
  notes = "y is the count for the species on the transect survey as deposited. Survey dates are not deposited; occasion is the deposited survey number within the year. Transects were surveyed in 5 to 10 of the 10 years. Names are as deposited, in the older taxonomy of the source (Dendroica, for instance); Accipiter striatus chionogaster is matched at the species. AMAUSP and POLISP are genus-level records (Amaurospiza sp., Polioptila sp.).",
  notShipped = list(row_totals = "Abund and SR, the row sum and number of species counted (asserted equal to the species columns)",
                    never_counted = "Dendroica nigrescens, a species column that is zero in every survey",
                    row_id = "Order, a row number"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/neateclegg_2018_cusuco_birds_count.R")
stage_dict_row(TABLE,
  description = "Repeated counts of 209 bird taxa on 25 point-count transects in Cusuco National Park, Honduras, 1-7 surveys a year over 2007-2016, with observer numbers and transect elevations.",
  url = "https://doi.org/10.5061/dryad.b025kp0",
  reference = "Neate-Clegg, M. H. C., Jones, S. E. I., Burdekin, O., Jocque, M., & Sekercioglu, C. H. (2018). Elevational changes in the avian community of a Mesoamerican cloud forest park. Biotropica, 50, 805-815.",
  doi_paper = "10.1111/btp.12596", doi_data = "10.5061/dryad.b025kp0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. One never-counted species column dropped; row totals not shipped; no dates or coordinates in the deposit.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community counts, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (10 years, 1-7 surveys per transect per year)",
  realm = "Terrestrial", country = "HND", coordinates = "None in source",
  notes = "Mesoamerican cloud forest birds along an elevation gradient; no survey dates.")
