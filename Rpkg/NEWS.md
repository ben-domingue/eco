# eco 0.1.0

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
