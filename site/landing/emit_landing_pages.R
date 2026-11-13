# Per-table landing pages (#13), a Quarto post-render step.
#
# Writes, under _site/tables/:
#   <table>/index.html  one page per published table, with schema.org/Dataset JSON-LD
#   <table>/eml.xml     a minimal EML 2.2 record of the same facts
#   index.html          an A-Z list of every page
# and appends the pages to Quarto's _site/sitemap.xml.
#
# Everything comes from committed files: metadata/*.csv (the pipeline's outputs),
# output/<table>__dataset.json, releases/*.csv. Nothing reads a table CSV or
# calls Redivis, so a local render and CI write the same pages.
# Rules (which tables get a page, tombstones, determinism) are in README.md here.
# Run from site/ (Quarto runs post-render steps in the project directory).

suppressPackageStartupMessages(library(jsonlite))

SITE_URL <- "https://ben-domingue.github.io/eco"
GH       <- "https://github.com/ben-domingue/eco"
OUT      <- "_site/tables"
GA_ID    <- "G-H94NN0RR8L"

rd <- function(f) read.csv(f, check.names = FALSE, stringsAsFactors = FALSE,
                           colClasses = "character", na.strings = character())
meta  <- rd("../metadata/metadata.csv")
bib   <- rd("../metadata/biblio.csv")
tags  <- rd("../metadata/tags.csv")
loc   <- rd("../metadata/table_locations.csv")
rel   <- rd("../releases/manifest.csv")
notes <- rd("../releases/data_notes.csv")
chg   <- rd("../releases/table_changes.csv")
wd    <- rd("../releases/withdrawals.csv")
eco_version <- rel$eco_version[nrow(rel)]
release_date <- substr(rel$date[nrow(rel)], 1, 10)

# ---------------------------------------------------------------- helpers

esc <- function(x) {
  x <- as.character(x); x[is.na(x)] <- ""
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE); gsub("\"", "&quot;", x, fixed = TRUE)
}
nz <- function(x) length(x) == 1 && !is.na(x) && nzchar(x)
num <- function(x) format(as.numeric(x), big.mark = ",", scientific = FALSE, trim = TRUE)
# Inline markdown the metadata uses: `code` and [text](url). Applied after esc().
md <- function(x) {
  x <- gsub("`([^`]+)`", "<code>\\1</code>", x)
  gsub("\\[([^]]+)\\]\\((https?://[^)]+)\\)", "<a href=\"\\2\">\\1</a>", x)
}
linkify <- function(x) gsub("(^|\\s)(https?://[^ <]+[^ <.,;)])", "\\1<a href=\"\\2\">\\2</a>", x)
# "1 periods" -> "1 period"
pl <- function(n, w) paste0(num(n), " ", w, if (as.numeric(n) == 1) "" else "s")
kv <- function(rows) {
  rows <- Filter(function(r) nz(r[[2]]), rows)
  paste0("<table class=\"kv\">\n", paste0("<tr><th>", vapply(rows, `[[`, "", 1), "</th><td>",
         vapply(rows, `[[`, "", 2), "</td></tr>", collapse = "\n"), "\n</table>\n")
}
section <- function(h, body, id = NULL) if (!nzchar(body)) "" else
  paste0("<h2", if (!is.null(id)) paste0(" id=\"", id, "\""), ">", h, "</h2>\n", body)
doi_url <- function(d) if (!nz(d)) "" else if (grepl("^https?://", d)) d else paste0("https://doi.org/", d)
sci <- function(x) if (is.null(x)) "" else as.character(x)[1]

# "Last, First; Last, First" -> schema.org Person/Organization
people <- function(s) {
  if (!nz(s)) return(list())
  lapply(trimws(strsplit(s, ";", fixed = TRUE)[[1]]), function(p) {
    if (grepl(",", p)) {
      fam <- trimws(sub(",.*", "", p)); giv <- trimws(sub("^[^,]*,", "", p))
      list(`@type` = "Person", name = trimws(paste(giv, fam)), givenName = giv, familyName = fam)
    } else list(`@type` = "Organization", name = p)
  })
}

