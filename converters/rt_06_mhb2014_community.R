# 6. Community occupancy: MHB2014 (AHMbook; 267 sites x 3 visits x 158 species, with NA surveys and an all-NA site)
source("rt_common.R")
suppressPackageStartupMessages({ library(AHMbook); library(nimble) })
DS <- "mhb2014_community"
data(MHB2014)
y <- MHB2014$counts; y[y > 1] <- 1               # detection/non-detection, as in AHM 11.3
raw <- MHB2014$counts
dimnames(y)[[3]] <- MHB2014$species$latabb
sites <- MHB2014$sites; rownames(sites) <- NULL
site_covs <- sites[, c("coordx", "coordy", "elev", "rlength", "forest")]   # nsurvey/obs14 are design/observer; keep obs14 as rater
obs_covs <- list(date = MHB2014$date, dur = MHB2014$dur)
item_covs <- MHB2014$species[, c("body.length", "body.mass", "wing.span")]
long <- array_to_eco(y, site_ids = sites$siteID, site_covs = site_covs, obs_covs = obs_covs, item_covs = item_covs,
                     resp_raw = raw)
long[, rater := sites$obs14[match(id, sites$siteID)]]
long <- order_eco(long)
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
n_surveys <- sum(!is.na(y[, , 1]))
record(DS, "rows == surveys x species", nrow(long) == n_surveys * dim(y)[3], sprintf("%d rows = %d surveys x %d species", nrow(long), n_surveys, dim(y)[3]))
record(DS, "all-NA site has no rows", !(sites$siteID[which(rowSums(!is.na(y[, , 1])) == 0)] %in% long$id))
record(DS, "resp_raw keeps counts", max(long$resp_raw, na.rm = TRUE) > 1)
items <- data.frame(item = MHB2014$species$latabb, scientificName = MHB2014$species$latname, vernacularName = MHB2014$species$engname,
                    taxonRank = "species", specid = MHB2014$species$specid)
write_eco(long, "kery_2014_mhb_community", OUT, items = items,
          dataset = list(title = "Swiss MHB 2014 community detection data (AHMbook::MHB2014)", responseType = "detection",
                         unitKind = "site", itemKind = "taxon", closure = "occasion", crs = "EPSG:21781 (CH1903/LV03) in cov_coordx/cov_coordy",
                         intellectualRights = "GPL-3 (bundled with AHMbook)"))
back <- read_eco(file.path(OUT, "kery_2014_mhb_community.csv"))
record(DS, "file size (MB)", TRUE, sprintf("%.1f", file.size(file.path(OUT, "kery_2014_mhb_community.csv")) / 1e6))
a <- eco_to_array(back, site_ids = sites$siteID, items = MHB2014$species$latabb)
# the all-NA site drops out of the table; eco_to_array pads it back because site_ids is supplied
y2 <- a$y
record(DS, "y array identical (incl. NA pattern)", identical(dim(y2), dim(y)) && identical(unname(is.na(y2)), unname(is.na(y))) && isTRUE(all.equal(unname(y2), unname(y))))
sc2 <- a$site_covs
record(DS, "siteCovs identical for surveyed sites", same_df(site_covs[rowSums(!is.na(y[, , 1])) > 0, ], sc2[rowSums(!is.na(y2[, , 1])) > 0, ]))
record(DS, "siteCovs lost for the never-surveyed site", all(is.na(sc2[rowSums(!is.na(y2[, , 1])) == 0, ])), "expected: core table cannot carry a unit with no surveys")
record(DS, "obsCovs identical at surveyed cells", same_matrix(obs_covs$date, a$obs_covs$date) && same_matrix(obs_covs$dur, a$obs_covs$dur))
record(DS, "itemCovs identical", same_df(item_covs, a$item_covs))
# textbook model: AHM 11.6.1 simplest community occupancy model (species random effects, no augmentation)
fit_comm <- function(y, seed = 1, niter = 600) {
  nsite <- dim(y)[1]; nrep <- dim(y)[2]; nspec <- dim(y)[3]
  code <- nimbleCode({
    for (k in 1:nspec) {
      lpsi[k] ~ dnorm(mu.lpsi, sd = sd.lpsi); lp[k] ~ dnorm(mu.lp, sd = sd.lp)
      logit(psi[k]) <- lpsi[k]; logit(p[k]) <- lp[k]
      for (i in 1:nsite) {
        z[i, k] ~ dbern(psi[k])
        for (j in 1:nrep) { y[i, j, k] ~ dbern(z[i, k] * p[k]) }
      }
    }
    mu.lpsi ~ dnorm(0, sd = 2); mu.lp ~ dnorm(0, sd = 2); sd.lpsi ~ dunif(0, 5); sd.lp ~ dunif(0, 5)
  })
  zst <- apply(y, c(1, 3), max, na.rm = TRUE); zst[zst == -Inf] <- 1
  m <- nimbleModel(code, constants = list(nsite = nsite, nrep = nrep, nspec = nspec), data = list(y = y),
                   inits = list(z = zst, mu.lpsi = 0, mu.lp = 0, sd.lpsi = 1, sd.lp = 1, lpsi = rep(0, nspec), lp = rep(0, nspec)))
  cm <- compileNimble(m); mc <- buildMCMC(m, monitors = c("mu.lpsi", "mu.lp", "sd.lpsi", "sd.lp"))
  cmc <- compileNimble(mc, project = m)
  set.seed(seed); s <- runMCMC(cmc, niter = niter, nburnin = 200, progressBar = FALSE)
  colMeans(s)
}
# The MCMC fit is slow (two runs of ~10 min) and only confirms what the array identity already implies;
# run it with ECO_FIT_COMMUNITY=1.
if (nzchar(Sys.getenv("ECO_FIT_COMMUNITY"))) {
  e1 <- fit_comm(y); e2 <- fit_comm(y2)
  record(DS, "nimble community model posterior means identical", isTRUE(all.equal(e1, e2)), sprintf("mu.lpsi=%.3f mu.lp=%.3f", e1["mu.lpsi"], e1["mu.lp"]))
} else record(DS, "nimble community model fit", TRUE, "skipped (set ECO_FIT_COMMUNITY=1); arrays identical so fits would be")
write_results(DS)
