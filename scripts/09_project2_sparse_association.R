# Workstream 2: evidence-limited, unadjusted association benchmark.
# Run from repository root: source("scripts/09_project2_sparse_association.R")
# No new packages. No holdout outcomes, multivariable adjustment or causal claims.
# Fisher intervals/tests are INDEPENDENT-PA references: NOT clustered inference.
run_project2_sparse_association <- function() {
  source("scripts/01_import_R.R",local=TRUE)
  d <- subset(tables$project2_pas,split=="Train")
  stopifnot(nrow(d)==1028,!anyDuplicated(d$pa_id),
            all(d$strikeout %in% c(0,1)),all(d$disrupted_first_pitch %in% c(0,1)),
            sum(d$disrupted_first_pitch)==13,
            sum(d$strikeout[d$disrupted_first_pitch==1])==1)
  # Rows: exposed then unexposed. Columns: strikeout then non-strikeout.
  make_table <- function(z) {
    matrix(c(sum(z$disrupted_first_pitch==1 & z$strikeout==1),
             sum(z$disrupted_first_pitch==1 & z$strikeout==0),
             sum(z$disrupted_first_pitch==0 & z$strikeout==1),
             sum(z$disrupted_first_pitch==0 & z$strikeout==0)),
           nrow=2,byrow=TRUE,dimnames=list(exposure=c("First-pitch disruption","No first-pitch disruption"),
                                        outcome=c("Strikeout","No strikeout")))
  }
  tab <- make_table(d)
  stopifnot(identical(as.numeric(tab),c(1,184,12,831)))
  out <- file.path("outputs","project2","association",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Run folder already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    cat("FIRST-PITCH EXPOSURE, TRAINING DATA\n");print(tab)
    write.csv(tab,file.path(out,"first_pitch_2x2.csv"))
    risks <- tab[,1]/rowSums(tab)
    sample_or <- (tab[1,1]*tab[2,2])/(tab[1,2]*tab[2,1])
    descriptive <- data.frame(exposed_n=sum(tab[1,]),unexposed_n=sum(tab[2,]),
                              exposed_strikeouts=tab[1,1],unexposed_strikeouts=tab[2,1],
                              exposed_risk=risks[1],unexposed_risk=risks[2],
                              risk_difference=risks[1]-risks[2],risk_ratio=risks[1]/risks[2],
                              sample_odds_ratio=sample_or)
    print(descriptive);write.csv(descriptive,file.path(out,"descriptive_association.csv"),row.names=FALSE)
    # Learning benchmark: binomial GLM with a logit link.
    # logit(P(strikeout)) = intercept + beta * first_pitch_disruption.
    # exp(beta) is an UNADJUSTED odds ratio, not a probability or risk ratio.
    fit <- glm(strikeout ~ disrupted_first_pitch,data=d,family=binomial(link="logit"),na.action=na.fail)
    stopifnot(fit$converged,all(is.finite(coef(fit))),
              isTRUE(all.equal(unname(exp(coef(fit)["disrupted_first_pitch"])),unname(sample_or),tolerance=1e-6)))
    glm_coefficients <- data.frame(term=names(coef(fit)),log_odds_coefficient=unname(coef(fit)),
                                   exponentiated_coefficient=unname(exp(coef(fit))))
    print(glm_coefficients)
    write.csv(glm_coefficients,file.path(out,"glm_coefficients.csv"),row.names=FALSE)
    fitted_risks <- data.frame(disrupted_first_pitch=0:1)
    fitted_risks$fitted_strikeout_probability <- predict(fit,newdata=fitted_risks,type="response")
    print(fitted_risks);write.csv(fitted_risks,file.path(out,"glm_fitted_probabilities.csv"),row.names=FALSE)
    # Exact small-cell reference under independent observations. This does not
    # remove confounding, within-game or within-batter dependence.
    fisher <- fisher.test(tab,alternative="two.sided",conf.level=.95)
    reference <- data.frame(method="Fisher conditional exact; independent-PA reference only",
                            conditional_odds_ratio=unname(fisher$estimate),
                            ci_lower=fisher$conf.int[1],ci_upper=fisher$conf.int[2],
                            p_two_sided=fisher$p.value)
    cat("\nINDEPENDENT-PA REFERENCE ONLY (not game-clustered)\n");print(reference)
    write.csv(reference,file.path(out,"independence_reference_fisher.csv"),row.names=FALSE)
    # Influence audit with exact cell counts, avoiding numerical fits under separation.
    # All-zero exposed events imply boundary MLE beta=-Inf, not proof of protection.
    omitted <- do.call(rbind,lapply(sort(unique(d$game_id)),function(g) {
      z <- d[d$game_id!=g,];tt <- make_table(z)
      finite <- all(tt>0)
      data.frame(omitted_game=g,pas=nrow(z),exposed_n=sum(tt[1,]),exposed_strikeouts=tt[1,1],
                 unexposed_n=sum(tt[2,]),unexposed_strikeouts=tt[2,1],
                 finite_logistic_exposure_MLE=finite,
                 sample_odds_ratio=if(sum(tt[1,])>0 && tt[1,2]*tt[2,1]>0)
                   tt[1,1]*tt[2,2]/(tt[1,2]*tt[2,1]) else NA_real_)
    }))
    cat("\nOMITTED-GAME CELL SUPPORT (not confidence intervals or 27 hypothesis tests)\n")
    print(omitted);write.csv(omitted,file.path(out,"leave_one_game_out_support.csv"),row.names=FALSE)
    write.csv(d[c("pa_id","game_id","batter_id")],file.path(out,"cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(glm_unadjusted=fit,fisher_independence_reference=fisher,
                 descriptive=descriptive,omitted_game_support=omitted,train_pas=d),
            file.path(out,"project2_sparse_association.rds"))
    notes <- c(
      "This is an evidence-limited exploratory workstream, not an adjusted effect estimate.",
      "Only 13 first-pitch-exposed PAs and one exposed strikeout support the contrast.",
      "The GLM is an unadjusted learning benchmark. No Wald significance result is promoted.",
      "Fisher is an independent-PA reference; exact refers to that reference distribution, not validity under clustered observations.",
      "A confidence interval spanning one does not demonstrate equivalence or no association.",
      "Batter and game composition may confound the comparison. Sparse support is not repaired by penalization alone.",
      "Any-PA disruption stays descriptive because timing/opportunity differ. Total pitch count is not a baseline covariate.",
      "No model selected using validation/test outcomes. GitHub remains private until all four workstreams are finished.")
    writeLines(notes,file.path(out,"INTERPRETATION_LIMITS.txt"))
    files <- c("scripts/09_project2_sparse_association.R","scripts/01_import_R.R",
               list.files("data",pattern="[.]csv$",full.names=TRUE))
    hashes <- tools::md5sum(files);stopifnot(!anyNA(hashes))
    write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/09_project2_sparse_association.R",file.path(out,"09_project2_sparse_association.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines("Completed sparse association benchmark; independence-based reference is not clustered confirmatory inference.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nWorkstream 2 association outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project2_association_output <- run_project2_sparse_association()
