# 1. Single-season occupancy: Swiss willow tit (unmarked's widewt.csv; 237 sites x 3 visits)
source("rt_common.R")
DS <- "willowtit_occu"
w <- read.csv(system.file("csv", "widewt.csv", package = "unmarked"))
y <- as.matrix(w[, c("y.1", "y.2", "y.3")])
umf <- unmarkedFrameOccu(y = y, siteCovs = w[, c("elev", "forest", "length")],
                         obsCovs = list(date = as.matrix(w[, c("date.1", "date.2", "date.3")]),
                                        ivel = as.matrix(w[, c("ivel.1", "ivel.2", "ivel.3")])))
# --- native -> standard
long <- umf_to_eco(umf, taxon = "POEMON", site_ids = w$site)
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
record(DS, "rows == non-NA cells", nrow(long) == sum(!is.na(y)), sprintf("%d rows, %d NA cells", nrow(long), sum(is.na(y))))
taxa <- data.frame(taxon = "POEMON", scientificName = "Poecile montanus", vernacularName = "Willow Tit", taxonRank = "species",
                    taxonID = "https://www.gbif.org/species/2487885")
write_eco(long, "kery_2008_willowtit_occ", OUT, taxa = taxa,
          dataset = list(title = "Swiss willow tit detection/non-detection, MHB 2004-ish (unmarked widewt.csv)",
                         responseType = "detection", unitKind = "site", closure = "occasion",
                         samplingProtocolCode = "line_transect", intellectualRights = "GPL-3 (bundled with unmarked)",
                         sourceURL = "https://cran.r-project.org/package=unmarked"))
# --- standard -> native
back <- read_eco(file.path(OUT, "kery_2008_willowtit_occ.csv"))
umf2 <- eco_to_umf(back, "occu", site_ids = w$site)
record(DS, "y identical", same_matrix(getY(umf), getY(umf2)))
record(DS, "siteCovs identical", same_df(siteCovs(umf), siteCovs(umf2)))
co <- compare_obs(obsCovs(umf), obsCovs(umf2), getY(umf))
record(DS, "obsCovs identical at surveyed cells", co$ok)
record(DS, "obsCovs values at unsurveyed cells (lost)", TRUE, sprintf("%d values not representable", co$n_lost))
# --- fit textbook model (unmarked vignette): psi ~ elev + forest + length, p ~ date + ivel
f1 <- occu(~ date + ivel ~ elev + forest + length, umf)
f2 <- occu(~ date + ivel ~ elev + forest + length, umf2)
record(DS, "occu estimates identical", same_estimates(coef(f1), coef(f2)), sprintf("psi(elev)=%.4f", coef(f1)[2]))
# --- also via NIMBLE (nimbleEcology::dOcc_v) to show the NIMBLE path
suppressPackageStartupMessages({ library(nimble); library(nimbleEcology) })
fit_nimble_occ <- function(umf, seed = 1) {
  y <- getY(umf); sc <- siteCovs(umf)
  code <- nimbleCode({
    for (i in 1:M) {
      logit(psi[i]) <- b0 + b1 * elev[i] + b2 * forest[i]
      y[i, 1:J] ~ dOcc_s(probOcc = psi[i], probDetect = p, len = J)
    }
    b0 ~ dnorm(0, sd = 2); b1 ~ dnorm(0, sd = 2); b2 ~ dnorm(0, sd = 2); p ~ dunif(0, 1)
  })
  yy <- y; yy[is.na(yy)] <- 0   # widewt has no NA; guard anyway
  m <- nimbleModel(code, constants = list(M = nrow(y), J = ncol(y), elev = sc$elev, forest = sc$forest),
                   data = list(y = yy), inits = list(b0 = 0, b1 = 0, b2 = 0, p = 0.5))
  cm <- compileNimble(m); mc <- buildMCMC(m, monitors = c("b0", "b1", "b2", "p"))
  cmc <- compileNimble(mc, project = m)
  set.seed(seed); s <- runMCMC(cmc, niter = 2000, nburnin = 500, progressBar = FALSE)
  colMeans(s)
}
n1 <- fit_nimble_occ(umf); n2 <- fit_nimble_occ(umf2)
record(DS, "nimble dOcc posterior means identical", isTRUE(all.equal(n1, n2)), sprintf("p=%.3f", n1["p"]))
write_results(DS)
