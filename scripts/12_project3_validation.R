# First use of Validation outcomes for model selection; Test not evaluated.
# Frozen shortlist: M0_prevalence and M2_behavior. Criterion: validation log loss.
# Tie within 1e-12 goes to prevalence. No tuning, class balancing or threshold search.
# Run once for this selection milestone from repository root:
# source("scripts/12_project3_validation.R")
run_project3_validation <- function(
  candidate_dir="outputs/project3/candidates/20261002_164056_23628") {
  old_hashes <- read.csv(file.path(candidate_dir,"input_hashes.csv"),stringsAsFactors=FALSE)
  now <- tools::md5sum(old_hashes$file)
  stopifnot(!anyNA(now),all(unname(now)==old_hashes$md5))
  # Write the fixed protocol before calculating validation scores.
  out <- file.path("outputs","project3","validation",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output folder already exists.")
  dir.create(out,recursive=TRUE)
  protocol <- list(shortlist=c("M0_prevalence","M2_behavior"),
                   formula="target_strikeout ~ log_routine + total_tics",
                   selection_metric="Validation log loss, lower is better",
                   tie_rule="Within 1e-12 choose M0_prevalence",
                   threshold=.5,threshold_purpose="Diagnostic only; not an operational recommendation",
                   preprocessing="Natural log of observed positive duration; no learned scaling or imputation",
                   fitting_data="Train only: 1027 first-pitch rows, 27 games",
                   selection_data="Validation only: 223 first-pitch rows, 6 games",
                   final_plan="After review, refit selected model on Train+Validation; evaluate selected model and prevalence comparator on Test once. If prevalence selected, test prevalence only.",
                   test_use="None in this script",visibility="GitHub private until all four workstreams finished")
  saveRDS(protocol,file.path(out,"frozen_protocol.rds"))
  writeLines(capture.output(str(protocol)),file.path(out,"FROZEN_PROTOCOL.txt"))
  source("scripts/01_import_R.R",local=TRUE)
  first <- subset(tables$project3_snapshots,pitch_number_pa==1)
  a <- subset(first,split=="Train");v <- subset(first,split=="Validation")
  stopifnot(nrow(a)==1027,nrow(v)==223,length(unique(a$game_id))==27,
            length(unique(v$game_id))==6,!anyDuplicated(a$pa_id),!anyDuplicated(v$pa_id),
            !any(a$pa_id %in% v$pa_id),!any(a$game_id %in% v$game_id),
            max(as.Date(a$game_date))<min(as.Date(v$game_date)),
            all(a$target_strikeout %in% 0:1),all(v$target_strikeout %in% 0:1),
            all(a$routine_time_secs>0),all(v$routine_time_secs>0))
  a$log_routine <- log(a$routine_time_secs);v$log_routine <- log(v$routine_time_secs)
  stopifnot(all(complete.cases(a[c("log_routine","total_tics","target_strikeout")])),
            all(complete.cases(v[c("log_routine","total_tics","target_strikeout")])))
  score <- function(y,p) {
    stopifnot(length(y)==length(p),all(is.finite(p)),all(p>=0 & p<=1))
    q <- pmin(pmax(p,1e-15),1-1e-15);pos <- p>=.5
    tp <- sum(pos & y==1);fp <- sum(pos & y==0);tn <- sum(!pos & y==0);fn <- sum(!pos & y==1)
    n1 <- sum(y==1);n0 <- sum(y==0)
    data.frame(n=length(y),events=n1,prevalence=mean(y),mean_prediction=mean(p),
               log_loss=-mean(y*log(q)+(1-y)*log1p(-q)),brier=mean((p-y)^2),
               roc_auc=if(n1*n0>0)(sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*n0) else NA_real_,
               threshold=.5,accuracy=(tp+tn)/length(y),precision=if(tp+fp>0)tp/(tp+fp) else NA_real_,
               recall=if(tp+fn>0)tp/(tp+fn) else NA_real_,tp=tp,fp=fp,tn=tn,fn=fn)
  }
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    fit <- glm(target_strikeout ~ log_routine + total_tics,data=a,
               family=binomial(),na.action=na.fail)
    stopifnot(fit$converged,all(is.finite(coef(fit))))
    prevalence <- mean(a$target_strikeout)
    probabilities <- list(M0_prevalence=rep(prevalence,nrow(v)),
                          M2_behavior=unname(predict(fit,newdata=v,type="response")))
    pred <- do.call(rbind,lapply(names(probabilities),function(name)
      data.frame(model=name,v[c("pitch_id","pa_id","game_id","game_date")],
                 target_strikeout=v$target_strikeout,probability=probabilities[[name]])))
    results <- do.call(rbind,lapply(names(probabilities),function(name)
      cbind(data.frame(model=name),score(v$target_strikeout,probabilities[[name]]))))
    baseline_loss <- results$log_loss[results$model=="M0_prevalence"]
    behavior_loss <- results$log_loss[results$model=="M2_behavior"]
    selected <- if(behavior_loss < baseline_loss-1e-12)"M2_behavior" else "M0_prevalence"
    choice <- data.frame(selected_model=selected,criterion="Validation log loss",
                         baseline_log_loss=baseline_loss,behavior_log_loss=behavior_loss,
                         behavior_minus_baseline=behavior_loss-baseline_loss,
                         test_evaluated=FALSE)
    per_game <- do.call(rbind,lapply(split(pred,list(pred$game_id,pred$model),drop=TRUE),function(z)
      cbind(data.frame(game_id=z$game_id[1],model=z$model[1]),score(z$target_strikeout,z$probability))))
    # Fixed bins for descriptive calibration, never used to refit or select thresholds.
    pred$probability_bin <- cut(pred$probability,breaks=c(0,.1,.2,.3,.5,1),include.lowest=TRUE)
    calibration <- do.call(rbind,lapply(split(pred,list(pred$model,pred$probability_bin),drop=TRUE),function(z)
      data.frame(model=z$model[1],bin=as.character(z$probability_bin[1]),n=nrow(z),
                 mean_prediction=mean(z$probability),observed_fraction=mean(z$target_strikeout))))
    cat("\nVALIDATION SCORES: 223 PAs, six later games\n");print(results)
    cat("\nLOCKED SELECTION RULE RESULT\n");print(choice)
    cat("\nPER-GAME DIAGNOSTICS\n");print(per_game)
    cat("\nDESCRIPTIVE CALIBRATION BINS\n");print(calibration)
    write.csv(results,file.path(out,"validation_metrics.csv"),row.names=FALSE)
    write.csv(choice,file.path(out,"model_selection.csv"),row.names=FALSE)
    write.csv(pred,file.path(out,"validation_predictions.csv"),row.names=FALSE)
    write.csv(per_game,file.path(out,"validation_by_game.csv"),row.names=FALSE)
    write.csv(calibration,file.path(out,"validation_calibration_bins.csv"),row.names=FALSE)
    write.csv(data.frame(term=names(coef(fit)),coefficient=unname(coef(fit))),
              file.path(out,"train_fitted_behavior_coefficients.csv"),row.names=FALSE)
    write.csv(rbind(data.frame(role="Train",a[c("pitch_id","pa_id","game_id","game_date")]),
                    data.frame(role="Validation",v[c("pitch_id","pa_id","game_id","game_date")])),
              file.path(out,"cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(protocol=protocol,selection=choice,train_behavior_model=fit,
                 train_prevalence=prevalence,predictions=pred,metrics=results,
                 train_data=a,validation_data=v),file.path(out,"project3_validation.rds"))
    files <- unique(c("scripts/12_project3_validation.R",file.path(candidate_dir,"input_hashes.csv"),
                      file.path(candidate_dir,"pooled_metrics.csv"),old_hashes$file))
    h <- tools::md5sum(files);stopifnot(!anyNA(h))
    write.csv(data.frame(file=names(h),md5=unname(h)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/12_project3_validation.R",file.path(out,"12_project3_validation.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines(c("Validation is now used for selection; it is not final unbiased test performance.",
                 "No new candidate, recalibration or threshold was selected from the calibration/game diagnostics.",
                 "A lower score may be a tiny difference. Selection does not establish meaningful superiority.",
                 "Six games give limited evidence; no independent-PA performance intervals or significance tests are claimed.",
                 "0.5 is a diagnostic threshold only. No operating costs have been specified.",
                 "The next step reviews this fixed selection, refits using Train+Validation, and performs one final Test assessment.",
                 "Test rows may have been loaded by shared ingestion, but no Test predictions, targets or scores are analyzed here.",
                 "Earlier full-period predictor EDA remains documented. GitHub stays private until all four workstreams finish."),
               file.path(out,"INTERPRETATION_LIMITS.txt"))
    writeLines("Completed frozen two-model Validation selection. Test not evaluated.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nValidation outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project3_validation_output <- run_project3_validation()