# ISO 8601 interval/date, or NULL for the prose some deposits need ("survey years
# not stated in the deposit ...").
iso_period <- "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?(/[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?)?$"
iso_cov <- function(tc) if (nz(tc) && grepl(iso_period, tc)) tc else NULL
# EML calendarDate takes a year or a full date, not a year-month.
eml_date <- function(d, end = FALSE) {
  if (nchar(d) != 7) return(d)
  if (!end) return(paste0(d, "-01"))
  first <- as.Date(paste0(d, "-01"))
  nxt <- seq(first, by = "month", length.out = 2)[2]
  format(nxt - 1)
}

PAGE_CSS <- paste0(
":root{--fg:#222;--muted:#5b625e;--line:#e3e8e5;--soft:#f4f7f5;--accent:#2f6b4f;--bg:#fff;",
"--warn-bg:#fff6e5;--warn-line:#d98b1f}",
"@media (prefers-color-scheme:dark){:root{--fg:#e6ebe8;--muted:#a3aca7;--line:#36403b;",
"--soft:#1d2420;--accent:#8fd0ad;--bg:#121614;--warn-bg:#2b2416;--warn-line:#c98a2c}}",
"html{background:var(--bg)}",
"body{font-family:'Source Sans 3','Segoe UI',Roboto,Helvetica,Arial,sans-serif;line-height:1.55;",
"margin:0;color:var(--fg);background:var(--bg)}",
"main{max-width:52rem;margin:0 auto;padding:0 16px 4rem}",
"a{color:var(--accent)}",
"header.top{background:#1f3d2f;margin:0 0 1.25rem;padding:.6rem 16px}",
"header.top div{max-width:52rem;margin:0 auto}",
"header.top a{color:#f3f6f4;text-decoration:none;font-weight:700;letter-spacing:.02em}",
"header.top img{height:30px;vertical-align:middle}",
"nav.crumb{font-size:.85rem;color:var(--muted);margin-bottom:.8rem}",
"h1{font-size:1.5rem;margin:.2rem 0 .3rem;word-break:break-word;font-family:ui-monospace,Menlo,Consolas,monospace}",
".title{font-size:1.15rem;font-weight:600;margin:.2rem 0 .4rem}",
".sub{color:var(--muted);font-size:.92rem;margin:0 0 1rem}",
"h2{font-size:1rem;margin:1.9rem 0 .5rem;padding-bottom:.25rem;border-bottom:1px solid var(--line);",
"text-transform:uppercase;letter-spacing:.05em;color:var(--muted)}",
"table.kv{border-collapse:collapse;width:100%;font-size:.95rem}",
"table.kv th{text-align:left;font-weight:600;padding:.32rem .8rem .32rem 0;vertical-align:top;",
"width:11rem;color:var(--muted)}",
"table.kv td{padding:.32rem 0;vertical-align:top;overflow-wrap:anywhere}",
"table.kv tr+tr th,table.kv tr+tr td{border-top:1px solid var(--line)}",
"@media (max-width:560px){table.kv th{width:7.5rem}}",
"pre{background:var(--soft);border:1px solid var(--line);border-radius:5px;padding:.7rem .85rem;",
"overflow-x:auto;font-size:.85rem}",
"code{background:var(--soft);border-radius:3px;padding:.05rem .3rem;font-size:.88em}",
"pre code{background:none;padding:0}",
".cite{background:var(--soft);border-left:4px solid var(--accent);padding:.6rem .9rem;margin:.6rem 0 1rem}",
".cite p{margin:.25rem 0}",
".warn{background:var(--warn-bg);border-left:5px solid var(--warn-line);border-radius:5px;",
"padding:.85rem 1rem;margin:1rem 0 1.4rem}",
".cols code{display:inline-block;margin:0 .25rem .3rem 0}",
"footer{margin-top:2.5rem;padding-top:1rem;border-top:1px solid var(--line);font-size:.85rem;color:var(--muted)}",
"input.find{width:100%;max-width:24rem;padding:.45rem .6rem;font-size:.95rem;border:1px solid var(--line);",
"border-radius:5px;margin:.2rem 0 1rem;background:var(--bg);color:var(--fg)}",
".scroll{overflow-x:auto}",
"table.idx{border-collapse:collapse;width:100%;font-size:.92rem}",
"table.idx th{text-align:left;padding:.35rem .6rem .35rem 0;border-bottom:1px solid var(--line)}",
"table.idx td{padding:.35rem .6rem .35rem 0;border-top:1px solid var(--line);vertical-align:top}",
"table.idx td.n{text-align:right;white-space:nowrap}")

