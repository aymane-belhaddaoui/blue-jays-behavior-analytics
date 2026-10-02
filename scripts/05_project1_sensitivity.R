# Targeted exploratory follow-up to the completed M2 model.
# Run from the project root; uses the uploaded completed run by default.
# No new packages beyond clubSandwich. Does not refit/tune on holdout dates.
run_project1_sensitivity <- function(
  model_path="outputs/project1/models/20261002_111847_28440/project1_models.rds") {
  if (!requireNamespace("clubSandwich",quietly=TRUE)) stop("Install clubSandwich first.")
  if (!file.exists(model_path)) stop("Model RDS not found: ",model_path)
  previous <- readRDS(model_path)
  main <- droplevels(previous$main_data)
  stopifnot(nrow(main)==3889, length(unique(main$game_id))==27,
            !anyDuplicated(main$pitch_id),all(main$split=="Train"),
            all(main$pitcher_disruption==0),all(main$routine_time_secs>0),
            all(complete.cases(main[c("routine_time_secs","risp","pre_balls",
                                     "pre_strikes","inning","batter_id","game_id")])))
  out <- file.path("outputs","project1","sensitivity",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Run directory already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE); on.exit(sink(),add=TRUE)
  withCallingHandlers({
    # Count and inning are categorical. This is a different conditional association,
    # not a causal adjustment or a replacement selected by statistical significance.
    count_fit <- lm(routine_time_secs ~ risp + factor(pre_balls) + factor(pre_strikes) +
                      factor(inning) + batter_id + game_id, data=main,na.action=na.fail)
    # Only the outcome scale changes from M2. Exponentiation gives a conditional
    # geometric-mean ratio, NOT an arithmetic-mean duration ratio.
    log_fit <- lm(log(routine_time_secs) ~ risp + batter_id + game_id,
                  data=main,na.action=na.fail)
    models <- list(S2_count_inning=count_fit,S3_log_duration=log_fit)
    tests <- list(); intervals <- list()
    for(name in names(models)) {
      fit <- models[[name]]
      if(anyNA(coef(fit))) stop("Aliased coefficients in ",name)
      tests[[name]] <- clubSandwich::coef_test(fit,vcov="CR2",cluster=main$game_id,
                                               coefs="risp",test="Satterthwaite")
      intervals[[name]] <- clubSandwich::conf_int(fit,vcov="CR2",cluster=main$game_id,
                                                  coefs="risp",test="Satterthwaite",level=.95)
      cat("\nMODEL:",name,"\n");print(tests[[name]]);print(intervals[[name]])
      write.csv(as.data.frame(tests[[name]]),file.path(out,paste0(name,"_test.csv")),row.names=TRUE)
      write.csv(as.data.frame(intervals[[name]]),file.path(out,paste0(name,"_ci.csv")),row.names=TRUE)
    }
    ci <- as.data.frame(intervals$S3_log_duration)
    stopifnot(all(c("beta","CI_L","CI_U") %in% names(ci)))
    geometric <- data.frame(geometric_mean_ratio=exp(ci$beta),
                            ratio_ci_lower=exp(ci$CI_L),ratio_ci_upper=exp(ci$CI_U),
                            percent_difference=100*expm1(ci$beta),
                            percent_ci_lower=100*expm1(ci$CI_L),
                            percent_ci_upper=100*expm1(ci$CI_U))
    cat("\nLOG MODEL: geometric-mean interpretation\n");print(geometric)
    write.csv(geometric,file.path(out,"S3_geometric_mean_ratio.csv"),row.names=FALSE)
    # Leave-one-game-out is an influence diagnostic, NOT 27 new hypothesis tests
    # and NOT a confidence interval constructed from the minimum and maximum.
    baseline <- unname(coef(previous$models$M2_batter_game)["risp"])
    loo <- do.call(rbind,lapply(levels(main$game_id),function(g) {
      reduced <- droplevels(main[main$game_id!=g,])
      fit <- lm(routine_time_secs ~ risp + batter_id + game_id,
                data=reduced,na.action=na.fail)
      if(anyNA(coef(fit))) stop("Aliased leave-one-game-out model: ",g)
      beta <- unname(coef(fit)["risp"])
      data.frame(omitted_game=g,pitches=nrow(reduced),games=length(unique(reduced$game_id)),
                 risp_coefficient_secs=beta,change_from_M2_secs=beta-baseline)
    }))
    loo <- loo[order(abs(loo$change_from_M2_secs),decreasing=TRUE),]
    cat("\nM2 leave-one-game-out influence, sorted by absolute change\n");print(loo,row.names=FALSE)
    write.csv(loo,file.path(out,"M2_leave_one_game_out.csv"),row.names=FALSE)
    saveRDS(list(models=models,tests=tests,intervals=intervals,geometric=geometric,
                 leave_one_game_out=loo,source_model_path=model_path),file.path(out,"sensitivity.rds"))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    files <- c(model_path,"scripts/05_project1_sensitivity.R")
    hashes <- tools::md5sum(files)
    write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    file.copy("scripts/05_project1_sensitivity.R",file.path(out,"05_project1_sensitivity.R"))
    writeLines("Completed exploratory sensitivity analyses; interpretation pending review.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nSensitivity outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
sensitivity_output <- run_project1_sensitivity()
