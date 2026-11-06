#!/usr/bin/env Rscript
# Table:  lindenmayer_2022_nsw_woodland_birds_comm
# Source: Dryad doi:10.5061/dryad.8cz8w9gv7 (CC0 1.0, as shown on the Dryad page; published
#         2022-12-19). Lindenmayer, D. Data for: Context dependency in interference competition
#         among birds in an endangered woodland ecosystem.
# Paper:  Lindenmayer, D. et al. (2023). Diversity and Distributions, doi:10.1111/ddi.13680.
#         Repeated bird surveys of temperate eucalypt woodland sites in south-eastern Australia
#         over 19 years, analysed with a Bayesian multi-species occupancy/detection model of
#         interference competition by the noisy miner (Dryad methods).
# Data:   DataForPublication_20220923.csv (4,627 rows = site x year x repeat: SiteCode (259 sites,
#         91 farms), SurveyYear (17 years 2002-2020), NPP91011Mean (mean spring net primary
#         productivity within 500 m), TreeCoverNSWPer (% tree cover within 500 m), NoisyMinorDet
#         (noisy miner detected at the site that year), RepeatNumber (repeat 1..k, k = 1-6),
#         then 31 species columns, 1 detected / 0 not). README.txt describes the columns. No NA.
#         Asserted: (site, year, repeat) unique, repeats numbered 1..k except TBOO-1 in 2008 (1 and 3,
#         kept as numbered); NPP and tree cover
#         constant per site.
# Mapping (standard: dynamic community occupancy, E9 core): unit = SiteCode; period = year
#   (__periods, 17 survey years); occasion = RepeatNumber; taxon = species code; y = the cell.
#   unit_: NPP, tree cover. Survey evidence: row_presence (a row per conducted repeat survey;
#   every species has a value on it). The 31 species are the authors' analysis set.
#   Not shipped: NoisyMinorDet, a site-year summary of the noisy miner's detections in the same
#   surveys (the paper's predictor; the miner's per-survey detections are not in the deposit).
#   Scientific names are the processor's, from the deposited common names. No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lindenmayer_2022_nsw_woodland_birds_comm"
dir <- download_dryad("10.5061/dryad.8cz8w9gv7", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^DataForPublication_20220923\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f)
SP <- c(Australian_Magpie = "Gymnorhina tibicen", Australian_Raven = "Corvus coronoides", Black.faced_Cuckoo.shrike = "Coracina novaehollandiae",
        Brown_Treecreeper = "Climacteris picumnus", Common_Starling = "Sturnus vulgaris", Crested_Pigeon = "Ocyphaps lophotes",
        Crested_Shrike.tit = "Falcunculus frontatus", Crimson_Rosella = "Platycercus elegans", Dusky_Woodswallow = "Artamus cyanopterus",
        Eastern_Rosella = "Platycercus eximius", Galah = "Eolophus roseicapilla", Grey_Shrike.thrush = "Colluricincla harmonica",
        Jacky_Winter = "Microeca fascinans", Laughing_Kookaburra = "Dacelo novaeguineae", Magpie.lark = "Grallina cyanoleuca",
        Noisy_Friarbird = "Philemon corniculatus", Pied_Butcherbird = "Cracticus nigrogularis", Red.rumped_Parrot = "Psephotus haematonotus",
        Red_Wattlebird = "Anthochaera carunculata", Rufous_Songlark = "Cincloramphus mathewsi", Rufous_Whistler = "Pachycephala rufiventris",
        Sacred_Kingfisher = "Todiramphus sanctus", Striated_Pardalote = "Pardalotus striatus", Superb_Fairy.wren = "Malurus cyaneus",
        Weebill = "Smicrornis brevirostris", White.browed_Woodswallow = "Artamus superciliosus", White.plumed_Honeyeater = "Ptilotula penicillata",
        White.winged_Chough = "Corcorax melanorhamphos", White.winged_Triller = "Lalage tricolor", Willie_Wagtail = "Rhipidura leucophrys",
        Yellow.rumped_Thornbill = "Acanthiza chrysorrhoa")
stopifnot(identical(names(d), c("SiteCode", "SurveyYear", "NPP91011Mean", "TreeCoverNSWPer", "NoisyMinorDet", "RepeatNumber", names(SP))),
          nrow(d) == 4627, uniqueN(d$SiteCode) == 259, !anyDuplicated(d[, .(SiteCode, SurveyYear, RepeatNumber)]), !anyNA(d),
          d[, identical(sort(RepeatNumber), seq_len(.N)), by = .(SiteCode, SurveyYear)][, sum(!V1)] == 1,   # TBOO-1 2008 has repeats 1 and 3
          d[, .(a = uniqueN(NPP91011Mean), b = uniqueN(TreeCoverNSWPer)), by = SiteCode][, all(a == 1 & b == 1)],
          all(as.matrix(d[, names(SP), with = FALSE]) %in% 0:1))
