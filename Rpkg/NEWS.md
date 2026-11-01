# eco 0.1.0

First release (ben-domingue/eco#7). Reads `datapages.eco` and `datapages.eco_meta`
anonymously over Redivis' CSV endpoint; disk cache; version pinning through the
release manifest; converters moved here from `converters/eco_standard.R`, which
now sources this package's `R/convert.R` so the build scripts and the package
share one implementation.
