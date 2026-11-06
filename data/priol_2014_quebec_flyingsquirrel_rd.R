#!/usr/bin/env Rscript
# Table:  priol_2014_quebec_flyingsquirrel_rd
# Source: Dryad doi:10.5061/dryad.p2r8r (CC0 1.0, as shown on the Dryad page; published
#         2015-03-31). Priol, P., Mazerolle, M.J., Imbeau, L., Drapeau, P., Trudeau, C. &
#         Ramiere, J. Data from: Using dynamic N-mixture models to test cavity limitation on
#         northern flying squirrel demographic parameters using experimental nest box
#         supplementation.
# Paper:  Priol, P. et al. (2014). Ecology and Evolution 4(11), 2165-2177, doi:10.1002/ece3.1086.
#         BACI experiment in deciduous stands of northwestern Quebec: live trapping of northern
#         flying squirrels at 56 sites, nest boxes added at half of them; trapping in 2008 and
#         2012, two capture occasions per year (abstract; CJS script: "T1 and T2 (2008), T3 and
#         T4 (2012)").
# Data:   "Priol et al. 2014. EE. R-script and data.zip": Cormack-Jolly-Seber (CJS) models/
#         CMR_pola_2008_2012_conifer_snag.csv (300 capture histories: Site (55 sites with a
#         capture), ID (tag; "INC" = unidentified, 5 rows), T1-T4 0/1, Snag and Conifer basal area,
#         standardized); Classic CMR models/cmr2008.txt and cmr2012.txt (the same histories split
#         by year, with freq); GLMM/Count.data.txt (224 rows: 56 sites x 2 years x 2 visits:
#         Boxes (nest-box site 0/1), Snag, Conifer, Counts = individuals captured, asserted equal
#         to the CMR tallies per site-visit, so not shipped); Dynamic N-mixture models/pola.txt
#         (56 x 8 counts S1V1..S2V4 with no site ids; four visits per season, which do not match
#         the two capture occasions and are not documented; not shipped) and covariates; R code.
#         Quirks: tag 049 is captured at site D1 (2008 T1) and D2 (2008 T2), tag 028D at B1 and
#         D6 (2012 T4); the authors keep each as a separate history row, as here.
# Mapping (standard: robust design capture-recapture, E9 core): unit = history row
#   ("<site>_<ID>", INC rows numbered); taxon = GLASAB; period = year (1 = 2008, 2 = 2012);
#   occasion = capture occasion within the year (1-2); y = capture 0/1; cluster_id = site.
#   Full rectangle (E4.4): every animal carries rows for both years (caught in the wild; no
#   removals recorded). unit_: snag and conifer basal area (standardized, as deposited) and the
#   site's nest-box assignment (Boxes; boxes were added after the 2008 trapping).
#   Survey evidence: deposited_matrix (all 56 sites trapped on all four occasions: Count.data
#   has a row for each). No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "priol_2014_quebec_flyingsquirrel_rd"
dir <- download_dryad("10.5061/dryad.p2r8r", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "Priol et al. 2014. EE. R-script and data")
c <- fread(file.path(b, "Cormack-Jolly-Seber (CJS) models", "CMR_pola_2008_2012_conifer_snag.csv"), colClasses = list(character = c("Site", "ID")))
g <- fread(file.path(b, "GLMM", "Count.data.txt"))
stopifnot(nrow(c) == 300, uniqueN(c$Site) == 55, sum(c$ID == "INC") == 5, all(as.matrix(c[, .(T1, T2, T3, T4)]) %in% 0:1),
          all(rowSums(c[, .(T1, T2, T3, T4)]) > 0), nrow(g) == 224, uniqueN(g$Site) == 56, all(c$Site %in% g$Site),
          g[, uniqueN(Boxes), by = Site][, all(V1 == 1)], identical(sort(unique(g$Year)), c(2008L, 2012L)))
# Count.data is the tally of the capture histories (a recode, not shipped)
tal <- rbind(c[, .(Year = 2008L, Visit = "T1", n = sum(T1)), by = Site], c[, .(Year = 2008L, Visit = "T2", n = sum(T2)), by = Site],
             c[, .(Year = 2012L, Visit = "T1", n = sum(T3)), by = Site], c[, .(Year = 2012L, Visit = "T2", n = sum(T4)), by = Site])
