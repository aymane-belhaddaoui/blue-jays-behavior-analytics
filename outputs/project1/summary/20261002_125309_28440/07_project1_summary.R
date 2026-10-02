# Reproduce a synthesis from archived CSV results, without refitting or using holdouts.
# From the project root: source("scripts/07_project1_summary.R")
run_project1_summary <- function() {
  m <- "outputs/project1/models/20261002_111847_28440"
  s <- "outputs/project1/sensitivity/20261002_120419_28440"
  t <- "outputs/project1/tics/20261002_122622_28440"
  specs <- data.frame(
    folder=c(m,m,m,m,s,s,t,t,t),
    model=c("M0_pooled","M1_batter","M2_batter_game","S1_all_adjusted",
            "S2_count_inning","S3_log_duration","T1_primary","T2_count_inning","T3_disruption_adjusted"),
    outcome=c(rep("Duration",6),rep("Tic count",3)),
    units=c(rep("seconds",5),"log seconds",rep("tics per pitch",3)),
    n=c(3889,3889,3889,3942,3889,3889,3890,3890,3943),
    primary=c(FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE),
    stringsAsFactors=FALSE)
  results <- do.call(rbind,lapply(seq_len(nrow(specs)),function(i) {
    ci <- read.csv(file.path(specs$folder[i],paste0(specs$model[i],"_ci.csv")))
    test <- read.csv(file.path(specs$folder[i],paste0(specs$model[i],"_test.csv")))
    stopifnot(nrow(ci)==1,nrow(test)==1,ci$Coef=="risp",test$Coef=="risp",
              isTRUE(all.equal(ci$beta,test$beta)))
    data.frame(model=specs$model[i],outcome=specs$outcome[i],units=specs$units[i],
               n=specs$n[i],games=27,primary=specs$primary[i],estimate=ci$beta,
               lower=ci$CI_L,upper=ci$CI_U,se=ci$SE,df=ci$df,p_nominal=test$p_Satt)
  }))
  out <- file.path("outputs","project1","summary",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Output directory already exists.")
  dir.create(out,recursive=TRUE)
  write.csv(results,file.path(out,"workstream1_all_models.csv"),row.names=FALSE)
  write.csv(subset(results,primary),file.path(out,"workstream1_primary_results.csv"),row.names=FALSE)
  # Separate axes: seconds and tic counts are not commensurate quantities.
  local({
    png(file.path(out,"workstream1_primary_results.png"),width=1800,height=850,res=180)
    on.exit(dev.off())
    par(mfrow=c(1,2),mar=c(5,2,5,2),oma=c(3,0,3,0))
    main <- subset(results,primary)
    colors <- c("#17618C","#187969")
    for(i in seq_len(nrow(main))) {
      r <- main[i,]
      xmax <- r$upper*1.2
      plot(NA,xlim=c(-.07*xmax,xmax),ylim=c(.4,1.6),yaxt="n",ylab="",bty="n",
           xlab=paste("Adjusted difference (",r$units,")",sep=""),
           main=paste(r$outcome,paste0("n = ",format(r$n,big.mark=",")),sep="\n"))
      abline(v=0,lty=2,col="gray60")
      segments(r$lower,1,r$upper,1,col=colors[i],lwd=3)
      segments(c(r$lower,r$upper),.95,c(r$lower,r$upper),1.05,col=colors[i],lwd=2)
      points(r$estimate,1,pch=19,cex=1.5,col=colors[i])
      text(r$estimate,1.3,sprintf("+%.3f  [%.3f, %.3f]",r$estimate,r$lower,r$upper),cex=.95)
    }
    mtext("Workstream 1 | RISP and observed pre-pitch behavior",outer=TRUE,side=3,line=1,font=2)
    mtext("Undisrupted training pitches; batter and game adjustment; game CR2 95% CIs.\nExploratory associations; 27 games, 16 batters. Separate horizontal scales.",outer=TRUE,side=1,line=.8,cex=.8)
  })
  files <- c("scripts/07_project1_summary.R",
             unlist(lapply(seq_len(nrow(specs)),function(i)
               file.path(specs$folder[i],paste0(specs$model[i],c("_ci.csv","_test.csv"))))))
  hashes <- tools::md5sum(files);stopifnot(!anyNA(hashes))
  write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
  stopifnot(file.copy("scripts/07_project1_summary.R",file.path(out,"07_project1_summary.R")))
  writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
  print(subset(results,primary));cat("\nSummary saved in:",out,"\n")
  writeLines("Summary tables and figure reproduced from archived estimates; no models refitted.",file.path(out,"RUN_COMPLETE.txt"))
  invisible(out)
}
summary_output <- run_project1_summary()
