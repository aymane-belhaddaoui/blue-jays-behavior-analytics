# Exploratory development models, specified after reviewing Session 03 EDA.
# Not a preregistered confirmatory analysis. No validation/test rows are used.
# Install once in the R console: install.packages("clubSandwich")
# Run from the project root: source("scripts/04_project1_models.R")
run_project1_models <- function() {
  if (!requireNamespace("clubSandwich", quietly=TRUE)) {
    stop('Install clubSandwich first: install.packages("clubSandwich")')
  }
  source("scripts/01_import_R.R", local=TRUE)
  d <- subset(p1_routine, split=="Train" & pa_sequence_valid==1 &
                !is.na(risp) & !is.na(pitcher_disruption))
  stopifnot(nrow(d)==3942, !anyDuplicated(d$pitch_id),
            all(d$routine_time_secs>0), all(d$routine_source=="Observed"),
            all(d$split=="Train"), all(d$risp %in% c(0,1)),
            all(d$pitcher_disruption %in% c(0,1)))
  d$batter_id <- factor(d$batter_id); d$game_id <- factor(d$game_id)
  main <- droplevels(subset(d,pitcher_disruption==0))
  stopifnot(nrow(main)==3889, sum(main$risp==0)==2852, sum(main$risp==1)==1037)
  out <- file.path("outputs","project1","models",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if (dir.exists(out)) stop("Run folder already exists; wait one second before rerunning.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE)
  on.exit(sink(),add=TRUE)
  capture_warning <- function(w) {
    cat(format(Sys.time()), conditionMessage(w), "\n",file=file.path(out,"warnings.txt"),append=TRUE)
  }
  withCallingHandlers({
    models <- list(
      M0_pooled=lm(routine_time_secs ~ risp,data=main,na.action=na.fail),
      M1_batter=lm(routine_time_secs ~ risp + batter_id,data=main,na.action=na.fail),
      M2_batter_game=lm(routine_time_secs ~ risp + batter_id + game_id,
                        data=main,na.action=na.fail),
      S1_all_adjusted=lm(routine_time_secs ~ risp + pitcher_disruption + batter_id + game_id,
                          data=d,na.action=na.fail)
    )
    tests <- list(); intervals <- list(); sizes <- list()
    for (name in names(models)) {
      fit <- models[[name]]
      dat <- if(name=="S1_all_adjusted") d else main
      if (anyNA(coef(fit))) stop("Aliased coefficient in ",name,". Inspect the model before inference.")
      tests[[name]] <- clubSandwich::coef_test(fit,vcov="CR2",cluster=dat$game_id,
                                               test="Satterthwaite",coefs="risp")
      intervals[[name]] <- clubSandwich::conf_int(fit,vcov="CR2",cluster=dat$game_id,
                                                  test="Satterthwaite",coefs="risp",level=.95)
      cat("\nMODEL:",name,"\n");print(formula(fit))
      print(tests[[name]]);print(intervals[[name]])
      write.csv(as.data.frame(tests[[name]]),file.path(out,paste0(name,"_test.csv")),row.names=TRUE)
      write.csv(as.data.frame(intervals[[name]]),file.path(out,paste0(name,"_ci.csv")),row.names=TRUE)
      sizes[[name]] <- data.frame(model=name,pitches=nrow(dat),pas=length(unique(dat$pa_id)),
                                 games=length(unique(dat$game_id)),batters=length(unique(dat$batter_id)),
                                 risp_coefficient_secs=unname(coef(fit)["risp"]))
    }
    model_sizes <- do.call(rbind,sizes);print(model_sizes)
    write.csv(model_sizes,file.path(out,"model_sizes.csv"),row.names=FALSE)
    write.csv(data.frame(pitch_id=main$pitch_id),file.path(out,"primary_cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(models=models,tests=tests,intervals=intervals,main_data=main,all_data=d),
            file.path(out,"project1_models.rds"))
    # Graphical diagnostics are not IID normality tests; CR2 supplies inference.
    local({
      pdf(file.path(out,"M2_diagnostics.pdf"),width=10,height=5)
      on.exit(dev.off())
      par(mfrow=c(1,2))
      plot(fitted(models$M2_batter_game),residuals(models$M2_batter_game),
           xlab="Fitted duration (seconds)",ylab="Residual (seconds)",
           main="Residuals versus fitted",pch=16,cex=.35)
      abline(h=0,col="red")
      qqnorm(residuals(models$M2_batter_game),pch=16,cex=.35,main="Residual Q-Q plot")
      qqline(residuals(models$M2_batter_game),col="red")
    })
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    files <- c(list.files("data",pattern="[.]csv$",full.names=TRUE),
               "scripts/01_import_R.R","scripts/04_project1_models.R")
    hashes <- tools::md5sum(files)
    write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    file.copy("scripts/04_project1_models.R",file.path(out,"04_project1_models.R"),overwrite=FALSE)
    writeLines("Complete exploratory model run. Review warnings, effective degrees of freedom and diagnostics.",
               file.path(out,"RUN_COMPLETE.txt"))
    cat("\nOutputs saved in:",out,"\n")
  },warning=capture_warning)
  invisible(out)
}
model_output <- run_project1_models()
