# eco 0.1.0

`eco_filter()` gains `licence`: SPDX ids, or `"permissive"` (public domain, CC
BY, ODC-By, UK OGL: commercial use allowed, attribution at most) or
`"public-domain"`. Results carry a `licence` column (ben-domingue/eco#153).

`eco_cite(tables, format = c("text", "bibtex"), file = NULL)` cites the sources
behind a set of tables: one entry per source deposit and one per paper, not one
per table, with stable BibTeX keys (the deposit's first table name), then eco
itself at the version read (ben-domingue/eco#149). `eco_save_bibtex()` is now
`eco_cite(tables, "bibtex", file)`, so its entries are deduplicated and end with
eco's. The first `eco_fetch()` in a session prints a one-line reminder to cite
the original deposits; `options(eco.cite_reminder = FALSE)` silences it.

`eco_list_deposits()` lists the source deposits, one row per DOI or archive
record, with the number of tables built from each and their names, over the
same released tables as `eco_list_tables()`. `eco_info()` with no table now
reports "N tables from M deposits". The package help (`?eco`) defines table,
core, side table, deposit, shard and entry (ben-domingue/eco#10).

The core tables are split across Redivis datasets (`eco`, `eco_2`, ...), since
Redivis caps one at 1000 tables. Every reader searches them newest-first, so
nothing changes for a user; `eco_list_tables()` gains a `dataset` column, a
fetched table an `eco_redivis_dataset` attribute, and `eco_version()` one tag per
shard. A pinned version reads each shard at the tag the manifest records, and a
shard with no tag there was not part of it.

`eco_traits()` fetches body mass from AVONET (birds) and COMBINE (mammals) into
the package cache and joins it onto a table's `__taxa` by scientific name
(ben-domingue/eco#35). Nothing from either source is stored in eco; `readxl` is
needed for AVONET's xlsx.

First release (ben-domingue/eco#7). Reads `datapages.eco` and `datapages.eco_meta`
anonymously over Redivis' CSV endpoint; disk cache; version pinning through the
release manifest; converters moved here from `converters/eco_standard.R`, which
now sources this package's `R/convert.R` so the build scripts and the package
share one implementation.
