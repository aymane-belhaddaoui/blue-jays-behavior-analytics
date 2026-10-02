# Analysis logic supplied in chat and run by the user as 03_project1_diagnostics.R.
# Checkpoint version adds automatic output archiving. It does not replace 02_eda_R.R.
# Run from the project root, which contains data/ and scripts/.
run_diagnostics <- function() {
  source("scripts/01_import_R.R", local = TRUE)
  out <- file.path("outputs", "project1", "diagnostics",
                   paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_", Sys.getpid()))
  if (dir.exists(out)) stop("Run folder already exists; wait one second before rerunning.")
  dir.create(out, recursive = TRUE)
  sink(file.path(out, "console.txt"), split = TRUE)
  on.exit(sink(), add = TRUE)
  p1_train <- subset(p1_routine, split == "Train")
  d <- subset(p1_train, pa_sequence_valid == 1 & !is.na(risp) & !is.na(pitcher_disruption))
  cohort_flow <- data.frame(
    stage = c("Observed routines: all dates", "Observed routines: training dates",
              "Training dates: valid PA and complete context"),
    pitches = c(nrow(p1_routine), nrow(p1_train), nrow(d)))
  print(cohort_flow)
  cohort_dimensions <- c(pitches=nrow(d), plate_appearances=length(unique(d$pa_id)),
                         games=length(unique(d$game_id)), batters=length(unique(d$batter_id)))
  print(cohort_dimensions)
  stopifnot(!anyDuplicated(d$pitch_id), all(d$routine_time_secs > 0),
            all(d$risp %in% c(0,1)), all(d$pitcher_disruption %in% c(0,1)))
  batter_support <- table(batter_id=d$batter_id, risp=factor(d$risp,levels=c(0,1)))
  print(batter_support)
  within_batter <- do.call(rbind, lapply(split(d,d$batter_id), function(z) {
    no_risp <- z$routine_time_secs[z$risp==0]; risp <- z$routine_time_secs[z$risp==1]
    mean0 <- if(length(no_risp)) mean(no_risp) else NA_real_
    mean1 <- if(length(risp)) mean(risp) else NA_real_
    data.frame(batter_id=z$batter_id[1],n_no_risp=length(no_risp),n_risp=length(risp),
               mean_no_risp=mean0,mean_risp=mean1,difference_secs=mean1-mean0)
  }))
  rownames(within_batter) <- NULL
  within_batter <- within_batter[order(within_batter$difference_secs,na.last=TRUE),]
  print(within_batter,row.names=FALSE,digits=3)
  context_counts <- with(d,table(risp,pitcher_disruption)); print(context_counts)
  context_summary <- aggregate(routine_time_secs ~ risp + pitcher_disruption, data=d,
    FUN=function(x)c(n=length(x),mean=mean(x),median=median(x),sd=sd(x),
                     p95=unname(quantile(x,.95)),maximum=max(x)))
  print(context_summary)
  long_routines <- d[d$routine_time_secs>60,c("pitch_id","pa_id","game_id","batter_id",
                      "pitch_number_pa","risp","pitcher_disruption","routine_time_secs")]
  print(long_routines,row.names=FALSE)
  write.csv(cohort_flow,file.path(out,"cohort_flow.csv"),row.names=FALSE)
  write.csv(data.frame(metric=names(cohort_dimensions),value=unname(cohort_dimensions)),
            file.path(out,"cohort_dimensions.csv"),row.names=FALSE)
  write.csv(as.data.frame(batter_support),file.path(out,"batter_support.csv"),row.names=FALSE)
  write.csv(within_batter,file.path(out,"within_batter.csv"),row.names=FALSE)
  write.csv(as.data.frame(context_counts),file.path(out,"context_counts.csv"),row.names=FALSE)
  # Flatten the matrix-valued aggregate column for a clean export.
  context_flat <- cbind(context_summary[c("risp","pitcher_disruption")],
                        as.data.frame(context_summary$routine_time_secs))
  write.csv(context_flat,file.path(out,"context_summary.csv"),row.names=FALSE)
  write.csv(long_routines,file.path(out,"long_routines.csv"),row.names=FALSE)
  saveRDS(list(data=d,cohort_flow=cohort_flow,within_batter=within_batter,
               context_summary=context_summary,long_routines=long_routines),
          file.path(out,"diagnostics.rds"))
  writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
  hashes <- tools::md5sum(c("data/project1_pitches.csv","scripts/03_project1_diagnostics.R"))
  write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
  cat("\nDiagnostics saved in:",out,"\n")
  invisible(out)
}
diagnostics_output <- run_diagnostics()
