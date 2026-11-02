#!/usr/bin/env Rscript
# Table:  davis_2016_feralswine_removal
# Source: Dryad doi:10.5061/dryad.67nb3 (CC0 1.0, shown on the dataset page and in the API
#         record), version 17089 (published 2016-05-13).
#   Davis, A. J., Hooten, M. B., Miller, R. S., Farnsworth, M. L., Lewis, J., Moxcey, M. &
#   Pepin, K. M. (2016). Data from: Inferring invasive species abundance using removal data
#   from management actions. Dryad.
# Paper:  Davis, A. J. et al. (2016). Inferring invasive species abundance using removal data
#         from management actions. Ecological Applications 26(7), 2339-2346. doi:10.1002/eap.1383.
# Data:   RemovalDataForPublication.xlsx, sheet "Data": 59 rows = property x removal episode
#         (aerial gunning of feral swine by USDA-APHIS Wildlife Services, Oklahoma and Texas,
#         2005-2013): SiteNumber (generic property id; 8 of the 49 properties have 2-3 episodes),
#         Start / End (dates of the episode), County, State, Effort1-3 (hours in the
#         helicopter on passes 1-3), Removal1-3 (swine removed on passes 1-3). Sheet
#         "Metadata" defines the columns; "Sheet3" is empty. No coordinates; the abstract
#         gives property sizes of 480-19,600 acres, which are not deposited.
#
# Mapping (standard E9 declared stretch: removal sampling, multinomialType = removal):
#   unit = property (SiteNumber, as "site_<n>"), taxon = SUSSCR (Sus scrofa), period = calendar
#   year in which the episode started (2005-2013 -> 1-9, in __periods; no property has two
#   episodes starting in one year, asserted), occasion = removal pass 1-3, y = swine removed
#   on that pass, y_raw = "pass<k>". obs_effort_h = helicopter hours on the pass
#   (effortColumn; > 0 on every pass, asserted); obs_episode_start / obs_episode_end = the
#   episode's dates (constant within unit x period); unit_county, unit_state.
#   Survey evidence = effort_table: every deposited pass has positive effort; a property x
#   year without an episode has no rows.
#   Closure: the authors treat each episode as closed (their guidance: <= 3 months for feral
#   swine); 5 episodes span more than 3 months and are kept as deposited (obs dates show it).
#   Not shipped: nothing deposited is left out; the authors' abundance estimates are not in
#   the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "davis_2016_feralswine_removal"
dir <- download_dryad("10.5061/dryad.67nb3", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "RemovalDataForPublication.xlsx")
stopifnot(identical(excel_sheets(f), c("Data", "Metadata", "Sheet3")))
d <- as.data.table(read_excel(f, "Data"))
stopifnot(identical(names(d), c("SiteNumber", "Start", "End", "County", "State", "Effort1", "Effort2", "Effort3",
                                "Removal1", "Removal2", "Removal3")),
          nrow(d) == 59L, uniqueN(d$SiteNumber) == 49L, nrow(d[as.numeric(as.Date(End) - as.Date(Start)) > 92]) == 5L, all(d$State %in% c("Oklahoma", "Texas")),
          d[, .N, by = State][order(State), identical(N, c(21L, 38L))],
          !anyNA(d), all(d[, c(Effort1, Effort2, Effort3)] > 0),
          all(d[, c(Removal1, Removal2, Removal3)] >= 1), all(d[, c(Removal1, Removal2, Removal3)] %% 1 == 0),
          all(d$End >= d$Start),
          d[, uniqueN(County) == 1L & uniqueN(State) == 1L, by = SiteNumber][, all(V1)])
d[, `:=`(start = as.Date(Start), end = as.Date(End), year = as.integer(format(as.Date(Start), "%Y")))]
stopifnot(!anyDuplicated(d[, .(SiteNumber, year)]), range(d$year) == c(2005L, 2013L))
long_days <- d[as.numeric(end - start) > 92]
cat(sprintf("  %d episodes at %d properties; %d episodes span more than 3 months; %d swine removed\n",
            nrow(d), uniqueN(d$SiteNumber), nrow(long_days), sum(d[, Removal1 + Removal2 + Removal3])))
