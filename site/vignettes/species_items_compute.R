# Companion compute script for site/vignettes/species_items.qmd.
#
# Fits, to every table the rule in select_tables() picks, the models the
# vignette compares:
#   naive_rasch   lme4::glmer(ever ~ 1 + (1 | site) + (1 | species)): the
#                 site x species "ever detected" matrix as a random-item model,
#                 ignoring imperfect detection (also refit live in the .qmd for
#                 the first table, where the code is shown)
#   naive_2pl     mirt 2PL on the same matrix (one site score, a slope per
#                 species); used to choose the anchor species for lf_occ and to
#                 compare slopes
#   nopool        unmarked::occu(~1 ~1) per species: occupancy and detection
#                 separated, no pooling across species
#   ms_occ        spOccupancy::msPGOcc(~1, ~1): species intercepts on logit psi
#                 and logit p drawn from community normals (Dorazio-Royle)
#   lf_occ        spOccupancy::lfMsPGOcc(~1, ~1, n.factors = 1): ms_occ plus one
#                 site latent variable w_i with a loading per species on logit
#                 psi, the full species-as-items model on the latent state
# and writes species_items_data/species_items.rds (summaries only, well under
# 5 MB), which the vignette reads instead of refitting.
#
# MCMC: 3 chains x 6000 iterations, 2000 burn-in, thinning 4 (3000 draws kept),
# default spOccupancy priors. Convergence (Rhat, ESS) is saved and printed by
# the vignette.
#
# The anchor (lf_occ): spOccupancy fixes the first species' loading at 1, which
# sets the sign and scale of w. A species present nearly everywhere carries no
# information about w and the chains then disagree about its sign (that happened
# with the most-detected species, Swainson's thrush, on the boreal table). The
# rule: among species detected at 10-90% of sites, the one with the largest
# absolute naive_2pl slope goes first.
#
# Run from site/vignettes/:   nice -n 15 Rscript species_items_compute.R
# Takes about 11 minutes: 2 minutes per spOccupancy fit on the boreal table; the
# Monongahela fits fail the Rhat check at the default length and are rerun long.

suppressPackageStartupMessages({
  library(eco); library(data.table); library(lme4); library(mirt)
  library(unmarked); library(spOccupancy)
})
ECO_VERSION <- 12
eco_set_version(ECO_VERSION)
set.seed(2026)
MCMC <- list(n.samples = 6000, n.burn = 2000, n.thin = 4, n.chains = 3)
# If any species or community parameter has Rhat > 1.1, the fit is rerun once
# with chains five times as long (30000 iterations, 10000 burn-in, thinning 20,
# still 3000 draws kept), and the vignette reports which fits needed it.
MCMC_LONG <- list(n.samples = 30000, n.burn = 10000, n.thin = 20, n.chains = 3)
max_rhat <- function(m) max(unlist(m$rhat[c("beta.comm", "tau.sq.beta", "alpha.comm", "tau.sq.alpha",
                                          "beta", "alpha", "lambda.lower.tri")]), na.rm = TRUE)
run_mcmc <- function(fun, args) {
  m <- do.call(fun, c(args, MCMC)); long <- FALSE
  if (max_rhat(m) > 1.1) { m <- do.call(fun, c(args, MCMC_LONG)); long <- TRUE }
  attr(m, "long") <- long
  m
}

# The rule. Site-unit community detection tables (unit_kind site, response
# detection, more than one taxon), closed within a single season (closure
# "closed", one period), replicate occasions in time (occasion_kind "time": not
# spatial subsamples, observers or methods), at least 30 sites, 10 to 40 taxa,
# fetchable anonymously, and a survey set that is not "inferred". `_exact`
# siblings repeat a coarsened table and are dropped.
select_tables <- function() {
  f <- as.data.table(eco_filter(unit_kind = "site", response_type = "detection",
                                multi_species = TRUE, min_units = 30, min_occasions = 2))
  sz <- as.data.table(eco_list_tables())[, .(table, needs_login, survey_taxa)]
  f <- merge(f, sz, by = "table", all.x = TRUE)
  f[, why := fifelse(closure != "closed", paste("closure", closure),
             fifelse(n_periods != 1, sprintf("%d periods", n_periods),
             fifelse(occasion_kind != "time", paste("occasions index", occasion_kind),
             fifelse(n_taxa < 10 | n_taxa > 40, sprintf("%d taxa", n_taxa),
             fifelse(needs_login %in% TRUE, "needs a Redivis login",
             fifelse(survey_evidence == "inferred", "survey set inferred",
             fifelse(grepl("_exact", table), "_exact sibling", "")))))))]
  f[, .(table, n_units, n_taxa, n_periods, n_occasions, closure, occasion_kind,
        survey_evidence, needs_login, survey_taxa, picked = why == "", why)]
}

