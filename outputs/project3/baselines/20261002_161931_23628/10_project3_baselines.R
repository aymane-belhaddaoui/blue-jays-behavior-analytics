# First-pitch strikeout prediction: chronological development benchmarks.
# Run from repository root: source("scripts/10_project3_baselines.R")
# No new packages. Fit/assess only within Train; validation/test outcomes unused.
# Prediction time: after first-pitch routine is observed, before pitch outcome.
# Models predict probabilities. Their coefficients are not causal estimates.
run_project3_baselines <- function() {
  source("scripts/01_import_R.R",local=TRUE)
  d <- subset(tables$project3_snapshots,split=="Train" & pitch_number_pa==1)
  meta <- tables$project1_pitches
  stopifnot(!anyDuplicated(meta$pitch_id),!anyDuplicated(d$pitch_id),!anyDuplicated(d$pa_id))
  idx <- match(d$pitch_id,meta$pitch_id)
  stopifnot(!anyNA(idx),all(meta$pa_id[idx]==d$pa_id),all(meta$game_id[idx]==d$game_id),
            all(meta$split[idx]=="Train"),all(meta$routine_model_eligible[idx]==1),
            all(meta$tics_model_eligible[idx]==1),all(meta$pa_sequence_valid[idx]==1))
  # First-pitch context only; no full-PA means, pitch totals, outcomes or alternate target.
  d$risp_start <- meta$risp[idx];d$home <- meta$home[idx];d$inning <- meta$inning[idx]
  d$batter_id <- meta$batter_id[idx] # audit only; not yet a predictor
  d$game_date <- as.Date(d$game_date)
  d$log_routine <- log(d$routine_time_secs)
  stopifnot(nrow(d)==1027,sum(d$target_strikeout)==185,
            all(d$target_strikeout %in% 0:1),all(d$pre_balls==0),all(d$pre_strikes==0),
            all(d$routine_time_secs>0),all(d$risp_start %in% 0:1),all(d$home %in% 0:1),
            all(complete.cases(d[c("game_date","log_routine","total_tics","risp_start","home","inning")])))
  dates <- sort(unique(d$game_date))
  stopifnot(length(dates)==27,length(unique(d$game_id))==27)
  # Fixed expanding windows; whole game dates remain together.
  # Fit dates 1:12 -> assess 13:17; 1:17 -> 18:22; 1:22 -> 23:27.
  ends <- c(12L,17L,22L)
  formulas <- list(
    M1_context=target_strikeout ~ risp_start + home + inning,
    M2_behavior=target_strikeout ~ log_routine + total_tics,
    M3_context_behavior=target_strikeout ~ risp_start + home + inning + log_routine + total_tics)
  # Deliberately low-dimensional starting benchmarks. Batter/opponent effects,
  # nonlinearities and ensembles are not covered by this initial comparison.
  score <- function(y,p) {
    stopifnot(length(y)==length(p),all(is.finite(p)),all(p>=0 & p<=1))
    q <- pmin(pmax(p,1e-15),1-1e-15)
    positive <- p>=.5;tp <- sum(positive & y==1);fp <- sum(positive & y==0)
    tn <- sum(!positive & y==0);fn <- sum(!positive & y==1)
    n1 <- sum(y==1);n0 <- sum(y==0)
    auc <- if(n1*n0>0) (sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0) else NA_real_
    data.frame(n=length(y),events=n1,prevalence=mean(y),
               log_loss=-mean(y*log(q)+(1-y)*log1p(-q)),brier=mean((p-y)^2),roc_auc=auc,
               threshold=.5,accuracy=(tp+tn)/length(y),precision=if(tp+fp>0)tp/(tp+fp) else NA_real_,
               recall=if(tp+fn>0)tp/(tp+fn) else NA_real_,tp=tp,fp=fp,tn=tn,fn=fn)
  }
  out <- file.path("outputs","project3","baselines",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output folder already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    predictions <- list();folds <- list();members <- list();fits <- list()
    for(k in seq_along(ends)) {
      a <- d[d$game_date %in% dates[seq_len(ends[k])],]
      v <- d[d$game_date %in% dates[(ends[k]+1L):(ends[k]+5L)],]
      stopifnot(max(a$game_date)<min(v$game_date),!any(a$game_id %in% v$game_id),
                length(unique(a$target_strikeout))==2,length(unique(v$target_strikeout))==2)
      folds[[k]] <- data.frame(fold=k,fit_start=min(a$game_date),fit_end=max(a$game_date),
                               assess_start=min(v$game_date),assess_end=max(v$game_date),
                               fit_n=nrow(a),fit_events=sum(a$target_strikeout),
                               assess_n=nrow(v),assess_events=sum(v$target_strikeout))
      members[[k]] <- rbind(data.frame(fold=k,role="fit",a[c("pa_id","game_id","game_date")]),
                            data.frame(fold=k,role="assess",v[c("pa_id","game_id","game_date")]))
      probs <- list(M0_prevalence=rep(mean(a$target_strikeout),nrow(v)))
      for(name in names(formulas)) {
        fit <- glm(formulas[[name]],data=a,family=binomial(),na.action=na.fail)
        if(!fit$converged || any(!is.finite(coef(fit)))) stop("Unstable model: ",name," fold ",k)
        fits[[paste(k,name,sep="_")]] <- fit
        probs[[name]] <- unname(predict(fit,newdata=v,type="response"))
      }
      predictions[[k]] <- do.call(rbind,lapply(names(probs),function(name) {
        data.frame(fold=k,model=name,v[c("pa_id","game_id","game_date")],
                   target_strikeout=v$target_strikeout,probability=probs[[name]])
      }))
    }
    pred <- do.call(rbind,predictions);fold_table <- do.call(rbind,folds)
    stopifnot(!anyDuplicated(pred[c("model","pa_id")]))
    fold_metrics <- do.call(rbind,lapply(split(pred,list(pred$fold,pred$model),drop=TRUE),function(z)
      cbind(data.frame(fold=z$fold[1],model=z$model[1]),score(z$target_strikeout,z$probability))))
    pooled <- do.call(rbind,lapply(split(pred,pred$model),function(z)
      cbind(data.frame(model=z$model[1]),score(z$target_strikeout,z$probability))))
    baseline <- pooled[pooled$model=="M0_prevalence",]
    pooled$log_loss_difference_vs_baseline <- pooled$log_loss-baseline$log_loss
    pooled$brier_difference_vs_baseline <- pooled$brier-baseline$brier
    pooled <- pooled[order(pooled$log_loss),]
    cat("\nFIXED TEMPORAL FOLDS\n");print(fold_table)
    cat("\nFOLD METRICS\n");print(fold_metrics)
    cat("\nPOOLED OUT-OF-FOLD METRICS: lower log loss/Brier is better\n");print(pooled)
    write.csv(fold_table,file.path(out,"fold_schedule.csv"),row.names=FALSE)
    write.csv(do.call(rbind,members),file.path(out,"fold_membership.csv"),row.names=FALSE)
    write.csv(pred,file.path(out,"out_of_fold_predictions.csv"),row.names=FALSE)
    write.csv(fold_metrics,file.path(out,"fold_metrics.csv"),row.names=FALSE)
    write.csv(pooled,file.path(out,"pooled_metrics.csv"),row.names=FALSE)
    write.csv(d[c("pitch_id","pa_id","game_id","game_date","batter_id")],file.path(out,"train_cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(fold_models=fits,formulas=formulas,train_data=d,folds=fold_table,
                 predictions=pred,fold_metrics=fold_metrics,pooled_metrics=pooled),file.path(out,"project3_baselines.rds"))
    writeLines(c("Primary development metric: log loss. Secondary: Brier score; ROC-AUC describes ranking.",
                 "0.5 is a diagnostic threshold only; no threshold optimization or class balancing.",
                 "First 12 training dates initialize fitting; OOF metrics cover the later 15 dates only.",
                 "The baseline estimates prevalence from each fold's fit data, never assessment labels.",
                 "Pooled AUC can reflect differences between folds; inspect fold AUCs as well.",
                 "All folds come from Train. Validation and Test outcomes are not evaluated.",
                 "Later folds reuse earlier assessment dates for fitting, as in expanding-window forecasting.",
                 "No independent-PA standard errors, model-comparison p-values or performance CIs are claimed.",
                 "Same-team later-game prediction; not a test of generalization to unseen players.",
                 "Initial context is limited to RISP, home/road and inning; no player/opponent benchmark yet.",
                 "A winning development score is not a final selected/tested model. Holdout evaluation follows a frozen specification.",
                 "Earlier full-period predictor EDA remains documented. No labels from holdout are used to choose this design."),
               file.path(out,"DESIGN_AND_LIMITS.txt"))
    files <- c("scripts/10_project3_baselines.R","scripts/01_import_R.R",list.files("data",pattern="[.]csv$",full.names=TRUE))
    h <- tools::md5sum(files);stopifnot(!anyNA(h))
    write.csv(data.frame(file=names(h),md5=unname(h)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/10_project3_baselines.R",file.path(out,"10_project3_baselines.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines("Completed Train-only temporal baselines. Validation/Test not evaluated; model selection pending review.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nProject 3 baseline outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project3_baselines_output <- run_project3_baselines()
