# Per-table landing pages (#13)

`emit_landing_pages.R` runs as a Quarto `post-render` step (`_quarto.yml`) and
writes, under `_site/tables/`:

- `<table>/index.html`: one page per published table, with `schema.org/Dataset`
  JSON-LD in the head, so Google Dataset Search can index each table on its own.
- `<table>/eml.xml`: a minimal EML 2.2.0 record of the same facts (DataONE/EDI).
- `index.html`: the A–Z list, linked from the navbar ("Table pages (A–Z)").

It also appends `/tables/` and every live page to Quarto's `_site/sitemap.xml`.

Adapted from IRW's `irw_site/landing/`. The structure is the same; the inputs
are not. Everything is read from committed files (`metadata/*.csv`,
`output/<table>__dataset.json`, `releases/*.csv`), never a table CSV and never
Redivis, so a local render and CI write identical pages and need no token.

## Which tables get a page

- **Every table in `metadata/` gets one**, except one whose tags `status` says
  `do_not_publish` or whose `spdx` licence is blank (held; named in the build log).
- **Withdrawn tables keep their URL as a tombstone**: a core table in
  `releases/withdrawals.csv` with no `reinstated` date gets a `noindex` page with
  the date, the reason and the ledger note (a live table the note names is
  linked). Tombstones are not in the sitemap.
- **Data notes** (`releases/data_notes.csv`) and **table changes**
  (`releases/table_changes.csv`) show on the page; neither keeps it out of search.
  eco has no known-issues banner: a defect is fixed and recorded, not flagged.

## What a page says

The deposit's citation comes first (#149), then the description, the facts the
data page card has, columns and side tables (from `__dataset.json`), how to get
it in R, what was not shipped, changes since release, other tables from the same
deposit (`biblio.csv`'s `deposit`), and the eco version.

## JSON-LD and EML choices

- `creator` is the deposit's creators ("Last, First; ..." → Person; no comma →
  Organization). `isBasedOn` is the deposit, `citation` the paper DOI and the
  deposit citation.
- `temporalCoverage` only when `__dataset.json` has an ISO 8601 date or
  interval; the prose some deposits need ("survey years not stated") is left out.
  In EML a year-month becomes the first/last day of that month.
- The location is the homepage map's point (`metadata/table_locations.csv`):
  the centre of the units rounded to 0.1 degree, never finer. EML gets it as a
  degenerate bounding box and says so in `geographicDescription`.
- No `distribution`: the CSV endpoint depends on the shard, which nothing
  committed records. The page tells readers to use `eco_fetch()`.
- EML describes the table as an `otherEntity` (name, column list), not a
  `dataTable`: a `dataTable` needs a measurement scale per column, which is not
  recorded anywhere committed.
- `taxonomicCoverage` is left out: `__taxa` lives on Redivis, not in git.

## Rules

1. **Deterministic.** No timestamps, no unordered iteration: rendering twice
   gives byte-identical files.
2. **Idempotent sitemap.** The emitter removes any `/tables/` URLs before adding
   its own, so a rerun or partial render never duplicates entries.

## Checks after a change

```sh
cd site
Rscript landing/emit_landing_pages.R && cp -r _site/tables /tmp/run1 \
  && Rscript landing/emit_landing_pages.R && diff -r /tmp/run1 _site/tables   # must be empty
# EML against the official schema (github.com/NCEAS/eml, tag RELEASE_EML_2_2_0, xsd/eml.xsd)
python3 -c "import glob,sys; from lxml import etree; s=etree.XMLSchema(etree.parse(sys.argv[1])); \
  print(sum(not s.validate(etree.parse(f)) for f in glob.glob('_site/tables/*/eml.xml')), 'invalid')" path/to/eml.xsd
```

After deploying, spot-check a few pages in Google's Rich Results Test.