GA <- paste0(
"<script async src=\"https://www.googletagmanager.com/gtag/js?id=", GA_ID, "\"></script>\n",
"<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}",
"gtag('js',new Date());gtag('config','", GA_ID, "');</script>\n")

head_html <- function(title, canonical, description, noindex = FALSE, extra = "") paste0(
"<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
"<title>", esc(title), "</title>\n",
"<link rel=\"canonical\" href=\"", esc(canonical), "\">\n",
"<meta name=\"description\" content=\"", esc(substr(description, 1, 300)), "\">\n",
if (noindex) "<meta name=\"robots\" content=\"noindex\">\n" else "",
"<meta property=\"og:title\" content=\"", esc(title), "\">\n",
"<meta property=\"og:description\" content=\"", esc(substr(description, 1, 300)), "\">\n",
"<meta property=\"og:image\" content=\"", SITE_URL, "/logos/og-image.png\">\n",
"<link rel=\"icon\" href=\"", SITE_URL, "/logos/favicon.ico\">\n",
"<style>", PAGE_CSS, "</style>\n", GA, extra, "</head>\n<body>\n",
"<header class=\"top\"><div><a href=\"", SITE_URL, "/\"><img src=\"", SITE_URL,
"/logos/eco-lockup-dark.svg\" alt=\"eco\"></a></div></header>\n<main>\n")

FOOT <- function() paste0(
"<footer>Part of <a href=\"", SITE_URL, "/\">eco</a>, ecological detection data in one format. ",
"This page describes eco v", esc(eco_version), " (released ", release_date, "). ",
"<a href=\"", SITE_URL, "/tables/\">All table pages</a> &middot; ",
"<a href=\"", SITE_URL, "/data.html\">Browse and filter the tables</a> &middot; ",
"<a href=\"", GH, "/issues/new\">Report a problem</a></footer>\n</main>\n</body>\n</html>\n")

# ---------------------------------------------------------------- which tables

published_status <- !grepl("do_not_publish", tags$status)
withdrawn <- wd[!grepl("__", wd$table) & !nzchar(wd$reinstated), ]
tbl <- merge(meta, bib, by = "table", suffixes = c("", ".bib"))
tbl <- merge(tbl, tags, by = "table", suffixes = c("", ".tag"))
tbl <- tbl[tbl$table %in% tags$table[published_status], ]
held <- tbl$table[!nzchar(tbl$spdx)]          # no recorded licence: no page
if (length(held)) message("landing: held (no licence): ", paste(held, collapse = ", "))
tbl <- tbl[nzchar(tbl$spdx) & !tbl$table %in% withdrawn$table, ]
tbl <- tbl[order(tbl$table), ]
stopifnot(!anyDuplicated(tolower(tbl$table)), all(tbl$table == tolower(tbl$table)))

# ---------------------------------------------------------------- one page

