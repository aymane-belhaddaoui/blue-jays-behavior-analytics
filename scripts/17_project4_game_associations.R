# Workstream 4: final descriptive game-level associations.
# Run from repository root: source("scripts/17_project4_game_associations.R")
# Base R only. Six exploratory comparisons, no fitted prediction model or p-values.
# No changes to the core data or Workstream 3's completed test assessment.
run_project4_game_associations <- function(
  game_dir="outputs/project4/game_kpis/20261002_214708_23628") {
  old_hashes <- read.csv(file.path(game_dir,"input_hashes.csv"),stringsAsFactors=FALSE)
  current <- tools::md5sum(old_hashes$file)
  stopifnot(!anyNA(current),all(unname(current)==old_hashes$md5))
  game_file <- file.path(game_dir,"game_kpis.csv")
  stopifnot(unname(tools::md5sum(game_file))=="9ac38262d5b4693ebbe7d85b8d0bfdc5")
  g <- read.csv(game_file,stringsAsFactors=FALSE,na.strings="")
  g <- g[order(g$game_order),];rownames(g) <- NULL
  stopifnot(nrow(g)==39,!anyDuplicated(g$game_id),all(g$game_order==1:39),
    all(g$win %in% 0:1),sum(g$win)==20,
    all(complete.cases(g[c("routine_undisrupted_mean_secs","tics_undisrupted_mean")])) )
  first_loss <- which(g$win==0)[1]
  g$streak_reset_observed_before_game <- as.integer(g$game_order>first_loss)
  # Initial streaks may extend before this observation window. Exclude the first
  # three games from primary streak comparisons; retain them in a named sensitivity.
  stopifnot(first_loss==3,sum(g$streak_reset_observed_before_game)==36,
    sum(!is.na(g$prior5_win_rate))==34)
  plan <- data.frame(
    pair_id=c("A1","A2","A3","A4","A5","A6"),
    context=c("win","win","prior5_win_rate","prior5_win_rate",
              "window_win_streak_before","window_win_streak_before"),
    context_label=rep(c("Same-game result","Prior-five-game win rate","Prior logged win streak"),each=2),
    feature=rep(c("routine_undisrupted_mean_secs","tics_undisrupted_mean"),3),
    feature_label=rep(c("Mean routine duration (seconds)","Mean tic count"),3),
    cohort=rep(c("All logged games","Complete prior-five-game history","Observed prior loss resets streak"),each=2),
    expected_n=rep(c(39L,34L,36L),each=2),stringsAsFactors=FALSE)
  safe_cor <- function(x,y,method="pearson") {
    ok <- is.finite(x)&is.finite(y);x <- x[ok];y <- y[ok]
    if(length(x)<3 || length(unique(x))<2 || length(unique(y))<2) return(NA_real_)
    cor(x,y,method=method)
  }
  pair_data <- do.call(rbind,lapply(seq_len(nrow(plan)),function(i) {
    r <- plan[i,];use <- complete.cases(g[c(r$context,r$feature)])
    if(r$context=="window_win_streak_before") use <- use & g$streak_reset_observed_before_game==1
    z <- g[use,];stopifnot(nrow(z)==r$expected_n)
    data.frame(pair_id=r$pair_id,z[c("game_id","game_order","game_date","opponent","venue","win")],
      context=r$context,feature=r$feature,x=z[[r$context]],y=z[[r$feature]],stringsAsFactors=FALSE)
  }))
  results <- do.call(rbind,lapply(seq_len(nrow(plan)),function(i) {
    r <- plan[i,];z <- pair_data[pair_data$pair_id==r$pair_id,]
    cbind(r,data.frame(n=nrow(z),context_levels=length(unique(z$x)),
      pearson_r=safe_cor(z$x,z$y),spearman_rho=safe_cor(z$x,z$y,"spearman")))
  }))
  stopifnot(all(is.finite(results$pearson_r)),all(is.finite(results$spearman_rho)))
  # Point-influence sensitivity: remove a row from a pair but keep its neighbors'
  # recorded historical context fixed. This does not rewrite the game sequence.
  loo <- do.call(rbind,lapply(plan$pair_id,function(id) {
    z <- pair_data[pair_data$pair_id==id,]
    do.call(rbind,lapply(seq_len(nrow(z)),function(i)
      data.frame(pair_id=id,omitted_game_id=z$game_id[i],remaining_n=nrow(z)-1,
        pearson_r=safe_cor(z$x[-i],z$y[-i]),spearman_rho=safe_cor(z$x[-i],z$y[-i],"spearman"))))
  }))
  influence <- do.call(rbind,lapply(plan$pair_id,function(id) {
    z <- loo[loo$pair_id==id,];r <- results[results$pair_id==id,]
    stopifnot(all(is.finite(z$pearson_r)),all(is.finite(z$spearman_rho)))
    data.frame(pair_id=id,n=r$n,pearson_r=r$pearson_r,
      loo_pearson_min=min(z$pearson_r),loo_pearson_max=max(z$pearson_r),
      pearson_min_omitted_game=z$omitted_game_id[which.min(z$pearson_r)],
      pearson_max_omitted_game=z$omitted_game_id[which.max(z$pearson_r)],
      pearson_sign_changes=any(sign(z$pearson_r)!=sign(r$pearson_r)),
      spearman_rho=r$spearman_rho,loo_spearman_min=min(z$spearman_rho),loo_spearman_max=max(z$spearman_rho))
  }))
  support <- do.call(rbind,lapply(plan$pair_id,function(id) {
    z <- pair_data[pair_data$pair_id==id,]
    do.call(rbind,lapply(split(z,z$x),function(a)
      data.frame(pair_id=id,context=a$context[1],feature=a$feature[1],context_value=a$x[1],
        games=nrow(a),mean_feature=mean(a$y),median_feature=median(a$y),
        sd_feature=if(nrow(a)>1)sd(a$y) else NA_real_)))
  }))
  streak_sensitivity <- do.call(rbind,lapply(unique(plan$feature),function(feature) {
    do.call(rbind,lapply(c("Primary: observed prior loss","All 39: window-truncated streak"),function(cohort) {
      z <- if(cohort=="Primary: observed prior loss")g[g$streak_reset_observed_before_game==1,] else g
      data.frame(feature=feature,cohort=cohort,n=nrow(z),
        pearson_r=safe_cor(z$window_win_streak_before,z[[feature]]),
        spearman_rho=safe_cor(z$window_win_streak_before,z[[feature]],"spearman"))
    }))
  }))
  contrasts <- do.call(rbind,lapply(unique(plan$feature),function(feature)
    data.frame(feature=feature,win_games=sum(g$win==1),loss_games=sum(g$win==0),
      mean_wins=mean(g[[feature]][g$win==1]),mean_losses=mean(g[[feature]][g$win==0]),
      win_minus_loss=mean(g[[feature]][g$win==1])-mean(g[[feature]][g$win==0]))))
  out <- file.path("outputs","project4","associations",
    paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output directory already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    write_table <- function(x,name)write.csv(x,file.path(out,name),row.names=FALSE,na="",fileEncoding="UTF-8")
    write_table(plan,"analysis_plan.csv")
    write_table(results,"correlations.csv")
    write_table(pair_data,"analysis_pair_data.csv")
    write_table(loo,"leave_one_game_out.csv")
    write_table(influence,"influence_summary.csv")
    write_table(support,"history_group_support.csv")
    write_table(streak_sensitivity,"streak_boundary_sensitivity.csv")
    write_table(contrasts,"win_loss_contrasts.csv")
    write_table(g[c("game_id","game_order","game_date","win","prior5_win_rate",
      "window_win_streak_before","streak_reset_observed_before_game")],"history_eligibility.csv")
    local({
      png(file.path(out,"game_associations.png"),width=2200,height=1950,res=190)
      on.exit(dev.off())
      par(mfrow=c(3,2),mar=c(4.6,4.8,3.5,1),oma=c(3.5,0,2,0))
      for(i in seq_len(nrow(plan))) {
        r <- results[i,];z <- pair_data[pair_data$pair_id==r$pair_id,]
        plot(z$x,z$y,pch=16,col=adjustcolor("#245C88",alpha.f=.65),xaxt="n",
          xlab=r$context_label,ylab=r$feature_label,
          main=sprintf("%s | n = %d",if(r$feature=="routine_undisrupted_mean_secs")"Routine duration" else "Tic count",r$n))
        at <- sort(unique(z$x))
        axis(1,at=at,labels=if(r$context=="win")c("Loss","Win") else if(r$context=="prior5_win_rate")paste0(round(100*at),"%") else at)
        means <- aggregate(y~x,data=z,FUN=mean)
        points(means$x,means$y,pch=18,cex=1.5,col="#182636")
        mtext(sprintf("Pearson r = %.3f; Spearman rho = %.3f",r$pearson_r,r$spearman_rho),side=3,line=.25,cex=.8)
      }
      mtext("Workstream 4: exploratory game-level associations",outer=TRUE,side=3,font=2)
      mtext("Dots: logged games. Diamonds: context-group means. Games have equal weight.\nNo causal interpretation, prediction claim, confidence intervals, or hypothesis tests.",outer=TRUE,side=1,line=1,cex=.85)
    })
    notes <- c(
      "Exploratory analysis after prior EDA, not a preregistered confirmatory study. Six fixed comparisons are reported together.",
      "Each observation is one game. Responses are means of observed, undisrupted measurements from valid PA sequences.",
      "Games have equal weight; results are not estimated using 5,634 independent game-outcome observations.",
      "Same-game win comparisons use 39 games. Win status and full-game behavior are retrospective; these are not pregame forecasts.",
      "Prior-five-game history uses 34 games, excluding the first five without a complete recorded history.",
      "Primary streak comparisons use 36 games after the first observed loss. The first three pregame streak lengths may extend before this dataset.",
      "A named sensitivity uses all 39 window-truncated streak values; it is not used to choose the preferred result.",
      "Pearson r summarizes linear association; with binary win it is a point-biserial correlation. Spearman rho correlates average ranks, retaining ties.",
      "No p-values or confidence intervals: serial dependence, overlapping history windows, small sample size, and multiple exploratory comparisons limit inference.",
      "Leave-one-game-out values assess single-row influence, not uncertainty. Historical exposure values remain fixed after removing a row.",
      "Dependence may persist even if leave-one-out signs are stable. No adjustment for batter mix, opponent, game order, venue, or other confounding is performed.",
      "Correlation with a prior win streak is not proof of psychological momentum or of an effect of behavior on winning.",
      "This analysis does not reopen Workstream 3's completed test or select a new predictive model.",
      "No raw observations were edited, imputed, extrapolated, trimmed, or winsorized.",
      "The final Power BI presentation review and overall portfolio integration remain separate completion steps.")
    writeLines(notes,file.path(out,"INTERPRETATION_LIMITS.txt"))
    report <- c("# Workstream 4: game-level results and recent history","",
      "Analytical draft generated by script 17; independent review pending.","",
      "## Scope","",
      "The study contains 39 logged games, 20 wins and 19 losses. The Power BI numerical checkpoint reproduced overall, venue, and individual-game results.",
      "The analysis below describes game-level associations. It does not estimate causal effects or forecast game wins.","",
      "## Six exploratory comparisons","",
      "| ID | Context | Behavioral mean | Games | Pearson r | Spearman rho |",
      "|---|---|---|---:|---:|---:|",
      vapply(seq_len(nrow(results)),function(i){r<-results[i,];sprintf("| %s | %s | %s | %d | %.3f | %.3f |",r$pair_id,r$context_label,r$feature_label,r$n,r$pearson_r,r$spearman_rho)},character(1)),"",
      "Positive coefficients indicate larger behavioral means at larger context values; negative coefficients indicate smaller means. Values describe these logged games only.","",
      "## Win/loss contrasts","",
      "| Behavioral measure | Mean in wins | Mean in losses | Win minus loss |",
      "|---|---:|---:|---:|",
      vapply(seq_len(nrow(contrasts)),function(i){r<-contrasts[i,];sprintf("| %s | %.4f | %.4f | %.4f |",r$feature,r$mean_wins,r$mean_losses,r$win_minus_loss)},character(1)),"",
      "## Single-game influence","",
      "| ID | Full-cohort Pearson r | Leave-one-out minimum | Leave-one-out maximum | Any sign change? |",
      "|---|---:|---:|---:|---|",
      vapply(seq_len(nrow(influence)),function(i){r<-influence[i,];sprintf("| %s | %.3f | %.3f | %.3f | %s |",r$pair_id,r$pearson_r,r$loo_pearson_min,r$loo_pearson_max,if(r$pearson_sign_changes)"Yes" else "No")},character(1)),"",
      "These ranges measure influence; they are not confidence intervals. See the separate streak-boundary sensitivity and context-group support tables.","",
      "![Game-level associations](game_associations.png)","","## Interpretation limits","",paste0("- ",notes),"",
      "## Reproducibility","",paste0("Run folder: `",out,"`."),
      "The run includes exact pair membership, point-level data, coefficients, all leave-one-out results, support counts, the source script, input hashes, RDS, and session information.")
    writeLines(report,file.path(out,"WORKSTREAM4_RESEARCH_SUMMARY.md"))
    saveRDS(list(plan=plan,games=g,pair_data=pair_data,correlations=results,leave_one_out=loo,
      influence=influence,support=support,streak_sensitivity=streak_sensitivity,contrasts=contrasts),file.path(out,"project4_game_associations.rds"))
    inputs <- unique(c("scripts/17_project4_game_associations.R",game_file,file.path(game_dir,"input_hashes.csv"),old_hashes$file))
    h <- tools::md5sum(inputs);stopifnot(!anyNA(h))
    write_table(data.frame(file=names(h),md5=unname(h)),"input_hashes.csv")
    stopifnot(file.copy("scripts/17_project4_game_associations.R",file.path(out,"17_project4_game_associations.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    cat("\nDESCRIPTIVE ASSOCIATIONS\n");print(results)
    cat("\nSINGLE-GAME INFLUENCE\n");print(influence)
    cat("\nSTREAK BOUNDARY SENSITIVITY\n");print(streak_sensitivity)
    writeLines("Completed descriptive association analysis; independent review and final report presentation remain pending.",file.path(out,"RUN_COMPLETE.txt"))
    cat("\nOutputs saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project4_associations_output <- run_project4_game_associations()
