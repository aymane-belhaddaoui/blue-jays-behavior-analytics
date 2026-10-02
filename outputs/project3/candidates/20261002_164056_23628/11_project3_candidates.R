# A bounded, fixed candidate round on the same Train-only temporal folds.
# Install once: install.packages(c("glmnet", "ranger"))
# Run from repository root: source("scripts/11_project3_candidates.R")
run_project3_candidates <- function(
  previous_dir="outputs/project3/baselines/20261002_161931_23628") {
  for(pkg in c("glmnet","ranger")) if(!requireNamespace(pkg,quietly=TRUE))
    stop("Install required package: ",pkg)
  old_hashes <- read.csv(file.path(previous_dir,"input_hashes.csv"),stringsAsFactors=FALSE)
  current_hashes <- tools::md5sum(old_hashes$file)
  stopifnot(!anyNA(current_hashes),all(unname(current_hashes)==old_hashes$md5))
  previous <- readRDS(file.path(previous_dir,"project3_baselines.rds"))
  d <- previous$train_data
  stopifnot(nrow(d)==1027,all(d$split=="Train"),sum(d$target_strikeout)==185,
            !anyDuplicated(d$pa_id),!anyDuplicated(d$pitch_id))
  meta <- read.csv("data/project1_pitches.csv",stringsAsFactors=FALSE,na.strings="")
  stopifnot(!anyDuplicated(meta$pitch_id))
  idx <- match(d$pitch_id,meta$pitch_id)
  stopifnot(!anyNA(idx),all(meta$split[idx]=="Train"),all(meta$batter_id[idx]==d$batter_id))
  d$opponent <- meta$opponent[idx]
  stopifnot(!anyNA(d$opponent),!anyNA(d$batter_id))
  # One-hot levels are learned ONLY from the fitting window. New categories in
  # an assessment window map to all-zero indicators for that field and are logged.
  # No target encoding and no global category vocabularies.
  encode_pair <- function(a,v,behavior) {
    numeric_cols <- c("risp_start","home","inning",if(behavior)c("log_routine","total_tics"))
    xa <- as.matrix(a[numeric_cols]);xv <- as.matrix(v[numeric_cols]);levels_used <- list()
    for(key in c("batter_id","opponent")) {
      lev <- sort(unique(as.character(a[[key]])));levels_used[[key]] <- lev
      ta <- vapply(lev,function(l)as.numeric(a[[key]]==l),numeric(nrow(a)))
      tv <- vapply(lev,function(l)as.numeric(v[[key]]==l),numeric(nrow(v)))
      colnames(ta) <- colnames(tv) <- paste0(key,"_",seq_along(lev))
      xa <- cbind(xa,ta);xv <- cbind(xv,tv)
    }
    keep <- apply(xa,2,function(x)length(unique(x))>1)
    xa <- xa[,keep,drop=FALSE];xv <- xv[,keep,drop=FALSE]
    stopifnot(ncol(xa)>1,identical(colnames(xa),colnames(xv)),all(is.finite(xa)),all(is.finite(xv)))
    list(fit=xa,assess=xv,levels=levels_used,numeric_cols=numeric_cols,
         retained_columns=colnames(xa),unseen_batters=sum(!v$batter_id %in% levels_used$batter_id),
         unseen_opponents=sum(!v$opponent %in% levels_used$opponent))
  }
  score <- function(y,p) {
    stopifnot(length(y)==length(p),all(is.finite(p)),all(p>=0 & p<=1))
    q <- pmin(pmax(p,1e-15),1-1e-15);pos <- p>=.5
    tp <- sum(pos & y==1);fp <- sum(pos & y==0);tn <- sum(!pos & y==0);fn <- sum(!pos & y==1)
    n1 <- sum(y==1);n0 <- sum(y==0)
    data.frame(n=length(y),events=n1,log_loss=-mean(y*log(q)+(1-y)*log1p(-q)),
               brier=mean((p-y)^2),roc_auc=if(n1*n0>0)(sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*n0) else NA_real_,
               accuracy=(tp+tn)/length(y),precision=if(tp+fp>0)tp/(tp+fp) else NA_real_,
               recall=if(tp+fn>0)tp/(tp+fn) else NA_real_,tp=tp,fp=fp,tn=tn,fn=fn)
  }
  out <- file.path("outputs","project3","candidates",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output folder already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    models <- list();encoders <- list();predictions <- list();audit <- list();counter <- 0L
    for(k in seq_len(nrow(previous$folds))) {
      row <- previous$folds[k,]
      a <- d[d$game_date>=row$fit_start & d$game_date<=row$fit_end,]
      v <- d[d$game_date>=row$assess_start & d$game_date<=row$assess_end,]
      stopifnot(nrow(a)==row$fit_n,nrow(v)==row$assess_n,max(a$game_date)<min(v$game_date),
                !any(a$game_id %in% v$game_id))
      for(behavior in c(FALSE,TRUE)) {
        pair <- encode_pair(a,v,behavior)
        suffix <- if(behavior)"behavior" else "context"
        ridge_name <- if(behavior)"M5_ridge_player_behavior" else "M4_ridge_player_context"
        rf_name <- if(behavior)"M7_forest_player_behavior" else "M6_forest_player_context"
        # Fixed ridge strength, no cv.glmnet (which would randomly split by default).
        ridge <- glmnet::glmnet(pair$fit,a$target_strikeout,family="binomial",alpha=0,
                                lambda=c(.1,.03,.01),standardize=TRUE,intercept=TRUE)
        if(!is.null(ridge$jerr) && ridge$jerr!=0) stop("glmnet fitting error in fold ",k)
        pr <- as.numeric(predict(ridge,newx=pair$assess,s=.01,type="response"))
        # Fixed probability forest; no class weights, resampling or importance tuning.
        mt <- max(1L,floor(sqrt(ncol(pair$fit))))
        forest <- ranger::ranger(x=as.data.frame(pair$fit),
                                  y=factor(a$target_strikeout,levels=c(0,1),labels=c("No","Yes")),
                                  probability=TRUE,num.trees=500,mtry=mt,min.node.size=20,
                                  splitrule="gini",seed=20261002L+k,num.threads=1,write.forest=TRUE)
        pf <- as.numeric(predict(forest,data=as.data.frame(pair$assess),num.threads=1)$predictions[,"Yes"])
        for(name in c(ridge_name,rf_name)) {
          prob <- if(name==ridge_name)pr else pf
          counter <- counter+1L
          predictions[[counter]] <- data.frame(fold=k,model=name,v[c("pa_id","game_id","game_date")],
                                                target_strikeout=v$target_strikeout,probability=prob)
          models[[paste(k,name,sep="_")]] <- if(name==ridge_name)ridge else forest
        }
        key <- paste(k,suffix,sep="_")
        encoders[[key]] <- pair[c("levels","numeric_cols","retained_columns")]
        audit[[key]] <- data.frame(fold=k,feature_set=suffix,columns=ncol(pair$fit),
                                   unseen_batter_rows=pair$unseen_batters,unseen_opponent_rows=pair$unseen_opponents,
                                   ridge_lambda=.01,forest_trees=500,forest_mtry=mt,forest_min_node_size=20)
      }
    }
    new_pred <- do.call(rbind,predictions)
    old_pred <- previous$predictions
    # Same rows, labels and folds for every old/new model.
    reference <- old_pred[old_pred$model=="M0_prevalence",]
    for(name in unique(new_pred$model)) {
      z <- new_pred[new_pred$model==name,];ix <- match(reference$pa_id,z$pa_id)
      stopifnot(nrow(z)==576,!anyNA(ix),!anyDuplicated(z$pa_id),
                all(reference$fold==z$fold[ix]),all(reference$target_strikeout==z$target_strikeout[ix]))
    }
    pred <- rbind(old_pred,new_pred)
    fold_metrics <- do.call(rbind,lapply(split(pred,list(pred$fold,pred$model),drop=TRUE),function(z)
      cbind(data.frame(fold=z$fold[1],model=z$model[1]),score(z$target_strikeout,z$probability))))
    pooled <- do.call(rbind,lapply(split(pred,pred$model),function(z)
      cbind(data.frame(model=z$model[1]),score(z$target_strikeout,z$probability))))
    pooled$log_loss_difference_vs_baseline <- pooled$log_loss-pooled$log_loss[pooled$model=="M0_prevalence"]
    pooled <- pooled[order(pooled$log_loss),]
    differences <- do.call(rbind,lapply(list(c("M5_ridge_player_behavior","M4_ridge_player_context"),
                                           c("M7_forest_player_behavior","M6_forest_player_context")),function(pair) {
      do.call(rbind,lapply(1:3,function(k) {
        a <- fold_metrics[fold_metrics$fold==k & fold_metrics$model==pair[1],]
        b <- fold_metrics[fold_metrics$fold==k & fold_metrics$model==pair[2],]
        data.frame(fold=k,with_behavior=pair[1],without_behavior=pair[2],
                   log_loss_difference=a$log_loss-b$log_loss,brier_difference=a$brier-b$brier)
      }))
    }))
    cat("\nPOOLED DEVELOPMENT METRICS\n");print(pooled)
    cat("\nBEHAVIOR INCREMENT WITHIN MODEL FAMILY (negative favors behavior)\n");print(differences)
    cat("\nENCODING / SETTINGS AUDIT\n");print(do.call(rbind,audit))
    write.csv(pred,file.path(out,"all_out_of_fold_predictions.csv"),row.names=FALSE)
    write.csv(fold_metrics,file.path(out,"fold_metrics.csv"),row.names=FALSE)
    write.csv(pooled,file.path(out,"pooled_metrics.csv"),row.names=FALSE)
    write.csv(differences,file.path(out,"behavior_increment_by_fold.csv"),row.names=FALSE)
    write.csv(do.call(rbind,audit),file.path(out,"encoding_audit.csv"),row.names=FALSE)
    write.csv(previous$folds,file.path(out,"fold_schedule.csv"),row.names=FALSE)
    saveRDS(list(models=models,encoders=encoders,train_data=d,folds=previous$folds,
                 predictions=pred,fold_metrics=fold_metrics,pooled_metrics=pooled,
                 original_baseline_dir=previous_dir),file.path(out,"project3_candidates.rds"))
    files <- unique(c("scripts/11_project3_candidates.R",file.path(previous_dir,"project3_baselines.rds"),old_hashes$file))
    h <- tools::md5sum(files);stopifnot(!anyNA(h))
    write.csv(data.frame(file=names(h),md5=unname(h)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/11_project3_candidates.R",file.path(out,"11_project3_candidates.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines(c("Fixed candidate round: ridge lambda .01; probability forests 500 trees, min.node.size 20, mtry floor(sqrt(p)).",
                 "Lambda path supplies warm starts; only .01 is assessed. No hyperparameter search is conducted.",
                 "Player/opponent one-hot levels and zero-variance filtering learned within fit window only.",
                 "Unseen categories use all-zero indicators for their field, not target encoding. Rows logged in encoding_audit.csv.",
                 "glmnet standardization is learned from fit data internally; forest input is unstandardized.",
                 "Compare behavior additions within the same model family. Different-feature forests also change mtry under the fixed rule.",
                 "This is exploratory model development after reviewing script10. Reusing folds does not make selection unbiased.",
                 "No holdout evaluation, threshold tuning, class balancing, or feature-importance claim.",
                 "Review this bounded round, freeze a shortlist, then evaluate Validation. Test remains for final assessment.",
                 "GitHub remains private until all four workstreams are finished."),file.path(out,"DESIGN_AND_LIMITS.txt"))
    writeLines("Completed Train-only candidate comparison; no final selection or Validation/Test evaluation.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nCandidate outputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project3_candidates_output <- run_project3_candidates()