jsonld <- function(r, d, pt) {
  desc <- r$description
  if (nchar(desc) < 50) desc <- paste(r$title, desc, sep = ". ")
  desc <- substr(desc, 1, 5000)
  tc <- iso_cov(sci(d$temporalCoverage))
  place <- list(`@type` = "Place", name = sci(d$geographicCoverage))
  if (!is.null(pt)) place$geo <- list(`@type` = "GeoCoordinates",
                                      latitude = as.numeric(pt$lat), longitude = as.numeric(pt$lon))
  if (!nz(place$name) && is.null(pt)) place <- NULL
  x <- list(
    `@context` = "https://schema.org", `@type` = "Dataset",
    name = r$title, alternateName = r$table, description = desc,
    url = paste0(SITE_URL, "/tables/", r$table, "/"),
    creator = people(r$creator),
    license = r$license_url,
    isAccessibleForFree = TRUE,
    isBasedOn = doi_url(if (nz(r$doi_data)) r$doi_data else r$source_url),
    citation = c(if (nz(r$doi_paper)) doi_url(r$doi_paper), r$citation),
    keywords = unique(Filter(nz, c(r$taxon_group, r$model_family, r$sampling_protocol,
                                   r$realm, r$response_type, "ecology", "detection data"))),
    temporalCoverage = tc,
    spatialCoverage = place,
    variableMeasured = unlist(d$columns),
    version = paste0("eco v", eco_version),
    includedInDataCatalog = list(`@type` = "DataCatalog", name = "eco", url = paste0(SITE_URL, "/")),
    subjectOf = list(`@type` = "DataDownload", encodingFormat = "application/eml+xml",
                     contentUrl = paste0(SITE_URL, "/tables/", r$table, "/eml.xml"))
  )
  if (!length(x$creator)) x$creator <- NULL
  if (!nz(x$license)) x$license <- NULL
  x <- Filter(Negate(is.null), x)
  gsub("</", "<\\/", toJSON(x, auto_unbox = TRUE, pretty = TRUE), fixed = TRUE)
}