summ <- function(x) c(med = median(x), lo = unname(quantile(x, 0.025)), hi = unname(quantile(x, 0.975)))

fit_table <- function(tb, has_survey_taxa) {
  timing <- list()
  d <- as.data.table(eco_fetch(tb))
  tx <- as.data.table(eco_taxa(tb))
  a <- eco_to_array(d)                                  # site x visit x species, NA = not surveyed
  y <- aperm(a$y, c(3, 1, 2))                           # species x site x visit, as spOccupancy wants
  # A community table without __survey_taxa has every taxon at every survey, so
  # the NA pattern is the same for every species. With __survey_taxa a species
  # can be NA where others were surveyed; spOccupancy would need those cells
  # handled per species, which this script does not do.
  na1 <- is.na(y[1, , ])
  stopifnot(!has_survey_taxa, all(apply(y, 1, function(m) identical(is.na(m), na1))))
  J <- rowSums(!na1)                                    # visits per site
  stopifnot(all(J >= 1))
  ever <- apply(y, c(1, 2), function(v) as.integer(max(v, na.rm = TRUE)))  # species x site
  sp <- dimnames(y)[[1]]; sites <- dimnames(y)[[2]]

  # naive random-item model
  long <- data.table(species = rep(sp, length(sites)), site = rep(sites, each = length(sp)),
                     ever = as.vector(ever))
  t0 <- Sys.time()
  g <- glmer(ever ~ 1 + (1 | site) + (1 | species), family = binomial, data = long)
  timing$naive_rasch <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  re_sp <- lme4::ranef(g)$species; re_si <- lme4::ranef(g)$site
  vc <- as.data.frame(VarCorr(g))

  # naive 2PL
  t0 <- Sys.time()
  m2 <- mirt(as.data.frame(t(ever)), 1, itemtype = "2PL", verbose = FALSE)
  timing$naive_2pl <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cf <- coef(m2, simplify = TRUE, IRTpars = FALSE)$items
  th2 <- fscores(m2)[, 1]

  # no pooling
  t0 <- Sys.time()
  np <- rbindlist(lapply(sp, function(k) {
    umf <- suppressMessages(eco_to_unmarked(d[taxon == k], family = "occu"))
    m <- tryCatch(suppressWarnings(occu(~1 ~1, umf)), error = function(e) NULL)
    if (is.null(m)) return(data.table(taxon = k, np_beta = NA_real_, np_beta_se = NA_real_,
                                      np_alpha = NA_real_, np_alpha_se = NA_real_))
    # a species seen once has a singular Hessian: estimate at the boundary, no SE
    s <- tryCatch(suppressWarnings(sqrt(diag(vcov(m)))), error = function(e) c(NA_real_, NA_real_))
    data.table(taxon = k, np_beta = coef(m)[1], np_beta_se = s[1], np_alpha = coef(m)[2], np_alpha_se = s[2])
  }))
  timing$nopool <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  # community occupancy, species random effects
  t0 <- Sys.time()
  ms <- run_mcmc(msPGOcc, list(occ.formula = ~1, det.formula = ~1, data = list(y = y), verbose = FALSE))
  timing$ms_occ <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  B <- ms$beta.samples; A <- ms$alpha.samples            # draws x species
  # implied probability of ever detecting species k at a site, averaged over the
  # sites' own visit counts: psi_k (1 - (1 - p_k)^J_i)
  pev <- sapply(seq_along(sp), function(k) {
    ps <- plogis(B[, k]); pp <- plogis(A[, k])
    rowMeans(outer(ps, rep(1, length(J))) * (1 - outer(1 - pp, J, `^`)))
  })
  rich <- apply(ms$z.samples, c(1, 3), sum)              # draws x site: species present
  species <- data.table(taxon = sp, n_sites_detected = rowSums(ever), n_detections = apply(y, 1, sum, na.rm = TRUE),
                        naive_share = rowMeans(ever),
                        rasch_b = lme4::fixef(g)[[1]] + re_sp[sp, 1],
                        twopl_a = cf[sp, "a1"], twopl_d = cf[sp, "d"])
  species <- merge(species, np, by = "taxon", sort = FALSE)
  for (nm in c("beta", "alpha")) {
    S <- if (nm == "beta") B else A
    s <- t(apply(S, 2, summ)); species[, paste0("ms_", nm, c("", "_lo", "_hi")) := as.data.table(s)]
  }
  s <- t(apply(pev, 2, summ)); species[, c("ms_pever", "ms_pever_lo", "ms_pever_hi") := as.data.table(s)]
  species[, `:=`(ms_beta_rhat = ms$rhat$beta, ms_alpha_rhat = ms$rhat$alpha,
                 ms_beta_ess = ms$ESS$beta, ms_alpha_ess = ms$ESS$alpha)]
  comm_ms <- data.table(param = c("mu_psi", "tau2_psi", "mu_p", "tau2_p"),
                        rbind(summ(ms$beta.comm.samples[, 1]), summ(ms$tau.sq.beta.samples[, 1]),
                              summ(ms$alpha.comm.samples[, 1]), summ(ms$tau.sq.alpha.samples[, 1])),
                        rhat = c(ms$rhat$beta.comm, ms$rhat$tau.sq.beta, ms$rhat$alpha.comm, ms$rhat$tau.sq.alpha))

  # community occupancy with one site factor; anchor species first
  ok <- species$naive_share > 0.1 & species$naive_share < 0.9
  anchor <- species[ok][which.max(abs(twopl_a)), taxon]
  o <- c(anchor, setdiff(sp, anchor))
  t0 <- Sys.time()
  lf <- run_mcmc(lfMsPGOcc, list(occ.formula = ~1, det.formula = ~1, n.factors = 1, verbose = FALSE,
                                 data = list(y = y[o, , ], coords = matrix(0, length(sites), 2))))
  timing$lf_occ <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  L <- lf$lambda.samples; colnames(L) <- o
  s <- t(apply(L, 2, summ))
  lfs <- data.table(taxon = o, lf_lambda = s[, 1], lf_lambda_lo = s[, 2], lf_lambda_hi = s[, 3],
                    lf_lambda_rhat = c(NA, lf$rhat$lambda.lower.tri), lf_lambda_ess = lf$ESS$lambda,
                    lf_beta = apply(lf$beta.samples, 2, median), lf_alpha = apply(lf$alpha.samples, 2, median),
                    lf_beta_rhat = lf$rhat$beta)
  species <- merge(species, lfs, by = "taxon", sort = FALSE)
  species <- merge(species, tx[, .(taxon, scientificName, vernacularName)], by = "taxon", all.x = TRUE, sort = FALSE)

  W <- lf$w.samples[, 1, ]                               # draws x site
  sitecov <- unique(d[, c("unit", intersect("cluster_id", names(d)), grep("^unit_", names(d), value = TRUE)), with = FALSE])
  site <- data.table(unit = sites, visits = J, n_species_detected = colSums(ever),
                     rasch_theta = re_si[sites, 1], twopl_theta = th2,
                     ms_rich = colMeans(rich), ms_rich_lo = apply(rich, 2, quantile, 0.025),
                     ms_rich_hi = apply(rich, 2, quantile, 0.975),
                     lf_w = colMeans(W), lf_w_sd = apply(W, 2, sd))
  site <- merge(site, sitecov, by = "unit", sort = FALSE)

  conv <- data.table(model = c("msPGOcc", "lfMsPGOcc"), long_chains = c(attr(ms, "long"), attr(lf, "long")),
                     max_rhat = c(max_rhat(ms), max_rhat(lf)),
                     min_ess = c(min(unlist(ms$ESS[c("beta", "alpha")])),
                                 min(c(lf$ESS$beta, lf$ESS$alpha, lf$ESS$lambda[-1]))),   # anchor loading is fixed
                     minutes = c(timing$ms_occ, timing$lf_occ) / 60)
  cat(sprintf("%-42s %d sites x %d species: rasch %.0fs, 2pl %.0fs, nopool %.0fs; anchor %s\n",
              tb, length(sites), length(sp), timing$naive_rasch, timing$naive_2pl, timing$nopool, anchor))
  print(conv)
  list(table = tb, species = species, site = site, comm_ms = comm_ms, conv = conv,
       rasch_var = setNames(vc$vcov, vc$grp), anchor = anchor, timing = timing,
       n_sites = length(sites), n_species = length(sp), max_visits = dim(y)[3])
}

cand <- select_tables()
print(cand[, .(table, n_units, n_taxa, picked, why)])
picked <- cand[picked == TRUE]
fits <- lapply(seq_len(nrow(picked)), function(i) fit_table(picked$table[i], isTRUE(picked$survey_taxa[i])))
names(fits) <- picked$table

dir.create("species_items_data", showWarnings = FALSE)
saveRDS(list(fits = fits, candidates = cand, mcmc = MCMC, date_run = Sys.Date(),
             eco_version = suppressMessages(eco_version()),
             versions = c(spOccupancy = as.character(packageVersion("spOccupancy")),
                          lme4 = as.character(packageVersion("lme4")),
                          mirt = as.character(packageVersion("mirt")),
                          unmarked = as.character(packageVersion("unmarked")))),
        "species_items_data/species_items.rds")
cat("wrote species_items_data/species_items.rds:", length(fits), "tables\n")
