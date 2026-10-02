# Final assessment of the validation-selected M2 behavior model.
# Refit on Train+Validation, compare with prevalence on Test, and stop selection.
# Run from repository root: source("scripts/13_project3_final_test.R")
# No new packages. Reproducing this fixed analysis is allowed; tuning to Test is not.
run_project3_final_test <- function(
  validation_dir="outputs/project3/validation/20261002_202247_23628") {
  old_hashes <- read.csv(file.path(validation_dir,"input_hashes.csv"),stringsAsFactors=FALSE)
  current <- tools::md5sum(old_hashes$file)
  stopifnot(!anyNA(current),all(unname(current)==old_hashes$md5))
  previous <- readRDS(file.path(validation_dir,"project3_validation.rds"))
  choice <- read.csv(file.path(validation_dir,"model_selection.csv"),stringsAsFactors=FALSE)
  stopifnot(nrow(choice)==1,choice$selected_model=="M2_behavior",!choice$test_evaluated,
            previous$selection$selected_model==choice$selected_model,
            choice$behavior_log_loss < choice$baseline_log_loss-1e-12,
            identical(previous$protocol$shortlist,c("M0_prevalence","M2_behavior")))
  a <- rbind(previous$train_data,previous$validation_data)
  stopifnot(nrow(a)==1250,length(unique(a$game_id))==33,!anyDuplicated(a$pa_id),
            all(a$split %in% c("Train","Validation")),sum(a$target_strikeout)==218,
            all(complete.cases(a[c("routine_time_secs","total_tics","target_strikeout")])) ,
            all(a$routine_time_secs>0),all(a$target_strikeout %in% 0:1))
  a$log_routine <- log(a$routine_time_secs)
  out <- file.path("outputs","project3","final_test",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output directory already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    # Freeze fitted objects before opening the Test portion for assessment.
    fit <- glm(target_strikeout ~ log_routine + total_tics,data=a,
               family=binomial(),na.action=na.fail)
    stopifnot(fit$converged,all(is.finite(coef(fit))))
    baseline_probability <- mean(a$target_strikeout)
    final_plan <- list(selected_model="M2_behavior",comparator="M0_prevalence",
                       fit_n=nrow(a),fit_games=33,fit_events=sum(a$target_strikeout),
                       baseline_probability=baseline_probability,
                       formula="target_strikeout ~ log_routine + total_tics",
                       primary_metric="Test log loss, descriptive final assessment",
                       threshold=.5,threshold_purpose="Diagnostic only",
                       recalibration="None",selection_after_test="None",
                       validation_source=validation_dir)
    saveRDS(list(model=fit,baseline_probability=baseline_probability,plan=final_plan,
                 fit_cohort=a[c("pitch_id","pa_id","game_id","game_date","split")]),
            file.path(out,"frozen_final_model.rds"))
    writeLines(capture.output(dput(final_plan)),file.path(out,"FINAL_MODEL_PLAN.txt"))
    write.csv(data.frame(term=names(coef(fit)),coefficient=unname(coef(fit))),
              file.path(out,"final_behavior_coefficients.csv"),row.names=FALSE)
    raw <- read.csv("data/project3_snapshots.csv",stringsAsFactors=FALSE,na.strings="")
    test <- subset(raw,split=="Test" & pitch_number_pa==1)
    stopifnot(nrow(test)==208,length(unique(test$game_id))==6,!anyDuplicated(test$pa_id),
              !any(test$pa_id %in% a$pa_id),!any(test$game_id %in% a$game_id),
              max(as.Date(a$game_date))<min(as.Date(test$game_date)),
              all(test$target_strikeout %in% 0:1),all(test$routine_time_secs>0),
              all(complete.cases(test[c("routine_time_secs","total_tics","target_strikeout")])) )
    test$log_routine <- log(test$routine_time_secs)
    probabilities <- list(M0_prevalence=rep(baseline_probability,nrow(test)),
                          M2_behavior=unname(predict(fit,newdata=test[c("log_routine","total_tics")],type="response")))
    score <- function(y,p) {
      stopifnot(length(y)==length(p),all(is.finite(p)),all(p>=0 & p<=1))
      q <- pmin(pmax(p,1e-15),1-1e-15);yes <- p>=.5
      tp <- sum(yes & y==1);fp <- sum(yes & y==0);tn <- sum(!yes & y==0);fn <- sum(!yes & y==1)
      n1 <- sum(y==1);n0 <- sum(y==0)
      data.frame(n=length(y),events=n1,prevalence=mean(y),mean_prediction=mean(p),
                 log_loss=-mean(y*log(q)+(1-y)*log1p(-q)),brier=mean((p-y)^2),
                 roc_auc=if(n1*n0>0)(sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*n0) else NA_real_,
                 threshold=.5,accuracy=(tp+tn)/length(y),precision=if(tp+fp>0)tp/(tp+fp) else NA_real_,
                 recall=if(tp+fn>0)tp/(tp+fn) else NA_real_,tp=tp,fp=fp,tn=tn,fn=fn)
    }
    pred <- do.call(rbind,lapply(names(probabilities),function(name)
      data.frame(model=name,test[c("pitch_id","pa_id","game_id","game_date")],
                 target_strikeout=test$target_strikeout,probability=probabilities[[name]])))
    results <- do.call(rbind,lapply(names(probabilities),function(name)
      cbind(data.frame(model=name),score(test$target_strikeout,probabilities[[name]]))))
    b <- results[results$model=="M0_prevalence",];m <- results[results$model=="M2_behavior",]
    comparison <- data.frame(selected_model="M2_behavior",comparator="M0_prevalence",
                             log_loss_difference=m$log_loss-b$log_loss,
                             brier_difference=m$brier-b$brier,auc_difference=m$roc_auc-b$roc_auc,
                             interpretation="Negative loss differences favor selected model; no post-test reselection")
    per_game <- do.call(rbind,lapply(split(pred,list(pred$game_id,pred$model),drop=TRUE),function(z)
      cbind(data.frame(game_id=z$game_id[1],model=z$model[1]),score(z$target_strikeout,z$probability))))
    pred$probability_bin <- cut(pred$probability,breaks=c(0,.1,.2,.3,.5,1),include.lowest=TRUE)
    calibration <- do.call(rbind,lapply(split(pred,list(pred$model,pred$probability_bin),drop=TRUE),function(z)
      data.frame(model=z$model[1],bin=as.character(z$probability_bin[1]),n=nrow(z),
                 mean_prediction=mean(z$probability),observed_fraction=mean(z$target_strikeout))))
    roc_points <- function(y,p) {
      n1 <- sum(y==1);n0 <- sum(y==0)
      if(n1==0 || n0==0) return(data.frame(fpr=numeric(),tpr=numeric()))
      o <- order(p,decreasing=TRUE);y <- y[o];p <- p[o]
      ends <- c(which(diff(p)!=0),length(p))
      data.frame(fpr=c(0,cumsum(y==0)[ends]/n0),tpr=c(0,cumsum(y==1)[ends]/n1))
    }
    rocs <- lapply(probabilities,function(p)roc_points(test$target_strikeout,p))
    # Linear interpolation through tied-score blocks gives diagonal baseline ROC.
    local({
      png(file.path(out,"final_test_diagnostics.png"),width=2000,height=1000,res=180)
      on.exit(dev.off())
      par(mfrow=c(1,2),mar=c(5,5,4,2),oma=c(4,0,3,0))
      colors <- c(M0_prevalence="#64748B",M2_behavior="#17618C")
      plot(NA,xlim=c(0,1),ylim=c(0,1),xlab="False positive rate",ylab="True positive rate",main="Test ROC",xaxs="i",yaxs="i")
      abline(0,1,lty=3,col="gray75")
      for(name in names(rocs)) if(nrow(rocs[[name]])>0)lines(rocs[[name]]$fpr,rocs[[name]]$tpr,col=colors[name],lwd=2)
      legend("bottomright",legend=sprintf("%s: AUC %.3f",c("Prevalence","Behavior"),results$roc_auc),
             col=colors[results$model],lwd=2,bty="n",cex=.85)
      plot(NA,xlim=c(0,1),ylim=c(0,1),xlab="Mean predicted probability",ylab="Observed strikeout fraction",main="Fixed-bin calibration",xaxs="i",yaxs="i")
      abline(0,1,lty=3,col="gray65")
      for(name in names(probabilities)) {
        z <- calibration[calibration$model==name,]
        points(z$mean_prediction,z$observed_fraction,col=colors[name],pch=if(name=="M0_prevalence")17 else 19,cex=1.3)
      }
      legend("topleft",legend=c("Prevalence","Behavior"),col=colors,pch=c(17,19),bty="n",cex=.85)
      mtext("Workstream 3 | Final reserved-period assessment",outer=TRUE,side=3,line=1,font=2)
      mtext("208 first-pitch PAs; six test games. Refit on 1,250 Train + Validation PAs.\nNo post-test model or threshold selection. Calibration bins are descriptive; no confidence intervals.",outer=TRUE,side=1,line=1,cex=.8)
    })
    cat("\nFINAL REFIT\n");print(final_plan)
    cat("\nFINAL TEST METRICS\n");print(results)
    cat("\nFROZEN MODEL COMPARISON\n");print(comparison)
    cat("\nPER-GAME RESULTS\n");print(per_game)
    write.csv(results,file.path(out,"test_metrics.csv"),row.names=FALSE)
    write.csv(comparison,file.path(out,"test_comparison.csv"),row.names=FALSE)
    write.csv(pred,file.path(out,"test_predictions.csv"),row.names=FALSE)
    write.csv(per_game,file.path(out,"test_by_game.csv"),row.names=FALSE)
    write.csv(calibration,file.path(out,"test_calibration_bins.csv"),row.names=FALSE)
    for(name in names(rocs))write.csv(rocs[[name]],file.path(out,paste0(name,"_roc_points.csv")),row.names=FALSE)
    write.csv(rbind(data.frame(role="Refit",a[c("pitch_id","pa_id","game_id","game_date")]),
                    data.frame(role="Test",test[c("pitch_id","pa_id","game_id","game_date")])),
              file.path(out,"cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(final_model=fit,baseline_probability=baseline_probability,plan=final_plan,
                 metrics=results,comparison=comparison,predictions=pred,calibration=calibration,
                 roc_points=rocs,refit_data=a,test_data=test),file.path(out,"project3_final_test.rds"))
    notes <- c("Test has now been evaluated; it is no longer unused for this project.",
               "M2 remains the validation-selected approach; do not select a replacement using these test scores.",
               "If M2 loses to prevalence, report failure to beat that benchmark on these six games.",
               "All performance numbers are descriptive; six game clusters limit uncertainty assessment and generalization.",
               "No independent-PA confidence intervals or formal model-comparison p-values are claimed.",
               "Threshold .5 is a diagnostic convention, not an optimized operational threshold.",
               "Calibration displays do not authorize post-test recalibration. New development would require fresh evaluation data.",
               "Earlier full-period predictor EDA was documented; held-out target evaluation followed the frozen selection sequence.",
               "Prediction time is after the first-pitch routine, before the first-pitch outcome.",
               "The final model concerns eligible observed-routine/tic PAs in this team/time window, not all baseball PAs.",
               "GitHub remains private until all four workstreams are finished.")
    writeLines(notes,file.path(out,"INTERPRETATION_LIMITS.txt"))
    table_lines <- vapply(seq_len(nrow(results)),function(i) {
      r <- results[i,];sprintf("| %s | %.6f | %.6f | %.3f | %.3f | %.3f |",r$model,r$log_loss,r$brier,r$roc_auc,r$accuracy,r$recall)
    },character(1))
    writeLines(c("# Workstream 3 — Final test output", "", "Interpretation pending review. Model selection is closed.","",
                 "| Model | Log loss | Brier | ROC-AUC | Accuracy at .5 | Recall at .5 |",
                 "|---|---:|---:|---:|---:|---:|",table_lines,"",
                 "![Final test diagnostics](final_test_diagnostics.png)","",notes),file.path(out,"TEST_RESULT_SUMMARY.md"))
    files <- unique(c("scripts/13_project3_final_test.R",file.path(validation_dir,c("project3_validation.rds","model_selection.csv")),old_hashes$file))
    h <- tools::md5sum(files);stopifnot(!anyNA(h))
    write.csv(data.frame(file=names(h),md5=unname(h)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/13_project3_final_test.R",file.path(out,"13_project3_final_test.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines("Completed final reserved-period assessment. Test is now used; interpretation pending review, no model reselection.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nFinal test outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project3_final_test_output <- run_project3_final_test()
