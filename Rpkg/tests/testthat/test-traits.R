# eco_traits(): the name matching runs offline on a made-up trait table; the
# figshare downloads are tried only with a network.

skip_if_offline <- function() {
  if (!requireNamespace("curl", quietly = TRUE) || !curl::has_internet()) skip("no network")
  if (nzchar(Sys.getenv("ECO_SKIP_REMOTE"))) skip("ECO_SKIP_REMOTE set")
}

test_that("trait matching tries exact, accepted and binomial names and skips higher ranks", {
  traits <- data.frame(
    scientific_name = c("Poecile montanus", "Pekania pennanti", "Panthera tigris"),
    body_mass_g = c(11, 4000, 150000), source = c("AVONET", "COMBINE", "COMBINE"),
    stringsAsFactors = FALSE)
  taxa <- data.frame(
    taxon = c("PM", "PP", "PT", "GEN", "XX", "NA1"),
    scientificName = c("Poecile montanus", "Martes pennanti", "Panthera tigris altaica", "Genetta", "Nobody atall", "Poecile montanus"),
    gbifAcceptedName = c(NA, "Pekania pennanti", NA, NA, NA, NA),
    taxonRank = c("species", "species", "subspecies", "genus", "species", NA),
    stringsAsFactors = FALSE)
  m <- eco:::.eco_match_traits(taxa, traits)
  expect_equal(m$trait_match, c("exact", "accepted_name", "binomial", "none", "none", "exact"))
  expect_equal(m$body_mass_g, c(11, 4000, 150000, NA, NA, 11))
  expect_equal(m$trait_name[3], "Panthera tigris")
  expect_equal(nrow(m), nrow(taxa))
  expect_error(eco:::.eco_match_traits(data.frame(taxon = "a"), traits), "scientificName")
})

test_that("a genus whose name happens to be in the source is still not matched", {
  traits <- data.frame(scientific_name = "Genetta", body_mass_g = 1, source = "x", stringsAsFactors = FALSE)
  taxa <- data.frame(taxon = "G", scientificName = "Genetta", taxonRank = "genus", stringsAsFactors = FALSE)
  expect_equal(eco:::.eco_match_traits(taxa, traits)$trait_match, "none")
})

test_that("COMBINE downloads, caches and joins onto a mammal table", {
  skip_if_offline()
  tr <- eco_traits(group = "mammals")
  expect_true(all(c("scientific_name", "body_mass_g", "source", "source_version") %in% names(tr)))
  expect_true(nrow(tr) > 5000)
  expect_equal(unique(tr$source), "COMBINE")
  expect_match(attr(tr, "citations")[["COMBINE"]], "Soria")
  expect_true(file.exists(file.path(eco_cache_dir(), "traits", "combine_v4", "trait_data_reported.csv")))
  j <- eco_traits("schank_2015_tapir_occ", group = "mammals")
  expect_equal(j$trait_match, "exact")
  expect_true(j$body_mass_g > 100000)
})