page <- function(r, d, pt, sibs) {
  url <- paste0(SITE_URL, "/tables/", r$table, "/")
  dims <- paste(pl(r$n_units, "unit"), "&times;", num(r$n_taxa), if (r$n_taxa == "1") "taxon" else "taxa",
                "&times;", pl(r$n_periods, "period"), "&times;", pl(r$n_occasions, "occasion"), ";",
                pl(r$n_rows, "row"))
  dims <- sub(" ;", ";", dims, fixed = TRUE)
  cite <- paste0("<div class=\"cite\"><p><strong>Cite the data's originators.</strong> ",
                 linkify(esc(r$citation)), "</p>",
                 if (nz(r$bibtex)) paste0("<details><summary>BibTeX</summary><pre><code>",
                                          esc(r$bibtex), "</code></pre></details>"),
                 "<p>In R: <code>eco_cite(\"", r$table, "\")</code>. ",
                 "<a href=\"", SITE_URL, "/r.html#how-to-cite\">How to cite</a></p></div>\n")
  tc <- sci(d$temporalCoverage)
  cov <- paste(Filter(nz, c(r$country, r$realm, esc(sci(d$geographicCoverage)), esc(tc))), collapse = "; ")
  about <- kv(list(
    list("Model family", esc(r$model_family)),
    list("Design", esc(r$design)),
    list("Protocol", esc(sci(d$samplingProtocol))),
    list("Response", paste0("<code>", esc(r$response_type), "</code>")),
    list("Unit", esc(r$unit_kind)),
    list("Coverage", cov),
    list("Coordinates", esc(r$coordinates)),
    list("Closure", if (nz(r$closure) && r$closure != "none") paste0("<code>", esc(r$closure), "</code>")),
    list("Taxa", esc(r$taxon_group)),
    list("Size", dims),
    list("Sample floor", paste0(esc(r$sample_floor), " <span class=\"sub\">(30+ units and 2+ occasions or periods; ",
                                "<a href=\"", SITE_URL, "/standard.html\">standard</a>)</span>")),
    list("Survey evidence", paste0("<code>", esc(r$survey_evidence), "</code>",
                                   if (!is.null(d$surveyEvidenceNote)) paste0(": ", md(esc(sci(d$surveyEvidenceNote)))))),
    list("Licence", paste0(if (nz(r$license_url)) paste0("<a href=\"", esc(r$license_url), "\">", esc(r$spdx), "</a>")
                           else esc(r$spdx),
                           if (nz(r$original_license) && r$original_license != r$spdx)
                             paste0(" (source: ", esc(r$original_license), ")"))),
    list("Source", paste0("<a href=\"", esc(r$source_url), "\">", esc(r$source_url), "</a>")),
    list("Paper", if (nz(r$doi_paper)) paste0("<a href=\"", esc(doi_url(r$doi_paper)), "\">",
                                             esc(r$doi_paper), "</a>"))))
  cols <- paste0("<p class=\"cols\">", paste0("<code>", esc(unlist(d$columns)), "</code>", collapse = " "),
                 "</p><p class=\"sub\">Column meanings follow their prefixes (<code>unit_</code>, ",
                 "<code>period_</code>, <code>obs_</code>, <code>taxon_</code>): ",
                 "<a href=\"", SITE_URL, "/standard.html\">the standard</a>, E5.</p>\n")
  st <- d$sideTables
  side <- if (length(st)) paste0("<ul>\n", paste0(
    "<li><code>", esc(r$table), "__", esc(names(st)), "</code>: ",
    vapply(st, function(s) num(s$rows), ""), " rows; ",
    vapply(st, function(s) paste0("<code>", esc(unlist(s$columns)), "</code>", collapse = " "), ""),
    "</li>", collapse = "\n"), "\n</ul>\n") else ""
  nt <- c(if (nz(r$notes.tag)) md(esc(r$notes.tag)),
          if (!is.null(d$designNote)) md(esc(sci(d$designNote))),
          if (any(notes$table == r$table))
            paste0("<strong>Data note.</strong> ", md(esc(notes$note[notes$table == r$table]))))
  nt <- if (length(nt)) paste0("<p>", nt, "</p>", collapse = "\n") else ""
  ns <- unlist(d$notShipped)
  notship <- if (length(ns)) paste0("<ul>", paste0("<li>", md(esc(ns)), "</li>", collapse = ""), "</ul>\n") else ""
  cg <- chg[chg$table == r$table, ]
  changes <- if (nrow(cg)) paste0("<ul>", paste0("<li>", cg$date, ", eco v", esc(cg$eco_version), " (", esc(cg$kind),
                    "): ", md(esc(cg$summary)),
                    ifelse(nzchar(cg$issue), paste0(" (<a href=\"", GH, "/issues/", cg$issue, "\">#", cg$issue, "</a>)"), ""),
                    "</li>", collapse = ""), "</ul>\n") else ""
  get <- paste0(
    "<p>Every table is served as CSV on Redivis to anyone, no account needed. In R:</p>\n",
    "<pre><code>remotes::install_github(\"ben-domingue/eco\", subdir = \"Rpkg\")\nlibrary(eco)\n",
    "d &lt;- eco_fetch(\"", r$table, "\")</code></pre>\n",
    "<p>Built from the deposit by <a href=\"", GH, "/blob/main/", esc(r$script), "\"><code>",
    esc(r$script), "</code></a>, which records every decision made along the way. ",
    "Also: <a href=\"eml.xml\">EML metadata</a> &middot; ",
    "<a href=\"", SITE_URL, "/data.html#", r$table, "\">entry on the data page</a></p>\n")
  related <- if (length(sibs)) paste0("<p>From the same deposit:</p><ul>", paste0(
    "<li><a href=\"../", sibs, "/\"><code>", sibs, "</code></a></li>", collapse = ""), "</ul>\n") else ""
  prov <- kv(list(
    list("eco version", paste0("v", esc(eco_version))),
    list("Standard", esc(r$standard_version)),
    list("Built", esc(r$build_date)),
    list("Tagged by", esc(r$rater))))
  desc <- paste0(r$title, ". ", r$description)
  paste0(
    head_html(paste0(r$table, " | eco"), url, desc,
              extra = paste0("<link rel=\"alternate\" type=\"application/eml+xml\" href=\"eml.xml\" title=\"EML\">\n",
                             "<script type=\"application/ld+json\">\n", jsonld(r, d, pt), "\n</script>\n")),
    "<nav class=\"crumb\"><a href=\"", SITE_URL, "/\">eco</a> / <a href=\"", SITE_URL,
    "/tables/\">Tables</a> / ", r$table, "</nav>\n",
    "<h1>", r$table, "</h1>\n<p class=\"title\">", esc(r$title), "</p>\n",
    "<p class=\"sub\">", dims, "</p>\n",
    cite,
    "<p>", md(esc(r$description)), "</p>\n",
    section("About this table", about),
    section("Notes", nt, id = "notes"),
    section("Columns", cols),
    section("Side tables", side),
    section("Get the data", get),
    section("Not shipped", notship),
    section("Changes since release", changes, id = "changes"),
    section("Related tables", related),
    section("Version and provenance", prov),
    FOOT())
}