m <- merge(g, tal, by = c("Site", "Year", "Visit"), all.x = TRUE)[is.na(n), n := 0]
stopifnot(all(m$Counts == m$n))
c[, k := seq_len(.N), by = .(Site, ID)]
c[, unit := ifelse(ID == "INC", paste0(Site, "_INC", k), paste(Site, ID, sep = "_"))]
stopifnot(!anyDuplicated(c$unit))
long <- melt(c[, .(unit, cluster_id = Site, T1, T2, T3, T4, unit_snag_ba_z = Snag, unit_conifer_ba_z = Conifer)],
             measure.vars = c("T1", "T2", "T3", "T4"), variable.name = "t", value.name = "y")
long[, `:=`(period = ifelse(t %in% c("T1", "T2"), 1L, 2L), occasion = ifelse(t %in% c("T1", "T3"), 1L, 2L), taxon = "GLASAB", y = as.integer(y))][, t := NULL]
long <- merge(long, unique(g[, .(cluster_id = Site, unit_nestbox_site = Boxes)]), by = "cluster_id")
long <- order_eco(long)
stopifnot(nrow(long) == 300 * 4, sum(long$y) == sum(c$T1 + c$T2 + c$T3 + c$T4))
periods <- data.table(period = 1:2, period_year = c(2008L, 2012L))
taxa <- make_taxa("GLASAB", "Glaucomys sabrinus", vernacularName = "Northern flying squirrel")
dataset <- list(
  title = "Live-trap capture histories of 300 northern flying squirrels at 55 sites in northwestern Quebec, two occasions in each of 2008 and 2012",
  creator = "Priol, Pauline; Mazerolle, Marc J.; Imbeau, Louis; Drapeau, Pierre; Trudeau, Caroline; Ramière, Jessica", pubDate = "2015",
  doi = "10.5061/dryad.p2r8r", sourceURL = "https://doi.org/10.5061/dryad.p2r8r",
  citation = "Priol, P., Mazerolle, M. J., Imbeau, L., Drapeau, P., Trudeau, C., & Ramière, J. (2015). Data from: Using dynamic N-mixture models to test cavity limitation on northern flying squirrel demographic parameters using experimental nest box supplementation [Dataset]. Dryad. https://doi.org/10.5061/dryad.p2r8r",
  paperDOI = "10.1002/ece3.1086",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture histories of individually tagged northern flying squirrels (Glaucomys sabrinus) live-trapped at 56 deciduous-forest sites in northwestern Quebec (55 with a capture), two occasions in 2008 and two in 2012, in a before-after control-impact experiment adding nest boxes at half the sites, with snag and conifer basal area per site.",
  samplingProtocol = "Live trapping at 56 sites in deciduous stands, two capture occasions per trapping year (2008 and 2012); captured squirrels tagged; nest boxes added at 29 sites after the 2008 trapping (BACI).",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "individual", closure = "closed", closureNote = "closed within a trapping year (two occasions), open between 2008 and 2012 (robust design; the authors fit CJS, closed CMR and dynamic N-mixture models)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Deciduous forest stands, Abitibi region of northwestern Quebec, Canada; no coordinates deposited",
  temporalCoverage = "2008/2012",
  designNote = "Robust design: period = trapping year, occasion = capture occasion within year, cluster_id = site.",
  notShipped = list(Count.data = "per site-visit counts of captured individuals, asserted equal to the tallies of the capture histories (a recode)",
                    pola.txt = "four counts per season per site with no site ids, not documented and not matching the two capture occasions",
                    cmr_by_year = "cmr2008.txt / cmr2012.txt, the same histories split by year"),
  notes = "unit = '<site>_<tag>'; the 5 'INC' (unidentified) rows are numbered within site. Tags 049 and 028D each appear at two sites and are kept as separate histories, as in the authors' file. unit_nestbox_site is the site's nest-box assignment (boxes added after the 2008 trapping), not a per-period treatment.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/priol_2014_quebec_flyingsquirrel_rd.R")
stage_dict_row(TABLE,
  description = "Robust-design live-trap capture histories of northern flying squirrels at 56 Quebec sites (2008 and 2012, two occasions each), from a nest-box supplementation BACI experiment.",
  url = "https://doi.org/10.5061/dryad.p2r8r",
  reference = "Priol, P. et al. (2014). Using dynamic N-mixture models to test cavity limitation on northern flying squirrel demographic parameters using experimental nest box supplementation. Ecology and Evolution, 4(11), 2165-2177.",
  doi_paper = "10.1002/ece3.1086", doi_data = "10.5061/dryad.p2r8r", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Robust design CMR; the per-visit counts are a recode of these histories.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design capture-recapture",
  sampling_protocol = "live_trap", design = "Robust design (2 years x 2 occasions, 56 sites)", realm = "Terrestrial",
  country = "CAN", coordinates = "None in source", notes = "BACI nest-box experiment.")
