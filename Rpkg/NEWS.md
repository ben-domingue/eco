# eco 0.1.0

`eco_traits()` fetches body mass from AVONET (birds) and COMBINE (mammals) into
the package cache and joins it onto a table's `__taxa` by scientific name
(ben-domingue/eco#35). Nothing from either source is stored in eco; `readxl` is
needed for AVONET's xlsx.

First release (ben-domingue/eco#7). Reads `datapages.eco` and `datapages.eco_meta`
anonymously over Redivis' CSV endpoint; disk cache; version pinning through the
release manifest; converters moved here from `converters/eco_standard.R`, which
now sources this package's `R/convert.R` so the build scripts and the package
share one implementation.