# ---------------------------------------------------------------- EML 2.2

xesc <- function(x) { x <- esc(x); gsub("'", "&apos;", x, fixed = TRUE) }
eml <- function(r, d, pt) {
  ind <- function(p, tag) if (p$`@type` == "Person")
    paste0("  <", tag, "><individualName><givenName>", xesc(p$givenName), "</givenName><surName>",
           xesc(p$familyName), "</surName></individualName></", tag, ">\n") else
    paste0("  <", tag, "><organizationName>", xesc(p$name), "</organizationName></", tag, ">\n")
  cr <- people(r$creator)
  if (!length(cr)) cr <- list(list(`@type` = "Organization", name = "Unknown (see source)"))
  geo <- ""
  if (!is.null(pt)) {
    gd <- paste0(sci(d$geographicCoverage), if (nz(sci(d$geographicCoverage))) ". " else "",
                 "Point is the centre of the table's units rounded to 0.1 degree (", pt$basis,
                 "), not a bounding box; extent about ", pt$extent_km, " km.")
    geo <- paste0("      <geographicCoverage><geographicDescription>", xesc(gd), "</geographicDescription>",
                  "<boundingCoordinates><westBoundingCoordinate>", pt$lon, "</westBoundingCoordinate>",
                  "<eastBoundingCoordinate>", pt$lon, "</eastBoundingCoordinate>",
                  "<northBoundingCoordinate>", pt$lat, "</northBoundingCoordinate>",
                  "<southBoundingCoordinate>", pt$lat, "</southBoundingCoordinate>",
                  "</boundingCoordinates></geographicCoverage>\n")
  }
  tmp <- ""
  tc <- iso_cov(sci(d$temporalCoverage))
  if (!is.null(tc)) {
    p <- strsplit(tc, "/", fixed = TRUE)[[1]]; if (length(p) == 1) p <- c(p, p)
    tmp <- paste0("      <temporalCoverage><rangeOfDates><beginDate><calendarDate>", eml_date(p[1]),
                  "</calendarDate></beginDate><endDate><calendarDate>", eml_date(p[2], TRUE),
                  "</calendarDate></endDate></rangeOfDates></temporalCoverage>\n")
  }
  coverage <- if (nzchar(geo) || nzchar(tmp)) paste0("    <coverage>\n", geo, tmp, "    </coverage>\n") else ""
  kw <- unique(Filter(nz, c(r$taxon_group, r$model_family, r$sampling_protocol, r$realm, r$response_type)))
  cols <- unlist(d$columns)
  method <- paste(Filter(nz, c(sci(d$samplingProtocol),
                               paste0("Survey evidence (", r$survey_evidence, "): ", sci(d$surveyEvidenceNote)),
                               paste0("Built by ", GH, "/blob/main/", r$script, " under ", r$standard_version, "."))),
                  collapse = "\n")
  pub <- if (grepl("^[0-9]{4}", r$pub_date)) substr(r$pub_date, 1, 4) else ""
  paste0(
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
"<eml:eml xmlns:eml=\"https://eml.ecoinformatics.org/eml-2.2.0\" ",
"xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" ",
"xsi:schemaLocation=\"https://eml.ecoinformatics.org/eml-2.2.0 https://eml.ecoinformatics.org/eml-2.2.0/eml.xsd\" ",
"packageId=\"eco.", r$table, ".v", eco_version, "\" system=\"https://ben-domingue.github.io/eco\">\n",
"  <dataset>\n",
"    <alternateIdentifier>", r$table, "</alternateIdentifier>\n",
if (nz(r$doi_data)) paste0("    <alternateIdentifier system=\"https://doi.org\">", xesc(sub("^https?://(dx\\.)?doi.org/", "", r$doi_data)), "</alternateIdentifier>\n"),
"    <title>", xesc(r$title), "</title>\n",
paste(vapply(cr, function(p) paste0("  ", ind(p, "creator")), ""), collapse = ""),
if (nzchar(pub)) paste0("    <pubDate>", pub, "</pubDate>\n"),
"    <abstract><para>", xesc(r$description), "</para></abstract>\n",
if (length(kw)) paste0("    <keywordSet>", paste0("<keyword>", xesc(kw), "</keyword>", collapse = ""), "</keywordSet>\n"),
"    <intellectualRights><para>", xesc(r$spdx), if (nz(r$license_url)) paste0(" (", xesc(r$license_url), ")"),
". Cite the originators: ", xesc(r$citation), "</para></intellectualRights>\n",
"    <distribution><online><url function=\"information\">", SITE_URL, "/tables/", r$table, "/</url></online></distribution>\n",
coverage,
"    <contact><organizationName>eco</organizationName><onlineUrl>", GH, "/issues</onlineUrl></contact>\n",
"    <methods><methodStep><description><para>", xesc(method), "</para></description></methodStep></methods>\n",
"    <otherEntity>\n",
"      <entityName>", r$table, "</entityName>\n",
"      <entityDescription>One row per survey of a taxon at a unit, in the eco standard (", xesc(r$standard_version),
"); y is ", xesc(r$response_type), ". Columns: ", xesc(paste(cols, collapse = ", ")), ".</entityDescription>\n",
"      <entityType>text/csv</entityType>\n",
"    </otherEntity>\n",
"  </dataset>\n",
"</eml:eml>\n")
}

