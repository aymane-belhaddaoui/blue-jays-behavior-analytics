# Exploratory Workstream 1: adjusted arithmetic-mean tic-count differences.
# Run from project root: source("scripts/06_project1_tics.R")
# Primary: undisrupted Train pitches, observed tic components, valid PA.
# Duration eligibility is deliberately NOT required: P00161 has observed tics.
# Linear models estimate additive count differences; not individual count predictions.
# Game CR2 permits within-game dependence; cross-game residual independence remains
# an assumption. No Poisson fit here: B016 has all-zero counts (boundary issue).
# No duration offset: the outcome is counts per pitch, not counts per second.
run_project1_tics <- function() {
  if (!requireNamespace("clubSandwich", quietly=TRUE)) stop("Install clubSandwich first.")
  source("scripts/01_import_R.R", local=TRUE)
  d <- subset(p1_tics, split=="Train" & pa_sequence_valid==1 &
                !is.na(risp) & !is.na(pitcher_disruption))
  stopifnot(nrow(d)==3943, !anyDuplicated(d$pitch_id),
            all(complete.cases(d[c("total_tics","batter_id","game_id",
                                  "pre_balls","pre_strikes","inning")])),
            all(d$total_tics>=0), all(d$total_tics==floor(d$total_tics)),
            all(d$tics_model_eligible==1), all(d$risp %in% c(0,1)),
            all(d$pitcher_disruption %in% c(0,1)))
  d$batter_id <- factor(d$batter_id); d$game_id <- factor(d$game_id)
  main <- droplevels(subset(d,pitcher_disruption==0))
  stopifnot(nrow(main)==3890, sum(main$risp==0)==2853,
            sum(main$risp==1)==1037, nlevels(main$game_id)==27)
  out <- file.path("outputs","project1","tics",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if (dir.exists(out)) stop("Run folder already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE); on.exit(sink(),add=TRUE)
  withCallingHandlers({
    flow <- data.frame(stage=c("Observed tics, all dates","Observed tics, Train",
                                "Valid PA and complete context, Train","Primary: undisrupted"),
                       pitches=c(nrow(p1_tics),sum(p1_tics$split=="Train"),nrow(d),nrow(main)))
    print(flow); write.csv(flow,file.path(out,"cohort_flow.csv"),row.names=FALSE)
    frequency <- as.data.frame(table(total_tics=main$total_tics,risp=main$risp))
    write.csv(frequency,file.path(out,"tic_frequency.csv"),row.names=FALSE)
    summary_by_context <- do.call(rbind,lapply(0:1,function(r) {
      x <- main$total_tics[main$risp==r]
      data.frame(risp=r,n=length(x),mean=mean(x),variance=var(x),
                 zero_fraction=mean(x==0),median=median(x),maximum=max(x))
    }))
    print(summary_by_context)
    write.csv(summary_by_context,file.path(out,"context_summary.csv"),row.names=FALSE)
    support <- do.call(rbind,lapply(split(main,main$batter_id),function(z) {
      x0 <- z$total_tics[z$risp==0]; x1 <- z$total_tics[z$risp==1]
      data.frame(batter_id=as.character(z$batter_id[1]),n_no_risp=length(x0),
                 n_risp=length(x1),mean_no_risp=mean(x0),mean_risp=mean(x1),
                 difference_tics=mean(x1)-mean(x0),all_zero=all(z$total_tics==0),
                 constant_count=length(unique(z$total_tics))==1)
    }))
    stopifnot(all(support$n_no_risp>0),all(support$n_risp>0))
    print(support);write.csv(support,file.path(out,"batter_support.csv"),row.names=FALSE)
    models <- list(
      T1_primary=lm(total_tics ~ risp + batter_id + game_id,data=main,na.action=na.fail),
      T2_count_inning=lm(total_tics ~ risp + factor(pre_balls) + factor(pre_strikes) +
                          factor(inning) + batter_id + game_id,data=main,na.action=na.fail),
      T3_disruption_adjusted=lm(total_tics ~ risp + pitcher_disruption + batter_id +
                                 game_id,data=d,na.action=na.fail))
    tests <- list(); intervals <- list(); sizes <- list()
    for (name in names(models)) {
      fit <- models[[name]]; dat <- if(name=="T3_disruption_adjusted") d else main
      if(anyNA(coef(fit))) stop("Aliased coefficients in ",name)
      tests[[name]] <- clubSandwich::coef_test(fit,vcov="CR2",cluster=dat$game_id,
                                               coefs="risp",test="Satterthwaite")
      intervals[[name]] <- clubSandwich::conf_int(fit,vcov="CR2",cluster=dat$game_id,
                                                  coefs="risp",test="Satterthwaite",level=.95)
      cat("\nMODEL:",name,"\n");print(tests[[name]]);print(intervals[[name]])
      write.csv(as.data.frame(tests[[name]]),file.path(out,paste0(name,"_test.csv")))
      write.csv(as.data.frame(intervals[[name]]),file.path(out,paste0(name,"_ci.csv")))
      sizes[[name]] <- data.frame(model=name,pitches=nrow(dat),pas=length(unique(dat$pa_id)),
                                 games=nlevels(dat$game_id),batters=nlevels(dat$batter_id),
                                 fitted_min=min(fitted(fit)),fitted_max=max(fitted(fit)),
                                 fitted_negative=sum(fitted(fit)<0))
    }
    sizes <- do.call(rbind,sizes);print(sizes)
    write.csv(sizes,file.path(out,"model_sizes_and_fitted_ranges.csv"),row.names=FALSE)
    write.csv(main[c("pitch_id","pa_id","game_id","batter_id")],
              file.path(out,"primary_cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(models=models,tests=tests,intervals=intervals,main_data=main,all_data=d,
                 support=support,context_summary=summary_by_context),file.path(out,"tics_models.rds"))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    files <- c("scripts/06_project1_tics.R","scripts/01_import_R.R",
               list.files("data",pattern="[.]csv$",full.names=TRUE))
    hashes <- tools::md5sum(files);stopifnot(!anyNA(hashes))
    write.csv(data.frame(file=names(hashes),md5=unname(hashes)),
              file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/06_project1_tics.R",file.path(out,"06_project1_tics.R")))
    writeLines("Completed exploratory tic-count models; interpretation pending review.",
               file.path(out,"RUN_COMPLETE.txt"))
    cat("\nTic-count outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
tics_output <- run_project1_tics()