long <- rbindlist(lapply(1:3, function(k) d[, .(unit = sprintf("site_%02d", as.integer(SiteNumber)), taxon = "SUSSCR",
  period = year - 2004L, occasion = k, y = as.integer(get(paste0("Removal", k))), y_raw = paste0("pass", k),
  obs_effort_h = get(paste0("Effort", k)), obs_episode_start = format(start), obs_episode_end = format(end),
  unit_county = tools::toTitleCase(tolower(County)), unit_state = State)]))
long <- order_eco(long)
stopifnot(nrow(long) == 3L * 59L, sum(long$y) == sum(d[, Removal1 + Removal2 + Removal3]), !any(grepl("^unit_unit_", names(long))))
periods <- data.table(period = 1:9, year = 2005:2013)
periods <- merge(periods, d[, .(n_episodes = .N), by = .(period = year - 2004L)], by = "period", all.x = TRUE)
periods[is.na(n_episodes), n_episodes := 0L]
stopifnot(all(periods$n_episodes > 0))
taxa <- make_taxa("SUSSCR", "Sus scrofa", vernacularName = "Feral swine (wild pig)")
dataset <- list(
  title = "Three-pass aerial removal of feral swine, 49 properties in Oklahoma and Texas, 59 removal episodes 2005-2013",
  creator = "Davis, Amy J.; Hooten, Mevin B.; Miller, Ryan S.; Farnsworth, Matthew L.; Lewis, Jesse; Moxcey, Michael; Pepin, Kim M.",
  pubDate = "2016", doi = "10.5061/dryad.67nb3", sourceURL = "https://doi.org/10.5061/dryad.67nb3", paperDOI = "10.1002/eap.1383",
  citation = "Davis, A. J., Hooten, M. B., Miller, R. S., Farnsworth, M. L., Lewis, J., Moxcey, M., & Pepin, K. M. (2016). Data from: Inferring invasive species abundance using removal data from management actions [Data set]. Dryad. https://doi.org/10.5061/dryad.67nb3",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Feral swine (Sus scrofa) removed by aerial gunning from helicopters during USDA-APHIS Wildlife Services management in Oklahoma and Texas, 2005-2013: 59 property x episode combinations (49 properties, 480-19,600 acres), each with three removal passes, the number removed on each pass and the helicopter hours spent. The authors fit a Bayesian hierarchical removal model with effort-dependent removal probability to estimate abundance before and after management.",
  samplingProtocol = "Management removal by aerial gunning from a helicopter; three passes per property within an episode, hours flown recorded per pass.",
  samplingProtocolCode = "removal", surveyEvidence = "effort_table",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site",
  closure = "occasion within period (one removal episode per property-year treated as closed; 5 episodes run longer than 3 months)",
  occasionCodes = list(`1` = "pass 1", `2` = "pass 2", `3` = "pass 3"),
  effortColumn = "obs_effort_h",
  geographicCoverage = "Oklahoma (21 episodes) and Texas (38 episodes), USA; county only, no coordinates deposited",
  temporalCoverage = "2005-12-05/2013-05-23",
  notes = "Period = calendar year in which the episode began (an episode starting in December runs into the next year); obs_episode_start / obs_episode_end give its dates. Pass dates are not deposited. Removed animals do not return within an episode (removal design); a later episode on the same property is a new closed population.",
  notShipped = list(property_area = "property sizes (480-19,600 acres) are given in the paper, not per property in the deposit",
                    estimates = "the authors' abundance estimates are not in the deposit"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/davis_2016_feralswine_removal.R")
stage_dict_row(TABLE,
  description = "Three-pass removal counts of feral swine shot from helicopters on 49 properties in Oklahoma and Texas, 59 removal episodes 2005-2013, with helicopter hours per pass as effort.",
  url = "https://doi.org/10.5061/dryad.67nb3",
  reference = "Davis, A. J., Hooten, M. B., Miller, R. S., Farnsworth, M. L., Lewis, J., Moxcey, M., & Pepin, K. M. (2016). Inferring invasive species abundance using removal data from management actions. Ecological Applications, 26(7), 2339-2346.",
  doi_paper = "10.1002/eap.1383", doi_data = "10.5061/dryad.67nb3",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Declared stretch (E9): occasion = removal pass, multinomialType = removal, effort per pass. Period = year the episode began. First removal table from management data.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Removal (multinomial N-mixture with effort)",
  sampling_protocol = "removal", design = "Multi-season (9 years, 1-3 episodes per property)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source",
  notes = "Invasive species management data; aerial gunning; helicopter hours as effort.")