# ---------------------------------------------------------------- tombstones

link_tables <- function(x) {
  for (t in tbl$table[vapply(tbl$table, function(t) grepl(paste0("\\b", t, "\\b"), x), NA)])
    x <- gsub(paste0("\\b", t, "\\b"), paste0("<a href=\"../", t, "/\"><code>", t, "</code></a>"), x)
  x
}
tombstone <- function(w) {
  url <- paste0(SITE_URL, "/tables/", w$table, "/")
  why <- switch(w$reason,
    care_review = "withdrawn while its data originators are consulted",
    duplicate = "withdrawn as a duplicate",
    paste("withdrawn:", w$reason))
  paste0(
    head_html(paste0(w$table, " (withdrawn) | eco"), url, paste0(w$table, " was ", why, "."), noindex = TRUE),
    "<nav class=\"crumb\"><a href=\"", SITE_URL, "/\">eco</a> / <a href=\"", SITE_URL,
    "/tables/\">Tables</a> / ", w$table, "</nav>\n",
    "<h1>", w$table, "</h1>\n",
    "<div class=\"warn\"><p><strong>Withdrawn ", w$withdrawn, ".</strong> This table was ", why,
    ".",
    if (nz(w$released)) paste0(" It was removed in eco v", esc(w$released), "."), "</p>",
    if (nz(w$note)) paste0("<p>", link_tables(md(esc(w$note))), "</p>"), "</div>\n",
    "<p>See the <a href=\"", SITE_URL, "/corrections.html\">corrections page</a> for the withdrawal ledger.</p>\n",
    FOOT())
}

# ---------------------------------------------------------------- index

