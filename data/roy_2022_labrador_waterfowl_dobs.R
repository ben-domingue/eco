#!/usr/bin/env Rscript
# Table:  roy_2022_labrador_waterfowl_dobs
# Source: Dryad doi:10.5061/dryad.7d7wm37wc (CC0 1.0), version 6 (2022-01-27)
#   Roy, C., Gilliland, S. & Reed, E. (2022). A hierarchical dependent double-observer method
#   for estimating waterfowl breeding pairs abundance from helicopters. Dryad.
# Paper:  Roy, C., Gilliland, S. G. & Reed, E. T. (2022). Wildlife Biology 2022(1), e01003.
#         doi:10.1002/wlb3.01003 (CC BY; read from queue/papers/).
# Data:   README.txt; HeliLabrador_flock_total.csv: 780 rows = 52 plots x 15 AOU species
#         codes, Observer1_seen / Observer2_seen = number of flocks detected by the primary /
#         by the secondary observers only (NA where the dependent double-observer protocol
#         was not run), Total_seen = flocks, Plot_area (km2), Front_seat_Observer (Veteran /
#         Rookie), First_observer_location (Front / Back = where the primary observers sat);
#         HeliLabrador_flock_composition.csv: one row per flock with sex composition.
#         Paper: Labrador, Canada, 10-19 June 2009; 36 systematic 5 x 5 km plots and 16
#         2 x 2 km plots; the dependent double-observer design was run on 29 of the 52
#         plots; flocks missed by both observer pairs on the first pass were recorded as
#         not detected and excluded. One observer had 18 years of experience, one was new.
#
# Mapping (standard E1-E5, E9 declared stretch: dependent double-observer,
#   multinomialType = dep_double_observer): unit = plot, taxon = species, occasion = cell
#   1 = "primary" (flocks detected by the primary observers), 2 = "secondary" (missed by the
#   primary, detected by the secondary), y = number of flocks in the cell; unit_plot_area_km2,
#   unit_front_seat_observer, unit_primary_position. 27 plots: the 24 plots without the
#   protocol (all 15 species NA) have totals only and are not shipped; plot S36 ran the
#   protocol but one red-breasted merganser flock has no observer attribution, so the plot
#   cannot carry a full species x cell record and is not shipped either. The paper reports
#   the design on 29 plots; the deposit attributes observers on 28 (one may have run the
#   protocol with no flocks and so carries no attribution).
#   Survey evidence = sample_table: the file lists every plot x species with explicit zeros.
#   Flocks, not birds, are the count (the authors' model); bird totals and sex composition
#   are per flock in the composition file and are not shipped.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roy_2022_labrador_waterfowl_dobs"
dir <- download_dryad("10.5061/dryad.7d7wm37wc", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
tot <- fread(file.path(dir, "HeliLabrador_flock_total.csv"), na.strings = "NA")
stopifnot(nrow(tot) == 780, uniqueN(tot$Plot) == 52, uniqueN(tot$Species) == 15,
          tot[, .N, by = Plot][, all(N == 15)], all(tot$Plot_area %in% c(4, 25)),
          tot[, uniqueN(Front_seat_Observer) == 1 & uniqueN(First_observer_location) == 1, by = Plot][, all(V1)],
          tot[!is.na(Observer1_seen), all(Observer1_seen + Observer2_seen == Total_seen)])
species <- c(ABDU = "Anas rubripes", AGWT = "Anas carolinensis", BLSC = "Melanitta americana", CAGO = "Branta canadensis",
             COGO = "Bucephala clangula", COME = "Mergus merganser", GRSC = "Aythya marila", HOME = "Lophodytes cucullatus",
             LESC = "Aythya affinis", LTDU = "Clangula hyemalis", MALL = "Anas platyrhynchos", NOPI = "Anas acuta",
             RBME = "Mergus serrator", SUSC = "Melanitta perspicillata", WWSC = "Melanitta deglandi")
vern <- c(ABDU = "American Black Duck", AGWT = "Green-winged Teal", BLSC = "Black Scoter", CAGO = "Canada Goose",
          COGO = "Common Goldeneye", COME = "Common Merganser", GRSC = "Greater Scaup", HOME = "Hooded Merganser",
          LESC = "Lesser Scaup", LTDU = "Long-tailed Duck", MALL = "Mallard", NOPI = "Northern Pintail",
          RBME = "Red-breasted Merganser", SUSC = "Surf Scoter", WWSC = "White-winged Scoter")
stopifnot(setequal(tot$Species, names(species)))
na_by_plot <- tot[, .(n_na = sum(is.na(Observer1_seen))), by = Plot]
no_protocol <- na_by_plot[n_na == 15, Plot]; partial <- na_by_plot[n_na > 0 & n_na < 15, Plot]
stopifnot(length(no_protocol) == 24, identical(partial, "S36"), tot[Plot == "S36" & is.na(Observer1_seen), .(Species, Total_seen)][, Species == "RBME" & Total_seen == 1])
keep <- tot[!Plot %in% c(no_protocol, partial)]
stopifnot(uniqueN(keep$Plot) == 27, !anyNA(keep$Observer1_seen))
cat(sprintf("  %d plots without the double-observer protocol (totals only) and plot S36 (one unattributed flock) not shipped; %d flocks in %d plots kept\n",
            length(no_protocol), sum(keep$Total_seen), uniqueN(keep$Plot)))
long <- rbind(
  keep[, .(unit = Plot, taxon = Species, y = as.integer(Observer1_seen), y_raw = "primary", occasion = 1L)],
  keep[, .(unit = Plot, taxon = Species, y = as.integer(Observer2_seen), y_raw = "secondary", occasion = 2L)])
long <- merge(long, unique(keep[, .(unit = Plot, unit_plot_area_km2 = Plot_area, unit_front_seat_observer = Front_seat_Observer,
                                     unit_primary_position = First_observer_location)]), by = "unit")
long <- order_eco(long)
stopifnot(nrow(long) == 27 * 15 * 2, sum(long$y) == sum(keep$Total_seen), long[occasion == 2, sum(y)] == sum(keep$Observer2_seen))
taxa <- make_taxa(names(species), unname(species), vernacularName = unname(vern[names(species)]))
dataset <- list(
  title = "Dependent double-observer helicopter counts of waterfowl flocks, 15 species x 27 plots, Labrador, Canada, June 2009",
  creator = "Roy, Christian; Gilliland, Scott G.; Reed, Eric T.", pubDate = "2022", doi = "10.5061/dryad.7d7wm37wc",
  sourceURL = "https://doi.org/10.5061/dryad.7d7wm37wc", paperDOI = "10.1002/wlb3.01003",
  citation = "Roy, C., Gilliland, S., & Reed, E. (2022). A hierarchical dependent double-observer method for estimating waterfowl breeding pairs abundance from helicopters [Data set]. Dryad. https://doi.org/10.5061/dryad.7d7wm37wc",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Helicopter breeding-waterfowl plot survey in Labrador (Eastern Waterfowl Survey protocol), 10-19 June 2009, with a dependent double-observer design on 29 of 52 plots: the pair of primary observers reported every flock detected ahead of an imaginary line across the aircraft; the secondary pair confirmed those and recorded flocks the primary pair missed once past the line. Pairs alternated roles and front/rear position between plots. Counts are flocks per species per plot by cell (detected by primary; missed by primary and detected by secondary); the authors fit a hierarchical Bayesian multinomial detection model with species random effects.",
  samplingProtocol = "Dependent double-observer helicopter survey of 5 x 5 km and 2 x 2 km plots at 15-50 m altitude and 30-100 km/h; primary observer pair reports all waterfowl flocks to the secondary pair, which adds flocks the primary missed; flocks missed by both on the first pass excluded.",
  samplingProtocolCode = "double_observer", surveyEvidence = "sample_table",
  responseType = "multinomial_cell", multinomialType = "dep_double_observer", unitKind = "site",
  closure = "closed", closureNote = "occasion (the two detection cells of one pass over a plot)", occasionKind = "cell", taxonInclusion = "recorded",
  geographicCoverage = "About 27,000 km2 straddling the Labrador / Quebec boundary, Newfoundland and Labrador, Canada (plot coordinates not deposited)",
  temporalCoverage = "2009-06-10/2009-06-19",
  effortColumn = "unit_plot_area_km2",
  notes = "Cell 1 = flocks detected by the primary observers, cell 2 = flocks missed by the primary and detected by the secondary observers; the order of the cells is the dependent design's order. unit_primary_position says whether the primary pair sat front or back; unit_front_seat_observer whether the front observer was the experienced (Veteran) or new (Rookie) one.",
  notShipped = list(plots_without_protocol = "24 plots surveyed without the double-observer design carry species totals only and are omitted",
                    plot_S36 = "ran the protocol, but one red-breasted merganser flock has no observer attribution, so the plot is omitted rather than shipped incomplete",
                    flock_composition = "HeliLabrador_flock_composition.csv: per-flock bird counts by sex; the authors' count unit is the flock",
                    missed_by_both = "flocks first seen while the helicopter was redirected are not in the deposit (recorded as not detected by the authors)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/roy_2022_labrador_waterfowl_dobs.R")
stage_dict_row(TABLE,
  description = "Dependent double-observer helicopter counts of waterfowl flocks (15 duck and goose species) on 27 plots in Labrador, Canada, June 2009: flocks detected by the primary observer pair and flocks missed by them but detected by the secondary pair, with plot area, observer position and experience. First double-observer (multinomial_cell) table.",
  url = "https://doi.org/10.5061/dryad.7d7wm37wc",
  reference = "Roy, C., Gilliland, S. G., & Reed, E. T. (2022). A hierarchical dependent double-observer method for estimating waterfowl breeding pairs abundance from helicopters. Wildlife Biology, 2022(1), e01003.",
  doi_paper = "10.1002/wlb3.01003", doi_data = "10.5061/dryad.7d7wm37wc",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = detection cell, multinomialType = dep_double_observer. 23 plots without the protocol and one plot with an unattributed flock not shipped (27 of 52 plots; below floor; the paper says 29 plots ran the protocol, the deposit attributes 28). Counts are flocks, not birds.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multinomial N-mixture (dependent double-observer)",
  sampling_protocol = "double_observer", design = "Single-season (one pass per plot, two observer cells)", realm = "Freshwater",
  country = "CAN", coordinates = "None in source",
  notes = "Declared stretch: occasion = observer cell. 27 plots, below floor. Flock counts; aerial survey.")