YRS <- sort(unique(d$SurveyYear)); stopifnot(length(YRS) == 17)
code <- toupper(paste0(substr(sub(" .*", "", SP), 1, 3), substr(sub(".* ", "", SP), 1, 3)))
stopifnot(!anyDuplicated(code))
long <- melt(d[, c("SiteCode", "SurveyYear", "RepeatNumber", "NPP91011Mean", "TreeCoverNSWPer", names(SP)), with = FALSE],
             id.vars = c("SiteCode", "SurveyYear", "RepeatNumber", "NPP91011Mean", "TreeCoverNSWPer"), variable.name = "sp", value.name = "y", variable.factor = FALSE)
long <- long[, .(unit = SiteCode, taxon = code[match(sp, names(SP))], y = as.integer(y), period = match(SurveyYear, YRS),
                 occasion = as.integer(RepeatNumber), unit_npp_spring_500m = NPP91011Mean, unit_tree_cover_pct_500m = TreeCoverNSWPer)]
long <- order_eco(long)
stopifnot(nrow(long) == 4627 * 31)
periods <- data.table(period = seq_along(YRS), period_year = YRS)
taxa <- make_taxa(code, unname(SP), vernacularName = gsub("_", " ", gsub("\\.", "-", names(SP))),
                  lookupName = sub("^Corcorax melanorhamphos$", "Corcorax melanoramphos", sub("^Cincloramphus mathewsi$", "Megalurus mathewsi", sub("^Ptilotula penicillata$", "Lichenostomus penicillatus", unname(SP)))))
dataset <- list(
  title = "Detections of 31 woodland bird species on repeated surveys of 259 temperate woodland sites in south-eastern Australia, 17 years 2002-2020",
  creator = "Lindenmayer, David", pubDate = "2022", doi = "10.5061/dryad.8cz8w9gv7", sourceURL = "https://doi.org/10.5061/dryad.8cz8w9gv7",
  citation = "Lindenmayer, D. (2022). Data for: Context dependency in interference competition among birds in an endangered woodland ecosystem [Dataset]. Dryad. https://doi.org/10.5061/dryad.8cz8w9gv7",
  paperDOI = "10.1111/ddi.13680",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection of 31 bird species on 1-6 repeat surveys per site and year at 259 sites on farms in endangered temperate eucalypt woodland of south-eastern Australia, in 17 survey years between 2002 and 2020, with spring net primary productivity and tree cover around each site: the input of a multi-species occupancy model of interference competition by the noisy miner.",
  samplingProtocol = "Repeated on-the-ground bird surveys at fixed woodland sites, usually two repeats per site per survey year; each species recorded as detected or not on each repeat.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a survey year (repeats), open between years",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Temperate eucalypt woodland on farms (91 farm prefixes in the site codes), south-eastern Australia; no coordinates deposited",
  temporalCoverage = "2002/2020",
  notShipped = list(NoisyMinorDet = "noisy miner detected at the site that year: a summary of the same surveys' detections (the paper's predictor)",
                    other_species = "species recorded on the surveys but not in the authors' analysis set of 31"),
  notes = "Scientific names are the processor's, from the deposited common names. Survey years are not contiguous (no 2016 or 2018). The noisy miner itself is not a species column; only its site-year detection flag is deposited, which is not shipped.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lindenmayer_2022_nsw_woodland_birds_comm.R")
stage_dict_row(TABLE,
  description = "Repeat-survey detections of 31 woodland bird species at 259 temperate woodland sites in south-eastern Australia, 17 years 2002-2020.",
  url = "https://doi.org/10.5061/dryad.8cz8w9gv7",
  reference = "Lindenmayer, D. et al. (2023). Context dependency in interference competition among birds in an endangered woodland ecosystem. Diversity and Distributions.",
  doi_paper = "10.1111/ddi.13680", doi_data = "10.5061/dryad.8cz8w9gv7", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic community occupancy; noisy miner flag not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic community occupancy",
  sampling_protocol = "point_count", design = "Multi-season (17 years, 1-6 repeats per year)", realm = "Terrestrial",
  country = "AUS", coordinates = "None in source", notes = "Woodland birds and the noisy miner question.")