index_page <- function(tbl) {
  rows <- paste0("<tr><td><a href=\"", tbl$table, "/\"><code>", tbl$table, "</code></a><br>",
                 "<span class=\"sub\">", esc(tbl$title), "</span></td>",
                 "<td>", esc(tbl$model_family), "</td>",
                 "<td class=\"n\">", vapply(tbl$n_rows, num, ""), "</td>",
                 "<td class=\"n\">", esc(tbl$spdx), "</td></tr>", collapse = "\n")
  paste0(
    head_html("Table pages | eco", paste0(SITE_URL, "/tables/"),
              paste0("One page per eco table: ", nrow(tbl), " tables of ecological detection data."),
              extra = paste0("<script>function f(q){q=q.toLowerCase();",
                             "document.querySelectorAll('#tbl tbody tr').forEach(function(r){",
                             "r.style.display=r.textContent.toLowerCase().indexOf(q)<0?'none':''})}</script>\n")),
    "<nav class=\"crumb\"><a href=\"", SITE_URL, "/\">eco</a> / Tables</nav>\n",
    "<h1>Table pages</h1>\n",
    "<p>", nrow(tbl), " tables in eco v", esc(eco_version), ", one page each. ",
    "To filter by family, taxa or protocol, use <a href=\"", SITE_URL, "/data.html\">the data page</a>.</p>\n",
    "<input class=\"find\" type=\"text\" placeholder=\"Filter by name or title...\" oninput=\"f(this.value)\">\n",
    "<div class=\"scroll\"><table class=\"idx\" id=\"tbl\"><thead><tr><th>Table</th><th>Family</th>",
    "<th>Rows</th><th>Licence</th></tr></thead>\n<tbody>\n", rows, "\n</tbody></table></div>\n",
    FOOT())
}

# ---------------------------------------------------------------- write

unlink(OUT, recursive = TRUE)
dir.create(OUT, recursive = TRUE)
write_file <- function(path, txt) { con <- file(path, "wb"); on.exit(close(con)); writeBin(charToRaw(enc2utf8(txt)), con) }

for (i in seq_len(nrow(tbl))) {
  r <- as.list(tbl[i, ])
  d <- read_json(file.path("../output", paste0(r$table, "__dataset.json")))
  li <- loc[loc$table == r$table & nzchar(loc$lat), ]
  pt <- if (nrow(li)) as.list(li[1, ]) else NULL
  sibs <- setdiff(tbl$table[tbl$deposit == r$deposit & nzchar(r$deposit)], r$table)
  dir.create(file.path(OUT, r$table))
  write_file(file.path(OUT, r$table, "index.html"), page(r, d, pt, sibs))
  write_file(file.path(OUT, r$table, "eml.xml"), eml(r, d, pt))
}
for (i in seq_len(nrow(withdrawn))) {
  w <- as.list(withdrawn[i, ])
  if (w$table %in% tbl$table) next
  dir.create(file.path(OUT, w$table), showWarnings = FALSE)
  write_file(file.path(OUT, w$table, "index.html"), tombstone(w))
}
write_file(file.path(OUT, "index.html"), index_page(tbl))

# Sitemap: Quarto writes _site/sitemap.xml (site-url is set); add the live pages,
# not the tombstones. No <lastmod>: nothing here dates a table's content.
sm <- "_site/sitemap.xml"
if (file.exists(sm)) {
  doc <- xml2::read_xml(sm)
  ns <- xml2::xml_ns(doc)
  old <- xml2::xml_find_all(doc, "//d1:url[contains(d1:loc, '/tables/')]", ns)
  xml2::xml_remove(old)
  for (u in paste0(SITE_URL, "/tables/", c("", paste0(tbl$table, "/"))))
    xml2::xml_add_child(xml2::xml_add_child(doc, "url"), "loc", u)
  xml2::write_xml(doc, sm)
}
cat(sprintf("landing: %d table pages, %d tombstones, index and sitemap written to %s\n",
            nrow(tbl), sum(!withdrawn$table %in% tbl$table), OUT))
